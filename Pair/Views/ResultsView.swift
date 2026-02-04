import SwiftUI

struct ResultsView: View {
    let pairResponse: PairResponse
    let promptText: String
    let mode: PairingMode
    
    @EnvironmentObject var authManager: AuthManager
    @EnvironmentObject var audioPlayer: AudioPlayer
    @EnvironmentObject var navigationState: NavigationState
    @Environment(\.dismiss) private var dismiss
    
    @State private var currentCardIndex = 0
    @State private var cardOffset: CGSize = .zero
    @State private var cardRotation: Double = 0
    @State private var showLikeBadge = false
    @State private var showPassBadge = false
    @State private var likedTracks: [PairingResult] = []
    @State private var showSavePlaylistSheet = false
    @State private var playlistTitle = ""
    @State private var isSavingPlaylist = false
    @State private var showPlaylistSaved = false
    @State private var errorMessage: String?
    @State private var showEmptyState = false
    
    private let apiService = APIService.shared
    private let hapticFeedback = UIImpactFeedbackGenerator(style: .medium)
    private let swipeThreshold: CGFloat = 150
    
    // Get mood color for the seed track
    private var moodColor: Color {
        MoodColorHelper.getMoodColor(for: pairResponse.seed)
    }
    
    var body: some View {
        ZStack {
            Color.pairBackground.ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Header
                headerSection
                
                Spacer()
                
                // Card stack or empty state
                if showEmptyState {
                    emptyStateView
                } else {
                    cardStackView
                }
                
                Spacer()
                
                // Action buttons
                if !showEmptyState {
                    actionButtonsView
                }
            }
            
            // Back button overlay
            VStack {
                HStack {
                    Button {
                        dismiss()
                    } label: {
                        HStack(spacing: 4) {
                            Image(systemName: "chevron.left")
                                .font(.system(size: 14))
                            Text("Back")
                                .font(.subheadline)
                        }
                        .foregroundColor(.pairTextSecondary)
                    }
                    .padding(.leading, 24)
                    .padding(.top, 16)
                    
                    Spacer()
                }
                Spacer()
            }
        }
        .navigationTitle("")
        .navigationBarHidden(true)
        .sheet(isPresented: $showSavePlaylistSheet) {
            savePlaylistSheet
        }
        .alert("Playlist Saved", isPresented: $showPlaylistSaved) {
            Button("OK", role: .cancel) {}
        } message: {
            Text("Your playlist has been saved!")
        }
        .onAppear {
            navigationState.hideNavBar()
            // Auto-play the first card's preview
            autoPlayCurrentCard()
        }
        .onDisappear {
            // Stop audio when leaving the view
            audioPlayer.stop()
        }
    }
    
    // MARK: - Header Section
    private var headerSection: some View {
        VStack(spacing: 12) {
            Text("\(pairResponse.seed.trackName) Pairing")
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(.pairTextPrimary)
                .multilineTextAlignment(.center)
            
            if !promptText.isEmpty {
                Text(promptText)
                    .font(.caption)
                    .foregroundColor(.pairTextSecondary)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(
                        Capsule()
                            .fill(Color.pairBackgroundSecondary)
                    )
            }
        }
        .padding(.top, 60)
        .padding(.horizontal, 24)
    }
    
    // MARK: - Card Stack View
    private var cardStackView: some View {
        ZStack {
            // Show up to 3 cards in the stack
            ForEach(Array(pairResponse.results.enumerated().reversed()), id: \.element.id) { index, result in
                if index >= currentCardIndex && index < currentCardIndex + 3 {
                    let stackPosition = index - currentCardIndex
                    
                    SwipeCard(
                        result: result,
                        moodColor: moodColor,
                        isTopCard: stackPosition == 0,
                        offset: stackPosition == 0 ? cardOffset : .zero,
                        rotation: stackPosition == 0 ? cardRotation : 0,
                        showLikeBadge: stackPosition == 0 && showLikeBadge,
                        showPassBadge: stackPosition == 0 && showPassBadge
                    )
                    .scaleEffect(stackPosition == 0 ? 1.0 : 0.95 - CGFloat(stackPosition) * 0.02)
                    .offset(y: CGFloat(stackPosition) * 8)
                    .opacity(stackPosition == 0 ? 1.0 : 0.9 - Double(stackPosition) * 0.1)
                    .zIndex(Double(pairResponse.results.count - index))
                    .gesture(
                        stackPosition == 0 ? DragGesture()
                            .onChanged { gesture in
                                cardOffset = gesture.translation
                                cardRotation = Double(gesture.translation.width / 20)
                                
                                // Show badges based on drag direction
                                showLikeBadge = gesture.translation.width > 50
                                showPassBadge = gesture.translation.width < -50
                            }
                            .onEnded { gesture in
                                handleSwipeEnd(gesture: gesture)
                            }
                        : nil
                    )
                }
            }
        }
        .frame(height: 450)
        .padding(.horizontal, 24)
    }
    
    // MARK: - Action Buttons
    private var actionButtonsView: some View {
        HStack(spacing: 24) {
            // Pass button
            Button {
                hapticFeedback.impactOccurred()
                swipeLeft()
            } label: {
                Image(systemName: "xmark")
                    .font(.system(size: 24, weight: .medium))
                    .foregroundColor(.red.opacity(0.8))
                    .frame(width: 64, height: 64)
                    .background(
                        Circle()
                            .fill(Color.pairCardBackground)
                    )
                    .overlay(
                        Circle()
                            .stroke(Color.pairCardBorder, lineWidth: 2)
                    )
                    .shadow(color: Color.black.opacity(0.05), radius: 8, y: 2)
            }
            
            // Like button
            Button {
                hapticFeedback.impactOccurred()
                swipeRight()
            } label: {
                Image(systemName: "heart.fill")
                    .font(.system(size: 24, weight: .medium))
                    .foregroundColor(.white)
                    .frame(width: 64, height: 64)
                    .background(
                        Circle()
                            .fill(Color.pairPurple)
                    )
                    .shadow(color: Color.pairPurple.opacity(0.3), radius: 16, y: 4)
            }
            
            // Info button
            Button {
                // Show more info about current track
            } label: {
                Image(systemName: "info")
                    .font(.system(size: 20, weight: .medium))
                    .foregroundColor(.pairTextSecondary)
                    .frame(width: 48, height: 48)
                    .background(
                        Circle()
                            .fill(Color.pairBackgroundSecondary)
                    )
            }
        }
        .padding(.bottom, 40)
    }
    
    // MARK: - Empty State
    private var emptyStateView: some View {
        VStack(spacing: 24) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 64))
                .foregroundColor(.pairPurple)
            
            Text("All done!")
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(.pairTextPrimary)
            
            Text("You liked \(likedTracks.count) tracks")
                .font(.body)
                .foregroundColor(.pairTextSecondary)
            
            if !likedTracks.isEmpty {
                // Playlist naming input
                VStack(alignment: .leading, spacing: 12) {
                    Text("Name your playlist")
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(.pairTextPrimary)
                    
                    TextField("", text: $playlistTitle, prompt: Text("e.g., Late Night Drive")
                        .foregroundColor(.pairTextTertiary))
                        .foregroundColor(.pairTextPrimary)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 14)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color.pairCardBackground)
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(Color.pairCardBorder, lineWidth: 1)
                        )
                }
                .padding(.horizontal, 24)
                .padding(.top, 8)
                
                // Save button
                Button {
                    savePlaylist()
                } label: {
                    if isSavingPlaylist {
                        ProgressView()
                            .tint(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(
                                Capsule()
                                    .fill(Color.pairPurple.opacity(0.7))
                            )
                    } else {
                        Text("Save Playlist")
                            .font(.body)
                            .fontWeight(.medium)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(
                                Capsule()
                                    .fill(Color.pairPurple)
                            )
                            .shadow(color: Color.pairPurple.opacity(0.25), radius: 16, y: 4)
                    }
                }
                .disabled(isSavingPlaylist || playlistTitle.isEmpty)
                .opacity(playlistTitle.isEmpty ? 0.6 : 1)
                .padding(.horizontal, 24)
                .padding(.top, 8)
                
                if let error = errorMessage {
                    Text(error)
                        .font(.caption)
                        .foregroundColor(.red)
                        .padding(.top, 4)
                }
            }
        }
        .opacity(showEmptyState ? 1 : 0)
        .animation(.easeIn(duration: 0.4), value: showEmptyState)
    }
    
    // MARK: - Save Playlist Sheet
    private var savePlaylistSheet: some View {
        NavigationStack {
            VStack(spacing: 24) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Playlist Title")
                        .font(.headline)
                    
                    TextField("Enter a title", text: $playlistTitle)
                        .textFieldStyle(.roundedBorder)
                }
                
                VStack(alignment: .leading, spacing: 8) {
                    Text("Details")
                        .font(.headline)
                    
                    VStack(alignment: .leading, spacing: 4) {
                        HStack {
                            Text("Seed:")
                                .foregroundStyle(.secondary)
                            Text(pairResponse.seed.trackName)
                        }
                        .font(.subheadline)
                        
                        HStack {
                            Text("Mode:")
                                .foregroundStyle(.secondary)
                            Text(mode.displayName)
                        }
                        .font(.subheadline)
                        
                        HStack {
                            Text("Liked tracks:")
                                .foregroundStyle(.secondary)
                            Text("\(likedTracks.count)")
                        }
                        .font(.subheadline)
                    }
                    .padding()
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color(.systemGray6))
                    .cornerRadius(12)
                }
                
                if let error = errorMessage {
                    Text(error)
                        .font(.caption)
                        .foregroundStyle(.red)
                }
                
                Spacer()
            }
            .padding()
            .navigationTitle("Save Playlist")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        showSavePlaylistSheet = false
                    }
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    Button {
                        savePlaylist()
                    } label: {
                        if isSavingPlaylist {
                            ProgressView()
                        } else {
                            Text("Save")
                        }
                    }
                    .disabled(isSavingPlaylist || likedTracks.isEmpty)
                }
            }
        }
        .presentationDetents([.medium])
    }
    
    // MARK: - Swipe Handling
    private func handleSwipeEnd(gesture: DragGesture.Value) {
        let horizontalAmount = gesture.translation.width
        
        if horizontalAmount > swipeThreshold {
            swipeRight()
        } else if horizontalAmount < -swipeThreshold {
            swipeLeft()
        } else {
            // Spring back to center
            withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                cardOffset = .zero
                cardRotation = 0
                showLikeBadge = false
                showPassBadge = false
            }
        }
    }
    
    private func swipeRight() {
        // Like the current track
        if currentCardIndex < pairResponse.results.count {
            likedTracks.append(pairResponse.results[currentCardIndex])
        }
        
        withAnimation(.easeOut(duration: 0.3)) {
            cardOffset = CGSize(width: 500, height: 0)
            cardRotation = 15
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            moveToNextCard()
        }
    }
    
    private func swipeLeft() {
        withAnimation(.easeOut(duration: 0.3)) {
            cardOffset = CGSize(width: -500, height: 0)
            cardRotation = -15
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            moveToNextCard()
        }
    }
    
    private func moveToNextCard() {
        cardOffset = .zero
        cardRotation = 0
        showLikeBadge = false
        showPassBadge = false
        
        if currentCardIndex < pairResponse.results.count - 1 {
            currentCardIndex += 1
            // Auto-play the next card's preview
            autoPlayCurrentCard()
        } else {
            // Stop audio when done
            audioPlayer.stop()
            withAnimation {
                showEmptyState = true
            }
        }
    }
    
    private func autoPlayCurrentCard() {
        guard currentCardIndex < pairResponse.results.count else { return }
        let currentResult = pairResponse.results[currentCardIndex]
        if let previewUrl = currentResult.previewUrl {
            audioPlayer.play(url: previewUrl, trackId: currentResult.trackId)
        }
    }
    
    private func savePlaylist() {
        guard let userId = authManager.userId else { return }
        
        isSavingPlaylist = true
        errorMessage = nil
        
        Task {
            do {
                let playlist = try await apiService.createPlaylist(
                    userId: userId,
                    title: playlistTitle.isEmpty ? nil : playlistTitle,
                    promptText: promptText.isEmpty ? nil : promptText,
                    seedTrackId: pairResponse.seed.trackId,
                    seedTrackName: pairResponse.seed.trackName,
                    seedArtistName: pairResponse.seed.artistName,
                    mode: mode.rawValue,
                    results: likedTracks
                )
                
                try await apiService.publishPlaylist(id: playlist.id, userId: userId)
                
                await MainActor.run {
                    isSavingPlaylist = false
                    showSavePlaylistSheet = false
                    showPlaylistSaved = true
                }
            } catch {
                await MainActor.run {
                    errorMessage = error.localizedDescription
                    isSavingPlaylist = false
                }
            }
        }
    }
}

// MARK: - Swipe Card Component
struct SwipeCard: View {
    let result: PairingResult
    let moodColor: Color
    let isTopCard: Bool
    let offset: CGSize
    let rotation: Double
    let showLikeBadge: Bool
    let showPassBadge: Bool
    
    @EnvironmentObject var audioPlayer: AudioPlayer
    
    private var isPlaying: Bool {
        return audioPlayer.currentTrackId == result.trackId && audioPlayer.isPlaying
    }
    
    private func slotTypeColor(for slotType: String) -> Color {
        switch slotType {
        case "core": return Color.pairPurple
        case "flavor": return Color.orange
        case "wildcard": return Color.green
        default: return Color.gray
        }
    }
    
    var body: some View {
        ZStack {
            // White card background
            VStack(spacing: 0) {
                // Album artwork with play button and slot type badge
                ZStack(alignment: .bottomTrailing) {
                    AsyncImage(url: URL(string: result.albumArtUrl ?? "")) { image in
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                    } placeholder: {
                        Rectangle()
                            .fill(Color.pairBackgroundSecondary)
                            .overlay {
                                Image(systemName: "music.note")
                                    .font(.system(size: 48))
                                    .foregroundColor(.pairTextTertiary)
                            }
                    }
                    .frame(width: UIScreen.main.bounds.width - 96, height: UIScreen.main.bounds.width - 96)
                    .clipped()
                    .cornerRadius(16)
                    .overlay(alignment: .topLeading) {
                        // Slot type badge
                        if let slotType = result.slotType, !slotType.isEmpty {
                            Text(result.slotTypeDisplay)
                                .font(.caption2)
                                .fontWeight(.semibold)
                                .foregroundColor(.white)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(
                                    Capsule()
                                        .fill(slotTypeColor(for: slotType))
                                )
                                .padding(8)
                        }
                    }
                    
                    // Play/Pause button overlay
                    if let previewUrl = result.previewUrl, isTopCard {
                        Button {
                            if isPlaying {
                                audioPlayer.pause()
                            } else {
                                audioPlayer.play(url: previewUrl, trackId: result.trackId)
                            }
                        } label: {
                            Image(systemName: isPlaying ? "pause.fill" : "play.fill")
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundColor(.white)
                                .frame(width: 44, height: 44)
                                .background(
                                    Circle()
                                        .fill(Color.black.opacity(0.6))
                                )
                        }
                        .padding(12)
                    }
                }
                .padding(.horizontal, 16)
                .padding(.top, 16)
                
                // Song info below artwork
                VStack(spacing: 4) {
                    Text(result.trackName)
                        .font(.title3)
                        .fontWeight(.bold)
                        .foregroundColor(.pairTextPrimary)
                        .lineLimit(1)
                    
                    Text(result.artistName)
                        .font(.body)
                        .foregroundColor(.pairTextSecondary)
                    
                    if let explanation = result.explanation {
                        Text(explanation)
                            .font(.caption)
                            .italic()
                            .foregroundColor(.pairTextTertiary)
                            .lineLimit(2)
                            .multilineTextAlignment(.center)
                            .padding(.top, 4)
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 16)
            }
            .background(
                RoundedRectangle(cornerRadius: 24)
                    .fill(Color.pairCardBackground)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 24)
                    .stroke(Color.black.opacity(0.08), lineWidth: 1)
            )
            
            // Like badge (top-left)
            if showLikeBadge {
                VStack {
                    HStack {
                        Text("LIKE")
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(.green)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 8)
                            .overlay(
                                RoundedRectangle(cornerRadius: 8)
                                    .stroke(Color.green, lineWidth: 3)
                            )
                            .rotationEffect(.degrees(-15))
                        Spacer()
                    }
                    .padding(24)
                    Spacer()
                }
                .opacity(min(Double(offset.width) / 100, 1.0))
            }
            
            // Pass badge (top-right)
            if showPassBadge {
                VStack {
                    HStack {
                        Spacer()
                        Text("PASS")
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(.red)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 8)
                            .overlay(
                                RoundedRectangle(cornerRadius: 8)
                                    .stroke(Color.red, lineWidth: 3)
                            )
                            .rotationEffect(.degrees(15))
                    }
                    .padding(24)
                    Spacer()
                }
                .opacity(min(Double(-offset.width) / 100, 1.0))
            }
        }
        .frame(width: UIScreen.main.bounds.width - 48)
        .shadow(color: Color.black.opacity(0.06), radius: 12, y: 4)
        .offset(offset)
        .rotationEffect(.degrees(rotation))
    }
}

struct ResultRowView: View {
    let result: PairingResult
    let rank: Int
    let isSaved: Bool
    let onSave: () -> Void
    let onOpenSpotify: () -> Void
    
    @EnvironmentObject var audioPlayer: AudioPlayer
    private let hapticFeedback = UIImpactFeedbackGenerator(style: .light)
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 12) {
                Text("\(rank)")
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(.pairTextTertiary)
                    .frame(width: 24)
                
                AsyncImage(url: URL(string: result.albumArtUrl ?? "")) { image in
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
                .frame(width: 52, height: 52)
                .cornerRadius(8)
                
                VStack(alignment: .leading, spacing: 3) {
                    Text(result.trackName)
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(.white)
                        .lineLimit(1)
                    
                    Text(result.artistName)
                        .font(.caption)
                        .foregroundColor(.pairTextSecondary)
                }
                
                Spacer()
                
                HStack(spacing: 8) {
                    if let previewUrl = result.previewUrl {
                        Button {
                            hapticFeedback.impactOccurred()
                            audioPlayer.play(url: previewUrl, trackId: result.trackId)
                        } label: {
                            Image(systemName: audioPlayer.currentTrackId == result.trackId && audioPlayer.isPlaying ? "pause.circle.fill" : "play.circle.fill")
                                .font(.system(size: 36))
                                .foregroundColor(.pairPurple)
                        }
                        .buttonStyle(.plain)
                    }
                    
                    Menu {
                        Button {
                            onSave()
                        } label: {
                            Label(isSaved ? "Saved" : "Save Track", systemImage: isSaved ? "heart.fill" : "heart")
                        }
                        
                        Button {
                            onOpenSpotify()
                        } label: {
                            Label("Open in Spotify", systemImage: "arrow.up.right")
                        }
                    } label: {
                        Image(systemName: "ellipsis")
                            .foregroundColor(.pairTextSecondary)
                            .padding(8)
                    }
                }
            }
            
            if let explanation = result.explanation {
                Text(explanation)
                    .font(.caption)
                    .foregroundColor(.pairTextTertiary)
                    .padding(.leading, 36)
                    .italic()
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
    }
}

#Preview {
    NavigationStack {
        ResultsView(
            pairResponse: PairResponse(
                seed: SpotifyTrack(
                    trackId: "seed",
                    trackName: "Seed Song",
                    artistName: "Seed Artist",
                    albumArtUrl: nil,
                    previewUrl: nil,
                    spotifyUrl: "https://spotify.com"
                ),
                results: [
                    PairingResult(
                        trackId: "1",
                        trackName: "Result 1",
                        artistName: "Artist 1",
                        albumArtUrl: nil,
                        previewUrl: nil,
                        spotifyUrl: "https://spotify.com",
                        score: 0.85,
                        explanation: "Similar tempo and energy",
                        slotType: "core",
                        slotPosition: 1
                    )
                ]
            ),
            promptText: "late night vibes",
            mode: .sameVibe
        )
    }
    .environmentObject(AuthManager.shared)
    .environmentObject(AudioPlayer.shared)
}
