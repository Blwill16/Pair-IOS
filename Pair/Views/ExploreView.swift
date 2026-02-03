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
            Group {
                if isLoading && allPlaylists.isEmpty {
                    loadingView
                } else if allPlaylists.isEmpty {
                    emptyStateView
                } else {
                    playlistsList
                }
            }
            .navigationTitle("Explore")
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
            Spacer()
        }
    }
    
    private var emptyStateView: some View {
        VStack(spacing: 24) {
            Spacer()
            
            Image(systemName: "globe")
                .font(.system(size: 64))
                .foregroundStyle(.purple.opacity(0.6))
            
            VStack(spacing: 8) {
                Text("No playlists yet")
                    .font(.title2)
                    .fontWeight(.semibold)
                
                Text("Be the first to create and share a playlist!")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
            }
            
            if let error = errorMessage {
                Text(error)
                    .font(.caption)
                    .foregroundStyle(.red)
            }
            
            Spacer()
        }
    }
    
    private var playlistsList: some View {
        List {
            if !myPlaylists.isEmpty {
                Section {
                    ForEach(myPlaylists) { playlist in
                        PlaylistRowView(playlist: playlist)
                            .contentShape(Rectangle())
                            .onTapGesture {
                                selectedPlaylist = playlist
                            }
                    }
                } header: {
                    Text("Your Playlists")
                        .textCase(nil)
                }
            }
            
            if !publicPlaylists.isEmpty {
                Section {
                    ForEach(publicPlaylists.filter { pub in
                        !myPlaylists.contains { $0.id == pub.id }
                    }) { playlist in
                        PlaylistRowView(playlist: playlist)
                            .contentShape(Rectangle())
                            .onTapGesture {
                                selectedPlaylist = playlist
                            }
                    }
                } header: {
                    Text("Discover")
                        .textCase(nil)
                }
            }
        }
        .listStyle(.plain)
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

#Preview {
    ExploreView()
        .environmentObject(AuthManager.shared)
        .environmentObject(AudioPlayer.shared)
}
