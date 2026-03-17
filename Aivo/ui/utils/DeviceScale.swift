import SwiftUI

/// iPad-aware scaling utility for responsive sizing
/// Usage: `Text("Hello").font(.system(size: iPadScale(16)))`
/// On iPhone: returns the original value
/// On iPad: returns the value multiplied by the scale factor (default 1.4x)
struct DeviceScale {
    static let isIPad = UIDevice.current.userInterfaceIdiom == .pad
    
    /// Standard scale factor for text and UI elements on iPad
    static let factor: CGFloat = isIPad ? 1.4 : 1.0
    
    /// Smaller scale for elements that shouldn't grow as much (e.g. spacing)
    static let smallFactor: CGFloat = isIPad ? 1.2 : 1.0
    
    /// Larger scale for elements that need to be much bigger (e.g. cover images)
    static let largeFactor: CGFloat = isIPad ? 1.6 : 1.0
}

/// Quick helper function for scaling values on iPad
func iPadScale(_ value: CGFloat) -> CGFloat {
    return value * DeviceScale.factor
}

/// Quick helper for small scaling (spacing, padding)
func iPadScaleSmall(_ value: CGFloat) -> CGFloat {
    return value * DeviceScale.smallFactor
}

/// Quick helper for large scaling (images, covers)
func iPadScaleLarge(_ value: CGFloat) -> CGFloat {
    return value * DeviceScale.largeFactor
}
