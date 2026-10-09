import SwiftUI

public enum AppTheme {
    public static let bgDark = Color(red: 11/255, green: 15/255, blue: 25/255)
    public static let surfaceCard = Color(red: 21/255, green: 30/255, blue: 46/255)
    public static let surfaceCardElevated = Color(red: 30/255, green: 41/255, blue: 59/255)
    public static let borderStroke = Color(red: 43/255, green: 57/255, blue: 80/255)
    
    public static let cyanNeon = Color(red: 6/255, green: 182/255, blue: 212/255)
    public static let cyanGlow = Color(red: 34/255, green: 211/255, blue: 238/255)
    public static let emeraldGreen = Color(red: 16/255, green: 185/255, blue: 129/255)
    public static let amberWarm = Color(red: 245/255, green: 158/255, blue: 11/255)
    public static let roseHot = Color(red: 244/255, green: 63/255, blue: 94/255)
    public static let purpleAccent = Color(red: 139/255, green: 92/255, blue: 246/255)
    
    public static let textPrimary = Color(red: 248/255, green: 250/255, blue: 252/255)
    public static let textSecondary = Color(red: 148/255, green: 163/255, blue: 184/255)
    public static let textMuted = Color(red: 100/255, green: 116/255, blue: 139/255)
    
    public static func temperatureColor(_ temp: Float) -> Color {
        switch temp {
        case ..<18.0:
            return cyanNeon
        case 18.0...25.5:
            return emeraldGreen
        case 25.5...30.0:
            return amberWarm
        default:
            return roseHot
        }
    }
    
    public static func batteryColor(_ battery: Int) -> Color {
        if battery >= 60 { return emeraldGreen }
        if battery >= 25 { return amberWarm }
        return roseHot
    }
    
    public static func rssiColor(_ rssi: Int) -> Color {
        if rssi >= -65 { return emeraldGreen }
        if rssi >= -78 { return cyanNeon }
        if rssi >= -88 { return amberWarm }
        return roseHot
    }
}
