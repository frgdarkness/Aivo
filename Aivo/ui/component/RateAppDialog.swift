import SwiftUI

struct RateAppDialog: View {
    @Binding var isPresented: Bool
    var onRate: (Int) -> Void
    var onDismiss: () -> Void
    
    @State private var rating: Int = 0
    
    var body: some View {
        ZStack {
            // Background dim
            Color.black.opacity(0.6)
                .edgesIgnoringSafeArea(.all)
                .onTapGesture {
                    // Optional: dismiss on background tap
                    // isPresented = false
                }
            
            // Dialog Content
            VStack(spacing: 24) {
                // Title & Description
                VStack(spacing: 12) {
                    Text("Support our improvement")
                        .font(.headline)
                        .fontWeight(.bold)
                        .foregroundColor(.black)
                        .multilineTextAlignment(.center)
                    
                    Text("Your rating helps us improve and provide the best possible experience for our users.")
                        .font(.subheadline)
                        .foregroundColor(.gray)
                        .multilineTextAlignment(.center)
                        .fixedSize(horizontal: false, vertical: true)
                }
                
                // Star Rating View
                // Emoji Rating View
                HStack(spacing: 12) {
                    ForEach(1...5, id: \.self) { index in
                        Image("icon_emoji_rate_\(index)")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 44, height: 44) // Adjust size as needed
                            .padding(4)
                            .background(
                                Circle()
                                    .stroke(rating == index ? AivoTheme.Primary.orange : Color.clear, lineWidth: 2)
                            )
                            .scaleEffect(rating == index ? 1.1 : 1.0)
                            .opacity(rating == 0 || rating == index ? 1.0 : 0.5) // Dim others if one selected
                            .onTapGesture {
                                withAnimation(.spring()) {
                                    rating = index
                                }
                            }
                    }
                }
                
                // Buttons
                VStack(spacing: 12) {
                    Button(action: {
                        onRate(rating)
                        isPresented = false
                    }) {
                        Text("Rate")
                            .font(.headline)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .frame(height: 50)
                            .background(rating > 0 ? AivoTheme.Primary.orange : Color.gray) // Disable visuals if 0
                            .cornerRadius(12)
                    }
                    .disabled(rating == 0)
                    
                    Button(action: {
                        onDismiss()
                        isPresented = false
                    }) {
                        Text("Not Now")
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .foregroundColor(.gray)
                    }
                }
            }
            .padding(24)
            .background(Color.white)
            .cornerRadius(20)
            .shadow(radius: 20)
            .padding(.horizontal, 40)
            .scaleEffect(isPresented ? 1 : 0.8)
            .opacity(isPresented ? 1 : 0)
            .animation(.spring(), value: isPresented)
        }
    }
}
