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
    @State private var notificationsEnabled = false
    @State private var showMailComposer = false
    @State private var canSendMail = false
    @State private var showEditNameDialog = false
    @State private var editingUserName = ""
    @State private var showImagePicker = false
    @State private var showToastMessage = false
    @State private var toastMessageText = ""
    @State private var showBuyCreditDialog = false
    @State private var showPremiumRequiredAlert = false
    @State private var showSubscriptionScreen = false
    @State private var isUploadingAvatar = false
    #if DEBUG
    @State private var showTestScreen = false
    #endif
    
    private var profile: UserProfile {
        localStorage.getLocalProfile()
    }
    
    private var profileID: String {
        profile.profileID
    }
    
    
    private var userName: String {
        profile.userName
    }
    
    private var avatarUrl: String {
        profile.avatarUrl
    }
    
    private var appVersion: String {
        Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0.0"
    }
    
    private var memberName: String {
        guard subscriptionManager.isPremium else {
            return "Basic"
        }
        
        if let subscription = subscriptionManager.currentSubscription {
            switch subscription.period {
            case .weekly:
                return "Weekly Premium"
            case .yearly:
                return "Yearly Premium"
            }
        }
        
        // Fallback dựa vào subscriptionPeriod từ localStorage
        if let period = localStorage.subscriptionPeriod {
            switch period {
            case .weekly:
                return "Weekly Premium"
            case .yearly:
                return "Yearly Premium"
            }
        }
        
        return "Basic"
    }
    
    private var memberIconColor: Color {
        subscriptionManager.isPremium
            ? Color(red: 1.0, green: 0.25, blue: 0.05).opacity(0.9)
            : Color.white.opacity(0.7)
    }

    var body: some View {
        ZStack {
            // ... (existing content)
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
             // ...
             AnalyticsLogger.shared.logScreenView(AnalyticsLogger.EVENT.EVENT_SCREEN_PROFILE)
             checkMailAvailability()
             editingUserName = userName
        }
        .fullScreenCover(isPresented: $showSubscriptionScreen) {
            SubscriptionView()
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
                if showEditNameDialog {
                    UsernameRequiredDialog(
                        title: "Change Your Username",
                        onSave: { newName in
                            saveUserName(newName)
                            showEditNameDialog = false
                        },
                        onDismiss: {
                            showEditNameDialog = false
                        }
                    )
                    .transition(.opacity.combined(with: .scale(scale: 0.9)))
                    .animation(.easeInOut(duration: 0.2), value: showEditNameDialog)
                }
            }
        )
        .fullScreenCover(isPresented: $showCreditHistory) {
            CreditUsageHistoryScreen()
        }
        #if DEBUG
        .fullScreenCover(isPresented: $showTestScreen) {
            TestScreen()
        }
        #endif
        .buyCreditDialog(isPresented: $showBuyCreditDialog)
        .alert("Premium Required", isPresented: $showPremiumRequiredAlert) {
            Button("OK", role: .cancel) { }
        } message: {
            Text("Only support for Premium Member")
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
                    .font(.system(size: iPadScale(22)))
                    .foregroundColor(.white)
            }
            
            Spacer()
            
            Text("Profile")
                .font(.system(size: iPadScale(20), weight: .bold))
                .foregroundColor(.white)
            
            Spacer()
            
            // Spacer để cân bằng với back button
            Spacer()
                .frame(width: iPadScale(32), height: iPadScale(32))
        }
        .padding(.horizontal, 20)
        .padding(.top, 10)
        .padding(.bottom, 20)
    }
    
    // MARK: - Profile Header Section
    private var profileHeaderSection: some View {
        HStack(alignment: .center, spacing: iPadScaleSmall(16)) {
            // Left side: User Name and ID
            VStack(alignment: .leading, spacing: iPadScaleSmall(12)) {
                // User Name Row
                HStack(spacing: 8) {
                    Text(userName)
                        .font(.system(size: iPadScale(20), weight: .bold))
                        .foregroundColor(.white)
                    
                    Button(action: {
                        editingUserName = userName
                        showEditNameDialog = true
                    }) {
                        Image(systemName: "pencil")
                            .font(.system(size: iPadScale(14)))
                            .foregroundColor(.gray)
                    }
                }
                
                // ID Badge
                HStack(spacing: 0) {
                    Text("ID")
                        .font(.system(size: iPadScale(14), weight: .medium))
                        .foregroundColor(.black)
                        .padding(.horizontal, iPadScaleSmall(8))
                        .padding(.vertical, iPadScaleSmall(6))
                        .background(Color.white)
                        .clipShape(RoundedCorner(radius: 6, corners: [.topLeft, .bottomLeft]))
                    
                    Text(profileID.prefix(20))
                        .font(.system(size: iPadScale(14), weight: .medium))
                        .foregroundColor(.white)
                        .padding(.horizontal, iPadScaleSmall(8))
                        .padding(.vertical, iPadScaleSmall(6))
                        .background(Color(white: 0.4))
                        .clipShape(RoundedCorner(radius: 6, corners: [.topRight, .bottomRight]))
                    
                    Button(action: {
                        copyIDToClipboard()
                    }) {
                        Image(systemName: "doc.on.doc")
                            .font(.system(size: iPadScale(12)))
                            .foregroundColor(.gray)
                            .padding(iPadScaleSmall(6))
                    }
                    .padding(.leading, 4)
                }
            }
            
            Spacer()
            
            // Avatar with edit icon
            ZStack(alignment: .bottomTrailing) {
                Group {
                    if avatarUrl.hasPrefix("avatar_") {
                        if let image = loadAvatarFromDocuments(imageName: avatarUrl) {
                            Image(uiImage: image)
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                        } else {
                            Image("demo_cover")
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                        }
                    } else if let url = URL(string: avatarUrl), avatarUrl.hasPrefix("http") {
                        AsyncImage(url: url) { phase in
                            switch phase {
                            case .success(let image):
                                image.resizable().aspectRatio(contentMode: .fill)
                            default:
                                Image("demo_cover").resizable().aspectRatio(contentMode: .fill)
                            }
                        }
                    } else {
                        let imageName = avatarUrl.isEmpty ? "demo_cover" : avatarUrl
                        Image(imageName)
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                    }
                }
                .frame(width: iPadScale(80), height: iPadScale(80))
                .clipShape(Circle())
                .overlay(
                    Circle()
                        .stroke(Color.white.opacity(0.3), lineWidth: 2)
                )
                
                Button(action: {
                    showImagePicker = true
                }) {
                    Image(systemName: "pencil")
                        .font(.system(size: iPadScale(10)))
                        .foregroundColor(.gray)
                        .frame(width: iPadScale(24), height: iPadScale(24))
                        .background(Color.gray.opacity(0.3))
                        .clipShape(Circle())
                }
                .offset(x: 4, y: 4)
                .disabled(isUploadingAvatar)
            }
        }
        .padding(.top, 10)
    }
    
    // MARK: - Membership Card
    private var membershipCard: some View {
        VStack(spacing: iPadScaleSmall(12)) {
            // Membership Row
            Button(action: {
                showSubscriptionScreen = true
            }) {
                premiumBadgeRow
            }
            .buttonStyle(PlainButtonStyle())
            
            // Credit Row
            VStack(spacing: iPadScaleSmall(8)) {
                // Credit count row
                HStack {
                    Image("icon_coin")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: iPadScale(18), height: iPadScale(18))
                    
                    Text("Credit")
                        .font(.system(size: iPadScale(16), weight: .medium))
                        .foregroundColor(.white)
                    
                    Spacer()
                    
                    Text("\(creditManager.credits)")
                        .font(.system(size: iPadScale(20), weight: .semibold))
                        .foregroundColor(Color(red: 1.0, green: 0.85, blue: 0.4))
                    
                    // Add credit button
                    Button(action: {
                        if subscriptionManager.isPremium {
                            showBuyCreditDialog = true
                        } else {
                            showPremiumRequiredAlert = true
                        }
                    }) {
                        Image(systemName: "plus.circle.fill")
                            .font(.system(size: iPadScale(20), weight: .semibold))
                            .foregroundColor(AivoTheme.Primary.orange)
                    }
                    .padding(.leading, 0)
                }
                
                // Next Bonus Date for Premium Users
                if subscriptionManager.isPremium, let nextBonus = subscriptionManager.getNextBonusDate() {
                    Rectangle()
                        .fill(Color.white.opacity(0.1))
                        .frame(height: 1)
                        .padding(.vertical, 4)
                        
                    HStack {
                        Text("Next bonus date")
                            .font(.system(size: iPadScale(14), weight: .regular))
                            .foregroundColor(.white.opacity(0.7))
                        Spacer()
                        Text(formatDate(nextBonus))
                            .font(.system(size: iPadScale(14), weight: .medium))
                            .foregroundColor(AivoTheme.Secondary.goldenSun)
                    }
                }
            }
            .padding(iPadScaleSmall(12))
            .background(Color.gray.opacity(0.25))
            .cornerRadius(iPadScale(12))
            .opacity(subscriptionManager.isPremium ? 1.0 : 0.8)
        }
        .padding(iPadScaleSmall(16))
        .background(Color.gray.opacity(0.15))
        .cornerRadius(iPadScale(12))
    }
    
    // MARK: - Premium Badge Row
    private var premiumBadgeRow: some View {
        HStack {
            Button(action: {
                showSubscriptionScreen = true
            }) {
                HStack(spacing: iPadScaleSmall(8)) {
                    Image(systemName: "crown.fill")
                        .font(.system(size: iPadScale(14), weight: .semibold))
                        .foregroundColor(subscriptionManager.isPremium ? .white : .white.opacity(0.7))
                        .frame(width: iPadScale(32), height: iPadScale(32))
                        .background(
                            Group {
                                if subscriptionManager.isPremium {
                                    LinearGradient(
                                        gradient: Gradient(colors: [
                                            Color(red: 1.0, green: 0.08, blue: 0.05),
                                            Color(red: 1.0, green: 0.25, blue: 0.05),
                                            Color(red: 1.0, green: 0.45, blue: 0.1)
                                        ]),
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                } else {
                                    Color.gray.opacity(0.3)
                                }
                            }
                        )
                        .clipShape(Circle())
                        .overlay(
                            Circle().stroke(
                                subscriptionManager.isPremium
                                ? Color(red: 1.0, green: 0.25, blue: 0.05).opacity(0.9)
                                : Color.white.opacity(0.5),
                                lineWidth: 1
                            )
                        )
                        .shadow(color: subscriptionManager.isPremium ? Color(red: 1.0, green: 0.2, blue: 0.05).opacity(0.45) : .clear,
                                radius: 8, x: 0, y: 3)
                    
                    Text(memberName)
                        .font(.system(size: iPadScale(16), weight: .bold))
                        .foregroundColor(subscriptionManager.isPremium ? Color(red: 1.0, green: 0.4, blue: 0.1) : .white)
                }
            }
            
            Spacer()
        }
    }
    
    // Helper function to format date
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        return formatter.string(from: date)
    }
    
    // MARK: - Menu Items Section
    private var menuItemsSection: some View {
        VStack(spacing: 20) {
            // Card 1: Usage History
            VStack(spacing: 0) {
                menuRow(
                    icon: "clock.arrow.circlepath",
                    title: "Credit Usage History",
                    showArrow: true,
                    action: { showCreditHistory = true }
                )
            }
            .background(Color.white.opacity(0.06))
            .cornerRadius(iPadScale(16))
            .overlay(RoundedRectangle(cornerRadius: iPadScale(16)).stroke(Color.white.opacity(0.1), lineWidth: 1))
            
            // Card 2: Notifications & Auto Share
            VStack(spacing: 0) {
                menuRowWithToggle(
                    icon: "bell.fill",
                    title: "Notifications",
                    isOn: $notificationsEnabled
                )
                
                Divider().background(Color.white.opacity(0.1)).padding(.horizontal, 16)
                
                menuRowWithToggle(
                    icon: "arrow.2.squarepath",
                    title: "Auto Share Song",
                    isOn: Binding(
                        get: { LocalStorageManager.shared.autoShareEnabled },
                        set: { LocalStorageManager.shared.setAutoShareEnabled($0) }
                    )
                )
            }
            .background(Color.white.opacity(0.06))
            .cornerRadius(iPadScale(16))
            .overlay(RoundedRectangle(cornerRadius: iPadScale(16)).stroke(Color.white.opacity(0.1), lineWidth: 1))
            
            // Card 3: Support & Feedback
            VStack(spacing: 0) {
                menuRow(
                    icon: "envelope.fill",
                    title: "Contact",
                    showArrow: true,
                    action: {
                        if canSendMail {
                            showMailComposer = true
                        } else {
                            openMailApp()
                        }
                    }
                )
                
                Divider().background(Color.white.opacity(0.1)).padding(.horizontal, 16)
                
                menuRow(
                    icon: "star.fill",
                    title: "Rate Us",
                    showArrow: true,
                    action: { AppRatingManager.shared.forceShowRateApp() }
                )
            }
            .background(Color.white.opacity(0.06))
            .cornerRadius(iPadScale(16))
            .overlay(RoundedRectangle(cornerRadius: iPadScale(16)).stroke(Color.white.opacity(0.1), lineWidth: 1))
            
            #if DEBUG
            // Debug card
            VStack(spacing: 0) {
                menuRow(
                    icon: "wrench.and.screwdriver.fill",
                    title: "Test Screen",
                    showArrow: true,
                    action: { showTestScreen = true }
                )
                
                Divider().background(Color.white.opacity(0.1)).padding(.horizontal, 16)
                
                menuRow(
                    icon: "exclamationmark.triangle.fill",
                    title: "Test Crashlytics",
                    showArrow: false,
                    action: { fatalError("Crashlytics Test Crash") }
                )
            }
            .background(Color.white.opacity(0.06))
            .cornerRadius(iPadScale(16))
            .overlay(RoundedRectangle(cornerRadius: iPadScale(16)).stroke(Color.white.opacity(0.1), lineWidth: 1))
            #endif
            
            // Card 4: App Info
            VStack(spacing: 0) {
                menuRow(
                    icon: "info.circle.fill",
                    title: "Version",
                    value: appVersion,
                    showArrow: false
                )
            }
            .background(Color.white.opacity(0.06))
            .cornerRadius(iPadScale(16))
            .overlay(RoundedRectangle(cornerRadius: iPadScale(16)).stroke(Color.white.opacity(0.1), lineWidth: 1))
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
            HStack(spacing: iPadScaleSmall(16)) {
                Image(systemName: icon)
                    .font(.system(size: iPadScale(20)))
                    .foregroundColor(.white)
                    .frame(width: iPadScale(24), height: iPadScale(24))
                
                Text(title)
                    .font(.system(size: iPadScale(16), weight: .medium))
                    .foregroundColor(.white)
                
                Spacer()
                
                if let value = value {
                    Text(value)
                        .font(.system(size: iPadScale(16)))
                        .foregroundColor(.gray)
                }
                
                if showArrow {
                    Image(systemName: "chevron.right")
                        .font(.system(size: iPadScale(12)))
                        .foregroundColor(.gray)
                }
            }
            .padding(.vertical, iPadScaleSmall(14))
            .padding(.horizontal, iPadScaleSmall(16))
            .contentShape(Rectangle())
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    // MARK: - Menu Row with Toggle
    private func menuRowWithToggle(
        icon: String,
        title: String,
        isOn: Binding<Bool>
    ) -> some View {
        HStack(spacing: iPadScaleSmall(16)) {
            Image(systemName: icon)
                .font(.system(size: iPadScale(20)))
                .foregroundColor(.white)
                .frame(width: iPadScale(24), height: iPadScale(24))
            
            Text(title)
                .font(.system(size: iPadScale(16), weight: .medium))
                .foregroundColor(.white)
            
            Spacer()
            
            Toggle("", isOn: isOn)
                .tint(AivoTheme.Primary.orange)
        }
        .padding(.vertical, iPadScaleSmall(14))
        .padding(.horizontal, iPadScaleSmall(16))
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
    
    private func openFAQUrl() {
        if let url = URL(string: remoteConfig.supportUrl) {
            UIApplication.shared.open(url)
        } else {
            Logger.e("Invalid FAQ URL: \(remoteConfig.supportUrl)")
        }
    }
    
    private func requestReview() {
        if let scene = UIApplication.shared.connectedScenes.first as? UIWindowScene {
            SKStoreReviewController.requestReview(in: scene)
        }
    }
    
    private func saveUserName(_ newName: String) {
        guard !newName.isEmpty else { return }
        
        let oldName = localStorage.getLocalProfile().userName
        
        Task {
            do {
                // 1. Update in Firestore (claims new, releases old atomically)
                try await FirestoreService.shared.updateUsername(profileID: profileID, newUsername: newName, oldUsername: oldName)
                
                // 2. Update local profile
                await MainActor.run {
                    var profile = localStorage.getLocalProfile()
                    profile.updateUserName(newName)
                    localStorage.updateLocalProfile(profile)
                    
                    showEditNameDialog = false
                    showToast(message: "Username updated successfully")
                }
            } catch {
                Logger.e("❌ Failed to update username: \(error.localizedDescription)")
                await MainActor.run {
                    showToast(message: "Error: \(error.localizedDescription)")
                }
            }
        }
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
        guard !isUploadingAvatar else { return }
        
        isUploadingAvatar = true
        
        // Resize image to 256x256 for optimal avatar size
        let optimizedSize = CGSize(width: 256, height: 256)
        let resizedImage = image.resized(to: optimizedSize) ?? image
        
        // Use high compression (0.5 for small size but still decent quality)
        guard let imageData = resizedImage.jpegData(compressionQuality: 0.5) else {
            isUploadingAvatar = false
            showToast(message: "Failed to process image")
            return
        }
        
        let fileSizeKB = Double(imageData.count) / 1024.0
        Logger.d("🖼️ Optimized image size: \(String(format: "%.2f", fileSizeKB)) KB")
        
        do {
            // 1. Upload to S3
            Logger.d("☁️ Starting S3 upload for avatar...")
            let publicUrl = try await S3Service.shared.uploadAvatar(data: imageData, profileID: profileID)
            Logger.d("✅ Avatar uploaded to S3: \(publicUrl)")
            
            // 2. Update local profile
            var profile = localStorage.getLocalProfile()
            profile.updateAvatarUrl(publicUrl)
            localStorage.updateLocalProfile(profile)
            
            // 3. Sync to Firestore
            try await FirestoreService.shared.saveProfile(profile)
            
            showToast(message: "Avatar updated successfully")
        } catch {
            Logger.e("❌ Avatar upload failed: \(error.localizedDescription)")
            showToast(message: "Update failed: \(error.localizedDescription)")
        }
        
        isUploadingAvatar = false
    }
}

// MARK: - UIImage Extension for resizing
extension UIImage {
    func resized(to size: CGSize) -> UIImage? {
        UIGraphicsBeginImageContextWithOptions(size, false, 0.0)
        draw(in: CGRect(origin: .zero, size: size))
        let newImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return newImage
    }
}

// MARK: - Image Picker View (using UIImagePickerController for cropping support)
struct ImagePickerView: UIViewControllerRepresentable {
    let onImageSelected: (UIImage) -> Void
    @Environment(\.dismiss) private var dismiss
    
    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.delegate = context.coordinator
        picker.allowsEditing = true // Enable square cropping
        picker.sourceType = .photoLibrary
        return picker
    }
    
    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}
    
    func makeCoordinator() -> Coordinator {
        Coordinator(onImageSelected: onImageSelected, dismiss: { dismiss() })
    }
    
    class Coordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
        let onImageSelected: (UIImage) -> Void
        let dismiss: () -> Void
        
        init(onImageSelected: @escaping (UIImage) -> Void, dismiss: @escaping () -> Void) {
            self.onImageSelected = onImageSelected
            self.dismiss = dismiss
        }
        
        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
            // Get the edited image (cropped) if available, otherwise original
            if let image = info[.editedImage] as? UIImage ?? info[.originalImage] as? UIImage {
                onImageSelected(image)
            }
            dismiss()
        }
        
        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            dismiss()
        }
    }
}

// MARK: - Edit Name Dialog
// MARK: - Edit Name Dialog Redesigned
struct EditNameDialog: View {
    let currentName: String
    let onSave: (String) -> Void
    let onCancel: () -> Void
    
    @State private var editedName: String
    @State private var isChecking = false
    @State private var verificationResult: VerificationResult = .idle
    @FocusState private var isTextFieldFocused: Bool
    
    enum VerificationResult: Equatable {
        case idle, available, taken, error(String)
        
        var color: Color {
            switch self {
            case .idle: return .gray.opacity(0.6)
            case .available: return .green
            case .taken: return .red
            case .error: return .red
            }
        }
        
        var message: String? {
            switch self {
            case .idle: return nil
            case .available: return "Username available!"
            case .taken: return "Username already taken"
            case .error(let msg): return msg
            }
        }
    }
    
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
                .onTapGesture { onCancel() }
            
            // Dialog Content
            VStack(spacing: 12) {
                // Header: Title and Close
                HStack {
                    Spacer()
                    Text("Edit Username")
                        .font(.system(size: 20, weight: .bold))
                        .foregroundColor(.white)
                    Spacer()
                    Button(action: onCancel) {
                        Image(systemName: "xmark")
                            .font(.system(size: 16, weight: .bold))
                            .foregroundColor(.white)
                    }
                }
                .padding(.bottom, 8)
                
                // TextField with Verify Button
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        TextField("Username", text: $editedName)
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.black)
                            .padding(.leading, 16)
                            .frame(height: 54)
                            .focused($isTextFieldFocused)
                            .onChange(of: editedName) { _ in
                                if verificationResult != .idle {
                                    verificationResult = .idle
                                }
                            }
                        
                        Button(action: verifyUsername) {
                            if isChecking {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                    .frame(width: 80, height: 38)
                            } else {
                                Text("Verify")
                                    .font(.system(size: 14, weight: .bold))
                                    .foregroundColor(.white)
                                    .frame(width: 80, height: 38)
                            }
                        }
                        .background(verificationResult == .idle ? Color.gray.opacity(0.5) : verificationResult.color)
                        .cornerRadius(19)
                        .padding(.trailing, 8)
                        .disabled(isChecking || editedName.trimmingCharacters(in: .whitespaces).isEmpty)
                    }
                    .background(Color.white.opacity(0.95))
                    .cornerRadius(12)
                    
                    // Reserved space for message to avoid jumping
                    Text(verificationResult.message ?? "")
                        .font(.system(size: iPadScale(12)))
                        .foregroundColor(verificationResult.color)
                        .padding(.leading, 4)
                        .frame(height: 18) // Fixed height
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
                
                Button(action: { onSave(editedName) }) {
                    Text("Save Username")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(.black)
                        .frame(maxWidth: .infinity)
                        .frame(height: 56)
                        .background(AivoTheme.Primary.orange)
                        .cornerRadius(28)
                        .opacity(isSaveEnabled ? 1.0 : 0.5)
                }
                .disabled(!isSaveEnabled)
            }
            .padding(24)
            .background(
                RoundedRectangle(cornerRadius: 24)
                    .fill(Color.black)
                    .overlay(
                        RoundedRectangle(cornerRadius: 24)
                            .stroke(Color.white.opacity(0.1), lineWidth: 1)
                    )
            )
            .frame(maxWidth: 340)
            .padding(.horizontal, 20)
            .onAppear { isTextFieldFocused = true }
        }
    }
    
    private var isSaveEnabled: Bool {
        // Allow save if verified as available OR if it's the current name and we just want to close/save
        return verificationResult == .available || (editedName == currentName && !editedName.isEmpty)
    }
    
    private func verifyUsername() {
        let name = editedName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !name.isEmpty else { return }
        
        if name.lowercased() == currentName.lowercased() {
            verificationResult = .available
            return
        }
        
        isChecking = true
        Task {
            do {
                let isAvailable = try await FirestoreService.shared.checkUsernameAvailability(username: name)
                await MainActor.run {
                    verificationResult = isAvailable ? .available : .taken
                    isChecking = false
                }
            } catch {
                await MainActor.run {
                    verificationResult = .error("Check failed")
                    isChecking = false
                }
            }
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
