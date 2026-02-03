import SwiftUI

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
            Group {
                if isLoading && profile == nil {
                    loadingView
                } else if let profile = profile {
                    profileContent(profile)
                } else {
                    errorView
                }
            }
            .navigationTitle(isOwnProfile ? "Profile" : "")
            .navigationBarTitleDisplayMode(isOwnProfile ? .large : .inline)
            .toolbar {
                if isOwnProfile {
                    ToolbarItem(placement: .topBarTrailing) {
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
                        }
                    }
                }
            }
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
    
    private var loadingView: some View {
        VStack {
            Spacer()
            ProgressView()
            Spacer()
        }
    }
    
    private var errorView: some View {
        VStack(spacing: 24) {
            Spacer()
            
            Image(systemName: "person.crop.circle.badge.exclamationmark")
                .font(.system(size: 64))
                .foregroundStyle(.secondary)
            
            VStack(spacing: 8) {
                Text("Profile not found")
                    .font(.title2)
                    .fontWeight(.semibold)
                
                if let error = errorMessage {
                    Text(error)
                        .font(.caption)
                        .foregroundStyle(.red)
                }
            }
            
            Spacer()
        }
    }
    
    private func profileContent(_ profile: Profile) -> some View {
        ScrollView {
            VStack(spacing: 24) {
                profileHeader(profile)
                
                statsSection(profile)
                
                if !isOwnProfile {
                    followButton
                }
                
                playlistsSection(profile)
            }
            .padding()
        }
    }
    
    private func profileHeader(_ profile: Profile) -> some View {
        VStack(spacing: 16) {
            AsyncImage(url: URL(string: profile.avatarUrl ?? "")) { image in
                image
                    .resizable()
                    .aspectRatio(contentMode: .fill)
            } placeholder: {
                Circle()
                    .fill(Color.gray.opacity(0.3))
                    .overlay {
                        Image(systemName: "person.fill")
                            .font(.system(size: 40))
                            .foregroundStyle(.gray)
                    }
            }
            .frame(width: 100, height: 100)
            .clipShape(Circle())
            
            VStack(spacing: 4) {
                Text(profile.displayName ?? profile.username)
                    .font(.title2)
                    .fontWeight(.bold)
                
                Text("@\(profile.username)")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                
                if let bio = profile.bio, !bio.isEmpty {
                    Text(bio)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.top, 4)
                }
            }
        }
    }
    
    private func statsSection(_ profile: Profile) -> some View {
        HStack(spacing: 48) {
            VStack(spacing: 4) {
                Text("\(profile.playlists?.count ?? 0)")
                    .font(.title3)
                    .fontWeight(.bold)
                Text("Playlists")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            
            VStack(spacing: 4) {
                Text("\(profile.followerCount ?? 0)")
                    .font(.title3)
                    .fontWeight(.bold)
                Text("Followers")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            
            VStack(spacing: 4) {
                Text("\(profile.followingCount ?? 0)")
                    .font(.title3)
                    .fontWeight(.bold)
                Text("Following")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
    
    private var followButton: some View {
        Button {
            toggleFollow()
        } label: {
            Text(isFollowing ? "Following" : "Follow")
                .fontWeight(.medium)
                .frame(maxWidth: .infinity)
                .padding()
                .background(isFollowing ? Color(.systemGray5) : Color.purple)
                .foregroundColor(isFollowing ? .primary : .white)
                .cornerRadius(12)
        }
    }
    
    private func playlistsSection(_ profile: Profile) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Playlists")
                .font(.headline)
            
            if let playlists = profile.playlists, !playlists.isEmpty {
                LazyVStack(spacing: 12) {
                    ForEach(playlists) { playlist in
                        PlaylistRowView(playlist: playlist)
                            .contentShape(Rectangle())
                            .onTapGesture {
                                selectedPlaylist = playlist
                            }
                    }
                }
            } else {
                VStack(spacing: 12) {
                    Image(systemName: "music.note.list")
                        .font(.system(size: 32))
                        .foregroundStyle(.secondary)
                    
                    Text("No playlists yet")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 32)
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

#Preview {
    ProfileView(userId: "test-user-id")
        .environmentObject(AuthManager.shared)
        .environmentObject(AudioPlayer.shared)
}
