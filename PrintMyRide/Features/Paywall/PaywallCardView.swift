import SwiftUI
import StoreKit

struct FeatureRow: View {
    let icon: String
    let text: String
    let color: Color
    
    var body: some View {
        HStack(spacing: DesignTokens.Spacing.md) {
            Image(systemName: icon)
                .font(.body)
                .foregroundStyle(color)
                .frame(width: 24)
            
            Text(text)
                .font(DesignTokens.Typography.subheadline)
                .foregroundStyle(DesignTokens.Colors.onSurface)
            
            Spacer()
        }
    }
}

struct PaywallCardView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var gate: SubscriptionGate
    @State private var products: [Product] = []
    @State private var loading = false
    @State private var purchasingID: String?
    @State private var error: String?

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: DesignTokens.Spacing.lg) {
                    // Hero Section
                    VStack(spacing: DesignTokens.Spacing.md) {
                        ZStack {
                            LinearGradient(
                                colors: [
                                    DesignTokens.Colors.primary.opacity(0.8),
                                    DesignTokens.Colors.accent.opacity(0.6)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                            .frame(height: 120)
                            .clipShape(RoundedRectangle(cornerRadius: DesignTokens.CornerRadius.xl))
                            
                            VStack(spacing: DesignTokens.Spacing.sm) {
                                Image(systemName: "crown.fill")
                                    .font(.system(size: 40))
                                    .foregroundStyle(.white)
                                
                                Text("PrintMyRide Pro")
                                    .font(DesignTokens.Typography.title)
                                    .foregroundStyle(.white)
                            }
                        }
                        
                        VStack(spacing: DesignTokens.Spacing.sm) {
                            Text("Transform Every Ride Into Art")
                                .font(DesignTokens.Typography.headline)
                                .multilineTextAlignment(.center)
                            
                            Text("Unlock unlimited high-resolution exports, exclusive templates, and priority features.")
                                .font(DesignTokens.Typography.subheadline)
                                .foregroundStyle(DesignTokens.Colors.secondary)
                                .multilineTextAlignment(.center)
                        }
                    }
                    .padding(.horizontal, DesignTokens.Spacing.sm)
                    // Subscription Options
                    VStack(spacing: DesignTokens.Spacing.md) {
                        if loading {
                            ProgressView()
                                .padding(.vertical, DesignTokens.Spacing.lg)
                        } else {
                            ForEach(products, id: \.id) { product in
                                Button {
                                    Task { await buy(product) }
                                } label: {
                                    HStack {
                                        VStack(alignment: .leading, spacing: 4) {
                                            HStack(spacing: DesignTokens.Spacing.xs) {
                                                Text(title(for: product))
                                                    .font(DesignTokens.Typography.headline)
                                                    .foregroundStyle(DesignTokens.Colors.onSurface)
                                                
                                                if product.id.contains("annual") {
                                                    Text("SAVE 20%")
                                                        .font(.caption)
                                                        .fontWeight(.bold)
                                                        .padding(.horizontal, 6)
                                                        .padding(.vertical, 2)
                                                        .background(DesignTokens.Colors.success)
                                                        .foregroundStyle(.white)
                                                        .clipShape(RoundedRectangle(cornerRadius: 4))
                                                }
                                            }
                                            
                                            Text(subtitle(for: product))
                                                .font(DesignTokens.Typography.caption)
                                                .foregroundStyle(DesignTokens.Colors.secondary)
                                        }
                                        
                                        Spacer()
                                        
                                        if purchasingID == product.id {
                                            ProgressView()
                                        } else {
                                            VStack(alignment: .trailing, spacing: 2) {
                                                Text(product.displayPrice)
                                                    .font(DesignTokens.Typography.headline)
                                                    .foregroundStyle(DesignTokens.Colors.primary)
                                                
                                                if product.id.contains("annual") {
                                                    Text(pricePerMonth(for: product))
                                                        .font(.caption2)
                                                        .foregroundStyle(DesignTokens.Colors.secondary)
                                                }
                                            }
                                        }
                                    }
                                    .padding(DesignTokens.Spacing.md)
                                    .background(
                                        RoundedRectangle(cornerRadius: DesignTokens.CornerRadius.button, style: .continuous)
                                            .fill(.ultraThinMaterial)
                                            .overlay(
                                                RoundedRectangle(cornerRadius: DesignTokens.CornerRadius.button, style: .continuous)
                                                    .stroke(product.id.contains("annual") ?
                                                           DesignTokens.Colors.primary :
                                                           .white.opacity(0.18), lineWidth: product.id.contains("annual") ? 2 : 1)
                                            )
                                    )
                                }
                                .buttonStyle(.plain)
                            }
                            // Fallback: demo enable if products missing
                            if products.isEmpty && !loading {
                                Button {
                                    gate.isSubscribed = true
                                    dismiss()
                                } label: {
                                    Text("Enable Demo Subscription")
                                        .font(DesignTokens.Typography.callout)
                                        .fontWeight(.semibold)
                                        .padding(.horizontal, DesignTokens.Spacing.lg)
                                        .padding(.vertical, DesignTokens.Spacing.md)
                                }
                                .buttonStyle(.bordered)
                                
                                Text("StoreKit products not loaded — using demo unlock.")
                                    .font(DesignTokens.Typography.caption2)
                                    .foregroundStyle(DesignTokens.Colors.secondary)
                            }
                        }
                    }
                    // Features List
                    VStack(spacing: DesignTokens.Spacing.md) {
                        Text("Everything in Pro")
                            .font(DesignTokens.Typography.headline)
                            .frame(maxWidth: .infinity, alignment: .leading)
                        
                        VStack(spacing: DesignTokens.Spacing.sm) {
                            FeatureRow(icon: "checkmark.circle.fill", text: "Unlimited high-resolution exports", color: .green)
                            FeatureRow(icon: "printer.fill", text: "Print-ready formats (18×24, A2, A3)", color: Color(UIColor.systemBrown))
                            FeatureRow(icon: "paintbrush.fill", text: "Exclusive poster templates", color: .purple)
                            FeatureRow(icon: "map.fill", text: "Advanced map overlays", color: .orange)
                            FeatureRow(icon: "bolt.fill", text: "Priority processing", color: .yellow)
                            FeatureRow(icon: "cloud.fill", text: "Cloud backup (coming soon)", color: .cyan)
                        }
                    }
                    .padding(DesignTokens.Spacing.md)
                    .background(
                        RoundedRectangle(cornerRadius: DesignTokens.CornerRadius.lg)
                            .fill(DesignTokens.Colors.surfaceSecondary)
                    )
                    
                    // Trust badges
                    HStack(spacing: DesignTokens.Spacing.lg) {
                        VStack {
                            Image(systemName: "lock.shield.fill")
                                .font(.title2)
                                .foregroundStyle(DesignTokens.Colors.primary)
                            Text("Secure")
                                .font(DesignTokens.Typography.caption)
                                .foregroundStyle(DesignTokens.Colors.secondary)
                        }
                        
                        VStack {
                            Image(systemName: "arrow.triangle.2.circlepath")
                                .font(.title2)
                                .foregroundStyle(DesignTokens.Colors.primary)
                            Text("Cancel Anytime")
                                .font(DesignTokens.Typography.caption)
                                .foregroundStyle(DesignTokens.Colors.secondary)
                        }
                        
                        VStack {
                            Image(systemName: "star.fill")
                                .font(.title2)
                                .foregroundStyle(DesignTokens.Colors.primary)
                            Text("4.9 Rating")
                                .font(DesignTokens.Typography.caption)
                                .foregroundStyle(DesignTokens.Colors.secondary)
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, DesignTokens.Spacing.md)
                    // Footer links
                    HStack(spacing: DesignTokens.Spacing.md) {
                        Button("Restore Purchases") {
                            Task { await restorePurchases() }
                        }
                        .font(DesignTokens.Typography.caption)
                        .foregroundStyle(DesignTokens.Colors.primary)
                        
                        Text("•")
                            .foregroundStyle(DesignTokens.Colors.secondary)
                        
                        Link("Terms", destination: URL(string: "https://printmyride.app/terms")!)
                            .font(DesignTokens.Typography.caption)
                            .foregroundStyle(DesignTokens.Colors.primary)
                        
                        Text("•")
                            .foregroundStyle(DesignTokens.Colors.secondary)
                        
                        Link("Privacy", destination: URL(string: "https://printmyride.app/privacy")!)
                            .font(DesignTokens.Typography.caption)
                            .foregroundStyle(DesignTokens.Colors.primary)
                    }
                    .padding(.bottom, DesignTokens.Spacing.xl)
                }
                .padding(DesignTokens.Spacing.md)
            }
            .navigationTitle("Try Pro")
            .toolbar { ToolbarItem(placement: .topBarTrailing) { Button("Close") { dismiss() } } }
            .background(.clear)
        }
        .task(loadProducts)
        .alert("Purchase Error", isPresented: .constant(error != nil)) {
            Button("OK") { self.error = nil }
        } message: { Text(error ?? "") }
    }

    // MARK: - Helpers
    private func loadProducts() async {
        loading = true; defer { loading = false }
        do {
            let ids: Set<String> = ["com.printmyride.sub.monthly","com.printmyride.sub.annual"]
            let res = try await Product.products(for: ids)
            products = res.filter { $0.type == .autoRenewable }
        } catch { products = [] }
    }
    private func buy(_ product: Product) async {
        purchasingID = product.id; defer { purchasingID = nil }
        do {
            let result = try await product.purchase()
            switch result {
            case .success(let ver):
                if case .verified = ver {
                    await MainActor.run { gate.isSubscribed = true }
                    dismiss()
                } else {
                    self.error = "Could not verify transaction."
                }
            case .userCancelled, .pending: break
            @unknown default: break
            }
        } catch { self.error = "Purchase failed. Try again." }
    }
    private func title(for p: Product) -> String { 
        p.id.contains("annual") ? "Annual Plan" : "Monthly Plan" 
    }
    
    private func subtitle(for p: Product) -> String { 
        p.id.contains("annual") ? "Best value • Billed yearly" : "Most flexible • Billed monthly" 
    }
    
    private func pricePerMonth(for p: Product) -> String {
        guard p.id.contains("annual") else { return "" }
        // Assuming annual price, divide by 12 for monthly equivalent
        // This is a simplified version - in production you'd parse the actual price
        return "per month"
    }
    
    private func restorePurchases() async {
        loading = true
        defer { loading = false }
        
        do {
            try await AppStore.sync()
            // Check entitlements after sync
            for await result in Transaction.currentEntitlements {
                if case .verified(_) = result {
                    await MainActor.run { gate.isSubscribed = true }
                    dismiss()
                    return
                }
            }
            await MainActor.run {
                self.error = "No active subscriptions found."
            }
        } catch {
            await MainActor.run {
                self.error = "Failed to restore purchases. Please try again."
            }
        }
    }
}