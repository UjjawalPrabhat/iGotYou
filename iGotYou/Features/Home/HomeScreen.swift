import SwiftUI

// Home.
//
// The scope decisions this screen encodes, from the source notes:
//   - Nothing removed. Four doors are open; nine more stay visible as Coming soon.
//   - Services first. The four cards are the first thing on the screen.
//   - The greeting asks a question — "the question is the structure, not decoration".
//   - Top left is location; the wordmark earns nothing there.
//   - One entry point each: Wallet and Activity have tabs, so they get no door.
//     The grid holds only what isn't already reachable.
//   - "Around you" replaces the ad slot. Explore was cut as a destination, so
//     the discovery it would have carried lives here instead — and in Search,
//     which shows the same places when the field is empty.

struct HomeScreen: View {
    @Environment(AppState.self) private var app

    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                greetingBand

                // The sheet. Everything below the greeting rides on one light
                // surface with a rounded top edge, lifted 28pt into the green.
                // That overlap is what makes the band read as the screen's
                // ground rather than as a banner pasted above the content — and
                // it's the move Grab's own home makes, with their service grid
                // breaking the bottom of the green block.
                VStack(spacing: 0) {
                    VStack(spacing: 12) {
                        serviceGrid
                        ComingSoonCard()
                    }
                    .padding(.horizontal, IGY.S.gutter)
                    .padding(.top, 20)

                    usuals
                    aroundYou

                    // Clears the bottom accessory. TabView reports the tab bar
                    // as safe area but not the accessory riding above it, so
                    // the last section needs its own room.
                    Color.clear.frame(height: 76)
                }
                .frame(maxWidth: .infinity)
                .background(
                    UnevenRoundedRectangle(topLeadingRadius: IGY.R.sheet,
                                           topTrailingRadius: IGY.R.sheet,
                                           style: .continuous)
                        .fill(IGY.C.surface)
                )
                .padding(.top, -28)
            }
        }
        .scrollIndicators(.hidden)
        .background(IGY.C.surface)
        .ignoresSafeArea(edges: .top)
        .overlay(alignment: .top) {
            GlassHeader(
                content: .location(label: "Deliver to",
                                   value: Mock.location,
                                   badge: app.notificationCount),
                onDark: true,
                onBell: { app.showingNotifications = true },
                onAvatar: { app.showingProfile = true }
            )
        }
    }

    // MARK: Greeting

    /// Grab's green block, continued.
    ///
    /// The band was a mint wash through Turn 11. It now runs deep green —
    /// #00562A up under the header, opening to #00873D at the fold — because
    /// that block is the one piece of Grab's chrome you can identify from a
    /// thumbnail, and an iGotYou that reads as a different company fails the brief
    /// before any of the structure gets looked at.
    ///
    /// The greeting sits *inside* it in white, so the question the screen is
    /// built around ("What can we help with?") lands on the brand rather than
    /// beside it. The service cards then break the bottom edge — the band ends
    /// under them, which is what stops the green from reading as a banner.
    private var greetingBand: some View {
        VStack(alignment: .leading, spacing: 3) {
            Spacer(minLength: 0)
            Text(Mock.greeting).textRole(.greeting, IGY.C.onBrand)
            Text(Mock.greetingAsk).textRole(.body, IGY.C.onBrandMuted)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .frame(height: 196, alignment: .bottom)
        .padding(.horizontal, IGY.S.gutter)
        .padding(.bottom, 40)
        .background(
            LinearGradient(
                // Flat until 0.52, which is roughly where the header's own
                // opaque fill ends. The header can't be translucent — white
                // cards scrolling under it would muddy the band — so the
                // gradient has to hold `brandDark` until it clears the header,
                // or a seam appears along the header's bottom edge.
                stops: [
                    .init(color: IGY.C.brandDark, location: 0),
                    .init(color: IGY.C.brandDark, location: 0.52),
                    .init(color: IGY.C.brandMid,  location: 1),
                ],
                startPoint: .top, endPoint: .bottom
            )
            .ignoresSafeArea(edges: .top)
        )
    }

    // MARK: Services

    private var serviceGrid: some View {
        // Two independent columns rather than a LazyVGrid: Ride/Food are 146pt
        // and Send/Bills 132pt, and a grid would force both rows to the
        // taller height and flatten that hierarchy.
        HStack(alignment: .top, spacing: 12) {
            VStack(spacing: 12) {
                ServiceCard(service: .ride) { app.presentedService = .ride }
                ServiceCard(service: .send) { app.presentedService = .send }
            }
            VStack(spacing: 12) {
                ServiceCard(service: .food) { app.presentedService = .food }
                ServiceCard(service: .bills) { app.presentedService = .bills }
            }
        }
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
