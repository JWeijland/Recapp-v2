// LocationManager.swift – Real GPS tracking + stop detection

import Foundation
import Combine
import CoreLocation
import SwiftUI

@MainActor
class LocationManager: NSObject, ObservableObject {

    // MARK: – Published state

    @Published var authStatus:    CLAuthorizationStatus = .notDetermined
    @Published var isTracking:    Bool = false
    @Published var sessionStops:  [NightStop]   = []
    @Published var routePoints:   [RoutePoint]  = []
    @Published var currentStop:   String?       = nil
    @Published var sessionStart:  Date?         = nil
    @Published var locationError: String?       = nil
    @Published var gpsAccuracy:   Double        = 0

    // MARK: – Private tracking state

    private let manager = CLLocationManager()
    private var recentLocations: [CLLocation] = []

    // Dwell detection
    private var dwellAnchor:     CLLocation? = nil   // reference point for current dwell
    private var dwellStart:      Date?       = nil   // when dwell at anchor started
    private var activeStopStart: Date?       = nil   // when confirmed stop began
    private var activeStopLoc:   CLLocation? = nil

    // Thresholds
    private let dwellRadiusMeters: Double       = 60    // user stays within 60m...
    private let dwellMinutes:      TimeInterval = 900   // ...for 15 min → stop
    private let departureMeters:   Double       = 100   // moved 100m away → departed stop

    // MARK: – Init

    override init() {
        super.init()
        manager.delegate          = self
        manager.desiredAccuracy   = kCLLocationAccuracyNearestTenMeters
        manager.distanceFilter    = 15   // update every 15m of movement
        manager.pausesLocationUpdatesAutomatically = false
        authStatus = manager.authorizationStatus
    }

    // MARK: – Public API

    func requestPermission() {
        manager.requestAlwaysAuthorization()
    }

    func startTracking() {
        guard authStatus == .authorizedAlways || authStatus == .authorizedWhenInUse else {
            requestPermission()
            return
        }
        isTracking   = true
        sessionStart = Date()
        sessionStops = []
        routePoints  = []
        recentLocations = []
        dwellAnchor  = nil
        dwellStart   = nil
        activeStopStart = nil
        activeStopLoc   = nil
        currentStop  = nil

        UserDefaults.standard.set(Date(), forKey: "sleepAnchorTime")
        NotificationManager.shared.rescheduleSleepCheck()

        manager.allowsBackgroundLocationUpdates = true
        manager.startUpdatingLocation()
    }

    /// Resume GPS after app was killed mid-session (does not reset stops/route).
    func resumeTracking(sessionStart: Date) {
        guard authStatus == .authorizedAlways || authStatus == .authorizedWhenInUse else { return }
        isTracking        = true
        self.sessionStart = sessionStart
        manager.allowsBackgroundLocationUpdates = true
        manager.startUpdatingLocation()
    }

    func stopTracking() {
        manager.stopUpdatingLocation()
        manager.allowsBackgroundLocationUpdates = false
        isTracking = false

        NotificationManager.shared.cancelSleepCheck()
        UserDefaults.standard.removeObject(forKey: "sleepAnchorTime")

        // Close any in-progress stop
        if let loc = activeStopLoc, let start = activeStopStart {
            finalizeStop(location: loc, arrived: start, departed: Date())
        }
        currentStop = nil
    }

    /// Build a NightData from the current session. Call after stopTracking().
    /// Pass effectiveEndTime to trim sleep time (auto-stop via sleep detection).
    func buildNightData(title: String, effectiveEndTime: Date? = nil) -> NightData {
        let fmt = DateFormatter()
        fmt.dateStyle = .medium
        fmt.timeStyle = .none

        let timeFmt = DateFormatter()
        timeFmt.timeStyle = .short
        timeFmt.dateStyle = .none

        let now     = effectiveEndTime ?? Date()
        let start   = sessionStart ?? now
        let steps   = estimateSteps(from: routePoints)

        // Add home stop if we have a location and know where home is
        var allStops = sessionStops
        if let last = routePoints.last {
            let homeStop = NightStop(
                stopId:        UUID().uuidString,
                stopName:      storedHomeLabel(),
                arrivalTime:   timeFmt.string(from: now),
                departureTime: timeFmt.string(from: now),
                iconType:      .home,
                latitude:      last.latitude,
                longitude:     last.longitude,
                dwellMinutes:  0
            )
            allStops.append(homeStop)
        }

        let simplified = douglasPeucker(points: routePoints, epsilon: 0.000045)

        return NightData(
            nightId:         UUID().uuidString,
            title:           title,
            dateString:      fmt.string(from: start),
            dateISO:         ISO8601DateFormatter().string(from: start),
            startTime:       timeFmt.string(from: start),
            endTime:         timeFmt.string(from: now),
            totalSteps:      steps,
            totalDuration:   formatDuration(from: start, to: now),
            totalStopsCount: allStops.filter { $0.iconType != .home }.count,
            stops:           allStops,
            routeCoordinates: simplified,
            photos:          [],
            venueBadges:     []
        )
    }

    // MARK: – Private: stop detection

    private func processLocation(_ location: CLLocation) {
        // Reset sleep detection timer on every GPS update (movement detected)
        UserDefaults.standard.set(Date(), forKey: "sleepAnchorTime")
        NotificationManager.shared.rescheduleSleepCheck()

        // Keep 30-min sliding window
        let cutoff = Date().addingTimeInterval(-1800)
        recentLocations = recentLocations.filter { $0.timestamp > cutoff }
        recentLocations.append(location)

        // Only add route point when NOT at a confirmed stop (avoids zigzag while stationary)
        // and only when moved at least 10m from last recorded point (extra noise filter)
        if activeStopStart == nil {
            let newPoint = RoutePoint(latitude: location.coordinate.latitude,
                                     longitude: location.coordinate.longitude)
            if let last = routePoints.last {
                let lastLoc = CLLocation(latitude: last.latitude, longitude: last.longitude)
                if location.distance(from: lastLoc) >= 10 {
                    routePoints.append(newPoint)
                }
            } else {
                routePoints.append(newPoint)
            }
        }

        // Phase 1: no anchor yet → set one
        guard let anchor = dwellAnchor, let dwStart = dwellStart else {
            dwellAnchor = location
            dwellStart  = Date()
            return
        }

        let distFromAnchor = location.distance(from: anchor)

        if distFromAnchor <= dwellRadiusMeters {
            // Still near anchor
            let dwell = Date().timeIntervalSince(dwStart)

            if dwell >= dwellMinutes && activeStopStart == nil {
                // Confirmed new stop
                activeStopStart = dwStart
                activeStopLoc   = anchor
                reverseGeocode(anchor) { [weak self] name in
                    self?.currentStop = name
                }
            }
        } else {
            // Moved away from anchor
            if let stopLoc = activeStopLoc, let stopStart = activeStopStart {
                // Was at a confirmed stop — record departure
                let distFromStop = location.distance(from: stopLoc)
                if distFromStop > departureMeters {
                    finalizeStop(location: stopLoc, arrived: stopStart, departed: Date())
                    activeStopStart = nil
                    activeStopLoc   = nil
                    currentStop     = nil
                }
            }
            // Reset dwell anchor
            dwellAnchor = location
            dwellStart  = Date()
        }
    }

    private func finalizeStop(location: CLLocation, arrived: Date, departed: Date) {
        let timeFmt = DateFormatter()
        timeFmt.timeStyle = .short
        let dwell = Int(departed.timeIntervalSince(arrived) / 60)

        reverseGeocode(location) { [weak self] name in
            guard let self else { return }
            let stop = NightStop(
                stopId:        UUID().uuidString,
                stopName:      name,
                arrivalTime:   timeFmt.string(from: arrived),
                departureTime: timeFmt.string(from: departed),
                iconType:      guessIconType(for: name),
                latitude:      location.coordinate.latitude,
                longitude:     location.coordinate.longitude,
                dwellMinutes:  dwell
            )
            self.sessionStops.append(stop)
        }
    }

    private func reverseGeocode(_ location: CLLocation, completion: @escaping (String) -> Void) {
        CLGeocoder().reverseGeocodeLocation(location) { placemarks, _ in
            let name = placemarks?.first?.name
                    ?? placemarks?.first?.thoroughfare
                    ?? "Unknown location"
            DispatchQueue.main.async { completion(name) }
        }
    }

    // MARK: – Helpers

    private func estimateSteps(from points: [RoutePoint]) -> Int {
        guard points.count > 1 else { return 0 }
        var totalMeters = 0.0
        for i in 1..<points.count {
            let a = CLLocation(latitude: points[i-1].latitude, longitude: points[i-1].longitude)
            let b = CLLocation(latitude: points[i].latitude,   longitude: points[i].longitude)
            totalMeters += b.distance(from: a)
        }
        return Int(totalMeters / 0.762)  // avg step length 76.2cm
    }

    private func formatDuration(from start: Date, to end: Date) -> String {
        let mins  = Int(end.timeIntervalSince(start) / 60)
        let hours = mins / 60
        let rem   = mins % 60
        return hours > 0 ? "\(hours)h \(rem)m" : "\(mins)m"
    }

    private func storedHomeLabel() -> String {
        let city = UserDefaults.standard.string(forKey: "homeCity") ?? ""
        return city.isEmpty ? "Home" : "Home, \(city)"
    }

    // MARK: – Douglas-Peucker route simplification

    private func douglasPeucker(points: [RoutePoint], epsilon: Double) -> [RoutePoint] {
        guard points.count > 2 else { return points }
        var maxDist = 0.0; var maxIdx = 0
        for i in 1..<points.count - 1 {
            let d = perpendicularDist(points[i], from: points.first!, to: points.last!)
            if d > maxDist { maxDist = d; maxIdx = i }
        }
        if maxDist > epsilon {
            let left  = douglasPeucker(points: Array(points[0...maxIdx]),   epsilon: epsilon)
            let right = douglasPeucker(points: Array(points[maxIdx...]),    epsilon: epsilon)
            return Array(left.dropLast()) + right
        }
        return [points.first!, points.last!]
    }

    private func perpendicularDist(_ p: RoutePoint, from a: RoutePoint, to b: RoutePoint) -> Double {
        let dx = b.longitude - a.longitude; let dy = b.latitude - a.latitude
        let len2 = dx*dx + dy*dy
        guard len2 > 0 else {
            return sqrt(pow(p.longitude - a.longitude, 2) + pow(p.latitude - a.latitude, 2))
        }
        let t = ((p.longitude - a.longitude)*dx + (p.latitude - a.latitude)*dy) / len2
        return sqrt(pow(p.latitude - (a.latitude + t*dy), 2) + pow(p.longitude - (a.longitude + t*dx), 2))
    }

    private func guessIconType(for name: String) -> StopIconType {
        let lower = name.lowercased()
        if lower.contains("bar") || lower.contains("pub") || lower.contains("lounge") { return .bar }
        if lower.contains("club") || lower.contains("disco") || lower.contains("night") { return .club }
        if lower.contains("restaurant") || lower.contains("bistro") || lower.contains("brasserie") { return .restaurant }
        if lower.contains("cafe") || lower.contains("coffee") || lower.contains("koffie") { return .cafe }
        if lower.contains("park") || lower.contains("garden") || lower.contains("strand") { return .park }
        if lower.contains("snack") || lower.contains("kebab") || lower.contains("pizza") { return .food }
        return .bar
    }
}

// MARK: – CLLocationManagerDelegate

extension LocationManager: CLLocationManagerDelegate {
    nonisolated func locationManager(_ manager: CLLocationManager,
                                     didUpdateLocations locations: [CLLocation]) {
        guard let loc = locations.last,
              loc.horizontalAccuracy > 0,
              loc.horizontalAccuracy < 100 else { return }
        Task { @MainActor in
            self.gpsAccuracy = loc.horizontalAccuracy
            self.locationError = nil
            self.processLocation(loc)
        }
    }

    nonisolated func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        Task { @MainActor in
            self.authStatus = manager.authorizationStatus
            if manager.authorizationStatus == .authorizedAlways ||
               manager.authorizationStatus == .authorizedWhenInUse {
                // Permission granted — tracking will start when user taps Start
            }
        }
    }

    nonisolated func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        let msg = (error as? CLError)?.code == .denied
            ? "Location access denied. Enable in Settings."
            : error.localizedDescription
        Task { @MainActor in self.locationError = msg }
    }
}
