import SwiftUI

struct GenreDetailView: View {
    @EnvironmentObject var authManager: AuthManager
    @Environment(\.dismiss) var dismiss
    @StateObject private var audioPlayer = AudioPlayer.shared
    
    let genre: WeeklyDropGenre
    
    @State private var currentlyPlayingId: String?
    @State private var playbackProgress: Double = 0
    
    var body: some View {
        NavigationView {
            ZStack {
                Color.pairBackground.ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 0) {
                        headerView
                        
                        trackListView
                        
                        Spacer(minLength: 100)
                    }
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(.primary)
                    }
                }
                
                ToolbarItem(placement: .principal) {
                    Text(genre.displayName)
                        .font(.system(size: 17, weight: .semibold))
                }
            }
        }
    }
    
    private var headerView: some View {
        VStack(spacing: 16) {
            ZStack {
                LinearGradient(
                    colors: [Color.pairPurple.opacity(0.3), Color.pairPurple.opacity(0.1)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                
                VStack(spacing: 8) {
                    Text(genre.displayName)
                        .font(.system(size: 28, weight: .bold))
                    
                    if let descriptor = genre.descriptor {
                        Text(descriptor)
                            .font(.system(size: 16))
                            .foregroundColor(.secondary)
                    }
                    
                    Text("\(genre.trackCount) tracks this week")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.pairPurple)
                        .padding(.top, 4)
                }
                .padding(.vertical, 32)
            }
            .frame(height: 160)
        }
    }
    
    private var trackListView: some View {
        VStack(spacing: 0) {
            ForEach(Array(genre.tracks.enumerated()), id: \.element.id) { index, track in
                DropTrackRowView(
                    track: track,
                    position: index + 1,
                    isPlaying: currentlyPlayingId == track.id,
                    onPlay: { playTrack(track) },
                    onSave: { saveTrack(track) },
                    onDislike: { dislikeTrack(track) }
                )
                .padding(.horizontal, 20)
                .padding(.vertical, 8)
                
                if index < genre.tracks.count - 1 {
                    Divider()
                        .padding(.horizontal, 20)
                }
            }
        }
        .padding(.top, 16)
    }
    
    private func playTrack(_ track: WeeklyDropTrack) {
        guard let previewUrl = track.previewUrl, let url = URL(string: previewUrl) else { return }
        
        if currentlyPlayingId == track.id {
            audioPlayer.pause()
            currentlyPlayingId = nil
        } else {
            audioPlayer.play(url: url)
            currentlyPlayingId = track.id
            
            if let userId = authManager.userId {
                Task {
                    await APIService.shared.logTrackAction(
                        userId: userId,
                        action: "play",
                        trackId: track.id,
                        appleMusicId: track.appleMusicId,
                        weeklyDropId: nil,
                        durationMs: nil,
                        context: "genre_detail"
                    )
                }
            }
        }
    }
    
    private func saveTrack(_ track: WeeklyDropTrack) {
        guard let userId = authManager.userId else { return }
        
        Task {
            await APIService.shared.logTrackAction(
                userId: userId,
                action: "save",
                trackId: track.id,
                appleMusicId: track.appleMusicId,
                weeklyDropId: nil,
                durationMs: nil,
                context: "genre_detail"
            )
        }
    }
    
    private func dislikeTrack(_ track: WeeklyDropTrack) {
        guard let userId = authManager.userId else { return }
        
        Task {
            await APIService.shared.logTrackAction(
                userId: userId,
                action: "dislike",
                trackId: track.id,
                appleMusicId: track.appleMusicId,
                weeklyDropId: nil,
                durationMs: nil,
                context: "genre_detail"
            )
        }
    }
}

struct DropTrackRowView: View {
    let track: WeeklyDropTrack
    let position: Int
    let isPlaying: Bool
    let onPlay: () -> Void
    let onSave: () -> Void
    let onDislike: () -> Void
    
    @State private var isSaved = false
    @State private var isDisliked = false
    
    var body: some View {
        HStack(spacing: 16) {
            Text("\(position)")
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(.secondary)
                .frame(width: 24)
            
            Button(action: onPlay) {
                ZStack {
                    AsyncImage(url: URL(string: track.albumArtUrl ?? "")) { image in
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                    } placeholder: {
                        Rectangle()
                            .fill(Color.gray.opacity(0.2))
                    }
                    .frame(width: 56, height: 56)
                    .cornerRadius(8)
                    
                    if track.previewUrl != nil {
                        Circle()
                            .fill(Color.black.opacity(0.4))
                            .frame(width: 32, height: 32)
                        
                        Image(systemName: isPlaying ? "pause.fill" : "play.fill")
                            .font(.system(size: 12))
                            .foregroundColor(.white)
                    }
                }
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(track.trackName ?? "Unknown")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.primary)
                    .lineLimit(1)
                
                Text(track.artistName ?? "Unknown")
                    .font(.system(size: 14))
                    .foregroundColor(.secondary)
                    .lineLimit(1)
                
                if let reason = track.reason {
                    Text(reason)
                        .font(.system(size: 12))
                        .foregroundColor(.pairPurple)
                        .lineLimit(1)
                }
            }
            
            Spacer()
            
            HStack(spacing: 12) {
                Button {
                    withAnimation(.spring(response: 0.3)) {
                        isDisliked.toggle()
                        if isDisliked { onDislike() }
                    }
                } label: {
                    Image(systemName: isDisliked ? "hand.thumbsdown.fill" : "hand.thumbsdown")
                        .font(.system(size: 18))
                        .foregroundColor(isDisliked ? .red : .secondary)
                }
                
                Button {
                    withAnimation(.spring(response: 0.3)) {
                        isSaved.toggle()
                        if isSaved { onSave() }
                    }
                } label: {
                    Image(systemName: isSaved ? "heart.fill" : "heart")
                        .font(.system(size: 18))
                        .foregroundColor(isSaved ? .pairPurple : .secondary)
                }
            }
        }
        .padding(.vertical, 8)
    }
}

#Preview {
    GenreDetailView(genre: WeeklyDropGenre(
        slug: "melodic-electronic",
        displayName: "Melodic Electronic",
        descriptor: "Atmospheric builds and emotional drops",
        trackCount: 3,
        tracks: []
    ))
    .environmentObject(AuthManager())
}
