import SwiftUI
import CoreLocation
import StoreKit
import UIKit
import MapKit

struct PosterDetailView: View {
    let poster: Poster
    private var coords: [CLLocationCoordinate2D] { 
        poster.coordinates ?? DemoCoordsLoader.coords(forTitle: poster.title) 
    } // pass parsed GPX coords if available
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var gate: SubscriptionGate
    @State private var exporting = false
    @State private var exportMessage: String?
    @State private var showPaywall = false
    @AppStorage("pmr.useMapBackground") private var useMapBackground: Bool = true
    @AppStorage("useOptimizedRenderer") private var useOptimizedRenderer = true
    @State private var generatedPosterImage: UIImage?
    @State private var isGeneratingPoster = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                // Full preview with self-healing
                Group {
                    if let generatedImage = generatedPosterImage {
                        Image(uiImage: generatedImage)
                            .resizable()
                            .scaledToFit()
                    } else {
                        AsyncImage(url: documentsURL().appendingPathComponent(poster.filePath)) { phase in
                            switch phase {
                            case .success(let img): 
                                img.resizable().scaledToFit()
                            default: 
                                ZStack {
                                    Color.black.opacity(0.1)
                                    if isGeneratingPoster {
                                        VStack(spacing: 12) {
                                            ProgressView()
                                                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                            Text("Generating poster...")
                                                .font(.caption)
                                                .foregroundColor(.white)
                                        }
                                    } else {
                                        Button("Generate Poster Image") {
                                            Task { await generatePosterImage() }
                                        }
                                        .buttonStyle(.borderedProminent)
                                    }
                                }
                            }
                        }
                        .task {
                            // Auto-generate if missing
                            await autoGeneratePosterIfMissing()
                        }
                    }
                }
                .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))

                // Route Map Preview
                if !coords.isEmpty {
                    PMRCard {
                        VStack(alignment: .leading, spacing: 12) {
                            HStack {
                                Text("Route Map")
                                    .font(DesignTokens.Typography.headline)
                                Spacer()
                                if useMapBackground {
                                    Image(systemName: "checkmark.seal.fill")
                                        .foregroundStyle(.green)
                                        .font(.caption)
                                }
                            }
                            
                            RouteMapView(coords: coords)
                                .frame(height: 200)
                                .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                            
                            HStack(spacing: 12) {
                                Button("Open in Apple Maps") {
                                    openInMaps()
                                }
                                .buttonStyle(.bordered)
                                .controlSize(.small)
                                
                                Button("Save Map Snapshot for Poster") {
                                    saveMapSnapshot()
                                }
                                .buttonStyle(.bordered)
                                .controlSize(.small)
                            }
                        }
                    }
                }

                // Metrics row (best-effort from coords)
                PMRCard {
                    HStack(spacing: 10) {
                        let s = StatsExtractor.compute(coords: coords, elevations: [], timestamps: nil)
                        MetricPill(icon: "map", text: s.distanceKm > 0 ? String(format: "%.1f km", s.distanceKm) : "Demo")
                        if let dur = s.durationSec, dur > 0 {
                            let h = Int(dur/3600), m = Int((dur.truncatingRemainder(dividingBy: 3600))/60)
                            MetricPill(icon: "clock", text: h > 0 ? "\(h)h \(m)m" : "\(m)m")
                        } else {
                            MetricPill(icon: "clock", text: "—")
                        }
                        if s.ascentM > 0 {
                            MetricPill(icon: "mountain.2", text: "\(Int(s.ascentM)) m ↑")
                        }
                        Spacer()
                    }
                }

                // Actions
                VStack(spacing: 10) {
                    Button("Export High-Res (PDF)") {
                        if gate.isSubscribed { Task { await exportPDF(inches: CGSize(width: 18, height: 24)) } }
                        else { 
                            PMRLog.export.warning("[Export] blocked by unsubscribed state for \(poster.title, privacy: .public)")
                            showPaywall = true 
                        }
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(exporting)

                    NavigationLink("Print Poster (Demo Checkout)") {
                        MockCheckoutView(poster: poster)
                    }.buttonStyle(.bordered)

                    Button("Share Poster Image") {
                        let url = documentsURL().appendingPathComponent(poster.filePath)
                        if let img = UIImage(contentsOfFile: url.path) {
                            Haptics.tap()
                            ShareSheet.present(items: [img])
                        }
                    }.buttonStyle(.bordered)
                }

                if let msg = exportMessage {
                    Text(msg).font(.footnote).foregroundStyle(.secondary)
                }
            }
            .padding(16)
        }
        .navigationTitle(poster.title)
        .sheet(isPresented: $showPaywall) {
            PaywallCardView().environmentObject(gate)
        }
    }

    private func exportPDF(inches: CGSize) async {
        if !gate.isSubscribed {
            exportMessage = "Subscription required for high-res export."
            return
        }
        exporting = true
        defer { exporting = false }
        
        // 300 DPI size
        let pixelSize = CGSize(width: inches.width * 300, height: inches.height * 300)
        
        // Use existing RouteRenderer to create high-res image
        guard let posterImage = await RouteRenderer.renderPoster(
            coordinates: coords,
            title: poster.title,
            distance: "Distance", // TODO: compute from coords if needed
            duration: "Duration", // TODO: compute from time if needed
            date: poster.createdAt.formatted(date: .abbreviated, time: .omitted),
            size: pixelSize,
            style: .standard,
            useMapBackground: useMapBackground
        ) else {
            exportMessage = "Failed to render poster."
            return
        }
        
        // Export as PDF
        let url = documentsURL().appendingPathComponent("PMR_\(poster.title.replacingOccurrences(of: " ", with: "_"))_\(Int(Date().timeIntervalSince1970)).pdf")
        do {
            try await exportImageAsPDF(image: posterImage, to: url)
            exportMessage = "Saved: \(url.lastPathComponent)"
        } catch {
            exportMessage = "Export failed: \(error.localizedDescription)"
        }
    }
    
    private func exportImageAsPDF(image: UIImage, to url: URL) async throws {
        try await Task {
            let pdfData = NSMutableData()
            UIGraphicsBeginPDFContextToData(pdfData, CGRect(origin: .zero, size: image.size), nil)
            UIGraphicsBeginPDFPage()
            image.draw(in: CGRect(origin: .zero, size: image.size))
            UIGraphicsEndPDFContext()
            try pdfData.write(to: url)
        }.value
    }

    private func documentsURL() -> URL {
        FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
    }
    
    private func openInMaps() {
        guard !coords.isEmpty else { return }
        
        // Create region for the route
        let region = RouteMapHelpers.region(fitting: coords)
        
        // Create map item for the route
        let placemark = MKPlacemark(coordinate: region.center)
        let mapItem = MKMapItem(placemark: placemark)
        mapItem.name = poster.title
        
        // Open in Maps with directions
        let launchOptions: [String: Any] = [
            MKLaunchOptionsMapTypeKey: MKMapType.standard.rawValue,
            MKLaunchOptionsMapCenterKey: NSValue(mkCoordinate: region.center),
            MKLaunchOptionsMapSpanKey: NSValue(mkCoordinateSpan: region.span)
        ]
        
        mapItem.openInMaps(launchOptions: launchOptions)
        Haptics.tap()
    }
    
    private func saveMapSnapshot() {
        guard !coords.isEmpty else { return }
        
        Task {
            if let image = await MapSnapshotper.snapshot(coords: coords, size: CGSize(width: 1200, height: 800)) {
                await MainActor.run {
                    // Save to photo library
                    UIImageWriteToSavedPhotosAlbum(image, nil, nil, nil)
                    exportMessage = "Map snapshot saved to Photos"
                    PMRLog.maps.log("[MapSnapshot] saved for \(poster.title, privacy: .public)")
                    Haptics.success()
                }
            } else {
                await MainActor.run {
                    exportMessage = "Failed to create map snapshot"
                    ErrorBus.shared.report("[MapSnapshot] nil image for \(poster.title)")
                }
            }
        }
    }
    
    // MARK: - Self-Healing Poster Generation
    
    private func autoGeneratePosterIfMissing() async {
        // Only auto-generate if the file doesn't exist
        let posterURL = documentsURL().appendingPathComponent(poster.filePath)
        
        // Check if file exists and is valid
        if FileManager.default.fileExists(atPath: posterURL.path),
           let _ = UIImage(contentsOfFile: posterURL.path) {
            return // Poster exists and is valid
        }
        
        // Auto-generate missing poster
        await generatePosterImage()
    }
    
    @MainActor
    private func generatePosterImage() async {
        guard !coords.isEmpty else { return }
        
        isGeneratingPoster = true
        defer { isGeneratingPoster = false }
        
        // Generate beautiful artistic poster instead of basic map
        generatedPosterImage = await ArtisticPosterRenderer.renderArtisticPoster(
            title: poster.title,
            coordinates: coords,
            distance: "14.2 MI", // TODO: Calculate from coords
            duration: "1H 23M", // TODO: Calculate from data
            elevation: "2,847 FT", // TODO: Calculate elevation gain
            date: poster.createdAt.formatted(date: .abbreviated, time: .omitted),
            location: "Colorado", // TODO: Reverse geocode from coords
            style: .minimalist,
            palette: .monochrome,
            size: CGSize(width: 800, height: 1200) // Portrait poster
        )
        
        // Save generated image to disk
        if let image = generatedPosterImage {
            await savePosterToDisk(image: image)
            exportMessage = "✅ Beautiful artistic poster generated successfully"
        } else {
            exportMessage = "❌ Failed to generate artistic poster"
        }
    }
    
    private func createPosterDesign() -> PosterDesign {
        var design = PosterDesign()
        design.paperSize = CGSize(width: 8, height: 10) // 8x10 inches
        design.backgroundColor = .black
        design.routeColor = .white
        design.strokeWidthPt = 3.0
        // Note: margins property might need different format depending on PosterDesign structure
        return design
    }
    
    private func savePosterToDisk(image: UIImage) async {
        guard let imageData = image.jpegData(compressionQuality: 0.9) else { return }
        
        let posterURL = documentsURL().appendingPathComponent(poster.filePath)
        
        do {
            try imageData.write(to: posterURL)
            PMRLog.export.log("[SelfHealing] Generated and saved poster for \(poster.title)")
        } catch {
            PMRLog.export.error("[SelfHealing] Failed to save poster: \(error)")
        }
    }
}