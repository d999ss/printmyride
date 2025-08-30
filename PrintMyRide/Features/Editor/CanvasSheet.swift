import SwiftUI

enum PaperPreset: String, CaseIterable, Identifiable {
    case _18x24, _24x36, A2
    var id: String { rawValue }
    var label: String {
        switch self { case ._18x24: "18×24"; case ._24x36: "24×36"; case .A2: "A2" }
    }
    var size: CGSize {
        switch self {
        case ._18x24: .init(width: 18, height: 24)
        case ._24x36: .init(width: 24, height: 36)
        case .A2:     .init(width: 16.54, height: 23.39)
        }
    }
    static func from(_ s: CGSize, tol: CGFloat = 0.1) -> PaperPreset {
        if abs(s.width-18) < tol && abs(s.height-24) < tol { return ._18x24 }
        if abs(s.width-24) < tol && abs(s.height-36) < tol { return ._24x36 }
        return .A2
    }
}

struct CanvasSheet: View {
    @Binding var design: PosterDesign
    @Environment(\.dismiss) private var dismiss
    @AppStorage("showHUD") private var showHUD = true
    @AppStorage("showMapBackground") private var showMapBackground = false
    @AppStorage("mapBackdropStyle") private var mapBackdropStyle = 0
    @AppStorage("activePosterStyle") private var activeStyleID: String = "gallery/pyrenees"
    @State private var preset: PaperPreset

    var pushUndo: (PosterDesign) -> Void = { _ in }

    init(design: Binding<PosterDesign>, pushUndo: @escaping (PosterDesign)->Void = { _ in }) {
        _design = design
        _preset = State(initialValue: PaperPreset.from(design.wrappedValue.paperSize))
        self.pushUndo = pushUndo
    }

    var body: some View {
        NavigationStack {
            List {
                
                Section("Paper Preset") {
                    Picker("", selection: $preset) {
                        ForEach(PaperPreset.allCases) { p in Text(p.label).tag(p) }
                    }
                    .pickerStyle(.segmented)
                    .onChange(of: preset) { p in
                        pushUndo(design); design.paperSize = p.size
                    }
                }

                Section("Paper Size") {
                    // Width
                    HStack { Text("Width"); Spacer()
                        Text("\(Int(design.paperSize.width))\"").font(DesignTokens.FontToken.monoFootnote).foregroundStyle(.secondary)
                    }
                    Slider(value: Binding(
                        get: { design.paperSize.width },
                        set: { newVal in pushUndo(design); design.paperSize.width = newVal }
                    ), in: 8...36, step: 0.5)

                    // Height
                    HStack { Text("Height"); Spacer()
                        Text("\(Int(design.paperSize.height))\"").font(DesignTokens.FontToken.monoFootnote).foregroundStyle(.secondary)
                    }
                    Slider(value: Binding(
                        get: { design.paperSize.height },
                        set: { newVal in pushUndo(design); design.paperSize.height = newVal }
                    ), in: 12...72, step: 0.5)
                }

                Section("Margins") {
                    HStack { Text("Margins"); Spacer()
                        Text("\(Int(design.margins*100))%").font(DesignTokens.FontToken.monoFootnote).foregroundStyle(.secondary)
                    }
                    Slider(value: $design.margins, in: 0...0.2)
                }

                Section("Grid") {
                    Toggle("Show grid", isOn: $design.showGrid)
                    if design.showGrid {
                        HStack { Text("Grid spacing"); Spacer()
                            Text("\(Int(design.gridSpacing)) pt").font(DesignTokens.FontToken.monoFootnote).foregroundStyle(.secondary)
                        }
                        Slider(value: $design.gridSpacing, in: 10...200, step: 10)
                    }
                    Toggle("Show info HUD", isOn: $showHUD)
                }

                Section("Poster Style") {
                    Picker("Poster", selection: $activeStyleID) {
                        ForEach(StyleRegistry.all) { s in
                            Text(s.name).tag(s.id)
                        }
                    }.pickerStyle(.segmented)
                }
                
                Section("Backdrop (preview)") {
                    Toggle("Map background", isOn: $showMapBackground)
                    if showMapBackground {
                        Picker("Style", selection: $mapBackdropStyle) {
                            Text("Standard").tag(0)
                            Text("Hybrid").tag(1)
                            Text("Satellite").tag(2)
                        }.pickerStyle(.segmented)
                        Text("Map is preview-only. Exports remain clean unless you choose to include map later.")
                            .font(.footnote).foregroundStyle(.secondary)
                    }
                }
            }
            .navigationTitle("Canvas")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}