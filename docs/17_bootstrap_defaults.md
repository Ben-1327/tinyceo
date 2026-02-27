# 17 Bootstrap Defaults Decision (v0.1)

このドキュメントは、`BootstrapConfig` の既定値を固定するための決定記録。
本書の目的は、実装者間で初期状態の解釈が揺れないようにすること。

## 1. 決定値（採用）
- `startingReputation = 0`
- `startingTeamHealth = 50`
- `startingTechDebt = 0`
- `startingMRRJPY = 0`
- `startingDebtJPY = 0`
- `startingLeads = 0`
- `baseEmployeeCapacity = 10`
- `startingStrategy = BALANCED`

## 2. 決定理由
- `TeamHealth=50` は `workConversion.company.teamHealthSpeedBonusPerPointFrom50` の基準点であり、バフ/デバフがない中立開始になるため。
- `TechDebt=0` 開始は、序盤の失敗をプレイヤーの意思決定に帰属させやすく、初期不公平感を避けられるため。
- `Reputation=0`/`MRR=0`/`Debt=0` は「1人社長の立ち上げ」を最も素直に表現するため。
- `baseEmployeeCapacity=10` は v0.1 で施設システム未連携でも「〜10名スコープ」を塞がないため。
- `BALANCED` 開始は、受託/プロダクトの両路線を最初に閉じないため。

## 3. 検証メモ
- シミュレーション（6h/8h/10h/12h、seed 1..10）で早期倒産 0 件。
- 24h/40h でも破綻せず、`Not-punishing` 原則に反しない。
- コマンド（再現用）:
  - `swift test --build-path /tmp/tinyceo-build`
  - `swift run --build-path /tmp/tinyceo-build tinyceo validate-data`
  - `swift run --build-path /tmp/tinyceo-build tinyceo simulate --real-minutes 480 --seed 123 --db /tmp/tinyceo-dev.sqlite`

## 4. 注意点（将来調整）
- 「最初の受託を6〜10時間で達成」目標の厳密検証には、実ユーザー行動ログを使ったリプレイ計測が必要。
- v0.1 は bootstrap を安定優先で固定し、速度調整は `data/balance.json` 側ノブで行う。

