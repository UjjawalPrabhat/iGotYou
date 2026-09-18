import SwiftUI

// The 92pt header shared by the tab screens.
//
// It floats over scrolling content — which is exactly the layer the glass rules
// reserve for it. The status bar is the real one; the artboards draw a fake
// 9:41 because they're HTML, but reproducing that in a running app would be
// wrong, so the header reserves the safe area instead and lets iOS fill it.
//
// One variant: a big title on the left, the profile avatar on the right. Wallet
// and Activity use it; Home builds its own bar into the green field.
//
// There was a `.location` variant here with a picker and a notification bell,
// and an `onDark` finish for the green band it sat on. Home now draws that bar
// itself and the bell is gone from the app, so both went with their last
// callers.

enum HeaderContent {
    case title(String)
}

struct GlassHeader: View {
    let content: HeaderContent
    var onAvatar: () -> Void = {}

    var body: some View {
        VStack(spacing: 0) {
            // Reserve the status bar rather than drawing one.
            Color.clear.frame(height: 0)

            HStack(alignment: .center, spacing: 10) {
                switch content {
                case let .title(text):
                    Text(text).textRole(.navTitle)
                    Spacer(minLength: 8)
                    avatar
                }
            }
            .frame(height: 44)
            .padding(.horizontal, IGY.S.gutter)
        }
        .frame(maxWidth: .infinity)
        .padding(.top, 4)
        .background(HeaderMaterial())
    }

    private var avatar: some View {
        Button(action: onAvatar) {
            Image(systemName: "person.crop.circle.fill")
                .font(.system(size: 34))
                .foregroundStyle(IGY.C.brand)
                .frame(width: 36, height: 36)
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Your profile")
    }
}

/// `rgba(255,255,255,0.55)` + `blur(26px) saturate(1.7)`, with the hairline
/// highlight along the *bottom* edge (`inset 0 -0.5px 0`) rather than the top —
/// the header is lit from below by the content passing under it.
private struct HeaderMaterial: View {
    @Environment(\.accessibilityReduceTransparency) private var reduceTransparency

    var body: some View {
        Group {
            if reduceTransparency {
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
            if reduceTransparency {
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
