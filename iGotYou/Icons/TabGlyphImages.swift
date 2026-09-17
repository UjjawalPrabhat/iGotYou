import SwiftUI

/// Rasterised tab-bar icons.
///
/// `UITabBar` takes a `UIImage`, not an arbitrary view — hand a SwiftUI `Shape`
/// to a `Tab` label and the icon silently drops, leaving a text-only tab. So the
/// glyphs are rendered once at launch and handed over as images.
///
/// They're rendered as **template** images in a single colour, which means the
/// tab bar tints them itself: brand green when selected, its own grey when not.
/// That's better than shipping two coloured variants — selection then animates
/// and dims exactly like every other iOS tab bar, including in states we don't
/// control (highlighted, disabled, Increase Contrast).
@MainActor
enum TabGlyphImages {
    /// The tabs that supply their own glyph. Search is absent deliberately —
    /// the search role draws the system magnifier, and shipping a second
    /// hand-drawn one would put two different magnifiers in the same app.
    enum Glyph {
        case home, wallet, activity
    }

    private static var cache: [Glyph: Image] = [:]

    static func image(for glyph: Glyph) -> Image {
        if let cached = cache[glyph] { return cached }
        let rendered = render(glyph)
        cache[glyph] = rendered
        return rendered
    }

    private static func render(_ glyph: Glyph) -> Image {
        // Rendered at the glyph's natural size in a 26pt box — the tab bar
        // scales to its own metrics from there.
        let side: CGFloat = 26
        let content = ZStack {
            Color.clear
            switch glyph {
            case .home:     HomeGlyph()
            case .wallet:   WalletGlyph()
            case .activity: ActivityGlyph()
            }
        }
        .frame(width: side, height: side)

        let renderer = ImageRenderer(content: content)
        renderer.scale = 3

        guard let ui = renderer.uiImage else {
            // Nothing sensible to fall back to but a symbol; better a wrong
            // icon than a tab with no icon at all.
            return Image(systemName: "circle")
        }
        return Image(uiImage: ui.withRenderingMode(.alwaysTemplate))
    }
}
