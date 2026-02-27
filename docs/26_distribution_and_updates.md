# TinyCEO 配布とアップデート運用

最終更新: 2026-02-27

## 配布の基本方針
- 配布チャネル: GitHub Releases
- 形式: `DMG`（推奨）と `ZIP`
- 固定共有URL（最新版）:
  - DMG: `https://github.com/Ben-1327/tinyceo/releases/latest/download/TinyCEO-latest.dmg`
  - ZIP: `https://github.com/Ben-1327/tinyceo/releases/latest/download/TinyCEO-latest.zip`
- リリース一覧: `https://github.com/Ben-1327/tinyceo/releases`

## 友達に共有する内容
以下 2 つだけ共有すれば良いです。

1. ダウンロードURL（DMG推奨）
2. インストール手順（下記）

## 友達向けインストール手順（初回）
1. 上記DMGリンクを開いて `TinyCEO-latest.dmg` をダウンロード
2. DMGを開く
3. `TinyCEO.app` を `Applications` にドラッグ
4. `Applications` から `TinyCEO` を起動

注記:
- 初回だけ macOS の警告が出る場合は、`TinyCEO.app` を右クリックして `開く` を選択してください。

## 友達向けアップデート手順
1. TinyCEO を終了
2. 同じ固定URL `TinyCEO-latest.dmg` を再ダウンロード
3. `Applications` にドラッグして上書き
4. 起動

## データ保持（PCを汚さない設計）
- アプリ本体: `~/Applications/TinyCEO.app` または `/Applications/TinyCEO.app`
- セーブデータ: `~/Library/Application Support/TinyCEO/tinyceo.sqlite`
- 設定: `~/Library/Preferences/com.ben1327.tinyceo.plist`

アップデート時に `TinyCEO.app` を上書きしても、セーブデータは消えません。

## 開発者向け: リリース作成手順
タグ push だけで Release が自動作成されます。

1. リリースしたいコミットを `main` に反映
2. タグを作成して push
   - `git tag v0.1.1`
   - `git push origin v0.1.1`
3. GitHub Actions `release-macos` が実行され、以下を Releases に添付
   - `TinyCEO-v0.1.1.dmg`
   - `TinyCEO-v0.1.1.zip`
   - `TinyCEO-latest.dmg`
   - `TinyCEO-latest.zip`
4. 友達には固定URLを共有

## ローカルで配布物を作る場合
`scripts/build_release_artifacts.sh` を実行すると `dist/` に DMG/ZIP が出力されます。

例:
- `./scripts/build_release_artifacts.sh v0.1.1`

