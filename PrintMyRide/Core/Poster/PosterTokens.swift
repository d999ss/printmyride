import SwiftUI

enum PosterTokens {
    // spacing
    static let s1: CGFloat = 4
    static let s2: CGFloat = 8
    static let s3: CGFloat = 12
    static let s4: CGFloat = 16
    static let s5: CGFloat = 24
    static let s6: CGFloat = 32

    // type
    static func h1() -> Font { .system(size: 56, weight: .semibold, design: .serif) }
    static func h2() -> Font { .system(size: 32, weight: .semibold, design: .serif) }
    static func numXL() -> Font { .system(size: 28, weight: .semibold, design: .default).monospacedDigit() }
    static func label() -> Font { .system(size: 14, weight: .semibold, design: .default) }

    // colors
    static var fgPrimary: Color { .primary }
    static var fgSecondary: Color { .secondary }
    static var accent: Color { .blue }
}