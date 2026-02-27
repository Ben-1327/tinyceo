# Data schema overview

このゲームは **データ駆動** で実装する前提。実装者はこの `data/` を読み込む。

## data/balance.json
- 時間・経済・ワーク変換・ダイナミクス（Debt/Health/AI）などの「数値の真実」

## data/activity_rules.json
- アクティブアプリ/ドメイン → カテゴリ変換ルール
- モード（FOCUS/RESEARCH/BREAK）の扱い

## data/roles.json
- 役割定義（給与、日次WorkUnits出力）

## data/traits.json
- 特性（トレイト）定義。社員生成時に付与し、出力/リスクに影響。

## data/policies.json
- 制度（Policy）定義。導入費・維持費・効果。

## data/facilities.json
- オフィス設備。コストと効果。

## data/projects.json
- プロジェクトテンプレ（受託/プロダクト/社内）
- 工数（discipline別 WorkUnits）と報酬
- 生成ルール（strategyに応じた比率など）

## data/progression.json
- Chapter（章）と解放条件・解放内容

## data/cards.json
- CEOカード本体
- category, weight, cooldown, conditions, options, effects
