import SwiftUI

// Food.
//
// Two decisions carry this screen.
//
// **Multiple carts at once.** Ordering from three kitchens is a normal thing to
// want, and every super-app makes you abandon one cart to start another. Here
// all of them stay open: the dock shows the one you touched last, and one tap
// opens the rest. Each checks out separately. Consequences, all visible —
// restaurant cards carry an "N in cart" tag so the list agrees with the dock,
// and a closed kitchen keeps its cart but offers Remove rather than Checkout.
//
// **A header that doesn't leave.** Search and the cuisine rail are pinned; the
// filter row rides with them but hides as you scroll down and returns the
// moment you scroll up. The split is deliberate: a category changes *what
// you're looking at* and you need it constantly, while a filter narrows a
// choice you already made and is mostly set once. Pinning both would spend a
// third of the screen on chrome; pinning neither would mean scrolling to the
// top to change cuisine.
//
// The whole pinned stack is one glass surface rather than three stacked ones —
// glass on glass is the thing Apple's guidance is most explicit about
// avoiding, and one panel also lets the filter row's hide/show read as the
// surface resizing rather than as a second bar appearing.

struct FoodScreen: View {
    @Environment(AppState.self) private var app

    @State private var query = ""
    @State private var category = Mock.foodCategories[0].id
    @State private var activeFilters: Set<String> = []
    @State private var showingFilters = true
    /// Honours `-showCarts 1`, the same convention as `-startTab`,
    /// `-startService` and `-rideStep`: a screenshot pass can't tap, so any
    /// state worth capturing needs a way to be opened from the command line.
    @State private var showingAllCarts =
        UserDefaults.standard.bool(forKey: "showCarts")
    @State private var dockDismissed = false

    var body: some View {
        ZStack(alignment: .bottom) {
            ScrollView {
                VStack(alignment: .leading, spacing: 0) {
                    orderAgain
                    kitchens

                    // Clears the cart dock.
                    Color.clear.frame(height: 128)
                }
            }
            .scrollIndicators(.hidden)
            .background(IRob.C.surface)
            .safeAreaInset(edge: .top, spacing: 0) { pinnedHeader }
            // Scroll direction, not position: the filter row answers "are you
            // moving away from the top or back toward it", which position alone
            // can't tell you.
            .onScrollGeometryChange(for: CGFloat.self) { $0.contentOffset.y } action: { old, new in
                let delta = new - old
                // Below the threshold this fires on rubber-banding and on the
                // half-point jitter of a finger resting on the glass, and the
                // row flickers.
                guard abs(delta) > 6 else { return }
                let wantsVisible = delta < 0 || new < 40
                guard wantsVisible != showingFilters else { return }
                withAnimation(.easeOut(duration: 0.22)) { showingFilters = wantsVisible }
            }

            if !dockDismissed, !app.carts.isEmpty {
                cartDock
            }

            if showingAllCarts {
                allCarts
            }
        }
        .background(IRob.C.surface)
        // Feedback the framework provides and we were doing without: a detent
        // tick when a category or filter changes what the list shows, and a
        // heavier one when a cart is destroyed.
        .sensoryFeedback(.selection, trigger: category)
        .sensoryFeedback(.selection, trigger: activeFilters)
        .sensoryFeedback(.impact(weight: .medium), trigger: app.carts.count)
    }

    /// The expanded carts panel, presented by hand rather than with `.sheet`.
    ///
    /// A `UISheetPresentationController` clips to its own bounds, so a control
    /// placed above the panel's top edge gets sliced in half — which is what
    /// happened to the close button on the first attempt, and is why Zomato's
    /// version can't be a system sheet either. Presenting it ourselves is what
    /// lets the × float clear of the panel the way the "All" tab floats clear
    /// of the dock.
    ///
    /// What the system sheet was giving us and now has to be written: the dim
    /// layer, tap-outside to close, and drag-down to close.
    private var allCarts: some View {
        ZStack(alignment: .bottom) {
            Rectangle()
                .fill(.black.opacity(0.34))
                .ignoresSafeArea()
                .onTapGesture { closeAllCarts() }
                .accessibilityAddTraits(.isButton)
                .accessibilityLabel("Close")

            VStack(spacing: 14) {
                CircleButton(symbol: "xmark", size: 46, action: closeAllCarts)
                    .accessibilityLabel("Close")

                AllCartsPanel(carts: app.carts,
                              total: Mock.cartTotal,
                              onRemove: { app.removeCart($0) },
                              onClearAll: {
                                  app.clearCarts()
                                  closeAllCarts()
                              },
                              onDismiss: closeAllCarts)
                    .accessibilityAddTraits(.isModal)
            }
            .padding(.bottom, IRob.S.dockBottom)
            .ignoresSafeArea(edges: .bottom)
        }
        .transition(.opacity)
        .zIndex(1)
    }

    private func closeAllCarts() {
        withAnimation(.easeOut(duration: 0.2)) { showingAllCarts = false }
    }

    // MARK: Pinned header

    /// The glass in this header is on the *controls*, not on the panel behind
    /// them.
    ///
    /// Putting it on both would be glass over glass, which is the one layering
    /// Apple's guidance rules out outright — the material samples what's behind
    /// it, and when what's behind it is also sampling, the result goes flat and
    /// muddy instead of deeper. So the panel is an opaque-ish scroll edge and
    /// the back button, search field and filter chips are the glass, all inside
    /// one `GlassEffectContainer` so they sample together and blend where they
    /// sit near each other rather than each fetching its own backdrop.
    private var pinnedHeader: some View {
        VStack(spacing: 0) {
            HStack(spacing: 12) {
                CircleButton(symbol: "arrow.left", size: 38) {
                    app.presentedService = nil
                }
                .accessibilityLabel("Back")

                searchField
            }
            .padding(.horizontal, IRob.S.dockInset)
            .padding(.top, 6)

            categoryRail
                .padding(.top, 14)

            if showingFilters {
                filterRail
                    .padding(.top, 12)
                    .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .padding(.bottom, 12)
        .frame(maxWidth: .infinity)
        .background {
            Rectangle()
                .fill(IRob.C.surface.opacity(0.94))
                .ignoresSafeArea(edges: .top)
        }
    }

    private var searchField: some View {
        HStack(spacing: 10) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 15, weight: .semibold))
                .foregroundStyle(IRob.C.inkMuted)

            TextField("Restaurant or dish", text: $query)
                .textRole(.rowTitleSm)
                .submitLabel(.search)

            if !query.isEmpty {
                Button { query = "" } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 15))
                        .foregroundStyle(IRob.C.inkMuted)
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Clear search")
            }
        }
        .padding(.horizontal, 16)
        .frame(height: 44)
        .glassEffect(.regular, in: .capsule)
    }

    /// The cuisine rail. Selection is an underline rather than a filled pill —
    /// a pill here would compete with the filter chips one row below it, and
    /// the two rows have to look like different kinds of control.
    private var categoryRail: some View {
        ScrollView(.horizontal) {
            HStack(alignment: .top, spacing: 18) {
                ForEach(Mock.foodCategories) { item in
                    let isOn = item.id == category
                    Button {
                        withAnimation(.easeOut(duration: 0.18)) { category = item.id }
                    } label: {
                        VStack(spacing: 7) {
                            item.art.placeholder.stripeWidth(5)
                                .frame(width: 46, height: 46)
                                .clipShape(Circle())
                                .overlay(Circle().strokeBorder(IRob.C.hairline, lineWidth: 1))
                                .opacity(isOn ? 1 : 0.72)

                            Text(item.name)
                                .textRole(.chip, isOn ? IRob.C.ink : IRob.C.inkMuted)
                                .fixedSize()

                            Capsule()
                                .fill(isOn ? IRob.C.brand : .clear)
                                .frame(width: 22, height: 2.5)
                        }
                    }
                    .buttonStyle(.plain)
                    .accessibilityAddTraits(isOn ? [.isSelected] : [])
                }
            }
            .padding(.horizontal, IRob.S.gutter)
        }
        .scrollIndicators(.hidden)
    }

    private var filterRail: some View {
        ScrollView(.horizontal) {
            HStack(spacing: 8) {
                ForEach(Mock.foodFilters, id: \.self) { name in
                    FilterChip(name: name, isOn: activeFilters.contains(name)) {
                        withAnimation(.easeOut(duration: 0.16)) {
                            if activeFilters.contains(name) {
                                activeFilters.remove(name)
                            } else {
                                activeFilters.insert(name)
                            }
                        }
                    }
                }
            }
            .padding(.horizontal, IRob.S.gutter)
        }
        .scrollIndicators(.hidden)
    }

    // MARK: Content

    private var orderAgain: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Order it again")
                .textRole(.section)
                .padding(.horizontal, IRob.S.gutter)

            ScrollView(.horizontal) {
                HStack(alignment: .top, spacing: 12) {
                    ForEach(Mock.orderAgain) { dish in
                        VStack(alignment: .leading, spacing: 0) {
                            dish.art.placeholder.caption("dish photo")
                                .frame(width: 150, height: 100)
                                .clipShape(RoundedRectangle(cornerRadius: IRob.R.control,
                                                            style: .continuous))
                                .overlay(
                                    RoundedRectangle(cornerRadius: IRob.R.control,
                                                     style: .continuous)
                                        .strokeBorder(IRob.C.hairline, lineWidth: 1)
                                )
                            Text(dish.name).textRole(.rowTitleSm).padding(.top, 8)
                            Text(dish.price).textRole(.caption, IRob.C.inkMuted)
                        }
                        .frame(width: 150, alignment: .leading)
                    }
                }
                .padding(.horizontal, IRob.S.gutter)
            }
            .scrollIndicators(.hidden)
        }
        .padding(.top, 18)
    }

    private var kitchens: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text(Service.food.status)
                .textRole(.section)
                .padding(.horizontal, IRob.S.gutter)

            ForEach(Mock.restaurants) { r in
                RestaurantCard(restaurant: r)
                    .padding(.horizontal, IRob.S.gutter)
            }
        }
        .padding(.top, 26)
    }

    // MARK: Cart dock

    /// The dock shows one cart — the one you touched last — and offers the rest
    /// behind "All".
    ///
    /// The earlier version listed every cart inline in a tray that was open by
    /// default, which meant the most common case (one cart) paid for the
    /// rarest (three). Showing the latest and hiding the others behind a count
    /// keeps the dock one row tall until you ask otherwise, and the count is
    /// what tells you the others are still there.
    private var cartDock: some View {
        // The "All" tab keeps its own capsule and sits *on* the dock rather
        // than merging into it. It was inside a `GlassEffectContainer` with the
        // capsule, which is the API for making adjacent glass shapes flow into
        // one another — right for a morphing control group, wrong here, because
        // the blend erased the pill's own outline and the two read as one
        // lumpy shape. Two separate capsules, the larger drawn over the
        // smaller, is what says "there are more of these behind this one".
        ZStack(alignment: .top) {
            if let cart = app.carts.last {
                CartDockRow(cart: cart) {
                    withAnimation(.easeOut(duration: 0.2)) { dockDismissed = true }
                }
            }

            // Drawn last, so it sits *over* the capsule rather than behind it.
            // Behind, the capsule cut its bottom off and it read as a tab
            // growing out of the dock; over, it reads as a card resting on the
            // stack — which is the right way round, because tapping it brings
            // the ones underneath forward.
            if app.carts.count > 1 {
                Button {
                    withAnimation(.easeOut(duration: 0.2)) { showingAllCarts = true }
                } label: {
                    HStack(spacing: 5) {
                        Text("All \(app.carts.count)").textRole(.chip)
                        Image(systemName: "chevron.up")
                            .font(.system(size: 9, weight: .bold))
                    }
                }
                .buttonStyle(.glass)
                .buttonBorderShape(.capsule)
                .tint(IRob.C.ink)
                .accessibilityLabel("Show all \(app.carts.count) carts")
                .offset(y: -18)
            }
        }
        .padding(.horizontal, IRob.S.dockInset)
        .padding(.bottom, IRob.S.dockBottom)
        .ignoresSafeArea(edges: .bottom)
        .transition(.move(edge: .bottom).combined(with: .opacity))
    }
}

// MARK: - Filter chip

/// One filter, in the two states the system already has names for.
///
/// `.glass` is the available state and `.glassProminent` the engaged one —
/// the exact distinction Apple built the pair for, so both chips get their
/// press feedback, tint handling and Increase Contrast fallbacks from the
/// framework instead of from two hand-built backgrounds. The chip was a
/// `Text` with a `Capsule` drawn behind it, which had neither.
///
/// The branch is duplicated rather than switched on a variable because
/// `buttonStyle` takes a concrete type — there is no `AnyPrimitiveButtonStyle`.
private struct FilterChip: View {
    let name: String
    let isOn: Bool
    var action: () -> Void

    var body: some View {
        Group {
            if isOn {
                Button(action: action) { Text(name).textRole(.bodySm) }
                    .buttonStyle(.glassProminent)
            } else {
                Button(action: action) { Text(name).textRole(.bodySm) }
                    .buttonStyle(.glass)
            }
        }
        .buttonBorderShape(.capsule)
        .tint(IRob.C.ink)
        .accessibilityAddTraits(isOn ? [.isSelected] : [])
    }
}

// MARK: - Cart dock row

private struct CartDockRow: View {
    let cart: Cart
    var onDismiss: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            cart.art.placeholder.stripeWidth(5)
                .frame(width: 40, height: 40)
                .clipShape(Circle())
                .overlay(Circle().strokeBorder(IRob.C.hairline, lineWidth: 1))

            VStack(alignment: .leading, spacing: 1) {
                Text(cart.restaurant).textRole(.rowTitleSm).lineLimit(1)
                HStack(spacing: 3) {
                    Text("View menu").textRole(.caption, IRob.C.inkMuted)
                    Image(systemName: "chevron.right")
                        .font(.system(size: 8, weight: .bold))
                        .foregroundStyle(IRob.C.inkMuted)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            Button {} label: {
                VStack(spacing: 0) {
                    Text("View cart").textRole(.label, .white)
                    Text("\(cart.itemCount) item\(cart.itemCount == 1 ? "" : "s")")
                        .textRole(.badge, .white.opacity(0.85))
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 9)
                .background(IRob.C.brandDeep, in: Capsule())
            }
            .buttonStyle(.plain)

            Button(action: onDismiss) {
                Image(systemName: "xmark")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(IRob.C.inkMuted)
                    .frame(width: 28, height: 28)
                    .contentShape(.rect)
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Hide carts")
        }
        .padding(.leading, 10)
        .padding(.trailing, 6)
        .padding(.vertical, 9)
        .glassEffect(.regular, in: .capsule)
        .irobShadow(.dock)
    }
}

// MARK: - All carts

/// Every open cart, with the two operations that only make sense across all of
/// them: clear them, or check them all out. Per-cart actions stay on the rows.
private struct AllCartsPanel: View {
    let carts: [Cart]
    let total: String
    var onRemove: (Cart) -> Void
    var onClearAll: () -> Void
    var onDismiss: () -> Void

    @State private var dragY: CGFloat = 0

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(alignment: .firstTextBaseline) {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Your carts").textRole(.sectionSm)
                    Text(total).textRole(.caption, IRob.C.inkMuted)
                }
                Spacer(minLength: 8)
                Button(action: onClearAll) {
                    Text("Clear all").textRole(.label, IRob.C.alert)
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, 18)
            .padding(.top, 20)

            VStack(spacing: 8) {
                ForEach(carts) { cart in
                    CartRow(cart: cart, onRemove: { onRemove(cart) })
                }
            }
            .padding(.horizontal, 12)
            .padding(.top, 14)
            .padding(.bottom, 18)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .glassEffect(.regular,
                     in: .rect(cornerRadius: IRob.R.sheet, style: .continuous))
        .padding(.horizontal, IRob.S.dockInset)
        .offset(y: max(dragY, 0))
        // Drag down to dismiss, which the system sheet used to provide. Only
        // downward: dragging up would imply a taller state this panel doesn't
        // have.
        .gesture(
            DragGesture(minimumDistance: 10)
                .onChanged { dragY = $0.translation.height }
                .onEnded { value in
                    if value.translation.height > 80 {
                        onDismiss()
                    } else {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.85)) {
                            dragY = 0
                        }
                    }
                }
        )
    }
}

/// One cart, as a card on the sheet.
///
/// Solid, not glass: these sit *on* the glass panel, and content laid over
/// chrome is exactly the direction the material is meant to run. Stacking a
/// second glass layer here would flatten both.
private struct CartRow: View {
    let cart: Cart
    var onRemove: () -> Void

    @State private var dragX: CGFloat = 0

    /// How far the row has to travel before letting go removes it.
    private let threshold: CGFloat = 96

    var body: some View {
        let shape = RoundedRectangle(cornerRadius: IRob.R.list, style: .continuous)

        // Tight spacing, because the row now carries a name, a summary, an
        // action and a close in one line. At the previous metrics
        // "Kebabs & Kurries" truncated — and a cart you can't identify is
        // worse than one you can't dismiss in a single tap.
        HStack(spacing: 10) {
            cart.art.placeholder.stripeWidth(6)
                .frame(width: 38, height: 38)
                .clipShape(Circle())
                .overlay(Circle().strokeBorder(IRob.C.hairline, lineWidth: 1))

            VStack(alignment: .leading, spacing: 1) {
                Text(cart.restaurant).textRole(.rowTitleSm).lineLimit(1)
                Text(cart.summary)
                    .textRole(.caption, cart.isAvailable ? IRob.C.inkMuted : IRob.C.alert)
                    .lineLimit(1)
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            action

            // The same × the collapsed dock carries, on every row. The swipe is
            // the faster way out once you know it's there; this is the one you
            // can see.
            Button(action: onRemove) {
                Image(systemName: "xmark")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(IRob.C.inkMuted)
                    .frame(width: 26, height: 26)
                    .contentShape(.rect)
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Remove \(cart.restaurant)")
        }
        .padding(.leading, 10)
        .padding(.trailing, 4)
        .padding(.vertical, 9)
        .background(IRob.C.card, in: shape)
        .opacity(cart.isAvailable ? 1 : 0.7)
        .offset(x: dragX)
        // Left swipe only. It was both directions on the assumption that one
        // destructive action shouldn't care which edge you came from — but a
        // row that follows the finger rightward with no action behind it reads
        // as broken, and leading swipes are the direction iOS reserves for
        // non-destructive actions everywhere else.
        .background {
            shape
                .fill(IRob.C.alert.opacity(min(-dragX / threshold, 1) * 0.9))
                .overlay(alignment: .trailing) {
                    Image(systemName: "trash.fill")
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundStyle(.white)
                        .opacity(-dragX > threshold * 0.55 ? 1 : 0)
                        .padding(.trailing, 22)
                }
        }
        .gesture(
            DragGesture(minimumDistance: 12)
                .onChanged { value in
                    // Vertical drags belong to the panel, which dismisses on
                    // them — claiming those here would make it feel stuck any
                    // time a swipe started slightly off-axis.
                    guard abs(value.translation.width) > abs(value.translation.height)
                    else { return }
                    dragX = min(value.translation.width, 0)
                }
                .onEnded { value in
                    if -value.translation.width > threshold {
                        withAnimation(.easeOut(duration: 0.2)) { dragX = -500 }
                        onRemove()
                    } else {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                            dragX = 0
                        }
                    }
                }
        )
        .accessibilityElement(children: .combine)
        .accessibilityAction(named: "Remove cart", onRemove)
    }

    /// Every checkoutable cart gets the same filled button.
    ///
    /// The first one used to be filled and the rest outlined, on the reasoning
    /// that one view should carry one primary action. That reasoning doesn't
    /// hold here: these carts are peers, each checks out separately, and
    /// ranking them by fill implied an order that doesn't exist — the outlined
    /// ones read as secondary or unavailable rather than as equally ready.
    ///
    /// A closed kitchen shows nothing here. Removing it is the swipe or the ×,
    /// the same as every other row, rather than a control only it has.
    @ViewBuilder
    private var action: some View {
        if cart.isAvailable {
            Button {} label: {
                Text("Checkout")
                    .textRole(.bodySm, .white)
                    .fixedSize()
                    .padding(.horizontal, 13)
                    .padding(.vertical, 9)
                    .background(IRob.C.brandDeep, in: .capsule)
            }
            .buttonStyle(.plain)
        }
    }
}

// MARK: - Restaurant card

private struct RestaurantCard: View {
    let restaurant: Restaurant

    var body: some View {
        Button {} label: {
            VStack(spacing: 0) {
                restaurant.art.placeholder.stripeWidth(9).caption("restaurant photo")
                    .frame(height: 132)

                VStack(alignment: .leading, spacing: 0) {
                    HStack(alignment: .firstTextBaseline, spacing: 10) {
                        Text(restaurant.name).textRole(.cardTitle)
                        Spacer(minLength: 0)
                        Text("\(restaurant.rating) ★")
                            .textRole(.bodySm, IRob.C.brandDeep)
                    }
                    Text(restaurant.cuisine)
                        .textRole(.bodySm, IRob.C.inkMuted)
                        .padding(.top, 3)

                    HStack(spacing: 7) {
                        if !restaurant.eta.isEmpty {
                            Tag(text: restaurant.eta, style: .brand)
                        }
                        if restaurant.freeDelivery {
                            Tag(text: "Free delivery", style: .muted)
                        }
                        // The dock, restated in the list. Without this the two
                        // surfaces would disagree about what's in progress.
                        if restaurant.inCart > 0 {
                            Tag(text: "\(restaurant.inCart) in cart", style: .warn)
                        }
                    }
                    .padding(.top, 10)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 16)
                .padding(.vertical, 14)
                .background(IRob.C.card)
            }
            .clipShape(RoundedRectangle(cornerRadius: IRob.R.card, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: IRob.R.card, style: .continuous)
                    .strokeBorder(IRob.C.hairline, lineWidth: 1)
            )
        }
        .buttonStyle(PressableCard())
        .accessibilityElement(children: .combine)
    }
}
