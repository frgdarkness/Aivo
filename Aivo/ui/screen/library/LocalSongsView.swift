import SwiftUI
import UniformTypeIdentifiers

struct LocalSongsView: View {
    @State private var localSongs: [SunoData] = []
    @State private var showFilePicker = false
    @State private var showingImportError = false
    @State private var importErrorMessage = ""
    @State private var isLoading = false
    
    // For navigation to Player
    @State private var showPlayMySongScreen = false
    @State private var selectedSongIndex = 0
    
    var body: some View {
        VStack {
            if isLoading {
                VStack(spacing: 16) {
                    Spacer()
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: AivoTheme.Primary.orange))
                        .scaleEffect(1.5)
                    
                    Text("Loading...")
                        .font(.headline)
                        .foregroundColor(.white)
                    Spacer()
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if localSongs.isEmpty {
                emptyState
            } else {
                listContent
            }
        }
        .onAppear {
            refreshSongs()
        }
        .sheet(isPresented: $showFilePicker) {
            DocumentPicker(supportedTypes: [.audio]) { urls in
                importSongs(from: urls)
            }
        }
        .alert("Import Failed", isPresented: $showingImportError) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(importErrorMessage)
        }
        .fullScreenCover(isPresented: $showPlayMySongScreen) {
            PlayMySongScreen(
                songs: localSongs,
                initialIndex: selectedSongIndex
            )
        }
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(action: { showFilePicker = true }) {
                    Image(systemName: "square.and.arrow.down")
                        .foregroundColor(AivoTheme.Primary.orange)
                }
            }
        }
    }
    
    private var emptyState: some View {
        VStack(spacing: 20) {
            Spacer()
            Image(systemName: "music.note.list")
                .font(.system(size: 60))
                .foregroundColor(.gray)
            
            Text("No Local Songs")
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(.white)
            
            Text("Import audio files from your device to play them here.")
                .font(.subheadline)
                .foregroundColor(.gray)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
            
            Button(action: { showFilePicker = true }) {
                Text("Import Songs")
                    .font(.headline)
                    .foregroundColor(.black)
                    .frame(height: 50)
                    .frame(maxWidth: .infinity)
                    .background(AivoTheme.Primary.orange)
                    .cornerRadius(12)
            }
            .padding(.horizontal, 40)
            .padding(.top, 20)
            Spacer()
        }
    }
    
    private var listContent: some View {
        ScrollView {
            LazyVStack(spacing: 6) { // Spacing 6 to match AI Songs
                ForEach(Array(localSongs.enumerated()), id: \.element.id) { index, song in
                    Button(action: {
                        playSong(index: index)
                    }) {
                        // Card Background
                        ZStack {
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color.white.opacity(0.05))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12)
                                        .stroke(Color.clear, lineWidth: 2)
                                )
                            
                            HStack(spacing: 12) {
                                let coverSize: CGFloat = 60
                                
                                // Cover Image
                                ZStack {
                                    if let coverPath = song.coverImageLocalPath,
                                       let image = UIImage(contentsOfFile: coverPath) {
                                        Image(uiImage: image)
                                            .resizable()
                                            .aspectRatio(contentMode: .fill)
                                    } else {
                                        Image("cover_default_resize") // Fallback image
                                            .resizable()
                                            .aspectRatio(contentMode: .fill)
                                    }
                                }
                                .frame(width: coverSize, height: coverSize)
                                .cornerRadius(8)
                                .clipped()
                                .padding(.leading, 12)
                                
                                // Song Info
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(song.title)
                                        .font(.headline)
                                        .fontWeight(.medium)
                                        .foregroundColor(.white)
                                        .lineLimit(1)
                                    
                                    HStack(spacing: 12) {
                                        // Duration
                                        Label(formatDuration(song.duration), systemImage: "clock.fill")
                                            .labelStyle(.titleAndIcon)
                                            .font(.caption)
                                            .foregroundColor(.gray)
                                            .lineLimit(1)
                                        
                                        // "Local" Label
                                        Text("Local")
                                            .font(.caption)
                                            .foregroundColor(.gray)
                                            .lineLimit(1)
                                    }
                                }
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .layoutPriority(1)
                                
                                // Menu Button
                                Menu {
                                    Button(action: {
                                        playSong(index: index)
                                    }) {
                                        Label("Play", systemImage: "play")
                                    }
                                    
                                    Button(action: {
                                        songToAddToPlaylist = song
                                    }) {
                                        Label("Add to Playlist", systemImage: "music.note.list")
                                    }
                                    
                                    Button(action: {
                                        addToQueue(song)
                                    }) {
                                        Label("Add to Queue", systemImage: "text.append")
                                    }
                                    
                                    Button(role: .destructive, action: {
                                        deleteLocalSong(song)
                                    }) {
                                        Label("Delete", systemImage: "trash")
                                    }
                                } label: {
                                    Image(systemName: "ellipsis")
                                        .font(.system(size: 20))
                                        .foregroundColor(.white)
                                        .frame(width: 40, height: 40)
                                        .contentShape(Rectangle())
                                }
                                .padding(.trailing, 12)
                            }
                            .frame(height: 76)
                        }
                    }
                    .padding(.vertical, 4)
                }
            }
            .padding(.horizontal, 20) // Padding 20
            .padding(.bottom, 100)
        }
        .sheet(item: $songToAddToPlaylist) { song in
            AddToPlaylistSheet(song: song)
        }
        .overlay(
            // floating import button
            Button(action: {
                 // Trigger import
                 showFilePicker = true
            }) {
                Image(systemName: "plus")
                    .font(.title2.weight(.bold))
                    .foregroundColor(.white)
                    .frame(width: 56, height: 56)
                    .background(AivoTheme.Primary.orange)
                    .clipShape(Circle())
                    .shadow(color: .black.opacity(0.3), radius: 4, x: 0, y: 4)
            }
            .padding(.trailing, 20)
            .padding(.bottom, 20) // Above tab bar/player
            , alignment: .bottomTrailing
        )
    }
    
    // MARK: - Actions
    @State private var songToAddToPlaylist: SunoData? = nil // Sheet state

    private func deleteLocalSong(_ song: SunoData) {
        LocalSongManager.shared.deleteLocalSong(song)
        refreshSongs()
    }
    private func refreshSongs() {
        isLoading = true
        // Simulate async load if needed, or just run on Main
        DispatchQueue.main.async {
            self.localSongs = LocalSongManager.shared.fetchLocalSongs()
            self.isLoading = false
        }
    }
    
    private func importSongs(from urls: [URL]) {
        isLoading = true
        DispatchQueue.global(qos: .userInitiated).async {
            var successCount = 0
            var errors: [String] = []
            
            for url in urls {
                do {
                     _ = try LocalSongManager.shared.importAndSaveSong(from: url)
                    successCount += 1
                } catch {
                    errors.append(error.localizedDescription)
                }
            }
            
            DispatchQueue.main.async {
                self.refreshSongs()
                if !errors.isEmpty {
                    self.importErrorMessage = "Allowed \(successCount) songs. Failed: \(errors.count)"
                    self.showingImportError = true
                }
            }
        }
    }
    
    private func deleteSongs(at offsets: IndexSet) {
        for index in offsets {
            let song = localSongs[index]
            LocalSongManager.shared.deleteLocalSong(song)
        }
        refreshSongs()
    }
    
    private func playSong(index: Int) {
        selectedSongIndex = index
        MusicPlayer.shared.loadSong(localSongs[index], at: index, in: localSongs)
        showPlayMySongScreen = true
    }
    
    private func addToQueue(_ song: SunoData) {
        MusicPlayer.shared.addToQueue(song)
    }
    
    private func formatDuration(_ duration: Double) -> String {
        let m = Int(duration) / 60
        let s = Int(duration) % 60
        return String(format: "%d:%02d", m, s)
    }
}

// MARK: - Document Picker
struct DocumentPicker: UIViewControllerRepresentable {
    var supportedTypes: [UTType]
    var onPick: ([URL]) -> Void
    
    func makeUIViewController(context: Context) -> UIDocumentPickerViewController {
        let picker = UIDocumentPickerViewController(forOpeningContentTypes: supportedTypes, asCopy: true)
        picker.allowsMultipleSelection = true
        picker.delegate = context.coordinator
        return picker
    }
    
    func updateUIViewController(_ uiViewController: UIDocumentPickerViewController, context: Context) {}
    
    func makeCoordinator() -> Coordinator {
        Coordinator(parent: self)
    }
    
    class Coordinator: NSObject, UIDocumentPickerDelegate {
        let parent: DocumentPicker
        
        init(parent: DocumentPicker) {
            self.parent = parent
        }
        
        func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
            parent.onPick(urls)
        }
    }
}
