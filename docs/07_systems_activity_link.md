# 07 Systems: Activity Link（実作業連携 / AI連携）

## 絶対ルール（プライバシー）
- 取得するのは **カテゴリ情報**のみ
- 収集対象:
  - アクティブアプリ名（Bundle ID）
  - ブラウザの場合はドメイン（任意/許可制）
  - 最終入力からの経過（アイドル判定）
- 収集しない:
  - メッセージ内容、入力内容、ページ内容、コマンド引数など

## カテゴリ
- DEV（コーディング/自動化）
- COMMS（Slack/Discord/メール）
- OPS（Sheets/事務/運用）
- RESEARCH（調査/読み物）
- AI（ChatGPT/Codex/Claude など）
- BREAK（娯楽/休憩）

## “モード”でYouTube/Xを敵にしない
- Focus Mode: YouTube/X = BREAK（=進捗は出ない、でも休憩回復）
- Research Mode: YouTube/X = RESEARCH（市場調査として扱う）
- Break Mode: BREAK（TeamHealth回復寄り）

## 変換（カテゴリ→WorkUnits）
- 1サイクル内のカテゴリ滞在分を集計し、FounderのWorkUnitsに変換
- 詳細は `data/balance.json` の `workConversion` を参照

## AI連携（使うほど会社のAI成熟度が上がる）
- AIカテゴリの分数で `aiXP` が増える
- `aiXP` が閾値を越えると `aiMaturityLevel` が上昇（0〜5）
- aiMaturityが上がると:
  - 特定のCEOカードの選択肢が解放
  - WorkUnitsの効率が少し上がる（ただしTechDebtも増えやすい、などバランスを付ける）
