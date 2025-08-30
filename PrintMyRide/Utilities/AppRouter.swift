import SwiftUI

final class AppRouter: ObservableObject {
    // 0 = Home, 1 = Create (dashboard/editor), 2 = Gallery, 3 = Settings
    @Published var selectedTab: Int = 0
}