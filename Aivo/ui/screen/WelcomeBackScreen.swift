import SwiftUI

struct WelcomeBackScreen: View {
    let onContinue: () -> Void
    
    var body: some View {
        ZStack {
            AivoSunsetBackground()
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 24) {
                        
                        // Top Bar: App Icon + App Name
                        ZStack(alignment: .trailing) {
                            HStack(spacing: 12) {
                                Spacer()
                                
                                Image("icon_app")
                                    .resizable()
                                    .aspectRatio(contentMode: .fit)
                                    .frame(width: 48, height: 48)
                                    .cornerRadius(12)
                                
                                Text("AIVO: AI Music Creator")
                                    .font(.system(size: 18, weight: .bold))
                                    .foregroundColor(.white)
                                
                                Spacer()
                            }
                        }
                        .padding(.top, 20)
                        
                        // Centered Welcome back text
                        VStack(spacing: 12) {
                            Text("Welcome back")
                                .font(.system(size: 32, weight: .bold))
                                .foregroundColor(.white)
                            
                            Text("We're glad to have you here again. Let's pick up where you left off and continue your music journey!")
                                .font(.system(size: 14))
                                .foregroundColor(.white.opacity(0.7))
                                .multilineTextAlignment(.center)
                                .lineLimit(3)
                                .padding(.horizontal, 32)
                        }
                        
                        // Welcome Image
                        Image("image_welcome_back")
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .cornerRadius(16)
                            .padding(.horizontal, 24)
                            .padding(.top, 20)
                            .padding(.bottom, 10)
                    }
                }
                
                // Continue button
                Button(action: onContinue) {
                    Text("Continue")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.white.opacity(0.8))
                        .padding(.bottom, 8)
                        .padding(.top, 16)
                }
                .padding(.bottom, 0)
                
                // Compact native ad at bottom
                BasicNativeAdView(isCtaButtonOntop: true, isIntroMode: true)
            }
        }
        .onAppear {
            AnalyticsLogger.shared.logScreenView("welcome_back_screen")
        }
    }
}
