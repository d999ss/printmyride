import SwiftUI

struct LoginView: View {
    @StateObject private var authService = AuthService.shared
    @State private var email = ""
    @State private var showEmailSent = false
    @State private var errorMessage: String?
    
    var body: some View {
        NavigationView {
            VStack(spacing: 32) {
                // Header
                VStack(spacing: 16) {
                    Image(systemName: "point.topleft.down.curvedto.point.bottomright.up")
                        .font(.system(size: 60))
                        .foregroundColor(Color(UIColor.systemBrown))
                        .padding(.top, 80)
                    
                    VStack(spacing: 8) {
                        Text("PrintMyRide")
                            .font(.largeTitle)
                            .fontWeight(.bold)
                        
                        Text("Transform your rides into art")
                            .font(.headline)
                            .foregroundColor(.secondary)
                    }
                }
                
                if showEmailSent {
                    // Email sent state
                    VStack(spacing: 20) {
                        Image(systemName: "envelope.badge.checkmark")
                            .font(.system(size: 50))
                            .foregroundColor(.green)
                        
                        VStack(spacing: 8) {
                            Text("Check your email")
                                .font(.title2)
                                .fontWeight(.semibold)
                            
                            Text("We sent a login link to:")
                                .foregroundColor(.secondary)
                            
                            Text(email)
                                .fontWeight(.medium)
                        }
                        
                        Button("Send another link") {
                            showEmailSent = false
                        }
                        .foregroundColor(Color(UIColor.systemBrown))
                    }
                    .multilineTextAlignment(.center)
                    
                } else {
                    // Login form
                    VStack(spacing: 20) {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Email address")
                                .font(.headline)
                            
                            TextField("Enter your email", text: $email)
                                .padding(.horizontal, 16)
                                .padding(.vertical, 12)
                                .background(Color(.systemGray6))
                                .cornerRadius(12)
                                .textContentType(.emailAddress)
                                .keyboardType(.emailAddress)
                                .autocapitalization(.none)
                                .disabled(authService.isLoading)
                                .foregroundColor(.primary)
                        }
                        
                        Button(action: sendLoginEmail) {
                            HStack {
                                if authService.isLoading {
                                    ProgressView()
                                        .scaleEffect(0.8)
                                        .foregroundColor(.white)
                                }
                                
                                Text(authService.isLoading ? "Sending..." : "Send login link")
                                    .fontWeight(.semibold)
                            }
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color(UIColor.systemBrown))
                            .foregroundColor(.white)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                        }
                        .disabled(email.isEmpty || authService.isLoading || !isValidEmail(email))
                        
                        if let errorMessage = errorMessage {
                            Text(errorMessage)
                                .foregroundColor(.red)
                                .font(.caption)
                        }
                    }
                }
                
                Spacer()
                
                // Skip button for demo
                Button(action: {
                    authService.skipAuth()
                }) {
                    HStack {
                        Image(systemName: "arrow.right.circle")
                        Text("Skip to Demo")
                    }
                    .foregroundColor(.gray)
                    .padding(.vertical, 12)
                    .padding(.horizontal, 24)
                    .overlay(
                        RoundedRectangle(cornerRadius: 20)
                            .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                    )
                }
                
                // Footer
                VStack(spacing: 8) {
                    Text("No password required")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Text("We'll send you a secure login link")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            .padding(.horizontal, 32)
            .padding(.vertical, 40)
            .navigationBarHidden(true)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Color(.systemBackground))
            .ignoresSafeArea()
        }
    }
    
    private func sendLoginEmail() {
        Task {
            do {
                try await authService.startEmailAuth(email: email)
                withAnimation {
                    showEmailSent = true
                    errorMessage = nil
                }
            } catch {
                errorMessage = error.localizedDescription
            }
        }
    }
    
    private func isValidEmail(_ email: String) -> Bool {
        email.contains("@") && email.contains(".")
    }
}

#Preview {
    LoginView()
}