import SwiftUI
import FirebaseFirestore

// MARK: - Input Username Screen
struct InputUsernameScreen: View {
    let onContinue: () -> Void
    
    @State private var username: String = ""
    @State private var isVerifying: Bool = false
    @State private var verifyResult: VerifyResult? = nil
    @State private var showContent = false
    @State private var showButton = false
    
    enum VerifyResult {
        case available
        case taken
        case invalid(String)
    }
    
    init(onContinue: @escaping () -> Void) {
        self.onContinue = onContinue
        // Generate default username
        let formatter = DateFormatter()
        formatter.dateFormat = "MMddHH"
        let dateStr = formatter.string(from: Date())
        let random4 = String(format: "%04d", Int.random(in: 0...9999))
        _username = State(initialValue: "user\(random4)\(dateStr)")
    }
    
    var body: some View {
        ZStack {
            AivoSunsetBackground()
            
            // Sticker decorations
            GeometryReader { geo in
                // Piano - top left
                Image("sticker_piano")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: iPadScale(320))
                    .opacity(1)
                    .rotationEffect(.degrees(-10))
                    .position(x: iPadScale(150), y: geo.size.height * 0.22)
                
                // Electric guitar - bottom left
                Image("sticker_electric_guitar")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: iPadScale(320))
                    .opacity(1)
                    .rotationEffect(.degrees(20))
                    .position(x: iPadScale(60), y: geo.size.height * 0.75)
                
                // Boom box - right side, 1/4 from bottom
                Image("sticker_column")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: iPadScale(280))
                    .opacity(1)
                    .rotationEffect(.degrees(12))
                    .position(x: geo.size.width - iPadScale(80), y: geo.size.height * 0.70)
            }
            .ignoresSafeArea()
            
            VStack(spacing: 0) {
                Spacer()
                
                // Username input card
                usernameCardView
                    .opacity(showContent ? 1 : 0)
                    .offset(y: showContent ? 0 : 30)
                    .animation(.easeOut(duration: 0.8).delay(0.3), value: showContent)
                
                Spacer()
                
                // Continue Button - matching IntroScreen
                continueButtonView
            }
            .padding(.horizontal, iPadScaleSmall(20))
        }
        .onAppear {
            showContent = true
            showButton = true
        }
    }
    
    // MARK: - Username Card View
    private var usernameCardView: some View {
        VStack(alignment: .leading, spacing: iPadScaleSmall(16)) {
            // Title
            Text("Input your username")
                .font(.system(size: iPadScale(22), weight: .bold))
                .foregroundColor(.white)
            
            Text("This name will be shown as the author when your songs are shared with the community.")
                .font(.system(size: iPadScale(14)))
                .foregroundColor(.white.opacity(0.6))
            
            // Username input field
            HStack {
                Image(systemName: "person.fill")
                    .font(.system(size: iPadScale(18)))
                    .foregroundColor(AivoTheme.Primary.orange)
                
                TextField("", text: $username)
                    .font(.system(size: iPadScale(17)))
                    .foregroundColor(.white)
                    .autocapitalization(.none)
                    .disableAutocorrection(true)
                    .placeholder(when: username.isEmpty) {
                        Text("Enter username")
                            .foregroundColor(.white.opacity(0.3))
                            .font(.system(size: iPadScale(17)))
                    }
                    .onChange(of: username) { _ in
                        // Reset verify result when user types
                        verifyResult = nil
                    }
                
                // Clear button
                if !username.isEmpty {
                    Button(action: { username = "" }) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: iPadScale(16)))
                            .foregroundColor(.white.opacity(0.4))
                    }
                }
            }
            .padding(iPadScaleSmall(14))
            .background(
                RoundedRectangle(cornerRadius: iPadScale(10))
                    .fill(Color.white.opacity(0.08))
            )
            .overlay(
                RoundedRectangle(cornerRadius: iPadScale(10))
                    .stroke(
                        verifyResult != nil
                            ? (isAvailable ? Color.green.opacity(0.5) : Color.red.opacity(0.5))
                            : AivoTheme.Primary.orange.opacity(0.3),
                        lineWidth: 1
                    )
            )
            
            // Validation hint + Verify button
            HStack {
                // Status text
                if let result = verifyResult {
                    switch result {
                    case .available:
                        Label("Username available!", systemImage: "checkmark.circle.fill")
                            .font(.system(size: iPadScale(13)))
                            .foregroundColor(.green)
                    case .taken:
                        Label("Username already taken", systemImage: "xmark.circle.fill")
                            .font(.system(size: iPadScale(13)))
                            .foregroundColor(.red)
                    case .invalid(let msg):
                        Label(msg, systemImage: "exclamationmark.triangle.fill")
                            .font(.system(size: iPadScale(13)))
                            .foregroundColor(.orange)
                    }
                } else {
                    Text("Require: Use 4–24 characters (letters, numbers, spaces, or hyphens).")
                        .font(.system(size: iPadScale(12)))
                        .foregroundColor(.white.opacity(0.4))
                }
                
                Spacer()
                
                // Verify button - fixed size
                Button(action: {
                    verifyUsername()
                }) {
                    ZStack {
                        // Always reserve space for "Verify" text
                        Text("Verify")
                            .font(.system(size: iPadScale(14), weight: .semibold))
                            .opacity(isVerifying ? 0 : 1)
                        
                        // Show spinner on top when verifying
                        if isVerifying {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .black))
                                .scaleEffect(DeviceScale.isIPad ? 1.2 : 0.7)
                        }
                    }
                    .foregroundColor(.black)
                    .frame(height: iPadScale(32))
                    .padding(.horizontal, iPadScaleSmall(16))
                    .background(AivoTheme.Primary.orange)
                    .cornerRadius(iPadScale(8))
                }
                .disabled(isVerifying || username.isEmpty)
                .opacity(isVerifying || username.isEmpty ? 0.6 : 1.0)
            }
        }
        .padding(iPadScaleSmall(20))
        .background(
            RoundedRectangle(cornerRadius: iPadScale(16), style: .continuous)
                .fill(AivoTheme.Background.card)
        )
        .overlay(
            RoundedRectangle(cornerRadius: iPadScale(16), style: .continuous)
                .stroke(AivoTheme.Primary.orange.opacity(0.3), lineWidth: 1)
        )
    }
    
    // MARK: - Continue Button (matching IntroScreen)
    private var continueButtonView: some View {
        Button(action: {
            handleContinue()
        }) {
            HStack {
                Text("Continue")
                    .font(.system(size: iPadScale(17), weight: .semibold))
                
                Image(systemName: "arrow.right")
                    .font(.system(size: iPadScale(17)))
            }
            .foregroundColor(.black)
            .frame(maxWidth: .infinity)
            .frame(height: iPadScale(50))
            .background(AivoTheme.Primary.orange)
            .cornerRadius(iPadScale(12))
            .shadow(color: AivoTheme.Shadow.orange, radius: 10, x: 0, y: 0)
        }
        .padding(.bottom, iPadScaleSmall(30))
        .opacity(showButton ? 1 : 0)
        .offset(y: showButton ? 0 : 40)
        .animation(.easeOut(duration: 0.9).delay(1.0), value: showButton)
    }
    
    // MARK: - Computed
    private var isAvailable: Bool {
        if case .available = verifyResult { return true }
        return false
    }
    
    // MARK: - Actions
    private func verifyUsername() {
        let trimmed = username.trimmingCharacters(in: .whitespacesAndNewlines)
        
        // Local validation first
        if let error = validateUsername(trimmed) {
            verifyResult = .invalid(error)
            return
        }
        
        // Check Firestore
        isVerifying = true
        Task {
            do {
                let available = try await FirestoreService.shared.checkUsernameAvailability(username: trimmed)
                await MainActor.run {
                    isVerifying = false
                    verifyResult = available ? .available : .taken
                }
            } catch {
                await MainActor.run {
                    isVerifying = false
                    // If network error, allow to proceed (will be checked again when saving)
                    verifyResult = .available
                    Logger.e("❌ [InputUsername] Verify error: \(error.localizedDescription)")
                }
            }
        }
    }
    
    private func validateUsername(_ name: String) -> String? {
        if name.count < 4 {
            return "Too short (min 4 characters)"
        }
        if name.count > 24 {
            return "Too long (max 24 characters)"
        }
        
        // Only allow letters, numbers, spaces, hyphens
        let allowed = CharacterSet.alphanumerics.union(CharacterSet(charactersIn: " -"))
        if name.unicodeScalars.contains(where: { !allowed.contains($0) }) {
            return "Only letters, numbers, spaces, hyphens"
        }
        
        return nil
    }
    
    private func handleContinue() {
        let trimmed = username.trimmingCharacters(in: .whitespacesAndNewlines)
        
        // If empty, use current default
        let finalUsername = trimmed.isEmpty ? username : trimmed
        
        // Local validation first
        if let error = validateUsername(finalUsername) {
            verifyResult = .invalid(error)
            return
        }
        
        // If already verified as available, proceed directly
        if isAvailable {
            saveAndContinue(finalUsername)
            return
        }
        
        // Otherwise trigger verify, proceed only if available
        isVerifying = true
        Task {
            do {
                let available = try await FirestoreService.shared.checkUsernameAvailability(username: finalUsername)
                await MainActor.run {
                    isVerifying = false
                    if available {
                        verifyResult = .available
                        saveAndContinue(finalUsername)
                    } else {
                        verifyResult = .taken
                    }
                }
            } catch {
                await MainActor.run {
                    isVerifying = false
                    // Network error - allow to proceed
                    verifyResult = .available
                    saveAndContinue(finalUsername)
                    Logger.e("❌ [InputUsername] Verify error: \(error.localizedDescription)")
                }
            }
        }
    }
    
    private func saveAndContinue(_ finalUsername: String) {
        // Save username to local profile
        var profile = LocalStorageManager.shared.getLocalProfile()
        profile.updateUserName(finalUsername)
        LocalStorageManager.shared.saveLocalProfile(profile)
        
        // Also claim username on Firestore in background
        Task {
            do {
                try await FirestoreService.shared.updateUsername(
                    profileID: profile.profileID,
                    newUsername: finalUsername,
                    oldUsername: nil
                )
                Logger.d("✅ [InputUsername] Username claimed: \(finalUsername)")
            } catch {
                Logger.e("❌ [InputUsername] Failed to claim username: \(error.localizedDescription)")
            }
        }
        
        // Sync profile to remote
        Task {
            await LocalStorageManager.shared.syncProfileIfNeeded()
        }
        
        // Mark intro as complete
        UserDefaultsManager.shared.markIntroAsShowed()
        
        Logger.d("✅ [InputUsername] Username set: \(finalUsername)")
        onContinue()
    }
}


// MARK: - Preview
struct InputUsernameScreen_Previews: PreviewProvider {
    static var previews: some View {
        InputUsernameScreen {
            print("Continue tapped")
        }
    }
}
