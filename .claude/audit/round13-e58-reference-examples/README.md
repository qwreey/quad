# round13 E58 — 레퍼런스 예제 전수 mock 실행 + strict (2026-09-27)

HEAD `938cb310`. `docs/reference/00-index.md`와 `core|sugar|roblox|extend/*.md`(errors/ 제외)의 ```luau 펜스 전부를 뽑아
(a) 실행 대상·(c) 조각(보강 필요)·(d) Roblox 전용(셔임)은 mock 실행 + `--!strict` 신 솔버(`scripts/test.sh` 79행 플래그 셋 그대로),
P(프롤로그)·b(시그니처/타입 — E33 범위)는 분류만 했다. 레포 파일은 건드리지 않았다. 재실행: `./run.sh`.

## 하네스

- `extract.py` → `blocks/<파일>-L<펜스 다음 줄>.luau` + `index.tsv`. `spec.py`가 블록별 분류·보강(pre/post/sub)을 쥐고, `gen.py`가
  `mock/`(러너)·`strict/`(strict 파일)을 만든다. `report.py` → `out/table.md`.
- mock: `harness.luau`·`engine-globals.luau`는 E56(=E27/S10) 사본 — 한 벌(`quad-roblox/luau_packages`). 변경: REFLECTED에 `Part`·`Model`·
  Frame `Style`, 반환에 `QuadRoblox`; `Enum.EasingStyle.Quart`·`Enum.FrameStyle`. 문서 프롤로그의 `require`는 하네스의 `q`/`D`/`Quad`로
  바꾸고 타입 전용 모듈(`QuadTypes`·`RobloxModule`)은 빈 테이블, `task`는 가상 스케줄러, `warn`·`script`는 셔임.
- strict: 페이지 프롤로그 블록을 그대로 붙이고 require 경로만 로컬로(`@game/.../Client/UI/Quad` → `strict/Quad.luau` = GS 01 §1 설정 모듈의
  한 벌 사본(E56 `annotated/Quad.luau`); `roblox_packages/quad_types|quad_base` → `quad-roblox/luau_packages/…`; `quad_roblox`와 자리표시
  `<quad-roblox 모듈>` → `quad-roblox/src`). 보강 pre는 strict에도 들어가고 post/sub(mock 확인)는 안 들어간다.
- 음성 대조: `probes/negctl-strict.luau`(Source 대입 불일치·`Text = 42`) → TypeError 2(정상).
- "출력 일치" 판정: `-->`·주석·본문이 말한 값/상태를 `out/mock/<블록>.txt`와 손으로 대조. 주장이 없는 블록은 보강 post로 문서가 말한
  동작(부모·파괴 여부·속성·태그·신원)을 찍어 대조했다. Roblox 백엔드는 물리 순서를 바꾸지 않으므로(`EngineOps` `nativeMove` no-op)
  `GetChildren` 순서는 판정하지 않았다.

## 요약

| 항목 | 수 |
|---|---|
| 펜스 블록 | 304 (P 25 · b 167 · a 83 · c 11 · d 18) |
| 실행 대상(a+c+d) | 112 — 그중 조각이라 실행 불가 3(core/06:552 `ctx` 미정의, roblox/01:161 함수 머리 한 줄, roblox/04:189 `{ … }`) |
| mock 통과 | 108 / 109 (실패 1 = core/09:392 — mock `SetAttribute`가 Color3 셔임(테이블)을 거부, 하네스 한계) |
| 출력 불일치 | 0 (문서가 말한 값·상태 전부 일치; extend/02:375 뒤 문장의 "철거" 경로만 발견 A2) |
| strict 대상 | 109 |
| strict TypeError | 4줄 / 3블록 — 번호 있음 1블록 2줄(8.17, core/09:392 — 문서 caution에 이미), 의도 1(roblox/02:287 "타입 에러" 시연), **새로움 1(roblox/05:95 → A1)** |
| lint(LocalUnused 등) | 159줄 — 조각 예제의 미사용 지역 변수, 판정 대상 아님 |

## 발견

- **A1 (문서 오류, strict)** roblox/05-onchange.md:95~96 — 본문이 "`State<T>`는 불변이라 클래스별 유니언을 타입 인자로 명시해서 만듭니다"라 하고
  예제는 `q.Source<<RobloxModule.OnChangeDescriptor>>(q.OnChange("Visible", …))`를 `D.Frame({ desc })`에 넣는데, strict에서 그 두 번째 줄이
  TypeError다. 루트 재수출 `OnChangeDescriptor`는 비제네릭 `{ read Name: string, read Callback: (any) -> () }`이고 Frame 자식 자리의 State 팔은
  `StateMarker<FrameOnChange>`(`Name`이 리터럴 유니언)라 들어가지 않는다. `H-764`(감사 16라운드)가 공개 경로 없는 `FrameOnChange`를 이 이름으로
  바꿀 때 근거로 든 E33 W3는 "생성 디스크립터 → 재수출 타입 대입"만 확인했고 자식 자리 배치는 안 봤다. `probes/onchange-state-variants.luau`:
  문서 그대로 V1 에러, `RobloxModule.FrameElem?` V3 에러, 무주석 `q.Source(q.OnChange(…))` V2·`<<any>>` V4는 무진단. 런타임은 정상(mock).
  Q122 보강의 `<Class>OnChange` 재수출 갈래와 같은 뿌리.
- **A2 (문서 오류, 경미)** extend/02-dispatch-handler-contract.md:375 — 예제 뒤 문장 "그 자리가 철거되면 `unmount Note (retracting = true)`로 끝납니다"는
  `q.Dispatch.retractFrom`으로는 맞지만(`out/extend02-retractfrom.txt`) 독자가 쓸 사용자 표면 경로 둘은 그렇게 끝나지 않는다 — (1) 요소 `Destroy`는
  retractor를 부르지 않고(같은 문서 385행이 이미 말함, `out/extend02-retract-sequence.txt`), (2) State로 `q.None`을 발행하면 `retract(true)`가
  찍힌 **뒤** 이 예제 핸들러의 `isHandlable`이 `nil`을 거부해 `Quad0076`이 던진다(`out/extend02-none.txt`; 165행의 nil 안내와 같은 규칙). 값 교체
  순서(`false` → mount)는 문서대로다.
- (관찰, 낮음) roblox/03-d-modifier.md:25·roblox/05-onchange.md:22 프롤로그의 `require(<quad-roblox 모듈>)`은 자리표시라 복사하면 구문 에러인데,
  같은 트랙 roblox/01:153·roblox/06:22는 `require("@game/ReplicatedStorage/roblox_packages/quad_roblox")`로 실제 경로를 쓴다.

코드 결함(b): 0. 판단 필요(c, 새 strict 유형): 0 — A1은 새 유형이 아니라 8.11 공변 마커 + Q122 재수출 표면의 조합.

## 블록 표

| 파일 | 블록(줄) | 분류 | mock | 출력 일치 | strict | 비고 |
|---|---|---|---|---|---|---|
| core/01-quad-module.md | 40 | a | 통과 | 일치 | 0 |  |
| core/01-quad-module.md | 64 | a | 통과 | 일치 | 0 |  |
| core/01-quad-module.md | 104 | a | 통과 | 일치 | 0 |  |
| core/01-quad-module.md | 153 | a | 통과 | 일치 | 0 |  |
| core/01-quad-module.md | 188 | a | 통과 | 일치 | 0 | 보강(확인 출력) |
| core/01-quad-module.md | 233 | c | 통과 | 일치 | 0 | 보강: assertOwn 호출 둘 |
| core/01-quad-module.md | 267 | a | 통과 | 일치 | 0 |  |
| core/02-source.md | 51 | a | 통과 | 일치 | 0 |  |
| core/02-source.md | 85 | a | 통과 | 일치 | 0 |  |
| core/02-source.md | 110 | a | 통과 | 일치 | 0 | 보강: 길이 출력 |
| core/02-source.md | 151 | a | 통과 | 일치 | 0 | 보강(확인 출력) |
| core/03-state.md | 87 | a | 통과 | 일치 | 0 |  |
| core/03-state.md | 125 | a | 통과 | 일치 | 0 |  |
| core/03-state.md | 162 | a | 통과 | 일치 | 0 | 보강(확인 출력) |
| core/03-state.md | 216 | a | 통과 | 일치 | 0 |  |
| core/04-store.md | 60 | a | 통과 | 일치 | 0 | 보강(확인 출력) |
| core/04-store.md | 81 | a | 통과 | 일치 | 0 |  |
| core/04-store.md | 115 | a | 통과 | 일치 | 0 |  |
| core/04-store.md | 143 | a | 통과 | 일치 | 0 |  |
| core/05-observer-effect.md | 39 | a | 통과 | 일치 | 0 | 보강(확인 출력) |
| core/05-observer-effect.md | 116 | a | 통과 | 일치 | 0 |  |
| core/05-observer-effect.md | 237 | a | 통과 | 일치 | 0 | 보강(확인 출력) |
| core/06-slot.md | 82 | a | 통과 | 일치 | 0 | 보강(확인 출력) |
| core/06-slot.md | 110 | a | 통과 | 일치 | 0 | 보강(확인 출력) |
| core/06-slot.md | 171 | a | 통과 | 일치 | 0 | 보강(확인 출력) |
| core/06-slot.md | 219 | a | 통과 | 일치 | 0 | 보강(확인 출력) |
| core/06-slot.md | 262 | a | 통과 | 일치 | 0 | 보강(확인 출력) |
| core/06-slot.md | 413 | a | 통과 | 일치 | 0 | 보강: a 인스턴스 신원 비교(Roblox 백엔드는 물리 순서를 안 바꿈 — GetChildren 순서는 판정 안 함) |
| core/06-slot.md | 485 | a | 통과 | 일치 | 0 | 보강(확인 출력) |
| core/06-slot.md | 514 | c | 통과 | 일치 | 0 | 보강: host 마운트 + 숨김/복귀 확인(rows:Emit으로 재조정) |
| core/06-slot.md | 552 | c | 구문/미정의(조각) | 해당 없음 | 제외 | 조각(`ctx` 미정의 — updateFn 안 줄) · L413이 같은 모양을 덮음 |
| core/06-slot.md | 595 | a | 통과 | 일치 | 0 | 보강(확인 출력) |
| core/07-ref.md | 97 | a | 통과 | 일치 | 0 | 보강(확인 출력) |
| core/07-ref.md | 123 | a | 통과 | 일치 | 0 | 보강: Activated 발화 |
| core/07-ref.md | 154 | a | 통과 | 일치 | 0 | 보강(확인 출력) |
| core/07-ref.md | 252 | a | 통과 | 일치 | 0 |  |
| core/07-ref.md | 331 | d | 통과 | 일치 | 0 | task.spawn 셔임(코루틴) |
| core/07-ref.md | 366 | a | 통과 | 일치 | 0 | 보강: Activated 발화 |
| core/08-modifier.md | 56 | a | 통과 | 일치 | 0 | 보강(확인 출력) |
| core/08-modifier.md | 103 | d | 통과 | 일치 | 0 | 보강(확인 출력) |
| core/08-modifier.md | 153 | a | 통과 | 일치 | 0 | 보강(확인 출력) |
| core/08-modifier.md | 200 | d | 통과 | 일치 | 0 | 보강(확인 출력) |
| core/08-modifier.md | 231 | a | 통과 | 일치 | 0 | 보강(확인 출력) |
| core/08-modifier.md | 303 | a | 통과 | 일치 | 0 | 보강(확인 출력) |
| core/08-modifier.md | 335 | a | 통과 | 일치 | 0 | 보강(확인 출력) |
| core/08-modifier.md | 373 | a | 통과 | 일치 | 0 | 보강(확인 출력) |
| core/08-modifier.md | 418 | a | 통과 | 일치 | 0 |  |
| core/09-tag-attr.md | 88 | a | 통과 | 일치 | 0 | 보강(확인 출력) |
| core/09-tag-attr.md | 113 | c | 통과 | 일치 | 0 | 보강: isSelected 정의 |
| core/09-tag-attr.md | 154 | a | 통과 | 일치 | 0 |  |
| core/09-tag-attr.md | 176 | a | 통과 | 일치 | 0 |  |
| core/09-tag-attr.md | 213 | a | 통과 | 일치 | 0 | 보강(확인 출력) |
| core/09-tag-attr.md | 286 | a | 통과 | 일치 | 0 | 보강(확인 출력) |
| core/09-tag-attr.md | 312 | a | 통과 | 일치 | 0 |  |
| core/09-tag-attr.md | 350 | a | 통과 | 일치 | 0 | 보강(확인 출력) |
| core/09-tag-attr.md | 392 | d | 실패 | — (mock 한계: SetAttribute가 Color3 셔임(테이블) 거부) | 2 TypeError — 8.17(문서 caution에 이미) | 보강(확인 출력) |
| core/09-tag-attr.md | 428 | a | 통과 | 일치 | 0 | 보강(확인 출력) |
| core/09-tag-attr.md | 464 | a | 통과 | 일치 | 0 | 보강(확인 출력) |
| core/10-lifetime-sentinels.md | 39 | c | 통과 | 일치 | 0 | 보강: Card 호출 둘 |
| core/10-lifetime-sentinels.md | 124 | a | 통과 | 일치 | 0 | 보강(확인 출력) |
| extend/01-backend-provider-contract.md | 192 | a | 통과 | 일치 | 0 | 보강(확인 출력) |
| extend/02-dispatch-handler-contract.md | 353 | a | 통과 | 일치(등록·mount); 뒤 문장 '철거' 경로 → 발견 A2 | 0 | 보강: 핸들러를 실제로 태워 봄 |
| roblox/01-install.md | 95 | a | 통과 | 일치 | 0 | 보강(확인 출력) |
| roblox/01-install.md | 153 | a | 통과 | 일치 | 0 | 보강(확인 출력) |
| roblox/01-install.md | 161 | c | 구문/미정의(조각) | 해당 없음 | 제외 | 조각(함수 머리 한 줄 — 본문 없음, 구문 불완전) |
| roblox/02-d.md | 59 | d | 통과 | 일치 | 0 | 보강(확인 출력); script 셔임 |
| roblox/02-d.md | 130 | d | 통과 | 일치 | 0 |  |
| roblox/02-d.md | 261 | c | 통과 | 일치 | 0 | 보강: props 정의 |
| roblox/02-d.md | 287 | a | 통과 | 일치(런타임 무에러, 문서 주장은 타입 쪽) | 1 TypeError — 의도(문서가 '타입 에러'라 말함) — 12행 한 자리 | 둘째 줄은 문서가 '타입 에러'라 말함 |
| roblox/02-d.md | 310 | a | 통과 | 일치 | 0 |  |
| roblox/02-d.md | 339 | d | 통과 | 일치 | 0 | 보강(확인 출력) |
| roblox/03-d-modifier.md | 48 | a | 통과 | 일치 | 0 | 보강(확인 출력) |
| roblox/03-d-modifier.md | 130 | a | 통과 | 일치 | 0 | 보강(확인 출력) |
| roblox/03-d-modifier.md | 187 | d | 통과 | 일치 | 0 | 보강(확인 출력) |
| roblox/03-d-modifier.md | 222 | a | 통과 | 일치 | 0 | 보강(확인 출력) |
| roblox/03-d-modifier.md | 248 | a | 통과 | 일치 | 0 |  |
| roblox/03-d-modifier.md | 284 | a | 통과 | 일치 | 0 | 보강(확인 출력) |
| roblox/04-claim-mapper.md | 50 | d | 통과 | 일치 | 0 | 보강: foreign 템플릿 |
| roblox/04-claim-mapper.md | 81 | d | 통과 | 일치 | 0 | 보강: foreign 템플릿 |
| roblox/04-claim-mapper.md | 132 | d | 통과 | 일치 | 0 | 보강: foreign 템플릿 |
| roblox/04-claim-mapper.md | 168 | d | 통과 | 일치 | 0 | 보강: foreign 템플릿 |
| roblox/04-claim-mapper.md | 189 | c | 구문/미정의(조각) | 해당 없음 | 제외 | 조각(`{ … }` 자리표시 — 구문 아님) |
| roblox/04-claim-mapper.md | 202 | a | 통과 | 일치 | 0 | 보강(확인 출력) |
| roblox/04-claim-mapper.md | 221 | d | 통과 | 일치 | 0 | 보강: foreign 템플릿 |
| roblox/05-onchange.md | 56 | d | 통과 | 일치 | 0 | 보강(확인 출력); AbsoluteSize는 mock에서 엔진 쪽 대입으로 흉내 |
| roblox/05-onchange.md | 79 | a | 통과 | 일치 | 0 | 보강(확인 출력) |
| roblox/05-onchange.md | 95 | a | 통과 | 일치(런타임) | 1 TypeError — **새로움** → 발견 A1 | 보강(확인 출력) |
| roblox/05-onchange.md | 109 | a | 통과 | 일치 | 0 | 보강(확인 출력) |
| roblox/05-onchange.md | 146 | a | 통과 | 일치 | 0 | 보강: 엔진 쪽 대입으로 타이핑 흉내 |
| roblox/06-tween-animate.md | 61 | d | 통과 | 일치 | 0 | 보강(확인 출력) |
| roblox/06-tween-animate.md | 127 | a | 통과 | 일치 | 0 | 보강(확인 출력) |
| roblox/06-tween-animate.md | 182 | a | 통과 | 일치 | 0 | 보강(확인 출력) |
| roblox/06-tween-animate.md | 226 | a | 통과 | 일치 | 0 | 보강(확인 출력) |
| sugar/01-context.md | 66 | a | 통과 | 일치 | 0 | 보강(확인 출력) |
| sugar/01-context.md | 167 | d | 통과 | 일치 | 0 | 보강(확인 출력) |
| sugar/02-operator.md | 35 | a | 통과 | 일치 | 0 | 보강: 값 출력(주석의 15/105→18/108) |
| sugar/02-operator.md | 99 | a | 통과 | 일치 | 0 | 보강(확인 출력) |
| sugar/02-operator.md | 114 | a | 통과 | 일치 | 0 | 보강(확인 출력) |
| sugar/02-operator.md | 160 | a | 통과 | 일치 | 0 | 보강(확인 출력) |
| sugar/02-operator.md | 177 | a | 통과 | 일치 | 0 | 보강(확인 출력) |
| sugar/02-operator.md | 222 | a | 통과 | 일치 | 0 | 보강(확인 출력) |
| sugar/02-operator.md | 251 | a | 통과 | 일치 | 0 | 보강(확인 출력) |
| sugar/02-operator.md | 270 | a | 통과 | 일치 | 0 | 보강(확인 출력) |
| sugar/03-debounce-throttle.md | 190 | d | 통과 | 일치 | 0 | d: 가상 시계 H.runTask(0.31) 삽입 + Flush 앞 Set("abc") 보강(보류분 있는 Flush 확인) |
| sugar/03-debounce-throttle.md | 214 | a | 통과 | 일치 | 0 | 보강(확인 출력) |
| sugar/04-lifecycle-hooks.md | 98 | c | 통과 | 일치 | 0 | 보강: 호출·Destroy |
| sugar/05-fallback-traceback.md | 79 | d | 통과 | 일치 | 0 | 보강(확인 출력); warn 셔임 |
| sugar/06-blocker.md | 47 | a | 통과 | 일치 | 0 | 보강: 관측자 둘로 통지 수 확인 |
| sugar/06-blocker.md | 111 | a | 통과 | 일치 | 0 |  |
| sugar/06-blocker.md | 150 | a | 통과 | 일치 | 0 | 보강(확인 출력) |
| sugar/06-blocker.md | 166 | c | 통과 | 일치 | 0 | 보강: state·blocker 정의 |
| sugar/06-blocker.md | 176 | c | 통과 | 일치 | 0 | 보강: hp·blocker 정의 |

프롤로그(P)·시그니처/타입(b) 블록(실행·strict 안 함 — b는 E33 범위):

| 파일 | P 줄 | b 줄 |
|---|---|---|
| core/01-quad-module.md | 13 | 25, 48, 80, 121, 163, 175, 196, 222, 251 |
| core/02-source.md | 11 | 24, 64, 97, 122 |
| core/03-state.md | 11 | 18, 40, 59, 108, 140, 176, 191 |
| core/04-store.md | 11 | 22, 93, 129 |
| core/05-observer-effect.md | 16 | 69, 192 |
| core/06-slot.md | 16 | 25, 57, 98, 124, 142, 182, 192, 202, 232, 244, 272, 284, 296, 308, 320, 334, 450, 501, 542, 562 |
| core/07-ref.md | 16 | 24, 76, 111, 142, 172, 186, 198, 212, 224, 262, 284, 296, 308, 350 |
| core/08-modifier.md | 18 | 27, 66, 120, 177, 213, 243, 257, 283, 312, 349, 389 |
| core/09-tag-attr.md | 20 | 33, 62, 103, 124, 136, 165, 187, 201, 225, 255, 302, 323, 338, 362, 402, 442, 454 |
| core/10-lifetime-sentinels.md | 13 | 23, 52, 67, 86, 98, 139, 150, 160, 178, 188, 198 |
| core/11-predicates.md | 11 | — |
| extend/01-backend-provider-contract.md | 182 | — |
| extend/02-dispatch-handler-contract.md | 13 | 25, 51, 80, 102, 120, 132, 146, 179, 191, 236, 256, 272, 282, 301, 311, 323, 339 |
| roblox/01-install.md | 20 | 34, 88, 125 |
| roblox/02-d.md | 22 | 38, 186, 333 |
| roblox/03-d-modifier.md | 22 | 35, 85, 114, 176, 240 |
| roblox/04-claim-mapper.md | 20 | 35, 147, 212 |
| roblox/05-onchange.md | 19 | 32, 136 |
| roblox/06-tween-animate.md | 20 | 35, 118, 142, 156 |
| sugar/01-context.md | 13 | 25, 43, 83, 116, 134, 146 |
| sugar/02-operator.md | 13 | 47, 93, 108, 124, 134, 144, 154, 169, 186, 196, 206, 216, 231, 241, 260 |
| sugar/03-debounce-throttle.md | 21 | 54, 72, 139, 170 |
| sugar/04-lifecycle-hooks.md | 13 | 48, 66, 84 |
| sugar/05-fallback-traceback.md | 13 | 48, 67 |
| sugar/06-blocker.md | 13 | 24, 128 |
