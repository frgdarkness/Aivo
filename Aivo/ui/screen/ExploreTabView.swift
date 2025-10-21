import SwiftUI

// MARK: - Explore Tab View
struct ExploreTabView: View {
    @State private var selectedCategory: ExploreCategory = .popular
    
    var body: some View {
        VStack(spacing: 0) {
            // Category Tabs
            categoryTabs
            
            // Song List
            songListView
        }
    }
    
    // MARK: - Category Tabs
    private var categoryTabs: some View {
        HStack(spacing: 0) {
            ForEach(ExploreCategory.allCases, id: \.self) { category in
                Button(action: { selectedCategory = category }) {
                    Text(category.rawValue)
                        .font(.headline)
                        .fontWeight(.medium)
                        .foregroundColor(selectedCategory == category ? .black : .white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(
                            RoundedRectangle(cornerRadius: 8)
                                .fill(selectedCategory == category ? AivoTheme.Primary.orange : Color.clear)
                        )
                }
            }
        }
        .padding(.horizontal, 20)
        .padding(.bottom, 20)
    }
    
    // MARK: - Song List View
    private var songListView: some View {
        ScrollView {
            LazyVStack(spacing: 12) {
                ForEach(selectedCategory == .popular ? popularSongs : newSongs, id: \.id) { song in
                    SongRowView(song: song)
                }
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 100) // Space for bottom nav
        }
    }
}

// MARK: - Song Row View
struct SongRowView: View {
    let song: SongItem
    
    var body: some View {
        HStack(spacing: 12) {
            // Album Art
            ZStack {
                RoundedRectangle(cornerRadius: 8)
                    .fill(song.albumArtColor)
                    .frame(width: 60, height: 60)
                
                Image(systemName: song.albumArtIcon)
                    .font(.title2)
                    .foregroundColor(.white)
            }
            
            // Song Info
            VStack(alignment: .leading, spacing: 4) {
                Text(song.title)
                    .font(.headline)
                    .fontWeight(.medium)
                    .foregroundColor(.white)
                    .lineLimit(1)
                
                HStack(spacing: 16) {
                    HStack(spacing: 4) {
                        Image(systemName: "play.fill")
                            .font(.caption)
                            .foregroundColor(.gray)
                        
                        Text("\(song.playCount)")
                            .font(.caption)
                            .foregroundColor(.gray)
                    }
                    
                    HStack(spacing: 4) {
                        Image(systemName: "heart.fill")
                            .font(.caption)
                            .foregroundColor(.gray)
                        
                        Text("\(song.likeCount)")
                            .font(.caption)
                            .foregroundColor(.gray)
                    }
                }
            }
            
            Spacer()
            
            // Play Button
            Button(action: { playSong(song) }) {
                Image(systemName: "play.fill")
                    .font(.title2)
                    .foregroundColor(.white)
                    .frame(width: 40, height: 40)
                    .background(
                        Circle()
                            .fill(Color.gray.opacity(0.3))
                    )
            }
        }
        .padding(.vertical, 8)
    }
    
    private func playSong(_ song: SongItem) {
        print("Playing: \(song.title)")
    }
}

// MARK: - Supporting Models
enum ExploreCategory: String, CaseIterable {
    case popular = "Popular"
    case new = "New"
}

struct SongItem: Identifiable {
    let id = UUID()
    let title: String
    let playCount: Int
    let likeCount: Int
    let albumArtIcon: String
    let albumArtColor: Color
}

// MARK: - Sample Data
extension ExploreTabView {
    private var popularSongs: [SongItem] {
        [
            SongItem(title: "Stars and Whispers", playCount: 5400, likeCount: 8092, albumArtIcon: "heart.fill", albumArtColor: .pink),
            SongItem(title: "Sunshine and Starlight", playCount: 4200, likeCount: 6543, albumArtIcon: "sun.max.fill", albumArtColor: .orange),
            SongItem(title: "Shine On My Love", playCount: 3800, likeCount: 5921, albumArtIcon: "flower.fill", albumArtColor: .yellow),
            SongItem(title: "Chasing the Dawn", playCount: 3600, likeCount: 5432, albumArtIcon: "sunrise.fill", albumArtColor: .blue),
            SongItem(title: "My Little Sunshine", playCount: 3200, likeCount: 4876, albumArtIcon: "cat.fill", albumArtColor: .green),
            SongItem(title: "Future Self Rising", playCount: 2900, likeCount: 4321, albumArtIcon: "bird.fill", albumArtColor: .purple),
            SongItem(title: "Future Me (Warrior)", playCount: 2700, likeCount: 3987, albumArtIcon: "person.fill", albumArtColor: .red),
            SongItem(title: "Unbreakable Fire", playCount: 2500, likeCount: 3654, albumArtIcon: "flame.fill", albumArtColor: .orange)
        ]
    }
    
    private var newSongs: [SongItem] {
        [
            SongItem(title: "Digital Dreams", playCount: 1200, likeCount: 2100, albumArtIcon: "laptopcomputer", albumArtColor: .blue),
            SongItem(title: "Neon Nights", playCount: 980, likeCount: 1876, albumArtIcon: "moon.fill", albumArtColor: .purple),
            SongItem(title: "Electric Soul", playCount: 850, likeCount: 1654, albumArtIcon: "bolt.fill", albumArtColor: .yellow),
            SongItem(title: "Cosmic Journey", playCount: 720, likeCount: 1432, albumArtIcon: "globe", albumArtColor: .green),
            SongItem(title: "Midnight Melodies", playCount: 650, likeCount: 1287, albumArtIcon: "music.note", albumArtColor: .indigo),
            SongItem(title: "Urban Vibes", playCount: 580, likeCount: 1154, albumArtIcon: "building.2.fill", albumArtColor: .gray),
            SongItem(title: "Ocean Waves", playCount: 520, likeCount: 987, albumArtIcon: "wave.3.right", albumArtColor: .cyan),
            SongItem(title: "Mountain Echoes", playCount: 480, likeCount: 876, albumArtIcon: "mountain.2.fill", albumArtColor: .brown)
        ]
    }
}

// MARK: - Preview
struct ExploreTabView_Previews: PreviewProvider {
    static var previews: some View {
        ExploreTabView()
    }
}
