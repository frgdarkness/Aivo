//
//  SleepTimerView.swift
//  Aivo
//
//  Adapted from Sona_ref
//

import SwiftUI

struct SleepTimerView: View {
    @ObservedObject var musicPlayer = MusicPlayer.shared
    @Environment(\.dismiss) private var dismiss
    
    @State private var selectedMinutes: Double = 15
    @State private var contentHeight: CGFloat = 0
    
    var body: some View {
        ZStack {
            Color.black // Using black background instead of Theme.Colors.background for now
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // MARK: - Header
                HStack {
                    Color.clear
                            .frame(width: 44, height: 44)
                    Spacer()
                    Text("Sleep Timer")
                        .font(.title2)
                        .foregroundColor(.white)
                    Spacer()
                    
                    Button(action: { dismiss() }) {
                        Image(systemName: "xmark")
                            .font(.system(size: 18, weight: .bold))
                            .foregroundColor(.white.opacity(0.8))
                            .frame(width: 44, height: 44)
                                        .contentShape(Rectangle())
                    }
                }
                .padding(.horizontal, 24)
                .padding(.top, 20)
                .padding(.bottom, 16)
                
                // MARK: - Main Display
                VStack(spacing: 8) {
                    Text("Stop Audio In")
                        .font(.subheadline)
                        .foregroundColor(.white.opacity(0.6))
                    
                    if let remaining = musicPlayer.sleepTimerTimeRemaining {
                        Text(formatTime(remaining))
                            .font(.system(size: 48, weight: .bold))
                            .foregroundColor(.white)
                    } else {
                        Text("\(Int(selectedMinutes)) min")
                            .font(.system(size: 48, weight: .bold))
                            .foregroundColor(.white)
                    }
                }
                .padding(.bottom, 24)
                
                // MARK: - Slider
                VStack(spacing: 8) {
                    Slider(value: $selectedMinutes, in: 0...120, step: 1)
                        .accentColor(AivoTheme.Primary.orange)
                        .padding(.horizontal, 24)
                        .onAppear {
                            let circleSize: CGFloat = 20
                            let thumbImage = UIImage.circle(diameter: circleSize, color: .white)
                            UISlider.appearance().setThumbImage(thumbImage, for: .normal)
                        }
                    
                    HStack {
                        Text("0 min")
                        Spacer()
                        Text("120 min")
                    }
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.4))
                    .padding(.horizontal, 24)
                }
                .padding(.bottom, 24)
                
                // MARK: - Quick Select Buttons
                HStack(spacing: 16) {
                    ForEach([15, 30, 45, 60], id: \.self) { min in
                        Button(action: {
                            selectedMinutes = Double(min)
                        }) {
                            VStack(spacing: 4) {
                                Image(systemName: "clock")
                                    .font(.system(size: 20))
                                Text("\(min)m")
                                    .font(.system(size: 14, weight: .medium))
                            }
                            .foregroundColor(.white.opacity(0.8))
                            .frame(maxWidth: .infinity)
                            .frame(height: 70)
                            .background(
                                RoundedRectangle(cornerRadius: 16)
                                    .fill(Color.white.opacity(0.1))
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 16)
                                            .stroke(selectedMinutes == Double(min) ? AivoTheme.Primary.orange : Color.clear, lineWidth: 2)
                                    )
                            )
                        }
                    }
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 24)
                
                // MARK: - Action Button
                Button(action: {
                    if musicPlayer.sleepTimerTimeRemaining != nil {
                        musicPlayer.cancelSleepTimer()
                    } else {
                        if selectedMinutes > 0 {
                            musicPlayer.startSleepTimer(minutes: Int(selectedMinutes))
                            dismiss()
                        }
                    }
                }) {
                    Text(musicPlayer.sleepTimerTimeRemaining != nil ? "Cancel Timer" : "Start Timer")
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 56)
                        .background(
                            RoundedRectangle(cornerRadius: 28)
                                .fill(musicPlayer.sleepTimerTimeRemaining != nil ? Color.red.opacity(0.8) : AivoTheme.Primary.orange)
                        )
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 4)
            }
        }
        .onAppear {
            if let remaining = musicPlayer.sleepTimerTimeRemaining {
                selectedMinutes = remaining / 60
            }
        }
    }
    
    private func formatTime(_ seconds: TimeInterval) -> String {
        let m = Int(seconds) / 60
        let s = Int(seconds) % 60
        return String(format: "%02d:%02d", m, s)
    }
}

// MARK: - UIImage Extension for Custom Slider Thumb
extension UIImage {
    static func circle(diameter: CGFloat, color: UIColor) -> UIImage {
        UIGraphicsBeginImageContextWithOptions(CGSize(width: diameter, height: diameter), false, 0)
        let ctx = UIGraphicsGetCurrentContext()!
        ctx.saveGState()

        let rect = CGRect(x: 0, y: 0, width: diameter, height: diameter)
        ctx.setFillColor(color.cgColor)
        ctx.fillEllipse(in: rect)

        ctx.restoreGState()
        let img = UIGraphicsGetImageFromCurrentImageContext()!
        UIGraphicsEndImageContext()

        return img
    }
}
