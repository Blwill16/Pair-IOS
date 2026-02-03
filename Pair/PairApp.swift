import SwiftUI

@main
struct PairApp: App {
    @StateObject private var authManager = AuthManager.shared
    @StateObject private var audioPlayer = AudioPlayer.shared
    @StateObject private var remixManager = RemixManager.shared
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(authManager)
                .environmentObject(audioPlayer)
                .environmentObject(remixManager)
                .onOpenURL { url in
                    handleIncomingURL(url)
                }
        }
    }
    
    private func handleIncomingURL(_ url: URL) {
        guard url.scheme == "pair" else { return }
        
        if url.host == "auth-callback" {
            Task {
                do {
                    try await authManager.handleMagicLinkCallback(url: url)
                } catch {
                    print("Magic link auth failed: \(error)")
                }
            }
        }
    }
}
