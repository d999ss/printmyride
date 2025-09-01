import SwiftUI
import UIKit
import MapKit

struct PurePoster: View {
    let design: PosterDesign
    let route: GPXRoute?
    let mode: PosterRenderMode
    @AppStorage("showHUD") private var showHUD = true
    @AppStorage("showMapBackground") private var showMapBackground = false
    @AppStorage("mapBackdropStyle") private var mapBackdropStyle = 0
    @State private var tempGrid = false
    @State private var mapImage: UIImage?
    
    var body: some View {
        GeometryReader { geo in
            ZStack {
                if mode == .editor { Color(.systemBackground).ignoresSafeArea() }
                
                ZStack {
                    // Background: map snapshot or poster bg color
                    if showMapBackground, let img = mapImage {
                        Image(uiImage: img)
                            .resizable().scaledToFill()
                            .frame(width: geo.size.width, height: geo.size.height)
                            .clipped()
                            .opacity(0.92) // muted, VSCO-like
                    } else {
                        Rectangle().fill(design.backgroundColor).ignoresSafeArea()
                    }
                    
                    // Route layer (existing draw)
                    CanvasView(design: design, route: route)
                        .aspectRatio(design.paperSize.width / design.paperSize.height, contentMode: .fit)
                        .frame(maxWidth: geo.size.width, maxHeight: geo.size.height)
                        .shadow(radius: design.dropShadowEnabled ? design.dropShadowRadius : 0)
                    
                    // Grid overlay (existing)
                    if design.showGrid || tempGrid {
                        GridOverlay(spacing: design.gridSpacing, color: design.gridColor)
                            .animation(DesignTokens.Animation.standard, value: design.showGrid)
                            .transition(.opacity)
                    }
                }
                .overlay(alignment: .topTrailing) {
                    if showHUD && mode == .editor {
                        InfoHUD(paper: design.paperSize,
                                dpi: design.dpi,
                                margins: design.margins,
                                grid: design.gridSpacing,
                                pointsPre: RenderStats.shared.pointsPre,
                                pointsPost: RenderStats.shared.pointsPost,
                                zoomPercent: RenderStats.shared.zoomPercent)
                            .padding(DesignTokens.Spacing.sm)
                    }
                }
                .gesture(
                    LongPressGesture(minimumDuration: 0.15)
                        .onChanged { _ in tempGrid = true }
                        .onEnded { _ in 
                            withAnimation(.easeInOut(duration: 0.2)) { 
                                tempGrid = false 
                            }
                        }
                )
                .task(id: snapshotKey(size: geo.size)) {
                    await refreshSnapshot(size: geo.size)
                }
                .shadow(color: (mode == .editor) ? Color.black.opacity(0.12) : .clear,
                        radius: (mode == .editor) ? 16 : 0, y: (mode == .editor) ? 8 : 0)
            }
        }
    }
    
    private func snapshotKey(size: CGSize) -> String {
        let count = route?.coordinates.count ?? 0
        return "\(showMapBackground)-\(mapBackdropStyle)-\(Int(size.width))x\(Int(size.height))-\(count)"
    }
    
    @MainActor
    private func refreshSnapshot(size: CGSize) async {
        guard showMapBackground, let coords = route?.coordinates, !coords.isEmpty else {
            mapImage = nil; return
        }
        let style = MapBackdropStyle(rawValue: mapBackdropStyle) ?? .standard
        mapImage = await MapSnapshotper.snapshot(coords: coords, size: size,
                                                 scale: UIScreen.main.scale, style: style)
    }
}