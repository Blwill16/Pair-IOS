import SwiftUI

struct FeedView: View {
    @EnvironmentObject var authManager: AuthManager
    
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
                    feedList
                }
            }
            .navigationTitle("Feed")
            .refreshable {
                await loadFeed()
            }
            .task {
                await loadFeed()
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
            
            Image(systemName: "house")
                .font(.system(size: 64))
                .foregroundStyle(.purple.opacity(0.6))
            
            VStack(spacing: 8) {
                Text("Your feed is empty")
                    .font(.title2)
                    .fontWeight(.semibold)
                
                Text("Follow other users to see their playlists here")
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
    
    private var feedList: some View {
        List {
            ForEach(playlists) { playlist in
                VStack(alignment: .leading, spacing: 8) {
                    if let profile = playlist.profiles {
                        HStack(spacing: 8) {
                            AsyncImage(url: URL(string: profile.avatarUrl ?? "")) { image in
                                image
                                    .resizable()
                                    .aspectRatio(contentMode: .fill)
                            } placeholder: {
                                Circle()
                                    .fill(Color.gray.opacity(0.3))
                                    .overlay {
                                        Image(systemName: "person.fill")
                                            .foregroundStyle(.gray)
                                    }
                            }
                            .frame(width: 32, height: 32)
                            .clipShape(Circle())
                            
                            VStack(alignment: .leading, spacing: 0) {
                                Text(profile.displayName ?? profile.username ?? "Unknown")
                                    .font(.subheadline)
                                    .fontWeight(.medium)
                                
                                if let createdAt = playlist.createdAt {
                                    Text(formatDate(createdAt))
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                            }
                        }
                    }
                    
                    PlaylistRowView(playlist: playlist)
                }
                .contentShape(Rectangle())
                .onTapGesture {
                    selectedPlaylist = playlist
                }
            }
        }
        .listStyle(.plain)
    }
    
    private func loadFeed() async {
        guard let userId = authManager.userId else { return }
        
        isLoading = true
        errorMessage = nil
        
        do {
            let fetchedPlaylists = try await apiService.getFeed(userId: userId)
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
    
    private func formatDate(_ dateString: String) -> String {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        
        if let date = formatter.date(from: dateString) {
            let relativeFormatter = RelativeDateTimeFormatter()
            relativeFormatter.unitsStyle = .abbreviated
            return relativeFormatter.localizedString(for: date, relativeTo: Date())
        }
        
        return dateString
    }
}

#Preview {
    FeedView()
        .environmentObject(AuthManager.shared)
        .environmentObject(AudioPlayer.shared)
}
