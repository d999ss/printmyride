import SwiftUI

struct SettingsView: View {
    @EnvironmentObject var library: LibraryStore
    @AppStorage("units") private var units: String = "mi"
    @AppStorage("defaultGridSpacing") private var defaultGrid: Double = 50
    @AppStorage("defaultPaperPreset") private var defaultPaper: String = "18x24"
    @State private var showStyleGuide = false

    var body: some View {
        Form {
            Section("Design") {
                Button {
                    showStyleGuide = true
                } label: {
                    HStack {
                        Text("Style Guide")
                        Spacer()
                        Image(systemName: "chevron.right").imageScale(.small).foregroundStyle(.secondary)
                    }
                }.buttonStyle(.plain)
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
                Text("Print My Ride — prototype build")
                    .font(DesignTokens.Typography.body)
                    .foregroundColor(DesignTokens.Colors.secondary)
            }
        }
        .navigationTitle("Settings")
        .sheet(isPresented: $showStyleGuide) { StyleGuideView() }
    }
}