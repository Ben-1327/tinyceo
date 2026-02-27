# 16 Pre-Design Implementation Plan (Design Waiting OK)

このドキュメントは、UIデザイン確定前に実装を進めるための作業分割。
デザイン未確定でも、ゲームの中核は先に実装できる。

## 1. 先に実装してよい領域
- データ読み込みとバリデーション
- シミュレーションエンジン（tick/day/cycle）
- カード生成・条件判定・効果適用
- プロジェクト進行と報酬反映
- 経済処理（収支、借入、倒産判定）
- アクティビティ分類（Bundle ID / domain -> category）
- 永続化（SQLite）
- 通知スケジューラ（文面は仮）
- テスト基盤（ユニット/シナリオ）

## 2. デザイン確定まで待つ領域
- 最終レイアウト
- カラー/タイポ/余白/アイコン
- モーション/演出の最終仕様
- UI文言の最終トーン調整

## 3. 推奨実装順（依存順）
1. `data/*.json` のデコード層と整合性チェック
2. ドメインモデル（State, Metrics, Project, Card, Chapter）
3. Tick/Day/Cycleエンジン（`docs/14` の処理順準拠）
4. カードデッキエンジン（条件、cooldown、weight抽選）
5. Effect executor（`ADD_*`, `SET_*`, `ENDGAME`）
6. プロジェクト割当と完了判定
7. 経済更新（MRR, fixed cost, salary, debt）
8. Activity collector + category mapper
9. SQLite repository（save/load/snapshot）
10. 通知トリガ（カード到着、Crisis）
11. 最小UIシェル（デバッグ表示のみ）

## 4. デザインと独立させるための実装ルール
- UIは `ViewState` のみ参照し、計算ロジックを持たせない
- 画面文言は `Localizable.strings` 相当へ分離
- 色やフォントはトークン化されたキー経由で参照
- コンポーネントのサイズを固定値にしない（後で差し替え可能に）

## 5. 最小UIシェル（デザイン前）
- メニューバーアイコンを仮表示
- ポップオーバーにテキストだけで主要指標を出す
- Inbox件数と「次カードまで時間」を表示
- カード選択をリスト+ボタンで処理可能にする

## 6. 先に固めるべき技術契約（Design-Dev Contract）
- `GameViewState`（`SimulationEngine.makeViewState(state:)`）をUIの唯一の入力として固定
- `Action`（カード選択、設定切替）を固定
- `NotificationPayload`（タイトル、本文、重要度）を固定
- `RiskLevel`（normal/warn/danger）を固定

## 7. テスト（デザイン前に可能）
- JSON schema互換テスト
- シミュレーション再現テスト（同seedで同結果）
- カード条件判定テスト
- 倒産/救済シナリオテスト
- Inbox上限ペナルティテスト
- Activity分類テスト（モード切替含む）

## 8. 完了定義（デザイン受領前）
- CLIまたは仮UIで1週間相当のシミュレーションが安定実行できる
- セーブ/ロードで状態が一致する
- 主要シナリオテストがグリーン
- デザイン受領後はUI差し替え中心で進められる
