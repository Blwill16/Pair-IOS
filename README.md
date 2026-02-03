# Pair iOS

A SwiftUI iOS app for discovering music that matches your vibe. Uses a hybrid pairing algorithm to find songs similar to a seed track.

## Features

- Search for seed tracks via Spotify
- Generate music pairings with 4 modes:
  - **Same Sound**: Find tracks with similar audio characteristics
  - **Same Vibe**: Match the mood and feeling
  - **Same Scene**: Discover related artists and scenes
  - **Adventure**: Explore new territory while staying connected
- Play 30-second previews
- Open tracks in Spotify
- Save favorite tracks
- Social features:
  - Create and share playlists
  - Follow other users
  - Like playlists
  - Remix prompts from other users

## Requirements

- iOS 17.0+
- Xcode 15.0+
- Swift 5.9+

## Setup

### 1. Clone the repository

```bash
git clone https://github.com/yourusername/pair-ios.git
cd pair-ios
```

### 2. Configure Environment

Create a `Config.xcconfig` file or set environment variables:

```
SUPABASE_URL=your_supabase_url
SUPABASE_ANON_KEY=your_supabase_anon_key
PAIR_API_BASE_URL=your_vercel_api_url
SPOTIFY_CLIENT_ID=your_spotify_client_id
SPOTIFY_REDIRECT_URI=pair://spotify-callback
```

### 3. Open in Xcode

```bash
open Pair.xcodeproj
```

### 4. Build and Run

Select your target device/simulator and press Cmd+R.

## Project Structure

```
Pair/
├── PairApp.swift           # App entry point
├── ContentView.swift       # Main tab view
├── Models/
│   └── Models.swift        # Data models
├── Services/
│   ├── APIService.swift    # API client
│   ├── AuthManager.swift   # Authentication
│   └── AudioPlayer.swift   # Audio playback
├── Views/
│   ├── SearchView.swift    # Seed track search
│   ├── PromptView.swift    # Pairing configuration
│   ├── ResultsView.swift   # Pairing results
│   ├── ExploreView.swift   # Public playlists
│   ├── FeedView.swift      # Following feed
│   ├── ProfileView.swift   # User profile
│   └── PlaylistDetailView.swift
├── Components/
│   ├── TrackRowView.swift
│   └── PlaylistRowView.swift
└── Assets.xcassets/
```

## Authentication

The app supports:
- Sign in with Apple
- Magic link email authentication
- Guest mode (limited features)

## API Integration

The app communicates with the Pair API (pair-api) for:
- Spotify track search
- Pairing generation
- Social features (playlists, follows, likes)
- User profiles

## License

MIT
