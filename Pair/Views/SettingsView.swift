import SwiftUI

struct SettingsView: View {
    @EnvironmentObject var authManager: AuthManager
    @EnvironmentObject var navigationState: NavigationState
    @Environment(\.dismiss) private var dismiss
    
    @State private var notificationsEnabled = true
    @State private var autoPlayPreviews = true
    @State private var showExplicitContent = true
    
    var body: some View {
        ZStack {
            Color.pairBackground.ignoresSafeArea()
            
            ScrollView {
                VStack(spacing: 0) {
                    // Header with back button
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
                        
                        Spacer()
                    }
                    .padding(.horizontal, 24)
                    .padding(.top, 16)
                    .padding(.bottom, 24)
                    
                    // Title
                    Text("Settings")
                        .font(.system(size: 32, weight: .bold))
                        .foregroundColor(.pairTextPrimary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal, 24)
                        .padding(.bottom, 32)
                    
                    // Account Section
                    SettingsSection(title: "ACCOUNT") {
                        SettingsNavigationItem(
                            title: "Edit Profile",
                            icon: "person"
                        ) {
                            // Navigate to edit profile
                        }
                        
                        SettingsNavigationItem(
                            title: "Connected Accounts",
                            icon: "link"
                        ) {
                            // Navigate to connected accounts
                        }
                        
                        SettingsNavigationItem(
                            title: "Privacy",
                            icon: "lock"
                        ) {
                            // Navigate to privacy settings
                        }
                    }
                    
                    // Preferences Section
                    SettingsSection(title: "PREFERENCES") {
                        SettingsToggleItem(
                            title: "Notifications",
                            description: "Get notified about new pairings",
                            isOn: $notificationsEnabled
                        )
                        
                        SettingsToggleItem(
                            title: "Auto-play Previews",
                            description: "Play song previews automatically",
                            isOn: $autoPlayPreviews
                        )
                        
                        SettingsToggleItem(
                            title: "Explicit Content",
                            description: "Show explicit songs in results",
                            isOn: $showExplicitContent
                        )
                    }
                    
                    // About Section
                    SettingsSection(title: "ABOUT") {
                        SettingsNavigationItem(
                            title: "Help & Support",
                            icon: "questionmark.circle"
                        ) {
                            // Navigate to help
                        }
                        
                        SettingsNavigationItem(
                            title: "Terms of Service",
                            icon: "doc.text"
                        ) {
                            // Navigate to terms
                        }
                        
                        SettingsNavigationItem(
                            title: "Privacy Policy",
                            icon: "shield"
                        ) {
                            // Navigate to privacy policy
                        }
                        
                        SettingsValueItem(
                            title: "Version",
                            value: "1.0.0"
                        )
                    }
                    
                    // Sign Out Button
                    Button {
                        authManager.signOut()
                    } label: {
                        Text("Sign Out")
                            .font(.body)
                            .fontWeight(.medium)
                            .foregroundColor(.red)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(Color.red.opacity(0.3), lineWidth: 1)
                            )
                    }
                    .padding(.horizontal, 24)
                    .padding(.top, 32)
                    .padding(.bottom, 40)
                }
            }
        }
        .navigationTitle("")
        .navigationBarHidden(true)
        .onAppear {
            navigationState.hideNavBar()
        }
    }
}

// MARK: - Settings Section
struct SettingsSection<Content: View>: View {
    let title: String
    @ViewBuilder let content: Content
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Section header
            Text(title)
                .font(.caption)
                .fontWeight(.medium)
                .foregroundColor(.pairTextSecondary)
                .padding(.horizontal, 24)
                .padding(.bottom, 12)
            
            // Section content
            VStack(spacing: 0) {
                content
            }
            .background(Color.pairCardBackground)
            .cornerRadius(12)
            .padding(.horizontal, 24)
        }
        .padding(.bottom, 32)
    }
}

// MARK: - Settings Navigation Item
struct SettingsNavigationItem: View {
    let title: String
    let icon: String
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack {
                Image(systemName: icon)
                    .font(.system(size: 18))
                    .foregroundColor(.pairTextSecondary)
                    .frame(width: 24)
                
                Text(title)
                    .font(.body)
                    .foregroundColor(.pairTextPrimary)
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.system(size: 14))
                    .foregroundColor(.pairTextTertiary)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 16)
        }
        .overlay(
            Divider()
                .padding(.leading, 56),
            alignment: .bottom
        )
    }
}

// MARK: - Settings Toggle Item
struct SettingsToggleItem: View {
    let title: String
    let description: String?
    @Binding var isOn: Bool
    
    init(title: String, description: String? = nil, isOn: Binding<Bool>) {
        self.title = title
        self.description = description
        self._isOn = isOn
    }
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.body)
                    .foregroundColor(.pairTextPrimary)
                
                if let description = description {
                    Text(description)
                        .font(.caption)
                        .foregroundColor(.pairTextSecondary)
                }
            }
            
            Spacer()
            
            Toggle("", isOn: $isOn)
                .tint(.pairPurple)
                .labelsHidden()
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 16)
        .overlay(
            Divider()
                .padding(.leading, 16),
            alignment: .bottom
        )
    }
}

// MARK: - Settings Value Item
struct SettingsValueItem: View {
    let title: String
    let value: String
    
    var body: some View {
        HStack {
            Text(title)
                .font(.body)
                .foregroundColor(.pairTextPrimary)
            
            Spacer()
            
            Text(value)
                .font(.body)
                .foregroundColor(.pairTextSecondary)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 16)
    }
}

#Preview {
    SettingsView()
        .environmentObject(AuthManager.shared)
        .environmentObject(NavigationState())
}
