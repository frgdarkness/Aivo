import SwiftUI

struct WeeklyBoardHistoryScreen: View {
    @Environment(\.dismiss) private var dismiss
    @State private var boards: [WeeklyBoard] = []
    @State private var isLoading = false
    @State private var selectedSongForPlayback: ExploreTabViewNew.SongPlaybackItem? = nil
    
    var body: some View {
        ZStack {
            // Background
            AivoSunsetBackground()
            
            VStack(spacing: 0) {
                // Header
                headerView
                
                // Content
                if isLoading && boards.isEmpty {
                    Spacer()
                    ProgressView()
                        .tint(.white)
                    Spacer()
                } else {
                    boardListView
                }
            }
        }
        .onAppear {
            loadBoardHistory()
            AnalyticsLogger.shared.logScreenView("WeeklyBoardHistoryScreen")
        }
        .fullScreenCover(item: $selectedSongForPlayback) { item in
            PlayOnlineSongScreen(songs: item.songs, initialIndex: item.initialIndex)
        }
    }
    
    // MARK: - Header
    private var headerView: some View {
        HStack {
            Button(action: {
                dismiss()
            }) {
                Image(systemName: "chevron.left")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(.white)
                    .padding(12)
                    .background(Color.white.opacity(0.1))
                    .clipShape(Circle())
            }
            
            Text("Weekly Billboard History")
                .font(.system(size: 20, weight: .bold))
                .foregroundColor(.white)
            
            Spacer()
        }
        .padding(.horizontal, 20)
        .padding(.top, 10)
        .padding(.bottom, 20)
    }
    
    // MARK: - Board List
    private var boardListView: some View {
        ScrollView {
            VStack(spacing: 32) {
                if boards.isEmpty && !isLoading {
                    emptyStateView
                } else {
                    ForEach(boards) { board in
                        boardSectionView(board)
                    }
                }
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 100)
        }
    }
    
    private var emptyStateView: some View {
        VStack(spacing: 16) {
            Image(systemName: "chart.bar.xaxis")
                .font(.system(size: 48))
                .foregroundColor(.white.opacity(0.5))
                .padding(.top, 100)
            
            Text("No Rankings Yet")
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(.white)
            
            Text("Check back next week for fresh rankings!")
                .font(.system(size: 14))
                .foregroundColor(.white.opacity(0.7))
        }
    }
    
    private func boardSectionView(_ board: WeeklyBoard) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(board.title)
                .font(.system(size: 20, weight: .bold))
                .foregroundColor(.white)
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 16) {
                    ForEach(Array(board.songs.enumerated()), id: \.offset) { index, song in
                        CommunitySongCard(song: song, rank: index + 1) {
                            selectedSongForPlayback = ExploreTabViewNew.SongPlaybackItem(songs: board.songs, initialIndex: index)
                        }
                    }
                }
                .padding(.horizontal, 2)
            }
        }
    }
    
    // MARK: - Data Loading
    private func loadBoardHistory() {
        // Check cache
        if let cached = LocalStorageManager.shared.getWeeklyBoardHistory() {
            self.boards = cached.compactMap { try? mapToWeeklyBoard(data: $0) }
            Logger.d("📦 WeeklyBoardHistory: Loaded from cache (\(boards.count) items)")
            
            // Still fetch fresh data in background
            if !isLoading {
                Task {
                    await fetchFreshHistory()
                }
            }
            return
        }
        
        isLoading = true
        Task {
            await fetchFreshHistory()
        }
    }
    
    private func fetchFreshHistory() async {
        do {
            let historyData = try await FirestoreService.shared.fetchWeeklyBoardHistory()
            let fetchedBoards = historyData.compactMap { try? mapToWeeklyBoard(data: $0) }
            
            await MainActor.run {
                self.boards = fetchedBoards
                self.isLoading = false
                LocalStorageManager.shared.saveWeeklyBoardHistory(historyData)
            }
        } catch {
            await MainActor.run {
                self.isLoading = false
                Logger.e("❌ Failed to fetch weekly board history: \(error)")
            }
        }
    }
    
    private func mapToWeeklyBoard(data: [String: Any]) throws -> WeeklyBoard {
        let jsonData = try JSONSerialization.data(withJSONObject: data)
        return try JSONDecoder().decode(WeeklyBoard.self, from: jsonData)
    }
}
