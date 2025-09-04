import SwiftUI

// Minimal onboarding that cannot "stick around" and block taps
struct SimpleOnboardingView: View {
    let onDismiss: () -> Void
    @EnvironmentObject private var services: ServiceHub
    
    var body: some View {
        ZStack {
            // Dimming layer is intentionally hit-testable so a tap dismisses it.
            Color.clear
                .background(.ultraThinMaterial)
                .ignoresSafeArea()
                .onTapGesture { onDismiss() }

            VStack(spacing: 20) {
                // Hero
                VStack(alignment: .leading, spacing: 12) {
                    RoundedRectangle(cornerRadius: 18)
                        .frame(height: 180)
                        .background(LiquidGlassRoundedRectangle(cornerRadius: 18))
                        .liquidGlassRounded(cornerRadius: 18)
                        .overlay(
                            ZStack {
                                Image(systemName: "map") // placeholder icon
                                    .imageScale(.large)
                                    .symbolRenderingMode(.hierarchical)
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
                    .buttonStyle(.plain)
                    .foregroundStyle(.primary)
                    .padding(.horizontal, 24)
                    .padding(.vertical, 16)
                    .background(LiquidGlassCapsule())
                    .liquidGlassCapsule()
                    
                    Button("Connect Strava") { 
                        onDismiss() 
                    }
                    .buttonStyle(.plain)
                    .foregroundStyle(.secondary)
                    .padding(.horizontal, 24)
                    .padding(.vertical, 16)
                    .background(LiquidGlassCapsule())
                    .liquidGlassCapsule(strokeOpacity: 0.15, shadowOpacity: 0.1)
                    
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