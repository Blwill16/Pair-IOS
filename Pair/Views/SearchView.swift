import SwiftUI

// MARK: - Mock Data for Design
struct MockSong: Identifiable {
    let id = UUID()
    let name: String
    let artist: String
    let imageUrl: String
}

let mockRecentPairings = [
    MockSong(name: "Midnight City", artist: "M83", imageUrl: "https://images.unsplash.com/photo-1493225457124-a3eb161ffa5f?w=100"),
    MockSong(name: "Holocene", artist: "Bon Iver", imageUrl: "https://images.unsplash.com/photo-1459749411175-04bf5292ceea?w=100")
]

let mockTrendingSeeds = [
    MockSong(name: "Intro", artist: "The xx", imageUrl: "https://images.unsplash.com/photo-1470225620780-dba8ba36b745?w=100"),
    MockSong(name: "Teardrop", artist: "Massive Attack", imageUrl: "https://images.unsplash.com/photo-1511671782779-c97d3d27a1d4?w=100")
]

struct SearchView: View {
    @State private var searchText = ""
    @State private var searchResults: [SpotifyTrack] = []
    @State private var isSearching = false
    @State private var selectedTrack: SpotifyTrack?
    @State private var showPromptView = false
    @State private var errorMessage: String?
    @State private var placeholderIndex = 0
    
    private let apiService = APIService.shared
    private let placeholders = ["Search a song", "Search an artist", "Type a feeling"]
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color.pairBackground.ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 0) {
                        if searchResults.isEmpty && !isSearching {
                            emptyStateView
                        } else {
                            searchResultsView
                        }
                    }
                }
            }
            .navigationTitle("")
            .navigationBarHidden(true)
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
        VStack(spacing: 0) {
            // Header section
            VStack(spacing: 8) {
                Text("Start with a song")
                    .font(.system(size: 32, weight: .bold))
                    .foregroundColor(.pairTextPrimary)
                
                Text("We'll find what belongs with it")
                    .font(.body)
                    .foregroundColor(.pairTextSecondary)
            }
            .padding(.top, 80)
            .padding(.bottom, 32)
            
            // Search bar
            HStack(spacing: 12) {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(.pairTextTertiary)
                    .font(.system(size: 18))
                
                TextField("", text: $searchText, prompt: Text(placeholders[placeholderIndex])
                    .foregroundColor(.pairTextTertiary))
                    .foregroundColor(.pairTextPrimary)
                    .font(.body)
                    .onSubmit {
                        performSearch()
                    }
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 18)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color.pairBackgroundSecondary)
            )
            .padding(.horizontal, 24)
            .padding(.bottom, 40)
            
            // Your recent pairings section
            VStack(alignment: .leading, spacing: 16) {
                HStack(spacing: 8) {
                    Image(systemName: "clock")
                        .font(.system(size: 14))
                        .foregroundColor(.pairTextSecondary)
                    
                    Text("Your recent pairings")
                        .font(.headline)
                        .foregroundColor(.pairTextPrimary)
                }
                .padding(.horizontal, 24)
                
                // Recent songs horizontal scroll
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 12) {
                        ForEach(mockRecentPairings) { song in
                            RecentSongCard(song: song) {
                                let track = SpotifyTrack(
                                    id: song.id.uuidString,
                                    trackName: song.name,
                                    artistName: song.artist,
                                    albumName: "",
                                    albumArtUrl: song.imageUrl,
                                    previewUrl: nil,
                                    spotifyUrl: nil
                                )
                                selectedTrack = track
                                showPromptView = true
                            }
                        }
                    }
                    .padding(.horizontal, 24)
                }
            }
            .padding(.bottom, 32)
            
            // Trending seeds section
            VStack(alignment: .leading, spacing: 16) {
                HStack(spacing: 8) {
                    Image(systemName: "sparkles")
                        .font(.system(size: 14))
                        .foregroundColor(.pairTextSecondary)
                    
                    Text("Trending seeds")
                        .font(.headline)
                        .foregroundColor(.pairTextPrimary)
                    
                    Spacer()
                    
                    Text("rising now")
                        .font(.caption)
                        .foregroundColor(.pairTextTertiary)
                }
                .padding(.horizontal, 24)
                
                // Trending songs
                VStack(spacing: 0) {
                    ForEach(mockTrendingSeeds) { song in
                        TrendingSongRow(song: song) {
                            let track = SpotifyTrack(
                                id: song.id.uuidString,
                                trackName: song.name,
                                artistName: song.artist,
                                albumName: "",
                                albumArtUrl: song.imageUrl,
                                previewUrl: nil,
                                spotifyUrl: nil
                            )
                            selectedTrack = track
                            showPromptView = true
                        }
                    }
                }
                .padding(.horizontal, 24)
            }
            .padding(.bottom, 24)
            
            // Random inspiration button
            Button {
                if let randomSong = mockTrendingSeeds.randomElement() {
                    let track = SpotifyTrack(
                        id: randomSong.id.uuidString,
                        trackName: randomSong.name,
                        artistName: randomSong.artist,
                        albumName: "",
                        albumArtUrl: randomSong.imageUrl,
                        previewUrl: nil,
                        spotifyUrl: nil
                    )
                    selectedTrack = track
                    showPromptView = true
                }
            } label: {
                HStack(spacing: 8) {
                    Image(systemName: "dice")
                        .font(.system(size: 16))
                    Text("Random inspiration")
                        .font(.subheadline)
                        .fontWeight(.medium)
                }
                .foregroundColor(.pairTextSecondary)
                .padding(.horizontal, 20)
                .padding(.vertical, 14)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.pairCardBorder, lineWidth: 1)
                )
            }
            .padding(.bottom, 120)
        }
        .onAppear {
            startPlaceholderCycling()
        }
    }
    
    private var searchResultsView: some View {
        VStack(spacing: 0) {
            // Search bar at top
            HStack(spacing: 12) {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(.pairTextTertiary)
                
                TextField("", text: $searchText, prompt: Text("Search...")
                    .foregroundColor(.pairTextTertiary))
                    .foregroundColor(.pairTextPrimary)
                    .onSubmit {
                        performSearch()
                    }
                
                if !searchText.isEmpty {
                    Button {
                        searchText = ""
                        searchResults = []
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.pairTextTertiary)
                    }
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
            .background(Color.pairBackgroundSecondary)
            .cornerRadius(12)
            .padding(.horizontal, 16)
            .padding(.top, 60)
            .padding(.bottom, 16)
            
            if isSearching {
                Spacer()
                ProgressView()
                    .tint(.pairPurple)
                Spacer()
            } else {
                LazyVStack(spacing: 0) {
                    ForEach(searchResults) { track in
                        SearchResultRow(track: track)
                            .contentShape(Rectangle())
                            .onTapGesture {
                                selectedTrack = track
                                showPromptView = true
                            }
                    }
                }
                .padding(.bottom, 120)
            }
            
            if let error = errorMessage {
                Text(error)
                    .font(.caption)
                    .foregroundColor(.red)
                    .padding()
            }
        }
    }
    
    private func startPlaceholderCycling() {
        Timer.scheduledTimer(withTimeInterval: 3.0, repeats: true) { _ in
            withAnimation(.easeInOut(duration: 0.3)) {
                placeholderIndex = (placeholderIndex + 1) % placeholders.count
            }
        }
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

// MARK: - Recent Song Card
struct RecentSongCard: View {
    let song: MockSong
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: 8) {
                AsyncImage(url: URL(string: song.imageUrl)) { image in
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                } placeholder: {
                    Rectangle()
                        .fill(Color.pairBackgroundSecondary)
                        .overlay {
                            Image(systemName: "music.note")
                                .foregroundColor(.pairTextTertiary)
                        }
                }
                .frame(width: 120, height: 120)
                .cornerRadius(12)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(song.name)
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(.pairTextPrimary)
                        .lineLimit(1)
                    
                    Text(song.artist)
                        .font(.caption)
                        .foregroundColor(.pairTextSecondary)
                        .lineLimit(1)
                }
            }
            .frame(width: 120)
        }
    }
}

// MARK: - Trending Song Row
struct TrendingSongRow: View {
    let song: MockSong
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                AsyncImage(url: URL(string: song.imageUrl)) { image in
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                } placeholder: {
                    Rectangle()
                        .fill(Color.pairBackgroundSecondary)
                        .overlay {
                            Image(systemName: "music.note")
                                .foregroundColor(.pairTextTertiary)
                        }
                }
                .frame(width: 48, height: 48)
                .cornerRadius(8)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(song.name)
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(.pairTextPrimary)
                        .lineLimit(1)
                    
                    Text(song.artist)
                        .font(.caption)
                        .foregroundColor(.pairTextSecondary)
                        .lineLimit(1)
                }
                
                Spacer()
            }
            .padding(.vertical, 8)
        }
    }
}

// MARK: - Search Result Row
struct SearchResultRow: View {
    let track: SpotifyTrack
    @EnvironmentObject var audioPlayer: AudioPlayer
    
    var body: some View {
        HStack(spacing: 12) {
            AsyncImage(url: URL(string: track.albumArtUrl ?? "")) { image in
                image
                    .resizable()
                    .aspectRatio(contentMode: .fill)
            } placeholder: {
                Rectangle()
                    .fill(Color.pairBackgroundSecondary)
                    .overlay {
                        Image(systemName: "music.note")
                            .foregroundColor(.pairTextTertiary)
                    }
            }
            .frame(width: 56, height: 56)
            .cornerRadius(8)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(track.trackName)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(.pairTextPrimary)
                    .lineLimit(1)
                
                Text(track.artistName)
                    .font(.caption)
                    .foregroundColor(.pairTextSecondary)
                    .lineLimit(1)
            }
            
            Spacer()
            
            Image(systemName: "chevron.right")
                .font(.system(size: 14))
                .foregroundColor(.pairTextTertiary)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(Color.pairBackground)
    }
}

#Preview {
    SearchView()
        .environmentObject(AudioPlayer.shared)
}
