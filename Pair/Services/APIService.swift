import Foundation

class APIService: ObservableObject {
    static let shared = APIService()
    
    private let baseURL: String
    
    init() {
        self.baseURL = ProcessInfo.processInfo.environment["PAIR_API_BASE_URL"] ?? "http://localhost:3000"
    }
    
    func searchTracks(query: String) async throws -> [SpotifyTrack] {
        guard let encodedQuery = query.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed),
              let url = URL(string: "\(baseURL)/api/spotify/search?q=\(encodedQuery)") else {
            throw APIError.invalidURL
        }
        
        let (data, response) = try await URLSession.shared.data(from: url)
        
        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
            throw APIError.requestFailed
        }
        
        let searchResponse = try JSONDecoder().decode(SearchResponse.self, from: data)
        return searchResponse.tracks
    }
    
    func generatePairing(seedTrackId: String, prompt: String?, mode: PairingMode, userId: String?) async throws -> PairResponse {
        guard let url = URL(string: "\(baseURL)/api/pair") else {
            throw APIError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        var body: [String: Any] = [
            "seedTrackId": seedTrackId,
            "mode": mode.rawValue
        ]
        
        if let prompt = prompt, !prompt.isEmpty {
            body["prompt"] = prompt
        }
        
        if let userId = userId {
            body["userId"] = userId
        }
        
        request.httpBody = try JSONSerialization.data(withJSONObject: body)
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
            throw APIError.requestFailed
        }
        
        return try JSONDecoder().decode(PairResponse.self, from: data)
    }
    
    func getPublicPlaylists(limit: Int = 20, offset: Int = 0) async throws -> [Playlist] {
        guard let url = URL(string: "\(baseURL)/api/playlists?type=public&limit=\(limit)&offset=\(offset)") else {
            throw APIError.invalidURL
        }
        
        let (data, response) = try await URLSession.shared.data(from: url)
        
        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
            throw APIError.requestFailed
        }
        
        struct PlaylistsResponse: Codable {
            let playlists: [Playlist]
        }
        
        let playlistsResponse = try JSONDecoder().decode(PlaylistsResponse.self, from: data)
        return playlistsResponse.playlists
    }
    
    func getFeed(userId: String, limit: Int = 20, offset: Int = 0) async throws -> [Playlist] {
        guard let url = URL(string: "\(baseURL)/api/feed?userId=\(userId)&limit=\(limit)&offset=\(offset)") else {
            throw APIError.invalidURL
        }
        
        let (data, response) = try await URLSession.shared.data(from: url)
        
        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
            throw APIError.requestFailed
        }
        
        struct FeedResponse: Codable {
            let playlists: [Playlist]
        }
        
        let feedResponse = try JSONDecoder().decode(FeedResponse.self, from: data)
        return feedResponse.playlists
    }
    
    func getPlaylist(id: String) async throws -> Playlist {
        guard let url = URL(string: "\(baseURL)/api/playlists/\(id)") else {
            throw APIError.invalidURL
        }
        
        let (data, response) = try await URLSession.shared.data(from: url)
        
        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
            throw APIError.requestFailed
        }
        
        struct PlaylistResponse: Codable {
            let playlist: Playlist
        }
        
        let playlistResponse = try JSONDecoder().decode(PlaylistResponse.self, from: data)
        return playlistResponse.playlist
    }
    
    func createPlaylist(userId: String, title: String?, promptText: String?, seedTrackId: String?, seedTrackName: String?, seedArtistName: String?, mode: String?, results: [PairingResult]) async throws -> Playlist {
        guard let url = URL(string: "\(baseURL)/api/playlists") else {
            throw APIError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        var body: [String: Any] = [
            "userId": userId,
            "results": results.map { result in
                [
                    "track_id": result.trackId,
                    "track_name": result.trackName,
                    "artist_name": result.artistName,
                    "preview_url": result.previewUrl as Any,
                    "spotify_url": result.spotifyUrl,
                    "score": result.score as Any,
                    "explanation": result.explanation as Any
                ]
            }
        ]
        
        if let title = title { body["title"] = title }
        if let promptText = promptText { body["promptText"] = promptText }
        if let seedTrackId = seedTrackId { body["seedTrackId"] = seedTrackId }
        if let seedTrackName = seedTrackName { body["seedTrackName"] = seedTrackName }
        if let seedArtistName = seedArtistName { body["seedArtistName"] = seedArtistName }
        if let mode = mode { body["mode"] = mode }
        
        request.httpBody = try JSONSerialization.data(withJSONObject: body)
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
            throw APIError.requestFailed
        }
        
        struct CreatePlaylistResponse: Codable {
            let playlist: Playlist
        }
        
        let createResponse = try JSONDecoder().decode(CreatePlaylistResponse.self, from: data)
        return createResponse.playlist
    }
    
    func publishPlaylist(id: String, userId: String) async throws {
        guard let url = URL(string: "\(baseURL)/api/playlists/\(id)/publish") else {
            throw APIError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue(userId, forHTTPHeaderField: "x-user-id")
        
        let (_, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
            throw APIError.requestFailed
        }
    }
    
    func getProfile(userId: String? = nil, username: String? = nil) async throws -> Profile {
        var urlString = "\(baseURL)/api/profiles?"
        if let userId = userId {
            urlString += "userId=\(userId)"
        } else if let username = username {
            urlString += "username=\(username)"
        }
        
        guard let url = URL(string: urlString) else {
            throw APIError.invalidURL
        }
        
        let (data, response) = try await URLSession.shared.data(from: url)
        
        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
            throw APIError.requestFailed
        }
        
        struct ProfileResponse: Codable {
            let profile: Profile
        }
        
        let profileResponse = try JSONDecoder().decode(ProfileResponse.self, from: data)
        return profileResponse.profile
    }
    
    func follow(followerId: String, followeeId: String, action: String) async throws {
        guard let url = URL(string: "\(baseURL)/api/follow") else {
            throw APIError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let body: [String: Any] = [
            "followerId": followerId,
            "followeeId": followeeId,
            "action": action
        ]
        
        request.httpBody = try JSONSerialization.data(withJSONObject: body)
        
        let (_, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
            throw APIError.requestFailed
        }
    }
    
    func likePlaylist(userId: String, playlistId: String, action: String) async throws {
        guard let url = URL(string: "\(baseURL)/api/like") else {
            throw APIError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let body: [String: Any] = [
            "userId": userId,
            "playlistId": playlistId,
            "action": action
        ]
        
        request.httpBody = try JSONSerialization.data(withJSONObject: body)
        
        let (_, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
            throw APIError.requestFailed
        }
    }
    
    func saveTrack(userId: String, track: PairingResult) async throws {
        guard let url = URL(string: "\(baseURL)/api/saved-tracks") else {
            throw APIError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let body: [String: Any] = [
            "userId": userId,
            "trackId": track.trackId,
            "trackName": track.trackName,
            "artistName": track.artistName,
            "previewUrl": track.previewUrl as Any,
            "spotifyUrl": track.spotifyUrl
        ]
        
        request.httpBody = try JSONSerialization.data(withJSONObject: body)
        
        let (_, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
            throw APIError.requestFailed
        }
    }
    
    func getSavedTracks(userId: String) async throws -> [SavedTrack] {
        guard let url = URL(string: "\(baseURL)/api/saved-tracks?userId=\(userId)") else {
            throw APIError.invalidURL
        }
        
        let (data, response) = try await URLSession.shared.data(from: url)
        
        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
            throw APIError.requestFailed
        }
        
        struct SavedTracksResponse: Codable {
            let savedTracks: [SavedTrack]
            
            enum CodingKeys: String, CodingKey {
                case savedTracks = "saved_tracks"
            }
        }
        
        let savedResponse = try JSONDecoder().decode(SavedTracksResponse.self, from: data)
        return savedResponse.savedTracks
    }
    
    func removeSavedTrack(userId: String, trackId: String) async throws {
        guard let url = URL(string: "\(baseURL)/api/saved-tracks?userId=\(userId)&trackId=\(trackId)") else {
            throw APIError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "DELETE"
        
        let (_, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
            throw APIError.requestFailed
        }
    }
}

enum APIError: Error, LocalizedError {
    case invalidURL
    case requestFailed
    case decodingFailed
    
    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "Invalid URL"
        case .requestFailed:
            return "Request failed"
        case .decodingFailed:
            return "Failed to decode response"
        }
    }
}
