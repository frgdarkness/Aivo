import SwiftUI

struct ScreenB: View {
    @State private var navigateToScreenC = false
    @StateObject private var adManager = AdManager.shared
    
    var body: some View {
        ZStack {
            // Background gradient
            LinearGradient(
                gradient: Gradient(colors: [Color.orange.opacity(0.8), Color.red.opacity(0.6)]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Main content
                VStack(spacing: 40) {
                    // Title
                    Text("Screen B")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                        .padding(.top, 50)
                    
                    Spacer()
                    
                    // Navigation button with rewarded ad
                    Button(action: {
                        // Show rewarded ad before navigation
                        adManager.showRewardAd(onFinish: {_ in })
                    }) {
                        HStack {
                            Image(systemName: "arrow.right.circle.fill")
                                .font(.title2)
                            Text("Go Screen C")
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
                NativeAdContainerView()
                    .frame(height: 240)
                    .padding(.bottom, 8)
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden(false)
        .background(
            NavigationLink(destination: ScreenC(), isActive: $navigateToScreenC) {
                EmptyView()
            }
        )
    }
}

#Preview {
    NavigationView {
        ScreenB()
    }
}
