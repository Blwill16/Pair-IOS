import SwiftUI

struct ExploreView: View {
    @EnvironmentObject var authManager: AuthManager
    
    @State private var publicPlaylists: [Playlist] = []
    @State private var myPlaylists: [Playlist] = []
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var selectedPlaylist: Playlist?
    
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
                
                Group {
                    if isLoading && allPlaylists.isEmpty {
                        loadingView
                    } else if allPlaylists.isEmpty {
                        emptyStateView
                    } else {
                        playlistsList
                    }
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
    
    private var loadingView: some View {
        VStack {
            Spacer()
            ProgressView()
                .tint(.pairPurple)
            Spacer()
        }
    }
    
    private var emptyStateView: some View {
        VStack(spacing: 24) {
            Spacer()
            
            ZStack {
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [Color.pairPurple.opacity(0.15), Color.clear],
                            center: .center,
                            startRadius: 0,
                            endRadius: 100
                        )
                    )
                    .frame(width: 200, height: 200)
                    .blur(radius: 30)
                
                Image(systemName: "globe")
                    .font(.system(size: 64))
                    .foregroundColor(.pairPurple.opacity(0.6))
            }
            
            VStack(spacing: 8) {
                Text("No playlists yet")
                    .font(.title2)
                    .fontWeight(.semibold)
                    .foregroundColor(.white)
                
                Text("Be the first to create and share a playlist!")
                    .font(.subheadline)
                    .foregroundColor(.pairTextSecondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
            }
            
            if let error = errorMessage {
                Text(error)
                    .font(.caption)
                    .foregroundColor(.red)
            }
            
            Spacer()
        }
    }
    
    private var playlistsList: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Header
                Text("Explore")
                    .font(.system(size: 28, weight: .bold))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, 16)
                    .padding(.top, 60)
                
                if !myPlaylists.isEmpty {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Your Playlists")
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .foregroundColor(.pairTextSecondary)
                            .padding(.horizontal, 16)
                        
                        LazyVStack(spacing: 0) {
                            ForEach(myPlaylists) { playlist in
                                ExplorePlaylistRow(playlist: playlist)
                                    .contentShape(Rectangle())
                                    .onTapGesture {
                                        selectedPlaylist = playlist
                                    }
                            }
                        }
                    }
                }
                
                if !publicPlaylists.isEmpty {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Discover")
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .foregroundColor(.pairTextSecondary)
                            .padding(.horizontal, 16)
                        
                        LazyVStack(spacing: 0) {
                            ForEach(publicPlaylists.filter { pub in
                                !myPlaylists.contains { $0.id == pub.id }
                            }) { playlist in
                                ExplorePlaylistRow(playlist: playlist)
                                    .contentShape(Rectangle())
                                    .onTapGesture {
                                        selectedPlaylist = playlist
                                    }
                            }
                        }
                    }
                }
            }
            .padding(.bottom, 100)
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

// MARK: - Explore Playlist Row
struct ExplorePlaylistRow: View {
    let playlist: Playlist
    
    var body: some View {
        HStack(spacing: 14) {
            RoundedRectangle(cornerRadius: 8)
                .fill(Color.pairPurple.opacity(0.2))
                .frame(width: 56, height: 56)
                .overlay {
                    Image(systemName: "music.note.list")
                        .foregroundColor(.pairPurple)
                }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(playlist.title)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(.white)
                    .lineLimit(1)
                
                HStack(spacing: 8) {
                    if let seedTrackName = playlist.seedTrackName {
                        Text("Seed: \(seedTrackName)")
                            .font(.caption)
                            .foregroundColor(.pairTextSecondary)
                            .lineLimit(1)
                    }
                    
                    if let likeCount = playlist.likeCount, likeCount > 0 {
                        HStack(spacing: 2) {
                            Image(systemName: "heart.fill")
                                .font(.system(size: 10))
                            Text("\(likeCount)")
                        }
                        .font(.caption)
                        .foregroundColor(.pairTextTertiary)
                    }
                }
            }
            
            Spacer()
            
            Image(systemName: "chevron.right")
                .font(.system(size: 14))
                .foregroundColor(.pairTextTertiary)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
    }
}

#Preview {
    ExploreView()
        .environmentObject(AuthManager.shared)
        .environmentObject(AudioPlayer.shared)
}
