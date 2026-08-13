# 스파이크 상태판 — **사람이 먼저 볼 것만 위에**

> 마지막 갱신: 2026-08-13 여섯 번째 세션(첫 실측 라운드).
> 상세 결과는 `.claude/audit/luau-test-first-run-2026-08-13.md`.
> 실행법: `luau <파일>` (런타임) / `luau-analyze <파일>` (타입 전용).

## 🔴 사람 결정 필요 — 설계가 걸린 것 (2건)

| 파일 | 무엇이 걸렸나 | 어디로 |
|---|---|---|
| `15-type-compute-trailing-deps-typepack.luau` | **`:Compute(fn)`의 lazy 핸들 계약이 Luau 추론과 충돌.** `state:Compute(function(s) return s:Get()*2 end)`가 타입 에러. 콜백이 raw 값을 받으면 완전 클린 — 즉 표기 조정이 아니라 계약 자체가 원인. `Effect`/`Observer`/`Animate`/`Operator` 등 같은 계약 공유 API 전부에 걸림 | `question.md` **0-Y** |
| `08-type-source-satisfies-state.luau` | 핵심 질문(Source⊇State)은 통과. 다만 `State<T>`가 **자기 자신**을 다른 타입 인자로 재귀 참조하면 `Recursive type being used with different parameters` — 사용자 방향은 "구울 때 인라이닝" | `question.md` **0-Y** 하단 |

## 🟠 스파이크 자체가 깨져 있음 — 재작성 필요 (3건, 설계 문제 아님)

| 파일 | 상태 | 무엇을 고쳐야 하나 |
|---|---|---|
| `13-type-ref-preref-subtype.luau` | 타입 A섹션은 ✅ 통과 / **런타임 B섹션 실행 불가** | B가 A의 더미 스텁(`fakePreRef = nil`)에 막혀 도달 못 함 — 두 섹션 분리 |
| `15-type-compute-trailing-deps-typepack.luau` | **파싱 실패**(SyntaxError) | 음성 대조군의 타입 표기가 `TypeError`가 아니라 `SyntaxError`로 걸려 **파일 전체가 아무것도 검증 못 함** — 대조군을 별도 파일/블록으로 격리 |
| `16-type-store-key-typefunction.luau` | ❌ 실패 | `types.newfunction` 시그니처가 설치된 버전의 실제 API와 안 맞음 — 실제 API 재확인 후 재시도 |

## ⚪ 아직 안 돌림

| 파일 | 이유 |
|---|---|
| `10-roblox-studio-checks.server.luau` | **Studio 전용**(`luau` CLI로 못 돌림). A 섹션 일부만 사용자가 자작 스크립트로 실측 — `audit/gcconn-trick-verification.md`. A-1/A-2/B/C는 여전히 미확인 |

---

## ✅ 통과 — 설계 성립 확인됨 (런타임 12개)

| 파일 | 확인된 것 |
|---|---|
| `01-two-pass-array-hash-order` | 배열 파트 전체 → 해시 파트 순. `Dispatch.drive` 두 패스 계약과 `PreRef` 호이스팅의 전제 |
| `02-none-sentinel-vs-nil-holes` | `nil` 소진 시 `#t` 50→49로 무너짐 / `None`은 항상 50. 반대로 Ref 콜백 배열은 `None` 쓰면 죽은 슬롯 1000개 잔존 — **두 배열의 규칙이 서로 반대여야 함**이 정량 확인 |
| `03-recursive-store-bind-dispatch` | StoreBind 재귀 재-dispatch, `None`→`nil` 흐름, 무한재귀 없이 종료 |
| `04-dispatch-chain-retractFrom` | 인덱스 기반 체인 + **음성 대조군이 감사 버그를 재현**(아래 별도 절) |
| `05-store-state-diamond-propagation` | 다이아몬드에서 재계산 정확히 1회, invalidate 2번째는 즉시 중단 |
| `06-component-boundary-nil-hole-props` | `or None` 없으면 앞쪽 nil-hole로 슬롯 소실, 관용구 쓰면 항상 보존 |
| `07-relate-weak-table-gc` | **연쇄 GC 확정**(아래 별도 절) — GC-native 아키텍처의 핵심 전제 |
| `09-type-modifier-overridden-subtype` | 문서가 우려한 `FrameModifier`↔`GuiObjectModifier` 서브타입 깨짐이 그대로 재현, fallback(`any`)은 정상 |
| `11-modifier-illegal-value-error` | Modifier 필드/Source에 핸들러 계층 값 넣으면 즉시 error — 16개 케이스 전원 |
| `17-modifier-index-tableclone-chaining` | 제네릭 `__index` + `table.clone` 체이닝, 메타테이블 참조 공유, 형제 분기 무오염 |
| `18-relate-mutual-cycle-gc` | **두 `Relate` 상호 순환은 실제로 GC 안 됨**(아래 별도 절) |
| `19-ownership-refcount-relate-patterns` | Tag 참조 카운트 / Attribute 점유 체크 / Slot `claimOwner` vs `claimOwnerAt` — **음성 대조군 포함** 전원 통과 |
| `20-slot-splice-index-arithmetic` | `Splice` 산술 11개 경계 케이스 전부 참조 구현과 일치 |
| `12-type-attribute-generic-key-narrowing` | ❌지만 **설계 영향 없음** — 제네릭 키 narrowing이 안 되는 건 `attribute-plan.md`가 이미 fallback으로 예비해둔 결과(타입 패밀리가 유일하게 믿을 경로) |
| `14-type-nilable-default-overload` | ⚠️ 부분 — 의도한 오용은 막지만 정상 nilable 사용례까지 막아 현 스케치로는 채택 불가. 설계 결정은 아직 필요 없음(대안이 이미 UB 경고로 존재) |

### 특별히 중요한 통과 3건

**`04` — 직전 감사가 찾은 버그가 음성 대조군으로 재현됨**

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

---

## 이 표를 갱신하는 방법

스파이크를 돌리거나 고칠 때마다 **여기 분류부터 옮기고**, 상세 서술은
`audit/`의 실행 결과 문서에 쓸 것. 이 파일은 "지금 뭘 봐야 하는가"만
빠르게 답하는 용도라 길어지면 안 됨(파일별 검증 의도/배경은
`luau-test/README.md`가 이미 담당).
