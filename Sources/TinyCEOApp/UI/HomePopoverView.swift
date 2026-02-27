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

    private var officeSceneState: OfficeSceneState {
        OfficeSceneState.from(
            snapshot: store.snapshot,
            viewState: store.viewState,
            focusCategory: store.focusInboxCategory
        )
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
                StatPill(symbol: "person.3.fill", text: "社員 \(officeSceneState.totalEmployeeCount)名")
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
                sceneState: officeSceneState,
                inboxCount: store.viewState.inboxCount
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
                OfficeDecorationRow(sceneState: officeSceneState)
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
    @Environment(\.colorScheme) private var colorScheme

    let sceneState: OfficeSceneState
    let inboxCount: Int

    private enum EmployeeKind: Equatable {
        case founder
        case dev
        case pm
    }

    private enum SeatMotion {
        case typing
        case headNod
        case leanSide
        case idleSway
        case urgentBounce
        case standWalk
    }

    private let seatAnchors: [CGPoint] = [
        CGPoint(x: 0.26, y: 0.44),
        CGPoint(x: 0.50, y: 0.44),
        CGPoint(x: 0.74, y: 0.44),
        CGPoint(x: 0.34, y: 0.70),
        CGPoint(x: 0.50, y: 0.70),
        CGPoint(x: 0.66, y: 0.70)
    ]

    private let phaseSeed: [Double] = [0.00, 0.37, 0.62, 0.81, 0.19, 0.54]

    /// Per-sprite visual-center correction derived from non-transparent pixel bounds.
    /// dx/dy are measured in source image pixels from image center to visible center.
    private let spriteVisualMeta: [String: SpriteVisualMeta] = [
        "office_desk_01": .init(sourceSize: .init(width: 64, height: 32), dx: 1.5, dy: 0),
        "office_monitor_01": .init(sourceSize: .init(width: 16, height: 16), dx: -3.0, dy: 0),
        "office_prop_window_blue_2dpig": .init(sourceSize: .init(width: 26, height: 21), dx: 0, dy: 0),
        "office_prop_window_note_2dpig": .init(sourceSize: .init(width: 26, height: 21), dx: 0, dy: 0),
        "office_prop_shelf_blue_2dpig": .init(sourceSize: .init(width: 24, height: 34), dx: 0, dy: 0),
        "office_prop_shelf_orange_2dpig": .init(sourceSize: .init(width: 24, height: 31), dx: 0, dy: 0),
        "office_prop_couch_blue_2dpig": .init(sourceSize: .init(width: 33, height: 16), dx: 0, dy: 0),
        "office_prop_couch_orange_2dpig": .init(sourceSize: .init(width: 33, height: 16), dx: 0, dy: 0),
        "char_founder_01": .init(sourceSize: .init(width: 16, height: 32), dx: 1.5, dy: 10.0),
        "char_staff_dev_01": .init(sourceSize: .init(width: 16, height: 32), dx: 1.0, dy: 4.5),
        "char_staff_pm_01": .init(sourceSize: .init(width: 16, height: 32), dx: 0, dy: 4.0)
    ]

    var body: some View {
        TimelineView(.animation(minimumInterval: 1.0 / 8.0)) { timeline in
            GeometryReader { proxy in
                let size = proxy.size
                let time = timeline.date.timeIntervalSinceReferenceDate

                ZStack(alignment: .topLeading) {
                    RoundedRectangle(cornerRadius: 10)
                        .fill(TinyTokens.ColorToken.bgCell)

                    floorTextureLayer()

                    officePropsLayer(size: size)

                    backRowCharactersLayer(size: size, time: time)
                    frontRowCharactersLayer(size: size, time: time)

                    atmosphereLayer(time: time)
                        .clipShape(RoundedRectangle(cornerRadius: 10))

                    if let category = sceneState.focusCategory {
                        EventBeacon(category: category, riskLevel: sceneState.riskLevel, time: time)
                            .position(x: size.width - 30, y: 30)
                    }

                    VStack(spacing: 0) {
                        Spacer()
                        OfficeInfoStrip(
                            teamCount: sceneState.totalEmployeeCount,
                            inboxCount: inboxCount,
                            focusCategory: sceneState.focusCategory
                        )
                    }
                }
                .clipShape(RoundedRectangle(cornerRadius: 10))
                .overlay(
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(sceneBorderColor, lineWidth: sceneBorderWidth)
                )
            }
            .frame(height: 200)
        }
    }

    // MARK: Layers

    @ViewBuilder
    private func floorTextureLayer() -> some View {
        if let bg = TinyAsset.officeSprite(named: "office_backdrop_main_2dpig") {
            bg
                .resizable()
                .interpolation(.none)
                .antialiased(false)
                .scaledToFill()
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .opacity(0.92)
                .clipShape(RoundedRectangle(cornerRadius: 10))
                .overlay {
                    LinearGradient(
                        colors: [
                            Color.black.opacity(0.08),
                            Color.black.opacity(0.24)
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                    .clipShape(RoundedRectangle(cornerRadius: 10))
                }
        } else {
            LinearGradient(
                colors: [
                    Color.white.opacity(0.015),
                    Color.black.opacity(0.05)
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            .clipShape(RoundedRectangle(cornerRadius: 10))
        }
    }

    @ViewBuilder
    private func officePropsLayer(size: CGSize) -> some View {
        let maturity = stageVisualMaturity
        let edgePropOpacity = 0.42 + 0.40 * maturity

        LinearGradient(
            colors: [
                Color.white.opacity(0.04),
                .clear
            ],
            startPoint: .top,
            endPoint: .bottom
        )

        VStack(spacing: 0) {
            Spacer()
            Rectangle()
                .fill(Color.black.opacity(0.16))
                .frame(height: 1)
            LinearGradient(
                colors: [
                    .clear,
                    Color.black.opacity(0.18)
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            .frame(height: size.height * 0.18)
        }

        sprite(name: "office_prop_terminal_2dpig", width: 16, height: 20)
            .position(x: size.width * 0.08, y: size.height * 0.76)
            .opacity(edgePropOpacity)

        sprite(name: "office_prop_shelf_orange_2dpig", width: 20, height: 28)
            .position(x: size.width * 0.92, y: size.height * 0.76)
            .opacity(edgePropOpacity)

        if sceneState.showPlant {
            sprite(name: "office_plant_01", width: 14, height: 24)
                .position(x: size.width * 0.18, y: size.height * 0.75)
                .opacity(edgePropOpacity)
        }
    }

    @ViewBuilder
    private func backRowCharactersLayer(size: CGSize, time: TimeInterval) -> some View {
        ForEach(0..<3, id: \.self) { index in
            if index < sceneState.activeEmployeeCount {
                employeeSprite(kind: employeeKind(for: index))
                    .overlay(alignment: .top) {
                        if sceneState.showActivityDots {
                            activityDots(time: time, employeeIndex: index)
                                .offset(y: -12)
                        }
                    }
                    .position(animatedPosition(for: index, in: size, time: time))
            }
        }
    }

    @ViewBuilder
    private func frontRowCharactersLayer(size: CGSize, time: TimeInterval) -> some View {
        ForEach(3..<6, id: \.self) { index in
            if index < sceneState.activeEmployeeCount {
                employeeSprite(kind: employeeKind(for: index))
                    .overlay(alignment: .top) {
                        if sceneState.showActivityDots {
                            activityDots(time: time, employeeIndex: index)
                                .offset(y: -12)
                        }
                    }
                    .position(animatedPosition(for: index, in: size, time: time))
            }
        }
    }

    private func atmosphereLayer(time: TimeInterval) -> some View {
        let pulse: Double = sceneState.riskLevel == .danger ? 0.7 + 0.3 * abs(sin(time * 1.5)) : 1.0
        return LinearGradient(
            colors: [
                sceneState.atmosphereColor.opacity(sceneState.atmosphereOpacity * pulse),
                .clear
            ],
            startPoint: .bottom,
            endPoint: .top
        )
    }

    // MARK: Sprite Helpers

    private func deskUnit(at point: CGPoint, active: Bool) -> some View {
        ZStack {
            Group {
                if let desk = TinyAsset.officeSprite(named: "office_desk_01") {
                    desk
                        .resizable()
                        .interpolation(.none)
                        .scaledToFit()
                        .offset(visualAlignmentOffset(for: "office_desk_01", targetSize: CGSize(width: 36, height: 20)))
                } else {
                    RoundedRectangle(cornerRadius: 3)
                        .fill(TinyTokens.ColorToken.bgPopover.opacity(0.75))
                        .overlay(
                            RoundedRectangle(cornerRadius: 3)
                                .stroke(TinyTokens.ColorToken.borderDefault.opacity(0.8), lineWidth: 1)
                        )
                }
            }
            .frame(width: 36, height: 20)
            .offset(y: 11)

            Group {
                if let monitor = TinyAsset.officeSprite(named: "office_monitor_01") {
                    monitor
                        .resizable()
                        .interpolation(.none)
                        .scaledToFit()
                        .offset(visualAlignmentOffset(for: "office_monitor_01", targetSize: CGSize(width: 18, height: 22)))
                } else {
                    RoundedRectangle(cornerRadius: 2)
                        .fill(TinyTokens.ColorToken.borderDefault.opacity(0.75))
                }
            }
            .frame(width: 18, height: 22)
            .offset(y: -11)
        }
        .frame(width: 36, height: 44)
        .position(point)
        .opacity(active ? 1.0 : sceneState.inactiveSeatOpacity)
    }

    private func seatShadow(at point: CGPoint, active: Bool) -> some View {
        Ellipse()
            .fill(Color.black.opacity(active ? 0.16 : max(0.03, sceneState.inactiveSeatOpacity * 0.5)))
            .frame(width: 28, height: 5)
            .position(x: point.x, y: point.y + 18)
    }

    private func seatMarker(at point: CGPoint, active: Bool) -> some View {
        RoundedRectangle(cornerRadius: 3)
            .fill(active ? Color.white.opacity(0.09) : Color.white.opacity(0.03))
            .frame(width: 24, height: 5)
            .overlay(
                RoundedRectangle(cornerRadius: 3)
                    .stroke(Color.white.opacity(active ? 0.10 : 0.04), lineWidth: 1)
            )
            .position(x: point.x, y: point.y + 13)
    }

    private func backStorageUnit() -> some View {
        RoundedRectangle(cornerRadius: 3)
            .fill(Color(red: 0.19, green: 0.30, blue: 0.44))
            .frame(width: 24, height: 18)
            .overlay(
                RoundedRectangle(cornerRadius: 3)
                    .stroke(TinyTokens.ColorToken.borderDefault.opacity(0.8), lineWidth: 1)
            )
            .overlay(alignment: .topLeading) {
                Capsule()
                    .fill(Color.white.opacity(0.45))
                    .frame(width: 7, height: 2)
                    .offset(x: 4, y: 4)
            }
    }

    private func serverRackUnit() -> some View {
        RoundedRectangle(cornerRadius: 3)
            .fill(Color(red: 0.12, green: 0.14, blue: 0.17))
            .frame(width: 18, height: 34)
            .overlay(
                RoundedRectangle(cornerRadius: 3)
                    .stroke(TinyTokens.ColorToken.borderDefault.opacity(0.7), lineWidth: 1)
            )
            .overlay {
                VStack(spacing: 3) {
                    ForEach(0..<4, id: \.self) { _ in
                        RoundedRectangle(cornerRadius: 1)
                            .fill(Color(red: 0.25, green: 0.33, blue: 0.45))
                            .frame(width: 11, height: 3)
                    }
                }
            }
    }

    private func pottedPlantDecoration() -> some View {
        ZStack(alignment: .bottom) {
            RoundedRectangle(cornerRadius: 2)
                .fill(Color(red: 0.33, green: 0.25, blue: 0.16))
                .frame(width: 10, height: 9)
                .offset(y: 10)

            VStack(spacing: 0) {
                RoundedRectangle(cornerRadius: 1)
                    .fill(Color(red: 0.18, green: 0.64, blue: 0.35))
                    .frame(width: 2, height: 10)
                HStack(spacing: 1) {
                    Circle().fill(Color(red: 0.22, green: 0.74, blue: 0.40)).frame(width: 6, height: 6)
                    Circle().fill(Color(red: 0.15, green: 0.56, blue: 0.30)).frame(width: 6, height: 6)
                }
            }
        }
        .frame(width: 16, height: 26)
    }

    @ViewBuilder
    private func sprite(name: String, width: CGFloat, height: CGFloat) -> some View {
        if let image = TinyAsset.officeSprite(named: name) {
            image
                .resizable()
                .interpolation(.none)
                .scaledToFit()
                .frame(width: width, height: height)
                .offset(visualAlignmentOffset(for: name, targetSize: CGSize(width: width, height: height)))
        } else {
            Rectangle()
                .fill(.clear)
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
                .scaledToFit()
                .frame(width: 20, height: 32)
                .offset(visualAlignmentOffset(for: assetName, targetSize: CGSize(width: 20, height: 32)))
                .shadow(color: .black.opacity(0.25), radius: 1, x: 0, y: 1)
        } else {
            Image(systemName: "person.fill")
                .font(.system(size: 14))
                .foregroundStyle(TinyTokens.ColorToken.textPrimary)
                .frame(width: 20, height: 32)
        }
    }

    private func activityDots(time: TimeInterval, employeeIndex: Int) -> some View {
        let speedMultiplier = sceneState.riskLevel == .danger
            ? 1.5
            : (sceneState.motionProfile == .busy || sceneState.riskLevel == .warn ? 1.2 : 1.0)
        let amplitude: CGFloat = sceneState.riskLevel == .danger ? 3.5 : 2.5
        let dotColor = sceneState.riskLevel == .danger ? Color.red.opacity(0.85) : Color.white.opacity(0.80)

        return HStack(spacing: 3) {
            dot(time: time, dotIndex: 0, employeeIndex: employeeIndex, speedMultiplier: speedMultiplier, amplitude: amplitude, color: dotColor)
            dot(time: time, dotIndex: 1, employeeIndex: employeeIndex, speedMultiplier: speedMultiplier, amplitude: amplitude, color: dotColor)
            dot(time: time, dotIndex: 2, employeeIndex: employeeIndex, speedMultiplier: speedMultiplier, amplitude: amplitude, color: dotColor)
        }
    }

    private func dot(
        time: TimeInterval,
        dotIndex: Int,
        employeeIndex: Int,
        speedMultiplier: Double,
        amplitude: CGFloat,
        color: Color
    ) -> some View {
        let phase = time * (5.5 * speedMultiplier) + Double(dotIndex) * 0.9 + Double(employeeIndex) * 0.4
        let dy = -abs(CGFloat(sin(phase))) * amplitude
        return Circle()
            .fill(color)
            .frame(width: 3, height: 3)
            .offset(y: dy)
    }

    // MARK: Motion

    private func animatedPosition(for index: Int, in size: CGSize, time: TimeInterval) -> CGPoint {
        let base = point(anchor: seatAnchors[index], in: size)
        let speed = sceneState.motionProfile.speedMultiplier
        let seed = phaseSeed[index % phaseSeed.count] * 2 * .pi

        let motion: SeatMotion
        if sceneState.motionProfile == .urgent {
            motion = .urgentBounce
        } else if shouldUseStandWalk(for: index) {
            motion = .standWalk
        } else {
            motion = defaultMotion(for: index)
        }

        var dx: CGFloat = 0
        var dy: CGFloat = 0

        switch motion {
        case .typing:
            dy = CGFloat(sin(time * speed * 25 + seed) * 1.5)
        case .headNod:
            dy = CGFloat(sin(time * speed * 5.2 + seed) * 2.0)
        case .leanSide:
            dx = CGFloat(sin(time * speed * 3.1 + seed) * 1.5)
        case .idleSway:
            dx = CGFloat(sin(time * speed * 1.8 + seed) * 1.0)
            dy = CGFloat(sin(time * speed * 2.1 + seed) * 0.8)
        case .urgentBounce:
            dy = -CGFloat(abs(sin(time * speed * 34 + seed)) * 3.0)
        case .standWalk:
            let walkPhase = (time * 0.125 * speed).truncatingRemainder(dividingBy: 1.0)
            if walkPhase < 0.5 {
                dx = CGFloat(lerp(-12, 12, t: walkPhase * 2))
            } else {
                dx = CGFloat(lerp(12, -12, t: (walkPhase - 0.5) * 2))
            }
            dy = CGFloat(sin(time * speed * 3.2 + seed) * 0.8)
        }

        return CGPoint(x: base.x + dx, y: base.y + dy - 8)
    }

    private func defaultMotion(for index: Int) -> SeatMotion {
        switch index {
        case 0, 4:
            return .typing
        case 1, 5:
            return .headNod
        case 2:
            return .leanSide
        default:
            return .idleSway
        }
    }

    private func shouldUseStandWalk(for index: Int) -> Bool {
        sceneState.growthStage == .mature
            && sceneState.motionProfile != .urgent
            && sceneState.activeEmployeeCount >= 5
            && index == 5
    }

    // MARK: Helpers

    private var wallTopColor: Color {
        if colorScheme == .dark {
            return Color(red: 0.18, green: 0.17, blue: 0.16)
        }
        return Color(red: 0.92, green: 0.91, blue: 0.89)
    }

    private var sceneBorderColor: Color {
        switch sceneState.riskLevel {
        case .danger:
            return TinyTokens.ColorToken.borderDanger
        case .warn:
            return TinyTokens.ColorToken.borderWarning
        case .normal:
            return TinyTokens.ColorToken.borderDefault
        }
    }

    private var sceneBorderWidth: CGFloat {
        sceneState.riskLevel == .danger ? 2.0 : 1.0
    }

    private var stageVisualMaturity: Double {
        switch sceneState.growthStage {
        case .seed:
            return 0.45
        case .growth:
            return 0.72
        case .mature:
            return 1.0
        }
    }

    private func point(anchor: CGPoint, in size: CGSize) -> CGPoint {
        CGPoint(x: size.width * anchor.x, y: size.height * anchor.y)
    }

    private func employeeKind(for index: Int) -> EmployeeKind {
        switch index {
        case 0:
            return .founder
        case 2, 4:
            return .pm
        default:
            return .dev
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

    private func lerp(_ a: Double, _ b: Double, t: Double) -> Double {
        a + (b - a) * t
    }

    private func visualAlignmentOffset(for assetName: String, targetSize: CGSize) -> CGSize {
        guard let meta = spriteVisualMeta[assetName], meta.sourceSize.width > 0, meta.sourceSize.height > 0 else {
            return .zero
        }

        // Keep aspect ratio (scaledToFit), then translate by inverse visible-center delta.
        let scale = min(
            targetSize.width / meta.sourceSize.width,
            targetSize.height / meta.sourceSize.height
        )
        return CGSize(width: -meta.dx * scale, height: -meta.dy * scale)
    }
}

private struct SpriteVisualMeta {
    let sourceSize: CGSize
    let dx: CGFloat
    let dy: CGFloat
}

private struct EventBeacon: View {
    let category: String
    let riskLevel: RiskLevel
    let time: TimeInterval

    var body: some View {
        let spec = EventVisualCatalog.spec(for: category)
        let bob = CGFloat(sin(time * 2.0)) * 2.5
        let glowPulse = 0.20 + 0.25 * abs(sin(time * 1.8))
        let categoryColor = TinyTokens.ColorToken.categoryBadge(category)

        return ZStack {
            Circle()
                .fill(categoryColor.opacity(glowPulse))
                .frame(width: 50, height: 50)

            Circle()
                .fill(TinyTokens.ColorToken.bgPopover.opacity(0.95))
                .frame(width: 36, height: 36)

            TinyAsset.icon(assetName: spec.iconAssetName, sfSymbol: spec.fallbackSymbol)
                .font(.system(size: 15, weight: .semibold))
                .foregroundStyle(categoryColor)
        }
        .overlay {
            Circle()
                .stroke(beaconBorderColor, lineWidth: 1.5)
                .frame(width: 36, height: 36)
        }
        .shadow(color: categoryColor.opacity(0.35), radius: 6, x: 0, y: 2)
        .offset(y: bob)
    }

    private var beaconBorderColor: Color {
        switch riskLevel {
        case .danger:
            return TinyTokens.ColorToken.borderDanger
        case .warn:
            return TinyTokens.ColorToken.borderWarning
        case .normal:
            return TinyTokens.ColorToken.categoryBadge(category)
        }
    }
}

private struct OfficeInfoStrip: View {
    let teamCount: Int
    let inboxCount: Int
    let focusCategory: String?

    var body: some View {
        HStack(spacing: 0) {
            infoPill(symbol: "person.2.fill", text: "社員\(teamCount)名", color: TinyTokens.ColorToken.textPrimary)

            if let focusCategory {
                categoryPill(for: focusCategory)
            }

            Spacer(minLength: 0)

            infoPill(
                symbol: inboxCount > 0 ? "tray.fill" : "tray",
                text: "Inbox \(inboxCount)",
                color: inboxCount > 0 ? TinyTokens.ColorToken.statusHealthy : TinyTokens.ColorToken.textSecondary
            )
        }
        .padding(.vertical, 1)
        .background(.black.opacity(0.34))
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

    private func categoryPill(for category: String) -> some View {
        let spec = EventVisualCatalog.spec(for: category)
        return HStack(spacing: 3) {
            Image(systemName: spec.fallbackSymbol)
                .font(.system(size: 9))
            Text(spec.label)
                .font(.system(size: 10, weight: .medium))
        }
        .foregroundStyle(TinyTokens.ColorToken.categoryBadge(category))
        .padding(.horizontal, 6)
        .padding(.vertical, 5)
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
