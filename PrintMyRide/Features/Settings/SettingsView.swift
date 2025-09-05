import SwiftUI
import StoreKit

struct SettingsView: View {
    @EnvironmentObject var library: LibraryStore
    @EnvironmentObject private var gate: SubscriptionGate
    @EnvironmentObject private var appearanceManager: AppearanceManager
    @AppStorage("units") private var units: String = "mi"
    @AppStorage("defaultGridSpacing") private var defaultGrid: Double = 50
    @AppStorage("defaultPaperPreset") private var defaultPaper: String = "18x24"
    @AppStorage("pmr.mockStrava") private var mockStrava: Bool = false
    @AppStorage("pmr.useMapBackground") private var useMapBackground: Bool = true
    @State private var showStyleGuide = false

    var body: some View {
        Form {
            // Account is now first-class
            AccountSection()
            
            Section("Preview") {
                NavigationLink("Preview Demo Experience") {
                    StudioHubView()
                }
            }
            
            Section("Demo Mode") {
                Toggle("Enable Mock Strava Data", isOn: $mockStrava)
                if mockStrava {
                    Text("Import functionality enabled with sample data")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            
            Section("Maps") {
                Toggle("Use Apple Maps", isOn: $useMapBackground)
                if useMapBackground {
                    Text("Route maps will be blended into poster backgrounds")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            
            Section("Design") {
                NavigationLink("Map Preview", destination: MapPreviewView())
            }
            
            Section("General") {
                Picker("Appearance", selection: $appearanceManager.appearanceMode) {
                    ForEach(AppearanceManager.AppearanceMode.allCases, id: \.self) { mode in
                        Label(mode.displayName, systemImage: mode.iconName)
                            .font(DesignTokens.Typography.body)
                            .tag(mode)
                    }
                }
                .font(DesignTokens.Typography.body)
                
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
        .formStyle(.grouped)
        .scrollContentBackground(.hidden)
        .navigationTitle("Settings")
        .navigationBarTitleDisplayMode(.large)
    }
    
    private var appVersionString: String {
        let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
        let build = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1"
        return "Version \(version) (\(build))"
    }
}

// MARK: - Map Preview View
struct MapPreviewView: View {
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Header
                VStack(spacing: 8) {
                    Text("Generated Map Styles")
                        .font(.largeTitle.weight(.bold))
                    Text("See how your rides will look as beautiful poster maps")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                }
                .padding(.horizontal)
                
                // Preview samples
                LazyVGrid(columns: [
                    GridItem(.flexible()),
                    GridItem(.flexible())
                ], spacing: 16) {
                    
                    MapPreviewCard(
                        title: "Classic Route",
                        subtitle: "Mountain Climb • 12.4 mi",
                        routeType: "mountain",
                        color: Color(UIColor.systemBrown)
                    )
                    
                    MapPreviewCard(
                        title: "Coastal Ride",
                        subtitle: "Ocean View • 8.7 mi", 
                        routeType: "coastal",
                        color: .teal
                    )
                    
                    MapPreviewCard(
                        title: "City Loop",
                        subtitle: "Urban Circuit • 5.2 mi",
                        routeType: "city", 
                        color: .orange
                    )
                    
                    MapPreviewCard(
                        title: "Forest Trail",
                        subtitle: "Nature Path • 15.8 mi",
                        routeType: "forest",
                        color: .green
                    )
                }
                .padding(.horizontal)
                
                // Info section
                VStack(alignment: .leading, spacing: 12) {
                    Text("Map Features")
                        .font(.headline)
                    
                    VStack(alignment: .leading, spacing: 8) {
                        MapFeatureRow(icon: "map.fill", text: "High-resolution route visualization")
                        MapFeatureRow(icon: "location.fill", text: "Automatic route smoothing")
                        MapFeatureRow(icon: "paintbrush.fill", text: "Custom color themes") 
                        MapFeatureRow(icon: "square.and.arrow.up.fill", text: "Print-ready export formats")
                    }
                }
                .padding()
                .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12))
                .padding(.horizontal)
            }
        }
        .navigationTitle("Map Preview")
        .navigationBarTitleDisplayMode(.inline)
    }
}

// MARK: - Supporting Views
private struct MapPreviewCard: View {
    let title: String
    let subtitle: String
    let routeType: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 12) {
            // Mock map preview
            RoundedRectangle(cornerRadius: 12)
                .fill(color.opacity(0.1))
                .frame(height: 120)
                .overlay {
                    ZStack {
                        // Mock route path
                        Path { path in
                            switch routeType {
                            case "mountain":
                                path.move(to: CGPoint(x: 20, y: 80))
                                path.addCurve(to: CGPoint(x: 140, y: 40), 
                                            control1: CGPoint(x: 60, y: 90),
                                            control2: CGPoint(x: 100, y: 30))
                            case "coastal":
                                path.move(to: CGPoint(x: 20, y: 60))
                                path.addCurve(to: CGPoint(x: 140, y: 60),
                                            control1: CGPoint(x: 50, y: 40),
                                            control2: CGPoint(x: 110, y: 80))
                            case "city":
                                path.move(to: CGPoint(x: 30, y: 70))
                                path.addLine(to: CGPoint(x: 60, y: 70))
                                path.addLine(to: CGPoint(x: 60, y: 40))
                                path.addLine(to: CGPoint(x: 100, y: 40))
                                path.addLine(to: CGPoint(x: 100, y: 80))
                                path.addLine(to: CGPoint(x: 130, y: 80))
                            case "forest":
                                path.move(to: CGPoint(x: 25, y: 70))
                                path.addCurve(to: CGPoint(x: 135, y: 50),
                                            control1: CGPoint(x: 60, y: 30),
                                            control2: CGPoint(x: 100, y: 90))
                            default:
                                path.move(to: CGPoint(x: 20, y: 60))
                                path.addLine(to: CGPoint(x: 140, y: 60))
                            }
                        }
                        .stroke(color, lineWidth: 3)
                        .shadow(color: color.opacity(0.3), radius: 2)
                    }
                }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.headline)
                    .foregroundStyle(.primary)
                Text(subtitle)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding()
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16))
    }
}

private struct MapFeatureRow: View {
    let icon: String
    let text: String
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .foregroundStyle(Color(UIColor.systemBrown))
                .frame(width: 20)
            Text(text)
                .font(.subheadline)
            Spacer()
        }
    }
}