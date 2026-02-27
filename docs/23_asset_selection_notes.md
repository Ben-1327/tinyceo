# 23 Asset Selection Notes (v0.1)

Acquired on 2026-02-27 based on `docs/20_asset_acquisition_playbook.md`.

## 1. Raw acquisition result
- Kenney: `ui-pack`, `game-icons`, `tiny-town` downloaded and extracted.
- 2dPig: `pixel-office` downloaded and extracted.
- OpenGameArt: CC0-only assets downloaded from:
  - `indoor-office-appliances`
  - `office-8x8-tileset`

## 2. Curated mapping
- `assets/curated/ui/ui_cash_icon.png`
  - Source: `assets/raw/kenney/game-icons/PNG/Black/1x/medal1.png`
  - Reason: high readability at small size.
- `assets/curated/ui/ui_health_icon.png`
  - Source: `assets/raw/kenney/game-icons/PNG/Black/1x/plus.png`
  - Reason: conventional health metaphor.
- `assets/curated/ui/ui_techdebt_icon.png`
  - Source: `assets/raw/kenney/game-icons/PNG/Black/1x/gear.png`
  - Reason: engineering/debt context fit.
- `assets/curated/ui/ui_reputation_icon.png`
  - Source: `assets/raw/kenney/game-icons/PNG/Black/1x/star.png`
  - Reason: reward/reputation metaphor.
- `assets/curated/ui/ui_card_bg.png`
  - Source: `assets/raw/kenney/ui-pack/PNG/Grey/Default/button_rectangle_depth_flat.png`
  - Reason: neutral panel texture for card background.

- `assets/curated/office/office_desk_01.png`
- `assets/curated/office/office_desk_02.png`
- `assets/curated/office/office_plant_01.png`
- `assets/curated/office/office_server_01.png`
- `assets/curated/office/office_monitor_01.png`
  - Source: `assets/raw/2dpig/pixel-office-asset-pack/PixelOfficeAssets.png`
  - Reason: coherent office visual language across furniture set.

- `assets/curated/characters/char_staff_dev_01.png`
- `assets/curated/characters/char_staff_pm_01.png`
- `assets/curated/characters/char_founder_01.png`
  - Source: `assets/raw/2dpig/pixel-office-asset-pack/PixelOfficeAssets.png`
  - Reason: style consistency with office objects.

- `assets/curated/office/office_tilemap_oga_indoor.png`
  - Source: `assets/raw/opengameart/indoor-office-appliances/office-tilemap.png`
  - Reason: fallback office tile composition base.

## 3. Notes for implementation
- v0.1 can keep SF Symbols as primary; curated assets are drop-in candidates for Phase 2/3.
- Some 2dPig items were cropped from atlas tiles (`PixelOfficeAssets.png`) and may require further polish when integrated into final UI scale.
