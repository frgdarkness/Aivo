import SwiftUI

// MARK: - Cover Tab View
import SwiftUI

// MARK: - Cover Tab View
struct CoverTabView: View {
    @State private var selectedSong = ""
    @State private var selectedVoiceType: VoiceType = .otherVoice
    @State private var youtubeUrl = ""
    @State private var selectedLanguage: CoverLanguage = .english
    @State private var selectedArtist: Artist? = nil
    @State private var showProcessingScreen = false
    @State private var showPlaySongScreen = false
    @State private var resultAudioUrl: String?
    @State private var showToast = false
    @State private var toastMessage = ""
    enum SourceType { case song, youtube }
    @State private var selectedSource: SourceType = .song
    
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Song Selection (Card-Tab đơn giản)
                songSelectionSection

                // Language Selection
                languageSelectionSection

                // Artist Selection
                artistSelectionSection

                // Generate Button
                generateButton

                Spacer(minLength: 100) // Space for bottom nav
            }
            .padding(.horizontal, 20)
            .padding(.top, 20)
        }
        .fullScreenCover(isPresented: $showProcessingScreen) {
            GenerateSongProcessingScreen(
                requestType: .coverSong,
                onComplete: {
                    showProcessingScreen = false
                }
            )
        }
        .fullScreenCover(isPresented: $showPlaySongScreen) {
            if let audioUrl = resultAudioUrl {
                PlaySongIntroScreen(
                    songData: nil,
                    audioUrl: audioUrl,
                    onIntroCompleted: {
                        showPlaySongScreen = false
                    }
                )
            }
        }
        .overlay(
            // Toast Message
            VStack {
                Spacer()
                if showToast {
                    Text(toastMessage)
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.white)
                        .padding(.horizontal, 20)
                        .padding(.vertical, 12)
                        .background(Color.black.opacity(0.8))
                        .cornerRadius(8)
                        .padding(.bottom, 100)
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                        .animation(.easeInOut(duration: 0.3), value: showToast)
                }
            }
        )
    }

    // MARK: - Song Selection Section
    private var songSelectionSection: some View {
        VStack(alignment: .leading, spacing: 0) {
            // === Tabs ===
            HStack(alignment: .bottom, spacing: 0) {
                TagLabel(
                    title: "Pick a Song",
                    isSelected: selectedSource == .song,
                    selectedColor: AivoTheme.Primary.orange
                ) {
                    withAnimation(.easeInOut(duration: 0.25)) { selectedSource = .song }
                }
                .zIndex(selectedSource == .song ? 1 : 0)

                TagLabel(
                    title: "Youtube",
                    isSelected: selectedSource == .youtube,
                    selectedColor: AivoTheme.Secondary.goldenSun
                ) {
                    withAnimation(.easeInOut(duration: 0.25)) { selectedSource = .youtube }
                }
                .padding(.leading, -8)
                .zIndex(selectedSource == .youtube ? 1 : 0)

                Spacer()
            }

            // Thanh nhỏ cam phía dưới (giữ nguyên nếu bạn thích)
            Rectangle()
                .fill(AivoTheme.Primary.orange)
                .frame(width: 40, height: 20)
                .padding(.top, -10)

            // === CARD NỘI DUNG ===
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(Color.black)
                .overlay(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .stroke(AivoTheme.Primary.orange, lineWidth: 1)
                )
                .overlay(
                    Group {
                        if selectedSource == .song {
                            // 📀 Trường hợp PICK A SONG
                            Text("Click to select a song")
                                .font(.headline.weight(.semibold))
                                .foregroundColor(.white)
                                .multilineTextAlignment(.center)
                                .frame(maxWidth: .infinity, maxHeight: .infinity)
                        } else {
                            // 🎥 Trường hợp YOUTUBE
                            VStack(alignment: .leading, spacing: 12) {
                                Text("Copy youtube link to here:")
                                    .font(.subheadline.weight(.medium))
                                    .foregroundColor(.white)

                                TextField("https://www.youtube.com/watch?v=ixkoVwKQaJg", text: $selectedSong)
                                    .foregroundColor(.white)
                                    .padding(10)
                                    .background(
                                        RoundedRectangle(cornerRadius: 8)
                                            .fill(Color.gray.opacity(0.25))
                                    )
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 8)
                                            .stroke(AivoTheme.Primary.orange.opacity(0.3), lineWidth: 1)
                                    )
                            }
                            .padding(16)
                            .frame(maxWidth: .infinity, alignment: .leading)
                        }
                    }
                )
                .frame(maxWidth: .infinity, minHeight: 120)
                .padding(.top, -10)
        }
    }


    // MARK: - Language Selection Section
    private var languageSelectionSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Select Language")
                .font(.headline)
                .foregroundColor(.white)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(CoverLanguage.allCases, id: \.self) { language in
                        Button(action: { selectedLanguage = language }) {
                            Text(language.displayName)
                                .font(.subheadline)
                                .fontWeight(.medium)
                                .foregroundColor(selectedLanguage == language ? .black : .white)
                                .padding(.horizontal, 16)
                                .padding(.vertical, 12)
                                .background(
                                    RoundedRectangle(cornerRadius: 12)
                                        .fill(selectedLanguage == language ? AivoTheme.Primary.orange : Color.gray.opacity(0.3))
                                )
                        }
                    }
                }
                .padding(.horizontal, 4)
            }
        }
    }

    // MARK: - Artist Selection Section
    private var artistSelectionSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Select Voice")
                .font(.headline)
                .foregroundColor(.white)

            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 3), spacing: 16) {
                ForEach(Artist.allCases, id: \.self) { artist in
                    Button(action: { selectedArtist = selectedArtist == artist ? nil : artist }) {
                        VStack(spacing: 8) {
                            ZStack {
                                Circle()
                                    .fill(artist.backgroundColor)
                                    .frame(width: 60, height: 60)

                                Text(artist.emoji)
                                    .font(.title2)
                            }

                            Text(artist.name)
                                .font(.caption)
                                .fontWeight(.medium)
                                .foregroundColor(.white)
                                .multilineTextAlignment(.center)
                        }
                        .overlay(
                            Circle()
                                .stroke(selectedArtist == artist ? AivoTheme.Primary.orange : Color.clear, lineWidth: 3)
                        )
                    }
                }
            }
        }
    }

    // MARK: - Generate Button
    private var generateButton: some View {
        Button(action: {
            if isGenerateEnabled {
                generateCoverSong()
            }
        }) {
            HStack(spacing: 8) {
                Text("Generate")
                    .font(.headline)
                    .fontWeight(.bold)
                    .foregroundColor(.black)

                Image(systemName: "mic.fill")
                    .font(.title3)
                    .foregroundColor(.black)
            }
            .frame(maxWidth: .infinity)
            .frame(height: 56)
            .background(isGenerateEnabled ? AivoTheme.Primary.orange : Color.gray.opacity(0.3))
            .cornerRadius(12)
            .shadow(color: isGenerateEnabled ? AivoTheme.Shadow.orange : Color.clear, radius: 10, x: 0, y: 0)
        }
        .disabled(!isGenerateEnabled)
    }
    
    // MARK: - Helper Properties
    private var isGenerateEnabled: Bool {
        if selectedSource == .song {
            return false // Pick a Song chưa implement
        } else {
            return !selectedSong.isEmpty // YouTube cần có URL
        }
    }

    // MARK: - Actions
    private func generateCoverSong() {
        print("🎤 [CoverTab] Starting cover song generation...")
        print("🎤 [CoverTab] YouTube URL: \(selectedSong)")
        print("🎤 [CoverTab] Language: \(selectedLanguage.displayName)")
        print("🎤 [CoverTab] Artist: \(selectedArtist?.name ?? "None")")
        
        // Show processing screen
        showProcessingScreen = true
        
        // Start generation in background
        Task {
            do {
                let modelsLabService = ModelsLabService.shared
                let coverModelID = selectedArtist?.rawValue ?? "jungkookv7-e"
                
                print("🎤 [CoverTab] Calling ModelsLabService.processVoiceCover...")
                let resultUrl = try await modelsLabService.processVoiceCover(
                    audioUrl: selectedSong, 
                    modelID: coverModelID
                )
                
                print("🎤 [CoverTab] Cover song generated successfully!")
                print("🎤 [CoverTab] Result URL: \(resultUrl)")
                
                await MainActor.run {
                    // Close processing screen
                    showProcessingScreen = false
                    
                    // Set result and show play screen
                    resultAudioUrl = resultUrl
                    showToastMessage("Cover song generated successfully!")
                    
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                        showPlaySongScreen = true
                    }
                }
                
            } catch {
                print("❌ [CoverTab] Error generating cover song: \(error)")
                await MainActor.run {
                    showProcessingScreen = false
                    showToastMessage("Failed to generate cover song: \(error.localizedDescription)")
                }
            }
        }
    }
    
    private func showToastMessage(_ message: String) {
        toastMessage = message
        showToast = true
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
            showToast = false
        }
    }
}

// MARK: - Supporting Enums
enum VoiceType: String, CaseIterable {
    case myVoice = "My voice"
    case otherVoice = "Other voice"
    
    var icon: String {
        switch self {
        case .myVoice: return "mic.fill"
        case .otherVoice: return "person.2.fill"
        }
    }
}

enum Artist: String, CaseIterable {
    case donald = "Dony"
    case edSheeran = "Ed 5heeran"
    case taylorSwift = "T4yl0r"
    case katyPerry = "K4ty Perry"
    case maroon5 = "Mar0on 5"
    case mrBeast = "Mr. Be4st"
    case elonMusk = "El0n"
    case shakira = "Sh4kira"
    case snoopDogg = "Sn00p"
    
    var name: String {
        return self.rawValue
    }
    
    var emoji: String {
        switch self {
        case .donald: return "👨‍💼"
        case .edSheeran: return "🎸"
        case .taylorSwift: return "🎤"
        case .katyPerry: return "🐅"
        case .maroon5: return "🎵"
        case .mrBeast: return "💰"
        case .elonMusk: return "🚀"
        case .shakira: return "💃"
        case .snoopDogg: return "🌿"
        }
    }
    
    var backgroundColor: Color {
        switch self {
        case .donald: return .orange
        case .edSheeran: return .red
        case .taylorSwift: return .blue
        case .katyPerry: return .pink
        case .maroon5: return .purple
        case .mrBeast: return .green
        case .elonMusk: return .gray
        case .shakira: return .yellow
        case .snoopDogg: return .brown
        }
    }
}

// MARK: - TagLabel Component
struct TagLabel0: View {
    let title: String
    let isSelected: Bool
    let selectedColor: Color
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(isSelected ? .black : .white)
                .padding(.horizontal, 20)
                .padding(.vertical, 12)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(isSelected ? selectedColor : Color.clear)
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(isSelected ? Color.clear : Color.white.opacity(0.3), lineWidth: 1)
                        )
                )
        }
    }
}

private struct TagLabel: View {
    let title: String
    let isSelected: Bool
    let selectedColor: Color
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(isSelected ? .subheadline.weight(.semibold)
                                 : .footnote.weight(.semibold))
                .foregroundColor(.black)
                //.foregroundColor(isSelected ? .black : .white)
                .padding(.horizontal, isSelected ? 16 : 12)
                .padding(.vertical,   isSelected ? 10 : 8)
                .background(
                    selectedColor
                        .clipShape(
                            RoundedCorner(
                                radius: 8,
                                corners: [.topLeft, .topRight] // ✅ chỉ bo cong 2 góc trên
                            )
                        )
                )
        }
        .buttonStyle(.plain)
    }
}

struct RoundedCorner: Shape {
    var radius: CGFloat = 8
    var corners: UIRectCorner = .allCorners
    
    func path(in rect: CGRect) -> Path {
        let path = UIBezierPath(
            roundedRect: rect,
            byRoundingCorners: corners,
            cornerRadii: CGSize(width: radius, height: radius)
        )
        return Path(path.cgPath)
    }
}


// MARK: - Preview
struct CoverTabView_Previews: PreviewProvider {
    static var previews: some View {
        ZStack {
            AivoSunsetBackground()
            CoverTabView()
        }
    }
}

private struct TabChip: View {
    let title: String
    let systemIcon: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                Image(systemName: systemIcon)
                Text(title)
            }
            // ↑ font to hơn khi chọn (đẩy layout thật)
            .font(isSelected ? .subheadline.weight(.semibold)
                             : .footnote.weight(.semibold))
            .foregroundColor(isSelected ? .black : .white)

            // ↑ padding lớn hơn khi chọn (kích thước thật, không scale)
            .padding(.horizontal, isSelected ? 16 : 12)
            .padding(.vertical,   isSelected ? 9  : 7)

            .background(
                RoundedRectangle(cornerRadius: 6, style: .continuous)
                    .fill(isSelected ? AivoTheme.Primary.orange : Color.gray.opacity(0.25))
            )
        }
        .buttonStyle(.plain)
    }
}
