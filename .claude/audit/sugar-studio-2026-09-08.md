# 슈거 구간 Studio 실측 — 시간 op 배선·Debounce/Throttle 타이밍 (2026-09-08 밤)

**무엇을**: 2026-09-08 밤 슈거 구현(`Debounce.luau`·`LifecycleHooks.luau`·`Fallback.luau`, `session/2026-09-08-04-sugar-implementation.md`)
가운데 엔진에 닿는 부분 — quad-roblox `EngineOps.luau`의 `setTimeout`/`clearTimeout`(`task.delay`/`task.cancel`)과 그 위의
`Debounce`/`Throttle`이 실물 스케줄러에서 `base/debounce-throttle-plan.md` 1-1절 시나리오대로 도는지. 사용자가 rojo serve를 Studio에
연결해 둔 상태(round8 실측과 같은 세션), MCP `execute_luau`(Edit).

**절차 메모 — require 캐시**: rojo가 새 파일(`Debounce` 등)을 트리에 넣어도 이미 `require`된 `quad-base/src` 모듈은 Studio의
require 캐시가 옛 본문을 돌려준다(`Quad.Debounce == nil`). `quad-base`·`quad-roblox` 폴더를 `:Clone()`해 임시 폴더에 두고 그
사본을 `require`하면 새 코드가 잡힌다 — 이후 Studio 실측은 이 관용구로.

**결과(전부 통과)**:

| 항목 | 결과 |
|---|---|
| `task.delay`로 만든 스레드가 발화한 뒤 `coroutine.status` | `dead` |
| 발화한(dead) 스레드에 `task.cancel` | **에러 없음(무해한 no-op)** — 코드의 `coroutine.status` 가드는 불필요해서 제거, 주석도 정정 |
| `q.setTimeout(fn, 0.05)` 반환 | `{ __quadTimeout = true, _native = thread }` |
| 발화 뒤 늦은 `q.clearTimeout(t)` | 에러 없음 |
| `Debounce{ Time = 0.2 }`: 0.0·0.1·0.2에 신호 | Observer 발화 1회, 0.42초(등록 즉시 1회는 별도) — 정본 "조용해지고 Time 뒤 1회" |
| `Throttle{ Time = 0.5 }`: 0.00·0.05·0.57·1.77에 신호 | 0.00:1(leading)·0.51:2(trailing)·1.01:3(창 재개방 뒤)·1.79:4(idle → leading) — 정본 1-1절 표 그대로 |

`task.wait` 해상도 때문에 ±0.02초의 지터가 있다(프레임 단위). 스펙(`spec.debounce`·`spec.timers`)은 mock 가상 시계라 정확한
값을 단언하고, 실물은 여기 수치로 남긴다.

**아직 안 본 것**: `MaxTime`·`Handle`·팩토리 브로드캐스트는 CLI 스펙만(순수 로직이라 엔진과 무관 — 정본 6절의 배치 근거 그대로).
