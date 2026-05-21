# AGENTS.md — 편의점 가는 길

이 저장소는 Godot 4.x 기반의 2D 탑다운 단편 공포게임 **「편의점 가는 길」**을 구현하기 위한 프로젝트입니다. Codex는 이 파일을 저장소의 지속 지침으로 사용한다.

## 0. 가장 먼저 읽을 문서

작업 시작 시 반드시 다음 순서로 읽는다.

1. `AGENTS.md`
2. `GAME_MASTER_PLAN.md`
3. `CODEX_GOAL_PROMPT.md`가 있으면 현재 목표와 종료 조건 확인
4. 기존 `project.godot`, `scenes/`, `scripts/`, `data/`, `tools/` 상태 확인

`AGENTS.md`는 저장소의 작업 규칙이다. 세부 구현 내용은 `GAME_MASTER_PLAN.md`를 우선한다.

---

## 1. 프로젝트 목표

여자친구를 모티브로 한 주인공이 밤늦게 시골 변두리 길을 지나 편의점에 다녀오려는 **8~10분 내외의 짧은 탑다운 공포 어드벤처 게임**을 완성한다.

플레이 흐름은 다음과 같다.

```text
집 → 어두운 시골길 → 첫 위협/추격 → 스프레이 사용 → 불 켜진 편의점 도착 → 문 잠김 → 스프레이 없음 → 최종 추격 → 남자친구 차량 구조 → 따뜻한 엔딩
```

최종 결과물은 **처음부터 엔딩까지 플레이 가능한 Godot 프로젝트**여야 한다.

---

## 2. 기술 스택

- Engine: Godot 4.x
- Language: GDScript
- View: 2D top-down
- Art style: 간단한 픽셀풍 또는 임시 도형 기반 2D
- Plugins: 기본적으로 사용하지 않는다. 외부 플러그인은 꼭 필요할 때만 제안하고, 자동 추가하지 않는다.
- Target build: Windows Desktop 우선. Export preset이 없으면 플레이 가능한 프로젝트 상태까지만 완성한다.

---

## 3. 핵심 제품 원칙

1. **완성 우선**: 그래픽보다 시작-진행-엔딩이 가능한 구조를 먼저 만든다.
2. **작은 범위**: 10분짜리 게임에 맞게 맵, 시스템, 적 종류를 제한한다.
3. **선물 같은 공포**: 무섭지만 불쾌하거나 과도하게 잔혹하지 않게 만든다.
4. **주인공 존중**: 주인공은 수동적인 피해자가 아니라 위기에서 버티고 도망치는 인물로 연출한다.
5. **개인화 가능성**: 이름, 별명, 좋아하는 간식, 말투는 나중에 쉽게 바꿀 수 있게 상수나 데이터로 분리한다.
6. **아오오니 감성 참고, 직접 제작**: 기존 게임의 에셋, 캐릭터, 음악, 맵을 복제하지 않는다.

---

## 4. 저장소 구조

가능하면 아래 구조를 만든다.

```text
res://
  project.godot
  AGENTS.md
  GAME_MASTER_PLAN.md
  CODEX_GOAL_PROMPT.md

  scenes/
    Main.tscn
    Player.tscn
    Enemy.tscn
    BoyfriendCar.tscn
    UI_Dialogue.tscn
    UI_HUD.tscn

  scripts/
    autoload/
      game_manager.gd
      dialogue_manager.gd
      audio_manager.gd
    player.gd
    enemy_chase.gd
    spray_controller.gd
    interaction_area.gd
    trigger_event.gd
    convenience_store_door.gd
    boyfriend_car.gd
    camera_controller.gd
    hud.gd

  data/
    dialogues.json
    game_config.json

  assets/
    sprites/
      player/
      enemy/
      map/
      objects/
    audio/
      bgm/
      sfx/
    fonts/

  tools/
    validate_project.gd

  .logs/
    progress.md
```

처음부터 모든 씬을 완벽히 만들 수 없으면, `Main.tscn` + 런타임 노드 생성 방식으로 플레이 가능한 버전을 먼저 완성한 뒤 점진적으로 분리한다.

---

## 5. 필수 게임 시스템

반드시 구현한다.

- 플레이어 이동
  - WASD 및 방향키
  - Shift 달리기
  - 충돌 처리
- 조사 상호작용
  - E 키
  - 편의점 문, 집 문, 주요 오브젝트 조사
- 대화창
  - 순차 대사 출력
  - 입력으로 다음 대사 진행
  - 대화 중 이동 제한
- 이벤트 트리거
  - Area2D 기반
  - 한 번만 발동되는 트리거 지원
- 추격 적
  - 평소 비활성
  - 특정 트리거 후 활성화
  - 플레이어 방향으로 추격
  - 플레이어와 접촉 시 게임오버 또는 체크포인트 재시작
- 캡사이신 스프레이
  - F 키
  - 사용 가능 횟수 1회
  - 첫 위협을 쫓아내는 데 사용
  - 최종 추격 시 잔량 없음 메시지 출력
- 편의점 문 잠김 이벤트
  - 편의점은 불이 켜져 있지만 문이 잠겨 있음
  - 조사 후 최종 추격 단계로 전환
- 최종 구조 이벤트
  - 남자친구 차량 등장
  - 헤드라이트/경적/대사 연출
  - 주인공 구조 후 엔딩
- HUD
  - 스프레이 잔량
  - 간단한 목표 문구
- 체크포인트
  - 첫 추격 직전
  - 편의점 도착 직후

---

## 6. 게임 상태 모델

`GameManager`는 다음 상태를 가진다.

```gdscript
enum GameStage {
    INTRO_HOME = 0,
    WALK_TO_STORE = 1,
    FIRST_THREAT = 2,
    SPRAY_USED = 3,
    STORE_REACHED = 4,
    FINAL_CHASE = 5,
    RESCUE = 6,
    ENDING = 7,
    GAME_OVER = 8,
}
```

상태 전환은 명확해야 하며, 트리거가 중복 발동하지 않도록 방어 코드를 둔다.

---

## 7. 조작 방식

| 입력 | 기능 |
|---|---|
| WASD / 방향키 | 이동 |
| Shift | 달리기 |
| E | 조사 / 대화 진행 |
| F / Space | 캡사이신 스프레이 사용 |
| Esc | 일시정지 또는 종료 메뉴. 최소 구현에서는 생략 가능 |

InputMap이 없으면 `project.godot`에 설정하거나 코드에서 기본 입력을 처리한다.

---

## 8. 구현 순서

항상 아래 순서를 따른다.

1. Godot 프로젝트 기본 구조 생성
2. 플레이어 이동 + 카메라 추적
3. 작은 맵과 충돌 영역 생성
4. 대화창/HUD 구현
5. 집에서 편의점까지 이동 가능한 MVP 완성
6. 첫 위협/추격 구현
7. 스프레이 구현
8. 편의점 문 잠김 이벤트 구현
9. 최종 추격 구현
10. 남자친구 차량 구조 컷신 구현
11. 게임오버/체크포인트 구현
12. 사운드/조명/화면 흔들림 등 공포 연출 추가
13. 검증 스크립트와 수동 QA 체크리스트 작성

---

## 9. Codex 작업 규칙

- 임의로 범위를 키우지 않는다.
- 세이브/로드, 복잡한 인벤토리, 다중 엔딩, 퍼즐, 전투 시스템은 구현하지 않는다.
- 막히면 그래픽 퀄리티를 낮추고 플레이 가능한 구조를 우선한다.
- 에셋이 부족하면 도형, 단색 Sprite2D, Label, ColorRect 등 임시 에셋으로 대체한다.
- 코드 변경 후 가능한 경우 즉시 실행/검증한다.
- 큰 변경은 `.logs/progress.md`에 체크포인트 단위로 기록한다.
- 새 스크립트에는 역할이 분명한 주석을 짧게 남긴다.
- Godot이 설치되어 있지 않거나 실행 명령을 찾을 수 없으면, 프로젝트 파일과 검증 방법을 완성하고 `.logs/progress.md`에 차단 사유를 기록한다.

---

## 10. 검증 명령

로컬 환경에 따라 Godot 실행 파일 이름은 다를 수 있다. 먼저 다음 후보를 확인한다.

```bash
godot --version
godot4 --version
Godot --version
```

가능하면 다음 검증을 실행한다.

```bash
# 프로젝트 경로에서 리소스 import
godot --headless --path . --import

# 프로젝트 검증 스크립트 실행
godot --headless --path . --script res://tools/validate_project.gd

# 검증 스크립트 파싱 확인
godot --headless --path . --check-only --script res://tools/validate_project.gd
```

Export preset이 구성되어 있을 때만 다음을 실행한다.

```bash
mkdir -p builds/windows
godot --headless --path . --export-release "Windows Desktop" builds/windows/convenience_store_road.exe
```

검증 명령이 실패하면 실패 원인을 정리하고, 가능한 최소 수정 후 재시도한다.

---

## 11. 완료 조건

Codex는 다음 조건이 모두 만족될 때까지 작업을 계속한다.

- `project.godot`가 존재한다.
- `Main.tscn` 또는 실행 가능한 메인 씬이 존재한다.
- 플레이어가 이동하고 벽과 충돌한다.
- 집에서 출발해 편의점까지 갈 수 있다.
- 첫 추격이 발생한다.
- 스프레이 1회 사용으로 첫 위협을 쫓아낼 수 있다.
- 편의점 문이 잠겨 있다는 대사가 나온다.
- 스프레이가 없는 상태에서 최종 추격이 발생한다.
- 남자친구 차량 구조 이벤트가 발생한다.
- 엔딩 대사가 출력된다.
- 게임오버 또는 체크포인트 재시작이 동작한다.
- `tools/validate_project.gd`가 핵심 씬/스크립트 존재 여부를 검증한다.
- `.logs/progress.md`에 구현 내역, 검증 결과, 남은 이슈가 기록되어 있다.

---

## 12. 품질 기준

- 플레이타임 목표: 8~10분
- 게임 난이도: 낮음. 선물용이므로 2~3회 안에 클리어 가능해야 한다.
- 추격 공포는 난이도보다 연출 중심으로 만든다.
- 대사는 짧고 자연스럽게 유지한다.
- 사운드가 없어도 진행 가능해야 하며, 사운드는 추가 몰입 요소로만 둔다.
- 최종 엔딩은 따뜻하고 귀엽게 마무리한다.

---

## 13. 금지 사항

- 실제 인물의 민감한 개인정보를 코드/파일명/대사에 직접 넣지 않는다. 별명과 플레이스홀더를 사용한다.
- 잔혹하거나 불쾌한 연출을 과도하게 넣지 않는다.
- 기존 상용 게임의 에셋, 음악, 캐릭터, 맵을 복제하지 않는다.
- 기능 욕심으로 범위를 확장하지 않는다.
- 검증 없이 “완료”라고 보고하지 않는다.

---

## 14. 최종 보고 형식

작업 종료 시 다음 형식으로 보고한다.

```text
완료 요약:
- 구현한 기능
- 실행 방법
- 검증 결과
- 남은 이슈
- 다음에 사람이 직접 확인해야 할 항목
```
