# GAME_MASTER_PLAN.md — 「편의점 가는 길」 구현 마스터 문서

이 문서는 Codex가 `/goal`로 오래 작업하더라도 한 번에 완성 가능한 방향으로 Godot 4.x 2D 탑다운 공포게임을 구현하기 위한 마스터 계획서다.

---

## 1. 게임 한 줄 정의

**밤늦게 간식을 사러 편의점에 가던 주인공이 정체불명의 위협을 피해 도망치고, 마지막에는 남자친구의 도움으로 무사히 돌아오는 8~10분짜리 2D 탑다운 공포 어드벤처.**

---

## 2. 의도와 톤

이 게임은 이벤트성 선물 게임이다. 공포게임을 좋아하는 여자친구가 직접 주인공이 된 듯한 느낌을 받도록 만든다.

### 핵심 감정선

```text
귀여운 출발 → 조용한 불안 → 첫 위협 → 안도 → 편의점 문 잠김 → 무력감 → 최종 위기 → 구조 → 따뜻한 엔딩
```

### 톤

- 공포: 시골 밤길, 발소리, 시야 제한, 갑작스러운 추격
- 귀여움: 배고파서 편의점에 가는 동기, 간식, 짧은 혼잣말
- 감동: 남자친구가 걱정되어 찾아오고 마지막에 좋아하는 간식을 건네줌

---

## 3. 대상 플레이 경험

플레이어는 다음을 경험해야 한다.

1. “금방 다녀오면 되겠지”라는 가벼운 마음으로 출발한다.
2. 어두운 시골길에서 점점 불안해진다.
3. 첫 추격에서 캡사이신 스프레이를 사용해 위기를 넘긴다.
4. 편의점 불빛을 보고 안심한다.
5. 문이 잠겨 있다는 사실로 다시 불안해진다.
6. 스프레이가 없는 상태에서 최종 추격을 당한다.
7. 남자친구 차 헤드라이트와 경적이 등장하며 구조된다.
8. 마지막에는 무섭지만 따뜻한 기억으로 끝난다.

---

## 4. 범위 고정

### 반드시 포함

- 2D 탑다운 이동
- 간단한 충돌 맵
- 대화창
- 조사 상호작용
- 이벤트 트리거
- 첫 추격
- 스프레이 1회 사용
- 편의점 문 잠김
- 최종 추격
- 차량 구조 이벤트
- 엔딩
- 게임오버/체크포인트
- 검증 스크립트

### 포함하지 않음

- 복잡한 퍼즐
- 다중 엔딩
- 저장/불러오기
- 인벤토리 시스템
- 전투 시스템
- 랜덤 AI
- NPC 다수
- 큰 마을 탐험
- 장시간 플레이 구조

---

## 5. 권장 프로젝트 구조

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
    audio/
    fonts/

  tools/
    validate_project.gd

  .logs/
    progress.md
```

---

## 6. MVP 우선 구현 전략

Godot 씬 파일을 직접 많이 생성하다가 막힐 수 있다. 따라서 처음에는 다음 방식이 가장 안정적이다.

### 1단계: 코드 주도 프로토타입

- `Main.tscn` 하나를 만든다.
- `Main.gd` 또는 `GameManager`가 맵 오브젝트, 플레이어, 적, 트리거를 최소한으로 구성한다.
- 그래픽은 도형/ColorRect/기본 Sprite2D로 대체한다.
- 게임을 처음부터 엔딩까지 플레이 가능하게 만든다.

### 2단계: 씬 분리

- 플레이어를 `Player.tscn`으로 분리한다.
- 적을 `Enemy.tscn`으로 분리한다.
- HUD와 Dialogue를 별도 씬으로 분리한다.
- 차량 구조 오브젝트를 `BoyfriendCar.tscn`으로 분리한다.

### 3단계: 연출 강화

- 카메라 흔들림
- 조명/암전 느낌
- 편의점 불빛
- 발소리/심장소리/경적 사운드 자리 만들기
- 대사 다듬기

---

## 7. 게임 맵 설계

### 전체 구조

거의 일자형 맵이어도 된다. 플레이어가 자연스럽게 왼쪽/아래쪽에서 시작해 오른쪽/위쪽의 편의점으로 이동한다고 가정한다.

```text
[주인공 집]
     |
[집 앞 골목]
     |
[가로등이 드문 시골길]
     |
[폐가/풀숲 구간]  ← 첫 추격 트리거
     |
[작은 다리 또는 도로]
     |
[불 켜진 편의점]  ← 문 잠김 이벤트
     |
[돌아가는 길]     ← 최종 추격
     |
[차량 구조 지점]  ← 남자친구 등장
```

### 맵 오브젝트

| 구역 | 오브젝트 | 목적 |
|---|---|---|
| 집 | 문, 냉장고, 침대 | 도입 대사 |
| 집 앞 | 우체통, 자전거, 낮은 담장 | 출발 분위기 |
| 시골길 | 전봇대, 가로등, 풀숲 | 불안감 |
| 폐가 앞 | 낡은 집, 쓰레기봉투 | 첫 추격 트리거 |
| 편의점 앞 | 자동문, 간판, 내부 불빛 | 거짓 안전지대 |
| 도로 끝 | 차 헤드라이트 위치 | 구조 이벤트 |

---

## 8. 게임 상태

`GameManager`는 아래 상태를 관리한다.

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

### 상태 전환표

| 현재 상태 | 조건 | 다음 상태 | 처리 |
|---|---|---|---|
| INTRO_HOME | 집 문 조사 | WALK_TO_STORE | 출발 대사, 목표 갱신 |
| WALK_TO_STORE | 폐가 앞 트리거 진입 | FIRST_THREAT | 적 등장, 추격 시작 |
| FIRST_THREAT | 스프레이 명중 | SPRAY_USED | 적 후퇴, 잔량 0 |
| SPRAY_USED | 편의점 도착 | STORE_REACHED | 편의점 목표 표시 |
| STORE_REACHED | 편의점 문 조사 | FINAL_CHASE | 문 잠김 대사, 최종 추격 시작 |
| FINAL_CHASE | 구조 지점 도달 | RESCUE | 차량 등장, 적 정지 |
| RESCUE | 컷신 종료 | ENDING | 엔딩 대사 |
| 모든 추격 상태 | 적과 접촉 | GAME_OVER | 체크포인트 재시작 |

---

## 9. 조작 사양

| 입력 | 기능 |
|---|---|
| WASD / 방향키 | 이동 |
| Shift | 달리기 |
| E | 조사 / 대화 진행 |
| F 또는 Space | 스프레이 사용 |
| Esc | 일시정지. 최소 구현에서는 생략 가능 |

### 플레이어 이동 수치

- 기본 속도: 90~110
- 달리기 속도: 150~170
- 적 속도, 첫 추격: 플레이어 기본 속도보다 빠르지만 달리기보다 느림
- 적 속도, 최종 추격: 플레이어 달리기보다 약간 느리거나 비슷하게 설정
- 난이도는 낮게 유지한다.

---

## 10. 핵심 시스템 상세

### 10.1 Player

책임:

- 입력 처리
- 이동/달리기
- 마지막 이동 방향 저장
- 상호작용 가능 오브젝트 추적
- 스프레이 컨트롤러 호출
- 대화 중 이동 잠금

권장 노드:

```text
Player CharacterBody2D
  CollisionShape2D
  Sprite2D 또는 ColorRect 대체 노드
  SprayOrigin Marker2D
  InteractionDetector Area2D
```

### 10.2 Enemy

책임:

- 활성화 전에는 숨김/정지
- 활성화 후 플레이어 추격
- 플레이어 접촉 시 `GameManager.game_over()` 호출
- 스프레이 명중 시 `stunned_by_spray()` 실행
- 첫 추격에서는 스프레이로 퇴장
- 최종 추격에서는 스프레이 무효. 단, 잔량 없음 메시지가 나오므로 실제 명중 판정은 발생하지 않아도 됨

권장 노드:

```text
Enemy CharacterBody2D
  CollisionShape2D
  Sprite2D 또는 ColorRect
  Hitbox Area2D
```

### 10.3 SprayController

책임:

- 남은 횟수 관리
- F/Space 입력 처리
- 플레이어 바라보는 방향으로 짧은 범위 판정 생성
- Enemy가 범위 안이면 `stunned_by_spray()` 호출
- 사용 후 HUD 업데이트
- 잔량 없음 상태에서 사용 시 대사 출력

스프레이 사양:

```text
max_uses = 1
range = 48~72px
cooldown = 0.5s
```

### 10.4 DialogueManager

책임:

- 대사 큐 관리
- 대화창 표시/숨김
- 대사 진행
- 대화 중 플레이어 이동 잠금
- 대화 종료 콜백 지원

대사는 `data/dialogues.json`에서 읽을 수 있으면 좋다. 어렵다면 우선 코드 상수로 구현하고 추후 JSON으로 분리한다.

### 10.5 TriggerEvent

책임:

- Area2D에 플레이어 진입 감지
- `trigger_id`별 이벤트 실행
- `one_shot`이면 한 번만 발동
- 요구되는 `GameStage`가 맞을 때만 실행

필수 트리거 ID:

```text
start_walk
ambient_dog_bark
first_chase
store_arrival
final_chase_escape_zone
rescue_zone
```

### 10.6 ConvenienceStoreDoor

책임:

- 플레이어가 근처에 있을 때 E 입력으로 조사
- 편의점 문 잠김 대사 출력
- 대사 종료 후 `GameManager.start_final_chase()` 호출

### 10.7 BoyfriendCar

책임:

- 최종 구조 지점에서 등장
- 헤드라이트처럼 보이는 밝은 사각형/원형 오브젝트 표시
- 경적 사운드 자리 제공
- 적 정지/퇴장
- 엔딩 대사 시작

---

## 11. 대사 초안

대사는 짧게 유지한다. 사용자가 나중에 여자친구 말투에 맞게 쉽게 바꿀 수 있어야 한다.

### 도입

```text
주인공: 배고파...
주인공: 냉장고에 뭐 없나?
시스템: 냉장고는 텅 비어 있다.
주인공: 편의점... 갔다 올까?
주인공: 금방 다녀오면 되겠지.
```

### 밤길 초반

```text
주인공: 밤공기가 생각보다 차갑네.
주인공: 편의점까지만 갔다 오자. 진짜 금방이야.
```

### 불안 트리거

```text
시스템: 풀숲에서 바스락거리는 소리가 들렸다.
주인공: ...뭐야?
```

### 첫 추격

```text
주인공: 저 사람... 방금 움직였어?
시스템: F 또는 Space 키로 스프레이를 사용할 수 있다.
```

스프레이 사용 성공:

```text
주인공: 가까이 오지 마!
시스템: 스프레이가 비었다.
주인공: 하아... 하아...
주인공: 편의점까지만 가자. 편의점까지만.
```

### 편의점 도착

```text
주인공: 살았다...
```

문 조사:

```text
시스템: 문이 잠겨 있다.
주인공: 왜...? 안에 불은 켜져 있는데.
시스템: 뒤쪽에서 발소리가 들린다.
주인공: 아니지...?
```

### 최종 추격 중 스프레이 입력

```text
시스템: 스프레이가 없다...!
```

### 구조

```text
시스템: 어두운 도로 끝에서 헤드라이트가 켜졌다.
남자친구: 타!
주인공: 어떻게 알고 왔어?
남자친구: 혼자 나간다길래 불안해서.
남자친구: 그리고 이거.
주인공: 뭐야?
남자친구: 네가 좋아하는 과자.
주인공: ...살짝 감동인데?
주인공: 근데 다음엔 같이 가.
남자친구: 응. 다음엔 무조건 같이.
```

엔딩 문구:

```text
END
오늘의 간식은 무사히 도착했습니다.
```

---

## 12. `data/dialogues.json` 권장 구조

```json
{
  "intro_home": [
    { "speaker": "주인공", "text": "배고파..." },
    { "speaker": "주인공", "text": "냉장고에 뭐 없나?" },
    { "speaker": "시스템", "text": "냉장고는 텅 비어 있다." },
    { "speaker": "주인공", "text": "편의점... 갔다 올까?" }
  ],
  "first_chase_hint": [
    { "speaker": "시스템", "text": "F 또는 Space 키로 스프레이를 사용할 수 있다." }
  ],
  "spray_success": [
    { "speaker": "주인공", "text": "가까이 오지 마!" },
    { "speaker": "시스템", "text": "스프레이가 비었다." }
  ],
  "store_locked": [
    { "speaker": "시스템", "text": "문이 잠겨 있다." },
    { "speaker": "주인공", "text": "왜...? 안에 불은 켜져 있는데." },
    { "speaker": "시스템", "text": "뒤쪽에서 발소리가 들린다." }
  ],
  "no_spray": [
    { "speaker": "시스템", "text": "스프레이가 없다...!" }
  ],
  "ending": [
    { "speaker": "남자친구", "text": "타!" },
    { "speaker": "주인공", "text": "어떻게 알고 왔어?" },
    { "speaker": "남자친구", "text": "혼자 나간다길래 불안해서." },
    { "speaker": "남자친구", "text": "그리고 이거." },
    { "speaker": "주인공", "text": "뭐야?" },
    { "speaker": "남자친구", "text": "네가 좋아하는 과자." },
    { "speaker": "주인공", "text": "...살짝 감동인데?" },
    { "speaker": "주인공", "text": "근데 다음엔 같이 가." },
    { "speaker": "남자친구", "text": "응. 다음엔 무조건 같이." }
  ]
}
```

---

## 13. UI 사양

### HUD

화면 좌측 상단:

```text
목표: 편의점에 가자
스프레이: 1/1
```

상태별 목표 문구:

| 상태 | 목표 문구 |
|---|---|
| INTRO_HOME | 밖으로 나가자 |
| WALK_TO_STORE | 편의점에 가자 |
| FIRST_THREAT | 도망치자! |
| SPRAY_USED | 편의점까지 가자 |
| STORE_REACHED | 편의점 문을 조사하자 |
| FINAL_CHASE | 도망쳐! |
| RESCUE | 차 쪽으로 가자 |
| ENDING |  |

### Dialogue UI

화면 하단 반투명 박스:

```text
[화자]
대사 내용...

E: 다음
```

---

## 14. 공포 연출 사양

우선순위는 다음과 같다.

1. 침묵과 발소리
2. 어두운 화면과 좁은 시야
3. 가로등 깜빡임
4. 편의점 불빛
5. 화면 흔들림
6. 갑작스러운 추격 시작
7. 차량 헤드라이트

### 구현 난이도 낮은 연출

- CanvasModulate로 전체 화면을 어둡게 함
- 편의점 근처에 밝은 ColorRect/PointLight2D 느낌의 오브젝트 배치
- Camera2D shake 함수 추가
- 추격 시작 시 짧은 암전 또는 화면 흔들림
- 적 등장 위치를 플레이어 후방/측면에 배치

사운드 파일이 없으면 AudioStreamPlayer 노드만 자리로 만들고, `.logs/progress.md`에 “사용자가 사운드 파일 추가 필요”라고 기록한다.

---

## 15. 체크포인트와 게임오버

### 체크포인트

| 체크포인트 | 위치 | 복귀 상태 |
|---|---|---|
| CP_1 | 첫 추격 직전 | WALK_TO_STORE |
| CP_2 | 편의점 도착 직후 | STORE_REACHED |

게임오버 시:

```text
시스템: 다시 해보자. 이번엔 조금 더 빨리...
```

이후 마지막 체크포인트로 복귀한다.

### 난이도 조정

- 적은 플레이어 달리기보다 너무 빠르면 안 된다.
- 최종 추격은 연출 중심이다. 구조 지점까지 1~2회 안에 도달 가능해야 한다.
- 막다른 길로 플레이어를 억지로 몰아넣지 않는다.

---

## 16. 구현 마일스톤

### Milestone 1 — 프로젝트 골격

완료 조건:

- `project.godot` 생성
- 기본 폴더 생성
- `Main.tscn` 생성
- `GameManager`, `DialogueManager` autoload 설정 또는 런타임 참조 구조 생성
- `.logs/progress.md` 생성

### Milestone 2 — 이동 가능한 맵

완료 조건:

- 플레이어가 이동한다.
- 카메라가 플레이어를 따라간다.
- 벽/장애물 충돌이 있다.
- 집에서 편의점까지 걸어갈 수 있다.

### Milestone 3 — 대화와 상호작용

완료 조건:

- E로 오브젝트 조사 가능
- 대화창 표시/다음 대사 진행 가능
- 대화 중 플레이어 이동 잠금
- 도입 대사와 편의점 문 대사 출력 가능

### Milestone 4 — 첫 추격과 스프레이

완료 조건:

- 트리거 진입 시 적 등장
- 적이 플레이어를 추격
- F/Space 스프레이 사용
- 적이 스프레이에 맞으면 사라짐
- HUD 스프레이 잔량 0 표시

### Milestone 5 — 편의점 반전과 최종 추격

완료 조건:

- 편의점 문이 잠겨 있음
- 문 조사 후 최종 추격 시작
- 스프레이 없음 메시지 출력
- 적 접촉 시 게임오버/체크포인트 복귀

### Milestone 6 — 구조와 엔딩

완료 조건:

- 구조 지점 도달 시 차량 등장
- 적 정지/퇴장
- 엔딩 대사 출력
- 엔딩 화면 표시

### Milestone 7 — 검증과 정리

완료 조건:

- `tools/validate_project.gd` 구현
- Godot 실행 가능 시 검증 명령 실행
- `.logs/progress.md`에 결과 기록
- 수동 QA 체크리스트 작성

---

## 17. 권장 스크립트 책임

### `scripts/autoload/game_manager.gd`

- 현재 stage
- 체크포인트
- 스프레이 잔량
- 플레이어 이동 잠금
- 적 활성화/비활성화
- 목표 문구 업데이트
- 게임오버/리스폰
- 엔딩 시작

### `scripts/autoload/dialogue_manager.gd`

- JSON 또는 상수 대사 로딩
- 대화 큐
- UI 연결
- 대화 종료 콜백

### `scripts/player.gd`

- 이동
- 달리기
- 상호작용
- 스프레이 사용 요청
- 대화 중 이동 제한 확인

### `scripts/enemy_chase.gd`

- 추격 활성화
- 플레이어 방향 이동
- 접촉 감지
- 스프레이 맞음 처리
- 최종 추격 모드 처리

### `scripts/spray_controller.gd`

- 잔량 확인
- 판정 Area2D 생성 또는 RayCast2D 사용
- 적 명중 처리
- 잔량 없음 대사 요청

### `scripts/trigger_event.gd`

- trigger_id 기반 이벤트 호출
- one_shot 처리
- required_stage 확인

### `scripts/convenience_store_door.gd`

- 조사 가능 상태 관리
- 문 잠김 대사 출력
- 최종 추격 시작

### `scripts/boyfriend_car.gd`

- 차량 표시
- 헤드라이트 표시
- 구조 컷신 실행
- 엔딩 대사 호출

### `tools/validate_project.gd`

검증 항목:

- 필수 파일 존재 여부
- 필수 씬 load 가능 여부
- 필수 스크립트 load 가능 여부
- `project.godot` 메인 씬 설정 여부
- `data/dialogues.json` 파싱 가능 여부

---

## 18. 검증 스크립트 요구사항

`tools/validate_project.gd`는 Godot headless 환경에서 실행 가능해야 한다.

권장 동작:

```gdscript
extends SceneTree

func _init():
    var failures: Array[String] = []
    _check_file("res://project.godot", failures)
    _check_file("res://scenes/Main.tscn", failures)
    _check_file("res://scripts/player.gd", failures)
    _check_file("res://scripts/enemy_chase.gd", failures)
    _check_file("res://data/dialogues.json", failures)

    # load() checks
    # JSON parse checks

    if failures.size() > 0:
        for failure in failures:
            print("VALIDATION_FAIL: ", failure)
        quit(1)
    else:
        print("VALIDATION_OK")
        quit(0)
```

---

## 19. 수동 QA 체크리스트

Codex가 작업을 마친 후 사람이 직접 확인할 항목이다.

- [ ] 게임이 실행된다.
- [ ] 시작 위치가 집이다.
- [ ] WASD/방향키 이동이 된다.
- [ ] Shift 달리기가 된다.
- [ ] 벽을 통과하지 않는다.
- [ ] E로 조사/대화 진행이 된다.
- [ ] 첫 추격이 자연스럽게 시작된다.
- [ ] 스프레이를 한 번만 사용할 수 있다.
- [ ] 첫 위협이 스프레이로 물러난다.
- [ ] 편의점 불빛이 안전지대처럼 보인다.
- [ ] 편의점 문은 잠겨 있다.
- [ ] 최종 추격에서 스프레이 없음 메시지가 나온다.
- [ ] 구조 지점에서 차량이 등장한다.
- [ ] 엔딩 대사가 나온다.
- [ ] 게임오버 후 체크포인트 복귀가 된다.
- [ ] 전체 플레이타임이 8~10분 근처다.
- [ ] 대사가 여자친구에게 불쾌하지 않고 선물 느낌이 난다.

---

## 20. 개인화 플레이스홀더

아래 값은 사용자가 나중에 바꿀 수 있게 `data/game_config.json` 또는 상수로 둔다.

```json
{
  "hero_display_name": "주인공",
  "boyfriend_display_name": "남자친구",
  "favorite_snack": "좋아하는 과자",
  "game_title": "편의점 가는 길"
}
```

엔딩 대사에서 `favorite_snack`을 사용할 수 있으면 사용한다.

---

## 21. 구현 중 판단 기준

### 시간이 부족하거나 막히면

우선순위:

1. 시작부터 엔딩까지 가능한 흐름
2. 추격/스프레이/문 잠김/구조 이벤트
3. 대화창과 HUD
4. 충돌/체크포인트
5. 공포 연출
6. 그래픽 디테일
7. 사운드

### 에셋이 없으면

- 플레이어: 작은 밝은 사각형 또는 단순 Sprite2D
- 적: 검은 실루엣 사각형
- 편의점: 밝은 사각형 건물 + 간판 Label
- 차량: 어두운 차체 사각형 + 밝은 헤드라이트 원/사각형
- 풀숲/가로등: 단순 도형

---

## 22. 진행 로그 형식

`.logs/progress.md`에 다음 형식으로 기록한다.

```markdown
# Progress Log

## Checkpoint 1 — Project skeleton
- Done:
- Verified:
- Issues:

## Checkpoint 2 — Movement and map
- Done:
- Verified:
- Issues:

...

## Final Summary
- Implemented:
- Validation commands run:
- Passing:
- Known issues:
- Manual QA needed:
```

---

## 23. 최종 산출물

완료 시 저장소에는 최소한 다음이 있어야 한다.

```text
project.godot
scenes/Main.tscn
scripts/autoload/game_manager.gd
scripts/autoload/dialogue_manager.gd
scripts/player.gd
scripts/enemy_chase.gd
scripts/spray_controller.gd
scripts/trigger_event.gd
scripts/convenience_store_door.gd
scripts/boyfriend_car.gd
data/dialogues.json
data/game_config.json
tools/validate_project.gd
.logs/progress.md
```

---

## 24. 성공 정의

이 프로젝트는 다음 문장이 참이면 성공이다.

> 플레이어가 집에서 출발해 밤길을 지나고, 첫 위협을 스프레이로 넘기고, 잠긴 편의점 앞에서 다시 위기에 처한 뒤, 남자친구 차량에 구조되어 따뜻한 엔딩을 보는 단편 공포게임이 Godot에서 실행된다.
