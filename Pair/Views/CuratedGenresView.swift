import SwiftUI

// MARK: - Screen 9: Curated Genres (Home)
struct CuratedGenresView: View {
    @EnvironmentObject var authManager: AuthManager
    @State private var genres: [CuratedGenreData] = []
    @State private var isLoading = true
    @State private var selectedTrack: CuratedTrack?
    @State private var showNowPlaying = false
    
    var body: some View {
        ZStack {
            Color.white.ignoresSafeArea()
            
            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 0) {
                    // Header
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Week of Feb 6")
                            .font(.system(size: 14))
                            .foregroundColor(.gray)
                        
                        Text("This Week")
                            .font(.system(size: 32, weight: .bold))
                            .foregroundColor(.black)
                        
                        Text("\(totalTracks) tracks across \(genres.count) genres")
                            .font(.system(size: 14))
                            .foregroundColor(.gray)
                    }
                    .padding(.horizontal, 24)
                    .padding(.top, 24)
                    .padding(.bottom, 16)
                    
                    Divider()
                        .padding(.horizontal, 24)
                    
                    // Genre sections
                    if isLoading {
                        VStack {
                            Spacer().frame(height: 100)
                            ProgressView()
                            Spacer()
                        }
                        .frame(maxWidth: .infinity)
                    } else {
                        LazyVStack(alignment: .leading, spacing: 32) {
                            ForEach(genres) { genre in
                                GenreSection(
                                    genre: genre,
                                    onTrackTap: { track in
                                        selectedTrack = track
                                        showNowPlaying = true
                                    }
                                )
                            }
                        }
                        .padding(.top, 24)
                    }
                    
                    Spacer().frame(height: 100)
                }
            }
        }
        .onAppear {
            loadGenres()
        }
        .sheet(isPresented: $showNowPlaying) {
            if let track = selectedTrack {
                NowPlayingView(track: track, isPresented: $showNowPlaying)
            }
        }
    }
    
    private var totalTracks: Int {
        genres.reduce(0) { $0 + $1.tracks.count }
    }
    
    private func loadGenres() {
        isLoading = true
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            genres = [
                CuratedGenreData(
                    name: "Melodic Electronic",
                    descriptor: "Atmospheric - emotional - long-form",
                    tracks: [
                        CuratedTrack(title: "Cascade", artist: "Olafur Arnalds", artworkUrl: "https://picsum.photos/seed/cascade/200"),
                        CuratedTrack(title: "Echo Chambers", artist: "Nils Frahm", artworkUrl: "https://picsum.photos/seed/echo/200"),
                        CuratedTrack(title: "Weightless", artist: "Kiasmos", artworkUrl: "https://picsum.photos/seed/weightless/200"),
                        CuratedTrack(title: "Drifting", artist: "Jon Hopkins", artworkUrl: "https://picsum.photos/seed/drifting/200")
                    ]
                ),
                CuratedGenreData(
                    name: "Indie Dance",
                    descriptor: "Groove-forward - restrained",
                    tracks: [
                        CuratedTrack(title: "Midnight City", artist: "M83", artworkUrl: "https://picsum.photos/seed/midnight/200"),
                        CuratedTrack(title: "Opus", artist: "Eric Prydz", artworkUrl: "https://picsum.photos/seed/opus/200")
                    ]
                ),
                CuratedGenreData(
                    name: "Dream Pop",
                    descriptor: "Soft focus - textural",
                    tracks: [
                        CuratedTrack(title: "Space Song", artist: "Beach House", artworkUrl: "https://picsum.photos/seed/space/200"),
                        CuratedTrack(title: "Cherry", artist: "Chromatics", artworkUrl: "https://picsum.photos/seed/cherry/200"),
                        CuratedTrack(title: "Myth", artist: "Beach House", artworkUrl: "https://picsum.photos/seed/myth/200")
                    ]
                ),
                CuratedGenreData(
                    name: "Alt R&B",
                    descriptor: "Intimate - boundary-pushing",
                    tracks: [
                        CuratedTrack(title: "Thinkin Bout You", artist: "Frank Ocean", artworkUrl: "https://picsum.photos/seed/thinkin/200"),
                        CuratedTrack(title: "Blinding Lights", artist: "The Weeknd", artworkUrl: "https://picsum.photos/seed/blinding/200"),
                        CuratedTrack(title: "Pink + White", artist: "Frank Ocean", artworkUrl: "https://picsum.photos/seed/pink/200")
                    ]
                )
            ]
            isLoading = false
        }
    }
}

// MARK: - Genre Section
struct GenreSection: View {
    let genre: CuratedGenreData
    let onTrackTap: (CuratedTrack) -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Genre header
            VStack(alignment: .leading, spacing: 4) {
                Text(genre.name)
                    .font(.system(size: 20, weight: .bold))
                    .foregroundColor(.black)
                
                Text(genre.descriptor)
                    .font(.system(size: 14))
                    .foregroundColor(.gray)
            }
            .padding(.horizontal, 24)
            
            // Tracks list
            VStack(spacing: 0) {
                ForEach(genre.tracks) { track in
                    Button(action: { onTrackTap(track) }) {
                        TrackRow(track: track)
                    }
                }
            }
            .padding(.horizontal, 24)
        }
    }
}

// MARK: - Track Row
struct TrackRow: View {
    let track: CuratedTrack
    
    var body: some View {
        HStack(spacing: 16) {
            AsyncImage(url: URL(string: track.artworkUrl)) { image in
                image
                    .resizable()
                    .aspectRatio(contentMode: .fill)
            } placeholder: {
                Rectangle()
                    .fill(Color.gray.opacity(0.2))
            }
            .frame(width: 56, height: 56)
            .cornerRadius(8)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(track.title)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.black)
                
                Text(track.artist)
                    .font(.system(size: 14))
                    .foregroundColor(.gray)
            }
            
            Spacer()
        }
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.white)
        )
    }
}

// MARK: - Data Models
struct CuratedGenreData: Identifiable {
    let id = UUID()
    let name: String
    let descriptor: String
    let tracks: [CuratedTrack]
}

struct CuratedTrack: Identifiable {
    let id = UUID()
    let title: String
    let artist: String
    let artworkUrl: String
    var appleMusicId: String?
    var genreName: String?
}

// MARK: - Screen 11: Now Playing
struct NowPlayingView: View {
    let track: CuratedTrack
    @Binding var isPresented: Bool
    @State private var isSaved = false
    
    var body: some View {
        ZStack {
            Color.white.ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Close button
                HStack {
                    Spacer()
                    Button(action: { isPresented = false }) {
                        Image(systemName: "xmark")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(.black)
                            .padding(12)
                            .background(
                                Circle()
                                    .fill(Color.gray.opacity(0.1))
                            )
                    }
                }
                .padding(.horizontal, 24)
                .padding(.top, 16)
                
                Spacer()
                
                // Album artwork
                AsyncImage(url: URL(string: track.artworkUrl)) { image in
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                } placeholder: {
                    Rectangle()
                        .fill(Color.gray.opacity(0.2))
                }
                .frame(width: 280, height: 280)
                .cornerRadius(16)
                .shadow(color: .black.opacity(0.2), radius: 20, y: 10)
                
                Spacer().frame(height: 40)
                
                // Track info
                VStack(spacing: 8) {
                    Text(track.title)
                        .font(.system(size: 24, weight: .bold))
                        .foregroundColor(.black)
                    
                    Text(track.artist)
                        .font(.system(size: 16))
                        .foregroundColor(.black)
                    
                    if let genre = track.genreName {
                        Text(genre)
                            .font(.system(size: 14))
                            .foregroundColor(.gray)
                    }
                }
                
                Spacer()
                
                // Action buttons
                HStack(spacing: 32) {
                    // Skip button
                    Button(action: { isPresented = false }) {
                        Image(systemName: "forward.end")
                            .font(.system(size: 20))
                            .foregroundColor(.black)
                    }
                    
                    // Save button (heart)
                    Button(action: { isSaved.toggle() }) {
                        Image(systemName: isSaved ? "heart.fill" : "heart")
                            .font(.system(size: 24))
                            .foregroundColor(.white)
                            .padding(24)
                            .background(
                                Circle()
                                    .fill(Color.pairPurple)
                            )
                    }
                    
                    // Share button
                    Button(action: {}) {
                        Image(systemName: "square.and.arrow.up")
                            .font(.system(size: 20))
                            .foregroundColor(.black)
                    }
                }
                
                Spacer().frame(height: 60)
            }
        }
    }
}

// MARK: - Screen 12: Profile
struct NewProfileView: View {
    @EnvironmentObject var authManager: AuthManager
    @State private var showTasteAdjustment = false
    
    let genres = [
        ("Melodic Electronic", "Atmospheric - emotional - long-form"),
        ("Dream Pop", "Soft focus - textural"),
        ("Alt R&B", "Intimate - boundary-pushing")
    ]
    
    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 24) {
                // Back button
                Button(action: {}) {
                    HStack(spacing: 8) {
                        Image(systemName: "arrow.left")
                        Text("Back")
                    }
                    .font(.system(size: 16))
                    .foregroundColor(.black)
                }
                .padding(.top, 16)
                
                // Header
                VStack(alignment: .leading, spacing: 4) {
                    Text("Profile")
                        .font(.system(size: 32, weight: .bold))
                        .foregroundColor(.black)
                    
                    Text("Your taste, your history")
                        .font(.system(size: 16))
                        .foregroundColor(.gray)
                }
                
                Divider()
                
                // Taste card
                Button(action: { showTasteAdjustment = true }) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Taste")
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundColor(.black)
                        
                        Text("Gently steer Pair's decisions")
                            .font(.system(size: 14))
                            .foregroundColor(.gray)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(20)
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(Color.gray.opacity(0.2), lineWidth: 1)
                    )
                }
                
                // Current genres section
                VStack(alignment: .leading, spacing: 16) {
                    Text("CURRENT GENRES")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.gray)
                        .tracking(1)
                    
                    VStack(alignment: .leading, spacing: 0) {
                        ForEach(genres, id: \.0) { genre in
                            VStack(alignment: .leading, spacing: 4) {
                                HStack {
                                    Text(genre.0)
                                        .font(.system(size: 16, weight: .medium))
                                        .foregroundColor(.black)
                                    
                                    Circle()
                                        .fill(Color.pairPurple)
                                        .frame(width: 6, height: 6)
                                }
                                
                                Text(genre.1)
                                    .font(.system(size: 13))
                                    .foregroundColor(.gray)
                            }
                            .padding(.vertical, 12)
                        }
                        
                        Button(action: { showTasteAdjustment = true }) {
                            HStack {
                                Text("Adjust")
                                    .font(.system(size: 14))
                                    .foregroundColor(.gray)
                                Image(systemName: "arrow.right")
                                    .font(.system(size: 12))
                                    .foregroundColor(.gray)
                            }
                        }
                        .padding(.top, 8)
                    }
                    .padding(20)
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(Color.gray.opacity(0.2), lineWidth: 1)
                    )
                }
                
                // Library section
                VStack(alignment: .leading, spacing: 16) {
                    Text("LIBRARY")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.gray)
                        .tracking(1)
                    
                    HStack(alignment: .top) {
                        Rectangle()
                            .fill(Color.pairPurple.opacity(0.3))
                            .frame(width: 4)
                            .cornerRadius(2)
                        
                        VStack(alignment: .leading, spacing: 4) {
                            HStack(alignment: .firstTextBaseline, spacing: 8) {
                                Text("47")
                                    .font(.system(size: 32, weight: .bold))
                                    .foregroundColor(.black)
                                
                                Text("tracks saved")
                                    .font(.system(size: 16))
                                    .foregroundColor(.gray)
                            }
                            
                            Text("Since Feb 2026")
                                .font(.system(size: 14))
                                .foregroundColor(.gray.opacity(0.6))
                        }
                    }
                    .padding(20)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(Color.gray.opacity(0.2), lineWidth: 1)
                    )
                }
                
                Spacer().frame(height: 100)
            }
            .padding(.horizontal, 24)
        }
        .sheet(isPresented: $showTasteAdjustment) {
            TasteAdjustmentSheet()
        }
    }
}

struct TasteAdjustmentSheet: View {
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        NavigationView {
            Text("Taste Adjustment")
                .navigationTitle("Adjust Taste")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button("Done") { dismiss() }
                    }
                }
        }
    }
}

// MARK: - Bottom Navigation (Old)
struct BottomNavigation: View {
    @Binding var selectedTab: Int
    
    var body: some View {
        HStack {
            // Curated tab
            Button(action: { selectedTab = 0 }) {
                Text("Curated")
                    .font(.system(size: 14, weight: selectedTab == 0 ? .semibold : .regular))
                    .foregroundColor(selectedTab == 0 ? .pairPurple : .gray)
            }
            .frame(maxWidth: .infinity)
            
            // Center waveform (Now Playing)
            Button(action: { selectedTab = 1 }) {
                Image(systemName: "waveform")
                    .font(.system(size: 20))
                    .foregroundColor(selectedTab == 1 ? .pairPurple : .gray)
            }
            .frame(maxWidth: .infinity)
            
            // Profile tab
            Button(action: { selectedTab = 2 }) {
                Image(systemName: "person")
                    .font(.system(size: 18))
                    .foregroundColor(selectedTab == 2 ? .pairPurple : .gray)
            }
            .frame(maxWidth: .infinity)
        }
        .padding(.vertical, 16)
        .background(
            Rectangle()
                .fill(Color.white)
                .shadow(color: .black.opacity(0.05), radius: 10, y: -5)
        )
    }
}

// MARK: - New Bottom Navigation (Figma Design)
struct NewBottomNavigation: View {
    @Binding var selectedTab: Int
    
    var body: some View {
        HStack {
            // Curated tab (left)
            Button(action: { selectedTab = 0 }) {
                Text("Curated")
                    .font(.system(size: 14, weight: selectedTab == 0 ? .semibold : .regular))
                    .foregroundColor(selectedTab == 0 ? .pairPurple : .gray)
            }
            .frame(maxWidth: .infinity)
            
            // Center waveform icon (Pair/Now Playing)
            Button(action: { selectedTab = 1 }) {
                Image(systemName: "waveform")
                    .font(.system(size: 22))
                    .foregroundColor(selectedTab == 1 ? .pairPurple : .gray)
            }
            .frame(maxWidth: .infinity)
            
            // Profile tab (right)
            Button(action: { selectedTab = 2 }) {
                Image(systemName: "person")
                    .font(.system(size: 20))
                    .foregroundColor(selectedTab == 2 ? .pairPurple : .gray)
            }
            .frame(maxWidth: .infinity)
        }
        .padding(.vertical, 16)
        .padding(.bottom, 20)
        .background(
            Rectangle()
                .fill(Color.white)
                .shadow(color: .black.opacity(0.08), radius: 12, y: -4)
        )
    }
}

// MARK: - Main App Container
struct MainAppContainer: View {
    @State private var selectedTab = 0
    
    var body: some View {
        ZStack(alignment: .bottom) {
            TabView(selection: $selectedTab) {
                CuratedGenresView()
                    .tag(0)
                
                Text("Now Playing")
                    .tag(1)
                
                NewProfileView()
                    .tag(2)
            }
            .tabViewStyle(.page(indexDisplayMode: .never))
            
            BottomNavigation(selectedTab: $selectedTab)
        }
    }
}

// MARK: - Preview
struct CuratedGenresView_Previews: PreviewProvider {
    static var previews: some View {
        MainAppContainer()
    }
}
