import SwiftUI

struct SelectMultiGenreScreen: View {
    let initialSelectedGenres: [SongGenre]
    let onDone: ([SongGenre]) -> Void
    let onCancel: () -> Void
    
    @State private var selectedGenres: [SongGenre] = []
    @State private var searchText = ""
    @Environment(\.dismiss) private var dismiss
    
    init(initialSelectedGenres: [SongGenre] = [], onDone: @escaping ([SongGenre]) -> Void, onCancel: @escaping () -> Void) {
        self.initialSelectedGenres = initialSelectedGenres
        self.onDone = onDone
        self.onCancel = onCancel
    }
    
    var filteredGenres: [SongGenre] {
        if searchText.isEmpty {
            return SongGenre.allCases
        } else {
            return SongGenre.allCases.filter { genre in
                genre.displayName.localizedCaseInsensitiveContains(searchText)
            }
        }
    }
    
    var body: some View {
        ZStack {
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
                    ], spacing: 10) {
                        ForEach(filteredGenres, id: \.self) { genre in
                            genreChipView(genre: genre)
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
            selectedGenres = initialSelectedGenres
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
            
            Text("Select Genre")
                .font(.system(size: 20, weight: .bold))
                .foregroundColor(.white)
            
            Spacer()
            
            // Placeholder for symmetry
            Color.clear
                .frame(width: 24, height: 24)
        }
        .padding(.horizontal, 20)
        .padding(.top, 10)
        .padding(.bottom, 20)
    }
    
    // MARK: - Search Bar
    private var searchBar: some View {
        HStack {
            Image(systemName: "magnifyingglass")
                .foregroundColor(.gray)
            
            TextField("Search Genre", text: $searchText)
                .foregroundColor(.white)
                .autocapitalization(.none)
                .disableAutocorrection(true)
            
            if !searchText.isEmpty {
                Button(action: {
                    searchText = ""
                }) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.gray)
                }
            }
        }
        .padding(.vertical, 10)
        .padding(.horizontal, 15)
        .background(Color.gray.opacity(0.2))
        .cornerRadius(10)
        .padding(.horizontal, 20)
        .padding(.bottom, 10)
    }
    
    // MARK: - Genre Chip View
    private func genreChipView(genre: SongGenre) -> some View {
        Button(action: {
            toggleGenreSelection(genre)
        }) {
            Text(genre.displayName)
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .background(
                    Capsule()
                        .fill(selectedGenres.contains(genre) ? Color.clear : Color.clear)
                        .overlay(
                            Capsule()
                                .stroke(selectedGenres.contains(genre) ? AivoTheme.Secondary.coralRed : Color.white.opacity(0.3), lineWidth: 1)
                        )
                )
        }
    }
    
    // MARK: - Bottom Buttons View
    private var bottomButtonsView: some View {
        HStack(spacing: 12) {

            Button(action: {
                onDone(selectedGenres)
                dismiss()
            }) {
                Text("Done")
                    .font(.headline)
                    .fontWeight(.bold)
                    .foregroundColor(.black)
                    .frame(maxWidth: .infinity)
                    .frame(height: 50)
                    .background(AivoTheme.Primary.orange)
                    .cornerRadius(12)
            }
            .disabled(selectedGenres.isEmpty)
            .opacity(selectedGenres.isEmpty ? 0.5 : 1.0)
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
    private func toggleGenreSelection(_ genre: SongGenre) {
        if selectedGenres.contains(genre) {
            selectedGenres.removeAll { $0 == genre }
        } else {
            if selectedGenres.count >= 5 {
                selectedGenres.removeFirst()
            }
            selectedGenres.append(genre)
        }
    }
}

// MARK: - Preview
struct SelectMultiGenreScreen_Previews: PreviewProvider {
    static var previews: some View {
        SelectMultiGenreScreen(onDone: {_ in}, onCancel: {})
    }
}
