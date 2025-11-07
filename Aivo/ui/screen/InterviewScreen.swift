import SwiftUI

// MARK: - Interview Screen
struct InterviewScreen: View {
    let onContinue: () -> Void
    
    // Animation states
    @State private var showWelcome = false
    @State private var showButton = false
    
    var body: some View {
        ZStack {
            // Background image
//            Image("intro_first")
//                .resizable()
//                .aspectRatio(contentMode: .fill)
//                .ignoresSafeArea()
//                .overlay(
//                    // Dark overlay để text nổi bật
//                    LinearGradient(
//                        gradient: Gradient(colors: [
//                            Color.black.opacity(0.1),
//                            Color.black.opacity(0.8)
//                        ]),
//                        startPoint: .top,
//                        endPoint: .bottom
//                    )
//                )
            //AivoSunsetBackground()
            
            
            
//            VStack(spacing: 2) {
//                Text("Welcome to")
//                    .font(.system(size: 32, weight: .medium))
//                    .foregroundColor(.white)
//                
//                // AIVO text với màu orange
//                HStack(spacing: 4) {
//                    Text("AIVO")
//                        .font(.system(size: 38, weight: .black, design: .rounded))
//                        .foregroundColor(AivoTheme.Primary.orange)
//                        .shadow(color: AivoTheme.Primary.orange.opacity(0.6), radius: 8, x: 0, y: 4)
//                    
//                    Text("- AI Music Maker")
//                        .font(.system(size: 32, weight: .semibold))
//                        .foregroundColor(.white)
//                }
//            }
//            .padding(.bottom, 60)
            
            // Content VStack
            VStack(spacing: 0) {
                Spacer()
                
                // Welcome text
                VStack(spacing: 2) {
                    Text("Welcome to")
                        .font(.system(size: 32, weight: .medium))
                        .foregroundColor(.white)
                    
                    HStack(spacing: 4) {
                        Text("AIVO")
                            .font(.system(size: 38, weight: .black, design: .rounded))
                            .foregroundColor(AivoTheme.Primary.orange)
                            .shadow(color: AivoTheme.Primary.orange.opacity(0.6), radius: 8, x: 0, y: 4)
                        
                        Text("- AI Music Maker")
                            .font(.system(size: 32, weight: .semibold))
                            .foregroundColor(.white)
                    }
                }
                // ✨ Animation cho Welcome
                .opacity(showWelcome ? 1 : 0)
                .offset(y: showWelcome ? 0 : 30)
                .animation(.easeOut(duration: 1.0).delay(0.3), value: showWelcome)
                .padding(.bottom, 32)
                
                // Continue Button
                Button(action: {
                    onContinue()
                }) {
                    Text("Continue")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(.black)
                        .frame(maxWidth: .infinity)
                        .frame(height: 56)
                        .background(AivoTheme.Primary.orange)
                        .cornerRadius(16)
                        .shadow(color: AivoTheme.Shadow.orange, radius: 12, x: 0, y: 4)
                }
                .padding(.horizontal, 40)
                .padding(.bottom, 50)
                // ✨ Animation cho button
                .opacity(showButton ? 1 : 0)
                .offset(y: showButton ? 0 : 40)
                .animation(.easeOut(duration: 0.9).delay(1.0), value: showButton)
            }
        }
        .background(
            //AivoSunsetBackground()
        
            Image("intro_first")
                .resizable()
                .aspectRatio(contentMode: .fill)
                .ignoresSafeArea()
                .overlay(
                    // Dark overlay để text nổi bật
                    LinearGradient(
                        gradient: Gradient(colors: [
                            Color.black.opacity(0.1),
                            Color.black.opacity(0.8)
                        ]),
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
        ).ignoresSafeArea()
        .onAppear {
            // Bắt đầu hiệu ứng tuần tự
            showWelcome = true
            showButton = true
        }
    }
}

// MARK: - Preview
struct InterviewScreen_Previews: PreviewProvider {
    static var previews: some View {
        InterviewScreen {
            print("Continue tapped")
        }
    }
}

