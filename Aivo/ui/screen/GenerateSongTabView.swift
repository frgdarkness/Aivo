import SwiftUI

// MARK: - Generate Song Tab View
struct GenerateSongTabView: View {
    @State private var selectedInputType: InputType = .description
    @State private var songDescription = ""
    @State private var songLyrics = ""
    @State private var selectedMoods: [SongMood] = []
    @State private var selectedGenres: [SongGenre] = []
    @State private var showMultiMoodScreen = false
    @State private var isAdvancedExpanded = false
    @State private var songName = ""
    @State private var isVocalEnabled = false
    @State private var selectedVocalGender: VocalGender = .random
    
    enum InputType: String, CaseIterable {
        case description = "Song Description"
        case lyrics = "Lyrics"
    }
    
    enum VocalGender: String, CaseIterable {
        case male = "Male"
        case female = "Female"
        case random = "Random"
    }
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Song Input Section
                songInputSection
                
                // Mood Selection
                moodSelectionSection
                
                // Genre Selection
                genreSelectionSection
                
                // Advanced Options
                advancedOptionsSection
                
                // Create Button
                createButton
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 100) // Space for bottom navigation
        }
        .sheet(isPresented: $showMultiMoodScreen) {
            SelectMultiMoodScreen(
                initialSelectedMoods: selectedMoods,
                onDone: { selectedMoods in
                    self.selectedMoods = selectedMoods
                },
                onCancel: {
                    // Do nothing, just dismiss
                }
            )
        }
    }
    
    // MARK: - Song Input Section
    private var songInputSection: some View {
        // animation khi đổi tab & đổi chiều cao vùng nhập
        let expandAnim = Animation.spring(response: 0.35, dampingFraction: 0.9, blendDuration: 0.2)

        return VStack(spacing: 12) {
            // Input Type Tabs
            HStack(spacing: 0) {
                ForEach(InputType.allCases, id: \.self) { type in
                    Button {
                        withAnimation(expandAnim) {
                            selectedInputType = type
                        }
                    } label: {
                        Text(type.rawValue)
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(selectedInputType == type ? .white : .white.opacity(0.7))
                            .padding(.horizontal, 20)
                            .padding(.vertical, 12)
                            .background(
                                RoundedRectangle(cornerRadius: 8)
                                    .fill(selectedInputType == type ? AivoTheme.Primary.orange : .clear)
                            )
                    }
                }
            }
            .padding(.horizontal, 4)
            .padding(.vertical, 4)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.black.opacity(0.3))
            )

            // Input Field
            VStack(alignment: .leading, spacing: 10) {
                HStack(spacing: 8) {
                    Text(selectedInputType == .description ? "Describe the Song" : "Enter lyrics")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.white)

                    Spacer()

                    
                    Button(action: {}) {
                        HStack(spacing: 6) {
                            Image(systemName: "lightbulb.fill")
                                .font(.caption)
                                .foregroundColor(.yellow)
                            Text("Get Inspired")
                                .font(.caption)
                                .foregroundColor(.white.opacity(0.8))
                        }
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .background(
                            RoundedRectangle(cornerRadius: 6)
                                .fill(Color.white.opacity(0.12))
                        )
                    }
                    
                }
                .padding(.top, 0)
                
                let lyrics = """
                Verse 1:
                I still remember the rain on that night
                When you held my hand, and it all felt right
                We were two hearts learning how to beat
                Now I walk alone on this empty street
                
                Chorus:
                And I hope you're smiling where you are
                Even if we drifted far
                ...
                """

                let insets = UIEdgeInsets(top: 12, left: 12, bottom: 12, right: 12)
                let editorHeight: CGFloat = (selectedInputType == .description) ? 120 : 200
                let expandAnim = Animation.spring(response: 0.35, dampingFraction: 0.9, blendDuration: 0.2)

                ZStack(alignment: .topLeading) {
                    // Card nền
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color.black.opacity(0.30))
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(AivoTheme.Primary.orange.opacity(0.30), lineWidth: 1)
                        )
                        .frame(height: editorHeight)
                        .animation(expandAnim, value: selectedInputType)

                    // Placeholder (đặt đúng vị trí theo insets)
                    Group {
                        if selectedInputType == .description, songDescription.isEmpty {
                            Text("Describe the music and topic you want (e.g. make a chill song about overcoming my biggest regret)")
                                .font(.system(size: 14))
                                .foregroundColor(.white.opacity(0.75)) // hint bớt mờ
                                .padding(EdgeInsets(top: insets.top, leading: insets.left, bottom: 0, trailing: insets.right))
                        } else if selectedInputType == .lyrics, songLyrics.isEmpty {
                            Text(lyrics)
                                .font(.system(size: 14))
                                .foregroundColor(.white.opacity(0.75))
                                .padding(EdgeInsets(top: insets.top, leading: insets.left, bottom: 0, trailing: insets.right))
                        }
                    }

                    // TextEditor đã tuỳ biến (căn top đúng, cuộn nội bộ)
                    if selectedInputType == .description {
                        PaddedTextEditor(text: $songDescription,
                                         font: .systemFont(ofSize: 14),
                                         textColor: .white,
                                         insets: insets,
                                         autocap: .sentences,
                                         autocorrect: true)
                        .frame(height: editorHeight)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                        .animation(expandAnim, value: selectedInputType)
                    } else {
                        PaddedTextEditor(text: $songLyrics,
                                         font: .systemFont(ofSize: 14),
                                         textColor: .white,
                                         insets: insets,
                                         autocap: .none,
                                         autocorrect: false)
                        .frame(height: editorHeight)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                        .animation(expandAnim, value: selectedInputType)
                    }

                    // Counter dưới-phải (nằm trong khung, không tràn)
                    VStack {
                        Spacer()
                        HStack {
                            Spacer()
                            Text("\(selectedInputType == .description ? songDescription.count : songLyrics.count) / \(selectedInputType == .description ? 128 : 1950)")
                                .font(.caption)
                                .foregroundColor(.white.opacity(0.6))
                                .padding(.trailing, 10)
                                .padding(.bottom, 8)
                        }
                    }
                    .frame(height: editorHeight)
                }
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.black.opacity(0.2))
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(AivoTheme.Primary.orange, lineWidth: 1)
                )
        )
    }

    
    // MARK: - Mood Selection Section
    private var moodSelectionSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Select Mood (Optional)")
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(.white)
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(SongMood.getHottest().prefix(10), id: \.self) { mood in
                        Button(action: {
                            toggleMoodSelection(mood)
                        }) {
                            Text(mood.displayName)
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(.white)
                                .padding(.horizontal, 16)
                                .padding(.vertical, 10)
                                .background(
                                    RoundedRectangle(cornerRadius: 8)
                                        .fill(selectedMoods.contains(mood) ? AivoTheme.Secondary.coralRed : Color.gray.opacity(0.3))
                                )
                        }
                    }
                    
                    Button(action: {
                        showMultiMoodScreen = true
                    }) {
                        Text("More")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.white)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 10)
                            .background(
                                RoundedRectangle(cornerRadius: 8)
                                    .fill(Color.clear)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 8)
                                            .stroke(Color.white.opacity(0.3), lineWidth: 1)
                                    )
                            )
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
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(.white)
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(SongGenre.allCases, id: \.self) { genre in
                        Button(action: {
                            toggleGenreSelection(genre)
                        }) {
                            VStack(spacing: 4) {
                                Image(genre.icon)
                                    .resizable()
                                    .aspectRatio(contentMode: .fit)
                                    .frame(width: 60, height: 60)
                                
                                Text(genre.displayName)
                                    .font(.system(size: 12, weight: .medium))
                                    .foregroundColor(.white)
                            }
                            .frame(width: 88, height: 88)
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(selectedGenres.contains(genre) ? AivoTheme.Primary.orangeDark : Color.gray.opacity(0.3))
                            )
                        }
                    }
                }
                .padding(.horizontal, 4)
            }
        }
    }
    
    // MARK: - Advanced Options Section
    private var advancedOptionsSection: some View {
            VStack(spacing: 0) {
                // Main container that looks like a button when collapsed
                VStack(spacing: 0) {
                    // Header - always visible
                    Button(action: {
                        withAnimation(.easeInOut(duration: 0.3)) {
                            isAdvancedExpanded.toggle()
                        }
                    }) {
                        HStack {
                            Text("Advanced Options")
                                .font(.system(size: 16, weight: .medium))
                                .foregroundColor(.white)
                            
                            Text("🥁")
                                .font(.system(size: 16))
                            
                            Spacer()
                            
                            Image(systemName: isAdvancedExpanded ? "chevron.up" : "chevron.down")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(.white)
                        }
                        .padding(16)
                    }
                    .buttonStyle(.plain)
                    
                    // Expandable content
                    if isAdvancedExpanded {
                        VStack(spacing: 16) {
                            Divider()
                                .background(AivoTheme.Primary.orange.opacity(0.3))
                            
                            // Song Name
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Song Name (Optional)")
                                    .font(.system(size: 14, weight: .medium))
                                    .foregroundColor(.white)
                                
                                TextField("Name", text: $songName)
                                    .font(.system(size: 14))
                                    .foregroundColor(.white)
                                    .padding(12)
                                    .background(
                                        RoundedRectangle(cornerRadius: 8)
                                            .fill(Color.white.opacity(0.1))
                                    )
                            }
                            
                            // Vocal Gender - Always visible, no toggle
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Vocal Gender")
                                    .font(.system(size: 14, weight: .medium))
                                    .foregroundColor(.white)
                                
                                HStack(spacing: 6) {
                                    ForEach(VocalGender.allCases, id: \.self) { gender in
                                        Button(action: {
                                            selectedVocalGender = gender
                                        }) {
                                            Text(gender.rawValue)
                                                .font(.system(size: 14, weight: .medium))
                                                .foregroundColor(selectedVocalGender == gender ? .black : .white)
                                                .frame(maxWidth: .infinity)
                                                .padding(.vertical, 12)
                                                .background(
                                                    RoundedRectangle(cornerRadius: 8)
                                                        .fill(selectedVocalGender == gender ? AivoTheme.Primary.orange : Color.gray.opacity(0.3))
                                                )
                                        }
                                    }
                                }
                            }
                        }
                        .padding(.horizontal, 16)
                        .padding(.bottom, 16)
                    }
                }
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color.black.opacity(0.2))
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(AivoTheme.Primary.orange, lineWidth: 1)
                        )
                )
            }
        }
    
    // MARK: - Create Button
    private var createButton: some View {
        Button(action: {}) {
            HStack(spacing: 8) {
                Text(selectedInputType == .description ? "Create with Description" : "Create with Lyrics")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.black)
                
                HStack(spacing: 2) {
                    Text("♪")
                        .font(.system(size: 14))
                    Text("♪")
                        .font(.system(size: 14))
                    Text("♪")
                        .font(.system(size: 14))
                }
                .foregroundColor(.black)
            }
            .frame(maxWidth: .infinity)
            .frame(height: 50)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(AivoTheme.Primary.orange)
            )
        }
    }
    
    // MARK: - Helper Methods
    private func toggleMoodSelection(_ mood: SongMood) {
        if selectedMoods.contains(mood) {
            selectedMoods.removeAll { $0 == mood }
        } else {
            if selectedMoods.count >= 3 {
                selectedMoods.removeFirst()
            }
            selectedMoods.append(mood)
        }
    }
    
    private func toggleGenreSelection(_ genre: SongGenre) {
        if selectedGenres.contains(genre) {
            selectedGenres.removeAll { $0 == genre }
        } else {
            if selectedGenres.count >= 3 {
                selectedGenres.removeFirst()
            }
            selectedGenres.append(genre)
        }
    }
}

// MARK: - PaddedTextEditor
struct PaddedTextEditor: UIViewRepresentable {
    @Binding var text: String
    var font: UIFont = .systemFont(ofSize: 14)
    var textColor: UIColor = .white
    var insets: UIEdgeInsets = UIEdgeInsets(top: 12, left: 12, bottom: 12, right: 12)
    var autocap: UITextAutocapitalizationType = .sentences
    var autocorrect: Bool = true

    func makeUIView(context: Context) -> UITextView {
        let tv = UITextView()
        tv.backgroundColor = .clear
        tv.textContainerInset = insets
        tv.textContainer.lineFragmentPadding = 0
        tv.isScrollEnabled = true
        tv.alwaysBounceVertical = true
        tv.showsVerticalScrollIndicator = true
        tv.font = font
        tv.textColor = textColor
        tv.autocapitalizationType = autocap
        tv.autocorrectionType = autocorrect ? .yes : .no
        tv.delegate = context.coordinator
        return tv
    }

    func updateUIView(_ uiView: UITextView, context: Context) {
        if uiView.text != text {
            uiView.text = text
        }
        uiView.font = font
        uiView.textColor = textColor
        uiView.textContainerInset = insets
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    final class Coordinator: NSObject, UITextViewDelegate {
        var parent: PaddedTextEditor
        init(_ parent: PaddedTextEditor) { self.parent = parent }
        func textViewDidChange(_ textView: UITextView) {
            parent.text = textView.text ?? ""
        }
    }
}

// MARK: - Preview
struct GenerateSongTabView_Previews: PreviewProvider {
    static var previews: some View {
        ZStack {
            AivoSunsetBackground()
            GenerateSongTabView()
        }
    }
}
