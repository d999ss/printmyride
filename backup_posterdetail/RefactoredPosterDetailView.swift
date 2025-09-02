// PrintMyRide/UI/PosterDetail/RefactoredPosterDetailView.swift
import SwiftUI
import MapKit

struct RefactoredPosterDetailView: View {
    // MARK: - Environment
    @Environment(\.dismiss) private var dismiss
    @StateObject private var viewModel = PosterDetailViewModel()
    
    // MARK: - Data
    let rideTitle: String
    let rideSubtitle: String
    let coordinates: [CLLocationCoordinate2D]
    let distanceMeters: Double
    let elevationMeters: Double
    let durationSeconds: Double
    let date: Date
    
    // MARK: - Layout Constants
    private let horizontalPadding: CGFloat = 16
    private let posterAspectRatio: CGFloat = 18.0/24.0
    
    init(
        rideTitle: String,
        rideSubtitle: String = "",
        coordinates: [CLLocationCoordinate2D],
        distanceMeters: Double = 0,
        elevationMeters: Double = 0,
        durationSeconds: Double = 0,
        date: Date = Date()
    ) {
        self.rideTitle = rideTitle
        self.rideSubtitle = rideSubtitle
        self.coordinates = coordinates
        self.distanceMeters = distanceMeters
        self.elevationMeters = elevationMeters
        self.durationSeconds = durationSeconds
        self.date = date
    }
    
    var body: some View {
        ScrollView {
            LazyVStack(spacing: 20) {
                // Header
                HeaderSection()
                
                // Poster Hero
                PosterSection()
                
                // Quick Actions
                ActionsSection()
                
                // Statistics
                StatisticsSection()
                
                // Style Presets
                StyleSection()
                
                // Map Controls
                MapControlsSection()
                
                // Caption Editor
                CaptionSection()
                
                // Variants (placeholder for now)
                VariantsSection()
            }
            .padding(.horizontal, horizontalPadding)
            .padding(.vertical, 8)
        }
        .overlay(alignment: .bottom) {
            if let toast = viewModel.toast {
                ToastView(message: toast)
                    .padding(.bottom, 16)
            }
        }
        .navigationBarBackButtonHidden(true)
        .task {
            await setupInitialData()
        }
    }
    
    // MARK: - Sections
    private func HeaderSection() -> some View {
        HStack(spacing: 12) {
            Button { dismiss() } label: {
                Image(systemName: "chevron.left")
                    .font(.title3.weight(.semibold))
                    .foregroundStyle(.primary)
            }
            
            VStack(alignment: .leading, spacing: 2) {
                Text(rideTitle)
                    .font(.title3.weight(.semibold))
                    .lineLimit(1)
                
                if !rideSubtitle.isEmpty {
                    Text(rideSubtitle)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }
            }
            
            Spacer()
            
            // Status indicator
            RouteStatusIndicator(
                coordinateCount: viewModel.rideData.coordinates.count
            )
            
            FavoriteButton(isFavorite: $viewModel.isFavorite)
            ProBadgeView()
        }
    }
    
    private func PosterSection() -> some View {
        PosterHeroView(
            image: viewModel.generatedImage,
            isLoading: viewModel.isGenerating,
            aspectRatio: posterAspectRatio
        )
        .task(id: viewModel.selectedPresetIndex) {
            await viewModel.render(size: CGSize(width: 1200, height: 1600))
        }
    }
    
    private func ActionsSection() -> some View {
        QuickActionsBar(
            onExport: { viewModel.exportPDF() },
            onShare: { viewModel.shareImage() },
            onPrint: { viewModel.printPoster() },
            onSaveMap: { viewModel.saveMapSnapshot() }
        )
    }
    
    private func StatisticsSection() -> some View {
        StatisticsGrid(rideData: viewModel.rideData)
    }
    
    private func StyleSection() -> some View {
        StylePresetsSelector(
            selectedIndex: $viewModel.selectedPresetIndex,
            presets: viewModel.stylePresets.presets
        )
    }
    
    private func MapControlsSection() -> some View {
        MapControlsView(
            useMapBackground: $viewModel.useMapBackground,
            mapStyle: $viewModel.mapStyle
        )
    }
    
    private func CaptionSection() -> some View {
        CaptionEditor(
            title: viewModel.rideData.title,
            subtitle: viewModel.rideData.subtitle
        ) { newTitle, newSubtitle in
            Task {
                viewModel.rideData.title = newTitle
                viewModel.rideData.subtitle = newSubtitle
                await viewModel.render(size: CGSize(width: 1200, height: 1600))
            }
        }
    }
    
    private func VariantsSection() -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Variants")
                .font(.headline)
                .foregroundColor(.primary)
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(0..<6, id: \.self) { index in
                        VariantPlaceholder(index: index)
                    }
                }
                .padding(.horizontal, 4)
            }
        }
        .padding(.bottom, 24)
    }
    
    // MARK: - Setup
    private func setupInitialData() async {
        viewModel.rideData = RideData(
            title: rideTitle,
            subtitle: rideSubtitle,
            coordinates: coordinates,
            distanceMeters: distanceMeters,
            elevationMeters: elevationMeters,
            durationSeconds: durationSeconds,
            date: date
        )
        
        await viewModel.render(size: CGSize(width: 1200, height: 1600))
    }
}

// MARK: - Supporting Views
private struct RouteStatusIndicator: View {
    let coordinateCount: Int
    
    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: coordinateCount > 0 ? "checkmark.circle.fill" : "xmark.circle.fill")
                .foregroundStyle(coordinateCount > 0 ? .green : .red)
            
            Text(coordinateCount > 0 ? "\(coordinateCount) pts" : "No route")
                .font(.caption2)
                .foregroundStyle(coordinateCount > 0 ? .secondary : .red)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(
            Capsule()
                .fill(coordinateCount > 0 ? Color(.systemGreen).opacity(0.1) : Color(.systemRed).opacity(0.1))
        )
    }
}

private struct FavoriteButton: View {
    @Binding var isFavorite: Bool
    
    var body: some View {
        Button {
            withAnimation(.easeInOut(duration: 0.2)) {
                isFavorite.toggle()
            }
        } label: {
            Image(systemName: isFavorite ? "heart.fill" : "heart")
                .foregroundStyle(isFavorite ? .red : .secondary)
                .font(.title3)
        }
        .scaleEffect(isFavorite ? 1.1 : 1.0)
        .animation(.spring(response: 0.3, dampingFraction: 0.6), value: isFavorite)
    }
}

private struct ProBadgeView: View {
    @ObservedObject private var accountStore = AccountStore.shared
    
    var body: some View {
        Group {
            if accountStore.account.isPro {
                Text("PRO")
                    .font(.caption2.weight(.bold))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(
                        LinearGradient(
                            colors: [.yellow, .orange],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        in: Capsule()
                    )
            } else {
                Button {
                    NotificationCenter.default.post(name: .pmrRequestPaywall, object: nil)
                } label: {
                    Text("Go Pro")
                        .font(.caption2.weight(.medium))
                        .foregroundStyle(.blue)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color(.systemBlue).opacity(0.15), in: Capsule())
                }
            }
        }
    }
}

private struct MapControlsView: View {
    @Binding var useMapBackground: Bool
    @Binding var mapStyle: Int
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Map Settings")
                .font(.headline)
                .foregroundColor(.primary)
            
            Toggle("Apple Maps Background", isOn: $useMapBackground)
                .toggleStyle(SwitchToggleStyle(tint: .blue))
            
            if useMapBackground {
                MapStylePicker(selection: $mapStyle)
                    .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .animation(.easeInOut(duration: 0.2), value: useMapBackground)
    }
}

private struct MapStylePicker: View {
    @Binding var selection: Int
    let styles = ["Standard", "Hybrid", "Satellite"]
    
    var body: some View {
        Picker("Map Style", selection: $selection) {
            ForEach(styles.indices, id: \.self) { index in
                Text(styles[index]).tag(index)
            }
        }
        .pickerStyle(.segmented)
    }
}

private struct CaptionEditor: View {
    @State private var editedTitle: String
    @State private var editedSubtitle: String
    
    let onUpdate: (String, String) -> Void
    
    init(title: String, subtitle: String, onUpdate: @escaping (String, String) -> Void) {
        _editedTitle = State(initialValue: title)
        _editedSubtitle = State(initialValue: subtitle)
        self.onUpdate = onUpdate
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Captions")
                .font(.headline)
                .foregroundColor(.primary)
            
            TextField("Poster title", text: $editedTitle)
                .textFieldStyle(.roundedBorder)
                .onSubmit { applyChanges() }
            
            TextField("Subtitle (optional)", text: $editedSubtitle)
                .textFieldStyle(.roundedBorder)
                .onSubmit { applyChanges() }
            
            HStack {
                Spacer()
                Button("Apply Changes") {
                    applyChanges()
                }
                .buttonStyle(.borderedProminent)
                .disabled(editedTitle.isEmpty)
            }
        }
    }
    
    private func applyChanges() {
        onUpdate(editedTitle, editedSubtitle)
    }
}

private struct VariantPlaceholder: View {
    let index: Int
    
    var body: some View {
        RoundedRectangle(cornerRadius: 12, style: .continuous)
            .fill(Color(.secondarySystemBackground))
            .frame(width: 100, height: 133) // Maintains poster aspect ratio
            .overlay(
                VStack(spacing: 4) {
                    Image(systemName: "photo")
                        .foregroundStyle(.tertiary)
                        .font(.title2)
                    
                    Text("Variant \(index + 1)")
                        .font(.caption2)
                        .foregroundStyle(.tertiary)
                }
            )
    }
}

private struct ToastView: View {
    let message: ToastMessage
    
    var body: some View {
        Text(message.text)
            .font(.subheadline.weight(.medium))
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background(
                .ultraThinMaterial,
                in: Capsule()
            )
            .overlay(
                Capsule()
                    .strokeBorder(message.color.opacity(0.3), lineWidth: 1)
            )
            .shadow(radius: 8, y: 4)
            .transition(.move(edge: .bottom).combined(with: .opacity))
    }
}

#Preview {
    RefactoredPosterDetailView(
        rideTitle: "Morning Mountain Ride",
        rideSubtitle: "Epic climbing session",
        coordinates: [
            CLLocationCoordinate2D(latitude: 37.7749, longitude: -122.4194),
            CLLocationCoordinate2D(latitude: 37.7849, longitude: -122.4094)
        ],
        distanceMeters: 32180,
        elevationMeters: 500,
        durationSeconds: 3600,
        date: Date()
    )
}