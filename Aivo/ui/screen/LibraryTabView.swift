import SwiftUI

// MARK: - Library Tab View
struct LibraryTabView: View {
    @State private var songs: [LibrarySong] = [] // Empty by default to show empty state
    
    var body: some View {
        VStack(spacing: 0) {
            // Content
            if songs.isEmpty {
                emptyStateView
            } else {
                songsListView
            }
        }
    }
    
    // MARK: - Empty State View
    private var emptyStateView: some View {
        VStack(spacing: 24) {
            Spacer()
            
            // Record Player Card
            VStack(spacing: 16) {
                ZStack {
                    RoundedRectangle(cornerRadius: 16)
                        .fill(Color.gray.opacity(0.2))
                        .frame(width: 200, height: 120)
                    
                    // Record Player
                    HStack(spacing: 20) {
                        // Vinyl Record
                        ZStack {
                            Circle()
                                .fill(Color.black)
                                .frame(width: 60, height: 60)
                            
                            Circle()
                                .fill(Color.red)
                                .frame(width: 20, height: 20)
                            
                            // Grooves
                            ForEach(0..<3, id: \.self) { index in
                                Circle()
                                    .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                                    .frame(width: 40 + CGFloat(index * 8), height: 40 + CGFloat(index * 8))
                            }
                        }
                        
                        // Tonearm
                        VStack(spacing: 8) {
                            Rectangle()
                                .fill(Color.white)
                                .frame(width: 2, height: 30)
                                .rotationEffect(.degrees(15))
                            
                            // Control Buttons
                            VStack(spacing: 4) {
                                ForEach(0..<4, id: \.self) { _ in
                                    Circle()
                                        .fill(Color.gray)
                                        .frame(width: 8, height: 8)
                                }
                            }
                        }
                    }
                }
                
                // Empty State Text
                VStack(spacing: 8) {
                    Text("Library is empty")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                    
                    HStack(spacing: 4) {
                        Text("Start using it now and discover")
                            .font(.subheadline)
                            .foregroundColor(.white)
                        
                        Text("AIVO AI")
                            .font(.system(size: 16, weight: .black, design: .monospaced))
                            .foregroundColor(AivoTheme.Primary.orange)
                    }
                }
                
                // Start Creating Button
                Button(action: startCreating) {
                    Text("Start Creating")
                        .font(.headline)
                        .fontWeight(.bold)
                        .foregroundColor(.black)
                        .frame(maxWidth: .infinity)
                        .frame(height: 50)
                        .background(AivoTheme.Primary.orange)
                        .cornerRadius(12)
                        .shadow(color: AivoTheme.Shadow.orange, radius: 10, x: 0, y: 0)
                }
                .padding(.horizontal, 40)
            }
            
            Spacer()
        }
        .padding(.horizontal, 20)
    }
    
    // MARK: - Songs List View
    private var songsListView: some View {
        ScrollView {
            LazyVStack(spacing: 12) {
                ForEach(songs, id: \.id) { song in
                    LibrarySongRowView(song: song)
                }
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 100) // Space for bottom nav
        }
    }
    
    // MARK: - Actions
    private func startCreating() {
        print("Starting to create...")
        // This would typically navigate to the home tab or song creation flow
    }
}

// MARK: - Library Song Row View
struct LibrarySongRowView: View {
    let song: LibrarySong
    
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
                
                Text(song.artist)
                    .font(.subheadline)
                    .foregroundColor(.gray)
                    .lineLimit(1)
                
                Text(song.createdDate, style: .date)
                    .font(.caption)
                    .foregroundColor(.gray)
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
    
    private func playSong(_ song: LibrarySong) {
        print("Playing: \(song.title)")
    }
}

// MARK: - Supporting Models
struct LibrarySong: Identifiable {
    let id = UUID()
    let title: String
    let artist: String
    let createdDate: Date
    let albumArtIcon: String
    let albumArtColor: Color
}

// MARK: - Preview
struct LibraryTabView_Previews: PreviewProvider {
    static var previews: some View {
        LibraryTabView()
    }
}
