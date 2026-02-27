# 21 Design Spec v0.1 — TinyCEO UI/UX

> ステータス: **確定版**（アセット取得済み・実装着手可能）
> 担当: Claude Code（デザイン）
> 対象バージョン: v0.1
> 実装参照: `docs/22_design_tokens.md`、`docs/24_design_asset_handoff_v01.md`
> 最終更新: 2026-02-27（アセット反映・Q1〜Q5確定反映）

---

## 0. 前提の理解と制約まとめ

| 項目 | 内容 |
|------|------|
| プラットフォーム | macOS 14+、Swift 6 + SwiftUI + AppKit |
| UIモデル | NSStatusItem + NSPopover（メニューバー常駐） |
| 操作頻度 | 約2時間に1回、1〜2分で完結 |
| カード択 | v0.1は3択固定 |
| 通知 | カード到着時・重大Crisisのみ |
| 収集範囲 | アプリ種別カテゴリの分数のみ（内容は収集しない） |
| 変更禁止 | data/*.json、ロジック、tick処理順 |

### KPI値域（balance.jsonより導出）
| KPI | 範囲 | Warning閾値 | Danger閾値 |
|-----|------|-------------|-----------|
| Cash（¥） | 0〜∞ | — | —（Runwayで判断） |
| Runway（ヶ月） | 0〜∞ | < 3ヶ月 | < 1ヶ月 |
| Reputation | 0〜100 | < 15 | < 5 |
| TeamHealth | 0〜100 | < 50 | < 30 |
| TechDebt | 0〜100 | > 50 | > 75 |

---

## 1. 実装確定事項（Codex同期済み）

| # | 項目 | 決定内容 | 状態 |
|---|------|----------|------|
| Q1 | Runway計算式（monthly burn） | `estimatedMonthlyNetBurn = max(0, (dailyBurn - dailyIncome) * 30)`、Runway=`cash / estimatedMonthlyNetBurn`（0なら∞） | 確定 |
| Q2 | ポップオーバー幅 | `default=360pt` / `min=300pt`（将来可変に備え2値で保持） | 確定 |
| Q3 | Inbox「FULL」表示条件 | `inbox==max(3)` かつ `満杯で生成タイミング超過フラグ=true` の時のみ表示 | 確定 |
| Q4 | 作業連携OFF時の扱い | v0.1は「作業連携 ON/OFF」設定のみ。独立したスタンドアロンモードは導入しない | 確定 |
| Q5 | カードrarityバッジ | v0.1では非表示（v0.2検討） | 確定 |

---

## 2. デザイン方向性：2案

### 案A — Terminal Dashboard（ダーク単色）

> 「開発者のホームグラウンド」をメタファーにした、ツール的UIデザイン。

**ビジュアル特徴**
- 背景: ダーク (#1A1A1E)、テキスト: 明るいモノクロ系
- KPI: 緑/アンバー/レッドのステータス色
- アイコン: SF Symbols のみ（アセット依存なし）
- 数値: SF Mono（タブ幅統一）

**長所**
- 実装コスト最低（システムフォント + SF Symbols のみ）
- コントラスト比が高く読みやすい
- ピクセルアートアセット未取得でも完成する

**短所**
- 「経営シム」としての遊び感が薄い
- macOS標準の外観（ライト/ダーク追随）と相性が悪い
- 競合するデバッガUIとの区別がつきにくい

---

### 案B — Pixel Office（ウォーム + ピクセルアート）

> 「在宅オフィスが少しずつ育っていく」体験を、暖色とドット絵で表現するゲームUI。

**ビジュアル特徴**
- 背景: クリーム (#FAF8F5 / ダーク時 #1C1A18)、macOSシステム外観追随
- KPI: カラーコード付きセルカード（Reputation=インディゴ、Health=グリーン、Debt=オレンジ）
- アイコン: SF Symbols ベース + 小さなピクセルスプライト（16×16〜32×32）
- ポップオーバー全体がゲームの「本社オフィス」イメージを持つ

**長所**
- 唯一性が高い（競合する他ツールと差別化できる）
- CC0ピクセルアセット（Kenney / 2dPig）と自然に統合できる
- 「会社が成長する」喜びを視覚的に伝えやすい

**短所**
- ピクセルアートアセット取得・選定が必要（取得手順は本書末尾に記載）
- 実装コストがやや高い（アセット管理、@1x/@2xスプライト対応）
- ライト/ダーク両対応のスプライト調整が必要

---

## 3. 推奨案：案B（Pixel Office）— 採用理由

**採用理由:**
1. TinyCEOの差別化軸は「仕事しながら会社が育つ」体験。その「育つ」感を視覚的に担保できるのは案Bだけ。
2. ピクセルアートスプライトは16×16〜32×32で十分機能する。プロジェクトの小ウィンドウ制約でも可読性は落ちない。
3. macOSのシステム外観（ライト/ダーク）に追随するベース設計にするため、クリームとダークウォームチャコールの2パレットを定義し、完全準拠させる。
4. アセット未取得でも「SF Symbols + KPIセルカード」だけで動作する段階的実装が可能。スプライトはv0.1で後付けできる。

**v0.1の実装優先順（アセット取得済みに基づき更新）:**
```
Phase 1: curated UIアイコン（assets/curated/ui/）を使用。
         アセット読込失敗時のみ SF Symbols にフォールバック。
Phase 2: オフィス装飾スプライト（assets/curated/office/）を Home Popover のフッターに追加。
Phase 3: スタッフキャラクター表示（assets/curated/characters/）
         ＝ v0.1 スコープ外、v0.2以降で導入。
```

**フォールバック切替条件（Codex 実装向け）:**
- `NSImage(named:)` が `nil` を返した場合 → 対応 SF Symbol を使用する。
- curated アイコンは `.renderingMode(.template)` で読み込み、`foregroundColor` でトークン色を適用する。
- Phase 2 の office スプライトは `.renderingMode(.original)` で表示（着色しない）。
- フォールバック発生時はコンソールに `[TinyAsset] fallback: <token_name>` を出力する（デバッグ用）。

---

## 4. 画面フロー

```
[初回起動]
    │
    ▼
┌─────────────────────────────┐
│ オンボーディング             │ ← 1画面のみ、ウィザードなし
│ - プライバシー説明           │
│ - 作業連携 ON/OFF 選択       │
└─────────────────────────────┘
    │
    ▼
┌─────────────────────────────┐
│ カード詳細：CARD_000_VISION  │ ← 初回カード（戦略選択）
│ [3択]                        │   = 実質的な「2枚目のオンボーディング」
└─────────────────────────────┘
    │ 選択
    ▼
┌─────────────────────────────┐  ←─────────────────────────────────┐
│ Home Popover（通常状態）     │                                    │
│ - KPIバー（5指標）           │  ←  メニューバーアイコン クリック  │
│ - プロジェクト進捗           │                                    │
│ - Inbox件数                  │────────────────────────────────────┘
└─────────────────────────────┘
    │  Inboxを開く                    │  設定を開く
    ▼                                 ▼
┌───────────────────────┐    ┌──────────────────────┐
│ Inbox（カード一覧）    │    │ 設定                  │
│ - 最大3件              │    │ - モード切替          │
│ - カテゴリ・タイトル   │    │ - 通知 ON/OFF         │
└───────────────────────┘    │ - プライバシー        │
    │  カードを選択              └──────────────────────┘
    ▼
┌───────────────────────┐
│ カード詳細            │
│ - タイトル・背景      │
│ - 影響する指標        │
│ - 3択ボタン           │
└───────────────────────┘
    │  選択
    ▼
┌───────────────────────┐
│ 選択結果              │
│ - 効果の表示（+/-）   │
│ - 次カード到着までの時間│
│ - [ホームに戻る]      │
└───────────────────────┘
    │  戻る
    ▼
 Home Popover（上記に戻る）

[Crisis発生時: Home Popoverに重ねて危機バナーを表示]
[Inbox満杯時: Inboxエリアに FULL バッジを表示]
[倒産時: カード詳細として ENDGAME カードを表示]
```

---

## 5. 主要画面モック定義

> ポップオーバー幅: 標準 360pt（最小 300pt）
> 最小高さ: 240pt / 最大高さ: 480pt（コンテンツに応じて可変）
> フォント: SF Pro（システムフォント）、数値: SF Pro Rounded

### 5.1 メニューバーアイコン

| 状態 | アイコン | バッジ | アニメーション |
|------|---------|--------|---------------|
| Normal | `building.2.fill` | なし | なし |
| Warning（指標悪化） | `building.2.fill` | 8pt amber ●（右上） | なし |
| Danger（Crisis/倒産危険） | `building.2.fill` | 8pt red ●（右上） | pulse（1.5s loop） |
| Cards Pending（未読Inbox） | `building.2.fill` | 8pt blue ●（右上） | なし |
| 複合（Crisis + Cards） | `building.2.fill` | red ● 優先 | pulse |

**実装注意:**
- アイコンはテンプレートイメージ（monocolor）→ NSStatusItem.button.image に設定
- バッジは別レイヤー（NSStatusItem.button の上に overlayView）で実装
- pulse は CALayer の opacity アニメーション（0.6→1.0→0.6、1.5s easeinout）
- 危機Danger中は通常Warningより赤ドットを優先表示

---

### 5.2 Home Popover — 通常状態

```
┌──────────────────────────────────────────────┐
│  🏢 TinyCEO            Day 42  ⚙             │  ← Header 44pt
├──────────────────────────────────────────────┤
│                                              │
│  ┌──────────┐ ┌──────────┐ ┌──────────┐    │
│  │  CASH    │ │ RUNWAY   │ │   REP    │    │  ← KPI上段 3セル
│  │  ¥30万   │ │  18ヶ月  │ │   32    │    │
│  └──────────┘ └──────────┘ └──────────┘    │
│                                              │
│  ┌──────────┐ ┌──────────┐                 │
│  │  HEALTH  │ │ TECHDEBT │                 │  ← KPI下段 2セル
│  │   78     │ │   15     │                 │
│  └──────────┘ └──────────┘                 │
│                                              │
├──────────────────────────────────────────────┤
│  プロジェクト                                │  ← Section header
│  ─────────────────────────────────────────  │
│  MVPリリース準備       ████████░░  82%      │
│  採用LP制作            ██░░░░░░░░  22%      │
│                                              │
├──────────────────────────────────────────────┤
│  📬 Inbox  2件                [カードを見る] │  ← Inbox row
└──────────────────────────────────────────────┘
```

**レイアウト仕様:**
- Header height: 44pt
- Header padding: 水平 16pt
- KPIセクション padding: 16pt（上下）/ 16pt（左右）
- KPI gap: 8pt
- KPIセル width: (360 - 32 - 16) / 3 ≈ 104pt（上段）/ (360 - 32 - 8) / 2 ≈ 160pt（下段）
- KPIセル height: 56pt
- Section divider: 1pt, color.separator
- Project section padding: 12pt（上下）/ 16pt（左右）
- Progress bar height: 6pt（track）、radius: 3pt
- Inbox row height: 44pt

---

### 5.3 Home Popover — 危機状態（Cash Danger）

```
┌──────────────────────────────────────────────┐
│  🏢 TinyCEO            Day 42  ⚙             │  ← Header（変化なし）
├──────────────────────────────────────────────┤
│  ⚠️ キャッシュが危険水準です。対応カードを確認してください。    │  ← Crisis Banner
├──────────────────────────────────────────────┤
│                                              │
│  ┌──────────┐ ┌──────────┐ ┌──────────┐    │
│  │  CASH    │ │ RUNWAY   │ │   REP    │    │
│  │  ¥5万    │ │  < 1ヶ月 │ │   32    │    │  ← CASH/RUNWAY セルが danger色
│  │  🔴 危険 │ │  🔴 危険 │ │         │    │
│  └──────────┘ └──────────┘ └──────────┘    │
│  ...（以下同じ）                             │
└──────────────────────────────────────────────┘
```

**Crisis Banner仕様:**
- 背景: `color.bg.crisis`（danger色の10% alpha）
- 左に ⚠️ アイコン（SF Symbol: `exclamationmark.triangle.fill`、danger色）
- テキスト: 13pt、danger色
- 高さ: 36〜40pt（テキスト量に応じてmin）
- 種類別メッセージ（後述の状態設計を参照）

---

### 5.4 Inbox（カード一覧）

```
┌──────────────────────────────────────────────┐
│  [←]  Inbox                                  │  ← Navigation header 44pt
├──────────────────────────────────────────────┤
│                                              │
│  ┌────────────────────────────────────────┐ │
│  │  [SALES]  最初の案件が来た：どれを受ける？ │ │  ← Card row
│  │           COMMON  •  影響: 💰 ★        │ │
│  └────────────────────────────────────────┘ │
│                                              │
│  ┌────────────────────────────────────────┐ │
│  │  [HIRING]  最初のエンジニアを採用する？  │ │
│  │            COMMON  •  影響: 💰 ❤️       │ │
│  └────────────────────────────────────────┘ │
│                                              │
│  ─── 次のカードまで: 約1時間45分 ───       │  ← Countdown footer
│                                              │
└──────────────────────────────────────────────┘
```

**Inbox満杯時:**
```
│  ⛔ INBOX FULL  • カード未処理による悪化中  │  ← 赤バナー（Headerの直下）
│  HEALTH -3  TECHDEBT +2  REP -1 / cycle     │
```

**カード行 (CardRow) 仕様:**
- 高さ: min 64pt
- 水平 padding: 12pt
- カテゴリバッジ: category color 背景、10pt white文字、radius: 4pt
- タイトル: 13pt Medium
- サブライン: rarity + 影響指標アイコン群、11pt secondary

---

### 5.5 カード詳細

```
┌──────────────────────────────────────────────┐
│  [←]                              Day 42     │  ← Header 44pt
├──────────────────────────────────────────────┤
│                                              │
│  [SALES]  COMMON                            │  ← Category badge + Rarity
│                                              │
│  最初の案件が来た：どれを受ける？            │  ← Title 17pt Semibold
│                                              │
│  スタートアップの支援案件か、大企業の         │  ← Flavor text（存在する場合）13pt
│  安定受託か。最初の選択が方向性を決める。    │
│                                              │
│  影響する指標：💰 Cash  ★ Reputation        │  ← 影響指標（タップ不可、情報のみ）
│                                              │
│  ─────────────────────────────────────────  │
│                                              │
│  ┌───────────────────────────────────────┐  │
│  │  A  長期案件で安定収入               │  │  ← Choice Button (default)
│  │     受託 安定収入                    │  │
│  │     💰 +¥50万/月   ⚡ TechDebt +2   │  │  ← Effect tags
│  └───────────────────────────────────────┘  │
│                                              │
│  ┌───────────────────────────────────────┐  │
│  │  B  スタートアップ支援（実績重視）   │  │
│  │     新興  評判向上                   │  │
│  │     ★ Reputation +3  💰 -¥20万      │  │
│  └───────────────────────────────────────┘  │
│                                              │
│  ┌───────────────────────────────────────┐  │
│  │  C  今は断る（内製に集中）           │  │
│  │     保守  内製優先                   │  │
│  │     変化なし（次サイクルで再出現）   │  │
│  └───────────────────────────────────────┘  │
│                                              │
└──────────────────────────────────────────────┘
```

**Choice Button 仕様:**
- 最小高さ: 56pt（アクセシビリティ確保）
- 水平 padding: 12pt / 垂直 padding: 10pt
- 左端にラベル "A" "B" "C"（16pt Medium）
- タイトル: 13pt Medium
- サブテキスト（タグ系）: 11pt Secondary
- Effect tag 行: effect icon + 値、色は指標ごとに固定
  - +値: color.positive（#30D158）
  - -値: color.negative（#FF453A）

---

### 5.6 選択結果

```
┌──────────────────────────────────────────────┐
│  [←]  完了                                   │  ← Header 44pt
├──────────────────────────────────────────────┤
│                                              │
│  ✓  「長期案件で安定収入」を選択しました     │  ← 選択済み表示（14pt Medium）
│                                              │
│  ─────────────────────────────────────────  │
│                                              │
│  💰 Cash          +¥500,000                 │  ← 効果一覧（1行1効果）
│  ⚡ Tech Debt     +2                         │
│                                              │
│  ─────────────────────────────────────────  │
│                                              │
│  次のカード到着まで: 約1時間45分             │  ← 次回予告（countdown）
│                                              │
│         ┌────────────────────────┐          │
│         │   ホームに戻る         │          │  ← Primary Button
│         └────────────────────────┘          │
│                                              │
└──────────────────────────────────────────────┘
```

---

### 5.7 オンボーディング

```
┌──────────────────────────────────────────────┐
│                                              │
│                  [🏢]                        │  ← SF Symbol: building.2.fill (36pt)
│                                              │
│           TinyCEO へようこそ                 │  ← 20pt Semibold
│                                              │
│  ─────────────────────────────────────────  │
│                                              │
│  作業連携について                            │  ← 15pt Semibold
│                                              │
│  アプリの種別（DEV / COMMS / BREAK など）    │  ← 13pt body
│  を10分ごとにカテゴリとして集計します。      │
│                                              │
│  🔒 作業の内容は記録しません。              │  ← Privacy highlight
│     ファイル名・テキスト・URLの中身は        │
│     一切取得しません。                       │
│                                              │
│  💾 データはこのMacにのみ保存されます。     │
│     外部に送信されません。                   │
│                                              │
│  ─────────────────────────────────────────  │
│                                              │
│  ┌────────────────────────────────────────┐ │
│  │   作業連携をONにして始める（推奨）     │ │  ← Primary Button
│  └────────────────────────────────────────┘ │
│                                              │
│       作業連携をOFFで始める                 │  ← Text button (secondary)
│                                              │
└──────────────────────────────────────────────┘
```

**重要:** プライバシー文言は `docs/12_privacy_and_telemetry.md` の確定文をそのまま使う。独自に文言を書き換えない。

---

### 5.8 設定

```
┌──────────────────────────────────────────────┐
│  [←]  設定                                   │  ← Header 44pt
├──────────────────────────────────────────────┤
│                                              │
│  作業連携                                    │  ← Section header 11pt uppercase
│  ─────────────────────────────────────────  │
│  作業連携     ──────────────────  ● ON      │  ← Toggle
│                                              │
│  通知                                        │
│  ─────────────────────────────────────────  │
│  カード到着   ──────────────────  ● ON      │  ← Toggle
│  重大Crisis   ──────────────────  ● ON      │
│                                              │
│  プライバシー                                │
│  ─────────────────────────────────────────  │
│  [収集データを確認する ↗]                    │  ← Link to local log viewer
│                                              │
│  ─────────────────────────────────────────  │
│                                              │
│  [データをリセット（最初からやり直す）]      │  ← Destructive action（テキストボタン、danger色）
│                                              │
└──────────────────────────────────────────────┘
```

---

## 6. 状態設計

### 6.1 通常運転
- Crisis Banner: なし
- メニューバー: normal
- KPIセル: すべて neutral/primary 色

### 6.2 資金繰り悪化（Cash Danger）
- Crisis Banner: 「キャッシュが危険水準です。対応カードを確認してください。」
- メニューバー: danger（赤点 pulse）
- Cash KPIセル + Runway KPIセル: danger スタイル

### 6.3 TechDebt悪化（TechDebt > 75）
- Crisis Banner: 「技術的負債が限界に近づいています。開発速度が低下します。」
- メニューバー: warning（アンバー点）
- TechDebt KPIセル: danger スタイル

### 6.4 TeamHealth悪化（TeamHealth < 30）
- Crisis Banner: 「チームの健康度が低下しています。離職リスクがあります。」
- メニューバー: danger（赤点 pulse）
- TeamHealth KPIセル: danger スタイル

### 6.5 Crisis発生中（Crisisカード到着）
- 通知（macOS notification）: タイトル「TinyCEO」+ 本文「緊急対応が必要です」
- Inbox に Crisis カードが追加される
- メニューバー: danger（赤点 pulse）
- 通常のCrisis bannerに加えて、カード行に `[緊急]` ラベルを追加

### 6.6 Inbox満杯（3件到達 + 新規生成タイミング）
- Crisis Banner: 「Inboxが満杯です。処理が遅れると指標が悪化します。」
- Inboxカード一覧のヘッダーに赤バッジ「FULL」
- ペナルティ明記: TeamHealth -3 / TechDebt +2 / Reputation -1 ／ 次サイクル

### 6.7 複合危機（複数のDanger同時）
- Crisis Bannerは「最も深刻な1件」のみ表示（CASH > HEALTH > DEBT の優先順）
- ホームのKPIは全て各自のステータス色で表示（累積可視化）

---

## 7. コンポーネント仕様

### 7.1 KPI Cell

| 属性 | 通常 | Warning | Danger |
|------|------|---------|--------|
| 背景 | `color.bg.cell` | `color.bg.warning` | `color.bg.danger` |
| ボーダー | なし | `color.border.warning` 1pt | `color.border.danger` 1pt |
| ラベル色 | `color.text.secondary` | `color.status.warning` | `color.status.danger` |
| 値色 | `color.text.primary` | `color.status.warning` | `color.status.danger` |
| Radius | 8pt | 8pt | 8pt |
| Padding | 8pt水平 / 10pt垂直 | 同左 | 同左 |

**KPI別カラーアクセント・アイコン（通常時）:**

| KPI | 値の色トークン | 主アイコン（curated アセット） | 主アイコンのパス | SF Symbol（fallback） |
|-----|-------------|------------------------------|----------------|----------------------|
| Cash | `text/primary` | `ui_cash_icon.png` | `assets/curated/ui/ui_cash_icon.png` | `yensign.circle` |
| Runway | `text/primary` | なし（SF Symbol のみ） | — | `calendar.badge.clock` |
| Reputation | `kpi/reputation` | `ui_reputation_icon.png` | `assets/curated/ui/ui_reputation_icon.png` | `star.fill` |
| TeamHealth | `kpi/health` | `ui_health_icon.png` | `assets/curated/ui/ui_health_icon.png` | `heart.fill` |
| TechDebt | `kpi/techdebt` | `ui_techdebt_icon.png` | `assets/curated/ui/ui_techdebt_icon.png` | `bolt.fill` |

アイコン表示サイズ: **16pt@1x / 32pt@2x**（Kenney game-icons は 1x/2x 両方あり）
レンダリングモード: `.renderingMode(.template)` + トークン色で着色（tintable）
Runway のみ curated アセット未提供のため SF Symbol を正式採用。

### 7.2 Progress Bar

| 属性 | 値 |
|------|-----|
| Height（track） | 6pt |
| Height（fill） | 6pt |
| Radius | 3pt |
| Track color | `color.bg.progressTrack` |
| Fill color（< 80%） | `color.accent.primary`（#5856D6） |
| Fill color（≥ 80%） | `color.accent.health`（#30D158） |
| Fill color（遅延中） | `color.status.warning` |

### 7.3 Risk Badge

| バッジ種別 | 背景色 | テキスト色 | 文言 |
|----------|--------|-----------|------|
| Warning | warning 15% alpha | `color.status.warning` | 指標名 |
| Danger | danger 12% alpha | `color.status.danger` | 指標名 |
| Crisis | danger solid | white | `緊急` |
| Full | danger solid | white | `FULL` |

- Font: 10pt Semibold
- Padding: 4pt × 8pt
- Radius: 4pt

### 7.4 Choice Button（カード択）

```
[Default] ─────────────────────────────────────────
背景: color.bg.cell
ボーダー: 1pt color.border.default
Radius: 8pt
Shadow: なし

[Hover] ─────────────────────────────────────────
背景: color.bg.hover
ボーダー: 1pt color.border.focus
Shadow: shadow.hover

[Pressed] ─────────────────────────────────────────
背景: color.bg.pressed（やや濃い）
Scale: 0.98（spring animation）

[Disabled] ─────────────────────────────────────────
不透明度: 0.4（選択済みの他の選択肢）
```

**内部レイアウト:**
```
┌─────────────────────────────────────────────────┐
│  A   タイトルテキスト                            │  ← A/B/C: 16pt Medium（固定幅24pt）
│      タグ1テキスト                               │  ← subtext: 11pt secondary
│      💰 +¥500K   ⚡ +2                          │  ← effect tags: 11pt, +は green, -は red
└─────────────────────────────────────────────────┘
```

### 7.5 Result Toast（通知トースト）

通知はmacOSネイティブ通知（UNUserNotificationCenter）を使用。
ゲーム内結果表示はポップオーバー内のResult画面（5.6参照）で行う。
**インアプリトーストは使わない**（Low-interruption原則）。

例外: カード選択直後に一時的にポップオーバーが閉じている場合のみ、次回オープン時にResult画面を表示する。

---

## 8. モーション設計

| 遷移 | 種別 | 時間 | イージング |
|------|------|------|----------|
| 画面遷移（push/pop） | slide | 200ms | easeInOut |
| Crisis Banner 表示 | fade + slideDown | 250ms | spring |
| KPI値更新 | countUp number animation | 400ms | easeOut |
| Choice Button hover | scale + shadow | 150ms | easeOut |
| Choice Button press | scale down | 80ms | linear |
| メニューバー danger pulse | opacity oscillation | 1500ms | easeInOut loop |
| Inbox 件数バッジ変化 | pop scale | 200ms | spring(0.8, 0.6) |

**禁止アニメーション:**
- 連続ループするキャラクターアニメーション（仕事への干渉）
- 3秒以上の演出（操作完結の阻害）
- 勝手に動く要素（ユーザーの視線を奪う）

---

## 9. コピー設計

### 9.1 文言の原則
- 断定・短文（「〜です。」で終わる）
- 主語は「あなた」か省略、「ゲーム」と言わない
- 効果は「何が増える / 減る」を即読できるように

### 9.2 状態別 Crisis Banner 文言（確定版）

| 状態 | 文言 |
|------|------|
| Cash Danger | 「キャッシュが危険水準です。対応カードを確認してください。」 |
| Runway Warning | 「キャッシュが3ヶ月を切りました。収益改善または資金調達を検討してください。」 |
| TeamHealth Danger | 「チームの健康度が低下しています。離職リスクがあります。」 |
| TechDebt Danger | 「技術的負債が限界に近づいています。開発速度が低下します。」 |
| Inbox Full | 「Inboxが満杯です。処理が遅れると指標が悪化します。」 |

### 9.3 プライバシー確定文言（変更禁止）
```
「あなたの作業内容は記録しません。
 アプリ種別の滞在時間をカテゴリに集計するだけです。」

「このデータはローカルに保存され、外部に送信されません。」
```

### 9.4 KPIラベル（短縮）

| KPI | 表示ラベル | 単位 |
|-----|-----------|------|
| Cash | CASH | ¥ + 万表記（例: ¥30万） |
| Runway | RUNWAY | Nヶ月（0なら "< 1ヶ月"） |
| Reputation | REP | 数値のみ（/ 100） |
| TeamHealth | HEALTH | 数値のみ（/ 100） |
| TechDebt | DEBT | 数値のみ（/ 100） |

### 9.5 カテゴリバッジ表示名

| 内部ID | 表示名 |
|--------|--------|
| STRATEGY | STRATEGY |
| HIRING | HIRING |
| PROCESS | PROCESS |
| SALES | SALES |
| PRODUCT | PRODUCT |
| FINANCE | FINANCE |
| CRISIS | ⚠ CRISIS |
| CULTURE | CULTURE |
| AI | 🤖 AI |

---

## 10. 実装者向け Handoff 注記

### 10.1 KPI更新タイミング
- ポップオーバーが開いている間は、毎tickに合わせてKPI値をアニメーション更新する。
- ポップオーバーが閉じている場合は、次回オープン時に最新値を表示（snapshot不要）。
- KPI値の変化方向アニメーション（上昇時グリーン、下降時レッドのflash）はv0.2以降で検討。

### 10.2 ポップオーバーの開閉
- NSPopover は `.transient` 動作（他をクリックで自動クローズ）を推奨。
- ただしカード詳細表示中は `.semitransient` に切り替え（誤クローズ防止）。

### 10.3 カード表示優先順
- Inboxに複数カードがある場合、一覧から手動選択（自動で1件を強制表示しない）。
- Crisis カテゴリのカードは一覧の最上位に表示。

### 10.4 状態遷移の禁止事項
- Crisis Banner とカード詳細を同時表示しない（ポップオーバーが狭くなりすぎる）。
- カード詳細では Crisis Banner を非表示にする（Inbox 戻り後に再表示）。

### 10.5 Inbox満杯バナーの表示条件
- `currentInboxCount == maxInboxCards（3）` かつ `hasMissedCardGenerationDueToFullInbox == true` の場合のみ表示する。
- 3件入っていても次のタイミングが来ていない間は「もうすぐ満杯」表示はしない（過剰通知防止）。

### 10.6 Runway表示
- `dailyIncome = floor(mrrJPY * mrrPaidPerCompanyDayFactor)`
- `dailyBurn = overheadPerDay + salaryPerDay + policyCostPerDay + debtInterestPerDay`
- `estimatedMonthlyNetBurn = max(0, (dailyBurn - dailyIncome) * 30)`
- `runway = cashJPY / estimatedMonthlyNetBurn`（`estimatedMonthlyNetBurn == 0` の場合は `∞` 表示）
- Runway < 1ヶ月: 「< 1ヶ月」と表示。

### 10.7 アイコン使用指針（アセット取得済み版）
- KPI アイコン（Cash/Rep/Health/Debt）: `assets/curated/ui/` の PNG を `.renderingMode(.template)` で使用する。
- Runway: curated アセット未提供のため `calendar.badge.clock`（SF Symbol）を正式採用。
- アセット読込失敗時のみ SF Symbol にフォールバック（条件は §3 参照）。
- KPI アイコンは 16pt 表示（`@1x` ソースを使用。Retinaでは `@2x` を自動選択）。
- アイコンとラベルは中央揃え（top揃え不可）。
- カードUI背景: `assets/curated/ui/ui_card_bg.png` を ChoiceButton の背景テクスチャとして使用可能（オプション）。使用時は opacity 0.08〜0.12 程度に抑えてテキスト可読性を維持すること。

### 10.8 小ウィンドウ可読性
- ポップオーバー最小幅を 300pt に設定（それ未満は不可）。
- 300pt時: KPI下段の2セル（HEALTH / DEBT）は横1列（各セルが縮む）。
- ダイナミックタイプ（アクセシビリティフォントスケール）はv0.1対応外。

### 10.9 オンボーディング表示条件
- `UserDefaults.standard.bool(forKey: "onboardingCompleted")` が false の場合のみ表示。
- 「作業連携をONにして始める」ボタン押下後:
  1. ユーザーにシステムアクセシビリティ権限ダイアログを表示
  2. 権限取得結果に関わらず onboardingCompleted = true にして先へ進む
- 「作業連携をOFFで始める」ボタン押下後:
  1. `workIntegrationEnabled = false` を保存
  2. onboardingCompleted = true にして先へ進む

---

## 11. カテゴリバッジカラー

| カテゴリ | 背景色（hex） | 用途 |
|---------|-------------|------|
| STRATEGY | #5856D6 | 方向性・重要 |
| HIRING | #30D158 | 人材 |
| PROCESS | #636366 | 内部改善 |
| SALES | #FF9F0A | 収益 |
| PRODUCT | #007AFF | プロダクト |
| FINANCE | #FF453A | 財務 |
| CRISIS | #FF453A | 危機（SalesとFINANCE差別化のため太字ボーダー追加） |
| CULTURE | #FF6B6B | 文化 |
| AI | #BF5AF2 | AI（パープル） |

バッジ文字は常に `#FFFFFF`（白）、10pt Semibold。

---

---

## 12. アセット使用マッピング（取得済み curated アセット）

> 詳細な実装 handoff は `docs/24_design_asset_handoff_v01.md` を参照。
> ライセンス情報は `assets/licenses/*.txt` を参照。

### 12.1 UI アイコン（Phase 1 — v0.1 対象）

| UI要素 | ファイルパス | ソース | レンダリングモード | 表示サイズ |
|--------|------------|--------|-----------------|----------|
| Cash KPI アイコン | `assets/curated/ui/ui_cash_icon.png` | Kenney game-icons (medal1) | `.template` | 16pt |
| Reputation KPI アイコン | `assets/curated/ui/ui_reputation_icon.png` | Kenney game-icons (star) | `.template` | 16pt |
| TeamHealth KPI アイコン | `assets/curated/ui/ui_health_icon.png` | Kenney game-icons (plus) | `.template` | 16pt |
| TechDebt KPI アイコン | `assets/curated/ui/ui_techdebt_icon.png` | Kenney game-icons (gear) | `.template` | 16pt |
| カード背景テクスチャ | `assets/curated/ui/ui_card_bg.png` | Kenney ui-pack (button_rectangle_depth_flat) | `.original` | ストレッチ・タイル |
| Runway KPI アイコン | N/A（SF Symbol `calendar.badge.clock` を正式採用） | — | SF Symbol | 14pt |

### 12.2 オフィス装飾（Phase 2 — v0.1 任意対応）

Home Popover の最下部に小さなオフィス情景として表示する。
会社の進行度（Day数・Chapter）に応じて表示する家具・設備を変化させることで「成長」を視覚化する。
実装は Phase 2 のため v0.1 では省略可能。

| 表示タイミング | ファイルパス | 説明 |
|-------------|------------|------|
| 常時（Day 1〜） | `assets/curated/office/office_desk_01.png` | 基本デスク |
| 常時（Day 1〜） | `assets/curated/office/office_monitor_01.png` | PCモニター |
| Day 10 以降 または PRODUCT 関連カード選択後 | `assets/curated/office/office_plant_01.png` | 観葉植物（雰囲気向上） |
| 社員2名以上 または CH2解放後 | `assets/curated/office/office_desk_02.png` | 追加デスク |
| AI関連カード選択後 または CH2解放後 | `assets/curated/office/office_server_01.png` | サーバーラック |
| タイルベース合成用 | `assets/curated/office/office_tilemap_oga_indoor.png` | OGA indoor tileset（将来の床/壁タイル用） |

### 12.3 キャラクター（Phase 3 — v0.2 以降）

| キャラクター | ファイルパス | 表示条件 |
|------------|------------|---------|
| Founder | `assets/curated/characters/char_founder_01.png` | 常時 |
| DEVスタッフ | `assets/curated/characters/char_staff_dev_01.png` | DEV職種の社員がいる時 |
| PMスタッフ | `assets/curated/characters/char_staff_pm_01.png` | PM職種の社員がいる時 |

> **注意（docs/23 §3より）:** 2dPig の character/office スプライトはアトラス（PixelOfficeAssets.png）から切り出し済み。
> 切り出し精度に課題がある場合は v0.1 では使用を省略し、SF Symbol の人型アイコン（`person.fill` 等）で代替する。

---

*最終更新: 2026-02-27（アセット取得済み反映・Q1〜Q5確定・handoff 完成版）*
*参照: `docs/22_design_tokens.md`（トークン定義）、`docs/24_design_asset_handoff_v01.md`（実装 handoff）*
