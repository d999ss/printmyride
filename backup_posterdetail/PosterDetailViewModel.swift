// PrintMyRide/UI/PosterDetail/PosterDetailViewModel.swift
import SwiftUI
import UIKit
import MapKit
import os.log

@MainActor
final class PosterDetailViewModel: ObservableObject {
    // MARK: - Published State
    @Published var generatedImage: UIImage?
    @Published var isGenerating = false
    @Published var toast: ToastMessage?
    @Published var isFavorite = false
    @Published var selectedPresetIndex = 0
    
    // MARK: - Settings
    @AppStorage("useOptimizedRenderer") var useOptimizedRenderer = true
    @AppStorage("pmr.useMapBackground") var useMapBackground = true
    @AppStorage("pmr.mapStyle") var mapStyle = 0
    @AppStorage("pmr.units") var units = "mi"
    
    // MARK: - Dependencies
    private let renderService: EnhancedPosterRenderServiceProtocol
    private let logger = Logger(subsystem: "PMR", category: "PosterDetail")
    
    // MARK: - Data
    var rideData: RideData = RideData()
    let stylePresets = PosterStylePresets.standard
    
    init(renderService: EnhancedPosterRenderServiceProtocol = EnhancedPosterRenderServiceFactory.create()) {
        self.renderService = renderService
    }
    
    // MARK: - Current Preset
    var currentPreset: PosterPreset {
        stylePresets.presets.indices.contains(selectedPresetIndex) 
            ? stylePresets.presets[selectedPresetIndex] 
            : stylePresets.presets[0]
    }
    
    // MARK: - Render Pipeline
    func render(size: CGSize) async {
        guard !rideData.coordinates.isEmpty else { 
            logger.warning("Cannot render: no coordinates available")
            return 
        }
        
        logger.info("Starting poster render with size: \(size)")
        
        isGenerating = true
        defer { isGenerating = false }
        
        let renderRequest = PosterRenderRequest(
            preset: currentPreset,
            rideData: rideData,
            canvasSize: size.width > 0 ? size : CGSize(width: 1200, height: 1600),
            useMapBackground: useMapBackground,
            mapStyle: mapStyle,
            useOptimizedRenderer: useOptimizedRenderer
        )
        
        do {
            let image = try await renderService.renderPoster(request: renderRequest)
            generatedImage = image
            logger.info("Poster render completed successfully")
        } catch {
            logger.error("Poster render failed: \(error)")
            showToast(.error("Render failed: \(error.localizedDescription)"))
        }
    }
    
    // MARK: - Actions
    func exportPDF() {
        showToast(.info("Export started"))
        
        Task {
            // Simulate export process
            try await Task.sleep(nanoseconds: 800_000_000)
            await MainActor.run {
                showToast(.success("PDF saved"))
            }
        }
    }
    
    func saveMapSnapshot() {
        showToast(.success("Map snapshot saved"))
    }
    
    func shareImage() {
        guard let image = generatedImage else {
            showToast(.error("No image to share"))
            return
        }
        
        // Implementation would use UIActivityViewController
        showToast(.info("Sharing..."))
    }
    
    func printPoster() {
        showToast(.info("Print flow demo"))
    }
    
    // MARK: - Toast Management
    private func showToast(_ message: ToastMessage) {
        toast = message
        
        Task {
            try await Task.sleep(nanoseconds: 2_000_000_000) // 2 seconds
            await MainActor.run {
                if toast == message {
                    toast = nil
                }
            }
        }
    }
}

// MARK: - Supporting Types
struct RideData {
    var title: String = "Unnamed Ride"
    var subtitle: String = ""
    var coordinates: [CLLocationCoordinate2D] = []
    var distanceMeters: Double = 0
    var elevationMeters: Double = 0
    var durationSeconds: Double = 0
    var date: Date = Date()
}

enum ToastMessage: Equatable {
    case info(String)
    case success(String)
    case error(String)
    
    var text: String {
        switch self {
        case .info(let text), .success(let text), .error(let text):
            return text
        }
    }
    
    var color: Color {
        switch self {
        case .info: return .blue
        case .success: return .green
        case .error: return .red
        }
    }
}

struct PosterRenderRequest {
    let preset: PosterPreset
    let rideData: RideData
    let canvasSize: CGSize
    let useMapBackground: Bool
    let mapStyle: Int
    let useOptimizedRenderer: Bool
}