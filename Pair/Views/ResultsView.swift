import SwiftUI

struct ResultsView: View {
    let pairResponse: PairResponse
    let promptText: String
    let mode: PairingMode
    
    @EnvironmentObject var authManager: AuthManager
    @EnvironmentObject var audioPlayer: AudioPlayer
    @Environment(\.dismiss) private var dismiss
    
    @State private var savedTrackIds: Set<String> = []
    @State private var showSavePlaylistSheet = false
    @State private var playlistTitle = ""
    @State private var isSavingPlaylist = false
    @State private var showPlaylistSaved = false
    @State private var errorMessage: String?
    
    private let apiService = APIService.shared
    
    var body: some View {
        ZStack {
            Color.pairBackground.ignoresSafeArea()
            
            VStack(spacing: 0) {
                headerSection
                
                resultsList
                
                if authManager.isAuthenticated {
                    savePlaylistButton
                }
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
        .sheet(isPresented: $showSavePlaylistSheet) {
            savePlaylistSheet
        }
        .alert("Playlist Saved", isPresented: $showPlaylistSaved) {
            Button("OK", role: .cancel) {}
        } message: {
            Text("Your playlist has been saved and published!")
        }
    }
    
    private var savePlaylistButton: some View {
        VStack(spacing: 0) {
            Button {
                showSavePlaylistSheet = true
            } label: {
                HStack(spacing: 10) {
                    Image(systemName: "square.and.arrow.up")
                        .font(.system(size: 16))
                    Text("Save & Share Playlist")
                        .fontWeight(.semibold)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(Color.pairPurple)
                .foregroundColor(.white)
                .cornerRadius(14)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 16)
            .background(
                Color.pairBackground
                    .shadow(color: Color.black.opacity(0.3), radius: 20, y: -10)
            )
        }
    }
    
    private var headerSection: some View {
        VStack(spacing: 12) {
            HStack(spacing: 14) {
                AsyncImage(url: URL(string: pairResponse.seed.albumArtUrl ?? "")) { image in
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                } placeholder: {
                    Rectangle()
                        .fill(Color.white.opacity(0.1))
                }
                .frame(width: 64, height: 64)
                .cornerRadius(10)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("Fresh pairings for")
                        .font(.caption)
                        .foregroundColor(.pairTextSecondary)
                    Text(pairResponse.seed.trackName)
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(.white)
                        .lineLimit(1)
                    Text(pairResponse.seed.artistName)
                        .font(.caption)
                        .foregroundColor(.pairTextSecondary)
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 4) {
                    Text(mode.displayName)
                        .font(.caption)
                        .fontWeight(.medium)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 5)
                        .background(Color.pairPurple.opacity(0.2))
                        .foregroundColor(.pairPurple)
                        .cornerRadius(8)
                    
                    Text("\(pairResponse.results.count) tracks")
                        .font(.caption)
                        .foregroundColor(.pairTextTertiary)
                }
            }
            .padding(16)
            .background(Color.white.opacity(0.05))
            .cornerRadius(16)
            .padding(.horizontal, 16)
            .padding(.top, 60)
        }
    }
    
    private var resultsList: some View {
        ScrollView {
            LazyVStack(spacing: 0) {
                ForEach(Array(pairResponse.results.enumerated()), id: \.element.id) { index, result in
                    ResultRowView(
                        result: result,
                        rank: index + 1,
                        isSaved: savedTrackIds.contains(result.trackId),
                        onSave: { saveTrack(result) },
                        onOpenSpotify: { openInSpotify(result.spotifyUrl) }
                    )
                }
            }
            .padding(.top, 8)
        }
    }
    
    private var savePlaylistSheet: some View {
        NavigationStack {
            VStack(spacing: 24) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Playlist Title")
                        .font(.headline)
                    
                    TextField("Enter a title", text: $playlistTitle)
                        .textFieldStyle(.roundedBorder)
                }
                
                VStack(alignment: .leading, spacing: 8) {
                    Text("Details")
                        .font(.headline)
                    
                    VStack(alignment: .leading, spacing: 4) {
                        HStack {
                            Text("Seed:")
                                .foregroundStyle(.secondary)
                            Text(pairResponse.seed.trackName)
                        }
                        .font(.subheadline)
                        
                        HStack {
                            Text("Mode:")
                                .foregroundStyle(.secondary)
                            Text(mode.displayName)
                        }
                        .font(.subheadline)
                        
                        if !promptText.isEmpty {
                            HStack(alignment: .top) {
                                Text("Prompt:")
                                    .foregroundStyle(.secondary)
                                Text(promptText)
                            }
                            .font(.subheadline)
                        }
                        
                        HStack {
                            Text("Tracks:")
                                .foregroundStyle(.secondary)
                            Text("\(pairResponse.results.count)")
                        }
                        .font(.subheadline)
                    }
                    .padding()
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color(.systemGray6))
                    .cornerRadius(12)
                }
                
                if let error = errorMessage {
                    Text(error)
                        .font(.caption)
                        .foregroundStyle(.red)
                }
                
                Spacer()
            }
            .padding()
            .navigationTitle("Save Playlist")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        showSavePlaylistSheet = false
                    }
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    Button {
                        savePlaylist()
                    } label: {
                        if isSavingPlaylist {
                            ProgressView()
                        } else {
                            Text("Save")
                        }
                    }
                    .disabled(isSavingPlaylist)
                }
            }
        }
        .presentationDetents([.medium])
    }
    
    private func saveTrack(_ result: PairingResult) {
        guard let userId = authManager.userId else { return }
        
        Task {
            do {
                try await apiService.saveTrack(userId: userId, track: result)
                await MainActor.run {
                    savedTrackIds.insert(result.trackId)
                }
            } catch {
                print("Failed to save track: \(error)")
            }
        }
    }
    
    private func savePlaylist() {
        guard let userId = authManager.userId else { return }
        
        isSavingPlaylist = true
        errorMessage = nil
        
        Task {
            do {
                let playlist = try await apiService.createPlaylist(
                    userId: userId,
                    title: playlistTitle.isEmpty ? nil : playlistTitle,
                    promptText: promptText.isEmpty ? nil : promptText,
                    seedTrackId: pairResponse.seed.trackId,
                    seedTrackName: pairResponse.seed.trackName,
                    seedArtistName: pairResponse.seed.artistName,
                    mode: mode.rawValue,
                    results: pairResponse.results
                )
                
                try await apiService.publishPlaylist(id: playlist.id, userId: userId)
                
                await MainActor.run {
                    isSavingPlaylist = false
                    showSavePlaylistSheet = false
                    showPlaylistSaved = true
                }
            } catch {
                await MainActor.run {
                    errorMessage = error.localizedDescription
                    isSavingPlaylist = false
                }
            }
        }
    }
    
    private func openInSpotify(_ urlString: String) {
        guard let url = URL(string: urlString) else { return }
        UIApplication.shared.open(url)
    }
}

struct ResultRowView: View {
    let result: PairingResult
    let rank: Int
    let isSaved: Bool
    let onSave: () -> Void
    let onOpenSpotify: () -> Void
    
    @EnvironmentObject var audioPlayer: AudioPlayer
    private let hapticFeedback = UIImpactFeedbackGenerator(style: .light)
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 12) {
                Text("\(rank)")
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(.pairTextTertiary)
                    .frame(width: 24)
                
                AsyncImage(url: URL(string: result.albumArtUrl ?? "")) { image in
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
                .frame(width: 52, height: 52)
                .cornerRadius(8)
                
                VStack(alignment: .leading, spacing: 3) {
                    Text(result.trackName)
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(.white)
                        .lineLimit(1)
                    
                    Text(result.artistName)
                        .font(.caption)
                        .foregroundColor(.pairTextSecondary)
                }
                
                Spacer()
                
                HStack(spacing: 8) {
                    if let previewUrl = result.previewUrl {
                        Button {
                            hapticFeedback.impactOccurred()
                            audioPlayer.play(url: previewUrl, trackId: result.trackId)
                        } label: {
                            Image(systemName: audioPlayer.currentTrackId == result.trackId && audioPlayer.isPlaying ? "pause.circle.fill" : "play.circle.fill")
                                .font(.system(size: 36))
                                .foregroundColor(.pairPurple)
                        }
                        .buttonStyle(.plain)
                    }
                    
                    Menu {
                        Button {
                            onSave()
                        } label: {
                            Label(isSaved ? "Saved" : "Save Track", systemImage: isSaved ? "heart.fill" : "heart")
                        }
                        
                        Button {
                            onOpenSpotify()
                        } label: {
                            Label("Open in Spotify", systemImage: "arrow.up.right")
                        }
                    } label: {
                        Image(systemName: "ellipsis")
                            .foregroundColor(.pairTextSecondary)
                            .padding(8)
                    }
                }
            }
            
            if let explanation = result.explanation {
                Text(explanation)
                    .font(.caption)
                    .foregroundColor(.pairTextTertiary)
                    .padding(.leading, 36)
                    .italic()
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
    }
}

#Preview {
    NavigationStack {
        ResultsView(
            pairResponse: PairResponse(
                seed: SpotifyTrack(
                    trackId: "seed",
                    trackName: "Seed Song",
                    artistName: "Seed Artist",
                    albumArtUrl: nil,
                    previewUrl: nil,
                    spotifyUrl: "https://spotify.com"
                ),
                results: [
                    PairingResult(
                        trackId: "1",
                        trackName: "Result 1",
                        artistName: "Artist 1",
                        albumArtUrl: nil,
                        previewUrl: nil,
                        spotifyUrl: "https://spotify.com",
                        score: 0.85,
                        explanation: "Similar tempo and energy"
                    )
                ]
            ),
            promptText: "late night vibes",
            mode: .sameVibe
        )
    }
    .environmentObject(AuthManager.shared)
    .environmentObject(AudioPlayer.shared)
}
