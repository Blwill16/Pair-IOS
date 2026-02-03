import SwiftUI

// MARK: - Mock Data for Design
struct MockSong: Identifiable {
    let id = UUID()
    let name: String
    let artist: String
    let imageUrl: String
}

let mockRecentPairings = [
    MockSong(name: "Midnight City", artist: "M83", imageUrl: "https://images.unsplash.com/photo-1493225457124-a3eb161ffa5f?w=200"),
    MockSong(name: "Holocene", artist: "Bon Iver", imageUrl: "https://images.unsplash.com/photo-1459749411175-04bf5292ceea?w=200"),
    MockSong(name: "Nightcall", artist: "Kavinsky", imageUrl: "https://images.unsplash.com/photo-1470225620780-dba8ba36b745?w=200")
]

let mockTrendingSeeds = [
    MockSong(name: "Intro", artist: "The xx", imageUrl: "https://images.unsplash.com/photo-1470225620780-dba8ba36b745?w=200"),
    MockSong(name: "Teardrop", artist: "Massive Attack", imageUrl: "https://images.unsplash.com/photo-1511671782779-c97d3d27a1d4?w=200"),
    MockSong(name: "Skinny Love", artist: "Bon Iver", imageUrl: "https://images.unsplash.com/photo-1514525253161-7a46d19cd819?w=200"),
    MockSong(name: "Breathe", artist: "Télépopmusik", imageUrl: "https://images.unsplash.com/photo-1508700115892-45ecd05ae2ad?w=200")
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
                    SongConfirmationView(track: track)
                }
            }
        }
    }
    
    private var emptyStateView: some View {
        VStack(spacing: 0) {
            // Header section per Figma
            VStack(spacing: 8) {
                Text("Start with a song")
                    .font(.system(size: 28, weight: .bold))
                    .foregroundColor(.pairTextPrimary)
                
                Text("We'll find what belongs with it")
                    .font(.subheadline)
                    .foregroundColor(.pairTextSecondary)
            }
            .padding(.top, 60)
            .padding(.bottom, 32)
            
            // Hero search input per Figma - elevated with shadow
            HStack(spacing: 12) {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(.pairTextTertiary)
                    .font(.system(size: 20))
                
                TextField("", text: $searchText, prompt: Text(placeholders[placeholderIndex])
                    .foregroundColor(.pairTextTertiary))
                    .foregroundColor(.pairTextPrimary)
                    .font(.body)
                    .onSubmit {
                        performSearch()
                    }
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 16)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color.pairCardBackground)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(Color.pairCardBorder, lineWidth: 1)
            )
            .shadow(color: Color.black.opacity(0.06), radius: 12, y: 4)
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
                                    trackId: song.id.uuidString,
                                    trackName: song.name,
                                    artistName: song.artist,
                                    albumArtUrl: song.imageUrl,
                                    previewUrl: nil,
                                    spotifyUrl: ""
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
                                trackId: song.id.uuidString,
                                trackName: song.name,
                                artistName: song.artist,
                                albumArtUrl: song.imageUrl,
                                previewUrl: nil,
                                spotifyUrl: ""
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
                        trackId: randomSong.id.uuidString,
                        trackName: randomSong.name,
                        artistName: randomSong.artist,
                        albumArtUrl: randomSong.imageUrl,
                        previewUrl: nil,
                        spotifyUrl: ""
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

// MARK: - Recent Song Card (Figma: Song card with mood color overlay)
struct RecentSongCard: View {
    let song: MockSong
    let action: () -> Void
    @State private var isPressed = false
    
    // Get mood color based on song name
    private var moodColor: Color {
        MoodColorHelper.getMoodColor(for: song.name, artist: song.artist)
    }
    
    var body: some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: 10) {
                // Album art with subtle mood color overlay
                ZStack(alignment: .bottomLeading) {
                    AsyncImage(url: URL(string: song.imageUrl)) { image in
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                    } placeholder: {
                        Rectangle()
                            .fill(Color.pairBackgroundSecondary)
                            .overlay {
                                Image(systemName: "music.note")
                                    .font(.system(size: 24))
                                    .foregroundColor(.pairTextTertiary)
                            }
                    }
                    .frame(width: 140, height: 140)
                    .cornerRadius(12)
                    
                    // Subtle mood color gradient overlay
                    LinearGradient(
                        colors: [Color.clear, moodColor.opacity(0.3)],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                    .cornerRadius(12)
                }
                .shadow(color: moodColor.opacity(0.15), radius: 8, y: 4)
                
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
            .frame(width: 140)
        }
        .scaleEffect(isPressed ? 0.97 : 1.0)
        .animation(.easeOut(duration: 0.15), value: isPressed)
        .onLongPressGesture(minimumDuration: .infinity, pressing: { pressing in
            isPressed = pressing
        }, perform: {})
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
