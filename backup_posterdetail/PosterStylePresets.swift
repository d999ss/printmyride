// PrintMyRide/UI/PosterDetail/PosterStylePresets.swift
import SwiftUI

struct PosterPreset: Hashable, Identifiable {
    let id = UUID()
    let name: String
    let backgroundColor: Color
    let routeColor: Color
    let strokeWidth: CGFloat
    let hasShadow: Bool
    
    init(name: String, bg: Color, route: Color, stroke: CGFloat, shadow: Bool = false) {
        self.name = name
        self.backgroundColor = bg
        self.routeColor = route
        self.strokeWidth = stroke
        self.hasShadow = shadow
    }
}

struct PosterStylePresets {
    let presets: [PosterPreset]
    
    static let standard = PosterStylePresets(presets: [
        .init(name: "Classic", bg: .black, route: .white, stroke: 3),
        .init(name: "Mono", bg: .white, route: .black, stroke: 3),
        .init(name: "Glow", bg: .black, route: .white, stroke: 4, shadow: true),
        .init(name: "Cornsilk", bg: Color(red: 0.98, green: 0.95, blue: 0.87), route: .black, stroke: 3),
        .init(name: "Ocean", bg: Color(.systemBlue).opacity(0.1), route: .blue, stroke: 3.5),
        .init(name: "Forest", bg: Color(.systemGreen).opacity(0.05), route: .green, stroke: 3.5),
        .init(name: "Sunset", bg: Color.orange.opacity(0.08), route: .orange, stroke: 4),
        .init(name: "Purple Haze", bg: Color.purple.opacity(0.06), route: .purple, stroke: 3.5, shadow: true)
    ])
    
    static let premium = PosterStylePresets(presets: [
        .init(name: "Neon", bg: .black, route: .cyan, stroke: 5, shadow: true),
        .init(name: "Gold Rush", bg: .black, route: .yellow, stroke: 4, shadow: true),
        .init(name: "Rose Gold", bg: Color(red: 0.95, green: 0.92, blue: 0.89), route: Color(red: 0.9, green: 0.45, blue: 0.45), stroke: 3.5),
        .init(name: "Midnight", bg: Color(red: 0.05, green: 0.05, blue: 0.1), route: Color(red: 0.3, green: 0.8, blue: 1.0), stroke: 4, shadow: true)
    ])
}