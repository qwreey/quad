# Q154 — 변이 테스트가 찾은 스펙 공백 메우기 (2026-10-12)

원장 round14 `Q154`(사용자 승인 2026-10-12 — "진행하면 될 것 같음")의 실행 기록이다. 2026-09-27 자율 구간의 변이 테스트
(round13 E69·E73 — `round13-e69-mutation/`·`round13-e73-mutation-2/`)가 남긴 공백 48과 그 초안(E76 —
`round13-drafts-2026-09-27/spec-drafts/`), 그리고 round14 탐사 E(`round14-explore-2026-10-04/E-mutation.md`)가
더한 일곱을 **지금 HEAD의 계약 기준으로 다시 걸러** 스펙 절로 옮겼다. 동작 코드(`src`)·`mock.luau`·문서는 한 줄도
바꾸지 않았다 — 바뀐 것은 스펙 열두 파일(절 스물하나 추가, 기존 절 무변경)과 이 폴더뿐이다. 작업자는 opus 서브에이전트
하나(하위 에이전트 없음), 기준 커밋은 `e19f8066`(작업 도중 올라온 커밋들은 `src`·`test`를 건드리지 않았다).

## 결과

원 목록은 55개(E69 27 + E73 21 + round14 탐사 E 7)다.

- **새 절로 잡은 것 37** — HEAD에서 살아남던 변이를 새 절이 죽인다(절마다 따로 떼어 돌려 확인 — 아래 "검증").
- **HEAD에서 이미 잡히던 것 6** — 초안 뒤에 들어온 스펙 절과 코드 변경(Q185 절, Q170으로 하나가 된 소유 검사 등)으로 그사이 잡히게 됐다. 그중 우선순위 1번인 기준 오프셋
  둘(`BK16`·`SE01`)은 다른 계약을 보던 절이 우연히 잡고 있던 것이라 직접 단언하는 절을 따로 넣었다.
- **대상 없음 4** — 변이할 코드가 사라졌다(`Quad0201`·`Quad0031` 퇴역, `H-240` 검사 철거).
- **게이트가 잡음 1** — 생성 파일의 한 줄이라 스펙이 아니라 `scripts/test.sh`의 생성물 대조 게이트가 잡는다.
- **계약 아님 4** — 차이가 정의되지 않은 입력에서만, 또는 사용자 코드가 던진 **뒤**의 상태에서만 난다. 절을 쓰지 않았다.
- **계약 여부 불명 3** — 아래 "계약 여부 불명" 절. 절을 쓰지 않았다.
- 동등 변이로 새로 분류한 것은 원 목록에 없다(이 작업이 더한 짝 변이 하나만 동등 — 표 둘째).
- 예산으로 남긴 것 없음.

이 작업에서 찾은 코드 결함은 없다 — 새 절 스물하나 가운데 HEAD의 동작이 계약과 어긋난 곳은 없었다(쓰는 동안 고친 것은 전부 절 쪽: 기대 id를
잘못 적은 것 하나와 타입 주석). 문서 쪽 어긋남 하나는 "문서 메모"에 적었다.

## 표 — 원 목록 55

"HEAD" 열은 절을 넣기 **전** 스펙 전체(smoke 3·spec 59 — 62파일)에서의 결과, "최종" 열은 절을 넣은 뒤 스펙 전체에서의 결과와 그 변이를
잡은 파일이다(셋까지). 변이 자리는 옛 줄 번호가 전부 옮겨져 내용으로 다시 찾았다.

| 변이 | 출처 | 변이 내용 | HEAD | 분류 | 스펙 절 | 계약 근거 | 최종 |
|---|---|---|---|---|---|---|---|
| `BK16` | E69 | `quad-base/src/Bookkeeping.luau` — `ensureBase`의 Slot 기준값 `ownerKey.Offset:Get()`을 0으로 | 죽음 | HEAD에서 이미 잡힘 + 직접 절 | spec.slot “a Slot nested under a non-zero base” | core/06 `slot.Offset`(마운트 대상 안의 절대 위치) · extend/02 `getOffsetAt`(Slot이 owner면 그 Slot의 `.Offset`이 출발점) · extend/01 §2(offset은 0-based 절대값) | 죽음 — spec.slot |
| `SE01` | E69 | `quad-base/src/Slot/Tree.luau` — 기준 Observer(`makeBaseObserver`)의 캐시 되돌림 줄 삭제 | 죽음 | HEAD에서 이미 잡힘 + 직접 절 | spec.slot “a Slot nested under a non-zero base” | 위와 같음(“형제가 앞에서 길이를 바꾸면 이 값이 따라 움직입니다”) | 죽음 — spec.slot |
| `SW04` | E69 | `quad-base/src/Slot/Raw.luau` — `vacate`의 역맵 삭제 줄 제거 | 죽음 | HEAD에서 이미 잡힘 | (기존) spec.slot round14 Q185 (d) 절 (2) | core/06 `slot:IndexOf` “없으면 nil” | 죽음 — spec.slot |
| `SW07` | E69 | `quad-base/src/Slot/Raw.luau` — `rawReplace`의 옛 원소 역맵 삭제 줄 제거 | 생존 | 새 절 | spec.slot “IndexOf answers nil for an element that was swapped out” | core/06 `slot:IndexOf` “없으면 nil”(같은 절의 `WhenIdle` 예제가 이 nil에 기댄다) | 죽음 — spec.slot |
| `SW14` | E69 | `quad-base/src/Slot/Raw.luau` — `releaseElement`의 보관분 갈래에서 소유 판정 반전 | 생존 | 새 절 | spec.slot “a q.Detach-held element …” (1) | core/06 `:List` 반환 표(`nil` — 소유 Slot이면 파괴) · `q.Detach`(보관 중인 원소는 Slot이 소유) | 죽음 — spec.slot |
| `SL04` | E69 | `quad-base/src/Slot/List.luau` — `:List` 중복 키 게이트 삭제 | 생존 | 새 절 | spec.slot “:List — duplicate key is Quad0145 …” | core/06 `:List` 사이클 순서 (1)·`Quad0145` · errors/03 Quad0145 | 죽음 — spec.slot |
| `SL06` | E69 | `quad-base/src/Slot/List.luau` — `userdata[key] = ud` 삭제(항목 패스) | 생존 | 새 절 | spec.slot “:List — … UserData round-trips per key” | core/06 `ctx.UserData` 행 · “두 번째 반환값은 이 키의 다음 `ctx.UserData`” | 죽음 — spec.slot |
| `SL10` | E69 | `quad-base/src/Slot/List.luau` — `:List`의 `ownsGate` 반전 | 생존 | 새 절 | spec.slot “:List — … one cycle publishes Length once” | core/06 `:List` “한 사이클은 하나의 배치로 묶여 재계산이 한 번만” | 죽음 — spec.slot |
| `BK10` | E69 | `quad-base/src/Bookkeeping.luau` — `gatedRecompute`의 배치 Blocker 게이트 삭제 | 생존 | 새 절 | spec.slot “:List — … one cycle publishes Length once” | 위와 같음 | 죽음 — spec.slot |
| `SN01` | E69 | `quad-base/src/Slot/Owner.luau` — `claimOwner`의 이미 쥔 값 게이트 삭제 | 죽음 | HEAD에서 이미 잡힘 | (기존) spec.slot 18절·spec.handlers 12절 | errors/03 Quad0156·Quad0170·Quad0172 | 죽음 — spec.slot, spec.handlers |
| `SN03` | E69 | `quad-base/src/Slot/Owner.luau` — `releaseOwner`의 주인 불일치 게이트 삭제 | 생존 | 새 절 | spec.slot “Slot-layer error ids” (Quad0163) | extend/02 `q.Bookkeeping.releaseOwner` · errors/03 Quad0163 | 죽음 — spec.slot |
| `SI09` | E69 | `quad-base/src/Slot/init.luau` — `Splice` 범위 게이트를 한 칸 늦춤 | 생존 | 새 절 | spec.slot “Slot-layer error ids” (Quad0174) | errors/03 Quad0174(“클램프하지 않습니다”) | 죽음 — spec.slot |
| `EF17` | E69 | `quad-base/src/Effect.luau` — Effect 잎 핸들러의 `old ~= v` dedup을 항상 참으로 | 생존 | 새 절 | spec.effect 16 | `base/source-state-plan.md` “Observer/Effect Leaf dedup”(`H-266` load-bearing) · extend/02 retractor(같은 핸들러가 같은 자리를 계속 맡을 때) | 죽음 — spec.effect |
| `EF18` | E69 | `quad-base/src/Effect.luau` — Effect 잎 retractor의 `nextValue ~= v`를 항상 참으로 | 생존 | 새 절 | spec.effect 16 | 위와 같음 | 죽음 — spec.effect |
| `EF11` | E69 | `quad-base/src/Effect.luau` — `Effect:WeakSubscribe`의 `canBound` 게이트 삭제 | 생존 | 새 절 | spec.effect 17 | errors/04 Quad0089(“`:WeakSubscribe()`를 두 번 불러도 이 에러”)·Quad0230 | 죽음 — spec.effect |
| `OB06` | E69 | `quad-base/src/Observer.luau` — `Observer:Unsubscribe`의 약한 기록 지우기 줄 삭제 | 생존 | 새 절 | spec.tostring 5 | `base/architecture.md` `__tostring` 목록(Observer의 세 상태 subscribed / weak / unsubscribed) — 관측되는 차이는 `tostring`뿐이다(실행 자격은 `.Subscribed`가 정한다) | 죽음 — spec.tostring |
| `DI07` | E69 | `quad-base/src/Dispatch/init.luau` — `Dispatch.process`의 index 구멍 게이트를 한 칸 늦춤 | 생존 | 새 절 | spec.dispatch “round14 Q154 — Dispatch.process의 index …” | errors/02 Quad0075 · `base/dispatch-core-plan.md`(체인 list는 구멍 없는 시퀀스) | 죽음 — spec.dispatch |
| `DI10` | E69 | `quad-base/src/Dispatch/init.luau` — 같은 핸들러 재처리의 `slot.retractor = NOOP` 삭제 | 생존 | 계약 아님(던진 뒤 상태) | — | 차이는 `process`가 던진 **뒤** 옛 retractor가 한 번 더 불리는 것뿐 — extend/02 “한계와 주의”가 그 자리를 적지만 `architecture.md` “예외 안전성 계약”상 던진 뒤 서술은 관측 | 생존 |
| `TG08` | E69 | `quad-base/src/Tag.luau` — Tag 이름 리스트 깊이 한도 64 → 640 | — | 대상 없음 | — | `Quad0201` 퇴역(round14 Q176) — 깊이 가드가 코드에 없다 | —(대상 없음) |
| `DB01` | E69 | `quad-base/src/Debounce.luau` — `readTime`의 `v < 0` → `v < -1` | 생존 | 새 절 | spec.debounce “round14 Q154 — Time에 묶은 State …” | errors/01 Quad0039(읽는 시점 검사, 신호가 여는 창은 그 `:Set` 줄) | 죽음 — spec.debounce |
| `OP03` | E69 | `quad-base/src/Operator.luau` — `Clamp`의 `lo > hi` → `lo >= hi` | 생존 | 새 절 | spec.operator “round14 Q154 — 경계값 …” | sugar/02 `q.Operator.Clamp`(“`lo > hi`이면 … Quad0124”, 문구 `min must be <= max`) | 죽음 — spec.operator |
| `OP05` | E69 | `quad-base/src/Operator.luau` — `Shr`의 `bit32.rshift` → `bit32.arshift` | 생존 | 새 절 | spec.operator “round14 Q154 — 경계값 …” | sugar/02 연산자 표(`Shr` = `bit32.rshift`) | 죽음 — spec.operator |
| `PR10` | E69 | `quad-roblox/src/Handlers/Property.luau` — 스냅 조건의 `Reverses ~= true` 항 삭제 | 생존 | 새 절 | spec.tweenproperty “round14 Q154 — Info 없는 Time = 0 …” | roblox/06 옵션 절(“그 셋 중 하나라도 있으면 평소대로 엔진 트윈”, “또는 0·거짓”) | 죽음 — spec.tweenproperty |
| `BK02` | E69 | `quad-base/src/Bookkeeping.luau` — `getOffsetAt`의 Get 창 되감기 검사 ① | — | 대상 없음 | — | `H-240` (a) 검사 철거(round14 Q171 (a)) — 줄이 없다 | —(대상 없음) |
| `BK04` | E69 | `quad-base/src/Bookkeeping.luau` — `recompute`의 Get 창 되감기 검사 ② | — | 대상 없음 | — | 위와 같음 | —(대상 없음) |
| `ST04` | E69 | `quad-base/src/State.luau` — 재계산 전 `dep:_track` 삭제 | 생존 | 계약 아님(UB 입력 전용) | — | 차이를 내는 입력이 Compute fn 안의 자기 상류 `:Set`뿐 — core/03이 UB로 적고 round13 Q156 (b)가 spec으로 고정하지 않기로 닫음 | 생존 |
| `ST09` | E69 | `quad-base/src/State.luau` — Gate flush의 `_emitEpochMap:Sync(batch)` 삭제 | 생존 | 계약 아님(통지 횟수) | — | 차이는 게이트 위 게이트의 중복 통지 횟수·`emit()` 반환값 — core/03·sugar/06이 “횟수가 아니라 값에 기대세요”로 계약에서 뺌(Q156 (b); round14 탐사 E의 T12는 판별 입력을 못 찾아 추정 동등) | 생존 |
| `LR03` | E73 | `quad-roblox/src/LifetimeHandle.luau` — `isClaimed`의 nil 게이트 삭제 | 생존 | 새 절 | spec.robloxfactory 9 | core/10 `q.Backend.isClaimed`(“순수 술어 — 던지지 않고, 인스턴스가 아닌 값에도 거짓”) | 죽음 — spec.robloxfactory |
| `LR06` | E73 | `quad-roblox/src/LifetimeHandle.luau` — `isHeld`의 nil 게이트 삭제 | 생존 | 새 절 | spec.robloxfactory 9 | extend/01 §4 `isHeld`(“던지지 말고, `nil`에는 거짓”) | 죽음 — spec.robloxfactory |
| `LR08` | E73 | `quad-roblox/src/LifetimeHandle.luau` — `isHeldBy`의 `held ~= nil and ` 삭제 | 생존 | 새 절 | spec.robloxfactory 9 | extend/01 §4 `isHeldBy`(“`value`를 쥔 것이 바로 이 `inst`인가 … 순수 술어”) | 죽음 — spec.robloxfactory |
| `LR10` | E73 | `quad-roblox/src/LifetimeHandle.luau` — `holdLifetime`의 `gchold[value] = true` 삭제 | 생존 | 새 절 | spec.robloxfactory 10 | extend/01 §4 `holdLifetime`(“`inst`가 사는 동안 `value`가 GC되지 않게”) | 죽음 — spec.robloxfactory |
| `LR12` | E73 | `quad-roblox/src/LifetimeHandle.luau` — `releaseLifetime`의 `gchold[value] = nil` 삭제 | 생존 | 새 절 | spec.robloxfactory 10 | extend/01 §4 `releaseLifetime`(“홀더에서 `value`를 빼고”) | 죽음 — spec.robloxfactory |
| `LR13` | E73 | `quad-roblox/src/LifetimeHandle.luau` — `releaseLifetime`의 근거(`gchold`) 지우기 삭제 | 생존 | 새 절 | spec.robloxfactory 10 | extend/01 §4 `releaseLifetime`(“남긴 근거를 지웁니다”) | 죽음 — spec.robloxfactory |
| `CL06` | E73 | `quad-base/src/Claim.luau` — Claim 매핑 패스의 `type(i) == "number" and ` 삭제 | 생존 | 계약 아님(던진 뒤 상태) | — | 지금은 변이든 HEAD든 문자 키의 디스크립터가 적용 단계의 `Quad0076`으로 끝난다(초안이 본 VM 에러는 `Quad0031` 철회와 함께 사라짐). 남은 차이는 그 throw **뒤** 자식이 claim돼 있느냐뿐 — roblox/04가 정의되지 않은 동작으로 적은 자리 | 생존 |
| `CL07` | E73 | `quad-base/src/Claim.luau` — 1패스의 소수 배열 키 검사 | — | 대상 없음 | — | `Quad0031` 퇴역(2026-10-01 철회) — 검사가 코드에 없다 | —(대상 없음) |
| `CL15` | E73 | `quad-base/src/Claim.luau` — `Claim` 둘째 인자의 디스크립터 게이트 삭제 | 생존 | 새 절 | spec.claim 18 | roblox/04 에러 표 Quad0034 · “위 표의 에러는 아무것도 claim하기 전에” | 죽음 — spec.claim |
| `CL16` | E73 | `quad-base/src/Claim.luau` — `newMapperClass`의 빈 문자열 검사 삭제 | 생존 | 새 절 | spec.claim 18 | errors/06 Quad0026 | 죽음 — spec.claim |
| `CL17` | E73 | `quad-base/src/Claim.luau` — Claim plan 삽입을 앞쪽으로(top-down drive) | 죽음 | HEAD에서 이미 잡힘 | (기존) spec.claim 13절 | roblox/04 동작 3(안쪽부터 바깥으로) | 죽음 — spec.claim |
| `SH05` | E73 | `quad-base/src/Slot/Handler.luau` — SlotHandler가 `claimOwnerAt` 결과를 무시 | 죽음 | HEAD에서 이미 잡힘 | (기존) spec.source 7절(이미 마운트된 Slot의 둘째 마운트) | extend/02 `claimOwnerAt` | 죽음 — spec.slot, spec.source |
| `SH06` | E73 | `quad-base/src/Slot/Handler.luau` — SlotHandler retractor의 `slotValue == nextValue` 조기 반환 삭제 | 생존 | 새 절 | spec.slot “the same Slot again at its own seat is a no-op” | extend/02 `claimOwnerAt`(정확히 같은 자리면 `false` … 물리 부착도 건너뜀) · retractor(`nextValue`는 자기 철거의 기준) | 죽음 — spec.slot |
| `SH03` | E73 | `quad-base/src/Slot/Handler.luau` — SlotHandler의 파괴된 Slot 사전검사 삭제 | 생존 | 새 절 | spec.slot “Slot-layer error ids” (Quad0140) | errors/03 Quad0140(“`claimOwnerAt`/`bindLifetime`이 커밋되기 전에”)·Quad0164(“공개 경로에서는 핸들러 사전검사 Quad0140이 먼저”) | 죽음 — spec.slot |
| `EL02` | E73 | `quad-base/src/Slot/Elements.luau` — 원소 게이트의 Modifier 판정 삭제 | 생존 | 새 절 | spec.slot “Slot-layer error ids” (Quad0238) | errors/03 Quad0238 | 죽음 — spec.slot |
| `EL04` | E73 | `quad-base/src/Slot/Elements.luau` — 원소 게이트의 `q.None` 판정 삭제 | 생존 | 새 절 | spec.slot “Slot-layer error ids” (Quad0239) | errors/03 Quad0239 | 죽음 — spec.slot |
| `SH01` | E73 | `quad-base/src/Slot/Handler.luau` — SlotHandler `isHandlable`의 `k >= 1 and ` 삭제 | 생존 | 계약 여부 불명 | — | 아래 “계약 여부 불명” 1 | 생존 |
| `SH02` | E73 | `quad-base/src/Slot/Handler.luau` — SlotHandler `isHandlable`의 `k % 1 == 0 and ` 삭제 | 생존 | 계약 여부 불명 | — | 아래 “계약 여부 불명” 1 | 생존 |
| `EO12` | E73 | `quad-roblox/src/EngineOps.luau` — roblox `setTimeout`의 NaN 항 삭제 | 생존 | 새 절 | spec.timers 4 | errors/07 Quad0216(“숫자가 아니거나, NaN이거나, 음수”) | 죽음 — spec.timers |
| `FB05` | E73 | `quad-base/src/Fallback.luau` — `Traceback`의 `debug.traceback(nil, 2)` → 레벨 1 | 생존 | 계약 여부 불명 | — | 아래 “계약 여부 불명” 2 | 생존 |
| `DC02` | E73 | 옛 `quad-roblox/src/Declaration/init.luau` — 생성 `DefineSubtype("GuiObject", "ScrollingFrame")` 줄 삭제 | 생존 | 게이트가 잡음 | — | 생성 파일의 한 줄이라 `scripts/test.sh`의 `gen-d.py check`(커밋된 Declaration == 새 emit)가 exit 1로 잡는다(사본에서 실측) — E73 드라이버가 spec만 돌려 생존으로 셌다 | 생존 (spec 기준; `scripts/gen-d.py` check는 exit 1) |
| `O03` | R14 | `quad-base/src/Observer.luau` — Observer `_receive`의 Q109 건너뜀에서 `from == self._state` 절 삭제 | 생존 | 새 절 | spec.observer 15 | core/03 `state:Gate`·sugar/06 Blocker(게이트는 유보분을 flush 때 하류로 넘긴다) · round13 Q109(건너뜀은 Source가 직접 보낸 통지에만) | 죽음 — spec.observer |
| `E05` | R14 | `quad-base/src/Effect.luau` — `RERUN_LIMIT` 카운터를 핸들에 누적 | 생존 | 새 절 | spec.effect 18 | core/05 `q.Effect`(“한 번의 반복 안에서 … 1만 번”) · errors/04 Quad0263 | 죽음 — spec.effect |
| `K10b` | R14 | `quad-base/src/Bookkeeping.luau` — 부기 되감기 카운터를 owner 부기에 누적 | 생존 | 새 절 | spec.lengthoffset “round14 Q154 — 되감기 한도는 자리 계산 한 번의 것” | core/06 `slot.Offset`(“한 번의 자리 계산이 1만 번 넘게”) · errors/02 Quad0267 | 죽음 — spec.lengthoffset |
| `R05` | R14 | `quad-base/src/Slot/Raw.luau` — `restoreChain`이 저장값 대신 false로 복원 | 생존 | 새 절 | spec.slot “Quad0167 on the remaining attach windows” (a) | core/06 `:List`(조상 Slot 전부가 막힌다) · round13 Q74 (a) | 죽음 — spec.slot |
| `R15` | R14 | `quad-base/src/Slot/Raw.luau` — `raiseChain`이 저장값으로 늘 false를 기록 | 생존 | 새 절 | spec.slot “Quad0167 on the remaining attach windows” (a) | 위와 같음 | 죽음 — spec.slot |
| `R09` | R14 | `quad-base/src/Slot/Raw.luau` — `rawReplace` 마운트된 갈래의 `raiseChain` 삭제 | 생존 | 새 절 | spec.slot “Quad0167 on the remaining attach windows” (b) | 위와 같음(“`Add`/`Splice`/`Replace`로 들어갈 때”) | 죽음 — spec.slot |
| `R08` | R14 | `quad-base/src/Slot/Raw.luau` — `rawReplace` 마운트 전 갈래의 `raiseChain` 삭제 | 생존 | 새 절 | spec.slot “Quad0167 on the remaining attach windows” (c) | 위와 같음 | 죽음 — spec.slot |

출처의 R14는 round14 탐사 E다. 계약 근거 열의 `core/…`·`extend/…`·`errors/…`·`sugar/…`·`roblox/…`는 전부 `docs/reference/` 아래 페이지이고
각 절의 머리 주석에 같은 근거와 변이 ID가 적혀 있다.

### 이 작업이 더한 짝 변이

원 목록의 변이 옆 줄(같은 경로의 다른 갈래, Observer 쪽 쌍둥이)이 같은 식으로 비어 있는지 보려고 열을 더 넣었다. E69가 "Detach 수명 경로
전체가 단언되지 않는다"고 적은 자리가 대부분이고, 다섯이 실제로 비어 있어 Detach 절이 같이 닫았다. Observer 쪽 쌍둥이 셋은 이미 잡히거나
동등이라 절을 넣지 않았다(써 봤던 두 절은 기존 절과 겹쳐 뺐다).

| 변이 | 출처 | 변이 내용 | HEAD | 분류 | 스펙 절 | 계약 근거 | 최종 |
|---|---|---|---|---|---|---|---|
| `DT2` | 추가 | `quad-base/src/Slot/Tree.luau` — `destroySlotTree` 보관분 루프의 파괴 줄 삭제 | 생존 | 새 절 | spec.slot “a q.Detach-held element …” (3) | core/06 `q.Detach`(Slot이 파괴될 때 같이 파괴) | 죽음 — spec.slot |
| `DT3` | 추가 | `quad-base/src/Slot/List.luau` — `settle`에서 보관분을 새 원소로 바꿀 때의 놓기 줄 삭제 | 생존 | 새 절 | spec.slot “a q.Detach-held element …” (2) | core/06 `:List` 반환 표(새 원소 — 소유 Slot이면 옛 원소 파괴) | 죽음 — spec.slot |
| `DT4` | 추가 | `quad-base/src/Slot/List.luau` — `_detachCleanup`을 호스트에 묶는 줄 삭제(첫 활성화) | 생존 | 새 절 | spec.slot “a q.Detach-held element …” (4) | core/06 “죽은 Slot과 마운트 규칙”(보관 중인 원소만은 호스트와 함께 파괴) · `base/slot-plan.md`(owner가 죽으면 `_detachCleanup`이 정리) | 죽음 — spec.slot |
| `DT4b` | 추가 | `quad-base/src/Slot/List.luau` — `_detachCleanup` 본문의 파괴 줄 삭제 | 생존 | 새 절 | spec.slot “a q.Detach-held element …” (4) | 위와 같음 | 죽음 — spec.slot |
| `DT5` | 추가 | `quad-base/src/Slot/Tree.luau` — `teardownTree`의 `_detachCleanup` 앵커 풀기 삭제 | 죽음 | HEAD에서 이미 잡힘 | (기존) spec.slot | `base/slot-plan.md`(언마운트는 앵커만 푼다) | 죽음 — spec.slot |
| `DT6` | 추가 | `quad-base/src/Slot/List.luau` — 재마운트 때 `_detachCleanup` 앵커 옮기기 삭제 | 생존 | 새 절 | spec.slot “a q.Detach-held element …” (5) | `base/slot-plan.md` `activateList`(재마운트 — GC 앵커만 새 target으로) — 아래 “근거가 얇은 곳” 참고 | 죽음 — spec.slot |
| `DT7` | 추가 | `quad-base/src/Slot/List.luau` — 보관분 되붙이기의 `fromDetached` 인자 삭제 | 죽음 | HEAD에서 이미 잡힘 | (기존) spec.slot 12절 | core/06 `q.Detach`(`ctx.Prev`를 반환하면 그대로 다시 붙는다) | 죽음 — spec.slot |
| `OBL1` | 추가 | `quad-base/src/Observer.luau` — Observer 잎 핸들러의 `old ~= v` dedup을 항상 참으로(EF17의 짝) | 죽음 | HEAD에서 이미 잡힘 | (기존) spec.leaf 3절 | `base/source-state-plan.md` “Observer/Effect Leaf dedup” — Observer 쪽은 이미 단언돼 있었고 Effect 쪽(EF17·EF18)만 비어 있었다 | 죽음 — spec.leaf |
| `OBL2` | 추가 | `quad-base/src/Observer.luau` — Observer 잎 retractor의 `nextValue ~= v`를 항상 참으로(EF18의 짝) | 생존 | 동등(관측 차이 없음) | — | Observer는 풀었다 다시 묶어도 보이는 것이 없다(cleanup이 없고 따라잡을 변경도 없음) — Effect 쪽(EF18)만 cleanup·재실행으로 드러난다 | 생존 |
| `OBW` | 추가 | `quad-base/src/Observer.luau` — `Observer:WeakSubscribe`의 `canBound` 게이트 삭제(EF11의 짝) | 죽음 | HEAD에서 이미 잡힘 | (기존) spec.observer 4절 | errors/04 Quad0111 — 기존 절은 문구(already subscribed)로 단언한다 | 죽음 — spec.observer |

## 새 절 — 파일별

`quad-base/test/spec.slot.luau`(일곱, 파일 끝 — 머리 주석 "round14 Q154 … spec-gap fill"부터):

1. "a Slot nested under a non-zero base" — 앞에 형제가 있는 Slot 안의 Slot: `Offset`이 부모의 기준을 싣고, 앞 형제가 자라거나 줄면 따라가고,
   `getOffsetAt`이 Slot 자신의 `Offset`에서 출발하며, 백엔드 `nativeInsert`가 절대 오프셋을 받는다(3단 중첩 포함).
2. "IndexOf answers nil for an element that was swapped out" — `Extract(i, new)`·`Replace`로 밀려난 원소(마운트 전·후 둘 다).
3. "a q.Detach-held element is destroyed with its key, its Slot or its host" — 보관분의 수명 다섯 장면(nil로 버림 / 새 원소로 바꿈 /
   Slot 파괴 / 호스트 사망 / 언마운트 뒤 옛 호스트 사망은 닿지 않고 새 호스트 사망은 닿음).
4. ":List — duplicate key is Quad0145 before any updateFn, UserData round-trips per key, one cycle publishes Length once".
5. "Slot-layer error ids" — `Quad0163`·`Quad0174`·`Quad0140`·`Quad0238`/`0239`/`0240`/`0242`(원소 게이트는 공개 진입 넷으로).
6. "the same Slot again at its own seat is a no-op" — `State<Slot>` 자리가 같은 Slot을 다시 발행할 때와 같은 props를 다시 `drive`할 때
   백엔드 호출이 0번이고 이후 CRUD가 그대로 선다.
7. "Quad0167 on the remaining attach windows" — 중첩된 창이 닫혀도 바깥 창이 남는가(조상 마운트 도중 형제에 Slot을 넣은 뒤 조상 CRUD),
   마운트된 Slot의 `Replace(i, 새 Slot)`과 State 원소가 Slot으로 바뀔 때, 아직 마운트 전인 Slot의 `Replace`. 거부되는 CRUD는 콜백 안에서
   받아 바깥 연산을 끝까지 마치게 했다 — 단언하는 것은 거부 자체와 "조상은 그대로"뿐이다.

`quad-base/test/spec.effect.luau`(16·17·18): 같은 Effect가 자기 자리에 다시 올 때의 중복 제거(같은 값 재발행·재`drive`, 다른 Effect면 교체) /
`:WeakSubscribe` 두 번의 `Quad0089`·자리에 묶인 핸들의 `Quad0230` / 재실행 한도가 반복 하나의 것(바깥 `Set` 1만 5회, 9천 회짜리 반복 둘).

`quad-base/test/spec.observer.luau`(15): 게이트(Gate 바로 아래·그 아래 Compute·Blocker) 아래 Observer가 flush 통지를 받는다.

`quad-base/test/spec.tostring.luau`(5), `quad-base/test/spec.dispatch.luau`(끝 — `Quad0075`), `quad-base/test/spec.debounce.luau`(끝 — `Quad0039`),
`quad-base/test/spec.operator.luau`(끝 — `Clamp(lo, lo)`·`Shr`), `quad-base/test/spec.lengthoffset.luau`(끝 — 되감기 한도는 계산 한 번의 것).

`quad-roblox/test/spec.robloxfactory.luau`(9·10): hold op 술어 셋의 nil·"아무도 안 쥔 값" 답 / `bindLifetime`이 값을 살리고(GC 뒤 발화)
`unbindLifetime`이 그 자리에서 놓는다(수거 가능·`isHeldBy` 거짓). `quad-roblox/test/spec.tweenproperty.luau`(끝 — `Time = 0`에
`Reverses`·`RepeatCount`·`DelayTime`), `quad-roblox/test/spec.claim.luau`(18 — `Quad0034`·`Quad0026`), `quad-roblox/test/spec.timers.luau`(4 — `Quad0216`).

## 검증

- **변이는 레포 밖 사본에서 넣었다.** 지시는 "소스에 넣고 `cp`로 복구"였는데, 같은 트리에서 메인 세션이 게이트를 돌릴 수 있어(변이가 들어간
  몇 초 사이에 `test.sh`가 돌면 거짓 실패) 다섯 패키지와 `scripts/`를 스크래치로 `cp -rL`한 사본에서 했다 — 사본의 `src`는 본 트리와
  `diff -r`로 같음을 확인했고, 스펙은 매번 본 트리 것을 덮어 가져갔으며, 변이는 사본 안에서 백업 `cp`로 되돌렸다. 본 트리의 `src`는 처음부터
  끝까지 그대로다(`git diff --stat -- quad-base/src quad-roblox/src quad-types/src` 빈 출력).
- 절을 넣기 전: 55 중 대상이 남은 51과 짝 변이를 HEAD 스펙 전체에 돌려 어느 것이 아직 사는지 다시 쟀다(표의 "HEAD" 열).
- 절을 넣을 때: 새 절**만** 담은 파일(그 스펙의 머리 + 추가분)을 따로 만들어 해당 변이를 돌렸다 — 다른 절이 먼저 실패해 가려지는 일 없이
  새 절이 그 변이를 잡는 것을 봤다(`BK16`·`SE01`처럼 기존 절이 먼저 잡던 것도 새 절 단독으로 잡는다).
- 끝: 전 변이를 절을 넣은 스펙 전체에 다시 돌렸다(표의 "최종" 열 — 생성 스크립트가 "새 절·이미 잡힘은 전부 죽음, 계약 아님·불명·동등은
  전부 생존"을 assert한다).
- 흔들림: 손댄 스펙 열둘을 여덟 번씩 반복해 실패 0(GC를 쓰는 `spec.robloxfactory` 10 포함).
- 게이트: `./scripts/test.sh` exit 0(smoke 3 + 스펙 59), 타입 검사 세 패스 진단 0(기존 `SameLineStatement` 린트 셋은 그대로).

## 계약 여부 불명 — 절을 쓰지 않은 셋

**1. `SH01`·`SH02` — `q.Dispatch.process`를 직접 불러 Slot을 배열 자리가 아닌 숫자 키(0·음수·소수)에 놓기.** 지금 동작: 내장 Slot 핸들러가
양의 정수 키만 받으므로 그런 키의 Slot은 매치 실패 `Quad0076`으로 거부되고, 그 Slot은 임자 없이 남아 다른 호스트에 그대로 마운트된다(사본
실측 — 키 0·1.5·−1). `k >= 1` 조건을 뺀 변이에서는 키 0·−1이 핸들러에 매치돼 자리를 잡은 **뒤**(소유 등록·수명 묶기 커밋) 부기의 `Quad0019`로
죽고, 그 Slot은 그 인스턴스 것으로 남아 다시 쓸 수 없다(다른 호스트에 놓으면 `Quad0160`); `k % 1 == 0`을 뺀 변이는 키 1.5에서 똑같다(둘 다
사본 실측). 근거 후보는 셋이다 — 초안이 기댄 errors/03 `Quad0141`의 "`process`를 직접 불러 배열 리터럴이 아닌 자리에 놓으면" 문장, extend/02 `claimOwnerAt`의 "거부가 나면 아무것도 남지
않아야 하므로"(핸들러 작성자용 일반 원칙), 그리고 `Slot/Handler.luau`의 주석(2026-09-17 체크포인트 리뷰가 넣은 조건). 애매한 이유: 첫째
근거는 `Quad0141`이 round14에서 퇴역하며 문장째 사라졌고, 지금 공개 문서에는 내장 Slot 핸들러가 어떤 키를 받는지가 어디에도 없다. `drive`는
그런 키를 `Quad0085`로 먼저 막으니 사용자 경로가 아니라 확장 작성자의 오용 경로이고, 어느 id가 나는지는 "매치되는 핸들러가 없으면"의 귀결일
뿐이다. 계약으로 삼는다면 절은 짧다 — 키 셋에 대해 `Quad0076`, 그리고 그 Slot을 다른 호스트에 `drive`하면 성공(위 실측대로면 두 변이를
다 잡는다).

**2. `FB05` — `q.Traceback`이 넘기는 trace의 첫 프레임.** 지금 동작: trace가 던진 줄에서 시작하고 그다음 줄이 `Fallback.luau`의 `xpcall` 줄이다.
레벨을 1로 바꾼 변이에서는 맨 앞에 에러 핸들러 자신의 프레임 한 줄이 더 붙는다 — 던진 줄은 여전히 들어 있어 기존 3절("trace는 던진 지점을
담는다")은 통과한다. 근거 후보: sugar/05의 "`xpcall` 핸들러 안에서, 즉 **던진 자리에서** 트레이스백을 뜹니다", `base/fallback-plan.md` 메커니즘
스케치의 `debug.traceback(nil, 2)`. 애매한 이유: 공개 문장은 **언제** 뜨는가(스택이 풀리기 전)를 말하지 trace 문자열이 어느 프레임으로 시작하는지를
약속하지 않고, 진단 문자열의 모양은 에러 문구와 같은 부류(API 아님)로 읽힌다. 초안은 "첫 줄에 `Fallback`이 없다"를 단언했는데, 그것은 문자열
모양을 고정한다.

## 계약 아님으로 분류한 넷

- **`DI10`** — 같은 핸들러 재처리에서 `process`가 던진 뒤, 그 자리를 철거할 때 옛 retractor가 한 번 더 불리는가. extend/02 "한계와 주의"가
  "no-op 표식을 단 채 남고"라고 적지만 같은 문단이 바로 앞에서 "quad는 예외 이후의 부기 정합성을 보장하지 않습니다"라고 적고, `base/architecture.md`의
  "예외 안전성 계약" 절이 던진 뒤 서술을 전부 관측으로 둔다. 초안의 23절은 넣지 않았다.
- **`ST04`·`ST09`** — round13 `Q156` (b) 닫힘 그대로(Compute 안의 `:Set`은 UB, 게이트 겹침의 통지 횟수는 계약 밖).
- **`CL06`** — 초안이 본 차이(VM 비교 에러 대 `Quad0076`)는 `Quad0031` 검사 철회와 함께 사라졌다. 지금은 HEAD도 변이도 문자 키의 디스크립터를
  적용 단계의 `Quad0076`으로 끝내고, 다른 점은 그 throw 뒤 자식 인스턴스가 claim돼 있느냐뿐이다 — roblox/04가 "`D.New`가 중간에 던질 때와 같은
  정의되지 않은 동작"으로 적은 자리.

## 근거가 얇은 곳 — 절은 썼지만 메인이 한 번 볼 것

- **Detach 절의 (5)(언마운트 뒤에는 옛 호스트의 죽음이 보관분에 닿지 않고 새 호스트의 죽음이 닿는다).** 근거는 `base/slot-plan.md`의
  `activateList`·`teardownTree` 의사코드 주석(재마운트는 앵커만 새 target으로, 언마운트는 앵커만 푼다 — "포탈 경로에서 실제로 터진다")이다.
  공개 문서 core/06 `q.Detach`도 같은 내용을 적지만 그 괄호 끝에 "[2026-09-27 mock 관측]" 태그가 붙어 있다. round14 `Q177`이 "날짜 태그는
  관측 표시가 아니다"로 정리했고 본문에 "관측 — 계약 아님" 표시는 없어 계약으로 읽었다. 관측으로 읽는다면 (5)만 걷으면 된다((1)~(4)는
  core/06의 표시 없는 문장들이 근거).
- **`:List` 절의 "한 사이클에 `Length` 발행 한 번".** 근거 문장은 "한 사이클은 하나의 배치로 묶여 재계산이 한 번만"이고, 단언은 Length Observer의
  실행 횟수다. 같은 꼴의 단언이 기존 26절(`ExtractAll` — "exactly one Length emit")에 있어 따랐다. 게이트가 여럿인 그래프의 통지 횟수(계약 밖)와는
  다른 자리다 — Slot 하나의 `Length` 하나.
- **`Quad0140`.** errors/03은 "공개 경로에서는 핸들러 사전검사 `Quad0140`이 먼저"라고 적는데 core/06 "죽은 Slot과 마운트 규칙"의 셋째 항목은
  마운트하려 할 때의 id를 `Quad0164`로 적는다(문구는 둘이 같다). 레지스트리 쪽(errors/03)을 따랐다 — 아래 "문서 메모".
- **`isHeldBy`의 nil.** extend/01은 `isHeld`에만 "nil에는 거짓"을 글자로 적고 `isHeldBy`에는 "순수 술어"라고만 적는다. 같은 문서가 "순수 술어"를
  "던지지 않고 nil에도 거짓"으로 쓰고 있어(`isHeld`, `Brand:Is`) 그렇게 읽었다.
- **`OB06`.** `Observer:Unsubscribe`가 약한 기록을 안 지워도 실행 자격은 `.Subscribed`가 정하므로 관측되는 차이는 `tostring`뿐이었다
  (`Observer(weak)`). 그래서 절은 `spec.tostring`에 있다 — "`:Unsubscribe` 뒤에는 fn이 돌지 않는다"를 단언해도 이 변이는 살아남는다(써 보고 확인).

**메인 대조(2026-10-12 저녁) — 다섯 다 그대로 둔다.** Detach (5): core/06 `q.Detach`의 "동작" 문단이 "보관분의 수명이 호스트에 묶이고, 언마운트 때
풀려 다시 마운트되면 새 호스트에 묶입니다"를 표시 없이 적는다 — 괄호 끝의 날짜 태그는 출처 표시이고 "관측(계약 아님)" 표시가 아니며, `slot-plan.md`의
의사코드도 같은 설계를 적는다. 계약. `Length` 한 번: core/06 `:List` "한 사이클은 하나의 배치로 묶여 재계산이 한 번만 일어납니다"가 근거 — Slot 하나의
`Length` Observer가 한 번 도는 것은 그 문장의 직접 귀결이다. `Quad0140`: core/06을 `Quad0140`으로 고쳤다(`6eca164d`). `isHeldBy`: 절이 단언하는 것은
"아무도 쥐지 않은 값은 이 인스턴스가 쥔 것이 아니다"이고 이는 extend/01의 정의("`value`를 쥔 것이 바로 이 `inst`인가") 그대로다. `OB06`: `tostring` 목록은
`architecture.md`가 고정한 표면이라 거기서 단언하는 것이 맞다.

## 문서 메모 (이 작업은 문서를 고치지 않았다)

- core/06 "죽은 Slot과 마운트 규칙"의 "마운트하려 하면 `Quad0164 Slot: destroyed Slot cannot be mounted`"는 errors/03의 `Quad0164` 절("공개
  경로에서는 … `Quad0140`이 먼저 걸리고 … 이 ID를 직접 볼 일은 드뭅니다")과 어긋난다 — 실측으로는 `drive`와 `State<Slot>` 자리 둘 다 `Quad0140`이다.
- `.claude/audit/README.md`에 이 폴더의 색인 줄이 아직 없다(이 작업의 허용 범위 밖이라 넣지 않았다).

## 미완

- E73이 "미지"로 남긴 `LR02`(roblox `gchold[1] = gcconn` — mock 신호가 연결을 강하게 잡아 CLI로는 못 가름)는 그대로 실기기 몫이다.
- 변이 자리는 원 목록과 그 옆 줄뿐이다 — 초안 뒤에 바뀐 코드 전체를 새로 변이하지는 않았다(round14 탐사 E가 그 주의 변경분을 봤고,
  2026-10-12의 세 커밋은 각자의 스펙 절과 함께 들어갔다).

## 재현

스크래치에 패키지 다섯(`quad-base`·`quad-roblox`·`quad-types`·`quad-error`·`type-version-check`)과 `scripts/`·`pesde.toml`·`pesde.lock`·`mise.toml`을
`cp -rL`로 복사하고 `./scripts/relink.sh`를 돌린 뒤, 변이 하나를 넣고(`mise exec -- luau-compile --null`로 구문 확인) `./scripts/relink.sh` →
`mise exec -- luau <스펙>` → 백업 `cp`로 복구 → `./scripts/relink.sh`. quad-base의 변이를 quad-roblox 스펙으로 볼 때 relink를 빼면 스펙이
옛 사본을 돈다. 변이 정의(파일·찾을 문자열·바꿀 문자열)는 표의 "변이 내용" 열과 원 목록의 mutants 파일(round13 두 폴더)·탐사 E 본문이 소스다.
