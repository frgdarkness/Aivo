import SwiftUI

// MARK: - Cover Tab View
struct CoverTabView: View {
    @State private var selectedSong = ""
    @State private var selectedVoiceType: VoiceType = .otherVoice
    @State private var selectedArtist: Artist? = nil
    
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Header
                headerView
                
                // Song Selection
                songSelectionSection
                
                // Voice Selection
                voiceSelectionSection
                
                // Artist Selection
                artistSelectionSection
                
                // Generate Button
                generateButton
                
                Spacer(minLength: 100) // Space for bottom nav
            }
            .padding(.horizontal, 20)
            .padding(.top, 20)
        }
    }
    
    // MARK: - Header View
    private var headerView: some View {
        HStack {
            Text("AIVO AI MUSIC")
                .font(.system(size: 24, weight: .black, design: .monospaced))
                .foregroundColor(.white)
            
            Spacer()
            
            // VIP Button
            Button(action: {}) {
                HStack(spacing: 4) {
                    Image(systemName: "crown.fill")
                        .font(.caption)
                        .foregroundColor(.yellow)
                    
                    Text("VIP")
                        .font(.caption)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(
                    Capsule()
                        .fill(Color.gray.opacity(0.3))
                        .overlay(
                            Capsule()
                                .stroke(Color.yellow.opacity(0.3), lineWidth: 1)
                        )
                )
            }
            
            // Settings Button
            Button(action: {}) {
                Image(systemName: "gearshape")
                    .font(.title2)
                    .foregroundColor(.white)
            }
        }
    }
    
    // MARK: - Song Selection Section
    private var songSelectionSection: some View {
        VStack(spacing: 12) {
            Button(action: pickSong) {
                Text("Pick a Song")
                    .font(.headline)
                    .fontWeight(.medium)
                    .foregroundColor(.black)
                    .frame(maxWidth: .infinity)
                    .frame(height: 50)
                    .background(AivoTheme.Primary.orange)
                    .cornerRadius(12)
            }
            
            HStack {
                TextField("Please pick a song to cover", text: $selectedSong)
                    .foregroundColor(.white)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color.gray.opacity(0.2))
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(AivoTheme.Primary.orange, lineWidth: 1)
                            )
                    )
                
                Button(action: {}) {
                    Image(systemName: "pencil")
                        .font(.title3)
                        .foregroundColor(.white)
                }
            }
        }
    }
    
    // MARK: - Voice Selection Section
    private var voiceSelectionSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Select Voice")
                .font(.headline)
                .foregroundColor(.white)
            
            HStack(spacing: 12) {
                ForEach(VoiceType.allCases, id: \.self) { type in
                    Button(action: { selectedVoiceType = type }) {
                        HStack(spacing: 8) {
                            Image(systemName: type.icon)
                                .font(.title3)
                                .foregroundColor(selectedVoiceType == type ? .black : .white)
                            
                            Text(type.rawValue)
                                .font(.subheadline)
                                .fontWeight(.medium)
                                .foregroundColor(selectedVoiceType == type ? .black : .white)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(selectedVoiceType == type ? AivoTheme.Primary.orange : Color.gray.opacity(0.3))
                        )
                    }
                }
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
        Button(action: generateCover) {
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
            .background(AivoTheme.Primary.orange)
            .cornerRadius(12)
            .shadow(color: AivoTheme.Shadow.orange, radius: 10, x: 0, y: 0)
        }
    }
    
    // MARK: - Actions
    private func pickSong() {
        print("Picking a song...")
    }
    
    private func generateCover() {
        print("Generating cover with \(selectedVoiceType.rawValue) voice")
        if let artist = selectedArtist {
            print("Selected artist: \(artist.name)")
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

// MARK: - Preview
struct CoverTabView_Previews: PreviewProvider {
    static var previews: some View {
        CoverTabView()
    }
}
