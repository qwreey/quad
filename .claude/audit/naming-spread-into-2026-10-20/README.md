# Spread 입력 이름 검토 — 세 모델 계열 (2026-10-20)

같은 프롬프트(`prompt.md`)를 세 계열에 줬다. 대상: 입력 마커 `SpreadInto<C>`, 키트 필드 `FieldSpread`/`TrackSpread`(`FieldModifier`/`TrackModifier` 옆에 따로), "먼저 자리 잡은 것이 이긴다" 규칙 아래 `:Add`의 읽힘. 결정 맥락은 `research/component-flatten-sugar-plan.md` 5절 끝 2026-10-20 문단.

- `codex-gpt-6-luna.md` — codex-cli 0.163.0, `gpt-6-luna`, effort medium, uid 61000·빈 디렉터리·read-only.
- `sonnet.md` — Claude sonnet 서브에이전트(다른 파일을 읽지 말라고 지시).
- `gemini-3.8-flash-high.md` — agy, 격리 worktree. 이번에도 레포를 읽었다(파일 인용 — `SliderNum.luau` 46행 `TrackModifier` 등은 메인이 확인).

**수렴**
- `SpreadInto<C>`: 셋 다 유지(`ModifierInto<C>`와 짝).
- 우선순위 방향: 셋 다 Modifier(뒤가 이김)와 반대인 것을 가장 큰 혼란 지점으로 짚음. 처방은 문서의 우선순위 표(sonnet·codex). Gemini는 JS `{...a, ...b}`(뒤가 이김)와도 반대라는 점을 더함.

**갈림**
- `:Add`: codex `Merge`, sonnet 유지(대안 `Append`), Gemini `Append`(유지하면 위험 높음 — 더한 것이 반영된다는 기대).
- 키트 필드: codex·Gemini 유지(`FieldSpread`), sonnet `FieldExtras`(역할 차이를 이름에). sonnet·Gemini 모두 두 통로가 공존하는 선택 비용을 지적.
