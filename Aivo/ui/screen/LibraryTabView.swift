import SwiftUI

// MARK: - Library Tab View
struct LibraryTabView: View {
    @State private var songs: [LibrarySong] = [] // Empty by default to show empty state
    @State private var downloadedSongs: [SunoData] = []
    @State private var showPlayMySongScreen = false
    @State private var selectedSongIndex = 0
    
    var body: some View {
        VStack(spacing: 0) {
            // Content
            if downloadedSongs.isEmpty {
                emptyStateView
            } else {
                downloadedSongsListView
            }
        }
        .onAppear {
            loadDownloadedSongs()
        }
        .fullScreenCover(isPresented: $showPlayMySongScreen) {
            PlayMySongScreen(
                songs: downloadedSongs,
                initialIndex: selectedSongIndex
            )
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
    
    // MARK: - Downloaded Songs List View
    private var downloadedSongsListView: some View {
        ScrollView {
            LazyVStack(spacing: 6) {
                ForEach(Array(downloadedSongs.enumerated()), id: \.element.id) { index, song in
                    DownloadedSongRowView(
                        song: song, 
                        index: index,
                        onTap: {
                            selectedSongIndex = index
                            showPlayMySongScreen = true
                        }
                    )
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
    
    private func loadDownloadedSongs() {
        print("📚 [Library] Loading downloaded songs...")
        
        Task {
            do {
                let sunoDataList = try await SunoDataManager.shared.loadAllSavedSunoData()
                await MainActor.run {
                    self.downloadedSongs = sunoDataList
                    print("📚 [Library] Loaded \(sunoDataList.count) songs into library")
                    for song in sunoDataList {
                        print("📚 [Library] - \(song.title) (\(song.modelName))")
                    }
                }
            } catch {
                print("❌ [Library] Error loading downloaded songs: \(error)")
                await MainActor.run {
                    self.downloadedSongs = []
                }
            }
        }
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

// MARK: - Downloaded Song Row View
struct DownloadedSongRowView: View {
    let song: SunoData
    let index: Int
    let onTap: () -> Void
    
    var body: some View {
        // Card nền
        ZStack {
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.white.opacity(0.05))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.clear, lineWidth: 2)
                )

            // Nội dung: ảnh (trái sát), info (giữa), nút (phải sát)
            HStack(spacing: 12) {
                let coverSize: CGFloat = 60

                ZStack {
                    // Cover image from saved SunoData
                    AsyncImage(url: URL(string: song.imageUrl)) { image in
                        image
                            .resizable()
                            .scaledToFill()
                    } placeholder: {
                        Image("demo_cover")
                            .resizable()
                            .scaledToFill()
                    }
                    .frame(width: coverSize, height: coverSize)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                }
                .frame(width: coverSize, height: coverSize)
                .padding(.leading, 12)

                // INFO: chiếm toàn bộ phần còn lại
                VStack(alignment: .leading, spacing: 4) {
                    Text(song.title)
                        .font(.headline).fontWeight(.medium)
                        .foregroundColor(.white)
                        .lineLimit(1).truncationMode(.tail)

                    HStack(spacing: 12) {
                        Label(formatDuration(song.duration), systemImage: "clock.fill")
                            .labelStyle(.titleAndIcon)
                            .font(.caption)
                            .foregroundColor(.gray)
                            .lineLimit(1)

                        Label(song.modelName, systemImage: "music.note")
                            .labelStyle(.titleAndIcon)
                            .font(.caption)
                            .foregroundColor(.gray)
                            .lineLimit(1)

                        Label("Saved", systemImage: "checkmark.circle.fill")
                            .labelStyle(.titleAndIcon)
                            .font(.caption)
                            .foregroundColor(.green)
                            .lineLimit(1)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .layoutPriority(1)

                // BUTTON: sát mép phải card
                Button {
                    onTap()
                } label: {
                    Image(systemName: "play.fill")
                        .font(.title2)
                        .foregroundColor(.white)
                        .frame(width: 40, height: 40)
                        .background(
                            Circle().fill(AivoTheme.Primary.orange)
                        )
                }
                .padding(.trailing, 12)
            }
            .frame(height: 76)
            .contentShape(RoundedRectangle(cornerRadius: 12))
        }
        .padding(.vertical, 4)
        .onTapGesture {
            onTap()
        }
    }
    
    private func playDownloadedSong(_ song: SunoData) {
        print("🎵 [Library] Playing downloaded song: \(song.title)")
        print("🎵 [Library] Audio URL: \(song.audioUrl)")
        
        // Convert string URL back to URL
        guard let url = URL(string: song.audioUrl) else {
            print("❌ [Library] Invalid URL for song: \(song.title)")
            return
        }
        
        // TODO: Implement audio playback for library songs
        // This could open a player screen or play directly
        // For now, just log the action
        print("🎵 [Library] Would play song from: \(url.path)")
    }
    
    private func formatDuration(_ duration: Double) -> String {
        let m = Int(duration) / 60
        let s = Int(duration) % 60
        return String(format: "%d:%02d", m, s)
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
