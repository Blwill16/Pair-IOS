import SwiftUI

struct PromptView: View {
    let seedTrack: SpotifyTrack
    
    @EnvironmentObject var authManager: AuthManager
    @EnvironmentObject var audioPlayer: AudioPlayer
    
    @State private var promptText = ""
    @State private var selectedMode: PairingMode = .sameSound
    @State private var isGenerating = false
    @State private var pairResponse: PairResponse?
    @State private var showResults = false
    @State private var errorMessage: String?
    
    private let apiService = APIService.shared
    
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                seedTrackCard
                
                promptSection
                
                modeSelector
                
                generateButton
                
                if let error = errorMessage {
                    Text(error)
                        .font(.caption)
                        .foregroundStyle(.red)
                        .padding()
                }
            }
            .padding()
        }
        .navigationTitle("Create Pairing")
        .navigationBarTitleDisplayMode(.inline)
        .navigationDestination(isPresented: $showResults) {
            if let response = pairResponse {
                ResultsView(
                    pairResponse: response,
                    promptText: promptText,
                    mode: selectedMode
                )
            }
        }
    }
    
    private var seedTrackCard: some View {
        VStack(spacing: 16) {
            Text("Seed Track")
                .font(.headline)
                .frame(maxWidth: .infinity, alignment: .leading)
            
            HStack(spacing: 16) {
                AsyncImage(url: URL(string: seedTrack.albumArtUrl ?? "")) { image in
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                } placeholder: {
                    Rectangle()
                        .fill(Color.gray.opacity(0.3))
                        .overlay {
                            Image(systemName: "music.note")
                                .foregroundStyle(.gray)
                        }
                }
                .frame(width: 80, height: 80)
                .cornerRadius(8)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(seedTrack.trackName)
                        .font(.headline)
                        .lineLimit(2)
                    
                    Text(seedTrack.artistName)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                
                Spacer()
                
                if let previewUrl = seedTrack.previewUrl {
                    Button {
                        audioPlayer.play(url: previewUrl, trackId: seedTrack.trackId)
                    } label: {
                        Image(systemName: audioPlayer.currentTrackId == seedTrack.trackId && audioPlayer.isPlaying ? "pause.circle.fill" : "play.circle.fill")
                            .font(.system(size: 44))
                            .foregroundStyle(.purple)
                    }
                }
            }
            .padding()
            .background(Color(.systemGray6))
            .cornerRadius(12)
        }
    }
    
    private var promptSection: some View {
        VStack(spacing: 12) {
            Text("Describe the vibe (optional)")
                .font(.headline)
                .frame(maxWidth: .infinity, alignment: .leading)
            
            TextField("e.g., late night drive, summer beach party, rainy day melancholy...", text: $promptText, axis: .vertical)
                .textFieldStyle(.roundedBorder)
                .lineLimit(3...6)
            
            Text("Add keywords to help find tracks that match a specific mood or scene")
                .font(.caption)
                .foregroundStyle(.secondary)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
    
    private var modeSelector: some View {
        VStack(spacing: 12) {
            Text("Pairing Mode")
                .font(.headline)
                .frame(maxWidth: .infinity, alignment: .leading)
            
            VStack(spacing: 8) {
                ForEach(PairingMode.allCases, id: \.self) { mode in
                    Button {
                        selectedMode = mode
                    } label: {
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(mode.displayName)
                                    .font(.subheadline)
                                    .fontWeight(.medium)
                                
                                Text(mode.description)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                            
                            Spacer()
                            
                            if selectedMode == mode {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundStyle(.purple)
                            }
                        }
                        .padding()
                        .background(selectedMode == mode ? Color.purple.opacity(0.1) : Color(.systemGray6))
                        .cornerRadius(12)
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(selectedMode == mode ? Color.purple : Color.clear, lineWidth: 2)
                        )
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }
    
    private var generateButton: some View {
        Button {
            generatePairing()
        } label: {
            HStack {
                if isGenerating {
                    ProgressView()
                        .tint(.white)
                } else {
                    Image(systemName: "waveform")
                    Text("Generate Pairing")
                }
            }
            .frame(maxWidth: .infinity)
            .padding()
            .background(Color.purple)
            .foregroundColor(.white)
            .cornerRadius(12)
        }
        .disabled(isGenerating)
        .padding(.top)
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
