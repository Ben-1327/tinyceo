# 20 Asset Acquisition Playbook

このドキュメントは、アセット取得を「Claude Code が自動で実施する場合」と
「ユーザーが手動で取得する場合」の両方に対応する手順書。

## 1. 取得元（今回固定）
- Kenney（CC0）
- Pixel Office Asset Pack / 2dPig（CC0）
- OpenGameArt office appliances（CC0）

## 2. 保存先（リポジトリ内）
- `assets/raw/kenney/`
- `assets/raw/2dpig/`
- `assets/raw/opengameart/`
- `assets/curated/ui/`
- `assets/curated/office/`
- `assets/curated/characters/`
- `assets/licenses/`

## 3. Claude Code が取得できる場合（優先）
1. 上記3サイトから候補アセットを選定
2. 原本を `assets/raw/...` に保存
3. 使用候補のみ `assets/curated/...` に抽出
4. `assets/licenses/` に以下を記録
   - 取得元URL
   - アセット名
   - ライセンス種別（CC0）
   - 取得日
5. `docs/` に「採用/不採用理由」を短く残す

## 4. Claude Code が取得できない場合（ユーザー手動）

> Claude Code はネットワークアクセスによるファイル直接ダウンロードができないため、
> 以下の手順をユーザーが手動で実行してください。

---

### 4.1 取得元 A: Kenney（kenney.nl）

**取得 URL:**
```
https://kenney.nl/assets/tiny-town
https://kenney.nl/assets/game-icons
https://kenney.nl/assets/ui-pack
https://kenney.nl/assets/pixel-shmup  （小物スプライト）
```

**取得するもの（優先順）:**
1. **UI Pack** または **Game Icons** — メニューバーアイコン代替、小アイコン類
2. **Tiny Town** — 建物・机・オフィス家具タイル（office成長表現）
3. **Pixel Shmup** — 小キャラクター素材（スタッフアバター候補）

**取得手順:**
1. 上記URLをブラウザで開く
2. ページ内の「Download」ボタン（無料・ログイン不要）をクリック
3. ZIPファイルをダウンロード

**配置先:**
```
assets/raw/kenney/<pack-name>.zip   ← ZIP原本を保存
assets/raw/kenney/<pack-name>/      ← ZIP展開済みディレクトリ
assets/curated/ui/                  ← UI向け抽出素材
assets/curated/office/              ← オフィス背景・家具素材
assets/curated/characters/          ← スタッフアバター素材
```

**ライセンス記録先:**
```
assets/licenses/kenney.txt
```
記録内容:
```
Source: https://kenney.nl/assets/<pack-name>
Pack: <パック名>
License: CC0 1.0 Universal
Acquired: YYYY-MM-DD
```

---

### 4.2 取得元 B: 2dPig — Pixel Office Asset Pack

**取得 URL:**
```
https://2dpig.itch.io/pixel-office
```
> **注:** itch.io のページ URL は `pixel-office`（`assets/licenses/2dpig.txt` に記録済みの正式 URL）。
> `pixel-office-asset-pack` は旧記載の誤りのため修正。

**取得するもの:**
- Pixel Office Asset Pack 全体（オフィス机・椅子・PC・植物・会議室タイル）
- v0.1で特に使うもの: 机・PC・植物・小物（会社規模の成長を視覚化するため）

**取得手順:**
1. 上記URLをブラウザで開く
2. 「Download Now」ボタンをクリック（無料）
3. 金額入力欄に「0」を入力し「Download」を選択
4. ZIPファイルをダウンロード

**配置先:**
```
assets/raw/2dpig/pixel-office-asset-pack.zip
assets/raw/2dpig/pixel-office-asset-pack/
assets/curated/office/<curated-files>.png
```

**ライセンス記録先:**
```
assets/licenses/2dpig.txt
```
記録内容:
```
Source: https://2dpig.itch.io/pixel-office-asset-pack
Pack: Pixel Office Asset Pack
License: CC0 1.0 Universal
Acquired: YYYY-MM-DD
```

---

### 4.3 取得元 C: OpenGameArt（opengameart.org）

**取得 URL:**
```
https://opengameart.org/art-search?keys=office+tileset
https://opengameart.org/art-search?keys=office+appliances
```

**取得するもの（検索結果から選択）:**
- オフィスアプライアンス（PC・コーヒーメーカー・観葉植物等）
- CC0ライセンスのみ取得（ライセンス欄を必ず確認）

**取得手順:**
1. 上記URLで検索
2. 各アセットページで「License」が **CC0** であることを確認
3. ページ内「Download」からファイルをダウンロード（PNG推奨）

**配置先:**
```
assets/raw/opengameart/<asset-name>/
assets/curated/office/<curated-files>.png
```

**ライセンス記録先:**
```
assets/licenses/opengameart.txt
```
記録内容（素材ごとに追記）:
```
Source: https://opengameart.org/content/<slug>
Asset: <アセット名>
Author: <作者名>
License: CC0 1.0 Universal
Acquired: YYYY-MM-DD
```

---

### 4.4 curated ファイルのリネーム規則

実際に使う素材を `curated/` へコピーする際は、以下のリネーム規則に従う:

```
ui_cash_icon.png           ← KPI Cash アイコン
ui_health_icon.png         ← KPI TeamHealth アイコン
ui_techdebt_icon.png       ← KPI TechDebt アイコン
ui_reputation_icon.png     ← KPI Reputation アイコン
ui_card_bg.png             ← カード背景テクスチャ
office_desk_01.png         ← 机（初期）
office_desk_02.png         ← 机（グレードアップ後）
office_plant_01.png        ← 観葉植物
office_server_01.png       ← サーバーラック
office_monitor_01.png      ← PCモニター
char_staff_dev_01.png      ← スタッフアバター（DEV）
char_staff_pm_01.png       ← スタッフアバター（PM）
char_founder_01.png        ← Founderアバター
```

**解像度規則:**
- 基本: 16×16 または 32×32（ピクセルアート維持）
- @1x: 16pt / @2x: 32px / @3x: 48px の3サイズを準備（可能なら）
- PNG形式（透過背景必須）

---

## 5. 運用ルール
- ライセンス表記は必ず残す（CC0でも出典追跡のため）
- 重い未使用素材は `raw` に留め、`curated` へは必要分のみ置く
- 実装側は `curated` のみ参照する
- 取得後は `docs/21_design_spec_v01.md` のセクション7（アイコン使用トークン）と照合し、SF Symbols との差し替え可否を記録する

## 6. v0.1実装フェーズ別アセット優先度

| フェーズ | 優先アセット | 代替（アセット未取得時） |
|---------|------------|---------------------|
| Phase 1（MVP） | なし | SF Symbols のみで実装 |
| Phase 2（UI強化） | Kenney UI Pack / Game Icons | SF Symbols 継続 |
| Phase 3（オフィス表現） | 2dPig Pixel Office + Kenney Tiny Town | 省略（v0.2以降） |

