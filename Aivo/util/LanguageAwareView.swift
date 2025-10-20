import SwiftUI

/// A wrapper view that refreshes when language changes
struct LanguageAwareView<Content: View>: View {
    @EnvironmentObject private var languageManager: LanguageManager
    @State private var refreshID = UUID()
    let content: () -> Content
    
    init(@ViewBuilder content: @escaping () -> Content) {
        self.content = content
    }
    
    var body: some View {
        content()
            .id(refreshID)
            .environment(\.locale, languageManager.locale)
            .onReceive(NotificationCenter.default.publisher(for: Notification.Name("LanguageChanged"))) { _ in
                withAnimation(.easeInOut(duration: 0.3)) {
                    refreshID = UUID()
                }
            }
    }
}
