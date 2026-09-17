import SwiftUI

// Home.
//
// The scope decisions this screen encodes, from the source notes:
//   - Nothing removed. Four doors are open; nine more stay visible as Coming soon.
//   - Services first — now literally. The grid is the first thing on the
//     screen, with no header above it at all.
//   - One entry point each: Wallet and Activity have tabs, so they get no door.
//     The grid holds only what isn't already reachable.
//   - "Around you" replaces the ad slot. Explore was cut as a destination, so
//     the discovery it would have carried lives here instead — and in Search,
//     which shows the same places when the field is empty.
//
// The green greeting band is gone. It spent about 250pt — a third of the
// screen — on a salutation and a question, above the four things anyone opens
// this app to do. Grab's own home spends that space on services and gets to
// ten of them before the fold; this now reaches four plus the Coming soon row.
//
// The bar above it stays, and stays green: location, notifications and profile
// have no other entry point in the app, and they are the three things a
// delivery app has to keep one tap away. Losing the band under it didn't cost
// the bar its colour — that green strip is the piece of Grab's chrome you can
// identify from a thumbnail, and it now does that job in 92pt instead of 250.

struct HomeScreen: View {
    @Environment(AppState.self) private var app

    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                VStack(spacing: 16) {
                    serviceGrid
                    ComingSoonCard()
                }
                .padding(.horizontal, IGY.S.gutter)
                .padding(.top, 14)

                usuals
                aroundYou

                // Clears the bottom accessory. TabView reports the tab bar as
                // safe area but not the accessory riding above it, so the last
                // section needs its own room.
                Color.clear.frame(height: 76)
            }
        }
        .scrollIndicators(.hidden)
        .background(IGY.C.surface)
        .safeAreaInset(edge: .top, spacing: 0) {
            GlassHeader(
                content: .location(value: Mock.location,
                                   detail: Mock.locationDetail,
                                   badge: app.notificationCount),
                onDark: true,
                onBell: { app.showingNotifications = true },
                onAvatar: { app.showingProfile = true }
            )
        }
    }

    // MARK: Services

    private var serviceGrid: some View {
        // Two independent columns rather than a LazyVGrid. The doors used to
        // be 146pt and 132pt cards, and a grid would have forced both rows to
        // the taller height; they size to their content now, but the columns
        // still have to be free to differ.
        HStack(alignment: .top, spacing: 12) {
            VStack(spacing: 22) {
                ServiceCard(service: .ride) { app.presentedService = .ride }
                ServiceCard(service: .send) { app.presentedService = .send }
            }
            VStack(spacing: 22) {
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
