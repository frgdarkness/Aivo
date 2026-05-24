import SwiftUI

struct PreIntroSlide: Identifiable {
    let id = UUID()
    let title: String
    let description: String
    let bgImageName: String
    let showGradientText: Bool
}

struct PreIntroScreen: View {
    let onCompleted: () -> Void
    let onSkip: () -> Void
    
    @State private var currentIndex = 0
    @ObservedObject private var remoteConfig = RemoteConfigManager.shared
    
    var slides: [PreIntroSlide] {
        [
            PreIntroSlide(title: "AIVO MUSIC", description: "Welcome to AIVO Music Creator. Your journey to AI-powered music generation starts here.", bgImageName: "image_intro_1", showGradientText: true),
            PreIntroSlide(title: "AI Music Generation", description: "Generate amazing tracks in seconds with just a text prompt", bgImageName: "image_intro_2", showGradientText: false),
            PreIntroSlide(title: "Create & Compose Lyrics", description: "Write your own lyrics or let AI compose professional lyrics like an artist", bgImageName: "image_intro_3", showGradientText: false),
            PreIntroSlide(title: "AI Music Community", description: "Discover millions of AI-generated songs and join the creator community", bgImageName: "image_intro_4", showGradientText: false)
        ]
    }
    
    var body: some View {
        ZStack {
            AivoSunsetBackground()
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Toolbar Area (Title + Skip)
                ZStack(alignment: .topTrailing) {
                    // Title
                    VStack {
                        if slides[currentIndex].showGradientText {
                            Text(slides[currentIndex].title)
                                .font(.system(size: 28, weight: .black, design: .rounded))
                                .foregroundStyle(
                                    LinearGradient(
                                        colors: [
                                            AivoTheme.Primary.orange,
                                            AivoTheme.Primary.orangeDark
                                        ],
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                                .shadow(color: AivoTheme.Primary.orange.opacity(0.6), radius: 8, x: 0, y: 4)
                        } else {
                            Text(slides[currentIndex].title)
                                .font(.system(size: 24, weight: .bold))
                                .foregroundColor(.white)
                                .multilineTextAlignment(.center)
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.top, 16)
                    
                    // Skip Button
                    if remoteConfig.enableSkipIntro {
                        Button(action: onSkip) {
                            Text("Skip")
                                .font(.system(size: 14, weight: .regular))
                                .foregroundColor(.white.opacity(0.5))
                        }
                        .padding(.trailing, 20)
                        .padding(.top, 16)
                    }
                }
                .padding(.bottom, 16)
                
                // Swipeable Image
                TabView(selection: $currentIndex) {
                    ForEach(0..<slides.count, id: \.self) { index in
                        Image(slides[index].bgImageName)
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .cornerRadius(16)
                            .padding(.horizontal, 24)
                            .tag(index)
                    }
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
                
                // Description
                Text(slides[currentIndex].description)
                    .font(.system(size: 14))
                    .foregroundColor(.white.opacity(0.7))
                    .multilineTextAlignment(.center)
                    .lineLimit(3)
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(.horizontal, 32)
                    .padding(.top, 16)
                    .padding(.bottom, 24)
                
                // Indicators and Next button
                HStack {
                    // Page Indicator
                    HStack(spacing: 8) {
                        ForEach(0..<slides.count, id: \.self) { index in
                            Capsule()
                                .fill(currentIndex == index ? AivoTheme.Primary.orange : Color.gray.opacity(0.5))
                                .frame(width: currentIndex == index ? 24 : 8, height: 8)
                                .animation(.easeInOut(duration: 0.2), value: currentIndex)
                        }
                    }
                    
                    Spacer()
                    
                    // Next Button (Text Only)
                    Button(action: {
                        if currentIndex < slides.count - 1 {
                            withAnimation {
                                currentIndex += 1
                            }
                        } else {
                            onCompleted()
                        }
                    }) {
                        Text(currentIndex == slides.count - 1 ? "Start" : "Next")
                            .font(.system(size: 16, weight: .bold))
                            .foregroundColor(AivoTheme.Primary.orange)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 8)
                    }
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 12)
                
                // Native Ad
                BasicNativeAdView(isIntroMode: true, reloadTrigger: currentIndex)
            }
        }
        .onAppear {
            AnalyticsLogger.shared.logScreenView("pre_intro_screen")
        }
    }
}
