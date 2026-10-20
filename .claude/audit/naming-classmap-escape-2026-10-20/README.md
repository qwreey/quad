# 클래스 맵 탈출구 이름 검토 — 세 모델 계열 (2026-10-20)

같은 프롬프트(`prompt.md`)를 세 계열에 줬다. 대상: 사용자 클래스 맵을 받아 같은 커리 표면을 돌려주는 탈출구(가칭 `With`, `research/declaration-surface-plan.md` 5절 끝 2026-10-20 문단).

- `codex-gpt-6-luna.md` — codex-cli 0.163.0, `gpt-6-luna`, effort medium, uid 61000·빈 디렉터리·read-only.
- `sonnet.md` — Claude sonnet 서브에이전트(다른 파일을 읽지 말라고 지시).
- `gemini-3.8-flash-high.md` — agy, 격리 worktree. 이번에도 레포를 읽었다 — 인용한 "옛 `State:With` → `Depend` 개명"(2026-09-15, `quad-types/src/init.luau`)은 메인이 확인.

**수렴**
- `With`: 셋 다 변경 — 전치사라 무엇이 돌아오는지가 없고, 인자 없는 `()` 호출과 어울리지 않는다(Gemini는 `State:With`를 이미 `Depend`로 바꾼 이력을 더함).
- 탈락: `Extend`(내장 맵에 합쳐진다는 거짓 약속 — sonnet·Gemini 위험 높음), `Bind`(반응형 바인딩 연상), `Using`, `ClassMap`(값·입력 이름처럼 읽힘), `Surface`(Gemini: `SurfaceGui` 등 3D 용어와 겹침 — 위험 높음).
- 메커니즘 경고(셋 다): 내장 맵과 합쳐지지 않는다, 거짓 맵은 검사되지 않는다, 사용자 맵이 커지면 too complex가 다시 난다(Gemini — M4 실측상 `keyof` 바운드는 130개까지 깨끗).

**갈림**: 1순위가 codex `For`, sonnet `Classes`, Gemini `ForClasses`(대안 `Classes`·`For`). sonnet은 `ForClasses`를 대안으로, Gemini는 `Classes`에 "클래스 사전이 돌아오는 것으로 읽힘(`W.Part`)" 위험 중간, `For`에 예약어 `for` 유사·무엇을 위한 것인지 생략으로 위험 중간.
