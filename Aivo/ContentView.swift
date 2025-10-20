//
//  ContentView.swift
//  Aivo
//
//  Created by Huy on 18/10/25.
//

import SwiftUI

struct ContentView: View {
    @StateObject private var themeManager = AivoThemeManager.shared
    
    var body: some View {
        ZStack {
            // Aivo Background with Orange Gradient
            AivoBackgroundView()
            
            // Main Content
            VStack(spacing: 30) {
                // App Logo/Title
                VStack(spacing: 10) {
                    Text("AIVO")
                        .aivoText(.title)
                        .shadow(color: AivoTheme.Shadow.orange, radius: 10, x: 0, y: 0)
                    
                    Text("AI Music Creator")
                        .aivoText(.subtitle)
                        .opacity(0.9)
                }
                .padding(.top, 50)
                
                Spacer()
                
                // Main Action Button
                Button(action: {
                    // TODO: Add main action
                }) {
                    HStack {
                        Image(systemName: "music.note")
                            .font(.title2)
                        Text("Create Music")
                            .font(.headline)
                    }
                }
                .aivoButton(.primary)
                .padding(.horizontal, 40)
                
                // Secondary Actions
                HStack(spacing: 20) {
                    Button(action: {
                        // TODO: Add secondary action
                    }) {
                        VStack {
                            Image(systemName: "waveform")
                                .font(.title2)
                            Text("Generate")
                                .font(.caption)
                        }
                        .frame(width: 80, height: 80)
                    }
                    .aivoButton(.secondary)
                    
                    Button(action: {
                        // TODO: Add secondary action
                    }) {
                        VStack {
                            Image(systemName: "mic")
                                .font(.title2)
                            Text("Record")
                                .font(.caption)
                        }
                        .frame(width: 80, height: 80)
                    }
                    .aivoButton(.secondary)
                    
                    Button(action: {
                        // TODO: Add secondary action
                    }) {
                        VStack {
                            Image(systemName: "music.note.list")
                                .font(.title2)
                            Text("Library")
                                .font(.caption)
                        }
                        .frame(width: 80, height: 80)
                    }
                    .aivoButton(.secondary)
                }
                
                Spacer()
                
                // Bottom Info
                VStack(spacing: 5) {
                    Text("Powered by AI")
                        .aivoText(.muted)
                        .font(.caption)
                    
                    Text("Version 1.0")
                        .aivoText(.muted)
                        .font(.caption2)
                }
                .padding(.bottom, 30)
            }
        }
        .environmentObject(themeManager)
    }
}

#Preview {
    ContentView()
}
