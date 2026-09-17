import SwiftUI

// Home, arranged the way Glovo arranges theirs.
//
// The top half of the screen is one green field and the services live on it as
// large discs. Nothing else competes: no greeting, no cards, no list. The
// argument is simply that this is a super-app, the services *are* the product,
// and the first screenful should be a menu of them rather than a lead-in to
// one. Glovo gets five above the fold this way; iGotYou has four, so they get
// more room each.
//
// Everything that is not a service sits below, on a white sheet whose top edge
// curves — the shape is what separates "what this app does" from "what is
// happening in it" without needing a divider or a heading to say so.
//
// The location is a pill floating in the field, centred, rather than a bar
// pinned to the top edge. It is the only control up here, so it does not need
// a bar to live in, and centring it keeps the field symmetrical behind the
// discs.
//
// Other scope decisions this screen still encodes:
//   - Nothing removed. Four doors are open; nine more stay visible as Coming soon.
//   - One entry point each: Wallet and Activity have tabs, so they get no door.
//   - "Around you" replaces the ad slot. Explore was cut as a destination, so
//     the discovery it would have carried lives here instead.

struct HomeScreen: View {
    @Environment(AppState.self) private var app

    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                servicesField

                sheet
                    // Pulls the curve up over the field's bottom edge so the
                    // two read as one continuous surface rather than as two
                    // blocks that happen to touch.
                    .padding(.top, -30)
            }
        }
        .scrollIndicators(.hidden)
        // The green reaches the top as a background that ignores the safe
        // area, while the content inside still respects it. Letting the
        // ScrollView ignore it instead put the status bar's own text on dark
        // green without iOS switching it to light — dark on dark.
        .background(IGY.C.brandDark.ignoresSafeArea())
    }

    // MARK: The green field

    private var servicesField: some View {
        VStack(spacing: 30) {
            locationPill
                .padding(.top, 8)

            VStack(spacing: 26) {
                HStack(spacing: 18) {
                    ServiceDisc(service: .ride) { app.presentedService = .ride }
                    ServiceDisc(service: .food) { app.presentedService = .food }
                }
                HStack(spacing: 18) {
                    ServiceDisc(service: .send) { app.presentedService = .send }
                    ServiceDisc(service: .bills) { app.presentedService = .bills }
                }
            }
            .padding(.horizontal, IGY.S.gutter)
        }
        .padding(.top, 10)
        .padding(.bottom, 54)
        .frame(maxWidth: .infinity)
        .background(IGY.C.brandDark)
    }

    /// Where you are, and the two personal entry points.
    ///
    /// The bell and the avatar ride on the pill rather than in a bar of their
    /// own. They are the only other things up here, and giving them a separate
    /// row would put a second horizontal band across a field whose whole job is
    /// to be quiet behind the discs.
    private var locationPill: some View {
        HStack(spacing: 10) {
            Button {} label: {
                HStack(spacing: 6) {
                    Image(systemName: "mappin.and.ellipse")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(IGY.C.brandDeep)
                    Text(Mock.location)
                        .textRole(.label, IGY.C.ink)
                        .lineLimit(1)
                    Image(systemName: "chevron.down")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundStyle(IGY.C.inkSecondary)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 11)
                .background(IGY.C.card, in: .capsule)
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Delivering to \(Mock.location). Change")

            Button { app.showingNotifications = true } label: {
                ZStack(alignment: .topTrailing) {
                    Circle().fill(.white.opacity(0.18))
                        .overlay(Circle().strokeBorder(.white.opacity(0.45), lineWidth: 1))
                        .frame(width: 40, height: 40)
                    Image(systemName: "bell.fill")
                        .font(.system(size: 15))
                        .foregroundStyle(IGY.C.onBrand)
                        .frame(width: 40, height: 40)
                    if app.notificationCount > 0 {
                        CountBadge(count: app.notificationCount, onDark: true)
                            .offset(x: 6, y: -4)
                    }
                }
                .frame(width: 40, height: 40)
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Notifications, \(app.notificationCount) unread")

            Button { app.showingProfile = true } label: {
                Image(systemName: "person.crop.circle.fill")
                    .font(.system(size: 38))
                    .foregroundStyle(IGY.C.onBrand.opacity(0.9))
                    .frame(width: 40, height: 40)
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Your profile")
        }
        .padding(.horizontal, IGY.S.gutter)
    }

    // MARK: The white sheet

    private var sheet: some View {
        VStack(spacing: 0) {
            ComingSoonCard()
                .padding(.horizontal, IGY.S.gutter)
                .padding(.top, 46)

            usuals
            aroundYou

            // Clears the bottom accessory. TabView reports the tab bar as safe
            // area but not the accessory riding above it, so the last section
            // needs its own room.
            Color.clear.frame(height: 76)
        }
        .frame(maxWidth: .infinity)
        .background(
            SheetCurve()
                .fill(IGY.C.surface)
        )
    }

    // MARK: Usuals

    private var usuals: some View {
        VStack(spacing: 12) {
            SectionHeader(title: "Your usuals", action: "Edit")
            ListCard {
                ForEach(Array(Mock.usuals.enumerated()), id: \.element.id) { i, usual in
                    if i > 0 { RowDivider() }
                    UsualRow(usual: usual)
                }
            }
        }
        .padding(.horizontal, IGY.S.gutter)
        .padding(.top, 22)
    }

    // MARK: Around you

    private var aroundYou: some View {
        VStack(alignment: .leading, spacing: 14) {
            SectionHeader(title: "Around you")
            HStack(alignment: .top, spacing: 12) {
                ForEach(Mock.aroundYou) { place in
                    PlaceCard(place: place)
                }
            }
        }
        .padding(.horizontal, IGY.S.gutter)
        .padding(.top, 26)
    }
}

// MARK: - The curved sheet edge

/// A shallow arc across the top of the sheet.
///
/// Not a rounded rectangle: a corner radius makes the green look like it is
/// *behind* a card, and the point here is that the field and the sheet are one
/// surface with a seam. A single quadratic curve, rising 30pt at the centre,
/// reads as the sheet being pulled up rather than laid on top — which is the
/// shape Glovo uses for the same reason.
private nonisolated struct SheetCurve: Shape {
    var rise: CGFloat = 30

    func path(in r: CGRect) -> Path {
        var p = Path()
        p.move(to: CGPoint(x: r.minX, y: r.minY + rise))
        p.addQuadCurve(to: CGPoint(x: r.maxX, y: r.minY + rise),
                       control: CGPoint(x: r.midX, y: r.minY - rise))
        p.addLine(to: CGPoint(x: r.maxX, y: r.maxY))
        p.addLine(to: CGPoint(x: r.minX, y: r.maxY))
        p.closeSubpath()
        return p
    }
}

// MARK: - Service disc

/// One service on the green field: a large disc, the name under it, the live
/// status under that.
///
/// The status line is the one thing Glovo's version doesn't have, and it stays.
/// "142 kitchens open" answers a question you would otherwise have to tap
/// through to ask, and a door that reports something is the whole difference
/// between a menu and a launcher.
private struct ServiceDisc: View {
    let service: Service
    var action: () -> Void = {}

    var body: some View {
        Button(action: action) {
            VStack(spacing: 12) {
                ZStack {
                    // Shows only for the one illustration that carries no disc
                    // of its own; the other three cover it exactly.
                    Circle().fill(IGY.C.artTint)
                    Image(service.artwork)
                        .resizable()
                        .scaledToFill()
                }
                .frame(width: 108, height: 108)
                .clipShape(.circle)
                .overlay(
                    Circle().strokeBorder(.white.opacity(0.28), lineWidth: 1)
                )

                VStack(spacing: 2) {
                    Text(service.title)
                        .textRole(.rowTitle, IGY.C.onBrand)
                        .lineLimit(1)
                        .minimumScaleFactor(0.8)
                    Text(service.status)
                        .textRole(.caption, IGY.C.onBrandMuted)
                        .lineLimit(1)
                        .minimumScaleFactor(0.85)
                }
                .multilineTextAlignment(.center)
            }
            .frame(maxWidth: .infinity)
            .contentShape(.rect)
        }
        .buttonStyle(PressableCard())
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(service.title). \(service.status)")
    }
}
