import SwiftUI

struct WeeklyDropView: View {
    @EnvironmentObject var authManager: AuthManager
    @EnvironmentObject var navigationState: NavigationState
    @StateObject private var audioPlayer = AudioPlayer.shared
    
    @State private var weeklyDrop: WeeklyDropResponse?
    @State private var isLoading = true
    @State private var errorMessage: String?
    @State private var selectedGenre: WeeklyDropGenre?
    @State private var scrollOffset: CGFloat = 0
    
    var body: some View {
        ZStack {
            Color.pairBackground.ignoresSafeArea()
            
            if isLoading {
                loadingView
            } else if let error = errorMessage {
                errorView(error)
            } else if let drop = weeklyDrop, let genres = drop.genres, !genres.isEmpty {
                dropContentView(genres: genres)
            } else {
                emptyStateView
            }
        }
        .task {
            await loadWeeklyDrop()
        }
        .sheet(item: $selectedGenre) { genre in
            GenreDetailView(genre: genre)
                .environmentObject(authManager)
        }
    }
    
    private var loadingView: some View {
        VStack(spacing: 20) {
            ProgressView()
                .scaleEffect(1.2)
                .tint(.pairPurple)
            
            Text("Loading your weekly drop...")
                .font(.system(size: 16))
                .foregroundColor(.secondary)
        }
    }
    
    private func errorView(_ error: String) -> some View {
        VStack(spacing: 20) {
            Image(systemName: "exclamationmark.triangle")
                .font(.system(size: 48))
                .foregroundColor(.orange)
            
            Text("Something went wrong")
                .font(.system(size: 20, weight: .semibold))
            
            Text(error)
                .font(.system(size: 14))
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
            
            Button {
                Task { await loadWeeklyDrop() }
            } label: {
                Text("Try Again")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.white)
                    .padding(.horizontal, 32)
                    .padding(.vertical, 12)
                    .background(Color.pairPurple)
                    .cornerRadius(12)
            }
        }
    }
    
    private var emptyStateView: some View {
        VStack(spacing: 24) {
            Image(systemName: "music.note.list")
                .font(.system(size: 64))
                .foregroundColor(.pairPurple.opacity(0.6))
            
            VStack(spacing: 8) {
                Text("Your First Drop is Coming")
                    .font(.system(size: 24, weight: .bold))
                
                Text("Pair is learning your taste.\nCheck back Friday for your first weekly drop.")
                    .font(.system(size: 16))
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
            
            Button {
                Task { await generateDrop() }
            } label: {
                HStack(spacing: 8) {
                    Image(systemName: "sparkles")
                    Text("Generate Now")
                }
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(.white)
                .padding(.horizontal, 32)
                .padding(.vertical, 14)
                .background(Color.pairPurple)
                .cornerRadius(14)
            }
        }
        .padding(.horizontal, 32)
    }
    
    private func dropContentView(genres: [WeeklyDropGenre]) -> some View {
        ScrollView {
            LazyVStack(spacing: 0) {
                headerView
                    .padding(.top, 16)
                
                ForEach(genres) { genre in
                    GenreRowView(genre: genre) {
                        selectedGenre = genre
                    }
                    .padding(.horizontal, 20)
                    .padding(.vertical, 8)
                }
                
                Spacer(minLength: 120)
            }
            .background(
                GeometryReader { geo in
                    Color.clear.preference(
                        key: ScrollOffsetPreferenceKey.self,
                        value: geo.frame(in: .named("scroll")).minY
                    )
                }
            )
        }
        .coordinateSpace(name: "scroll")
        .onPreferenceChange(ScrollOffsetPreferenceKey.self) { value in
            navigationState.handleScroll(scrollY: -value)
        }
    }
    
    private var headerView: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("This Week")
                    .font(.system(size: 32, weight: .bold))
                
                Spacer()
                
                if let drop = weeklyDrop, let total = drop.totalTracks {
                    Text("\(total) tracks")
                        .font(.system(size: 14))
                        .foregroundColor(.secondary)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(Color.gray.opacity(0.1))
                        .cornerRadius(12)
                }
            }
            
            if let drop = weeklyDrop, let weekDate = drop.weekStartDate {
                Text("Week of \(formatWeekDate(weekDate))")
                    .font(.system(size: 14))
                    .foregroundColor(.secondary)
            }
        }
        .padding(.horizontal, 20)
        .padding(.bottom, 16)
    }
    
    private func formatWeekDate(_ dateString: String) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        guard let date = formatter.date(from: dateString) else { return dateString }
        
        formatter.dateFormat = "MMMM d"
        return formatter.string(from: date)
    }
    
    private func loadWeeklyDrop() async {
        guard let userId = authManager.userId else {
            errorMessage = "Please sign in to see your weekly drop"
            isLoading = false
            return
        }
        
        isLoading = true
        errorMessage = nil
        
        do {
            weeklyDrop = try await APIService.shared.getWeeklyDrop(userId: userId)
            isLoading = false
        } catch {
            errorMessage = "Failed to load weekly drop"
            isLoading = false
        }
    }
    
    private func generateDrop() async {
        guard let userId = authManager.userId else { return }
        
        isLoading = true
        
        do {
            weeklyDrop = try await APIService.shared.generateWeeklyDrop(userId: userId)
            isLoading = false
        } catch {
            errorMessage = "Failed to generate drop"
            isLoading = false
        }
    }
}

struct GenreRowView: View {
    let genre: WeeklyDropGenre
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(genre.displayName)
                            .font(.system(size: 20, weight: .semibold))
                            .foregroundColor(.primary)
                        
                        if let descriptor = genre.descriptor {
                            Text(descriptor)
                                .font(.system(size: 14))
                                .foregroundColor(.secondary)
                        }
                    }
                    
                    Spacer()
                    
                    HStack(spacing: 4) {
                        Text("\(genre.trackCount)")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(.pairPurple)
                        
                        Image(systemName: "chevron.right")
                            .font(.system(size: 14))
                            .foregroundColor(.secondary)
                    }
                }
                
                if !genre.tracks.isEmpty {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 12) {
                            ForEach(genre.tracks.prefix(5)) { track in
                                TrackThumbnailView(track: track)
                            }
                        }
                    }
                }
            }
            .padding(16)
            .background(Color.white)
            .cornerRadius(16)
            .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 2)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct TrackThumbnailView: View {
    let track: WeeklyDropTrack
    
    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            AsyncImage(url: URL(string: track.albumArtUrl ?? "")) { image in
                image
                    .resizable()
                    .aspectRatio(contentMode: .fill)
            } placeholder: {
                Rectangle()
                    .fill(Color.gray.opacity(0.2))
            }
            .frame(width: 80, height: 80)
            .cornerRadius(8)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(track.trackName ?? "Unknown")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.primary)
                    .lineLimit(1)
                
                Text(track.artistName ?? "Unknown")
                    .font(.system(size: 11))
                    .foregroundColor(.secondary)
                    .lineLimit(1)
            }
            .frame(width: 80, alignment: .leading)
        }
    }
}

#Preview {
    WeeklyDropView()
        .environmentObject(AuthManager())
        .environmentObject(NavigationState())
}
