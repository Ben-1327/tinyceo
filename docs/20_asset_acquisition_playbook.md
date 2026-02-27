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
以下をユーザーに明示して依頼すること。

### 4.1 どこで取得するか
- Kenney: サイト内の office / UI / icon 系パック
- 2dPig: Pixel Office Asset Pack
- OpenGameArt: office appliances タイル素材

### 4.2 何を取得するか
- UI向けアイコン/小物
- オフィス背景や家具タイル
- キャラクター/スタッフ表現に使える素材
- 可能なら PNG + 元データ（zip）を保持

### 4.3 どう配置するか
- ダウンロード直後のzipは `assets/raw/<source>/` に保存
- 実際に使う素材だけ `assets/curated/<category>/` へコピー
- ファイル名は用途がわかる形にリネーム
  - 例: `office_desk_tile_01.png`, `ui_cash_icon.png`
- 同梱ライセンス情報やURLを `assets/licenses/` にテキストで保存

## 5. 運用ルール
- ライセンス表記は必ず残す（CC0でも出典追跡のため）
- 重い未使用素材は `raw` に留め、`curated` へは必要分のみ置く
- 実装側は `curated` のみ参照する

