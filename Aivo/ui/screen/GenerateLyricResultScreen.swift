import SwiftUI

struct GenerateLyricResultScreen: View {
    @Environment(\.dismiss) private var dismiss
    
    let results: [LyricsResult]
    @Binding var selectedLyrics: String
    @Binding var selectedSongName: String
    
    // UI State
    @State private var showToast = false
    @State private var toastMessage = ""
    
    var onSelect: ((String, String) -> Void)?
    
    var body: some View {
        ZStack {
            // Background
            AivoSunsetBackground()
            
            VStack(spacing: 0) {
                // Header
                headerView
                    .frame(height: 60)
                
                ScrollView {
                    VStack(spacing: 20) {
                        ForEach(results) { result in
                            lyricsCard(for: result)
                        }
                    }
                    .padding(20)
                    .padding(.bottom, 100)
                }
            }
        }
        .overlay(toastOverlay)
        .navigationBarHidden(true)
    }
    
    // MARK: - Header
    private var headerView: some View {
        HStack {
            Button(action: { dismiss() }) {
                Image(systemName: "arrow.left")
                    .font(.title3)
                    .foregroundColor(.white)
                    .frame(width: 40, height: 40)
                    .background(Color.gray.opacity(0.3))
                    .clipShape(Circle())
            }
            
            Spacer()
            
            Text("Generated Results")
                .font(.headline)
                .foregroundColor(.white)
            
            Spacer()
            
            Button(action: { copyAllLyrics() }) {
                Image(systemName: "doc.on.doc")
                    .font(.system(size: 16))
                    .foregroundColor(.white)
                    .frame(width: 40, height: 40)
                    .background(Color.gray.opacity(0.3))
                    .clipShape(Circle())
            }
        }
        .padding(.horizontal, 20)
        .padding(.top, 10)
        .padding(.bottom, 16)
    }
    
    // MARK: - Lyrics Card
    private func lyricsCard(for result: LyricsResult) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            // Title
            Text(result.title)
                .font(.headline)
                .foregroundColor(AivoTheme.Primary.orange)
            
            // Lyrics Text
            Text(result.text)
                .font(.system(size: 15))
                .foregroundColor(.white.opacity(0.9))
                .lineSpacing(6)
            
            HStack(spacing: 12) {
                // Copy Button
                Button(action: { copyLyrics(result.text, title: result.title) }) {
                    HStack(spacing: 6) {
                        Image(systemName: "doc.on.doc")
                        Text("Copy")
                    }
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 8)
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .fill(Color.white.opacity(0.15))
                    )
                }
                
                // Select Button
                Button(action: { selectLyrics(result.text, title: result.title) }) {
                    HStack(spacing: 6) {
                        Image(systemName: "checkmark.circle.fill")
                        Text("Use This")
                    }
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 8)
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .fill(AivoTheme.Primary.orange)
                    )
                }
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.black.opacity(0.3))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(AivoTheme.Primary.orange.opacity(0.3), lineWidth: 1)
                )
        )
    }
    
    // MARK: - Actions
    private func copyLyrics(_ text: String, title: String) {
        let formattedText = "[\(title)]\n\n\(text)"
        UIPasteboard.general.string = formattedText
        showToastMessage("Lyrics copied to clipboard!")
    }
    
    private func copyAllLyrics() {
        let allText = results.map { "[\($0.title)]\n\n\($0.text)" }
            .joined(separator: "\n\n---\n\n")
        UIPasteboard.general.string = allText
        showToastMessage("All lyrics copied!")
    }
    
    private func selectLyrics(_ text: String, title: String) {
        selectedLyrics = text
        selectedSongName = title
        onSelect?(text, title)
        
        // Dismiss this screen AND the parent GenerateLyricsScreen to go back to previous screen (like CreateSong)
        // Or if the user just wants to go back to GenerateLyricsScreen with the selection?
        // Usually "Use" implies we accept the result.
        // Let's assume we want to pop everything or just dismiss this.
        // If we want to fully support "Use", we might need to communicate back.
        // For now, let's just dismiss this screen, the binding is updated.
        // But wait, if we are in a navigation stack, we might want to go back to root or something.
        
        // Based on existing code: selects and dismisses.
        dismiss()
        // We might need a way to dismiss the parent too if the parent was just a modal for generation.
        // But for now, let's mimic original behavior: select and dismiss.
        // NOTE: The previous code did `dismiss()` which closed `GenerateLyricsScreen`.
        // Now `GenerateLyricResultScreen` is pushed likely.
        // If we want to close `GenerateLyricsScreen` too, we might need a shared binding or environment approach.
        // But let's stick to simple dismiss first.
    }
    
    // MARK: - Toast
    private var toastOverlay: some View {
        VStack {
            Spacer()
            if showToast {
                Text(toastMessage)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.white)
                    .padding(.horizontal, 20)
                    .padding(.vertical, 12)
                    .background(Color.black.opacity(0.8))
                    .cornerRadius(8)
                    .padding(.bottom, 50)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                    .animation(.easeInOut(duration: 0.3), value: showToast)
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
