import SwiftUI
import TinyCEOCore

private enum HomePanelMode: String, CaseIterable, Identifiable {
    case office
    case summary

    var id: String { rawValue }

    var label: String {
        switch self {
        case .office:
            return "オフィス"
        case .summary:
            return "サマリー"
        }
    }
}

struct HomePopoverView: View {
    @ObservedObject var store: GameRuntimeStore
    @State private var panelMode: HomePanelMode = .office

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

                Picker("表示", selection: $panelMode) {
                    ForEach(HomePanelMode.allCases) { mode in
                        Text(mode.label).tag(mode)
                    }
                }
                .pickerStyle(.segmented)

                if panelMode == .office {
                    officeMainSection
                } else {
                    summarySection
                }

                inboxSection
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
                    .padding(6)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .foregroundStyle(TinyTokens.ColorToken.textSecondary)
        }
    }

    private var officeMainSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 6) {
                StatPill(symbol: "person.3.fill", text: "社員 \(store.snapshot?.teamSize ?? 1)名")
                StatPill(symbol: "hammer.fill", text: "案件 \(store.projectRows.count)")
                StatPill(symbol: "tray.fill", text: "Inbox \(store.viewState.inboxCount)")
                if let focusCategory = store.focusInboxCategory {
                    let spec = EventVisualCatalog.spec(for: focusCategory)
                    StatPill(
                        symbol: spec.fallbackSymbol,
                        text: spec.label
                    )
                }
            }

            AnimatedOfficeScene(
                snapshot: store.snapshot,
                focusCategory: store.focusInboxCategory,
                riskLevel: store.viewState.riskLevel
            )

            Text("会社が成長するほどオフィスがにぎやかになります")
                .font(.system(size: 11))
                .foregroundStyle(TinyTokens.ColorToken.textSecondary)
        }
        .padding(12)
        .background(TinyTokens.ColorToken.bgCell)
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(TinyTokens.ColorToken.borderDefault, lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }

    private var summarySection: some View {
        VStack(alignment: .leading, spacing: 12) {
            kpiSection
            projectSection
            if store.showOfficeDecorations {
                OfficeDecorationRow(snapshot: store.snapshot)
            }
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

private struct StatPill: View {
    let symbol: String
    let text: String

    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: symbol)
                .font(.system(size: 10))
            Text(text)
                .font(.system(size: 10, weight: .medium))
                .lineLimit(1)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .foregroundStyle(TinyTokens.ColorToken.textPrimary)
        .background(TinyTokens.ColorToken.bgPopover.opacity(0.6))
        .clipShape(Capsule())
    }
}

private struct AnimatedOfficeScene: View {
    let snapshot: GameState?
    let focusCategory: String?
    let riskLevel: RiskLevel

    private let seatAnchors: [CGPoint] = [
        CGPoint(x: 0.16, y: 0.30),
        CGPoint(x: 0.45, y: 0.28),
        CGPoint(x: 0.75, y: 0.32),
        CGPoint(x: 0.24, y: 0.72),
        CGPoint(x: 0.56, y: 0.68),
        CGPoint(x: 0.83, y: 0.72)
    ]

    var body: some View {
        TimelineView(.animation(minimumInterval: 1.0 / 12.0)) { timeline in
            GeometryReader { proxy in
                let size = proxy.size
                let employees = employeeKinds
                let time = timeline.date.timeIntervalSinceReferenceDate

                ZStack(alignment: .topLeading) {
                    RoundedRectangle(cornerRadius: 8)
                        .fill(TinyTokens.ColorToken.bgPopover.opacity(0.55))

                    OfficeGridPattern()
                        .stroke(TinyTokens.ColorToken.borderDefault.opacity(0.25), lineWidth: 0.5)
                        .clipShape(RoundedRectangle(cornerRadius: 8))

                    ForEach(Array(seatAnchors.enumerated()), id: \.offset) { index, anchor in
                        deskSprite(at: point(anchor: anchor, in: size))
                            .opacity(index < max(employees.count, 2) ? 1 : 0.4)
                    }

                    if showPlant {
                        sprite(name: "office_plant_01", width: 24, height: 32)
                            .position(x: size.width * 0.08, y: size.height * 0.76)
                    }

                    if showDesk2 {
                        sprite(name: "office_desk_02", width: 30, height: 30)
                            .position(x: size.width * 0.72, y: size.height * 0.74)
                    }

                    if showServer {
                        sprite(name: "office_server_01", width: 24, height: 40)
                            .position(x: size.width * 0.92, y: size.height * 0.68)
                    }

                    ForEach(Array(employees.enumerated()), id: \.offset) { index, employee in
                        let base = point(anchor: seatAnchors[index % seatAnchors.count], in: size)
                        let motion = motionProfile(for: employee, focusedCategory: focusCategory)
                        let speedMultiplier = speedMultiplier(for: motion)
                        let amplitude = amplitude(for: motion)
                        let animatedPoint = CGPoint(
                            x: base.x + CGFloat(sin(time * 1.2 * speedMultiplier + Double(index))) * amplitude,
                            y: base.y + CGFloat(cos(time * 1.5 * speedMultiplier + Double(index) * 0.7)) * (amplitude * 0.5) - 10
                        )
                        employeeSprite(kind: employee)
                            .position(animatedPoint)
                    }

                    if let focusCategory {
                        EventBeacon(category: focusCategory, riskLevel: riskLevel, time: time)
                            .position(x: size.width - 18, y: 18)
                    }
                }
            }
            .frame(height: 150)
        }
    }

    private var employeeKinds: [EmployeeKind] {
        let total = max(1, min(snapshot?.teamSize ?? 1, seatAnchors.count))
        return (0..<total).map { index in
            if index == 0 {
                return .founder
            }
            return index % 2 == 0 ? .pm : .dev
        }
    }

    private func point(anchor: CGPoint, in size: CGSize) -> CGPoint {
        CGPoint(x: size.width * anchor.x, y: size.height * anchor.y)
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
    private func deskSprite(at point: CGPoint) -> some View {
        if let desk = TinyAsset.officeSprite(named: "office_desk_01") {
            desk
                .resizable()
                .interpolation(.none)
                .frame(width: 30, height: 30)
                .position(point)
        }
        if let monitor = TinyAsset.officeSprite(named: "office_monitor_01") {
            monitor
                .resizable()
                .interpolation(.none)
                .frame(width: 22, height: 22)
                .position(CGPoint(x: point.x + 10, y: point.y - 10))
        }
    }

    @ViewBuilder
    private func sprite(name: String, width: CGFloat, height: CGFloat) -> some View {
        if let image = TinyAsset.officeSprite(named: name) {
            image
                .resizable()
                .interpolation(.none)
                .frame(width: width, height: height)
        }
    }

    @ViewBuilder
    private func employeeSprite(kind: EmployeeKind) -> some View {
        let assetName = characterAssetName(for: kind)

        if let image = TinyAsset.characterSprite(named: assetName) {
            image
                .resizable()
                .interpolation(.none)
                .frame(width: 20, height: 28)
                .shadow(color: .black.opacity(0.2), radius: 1, x: 0, y: 1)
        } else {
            Image(systemName: "person.fill")
                .font(.system(size: 14))
                .foregroundStyle(TinyTokens.ColorToken.textPrimary)
                .frame(width: 20, height: 28)
        }
    }

    private func motionProfile(for employee: EmployeeKind, focusedCategory: String?) -> OfficeMotionProfile {
        if riskLevel == .danger {
            return .urgent
        }
        if let focusedCategory {
            let focusMotion = EventVisualCatalog.spec(for: focusedCategory).motion
            if focusMotion == .urgent || focusMotion == .busy {
                return focusMotion
            }
        }
        if employee == .founder {
            return .steady
        }
        return .calm
    }

    private func speedMultiplier(for profile: OfficeMotionProfile) -> Double {
        switch profile {
        case .calm:
            return 0.85
        case .steady:
            return 1.0
        case .busy:
            return 1.2
        case .urgent:
            return 1.45
        }
    }

    private func amplitude(for profile: OfficeMotionProfile) -> CGFloat {
        switch profile {
        case .calm:
            return 2.0
        case .steady:
            return 3.0
        case .busy:
            return 4.2
        case .urgent:
            return 5.2
        }
    }

    private func characterAssetName(for kind: EmployeeKind) -> String {
        switch kind {
        case .founder:
            return "char_founder_01"
        case .dev:
            return "char_staff_dev_01"
        case .pm:
            return "char_staff_pm_01"
        }
    }

    private enum EmployeeKind: Equatable {
        case founder
        case dev
        case pm
    }
}

private struct EventBeacon: View {
    let category: String
    let riskLevel: RiskLevel
    let time: TimeInterval

    var body: some View {
        let spec = EventVisualCatalog.spec(for: category)
        let bob = CGFloat(sin(time * 2.0)) * 2

        return ZStack {
            Circle()
                .fill(TinyTokens.ColorToken.bgPopover.opacity(0.92))
                .frame(width: 24, height: 24)
            TinyAsset.icon(assetName: spec.iconAssetName, sfSymbol: spec.fallbackSymbol)
                .font(.system(size: 11, weight: .semibold))
                .foregroundStyle(TinyTokens.ColorToken.categoryBadge(category))
                .offset(y: bob * 0.2)
        }
        .overlay(
            Circle()
                .stroke(borderColor, lineWidth: 1)
        )
        .shadow(color: .black.opacity(0.12), radius: 2, x: 0, y: 1)
        .offset(y: bob)
    }

    private var borderColor: Color {
        if riskLevel == .danger {
            return TinyTokens.ColorToken.borderDanger
        }
        return TinyTokens.ColorToken.borderDefault
    }
}

private struct OfficeGridPattern: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let spacing: CGFloat = 14

        var x: CGFloat = 0
        while x <= rect.width {
            path.move(to: CGPoint(x: x, y: 0))
            path.addLine(to: CGPoint(x: x, y: rect.height))
            x += spacing
        }

        var y: CGFloat = 0
        while y <= rect.height {
            path.move(to: CGPoint(x: 0, y: y))
            path.addLine(to: CGPoint(x: rect.width, y: y))
            y += spacing
        }

        return path
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
