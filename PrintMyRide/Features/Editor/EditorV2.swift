import SwiftUI
import UniformTypeIdentifiers

struct EditorV2: View {
    // your state
    @Environment(\.dismiss) private var dismiss
    @State private var design: PosterDesign
    @State private var route: GPXRoute?
    @State private var payload: RoutePayload?
    var onClose: (() -> Void)? = nil                // <— add this
    
    init(initialDesign: PosterDesign = PosterDesign(), initialRoute: GPXRoute? = nil, onClose: (() -> Void)? = nil) {
        _design = State(initialValue: initialDesign)
        _route = State(initialValue: initialRoute)
        _payload = State(initialValue: nil)
        self.onClose = onClose
    }
    
    init(payload: RoutePayload, onClose: (() -> Void)? = nil) {
        _design = State(initialValue: PosterDesign())
        _route  = State(initialValue: nil)
        _payload = State(initialValue: payload)
        self.onClose = onClose
    }

    // panels
    @State private var activePanel: Panel? = nil
    @State private var showingNext = false
    @State private var showStravaSheet = false
    @State private var showPicker = false
    enum Panel { case canvas, importGPX, style, text, map, grid }

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            VStack(spacing: 0) {

                // TOP BAR
                HStack {
                    Button { 
                        if let onClose = onClose {
                            onClose()
                        } else {
                            dismiss()
                        }
                    } label: {
                        Image(systemName: "xmark").font(.system(size: 18, weight: .semibold))
                    }
                    .foregroundStyle(.white)
                    Spacer()
                    Button("Next") { showingNext = true }
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundStyle(.white)
                }
                .padding(.horizontal, 16)
                .frame(height: 44)
                .background(Color.black)       // tactile hit area

                // POSTER AREA
                CenteredPosterContainer(topBarHeight: 44, toolTrayHeight: 80) {
                    PosterPreview(design: design, posterTitle: "My Ride", mode: .editor, route: route, payload: payload)
                }

                // TOOL TRAY
                IconTray(active: $activePanel) {
                    IconButton(system: "rectangle.inset.filled", sel: .canvas,   active: $activePanel)
                    IconButton(system: "bolt.horizontal",        sel: .importGPX,active: $activePanel) // Strava
                    IconButton(system: "paintbrush",             sel: .style,    active: $activePanel)
                    IconButton(system: "textformat",             sel: .text,     active: $activePanel)
                    IconButton(system: "globe.americas",         sel: .map,      active: $activePanel)
                    IconButton(system: "grid",                   sel: .grid,     active: $activePanel)
                }
            }
        }
        .toolbar(.hidden, for: .tabBar)
        .toolbar(.hidden, for: .navigationBar)
        .onAppear {
            // iOS 16 fallback for hiding tab bar
            if #available(iOS 16.0, *) {
                // Already handled by .toolbar(.hidden, for: .tabBar)
            } else {
                UITabBar.appearance().isHidden = true
            }
        }
        .onDisappear {
            if #available(iOS 16.0, *) {
                // Toolbar modifier handles this
            } else {
                UITabBar.appearance().isHidden = false
            }
        }
        // BOTTOM PANELS (compact, like VSCO)
        .overlay(alignment: .bottom) {
            if let p = activePanel { PanelSheet(panel: p,
                                                design: $design,
                                                route: $route,
                                                close: { activePanel = nil }) }
        }
        .sheet(isPresented: $showingNext) {
            NextSheet(design: design, route: route) { showingNext = false }
                .presentationDetents([.fraction(0.38), .large])
        }
        .sheet(isPresented: $showPicker) {
            StravaActivityPicker { act in 
                Task {
                    if let r = try? await StravaService.shared.buildRoute(from: act) { 
                        route = r 
                    }
                } 
            }
        }
        .onChange(of: activePanel) { p in
            if p == .importGPX {
                Task {
                    do {
                        _ = try await StravaService.shared.connect()
                        showPicker = true
                    } catch {}
                    activePanel = nil
                }
            }
        }
    }
}

private struct IconTray<Content: View>: View {
    @Binding var active: EditorV2.Panel?
    @ViewBuilder var content: () -> Content
    var body: some View {
        VStack(spacing: 0) {
            Rectangle().fill(.white.opacity(0.10)).frame(height: 1)
            HStack(spacing: 0) { content() }
                .frame(height: 60)                         // LARGE hit area
                .background(Color.black.ignoresSafeArea(edges: .bottom))
        }
    }
}

private struct IconButton: View {
    let system: String
    let sel: EditorV2.Panel
    @Binding var active: EditorV2.Panel?
    var body: some View {
        Button {
            UISelectionFeedbackGenerator().selectionChanged()
            active = (active == sel ? nil : sel)
        } label: {
            Image(systemName: system)
                .font(.system(size: 20, weight: .regular))
                .foregroundStyle(active == sel ? .white : .white.opacity(0.7))
                .frame(maxWidth: .infinity, maxHeight: .infinity)  // equal widths
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(labelFor(system))   // VSCO look, still accessible
    }
    private func labelFor(_ s: String) -> String {
        switch s {
        case "rectangle.inset.filled": return "Canvas"
        case "bolt.horizontal":        return "Strava"
        case "paintbrush":             return "Style"
        case "textformat":             return "Text"
        case "globe.americas":         return "Map"
        case "grid":                   return "Grid"
        default: return "Button"
        }
    }
}

private struct PanelSheet: View {
    let panel: EditorV2.Panel
    @Binding var design: PosterDesign
    @Binding var route: GPXRoute?
    let close: () -> Void

    @AppStorage("showMapBackground") private var showMapBackground = false
    @AppStorage("mapBackdropStyle")  private var mapStyle = 0

    var body: some View {
        VStack(spacing: 12) {
            HStack {
                Text(title).font(.system(size: 14, weight: .semibold)).foregroundStyle(.white.opacity(0.8))
                Spacer()
                Button("Done", action: close).foregroundStyle(.white)
            }
            .padding(.horizontal, 16).padding(.top, 8)

            switch panel {
            case .canvas:
                VStack(spacing: 8) {
                    ToggleRow(title: "Map background", isOn: $showMapBackground)
                    if showMapBackground {
                        SegRow(title: "Map style", options: ["Std","Hybr","Sat"], selection: $mapStyle)
                    }
                }
                .padding(.horizontal, 16).padding(.bottom, 12)

            case .style:
                VStack(spacing: 8) {
                    SliderRow(title: "Stroke", value: $design.strokeWidthPt, range: 0.5...12, step: 0.5, suffix: "pt")
                    SegEnumRow(title: "Cap", cases: [.round, .butt, .square], selection: $design.lineCap)
                }
                .padding(.horizontal, 16).padding(.bottom, 12)

            case .text:
                // keep it minimal here; open full sheet later if needed
                Text("Edit title in Text sheet").foregroundStyle(.white.opacity(0.6)).padding(.bottom, 12)
                    // hook to your existing TextSheet if you want

            case .map:
                VStack(spacing: 8) {
                    ToggleRow(title: "Show grid", isOn: $design.showGrid)
                    if design.showGrid {
                        SliderRow(title: "Grid", value: Binding(get: { CGFloat(design.gridSpacing) }, set: { design.gridSpacing = Double($0) }), range: 10...200, step: 10, suffix: "pt")
                    }
                }
                .padding(.horizontal, 16).padding(.bottom, 12)

            case .grid: // alias of map/grid controls
                VStack(spacing: 8) {
                    ToggleRow(title: "Show grid", isOn: $design.showGrid)
                    if design.showGrid {
                        SliderRow(title: "Grid", value: Binding(get: { CGFloat(design.gridSpacing) }, set: { design.gridSpacing = Double($0) }), range: 10...200, step: 10, suffix: "pt")
                    }
                }
                .padding(.horizontal, 16).padding(.bottom, 12)

            case .importGPX:
                EmptyView()
            }
        }
        .frame(maxWidth: .infinity)
        .background(.black)
    }

    private var title: String {
        switch panel { case .canvas: "Canvas"; case .importGPX:"Import"; case .style:"Style"; case .text:"Text"; case .map:"Map"; case .grid:"Grid" }
    }
}

private struct ToggleRow: View {
    let title: String
    @Binding var isOn: Bool
    var body: some View {
        HStack {
            Text(title).foregroundStyle(.white)
            Spacer()
            Toggle("", isOn: $isOn).labelsHidden().tint(.white)
        }
    }
}

private struct SliderRow: View {
    let title: String
    @Binding var value: CGFloat
    let range: ClosedRange<CGFloat>
    var step: CGFloat = 1
    var suffix: String = ""
    var body: some View {
        VStack(spacing: 4) {
            HStack {
                Text(title).foregroundStyle(.white)
                Spacer()
                Text("\(Int(value)) \(suffix)").foregroundStyle(.white.opacity(0.6))
            }
            Slider(value: $value, in: range, step: step).tint(.white)
        }
    }
}

private struct SegRow: View {
    let title: String
    let options: [String]
    @Binding var selection: Int
    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title).foregroundStyle(.white)
            HStack(spacing: 8) {
                ForEach(options.indices, id: \.self) { i in
                    Button {
                        UISelectionFeedbackGenerator().selectionChanged(); selection = i
                    } label: {
                        Text(options[i])
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundStyle(selection == i ? .black : .white)
                            .frame(height: 30)
                            .frame(maxWidth: .infinity)
                            .background(selection == i ? Color.white : Color.white.opacity(0.1))
                    }.buttonStyle(.plain)
                }
            }
        }
    }
}

private struct SegEnumRow: View {
    let title: String
    let cases: [PosterDesign.LineCap]
    @Binding var selection: PosterDesign.LineCap
    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title).foregroundStyle(.white)
            HStack(spacing: 8) {
                ForEach(cases, id: \.self) { c in
                    Button {
                        UISelectionFeedbackGenerator().selectionChanged(); selection = c
                    } label: {
                        Text(label(for: c))
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundStyle(selection == c ? .black : .white)
                            .frame(height: 30)
                            .frame(maxWidth: .infinity)
                            .background(selection == c ? Color.white : Color.white.opacity(0.1))
                    }.buttonStyle(.plain)
                }
            }
        }
    }
    private func label(for c: PosterDesign.LineCap) -> String {
        switch c { case .round: "Round"; case .butt: "Butt"; case .square: "Square" }
    }
}

private struct NextSheet: View {
    let design: PosterDesign
    let route: GPXRoute?
    let close: () -> Void
    @State private var saveToPhotos = true
    @State private var includeGrid   = true
    @State private var asPDF         = false

    var body: some View {
        VStack(spacing: 16) {
            HStack {
                Text("Prepare Export").font(.system(size: 16, weight: .semibold))
                Spacer()
                Button { close() } label: { Image(systemName: "xmark").font(.system(size: 16, weight: .semibold)) }
            }
            .padding(.horizontal, 16).padding(.top, 10)

            ToggleRow(title: "Save to Photos", isOn: $saveToPhotos)
            ToggleRow(title: "Include grid",  isOn: $includeGrid)
            ToggleRow(title: "Export as PDF", isOn: $asPDF)

            VSCOPrimaryBar(title: "Save") {
                // call your export using PosterExport.* with these flags
                // then close()
                close()
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 12)
        }
        .frame(maxWidth: .infinity, alignment: .top)
        .background(Color.black.ignoresSafeArea())
        .foregroundStyle(.white)
    }
}