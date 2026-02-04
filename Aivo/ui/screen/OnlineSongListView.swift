import SwiftUI

struct OnlineSongListView: View {
    let title: String
    let songs: [SunoData]
    @Environment(\.dismiss) private var dismiss
    @ObservedObject private var audioPlayer = MusicPlayer.shared // Use Aivo's MusicPlayer
    
    // State for full player
    @State private var selectedSongForPlayback: SongPlaybackItem? = nil

    struct SongPlaybackItem: Identifiable {
        let id: String
        let songs: [SunoData]
        let initialIndex: Int
        
        init(songs: [SunoData], initialIndex: Int) {
            self.id = songs[initialIndex].id
            self.songs = songs
            self.initialIndex = initialIndex
        }
    }

    var body: some View {
        ZStack {
            // Background
            AivoSunsetBackground() // Use Aivo's background
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Header
                headerView
                
                // Songs List
                if songs.isEmpty {
                    emptyStateView
                } else {
                    songListView
                }
            }
        }
        .fullScreenCover(item: $selectedSongForPlayback) { item in
            PlayOnlineSongScreen(songs: item.songs, initialIndex: item.initialIndex)
        }
        .navigationBarHidden(true)
    }
    
    // ...
    // Keep headerView and songListView helpers
    // ...
    
    private var headerView: some View {
        ZStack {
            // Back button
            HStack {
                Button(action: { dismiss() }) {
                    Image(systemName: "chevron.left")
                        .font(.title3)
                        .foregroundColor(.white)
                }
                
                Spacer()
                
                // Song count
                Text("(\(songs.count))")
                    .font(.subheadline)
                    .foregroundColor(.white.opacity(0.6))
            }
            
            // Title centered
            Text(title)
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(.white)
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 16)
    }
    
    private var songListView: some View {
        ScrollView {
            VStack(spacing: 12) {
                ForEach(Array(songs.enumerated()), id: \.element.id) { index, song in
                    let isPlaying = isPlayingSong(song)
                    
                    OnlineSongRow(
                        song: song,
                        isPlaying: isPlaying,
                        onPlayPause: isPlaying ? {
                            // If playing, toggle pause. If paused, resume.
                            // However, we normally open player on tap.
                            // Here we just toggle play/pause on the row button.
                            MusicPlayer.shared.togglePlayPause()
                        } : nil
                    )
                    .onTapGesture {
                        playSong(song, at: index)
                    }
                }
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 16)
            .padding(.bottom, 100) // Bottom padding for player
        }
    }
    
    // ...
    // Keep emptyStateView
    // ...
    
    private var emptyStateView: some View {
        VStack(spacing: 16) {
            Image(systemName: "music.note")
                .font(.system(size: 48))
                .foregroundColor(.gray)
            
            Text("No songs found")
                .font(.headline)
                .foregroundColor(.white.opacity(0.7))
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    private func isPlayingSong(_ song: SunoData) -> Bool {
        guard let currentSong = audioPlayer.currentSong, audioPlayer.isPlaying else { return false }
        return currentSong.id == song.id
    }
    
    private func playSong(_ song: SunoData, at index: Int) {
        selectedSongForPlayback = SongPlaybackItem(songs: songs, initialIndex: index)
    }
}
