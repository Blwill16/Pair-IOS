import Foundation

struct SpotifyTrack: Codable, Identifiable, Hashable {
    let trackId: String
    let trackName: String
    let artistName: String
    let albumArtUrl: String?
    let previewUrl: String?
    let spotifyUrl: String
    
    var id: String { trackId }
    
    enum CodingKeys: String, CodingKey {
        case trackId = "track_id"
        case trackName = "track_name"
        case artistName = "artist_name"
        case albumArtUrl = "album_art_url"
        case previewUrl = "preview_url"
        case spotifyUrl = "spotify_url"
    }
}

struct PairingResult: Codable, Identifiable, Hashable {
    let trackId: String
    let trackName: String
    let artistName: String
    let albumArtUrl: String?
    let previewUrl: String?
    let spotifyUrl: String
    let score: Double?
    let explanation: String?
    let slotType: String?
    let slotPosition: Int?
    
    var id: String { trackId }
    
    // Computed property for display-friendly slot type
    var slotTypeDisplay: String {
        switch slotType {
        case "core": return "Core Match"
        case "flavor": return "Flavor Pick"
        case "wildcard": return "Wildcard"
        default: return ""
        }
    }
    
    enum CodingKeys: String, CodingKey {
        case trackId = "track_id"
        case trackName = "track_name"
        case artistName = "artist_name"
        case albumArtUrl = "album_art_url"
        case previewUrl = "preview_url"
        case spotifyUrl = "spotify_url"
        case score
        case explanation
        case slotType = "slot_type"
        case slotPosition = "slot_position"
    }
}

struct PairResponse: Codable {
    let seed: SpotifyTrack
    let results: [PairingResult]
}

struct SearchResponse: Codable {
    let tracks: [SpotifyTrack]
}

enum PairingMode: String, CaseIterable, Codable {
    case sameSound = "same_sound"
    case sameVibe = "same_vibe"
    case sameScene = "same_scene"
    case adventure = "adventure"
    
    var displayName: String {
        switch self {
        case .sameSound: return "Same Sound"
        case .sameVibe: return "Same Vibe"
        case .sameScene: return "Same Scene"
        case .adventure: return "Adventure"
        }
    }
    
    var description: String {
        switch self {
        case .sameSound: return "Find tracks with similar audio characteristics"
        case .sameVibe: return "Match the mood and feeling"
        case .sameScene: return "Discover related artists and scenes"
        case .adventure: return "Explore new territory while staying connected"
        }
    }
}

struct Profile: Codable, Identifiable {
    let userId: String
    let username: String
    let displayName: String?
    let bio: String?
    let avatarUrl: String?
    let createdAt: String?
    let followerCount: Int?
    let followingCount: Int?
    let playlists: [Playlist]?
    
    var id: String { userId }
    
    enum CodingKeys: String, CodingKey {
        case userId = "user_id"
        case username
        case displayName = "display_name"
        case bio
        case avatarUrl = "avatar_url"
        case createdAt = "created_at"
        case followerCount = "follower_count"
        case followingCount = "following_count"
        case playlists
    }
}

struct Playlist: Codable, Identifiable, Hashable {
    let id: String
    let ownerId: String
    let title: String
    let promptText: String?
    let seedTrackId: String?
    let seedTrackName: String?
    let seedArtistName: String?
    let mode: String?
    let isPublic: Bool
    let createdAt: String?
    let tracks: [PlaylistTrack]?
    let likeCount: Int?
    let viewerHasLiked: Bool?
    let profiles: ProfileSummary?
    
    enum CodingKeys: String, CodingKey {
        case id
        case ownerId = "owner_id"
        case title
        case promptText = "prompt_text"
        case seedTrackId = "seed_track_id"
        case seedTrackName = "seed_track_name"
        case seedArtistName = "seed_artist_name"
        case mode
        case isPublic = "is_public"
        case createdAt = "created_at"
        case tracks
        case likeCount = "like_count"
        case viewerHasLiked = "viewer_has_liked"
        case profiles
    }
    
    static func == (lhs: Playlist, rhs: Playlist) -> Bool {
        lhs.id == rhs.id
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}

struct ProfileSummary: Codable, Hashable {
    let userId: String?
    let username: String?
    let displayName: String?
    let avatarUrl: String?
    
    enum CodingKeys: String, CodingKey {
        case userId = "user_id"
        case username
        case displayName = "display_name"
        case avatarUrl = "avatar_url"
    }
}

struct PlaylistTrack: Codable, Identifiable, Hashable {
    let id: String
    let playlistId: String
    let trackId: String
    let trackName: String?
    let artistName: String?
    let previewUrl: String?
    let spotifyUrl: String?
    let score: Double?
    let explanation: String?
    let rank: Int?
    
    enum CodingKeys: String, CodingKey {
        case id
        case playlistId = "playlist_id"
        case trackId = "track_id"
        case trackName = "track_name"
        case artistName = "artist_name"
        case previewUrl = "preview_url"
        case spotifyUrl = "spotify_url"
        case score
        case explanation
        case rank
    }
}

struct SavedTrack: Codable, Identifiable {
    let id: String
    let userId: String
    let trackId: String
    let trackName: String?
    let artistName: String?
    let previewUrl: String?
    let spotifyUrl: String?
    let createdAt: String?
    
    enum CodingKeys: String, CodingKey {
        case id
        case userId = "user_id"
        case trackId = "track_id"
        case trackName = "track_name"
        case artistName = "artist_name"
        case previewUrl = "preview_url"
        case spotifyUrl = "spotify_url"
        case createdAt = "created_at"
    }
}

struct User: Codable {
    let id: String
    let email: String?
}

// PairTrack is used for local/unsaved pairing results from the API
struct PairTrack: Codable, Identifiable, Hashable {
    let apple_music_id: String
    let track_name: String
    let artist_name: String
    let album_art_url: String?
    let preview_url: String?
    let duration_ms: Int?
    let score: Double?
    let explanation: String?
    
    var id: String { apple_music_id }
}

// MARK: - Curator Engine Models

struct CuratedGenre: Codable, Identifiable, Hashable {
    let id: String
    let slug: String
    let displayName: String
    let descriptor: String?
    let searchKeywords: [String]?
    let isActive: Bool?
    let userWeight: Double?
    let userActive: Bool?
    
    enum CodingKeys: String, CodingKey {
        case id
        case slug
        case displayName = "display_name"
        case descriptor
        case searchKeywords = "search_keywords"
        case isActive = "is_active"
        case userWeight = "user_weight"
        case userActive = "user_active"
    }
}

struct WeeklyDropTrack: Codable, Identifiable, Hashable {
    let id: String?
    let appleMusicId: String?
    let trackName: String?
    let artistName: String?
    let albumName: String?
    let albumArtUrl: String?
    let previewUrl: String?
    let confidence: Double?
    let reason: String?
    
    enum CodingKeys: String, CodingKey {
        case id
        case appleMusicId = "apple_music_id"
        case trackName = "track_name"
        case artistName = "artist_name"
        case albumName = "album_name"
        case albumArtUrl = "album_art_url"
        case previewUrl = "preview_url"
        case confidence
        case reason
    }
}

struct WeeklyDropGenre: Codable, Identifiable, Hashable {
    let slug: String
    let displayName: String
    let descriptor: String?
    let trackCount: Int
    let tracks: [WeeklyDropTrack]
    
    var id: String { slug }
    
    enum CodingKeys: String, CodingKey {
        case slug
        case displayName = "display_name"
        case descriptor
        case trackCount = "track_count"
        case tracks
    }
}

struct WeeklyDropResponse: Codable {
    let status: String
    let weekStartDate: String?
    let totalTracks: Int?
    let genres: [WeeklyDropGenre]?
    let message: String?
    
    enum CodingKeys: String, CodingKey {
        case status
        case weekStartDate = "week_start_date"
        case totalTracks = "total_tracks"
        case genres
        case message
    }
}

struct GenresResponse: Codable {
    let genres: [CuratedGenre]
}

struct DiscoverResponse: Codable {
    let playlists: [Playlist]?
    let featured: [Playlist]?
}

struct TasteProfile: Codable {
    let tasteVector: TasteVector?
    let genrePreferences: [GenrePreference]?
    let stats: TasteStats?
    
    enum CodingKeys: String, CodingKey {
        case tasteVector = "taste_vector"
        case genrePreferences = "genre_preferences"
        case stats
    }
}

struct TasteVector: Codable {
    let preferredEnergy: Double?
    let preferredValence: Double?
    let preferredDanceability: Double?
    let preferredAcousticness: Double?
    let preferredTempo: Double?
    
    enum CodingKeys: String, CodingKey {
        case preferredEnergy = "preferred_energy"
        case preferredValence = "preferred_valence"
        case preferredDanceability = "preferred_danceability"
        case preferredAcousticness = "preferred_acousticness"
        case preferredTempo = "preferred_tempo"
    }
}

struct GenrePreference: Codable, Identifiable {
    let slug: String?
    let displayName: String?
    let weight: Double?
    let isActive: Bool?
    
    var id: String { slug ?? UUID().uuidString }
    
    enum CodingKeys: String, CodingKey {
        case slug
        case displayName = "display_name"
        case weight
        case isActive = "is_active"
    }
}

struct TasteStats: Codable {
    let totalInteractions: Int?
    let likes: Int?
    let dislikes: Int?
    let saves: Int?
    let skips: Int?
    
    enum CodingKeys: String, CodingKey {
        case totalInteractions = "total_interactions"
        case likes
        case dislikes
        case saves
        case skips
    }
}
