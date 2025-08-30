import SwiftUI

struct PMRLogoView: View {
    var body: some View {
        Image("PMR Logo")
            .resizable()
            .aspectRatio(contentMode: .fit)
            .frame(maxWidth: 200, maxHeight: 200)
            .accessibilityLabel("PMR Logo")
    }
}