import SwiftUI

@main
struct PairApp: App {
    @StateObject private var authManager = AuthManager.shared
    @StateObject private var audioPlayer = AudioPlayer.shared
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(authManager)
                .environmentObject(audioPlayer)
        }
    }
}
