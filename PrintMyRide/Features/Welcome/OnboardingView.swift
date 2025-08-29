import SwiftUI

struct OnboardingView: View {
    @EnvironmentObject var library: LibraryStore
    @State private var thumbs: [UIImage] = []
    @State private var isLoading = true
    @StateObject private var settings = SettingsStore.shared

    var body: some View {
        ZStack {
            (settings.onboardingTheme == "studio" ? Color.black : Color(.systemBackground)).ignoresSafeArea()

            VStack(spacing: 24) {
                // HERO
                Group {
                    if settings.onboardingUsePager {
                        PagerHero(thumbs: thumbs, isLoading: isLoading)
                            .frame(height: 280)
                    } else {
                        Filmstrip(thumbs: thumbs, isLoading: isLoading)
                            .frame(height: 220)
                    }
                }
                .padding(.top, 12)

                // COPY
                VStack(spacing: 8) {
                    Text("Turn rides into art.")
                        .font(.system(.largeTitle, design: .default).weight(.semibold))
                        .foregroundStyle(themePrimary)
                        .multilineTextAlignment(.center)
                    Text("Make beautiful, print-ready posters from your GPX.")
                        .font(.footnote)
                        .foregroundStyle(themeSecondary)
                        .multilineTextAlignment(.center)
                }
                .padding(.horizontal, 24)

                // CTA
                Button {
                    UISelectionFeedbackGenerator().selectionChanged()
                    library.hasSeenOnboarding = true
                } label: {
                    Text("Get Started")
                        .fontWeight(.semibold)
                        .padding(.vertical, 12).padding(.horizontal, 22)
                        .foregroundStyle(.white)
                        .background(rideOrange, in: Capsule())
                }
                .accessibilityIdentifier("btn-get-started")

                Text("All on-device. No account.")
                    .font(.footnote)
                    .foregroundStyle(themeSecondary)

                Spacer(minLength: 0)
            }
            .padding(.bottom, 20)
        }
        .task { await loadThumbs() }
    }

    private var rideOrange: Color { Color(red: 0xFC/255, green: 0x4C/255, blue: 0x02/255) }
    private var themePrimary: Color { settings.onboardingTheme == "studio" ? .white : Color(.label) }
    private var themeSecondary: Color { settings.onboardingTheme == "studio" ? .white.opacity(0.6) : Color(.secondaryLabel) }

    @MainActor
    private func loadThumbs() async {
        guard let r = SampleRoute.route() else { isLoading = false; return }
        // 3 variations from same route; quick and clean
        let d = PosterDesign()
        let t = CGSize(width: 720, height: 960)
        var images: [UIImage] = []
        if let a = Snapshotter.posterThumb(design: d, route: r, size: t) { images.append(a) }
        if let b = Snapshotter.posterThumb(design: d, route: r, size: t) { images.append(b) }
        if let c = Snapshotter.posterThumb(design: d, route: r, size: t) { images.append(c) }
        thumbs = images; isLoading = false
    }
}