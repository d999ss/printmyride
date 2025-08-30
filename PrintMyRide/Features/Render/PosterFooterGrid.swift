import SwiftUI

struct PosterFooterGrid: View {
    let style: PosterStyle
    let title: String
    let date: Date?
    let distanceText: String
    let timeText: String
    let avgText: String
    let gainText: String

    var body: some View {
        GeometryReader { geo in
            let isNarrow = geo.size.width < 320   // SE / tight cases
            let avgLabel = isNarrow ? "AVG SPD" : "AVG SPEED"
            let elevLabel = isNarrow ? "ELEV" : "ELEVATION"

            VStack(alignment: .leading, spacing: 6) {
                // Title + date
                Text(title)
                    .font(.headline)
                    .foregroundStyle(.black)
                    .lineLimit(1)
                    .minimumScaleFactor(0.9)

                if let d = date {
                    Text(dateFormatter.string(from: d))
                        .font(.caption2)
                        .foregroundStyle(.black.opacity(0.7))
                        .lineLimit(1)
                        .minimumScaleFactor(0.9)
                }

                // 4 responsive columns
                HStack(spacing: 24) {
                    Stat(value: distanceText, label: "DISTANCE")
                    Stat(value: timeText,     label: "TIME")
                    Stat(value: avgText,      label: avgLabel)
                    Stat(value: gainText,     label: elevLabel)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            // use style padding
            .padding(.horizontal, style.footer?.paddingH ?? 26)
            .padding(.vertical, style.footer?.paddingV ?? 12)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
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
                Text(value)
                    .font(.footnote)
                    .foregroundStyle(.black)
                    .lineLimit(1)
                    .minimumScaleFactor(0.9)

                Text(label)
                    .font(.caption2)
                    .foregroundStyle(.black.opacity(0.6))
                    .tracking(0.5)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
            }
            // equal flexible column
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
}