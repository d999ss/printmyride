import SwiftUI
import UniformTypeIdentifiers

struct EditorView: View {
    @State private var design: PosterDesign
    @State private var route: GPXRoute?
    @State private var textMeta: PosterText = .init()
    @State private var showingStyle = false
    @State private var showingCanvas = false
    @State private var showingExport = false
    @State private var showingImporter = false
    @State private var showingText = false
    @EnvironmentObject private var library: LibraryStore
    @StateObject private var settings = SettingsStore.shared
    @AppStorage("defaultPaperPreset") private var dp: String = "18x24"
    @AppStorage("defaultGridSpacing") private var dg: Double = 50
    @AppStorage("alwaysShowControls") private var alwaysShowControls = false
    @Environment(\.dismiss) private var dismiss
    
    // Undo/Redo system
    @State private var undoStack: [PosterDesign] = []
    @State private var redoStack: [PosterDesign] = []
    
    // VSCO chrome system
    @StateObject private var chrome = ChromeVisibility()
    @State private var toolHint: String? = nil

    init(initialDesign: PosterDesign? = nil, initialRoute: GPXRoute? = nil, initialText: PosterText? = nil) {
        _design = State(initialValue: initialDesign ?? PosterDesign())
        _route  = State(initialValue: initialRoute)
        _textMeta = State(initialValue: initialText ?? PosterText())
    }
    
    init() {
        let base = PosterDesign(paperSize: CGSize(width: 18, height: 24),
                                showGrid: false,
                                orientation: .portrait,
                                strokeWidthPt: 2,
                                lineCap: .round,
                                routeColor: .black,
                                backgroundColor: .white)
        _design = State(initialValue: base)
        _route = State(initialValue: nil)
        _textMeta = State(initialValue: PosterText())
    }
    
    private func pushUndo(_ old: PosterDesign) {
        undoStack.append(old)
        if undoStack.count > 20 { _ = undoStack.removeFirst() }
        redoStack.removeAll()
    }

    private var activeRoute: GPXRoute? {
        return route ?? (settings.useSampleRoute ? SampleRoute.route() : nil)
    }

    var body: some View {
        NavigationStack {
            ZStack {
                // Full-bleed poster
                if let r = activeRoute {
                    PosterPreview(design: design, posterTitle: "My Ride", mode: .editor, route: r, payload: nil)
                        .overlay(alignment: .topLeading) {
                            let coords = r.coordinates
                            let stats = coords.isEmpty ? nil : StatsExtractor.compute(coords: coords, elevations: nil, timestamps: nil)
                            TextOverlay(text: textMeta, stats: stats)
                                .allowsHitTesting(false)
                        }
                        .ignoresSafeArea()
                        .onTapGesture { 
                            if !alwaysShowControls { chrome.showTemporarily() }
                        }
                } else {
                    DesignTokens.Colors.surface
                        .ignoresSafeArea()
                        .overlay {
                            Text("Import a GPX to start")
                                .font(DesignTokens.Typography.body)
                                .foregroundStyle(DesignTokens.Colors.secondary)
                        }
                        .onTapGesture { 
                            if !alwaysShowControls { chrome.showTemporarily() }
                        }
                }
                
                // Top gradient overlay with back + save (minimal chrome)
                if chrome.visible {
                    LinearGradient(
                        colors: [.black.opacity(0.35), .clear],
                        startPoint: .top,
                        endPoint: .center
                    )
                    .ignoresSafeArea(edges: .top)
                    
                    HStack {
                        Button { dismiss() } label: { 
                            Image(systemName: "chevron.backward")
                                .imageScale(.large)
                        }
                        Spacer()
                        Button("Save") { save() }
                            .tint(DesignTokens.Colors.accent)
                    }
                    .font(DesignTokens.Typography.title)
                    .foregroundStyle(.white)
                    .padding(.horizontal, DesignTokens.Spacing.md)
                    .padding(.top, 12)
                    .frame(maxHeight: .infinity, alignment: .top)
                }
                
                // Floating icon-only tool pill
                if chrome.visible {
                    HStack(spacing: DesignTokens.Spacing.lg) {
                        icon("tray.and.arrow.down", "Import") { showingImporter = true }
                        icon("paintbrush", "Style") { showingStyle = true }
                        icon("textformat", "Text") { showingText = true }
                        icon("rectangle.and.pencil.and.ellipsis", "Canvas") { showingCanvas = true }
                        icon("square.and.arrow.up", "Export", disabled: activeRoute == nil) { showingExport = true }
                    }
                    .padding(.horizontal, DesignTokens.Spacing.md)
                    .padding(.vertical, DesignTokens.Spacing.sm)
                    .background(.regularMaterial, in: Capsule())
                    .padding(.bottom, DesignTokens.Spacing.lg)
                    .frame(maxHeight: .infinity, alignment: .bottom)
                    
                    // Tool hint bubble
                    if let hint = toolHint {
                        Text(hint)
                            .font(DesignTokens.Typography.caption)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 6)
                            .background(.ultraThinMaterial, in: Capsule())
                            .shadow(color: .black.opacity(0.08), radius: 6, y: 3)
                            .transition(.opacity)
                            .padding(.bottom, 84)
                            .frame(maxHeight: .infinity, alignment: .bottom)
                    }
                }
            }
            .toolbar(.hidden, for: .navigationBar)
            .toolbar(.hidden, for: .tabBar)
            .onAppear {
                if alwaysShowControls { chrome.show() } else { chrome.showTemporarily() }
                if activeRoute == nil && design.strokeWidthPt == 2 {
                    var copy = design
                    copy.paperSize = DesignDefaults.paper(from: dp)
                    copy.gridSpacing = dg
                    design = copy
                }
            }
            
            // Sheets with VSCO detents
            .sheet(isPresented: $showingStyle) {
                StyleSheet(design: $design, pushUndo: pushUndo)
                    .presentationDetents([.fraction(0.33), .fraction(0.66), .large])
            }
            .sheet(isPresented: $showingCanvas) {
                CanvasSheet(design: $design, pushUndo: pushUndo)
                    .presentationDetents([.fraction(0.33), .fraction(0.66), .large])
            }
            .sheet(isPresented: $showingText) {
                TextSheet(text: $textMeta)
                    .presentationDetents([.fraction(0.33), .fraction(0.66), .large])
            }
            .sheet(isPresented: $showingExport) {
                ExportSheet(design: design, route: activeRoute)
                    .presentationDetents([.medium, .large])
            }
            .fileImporter(
                isPresented: $showingImporter,
                allowedContentTypes: [.gpx, .xml],
                allowsMultipleSelection: false,
                onCompletion: handleImport
            )
        }
    }

    // MARK: - Import handler (matches allowsMultipleSelection: false)
    private func handleImport(_ result: Result<[URL], Error>) {
        guard let url = (try? result.get().first) else { return }
        let access = url.startAccessingSecurityScopedResource()
        defer { if access { url.stopAccessingSecurityScopedResource() } }
        route = GPXImporter.load(url: url)
        settings.useSampleRoute = false
    }
    
    private func loadSample() {
        guard let url = Bundle.main.url(forResource: "sample", withExtension: "gpx") else { return }
        route = GPXImporter.load(url: url)
    }
    
    @ViewBuilder
    private func icon(_ name: String, _ title: String, disabled: Bool = false, action: @escaping () -> Void) -> some View {
        Button {
            UISelectionFeedbackGenerator().selectionChanged()
            toolHint = title
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.1) {
                if toolHint == title { toolHint = nil }
            }
            action()
        } label: {
            Image(systemName: name)
                .imageScale(.large)
        }
        .disabled(disabled)
        .foregroundStyle(disabled ? DesignTokens.Colors.secondary : DesignTokens.Colors.onSurface)
        .buttonStyle(.plain)
        .simultaneousGesture(
            LongPressGesture(minimumDuration: 0.2)
                .onEnded { _ in toolHint = title }
        )
    }
    
    private func save() {
        Task { @MainActor in
            guard let png = Snapshotter.posterPNG(design: design, route: activeRoute) else { return }
            let routeURL: URL? = nil // route?.sourceURL // optional: expose in GPXImporter
            library.add(design: design, routeURL: routeURL, thumbnailPNG: png,
                       title: textMeta.title.isEmpty ? "My Ride" : textMeta.title,
                       text: textMeta)
            UINotificationFeedbackGenerator().notificationOccurred(.success)
        }
    }
}
