import SwiftUI

struct PosterFooterGrid: View {
    let title: String
    let date: Date?
    let distanceText: String
    let timeText: String
    let avgText: String
    let gainText: String

    var body: some View {
        GeometryReader { geo in
            // Total width inside the footer container
            let total = geo.size.width

            // Layout constants (tunable if needed)
            let cols = 4
            let spacing: CGFloat = 28      // space between columns
            let minCol: CGFloat = 60       // smallest we allow on SE
            let maxCol: CGFloat = 120      // don't let columns get too wide

            // Compute a width that fits 4 columns + 3 gaps
            let available = max(0, total - spacing * CGFloat(cols - 1))
            let colW = max(minCol, min(maxCol, available / CGFloat(cols)))

            VStack(alignment: .leading, spacing: 6) {
                Text(title)
                    .font(.headline)
                    .foregroundStyle(.black)

                if let d = date {
                    Text(dateFormatter.string(from: d))
                        .font(.caption2)
                        .foregroundStyle(.black.opacity(0.7))
                }

                HStack(spacing: spacing) {
                    Stat(value: distanceText, label: "Distance")
                        .frame(width: colW, alignment: .leading)
                    Stat(value: timeText, label: "Time")
                        .frame(width: colW, alignment: .leading)
                    Stat(value: avgText, label: "Avg Speed")
                        .frame(width: colW, alignment: .leading)
                    Stat(value: gainText, label: "Elevation")
                        .frame(width: colW, alignment: .leading)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
    
    private var dateFormatter: DateFormatter {
        let f = DateFormatter()
        f.dateStyle = .full
        return f
    }
    
    private struct Stat: View {
        let value: String
        let label: String
        var body: some View {
            VStack(spacing: 2) {
                Text(value).font(.footnote).foregroundStyle(.black)
                Text(label.uppercased()).font(.caption2).foregroundStyle(.black.opacity(0.6)).tracking(0.5)
            }
        }
    }
}