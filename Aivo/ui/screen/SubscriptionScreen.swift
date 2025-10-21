import SwiftUI

// MARK: - Subscription Plan Model
enum SubscriptionPlan: String, CaseIterable, Identifiable {
    case weekly = "Weekly"
    case monthly = "Monthly"
    case annually = "Annually"
    
    var id: String { self.rawValue }
    
    var displayName: String {
        switch self {
        case .weekly: return "Weekly Plan"
        case .monthly: return "Monthly Plan"
        case .annually: return "Annually Plan"
        }
    }
    
    var price: String {
        switch self {
        case .weekly: return "198.000 ₫ / week"
        case .monthly: return "49.000 ₫ / month"
        case .annually: return "1.250.000 ₫ / year"
        }
    }
    
    var weeklyEquivalent: String {
        switch self {
        case .weekly: return "198.000 ₫ / week"
        case .monthly: return "₫11,307.69 / week"
        case .annually: return "₫24,038.46 / week"
        }
    }
    
    var isBestValue: Bool {
        return self == .annually
    }
    
    var renewalText: String {
        switch self {
        case .weekly: return "Renews Weekly"
        case .monthly: return "Renews Monthly"
        case .annually: return "Renews Annualy"
        }
    }
}

// MARK: - Subscription Screen
struct SubscriptionScreen: View {
    @State private var selectedPlan: SubscriptionPlan = .annually
    @State private var autoRenewal: Bool = true
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        ZStack {
            // Background
            AivoSunsetBackground()
            
            ScrollView {
                VStack(spacing: 0) {
                    // Header
                    headerView
                    
                    // Features
                    featuresView
                    
                    // Subscription Plans
                    plansView
                    
                    // Auto Renewal
                    autoRenewalView
                    
                    // Subscribe Button
                    subscribeButton
                    
                    // Footer Links
                    footerLinks
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 40)
            }
        }
        .navigationBarHidden(true)
    }
    
    // MARK: - Header View
    private var headerView: some View {
        VStack(spacing: 16) {
            HStack {
                Spacer()
                Button(action: { dismiss() }) {
                    Image(systemName: "xmark")
                        .font(.title2)
                        .foregroundColor(.white)
                }
            }
            .padding(.top, 20)
            
            VStack(spacing: 12) {
                Text("ENJOY AIVO PRO")
                    .font(.system(size: 28, weight: .black, design: .monospaced))
                    .foregroundColor(.white)
                
                Text("AI Song & Music Maker")
                    .font(.subheadline)
                    .foregroundColor(.white)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(
                        Capsule()
                            .fill(Color.gray.opacity(0.3))
                    )
            }
        }
        .padding(.bottom, 40)
    }
    
    // MARK: - Features View
    private var featuresView: some View {
        VStack(spacing: 20) {
            FeatureRow(
                icon: "mic.fill",
                iconColor: .blue,
                title: "Fast Song Creation",
                description: "Generate Hits in Seconds"
            )
            
            FeatureRow(
                icon: "guitar.fill",
                iconColor: .red,
                title: "Ai Voice Covers",
                description: "Create Your Voice"
            )
            
            FeatureRow(
                icon: "camera.fill",
                iconColor: .gray,
                title: "Top-Notch studio Quality",
                description: "Advanced Details"
            )
            
            FeatureRow(
                icon: "ribbon.fill",
                iconColor: .yellow,
                title: "Royalty Free",
                description: "Use songs anywhere you want"
            )
        }
        .padding(.bottom, 40)
    }
    
    // MARK: - Plans View
    private var plansView: some View {
        VStack(spacing: 16) {
            ForEach(SubscriptionPlan.allCases) { plan in
                PlanCard(
                    plan: plan,
                    isSelected: selectedPlan == plan,
                    action: { selectedPlan = plan }
                )
            }
        }
        .padding(.bottom, 24)
    }
    
    // MARK: - Auto Renewal View
    private var autoRenewalView: some View {
        HStack(spacing: 12) {
            Button(action: { autoRenewal.toggle() }) {
                Image(systemName: autoRenewal ? "checkmark.square.fill" : "square")
                    .font(.title2)
                    .foregroundColor(autoRenewal ? AivoTheme.Primary.orange : .gray)
            }
            
            Text("Auto Renewal. Cancel anytime.")
                .font(.subheadline)
                .foregroundColor(.white)
            
            Spacer()
        }
        .padding(.bottom, 32)
    }
    
    // MARK: - Subscribe Button
    private var subscribeButton: some View {
        Button(action: subscribeAction) {
            VStack(spacing: 4) {
                Text("Start My Subscription")
                    .font(.headline)
                    .fontWeight(.bold)
                    .foregroundColor(.black)
                
                Text(selectedPlan.renewalText)
                    .font(.caption)
                    .foregroundColor(.black.opacity(0.8))
            }
            .frame(maxWidth: .infinity)
            .frame(height: 56)
            .background(AivoTheme.Primary.orange)
            .cornerRadius(12)
            .shadow(color: AivoTheme.Shadow.orange, radius: 10, x: 0, y: 0)
        }
        .padding(.bottom, 24)
    }
    
    // MARK: - Footer Links
    private var footerLinks: some View {
        VStack(spacing: 16) {
            Button(action: restoreAction) {
                Text("Restore Subscriptions")
                    .font(.subheadline)
                    .foregroundColor(.white)
            }
            
            HStack {
                Button(action: privacyAction) {
                    Text("Privacy Policy")
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.8))
                }
                
                Spacer()
                
                Button(action: termsAction) {
                    Text("Term of Use")
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.8))
                }
            }
        }
    }
    
    // MARK: - Actions
    private func subscribeAction() {
        // Handle subscription logic
        print("Subscribe to \(selectedPlan.displayName)")
    }
    
    private func restoreAction() {
        // Handle restore logic
        print("Restore subscriptions")
    }
    
    private func privacyAction() {
        // Handle privacy policy
        print("Open privacy policy")
    }
    
    private func termsAction() {
        // Handle terms of use
        print("Open terms of use")
    }
}

// MARK: - Feature Row Component
struct FeatureRow: View {
    let icon: String
    let iconColor: Color
    let title: String
    let description: String
    
    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(iconColor)
                .frame(width: 24, height: 24)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.headline)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                
                Text(description)
                    .font(.subheadline)
                    .foregroundColor(.white.opacity(0.8))
            }
            
            Spacer()
        }
    }
}

// MARK: - Plan Card Component
struct PlanCard: View {
    let plan: SubscriptionPlan
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        ZStack {
            // Best value tag
            if plan.isBestValue {
                VStack {
                    HStack {
                        Spacer()
                        Text("Best value")
                            .font(.caption)
                            .fontWeight(.bold)
                            .foregroundColor(.black)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(
                                Capsule()
                                    .fill(Color.yellow)
                            )
                            .offset(x: -8, y: -8)
                    }
                    Spacer()
                }
            }
            
            // Plan card
            Button(action: action) {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(plan.displayName)
                            .font(.headline)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                        
                        Text(plan.price)
                            .font(.subheadline)
                            .foregroundColor(.white.opacity(0.8))
                    }
                    
                    Spacer()
                    
                    VStack(alignment: .trailing, spacing: 4) {
                        Text(plan.weeklyEquivalent)
                            .font(.caption)
                            .foregroundColor(.white.opacity(0.6))
                        
                        Circle()
                            .stroke(isSelected ? AivoTheme.Primary.orange : Color.gray, lineWidth: 2)
                            .frame(width: 20, height: 20)
                            .overlay(
                                Circle()
                                    .fill(isSelected ? AivoTheme.Primary.orange : Color.clear)
                                    .frame(width: 8, height: 8)
                            )
                    }
                }
                .padding(16)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color.gray.opacity(0.2))
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(isSelected ? AivoTheme.Primary.orange : Color.gray.opacity(0.3), lineWidth: isSelected ? 2 : 1)
                        )
                )
            }
        }
    }
}

// MARK: - Preview
struct SubscriptionScreen_Previews: PreviewProvider {
    static var previews: some View {
        SubscriptionScreen()
    }
}
