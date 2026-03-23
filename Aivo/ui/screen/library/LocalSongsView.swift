import SwiftUI
import UniformTypeIdentifiers

struct LocalSongsView: View {
    @Binding var currentSort: LibrarySortOption
    @State private var localSongs: [SunoData] = []
    @State private var showFilePicker = false
    @State private var showingImportError = false
    @State private var importErrorMessage = ""
    @State private var isLoading = false
    
    // For navigation to Player
    @State private var showPlayMySongScreen = false
    @State private var selectedSongIndex = 0
    
    private var sortedLocalSongs: [SunoData] {
        switch currentSort {
        case .aToZ:
            return localSongs.sorted { ($0.title).lowercased() < ($1.title).lowercased() }
        case .zToA:
            return localSongs.sorted { ($0.title).lowercased() > ($1.title).lowercased() }
        case .newest:
            return localSongs.sorted { ($0.createTime) > ($1.createTime) }
        case .oldest:
            return localSongs.sorted { ($0.createTime) < ($1.createTime) }
        }
    }
    
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
                songs: sortedLocalSongs,
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
                .font(.system(size: iPadScale(60)))
                .foregroundColor(.gray)
            
            Text("No Local Songs")
                .font(.system(size: iPadScale(22), weight: .bold))
                .foregroundColor(.white)
            
            Text("Import audio files from your device to play them here.")
                .font(.system(size: iPadScale(15)))
                .foregroundColor(.gray)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
            
            Button(action: { showFilePicker = true }) {
                Text("Import Songs")
                    .font(.system(size: iPadScale(17), weight: .semibold))
                    .foregroundColor(.black)
                    .frame(height: iPadScale(50))
                    .frame(maxWidth: .infinity)
                    .background(AivoTheme.Primary.orange)
                    .cornerRadius(iPadScale(12))
            }
            .padding(.horizontal, 40)
            .padding(.top, 20)
            Spacer()
        }
    }
    
    private var listContent: some View {
        ScrollView {
            LazyVStack(spacing: 6) { // Spacing 6 to match AI Songs
                let sortedList = sortedLocalSongs
                ForEach(Array(sortedList.enumerated()), id: \.element.id) { index, song in
                    Button(action: {
                        playSong(index: index)
                    }) {
                        // Card Background
                        let coverSize: CGFloat = DeviceScale.isIPad ? 90 : 60
                        
                        ZStack {
                            RoundedRectangle(cornerRadius: iPadScale(12))
                                .fill(Color.white.opacity(0.05))
                                .overlay(
                                    RoundedRectangle(cornerRadius: iPadScale(12))
                                        .stroke(Color.clear, lineWidth: 2)
                                )
                            
                            HStack(spacing: iPadScaleSmall(12)) {
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
                                .cornerRadius(iPadScale(8))
                                .clipped()
                                .padding(.leading, iPadScaleSmall(12))
                                
                                // Song Info
                                VStack(alignment: .leading, spacing: iPadScaleSmall(4)) {
                                    Text(song.title)
                                        .font(.system(size: iPadScale(17), weight: .medium))
                                        .foregroundColor(.white)
                                        .lineLimit(1)
                                    
                                    HStack(spacing: iPadScaleSmall(12)) {
                                        // Duration
                                        Label(formatDuration(song.duration), systemImage: "clock.fill")
                                            .labelStyle(.titleAndIcon)
                                            .font(.system(size: iPadScale(12)))
                                            .foregroundColor(.gray)
                                            .lineLimit(1)
                                        
                                        // Artist / Username
                                        Text(displayArtist(for: song))
                                            .font(.system(size: iPadScale(12)))
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
                                        .font(.system(size: iPadScale(20)))
                                        .foregroundColor(.white)
                                        .frame(width: iPadScale(40), height: iPadScale(40))
                                        .contentShape(Rectangle())
                                }
                                .padding(.trailing, iPadScaleSmall(12))
                            }
                            .frame(height: DeviceScale.isIPad ? 110 : 76)
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
                    .font(.system(size: iPadScale(22), weight: .bold))
                    .foregroundColor(.white)
                    .frame(width: iPadScale(56), height: iPadScale(56))
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
        Task {
            if song.modelName == "Local" {
                LocalSongManager.shared.deleteLocalSong(song)
            } else {
                try? await SunoDataManager.shared.deleteSunoData(song)
            }
            refreshSongs()
        }
    }
    private func refreshSongs() {
        isLoading = true
        Task {
            // 1. Fetch Local Imported Songs
            let importedSongs = LocalSongManager.shared.fetchLocalSongs()
            
            // 2. Fetch AI Downloaded Songs (Async)
            var aiSongs: [SunoData] = []
            do {
                aiSongs = try await SunoDataManager.shared.loadAllSavedSunoData()
            } catch {
                print("❌ [LocalSongsView] Error loading AI songs: \(error)")
            }
            
            // 3. Merge and Sort
            await MainActor.run {
                // Combine lists
                let allSongs = importedSongs + aiSongs
                
                // Remove duplicates if any (based on ID)
                let uniqueSongs = Array(Dictionary(grouping: allSongs, by: { $0.id })
                                            .compactMap { $0.value.first })
                
                // Sort by createTime descending (newest first)
                self.localSongs = uniqueSongs.sorted(by: { $0.createTime > $1.createTime })
                
                self.isLoading = false
            }
        }
    }
    
    private func importSongs(from urls: [URL]) {
        isLoading = true
        Task {
            var successCount = 0
            var errors: [String] = []
            
            for url in urls {
                do {
                    _ = try await LocalSongManager.shared.importAndSaveSong(from: url)
                    successCount += 1
                } catch {
                    Logger.e("❌ [LocalSongsView] Import failed: \(error.localizedDescription)")
                    errors.append(error.localizedDescription)
                }
            }
            
            await MainActor.run {
                self.refreshSongs()
                if !errors.isEmpty {
                    self.importErrorMessage = "Imported \(successCount) songs. Failed: \(errors.count)"
                    self.showingImportError = true
                }
            }
        }
    }
    
    private func deleteSongs(at offsets: IndexSet) {
        let sortedList = sortedLocalSongs
        for index in offsets {
            let song = sortedList[index]
            LocalSongManager.shared.deleteLocalSong(song)
        }
        refreshSongs()
    }
    
    private func playSong(index: Int) {
        selectedSongIndex = index
        let sortedList = sortedLocalSongs
        MusicPlayer.shared.loadSong(sortedList[index], at: index, in: sortedList)
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
    
    private func displayArtist(for song: SunoData) -> String {
        if song.id.hasPrefix("local_") || song.modelName == "Local" {
            return song.username ?? "Unknown Artist"
        }
        return song.username ?? "Aivo Music"
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
