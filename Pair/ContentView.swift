import SwiftUI

// MARK: - Scroll Offset Tracking
struct ScrollOffsetPreferenceKey: PreferenceKey {
    static var defaultValue: CGFloat = 0
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = nextValue()
    }
}

struct ViewHeightPreferenceKey: PreferenceKey {
    static var defaultValue: CGFloat = 0
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = nextValue()
    }
}

struct ContentHeightPreferenceKey: PreferenceKey {
    static var defaultValue: CGFloat = 0
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = nextValue()
    }
}

// MARK: - Navigation State
// Tracks whether the floating nav bar should be visible with smart auto-hide on scroll
class NavigationState: ObservableObject {
    @Published var isNavBarVisible: Bool = true
    @Published var isNavBarEnabled: Bool = true // Whether nav bar should show at all (false for full-screen experiences)
    
    private var lastScrollOffset: CGFloat = 0
    private let scrollThreshold: CGFloat = 5 // Minimum scroll distance before triggering
    
    // Manually hide nav bar (for full-screen experiences like create pairing, results, settings)
    func hideNavBar() {
        withAnimation(.easeInOut(duration: 0.3)) {
            isNavBarEnabled = false
            isNavBarVisible = false
        }
    }
    
    // Manually show nav bar (when returning from full-screen experiences)
    func showNavBar() {
        withAnimation(.easeInOut(duration: 0.3)) {
            isNavBarEnabled = true
            isNavBarVisible = true
        }
    }
    
    // Handle scroll-based auto-hide (for scrollable screens like Discover, Profile)
    func handleScroll(offset: CGFloat, contentHeight: CGFloat, viewHeight: CGFloat) {
        guard isNavBarEnabled else { return }
        
        let delta = offset - lastScrollOffset
        
        // Always show nav bar near top or bottom
        if offset < 50 {
            if !isNavBarVisible {
                withAnimation(.easeInOut(duration: 0.3)) {
                    isNavBarVisible = true
                }
            }
            lastScrollOffset = offset
            return
        }
        
        // Near bottom - always show
        let maxScroll = contentHeight - viewHeight
        if offset >= maxScroll - 50 {
            if !isNavBarVisible {
                withAnimation(.easeInOut(duration: 0.3)) {
                    isNavBarVisible = true
                }
            }
            lastScrollOffset = offset
            return
        }
        
        // Check scroll direction with threshold
        if delta > scrollThreshold {
            // Scrolling down - hide nav
            if isNavBarVisible {
                withAnimation(.easeInOut(duration: 0.3)) {
                    isNavBarVisible = false
                }
            }
        } else if delta < -scrollThreshold {
            // Scrolling up - show nav
            if !isNavBarVisible {
                withAnimation(.easeInOut(duration: 0.3)) {
                    isNavBarVisible = true
                }
            }
        }
        
        lastScrollOffset = offset
    }
    
    // Reset scroll tracking (call when switching tabs)
    func resetScrollTracking() {
        lastScrollOffset = 0
        if isNavBarEnabled && !isNavBarVisible {
            withAnimation(.easeInOut(duration: 0.3)) {
                isNavBarVisible = true
            }
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
                
                // Floating nav bar with smart auto-hide
                // Uses translateY animation per Figma spec
                FloatingNavBar(selectedTab: $selectedTab)
                    .padding(.bottom, 20)
                    .offset(y: navigationState.isNavBarVisible ? 0 : 100)
                    .opacity(navigationState.isNavBarVisible ? 1 : 0)
                    .animation(.easeInOut(duration: 0.3), value: navigationState.isNavBarVisible)
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
    @State private var isEmailFocused = false
    @State private var appearAnimation = false
    
    var body: some View {
        ZStack {
            AnimatedGradientBackground()
            
            VStack(spacing: 0) {
                Spacer()
                
                // Logo and tagline with entrance animation
                VStack(spacing: 20) {
                    // Logo with glow effect
                    PairLogo(size: 80)
                        .logoGlow()
                    
                    // Brand name
                    Text("Pair")
                        .font(.system(size: 48, weight: .bold))
                        .foregroundColor(.white)
                    
                    // Tagline - per Figma: "Discover music that belongs together"
                    Text("Discover music that belongs together")
                        .font(.body)
                        .foregroundColor(.white.opacity(0.7))
                }
                .opacity(appearAnimation ? 1 : 0)
                .offset(y: appearAnimation ? 0 : 20)
                .animation(.easeOut(duration: 0.6), value: appearAnimation)
                .padding(.bottom, 60)
                
                // Auth section
                VStack(spacing: 24) {
                    // Spotify button - Primary action per Figma
                    Button {
                        // Spotify login would go here
                        authManager.continueAsGuest()
                    } label: {
                        HStack(spacing: 10) {
                            Image(systemName: "music.note")
                                .font(.system(size: 20))
                            Text("Continue with Spotify")
                                .font(.body)
                                .fontWeight(.medium)
                        }
                        .foregroundColor(Color(hex: "1a1230")) // Dark text for contrast per Figma
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(
                            Capsule()
                                .fill(Color.pairPurple)
                        )
                        .shadow(color: Color.pairPurple.opacity(0.25), radius: 24, x: 0, y: 6)
                    }
                    .scaleEffect(appearAnimation ? 1 : 0.95)
                    .opacity(appearAnimation ? 1 : 0)
                    .animation(.easeOut(duration: 0.6).delay(0.2), value: appearAnimation)
                    
                    // Divider with "or continue with email"
                    HStack(spacing: 16) {
                        Rectangle()
                            .fill(Color.white.opacity(0.15))
                            .frame(height: 1)
                        Text("or continue with email")
                            .font(.caption)
                            .foregroundColor(.white.opacity(0.5))
                        Rectangle()
                            .fill(Color.white.opacity(0.15))
                            .frame(height: 1)
                    }
                    .opacity(appearAnimation ? 1 : 0)
                    .animation(.easeOut(duration: 0.6).delay(0.3), value: appearAnimation)
                    
                    // Email input with focus state
                    VStack(spacing: 16) {
                        TextField("", text: $email, prompt: Text("your@email.com").foregroundColor(.white.opacity(0.4)))
                            .textContentType(.emailAddress)
                            .keyboardType(.emailAddress)
                            .autocapitalization(.none)
                            .foregroundColor(.white)
                            .padding(.horizontal, 20)
                            .padding(.vertical, 16)
                            .background(
                                RoundedRectangle(cornerRadius: 16)
                                    .fill(Color.white.opacity(0.08))
                            )
                            .overlay(
                                RoundedRectangle(cornerRadius: 16)
                                    .stroke(
                                        isEmailFocused ? Color.pairPurple.opacity(0.5) : Color.white.opacity(0.15),
                                        lineWidth: isEmailFocused ? 2 : 1
                                    )
                            )
                            .shadow(
                                color: isEmailFocused ? Color.pairPurple.opacity(0.12) : Color.clear,
                                radius: 16, x: 0, y: 4
                            )
                            .onTapGesture {
                                isEmailFocused = true
                            }
                        
                        // Magic link button - Secondary style per Figma
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
                            Text("Send magic link")
                                .font(.body)
                                .fontWeight(.medium)
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 16)
                                .background(
                                    Capsule()
                                        .fill(Color.white.opacity(0.1))
                                )
                                .overlay(
                                    Capsule()
                                        .stroke(Color.white.opacity(0.2), lineWidth: 1)
                                )
                        }
                        .disabled(email.isEmpty)
                        .opacity(email.isEmpty ? 0.5 : 1)
                    }
                    .opacity(appearAnimation ? 1 : 0)
                    .animation(.easeOut(duration: 0.6).delay(0.4), value: appearAnimation)
                    
                    // Continue as guest - subtle link
                    Button {
                        authManager.continueAsGuest()
                    } label: {
                        Text("Continue as guest")
                            .font(.subheadline)
                            .foregroundColor(.white.opacity(0.5))
                    }
                    .padding(.top, 8)
                    .opacity(appearAnimation ? 1 : 0)
                    .animation(.easeOut(duration: 0.6).delay(0.5), value: appearAnimation)
                }
                .padding(.horizontal, 24)
                
                if let error = errorMessage {
                    Text(error)
                        .font(.caption)
                        .foregroundColor(.red)
                        .padding(.top, 12)
                }
                
                Spacer()
                
                // Footer
                Text("By continuing, you agree to our Terms and Privacy Policy")
                    .font(.caption2)
                    .foregroundColor(.white.opacity(0.35))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
                    .padding(.bottom, 32)
            }
        }
        .onAppear {
            appearAnimation = true
        }
        .onTapGesture {
            isEmailFocused = false
            UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
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
