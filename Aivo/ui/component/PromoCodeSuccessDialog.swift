import SwiftUI

struct PromoCodeSuccessDialog: View {
    @Binding var isPresented: Bool
    
    var body: some View {
        ZStack {
            // Background blur/dim
            Color.black.opacity(0.6)
                .ignoresSafeArea()
                .onTapGesture {
                    withAnimation { isPresented = false }
                }
            
            VStack(spacing: 24) {
                // Header Image / Icon with Glow
                ZStack {
                    Circle()
                        .fill(RadialGradient(
                            gradient: Gradient(colors: [AivoTheme.Primary.orange.opacity(0.6), .clear]),
                            center: .center,
                            startRadius: 0,
                            endRadius: 60
                        ))
                        .frame(width: 120, height: 120)
                    
                    Image("icon_gift_yes") // Using existing gift icon
                        .resizable()
                        .scaledToFit()
                        .frame(width: 80, height: 80)
                        .shadow(color: AivoTheme.Primary.orange.opacity(0.5), radius: 10, x: 0, y: 5)
                }
                .padding(.top, 10)
                
                // Titles
                VStack(spacing: 8) {
                    Text("Congratulations!")
                        .font(.system(size: 24, weight: .bold))
                        .foregroundColor(.white)
                    
                    Text("You have successfully claimed your promo code.")
                        .font(.system(size: 16))
                        .foregroundColor(.gray)
                        .multilineTextAlignment(.center)
                    
                    Text("+100 Credits")
                        .font(.system(size: 28, weight: .black))
                        .foregroundColor(AivoTheme.Primary.orange)
                        .padding(.top, 4)
                }
                
                // OK Button
                Button(action: {
                    withAnimation { isPresented = false }
                }) {
                    Text("Awesome")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 54)
                        .background(
                            LinearGradient(
                                colors: [AivoTheme.Primary.orange, AivoTheme.Primary.orange.opacity(0.8)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .cornerRadius(27)
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 10)
            }
            .padding(24)
            .background(
                ZStack {
                    RoundedRectangle(cornerRadius: 24)
                        .fill(Color(hex: "#1C1C1E"))
                    
                    RoundedRectangle(cornerRadius: 24)
                        .stroke(
                            LinearGradient(
                                colors: [AivoTheme.Primary.orange, AivoTheme.Primary.orange.opacity(0.5), AivoTheme.Primary.orange],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 3
                        )
                }
            )
            .clipShape(RoundedRectangle(cornerRadius: 24))
            .shadow(color: AivoTheme.Primary.orange.opacity(0.25), radius: 15)
            .shadow(color: .black.opacity(0.5), radius: 40)
            .padding(.horizontal, 40)
        }
    }
}
