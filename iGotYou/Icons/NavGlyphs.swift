import SwiftUI

// What's left of the hand-drawn UI glyphs: one badge.
//
// Home, Wallet, Activity, the chevrons, the pin, the bell and the avatar were
// all drawn here, on the argument that SF Symbols would "read as a different
// hand" beside the drawn service icons. That argument didn't survive contact
// with the tab bar: `UITabBar` won't take a `Shape`, so the three tab glyphs
// had to be rendered through `ImageRenderer` into cached template images — a
// whole layer of machinery to reproduce icons the system ships, in a set that
// already tracks weight, scale, Dynamic Type, and the selected and unselected
// treatments without being asked.
//
// The service illustrations are the app's own mark. The furniture around them
// is Apple's, and should look like it.

/// The red count badge that rides on the bell.
///
/// Not a symbol: SF Symbols' numbered badges stop at 50 and carry their own
/// shape, and `.badge()` belongs to a `Tab` or a `List` row, not to a button
/// inside a header. It takes `alert`, not the Food orange — an unread count
/// and a food accent must not share a hue.
struct CountBadge: View {
    let count: Int
    var onDark: Bool = false

    var body: some View {
        Text("\(count)")
            .textRole(.badgeCount, .white)
            .padding(.horizontal, 4)
            .frame(minWidth: 16, minHeight: 16)
            .background(IGY.C.alert, in: Capsule())
            // On the green band the badge has to separate from the bell's
            // translucent well, which is nearly the same value as the red.
            .overlay {
                if onDark { Capsule().strokeBorder(.white.opacity(0.9), lineWidth: 1.5) }
            }
    }
}

#Preview("Count badge") {
    HStack(spacing: 22) {
        CountBadge(count: 7)
        CountBadge(count: 7, onDark: true)
    }
    .padding(40)
    .background(IGY.C.brandDark)
}
