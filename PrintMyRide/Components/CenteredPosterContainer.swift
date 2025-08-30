import SwiftUI

struct CenteredPosterContainer<Content: View>: View {
    let topBarHeight: CGFloat
    let toolTrayHeight: CGFloat
    @ViewBuilder let content: () -> Content
    
    init(topBarHeight: CGFloat = 44, toolTrayHeight: CGFloat = 0, @ViewBuilder content: @escaping () -> Content) {
        self.topBarHeight = topBarHeight
        self.toolTrayHeight = toolTrayHeight
        self.content = content
    }
    
    var body: some View {
        GeometryReader { geo in
            // Layout constants
            let aspect: CGFloat = 18.0/24.0
            let sideGutter: CGFloat = 20                  // left/right breathing room
            let verticalGutter: CGFloat = 16
            
            // Available drawing area between top bar and bottom (tray or safe area)
            let availW = geo.size.width - sideGutter * 2
            let availH = geo.size.height - topBarHeight - toolTrayHeight - verticalGutter * 2
            
            // Fit the 18×24 poster into the available box
            let posterW = min(availW, availH * aspect)
            let posterH = posterW / aspect
            
            // Centered poster
            ZStack {
                // Poster surface (paper)
                Rectangle()
                    .fill(Color.white)
                
                // Your poster content
                content()
            }
            .frame(width: posterW, height: posterH)
            .overlay(                                      // hairline edge (no shadow)
                Rectangle()
                    .stroke(Color.white.opacity(0.08), lineWidth: 1)
            )
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
            .padding(.horizontal, sideGutter)
            .padding(.vertical, verticalGutter)
        }
    }
}