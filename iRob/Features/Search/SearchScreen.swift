import SwiftUI

// Search.
//
// This is the destination behind the detached capsule in the dock. It exists as
// a real screen rather than a placeholder for two reasons.
//
// The design one: Grab puts a search field in the green header of every screen,
// which means search competes with the services for the most valuable strip of
// the app. Moving it to its own dock capsule is the trade this redesign makes —
// the header gets to be about *where you are*, and search gets to be one thumb
// reach away instead of one stretch away. That trade only pays off if the
// destination is worth arriving at, so it opens on recent searches and the
// things actually near you rather than on an empty field.
//
// The mechanical one: `Tab(role: .search)` only renders as the separated
// capsule beside the tab bar when its content is genuinely searchable. Without
// a `.searchable` modifier some iOS 26 builds fold it back into the tab bar as
// an ordinary fourth tab, which is exactly the thing this dock is designed not
// to be.

struct SearchScreen: View {
    @Environment(AppState.self) private var app
    @State private var query = ""

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                if query.isEmpty {
                    recents
                    nearYou
                } else {
                    results
                }

                Color.clear.frame(height: 76)
            }
        }
        .scrollIndicators(.hidden)
        .background(IRob.C.surface)
        .searchable(text: $query, prompt: "Search iRob")
        .navigationTitle("Search")
    }

    // MARK: Resting state

    private var recents: some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionHeader(title: "Recent", action: "Clear", small: true)
            ListCard {
                ForEach(Array(Mock.recentSearches.enumerated()), id: \.element.id) { i, item in
                    if i > 0 { RowDivider(inset: 52) }
                    RecentSearchRow(item: item) { query = item.term }
                }
            }
        }
        .padding(.horizontal, IRob.S.gutter)
        .padding(.top, 16)
    }

    /// The same places Home surfaces, reachable without going back to Home.
    /// Search that only answers typed questions wastes the trip.
    private var nearYou: some View {
        VStack(alignment: .leading, spacing: 14) {
            SectionHeader(title: "Around you", small: true)
            HStack(alignment: .top, spacing: 12) {
                ForEach(Mock.aroundYou) { place in
                    PlaceCard(place: place, height: 116)
                }
            }
        }
        .padding(.horizontal, IRob.S.gutter)
        .padding(.top, 28)
    }

    // MARK: Typing

    /// Mock matching — a prefix test over the fixtures. The prototype is making
    /// a claim about what search *shows*, not about how it ranks.
    private var results: some View {
        let hits = Mock.searchables.filter {
            $0.term.localizedCaseInsensitiveContains(query)
        }

        return VStack(alignment: .leading, spacing: 12) {
            if hits.isEmpty {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Nothing for “\(query)”").textRole(.rowTitle)
                    Text("Try a dish, a place, or a service.")
                        .textRole(.caption, IRob.C.inkMuted)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.top, 8)
            } else {
                ListCard {
                    ForEach(Array(hits.enumerated()), id: \.element.id) { i, item in
                        if i > 0 { RowDivider(inset: 52) }
                        RecentSearchRow(item: item) { query = item.term }
                    }
                }
            }
        }
        .padding(.horizontal, IRob.S.gutter)
        .padding(.top, 16)
    }
}

// MARK: - Row

private struct RecentSearchRow: View {
    let item: SearchEntry
    var onTap: () -> Void = {}

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 12) {
                ZStack {
                    Circle().fill(IRob.C.surfaceMuted)
                    item.kind.glyph
                }
                .frame(width: 30, height: 30)

                VStack(alignment: .leading, spacing: 1) {
                    Text(item.term).textRole(.rowTitleSm)
                    Text(item.context).textRole(.caption, IRob.C.inkMuted)
                }
                .frame(maxWidth: .infinity, alignment: .leading)

                ChevronGlyph(size: 7, direction: .right, color: IRob.C.inkMuted)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 13)
            .contentShape(.rect)
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    SearchScreen().environment(AppState())
}
