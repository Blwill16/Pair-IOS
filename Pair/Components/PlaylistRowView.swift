import SwiftUI

struct PlaylistRowView: View {
    let playlist: Playlist
    
    var body: some View {
        HStack(spacing: 12) {
            ZStack {
                Rectangle()
                    .fill(
                        LinearGradient(
                            colors: [.purple.opacity(0.6), .purple.opacity(0.3)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                
                Image(systemName: "waveform")
                    .font(.system(size: 24))
                    .foregroundStyle(.white)
            }
            .frame(width: 60, height: 60)
            .cornerRadius(8)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(playlist.title)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .lineLimit(1)
                
                if let seedTrackName = playlist.seedTrackName {
                    Text("Based on \(seedTrackName)")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }
                
                HStack(spacing: 12) {
                    if let mode = playlist.mode {
                        Text(formatMode(mode))
                            .font(.caption2)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Color.purple.opacity(0.2))
                            .foregroundStyle(.purple)
                            .cornerRadius(4)
                    }
                    
                    if let likeCount = playlist.likeCount, likeCount > 0 {
                        HStack(spacing: 2) {
                            Image(systemName: "heart.fill")
                                .font(.caption2)
                            Text("\(likeCount)")
                                .font(.caption2)
                        }
                        .foregroundStyle(.secondary)
                    }
                }
            }
            
            Spacer()
            
            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding(.vertical, 4)
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
    PlaylistRowView(playlist: Playlist(
        id: "test",
        ownerId: "owner",
        title: "Test Playlist",
        promptText: "late night vibes",
        seedTrackId: "seed",
        seedTrackName: "Test Song",
        seedArtistName: "Test Artist",
        mode: "same_vibe",
        isPublic: true,
        createdAt: nil,
        tracks: nil,
        likeCount: 42,
        viewerHasLiked: false,
        profiles: nil
    ))
}
