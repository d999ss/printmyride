import SwiftUI
import UIKit

// Stub for existing PosterDesign to resolve build errors
struct PosterDesign {
    var backgroundColor: Color = .black
    var routeColor: Color = .white
    var dropShadowEnabled: Bool = false
    var dropShadowRadius: CGFloat = 0
    var strokeWidthPt: CGFloat = 2
    var paperSize: CGSize = CGSize(width: 18, height: 24)
    var showGrid: Bool = false
    var gridSpacing: Double = 20
    var gridColor: Color = .gray.opacity(0.3)
    var dpi: Int = 300
    var margins: CGFloat = 0.10
    
    enum LineCap { case round, square, butt }
    enum Orientation { case portrait, landscape }
    
    var lineCap: LineCap = .round
    var orientation: Orientation = .portrait
    
    init(paperSize: CGSize = CGSize(width: 18, height: 24), 
         showGrid: Bool = false,
         orientation: Orientation = .portrait,
         strokeWidthPt: CGFloat = 2,
         lineCap: LineCap = .round,
         routeColor: Color = .white,
         backgroundColor: Color = .black) {
        self.paperSize = paperSize
        self.showGrid = showGrid
        self.orientation = orientation
        self.strokeWidthPt = strokeWidthPt
        self.lineCap = lineCap
        self.routeColor = routeColor
        self.backgroundColor = backgroundColor
    }
    
    init() {}
    
    static func `default`() -> PosterDesign {
        return PosterDesign()
    }
    
    struct ColorData {
        let color: Color
        init(_ color: Color) { self.color = color }
    }
}