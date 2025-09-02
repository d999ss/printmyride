import SwiftUI

struct PosterCell: View {
    let image: UIImage
    let onExport: () -> Void
    let onPrint: () -> Void 
    let onShare: () -> Void
    let onFavorite: () -> Void
    
    @Namespace private var ns
    @State private var show = false

    var body: some View {
        VStack(spacing: PosterTokens.s3) {
            Image(uiImage: image)
                .resizable()
                .scaledToFit()
                .matchedGeometryEffect(id: "poster", in: ns)
                .onTapGesture { 
                    withAnimation(.spring(response: 0.35, dampingFraction: 0.9)) { 
                        show = true 
                    } 
                }
                .accessibilityIdentifier("posterImage")

            HStack(spacing: PosterTokens.s2) {
                Button("Export", action: onExport)
                    .buttonStyle(.bordered)
                    .frame(maxWidth: .infinity)
                
                Button("Print", action: onPrint)
                    .buttonStyle(.bordered)
                    .frame(maxWidth: .infinity)
                
                Button("Share", action: onShare)
                    .buttonStyle(.bordered)
                    .frame(maxWidth: .infinity)
                
                Button("♥", action: onFavorite)
                    .buttonStyle(.bordered)
                    .frame(maxWidth: .infinity)
            }
            .frame(width: nil) // inherits width from the poster through the stack
        }
        .fullScreenCover(isPresented: $show) {
            ZStack {
                Color.black.opacity(0.95)
                    .ignoresSafeArea()
                    .accessibilityIdentifier("focusBackdrop")
                
                Image(uiImage: image)
                    .resizable()
                    .scaledToFit()
                    .matchedGeometryEffect(id: "poster", in: ns)
                    .onTapGesture { 
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.9)) { 
                            show = false 
                        } 
                    }
            }
            .statusBarHidden(true)
        }
    }
}