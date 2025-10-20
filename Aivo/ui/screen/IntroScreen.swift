//
//  IntroScreen.swift
//  DreamHomeAI
//
//  Created by AI Assistant on 2025-01-01.
//

import SwiftUI

struct IntroScreen: View {
    let onIntroCompleted: () -> Void
    
    @State private var currentPage = 0
    private let introSlides = IntroSlideData.introSlides
    
    var body: some View {
        ZStack {
            // Background gradient
            LinearGradient(
                gradient: Gradient(colors: [
                    Color(red: 0.95, green: 0.95, blue: 1.0),
                    Color.white
                ]),
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Skip button
//                HStack {
//                    Spacer()
//                    Button("Skip") {
//                        onIntroCompleted()
//                    }
//                    .foregroundColor(.gray)
//                    .font(.body)
//                    .padding(.trailing, 20)
//                    .padding(.top, 10)
//                }
                
                // Page content
                TabView(selection: $currentPage) {
                    ForEach(0..<introSlides.count, id: \.self) { index in
                        introSlideView(introSlides[index])
                            .tag(index)
                    }
                }
                .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
                .animation(.easeInOut, value: currentPage)
                
                // Page indicators
                pageIndicators
                
                // Next button
                nextButton
                    .padding(.horizontal, 20)
                    .padding(.bottom, 50)
            }
        }
        .onAppear {
            // Log screen view
            FirebaseLogger.shared.logScreenView(FirebaseLogger.EVENT_SCREEN_INTRO)
        }
    }
    
    // MARK: - Intro Slide View
    private func introSlideView(_ slide: IntroSlideData) -> some View {
        VStack(spacing: 0) {
            // Fixed image section at top - always same height and position
            ZStack {
                // Main phone mockup - fixed size and position
                Image(slide.imageName)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 300, height: 400) // Fixed size for consistency
                    .cornerRadius(20)
                    .shadow(color: .black.opacity(0.2), radius: 10, x: 0, y: 5)
                
                // Floating theme cards (similar to design)
                if slide.imageName == "intro_3" {
                    floatingThemeCards
                }
            }
            .frame(height: 320) // Fixed height for image section
            .padding(.top, 40) // Fixed top padding
            
            // Flexible content section - can expand/contract based on text length
            VStack(spacing: 16) {
                Text(slide.title)
                    .font(.title)
                    .fontWeight(.bold)
                    .foregroundColor(.black)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 20)
                    .fixedSize(horizontal: false, vertical: true) // Allow text to expand vertically
                
                Text(slide.description)
                    .font(.body)
                    .foregroundColor(.gray)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 30)
                    .fixedSize(horizontal: false, vertical: true) // Allow text to expand vertically
            }
            .padding(.top, 30) // Fixed spacing from image
            .frame(maxWidth: .infinity) // Take full width
            
            // Fixed spacer to push content up consistently
            Spacer(minLength: 60) // Minimum space at bottom
        }
    }
    
    // MARK: - Floating Theme Cards
    private var floatingThemeCards: some View {
        ZStack {
            // Ready For It card
            
        }
    }
    
    // MARK: - Page Indicators
    private var pageIndicators: some View {
        HStack(spacing: 8) {
            ForEach(0..<introSlides.count, id: \.self) { index in
                Circle()
                    .fill(currentPage == index ? Color.purple : Color.gray.opacity(0.3))
                    .frame(width: 8, height: 8)
                    .animation(.easeInOut, value: currentPage)
            }
        }
        .padding(.bottom, 30)
    }
    
    // MARK: - Next Button
    private var nextButton: some View {
        Button(action: {
            if currentPage < introSlides.count - 1 {
                withAnimation {
                    currentPage += 1
                }
            } else {
                onIntroCompleted()
            }
        }) {
            Text(currentPage == introSlides.count - 1 ? "Get Started" : "Next")
                .font(.headline)
                .fontWeight(.semibold)
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .frame(height: 56)
                .background(
                    LinearGradient(
                        gradient: Gradient(colors: [
                            Color.orange,
                            Color.pink
                        ]),
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .cornerRadius(28)
        }
    }
}

#Preview {
    IntroScreen {
        Logger.d("Intro completed")
    }
}
