import SwiftUI

struct WeeklyBoardHistoryScreen: View {
    @Environment(\.dismiss) private var dismiss
    @State private var boards: [WeeklyBoard] = []
    @State private var isLoading = false
    @State private var selectedBoard: WeeklyBoard?
    @State private var showSongs = false
    @State private var weeklySongs: [SunoData] = []
    
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
        .fullScreenCover(item: $selectedBoard) { board in
            OnlineSongListView(title: board.title, songs: weeklySongs)
        }
    }
    
    // MARK: - Header
    private var headerView: some View {
        HStack {
            Button(action: { dismiss() }) {
                Image(systemName: "chevron.left")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(.white)
                    .padding(12)
                    .background(Color.white.opacity(0.1))
                    .clipShape(Circle())
            }
            
            Text("Weekly Top 10 History")
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
            LazyVStack(spacing: 12) {
                if boards.isEmpty && !isLoading {
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
                } else {
                    ForEach(boards) { board in
                        boardItemView(board)
                    }
                }
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 100)
        }
    }
    
    // MARK: - Board Item
    private func boardItemView(_ board: WeeklyBoard) -> some View {
        Button(action: {
            fetchSongsForBoard(board)
        }) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(board.title)
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(.white)
                    
                    Text(DateUtils.formatTimestamp(board.timestamp))
                        .font(.system(size: 12))
                        .foregroundColor(.white.opacity(0.6))
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.white.opacity(0.5))
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 16)
            .background(Color.white.opacity(0.1))
            .cornerRadius(16)
        }
        .buttonStyle(.plain)
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
    
    private func fetchSongsForBoard(_ board: WeeklyBoard) {
        // Check cache
        if let cachedSongs = LocalStorageManager.shared.getWeeklySongs(weekTag: board.weekTag) {
            self.weeklySongs = cachedSongs
            self.selectedBoard = board
            return
        }
        
        isLoading = true
        Task {
            do {
                let songs = try await FirestoreService.shared.fetchSongsForWeek(songIDs: board.songIDs)
                await MainActor.run {
                    self.weeklySongs = songs
                    self.isLoading = false
                    LocalStorageManager.shared.saveWeeklySongs(weekTag: board.weekTag, songs: songs)
                    self.selectedBoard = board
                }
            } catch {
                await MainActor.run {
                    self.isLoading = false
                    Logger.e("❌ Failed to fetch songs for week \(board.weekTag): \(error)")
                }
            }
        }
    }
    
    private func mapToWeeklyBoard(data: [String: Any]) throws -> WeeklyBoard {
        let jsonData = try JSONSerialization.data(withJSONObject: data)
        return try JSONDecoder().decode(WeeklyBoard.self, from: jsonData)
    }
}
