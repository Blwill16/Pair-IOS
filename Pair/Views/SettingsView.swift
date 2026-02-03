import SwiftUI

struct SettingsView: View {
    @EnvironmentObject var authManager: AuthManager
    @EnvironmentObject var navigationState: NavigationState
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        ZStack {
            Color.pairBackground.ignoresSafeArea()
            
            ScrollView {
                VStack(alignment: .leading, spacing: 0) {
                    // Header with back button
                    Button {
                        dismiss()
                    } label: {
                        HStack(spacing: 4) {
                            Image(systemName: "arrow.left")
                                .font(.system(size: 14))
                            Text("Back")
                                .font(.subheadline)
                        }
                        .foregroundColor(.pairTextPrimary)
                    }
                    .padding(.horizontal, 24)
                    .padding(.top, 16)
                    .padding(.bottom, 24)
                    
                    // Title
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Settings")
                            .font(.system(size: 32, weight: .bold))
                            .foregroundColor(.pairTextPrimary)
                        
                        Text("Preferences and account")
                            .font(.body)
                            .foregroundColor(.pairTextSecondary)
                    }
                    .padding(.horizontal, 24)
                    .padding(.bottom, 40)
                    
                    // Account Section
                    SettingsSectionHeader(title: "Account")
                        .padding(.horizontal, 24)
                        .padding(.bottom, 16)
                    
                    VStack(alignment: .leading, spacing: 0) {
                        SettingsTextItem(title: "Edit Profile") {
                            // Navigate to edit profile
                        }
                        
                        SettingsTextItem(title: "Privacy") {
                            // Navigate to privacy settings
                        }
                        
                        SettingsTextItem(title: "Notifications") {
                            // Navigate to notifications
                        }
                    }
                    .padding(.horizontal, 24)
                    .padding(.bottom, 40)
                    
                    // Preferences Section
                    SettingsSectionHeader(title: "Preferences")
                        .padding(.horizontal, 24)
                        .padding(.bottom, 16)
                    
                    VStack(alignment: .leading, spacing: 0) {
                        SettingsTextItem(title: "Music Quality") {
                            // Navigate to music quality
                        }
                        
                        SettingsTextItem(title: "Playback") {
                            // Navigate to playback settings
                        }
                    }
                    .padding(.horizontal, 24)
                    .padding(.bottom, 40)
                    
                    // About Section
                    SettingsSectionHeader(title: "About")
                        .padding(.horizontal, 24)
                        .padding(.bottom, 16)
                    
                    VStack(alignment: .leading, spacing: 0) {
                        SettingsTextItem(title: "Help & Support") {
                            // Navigate to help
                        }
                        
                        SettingsTextItem(title: "Terms & Privacy Policy") {
                            // Navigate to terms
                        }
                        
                        SettingsTextItem(title: "About Pair") {
                            // Navigate to about
                        }
                    }
                    .padding(.horizontal, 24)
                    .padding(.bottom, 40)
                    
                    // Sign Out Button
                    Button {
                        authManager.signOut()
                        dismiss()
                    } label: {
                        Text("Sign Out")
                            .font(.body)
                            .foregroundColor(.pairTextPrimary)
                    }
                    .padding(.horizontal, 24)
                    .padding(.bottom, 60)
                    
                    Spacer(minLength: 40)
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

// MARK: - Settings Section Header (bold title)
struct SettingsSectionHeader: View {
    let title: String
    
    var body: some View {
        Text(title)
            .font(.system(size: 22, weight: .bold))
            .foregroundColor(.pairTextPrimary)
    }
}

// MARK: - Settings Text Item (simple text link)
struct SettingsTextItem: View {
    let title: String
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.body)
                .foregroundColor(.pairTextSecondary)
                .padding(.vertical, 12)
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
