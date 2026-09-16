import SwiftUI

// Domain models for the prototype.
//
// Deliberately thin: value types holding exactly what the screens display, with
// no networking, persistence or business logic. Anything that would be computed
// server-side (an ETA, a fare, a kitchen count) is stored as the literal string
// the artboard shows, because the design decision is the wording, not the
// arithmetic.

// MARK: - Service

enum Service: String, CaseIterable, Identifiable, Hashable {
    case ride, food, send, rewards

    var id: String { rawValue }

    var title: String {
        switch self {
        case .ride: "Ride"
        case .food: "Food"
        case .send: "Send"
        case .rewards: "Rewards"
        }
    }

    /// The live status line under each door. Every one answers a question the
    /// user would otherwise have to tap through to ask.
    var status: String {
        switch self {
        case .ride: "Bikes 4 min away"
        case .food: "142 kitchens open"
        case .send: "Same day until 6pm"
        case .rewards: "2,480 points"
        }
    }

    /// Ride and Food get taller cards — they're the two services with the most
    /// traffic, and the grid says so.
    var cardHeight: CGFloat {
        switch self {
        case .ride, .food: 146
        case .send, .rewards: 132
        }
    }

    var iconSize: CGFloat {
        switch self {
        case .ride, .food: 48
        case .send, .rewards: 44
        }
    }

    @ViewBuilder
    func icon(size: CGFloat? = nil) -> some View {
        let s = size ?? iconSize
        switch self {
        case .ride:    RideIcon(size: s)
        case .food:    FoodIcon(size: s)
        case .send:    SendIcon(size: s)
        case .rewards: RewardsIcon(size: s)
        }
    }
}

/// The nine services that exist in the catalogue but aren't built yet.
/// They stay on screen rather than being deleted — the scope note is explicit:
/// "a superapp gets simpler through presentation, not subtraction".
enum ComingSoon: String, CaseIterable, Identifiable {
    case dineOut = "Dine out", mart = "Mart", pulsa = "Pulsa"
    case health = "Health", hotels = "Hotels", loans = "Loans"
    case insurance = "Insurance", jastip = "Jastip", subscribe = "Subscribe"

    var id: String { rawValue }
    static var summary: String { "Mart, Dine out, Health and 6 others" }
}

// MARK: - Live activity

/// Something already in flight. Drives the dock pill, and the "HAPPENING NOW"
/// block on Activity.
struct LiveActivity: Identifiable, Hashable {
    let id = UUID()
    var service: Service
    var headline: String          // "Wira is picking up your order"
    var detail: String            // "Kebabs & Kurries · Rp288.400"
    var statusLabel: String       // "ARRIVING 9:58"
    var compactLabel: String      // "9:58" — shown when the dock collapses
    var progress: Int             // filled segments, of 4
    var totalSegments: Int = 4
    var amount: String?
    /// A booked-but-not-started activity shows no pulse and no progress bar.
    var isInMotion: Bool = true
}

// MARK: - Usuals

struct Usual: Identifiable, Hashable {
    let id = UUID()
    var service: Service
    var title: String             // "Home → Campus"
    var detail: String            // "Bike · 11 min · Rp15.200"
    var action: String            // "Book" / "Reorder"
}

// MARK: - Places

struct Place: Identifiable, Hashable {
    let id = UUID()
    var title: String
    var subtitle: String?
    var art: PlaceArt
}

/// Which stripe pair stands in for the photo. Real photography is called out in
/// the design notes as "the single biggest lift available" — leaving these as
/// marked placeholders is honest about what has actually been designed.
enum PlaceArt: Hashable {
    case mint, coral, gold, blue

    @MainActor var placeholder: StripePlaceholder {
        switch self {
        case .mint:  .mint
        case .coral: .coral
        case .gold:  .gold
        case .blue:  .blue
        }
    }
}

// MARK: - Food

struct Restaurant: Identifiable, Hashable {
    let id = UUID()
    var name: String
    var cuisine: String           // "North Indian · Kuta · 1.2 km"
    var rating: String            // "4.7"
    var eta: String               // "32 min"
    var freeDelivery: Bool
    var inCart: Int               // 0 = no cart badge
    var art: PlaceArt
}

/// A cuisine rail entry. These ride in the pinned header and never scroll away,
/// so they're the one piece of Food navigation that's always reachable —
/// which is why they're a separate axis from the filters below them. A category
/// changes *what you're looking at*; a filter narrows what you already chose.
struct FoodCategory: Identifiable, Hashable {
    let id = UUID()
    var name: String
    var art: PlaceArt
}

struct Dish: Identifiable, Hashable {
    let id = UUID()
    var name: String
    var price: String
    var art: PlaceArt
}

/// One restaurant's cart. The multi-cart tray is the key Food decision: three
/// carts open at once, each checking out separately, rather than forcing the
/// user to abandon one to start another.
struct Cart: Identifiable, Hashable {
    let id = UUID()
    var restaurant: String
    var itemCount: Int
    var total: String
    var art: PlaceArt
    /// A closed kitchen can't be checked out — the row offers Remove instead.
    var isAvailable: Bool = true

    var summary: String {
        isAvailable
            ? "\(itemCount) item\(itemCount == 1 ? "" : "s") · \(total)"
            : "\(itemCount) item\(itemCount == 1 ? "" : "s") · Rp0 · kitchen closed"
    }
}

// MARK: - Ride

/// Somewhere you can be picked up or dropped off.
///
/// One type covers recents, saved places, suggestions and the pickup points
/// offered around a building, because they are the same thing to the user — a
/// place with a name, an address and a distance — and differ only in why it is
/// being shown. `kind` carries that reason, and nothing else branches on it.
struct RidePlace: Identifiable, Hashable {
    let id = UUID()
    var name: String
    var address: String
    var distance: String
    var kind: Kind
    /// A shorter form for setting beside a pin. Map labels sit in open space
    /// with nothing to wrap against, so a name long enough to run off the edge
    /// has to be shortened at the source rather than truncated at draw time —
    /// "Park 23 Mall — North ent…" tells you less than "North entrance".
    var mapLabel: String?

    enum Kind: Hashable { case recent, saved, suggested, pickupPoint }

    var pinLabel: String { mapLabel ?? name }
}

/// Now or Later. Scheduling is the first question Grab asks on this screen and
/// it's the right one: it changes what "4 min away" even means, so asking it
/// after the vehicle list would invalidate the list.
enum RideTiming: String, CaseIterable, Identifiable {
    case now = "Now", later = "Later"
    var id: String { rawValue }

    var symbol: String {
        switch self {
        case .now: "bolt.fill"
        case .later: "calendar"
        }
    }
}

struct Vehicle: Identifiable, Hashable {
    let id = UUID()
    var name: String              // "Bike"
    var detail: String            // "4 min away · arrives 9:56"
    var price: String             // "Rp15.200"
    var badge: String?            // "FASTEST"
    var kind: Kind

    enum Kind: Hashable { case bike, car }
}

// MARK: - Wallet

struct Transaction: Identifiable, Hashable {
    let id = UUID()
    var title: String
    var date: String
    var amount: String            // carries its own sign: "−Rp288.400"
    var isCredit: Bool
    var icon: Icon

    enum Icon: Hashable { case ride, food, send, topUp }
}

// MARK: - Activity

struct PastActivity: Identifiable, Hashable {
    let id = UUID()
    var service: Service
    var title: String
    var detail: String            // "Yesterday · completed"
    var action: String?           // "Rebook" / "Reorder" / nil
}

// MARK: - Search

/// One thing you can search for, and what it is. `kind` decides the glyph, so
/// a result announces its own type before you read the label — the whole point
/// of a search that spans a superapp's worth of things.
struct SearchEntry: Identifiable, Hashable {
    let id = UUID()
    var term: String
    var context: String
    var kind: Kind

    enum Kind: Hashable {
        case place, dish, service(Service), address

        @ViewBuilder @MainActor var glyph: some View {
            switch self {
            case .place:   PinGlyph(size: 13, color: IRob.C.inkSecondary, filled: true)
            case .dish:    FoodIcon(size: 18)
            case .address: PinGlyph(size: 13, color: IRob.C.brandDeep)
            case let .service(s): s.icon(size: 18)
            }
        }
    }
}

