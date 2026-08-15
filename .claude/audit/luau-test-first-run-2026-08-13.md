# `.claude/luau-test/` 첫 실측 결과 (2026-08-13 여섯 번째 세션)

> **⚠️ [2026-08-13 열세 번째 세션 정정] 이 문서의 타입 관련 결론 하나가
> 뒤집혔습니다 — 아래 "⚠️ 실측으로 드러난 진짜 설계 이슈" 절의
> "콜백이 raw 값을 받으면 ✅ 완전 클린(0건)" 판정.**
>
> 그 판정은 **"진단이 0건이다"만 확인**한 것이었고, 반환 타입이 실제로
> 해소됐는지는 확인하지 않았습니다. 열세 번째 세션에 `luau-analyze
> --annotate`로 추론된 실제 타입을 열어보니 **raw 값 계약도 똑같이
> `Unifiable<Error>`로 새고 있었고**(틀린 타입에 대입해도 안 잡힘),
> 따라서 아래 표의 "raw 값 = 완전 클린"과 그에 근거한 "선택지 2로 가면
> 추론이 완벽해진다"는 서술은 **틀렸습니다.**
>
> 진짜 원인은 콜백 계약이 아니라 **`Compute`가 `State<U>`(자기 이름을
> 다른 타입 인자로 감싼 타입)를 반환한다는 것 자체**(Luau의 현 한계)로
> 확정됐고, 콜백의 lazy 핸들 계약은 **그대로 유지**됩니다.
>
> - 지금 유효한 규약: **`base/typing-limits.md`**
> - 재실측 전문(스파이크 44개): **`audit/type-recursion-issue/`**
>
> 아래 런타임 스파이크 결과(12개 통과, `04`/`07`/`18` 절)는 **그대로
> 유효**합니다 — 정정 대상은 타입 절뿐입니다.

**배경**: 2026-08-09 열두 번째 세션에 스파이크를 만들기 시작한 이래
**처음으로 `luau`/`luau-analyze` 바이너리가 사용 가능해져 실제로 돌려본
결과**. 그동안 CLAUDE.md가 "M0 착수 전 남은 유일한 게이트"로 꼽아온 항목.

사용자 요청: "지금 상황에서 문제가 생겨 프로젝트의 구조 변경이 생기면 큰
작업인데, 이것이 더 큰 스파이크로 번지기 전에 미리 확인하고싶습니다."

## 런타임 스파이크 (`luau`)

| 파일 | 판정 | 요지 |
|---|---|---|
| `01-two-pass-array-hash-order` | ✅ 통과 | 배열 파트 전체 → 해시 파트 순으로 처리됨. `Dispatch.drive`의 두 패스 계약과 `PreRef` 호이스팅이 기대는 바로 그 순서 |
| `02-none-sentinel-vs-nil-holes` | ✅ 통과 | `nil` 소진 시 `#t`가 50→**49**로 무너지고 순회가 흐트러짐 / `None` 소진은 `#t`가 항상 50. 반대로 Ref 콜백 배열은 `None`을 쓰면 1000회 반복 후 **죽은 슬롯 1000개**가 그대로 남음 — 두 배열의 규칙이 서로 반대여야 한다는 2026-08-09 열한 번째 세션 정정이 정량적으로 확인됨 |
| `03-recursive-store-bind-dispatch` | ✅ 통과 | StoreBind 재귀 재-dispatch, `None`→`nil` 흘러가기, 무한재귀 없이 종료 |
| `04-dispatch-chain-retractFrom` | ✅ 통과 + **버그 재현** | 아래 별도 절 |
| `05-store-state-diamond-propagation` | ⚠️ **통과했으나 검증 대상이 뒤집힘**(2026-08-14) | 다이아몬드 의존성에서 `stateC` 재계산이 정확히 1회(중복 재계산 없음)라는 **앞부분은 그대로 유효**. 다만 "invalidate는 2번 도달하지만 2번째가 즉시 중단"은 **폐기된 모델**을 검증한 것 — 그 전파 중단 규칙이 `Observer` 계약과 모순돼 역전됨(`archive/invalidate-dedup-propagation-reversed.md`). 스파이크는 `rewrite-required/`로 이동, 재작성 후 재측정 필요 |
| `06-component-boundary-nil-hole-props` | ✅ 통과 | `or None` 없으면 앞쪽 nil-hole로 `bad[1]`/`bad[2]`가 사라짐, 관용구 쓰면 항상 5칸 유지 |
| `07-relate-weak-table-gc` | ✅ 통과(**이번에 보강 후**) | 아래 별도 절 |
| `11-modifier-illegal-value-error` | ⚠️ 부분 | 대부분 의도된 가드 에러로 통과하나 "다른 Modifier" 케이스만 브랜드 판별이 크래시해 **엉뚱한 이유로 통과** — 수정 진행 |
| `17-modifier-index-tableclone-chaining` | ❌ 크래시 | `attempt to call a number value`(44행)로 죽어 **아무것도 검증 못 함** — 수정 진행 |
| `18-relate-mutual-cycle-gc` | ✅ 통과 | 아래 별도 절 |
| `20-slot-splice-index-arithmetic` | ✅ 통과 | 11개 경계 케이스 전부 참조 구현과 일치(delta 양/음, 맨앞/맨끝, 전체 교체 등) |

`10-roblox-studio-checks.server.luau`는 Studio 전용이라 이 라운드 범위 밖
(부분 결과는 `audit/gcconn-trick-verification.md`).

## `04` — 이번 세션 감사가 찾은 버그가 실측으로 재현됨 (가장 중요)

같은 스크립트가 두 시나리오를 돌림: `chains:SetStrong`을 `handler.process`
**앞**에 두는 정상 설계와, **뒤**에 두는 음성 대조군.

| 관측 지점 | 정상(수정본) | 음성 대조군(버그) |
|---|---|---|
| [1] 최초 마운트 후 체인 깊이 | **3** (기대) | **1** ← 인덱스 2/3 retractor 유실 |
| [3] 바깥 store 재발행 후 옛 inner 구독 | **0** (끊김) | **1** ← 안 끊김 |
| [4] 죽은 store를 건드렸을 때 | `w1` 유지 | **`STALE`로 덮어써짐** |

즉 이 버그는 "리소스가 좀 샌다" 수준이 아니라 **이미 버려진 store가
나중에 UI를 덮어쓰는** 증상까지 간다는 게 실측으로 확인됨. 수정
(`SetStrong` hoist + no-op 점유 마커)이 옳았다는 결정적 근거.

> **[2026-08-14 리뷰에서 정정] "no-op 점유 마커" 부분은 이후 폐기된
> 옛 모델 서술입니다.** `chains:SetStrong`을 `process` 호출 *전에* 끝내야
> 한다는 순서 버그(위 표, `retractor` 유실/`STALE` 재현)는 하강 diff
> 재설계(2026-08-13 열네 번째 세션, `base/dispatch-core-plan.md`)에서도
> 그대로 유효 — 지금 `Dispatch.process`도 여전히 `chains:GetStrong`/
> `SetStrong`으로 list를 먼저 확보한 뒤에 `h.process`를 부름. 다만 "점유
> 마커"(같은 인덱스가 이미 점유돼 있으면 즉시 error)는 그 뒤 **Dispatch의
> 점유 체크 자체가 폐지**되며(`dispatch-core-plan.md` "Dispatch 체인" 절)
> 없어진 옛 개념 — 지금은 `list[index] = { handler = h, retractor = NOOP }`
> placeholder만 미리 박아두는 것으로 대체됨(같은 "호출 전 자리 확보"
> 목적, 에러를 내는 메커니즘은 아님). 이 스파이크는 `rewrite-required/`로
> 이동돼 있고(`luau-test/STATUS.md`), 재작성 시 이 절의 "정상(수정본)"
> 시나리오도 새 모델(placeholder, 점유 에러 없음)로 갱신할 것.

## `07` — 스파이크를 보강해야 실제 검증이 됐음

원래 3번 섹션이 "강하게 붙잡아둔 10개가 살아있는가"라는 **sanity check만**
하고 있었고, 헤더가 내세운 핵심 주장("inst가 죽으면 중첩된 것까지 전부
같이 GC")은 검증되지 않은 채였음. 파일 자신도 "Luau가 weak table 내부
엔트리 개수를 세는 표준 API를 안 줘서 직접 카운트 불가"라고 적어뒀는데
**그 전제가 틀렸음** — outer가 `__mode="k"`이므로 GC 후 죽은 엔트리는
`pairs` 순회에서 그냥 사라져 직접 셀 수 있음.

그래서 이번에 `relate._countEntries()`(테스트 전용)와 **weak-value canary
레지스트리**를 추가해 4번 섹션을 신설, 연쇄 GC를 직접 검증:

```
inst 5개만 살린 상태에서 살아남은 payload 수: 5   (기대 5 — 45개는 연쇄 GC)
relate4의 살아있는 엔트리 총 개수:            5   (기대 5)
모든 inst 참조를 놓은 뒤 살아남은 payload 수: 0   (기대 0)
relate4의 살아있는 엔트리 총 개수:            0   (기대 0)
```

**`base/lifecycle-pattern.md`(GC-native 관용구)와 `base/relate-plan.md`
전체가 기대고 있는 전제가 실측 확인됨** — quad의 GC-native 아키텍처
(명시적 Destroy 강제 없음, `bindLifetime`으로 매달아둔 자원이 inst와 함께
자동 소멸)가 실제로 성립함.

## `18` — `Relate` 상호 순환 경고가 실측 확인됨

`base/relate-plan.md` "위험한 패턴" 절이 공식 문서 인용(Luau에 ephemeron
없음)으로만 뒷받침되던 주장:

```
1. 상호 강참조 순환:        inst 살아있음 = true,  value 살아있음 = true   (GC 못 풂)
2. 한쪽을 weak-value로 낮춤: inst 살아있음 = false, value 살아있음 = false  (풀림)
```

**추측이 아니라 실제로 GC가 안 되는 게 확인됨** — `Slot`의
`kSlotMap`/`slotOwner`를 둘 다 `SetWeak`로 낮춘 2026-08-12 열세 번째
세션 결정이 필수 조치였음이 입증됨.

## 타입 스파이크 (`luau-analyze`) — 판정 완료

| 파일 | 판정 | 요지 |
|---|---|---|
| `08-type-source-satisfies-state` | ✅ 부분통과 | 핵심 질문(`Source<T>`를 `State<T>` 자리에 그대로 넘기기)은 클린 통과 — 구조적 서브타이핑 성립. 별개로 `State<T>`가 **자기 자신**을 다른 타입 인자로 재귀 참조하면 `Recursive type being used with different parameters` — M0에서 타입 선언 작성 시 유의할 좁은 제약 |
| `09-type-modifier-overridden-subtype` | ✅ 통과 | 문서가 우려한 지점(`FrameModifier`↔`GuiObjectModifier`)이 그대로 재현 — `Apply`의 리턴 타입 불일치로 서브타입이 깨짐. fallback(`any`)은 정상. 확인하려던 걸 정확히 확인 |
| `12-type-attribute-generic-key-narrowing` | ❌ 실패(**설계 영향 없음**) | 제네릭 키의 `T`가 이름별로 고정 안 되고 호출마다 독립 추론돼 narrowing이 전혀 강제 안 됨. **`attribute-plan.md`가 이미 이 결과를 fallback으로 예비**("안 되면 `BooleanAttribute` 같은 타입 패밀리가 유일하게 믿을 수 있는 정적 체크 경로") — 문서의 "[실측 필요]" 마커만 "확인됨: 안 됨"으로 갱신하면 됨 |
| `13-type-ref-preref-subtype` | ✅ 통과 | `PreRef<T>`가 `Ref<T>` 자리에 대입 가능 — 진단 0건 |
| `14-type-nilable-default-overload` | ⚠️ 부분통과 | 의도한 오용은 정확히 막지만 **정상 nilable 사용례까지 같이 막아** 현 스케치로는 채택 불가 |
| `15-type-compute-trailing-deps-typepack` | ❌ 검증불가 | 음성 대조군의 타입 표기가 `TypeError`가 아니라 `SyntaxError`로 걸려 파일 전체가 파싱 실패. 다만 파서가 복구 후 낸 진단에서 **아래 1번 이슈**가 드러남 |
| `16-type-store-key-typefunction` | ❌ 실패(당시) → **[2026-08-15] ✅ 통과로 복구** | `type function` 스케치의 `types.newfunction` 시그니처가 설치된 버전의 실제 API와 안 맞음(레코드 대신 배열을 넘기고 있었음) — 설계 문제 아니라 API 버전 드리프트였음이 나중에 확인됨. 상세: `audit/type-recursive-issue-with-typeof/REPORT.md` 6-1절, `luau-test/done/16-type-store-key-typefunction.luau` |

## ⚠️ 실측으로 드러난 진짜 설계 이슈 — `:Compute(fn)`의 lazy 핸들 계약이 Luau 추론과 충돌

**이번 실측 라운드에서 나온 가장 중요한 발견.** 최소 재현으로 원인을
정확히 좁혔음(에이전트 보고를 액면 그대로 받지 않고 직접 검증):

| 형태 | 진단 |
|---|---|
| 콜백이 `State<T>`(lazy 핸들)를 받음, **무주석 인라인 람다** | ❌ 2건 |
| 위 + `Get`을 `read`로 선언 | ❌ 여전 |
| 위 + `Get: (self: State<T>) -> T` 형태로 변경 | ❌ 여전 |
| 콜백 **파라미터에 타입 주석**을 달면 | ✅ 0건 |
| 콜백이 **raw 값 `T`** 를 받으면(`fn(v)`) | ~~✅ **0건**~~ **[13차 세션 정정] 진단만 0건이고 반환 타입은 똑같이 `Unifiable<Error>` — 안전하지 않음** |

즉 **원인은 "콜백이 lazy `State<T>` 핸들을 받는다"는 quad의 커링 계약
그 자체**임. `read`/`self` 표기 조정으로는 안 풀리고, raw 값을 넘기면
완벽히 추론됨.

> **[13차 세션 정정] 위 문단이 틀렸음.** 원인은 커링 계약이 아니라
> `Compute`의 **반환 타입**(`State<U>`)이고, raw 값을 넘겨도 "완벽히
> 추론"되지 않음(진단만 0건). 정확한 원인 분리와 근거는
> `audit/type-recursion-issue/`, 규약은 `base/typing-limits.md`.

```lua
-- 지금 확정된 관용구 — 타입 추론 실패
state:Compute(function(s) return s:Get() * 2 end)
-- 우회책 1: 파라미터 주석(가장 흔한 자리에 매번 타입을 써야 함)
state:Compute(function(s: State<number>) return s:Get() * 2 end)
```

**이건 `:Compute`만의 문제가 아님** — `Effect`/`Observer`/`Animate`/
`Operator` 카탈로그 등 "콜백이 lazy 핸들을 받는다"는 계약을 공유하는
API 전부에 걸림. 2026-08-07 일곱 번째 세션의 커링 스타일 확정,
2026-08-12 네 번째 세션의 "`:Get()` 누락 버그 전역 감사"가 전부 이 계약
위에 서 있음.

**결정은 사용자 몫** — `.claude/question.md`에 올림. 선택지:
1. 계약 유지 + 파라미터 주석 필수(인체공학 손해, 가장 흔한 자리에 매번).
2. 콜백이 raw 값을 받도록 전환(추론은 완벽해지나 lazy/trailing-deps/
   `previous` 설계 전반과 충돌 — **구조 변경 규모가 큼**).
3. 혼합(무주석은 raw, 명시적으로 lazy가 필요할 때만 별도 API).

> **[13차 세션 정정 — 위 선택지 셋 다 폐기됨]** 재실측 결과 이 셋은
> 전부 잘못된 프레이밍이었음(2번은 전제 자체가 틀렸고, 1/3번도 반환
> 타입 문제를 못 고침). **최종 결론: 계약은 그대로 유지, 남은 건 Luau의
> 현 한계라 quad가 할 수 있는 게 없음.** 대응은 "파생 State를 만드는
> 자리마다 결과 타입을 명시 주석으로 바인딩"하는 관례 하나 —
> `base/typing-limits.md`.

## 그 외 — 스파이크 코드 결함이었던 것들 (전부 수정 완료)

- **`17` 크래시의 원인이 실은 문서 결함이었음** — `modifier-plan.md`의
  "데이터를 테이블에 직접 두고"가 "self 최상위 리터럴 키"로 읽힐 여지가
  있었는데, 그렇게 하면 `__index`가 `rawget` 성공 시 안 불리므로 **같은
  필드를 두 번째로 변환 함수와 함께 호출하는 순간 죽음**(`attempt to call
  a number value`). 그 재호출 패턴이 바로 문서 3·4번 절의 대표 용례라
  실사용에서 즉시 터지는 경로였음 — `modifier-plan.md`에 경고 문단
  추가하고, 필드를 내부 저장소에 두는 구조로 `17`을 재작성해 통과 확인.
- `11`의 "다른 Modifier" 케이스가 브랜드 판별 크래시로 **엉뚱하게 통과**하던
  것 수정 — 이제 의도된 가드 에러로 검증됨(16개 케이스 전원 통과).
- `19`의 B/C 섹션을 현행 설계로 재작성(옛 `rawNew`+`owners`, 3분기
  `claimOwner` 폐기 반영). **음성 대조군을 넣어** 옛 로직이 `Slot{a,a}`와
  `Frame{slot,slot}`을 조용히 통과시키는 것까지 재현 확인.
- `07`을 보강(위 절 참고).

**최종 런타임 상태: 12개 전원 통과**(01/02/03/04/05/06/07/11/17/18/19/20),
crash 0, FAIL 0.

> **[2026-08-14 정정 — 이 "전원 통과"를 액면 그대로 읽지 말 것]** 통과
> 자체는 사실이지만, 그 뒤 **검증 대상이던 설계가 바뀐 스파이크가 셋**
> 생겼음(`04`/`19`는 열네 번째 세션의 하강 diff 재디스패치로, `05`는
> 2026-08-14의 "emit은 항상 전파" 정정으로). 셋 다 `rewrite-required/`에
> 있고 **재작성 후 재측정이 필요함** — 즉 지금 기준 "현행 설계를 검증하며
> 통과한" 런타임 스파이크는 9개임. 개수의 소스는 항상
> `luau-test/STATUS.md`.

## 스파이크 자체 수정이 더 필요한 것 (설계 문제 아님)

- `13`: B 런타임 섹션이 A의 더미 스텁에 막혀 단독 실행 불가 — 분리 필요.
- `15`: 음성 대조군을 별도 파일/블록으로 격리해 `SyntaxError`가 A/B/D
  판정을 막지 않도록.
- `16`: 설치된 버전의 `types.*` 실제 API 재확인 후 재시도. **[2026-08-15
  완료]** — `done/`으로 이동, 위 표에 반영.

## 결론

**런타임 설계는 전부 성립** — 검증된 주장마다 예외 없이 통과했고, 특히
GC-native 아키텍처의 핵심 전제(연쇄 GC)와 `Relate` 상호 순환 경고가
실측으로 확정됨. 이번 세션 감사가 찾은 버그도 음성 대조군으로 재현되어
**감사→수정 사이클이 실측으로 닫힘**.

**타입 쪽에서 하나가 걸림** — `:Compute(fn)`의 lazy 핸들 계약이 Luau
양방향 추론과 충돌(위 절). 사용자가 우려한 "구조 변경이 생기면 큰 작업"에
해당할 수 있는 유일한 항목이고, **선택지 2를 고르면 실제로 큰 작업**이므로
M0 착수 전에 결정해두는 게 맞음.

> **[13차 세션 정정]** 위 문단의 걱정은 **결과적으로 기우였음** — 재실측
> 결과 선택지 2(raw 값 전환)는 애초에 문제를 안 고치므로 "큰 작업"을
> 할 이유 자체가 없어졌음. 계약을 그대로 두는 게 정답이고, **구조
> 변경은 전혀 필요 없음**. 다만 진짜 원인(반환 타입)은 Luau가 고쳐줄
> 때까지 남으므로 명시 주석 바인딩 관례로 대응 —
> `base/typing-limits.md`.

`modifier-plan.md`의 `__index` 저장 위치 모호성은 문서 결함이었고 이번에
수정 — 스파이크가 없었으면 M2/M6 구현 중에 터졌을 건이라, 실측 라운드
자체의 값어치를 보여준 사례.
