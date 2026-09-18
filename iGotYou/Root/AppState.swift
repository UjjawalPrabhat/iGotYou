import SwiftUI

/// Cross-cutting state: which tab is showing, what's in flight, what's in the
/// carts. Everything else lives as local `@State` on the screen that owns it.
///
/// No persistence — this is a prototype, and a fresh launch showing the same
/// curated moment is a feature, not a limitation.
@Observable
final class AppState {
    /// Honours `-startTab <name>` so a screenshot pass can open straight to a
    /// given tab — the simulator offers no way to tap one from the command line.
    var tab: AppTab = {
        let arg = UserDefaults.standard.string(forKey: "startTab") ?? ""
        return AppTab(rawValue: arg) ?? .home
    }()

    /// Drives the dock pill and Activity's "HAPPENING NOW" block. The pill
    /// pages between these; Home shows all of them, but a service screen shows
    /// only its own — the live pill never crosses services.
    var liveActivities: [LiveActivity] = Mock.liveActivities
    var visibleActivityIndex: Int = 0

    var carts: [Cart] = Mock.carts

    /// Which service flow is presented over the tabs, if any.
    /// Also honours `-startService <name>` for the screenshot pass.
    var presentedService: Service? = {
        let arg = UserDefaults.standard.string(forKey: "startService") ?? ""
        return Service(rawValue: arg)
    }()
    var showingProfile = false

    // MARK: Derived

    var currentActivity: LiveActivity? {
        guard liveActivities.indices.contains(visibleActivityIndex) else {
            return liveActivities.first
        }
        return liveActivities[visibleActivityIndex]
    }

    func activities(for service: Service) -> [LiveActivity] {
        liveActivities.filter { $0.service == service }
    }

    func removeCart(_ cart: Cart) {
        carts.removeAll { $0.id == cart.id }
    }

    func clearCarts() { carts.removeAll() }
}

// MARK: - Tabs

/// Three destinations plus Search.
///
/// Explore was cut from the MVP: it was the only tab that sold discovery
/// rather than doing something, and "Around you" already carries that job on
/// Home without needing a destination of its own.
///
/// Search is a member here only because SwiftUI models it as a `Tab` with
/// `role: .search` — which is what renders it as the detached circular capsule
/// the artboards draw. It is not a peer destination: profile likewise stays on
/// the header avatar rather than becoming a fifth tab. The rule from the scope
/// notes: "One entry point each — nothing with a tab gets a door."
enum AppTab: String, CaseIterable, Identifiable, Hashable {
    case home, wallet, activity, search

    var id: String { rawValue }

    var title: String {
        switch self {
        case .home: "Home"
        case .wallet: "Wallet"
        case .activity: "Activity"
        case .search: "Search"
        }
    }
}
