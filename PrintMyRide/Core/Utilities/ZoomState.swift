import SwiftUI

struct ZoomState {
    var scale: CGFloat = 1.0
    var offset: CGSize = .zero
    
    mutating func clamp() {
        scale = min(max(scale, 0.5), 8.0)
        if scale == 1 {
            offset = .zero
        }
    }
    
    mutating func reset() {
        scale = 1
        offset = .zero
    }
}