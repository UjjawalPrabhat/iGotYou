import SwiftUI

// Fixtures.
//
// Every string here is copied verbatim from the artboards. That matters more
// than it sounds: the copy *is* the design in several places — "What can we
// help with?" is the structure of the Home screen, not a caption, and
// "checkout separately" is the whole argument for the multi-cart tray. Names,
// prices and times are kept exactly so the build can be diffed against the
// source screen by screen.

enum Mock {

    // MARK: Identity

    static let location      = "Park 23 Mall"

    // MARK: Live activities
    //
    // Two things in flight. The dock pill pages between them; Activity lists
    // both under "HAPPENING NOW · 2".

    static let liveActivities: [LiveActivity] = [
        LiveActivity(
            service: .food,
            headline: "Wira is picking up your order",
            detail: "Kebabs & Kurries · Rp288.400",
            statusLabel: "ARRIVING 9:58",
            compactLabel: "9:58",
            progress: 2
        ),
        LiveActivity(
            service: .ride,
            headline: "Ride booked for 5:30 PM",
            detail: "Campus → Ngurah Rai Airport",
            statusLabel: "CAMPUS → AIRPORT",
            compactLabel: "5:30",
            progress: 0,
            amount: "Rp64.000",
            isInMotion: false
        ),
    ]

    // MARK: Home

    static let usuals: [Usual] = [
        Usual(service: .ride,
              title: "Home → Campus",
              detail: "Bike · 11 min · Rp15.200",
              action: "Book"),
        Usual(service: .food,
              title: "Your usual lunch",
              detail: "Kebabs & Kurries · Rp75.000",
              action: "Reorder"),
    ]

    static let aroundYou: [Place] = [
        Place(title: "Cafés nearby", subtitle: nil, art: .mint),
        Place(title: "Popular for lunch", subtitle: nil, art: .coral),
    ]

    // MARK: Search
    //
    // Recents come first and are drawn from what this user has actually done in
    // the rest of the fixtures — the same kitchen they have a cart at, the same
    // campus trip that sits in "Your usuals". A search screen that opens on
    // invented history reads as a stock screenshot.

    static let recentSearches: [SearchEntry] = [
        SearchEntry(term: "Kebabs & Kurries", context: "North Indian · 1.2 km",
                    kind: .place),
        SearchEntry(term: "Campus, Jl. Pararaton", context: "Saved place",
                    kind: .address),
        SearchEntry(term: "Nasi campur", context: "Dish · 14 kitchens",
                    kind: .dish),
    ]

    /// Everything the mock index can match. Deliberately spans all four
    /// services: the argument for one search box in a superapp only holds if it
    /// actually crosses them.
    static let searchables: [SearchEntry] = recentSearches + [
        SearchEntry(term: "Warung Bu Made",  context: "Balinese · 0.8 km",      kind: .place),
        SearchEntry(term: "Sate Ayam Pak Tono", context: "Indonesian · 2.4 km", kind: .place),
        SearchEntry(term: "Samosa chaat",    context: "Dish · 6 kitchens",      kind: .dish),
        SearchEntry(term: "Ride to airport", context: "Ngurah Rai · from Rp64.000",
                    kind: .service(.ride)),
        SearchEntry(term: "Send a parcel",   context: "Same day until 6pm",     kind: .service(.send)),
        SearchEntry(term: "Pay a bill",      context: "2 due this week",        kind: .service(.bills)),
        SearchEntry(term: "Park 23 Mall",    context: "Current location",       kind: .address),
    ]

    // MARK: Food

    /// The pinned cuisine rail. "All" leads because it's the resting state, not
    /// a cuisine — clearing a category has to be as easy as choosing one.
    static let foodCategories: [FoodCategory] = [
        FoodCategory(name: "All",      art: .mint),
        FoodCategory(name: "Biryani",  art: .gold),
        FoodCategory(name: "Kebabs",   art: .coral),
        FoodCategory(name: "Nasi",     art: .gold),
        FoodCategory(name: "Sate",     art: .coral),
        FoodCategory(name: "Desserts", art: .blue),
    ]

    /// Filters narrow whatever category is showing. Multi-select, and none of
    /// them is a default — an app that ships with a filter already on is
    /// hiding results it never told you about.
    static let foodFilters = ["Under 30 min", "Free delivery", "4.5+", "Near & fast"]

    static let orderAgain: [Dish] = [
        Dish(name: "Samosa chaat", price: "Rp75.000", art: .coral),
        Dish(name: "Nasi campur",  price: "Rp52.000", art: .gold),
    ]

    static let restaurants: [Restaurant] = [
        Restaurant(name: "Kebabs & Kurries",
                   cuisine: "North Indian · Kuta · 1.2 km",
                   rating: "4.7", eta: "32 min",
                   freeDelivery: true, inCart: 2, art: .coral),
        Restaurant(name: "Warung Bu Made",
                   cuisine: "Balinese · Tuban · 0.8 km",
                   rating: "4.5", eta: "24 min",
                   freeDelivery: false, inCart: 1, art: .mint),
        Restaurant(name: "Sate Ayam Pak Tono",
                   cuisine: "Indonesian · Legian · 2.4 km",
                   rating: "4.8", eta: "",
                   freeDelivery: false, inCart: 0, art: .blue),
    ]

    /// Oldest first. There's no timestamp on `Cart` — the prototype has no
    /// clock — so the dock treats the last element as the most recently touched
    /// cart, and the order here is what makes that true. The closed kitchen
    /// sits in the middle deliberately: it has to be reachable in the full list
    /// without being the one the dock puts forward.
    static let carts: [Cart] = [
        Cart(restaurant: "Kebabs & Kurries",   itemCount: 2, total: "Rp260.000", art: .coral),
        Cart(restaurant: "Nasi Tempong Indra", itemCount: 1, total: "Rp0",
             art: .gold, isAvailable: false),
        Cart(restaurant: "Warung Bu Made",     itemCount: 1, total: "Rp52.000",  art: .mint),
    ]

    static let cartTotal = "Rp312.000 total · checkout separately"

    // MARK: Ride

    static let ridePickup      = "Park 23 Mall"
    static let rideDestination = "Campus, Jl. Pararaton"
    static let rideDuration    = "11 min"
    static let riderETA        = "4 min"

    /// Where you've been, drawn from the same trips that appear in "Your
    /// usuals" and Activity — a recents list that doesn't agree with the rest
    /// of the app reads as filler.
    static let recentDestinations: [RidePlace] = [
        RidePlace(name: "Campus, Jl. Pararaton",
                  address: "Jl. Pararaton No. 12, Kuta, Badung, Bali",
                  distance: "3.4 km", kind: .recent),
        RidePlace(name: "Kebabs & Kurries",
                  address: "Komplek Pertokoan Central Park, Jl. Patih Jelantik, Kuta",
                  distance: "1.2 km", kind: .recent),
        RidePlace(name: "Ngurah Rai International Airport",
                  address: "Jl. Raya Gusti Ngurah Rai, Tuban, Badung, Bali 80362",
                  distance: "6.8 km", kind: .recent),
    ]

    static let savedDestinations: [RidePlace] = [
        RidePlace(name: "Home",
                  address: "Bali Duta Apartments, Jl. Nyangnyang Sari No. 3, Kuta",
                  distance: "0.0 km", kind: .saved),
        RidePlace(name: "Campus",
                  address: "Jl. Pararaton No. 12, Kuta, Badung, Bali",
                  distance: "3.4 km", kind: .saved),
    ]

    static let suggestedDestinations: [RidePlace] = [
        RidePlace(name: "Beachwalk Kuta",
                  address: "Jl. Pantai Kuta, Kuta, Badung, Bali 80361",
                  distance: "2.1 km", kind: .suggested),
        RidePlace(name: "Mal Bali Galeria",
                  address: "Jl. Bypass Ngurah Rai, Kuta, Badung, Bali 80361",
                  distance: "4.6 km", kind: .suggested),
        RidePlace(name: "Seminyak night market",
                  address: "Jl. Kayu Aya, Seminyak, Badung, Bali",
                  distance: "7.2 km", kind: .suggested),
    ]

    /// The doors the driver can actually stop at. The first is where the pin
    /// lands; the rest are what's within a minute's walk.
    static let pickupPoints: [RidePlace] = [
        RidePlace(name: "Park 23 Mall — Main lobby",
                  address: "Jl. Patih Jelantik, Kuta, Badung, Bali 80361",
                  distance: "0.0 km", kind: .pickupPoint,
                  mapLabel: "Main lobby"),
        RidePlace(name: "Park 23 Mall — North entrance",
                  address: "Jl. Patih Jelantik, beside the taxi bay",
                  distance: "80 m", kind: .pickupPoint,
                  mapLabel: "North entrance"),
        RidePlace(name: "Pertamini Anambentot Food Stall",
                  address: "Jl. Nyangnyang Sari, Kuta",
                  distance: "140 m", kind: .pickupPoint,
                  mapLabel: "Pertamini stall"),
    ]

    static let pickupNotePrompt = "Add pickup details (e.g. near the gate)"

    static let vehicles: [Vehicle] = [
        Vehicle(name: "Bike",
                detail: "4 min away · arrives 9:56",
                price: "Rp15.200", badge: "FASTEST", kind: .bike),
        Vehicle(name: "Car",
                detail: "6 min away · up to 4 seats",
                price: "Rp42.000", badge: nil, kind: .car),
    ]

    // MARK: Wallet

    static let walletLabel   = "IGOTYOU WALLET"
    static let walletBalance = "Rp412.000"
    static let rewardPoints  = "2,480 pts"
    static let voucherCount  = "2 vouchers"

    static let transactions: [Transaction] = [
        Transaction(title: "Kebabs & Kurries", date: "Today, 9:41",
                    amount: "−Rp288.400", isCredit: false, icon: .food),
        Transaction(title: "Ride to Campus",   date: "Yesterday, 8:12",
                    amount: "−Rp15.200",  isCredit: false, icon: .ride),
        Transaction(title: "Top up",           date: "Mon, 14 Sep",
                    amount: "+Rp500.000", isCredit: true,  icon: .topUp),
        Transaction(title: "Parcel to Denpasar", date: "Sun, 13 Sep",
                    amount: "−Rp34.000",  isCredit: false, icon: .send),
    ]

    // MARK: Activity

    static let pastActivities: [PastActivity] = [
        PastActivity(service: .ride, title: "Home → Campus",
                     detail: "Yesterday · completed", action: "Rebook"),
        PastActivity(service: .food, title: "Warung Bu Made",
                     detail: "Mon · delivered", action: "Reorder"),
        PastActivity(service: .send, title: "Parcel to Denpasar",
                     detail: "Sun · delivered", action: nil),
    ]
}
