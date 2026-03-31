import SwiftUI

// MARK: - Generate Song Processing Screen
struct GenerateSongProcessingScreen: View {
    let requestType: RequestType
    let onBackgroundProcess: () -> Void
    let onCancel: (() -> Void)?
    
    @State private var progress: Double = 0.0
    @State private var animationOffset: CGFloat = 0
    @State private var isAnimating = false
    @State private var randomSeed: Double = 0
    @State private var showToast = false
    @State private var toastMessage = ""
    @State private var showCancelAlert = false
    @Environment(\.dismiss) private var dismiss
    
    // Initialize with request type, onBackgroundProcess and optional onCancel
    init(requestType: RequestType, onBackgroundProcess: @escaping () -> Void, onCancel: (() -> Void)? = nil) {
        self.requestType = requestType
        self.onBackgroundProcess = onBackgroundProcess
        self.onCancel = onCancel
    }
    
    var body: some View {
        ZStack {
            // Background
            AivoSunsetBackground()
            VStack {
                VStack(spacing: iPadScaleSmall(12)) {
                    // Header: Title centered + Close button at trailing
                    ZStack {
                        // Close button at trailing
                        HStack {
                            Spacer()
                            Button(action: {
                                showCancelAlert = true
                            }) {
                                Image(systemName: "xmark")
                                    .font(.system(size: iPadScale(20)))
                                    .foregroundColor(.white)
                                    .padding()
                            }
                        }
                        
                        // Title centered in full width
                        Text(requestType.displayName)
                            .font(.system(size: iPadScale(24), weight: .bold))
                            .foregroundColor(.white)
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 30)
                    
                    // Subtitle close to title
                    Text("Just a Moment!")
                        .font(.system(size: iPadScale(16), weight: .medium))
                        .foregroundColor(.white.opacity(0.8))
                        .padding(.top, -6)
                }
                
                if SubscriptionManager.shared.isPremium {
                    Spacer()
                }
                
                // Animation Area
                animationView
                
                // Status Text
                statusView
                
                Spacer()
                
                // Native Ad (non-premium only)
                if !SubscriptionManager.shared.isPremium {
                    LargeNativeAdContainerView()
                        .frame(height: iPadScale(280))
                        .clipShape(RoundedRectangle(cornerRadius: iPadScale(12)))
                        .padding(.horizontal, 24)
                }
                
                Spacer().frame(height: 8)
                
                // Process in Background Button
                Button(action: {
                    onBackgroundProcess()
                }) {
                    Text("Process in Background")
                        .font(.system(size: iPadScale(17), weight: .semibold))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: iPadScale(50))
                        .background(Color.white.opacity(0.2))
                        .cornerRadius(iPadScale(25))
                        .overlay(
                            RoundedRectangle(cornerRadius: iPadScale(25))
                                .stroke(Color.white.opacity(0.5), lineWidth: 1)
                        )
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 40)
            }
        }
        .onAppear {
            startProgressAnimation()
            startWaveAnimation()
        }
        .overlay(
            // Toast Message
            VStack {
                Spacer()
                if showToast {
                    Text(toastMessage)
                        .font(.system(size: iPadScale(16), weight: .medium))
                        .foregroundColor(.white)
                        .padding(.horizontal, 20)
                        .padding(.vertical, 12)
                        .background(Color.black.opacity(0.8))
                        .cornerRadius(8)
                        .padding(.bottom, 100)
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                        .animation(.easeInOut(duration: 0.3), value: showToast)
                }
            }
        )
        .alert("Cancel Generation?", isPresented: $showCancelAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Yes, Exit", role: .destructive) {
                // User confirmed cancellation
                Logger.i("⚠️ [ProcessingScreen] User confirmed cancellation")
                onCancel?()
                dismiss()
            }
        } message: {
            Text("If you exit now, the generation process will be cancelled. To keep it running, choose 'Process in Background'.")
        }
    }
    
    // MARK: - Animation View
    private var animationView: some View {
        let animSize: CGFloat = DeviceScale.isIPad ? 440 : 240
        let lottieSize: CGFloat = DeviceScale.isIPad ? 400 : 240
        
        return ZStack {
            Circle()
                .stroke(Color.white.opacity(0.18), lineWidth: DeviceScale.isIPad ? 3 : 2)
                .frame(width: animSize, height: animSize)

            LottieView(name: "lottie_wave_loop", loopMode: .loop, speed: 2.0)
                        .frame(width: lottieSize, height: lottieSize)
                        .clipShape(Circle())
                        .shadow(color: .yellow.opacity(0.4), radius: 10, x: 0, y: 0)
            Circle()
                .stroke(
                    LinearGradient(colors: [.yellow.opacity(0.8), .orange.opacity(0.4)],
                                   startPoint: .topLeading, endPoint: .bottomTrailing),
                    lineWidth: DeviceScale.isIPad ? 4 : 3
                )
                .frame(width: animSize, height: animSize)
        }
        .padding(.top, 18)
    }

    
    // MARK: - Status View
    private var statusView: some View {
        VStack(spacing: iPadScaleSmall(8)) {
            Text("We'll let you know once it's done!")
                .font(.system(size: iPadScale(16), weight: .medium))
                .foregroundColor(.white)
                .multilineTextAlignment(.center)
            
            Text("(2-5 Min)")
                .font(.system(size: iPadScale(14), weight: .regular))
                .foregroundColor(.white.opacity(0.8))
        }.padding(.top, 12)
    }
    
    // MARK: - Helper Methods
    
    private func startWaveAnimation() {
        // Initialize random seed
        randomSeed = Double.random(in: 0...1000)
        
        // Start continuous animation with random variations
        Timer.scheduledTimer(withTimeInterval: 0.08, repeats: true) { timer in
            withAnimation(.linear(duration: 0.08)) {
                animationOffset += 0.15
                
                // Occasionally change random seed for more variation
                if Int.random(in: 1...20) == 1 {
                    randomSeed += Double.random(in: -50...50)
                }
            }
            
            // Toggle animation state for wave height changes
            if !isAnimating {
                isAnimating = true
            }
        }
    }
    
    private func startProgressAnimation() {
        // Simulate progress for UI only
        Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { timer in
            if progress < 1.0 {
                progress += 0.02
            } else {
                timer.invalidate()
            }
        }
    }
    
    private func showToastMessage(_ message: String) {
        toastMessage = message
        showToast = true
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
            showToast = false
        }
    }
}
