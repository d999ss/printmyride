import SwiftUI
import UIKit

struct PosterPreview: View {
    let route: GPXRoute
    @Binding var design: PosterDesign
    
    var body: some View {
        GeometryReader { geo in
            if let data = PosterExport.renderPNG(route: route, design: design, exportScale: 0.25),
               let ui = UIImage(data: data) {
                Image(uiImage: ui)
                    .resizable()
                    .aspectRatio(design.widthInches / design.heightInches, contentMode: .fit)
                    .frame(maxWidth: geo.size.width, maxHeight: geo.size.height)
            } else {
                Color.black
            }
        }
    }
}
