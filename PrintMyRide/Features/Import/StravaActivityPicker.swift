import SwiftUI

struct StravaActivityPicker: View {
    let onPick: (StravaService.StravaActivity) -> Void
    @State private var items: [StravaService.StravaActivity] = []
    
    var body: some View {
        NavigationView {
            List {
                ForEach(items, id: \.id) { activity in
                    Button {
                        onPick(activity)
                    } label: {
                        VStack(alignment: .leading) {
                            Text(activity.name).font(.headline)
                            Text("\(activity.type) • \(Int(activity.distance/1000))km")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                }
            }
            .navigationTitle("Activities")
            .task {
                // Placeholder - empty list until OAuth is configured
                items = []
            }
        }
    }
}