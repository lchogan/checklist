/// Tag.swift
/// Purpose: SwiftData model for a filter label applied to Items. App-wide scope.
/// Dependencies: SwiftData, Foundation.
/// Key concepts:
///   - `colorHue` is an OKLCH hue angle (0–360). Chroma and lightness are applied
///     by Theme at render time so all tags have visually consistent saturation.
///   - `iconName` is a design-token key; see `Design/GemIcons.swift` for the map
///     to SF Symbols / custom glyphs.

import Foundation
import SwiftData

/// A filter label applied to items. App-wide scope — a tag can be referenced
/// by items across any checklist.
///
/// Key concepts:
/// - `colorHue` is an OKLCH hue angle (0–360). Chroma and lightness are applied
///   by Theme at render time so all tags have visually consistent saturation.
/// - `iconName` is a design-token key; see `Design/GemIcons.swift` for the map
///   to SF Symbols / custom glyphs.
@Model
final class Tag {
    // MARK: - Persistent properties

    /// Stable unique identifier assigned at creation.
    var id: UUID = UUID()

    /// Display name shown in the UI.
    var name: String = ""

    /// Design-token key mapping to an SF Symbol or custom glyph.
    var iconName: String = "tag"

    /// OKLCH hue angle (0–360) for this tag's colour. Chroma and lightness
    /// are applied by Theme at render time.
    var colorHue: Double = 300

    /// Determines display order within the tag list. Lower = first.
    var sortKey: Int = 0

    // MARK: - Init

    /// Creates a new Tag.
    /// - Parameters:
    ///   - name: Display label.
    ///   - iconName: Design-token key; defaults to `"tag"`.
    ///   - colorHue: OKLCH hue angle; defaults to 300 (magenta-ish).
    ///   - sortKey: Integer ordering; defaults to 0.
    init(name: String, iconName: String = "tag", colorHue: Double = 300, sortKey: Int = 0) {
        self.name = name
        self.iconName = iconName
        self.colorHue = colorHue
        self.sortKey = sortKey
    }
}
