import SwiftUI

struct AuthWrapperView: View {
    @StateObject private var authService = AuthService.shared
    
    var body: some View {
        Group {
            if authService.isAuthenticated {
                // Show main app
                RootView()
                    .transition(.opacity)
            } else {
                // Show login
                LoginView()
                    .transition(.opacity)
            }
        }
        .animation(.easeInOut, value: authService.isAuthenticated)
        .task {
            await authService.checkAuthStatus()
        }
    }
}

#Preview {
    AuthWrapperView()
}