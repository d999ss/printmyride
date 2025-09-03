// PrintMyRide/UI/Settings/AccountSection.swift
import SwiftUI

struct AccountSection: View {
    @ObservedObject var store = AccountStore.shared
    @State private var showingConfirmDelete = false

    var body: some View {
        Section(header: Text("ACCOUNT")) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text(store.account.displayName ?? "Guest")
                        .font(.headline)
                    Text("ID \(store.account.userId.prefix(8)) • \(store.account.tier.rawValue.uppercased())")
                        .font(.caption).foregroundStyle(.secondary)
                }
                Spacer()
                if store.account.isPro {
                    Text("Pro").font(.caption2.bold())
                        .padding(.vertical, 4).padding(.horizontal, 8)
                        .background(Color.yellow.opacity(0.2), in: Capsule())
                }
            }

            // Auth buttons
            if store.account.tier == .guest {
                Button {
                    // hook up SIWA later; for now mock sign-in:
                    store.signInWithApple(displayName: "You", emailHash: nil)
                } label: { 
                    Label("Sign in with Apple", systemImage: "applelogo") 
                }
            } else {
                Button(role: .destructive) {
                    store.signOutAndResetToGuest()
                } label: { 
                    Label("Sign out", systemImage: "rectangle.portrait.and.arrow.right") 
                }
            }

            // Pro management
            if !store.account.isPro {
                Button { 
                    NotificationCenter.default.post(name: .pmrRequestPaywall, object: nil) 
                } label: {
                    Label("Try Pro", systemImage: "crown")
                }
                #if DEBUG
                Button { 
                    store.grantPro() 
                } label: { 
                    Label("Debug: Grant Pro", systemImage: "checkmark.shield")
                        .foregroundColor(.green)
                }
                #endif
            } else {
                #if DEBUG
                Button { 
                    store.revokePro() 
                } label: { 
                    Label("Debug: Revoke Pro", systemImage: "xmark.shield")
                        .foregroundColor(.orange)
                }
                #endif
                
                if let expires = store.account.proExpiresAt {
                    HStack {
                        Text("Pro expires")
                            .foregroundStyle(.secondary)
                        Spacer()
                        Text(expires, style: .relative)
                            .foregroundStyle(.secondary)
                    }
                    .font(.caption)
                }
            }

            // Strava
            Toggle(isOn: Binding(
                get: { store.account.stravaLinked },
                set: { store.setStravaLinked($0) }
            )) {
                Label("Strava linked", systemImage: "bolt.horizontal.icloud")
            }

            // Danger zone
            Button(role: .destructive) { 
                showingConfirmDelete = true 
            } label: {
                Label("Delete local account & data", systemImage: "trash")
            }
            .confirmationDialog("Delete local account & data?",
                                isPresented: $showingConfirmDelete, 
                                titleVisibility: .visible) {
                Button("Delete", role: .destructive) { 
                    store.deleteAllLocalData() 
                }
                Button("Cancel", role: .cancel) {}
            }
        }
    }
}

