# 04 Systems: Projects（案件/プロダクト）

## プロジェクトの基本
プロジェクトは WorkUnits の蓄積で進む。

- discipline: DEV / DESIGN / SALES / OPS / PM / CS / RESEARCH
- 各プロジェクトは discipline ごとの必要WorkUnitsを持つ
- WorkUnits が満たされると完了

## プロジェクト種別
### Contract（受託）
- 例: Slack Bot、業務自動化、ダッシュボード、データ連携
- 完了報酬: Cash
- 副作用: TechDebt が増えやすい（無理すると）

### Product Feature（SaaS）
- MVP/機能追加/運用改善
- 完了報酬: MRR + Reputation（小）
- 副作用: 運用負荷（CS）増、TechDebt要管理

### Internal（社内）
- ドキュメント整備、CI/CD、採用基盤、サポート体制など
- 完了報酬: 放置耐性が上がる（裏バフ）

## プロジェクトの自動割当（実装指針）
- 会社の StrategySlider（受託↔プロダクト）で優先度を決定
- Crisis時は火消しプロジェクトが最優先
- プレイヤーは CEOカードで優先度を上書きできる

## “やりすぎ”の抑制
- 同時進行数には上限（初期 2、制度/PMで増える）
- 過多な同時進行は TeamHealth を落とし、TechDebt を増やす（現実的）
