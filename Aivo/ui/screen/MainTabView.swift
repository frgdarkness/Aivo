import SwiftUI

// MARK: - Main Tab View
struct HomeView: View {
    @State private var selectedTab: TabItem = .home
    
    var body: some View {
        ZStack {
            // Background
            AivoSunsetBackground()
            
            VStack(spacing: 0) {
                // Content based on selected tab
                contentView
                
                Spacer()
                // Bottom Navigation
                bottomNavigationView
            }
        }
        .navigationBarHidden(true)
    }
    
    // MARK: - Content View
    @ViewBuilder
    private var contentView: some View {
        switch selectedTab {
        case .home:
            HomeTabView()
        case .explore:
            ExploreTabView()
        case .cover:
            CoverTabView()
        case .library:
            LibraryTabView()
        }
    }
    
    // MARK: - Bottom Navigation
    private var bottomNavigationView: some View {
        HStack(spacing: 0) {
            ForEach(TabItem.allCases, id: \.self) { tab in
                Button(action: { selectedTab = tab }) {
                    VStack(spacing: 4) {
                        Image(systemName: tab.icon)
                            .font(.system(size: 20, weight: .medium))
                            .foregroundColor(selectedTab == tab ? AivoTheme.Primary.orange : .gray)
                        
                        Text(tab.title)
                            .font(.caption)
                            .fontWeight(.medium)
                            .foregroundColor(selectedTab == tab ? AivoTheme.Primary.orange : .gray)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 8)
                }
            }
        }
        .padding(.horizontal, 20)
        .background(
            Rectangle()
                .fill(Color.black.opacity(0.8))
                .shadow(color: .black.opacity(0.3), radius: 10, x: 0, y: -5)
        )
    }
}

// MARK: - Tab Item Enum
enum TabItem: String, CaseIterable {
    case home = "Home"
    case explore = "Explore"
    case cover = "Cover"
    case library = "Library"
    
    var title: String {
        return self.rawValue
    }
    
    var icon: String {
        switch self {
        case .home:
            return "music.note"
        case .explore:
            return "headphones"
        case .cover:
            return "mic"
        case .library:
            return "books.vertical"
        }
    }
}

// MARK: - Home Tab View
struct HomeTabView: View {
    @State private var selectedInputType: InputType = .description
    @State private var songDescription = ""
    @State private var songLyrics = ""
    @State private var selectedMood: String? = nil
    @State private var selectedGenre: String? = nil
    @State private var isAdvancedExpanded = false
    @State private var songName = ""
    @State private var isVocalEnabled = false
    @State private var selectedVocalGender: VocalGender = .random
    
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Header
                headerView
                
                // Input Type Tabs
                inputTypeTabs
                
                // Main Input Section
                mainInputSection
                
                // Mood Selection
                moodSelectionSection
                
                // Genre Selection
                genreSelectionSection
                
                // Advanced Options
                advancedOptionsSection
                
                // Create Button
                createButton
                
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
    
    // MARK: - Input Type Tabs
    private var inputTypeTabs: some View {
        HStack(spacing: 0) {
            ForEach(InputType.allCases, id: \.self) { type in
                Button(action: { selectedInputType = type }) {
                    Text(type.title)
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(selectedInputType == type ? .black : .white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(
                            RoundedRectangle(cornerRadius: 8)
                                .fill(selectedInputType == type ? AivoTheme.Primary.orange : Color.clear)
                        )
                }
            }
        }
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(Color.gray.opacity(0.2))
        )
    }
    
    // MARK: - Main Input Section
    private var mainInputSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text(selectedInputType == .description ? "Describe the Song" : "Enter lyrics")
                    .font(.headline)
                    .foregroundColor(.white)
                
                Spacer()
                
                if selectedInputType == .description {
                    Button(action: {}) {
                        HStack(spacing: 4) {
                            Image(systemName: "lightbulb.fill")
                                .font(.caption)
                                .foregroundColor(.yellow)
                            
                            Text("Get Inspired")
                                .font(.caption)
                                .foregroundColor(.white)
                        }
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(
                            Capsule()
                                .fill(Color.gray.opacity(0.3))
                        )
                    }
                }
            }
            
            // Input Field
            ZStack(alignment: .topLeading) {
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.black.opacity(0.3))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(AivoTheme.Primary.orange, lineWidth: 1)
                    )
                
                VStack(alignment: .leading, spacing: 8) {
                    if selectedInputType == .description {
                        TextField("Describe the music and topic you want (e.g: make a chill song for my biggest regret)", text: $songDescription, axis: .vertical)
                            .foregroundColor(.white)
                            .lineLimit(4...8)
                    } else {
                        TextField("Enter your lyrics here...", text: $songLyrics, axis: .vertical)
                            .foregroundColor(.white)
                            .lineLimit(8...15)
                    }
                    
                    Spacer()
                    
                    HStack {
                        Spacer()
                        Text("\(selectedInputType == .description ? songDescription.count : songLyrics.count) / \(selectedInputType == .description ? 128 : 1950)")
                            .font(.caption)
                            .foregroundColor(.gray)
                    }
                }
                .padding(16)
            }
            .frame(height: selectedInputType == .description ? 120 : 200)
        }
    }
    
    // MARK: - Mood Selection Section
    private var moodSelectionSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Select Mood (Optional)")
                .font(.headline)
                .foregroundColor(.white)
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(MoodOption.allCases, id: \.self) { mood in
                        Button(action: { 
                            selectedMood = selectedMood == mood.rawValue ? nil : mood.rawValue
                        }) {
                            Text(mood.rawValue)
                                .font(.subheadline)
                                .fontWeight(.medium)
                                .foregroundColor(.white)
                                .padding(.horizontal, 16)
                                .padding(.vertical, 8)
                                .background(
                                    RoundedRectangle(cornerRadius: 20)
                                        .fill(selectedMood == mood.rawValue ? AivoTheme.Primary.orange : Color.gray.opacity(0.3))
                                )
                        }
                    }
                }
                .padding(.horizontal, 4)
            }
        }
    }
    
    // MARK: - Genre Selection Section
    private var genreSelectionSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Select Genre (Optional)")
                .font(.headline)
                .foregroundColor(.white)
            
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 12) {
                ForEach(GenreOption.allCases, id: \.self) { genre in
                    Button(action: { 
                        selectedGenre = selectedGenre == genre.rawValue ? nil : genre.rawValue
                    }) {
                        VStack(spacing: 8) {
                            ZStack {
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(genre.backgroundColor)
                                    .frame(height: 60)
                                
                                Image(systemName: genre.icon)
                                    .font(.title2)
                                    .foregroundColor(genre.iconColor)
                            }
                            
                            Text(genre.rawValue)
                                .font(.caption)
                                .fontWeight(.medium)
                                .foregroundColor(.white)
                        }
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(selectedGenre == genre.rawValue ? AivoTheme.Primary.orange : Color.clear, lineWidth: 2)
                        )
                    }
                }
            }
        }
    }
    
    // MARK: - Advanced Options Section
    private var advancedOptionsSection: some View {
        VStack(spacing: 0) {
            // Header
            Button(action: { 
                withAnimation(.easeInOut(duration: 0.3)) {
                    isAdvancedExpanded.toggle()
                }
            }) {
                HStack {
                    Text("Advanced Options")
                        .font(.headline)
                        .foregroundColor(.white)
                    
                    Image(systemName: "drum.fill")
                        .font(.caption)
                        .foregroundColor(.white)
                    
                    Spacer()
                    
                    Image(systemName: isAdvancedExpanded ? "chevron.up" : "chevron.down")
                        .font(.caption)
                        .foregroundColor(.white)
                }
                .padding(16)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color.gray.opacity(0.2))
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(AivoTheme.Primary.orange, lineWidth: 1)
                        )
                )
            }
            
            // Expanded Content
            if isAdvancedExpanded {
                VStack(spacing: 16) {
                    // Song Name
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Song Name (Optional)")
                            .font(.subheadline)
                            .foregroundColor(.white)
                        
                        TextField("Name", text: $songName)
                            .foregroundColor(.white)
                            .padding(12)
                            .background(
                                RoundedRectangle(cornerRadius: 8)
                                    .fill(Color.white.opacity(0.1))
                            )
                    }
                    
                    // Vocal Toggle
                    HStack {
                        Text("Vocal")
                            .font(.subheadline)
                            .foregroundColor(.white)
                        
                        Spacer()
                        
                        Toggle("", isOn: $isVocalEnabled)
                            .toggleStyle(SwitchToggleStyle(tint: AivoTheme.Primary.orange))
                    }
                    
                    // Vocal Gender
                    if isVocalEnabled {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Vocal Gender (Optional)")
                                .font(.subheadline)
                                .foregroundColor(.white)
                            
                            HStack(spacing: 12) {
                                ForEach(VocalGender.allCases, id: \.self) { gender in
                                    Button(action: { selectedVocalGender = gender }) {
                                        HStack(spacing: 4) {
                                            Text(gender.emoji)
                                                .font(.caption)
                                            
                                            Text(gender.rawValue)
                                                .font(.caption)
                                                .fontWeight(.medium)
                                        }
                                        .foregroundColor(selectedVocalGender == gender ? .black : .white)
                                        .padding(.horizontal, 12)
                                        .padding(.vertical, 6)
                                        .background(
                                            RoundedRectangle(cornerRadius: 16)
                                                .fill(selectedVocalGender == gender ? AivoTheme.Primary.orange : Color.gray.opacity(0.3))
                                        )
                                    }
                                }
                            }
                        }
                    }
                }
                .padding(16)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color.gray.opacity(0.1))
                )
                .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
    }
    
    // MARK: - Create Button
    private var createButton: some View {
        Button(action: createAction) {
            HStack(spacing: 8) {
                Text(selectedInputType == .description ? "Create with Description" : "Create with Lyrics")
                    .font(.headline)
                    .fontWeight(.bold)
                    .foregroundColor(.black)
                
                ForEach(0..<3, id: \.self) { _ in
                    Image(systemName: "music.note")
                        .font(.caption)
                        .foregroundColor(.black)
                }
            }
            .frame(maxWidth: .infinity)
            .frame(height: 56)
            .background(AivoTheme.Primary.orange)
            .cornerRadius(12)
            .shadow(color: AivoTheme.Shadow.orange, radius: 10, x: 0, y: 0)
        }
    }
    
    // MARK: - Actions
    private func createAction() {
        print("Creating song with \(selectedInputType.rawValue)")
    }
}

// MARK: - Supporting Enums
enum InputType: String, CaseIterable {
    case description = "Song Description"
    case lyrics = "Lyrics"
    
    var title: String {
        return self.rawValue
    }
}

enum MoodOption: String, CaseIterable {
    case happy = "Happy"
    case confident = "Confident"
    case motivational = "Motivational"
    case whimsical = "Whimsical"
    case depressive = "Depressive"
    case energetic = "Energetic"
    case calm = "Calm"
    case romantic = "Romantic"
}

enum GenreOption: String, CaseIterable {
    case random = "Random Genre"
    case blues = "Blues"
    case funks = "Funks"
    case rap = "Rap"
    case pop = "Pop"
    case rock = "Rock"
    case electronic = "Electronic"
    case jazz = "Jazz"
    
    var icon: String {
        switch self {
        case .random: return "drum.fill"
        case .blues: return "violin"
        case .funks: return "trumpet.fill"
        case .rap: return "guitar.fill"
        case .pop: return "music.note"
        case .rock: return "guitar"
        case .electronic: return "waveform"
        case .jazz: return "saxophone.fill"
        }
    }
    
    var backgroundColor: Color {
        switch self {
        case .random: return .purple.opacity(0.7)
        case .blues: return .purple.opacity(0.7)
        case .funks: return .teal.opacity(0.7)
        case .rap: return .teal.opacity(0.7)
        case .pop: return .blue.opacity(0.7)
        case .rock: return .red.opacity(0.7)
        case .electronic: return .green.opacity(0.7)
        case .jazz: return .orange.opacity(0.7)
        }
    }
    
    var iconColor: Color {
        switch self {
        case .random: return .red
        case .blues: return .yellow
        case .funks: return .yellow
        case .rap: return .red
        case .pop: return .white
        case .rock: return .white
        case .electronic: return .white
        case .jazz: return .white
        }
    }
}

enum VocalGender: String, CaseIterable {
    case male = "Male"
    case female = "Female"
    case random = "Random"
    
    var emoji: String {
        switch self {
        case .male: return "👨"
        case .female: return "👩"
        case .random: return "🎲"
        }
    }
}

// MARK: - Preview
struct HomeView_Previews: PreviewProvider {
    static var previews: some View {
        HomeView()
    }
}
