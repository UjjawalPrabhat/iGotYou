import SwiftUI

// Surface treatments: the hairline card and the glass surface.
//
// The glass rules are the project's own, stated in `iRob V1.dc.html` (Turn 5,
// "Glass on the navigation layer, content left alone"):
//
//   Glass    top bar, live-order pill, tab bar, search — all floating, Regular
//   Not glass cards, lists, doors, merchant photos; content stays opaque
//   Never    glass inside glass, or two permanently pinned surfaces on one edge
//   Variant  Clear is unused — it needs media-rich content and a dimming layer
//
// Most of that list is no longer ours to enforce. The tab bar, the search
// capsule and the live-order accessory are system surfaces now, and they bring
// Regular glass and the Reduce Transparency fallback with them. What's left
// here is the Ride and Food pills, which float over their own screens rather
// than over the tab bar — so the rule that still matters is the last one:
// apply `.igyGlass` only to something that floats, and never inside another
// glass surface. Cards use `.hairlineCard`.

// MARK: - Hairline card

/// The workhorse surface. In CSS this is `box-shadow: 0 0 0 1px #DCE3E0` — a
/// ring drawn *outside* the box, which is why the artboards can stack it with a
/// real drop shadow in the same declaration. SwiftUI has no outset ring, so we
/// stroke the shape inset by half a line width to land on the same pixel.
struct HairlineCard: ViewModifier {
    var radius: CGFloat = IGY.R.list
    var fill: Color = IGY.C.card
    var shadow: IGY.Shadow? = nil

    func body(content: Content) -> some View {
        let shape = RoundedRectangle(cornerRadius: radius, style: .continuous)
        return content
            .background(fill, in: shape)
            .overlay(shape.strokeBorder(IGY.C.hairline, lineWidth: 1))
            .igyShadow(shadow)
    }
}

extension View {
    func hairlineCard(radius: CGFloat = IGY.R.list,
                      fill: Color = IGY.C.card,
                      shadow: IGY.Shadow? = nil) -> some View {
        modifier(HairlineCard(radius: radius, fill: fill, shadow: shadow))
    }

    /// A selection ring, used on the chosen vehicle row. 2pt brand green,
    /// replacing the hairline rather than sitting beside it.
    func selectedCard(radius: CGFloat = IGY.R.cardTight, selected: Bool) -> some View {
        let shape = RoundedRectangle(cornerRadius: radius, style: .continuous)
        return self
            .background(IGY.C.card, in: shape)
            .overlay(
                shape.strokeBorder(selected ? IGY.C.brandDeep : IGY.C.hairline,
                                   lineWidth: selected ? 2 : 1)
            )
    }
}

// MARK: - Glass

extension View {
    /// A floating glass surface — the Ride and Food live pills.
    ///
    /// This was a hand-rolled recipe: `.ultraThinMaterial` under a white tint,
    /// a gradient top highlight, and a `reduceTransparency` fallback, about
    /// fifty lines reproducing the artboards' CSS. It was written before the
    /// dock went native, when nothing else on screen was real glass.
    ///
    /// It isn't worth keeping now. `.glassEffect` is the same surface the tab
    /// bar and its accessory already render, so an imitation sitting inches
    /// from the real thing reads as a near-miss rather than as a match — and
    /// the system version tracks what passes beneath it, responds to scroll
    /// edges, and handles Reduce Transparency and Increase Contrast without us
    /// maintaining a second set of rules that only we remember to update.
    func igyGlass(radius: CGFloat = IGY.R.full,
                   shadow: IGY.Shadow = .dock) -> some View {
        glassEffect(.regular, in: .rect(cornerRadius: radius, style: .continuous))
            .igyShadow(shadow)
    }
}

// MARK: - Placeholder art
//
// Every photo in the artboards is a 45° candy-stripe with a mono caption.
// Keeping them as placeholders is deliberate — the design notes call real
// photography "the single biggest lift available", and faking it with stock
// images would overstate what has actually been designed.

struct StripePlaceholder: View {
    var a: Color
    var b: Color
    var caption: String? = nil
    var stripe: CGFloat = 8

    var body: some View {
        ZStack {
            Canvas { ctx, size in
                ctx.fill(Path(CGRect(origin: .zero, size: size)), with: .color(b))
                // 135° in CSS runs top-left to bottom-right; we draw the band
                // set rotated about the centre so it covers the corners.
                let diag = size.width + size.height
                ctx.translateBy(x: size.width / 2, y: size.height / 2)
                ctx.rotate(by: .degrees(45))
                var x = -diag
                while x < diag {
                    ctx.fill(
                        Path(CGRect(x: x, y: -diag, width: stripe, height: diag * 2)),
                        with: .color(a)
                    )
                    x += stripe * 2
                }
            }
            if let caption {
                Text(caption)
                    .textRole(.monoCaption, IGY.C.inkMuted)
            }
        }
        .clipped()
    }

    static let mint  = StripePlaceholder(a: IGY.C.brandTint,  b: IGY.C.washGreen)
    static let coral = StripePlaceholder(a: IGY.C.coralTint,  b: IGY.C.coralWash)
    static let gold  = StripePlaceholder(a: IGY.C.goldTint,   b: IGY.C.goldWash)
    static let blue  = StripePlaceholder(a: IGY.C.blueTint,   b: IGY.C.blueWash)
    static let lilac = StripePlaceholder(a: IGY.C.violetTint, b: Color(hex: 0xF6F4FD))

    func caption(_ text: String) -> StripePlaceholder {
        var copy = self
        copy.caption = text
        return copy
    }

    func stripeWidth(_ w: CGFloat) -> StripePlaceholder {
        var copy = self
        copy.stripe = w
        return copy
    }
}
