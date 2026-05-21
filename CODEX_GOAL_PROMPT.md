# CODEX_GOAL_PROMPT.md — Codex `/goal` 실행 프롬프트

아래 내용을 Codex CLI 또는 Codex 환경에서 그대로 사용한다.

```text
/goal Implement the Godot 4.x 2D top-down short horror game described in AGENTS.md and GAME_MASTER_PLAN.md without stopping until the project is playable from start to ending and the verification script passes or a concrete environment blocker is documented.

Before coding:
1. Read AGENTS.md and GAME_MASTER_PLAN.md.
2. Inspect the repository structure.
3. If this is an empty directory, create a new Godot 4.x project.
4. Keep the scope fixed: no save/load system, no inventory system, no multiple endings, no complex puzzles.

Primary objective:
Build a playable 8-10 minute top-down horror adventure called "편의점 가는 길".
The player starts at home, goes to a rural convenience store at night, survives a first chase by using a one-use capsaicin spray, finds the lit convenience store locked, faces a final chase with no spray left, and is rescued by the boyfriend's car before a warm ending.

Required implementation:
- project.godot with a runnable main scene
- 2D top-down player movement using WASD/arrow keys
- Shift sprint
- E interaction/dialogue progression
- F or Space spray use
- HUD showing current objective and spray count
- Dialogue UI
- Simple collision map
- Trigger system
- First chase event
- One-use spray system
- Locked convenience store door event
- Final chase event with no-spray message
- Boyfriend car rescue event
- Ending dialogue and ending screen
- Game over or checkpoint retry behavior
- tools/validate_project.gd that validates required files/scenes/scripts/dialogue data
- .logs/progress.md with checkpoint progress and verification results

Implementation strategy:
1. First create a minimal playable vertical slice even if all assets are placeholder shapes.
2. Prefer simple, robust code over complex scene architecture.
3. If direct .tscn authoring becomes fragile, use Main.tscn plus runtime-created nodes until the game is playable.
4. After the full flow works, split scenes/scripts where safe.
5. Do not wait for external art or audio assets. Use placeholder visuals and empty AudioStreamPlayer nodes as needed.
6. Keep all dialogue and personalized values easy to edit in data/dialogues.json and data/game_config.json when feasible.

Validation loop:
- After each milestone, update .logs/progress.md.
- If a Godot binary is available, run:
  - godot --version, or godot4 --version
  - godot --headless --path . --import
  - godot --headless --path . --script res://tools/validate_project.gd
  - godot --headless --path . --check-only --script res://tools/validate_project.gd
- If the Godot binary is not available, still create the project files and document the missing executable as an environment blocker in .logs/progress.md.

Stop only when:
- The game has a complete start-to-ending flow.
- The player can move, interact, use spray once, experience both chase events, trigger the locked-store event, and reach the rescue ending.
- The validation script exists and either passes or the only blocker is an unavailable local Godot executable.
- .logs/progress.md contains a clear final summary, run instructions, verification results, and known issues.
```

## 선택: 더 엄격한 버전

아래 버전은 Codex가 범위를 덜 흔들도록 더 강하게 제한한다.

```text
/goal Complete the first playable Godot 4.x version of "편의점 가는 길" exactly according to AGENTS.md and GAME_MASTER_PLAN.md. Do not add extra systems beyond the required scope. Use placeholder assets. Keep working through milestones, validate after each milestone when possible, update .logs/progress.md, and stop only when the game is playable from home start to boyfriend rescue ending or when a non-code environment blocker is documented with exact next steps.
```
