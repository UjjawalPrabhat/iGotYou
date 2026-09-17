import SwiftUI

// Activity: in flight above, finished below.
//
// The split is the whole design. "HAPPENING NOW" carries a live count and gets
// full cards with pulse and progress; "Earlier" collapses to a grouped list
// where the only affordance that matters is doing it again. Nothing in between.

struct ActivityScreen: View {
    @Environment(AppState.self) private var app

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                happeningNow
                earlier

                Color.clear.frame(height: 76)
            }
        }
        .scrollIndicators(.hidden)
        .background(IGY.C.surface)
        .safeAreaInset(edge: .top, spacing: 0) {
            GlassHeader(content: .title("Activity"),
                        onAvatar: { app.showingProfile = true })
        }
    }

    // MARK: In flight

    private var happeningNow: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("HAPPENING NOW · \(app.liveActivities.count)")
                .textRole(.eyebrow, IGY.C.brandDeep)

            VStack(spacing: 10) {
                ForEach(app.liveActivities) { activity in
                    LiveActivityCard(activity: activity)
                }
            }
        }
        .padding(.horizontal, IGY.S.gutter)
        .padding(.top, 16)
    }

    // MARK: Finished

    private var earlier: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Earlier").textRole(.sectionSm)

            ListCard {
                ForEach(Array(Mock.pastActivities.enumerated()), id: \.element.id) { i, item in
                    if i > 0 { RowDivider(inset: 57) }
                    PastActivityRow(item: item)
                }
            }
        }
        .padding(.horizontal, IGY.S.gutter)
        .padding(.top, 28)
    }
}

// MARK: - Live card

private struct LiveActivityCard: View {
    let activity: LiveActivity

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(spacing: 12) {
                PulseBadge(service: activity.service,
                           pulsing: activity.isInMotion,
                           size: 40)

                VStack(alignment: .leading, spacing: 1) {
                    Text(activity.headline).textRole(.rowTitle)
                    Text(activity.detail).textRole(.bodySm, IGY.C.inkMuted)
                }
                .frame(maxWidth: .infinity, alignment: .leading)

                if let amount = activity.amount {
                    Text(amount).textRole(.label)
                }
            }

            // A scheduled ride has no progress to show — giving it an empty bar
            // would imply it had stalled rather than not yet started.
            if activity.isInMotion {
                HStack(spacing: 10) {
                    Text(activity.statusLabel)
                        .textRole(.statusLabel, IGY.C.brandDeep)
                        .fixedSize()
                    ProgressSegments(filled: activity.progress,
                                     total: activity.totalSegments,
                                     trackColor: IGY.C.track)
                }
            }
        }
        .padding(16)
        .hairlineCard(radius: IGY.R.card)
        .accessibilityElement(children: .combine)
    }
}

// MARK: - Past row

private struct PastActivityRow: View {
    let item: PastActivity

    var body: some View {
        HStack(spacing: 13) {
            item.service.icon(size: 28)
                // Finished items sit back: same glyph, less presence.
                .opacity(0.75)

            VStack(alignment: .leading, spacing: 1) {
                Text(item.title).textRole(.rowTitleSm)
                Text(item.detail).textRole(.caption, IGY.C.inkMuted)
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            if let action = item.action {
                Button {} label: {
                    Text(action)
                        .textRole(.bodySm, IGY.C.brandDeep)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 7)
                        .overlay(
                            RoundedRectangle(cornerRadius: 11, style: .continuous)
                                .strokeBorder(IGY.C.brandDeep, lineWidth: 1)
                        )
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
    }
}
