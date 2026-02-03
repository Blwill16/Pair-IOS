import SwiftUI

// MARK: - Mock Playlist Data for Design
struct MockPlaylist: Identifiable {
    let id = UUID()
    let title: String
    let description: String
    let seedTrack: String
    let seedArtist: String
    let imageUrl: String
    let creatorName: String
    let creatorAvatar: String
    let trackCount: Int
}

let mockDiscoverPlaylists = [
    MockPlaylist(
        title: "Late Night Drive",
        description: "Empty highways, city lights fading. That feeling when you're driving nowhere in particular.",
        seedTrack: "Nightcall",
        seedArtist: "Kavinsky",
        imageUrl: "https://images.unsplash.com/photo-1493225457124-a3eb161ffa5f?w=400",
        creatorName: "Alex Chen",
        creatorAvatar: "https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=100",
        trackCount: 18
    ),
    MockPlaylist(
        title: "Gentle Morning",
        description: "Sunday morning light through curtains. Coffee brewing, world still quiet.",
        seedTrack: "Holocene",
        seedArtist: "Bon Iver",
        imageUrl: "https://images.unsplash.com/photo-1459749411175-04bf5292ceea?w=400",
        creatorName: "Maya Patel",
        creatorAvatar: "https://images.unsplash.com/photo-1494790108377-be9c29b29330?w=100",
        trackCount: 14
    ),
    MockPlaylist(
        title: "Lost in Thought",
        description: "Walking alone through a familiar city. Every street corner holds a memory.",
        seedTrack: "Motion Picture Soundtrack",
        seedArtist: "Radiohead",
        imageUrl: "https://images.unsplash.com/photo-1470225620780-dba8ba36b745?w=400",
        creatorName: "Jordan Lee",
        creatorAvatar: "https://images.unsplash.com/photo-1500648767791-00dcc994a43e?w=100",
        trackCount: 16
    ),
    MockPlaylist(
        title: "First Rain",
        description: "That smell after the first rain. Everything feels clearer, renewed.",
        seedTrack: "Intro",
        seedArtist: "The xx",
        imageUrl: "https://images.unsplash.com/photo-1511671782779-c97d3d27a1d4?w=400",
        creatorName: "Sam Rivers",
        creatorAvatar: "https://images.unsplash.com/photo-1438761681033-6461ffad8d80?w=100",
        trackCount: 12
    )
]

struct ExploreView: View {
    @EnvironmentObject var authManager: AuthManager
    
    @State private var publicPlaylists: [Playlist] = []
    @State private var myPlaylists: [Playlist] = []
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var selectedPlaylist: Playlist?
    @State private var selectedMockPlaylist: MockPlaylist?
    
    private let apiService = APIService.shared
    
    private var allPlaylists: [Playlist] {
        let combined = myPlaylists + publicPlaylists.filter { pub in
            !myPlaylists.contains { $0.id == pub.id }
        }
        return combined
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color.pairBackground.ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 0) {
                        // Fixed header per Figma
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Discover")
                                .font(.system(size: 28, weight: .bold))
                                .foregroundColor(.pairTextPrimary)
                            
                            Text("Playlists curated by people with taste")
                                .font(.subheadline)
                                .foregroundColor(.pairTextSecondary)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal, 24)
                        .padding(.top, 16)
                        .padding(.bottom, 20)
                        
                        // Playlist cards grid
                        LazyVStack(spacing: 16) {
                            ForEach(mockDiscoverPlaylists) { playlist in
                                DiscoverPlaylistCard(playlist: playlist)
                                    .onTapGesture {
                                        selectedMockPlaylist = playlist
                                    }
                            }
                            
                            // Also show real playlists if any
                            ForEach(allPlaylists) { playlist in
                                ExplorePlaylistRow(playlist: playlist)
                                    .contentShape(Rectangle())
                                    .onTapGesture {
                                        selectedPlaylist = playlist
                                    }
                            }
                        }
                        .padding(.horizontal, 24)
                        .padding(.bottom, 120)
                    }
                }
                
                if isLoading && allPlaylists.isEmpty && mockDiscoverPlaylists.isEmpty {
                    ProgressView()
                        .tint(.pairPurple)
                }
            }
            .navigationTitle("")
            .navigationBarHidden(true)
            .refreshable {
                await loadPlaylists()
            }
            .task {
                await loadPlaylists()
            }
            .navigationDestination(item: $selectedPlaylist) { playlist in
                PlaylistDetailView(playlistId: playlist.id)
            }
        }
    }
    
    private func loadPlaylists() async {
        isLoading = true
        errorMessage = nil
        
        do {
            async let publicFetch = apiService.getPublicPlaylists()
            
            var userPlaylists: [Playlist] = []
            if let userId = authManager.userId {
                userPlaylists = try await apiService.getUserPlaylists(userId: userId)
            }
            
            let fetchedPublic = try await publicFetch
            
            await MainActor.run {
                publicPlaylists = fetchedPublic
                myPlaylists = userPlaylists
                isLoading = false
            }
        } catch {
            await MainActor.run {
                errorMessage = error.localizedDescription
                isLoading = false
            }
        }
    }
}

// MARK: - Discover Playlist Card (Figma Design)
struct DiscoverPlaylistCard: View {
    let playlist: MockPlaylist
    @State private var isPressed = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Cover image - square with rounded corners per Figma
            AsyncImage(url: URL(string: playlist.imageUrl)) { image in
                image
                    .resizable()
                    .aspectRatio(contentMode: .fill)
            } placeholder: {
                Rectangle()
                    .fill(Color.pairBackgroundSecondary)
                    .overlay {
                        Image(systemName: "music.note")
                            .font(.system(size: 32))
                            .foregroundColor(.pairTextTertiary)
                    }
            }
            .frame(height: 180)
            .frame(maxWidth: .infinity)
            .cornerRadius(12)
            .shadow(color: Color.black.opacity(0.08), radius: 4, y: 2)
            
            // Playlist title
            Text(playlist.title)
                .font(.headline)
                .fontWeight(.semibold)
                .foregroundColor(.pairTextPrimary)
            
            // Description/vibe text - italic per Figma
            Text(playlist.description)
                .font(.subheadline)
                .italic()
                .foregroundColor(.pairTextSecondary)
                .lineLimit(2)
            
            // Curator info row
            HStack(spacing: 8) {
                // Small avatar
                AsyncImage(url: URL(string: playlist.creatorAvatar)) { image in
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                } placeholder: {
                    Circle()
                        .fill(Color.pairBackgroundSecondary)
                }
                .frame(width: 32, height: 32)
                .clipShape(Circle())
                .overlay(
                    Circle()
                        .stroke(Color.pairCardBorder, lineWidth: 1)
                )
                
                // Curator name
                Text(playlist.creatorName)
                    .font(.caption)
                    .foregroundColor(.pairTextSecondary)
                
                Spacer()
                
                // Track count
                Text("\(playlist.trackCount) tracks")
                    .font(.caption)
                    .foregroundColor(.pairTextTertiary)
            }
        }
        .padding(16)
        .background(Color.pairCardBackground)
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.04), radius: 12, y: 2)
        .scaleEffect(isPressed ? 1.02 : 1.0)
        .animation(.easeOut(duration: 0.2), value: isPressed)
        .onLongPressGesture(minimumDuration: .infinity, pressing: { pressing in
            isPressed = pressing
        }, perform: {})
    }
}

// MARK: - Explore Playlist Row (for real playlists)
struct ExplorePlaylistRow: View {
    let playlist: Playlist
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(playlist.title)
                .font(.headline)
                .foregroundColor(.pairTextPrimary)
            
            if let seedTrackName = playlist.seedTrackName {
                HStack(spacing: 8) {
                    RoundedRectangle(cornerRadius: 6)
                        .fill(Color.pairBackgroundSecondary)
                        .frame(width: 40, height: 40)
                        .overlay {
                            Image(systemName: "music.note")
                                .foregroundColor(.pairTextTertiary)
                                .font(.system(size: 14))
                        }
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Seed")
                            .font(.caption2)
                            .foregroundColor(.pairTextTertiary)
                        
                        Text(seedTrackName)
                            .font(.caption)
                            .fontWeight(.medium)
                            .foregroundColor(.pairTextPrimary)
                            .lineLimit(1)
                    }
                }
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.pairCardBackground)
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.05), radius: 8, y: 2)
    }
}

#Preview {
    ExploreView()
        .environmentObject(AuthManager.shared)
        .environmentObject(AudioPlayer.shared)
}
