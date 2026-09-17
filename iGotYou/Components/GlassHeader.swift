import SwiftUI

// The 92pt header shared by the tab screens.
//
// It floats over scrolling content — which is exactly the layer the glass rules
// reserve for it. The status bar is the real one; the artboards draw a fake
// 9:41 because they're HTML, but reproducing that in a running app would be
// wrong, so the header reserves the safe area instead and lets iOS fill it.
//
// Two variants, both the same height:
//   .location — Home. Where you are, left; bell + avatar right.
//   .title    — Wallet, Activity. Big title left, avatar right.
//
// Two finishes. Glass covers the interior tabs. `onDark` puts Home's bar on
// Grab's deep green, which is the one piece of their chrome identifiable from
// a thumbnail — worth keeping even now the tall greeting band under it is gone.
// The interior tabs stay on glass: green on every screen would flatten a
// hierarchy Grab itself doesn't have.
//
// The location has no "Deliver to" eyebrow. A label over a value spends a line
// saying what the pin already says, and Zomato's header is the better pattern —
// the place on top, its address under it, both tappable as one control. The
// address is what actually disambiguates two saved places with similar names.

enum HeaderContent {
    case location(value: String, detail: String, badge: Int)
    case title(String)
}

struct GlassHeader: View {
    let content: HeaderContent
    /// Renders on the green band: white type, inverted controls.
    var onDark: Bool = false
    var onBell: () -> Void = {}
    var onAvatar: () -> Void = {}
    var onLocation: () -> Void = {}

    private var titleInk: Color { onDark ? IGY.C.onBrand : IGY.C.ink }
    private var subInk: Color { onDark ? IGY.C.onBrandMuted : IGY.C.inkMuted }

    var body: some View {
        VStack(spacing: 0) {
            // Reserve the status bar rather than drawing one.
            Color.clear.frame(height: 0)

            HStack(alignment: .center, spacing: 10) {
                switch content {
                case let .location(value, detail, badge):
                    picker(value: value, detail: detail)
                    Spacer(minLength: 8)
                    bell(badge: badge)
                    avatar

                case let .title(text):
                    Text(text).textRole(.navTitle, titleInk)
                    Spacer(minLength: 8)
                    avatar
                }
            }
            .frame(height: 44)
            .padding(.horizontal, IGY.S.gutter)
        }
        .frame(maxWidth: .infinity)
        .padding(.top, 4)
        .background(HeaderMaterial(onDark: onDark))
    }

    private func picker(value: String, detail: String) -> some View {
        Button(action: onLocation) {
            VStack(alignment: .leading, spacing: 0) {
                HStack(spacing: 5) {
                    PinGlyph(color: onDark ? IGY.C.onBrand : IGY.C.brand, filled: true)
                    Text(value).textRole(.navTitleSm, titleInk)
                    ChevronGlyph(size: 6, color: titleInk)
                }
                Text(detail)
                    .textRole(.caption, subInk)
                    .lineLimit(1)
            }
            .contentShape(.rect)
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Delivering to \(value), \(detail). Change")
    }

    private func bell(badge: Int) -> some View {
        Button(action: onBell) {
            ZStack(alignment: .topTrailing) {
                Circle()
                    .fill(onDark ? Color.white.opacity(0.18) : .white.opacity(0.7))
                    .overlay(
                        Circle().strokeBorder(.white.opacity(onDark ? 0.45 : 0.9),
                                              lineWidth: onDark ? 1 : 0.5)
                    )
                    .frame(width: 36, height: 36)
                BellGlyph(color: onDark ? IGY.C.onBrand : IGY.C.inkSecondary)
                    .frame(width: 36, height: 36)
                if badge > 0 {
                    CountBadge(count: badge, onDark: onDark).offset(x: 5, y: -4)
                }
            }
            .frame(width: 36, height: 36)
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Notifications, \(badge) unread")
    }

    private var avatar: some View {
        Button(action: onAvatar) { AvatarGlyph(onDark: onDark) }
            .buttonStyle(.plain)
            .accessibilityLabel("Your profile")
    }
}

/// `rgba(255,255,255,0.55)` + `blur(26px) saturate(1.7)`, with the hairline
/// highlight along the *bottom* edge (`inset 0 -0.5px 0`) rather than the top —
/// the header is lit from below by the content passing under it.
private struct HeaderMaterial: View {
    var onDark: Bool = false

    @Environment(\.accessibilityReduceTransparency) private var reduceTransparency

    var body: some View {
        Group {
            if onDark {
                // Opaque, not glass. The band is a surface in Grab's system,
                // not chrome floating over one, and translucency here would let
                // the white cards scrolling under it turn the green muddy.
                IGY.C.brandDark
            } else if reduceTransparency {
                IGY.C.surface.opacity(0.96)
            } else {
                // The real material. This was a white tint over
                // `.ultraThinMaterial` approximating it, written before the tab
                // bar went native; with genuine Liquid Glass in the dock below,
                // an imitation at the opposite edge of the same screen read as
                // a mismatch.
                Rectangle()
                    .fill(.clear)
                    .glassEffect(.regular, in: .rect)
            }
        }
        .overlay(alignment: .bottom) {
            if !onDark && reduceTransparency {
                Rectangle().fill(IGY.C.hairline).frame(height: 0.5)
            }
        }
        .ignoresSafeArea(edges: .top)
    }
}

// MARK: - Service header

/// The header on a service flow: back button, optional service mark, title.
/// Shorter than the tab header because it carries no location or avatar.
///
/// `Trailing` is a generic parameter rather than an `AnyView`. The erased
/// version forced every caller to wrap its button in `AnyView(…)`, which throws
/// away the view's identity and its type — so SwiftUI can no longer tell one
/// trailing item from another across updates, and the compiler stops checking
/// what was passed. `EmptyView` is the default, so headers without one are
/// unchanged at the call site.
struct ServiceHeader<Trailing: View>: View {
    let title: String
    var service: Service?
    var onBack: () -> Void
    @ViewBuilder var trailing: Trailing

    var body: some View {
        HStack(spacing: 12) {
            CircleButton(symbol: "arrow.left", size: 34, action: onBack)
                .accessibilityLabel("Back")

            if let service {
                service.icon(size: 28)
            }

            Text(title).textRole(.navTitleSm)

            Spacer(minLength: 0)

            trailing
        }
        .frame(height: 44)
        .padding(.horizontal, IGY.S.gutter)
        .padding(.top, 4)
        .frame(maxWidth: .infinity)
        // Service flows are always on glass — they sit over a map or a list,
        // never over the green.
        .background(HeaderMaterial())
    }
}

extension ServiceHeader where Trailing == EmptyView {
    init(title: String, service: Service? = nil, onBack: @escaping () -> Void) {
        self.init(title: title, service: service, onBack: onBack) { EmptyView() }
    }
}
