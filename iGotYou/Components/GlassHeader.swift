import SwiftUI

// The 92pt header shared by the tab screens.
//
// It floats over scrolling content — which is exactly the layer the glass rules
// reserve for it. The status bar is the real one; the artboards draw a fake
// 9:41 because they're HTML, but reproducing that in a running app would be
// wrong, so the header reserves the safe area instead and lets iOS fill it.
//
// Two variants, both the same height:
//   .location — Home. Location picker left, bell + avatar right.
//   .title    — Wallet, Activity. Big title left, avatar right.
//
// Two finishes. Glass is the default and covers the light screens. `onDark`
// swaps in Grab's deep green band, which is the single most recognisable thing
// about their app: every Grab screen opens on a green block, and the app is
// identifiable from a thumbnail because of it. Home takes it; the interior
// tabs stay on glass, because a green band on every screen would flatten the
// hierarchy Grab itself doesn't have.

enum HeaderContent {
    case location(label: String, value: String, badge: Int)
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
                case let .location(label, value, badge):
                    picker(label: label, value: value)
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

    private func picker(label: String, value: String) -> some View {
        Button(action: onLocation) {
            VStack(alignment: .leading, spacing: 1) {
                Text(label).textRole(.eyebrow, subInk)
                HStack(spacing: 5) {
                    PinGlyph(color: onDark ? IGY.C.onBrand : IGY.C.brand)
                    Text(value).textRole(.location, titleInk)
                    ChevronGlyph(size: 6, color: titleInk)
                }
            }
            .contentShape(.rect)
        }
        .buttonStyle(.plain)
        .accessibilityLabel("\(label) \(value). Change")
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
                // Opaque, not glass. The band is a *surface* in Grab's system,
                // not chrome floating over one, and translucency here would let
                // white cards bleed through and turn it muddy as you scroll.
                // It also carries no bottom hairline and no shadow: the green
                // continues into the greeting band below it as one block.
                //
                // This is the case Apple's guidance covers directly — glass is
                // for the layer floating *above* content, and the green block
                // is content's own ground.
                IGY.C.brandDark
            } else if reduceTransparency {
                IGY.C.surface.opacity(0.96)
            } else {
                // The real material. This was a white tint over
                // `.ultraThinMaterial` approximating it, written before the
                // tab bar went native; now that the dock below is genuine
                // Liquid Glass, an imitation at the opposite edge of the same
                // screen read as a mismatch.
                Rectangle()
                    .fill(.clear)
                    .glassEffect(.regular, in: .rect)
            }
        }
        .overlay(alignment: .bottom) {
            if onDark == false && reduceTransparency {
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
        .background(HeaderMaterial())
    }
}

extension ServiceHeader where Trailing == EmptyView {
    init(title: String, service: Service? = nil, onBack: @escaping () -> Void) {
        self.init(title: title, service: service, onBack: onBack) { EmptyView() }
    }
}
