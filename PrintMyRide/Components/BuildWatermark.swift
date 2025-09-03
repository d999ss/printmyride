import SwiftUI

struct BuildWatermark: View {
    #if DEBUG
    private var version: String {
        let v = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
        let b = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "999"
        // For now, just show build number and a timestamp
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "HH:mm"
        let time = dateFormatter.string(from: Date())
        return "PMR Build \(b) • \(time)"
    }
    var body: some View {
        Text(version)
            .font(.caption2).monospaced().bold()
            .padding(6)
            .background(.ultraThinMaterial, in: Capsule())
            .padding([.bottom, .trailing], 8)
            .foregroundStyle(.secondary)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottomTrailing)
            .allowsHitTesting(false)
            .decorative()  // Mark as decorative for TapDoctor
    }
    #else
    var body: some View { EmptyView() }
    #endif
}