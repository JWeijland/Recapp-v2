// NightData.swift – Color system + data models

import SwiftUI
import MapKit

// MARK: – Color hex init

extension Color {
    init(hex: String) {
        let h = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: h).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch h.count {
        case 3:  (a,r,g,b) = (255,(int>>8)*17,(int>>4 & 0xF)*17,(int & 0xF)*17)
        case 6:  (a,r,g,b) = (255,int>>16,int>>8 & 0xFF,int & 0xFF)
        case 8:  (a,r,g,b) = (int>>24,int>>16 & 0xFF,int>>8 & 0xFF,int & 0xFF)
        default: (a,r,g,b) = (255,0,0,0)
        }
        self.init(.sRGB, red: Double(r)/255, green: Double(g)/255, blue: Double(b)/255, opacity: Double(a)/255)
    }
}

// MARK: – App color system (warm beige theme)

extension Color {
    static let bgPrimary        = Color(hex: "#FBF7F2")   // cream background
    static let bgCard           = Color(hex: "#FFFFFF")   // white cards
    static let bgAlt            = Color(hex: "#FFFFFF")   // white alt
    static let textPrimary      = Color(hex: "#1C1B1A")   // dark brown text
    static let textSecondary    = Color(hex: "#6B6357")   // muted text
    static let textMuted        = Color(hex: "#9A9082")   // subtle text
    static let textDim          = Color(hex: "#ECE3D6")   // dim (borders/dividers)
    static let borderCard       = Color(hex: "#ECE3D6")   // card border
    static let borderInput      = Color(hex: "#DCD0BE")   // input border
    static let borderDeep       = Color(hex: "#DCD0BE")   // stronger border
    static let accentOrange     = Color(hex: "#FF8A3D")   // primary orange accent
    static let accentOrangeSoft = Color(hex: "#FFE2CC")   // soft orange
    static let accentGreen      = Color(hex: "#4FC38A")   // mint green
    static let accentGreenSoft  = Color(hex: "#D8F3E4")   // mint soft
    static let accentBlue       = Color(hex: "#3FA9F5")   // sky blue
    static let accentBlueSoft   = Color(hex: "#D6ECFD")   // sky soft
    static let accentYellow     = Color(hex: "#F4C23D")   // sunshine yellow
    static let accentYellowSoft = Color(hex: "#FFF1C8")   // sunshine soft
    static let accentPink       = Color(hex: "#EA5A8A")   // berry pink
    static let accentPinkSoft   = Color(hex: "#FCDCE6")   // berry soft
    static let accentPurple     = Color(hex: "#9B7EDE")   // lavender
    static let accentPurpleSoft = Color(hex: "#E7DEFA")   // lavender soft
}

// MARK: – Stop icon type

enum StopIconType: String, Codable {
    case bar, club, food, home, cafe, restaurant, park

    var emoji: String {
        switch self {
        case .bar:        return "😎"
        case .club:       return "🥳"
        case .food:       return "😋"
        case .home:       return "🏡"
        case .cafe:       return "☕"
        case .restaurant: return "🍽️"
        case .park:       return "🌳"
        }
    }

    var label: String {
        switch self {
        case .bar:        return "Bar"
        case .club:       return "Club"
        case .food:       return "Snack"
        case .home:       return "Home"
        case .cafe:       return "Café"
        case .restaurant: return "Restaurant"
        case .park:       return "Outdoor"
        }
    }

    var accentColor: Color {
        switch self {
        case .bar:        return .accentOrange
        case .club:       return .accentPink
        case .food:       return .accentGreen
        case .home:       return .accentGreen
        case .cafe:       return .accentYellow
        case .restaurant: return .accentOrange
        case .park:       return .accentGreen
        }
    }

    var symbolName: String {
        switch self {
        case .bar:        return "wineglass"
        case .club:       return "music.note"
        case .food:       return "fork.knife"
        case .home:       return "house.fill"
        case .cafe:       return "cup.and.saucer.fill"
        case .restaurant: return "fork.knife.circle.fill"
        case .park:       return "leaf.fill"
        }
    }
}

// MARK: – Data models

struct NightStop: Identifiable, Codable {
    let stopId:        String
    var stopName:      String
    let arrivalTime:   String
    let departureTime: String
    let iconType:      StopIconType
    let latitude:      Double
    let longitude:     Double
    let dwellMinutes:  Int

    var id: String { stopId }
    var coordinate: CLLocationCoordinate2D { .init(latitude: latitude, longitude: longitude) }
}

struct SessionPhoto: Identifiable, Codable {
    let id:        String
    let uri:       String
    let timestamp: String
    var caption:   String? = nil
}

struct VenueBadge: Identifiable, Codable {
    let id:        String
    let name:      String
    let iconType:  StopIconType
    let latitude:  Double
    let longitude: Double
    var emoji:     String?

    var coordinate: CLLocationCoordinate2D { .init(latitude: latitude, longitude: longitude) }
}

struct RoutePoint: Codable {
    let latitude:  Double
    let longitude: Double
}

struct NightData: Identifiable, Codable {
    let nightId:         String
    var title:           String
    let dateString:      String
    let dateISO:         String
    let startTime:       String
    let endTime:         String
    let totalSteps:      Int
    let totalDuration:   String
    let totalStopsCount: Int
    let stops:           [NightStop]
    let routeCoordinates:[RoutePoint]
    var photos:          [SessionPhoto]
    let venueBadges:     [VenueBadge]
    var postCaption:     String? = nil
    var taggedFriends:   [String]  = []

    var id: String { nightId }

    var centerCoordinate: CLLocationCoordinate2D {
        guard !routeCoordinates.isEmpty else { return .init(latitude: 52.52, longitude: 13.405) }
        let lat = routeCoordinates.map(\.latitude).reduce(0, +) / Double(routeCoordinates.count)
        let lng = routeCoordinates.map(\.longitude).reduce(0, +) / Double(routeCoordinates.count)
        return .init(latitude: lat, longitude: lng)
    }

    var clRouteCoordinates: [CLLocationCoordinate2D] {
        routeCoordinates.map { .init(latitude: $0.latitude, longitude: $0.longitude) }
    }

    var caloriesBurned: Int { Int(Double(totalSteps) * 0.035) }
}

// MARK: – Favorite Places

struct FavoritePlace: Identifiable, Codable {
    var id:        String = UUID().uuidString
    var name:      String
    var address:   String
    var latitude:  Double
    var longitude: Double
}

class FavoritePlaceStore {
    private static let key = "favoritePlaces"

    static func load() -> [FavoritePlace] {
        guard let data = UserDefaults.standard.data(forKey: key),
              let places = try? JSONDecoder().decode([FavoritePlace].self, from: data)
        else { return [] }
        return places
    }

    static func save(_ places: [FavoritePlace]) {
        if let data = try? JSONEncoder().encode(places) {
            UserDefaults.standard.set(data, forKey: key)
        }
    }

    static func isMatch(stop: NightStop, in places: [FavoritePlace]) -> Bool {
        let stopLoc = CLLocation(latitude: stop.latitude, longitude: stop.longitude)
        return places.contains {
            CLLocation(latitude: $0.latitude, longitude: $0.longitude).distance(from: stopLoc) <= 20
        }
    }
}

// MARK: – Photo helper view (handles both remote URLs and local file:// URIs)

struct RecapPhotoView: View {
    let photo: SessionPhoto
    @State private var localImage: UIImage?

    var body: some View {
        Group {
            if let img = localImage {
                Image(uiImage: img).resizable().scaledToFill()
            } else if !photo.uri.hasPrefix("file://") && !photo.uri.isEmpty {
                AsyncImage(url: URL(string: photo.uri)) { phase in
                    switch phase {
                    case .success(let img): img.resizable().scaledToFill()
                    default: Color.bgAlt
                    }
                }
            } else {
                Color.bgAlt
            }
        }
        .task(id: photo.uri) {
            guard photo.uri.hasPrefix("file://"), let url = URL(string: photo.uri) else { return }
            guard let data = try? Data(contentsOf: url), let img = UIImage(data: data) else { return }
            await MainActor.run { localImage = img }
        }
    }
}
