import SwiftUI

// MARK: - Navigation State
// Tracks whether the floating nav bar should be visible
class NavigationState: ObservableObject {
    @Published var isNavBarVisible: Bool = true
    
    func hideNavBar() {
        withAnimation(.easeOut(duration: 0.2)) {
            isNavBarVisible = false
        }
    }
    
    func showNavBar() {
        withAnimation(.easeIn(duration: 0.2)) {
            isNavBarVisible = true
        }
    }
}

struct ContentView: View {
    @EnvironmentObject var authManager: AuthManager
    @StateObject private var navigationState = NavigationState()
    @State private var selectedTab = 0
    
    var body: some View {
        if !authManager.isAuthenticated {
            AuthView()
        } else {
            ZStack(alignment: .bottom) {
                // Light background for main app
                Color.pairBackground.ignoresSafeArea()
                
                TabView(selection: $selectedTab) {
                    // Tab 0: Discover (compass icon)
                    ExploreView()
                        .tag(0)
                    
                    // Tab 1: Create (+ icon) - Search/Create flow
                    SearchView()
                        .tag(1)
                    
                    // Tab 2: Profile (person icon)
                    ProfileView(userId: authManager.userId)
                        .tag(2)
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
                .environmentObject(navigationState)
                
                // Floating nav bar - hidden on detail screens
                if navigationState.isNavBarVisible {
                    FloatingNavBar(selectedTab: $selectedTab)
                        .padding(.bottom, 20)
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                }
            }
            .ignoresSafeArea(.keyboard)
        }
    }
}

struct AuthView: View {
    @EnvironmentObject var authManager: AuthManager
    @State private var email = ""
    @State private var showMagicLinkSent = false
    @State private var errorMessage: String?
    
    var body: some View {
        ZStack {
            AnimatedGradientBackground()
            
            VStack(spacing: 0) {
                Spacer()
                
                // Logo and tagline
                VStack(spacing: 16) {
                    PairLogo(size: 80)
                        .breathingAnimation(duration: 4, scale: 1.03)
                    
                    Text("Pair")
                        .font(.system(size: 42, weight: .bold))
                        .foregroundColor(.white)
                    
                    VStack(spacing: 4) {
                        Text("Music finds you here.")
                            .font(.subheadline)
                            .foregroundColor(.pairTextSecondary)
                        Text("Start with a song, discover what's next.")
                            .font(.subheadline)
                            .foregroundColor(.pairTextSecondary)
                    }
                }
                .padding(.bottom, 48)
                
                // Login card
                VStack(spacing: 20) {
                    // Spotify button
                    Button {
                        // Spotify login would go here
                        authManager.continueAsGuest()
                    } label: {
                        HStack(spacing: 12) {
                            Image(systemName: "music.note")
                                .font(.system(size: 18))
                            Text("Continue with Spotify")
                                .font(.headline)
                        }
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color.white.opacity(0.15))
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(Color.white.opacity(0.2), lineWidth: 1)
                        )
                    }
                    
                    // Divider
                    HStack(spacing: 16) {
                        Rectangle()
                            .fill(Color.white.opacity(0.2))
                            .frame(height: 1)
                        Text("or")
                            .font(.caption)
                            .foregroundColor(.pairTextTertiary)
                        Rectangle()
                            .fill(Color.white.opacity(0.2))
                            .frame(height: 1)
                    }
                    
                    // Email input
                    TextField("Email", text: $email)
                        .textFieldStyle(GlassTextFieldStyle())
                        .textContentType(.emailAddress)
                        .keyboardType(.emailAddress)
                        .autocapitalization(.none)
                    
                    // Magic link button
                    Button {
                        Task {
                            do {
                                try await authManager.signInWithMagicLink(email: email)
                                showMagicLinkSent = true
                            } catch {
                                errorMessage = error.localizedDescription
                            }
                        }
                    } label: {
                        Text("Send Magic Link")
                            .font(.headline)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(email.isEmpty ? Color.pairPurple.opacity(0.5) : Color.pairPurple)
                            )
                    }
                    .disabled(email.isEmpty)
                    
                    // Continue as guest
                    Button {
                        authManager.continueAsGuest()
                    } label: {
                        Text("Continue as guest")
                            .font(.subheadline)
                            .foregroundColor(.pairTextSecondary)
                    }
                    .padding(.top, 8)
                }
                .padding(.horizontal, 24)
                .padding(.vertical, 32)
                .glassCard()
                .padding(.horizontal, 24)
                
                if let error = errorMessage {
                    Text(error)
                        .font(.caption)
                        .foregroundColor(.red)
                        .padding(.top, 12)
                }
                
                Spacer()
                
                // Footer
                Text("By continuing, you agree to our use of music discovery magic")
                    .font(.caption2)
                    .foregroundColor(.pairTextTertiary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
                    .padding(.bottom, 32)
            }
        }
        .alert("Check your email", isPresented: $showMagicLinkSent) {
            Button("OK", role: .cancel) {}
        } message: {
            Text("We sent a magic link to \(email)")
        }
    }
}

struct SignInWithAppleButton: UIViewRepresentable {
    @EnvironmentObject var authManager: AuthManager
    
    func makeUIView(context: Context) -> ASAuthorizationAppleIDButton {
        let button = ASAuthorizationAppleIDButton(type: .signIn, style: .black)
        button.addTarget(context.coordinator, action: #selector(Coordinator.handleSignIn), for: .touchUpInside)
        return button
    }
    
    func updateUIView(_ uiView: ASAuthorizationAppleIDButton, context: Context) {}
    
    func makeCoordinator() -> Coordinator {
        Coordinator(authManager: authManager)
    }
    
    class Coordinator: NSObject, ASAuthorizationControllerDelegate, ASAuthorizationControllerPresentationContextProviding {
        let authManager: AuthManager
        
        init(authManager: AuthManager) {
            self.authManager = authManager
        }
        
        @objc func handleSignIn() {
            let provider = ASAuthorizationAppleIDProvider()
            let request = provider.createRequest()
            request.requestedScopes = [.email, .fullName]
            
            let controller = ASAuthorizationController(authorizationRequests: [request])
            controller.delegate = self
            controller.presentationContextProvider = self
            controller.performRequests()
        }
        
        func presentationAnchor(for controller: ASAuthorizationController) -> ASPresentationAnchor {
            UIApplication.shared.connectedScenes
                .compactMap { $0 as? UIWindowScene }
                .flatMap { $0.windows }
                .first { $0.isKeyWindow } ?? UIWindow()
        }
        
        func authorizationController(controller: ASAuthorizationController, didCompleteWithAuthorization authorization: ASAuthorization) {
            if let credential = authorization.credential as? ASAuthorizationAppleIDCredential {
                Task {
                    try? await authManager.signInWithApple(credential: credential)
                }
            }
        }
        
        func authorizationController(controller: ASAuthorizationController, didCompleteWithError error: Error) {
            print("Sign in with Apple failed: \(error)")
        }
    }
}

import AuthenticationServices

#Preview {
    ContentView()
        .environmentObject(AuthManager.shared)
        .environmentObject(AudioPlayer.shared)
}
