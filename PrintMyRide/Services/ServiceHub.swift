import Foundation
import SwiftUI

@MainActor
final class ServiceHub: ObservableObject {
    @AppStorage("pmr.mockStrava") var mockStrava: Bool = false {
        didSet { strava = mockStrava ? StravaMock(preconnected: true) : StravaReal() }
    }
    @Published var strava: StravaAPI

    init() {
        self.strava = UserDefaults.standard.bool(forKey: "pmr.mockStrava") ? StravaMock(preconnected: true) : StravaReal()
    }
}