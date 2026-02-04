import SwiftUI
import PhotosUI

struct ProfileSetupView: View {
    @EnvironmentObject var authManager: AuthManager
    @Binding var isProfileSetupComplete: Bool
    
    @State private var displayName = ""
    @State private var username = ""
    @State private var selectedImage: UIImage?
    @State private var showImagePicker = false
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var currentStep = 1
    
    private let totalSteps = 3
    
    var body: some View {
        ZStack {
            Color.pairBackground.ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Progress bar
                HStack(spacing: 8) {
                    ForEach(1...totalSteps, id: \.self) { step in
                        Rectangle()
                            .fill(step <= currentStep ? Color.pairPurple : Color.pairCardBorder)
                            .frame(height: 4)
                            .cornerRadius(2)
                    }
                }
                .padding(.horizontal, 24)
                .padding(.top, 24)
                .padding(.bottom, 32)
                
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
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(Color.pairBackgroundSecondary)
                            )
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(Color.pairCardBorder, lineWidth: 1)
                            )
                    }
                    
                    // Username
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Username")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.pairTextPrimary)
                        
                        TextField("@ username", text: $username)
                            .font(.system(size: 16))
                            .autocapitalization(.none)
                            .autocorrectionDisabled()
                            .padding(.horizontal, 16)
                            .padding(.vertical, 16)
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(Color.pairBackgroundSecondary)
                            )
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(Color.pairCardBorder, lineWidth: 1)
                            )
                            .onChange(of: username) { newValue in
                                // Remove @ if user types it and sanitize
                                let sanitized = newValue
                                    .replacingOccurrences(of: "@", with: "")
                                    .replacingOccurrences(of: " ", with: "")
                                    .lowercased()
                                if sanitized != newValue {
                                    username = sanitized
                                }
                            }
                    }
                    
                    if let error = errorMessage {
                        Text(error)
                            .font(.caption)
                            .foregroundColor(.red)
                    }
                }
                .padding(.horizontal, 24)
                
                Spacer()
                
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
                                RoundedRectangle(cornerRadius: 16)
                                    .fill(Color.pairPurple)
                            )
                    } else {
                        Text("Continue")
                            .font(.system(size: 17, weight: .semibold))
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 18)
                            .background(
                                RoundedRectangle(cornerRadius: 16)
                                    .fill(canContinue ? Color.pairPurple : Color.pairPurple.opacity(0.5))
                            )
                    }
                }
                .disabled(!canContinue || isLoading)
                .padding(.horizontal, 24)
                .padding(.bottom, 48)
            }
        }
        .sheet(isPresented: $showImagePicker) {
            ImagePicker(image: $selectedImage)
        }
    }
    
    private var canContinue: Bool {
        !displayName.trimmingCharacters(in: .whitespaces).isEmpty &&
        !username.trimmingCharacters(in: .whitespaces).isEmpty
    }
    
    private func saveProfile() {
        guard canContinue else { return }
        
        isLoading = true
        errorMessage = nil
        
        Task {
            do {
                guard let userId = authManager.currentUser?.id else {
                    throw ProfileSetupError.notAuthenticated
                }
                
                // Save profile to API
                try await saveProfileToAPI(
                    userId: userId,
                    displayName: displayName.trimmingCharacters(in: .whitespaces),
                    username: username.trimmingCharacters(in: .whitespaces)
                )
                
                // Mark profile setup as complete
                UserDefaults.standard.set(true, forKey: "profileSetupComplete_\(userId)")
                
                await MainActor.run {
                    isLoading = false
                    isProfileSetupComplete = true
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
    
    private func saveProfileToAPI(userId: String, displayName: String, username: String) async throws {
        let baseURL = ProcessInfo.processInfo.environment["PAIR_API_BASE_URL"] ?? "https://pair-api-seven.vercel.app"
        
        guard let url = URL(string: "\(baseURL)/api/profiles") else {
            throw ProfileSetupError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let body: [String: Any] = [
            "userId": userId,
            "username": username,
            "displayName": displayName
        ]
        
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

enum ProfileSetupError: Error, LocalizedError {
    case notAuthenticated
    case invalidURL
    case requestFailed
    case usernameTaken
    
    var errorDescription: String? {
        switch self {
        case .notAuthenticated:
            return "Not authenticated"
        case .invalidURL:
            return "Invalid URL"
        case .requestFailed:
            return "Failed to save profile"
        case .usernameTaken:
            return "Username is already taken"
        }
    }
}

// MARK: - Image Picker
struct ImagePicker: UIViewControllerRepresentable {
    @Binding var image: UIImage?
    @Environment(\.dismiss) private var dismiss
    
    func makeUIViewController(context: Context) -> PHPickerViewController {
        var config = PHPickerConfiguration()
        config.filter = .images
        config.selectionLimit = 1
        
        let picker = PHPickerViewController(configuration: config)
        picker.delegate = context.coordinator
        return picker
    }
    
    func updateUIViewController(_ uiViewController: PHPickerViewController, context: Context) {}
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, PHPickerViewControllerDelegate {
        let parent: ImagePicker
        
        init(_ parent: ImagePicker) {
            self.parent = parent
        }
        
        func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
            parent.dismiss()
            
            guard let provider = results.first?.itemProvider,
                  provider.canLoadObject(ofClass: UIImage.self) else { return }
            
            provider.loadObject(ofClass: UIImage.self) { image, _ in
                DispatchQueue.main.async {
                    self.parent.image = image as? UIImage
                }
            }
        }
    }
}

#Preview {
    ProfileSetupView(isProfileSetupComplete: .constant(false))
        .environmentObject(AuthManager.shared)
}
