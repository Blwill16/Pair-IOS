import Foundation

class RemixManager: ObservableObject {
    static let shared = RemixManager()
    
    @Published var remixData: RemixData?
    
    struct RemixData {
        let seedTrackId: String?
        let seedTrackName: String?
        let seedArtistName: String?
        let promptText: String?
        let mode: String?
    }
    
    func setRemix(from playlist: Playlist) {
        remixData = RemixData(
            seedTrackId: playlist.seedTrackId,
            seedTrackName: playlist.seedTrackName,
            seedArtistName: playlist.seedArtistName,
            promptText: playlist.promptText,
            mode: playlist.mode
        )
    }
    
    func clearRemix() {
        remixData = nil
    }
}
