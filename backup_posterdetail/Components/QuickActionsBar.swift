// PrintMyRide/UI/PosterDetail/Components/QuickActionsBar.swift
import SwiftUI

struct QuickActionsBar: View {
    let onExport: () -> Void
    let onShare: () -> Void
    let onPrint: () -> Void
    let onSaveMap: () -> Void
    
    var body: some View {
        HStack(spacing: 12) {
            PMRActionButton(
                icon: "square.and.arrow.up.on.square",
                title: "Export",
                action: onExport
            )
            
            PMRActionButton(
                icon: "square.and.arrow.up",
                title: "Share",
                action: onShare
            )
            
            PMRActionButton(
                icon: "printer",
                title: "Print",
                action: onPrint
            )
            
            PMRActionButton(
                icon: "map",
                title: "Save Map",
                action: onSaveMap
            )
        }
    }
}

struct PMRActionButton: View {
    let icon: String
    let title: String
    let action: () -> Void
    
    @State private var isPressed = false
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.title3)
                    .symbolRenderingMode(.hierarchical)
                    .foregroundStyle(.primary)
                
                Text(title)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity, minHeight: 56)
            .background(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(Color(.secondarySystemBackground))
                    .scaleEffect(isPressed ? 0.95 : 1.0)
            )
        }
        .buttonStyle(.plain)
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
    }
}

#Preview {
    QuickActionsBar(
        onExport: { print("Export") },
        onShare: { print("Share") },
        onPrint: { print("Print") },
        onSaveMap: { print("Save Map") }
    )
    .padding()
}