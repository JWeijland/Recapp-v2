// DashboardView.swift – Main screen: map preview, start/stop, recap list

import SwiftUI
import MapKit
import Combine
import Photos
import CoreLocation

struct DashboardView: View {
    @StateObject private var location    = LocationManager()
    @State private var nights            = mockNights
    @AppStorage("sessionActive")         private var sessionActive         = false
    @AppStorage("sessionStartTimestamp") private var sessionStartTimestamp: Double = 0
    @State private var elapsedStr        = "0m"

    private var sessionStart: Date? {
        sessionStartTimestamp > 0 ? Date(timeIntervalSince1970: sessionStartTimestamp) : nil
    }
    @State private var pulseOpacity      = 1.0
    @State private var searchQuery       = ""
    @State private var showSearch        = false
    @State private var sortOldest        = false
    @State private var showFilterModal   = false
    @State private var specificDate:     String? = nil
    @State private var favoritePlaces:   [FavoritePlace] = []
    @State private var renameNightId:    String? = nil
    @State private var renameText        = ""
    @State private var showRenameAlert   = false
    @State private var sessionPhotos:    [UIImage] = []
    @State private var showRecapSummary  = false
    @State private var hasLoadedFromCloud = false
    @State private var effectiveEndTime: Date? = nil

    @Environment(\.scenePhase) private var scenePhase

    @StateObject private var network = NetworkMonitor.shared

    private let elapsedTimer = Timer.publish(every: 10, on: .main, in: .common).autoconnect()

    private var latestNight: NightData? { nights.first }
    @State private var mapCamera = MapCameraPosition.userLocation(fallback: .automatic)

    private var filteredNights: [NightData] {
        var result = nights
        if !searchQuery.isEmpty {
            result = result.filter {
                $0.title.localizedCaseInsensitiveContains(searchQuery) ||
                $0.dateString.localizedCaseInsensitiveContains(searchQuery)
            }
        }
        if let date = specificDate {
            result = result.filter { $0.dateISO == date }
        }
        return sortOldest ? result.reversed() : result
    }

    private var availableDates: [String] {
        Array(Set(nights.map { $0.dateISO })).sorted().reversed()
    }

    var body: some View {
        NavigationStack {
            ZStack(alignment: .top) {
                Color.bgPrimary.ignoresSafeArea()

                ScrollView(showsIndicators: false) {
                    VStack(spacing: 0) {
                        topBar
                        if sessionActive { liveMapSection } else { favoritesMapSection }
                        actionSection
                        locationPermissionBanner
                        listSection
                    }
                    .padding(.bottom, 40)
                }

                // Offline banner floats at top
                VStack {
                    AnimatedOfflineBanner(network: network)
                        .padding(.top, 54)
                    Spacer()
                }
            }
            .navigationBarHidden(true)
            .alert("Rename Recap", isPresented: $showRenameAlert) {
                TextField("Recap name", text: $renameText)
                Button("Save") { saveRename() }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("Give this recap a new name.")
            }
            .sheet(isPresented: $showRecapSummary) {
                RecapSummarySheet(photos: $sessionPhotos) { title, selectedPhotos, caption, friends, postToFeed in
                    finalizeRecap(title: title, selectedPhotos: selectedPhotos,
                                  caption: caption, taggedFriends: friends, postToFeed: postToFeed)
                }
                .interactiveDismissDisabled()
            }
            .onReceive(elapsedTimer) { _ in updateElapsed() }
            .onAppear {
                startPulse()
                checkAutoStop()
                favoritePlaces = FavoritePlaceStore.load()
                if sessionActive, let start = sessionStart {
                    location.resumeTracking(sessionStart: start)
                }
            }
            .sheet(isPresented: $showFilterModal) { filterModalSheet }
            .onChange(of: scenePhase) { _, newPhase in
                if newPhase == .active { checkAutoStop() }
            }
            .task { await loadCloudNights() }
        }
    }

    // MARK: – Top bar

    private var topBar: some View {
        HStack {
            Text("My Recaps")
                .font(.system(size: 28, weight: .black))
                .tracking(-0.8)
                .foregroundColor(.textPrimary)
            Spacer()
            NavigationLink(destination: SettingsView()) {
                ZStack {
                    RoundedRectangle(cornerRadius: 14)
                        .fill(Color.bgCard)
                        .frame(width: 42, height: 42)
                        .overlay(RoundedRectangle(cornerRadius: 14).stroke(Color.borderCard, lineWidth: 1))
                    Image(systemName: "person")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.textPrimary)
                }
            }
        }
        .padding(.top, 58)
        .padding(.horizontal, 20)
        .padding(.bottom, 16)
    }

    // MARK: – Search bar

    private var searchBar: some View {
        HStack(spacing: 8) {
            Image(systemName: "magnifyingglass")
                .foregroundColor(.textSecondary)
                .font(.system(size: 13))
            TextField("", text: $searchQuery, prompt: Text("Search Recaps...").foregroundColor(.textSecondary))
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(.textPrimary)
                .tint(.accentOrange)
            if !searchQuery.isEmpty {
                Button { searchQuery = "" } label: {
                    Image(systemName: "xmark")
                        .font(.system(size: 13))
                        .foregroundColor(.textSecondary)
                }
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 11)
        .background(Color.bgCard)
        .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.borderCard, lineWidth: 1))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .padding(.horizontal, 20)
        .padding(.bottom, 12)
    }

    // MARK: – Live session map

    private var liveMapSection: some View {
        let routeCoords = location.routePoints.map {
            CLLocationCoordinate2D(latitude: $0.latitude, longitude: $0.longitude)
        }
        return Map(position: $mapCamera) {
            UserAnnotation()
            if routeCoords.count > 1 {
                MapPolyline(coordinates: routeCoords)
                    .stroke(Color.accentOrange, lineWidth: 3)
            }
            ForEach(favoritePlaces) { place in
                Annotation(place.name, coordinate: CLLocationCoordinate2D(latitude: place.latitude, longitude: place.longitude)) {
                    favMarker(place: place)
                }
            }
        }
        .mapStyle(.standard)
        .mapControls { }
        .frame(height: UIScreen.main.bounds.height * 0.30)
        .clipShape(RoundedRectangle(cornerRadius: 22))
        .overlay(RoundedRectangle(cornerRadius: 22).stroke(Color.borderCard, lineWidth: 1))
        .padding(.horizontal, 20)
        .padding(.bottom, 8)
    }

    // MARK: – Start / End action section

    private var actionSection: some View {
        VStack(spacing: 12) {
            if sessionActive {
                VStack(spacing: 4) {
                    HStack(spacing: 8) {
                        Circle()
                            .fill(Color.accentPink)
                            .frame(width: 8, height: 8)
                            .opacity(pulseOpacity)
                        Text("Recording for \(elapsedStr)")
                            .font(.system(size: 14, weight: .black))
                            .foregroundColor(.accentPink)
                        Spacer()
                        Text("\(location.sessionStops.count) stops")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundColor(.accentPink.opacity(0.7))
                    }
                    if let stopName = location.currentStop {
                        HStack(spacing: 6) {
                            Image(systemName: "mappin.circle.fill")
                                .font(.system(size: 11))
                                .foregroundColor(.accentPink.opacity(0.7))
                            Text("Now at: \(stopName)")
                                .font(.system(size: 12, weight: .semibold))
                                .foregroundColor(.accentPink.opacity(0.8))
                                .lineLimit(1)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                    }
                }
                .frame(maxWidth: .infinity)
                .padding(.horizontal, 14)
                .padding(.vertical, 10)
                .background(Color.accentPinkSoft)
                .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.accentPink.opacity(0.3), lineWidth: 1))
                .clipShape(RoundedRectangle(cornerRadius: 12))

                Button(action: handleEndRecap) {
                    HStack(spacing: 10) {
                        Image(systemName: "stop.fill")
                            .font(.system(size: 14))
                        Text("End Recap")
                            .font(.system(size: 16, weight: .black))
                    }
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 18)
                    .background(
                        LinearGradient(colors: [Color(hex: "#EA5A8A"), Color(hex: "#D64578")],
                                       startPoint: .leading, endPoint: .trailing)
                    )
                    .clipShape(RoundedRectangle(cornerRadius: 18))
                    .shadow(color: Color.accentPink.opacity(0.25), radius: 10, y: 6)
                }

            } else {
                Button(action: handleStartRecap) {
                    HStack(spacing: 10) {
                        Image(systemName: "play.fill")
                            .font(.system(size: 15))
                        Text("Start New Recap")
                            .font(.system(size: 16, weight: .black))
                    }
                    .foregroundColor(Color(hex: "#FFFDF7"))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 18)
                    .background(
                        LinearGradient(colors: [Color(hex: "#FF9F53"), Color(hex: "#FF7A2F")],
                                       startPoint: .leading, endPoint: .trailing)
                    )
                    .clipShape(RoundedRectangle(cornerRadius: 18))
                    .shadow(color: Color(hex: "#FF7A2F").opacity(0.25), radius: 10, y: 6)
                }
            }
        }
        .padding(.horizontal, 20)
        .padding(.top, 16)
    }

    // MARK: – Location permission banner

    @ViewBuilder
    private var locationPermissionBanner: some View {
        if location.authStatus == .denied || location.authStatus == .restricted {
            HStack(spacing: 10) {
                Image(systemName: "location.slash.fill")
                    .font(.system(size: 14))
                    .foregroundColor(.accentOrange)
                VStack(alignment: .leading, spacing: 2) {
                    Text("Location access needed")
                        .font(.system(size: 13, weight: .black))
                        .foregroundColor(.textPrimary)
                    Text("Enable in Settings to track your recaps.")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundColor(.textSecondary)
                }
                Spacer()
                Button {
                    if let url = URL(string: UIApplication.openSettingsURLString) {
                        UIApplication.shared.open(url)
                    }
                } label: {
                    Text("Fix")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(.accentOrange)
                        .padding(.horizontal, 12).padding(.vertical, 6)
                        .background(Color.accentOrangeSoft)
                        .clipShape(Capsule())
                }
            }
            .padding(14)
            .background(Color.bgCard)
            .overlay(RoundedRectangle(cornerRadius: 14).stroke(Color.accentOrange.opacity(0.3), lineWidth: 1))
            .clipShape(RoundedRectangle(cornerRadius: 14))
            .padding(.horizontal, 20)
            .padding(.top, 12)
        }
    }

    // MARK: – Recap list

    private var listSection: some View {
        VStack(spacing: 0) {
            HStack {
                Text("Previous Recaps")
                    .font(.system(size: 15, weight: .black))
                    .foregroundColor(.textPrimary)
                Spacer()
                HStack(spacing: 8) {
                    Button { showFilterModal = true } label: {
                        HStack(spacing: 5) {
                            Image(systemName: specificDate != nil ? "calendar" : "arrow.up.arrow.down")
                                .font(.system(size: 12))
                            Text(specificDate != nil
                                 ? (Date(isoString: specificDate!)?.shortLabel ?? "Date")
                                 : (sortOldest ? "Oldest" : "Newest"))
                                .font(.system(size: 11, weight: .bold))
                        }
                        .foregroundColor(.textPrimary)
                        .padding(.horizontal, 10).padding(.vertical, 8)
                        .background(Color.bgCard)
                        .overlay(RoundedRectangle(cornerRadius: 10).stroke(Color.borderCard, lineWidth: 1))
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                    }
                    Button {
                        withAnimation { showSearch.toggle() }
                        if !showSearch { searchQuery = "" }
                    } label: {
                        ZStack {
                            RoundedRectangle(cornerRadius: 10)
                                .fill(showSearch ? Color.accentOrangeSoft : Color.bgCard)
                                .frame(width: 34, height: 34)
                                .overlay(RoundedRectangle(cornerRadius: 10).stroke(
                                    showSearch ? Color.accentOrange.opacity(0.3) : Color.borderCard, lineWidth: 1))
                            Image(systemName: showSearch ? "xmark" : "magnifyingglass")
                                .font(.system(size: 12))
                                .foregroundColor(showSearch ? .accentOrange : .textPrimary)
                        }
                    }
                }
            }
            .padding(.horizontal, 20)
            .padding(.top, 28)
            .padding(.bottom, 14)

            if showSearch { searchBar }

            if nights.isEmpty {
                emptyState
            } else if filteredNights.isEmpty && !searchQuery.isEmpty {
                VStack(spacing: 6) {
                    Text("🔎").font(.system(size: 32))
                    Text("No Recaps match \"\(searchQuery)\"")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(.textSecondary)
                }
                .padding(.vertical, 32)
            }

            ForEach(Array(filteredNights.enumerated()), id: \.element.id) { idx, night in
                NavigationLink(destination: NightDetailView(nightId: night.nightId, nights: $nights)) {
                    RecapCard(
                        night: night,
                        isLatest: idx == 0 && !sortOldest && searchQuery.isEmpty,
                        onRename: {
                            renameNightId = night.nightId
                            renameText    = night.title
                            showRenameAlert = true
                        }
                    )
                }
                .buttonStyle(.plain)
                .padding(.horizontal, 20)
                .padding(.bottom, 10)
            }
        }
    }

    // MARK: – Favorites map helpers

    private var favoritesMapRegion: MapCameraPosition {
        guard !favoritePlaces.isEmpty else {
            return .userLocation(fallback: .automatic)
        }
        let avgLat = favoritePlaces.reduce(0) { $0 + $1.latitude } / Double(favoritePlaces.count)
        let avgLng = favoritePlaces.reduce(0) { $0 + $1.longitude } / Double(favoritePlaces.count)
        return .region(MKCoordinateRegion(
            center: CLLocationCoordinate2D(latitude: avgLat, longitude: avgLng),
            span: MKCoordinateSpan(latitudeDelta: 0.07, longitudeDelta: 0.07)
        ))
    }

    private func favMarker(place: FavoritePlace) -> some View {
        ZStack {
            Circle()
                .fill(Color.bgCard)
                .frame(width: 36, height: 36)
                .overlay(Circle().stroke(Color.accentPink, lineWidth: 2))
            Image(systemName: "heart.fill")
                .font(.system(size: 14))
                .foregroundColor(.accentPink)
        }
        .shadow(color: Color(hex: "#231600").opacity(0.1), radius: 4, y: 2)
    }

    // MARK: – Favorites map section

    private var favoritesMapSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                HStack(spacing: 6) {
                    Image(systemName: "heart.fill")
                        .font(.system(size: 12))
                        .foregroundColor(.accentPink)
                    Text(favoritePlaces.isEmpty ? "Your favorites map" : "\(favoritePlaces.count) favorite places")
                        .font(.system(size: 13, weight: .heavy))
                        .foregroundColor(.textPrimary)
                }
                Spacer()
                NavigationLink(destination: SettingsView()) {
                    HStack(spacing: 2) {
                        Text("View all")
                            .font(.system(size: 12, weight: .heavy))
                            .foregroundColor(.accentOrange)
                        Image(systemName: "chevron.right")
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundColor(.accentOrange)
                    }
                }
            }

            Map(initialPosition: favoritesMapRegion) {
                ForEach(favoritePlaces) { place in
                    Annotation(place.name, coordinate: CLLocationCoordinate2D(latitude: place.latitude, longitude: place.longitude)) {
                        favMarker(place: place)
                    }
                }
            }
            .mapStyle(.standard)
            .mapControls { }
            .frame(height: UIScreen.main.bounds.height * 0.28)
            .clipShape(RoundedRectangle(cornerRadius: 22))
            .overlay(
                Group {
                    if favoritePlaces.isEmpty {
                        VStack {
                            Spacer()
                            HStack(spacing: 6) {
                                Image(systemName: "heart")
                                    .font(.system(size: 11))
                                    .foregroundColor(.accentPink)
                                Text("Heart places in a Recap to save them here")
                                    .font(.system(size: 11, weight: .bold))
                                    .foregroundColor(.textPrimary)
                            }
                            .padding(.horizontal, 12).padding(.vertical, 8)
                            .background(Color.bgCard.opacity(0.88))
                            .clipShape(Capsule())
                            .shadow(color: Color.black.opacity(0.08), radius: 4, y: 2)
                            .padding(.bottom, 12)
                        }
                    }
                }
            )
            .overlay(RoundedRectangle(cornerRadius: 22).stroke(Color.borderCard, lineWidth: 1))
        }
        .padding(.horizontal, 20)
        .padding(.bottom, 4)
    }

    // MARK: – Filter modal sheet

    private var filterModalSheet: some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: 0) {
                Text("Sort")
                    .font(.system(size: 20, weight: .black))
                    .foregroundColor(.textPrimary)
                    .padding(.horizontal, 20)
                    .padding(.top, 24)
                    .padding(.bottom, 12)

                ForEach([("newest", "Newest → Oldest"), ("oldest", "Oldest → Newest")], id: \.0) { key, label in
                    let isActive = (key == "oldest") == sortOldest && specificDate == nil
                    Button {
                        sortOldest = (key == "oldest")
                        specificDate = nil
                        showFilterModal = false
                    } label: {
                        HStack {
                            Text(label)
                                .font(.system(size: 15, weight: isActive ? .heavy : .semibold))
                                .foregroundColor(isActive ? .accentOrange : .textPrimary)
                            Spacer()
                            if isActive {
                                Text("✓")
                                    .font(.system(size: 16, weight: .black))
                                    .foregroundColor(.accentOrange)
                            }
                        }
                        .padding(.horizontal, 16).padding(.vertical, 14)
                        .background(isActive ? Color.accentOrangeSoft : Color.bgPrimary)
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                        .padding(.horizontal, 20)
                        .padding(.bottom, 6)
                    }
                }

                HStack {
                    Text("Specific date")
                        .font(.system(size: 20, weight: .black))
                        .foregroundColor(.textPrimary)
                    Spacer()
                    if specificDate != nil {
                        Button { specificDate = nil } label: {
                            Text("Clear")
                                .font(.system(size: 13, weight: .heavy))
                                .foregroundColor(.accentOrange)
                        }
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 20)
                .padding(.bottom, 8)

                CalendarDatePicker(
                    availableDates: availableDates,
                    selected: specificDate
                ) { date in
                    specificDate = date
                    showFilterModal = false
                }
                .padding(.horizontal, 20)

                Spacer()
            }
            .background(Color.bgCard.ignoresSafeArea())
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { showFilterModal = false }
                        .foregroundColor(.accentOrange)
                        .fontWeight(.bold)
                }
            }
        }
        .presentationDetents([.large])
    }

    // MARK: – Empty state

    private var emptyState: some View {
        VStack(spacing: 16) {
            ZStack {
                Circle()
                    .fill(Color.accentOrangeSoft)
                    .frame(width: 80, height: 80)
                Image(systemName: "moon.stars.fill")
                    .font(.system(size: 32))
                    .foregroundColor(.accentOrange)
            }
            VStack(spacing: 6) {
                Text("No recaps yet")
                    .font(.system(size: 18, weight: .black))
                    .foregroundColor(.textPrimary)
                Text("Tap Start to record your first evening out.")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.textSecondary)
                    .multilineTextAlignment(.center)
            }
        }
        .padding(.vertical, 48)
        .padding(.horizontal, 40)
    }

    // MARK: – Logic

    private func handleStartRecap() {
        location.requestPermission()
        location.startTracking()
        sessionActive         = true
        sessionStartTimestamp = Date().timeIntervalSince1970
        elapsedStr            = "0m"
        NotificationManager.shared.scheduleIdleCheck()
    }

    private func handleEndRecap() {
        effectiveEndTime = nil  // manual stop: no sleep-time subtraction
        let start = sessionStart
        location.stopTracking()
        sessionActive         = false
        sessionStartTimestamp = 0
        elapsedStr            = "0m"
        sessionPhotos = []
        if let start { fetchSessionPhotos(since: start) }
        showRecapSummary = true
    }

    private func checkAutoStop() {
        guard sessionActive else { return }

        let explicitFlag = UserDefaults.standard.bool(forKey: "autoStopRecap")
        let anchorDate   = UserDefaults.standard.object(forKey: "sleepAnchorTime") as? Date
        // Auto-stop if the flag was set by a notification tap OR if the anchor is 5h+ old
        // (covers the case where the user dismissed the notification without tapping)
        let sleepExpired = anchorDate.map { Date().timeIntervalSince($0) >= 5 * 3600 } ?? false
        guard explicitFlag || sleepExpired else { return }

        UserDefaults.standard.removeObject(forKey: "autoStopRecap")
        effectiveEndTime = anchorDate
        UserDefaults.standard.removeObject(forKey: "sleepAnchorTime")
        let start = sessionStart
        location.stopTracking()
        sessionActive         = false
        sessionStartTimestamp = 0
        elapsedStr            = "0m"
        sessionPhotos         = []
        if let start { fetchSessionPhotos(since: start) }
        showRecapSummary = true
    }

    private func finalizeRecap(title: String, selectedPhotos: [(UIImage, String?)],
                               caption: String, taggedFriends: [String], postToFeed: Bool) {
        showRecapSummary = false
        let savedTitle = title.trimmingCharacters(in: .whitespaces).isEmpty
            ? "Recap \(formattedDate())" : title
        var newNight = location.buildNightData(title: savedTitle, effectiveEndTime: effectiveEndTime)
        effectiveEndTime = nil
        newNight.photos = savePhotos(selectedPhotos, nightId: newNight.nightId)
        if !caption.isEmpty { newNight.postCaption = caption }
        newNight.taggedFriends = taggedFriends
        nights.insert(newNight, at: 0)
        sessionPhotos = []
        NotificationManager.shared.cancelIdleCheck()
        NotificationManager.shared.scheduleRecapReady(
            title: newNight.title,
            stopsCount: newNight.totalStopsCount,
            steps: newNight.totalSteps
        )
        NotificationManager.shared.resetInactivityReminder()
        if postToFeed { postRecapToFeed(newNight) }
        Task { try? await SupabaseManager.shared.saveNight(newNight) }
    }

    private func postRecapToFeed(_ night: NightData) {
        let post = FeedPost(
            profileId: "me",
            username: ownProfileName(),
            initials: ownProfileInitials(),
            avatarHex: "#FF8A3D",
            nightTitle: night.title,
            dateString: night.dateString,
            coverUri: night.photos.first?.uri ?? "",
            steps: night.totalSteps,
            stopsCount: night.totalStopsCount,
            likes: 0,
            commentsCount: 0,
            timeAgo: "Just now",
            caption: night.postCaption,
            taggedFriends: night.taggedFriends,
            nightData: night
        )
        FeedStore.shared.addPost(post)
    }

    private func ownProfileName() -> String {
        UserDefaults.standard.string(forKey: "displayName") ?? "Jij"
    }

    private func ownProfileInitials() -> String {
        let name = ownProfileName()
        return name.split(separator: " ").prefix(2)
            .compactMap(\.first).map(String.init).joined()
    }

    private func savePhotos(_ photos: [(UIImage, String?)], nightId: String) -> [SessionPhoto] {
        let fmt = DateFormatter(); fmt.timeStyle = .short
        return photos.enumerated().compactMap { idx, pair in
            let (image, caption) = pair
            guard let data = image.jpegData(compressionQuality: 0.8) else { return nil }
            let filename = "recap_\(nightId)_\(idx).jpg"
            let url = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
                .appendingPathComponent(filename)
            try? data.write(to: url)
            return SessionPhoto(id: "\(nightId)-photo-\(idx)", uri: url.absoluteString,
                                timestamp: fmt.string(from: Date()), caption: caption)
        }
    }

    private func loadCloudNights() async {
        guard SupabaseManager.shared.isLoggedIn, !hasLoadedFromCloud else { return }
        hasLoadedFromCloud = true
        do {
            let cloudNights = try await SupabaseManager.shared.fetchMyNights()
            if !cloudNights.isEmpty { nights = cloudNights }
        } catch {}
    }

    private func formattedDate() -> String {
        let f = DateFormatter()
        f.dateFormat = "MMM d"
        return f.string(from: Date())
    }

    private func fetchSessionPhotos(since start: Date) {
        let options = PHFetchOptions()
        options.predicate = NSPredicate(format: "creationDate >= %@", start as CVarArg)
        options.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: true)]
        let assets = PHAsset.fetchAssets(with: .image, options: options)
        guard assets.count > 0 else { return }

        let reqOpts = PHImageRequestOptions()
        reqOpts.deliveryMode = .highQualityFormat
        reqOpts.isNetworkAccessAllowed = true

        let count = assets.count
        var images: [UIImage?] = Array(repeating: nil, count: count)
        let manager = PHImageManager.default()
        assets.enumerateObjects { asset, idx, _ in
            manager.requestImage(for: asset,
                                 targetSize: CGSize(width: 600, height: 600),
                                 contentMode: .aspectFill,
                                 options: reqOpts) { img, info in
                let isDegraded = (info?[PHImageResultIsDegradedKey] as? Bool) ?? false
                guard let img, !isDegraded else { return }
                DispatchQueue.main.async {
                    images[idx] = img
                    sessionPhotos = images.compactMap { $0 }
                }
            }
        }
    }

    private func updateElapsed() {
        guard sessionActive, let start = sessionStart else { return }
        let mins  = Int(Date().timeIntervalSince(start) / 60)
        let hours = mins / 60
        let rem   = mins % 60
        elapsedStr = hours > 0 ? "\(hours)h \(rem)m" : "\(mins)m"
    }

    private func startPulse() {
        withAnimation(.easeInOut(duration: 0.8).repeatForever(autoreverses: true)) {
            pulseOpacity = 0.3
        }
    }

    private func saveRename() {
        guard let id = renameNightId, !renameText.trimmingCharacters(in: .whitespaces).isEmpty else { return }
        if let idx = nights.firstIndex(where: { $0.nightId == id }) {
            nights[idx].title = renameText.trimmingCharacters(in: .whitespaces)
        }
    }
}

// MARK: – RecapCard

struct RecapCard: View {
    let night:    NightData
    let isLatest: Bool
    let onRename: () -> Void

    var body: some View {
        ZStack(alignment: .topLeading) {
            HStack(spacing: 12) {
                if let photo = night.photos.first {
                    AsyncImage(url: URL(string: photo.uri)) { img in
                        img.resizable().scaledToFill()
                    } placeholder: {
                        Color.bgCard
                    }
                    .frame(width: 56, height: 56)
                    .clipShape(RoundedRectangle(cornerRadius: 14))
                }

                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 6) {
                        Text(night.title)
                            .font(.system(size: 15, weight: .black))
                            .foregroundColor(.textPrimary)
                            .lineLimit(1)
                        Button(action: onRename) {
                            Image(systemName: "pencil")
                                .font(.system(size: 10))
                                .foregroundColor(.textSecondary)
                                .padding(3)
                                .background(Color.bgPrimary)
                                .clipShape(RoundedRectangle(cornerRadius: 4))
                        }
                    }
                    HStack(spacing: 4) {
                        Image(systemName: "calendar")
                            .font(.system(size: 10))
                            .foregroundColor(.textMuted)
                        Text(night.dateString)
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundColor(.textMuted)
                    }
                    HStack(spacing: 6) {
                        miniChip(icon: "figure.walk", bg: .accentBlueSoft,   fg: .accentBlue,   text: "\(night.totalSteps.formatted())")
                        miniChip(icon: "mappin",      bg: .accentGreenSoft,  fg: .accentGreen,  text: "\(night.totalStopsCount)")
                        miniChip(icon: "flame",       bg: .accentYellowSoft, fg: Color(hex: "#B8881A"), text: "\(Int(Double(night.totalSteps) * 0.035))")
                    }
                    .padding(.top, 2)
                }

                Spacer()
                Image(systemName: "chevron.right")
                    .font(.system(size: 13))
                    .foregroundColor(.textMuted)
            }
            .padding(12)
            .background(Color.bgCard)
            .overlay(
                RoundedRectangle(cornerRadius: 18)
                    .stroke(isLatest ? Color.accentOrange : Color.borderCard,
                            lineWidth: isLatest ? 1.5 : 1)
            )
            .clipShape(RoundedRectangle(cornerRadius: 18))

            if isLatest {
                HStack(spacing: 4) {
                    Image(systemName: "star.fill")
                        .font(.system(size: 9))
                        .foregroundColor(Color(hex: "#FFFDF7"))
                    Text("Latest Recap")
                        .font(.system(size: 9, weight: .black))
                        .tracking(0.3)
                        .foregroundColor(Color(hex: "#FFFDF7"))
                }
                .padding(.horizontal, 8).padding(.vertical, 3)
                .background(Color.accentOrange)
                .clipShape(Capsule())
                .offset(x: 10, y: -8)
            }
        }
    }

    private func miniChip(icon: String, bg: Color, fg: Color, text: String) -> some View {
        HStack(spacing: 3) {
            Image(systemName: icon)
                .font(.system(size: 9))
                .foregroundColor(fg)
            Text(text)
                .font(.system(size: 10, weight: .bold))
                .foregroundColor(fg)
        }
        .padding(.horizontal, 8).padding(.vertical, 4)
        .background(bg)
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }
}

// MARK: – Animated offline banner (floating)

struct AnimatedOfflineBanner: View {
    @ObservedObject var network: NetworkMonitor

    var body: some View {
        Group {
            if !network.isConnected {
                banner(text: "No internet connection", icon: "wifi.slash", color: Color.textPrimary)
            } else if network.wasOffline {
                banner(text: "Back online", icon: "wifi", color: .accentGreen)
            }
        }
        .animation(.spring(duration: 0.4), value: network.isConnected)
        .animation(.spring(duration: 0.4), value: network.wasOffline)
    }

    private func banner(text: String, icon: String, color: Color) -> some View {
        HStack(spacing: 7) {
            Image(systemName: icon).font(.system(size: 12, weight: .bold))
            Text(text).font(.system(size: 13, weight: .bold))
        }
        .foregroundColor(.white)
        .padding(.horizontal, 16).padding(.vertical, 9)
        .background(color)
        .clipShape(Capsule())
        .shadow(color: color.opacity(0.3), radius: 8, y: 4)
    }
}

// MARK: – Calendar date picker

struct CalendarDatePicker: View {
    let availableDates: [String]
    let selected: String?
    let onSelect: (String) -> Void

    @State private var viewYear  = Calendar.current.component(.year, from: Date())
    @State private var viewMonth = Calendar.current.component(.month, from: Date()) - 1

    private let weekdays = ["M","T","W","T","F","S","S"]
    private let monthLabels = ["January","February","March","April","May","June",
                                "July","August","September","October","November","December"]

    var body: some View {
        VStack(spacing: 8) {
            HStack {
                Button { goPrev() } label: {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.textPrimary)
                        .frame(width: 32, height: 32)
                        .background(Color.bgCard)
                        .overlay(RoundedRectangle(cornerRadius: 10).stroke(Color.borderCard, lineWidth: 1))
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                }
                Spacer()
                Text("\(monthLabels[viewMonth]) \(viewYear)")
                    .font(.system(size: 15, weight: .black))
                    .foregroundColor(.textPrimary)
                Spacer()
                Button { goNext() } label: {
                    Image(systemName: "chevron.right")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.textPrimary)
                        .frame(width: 32, height: 32)
                        .background(Color.bgCard)
                        .overlay(RoundedRectangle(cornerRadius: 10).stroke(Color.borderCard, lineWidth: 1))
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                }
            }
            .padding(.horizontal, 4).padding(.vertical, 4)

            HStack {
                ForEach(weekdays, id: \.self) { d in
                    Text(d).font(.system(size: 10, weight: .heavy)).foregroundColor(.textMuted)
                        .frame(maxWidth: .infinity)
                }
            }

            let cells = buildGrid()
            let availSet = Set(availableDates)
            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 0), count: 7), spacing: 0) {
                ForEach(Array(cells.enumerated()), id: \.offset) { _, iso in
                    if let iso {
                        let day = Int(iso.suffix(2)) ?? 0
                        let isAvail = availSet.contains(iso)
                        let isSel   = selected == iso
                        Button {
                            if isAvail { onSelect(iso) }
                        } label: {
                            ZStack {
                                Circle()
                                    .fill(isSel ? Color.accentOrange : (isAvail ? Color.accentOrangeSoft : Color.clear))
                                    .padding(3)
                                Text("\(day)")
                                    .font(.system(size: 13, weight: isSel ? .black : (isAvail ? .bold : .regular)))
                                    .foregroundColor(isSel ? Color(hex: "#FFFDF7") : (isAvail ? .textPrimary : .textMuted))
                            }
                        }
                        .frame(maxWidth: .infinity).aspectRatio(1, contentMode: .fit)
                        .disabled(!isAvail)
                    } else {
                        Color.clear.frame(maxWidth: .infinity).aspectRatio(1, contentMode: .fit)
                    }
                }
            }
        }
        .padding(12)
        .background(Color.bgPrimary)
        .clipShape(RoundedRectangle(cornerRadius: 18))
    }

    private func buildGrid() -> [String?] {
        let first = Calendar.current.date(from: DateComponents(year: viewYear, month: viewMonth + 1, day: 1))!
        let startIdx = (Calendar.current.component(.weekday, from: first) + 5) % 7
        let days = Calendar.current.range(of: .day, in: .month, for: first)!.count
        var cells: [String?] = Array(repeating: nil, count: startIdx)
        for d in 1...days {
            let mm = String(format: "%02d", viewMonth + 1)
            let dd = String(format: "%02d", d)
            cells.append("\(viewYear)-\(mm)-\(dd)")
        }
        while cells.count % 7 != 0 { cells.append(nil) }
        return cells
    }

    private func goPrev() {
        if viewMonth == 0 { viewMonth = 11; viewYear -= 1 } else { viewMonth -= 1 }
    }
    private func goNext() {
        if viewMonth == 11 { viewMonth = 0; viewYear += 1 } else { viewMonth += 1 }
    }
}

// MARK: – Date helper

extension Date {
    init?(isoString: String) {
        let f = DateFormatter(); f.dateFormat = "yyyy-MM-dd"
        guard let d = f.date(from: isoString) else { return nil }
        self = d
    }
    var shortLabel: String {
        let f = DateFormatter(); f.dateFormat = "MMM d"
        return f.string(from: self)
    }
}

#Preview { DashboardView() }
