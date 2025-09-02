import SwiftUI

final class AppRouter: ObservableObject {
    // 0 = Studio (primary), 1 = Collections, 2 = Settings
    @Published var selectedTab: Int = 0 // Default to Studio
}