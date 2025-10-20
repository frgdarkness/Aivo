//
//  SelectLanguageScreen.swift
//  DreamHomeAI
//

import SwiftUI
import GoogleMobileAds

struct SelectLanguageScreen: View {
    let onLanguageSelected: (LanguageData) -> Void

    // Nhận LanguageManager từ môi trường (đã bơm ở @main App)
    @EnvironmentObject private var languageManager: LanguageManager
    @Environment(\.dismiss) private var dismiss

    @StateObject private var userDefaultsManager: UserDefaultsManager = .shared
    @State private var selectedLanguage: LanguageData? = nil
    @State private var isFirstTime: Bool = false

    var body: some View {
        ZStack {
            // Background gradient
            LinearGradient(
                gradient: Gradient(colors: [
                    Color(red: 0.95, green: 0.95, blue: 1.0),
                    Color.white
                ]),
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()

            VStack(spacing: 0) {
                // Header
                headerView

                // Language List
                ScrollView {
                    LazyVStack(spacing: 12) {
                        ForEach(LanguageData.supportedLanguages) { language in
                            languageRow(language)
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 20)
                }

                // Native Ad at bottom
                NativeAdContainerView()
                    .frame(height: 240)
                    .padding(.horizontal, 16)
                    .padding(.bottom, 8)
            }
        }
        .onAppear {
            // Chọn mặc định theo ngôn ngữ hiện tại của app
            isFirstTime = !userDefaultsManager.isLanguageShowed
            if let current = LanguageData.supportedLanguages.first(where: { canonical($0.code) == canonical(languageManager.code) }) {
                selectedLanguage = current
            } else {
                selectedLanguage = LanguageData.supportedLanguages.first
            }
            //FirebaseLogger.shared.logScreenView(FirebaseLogger.EVENT_SCREEN_LANGUAGE)
        }
    }

    // MARK: - Header View
    private var headerView: some View {
        HStack {
            // Back button chỉ hiện khi không phải lần đầu
            if !isFirstTime {
                Button(action: { dismiss() }) {
                    Image(systemName: "chevron.left")
                        .font(.title2)
                        .foregroundColor(.black)
                }
            } else {
                // Spacer để giữ layout khi không có back button
                Spacer()
                    .frame(width: 32, height: 32)
            }

            Spacer()

            Text("language_title".localizedWithCurrentLanguage)
                .font(.largeTitle)
                .fontWeight(.semibold)
                .foregroundColor(.black)

            Spacer()

            Button(action: applySelectedLanguage) {
                Image(systemName: "checkmark")
                    .font(.title2)
                    .foregroundColor(.white)
                    .frame(width: 32, height: 32)
                    .background(
                        LinearGradient(
                            gradient: Gradient(colors: [Color.orange, Color.pink]),
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .clipShape(Circle())
            }
            .disabled(selectedLanguage == nil)
            .opacity(selectedLanguage == nil ? 0.5 : 1.0)
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 20)
        .padding(.top, 10)
        .padding(.bottom, 10)
    }

    // MARK: - Language Row
    private func languageRow(_ language: LanguageData) -> some View {
        let isSelected = selectedLanguage?.code == language.code
        let isCurrent = canonical(languageManager.code) == canonical(language.code)

        return Button(action: {
            Logger.d("selectedLanguage: \(language.code)")
            selectedLanguage = language
            // Nếu muốn áp dụng ngay khi chạm dòng, bật dòng sau:
            // applySelectedLanguage()
        }) {
            HStack(spacing: 16) {
                // Flag
                Text(language.flagEmoji)
                    .font(.title2)
                    .frame(width: 32, height: 32)
                    .background(Color.white)
                    .clipShape(Circle())
                    .shadow(color: .black.opacity(0.1), radius: 2, x: 0, y: 1)

                // Language name
                VStack(alignment: .leading, spacing: 2) {
                    Text(language.name)
                        .font(.body)
                        .foregroundColor(.black)
                    if isCurrent {
                        Text("current_language_badge".localizedWithCurrentLanguage)
                            .font(.caption)
                            .foregroundColor(.gray)
                    }
                }

                Spacer()

                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.title3)
                        .foregroundColor(.green)
                }
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 16)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.white)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(
                                isSelected
                                ? LinearGradient(
                                    gradient: Gradient(colors: [Color.orange, Color.pink]),
                                    startPoint: .leading,
                                    endPoint: .trailing
                                  )
                                : LinearGradient(
                                    gradient: Gradient(colors: [Color.clear]),
                                    startPoint: .leading,
                                    endPoint: .trailing
                                  ),
                                lineWidth: isSelected ? 2 : 0
                            )
                    )
                    .shadow(color: .black.opacity(0.05), radius: 4, x: 0, y: 2)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }

    // MARK: - Apply
    private func applySelectedLanguage() {
        guard let selected = selectedLanguage else { return }
        Logger.d("Apply selected language: \(selected)")
        languageManager.setLanguage(code: selected.code)      // Cập nhật LanguageManager → đổi .locale toàn app
        onLanguageSelected(selected)               // Callback cho parent nếu cần
        // Haptics nhẹ
        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
        userDefaultsManager.setLanguageSelected(selected)
        // Đóng màn hình sau khi chọn ngôn ngữ
        dismiss()
    }

    // MARK: - Canonicalize helper (khớp chuẩn iOS)
    private func canonical(_ raw: String) -> String {
        // giống logic trong LanguageManager.canonicalCode(_:)
        switch raw.lowercased() {
        case "pt", "pt-pt": return "pt-PT"
        case "pt-br":       return "pt-BR"
        case "zh", "zh-hans": return "zh-Hans"
        case "zh-hant":       return "zh-Hant"
        case "en-gb":       return "en-GB"
        case "en-us":       return "en-US"
        case "es-mx":       return "es-MX"
        default:
            var parts = raw.split(separator: "-").map(String.init)
            if parts.count == 2 { parts[1] = parts[1].uppercased() }
            return parts.joined(separator: parts.count == 2 ? "-" : "")
        }
    }
}

#Preview {
    SelectLanguageScreen { language in
        print("Selected language: \(language.name)")
    }
    .environmentObject(LanguageManager.shared)
}
