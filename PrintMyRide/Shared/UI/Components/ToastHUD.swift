import SwiftUI

struct ToastHUD: View {
    let text: String
    var body: some View {
        Text(text)
            .font(.footnote).bold().monospaced()
            .padding(.horizontal, 14).padding(.vertical, 10)
            .background(.ultraThinMaterial, in: Capsule())
            .overlay(Capsule().strokeBorder(Color.white.opacity(0.08)))
            .shadow(radius: 6, y: 3)
    }
}

struct ToastHost<Content: View>: View {
    @Binding var message: String?
    @ViewBuilder var content: () -> Content
    var body: some View {
        ZStack {
            content()
            if let m = message {
                VStack { Spacer(); ToastHUD(text: m).padding(.bottom, 22) }
                    .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
        .animation(.spring(response: 0.35, dampingFraction: 0.9), value: message)
    }
}