import SwiftUI

struct SubscriptionScreen: View {
    @Environment(\.dismiss) private var dismiss
    @State private var selectedPlan: Plan = .professional
    @State private var autoRenewal: Bool = true

    enum Plan { case professional, team }

    var body: some View {
        ZStack {
            customBackgroundView

            VStack(spacing: 0) {
                header
                Spacer(minLength: 20)
                title
                features
                //Spacer(minLength: 12)
                planCards
                autoRenewalView
                //Spacer(minLength: 8)
                ctaButton
                footer
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 24)
        }
        .ignoresSafeArea()
        .background(AivoTheme.Background.primary.ignoresSafeArea())
    }

    // MARK: - Background giống PlayMySongScreen (nửa trên ảnh, dưới đen, overlay gradient)
    private var customBackgroundView: some View {
        GeometryReader { geometry in
            ZStack {
                // Nửa trên: Ảnh cover (không blur)
                VStack {
                    Image("demo_cover")
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: geometry.size.width, height: geometry.size.height * 0.55, alignment: .center)
                        .clipped()

                    Spacer()
                }

                // Nửa dưới: Đen theo theme
                VStack {
                    Spacer()
                    AivoTheme.Primary.blackOrangeDark
                        .opacity(0.9)
                        .frame(height: geometry.size.height * 0.45)
                }

                // Overlay đen dần từ đỉnh đến cuối (nhấn cam nhẹ)
                LinearGradient(
                    gradient: Gradient(stops: [
                        .init(color: Color.black.opacity(0.05), location: 0.0),
                        .init(color: Color.black.opacity(1.0), location: 0.5),
                        .init(color: Color.black.opacity(1.0), location: 1.0)
                    ]),
                    startPoint: .top,
                    endPoint: .bottom
                )

                // Orange glow very subtle at bottom area
                LinearGradient(
                    gradient: Gradient(colors: [
                        Color.clear,
                        AivoTheme.Primary.orange.opacity(0.08)
                    ]),
                    startPoint: .center,
                    endPoint: .bottom
                )
            }
            .ignoresSafeArea()
            .drawingGroup()
        }
    }

    private var header: some View {
        HStack {
            Spacer()
            Button(action: { dismiss() }) {
                Image(systemName: "xmark")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(.white)
                    .frame(width: 36, height: 36)
                    .background(Color.white.opacity(0.15))
                    .clipShape(Circle())
            }
        }
        .padding(.top, 50)
    }

    private var title: some View {
        HStack { Text("Upgrade to Premium")
                .font(.system(size: 28, weight: .heavy))
                .foregroundColor(.white)
                .shadow(color: .black.opacity(0.4), radius: 6, x: 0, y: 2)
            Spacer()
        }
        .padding(.top, 8)
    }

    private var features: some View {
        VStack(alignment: .leading, spacing: 16) {
            featureRow("1000 credits")
            featureRow("Access to All Features")
            featureRow("Remove all Ads")
            featureRow("Premium quality AI Song")
            featureRow("Unlimited downloads")
        }
        .padding(.top, 18)
    }

    private func featureRow(_ text: String) -> some View {
        HStack(spacing: 12) {
            ZStack {
                Circle().fill(AivoTheme.Primary.orange.opacity(0.15))
                    .frame(width: 28, height: 28)
                Image(systemName: "checkmark.circle.fill")
                    .foregroundColor(AivoTheme.Primary.orange)
                    .font(.system(size: 20))
            }
            Text(text)
                .foregroundColor(.white.opacity(0.85))
                .font(.system(size: 17, weight: .medium))
            Spacer()
        }
    }

    private var planCards: some View {
        VStack(spacing: 14) {
            planCard(
                title: "Yearly",
                subtitle: "1200 credit per week",
                price: "$119.99",
                per: "/Year",
                isSelected: selectedPlan == .professional,
                showTag: true
            ) { selectedPlan = .professional }

            planCard(
                title: "Weekly",
                subtitle: "1000 credits per week",
                price: "$8.99",
                per: "/Week",
                isSelected: selectedPlan == .team,
                showTag: false
            ) { selectedPlan = .team }
        }
        .padding(.top, 28)
    }

    private func planCard(title: String, subtitle: String, price: String, per: String, isSelected: Bool, showTag: Bool, onTap: @escaping () -> Void) -> some View {
        ZStack(alignment: .topTrailing) {
            Button(action: onTap) {
                HStack {
                // Radio
                ZStack {
                    Circle().stroke(AivoTheme.Primary.orange, lineWidth: 2)
                        .frame(width: 26, height: 26)
                    if isSelected {
                        Circle().fill(AivoTheme.Primary.orange)
                            .frame(width: 14, height: 14)
                    }
                }
                    .padding(.leading, 18)

                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .foregroundColor(.white)
                        .font(.system(size: 18, weight: .semibold))
//                    Text(subtitle)
//                        .foregroundColor(.white.opacity(0.7))
//                        .font(.system(size: 13, weight: .regular))
                }
                    Spacer()
                    HStack(alignment: .firstTextBaseline, spacing: 2) {
                    Text(price)
                        .foregroundColor(.white)
                        .font(.system(size: 18, weight: .bold))
                    Text(per)
                        .foregroundColor(.white.opacity(0.7))
                        .font(.system(size: 14, weight: .regular))
                    }
                    .padding(.trailing, 16)
                }
                .frame(height: 64)
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(Color.white.opacity(0.06))
                        .overlay(
                            RoundedRectangle(cornerRadius: 16)
                                .stroke(isSelected ? AivoTheme.Primary.orange : Color.white.opacity(0.15), lineWidth: 2)
                        )
                )
            }
            .buttonStyle(.plain)

            if showTag {
                tagView("Save 75%")
                    .padding(.trailing, 12)
                    .padding(.top, -8)
            }
        }
    }

    private func tagView(_ text: String) -> some View {
        let gradient = LinearGradient(
                colors: [
                    Color(red: 1.0, green: 0.1, blue: 0.1),   // 🔴 Đỏ tươi (#FF1A1A)
                    Color(red: 1.0, green: 0.25, blue: 0.0)   // 🟠 Đỏ-cam nhạt (#FF4000)
                ],
                startPoint: .leading,
                endPoint: .trailing
            )
        return Text(text)
            .font(.system(size: 12, weight: .heavy))
            .foregroundColor(.white)
            .padding(.horizontal, 10)
            .padding(.vertical, 4)
            .background(
                Capsule().fill(gradient)
            )
            .overlay(
                Capsule().stroke(Color.white.opacity(0.2), lineWidth: 1)
            )
            .shadow(color: AivoTheme.Shadow.black.opacity(0.4), radius: 6, x: 0, y: 3)
    }

    private var ctaButton: some View {
        Button(action: { /* open purchase flow */ }) {
            Text("Continue For Payment")
                .font(.system(size: 17, weight: .semibold))
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .frame(height: 58)
                .background(
                    Capsule()
                        .fill(AivoTheme.Primary.orange)
                )
        }
        .padding(.top, 18)
    }

    // MARK: - Auto Renewal
    private var autoRenewalView: some View {
        HStack(spacing: 8) {
            Image(systemName: "checkmark")
                .font(.system(size: 15, weight: .bold))
                .foregroundColor(AivoTheme.Primary.orange)
            Text("Auto Renewal. Cancel anytime.")
                .foregroundColor(.white.opacity(0.85))
                .font(.system(size: 15, weight: .medium))
        }
        .frame(maxWidth: .infinity)
        .padding(.top, 10)
        .padding(.bottom, 6)
    }

    private var footer: some View {
        VStack(spacing: 8) {
            HStack(spacing: 12) {
                Text("Terms of use")
                Text("|")
                Text("Privacy Policy")
                Text("|")
                Text("Restore")
            }
            .font(.system(size: 12, weight: .medium))
            .foregroundColor(.white.opacity(0.7))
            .padding(.top, 10)
        }
    }
}

struct SubscriptionScreen_Previews: PreviewProvider {
    static var previews: some View {
        SubscriptionScreen()
    }
}
