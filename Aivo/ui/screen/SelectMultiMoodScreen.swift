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
                        GridItem(.flexible(), spacing: 12),
                        GridItem(.flexible(), spacing: 12),
                        GridItem(.flexible(), spacing: 12)
                    ], spacing: 18) {
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
                    .font(.title2)
                    .foregroundColor(.white)
            }
            
            Spacer()
            
            Text("Select Mood")
                .font(.system(size: 20, weight: .bold))
                .foregroundColor(.white)
            
            Spacer()
            
            // Placeholder for symmetry
            Color.clear
                .frame(width: 24, height: 24)
        }
        .padding(.horizontal, 20)
        .padding(.top, 10)
        .padding(.bottom, 16)
    }
    
    // MARK: - Search Bar
    private var searchBar: some View {
        HStack {
            Image(systemName: "magnifyingglass")
                .foregroundColor(.gray)
                .padding(.leading, 12)
            
            TextField("Search Mood", text: $searchText)
                .textFieldStyle(PlainTextFieldStyle())
                .foregroundColor(.white)
                .padding(.vertical, 12)
            
            if !searchText.isEmpty {
                Button(action: {
                    searchText = ""
                }) {
                    Image(systemName: "xmark.circle.fill")
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
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(.white)
                .frame(maxWidth: .infinity) // ✅ chiếm toàn bộ chiều rộng cột
                .padding(.vertical, 14)     // chỉ padding theo chiều dọc
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
//            Text("maxium 3")
//                .font(.system(size: 14, weight: .medium))
//                .foregroundColor(.white.opacity(0.8))
//                .padding(.top, 8)
            
            Button(action: {
                onDone(selectedMoods)
                dismiss()
            }) {
                Text("Done")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.black)
                    .frame(maxWidth: .infinity)
                    .frame(height: 50)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(AivoTheme.Primary.orange)
                    )
            }
            .disabled(selectedMoods.isEmpty)
            .opacity(selectedMoods.isEmpty ? 0.5 : 1.0)
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 14)
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
