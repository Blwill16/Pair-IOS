import Foundation
import AuthenticationServices

@MainActor
class AuthManager: ObservableObject {
    static let shared = AuthManager()
    
    @Published var isAuthenticated = false
    @Published var currentUser: User?
    @Published var isLoading = false
    
    private let supabaseURL: String
    private let supabaseAnonKey: String
    
    init() {
        self.supabaseURL = ProcessInfo.processInfo.environment["SUPABASE_URL"] ?? ""
        self.supabaseAnonKey = ProcessInfo.processInfo.environment["SUPABASE_ANON_KEY"] ?? ""
        
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
    
    func signInWithMagicLink(email: String) async throws {
        isLoading = true
        defer { isLoading = false }
        
        guard let url = URL(string: "\(supabaseURL)/auth/v1/magiclink") else {
            throw AuthError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue(supabaseAnonKey, forHTTPHeaderField: "apikey")
        
        let body: [String: Any] = [
            "email": email
        ]
        
        request.httpBody = try JSONSerialization.data(withJSONObject: body)
        
        let (_, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
            throw AuthError.signInFailed
        }
    }
    
    func signOut() {
        currentUser = nil
        isAuthenticated = false
        UserDefaults.standard.removeObject(forKey: "currentUser")
        UserDefaults.standard.removeObject(forKey: "accessToken")
    }
    
    func continueAsGuest() {
        isAuthenticated = false
        currentUser = nil
    }
}

enum AuthError: Error, LocalizedError {
    case invalidCredential
    case invalidURL
    case signInFailed
    
    var errorDescription: String? {
        switch self {
        case .invalidCredential:
            return "Invalid credential"
        case .invalidURL:
            return "Invalid URL"
        case .signInFailed:
            return "Sign in failed"
        }
    }
}
