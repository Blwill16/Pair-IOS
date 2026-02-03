import SwiftUI

// MARK: - Brand Colors
extension Color {
    // Primary brand purple
    static let pairPurple = Color(hex: "9b87f5")
    static let pairPurpleDark = Color(hex: "7c6bd4")
    
    // Background colors
    static let pairBackground = Color(hex: "1a1625")
    static let pairBackgroundLight = Color(hex: "2d2640")
    
    // Mood colors for songs
    static let moodPink = Color(hex: "e67e9f")      // Warm nostalgic
    static let moodBlue = Color(hex: "6ba3c9")      // Cool ethereal
    static let moodPurple = Color(hex: "8b7fc9")    // Moody
    static let moodTeal = Color(hex: "5d9b8f")      // Dark teal
    
    // Gradient orb colors
    static let orbPurple = Color(hex: "9b87f5").opacity(0.6)
    static let orbOrange = Color(hex: "f5a962").opacity(0.5)
    static let orbTeal = Color(hex: "62c4b5").opacity(0.5)
    static let orbMagenta = Color(hex: "c962b5").opacity(0.5)
    
    // Glass morphism
    static let glassBackground = Color.white.opacity(0.1)
    static let glassBorder = Color.white.opacity(0.2)
    
    // Text colors
    static let pairTextPrimary = Color.white
    static let pairTextSecondary = Color.white.opacity(0.6)
    static let pairTextTertiary = Color.white.opacity(0.35)
}

// MARK: - Color Hex Initializer
extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3:
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6:
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8:
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (255, 0, 0, 0)
        }
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}

// MARK: - Pair Logo
struct PairLogo: View {
    var size: CGFloat = 60
    var color: Color = .white
    
    var body: some View {
        ZStack {
            Circle()
                .stroke(color, lineWidth: size * 0.05)
                .frame(width: size * 0.7, height: size * 0.7)
                .offset(x: -size * 0.15)
            
            Circle()
                .stroke(color, lineWidth: size * 0.05)
                .frame(width: size * 0.7, height: size * 0.7)
                .offset(x: size * 0.15)
        }
        .frame(width: size, height: size)
    }
}

// MARK: - Animated Gradient Background
struct AnimatedGradientBackground: View {
    @State private var animateOrb1 = false
    @State private var animateOrb2 = false
    @State private var animateOrb3 = false
    @State private var animateOrb4 = false
    
    var body: some View {
        ZStack {
            Color.pairBackground
                .ignoresSafeArea()
            
            // Purple orb
            Circle()
                .fill(
                    RadialGradient(
                        colors: [Color.pairPurple.opacity(0.4), Color.clear],
                        center: .center,
                        startRadius: 0,
                        endRadius: 200
                    )
                )
                .frame(width: 400, height: 400)
                .offset(x: animateOrb1 ? 50 : -50, y: animateOrb1 ? -100 : 100)
                .blur(radius: 60)
            
            // Orange orb
            Circle()
                .fill(
                    RadialGradient(
                        colors: [Color.orbOrange, Color.clear],
                        center: .center,
                        startRadius: 0,
                        endRadius: 150
                    )
                )
                .frame(width: 300, height: 300)
                .offset(x: animateOrb2 ? -80 : 80, y: animateOrb2 ? 150 : -50)
                .blur(radius: 50)
            
            // Teal orb
            Circle()
                .fill(
                    RadialGradient(
                        colors: [Color.orbTeal, Color.clear],
                        center: .center,
                        startRadius: 0,
                        endRadius: 180
                    )
                )
                .frame(width: 350, height: 350)
                .offset(x: animateOrb3 ? 100 : -30, y: animateOrb3 ? 50 : -150)
                .blur(radius: 55)
            
            // Magenta orb
            Circle()
                .fill(
                    RadialGradient(
                        colors: [Color.orbMagenta, Color.clear],
                        center: .center,
                        startRadius: 0,
                        endRadius: 120
                    )
                )
                .frame(width: 250, height: 250)
                .offset(x: animateOrb4 ? -60 : 60, y: animateOrb4 ? -80 : 120)
                .blur(radius: 45)
        }
        .onAppear {
            withAnimation(.easeInOut(duration: 18).repeatForever(autoreverses: true)) {
                animateOrb1 = true
            }
            withAnimation(.easeInOut(duration: 20).repeatForever(autoreverses: true).delay(2)) {
                animateOrb2 = true
            }
            withAnimation(.easeInOut(duration: 16).repeatForever(autoreverses: true).delay(4)) {
                animateOrb3 = true
            }
            withAnimation(.easeInOut(duration: 22).repeatForever(autoreverses: true).delay(1)) {
                animateOrb4 = true
            }
        }
    }
}

// MARK: - Glass Card Modifier
struct GlassCard: ViewModifier {
    var cornerRadius: CGFloat = 24
    
    func body(content: Content) -> some View {
        content
            .background(
                RoundedRectangle(cornerRadius: cornerRadius)
                    .fill(Color.glassBackground)
                    .background(
                        RoundedRectangle(cornerRadius: cornerRadius)
                            .fill(.ultraThinMaterial)
                    )
            )
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius)
                    .stroke(Color.glassBorder, lineWidth: 1)
            )
    }
}

extension View {
    func glassCard(cornerRadius: CGFloat = 24) -> some View {
        modifier(GlassCard(cornerRadius: cornerRadius))
    }
}

// MARK: - Breathing Animation Modifier
struct BreathingAnimation: ViewModifier {
    @State private var isAnimating = false
    var duration: Double = 3.0
    var scale: CGFloat = 1.05
    
    func body(content: Content) -> some View {
        content
            .scaleEffect(isAnimating ? scale : 1.0)
            .opacity(isAnimating ? 1.0 : 0.9)
            .onAppear {
                withAnimation(.easeInOut(duration: duration).repeatForever(autoreverses: true)) {
                    isAnimating = true
                }
            }
    }
}

extension View {
    func breathingAnimation(duration: Double = 3.0, scale: CGFloat = 1.05) -> some View {
        modifier(BreathingAnimation(duration: duration, scale: scale))
    }
}

// MARK: - Primary Button Style
struct PairPrimaryButtonStyle: ButtonStyle {
    var isEnabled: Bool = true
    
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.headline)
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(isEnabled ? Color.pairPurple : Color.pairPurple.opacity(0.5))
            )
            .scaleEffect(configuration.isPressed ? 0.98 : 1.0)
            .animation(.spring(response: 0.3, dampingFraction: 0.6), value: configuration.isPressed)
    }
}

// MARK: - Secondary Button Style
struct PairSecondaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.subheadline)
            .foregroundColor(.pairTextSecondary)
            .padding(.vertical, 12)
            .scaleEffect(configuration.isPressed ? 0.98 : 1.0)
            .animation(.spring(response: 0.3, dampingFraction: 0.6), value: configuration.isPressed)
    }
}

// MARK: - Glass Text Field Style
struct GlassTextFieldStyle: TextFieldStyle {
    func _body(configuration: TextField<Self._Label>) -> some View {
        configuration
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.white.opacity(0.08))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color.white.opacity(0.15), lineWidth: 1)
            )
            .foregroundColor(.white)
    }
}

// MARK: - Floating Navigation Bar
struct FloatingNavBar: View {
    @Binding var selectedTab: Int
    @State private var isBreathing = false
    
    var body: some View {
        HStack(spacing: 0) {
            // Discover
            NavBarItem(
                icon: "magnifyingglass",
                label: "Discover",
                isSelected: selectedTab == 0
            ) {
                selectedTab = 0
            }
            
            // Create (center, larger)
            Button {
                selectedTab = 1
            } label: {
                ZStack {
                    Circle()
                        .fill(selectedTab == 1 ? Color.pairPurple : Color.white.opacity(0.1))
                        .frame(width: 58, height: 58)
                        .shadow(color: selectedTab == 1 ? Color.pairPurple.opacity(0.5) : Color.clear, radius: 12)
                    
                    Image(systemName: "plus")
                        .font(.system(size: 24, weight: .medium))
                        .foregroundColor(selectedTab == 1 ? .white : .pairTextSecondary)
                        .rotationEffect(.degrees(selectedTab == 1 ? 45 : 0))
                }
                .scaleEffect(isBreathing ? 1.05 : 1.0)
            }
            .padding(.horizontal, 16)
            
            // Profile
            NavBarItem(
                icon: "person",
                label: "Profile",
                isSelected: selectedTab == 2
            ) {
                selectedTab = 2
            }
        }
        .padding(.horizontal, 24)
        .padding(.vertical, 12)
        .background(
            Capsule()
                .fill(.ultraThinMaterial)
                .shadow(color: Color.black.opacity(0.2), radius: 20, y: 10)
        )
        .overlay(
            Capsule()
                .stroke(Color.white.opacity(0.1), lineWidth: 1)
        )
        .onAppear {
            withAnimation(.easeInOut(duration: 3).repeatForever(autoreverses: true)) {
                isBreathing = true
            }
        }
    }
}

struct NavBarItem: View {
    let icon: String
    let label: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.system(size: 20))
                    .foregroundColor(isSelected ? .pairPurple : .pairTextSecondary)
                
                Text(label)
                    .font(.caption2)
                    .foregroundColor(isSelected ? .pairPurple : .pairTextSecondary)
            }
            .frame(width: 52, height: 52)
        }
    }
}

// MARK: - Back Button Style
struct PairBackButton: View {
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        Button {
            dismiss()
        } label: {
            HStack(spacing: 4) {
                Image(systemName: "chevron.left")
                    .font(.system(size: 14, weight: .medium))
                Text("Back")
                    .font(.subheadline)
            }
            .foregroundColor(.pairTextTertiary)
        }
    }
}

// MARK: - Cycling Placeholder Text
struct CyclingPlaceholder: View {
    let placeholders: [String]
    @State private var currentIndex = 0
    @State private var opacity: Double = 1.0
    
    var body: some View {
        Text(placeholders[currentIndex])
            .opacity(opacity)
            .onAppear {
                startCycling()
            }
    }
    
    private func startCycling() {
        Timer.scheduledTimer(withTimeInterval: 3.0, repeats: true) { _ in
            withAnimation(.easeOut(duration: 0.3)) {
                opacity = 0
            }
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                currentIndex = (currentIndex + 1) % placeholders.count
                withAnimation(.easeIn(duration: 0.3)) {
                    opacity = 1
                }
            }
        }
    }
}

#Preview("Design System") {
    ZStack {
        AnimatedGradientBackground()
        
        VStack(spacing: 32) {
            PairLogo(size: 80)
                .breathingAnimation()
            
            Text("Pair")
                .font(.largeTitle)
                .fontWeight(.bold)
                .foregroundColor(.white)
            
            VStack(spacing: 16) {
                TextField("Email", text: .constant(""))
                    .textFieldStyle(GlassTextFieldStyle())
                
                Button("Continue with Spotify") {}
                    .buttonStyle(PairPrimaryButtonStyle())
                
                Button("Continue as guest") {}
                    .buttonStyle(PairSecondaryButtonStyle())
            }
            .padding(.horizontal, 32)
            .padding(.vertical, 24)
            .glassCard()
        }
        .padding()
    }
}
