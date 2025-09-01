import SwiftUI

struct OnboardingView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var services: ServiceHub
    @EnvironmentObject private var oauth: StravaOAuth
    @AppStorage("pmr.hasOnboarded") private var hasOnboarded: Bool = false
    @State private var isWorking = false

    var body: some View {
        ZStack {
            // Background
            LinearGradient(
                colors: [.black, .black.opacity(0.85)],
                startPoint: .topLeading, endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            VStack(spacing: 20) {
                // Hero
                VStack(alignment: .leading, spacing: 12) {
                    RoundedRectangle(cornerRadius: 18)
                        .fill(.ultraThinMaterial)
                        .frame(height: 180)
                        .overlay(
                            ZStack {
                                Image(systemName: "map") // placeholder icon
                                    .imageScale(.large)
                                    .foregroundStyle(.secondary)
                            }
                        )
                    Text("Turn rides into art.")
                        .font(.system(size: 28, weight: .bold, design: .rounded))
                    Text("Instant demo posters. Export hi-res with Try Pro. Print via demo checkout.")
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 20)

                // CTA Buttons (explicit frames + backgrounds to guarantee hit testing)
                VStack(spacing: 12) {
                    Button(action: startDemo) {
                        Text(isWorking ? "Starting…" : "Start Demo")
                            .fontWeight(.semibold)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                    }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.large)
                    .disabled(isWorking)

                    Button(action: connectStrava) {
                        Text("Connect Strava")
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                    }
                    .buttonStyle(.bordered)
                    .controlSize(.large)

                    Button(action: skip) {
                        Text("Skip for now")
                            .foregroundStyle(.secondary)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 10)
                    }
                    .buttonStyle(.plain)
                }
                .padding(.horizontal, 20)

                Spacer(minLength: 12)
            }
        }
        .onAppear {
            // Ensure this view captures taps (avoid phantom overlays)
            UIApplication.shared.windows.first?.endEditing(true)
        }
    }

    // MARK: - Actions
    private func finish() {
        hasOnboarded = true
        Haptics.success()
        print("[Onboarding] completed")
        dismiss()
    }
    private func startDemo() {
        guard !isWorking else { return }
        isWorking = true
        services.mockStrava = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
            isWorking = false
            finish()
        }
    }
    private func connectStrava() {
        oauth.startLogin()
        finish()
    }
    private func skip() {
        finish()
    }
}