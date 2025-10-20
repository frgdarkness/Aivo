import SwiftUI

struct CreditBadgeView: View {
    @ObservedObject private var creditManager = CreditManager.shared
    
    var body: some View {
        HStack(spacing: 4) {
            Image("icon_coin")
                .foregroundColor(Color.yellow)
                .font(.system(size: 15, weight: .bold))
            Text("\(creditManager.credits)")
                .foregroundColor(.white)
                .font(.system(size: 20, weight: .semibold))
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(Color.black.opacity(0.85))
        .clipShape(Capsule())
        .accessibilityLabel("User Credits")
    }
}

#Preview {
    CreditBadgeView()
}
