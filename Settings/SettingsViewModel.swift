import Foundation
import SwiftUI
import UserNotifications

@MainActor
final class SettingsViewModel: ObservableObject {
    // Simple prefs
    @AppStorage("pmr.units") var units: String = "mi"            // "mi" | "km"
    @AppStorage("pmr.theme") var theme: String = "Topo"          // "Topo"|"Route"|"Minimal"
    @AppStorage("pmr.size")  var posterSize: String = "18x24"    // "A2"|"A3"|"18x24"
    @AppStorage("pmr.analyticsOptIn") var analyticsOptIn: Bool = false
    @AppStorage("pmr.crashOptIn")     var crashOptIn: Bool = true
    @Published var notificationsEnabled: Bool = false

    let addressStore = AddressStore()

    func requestNotifications() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound]) { granted, _ in
            Task { @MainActor in self.notificationsEnabled = granted }
        }
    }

    func clearLocalData() {
        // Delete posters_index.json and any files it references
        let fm = FileManager.default
        let docs = fm.urls(for: .documentDirectory, in: .userDomainMask).first!
        let indexURL = docs.appendingPathComponent("posters_index.json")
        if let data = try? Data(contentsOf: indexURL),
           let posters = try? JSONDecoder().decode([Poster].self, from: data) {
            posters.forEach { p in
                try? fm.removeItem(at: docs.appendingPathComponent(p.thumbnailPath))
                try? fm.removeItem(at: docs.appendingPathComponent(p.filePath))
            }
        }
        try? fm.removeItem(at: indexURL)
    }

    func exportData() {
        // Stub for V1. Future: zip Documents + prefs and present ShareLink.
        print("Export data requested")
    }
}