import SwiftUI

struct OnboardingContainerView: View {
    @EnvironmentObject var authManager: AuthManager
    @Binding var isOnboardingComplete: Bool
    
    @State private var currentStep = 1
    
    var body: some View {
        ZStack {
            switch currentStep {
            case 1:
                ProfileSetupStepView(currentStep: $currentStep)
                    .transition(.asymmetric(insertion: .move(edge: .trailing), removal: .move(edge: .leading)))
            case 2:
                TasteSelectionView(currentStep: $currentStep)
                    .transition(.asymmetric(insertion: .move(edge: .trailing), removal: .move(edge: .leading)))
            case 3:
                AppleMusicOnboardingStep(currentStep: $currentStep)
                    .transition(.asymmetric(insertion: .move(edge: .trailing), removal: .move(edge: .leading)))
            case 4:
                DiscoverTastemakersView(isOnboardingComplete: $isOnboardingComplete)
                    .transition(.asymmetric(insertion: .move(edge: .trailing), removal: .move(edge: .leading)))
            default:
                EmptyView()
            }
        }
        .animation(.easeInOut(duration: 0.3), value: currentStep)
    }
}

// MARK: - Apple Music Onboarding Step (Step 3)
struct AppleMusicOnboardingStep: View {
    @Binding var currentStep: Int
    @StateObject private var appleMusicManager = AppleMusicManager.shared
    @State private var isConnecting = false
    @State private var showError = false
    @State private var errorMessage = ""
    
    var body: some View {
        ZStack {
            Color.pairBackground.ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Progress bar (4 steps now)
                HStack(spacing: 8) {
                    Rectangle()
                        .fill(Color.pairPurple)
                        .frame(height: 4)
                        .cornerRadius(2)
                    
                    Rectangle()
                        .fill(Color.pairPurple)
                        .frame(height: 4)
                        .cornerRadius(2)
                    
                    Rectangle()
                        .fill(Color.pairPurple)
                        .frame(height: 4)
                        .cornerRadius(2)
                    
                    Rectangle()
                        .fill(Color.pairCardBorder)
                        .frame(height: 4)
                        .cornerRadius(2)
                }
                .padding(.horizontal, 24)
                .padding(.top, 24)
                .padding(.bottom, 32)
                
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
                    OnboardingBenefitRow(icon: "waveform.path.ecg", text: "Personalized recommendations")
                    OnboardingBenefitRow(icon: "heart.fill", text: "Save tracks to your library")
                    OnboardingBenefitRow(icon: "sparkles", text: "Weekly drops curated for you")
                }
                .padding(.horizontal, 48)
                
                Spacer()
                
                // Bottom buttons
                VStack(spacing: 16) {
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
                        .cornerRadius(20)
                        .shadow(color: Color(red: 0.98, green: 0.24, blue: 0.35).opacity(0.3), radius: 8, y: 4)
                    }
                    .disabled(isConnecting)
                    
                    // Skip button
                    Button {
                        currentStep = 4
                    } label: {
                        Text("Skip for now")
                            .font(.system(size: 15))
                            .foregroundColor(.pairTextSecondary)
                    }
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 48)
            }
        }
        .alert("Connection Failed", isPresented: $showError) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(errorMessage)
        }
    }
    
    private func connectAppleMusic() {
        isConnecting = true
        
        Task {
            let success = await appleMusicManager.requestAuthorization()
            
            await MainActor.run {
                isConnecting = false
                
                if success {
                    currentStep = 4
                } else {
                    switch appleMusicManager.authorizationStatus {
                    case .denied:
                        errorMessage = "Apple Music access was denied. You can enable it later in Settings."
                        showError = true
                    case .restricted:
                        errorMessage = "Apple Music access is restricted on this device."
                        showError = true
                    default:
                        // User cancelled or other - just move on
                        currentStep = 4
                    }
                }
            }
        }
    }
}

struct OnboardingBenefitRow: View {
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

// MARK: - Profile Setup Step (Step 1)
struct ProfileSetupStepView: View {
    @EnvironmentObject var authManager: AuthManager
    @Binding var currentStep: Int
    
    @State private var displayName = ""
    @State private var username = ""
    @State private var selectedImage: UIImage?
    @State private var showImagePicker = false
    @State private var isLoading = false
    @State private var errorMessage: String?
    
    var body: some View {
        ZStack {
            Color.pairBackground.ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Progress bar (4 steps)
                HStack(spacing: 8) {
                    Rectangle()
                        .fill(Color.pairPurple)
                        .frame(height: 4)
                        .cornerRadius(2)
                    
                    Rectangle()
                        .fill(Color.pairCardBorder)
                        .frame(height: 4)
                        .cornerRadius(2)
                    
                    Rectangle()
                        .fill(Color.pairCardBorder)
                        .frame(height: 4)
                        .cornerRadius(2)
                    
                    Rectangle()
                        .fill(Color.pairCardBorder)
                        .frame(height: 4)
                        .cornerRadius(2)
                }
                .padding(.horizontal, 24)
                .padding(.top, 24)
                .padding(.bottom, 32)
                
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 0) {
                        // Header
                        HStack(spacing: 8) {
                            Image(systemName: "sparkles")
                                .font(.system(size: 16))
                                .foregroundColor(.pairPurple)
                            
                            Text("Welcome to Pair")
                                .font(.system(size: 16, weight: .medium))
                                .foregroundColor(.pairPurple)
                        }
                        .padding(.bottom, 8)
                        
                        // Title
                        Text("Set up your profile")
                            .font(.system(size: 32, weight: .bold))
                            .foregroundColor(.pairTextPrimary)
                            .padding(.bottom, 8)
                        
                        // Subtitle
                        Text("Help others discover your taste in music")
                            .font(.system(size: 16))
                            .foregroundColor(.pairTextSecondary)
                            .padding(.bottom, 40)
                        
                        // Profile photo
                        Button {
                            showImagePicker = true
                        } label: {
                            ZStack {
                                Circle()
                                    .stroke(style: StrokeStyle(lineWidth: 2, dash: [8, 4]))
                                    .foregroundColor(.pairPurple.opacity(0.3))
                                    .frame(width: 120, height: 120)
                                
                                if let image = selectedImage {
                                    Image(uiImage: image)
                                        .resizable()
                                        .scaledToFill()
                                        .frame(width: 116, height: 116)
                                        .clipShape(Circle())
                                        .overlay(alignment: .bottomTrailing) {
                                            Circle()
                                                .fill(Color.pairPurple)
                                                .frame(width: 32, height: 32)
                                                .overlay {
                                                    Image(systemName: "camera.fill")
                                                        .font(.system(size: 14))
                                                        .foregroundColor(.white)
                                                }
                                                .offset(x: 4, y: 4)
                                        }
                                } else {
                                    Circle()
                                        .fill(Color.pairPurple.opacity(0.1))
                                        .frame(width: 116, height: 116)
                                        .overlay {
                                            Image(systemName: "camera")
                                                .font(.system(size: 32))
                                                .foregroundColor(.pairPurple.opacity(0.5))
                                        }
                                }
                            }
                        }
                        .padding(.bottom, 12)
                        
                        Text("Add a profile photo")
                            .font(.system(size: 14))
                            .foregroundColor(.pairTextSecondary)
                            .padding(.bottom, 32)
                        
                        // Form fields
                        VStack(alignment: .leading, spacing: 24) {
                            // Display name
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Display name")
                                    .font(.system(size: 14, weight: .medium))
                                    .foregroundColor(.pairTextPrimary)
                                
                                TextField("How should we call you?", text: $displayName)
                                    .font(.system(size: 16))
                                    .padding(.horizontal, 16)
                                    .padding(.vertical, 16)
                                    .background(
                                        RoundedRectangle(cornerRadius: 16)
                                            .fill(Color.pairBackgroundSecondary)
                                    )
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 16)
                                            .stroke(Color.pairCardBorder, lineWidth: 1)
                                    )
                            }
                            
                            // Username
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Username")
                                    .font(.system(size: 14, weight: .medium))
                                    .foregroundColor(.pairTextPrimary)
                                
                                HStack(spacing: 0) {
                                    Text("@")
                                        .font(.system(size: 16))
                                        .foregroundColor(.pairTextSecondary)
                                        .padding(.leading, 16)
                                    
                                    TextField("username", text: $username)
                                        .font(.system(size: 16))
                                        .autocapitalization(.none)
                                        .autocorrectionDisabled()
                                        .padding(.trailing, 16)
                                        .padding(.vertical, 16)
                                        .onChange(of: username) { newValue in
                                            let sanitized = newValue
                                                .replacingOccurrences(of: "@", with: "")
                                                .replacingOccurrences(of: " ", with: "")
                                                .lowercased()
                                            if sanitized != newValue {
                                                username = sanitized
                                            }
                                        }
                                }
                                .background(
                                    RoundedRectangle(cornerRadius: 16)
                                        .fill(Color.pairBackgroundSecondary)
                                )
                                .overlay(
                                    RoundedRectangle(cornerRadius: 16)
                                        .stroke(Color.pairCardBorder, lineWidth: 1)
                                )
                                
                                if !username.isEmpty {
                                    Text("Your profile will be at pair.app/@\(username)")
                                        .font(.system(size: 12))
                                        .foregroundColor(.pairTextTertiary)
                                        .padding(.top, 4)
                                }
                            }
                            
                            if let error = errorMessage {
                                Text(error)
                                    .font(.caption)
                                    .foregroundColor(.red)
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
                        saveProfile()
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
                            Text("Continue")
                                .font(.system(size: 17, weight: .semibold))
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 18)
                                .background(
                                    RoundedRectangle(cornerRadius: 20)
                                        .fill(canContinue ? Color.pairPurple : Color.pairPurple.opacity(0.5))
                                )
                                .shadow(color: canContinue ? Color.pairPurple.opacity(0.3) : .clear, radius: 8, y: 4)
                        }
                    }
                    .disabled(!canContinue || isLoading)
                    
                    // Skip button
                    Button {
                        currentStep = 2
                    } label: {
                        Text("Skip for now")
                            .font(.system(size: 15))
                            .foregroundColor(.pairTextSecondary)
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
        .sheet(isPresented: $showImagePicker) {
            ImagePicker(image: $selectedImage)
        }
    }
    
    private var canContinue: Bool {
        !displayName.trimmingCharacters(in: .whitespaces).isEmpty
    }
    
    private func saveProfile() {
        isLoading = true
        errorMessage = nil
        
        Task {
            do {
                guard let userId = authManager.currentUser?.id else {
                    currentStep = 2
                    return
                }
                
                // Upload avatar if selected
                var avatarUrl: String?
                if let image = selectedImage {
                    avatarUrl = try await uploadAvatar(image: image, userId: userId)
                }
                
                try await saveProfileToAPI(
                    userId: userId,
                    displayName: displayName.trimmingCharacters(in: .whitespaces),
                    username: username.trimmingCharacters(in: .whitespaces),
                    avatarUrl: avatarUrl
                )
                
                await MainActor.run {
                    isLoading = false
                    currentStep = 2
                }
            } catch {
                await MainActor.run {
                    isLoading = false
                    if let profileError = error as? ProfileSetupError {
                        errorMessage = profileError.localizedDescription
                    } else {
                        errorMessage = "Failed to save profile. Please try again."
                    }
                }
            }
        }
    }
    
    private func uploadAvatar(image: UIImage, userId: String) async throws -> String? {
        let baseURL = ProcessInfo.processInfo.environment["PAIR_API_BASE_URL"] ?? "https://pair-api-seven.vercel.app"
        
        guard let url = URL(string: "\(baseURL)/api/avatars") else {
            return nil
        }
        
        guard let imageData = image.jpegData(compressionQuality: 0.8) else {
            return nil
        }
        
        let boundary = UUID().uuidString
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
        
        var body = Data()
        
        // Add userId field
        body.append("--\(boundary)\r\n".data(using: .utf8)!)
        body.append("Content-Disposition: form-data; name=\"userId\"\r\n\r\n".data(using: .utf8)!)
        body.append("\(userId)\r\n".data(using: .utf8)!)
        
        // Add file field
        body.append("--\(boundary)\r\n".data(using: .utf8)!)
        body.append("Content-Disposition: form-data; name=\"file\"; filename=\"avatar.jpg\"\r\n".data(using: .utf8)!)
        body.append("Content-Type: image/jpeg\r\n\r\n".data(using: .utf8)!)
        body.append(imageData)
        body.append("\r\n".data(using: .utf8)!)
        body.append("--\(boundary)--\r\n".data(using: .utf8)!)
        
        request.httpBody = body
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else {
            return nil
        }
        
        if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
           let avatarUrl = json["avatarUrl"] as? String {
            return avatarUrl
        }
        
        return nil
    }
    
    private func saveProfileToAPI(userId: String, displayName: String, username: String, avatarUrl: String? = nil) async throws {
        let baseURL = ProcessInfo.processInfo.environment["PAIR_API_BASE_URL"] ?? "https://pair-api-seven.vercel.app"
        
        guard let url = URL(string: "\(baseURL)/api/profiles") else {
            throw ProfileSetupError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        var body: [String: Any] = [
            "userId": userId,
            "displayName": displayName
        ]
        
        if !username.isEmpty {
            body["username"] = username
        }
        
        if let avatarUrl = avatarUrl {
            body["avatarUrl"] = avatarUrl
        }
        
        request.httpBody = try JSONSerialization.data(withJSONObject: body)
        
        let (_, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw ProfileSetupError.requestFailed
        }
        
        if httpResponse.statusCode == 409 {
            throw ProfileSetupError.usernameTaken
        }
        
        guard httpResponse.statusCode == 200 || httpResponse.statusCode == 201 else {
            throw ProfileSetupError.requestFailed
        }
    }
}

#Preview {
    OnboardingContainerView(isOnboardingComplete: .constant(false))
        .environmentObject(AuthManager.shared)
}
