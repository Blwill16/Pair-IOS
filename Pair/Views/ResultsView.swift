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
        VStack(spacing: 0) {
            headerSection
            
            resultsList
            
            if authManager.isAuthenticated {
                savePlaylistButton
            }
        }
        .navigationTitle("Results")
        .navigationBarTitleDisplayMode(.inline)
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
            Divider()
            Button {
                showSavePlaylistSheet = true
            } label: {
                HStack {
                    Image(systemName: "square.and.arrow.up")
                    Text("Save & Share Playlist")
                        .fontWeight(.semibold)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(Color.purple)
                .foregroundColor(.white)
                .cornerRadius(12)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(Color(.systemBackground))
        }
    }
    
    private var headerSection: some View {
        VStack(spacing: 12) {
            HStack(spacing: 12) {
                AsyncImage(url: URL(string: pairResponse.seed.albumArtUrl ?? "")) { image in
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                } placeholder: {
                    Rectangle()
                        .fill(Color.gray.opacity(0.3))
                }
                .frame(width: 60, height: 60)
                .cornerRadius(8)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text("Based on")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Text(pairResponse.seed.trackName)
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .lineLimit(1)
                    Text(pairResponse.seed.artistName)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 2) {
                    Text(mode.displayName)
                        .font(.caption)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.purple.opacity(0.2))
                        .foregroundStyle(.purple)
                        .cornerRadius(8)
                    
                    Text("\(pairResponse.results.count) tracks")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            .padding()
            .background(Color(.systemGray6))
        }
    }
    
    private var resultsList: some View {
        List {
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
        .listStyle(.plain)
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
                    .foregroundStyle(.secondary)
                    .frame(width: 24)
                
                AsyncImage(url: URL(string: result.albumArtUrl ?? "")) { image in
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
                .frame(width: 50, height: 50)
                .cornerRadius(6)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(result.trackName)
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .lineLimit(1)
                    
                    Text(result.artistName)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                
                Spacer()
                
                HStack(spacing: 8) {
                    if let previewUrl = result.previewUrl {
                        Button {
                            hapticFeedback.impactOccurred()
                            audioPlayer.play(url: previewUrl, trackId: result.trackId)
                        } label: {
                            Image(systemName: audioPlayer.currentTrackId == result.trackId && audioPlayer.isPlaying ? "pause.circle.fill" : "play.circle.fill")
                                .font(.system(size: 32))
                                .foregroundStyle(.purple)
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
                            .foregroundStyle(.secondary)
                            .padding(8)
                    }
                }
            }
            
            if let explanation = result.explanation {
                Text(explanation)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .padding(.leading, 36)
            }
        }
        .padding(.vertical, 4)
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
