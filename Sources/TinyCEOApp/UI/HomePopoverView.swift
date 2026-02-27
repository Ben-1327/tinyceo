import SwiftUI
import TinyCEOCore

// MARK: - Home Popover Root

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
        let f = NumberFormatter()
        f.numberStyle   = .currency
        f.currencyCode  = "JPY"
        f.locale        = Locale(identifier: "ja_JP")
        f.maximumFractionDigits = 0
        return f
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
                    officeDashboardSection
                } else {
                    summaryDashboardSection
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
        }
        .scrollIndicators(.never)
        .background(TinyTokens.ColorToken.bgPopover)
    }

    private var officeSceneState: OfficeSceneState {
        OfficeSceneState.from(
            snapshot: store.snapshot,
            viewState: store.viewState,
            focusCategory: store.focusInboxCategory
        )
    }

    // MARK: Office section

    private var officeSectionView: some View {
        AnimatedOfficeScene(
            sceneState: officeSceneState,
            inboxCount: store.viewState.inboxCount
        )
    }

    private var officeDashboardSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            officeStatsRow
            officeSectionView
            Text("オフィスが成長し、社員が増えるほどシーンがにぎやかになります")
                .font(.system(size: 11))
                .foregroundStyle(TinyTokens.ColorToken.textSecondary)
            inboxSection
        }
    }

    private var summaryDashboardSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            kpiSection
            projectSection
            if store.showOfficeDecorations {
                OfficeDecorationRow(sceneState: officeSceneState)
            }
            inboxSection
        }
    }

    private var officeStatsRow: some View {
        HStack(spacing: 6) {
            OfficeStatPill(symbol: "person.2.fill", text: "社員 \(officeSceneState.totalEmployeeCount)名")
            OfficeStatPill(symbol: "hammer.fill", text: "案件 \(store.projectRows.count)")
            OfficeStatPill(symbol: "tray.fill", text: "Inbox \(store.viewState.inboxCount)")
            if let focusCategory = officeSceneState.focusCategory {
                let spec = EventVisualCatalog.spec(for: focusCategory)
                OfficeStatPill(symbol: spec.fallbackSymbol, text: spec.label)
            }
        }
    }

    // MARK: Header

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

    // MARK: KPI grid (always visible)

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

    // MARK: Projects

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

    // MARK: Inbox CTA

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

    // MARK: KPI models

    private var kpiModels: [KPIModel] {
        let s = store.viewState
        return [
            KPIModel(
                id: "cash",
                label: "CASH",
                valueText: formatJPY(s.cashJPY),
                assetName: "ui_cash_icon",
                fallbackSymbol: "yensign.circle",
                accentColor: TinyTokens.ColorToken.kpiCash,
                riskLevel: s.runway.riskLevel
            ),
            KPIModel(
                id: "runway",
                label: "RUNWAY",
                valueText: s.runway.displayText,
                assetName: nil,
                fallbackSymbol: "calendar.badge.clock",
                accentColor: TinyTokens.ColorToken.kpiRunway,
                riskLevel: s.runway.riskLevel
            ),
            KPIModel(
                id: "reputation",
                label: "REP",
                valueText: "\(Int(s.reputation.rounded()))",
                assetName: "ui_reputation_icon",
                fallbackSymbol: "star.fill",
                accentColor: TinyTokens.ColorToken.kpiReputation,
                riskLevel: reputationRisk(s.reputation)
            ),
            KPIModel(
                id: "health",
                label: "HEALTH",
                valueText: "\(Int(s.teamHealth.rounded()))",
                assetName: "ui_health_icon",
                fallbackSymbol: "heart.fill",
                accentColor: TinyTokens.ColorToken.kpiHealth,
                riskLevel: healthRisk(s.teamHealth)
            ),
            KPIModel(
                id: "techDebt",
                label: "DEBT",
                valueText: "\(Int(s.techDebt.rounded()))",
                assetName: "ui_techdebt_icon",
                fallbackSymbol: "bolt.fill",
                accentColor: TinyTokens.ColorToken.kpiTechDebt,
                riskLevel: techDebtRisk(s.techDebt)
            )
        ]
    }

    private func formatJPY(_ value: Int) -> String {
        Self.jpyFormatter.string(from: NSNumber(value: value)) ?? "¥\(value)"
    }

    private func reputationRisk(_ reputation: Double) -> RiskLevel {
        reputation < 5  ? .danger : reputation < 15 ? .warn : .normal
    }

    private func healthRisk(_ health: Double) -> RiskLevel {
        health < 30 ? .danger : health < 50 ? .warn : .normal
    }

    private func techDebtRisk(_ techDebt: Double) -> RiskLevel {
        techDebt > 75 ? .danger : techDebt > 50 ? .warn : .normal
    }
}

private struct OfficeStatPill: View {
    let symbol: String
    let text: String

    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: symbol)
                .font(.system(size: 10))
            Text(text)
                .font(.system(size: 10, weight: .semibold))
                .lineLimit(1)
        }
        .foregroundStyle(TinyTokens.ColorToken.textPrimary)
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(TinyTokens.ColorToken.bgCell)
        .overlay(
            Capsule()
                .stroke(TinyTokens.ColorToken.borderDefault, lineWidth: 1)
        )
        .clipShape(Capsule())
    }
}

// MARK: - Animated Office Scene

private struct AnimatedOfficeScene: View {
    let sceneState: OfficeSceneState
    let inboxCount: Int

    /// 6 desk anchors (normalised 0…1) arranged in perspective-friendly rows.
    private let deskAnchors: [CGPoint] = [
        CGPoint(x: 0.17, y: 0.55),
        CGPoint(x: 0.50, y: 0.53),
        CGPoint(x: 0.82, y: 0.55),
        CGPoint(x: 0.24, y: 0.76),
        CGPoint(x: 0.52, y: 0.74),
        CGPoint(x: 0.79, y: 0.76)
    ]

    var body: some View {
        TimelineView(.animation(minimumInterval: 1.0 / 10.0)) { timeline in
            GeometryReader { proxy in
                let size = proxy.size
                let time = timeline.date.timeIntervalSinceReferenceDate

                ZStack(alignment: .topLeading) {
                    // Layer 1: Room background (wall/windows)
                    backgroundLayer(size: size, time: time)

                    // Layer 2: Floor texture + perspective grid
                    floorLayer(size: size, time: time)

                    // Layer 3: Furniture & room props
                    furnitureLayer(size: size)
                    wallDecorLayer(size: size)

                    // Layer 4: Animated employees and aisle movement
                    employeesLayer(size: size, time: time)
                    roamingEmployeeLayer(size: size, time: time)

                    // Layer 5: Risk atmosphere wash (danger pulses)
                    atmosphereLayer(time: time)
                        .clipShape(RoundedRectangle(cornerRadius: 10))

                    // Layer 6: Event beacon (top-right, only when a category is active)
                    if let cat = sceneState.focusCategory {
                        EventBeacon(category: cat, riskLevel: sceneState.riskLevel, time: time)
                            .position(x: size.width - 28, y: 28)
                    }

                    // Layer 7: Info strip pinned to the bottom of the scene
                    VStack(spacing: 0) {
                        Spacer()
                        OfficeInfoStrip(sceneState: sceneState, inboxCount: inboxCount)
                    }
                }
                .clipShape(RoundedRectangle(cornerRadius: 10))
                .overlay(
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(sceneBorderColor, lineWidth: 1)
                )
            }
            .frame(height: 220)
        }
    }

    // MARK: Layers

    @ViewBuilder
    private func backgroundLayer(size: CGSize, time: TimeInterval) -> some View {
        RoundedRectangle(cornerRadius: 10)
            .fill(
                LinearGradient(
                    colors: [
                        TinyTokens.ColorToken.bgPopover.opacity(0.96),
                        TinyTokens.ColorToken.bgCell.opacity(0.92)
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
            )

        // Wall split to create room depth.
        Rectangle()
            .fill(
                LinearGradient(
                    colors: [
                        TinyTokens.ColorToken.borderDefault.opacity(0.22),
                        .clear
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
            )
            .frame(height: size.height * 0.52)

        // Window strips for a "lively office" feeling.
        HStack(spacing: 10) {
            windowPane(width: size.width * 0.24, height: size.height * 0.26, time: time, phase: 0.0)
            windowPane(width: size.width * 0.24, height: size.height * 0.26, time: time, phase: 0.8)
            windowPane(width: size.width * 0.24, height: size.height * 0.26, time: time, phase: 1.6)
        }
        .frame(maxWidth: .infinity)
        .padding(.top, 14)
    }

    @ViewBuilder
    private func floorLayer(size: CGSize, time: TimeInterval) -> some View {
        Rectangle()
            .fill(
                LinearGradient(
                    colors: [
                        TinyTokens.ColorToken.bgCell.opacity(0.20),
                        TinyTokens.ColorToken.bgCell.opacity(0.88)
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
            )
            .frame(height: size.height * 0.56)
            .position(x: size.width / 2, y: size.height * 0.74)

        if let texture = TinyAsset.choiceTexture() {
            texture
                .resizable(resizingMode: .tile)
                .interpolation(.none)
                .opacity(0.08)
                .frame(width: size.width, height: size.height * 0.56)
                .position(x: size.width / 2, y: size.height * 0.74)
        }

        OfficeGridPattern()
            .stroke(TinyTokens.ColorToken.borderDefault.opacity(0.14), lineWidth: 0.5)
            .scaleEffect(x: 1.0, y: 0.82, anchor: .bottom)
            .offset(y: size.height * 0.09)
    }

    private func atmosphereLayer(time: TimeInterval) -> some View {
        let pulse: Double = sceneState.riskLevel == .danger
            ? 0.7 + 0.3 * abs(sin(time * 1.5))
            : 1.0
        return LinearGradient(
            colors: [
                sceneState.atmosphereColor.opacity(sceneState.atmosphereOpacity * pulse),
                .clear
            ],
            startPoint: .bottom,
            endPoint: .top
        )
    }

    @ViewBuilder
    private func furnitureLayer(size: CGSize) -> some View {
        // Desks — dimmed beyond the active seat count to hint at future growth.
        ForEach(Array(deskAnchors.enumerated()), id: \.offset) { index, anchor in
            let pos = point(anchor: anchor, in: size)
            let active = index < sceneState.activeEmployeeCount
            deskSprite(index: index, at: pos)
            .opacity(active ? 1.0 : 0.22)
        }

        // Stage-aware decorative furniture.
        if sceneState.showPlant {
            sprite(name: "office_plant_01", width: 30, height: 36)
                .position(x: size.width * 0.08, y: size.height * 0.76)
            sprite(name: "office_plant_01", width: 24, height: 30)
                .position(x: size.width * 0.92, y: size.height * 0.49)
        }
        if sceneState.showDesk2 {
            sprite(name: "office_desk_02", width: 38, height: 34)
                .position(x: size.width * 0.90, y: size.height * 0.72)
        }
        if sceneState.showServer {
            sprite(name: "office_server_01", width: 28, height: 44)
                .position(x: size.width * 0.06, y: size.height * 0.64)
        }
    }

    @ViewBuilder
    private func wallDecorLayer(size: CGSize) -> some View {
        let icons: [(String, String)] = [
            ("cat_strategy_icon", "target"),
            ("cat_product_icon", "shippingbox.fill"),
            ("cat_sales_icon", "chart.line.uptrend.xyaxis"),
            ("cat_ai_icon", "sparkles")
        ]
        HStack(spacing: 12) {
            ForEach(Array(icons.enumerated()), id: \.offset) { _, item in
                RoundedRectangle(cornerRadius: 5)
                    .fill(.black.opacity(0.16))
                    .frame(width: 28, height: 28)
                    .overlay {
                        TinyAsset.icon(assetName: item.0, sfSymbol: item.1)
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundStyle(.white.opacity(0.82))
                    }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.leading, 10)
        .padding(.top, 12)
    }

    @ViewBuilder
    private func employeesLayer(size: CGSize, time: TimeInterval) -> some View {
        let profile = sceneState.motionProfile
        let speed   = speedMultiplier(for: profile)
        let amp     = amplitude(for: profile)
        let showDots = profile == .busy || profile == .urgent

        ForEach(0..<sceneState.activeEmployeeCount, id: \.self) { index in
            let kind: EmployeeKind = index == 0 ? .founder : (index % 2 == 0 ? .pm : .dev)
            let desk = point(anchor: deskAnchors[index % deskAnchors.count], in: size)
            let base = CGPoint(x: desk.x, y: desk.y - 20)
            let dx = CGFloat(sin(time * 1.0 * speed + Double(index) * 0.7)) * amp
            let dy = CGFloat(cos(time * 1.4 * speed + Double(index) * 0.5)) * (amp * 0.4)
            let animPos = CGPoint(x: base.x + dx, y: base.y + dy)

            employeeSprite(kind: kind)
                .overlay(alignment: .top) {
                    if showDots {
                        activityDots(time: time, employeeIndex: index)
                            .offset(y: -12)
                    }
                }
                .position(animPos)
        }
    }

    @ViewBuilder
    private func roamingEmployeeLayer(size: CGSize, time: TimeInterval) -> some View {
        if sceneState.activeEmployeeCount >= 3 {
            let profile = sceneState.motionProfile
            let speed = speedMultiplier(for: profile)
            let progress = 0.5 + 0.5 * sin(time * 0.36 * speed)
            let x = size.width * (0.13 + progress * 0.74)
            let y = size.height * (0.66 + 0.02 * sin(time * 1.6))
            let facingRight = cos(time * 0.36 * speed) >= 0

            employeeSprite(kind: .dev)
                .scaleEffect(x: facingRight ? 1 : -1, y: 1, anchor: .center)
                .opacity(0.62)
                .position(x: x, y: y)
        }
    }

    // MARK: Sprite helpers

    private func activityDots(time: TimeInterval, employeeIndex: Int) -> some View {
        HStack(spacing: 3) {
            dotDot(time: time, dotIdx: 0, employeeIndex: employeeIndex)
            dotDot(time: time, dotIdx: 1, employeeIndex: employeeIndex)
            dotDot(time: time, dotIdx: 2, employeeIndex: employeeIndex)
        }
    }

    private func dotDot(time: TimeInterval, dotIdx: Int, employeeIndex: Int) -> some View {
        let phase = time * 5.5 + Double(dotIdx) * 0.9 + Double(employeeIndex) * 0.4
        let dy = -abs(CGFloat(sin(phase))) * 2.5
        return Circle()
            .fill(Color.white.opacity(0.80))
            .frame(width: 3, height: 3)
            .offset(y: dy)
    }

    @ViewBuilder
    private func deskSprite(index: Int, at p: CGPoint) -> some View {
        let deskAsset = index % 2 == 0 ? "office_desk_01" : "office_desk_02"

        Ellipse()
            .fill(.black.opacity(0.18))
            .frame(width: 44, height: 12)
            .position(x: p.x, y: p.y + 12)

        if let desk = TinyAsset.officeSprite(named: deskAsset) {
            desk
                .resizable()
                .interpolation(.none)
                .frame(width: 38, height: 32)
                .position(p)
        }
        if let monitor = TinyAsset.officeSprite(named: "office_monitor_01") {
            monitor
                .resizable()
                .interpolation(.none)
                .frame(width: 18, height: 16)
                .position(CGPoint(x: p.x + 3, y: p.y - 7))
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
                .frame(width: 22, height: 28)
                .shadow(color: .black.opacity(0.2), radius: 1, x: 0, y: 1)
        } else {
            Image(systemName: "person.fill")
                .font(.system(size: 14))
                .foregroundStyle(TinyTokens.ColorToken.textPrimary)
                .frame(width: 22, height: 28)
        }
    }

    private func windowPane(width: CGFloat, height: CGFloat, time: TimeInterval, phase: Double) -> some View {
        let glow = 0.30 + 0.12 * abs(sin(time * 0.45 + phase))
        return RoundedRectangle(cornerRadius: 5)
            .fill(
                LinearGradient(
                    colors: [
                        Color(red: 0.24, green: 0.58, blue: 0.95).opacity(0.56 + glow * 0.35),
                        Color(red: 0.18, green: 0.36, blue: 0.62).opacity(0.40 + glow * 0.30)
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
            )
            .overlay(
                RoundedRectangle(cornerRadius: 5)
                    .stroke(.white.opacity(0.22), lineWidth: 0.6)
            )
            .frame(width: width, height: height)
    }

    // MARK: Helpers

    private func point(anchor: CGPoint, in size: CGSize) -> CGPoint {
        CGPoint(x: size.width * anchor.x, y: size.height * anchor.y)
    }

    private var sceneBorderColor: Color {
        switch sceneState.riskLevel {
        case .danger: return TinyTokens.ColorToken.borderDanger
        case .warn:   return TinyTokens.ColorToken.borderWarning
        case .normal: return TinyTokens.ColorToken.borderDefault
        }
    }

    private func speedMultiplier(for profile: OfficeMotionProfile) -> Double {
        switch profile {
        case .calm:   return 0.85
        case .steady: return 1.0
        case .busy:   return 1.25
        case .urgent: return 1.55
        }
    }

    private func amplitude(for profile: OfficeMotionProfile) -> CGFloat {
        switch profile {
        case .calm:   return 1.4
        case .steady: return 2.0
        case .busy:   return 2.8
        case .urgent: return 3.4
        }
    }

    private func characterAssetName(for kind: EmployeeKind) -> String {
        switch kind {
        case .founder: return "char_founder_01"
        case .dev:     return "char_staff_dev_01"
        case .pm:      return "char_staff_pm_01"
        }
    }

    private enum EmployeeKind: Equatable {
        case founder, dev, pm
    }
}

// MARK: - Event Beacon (36pt, glow ring, bobbing)

private struct EventBeacon: View {
    let category: String
    let riskLevel: RiskLevel
    let time: TimeInterval

    var body: some View {
        let spec       = EventVisualCatalog.spec(for: category)
        let bob        = CGFloat(sin(time * 2.0)) * 2.5
        let glowPulse  = 0.20 + 0.25 * abs(sin(time * 1.8))
        let catColor   = TinyTokens.ColorToken.categoryBadge(category)

        return ZStack {
            // Outer animated glow ring
            Circle()
                .fill(catColor.opacity(glowPulse))
                .frame(width: 50, height: 50)
            // Background disc
            Circle()
                .fill(TinyTokens.ColorToken.bgPopover.opacity(0.95))
                .frame(width: 36, height: 36)
            // Category icon
            TinyAsset.icon(assetName: spec.iconAssetName, sfSymbol: spec.fallbackSymbol)
                .font(.system(size: 15, weight: .semibold))
                .foregroundStyle(catColor)
        }
        .overlay(
            Circle()
                .stroke(beaconBorderColor, lineWidth: 1.5)
                .frame(width: 36, height: 36)
        )
        .shadow(color: catColor.opacity(0.35), radius: 6, x: 0, y: 2)
        .offset(y: bob)
    }

    private var beaconBorderColor: Color {
        switch riskLevel {
        case .danger: return TinyTokens.ColorToken.borderDanger
        case .warn:   return TinyTokens.ColorToken.borderWarning
        case .normal: return TinyTokens.ColorToken.categoryBadge(category)
        }
    }
}

// MARK: - Office Info Strip (bottom of scene)

private struct OfficeInfoStrip: View {
    let sceneState: OfficeSceneState
    let inboxCount: Int

    var body: some View {
        HStack(spacing: 0) {
            // Team size
            infoPill(
                symbol: "person.2.fill",
                text: "社員\(sceneState.totalEmployeeCount)名",
                color: TinyTokens.ColorToken.textPrimary
            )

            // Focus category (if any)
            if let cat = sceneState.focusCategory {
                categoryPill(for: cat)
            }

            Spacer(minLength: 0)

            // Inbox count
            infoPill(
                symbol: inboxCount > 0 ? "tray.fill" : "tray",
                text: "Inbox \(inboxCount)",
                color: inboxCount > 0
                    ? TinyTokens.ColorToken.statusHealthy
                    : TinyTokens.ColorToken.textSecondary
            )
        }
        .background(.black.opacity(0.32))
    }

    private func infoPill(symbol: String, text: String, color: Color) -> some View {
        HStack(spacing: 3) {
            Image(systemName: symbol)
                .font(.system(size: 9))
            Text(text)
                .font(.system(size: 10, weight: .medium))
        }
        .foregroundStyle(color)
        .padding(.horizontal, 8)
        .padding(.vertical, 5)
    }

    private func categoryPill(for cat: String) -> some View {
        let spec = EventVisualCatalog.spec(for: cat)
        return HStack(spacing: 3) {
            Image(systemName: spec.fallbackSymbol)
                .font(.system(size: 9))
            Text(spec.label)
                .font(.system(size: 10, weight: .medium))
        }
        .foregroundStyle(TinyTokens.ColorToken.categoryBadge(cat))
        .padding(.horizontal, 6)
        .padding(.vertical, 5)
    }
}

// MARK: - Office Grid Pattern

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

// MARK: - KPI Cell

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
        case .normal: return TinyTokens.ColorToken.bgCell
        case .warn:   return TinyTokens.ColorToken.bgWarning
        case .danger: return TinyTokens.ColorToken.bgDanger
        }
    }

    private func borderColor(for level: RiskLevel) -> Color {
        switch level {
        case .normal: return TinyTokens.ColorToken.borderDefault
        case .warn:   return TinyTokens.ColorToken.borderWarning
        case .danger: return TinyTokens.ColorToken.borderDanger
        }
    }
}

// MARK: - Risk Badge

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
        case .normal: return "NORMAL"
        case .warn:   return "WARN"
        case .danger: return "DANGER"
        }
    }

    private var color: Color {
        switch level {
        case .normal: return TinyTokens.ColorToken.statusHealthy
        case .warn:   return TinyTokens.ColorToken.statusWarning
        case .danger: return TinyTokens.ColorToken.statusDanger
        }
    }
}

// MARK: - Crisis Banner

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

// MARK: - Office Decoration Row

private struct OfficeDecorationRow: View {
    let sceneState: OfficeSceneState

    var body: some View {
        HStack(alignment: .bottom, spacing: 8) {
            sprite("office_desk_01", width: 32, height: 32)
            sprite("office_monitor_01", width: 32, height: 32)
            if sceneState.showPlant {
                sprite("office_plant_01", width: 24, height: 32)
            }
            Spacer(minLength: 0)
            if sceneState.showDesk2 {
                sprite("office_desk_02", width: 32, height: 32)
            }
            if sceneState.showServer {
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
