import SwiftUI

/// The live-order pill as a tab-view bottom accessory.
///
/// The system supplies the glass, the corner radius and the collapse animation;
/// all this has to do is answer the placement question. `.expanded` is the
/// resting state — full width above the tab bar, headline, status and progress.
/// `.inline` is what it becomes once the tab bar minimises on scroll, sharing
/// the row with the collapsed tabs and the search capsule, and there the only
/// thing worth keeping is the mark and the time.
///
/// Wrapping the accessory in its own view rather than inlining it at the call
/// site matters: `tabViewBottomAccessoryPlacement` is only populated inside the
/// accessory's own hierarchy.
struct LiveOrderAccessory: View {
    let activity: LiveActivity
    var pageCount: Int = 1
    var pageIndex: Int = 0

    @Environment(\.tabViewBottomAccessoryPlacement) private var placement

    var body: some View {
        switch placement {
        case .inline:
            inline
        default:
            expanded
        }
    }

    // MARK: Expanded

    private var expanded: some View {
        // Dots at the trailing edge, not along the bottom.
        //
        // Along the bottom they need a reserved strip, and the accessory's
        // height belongs to the system — so that strip comes out of the
        // content, pushing the badge and both lines of text off the pill's
        // optical centre and squeezing them into the left two-thirds while the
        // right third sat empty. Two problems with one cause.
        //
        // Trailing solves both: the content keeps the full height and spreads
        // into the width the dots now occupy. It costs the textbook page-dot
        // position, but a page control's job is to say "there are others and
        // you can swipe" — which two dots on the trailing edge still say, and
        // the accessibility hint says outright.
        //
        // To flip back: move `PageDots` into an `.overlay(alignment: .bottom)`
        // and restore the bottom padding.
        HStack(spacing: 11) {
            PulseBadge(service: activity.service, pulsing: activity.isInMotion)

            VStack(alignment: .leading, spacing: 3) {
                Text(activity.headline)
                    .textRole(.label)
                    .lineLimit(1)
                    .truncationMode(.tail)

                HStack(spacing: 9) {
                    Text(activity.statusLabel)
                        .textRole(.statusLabel, IRob.C.brandDeep)
                        .fixedSize()

                    if activity.isInMotion {
                        ProgressSegments(filled: activity.progress,
                                         total: activity.totalSegments)
                            // Still capped, just less tightly now there's room.
                            // Stretched to the whole pill the bar read as a
                            // loading indicator for the row itself; at this
                            // width it reads as four stages of a delivery.
                            .frame(maxWidth: 148)
                    }
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            if pageCount > 1 {
                PageDots(count: pageCount, index: pageIndex)
                    .padding(.leading, 2)
            }
        }
        .padding(.horizontal, 14)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(activity.headline). \(activity.statusLabel)")
        .accessibilityHint(pageCount > 1
            ? "Activity \(pageIndex + 1) of \(pageCount). Swipe left or right for the others."
            : "")
    }

    // MARK: Inline

    private var inline: some View {
        // The collapsed row keeps its dots too. They were dropped here on the
        // assumption that a minimised bar should carry the minimum — but the
        // dots aren't decoration, they're the only thing saying a second
        // activity exists and can be swiped to. Losing them on scroll loses the
        // affordance exactly when the pill is smallest and most ambiguous.
        // Trailing here too, for the same reason and to keep one position
        // across both states — dots that move when the bar minimises would
        // read as a different control rather than the same one, smaller.
        HStack(spacing: 8) {
            PulseBadge(service: activity.service,
                       pulsing: activity.isInMotion,
                       size: 24)

            Text(activity.headline)
                .textRole(.label)
                .lineLimit(1)
                .truncationMode(.tail)

            Spacer(minLength: 4)

            Text(activity.compactLabel)
                .textRole(.rowTitleSm, IRob.C.brandDeep)
                .fixedSize()

            if pageCount > 1 {
                PageDots(count: pageCount, index: pageIndex, dot: 4, active: 6)
            }
        }
        .padding(.horizontal, 12)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(activity.headline). \(activity.statusLabel)")
    }
}
