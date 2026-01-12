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
                            .font(.system(size: 16, weight: .bold))
                            .foregroundColor(.white.opacity(0.7))
                            .padding(12)
                    }
                }
                
                // Content
                VStack(spacing: 16) {
                    // Success Icon/Title
                    VStack(spacing: 12) {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 48))
                            .foregroundColor(AivoTheme.Primary.orange)
                            .shadow(color: AivoTheme.Primary.orange.opacity(0.5), radius: 10)
                        
                        Text("Song Generation Complete!")
                            .font(.system(size: 20, weight: .bold))
                            .foregroundColor(.white)
                            .multilineTextAlignment(.center)
                    }
                    .padding(.bottom, 8)
                    
                    // Song List
                    VStack(spacing: 12) {
                        ForEach(sunoDataList) { song in
                            songItemView(song)
                        }
                    }
                    .padding(.horizontal, 16)
                    
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
                            // User requested View Result to ONLY open Library, not auto-play
                            // NotificationCenter.default.post(name: NSNotification.Name("PlayLatestGeneratedSongs"), object: songIds)
                        }
                    }) {
                        Text("View Result")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .frame(height: 50)
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(Color.white.opacity(0.15))
                            )
                    }
                    .padding(.horizontal, 20)
                    
                    // Play Now Button
                    Button(action: onPlayNow) {
                        HStack(spacing: 8) {
                            Image(systemName: "play.fill")
                                .font(.system(size: 16, weight: .bold))
                            Text("Play Now")
                                .font(.system(size: 16, weight: .bold))
                        }
                        .foregroundColor(.black)
                        .frame(maxWidth: .infinity)
                        .frame(height: 50)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(AivoTheme.Primary.orange)
                        )
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 24)
                }
            }
            .frame(maxWidth: 340)
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(Color(hex: 0x1C1C1E)) // Dark gray background
                    .overlay(
                        RoundedRectangle(cornerRadius: 20)
                            .stroke(AivoTheme.Primary.orange.opacity(0.3), lineWidth: 1)
                    )
                    .shadow(color: .black.opacity(0.5), radius: 20, x: 0, y: 10)
            )
        }
        .transition(.opacity.combined(with: .scale(scale: 0.9)))
        .animation(.spring(response: 0.35, dampingFraction: 0.8), value: true)
    }
    
    // MARK: - Song Item View
    private func songItemView(_ song: SunoData) -> some View {
        HStack(spacing: 12) {
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
                    .frame(width: 50, height: 50)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
            } else {
                Image("cover_default_resize")
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: 50, height: 50)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
            }
            
            // Info
            VStack(alignment: .leading, spacing: 4) {
                Text(song.title.isEmpty ? "Untitled Song" : song.title)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.white)
                    .lineLimit(1)
                
                HStack(spacing: 8) {
                    Label(formatDuration(song.duration), systemImage: "clock")
                        .font(.system(size: 12))
                        .foregroundColor(.white.opacity(0.6))
                    
                    Text("•")
                        .foregroundColor(.white.opacity(0.6))
                        .font(.system(size: 10))
                    
                    Text(song.modelName)
                        .font(.system(size: 12))
                        .foregroundColor(AivoTheme.Primary.orange)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(AivoTheme.Primary.orange.opacity(0.15))
                        .cornerRadius(4)
                }
            }
            
            Spacer()
        }
        .padding(10)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.white.opacity(0.05))
        )
    }
    
    private func formatDuration(_ duration: Double) -> String {
        let minutes = Int(duration) / 60
        let seconds = Int(duration) % 60
        return String(format: "%d:%02d", minutes, seconds)
    }
}
