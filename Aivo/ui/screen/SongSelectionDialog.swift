import SwiftUI
import Kingfisher
import UniformTypeIdentifiers

// MARK: - Song Selection Dialog Modifier
struct SongSelectionDialogModifier: ViewModifier {
    @Binding var isPresented: Bool
    let onSelectSong: (SelectedSong, URL?) -> Void
    
    func body(content: Content) -> some View {
        ZStack {
            content
            
            if isPresented {
                // Backdrop
                Rectangle()
                    .fill(Color.black.opacity(0.45))
                    .ignoresSafeArea()
                    .transition(.opacity)
                    .onTapGesture {
                        withAnimation(.spring()) { isPresented = false }
                    }
                
                // Dialog Card
                SongSelectionDialogCard(
                    onClose: { withAnimation(.spring()) { isPresented = false } },
                    onSelectSong: onSelectSong
                )
                .padding(.horizontal, 24)
                .transition(.scale.combined(with: .opacity))
                .zIndex(1)
            }
        }
        .animation(.spring(response: 0.35, dampingFraction: 0.88, blendDuration: 0.2), value: isPresented)
    }
}

extension View {
    /// Song selection dialog modifier
    func songSelectionDialog(
        isPresented: Binding<Bool>,
        onSelectSong: @escaping (SelectedSong, URL?) -> Void
    ) -> some View {
        self.modifier(SongSelectionDialogModifier(
            isPresented: isPresented,
            onSelectSong: onSelectSong
        ))
    }
}

// MARK: - Dialog Card Content
private struct SongSelectionDialogCard: View {
    let onClose: () -> Void
    let onSelectSong: (SelectedSong, URL?) -> Void
    
    @State private var selectedTab: SongTab = .hotSongs
    @State private var downloadedSongs: [SunoData] = []
    @State private var hotSongs: [SunoData] = []
    @State private var isLoading = false
    @State private var isLoadingHotSongs = false
    
    enum SongTab {
        case hotSongs, mySongs
    }
    
    @State private var searchText = ""
    @State private var showingFilePicker = false
    @State private var selectedAudioFileURL: URL?
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            headerView
            
            // Tabs
            tabsView
            
            // Search Box
            searchView
            
            // Content
            tabContentView
            
            // Select from Device Button
            selectFromDeviceButton
        }
        .frame(maxWidth: .infinity, maxHeight: 600)
        .background(
            ZStack {
                LinearGradient(
                    gradient: Gradient(colors: [
                        Color.black.opacity(0.75),
                        Color.black.opacity(0.55)
                    ]),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .background(.ultraThinMaterial)
                .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
            }
        )
        .overlay(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(Color.white.opacity(0.10), lineWidth: 1)
        )
        .shadow(color: .black.opacity(0.35), radius: 24, x: 0, y: 12)
        .onAppear {
            loadDownloadedSongs()
            loadHotSongs()
        }
    }
    
    // MARK: - Header
    private var headerView: some View {
        HStack {
            Text("Select a Song")
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(.white)
            
            Spacer()
            
            Button(action: onClose) {
                Image(systemName: "xmark")
                    .font(.title3)
                    .foregroundColor(.white)
                    .frame(width: 32, height: 32)
                    .background(Color.gray.opacity(0.3))
                    .clipShape(Circle())
            }
        }
        .padding(.horizontal, 20)
        .padding(.top, 20)
        .padding(.bottom, 16)
    }
    
    // MARK: - Search View
    private var searchView: some View {
        HStack(spacing: 12) {
            Image(systemName: "magnifyingglass")
                .foregroundColor(.gray.opacity(0.7))
            
            TextField("Search songs...", text: $searchText)
                .font(.system(size: 15))
                .foregroundColor(.white)
            
            if !searchText.isEmpty {
                Button(action: { searchText = "" }) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.gray)
                        .font(.system(size: 16))
                }
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(Color.white.opacity(0.1))
        )
        .padding(.horizontal, 20)
        .padding(.top, 12)
    }
    
    // MARK: - Select from Device Button
    private var selectFromDeviceButton: some View {
        Button(action: {
            showingFilePicker = true
        }) {
            HStack(spacing: 8) {
                Image(systemName: "doc.badge.plus")
                    .font(.system(size: 16, weight: .semibold))
                Text("Select from Device")
                    .font(.system(size: 15, weight: .semibold))
            }
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(AivoTheme.Secondary.coralRed)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color.white.opacity(0.3), lineWidth: 1)
                    )
            )
        }
        .padding(.horizontal, 20)
        .padding(.bottom, 12)
        .padding(.top, 16)
        .fileImporter(
            isPresented: $showingFilePicker,
            allowedContentTypes: [.audio, .mp3, .wav],
            allowsMultipleSelection: false
        ) { result in
            switch result {
            case .success(let urls):
                if let url = urls.first {
                    handleSelectedFile(url)
                }
            case .failure(let error):
                Logger.e("❌ [SongSelection] File picker error: \(error.localizedDescription)")
            }
        }
    }
    
    private func handleSelectedFile(_ url: URL) {
        Logger.i("📁 [SongSelection] Selected file: \(url.lastPathComponent)")
        
        // Security scoped resource access for picked file
        guard url.startAccessingSecurityScopedResource() else {
             Logger.e("❌ [SongSelection] Failed to access security scoped resource")
             return
        }
        
        defer {
            url.stopAccessingSecurityScopedResource()
        }
        
        do {
            // Copy file to temp directory to persist access
            let tempDir = FileManager.default.temporaryDirectory
            let fileName = url.lastPathComponent
            let destUrl = tempDir.appendingPathComponent(fileName)
            
            if FileManager.default.fileExists(atPath: destUrl.path) {
                try FileManager.default.removeItem(at: destUrl)
            }
            
            try FileManager.default.copyItem(at: url, to: destUrl)
            
            // Use the copy
            let selectedSong = SelectedSong(
                id: UUID().uuidString,
                title: fileName.replacingOccurrences(of: ".mp3", with: "").replacingOccurrences(of: ".m4a", with: ""),
                coverImageUrl: "",
                audioUrl: nil,
                sunoData: nil
            )
            
            // Store the file URL (use the destination URL which is safe to access)
            selectedAudioFileURL = destUrl
            onSelectSong(selectedSong, destUrl)
            onClose()
            
        } catch {
            Logger.e("❌ [SongSelection] Failed to copy file: \(error)")
        }
    }
    
    // MARK: - Tabs
    private var tabsView: some View {
        HStack(spacing: 0) {
            Button(action: { 
                withAnimation { selectedTab = .hotSongs } 
            }) {
                Text("Hot Songs")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(selectedTab == .hotSongs ? .black : .white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 44)
                    .background(
                        RoundedCornerShape(radius: 0, corners: selectedTab == .hotSongs ? [.topLeft] : [])
                            .fill(selectedTab == .hotSongs ? AivoTheme.Primary.orange : Color.clear)
                    )
            }
            
            Button(action: { 
                withAnimation { selectedTab = .mySongs } 
            }) {
                Text("My Songs")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(selectedTab == .mySongs ? .black : .white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 44)
                    .background(
                        RoundedCornerShape(radius: 0, corners: selectedTab == .mySongs ? [.topRight] : [])
                            .fill(selectedTab == .mySongs ? AivoTheme.Primary.orange : Color.clear)
                    )
            }
        }
        .padding(.horizontal, 20)
    }
    
    // MARK: - Tab Content
    private var tabContentView: some View {
        ScrollView {
            LazyVStack(spacing: 12) {
                if selectedTab == .hotSongs {
                    hotSongsView
                } else {
                    mySongsView
                }
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 16)
        }
        .frame(maxHeight: 350)
    }
    
    // MARK: - Hot Songs View
    private var hotSongsView: some View {
        Group {
            if isLoadingHotSongs {
                loadingView
            } else if hotSongs.isEmpty {
                emptyStateView
            } else {
                ForEach(filteredHotSongs, id: \.id) { song in
                    SelectSongRowView(
                        title: song.title,
                        coverImageUrl: song.imageUrl.isEmpty ? song.sourceImageUrl : song.imageUrl,
                        isRemote: true
                    ) {
                        // Create SelectedSong from SunoData with audioUrl
                        let selectedSong = SelectedSong(
                            id: song.id,
                            title: song.title,
                            coverImageUrl: song.imageUrl.isEmpty ? song.sourceImageUrl : song.imageUrl,
                            audioUrl: song.audioUrl,
                            sunoData: song
                        )
                        onSelectSong(selectedSong, nil)
                        onClose()
                    }
                }
            }
        }
    }
    
    // MARK: - My Songs View
    private var mySongsView: some View {
        Group {
            if isLoading {
                loadingView
            } else if downloadedSongs.isEmpty {
                emptyStateView
            } else {
                ForEach(filteredDownloadedSongs, id: \.id) { song in
                    SelectSongRowView(
                        title: song.title,
                        coverImageUrl: getImageURL(for: song)?.absoluteString ?? "",
                        isRemote: false
                    ) {
                        onSelectSong(.fromSunoData(song), nil)
                        onClose()
                    }
                }
            }
        }
    }
    
    private var loadingView: some View {
        VStack(spacing: 16) {
            ProgressView()
                .tint(AivoTheme.Primary.orange)
                .scaleEffect(1.5)
            
            Text("Loading your songs...")
                .font(.headline)
                .foregroundColor(.white.opacity(0.7))
        }
        .frame(height: 200)
    }
    
    private var emptyStateView: some View {
        VStack(spacing: 16) {
            Image(systemName: "music.note.list")
                .font(.system(size: 48))
                .foregroundColor(.gray.opacity(0.5))
            
            Text("No saved songs yet")
                .font(.headline)
                .foregroundColor(.white.opacity(0.7))
            
            Text("Generate songs to add them here")
                .font(.caption)
                .foregroundColor(.gray)
        }
        .frame(height: 200)
    }
    
    private func getImageURL(for song: SunoData) -> URL? {
        if let localCoverPath = SunoDataManager.shared.getLocalCoverPath(for: song.id) {
            return localCoverPath
        }
        return URL(string: song.sourceImageUrl)
    }
    
    private func loadDownloadedSongs() {
        isLoading = true
        Logger.i("📚 [SongSelection] Loading downloaded songs...")
        
        Task {
            do {
                let songs = try await SunoDataManager.shared.loadAllSavedSunoData()
                await MainActor.run {
                    self.downloadedSongs = songs
                    self.isLoading = false
                    Logger.i("✅ [SongSelection] Loaded \(songs.count) downloaded songs")
                    for song in songs {
                        Logger.d("📚 [SongSelection] - \(song.title) (ID: \(song.id))")
                    }
                }
            } catch {
                Logger.e("❌ [SongSelection] Error loading songs: \(error)")
                await MainActor.run {
                    self.isLoading = false
                    self.downloadedSongs = []
                }
            }
        }
    }
    
    private func loadHotSongs() {
        isLoadingHotSongs = true
        Logger.i("🔥 [SongSelection] Loading hot songs from hottest_songs.json...")
        
        Task {
            do {
                guard let url = Bundle.main.url(forResource: "hottest_songs", withExtension: "json") else {
                    Logger.e("❌ [SongSelection] Could not find hottest_songs.json")
                    await MainActor.run {
                        isLoadingHotSongs = false
                        hotSongs = []
                    }
                    return
                }
                
                let data = try Data(contentsOf: url)
                let songs = try JSONDecoder().decode([SunoData].self, from: data)
                
                await MainActor.run {
                    self.hotSongs = songs
                    self.isLoadingHotSongs = false
                    Logger.i("✅ [SongSelection] Loaded \(songs.count) hot songs")
                    for song in songs.prefix(5) {
                        Logger.d("🔥 [SongSelection] - \(song.title) (ID: \(song.id), audioUrl: \(song.audioUrl))")
                    }
                }
            } catch {
                Logger.e("❌ [SongSelection] Error loading hot songs: \(error)")
                await MainActor.run {
                    isLoadingHotSongs = false
                    hotSongs = []
                }
            }
        }
    }
    
    private var filteredHotSongs: [SunoData] {
        if searchText.isEmpty {
            return hotSongs
        }
        return hotSongs.filter { $0.title.localizedCaseInsensitiveContains(searchText) }
    }
    
    private var filteredDownloadedSongs: [SunoData] {
        if searchText.isEmpty {
            return downloadedSongs
        }
        return downloadedSongs.filter { $0.title.localizedCaseInsensitiveContains(searchText) }
    }
}

// MARK: - Song Row View
struct SelectSongRowView: View {
    let title: String
    let coverImageUrl: String
    let isRemote: Bool
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 12) {
                // Cover Image
                KFImage(URL(string: coverImageUrl))
                    .placeholder {
                        Image("demo_cover")
                            .resizable()
                            .scaledToFill()
                    }
                    .setProcessor(DownsamplingImageProcessor(size: CGSize(width: 240, height: 240)))
                    .cacheMemoryOnly()
                    .resizable()
                    .scaledToFill()
                    .frame(width: 60, height: 60)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                
                // Title
                Text(title)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .multilineTextAlignment(.leading)
                
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundColor(.gray)
            }
            .padding(.vertical, 8)
            .padding(.horizontal, 12)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.white.opacity(0.05))
            )
        }
    }
}

// MARK: - Selected Song Model
struct SelectedSong: Identifiable {
    let id: String
    let title: String
    let coverImageUrl: String
    let audioUrl: String?
    let sunoData: SunoData?
    
    init(id: String, title: String, coverImageUrl: String, audioUrl: String? = nil, sunoData: SunoData? = nil) {
        self.id = id
        self.title = title
        self.coverImageUrl = coverImageUrl
        self.audioUrl = audioUrl
        self.sunoData = sunoData
    }
    
    static func fromSunoData(_ sunoData: SunoData) -> SelectedSong {
        return SelectedSong(
            id: sunoData.id,
            title: sunoData.title,
            coverImageUrl: sunoData.imageUrl.isEmpty ? "demo_cover" : sunoData.imageUrl,
            audioUrl: sunoData.audioUrl,
            sunoData: sunoData
        )
    }
}

// MARK: - Rounded Corner Helper
struct RoundedCornerShape: Shape {
    var radius: CGFloat = .infinity
    var corners: UIRectCorner = .allCorners

    func path(in rect: CGRect) -> Path {
        let path = UIBezierPath(
            roundedRect: rect,
            byRoundingCorners: corners,
            cornerRadii: CGSize(width: radius, height: radius)
        )
        return Path(path.cgPath)
    }
}

#Preview {
    ZStack {
        LinearGradient(colors: [.black, .gray], startPoint: .top, endPoint: .bottom)
            .ignoresSafeArea()
        Text("Your Screen")
            .foregroundColor(.white)
    }
    .songSelectionDialog(
        isPresented: .constant(true),
        onSelectSong: {_,_ in }
    )
}
