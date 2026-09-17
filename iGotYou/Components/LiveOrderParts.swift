import SwiftUI

// Parts of the live-order pill.
//
// The pill is the most characterful component in the system and does most of
// the work of making the app feel resourceful: it reports what is already
// happening rather than offering something new. The scope note is strict about
// what it may carry —
//
//   "Dock is live only — it carries activity already in motion (this order,
//    plus a booked ride on the second page), never carts or suggestions"
//
// Its container and collapse behaviour come from the system, via
// `.tabViewBottomAccessory` — see `LiveOrderAccessory`. What lives here are the
// pieces that assembles: the pulsing badge, the segmented progress bar and the
// page dots.

// MARK: - Pulse badge

/// The icon disc with its expanding ring. The ring is the main piece of
/// ambient motion in the app — it's what stops a screenshot-still interface
/// from reading as inert — so it runs only where something is genuinely in
/// motion, never on a merely scheduled item.
struct PulseBadge: View {
    let service: Service
    var pulsing: Bool = true
    var size: CGFloat = 34

    @State private var animating = false
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        ZStack {
            Circle().fill(IGY.C.brandTint)

            if pulsing && !reduceMotion {
                Circle()
                    .strokeBorder(IGY.C.brandBright, lineWidth: 2)
                    .scaleEffect(animating ? 1.5 : 0.85)
                    .opacity(animating ? 0 : 0.9)
                    .animation(
                        .easeOut(duration: 2.2).repeatForever(autoreverses: false),
                        value: animating
                    )
            }

            // The pill's mark is the Food bowl recoloured green regardless of
            // service — it denotes "a delivery in flight", not the Food
            // service. Ride keeps its own glyph because a booked ride isn't a
            // delivery.
            Group {
                if service == .ride {
                    RideIcon(size: size * 0.62, palette: .ride(onCard: true))
                } else {
                    FoodIcon(size: size * 0.64, palette: .deliveryInFlight)
                }
            }
        }
        .frame(width: size, height: size)
        .onAppear { animating = true }
    }
}

// MARK: - Progress segments

/// Four bars, filled left to right. Chosen over a continuous bar because
/// delivery has discrete stages and a smooth fill would imply precision the
/// system doesn't have.
struct ProgressSegments: View {
    let filled: Int
    var total: Int = 4
    var trackColor: Color = IGY.C.ink.opacity(0.14)

    var body: some View {
        HStack(spacing: 3) {
            ForEach(0..<total, id: \.self) { i in
                Capsule()
                    .fill(i < filled ? IGY.C.brand : trackColor)
                    .frame(height: 4)
            }
        }
        .accessibilityHidden(true)
    }
}

// MARK: - Page dots

struct PageDots: View {
    let count: Int
    let index: Int
    /// Diameter of an inactive dot, and of the active one. The collapsed pill
    /// runs both a step smaller — it has roughly half the height to spend and
    /// the dots have to stay subordinate to the headline.
    var dot: CGFloat = 5
    var active: CGFloat = 7

    var body: some View {
        // Circles, not capsules. The active dot used to stretch into a short
        // green bar, which is exactly what the progress segments beside it
        // already are — at the trailing edge the two sat one line apart and the
        // dot read as a fifth segment. Size and colour carry the selection
        // instead of shape, so nothing here looks like a bar.
        HStack(spacing: dot + 1) {
            ForEach(0..<count, id: \.self) { i in
                Circle()
                    .fill(i == index ? IGY.C.brand : IGY.C.ink.opacity(0.22))
                    .frame(width: i == index ? active : dot,
                           height: i == index ? active : dot)
            }
        }
        .animation(.easeOut(duration: 0.2), value: index)
        .accessibilityHidden(true)
    }
}
