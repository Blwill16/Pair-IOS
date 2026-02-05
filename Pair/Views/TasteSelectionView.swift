import SwiftUI

struct TasteSelectionView: View {
    @EnvironmentObject var authManager: AuthManager
    @Binding var currentStep: Int
    
    @State private var selectedGenres: Set<String> = []
    @State private var selectedMoods: Set<String> = []
    @State private var selectedEras: Set<String> = []
    @State private var isLoading = false
    
    private let genres = [
        ("Indie", Color(red: 0.91, green: 0.45, blue: 0.45), Color(red: 0.95, green: 0.60, blue: 0.60)),
        ("Electronic", Color(red: 0.40, green: 0.75, blue: 0.75), Color(red: 0.50, green: 0.85, blue: 0.85)),
        ("R&B", Color(red: 0.61, green: 0.53, blue: 0.96), Color(red: 0.71, green: 0.63, blue: 1.0)),
        ("Jazz", Color(red: 0.90, green: 0.80, blue: 0.45), Color(red: 0.95, green: 0.85, blue: 0.55)),
        ("Rock", Color(red: 0.55, green: 0.80, blue: 0.70), Color(red: 0.65, green: 0.90, blue: 0.80)),
        ("Hip-Hop", Color(red: 0.95, green: 0.65, blue: 0.65), Color(red: 1.0, green: 0.75, blue: 0.75)),
        ("Folk", Color(red: 0.75, green: 0.70, blue: 0.90), Color(red: 0.85, green: 0.80, blue: 1.0)),
        ("Soul", Color(red: 0.95, green: 0.70, blue: 0.60), Color(red: 1.0, green: 0.80, blue: 0.70))
    ]
    
    private let moods = ["Melancholic", "Energetic", "Dreamy", "Intimate", "Experimental", "Nostalgic"]
    private let eras = ["60s & 70s", "80s & 90s", "2000s", "Modern"]
    
    private var totalSelections: Int {
        selectedGenres.count + selectedMoods.count + selectedEras.count
    }
    
    var body: some View {
        ZStack {
            Color.pairBackground.ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Progress bar (4 steps)
                HStack(spacing: 8) {
                    Rectangle()
                        .fill(Color.pairPurple)
                        .frame(height: 4)
                        .cornerRadius(2)
                    
                    Rectangle()
                        .fill(Color.pairPurple)
                        .frame(height: 4)
                        .cornerRadius(2)
                    
                    Rectangle()
                        .fill(Color.pairCardBorder)
                        .frame(height: 4)
                        .cornerRadius(2)
                    
                    Rectangle()
                        .fill(Color.pairCardBorder)
                        .frame(height: 4)
                        .cornerRadius(2)
                }
                .padding(.horizontal, 24)
                .padding(.top, 24)
                .padding(.bottom, 32)
                
                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 0) {
                        // Header
                        HStack(spacing: 8) {
                            Image(systemName: "sparkles")
                                .font(.system(size: 16))
                                .foregroundColor(.pairPurple)
                            
                            Text("Your taste")
                                .font(.system(size: 16, weight: .medium))
                                .foregroundColor(.pairPurple)
                        }
                        .padding(.bottom, 8)
                        .padding(.horizontal, 24)
                        
                        // Title
                        Text("What moves you?")
                            .font(.system(size: 32, weight: .bold))
                            .foregroundColor(.pairTextPrimary)
                            .padding(.bottom, 8)
                            .padding(.horizontal, 24)
                        
                        // Subtitle
                        Text("Choose the sounds, feelings, and eras that resonate")
                            .font(.system(size: 16))
                            .foregroundColor(.pairTextSecondary)
                            .padding(.bottom, 32)
                            .padding(.horizontal, 24)
                        
                        // Genres section
                        Text("Genres")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.pairTextPrimary)
                            .padding(.bottom, 12)
                            .padding(.horizontal, 24)
                        
                        FlowLayout(spacing: 10) {
                            ForEach(genres, id: \.0) { genre, color1, color2 in
                                GenrePill(
                                    title: genre,
                                    gradientColors: [color1, color2],
                                    isSelected: selectedGenres.contains(genre)
                                ) {
                                    withAnimation(.easeOut(duration: 0.2)) {
                                        if selectedGenres.contains(genre) {
                                            selectedGenres.remove(genre)
                                        } else {
                                            selectedGenres.insert(genre)
                                        }
                                    }
                                }
                            }
                        }
                        .padding(.horizontal, 24)
                        .padding(.bottom, 28)
                        
                        // Moods section
                        Text("Moods")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.pairTextPrimary)
                            .padding(.bottom, 12)
                            .padding(.horizontal, 24)
                        
                        FlowLayout(spacing: 10) {
                            ForEach(moods, id: \.self) { mood in
                                MoodEraPill(
                                    title: mood,
                                    isSelected: selectedMoods.contains(mood)
                                ) {
                                    withAnimation(.easeOut(duration: 0.2)) {
                                        if selectedMoods.contains(mood) {
                                            selectedMoods.remove(mood)
                                        } else {
                                            selectedMoods.insert(mood)
                                        }
                                    }
                                }
                            }
                        }
                        .padding(.horizontal, 24)
                        .padding(.bottom, 28)
                        
                        // Eras section
                        Text("Eras")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.pairTextPrimary)
                            .padding(.bottom, 12)
                            .padding(.horizontal, 24)
                        
                        FlowLayout(spacing: 10) {
                            ForEach(eras, id: \.self) { era in
                                MoodEraPill(
                                    title: era,
                                    isSelected: selectedEras.contains(era)
                                ) {
                                    withAnimation(.easeOut(duration: 0.2)) {
                                        if selectedEras.contains(era) {
                                            selectedEras.remove(era)
                                        } else {
                                            selectedEras.insert(era)
                                        }
                                    }
                                }
                            }
                        }
                        .padding(.horizontal, 24)
                        .padding(.bottom, 24)
                        
                        // Selection count badge
                        if totalSelections > 0 {
                            HStack(spacing: 6) {
                                Image(systemName: "sparkles")
                                    .font(.system(size: 12))
                                Text("\(totalSelections) selections")
                                    .font(.system(size: 14, weight: .medium))
                            }
                            .foregroundColor(.pairPurple)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 10)
                            .background(
                                Capsule()
                                    .fill(Color.pairPurple.opacity(0.1))
                            )
                            .padding(.horizontal, 24)
                            .padding(.bottom, 24)
                        }
                        
                        Spacer().frame(height: 120)
                    }
                }
                
                // Bottom buttons
                VStack(spacing: 16) {
                    // Continue button
                    Button {
                        saveTasteAndContinue()
                    } label: {
                        if isLoading {
                            ProgressView()
                                .tint(.white)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 18)
                                .background(
                                    RoundedRectangle(cornerRadius: 20)
                                        .fill(Color.pairPurple)
                                )
                        } else {
                            Text("Continue")
                                .font(.system(size: 17, weight: .semibold))
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 18)
                                .background(
                                    RoundedRectangle(cornerRadius: 20)
                                        .fill(totalSelections > 0 ? Color.pairPurple : Color.pairPurple.opacity(0.5))
                                )
                                .shadow(color: totalSelections > 0 ? Color.pairPurple.opacity(0.3) : .clear, radius: 8, y: 4)
                        }
                    }
                    .disabled(totalSelections == 0 || isLoading)
                    
                    // Skip button
                    Button {
                        currentStep = 3
                    } label: {
                        Text("Skip for now")
                            .font(.system(size: 15))
                            .foregroundColor(.pairTextSecondary)
                    }
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 48)
                .background(
                    LinearGradient(
                        colors: [Color.pairBackground.opacity(0), Color.pairBackground],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                    .frame(height: 40)
                    .offset(y: -40)
                    , alignment: .top
                )
            }
        }
    }
    
    private func saveTasteAndContinue() {
        isLoading = true
        
        Task {
            // Save taste preferences to API
            do {
                guard let userId = authManager.currentUser?.id else {
                    currentStep = 3
                    return
                }
                
                try await saveTasteToAPI(
                    userId: userId,
                    genres: Array(selectedGenres),
                    moods: Array(selectedMoods),
                    eras: Array(selectedEras)
                )
            } catch {
                print("Failed to save taste: \(error)")
            }
            
            await MainActor.run {
                isLoading = false
                currentStep = 3
            }
        }
    }
    
    private func saveTasteToAPI(userId: String, genres: [String], moods: [String], eras: [String]) async throws {
        let baseURL = ProcessInfo.processInfo.environment["PAIR_API_BASE_URL"] ?? "https://pair-api-seven.vercel.app"
        
        guard let url = URL(string: "\(baseURL)/api/brain/taste") else { return }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let body: [String: Any] = [
            "userId": userId,
            "genres": genres,
            "moods": moods,
            "eras": eras
        ]
        
        request.httpBody = try JSONSerialization.data(withJSONObject: body)
        
        let (_, _) = try await URLSession.shared.data(for: request)
    }
}

// MARK: - Genre Pill with Gradient
struct GenrePill: View {
    let title: String
    let gradientColors: [Color]
    let isSelected: Bool
    let action: () -> Void
    
    @State private var isPressed = false
    
    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 15, weight: .medium))
                .foregroundColor(isSelected ? .white : .pairTextPrimary)
                .padding(.horizontal, 20)
                .padding(.vertical, 12)
                .background(
                    Group {
                        if isSelected {
                            LinearGradient(
                                colors: gradientColors,
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        } else {
                            Color(red: 0.96, green: 0.96, blue: 0.96)
                        }
                    }
                )
                .clipShape(Capsule())
                .overlay(
                    Capsule()
                        .stroke(isSelected ? Color.clear : Color.pairCardBorder, lineWidth: 1)
                )
        }
        .buttonStyle(ScaleButtonStyle())
    }
}

// MARK: - Mood/Era Pill (no gradient)
struct MoodEraPill: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 15, weight: .medium))
                .foregroundColor(isSelected ? .pairPurple : .pairTextPrimary)
                .padding(.horizontal, 20)
                .padding(.vertical, 12)
                .background(
                    isSelected ? Color.pairPurple.opacity(0.1) : Color(red: 0.96, green: 0.96, blue: 0.96)
                )
                .clipShape(Capsule())
                .overlay(
                    Capsule()
                        .stroke(isSelected ? Color.pairPurple.opacity(0.3) : Color.pairCardBorder, lineWidth: 1)
                )
        }
        .buttonStyle(ScaleButtonStyle())
    }
}

// MARK: - Scale Button Style
struct ScaleButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
            .animation(.easeOut(duration: 0.2), value: configuration.isPressed)
    }
}

// MARK: - Flow Layout for Pills
struct FlowLayout: Layout {
    var spacing: CGFloat = 10
    
    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let result = FlowResult(in: proposal.width ?? 0, subviews: subviews, spacing: spacing)
        return result.size
    }
    
    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let result = FlowResult(in: bounds.width, subviews: subviews, spacing: spacing)
        for (index, subview) in subviews.enumerated() {
            subview.place(at: CGPoint(x: bounds.minX + result.positions[index].x, y: bounds.minY + result.positions[index].y), proposal: .unspecified)
        }
    }
    
    struct FlowResult {
        var size: CGSize = .zero
        var positions: [CGPoint] = []
        
        init(in maxWidth: CGFloat, subviews: Subviews, spacing: CGFloat) {
            var x: CGFloat = 0
            var y: CGFloat = 0
            var rowHeight: CGFloat = 0
            
            for subview in subviews {
                let size = subview.sizeThatFits(.unspecified)
                
                if x + size.width > maxWidth && x > 0 {
                    x = 0
                    y += rowHeight + spacing
                    rowHeight = 0
                }
                
                positions.append(CGPoint(x: x, y: y))
                rowHeight = max(rowHeight, size.height)
                x += size.width + spacing
                
                self.size.width = max(self.size.width, x)
            }
            
            self.size.height = y + rowHeight
        }
    }
}

#Preview {
    TasteSelectionView(currentStep: .constant(2))
        .environmentObject(AuthManager.shared)
}
