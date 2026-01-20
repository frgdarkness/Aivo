import SwiftUI

struct RateAppDialog: View {
    @Binding var isPresented: Bool
    var onRate: (Int) -> Void
    var onDismiss: () -> Void
    
    @State private var rating: Int = 0
    @State private var currentStep: RateStep = .rating
    
    // Changed to Set for multi-selection
    @State private var selectedReasons: Set<String> = []
    // Text for "Other" reason
    @State private var otherReasonText: String = ""
    
    enum RateStep {
        case rating
        case feedback
    }
    
    // Configurable reasons
    private let feedbackReasons = [
        "AI song generation failed",
        "Generated music quality is not good",
        "App is slow or laggy",
        "High battery or data usage",
        "Other"
    ]
    
    var body: some View {
        ZStack {
            // Background dim
            Color.black.opacity(0.3)
                .edgesIgnoringSafeArea(.all)
                .onTapGesture {
                    // Optional: dismiss on background tap
                }
            
            // Dialog Content
            VStack(spacing: 0) {
                if currentStep == .rating {
                    ratingContent
                        .transition(.opacity)
                } else {
                    feedbackContent
                        .transition(.opacity)
                }
            }
            .padding(24)
            .background(
                RoundedRectangle(cornerRadius: 24)
                    .fill(Color(hex: 0x2C2C2E)) // Lighter dark background
                    .overlay(
                        RoundedRectangle(cornerRadius: 24)
                            .stroke(Color.white.opacity(0.2), lineWidth: 1) // White border
                    )
                    .shadow(color: .black.opacity(0.5), radius: 20, x: 0, y: 10)
            )
            .padding(.horizontal, 32)
            .scaleEffect(isPresented ? 1 : 0.9)
            .opacity(isPresented ? 1 : 0)
            .animation(.spring(response: 0.4, dampingFraction: 0.8), value: isPresented)
            // Animated transition between steps
            .animation(.easeInOut(duration: 0.3), value: currentStep)
        }
    }
    
    // MARK: - Rating Step
    private var ratingContent: some View {
        VStack(spacing: 24) {
            // Text
            VStack(spacing: 12) {
                Text("Do you love Aivo?")
                    .font(.system(size: 22, weight: .bold))
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)
                
                Text("Please rate your experience!")
                    .font(.system(size: 16))
                    .foregroundColor(.white.opacity(0.7))
                    .multilineTextAlignment(.center)
            }
            .padding(.top, 8)
            
            // Emojis
            HStack(spacing: 16) {
                ForEach(1...5, id: \.self) { index in
                    emojiButton(for: index)
                }
            }
            
            // Not Now
            Button(action: {
                onDismiss()
            }) {
                Text("Not now")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.white.opacity(0.5))
                    .padding(.bottom, 8)
            }
        }
    }
    
    private func emojiButton(for index: Int) -> some View {
        let isSelected = rating == index
        
        return Button(action: {
            withAnimation(.spring()) {
                rating = index
            }
            
            // 1 second delay before action
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                handleRatingSelection(index)
            }
        }) {
            ZStack {
                // Glow/Ring for selection
                if isSelected {
                    Circle()
                        .fill(AivoTheme.Primary.orange.opacity(0.2))
                        .scaleEffect(1.4)
                    
                    Circle()
                        .stroke(AivoTheme.Primary.orange, lineWidth: 2)
                        .scaleEffect(1.2)
                }
                
                Image("icon_emoji_rate_\(index)")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 44, height: 44)
                    .scaleEffect(isSelected ? 1.1 : 1.0)
                    .opacity(rating == 0 || isSelected ? 1.0 : 0.4)
            }
            .frame(width: 44, height: 44)
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    private func handleRatingSelection(_ index: Int) {
        if index <= 3 {
             // Low rating -> Show feedback
             withAnimation {
                 currentStep = .feedback
             }
        } else {
             // High rating -> Submit & Close
             onRate(index)
        }
    }
    
    // MARK: - Feedback Step
    private var feedbackContent: some View {
        VStack(spacing: 20) {
            // Header
            ZStack {
                VStack(spacing: 4) {
                    Text("Your Feedback")
                        .font(.system(size: 20, weight: .bold))
                        .foregroundColor(.white)
                    
                    Text("Tell us about any issues you experienced.")
                        .font(.system(size: 14))
                        .foregroundColor(.white.opacity(0.7))
                }
                
                // Close Button (Top right relative to header, or absolute in overlay)
                HStack {
                    Spacer()
                    Button(action: { onDismiss() }) {
                        Image(systemName: "xmark")
                            .foregroundColor(.white.opacity(0.6))
                            .padding(8)
                            .background(Color.white.opacity(0.1))
                            .clipShape(Circle())
                    }
                }
                .offset(x: 0, y: -10)
            }
            .padding(.top, 4)
            
            // Reasons list
            VStack(spacing: 12) {
                ForEach(feedbackReasons, id: \.self) { reason in
                    reasonRow(reason)
                }
            }
            
            // Submit Button
            Button(action: {
                submitFeedback()
            }) {
                Text("Submit")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(canSubmit ? .white : .white.opacity(0.3))
                    .frame(maxWidth: .infinity)
                    .frame(height: 50)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(canSubmit ? AivoTheme.Primary.orange : Color.gray.opacity(0.3))
                    )
            }
            .disabled(!canSubmit)
            .padding(.top, 10)
        }
    }
    
    private func reasonRow(_ reason: String) -> some View {
        let isSelected = selectedReasons.contains(reason)
        let isOther = reason == "Other"
        
        return VStack(spacing: 12) {
            Button(action: {
                if isSelected {
                    selectedReasons.remove(reason)
                } else {
                    selectedReasons.insert(reason)
                }
            }) {
                HStack {
                    Text(reason)
                        .font(.system(size: 14))
                        .foregroundColor(.white.opacity(0.9))
                        .fixedSize(horizontal: false, vertical: true)
                        .multilineTextAlignment(.leading)
                    
                    Spacer()
                    
                    // Checkbox Square with Checkmark
                    ZStack {
                        RoundedRectangle(cornerRadius: 6)
                            .stroke(isSelected ? AivoTheme.Primary.orange : Color.white.opacity(0.3), lineWidth: 2)
                            .frame(width: 24, height: 24)
                        
                        if isSelected {
                            RoundedRectangle(cornerRadius: 6)
                                .fill(AivoTheme.Primary.orange)
                                .frame(width: 24, height: 24)
                            
                            Image(systemName: "checkmark")
                                .font(.system(size: 12, weight: .bold))
                                .foregroundColor(.white)
                        }
                    }
                }
                .padding(16)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color.white.opacity(0.05))
                )
                .overlay(
                     RoundedRectangle(cornerRadius: 12)
                         .stroke(isSelected ? AivoTheme.Primary.orange.opacity(0.5) : Color.clear, lineWidth: 1)
                )
            }
            .buttonStyle(PlainButtonStyle())
            
            // Text Input for "Other" - Always Visible
            if isOther {
                TextField("", text: $otherReasonText)
                    .placeholder(when: otherReasonText.isEmpty) {
                        Text("Please tell us more...")
                            .foregroundColor(Color.white.opacity(0.3))
                    }
                    .font(.system(size: 14))
                    .padding(16)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color.white.opacity(0.05))
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color.white.opacity(0.1), lineWidth: 1)
                    )
                    .foregroundColor(.white)
            }
        }
        .animation(.easeInOut(duration: 0.2), value: selectedReasons.contains(reason))
    }
    
    private var canSubmit: Bool {
        if selectedReasons.isEmpty { return false }
        if selectedReasons.contains("Other") && otherReasonText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            return false
        }
        return true
    }
    
    private func submitFeedback() {
        var reasonsList = Array(selectedReasons)
        
        // Append custom text to "Other" if present
        if let index = reasonsList.firstIndex(of: "Other") {
            reasonsList[index] = "Other: \(otherReasonText)"
        }
        
        let reasonString = reasonsList.joined(separator: ", ")
        
        // Log to Firebase
        Task {
            let userId = LocalStorageManager.shared.getLocalProfile().profileID
            try? await FirebaseRealtimeService.shared.logUserReport(userId: userId, reason: reasonString)
        }
        
        onRate(rating) // Finalize (dismiss or custom validation)
    }
}

extension View {
    func placeholder<Content: View>(
        when shouldShow: Bool,
        alignment: Alignment = .leading,
        @ViewBuilder placeholder: () -> Content) -> some View {

        ZStack(alignment: alignment) {
            placeholder().opacity(shouldShow ? 1 : 0)
            self
        }
    }
}
