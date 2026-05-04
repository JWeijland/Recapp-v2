// NightDetailView.swift – Full night detail: scattered deck, stats, locations, photos, share

import SwiftUI
import MapKit
import CoreLocation

struct NightDetailView: View {
    let nightId: String
    @Binding var nights: [NightData]

    @State private var currentIndex  = 0
    @State private var editedNames:  [String: String] = [:]
    @State private var editedEmojis: [String: String] = [:]
    @State private var editingStopId = ""
    @State private var editingName   = ""
    @State private var showEditAlert = false
    @State private var likedNights:      Set<String> = []
    @State private var likedStops:       Set<String> = []
    @State private var showPhotoViewer   = false
    @State private var photoViewerIndex  = 0
    @State private var favoritePlaces:   [FavoritePlace] = []
    @State private var shareImage:        UIImage?    = nil
    @State private var isGeneratingShare  = false
    @State private var showShareSheet     = false
    @State private var showAccountPrompt  = false
    @ObservedObject private var supabase  = SupabaseManager.shared

    private var night: NightData {
        guard nights.indices.contains(currentIndex) else {
            return nights.first ?? NightData(
                nightId: "", title: "", dateString: "", dateISO: "",
                startTime: "", endTime: "", totalSteps: 0, totalDuration: "",
                totalStopsCount: 0, stops: [], routeCoordinates: [], photos: [], venueBadges: []
            )
        }
        return nights[currentIndex]
    }
    private var canGoOlder: Bool { currentIndex < nights.count - 1 }
    private var canGoNewer: Bool { currentIndex > 0 }

    var body: some View {
        ZStack(alignment: .top) {
            Color.bgPrimary.ignoresSafeArea()

            VStack(spacing: 0) {
                titleNavBar
                scrollContent
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(Color.bgPrimary, for: .navigationBar)
        .sheet(isPresented: $showPhotoViewer) {
            photoViewerSheet
        }
        .sheet(isPresented: $showShareSheet) {
            if let img = shareImage {
                ShareSheet(image: img, night: night)
            }
        }
        .sheet(isPresented: $showAccountPrompt, onDismiss: {
            if supabase.isLoggedIn { triggerShare() }
        }) {
            ShareAuthSheet()
        }
        .alert("Edit Location", isPresented: $showEditAlert) {
            TextField("Location name", text: $editingName)
            Button("Save") {
                let t = editingName.trimmingCharacters(in: .whitespaces)
                if !t.isEmpty { editedNames[editingStopId] = t }
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("Correct the location name:")
        }
        .onAppear {
            currentIndex = nights.firstIndex(where: { $0.nightId == nightId }) ?? 0
            favoritePlaces = FavoritePlaceStore.load()
        }
    }

    // MARK: – Title nav bar

    private var titleNavBar: some View {
        VStack(spacing: 3) {
            HStack(spacing: 6) {
                Button {
                    if canGoOlder { currentIndex += 1 }
                } label: {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundColor(canGoOlder ? .textPrimary : .textDim)
                }
                .frame(width: 28, height: 28)
                .disabled(!canGoOlder)

                Spacer()

                Text(night.title)
                    .font(.system(size: 20, weight: .black))
                    .tracking(-0.6)
                    .foregroundColor(.textPrimary)
                    .lineLimit(1)

                Spacer()

                Button {
                    if canGoNewer { currentIndex -= 1 }
                } label: {
                    Image(systemName: "chevron.right")
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundColor(canGoNewer ? .textPrimary : .textDim)
                }
                .frame(width: 28, height: 28)
                .disabled(!canGoNewer)
            }

            Text(night.dateString)
                .font(.system(size: 11, weight: .semibold))
                .foregroundColor(.textMuted)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .background(Color.bgPrimary)
        .overlay(Rectangle().frame(height: 1).foregroundColor(Color.borderCard), alignment: .bottom)
    }

    // MARK: – Scroll content

    private var scrollContent: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 0) {
                deckSection
                actionsRow
                timeRow
                locationsSection
                shareSection
            }
            .padding(.bottom, 40)
        }
    }

    // MARK: – Scattered deck

    private var deckSection: some View {
        ScatteredDeckPreview(night: night, showStats: false)
            .padding(.horizontal, 16)
            .padding(.top, 20)
            .id(night.nightId)
    }

    // MARK: – Actions row

    private var actionsRow: some View {
        HStack(spacing: 10) {
            actionButton(
                icon: likedNights.contains(night.nightId) ? "heart.fill" : "heart",
                active: likedNights.contains(night.nightId),
                activeBg: .accentPinkSoft,
                activeFg: .accentPink
            ) {
                if likedNights.contains(night.nightId) {
                    likedNights.remove(night.nightId)
                } else {
                    likedNights.insert(night.nightId)
                }
            }

            Button { triggerShare() } label: {
                actionButtonLabel(icon: isGeneratingShare ? "ellipsis" : "square.and.arrow.up",
                                  active: false, activeBg: .bgCard, activeFg: .textPrimary)
            }
            .disabled(isGeneratingShare)

            actionButton(
                icon: "bookmark",
                active: false,
                activeBg: .accentOrangeSoft,
                activeFg: .accentOrange
            ) {}
        }
        .padding(.horizontal, 16)
        .padding(.top, 16)
    }

    @ViewBuilder
    private func actionButton(icon: String, active: Bool, activeBg: Color, activeFg: Color, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            actionButtonLabel(icon: icon, active: active, activeBg: activeBg, activeFg: activeFg)
        }
    }

    private func actionButtonLabel(icon: String, active: Bool, activeBg: Color, activeFg: Color) -> some View {
        Image(systemName: icon)
            .font(.system(size: 18))
            .foregroundColor(active ? activeFg : .textPrimary)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .background(active ? activeBg : Color.bgCard)
            .overlay(
                RoundedRectangle(cornerRadius: 14)
                    .stroke(active ? activeFg.opacity(0.4) : Color.borderCard, lineWidth: 1)
            )
            .clipShape(RoundedRectangle(cornerRadius: 14))
    }

    // MARK: – Compact time / steps row

    private var timeRow: some View {
        VStack(spacing: 8) {
            HStack(spacing: 8) {
                timeChip(icon: "clock",       value: night.startTime,                      label: "Start",    fg: .accentGreen)
                timeChip(icon: "clock.fill",  value: night.endTime,                        label: "End",      fg: .accentPink)
                timeChip(icon: "timer",       value: night.totalDuration,                  label: "Duration", fg: .accentOrange)
            }
            HStack(spacing: 8) {
                timeChip(icon: "figure.walk", value: "\(night.totalSteps.formatted())",    label: "Steps",    fg: .accentBlue)
                timeChip(icon: "mappin",      value: "\(night.totalStopsCount)",           label: "Stops",    fg: .accentPurple)
                timeChip(icon: "flame",       value: "\(Int(Double(night.totalSteps) * 0.035))", label: "Cal", fg: Color(hex: "#B8881A"))
            }
        }
        .padding(.horizontal, 16)
        .padding(.top, 12)
    }

    private func timeChip(icon: String, value: String, label: String, fg: Color) -> some View {
        VStack(spacing: 4) {
            Image(systemName: icon)
                .font(.system(size: 15))
                .foregroundColor(fg)
            Text(value)
                .font(.system(size: 14, weight: .black))
                .foregroundColor(fg)
            Text(label)
                .font(.system(size: 9, weight: .bold))
                .tracking(0.4)
                .textCase(.uppercase)
                .foregroundColor(fg.opacity(0.7))
        }
        .padding(.vertical, 14).padding(.horizontal, 8)
        .frame(maxWidth: .infinity)
        .background(Color.bgCard)
        .overlay(RoundedRectangle(cornerRadius: 16).stroke(Color.borderCard, lineWidth: 1))
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    // MARK: – Locations

    private var locationsSection: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack {
                Text("Places")
                    .font(.system(size: 18, weight: .black))
                    .foregroundColor(.textPrimary)
                Spacer()
                Text("Tap to edit name")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundColor(.textMuted)
            }
            .padding(.bottom, 12)

            ForEach(stopsWithEdits) { stop in
                locationRow(stop: stop)
            }
        }
        .padding(.horizontal, 16)
        .padding(.top, 28)
    }

    private var stopsWithEdits: [NightStop] {
        night.stops.map { stop in
            var s = stop
            if let edited = editedNames[stop.stopId] { s.stopName = edited }
            return s
        }
    }

    private func locationRow(stop: NightStop) -> some View {
        HStack(spacing: 12) {
            Button {
            } label: {
                Text(editedEmojis[stop.stopId] ?? stop.iconType.emoji)
                    .font(.system(size: 22))
                    .frame(width: 44, height: 44)
                    .background(Color.bgPrimary)
                    .clipShape(RoundedRectangle(cornerRadius: 14))
            }

            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 5) {
                    Text(stop.stopName)
                        .font(.system(size: 15, weight: .black))
                        .foregroundColor(.textPrimary)
                    if FavoritePlaceStore.isMatch(stop: stop, in: favoritePlaces) {
                        Image(systemName: "star.fill")
                            .font(.system(size: 10))
                            .foregroundColor(.accentYellow)
                    }
                }
                Text(stop.iconType == .home
                     ? "Arrived \(stop.arrivalTime)"
                     : "\(stop.arrivalTime) – \(stop.departureTime)")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(.textSecondary)
            }

            Spacer()

            Button {
                let isFav = FavoritePlaceStore.isMatch(stop: stop, in: favoritePlaces)
                if isFav {
                    favoritePlaces = favoritePlaces.filter {
                        CLLocation(latitude: $0.latitude, longitude: $0.longitude)
                            .distance(from: CLLocation(latitude: stop.latitude, longitude: stop.longitude)) > 20
                    }
                    likedStops.remove(stop.stopId)
                } else {
                    let place = FavoritePlace(
                        name: stop.stopName,
                        address: stop.stopName,
                        latitude: stop.latitude,
                        longitude: stop.longitude
                    )
                    favoritePlaces.append(place)
                    likedStops.insert(stop.stopId)
                }
                FavoritePlaceStore.save(favoritePlaces)
            } label: {
                let isFav = FavoritePlaceStore.isMatch(stop: stop, in: favoritePlaces)
                Image(systemName: isFav ? "heart.fill" : "heart")
                    .font(.system(size: 14))
                    .foregroundColor(isFav ? .accentPink : .textSecondary)
                    .frame(width: 32, height: 32)
            }

            Button {
                editingStopId = stop.stopId
                editingName   = editedNames[stop.stopId] ?? stop.stopName
                showEditAlert = true
            } label: {
                Image(systemName: "pencil")
                    .font(.system(size: 14))
                    .foregroundColor(.textSecondary)
                    .frame(width: 32, height: 32)
            }
        }
        .padding(12)
        .background(Color.bgCard)
        .overlay(RoundedRectangle(cornerRadius: 16).stroke(Color.borderCard, lineWidth: 1))
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .padding(.bottom, 10)
    }

    // MARK: – Photos

    private var photosSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 6) {
                Text("Photos")
                    .font(.system(size: 18, weight: .black))
                    .foregroundColor(.textPrimary)
                Spacer()
                Text("\(night.photos.count)")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundColor(.textSecondary)
                    .padding(.horizontal, 10).padding(.vertical, 3)
                    .background(Color.bgCard)
                    .overlay(RoundedRectangle(cornerRadius: 10).stroke(Color.borderCard, lineWidth: 1))
                    .clipShape(RoundedRectangle(cornerRadius: 10))
            }

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(alignment: .top, spacing: 10) {
                    ForEach(Array(night.photos.enumerated()), id: \.element.id) { idx, photo in
                        VStack(alignment: .leading, spacing: 4) {
                            ZStack(alignment: .bottomLeading) {
                                RecapPhotoView(photo: photo)
                                    .frame(width: 120, height: 120)
                                    .clipShape(RoundedRectangle(cornerRadius: 16))
                                Text(photo.timestamp)
                                    .font(.system(size: 9, weight: .bold))
                                    .foregroundColor(.white)
                                    .padding(.horizontal, 8).padding(.vertical, 3)
                                    .background(Color.black.opacity(0.55))
                                    .clipShape(RoundedRectangle(cornerRadius: 8))
                                    .padding(6)
                            }
                            .frame(width: 120, height: 120)
                            .clipShape(RoundedRectangle(cornerRadius: 16))
                            .onTapGesture {
                                photoViewerIndex = idx
                                showPhotoViewer  = true
                            }
                            if let cap = photo.caption, !cap.isEmpty {
                                Text(cap)
                                    .font(.system(size: 10, weight: .semibold))
                                    .foregroundColor(.textSecondary)
                                    .frame(width: 120, alignment: .leading)
                                    .lineLimit(2)
                            }
                        }
                    }
                }
                .padding(.horizontal, 16)
            }
        }
        .padding(.horizontal, 16)
        .padding(.top, 28)
    }

    // MARK: – Photo viewer

    private var photoViewerSheet: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            TabView(selection: $photoViewerIndex) {
                ForEach(Array(night.photos.enumerated()), id: \.element.id) { idx, photo in
                    ZStack(alignment: .bottom) {
                        RecapPhotoView(photo: photo)
                            .scaledToFit()
                            .frame(maxWidth: .infinity, maxHeight: .infinity)

                        VStack(spacing: 4) {
                            Text(photo.timestamp)
                                .font(.system(size: 12, weight: .semibold))
                                .foregroundColor(.white)
                            if let cap = photo.caption, !cap.isEmpty {
                                Text(cap)
                                    .font(.system(size: 14, weight: .semibold))
                                    .foregroundColor(.white)
                                    .multilineTextAlignment(.center)
                            }
                        }
                        .padding(.horizontal, 20).padding(.vertical, 10)
                        .background(Color.black.opacity(0.5))
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                        .padding(.bottom, 60)
                    }
                    .tag(idx)
                }
            }
            .tabViewStyle(.page)
            .indexViewStyle(.page(backgroundDisplayMode: .always))

            VStack {
                HStack {
                    Spacer()
                    Button { showPhotoViewer = false } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 28))
                            .foregroundColor(.white.opacity(0.8))
                    }
                    .padding(20)
                }
                Spacer()
            }
        }
    }

    // MARK: – Share

    private var shareSection: some View {
        VStack(spacing: 12) {
            Button { triggerShare() } label: {
                HStack(spacing: 10) {
                    if isGeneratingShare {
                        ProgressView().tint(Color(hex: "#FFFDF7"))
                            .scaleEffect(0.85)
                    } else {
                        Image(systemName: "square.and.arrow.up")
                            .font(.system(size: 16, weight: .bold))
                    }
                    Text(isGeneratingShare ? "Generating..." : "Share Recap")
                        .font(.system(size: 16, weight: .black))
                        .tracking(0.3)
                }
                .foregroundColor(Color(hex: "#FFFDF7"))
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(
                    LinearGradient(colors: [Color(hex: "#FF9F53"), Color(hex: "#FF7A2F")],
                                   startPoint: .leading, endPoint: .trailing)
                )
                .clipShape(RoundedRectangle(cornerRadius: 16))
                .shadow(color: Color(hex: "#FF7A2F").opacity(0.25), radius: 12, y: 6)
            }
            .disabled(isGeneratingShare)
        }
        .frame(maxWidth: .infinity)
        .padding(.horizontal, 24)
        .padding(.top, 32)
    }

    private func triggerShare() {
        guard !isGeneratingShare else { return }
        guard supabase.isLoggedIn else {
            showAccountPrompt = true
            return
        }
        isGeneratingShare = true
        Task {
            shareImage        = await ShareCardRenderer.generate(for: night)
            isGeneratingShare = false
            showShareSheet    = true
        }
    }
}

// MARK: – UIActivityViewController wrapper

struct ShareSheet: UIViewControllerRepresentable {
    let image: UIImage
    let night: NightData

    func makeUIViewController(context: Context) -> UIActivityViewController {
        let caption = "\(night.title) — \(night.totalSteps.formatted()) stappen, \(night.totalStopsCount) stops. Gemaakt met Recap."
        return UIActivityViewController(activityItems: [image, caption], applicationActivities: nil)
    }

    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}

#Preview {
    NavigationStack {
        NightDetailView(
            nightId: mockNights[0].nightId,
            nights:  .constant(mockNights)
        )
    }
}
