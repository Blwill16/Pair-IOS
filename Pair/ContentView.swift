import SwiftUI
import AuthenticationServices
import MusicKit

// MARK: - Main Content View
struct ContentView: View {
    @EnvironmentObject var authManager: AuthManager
    @State private var isOnboardingComplete = false
    @State private var selectedTab = 0
    
    var body: some View {
        if !authManager.isAuthenticated {
            MagicLinkLoginView()
        } else if !isOnboardingComplete && !isOnboardingCompleteForUser {
            OnboardingFlowView(isOnboardingComplete: $isOnboardingComplete)
        } else {
            MainAppView(selectedTab: $selectedTab)
        }
    }
    
    private var isOnboardingCompleteForUser: Bool {
        guard let userId = authManager.currentUser?.id else { return true }
        return UserDefaults.standard.bool(forKey: "onboardingComplete_\(userId)")
    }
}

// MARK: - Screen 1: Magic Link Login
struct MagicLinkLoginView: View {
    @EnvironmentObject var authManager: AuthManager
    @State private var email = ""
    @State private var otpCode = ""
    @State private var showOTPEntry = false
    @State private var errorMessage: String?
    @State private var isLoading = false
    @State private var showContent = false
    
    var body: some View {
        ZStack {
            Color.pairPurple.ignoresSafeArea()
            
            if showOTPEntry {
                otpEntryView
            } else {
                emailEntryView
            }
        }
        .onTapGesture {
            UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
        }
        .onAppear {
            withAnimation(.easeOut(duration: 0.6).delay(0.2)) {
                showContent = true
            }
        }
    }
    
    private var emailEntryView: some View {
        VStack(spacing: 0) {
            Spacer()
            
            VStack(spacing: 16) {
                Text("Pair Music")
                    .font(.system(size: 42, weight: .semibold))
                    .foregroundColor(.white)
                
                Text("Discover music that belongs\ntogether")
                    .font(.system(size: 18))
                    .foregroundColor(.white.opacity(0.8))
                    .multilineTextAlignment(.center)
            }
            .opacity(showContent ? 1 : 0)
            .offset(y: showContent ? 0 : 20)
            
            Spacer()
            
            PairWaveAnimation()
                .frame(height: 60)
                .padding(.horizontal, 40)
                .opacity(showContent ? 1 : 0)
            
            Spacer()
            
            VStack(spacing: 16) {
                ZStack(alignment: .leading) {
                    if email.isEmpty {
                        Text("your@email.com")
                            .foregroundColor(.white.opacity(0.5))
                            .padding(.horizontal, 20)
                    }
                    
                    TextField("", text: $email)
                        .textContentType(.emailAddress)
                        .keyboardType(.emailAddress)
                        .autocapitalization(.none)
                        .disableAutocorrection(true)
                        .foregroundColor(.white)
                        .tint(.white)
                        .padding(.horizontal, 20)
                }
                .padding(.vertical, 18)
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(Color.white.opacity(0.15))
                )
                
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
                }
            }
            .padding(.horizontal, 32)
            .padding(.bottom, 24)
            .opacity(showContent ? 1 : 0)
            
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
                        Text("Back")
                    }
                    .font(.system(size: 16))
                    .foregroundColor(.white.opacity(0.8))
                }
                Spacer()
            }
            .padding(.horizontal, 24)
            .padding(.top, 16)
            
            Spacer()
            
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
                        if newValue.count > 6 {
                            otpCode = String(newValue.prefix(6))
                        }
                        if newValue.count == 6 {
                            verifyOTPCode()
                        }
                    }
                
                Button {
                    verifyOTPCode()
                } label: {
                    if isLoading {
                        ProgressView()
                            .tint(.white)
                    } else {
                        Text("Verify")
                            .font(.system(size: 17, weight: .medium))
                            .foregroundColor(.white.opacity(0.9))
                    }
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 18)
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(Color.white.opacity(0.25))
                )
                .disabled(otpCode.count != 6 || isLoading)
                .opacity(otpCode.count != 6 ? 0.6 : 1)
                
                if let error = errorMessage {
                    Text(error)
                        .font(.caption)
                        .foregroundColor(.red.opacity(0.9))
                }
                
                Button {
                    sendOTPCode()
                } label: {
                    Text("Didn't receive a code? Resend")
                        .font(.system(size: 14))
                        .foregroundColor(.white.opacity(0.6))
                }
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
            } catch {
                await MainActor.run {
                    isLoading = false
                    errorMessage = "Invalid code. Please try again."
                    otpCode = ""
                }
            }
        }
    }
}

// MARK: - Wave Animation
struct PairWaveAnimation: View {
    @State private var amplitude: CGFloat = -40
    @State private var glowScale: CGFloat = 1.0
    @State private var glowOpacity: Double = 0.3
    
    var body: some View {
        ZStack {
            WavePath(amplitude: amplitude)
                .stroke(Color.white.opacity(0.6), lineWidth: 2)
            
            Circle()
                .fill(Color.white.opacity(glowOpacity))
                .frame(width: 40, height: 40)
                .scaleEffect(glowScale)
            
            Circle()
                .fill(Color.white.opacity(0.9))
                .frame(width: 16, height: 16)
        }
        .onAppear {
            withAnimation(.easeInOut(duration: 2.0).repeatForever(autoreverses: true)) {
                amplitude = 40
            }
            withAnimation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true)) {
                glowScale = 1.4
                glowOpacity = 0.5
            }
        }
    }
}

struct WavePath: Shape {
    var amplitude: CGFloat
    
    var animatableData: CGFloat {
        get { amplitude }
        set { amplitude = newValue }
    }
    
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let midY = rect.midY
        let midX = rect.midX
        
        path.move(to: CGPoint(x: 0, y: midY))
        path.addCurve(
            to: CGPoint(x: midX, y: midY),
            control1: CGPoint(x: rect.width * 0.25, y: midY + amplitude),
            control2: CGPoint(x: rect.width * 0.40, y: midY + amplitude * 0.3)
        )
        path.addCurve(
            to: CGPoint(x: rect.width, y: midY),
            control1: CGPoint(x: rect.width * 0.60, y: midY - amplitude * 0.3),
            control2: CGPoint(x: rect.width * 0.75, y: midY - amplitude)
        )
        
        return path
    }
}

// MARK: - Onboarding Flow (Screens 2-7)
struct OnboardingFlowView: View {
    @EnvironmentObject var authManager: AuthManager
    @Binding var isOnboardingComplete: Bool
    
    @State private var currentStep = 1
    @State private var firstName = ""
    @State private var lastName = ""
    @State private var detectedGenres: [TasteGenre] = []
    
    var body: some View {
        ZStack {
            Color.white.ignoresSafeArea()
            
            switch currentStep {
            case 1:
                NameCollectionScreen(firstName: $firstName, lastName: $lastName, onContinue: { currentStep = 2 })
                    .transition(.asymmetric(insertion: .move(edge: .trailing), removal: .move(edge: .leading)))
            case 2:
                ConnectAppleMusicScreen(onContinue: { currentStep = 3 })
                    .transition(.asymmetric(insertion: .move(edge: .trailing), removal: .move(edge: .leading)))
            case 3:
                ListeningAnalysisScreen(onComplete: { genres in
                    detectedGenres = genres
                    currentStep = 4
                })
                .transition(.asymmetric(insertion: .move(edge: .trailing), removal: .move(edge: .leading)))
            case 4:
                TasteSummaryScreen(genres: detectedGenres, onLooksRight: { currentStep = 6 }, onAdjust: { currentStep = 5 })
                    .transition(.asymmetric(insertion: .move(edge: .trailing), removal: .move(edge: .leading)))
            case 5:
                AdjustTasteScreen(genres: $detectedGenres, onContinue: { currentStep = 6 })
                    .transition(.asymmetric(insertion: .move(edge: .trailing), removal: .move(edge: .leading)))
            case 6:
                WelcomeScreen(firstName: firstName, onComplete: { completeOnboarding() })
                    .transition(.asymmetric(insertion: .move(edge: .trailing), removal: .move(edge: .leading)))
            default:
                EmptyView()
            }
        }
        .animation(.easeInOut(duration: 0.3), value: currentStep)
    }
    
    private func completeOnboarding() {
        if let userId = authManager.currentUser?.id {
            UserDefaults.standard.set(true, forKey: "onboardingComplete_\(userId)")
        }
        isOnboardingComplete = true
    }
}

// MARK: - Taste Genre Model
struct TasteGenre: Identifiable {
    let id = UUID()
    let name: String
    let descriptor: String
    var isSelected: Bool = true
}

// MARK: - Screen 2: Name Collection
struct NameCollectionScreen: View {
    @Binding var firstName: String
    @Binding var lastName: String
    let onContinue: () -> Void
    
    var body: some View {
        VStack(spacing: 0) {
            Spacer()
            
            VStack(alignment: .leading, spacing: 24) {
                Text("Welcome to Pair")
                    .font(.system(size: 32, weight: .bold))
                    .foregroundColor(.black)
                
                Text("What should we call you?")
                    .font(.system(size: 16))
                    .foregroundColor(.gray)
                
                VStack(alignment: .leading, spacing: 16) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("First name")
                            .font(.system(size: 14))
                            .foregroundColor(.gray)
                        
                        TextField("Alex", text: $firstName)
                            .font(.system(size: 16))
                            .padding(16)
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                            )
                    }
                    
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Last name")
                            .font(.system(size: 14))
                            .foregroundColor(.gray)
                        
                        TextField("Chen", text: $lastName)
                            .font(.system(size: 16))
                            .padding(16)
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                            )
                    }
                }
                
                Button(action: onContinue) {
                    HStack {
                        Text("Continue")
                            .font(.system(size: 17, weight: .semibold))
                        Image(systemName: "arrow.right")
                    }
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 18)
                    .background(
                        RoundedRectangle(cornerRadius: 28)
                            .fill(Color.pairPurple)
                    )
                }
                .disabled(firstName.isEmpty)
                .opacity(firstName.isEmpty ? 0.5 : 1)
            }
            .padding(.horizontal, 24)
            
            Spacer()
        }
    }
}

// MARK: - Screen 3: Connect Apple Music
struct ConnectAppleMusicScreen: View {
    let onContinue: () -> Void
    @State private var isConnecting = false
    
    var body: some View {
        VStack(spacing: 0) {
            Spacer()
            
            VStack(spacing: 24) {
                Text("Pair Music")
                    .font(.system(size: 32, weight: .bold))
                    .foregroundColor(.black)
                
                Text("Your personal\nweekly curator.")
                    .font(.system(size: 24))
                    .foregroundColor(.black)
                    .multilineTextAlignment(.center)
                
                Text("Connect your Apple Music library to\ndiscover new music that fits your taste.")
                    .font(.system(size: 16))
                    .foregroundColor(.gray)
                    .multilineTextAlignment(.center)
                    .padding(.top, 16)
                
                Button(action: connectAppleMusic) {
                    HStack {
                        if isConnecting {
                            ProgressView()
                                .tint(.white)
                        } else {
                            Text("Connect Apple Music")
                                .font(.system(size: 17, weight: .semibold))
                        }
                    }
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 18)
                    .background(
                        RoundedRectangle(cornerRadius: 28)
                            .fill(Color.pairPurple)
                    )
                }
                .padding(.top, 24)
                .disabled(isConnecting)
                
                Text("Spotify coming soon")
                    .font(.system(size: 14))
                    .foregroundColor(.gray.opacity(0.6))
            }
            .padding(.horizontal, 24)
            
            Spacer()
        }
    }
    
    private func connectAppleMusic() {
        isConnecting = true
        
        Task {
            #if targetEnvironment(simulator)
            // MusicKit doesn't work on simulator - skip and continue
            try? await Task.sleep(nanoseconds: 1_000_000_000)
            await MainActor.run {
                isConnecting = false
                onContinue()
            }
            #else
            do {
                let _ = await AppleMusicManager.shared.requestAuthorization()
            } catch {
                print("Apple Music authorization error: \(error)")
            }
            await MainActor.run {
                isConnecting = false
                onContinue()
            }
            #endif
        }
    }
}

// MARK: - Screen 4: Listening Analysis
struct ListeningAnalysisScreen: View {
    let onComplete: ([TasteGenre]) -> Void
    
    var body: some View {
        VStack(spacing: 0) {
            Spacer()
            
            VStack(spacing: 16) {
                Text("Listening...")
                    .font(.system(size: 32, weight: .bold))
                    .foregroundColor(.black)
                
                Text("Understanding how you listen")
                    .font(.system(size: 16))
                    .foregroundColor(.gray)
            }
            
            Spacer()
        }
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
                let genres = [
                    TasteGenre(name: "Melodic Electronic", descriptor: "Atmospheric - emotional - long-form"),
                    TasteGenre(name: "Dream Pop", descriptor: "Soft focus - textural"),
                    TasteGenre(name: "Alt R&B", descriptor: "Intimate - boundary-pushing"),
                    TasteGenre(name: "Indie Dance", descriptor: "Groove-forward - restrained")
                ]
                onComplete(genres)
            }
        }
    }
}

// MARK: - Screen 5: Taste Summary
struct TasteSummaryScreen: View {
    let genres: [TasteGenre]
    let onLooksRight: () -> Void
    let onAdjust: () -> Void
    
    var body: some View {
        VStack(spacing: 0) {
            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 24) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("This is what Pair\nhears.")
                            .font(.system(size: 32, weight: .bold))
                            .foregroundColor(.black)
                        
                        Text("Based on your library and listening patterns.")
                            .font(.system(size: 16))
                            .foregroundColor(.gray)
                    }
                    .padding(.top, 60)
                    
                    VStack(spacing: 12) {
                        ForEach(genres) { genre in
                            TasteGenreCard(genre: genre)
                        }
                    }
                }
                .padding(.horizontal, 24)
            }
            
            VStack(spacing: 12) {
                Button(action: onLooksRight) {
                    Text("Looks right")
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 18)
                        .background(
                            RoundedRectangle(cornerRadius: 28)
                                .fill(Color.black)
                        )
                }
                
                Button(action: onAdjust) {
                    Text("Adjust")
                        .font(.system(size: 17))
                        .foregroundColor(.gray)
                }
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 40)
        }
    }
}

struct TasteGenreCard: View {
    let genre: TasteGenre
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(genre.name)
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(.black)
            
            Text(genre.descriptor)
                .font(.system(size: 14))
                .foregroundColor(.gray)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color.gray.opacity(0.2), lineWidth: 1)
        )
    }
}

// MARK: - Screen 6: Adjust Taste
struct AdjustTasteScreen: View {
    @Binding var genres: [TasteGenre]
    let onContinue: () -> Void
    
    var body: some View {
        ZStack {
            Color.pairPurple.opacity(0.05).ignoresSafeArea()
            
            VStack(spacing: 0) {
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 24) {
                        VStack(spacing: 8) {
                            Text("Adjust taste")
                                .font(.system(size: 32, weight: .bold))
                                .foregroundColor(Color(red: 0.3, green: 0.2, blue: 0.5))
                            
                            Text("Remove what doesn't fit, or add\nmore genres.")
                                .font(.system(size: 16))
                                .foregroundColor(.gray)
                                .multilineTextAlignment(.center)
                        }
                        .padding(.top, 40)
                        
                        VStack(spacing: 12) {
                            ForEach($genres) { $genre in
                                AdjustableGenreCard(genre: $genre)
                            }
                        }
                        
                        Button(action: {}) {
                            Text("Add more genres")
                                .font(.system(size: 16))
                                .foregroundColor(.gray)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 20)
                                .background(
                                    RoundedRectangle(cornerRadius: 16)
                                        .stroke(style: StrokeStyle(lineWidth: 1, dash: [5]))
                                        .foregroundColor(.gray.opacity(0.3))
                                )
                        }
                    }
                    .padding(.horizontal, 24)
                }
                
                Button(action: onContinue) {
                    Text("Continue")
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 18)
                        .background(
                            RoundedRectangle(cornerRadius: 28)
                                .fill(Color.pairPurple)
                        )
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 40)
            }
        }
    }
}

struct AdjustableGenreCard: View {
    @Binding var genre: TasteGenre
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(genre.name)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.black)
                
                Text(genre.descriptor)
                    .font(.system(size: 13))
                    .foregroundColor(.gray)
            }
            
            Spacer()
            
            Button(action: { genre.isSelected = false }) {
                Text("Remove")
                    .font(.system(size: 14))
                    .foregroundColor(.gray.opacity(0.6))
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.white)
        )
        .opacity(genre.isSelected ? 1 : 0.5)
    }
}

// MARK: - Screen 7: Welcome Screen
struct WelcomeScreen: View {
    let firstName: String
    let onComplete: () -> Void
    
    var body: some View {
        VStack {
            Spacer()
            
            HStack(spacing: 0) {
                Text("Welcome to ")
                    .font(.system(size: 32, weight: .bold))
                    .foregroundColor(.black)
                Text("Pair")
                    .font(.system(size: 32, weight: .bold))
                    .foregroundColor(.pairPurple)
                Text(firstName.isEmpty ? "" : ", \(firstName)")
                    .font(.system(size: 32, weight: .bold))
                    .foregroundColor(.black)
            }
            
            Spacer()
        }
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
                onComplete()
            }
        }
    }
}

// MARK: - Main App View (Screens 9-16)
struct MainAppView: View {
    @Binding var selectedTab: Int
    @State private var showGenreDetail: GenreData?
    @State private var showNowPlaying: TrackData?
    
    var body: some View {
        ZStack(alignment: .bottom) {
            Color.white.ignoresSafeArea()
            
            TabView(selection: $selectedTab) {
                CuratedHomeScreen(
                    onGenreTap: { genre in showGenreDetail = genre },
                    onTrackTap: { track in showNowPlaying = track }
                )
                .tag(0)
                
                Text("")
                    .tag(1)
                
                ProfileScreen()
                    .tag(2)
            }
            .tabViewStyle(.page(indexDisplayMode: .never))
            
            FloatingNavBar(selectedTab: $selectedTab)
                .padding(.bottom, 20)
        }
        .sheet(item: $showGenreDetail) { genre in
            GenreDetailScreen(genre: genre, onTrackTap: { track in
                showGenreDetail = nil
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                    showNowPlaying = track
                }
            })
        }
        .sheet(item: $showNowPlaying) { track in
            NowPlayingScreen(track: track)
        }
    }
}

// MARK: - Bottom Navigation (uses FloatingNavBar from DesignSystem)

// MARK: - Data Models
struct GenreData: Identifiable {
    let id = UUID()
    let name: String
    let descriptor: String
    let editorialSummary: String
    let tracks: [TrackData]
}

struct TrackData: Identifiable {
    let id = UUID()
    let title: String
    let artist: String
    let artworkUrl: String
    var genreName: String?
    var appleMusicId: String?
    var appleMusicUrl: String?
}

// MARK: - Screen 9: Curated Genres (Home)
struct CuratedHomeScreen: View {
    let onGenreTap: (GenreData) -> Void
    let onTrackTap: (TrackData) -> Void
    
    @State private var genres: [GenreData] = []
    @State private var isLoading = true
    
    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 0) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Week of Feb 6")
                        .font(.system(size: 14))
                        .foregroundColor(.gray)
                    
                    Text("This Week")
                        .font(.system(size: 32, weight: .bold))
                        .foregroundColor(.black)
                    
                    Text("\(totalTracks) tracks across \(genres.count) genres")
                        .font(.system(size: 14))
                        .foregroundColor(.gray)
                }
                .padding(.horizontal, 24)
                .padding(.top, 24)
                .padding(.bottom, 16)
                
                Divider()
                    .padding(.horizontal, 24)
                
                if isLoading {
                    VStack {
                        Spacer().frame(height: 100)
                        WaveformLoadingView()
                        Spacer()
                    }
                    .frame(maxWidth: .infinity)
                } else {
                    LazyVStack(alignment: .leading, spacing: 32) {
                        ForEach(Array(genres.enumerated()), id: \.element.id) { index, genre in
                            GenreSectionView(genre: genre, onGenreTap: onGenreTap, onTrackTap: onTrackTap)
                                .staggeredListItem(index: index, baseDelay: 0.1)
                        }
                    }
                    .padding(.top, 24)
                }
                
                Spacer().frame(height: 100)
            }
        }
        .onAppear {
            loadGenres()
        }
    }
    
    private var totalTracks: Int {
        genres.reduce(0) { $0 + $1.tracks.count }
    }
    
    private func loadGenres() {
        isLoading = true
        
        Task {
            // Try to get recently played first, then fall back to library
            var allSongs: [MusicKit.Song] = []
            
            // Get recently played tracks (most likely to have good metadata)
            let recentlyPlayed = await AppleMusicManager.shared.getRecentlyPlayed()
            allSongs.append(contentsOf: recentlyPlayed)
            
            // Also get library songs
            let librarySongs = await AppleMusicManager.shared.getLibrarySongs(limit: 100)
            
            // Add library songs that aren't already in recently played
            let recentIds = Set(recentlyPlayed.map { $0.id.rawValue })
            for song in librarySongs {
                if !recentIds.contains(song.id.rawValue) {
                    allSongs.append(song)
                }
            }
            
            // Group songs by genre, filtering out "Other" and empty genres
            var genreGroups: [String: [MusicKit.Song]] = [:]
            
            for song in allSongs {
                // Get all genre names and use the most specific one
                let genreNames = song.genreNames
                var bestGenre: String? = nil
                
                // Prefer more specific genres over generic ones
                for name in genreNames {
                    let lowered = name.lowercased()
                    // Skip very generic genres
                    if lowered == "music" || lowered == "other" || lowered == "unknown" {
                        continue
                    }
                    bestGenre = name
                    break
                }
                
                guard let genreName = bestGenre else { continue }
                
                if genreGroups[genreName] == nil {
                    genreGroups[genreName] = []
                }
                genreGroups[genreName]?.append(song)
            }
            
            // Convert to GenreData, limiting to top genres with most tracks
            var loadedGenres: [GenreData] = []
            
            // Sort genres by track count and take top ones
            let sortedGenres = genreGroups.sorted { $0.value.count > $1.value.count }
            
            for (genreName, songsInGenre) in sortedGenres.prefix(6) {
                var tracks: [TrackData] = []
                
                // Take up to 5 tracks per genre
                for song in songsInGenre.prefix(5) {
                    let artworkUrl = song.artwork?.url(width: 400, height: 400)?.absoluteString ?? ""
                    let appleMusicUrl = song.url?.absoluteString
                    
                    tracks.append(TrackData(
                        title: song.title,
                        artist: song.artistName,
                        artworkUrl: artworkUrl,
                        genreName: genreName,
                        appleMusicId: song.id.rawValue,
                        appleMusicUrl: appleMusicUrl
                    ))
                }
                
                if !tracks.isEmpty {
                    let descriptor = getGenreDescriptor(for: genreName)
                    let summary = "Based on \(songsInGenre.count) tracks you've been listening to."
                    
                    loadedGenres.append(GenreData(
                        name: genreName,
                        descriptor: descriptor,
                        editorialSummary: summary,
                        tracks: tracks
                    ))
                }
            }
            
            await MainActor.run {
                genres = loadedGenres
                isLoading = false
            }
        }
    }
    
    private func getGenreDescriptor(for genre: String) -> String {
        let descriptors: [String: String] = [
            "Pop": "Catchy - melodic - accessible",
            "Hip-Hop/Rap": "Rhythmic - lyrical - bass-heavy",
            "R&B/Soul": "Smooth - emotional - groove-driven",
            "Rock": "Guitar-driven - energetic - raw",
            "Electronic": "Synthesized - atmospheric - danceable",
            "Alternative": "Experimental - indie - boundary-pushing",
            "Dance": "High-energy - club-ready - rhythmic",
            "Country": "Storytelling - acoustic - heartfelt",
            "Jazz": "Improvisational - sophisticated - timeless",
            "Classical": "Orchestral - composed - refined",
            "Indie": "Independent - authentic - creative",
            "Metal": "Heavy - intense - powerful",
            "Folk": "Acoustic - traditional - narrative",
            "Reggae": "Laid-back - rhythmic - island vibes",
            "Latin": "Passionate - rhythmic - vibrant",
            "Blues": "Soulful - expressive - roots-based"
        ]
        return descriptors[genre] ?? "Curated from your library"
    }
}

struct GenreSectionView: View {
    let genre: GenreData
    let onGenreTap: (GenreData) -> Void
    let onTrackTap: (TrackData) -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Button(action: { onGenreTap(genre) }) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(genre.name)
                        .font(.system(size: 20, weight: .bold))
                        .foregroundColor(.black)
                    
                    Text(genre.descriptor)
                        .font(.system(size: 14))
                        .foregroundColor(.gray)
                }
            }
            .padding(.horizontal, 24)
            
            VStack(spacing: 0) {
                ForEach(genre.tracks) { track in
                    Button(action: { onTrackTap(track) }) {
                        TrackRowView(track: track)
                    }
                }
            }
            .padding(.horizontal, 24)
        }
    }
}

struct TrackRowView: View {
    let track: TrackData
    
    var body: some View {
        HStack(spacing: 16) {
            AsyncImage(url: URL(string: track.artworkUrl)) { image in
                image
                    .resizable()
                    .aspectRatio(contentMode: .fill)
            } placeholder: {
                Rectangle()
                    .fill(Color.gray.opacity(0.2))
            }
            .frame(width: 56, height: 56)
            .cornerRadius(8)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(track.title)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.black)
                
                Text(track.artist)
                    .font(.system(size: 14))
                    .foregroundColor(.gray)
            }
            
            Spacer()
        }
        .padding(.vertical, 12)
    }
}

// MARK: - Screen 10: Genre Detail
struct GenreDetailScreen: View {
    let genre: GenreData
    let onTrackTap: (TrackData) -> Void
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 0) {
                Button(action: { dismiss() }) {
                    HStack(spacing: 8) {
                        Image(systemName: "arrow.left")
                        Text("Back")
                    }
                    .font(.system(size: 16))
                    .foregroundColor(.black)
                }
                .padding(.top, 24)
                .padding(.horizontal, 24)
                
                VStack(alignment: .leading, spacing: 8) {
                    Text(genre.name)
                        .font(.system(size: 32, weight: .bold))
                        .foregroundColor(.black)
                    
                    Text(genre.descriptor)
                        .font(.system(size: 16))
                        .foregroundColor(.black)
                }
                .padding(.top, 24)
                .padding(.horizontal, 24)
                
                Divider()
                    .padding(.vertical, 16)
                    .padding(.horizontal, 24)
                
                Text(genre.editorialSummary)
                    .font(.system(size: 16))
                    .foregroundColor(.gray)
                    .padding(.horizontal, 24)
                
                Text("This week's drop")
                    .font(.system(size: 14))
                    .foregroundColor(.gray)
                    .padding(.top, 24)
                    .padding(.horizontal, 24)
                
                VStack(spacing: 0) {
                    ForEach(genre.tracks) { track in
                        Button(action: { onTrackTap(track) }) {
                            TrackRowView(track: track)
                        }
                    }
                }
                .padding(.horizontal, 24)
                
                Text("\(genre.tracks.count) tracks - updated weekly")
                    .font(.system(size: 14))
                    .foregroundColor(.gray.opacity(0.6))
                    .padding(.top, 16)
                    .padding(.horizontal, 24)
                
                Spacer().frame(height: 40)
            }
        }
        .background(Color.white)
    }
}

// MARK: - Screen 11: Now Playing
struct NowPlayingScreen: View {
    let track: TrackData
    @Environment(\.dismiss) var dismiss
    @State private var isSaved = false
    @State private var isHolding = false
    @State private var holdProgress: CGFloat = 0
    @State private var showSaveSuccess = false
    @State private var isPlaying = false
    @State private var artworkVisible = false
    @State private var closeButtonVisible = false
    
    private let holdDuration: Double = 1.0 // 1 second
    
    var body: some View {
        ZStack {
            Color.white.ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Close button at top right with fade-in animation
                HStack {
                    Spacer()
                    Button(action: { 
                        stopPlayback()
                        dismiss() 
                    }) {
                        Image(systemName: "xmark")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(.black)
                            .padding(12)
                            .background(
                                Circle()
                                    .fill(Color.gray.opacity(0.1))
                            )
                    }
                    .buttonScaleAnimation(hoverScale: 1.05, pressScale: 0.95)
                    .opacity(closeButtonVisible ? 1 : 0)
                }
                .padding(.horizontal, 24)
                .padding(.top, 16)
                
                Spacer()
                
                // Album artwork with scale and fade animation
                AsyncImage(url: URL(string: track.artworkUrl)) { image in
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                } placeholder: {
                    Rectangle()
                        .fill(Color.gray.opacity(0.2))
                }
                .frame(width: 280, height: 280)
                .cornerRadius(16)
                .shadow(color: .black.opacity(0.2), radius: 20, y: 10)
                .scaleEffect(artworkVisible ? 1 : 0.9)
                .opacity(artworkVisible ? 1 : 0)
                .offset(y: artworkVisible ? 0 : 20)
                
                Spacer().frame(height: 40)
                
                // Track info
                VStack(spacing: 8) {
                    Text(track.title)
                        .font(.system(size: 24, weight: .bold))
                        .foregroundColor(.black)
                    
                    Text(track.artist)
                        .font(.system(size: 16))
                        .foregroundColor(.black)
                    
                    if let genre = track.genreName {
                        Text(genre)
                            .font(.system(size: 14))
                            .foregroundColor(.gray)
                    }
                }
                
                Spacer()
                
                // Action buttons: Skip | Hold-to-Save | Open in Apple Music
                HStack(spacing: 40) {
                    // Left button: Skip/Decline
                    Button(action: { dismiss() }) {
                        Image(systemName: "forward.end")
                            .font(.system(size: 22))
                            .foregroundColor(.black)
                            .frame(width: 56, height: 56)
                            .background(
                                Circle()
                                    .fill(Color.gray.opacity(0.1))
                            )
                    }
                    
                    // Center button: Hold-to-Save with progress ring
                    ZStack {
                        // Background circle
                        Circle()
                            .fill(Color.pairPurple)
                            .frame(width: 72, height: 72)
                            .scaleEffect(isHolding ? 0.95 : (showSaveSuccess ? 1.05 : 1.0))
                            .animation(.easeInOut(duration: 0.1), value: isHolding)
                            .animation(.easeInOut(duration: 0.2), value: showSaveSuccess)
                        
                        // Progress ring track (background)
                        Circle()
                            .stroke(Color.white.opacity(0.3), lineWidth: 3)
                            .frame(width: 66, height: 66)
                        
                        // Progress ring (animated)
                        Circle()
                            .trim(from: 0, to: holdProgress)
                            .stroke(Color.white, style: StrokeStyle(lineWidth: 3, lineCap: .round))
                            .frame(width: 66, height: 66)
                            .rotationEffect(.degrees(-90))
                            .animation(.linear(duration: 0.016), value: holdProgress)
                        
                        // Heart icon
                        Image(systemName: isSaved ? "heart.fill" : "heart")
                            .font(.system(size: 28))
                            .foregroundColor(.white)
                    }
                    .gesture(
                        DragGesture(minimumDistance: 0)
                            .onChanged { _ in
                                if !isHolding && !isSaved {
                                    startHold()
                                }
                            }
                            .onEnded { _ in
                                endHold()
                            }
                    )
                    
                    // Right button: Open in Apple Music
                    Button(action: openInAppleMusic) {
                        Image(systemName: "arrow.up.right")
                            .font(.system(size: 20, weight: .medium))
                            .foregroundColor(.black)
                            .frame(width: 56, height: 56)
                            .background(
                                Circle()
                                    .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                            )
                    }
                }
                
                Spacer().frame(height: 60)
            }
        }
        .onAppear {
            startPlayback()
            // Trigger entry animations
            withAnimation(.easeOut(duration: 0.5)) {
                artworkVisible = true
            }
            withAnimation(.easeOut(duration: 0.3).delay(0.2)) {
                closeButtonVisible = true
            }
        }
    }
    
    private func startHold(){
        isHolding = true
        holdProgress = 0
        
        // Animate progress over holdDuration
        let startTime = Date()
        Timer.scheduledTimer(withTimeInterval: 0.016, repeats: true) { timer in
            let elapsed = Date().timeIntervalSince(startTime)
            let progress = min(elapsed / holdDuration, 1.0)
            
            if isHolding {
                holdProgress = CGFloat(progress)
                
                if progress >= 1.0 {
                    timer.invalidate()
                    completeHold()
                }
            } else {
                timer.invalidate()
                withAnimation(.easeOut(duration: 0.2)) {
                    holdProgress = 0
                }
            }
        }
    }
    
    private func endHold() {
        if holdProgress < 1.0 {
            isHolding = false
            withAnimation(.easeOut(duration: 0.2)) {
                holdProgress = 0
            }
        }
    }
    
    private func completeHold() {
        isHolding = false
        isSaved = true
        showSaveSuccess = true
        
        // Add to Apple Music library
        if let appleMusicId = track.appleMusicId {
            Task {
                let _ = await AppleMusicManager.shared.addToLibrary(appleMusicId: appleMusicId)
            }
        }
        
        // Reset success animation after a moment
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            showSaveSuccess = false
        }
        
        // Reset progress
        withAnimation(.easeOut(duration: 0.3)) {
            holdProgress = 0
        }
    }
    
    private func openInAppleMusic() {
        // Try to open in Apple Music app
        if let appleMusicUrl = track.appleMusicUrl,
           let url = URL(string: appleMusicUrl) {
            UIApplication.shared.open(url)
        } else if let appleMusicId = track.appleMusicId {
            // Fallback: construct Apple Music URL from ID
            if let url = URL(string: "https://music.apple.com/song/\(appleMusicId)") {
                UIApplication.shared.open(url)
            }
        }
    }
    
    private func startPlayback() {
        guard let appleMusicId = track.appleMusicId else { return }
        isPlaying = true
        Task {
            await AppleMusicManager.shared.playSong(appleMusicId: appleMusicId)
        }
    }
    
    private func stopPlayback() {
        isPlaying = false
        // Stop the system music player
        Task {
            let player = SystemMusicPlayer.shared
            player.stop()
        }
    }
}

// MARK: - Screen 12: Profile
struct ProfileScreen: View {
    @State private var showTasteAdjustment = false
    
    let genres = [
        ("Melodic Electronic", "Atmospheric - emotional - long-form"),
        ("Dream Pop", "Soft focus - textural"),
        ("Alt R&B", "Intimate - boundary-pushing")
    ]
    
    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 24) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Profile")
                        .font(.system(size: 32, weight: .bold))
                        .foregroundColor(.black)
                    
                    Text("Your taste, your history")
                        .font(.system(size: 16))
                        .foregroundColor(.gray)
                }
                .padding(.top, 24)
                
                Divider()
                
                Button(action: { showTasteAdjustment = true }) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Taste")
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundColor(.black)
                        
                        Text("Gently steer Pair's decisions")
                            .font(.system(size: 14))
                            .foregroundColor(.gray)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(20)
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(Color.gray.opacity(0.2), lineWidth: 1)
                    )
                }
                
                VStack(alignment: .leading, spacing: 16) {
                    Text("CURRENT GENRES")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.gray)
                        .tracking(1)
                    
                    VStack(alignment: .leading, spacing: 0) {
                        ForEach(genres, id: \.0) { genre in
                            VStack(alignment: .leading, spacing: 4) {
                                HStack {
                                    Text(genre.0)
                                        .font(.system(size: 16, weight: .medium))
                                        .foregroundColor(.black)
                                    
                                    Circle()
                                        .fill(Color.pairPurple)
                                        .frame(width: 6, height: 6)
                                }
                                
                                Text(genre.1)
                                    .font(.system(size: 13))
                                    .foregroundColor(.gray)
                            }
                            .padding(.vertical, 12)
                        }
                        
                        Button(action: { showTasteAdjustment = true }) {
                            HStack {
                                Text("Adjust")
                                    .font(.system(size: 14))
                                    .foregroundColor(.gray)
                                Image(systemName: "arrow.right")
                                    .font(.system(size: 12))
                                    .foregroundColor(.gray)
                            }
                        }
                        .padding(.top, 8)
                    }
                    .padding(20)
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(Color.gray.opacity(0.2), lineWidth: 1)
                    )
                }
                
                Spacer().frame(height: 100)
            }
            .padding(.horizontal, 24)
        }
        .sheet(isPresented: $showTasteAdjustment) {
            TasteAdjustmentScreen()
        }
    }
}

// MARK: - Screen 14: Taste Adjustment
struct TasteAdjustmentScreen: View {
    @Environment(\.dismiss) var dismiss
    @State private var genres: [TasteGenre] = [
        TasteGenre(name: "Melodic Electronic", descriptor: "Atmospheric - emotional - long-form"),
        TasteGenre(name: "Dream Pop", descriptor: "Soft focus - textural"),
        TasteGenre(name: "Alt R&B", descriptor: "Intimate - boundary-pushing"),
        TasteGenre(name: "Indie Dance", descriptor: "Groove-forward - restrained")
    ]
    
    var body: some View {
        NavigationView {
            ZStack {
                Color.pairPurple.opacity(0.05).ignoresSafeArea()
                
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 24) {
                        VStack(spacing: 8) {
                            Text("Adjust taste")
                                .font(.system(size: 32, weight: .bold))
                                .foregroundColor(Color(red: 0.3, green: 0.2, blue: 0.5))
                            
                            Text("Remove what doesn't fit, or add\nmore genres.")
                                .font(.system(size: 16))
                                .foregroundColor(.gray)
                                .multilineTextAlignment(.center)
                        }
                        .padding(.top, 20)
                        
                        VStack(spacing: 12) {
                            ForEach($genres) { $genre in
                                AdjustableGenreCard(genre: $genre)
                            }
                        }
                        
                        Button(action: {}) {
                            Text("Add more genres")
                                .font(.system(size: 16))
                                .foregroundColor(.gray)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 20)
                                .background(
                                    RoundedRectangle(cornerRadius: 16)
                                        .stroke(style: StrokeStyle(lineWidth: 1, dash: [5]))
                                        .foregroundColor(.gray.opacity(0.3))
                                )
                        }
                        
                        Spacer().frame(height: 40)
                    }
                    .padding(.horizontal, 24)
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") { dismiss() }
                        .foregroundColor(.pairPurple)
                }
            }
        }
    }
}

// MARK: - Screen 16: Quiet Week
struct QuietWeekScreen: View {
    let onContinue: () -> Void
    
    var body: some View {
        VStack(spacing: 0) {
            Spacer()
            
            VStack(spacing: 16) {
                Text("A quiet week")
                    .font(.system(size: 32, weight: .bold))
                    .foregroundColor(.black)
                
                Text("Nothing met the bar this week.\nThat's the point - quality over quantity.")
                    .font(.system(size: 16))
                    .foregroundColor(.gray)
                    .multilineTextAlignment(.center)
            }
            
            Spacer()
            
            Button(action: onContinue) {
                Text("Continue")
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 18)
                    .background(
                        RoundedRectangle(cornerRadius: 28)
                            .fill(Color.black)
                    )
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 40)
        }
    }
}

// MARK: - Preview
struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
            .environmentObject(AuthManager.shared)
    }
}
