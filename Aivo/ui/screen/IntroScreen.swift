import SwiftUI

// MARK: - Intro Screen Controller
struct IntroScreen: View {
    let onIntroCompleted: () -> Void // Callback to SplashScreenView
    
    @State private var currentStep = 1
    @State private var selectedMood: SongMood?
    @State private var selectedGenre: SongGenre?
    @State private var selectedTheme: SongTheme?
    @State private var showProcessing = false
    @State private var selectedSong: SunoData?
    @State private var processingTask: Task<Void, Never>?
    
    var body: some View {
        ZStack {
            // Background
            AivoSunsetBackground()
            
            VStack(spacing: 0) {
                // Header
                headerView
                
                // Content based on current step
                contentView
                
                Spacer()
                
                // Continue Button
                continueButton
            }
            .padding(.horizontal, 20)
            .padding(.top, 50)
        }
        .fullScreenCover(isPresented: $showProcessing) {
            GenerateSongProcessingScreen(
                requestType: .generateSong,
                onComplete: {
                    // Processing screen will auto-dismiss after 5s
                    // Then we'll show play screen
                },
                onCancel: {
                    // Cancel processing and reset state
                    Logger.i("⚠️ [IntroScreen] Processing cancelled by user")
                    processingTask?.cancel()
                    showProcessing = false
                    // Reset selections if needed
                    selectedMood = nil
                    selectedGenre = nil
                    selectedTheme = nil
                    currentStep = 1
                }
            )
        }
        .fullScreenCover(item: $selectedSong) { song in
            PlaySunoSongIntroScreen(
                sunoData: song,
                onIntroCompleted: onIntroCompleted
            )
            .onAppear {
                Logger.d("🎵 [IntroScreen] PlaySunoSongIntroScreen appeared with song: \(song.title)")
            }
        }
    }
    
    // MARK: - Header View
    private var headerView: some View {
        VStack(spacing: 8) {
            Text("LET'S START!")
                .font(.system(size: 32, weight: .black, design: .monospaced))
                .foregroundColor(.white)
            
            // Fixed height container for text to prevent layout shifts (~3 lines)
            VStack(spacing: 0) {
                if let mood = selectedMood, let genre = selectedGenre, let theme = selectedTheme {
                    Text("Make a \(mood.displayName) & \(genre.displayName) song for \(theme.displayName)")
                        .font(.headline)
                        .foregroundColor(.white)
                        .multilineTextAlignment(.center)
                        .lineLimit(3)
                        .fixedSize(horizontal: false, vertical: true)
                } else if let mood = selectedMood, let genre = selectedGenre {
                    Text("Make a \(mood.displayName) & \(genre.displayName) song")
                        .font(.headline)
                        .foregroundColor(.white)
                        .multilineTextAlignment(.center)
                        .lineLimit(3)
                        .fixedSize(horizontal: false, vertical: true)
                } else if let mood = selectedMood {
                    Text("Make a \(mood.displayName) song")
                        .font(.headline)
                        .foregroundColor(.white)
                        .multilineTextAlignment(.center)
                        .lineLimit(3)
                        .fixedSize(horizontal: false, vertical: true)
                } else {
                    Text("Make a song")
                        .font(.headline)
                        .foregroundColor(.white)
                        .multilineTextAlignment(.center)
                        .lineLimit(3)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
            .frame(height: 52) // Fixed height for ~3 lines (headline font ~20pt per line with 4pt spacing)
            .frame(maxWidth: .infinity)
        }
        .padding(.bottom, 40)
    }
    
    // MARK: - Content View
    @ViewBuilder
    private var contentView: some View {
        switch currentStep {
        case 1:
            MoodSelectionView(selectedMood: $selectedMood)
        case 2:
            GenreSelectionView(selectedGenre: $selectedGenre)
        case 3:
            ThemeSelectionView(selectedTheme: $selectedTheme)
        default:
            EmptyView()
        }
    }
    
    // MARK: - Continue Button
    private var continueButton: some View {
        Button(action: handleContinue) {
            HStack {
                Text("Continue")
                    .font(.headline)
                    .fontWeight(.semibold)
                
                Image(systemName: "arrow.right")
                    .font(.headline)
            }
            .foregroundColor(.black)
            .frame(maxWidth: .infinity)
            .frame(height: 50)
            .background(AivoTheme.Primary.orange)
            .cornerRadius(12)
            .shadow(color: AivoTheme.Shadow.orange, radius: 10, x: 0, y: 0)
        }
        .disabled(!canContinue)
        .opacity(canContinue ? 1.0 : 0.6)
        .padding(.bottom, 30)
    }
    
    // MARK: - Computed Properties
    private var canContinue: Bool {
        switch currentStep {
        case 1:
            return selectedMood != nil
        case 2:
            return selectedGenre != nil
        case 3:
            return selectedTheme != nil
        default:
            return false
        }
    }
    
    private var songCreationData: SongCreationData? {
        guard let mood = selectedMood,
              let genre = selectedGenre,
              let theme = selectedTheme else {
            return nil
        }
        return SongCreationData(mood: mood, genre: genre, theme: theme)
    }
    
    // MARK: - Actions
    private func handleContinue() {
        if currentStep < 3 {
            withAnimation(.easeInOut(duration: 0.3)) {
                currentStep += 1
            }
        } else {
            // All steps completed, query song and show processing
            guard let mood = selectedMood,
                  let genre = selectedGenre,
                  let theme = selectedTheme else {
                Logger.e("❌ [IntroScreen] Missing selection data")
                return
            }
            
            // Query and select random song
            Task {
                if let song = IntroSongService.shared.getRandomSong(mood: mood, genre: genre, theme: theme) {
                    await MainActor.run {
                        Logger.d("🎵 [IntroScreen] Selected song: \(song.title)")
                        
                        // DON'T set selectedSong yet - we'll set it after processing to trigger fullScreenCover(item:)
                        // Show processing screen first
                        showProcessing = true
                        Logger.d("⏳ [IntroScreen] Showing processing screen")
                        
                        // After 5 seconds, hide processing and show play screen
                        processingTask = Task { @MainActor in
                            // Check if task was cancelled
                            guard !Task.isCancelled else {
                                Logger.d("⚠️ [IntroScreen] Processing task was cancelled")
                                return
                            }
                            
                            try? await Task.sleep(nanoseconds: 4_000_000_000) // 5 seconds
                            
                            // Check again after sleep
                            guard !Task.isCancelled else {
                                Logger.d("⚠️ [IntroScreen] Processing task was cancelled after sleep")
                                return
                            }
                            
                            Logger.d("✅ [IntroScreen] Hiding processing, showing play screen")
                            showProcessing = false
                            
                            try? await Task.sleep(nanoseconds: 100_000_000) // 0.5 seconds - longer delay to ensure processing dismissed
                            
                            // Final check before setting selectedSong
                            guard !Task.isCancelled else {
                                Logger.d("⚠️ [IntroScreen] Processing task was cancelled before showing play screen")
                                return
                            }
                            
                            // NOW set selectedSong - this will trigger fullScreenCover(item:) automatically
                            Logger.d("🎵 [IntroScreen] Setting selectedSong to trigger fullScreenCover: \(song.title)")
                            selectedSong = song
                            Logger.d("🎵 [IntroScreen] selectedSong set, fullScreenCover should trigger automatically")
                        }
                    }
                } else {
                    await MainActor.run {
                        Logger.e("❌ [IntroScreen] No song found for \(mood.displayName)/\(genre.displayName)/\(theme.displayName)")
                        // No fallback - user should try different selections
                    }
                }
            }
        }
    }
}

// MARK: - Mood Selection View
struct MoodSelectionView: View {
    @Binding var selectedMood: SongMood?
    
    var body: some View {
        VStack(spacing: 30) {
            // Step indicator
            VStack(spacing: 8) {
                Text("STEP I")
                    .font(.system(size: 28, weight: .black, design: .monospaced))
                    .foregroundColor(.white)
                
                Text("What is the **MOOD** of your song?")
                    .font(.title2)
                    .fontWeight(.medium)
                    .foregroundColor(.white)
            }
            
            // Mood options
            VStack(spacing: 16) {
                ForEach(SongMood.getIntroList(), id: \.self) { mood in
                    MoodOptionButton(
                        mood: mood,
                        isSelected: selectedMood == mood,
                        action: { selectedMood = mood }
                    )
                }
            }
        }
    }
}

// MARK: - Genre Selection View
struct GenreSelectionView: View {
    @Binding var selectedGenre: SongGenre?
    
    var body: some View {
        VStack(spacing: 30) {
            // Step indicator
            VStack(spacing: 8) {
                Text("STEP 2")
                    .font(.system(size: 28, weight: .black, design: .monospaced))
                    .foregroundColor(.white)
                
                Text("What is the **GENRE** of your song?")
                    .font(.title2)
                    .fontWeight(.medium)
                    .foregroundColor(.white)
            }
            
            // Genre options
            VStack(spacing: 16) {
                ForEach(SongGenre.getIntroList(), id: \.self) { genre in
                    GenreOptionButton(
                        genre: genre,
                        isSelected: selectedGenre == genre,
                        action: { selectedGenre = genre }
                    )
                }
            }
        }
    }
}

// MARK: - Theme Selection View
struct ThemeSelectionView: View {
    @Binding var selectedTheme: SongTheme?
    
    var body: some View {
        VStack(spacing: 30) {
            // Step indicator
            VStack(spacing: 8) {
                Text("STEP 3")
                    .font(.system(size: 28, weight: .black, design: .monospaced))
                    .foregroundColor(.white)
                
                Text("WHO is song for?")
                    .font(.title2)
                    .fontWeight(.medium)
                    .foregroundColor(.white)
            }
            
            // Theme options
            VStack(spacing: 16) {
                ForEach(SongTheme.getHottest(), id: \.self) { theme in
                    ThemeOptionButton(
                        theme: theme,
                        isSelected: selectedTheme == theme,
                        action: { selectedTheme = theme }
                    )
                }
            }
        }
    }
}

// MARK: - Option Buttons
struct MoodOptionButton: View {
    let mood: SongMood
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(mood.displayName)
                .font(.headline)
                .fontWeight(.medium)
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .frame(height: 50)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(isSelected ? Color.clear : Color.clear)
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(
                                    isSelected ? AivoTheme.Primary.orange : Color.white.opacity(0.3),
                                    lineWidth: isSelected ? 3 : 1
                                )
                        )
                )
        }
        .scaleEffect(isSelected ? 1.02 : 1.0)
        .animation(.easeInOut(duration: 0.2), value: isSelected)
    }
}

struct GenreOptionButton: View {
    let genre: SongGenre
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(genre.displayName)
                .font(.headline)
                .fontWeight(.medium)
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .frame(height: 50)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(isSelected ? Color.clear : Color.clear)
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(
                                    isSelected ? AivoTheme.Primary.orange : Color.white.opacity(0.3),
                                    lineWidth: isSelected ? 3 : 1
                                )
                        )
                )
        }
        .scaleEffect(isSelected ? 1.02 : 1.0)
        .animation(.easeInOut(duration: 0.2), value: isSelected)
    }
}

struct ThemeOptionButton: View {
    let theme: SongTheme
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(theme.displayName)
                .font(.headline)
                .fontWeight(.medium)
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .frame(height: 50)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(isSelected ? Color.clear : Color.clear)
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(
                                    isSelected ? AivoTheme.Primary.orange : Color.white.opacity(0.3),
                                    lineWidth: isSelected ? 3 : 1
                                )
                        )
                )
        }
        .scaleEffect(isSelected ? 1.02 : 1.0)
        .animation(.easeInOut(duration: 0.2), value: isSelected)
    }
}

// MARK: - Preview
struct IntroScreen_Previews: PreviewProvider {
    static var previews: some View {
        IntroScreen(onIntroCompleted: {})
    }
}
