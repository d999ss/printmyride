// PrintMyRide/UI/PosterDetail/Components/PosterHeroView.swift
import SwiftUI

struct PosterHeroView: View {
    let image: UIImage?
    let isLoading: Bool
    let aspectRatio: CGFloat
    
    init(image: UIImage?, isLoading: Bool, aspectRatio: CGFloat = 18.0/24.0) {
        self.image = image
        self.isLoading = isLoading
        self.aspectRatio = aspectRatio
    }
    
    var body: some View {
        ZStack {
            // Background container
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(Color(.secondarySystemBackground))
                .aspectRatio(aspectRatio, contentMode: .fit)
            
            // Content
            Group {
                if let image = image {
                    Image(uiImage: image)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                        .shadow(radius: 12, y: 6)
                        .transition(.opacity.combined(with: .scale(scale: 0.95)))
                } else if isLoading {
                    LoadingIndicator()
                } else {
                    EmptyPosterPlaceholder()
                }
            }
        }
        .animation(.easeInOut(duration: 0.3), value: image != nil)
        .animation(.easeInOut(duration: 0.2), value: isLoading)
    }
}

private struct LoadingIndicator: View {
    @State private var rotationAngle: Double = 0
    
    var body: some View {
        VStack(spacing: 16) {
            Circle()
                .stroke(lineWidth: 3)
                .frame(width: 32, height: 32)
                .foregroundStyle(.tertiary)
                .overlay(
                    Circle()
                        .trim(from: 0, to: 0.25)
                        .stroke(lineWidth: 3)
                        .foregroundStyle(.primary)
                        .rotationEffect(.degrees(rotationAngle))
                )
                .onAppear {
                    withAnimation(.linear(duration: 1).repeatForever(autoreverses: false)) {
                        rotationAngle = 360
                    }
                }
            
            Text("Generating poster...")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
    }
}

private struct EmptyPosterPlaceholder: View {
    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: "photo.on.rectangle.angled")
                .font(.system(size: 48, weight: .light))
                .foregroundStyle(.tertiary)
            
            VStack(spacing: 4) {
                Text("No poster generated")
                    .font(.headline)
                    .foregroundStyle(.secondary)
                
                Text("Add route data to generate")
                    .font(.caption)
                    .foregroundStyle(.tertiary)
            }
        }
    }
}

#Preview {
    VStack(spacing: 20) {
        PosterHeroView(image: nil, isLoading: false)
            .frame(height: 300)
        
        PosterHeroView(image: nil, isLoading: true)
            .frame(height: 300)
    }
    .padding()
}