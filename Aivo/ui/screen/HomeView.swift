import SwiftUI

// MARK: - Main Home View (Container)
struct HomeView: View {
    @StateObject private var subscriptionManager = SubscriptionManager.shared
    @State private var selectedTab: TabItem = .home
    @State private var showGenerateSongResult = false
    @State private var showSunoSongResult = false
    @State private var showSubscription = false
    
    // Hardcoded SunoData for testing
    private let hardcodedSunoData: [SunoData] = [
//        SunoData(
//            id: "bed102bd-f445-4a14-b5d2-918f0e389d2c",
//            audioUrl: "https://cdn1.suno.ai/bed102bd-f445-4a14-b5d2-918f0e389d2c.mp3",
//            sourceAudioUrl: "https://cdn1.suno.ai/bed102bd-f445-4a14-b5d2-918f0e389d2c.mp3",
//            streamAudioUrl: "https://cdn1.suno.ai/bed102bd-f445-4a14-b5d2-918f0e389d2c.mp3",
//            sourceStreamAudioUrl: "https://cdn1.suno.ai/bed102bd-f445-4a14-b5d2-918f0e389d2c.mp3",
//            imageUrl: "https://cdn2.suno.ai/image_bed102bd-f445-4a14-b5d2-918f0e389d2c.jpeg",
//            sourceImageUrl: "https://cdn2.suno.ai/image_bed102bd-f445-4a14-b5d2-918f0e389d2c.jpeg",
//            prompt: "Create an energetic and uplifting EDM track inspired by the style of Alan Walker. The song should combine emotional melodies with a powerful drop and strong rhythmic bass. The theme is about Love and Life — embracing the present, chasing dreams, and finding light through love.The sound should be modern, catchy, cinematic, with emotional female vocals and a bright, punchy mix that motivates and inspires.",
//            modelName: "chirp-v4",
//            title: "Freedom",
//            tags: "",
//            createTime: 1761204292496,
//            duration: 168.84
//        ),
//        SunoData(
//            id: "97d4adf6-8c34-442a-84b1-ecd3b9e5be04",
//            audioUrl: "https://cdn1.suno.ai/97d4adf6-8c34-442a-84b1-ecd3b9e5be04.mp3",
//            sourceAudioUrl: "https://cdn1.suno.ai/97d4adf6-8c34-442a-84b1-ecd3b9e5be04.mp3",
//            streamAudioUrl: "https://cdn1.suno.ai/97d4adf6-8c34-442a-84b1-ecd3b9e5be04.mp3",
//            sourceStreamAudioUrl: "https://cdn1.suno.ai/97d4adf6-8c34-442a-84b1-ecd3b9e5be04.mp3",
//            imageUrl: "https://cdn2.suno.ai/image_97d4adf6-8c34-442a-84b1-ecd3b9e5be04.jpeg",
//            sourceImageUrl: "https://cdn2.suno.ai/image_97d4adf6-8c34-442a-84b1-ecd3b9e5be04.jpeg",
//            prompt: "Create an energetic and uplifting EDM track inspired by the style of Alan Walker. The song should combine emotional melodies with a powerful drop and strong rhythmic bass. The theme is about Love and Life — embracing the present, chasing dreams, and finding light through love.The sound should be modern, catchy, cinematic, with emotional female vocals and a bright, punchy mix that motivates and inspires.",
//            modelName: "chirp-v4",
//            title: "Freedom",
//            tags: "",
//            createTime: 1761204292496,
//            duration: 178.4
//        )
        SunoData(
            id: "abcd1234",
            audioUrl: "https://pub-3626123a908346a7a8be8d9295f44e26.r2.dev/generations/cba705b7-a7b8-4a32-acbf-338583de7b49.wav",
            sourceAudioUrl: "https://pub-3626123a908346a7a8be8d9295f44e26.r2.dev/generations/cba705b7-a7b8-4a32-acbf-338583de7b49.wav",
            streamAudioUrl: "https://pub-3626123a908346a7a8be8d9295f44e26.r2.dev/generations/680b717c-366c-44a4-808f-7cd0a79199f9.wav",
            sourceStreamAudioUrl: "https://pub-3626123a908346a7a8be8d9295f44e26.r2.dev/generations/680b717c-366c-44a4-808f-7cd0a79199f9.wav",
            imageUrl: "https://cdn2.suno.ai/image_97d4adf6-8c34-442a-84b1-ecd3b9e5be04.jpeg",
            sourceImageUrl: "https://cdn2.suno.ai/image_97d4adf6-8c34-442a-84b1-ecd3b9e5be04.jpeg",
            prompt: "Create an energetic and uplifting EDM track inspired by the style of Alan Walker. The song should combine emotional melodies with a powerful drop and strong rhythmic bass. The theme is about Love and Life — embracing the present, chasing dreams, and finding light through love.The sound should be modern, catchy, cinematic, with emotional female vocals and a bright, punchy mix that motivates and inspires.",
            modelName: "ModelsLab cover",
            title: "PayPhone",
            tags: "",
            createTime: 1761204292496,
            duration: 178.4
        )
    ]
    
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
            Text("Aivo Music")
                .font(.system(size: 24, weight: .black, design: .monospaced))
                .foregroundColor(.white)
            
            Spacer()
            //SubscriptionManager.shared.isPremium
            // VIP Button
            Button(action: { showSubscription = true }) {
                HStack(spacing: 4) {
                    Image(systemName: "crown.fill")
                        .font(.caption)
                        .foregroundColor(SubscriptionManager.shared.isPremium ? .white : .white.opacity(0.7))
                    Text("VIP")
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundColor(SubscriptionManager.shared.isPremium ? .white : .white.opacity(0.7))
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 8)
                // NỀN: chỉ có khi VIP
                .background(
                    Group {
                        if SubscriptionManager.shared.isPremium {
                            LinearGradient(
                                gradient: Gradient(colors: [
                                    Color(red: 1.0, green: 0.0,  blue: 0.0),   // đỏ thuần
                                    Color(red: 1.0, green: 0.15, blue: 0.03),  // đỏ→cam
                                    Color(red: 1.0, green: 0.38, blue: 0.08)   // cam đậm (ít hơn)
                                ]),
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                            .clipShape(Capsule())
                        } else {
                            Color.clear.clipShape(Capsule())
                        }
                    }
                )
                // VIỀN: VIP viền đỏ-cam; Non-VIP viền trắng mờ, không nền
                .overlay(
                    Capsule().stroke(
                        SubscriptionManager.shared.isPremium
                        ? Color(red: 1.0, green: 0.25, blue: 0.05).opacity(0.9)
                        : Color.white.opacity(0.5),
                        lineWidth: 1
                    )
                )
                // Bóng nhẹ chỉ khi VIP để nổi bật
                .shadow(color: SubscriptionManager.shared.isPremium ? Color(red: 1.0, green: 0.2, blue: 0.05).opacity(0.45) : .clear,
                        radius: 8, x: 0, y: 3)
            }
            
            // Credit Badge View
            CreditBadgeView()
            
            // Settings
            Button(action: {
                testSunoDataDecoding()
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
        .fullScreenCover(isPresented: $showSubscription) {
            SubscriptionScreen()
        }
        .fullScreenCover(isPresented: $showGenerateSongResult) {
            GenerateSongResultScreen(
                audioUrl: "https://cdn1.suno.ai/53d93a26-3bed-4f54-b9fc-47433f424884.mp3",
                onClose: {
                    showGenerateSongResult = false
                }
            )
        }
        .fullScreenCover(isPresented: $showSunoSongResult) {
            let data =
                    SunoData(
                        id: "97d4adf6-8c34-442a-84b1-ecd3b9e5be04",
                        audioUrl: "https://musicfile.api.box/N2QyMzY1OWQtNjQ0NC00MDc5LTk5MmMtMjZkYjhlYTcwZTU4.mp3",
                        sourceAudioUrl: "https://cdn1.suno.ai/97d4adf6-8c34-442a-84b1-ecd3b9e5be04.mp3",
                        streamAudioUrl: "https://cdn1.suno.ai/97d4adf6-8c34-442a-84b1-ecd3b9e5be04.mp3",
                        sourceStreamAudioUrl: "https://cdn1.suno.ai/97d4adf6-8c34-442a-84b1-ecd3b9e5be04.mp3",
                        imageUrl: "https://musicfile.api.box/N2QyMzY1OWQtNjQ0NC00MDc5LTk5MmMtMjZkYjhlYTcwZTU4.jpeg",
                        sourceImageUrl: "https://cdn2.suno.ai/image_7d23659d-6444-4079-992c-26db8ea70e58.jpeg",
                        prompt: "[Verse]\nWhispers in the night they call my name\nStars align to play our timeless game\nFootsteps echo soft on moonlit sand\n\n[Prechorus]\nEvery shadow fades to light\nWhen you're here it feels so right\n\n[Chorus]\nWe are the glow that never dies\nBurning bright in endless skies\nYou and me\nInfinity\nOur love will always rise\n\n[Verse 2]\nGolden rivers flow through endless streams\nChasing moments painted in our dreams\nTime stands still beneath this glowing tide\n\n[Prechorus]\nEvery heartbeat feels like fire\nYou lift me higher and higher\n\n[Chorus]\nWe are the glow that never dies\nBurning bright in endless skies\nYou and me\nInfinity\nOur love will always rise",
                        modelName: "chirp-v4",
                        title: "Freedom",
                        tags: "",
                        createTime: 1761204292496,
                        duration: 178.4
                        )
//            GenerateSunoSongResultScreen(
//                sunoDataList: hardcodedSunoData,
//                onClose: {
//                    showSunoSongResult = false
//                }
//            )
            PlaySunoSongIntroScreen(
                sunoData: data,
                onIntroCompleted: {},
                
            )
        }
    }
    
    // MARK: - Test Method
    private func testSunoDataDecoding() {
        let jsonString = """
        [
            {
                "id": "a5272d42-505a-455f-ae08-d16a2dd2cc35",
                "audioUrl": "https://cdn1.suno.ai/9e3074cf-3991-4a1a-a730-2336965ae9a4.mp3",
                "sourceAudioUrl": "https://cdn1.suno.ai/9e3074cf-3991-4a1a-a730-2336965ae9a4.mp3",
                "streamAudioUrl": "https://cdn1.suno.ai/9e3074cf-3991-4a1a-a730-2336965ae9a4.mp3",
                "sourceStreamAudioUrl": "https://cdn1.suno.ai/9e3074cf-3991-4a1a-a730-2336965ae9a4.mp3",
                "imageUrl": "https://musicfile.api.box/YTUyNzJkNDItNTA1YS00NTVmLWFlMDgtZDE2YTJkZDJjYzM1.jpeg",
                "sourceImageUrl": "https://cdn2.suno.ai/image_a5272d42-505a-455f-ae08-d16a2dd2cc35.jpeg",
                "prompt": "[Verse]\\nI caught the sunrise in your eyes\\nLike neon sparks across the skies\\nThe world is ours no need to hide",
                "modelName": "chirp-v4",
                "title": "Dancing in the glow",
                "tags": "edm, sunset vibe, vocal, airy female vocals",
                "createTime": 1761704068892,
                "duration": 159
            },
            {
                "id": "a5272d42-505a-455f-ae08-d16a2dd2cc35",
                "audioUrl": "https://musicfile.api.box/MGI2NTE3OTItMTI4OC00MWJjLTg2ZjgtMTYwYThmOTExMGUy.mp3",
                "sourceAudioUrl": "https://musicfile.api.box/MGI2NTE3OTItMTI4OC00MWJjLTg2ZjgtMTYwYThmOTExMGUy.mp3",
                "streamAudioUrl": "https://musicfile.api.box/MGI2NTE3OTItMTI4OC00MWJjLTg2ZjgtMTYwYThmOTExMGUy.mp3",
                "sourceStreamAudioUrl": "https://cdn1.suno.ai/9e3074cf-3991-4a1a-a730-2336965ae9a4.mp3",
                "imageUrl": "https://musicfile.api.box/YTUyNzJkNDItNTA1YS00NTVmLWFlMDgtZDE2YTJkZDJjYzM1.jpeg",
                "sourceImageUrl": "https://cdn2.suno.ai/image_a5272d42-505a-455f-ae08-d16a2dd2cc35.jpeg"
            }
        ]
        """
        
        do {
            guard let data = jsonString.data(using: .utf8) else {
                print("❌ [Test] Failed to convert string to data")
                return
            }
            
            let songs = try JSONDecoder().decode([SunoData].self, from: data)
            
            print("✅ [Test] Successfully decoded \(songs.count) songs")
            for (index, song) in songs.enumerated() {
                print("\n[Song \(index + 1)]")
                print("ID: \(song.id)")
                print("Title: \(song.title)")
                print("Model: \(song.modelName)")
                print("Duration: \(song.duration)")
                print("Prompt: \(song.prompt.isEmpty ? "(empty - using default)" : "\(song.prompt.prefix(50))...")")
                print("Tags: \(song.tags.isEmpty ? "(empty - using default)" : song.tags)")
            }
            
            // Show the result
            Task { @MainActor in
                showSunoSongResult = true
            }
            
        } catch {
            print("❌ [Test] Decoding error: \(error)")
            if let decodingError = error as? DecodingError {
                switch decodingError {
                case .keyNotFound(let key, let context):
                    print("❌ [Test] Missing key: \(key.stringValue), context: \(context)")
                case .valueNotFound(let type, let context):
                    print("❌ [Test] Missing value: \(type), context: \(context)")
                case .typeMismatch(let type, let context):
                    print("❌ [Test] Type mismatch: \(type), context: \(context)")
                case .dataCorrupted(let context):
                    print("❌ [Test] Data corrupted: \(context)")
                @unknown default:
                    print("❌ [Test] Unknown error")
                }
            }
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

