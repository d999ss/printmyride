import SwiftUI

struct DebugHUD: View {
    @ObservedObject var bus = ErrorBus.shared
    @State private var visible = false
    var body: some View {
        ZStack {
            // 1) Small triple-tap hotspot (top-left 44x44pt)
            Color.clear
                .frame(width: 44, height: 44, alignment: .topLeading)
                .contentShape(Rectangle())
                .onTapGesture(count: 3) { withAnimation(.spring()) { visible.toggle() } }
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
                // When HUD is hidden, do NOT intercept any other touches.
                .allowsHitTesting(true)

            // 2) The panel itself (bottom-left), only when visible
            if visible {
                VStack(alignment: .leading, spacing: 6) {
                    HStack {
                        Text("PMR Debug").bold()
                        Spacer()
                        Button {
                            withAnimation(.spring()) { visible = false }
                        } label: { Image(systemName: "xmark.circle.fill") }
                    }
                    Text(bus.lastMessage ?? "No errors")
                        .font(.footnote).foregroundStyle(.secondary)
                }
                .padding(10)
                .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
                .padding(12)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottomLeading)
            }
        }
    }
}