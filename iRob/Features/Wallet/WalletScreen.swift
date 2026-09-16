import SwiftUI

// Wallet.
//
// The one screen where the brand green steps aside. Violet #5341B0 owns the
// balance card because, as the icon notes put it, this is where "colour needs
// to mean money rather than decoration" — green everywhere else would make the
// balance read as just another service.

struct WalletScreen: View {
    @Environment(AppState.self) private var app

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                balanceCard
                statTiles
                recent

                Color.clear.frame(height: 76)
            }
        }
        .scrollIndicators(.hidden)
        .background(IRob.C.surface)
        .safeAreaInset(edge: .top, spacing: 0) {
            GlassHeader(content: .title("Wallet"),
                        onAvatar: { app.showingProfile = true })
        }
    }

    // MARK: Balance

    private var balanceCard: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text(Mock.walletLabel).textRole(.eyebrow, IRob.C.violetOnDark)
            Text(Mock.walletBalance)
                .textRole(.balance, .white)
                .padding(.top, 6)

            HStack(spacing: 10) {
                // Top up is the primary action and the only solid white fill;
                // Send and Scan sit back in translucent wells. One primary
                // action per view.
                WalletAction(title: "Top up", prominent: true)
                WalletAction(title: "Send")
                WalletAction(title: "Scan")
            }
            .padding(.top, 20)
        }
        .padding(22)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(IRob.C.violet,
                    in: RoundedRectangle(cornerRadius: IRob.R.pillCard, style: .continuous))
        .irobShadow(.violetGlow)
        .padding(.horizontal, IRob.S.gutter)
        .padding(.top, 16)
    }

    // MARK: Stats

    private var statTiles: some View {
        HStack(spacing: 12) {
            StatTile(value: Mock.rewardPoints, label: "Rewards") {
                RewardsIcon(size: 32)
            }
            StatTile(value: Mock.voucherCount, label: "Expiring soon") {
                ZStack {
                    RoundedRectangle(cornerRadius: 9, style: .continuous)
                        .fill(IRob.C.brandTint)
                    RoundedRectangle(cornerRadius: 4, style: .continuous)
                        .strokeBorder(IRob.C.brandDeep, lineWidth: 2)
                        .frame(width: 16, height: 16)
                }
                .frame(width: 32, height: 32)
            }
        }
        .padding(.horizontal, IRob.S.gutter)
        .padding(.top, 16)
    }

    // MARK: Recent

    private var recent: some View {
        VStack(spacing: 12) {
            SectionHeader(title: "Recent", action: "All", small: true)
            ListCard {
                ForEach(Array(Mock.transactions.enumerated()), id: \.element.id) { i, tx in
                    if i > 0 { RowDivider(inset: 57) }
                    TransactionRow(tx: tx)
                }
            }
        }
        .padding(.horizontal, IRob.S.gutter)
        .padding(.top, 26)
    }
}

// MARK: - Pieces

private struct WalletAction: View {
    let title: String
    var prominent: Bool = false

    var body: some View {
        Button {} label: {
            Text(title)
                .textRole(.label, prominent ? IRob.C.violet : .white)
                .frame(maxWidth: .infinity)
                .frame(height: 44)
                .background(
                    prominent ? AnyShapeStyle(Color.white)
                              : AnyShapeStyle(Color.white.opacity(0.18)),
                    in: RoundedRectangle(cornerRadius: IRob.R.button, style: .continuous)
                )
                .overlay {
                    if !prominent {
                        RoundedRectangle(cornerRadius: IRob.R.button, style: .continuous)
                            .strokeBorder(.white.opacity(0.4), lineWidth: 1)
                    }
                }
        }
        .buttonStyle(PressableCard())
    }
}

private struct StatTile<Icon: View>: View {
    let value: String
    let label: String
    @ViewBuilder var icon: Icon

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            icon
            Text(value).textRole(.cardTitle).padding(.top, 12)
            Text(label).textRole(.caption, IRob.C.inkMuted).padding(.top, 1)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .hairlineCard(radius: IRob.R.cardTight)
    }
}

private struct TransactionRow: View {
    let tx: Transaction

    var body: some View {
        HStack(spacing: 13) {
            icon.frame(width: 28, height: 28)

            VStack(alignment: .leading, spacing: 1) {
                Text(tx.title).textRole(.rowTitleSm)
                Text(tx.date).textRole(.caption, IRob.C.inkMuted)
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            // Credits are the only amounts that take colour — money arriving is
            // the exception worth marking, money leaving is the norm.
            Text(tx.amount)
                .textRole(.rowTitle, tx.isCredit ? IRob.C.brandDeep : IRob.C.ink)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
    }

    @ViewBuilder
    private var icon: some View {
        switch tx.icon {
        case .ride: RideIcon(size: 28)
        case .food: FoodIcon(size: 28)
        case .send: SendIcon(size: 28)
        case .topUp:
            ZStack {
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .fill(IRob.C.violetTint)
                Image(systemName: "plus")
                    .font(.system(size: 13, weight: .bold))
                    .foregroundStyle(IRob.C.violet)
            }
        }
    }
}
