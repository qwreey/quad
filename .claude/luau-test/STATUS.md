# 스파이크 상태판 — **폴더가 곧 상태**

> 마지막 갱신: 2026-08-14 (**"emit은 항상 전파"** 정정으로 `05`가 옛 모델을
> 검증 중이라 `rewrite-required/`로 이동 —
> `archive/invalidate-dedup-propagation-reversed.md`). 직전 갱신은 같은 날 **세 번째 세션**(`bindLifetime`/`canExecute`/
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
| `done/` | 통과 or 판정 끝, 더 할 일 없음 | 13 | — |

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
- 실측 근거 전문(스파이크 44개 포함): `audit/type-recursion-issue/`

`15`도 같은 계약을 다루지만 **스파이크 자체가 파싱 실패**라
`rewrite-required/`에 그대로 둠 — 재작성 대상이지 사람 결정 대상이
아님(계약 자체는 위에서 이미 확정됨).

## 🟠 `rewrite-required/` — 스파이크가 낡음 (7건)

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

| 파일 | 상태 | 무엇을 고쳐야 하나 |
|---|---|---|
| `04-dispatch-chain-retractFrom.luau` | 옛 모델 기준으로는 ✅ 통과였음 | (1) `chains` 슬롯이 `{handler, retractor}`가 되고 `Dispatch.process`가 핸들러를 먼저 비교하는 **하강 diff**로 재작성, (2) `retractFrom`은 **3-인자**(힌트 인자 없음), (3) "힌트가 target 인덱스에만 간다"를 검증하던 부분은 **정반대**로 뒤집힘 — 이제 각 레벨이 자기 값을 받는지를 검증해야 함. **살릴 것**: `chains:SetStrong` 순서 음성 대조군(그 버그는 새 모델에서도 그대로 유효) |
| `19-ownership-refcount-relate-patterns.luau` | A/C ✅ 유효, **B 섹션이 낡음** | B가 검증하던 "공개 `AttributeKey(name)` + 인덱스 1 점유 체크"가 폐기됨 — **그룹 전용 키 + `AttributeKeyHandler`의 이름 claim**으로 재작성하고, 음성 대조군도 "두 그룹이 같은 이름 → 즉시 error", "그룹↔직접 쓰기 → 즉시 error"로 바꿀 것(0-Z 확정 내용). A/C는 손댈 것 없음 |
| `05-store-state-diamond-propagation.luau` | 옛 모델 기준으로는 ✅ 통과였음 | **검증하던 모델이 뒤집힘**(2026-08-14) — 이 스파이크는 "이미 dirty면 더 아래로 전파하지 않음"을 assert하는데, 그게 `Observer` 계약과 모순돼 폐기됨(`archive/invalidate-dedup-propagation-reversed.md`). 재작성 방향: **emit은 자기 invalid 상태와 무관하게 항상 전파**되는지, 중복 재계산은 `:Get()` 시점 캐시로만 막히는지(재계산 1회 검증은 그대로 유효), 그리고 **`:Get()`을 안 부르는 `Observer`가 매 변경마다 계속 울리는지**(옛 모델에선 두 번째부터 침묵 — 이게 음성 대조군으로 딱 맞음) |
| `13-type-ref-preref-subtype.luau` | 타입 A섹션 ✅ 통과 / **런타임 B섹션 실행 불가** | B가 A의 더미 스텁(`fakePreRef = nil`)에 막혀 도달 못 함 — 두 섹션을 파일로 분리 |
| `15-type-compute-trailing-deps-typepack.luau` | **파싱 실패**(SyntaxError) | 음성 대조군의 타입 표기가 `TypeError`가 아니라 `SyntaxError`로 걸려 **파일 전체가 아무것도 검증 못 함** — 대조군을 별도 파일/블록으로 격리 |
| `16-type-store-key-typefunction.luau` | ❌ 실패 | `types.newfunction` 시그니처가 설치된 버전의 실제 API와 안 맞음 — 실제 API 재확인 후 재시도 |
| `10-roblox-studio-checks.server.luau` (Studio 전용) | 미실행 + **A 섹션이 옛 모델** | A가 폐기된 `canBound`/`bindLifetime`의 `.Subscribed` 세팅/2-인자 `canExecute`를 검증 중 — **`canExecute(value)` 1-인자 + `bindLifetime`이 gcconn을 `value` 쪽 릴레이션에 복사하는 모델**로 재작성할 것(`base/lifecycle-pattern.md`). 이중 바인딩 게이트도 `canBound`가 아니라 `if canExecute(v) then error(...) end`로. **살릴 것**: "ClassName 신호 미발화 / Destroy 시 `Connected` 즉시 전환" 검증(새 모델에서 더 중요해짐), gcconn/gchold를 **Instance 생성 시점**에 만드는 것으로 바꿀 것(옛 lazy 생성 폐기). B/C 섹션은 손댈 것 없음 |

## ⚪ `not-run/` — 이 환경에서 못 돌림

**[2026-08-14 다섯 번째 세션] 스파이크는 0건** — 유일했던 `10`이
`rewrite-required/`로 갔음(위 표). 남은 건 헬퍼 하나뿐.

| 파일 | 이유 |
|---|---|
| `gc-trigger-helper.server.luau` | 스파이크가 아니라 **헬퍼** — Studio에 `collectgarbage()`가 없어서 GC를 강제 트리거하는 기법. `10`을 돌릴 때 같이 씀 |

## ✅ `done/` — 통과 or 판정 끝 (13건)

**런타임 12개 전원 통과**(crash 0 / FAIL 0) — **[열네 번째 세션] 그중
`04`/`19`, [2026-08-14] 추가로 `05`는 검증 대상 설계가 바뀌어 위
`rewrite-required/`로 이동했고, 아래 표엔 남은 9개만 있음**(실측 당시
통과였다는 사실 자체는 유효):

| 파일 | 확인된 것 |
|---|---|
| `01-two-pass-array-hash-order` | 배열 파트 전체 → 해시 파트 순. `Dispatch.drive` 두 패스 계약과 `PreRef` 호이스팅의 전제 |
| `02-none-sentinel-vs-nil-holes` | `nil` 소진 시 `#t` 50→49로 무너짐 / `None`은 항상 50. 반대로 Ref 콜백 배열은 `None` 쓰면 죽은 슬롯 1000개 잔존 — **두 배열의 규칙이 서로 반대여야 함**이 정량 확인 |
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
| `12-type-attribute-generic-key-narrowing` | ❌지만 **설계 영향 없음** — 제네릭 키 narrowing이 안 되는 건 `attribute-plan.md`가 이미 fallback으로 예비해둔 결과(타입 패밀리가 유일하게 믿을 경로) |
| `14-type-nilable-default-overload` | ⚠️ 부분 — 의도한 오용은 막지만 정상 nilable 사용례까지 막아 현 스케치로는 채택 불가. **설계 결정은 아직 필요 없음**(대안이 이미 UB 경고로 존재)이라 `review-required`가 아님 |

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
