import SwiftUI

// Ride, step three: the vehicle.
//
// Both ends of the journey are settled by the time this screen appears — see
// `RideFlow` for why that ordering matters. Because they are, the list can
// quote a fare and an arrival time instead of a range, which is the whole
// payoff of asking for the vehicle last.
//
// Two options, not five — the fastest and the roomiest — with the trade-off
// stated in the subtitle rather than in a tier name you have to learn.
//
// The dock is replaced by the sheet, and the live pill shows only ride status.

struct RideScreen: View {
    let pickup: RidePlace
    let destination: RidePlace
    /// The driver note taken on the pickup step. Empty means none was given.
    var note: String = ""
    var onBack: () -> Void

    @State private var selected: Vehicle.ID?

    var body: some View {
        ZStack(alignment: .bottom) {
            // Both ends of the journey are labelled on the map itself rather
            // than restated in a card above the vehicle list. The sheet used to
            // carry a read-only route card and a pill for an unrelated booked
            // ride, which left this screen making three claims at once; the map
            // already owns "where", so the sheet is now only "which vehicle".
            MapCanvas(pickupLabel: pickup.name,
                      pickupNote: note,
                      destinationLabel: destination.name)
                .ignoresSafeArea()

            // A back button, and nothing else. The header bar was a title that
            // said "Ride" over a screen that is obviously a ride, plus an
            // opaque band covering the top of the map — the one part of this
            // screen the map most needs, since both endpoints are labelled up
            // there now. Dropping it gives the route roughly 90pt back.
            VStack(spacing: 0) {
                HStack {
                    CircleButton(symbol: "arrow.left", action: onBack)
                        .accessibilityLabel("Back")
                    Spacer(minLength: 0)
                }
                .padding(.horizontal, IRob.S.dockInset)
                .padding(.top, 8)

                Spacer(minLength: 0)
            }

            sheet
        }
        .background(IRob.C.mapBase)
        .onAppear { selected = selected ?? Mock.vehicles.first?.id }
        .sensoryFeedback(.selection, trigger: selected)
    }

    // MARK: Sheet

    private var sheet: some View {
        VStack(spacing: 0) {
            Capsule()
                .fill(IRob.C.hairline)
                .frame(width: 40, height: 4)
                .padding(.top, 12)
                .padding(.bottom, 16)

            Text("CHOOSE A VEHICLE")
                .textRole(.sheetLabel, IRob.C.inkMuted)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.top, 20)
                .padding(.bottom, 10)

            VStack(spacing: 10) {
                ForEach(Mock.vehicles) { v in
                    VehicleRow(vehicle: v, selected: selected == v.id) {
                        withAnimation(.easeOut(duration: 0.18)) { selected = v.id }
                    }
                }
            }

            payAndBook.padding(.top, 18)
        }
        .padding(.horizontal, IRob.S.gutter)
        .padding(.bottom, 30)
        .frame(maxWidth: .infinity)
        // Glass, like every other surface that floats over the map. It was an
        // opaque fill, which made the sheet read as a second screen stacked on
        // the first rather than as a panel the map continues behind.
        .background(
            UnevenRoundedRectangle(topLeadingRadius: IRob.R.sheet,
                                   topTrailingRadius: IRob.R.sheet,
                                   style: .continuous)
                .fill(.clear)
                .glassEffect(.regular,
                             in: .rect(topLeadingRadius: IRob.R.sheet,
                                       bottomLeadingRadius: 0,
                                       bottomTrailingRadius: 0,
                                       topTrailingRadius: IRob.R.sheet,
                                       style: .continuous))
                // The sheet is the bottom edge of the screen; without this the
                // map shows through beneath the home indicator.
                .ignoresSafeArea(edges: .bottom)
        )
    }

    private var payAndBook: some View {
        HStack(spacing: 12) {
            // Payment is a quiet chip, not a step. It is already chosen; the
            // only reason it's on screen is so you can change it before you
            // commit, which is a different job from asking you to pick.
            HStack(spacing: 9) {
                RoundedRectangle(cornerRadius: 4, style: .continuous)
                    .strokeBorder(IRob.C.violet, lineWidth: 2)
                    .frame(width: 22, height: 16)
                VStack(alignment: .leading, spacing: 0) {
                    Text("iRob Wallet").textRole(.label)
                    Text(Mock.walletBalance).textRole(.caption, IRob.C.inkMuted)
                }
                Spacer(minLength: 0)
                ChevronGlyph(size: 7)
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 13)
            .hairlineCard(radius: IRob.R.control)

            PrimaryButton(title: "Book")
        }
    }
}

// MARK: - Vehicle row

private struct VehicleRow: View {
    let vehicle: Vehicle
    let selected: Bool
    var onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 14) {
                Group {
                    switch vehicle.kind {
                    case .bike: RideIcon(size: 42)
                    case .car:  CarIcon(size: 42)
                    }
                }

                VStack(alignment: .leading, spacing: 2) {
                    HStack(spacing: 7) {
                        Text(vehicle.name).textRole(.cardTitle)
                        if let badge = vehicle.badge {
                            Text(badge)
                                .textRole(.badge, IRob.C.brandDeep)
                                .padding(.horizontal, 7)
                                .padding(.vertical, 3)
                                .background(IRob.C.brandTint,
                                            in: RoundedRectangle(cornerRadius: 6,
                                                                 style: .continuous))
                        }
                    }
                    Text(vehicle.detail).textRole(.bodySm, IRob.C.inkMuted)
                }
                .frame(maxWidth: .infinity, alignment: .leading)

                Text(vehicle.price).textRole(.cardTitle)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
            .selectedCard(selected: selected)
            .contentShape(.rect)
        }
        .buttonStyle(.plain)
        .accessibilityElement(children: .combine)
        .accessibilityAddTraits(selected ? [.isSelected] : [])
    }
}

// MARK: - Map

/// A drawn stand-in for the map: grid streets, a couple of arterials, the route
/// polyline and its two endpoints.
///
/// Deliberately not MapKit. A real map would import Apple's cartography — its
/// colours, its type, its density — into the middle of a design system this
/// whole exercise is about, and the surrounding decisions would then be tuned
/// against someone else's surface. The stripe placeholders elsewhere make the
/// same argument.
struct MapCanvas: View {
    /// The pickup step has no route to draw yet — only the one end that's been
    /// settled — so it asks for the map without the polyline and its
    /// destination pin. Drawing a route to a place the user hasn't chosen would
    /// be the map asserting something it doesn't know.
    var showsRoute: Bool = true

    /// Callouts on the two endpoints. On the booking screen these are the only
    /// statement of the route — the sheet below is purely the vehicle choice —
    /// so they carry the names rather than leaving two anonymous markers.
    var pickupLabel: String? = nil
    var pickupNote: String = ""
    var destinationLabel: String? = nil

    var body: some View {
        Canvas { ctx, size in
            ctx.fill(Path(CGRect(origin: .zero, size: size)),
                     with: .color(IRob.C.mapBase))

            // Street grid — 46pt blocks with 2pt seams.
            let step: CGFloat = 48, line: CGFloat = 2
            var x: CGFloat = 0
            while x < size.width {
                ctx.fill(Path(CGRect(x: x + step - line, y: 0,
                                     width: line, height: size.height)),
                         with: .color(IRob.C.mapGrid))
                x += step
            }
            var y: CGFloat = 0
            while y < size.height {
                ctx.fill(Path(CGRect(x: 0, y: y + step - line,
                                     width: size.width, height: line)),
                         with: .color(IRob.C.mapGrid))
                y += step
            }

            // Two arterials and one vertical, to break the regularity.
            ctx.drawLayer { l in
                l.rotate(by: .degrees(-8))
                l.fill(Path(CGRect(x: -60, y: 180, width: size.width + 160, height: 9)),
                       with: .color(IRob.C.mapRoad))
            }
            // The one white arterial. It sat at y=420, which is within a few
            // points of where the bottom sheet's top edge lands on both ride
            // screens — a full-width white bar meeting the sheet there read as
            // a rendering seam rather than as a road. Moved up into open map.
            ctx.fill(Path(CGRect(x: -20, y: 336, width: size.width + 60, height: 14)),
                     with: .color(.white))
            ctx.fill(Path(CGRect(x: 104, y: 0, width: 11, height: 620)),
                     with: .color(IRob.C.mapRoad))

            if showsRoute {
                var route = Path()
                route.move(to: CGPoint(x: 116, y: 260))
                route.addLine(to: CGPoint(x: 292, y: 384))
                ctx.stroke(route, with: .color(IRob.C.brand),
                           style: StrokeStyle(lineWidth: 5, lineCap: .round))
            }
        }
        .overlay(alignment: .topLeading) {
            // Pickup dot with its halo.
            Circle()
                .fill(IRob.C.ink)
                .frame(width: 16, height: 16)
                .overlay(Circle().strokeBorder(IRob.C.ink.opacity(0.14), lineWidth: 4)
                    .frame(width: 24, height: 24))
                .offset(x: 108, y: 252)
        }
        .overlay(alignment: .topLeading) {
            // Pickup callout, above its dot. Above rather than beside, because
            // the route leaves the dot to the right and a label there would sit
            // on top of it.
            if let pickupLabel {
                MapCallout(text: pickupLabel, detail: pickupNote,
                           marker: .dot(IRob.C.ink))
                    .offset(x: 96, y: 196)
            }
        }
        .overlay(alignment: .topLeading) {
            if showsRoute {
                PinGlyph(size: 20, color: IRob.C.coral, filled: true)
                    .offset(x: 282, y: 374)
            }
        }
        .overlay(alignment: .topLeading) {
            // Destination callout, below its pin and pulled left so a long name
            // runs into open map rather than off the trailing edge.
            if let destinationLabel {
                MapCallout(text: destinationLabel, detail: Mock.rideDuration,
                           marker: .pin(IRob.C.coral))
                    .offset(x: 132, y: 404)
            }
        }
        .overlay(alignment: .topLeading) {
            // The "4 min" rider callout — only once there's a route. On the
            // pickup step no vehicle has been chosen, so quoting a rider's
            // arrival would be the map promising something nothing has agreed
            // to yet.
            if showsRoute {
                HStack(spacing: 6) {
                    RideIcon(size: 18, band: .compact)
                    Text(Mock.riderETA).textRole(.chip)
                }
                .padding(.horizontal, 11)
                .padding(.vertical, 5)
                .glassEffect(.regular, in: .capsule)
                .offset(x: 186, y: 300)
            }
        }
    }
}

// MARK: - Map callout

/// A named marker on the map: a mark, the place, and one line of detail.
///
/// The detail line is what keeps these from being decoration — on the pickup it
/// carries the driver note typed two screens earlier, and on the destination it
/// carries the journey time. Without it the callouts would only repeat what the
/// pins already say.
private struct MapCallout: View {
    let text: String
    var detail: String = ""
    let marker: Marker

    enum Marker {
        case dot(Color), pin(Color)

        @ViewBuilder var view: some View {
            switch self {
            case let .dot(c): Circle().fill(c).frame(width: 10, height: 10)
            case let .pin(c): PinGlyph(size: 13, color: c, filled: true)
            }
        }
    }

    var body: some View {
        HStack(spacing: 8) {
            marker.view
            VStack(alignment: .leading, spacing: 1) {
                Text(text).textRole(.chip).lineLimit(1)
                if !detail.isEmpty {
                    // `.caption`, not `.monoCaption` — the mono face is
                    // reserved for placeholder captions like "dish photo", and
                    // a real journey time set in it reads as a stand-in.
                    Text(detail).textRole(.caption, IRob.C.inkMuted).lineLimit(1)
                }
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        // Glass. A callout is chrome sitting on the map, which is the one
        // layer the material is for — and it was the last opaque white capsule
        // left floating over content anywhere in the app.
        .glassEffect(.regular, in: .capsule)
        .accessibilityElement(children: .combine)
    }
}
