import SwiftUI

struct SearchView: View {
    @State private var searchText = ""
    @State private var searchResults: [SpotifyTrack] = []
    @State private var isSearching = false
    @State private var selectedTrack: SpotifyTrack?
    @State private var showPromptView = false
    @State private var errorMessage: String?
    @State private var isSearchFocused = false
    @State private var placeholderIndex = 0
    
    private let apiService = APIService.shared
    private let placeholders = ["Start with a song", "Start with an artist", "Start with a vibe"]
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color.pairBackground.ignoresSafeArea()
                
                VStack(spacing: 0) {
                    if searchResults.isEmpty && !isSearching {
                        emptyStateView
                    } else {
                        searchResultsList
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
        VStack(spacing: 32) {
            Spacer()
            
            // Gradient wash behind headline
            ZStack {
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [Color.pairPurple.opacity(0.15), Color.clear],
                            center: .center,
                            startRadius: 0,
                            endRadius: 150
                        )
                    )
                    .frame(width: 300, height: 300)
                    .blur(radius: 40)
                
                VStack(spacing: 12) {
                    Text("Start with a song")
                        .font(.system(size: 28, weight: .bold))
                        .foregroundColor(.white)
                    
                    Text("We'll find what belongs with it")
                        .font(.subheadline)
                        .foregroundColor(.pairTextSecondary)
                }
            }
            
            // Search bar
            VStack(spacing: 8) {
                HStack(spacing: 12) {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(.pairTextSecondary)
                    
                    TextField("", text: $searchText, prompt: Text(placeholders[placeholderIndex])
                        .foregroundColor(.pairTextTertiary))
                        .foregroundColor(.white)
                        .onSubmit {
                            performSearch()
                        }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 16)
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(Color.white.opacity(0.08))
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(isSearchFocused ? Color.pairPurple.opacity(0.5) : Color.white.opacity(0.1), lineWidth: 1)
                )
            }
            .padding(.horizontal, 24)
            
            // Recent and trending sections
            VStack(spacing: 24) {
                // Your recent pairings
                VStack(alignment: .leading, spacing: 12) {
                    Text("Your recent pairings")
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(.pairTextSecondary)
                    
                    Text("No recent pairings yet")
                        .font(.caption)
                        .foregroundColor(.pairTextTertiary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding()
                        .background(Color.white.opacity(0.05))
                        .cornerRadius(12)
                }
                
                // Trending seeds
                VStack(alignment: .leading, spacing: 12) {
                    HStack(spacing: 8) {
                        Text("Trending seeds")
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .foregroundColor(.pairTextSecondary)
                        
                        HStack(spacing: 4) {
                            Circle()
                                .fill(Color.pairPurple)
                                .frame(width: 6, height: 6)
                            Text("rising now")
                                .font(.caption2)
                                .foregroundColor(.pairPurple)
                        }
                    }
                    
                    Text("Search to discover trending songs")
                        .font(.caption)
                        .foregroundColor(.pairTextTertiary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding()
                        .background(Color.white.opacity(0.05))
                        .cornerRadius(12)
                }
            }
            .padding(.horizontal, 24)
            .padding(.top, 16)
            
            Spacer()
            Spacer()
        }
        .onAppear {
            startPlaceholderCycling()
        }
    }
    
    private var searchResultsList: some View {
        VStack(spacing: 0) {
            // Search bar at top
            HStack(spacing: 12) {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(.pairTextSecondary)
                
                TextField("", text: $searchText, prompt: Text("Search...")
                    .foregroundColor(.pairTextTertiary))
                    .foregroundColor(.white)
                    .onSubmit {
                        performSearch()
                    }
                
                if !searchText.isEmpty {
                    Button {
                        searchText = ""
                        searchResults = []
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.pairTextSecondary)
                    }
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
            .background(Color.white.opacity(0.08))
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
                ScrollView {
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
                }
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
                    .fill(Color.white.opacity(0.1))
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
                    .foregroundColor(.white)
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
        .background(Color.white.opacity(0.001)) // For tap area
    }
}

#Preview {
    SearchView()
        .environmentObject(AudioPlayer.shared)
}
