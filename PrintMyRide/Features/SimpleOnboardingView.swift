import SwiftUI

// Minimal onboarding that cannot "stick around" and block taps
struct SimpleOnboardingView: View {
    let onDismiss: () -> Void
    @EnvironmentObject private var services: ServiceHub
    
    var body: some View {
        ZStack {
            // Dimming layer is intentionally hit-testable so a tap dismisses it.
            Color.black.opacity(0.55)
                .ignoresSafeArea()
                .onTapGesture { onDismiss() }

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
                
                VStack(spacing: 12) {
                    Button("Start Demo") { 
                        services.mockStrava = true
                        onDismiss() 
                    }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.large)
                    
                    Button("Connect Strava") { 
                        onDismiss() 
                    }
                    .buttonStyle(.bordered)
                    .controlSize(.large)
                    
                    Button("Skip for now") { 
                        onDismiss() 
                    }
                    .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity)
            }
            .padding(32)
            .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16))
            .padding(.horizontal, 20)
        }
    }
}