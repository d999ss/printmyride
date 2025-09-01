import SwiftUI
import CoreLocation

struct PosterCardView: View {
    let title: String
    let thumbPath: String
    let coords: [CLLocationCoordinate2D]
    var locked: Bool = false
    var onShare: (() -> Void)?
    var onFavorite: (() -> Void)?
    var isFavorite: Bool = false
    var matchedID: String? = nil
    var ns: Namespace.ID? = nil

    var body: some View {
        // Card container with subtle glass stroke
        VStack(alignment: .leading, spacing: 8) {
            ZStack(alignment: .topTrailing) {
                // Guaranteed thumbnail: load real path or generate (snapshot -> route)
                PosterThumbProvider(
                    thumbPath: thumbPath,
                    posterTitle: title,
                    coords: coords,
                    thumbSize: CGSize(width: 600, height: 840)
                )
                .frame(maxWidth: .infinity)
                .frame(height: 200)
                .clipShape(RoundedRectangle(cornerRadius: DesignTokens.CornerRadius.card, style: .continuous))
                .modifier(MatchedIfAvailable(id: matchedID, ns: ns))

                if locked {
                    Label("Pro", systemImage: "crown.fill")
                        .font(.caption).fontWeight(.semibold)
                        .padding(.horizontal, 8).padding(.vertical, 6)
                        .background(.ultraThinMaterial, in: Capsule())
                        .padding(10)
                }
                
                HStack(spacing: 8) {
                    Button { onShare?() } label: {
                        Image(systemName: "square.and.arrow.up").imageScale(.medium)
                            .padding(8)
                            .background(.ultraThinMaterial, in: Circle())
                    }
                    .buttonStyle(PlainButtonStyle())
                    
                    Button { onFavorite?() } label: {
                        Image(systemName: isFavorite ? "heart.fill" : "heart")
                            .imageScale(.medium)
                            .foregroundStyle(isFavorite ? .red : .primary)
                            .padding(8)
                            .background(.ultraThinMaterial, in: Circle())
                    }
                    .buttonStyle(PlainButtonStyle())
                }
                .padding(8)
            }

            Text(title)
                .font(.subheadline).fontWeight(.semibold)
                .lineLimit(1)

            let s = StatsExtractor.compute(coords: coords, elevations: nil, timestamps: nil)
            HStack(spacing: 8) {
                MetricPill(icon: "map", text: s.distanceKm > 0 ? String(format: "%.1f km", s.distanceKm) : "Demo")
                if let duration = s.durationSec, duration > 0 {
                    let h = Int(duration/3600), m = Int((duration.truncatingRemainder(dividingBy: 3600))/60)
                    MetricPill(icon: "clock", text: h > 0 ? "\(h)h \(m)m" : "\(m)m")
                }
                Spacer()
            }
        }
        .padding(10) // breathing room so the stroke isn't tight to content
        .background(
            // subtle glass backdrop so the stroke reads on dark
            RoundedRectangle(cornerRadius: DesignTokens.CornerRadius.card, style: .continuous)
                .fill(Color.white.opacity(0.02))
        )
        .overlay(
            // faint stroke around the whole tile
            RoundedRectangle(cornerRadius: DesignTokens.CornerRadius.card, style: .continuous)
                .strokeBorder(Color.white.opacity(0.08), lineWidth: 1)
        )
    }
}

// Helper modifier for matched geometry
struct MatchedIfAvailable: ViewModifier {
    let id: String?
    let ns: Namespace.ID?
    
    func body(content: Content) -> some View {
        if let id = id, let ns = ns {
            content.matchedGeometryEffect(id: id, in: ns)
        } else {
            content
        }
    }
}