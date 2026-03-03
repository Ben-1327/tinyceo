# TinyCEO Design + Core Engine Package

このフォルダは、設計ドキュメントとデータに加えて、デザイン確定前でも進められる **コア実装（Swift Package）** を含みます。  
**誰が実装しても同じ挙動・同じバランス・同じコンテンツ**になるように、仕様・データ定義・初期バランス・カード/プロジェクト/人材データを同梱しています。

- 世界観: 現実寄りの今っぽい **ITベンチャー**（1人社長スタート固定）
- 運用: macOS デスクトップ常駐（メニューバー想定）で軽量
- プレイ: **2時間に1回**の「CEOカード（意思決定）」が核（基本3択だが単調にならない設計）
- 実作業連動: Slack / Sheets / Browser / Terminal / AIツール等の「カテゴリ」だけを使い、**内容は収集しない**（プライバシー設計あり）
- 収益モデル: **受託 + SaaS（MRR）**の両建て

## 使い方（実装者向け）
1. `docs/` を読み、ループ・システム・UX方針を把握する
2. `docs/14_implementation_decisions.md` を読み、未定だった実装判断（処理順/演算子定義/権限方針）を固定する
3. `data/` の JSON を「唯一の真実（Single Source of Truth）」としてゲームを実装する
4. 実装上の自由度はあるが **数値・ロジック・カード内容**は `data/` に従うこと（変更すると別ゲームになる）

## 先行実装（デザイン前）
- データ検証: `swift run tinyceo validate-data`
- シミュレーション実行: `swift run tinyceo simulate --real-minutes 480 --seed 123 --db /tmp/tinyceo.sqlite`
- テスト: `swift test`
- UI連携ViewState: `SimulationEngine.makeViewState(state:)`（Runway/Inbox FULL判定を含む）
- メニューバーUI（v0.1実装フェーズ）: `swift run tinyceo-app`

## 実運用時の保存先（Dropbox外）
- `tinyceo-app` のセーブ/イベントDBは `~/Library/Application Support/TinyCEO/tinyceo.sqlite` に保存されます。
- このため、開発ディレクトリ（Dropbox配下）とは分離して運用できます。
- `tinyceo-app` は起動時に `data/*.json` を優先順で読み込みます:
  1. `TINYCEO_DATA_DIR`（指定時）
  2. アプリ同梱リソース（`Resources/Data`）
  3. カレントディレクトリから親方向に探索した `data/`

## ローカルインストール（Dropbox外で利用）
- `scripts/install_local_app.sh` を実行すると `~/Applications/TinyCEO.app` にインストールされます。
- 実行:
  - `./scripts/install_local_app.sh`
- 起動:
  - `open ~/Applications/TinyCEO.app`

## 友達向け配布（簡単インストーラー）
- `scripts/build_easy_installer.sh <version>` で、配布用ZIPを1ファイル生成します。
- 例:
  - `./scripts/build_easy_installer.sh v0.1.1`
- 生成物:
  - `dist/TinyCEO-Installer-v0.1.1.zip`
- 受け取り側はZIP解凍後、`Install TinyCEO.command` を実行するだけでインストールできます。

## 友達向け配布（Gatekeeper回避の推奨手順）
- 受け取り側が `Install *.command` / `TinyCEO.app` の検証エラーで止まる場合は、以下の1コマンドを使用してください。
- 最新版をインストール:
  - `bash -c "$(curl -fsSL https://raw.githubusercontent.com/Ben-1327/tinyceo/main/scripts/install_release.sh)"`
- バージョン指定でインストール:
  - `bash -c "$(curl -fsSL https://raw.githubusercontent.com/Ben-1327/tinyceo/main/scripts/install_release.sh)" -- v0.1.2`
- このスクリプトは、Release から DMG を取得して `TinyCEO.app` を配置し、quarantine属性を除去して起動します。

## フォルダ構成
- `docs/` : 仕様書（GDD / システム / UX / バランス / テスト）
- `data/` : ゲームデータ（バランス、カード、プロジェクト、役割、特性、制度、進行）
- `assets/` : 外部アセット（raw/curated/licenses）
- `references/` : 参照メモ（類似作・アセット・ライセンス等の出典メモ）

## 担当分離ガイド
- デザイン担当へ渡す専用仕様: `docs/15_design_handoff.md`
- デザイン待ちでも進める実装範囲: `docs/16_pre_design_implementation.md`
- Bootstrap既定値の決定記録: `docs/17_bootstrap_defaults.md`
- Claude Code向けデザイン依頼ブリーフ: `docs/18_claude_code_design_brief.md`
- GitHub共同開発ルール: `docs/19_github_collaboration_workflow.md`
- アセット取得/配置プレイブック: `docs/20_asset_acquisition_playbook.md`

## スコープ（v0.1）
- 1人社長 → 小チーム（〜10名）までをメインに遊べる
- Fundraising / IPO / M&A は **拡張しやすい骨格 + 主要イベントカード**を定義（Chapter追加で拡張）

作成日: 2026-02-27
