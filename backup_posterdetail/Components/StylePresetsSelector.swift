// PrintMyRide/UI/PosterDetail/Components/StylePresetsSelector.swift
import SwiftUI

struct StylePresetsSelector: View {
    @Binding var selectedIndex: Int
    let presets: [PosterPreset]
    
    @State private var scrollID: UUID?
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Style Presets")
                    .font(.headline)
                    .foregroundColor(.primary)
                
                Spacer()
                
                if presets.count > 8 {
                    Text("\(selectedIndex + 1) of \(presets.count)")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color(.tertiarySystemBackground), in: Capsule())
                }
            }
            
            ScrollViewReader { proxy in
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 10) {
                        ForEach(Array(presets.enumerated()), id: \.offset) { index, preset in
                            StylePresetCard(
                                preset: preset,
                                isSelected: index == selectedIndex
                            )
                            .id(preset.id)
                            .onTapGesture {
                                withAnimation(.easeInOut(duration: 0.2)) {
                                    selectedIndex = index
                                }
                            }
                        }
                    }
                    .padding(.horizontal, 4)
                }
                .onChange(of: selectedIndex) { _, newIndex in
                    guard presets.indices.contains(newIndex) else { return }
                    
                    withAnimation(.easeInOut(duration: 0.3)) {
                        proxy.scrollTo(presets[newIndex].id, anchor: .center)
                    }
                }
            }
        }
    }
}

private struct StylePresetCard: View {
    let preset: PosterPreset
    let isSelected: Bool
    
    @State private var isPressed = false
    
    var body: some View {
        VStack(spacing: 8) {
            // Preview circle
            ZStack {
                Circle()
                    .fill(preset.backgroundColor)
                    .frame(width: 32, height: 32)
                    .overlay(
                        Circle()
                            .strokeBorder(preset.routeColor, lineWidth: preset.strokeWidth)
                    )
                
                if preset.hasShadow {
                    Circle()
                        .fill(preset.routeColor.opacity(0.3))
                        .frame(width: 28, height: 28)
                        .blur(radius: 2)
                        .offset(x: 1, y: 1)
                }
            }
            .shadow(
                color: isSelected ? preset.routeColor.opacity(0.4) : .clear,
                radius: isSelected ? 4 : 0
            )
            
            // Name
            Text(preset.name)
                .font(.caption.weight(.medium))
                .foregroundStyle(isSelected ? .primary : .secondary)
                .lineLimit(1)
        }
        .padding(.vertical, 12)
        .padding(.horizontal, 16)
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(isSelected ? Color(.tertiarySystemBackground) : Color(.secondarySystemBackground))
                .scaleEffect(isPressed ? 0.95 : 1.0)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .strokeBorder(
                    isSelected ? preset.routeColor.opacity(0.5) : Color.clear,
                    lineWidth: 1.5
                )
        )
        .onLongPressGesture(
            minimumDuration: 0,
            maximumDistance: .infinity,
            pressing: { pressing in
                withAnimation(.easeInOut(duration: 0.1)) {
                    isPressed = pressing
                }
            },
            perform: {}
        )
        .animation(.easeInOut(duration: 0.2), value: isSelected)
    }
}

#Preview {
    VStack(spacing: 20) {
        StylePresetsSelector(
            selectedIndex: .constant(0),
            presets: PosterStylePresets.standard.presets
        )
        
        StylePresetsSelector(
            selectedIndex: .constant(2),
            presets: PosterStylePresets.premium.presets
        )
    }
    .padding()
}