# 18 Claude Code Design Brief

このファイルは、Claude Code に UI/UX デザイン作業を依頼するためのブリーフ。
「背景説明 + 読むべき資料 + 依頼範囲 + 成果物」を1つにまとめている。

## 1. プロジェクト背景（共有すべき前提）
- プロダクト: TinyCEO（macOS メニューバー常駐のITベンチャー経営シム）
- 現状: ゲームロジックとデータ駆動コアは先行実装済み
- 今回依頼: UI/UX とビジュアル設計（デザイン領域のみ）
- 重要: ロジック・バランス・カード効果は固定。変更対象外

## 2. Claude Code に読むよう指示する資料
必読（優先順）:
1. `docs/15_design_handoff.md`
2. `docs/14_implementation_decisions.md`
3. `docs/10_ux_and_notifications.md`
4. `docs/12_privacy_and_telemetry.md`
5. `docs/00_overview.md`
6. `docs/19_github_collaboration_workflow.md`
7. `docs/20_asset_acquisition_playbook.md`

必要に応じて参照:
- `docs/11_art_audio_and_assets.md`
- `data/cards.json`

## 3. 依頼範囲（やってほしいこと）
- メニューバーアプリ前提の画面構造を設計
- 通常時/危機時を含む主要画面モックを作成
- UIコンポーネント仕様を定義
- デザイントークンを定義（Color/Type/Spacing/Radius/Shadow）
- 実装者が迷わない handoff 情報を整理

## 4. 依頼範囲外（やらないこと）
- `data/*.json` の変更
- 経済/進行/カード効果ロジックの変更
- システム処理順（tick/day/cycle）の変更
- プライバシー方針（ローカル完結、内容非収集）の緩和

## 5. 成果物（納品してほしいもの）
1. 画面フロー図（初回起動〜通常運用〜危機対応）
2. 主要画面モック（通常/危機状態を最低1セットずつ）
3. コンポーネント仕様（状態、サイズ、余白、タイポ、色）
4. デザイントークン定義
5. アイコン/イラスト利用ルール
6. 実装注記（エンジニア向け）

## 6. 受け入れ基準
- KPIと危険状態を2秒以内に認識できる
- カード1件の処理を1分前後で完了できる
- 通知が過剰でない
- プライバシー不安を生む文言/演出がない
- 小ウィンドウでも可読性が落ちない

## 7. Claude Code への追加指示（推奨）
- まず「理解した範囲」と「不足情報」を箇条書きで返す
- 曖昧点は勝手に埋めず、先に質問する
- 提案は最低2案出し、理由付きで1案を推奨する
- 実装者向けに、画面ごとの状態遷移と例外ケースを明記する

## 8. GitHub 作業指示（Claude Code向け）
- 作業ブランチは `claude/design-*` を使う
- PRは「デザイン変更のみ」で作る（実装コードは変更しない）
- 変更対象は原則 `docs/**`（デザイン仕様）
- PR本文に必ず以下を記載:
  - 背景と目的
  - 変更ファイル一覧
  - 受け入れ基準への対応
  - 未解決事項 / 質問

## 9. アセット取得指示（重要）
- まず Claude Code 自身でアセット取得を試みる
  - 対象: Kenney / 2dPig Pixel Office / OpenGameArt office appliances
- 取得できた場合:
  - `docs/20_asset_acquisition_playbook.md` の保存先ルールに従って整理
- 取得できない場合:
  - ユーザー向けに「どこで、何を、どう取得し、どこへ配置するか」を具体的に手順化して提示
  - 手順は `docs/20_asset_acquisition_playbook.md` に沿って不足なく書く
