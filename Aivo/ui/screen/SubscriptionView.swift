import SwiftUI

struct SubscriptionView: View {
    @ObservedObject private var subscriptionManager = SubscriptionManager.shared
    var onDismiss: (() -> Void)? = nil
    
    var body: some View {
        if subscriptionManager.isPremium {
            SubscriptionScreen(onDismiss: onDismiss)
        } else {
            SubscriptionScreenIntro(onDismiss: onDismiss)
        }
    }
}

struct SubscriptionView_Previews: PreviewProvider {
    static var previews: some View {
        SubscriptionView()
    }
}
