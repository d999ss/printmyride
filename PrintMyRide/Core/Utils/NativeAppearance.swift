import UIKit

/// Apply native iOS appearances and materials globally
func applyNativeAppearances() {
    // Use system materials and colors throughout
    UINavigationBar.appearance().scrollEdgeAppearance = {
        let appearance = UINavigationBarAppearance()
        appearance.configureWithDefaultBackground()
        appearance.backgroundEffect = UIBlurEffect(style: .systemUltraThinMaterial)
        return appearance
    }()
    
    UINavigationBar.appearance().standardAppearance = {
        let appearance = UINavigationBarAppearance()
        appearance.configureWithDefaultBackground()
        appearance.backgroundEffect = UIBlurEffect(style: .systemUltraThinMaterial)
        return appearance
    }()
    
    // Tab bar with native materials
    UITabBar.appearance().scrollEdgeAppearance = {
        let appearance = UITabBarAppearance()
        appearance.configureWithDefaultBackground()
        appearance.backgroundEffect = UIBlurEffect(style: .systemUltraThinMaterial)
        return appearance
    }()
    
    UITabBar.appearance().standardAppearance = {
        let appearance = UITabBarAppearance()
        appearance.configureWithDefaultBackground()
        appearance.backgroundEffect = UIBlurEffect(style: .systemUltraThinMaterial)
        return appearance
    }()
    
    // Use system colors for tint
    UIView.appearance().tintColor = UIColor.systemBrown
}