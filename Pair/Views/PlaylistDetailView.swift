import SwiftUI

struct PlaylistDetailView: View {
    let playlistId: String
    
    @EnvironmentObject var authManager: AuthManager
    @EnvironmentObject var audioPlayer: AudioPlayer
    @EnvironmentObject var remixManager: RemixManager
    @Environment(\.dismiss) private var dismiss
    
    @State private var playlist: Playlist?
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var isLiked = false
    @State private var likeCount = 0
    @State private var showRemixSheet = false
    
    private let apiService = APIService.shared
    
    var body: some View {
        Group {
            if isLoading && playlist == nil {
                loadingView
            } else if let playlist = playlist {
                playlistContent(playlist)
            } else {
                errorView
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Menu {
                    if authManager.isAuthenticated {
                        Button {
                            toggleLike()
                        } label: {
                            Label(isLiked ? "Unlike" : "Like", systemImage: isLiked ? "heart.fill" : "heart")
                        }
                        
                        Button {
                            showRemixSheet = true
                        } label: {
                            Label("Remix Prompt", systemImage: "arrow.triangle.2.circlepath")
                        }
                    }
                    
                    if let playlist = playlist {
                        Button {
                            sharePlaylist(playlist)
                        } label: {
                            Label("Share", systemImage: "square.and.arrow.up")
                        }
                    }
                } label: {
                    Image(systemName: "ellipsis.circle")
                }
            }
        }
        .task {
            await loadPlaylist()
        }
        .sheet(isPresented: $showRemixSheet) {
            if let playlist = playlist {
                RemixPromptSheet(playlist: playlist) {
                    remixManager.setRemix(from: playlist)
                }
            }
        }
    }
    
    private var loadingView: some View {
        VStack {
            Spacer()
            ProgressView()
            Spacer()
        }
    }
    
    private var errorView: some View {
        VStack(spacing: 24) {
            Spacer()
            
            Image(systemName: "exclamationmark.triangle")
                .font(.system(size: 64))
                .foregroundStyle(.secondary)
            
            VStack(spacing: 8) {
                Text("Playlist not found")
                    .font(.title2)
                    .fontWeight(.semibold)
                
                if let error = errorMessage {
                    Text(error)
                        .font(.caption)
                        .foregroundStyle(.red)
                }
            }
            
            Spacer()
        }
    }
    
    private func playlistContent(_ playlist: Playlist) -> some View {
        ScrollView {
            VStack(spacing: 0) {
                headerSection(playlist)
                
                tracksList(playlist)
            }
        }
    }
    
    private func headerSection(_ playlist: Playlist) -> some View {
        VStack(spacing: 16) {
            VStack(spacing: 8) {
                Text(playlist.title)
                    .font(.title2)
                    .fontWeight(.bold)
                    .multilineTextAlignment(.center)
                
                if let profile = playlist.profiles {
                    HStack(spacing: 8) {
                        AsyncImage(url: URL(string: profile.avatarUrl ?? "")) { image in
                            image
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                        } placeholder: {
                            Circle()
                                .fill(Color.gray.opacity(0.3))
                        }
                        .frame(width: 24, height: 24)
                        .clipShape(Circle())
                        
                        Text("by \(profile.displayName ?? profile.username ?? "Unknown")")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                }
            }
            
            if let seedTrackName = playlist.seedTrackName {
                HStack(spacing: 8) {
                    Image(systemName: "music.note")
                        .foregroundStyle(.purple)
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Seed: \(seedTrackName)")
                            .font(.caption)
                        if let artistName = playlist.seedArtistName {
                            Text(artistName)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                    
                    Spacer()
                    
                    if let mode = playlist.mode {
                        Text(formatMode(mode))
                            .font(.caption)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Color.purple.opacity(0.2))
                            .foregroundStyle(.purple)
                            .cornerRadius(8)
                    }
                }
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(12)
            }
            
            if let promptText = playlist.promptText, !promptText.isEmpty {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Prompt")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Text("\"\(promptText)\"")
                        .font(.subheadline)
                        .italic()
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(12)
            }
            
            HStack(spacing: 24) {
                Button {
                    toggleLike()
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: isLiked ? "heart.fill" : "heart")
                            .foregroundStyle(isLiked ? .red : .secondary)
                        Text("\(likeCount)")
                            .foregroundStyle(.secondary)
                    }
                }
                .disabled(!authManager.isAuthenticated)
                
                HStack(spacing: 4) {
                    Image(systemName: "music.note.list")
                        .foregroundStyle(.secondary)
                    Text("\(playlist.tracks?.count ?? 0) tracks")
                        .foregroundStyle(.secondary)
                }
            }
            .font(.subheadline)
            
            Button {
                showRemixSheet = true
            } label: {
                HStack {
                    Image(systemName: "arrow.triangle.2.circlepath")
                    Text("Remix")
                }
                .fontWeight(.medium)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .background(Color.purple.opacity(0.15))
                .foregroundStyle(.purple)
                .cornerRadius(10)
            }
        }
        .padding()
    }
    
    private func tracksList(_ playlist: Playlist) -> some View {
        LazyVStack(spacing: 0) {
            if let tracks = playlist.tracks {
                ForEach(Array(tracks.enumerated()), id: \.element.id) { index, track in
                    PlaylistTrackRow(track: track, rank: index + 1)
                    
                    if index < tracks.count - 1 {
                        Divider()
                            .padding(.leading, 60)
                    }
                }
            }
        }
        .padding(.horizontal)
    }
    
    private func loadPlaylist() async {
        isLoading = true
        errorMessage = nil
        
        do {
            let fetchedPlaylist = try await apiService.getPlaylist(id: playlistId)
            await MainActor.run {
                playlist = fetchedPlaylist
                likeCount = fetchedPlaylist.likeCount ?? 0
                isLiked = fetchedPlaylist.viewerHasLiked ?? false
                isLoading = false
            }
        } catch {
            await MainActor.run {
                errorMessage = error.localizedDescription
                isLoading = false
            }
        }
    }
    
    private func toggleLike() {
        guard let userId = authManager.userId else { return }
        
        let action = isLiked ? "unlike" : "like"
        
        Task {
            do {
                try await apiService.likePlaylist(
                    userId: userId,
                    playlistId: playlistId,
                    action: action
                )
                await MainActor.run {
                    isLiked.toggle()
                    likeCount += isLiked ? 1 : -1
                }
            } catch {
                print("Failed to \(action) playlist: \(error)")
            }
        }
    }
    
    private func sharePlaylist(_ playlist: Playlist) {
        let text = "Check out this playlist: \(playlist.title)"
        let activityVC = UIActivityViewController(activityItems: [text], applicationActivities: nil)
        
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let rootVC = windowScene.windows.first?.rootViewController {
            rootVC.present(activityVC, animated: true)
        }
    }
    
    private func formatMode(_ mode: String) -> String {
        switch mode {
        case "same_sound": return "Same Sound"
        case "same_vibe": return "Same Vibe"
        case "same_scene": return "Same Scene"
        case "adventure": return "Adventure"
        default: return mode
        }
    }
}

struct PlaylistTrackRow: View {
    let track: PlaylistTrack
    let rank: Int
    
    @EnvironmentObject var audioPlayer: AudioPlayer
    private let hapticFeedback = UIImpactFeedbackGenerator(style: .light)
    
    var body: some View {
        HStack(spacing: 12) {
            Text("\(rank)")
                .font(.caption)
                .fontWeight(.medium)
                .foregroundStyle(.secondary)
                .frame(width: 24)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(track.trackName ?? "Unknown")
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .lineLimit(1)
                
                Text(track.artistName ?? "Unknown")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                
                if let explanation = track.explanation {
                    Text(explanation)
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }
            }
            
            Spacer()
            
            HStack(spacing: 8) {
                if let previewUrl = track.previewUrl {
                    Button {
                        hapticFeedback.impactOccurred()
                        audioPlayer.play(url: previewUrl, trackId: track.trackId)
                    } label: {
                        Image(systemName: audioPlayer.currentTrackId == track.trackId && audioPlayer.isPlaying ? "pause.circle.fill" : "play.circle.fill")
                            .font(.system(size: 28))
                            .foregroundStyle(.purple)
                    }
                    .buttonStyle(.plain)
                }
                
                if let spotifyUrl = track.spotifyUrl, let url = URL(string: spotifyUrl) {
                    Button {
                        UIApplication.shared.open(url)
                    } label: {
                        Image(systemName: "arrow.up.right.circle")
                            .font(.system(size: 20))
                            .foregroundStyle(.secondary)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .padding(.vertical, 12)
    }
}

struct RemixPromptSheet: View {
    let playlist: Playlist
    let onRemix: () -> Void
    
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                VStack(spacing: 16) {
                    Image(systemName: "arrow.triangle.2.circlepath")
                        .font(.system(size: 48))
                        .foregroundStyle(.purple)
                    
                    Text("Remix This Prompt")
                        .font(.title2)
                        .fontWeight(.bold)
                    
                    Text("Use this playlist's settings as a starting point for your own pairing")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                }
                
                VStack(alignment: .leading, spacing: 12) {
                    if let seedTrackName = playlist.seedTrackName {
                        HStack {
                            Text("Seed:")
                                .foregroundStyle(.secondary)
                            Text(seedTrackName)
                        }
                        .font(.subheadline)
                    }
                    
                    if let mode = playlist.mode {
                        HStack {
                            Text("Mode:")
                                .foregroundStyle(.secondary)
                            Text(formatMode(mode))
                        }
                        .font(.subheadline)
                    }
                    
                    if let promptText = playlist.promptText, !promptText.isEmpty {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Prompt:")
                                .foregroundStyle(.secondary)
                            Text("\"\(promptText)\"")
                                .italic()
                        }
                        .font(.subheadline)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(12)
                
                Spacer()
                
                Button {
                    onRemix()
                    dismiss()
                } label: {
                    HStack {
                        Image(systemName: "arrow.triangle.2.circlepath")
                        Text("Remix This Prompt")
                    }
                    .fontWeight(.semibold)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.purple)
                    .foregroundColor(.white)
                    .cornerRadius(12)
                }
            }
            .padding()
            .navigationTitle("Remix")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
        }
        .presentationDetents([.medium])
    }
    
    private func formatMode(_ mode: String) -> String {
        switch mode {
        case "same_sound": return "Same Sound"
        case "same_vibe": return "Same Vibe"
        case "same_scene": return "Same Scene"
        case "adventure": return "Adventure"
        default: return mode
        }
    }
}

#Preview {
    NavigationStack {
        PlaylistDetailView(playlistId: "test-playlist-id")
    }
    .environmentObject(AuthManager.shared)
    .environmentObject(AudioPlayer.shared)
}
