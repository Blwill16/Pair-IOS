import SwiftUI
import MusicKit

// MARK: - New Onboarding Container
struct NewOnboardingContainerView: View {
    @EnvironmentObject var authManager: AuthManager
    @Binding var isOnboardingComplete: Bool
    
    @State private var currentStep = 1
    @State private var firstName = ""
    @State private var lastName = ""
    @State private var detectedGenres: [DetectedGenre] = []
    
    var body: some View {
        ZStack {
            Color.white.ignoresSafeArea()
            
            switch currentStep {
            case 1:
                NameCollectionView(
                    firstName: $firstName,
                    lastName: $lastName,
                    onContinue: { currentStep = 2 }
                )
                .transition(.asymmetric(insertion: .move(edge: .trailing), removal: .move(edge: .leading)))
            case 2:
                ConnectAppleMusicView(onContinue: { currentStep = 3 })
                    .transition(.asymmetric(insertion: .move(edge: .trailing), removal: .move(edge: .leading)))
            case 3:
                ListeningAnalysisView(onComplete: { genres in
                    detectedGenres = genres
                    currentStep = 4
                })
                .transition(.asymmetric(insertion: .move(edge: .trailing), removal: .move(edge: .leading)))
            case 4:
                TasteSummaryView(
                    genres: detectedGenres,
                    onLooksRight: { currentStep = 6 },
                    onAdjust: { currentStep = 5 }
                )
                .transition(.asymmetric(insertion: .move(edge: .trailing), removal: .move(edge: .leading)))
            case 5:
                AdjustTasteView(
                    genres: $detectedGenres,
                    onContinue: { currentStep = 6 }
                )
                .transition(.asymmetric(insertion: .move(edge: .trailing), removal: .move(edge: .leading)))
            case 6:
                WelcomeScreenView(firstName: firstName, onComplete: {
                    isOnboardingComplete = true
                })
                .transition(.asymmetric(insertion: .move(edge: .trailing), removal: .move(edge: .leading)))
            default:
                EmptyView()
            }
        }
        .animation(.easeInOut(duration: 0.3), value: currentStep)
    }
}

// MARK: - Detected Genre Model
struct DetectedGenre: Identifiable {
    let id = UUID()
    let name: String
    let descriptor: String
    var isSelected: Bool = true
}

// MARK: - Screen 2: Name Collection
struct NameCollectionView: View {
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
            
            // Progress dots
            HStack(spacing: 8) {
                Circle()
                    .fill(Color.pairPurple.opacity(0.3))
                    .frame(width: 8, height: 8)
                Circle()
                    .fill(Color.pairPurple.opacity(0.3))
                    .frame(width: 8, height: 8)
            }
            .padding(.bottom, 40)
        }
    }
}

// MARK: - Screen 3: Connect Apple Music
struct ConnectAppleMusicView: View {
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
            let _ = await AppleMusicManager.shared.requestAuthorization()
            await MainActor.run {
                isConnecting = false
                onContinue()
            }
        }
    }
}

// MARK: - Screen 4: Listening Analysis
struct ListeningAnalysisView: View {
    let onComplete: ([DetectedGenre]) -> Void
    @State private var progress: CGFloat = 0
    
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
            analyzeListeningHistory()
        }
    }
    
    private func analyzeListeningHistory() {
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
            let genres = [
                DetectedGenre(name: "Melodic Electronic", descriptor: "Atmospheric - emotional - long-form"),
                DetectedGenre(name: "Dream Pop", descriptor: "Soft focus - textural"),
                DetectedGenre(name: "Alt R&B", descriptor: "Intimate - boundary-pushing"),
                DetectedGenre(name: "Indie Dance", descriptor: "Groove-forward - restrained")
            ]
            onComplete(genres)
        }
    }
}

// MARK: - Screen 5: Taste Summary
struct TasteSummaryView: View {
    let genres: [DetectedGenre]
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
                            GenreCard(genre: genre)
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

struct GenreCard: View {
    let genre: DetectedGenre
    
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
struct AdjustTasteView: View {
    @Binding var genres: [DetectedGenre]
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
    @Binding var genre: DetectedGenre
    
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
struct WelcomeScreenView: View {
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
                Text(", \(firstName)")
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

// MARK: - Preview
struct NewOnboardingFlow_Previews: PreviewProvider {
    static var previews: some View {
        NewOnboardingContainerView(isOnboardingComplete: .constant(false))
    }
}
