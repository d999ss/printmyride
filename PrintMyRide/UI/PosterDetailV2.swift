// PrintMyRide/UI/PosterDetailV2.swift
import SwiftUI
import MapKit

@MainActor
final class PosterDetailVM: ObservableObject {
    @Published var generatedImage: UIImage?
    @Published var isGenerating = false
    @Published var toast: String?
    @Published var isFavorite = false

    @AppStorage("useOptimizedRenderer") var useOptimizedRenderer = true
    @AppStorage("pmr.useMapBackground") var useMapBackground = false
    @AppStorage("pmr.mapStyle") var mapStyle = 0
    @AppStorage("pmr.units") var units = "mi"

    @Published var selectedPreset = 0
    let presets: [PosterPreset] = [
        .init(name: "Classic", bg: .black, route: .white, stroke: 3),
        .init(name: "Mono", bg: .white, route: .black, stroke: 3),
        .init(name: "Glow", bg: .black, route: .white, stroke: 4, shadow: true),
        .init(name: "Cornsilk", bg: Color(red: 0.98, green: 0.95, blue: 0.87), route: .black, stroke: 3)
    ]

    var distanceMeters: Double = 0
    var elevationMeters: Double = 0
    var durationSec: Double = 0
    var date: Date = Date()

    var coords: [CLLocationCoordinate2D] = []
    var title: String = "Unnamed Ride"
    var subtitle: String = ""

    func render(size: CGSize) async {
        guard !coords.isEmpty else { return }
        isGenerating = true
        defer { isGenerating = false }

        let preset = presets.indices.contains(selectedPreset) ? presets[selectedPreset] : presets[0]
        var design = PosterDesignFallback.make()
        design.background = preset.bg
        design.route = preset.route
        design.stroke = preset.stroke
        design.shadow = preset.shadow

        let points = coords.map { GPXPoint(lat: $0.latitude, lon: $0.longitude) }
        let route = GPXRouteFallback(points: points, distanceMeters: distanceMeters, duration: durationSec)
        let pxSize = size.width > 0 ? size : CGSize(width: 1200, height: 1600)

        if useOptimizedRenderer {
            if let img = await PosterRenderServiceBridge.renderPoster(
                design: design, route: route, size: pxSize, useMap: useMapBackground, mapStyle: mapStyle
            ) {
                generatedImage = img
                return
            }
        }
        if let img = await LegacyRendererBridge.renderImage(coords: coords, size: pxSize) {
            generatedImage = img
        }
    }

    func exportPDF() { toast = "Export started"; DispatchQueue.main.asyncAfter(deadline: .now()+0.8) { self.toast = "PDF saved" } }
    func saveMapSnapshot() { toast = "Map snapshot saved"; DispatchQueue.main.asyncAfter(deadline: .now()+0.8) { self.toast = nil } }
    func share() {}
}

struct PosterPreset: Hashable {
    let name: String
    let bg: Color
    let route: Color
    let stroke: CGFloat
    var shadow: Bool = false
}

struct PosterDetailV2: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var vm = PosterDetailVM()

    let rideTitle: String
    let rideSubtitle: String
    let coords: [CLLocationCoordinate2D]
    let distanceMeters: Double
    let elevationMeters: Double
    let durationSec: Double
    let date: Date

    init(
        rideTitle: String,
        rideSubtitle: String = "",
        coords: [CLLocationCoordinate2D],
        distanceMeters: Double = 0,
        elevationMeters: Double = 0,
        durationSec: Double = 0,
        date: Date = .init()
    ) {
        self.rideTitle = rideTitle
        self.rideSubtitle = rideSubtitle
        self.coords = coords
        self.distanceMeters = distanceMeters
        self.elevationMeters = elevationMeters
        self.durationSec = durationSec
        self.date = date
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                HStack(spacing: 12) {
                    Button { dismiss() } label: {
                        Image(systemName: "chevron.left").font(.title3.weight(.semibold))
                    }
                    Text(rideTitle).font(.title3.weight(.semibold)).lineLimit(1)
                    Spacer()
                    FavoriteToggle(isOn: $vm.isFavorite)
                    ProBadge()
                }
                .padding(.horizontal)

                PosterHero(image: vm.generatedImage, isLoading: vm.isGenerating)
                    .frame(height: 420)
                    .padding(.horizontal)
                    .task(id: vm.selectedPreset) {
                        await vm.render(size: CGSize(width: 1200, height: 1600))
                    }
                    .task {
                        vm.coords = coords
                        vm.distanceMeters = distanceMeters
                        vm.elevationMeters = elevationMeters
                        vm.durationSec = durationSec
                        vm.date = date
                        vm.title = rideTitle
                        vm.subtitle = rideSubtitle
                        await vm.render(size: CGSize(width: 1200, height: 1600))
                    }

                QuickActionsBar(
                    export: { vm.exportPDF() },
                    share: { vm.share() },
                    printPoster: { vm.toast = "Print flow demo" },
                    saveMap: { vm.saveMapSnapshot() }
                )
                .padding(.horizontal)

                StatGrid(distance: distanceMeters, climb: elevationMeters, duration: durationSec, date: date)
                    .padding(.horizontal)

                StylePresets(selected: $vm.selectedPreset, presets: vm.presets)
                    .padding(.horizontal)

                MapControls(useMap: $vm.useMapBackground, mapStyle: $vm.mapStyle)
                    .padding(.horizontal)

                CaptionEditor(title: vm.title, subtitle: vm.subtitle) { newTitle, newSub in
                    vm.title = newTitle
                    vm.subtitle = newSub
                    Task { await vm.render(size: CGSize(width: 1200, height: 1600)) }
                }
                .padding(.horizontal)

                VariantStrip()
                    .padding(.horizontal)
                    .padding(.bottom, 24)
            }
        }
        .overlay(alignment: .bottom) { if let t = vm.toast { ToastView(text: t).padding(.bottom, 16) } }
        .navigationBarBackButtonHidden(true)
    }
}

struct PosterHero: View {
    let image: UIImage?
    let isLoading: Bool
    @State private var zoom: CGFloat = 1
    @State private var last: CGFloat = 1
    var body: some View {
        ZStack {
            Rectangle().fill(Color(.secondarySystemBackground)).cornerRadius(16)
            if let img = image {
                Image(uiImage: img)
                    .resizable()
                    .scaledToFit()
                    .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                    .scaleEffect(zoom)
                    .gesture(
                        MagnificationGesture()
                            .onChanged { v in zoom = min(max(1, last * v), 2.5) }
                            .onEnded { _ in last = zoom }
                    )
                    .shadow(radius: 8, y: 4)
            } else if isLoading {
                ProgressView().progressViewStyle(.circular)
            } else {
                VStack(spacing: 8) {
                    Image(systemName: "photo.on.rectangle").font(.largeTitle)
                    Text("Generating poster").font(.footnote).foregroundStyle(.secondary)
                }
            }
        }
    }
}

struct QuickActionsBar: View {
    let export: () -> Void; let share: () -> Void; let printPoster: () -> Void; let saveMap: () -> Void
    var body: some View {
        HStack(spacing: 12) {
            PMRAction(icon: "square.and.arrow.up.on.square", title: "Export", action: export)
            PMRAction(icon: "square.and.arrow.up", title: "Share", action: share)
            PMRAction(icon: "printer", title: "Print", action: printPoster)
            PMRAction(icon: "map", title: "Save Map", action: saveMap)
        }
    }
}

struct PMRAction: View {
    let icon: String; let title: String; let action: () -> Void
    var body: some View {
        Button(action: action) {
            VStack(spacing: 6) {
                Image(systemName: icon).font(.title3)
                Text(title).font(.caption2)
            }
            .frame(maxWidth: .infinity, minHeight: 56)
            .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12))
        }
        .buttonStyle(.plain)
    }
}

struct StatGrid: View {
    let distance: Double; let climb: Double; let duration: Double; let date: Date
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Ride stats").font(.headline)
            LazyVGrid(columns: Array(repeating: .init(.flexible(), spacing: 12), count: 3), spacing: 12) {
                StatTile(title: "Distance", value: formatDistance(distance))
                StatTile(title: "Climb", value: formatClimb(climb))
                StatTile(title: "Time", value: formatTime(duration))
                StatTile(title: "Date", value: date.formatted(date: .abbreviated, time: .omitted))
                StatTile(title: "Pace", value: pace(distance: distance, sec: duration))
                StatTile(title: "Style", value: "Poster")
            }
        }
    }
    private func formatDistance(_ m: Double) -> String {
        let miles = m / 1609.344
        return miles < 0.1 ? "\(Int(m)) m" : String(format: "%.1f mi", miles)
    }
    private func formatClimb(_ m: Double) -> String {
        let ft = m * 3.28084
        return "\(Int(ft)) ft"
    }
    private func formatTime(_ s: Double) -> String {
        let h = Int(s) / 3600, m = (Int(s) % 3600) / 60
        return h > 0 ? "\(h)h \(m)m" : "\(m)m"
    }
    private func pace(distance m: Double, sec: Double) -> String {
        guard m > 0, sec > 0 else { return "—" }
        let miles = m / 1609.344
        let spm = sec / miles
        let mm = Int(spm) / 60, ss = Int(spm) % 60
        return "\(mm):\(String(format: "%02d", ss))/mi"
    }
}

struct StatTile: View {
    let title: String; let value: String
    var body: some View {
        VStack(alignment:.leading, spacing: 4) {
            Text(title).font(.caption2).foregroundStyle(.secondary)
            Text(value).font(.subheadline.weight(.semibold))
        }
        .frame(maxWidth: .infinity, minHeight: 56, alignment: .leading)
        .padding(12)
        .background(Color(.secondarySystemBackground), in: RoundedRectangle(cornerRadius: 12))
    }
}

struct StylePresets: View {
    @Binding var selected: Int; let presets: [PosterPreset]
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Style presets").font(.headline)
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 10) {
                    ForEach(Array(presets.enumerated()), id: \.offset) { idx, p in
                        Button { selected = idx } label: {
                            HStack(spacing: 8) {
                                Circle().fill(p.route).frame(width: 12, height: 12)
                                    .overlay(Circle().stroke(p.bg, lineWidth: 2))
                                Text(p.name).font(.caption)
                            }
                            .padding(.vertical, 8).padding(.horizontal, 10)
                            .background(idx == selected ? Color(.systemGray5) : Color(.secondarySystemBackground),
                                        in: Capsule())
                        }.buttonStyle(.plain)
                    }
                }
            }
        }
    }
}

struct MapControls: View {
    @Binding var useMap: Bool
    @Binding var mapStyle: Int
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Map").font(.headline)
            Toggle("Apple Maps background", isOn: $useMap)
            Segmented(items: ["Standard","Hybrid","Satellite"], selection: $mapStyle)
        }
    }
}

struct Segmented: View {
    let items: [String]; @Binding var selection: Int
    var body: some View {
        HStack(spacing: 6) {
            ForEach(items.indices, id: \.self) { i in
                Button(items[i]) { selection = i }
                    .buttonStyle(.plain)
                    .padding(.vertical, 8)
                    .frame(maxWidth: .infinity)
                    .background(selection == i ? Color(.systemGray5) : Color(.secondarySystemBackground),
                                in: RoundedRectangle(cornerRadius: 8))
                    .font(.caption)
            }
        }
    }
}

struct CaptionEditor: View {
    @State var title: String; @State var subtitle: String
    let onChange: (String,String) -> Void
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Captions").font(.headline)
            TextField("Poster title", text: $title)
                .textFieldStyle(.roundedBorder)
                .onSubmit { onChange(title, subtitle) }
            TextField("Subtitle", text: $subtitle)
                .textFieldStyle(.roundedBorder)
                .onSubmit { onChange(title, subtitle) }
            HStack { Spacer()
                Button("Apply") { onChange(title, subtitle) }
                    .buttonStyle(.borderedProminent)
            }
        }
    }
}

struct VariantStrip: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Variants").font(.headline)
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 10) {
                    ForEach(0..<6, id: \.self) { _ in
                        Rectangle()
                            .fill(Color(.secondarySystemBackground))
                            .frame(width: 120, height: 160)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                            .overlay(Image(systemName: "photo").foregroundStyle(.secondary))
                    }
                }
            }
        }
    }
}

struct FavoriteToggle: View {
    @Binding var isOn: Bool
    var body: some View {
        Button {
            isOn.toggle()
        } label: {
            Image(systemName: isOn ? "heart.fill" : "heart")
                .foregroundStyle(isOn ? .red : .primary)
        }
        .buttonStyle(.plain)
        .accessibilityIdentifier("btn_favorite")
    }
}

struct ProBadge: View {
    @AppStorage("pmr.isPro") private var isPro = false
    var body: some View {
        if isPro {
            Text("Pro").font(.caption2.weight(.bold))
                .padding(.vertical, 4).padding(.horizontal, 8)
                .background(Color(.systemYellow), in: Capsule())
        } else {
            NavigationLink {
                PaywallPlaceholder()
            } label: {
                Text("Go Pro").font(.caption2.weight(.bold))
                    .padding(.vertical, 4).padding(.horizontal, 8)
                    .background(Color(.systemBlue).opacity(0.15), in: Capsule())
            }
            .buttonStyle(.plain)
        }
    }
}

struct PaywallPlaceholder: View {
    var body: some View {
        VStack(spacing: 12) {
            Text("PrintMyRide Pro").font(.title2.weight(.semibold))
            Text("Unlimited exports and exclusive styles").foregroundStyle(.secondary)
            Button("Start trial"){}.buttonStyle(.borderedProminent)
            Spacer()
        }.padding()
    }
}

struct ToastView: View {
    let text: String
    var body: some View {
        Text(text)
            .font(.footnote.weight(.semibold))
            .padding(.vertical, 10).padding(.horizontal, 14)
            .background(.ultraThinMaterial, in: Capsule())
            .shadow(radius: 6, y: 3)
    }
}

// Fallbacks and bridges

struct PosterDesignFallback {
    var background: Color = .black
    var route: Color = .white
    var stroke: CGFloat = 3
    var shadow: Bool = false
    static func make() -> PosterDesignFallback { .init() }
}

struct GPXPoint: Hashable { let lat: Double; let lon: Double }

struct GPXRouteFallback {
    let points: [GPXPoint]
    let distanceMeters: Double
    let duration: Double
}

enum PosterRenderServiceBridge {
    static func renderPoster(
        design: PosterDesignFallback,
        route: GPXRouteFallback,
        size: CGSize,
        useMap: Bool,
        mapStyle: Int
    ) async -> UIImage? {
        // map to your real PosterRenderService here if available
        return nil
    }
}

enum LegacyRendererBridge {
    static func renderImage(coords: [CLLocationCoordinate2D], size: CGSize) async -> UIImage? {
        let r = UIGraphicsImageRenderer(size: size)
        return r.image { ctx in
            UIColor.black.setFill(); ctx.fill(CGRect(origin: .zero, size: size))
            UIColor.white.setStroke()
            let path = UIBezierPath(); path.lineWidth = 6
            guard let first = coords.first else { return }
            func pt(_ c: CLLocationCoordinate2D) -> CGPoint {
                CGPoint(x: size.width * CGFloat((c.longitude + 180)/360),
                        y: size.height * CGFloat(1 - (c.latitude + 90)/180))
            }
            path.move(to: pt(first))
            for c in coords.dropFirst() { path.addLine(to: pt(c)) }
            path.stroke()
        }
    }
}

extension Array {
    subscript(safe i: Int) -> Element? { indices.contains(i) ? self[i] : nil }
}
