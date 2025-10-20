//
//  MyLocalizable.swift
//  DreamHomeAI
//
//  Created by AI Assistant on 2025-01-01.
//

import Foundation

// MARK: - MyLocalizable
/// Centralized localization keys mapping to Localizable.xcstrings
enum MyLocalizable {
    
    // MARK: - Common UI Elements
    static let language = "Language"
    static let done = "Done"
    static let cancel = "Cancel"
    static let save = "Save"
    static let delete = "Delete"
    static let edit = "Edit"
    static let back = "Back"
    static let next = "Next"
    static let previous = "Previous"
    static let close = "Close"
    static let ok = "OK"
    static let yes = "Yes"
    static let no = "No"
    static let later = "Later"
    static let retry = "Retry"
    static let success = "Success"
    static let error = "Error"
    static let loading = "LOADING..."
    static let processing = "Processing..."
    static let comingSoon = "Coming soon"
    static let comingSoonTitle = "Coming Soon"
    
    // MARK: - Language Names
    static let english = "English"
    static let vietnamese = "Vietnamese"
    static let french = "French"
    static let spanish = "Spanish"
    static let german = "German"
    static let japanese = "Japanese"
    static let korean = "Korean"
    static let chineseSimplified = "Chinese Simplified"
    static let chineseTraditional = "Chinese Traditional"
    static let portuguese = "Portuguese"
    static let italian = "Italian"
    static let russian = "Russian"
    static let arabic = "Arabic"
    
    // MARK: - App Information
    static let dreamHomeAI = "DreamHomeAI"
    static let dreamHomeAITitle = "DreamHome AI"
    static let appVersion = "App Version"
    static let lastUpdated = "Last Updated"
    static let created = "Created"
    static let profileID = "Profile ID"
    static let userProfile = "User Profile"
    static let userCredits = "User Credits"
    static let currentCredits = "Current Credits"
    static let totalCredits = "Total Credits"
    static let yourCredit = "Your Credit"
    
    // MARK: - Language Selection
    static let selectLanguage = "Select Language"
    static let languageSelectionExample = "Language Selection Example"
    static let currentLanguage = "Current Language: %@"
    static let languageNames = "Language Names:"
    static let languageColon = "Language:"
    static let doneColon = "Done:"
    static let cancelColon = "Cancel:"
    static let commonUIElements = "Common UI Elements:"
    
    // MARK: - Restart App
    static let restartRequired = "Restart Required"
    static let restartApp = "Restart App"
    static let pleaseRestartApp = "Please restart the app to apply the new language setting."
    
    // MARK: - Home Screen
    static let designYourDreamHome = "Design your dream home"
    static let loadingSavedDesigns = "Loading saved designs..."
    static let noSavedDesignsYet = "No saved designs yet"
    static let generateDesignsToSeeThemHere = "Generate designs to see them here"
    static let redesignAndBeautifyYourHome = "Redesign and beautify your home"
    static let splashDescription = "splash.desription"
    
    // MARK: - Tools Tab
    static let tryIt = "Try It!"
    static let comingSoonTools = "Coming soon"
    
    // MARK: - Main Features
    static let interiorDesign = "Interior Design"
    static let exteriorDesign = "Exterior Design"
    static let sketchToDesign = "Sketch To Design"
    static let removeObject = "Remove Object"
    static let replaceObject = "Replace Object"
    static let itemDecorator = "Item Decorator"
    static let paint = "Paint"
    static let floorSwap = "Floor Swap"
    
    // MARK: - Feature Descriptions
    static let uploadPicChooseStyle = "Upload a pic, choose a style, let AI design the room!"
    static let transformBuildingExterior = "Transform your building's exterior with AI-powered design."
    static let turnHandDrawnSketches = "Turn your hand-drawn sketches into stunning realistic designs."
    static let seamlesslyRemoveObjects = "Seamlessly remove unwanted objects from your photos."
    static let replaceFurnitureDecor = "Replace furniture and decor with AI-suggested alternatives."
    static let decorateEmptyRooms = "Decorate empty or sparse rooms by adding furniture and decor."
    static let changeWallPaintColors = "Change wall paint colors to explore different palettes."
    static let swapFlooringTypes = "Swap flooring types to preview wood, tile, or carpet styles."
    
    // MARK: - Difficulty Levels
    static let easy = "Easy"
    static let medium = "Medium"
    static let advanced = "Advanced"
    
    // MARK: - Processing Times
    static let oneToTwoMinutes = "1-2 minutes"
    static let oneToThreeMinutes = "1-3 minutes"
    static let twoToThreeMinutes = "2-3 minutes"
    static let twoToFourMinutes = "2-4 minutes"
    static let threeToFiveMinutes = "3-5 minutes"
    
    // MARK: - Credits & Purchases
    static let credits = "credits"
    static let buyCredit = "Buy CREDIT"
    static let getFree = "Get FREE"
    static let getFreeCredit = "Get Free Credit"
    static let getFreeCreditTitle = "GET FREE CREDIT"
    static let notEnoughCredit = "NOT ENOUGH CREDIT"
    static let notEnoughCredits = "Not Enough Credits"
    static let youDontHaveEnoughCredits = "You don't have enough credits to make this request. "
    static let creditsAreUsed = "Credits are used to generate or edit designs with premium quality and faster processing."
    static let oneRequestThirtyCredits = "1 request = 30 credits"
    static let currentCreditsFormat = "Current Credits: %lld"
    static let creditsFormat = "%lld Credits"
    static let creditsFormatTitle = "%lld CREDITS"
    static let purchaseError = "Purchase Error"
    static let purchaseHistory = "Purchase History"
    static let noPurchasesYet = "No purchases yet"
    static let yourPurchaseHistoryWillAppearHere = "Your purchase history will appear here"
    static let purchaseIDCopiedToClipboard = "Purchase ID copied to clipboard"
    static let profileIDCopiedToClipboard = "Profile ID copied to clipboard"
    
    // MARK: - Actions & Buttons
    static let continueAction = "Continue"
    static let continueTitle = "CONTINUE"
    static let getStarted = "Get Started"
    static let startRedesigning = "Start Redesigning"
    static let startSketching = "Start Sketching"
    static let generateDesign = "GENERATE DESIGN"
    static let generateByFreeServer = "GENERATE BY FREE SERVER"
    static let bestOffer = "BEST OFFER"
    static let bestExperienceWithPremium = "Best experience with PREMIUM server!"
    static let completeActionsBelow = "Complete actions below to receive free credits."
    static let completeActionsBelowToEarn = "Complete the actions below to earn free credits."
    
    // MARK: - Image & Media
    static let addAPhoto = "Add a Photo"
    static let addItem = "Add Item"
    static let chooseAnImage = "Choose an image from your gallery"
    static let selectAnImage = "Select an Image"
    static let selectImage = "Select Image"
    static let selectAnItem = "Select an item"
    static let examplePhotos = "Example Photos"
    static let examplePrompt = "Example Prompt"
    static let examplePrompts = "Example prompts"
    static let chooseAColorPalette = "Choose a color palette to bring your vision to life! Select from curated shades to transform your space."
    
    // MARK: - Design & Style
    static let designWithPrompt = "Design with prompt"
    static let textToDesign = "Text to Design"
    static let chooseRoom = "Choose Room"
    static let chooseBuildingType = "Choose Building Type"
    static let selectStyle = "Select Style"
    static let selectPalette = "Select Palette"
    static let pickColor = "Pick Color"
    static let brushFormat = "Brush: %lld"
    static let stepTwoFormat = "Step %lld/2"
    static let stepFourFormat = "Step %lld/4"
    
    // MARK: - Prompts & Descriptions
    static let enterPrompt = "Enter prompt"
    static let enterPromptTitle = "Enter Prompt"
    static let enterCredits = "Enter credits"
    static let enterWhatYouWantToReplace = "Enter what you want to replace"
    static let whatDoYouWantToReplaceItWith = "What do you want to replace it with?"
    static let tryThisPrompt = "Try this prompt"
    static let typeHereDetailedDescription = "Type here a detailed description of what you want to see in your home design"
    static let uploadYourSketch = "Upload your sketch to transform it into a design"
    static let selectARoomToDecorate = "Select a room to decorate using AI prompts"
    static let selectARoomToDesign = "Select a room to design and see it transformed in your chosen style."
    static let selectTheBuildingType = "Select the building type to transform its exterior in your chosen style."
    static let selectYourDesiredDesignStyle = "Select your desired design style for decoration"
    static let selectYourDesiredDesignStyleInterior = "Select your desired design style to start creating your ideal interior"
    static let selectYourDesiredExteriorStyle = "Select your desired exterior style to start creating your ideal facade"
    
    // MARK: - Ads & Monetization
    static let bannerAd = "Banner Ad"
    static let nativeAd = "Native Ad"
    static let interstitialResult = "Interstitial Result: %@"
    static let rewardedResult = "Rewarded Result: %@"
    static let showInterstitialAd = "Show Interstitial Ad"
    static let showRewardedAd = "Show Rewarded Ad"
    static let watchAd = "Watch Ad"
    static let watchAShortAd = "Watch a short ad to remove the watermark from your image."
    static let removeWatermark = "Remove Watermark"
    static let watermarkRemoved = "✓ Watermark Removed"
    static let testAds = "Test Ads"
    static let adTesting = "Ad Testing"
    
    // MARK: - Admin & Settings
    static let admin = "Admin"
    static let adminTools = "Admin Tools"
    static let setCredit = "Set Credit"
    static let refreshData = "Refresh Data"
    static let refreshDataSuccess = "Refresh data success!"
    static let clearData = "Clear Data"
    static let clearData2 = "Clear Data 2"
    static let clear = "Clear"
    static let share = "Share"
    static let report = "Report"
    static let copied = "Copied"
    static let itemAtFormat = "Item at %@"
    static let idFormat = "ID: %@"
    
    // MARK: - Data Management
    static let thisWillClearAllData = "This will clear all data except intro and language settings. This action cannot be undone."
    static let thisWillClearAllOnboardingData = "This will clear all onboarding data. This action cannot be undone."
    
    // MARK: - Login & Authentication
    static let login = "Login"
    static let loginFeatureComingSoon = "Login feature is coming soon!"
    
    // MARK: - Status & Results
    static let result = "Result"
    static let mostPopular = "Most Popular"
    static let nA = "N/A"
    
    // MARK: - Format Strings
    static let brushFormatString = "Brush: %lld"
    static let stepTwoFormatString = "Step %lld/2"
    static let stepFourFormatString = "Step %lld/4"
    static let currentCreditsFormatString = "Current Credits: %lld"
    static let creditsFormatString = "%lld Credits"
    static let creditsFormatTitleString = "%lld CREDITS"
    static let interstitialResultFormat = "Interstitial Result: %@"
    static let rewardedResultFormat = "Rewarded Result: %@"
    static let currentLanguageFormat = "Current Language: %@"
    static let itemAtFormatString = "Item at %@"
    static let idFormatString = "ID: %@"
    static let dreamHomeAIVersionFormat = "DreamHomeAI\nVersion %@\nBuild %@"
    static let brushFormatStringValue = "Brush: %lld"
    static let stepTwoFormatStringValue = "Step %lld/2"
    static let stepFourFormatStringValue = "Step %lld/4"
    static let currentCreditsFormatStringValue = "Current Credits: %lld"
    static let creditsFormatStringValue = "%lld Credits"
    static let creditsFormatTitleStringValue = "%lld CREDITS"
    static let interstitialResultFormatValue = "Interstitial Result: %@"
    static let rewardedResultFormatValue = "Rewarded Result: %@"
    static let currentLanguageFormatValue = "Current Language: %@"
    static let itemAtFormatStringValue = "Item at %@"
    static let idFormatStringValue = "ID: %@"
    static let dreamHomeAIVersionFormatValue = "DreamHomeAI\nVersion %@\nBuild %@"
    
    // MARK: - Bottom Navigation
    static let tools = "Tools"
    static let create = "Create"
    static let dashboard = "Dashboard"
    
    // MARK: - Drawer Menu
    static let home = "Home"
    static let myDesigns = "My Designs"
    static let favorites = "Favorites"
    static let shareApp = "Share App"
    static let rateApp = "Rate App"
    static let settings = "Settings"
    static let helpSupport = "Help & Support"
    static let about = "About"
    static let signOut = "Sign Out"
    
    // MARK: - Toast Messages
    static let copiedToClipboard = "Copied to clipboard"
    static let savedToPhotos = "Saved to Photos"
    static let saveFailed = "Save failed"
    static let photoAccessDenied = "Photo access denied"
    static let photoAccessError = "Photo access error"
    static let adFailedToLoad = "Ad failed to load"
    
    // MARK: - Intro Slides
    static let introSlide1Title = "Redesign your home quickly and easy"
    static let introSlide1Description = "Transform your living space with AI-powered interior design. Get professional results in minutes, not hours."
    static let introSlide2Title = "Edit Your Space Like Magic"
    static let introSlide2Description = "Remove unwanted objects, replace furniture, and change styles with just a few taps. Your dream home is just a click away."
    static let introSlide3Title = "Let's design your Dream Home"
    static let introSlide3Description = "Start your journey to the perfect home. Create stunning interiors that reflect your unique style and personality."
    
    // MARK: - Buy Credit Screen
    static let unlockAllFeatures = "Unlock all features and data"
    static let processedOnUltraServers = "Processed on Ultra Servers"
    static let boostProcessingSpeed = "Boost processing x10 speed"
    static let premiumDesignQuality = "Premium design quality"
    static let productNotAvailable = "Product not available. Please try again later."
    
    // MARK: - Credit Dialog
    static let creditsDescription = "Credits are used to generate or edit designs with premium quality and faster processing."
    static let higherQualityOutputs = "Higher quality outputs"
    static let priorityInQueue = "Priority in queue (x10 speed)"
    static let unlockAllDesignTools = "Unlock all design tools"
    
    // MARK: - Empty Strings (for placeholders)
    static let emptyString = ""
    static let emptyStringWithDash = "(-30"
    static let emptyStringWithParenthesis = ")"
    static let emptyStringWithPercent = "%lld"
}

// MARK: - Usage Examples
/*
 Usage Examples:
 
 // Basic usage
 Text(MyLocalizable.dreamHomeAI.localized)
 
 // With parameters
 Text(String(format: MyLocalizable.currentCreditsFormat.localized, 100))
 
 // In buttons
 Button(MyLocalizable.ok.localized) { }
 
 // In alerts
 .alert(MyLocalizable.restartRequired.localized, isPresented: $showAlert) {
     Button(MyLocalizable.restartApp.localized) { }
     Button(MyLocalizable.later.localized, role: .cancel) { }
 }
 */
