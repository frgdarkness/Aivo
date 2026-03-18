import SwiftUI

// MARK: - Select Multi Mood Screen
struct SelectMultiMoodScreen: View {
    let initialSelectedMoods: [SongMood]
    let onDone: ([SongMood]) -> Void
    let onCancel: () -> Void
    
    @State private var selectedMoods: [SongMood] = []
    @State private var searchText = ""
    @Environment(\.dismiss) private var dismiss
    
    init(initialSelectedMoods: [SongMood] = [], onDone: @escaping ([SongMood]) -> Void, onCancel: @escaping () -> Void) {
        self.initialSelectedMoods = initialSelectedMoods
        self.onDone = onDone
        self.onCancel = onCancel
    }
    
    var filteredMoods: [SongMood] {
        if searchText.isEmpty {
            return SongMood.allCases
        } else {
            return SongMood.allCases.filter { mood in
                mood.displayName.localizedCaseInsensitiveContains(searchText)
            }
        }
    }
    
    var body: some View {
        ZStack {
            // Background
            AivoSunsetBackground()
            
            VStack(spacing: 0) {
                // Header
                headerView
                
                // Search Bar
                searchBar
                
                // Content
                ScrollView {
                    LazyVGrid(columns: [
                        GridItem(.flexible(), spacing: iPadScaleSmall(12)),
                        GridItem(.flexible(), spacing: iPadScaleSmall(12)),
                        GridItem(.flexible(), spacing: iPadScaleSmall(12))
                    ], spacing: iPadScaleSmall(18)) {
                        ForEach(filteredMoods, id: \.self) { mood in
                            moodChipView(mood: mood)
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.vertical, 12)
                }
                
                // Bottom buttons
                bottomButtonsView
            }
        }
        .onAppear {
            selectedMoods = initialSelectedMoods
        }
    }
    
    // MARK: - Header View
    private var headerView: some View {
        HStack {
            Button(action: {
                onCancel()
                dismiss()
            }) {
                Image(systemName: "xmark")
                    .font(.system(size: iPadScale(22)))
                    .foregroundColor(.white)
            }
            
            Spacer()
            
            Text("Select Mood")
                .font(.system(size: iPadScale(20), weight: .bold))
                .foregroundColor(.white)
            
            Spacer()
            
            // Placeholder for symmetry
            Color.clear
                .frame(width: iPadScale(24), height: iPadScale(24))
        }
        .padding(.horizontal, 20)
        .padding(.top, 10)
        .padding(.bottom, 16)
    }
    
    // MARK: - Search Bar
    private var searchBar: some View {
        HStack {
            Image(systemName: "magnifyingglass")
                .font(.system(size: iPadScale(16)))
                .foregroundColor(.gray)
                .padding(.leading, 12)
            
            TextField("Search Mood", text: $searchText)
                .textFieldStyle(PlainTextFieldStyle())
                .font(.system(size: iPadScale(16)))
                .foregroundColor(.white)
                .padding(.vertical, iPadScaleSmall(12))
            
            if !searchText.isEmpty {
                Button(action: {
                    searchText = ""
                }) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: iPadScale(16)))
                        .foregroundColor(.gray)
                }
                .padding(.trailing, 12)
            }
        }
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(Color.gray.opacity(0.2))
        )
        .padding(.horizontal, 20)
        .padding(.bottom, 16)
    }
    
    // MARK: - Mood Chip View
    // MARK: - Mood Chip View
    private func moodChipView(mood: SongMood) -> some View {
        Button(action: {
            toggleMoodSelection(mood)
        }) {
            Text(mood.displayName)
                .font(.system(size: iPadScale(14), weight: .medium))
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, iPadScaleSmall(14))
                .background(
                    Capsule()
                        .fill(Color.clear)
                        .overlay(
                            Capsule()
                                .stroke(selectedMoods.contains(mood) ? AivoTheme.Secondary.coralRed : Color.white.opacity(0.3), lineWidth: 1)
                        )
                )
        }
        .buttonStyle(.plain)
    }

    
    // MARK: - Bottom Buttons View
    private var bottomButtonsView: some View {
        VStack(spacing: 12) {
            Button(action: {
                onDone(selectedMoods)
                dismiss()
            }) {
                Text("Done")
                    .font(.system(size: iPadScale(16), weight: .semibold))
                    .foregroundColor(.black)
                    .frame(maxWidth: .infinity)
                    .frame(height: iPadScale(50))
                    .background(
                        RoundedRectangle(cornerRadius: iPadScale(12))
                            .fill(AivoTheme.Primary.orange)
                    )
            }
            .disabled(selectedMoods.isEmpty)
            .opacity(selectedMoods.isEmpty ? 0.5 : 1.0)
        }
        .padding(.horizontal, 20)
        .padding(.vertical, iPadScaleSmall(14))
        .background(
            Rectangle()
                .fill(AivoTheme.Background.primary)
                .shadow(color: .black.opacity(0.3), radius: 10, x: 0, y: -5)
        )
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
}

// MARK: - Preview
struct SelectMultiMoodScreen_Previews: PreviewProvider {
    static var previews: some View {
        SelectMultiMoodScreen(
            onDone: { moods in
                print("Selected moods: \(moods)")
            },
            onCancel: {
                print("Cancelled")
            }
        )
    }
}
