# Office Scene Inner — Motion & Asset Import Plan v01

**対象ブランチ:** `codex/a1-viewstate-spec-sync`（実装先）
**設計日:** 2026-02-27
**関連 doc:** `docs/27_office_scene_inner_asset_blueprint_v01.md`（座席/Z-order/配置仕様）
**実装禁止:** 本ドキュメントはコード変更を一切含まない。設計・引き継ぎ専用。

---

## 目次

1. [モーション設計方針](#1-モーション設計方針)
2. [社員モーション種別カタログ](#2-社員モーション種別カタログ)
3. [アニメーション制御ルール](#3-アニメーション制御ルール)
4. [危機演出（Crisis Effects）](#4-危機演出crisis-effects)
5. [CPU 負荷対策](#5-cpu-負荷対策)
6. [B アセット取り込み計画](#6-b-アセット取り込み計画)
7. [受け入れチェックリスト](#7-受け入れチェックリスト)

---

## 1. モーション設計方針

### 1.1 基本原則

| 原則 | 内容 |
|------|------|
| **8 FPS キャップ** | `TimelineView(.animation(minimumInterval: 1.0/8.0))` で全モーション駆動。時間連続 sin/cos でキーフレーム不要 |
| **位置は絶対座標** | 全スプライトは `GeometryReader` → `.position(x:y:)` で配置。親の frame 変化に連動するオフセット加算 |
| **状態ドリブン** | `OfficeMotionProfile`（calm/steady/busy/urgent）が速度乗数を決定。View は乗数を `sin()` の周期に掛けるだけ |
| **同期防止** | 各スプライトに `employeeIndex` シード（0–5）と `motionPhase: Double`（0.0–1.0 乱数固定）を持たせ、全員が同じ動きにならないようにする |
| **加算 offset のみ** | `.position()` の基準座標（seatAnchor）は不変。モーションは `offsetX/offsetY` の加算のみ。基準座標を変えない |

### 1.2 MotionProfile と速度乗数

```
calm   : 0.85× — 朝の静かな時間帯
steady : 1.00× — 通常業務
busy   : 1.20× — 会議/開発スプリント中
urgent : 1.45× — 危機（runway 30 日未満 / health < 30）
```

`OfficeMotionProfile` は既に `OfficeSceneState.motionProfile` として提供済み（`OfficeSceneState.swift` 参照）。

---

## 2. 社員モーション種別カタログ

### 2.1 モーション一覧

各 `seatIndex` に 1 モーションを割り当てる。割り当ては `(employeeIndex % モーション数)` で決定し、起動時固定。

| ID | 名前 | 説明 | 振幅 (px) | 周期 (s) | offsetX | offsetY |
|----|------|------|-----------|----------|---------|---------|
| M0 | **Typing** | キー打鍵を模した微細な上下揺れ | Y: ±1.5 | 0.25 | 0 | sin(t × 25) × 1.5 |
| M1 | **Head-Nod** | 思考中の小さなうなずき | Y: ±2.0 | 1.2 | 0 | sin(t × 5.2) × 2.0 |
| M2 | **Lean-Side** | 集中時の体の左右傾き | X: ±1.5 | 2.0 | sin(t × 3.1) × 1.5 | 0 |
| M3 | **Idle-Sway** | 待機中のゆっくりした揺れ | X: ±1.0, Y: ±0.8 | 3.5 | sin(t × 1.8) × 1.0 | sin(t × 2.1) × 0.8 |
| M4 | **Urgent-Bounce** | 危機時限定の小刻み縦バウンス | Y: ±3.0 | 0.18 | 0 | abs(sin(t × 34)) × -3.0 |
| M5 | **Stand-Walk** | （mature 限定）画面内短距離移動 ※後述 | X: ±12 | 8.0 | walkX(t) | 0 |

> **M4 Urgent-Bounce** は `motionProfile == .urgent` のときのみ適用。それ以外のときは当該 seatIndex に割り当てられた通常モーション（M0–M3）に戻る。

### 2.2 モーション割り当て規則

```
seatIndex 0 → M0 (Typing)
seatIndex 1 → M1 (Head-Nod)
seatIndex 2 → M2 (Lean-Side)
seatIndex 3 → M3 (Idle-Sway)
seatIndex 4 → M0 (Typing)   ← mature 追加席
seatIndex 5 → M1 (Head-Nod) ← mature 追加席
```

### 2.3 位相シード（Phase Seed）

全員が同周期で動く「軍隊行進」を防ぐため、各 `employeeIndex` に固定位相シードを与える。

```swift
// 擬似コード（実装時参照）
let phaseSeed: [Double] = [0.00, 0.37, 0.62, 0.81, 0.19, 0.54]
let phased_t = time * speedMultiplier + phaseSeed[employeeIndex] * period
```

| employeeIndex | phaseSeed |
|--------------|-----------|
| 0 | 0.00 |
| 1 | 0.37 |
| 2 | 0.62 |
| 3 | 0.81 |
| 4 | 0.19 |
| 5 | 0.54 |

---

## 3. アニメーション制御ルール

### 3.1 座席作業モーション（Seated, M0–M3）

```
offsetY = sin(time × speedMul × (2π / period) + phaseSeed × 2π) × amplitude_Y
offsetX = sin(time × speedMul × (2π / period_X) + phaseSeed × 2π) × amplitude_X
```

- `speedMul` = `motionProfile.speedMultiplier`（0.85–1.45）
- `period` は各モーション定義値（秒）
- アニメーション loop: 8 FPS `TimelineView` から渡された `context.date.timeIntervalSinceReferenceDate` を `time` として使用

### 3.2 Urgent-Bounce（M4）切り替え規則

```
if motionProfile == .urgent {
    apply M4 to ALL seated employees
} else {
    apply default motion (M0–M3 by seatIndex)
}
```

M4 は `.urgent` 専用。`.busy` では通常モーションに速度乗数 1.2× をかけるだけ。

### 3.3 Stand-Walk（M5, mature 限定）

Stand-Walk は高コストなため、以下の厳格な条件下のみ有効化：

**有効化条件:**
- `growthStage == .mature`
- `motionProfile != .urgent`（危機中は歩き回らない）
- `activeEmployeeCount >= 5`
- `seatIndex` が `walkableSeats`（例: seat 5 のみ）

**移動軌跡（walkX）:**

```
walkPhase = fmod(time × 0.125, 1.0)  // 8秒で1往復
if walkPhase < 0.5:
    // 右へ移動 (0〜0.5 フェーズ)
    walkX = lerp(-12, +12, walkPhase × 2)
    direction = .right
else:
    // 左へ戻る (0.5〜1.0 フェーズ)
    walkX = lerp(+12, -12, (walkPhase - 0.5) × 2)
    direction = .left
```

X範囲 ±12px（seatAnchor.x を中心）。Y は不変（スプライト差し替えなしで斜め移動は表現しない）。

**スプライト切り替え（将来対応）:**
- 現在は `char_01`〜`char_03` の固定画像を使用
- 将来的に歩行アニメ（walk_l/walk_r フレーム）が用意された場合、`direction` で切り替え

### 3.4 Activity Dots

`busy` / `urgent` 時に各キャラクター頭上に表示（既存実装 `activityDots` 参照）。

| モーション | dotDot offset Y 振幅 | 速度 |
|-----------|---------------------|------|
| busy | ±2.5 px | ×1.2 |
| urgent | ±3.5 px | ×1.5 |

実装参照: `HomePopoverView.swift` の `dotDot(time:dotIdx:employeeIndex:)` 関数。
`urgent` 時は振幅と速度を引数で増幅すること（現状は固定値 2.5 / 5.5）。

### 3.5 装飾物モーション

| 装飾 | モーション | 仕様 |
|------|-----------|------|
| 植物（plant） | **Leaf-Sway** | `rotationEffect(Angle(degrees: sin(t × 1.2) × 3.0))` — 中心点は底部 anchor |
| サーバー（server） | **Status-Blink** | LED 点滅: `opacity = 0.4 + 0.6 × abs(sin(t × 2.0))` — 別途 LED overlay view が必要 |
| サーバー（urgent 時） | **Error-Flash** | `opacity = abs(sin(t × 8.0))` + 赤色 overlay |

---

## 4. 危機演出（Crisis Effects）

### 4.1 Atmosphere Pulse（既存）

`HomePopoverView.swift` 実装済み。`danger` 時に赤い大気色を 1.5Hz で明滅。
`warn` 時は橙色、非点滅（固定 opacity 0.10）。

### 4.2 Scene Border（既存）

`sceneBorderColor` が `riskLevel` で変化（実装済み）。
追加仕様: `urgent` 時は border の `lineWidth` を 1.5 → 2.5 pt に広げること（視認性向上）。

### 4.3 キャラクター危機演出

| 危機レベル | キャラクター演出 |
|-----------|----------------|
| warn | Activity dots 表示（busy と同等） |
| danger | M4 Urgent-Bounce + Activity dots + dots 赤色化（`.red.opacity(0.85)`） |

danger 時の dots 色変更:
```swift
// 現状 (white): Circle().fill(Color.white.opacity(0.80))
// danger 時:    Circle().fill(Color.red.opacity(0.85))
```

### 4.4 植物の枯れ演出（health < 30）

- `teamHealth < 30` かつ `showPlant == true`
- 植物スプライトに `saturation(0.0).brightness(-0.1)` フィルタを適用
- Leaf-Sway の振幅を 3.0° → 1.0° に減らす（元気なし）

---

## 5. CPU 負荷対策

### 5.1 8 FPS キャップ（実装済み）

`TimelineView(.animation(minimumInterval: 1.0/8.0))` によりアニメーション更新を 8 FPS に制限。
sin/cos 計算は 8 FPS 分のみ実行される。

### 5.2 スプライトキャッシュ（実装済み）

`TinyAsset` の `NSCache<NSString, NSImage>` により画像は初回ロード後キャッシュ済み。
重複 loadImage 呼び出しはキャッシュヒットのみ。

### 5.3 条件付きモーション無効化

| 条件 | 無効化するモーション |
|------|-------------------|
| ウィンドウ非表示（popover closed） | 全モーション（TimelineView は自動停止） |
| `growthStage == .seed` かつ employee = 1 | Stand-Walk（M5）を完全無効化 |
| `activeEmployeeCount == 0` | Activity dots を非表示 |
| `motionProfile == .calm` | Leaf-Sway 振幅を 50% に削減 |

### 5.4 Draw Call 最適化

- `Image(nsImage:)` は SwiftUI が内部でキャッシュ。フレームごとに `TinyAsset.officeSprite` を呼ばない
- `TinyAsset.officeSprite` の戻り値を `let` に保持し、`TimelineView` のクロージャ外（`@State` か computed property）で管理
- `Animation` 系の `.withAnimation` ブロックを `TimelineView` 内部では使用しない（二重計算になる）

### 5.5 fallback 時の軽量化

スプライトが nil の場合、固定サイズの透明 `Rectangle()` を代替として配置（EmptyView は NG — 座標系が崩れる）。
fallback view はモーション offset を適用しない（計算コスト不要）。

---

## 6. B アセット取り込み計画

### 6.1 ソース分類（doc 27 §1 の整理）

| ソース | 場所 | 状態 | 即使用可 |
|--------|------|------|---------|
| **A: XCAssets** | `Assets.xcassets/` | 23 imagesets 登録済 | ✅ |
| **B1: Curated PNG** | `assets/curated/` | PNG 単体、未登録 | ❌ 要登録 |
| **B2: 2dPig atlas** | `assets/raw/2dPig/PixelOfficeAssets.png` | スプライトシート | ❌ 要切り出し |
| **B3: OGA tileset** | `assets/raw/OGA/office-tilemap.png`, `office-8x8-tileset/c1-c5.png` | タイルマップ/キャラ | ❌ 要切り出し（任意） |
| **B4: Kenney tiny-town** | `assets/raw/kenney-tiny-town/` | タイルセット | ❌ 将来対応 |

### 6.2 B1: Curated PNG 取り込み手順

`assets/curated/` 内の個別 PNG を XCAssets imageset として登録する。

**手順:**

1. `Assets.xcassets/` 内に `<assetName>.imageset/` ディレクトリを作成
2. PNG を imageset ディレクトリにコピー（ファイル名そのまま）
3. `Contents.json` を作成:

```json
{
  "images": [
    {
      "idiom": "mac",
      "scale": "1x",
      "filename": "<filename>.png"
    }
  ],
  "info": {
    "author": "xcode",
    "version": 1
  }
}
```

4. `TinyAsset.officeSprite(named:)` で参照（imageset 名 = assetName）

**対象ファイル（確認が必要なもの）:**

```
assets/curated/
├── office_desk_front.png     → imageset: office_desk_front
├── office_desk_monitor.png   → imageset: office_desk_monitor
├── office_chair_*.png        → imageset: office_chair_*
└── （その他 curated 内の未登録ファイル）
```

> 実装担当者は `ls assets/curated/` で全ファイルを確認し、XCAssets に未登録のものを登録すること。

### 6.3 B2: 2dPig スプライトアトラス 切り出し計画

**ファイル:** `assets/raw/2dPig/PixelOfficeAssets.png`

スプライトシートからの切り出しは **手動または自動化ツール** で実施。

**推奨手順（手動）:**
1. `Preview.app` または `Aseprite` でアトラスを開く
2. グリッドが 16×16 または 32×32 であることを確認
3. 必要なスプライト（デスク、チェア、モニター、植物）を選択してエクスポート
4. 書き出しファイル名規則: `office_<object>_2dpig.png`
5. B1 と同じ手順で XCAssets 登録

**優先度:**

| スプライト | 優先度 | 理由 |
|-----------|--------|------|
| デスク前面 | 高 | 現在 `office_desk` のみ。前面/背面分離が Z-order 修正に必要 |
| モニター | 高 | デスク+モニター ZStack 構成に必要 |
| 植物（大） | 中 | `showPlant` 時の mature 演出強化 |
| チェア | 低 | 現状のデスクスプライトで代替可能 |

### 6.4 B3: OGA キャラクタースプライト（任意）

**ファイル:** `assets/raw/OGA/office-8x8-tileset/c1.png` 〜 `c5.png`

- 8×8 px の極小スプライト。macOS でそのまま使うと潰れる
- **取り込み条件:** `@2x` / `@3x` スケールアップ後、ぼかしなしで Nearest Neighbor 拡大すること
- 拡大後サイズ: 24×24 px（3x）または 32×32 px（4x）
- **推奨:** 現状の `char_01`〜`char_03`（既存 XCAssets）が十分なため、OGA キャラは後回しで良い

**もし取り込む場合の手順:**
1. `sips --resampleWidth 32 c1.png --out c1_32.png` でリサイズ（Nearest Neighbor: `--resampleHeightWidthMax 32`）
2. より精密なリサイズは `Aseprite` の Export Sprite Sheet 機能を使用
3. 書き出し名: `char_oga_c1.png` 〜 `char_oga_c5.png`
4. XCAssets 登録後、`TinyAsset.characterSprite(named:)` で参照

### 6.5 B4: Kenney tiny-town（将来対応）

`assets/raw/kenney-tiny-town/` — タイルセット。現フェーズでは取り込まない。
doc 27 §1 の Case C（Tilemap Background）を採用するタイミングで検討。

### 6.6 取り込み優先順位サマリー

| 優先 | アセット | ソース | 作業 | いつ |
|------|---------|--------|------|------|
| P0 | curated/ 未登録 PNG | B1 | XCAssets 登録のみ | 次スプリント |
| P1 | desk_front / monitor | B2 | アトラス切り出し + 登録 | doc 27 実装フェーズ |
| P2 | plant 大サイズ | B2 | アトラス切り出し + 登録 | mature 演出強化時 |
| P3 | OGA c1–c5 キャラ | B3 | リサイズ + 登録 | 後日（任意） |
| P4 | Kenney タイル | B4 | Case C 採用時のみ | 将来 |

---

## 7. 受け入れチェックリスト

### 7.1 モーション品質

- [ ] 全 6 席のキャラクターが異なる位相・モーションで動いている（同期していない）
- [ ] `calm` → `busy` → `urgent` でモーション速度が段階的に速くなる
- [ ] `urgent` 時に M4 Urgent-Bounce が全員に適用され、dots が赤くなる
- [ ] `urgent` 解除後に通常モーション（M0–M3）に戻る
- [ ] 植物の Leaf-Sway が `teamHealth < 30` 時に弱まる
- [ ] サーバーの Status-Blink が一定周期で明滅する
- [ ] Stand-Walk（M5）が `mature` かつ `activeEmployeeCount >= 5` 時のみ発動
- [ ] キャラクターが seatAnchor を大きく外れない（±12px 以内）

### 7.2 Z-order 正確性（doc 27 チェックリストと対）

- [ ] 後列デスク → 後列キャラ → 前列デスク → 前列キャラ の順に描画される
- [ ] モーション offset を適用してもキャラが誤った Z-layer に見えない
- [ ] Stand-Walk 中のキャラが Z-order を乱さない

### 7.3 パフォーマンス

- [ ] Activity Monitor で CPU 使用率がポップオープン中 1% 未満（アイドル時）
- [ ] busy/urgent 時でも 3% 未満
- [ ] popover 非表示時に TimelineView が停止（CPU ゼロに戻る）
- [ ] `TinyAsset.loadImage` が 2 回目以降キャッシュヒットする（ログ確認）

### 7.4 アセット

- [ ] 全 imageset が `TinyAsset.officeSprite/characterSprite` で正しくロードされる
- [ ] nil の場合に固定サイズ透明 Rectangle が代替表示される（位置ズレなし）
- [ ] B1 curated PNG が XCAssets に登録され `Bundle.module` からアクセス可能
- [ ] B2 アトラスから切り出したアセットがピクセル境界で正確にトリミングされている

### 7.5 スペック整合性

- [ ] doc 27 §3 の座席座標（6 席）と本ドキュメントのモーション割り当てが一致
- [ ] `phaseSeed` テーブルの値が実装コードに反映されている
- [ ] `OfficeMotionProfile.speedMultiplier` が 0.85 / 1.00 / 1.20 / 1.45 で実装されている
- [ ] 危機演出が `GameViewState.riskLevel` / `GameState` の正しいフィールドを参照している

---

## 付録: 実装者向け簡易リファレンス

### A. sin-based offset 計算テンプレート

```swift
// TimelineView クロージャ内
let time = context.date.timeIntervalSinceReferenceDate
let speedMul = sceneState.motionProfile.speedMultiplier

// M1 Head-Nod の例 (employeeIndex=1, period=1.2s, amplitude=2.0)
let period = 1.2
let amplitude: CGFloat = 2.0
let phase = time * speedMul * (2 * .pi / period) + phaseSeed[1] * 2 * .pi
let offsetY = sin(phase) * amplitude
```

### B. MotionProfile speedMultiplier 定義

```swift
// OfficeSceneState.swift に追加（または OfficeMotionProfile に直接定義）
extension OfficeMotionProfile {
    var speedMultiplier: Double {
        switch self {
        case .calm:   return 0.85
        case .steady: return 1.00
        case .busy:   return 1.20
        case .urgent: return 1.45
        }
    }
}
```

### C. Phase Seed 配列

```swift
private let employeePhaseSeed: [Double] = [0.00, 0.37, 0.62, 0.81, 0.19, 0.54]
```

### D. Fallback View テンプレート

```swift
// スプライトが nil の場合
func spriteFallback(width: CGFloat, height: CGFloat) -> some View {
    Rectangle()
        .fill(Color.clear)
        .frame(width: width, height: height)
}
```
