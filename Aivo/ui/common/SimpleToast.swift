//
//  SimpleToast.swift
//  DreamHomeAI
//
//  Created by Huy on 14/10/25.
//


import SwiftUI

// Gói dữ liệu toast
struct SimpleToast: Equatable {
    let message: String
    let icon: String?   // ví dụ "checkmark.circle.fill"
    let duration: TimeInterval
}

// ViewModifier để overlay toast
struct SimpleToastModifier: ViewModifier {
    @Binding var toast: SimpleToast?
    @State private var isVisible = false

    func body(content: Content) -> some View {
        ZStack {
            content

            if let toast, isVisible {
                // Toast view
                HStack(spacing: 10) {
                    if let icon = toast.icon {
                        Image(systemName: icon)
                            .font(.system(size: 16, weight: .semibold))
                    }
                    Text(toast.message)
                        .font(.system(size: 14, weight: .semibold))
                        .multilineTextAlignment(.center)
                }
                .foregroundColor(.white)
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                .background(.ultraThinMaterial.opacity(0.25))
                .background(Color.black.opacity(0.7))
                .clipShape(Capsule())
                .shadow(radius: 8)
                .padding(.bottom, 28)
                .frame(maxHeight: .infinity, alignment: .bottom)
                .transition(.move(edge: .bottom).combined(with: .opacity))
                .onAppear {
                    // Haptics nhẹ
                    let gen = UINotificationFeedbackGenerator()
                    gen.notificationOccurred(.success)

                    // Tự ẩn sau duration
                    DispatchQueue.main.asyncAfter(deadline: .now() + (toast.duration)) {
                        withAnimation(.spring(response: 0.4, dampingFraction: 0.9)) {
                            isVisible = false
                        }
                        // dọn state sau animation
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                            self.toast = nil
                        }
                    }
                }
            }
        }
        .onChange(of: toast) { newValue in
            guard newValue != nil else { return }
            withAnimation(.spring(response: 0.4, dampingFraction: 0.9)) {
                isVisible = true
            }
        }
    }
}

extension View {
    func simpleToast(_ toast: Binding<SimpleToast?>) -> some View {
        modifier(SimpleToastModifier(toast: toast))
    }
}
