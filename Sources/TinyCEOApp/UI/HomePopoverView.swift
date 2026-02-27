import SwiftUI
import TinyCEOCore

struct HomePopoverView: View {
    @ObservedObject var store: GameRuntimeStore

    private static let jpyFormatter: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = "JPY"
        formatter.locale = Locale(identifier: "ja_JP")
        formatter.maximumFractionDigits = 0
        return formatter
    }()

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 12) {
                header
                if let crisis = store.crisisBannerText {
                    CrisisBanner(text: crisis)
                }
                kpiSection
                projectSection
                inboxSection
                if store.showOfficeDecorations {
                    OfficeDecorationRow(snapshot: store.snapshot)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
        }
        .scrollIndicators(.never)
        .background(TinyTokens.ColorToken.bgPopover)
    }

    private var header: some View {
        HStack(spacing: 8) {
            Image(systemName: "building.2.fill")
                .font(.system(size: 14))
            Text("TinyCEO")
                .font(.system(size: 15, weight: .medium))
                .foregroundStyle(TinyTokens.ColorToken.textPrimary)
            Spacer()
            Text("Day \(store.viewState.day)")
                .font(.system(size: 12))
                .foregroundStyle(TinyTokens.ColorToken.textSecondary)
            RiskBadge(level: store.viewState.riskLevel)
            Button {
                store.openSettings()
            } label: {
                Image(systemName: "gearshape")
                    .font(.system(size: 15))
            }
            .buttonStyle(.plain)
            .foregroundStyle(TinyTokens.ColorToken.textSecondary)
        }
    }

    private var kpiSection: some View {
        VStack(spacing: 8) {
            HStack(spacing: 8) {
                ForEach(Array(kpiModels.prefix(3))) { model in
                    KPICellView(model: model)
                }
            }
            HStack(spacing: 8) {
                ForEach(Array(kpiModels.suffix(2))) { model in
                    KPICellView(model: model)
                }
            }
        }
    }

    private var projectSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("プロジェクト")
                .font(.system(size: 11, weight: .semibold))
                .foregroundStyle(TinyTokens.ColorToken.textSecondary)

            if store.projectRows.isEmpty {
                Text("進行中のプロジェクトはありません")
                    .font(.system(size: 12))
                    .foregroundStyle(TinyTokens.ColorToken.textSecondary)
            } else {
                ForEach(store.projectRows) { row in
                    VStack(alignment: .leading, spacing: 6) {
                        Text(row.title)
                            .font(.system(size: 12, weight: .medium))
                            .lineLimit(1)
                            .foregroundStyle(TinyTokens.ColorToken.textPrimary)
                        ProgressView(value: row.progress)
                            .tint(TinyTokens.ColorToken.statusHealthy)
                        Text("\(Int(row.progress * 100))%")
                            .font(.system(size: 11))
                            .foregroundStyle(TinyTokens.ColorToken.textSecondary)
                    }
                }
            }
        }
        .padding(12)
        .background(TinyTokens.ColorToken.bgCell)
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(TinyTokens.ColorToken.borderDefault, lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }

    private var inboxSection: some View {
        HStack(spacing: 8) {
            Image(systemName: store.viewState.showInboxFullBanner ? "tray.full.fill" : "tray.fill")
                .font(.system(size: 14))
            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 4) {
                    Text("Inbox \(store.viewState.inboxCount)件")
                        .font(.system(size: 13, weight: .medium))
                    if store.viewState.showInboxFullBanner {
                        Text("FULL")
                            .font(.system(size: 10, weight: .semibold))
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .foregroundStyle(.white)
                            .background(TinyTokens.ColorToken.statusDanger)
                            .clipShape(Capsule())
                    }
                }
                Text("次のカードまで: 約\(store.viewState.minutesUntilNextCard)分")
                    .font(.system(size: 11))
                    .monospacedDigit()
                    .foregroundStyle(TinyTokens.ColorToken.textSecondary)
            }
            Spacer()
            Button("カードを見る") {
                store.openInbox()
            }
            .buttonStyle(.borderedProminent)
            .font(.system(size: 12, weight: .medium))
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .background(TinyTokens.ColorToken.bgCell)
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(TinyTokens.ColorToken.borderDefault, lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }

    private var kpiModels: [KPIModel] {
        let state = store.viewState
        return [
            KPIModel(
                id: "cash",
                label: "CASH",
                valueText: formatJPY(state.cashJPY),
                assetName: "ui_cash_icon",
                fallbackSymbol: "yensign.circle",
                accentColor: TinyTokens.ColorToken.kpiCash,
                riskLevel: state.runway.riskLevel
            ),
            KPIModel(
                id: "runway",
                label: "RUNWAY",
                valueText: state.runway.displayText,
                assetName: nil,
                fallbackSymbol: "calendar.badge.clock",
                accentColor: TinyTokens.ColorToken.kpiRunway,
                riskLevel: state.runway.riskLevel
            ),
            KPIModel(
                id: "reputation",
                label: "REP",
                valueText: "\(Int(state.reputation.rounded()))",
                assetName: "ui_reputation_icon",
                fallbackSymbol: "star.fill",
                accentColor: TinyTokens.ColorToken.kpiReputation,
                riskLevel: reputationRisk(reputation: state.reputation)
            ),
            KPIModel(
                id: "health",
                label: "HEALTH",
                valueText: "\(Int(state.teamHealth.rounded()))",
                assetName: "ui_health_icon",
                fallbackSymbol: "heart.fill",
                accentColor: TinyTokens.ColorToken.kpiHealth,
                riskLevel: healthRisk(health: state.teamHealth)
            ),
            KPIModel(
                id: "techDebt",
                label: "DEBT",
                valueText: "\(Int(state.techDebt.rounded()))",
                assetName: "ui_techdebt_icon",
                fallbackSymbol: "bolt.fill",
                accentColor: TinyTokens.ColorToken.kpiTechDebt,
                riskLevel: techDebtRisk(techDebt: state.techDebt)
            )
        ]
    }

    private func formatJPY(_ value: Int) -> String {
        Self.jpyFormatter.string(from: NSNumber(value: value)) ?? "¥\(value)"
    }

    private func reputationRisk(reputation: Double) -> RiskLevel {
        if reputation < 5 {
            return .danger
        }
        if reputation < 15 {
            return .warn
        }
        return .normal
    }

    private func healthRisk(health: Double) -> RiskLevel {
        if health < 30 {
            return .danger
        }
        if health < 50 {
            return .warn
        }
        return .normal
    }

    private func techDebtRisk(techDebt: Double) -> RiskLevel {
        if techDebt > 75 {
            return .danger
        }
        if techDebt > 50 {
            return .warn
        }
        return .normal
    }
}

private struct KPIModel: Identifiable {
    let id: String
    let label: String
    let valueText: String
    let assetName: String?
    let fallbackSymbol: String
    let accentColor: Color
    let riskLevel: RiskLevel
}

private struct KPICellView: View {
    let model: KPIModel

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack(spacing: 4) {
                TinyAsset.icon(assetName: model.assetName, sfSymbol: model.fallbackSymbol)
                    .font(.system(size: 14))
                    .foregroundStyle(model.accentColor)
                Text(model.label)
                    .font(.system(size: 10, weight: .regular))
                    .foregroundStyle(TinyTokens.ColorToken.textSecondary)
            }
            Text(model.valueText)
                .font(.system(size: 17, weight: .semibold, design: .rounded))
                .monospacedDigit()
                .foregroundStyle(model.accentColor)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
        }
        .frame(maxWidth: .infinity, minHeight: TinyTokens.Size.kpiCellHeight, alignment: .leading)
        .padding(.horizontal, 8)
        .padding(.vertical, 10)
        .background(backgroundColor(for: model.riskLevel))
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(borderColor(for: model.riskLevel), lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }

    private func backgroundColor(for level: RiskLevel) -> Color {
        switch level {
        case .normal:
            return TinyTokens.ColorToken.bgCell
        case .warn:
            return TinyTokens.ColorToken.bgWarning
        case .danger:
            return TinyTokens.ColorToken.bgDanger
        }
    }

    private func borderColor(for level: RiskLevel) -> Color {
        switch level {
        case .normal:
            return TinyTokens.ColorToken.borderDefault
        case .warn:
            return TinyTokens.ColorToken.borderWarning
        case .danger:
            return TinyTokens.ColorToken.borderDanger
        }
    }
}

private struct RiskBadge: View {
    let level: RiskLevel

    var body: some View {
        Text(label)
            .font(.system(size: 11, weight: .semibold))
            .foregroundStyle(.white)
            .padding(.horizontal, 8)
            .padding(.vertical, 2)
            .background(color)
            .clipShape(Capsule())
    }

    private var label: String {
        switch level {
        case .normal:
            return "NORMAL"
        case .warn:
            return "WARN"
        case .danger:
            return "DANGER"
        }
    }

    private var color: Color {
        switch level {
        case .normal:
            return TinyTokens.ColorToken.statusHealthy
        case .warn:
            return TinyTokens.ColorToken.statusWarning
        case .danger:
            return TinyTokens.ColorToken.statusDanger
        }
    }
}

private struct CrisisBanner: View {
    let text: String

    var body: some View {
        HStack(alignment: .top, spacing: 6) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 13))
            Text(text)
                .font(.system(size: 13))
                .lineLimit(2)
        }
        .foregroundStyle(TinyTokens.ColorToken.statusDanger)
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(TinyTokens.ColorToken.bgDanger)
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(TinyTokens.ColorToken.borderDanger, lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }
}

private struct OfficeDecorationRow: View {
    let snapshot: GameState?

    var body: some View {
        HStack(alignment: .bottom, spacing: 8) {
            sprite("office_desk_01", width: 32, height: 32)
            sprite("office_monitor_01", width: 32, height: 32)
            if showPlant {
                sprite("office_plant_01", width: 24, height: 32)
            }

            Spacer(minLength: 0)

            if showDesk2 {
                sprite("office_desk_02", width: 32, height: 32)
            }
            if showServer {
                sprite("office_server_01", width: 24, height: 40)
            }
        }
        .frame(maxWidth: .infinity)
        .frame(height: TinyTokens.Size.officeRowHeight)
        .padding(.horizontal, 12)
        .padding(.vertical, 4)
        .background(TinyTokens.ColorToken.bgCell)
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(TinyTokens.ColorToken.borderDefault, lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }

    private var chapter2Unlocked: Bool {
        (snapshot?.chapterIndex ?? 0) >= 1
    }

    private var showPlant: Bool {
        guard let snapshot else { return false }
        return snapshot.day >= 10 || snapshot.hasProductLaunched
    }

    private var showDesk2: Bool {
        guard let snapshot else { return false }
        return snapshot.teamSize >= 2 || chapter2Unlocked
    }

    private var showServer: Bool {
        guard let snapshot else { return false }
        return chapter2Unlocked || snapshot.metrics.aiXP > 0
    }

    @ViewBuilder
    private func sprite(_ name: String, width: CGFloat, height: CGFloat) -> some View {
        if let image = TinyAsset.officeSprite(named: name) {
            image
                .resizable()
                .interpolation(.none)
                .frame(width: width, height: height)
        }
    }
}
