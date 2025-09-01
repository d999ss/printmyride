import SwiftUI

struct HeroBannerView: View {
    @EnvironmentObject private var gate: SubscriptionGate
    @Binding var toast: String?
    let onTryPro: () -> Void
    
    @State private var heroImageOffset: CGFloat = 0
    
    var body: some View {
        GeometryReader { geometry in
            let scrollOffset = geometry.frame(in: .global).minY
            
            ZStack(alignment: .bottomLeading) {
                // Hero background with parallax
                heroBackground
                    .offset(y: scrollOffset > 0 ? -scrollOffset * 0.5 : 0)
                    .scaleEffect(scrollOffset > 0 ? 1 + (scrollOffset * 0.001) : 1)
                
                // Gradient overlay
                LinearGradient(
                    colors: [
                        Color.clear,
                        Color.black.opacity(0.3),
                        Color.black.opacity(0.6)
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .clipShape(RoundedRectangle(cornerRadius: DesignTokens.CornerRadius.xl))
                
                // Content overlay
                heroContent
                    .padding(DesignTokens.Spacing.lg)
            }
            .clipShape(RoundedRectangle(cornerRadius: DesignTokens.CornerRadius.xl))
            .shadow(
                color: DesignTokens.Shadow.card.color,
                radius: DesignTokens.Shadow.card.radius,
                x: DesignTokens.Shadow.card.x,
                y: DesignTokens.Shadow.card.y
            )
        }
        .frame(height: 220)
    }
    
    private var heroBackground: some View {
        ZStack {
            // Base gradient
            LinearGradient(
                colors: [
                    Color(red: 0.1, green: 0.3, blue: 0.8),
                    Color(red: 0.6, green: 0.2, blue: 0.8),
                    Color(red: 0.9, green: 0.4, blue: 0.2)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            
            // Texture overlay
            Image(systemName: "bicycle")
                .font(.system(size: 120))
                .foregroundStyle(.white.opacity(0.1))
                .offset(x: 80, y: -20)
                .rotationEffect(.degrees(15))
            
            // Additional decorative elements
            ForEach(0..<3, id: \.self) { i in
                Circle()
                    .fill(.white.opacity(0.05))
                    .frame(width: 40 + CGFloat(i * 20))
                    .offset(
                        x: CGFloat.random(in: -100...100),
                        y: CGFloat.random(in: -50...50)
                    )
            }
        }
    }
    
    private var heroContent: some View {
        VStack(alignment: .leading, spacing: DesignTokens.Spacing.md) {
            Spacer()
            
            VStack(alignment: .leading, spacing: DesignTokens.Spacing.sm) {
                Text("The Art of the Journey")
                    .font(DesignTokens.Typography.title)
                    .foregroundStyle(.white)
                
                Text("Transform your cycling adventures into stunning poster art. Export hi-res prints or share your favorite routes.")
                    .font(DesignTokens.Typography.subheadline)
                    .foregroundStyle(.white.opacity(0.9))
                    .lineLimit(2)
            }
            
            actionButtons
        }
    }
    
    @State private var buttonPressed = false
    
    private var actionButtons: some View {
        HStack(spacing: DesignTokens.Spacing.sm) {
            // Enhanced Try Pro button
            Button {
                Haptics.tap()
                if gate.isSubscribed {
                    toast = "You're Pro already"
                    Haptics.success()
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) { toast = nil }
                } else {
                    onTryPro()
                }
            } label: {
                HStack(spacing: 6) {
                    Image(systemName: gate.isSubscribed ? "checkmark.circle.fill" : "crown.fill")
                        .imageScale(.medium)
                    Text(gate.isSubscribed ? "Pro Active" : "Try Pro")
                }
                .font(DesignTokens.Typography.callout)
                .fontWeight(.semibold)
                .foregroundStyle(gate.isSubscribed ? .white : .black)
                .padding(.horizontal, DesignTokens.Spacing.md)
                .padding(.vertical, DesignTokens.Spacing.sm)
                .background(
                    Group {
                        if gate.isSubscribed {
                            LinearGradient(
                                colors: [.green.opacity(0.9), .green.opacity(0.7)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        } else {
                            LinearGradient(
                                colors: [.white.opacity(0.95), .white.opacity(0.8)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        }
                    }
                )
                .clipShape(RoundedRectangle(cornerRadius: DesignTokens.CornerRadius.button))
                .shadow(
                    color: .black.opacity(0.1),
                    radius: 4,
                    x: 0,
                    y: 2
                )
            }
            .scaleEffect(buttonPressed ? 0.95 : 1.0)
            .animation(DesignTokens.Animation.spring, value: buttonPressed)
            .simultaneousGesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { _ in buttonPressed = true }
                    .onEnded { _ in buttonPressed = false }
            )
            
            // Enhanced Settings link
            NavigationLink {
                SettingsView()
            } label: {
                HStack(spacing: 6) {
                    Image(systemName: "gearshape.fill")
                        .imageScale(.medium)
                    Text("Settings")
                }
                .font(DesignTokens.Typography.callout)
                .fontWeight(.medium)
                .foregroundStyle(.white)
                .padding(.horizontal, DesignTokens.Spacing.md)
                .padding(.vertical, DesignTokens.Spacing.sm)
                .background(
                    LinearGradient(
                        colors: [.white.opacity(0.2), .white.opacity(0.1)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .clipShape(RoundedRectangle(cornerRadius: DesignTokens.CornerRadius.button))
                .overlay(
                    RoundedRectangle(cornerRadius: DesignTokens.CornerRadius.button)
                        .strokeBorder(.white.opacity(0.3), lineWidth: 1)
                )
            }
            
            Spacer()
        }
    }
}