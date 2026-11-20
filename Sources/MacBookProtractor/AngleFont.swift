import AppKit
import CoreText
import SwiftUI

/// The number font (SF Rounded, semibold, monospaced digits) and the
/// metrics needed to fit it to the screen and to find the degree glyph.
struct AngleFont {
    static let degree = "°"

    let nsFont: NSFont
    var font: Font { Font(nsFont as CTFont) }

    init(size: CGFloat) {
        let base = NSFont.systemFont(ofSize: size, weight: .semibold)
        let rounded = base.fontDescriptor.withDesign(.rounded) ?? base.fontDescriptor
        let descriptor = rounded.addingAttributes([
            .featureSettings: [[
                NSFontDescriptor.FeatureKey.typeIdentifier: kNumberSpacingType,
                NSFontDescriptor.FeatureKey.selectorIdentifier: kMonospacedNumbersSelector,
            ]],
        ])
        nsFont = NSFont(descriptor: descriptor, size: size) ?? base
    }

    private struct CacheKey: Hashable {
        let text: String
        let width: CGFloat
        let height: CGFloat
    }

    @MainActor private static var cache: [CacheKey: AngleFont] = [:]

    /// Largest font whose cap height and width fit the given box.
    /// Cached, because the view asks again on every angle change.
    @MainActor
    static func fitting(_ text: String, in box: CGSize) -> AngleFont {
        let key = CacheKey(text: text, width: box.width, height: box.height)
        if let font = cache[key] { return font }
        if cache.count > 64 { cache.removeAll() }   // live resize makes many sizes
        let font = measureFitting(text, in: box)
        cache[key] = font
        return font
    }

    private static func measureFitting(_ text: String, in box: CGSize) -> AngleFont {
        let reference = AngleFont(size: 100)
        let byWidth = box.width / reference.width(of: text) * 100
        let byHeight = box.height / reference.nsFont.capHeight * 100
        return AngleFont(size: max(1, min(byWidth, byHeight)))
    }

    func width(of text: String) -> CGFloat {
        (text as NSString).size(withAttributes: [.font: nsFont]).width
    }

    /// Ink bounds of the degree glyph, relative to its origin on the baseline (y up).
    var degreeBounds: CGRect {
        var character = UniChar(0x00B0)
        var glyph = CGGlyph()
        guard CTFontGetGlyphsForCharacters(nsFont as CTFont, &character, &glyph, 1) else { return .zero }
        return CTFontGetBoundingRectsForGlyphs(nsFont as CTFont, .horizontal, &glyph, nil, 1)
    }

    var degreeAdvance: CGFloat { width(of: Self.degree) }

    /// Vertical offset that centers the cap height (not the line box) in a frame.
    var capCenteringOffset: CGFloat {
        (abs(nsFont.descender) - nsFont.ascender + nsFont.capHeight) / 2
    }
}
