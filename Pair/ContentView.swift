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
// Tracks whether the floating nav bar should be visible
class NavigationState: ObservableObject {
    @Published var isNavBarVisible: Bool = true
    @Published var isNavBarEnabled: Bool = true // Whether nav bar should show at all (false for full-screen experiences)
    
    // Scroll tracking state
    private var lastScrollY: CGFloat = 0
    private var accumulatedDelta: CGFloat = 0
    private let scrollThreshold: CGFloat = 30 // Amount of scroll needed to trigger hide/show
    
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
    
    // Handle scroll position changes for auto-hide behavior
    // scrollY is the current scroll offset (positive = scrolled down)
    func handleScroll(scrollY: CGFloat) {
        guard isNavBarEnabled else { return }
        
        let delta = scrollY - lastScrollY
        
        // Near top of content - always show nav bar
        if scrollY < 50 {
            accumulatedDelta = 0
            if !isNavBarVisible {
                withAnimation(.easeInOut(duration: 0.3)) {
                    isNavBarVisible = true
                }
            }
            lastScrollY = scrollY
            return
        }
        
        // Accumulate scroll delta
        accumulatedDelta += delta
        
        // Scrolling down - hide nav bar
        if accumulatedDelta > scrollThreshold {
            if isNavBarVisible {
                withAnimation(.easeInOut(duration: 0.3)) {
                    isNavBarVisible = false
                }
            }
            accumulatedDelta = 0
        }
        // Scrolling up - show nav bar
        else if accumulatedDelta < -scrollThreshold {
            if !isNavBarVisible {
                withAnimation(.easeInOut(duration: 0.3)) {
                    isNavBarVisible = true
                }
            }
            accumulatedDelta = 0
        }
        
        lastScrollY = scrollY
    }
    
    // Reset scroll tracking when switching tabs
    func resetScrollState() {
        lastScrollY = 0
        accumulatedDelta = 0
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
    @State private var selectedTab = 1
    
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
    @State private var isLoading = false
    
    var body: some View {
        ZStack {
            // Solid purple background per Figma
            Color.pairPurple.ignoresSafeArea()
            
            VStack(spacing: 0) {
                Spacer()
                
                // Logo and tagline
                VStack(spacing: 16) {
                    Text("Pair")
                        .font(.system(size: 42, weight: .bold))
                        .foregroundColor(.white)
                    
                    Text("Discover music that belongs\ntogether")
                        .font(.system(size: 18))
                        .foregroundColor(.white.opacity(0.8))
                        .multilineTextAlignment(.center)
                }
                .padding(.bottom, 80)
                
                Spacer()
                
                // Auth section at bottom
                VStack(spacing: 16) {
                    // Email input - frosted glass style
                    TextField("", text: $email, prompt: Text("brendanpjwilliams@icloud.com").foregroundColor(.white.opacity(0.5)))
                        .textContentType(.emailAddress)
                        .keyboardType(.emailAddress)
                        .autocapitalization(.none)
                        .foregroundColor(.white)
                        .padding(.horizontal, 20)
                        .padding(.vertical, 18)
                        .background(
                            RoundedRectangle(cornerRadius: 16)
                                .fill(Color.white.opacity(0.15))
                        )
                    
                    // Send magic link button
                    Button {
                        sendMagicLink()
                    } label: {
                        if isLoading {
                            ProgressView()
                                .tint(.white)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 18)
                                .background(
                                    RoundedRectangle(cornerRadius: 16)
                                        .fill(Color.white.opacity(0.25))
                                )
                        } else {
                            Text("Send magic link")
                                .font(.system(size: 17, weight: .medium))
                                .foregroundColor(.white.opacity(0.9))
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 18)
                                .background(
                                    RoundedRectangle(cornerRadius: 16)
                                        .fill(Color.white.opacity(0.25))
                                )
                        }
                    }
                    .disabled(email.isEmpty || isLoading)
                    .opacity(email.isEmpty ? 0.6 : 1)
                    
                    if let error = errorMessage {
                        Text(error)
                            .font(.caption)
                            .foregroundColor(.red.opacity(0.9))
                            .padding(.top, 4)
                    }
                }
                .padding(.horizontal, 32)
                .padding(.bottom, 24)
                
                // Footer - Terms and Privacy
                Text("By continuing, you agree to Pair's Terms of Service\nand Privacy Policy")
                    .font(.system(size: 13))
                    .foregroundColor(.white.opacity(0.5))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
                    .padding(.bottom, 48)
            }
            
            // Custom modal overlay for "Check your email"
            if showMagicLinkSent {
                Color.black.opacity(0.4)
                    .ignoresSafeArea()
                    .onTapGesture {
                        showMagicLinkSent = false
                    }
                
                MagicLinkSentModal(email: email, isPresented: $showMagicLinkSent)
                    .transition(.scale.combined(with: .opacity))
            }
        }
        .animation(.easeInOut(duration: 0.25), value: showMagicLinkSent)
        .onTapGesture {
            UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
        }
    }
    
    private func sendMagicLink() {
        isLoading = true
        errorMessage = nil
        
        Task {
            do {
                try await authManager.signInWithMagicLink(email: email)
                await MainActor.run {
                    isLoading = false
                    showMagicLinkSent = true
                }
            } catch {
                await MainActor.run {
                    isLoading = false
                    errorMessage = "Sign in failed"
                }
            }
        }
    }
}

// MARK: - Magic Link Sent Modal
struct MagicLinkSentModal: View {
    let email: String
    @Binding var isPresented: Bool
    
    var body: some View {
        VStack(spacing: 24) {
            VStack(spacing: 16) {
                Text("Check your email")
                    .font(.system(size: 24, weight: .bold))
                    .foregroundColor(Color(hex: "1a1230"))
                
                VStack(spacing: 4) {
                    Text("We sent a magic link to")
                        .font(.system(size: 16))
                        .foregroundColor(Color(hex: "1a1230").opacity(0.6))
                    
                    Text(email)
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(Color(hex: "1a1230"))
                }
            }
            .padding(.top, 8)
            
            Button {
                isPresented = false
            } label: {
                Text("OK")
                    .font(.system(size: 17, weight: .medium))
                    .foregroundColor(Color(hex: "1a1230"))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(
                        RoundedRectangle(cornerRadius: 14)
                            .fill(Color(hex: "f0f0f5"))
                    )
            }
        }
        .padding(24)
        .background(
            RoundedRectangle(cornerRadius: 24)
                .fill(Color.white)
        )
        .padding(.horizontal, 40)
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
