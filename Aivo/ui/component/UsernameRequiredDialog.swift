//
//  UsernameRequiredDialog.swift
//  Aivo
//
//  Dialog shown to users with default "Your name" username,
//  prompting them to set a proper username before generating songs.
//

import SwiftUI

struct UsernameRequiredDialog: View {
    var title: String = "Set Your Username"
    let onSave: (String) -> Void
    let onDismiss: () -> Void
    
    @State private var editedName: String = ""
    @State private var isVerifying = false
    @State private var verifyResult: VerifyResult? = nil
    @FocusState private var isTextFieldFocused: Bool
    
    enum VerifyResult {
        case available
        case taken
        case invalid(String)
    }
    
    var body: some View {
        ZStack {
            // Background overlay
            Color.black.opacity(0.6)
                .ignoresSafeArea()
            
            // Dialog Content
            VStack(alignment: .leading, spacing: iPadScaleSmall(16)) {
                // Header
                HStack {
                    Image(systemName: "person.crop.circle")
                        .font(.system(size: iPadScale(28)))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [AivoTheme.Primary.orange, Color(red: 1.0, green: 0.5, blue: 0.0)],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                    
                    Text(title)
                        .font(.system(size: iPadScale(20), weight: .bold))
                        .foregroundColor(.white)
                    
                    Spacer()
                    
                    Button(action: onDismiss) {
                        Image(systemName: "xmark")
                            .font(.system(size: iPadScale(14), weight: .bold))
                            .foregroundColor(.white.opacity(0.6))
                    }
                }
                
                // Description
                Text("Your username will be used as the author name when your songs are shared with the community.")
                    .font(.system(size: iPadScale(14)))
                    .foregroundColor(.white.opacity(0.7))
                    .lineSpacing(3)
                    .fixedSize(horizontal: false, vertical: true)
                
                // Username input field
                HStack {
                    Image(systemName: "person.fill")
                        .font(.system(size: iPadScale(18)))
                        .foregroundColor(AivoTheme.Primary.orange)
                    
                    TextField("", text: $editedName)
                        .font(.system(size: iPadScale(17)))
                        .foregroundColor(.white)
                        .autocapitalization(.none)
                        .disableAutocorrection(true)
                        .placeholder(when: editedName.isEmpty) {
                            Text("Enter username")
                                .foregroundColor(.white.opacity(0.3))
                                .font(.system(size: iPadScale(17)))
                        }
                        .focused($isTextFieldFocused)
                        .onChange(of: editedName) { _ in
                            verifyResult = nil
                        }
                    
                    // Clear button
                    if !editedName.isEmpty {
                        Button(action: { editedName = "" }) {
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
                            .foregroundColor(.white.opacity(0.6))
                    }
                    
                    Spacer()
                    
                    // Verify button
                    Button(action: { verifyUsername() }) {
                        ZStack {
                            Text("Verify")
                                .font(.system(size: iPadScale(14), weight: .semibold))
                                .opacity(isVerifying ? 0 : 1)
                            
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
                    .disabled(isVerifying || editedName.trimmingCharacters(in: .whitespaces).isEmpty)
                    .opacity(isVerifying || editedName.trimmingCharacters(in: .whitespaces).isEmpty ? 0.6 : 1.0)
                }
                
                // Save Button
                Button(action: { onSave(editedName.trimmingCharacters(in: .whitespacesAndNewlines)) }) {
                    Text("Save Username")
                        .font(.system(size: iPadScale(18), weight: .bold))
                        .foregroundColor(.black)
                        .frame(maxWidth: .infinity)
                        .frame(height: iPadScale(52))
                        .background(
                            RoundedRectangle(cornerRadius: iPadScale(26))
                                .fill(AivoTheme.Primary.orange)
                        )
                        .opacity(isAvailable ? 1.0 : 0.5)
                }
                .disabled(!isAvailable)
            }
            .padding(iPadScaleSmall(24))
            .background(
                RoundedRectangle(cornerRadius: iPadScale(24))
                    .fill(Color(white: 0.12))
                    .overlay(
                        RoundedRectangle(cornerRadius: iPadScale(24))
                            .stroke(Color.white.opacity(0.1), lineWidth: 1)
                    )
            )
            .frame(maxWidth: iPadScale(360))
            .padding(.horizontal, 20)
            .onAppear { isTextFieldFocused = true }
        }
    }
    
    private var isAvailable: Bool {
        if case .available = verifyResult { return true }
        return false
    }
    
    private func validateUsername(_ name: String) -> String? {
        if name.count < 4 {
            return "Too short (min 4 characters)"
        }
        if name.count > 24 {
            return "Too long (max 24 characters)"
        }
        
        let allowed = CharacterSet.alphanumerics.union(CharacterSet(charactersIn: " -"))
        if name.unicodeScalars.contains(where: { !allowed.contains($0) }) {
            return "Only letters, numbers, spaces, hyphens"
        }
        
        return nil
    }
    
    private func verifyUsername() {
        let name = editedName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !name.isEmpty else { return }
        
        // Local validation first
        if let error = validateUsername(name) {
            verifyResult = .invalid(error)
            return
        }
        
        isVerifying = true
        Task {
            do {
                let available = try await FirestoreService.shared.checkUsernameAvailability(username: name)
                await MainActor.run {
                    isVerifying = false
                    verifyResult = available ? .available : .taken
                }
            } catch {
                await MainActor.run {
                    isVerifying = false
                    verifyResult = .invalid("Check failed")
                }
            }
        }
    }
}

#Preview {
    UsernameRequiredDialog(
        onSave: { _ in },
        onDismiss: { }
    )
}
