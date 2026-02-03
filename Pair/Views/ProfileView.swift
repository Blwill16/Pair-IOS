import SwiftUI

// MARK: - Mock Profile Data for Design
struct MockProfilePlaylist: Identifiable {
    let id = UUID()
    let title: String
    let description: String
    let seedTrack: String
    let seedArtist: String
    let imageUrl: String
    let trackCount: Int
}

let mockProfilePlaylists = [
    MockProfilePlaylist(
        title: "Late Night Drive",
        description: "Empty highways, city lights fading. That feeling when you're driving nowhere in particular.",
        seedTrack: "Midnight City",
        seedArtist: "M83",
        imageUrl: "https://images.unsplash.com/photo-1493225457124-a3eb161ffa5f?w=200",
        trackCount: 18
    ),
    MockProfilePlaylist(
        title: "Sunday Morning",
        description: "Coffee brewing. Light through curtains. The world hasn't woken up yet.",
        seedTrack: "Holocene",
        seedArtist: "Bon Iver",
        imageUrl: "https://images.unsplash.com/photo-1459749411175-04bf5292ceea?w=200",
        trackCount: 14
    ),
    MockProfilePlaylist(
        title: "Rainy Afternoon",
        description: "Windows fogged. The kind of rain that makes you want to stay inside all day.",
        seedTrack: "Breathe",
        seedArtist: "Telepopmusik",
        imageUrl: "https://images.unsplash.com/photo-1470225620780-dba8ba36b745?w=200",
        trackCount: 20
    )
]

struct ProfileView: View {
    let userId: String?
    
    @EnvironmentObject var authManager: AuthManager
    @EnvironmentObject var audioPlayer: AudioPlayer
    
    @State private var profile: Profile?
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var isFollowing = false
    @State private var selectedPlaylist: Playlist?
    @State private var showEditProfile = false
    
    private let apiService = APIService.shared
    
    private var isOwnProfile: Bool {
        userId == authManager.userId
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color.pairBackground.ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 0) {
                        // Header with back and settings
                        HStack {
                            Button {
                                // Back action - handled by navigation
                            } label: {
                                HStack(spacing: 4) {
                                    Image(systemName: "arrow.left")
                                        .font(.system(size: 16))
                                    Text("Back")
                                        .font(.subheadline)
                                }
                                .foregroundColor(.pairTextSecondary)
                            }
                            
                            Spacer()
                            
                            if isOwnProfile {
                                Menu {
                                    Button {
                                        showEditProfile = true
                                    } label: {
                                        Label("Edit Profile", systemImage: "pencil")
                                    }
                                    
                                    Button(role: .destructive) {
                                        authManager.signOut()
                                    } label: {
                                        Label("Sign Out", systemImage: "rectangle.portrait.and.arrow.right")
                                    }
                                } label: {
                                    Image(systemName: "gearshape")
                                        .font(.system(size: 20))
                                        .foregroundColor(.pairTextSecondary)
                                }
                            }
                        }
                        .padding(.horizontal, 24)
                        .padding(.top, 60)
                        .padding(.bottom, 24)
                        
                        // Profile avatar and info
                        VStack(spacing: 12) {
                            // Avatar placeholder
                            Circle()
                                .stroke(Color.pairCardBorder, lineWidth: 1)
                                .frame(width: 80, height: 80)
                                .overlay {
                                    Image(systemName: "person")
                                        .font(.system(size: 32))
                                        .foregroundColor(.pairTextTertiary)
                                }
                            
                            // Name
                            Text("Jordan Moss")
                                .font(.system(size: 28, weight: .bold))
                                .foregroundColor(.pairTextPrimary)
                            
                            // Pairing count
                            Text("12 pairings")
                                .font(.subheadline)
                                .foregroundColor(.pairTextSecondary)
                            
                            // Bio
                            Text("Music for late drives and early mornings")
                                .font(.body)
                                .foregroundColor(.pairTextSecondary)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal, 40)
                        }
                        .padding(.bottom, 32)
                        
                        // Published Pairings section
                        VStack(alignment: .leading, spacing: 16) {
                            Text("Published Pairings")
                                .font(.headline)
                                .foregroundColor(.pairTextPrimary)
                                .padding(.horizontal, 24)
                            
                            LazyVStack(spacing: 16) {
                                ForEach(mockProfilePlaylists) { playlist in
                                    ProfilePlaylistCard(playlist: playlist)
                                }
                                
                                // Also show real playlists if any
                                if let realProfile = profile, let playlists = realProfile.playlists {
                                    ForEach(playlists) { playlist in
                                        ProfilePlaylistRow(playlist: playlist)
                                            .contentShape(Rectangle())
                                            .onTapGesture {
                                                selectedPlaylist = playlist
                                            }
                                    }
                                }
                            }
                            .padding(.horizontal, 24)
                        }
                        .padding(.bottom, 120)
                    }
                }
                
                if isLoading && profile == nil {
                    ProgressView()
                        .tint(.pairPurple)
                }
            }
            .navigationTitle("")
            .navigationBarHidden(true)
            .task {
                await loadProfile()
            }
            .refreshable {
                await loadProfile()
            }
            .navigationDestination(item: $selectedPlaylist) { playlist in
                PlaylistDetailView(playlistId: playlist.id)
            }
            .sheet(isPresented: $showEditProfile) {
                EditProfileSheet(profile: profile) {
                    Task { await loadProfile() }
                }
            }
        }
    }
    
    private func loadProfile() async {
        guard let userId = userId else { return }
        
        isLoading = true
        errorMessage = nil
        
        do {
            let fetchedProfile = try await apiService.getProfile(userId: userId)
            await MainActor.run {
                profile = fetchedProfile
                isLoading = false
            }
        } catch {
            await MainActor.run {
                errorMessage = error.localizedDescription
                isLoading = false
            }
        }
    }
    
    private func toggleFollow() {
        guard let currentUserId = authManager.userId,
              let targetUserId = userId else { return }
        
        let action = isFollowing ? "unfollow" : "follow"
        
        Task {
            do {
                try await apiService.follow(
                    followerId: currentUserId,
                    followeeId: targetUserId,
                    action: action
                )
                await MainActor.run {
                    isFollowing.toggle()
                }
            } catch {
                print("Failed to \(action): \(error)")
            }
        }
    }
}

struct EditProfileSheet: View {
    let profile: Profile?
    let onSave: () -> Void
    
    @Environment(\.dismiss) private var dismiss
    
    @State private var username = ""
    @State private var displayName = ""
    @State private var bio = ""
    @State private var isSaving = false
    @State private var errorMessage: String?
    
    var body: some View {
        NavigationStack {
            Form {
                Section("Username") {
                    TextField("Username", text: $username)
                        .autocapitalization(.none)
                }
                
                Section("Display Name") {
                    TextField("Display Name", text: $displayName)
                }
                
                Section("Bio") {
                    TextField("Bio", text: $bio, axis: .vertical)
                        .lineLimit(3...6)
                }
                
                if let error = errorMessage {
                    Section {
                        Text(error)
                            .foregroundStyle(.red)
                    }
                }
            }
            .navigationTitle("Edit Profile")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    Button {
                        saveProfile()
                    } label: {
                        if isSaving {
                            ProgressView()
                        } else {
                            Text("Save")
                        }
                    }
                    .disabled(username.isEmpty || isSaving)
                }
            }
            .onAppear {
                if let profile = profile {
                    username = profile.username
                    displayName = profile.displayName ?? ""
                    bio = profile.bio ?? ""
                }
            }
        }
    }
    
    private func saveProfile() {
        isSaving = true
        errorMessage = nil
        
        Task {
            do {
                guard let userId = profile?.userId else { return }
                
                guard let url = URL(string: "\(ProcessInfo.processInfo.environment["PAIR_API_BASE_URL"] ?? "http://localhost:3000")/api/profiles") else {
                    throw APIError.invalidURL
                }
                
                var request = URLRequest(url: url)
                request.httpMethod = "POST"
                request.setValue("application/json", forHTTPHeaderField: "Content-Type")
                
                let body: [String: Any] = [
                    "userId": userId,
                    "username": username,
                    "displayName": displayName,
                    "bio": bio
                ]
                
                request.httpBody = try JSONSerialization.data(withJSONObject: body)
                
                let (_, response) = try await URLSession.shared.data(for: request)
                
                guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
                    throw APIError.requestFailed
                }
                
                await MainActor.run {
                    isSaving = false
                    onSave()
                    dismiss()
                }
            } catch {
                await MainActor.run {
                    errorMessage = error.localizedDescription
                    isSaving = false
                }
            }
        }
    }
}

// MARK: - Profile Playlist Card (for mock data)
struct ProfilePlaylistCard: View {
    let playlist: MockProfilePlaylist
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Title
            Text(playlist.title)
                .font(.title3)
                .fontWeight(.semibold)
                .foregroundColor(.pairTextPrimary)
            
            // Description
            Text(playlist.description)
                .font(.subheadline)
                .foregroundColor(.pairTextSecondary)
                .lineLimit(2)
            
            // Seed track info
            HStack(spacing: 10) {
                AsyncImage(url: URL(string: playlist.imageUrl)) { image in
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
                .frame(width: 40, height: 40)
                .cornerRadius(6)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text("Seed")
                        .font(.caption2)
                        .foregroundColor(.pairTextTertiary)
                    
                    Text(playlist.seedTrack)
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundColor(.pairTextPrimary)
                        .lineLimit(1)
                }
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.pairCardBackground)
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.05), radius: 8, y: 2)
    }
}

// MARK: - Profile Playlist Row (for real playlists)
struct ProfilePlaylistRow: View {
    let playlist: Playlist
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(playlist.title)
                .font(.headline)
                .foregroundColor(.pairTextPrimary)
            
            if let seedTrackName = playlist.seedTrackName {
                HStack(spacing: 8) {
                    RoundedRectangle(cornerRadius: 6)
                        .fill(Color.pairBackgroundSecondary)
                        .frame(width: 40, height: 40)
                        .overlay {
                            Image(systemName: "music.note")
                                .foregroundColor(.pairTextTertiary)
                                .font(.system(size: 14))
                        }
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Seed")
                            .font(.caption2)
                            .foregroundColor(.pairTextTertiary)
                        
                        Text(seedTrackName)
                            .font(.caption)
                            .fontWeight(.medium)
                            .foregroundColor(.pairTextPrimary)
                            .lineLimit(1)
                    }
                }
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.pairCardBackground)
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.05), radius: 8, y: 2)
    }
}

#Preview {
    ProfileView(userId: "test-user-id")
        .environmentObject(AuthManager.shared)
        .environmentObject(AudioPlayer.shared)
}
