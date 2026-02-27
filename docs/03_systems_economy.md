# 03 Systems: Economy（経済）

## 主要指標
- Cash（現金）: 0で倒産
- MRR（月次継続売上）: SaaSが生む
- Overhead（固定費）: 家賃/ツール/サブスク等
- Salaries（人件費）: 社員給与
- Runway（何サイクル生きられるか）: 参考表示（派手にしない）

## 収益源
### 受託（Contract）
- 完了時に一括入金
- 受注は「Lead → Deal Offer → Accept」方式（Sales要素）
- 受託はキャッシュの安定、ただし TechDebt を溜めやすい（短納期の誘惑）

### SaaS（Product）
- 機能開発（Feature）で価値を上げる
- ローンチ後は MRR が毎サイクル入る（MRR/30 を 1日分として換算）
- チャーン（解約）イベントあり。TeamHealth/TechDebt/Quality が影響

## 支出
- 固定費（Overhead）: サイクルごとに控除
- 給与: サイクルごとに `monthlySalary / 30` を控除
- 制度/設備: 導入時に初期費用 + 維持費（任意）

## 経済の設計思想
- 早期は受託で食う → 中期にSaaS育成 → 収益が安定
- “放置の代償” は Cash だけでなく、TechDebt/TeamHealth で遅れて効く（じわっと苦しくなる）
