import SwiftUI

struct AdminScreen: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject private var creditManager = CreditManager.shared
    @State private var inputText: String = ""
    @State private var showTestAdScreen = false
    @State private var showClearDataAlert = false
    @State private var showClearData2Alert = false
    
    var body: some View {
        NavigationView {
            VStack(alignment: .leading, spacing: 16) {
                Text("Current Credits: \(creditManager.credits)")
                    .font(.system(size: 18, weight: .semibold))
                
                TextField("Enter credits", text: $inputText)
                    .keyboardType(.numberPad)
                    .padding()
                    .background(Color(.secondarySystemBackground))
                    .cornerRadius(10)
                
                Button(action: {
                    if let value = Int(inputText) {
                        creditManager.setCredits(value)
                        dismiss()
                    }
                }) {
                    Text("Set Credit")
                        .frame(maxWidth: .infinity)
                        .padding()
                        .foregroundColor(.white)
                        .background(Color.blue)
                        .cornerRadius(12)
                }
                
                Divider()
                    .padding(.vertical, 8)
                
                // Admin Tools Section
                VStack(alignment: .leading, spacing: 12) {
                    Text("Admin Tools")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(.primary)
                    
                    Button(action: {
                        showTestAdScreen = true
                    }) {
                        HStack {
                            Image(systemName: "testtube.2")
                                .foregroundColor(.orange)
                            Text("Test Ads")
                                .foregroundColor(.primary)
                            Spacer()
                            Image(systemName: "chevron.right")
                                .foregroundColor(.secondary)
                                .font(.system(size: 12))
                        }
                        .padding()
                        .background(Color(.secondarySystemBackground))
                        .cornerRadius(10)
                    }
                    
                    Button(action: {
                        showClearDataAlert = true
                    }) {
                        HStack {
                            Image(systemName: "trash.fill")
                                .foregroundColor(.red)
                            Text("Clear Data")
                                .foregroundColor(.primary)
                            Spacer()
                            Image(systemName: "chevron.right")
                                .foregroundColor(.secondary)
                                .font(.system(size: 12))
                        }
                        .padding()
                        .background(Color(.secondarySystemBackground))
                        .cornerRadius(10)
                    }
                    
                    Button(action: {
                        showClearData2Alert = true
                    }) {
                        HStack {
                            Image(systemName: "trash.circle.fill")
                                .foregroundColor(.red)
                            Text("Clear Data (Skip Intro Language)")
                                .foregroundColor(.primary)
                            Spacer()
                            Image(systemName: "chevron.right")
                                .foregroundColor(.secondary)
                                .font(.system(size: 12))
                        }
                        .padding()
                        .background(Color(.secondarySystemBackground))
                        .cornerRadius(10)
                    }
                }
                
                Spacer()
            }
            .padding(16)
            .navigationTitle("Admin")
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: { dismiss() }) {
                        Image(systemName: "xmark")
                            .font(.system(size: 16, weight: .medium))
                    }
                }
            }
        }
        .alert("Clear Data", isPresented: $showClearDataAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Clear", role: .destructive) {
                UserDefaultsManager.shared.resetOnboarding()
            }
        } message: {
            Text("This will clear all onboarding data. This action cannot be undone.")
        }
        .alert("Clear Data 2", isPresented: $showClearData2Alert) {
            Button("Cancel", role: .cancel) { }
            Button("Clear", role: .destructive) {
                UserDefaultsManager.shared.clearAllDataExceptIntroAndLanguage()
            }
        } message: {
            Text("This will clear all data except intro and language settings. This action cannot be undone.")
        }
        .onAppear {
            // Log screen view
            AnalyticsLogger.shared.logScreenView(AnalyticsLogger.EVENT.EVENT_SCREEN_ADMIN)
        }
    }
}
