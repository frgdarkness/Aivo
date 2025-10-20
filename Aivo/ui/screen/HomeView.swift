import SwiftUI

struct HomeView: View {
    @State private var navigateToScreenA = false
    @State private var navigateToScreenB = false
    @State private var navigateToScreenC = false
    @State private var navigateToLanguageScreen = false
    @State private var showBuyCreditScreen = false
    @State private var showGetFreeCreditDialog = false
    @State private var showCreditDialog = false
    @State private var navigateToScreenAdmin = false
    @StateObject private var adManager = AdManager.shared
    @EnvironmentObject private var languageManager: LanguageManager
    
    var body: some View {
        NavigationView {
            ZStack {
                // Aivo Background with Orange Gradient
                AivoSunsetBackground()
                
                VStack(spacing: 30) {
                    // Header with Title and Credit Badge
                    HStack {
                        Text("AIVO")
                            .aivoText(.title)
                            .shadow(color: AivoTheme.Shadow.orange, radius: 10, x: 0, y: 0)
                        
                        Spacer()
                        
                        Button(action: {
                            showCreditDialog = true
                        }) {
                            CreditBadgeView()
                        }
                        .buttonStyle(.plain)
                    }
                    .padding(.horizontal, 20)
                    
                    Spacer()
                    
                    // Ad Test Buttons Section
                    VStack(spacing: 15) {
                        Text("Test Ads")
                            .aivoText(.subtitle)
                        
                        HStack(spacing: 15) {
                            // Show Interstitial Ad Button
                            Button(action: {
                                adManager.showInterAd { _ in
                                    
                                }
                            }) {
                                VStack {
                                    Image(systemName: "rectangle.fill.on.rectangle.fill")
                                        .font(.title2)
                                    Text("show_inter_ad")
                                        .font(.caption)
                                        .fontWeight(.medium)
                                }
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .frame(height: 70)
                                .background(
                                    RoundedRectangle(cornerRadius: 12)
                                        .fill(AivoTheme.Primary.orange.opacity(0.8))
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 12)
                                                .stroke(AivoTheme.Primary.orangeLight.opacity(0.5), lineWidth: 1)
                                        )
                                )
                            }
                            
                            // Show Rewarded Ad Button
                            Button(action: {
                                adManager.showRewardAd(onFinish: {_ in })
                            }) {
                                VStack {
                                    Image(systemName: "gift.fill")
                                        .font(.title2)
                                    Text("Show RewardAd")
                                        .font(.caption)
                                        .fontWeight(.medium)
                                }
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .frame(height: 70)
                                .background(
                                    RoundedRectangle(cornerRadius: 12)
                                        .fill(AivoTheme.Primary.orangeLight.opacity(0.8))
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 12)
                                                .stroke(AivoTheme.Primary.orange.opacity(0.5), lineWidth: 1)
                                        )
                                )
                            }
                        }
                    }
                    .padding(.horizontal, 30)
                    
                    // Navigation buttons
                    VStack(spacing: 20) {
                        Text("Navigation")
                            .aivoText(.subtitle)
                        
                        NavigationLink(destination: ScreenA(), isActive: $navigateToScreenA) {
                            Button(action: {
                                navigateToScreenA = true
                            }) {
                                HStack {
                                    Image(systemName: "arrow.right.circle.fill")
                                        .font(.title2)
                                    Text("Go Screen A")
                                        .font(.title2)
                                        .fontWeight(.semibold)
                                }
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .frame(height: 60)
                                .background(
                                    RoundedRectangle(cornerRadius: 15)
                                        .fill(AivoTheme.Background.card.opacity(0.8))
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 15)
                                                .stroke(AivoTheme.Primary.orange.opacity(0.3), lineWidth: 1)
                                        )
                                )
                            }
                        }
                        
                        NavigationLink(destination: ScreenB(), isActive: $navigateToScreenB) {
                            Button(action: {
                                navigateToScreenB = true
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
                                        .fill(AivoTheme.Background.card.opacity(0.8))
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 15)
                                                .stroke(AivoTheme.Primary.orange.opacity(0.3), lineWidth: 1)
                                        )
                                )
                            }
                        }
                        
                        NavigationLink(destination: ScreenC(), isActive: $navigateToScreenC) {
                            Button(action: {
                                navigateToScreenC = true
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
                                        .fill(AivoTheme.Background.card.opacity(0.8))
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 15)
                                                .stroke(AivoTheme.Primary.orange.opacity(0.3), lineWidth: 1)
                                        )
                                )
                            }
                        }
                        
                        NavigationLink(destination: AdminScreen(), isActive: $navigateToScreenAdmin) {
                            Button(action: {
                                navigateToScreenAdmin = true
                            }) {
                                HStack {
                                    Image(systemName: "arrow.right.circle.fill")
                                        .font(.title2)
                                    Text("Go Screen Admin")
                                        .font(.title2)
                                        .fontWeight(.semibold)
                                }
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .frame(height: 60)
                                .background(
                                    RoundedRectangle(cornerRadius: 15)
                                        .fill(AivoTheme.Background.card.opacity(0.8))
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 15)
                                                .stroke(AivoTheme.Primary.orange.opacity(0.3), lineWidth: 1)
                                        )
                                )
                            }
                        }
                        
                        NavigationLink(destination: SelectLanguageScreen { language in
                            print("Selected language: \(language.name)")
                            // Dismiss the language screen after selection
                            navigateToLanguageScreen = false
                        }
                        .environmentObject(languageManager), isActive: $navigateToLanguageScreen) {
                            Button(action: {
                                navigateToLanguageScreen = true
                            }) {
                                HStack {
                                    Image(systemName: "globe")
                                        .font(.title2)
                                    Text("Select Language")
                                        .font(.title2)
                                        .fontWeight(.semibold)
                                }
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .frame(height: 60)
                                .background(
                                    RoundedRectangle(cornerRadius: 15)
                                        .fill(AivoTheme.Background.card.opacity(0.8))
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 15)
                                                .stroke(AivoTheme.Primary.orange.opacity(0.3), lineWidth: 1)
                                        )
                                )
                            }
                        }
                    }
                    .padding(.horizontal, 30)
                    
                    Spacer()
                }
            }
        }
        .navigationBarHidden(true)
        .creditDialog(
            isPresented: $showCreditDialog,
            onBuy: {
                showBuyCreditScreen = true
            },
            onGetFree: {
                showGetFreeCreditDialog = true
            }
        )
        .fullScreenCover(isPresented: $showBuyCreditScreen) {
            BuyCreditScreen {
                showBuyCreditScreen = false
            }
        }
        .overlay(
            GetFreeCreditDialogOverlay(isPresented: $showGetFreeCreditDialog)
        )
//        .sheet(isPresented: $showGetFreeCreditDialog) {
//            GetFreeCreditDialog(onClose: {
//                showGetFreeCreditDialog = false
//            })
//        }
    }
}

#Preview {
    HomeView()
}
