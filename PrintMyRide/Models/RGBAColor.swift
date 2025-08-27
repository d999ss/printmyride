import SwiftUI
import UIKit

struct RGBAColor: Codable, Equatable {
    var r: Double, g: Double, b: Double, a: Double
    
    init(_ color: Color) {
        let ui = UIColor(color)
        var rr: CGFloat = 0, gg: CGFloat = 0, bb: CGFloat = 0, aa: CGFloat = 0
        ui.getRed(&rr, green: &gg, blue: &bb, alpha: &aa)
        r = Double(rr); g = Double(gg); b = Double(bb); a = Double(aa)
    }
    
    var color: Color { Color(red: r, green: g, blue: b).opacity(a) }
}
