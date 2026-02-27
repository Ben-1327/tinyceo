# 06 Systems: CEO Cards（意思決定）

## 目的
- 2時間ごとに “社長をやってる” を感じさせる
- 単なる3択の繰り返しを避ける（条件解放/確率/ドラフト/追撃カード）

## カードのカテゴリ
- STRATEGY / HIRING / PROCESS / SALES / PRODUCT / FINANCE / CRISIS / CULTURE / AI / INVESTOR / EXIT

## カード生成（デッキ運用）ルール
1. サイクル開始時、Inboxが空いていればカードを生成
2. 候補カード群を「解放済みカテゴリ」「条件」「クールダウン」でフィルタ
3. `weight = baseWeight × stateMultiplier` で重み付け抽選
4. 同カテゴリ連打を避けるため、直近履歴でカテゴリ重みを減衰

### stateMultiplier例
- Cashが低い → FINANCE/SALESの重みUP
- TechDebtが高い → PROCESS/CRISISの重みUP
- TeamHealthが低い → CULTURE/PROCESSの重みUP
- AI利用が多い → AIカテゴリの重みUP

## 選択肢フォーマットの多様化（実装ルール）
- 基本は3択
- ただし以下で単調さを消す:
  - 条件付き選択肢（制度/役割/AI成熟度で解放）
  - 確率付き結果（成功率が会社状態で変わる）
  - ドラフト（5案から1つ選ぶ）= “採用/案件”で使う
  - 追撃カード（選択後、次サイクルにフォローアップ）

## 例: 条件付き
- “CI/CDがあるなら障害対応が軽い”
- “Salesがいるなら価格改定が成功しやすい”
