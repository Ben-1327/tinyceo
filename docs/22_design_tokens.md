# 22 Design Tokens — TinyCEO v0.1

> 対象: Codex実装担当・将来の追加デザイン担当
> 参照仕様: `docs/21_design_spec_v01.md`
> 実装形式: Swift enum / struct で定義すること（直接 `#hex` を埋め込まない）

---

## 1. カラートークン

### 1.1 基本構造

SwiftUI / AppKit での実装時は `Asset Catalog` の `Color Set` に登録し、
`Any Appearance`（Light）と `Dark` の2値を設定すること。

```swift
// 命名規約: TinyColors.<token_name>
// 例:
extension Color {
    static let tinyBgBase = Color("bg/base")
    static let tinyStatusDanger = Color("status/danger")
}
```

---

### 1.2 背景・サーフェス

| トークン名 | Light (#hex) | Dark (#hex) | 用途 |
|-----------|-------------|------------|------|
| `bg/base` | `#FAF8F5` | `#1C1A18` | アプリ全体の基盤 |
| `bg/popover` | `#FFFFFF` | `#242220` | NSPopoverのメイン背景 |
| `bg/cell` | `#F5F3F0` | `#2C2A28` | KPIセル、カード行 |
| `bg/button/primary` | `#3A3A3C` | `#E8E6E3` | プライマリボタン背景 |
| `bg/button/choice` | `#FFFFFF` | `#2C2A28` | 3択ボタン背景 |
| `bg/hover` | `#EDEBE8` | `#363432` | hover 時のセル・ボタン |
| `bg/pressed` | `#E5E3E0` | `#3E3C3A` | pressed 時 |
| `bg/crisis` | `#FFF0EE` | `#2E1A1A` | Crisis Banner 背景 |
| `bg/warning` | `#FFF7EC` | `#2A2116` | Warning状態のセル背景 |
| `bg/danger` | `#FFF0EE` | `#2E1818` | Danger状態のセル背景 |
| `bg/progressTrack` | `#E5E5EA` | `#3A3A3C` | プログレスバーのトラック |
| `separator` | `#E5E5EA` | `#38363A` | セパレーター線 |

---

### 1.3 テキスト

| トークン名 | Light (#hex) | Dark (#hex) | 用途 |
|-----------|-------------|------------|------|
| `text/primary` | `#1C1C1E` | `#F2F0ED` | 本文、KPI値 |
| `text/secondary` | `#636366` | `#98989D` | ラベル、サブテキスト |
| `text/tertiary` | `#AEAEB2` | `#636366` | ヒント、プレースホルダー |
| `text/button/primary` | `#FFFFFF` | `#1C1C1E` | プライマリボタン内テキスト |
| `text/button/choice` | `#1C1C1E` | `#F2F0ED` | 3択ボタン内テキスト |
| `text/link` | `#007AFF` | `#0A84FF` | リンク・インラインアクション |

---

### 1.4 ステータス・セマンティック

| トークン名 | Light (#hex) | Dark (#hex) | 用途 |
|-----------|-------------|------------|------|
| `status/healthy` | `#30D158` | `#30D158` | 良好状態の強調 |
| `status/warning` | `#FF9F0A` | `#FFD60A` | 注意・悪化傾向 |
| `status/danger` | `#FF3B30` | `#FF453A` | 危険・Crisis |
| `status/neutral` | `#636366` | `#98989D` | 変化なし・中立 |
| `border/warning` | `#FF9F0A` | `#FFD60A` | Warning セルのボーダー |
| `border/danger` | `#FF3B30` | `#FF453A` | Danger セルのボーダー |
| `border/default` | `#E5E5EA` | `#3A3A3C` | 通常ボーダー |
| `border/focus` | `#007AFF` | `#0A84FF` | フォーカス状態 |

---

### 1.5 KPIアクセント（通常状態）

| トークン名 | Light (#hex) | Dark (#hex) | 対応KPI |
|-----------|-------------|------------|--------|
| `kpi/cash` | `#1C1C1E` | `#F2F0ED` | Cash（通常は primary text） |
| `kpi/runway` | `#1C1C1E` | `#F2F0ED` | Runway（通常は primary text） |
| `kpi/reputation` | `#5856D6` | `#7D7AFF` | Reputation（インディゴ） |
| `kpi/health` | `#25A244` | `#30D158` | TeamHealth（グリーン） |
| `kpi/techdebt` | `#E6780C` | `#FF9F0A` | TechDebt（アンバー/オレンジ） |

---

### 1.6 エフェクト値表示

| トークン名 | Light (#hex) | Dark (#hex) | 用途 |
|-----------|-------------|------------|------|
| `effect/positive` | `#25A244` | `#30D158` | +値（Cash増加、Health増加等） |
| `effect/negative` | `#FF3B30` | `#FF453A` | -値（Cash減少、TechDebt増加等） |
| `effect/neutral` | `#636366` | `#98989D` | 変化なし |

---

### 1.7 カテゴリバッジ

| カテゴリID | 背景 (#hex) | テキスト |
|-----------|------------|---------|
| STRATEGY | `#5856D6` | `#FFFFFF` |
| HIRING | `#25A244` | `#FFFFFF` |
| PROCESS | `#636366` | `#FFFFFF` |
| SALES | `#E6780C` | `#FFFFFF` |
| PRODUCT | `#007AFF` | `#FFFFFF` |
| FINANCE | `#FF3B30` | `#FFFFFF` |
| CRISIS | `#FF3B30` | `#FFFFFF` |
| CULTURE | `#E05050` | `#FFFFFF` |
| AI | `#BF5AF2` | `#FFFFFF` |

> カテゴリバッジの背景色は Light/Dark で同一値を使う（識別子として機能するため変えない）。

---

## 2. タイポグラフィトークン

フォントは **SF Pro（システムフォント）** のみを使用する。
Google Fonts等の外部フォントは v0.1 では使用しない。

```swift
// 実装例
extension Font {
    static let tinyTitle = Font.system(size: 17, weight: .semibold)
    static let tinyBody = Font.system(size: 13, weight: .regular)
    static let tinyKpiValue = Font.system(size: 17, weight: .semibold, design: .rounded)
}
```

| トークン名 | サイズ | Weight | Design | 用途 |
|-----------|--------|--------|--------|------|
| `type/screen-title` | 15pt | Medium | Default | ヘッダーのタイトル |
| `type/section-header` | 11pt | Semibold | Default | セクション見出し（大文字推奨） |
| `type/body` | 13pt | Regular | Default | 本文、カードフレーバー |
| `type/body-medium` | 13pt | Medium | Default | リスト項目のタイトル、ラベル |
| `type/caption` | 11pt | Regular | Default | サブテキスト、タグ |
| `type/caption-semibold` | 11pt | Semibold | Default | バッジ、ステータス文字 |
| `type/kpi-value` | 17pt | Semibold | Rounded | KPI数値 |
| `type/kpi-label` | 10pt | Regular | Default | KPIラベル（CASH等） |
| `type/choice-label` | 16pt | Medium | Monospaced | カード択の A/B/C ラベル |
| `type/button-primary` | 13pt | Medium | Default | プライマリボタン |
| `type/countdown` | 12pt | Regular | Default | 次カードまでのカウントダウン |

**数値表示の注意:**
- KPI値（¥金額、Runway月数）は必ずタブ幅固定の数値（tabular figures）を使用する
- SwiftUI: `.monospacedDigit()` modifier を付与する

---

## 3. スペーシングトークン

基本単位: **4pt**

| トークン名 | 値 | 用途 |
|-----------|-----|------|
| `space/1` | 4pt | 最小間隔（アイコンと文字の間等） |
| `space/2` | 8pt | タイトルとサブテキストの間 |
| `space/3` | 12pt | コンポーネント内パディング |
| `space/4` | 16pt | セクション間・ポップオーバーのサイドパディング |
| `space/5` | 20pt | セクション見出し上の余白 |
| `space/6` | 24pt | 大きなセクション間 |

### コンポーネント別スペーシング

| コンポーネント | 水平 padding | 垂直 padding | gap |
|-------------|-------------|-------------|-----|
| Popover全体 | 16pt | 0pt（各セクションで管理） | — |
| Header | 16pt | 12pt | — |
| KPIセクション | 16pt | 12pt上 / 8pt下 | 8pt（セル間） |
| KPIセル | 8pt | 10pt | — |
| Projectセクション | 16pt | 12pt | 8pt（バー間） |
| Inboxロウ | 16pt | 12pt | — |
| CardRow（Inbox一覧） | 12pt | 10pt | — |
| CardDetail全体 | 16pt | 16pt | 12pt（要素間） |
| ChoiceButton | 12pt | 10pt | 8pt（A/B/Cボタン間） |
| Crisis Banner | 16pt | 10pt | — |

---

## 4. Radiusトークン

| トークン名 | 値 | 用途 |
|-----------|-----|------|
| `radius/sm` | 4pt | カテゴリバッジ、Risk Badge |
| `radius/md` | 8pt | KPIセル、Choice Button、CardRow |
| `radius/lg` | 12pt | オンボーディングカード等の大型コンテナ |
| `radius/pill` | 999pt | 完全な丸角（ステータスインジケーター） |

**NSPopover 自体の radius は macOS が制御するため定義しない。**

---

## 5. シャドウトークン

| トークン名 | 値 | 用途 |
|-----------|-----|------|
| `shadow/card` | `x:0 y:1 blur:3 color:rgba(0,0,0,0.08)` + `x:0 y:0 blur:0 spread:1 color:rgba(0,0,0,0.04)` | CardRow, KPIセル |
| `shadow/button/hover` | `x:0 y:2 blur:8 color:rgba(0,0,0,0.12)` | ChoiceButton hover時 |
| `shadow/crisis-banner` | なし（border-bottomで代替） | Crisis Banner |

**実装注意:**
- `shadow/card` は Light モードのみ表示。Dark モードでは border（1pt separator色）に切り替える。
- NSPopover自体のドロップシャドウはmacOSネイティブ（変更不要）。

---

## 6. アニメーショントークン

| トークン名 | 値 | 用途 |
|-----------|-----|------|
| `motion/fast` | 150ms easeOut | hover, tap フィードバック |
| `motion/standard` | 200ms easeInOut | 画面遷移、バナー出現 |
| `motion/slow` | 400ms easeOut | KPI数値アニメーション |
| `motion/pulse-period` | 1500ms easeInOut | メニューバー danger dot |
| `motion/spring-choice` | spring(response:0.3, dampingFraction:0.8) | ChoiceButton press |
| `motion/spring-badge` | spring(response:0.25, dampingFraction:0.6) | Inboxバッジ変化 |

---

## 7. コンポーネントサイズトークン

| トークン名 | 値 | 用途 |
|-----------|-----|------|
| `size/popover-width` | 360pt | ポップオーバー標準幅（default） |
| `size/popover-min-width` | 300pt | 最小幅 |
| `size/header-height` | 44pt | Header bar |
| `size/kpi-cell-height` | 56pt | KPIセル |
| `size/choice-button-min-height` | 56pt | 3択ボタン（アクセシビリティ最小タップ高さ） |
| `size/card-row-min-height` | 64pt | Inbox CardRow |
| `size/progress-bar-height` | 6pt | プログレスバー |
| `size/menubar-icon` | 18×18pt | メニューバーアイコン |
| `size/status-dot` | 8pt diameter | メニューバーのステータスドット |
| `size/category-badge-height` | 20pt | カテゴリバッジ |
| `size/risk-badge-height` | 18pt | Risk Badge |

---

## 8. アイコン使用トークン（SF Symbols 対応表）

| 用途 | SF Symbol | Weight | Size |
|------|-----------|--------|------|
| メニューバーアイコン | `building.2.fill` | Regular | 16pt |
| Cash KPI | `yensign.circle` | Regular | 14pt |
| Runway KPI | `calendar.badge.clock` | Regular | 14pt |
| Reputation KPI | `star.fill` | Regular | 14pt |
| TeamHealth KPI | `heart.fill` | Regular | 14pt |
| TechDebt KPI | `bolt.fill` | Regular | 14pt |
| Inbox | `tray.fill` | Regular | 14pt |
| 設定 | `gearshape` | Regular | 16pt |
| 戻るボタン | `chevron.left` | Regular | 14pt |
| Crisis警告 | `exclamationmark.triangle.fill` | Regular | 14pt |
| Inbox満杯 | `tray.full.fill` | Regular | 14pt |
| プライバシーロック | `lock.fill` | Regular | 16pt |
| ローカル保存 | `internaldrive.fill` | Regular | 16pt |
| 選択済みチェック | `checkmark.circle.fill` | Regular | 20pt |

---

---

## 9. アセットトークン（curated アセット対応表）

> アセット取得完了日: 2026-02-27
> 詳細実装 handoff: `docs/24_design_asset_handoff_v01.md`

### 9.1 実装パターン（Swift参考）

```swift
// アセットトークンの実装パターン
enum TinyAsset {
    /// curated アセットを読み込む。失敗時は SF Symbol フォールバックを返す。
    static func icon(_ name: String, sfSymbol: String) -> Image {
        if let ns = NSImage(named: name) {
            return Image(ns: ns).renderingMode(.template)
        }
        // フォールバック
        print("[TinyAsset] fallback: \(name) -> \(sfSymbol)")
        return Image(systemName: sfSymbol)
    }
}
```

---

### 9.2 UI アイコンアセット

| トークン名 | ファイルパス（curated） | 表示サイズ | @1x ソース | @2x ソース | tint 可否 | SF Symbol（fallback） |
|-----------|----------------------|----------|-----------|-----------|---------|----------------------|
| `asset/icon/cash` | `assets/curated/ui/ui_cash_icon.png` | 16pt | `assets/raw/kenney/game-icons/PNG/Black/1x/medal1.png` | `…/2x/medal1.png` | ✅ template | `yensign.circle` |
| `asset/icon/reputation` | `assets/curated/ui/ui_reputation_icon.png` | 16pt | `assets/raw/kenney/game-icons/PNG/Black/1x/star.png` | `…/2x/star.png` | ✅ template | `star.fill` |
| `asset/icon/health` | `assets/curated/ui/ui_health_icon.png` | 16pt | `assets/raw/kenney/game-icons/PNG/Black/1x/plus.png` | `…/2x/plus.png` | ✅ template | `heart.fill` |
| `asset/icon/techdebt` | `assets/curated/ui/ui_techdebt_icon.png` | 16pt | `assets/raw/kenney/game-icons/PNG/Black/1x/gear.png` | `…/2x/gear.png` | ✅ template | `bolt.fill` |
| `asset/icon/runway` | N/A（curated なし） | 14pt | — | — | — | `calendar.badge.clock`（正式採用） |

**tint 方法:**
- `NSImage` を `isTemplate = true` に設定するか、SwiftUI で `.renderingMode(.template)` を使用する。
- 適用色は対応する KPI カラートークン（`kpi/cash`、`kpi/reputation` 等）を使う。
- Dark モード時はトークン色が自動で切り替わるため、アセット自体の Dark 版は不要。

---

### 9.3 カード UI テクスチャ

| トークン名 | ファイルパス | 用途 | 表示方法 | tint 可否 | 推奨 opacity |
|-----------|------------|------|--------|---------|------------|
| `asset/texture/card-bg` | `assets/curated/ui/ui_card_bg.png` | ChoiceButton 背景テクスチャ（オプション） | ストレッチ or タイル | ❌ original | 0.08〜0.12 |

**使用条件:** ChoiceButton にゲームらしさを加えたい場合のみ。テキスト可読性が下がる場合は非表示にすること。

---

### 9.4 オフィス装飾アセット（Phase 2）

| トークン名 | ファイルパス | 表示サイズ（目安） | tint 可否 | 表示条件 |
|-----------|------------|----------------|---------|---------|
| `asset/office/desk-1` | `assets/curated/office/office_desk_01.png` | 32×32pt | ❌ original | Day 1〜（常時） |
| `asset/office/desk-2` | `assets/curated/office/office_desk_02.png` | 32×32pt | ❌ original | 社員 2名以上 or CH2 解放 |
| `asset/office/monitor` | `assets/curated/office/office_monitor_01.png` | 32×32pt | ❌ original | Day 1〜（常時） |
| `asset/office/plant` | `assets/curated/office/office_plant_01.png` | 24×32pt | ❌ original | Day 10〜 or PRODUCT カード選択後 |
| `asset/office/server` | `assets/curated/office/office_server_01.png` | 24×40pt | ❌ original | AI カード選択後 or CH2 解放 |
| `asset/office/tilemap-oga` | `assets/curated/office/office_tilemap_oga_indoor.png` | タイル単位 8pt | ❌ original | Phase 3 床/壁合成用（v0.2以降） |

**レンダリングモード:** `.renderingMode(.original)` — ピクセルアートの配色を維持すること。
**スケーリング:** pixel-perfect 表示（`interpolation(.none)`）を使用し、拡大時のぼけを防ぐ。

---

### 9.5 キャラクターアセット（Phase 3 — v0.2 以降）

| トークン名 | ファイルパス | 表示サイズ（目安） | tint 可否 | v0.1 fallback |
|-----------|------------|----------------|---------|--------------|
| `asset/char/founder` | `assets/curated/characters/char_founder_01.png` | 24×32pt | ❌ original | `person.fill`（SF Symbol） |
| `asset/char/staff-dev` | `assets/curated/characters/char_staff_dev_01.png` | 24×32pt | ❌ original | `person.fill` |
| `asset/char/staff-pm` | `assets/curated/characters/char_staff_pm_01.png` | 24×32pt | ❌ original | `person.fill` |

> **注意:** 2dPig アトラスからの切り出し精度が不十分な場合は v0.1 では使用を省略し、SF Symbol で代替する。
> 切り出し品質を確認してから判断すること（`docs/23_asset_selection_notes.md` §3 参照）。

---

### 9.6 ライセンス出典マトリクス

| アセットグループ | ライセンス | 出典記録ファイル | クレジット要否 |
|--------------|----------|--------------|------------|
| Kenney game-icons（ui/ui_*.png） | CC0 1.0 Universal | `assets/licenses/kenney.txt` | 不要（CC0） |
| Kenney ui-pack（ui/ui_card_bg.png） | CC0 1.0 Universal | `assets/licenses/kenney.txt` | 不要（CC0） |
| 2dPig Pixel Office（office/*, characters/*） | CC0 1.0 Universal | `assets/licenses/2dpig.txt` | 不要（CC0） |
| OGA indoor-office-appliances（office/office_tilemap_oga_indoor.png） | CC0 1.0 Universal | `assets/licenses/opengameart.txt` | 不要（CC0）、Author: semtex99 |

---

*最終更新: 2026-02-27（アセットトークン追加）*
*次ステップ: Codex はこのファイルを参照して Swift の `DesignTokens.swift`（または Asset Catalog）を実装する。*
