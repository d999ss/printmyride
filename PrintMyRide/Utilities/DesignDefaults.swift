import SwiftUI

enum DesignDefaults {
    static func paper(from tag: String) -> CGSize {
        switch tag {
        case "18x24": return .init(width: 18, height: 24)
        case "24x36": return .init(width: 24, height: 36)
        case "A2":    return .init(width: 16.54, height: 23.39)
        default:      return .init(width: 18, height: 24)
        }
    }
}