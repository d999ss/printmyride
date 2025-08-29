import SwiftUI
import MapKit

struct StyleGuideView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var settings = SettingsStore.shared
    @State private var sampleRoute: GPXRoute? = SampleRoute.route()

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {

                    // TOKENS
                    TokensSection()

                    // COMPONENTS
                    ComponentsSection()

                    // POSTER PREVIEWS
                    PosterPreviews(sampleRoute: sampleRoute)

                    // APP BEHAVIOR
                    BehaviorSection(settings: settings)

                    // RESET
                    ResetSection()
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 24)
            }
            .navigationTitle("Style Guide")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Close") { dismiss() } }
            }
        }
        .background(settings.onboardingTheme == "studio" ? Color.black : DesignTokens.ColorToken.bg)
    }
}

// MARK: - Tokens

private struct TokensSection: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionHeader("Tokens")

            // Colors
            VStack(alignment: .leading, spacing: 8) {
                Text("Colors").font(.headline)
                HStack(spacing: 12) {
                    ColorSwatch(name: "Background", color: DesignTokens.ColorToken.bg)
                    ColorSwatch(name: "Label", color: DesignTokens.ColorToken.label)
                    ColorSwatch(name: "Secondary", color: DesignTokens.ColorToken.secondary)
                    ColorSwatch(name: "Accent", color: DesignTokens.ColorToken.accent)
                }
            }

            // Typography
            VStack(alignment: .leading, spacing: 8) {
                Text("Typography").font(.headline)
                VStack(alignment: .leading, spacing: 6) {
                    Text("Title / Semibold").font(DesignTokens.FontToken.title)
                    Text("Body / Regular").font(DesignTokens.FontToken.body)
                    Text("Footnote / Regular").font(DesignTokens.FontToken.footnote).foregroundStyle(.secondary)
                    HStack { Text("12.34").font(DesignTokens.FontToken.monoFootnote); Text("monospaced digits") }
                        .foregroundStyle(.secondary)
                }
            }

            // Spacing
            VStack(alignment: .leading, spacing: 8) {
                Text("Spacing").font(.headline)
                HStack {
                    SpacerChip(label: "s", value: DesignTokens.Spacing.s)
                    SpacerChip(label: "m", value: DesignTokens.Spacing.m)
                    SpacerChip(label: "l", value: DesignTokens.Spacing.l)
                }
            }
        }
    }
}

// MARK: - Components

private struct ComponentsSection: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionHeader("Components")

            // Tool pill
            VStack(alignment: .leading, spacing: 8) {
                Text("Tool Pill").font(.headline)
                HStack(spacing: DesignTokens.Spacing.l) {
                    Image(systemName: "tray.and.arrow.down").imageScale(.large)
                    Image(systemName: "paintbrush").imageScale(.large)
                    Image(systemName: "textformat").imageScale(.large)
                    Image(systemName: "rectangle.and.pencil.and.ellipsis").imageScale(.large)
                    Image(systemName: "square.and.arrow.up").imageScale(.large)
                }
                .blurPill()
            }

            // CTAs
            HStack(spacing: DesignTokens.Spacing.m) {
                Text("Import GPX").fontWeight(.semibold)
                    .padding(.vertical, 10).padding(.horizontal, 16)
                    .foregroundStyle(.white).background(DesignTokens.ColorToken.accent, in: Capsule())
                Text("Try Sample")
                    .padding(.vertical, 10).padding(.horizontal, 16)
                    .background(.ultraThinMaterial, in: Capsule())
            }

            // Poster card
            VStack(alignment: .leading, spacing: 6) {
                Text("Poster Card").font(.headline)
                RoundedRectangle(cornerRadius: 12).fill(Color(.secondarySystemBackground))
                    .frame(width: 160, height: 213.3333)
                    .shadow(color: .black.opacity(0.10), radius: 10, y: 6)
            }
        }
    }
}

// MARK: - Poster previews

private struct PosterPreviews: View {
    let sampleRoute: GPXRoute?

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionHeader("Poster Styles")

            Text("Classic Map").font(.headline)
            PosterPreview(design: PosterDesign(), route: sampleRoute, mode: .editor)
                .frame(height: 320)
                .clipShape(RoundedRectangle(cornerRadius: 16))
                .shadow(color: .black.opacity(0.12), radius: 8, y: 4)

            Divider().padding(.vertical, 8)

            Text("Pure").font(.headline)
            PurePosterPreview(route: sampleRoute) // minimal variant
                .frame(height: 320)
                .clipShape(RoundedRectangle(cornerRadius: 16))
                .shadow(color: .black.opacity(0.12), radius: 8, y: 4)
        }
    }
}

private struct PurePosterPreview: View {
    let route: GPXRoute?
    var body: some View {
        GeometryReader { geo in
            let aspect: CGFloat = 18/24
            let w = min(geo.size.width, geo.size.height * aspect)
            let h = w / aspect
            ZStack {
                Color(.systemBackground).ignoresSafeArea()
                ZStack {
                    Rectangle().fill(Color.white)
                    CanvasView(design: PosterDesign(), route: route, drawBackground: false)
                }
                .frame(width: w, height: h)
                .shadow(color: .black.opacity(0.12), radius: 16, y: 8)
            }
        }
    }
}

// MARK: - Behavior / QA

private struct BehaviorSection: View {
    @ObservedObject var settings: SettingsStore
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionHeader("Behavior & QA")

            Group {
                Toggle("Studio theme (black)", isOn: Binding(
                    get: { settings.onboardingTheme == "studio" },
                    set: { settings.onboardingTheme = $0 ? "studio" : "light" }
                ))
                Toggle("Pager hero on onboarding", isOn: $settings.onboardingUsePager)
                Toggle("Use sample route when empty", isOn: $settings.useSampleRouteWhenEmpty)
                Toggle("Always show controls (editor)", isOn: $settings.alwaysShowControls)
                Toggle("Show info HUD", isOn: $settings.showHUD)
                Picker("Appearance", selection: $settings.appearance) {
                    Text("System").tag("system")
                    Text("Light").tag("light")
                    Text("Dark").tag("dark")
                }.pickerStyle(.segmented)
            }
            .font(DesignTokens.FontToken.body)
        }
    }
}

// MARK: - Reset

private struct ResetSection: View {
    @State private var confirm = false
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionHeader("Reset")
            Button(role: .destructive) {
                confirm = true
            } label: {
                Text("Reset style settings to defaults")
            }
            .confirmationDialog("Reset style settings?", isPresented: $confirm) {
                Button("Reset", role: .destructive) { resetDefaults() }
                Button("Cancel", role: .cancel) {}
            } message: { Text("This resets theme, HUD, pager, and defaults. It does not delete posters.") }
        }
    }
    private func resetDefaults() {
        UserDefaults.standard.set(true,  forKey: "useSampleRouteWhenEmpty")
        UserDefaults.standard.set(false, forKey: "alwaysShowControls")
        UserDefaults.standard.set(false, forKey: "showHUD")
        UserDefaults.standard.set("dark", forKey: "appearance")
        UserDefaults.standard.set(true,  forKey: "onboardingUsePager")
        UserDefaults.standard.set("studio", forKey: "onboardingTheme")
    }
}

// MARK: - Small pieces

private struct SectionHeader: View {
    let title: String
    init(_ t: String) { self.title = t }
    var body: some View {
        Text(title.uppercased())
            .font(.caption).tracking(0.8)
            .foregroundStyle(.secondary)
    }
}
private struct ColorSwatch: View {
    let name: String; let color: Color
    var body: some View {
        VStack(spacing: 6) {
            RoundedRectangle(cornerRadius: 8).fill(color).frame(width: 48, height: 36)
                .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color(.separator), lineWidth: 0.5))
            Text(name).font(.caption2).foregroundStyle(.secondary)
        }
    }
}
private struct SpacerChip: View {
    let label: String; let value: CGFloat
    var body: some View {
        VStack(spacing: 6) {
            RoundedRectangle(cornerRadius: 4)
                .fill(Color(.tertiarySystemFill))
                .frame(width: value * 2, height: 10)
            Text("\(label) = \(Int(value))").font(.caption2).foregroundStyle(.secondary)
        }
    }
}