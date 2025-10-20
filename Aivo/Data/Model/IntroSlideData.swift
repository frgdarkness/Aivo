//
//  IntroSlideData.swift
//  DreamHomeAI
//
//  Created by AI Assistant on 2025-01-01.
//

import Foundation

struct IntroSlideData: Identifiable {
    let id = UUID()
    let title: String
    let description: String
    let imageName: String
    
    init(title: String, description: String, imageName: String) {
        self.title = title
        self.description = description
        self.imageName = imageName
    }
}

// MARK: - Static Data
extension IntroSlideData {
    static let introSlides: [IntroSlideData] = [
        IntroSlideData(
            title: "Redesign your home quickly and easy",
            description: "Transform your living space with AI-powered interior design. Get professional results in minutes, not hours.",
            imageName: "intro_1"
        ),
        IntroSlideData(
            title: "Edit Your Space Like Magic",
            description: "Remove unwanted objects, replace furniture, and change styles with just a few taps. Your dream home is just a click away.",
            imageName: "intro_2"
        ),
        IntroSlideData(
            title: "Let's design your Dream Home",
            description: "Start your journey to the perfect home. Create stunning interiors that reflect your unique style and personality.",
            imageName: "intro_3"
        )
    ]
}