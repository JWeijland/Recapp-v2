// RecapShareCard.swift – Scattered polaroid deck + shareable card

import SwiftUI
import MapKit

// MARK: – Card Metrics

struct CardMetrics {
    static let photoW: CGFloat   = 276
    static let photoH: CGFloat   = 207
    static let frameInset: CGFloat = 12
    static let captionH: CGFloat = 50
    static var totalW: CGFloat { photoW + frameInset * 2 }
    static var totalH: CGFloat { photoH + captionH + frameInset * 2 }
}

// MARK: – Scatter Spots

struct ScatterSpot: Identifiable {
    let id: Int
    let angle: Double
    let offsetX: CGFloat
    let offsetY: CGFloat
}

let scatterSpots: [ScatterSpot] = [
    ScatterSpot(id: 0, angle: -6,  offsetX:  0,   offsetY:  0),
    ScatterSpot(id: 1, angle:  9,  offsetX: -10,  offsetY: -6),
    ScatterSpot(id: 2, angle: -3,  offsetX:  8,   offsetY:  4),
    ScatterSpot(id: 3, angle:  13, offsetX: -6,   offsetY:  6),
    ScatterSpot(id: 4, angle: -15, offsetX:  10,  offsetY: -10),
]

func activeSpot(_ idx: Int) -> ScatterSpot {
    ScatterSpot(id: idx, angle: 0, offsetX: 0, offsetY: 0)
}

// MARK: – Polaroid Frame

struct PolaroidFrame: View {
    let image: UIImage?
    let caption: String?
    let isActive: Bool

    var body: some View {
        VStack(spacing: 0) {
            ZStack {
                Color(hex: "#F0EBE0")
                if let img = image {
                    Image(uiImage: img)
                        .resizable()
                        .scaledToFill()
                        .frame(width: CardMetrics.photoW, height: CardMetrics.photoH)
                        .clipped()
                } else {
                    LinearGradient(
                        colors: [Color(hex: "#FFE2CC"), Color(hex: "#FFF1C8")],
                        startPoint: .topLeading, endPoint: .bottomTrailing
                    )
                    Image(systemName: "photo")
                        .font(.system(size: 36))
                        .foregroundColor(Color.accentOrange.opacity(0.4))
                }
            }
            .frame(width: CardMetrics.photoW, height: CardMetrics.photoH)

            ZStack {
                Color(hex: "#FFFDF7")
                Text(caption ?? "")
                    .font(.custom("Georgia", size: 13))
                    .foregroundColor(Color(hex: "#4A4540"))
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
                    .padding(.horizontal, 10)
            }
            .frame(width: CardMetrics.photoW, height: CardMetrics.captionH)
        }
        .frame(width: CardMetrics.totalW, height: CardMetrics.totalH)
        .background(Color(hex: "#FFFDF7"))
        .clipShape(RoundedRectangle(cornerRadius: 4))
        .shadow(
            color: .black.opacity(isActive ? 0.18 : 0.11),
            radius: isActive ? 16 : 8,
            y: isActive ? 6 : 3
        )
    }
}

// MARK: – Polaroid (with scatter transform)

struct Polaroid: View {
    let image: UIImage?
    let caption: String?
    let spot: ScatterSpot
    let isActive: Bool

    var body: some View {
        PolaroidFrame(image: image, caption: caption, isActive: isActive)
            .rotationEffect(.degrees(isActive ? 0 : spot.angle))
            .offset(x: isActive ? 0 : spot.offsetX, y: isActive ? 0 : spot.offsetY)
            .animation(.spring(response: 0.4, dampingFraction: 0.75), value: isActive)
    }
}

// MARK: – Branding mark

struct RecapBrandMark: View {
    var body: some View {
        HStack(spacing: 5) {
            Image(systemName: "moon.stars.fill")
                .font(.system(size: 10))
                .foregroundColor(Color(hex: "#FF8A3D"))
            Text("Recap")
                .font(.system(size: 12, weight: .black))
                .tracking(0.5)
                .foregroundColor(Color(hex: "#1C1B1A"))
        }
        .padding(.horizontal, 12).padding(.vertical, 6)
        .background(Color.white.opacity(0.9))
        .clipShape(Capsule())
        .overlay(Capsule().stroke(Color(hex: "#ECE3D6"), lineWidth: 1))
    }
}

// MARK: – Title sticker

struct TitleSticker: View {
    let title: String
    let date: String

    var body: some View {
        VStack(spacing: 2) {
            Text(title)
                .font(.system(size: 15, weight: .black))
                .tracking(-0.3)
                .foregroundColor(Color(hex: "#1C1B1A"))
                .lineLimit(1)
            Text(date)
                .font(.system(size: 11, weight: .semibold))
                .foregroundColor(Color(hex: "#9A9082"))
        }
        .padding(.horizontal, 14).padding(.vertical, 8)
        .background(Color(hex: "#FFFDF7"))
        .clipShape(RoundedRectangle(cornerRadius: 10))
        .overlay(RoundedRectangle(cornerRadius: 10).stroke(Color(hex: "#ECE3D6"), lineWidth: 1))
        .shadow(color: .black.opacity(0.06), radius: 4, y: 2)
    }
}

// MARK: – Stats ribbon

struct StatsRibbon: View {
    let night: NightData

    var body: some View {
        HStack(spacing: 6) {
            chip(icon: "figure.walk",
                 value: night.totalSteps > 0 ? "\(night.totalSteps.formatted())" : "—",
                 label: "walked")
            chip(icon: "mappin",
                 value: "\(night.totalStopsCount)",
                 label: "stops")
            chip(icon: "timer",
                 value: night.totalDuration,
                 label: "duration")
        }
    }

    private func chip(icon: String, value: String, label: String) -> some View {
        VStack(spacing: 2) {
            HStack(spacing: 3) {
                Image(systemName: icon)
                    .font(.system(size: 8))
                    .foregroundColor(.accentOrange)
                Text(value)
                    .font(.system(size: 12, weight: .black))
                    .foregroundColor(.accentOrange)
            }
            Text(label)
                .font(.system(size: 8, weight: .semibold))
                .foregroundColor(.accentOrange.opacity(0.7))
        }
        .padding(.horizontal, 8).padding(.vertical, 6)
        .frame(maxWidth: .infinity)
        .background(Color.accentOrangeSoft)
        .clipShape(RoundedRectangle(cornerRadius: 10))
    }
}

// MARK: – Scattered Stage

struct ScatteredStage: View {
    let night: NightData
    let mapImage: UIImage?
    let photoImages: [UIImage]
    @Binding var activeIdx: Int

    private var allImages: [UIImage?] {
        var imgs: [UIImage?] = []
        if let map = mapImage { imgs.append(map) }
        imgs.append(contentsOf: photoImages.map { Optional($0) })
        if imgs.isEmpty { imgs.append(nil) }
        return imgs
    }

    private var allCaptions: [String?] {
        var caps: [String?] = []
        if mapImage != nil { caps.append(night.title) }
        caps.append(contentsOf: night.photos.map { $0.caption })
        if caps.isEmpty { caps.append(nil) }
        return caps
    }

    var body: some View {
        ZStack {
            ForEach(Array(allImages.indices.reversed()), id: \.self) { idx in
                let spot = idx < scatterSpots.count ? scatterSpots[idx] : scatterSpots[0]
                let isActive = idx == activeIdx
                Polaroid(
                    image: allImages[idx],
                    caption: idx < allCaptions.count ? allCaptions[idx] : nil,
                    spot: spot,
                    isActive: isActive
                )
                .zIndex(isActive ? 10 : Double(allImages.count - idx))
                .onTapGesture {
                    withAnimation(.spring(response: 0.4, dampingFraction: 0.75)) {
                        activeIdx = idx == activeIdx
                            ? (idx + 1) % allImages.count
                            : idx
                    }
                }
            }
        }
        .frame(width: CardMetrics.totalW + 30, height: CardMetrics.totalH + 30)
    }
}

// MARK: – Scattered Deck Preview (main recap view in NightDetailView + FeedCard)

struct ScatteredDeckPreview: View {
    let night: NightData
    var showTitle: Bool = true
    var showStats: Bool = true
    @State private var mapImage: UIImage?
    @State private var photoImages: [UIImage] = []
    @State private var activeIdx: Int = 0
    @State private var isLoading = true

    var totalCount: Int {
        (mapImage != nil ? 1 : 0) + photoImages.count
    }

    var body: some View {
        VStack(spacing: 12) {
            if isLoading {
                RoundedRectangle(cornerRadius: 4)
                    .fill(Color(hex: "#F0EBE0"))
                    .frame(width: CardMetrics.totalW, height: CardMetrics.totalH)
                    .overlay(ProgressView())
                    .shadow(color: .black.opacity(0.10), radius: 8, y: 3)
            } else {
                ScatteredStage(
                    night: night,
                    mapImage: mapImage,
                    photoImages: photoImages,
                    activeIdx: $activeIdx
                )

                if totalCount > 1 {
                    HStack(spacing: 5) {
                        ForEach(0..<totalCount, id: \.self) { i in
                            Circle()
                                .fill(i == activeIdx ? Color.accentOrange : Color(hex: "#D4CEC6"))
                                .frame(
                                    width: i == activeIdx ? 8 : 5,
                                    height: i == activeIdx ? 8 : 5
                                )
                                .animation(.spring(response: 0.3), value: activeIdx)
                        }
                    }
                }

                if showStats {
                    StatsRibbon(night: night)
                        .padding(.horizontal, 4)
                }

                if showTitle {
                    TitleSticker(title: night.title, date: night.dateString)
                }
            }
        }
        .task {
            let (map, photos) = await ShareCardRenderer.loadAssets(for: night)
            mapImage = map
            photoImages = photos
            isLoading = false
        }
    }
}

// MARK: – Legacy share card view (for export / share sheet)

struct RecapShareCardView: View {
    let night:    NightData
    let mapImage: UIImage?

    private let cardW: CGFloat = 390
    private let cardH: CGFloat = 580

    var body: some View {
        ZStack(alignment: .bottom) {
            VStack(spacing: 0) {
                mapArea
                infoArea
            }
            brandingBadge
        }
        .frame(width: cardW, height: cardH)
        .clipShape(RoundedRectangle(cornerRadius: 28))
        .background(Color(hex: "#FBF7F2"))
    }

    private var mapArea: some View {
        ZStack(alignment: .bottomLeading) {
            if let img = mapImage {
                Image(uiImage: img)
                    .resizable()
                    .scaledToFill()
                    .frame(width: cardW, height: 280)
                    .clipped()
            } else {
                LinearGradient(
                    colors: [Color(hex: "#FFE2CC"), Color(hex: "#FFF1C8")],
                    startPoint: .topLeading, endPoint: .bottomTrailing
                )
                .frame(width: cardW, height: 280)
                Image(systemName: "map.fill")
                    .font(.system(size: 48))
                    .foregroundColor(Color.accentOrange.opacity(0.3))
            }
            LinearGradient(
                colors: [Color.clear, Color(hex: "#FBF7F2")],
                startPoint: .center, endPoint: .bottom
            )
            .frame(height: 100)
        }
        .frame(width: cardW, height: 280)
    }

    private var infoArea: some View {
        VStack(alignment: .leading, spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                Text(night.title)
                    .font(.system(size: 22, weight: .black))
                    .tracking(-0.5)
                    .foregroundColor(Color(hex: "#1C1B1A"))
                    .lineLimit(1)
                Text(night.dateString)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(Color(hex: "#9A9082"))
            }

            HStack(spacing: 8) {
                statChip(icon: "figure.walk",
                         value: "\(night.totalSteps.formatted())",
                         label: "gelopen", bg: "#D6ECFD", fg: "#3FA9F5")
                statChip(icon: "mappin",
                         value: "\(night.totalStopsCount)",
                         label: "stops",   bg: "#D8F3E4", fg: "#4FC38A")
                statChip(icon: "timer",
                         value: night.totalDuration,
                         label: "duur",    bg: "#FFF1C8", fg: "#B8881A")
            }

            if !night.stops.filter({ $0.iconType != .home }).isEmpty {
                HStack(spacing: 6) {
                    ForEach(night.stops.filter { $0.iconType != .home }.prefix(4)) { stop in
                        HStack(spacing: 4) {
                            Text(stop.iconType.emoji)
                                .font(.system(size: 12))
                            Text(stop.stopName)
                                .font(.system(size: 11, weight: .semibold))
                                .foregroundColor(Color(hex: "#6B6357"))
                                .lineLimit(1)
                        }
                        .padding(.horizontal, 8).padding(.vertical, 4)
                        .background(Color(hex: "#F4EEE5"))
                        .clipShape(Capsule())
                    }
                }
            }
        }
        .padding(.horizontal, 22)
        .padding(.top, 4)
        .padding(.bottom, 48)
        .frame(width: cardW, alignment: .leading)
        .background(Color(hex: "#FBF7F2"))
    }

    private var brandingBadge: some View {
        RecapBrandMark()
            .padding(.bottom, 14)
    }

    private func statChip(icon: String, value: String, label: String,
                           bg: String, fg: String) -> some View {
        VStack(spacing: 2) {
            HStack(spacing: 3) {
                Image(systemName: icon)
                    .font(.system(size: 9))
                    .foregroundColor(Color(hex: fg))
                Text(value)
                    .font(.system(size: 13, weight: .black))
                    .foregroundColor(Color(hex: fg))
            }
            Text(label)
                .font(.system(size: 9, weight: .semibold))
                .foregroundColor(Color(hex: fg).opacity(0.7))
        }
        .padding(.horizontal, 10).padding(.vertical, 7)
        .frame(maxWidth: .infinity)
        .background(Color(hex: bg))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

// MARK: – Renderer

@MainActor
enum ShareCardRenderer {

    static func generate(for night: NightData) async -> UIImage {
        let mapImg = await makeMapSnapshot(night: night)
        let card   = RecapShareCardView(night: night, mapImage: mapImg)
        let renderer = ImageRenderer(content: card)
        renderer.scale = 3.0
        return renderer.uiImage ?? UIImage()
    }

    static func loadAssets(for night: NightData) async -> (UIImage?, [UIImage]) {
        async let mapTask    = makeMapSnapshot(night: night)
        async let photosTask = loadPhotoImages(night: night)
        let (map, photos)    = await (mapTask, photosTask)
        return (map, photos)
    }

    static func makeMapSnapshot(night: NightData) async -> UIImage? {
        let coords = night.clRouteCoordinates
        guard !coords.isEmpty else { return nil }

        let region  = MKCoordinateRegion(
            center: night.centerCoordinate,
            span: MKCoordinateSpan(latitudeDelta: 0.030, longitudeDelta: 0.030)
        )
        let opts            = MKMapSnapshotter.Options()
        opts.region         = region
        opts.size           = CGSize(width: 390 * 3, height: 280 * 3)
        opts.scale          = 1
        opts.mapType        = .standard
        opts.showsBuildings = true

        return await withCheckedContinuation { continuation in
            MKMapSnapshotter(options: opts).start { snapshot, error in
                guard let snapshot, error == nil else {
                    continuation.resume(returning: nil); return
                }
                continuation.resume(returning: drawRoute(on: snapshot, coords: coords))
            }
        }
    }

    static func loadPhotoImages(night: NightData) async -> [UIImage] {
        var result: [UIImage] = []
        for photo in night.photos {
            if let img = await loadSingleImage(uri: photo.uri) {
                result.append(img)
            }
        }
        return result
    }

    static func loadSingleImage(uri: String) async -> UIImage? {
        guard let url = URL(string: uri) else { return nil }
        if url.isFileURL {
            return (try? Data(contentsOf: url)).flatMap { UIImage(data: $0) }
        }
        return await withCheckedContinuation { continuation in
            URLSession.shared.dataTask(with: url) { data, _, _ in
                continuation.resume(returning: data.flatMap { UIImage(data: $0) })
            }.resume()
        }
    }

    private static func drawRoute(on snapshot: MKMapSnapshotter.Snapshot,
                                  coords: [CLLocationCoordinate2D]) -> UIImage {
        let base = snapshot.image
        let fmt  = UIGraphicsImageRendererFormat()
        fmt.scale = base.scale

        return UIGraphicsImageRenderer(size: base.size, format: fmt).image { _ in
            base.draw(at: .zero)
            guard coords.count > 1 else { return }
            let points = coords.map { snapshot.point(for: $0) }

            let path = UIBezierPath()
            path.move(to: points[0])
            points.dropFirst().forEach { path.addLine(to: $0) }

            UIColor.white.withAlphaComponent(0.6).setStroke()
            path.lineWidth = 7
            path.lineCapStyle  = .round
            path.lineJoinStyle = .round
            path.stroke()

            UIColor(red: 1.0, green: 0.54, blue: 0.24, alpha: 1).setStroke()
            path.lineWidth = 4
            path.stroke()

            if let first = points.first {
                drawDot(at: first, color: UIColor(red: 0.31, green: 0.76, blue: 0.54, alpha: 1))
            }
            if let last = points.last {
                drawDot(at: last, color: UIColor(red: 0.92, green: 0.35, blue: 0.54, alpha: 1))
            }
        }
    }

    private static func drawDot(at point: CGPoint, color: UIColor) {
        let r: CGFloat = 10
        let rect = CGRect(x: point.x - r, y: point.y - r, width: r * 2, height: r * 2)
        UIColor.white.setFill()
        UIBezierPath(ovalIn: rect.insetBy(dx: -3, dy: -3)).fill()
        color.setFill()
        UIBezierPath(ovalIn: rect).fill()
    }
}
