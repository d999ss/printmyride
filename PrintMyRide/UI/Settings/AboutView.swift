import SwiftUI

struct AboutView: View {
    @State private var showingCredits = false
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: DesignTokens.Spacing.xl) {
                    appHeader
                    
                    buildInfoSection
                    
                    infoSection
                    
                    linksSection
                    
                    creditsSection
                    
                    legalSection
                }
                .padding(DesignTokens.Spacing.md)
            }
            .background(DesignTokens.Colors.surface)
            .navigationTitle("About")
            .navigationBarTitleDisplayMode(.large)
        }
        .sheet(isPresented: $showingCredits) {
            creditsSheet
        }
    }
    
    private var appHeader: some View {
        VStack(spacing: DesignTokens.Spacing.md) {
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [DesignTokens.Colors.primary, DesignTokens.Colors.accent],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 120, height: 120)
                
                Image(systemName: "bicycle")
                    .font(.system(size: 50))
                    .foregroundStyle(.white)
            }
            
            VStack(spacing: DesignTokens.Spacing.xs) {
                Text("PrintMyRide")
                    .font(DesignTokens.Typography.largeTitle)
                
                Text("Transform Your Rides Into Art")
                    .font(DesignTokens.Typography.subheadline)
                    .foregroundStyle(DesignTokens.Colors.secondary)
            }
            
            Text(appVersionString)
                .font(DesignTokens.Typography.caption)
                .foregroundStyle(DesignTokens.Colors.secondary)
                .padding(.horizontal, DesignTokens.Spacing.md)
                .padding(.vertical, DesignTokens.Spacing.xs)
                .background(DesignTokens.Colors.surfaceSecondary)
                .clipShape(RoundedRectangle(cornerRadius: DesignTokens.CornerRadius.sm))
        }
    }
    
    private var buildInfoSection: some View {
        VStack(alignment: .leading, spacing: DesignTokens.Spacing.sm) {
            Text("App Info")
                .font(DesignTokens.Typography.headline)
            
            VStack(spacing: DesignTokens.Spacing.xs) {
                HStack {
                    Text("Version")
                        .font(DesignTokens.Typography.subheadline)
                    Spacer()
                    Text(Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "—")
                        .font(DesignTokens.Typography.subheadline)
                        .foregroundStyle(DesignTokens.Colors.secondary)
                }
                
                HStack {
                    Text("Build")
                        .font(DesignTokens.Typography.subheadline)
                    Spacer()
                    Text("PMR Build 2 • \(Date.now.formatted(date: .omitted, time: .shortened))")
                        .font(DesignTokens.Typography.caption)
                        .monospaced()
                        .foregroundStyle(DesignTokens.Colors.secondary)
                }
            }
        }
        .padding(DesignTokens.Spacing.md)
        .background(DesignTokens.Colors.surfaceSecondary)
        .clipShape(RoundedRectangle(cornerRadius: DesignTokens.CornerRadius.lg))
    }
    
    private var infoSection: some View {
        VStack(alignment: .leading, spacing: DesignTokens.Spacing.md) {
            Text("About the App")
                .font(DesignTokens.Typography.headline)
            
            Text("PrintMyRide transforms your cycling adventures into beautiful poster art. Import GPX tracks from your favorite rides, customize the design, and create high-quality prints to commemorate your journeys.")
                .font(DesignTokens.Typography.body)
                .foregroundStyle(DesignTokens.Colors.onSurface)
                .fixedSize(horizontal: false, vertical: true)
            
            Text("Whether it's a scenic route through the mountains, a challenging urban ride, or your daily commute, every journey has a story worth preserving.")
                .font(DesignTokens.Typography.body)
                .foregroundStyle(DesignTokens.Colors.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(DesignTokens.Spacing.md)
        .background(DesignTokens.Colors.surfaceSecondary)
        .clipShape(RoundedRectangle(cornerRadius: DesignTokens.CornerRadius.lg))
    }
    
    private var linksSection: some View {
        VStack(spacing: DesignTokens.Spacing.sm) {
            LinkRow(
                icon: "globe",
                title: "Website",
                subtitle: "printmyride.app",
                url: "https://printmyride.app"
            )
            
            LinkRow(
                icon: "envelope",
                title: "Support",
                subtitle: "Get help & send feedback",
                url: "mailto:support@printmyride.app"
            )
            
            LinkRow(
                icon: "star",
                title: "Rate on App Store",
                subtitle: "Help us grow with a review",
                action: { requestAppStoreReview() }
            )
            
            LinkRow(
                icon: "person.2",
                title: "Follow Development",
                subtitle: "@printmyride on social",
                url: "https://twitter.com/printmyride"
            )
        }
    }
    
    private var creditsSection: some View {
        VStack(spacing: DesignTokens.Spacing.md) {
            Button {
                showingCredits = true
            } label: {
                HStack {
                    Image(systemName: "heart.fill")
                        .foregroundStyle(.red)
                    
                    VStack(alignment: .leading) {
                        Text("Made with ❤️")
                            .font(DesignTokens.Typography.subheadline)
                            .fontWeight(.semibold)
                        
                        Text("View credits & acknowledgments")
                            .font(DesignTokens.Typography.caption)
                            .foregroundStyle(DesignTokens.Colors.secondary)
                    }
                    
                    Spacer()
                    
                    Image(systemName: "chevron.right")
                        .font(.caption)
                        .foregroundStyle(DesignTokens.Colors.secondary)
                }
                .padding(DesignTokens.Spacing.md)
                .background(DesignTokens.Colors.surfaceSecondary)
                .clipShape(RoundedRectangle(cornerRadius: DesignTokens.CornerRadius.lg))
            }
            .buttonStyle(.plain)
        }
    }
    
    private var legalSection: some View {
        VStack(spacing: DesignTokens.Spacing.sm) {
            Text("Legal")
                .font(DesignTokens.Typography.headline)
                .frame(maxWidth: .infinity, alignment: .leading)
            
            LinkRow(
                icon: "doc.text",
                title: "Terms of Service",
                subtitle: "User agreement & conditions",
                url: "https://printmyride.app/terms"
            )
            
            LinkRow(
                icon: "hand.raised",
                title: "Privacy Policy",
                subtitle: "How we handle your data",
                url: "https://printmyride.app/privacy"
            )
            
            LinkRow(
                icon: "questionmark.circle",
                title: "Open Source Licenses",
                subtitle: "Third-party acknowledgments",
                action: { showingCredits = true }
            )
        }
    }
    
    private var creditsSheet: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: DesignTokens.Spacing.lg) {
                    VStack(alignment: .leading, spacing: DesignTokens.Spacing.md) {
                        Text("Development")
                            .font(DesignTokens.Typography.headline)
                        
                        VStack(alignment: .leading, spacing: DesignTokens.Spacing.sm) {
                            Text("• SwiftUI & MapKit for native iOS experience")
                            Text("• CoreLocation for GPX processing")
                            Text("• StoreKit for subscription management")
                            Text("• OSLog for debugging & analytics")
                        }
                        .font(DesignTokens.Typography.subheadline)
                        .foregroundStyle(DesignTokens.Colors.secondary)
                    }
                    
                    VStack(alignment: .leading, spacing: DesignTokens.Spacing.md) {
                        Text("Inspiration")
                            .font(DesignTokens.Typography.headline)
                        
                        Text("Built for cyclists, by cyclists. Every feature is designed with the riding community in mind.")
                            .font(DesignTokens.Typography.subheadline)
                            .foregroundStyle(DesignTokens.Colors.secondary)
                    }
                    
                    VStack(alignment: .leading, spacing: DesignTokens.Spacing.md) {
                        Text("Special Thanks")
                            .font(DesignTokens.Typography.headline)
                        
                        VStack(alignment: .leading, spacing: DesignTokens.Spacing.sm) {
                            Text("• Beta testers who provided invaluable feedback")
                            Text("• The cycling community for inspiration")
                            Text("• Open source contributors worldwide")
                        }
                        .font(DesignTokens.Typography.subheadline)
                        .foregroundStyle(DesignTokens.Colors.secondary)
                    }
                }
                .padding(DesignTokens.Spacing.md)
            }
            .navigationTitle("Credits")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") {
                        showingCredits = false
                    }
                }
            }
        }
    }
    
    private var appVersionString: String {
        let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
        let build = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1"
        return "Version \(version) (\(build))"
    }
    
    private func requestAppStoreReview() {
        #if canImport(StoreKit)
        if let scene = UIApplication.shared.connectedScenes.first(where: { $0.activationState == .foregroundActive }) as? UIWindowScene {
            SKStoreReviewController.requestReview(in: scene)
        }
        #endif
    }
}

struct LinkRow: View {
    let icon: String
    let title: String
    let subtitle: String
    var url: String?
    var action: (() -> Void)?
    
    var body: some View {
        Button {
            if let action = action {
                action()
            } else if let url = url, let nsurl = URL(string: url) {
                UIApplication.shared.open(nsurl)
            }
        } label: {
            HStack(spacing: DesignTokens.Spacing.md) {
                Image(systemName: icon)
                    .font(.title3)
                    .foregroundStyle(DesignTokens.Colors.primary)
                    .frame(width: 24)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(DesignTokens.Typography.subheadline)
                        .fontWeight(.semibold)
                        .foregroundStyle(DesignTokens.Colors.onSurface)
                    
                    Text(subtitle)
                        .font(DesignTokens.Typography.caption)
                        .foregroundStyle(DesignTokens.Colors.secondary)
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundStyle(DesignTokens.Colors.secondary)
            }
            .padding(DesignTokens.Spacing.md)
            .background(DesignTokens.Colors.surfaceSecondary)
            .clipShape(RoundedRectangle(cornerRadius: DesignTokens.CornerRadius.lg))
        }
        .buttonStyle(.plain)
    }
}

#if canImport(StoreKit)
import StoreKit
#endif