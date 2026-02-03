import SwiftUI

// MARK: - Mood Color Helper
// Maps songs to mood colors based on their characteristics
struct MoodColorHelper {
    // Mood colors from Figma design
    static let warmPink = Color(hex: "e67e9f")      // Warm nostalgic (Midnight City)
    static let coolBlue = Color(hex: "6ba3c9")      // Cool ethereal (Holocene)
    static let moodyPurple = Color(hex: "8b7fc9")   // Moody (Intro)
    static let darkTeal = Color(hex: "5d9b8f")      // Dark teal (Teardrop)
    
    // Get mood color based on track name/artist
    static func getMoodColor(for track: SpotifyTrack) -> Color {
        return getMoodColor(for: track.trackName, artist: track.artistName)
    }
    
    // Get mood color based on string name/artist (for mock data)
    static func getMoodColor(for name: String, artist: String) -> Color {
        let nameLower = name.lowercased()
        let artistLower = artist.lowercased()
        
        // Map specific songs to their mood colors
        if nameLower.contains("midnight") || artistLower.contains("m83") {
            return warmPink
        } else if nameLower.contains("holocene") || nameLower.contains("skinny") || artistLower.contains("bon iver") {
            return coolBlue
        } else if nameLower.contains("intro") || artistLower.contains("xx") {
            return moodyPurple
        } else if nameLower.contains("teardrop") || nameLower.contains("breathe") || artistLower.contains("massive attack") || artistLower.contains("telepop") {
            return darkTeal
        } else if nameLower.contains("nightcall") || artistLower.contains("kavinsky") {
            return warmPink
        }
        
        // Default: use a hash of the track name to pick a consistent color
        let hash = abs(name.hashValue)
        let colors = [warmPink, coolBlue, moodyPurple, darkTeal]
        return colors[hash % colors.count]
    }
}

struct PromptView: View {
    let seedTrack: SpotifyTrack
    var initialPrompt: String? = nil
    var initialMode: PairingMode? = nil
    
    @EnvironmentObject var authManager: AuthManager
    @EnvironmentObject var audioPlayer: AudioPlayer
    @EnvironmentObject var navigationState: NavigationState
    @Environment(\.dismiss) private var dismiss
    
    @State private var promptText = ""
    @State private var selectedMode: PairingMode = .sameSound
    @State private var isGenerating = false
    @State private var pairResponse: PairResponse?
    @State private var showResults = false
    @State private var errorMessage: String?
    @State private var animateButton = false
    @State private var artworkGlowIntensity: CGFloat = 0.15
    
    private let apiService = APIService.shared
    private let hapticFeedback = UIImpactFeedbackGenerator(style: .medium)
    
    // Computed mood color based on the seed track
    private var moodColor: Color {
        MoodColorHelper.getMoodColor(for: seedTrack)
    }
    
    var body: some View {
        ZStack {
            Color.pairBackground.ignoresSafeArea()
            
            ScrollView {
                VStack(spacing: 0) {
                    // Header
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Create a Pairing")
                            .font(.system(size: 32, weight: .bold))
                            .foregroundColor(.pairTextPrimary)
                        
                        Text("Find music that resonates")
                            .font(.body)
                            .foregroundColor(.pairTextSecondary)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, 24)
                    .padding(.top, 20)
                    .padding(.bottom, 24)
                    
                    // Album art - large and centered with breathing glow
                    AsyncImage(url: URL(string: seedTrack.albumArtUrl ?? "")) { image in
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                    } placeholder: {
                        Rectangle()
                            .fill(Color.pairBackgroundSecondary)
                            .overlay {
                                Image(systemName: "music.note")
                                    .font(.system(size: 48))
                                    .foregroundColor(.pairTextTertiary)
                            }
                    }
                    .frame(width: 200, height: 200)
                    .cornerRadius(16)
                    .shadow(color: moodColor.opacity(artworkGlowIntensity), radius: 24, x: 0, y: 12)
                    .shadow(color: moodColor.opacity(artworkGlowIntensity * 0.5), radius: 40, x: 0, y: 20)
                    .padding(.bottom, 20)
                    .onChange(of: promptText) { _, newValue in
                        // Trigger breathing animation when vibe input is filled
                        if !newValue.isEmpty {
                            withAnimation(.easeInOut(duration: 3).repeatForever(autoreverses: true)) {
                                artworkGlowIntensity = 0.25
                            }
                        } else {
                            withAnimation(.easeOut(duration: 0.3)) {
                                artworkGlowIntensity = 0.15
                            }
                        }
                    }
                    
                    // Song title and artist - centered
                    VStack(spacing: 4) {
                        Text(seedTrack.trackName)
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(.pairTextPrimary)
                            .multilineTextAlignment(.center)
                        
                        Text(seedTrack.artistName)
                            .font(.body)
                            .foregroundColor(.pairTextSecondary)
                    }
                    .padding(.bottom, 32)
                    
                    // "What does this song feel like?" label
                    Text("What does this song feel like?")
                        .font(.subheadline)
                        .italic()
                        .foregroundColor(.pairTextSecondary)
                        .padding(.bottom, 12)
                    
                    // Text field
                    TextField("", text: $promptText, prompt: Text("Late night drive")
                        .foregroundColor(.pairTextTertiary))
                        .font(.body)
                        .foregroundColor(.pairTextPrimary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 20)
                        .padding(.vertical, 18)
                        .background(
                            RoundedRectangle(cornerRadius: 16)
                                .fill(Color.pairBackgroundSecondary)
                        )
                        .padding(.horizontal, 24)
                        .padding(.bottom, 32)
                    
                    // "Pairing approach" label - centered
                    Text("Pairing approach")
                        .font(.subheadline)
                        .foregroundColor(.pairTextSecondary)
                        .padding(.bottom, 16)
                    
                    // 2x2 Grid of mode cards
                    LazyVGrid(columns: [
                        GridItem(.flexible(), spacing: 12),
                        GridItem(.flexible(), spacing: 12)
                    ], spacing: 12) {
                        ForEach(PairingMode.allCases, id: \.self) { mode in
                            ModeCard(
                                mode: mode,
                                isSelected: selectedMode == mode,
                                moodColor: moodColor,
                                action: {
                                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                        selectedMode = mode
                                    }
                                    hapticFeedback.impactOccurred()
                                }
                            )
                        }
                    }
                    .padding(.horizontal, 24)
                    .padding(.bottom, 40)
                    
                    // Generate button - uses mood color
                    Button {
                        hapticFeedback.impactOccurred()
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                            animateButton = true
                        }
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
                            animateButton = false
                        }
                        generatePairing()
                    } label: {
                        HStack(spacing: 8) {
                            if isGenerating {
                                ProgressView()
                                    .tint(.white)
                            } else {
                                Text("Generate Pairing")
                                    .fontWeight(.semibold)
                                Image(systemName: "chevron.right")
                                    .font(.system(size: 14, weight: .semibold))
                            }
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 18)
                        .background(
                            RoundedRectangle(cornerRadius: 28)
                                .fill(moodColor)
                        )
                        .foregroundColor(.white)
                        .scaleEffect(animateButton ? 0.97 : 1.0)
                    }
                    .disabled(isGenerating)
                    .padding(.horizontal, 24)
                    .padding(.bottom, 40)
                    
                    if let error = errorMessage {
                        Text(error)
                            .font(.caption)
                            .foregroundColor(.red)
                            .padding()
                    }
                }
            }
        }
        .navigationTitle("")
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden(false)
        .navigationDestination(isPresented: $showResults) {
            if let response = pairResponse {
                ResultsView(
                    pairResponse: response,
                    promptText: promptText,
                    mode: selectedMode
                )
            }
        }
        .onAppear {
            // Hide nav bar on detail screens
            navigationState.hideNavBar()
            
            if let prompt = initialPrompt {
                promptText = prompt
            }
            if let mode = initialMode {
                selectedMode = mode
            }
        }
    }
    
    private func generatePairing() {
        isGenerating = true
        errorMessage = nil
        
        Task {
            do {
                let response = try await apiService.generatePairing(
                    seedTrackId: seedTrack.trackId,
                    prompt: promptText.isEmpty ? nil : promptText,
                    mode: selectedMode,
                    userId: authManager.userId
                )
                
                await MainActor.run {
                    pairResponse = response
                    isGenerating = false
                    showResults = true
                }
            } catch {
                await MainActor.run {
                    errorMessage = error.localizedDescription
                    isGenerating = false
                }
            }
        }
    }
}

// MARK: - Mode Card (2x2 Grid Item)
struct ModeCard: View {
    let mode: PairingMode
    let isSelected: Bool
    let moodColor: Color
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 4) {
                Text(mode.displayName)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(isSelected ? .white : .pairTextPrimary)
                
                Text(modeSubtitle)
                    .font(.caption)
                    .foregroundColor(isSelected ? .white.opacity(0.8) : .pairTextSecondary)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 20)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(isSelected ? moodColor : Color.clear)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(isSelected ? Color.clear : Color.pairCardBorder, lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }
    
    private var modeSubtitle: String {
        switch mode {
        case .sameSound: return "sonically close"
        case .sameVibe: return "emotionally aligned"
        case .sameScene: return "same place, different song"
        case .adventure: return "surprise me"
        }
    }
}

#Preview {
    NavigationStack {
        PromptView(seedTrack: SpotifyTrack(
            trackId: "test",
            trackName: "Midnight City",
            artistName: "M83",
            albumArtUrl: "https://images.unsplash.com/photo-1493225457124-a3eb161ffa5f?w=200",
            previewUrl: nil,
            spotifyUrl: "https://spotify.com"
        ))
    }
    .environmentObject(AuthManager.shared)
    .environmentObject(AudioPlayer.shared)
}
