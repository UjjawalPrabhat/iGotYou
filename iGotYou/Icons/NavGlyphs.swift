import SwiftUI

// Navigation and UI glyphs.
//
// Unlike the four service icons, none of these exist as SVG in the export —
// they're CSS-shaped `<div>`s (a rotated square with two borders for a chevron,
// a circle with one square corner for a pin, a clip-path pentagon for Home).
// Authored here from that geometry so they stay a matched set with the drawn
// icons rather than drifting toward SF Symbols, which would read as a different
// hand.
//
// Each is built on the same principle as the source: 2pt strokes, round caps,
// and the active state expressed by colour plus a fill rather than by a
// different shape.

// MARK: - Tab glyphs

// The three tab glyphs carry no selected/unselected variant. They are
// rasterised once as *template* images (see `TabGlyphImages`), and a template
// keeps only its alpha — the tab bar supplies the colour, brand green when
// selected and its own grey when not. An `active` flag here would have been
// drawn and then thrown away, so the ink below is only ever the mask.

/// Solid pentagon house. `clip-path:polygon(50% 0, 100% 42%, 100% 100%, 0 100%, 0 42%)`
struct HomeGlyph: View {
    var body: some View {
        let w: CGFloat = 22, h: CGFloat = 20
        Path { p in
            p.move(to: CGPoint(x: w * 0.5, y: 0))
            p.addLine(to: CGPoint(x: w, y: h * 0.42))
            p.addLine(to: CGPoint(x: w, y: h))
            p.addLine(to: CGPoint(x: 0, y: h))
            p.addLine(to: CGPoint(x: 0, y: h * 0.42))
            p.closeSubpath()
        }
        .fill(IGY.C.inkSecondary)
        .frame(width: w, height: h)
    }
}

/// Wallet: a plain rounded rectangle. The quietest glyph in the set — which is
/// deliberate, since Wallet is where colour has to mean money rather than
/// decoration.
struct WalletGlyph: View {
    var body: some View {
        RoundedRectangle(cornerRadius: 5, style: .continuous)
            .strokeBorder(IGY.C.inkSecondary, lineWidth: 2)
            .frame(width: 22, height: 17)
    }
}

/// Clock: ring plus two hands, drawn as bars rather than strokes so they keep
/// their weight at 20pt.
struct ActivityGlyph: View {
    var body: some View {
        ZStack(alignment: .topLeading) {
            Circle()
                .strokeBorder(IGY.C.inkSecondary, lineWidth: 2)
                .frame(width: 20, height: 20)
            RoundedRectangle(cornerRadius: 1).fill(IGY.C.inkSecondary)
                .frame(width: 2, height: 8)
                .offset(x: 8, y: 3)
            RoundedRectangle(cornerRadius: 1).fill(IGY.C.inkSecondary)
                .frame(width: 6, height: 2)
                .offset(x: 9, y: 9)
        }
        .frame(width: 20, height: 20)
    }
}

// MARK: - Header glyphs

/// Bell: a dome with softly squared shoulders, plus a clapper bar across the
/// foot. `border-radius: 999px 999px 6px 6px`
///
/// The source is just the rounded outline. On its own that shape is ambiguous
/// at 16pt — it reads as a rounded square — so a short foot bar is added to
/// name it, which is the minimum needed for the glyph to carry meaning next to
/// a count badge.
struct BellGlyph: View {
    var size: CGFloat = 16
    var color: Color = IGY.C.inkSecondary

    var body: some View {
        let w = size * 0.125            // 2pt at 16pt
        ZStack {
            UnevenRoundedRectangle(
                topLeadingRadius: size / 2,
                bottomLeadingRadius: size * 0.375,
                bottomTrailingRadius: size * 0.375,
                topTrailingRadius: size / 2,
                style: .continuous
            )
            .strokeBorder(color, lineWidth: w)

            Path { p in
                p.move(to: CGPoint(x: size * 0.10, y: size))
                p.addLine(to: CGPoint(x: size * 0.90, y: size))
            }
            .stroke(color, style: StrokeStyle(lineWidth: w, lineCap: .round))
        }
        .frame(width: size, height: size)
    }
}

/// Location pin: a circle with one square corner, rotated 45° so the point
/// falls to the bottom. Exactly how the source builds it.
/// `border-radius: 999px 999px 999px 2px; transform: rotate(-45deg)`
struct PinGlyph: View {
    var size: CGFloat = 11
    var color: Color = IGY.C.brand
    var filled: Bool = false

    var body: some View {
        let shape = UnevenRoundedRectangle(
            topLeadingRadius: size / 2, bottomLeadingRadius: 2,
            bottomTrailingRadius: size / 2, topTrailingRadius: size / 2,
            style: .continuous
        )
        Group {
            if filled { shape.fill(color) }
            else { shape.strokeBorder(color, lineWidth: 2) }
        }
        .frame(width: size, height: size)
        .rotationEffect(.degrees(-45))
    }
}

/// Disclosure chevron. The source draws a square with only two borders and
/// rotates it, which produces a sharper corner than SF Symbols' chevron —
/// worth preserving, it's part of why the lists read as crisp.
struct ChevronGlyph: View {
    /// The base path is a corner whose vertex points down-right at 45°, so each
    /// direction is that vertex rotated onto the axis it should indicate.
    /// `.up` is −135°, not +135° — the latter points it left.
    enum Direction { case down, right, up, left

        var angle: Double {
            switch self {
            case .down: 45
            case .right: -45
            case .up: -135
            case .left: 135
            }
        }
    }

    var size: CGFloat = 9
    var direction: Direction = .down
    var color: Color = IGY.C.inkSecondary
    var weight: CGFloat = 2

    var body: some View {
        Path { p in
            p.move(to: CGPoint(x: 0, y: size))
            p.addLine(to: CGPoint(x: size, y: size))
            p.addLine(to: CGPoint(x: size, y: 0))
        }
        .stroke(color, style: StrokeStyle(lineWidth: weight, lineCap: .square))
        .frame(width: size, height: size)
        .rotationEffect(.degrees(direction.angle))
    }
}

/// The avatar placeholder — a mint disc with a tint ring. Never a person glyph
/// in the source; it stands in for a photo.
struct AvatarGlyph: View {
    var size: CGFloat = 36
    /// On the green band the mint disc disappears, so the placeholder inverts:
    /// a translucent white well with a white rim.
    var onDark: Bool = false

    var body: some View {
        Circle()
            .fill(onDark ? Color.white.opacity(0.22) : IGY.C.brandTint)
            .overlay(
                Circle().strokeBorder(onDark ? .white.opacity(0.55)
                                             : IGY.C.brandTintEdge,
                                      lineWidth: 1)
            )
            .frame(width: size, height: size)
    }
}

/// The red count badge that rides on the bell. It takes `alert`, not the Food
/// orange — an unread count and a food accent must not share a hue.
struct CountBadge: View {
    let count: Int
    var onDark: Bool = false

    var body: some View {
        Text("\(count)")
            .textRole(.badgeCount, .white)
            .padding(.horizontal, 4)
            .frame(minWidth: 16, minHeight: 16)
            .background(IGY.C.alert, in: Capsule())
            // On the green band the badge needs to separate from the bell's
            // translucent well, which is nearly the same value as the red.
            .overlay {
                if onDark { Capsule().strokeBorder(.white.opacity(0.9), lineWidth: 1.5) }
            }
    }
}

// MARK: - Previews

#Preview("Nav glyphs") {
    VStack(spacing: 32) {
        HStack(spacing: 26) {
            HomeGlyph()
            WalletGlyph()
            ActivityGlyph()
        }
        HStack(spacing: 22) {
            BellGlyph()
            PinGlyph()
            PinGlyph(filled: true)
            ChevronGlyph()
            ChevronGlyph(direction: .right)
            AvatarGlyph()
            AvatarGlyph(onDark: true)
            CountBadge(count: 7)
        }
    }
    .padding(40)
    .background(IGY.C.surface)
}
