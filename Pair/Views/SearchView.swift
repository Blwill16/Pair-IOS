import SwiftUI
import Combine

struct SearchView: View {
    @EnvironmentObject var navigationState: NavigationState
    @EnvironmentObject var authManager: AuthManager
    
    @State private var searchText = ""
    @State private var searchResults: [SpotifyTrack] = []
    @State private var isSearching = false
    @State private var selectedTrack: SpotifyTrack?
    @State private var showPromptView = false
    @State private var errorMessage: String?
    @State private var placeholderIndex = 0
    @State private var searchTask: Task<Void, Never>?
    @State private var recentPairings: [RecentPairing] = []
    
    private let apiService = APIService.shared
    private let placeholders = ["Search a song", "Search an artist", "Type a feeling"]
    
    // 5 trending seeds - popular songs to get users started
    private let trendingSeeds: [TrendingSeed] = [
        TrendingSeed(name: "Blinding Lights", artist: "The Weeknd", imageUrl: "https://i.scdn.co/image/ab67616d0000b2738863bc11d2aa12b54f5aeb36"),
        TrendingSeed(name: "Bohemian Rhapsody", artist: "Queen", imageUrl: "https://i.scdn.co/image/ab67616d0000b273e8b066f70c206551210d902b"),
        TrendingSeed(name: "Starboy", artist: "The Weeknd", imageUrl: "https://i.scdn.co/image/ab67616d0000b2734718e2b124f79258be7bc452"),
        TrendingSeed(name: "Shape of You", artist: "Ed Sheeran", imageUrl: "https://i.scdn.co/image/ab67616d0000b273ba5db46f4b838ef6027e6f96"),
        TrendingSeed(name: "Levitating", artist: "Dua Lipa", imageUrl: "https://i.scdn.co/image/ab67616d0000b273bd26ede1ae69327010d49946")
    ]
    
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
                // Cancel any pending search
                searchTask?.cancel()
                
                if newValue.isEmpty {
                    searchResults = []
                    isSearching = false
                } else if newValue.count >= 2 {
                    // Debounce search - wait 300ms after user stops typing
                    searchTask = Task {
                        try? await Task.sleep(nanoseconds: 300_000_000) // 300ms
                        if !Task.isCancelled {
                            await MainActor.run {
                                performSearch()
                            }
                        }
                    }
                }
            }
            .navigationDestination(isPresented: $showPromptView) {
                if let track = selectedTrack {
                    SongConfirmationView(track: track)
                }
            }
        }
        .onAppear {
            // Show nav bar when returning to main tab
            navigationState.showNavBar()
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
            
            // Hero search input per Figma - elevated with shadow and border
            VStack(spacing: 0) {
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
                .padding(.horizontal, 20)
                .padding(.vertical, 16)
            }
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color.pairCardBackground)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(Color.black.opacity(0.15), lineWidth: 1.5)
            )
            .shadow(color: Color.black.opacity(0.06), radius: 12, y: 4)
            .padding(.horizontal, 24)
            .padding(.bottom, searchResults.isEmpty ? 40 : 16)
            
            // Quick select suggestions - show when user is typing
            if !searchResults.isEmpty && !searchText.isEmpty {
                VStack(spacing: 0) {
                    ForEach(searchResults.prefix(8)) { track in
                        QuickSelectRow(track: track)
                            .contentShape(Rectangle())
                            .onTapGesture {
                                selectedTrack = track
                                showPromptView = true
                            }
                        
                        if track.trackId != searchResults.prefix(8).last?.trackId {
                            Divider()
                                .padding(.leading, 76)
                        }
                    }
                }
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(Color.pairCardBackground)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(Color.black.opacity(0.08), lineWidth: 1)
                )
                .shadow(color: Color.black.opacity(0.06), radius: 12, y: 4)
                .padding(.horizontal, 24)
            }
            
            // Loading indicator
            if isSearching {
                ProgressView()
                    .tint(.pairPurple)
                    .padding(.top, 40)
            }
            
            // Trending Seeds section - only show when not searching
            if searchText.isEmpty && searchResults.isEmpty {
                VStack(alignment: .leading, spacing: 16) {
                    Text("Trending Seeds")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(.pairTextPrimary)
                        .padding(.horizontal, 24)
                    
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 12) {
                            ForEach(trendingSeeds) { seed in
                                TrendingSeedCard(seed: seed) {
                                    searchText = seed.name
                                    performSearch()
                                }
                            }
                        }
                        .padding(.horizontal, 24)
                    }
                }
                .padding(.bottom, 32)
                
                // Your Recent Pairings section - only for logged in users
                if authManager.isAuthenticated && authManager.currentUser != nil && !recentPairings.isEmpty {
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Your Recent Pairings")
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundColor(.pairTextPrimary)
                            .padding(.horizontal, 24)
                        
                        VStack(spacing: 0) {
                            ForEach(recentPairings) { pairing in
                                RecentPairingRow(pairing: pairing)
                            }
                        }
                        .padding(.horizontal, 24)
                    }
                }
            }
            
            Spacer()
        }
        .onAppear {
            startPlaceholderCycling()
            loadRecentPairings()
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
        
        // Log the search query for trending
        logSearchQuery(searchText)
        
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
    
    private func loadRecentPairings() {
        guard authManager.isAuthenticated, let userId = authManager.userId else { return }
        
        Task {
            do {
                let pairingsData = try await apiService.getRecentPairings(userId: userId)
                await MainActor.run {
                    recentPairings = pairingsData.map { data in
                        RecentPairing(
                            seedName: data.seedName,
                            seedArtist: data.seedArtist,
                            mode: data.mode,
                            date: data.formattedDate ?? Date(),
                            trackCount: data.trackCount
                        )
                    }
                }
            } catch {
                // Silently fail - recent pairings are optional
                print("Failed to load recent pairings: \(error)")
            }
        }
    }
    
    private func logSearchQuery(_ query: String) {
        Task {
            await apiService.logSearch(query: query, userId: authManager.userId)
        }
    }
}

// MARK: - Trending Seed Model
struct TrendingSeed: Identifiable {
    let id = UUID()
    let name: String
    let artist: String
    let imageUrl: String
}

// MARK: - Recent Pairing Model
struct RecentPairing: Identifiable {
    let id = UUID()
    let seedName: String
    let seedArtist: String
    let mode: String
    let date: Date
    let trackCount: Int
}

// MARK: - Trending Seed Card
struct TrendingSeedCard: View {
    let seed: TrendingSeed
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: 8) {
                AsyncImage(url: URL(string: seed.imageUrl)) { image in
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
                .frame(width: 100, height: 100)
                .cornerRadius(12)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(seed.name)
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundColor(.pairTextPrimary)
                        .lineLimit(1)
                    
                    Text(seed.artist)
                        .font(.caption2)
                        .foregroundColor(.pairTextSecondary)
                        .lineLimit(1)
                }
            }
            .frame(width: 100)
        }
    }
}

// MARK: - Recent Pairing Row
struct RecentPairingRow: View {
    let pairing: RecentPairing
    
    private var formattedDate: String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: pairing.date, relativeTo: Date())
    }
    
    var body: some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 2) {
                Text(pairing.seedName)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(.pairTextPrimary)
                
                Text("\(pairing.seedArtist) \u{00B7} \(pairing.mode)")
                    .font(.caption)
                    .foregroundColor(.pairTextSecondary)
            }
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 2) {
                Text("\(pairing.trackCount) tracks")
                    .font(.caption)
                    .foregroundColor(.pairTextSecondary)
                
                Text(formattedDate)
                    .font(.caption2)
                    .foregroundColor(.pairTextTertiary)
            }
        }
        .padding(.vertical, 12)
    }
}

// MARK: - Quick Select Row (Figma: Compact suggestion row)
struct QuickSelectRow: View {
    let track: SpotifyTrack
    
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
            .frame(width: 48, height: 48)
            .cornerRadius(8)
            
            VStack(alignment: .leading, spacing: 2) {
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
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
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
