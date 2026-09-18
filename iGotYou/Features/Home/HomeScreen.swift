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
// The location is a pill floating in the field rather than a bar pinned to the
// top edge. It is glass, as is the profile button opposite it — they float over
// the green with nothing behind them but the field, which is the layer the
// material is for.
//
// Other scope decisions this screen still encodes:
//   - One entry point each: Wallet and Activity have tabs, so they get no door.
//   - "Around you" replaces the ad slot. Explore was cut as a destination, so
//     the discovery it would have carried lives here instead.
//
// One it no longer encodes: "nothing removed — nine more services stay visible
// as Coming soon". That row is gone, so the other nine are now invisible rather
// than deferred. Worth knowing the scope note in `ComingSoon` no longer
// describes the screen.

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
        // Green at the top, surface everywhere else.
        //
        // A flat green background was simpler but it also painted the bottom
        // safe area, so scrolling to the end of the sheet revealed a green band
        // under it with the dock floating on top. The green only has to reach
        // far enough to cover the status bar, which the content itself still
        // respects — letting the ScrollView ignore the safe area instead left
        // iOS drawing dark status text on dark green.
        .background {
            ZStack(alignment: .top) {
                IGY.C.surface
                IGY.C.brandDark.frame(height: 320)
            }
            .ignoresSafeArea()
        }
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

    /// Where you are, on the left; who you are, on the right.
    ///
    /// The notification bell is gone. Profile sits at the trailing edge, which
    /// is where every other header in the app already puts it — it was in the
    /// middle of a three-item cluster here and nowhere else.
    ///
    /// Both are glass. They float over the green field with nothing behind them
    /// but the field itself, which is exactly the layer the material is for.
    private var locationPill: some View {
        HStack(spacing: 10) {
            Button {} label: {
                HStack(spacing: 6) {
                    Image(systemName: "mappin.and.ellipse")
                        .font(.system(size: 14, weight: .semibold))
                    Text(Mock.location)
                        .textRole(.label)
                        .lineLimit(1)
                    Image(systemName: "chevron.down")
                        .font(.system(size: 10, weight: .bold))
                }
                .foregroundStyle(IGY.C.onBrand)
                .padding(.horizontal, 16)
                .padding(.vertical, 11)
                .glassEffect(.regular, in: .capsule)
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Delivering to \(Mock.location). Change")

            Spacer(minLength: 8)

            Button { app.showingProfile = true } label: {
                Image(systemName: "person.fill")
                    .font(.system(size: 17))
                    .foregroundStyle(IGY.C.onBrand)
                    .frame(width: 42, height: 42)
                    .glassEffect(.regular, in: .circle)
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Your profile")
        }
        .padding(.horizontal, IGY.S.gutter)
    }

    // MARK: The white sheet

    private var sheet: some View {
        VStack(spacing: 0) {
            usuals
                .padding(.top, 24)
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
