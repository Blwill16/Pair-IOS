import Foundation
import MusicKit
import StoreKit

// MARK: - Apple Music Manager
// Handles MusicKit authorization and Apple Music API interactions
@MainActor
class AppleMusicManager: ObservableObject {
    static let shared = AppleMusicManager()
    
    @Published var isAuthorized: Bool = false
    @Published var authorizationStatus: MusicAuthorization.Status = .notDetermined
    @Published var subscriptionStatus: MusicSubscription? = nil
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?
    
    private let apiService = APIService.shared
    
    private init() {
        // Check initial authorization status
        Task {
            await checkAuthorizationStatus()
        }
    }
    
    // MARK: - Authorization
    
    /// Check current authorization status
    func checkAuthorizationStatus() async {
        let status = MusicAuthorization.currentStatus
        authorizationStatus = status
        isAuthorized = status == .authorized
        
        if isAuthorized {
            await checkSubscriptionStatus()
        }
    }
    
    /// Request authorization to access Apple Music
    func requestAuthorization() async -> Bool {
        isLoading = true
        errorMessage = nil
        
        let status = await MusicAuthorization.request()
        authorizationStatus = status
        isAuthorized = status == .authorized
        
        if isAuthorized {
            await checkSubscriptionStatus()
            // Get and store the user token
            await fetchAndStoreUserToken()
        }
        
        isLoading = false
        return isAuthorized
    }
    
    /// Check if user has an active Apple Music subscription
    func checkSubscriptionStatus() async {
        do {
            let subscription = try await MusicSubscription.current
            subscriptionStatus = subscription
        } catch {
            print("Failed to check subscription status: \(error)")
            subscriptionStatus = nil
        }
    }
    
    /// Fetch the Music User Token and store it in the backend
    private func fetchAndStoreUserToken() async {
        do {
            // Get the developer token from our API
            guard let developerToken = try await fetchDeveloperToken() else {
                errorMessage = "Failed to get developer token"
                return
            }
            
            // Request the user token from MusicKit
            let userToken = try await MusicUserTokenProvider.current.userToken(
                for: developerToken,
                options: .ignoreCache
            )
            
            // Store the user token in the backend
            await storeUserToken(userToken)
            
        } catch {
            print("Failed to fetch user token: \(error)")
            errorMessage = "Failed to connect Apple Music"
        }
    }
    
    /// Fetch developer token from our API
    private func fetchDeveloperToken() async throws -> String? {
        guard let url = URL(string: "\(apiService.baseURL)/api/apple-music/token") else {
            return nil
        }
        
        let (data, _) = try await URLSession.shared.data(from: url)
        let response = try JSONDecoder().decode(DeveloperTokenResponse.self, from: data)
        return response.token
    }
    
    /// Store user token in the backend
    private func storeUserToken(_ token: String) async {
        guard let userId = AuthManager.shared.userId else { return }
        
        guard let url = URL(string: "\(apiService.baseURL)/api/music-accounts") else { return }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue(userId, forHTTPHeaderField: "x-user-id")
        
        let body: [String: Any] = [
            "provider": "apple_music",
            "music_user_token": token
        ]
        
        request.httpBody = try? JSONSerialization.data(withJSONObject: body)
        
        do {
            let (_, response) = try await URLSession.shared.data(for: request)
            if let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 {
                print("Successfully stored Apple Music user token")
            }
        } catch {
            print("Failed to store user token: \(error)")
        }
    }
    
    // MARK: - Library Operations
    
    /// Add a track to the user's Apple Music library
    func addToLibrary(appleMusicId: String) async -> Bool {
        guard isAuthorized else { return false }
        
        do {
            let request = MusicCatalogResourceRequest<Song>(matching: \.id, equalTo: MusicItemID(appleMusicId))
            let response = try await request.response()
            
            guard let song = response.items.first else { return false }
            
            try await MusicLibrary.shared.add(song)
            return true
        } catch {
            print("Failed to add to library: \(error)")
            return false
        }
    }
    
    /// Create or get the "Pair — Saved" playlist
    func getOrCreatePairPlaylist() async -> MusicItemID? {
        guard isAuthorized else { return nil }
        
        do {
            // Search for existing Pair playlist
            var request = MusicLibraryRequest<Playlist>()
            request.filter(matching: \.name, equalTo: "Pair — Saved")
            let response = try await request.response()
            
            if let existingPlaylist = response.items.first {
                return existingPlaylist.id
            }
            
            // Create new playlist
            let newPlaylist = try await MusicLibrary.shared.createPlaylist(
                name: "Pair — Saved",
                description: "Tracks saved from Pair Music"
            )
            
            return newPlaylist.id
        } catch {
            print("Failed to get/create Pair playlist: \(error)")
            return nil
        }
    }
    
    /// Add a track to the Pair playlist
    func addToPairPlaylist(appleMusicId: String) async -> Bool {
        guard isAuthorized else { return false }
        
        do {
            // Get the song
            let songRequest = MusicCatalogResourceRequest<Song>(matching: \.id, equalTo: MusicItemID(appleMusicId))
            let songResponse = try await songRequest.response()
            guard let song = songResponse.items.first else { return false }
            
            // Get or create the Pair playlist
            guard let playlistId = await getOrCreatePairPlaylist() else { return false }
            
            // Get the playlist
            var playlistRequest = MusicLibraryRequest<Playlist>()
            playlistRequest.filter(matching: \.id, equalTo: playlistId)
            let playlistResponse = try await playlistRequest.response()
            guard let playlist = playlistResponse.items.first else { return false }
            
            // Add the song to the playlist
            try await MusicLibrary.shared.add(song, to: playlist)
            
            return true
        } catch {
            print("Failed to add to Pair playlist: \(error)")
            return false
        }
    }
    
    /// Get user's recently played tracks
    func getRecentlyPlayed() async -> [Song] {
        guard isAuthorized else { return [] }
        
        do {
            var request = MusicRecentlyPlayedRequest<Song>()
            request.limit = 25
            let response = try await request.response()
            return Array(response.items)
        } catch {
            print("Failed to get recently played: \(error)")
            return []
        }
    }
    
    /// Get user's library songs for taste analysis
    func getLibrarySongs(limit: Int = 100) async -> [Song] {
        guard isAuthorized else { return [] }
        
        do {
            var request = MusicLibraryRequest<Song>()
            request.limit = limit
            let response = try await request.response()
            return Array(response.items)
        } catch {
            print("Failed to get library songs: \(error)")
            return []
        }
    }
    
    /// Search Apple Music catalog
    func searchCatalog(query: String, limit: Int = 25) async -> [Song] {
        do {
            var request = MusicCatalogSearchRequest(term: query, types: [Song.self])
            request.limit = limit
            let response = try await request.response()
            return Array(response.songs)
        } catch {
            print("Failed to search catalog: \(error)")
            return []
        }
    }
    
    // MARK: - Playback
    
    /// Play a song using the system music player
    func playSong(appleMusicId: String) async {
        guard isAuthorized else { return }
        
        do {
            let request = MusicCatalogResourceRequest<Song>(matching: \.id, equalTo: MusicItemID(appleMusicId))
            let response = try await request.response()
            
            guard let song = response.items.first else { return }
            
            let player = SystemMusicPlayer.shared
            player.queue = [song]
            try await player.play()
        } catch {
            print("Failed to play song: \(error)")
        }
    }
}

// MARK: - Response Models

struct DeveloperTokenResponse: Codable {
    let token: String
}

// MARK: - Music User Token Provider Extension
// Helper to get user token with developer token
class MusicUserTokenProvider {
    static let current = MusicUserTokenProvider()
    
    func userToken(for developerToken: String, options: MusicTokenRequestOptions) async throws -> String {
        // Use the default music user token request
        let controller = SKCloudServiceController()
        
        return try await withCheckedThrowingContinuation { continuation in
            controller.requestUserToken(forDeveloperToken: developerToken) { token, error in
                if let error = error {
                    continuation.resume(throwing: error)
                } else if let token = token {
                    continuation.resume(returning: token)
                } else {
                    continuation.resume(throwing: NSError(domain: "AppleMusicManager", code: -1, userInfo: [NSLocalizedDescriptionKey: "No token returned"]))
                }
            }
        }
    }
}

enum MusicTokenRequestOptions {
    case ignoreCache
    case useCache
}
