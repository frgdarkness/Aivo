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
            RequestData(requestType: .generateSong, time: now, creditCost: 20),
            RequestData(requestType: .generateLyric, time: calendar.date(byAdding: .hour, value: -2, to: now) ?? now, creditCost: 4),
            RequestData(requestType: .coverSong, time: calendar.date(byAdding: .day, value: -1, to: now) ?? now, creditCost: 10),
            RequestData(requestType: .bonusPremiumWeekly, time: calendar.date(byAdding: .day, value: -2, to: now) ?? now, creditCost: 1000),
            RequestData(requestType: .weeklyReward, time: calendar.date(byAdding: .day, value: -3, to: now) ?? now, creditCost: 500),
            RequestData(requestType: .buyCredits1000, time: calendar.date(byAdding: .day, value: -5, to: now) ?? now, creditCost: 1000),
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
        .onAppear {
            // Log screen view
            AnalyticsLogger.shared.logScreenView(AnalyticsLogger.EVENT.EVENT_SCREEN_CREDIT_HISTORY)
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
        
        // Filter out shareSong entries (deprecated)
        let filteredData = displayData.filter { $0.requestType != .shareSong }
        
        return ScrollView {
            LazyVStack(spacing: 12) {
                if filteredData.isEmpty {
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
                    ForEach(filteredData) { request in
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
        let isCredit = request.requestType.isCredit
        let prefix = isCredit ? "+" : "-"
        let creditColor = isCredit ? Color.green : Color(red: 1.0, green: 0.85, blue: 0.4)
        
        return HStack(spacing: 16) {
            // Left: Request Name
            VStack(alignment: .leading, spacing: 2) {
                Text(request.requestType == .weeklyReward ? weeklyRewardDisplayName(request) : request.requestType.displayName)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.white)
                    .lineLimit(1)
                
                Text(formatTime(request.time))
                    .font(.system(size: 12))
                    .foregroundColor(.white.opacity(0.5))
            }
            
            Spacer()
            
            // Right: Credit Cost with Icon
            HStack(spacing: 4) {
                Text("\(prefix)\(request.creditCost)")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(creditColor)
                
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
    
    private func weeklyRewardDisplayName(_ request: RequestData) -> String {
        // Could be customized with week tag if stored, for now generic
        return "Weekly Reward"
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

