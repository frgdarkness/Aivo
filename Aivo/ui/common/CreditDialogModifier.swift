//
//  CreditDialogModifier.swift
//  DreamHomeAI
//
//  Created by Huy on 10/10/25.
//


import SwiftUI
import Foundation

// MARK: - View Modifier: Credit Dialog
struct CreditDialogModifier: ViewModifier {
    @Binding var isPresented: Bool
    let creditCount = CreditManager.shared.credits
    let onBuy: () -> Void
    let onGetFree: () -> Void

    func body(content: Content) -> some View {
        ZStack {
            content

            if isPresented {
                // Nền mờ tối
                Rectangle()
                    .fill(Color.black.opacity(0.45))
                    .ignoresSafeArea()
                    .transition(.opacity)
                    .onTapGesture { withAnimation(.spring()) { isPresented = false } }

                // Dialog Card
                CreditDialogCard(
                    creditCount: creditCount,
                    onClose: { withAnimation(.spring()) { isPresented = false } },
                    onBuy: {
                        withAnimation(.spring()) { isPresented = false }
                        onBuy()
                    },
                    onGetFree: {
                        withAnimation(.spring()) { isPresented = false }
                        onGetFree()
                    }
                )
                .padding(.horizontal, 24)
                .transition(.scale.combined(with: .opacity))
                .zIndex(1)
            }
        }
        .animation(.spring(response: 0.35, dampingFraction: 0.88, blendDuration: 0.2), value: isPresented)
    }
}

extension View {
    /// Gắn dialog credit vào bất kỳ view nào
    func creditDialog(
        isPresented: Binding<Bool>,
        onBuy: @escaping () -> Void,
        onGetFree: @escaping () -> Void
    ) -> some View {
        self.modifier(CreditDialogModifier(
            isPresented: isPresented,
            onBuy: onBuy,
            onGetFree: onGetFree
        ))
    }
}

// MARK: - Dialog Card
private struct CreditDialogCard: View {
    let creditCount: Int
    let onClose: () -> Void
    let onBuy: () -> Void
    let onGetFree: () -> Void

    var body: some View {
        VStack(spacing: 16) {
            // Header: Title + nút X
            HStack {
                   Text(MyLocalizable.yourCredit.localized)
                       .font(.title3).bold()
                       .foregroundColor(.white)
                Spacer()
                Button(action: onClose) {
                    Image(systemName: "xmark")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.white.opacity(0.9))
                        .padding(8)
                        .background(Color.white.opacity(0.12))
                        .clipShape(Circle())
                }
                .buttonStyle(.plain)
            }

            // Coin + số credits
            VStack(spacing: 8) {
                Image("icon_coin")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 64, height: 64)
                    .shadow(radius: 4, y: 2)

                HStack(spacing: 8) {
                    Text("\(creditCount)")
                        .font(.system(size: 34, weight: .bold))
                        .foregroundColor(.white)
                   Text(MyLocalizable.credits.localized)
                       .font(.headline)
                       .foregroundColor(.white.opacity(0.9))
                }
            }
            .padding(.top, 6)

            // Mô tả nhẹ
                   Text(MyLocalizable.creditsDescription.localized)
                       .font(.subheadline)
                       .foregroundColor(.white.opacity(0.85))
                       .multilineTextAlignment(.center)
                       .padding(.horizontal, 6)

            // Divider mềm
            Divider().background(Color.white.opacity(0.12))

            // Quick perks / gợi ý (tuỳ chỉnh)
                   VStack(alignment: .leading, spacing: 8) {
                       PerkRow(text: MyLocalizable.unlockAllFeatures.localized)
                       PerkRow(text: MyLocalizable.processedOnUltraServers.localized)
                       PerkRow(text: MyLocalizable.boostProcessingSpeed.localized)
                       PerkRow(text: MyLocalizable.premiumDesignQuality.localized)
                   }
            .padding(.horizontal, 6)

            // Buttons
            VStack(spacing: 10) {
                // Primary: Buy CREDIT
                Button(action: onBuy) {
                   Text(MyLocalizable.buyCredit.localized)
                       .font(.headline).bold()
                       .foregroundColor(.black)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(
                            LinearGradient(
                                gradient: Gradient(colors: [
                                    Color(red: 1, green: 0.84, blue: 0.20),
                                    Color(red: 1, green: 0.93, blue: 0.50)
                                ]),
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                }
                .buttonStyle(.plain)

                // Secondary: Get FREE
                Button(action: onGetFree) {
                    HStack(spacing: 6) {
                        Image(systemName: "gift.fill")
                            .font(.headline)
                           Text(MyLocalizable.getFree.localized)
                               .font(.headline).bold()
                    }
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 13)
                    .background(
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .strokeBorder(Color.white.opacity(0.35), lineWidth: 1)
                    )
                }
                .buttonStyle(.plain)
            }
            .padding(.top, 4)
        }
        .padding(16)
        .background(
            // Thẻ nền mờ + gradient tinh tế
            ZStack {
                LinearGradient(
                    gradient: Gradient(colors: [
                        Color.black.opacity(0.75),
                        Color.black.opacity(0.55)
                    ]),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .background(.ultraThinMaterial) // hiệu ứng blur
                .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
            }
        )
        .overlay(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(Color.white.opacity(0.10), lineWidth: 1)
        )
        .shadow(color: .black.opacity(0.35), radius: 24, x: 0, y: 12)
    }
}

// MARK: - Perk Row
private struct PerkRow: View {
    let text: String
    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: "checkmark.seal.fill")
                .foregroundColor(.green)
                .font(.system(size: 14, weight: .semibold))
            Text(text)
                .foregroundColor(.white)
                .font(.system(size: 15, weight: .medium))
            Spacer(minLength: 0)
        }
    }
}

// MARK: - Preview
#Preview {
    ZStack {
        LinearGradient(colors: [.black, .gray], startPoint: .top, endPoint: .bottom)
            .ignoresSafeArea()
        Text("Your Screen")
            .foregroundColor(.white)
    }
    .creditDialog(
        isPresented: .constant(true),
        onBuy: {},
        onGetFree: {}
    )
}
