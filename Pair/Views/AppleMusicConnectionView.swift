import SwiftUI
import MusicKit

struct AppleMusicConnectionView: View {
    @StateObject private var appleMusicManager = AppleMusicManager.shared
    @Environment(\.dismiss) private var dismiss
    
    var onConnected: (() -> Void)?
    var showSkipOption: Bool = true
    
    @State private var isConnecting = false
    @State private var showError = false
    @State private var errorMessage = ""
    
    var body: some View {
        ZStack {
            Color.pairBackground.ignoresSafeArea()
            
            VStack(spacing: 0) {
                Spacer()
                
                // Apple Music icon
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [Color(red: 0.98, green: 0.24, blue: 0.35), Color(red: 0.85, green: 0.15, blue: 0.45)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 120, height: 120)
                    
                    Image(systemName: "music.note")
                        .font(.system(size: 48, weight: .medium))
                        .foregroundColor(.white)
                }
                .padding(.bottom, 32)
                
                // Title
                Text("Connect Apple Music")
                    .font(.system(size: 28, weight: .bold))
                    .foregroundColor(.pairTextPrimary)
                    .padding(.bottom, 12)
                
                // Description
                Text("Pair uses your music library to understand\nyour taste and find tracks you'll love")
                    .font(.system(size: 16))
                    .foregroundColor(.pairTextSecondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
                    .padding(.bottom, 40)
                
                // Benefits list
                VStack(alignment: .leading, spacing: 16) {
                    BenefitRow(icon: "waveform.path.ecg", text: "Personalized recommendations based on your taste")
                    BenefitRow(icon: "heart.fill", text: "Save tracks directly to your library")
                    BenefitRow(icon: "music.note.list", text: "Create playlists from your pairings")
                    BenefitRow(icon: "sparkles", text: "Weekly drops curated just for you")
                }
                .padding(.horizontal, 32)
                .padding(.bottom, 48)
                
                Spacer()
                
                // Connect button
                Button {
                    connectAppleMusic()
                } label: {
                    HStack(spacing: 12) {
                        if isConnecting {
                            ProgressView()
                                .tint(.white)
                        } else {
                            Image(systemName: "applelogo")
                                .font(.system(size: 18))
                            Text("Connect Apple Music")
                                .font(.system(size: 17, weight: .semibold))
                        }
                    }
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 18)
                    .background(
                        LinearGradient(
                            colors: [Color(red: 0.98, green: 0.24, blue: 0.35), Color(red: 0.85, green: 0.15, blue: 0.45)],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .cornerRadius(16)
                }
                .disabled(isConnecting)
                .padding(.horizontal, 24)
                
                // Skip button (optional)
                if showSkipOption {
                    Button {
                        dismiss()
                    } label: {
                        Text("Skip for now")
                            .font(.system(size: 15))
                            .foregroundColor(.pairTextSecondary)
                    }
                    .padding(.top, 16)
                }
                
                // Privacy note
                Text("We only access your music to improve recommendations.\nYour data is never shared.")
                    .font(.system(size: 12))
                    .foregroundColor(.pairTextTertiary)
                    .multilineTextAlignment(.center)
                    .padding(.top, 24)
                    .padding(.bottom, 32)
            }
        }
        .alert("Connection Failed", isPresented: $showError) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(errorMessage)
        }
        .onChange(of: appleMusicManager.isAuthorized) { _, isAuthorized in
            if isAuthorized {
                onConnected?()
                dismiss()
            }
        }
    }
    
    private func connectAppleMusic() {
        isConnecting = true
        
        Task {
            let success = await appleMusicManager.requestAuthorization()
            
            await MainActor.run {
                isConnecting = false
                
                if !success {
                    switch appleMusicManager.authorizationStatus {
                    case .denied:
                        errorMessage = "Apple Music access was denied. Please enable it in Settings > Privacy > Media & Apple Music."
                    case .restricted:
                        errorMessage = "Apple Music access is restricted on this device."
                    default:
                        errorMessage = "Failed to connect to Apple Music. Please try again."
                    }
                    showError = true
                }
            }
        }
    }
}

// MARK: - Benefit Row
struct BenefitRow: View {
    let icon: String
    let text: String
    
    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: icon)
                .font(.system(size: 20))
                .foregroundColor(.pairPurple)
                .frame(width: 32)
            
            Text(text)
                .font(.system(size: 15))
                .foregroundColor(.pairTextPrimary)
            
            Spacer()
        }
    }
}

// MARK: - Apple Music Status View (for Settings)
struct AppleMusicStatusView: View {
    @StateObject private var appleMusicManager = AppleMusicManager.shared
    @State private var showConnectionSheet = false
    
    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 16) {
                // Apple Music icon
                ZStack {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(
                            LinearGradient(
                                colors: [Color(red: 0.98, green: 0.24, blue: 0.35), Color(red: 0.85, green: 0.15, blue: 0.45)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 48, height: 48)
                    
                    Image(systemName: "music.note")
                        .font(.system(size: 20, weight: .medium))
                        .foregroundColor(.white)
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("Apple Music")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.pairTextPrimary)
                    
                    if appleMusicManager.isAuthorized {
                        HStack(spacing: 4) {
                            Image(systemName: "checkmark.circle.fill")
                                .font(.system(size: 12))
                                .foregroundColor(.green)
                            Text("Connected")
                                .font(.system(size: 13))
                                .foregroundColor(.green)
                        }
                    } else {
                        Text("Not connected")
                            .font(.system(size: 13))
                            .foregroundColor(.pairTextSecondary)
                    }
                }
                
                Spacer()
                
                if !appleMusicManager.isAuthorized {
                    Button {
                        showConnectionSheet = true
                    } label: {
                        Text("Connect")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.white)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 8)
                            .background(Color.pairPurple)
                            .cornerRadius(8)
                    }
                } else {
                    Image(systemName: "chevron.right")
                        .font(.system(size: 14))
                        .foregroundColor(.pairTextTertiary)
                }
            }
            .padding(16)
            .background(Color.pairCardBackground)
            .cornerRadius(16)
        }
        .sheet(isPresented: $showConnectionSheet) {
            AppleMusicConnectionView(showSkipOption: false)
        }
    }
}

// MARK: - Compact Connection Button (for inline use)
struct AppleMusicConnectButton: View {
    @StateObject private var appleMusicManager = AppleMusicManager.shared
    @State private var showConnectionSheet = false
    @State private var isConnecting = false
    
    var compact: Bool = false
    
    var body: some View {
        if appleMusicManager.isAuthorized {
            HStack(spacing: 8) {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundColor(.green)
                Text("Apple Music Connected")
                    .font(.system(size: compact ? 13 : 15))
                    .foregroundColor(.pairTextSecondary)
            }
        } else {
            Button {
                showConnectionSheet = true
            } label: {
                HStack(spacing: 8) {
                    Image(systemName: "applelogo")
                        .font(.system(size: compact ? 14 : 16))
                    Text(compact ? "Connect" : "Connect Apple Music")
                        .font(.system(size: compact ? 13 : 15, weight: .medium))
                }
                .foregroundColor(.white)
                .padding(.horizontal, compact ? 12 : 20)
                .padding(.vertical, compact ? 8 : 12)
                .background(
                    LinearGradient(
                        colors: [Color(red: 0.98, green: 0.24, blue: 0.35), Color(red: 0.85, green: 0.15, blue: 0.45)],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .cornerRadius(compact ? 8 : 12)
            }
            .sheet(isPresented: $showConnectionSheet) {
                AppleMusicConnectionView(showSkipOption: true)
            }
        }
    }
}

#Preview {
    AppleMusicConnectionView()
}
