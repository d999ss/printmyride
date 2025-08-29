import SwiftUI

struct ExportSheet: View {
    let design: PosterDesign
    let route: GPXRoute?
    var onExport: ((URL) -> Void)? = nil

    @State private var format: String = "PNG" // PNG | PDF
    @State private var dpi: Int = 300
    @State private var bleed: Double = 0.0
    @State private var includeGrid: Bool = true
    @State private var exporting = false
    @State private var errorText: String?
    @State private var progress: Double = 0.0

    var body: some View {
        NavigationStack {
            Form {
                Section("Format") {
                    Picker("Type", selection: $format) {
                        Text("PNG").tag("PNG")
                        Text("PDF").tag("PDF")
                    }.pickerStyle(.segmented)
                    if format == "PNG" {
                        Stepper("DPI \(dpi)", value: $dpi, in: 150...600, step: 25)
                    }
                }
                Section("Bleed") {
                    Picker("Amount", selection: $bleed) {
                        Text("None").tag(0.0)
                        Text("0.125 in").tag(0.125)
                        Text("0.25 in").tag(0.25)
                    }.pickerStyle(.segmented)
                }
                Section("Options") {
                    Toggle("Include grid", isOn: $includeGrid)
                }
                
                if exporting {
                    Section {
                        VStack {
                            ProgressView(value: progress)
                            Text("Exporting...")
                                .font(DesignTokens.FontToken.footnote)
                                .foregroundStyle(DesignTokens.ColorToken.secondary)
                        }
                    }
                }
                
                if let err = errorText {
                    Text(err).foregroundStyle(.red)
                }
            }
            .navigationTitle("Export")
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button(exporting ? "Exporting…" : "Export") { exportTapped() }.disabled(exporting)
                }
                ToolbarItem(placement: .cancellationAction) { Button("Close") { dismiss() } }
            }
        }
    }

    @Environment(\.dismiss) private var dismiss

    private func exportTapped() {
        UISelectionFeedbackGenerator().selectionChanged()
        exporting = true; progress = 0; errorText = nil

        Task(priority: .userInitiated) {
            var data: Data?
            if format == "PNG" {
                await MainActor.run { progress = 0.1 }
                data = await PosterExport.pngAsync(design: design, route: route, dpi: dpi,
                                                   bleedInches: bleed, includeGrid: includeGrid)
                await MainActor.run { progress = 0.95 }
            } else {
                await MainActor.run { progress = 0.1 }
                data = await PosterExport.pdfAsync(design: design, route: route,
                                                   bleedInches: bleed, includeGrid: includeGrid)
                await MainActor.run { progress = 0.95 }
            }

            await MainActor.run {
                guard let data else {
                    exporting = false
                    UINotificationFeedbackGenerator().notificationOccurred(.error)
                    errorText = "Export failed."
                    return
                }
                let dir = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
                    .appendingPathComponent("Exports", isDirectory: true)
                try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
                let ext = (format == "PNG") ? "png" : "pdf"
                let url = dir.appendingPathComponent("PMR-\(Int(Date().timeIntervalSince1970)).\(ext)")

                do {
                    try data.write(to: url, options: .atomic)
                    progress = 1.0; exporting = false
                    UINotificationFeedbackGenerator().notificationOccurred(.success)
                    let card = ShareCard.generate(design: design, route: route, title: "My Ride")
                    ShareSheet.present(fileURL: url, previewPNGData: card)
                    onExport?(url)
                    dismiss()
                } catch {
                    exporting = false
                    UINotificationFeedbackGenerator().notificationOccurred(.error)
                    errorText = "Could not save file."
                }
            }
        }
    }
}
