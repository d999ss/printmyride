import SwiftUI

struct PosterCard: View {
    let image: UIImage?

    var body: some View {
        ZStack {
            if let img = image {
                Image(uiImage: img)
                    .resizable()
                    .scaledToFill()
            } else {
                Shimmer()
            }
        }
        .frame(width: 160, height: 213.3) // 3:4 ratio
        .clipped()
    }
}

// Overload for non-optional UIImage (Filmstrip use)
extension PosterCard {
    init(image: UIImage) {
        self.image = image
    }
}