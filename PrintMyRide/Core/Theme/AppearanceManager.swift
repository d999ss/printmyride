import SwiftUI
import Combine
import UIKit

class AppearanceManager: ObservableObject {
    @Published var appearanceMode: AppearanceMode = .system {
        didSet {
            applyAppearance()
        }
    }
    
    private let userDefaults = UserDefaults.standard
    private let key = "appearance"
    
    enum AppearanceMode: String, CaseIterable {
        case system = "system"
        case light = "light"
        case dark = "dark"
        
        var colorScheme: ColorScheme? {
            switch self {
            case .system: return nil
            case .light: return .light
            case .dark: return .dark
            }
        }
        
        var displayName: String {
            switch self {
            case .system: return "Automatic"
            case .light: return "Light"
            case .dark: return "Dark"
            }
        }
        
        var iconName: String {
            switch self {
            case .system: return "circle.lefthalf.filled"
            case .light: return "sun.max"
            case .dark: return "moon"
            }
        }
    }
    
    init() {
        // Load from UserDefaults
        let savedValue = userDefaults.string(forKey: key) ?? "system"
        self.appearanceMode = AppearanceMode(rawValue: savedValue) ?? .system
        
        // Apply the loaded appearance immediately
        DispatchQueue.main.async {
            self.applyAppearance()
        }
        
        // Save changes to UserDefaults
        $appearanceMode
            .sink { [weak self] mode in
                self?.userDefaults.set(mode.rawValue, forKey: self?.key ?? "appearance")
            }
            .store(in: &cancellables)
    }
    
    private func applyAppearance() {
        DispatchQueue.main.async {
            guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene else { return }
            
            for window in windowScene.windows {
                switch self.appearanceMode {
                case .light:
                    window.overrideUserInterfaceStyle = .light
                case .dark:
                    window.overrideUserInterfaceStyle = .dark
                case .system:
                    window.overrideUserInterfaceStyle = .unspecified
                }
            }
        }
    }
    
    private var cancellables = Set<AnyCancellable>()
}