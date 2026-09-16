import SwiftUI

// Type scale for iRob.
//
// Plus Jakarta Sans carries the interface; IBM Plex Mono is reserved for
// placeholder captions and eyebrow labels. Neither ships with iOS, so both are
// bundled in `Fonts/` and registered via ATSApplicationFontsPath.
//
// The five Jakarta weights were instantiated from the variable font and given
// distinct family names, because iOS resolves a bundled family by PostScript
// name and will silently fall back to Regular if two faces claim the same one.

extension IRob {
    enum FontName {
        static let regular   = "PlusJakartaSans-Regular"    // 400
        static let medium    = "PlusJakartaSans-Medium"     // 500
        static let semibold  = "PlusJakartaSans-SemiBold"   // 600
        static let bold      = "PlusJakartaSans-Bold"       // 700
        static let extrabold = "PlusJakartaSans-ExtraBold"  // 800

        static let mono        = "IBMPlexMono-Regular"
        static let monoMedium  = "IBMPlexMono-Medium"
    }
}

extension Font {
    /// Jakarta at an explicit weight and size.
    ///
    /// `relativeTo` keeps Dynamic Type working — the artboards are fixed-pixel,
    /// but shipping type that ignores the accessibility setting would fail the
    /// HIG commitments the design explicitly claims.
    static func jakarta(_ weight: Int, _ size: CGFloat,
                        relativeTo style: Font.TextStyle = .body) -> Font {
        let name: String
        switch weight {
        case ...400: name = IRob.FontName.regular
        case 401...500: name = IRob.FontName.medium
        case 501...600: name = IRob.FontName.semibold
        case 601...700: name = IRob.FontName.bold
        default: name = IRob.FontName.extrabold
        }
        return .custom(name, size: size, relativeTo: style)
    }

    static func mono(_ size: CGFloat, medium: Bool = false,
                     relativeTo style: Font.TextStyle = .caption) -> Font {
        .custom(medium ? IRob.FontName.monoMedium : IRob.FontName.mono,
                size: size, relativeTo: style)
    }
}

// MARK: - Named roles
//
// Each role pairs a font with its tracking. The artboards use negative tracking
// on every display size and positive tracking on uppercase labels, so the two
// always travel together — a `Font` alone would lose half the style.

extension IRob {
    struct TextRole {
        let font: Font
        let tracking: CGFloat

        // Display
        /// 700 27 / −0.7 — "Good morning, Ujjawal", "Explore Kuta"
        static let greeting     = TextRole(font: .jakarta(700, 27, relativeTo: .title), tracking: -0.7)
        /// 800 34 / −1.0 — the wallet balance
        static let balance      = TextRole(font: .jakarta(800, 34, relativeTo: .largeTitle), tracking: -1.0)

        // Navigation
        /// 700 21 / −0.5 — "Wallet", "Activity"
        static let navTitle     = TextRole(font: .jakarta(700, 21, relativeTo: .title2), tracking: -0.5)
        /// 700 19 / −0.4 — "Ride", "Food" (service screens, beside the back button)
        static let navTitleSm   = TextRole(font: .jakarta(700, 19, relativeTo: .title3), tracking: -0.4)

        // Sections
        /// 700 22 / −0.4 — "Your usuals", "Around you", "142 kitchens open"
        static let section      = TextRole(font: .jakarta(700, 22, relativeTo: .title2), tracking: -0.4)
        /// 700 20 / −0.4 — "Collections", "Recent", "Earlier"
        static let sectionSm    = TextRole(font: .jakarta(700, 20, relativeTo: .title3), tracking: -0.4)

        // Cards
        /// 700 22 / −0.5 — Ride and Food service-card titles
        static let serviceTitle = TextRole(font: .jakarta(700, 22, relativeTo: .title2), tracking: -0.5)
        /// 700 20 / −0.4 — Send and Rewards (the shorter cards)
        static let serviceTitleSm = TextRole(font: .jakarta(700, 20, relativeTo: .title3), tracking: -0.4)
        /// 700 17.5 / −0.3 — restaurant names
        static let cardTitle    = TextRole(font: .jakarta(700, 17.5, relativeTo: .headline), tracking: -0.3)
        /// 700 19 / −0.3 — the featured Explore card
        static let featureTitle = TextRole(font: .jakarta(700, 19, relativeTo: .headline), tracking: -0.3)

        // Rows
        /// 600 16 — "Home → Campus"
        static let rowTitle     = TextRole(font: .jakarta(600, 16, relativeTo: .body), tracking: 0)
        /// 600 15.5 — transaction and activity rows
        static let rowTitleSm   = TextRole(font: .jakarta(600, 15.5, relativeTo: .body), tracking: 0)
        /// 600 14 — the single most-used style in the whole export (35 uses)
        static let label        = TextRole(font: .jakarta(600, 14, relativeTo: .subheadline), tracking: 0)

        // Body
        /// 400 14 — "What can iRob help with?"
        static let body         = TextRole(font: .jakarta(400, 14, relativeTo: .subheadline), tracking: 0)
        /// 400 13.5 — restaurant metadata
        static let bodySm       = TextRole(font: .jakarta(400, 13.5, relativeTo: .footnote), tracking: 0)
        /// 400 13 — captions under every list row
        static let caption      = TextRole(font: .jakarta(400, 13, relativeTo: .footnote), tracking: 0)
        /// 500 13 — service-card subtitles ("Bikes 4 min away")
        static let captionMed   = TextRole(font: .jakarta(500, 13, relativeTo: .footnote), tracking: 0)

        // Labels
        /// 500 11.5 / +0.06em — "Deliver to", "THIS WEEK"
        static let eyebrow      = TextRole(font: .jakarta(500, 11.5, relativeTo: .caption), tracking: 11.5 * 0.06)
        /// 500 11 / +0.04em — "ARRIVING 9:58"
        static let statusLabel  = TextRole(font: .jakarta(500, 11, relativeTo: .caption), tracking: 11 * 0.04)
        /// 600 13 / +0.05em — "CHOOSE A VEHICLE"
        static let sheetLabel   = TextRole(font: .jakarta(600, 13, relativeTo: .footnote), tracking: 13 * 0.05)
        /// 700 16 / −0.3 — the location in the header
        static let location     = TextRole(font: .jakarta(700, 16, relativeTo: .body), tracking: -0.3)

        // Tabs
        static let tabActive    = TextRole(font: .jakarta(600, 11, relativeTo: .caption2), tracking: 0)
        static let tabInactive  = TextRole(font: .jakarta(500, 11, relativeTo: .caption2), tracking: 0)

        // Badges and pills
        /// 700 10.5 — "FASTEST"
        static let badge        = TextRole(font: .jakarta(700, 10.5, relativeTo: .caption2), tracking: 0)
        /// 600 12 — "32 min", "Free delivery"
        static let chip         = TextRole(font: .jakarta(600, 12, relativeTo: .caption), tracking: 0)
        /// 700 10 — the red notification count
        static let badgeCount   = TextRole(font: .jakarta(700, 10, relativeTo: .caption2), tracking: 0)

        // Mono
        /// 400 10 / +0.08em — "place photo", "dish photo"
        static let monoCaption  = TextRole(font: .mono(10), tracking: 10 * 0.08)
    }
}

extension View {
    func textRole(_ role: IRob.TextRole) -> some View {
        font(role.font).tracking(role.tracking)
    }
}

extension Text {
    func textRole(_ role: IRob.TextRole, _ color: Color = IRob.C.ink) -> some View {
        self.font(role.font).tracking(role.tracking).foregroundStyle(color)
    }
}
