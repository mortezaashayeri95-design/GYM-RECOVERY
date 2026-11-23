import SwiftUI

enum Theme {
    /// #C8F031, primary actions, rest ring and highlights.
    static let accent = Color(red: 0.78, green: 0.94, blue: 0.19)
    /// #121405, text on accent-colored buttons.
    static let onAccent = Color(red: 0.07, green: 0.08, blue: 0.02)
    /// #FF8A3D, effort.
    static let effort = Color(red: 1.0, green: 0.54, blue: 0.24)
    /// #3CC8F0, recovery.
    static let recovery = Color(red: 0.24, green: 0.78, blue: 0.94)
    /// #A770FF, milestones and challenges.
    static let milestone = Color(red: 0.65, green: 0.44, blue: 1.0)
    /// #FF5A6E, heart rate.
    static let heart = Color(red: 1.0, green: 0.35, blue: 0.43)
    /// #0D0F12, screen background.
    static let background = Color(red: 0.05, green: 0.06, blue: 0.07)
    /// #17191D, cards.
    static let card = Color(red: 0.09, green: 0.10, blue: 0.11)
    /// #23262B, rows inside cards.
    static let cardInner = Color(red: 0.14, green: 0.15, blue: 0.17)
    /// #9CA0A8, secondary text.
    static let secondaryText = Color(red: 0.61, green: 0.63, blue: 0.66)

    /// Large condensed numbers, like the rest timer and heart rate.
    static func display(_ size: CGFloat) -> Font {
        .system(size: size, weight: .heavy).width(.condensed)
    }
}
