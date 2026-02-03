import SwiftUI

// MARK: - Brand Colors
extension Color {
    // Primary brand purple
    static let pairPurple = Color(hex: "9b87f5")
    static let pairPurpleDark = Color(hex: "7c6bd4")
    
    // Background colors - Dark (for login only)
    static let pairBackgroundDark = Color(hex: "1a1625")
    
    // Background colors - Light (for main app screens)
    static let pairBackground = Color(hex: "fafafa")
    static let pairBackgroundSecondary = Color(hex: "f5f5f5")
    
    // Mood colors for songs
    static let moodPink = Color(hex: "e67e9f")      // Warm nostalgic
    static let moodBlue = Color(hex: "6ba3c9")      // Cool ethereal
    static let moodPurple = Color(hex: "8b7fc9")    // Moody
    static let moodTeal = Color(hex: "5d9b8f")      // Dark teal
    
    // Gradient orb colors (for login screen)
    static let orbPurple = Color(hex: "9b87f5").opacity(0.6)
    static let orbOrange = Color(hex: "f5a962").opacity(0.5)
    static let orbTeal = Color(hex: "62c4b5").opacity(0.5)
    static let orbMagenta = Color(hex: "c962b5").opacity(0.5)
    
    // Glass morphism (for login screen)
    static let glassBackground = Color.white.opacity(0.1)
    static let glassBorder = Color.white.opacity(0.2)
    
    // Text colors - Light theme (main app)
    static let pairTextPrimary = Color(hex: "1a1a1a")
    static let pairTextSecondary = Color(hex: "666666")
    static let pairTextTertiary = Color(hex: "999999")
    
    // Text colors - Dark theme (login only)
    static let pairTextPrimaryDark = Color.white
    static let pairTextSecondaryDark = Color.white.opacity(0.6)
    static let pairTextTertiaryDark = Color.white.opacity(0.35)
    
    // Card colors
    static let pairCardBackground = Color.white
    static let pairCardBorder = Color(hex: "e5e5e5")
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

// MARK: - Film Grain Texture Overlay
struct FilmGrainOverlay: View {
    @State private var noiseOffset: CGFloat = 0
    
    var body: some View {
        GeometryReader { geometry in
            Canvas { context, size in
                // Create noise pattern
                for _ in 0..<Int(size.width * size.height * 0.003) {
                    let x = CGFloat.random(in: 0..<size.width)
                    let y = CGFloat.random(in: 0..<size.height)
                    let opacity = Double.random(in: 0.02...0.06)
                    
                    context.fill(
                        Path(ellipseIn: CGRect(x: x, y: y, width: 1.5, height: 1.5)),
                        with: .color(Color.white.opacity(opacity))
                    )
                }
            }
            .blendMode(.overlay)
        }
        .allowsHitTesting(false)
    }
}

// MARK: - Animated Gradient Background (Login screen only)
struct AnimatedGradientBackground: View {
    @State private var animateGradient = false
    
    var body: some View {
        ZStack {
            // Base dark background
            Color.pairBackgroundDark
                .ignoresSafeArea()
            
            // Animated radial gradient - slow drift (30s as per Figma spec)
            RadialGradient(
                colors: [
                    Color.pairPurple.opacity(0.35),
                    Color.pairPurple.opacity(0.15),
                    Color.pairPurple.opacity(0.05),
                    Color.clear
                ],
                center: animateGradient ? .topTrailing : .topLeading,
                startRadius: 0,
                endRadius: 500
            )
            .ignoresSafeArea()
            .animation(.easeInOut(duration: 30).repeatForever(autoreverses: true), value: animateGradient)
            
            // Secondary subtle gradient for depth
            RadialGradient(
                colors: [
                    Color.orbMagenta.opacity(0.15),
                    Color.clear
                ],
                center: animateGradient ? .bottomLeading : .bottomTrailing,
                startRadius: 0,
                endRadius: 400
            )
            .ignoresSafeArea()
            .animation(.easeInOut(duration: 25).repeatForever(autoreverses: true), value: animateGradient)
            
            // Film grain texture overlay (3% opacity, barely perceptible)
            FilmGrainOverlay()
                .opacity(0.03)
                .ignoresSafeArea()
        }
        .onAppear {
            animateGradient = true
        }
    }
}

// MARK: - Logo Glow Effect
struct LogoGlowModifier: ViewModifier {
    @State private var glowIntensity: Double = 0.4
    
    func body(content: Content) -> some View {
        content
            .shadow(color: Color.pairPurple.opacity(glowIntensity), radius: 40, x: 0, y: 0)
            .shadow(color: Color.pairPurple.opacity(glowIntensity * 0.5), radius: 20, x: 0, y: 0)
            .onAppear {
                withAnimation(.easeInOut(duration: 3).repeatForever(autoreverses: true)) {
                    glowIntensity = 0.6
                }
            }
    }
}

extension View {
    func logoGlow() -> some View {
        modifier(LogoGlowModifier())
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
            // Discover (compass icon)
            NavBarItem(
                icon: "safari",
                isSelected: selectedTab == 0
            ) {
                selectedTab = 0
            }
            
            // Create (center, larger with + icon)
            Button {
                selectedTab = 1
            } label: {
                ZStack {
                    Circle()
                        .fill(selectedTab == 1 ? Color.pairPurple : Color(hex: "f0f0f0"))
                        .frame(width: 52, height: 52)
                        .shadow(color: selectedTab == 1 ? Color.pairPurple.opacity(0.3) : Color.black.opacity(0.1), radius: 8, y: 2)
                    
                    Image(systemName: selectedTab == 1 ? "xmark" : "plus")
                        .font(.system(size: 22, weight: .medium))
                        .foregroundColor(selectedTab == 1 ? .white : .pairTextSecondary)
                }
                .scaleEffect(isBreathing && selectedTab != 1 ? 1.03 : 1.0)
            }
            .padding(.horizontal, 20)
            
            // Profile (person icon)
            NavBarItem(
                icon: "person",
                isSelected: selectedTab == 2
            ) {
                selectedTab = 2
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 10)
        .background(
            Capsule()
                .fill(Color.white)
                .shadow(color: Color.black.opacity(0.12), radius: 16, y: 4)
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
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Image(systemName: icon)
                .font(.system(size: 22))
                .foregroundColor(isSelected ? .pairPurple : .pairTextTertiary)
                .frame(width: 44, height: 44)
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
