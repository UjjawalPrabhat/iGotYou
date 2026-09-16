import SwiftUI

// The four service icons, ported from set 9a of the icon exploration.
//
// Construction rules, from `iRob Icon Language.dc.html` (Turn 9):
//   - 40×40 viewBox, charcoal #2B3330 ink (not pure black), flat colour inside
//   - round linejoin and linecap throughout
//   - no container, no ground shadow — the finalised Home puts all four cards on
//     the same light surface, which as Turn 10 notes is "the hard case: the
//     icons alone have to tell the four services apart"
//   - motion ticks appear "only on things that move", and only at hero size
//
// Stroke weight is set per size band rather than scaled, because the source
// deliberately thickens the ink as the icon shrinks to hold optical weight
// constant: 2.0 at 44–48, 2.4 at 28, 2.6 at 21–24.
//
// Each sub-path is filled and then stroked in place, matching SVG's paint order
// — a single merged Path would lose the per-shape fills.

// MARK: - Geometry helpers

/// Maps the 40-unit design grid onto whatever frame the icon is given.
struct Grid {
    let s: CGFloat
    init(_ size: CGFloat) { s = size / 40 }
    func p(_ x: CGFloat, _ y: CGFloat) -> CGPoint { CGPoint(x: x * s, y: y * s) }
    func v(_ n: CGFloat) -> CGFloat { n * s }
}

/// One filled-and-stroked sub-path.
struct Stroked: View {
    let path: Path
    let fill: Color?
    let ink: Color
    let width: CGFloat

    var body: some View {
        ZStack {
            if let fill { path.fill(fill) }
            path.stroke(ink, style: StrokeStyle(lineWidth: width,
                                                lineCap: .round,
                                                lineJoin: .round))
        }
    }
}

// MARK: - Size bands

enum IconBand {
    case hero      // 44–48pt — service cards
    case row       // 28–30pt — "Your usuals" list rows
    case compact   // 21–24pt — the live-order pill

    var stroke: CGFloat {
        switch self {
        case .hero: 2.0
        case .row: 2.4
        case .compact: 2.6
        }
    }

    /// Ticks only ever render at hero size.
    var showsTicks: Bool { self == .hero }

    static func forSize(_ size: CGFloat) -> IconBand {
        switch size {
        case ..<26: .compact
        case ..<40: .row
        default: .hero
        }
    }
}

// MARK: - Ride

/// Scooter: body cowl, handlebar stem, two wheels, a gold front fairing,
/// and two speed ticks trailing behind.
struct RideIcon: View {
    var size: CGFloat = 48
    var palette: IconPalette = .init(primary: IRob.C.brandBright,
                                     secondary: Color(hex: 0xF5F8F7),
                                     tertiary: IRob.C.gold)
    var ink: Color = IRob.C.iconInk
    var band: IconBand? = nil

    private var b: IconBand { band ?? .forSize(size) }

    var body: some View {
        let g = Grid(size)
        let w = g.v(b.stroke)

        return ZStack {
            // Body cowl — rounded top corners via quadratic curves.
            Stroked(path: Path { p in
                p.move(to: g.p(9, 20))
                p.addLine(to: g.p(9, 13))
                p.addQuadCurve(to: g.p(11, 11), control: g.p(9, 11))
                p.addLine(to: g.p(17, 11))
                p.addQuadCurve(to: g.p(19, 13), control: g.p(19, 11))
                p.addLine(to: g.p(19, 20))
                p.closeSubpath()
            }, fill: palette.primary, ink: ink, width: w)

            // Handlebar stem.
            Stroked(path: Path { p in
                p.move(to: g.p(19, 21))
                p.addLine(to: g.p(24, 21))
                p.addLine(to: g.p(27, 15))
                p.addLine(to: g.p(30, 15))
            }, fill: nil, ink: ink, width: w)

            // Wheels.
            Stroked(path: Path(ellipseIn: CGRect(x: g.v(11 - 4.5), y: g.v(27 - 4.5),
                                                 width: g.v(9), height: g.v(9))),
                    fill: palette.secondary, ink: ink, width: w)
            Stroked(path: Path(ellipseIn: CGRect(x: g.v(28 - 4.5), y: g.v(27 - 4.5),
                                                 width: g.v(9), height: g.v(9))),
                    fill: palette.secondary, ink: ink, width: w)

            // Front fairing.
            Stroked(path: Path { p in
                p.move(to: g.p(27, 15))
                p.addLine(to: g.p(31, 21))
                p.addLine(to: g.p(28, 26))
            }, fill: palette.tertiary, ink: ink, width: w)

            if b.showsTicks {
                Path { p in
                    p.move(to: g.p(4, 17)); p.addLine(to: g.p(7, 17))
                    p.move(to: g.p(3, 22)); p.addLine(to: g.p(6, 22))
                }
                .stroke(IRob.C.speedTick,
                        style: StrokeStyle(lineWidth: g.v(1.8), lineCap: .round))
            }
        }
        .frame(width: size, height: size)
    }
}

// MARK: - Food

/// Domed cloche: dome, broth band, the plate curve beneath, stem and knob.
struct FoodIcon: View {
    var size: CGFloat = 48
    var palette: IconPalette = .init(primary: IRob.C.coral,
                                     secondary: IRob.C.gold,
                                     tertiary: Color(hex: 0xF5F8F7),
                                     quaternary: IRob.C.coral)
    var ink: Color = IRob.C.iconInk
    var band: IconBand? = nil

    private var b: IconBand { band ?? .forSize(size) }

    var body: some View {
        let g = Grid(size)
        let w = g.v(b.stroke)

        ZStack {
            // Dome.
            Stroked(path: Path { p in
                p.move(to: g.p(9, 19))
                p.addQuadCurve(to: g.p(20, 13), control: g.p(11, 13))
                p.addQuadCurve(to: g.p(31, 19), control: g.p(29, 13))
                p.closeSubpath()
            }, fill: palette.primary, ink: ink, width: w)

            // Broth band.
            Stroked(path: Path { p in
                p.move(to: g.p(9, 19))
                p.addQuadCurve(to: g.p(20, 23), control: g.p(11, 23))
                p.addQuadCurve(to: g.p(31, 19), control: g.p(29, 23))
            }, fill: palette.secondary, ink: ink, width: w)

            // Plate.
            Stroked(path: Path { p in
                p.move(to: g.p(8, 25.5))
                p.addQuadCurve(to: g.p(32, 25.5), control: g.p(20, 29.5))
            }, fill: palette.tertiary, ink: ink, width: w)

            // Stem + knob.
            Stroked(path: Path { p in
                p.move(to: g.p(20, 13)); p.addLine(to: g.p(20, 10))
            }, fill: nil, ink: ink, width: w)
            Stroked(path: Path(ellipseIn: CGRect(x: g.v(18), y: g.v(6.6),
                                                 width: g.v(4), height: g.v(4))),
                    fill: palette.quaternary, ink: ink, width: w)
        }
        .frame(width: size, height: size)
    }
}

// MARK: - Send

/// Isometric parcel: lid rhombus, left face, right face. Three tones of blue
/// do the work that a light source would — there is no shading here.
struct SendIcon: View {
    var size: CGFloat = 44
    var palette: IconPalette = .init(primary: IRob.C.blueLight,
                                     secondary: IRob.C.blueMid,
                                     tertiary: IRob.C.blueDeep)
    var ink: Color = IRob.C.iconInk
    var band: IconBand? = nil

    private var b: IconBand { band ?? .forSize(size) }

    var body: some View {
        let g = Grid(size)
        let w = g.v(b.stroke)

        ZStack {
            Stroked(path: Path { p in
                p.move(to: g.p(20, 9)); p.addLine(to: g.p(32, 14.5))
                p.addLine(to: g.p(20, 20)); p.addLine(to: g.p(8, 14.5))
                p.closeSubpath()
            }, fill: palette.primary, ink: ink, width: w)

            Stroked(path: Path { p in
                p.move(to: g.p(8, 14.5)); p.addLine(to: g.p(8, 26))
                p.addLine(to: g.p(20, 31.5)); p.addLine(to: g.p(20, 20))
                p.closeSubpath()
            }, fill: palette.secondary, ink: ink, width: w)

            Stroked(path: Path { p in
                p.move(to: g.p(32, 14.5)); p.addLine(to: g.p(32, 26))
                p.addLine(to: g.p(20, 31.5)); p.addLine(to: g.p(20, 20))
                p.closeSubpath()
            }, fill: palette.tertiary, ink: ink, width: w)
        }
        .frame(width: size, height: size)
    }
}

// MARK: - Rewards

/// Gift: tapered box, lid bar, centre ribbon, and a bow built from four
/// quadratic curves meeting at the ribbon's top.
struct RewardsIcon: View {
    var size: CGFloat = 44
    var palette: IconPalette = .init(primary: IRob.C.goldShade,
                                     secondary: IRob.C.gold,
                                     tertiary: IRob.C.coral)
    var ink: Color = IRob.C.iconInk
    var band: IconBand? = nil

    private var b: IconBand { band ?? .forSize(size) }

    var body: some View {
        let g = Grid(size)
        let w = g.v(b.stroke)

        ZStack {
            // Box.
            Stroked(path: Path { p in
                p.move(to: g.p(9, 18)); p.addLine(to: g.p(31, 18))
                p.addLine(to: g.p(29.5, 31)); p.addLine(to: g.p(10.5, 31))
                p.closeSubpath()
            }, fill: palette.primary, ink: ink, width: w)

            // Lid.
            Stroked(path: Path(roundedRect: CGRect(x: g.v(7), y: g.v(12.5),
                                                   width: g.v(26), height: g.v(6)),
                               cornerRadius: g.v(2)),
                    fill: palette.secondary, ink: ink, width: w)

            // Ribbon.
            Stroked(path: Path { p in
                p.move(to: g.p(20, 12.5)); p.addLine(to: g.p(20, 31))
            }, fill: nil, ink: ink, width: w)

            // Bow.
            Stroked(path: Path { p in
                p.move(to: g.p(20, 12.5))
                p.addQuadCurve(to: g.p(13.5, 9),  control: g.p(13, 12.5))
                p.addQuadCurve(to: g.p(17, 7.5),  control: g.p(14, 6))
                p.addQuadCurve(to: g.p(20, 12.5), control: g.p(19.5, 8.8))
                p.addQuadCurve(to: g.p(23, 7.5),  control: g.p(20.5, 8.8))
                p.addQuadCurve(to: g.p(26.5, 9),  control: g.p(26, 6))
                p.addQuadCurve(to: g.p(20, 12.5), control: g.p(27, 12.5))
                p.closeSubpath()
            }, fill: palette.tertiary, ink: ink, width: w)
        }
        .frame(width: size, height: size)
    }
}

// MARK: - Car

/// Car, in the same hand as the four service icons: rounded cabin over a body
/// box, a window line, two wheels.
///
/// It lives here rather than in `RideScreen` — it is an icon, and the version
/// that lived beside the vehicle list had its own copy of the grid maths, its
/// own fill-then-stroke scaffolding, and the shell path written out twice,
/// once to fill and once to stroke. All three are `Grid` and `Stroked` above,
/// which is what every other icon in the set already uses.
struct CarIcon: View {
    var size: CGFloat = 42
    var palette: IconPalette = .init(primary: IRob.C.blueMid,
                                     secondary: Color(hex: 0xF5F8F7))
    var ink: Color = IRob.C.iconInk
    var band: IconBand? = nil

    private var b: IconBand { band ?? .forSize(size) }

    var body: some View {
        let g = Grid(size)
        let w = g.v(b.stroke)

        ZStack {
            // Shell.
            Stroked(path: Path { p in
                p.move(to: g.p(7, 24))
                p.addLine(to: g.p(7, 19))
                p.addQuadCurve(to: g.p(8.5, 17), control: g.p(7, 17.5))
                p.addLine(to: g.p(12, 12))
                p.addQuadCurve(to: g.p(15, 10.5), control: g.p(13, 10.5))
                p.addLine(to: g.p(25, 10.5))
                p.addQuadCurve(to: g.p(28, 12), control: g.p(27, 10.5))
                p.addLine(to: g.p(31.5, 17))
                p.addQuadCurve(to: g.p(33, 19), control: g.p(33, 17.5))
                p.addLine(to: g.p(33, 24))
                p.closeSubpath()
            }, fill: palette.primary, ink: ink, width: w)

            // Window line.
            Stroked(path: Path { p in
                p.move(to: g.p(11.5, 17)); p.addLine(to: g.p(28.5, 17))
            }, fill: nil, ink: ink, width: w)

            // Wheels.
            ForEach([CGFloat(12), CGFloat(28)], id: \.self) { cx in
                Stroked(path: Path(ellipseIn: CGRect(x: g.v(cx - 3.4), y: g.v(25 - 3.4),
                                                     width: g.v(6.8), height: g.v(6.8))),
                        fill: palette.secondary, ink: ink, width: w)
            }
        }
        .frame(width: size, height: size)
    }
}

// MARK: - Palette

/// Up to four fills per icon, in paint order.
struct IconPalette {
    var primary: Color
    var secondary: Color
    var tertiary: Color = .white
    var quaternary: Color = .white

    /// Small sizes drop the near-white `#F5F8F7` for pure white — that tone only
    /// exists to read as paper against a white tile, and the finalised screens
    /// have no tiles.
    static func ride(onCard: Bool = true) -> IconPalette {
        .init(primary: IRob.C.brandBright,
              secondary: onCard ? .white : Color(hex: 0xF5F8F7),
              tertiary: IRob.C.gold)
    }

    /// The live-order pill recolours the Food bowl green — it marks a delivery
    /// in progress, not the Food service.
    static let deliveryInFlight = IconPalette(primary: IRob.C.brandBright,
                                              secondary: .white,
                                              tertiary: .white,
                                              quaternary: IRob.C.brandBright)
}

// MARK: - Previews

#Preview("Service icons — size bands") {
    VStack(alignment: .leading, spacing: 28) {
        ForEach([48, 44, 28, 24, 21], id: \.self) { s in
            let size = CGFloat(s)
            VStack(alignment: .leading, spacing: 8) {
                Text("\(s)pt · stroke \(IconBand.forSize(size).stroke, specifier: "%.1f")")
                    .textRole(.monoCaption, IRob.C.inkMuted)
                HStack(spacing: 20) {
                    RideIcon(size: size)
                    FoodIcon(size: size)
                    SendIcon(size: size)
                    RewardsIcon(size: size)
                }
            }
        }
    }
    .padding(28)
    .background(IRob.C.surface)
}
