# ASSET_IMPLEMENTATION_GUIDE.md — 고정 에셋 구현 지침

이 문서는 Godot 4.x 2D 탑다운 공포게임 **「편의점 가는 길」**에서 사용자가 제공한 주인공, 남자친구, 자동차 자료를 변형 없이 구현하기 위한 에셋 헌장이다.

## 1. 핵심 원칙

제공된 캐릭터와 자동차 이미지는 이 프로젝트의 정체성이다. Codex는 이 에셋을 **그대로 사용**해야 하며, 원본 이미지의 형태를 바꾸는 작업을 하면 안 된다.

### 절대 금지

- 캐릭터 또는 자동차를 다시 그리기
- AI 이미지 생성/보정/업스케일/다운스케일로 대체하기
- 비율이 달라지는 확대/축소
- `scale.x != scale.y`인 비균등 스케일
- `scale.x < 0` 또는 `flip_h`로 좌우 반전하기
- 회전, 기울이기, 원근 왜곡, 찌그러뜨리기
- 색상 변경, 외곽선 변경, 표정/장식 변경
- 프레임별 투명 여백을 잘라내기
- 자동차에 헤드라이트나 그림자를 직접 그려 넣기

### 허용

- 런타임에서 **균등 스케일** 적용: `Vector2(s, s)`
- 위치 이동
- 레이어 순서 조정
- 별도 노드로 그림자/헤드라이트/상호작용 표시 추가
- Godot import를 위한 일반 리소스 등록
- 필요 시 형식 변환만 수행하되, 픽셀 크기/알파/비율/모양을 보존하고 `.logs/progress.md`에 기록

---

## 2. 에셋 배치 경로

프로젝트 루트에 다음 구조로 배치한다.

```text
res://
  assets/
    source/
      characters/
        hero_spritesheet.webp
        boyfriend_spritesheet.webp
      vehicles/
        silver_sedan_4view_grid.png
        silver_sedan_4view_sheet.png
        silver_sedan_front_3q.png
        silver_sedan_side.png
        silver_sedan_rear_3q.png
        silver_sedan_opposite_side.png
        silver_sedan_single.png
        silver_sedan_single_512w.png
        silver_sedan_single_1024w.png
      manifests/
        validation_hero.json
        validation_boyfriend.json
        vehicle_assets_manifest.json
  asset_manifest.lock.json
```

작업 중 파일명을 바꾸지 않는 것이 가장 좋다. 부득이하게 파일명을 바꾸면 `asset_manifest.lock.json`, `.logs/progress.md`, `tools/verify_asset_lock.py`를 함께 갱신한다.

---

## 3. 캐릭터 매핑

| 역할 | 파일 | 설명 |
|---|---|---|
| 주인공 | `assets/source/characters/hero_spritesheet.webp` | 꽃 장식이 있는 주인공 캐릭터 |
| 남자친구 | `assets/source/characters/boyfriend_spritesheet.webp` | 파란 나비넥타이가 있는 남자친구 캐릭터 |

두 캐릭터 시트는 동일한 격자 구조를 사용한다.

```text
전체 크기: 1536 x 1872
열: 8
행: 9
셀 크기: 192 x 208
```

프레임은 **셀 단위 전체 영역**으로 잘라 쓴다. 프레임마다 보이는 캐릭터 영역만 따로 자르지 않는다. 투명 여백까지 포함해야 애니메이션 흔들림이 줄어든다.

### 행별 애니메이션

| Row | 상태 | 사용 Column |
|---:|---|---|
| 0 | idle | 0~5 |
| 1 | running_right | 0~7 |
| 2 | running_left | 0~7 |
| 3 | waving | 0~3 |
| 4 | jumping | 0~4 |
| 5 | failed | 0~7 |
| 6 | waiting | 0~5 |
| 7 | running | 0~5 |
| 8 | review | 0~5 |

### Godot 구현 권장

- `Player.tscn`
  - `CharacterBody2D`
    - `AnimatedSprite2D`
    - `CollisionShape2D`
    - `Area2D` for interaction
- `BoyfriendCharacter.tscn` 또는 구조 컷신 내부 노드
  - `Node2D`
    - `AnimatedSprite2D`

`AnimatedSprite2D`는 `SpriteFrames`를 생성하여 `AtlasTexture.region`으로 프레임을 등록한다.

```gdscript
const SHEET_COLUMNS := 8
const SHEET_ROWS := 9
const CELL_SIZE := Vector2i(192, 208)

func make_region(row: int, column: int) -> Rect2i:
    return Rect2i(column * CELL_SIZE.x, row * CELL_SIZE.y, CELL_SIZE.x, CELL_SIZE.y)
```

방향 전환 시 `flip_h`를 쓰지 않는다. 오른쪽 달리기는 row 1, 왼쪽 달리기는 row 2를 사용한다. 위/아래 이동에는 row 7 `running` 또는 현재 방향의 idle/running을 사용한다.

---

## 4. 자동차 매핑

자동차는 남자친구 구조 이벤트에 사용한다.

| 목적 | 권장 파일 |
|---|---|
| 최종 구조 컷신의 주 차량 | `assets/source/vehicles/silver_sedan_side.png` 또는 `silver_sedan_front_3q.png` |
| 헤드라이트가 보이는 등장 연출 | `silver_sedan_front_3q.png` |
| 수평 진입 연출 | `silver_sedan_side.png` / `silver_sedan_opposite_side.png` |
| 대형 컷신 이미지 | `silver_sedan_single_1024w.png` 또는 `silver_sedan_single.png` |
| 여러 방향이 필요한 경우 | `silver_sedan_4view_grid.png` 또는 개별 방향 파일 |

자동차 역시 비율을 바꾸면 안 된다. `scale = Vector2(s, s)`만 사용한다.

`BoyfriendCar.tscn` 권장 구조:

```text
BoyfriendCar (Node2D)
  CarSprite (Sprite2D)       # 원본 자동차 PNG 사용
  Headlights (Node2D)        # 별도 Polygon2D/Light2D/ColorRect로 표현
  HonkAudio (AudioStreamPlayer2D, optional)
  RescueArea (Area2D)
  CollisionShape2D
```

헤드라이트는 자동차 이미지에 직접 합성하지 말고 별도 반투명 Polygon2D, PointLight2D, ColorRect 등으로 만든다.

---

## 5. 스케일 기준

처음 구현 시 권장값:

```gdscript
const CHARACTER_VISUAL_SCALE := 0.33
const CAR_VISUAL_SCALE := 0.45
```

단, 맵 크기에 맞게 조정할 수 있다. 반드시 다음 조건을 지킨다.

```gdscript
sprite.scale = Vector2(CHARACTER_VISUAL_SCALE, CHARACTER_VISUAL_SCALE)
car_sprite.scale = Vector2(CAR_VISUAL_SCALE, CAR_VISUAL_SCALE)
```

금지 예시:

```gdscript
sprite.scale = Vector2(0.33, 0.28) # 금지: 세로로 찌그러짐
sprite.flip_h = true               # 금지: 제공 프레임 대신 반전
sprite.rotation_degrees = 12        # 금지: 캐릭터 회전 변형
```

---

## 6. 검증 규칙

`tools/verify_asset_lock.py`를 만들어 `asset_manifest.lock.json`의 SHA-256, 파일 크기, 이미지 크기를 확인한다.

권장 실행:

```bash
python tools/verify_asset_lock.py
```

Godot 검증 스크립트 `tools/validate_project.gd`도 다음을 확인한다.

- `hero_spritesheet.webp` 존재
- `boyfriend_spritesheet.webp` 존재
- 자동차 파일 중 최소 하나 이상 존재
- `asset_manifest.lock.json` 존재
- 주인공/남자친구 애니메이션이 원본 시트의 192x208 full-cell region을 사용한다는 구현 주석 또는 설정 존재

---

## 7. 완료 조건에 추가

이 에셋 지침을 적용한 후의 완료 조건은 다음을 포함한다.

- 주인공은 `hero_spritesheet.webp`에서 표시된다.
- 남자친구는 `boyfriend_spritesheet.webp`에서 표시된다.
- 구조 차량은 제공된 silver sedan PNG 중 하나에서 표시된다.
- 캐릭터/자동차에 비균등 스케일, 좌우 반전, 회전, 재생성, 리터칭이 없다.
- `.logs/progress.md`에 사용한 파일명과 검증 결과가 기록된다.
