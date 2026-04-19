/// GemIcons.swift
/// Purpose: Maps prototype icon-name tokens to SF Symbol names. All icon references
///   flow through this file so tag/icon choices remain consistent across the app.
/// Dependencies: SwiftUI.
/// Key concepts:
///   - `all` lists every picker-visible icon in menu order, matching `TAG_ICONS` in
///     `gem-app/tags.jsx`.
///   - `tagHues` lists every picker-visible hue in palette order (OKLCH hue angles).
///   - App-chrome icons (chevrons, checkmark, trash, etc.) are included in `sfSymbol`
///     but intentionally omitted from `all` — they are not offered in the tag picker.
///   - Unknown names fall back to `questionmark.circle` rather than crashing.

import SwiftUI

/// Maps the prototype's icon-name tokens (from `gem-app/tags.jsx` TAG_ICONS)
/// to SF Symbol names. Centralized so tag/icon choices stay consistent across
/// the app. Missing mappings fall back to `questionmark.circle`.
enum GemIcons {

    /// Every icon name the prototype uses, in menu order.
    static let all: [String] = [
        "sun", "snow", "leaf", "plane", "case", "laptop",
        "home-icon", "cart", "dumbbell", "flame", "moon",
        "globe", "sparkle", "tag",
    ]

    /// Every tag hue the prototype offers, in palette order. Each value is an
    /// OKLCH hue angle (0–360).
    static let tagHues: [Double] = [300, 250, 210, 170, 135, 85, 45, 20, 350]

    static func sfSymbol(for name: String) -> String {
        switch name {
        case "sun":        return "sun.max.fill"
        case "snow":       return "snowflake"
        case "leaf":       return "leaf.fill"
        case "plane":      return "airplane"
        case "case":       return "briefcase.fill"
        case "laptop":     return "laptopcomputer"
        case "home-icon":  return "house.fill"
        case "cart":       return "cart.fill"
        case "dumbbell":   return "dumbbell.fill"
        case "flame":      return "flame.fill"
        case "moon":       return "moon.fill"
        case "globe":      return "globe"
        case "sparkle":    return "sparkle"
        case "tag":        return "tag.fill"
        // App chrome icons — not in the tag picker, but used by other screens
        case "more":       return "ellipsis"
        case "back":       return "chevron.left"
        case "right":      return "chevron.right"
        case "down":       return "chevron.down"
        case "check":      return "checkmark"
        case "plus":       return "plus"
        case "trash":      return "trash.fill"
        case "edit":       return "pencil"
        case "history":    return "clock.arrow.circlepath"
        case "archive":    return "archivebox.fill"
        case "stack":      return "square.stack.3d.up.fill"
        case "eye-off":    return "eye.slash.fill"
        default:           return "questionmark.circle"
        }
    }

    static func image(_ name: String) -> Image {
        Image(systemName: sfSymbol(for: name))
    }
}
