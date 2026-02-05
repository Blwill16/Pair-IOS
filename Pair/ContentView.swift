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
    @State private var isOnboardingComplete = false
    
    var body: some View {
        if !authManager.isAuthenticated {
            AuthView()
        } else if !isOnboardingComplete && authManager.currentUser != nil && !isOnboardingCompleteForUser {
            // Show 3-step onboarding for new users
            OnboardingContainerView(isOnboardingComplete: $isOnboardingComplete)
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
    
    private var isOnboardingCompleteForUser: Bool {
        guard let userId = authManager.currentUser?.id else { return true }
        return UserDefaults.standard.bool(forKey: "profileSetupComplete_\(userId)")
    }
}

// MARK: - Sound Wave Animation
struct SoundWaveView: View {
    @State private var phase: CGFloat = 0
    
    var body: some View {
        ZStack {
            // Left wave
            WavePath(phase: phase, direction: .left)
                .stroke(Color.white.opacity(0.6), lineWidth: 2)
            
            // Right wave
            WavePath(phase: phase, direction: .right)
                .stroke(Color.white.opacity(0.6), lineWidth: 2)
            
            // Center merge point - pulsing dot
            Circle()
                .fill(Color.white)
                .frame(width: 12, height: 12)
                .shadow(color: .white.opacity(0.5), radius: 8, x: 0, y: 0)
            
            // Expanding glow ring
            Circle()
                .stroke(Color.white.opacity(0.3), lineWidth: 1)
                .frame(width: 24 + (phase * 10), height: 24 + (phase * 10))
                .opacity(Double(1.0 - (phase * 0.5)))
        }
        .onAppear {
            withAnimation(.linear(duration: 3).repeatForever(autoreverses: false)) {
                phase = 1
            }
        }
    }
}

struct WavePath: Shape {
    var phase: CGFloat
    var direction: WaveDirection
    
    enum WaveDirection {
        case left, right
    }
    
    var animatableData: CGFloat {
        get { phase }
        set { phase = newValue }
    }
    
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let midY = rect.midY
        let midX = rect.midX
        let amplitude: CGFloat = 20
        let wavelength: CGFloat = 60
        let step: CGFloat = 2
        
        if direction == .left {
            // Wave from left to center
            path.move(to: CGPoint(x: 0, y: midY))
            var x: CGFloat = 0
            while x <= midX {
                let relativeX = x / wavelength
                let y = midY + sin((relativeX + phase) * .pi * 2) * amplitude * (x / midX)
                path.addLine(to: CGPoint(x: x, y: y))
                x += step
            }
        } else {
            // Wave from right to center
            path.move(to: CGPoint(x: rect.width, y: midY))
            var x: CGFloat = rect.width
            while x >= midX {
                let relativeX = (rect.width - x) / wavelength
                let y = midY + sin((relativeX + phase) * .pi * 2) * amplitude * ((rect.width - x) / (rect.width - midX))
                path.addLine(to: CGPoint(x: x, y: y))
                x -= step
            }
        }
        
        return path
    }
}

struct AuthView: View {
    @EnvironmentObject var authManager: AuthManager
    @State private var email = ""
    @State private var otpCode = ""
    @State private var showOTPEntry = false
    @State private var errorMessage: String?
    @State private var isLoading = false
    @State private var showContent = false
    
    var body: some View {
        ZStack {
            // Solid purple background per Figma (#9b87f5)
            Color.pairPurple.ignoresSafeArea()
            
            if showOTPEntry {
                // OTP Code Entry Screen
                otpEntryView
            } else {
                // Email Entry Screen
                emailEntryView
            }
        }
        .onTapGesture {
            UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
        }
        .onAppear {
            // Staggered fade-in animation
            withAnimation(.easeOut(duration: 0.6).delay(0.2)) {
                showContent = true
            }
        }
    }
    
    private var emailEntryView: some View {
        VStack(spacing: 0) {
            Spacer()
            
            // Logo and tagline with staggered fade-in
            VStack(spacing: 16) {
                Text("Pair Music")
                    .font(.system(size: 42, weight: .semibold))
                    .foregroundColor(.white)
                    .tracking(-1.26) // -0.03em letter spacing
                
                Text("Discover music that belongs\ntogether")
                    .font(.system(size: 18))
                    .foregroundColor(.white.opacity(0.8))
                    .multilineTextAlignment(.center)
            }
            .opacity(showContent ? 1 : 0)
            .offset(y: showContent ? 0 : 20)
            
            Spacer()
            
            // Sound wave animation in center
            SoundWaveView()
                .frame(height: 60)
                .padding(.horizontal, 40)
                .opacity(showContent ? 1 : 0)
            
            Spacer()
            
            // Auth section at bottom
            VStack(spacing: 16) {
                // Email input - frosted glass style
                TextField("", text: $email, prompt: Text("your@email.com").foregroundColor(.white.opacity(0.5)))
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
                    sendOTPCode()
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
            .opacity(showContent ? 1 : 0)
            .offset(y: showContent ? 0 : 20)
            
            // Footer - Terms and Privacy (updated to Pair Music)
            Text("By continuing, you agree to Pair Music's Terms of Service\nand Privacy Policy")
                .font(.system(size: 13))
                .foregroundColor(.white.opacity(0.5))
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)
                .padding(.bottom, 48)
                .opacity(showContent ? 1 : 0)
        }
    }
    
    private var otpEntryView: some View {
        VStack(spacing: 0) {
            // Back button
            HStack {
                Button {
                    withAnimation {
                        showOTPEntry = false
                        otpCode = ""
                        errorMessage = nil
                    }
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: "arrow.left")
                            .font(.system(size: 16))
                        Text("Back")
                            .font(.system(size: 16))
                    }
                    .foregroundColor(.white.opacity(0.8))
                }
                Spacer()
            }
            .padding(.horizontal, 24)
            .padding(.top, 16)
            
            Spacer()
            
            // Title and instructions
            VStack(spacing: 16) {
                Text("Enter your code")
                    .font(.system(size: 32, weight: .bold))
                    .foregroundColor(.white)
                
                Text("We sent a 6-digit code to\n\(email)")
                    .font(.system(size: 16))
                    .foregroundColor(.white.opacity(0.7))
                    .multilineTextAlignment(.center)
            }
            .padding(.bottom, 48)
            
            // OTP Code input
            VStack(spacing: 24) {
                TextField("", text: $otpCode, prompt: Text("000000").foregroundColor(.white.opacity(0.3)))
                    .keyboardType(.numberPad)
                    .multilineTextAlignment(.center)
                    .font(.system(size: 32, weight: .semibold, design: .monospaced))
                    .foregroundColor(.white)
                    .padding(.horizontal, 20)
                    .padding(.vertical, 20)
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .fill(Color.white.opacity(0.15))
                    )
                    .onChange(of: otpCode) { newValue in
                        // Limit to 6 digits
                        if newValue.count > 6 {
                            otpCode = String(newValue.prefix(6))
                        }
                        // Auto-verify when 6 digits entered
                        if newValue.count == 6 {
                            verifyOTPCode()
                        }
                    }
                
                // Verify button
                Button {
                    verifyOTPCode()
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
                        Text("Verify")
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
                                .disabled(otpCode.count != 6 || isLoading)
                                .opacity(otpCode.count != 6 ? 0.6 : 1)
                
                if let error = errorMessage {
                    Text(error)
                        .font(.caption)
                        .foregroundColor(.red.opacity(0.9))
                }
                
                // Resend code button
                Button {
                    resendCode()
                } label: {
                    Text("Didn't receive a code? Resend")
                        .font(.system(size: 14))
                        .foregroundColor(.white.opacity(0.6))
                }
                .padding(.top, 8)
            }
            .padding(.horizontal, 32)
            
            Spacer()
            Spacer()
        }
    }
    
    private func sendOTPCode() {
        isLoading = true
        errorMessage = nil
        
        Task {
            do {
                try await authManager.sendOTP(email: email)
                await MainActor.run {
                    isLoading = false
                    withAnimation {
                        showOTPEntry = true
                    }
                }
            } catch {
                await MainActor.run {
                    isLoading = false
                    errorMessage = "Failed to send code"
                }
            }
        }
    }
    
    private func verifyOTPCode() {
        guard otpCode.count == 6 else { return }
        
        isLoading = true
        errorMessage = nil
        
        Task {
            do {
                try await authManager.verifyOTP(email: email, token: otpCode)
                // Auth manager will update isAuthenticated, which will dismiss this view
            } catch {
                await MainActor.run {
                    isLoading = false
                    errorMessage = "Invalid code. Please try again."
                    otpCode = ""
                }
            }
        }
    }
    
    private func resendCode() {
        isLoading = true
        errorMessage = nil
        
        Task {
            do {
                try await authManager.sendOTP(email: email)
                await MainActor.run {
                    isLoading = false
                    errorMessage = nil
                }
            } catch {
                await MainActor.run {
                    isLoading = false
                    errorMessage = "Failed to resend code"
                }
            }
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
