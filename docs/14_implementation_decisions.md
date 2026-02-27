# 14 Implementation Decisions (v0.1 Fixed Spec)

このドキュメントは、実装時に解釈が割れていた点を固定するための「決定仕様」。
`docs/` 内で解釈が衝突した場合、**v0.1では本書を優先**する。

## 1. Platform / Architecture
- 実装スタック: **Swift 6 + SwiftUI + AppKit**
- 対応OS: **macOS 14+**
- 形態: メニューバー常駐アプリ（`NSStatusItem + NSPopover`）
- プロセス構成: 単一プロセス（常駐ヘルパー分離なし）
- 保存: ローカルSQLite（ゲーム状態 + イベントログ）
- データ読込: `data/*.json` を起動時に読み込み、実行中は読み取り専用として扱う

## 2. Distribution / Permission 方針
- v0.1 配布: **App Store必須にしない**
- 既定の配布チャネル:
  - Developer ID 署名 + Notarization + DMG（公式サイト / GitHub Releases）
- App Storeは将来の任意対応とし、v0.1の受け入れ条件には含めない
- 権限:
  - 通知: 任意（拒否されても進行可能）
  - ブラウザドメイン取得: opt-in（拒否時はアプリ分類のみで継続）
- 「内容を読まない」保証のため、収集単位はカテゴリ分数のみを永続化する

### 2.1 v0.1 で実施しないこと（配布）
- App Store向けの審査最適化作業
- App Store向けメタデータ・課金・レビューフロー整備
- App Sandbox制約を前提にした別実装分岐

### 2.2 将来App Store対応する場合の扱い
- v0.1コードをベースに、配布レイヤーのみ追加対応する
- ゲームロジックと `data/*.json` は不変（別ゲーム化を避ける）

## 3. Time / Tick / Cycle 決定
- シミュレーションtick: `60秒` ごと
- `isSessionActive == true` のときのみ tick を進める（`advanceTimeWhenIdle` が `true` の場合を除く）
- 1 tick で進む company time:
  - `companyMinutes += timeScaleCompanyMinPerRealMin`
- 1 company day = 1440 company minutes
- CEOカード間隔:
  - 「**アクティブ実時間120分**」を1サイクルとしてカード生成判定する

## 4. 1 tick の処理順（固定）
1. アクティブアプリ/ドメインからカテゴリを決定
2. Founderのカテゴリ変換で WorkUnits を加算
3. AIカテゴリなら `aiXP` を加算
4. BREAKカテゴリなら TeamHealth回復を加算
5. company time を進める
6. day境界を跨いだら company day 処理を実行

## 5. 1 company day の処理順（固定）
1. 社員の日次WorkUnitsを加算
2. プロジェクトへWorkUnitsを割当
3. 完了プロジェクト報酬を反映
4. 収支反映（MRR入金、固定費、給与、制度維持費）
5. Dynamics反映（TechDebt/TeamHealth/Reputationのドリフト）
6. Chapter解放条件チェック
7. CEOカード生成タイミングなら Inbox 処理

## 6. Multipliers / Clamp ルール
- 同種 multiplier は **乗算** で合成
- 加算系は単純加算
- 指標クランプ:
  - `techDebt`, `teamHealth`, `reputation` は `0..max`
  - `aiMaturityLevel` は `0..maxLevel`
  - WorkUnits は discipline ごとに `>= 0`

## 7. Card 生成ルール（固定）
- 候補条件:
  - category が chapter で解放済み
  - card `conditions` を満たす
  - cooldown中でない
- 抽選重み:
  - `baseWeight * product(weightMultipliers)`
- 候補0件:
  - そのサイクルは新規カード生成しない（無理に補充しない）

## 8. Inbox 上限時の未処理ペナルティ（固定値）
- 追加生成タイミングで Inbox が `maxInboxCards` に達していた場合:
  - `teamHealth -= 3`
  - `techDebt += 2`
  - `reputation -= 1`
- 追加カードは生成しない（溢れ分は破棄）

## 9. Card effects 適用順（固定）
1. 状態切替: `SET_STRATEGY`, `SET_FLAG`, `ADD_FLAG`
2. 解放/有効化: `UNLOCK_POLICY`, `ENABLE_POLICY`
3. エンティティ操作: `HIRE_RANDOM`, `ADD_PROJECT`, `ADD_TEMP_CAPACITY`
4. 数値変化: `ADD_CASH`, `ADD_DEBT`, `ADD_MRR`, `ADD_REPUTATION`, `ADD_TEAM_HEALTH`, `ADD_TECH_DEBT`, `ADD_AI_XP`, `ADD_LEADS`
5. 終了処理: `ENDGAME`

## 10. Ambiguous op の定義
- `ADD_FLAG`: `SET_FLAG` のエイリアス（同じ key なら上書き）
- `ADD_DEBT`:
  - `debtJPY += value`
  - `cashJPY += value`
- `ADD_TEMP_CAPACITY`:
  - `discipline`, `workUnitsPerDay`, `days` を使用
  - 省略時のデフォルトは `DEV`, `1`, `2`
  - 効果は「一時的な日次WorkUnits増加」（人員上限の増加には使わない）
- `HIRE_RANDOM`:
  - `value` 省略時、Hiring pool から1名採用
  - 役割重みは「不足discipline」と現在strategyで決定
- `ENDGAME`:
  - `endType` がなければカードIDで補完
  - `_MA` を含むIDは `MA_EXIT`
  - `_IPO` を含むIDは `IPO_EXIT`
  - それ以外は `GENERIC_END`

## 11. Condition 評価の定義
- 比較演算: `==`, `!=`, `>`, `>=`, `<`, `<=`
- 集合演算: `CONTAINS`, `NOT_CONTAINS`
- `chapterUnlocked >= CHx`:
  - 文字列比較ではなく、`progression.chapters` の定義順を序数化して比較

## 12. Hiring / Capacity 決定
- 初期チーム: Founder 1名
- 人員上限:
  - `baseEmployeeCapacity + facilities(CAPACITY_EMPLOYEES)`
  - `baseEmployeeCapacity` の既定値は `10`（BootstrapConfigで変更可能）
- `NEW_HIRE_RAMP_DAYS` のデフォルト: `5` company days
- trait付与:
  - 1〜2個ランダム
  - 同時付与しない組み合わせ:
    - `TR_PERFECTIONIST` と `TR_SHIP_FAST`
    - `TR_CALM` と `TR_BURNOUT_RISK`

## 13. Project 割当決定
- 同時進行上限:
  - 既定 `limits.maxConcurrentProjectsBase`
  - `MAX_CONCURRENT_PROJECTS` 効果で上書き
- Founderの出力は最優先プロジェクトに先に投入
- 残り社員出力は「不足WorkUnitsが大きい discipline」へ貪欲に割当

## 14. Bankruptcy 判定（固定）
- 判定タイミング: company day 終了時
- 倒産条件:
  - `cashJPY < 0` かつ
  - `debtJPY > maxDebtToMRRRatio * max(mrrJPY, 1)`
- それ以外は継続（資金不足状態として FINANCE/CRISIS カテゴリ重みを上げる）

## 15. v0.1 Scope Lock（カード表現）
- v0.1 のカードは **全て3択固定**
- 「確率結果」「ドラフト」「追撃カード」は v0.2 で導入
- 実装は拡張可能にしてよいが、v0.1では未使用として扱う

## 16. Data Consistency Decisions（この版で確定）
- `roles.json` の `COMMS` 出力は削除する
  - 理由: `COMMS` は「作業カテゴリ」であり、プロジェクトdisciplineではないため
- `CH3_SCALING` の `cardCategories` は v0.1 では空配列
  - 理由: 現データに `SCALING` カテゴリカードが未収録のため
