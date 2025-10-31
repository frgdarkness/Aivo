import SwiftUI

struct CreditBadgeView: View {
    @ObservedObject private var creditManager = CreditManager.shared
    
    var body: some View {
        HStack(spacing: 4) {
            Image("icon_coin")
                .foregroundColor(Color.yellow)
                .font(.system(size: 14, weight: .bold))
            Text("\(creditManager.credits)")
                .foregroundColor(.white)
                .font(.system(size: 18, weight: .semibold))
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 6)
        .background(Color.black.opacity(0.85))
        .clipShape(Capsule())
        .accessibilityLabel("User Credits")
    }
}

#Preview {
    CreditBadgeView()
}
