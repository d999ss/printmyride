import SwiftUI

struct CenterlineHeadline: View {
    let text: String
    var wrapFactor: CGFloat = 0.58   // ~centerline
    var fontSize: CGFloat   = 32
    var body: some View {
        GeometryReader { geo in
            let pad: CGFloat = 16
            let width = max(0, geo.size.width * wrapFactor - pad)
            Text(text)
               .font(.system(size: fontSize, weight: .semibold))
               .multilineTextAlignment(.leading)
               .lineSpacing(-20) // Extremely tight line spacing
               .fixedSize(horizontal:false, vertical:true)
               .frame(width: width, alignment: .leading)
               .padding(.horizontal, pad)
               .foregroundStyle(.white)
        }
        .frame(height: fontSize > 32 ? 120 : 92) // More height for wrapped text
    }
}