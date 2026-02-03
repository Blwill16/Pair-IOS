import SwiftUI

struct PromptView: View {
    let seedTrack: SpotifyTrack
    var initialPrompt: String? = nil
    var initialMode: PairingMode? = nil
    
    @EnvironmentObject var authManager: AuthManager
    @EnvironmentObject var audioPlayer: AudioPlayer
    @Environment(\.dismiss) private var dismiss
    
    @State private var promptText = ""
    @State private var selectedMode: PairingMode = .sameSound
    @State private var isGenerating = false
    @State private var pairResponse: PairResponse?
    @State private var showResults = false
    @State private var errorMessage: String?
    @State private var animateButton = false
    @State private var isVibeReady = false
    
    private let apiService = APIService.shared
    private let hapticFeedback = UIImpactFeedbackGenerator(style: .medium)
    
    var body: some View {
        ZStack {
            Color.pairBackground.ignoresSafeArea()
            
            ScrollView {
                VStack(spacing: 28) {
                    seedTrackCard
                    
                    promptSection
                    
                    modeSelector
                    
                    generateButton
                    
                    if let error = errorMessage {
                        Text(error)
                            .font(.caption)
                            .foregroundColor(.red)
                            .padding()
                    }
                }
                .padding()
                .padding(.top, 12)
            }
        }
        .navigationTitle("")
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden(true)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                PairBackButton()
            }
        }
        .navigationDestination(isPresented: $showResults) {
            if let response = pairResponse {
                ResultsView(
                    pairResponse: response,
                    promptText: promptText,
                    mode: selectedMode
                )
                .transition(.asymmetric(
                    insertion: .move(edge: .trailing).combined(with: .opacity),
                    removal: .move(edge: .leading).combined(with: .opacity)
                ))
            }
        }
        .onAppear {
            if let prompt = initialPrompt {
                promptText = prompt
            }
            if let mode = initialMode {
                selectedMode = mode
            }
        }
        .onChange(of: promptText) { _, newValue in
            withAnimation(.easeInOut(duration: 0.3)) {
                isVibeReady = !newValue.isEmpty
            }
        }
    }
    
    private var seedTrackCard: some View {
        VStack(spacing: 16) {
            HStack(spacing: 16) {
                AsyncImage(url: URL(string: seedTrack.albumArtUrl ?? "")) { image in
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                } placeholder: {
                    Rectangle()
                        .fill(Color.white.opacity(0.1))
                        .overlay {
                            Image(systemName: "music.note")
                                .foregroundColor(.pairTextTertiary)
                        }
                }
                .frame(width: 100, height: 100)
                .cornerRadius(12)
                .shadow(color: Color.pairPurple.opacity(isVibeReady ? 0.4 : 0), radius: 20)
                .scaleEffect(isVibeReady ? 1.02 : 1.0)
                .animation(.easeInOut(duration: 2.5).repeatForever(autoreverses: true), value: isVibeReady)
                
                VStack(alignment: .leading, spacing: 6) {
                    Text(seedTrack.trackName)
                        .font(.headline)
                        .foregroundColor(.white)
                        .lineLimit(2)
                    
                    Text(seedTrack.artistName)
                        .font(.subheadline)
                        .foregroundColor(.pairTextSecondary)
                }
                
                Spacer()
                
                if let previewUrl = seedTrack.previewUrl {
                    Button {
                        hapticFeedback.impactOccurred()
                        audioPlayer.play(url: previewUrl, trackId: seedTrack.trackId)
                    } label: {
                        Image(systemName: audioPlayer.currentTrackId == seedTrack.trackId && audioPlayer.isPlaying ? "pause.circle.fill" : "play.circle.fill")
                            .font(.system(size: 48))
                            .foregroundColor(.pairPurple)
                    }
                }
            }
            .padding(20)
            .background(Color.white.opacity(0.05))
            .cornerRadius(16)
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(Color.white.opacity(0.1), lineWidth: 1)
            )
        }
    }
    
    private var promptSection: some View {
        VStack(spacing: 16) {
            // Poetic prompt
            Text("What does this song feel like?")
                .font(.subheadline)
                .italic()
                .foregroundColor(.pairTextSecondary)
                .frame(maxWidth: .infinity, alignment: .center)
            
            TextField("", text: $promptText, prompt: Text("late night drive, summer memories...")
                .foregroundColor(.pairTextTertiary), axis: .vertical)
                .foregroundColor(.white)
                .multilineTextAlignment(.center)
                .lineLimit(2...4)
                .padding(.horizontal, 20)
                .padding(.vertical, 16)
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(Color.white.opacity(0.05))
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(isVibeReady ? Color.pairPurple.opacity(0.5) : Color.white.opacity(0.1), lineWidth: 1)
                )
        }
    }
    
    private var modeSelector: some View {
        VStack(spacing: 16) {
            Text("Pairing approach")
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundColor(.pairTextSecondary)
                .frame(maxWidth: .infinity, alignment: .leading)
            
            VStack(spacing: 10) {
                ForEach(PairingMode.allCases, id: \.self) { mode in
                    Button {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                            selectedMode = mode
                        }
                        hapticFeedback.impactOccurred()
                    } label: {
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(mode.displayName)
                                    .font(.subheadline)
                                    .fontWeight(.medium)
                                    .foregroundColor(.white)
                                
                                Text(modeSubtitle(mode))
                                    .font(.caption)
                                    .foregroundColor(.pairTextSecondary)
                            }
                            
                            Spacer()
                            
                            if selectedMode == mode {
                                Circle()
                                    .fill(Color.pairPurple)
                                    .frame(width: 8, height: 8)
                            }
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 14)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(selectedMode == mode ? Color.pairPurple.opacity(0.15) : Color.white.opacity(0.05))
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(selectedMode == mode ? Color.pairPurple.opacity(0.5) : Color.white.opacity(0.1), lineWidth: 1)
                        )
                        .shadow(color: selectedMode == mode ? Color.pairPurple.opacity(0.2) : Color.clear, radius: 8)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }
    
    private func modeSubtitle(_ mode: PairingMode) -> String {
        switch mode {
        case .sameSound: return "sonically close"
        case .sameVibe: return "emotionally aligned"
        case .sameScene: return "same place, different song"
        case .adventure: return "surprise me"
        }
    }
    
    private var generateButton: some View {
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
            HStack(spacing: 12) {
                if isGenerating {
                    ProgressView()
                        .tint(.white)
                } else {
                    Image(systemName: "waveform")
                        .font(.system(size: 18))
                    Text("Generate Pairing")
                        .fontWeight(.semibold)
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 18)
            .background(
                RoundedRectangle(cornerRadius: 14)
                    .fill(Color.pairPurple)
                    .shadow(color: Color.pairPurple.opacity(isVibeReady ? 0.5 : 0.3), radius: isVibeReady ? 16 : 8)
            )
            .foregroundColor(.white)
            .scaleEffect(animateButton ? 0.97 : 1.0)
        }
        .disabled(isGenerating)
        .padding(.top, 8)
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

#Preview {
    NavigationStack {
        PromptView(seedTrack: SpotifyTrack(
            trackId: "test",
            trackName: "Test Song",
            artistName: "Test Artist",
            albumArtUrl: nil,
            previewUrl: nil,
            spotifyUrl: "https://spotify.com"
        ))
    }
    .environmentObject(AuthManager.shared)
    .environmentObject(AudioPlayer.shared)
}
