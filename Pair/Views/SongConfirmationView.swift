import SwiftUI

// MARK: - Song Confirmation Screen (Figma: Intermediate step between search and pairing)
struct SongConfirmationView: View {
    let track: SpotifyTrack
    @Environment(\.dismiss) private var dismiss
    @State private var showContent = false
    @State private var navigateToPrompt = false
    
    // Get mood color based on track
    private var moodColor: Color {
        MoodColorHelper.getMoodColor(for: track.trackName, artist: track.artistName)
    }
    
    var body: some View {
        ZStack {
            // Base background
            Color.pairBackground.ignoresSafeArea()
            
            // Atmospheric mood color gradient at top per Figma
            VStack {
                RadialGradient(
                    colors: [
                        moodColor.opacity(0.3),
                        moodColor.opacity(0.15),
                        Color.clear
                    ],
                    center: .top,
                    startRadius: 0,
                    endRadius: UIScreen.main.bounds.height * 0.6
                )
                .frame(height: UIScreen.main.bounds.height * 0.6)
                .ignoresSafeArea()
                
                Spacer()
            }
            
            // Content
            VStack(spacing: 0) {
                Spacer()
                
                // Album artwork with breathing glow
                AlbumArtworkView(
                    imageUrl: track.albumArtUrl,
                    moodColor: moodColor,
                    size: 288
                )
                .opacity(showContent ? 1 : 0)
                .scaleEffect(showContent ? 1 : 0.95)
                .animation(.easeOut(duration: 0.6), value: showContent)
                .padding(.bottom, 32)
                
                // Song details
                VStack(spacing: 12) {
                    Text(track.trackName)
                        .font(.title)
                        .fontWeight(.bold)
                        .foregroundColor(.pairTextPrimary)
                        .multilineTextAlignment(.center)
                    
                    Text(track.artistName)
                        .font(.title3)
                        .foregroundColor(.pairTextSecondary)
                }
                .opacity(showContent ? 1 : 0)
                .offset(y: showContent ? 0 : 10)
                .animation(.easeOut(duration: 0.6).delay(0.2), value: showContent)
                .padding(.bottom, 16)
                
                // Poetic copy
                Text("Ready to find what belongs with this")
                    .font(.subheadline)
                    .italic()
                    .foregroundColor(.pairTextSecondary.opacity(0.6))
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: 320)
                    .opacity(showContent ? 1 : 0)
                    .offset(y: showContent ? 0 : 10)
                    .animation(.easeOut(duration: 0.6).delay(0.3), value: showContent)
                    .padding(.bottom, 48)
                
                Spacer()
                
                // Continue button
                Button {
                    navigateToPrompt = true
                } label: {
                    HStack(spacing: 8) {
                        Text("Continue")
                            .font(.body)
                            .fontWeight(.medium)
                        
                        Image(systemName: "chevron.right")
                            .font(.system(size: 16))
                    }
                    .foregroundColor(Color(hex: "1a1230"))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(
                        Capsule()
                            .fill(Color.pairPurple)
                    )
                    .shadow(color: Color.pairPurple.opacity(0.25), radius: 24, x: 0, y: 6)
                }
                .padding(.horizontal, 24)
                .opacity(showContent ? 1 : 0)
                .offset(y: showContent ? 0 : 10)
                .animation(.easeOut(duration: 0.6).delay(0.4), value: showContent)
                .padding(.bottom, 48)
            }
            
            // Back button - top left per Figma
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
                        .foregroundColor(.pairTextSecondary.opacity(0.6))
                    }
                    .padding(.leading, 24)
                    .padding(.top, 16)
                    
                    Spacer()
                }
                Spacer()
            }
        }
        .navigationBarHidden(true)
        .onAppear {
            showContent = true
        }
        .navigationDestination(isPresented: $navigateToPrompt) {
            PromptView(seedTrack: track)
        }
    }
}

// MARK: - Album Artwork with Breathing Glow
struct AlbumArtworkView: View {
    let imageUrl: String?
    let moodColor: Color
    let size: CGFloat
    
    @State private var glowIntensity: CGFloat = 0.2
    
    var body: some View {
        AsyncImage(url: URL(string: imageUrl ?? "")) { image in
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
        .frame(width: size, height: size)
        .cornerRadius(24)
        .shadow(color: moodColor.opacity(glowIntensity), radius: 30, x: 0, y: 20)
        .shadow(color: moodColor.opacity(glowIntensity * 0.5), radius: 60, x: 0, y: 30)
        .onAppear {
            withAnimation(.easeInOut(duration: 3).repeatForever(autoreverses: true)) {
                glowIntensity = 0.25
            }
        }
    }
}

#Preview {
    SongConfirmationView(track: SpotifyTrack(
        trackId: "1",
        trackName: "Midnight City",
        artistName: "M83",
        albumArtUrl: "https://images.unsplash.com/photo-1493225457124-a3eb161ffa5f?w=400",
        previewUrl: nil,
        spotifyUrl: ""
    ))
}
