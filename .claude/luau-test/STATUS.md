# 스파이크 상태판 — **폴더가 곧 상태**

> 마지막 갱신: **2026-08-21** — `Brand`가 **인스턴스 브랜드**로 전면
> 재작성되면서(`base/brand-plan.md`) 옛 `Brand.set`/`Brand.get`을 직접 구현해
> 쓰던 `22`가 `done/` → `rewrite-required/` 이동(검증 대상인 `isRef`/`isPreRef`
> 포함 관계 자체는 그대로). 같은 날 `Epoch`/`EpochMap` 승격도 있었으나 그건
> 이미 `rewrite-required/`에 있는 `05`의 지침에 반영돼 있다. 직전 갱신도
> 같은 날 — QA 4라운드 `F-4-1`로 `Dispatch.drive`의
> props 순회가 **단일 일반화 `for`**로 정정되면서, 두 루프 버전을 검증하던
> `01`이 낡아 `done/` → `rewrite-required/` 이동(검증 대상인 순서 계약
> 자체는 그대로). 같이 **만들어야 할 스파이크** 절 신설 — 아직 파일이
> 없는 실측 항목(중간 State GC — **[2026-08-24]** 같이 나열돼 있던 `R-11`의
> `table.insert` 구멍 재사용은 6라운드 `H-7`로 **전제가 사라져 폐기**됐다)을
> 여기 모은다. 직전 갱신은 2026-08-19 — 신규 `quad-types` 패키지(`CheckedQuad<T, Pattern>`
> 버전 패턴 체크 + `AddPlugin<Self,P>` 체이닝) 검증용 `23` 신규 추가 →
> `done/` 직행, 같은 날 후속으로 `type-version-check` 분리에 맞춰 재작성.
> 그 과정에서 `type function`을 거친 값은 패스스루라도 이후
> 제네릭 self 체이닝이 깨진다는 새 Luau 함정을 발견(`typing-limits.md`
> §6로 승격). 직전 갱신은 같은 날 — `13`을 타입 전용/런타임 두 파일로 분리
> (A의 더미 스텁이 B 실행을 막던 문제 해결) + PostRef까지 확장, 런타임
> 절반은 신규 `22`로 분가 → 둘 다 `done/`. 직전 갱신은 같은 날 —
> M0/M1 스캐폴딩을 처음 실제로 짜보는 과정에서 `05`를 현행 모델("emit은
> 항상 전파, 재계산만 캐시로 dedup")로 재작성해 통과 → `rewrite-required/`
> → `done/` 이동, `todos.md` 00번이 요구하던 "Store 미선언 키 타입 에러"
> 확인도 신규 스파이크 `21`로 완료 → `done/` 직행. 직전 갱신은
> 2026-08-15 — `16`이 `types.newfunction` API 버전 드리프트
> (배열이 아니라 `{head=..., tail=...}` 레코드를 받음) 수정으로 통과,
> `rewrite-required/` → `done/` 이동. 근거:
> `audit/type-recursive-issue-with-typeof/REPORT.md` 6-1절.
> 직전 갱신은 2026-08-14(**"emit은 항상 전파"** 정정으로 `05`가 옛 모델을
> 검증 중이라 `rewrite-required/`로 이동 —
> `archive/invalidate-dedup-propagation-reversed.md`). 직전 갱신은 같은 날 **다섯 번째 세션**(`bindLifetime`/`canExecute`/
> `unbindLifetime` 재정정으로 `10`이 옛 모델을 검증하고 있어
> `rewrite-required/`로 이동 — 이제 `not-run/`에는 스파이크가 없고 헬퍼만
> 남음). 직전 갱신은 2026-08-13 열네 번째 세션(하강 diff 재디스패치 확정으로
> `04`/`19` 이동).
> 첫 실측은 여섯 번째 세션 — 상세 결과는 `.claude/audit/luau-test-first-run-2026-08-13.md`.
> 실행법: `luau <파일>` (런타임) / `luau-analyze <파일>` (타입 전용).

**[2026-08-13 열세 번째 세션] `review-required/`가 비었습니다** — 마지막
한 건이던 `08`이 해소돼 `done/`으로 갔습니다. **[2026-08-14 다섯 번째 세션]
`not-run/`의 유일한 스파이크였던 `10`도 `rewrite-required/`로 갔습니다** —
지금 남은 건 전부 에이전트가 먼저 재작성해야 할 일(`rewrite-required/`)이고,
`not-run/`엔 스파이크가 아닌 헬퍼 하나만 있습니다.

| 폴더 | 뜻 | 개수 | 누가 처리 |
|---|---|---|---|
| `review-required/` | **설계가 걸림 — 사람 결정 필요** | **0** | ⭐ 사용자 |
| `rewrite-required/` | 스파이크가 낡음(코드가 깨졌거나, 설계가 바뀌어 옛 모델을 검증 중) | 7 | 에이전트 |
| `not-run/` | 이 환경에서 못 돌림(Studio 전용) | 0(+헬퍼 1) | 사용자 or MCP 연결 후 에이전트 |
| `done/` | 통과 or 판정 끝, 더 할 일 없음 | 16 | — |

**폴더를 옮기는 게 곧 상태 갱신** — 스파이크를 고치거나 돌렸으면 파일을
해당 폴더로 `git mv`하고 아래 표의 줄도 같이 옮길 것. 파일별 "무엇을 왜
검증하는가"는 `README.md`가 담당(이 파일은 상태만).

---

## ⭐ `review-required/` — 사람 결정 필요 (0건, 비어 있음)

**[2026-08-13 열세 번째 세션] 마지막 한 건이 해소됐습니다.**
`08-type-source-satisfies-state.luau`가 남겨뒀던 잔여 케이스(`State<T>`가
자기 자신을 다른 타입 인자로 재귀 참조하면 막힘)는 **Luau의 현 한계로
확정**되어 quad가 설계로 풀 대상이 아님이 정해졌고(구 `question.md`
0-Y 해소), 스파이크는 `done/`으로 이동했습니다. 당시 검토됐던 "구울 때
인라이닝" 방향은 **채택 안 함**.

- 지금 유효한 규약: **`base/typing-limits.md`**
- 실측 근거 전문(스파이크 다수 포함 — 개수는 `spikes/` 폴더가 소스):
  `audit/type-recursion-issue/`

`15`도 같은 계약을 다루지만 **스파이크 자체가 파싱 실패**라
`rewrite-required/`에 그대로 둠 — 재작성 대상이지 사람 결정 대상이
아님(계약 자체는 위에서 이미 확정됨).

## 🟠 `rewrite-required/` — 스파이크가 낡음

(개수는 위 표와 폴더가 소스 — 여기서 다시 세지 않는다. 예전엔 이 제목이
개수를 들고 있다가 실제와 어긋난 적이 있다.)

**[2026-08-13 열네 번째 세션] 앞의 두 건은 "코드가 깨진" 게 아니라 "설계가
바뀐" 경우** — `question.md` 0-A/0-Z 확정으로 재디스패치가 **하강 diff**가
되면서, 이 둘이 검증하던 전제(선행 `retractFrom` + 4-인자 힌트 + 인덱스
점유 체크)가 더 이상 설계가 아님. 통과 상태로 `done/`에 두면 **옛 모델을
"검증됨"으로 오독하게 되므로** 옮김. 새 정본은
`base/dispatch-core-plan.md`/`base/attribute-plan.md`.

**[2026-08-14 다섯 번째 세션] `10`도 같은 이유로 합류** — `bindLifetime`/
`canExecute`/`unbindLifetime` 재정정으로 A 섹션이 폐기된 모델(`canBound`,
`bindLifetime`의 `.Subscribed` 세팅, 2-인자 `canExecute`)을 검증 중.
`10`은 **Studio 전용이라 재작성해도 이 환경에서는 못 돌린다** — 재작성
후 다시 `not-run/`으로 내려가 사용자/MCP를 기다리는 자리다.

**[2026-08-21] `01`과 `05`가 합류** — 둘 다 같은 "설계가 바뀐" 유형이다.
통과 상태로 `done/`에 두면 `01`은 구현이 안 하는 두 루프 순회를, `05`는
**이제 접히는 중복 통지가 안 접힌다는 것**을 "검증됨"으로 오독하게 된다.

**[2026-08-21 후속] `22`도 같은 이유로 합류** — `Brand`가 **인스턴스
브랜드**로 전면 재작성되면서(`base/brand-plan.md`) 이 스파이크가 직접 구현해
쓰는 `Brand.set`/`Brand.get`/`XxxTag`가 **역전된 옛 API**가 됐다
(`archive/brand-shared-registry-reversed.md`). **검증 대상 자체는 그대로
유효하다** — `isPreRef`/`isPostRef`가 서로 배타적 형제이고 둘 다 `isRef`엔
`true`라는 포함 관계는 재작성 후에도 안 바뀌었다. 옮기는 이유는 결론이
틀려서가 아니라, 통과 상태로 `done/`에 두면 **구현자가 그 파일의 `Brand`
구현을 참고 모델로 오독**하기 때문이다.

| 파일 | 상태 | 무엇을 고쳐야 하나 |
|---|---|---|
| `01-two-pass-array-hash-order.luau` | 옛 형태 기준으로는 ✅ 통과였음 | 숫자 `for` + 일반화 `for` **두 루프**로 짜여 있는데, 구현은 **단일 일반화 `for`**로 정정됨(`base/dispatch-core-plan.md`의 "props 순회 순서" 절, QA 4라운드 `F-4-1`) — Luau의 일반화 `for`가 배열 파트를 먼저 다 돌고 해시 파트로 넘어간다는 것 자체를 **한 루프로** 검증하도록 다시 쓸 것. **검증 대상(순서 계약)은 그대로**라 결론이 바뀌는 건 아님 |
| `05-store-state-diamond-propagation.luau` | 2026-08-19 재작성분은 그 시점 모델 기준 ✅ 통과였음 | **[2026-08-21] 모델이 또 바뀌었다** — 소스 에포크 비교 채택(`base/state-epoch-plan.md`)으로 다이아몬드에서 **두 번째 통지가 접힌다**. 그래서 이 스파이크의 핵심 assert("`:Get()`을 안 부르는 Observer가 변경당 경로 수(2)만큼 운다")가 **정반대**가 됐다 — 이제 **변경당 1회**여야 한다. **살릴 것**: `invalid` 기반 dedup이면 두 번째 변경부터 침묵하는 것을 잡는 음성 대조군(그 금지는 지금도 유효). **새로 넣을 것**: DFS 도중 `Get()`이 섞인 값을 캐시하던 glitch가 에포크로 사라지는지(그 문서 §1의 시나리오) |
| `04-dispatch-chain-retractFrom.luau` | 옛 모델 기준으로는 ✅ 통과였음 | (1) `chains` 슬롯이 `{handler, retractor}`가 되고 `Dispatch.process`가 핸들러를 먼저 비교하는 **하강 diff**로 재작성, (2) `retractFrom`은 **3-인자**(힌트 인자 없음), (3) "힌트가 target 인덱스에만 간다"를 검증하던 부분은 **정반대**로 뒤집힘 — 이제 각 레벨이 자기 값을 받는지를 검증해야 함. **살릴 것**: `chains:SetStrong` 순서 음성 대조군(그 버그는 새 모델에서도 그대로 유효) |
| `19-ownership-refcount-relate-patterns.luau` | A/C ✅ 유효, **B 섹션이 낡음** | B가 검증하던 "공개 `AttributeKey(name)` + 인덱스 1 점유 체크"가 폐기됨 — **그룹 전용 키 + `AttributeKeyHandler`의 이름 claim**으로 재작성하고, 음성 대조군도 "두 그룹이 같은 이름 → 즉시 error", "그룹↔직접 쓰기 → 즉시 error"로 바꿀 것(0-Z 확정 내용). A/C는 손댈 것 없음 |
| `15-type-compute-trailing-deps-typepack.luau` | **파싱 실패**(SyntaxError) | 음성 대조군의 타입 표기가 `TypeError`가 아니라 `SyntaxError`로 걸려 **파일 전체가 아무것도 검증 못 함** — 대조군을 별도 파일/블록으로 격리 |
| `22-runtime-ref-preref-postref-brand.luau` | 옛 `Brand` API 기준으로는 ✅ 통과였음 | **[2026-08-21] `Brand`가 인스턴스 브랜드로 재작성됨** — 파일 안의 `Brand.set(x, tag)`/`Brand.get(x)`/`XxxTag` 변수를 `Brand()` + `SomeBrand:register(x)`/`SomeBrand:is(x)`로 바꿔 쓸 것(`base/brand-plan.md`). **검증 대상(`isPreRef`/`isPostRef` 배타 + 둘 다 `isRef`엔 `true`, Leaf 핸들러 흉내)은 그대로**라 assert는 손댈 게 없다. **새로 넣을 것**: 다중 태깅이 실제로 되는지 — 한 값을 두 브랜드에 등록하고 양쪽 `:is`가 다 `true`인지(`Source`가 `SourceBrand`+`EpochBrand`인 자리, `base/state-epoch-plan.md` §2) |
| `10-roblox-studio-checks.server.luau` (Studio 전용) | 미실행 + **A 섹션이 옛 모델** | A가 옛 2-인자 `canExecute(inst,value)`와 `bindLifetime`의 `.Subscribed` 세팅을 검증 중 — **`bindLifetime`이 gcconn을 `value` 쪽 릴레이션에 복사하는 모델**로 재작성할 것(`base/lifecycle-pattern.md`). **[2026-08-14 열한 번째 세션 재정정, 2026-08-18 방향 정정]** 이중 바인딩 게이트는 `canBound(value)`(`if not canBound(v) then error(...) end` — `canBound` 참 = "지금 묶어도 됨") — `canExecute`는 State emit 전파 게이팅 전용으로 분리됨, 둘 다 비공개 헬퍼 `isBoundAlive`를 공유하는 1-인자 진입점이지만 **서로의 부정**(`base/lifecycle-pattern.md`의 "`canBound` vs `canExecute`" 절). **살릴 것**: "ClassName 신호 미발화 / Destroy 시 `Connected` 즉시 전환" 검증(새 모델에서 더 중요해짐), gcconn/gchold를 **Instance 생성 시점**에 만드는 것으로 바꿀 것(옛 lazy 생성 폐기). B/C 섹션은 손댈 것 없음 |

## ⚪ `not-run/` — 이 환경에서 못 돌림

**[2026-08-14 다섯 번째 세션] 스파이크는 0건** — 유일했던 `10`이
`rewrite-required/`로 갔음(위 표). 남은 건 헬퍼 하나뿐.

| 파일 | 이유 |
|---|---|
| `gc-trigger-helper.server.luau` | 스파이크가 아니라 **헬퍼** — Studio에 `collectgarbage()`가 없어서 GC를 강제 트리거하는 기법. `10`을 돌릴 때 같이 씀 |

## ✅ `done/` — 통과 or 판정 끝

(개수는 위 표와 폴더가 소스 — 여기서 다시 세지 않는다.)

**지금 `done/`에 있는 런타임 스파이크는 `02`/`03`/`06`/`07`/`11`/`17`/`18`/`20`,
전원 통과**(crash 0 / FAIL 0). 나머지는 타입 스파이크다.
**[2026-08-21] `22`는 여기서 빠졌다** — `Brand` 인스턴스 브랜드 재작성으로
파일이 쓰는 `Brand.set`/`Brand.get`이 옛 API가 되어 `rewrite-required/`로
이동(검증 대상 자체는 유효, 위 표의 재작성 지침 참고).
**[2026-08-21 정정]** 여기 "런타임 12개"라고 적혀 있었는데, 그 산술이 이미
`rewrite-required/`로 나간 `04`/`10`/`19`까지 포함한 옛 총계에서 이어져 온
것이라 실제와 안 맞았다(두 번째 `/code-review high` 발견). — **[열네 번째 세션] `04`/`19`는
검증 대상 설계가 바뀌어 `rewrite-required/`로 이동했고, [2026-08-19]
`05`는 현행 모델로 재작성해 잠시 돌아왔다가 **[2026-08-21] 소스 에포크
채택으로 다시 나갔으며**, 신규 `22`(구 `13` 런타임 절반, PostRef까지
확장)가 합류**:

| 파일 | 확인된 것 |
|---|---|
| `02-none-sentinel-vs-nil-holes` | `nil` 소진 시 `#t` 50→49로 무너짐 / `None`은 항상 50. 반대로 **당시의** Ref 콜백 배열은 `None` 쓰면 죽은 슬롯 1000개 잔존 — **두 배열의 규칙이 서로 반대여야 함**이 정량 확인. **[2026-08-24]** 그 대비의 한쪽(Ref 콜백)은 6라운드 `H-7`로 **해시맵 셋**이 되어 사라졌지만, 이 스파이크가 실제로 확인한 것(**일반 Lua 테이블에서 `nil` 구멍과 `None` 채움의 거동 차이**)은 그대로 유효하다 — `sourceList`/`flattened`처럼 순서가 중요한 배열이 여전히 그 결론 위에 선다 |
| `03-recursive-store-bind-dispatch` | StoreBind 재귀 재-dispatch, `None`→`nil` 흐름, 무한재귀 없이 종료 |
| `06-component-boundary-nil-hole-props` | `or None` 없으면 앞쪽 nil-hole로 슬롯 소실, 관용구 쓰면 항상 보존 |
| `07-relate-weak-table-gc` | **연쇄 GC 확정**(아래 별도 절) — GC-native 아키텍처의 핵심 전제 |
| `11-modifier-illegal-value-error` | Modifier 필드/Source에 핸들러 계층 값 넣으면 즉시 error — 16개 케이스 전원 |
| `17-modifier-index-tableclone-chaining` | 제네릭 `__index` + `table.clone` 체이닝, 메타테이블 참조 공유, 형제 분기 무오염 |
| `18-relate-mutual-cycle-gc` | **두 `Relate` 상호 순환은 실제로 GC 안 됨**(아래 별도 절) |
| `20-slot-splice-index-arithmetic` | `Splice` 산술 11개 경계 케이스 전부 참조 구현과 일치 |

**타입 스파이크 중 판정이 끝나 더 할 일 없는 것**:

| 파일 | 판정 |
|---|---|
| `08-type-source-satisfies-state` | ✅ 핵심 질문(Source⊇State 구조적 서브타이핑) 통과. 잔여 케이스(자기 이름을 다른 인자로 재귀 참조)는 **[2026-08-13 13차 세션] Luau 현 한계로 확정** — quad가 풀 대상 아님, `base/typing-limits.md` 1번 |
| `09-type-modifier-overridden-subtype` | ✅ 통과 — 문서가 우려한 `FrameModifier`↔`GuiObjectModifier` 서브타입 깨짐이 그대로 재현, fallback(`any`)은 정상 |
| `12-type-attribute-generic-key-narrowing` | ❌지만 **설계 영향 없음** — 제네릭 키 narrowing이 안 되는 건 `attribute-plan.md`가 이미 fallback으로 예비해둔 결과(타입 패밀리가 유일하게 믿을 경로). **[2026-08-24 `H-54`] 단 스파이크 자신의 주석이 실제 결과와 어긋난다** — *"이건 당연히 통과해야 함"*이라 적어둔 동질 대조군(line 41-43)이 실제로는 에러를 낸다(`AttributeKey<T>(name)`이 문맥에서 `T`를 못 추론해 `unknown`으로 남음). 오히려 "왜 진짜 테스트 대상이 조용히 통과하는지(= narrowing이 아예 안 일어남)"를 설명해주는 정합적 결과라 **이 총론은 그대로 유효**하고, 근거 라인만 다르다 — 재작성 시 참고 |
| `13-type-ref-preref-subtype` | **[2026-08-19 재작성]** ✅ 통과 — `PreRef<T>`/`PostRef<T>` 둘 다 `Ref<T>`를 구조적으로 만족(음성 대조군도 정확히 에러). 런타임 B섹션은 `22`로 분리(A의 더미 스텁이 B 실행을 막던 문제 해결) |
| `14-type-nilable-default-overload` | ⚠️ 부분 — 의도한 오용은 막지만 정상 nilable 사용례까지 막아 현 스케치로는 채택 불가. **설계 결정은 아직 필요 없음**(대안이 이미 UB 경고로 존재)이라 `review-required`가 아님 |
| `16-type-store-key-typefunction` | **[2026-08-15]** ✅ 통과 — 원인은 설계 문제가 아니라 `types.newfunction` API 버전 드리프트(배열이 아니라 `{head=...}` 레코드). `ProcessStoreType<Input>`이 정확히 `{ty: Source<string>, count: Source<number>}` 구조를 만족, 음성 대조군 4건(틀린 Get/Set 타입 2건, 존재하지 않는 메소드) 전부 정확히 에러. 근거: `audit/type-recursive-issue-with-typeof/REPORT.md` 6-1절 |
| `21-type-store-undeclared-key-rejected` | **[2026-08-19 신규]** ✅ 통과 — `16`의 `ProcessStoreType`을 재사용해 미선언 키 접근 2건(읽기, 메소드 체이닝)이 정확히 `TypeError`로 거부됨을 확인, 양성 경로(선언된 키 3개) 클린. `store-plan.md`가 "아마 그럴 것"으로만 적어뒀던 걸 M0에서 실측 확정 |
| `23-type-quadtypes-checkversion-addplugin` | **[2026-08-19 신규, 같은 날 후속으로 재작성]** ✅ 통과 — 실제 `quad-types`/`quad-base`/`type-version-check`로 `CheckedQuad<T, Pattern>`+`AddPlugin<Self,P>` 통합 검증. 재작성 과정에서 `type function`을 거친 값은 패스스루라도 이후 제네릭 self 체이닝이 조용히 깨진다는 새 Luau 함정 발견(`typing-limits.md` §6으로 승격), `export type function`/이중 꺾쇠 제네릭 인스턴스화 요구도 같이 실측 — 최종 설계(별도 가상 필드로 격리)는 양성/음성 경로 모두 클린 |

### 특별히 중요한 통과 3건

**`04` — 직전 감사가 찾은 버그가 음성 대조군으로 재현됨**(파일은 지금
`rewrite-required/`에 있음 — 아래 관측 자체는 새 모델에서도 유효)

| 관측 지점 | 정상(수정본) | 대조군(버그) |
|---|---|---|
| 최초 마운트 후 체인 깊이 | **3** | **1** |
| 재발행 후 옛 store 구독 | 0 (끊김) | 1 (안 끊김) |
| 죽은 store를 건드리면 | 값 유지 | **`STALE`로 덮어써짐** |

`chains:SetStrong`을 `handler.process` 뒤에 두면 하위 retractor가 통째로
유실되고, 결국 **버려진 store가 나중에 UI를 덮어쓰는** 데까지 감.

**`07` — GC-native 아키텍처의 핵심 전제**
```
inst 5개만 살린 상태 → 살아남은 payload 5 / 엔트리 5   (기대치 일치)
모든 참조를 놓은 뒤   → 살아남은 payload 0 / 엔트리 0   (기대치 일치)
```
`bindLifetime`으로 매달아둔 자원이 `inst`와 함께 연쇄 소멸함이 확인됨.
(이 스파이크는 원래 sanity check만 하고 있어서 이번에 보강한 것 — 파일이
스스로 적어둔 "weak table 엔트리를 셀 방법 없음"이라는 전제가 틀렸음.)

**`18` — `relate-plan.md`의 상호 순환 경고**
```
상호 강참조 순환:        inst=true,  value=true   (GC 못 풂)
한쪽을 weak-value로 낮춤: inst=false, value=false  (풀림)
```
추측이 아니라 **실제로 GC가 안 됨** — `Slot`의 두-`Relate` 수정이 필수
조치였음이 입증.


## 🔵 만들어야 할 스파이크 — 아직 파일이 없음 (2026-08-21 신설)

폴더가 곧 상태인 이 문서에서 **"아직 파일조차 없는 실측 항목"**은 어느
폴더로도 표현되지 않아 그냥 잊혔다. 실제로 QA 4라운드 followup(H-7)이
"실측으로 남은 것"의 소스로 이 문서를 지목했는데 여기 항목이 없었다.
앞으로 이 절이 그 소스다 — 파일을 만들면 `not-run/` 또는 실행 결과에 따라
해당 폴더로 옮기고 여기서 지운다.

| 검증할 것 | 왜 | 출처 |
|---|---|---|
| ~~`table.insert`가 배열 중간의 구멍을 재사용하는가~~ **[2026-08-24 폐기]** | **전제 자체가 없어졌다** — 6라운드 `H-7`로 `Ref.Callbacks`가 배열에서 `{[callback\|thread] = true}` **해시맵 셋**으로 바뀌었고, 해시맵엔 border 개념도 구멍도 없다(`base/ref-plan.md`). 이 스파이크는 만들지 말 것 | QA 4라운드 `R-11`(폐기), 6라운드 `H-7` |
| 중간 State가 상류 strong / 하류 weak 불변식으로 실제로 살아남는가 | `State → State → State → Observer` 체인에서 중간 노드를 강하게 붙잡는 주체가 문서 어디에도 없어 전파가 조용히 끊길 수 있음. **M3 착수 전 필요** | `base/source-state-plan.md`의 "미해결 — 중간 State가 살아남는가" 절, `question.md` 3번 |
| `Visible = false`인 GuiObject의 `AbsoluteSize`/`AbsolutePosition`이 갱신되는가 | `quad-roblox-fastscroll` 설계의 선행 실측. **Studio 필요** — 만들면 `not-run/`행 | `research/fastscroll-plan.md` |
