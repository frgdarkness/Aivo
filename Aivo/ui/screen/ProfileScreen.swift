//
//  ProfileScreen.swift
//  Aivo
//
//  Created by AI Assistant
//

import SwiftUI
import StoreKit
import MessageUI
import UIKit
import PhotosUI

struct ProfileScreen: View {
    @Binding var isPresented: Bool
    @ObservedObject private var creditManager = CreditManager.shared
    @ObservedObject private var subscriptionManager = SubscriptionManager.shared
    @StateObject private var localStorage = LocalStorageManager.shared
    @StateObject private var remoteConfig = RemoteConfigManager.shared
    
    @State private var showLanguageScreen = false
    @State private var showCreditHistory = false
    @State private var showFAQ = false
    @State private var notificationsEnabled = false
    @State private var showMailComposer = false
    @State private var canSendMail = false
    @State private var showUserNameEditor = false
    @State private var editingUserName = ""
    @State private var showImagePicker = false
    @State private var showToastMessage = false
    @State private var toastMessageText = ""
    
    private var profile: UserProfile {
        localStorage.getLocalProfile()
    }
    
    private var profileID: String {
        profile.profileID
    }
    
    
    private var userName: String {
        profile.userName
    }
    
    private var avatarImageName: String {
        profile.avatarImageName
    }
    
    private var appVersion: String {
        Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0.0"
    }
    
    private var memberName: String {
        guard subscriptionManager.isPremium else {
            return "Basic Member"
        }
        
        if let subscription = subscriptionManager.currentSubscription {
            switch subscription.period {
            case .weekly:
                return "AIVO Premium Weekly"
            case .yearly:
                return "AIVO Premium Yearly"
            }
        }
        
        // Fallback dựa vào subscriptionPeriod từ localStorage
        if let period = localStorage.subscriptionPeriod {
            switch period {
            case .weekly:
                return "AIVO Premium Weekly"
            case .yearly:
                return "AIVO Premium Yearly"
            }
        }
        
        return "Basic Member"
    }
    
    private var memberIconColor: Color {
        subscriptionManager.isPremium
            ? Color(red: 1.0, green: 0.25, blue: 0.05).opacity(0.9)
            : Color.white.opacity(0.7)
    }
    
    var body: some View {
        ZStack {
            // Background
            AivoSunsetBackground()
            
            VStack(spacing: 0) {
                // Header
                headerView
                
                ScrollView {
                    VStack(spacing: 20) {
                        // Profile Header Section
                        profileHeaderSection
                        
                        // Membership & Credit Card
                        membershipCard
                        
                        // Menu Items
                        menuItemsSection
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 20)
                    .padding(.bottom, 40)
                }
            }
        }
        .onAppear {
            checkMailAvailability()
            editingUserName = userName
        }
        .sheet(isPresented: $showLanguageScreen) {
            SelectLanguageScreen { _ in
                // Language selected callback
            }
            .environmentObject(LanguageManager.shared)
        }
        .sheet(isPresented: $showMailComposer) {
            if canSendMail {
                MailComposeView(recipient: remoteConfig.adminEmail)
            }
        }
        .sheet(isPresented: $showImagePicker) {
            ImagePickerView(onImageSelected: { image in
                Task {
                    await saveSelectedImage(image)
                }
            })
        }
        .overlay(
            // Toast message
            VStack {
                Spacer()
                if showToastMessage {
                    Text(toastMessageText)
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.white)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 12)
                        .background(Color.black.opacity(0.8))
                        .cornerRadius(8)
                        .padding(.bottom, 100)
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                        .animation(.easeInOut(duration: 0.3), value: showToastMessage)
                }
            }
        )
        .overlay(
            // Edit Name Dialog
            Group {
                if showUserNameEditor {
                    EditNameDialog(
                        currentName: userName,
                        onSave: { newName in
                            editingUserName = newName
                            saveUserName()
                            showUserNameEditor = false
                        },
                        onCancel: {
                            showUserNameEditor = false
                        }
                    )
                    .transition(.opacity.combined(with: .scale(scale: 0.9)))
                    .animation(.easeInOut(duration: 0.2), value: showUserNameEditor)
                }
            }
        )
        .fullScreenCover(isPresented: $showCreditHistory) {
            CreditUsageHistoryScreen()
        }
    }
    
    // MARK: - Header View
    private var headerView: some View {
        HStack {
            Button(action: {
                withAnimation(.easeInOut(duration: 0.3)) {
                    isPresented = false
                }
            }) {
                Image(systemName: "chevron.left")
                    .font(.title2)
                    .foregroundColor(.white)
            }
            
            Spacer()
            
            Text("Profile")
                .font(.system(size: 20, weight: .bold))
                .foregroundColor(.white)
            
            Spacer()
            
            // Spacer để cân bằng với back button
            Spacer()
                .frame(width: 32, height: 32)
        }
        .padding(.horizontal, 20)
        .padding(.top, 10)
        .padding(.bottom, 20)
    }
    
    // MARK: - Profile Header Section
    private var profileHeaderSection: some View {
        HStack(alignment: .center, spacing: 16) {
            // Left side: User Name and ID
            VStack(alignment: .leading, spacing: 12) {
                // User Name Row
                HStack(spacing: 8) {
                    Text(userName)
                        .font(.system(size: 20, weight: .bold))
                        .foregroundColor(.white)
                    
                    Button(action: {
                        editingUserName = userName
                        showUserNameEditor = true
                    }) {
                        Image(systemName: "pencil")
                            .font(.system(size: 14))
                            .foregroundColor(.gray)
                    }
                }
                
                // ID Badge - giống design: label trắng, giá trị xám nhạt
                HStack(spacing: 0) {
                    // "ID" label với background trắng
                    Text("ID")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.black)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 6)
                        .background(Color.white)
                        .clipShape(RoundedCorner(radius: 6, corners: [.topLeft, .bottomLeft]))
                    
                    // ID value với background xám nhạt
                    Text(profileID.prefix(20))
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.white)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 6)
                        .background(Color(white: 0.4))
                        .clipShape(RoundedCorner(radius: 6, corners: [.topRight, .bottomRight]))
                    
                    // Copy button
                    Button(action: {
                        copyIDToClipboard()
                    }) {
                        Image(systemName: "doc.on.doc")
                            .font(.system(size: 12))
                            .foregroundColor(.gray)
                            .padding(6)
                    }
                    .padding(.leading, 4)
                }
            }
            
            Spacer()
            
            // Avatar with edit icon
            ZStack(alignment: .bottomTrailing) {
                // Avatar image
                Group {
                    if avatarImageName.hasPrefix("avatar_") {
                        // Load from Documents directory
                        if let image = loadAvatarFromDocuments(imageName: avatarImageName) {
                            Image(uiImage: image)
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                        } else {
                            Image("demo_cover")
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                        }
                    } else {
                        // Load from Assets
                        Image(avatarImageName)
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                    }
                }
                .frame(width: 80, height: 80)
                .clipShape(Circle())
                .overlay(
                    Circle()
                        .stroke(Color.white.opacity(0.3), lineWidth: 2)
                )
                
                // Edit icon
                Button(action: {
                    showImagePicker = true
                }) {
                    Image(systemName: "pencil")
                        .font(.system(size: 10))
                        .foregroundColor(.gray)
                        .frame(width: 24, height: 24)
                        .background(Color.gray.opacity(0.3))
                        .clipShape(Circle())
                }
                .offset(x: 4, y: 4)
            }
        }
        .padding(.top, 10)
    }
    
    // MARK: - Membership Card
    private var membershipCard: some View {
        VStack(spacing: 12) {
            // Membership Row - VIP icon và tên gói bên phải
            HStack {
                // VIP Button icon giống HomeView
                HStack(spacing: 4) {
                    Image(systemName: "crown.fill")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(subscriptionManager.isPremium ? .white : .white.opacity(0.7))
                    Text(memberName)
                        .font(.system(size: 16, weight: .medium))
                        .fontWeight(.semibold)
                        .foregroundColor(subscriptionManager.isPremium ? .white : .white.opacity(0.7))
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 8)
                // NỀN: chỉ có khi VIP
                .background(
                    Group {
                        if subscriptionManager.isPremium {
                            LinearGradient(
                                gradient: Gradient(colors: [
                                    Color(red: 1.0, green: 0.08, blue: 0.05),  // đỏ hơi pha cam
                                    Color(red: 1.0, green: 0.25, blue: 0.05),  // đỏ-cam
                                    Color(red: 1.0, green: 0.45, blue: 0.1) 
                                ]),
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                            .clipShape(Capsule())
                        } else {
                            Color.clear.clipShape(Capsule())
                        }
                    }
                )
                // VIỀN: VIP viền đỏ-cam; Non-VIP viền trắng mờ, không nền
                .overlay(
                    Capsule().stroke(
                        subscriptionManager.isPremium
                        ? Color(red: 1.0, green: 0.25, blue: 0.05).opacity(0.9)
                        : Color.white.opacity(0.5),
                        lineWidth: 1
                    )
                )
                // Bóng nhẹ chỉ khi VIP để nổi bật
                .shadow(color: subscriptionManager.isPremium ? Color(red: 1.0, green: 0.2, blue: 0.05).opacity(0.45) : .clear,
                        radius: 8, x: 0, y: 3)
                
                // Tên gói member bên phải icon
//                Text(memberName)
//                    .font(.system(size: 16, weight: .medium))
//                    .foregroundColor(.white)
                
                Spacer()
                
//                Button(action: {
//                    // Show membership info
//                }) {
//                    Image(systemName: "info.circle")
//                        .font(.system(size: 14))
//                        .foregroundColor(.gray)
//                }
            }
            
            // Credit Row - Layer riêng mờ hơn
            HStack {
//                Image("icon_coin")
//                    .resizable()
//                    .aspectRatio(contentMode: .fit)
//                    .frame(width: 16, height: 16)
                
                Text("Credit")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.white)
                
                Spacer()
                
                Text("\(creditManager.credits)")
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundColor(Color(red: 1.0, green: 0.85, blue: 0.4))
                
                Image("icon_coin")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 18, height: 18)
//                Button(action: {
//                    // Add credit action - có thể mở subscription screen
//                }) {
//                    Image(systemName: "plus.circle.fill")
//                        .font(.system(size: 18))
//                        .foregroundColor(Color(red: 1.0, green: 0.85, blue: 0.4))
//                }
            }
            .padding(16)
            .background(Color.gray.opacity(0.25))
            .cornerRadius(12)
        }
        .padding(16)
        .background(Color.gray.opacity(0.15))
        .cornerRadius(12)
    }
    
    // MARK: - Menu Items Section
    private var menuItemsSection: some View {
        VStack(spacing: 12) {
            // Credit Usage History
            menuRow(
                icon: "clock.arrow.circlepath",
                title: "Credit Usage History",
                showArrow: true,
                action: { showCreditHistory = true }
            )
            
            // Contact
            menuRow(
                icon: "envelope",
                title: "Contact",
                showArrow: true,
                action: {
                    if canSendMail {
                        showMailComposer = true
                    } else {
                        // Fallback: mở mail app với email
                        openMailApp()
                    }
                }
            )
            
            // Notifications (Toggle)
            menuRowWithToggle(
                icon: "bell",
                title: "Notifications",
                isOn: $notificationsEnabled
            )
            
            // Language
//            menuRow(
//                icon: "globe",
//                title: "Language",
//                showArrow: true,
//                action: { showLanguageScreen = true }
//            )
            
            // FAQ
            menuRow(
                icon: "questionmark.square",
                title: "FAQ",
                showArrow: true,
                action: { showFAQ = true }
            )
            
            // Rate Us
            menuRow(
                icon: "star.fill",
                title: "Rate Us",
                showArrow: true,
                action: { requestReview() }
            )
            
            // Version
            menuRow(
                icon: "arrow.triangle.2.circlepath",
                title: "Version",
                value: appVersion,
                showArrow: false
            )
        }
    }
    
    
    // MARK: - Menu Row
    private func menuRow(
        icon: String,
        title: String,
        value: String? = nil,
        showArrow: Bool = true,
        action: (() -> Void)? = nil
    ) -> some View {
        Button(action: {
            action?()
        }) {
            HStack(spacing: 16) {
                Image(systemName: icon)
                    .font(.system(size: 20))
                    .foregroundColor(.white)
                    .frame(width: 24, height: 24)
                
                Text(title)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.white)
                
                Spacer()
                
                if let value = value {
                    Text(value)
                        .font(.system(size: 16))
                        .foregroundColor(.gray)
                }
                
                if showArrow {
                    Image(systemName: "chevron.right")
                        .font(.system(size: 12))
                        .foregroundColor(.gray)
                }
            }
            .padding(.vertical, 12)
            .padding(.horizontal, 16)
            .background(Color.gray.opacity(0.1))
            .cornerRadius(8)
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    // MARK: - Menu Row with Toggle
    private func menuRowWithToggle(
        icon: String,
        title: String,
        isOn: Binding<Bool>
    ) -> some View {
        HStack(spacing: 16) {
            Image(systemName: icon)
                .font(.system(size: 20))
                .foregroundColor(.white)
                .frame(width: 24, height: 24)
            
            Text(title)
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(.white)
            
            Spacer()
            
            Toggle("", isOn: isOn)
                .tint(Color(red: 1.0, green: 0.85, blue: 0.4))
        }
        .padding(.vertical, 12)
        .padding(.horizontal, 16)
        .background(Color.gray.opacity(0.1))
        .cornerRadius(8)
    }
    
    // MARK: - Helper Methods
    private func copyIDToClipboard() {
        UIPasteboard.general.string = profileID
        // Show toast notification
        showToast(message: "ID copied to clipboard")
    }
    
    private func showToast(message: String) {
        toastMessageText = message
        showToastMessage = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            showToastMessage = false
        }
    }
    
    private func checkMailAvailability() {
        canSendMail = MFMailComposeViewController.canSendMail()
    }
    
    private func openMailApp() {
        if let emailURL = URL(string: "mailto:\(remoteConfig.adminEmail)") {
            UIApplication.shared.open(emailURL)
        }
    }
    
    private func requestReview() {
        if let scene = UIApplication.shared.connectedScenes.first as? UIWindowScene {
            SKStoreReviewController.requestReview(in: scene)
        }
    }
    
    private func saveUserName() {
        var profile = localStorage.getLocalProfile()
        profile.updateUserName(editingUserName)
        localStorage.updateLocalProfile(profile)
    }
    
    private func loadAvatarFromDocuments(imageName: String) -> UIImage? {
        guard let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first else {
            return nil
        }
        
        let fileURL = documentsDirectory.appendingPathComponent(imageName)
        
        guard FileManager.default.fileExists(atPath: fileURL.path),
              let imageData = try? Data(contentsOf: fileURL),
              let image = UIImage(data: imageData) else {
            return nil
        }
        
        return image
    }
    
    @MainActor
    private func saveSelectedImage(_ image: UIImage) async {
        // Save image to Documents directory
        guard let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first else {
            return
        }
        
        let fileName = "avatar_\(profileID).jpg"
        let fileURL = documentsDirectory.appendingPathComponent(fileName)
        
        guard let imageData = image.jpegData(compressionQuality: 0.8) else {
            return
        }
        
        do {
            try imageData.write(to: fileURL)
            
            // Update profile with new avatar image name
            var profile = localStorage.getLocalProfile()
            profile.updateAvatarImageName(fileName)
            localStorage.updateLocalProfile(profile)
        } catch {
            Logger.e("Failed to save avatar image: \(error)")
        }
    }
}

// MARK: - Image Picker View (iOS 15+ compatible)
struct ImagePickerView: UIViewControllerRepresentable {
    let onImageSelected: (UIImage) -> Void
    @Environment(\.dismiss) private var dismiss
    
    func makeUIViewController(context: Context) -> PHPickerViewController {
        var configuration = PHPickerConfiguration()
        configuration.filter = .images
        configuration.selectionLimit = 1
        
        let picker = PHPickerViewController(configuration: configuration)
        picker.delegate = context.coordinator
        return picker
    }
    
    func updateUIViewController(_ uiViewController: PHPickerViewController, context: Context) {}
    
    func makeCoordinator() -> Coordinator {
        Coordinator(onImageSelected: onImageSelected, dismiss: { dismiss() })
    }
    
    class Coordinator: NSObject, PHPickerViewControllerDelegate {
        let onImageSelected: (UIImage) -> Void
        let dismiss: () -> Void
        
        init(onImageSelected: @escaping (UIImage) -> Void, dismiss: @escaping () -> Void) {
            self.onImageSelected = onImageSelected
            self.dismiss = dismiss
        }
        
        func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
            dismiss()
            
            guard let result = results.first else { return }
            
            result.itemProvider.loadObject(ofClass: UIImage.self) { [weak self] object, error in
                guard let self = self else { return }
                
                if let error = error {
                    Logger.e("Failed to load image: \(error.localizedDescription)")
                    return
                }
                
                if let image = object as? UIImage {
                    DispatchQueue.main.async {
                        self.onImageSelected(image)
                    }
                }
            }
        }
    }
}

// MARK: - Edit Name Dialog
struct EditNameDialog: View {
    let currentName: String
    let onSave: (String) -> Void
    let onCancel: () -> Void
    
    @State private var editedName: String
    @FocusState private var isTextFieldFocused: Bool
    
    init(currentName: String, onSave: @escaping (String) -> Void, onCancel: @escaping () -> Void) {
        self.currentName = currentName
        self.onSave = onSave
        self.onCancel = onCancel
        self._editedName = State(initialValue: currentName)
    }
    
    var body: some View {
        ZStack {
            // Background overlay
            Color.black.opacity(0.6)
                .ignoresSafeArea()
                .onTapGesture {
                    onCancel()
                }
            
            // Dialog Content
            VStack(spacing: 20) {
                // Title
                Text("Edit Name")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(.white)
                
                // TextField
                TextField("Your name", text: $editedName)
                    .font(.system(size: 16))
                    .foregroundColor(.white)
                    .padding(14)
                    .background(
                        RoundedRectangle(cornerRadius: 10)
                            .fill(Color.white.opacity(0.15))
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 10)
                            .stroke(Color.white.opacity(0.2), lineWidth: 1)
                    )
                    .focused($isTextFieldFocused)
                    .onAppear {
                        isTextFieldFocused = true
                    }
                
                // Buttons
                HStack(spacing: 12) {
                    // Cancel Button
                    Button(action: onCancel) {
                        Text("Cancel")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                            .background(Color.gray.opacity(0.3))
                            .cornerRadius(10)
                    }
                    
                    // Save Button
                    Button(action: {
                        onSave(editedName)
                    }) {
                        Text("Save")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                            .background(
                                LinearGradient(
                                    gradient: Gradient(colors: [
                                        Color(red: 1.0, green: 0.5, blue: 0.0),
                                        Color(red: 1.0, green: 0.7, blue: 0.2)
                                    ]),
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .cornerRadius(10)
                    }
                }
            }
            .padding(24)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color.black)
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .fill(Color.white.opacity(0.1))
                    )
            )
            .frame(maxWidth: 320)
            .padding(.horizontal, 40)
        }
    }
}

// MARK: - Mail Compose View
struct MailComposeView: UIViewControllerRepresentable {
    let recipient: String
    
    func makeUIViewController(context: Context) -> MFMailComposeViewController {
        let composer = MFMailComposeViewController()
        composer.mailComposeDelegate = context.coordinator
        composer.setToRecipients([recipient])
        composer.setSubject("Aivo App - Contact")
        return composer
    }
    
    func updateUIViewController(_ uiViewController: MFMailComposeViewController, context: Context) {}
    
    func makeCoordinator() -> Coordinator {
        Coordinator()
    }
    
    class Coordinator: NSObject, MFMailComposeViewControllerDelegate {
        func mailComposeController(_ controller: MFMailComposeViewController, didFinishWith result: MFMailComposeResult, error: Error?) {
            controller.dismiss(animated: true)
        }
    }
}

#Preview {
    ProfileScreen(isPresented: .constant(true))
}
