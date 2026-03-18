//
//  GenerationSuccessDialog.swift
//  Aivo
//
//  Created on 25/12/24.
//

import SwiftUI
import Kingfisher

struct GenerationSuccessDialog: View {
    let sunoDataList: [SunoData]
    let onPlayNow: () -> Void
    let onClose: () -> Void
    
    @ObservedObject private var storage = LocalStorageManager.shared
    @State private var showInfoAlert = false
    
    var body: some View {
        ZStack {
            // Dimmed background
            Color.black.opacity(0.7)
                .edgesIgnoringSafeArea(.all)
                .onTapGesture {
                    onClose()
                }
            
            // Dialog Card
            VStack(spacing: 0) {
                // Header
                HStack {
                    Spacer()
                    Button(action: onClose) {
                        Image(systemName: "xmark")
                            .font(.system(size: iPadScale(16), weight: .bold))
                            .foregroundColor(.white.opacity(0.7))
                            .padding(iPadScaleSmall(12))
                    }
                }
                
                // Content
                VStack(spacing: iPadScaleSmall(16)) {
                    // Success Icon/Title
                    VStack(spacing: iPadScaleSmall(12)) {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: iPadScale(48)))
                            .foregroundColor(AivoTheme.Primary.orange)
                            .shadow(color: AivoTheme.Primary.orange.opacity(0.5), radius: 10)
                        
                        Text("Song Generation Complete!")
                            .font(.system(size: iPadScale(20), weight: .bold))
                            .foregroundColor(.white)
                            .multilineTextAlignment(.center)
                    }
                    .padding(.bottom, 8)
                    
                    // Song List
                    VStack(spacing: iPadScaleSmall(12)) {
                        ForEach(sunoDataList) { song in
                            songItemView(song)
                        }
                    }
                    .padding(.horizontal, iPadScaleSmall(16))
                    
                    // Auto Share Toggle
                    autoShareRow
                    
                    Spacer().frame(height: 8)
                    
                    // View Result Button
                    Button(action: {
                        onClose()
                        Logger.i("View Result tapped. Switching to Library Tab...", file: "GenerationSuccessDialog.swift")
                        // Switch to Library Tab (Index 3)
                        NotificationCenter.default.post(name: NSNotification.Name("SwitchMainTab"), object: 3)
                        
                        // Switch to AI Generate Category and Play
                        let songIds = sunoDataList.map { $0.id }
                        Logger.d("Posting PlayLatestGeneratedSongs for IDs: \(songIds)", file: "GenerationSuccessDialog.swift")
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                            NotificationCenter.default.post(name: NSNotification.Name("SwitchLibraryCategory"), object: "AI Generate")
                        }
                        
                        // Show rating after 3s delay
                        DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                            AppRatingManager.shared.tryShowRateApp()
                        }
                    }) {
                        Text("View Result")
                            .font(.system(size: iPadScale(16), weight: .semibold))
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .frame(height: iPadScale(50))
                            .background(
                                RoundedRectangle(cornerRadius: iPadScale(12))
                                    .fill(Color.white.opacity(0.15))
                            )
                    }
                    .padding(.horizontal, 20)
                    
                    // Play Now Button
                    Button(action: {
                        onPlayNow()
                        // Show rating after 3s delay
                        DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                            AppRatingManager.shared.tryShowRateApp()
                        }
                    }) {
                        HStack(spacing: 8) {
                            Image(systemName: "play.fill")
                                .font(.system(size: iPadScale(16), weight: .bold))
                            Text("Play Now")
                                .font(.system(size: iPadScale(16), weight: .bold))
                        }
                        .foregroundColor(.black)
                        .frame(maxWidth: .infinity)
                        .frame(height: iPadScale(50))
                        .background(
                            RoundedRectangle(cornerRadius: iPadScale(12))
                                .fill(AivoTheme.Primary.orange)
                        )
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 24)
                }
            }
            .frame(maxWidth: DeviceScale.isIPad ? 480 : 340)
            .background(
                RoundedRectangle(cornerRadius: iPadScale(20))
                    .fill(Color(hex: 0x1C1C1E)) // Dark gray background
                    .overlay(
                        RoundedRectangle(cornerRadius: iPadScale(20))
                            .stroke(AivoTheme.Primary.orange.opacity(0.3), lineWidth: 1)
                    )
                    .shadow(color: .black.opacity(0.5), radius: 20, x: 0, y: 10)
            )
        }
        .transition(.opacity.combined(with: .scale(scale: 0.9)))
        .animation(.spring(response: 0.35, dampingFraction: 0.8), value: true)
        .alert("Auto Share Mode", isPresented: $showInfoAlert) {
            Button("Got it!", role: .cancel) { }
        } message: {
            Text("If you enable this mode, your songs will be shared with the community. The top 10 most-played songs each week will be honored and receive rewards.")
        }
    }
    
    // MARK: - Auto Share Row
    private var autoShareRow: some View {
        HStack(spacing: iPadScaleSmall(8)) {
            Button(action: {
                showInfoAlert = true
            }) {
                Image(systemName: "info.circle")
                    .foregroundColor(AivoTheme.Primary.orange)
                    .font(.system(size: iPadScale(18)))
            }
            
            Text("Auto Share Song")
                .font(.system(size: iPadScale(15), weight: .medium))
                .foregroundColor(.white.opacity(0.85))
            
            Spacer()
            
            Toggle("", isOn: Binding(
                get: { storage.autoShareEnabled },
                set: { storage.setAutoShareEnabled($0) }
            ))
            .labelsHidden()
            .tint(AivoTheme.Primary.orange)
            .scaleEffect(0.85)
        }
        .padding(.horizontal, iPadScaleSmall(24))
        .padding(.vertical, 4)
    }
    
    // MARK: - Song Item View
    private func songItemView(_ song: SunoData) -> some View {
        let coverSize = iPadScale(50)
        
        return HStack(spacing: iPadScaleSmall(12)) {
            // Cover Image
            if let url = URL(string: song.imageUrl), !song.imageUrl.isEmpty {
                KFImage(url)
                    .placeholder {
                        Image("cover_default_resize")
                           .resizable()
                           .aspectRatio(contentMode: .fill)
                    }
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: coverSize, height: coverSize)
                    .clipShape(RoundedRectangle(cornerRadius: iPadScale(8)))
            } else {
                Image("cover_default_resize")
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: coverSize, height: coverSize)
                    .clipShape(RoundedRectangle(cornerRadius: iPadScale(8)))
            }
            
            // Info
            VStack(alignment: .leading, spacing: 4) {
                Text(song.title.isEmpty ? "Untitled Song" : song.title)
                    .font(.system(size: iPadScale(16), weight: .semibold))
                    .foregroundColor(.white)
                    .lineLimit(1)
                
                HStack(spacing: 8) {
                    Label(formatDuration(song.duration), systemImage: "clock")
                        .font(.system(size: iPadScale(12)))
                        .foregroundColor(.white.opacity(0.6))
                    
                    Text("•")
                        .foregroundColor(.white.opacity(0.6))
                        .font(.system(size: iPadScale(10)))
                    
                    Text(song.modelName)
                        .font(.system(size: iPadScale(12)))
                        .foregroundColor(AivoTheme.Primary.orange)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(AivoTheme.Primary.orange.opacity(0.15))
                        .cornerRadius(4)
                }
            }
            
            Spacer()
        }
        .padding(iPadScaleSmall(10))
        .background(
            RoundedRectangle(cornerRadius: iPadScale(12))
                .fill(Color.white.opacity(0.05))
        )
    }
    
    private func formatDuration(_ duration: Double) -> String {
        let minutes = Int(duration) / 60
        let seconds = Int(duration) % 60
        return String(format: "%d:%02d", minutes, seconds)
    }
}
