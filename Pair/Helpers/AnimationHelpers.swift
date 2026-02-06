import SwiftUI

// MARK: - Animation Constants
struct PairAnimations {
    // Standard easing curve - "Ease out expo" - smooth deceleration
    static let standardEasing = Animation.timingCurve(0.16, 1, 0.3, 1)
    
    // Common durations
    static let instantFeedback: Double = 0.15
    static let buttonHover: Double = 0.2
    static let modalTransition: Double = 0.3
    static let pageTransition: Double = 0.6
    static let pageTransitionLong: Double = 0.8
    static let loadingSpinner: Double = 1.0
    static let ambientAnimation: Double = 3.0
    static let ambientAnimationLong: Double = 15.0
    
    // Stagger delays
    static let listStaggerDelay: Double = 0.05
    static let genreStaggerDelay: Double = 0.08
    static let trackStaggerDelay: Double = 0.06
}

// MARK: - Page Entry Animation Modifier
struct PageEntryAnimation: ViewModifier {
    @State private var isVisible = false
    let delay: Double
    
    init(delay: Double = 0) {
        self.delay = delay
    }
    
    func body(content: Content) -> some View {
        content
            .opacity(isVisible ? 1 : 0)
            .offset(y: isVisible ? 0 : 20)
            .onAppear {
                withAnimation(PairAnimations.standardEasing.duration(PairAnimations.pageTransitionLong).delay(delay)) {
                    isVisible = true
                }
            }
    }
}

// MARK: - Staggered List Item Animation
struct StaggeredListItem: ViewModifier {
    @State private var isVisible = false
    let index: Int
    let baseDelay: Double
    let staggerDelay: Double
    
    init(index: Int, baseDelay: Double = 0.1, staggerDelay: Double = PairAnimations.listStaggerDelay) {
        self.index = index
        self.baseDelay = baseDelay
        self.staggerDelay = staggerDelay
    }
    
    func body(content: Content) -> some View {
        content
            .opacity(isVisible ? 1 : 0)
            .offset(y: isVisible ? 0 : 10)
            .onAppear {
                let delay = baseDelay + (Double(index) * staggerDelay)
                withAnimation(PairAnimations.standardEasing.duration(0.5).delay(delay)) {
                    isVisible = true
                }
            }
    }
}

// MARK: - Button Scale Animation
struct ButtonScaleAnimation: ViewModifier {
    @State private var isPressed = false
    let hoverScale: CGFloat
    let pressScale: CGFloat
    
    init(hoverScale: CGFloat = 1.02, pressScale: CGFloat = 0.98) {
        self.hoverScale = hoverScale
        self.pressScale = pressScale
    }
    
    func body(content: Content) -> some View {
        content
            .scaleEffect(isPressed ? pressScale : 1.0)
            .animation(.easeInOut(duration: PairAnimations.instantFeedback), value: isPressed)
            .simultaneousGesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { _ in isPressed = true }
                    .onEnded { _ in isPressed = false }
            )
    }
}

// MARK: - Breathing Animation
struct BreathingAnimation: ViewModifier {
    @State private var isAnimating = false
    let minScale: CGFloat
    let maxScale: CGFloat
    let minOpacity: Double
    let maxOpacity: Double
    let duration: Double
    
    init(minScale: CGFloat = 1.0, maxScale: CGFloat = 1.05, 
         minOpacity: Double = 0.6, maxOpacity: Double = 0.8,
         duration: Double = 3.0) {
        self.minScale = minScale
        self.maxScale = maxScale
        self.minOpacity = minOpacity
        self.maxOpacity = maxOpacity
        self.duration = duration
    }
    
    func body(content: Content) -> some View {
        content
            .scaleEffect(isAnimating ? maxScale : minScale)
            .opacity(isAnimating ? maxOpacity : minOpacity)
            .onAppear {
                withAnimation(.easeInOut(duration: duration).repeatForever(autoreverses: true)) {
                    isAnimating = true
                }
            }
    }
}

// MARK: - Ambient Glow View
struct AmbientGlowView: View {
    @State private var offset: CGSize = .zero
    @State private var scale: CGFloat = 1.0
    
    let color: Color
    let size: CGFloat
    let blurRadius: CGFloat
    let opacity: Double
    
    init(color: Color = Color.pairPurple, size: CGFloat = 300, blurRadius: CGFloat = 140, opacity: Double = 0.06) {
        self.color = color
        self.size = size
        self.blurRadius = blurRadius
        self.opacity = opacity
    }
    
    var body: some View {
        Circle()
            .fill(color)
            .frame(width: size, height: size)
            .blur(radius: blurRadius)
            .opacity(opacity)
            .offset(offset)
            .scaleEffect(scale)
            .onAppear {
                withAnimation(.easeInOut(duration: 15).repeatForever(autoreverses: true)) {
                    offset = CGSize(width: 50, height: -30)
                    scale = 1.2
                }
            }
    }
}

// MARK: - Waveform Loading Animation
struct WaveformLoadingView: View {
    let barCount: Int
    let color: Color
    
    init(barCount: Int = 5, color: Color = .pairPurple) {
        self.barCount = barCount
        self.color = color
    }
    
    var body: some View {
        HStack(spacing: 4) {
            ForEach(0..<barCount, id: \.self) { index in
                WaveformBar(delay: Double(index) * 0.1, color: color)
            }
        }
        .frame(height: 48)
    }
}

struct WaveformBar: View {
    @State private var isAnimating = false
    let delay: Double
    let color: Color
    
    var body: some View {
        RoundedRectangle(cornerRadius: 2)
            .fill(color)
            .frame(width: 4, height: isAnimating ? 48 : 10)
            .onAppear {
                withAnimation(.easeInOut(duration: 1.2).repeatForever(autoreverses: true).delay(delay)) {
                    isAnimating = true
                }
            }
    }
}

// MARK: - Loading Spinner
struct LoadingSpinner: View {
    @State private var isAnimating = false
    let color: Color
    let size: CGFloat
    
    init(color: Color = .white, size: CGFloat = 20) {
        self.color = color
        self.size = size
    }
    
    var body: some View {
        Circle()
            .trim(from: 0, to: 0.7)
            .stroke(color, lineWidth: 2)
            .frame(width: size, height: size)
            .rotationEffect(.degrees(isAnimating ? 360 : 0))
            .onAppear {
                withAnimation(.linear(duration: 1).repeatForever(autoreverses: false)) {
                    isAnimating = true
                }
            }
    }
}

// MARK: - Slide In From Left Animation
struct SlideInFromLeft: ViewModifier {
    @State private var isVisible = false
    let delay: Double
    
    init(delay: Double = 0) {
        self.delay = delay
    }
    
    func body(content: Content) -> some View {
        content
            .opacity(isVisible ? 1 : 0)
            .offset(x: isVisible ? 0 : -20)
            .onAppear {
                withAnimation(PairAnimations.standardEasing.duration(0.5).delay(delay)) {
                    isVisible = true
                }
            }
    }
}

// MARK: - Modal Entry Animation
struct ModalEntryAnimation: ViewModifier {
    @State private var isVisible = false
    
    func body(content: Content) -> some View {
        content
            .opacity(isVisible ? 1 : 0)
            .onAppear {
                withAnimation(.easeOut(duration: PairAnimations.modalTransition)) {
                    isVisible = true
                }
            }
    }
}

// MARK: - View Extensions
extension View {
    func pageEntryAnimation(delay: Double = 0) -> some View {
        modifier(PageEntryAnimation(delay: delay))
    }
    
    func staggeredListItem(index: Int, baseDelay: Double = 0.1) -> some View {
        modifier(StaggeredListItem(index: index, baseDelay: baseDelay))
    }
    
    func buttonScaleAnimation(hoverScale: CGFloat = 1.02, pressScale: CGFloat = 0.98) -> some View {
        modifier(ButtonScaleAnimation(hoverScale: hoverScale, pressScale: pressScale))
    }
    
    func breathingAnimation(minScale: CGFloat = 1.0, maxScale: CGFloat = 1.05, duration: Double = 3.0) -> some View {
        modifier(BreathingAnimation(minScale: minScale, maxScale: maxScale, duration: duration))
    }
    
    func slideInFromLeft(delay: Double = 0) -> some View {
        modifier(SlideInFromLeft(delay: delay))
    }
    
    func modalEntryAnimation() -> some View {
        modifier(ModalEntryAnimation())
    }
}

// MARK: - Reduced Motion Support
extension View {
    @ViewBuilder
    func respectReducedMotion<T: View>(@ViewBuilder animated: () -> T, @ViewBuilder static staticView: () -> T) -> some View {
        if UIAccessibility.isReduceMotionEnabled {
            staticView()
        } else {
            animated()
        }
    }
}
