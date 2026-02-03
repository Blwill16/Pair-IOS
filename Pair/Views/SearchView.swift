import SwiftUI

struct SearchView: View {
    @State private var searchText = ""
    @State private var searchResults: [SpotifyTrack] = []
    @State private var isSearching = false
    @State private var selectedTrack: SpotifyTrack?
    @State private var showPromptView = false
    @State private var errorMessage: String?
    
    private let apiService = APIService.shared
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                if searchResults.isEmpty && !isSearching {
                    emptyStateView
                } else {
                    searchResultsList
                }
            }
            .navigationTitle("Find a Song")
            .searchable(text: $searchText, prompt: "Search for a track")
            .onSubmit(of: .search) {
                performSearch()
            }
            .onChange(of: searchText) { _, newValue in
                if newValue.isEmpty {
                    searchResults = []
                }
            }
            .navigationDestination(isPresented: $showPromptView) {
                if let track = selectedTrack {
                    PromptView(seedTrack: track)
                }
            }
        }
    }
    
    private var emptyStateView: some View {
        VStack(spacing: 24) {
            Spacer()
            
            Image(systemName: "music.magnifyingglass")
                .font(.system(size: 64))
                .foregroundStyle(.purple.opacity(0.6))
            
            VStack(spacing: 8) {
                Text("Search for a song")
                    .font(.title2)
                    .fontWeight(.semibold)
                
                Text("Find a track to use as your seed for discovering similar music")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
            }
            
            Spacer()
        }
    }
    
    private var searchResultsList: some View {
        List {
            if isSearching {
                HStack {
                    Spacer()
                    ProgressView()
                    Spacer()
                }
                .listRowBackground(Color.clear)
            } else {
                ForEach(searchResults) { track in
                    TrackRowView(
                        trackName: track.trackName,
                        artistName: track.artistName,
                        albumArtUrl: track.albumArtUrl,
                        previewUrl: track.previewUrl,
                        trackId: track.trackId
                    )
                    .contentShape(Rectangle())
                    .onTapGesture {
                        selectedTrack = track
                        showPromptView = true
                    }
                }
            }
            
            if let error = errorMessage {
                Text(error)
                    .font(.caption)
                    .foregroundStyle(.red)
                    .listRowBackground(Color.clear)
            }
        }
        .listStyle(.plain)
    }
    
    private func performSearch() {
        guard !searchText.isEmpty else { return }
        
        isSearching = true
        errorMessage = nil
        
        Task {
            do {
                let results = try await apiService.searchTracks(query: searchText)
                await MainActor.run {
                    searchResults = results
                    isSearching = false
                }
            } catch {
                await MainActor.run {
                    errorMessage = error.localizedDescription
                    isSearching = false
                }
            }
        }
    }
}

#Preview {
    SearchView()
        .environmentObject(AudioPlayer.shared)
}
