import SwiftUI

struct ExploreView: View {
    @State private var playlists: [Playlist] = []
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var selectedPlaylist: Playlist?
    
    private let apiService = APIService.shared
    
    var body: some View {
        NavigationStack {
            Group {
                if isLoading && playlists.isEmpty {
                    loadingView
                } else if playlists.isEmpty {
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
            Section {
                ForEach(playlists) { playlist in
                    PlaylistRowView(playlist: playlist)
                        .contentShape(Rectangle())
                        .onTapGesture {
                            selectedPlaylist = playlist
                        }
                }
            } header: {
                Text("Public Playlists")
                    .textCase(nil)
            }
        }
        .listStyle(.plain)
    }
    
    private func loadPlaylists() async {
        isLoading = true
        errorMessage = nil
        
        do {
            let fetchedPlaylists = try await apiService.getPublicPlaylists()
            await MainActor.run {
                playlists = fetchedPlaylists
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
