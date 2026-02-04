import Foundation
import AuthenticationServices

@MainActor
class AuthManager: ObservableObject {
    static let shared = AuthManager()
    
    @Published var isAuthenticated = false
    @Published var currentUser: User?
    @Published var isLoading = false
    
    // MARK: - Configuration
    private static let defaultSupabaseURL = "https://rsqwasmycfykkrxpjfka.supabase.co"
    private static let defaultSupabaseAnonKey = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InJzcXdhc215Y2Z5a2tyeHBqZmthIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzAwOTAwMzIsImV4cCI6MjA4NTY2NjAzMn0.taf4h0JRJfVQr4Ri_bydgLUE4xghdtRCE0U8d0R9-u4"
    
    private let supabaseURL: String
    private let supabaseAnonKey: String
    
    init() {
        self.supabaseURL = ProcessInfo.processInfo.environment["SUPABASE_URL"] ?? AuthManager.defaultSupabaseURL
        self.supabaseAnonKey = ProcessInfo.processInfo.environment["SUPABASE_ANON_KEY"] ?? AuthManager.defaultSupabaseAnonKey
        
        checkExistingSession()
    }
    
    var userId: String? {
        currentUser?.id
    }
    
    private func checkExistingSession() {
        if let userData = UserDefaults.standard.data(forKey: "currentUser"),
           let user = try? JSONDecoder().decode(User.self, from: userData) {
            self.currentUser = user
            self.isAuthenticated = true
        } else if UserDefaults.standard.bool(forKey: "isGuest") {
            self.isAuthenticated = true
            self.currentUser = nil
        }
    }
    
    func signInWithApple(credential: ASAuthorizationAppleIDCredential) async throws {
        isLoading = true
        defer { isLoading = false }
        
        guard let identityToken = credential.identityToken,
              let tokenString = String(data: identityToken, encoding: .utf8) else {
            throw AuthError.invalidCredential
        }
        
        guard let url = URL(string: "\(supabaseURL)/auth/v1/token?grant_type=id_token") else {
            throw AuthError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue(supabaseAnonKey, forHTTPHeaderField: "apikey")
        
        let body: [String: Any] = [
            "provider": "apple",
            "id_token": tokenString
        ]
        
        request.httpBody = try JSONSerialization.data(withJSONObject: body)
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
            throw AuthError.signInFailed
        }
        
        struct AuthResponse: Codable {
            let user: AuthUser
            let accessToken: String
            
            enum CodingKeys: String, CodingKey {
                case user
                case accessToken = "access_token"
            }
        }
        
        struct AuthUser: Codable {
            let id: String
            let email: String?
        }
        
        let authResponse = try JSONDecoder().decode(AuthResponse.self, from: data)
        
        let user = User(id: authResponse.user.id, email: authResponse.user.email)
        self.currentUser = user
        self.isAuthenticated = true
        
        if let userData = try? JSONEncoder().encode(user) {
            UserDefaults.standard.set(userData, forKey: "currentUser")
        }
        
        UserDefaults.standard.set(authResponse.accessToken, forKey: "accessToken")
    }
    
    func sendOTP(email: String) async throws {
        isLoading = true
        defer { isLoading = false }
        
        guard let url = URL(string: "\(supabaseURL)/auth/v1/otp") else {
            throw AuthError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue(supabaseAnonKey, forHTTPHeaderField: "apikey")
        
        let body: [String: Any] = [
            "email": email,
            "create_user": true
        ]
        
        request.httpBody = try JSONSerialization.data(withJSONObject: body)
        
        let (_, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
            throw AuthError.signInFailed
        }
    }
    
    func verifyOTP(email: String, token: String) async throws {
        isLoading = true
        defer { isLoading = false }
        
        guard let url = URL(string: "\(supabaseURL)/auth/v1/verify") else {
            throw AuthError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue(supabaseAnonKey, forHTTPHeaderField: "apikey")
        
        let body: [String: Any] = [
            "email": email,
            "token": token,
            "type": "email"
        ]
        
        request.httpBody = try JSONSerialization.data(withJSONObject: body)
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
            throw AuthError.invalidCode
        }
        
        struct VerifyResponse: Codable {
            let accessToken: String
            let refreshToken: String?
            let user: VerifyUser
            
            enum CodingKeys: String, CodingKey {
                case accessToken = "access_token"
                case refreshToken = "refresh_token"
                case user
            }
        }
        
        struct VerifyUser: Codable {
            let id: String
            let email: String?
        }
        
        let verifyResponse = try JSONDecoder().decode(VerifyResponse.self, from: data)
        
        UserDefaults.standard.set(verifyResponse.accessToken, forKey: "accessToken")
        if let refreshToken = verifyResponse.refreshToken {
            UserDefaults.standard.set(refreshToken, forKey: "refreshToken")
        }
        
        let user = User(id: verifyResponse.user.id, email: verifyResponse.user.email)
        self.currentUser = user
        self.isAuthenticated = true
        
        if let userData = try? JSONEncoder().encode(user) {
            UserDefaults.standard.set(userData, forKey: "currentUser")
        }
    }
    
    // Keep for backwards compatibility but not used
    func signInWithMagicLink(email: String) async throws {
        try await sendOTP(email: email)
    }
    
    func handleMagicLinkCallback(url: URL) async throws {
        // No longer used with OTP flow
    }
    
    private func fetchCurrentUser(accessToken: String) async throws {
        guard let url = URL(string: "\(supabaseURL)/auth/v1/user") else {
            throw AuthError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
        request.setValue(supabaseAnonKey, forHTTPHeaderField: "apikey")
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
            throw AuthError.signInFailed
        }
        
        struct UserResponse: Codable {
            let id: String
            let email: String?
        }
        
        let userResponse = try JSONDecoder().decode(UserResponse.self, from: data)
        
        let user = User(id: userResponse.id, email: userResponse.email)
        self.currentUser = user
        self.isAuthenticated = true
        
        if let userData = try? JSONEncoder().encode(user) {
            UserDefaults.standard.set(userData, forKey: "currentUser")
        }
    }
    
    func signOut() {
        currentUser = nil
        isAuthenticated = false
        UserDefaults.standard.removeObject(forKey: "currentUser")
        UserDefaults.standard.removeObject(forKey: "accessToken")
        UserDefaults.standard.removeObject(forKey: "isGuest")
    }
    
    func continueAsGuest() {
        isAuthenticated = true
        currentUser = nil
        UserDefaults.standard.set(true, forKey: "isGuest")
    }
}

enum AuthError: Error, LocalizedError {
    case invalidCredential
    case invalidURL
    case signInFailed
    case invalidCode
    
    var errorDescription: String? {
        switch self {
        case .invalidCredential:
            return "Invalid credential"
        case .invalidURL:
            return "Invalid URL"
        case .signInFailed:
            return "Sign in failed"
        case .invalidCode:
            return "Invalid code"
        }
    }
}
