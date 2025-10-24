import SwiftUI

// MARK: - Main Home View (Container)
struct HomeView: View {
    @State private var selectedTab: TabItem = .home
    @State private var showGenerateSongResult = false
    
    var body: some View {
        ZStack {
            // Background
            AivoSunsetBackground()
            
            VStack(spacing: 0) {
                // Header - Fixed
                headerView
                
                // Content based on selected tab
                Group {
                    switch selectedTab {
                    case .home:
                        GenerateSongTabView()
                            //.padding(.bottom, 100) // Space for bottom navigation
                        
                    case .explore:
                        ExploreTabView()
                            //.padding(.bottom, 100) // Space for bottom navigation
                        
                    case .cover:
                        CoverTabView()
                            //.padding(.bottom, 100) // Space for bottom navigation
                        
                    case .library:
                        LibraryTabView()
                            //.padding(.bottom, 100) // Space for bottom navigation
                    }
                }
                
                // Playing Banner View (if music is playing) - Above bottom nav
                PlayingBannerView()
                
                // Bottom Navigation - Fixed
                bottomNavigationView
            }
        }
    }
    
    // MARK: - Header View
    private var headerView: some View {
        HStack {
            Text("Aivo - AI MUSIC")
                .font(.system(size: 24, weight: .black, design: .monospaced))
                .foregroundColor(.white)
            
            Spacer()
            
            // VIP Button
            Button(action: {}) {
                HStack(spacing: 4) {
                    Image(systemName: "crown.fill")
                        .font(.caption)
                        .foregroundColor(.yellow)
                    Text("VIP")
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundColor(.white)
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(
                    Capsule()
                        .fill(Color.gray.opacity(0.3))
                        .overlay(
                            Capsule()
                                .stroke(Color.yellow.opacity(0.5), lineWidth: 1)
                        )
                )
            }
            
            // Settings
            Button(action: {
                showGenerateSongResult = true
            }) {
                Image(systemName: "gearshape.fill")
                    .font(.title2)
                    .foregroundColor(.white)
            }
        }
        .padding(.horizontal, 20)
        .padding(.top, 10)
        .padding(.bottom, 20)
    }
    
    
    // MARK: - Bottom Navigation View
    private var bottomNavigationView: some View {
        HStack(spacing: 0) {
            ForEach(TabItem.allCases, id: \.self) { tab in
                Button(action: {
                    selectedTab = tab
                }) {
                    VStack(spacing: 4) {
                        Image(systemName: tab.icon)
                            .font(.system(size: 20, weight: .medium))
                            .foregroundColor(selectedTab == tab ? AivoTheme.Primary.orange : .gray)
                        
                        Text(tab.title)
                            .font(.caption)
                            .fontWeight(.medium)
                            .foregroundColor(selectedTab == tab ? AivoTheme.Primary.orange : .gray)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 8)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, 20)
        .padding(.bottom, 8)
        .background(
            Rectangle()
                .fill(AivoTheme.Background.primary)
                .shadow(color: .black.opacity(0.3), radius: 10, x: 0, y: -5)
        )
        .fullScreenCover(isPresented: $showGenerateSongResult) {
            GenerateSongResultScreen(
                audioUrl: "https://cdn1.suno.ai/53d93a26-3bed-4f54-b9fc-47433f424884.mp3",
                onClose: {
                    showGenerateSongResult = false
                }
            )
        }
    }
}

// MARK: - Tab Item Enum
enum TabItem: String, CaseIterable {
    case home = "Home"
    case explore = "Explore"
    case cover = "Cover"
    case library = "Library"
    
    var icon: String {
        switch self {
        case .home:
            return "music.note"
        case .explore:
            return "headphones"
        case .cover:
            return "mic"
        case .library:
            return "books.vertical"
        }
    }
    
    var title: String {
        return self.rawValue
    }
}

// MARK: - Preview
struct HomeView_Previews: PreviewProvider {
    static var previews: some View {
        HomeView()
    }
}

