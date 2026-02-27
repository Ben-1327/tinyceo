# Event Asset / Logic Map (v0.1.1)

## 1. カテゴリ別アイコン割当

| Category | UIラベル | アセット名 | fallback |
| --- | --- | --- | --- |
| STRATEGY | 戦略 | `cat_strategy_icon` | `target` |
| HIRING | 採用 | `cat_hiring_icon` | `person.2.fill` |
| PROCESS | 業務改善 | `cat_process_icon` | `wrench.and.screwdriver.fill` |
| SALES | 営業 | `cat_sales_icon` | `chart.line.uptrend.xyaxis` |
| PRODUCT | プロダクト | `cat_product_icon` | `shippingbox.fill` |
| FINANCE | 資金 | `ui_cash_icon` | `yensign.circle.fill` |
| CRISIS | 危機対応 | `cat_crisis_icon` | `exclamationmark.triangle.fill` |
| CULTURE | 文化 | `cat_culture_icon` | `heart.fill` |
| AI | AI | `cat_ai_icon` | `sparkles` |
| INVESTOR | 投資家 | `cat_investor_icon` | `person.3.fill` |
| EXIT | EXIT | `cat_exit_icon` | `flag.checkered` |

## 2. オフィス演出ロジック

- 社員スプライト: Founder + DEV/PM を team size に応じて増加
- オブジェクト表示:
  - `office_plant_01`: `day >= 10` または `hasProductLaunched`
  - `office_desk_02`: `teamSize >= 2` または `chapter >= CH2`
  - `office_server_01`: `aiXP > 0` または `chapter >= CH2`
- 動き:
  - `RiskLevel == danger` で揺れ速度/振幅を増加
  - Inbox先頭カテゴリの `motion profile` に応じて社員の速度/振幅を補正
  - 先頭カテゴリは `EventBeacon` として右上に表示

## 3. カード発生ロジック（実時間）

- 固定120分を廃止し、次回間隔を毎回サンプルする方式へ変更
- `state.flags.__nextCardIntervalRealMinutes` に次回間隔（分）を保持
- 区間レンジ:
  - 0〜179分: `30...70`（初期は多め）
  - 180〜479分: `55...105`
  - 480分以降: `80...160`
- 補正:
  - Inbox滞留（2件以上）で間隔を延長
  - キャッシュ/健康/技術負債が悪化時は間隔を短縮

## 4. 初期フェーズのカード内容バイアス

- 開始6時間は STRATEGY/SALES/PRODUCT/HIRING/PROCESS を優先
- AI/CRISIS/INVESTOR/EXIT は抑制
- 開始4時間の CRISIS は、指標が重篤でない限り強く抑制
