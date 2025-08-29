import SwiftUI
import UniformTypeIdentifiers

@MainActor
class EditorState: ObservableObject {
    @Published var route: GPXRoute?
    @Published var design = PosterDesign()
    @Published var showingFileImporter = false
    @Published var showingError = false
    @Published var errorMessage = ""
    
    private var lastImportURL: URL?
    
    // MARK: - Public Methods
    
    func importGPX() {
        showingFileImporter = true
    }
    
    func loadSample() {
        Task {
            do {
                if let url = Bundle.main.url(forResource: "sample", withExtension: "gpx"),
                   let data = try? Data(contentsOf: url) {
                    let parsed = try GPXImporter().parse(data: data)
                    await MainActor.run {
                        self.route = parsed
                        self.fitToScreen()
                    }
                }
            } catch {
                await MainActor.run {
                    self.showError("Failed to load sample: \(error.localizedDescription)")
                }
            }
        }
    }
    
    func loadMountainBike() {
        Task {
            do {
                if let url = Bundle.main.url(forResource: "Afternoon_Mountain_Bike_Ride", withExtension: "gpx"),
                   let data = try? Data(contentsOf: url) {
                    let parsed = try GPXImporter().parse(data: data)
                    await MainActor.run {
                        self.route = parsed
                        self.fitToScreen()
                    }
                }
            } catch {
                await MainActor.run {
                    self.showError("Failed to load mountain bike route: \(error.localizedDescription)")
                }
            }
        }
    }
    
    func clearCanvas() {
        route = nil
        design = PosterDesign()
    }
    
    func fitToScreen() {
        // Canvas fitting handled by zoom state in CanvasView
    }
    
    func export(data: Data) {
        // Export handled by PosterExport async methods
    }
    
    // MARK: - Private Methods
    
    func handleFileImport(_ result: Result<[URL], Error>) {
        switch result {
        case .success(let urls):
            guard let url = urls.first else { return }
            
            Task {
                do {
                    let data = try Data(contentsOf: url)
                    let parsed = try GPXImporter().parse(data: data)
                    
                    await MainActor.run {
                        self.route = parsed
                        self.lastImportURL = url
                        self.fitToScreen()
                    }
                } catch {
                    await MainActor.run {
                        self.showError("Failed to parse GPX file: \(error.localizedDescription)")
                    }
                }
            }
            
        case .failure(let error):
            showError("Import failed: \(error.localizedDescription)")
        }
    }
    
    private func showError(_ message: String) {
        errorMessage = message
        showingError = true
    }
    
    private func makeSubtitle(route: GPXRoute) -> String {
        let km = route.distanceMeters / 1000
        let dur = route.duration ?? 0
        let h = Int(dur) / 3600, m = (Int(dur) % 3600) / 60
        return String(format: "%.1f km  ·  %dh %dm", km, h, m)
    }
}
