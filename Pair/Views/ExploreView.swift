import SwiftUI

// MARK: - Curated Playlist Data
struct CuratedPlaylist: Identifiable {
    let id = UUID()
    let title: String
    let description: String
    let seedTrack: String
    let seedArtist: String
    let seedArtwork: String
    let curatorName: String
    let trackCount: Int
    let genres: [String]
    let emotions: [String]
    let tracks: [CuratedTrack]
}

struct CuratedTrack: Identifiable {
    let id = UUID()
    let name: String
    let artist: String
    let duration: String
    let artworkUrl: String
}

// MARK: - Curated Playlists with Real Songs
let curatedPlaylists = [
    CuratedPlaylist(
        title: "Late Night Drive",
        description: "Empty highways, city lights fading. That feeling when you're driving nowhere in particular.",
        seedTrack: "Nightcall",
        seedArtist: "Kavinsky",
        seedArtwork: "https://is1-ssl.mzstatic.com/image/thumb/Music125/v4/a3/a3/2a/a3a32a1c-8f8e-8e1e-8e1e-8e1e8e1e8e1e/source/400x400bb.jpg",
        curatorName: "Alex Chen",
        trackCount: 5,
        genres: ["Electronic", "Indie"],
        emotions: ["Nostalgic", "Dreamy"],
        tracks: [
            CuratedTrack(name: "Nightcall", artist: "Kavinsky", duration: "4:29", artworkUrl: "https://is1-ssl.mzstatic.com/image/thumb/Music125/v4/a3/a3/2a/a3a32a1c-8f8e-8e1e-8e1e-8e1e8e1e8e1e/source/100x100bb.jpg"),
            CuratedTrack(name: "Midnight City", artist: "M83", duration: "4:04", artworkUrl: "https://is1-ssl.mzstatic.com/image/thumb/Music115/v4/b5/b5/b5/b5b5b5b5-8e1e-8e1e-8e1e-8e1e8e1e8e1e/source/100x100bb.jpg"),
            CuratedTrack(name: "Under Cover of Darkness", artist: "The Strokes", duration: "3:59", artworkUrl: "https://is1-ssl.mzstatic.com/image/thumb/Music125/v4/c4/c4/c4/c4c4c4c4-8e1e-8e1e-8e1e-8e1e8e1e8e1e/source/100x100bb.jpg"),
            CuratedTrack(name: "Hyperballad", artist: "Bjork", duration: "5:21", artworkUrl: "https://is1-ssl.mzstatic.com/image/thumb/Music125/v4/d5/d5/d5/d5d5d5d5-8e1e-8e1e-8e1e-8e1e8e1e8e1e/source/100x100bb.jpg"),
            CuratedTrack(name: "Such Great Heights", artist: "The Postal Service", duration: "4:26", artworkUrl: "https://is1-ssl.mzstatic.com/image/thumb/Music125/v4/e6/e6/e6/e6e6e6e6-8e1e-8e1e-8e1e-8e1e8e1e8e1e/source/100x100bb.jpg")
        ]
    ),
    CuratedPlaylist(
        title: "Gentle Morning",
        description: "Sunday morning light through curtains. Coffee brewing, world still quiet.",
        seedTrack: "Holocene",
        seedArtist: "Bon Iver",
        seedArtwork: "https://is1-ssl.mzstatic.com/image/thumb/Music125/v4/f7/f7/f7/f7f7f7f7-8e1e-8e1e-8e1e-8e1e8e1e8e1e/source/400x400bb.jpg",
        curatorName: "Maya Patel",
        trackCount: 5,
        genres: ["Folk", "Indie"],
        emotions: ["Intimate", "Melancholic"],
        tracks: [
            CuratedTrack(name: "Holocene", artist: "Bon Iver", duration: "5:36", artworkUrl: "https://is1-ssl.mzstatic.com/image/thumb/Music125/v4/f7/f7/f7/f7f7f7f7-8e1e-8e1e-8e1e-8e1e8e1e8e1e/source/100x100bb.jpg"),
            CuratedTrack(name: "Skinny Love", artist: "Bon Iver", duration: "3:58", artworkUrl: "https://is1-ssl.mzstatic.com/image/thumb/Music125/v4/f7/f7/f7/f7f7f7f7-8e1e-8e1e-8e1e-8e1e8e1e8e1e/source/100x100bb.jpg"),
            CuratedTrack(name: "The Night We Met", artist: "Lord Huron", duration: "3:28", artworkUrl: "https://is1-ssl.mzstatic.com/image/thumb/Music125/v4/g8/g8/g8/g8g8g8g8-8e1e-8e1e-8e1e-8e1e8e1e8e1e/source/100x100bb.jpg"),
            CuratedTrack(name: "First Day of My Life", artist: "Bright Eyes", duration: "3:06", artworkUrl: "https://is1-ssl.mzstatic.com/image/thumb/Music125/v4/h9/h9/h9/h9h9h9h9-8e1e-8e1e-8e1e-8e1e8e1e8e1e/source/100x100bb.jpg"),
            CuratedTrack(name: "re: stacks", artist: "Bon Iver", duration: "6:41", artworkUrl: "https://is1-ssl.mzstatic.com/image/thumb/Music125/v4/f7/f7/f7/f7f7f7f7-8e1e-8e1e-8e1e-8e1e8e1e8e1e/source/100x100bb.jpg")
        ]
    ),
    CuratedPlaylist(
        title: "Velvet Grooves",
        description: "Smooth R&B for late nights. Let the rhythm carry you somewhere warm.",
        seedTrack: "Untitled (How Does It Feel)",
        seedArtist: "D'Angelo",
        seedArtwork: "https://is1-ssl.mzstatic.com/image/thumb/Music125/v4/i0/i0/i0/i0i0i0i0-8e1e-8e1e-8e1e-8e1e8e1e8e1e/source/400x400bb.jpg",
        curatorName: "Marcus Reid",
        trackCount: 5,
        genres: ["R&B", "Soul"],
        emotions: ["Intimate", "Dreamy"],
        tracks: [
            CuratedTrack(name: "Untitled (How Does It Feel)", artist: "D'Angelo", duration: "4:47", artworkUrl: "https://is1-ssl.mzstatic.com/image/thumb/Music125/v4/i0/i0/i0/i0i0i0i0-8e1e-8e1e-8e1e-8e1e8e1e8e1e/source/100x100bb.jpg"),
            CuratedTrack(name: "Electric", artist: "Alina Baraz & Khalid", duration: "4:00", artworkUrl: "https://is1-ssl.mzstatic.com/image/thumb/Music125/v4/j1/j1/j1/j1j1j1j1-8e1e-8e1e-8e1e-8e1e8e1e8e1e/source/100x100bb.jpg"),
            CuratedTrack(name: "Best Part", artist: "Daniel Caesar ft. H.E.R.", duration: "3:29", artworkUrl: "https://is1-ssl.mzstatic.com/image/thumb/Music125/v4/k2/k2/k2/k2k2k2k2-8e1e-8e1e-8e1e-8e1e8e1e8e1e/source/100x100bb.jpg"),
            CuratedTrack(name: "Adorn", artist: "Miguel", duration: "3:13", artworkUrl: "https://is1-ssl.mzstatic.com/image/thumb/Music125/v4/l3/l3/l3/l3l3l3l3-8e1e-8e1e-8e1e-8e1e8e1e8e1e/source/100x100bb.jpg"),
            CuratedTrack(name: "Prototype", artist: "OutKast", duration: "5:24", artworkUrl: "https://is1-ssl.mzstatic.com/image/thumb/Music125/v4/m4/m4/m4/m4m4m4m4-8e1e-8e1e-8e1e-8e1e8e1e8e1e/source/100x100bb.jpg")
        ]
    ),
    CuratedPlaylist(
        title: "Jazz After Dark",
        description: "Smoky rooms and dim lights. The kind of jazz that makes time slow down.",
        seedTrack: "Blue in Green",
        seedArtist: "Miles Davis",
        seedArtwork: "https://is1-ssl.mzstatic.com/image/thumb/Music125/v4/n5/n5/n5/n5n5n5n5-8e1e-8e1e-8e1e-8e1e8e1e8e1e/source/400x400bb.jpg",
        curatorName: "Jordan Park",
        trackCount: 5,
        genres: ["Jazz"],
        emotions: ["Melancholic", "Intimate"],
        tracks: [
            CuratedTrack(name: "Blue in Green", artist: "Miles Davis", duration: "5:37", artworkUrl: "https://is1-ssl.mzstatic.com/image/thumb/Music125/v4/n5/n5/n5/n5n5n5n5-8e1e-8e1e-8e1e-8e1e8e1e8e1e/source/100x100bb.jpg"),
            CuratedTrack(name: "In a Sentimental Mood", artist: "Duke Ellington & John Coltrane", duration: "4:16", artworkUrl: "https://is1-ssl.mzstatic.com/image/thumb/Music125/v4/o6/o6/o6/o6o6o6o6-8e1e-8e1e-8e1e-8e1e8e1e8e1e/source/100x100bb.jpg"),
            CuratedTrack(name: "My Favorite Things", artist: "John Coltrane", duration: "13:41", artworkUrl: "https://is1-ssl.mzstatic.com/image/thumb/Music125/v4/p7/p7/p7/p7p7p7p7-8e1e-8e1e-8e1e-8e1e8e1e8e1e/source/100x100bb.jpg"),
            CuratedTrack(name: "Round Midnight", artist: "Thelonious Monk", duration: "5:54", artworkUrl: "https://is1-ssl.mzstatic.com/image/thumb/Music125/v4/q8/q8/q8/q8q8q8q8-8e1e-8e1e-8e1e-8e1e8e1e8e1e/source/100x100bb.jpg"),
            CuratedTrack(name: "Naima", artist: "John Coltrane", duration: "4:24", artworkUrl: "https://is1-ssl.mzstatic.com/image/thumb/Music125/v4/r9/r9/r9/r9r9r9r9-8e1e-8e1e-8e1e-8e1e8e1e8e1e/source/100x100bb.jpg")
        ]
    ),
    CuratedPlaylist(
        title: "Indie Heartbreak",
        description: "Songs for staring out windows. When feelings need a soundtrack.",
        seedTrack: "Motion Picture Soundtrack",
        seedArtist: "Radiohead",
        seedArtwork: "https://is1-ssl.mzstatic.com/image/thumb/Music125/v4/s0/s0/s0/s0s0s0s0-8e1e-8e1e-8e1e-8e1e8e1e8e1e/source/400x400bb.jpg",
        curatorName: "Emma Wilson",
        trackCount: 5,
        genres: ["Indie", "Rock"],
        emotions: ["Melancholic", "Nostalgic"],
        tracks: [
            CuratedTrack(name: "Motion Picture Soundtrack", artist: "Radiohead", duration: "7:01", artworkUrl: "https://is1-ssl.mzstatic.com/image/thumb/Music125/v4/s0/s0/s0/s0s0s0s0-8e1e-8e1e-8e1e-8e1e8e1e8e1e/source/100x100bb.jpg"),
            CuratedTrack(name: "The Funeral", artist: "Band of Horses", duration: "5:23", artworkUrl: "https://is1-ssl.mzstatic.com/image/thumb/Music125/v4/t1/t1/t1/t1t1t1t1-8e1e-8e1e-8e1e-8e1e8e1e8e1e/source/100x100bb.jpg"),
            CuratedTrack(name: "Lua", artist: "Bright Eyes", duration: "4:05", artworkUrl: "https://is1-ssl.mzstatic.com/image/thumb/Music125/v4/u2/u2/u2/u2u2u2u2-8e1e-8e1e-8e1e-8e1e8e1e8e1e/source/100x100bb.jpg"),
            CuratedTrack(name: "Fake Plastic Trees", artist: "Radiohead", duration: "4:50", artworkUrl: "https://is1-ssl.mzstatic.com/image/thumb/Music125/v4/v3/v3/v3/v3v3v3v3-8e1e-8e1e-8e1e-8e1e8e1e8e1e/source/100x100bb.jpg"),
            CuratedTrack(name: "Between the Bars", artist: "Elliott Smith", duration: "2:21", artworkUrl: "https://is1-ssl.mzstatic.com/image/thumb/Music125/v4/w4/w4/w4/w4w4w4w4-8e1e-8e1e-8e1e-8e1e8e1e8e1e/source/100x100bb.jpg")
        ]
    )
]

// MARK: - Genre/Emotion Colors
let genreColors: [String: (Color, Color)] = [
    "Indie": (Color(red: 0.91, green: 0.45, blue: 0.45), Color(red: 0.95, green: 0.60, blue: 0.60)),
    "Electronic": (Color(red: 0.40, green: 0.75, blue: 0.75), Color(red: 0.50, green: 0.85, blue: 0.85)),
    "R&B": (Color(red: 0.61, green: 0.53, blue: 0.96), Color(red: 0.71, green: 0.63, blue: 1.0)),
    "Jazz": (Color(red: 0.90, green: 0.80, blue: 0.45), Color(red: 0.95, green: 0.85, blue: 0.55)),
    "Rock": (Color(red: 0.55, green: 0.80, blue: 0.70), Color(red: 0.65, green: 0.90, blue: 0.80)),
    "Hip-Hop": (Color(red: 0.95, green: 0.65, blue: 0.65), Color(red: 1.0, green: 0.75, blue: 0.75)),
    "Folk": (Color(red: 0.75, green: 0.70, blue: 0.90), Color(red: 0.85, green: 0.80, blue: 1.0)),
    "Soul": (Color(red: 0.95, green: 0.70, blue: 0.60), Color(red: 1.0, green: 0.80, blue: 0.70))
]

let emotionColors: [String: (Color, Color)] = [
    "Melancholic": (Color(red: 0.55, green: 0.55, blue: 0.75), Color(red: 0.65, green: 0.65, blue: 0.85)),
    "Energetic": (Color(red: 0.95, green: 0.55, blue: 0.45), Color(red: 1.0, green: 0.65, blue: 0.55)),
    "Dreamy": (Color(red: 0.60, green: 0.75, blue: 0.90), Color(red: 0.70, green: 0.85, blue: 1.0)),
    "Intimate": (Color(red: 0.85, green: 0.60, blue: 0.70), Color(red: 0.95, green: 0.70, blue: 0.80)),
    "Experimental": (Color(red: 0.70, green: 0.60, blue: 0.80), Color(red: 0.80, green: 0.70, blue: 0.90)),
    "Nostalgic": (Color(red: 0.80, green: 0.70, blue: 0.55), Color(red: 0.90, green: 0.80, blue: 0.65))
]

struct ExploreView: View {
    @EnvironmentObject var authManager: AuthManager
    @EnvironmentObject var navigationState: NavigationState
    
    @State private var selectedGenres: Set<String> = []
    @State private var selectedEmotions: Set<String> = []
    @State private var showFilters = false
    @State private var selectedPlaylist: CuratedPlaylist?
    
    private let genres = ["Indie", "Electronic", "R&B", "Jazz", "Rock", "Hip-Hop", "Folk", "Soul"]
    private let emotions = ["Melancholic", "Energetic", "Dreamy", "Intimate", "Experimental", "Nostalgic"]
    
    private var filteredPlaylists: [CuratedPlaylist] {
        if selectedGenres.isEmpty && selectedEmotions.isEmpty {
            return curatedPlaylists
        }
        
        return curatedPlaylists.filter { playlist in
            let matchesGenre = selectedGenres.isEmpty || !Set(playlist.genres).isDisjoint(with: selectedGenres)
            let matchesEmotion = selectedEmotions.isEmpty || !Set(playlist.emotions).isDisjoint(with: selectedEmotions)
            return matchesGenre && matchesEmotion
        }
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color.pairBackground.ignoresSafeArea()
                
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 0) {
                        // Header with filter button
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Discover")
                                    .font(.system(size: 32, weight: .bold))
                                    .foregroundColor(.pairTextPrimary)
                                
                                Text("Playlists curated by people with taste")
                                    .font(.system(size: 15))
                                    .foregroundColor(.pairTextSecondary)
                            }
                            
                            Spacer()
                            
                            // Filter button
                            Button {
                                withAnimation(.easeOut(duration: 0.2)) {
                                    showFilters.toggle()
                                }
                            } label: {
                                Image(systemName: "slider.horizontal.3")
                                    .font(.system(size: 18))
                                    .foregroundColor(showFilters ? .pairPurple : .pairTextSecondary)
                                    .padding(12)
                                    .background(
                                        RoundedRectangle(cornerRadius: 12)
                                            .stroke(showFilters ? Color.pairPurple : Color.pairCardBorder, lineWidth: 1)
                                    )
                            }
                        }
                        .padding(.horizontal, 24)
                        .padding(.top, 16)
                        .padding(.bottom, 16)
                        
                        // Filters section (collapsible)
                        if showFilters {
                            VStack(alignment: .leading, spacing: 16) {
                                // Genres
                                VStack(alignment: .leading, spacing: 10) {
                                    Text("Genres")
                                        .font(.system(size: 14, weight: .medium))
                                        .foregroundColor(.pairTextPrimary)
                                    
                                    FlowLayout(spacing: 8) {
                                        ForEach(genres, id: \.self) { genre in
                                            FilterPill(
                                                title: genre,
                                                isSelected: selectedGenres.contains(genre),
                                                colors: genreColors[genre]
                                            ) {
                                                withAnimation(.easeOut(duration: 0.2)) {
                                                    if selectedGenres.contains(genre) {
                                                        selectedGenres.remove(genre)
                                                    } else {
                                                        selectedGenres.insert(genre)
                                                    }
                                                }
                                            }
                                        }
                                    }
                                }
                                
                                // Emotions
                                VStack(alignment: .leading, spacing: 10) {
                                    Text("Emotions")
                                        .font(.system(size: 14, weight: .medium))
                                        .foregroundColor(.pairTextPrimary)
                                    
                                    FlowLayout(spacing: 8) {
                                        ForEach(emotions, id: \.self) { emotion in
                                            FilterPill(
                                                title: emotion,
                                                isSelected: selectedEmotions.contains(emotion),
                                                colors: emotionColors[emotion]
                                            ) {
                                                withAnimation(.easeOut(duration: 0.2)) {
                                                    if selectedEmotions.contains(emotion) {
                                                        selectedEmotions.remove(emotion)
                                                    } else {
                                                        selectedEmotions.insert(emotion)
                                                    }
                                                }
                                            }
                                        }
                                    }
                                }
                            }
                            .padding(.horizontal, 24)
                            .padding(.bottom, 20)
                            .transition(.opacity.combined(with: .move(edge: .top)))
                        }
                        
                        // Playlist cards
                        LazyVStack(spacing: 20) {
                            ForEach(filteredPlaylists) { playlist in
                                DiscoverHeroCard(playlist: playlist)
                                    .onTapGesture {
                                        selectedPlaylist = playlist
                                    }
                            }
                        }
                        .padding(.horizontal, 24)
                        .padding(.bottom, 120)
                    }
                    .background(
                        GeometryReader { geo in
                            Color.clear.preference(
                                key: ScrollOffsetPreferenceKey.self,
                                value: -geo.frame(in: .named("discoverScroll")).origin.y
                            )
                        }
                    )
                }
                .coordinateSpace(name: "discoverScroll")
                .onPreferenceChange(ScrollOffsetPreferenceKey.self) { offset in
                    navigationState.handleScroll(scrollY: offset)
                }
            }
            .navigationTitle("")
            .navigationBarHidden(true)
            .sheet(item: $selectedPlaylist) { playlist in
                CuratedPlaylistDetailView(playlist: playlist)
            }
        }
        .onAppear {
            navigationState.showNavBar()
            navigationState.resetScrollState()
        }
    }
}

// MARK: - Filter Pill
struct FilterPill: View {
    let title: String
    let isSelected: Bool
    let colors: (Color, Color)?
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(isSelected ? .white : .pairTextPrimary)
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
                .background(
                    Group {
                        if isSelected, let colors = colors {
                            LinearGradient(
                                colors: [colors.0, colors.1],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        } else {
                            Color.pairBackgroundSecondary
                        }
                    }
                )
                .clipShape(Capsule())
                .overlay(
                    Capsule()
                        .stroke(isSelected ? Color.clear : Color.pairCardBorder, lineWidth: 1)
                )
        }
        .buttonStyle(ScaleButtonStyle())
    }
}

// MARK: - Discover Hero Card
struct DiscoverHeroCard: View {
    let playlist: CuratedPlaylist
    @State private var isPressed = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Hero image with seed track overlay
            ZStack(alignment: .bottomLeading) {
                // Background image (using gradient as placeholder)
                LinearGradient(
                    colors: [Color.gray.opacity(0.3), Color.gray.opacity(0.5)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .frame(height: 280)
                .overlay {
                    // Placeholder pattern
                    Image(systemName: "music.note.list")
                        .font(.system(size: 60))
                        .foregroundColor(.white.opacity(0.3))
                }
                
                // Dark gradient overlay at bottom
                LinearGradient(
                    colors: [Color.clear, Color.black.opacity(0.7)],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .frame(height: 140)
                .frame(maxHeight: .infinity, alignment: .bottom)
                
                // Track count badge
                Text("\(playlist.trackCount) tracks")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.white)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(Color.black.opacity(0.5))
                    .clipShape(Capsule())
                    .padding(16)
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topTrailing)
                
                // Seed track info
                VStack(alignment: .leading, spacing: 4) {
                    Text("SEED TRACK")
                        .font(.system(size: 10, weight: .semibold))
                        .foregroundColor(.white.opacity(0.7))
                        .tracking(1)
                    
                    Text(playlist.seedTrack)
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(.white)
                    
                    Text(playlist.seedArtist)
                        .font(.system(size: 14))
                        .foregroundColor(.white.opacity(0.8))
                }
                .padding(20)
            }
            .frame(height: 280)
            .clipShape(RoundedRectangle(cornerRadius: 16))
            
            // Playlist info below image
            VStack(alignment: .leading, spacing: 12) {
                // Title
                Text(playlist.title)
                    .font(.system(size: 22, weight: .bold))
                    .foregroundColor(.pairTextPrimary)
                
                // Description
                Text(playlist.description)
                    .font(.system(size: 15))
                    .foregroundColor(.pairTextSecondary)
                    .lineLimit(2)
                
                // Genre/emotion tags
                HStack(spacing: 8) {
                    ForEach(playlist.genres, id: \.self) { genre in
                        TagPill(title: genre, colors: genreColors[genre])
                    }
                    ForEach(playlist.emotions.prefix(2), id: \.self) { emotion in
                        TagPill(title: emotion, colors: emotionColors[emotion])
                    }
                }
                
                // Curator
                Text("Curated by \(playlist.curatorName)")
                    .font(.system(size: 13))
                    .foregroundColor(.pairTextSecondary)
            }
            .padding(.top, 16)
            .padding(.bottom, 8)
        }
        .background(Color.pairCardBackground)
        .cornerRadius(20)
        .shadow(color: Color.black.opacity(0.06), radius: 16, y: 4)
        .scaleEffect(isPressed ? 0.98 : 1.0)
        .animation(.easeOut(duration: 0.2), value: isPressed)
        .onLongPressGesture(minimumDuration: .infinity, pressing: { pressing in
            isPressed = pressing
        }, perform: {})
    }
}

// MARK: - Tag Pill (for genre/emotion tags on cards)
struct TagPill: View {
    let title: String
    let colors: (Color, Color)?
    
    var body: some View {
        Text(title)
            .font(.system(size: 12, weight: .medium))
            .foregroundColor(.white)
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(
                Group {
                    if let colors = colors {
                        LinearGradient(
                            colors: [colors.0, colors.1],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    } else {
                        Color.pairPurple
                    }
                }
            )
            .clipShape(Capsule())
    }
}

// MARK: - Curated Playlist Detail View
struct CuratedPlaylistDetailView: View {
    let playlist: CuratedPlaylist
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationStack {
            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 0) {
                    // Back button
                    Button {
                        dismiss()
                    } label: {
                        HStack(spacing: 4) {
                            Image(systemName: "arrow.left")
                                .font(.system(size: 16))
                            Text("Back")
                                .font(.system(size: 16))
                        }
                        .foregroundColor(.pairTextPrimary)
                    }
                    .padding(.top, 16)
                    .padding(.bottom, 24)
                    
                    // Title
                    Text(playlist.title)
                        .font(.system(size: 32, weight: .bold))
                        .foregroundColor(.pairTextPrimary)
                        .padding(.bottom, 12)
                    
                    // Description
                    Text(playlist.description)
                        .font(.system(size: 16))
                        .foregroundColor(.pairTextSecondary)
                        .padding(.bottom, 24)
                    
                    // Seed track info
                    HStack(spacing: 12) {
                        // Seed artwork placeholder
                        RoundedRectangle(cornerRadius: 8)
                            .fill(Color.pairBackgroundSecondary)
                            .frame(width: 56, height: 56)
                            .overlay {
                                Image(systemName: "music.note")
                                    .foregroundColor(.pairTextTertiary)
                            }
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Seed")
                                .font(.system(size: 12))
                                .foregroundColor(.pairTextSecondary)
                            
                            Text(playlist.seedTrack)
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundColor(.pairTextPrimary)
                        }
                    }
                    .padding(.bottom, 20)
                    
                    Divider()
                        .padding(.bottom, 20)
                    
                    // Curator
                    Text(playlist.curatorName)
                        .font(.system(size: 15))
                        .foregroundColor(.pairTextPrimary)
                        .padding(.bottom, 24)
                    
                    // Save/Remix buttons
                    HStack(spacing: 12) {
                        Button {
                            // Save action
                        } label: {
                            HStack(spacing: 8) {
                                Image(systemName: "bookmark")
                                    .font(.system(size: 16))
                                Text("Save")
                                    .font(.system(size: 16, weight: .medium))
                            }
                            .foregroundColor(.pairTextPrimary)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background(Color.pairBackgroundSecondary)
                            .cornerRadius(12)
                        }
                        
                        Button {
                            // Remix action
                        } label: {
                            HStack(spacing: 8) {
                                Image(systemName: "shuffle")
                                    .font(.system(size: 16))
                                Text("Remix")
                                    .font(.system(size: 16, weight: .medium))
                            }
                            .foregroundColor(.pairTextPrimary)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background(Color.pairBackgroundSecondary)
                            .cornerRadius(12)
                        }
                    }
                    .padding(.bottom, 32)
                    
                    // Track count
                    Text("\(playlist.tracks.count) tracks")
                        .font(.system(size: 14))
                        .foregroundColor(.pairTextSecondary)
                        .padding(.bottom, 16)
                    
                    // Track list
                    VStack(spacing: 0) {
                        ForEach(Array(playlist.tracks.enumerated()), id: \.element.id) { index, track in
                            HStack(spacing: 16) {
                                // Track number
                                Text("\(index + 1)")
                                    .font(.system(size: 14))
                                    .foregroundColor(.pairTextTertiary)
                                    .frame(width: 20)
                                
                                // Artwork placeholder
                                RoundedRectangle(cornerRadius: 6)
                                    .fill(Color.pairBackgroundSecondary)
                                    .frame(width: 48, height: 48)
                                    .overlay {
                                        Image(systemName: "music.note")
                                            .font(.system(size: 14))
                                            .foregroundColor(.pairTextTertiary)
                                    }
                                
                                // Track info
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(track.name)
                                        .font(.system(size: 15, weight: .medium))
                                        .foregroundColor(.pairTextPrimary)
                                        .lineLimit(1)
                                    
                                    Text(track.artist)
                                        .font(.system(size: 13))
                                        .foregroundColor(.pairTextSecondary)
                                        .lineLimit(1)
                                }
                                
                                Spacer()
                                
                                // Duration
                                Text(track.duration)
                                    .font(.system(size: 14))
                                    .foregroundColor(.pairTextTertiary)
                            }
                            .padding(.vertical, 12)
                            
                            if index < playlist.tracks.count - 1 {
                                Divider()
                            }
                        }
                    }
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 40)
            }
            .background(Color.pairBackground)
            .navigationBarHidden(true)
        }
    }
}

#Preview {
    ExploreView()
        .environmentObject(AuthManager.shared)
        .environmentObject(NavigationState())
}
