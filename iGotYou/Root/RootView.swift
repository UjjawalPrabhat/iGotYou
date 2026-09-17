import SwiftUI

/// The app shell.
///
/// Built on the native iOS 26 `TabView`, which turns out to provide the design's
/// dock almost exactly as drawn:
///
///   - `Tab(role: .search)` plus `.tabViewSearchActivation(.searchTabSelection)`
///     renders the search destination as a **detached circular capsule** beside
///     the tab bar — the 65pt circle in the artboards.
///   - `.tabViewBottomAccessory` puts the live-order pill above the tab bar and
///     collapses it *into* that row on scroll, which is precisely what the Turn 5
///     note describes: "three capsules resolving into one band, the way Apple
///     Music docks its mini player".
///   - `.tabBarMinimizeBehavior(.onScrollDown)` drives that collapse.
///
/// So the scroll-collapse doesn't need hand-rolling, and going native means the
/// glass is the real Liquid Glass — correct blur, correct scroll-edge response,
/// correct accessibility fallbacks — rather than an imitation of it.
struct RootView: View {
    @State private var app = AppState()


    var body: some View {
        @Bindable var app = app

        TabView(selection: $app.tab) {
            // SF Symbols, not drawn glyphs. The custom set had to be
            // rasterised through `ImageRenderer` into template `UIImage`s
            // because `UITabBar` won't take an arbitrary `Shape` — a whole
            // caching layer to get icons the system already ships, in a set
            // that tracks weight, scale, Dynamic Type and the tab bar's own
            // selected/unselected treatment without being asked.
            Tab(AppTab.home.title, systemImage: "house.fill", value: AppTab.home) {
                HomeScreen()
            }

            Tab(AppTab.wallet.title, systemImage: "wallet.bifold.fill",
                value: AppTab.wallet) {
                WalletScreen()
            }

            Tab(AppTab.activity.title, systemImage: "clock.fill",
                value: AppTab.activity) {
                ActivityScreen()
            }

            // The search role only resolves into the detached capsule beside
            // the tab bar when its content is genuinely searchable — a bare
            // destination gets folded back in as an ordinary fourth tab on
            // some iOS 26 builds. `NavigationStack` is what hosts the field
            // the capsule expands into.
            // The search destination. `.searchable` lives inside it, on the
            // screen — see `SearchScreen`.
            Tab(value: AppTab.search, role: .search) {
                NavigationStack { SearchScreen() }
            }
        }
        // This line is what detaches the search capsule from the tab bar.
        //
        // It should be redundant — `Tab(role: .search)` is documented to render
        // as a separate button beside the bar, and on iOS 26 it does, with or
        // without this. iOS 27 changed the default: `TabSearchActivation
        // .automatic` now resolves to a plain fourth tab inside the bar, and
        // only `.searchTabSelection` still asks for the detached capsule that
        // expands into a field. Verified by bisection against both runtimes —
        // on 27 this modifier is the single difference between the two
        // layouts, and neither the bottom accessory nor the minimize behaviour
        // has any bearing on it.
        //
        // Stating it explicitly is right regardless of the version: the
        // separation is a design decision here, not a default we're inheriting.
        .tabViewSearchActivation(.searchTabSelection)
        .tabBarMinimizeBehavior(.onScrollDown)
        .tabViewBottomAccessory {
            if let activity = app.currentActivity {
                LiveOrderAccessory(activity: activity,
                                   pageCount: app.liveActivities.count,
                                   pageIndex: app.visibleActivityIndex)
                    // The dots promise a swipe, so the swipe has to work.
                    .contentShape(.rect)
                    .gesture(
                        DragGesture(minimumDistance: 18)
                            .onEnded { value in
                                guard app.liveActivities.count > 1,
                                      abs(value.translation.width) > abs(value.translation.height)
                                else { return }
                                let step = value.translation.width < 0 ? 1 : -1
                                let next = app.visibleActivityIndex + step
                                guard app.liveActivities.indices.contains(next) else { return }
                                withAnimation(.easeOut(duration: 0.22)) {
                                    app.visibleActivityIndex = next
                                }
                            }
                    )
            }
        }
        .tint(IGY.C.brand)
        .environment(app)
        // Service flows cover the tabs entirely: each replaces the dock with
        // its own bottom furniture — Ride's vehicle sheet, Food's cart tray —
        // so leaving the tab bar visible underneath would put two competing
        // pinned surfaces on one edge.
        .fullScreenCover(item: $app.presentedService) { service in
            ServiceFlow(service: service).environment(app)
        }
    }
}

#Preview { RootView() }

/// Routes a service to its flow.
struct ServiceFlow: View {
    let service: Service

    var body: some View {
        switch service {
        case .ride: RideFlow()
        case .food: FoodScreen()
        case .send, .bills: UnbuiltServiceScreen(service: service)
        }
    }
}

/// Honest placeholder for the two services that have no design yet — entry
/// points exist in the artboards, screens don't.
struct UnbuiltServiceScreen: View {
    @Environment(AppState.self) private var app
    let service: Service

    var body: some View {
        VStack(spacing: 14) {
            Spacer()
            service.icon(size: 48)
            Text(service.title).textRole(.section)
            Text("Not designed yet").textRole(.caption, IGY.C.inkMuted)
            Spacer()
        }
        .frame(maxWidth: .infinity)
        .background(IGY.C.surface)
        .safeAreaInset(edge: .top, spacing: 0) {
            ServiceHeader(title: service.title, service: service,
                          onBack: { app.presentedService = nil })
        }
    }
}
