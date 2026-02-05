import SwiftUI

struct Tastemaker: Identifiable {
    let id = UUID()
    let name: String
    let username: String
    let followerCount: String
    let genres: [String]
    let avatarSeed: String
}

struct DiscoverTastemakersView: View {
    @EnvironmentObject var authManager: AuthManager
    @Binding var isOnboardingComplete: Bool
    
    @State private var followedUsers: Set<UUID> = []
    @State private var isLoading = false
    
    private let tastemakers = [
        Tastemaker(name: "Maya Chen", username: "mayabeats", followerCount: "2.4k", genres: ["Indie Pop", "Dream Pop"], avatarSeed: "maya"),
        Tastemaker(name: "Marcus Reid", username: "soulcurator", followerCount: "5.1k", genres: ["R&B", "Neo-Soul"], avatarSeed: "marcus"),
        Tastemaker(name: "Sofia Rodriguez", username: "electronica_", followerCount: "3.8k", genres: ["Electronic", "House"], avatarSeed: "sofia"),
        Tastemaker(name: "Jordan Park", username: "vinylvibes", followerCount: "1.9k", genres: ["Jazz", "Funk"], avatarSeed: "jordan"),
        Tastemaker(name: "Emma Wilson", username: "folkfinds", followerCount: "4.2k", genres: ["Folk", "Americana"], avatarSeed: "emma")
    ]
    
    var body: some View {
        ZStack {
            Color.pairBackground.ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Progress bar - all 4 steps complete
                HStack(spacing: 8) {
                    ForEach(0..<4) { _ in
                        Rectangle()
                            .fill(Color.pairPurple)
                            .frame(height: 4)
                            .cornerRadius(2)
                    }
                }
                .padding(.horizontal, 24)
                .padding(.top, 24)
                .padding(.bottom, 32)
                
                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 0) {
                        // Title
                        Text("Discover tastemakers")
                            .font(.system(size: 32, weight: .bold))
                            .foregroundColor(.pairTextPrimary)
                            .padding(.bottom, 8)
                            .padding(.horizontal, 24)
                        
                        // Subtitle
                        Text("Follow curators to see their music discoveries")
                            .font(.system(size: 16))
                            .foregroundColor(.pairTextSecondary)
                            .padding(.bottom, 24)
                            .padding(.horizontal, 24)
                        
                        // Tastemaker cards
                        VStack(spacing: 12) {
                            ForEach(tastemakers) { tastemaker in
                                TastemakerCard(
                                    tastemaker: tastemaker,
                                    isFollowing: followedUsers.contains(tastemaker.id)
                                ) {
                                    withAnimation(.easeOut(duration: 0.2)) {
                                        if followedUsers.contains(tastemaker.id) {
                                            followedUsers.remove(tastemaker.id)
                                        } else {
                                            followedUsers.insert(tastemaker.id)
                                        }
                                    }
                                }
                            }
                        }
                        .padding(.horizontal, 24)
                        
                        Spacer().frame(height: 120)
                    }
                }
                
                // Bottom buttons
                VStack(spacing: 16) {
                    // Continue button
                    Button {
                        completeOnboarding()
                    } label: {
                        if isLoading {
                            ProgressView()
                                .tint(.white)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 18)
                                .background(
                                    RoundedRectangle(cornerRadius: 20)
                                        .fill(Color.pairPurple)
                                )
                        } else {
                            Text(continueButtonText)
                                .font(.system(size: 17, weight: .semibold))
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 18)
                                .background(
                                    RoundedRectangle(cornerRadius: 20)
                                        .fill(Color.pairPurple)
                                )
                                .shadow(color: followedUsers.count > 0 ? Color.pairPurple.opacity(0.3) : .clear, radius: 8, y: 4)
                        }
                    }
                    .disabled(isLoading)
                    
                    // Skip button (only show if no one followed)
                    if followedUsers.isEmpty {
                        Button {
                            completeOnboarding()
                        } label: {
                            Text("Skip for now")
                                .font(.system(size: 15))
                                .foregroundColor(.pairTextSecondary)
                        }
                    }
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 48)
                .background(
                    LinearGradient(
                        colors: [Color.pairBackground.opacity(0), Color.pairBackground],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                    .frame(height: 40)
                    .offset(y: -40)
                    , alignment: .top
                )
            }
        }
    }
    
    private var continueButtonText: String {
        if followedUsers.isEmpty {
            return "Continue"
        } else if followedUsers.count == 1 {
            return "Continue with 1 person"
        } else {
            return "Continue with \(followedUsers.count) people"
        }
    }
    
    private func completeOnboarding() {
        isLoading = true
        
        Task {
            // Save followed users to API
            if !followedUsers.isEmpty {
                do {
                    guard let userId = authManager.currentUser?.id else {
                        finishOnboarding()
                        return
                    }
                    
                    // In a real app, we'd save the followed tastemaker IDs
                    // For now, just mark onboarding as complete
                } catch {
                    print("Failed to save follows: \(error)")
                }
            }
            
            finishOnboarding()
        }
    }
    
    private func finishOnboarding() {
        Task { @MainActor in
            isLoading = false
            
            // Mark onboarding as complete
            if let userId = authManager.currentUser?.id {
                UserDefaults.standard.set(true, forKey: "profileSetupComplete_\(userId)")
            }
            
            isOnboardingComplete = true
        }
    }
}

// MARK: - Tastemaker Card
struct TastemakerCard: View {
    let tastemaker: Tastemaker
    let isFollowing: Bool
    let action: () -> Void
    
    var body: some View {
        HStack(spacing: 16) {
            // Avatar
            AsyncImage(url: URL(string: "https://api.dicebear.com/7.x/avataaars/png?seed=\(tastemaker.avatarSeed)")) { image in
                image
                    .resizable()
                    .scaledToFill()
            } placeholder: {
                Circle()
                    .fill(Color.pairBackgroundSecondary)
                    .overlay {
                        Image(systemName: "person.fill")
                            .foregroundColor(.pairTextTertiary)
                    }
            }
            .frame(width: 56, height: 56)
            .clipShape(Circle())
            
            // Info
            VStack(alignment: .leading, spacing: 4) {
                Text(tastemaker.name)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(.pairTextPrimary)
                
                HStack(spacing: 4) {
                    Text("@\(tastemaker.username)")
                        .font(.system(size: 13))
                        .foregroundColor(.pairTextSecondary)
                    
                    Text("·")
                        .font(.system(size: 13))
                        .foregroundColor(.pairTextSecondary)
                    
                    Text("\(tastemaker.followerCount) fol...")
                        .font(.system(size: 13))
                        .foregroundColor(.pairTextSecondary)
                        .lineLimit(1)
                }
                
                // Genre tags
                HStack(spacing: 8) {
                    ForEach(tastemaker.genres, id: \.self) { genre in
                        Text(genre)
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(.pairPurple)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 4)
                            .background(
                                Capsule()
                                    .fill(Color.pairPurple.opacity(0.1))
                            )
                    }
                }
            }
            
            Spacer()
            
            // Follow button
            Button(action: action) {
                HStack(spacing: 4) {
                    if isFollowing {
                        Image(systemName: "checkmark")
                            .font(.system(size: 12, weight: .semibold))
                    }
                    Text(isFollowing ? "Following" : "Follow")
                        .font(.system(size: 14, weight: .semibold))
                }
                .foregroundColor(isFollowing ? .pairTextPrimary : .white)
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
                .background(
                    Capsule()
                        .fill(isFollowing ? Color.pairBackgroundSecondary : Color.pairPurple)
                )
                .overlay(
                    Capsule()
                        .stroke(isFollowing ? Color.pairCardBorder : Color.clear, lineWidth: 1)
                )
            }
            .buttonStyle(ScaleButtonStyle())
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.pairCardBackground)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color.pairCardBorder, lineWidth: 1)
        )
    }
}

#Preview {
    DiscoverTastemakersView(isOnboardingComplete: .constant(false))
        .environmentObject(AuthManager.shared)
}
