import SwiftUI
import StoreKit

struct SettingsView: View {
    @EnvironmentObject var library: LibraryStore
    @EnvironmentObject private var gate: SubscriptionGate
    @AppStorage("units") private var units: String = "mi"
    @AppStorage("defaultGridSpacing") private var defaultGrid: Double = 50
    @AppStorage("defaultPaperPreset") private var defaultPaper: String = "18x24"
    @AppStorage("pmr.mockStrava") private var mockStrava: Bool = false
    @AppStorage("pmr.useMapBackground") private var useMapBackground: Bool = false
    @State private var showStyleGuide = false

    var body: some View {
        Form {
            Section("Preview") {
                NavigationLink("Preview Demo Experience") {
                    StudioHubView()
                }
            }
            
            Section("Demo Mode") {
                HStack {
                    Label("Enable Mock Strava Data", systemImage: "bicycle.circle.fill")
                        .font(DesignTokens.Typography.body)
                    Spacer()
                    Toggle("", isOn: $mockStrava)
                }
                if mockStrava {
                    HStack {
                        Image(systemName: "info.circle")
                            .foregroundStyle(DesignTokens.Colors.secondary)
                            .imageScale(.small)
                        Text("Import functionality enabled with sample data")
                            .font(DesignTokens.Typography.caption)
                            .foregroundStyle(DesignTokens.Colors.secondary)
                    }
                }
            }
            
            Section("Maps") {
                HStack {
                    Label("Use Apple Maps Background in Posters", systemImage: "map.fill")
                        .font(DesignTokens.Typography.body)
                    Spacer()
                    Toggle("", isOn: $useMapBackground)
                }
                if useMapBackground {
                    HStack {
                        Image(systemName: "info.circle")
                            .foregroundStyle(DesignTokens.Colors.secondary)
                            .imageScale(.small)
                        Text("Route maps will be blended into poster backgrounds")
                            .font(DesignTokens.Typography.caption)
                            .foregroundStyle(DesignTokens.Colors.secondary)
                    }
                }
            }
            
            Section("Subscription") {
                HStack {
                    Label(gate.isSubscribed ? "Pro Active" : "Not Subscribed", systemImage: gate.isSubscribed ? "crown.fill" : "crown")
                        .foregroundStyle(gate.isSubscribed ? DesignTokens.Colors.accent : DesignTokens.Colors.secondary)
                        .font(DesignTokens.Typography.body)
                    Spacer()
                    Button("Manage") { 
                        // For demo - would normally show App Store subscriptions
                    }
                    .font(DesignTokens.Typography.body)
                    .foregroundStyle(DesignTokens.Colors.primary)
                }
                
                Button("Restore Purchases") { 
                    Task { await gate.refresh() } 
                }
                .font(DesignTokens.Typography.body)
            }
            
            Section("Design") {
                Button {
                    showStyleGuide = true
                } label: {
                    HStack {
                        Label("Style Guide", systemImage: "paintbrush.fill")
                            .font(DesignTokens.Typography.body)
                        Spacer()
                        Image(systemName: "chevron.right")
                            .imageScale(.small)
                            .foregroundStyle(DesignTokens.Colors.secondary)
                    }
                }
                .buttonStyle(.plain)
                .foregroundStyle(DesignTokens.Colors.onSurface)
            }
            
            Section("General") {
                Picker("Units", selection: $units) {
                    Text("Miles")
                        .font(DesignTokens.Typography.body)
                        .tag("mi")
                    Text("Kilometers")
                        .font(DesignTokens.Typography.body)
                        .tag("km")
                }
                .font(DesignTokens.Typography.body)
                
                Stepper("Default grid \(Int(defaultGrid)) pt", value: $defaultGrid, in: 10...200, step: 10)
                    .font(DesignTokens.Typography.body)
                
                Picker("Default paper", selection: $defaultPaper) {
                    Text("18×24 in")
                        .font(DesignTokens.Typography.body)
                        .tag("18x24")
                    Text("24×36 in")
                        .font(DesignTokens.Typography.body)
                        .tag("24x36")
                    Text("A2")
                        .font(DesignTokens.Typography.body)
                        .tag("A2")
                }
                .font(DesignTokens.Typography.body)
            }
            
            Section {
                Button("Clear Library", role: .destructive) { 
                    library.projects.removeAll()
                    library.save() 
                }
                .font(DesignTokens.Typography.body)
            }
            
            Section("About") { 
                NavigationLink {
                    AboutView()
                } label: {
                    HStack {
                        Label {
                            VStack(alignment: .leading) {
                                Text("PrintMyRide")
                                    .font(DesignTokens.Typography.body)
                                Text(appVersionString)
                                    .font(DesignTokens.Typography.caption)
                                    .foregroundStyle(DesignTokens.Colors.secondary)
                            }
                        } icon: {
                            Image(systemName: "info.circle.fill")
                                .foregroundStyle(DesignTokens.Colors.primary)
                        }
                        Spacer()
                        Image(systemName: "chevron.right")
                            .imageScale(.small)
                            .foregroundStyle(DesignTokens.Colors.secondary)
                    }
                }
                .foregroundStyle(DesignTokens.Colors.onSurface)
            }
        }
        .navigationTitle("Settings")
        .navigationBarTitleDisplayMode(.large)
        .sheet(isPresented: $showStyleGuide) { StyleGuideView() }
    }
    
    private var appVersionString: String {
        let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
        let build = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1"
        return "Version \(version) (\(build))"
    }
}