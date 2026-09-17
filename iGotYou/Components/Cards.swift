import SwiftUI

// Reusable card and row components shared across the tab screens.

/// A card press that scales slightly. The artboards are static, so nothing
/// specifies this — but a hi-fi prototype that doesn't respond to touch reads
/// as a screenshot, and "energetic" has to live somewhere.
struct PressableCard: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.975 : 1)
            .animation(.easeOut(duration: 0.14), value: configuration.isPressed)
    }
}

// MARK: - Coming soon

/// The nine unbuilt services, collapsed to one row. Tapping expands them.
/// They stay visible rather than being removed — that's the whole scope thesis.
struct ComingSoonCard: View {
    @State private var expanded = false

    var body: some View {
        VStack(spacing: 0) {
            Button {
                withAnimation(.easeOut(duration: 0.26)) { expanded.toggle() }
            } label: {
                HStack(spacing: 12) {
                    VStack(alignment: .leading, spacing: 1) {
                        Text("9 more services coming soon")
                            .textRole(.rowTitleSm)
                        Text(ComingSoon.summary)
                            .textRole(.caption, IGY.C.inkMuted)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)

                    Image(systemName: expanded ? "chevron.up" : "chevron.down")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(IGY.C.inkSecondary)
                }
                .padding(.horizontal, 18)
                .padding(.vertical, 15)
                .contentShape(.rect)
            }
            .buttonStyle(.plain)

            if expanded {
                VStack(spacing: 14) {
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 4),
                                             count: 5),
                              spacing: 14) {
                        ForEach(ComingSoon.allCases) { s in
                            VStack(spacing: 6) {
                                Circle()
                                    .strokeBorder(IGY.C.hairline,
                                                  style: StrokeStyle(lineWidth: 1.5, dash: [3, 3]))
                                    .frame(width: 38, height: 38)
                                Text(s.rawValue)
                                    .textRole(.tabInactive, IGY.C.inkMuted)
                                    .lineLimit(1)
                                    .minimumScaleFactor(0.8)
                            }
                        }
                    }
                    Text("We'll tell you the moment these open.")
                        .textRole(.caption, IGY.C.inkMuted)
                }
                .opacity(0.55)
                .padding(.horizontal, 14)
                .padding(.bottom, 16)
                .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .hairlineCard(radius: IGY.R.cardTight)
        .clipped()
    }
}

// MARK: - Section header

struct SectionHeader: View {
    let title: String
    var action: String? = nil
    var small: Bool = false
    var onAction: () -> Void = {}

    var body: some View {
        HStack(alignment: .firstTextBaseline) {
            Text(title).textRole(small ? .sectionSm : .section)
            Spacer()
            if let action {
                Button(action: onAction) {
                    Text(action).textRole(.label, IGY.C.brandDeep)
                }
                .buttonStyle(.plain)
            }
        }
    }
}

// MARK: - List container

/// A white rounded container holding rows separated by inset hairlines. The
/// inset (the divider starts where the text starts, not at the card edge) is
/// what makes these read as a grouped list rather than a stack of cards.
struct ListCard<Content: View>: View {
    var radius: CGFloat = IGY.R.list
    @ViewBuilder var content: Content

    var body: some View {
        VStack(spacing: 0) { content }
            .hairlineCard(radius: radius)
    }
}

struct RowDivider: View {
    var inset: CGFloat = 60
    var body: some View {
        Rectangle()
            .fill(IGY.C.surfaceMuted)
            .frame(height: 1)
            .padding(.leading, inset)
    }
}

// MARK: - Usual row

struct UsualRow: View {
    let usual: Usual
    var action: () -> Void = {}

    var body: some View {
        HStack(spacing: 14) {
            usual.service.icon(size: 30)
            VStack(alignment: .leading, spacing: 1) {
                Text(usual.title).textRole(.rowTitle)
                Text(usual.detail).textRole(.caption, IGY.C.inkMuted)
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            Button(action: action) {
                Text(usual.action)
                    .textRole(.label, IGY.C.brandDeep)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 8)
                    .overlay(
                        RoundedRectangle(cornerRadius: IGY.R.button, style: .continuous)
                            .strokeBorder(IGY.C.brandDeep, lineWidth: 1)
                    )
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
    }
}

// MARK: - Place card

struct PlaceCard: View {
    let place: Place
    var height: CGFloat = 140

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            place.art.placeholder.caption("place photo")
                .frame(height: height)
                .clipShape(RoundedRectangle(cornerRadius: IGY.R.list, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: IGY.R.list, style: .continuous)
                        .strokeBorder(IGY.C.hairline, lineWidth: 1)
                )
            Text(place.title).textRole(.rowTitleSm)
        }
    }
}

// MARK: - Chips

struct Chip: View {
    let text: String
    var style: Style = .neutral

    enum Style { case selected, neutral, brand, warn, muted }

    var body: some View {
        Text(text)
            .textRole(style == .selected || style == .neutral ? .bodySm : .chip,
                      foreground)
            .padding(.horizontal, style == .selected || style == .neutral ? 14 : 9)
            .padding(.vertical, style == .selected || style == .neutral ? 9 : 5)
            .background(background, in: Capsule())
            .overlay {
                if style == .neutral {
                    Capsule().strokeBorder(IGY.C.hairline, lineWidth: 1)
                }
            }
    }

    private var foreground: Color {
        switch style {
        case .selected: .white
        case .neutral: IGY.C.inkSecondary
        case .brand: IGY.C.brandDeep
        case .warn: IGY.C.goldInk
        case .muted: IGY.C.inkSecondary
        }
    }

    private var background: Color {
        switch style {
        case .selected: IGY.C.ink
        case .neutral: IGY.C.card
        case .brand: IGY.C.brandTint
        case .warn: IGY.C.goldWash
        case .muted: IGY.C.surfaceMuted
        }
    }
}

/// The square-cornered tag used inside restaurant cards — deliberately not a
/// pill, so it reads as metadata rather than as a control.
struct Tag: View {
    let text: String
    var style: Chip.Style = .brand

    var body: some View {
        Text(text)
            .textRole(.chip, foreground)
            .padding(.horizontal, 9)
            .padding(.vertical, 5)
            .background(background,
                        in: RoundedRectangle(cornerRadius: 7, style: .continuous))
    }

    private var foreground: Color {
        switch style {
        case .brand: IGY.C.brandDeep
        case .warn: IGY.C.goldInk
        default: IGY.C.inkSecondary
        }
    }

    private var background: Color {
        switch style {
        case .brand: IGY.C.brandTint
        case .warn: IGY.C.goldWash
        default: IGY.C.surfaceMuted
        }
    }
}

// MARK: - Primary button

struct PrimaryButton: View {
    let title: String
    var fill: Color = IGY.C.brandDeep
    /// Fills the width it's given. A button that commits you to the whole
    /// screen — "Choose this pickup" — should be as wide as the decision;
    /// one that sits beside another control — "Book", next to the payment
    /// chip — should only be as wide as its label.
    var expands: Bool = false
    var action: () -> Void = {}

    var body: some View {
        Button(action: action) {
            Text(title)
                .textRole(.rowTitle, .white)
                .frame(maxWidth: expands ? .infinity : nil)
                .frame(height: 54)
                .padding(.horizontal, 26)
                .background(fill,
                            in: RoundedRectangle(cornerRadius: IGY.R.control,
                                                 style: .continuous))
                .igyShadow(.brandGlow)
        }
        .buttonStyle(PressableCard())
    }
}
