# 19 GitHub Collaboration Workflow

TinyCEO の実装を「Claude Code（デザイン） + Codex（機能実装）」で並行進行するための運用ルール。

## 1. 役割分担
- Claude Code:
  - UI/UX設計
  - デザイン仕様書
  - デザイントークン
  - モック/画面フロー
- Codex:
  - 全体設計整合
  - ゲームロジック
  - データ駆動実装
  - テスト/CI/永続化/配布

## 2. GitHub ブランチ運用
- `main`:
  - 常に動作する状態を維持
- Claude Code 用:
  - `claude/design-*`
- Codex 用:
  - `codex/feature-*`
  - `codex/fix-*`

## 3. ファイル責務（編集境界）
- Claude Code が主に編集:
  - `docs/15_design_handoff.md`
  - `docs/18_claude_code_design_brief.md`
  - 新規のデザイン仕様ドキュメント
- Codex が主に編集:
  - `Sources/**`
  - `Tests/**`
  - `Package.swift`
  - 実装仕様との整合が必要な `docs/**`
- 両者変更可だが、衝突時は Codex が最終整合を担当

## 4. PR ルール
- Claude Code のPRは「デザイン変更のみ」に絞る
- 実装コード変更が必要な提案は、PR本文で「実装依頼」として分離
- PR本文に必ず以下を含める:
  - 目的
  - 変更ファイル一覧
  - 受け入れ基準への対応
  - 未解決事項

## 5. マージ基準
- デザインPR:
  - ロジック/データ仕様に触れていない
  - `docs/15` と `docs/14` の制約を満たしている
- 実装PR:
  - `swift test --build-path /tmp/tinyceo-build` が通る
  - `swift run --build-path /tmp/tinyceo-build tinyceo validate-data` が通る

## 6. 衝突時の優先順位
1. `data/*.json`（ゲームの真実）
2. `docs/14_implementation_decisions.md`
3. デザイン仕様（`docs/15` 系）
4. 実装詳細

## 7. Issue ラベル（推奨）
- `design`
- `core-engine`
- `balance`
- `test`
- `docs`

