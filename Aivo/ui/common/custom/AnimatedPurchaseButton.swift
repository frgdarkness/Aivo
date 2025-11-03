//
//  AnimatedPurchaseButton.swift
//  Aivo
//
//  Created by Huy on 3/11/25.
//


import SwiftUI

struct AnimatedPurchaseButton: View {
    var title: String
    var isLoading: Bool
    var isEnabled: Bool = true
    var baseColor: Color
    var action: () -> Void

    @State private var rotate: Double = 0
    @State private var pulse: Bool = false
    @State private var shimmerPhase: CGFloat = -1.0
    @State private var isPressed: Bool = false

    var body: some View {
        Button {
            guard isEnabled, !isLoading else { return }
            UIImpactFeedbackGenerator(style: .medium).impactOccurred()
            action()
        } label: {
            ZStack {
                // Nền capsule
                Capsule()
                    .fill(baseColor)
                    .overlay(
                        Capsule().fill(
                            LinearGradient(
                                colors: [
                                    .white.opacity(0.08),
                                    .white.opacity(0.02)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                    )

                // Viền gradient quay vòng
                Capsule()
                    .strokeBorder(
                        AngularGradient(
                            gradient: Gradient(colors: [
                                .white.opacity(0.0),
                                .white.opacity(0.35),
                                .white.opacity(0.0)
                            ]),
                            center: .center,
                            angle: .degrees(rotate)
                        ),
                        lineWidth: 2
                    )
                    .blendMode(.screen)

                // Nội dung
                HStack(spacing: 10) {
                    if isLoading {
                        ProgressView()
                            .progressViewStyle(.circular)
                            .tint(.white)
                    }
                    Text(isLoading ? "Processing..." : title)
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundColor(.white)
                        .overlay( // Shimmer quét chữ
                            GeometryReader { proxy in
                                let w = proxy.size.width
                                Rectangle()
                                    .fill(
                                        LinearGradient(
                                            colors: [
                                                .white.opacity(0.0),
                                                .white.opacity(0.55),
                                                .white.opacity(0.0)
                                            ],
                                            startPoint: .top,
                                            endPoint: .bottom
                                        )
                                    )
                                    .rotationEffect(.degrees(20))
                                    .offset(x: shimmerPhase * (w + 120))
                            }
                            .mask(
                                Text(isLoading ? "Processing..." : title)
                                    .font(.system(size: 17, weight: .semibold))
                            )
                        )
                }
                .padding(.horizontal, 16)
            }
            .frame(height: 58)
            // Glow & pulse khi không loading
            .shadow(color: baseColor.opacity(isLoading ? 0.15 : 0.55), radius: isLoading ? 8 : 18, y: 6)
            .scaleEffect(isPressed ? 0.98 : (pulse && !isLoading ? 1.03 : 1.0))
            .animation(.easeInOut(duration: 1.2).repeatForever(autoreverses: true), value: pulse)
            .animation(.spring(response: 0.22, dampingFraction: 0.8), value: isPressed)
            .overlay( // Viền sáng mảnh để nút nổi hơn
                Capsule()
                    .stroke(.white.opacity(0.10), lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
        .simultaneousGesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in
                    if !isPressed { isPressed = true }
                }
                .onEnded { _ in
                    isPressed = false
                }
        )
        .onAppear {
            withAnimation(.linear(duration: 2.8).repeatForever(autoreverses: false)) {
                rotate = 360
            }
            pulse = true
            withAnimation(.linear(duration: 1.8).delay(0.2).repeatForever(autoreverses: false)) {
                shimmerPhase = 1.0
            }
        }
        .opacity(isEnabled ? 1.0 : 0.6)
        .accessibilityLabel(Text(title))
    }
}

struct AnimatedPurchaseButton_Previews: PreviewProvider {
    static var previews: some View {
        VStack(spacing: 20) {
            // Bình thường
            AnimatedPurchaseButton(
                title: "Continue For Payment",
                isLoading: false,
                isEnabled: true,
                baseColor: Color.orange
            ) {
                print("Tapped Normal")
            }

            // Loading
            AnimatedPurchaseButton(
                title: "Processing...",
                isLoading: true,
                isEnabled: true,
                baseColor: Color.orange
            ) {
                print("Tapped Loading")
            }

            // Disabled
            AnimatedPurchaseButton(
                title: "Disabled State",
                isLoading: false,
                isEnabled: false,
                baseColor: Color.orange
            ) {
                print("Tapped Disabled")
            }
        }
        .padding()
        .background(
            LinearGradient(
                colors: [.black, .gray.opacity(0.2)],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()
        )
        .previewDisplayName("AnimatedPurchaseButton Preview")
    }
}

