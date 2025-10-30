import SwiftUI

struct SubscriptionScreen: View {
    @Environment(\.dismiss) private var dismiss
    @State private var selectedPlan: Plan = .professional

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
                        .scaleEffect(1.2)
                        .clipped()
                        .frame(height: geometry.size.height * 0.55)
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
            Button(action: { dismiss() }) {
                Image(systemName: "xmark")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(.white)
                    .frame(width: 36, height: 36)
                    .background(Color.white.opacity(0.15))
                    .clipShape(Circle())
            }
            Spacer()
        }
        .padding(.top, 14)
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
            featureRow("Unlimited AI Generations")
            featureRow("Generate High Quality Images")
            featureRow("Ads Free")
            featureRow("Unlimited Storage")
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
                .foregroundColor(.white)
                .font(.system(size: 17, weight: .medium))
            Spacer()
        }
    }

    private var planCards: some View {
        VStack(spacing: 14) {
            planCard(
                title: "Professional",
                subtitle: "7-Days Free Trial",
                price: "$29",
                per: "/Month",
                isSelected: selectedPlan == .professional
            ) { selectedPlan = .professional }

            planCard(
                title: "Team",
                subtitle: "14-Days Free Trial",
                price: "$99",
                per: "/Month",
                isSelected: selectedPlan == .team
            ) { selectedPlan = .team }
        }
        .padding(.top, 28)
    }

    private func planCard(title: String, subtitle: String, price: String, per: String, isSelected: Bool, onTap: @escaping () -> Void) -> some View {
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
                        .font(.system(size: 17, weight: .semibold))
                    Text(subtitle)
                        .foregroundColor(.white.opacity(0.7))
                        .font(.system(size: 13, weight: .regular))
                }
                Spacer()
                HStack(alignment: .firstTextBaseline, spacing: 2) {
                    Text(price)
                        .foregroundColor(.white)
                        .font(.system(size: 18, weight: .bold))
                    Text(per)
                        .foregroundColor(.white.opacity(0.7))
                        .font(.system(size: 12, weight: .regular))
                }
                .padding(.trailing, 10)
            }
            .frame(height: 74)
            .background(
                RoundedRectangle(cornerRadius: 36)
                    .fill(Color.white.opacity(0.06))
                    .overlay(
                        RoundedRectangle(cornerRadius: 36)
                            .stroke(isSelected ? AivoTheme.Primary.orange : Color.white.opacity(0.15), lineWidth: 2)
                    )
            )
        }
        .buttonStyle(.plain)
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
