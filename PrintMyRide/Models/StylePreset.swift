import SwiftUI

enum StylePreset: String, CaseIterable, Identifiable {
    case light = "Light"
    case dark  = "Dark"
    case neon  = "Neon"
    var id: String { rawValue }

    func apply(to d: inout PosterDesign) {
        switch self {
        case .light:
            d.backgroundColor = .init(.white)
            d.routeColor = .init(.black)
            d.dropShadowEnabled = false
            d.strokeWidthPt = 2
        case .dark:
            d.backgroundColor = .init(.black)
            d.routeColor = .init(.white)
            d.dropShadowEnabled = true
            d.dropShadowRadius = 18
            d.strokeWidthPt = 2.5
        case .neon:
            d.backgroundColor = .init(.black)
            d.routeColor = .init(Color(hue: 0.83, saturation: 0.9, brightness: 1))
            d.dropShadowEnabled = true
            d.dropShadowRadius = 22
            d.strokeWidthPt = 3
        }
    }
}