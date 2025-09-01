import SwiftUI

struct PMRCard<Content: View>: View {
    let content: Content
    init(@ViewBuilder content: () -> Content) { self.content = content() }
    var body: some View {
        content
            .padding(14)
            .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .strokeBorder(Color.white.opacity(0.06), lineWidth: 1)
            )
    }
}

struct MetricPill: View {
    let icon: String
    let text: String
    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: icon).imageScale(.small)
            Text(text).font(.footnote).fontWeight(.medium)
        }
        .padding(.horizontal, 10).padding(.vertical, 6)
        .background(.ultraThinMaterial, in: Capsule())
    }
}