# 이름 검토 — base 표면 둘: q별 결과 캐시·프로바이더 단언 (2026-10-22)

세 계열(sonnet Agent, codex gpt-6-luna, Gemini 3.8 flash high)에게 같은 `prompt.md`를 줬다(sonnet은 첫 송신에 본문이 빠져 같은 본문을 다시 보냈다). 답은 각 파일(sonnet 답은 대화에서 받아 `sonnet.md`). 판정은 다수안(1순위가 셋 중 둘). 맥락은 `research/kit-packaging-plan.md` 3.1 뒤 회신 문단들.

| 자리 | sonnet | luna | Gemini | 다수안 |
|---|---|---|---|---|
| 1 q별 결과 캐시 | Memo (2위 GetOrCreate) | GetOrCreate (2위 Memo) | GetOrCreate (Memo는 반응형 memo/computed로 오해 — 경고) | `GetOrCreate` |
| 1 인자 모양 | `(key, build)` 고정 | `(key, build)` 고정 | `(build, [key])` — 모듈의 `(build, build)` 중복을 피함 | `(key, build)` |
| 2 프로바이더 단언 | AssertProvider | AssertBackend (2위 AssertProvider — Context.Provider 혼동) | AssertProvider (UseProvider와 대칭) | `AssertProvider` |
| 3 이름·버전 선언 | `Provider = { Name, Version }` | 같음 | 같음 | `Provider = { Name, Version }` (셋 다: 최상위 `Version`은 병합 때 `q.Version`을 덮는다) |

메인 메모(사용자 판정 전): 3의 `Provider`는 이미 공개 타입 `Provider<T>`(Context의 열쇠 타입, `docs/getting-started/01-setup.md`)와 같은 낱말이라, q에 `q.Provider` 필드로 병합되면 그 혼동이 커진다 — 선언은 확장 표에 두되 `UseProvider`가 q에 병합하지 않고 비공개 자리에 기록하는 갈래가 있다.
