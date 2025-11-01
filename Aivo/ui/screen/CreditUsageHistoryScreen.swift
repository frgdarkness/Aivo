//
//  CreditUsageHistoryScreen.swift
//  Aivo
//
//  Created by AI Assistant
//

import SwiftUI

struct CreditUsageHistoryScreen: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject private var historyManager = CreditHistoryManager.shared
    
    // Preview mode với hard-coded data
    #if DEBUG
    private let isPreviewMode = false
    private var previewData: [RequestData] {
        let calendar = Calendar.current
        let now = Date()
        
        return [
            RequestData(requestType: .generateSong, time: now),
            RequestData(requestType: .generateLyric, time: calendar.date(byAdding: .hour, value: -2, to: now) ?? now),
            RequestData(requestType: .coverSong, time: calendar.date(byAdding: .day, value: -1, to: now) ?? now),
            RequestData(requestType: .generateSong, time: calendar.date(byAdding: .day, value: -2, to: now) ?? now),
            RequestData(requestType: .generateLyric, time: calendar.date(byAdding: .day, value: -3, to: now) ?? now),
            RequestData(requestType: .coverSong, time: calendar.date(byAdding: .day, value: -5, to: now) ?? now),
            RequestData(requestType: .generateSong, time: calendar.date(byAdding: .day, value: -7, to: now) ?? now),
            RequestData(requestType: .generateLyric, time: calendar.date(byAdding: .day, value: -10, to: now) ?? now),
        ]
    }
    #endif
    
    var body: some View {
        ZStack {
            // Background
            AivoSunsetBackground()
            
            VStack(spacing: 0) {
                // Header
                headerView
                
                // History List
                historyListView
            }
        }
    }
    
    // MARK: - Header View
    private var headerView: some View {
        HStack {
            // Back Button
            Button(action: {
                dismiss()
            }) {
                Image(systemName: "chevron.left")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(.white)
                    .padding(12)
                    .background(Color.white.opacity(0.1))
                    .clipShape(Circle())
            }
            
            Text("Credit Usage History")
                .font(.system(size: 20, weight: .bold))
                .foregroundColor(.white)
            
            Spacer()
        }
        .padding(.horizontal, 20)
        .padding(.top, 10)
        .padding(.bottom, 20)
    }
    
    // MARK: - History List View
    private var historyListView: some View {
        #if DEBUG
        let displayData = isPreviewMode ? previewData : historyManager.history
        #else
        let displayData = historyManager.history
        #endif
        
        return ScrollView {
            LazyVStack(spacing: 12) {
                if displayData.isEmpty {
                    // Empty State
                    VStack(spacing: 16) {
                        Image(systemName: "clock.arrow.circlepath")
                            .font(.system(size: 48))
                            .foregroundColor(.white.opacity(0.5))
                            .padding(.top, 100)
                        
                        Text("No History Yet")
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundColor(.white)
                        
                        Text("Your credit usage history will appear here")
                            .font(.system(size: 14))
                            .foregroundColor(.white.opacity(0.7))
                    }
                } else {
                    ForEach(displayData) { request in
                        historyItemView(request)
                    }
                }
            }
            .padding(.horizontal, 20)
            .padding(.top, 10)
            .padding(.bottom, 100)
        }
    }
    
    // MARK: - History Item View
    private func historyItemView(_ request: RequestData) -> some View {
        HStack(spacing: 16) {
            // Left: Request Name
            Text(request.requestType.displayName)
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(.white)
            
            Spacer()
            
            // Middle: Time
            Text(formatTime(request.time))
                .font(.system(size: 14))
                .foregroundColor(.white.opacity(0.7))
            
            // Right: Credit Cost with Icon
            HStack(spacing: 4) {
                Text("\(request.requestType.creditCost)")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(Color(red: 1.0, green: 0.85, blue: 0.4))
                
                Image("icon_coin")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 16, height: 16)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
        .background(Color.white.opacity(0.1))
        .cornerRadius(12)
    }
    
    // MARK: - Helper Methods
    private func formatTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "hh:mm dd/MM/yyyy"
        return formatter.string(from: date)
    }
}

#Preview {
    CreditUsageHistoryScreen()
}

