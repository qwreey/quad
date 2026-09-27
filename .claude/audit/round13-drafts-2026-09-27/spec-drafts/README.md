# E76 — 변이 공백 48을 닫는 spec 초안(round13 `Q154` (a) 한 번에 받기용)

round13 자율 루프 탐사 E76. E69(`../../round13-e69-mutation/`)와 E73(`../../round13-e73-mutation-2/`)이 찾은 **실제 공백 48**(E69 27 — E73의
재분류 반영 뒤, E73 21)을 죽이는 판별 프로브를 이 레포의 spec 관용구(`print("=== N. … ===")` + `do … end` + `print("PASS")`)로 옮긴 초안이다.
`Q154`에 (a)로 답하면 여기 있는 `*.additions.luau`를 각 대상 spec의 끝 `ALL PASS` 줄 바로 앞에 붙이는 것으로 끝난다 — 소스(`src/`)와
`mock.luau`는 한 줄도 바꾸지 않는다. 본 트리의 기존 파일은 건드리지 않았고, 검증은 스크래치패드의 별도 git worktree(HEAD `0dc431dd`)에서 했다.

## 결과 요약

- 초안 13파일, 새 절 29개. 새 spec 파일은 없다 — 48개 모두 기존 spec에 자연스러운 자리가 있었다.
- 초안을 붙인 worktree에서 `./scripts/test.sh` **exit 0**(두 strict 패스 포함). 분석기 출력은 기준선과 한 글자도 다르지 않다(`spec.slot` 1275·1287·1302의
  `SameLineStatement` 린트 셋은 원래 있던 것). strict 때문에 고친 곳은 하나 — `spec.fallback` 초안의 `Traceback` 두 함수에 `: any` 반환 주석
  (주석 없이는 `(...any) -> (...unknown)`이 `(...any) -> unknown`에 안 맞는다는 TypeError가 두 패스 모두에서 났다; 기존 절 4와 같은 관용구).
- 공백 변이 48개를 E69/E73 드라이버와 같은 방식(변이 하나 → `luau-compile` → `relink.sh` → smoke/spec 전부)으로 다시 돌린 결과 **44개가 죽었다**.
  살아남은 넷(`BK02`·`BK04`·`ST04`·`ST09`)은 문서가 정의되지 않은 동작이거나 계약이 아니라고 적은 입력으로만 닿는 것이라 초안을 쓰지 않았다
  (아래 "문항 대기").
- 초안을 붙인 spec 13개를 여덟 번씩 반복 실행해 실패 0 — GC를 쓰는 절(`spec.robloxfactory` 10)도 흔들리지 않았다.

## 표 — 변이 → 대상 spec → 새 절 → 계약 출처 → 검증

| 변이 | 대상 spec | 새 절 | 계약 출처 | 검증 |
|---|---|---|---|---|
| E69 `BK16` | `quad-base/test/spec.slot.luau` | 39. 기준 오프셋이 0이 아닌 자리의 중첩 Slot | `docs/reference/core/06-slot.md` `slot.Offset` 동작 · `.claude/base/dispatch-core-plan.md` Length/Offset | 죽음 |
| E69 `SE01` | 〃 | 39 | 〃 | 죽음 |
| E69 `SW04` | 〃 | 40. IndexOf — 빠진·밀려난 원소는 nil | `core/06-slot.md` `slot:IndexOf` "없으면 nil" | 죽음 |
| E69 `SW07` | 〃 | 40 | 〃 | 죽음 |
| E69 `SW14` | 〃 | 41. :List — Detach 보관분을 nil로 버리면 파괴 | `core/06-slot.md` `:List` 반환 표 · `q.Detach` | 죽음 |
| E69 `SL04` | 〃 | 42. :List — 중복 키 Quad0145 | `core/06-slot.md` `:List` 재조정 중 에러 · `errors/03-slot.md` Quad0145 | 죽음 |
| E69 `SL06` | 〃 | 43. :List — UserData 왕복 | `core/06-slot.md` `ctx.UserData` 행·"두 번째 반환값은…" | 죽음 |
| E69 `SL10` | 〃 | 44. :List — 한 사이클 한 배치(Length 1회) | `core/06-slot.md` `:List` 동작 "한 사이클은 하나의 배치" | 죽음 |
| E69 `BK10` | 〃 | 44 | 〃 | 죽음 |
| E69 `SN01` | 〃 | 45. :List — 다른 Slot의 원소 반환은 Quad0156 | `errors/03-slot.md` Quad0156 | 죽음 |
| E69 `SN03` | 〃 | 46. `releaseOwner` 주인 불일치 Quad0163 | `errors/03-slot.md` Quad0163 · `extend/02` `releaseOwner` | 죽음 |
| E69 `SI09` | 〃 | 47. Splice 범위 Quad0174 | `errors/03-slot.md` Quad0174 | 죽음 |
| E73 `SH05` | 〃 | 48. 같은 Slot 같은 자리 재drive는 no-op | `extend/02` `claimOwnerAt`("정확히 같은 자리 … `false` … 물리 부착도 건너뛰면") | 죽음 |
| E73 `SH06` | 〃 | 48 | 〃 | 죽음 |
| E73 `SH03` | 〃 | 49. 파괴된 Slot 마운트 Quad0140 | `errors/03-slot.md` Quad0140 · Quad0164 절 | 죽음 |
| E73 `EL02` | 〃 | 50. 원소 게이트 Quad0238/0239 | `errors/03-slot.md` Quad0238 | 죽음 |
| E73 `EL04` | 〃 | 50 | `errors/03-slot.md` Quad0239 | 죽음 |
| E73 `SH01` | 〃 | 51. raw process의 0·소수 키 Quad0141 | `errors/03-slot.md` Quad0141(`process` 직접 호출 문장) | 죽음 |
| E73 `SH02` | 〃 | 51 | 〃 | 죽음 |
| E69 `EF17` | `quad-base/test/spec.effect.luau` | 13. 같은 Effect/Observer 같은 자리 재drive는 접힘 | `.claude/base/source-state-plan.md` "Observer/Effect Leaf dedup"(`H-266`) · `extend/02` 재처리 | 죽음 |
| E69 `EF18` | 〃 | 13 | 〃 | 죽음 |
| E69 `EF11` | 〃 | 14. WeakSubscribe 두 번 Quad0089 | `errors/04-ref-observer-effect.md` Quad0089 | 죽음 |
| E69 `OB06` | `quad-base/test/spec.tostring.luau` | 5. 구독을 푼 Observer는 `Observer(unsubscribed)` | `.claude/base/architecture.md` `__tostring` 목록 | 죽음 |
| E69 `DI07` | `quad-base/test/spec.dispatch.luau` | 22. index 구멍 Quad0075 | `errors/02-dispatch-bookkeeping.md` Quad0075 | 죽음 |
| E69 `DI10` | 〃 | 23. process가 던진 자리는 no-op 표식 — 옛 retractor 재호출 없음 | `extend/02` "한계와 주의"(`process`가 던지면 "no-op 표식을 단 채 남고") | 죽음 |
| E69 `TG08` | `quad-base/test/spec.tag.luau` | 8. 64단계 넘는 중첩 Quad0201 | `errors/05-tag-attr.md` Quad0201 | 죽음 |
| E69 `DB01` | `quad-base/test/spec.debounce.luau` | 14. State Time 음수는 신호 시점 Quad0039 | `errors/01-core-reactive.md` Quad0039 · `sugar/03-debounce-throttle.md` | 죽음 |
| E69 `OP03` | `quad-base/test/spec.operator.luau` | 8. Clamp(lo, lo) 허용 · Shr 논리 시프트 | `sugar/02-operator.md` `Clamp`("`lo > hi`이면") | 죽음 |
| E69 `OP05` | 〃 | 8 | `sugar/02-operator.md` 연산자 표 `Shr` = `bit32.rshift` | 죽음 |
| E73 `FB05` | `quad-base/test/spec.fallback.luau` | 5. Traceback의 trace는 던진 자리에서 | `sugar/05-fallback-traceback.md` `q.Traceback` "던진 자리에서" | 죽음 |
| E69 `PR10` | `quad-roblox/test/spec.tweenproperty.luau` | 12. Time = 0이라도 Reverses·RepeatCount면 엔진 트윈 | `roblox/06-tween-animate.md` 옵션 절 "그 셋 중 하나라도 있으면" | 죽음 |
| E73 `LR03` | `quad-roblox/test/spec.robloxfactory.luau` | 9. hold op·isClaimed는 순수 술어(nil → 거짓) | `extend/01` §3 표 `isClaimed (inst: any) -> boolean`(nil 명시는 없음 — 아래 주의) | 죽음 |
| E73 `LR06` | 〃 | 9 | `extend/01` §4 `isHeld` "nil에는 거짓" | 죽음 |
| E73 `LR08` | 〃 | 9 | `extend/01` §4 `isHeldBy` | 죽음 |
| E73 `LR10` | 〃 | 10. bindLifetime은 값을 살리고 unbind는 즉시 놓는다 | `extend/01` §4 `holdLifetime` | 죽음 |
| E73 `LR12` | 〃 | 10 | `extend/01` §4 `releaseLifetime` | 죽음 |
| E73 `LR13` | 〃 | 10 | 〃 | 죽음 |
| E73 `CL07` | `quad-roblox/test/spec.claim.luau` | 17. 1패스 게이트 넷 | `roblox/04-claim-mapper.md` 에러 표 Quad0031 · "아무것도 claim하기 전에" | 죽음 |
| E73 `CL15` | 〃 | 17 | 같은 표 Quad0034 | 죽음 |
| E73 `CL16` | 〃 | 17 | `errors/06-module-backend.md` Quad0026 | 죽음 |
| E73 `CL06` | 〃 | 17 | `errors/02-dispatch-bookkeeping.md` Quad0076(문자 키의 quad 값 꼬리) | 죽음 |
| E73 `CL17` | 〃 | 18. drive는 안쪽부터 바깥으로 | `roblox/04-claim-mapper.md` 동작 3 · `.claude/base/claim-plan.md` §4 | 죽음 |
| E73 `EO12` | `quad-roblox/test/spec.timers.luau` | 4. NaN delay Quad0216 | `errors/07-roblox.md` Quad0216 | 죽음 |
| E73 `DC02` | `quad-roblox/test/spec.d.luau` | 6. GuiObject에서 직계 하위로의 검사형 캐스트 | `roblox/03-d-modifier.md` 캐스트 예(`GuiObject():AsTextLabel()`) | 죽음 |
| E69 `BK02` | — | 초안 없음(문항 대기) | — | 생존 |
| E69 `BK04` | — | 초안 없음(문항 대기) | — | 생존 |
| E69 `ST04` | — | 초안 없음(문항 대기) | — | 생존 |
| E69 `ST09` | — | 초안 없음(문항 대기) | — | 생존 |

(표의 `errors/…`·`core/…`·`extend/…`·`sugar/…`·`roblox/…`는 전부 `docs/reference/` 아래. 각 초안 절의 머리 주석에 같은 출처와 변이 ID가 적혀 있다.)

## 문항 대기 — 초안을 쓰지 않은 넷

**`BK02`·`BK04`(Bookkeeping의 되감기 가드 두 줄).** E73이 이 경로를 여는 유일한 입력으로 찾은 것은 "닫힌 Gate 뒤의 길이 Compute가 계산 함수 안에서
다른 Source를 `:Set`하는" 모양이다. 그런데 `.claude/base/source-state-plan.md`의 "Compute 순수성" 절(2026-09-07 사용자 결정)은 Compute 함수 안의
`:Set`을 상류든 형제든 **정의되지 않은 동작**으로 못 박았다. 한편 `.claude/base/dispatch-core-plan.md`의 `H-240` (a)(2026-09-01 사용자 확정)는
"길이 `Get` 안의 사용자 코드가 부기를 바꾸면 채우기 루프가 자가 치유한다"를 계약으로 세웠고, 두 가드가 바로 그 치유 코드다. 즉 이 두 줄이 지키는
동작은 한 문서에선 약속이고 다른 문서에선 UB라, spec으로 단언하면 UB를 계약으로 굳히는 셈이 된다. 사용자가 정할 것은 "H-240의 자가 치유를
Compute 순수성 원칙 뒤에도 계약으로 유지하는가"다 — 유지한다면 E73 `probe.e73.luau`의 `PBK`·`PBKb`를 그대로 `spec.lengthoffset`의 새 절로 옮기면
둘 다 죽는다(E73 실측), 유지하지 않는다면 두 가드는 방어 코드이고 공백이 아니다.

**`ST04`(재계산 전 `dep:_track` 삭제).** E73 퍼저가 찾은 차이(`PST04`)는 "격번 통과 Gate 뒤의 Compute가 첫 실행에서 **자기 상류를** `:Set`"하는
입력에서만 난다. `docs/reference/core/03-state.md` 77행이 "계산 함수 안에서 자기 의존성을 쓰는 것 자체가 정의되지 않은 동작"이라고 적고 있고, 순수
fn에서는 E73 퍼저가 차이를 못 찾았다. 그래서 초안을 쓰지 않았다. 문서가 UB라고 부르는 한 이 변이는 공백이 아니라 동등(UB 입력 밖에서)으로 분류하는
것이 맞고, 그 재분류를 `Q154`에 함께 적을지가 문항이다.

**`ST09`(Gate flush의 `emitEpochMap:Sync` 삭제).** 차이(`PST09`)는 Gate 위의 Gate에서 하류 구독자가 **같은 값으로 한 번 더** 울리는 것, 그리고 아래
Gate의 `emit()`이 "모아둔 게 있었다"(`true`)를 돌려주는 것이다. 앞의 것은 `core/03-state.md` `state:Gate` 동작 절이 "게이트가 여럿이면 하류가
받는 횟수는 그래프·순회 순서에 따라 달라질 수 있습니다 — 횟수가 아니라 값에 기대세요"라고 계약에서 뺀 부분이다. 뒤의 것(`emit()` 반환값)은 "반환값은
모아둔 게 있었는가"라는 문장과 닿지만, "아래 Gate가 이미 흘려보낸 revision을 위 Gate가 다시 넘길 때 그것이 '모아둔 것'인가"는 문서가 정하지 않았다.
사용자가 정할 것은 "게이트 겹침에서의 emit 반환값·중복 통지를 계약으로 좁힐 것인가"다 — 좁힌다면 `PST09`를 `spec.gate`로 옮기면 된다.

`Q151`(`setLength`에 잘못된 초기값 State)은 이번 48개와 겹치지 않는다 — 초안 어디에도 `setLength`를 부르지 않는다.

## 주의 — 초안이 기대는 문장이 얇은 곳

- `LR03`(`q.Backend.isClaimed(nil)`이 거짓): 레퍼런스는 `isHeld`에 대해서만 "nil에는 거짓"을 명시하고 `isClaimed`는 시그니처(`(inst: any) -> boolean`)와
  구현 주석(`H-444` 계열)뿐이다. 초안은 "술어는 던지지 않는다"로 읽었다. 받아들인다면 `extend/01`의 `isClaimed` 문단에 "`nil`에는 거짓" 한 구절을 같이
  넣는 것이 짝이다.
- `CL06`(문자 키에 놓인 디스크립터): 지금 코드는 1패스를 지나 적용 단계의 `Quad0076`으로 죽고 루트는 claim된 채 남는다(04-claim-mapper가 적용 단계
  throw를 UB라 부르는 경우). 초안은 에러 ID만 단언하고 루트 상태는 단언하지 않는다 — 1패스에서 막을지는 별개 결정이다.
- `DC02`: 생성 간선 43개 중 GuiObject의 직계 여덟만 본다. 간선 표 전체 대조는 spec보다 생성기 `gen-d.py check` 층이 맞는 자리일 수 있다(E73 README와 같은 판단).
- `spec.slot` 44(`SL10`·`BK10`)는 발화 **횟수**를 단언한다. 단일 `Length` Source 하나에 대한 것이라 위 `ST09`의 "게이트 여럿이면 횟수 무계약"과는 다른 자리이고,
  근거는 06-slot의 "한 사이클은 하나의 배치 … 재계산이 한 번만"이다.

## 파일

| 파일 | 내용 |
|---|---|
| `spec.<이름>.additions.luau` (13개) | 대상 spec에 붙일 새 절만. 대상 파일의 지역 이름(`q`·`Slot`·`dispatch`·`mock`·`newQuad` 등)을 그대로 쓴다 |
| `apply.py` | worktree에 초안을 붙이는 스크립트 — 대상 파일의 마지막 `ALL PASS` 줄(두 모양 모두) 바로 앞(앞의 `print()`가 있으면 그 앞)에 넣는다. 먼저 `git checkout -- quad-*/test`로 원상 복구 |
| `run48.py` / `run48-results.json` | 공백 변이 48개만 E69/E73 드라이버 로직으로 다시 돌린 스크립트와 결과(변이별 잡은 spec, 실패 꼬리) |
| `test-sh-with-drafts.log` | 초안을 붙인 worktree의 `test.sh` 분석기 구간과 끝부분(exit 0) |

재현: `git worktree add <wt> HEAD` → `<wt>`에서 `mise exec -- pesde install` → `python3 apply.py <이 폴더> <wt>` → `./scripts/test.sh; echo $?` →
`python3 run48.py <wt> out.json`. 끝나면 `git worktree remove --force <wt>` + `git worktree prune`.
