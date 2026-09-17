import SwiftUI

// Ride, as three screens.
//
// It used to be one: tapping Ride landed straight on a vehicle list with the
// route already filled in, which only worked because the route was a fixture.
// Grab asks three questions in order and the order is right, so this follows it:
//
//   1. Where to?          — destination first, because it's the only thing the
//                           user actually came to say
//   2. Where from, exactly — the pin is approximate; a lobby or a gate is not
//   3. Which vehicle       — now that both ends are known, every price and ETA
//                           on the list is real
//
// Asking for the vehicle before the route is what most ride apps do, and it
// forces the tiers to quote a range instead of a price. Deferring it one step
// is what lets the last screen commit to "Rp15.200" and "arrives 9:56".
//
// The steps are an explicit enum rather than a `NavigationStack` path: every
// screen here carries its own designed header, and a navigation stack would
// either fight it or have to be hidden, which costs the back gesture anyway.

struct RideFlow: View {
    @Environment(AppState.self) private var app

    /// Honours `-rideStep pickup|vehicle`, the same way `AppState` honours
    /// `-startTab` and `-startService`: the simulator gives no way to tap
    /// through a flow from the command line, so a screenshot pass needs to be
    /// able to open each step directly.
    @State private var step: Step = {
        let arg = UserDefaults.standard.string(forKey: "rideStep") ?? ""
        return Step(rawValue: arg) ?? .destination
    }()
    @State private var timing: RideTiming = .now
    @State private var destination: RidePlace?
    @State private var pickup: RidePlace = Mock.pickupPoints[0]
    @State private var pickupNote = ""

    enum Step: String { case destination, pickup, vehicle }

    var body: some View {
        ZStack {
            switch step {
            case .destination:
                DestinationScreen(timing: $timing, onBack: dismiss) { place in
                    destination = place
                    advance(to: .pickup)
                }
                .transition(.move(edge: .leading).combined(with: .opacity))

            case .pickup:
                PickupScreen(pickup: $pickup, note: $pickupNote,
                             onBack: { advance(to: .destination) },
                             onConfirm: { advance(to: .vehicle) })
                    .transition(.move(edge: .trailing).combined(with: .opacity))

            case .vehicle:
                RideScreen(pickup: pickup,
                           destination: destination ?? Mock.recentDestinations[0],
                           note: pickupNote,
                           onBack: { advance(to: .pickup) })
                    .transition(.move(edge: .trailing).combined(with: .opacity))
            }
        }
        .background(IGY.C.surface)
    }

    private func advance(to next: Step) {
        withAnimation(.easeOut(duration: 0.24)) { step = next }
    }

    private func dismiss() { app.presentedService = nil }
}

// MARK: - 1. Where to?

private struct DestinationScreen: View {
    @Binding var timing: RideTiming
    var onBack: () -> Void
    var onPick: (RidePlace) -> Void

    @State private var query = ""
    @State private var tab: Tab = .recent
    @FocusState private var fieldFocused: Bool

    enum Tab: String, CaseIterable, Identifiable {
        case recent = "Recent", suggested = "Suggested", saved = "Saved"
        var id: String { rawValue }

        var places: [RidePlace] {
            switch self {
            case .recent: Mock.recentDestinations
            case .suggested: Mock.suggestedDestinations
            case .saved: Mock.savedDestinations
            }
        }
    }

    /// Typing searches across all three lists at once. Splitting results by
    /// which tab they came from would make the user guess where a place lives
    /// before they can find it.
    private var results: [RidePlace] {
        let all = Tab.allCases.flatMap(\.places)
        guard !query.isEmpty else { return tab.places }
        return all.filter {
            $0.name.localizedCaseInsensitiveContains(query)
                || $0.address.localizedCaseInsensitiveContains(query)
        }
    }

    var body: some View {
        VStack(spacing: 0) {
            header
            routeFields

            if query.isEmpty {
                tabs.padding(.top, 20)
            }

            list
        }
        .background(IGY.C.surface)
        .onAppear { fieldFocused = true }
    }

    // MARK: Header

    private var header: some View {
        ZStack {
            SegmentedPill(selection: $timing)

            HStack {
                CircleButton(symbol: "arrow.left", action: onBack)
                    .accessibilityLabel("Back")
                Spacer()
            }
        }
        .frame(height: 44)
        .padding(.horizontal, IGY.S.gutter)
        .padding(.top, 8)
        .padding(.bottom, 18)
    }

    // MARK: Fields

    /// The origin and destination fields, joined by the dotted rail. The rail
    /// is the whole reason these two aren't just a list of inputs — it says
    /// they're the ends of one journey.
    private var routeFields: some View {
        HStack(alignment: .top, spacing: 12) {
            RouteRail()
                .padding(.top, 16)

            VStack(spacing: 10) {
                Text(Mock.ridePickup)
                    .textRole(.rowTitle)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, 16)
                    .frame(height: 48)
                    .hairlineCard(radius: IGY.R.control)

                TextField("Where to?", text: $query)
                    .textRole(.rowTitle)
                    .focused($fieldFocused)
                    .submitLabel(.search)
                    .padding(.horizontal, 16)
                    .frame(height: 48)
                    .background(IGY.C.card,
                                in: RoundedRectangle(cornerRadius: IGY.R.control,
                                                     style: .continuous))
                    .overlay(
                        RoundedRectangle(cornerRadius: IGY.R.control, style: .continuous)
                            .strokeBorder(fieldFocused ? IGY.C.brandDeep : IGY.C.hairline,
                                          lineWidth: fieldFocused ? 2 : 1)
                    )
            }
        }
        .padding(.horizontal, IGY.S.gutter)
    }

    // MARK: Tabs

    private var tabs: some View {
        HStack(spacing: 8) {
            ForEach(Tab.allCases) { t in
                Button { tab = t } label: {
                    Text(t.rawValue)
                        .textRole(.label, tab == t ? IGY.C.brandDeep : IGY.C.inkMuted)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 9)
                        .background(tab == t ? IGY.C.brandTint : .clear, in: Capsule())
                }
                .buttonStyle(.plain)
                .accessibilityAddTraits(tab == t ? [.isSelected] : [])
            }
            Spacer(minLength: 0)
        }
        .padding(.horizontal, IGY.S.gutter)
    }

    // MARK: List

    private var list: some View {
        ScrollView {
            LazyVStack(spacing: 0) {
                if results.isEmpty {
                    Text("Nothing for “\(query)”")
                        .textRole(.rowTitle, IGY.C.inkMuted)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal, IGY.S.gutter)
                        .padding(.top, 28)
                } else {
                    ForEach(Array(results.enumerated()), id: \.element.id) { i, place in
                        if i > 0 { RowDivider(inset: IGY.S.gutter + 38) }
                        PlaceRow(place: place) { onPick(place) }
                    }
                }
            }
            .padding(.top, 8)
        }
        .scrollIndicators(.hidden)
        .scrollDismissesKeyboard(.immediately)
    }
}

// MARK: - 2. Pick up at?

private struct PickupScreen: View {
    @Binding var pickup: RidePlace
    @Binding var note: String
    var onBack: () -> Void
    var onConfirm: () -> Void

    @State private var editingNote = false
    @FocusState private var noteFocused: Bool
    /// Which row the list is currently settled on. Driven both ways: tapping a
    /// row writes it, and scrolling writes it too, because the list snaps.
    @State private var scrolledID: RidePlace.ID?

    var body: some View {
        ZStack(alignment: .bottom) {
            MapCanvas(showsRoute: false)
                .ignoresSafeArea()
                .overlay(alignment: .topLeading) {
                    PickupMarkers(selectedID: pickup.id)
                }

            VStack(spacing: 0) {
                searchBar
                Spacer(minLength: 0)
            }

            sheet
        }
        .background(IGY.C.mapBase)
        .onAppear { scrolledID = pickup.id }
        .onChange(of: scrolledID) { _, id in
            guard let point = Mock.pickupPoints.first(where: { $0.id == id }) else { return }
            pickup = point
        }
        // The list behaves like a dial, so it should feel like one. This is the
        // detent tick the system uses for pickers everywhere else.
        .sensoryFeedback(.selection, trigger: pickup)
    }

    private var searchBar: some View {
        HStack(spacing: 12) {
            CircleButton(symbol: "arrow.left", action: onBack)
                .accessibilityLabel("Back")

            // The field stays a prompt, not a readout. Which pickup is chosen
            // is already said twice below — by the pin on the map and by the
            // filled row in the sheet — and echoing it a third time up here
            // made the field look answered, when its job is to offer the way
            // out: type somewhere else entirely.
            HStack(spacing: 10) {
                Circle().fill(IGY.C.brand).frame(width: 10, height: 10)
                Text("Pick up at?")
                    .textRole(.rowTitle, IGY.C.inkMuted)
                    .lineLimit(1)
                Spacer(minLength: 0)
            }
            .padding(.horizontal, 16)
            .frame(height: 48)
            .glassEffect(.regular,
                         in: .rect(cornerRadius: IGY.R.control, style: .continuous))
        }
        .padding(.horizontal, IGY.S.dockInset)
        .padding(.top, 8)
    }

    // MARK: Sheet

    private var sheet: some View {
        VStack(spacing: 0) {
            Capsule()
                .fill(IGY.C.hairline)
                .frame(width: 40, height: 4)
                .padding(.top, 12)
                .padding(.bottom, 14)

            pickupList

            noteField
                .padding(.horizontal, IGY.S.gutter)
                .padding(.top, 4)

            PrimaryButton(title: "Choose this pickup", expands: true, action: onConfirm)
                .padding(.horizontal, IGY.S.gutter)
                .padding(.top, 12)
        }
        .padding(.bottom, 30)
        .frame(maxWidth: .infinity)
        // Glass, like the vehicle sheet and every other surface that floats
        // over the map. Opaque, it read as a second screen stacked on the
        // first rather than as a panel the map continues behind.
        .background(
            Rectangle()
                .fill(.clear)
                .glassEffect(.regular,
                             in: .rect(topLeadingRadius: IGY.R.sheet,
                                       bottomLeadingRadius: 0,
                                       bottomTrailingRadius: 0,
                                       topTrailingRadius: IGY.R.sheet,
                                       style: .continuous))
                .ignoresSafeArea(edges: .bottom)
        )
    }

    /// The pickup points, nearest first — full-bleed rows rather than a card.
    ///
    /// The card was wrong here: a boxed list reads as content *about* the map,
    /// and this list isn't about the map, it *is* the map's state. Running the
    /// rows to both edges makes the sheet read as one surface you're moving
    /// through rather than a container holding options.
    ///
    /// It also scrolls to select. The rows snap, and whichever one settles
    /// under the anchor becomes the pickup — so the sheet behaves like a dial
    /// and the pin on the map follows your thumb. Tapping still works and is
    /// the faster path; scrolling is for when you're reading the options rather
    /// than already knowing which one you want.
    private var pickupList: some View {
        ScrollView {
            LazyVStack(spacing: 0) {
                ForEach(Array(Mock.pickupPoints.enumerated()), id: \.element.id) { i, point in
                    VStack(spacing: 0) {
                        if i > 0 {
                            RowDivider(inset: IGY.S.gutter + 33)
                        }
                        PickupRow(point: point, selected: point.id == pickup.id) {
                            select(point.id)
                        }
                    }
                    .id(point.id)
                }
            }
            .scrollTargetLayout()
        }
        // Two and a bit rows. The fraction is deliberate — a list cut cleanly
        // at a row boundary looks complete, and nobody scrolls a list that
        // looks complete.
        .frame(height: 164)
        .scrollTargetBehavior(.viewAligned)
        .scrollPosition(id: $scrolledID, anchor: .top)
        .scrollIndicators(.hidden)
        // The partial row fades out instead of being sliced through its text.
        // A hard cut mid-word reads as a clipping bug; a fade reads as more.
        .mask(
            LinearGradient(stops: [.init(color: .black, location: 0),
                                   .init(color: .black, location: 0.78),
                                   .init(color: .clear, location: 1)],
                           startPoint: .top, endPoint: .bottom)
        )
    }

    private func select(_ id: RidePlace.ID) {
        withAnimation(.easeOut(duration: 0.22)) { scrolledID = id }
    }

    /// A note for the driver. Collapsed to a prompt until it's wanted, because
    /// almost nobody needs it and an always-open text field on the last screen
    /// before a booking reads as a required step.
    private var noteField: some View {
        Button {
            editingNote = true
            noteFocused = true
        } label: {
            HStack(spacing: 10) {
                if editingNote {
                    TextField(Mock.pickupNotePrompt, text: $note)
                        .textRole(.bodySm)
                        .focused($noteFocused)
                        .submitLabel(.done)
                } else {
                    Text(note.isEmpty ? Mock.pickupNotePrompt : note)
                        .textRole(.bodySm, note.isEmpty ? IGY.C.brandDeep : IGY.C.ink)
                        .lineLimit(1)
                }
                Spacer(minLength: 0)
                Image(systemName: editingNote ? "checkmark.circle.fill" : "plus.circle.fill")
                    .font(.system(size: 18))
                    .foregroundStyle(IGY.C.brandDeep)
            }
            .padding(.vertical, 14)
            .contentShape(.rect)
        }
        .buttonStyle(.plain)
        .onSubmit { editingNote = false }
    }
}

// MARK: - Shared pieces

/// The pickup candidates, as map furniture.
///
/// The names are set on the map rather than in floating callout capsules. A
/// capsule is chrome — it sits *over* the map and belongs to the app — whereas
/// a place name drawn flat beside its pin is part of the map, which is what
/// these are: labels on a place that exists whether or not you pick it.
///
/// One pin is large and moves. Selecting a different door slides it there
/// rather than cutting, because the movement is the answer to "where will the
/// driver actually be" — a pin that teleports makes you re-find it, and a pin
/// that travels shows you how far apart the options are.
private struct PickupMarkers: View {
    let selectedID: RidePlace.ID?

    /// Where each candidate sits on the drawn map. Fixed, because the map is a
    /// drawing — see `MapCanvas` on why it isn't MapKit.
    private static let spots: [CGPoint] = [
        CGPoint(x: 142, y: 236),
        CGPoint(x: 236, y: 312),
        CGPoint(x: 104, y: 386),
    ]

    /// Small pin 13pt, large pin 26pt, both centred on the spot — so the label
    /// has to clear the larger one whether or not it's showing.
    private static let labelGap: CGFloat = 26

    private var selectedSpot: CGPoint {
        guard let i = Mock.pickupPoints.firstIndex(where: { $0.id == selectedID })
        else { return Self.spots[0] }
        return Self.spots[min(i, Self.spots.count - 1)]
    }

    var body: some View {
        ZStack(alignment: .topLeading) {
            ForEach(Array(Mock.pickupPoints.enumerated()), id: \.element.id) { i, point in
                let spot = Self.spots[min(i, Self.spots.count - 1)]
                let isOn = point.id == selectedID

                PinGlyph(size: 13, color: IGY.C.brandDeep, filled: true)
                    .opacity(isOn ? 0 : 1)
                    .offset(x: spot.x, y: spot.y)

                Text(point.pinLabel)
                    .textRole(.chip, isOn ? IGY.C.ink : IGY.C.inkSecondary)
                    .fixedSize()
                    .offset(x: spot.x + Self.labelGap, y: spot.y)
            }

            // The chosen pin, drawn once and moved. Last in the stack so it
            // never ends up behind a label.
            PinGlyph(size: 26, color: IGY.C.brand, filled: true)
                .igyShadow(.card)
                .offset(x: selectedSpot.x - 6.5, y: selectedSpot.y - 8)
                .animation(.spring(response: 0.34, dampingFraction: 0.78),
                           value: selectedSpot)
        }
        .accessibilityHidden(true)
    }
}

/// The origin dot, the dotted run, and the destination pin.
private struct RouteRail: View {
    var body: some View {
        VStack(spacing: 5) {
            Circle()
                .strokeBorder(IGY.C.brand, lineWidth: 4)
                .frame(width: 14, height: 14)

            ForEach(0..<3, id: \.self) { _ in
                Circle().fill(IGY.C.hairline).frame(width: 3, height: 3)
            }

            PinGlyph(size: 14, color: IGY.C.coral, filled: true)
        }
        .frame(width: 16)
        .accessibilityHidden(true)
    }
}

/// Now / Later. Hand-built rather than a segmented `Picker` because the two
/// options carry symbols and the control sits on the header's centre line —
/// `.segmented` gives neither, and restyling it is more code than this.
private struct SegmentedPill: View {
    @Binding var selection: RideTiming

    var body: some View {
        HStack(spacing: 2) {
            ForEach(RideTiming.allCases) { option in
                let isOn = option == selection
                Button {
                    withAnimation(.easeOut(duration: 0.18)) { selection = option }
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: option.symbol)
                            .font(.system(size: 12, weight: .semibold))
                        Text(option.rawValue).textRole(.label)
                    }
                    .foregroundStyle(isOn ? IGY.C.ink : IGY.C.inkMuted)
                    .padding(.horizontal, 18)
                    .padding(.vertical, 9)
                    .background {
                        if isOn {
                            Capsule().fill(IGY.C.card).igyShadow(.card)
                        }
                    }
                }
                .buttonStyle(.plain)
                .accessibilityAddTraits(isOn ? [.isSelected] : [])
            }
        }
        .padding(3)
        .background(IGY.C.surfaceMuted, in: Capsule())
    }
}

/// A destination in the Recent / Suggested / Saved list.
private struct PlaceRow: View {
    let place: RidePlace
    var onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack(alignment: .top, spacing: 14) {
                Image(systemName: symbol)
                    .font(.system(size: 17))
                    .foregroundStyle(tint)
                    .frame(width: 24, height: 22)

                VStack(alignment: .leading, spacing: 3) {
                    Text(place.name).textRole(.rowTitle)
                    // Distance first, then the address. The distance is what
                    // tells two similarly-named places apart at a glance; the
                    // address is only there to confirm it.
                    Text("\(place.distance) · \(place.address)")
                        .textRole(.caption, IGY.C.inkMuted)
                        .lineLimit(2)
                        .multilineTextAlignment(.leading)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .padding(.horizontal, IGY.S.gutter)
            .padding(.vertical, 14)
            .contentShape(.rect)
        }
        .buttonStyle(.plain)
        .accessibilityElement(children: .combine)
    }

    private var symbol: String {
        switch place.kind {
        case .recent: "clock.arrow.circlepath"
        case .saved: "heart.fill"
        case .suggested: "sparkles"
        case .pickupPoint: "mappin.circle.fill"
        }
    }

    private var tint: Color {
        switch place.kind {
        case .saved: IGY.C.coral
        case .suggested: IGY.C.brandDeep
        default: IGY.C.inkMuted
        }
    }
}

/// One candidate door on the pickup sheet.
private struct PickupRow: View {
    let point: RidePlace
    let selected: Bool
    var onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 13) {
                Image(systemName: selected ? "largecircle.fill.circle" : "circle")
                    .font(.system(size: 20))
                    .foregroundStyle(selected ? IGY.C.brandDeep : IGY.C.hairline)

                VStack(alignment: .leading, spacing: 2) {
                    Text(point.name).textRole(.rowTitleSm).lineLimit(1)
                    Text("\(point.distance) · \(point.address)")
                        .textRole(.caption, IGY.C.inkMuted)
                        .lineLimit(1)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .padding(.horizontal, IGY.S.gutter)
            .padding(.vertical, 14)
            .frame(maxWidth: .infinity, alignment: .leading)
            // The selected row takes a mint wash as well as the filled radio,
            // edge to edge. Two signals rather than one, because this row is
            // also what the map's pin is showing — they have to be obviously
            // the same thing.
            .background(selected ? IGY.C.brandTint : .clear)
            .contentShape(.rect)
        }
        .buttonStyle(.plain)
        .accessibilityElement(children: .combine)
        .accessibilityAddTraits(selected ? [.isSelected] : [])
    }
}

/// The white disc that carries a single symbol — back arrows, and the map's
/// recentre control.
/// The white disc that carries a single symbol — back arrows, closes, and the
/// map's recentre control.
///
/// `.buttonStyle(.glass)` rather than `.plain` with `.glassEffect` drawn on by
/// hand. The style is the same material, but it also brings the press and
/// highlight states, the focus ring, and the Reduce Transparency and Increase
/// Contrast fallbacks — all of which we were silently doing without. Hand-drawn
/// glass makes a button that *looks* right and doesn't respond to being
/// touched.
struct CircleButton: View {
    let symbol: String
    var size: CGFloat = 40
    var action: () -> Void

    var body: some View {
        Button(action: action) {
            Image(systemName: symbol)
                .font(.system(size: size * 0.4, weight: .semibold))
                // The style supplies its own padding, so the label is sized to
                // the glyph and `size` sets the overall disc.
                .frame(width: size * 0.5, height: size * 0.5)
        }
        .buttonStyle(.glass)
        .buttonBorderShape(.circle)
        .tint(IGY.C.ink)
    }
}

#Preview { RideFlow().environment(AppState()) }
