// PrintMyRide/UI/Paywall/PaywallPlaceholder.swift
import SwiftUI

struct PaywallPlaceholder: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject private var accountStore = AccountStore.shared
    
    var body: some View {
        NavigationView {
            VStack(spacing: 24) {
                // Hero
                VStack(spacing: 16) {
                    Image(systemName: "crown.fill")
                        .font(.system(size: 60))
                        .foregroundStyle(.yellow)
                        .shadow(radius: 10)
                    
                    Text("PrintMyRide Pro")
                        .font(.largeTitle.bold())
                    
                    Text("Unlock premium features")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                .padding(.top, 40)
                
                // Features
                VStack(alignment: .leading, spacing: 16) {
                    ProFeatureRow(icon: "square.and.arrow.up", 
                              title: "Hi-res PDF Export",
                              subtitle: "Print-quality posters")
                    
                    ProFeatureRow(icon: "map.fill",
                              title: "Apple Maps Backgrounds",
                              subtitle: "Satellite & hybrid styles")
                    
                    ProFeatureRow(icon: "paintbrush.fill",
                              title: "All Poster Styles",
                              subtitle: "Premium templates")
                    
                    ProFeatureRow(icon: "infinity",
                              title: "Unlimited Saves",
                              subtitle: "No restrictions")
                }
                .padding(.horizontal, 32)
                
                Spacer()
                
                // CTA buttons
                VStack(spacing: 12) {
                    #if DEBUG
                    Button {
                        accountStore.grantPro(until: Date().addingTimeInterval(86400 * 30)) // 30 days
                        dismiss()
                    } label: {
                        Text("Debug: Grant Pro (30 days)")
                            .font(.headline)
                            .foregroundStyle(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.green)
                            .cornerRadius(12)
                    }
                    #endif
                    
                    Button {
                        // TODO: Real StoreKit purchase
                        dismiss()
                    } label: {
                        Text("Subscribe • $4.99/month")
                            .font(.headline)
                            .foregroundStyle(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(
                                LinearGradient(
                                    colors: [.orange, .pink],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .cornerRadius(12)
                    }
                    
                    Button {
                        dismiss()
                    } label: {
                        Text("Maybe Later")
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                    }
                }
                .padding(.horizontal, 32)
                .padding(.bottom, 32)
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .symbolRenderingMode(.hierarchical)
                            .foregroundStyle(.secondary)
                    }
                }
            }
        }
    }
}

private struct ProFeatureRow: View {
    let icon: String
    let title: String
    let subtitle: String
    
    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundStyle(.orange)
                .frame(width: 36)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.headline)
                Text(subtitle)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            
            Spacer()
        }
    }
}