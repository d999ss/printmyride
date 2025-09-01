import SwiftUI
import StoreKit

// Minimal entitlement helper (reuse your app-wide one if present)
@MainActor
final class SubscriptionGateLocal: ObservableObject {
    @Published var isSubscribed = false
    init() { Task { await refresh() } }
    func refresh() async {
        for await state in Transaction.currentEntitlements {
            if case .verified(let txn) = state, txn.productType == .autoRenewable {
                isSubscribed = true; return
            }
        }
        isSubscribed = false
    }
}

struct SettingsView: View {
    @StateObject private var vm = SettingsViewModel()
    @EnvironmentObject private var oauth: StravaOAuth
    @EnvironmentObject private var services: ServiceHub
    @StateObject private var gate = SubscriptionGateLocal()
    @Environment(\.dismiss) private var dismiss
    @State private var showAddress = false
    @State private var showClearConfirm = false

    var body: some View {
        List {
            Section("Account & Profile") {
                HStack {
                    Circle().fill(Color.gray.opacity(0.2)).frame(width: 44, height: 44)
                        .overlay(Image(systemName: "person.fill").imageScale(.large))
                    VStack(alignment: .leading) {
                        Text("Donny").font(.headline) // placeholder; wire to profile later
                        Text(vm.units == "mi" ? "Units: Miles" : "Units: Kilometers")
                            .font(.caption).foregroundStyle(.secondary)
                    }
                }
                Picker("Units", selection: $vm.units) {
                    Text("Miles").tag("mi")
                    Text("Kilometers").tag("km")
                }
            }

            Section("Subscription") {
                HStack {
                    Label(gate.isSubscribed ? "Active" : "Not Subscribed", systemImage: gate.isSubscribed ? "checkmark.seal.fill" : "xmark.seal")
                        .foregroundStyle(gate.isSubscribed ? .green : .red)
                    Spacer()
                    Button("Manage") { Task { try? await AppStore.showManageSubscriptions(in: nil) } }
                }
                Button("Restore Purchases") { Task { try? await AppStore.sync() ; await gate.refresh() } }
            }

            Section("Connected Services") {
                Toggle("Demo Mode (Mock Strava)", isOn: $services.mockStrava)
                HStack {
                    Label("Strava", systemImage: "figure.walk")
                    Spacer()
                    if services.mockStrava || oauth.isConnected {
                        Button("Disconnect") { 
                            if services.mockStrava {
                                services.mockStrava = false
                            } else {
                                oauth.disconnect()
                            }
                        }
                    } else {
                        Button("Connect") { oauth.startLogin() }
                    }
                }
            }

            Section("Poster Defaults") {
                Picker("Theme", selection: $vm.theme) {
                    Text("Topo").tag("Topo")
                    Text("Route").tag("Route")
                    Text("Minimal").tag("Minimal")
                }
                Picker("Default Size", selection: $vm.posterSize) {
                    Text("18×24").tag("18x24")
                    Text("A2").tag("A2")
                    Text("A3").tag("A3")
                }
                Toggle("Captions", isOn: .constant(true)) // wire later
                    .disabled(true)
            }

            Section("Orders & Addresses") {
                Button("Shipping Address") { showAddress = true }
                Button("Order History") {}.disabled(true) // wire when print partner live
            }

            Section("Notifications") {
                Toggle("Order Updates", isOn: $vm.notificationsEnabled)
                    .onChange(of: vm.notificationsEnabled) { _, on in if on { vm.requestNotifications() } }
            }

            Section("Data & Privacy") {
                Toggle("Analytics Opt-In", isOn: $vm.analyticsOptIn)
                Toggle("Crash Reporting", isOn: $vm.crashOptIn)
                Button("Export My Data") { vm.exportData() }
                Button(role: .destructive) { showClearConfirm = true } label: {
                    Text("Clear Local Poster Data")
                }
            }

            Section("About & Support") {
                HStack {
                    Text("Version")
                    Spacer()
                    Text(Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "—")
                }
                Button("Rate on the App Store") { 
                    if let url = URL(string: "itms-apps://itunes.apple.com/app/id000000000?action=write-review") { UIApplication.shared.open(url) }
                }
                Button("Email Support") {
                    if let url = URL(string: "mailto:support@printmyride.app") { UIApplication.shared.open(url) }
                }
            }
        }
        .navigationTitle("Settings")
        .sheet(isPresented: $showAddress) { AddressEditor(addressStore: vm.addressStore) }
        .alert("Clear Local Poster Data?", isPresented: $showClearConfirm) {
            Button("Cancel", role: .cancel) {}
            Button("Clear", role: .destructive) { vm.clearLocalData() }
        } message: {
            Text("This removes downloaded posters and the local index. It does not affect your subscription.")
        }
    }
}

private struct AddressEditor: View {
    @ObservedObject var addressStore: AddressStore
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("Full Name", text: $addressStore.address.fullName)
                    TextField("Address Line 1", text: $addressStore.address.line1)
                    TextField("Address Line 2", text: $addressStore.address.line2)
                    TextField("City", text: $addressStore.address.city)
                    TextField("State", text: $addressStore.address.state)
                    TextField("Postal Code", text: $addressStore.address.postalCode)
                    TextField("Country", text: $addressStore.address.country)
                }
            }
            .navigationTitle("Shipping Address")
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { addressStore.save(); dismiss() }
                }
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
        }
    }
}