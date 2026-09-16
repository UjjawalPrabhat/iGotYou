import SwiftUI

// Colour, radius and spacing tokens for iRob.
//
// The structure comes from the finalised artboards in `iRob App.dc.html`
// (Turn 11) — the source has no named tokens, so the names here are ours,
// assigned by usage.
//
// The *values* were re-pitched onto Grab's brand palette (Turn 12). iRob is a
// redesign of Grab, not a different company, so the hues have to be theirs
// while the composition stays ours:
//
//   - Green moved from the teal-leaning #168A63 to Grab green #00B14F, with a
//     deep #00562A for the header band Grab puts at the top of every screen.
//   - The ink ramp was neutralised. The old greys carried a green cast that
//     read as a second brand colour; Grab's text is plain neutral, which lets
//     the green be the only thing on screen that is green.
//   - The food accent moved from coral to Grab's orange #F5821F, and the
//     notification badge took its own red so "unread" and "food" stop sharing
//     a hue.
//
// The system is light-only. No dark variant was ever designed; the only dark
// artboard in the project belongs to the abandoned warm-canvas exploration.

extension Color {
    init(hex: UInt32) {
        self.init(
            .sRGB,
            red:   Double((hex >> 16) & 0xFF) / 255,
            green: Double((hex >> 8)  & 0xFF) / 255,
            blue:  Double( hex        & 0xFF) / 255,
            opacity: 1
        )
    }
}

enum IRob {}

// MARK: - Colour

extension IRob {
    enum C {
        // Surfaces
        static let surface       = Color(hex: 0xF4F5F5)   // screen background
        static let surfaceMuted  = Color(hex: 0xEBEDEC)   // secondary fill, dividers
        static let card          = Color.white
        static let washGreen     = Color(hex: 0xEAF8EF)   // mint wash, gradient tail
        static let hairline      = Color(hex: 0xE2E5E3)   // the 1px ring on every card

        // Ink — neutral greys. Nothing in this ramp is green; the brand is.
        static let ink           = Color(hex: 0x1C1C1C)   // primary text
        static let inkSecondary  = Color(hex: 0x4D4D4D)   // body, inactive tab
        static let inkMuted      = Color(hex: 0x757575)   // captions, metadata
        static let iconInk       = Color(hex: 0x212121)   // icon stroke
        static let speedTick     = Color(hex: 0x9AA5A0)   // motion marks on the Ride icon

        // Brand green — Grab green and its family.
        //
        // Two greens, and which one to reach for is a contrast decision, not a
        // taste one. Grab green on white is 2.5:1, so it can carry a shape but
        // it cannot carry a word: anything text-sized, any 1pt border, and any
        // fill with white text on it takes `brandDeep` (5.0:1 on white, 4.6:1
        // with white on it). `brand` is for large filled areas and system
        // chrome — the tab tint, the progress segments, the route line.
        static let brand         = Color(hex: 0x00B14F)   // fills, tab tint, chrome
        static let brandDeep     = Color(hex: 0x00803A)   // green *text*, borders, CTAs
        static let brandBright   = Color(hex: 0x00C95A)   // icon fills, pulse ring
        static let brandTint     = Color(hex: 0xE4F7EB)   // mint fill
        static let brandTintEdge = Color(hex: 0xC4EDD3)   // ring around the avatar

        /// The two darks behind Grab's signature top band. Everything set on
        /// them is white or near-white, so they are never used as a text colour.
        static let brandDark     = Color(hex: 0x00562A)
        static let brandMid      = Color(hex: 0x00873D)
        /// Text and rules that sit *on* the dark band.
        static let onBrand       = Color.white
        static let onBrandMuted  = Color(hex: 0xBFE8CE)

        // Food orange — Grab's second colour, and the only warm hue in the set
        static let coral         = Color(hex: 0xF5821F)
        static let coralTint     = Color(hex: 0xFFE7CF)
        static let coralWash     = Color(hex: 0xFFF6EC)

        /// Unread counts and destructive states. Its own red, so an unread
        /// badge can never be mistaken for a Food accent.
        static let alert         = Color(hex: 0xE0342B)

        // Rewards gold
        static let gold          = Color(hex: 0xFFC02E)
        static let goldShade     = Color(hex: 0xF2A81D)
        static let goldInk       = Color(hex: 0x8A5A00)   // gold text on tint
        static let goldTint      = Color(hex: 0xFFEFCC)
        static let goldWash      = Color(hex: 0xFFF9EC)

        // Send blue — three tones, one per face of the isometric parcel
        static let blueLight     = Color(hex: 0x7FB3F0)
        static let blueMid       = Color(hex: 0x2F6FD0)
        static let blueDeep      = Color(hex: 0x1E4F9C)
        static let blueTint      = Color(hex: 0xE1EDFB)
        static let blueWash      = Color(hex: 0xF2F7FD)

        // Wallet violet
        static let violet        = Color(hex: 0x5341B0)
        static let violetOnDark  = Color(hex: 0xD6CFF7)   // label on the balance card
        static let violetTint    = Color(hex: 0xEEEBFA)

        // Map (Ride screen)
        static let mapBase       = Color(hex: 0xE8EBE9)
        static let mapGrid       = Color(hex: 0xE0E4E2)
        static let mapRoad       = Color(hex: 0xCDD2CF)

        // Progress track behind the 4-segment order bar
        static let track         = Color(hex: 0xE3E6E4)
    }
}

// MARK: - Radius

extension IRob {
    /// The shape ladder, stated in `iRob V1.dc.html` (Turn 4) as:
    /// "10px input, 18px cards, 24px feature, pills full".
    enum R {
        static let sheet       : CGFloat = 28
        static let feature     : CGFloat = 24   // service cards
        static let pillCard    : CGFloat = 26   // live-order pill, wallet card
        static let card        : CGFloat = 22   // restaurant card, cart tray
        static let cardTight   : CGFloat = 20   // vehicle row, stat tile
        static let list        : CGFloat = 18   // list containers, place photos
        static let control     : CGFloat = 16   // payment chip
        static let button      : CGFloat = 14
        static let thumb       : CGFloat = 12   // cart thumbnails
        static let full        : CGFloat = 999
    }
}

// MARK: - Spacing

extension IRob {
    /// Only the three spacings that are genuinely shared *between* screens.
    ///
    /// There was a full xs…xxl ladder here and nothing ever read from it — every
    /// screen kept writing `.padding(12)` directly. A scale that the code
    /// doesn't use isn't a system, it's a second opinion, so it's gone. The
    /// values below earn their place because getting one of them wrong on one
    /// screen is visible as misalignment against the next.
    enum S {
        /// Screen side gutter. Every artboard uses 20.
        static let gutter    : CGFloat = 20
        /// The dock and its siblings inset further than content.
        static let dockInset : CGFloat = 14
        /// Distance from the dock to the physical bottom of the screen — not
        /// to the safe area.
        ///
        /// The artboards said 22 above the safe area, but they were drawn
        /// without a home indicator. Measured against one, 22 stacks on the
        /// safe area's own ~34pt and the dock ends up floating more than 50pt
        /// clear of the edge, which reads as a misalignment rather than as a
        /// floating control. Callers pair this with
        /// `.ignoresSafeArea(edges: .bottom)` so it means what it says; 20
        /// still clears the home indicator, which ends about 8pt up.
        static let dockBottom: CGFloat = 20
    }
}

// MARK: - Elevation

extension IRob {
    /// Shadow recipes, transcribed from the artboards' `box-shadow` values.
    ///
    /// CSS shadows carry a spread/inset term SwiftUI has no equivalent for, so
    /// the negative-spread blurs (`0 2px 10px -4px`) are approximated by
    /// reducing the radius rather than the opacity — this keeps the shadow
    /// tight to the card the way the original does.
    struct Shadow {
        let color: Color
        let radius: CGFloat
        let x: CGFloat
        let y: CGFloat

        /// `0 2px 10px -4px rgba(23,32,29,0.10)`
        static let card = Shadow(
            color: Color(hex: 0x1C1C1C).opacity(0.10), radius: 5, x: 0, y: 2
        )
        /// `0 6px 20px -10px rgba(23,32,29,0.18)` — under the glass header
        static let header = Shadow(
            color: Color(hex: 0x1C1C1C).opacity(0.18), radius: 10, x: 0, y: 6
        )
        /// `0 14px 34px -12px rgba(23,32,29,0.34)` — the floating dock
        static let dock = Shadow(
            color: Color(hex: 0x1C1C1C).opacity(0.34), radius: 17, x: 0, y: 14
        )
        /// `0 16px 38px -14px rgba(23,32,29,0.40)` — the cart tray, which sits
        /// above the dock and needs to out-lift it
        static let tray = Shadow(
            color: Color(hex: 0x1C1C1C).opacity(0.40), radius: 19, x: 0, y: 16
        )
        /// `0 -12px 34px -14px rgba(23,32,29,0.30)` — bottom sheets, cast upward
        static let sheet = Shadow(
            color: Color(hex: 0x1C1C1C).opacity(0.30), radius: 17, x: 0, y: -12
        )
        /// `0 8px 20px -8px rgba(22,138,99,0.55)` — the green Book button.
        /// Cast in the bright green even though the button is filled in the
        /// deep one; a shadow tinted darker than its own surface reads as dirt.
        static let brandGlow = Shadow(
            color: Color(hex: 0x00B14F).opacity(0.45), radius: 10, x: 0, y: 8
        )
        /// `0 14px 30px -14px rgba(83,65,176,0.60)` — the wallet balance card
        static let violetGlow = Shadow(
            color: Color(hex: 0x5341B0).opacity(0.60), radius: 15, x: 0, y: 14
        )
    }
}

extension View {
    /// `nil` applies no shadow, which lets callers pass an optional recipe
    /// straight through instead of branching around the modifier.
    func irobShadow(_ s: IRob.Shadow?) -> some View {
        shadow(color: s?.color ?? .clear,
               radius: s?.radius ?? 0,
               x: s?.x ?? 0, y: s?.y ?? 0)
    }
}
