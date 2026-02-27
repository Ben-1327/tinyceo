# 24 Design Asset Handoff — TinyCEO v0.1

> **対象:** Codex 実装担当
> **目的:** アセット確定版のコンポーネント→ファイル対応と受け入れチェックリストを1ファイルで完結させる
> **参照元:** `docs/21_design_spec_v01.md`、`docs/22_design_tokens.md`、`docs/23_asset_selection_notes.md`
> **作成日:** 2026-02-27

---

## 1. コンポーネント → アセット → ファイルパス → ライセンス 対応表

### 1.1 KPI セル（Home Popover の指標表示）

| コンポーネント | 表示要素 | 使用アセット | ファイルパス | レンダリングモード | 表示サイズ | ライセンス | fallback |
|-------------|---------|------------|------------|----------------|----------|----------|---------|
| Cash KPI | アイコン | `ui_cash_icon.png` | `assets/curated/ui/ui_cash_icon.png` | template（tint: `kpi/cash`） | 16pt | CC0 / kenney.txt | `yensign.circle` |
| Reputation KPI | アイコン | `ui_reputation_icon.png` | `assets/curated/ui/ui_reputation_icon.png` | template（tint: `kpi/reputation`） | 16pt | CC0 / kenney.txt | `star.fill` |
| TeamHealth KPI | アイコン | `ui_health_icon.png` | `assets/curated/ui/ui_health_icon.png` | template（tint: `kpi/health`） | 16pt | CC0 / kenney.txt | `heart.fill` |
| TechDebt KPI | アイコン | `ui_techdebt_icon.png` | `assets/curated/ui/ui_techdebt_icon.png` | template（tint: `kpi/techdebt`） | 16pt | CC0 / kenney.txt | `bolt.fill` |
| Runway KPI | アイコン | なし（SF Symbol 正式採用） | — | SF Symbol | 14pt | — | `calendar.badge.clock` |
| 全 KPI セル | 値テキスト | SF Pro Rounded | SF Pro（システム） | — | 17pt Semibold | — | — |
| 全 KPI セル | ラベルテキスト | SF Pro | SF Pro（システム） | — | 10pt Regular | — | — |

**実装注意:**
- curated アイコンは `NSBundle.main.image(forResource:)` またはアセットカタログに登録して参照する。
- KPIセルのアイコンは KPI の状態（normal/warning/danger）に関係なくアセット画像を使用する。
  状態変化は tint カラーの切り替えで表現する（アイコン画像自体は変えない）。
- Warning/Danger 時の tint カラー: `status/warning` / `status/danger`（KPI アクセント色を上書き）。

---

### 1.2 カードUI

| コンポーネント | 表示要素 | 使用アセット | ファイルパス | レンダリングモード | 表示サイズ | ライセンス | fallback |
|-------------|---------|------------|------------|----------------|----------|----------|---------|
| ChoiceButton | 背景テクスチャ（オプション） | `ui_card_bg.png` | `assets/curated/ui/ui_card_bg.png` | original（opacity 0.08〜0.12） | ボタン全面 | CC0 / kenney.txt | 背景色のみ（`bg/button/choice`） |
| CardRow（Inbox） | カテゴリバッジ | なし（カラー + テキスト） | — | — | 20pt height | — | — |
| カード詳細ヘッダー | カテゴリバッジ | なし（カラー + テキスト） | — | — | 20pt height | — | — |

**`ui_card_bg.png` の使用判断フロー:**
```
ChoiceButton にテクスチャを使う場合
  ↓
opacity: 0.10 でレンダリングし、テキスト可読性を確認
  ├─ 可読 → 採用
  └─ 不可読 → テクスチャ非表示（`bg/button/choice` 単色のみ）
```

---

### 1.3 オフィス装飾（Home Popover フッター — Phase 2）

**表示エリア:** Home Popover の Inbox 行の下、24pt 高さのオフィスビュー行として追加する。
**実装タイミング:** v0.1 実装時に余裕がある場合のみ。なければ省略可能。

| コンポーネント | 使用アセット | ファイルパス | レンダリングモード | 表示サイズ | ライセンス | 表示条件 | fallback |
|-------------|------------|------------|----------------|----------|----------|---------|---------|
| 基本デスク | `office_desk_01.png` | `assets/curated/office/office_desk_01.png` | original | 32×32pt | CC0 / 2dpig.txt | 常時 | 非表示 |
| 追加デスク | `office_desk_02.png` | `assets/curated/office/office_desk_02.png` | original | 32×32pt | CC0 / 2dpig.txt | 社員 2名以上 or CH2 | 非表示 |
| PCモニター | `office_monitor_01.png` | `assets/curated/office/office_monitor_01.png` | original | 32×32pt | CC0 / 2dpig.txt | 常時 | 非表示 |
| 観葉植物 | `office_plant_01.png` | `assets/curated/office/office_plant_01.png` | original | 24×32pt | CC0 / 2dpig.txt | Day 10〜 or PRODUCT カード後 | 非表示 |
| サーバーラック | `office_server_01.png` | `assets/curated/office/office_server_01.png` | original | 24×40pt | CC0 / 2dpig.txt | AI カード後 or CH2 解放 | 非表示 |
| 床タイル（将来） | `office_tilemap_oga_indoor.png` | `assets/curated/office/office_tilemap_oga_indoor.png` | original | 8pt/タイル | CC0 / opengameart.txt | v0.2 以降 | 非表示 |

**pixel-perfect 表示:**
```swift
// SwiftUI での pixel-perfect 表示
Image("office_desk_01")
    .interpolation(.none)
    .resizable()
    .frame(width: 32, height: 32)
```

---

### 1.4 キャラクター（Phase 3 — v0.2 以降）

> v0.1 では実装不要。以下は将来実装の参照用。

| キャラクター | ファイルパス | 表示サイズ | ライセンス | 表示条件 | fallback |
|------------|------------|----------|----------|---------|---------|
| Founder | `assets/curated/characters/char_founder_01.png` | 24×32pt | CC0 / 2dpig.txt | 常時 | `person.fill` |
| DEVスタッフ | `assets/curated/characters/char_staff_dev_01.png` | 24×32pt | CC0 / 2dpig.txt | DEV職社員あり | `person.fill` |
| PMスタッフ | `assets/curated/characters/char_staff_pm_01.png` | 24×32pt | CC0 / 2dpig.txt | PM職社員あり | `person.fill` |

> **切り出し品質確認:** 2dPig アトラスからの切り出しは目視で確認すること。
> 背景混入・余白過剰がある場合は v0.1 での使用を見送り、SF Symbol（`person.fill`）で代替する。

---

### 1.5 SF Symbols（fallback / 正式採用）

curated アセットが存在しない、または読込失敗した場合の代替。
Runway は curated なし → SF Symbol を正式採用。

| 用途 | SF Symbol | Weight | Size | 使用箇所 |
|------|-----------|--------|------|---------|
| Cash KPI fallback | `yensign.circle` | Regular | 14pt | KPI セル |
| Runway KPI（正式） | `calendar.badge.clock` | Regular | 14pt | KPI セル |
| Reputation KPI fallback | `star.fill` | Regular | 14pt | KPI セル |
| TeamHealth KPI fallback | `heart.fill` | Regular | 14pt | KPI セル |
| TechDebt KPI fallback | `bolt.fill` | Regular | 14pt | KPI セル |
| メニューバーアイコン | `building.2.fill` | Regular | 16pt | StatusItem |
| Inbox | `tray.fill` | Regular | 14pt | Home Popover |
| Inbox 満杯 | `tray.full.fill` | Regular | 14pt | Home Popover |
| 設定 | `gearshape` | Regular | 16pt | Header |
| 戻るボタン | `chevron.left` | Regular | 14pt | Navigation |
| Crisis 警告 | `exclamationmark.triangle.fill` | Regular | 14pt | Crisis Banner |
| プライバシーロック | `lock.fill` | Regular | 16pt | オンボーディング |
| ローカル保存 | `internaldrive.fill` | Regular | 16pt | オンボーディング |
| 選択済みチェック | `checkmark.circle.fill` | Regular | 20pt | 選択結果 |
| スタッフ fallback | `person.fill` | Regular | 16pt | キャラクター |

---

## 2. fallback 判断ロジック（実装仕様）

```swift
// 推奨実装パターン
struct TinyAsset {
    /// KPI アイコン: curated アセット優先、失敗時 SF Symbol
    static func kpiIcon(for kpi: KPIType) -> some View {
        Group {
            if let image = NSImage(named: kpi.assetName) {
                Image(nsImage: image)
                    .renderingMode(.template)
                    .resizable()
                    .frame(width: 16, height: 16)
            } else {
                Image(systemName: kpi.sfSymbol)
                    .frame(width: 16, height: 16)
                    .onAppear {
                        print("[TinyAsset] fallback: \(kpi.assetName) -> \(kpi.sfSymbol)")
                    }
            }
        }
    }

    /// オフィス装飾: アセットあれば表示、なければ非表示（エラーではない）
    static func officeSprite(named name: String, size: CGSize) -> some View {
        Group {
            if let image = NSImage(named: name) {
                Image(nsImage: image)
                    .interpolation(.none)
                    .resizable()
                    .frame(width: size.width, height: size.height)
            }
            // fallback = 非表示（Empty View）
        }
    }
}
```

**KPIType enum の想定:**
```swift
enum KPIType {
    case cash, runway, reputation, health, techDebt
    var assetName: String {
        switch self {
        case .cash:       return "ui_cash_icon"
        case .runway:     return ""              // curated なし → 常に fallback
        case .reputation: return "ui_reputation_icon"
        case .health:     return "ui_health_icon"
        case .techDebt:   return "ui_techdebt_icon"
        }
    }
    var sfSymbol: String {
        switch self {
        case .cash:       return "yensign.circle"
        case .runway:     return "calendar.badge.clock"
        case .reputation: return "star.fill"
        case .health:     return "heart.fill"
        case .techDebt:   return "bolt.fill"
        }
    }
}
```

---

## 3. ライセンス出典一覧

| アセット | ライセンス | 出典 URL | 記録ファイル | 取得日 |
|--------|----------|--------|------------|------|
| Kenney game-icons (medal1, star, plus, gear) | CC0 1.0 Universal | https://kenney.nl/assets/game-icons | `assets/licenses/kenney.txt` | 2026-02-27 |
| Kenney UI Pack (button_rectangle_depth_flat) | CC0 1.0 Universal | https://kenney.nl/assets/ui-pack | `assets/licenses/kenney.txt` | 2026-02-27 |
| 2dPig Pixel Office Asset Pack（office/*, characters/*） | CC0 1.0 Universal | https://2dpig.itch.io/pixel-office | `assets/licenses/2dpig.txt` | 2026-02-27 |
| OGA indoor-office-appliances（office_tilemap_oga_indoor.png） | CC0 1.0 Universal | https://opengameart.org/content/indoor-office-appliances | `assets/licenses/opengameart.txt` | 2026-02-27 |

**CC0 の意味:**
クレジット表記不要、商用利用可、改変可。ただし出典追跡のためライセンスファイルは維持する。

---

## 4. 受け入れチェックリスト

### 4.1 可読性チェック

- [ ] KPI 値が 2 秒以内に読み取れる（全 5 指標が一画面に収まる）
- [ ] Crisis Banner が表示された場合、危機の種類がテキストのみで即読できる
- [ ] カード選択肢（A/B/C）の効果表示（+/-）が色と数値で即識別できる
- [ ] Inbox の件数バッジが 300pt 最小幅でも視認できる（最小 8pt diameter 維持）
- [ ] ポップオーバーを 300pt 幅に縮小した場合、KPI セルのテキストが切れない
- [ ] Dark モードで全テキストのコントラスト比が WCAG AA 基準（4.5:1）以上である

### 4.2 アセット統合チェック

- [ ] curated UI アイコン 4点（cash/reputation/health/techdebt）が KPI セルに表示される
- [ ] アイコンの tint がトークン色（normal/warning/danger）で正しく切り替わる
- [ ] Runway KPI のみ SF Symbol `calendar.badge.clock` が表示される（curated アセット不使用）
- [ ] Dark モードでアイコンの tint が `text/primary` ダーク版に切り替わる
- [ ] アセット読込失敗時にコンソールに `[TinyAsset] fallback:` が出力され、SF Symbol が代替表示される
- [ ] オフィス装飾スプライト（Phase 2）を表示した場合、pixel-perfect（`.interpolation(.none)`）で描画される
- [ ] `ui_card_bg.png` を ChoiceButton に使う場合、テキストのコントラストが確保されている

### 4.3 Low-interruption UX チェック

- [ ] カード 1 件の処理（Inbox 開く → カード選択 → 結果確認 → ホーム戻る）が 60 秒以内に完了できる
- [ ] ポップオーバーを 10 分間開いていても新規通知が 2 件以上発生しない（Crisis 以外）
- [ ] Crisis Banner が表示される場合、テキストは 30 文字以内に収まる
- [ ] アニメーション（Crisis Banner 出現・KPI 更新）が 3 秒以上続かない

### 4.4 プライバシー UX チェック

- [ ] オンボーディング画面にプライバシー確定文言が 2 行分（収集範囲・送信しない）表示される
- [ ] 収集するもの・しないものがオンボーディングに明記されている
- [ ] 設定画面に「収集データを確認する」リンクが存在する
- [ ] アプリ UI のどこにも「作業内容を読む・監視する」と誤解させる演出がない
- [ ] メニューバーアイコンが仕事中にユーザーの視線を引きすぎない（pulse アニメは Danger 時のみ）

### 4.5 整合性チェック（docs/14 / docs/21 との矛盾なし）

- [ ] Runway 計算: `estimatedMonthlyNetBurn = max(0, (dailyBurn - dailyIncome) * 30)` で実装されている
- [ ] ポップオーバー幅: default 360pt / min 300pt（他の値を使っていない）
- [ ] Inbox FULL バナー: `inbox == 3` かつ `hasMissedCardGenerationDueToFullInbox == true` の場合のみ
- [ ] カード rarity バッジ: v0.1 では非表示（`Q5` 決定）
- [ ] 作業連携の ON/OFF は設定 1 つのみ（独立した「スタンドアロンモード」は存在しない）（`Q4` 決定）
- [ ] v0.1 カードは 3 択固定（4 択・ドラフト UI は存在しない）

---

## 5. 未確定事項（Codex への質問）

以下は設計上の疑問点。実装前に確認または判断を求める。

| # | 質問 | 設計上の仮定 | 優先度 |
|---|------|-----------|--------|
| UQ1 | アセットを XCAssets ではなく `NSBundle.main.image(forResource:)` で直接参照してよいか？ | 直接参照でよい（Asset Catalog 登録は任意） | 高 |
| UQ2 | オフィス装飾エリアを Home Popover に追加する場合、Inbox 行の下に新セクションを追加するか、Inbox 行と同一行に並列配置するか？ | Inbox 行の下に独立した 32pt 高さの装飾行を追加 | 中 |
| UQ3 | `ui_card_bg.png` の ChoiceButton テクスチャ使用はデフォルト ON か OFF か？ | デフォルト OFF（オプション機能として扱う） | 低 |

---

*作成: 2026-02-27（Claude Code / デザイン担当）*
*参照先: `docs/21_design_spec_v01.md`、`docs/22_design_tokens.md`、`docs/23_asset_selection_notes.md`*
