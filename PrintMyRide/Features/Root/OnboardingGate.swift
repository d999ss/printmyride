import SwiftUI

struct OnboardingGate: View {
    @AppStorage("hasSeenOnboarding") private var hasSeenOnboarding = false
    
    var body: some View {
        Group {
            if hasSeenOnboarding { 
                RootView() 
            } else { 
                SimpleOnboardingView { 
                    hasSeenOnboarding = true 
                } 
            }
        }
    }
}