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
    @EnvironmentObject var navigationState: NavigationState
    
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
                            // Avatar - 96px circle per Figma
                            Circle()
                                .stroke(Color.pairCardBorder, lineWidth: 2)
                                .frame(width: 96, height: 96)
                                .overlay {
                                    Image(systemName: "person.fill")
                                        .font(.system(size: 40))
                                        .foregroundColor(.pairTextTertiary)
                                }
                                .shadow(color: Color.black.opacity(0.05), radius: 8, y: 2)
                            
                            // Name
                            Text("Jordan Moss")
                                .font(.system(size: 28, weight: .bold))
                                .foregroundColor(.pairTextPrimary)
                            
                            // Bio - italic per Figma
                            Text("Curator of late-night drives and rainy day moods")
                                .font(.body)
                                .italic()
                                .foregroundColor(.pairTextSecondary)
                                .multilineTextAlignment(.center)
                                .frame(maxWidth: 320)
                        }
                        .padding(.bottom, 16)
                        
                        // Stats row per Figma
                        HStack(spacing: 0) {
                            Spacer()
                            
                            // Pairings stat
                            VStack(spacing: 4) {
                                Text("24")
                                    .font(.system(size: 24, weight: .bold))
                                    .foregroundColor(.pairTextPrimary)
                                Text("Pairings")
                                    .font(.caption)
                                    .foregroundColor(.pairTextSecondary)
                            }
                            
                            Spacer()
                            
                            // Divider
                            Rectangle()
                                .fill(Color.pairCardBorder)
                                .frame(width: 1, height: 40)
                            
                            Spacer()
                            
                            // Followers stat
                            VStack(spacing: 4) {
                                Text("156")
                                    .font(.system(size: 24, weight: .bold))
                                    .foregroundColor(.pairTextPrimary)
                                Text("Followers")
                                    .font(.caption)
                                    .foregroundColor(.pairTextSecondary)
                            }
                            
                            Spacer()
                            
                            // Divider
                            Rectangle()
                                .fill(Color.pairCardBorder)
                                .frame(width: 1, height: 40)
                            
                            Spacer()
                            
                            // Following stat
                            VStack(spacing: 4) {
                                Text("89")
                                    .font(.system(size: 24, weight: .bold))
                                    .foregroundColor(.pairTextPrimary)
                                Text("Following")
                                    .font(.caption)
                                    .foregroundColor(.pairTextSecondary)
                            }
                            
                            Spacer()
                        }
                        .padding(.vertical, 24)
                        .overlay(
                            VStack {
                                Divider()
                                Spacer()
                                Divider()
                            }
                        )
                        .padding(.bottom, 24)
                        
                        // Published Pairings section - 2 column grid per Figma
                        VStack(alignment: .leading, spacing: 16) {
                            Text("Pairings")
                                .font(.subheadline)
                                .foregroundColor(.pairTextSecondary)
                                .padding(.horizontal, 24)
                            
                            // 2-column grid per Figma
                            LazyVGrid(columns: [
                                GridItem(.flexible(), spacing: 12),
                                GridItem(.flexible(), spacing: 12)
                            ], spacing: 12) {
                                ForEach(mockProfilePlaylists) { playlist in
                                    ProfilePlaylistGridCard(playlist: playlist)
                                }
                                
                                // Also show real playlists if any
                                if let realProfile = profile, let playlists = realProfile.playlists {
                                    ForEach(playlists) { playlist in
                                        ProfilePlaylistGridCardReal(playlist: playlist)
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
        .onAppear {
            // Nav bar always visible on main tabs for now
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

// MARK: - Profile Playlist Grid Card (compact square card per Figma)
struct ProfilePlaylistGridCard: View {
    let playlist: MockProfilePlaylist
    @State private var isPressed = false
    
    var body: some View {
        ZStack(alignment: .bottomLeading) {
            // Cover image - full bleed
            AsyncImage(url: URL(string: playlist.imageUrl)) { image in
                image
                    .resizable()
                    .aspectRatio(contentMode: .fill)
            } placeholder: {
                Rectangle()
                    .fill(Color.pairBackgroundSecondary)
                    .overlay {
                        Image(systemName: "music.note")
                            .font(.system(size: 32))
                            .foregroundColor(.pairTextTertiary)
                    }
            }
            .frame(minWidth: 0, maxWidth: .infinity)
            .aspectRatio(1, contentMode: .fill)
            .clipped()
            
            // Gradient overlay for text readability
            LinearGradient(
                colors: [Color.clear, Color.black.opacity(0.7)],
                startPoint: .center,
                endPoint: .bottom
            )
            
            // Text overlay
            VStack(alignment: .leading, spacing: 4) {
                Text(playlist.title)
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundColor(.white)
                    .lineLimit(1)
                
                Text("\(playlist.trackCount) tracks")
                    .font(.caption2)
                    .foregroundColor(.white.opacity(0.8))
            }
            .padding(12)
        }
        .aspectRatio(1, contentMode: .fit)
        .cornerRadius(12)
        .scaleEffect(isPressed ? 1.03 : 1.0)
        .animation(.easeOut(duration: 0.2), value: isPressed)
        .onLongPressGesture(minimumDuration: .infinity, pressing: { pressing in
            isPressed = pressing
        }, perform: {})
    }
}

// MARK: - Profile Playlist Grid Card for Real Data
struct ProfilePlaylistGridCardReal: View {
    let playlist: Playlist
    @State private var isPressed = false
    
    var body: some View {
        ZStack(alignment: .bottomLeading) {
            // Placeholder cover
            Rectangle()
                .fill(Color.pairBackgroundSecondary)
                .overlay {
                    Image(systemName: "music.note.list")
                        .font(.system(size: 32))
                        .foregroundColor(.pairTextTertiary)
                }
            
            // Gradient overlay
            LinearGradient(
                colors: [Color.clear, Color.black.opacity(0.7)],
                startPoint: .center,
                endPoint: .bottom
            )
            
            // Text overlay
            VStack(alignment: .leading, spacing: 4) {
                Text(playlist.title)
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundColor(.white)
                    .lineLimit(1)
                
                Text("\(playlist.tracks?.count ?? 0) tracks")
                    .font(.caption2)
                    .foregroundColor(.white.opacity(0.8))
            }
            .padding(12)
        }
        .aspectRatio(1, contentMode: .fit)
        .cornerRadius(12)
        .scaleEffect(isPressed ? 1.03 : 1.0)
        .animation(.easeOut(duration: 0.2), value: isPressed)
        .onLongPressGesture(minimumDuration: .infinity, pressing: { pressing in
            isPressed = pressing
        }, perform: {})
    }
}

// MARK: - Profile Playlist Card (legacy - for list view)
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
