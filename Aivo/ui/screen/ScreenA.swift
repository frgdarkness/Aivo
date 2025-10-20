import SwiftUI

struct ScreenA: View {
    @State private var navigateToScreenB = false
    @StateObject private var adManager = AdManager.shared
    
    var body: some View {
        ZStack {
            // Background gradient
            LinearGradient(
                gradient: Gradient(colors: [Color.green.opacity(0.8), Color.teal.opacity(0.6)]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Main content
                VStack(spacing: 40) {
                    // Title
                    Text("Screen A")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                        .padding(.top, 50)
                    
                    Spacer()
                    
                    // Navigation button with interstitial ad
                    Button(action: {
                        // Show interstitial ad before navigation
                        adManager.showInterAd { result in
                            print("Interstitial ad dismissed, navigating to Screen B")
                            navigateToScreenB = true
                        }
                    }) {
                        HStack {
                            Image(systemName: "arrow.right.circle.fill")
                                .font(.title2)
                            Text("Go Screen B")
                                .font(.title2)
                                .fontWeight(.semibold)
                        }
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 60)
                        .background(
                            RoundedRectangle(cornerRadius: 15)
                                .fill(Color.white.opacity(0.2))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 15)
                                        .stroke(Color.white.opacity(0.3), lineWidth: 1)
                                )
                        )
                    }
                    .padding(.horizontal, 30)
                    
                    Button(action: {
                        // Show interstitial ad before navigation
                        adManager.showInterAd(onFinish: {_ in })
                    }) {
                        HStack {
                            Image(systemName: "arrow.right.circle.fill")
                                .font(.title2)
                            Text("Show interAd")
                                .font(.title2)
                                .fontWeight(.semibold)
                        }
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 60)
                        .background(
                            RoundedRectangle(cornerRadius: 15)
                                .fill(Color.white.opacity(0.2))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 15)
                                        .stroke(Color.white.opacity(0.3), lineWidth: 1)
                                )
                        )
                    }
                    .padding(.horizontal, 30)
                    
                    Spacer()
                }
                
                // Banner ad at bottom
                BannerAdView()
                    .frame(height: 50)
                    .background(Color.black.opacity(0.1))
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden(false)
        .background(
            NavigationLink(destination: ScreenB(), isActive: $navigateToScreenB) {
                EmptyView()
            }
        )
    }
}

#Preview {
    NavigationView {
        ScreenA()
    }
}
