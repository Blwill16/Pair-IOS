import SwiftUI

struct TrackRowView: View {
    let trackName: String
    let artistName: String
    let albumArtUrl: String?
    let previewUrl: String?
    let trackId: String
    
    @EnvironmentObject var audioPlayer: AudioPlayer
    
    var body: some View {
        HStack(spacing: 12) {
            AsyncImage(url: URL(string: albumArtUrl ?? "")) { image in
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
                Text(trackName)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .lineLimit(1)
                
                Text(artistName)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            
            Spacer()
            
            if let previewUrl = previewUrl {
                Button {
                    audioPlayer.play(url: previewUrl, trackId: trackId)
                } label: {
                    Image(systemName: audioPlayer.currentTrackId == trackId && audioPlayer.isPlaying ? "pause.circle.fill" : "play.circle.fill")
                        .font(.system(size: 32))
                        .foregroundStyle(.purple)
                }
                .buttonStyle(.plain)
            }
            
            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding(.vertical, 4)
    }
}

#Preview {
    TrackRowView(
        trackName: "Test Song",
        artistName: "Test Artist",
        albumArtUrl: nil,
        previewUrl: nil,
        trackId: "test"
    )
    .environmentObject(AudioPlayer.shared)
}
