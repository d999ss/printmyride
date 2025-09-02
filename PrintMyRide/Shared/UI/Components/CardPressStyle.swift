import SwiftUI

struct CardPressStyle: ButtonStyle {
    @Binding var pressed: Bool
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .onChange(of: configuration.isPressed) { isDown in 
                pressed = isDown 
            }
    }
}