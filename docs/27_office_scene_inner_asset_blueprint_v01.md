# 27 Office Scene 内部アセット配置ブループリント v0.1

> **種別:** 設計ドキュメント（実装禁止）
> **対象:** `AnimatedOfficeScene` 内部（`HomePopoverView.swift` の ZStack 中身のみ）
> **作成:** 2026-02-27（Claude Code / Office Scene 内部デザイン設計担当）
> **参照:** docs/14, docs/21, docs/22, docs/24, HomePopoverView.swift, OfficeSceneState.swift

---

## 0. 本書の読み方

- §1–2: 方向性と推奨案選定
- §3: 推奨案の完全ブループリント（レイヤー・座標・条件）
- §4: バグ予防仕様（現在の崩れを再発させない）
- §5: 実装ハンドオフ表（Codex向け）
- §6: 受け入れチェックリスト

---

## 1. 方向性案（A / B / C）

### 案A — "Furniture Fix Only"（保守的）

**コンセプト:** 現コードの構造を保ちつつ、座標バグと重なり破綻のみを修正する。

**狙い:**
- 壊れている配置（デスク・モニターの位置ズレ、Z-order 破綻）を直す
- 既存コードへの変更量を最小化する
- SF Symbol fallback のみ使用、アセット追加なし

**アセット方針:** A分類（XCAssets登録済み）のみ使用。B分類への取り込み不要。

**メリット:**
- 実装コスト最低（2–3関数修正のみ）
- ビルド・テストリスクがほぼゼロ
- 座標バグは完全解消できる

**デメリット:**
- 背景が平坦なまま（bgCell一色）で「オフィス感」が出ない
- キャラ・家具の奥行きが出ない
- 「カイロソフト風」には程遠い

**実装難易度:** 低

---

### 案B — "Pixel Room"（推奨案）

**コンセプト:** 純粋なSwiftUI描画で「壁・床」の奥行きを表現し、既存A分類アセットを正しく積み上げる。1件のみB分類（タイル背景）をオプション取り込みとする。

**狙い:**
- 背景に「壁面（上20%）＋床（下80%）」のグラデーション分割を入れる（純色のみ、アセット不要）
- デスク＋モニター＋キャラクターのZ順を「奥行き」ベースで正しく積む
- 成長段階ごとに席数と家具の密度が変わり、シーンが文字通り「成長」する
- リスク大気オーバーレイで緊張感を演出する（既実装を精度UP）
- 取り込み推奨：`office_tilemap_oga_indoor.png`（floor pattern として背景に薄敷き）

**アセット方針:**
- A分類（XCAssets）を主体。キャラ3種・家具5種は全てA分類で揃っている。
- B分類オプション: `office_tilemap_oga_indoor.png` → XCAssets に imageset 追加（`office_floor_tile`）で床の視覚密度アップ

**メリット:**
- 追加アセット取り込みなしで「カイロソフト風」の質感に近づける
- Z-order 奥行きソートで配置破綻を根本から防ぐ
- OfficeSceneState.growthStage との対応が明確
- 実装量が適切（AnimatedOfficeScene リファクタリング + 背景View追加）

**デメリット:**
- A案より実装工数が多い（中程度）
- 壁・床はSwiftUIカラーのみのため、ピクセルアート感は限定的

**実装難易度:** 中

---

### 案C — "Tilemap Background"（拡張版）

**コンセプト:** OGAの8×8タイルセットやkenney tiny-townの個別タイルをタイリングして床・壁面を構築する。B分類アセット複数を取り込む本格的な再設計。

**狙い:**
- `office-8x8-tileset/tileset2_4.png` で格子状の床タイルを敷く
- kenney tiny-town tiles（`tile_0000`–`tile_0092`）から棚・窓・ドアを追加
- OGA キャラ（`c1.png`–`c5.png`、8×8ピクセル）を追加社員スプライトとして使用

**アセット方針:**
- A分類を引き続き使用
- B分類: タイルマップ + OGAキャラ + tiny-town装飾タイルを多数インポート

**メリット:**
- 最も「カイロソフト風」に近い質感
- 社員バリエーションが増える（最大5種）
- 背景の豊かさが段違い

**デメリット:**
- 実装難易度が高い（タイル管理、スプライト分割の事前作業、座標管理の複雑化）
- B分類アセット複数の取り込み作業が必要
- v0.1 スコープを大きく超える
- tiny-town / OGAタイルはオフィスシーン専用ではないため選定作業が必要

**実装難易度:** 高

---

## 2. 推奨案選定：案B「Pixel Room」

### 選定理由

| 評価軸 | 案A | 案B（推奨） | 案C |
|------|-----|------------|-----|
| 破綻しにくさ | ○ バグ修正のみ | ◎ 設計から奥行きを組む | △ タイル管理が複雑 |
| 将来拡張性 | △ そのまま | ◎ L-番号レイヤー構造が明確 | ○ タイル拡張可 |
| 実装コスト | 低 | **中（適切）** | 高（v0.1超過） |
| 「カイロソフト風」達成度 | 低（配置修正のみ） | **高（壁・床・Z順）** | 最高（v0.2向け） |
| 新規アセット必要数 | 0 | 1（オプション） | 5以上 |

**結論:** 案Bは「現在の破綻を完全解消しつつ、追加アセットなしで奥行き表現を実現」できる唯一の選択肢。案Aは最小限すぎてUX目標に届かず。案CはV0.2向けロードマップとして保存する。

---

## 3. 推奨案ブループリント（Pixel Room）

### 3.1 シーン仕様

```
シーン外寸
  幅:  GeometryReader が提供する実幅（典型: 328pt = 360 - 32pt padding）
  高さ: 200pt（frame(height: 200)）
  角丸: 10pt
  座標系: (0,0) = 左上、(1,1) = 右下（正規化）
  anchor: CGPoint.position() は常に View の中心を指す
```

### 3.2 視覚的奥行きレイアウト

```
Y=0.00 ┌─────────────────────────────────────────┐
       │  L1b: 壁面ストリップ（上部15%）         │
       │  暗めのグラデーション → 奥行き感         │
Y=0.15 ├─────────────────────────────────────────┤
       │  L2: グリッドパターン（全面、opacity低）  │
       │                                         │
       │  L3: バックロー家具（y=0.28〜0.35）      │
       │  [desk][monitor] × 最大3席              │
Y=0.45 │─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─  │
       │  L4: バックローキャラ（y=0.28〜0.35）    │
       │  [founder][dev][pm]                     │
       │                                         │
       │  L5: フロントロー家具（y=0.65〜0.75）    │
       │  + 装飾（植物、追加デスク、サーバー）     │
Y=0.65 │─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─  │
       │  L6: フロントローキャラ（y=0.65〜0.75）  │
       │                                         │
       │  L7: 大気オーバーレイ（リスク色グラデ）   │
Y=0.85 │  L8: EventBeacon（右上固定）             │
       │  L9: InfoStrip（下部フッター）           │
Y=1.00 └─────────────────────────────────────────┘
```

### 3.3 レイヤー定義

| レイヤーID | 名称 | 実装方式 | Z-index | アセット種別 |
|-----------|------|---------|---------|------------|
| L1a | 床面 | `RoundedRectangle.fill(bgCell)` | 0 | なし（SwiftUI Color） |
| L1b | 壁面ストリップ | `LinearGradient` (bgCell darkened → bgCell) | 1 | なし |
| L2 | グリッド | `OfficeGridPattern` Shape | 2 | なし |
| L3 | バックロー家具 | `@ViewBuilder` sprite群 | 3–4 | **A**: office_desk_01, office_monitor_01 |
| L4 | バックローキャラ | `@ViewBuilder` 社員スプライト | 5 | **A**: char_founder_01, char_staff_dev_01, char_staff_pm_01 |
| L5 | フロントロー家具 + 装飾 | `@ViewBuilder` sprite群 | 6–7 | **A**: office_desk_01/02, office_plant_01, office_server_01 |
| L6 | フロントローキャラ | `@ViewBuilder` 社員スプライト | 8 | **A**: char_staff_dev_01, char_staff_pm_01 |
| L7 | 大気オーバーレイ | `LinearGradient` | 9 | なし（SwiftUI Color） |
| L8 | EventBeacon | `EventBeacon` View | 10 | **A**: cat_*_icon |
| L9 | InfoStrip | `OfficeInfoStrip` View | 11 | なし（SF Symbol） |

### 3.4 壁面ストリップ仕様（L1b）

```
高さ: 30pt（scene_height * 0.15）
グラデーション:
  - Light モード: Color(hex: 0xEBE9E4) → bgCell  (上→下)
  - Dark  モード: Color(hex: 0x2E2C2A) → bgCell  (上→下)
目的: 「壁と床の境界」を暗示して奥行き感を出す
実装: LinearGradient(colors: [wallColor, .clear], startPoint: .top, endPoint: .bottom)
      .frame(maxWidth: .infinity).frame(height: 30)
      + VStack { wallGradient; Spacer() } で上部固定
```

### 3.5 座標仕様（デスク＋モニター）

#### 現状バグと修正方針

**現在の問題:**
```swift
// 問題: desk と monitor が別々に .position() されている
// .position() は view 中心 を座標に置く
// モニターは (p.x + 10, p.y - 10) → デスクに対して右+上にズレる
// 2つの view は互いの位置を知らない → スプライト分離が起きる
func deskSprite(at p: CGPoint) -> some View {
    desk.position(p)                              // 中心: p
    monitor.position(CGPoint(x:p.x+10, y:p.y-10)) // 中心: p+offset
}
```

**修正後の方針:**
```
デスク+モニターを1つの ZStack でまとめ、
ZStack ごと .position(p) する。
ZStack 内では offset を使い相対位置を制御する。
```

**デスクユニットの内部レイアウト（pt）:**
```
             ┌──────────────┐
             │  monitor     │ w=18, h=22, top-center
             └──────────────┘
   ┌──────────────────────────┐
   │         desk             │ w=36, h=20, bottom-center
   └──────────────────────────┘

ZStack 内の相対座標（アンカー=ZStack中心）:
  - desk:    offset(x: 0, y: +11)   （ZStack下部）
  - monitor: offset(x: 0, y: -11)   （ZStack上部）

ZStack 合計サイズ: w=36, h=44 (= desk_h + monitor_h + 2gap)
.position(p) で seatAnchor に配置
```

### 3.6 座標仕様（キャラクター）

**キャラクターの position ルール:**
```
キャラクター中心 = seatAnchor の Y に -8pt オフセット
理由: キャラが「デスクの後ろ（奥）に座っている」印象を出す。
     座席アンカーはデスク中心に合わせているので、
     キャラは僅かに上(奥)にいる必要がある。

animPos.y -= 8  （アニメーション計算後に適用）
```

**キャラクターサイズ:**
```
frame: width=20, height=28 （現状維持）
shadow: color=.black.opacity(0.25), radius=1, x=0, y=1
interpolation: .none（pixel-perfect必須）
```

### 3.7 Z-order ソート（奥行き）の実装ルール

**ルール:** シーン内のスプライトは「Y座標が大きいほど手前」に描画する。

**具体的な描画順（ZStack 内 @ViewBuilder の呼び出し順）:**

```
1. L1a floor_bg           (fill, 最背面)
2. L1b wall_strip         (グラデーション、上部のみ)
3. L2  grid               (Shape、全面)
4. L3  backrow_furniture  (seat 0,1,2 のデスクユニット)
5. L4  backrow_characters (seat 0,1,2 のキャラ)
6. L5a decorative_back    (office_desk_02, office_server_01 — 右端・奥寄り)
7. L5b frontrow_furniture (seat 3,4,5 のデスクユニット)
8. L5c decorative_front   (office_plant_01 — 左端・手前)
9. L6  frontrow_characters (seat 3,4,5 のキャラ)
10. L7 atmosphere         (大気オーバーレイ)
11. L8 event_beacon       (EventBeacon)
12. L9 info_strip         (VStack > Spacer + OfficeInfoStrip)
```

**実装上のポイント:** `@ViewBuilder` を `backrowFurnitureLayer`、`backrowCharactersLayer`、`frontrowFurnitureLayer`、`frontrowCharactersLayer` の4関数に分割する。現状の `furnitureLayer`/`employeesLayer` の2分割では前後の正しいZ順を実現できない。

### 3.8 席配置（seatAnchors）

6席を2行3列に配置。バックロー（背面行）を index 0–2、フロントロー（前面行）を index 3–5 とする。

| index | row | x_norm | y_norm | 表示条件 | キャラ種別 |
|-------|-----|--------|--------|---------|----------|
| 0 | back | 0.16 | 0.30 | activeEmp ≥ 1 | founder |
| 1 | back | 0.45 | 0.28 | activeEmp ≥ 2 | dev |
| 2 | back | 0.75 | 0.32 | activeEmp ≥ 3 | pm |
| 3 | front | 0.24 | 0.72 | activeEmp ≥ 4 | dev |
| 4 | front | 0.56 | 0.68 | activeEmp ≥ 5 | pm |
| 5 | front | 0.83 | 0.72 | activeEmp ≥ 6 | dev |

**非アクティブ席の表示:** index >= activeEmployeeCount のデスクユニットは opacity=0.20 で薄く表示（「将来の席」示唆）。キャラクターは描画しない。

### 3.9 装飾配置（Conditional Props）

| element_id | x_norm | y_norm | w_pt | h_pt | z_layer | 表示条件 | asset_source |
|-----------|--------|--------|------|------|---------|---------|-------------|
| plant_01 | 0.07 | 0.82 | 24 | 32 | L5c | showPlant | **A** |
| desk_02 | 0.87 | 0.52 | 30 | 30 | L5a | showDesk2 | **A** |
| server_01 | 0.95 | 0.40 | 24 | 40 | L5a | showServer | **A** |

**配置理由:**
- `plant_01` は左手前（視聴者に最も近い位置）→ 最前景感
- `desk_02` は右中景（追加席・会議机として見せる）
- `server_01` は右奥（技術インフラを示す場所として奥へ）

### 3.10 成長段階ビジュアル差分

| growthStage | 条件 | アクティブ席 | 壁面彩度 | 追加要素 |
|------------|------|------------|---------|---------|
| seed | teamSize=1, day<15, ch=0 | 2席（index 0,1 dim） | 低（ほぼbgCell） | なし |
| growth | teamSize≥2 or ch≥1 or day≥15 | 4席 | 中（わずかに差分） | plant_01（day≥10 or hasProduct） |
| mature | teamSize≥5 or ch≥2 or day≥30 | 6席 | 高（壁色最大） | plant + desk_02 + server |

**seed ステージの壁面:**
```
壁グラデーションの top 色 opacity: seed=0.2, growth=0.5, mature=0.8
目的: 成長するほど「オフィスらしさ」が増す感覚を色で演出
```

### 3.11 リスク状態差分

| riskLevel | 大気色 | opacity | パルス | シーン枠線色 |
|----------|-------|---------|-------|------------|
| normal | .clear | 0.0 | なし | borderDefault |
| warn | amber #FF9F0A | 0.10 | なし | borderWarning |
| danger | red #FF453A | 0.15 | 1.5Hz正弦 | borderDanger |

**danger の枠線追加演出:**
シーン外枠（RoundedRectangle.stroke）の lineWidth を danger 時に 1.5pt → 2pt に変える。

### 3.12 focusCategory 有無差分

| 条件 | 変化 |
|------|------|
| focusCategory == nil | EventBeacon 非表示、モーション = calm |
| focusCategory != nil | EventBeacon 表示（top-right）、モーション = EventVisualCatalog.spec().motion |
| riskLevel == danger | EventBeacon border = borderDanger（category色より優先） |

---

## 4. バグ予防仕様

### 4.1 現在の崩れ原因（特定済み）

| 問題 | 原因 | 修正方針 |
|------|------|---------|
| デスクとモニターが分離している | 各々に `.position()` を使い、相対位置ではなく絶対位置で配置している | ZStack 内でデスクとモニターを合成し、ZStack ごと `.position()` する |
| キャラがデスクの上に乗っているように見える | furnitureLayer と employeesLayer が分離しており、全家具が全キャラより奥にある | 奥行きソートを実装（backrowFurniture→backrowChars→frontFurniture→frontChars） |
| 植物・サーバーがキャラと同Z層に混在する | `furnitureLayer` 内で全装飾を一括描画しているため、前後関係が定義されていない | 装飾を「奥寄り（L5a）」と「手前（L5c）」に分類して描画順を固定 |
| アセット欠損時にレイアウトが崩れる（サイズ0） | `@ViewBuilder` の `if let image = TinyAsset...` が nil のとき EmptyView → サイズ0 → 周囲の View がズレる | フォールバック View（SF Symbol または固定サイズの透明矩形）を必ず返す |

### 4.2 座標の基準統一ルール

1. **全ての絶対座標は `seatAnchor × size` で計算する**（直接数値ハードコード禁止）
2. **relative layout（デスク+モニター）は `offset()` を使い、`position()` を外側の1か所のみに使う**
3. **`GeometryReader` から取得した `size` を計算に使う**（`Binding<CGSize>` のような state 変数への保存禁止）
4. **サイズ指定は pt 定数で行い、画面幅に対する比率変換しない**（家具は常に同じ pt サイズ）

### 4.3 画面サイズ変化（幅変化）への対応

ポップオーバー最小幅 300pt → 最大 360pt の範囲でシーンが縮む可能性がある。

**防止ルール:**
- seatAnchor は正規化座標（0–1）→ `x * size.width` で常に実幅に追従する ✅（現行の `point(anchor:in:)` 関数は正しい）
- 家具・キャラのフレームサイズはpt固定 → 幅が縮んでも家具サイズは変わらない
- ただし 300pt 幅では家具が重なる可能性があるため、seatAnchor の X 値に注意
  - seat 0 (x=0.16): 300pt × 0.16 = 48pt → 家具幅36pt → 左端12pt, 問題なし
  - seat 5 (x=0.83): 300pt × 0.83 = 249pt → 家具幅36pt → 右端18pt, 問題なし
  - seat 0 と seat 3 (x=0.16 vs x=0.24): 差 = (0.24-0.16) × 300 = 24pt < 36pt（デスク幅）
  - **300pt幅では seat 0 と seat 3 のデスクが横方向に重なる（縦方向は 0.30 vs 0.72 で問題なし）**
  - **対応:** frontrow の seat 3 x_norm を 0.26 に変更（差=30pt、ギリギリ重ならない）

### 4.4 アセット欠損時フォールバックルール

**ルール: 全スプライト関数はゼロサイズの EmptyView を返さない**

```
オフィス家具 → 欠損時: SF Symbol で代替（size固定）
  office_desk_01 → rectangle.fill (36×20pt, foreStyle: borderDefault)
  office_monitor_01 → rectangle.fill (18×22pt)

キャラクター → 欠損時: person.fill SF Symbol (20×28pt)
  SF Symbol は既に現行コードで実装済み ✅

装飾 (plant, desk_02, server) → 欠損時: 非表示 (EmptyView) でよい
  （これらはレイアウトの基準ではないので消えても崩れない）
```

**絶対に返してはいけないパターン:**
```swift
// NG: image が nil のとき EmptyView → サイズ0 → position() が無効になる
if let image = TinyAsset.officeSprite(named: "office_desk_01") {
    image.frame(...)
}
// OK: 必ずフォールバックViewを返す
if let image = TinyAsset.officeSprite(named: "office_desk_01") {
    image.frame(...)
} else {
    Rectangle()
        .fill(TinyTokens.ColorToken.bgCell)
        .frame(width: 36, height: 20)
}
```

### 4.5 再発防止チェックリスト（設計保証）

- [ ] デスクとモニターは同一 ZStack にまとめ、`.position()` は ZStack 外側1か所のみ
- [ ] backrow 家具 → backrow キャラ → frontrow 家具 → frontrow キャラ の順で ZStack に積む
- [ ] `@ViewBuilder` 関数内で `if let` が nil になるパスで EmptyView を返す場合、そのviewが layout に影響しないことを確認する
- [ ] `GeometryReader` の size は `let size = proxy.size` で取得し、TimelineView と GeometryReader の両方をまたぐ state 保存をしない
- [ ] 非アクティブ席は `.opacity(0.20)` で描画し、`if index >= activeCount { EmptyView }` で省略しない（省略するとForEachの型が不一致になる可能性）

---

## 5. 実装ハンドオフ表（Codex向け）

全ての `x`, `y` は `seatAnchor` からの **normalized (0–1)** または **pt offset**。
`position()` はsizeに乗じた絶対座標に変換する。

### 5.1 背景レイヤー群

| element_id | layer | asset_source | asset_name_or_path | x | y | width | height | anchor | z_index | visibility_condition | motion_profile | fallback_asset | notes |
|-----------|-------|-------------|-------------------|---|---|-------|--------|--------|---------|---------------------|---------------|---------------|-------|
| floor_bg | L1a | none | SwiftUI Color: bgCell | 0 | 0 | 1.0 (norm) | 1.0 (norm) | topLeading | 0 | always | none | — | RoundedRectangle cornerRadius=10 |
| wall_strip | L1b | none | LinearGradient (wallColor→clear) | 0 | 0 | 1.0 (norm) | 30pt | top | 1 | always | none | — | Light: #EBE9E4, Dark: #2E2C2A、VStack { wall; Spacer() } で上固定 |
| grid | L2 | none | OfficeGridPattern Shape | 0 | 0 | 1.0 (norm) | 1.0 (norm) | topLeading | 2 | always | none | — | stroke opacity=0.18, lineWidth=0.5 |

### 5.2 バックロー家具（seats 0–2）

| element_id | layer | asset_source | asset_name_or_path | x | y | width | height | anchor | z_index | visibility_condition | motion_profile | fallback_asset | notes |
|-----------|-------|-------------|-------------------|---|---|-------|--------|--------|---------|---------------------|---------------|---------------|-------|
| desk_unit_0 | L3 | **A** | office_desk_01 + office_monitor_01 | 0.16 | 0.30 | 36pt (desk) 18pt (mon) | 44pt total | center | 3 | always (opacity: active?1.0:0.20) | none | rect(36×20) + rect(18×22) | ZStack: monitor(offset y=-11) + desk(offset y=+11)。ZStack ごと .position(p) |
| desk_unit_1 | L3 | **A** | office_desk_01 + office_monitor_01 | 0.45 | 0.28 | 36pt | 44pt | center | 3 | always (opacity: active?1.0:0.20) | none | 同上 | |
| desk_unit_2 | L3 | **A** | office_desk_01 + office_monitor_01 | 0.75 | 0.32 | 36pt | 44pt | center | 3 | always (opacity: active?1.0:0.20) | none | 同上 | |

### 5.3 バックローキャラ（seats 0–2）

| element_id | layer | asset_source | asset_name_or_path | x | y | width | height | anchor | z_index | visibility_condition | motion_profile | fallback_asset | notes |
|-----------|-------|-------------|-------------------|---|---|-------|--------|--------|---------|---------------------|---------------|---------------|-------|
| char_0 (founder) | L4 | **A** | char_founder_01 | 0.16 | 0.30 | 20pt | 28pt | center | 5 | activeEmp ≥ 1 | sceneState.motionProfile | person.fill (sf) | animPos: seat + sine/cosine offset - 8pt(y) |
| char_1 (dev) | L4 | **A** | char_staff_dev_01 | 0.45 | 0.28 | 20pt | 28pt | center | 5 | activeEmp ≥ 2 | same | person.fill | phase offset: +index |
| char_2 (pm) | L4 | **A** | char_staff_pm_01 | 0.75 | 0.32 | 20pt | 28pt | center | 5 | activeEmp ≥ 3 | same | person.fill | |

### 5.4 装飾・奥面（L5a）

| element_id | layer | asset_source | asset_name_or_path | x | y | width | height | anchor | z_index | visibility_condition | motion_profile | fallback_asset | notes |
|-----------|-------|-------------|-------------------|---|---|-------|--------|--------|---------|---------------------|---------------|---------------|-------|
| desk_02 | L5a | **A** | office_desk_02 | 0.87 | 0.52 | 30pt | 30pt | center | 6 | showDesk2 | none | EmptyView | 追加デスク、奥右側 |
| server_01 | L5a | **A** | office_server_01 | 0.95 | 0.40 | 24pt | 40pt | center | 6 | showServer | none | EmptyView | |

### 5.5 フロントロー家具（seats 3–5）

| element_id | layer | asset_source | asset_name_or_path | x | y | width | height | anchor | z_index | visibility_condition | motion_profile | fallback_asset | notes |
|-----------|-------|-------------|-------------------|---|---|-------|--------|--------|---------|---------------------|---------------|---------------|-------|
| desk_unit_3 | L5b | **A** | office_desk_01 + office_monitor_01 | 0.26 | 0.72 | 36pt | 44pt | center | 7 | always (opacity: active?1.0:0.20) | none | rect | x=0.26（300pt幅での衝突回避） |
| desk_unit_4 | L5b | **A** | office_desk_01 + office_monitor_01 | 0.56 | 0.68 | 36pt | 44pt | center | 7 | always (opacity: active?1.0:0.20) | none | rect | |
| desk_unit_5 | L5b | **A** | office_desk_01 + office_monitor_01 | 0.83 | 0.72 | 36pt | 44pt | center | 7 | always (opacity: active?1.0:0.20) | none | rect | |

### 5.6 装飾・手前面（L5c）

| element_id | layer | asset_source | asset_name_or_path | x | y | width | height | anchor | z_index | visibility_condition | motion_profile | fallback_asset | notes |
|-----------|-------|-------------|-------------------|---|---|-------|--------|--------|---------|---------------------|---------------|---------------|-------|
| plant_01 | L5c | **A** | office_plant_01 | 0.07 | 0.82 | 24pt | 32pt | center | 8 | showPlant | none | EmptyView | 手前左、最前景 |

### 5.7 フロントローキャラ（seats 3–5）

| element_id | layer | asset_source | asset_name_or_path | x | y | width | height | anchor | z_index | visibility_condition | motion_profile | fallback_asset | notes |
|-----------|-------|-------------|-------------------|---|---|-------|--------|--------|---------|---------------------|---------------|---------------|-------|
| char_3 (dev) | L6 | **A** | char_staff_dev_01 | 0.26 | 0.72 | 20pt | 28pt | center | 9 | activeEmp ≥ 4 | same as backrow | person.fill | y=-8pt offset適用後 |
| char_4 (pm) | L6 | **A** | char_staff_pm_01 | 0.56 | 0.68 | 20pt | 28pt | center | 9 | activeEmp ≥ 5 | same | person.fill | |
| char_5 (dev) | L6 | **A** | char_staff_dev_01 | 0.83 | 0.72 | 20pt | 28pt | center | 9 | activeEmp ≥ 6 | same | person.fill | |

### 5.8 演出・UI オーバーレイ

| element_id | layer | asset_source | asset_name_or_path | x | y | width | height | anchor | z_index | visibility_condition | motion_profile | fallback_asset | notes |
|-----------|-------|-------------|-------------------|---|---|-------|--------|--------|---------|---------------------|---------------|---------------|-------|
| atmosphere | L7 | none | LinearGradient (atmosphereColor→clear) | 0 | 0 | 1.0 | 1.0 | topLeading | 10 | always (opacity=0 if normal) | danger: 1.5Hz pulse | — | .clipShape(RoundedRectangle(10)) |
| event_beacon | L8 | **A** | cat_{category}_icon (XCAssets) | 0.92 | 0.14 | 50pt glow / 36pt disc | 50pt | center | 11 | focusCategory != nil | 2Hz bob | sf.fallbackSymbol | position: (size.width-28, 28) |
| info_strip | L9 | none | SwiftUI HStack | 0 | 0.85 | 1.0 | 0.15 | bottomLeading | 12 | always | none | — | VStack{Spacer;strip} でbottom固定 |

---

## 6. 受け入れチェックリスト

### デザイン観点

- [ ] デスクとモニターが1つのユニットとして描画され、分離していない
- [ ] バックローのキャラクターがフロントローのデスクより奥（Z-order 低い）に見える
- [ ] seed → growth → mature でシーンが目に見えて賑やかになる（席数・家具の変化）
- [ ] danger リスク時に赤いグラデーションが画面下部から立ち上がって見える
- [ ] plant は手前左、server は奥右に配置され、視線の奥行きガイドになっている
- [ ] EventBeacon が 36pt の円とその外側のグローリングで正しく表示される
- [ ] 壁面ストリップ（上部）が光モード・ダークモード両方で自然に見える

### バグ観点

- [ ] 300pt 幅（最小）でデスクユニット同士が横方向に重ならない
- [ ] アセット欠損時（TinyAsset が nil を返す）にレイアウトが崩れない
- [ ] BackRow キャラが BackRow デスクより手前（高Z）に描画されている
- [ ] FrontRow 家具が BackRow キャラより手前に描画されている
- [ ] 非アクティブ席（opacity 0.20）のデスクが `position()` の基準点を持ち、 EmptyView にならない

### パフォーマンス観点

- [ ] TimelineView 更新間隔が `1/8s`（8fps）以上にならない
- [ ] 同時アニメーション View 数が 6（最大 activeEmployeeCount）を超えない
- [ ] 大気オーバーレイの opacity 計算に `abs(sin(time))` のみ使用し、 複数の三角関数ネストがない
- [ ] `@ViewBuilder` 内でループや重い計算を行わない（`let` で先に計算する）

### 仕様整合観点

- [ ] growthStage の条件が OfficeSceneState.swift と一致している（コードコピー禁止、OfficeSceneState.from() の判定を使う）
- [ ] showPlant / showDesk2 / showServer の条件が OfficeSceneState.from() から来ている（View 側で再計算しない）
- [ ] activeEmployeeCount は OfficeSceneState.activeEmployeeCount を参照（View で min/max を再計算しない）
- [ ] リスクカラーは TinyTokens.ColorToken.borderDanger 等を使用（ハードコード禁止）

---

*作成: 2026-02-27（Claude Code / Office Scene 内部デザイン設計担当）*
*次回更新タイミング: 推奨案 B の実装後、崩れ確認チェックリスト合格で「確定版」に昇格*
