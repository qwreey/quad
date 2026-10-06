# 걷어낸 UB 가드의 debug 가시성 조사 (2026-10-06, opus 읽기 전용 + mock 프로브)

**요약.** round13·round14에서 걷어냈거나 debug 층으로 내렸거나 걷기로 결정만 난 가드 열일곱 개를 모아, 그 가드가 막던 실수를 사용자가 밟았을 때 `q.debug = true`에서 알아챌 수 있는지 mock 프로브로 쟀다. 열일곱 중 열 개는 이미 반영됐고 일곱 개는 결정만 났다(코드는 HEAD `261e69ac` 그대로라, 반영 뒤 모습은 스크래치 사본에서 가드를 직접 지워 쟀다). **아홉 개는 지금 있는 debug 장치가 이미 덮는다** — 그중 다섯은 debug 층으로 옮겨진 검사 자체이고(`Quad0083`·`Quad0143`·`Quad0173`·`Quad0220`·`Quad0070`), 넷은 일반형 감지기가 잡는다(Compute 안 Set 감지가 `H-198`과 `H-240`을, 겹친 실행 감지가 yield 가드 둘을, 문자 키 경고가 퇴역한 `Quad0141` 자리를). **하나는 반만 덮인다** — Observer 설치 재실행 루프가 막던 "설치 fn이 자기 대상을 한 번 되쓰고 멈추는" 모양은 debug에서도 0줄이다. **둘은 debug가 전혀 못 본다** — flush 도중 `handle:Cancel()`(`H-570`을 걷은 뒤)과 파괴된 인스턴스 위의 `process`/`drive`(`H-877`을 걷은 뒤). **다섯은 debug 감지기가 필요 없다** — 꺼 두어도 에러로 시끄럽게 드러나거나, UB가 아니라 정의된 동작으로 바꾼 것이다. debug를 끈 채 **에러 없이 결과가 틀리는 것은 다섯 개**(`H-198` 첫 `Get`의 낡은 값, `Quad0143` 덧붙은 키 무시, `H-240` 한 파동 낡은 오프셋, `H-570` 한 `Time` 늦은 신호, `H-877` 시체 위 콜백)이고, 그중 셋은 debug가 이미 잡고 둘(`H-570`·`H-877`)은 못 잡는다. 이 둘과 설치 창 되먹임까지 세 자리에 debug 감지기를 붙이는 안을 스크래치 사본에서 시험했다. quad-base·quad-roblox spec 전체를 돌렸을 때 세 감지기가 걸린 자리는 spec이 일부러 만든 UB 장면뿐이었다. 단 설치 창 감지기는 내부 Observer 둘이 `_internal` 표시를 설치가 끝난 **뒤에** 받아서, 그 둘에서 표시 순서 때문에 생긴 경고가 났다. **새 감지기는 새 메커니즘이므로 셋 다 사용자 결정 거리다**(`H-877` 쪽은 Q166 회신에서 사용자가 방향을 이미 냈다).

## 표

"꺼졌을 때"는 `q.debug = false`(기본값)로 그 실수를 밟았을 때 무엇이 일어나는가이다. "조용히 틀림"은 에러 없이 결과가 틀리는 것이고, 이 조사에서 가장 중요한 칸이다.

| # | 항목 | 결정·상태 | 막던 UB(또는 받지 않는 입력) | debug에서 보이나(실측) | 꺼졌을 때(실측) | 권고 |
|---|---|---|---|---|---|---|
| 1 | `H-198` `Get` 재시작 루프 | 반영됨(2026-10-01 `a9c948b9`) | Compute fn이 자기 의존성을 `Set` | 보인다 — Compute 안 Set 감지 한 줄 | **조용히 틀림** — 첫 `Get`이 1(수렴값 3), 다음 `Get`들이 2, 3으로 따라잡음 | 이미 덮임 |
| 2 | Q93·Q98 yield 가드 | 반영됨(2026-10-01) | Compute fn이 yield한 사이 다른 코루틴이 읽음 | 보인다 — 겹친 실행 감지 한 줄 | 조용히 fn이 한 번 더 돎(Q93: 같은 세대 두 번, Q98: 덮인 캐시 재계산). 최종 값은 맞음 | 이미 덮임 |
| 3 | Observer 설치 재실행 루프·`Quad0262` | 반영됨(2026-10-01) | Observer 설치 fn이 자기 상류를 되먹임 | **반만** — 계속 되먹이면 바인드 때 한 줄, 한 번 되쓰고 멈추는 모양(clamp)은 0줄 | 조용함 — 보류됐다가 바인드·구독 때 한 번 재생. 끝 상태는 맞음 | debug 감지기 확장 권고(보류 갈래에 같은 검사) |
| 4 | `Quad0083` 중괄호 빠진 props 전수 스캔 | debug로 내림(2026-10-01) | `D.Frame(value)`(받지 않는 입력) | 보인다 — 그 검사 자체(에러) | 대개 `Quad0076` 등 다른 에러. 시끄러움 | 이미 덮임 |
| 5 | `Quad0143` `:List` data 키 전수 | debug로 내림(2026-10-01) | 배열에 문자 키가 덧붙은 data | 보인다 — 그 검사 자체(에러) | **조용히 틀림** — 덧붙은 키를 무시 | 이미 덮임 |
| 6 | `Quad0173` Slot 순환 | debug로 내림(2026-10-01) | `s:Add(s)`, `a:Add(b); b:Add(a)` | 보인다 — Add 줄 에러 | Add 통과. 그 트리를 건드리면 엉뚱한 에러(`Quad0160`·`Quad0179`·`Quad0163`·`Quad0232`). 건드리지 않으면 조용함 | 이미 덮임 |
| 7 | `Quad0220` 정적 자식 순환 | debug로 내림(2026-10-01) | Instance를 자기·자손 자리에 | 보인다 — 그 검사 자체 | 엔진 circular reference 에러(spec 고정, 자리는 잡힌 뒤) | 이미 덮임 |
| 8 | `Quad0141` 동적 경로 가드 둘 | 퇴역(2026-10-02 `9787b0ec`) | Slot·Ref를 문자 키에(받지 않는 입력) | 보인다 — `Quad0076` + 문자 키 경고 한 줄 | `Quad0076`가 같은 안내. 반영 프로퍼티 키면 mock은 조용히 저장(실기기는 엔진 대입 에러로 추정, 미실측) | 이미 덮임 |
| 9 | `Quad0031` Claim 배열 키 도메인 | 퇴역(2026-10-01 `8062702b`) | `[2.5] = M.X(…)`(받지 않는 입력) | debug 무관 | `Quad0085`가 drive에서(claim 뒤). 시끄러움 | 필요 없음 |
| 10 | `Quad0261` Operator 넘친 인자 | 퇴역(2026-10-01) — 정의된 동작(무시)으로 | (UB 아님) | 0줄 | 넘친 인자 무시. strict가 잡음 | 필요 없음 |
| 11 | Debounce `Time` 진입 캐시·`Flush` nil 가드 | 결정만(2026-10-02) | 잘못된 `Time` State 값 뒤의 반쪽 상태(던진 뒤 장치) | debug 무관 | 창 끝 타이머 콜백 안에서 `Quad0039`(blame은 `Debounce.luau`), 다음 신호는 사용자 줄에서 같은 에러, `Time`을 고치면 회복. 시끄러움 | 필요 없음 |
| 12 | `H-570` flush 중 `Cancel` | 결정만(2026-10-02, round9 (h) UB로 되돌림) | 하류가 같은 게이트의 `handle:Cancel()`을 flush 도중 부름 | **안 보인다** — 0줄 | **조용히 틀림** — 창이 다시 열려 다음 leading 신호가 한 `Time` 늦음, 저절로 회복. HEAD에서도 핸들 `Flush` 경로는 이미 이 동작 | debug 감지기 추가 권고 |
| 13 | `H-877` 시체 위 새 값 콜백 차단 | 결정만(2026-10-04 Q166 (a) + debug 경고 방향) | 파괴된 인스턴스에 공개 `process`/`drive` | **안 보인다** — 0줄(HEAD에서도 시체 위 drive 자체는 0줄) | **조용히 틀림** — `Started`(스냅이면 `Completed`도)가 시체 위에서 발화, 짝이 될 `Completed`/`Cancelled`는 영영 없음 | debug 감지기 추가 권고(사용자 방향 있음) |
| 14 | `Quad0201` Tag 깊이 가드 | 결정만(2026-10-06 Q176 (a)) | 자기 자신을 품는 이름 리스트 | debug 무관 | stack overflow(`Brand.luau` blame). 정직한 100단 중첩은 이제 통과 | 필요 없음 |
| 15 | Slot CRUD 사전 스캔 | 결정만(2026-10-06 Q170 — 스캔 떼기, `H-517`은 답 대기) | 이미 든 원소 재추가, 마운트 전 두 State가 같은 Instance | debug 무관 | 대부분 `Quad0172`가 같은 Add 줄에서(문구가 덜 구체적). 마운트 전 두 State는 Add 통과, 마운트 줄에서 `Quad0156` | 필요 없음(선택: 같은 스캔을 debug 안에) |
| 16 | `H-240` 부기 `Get` 창 검사 | 결정 대기(Q171 진행 — 사용자 질문 답 대기) | 길이 Compute의 fn이 다른 길이 Source를 `Set` | 보인다 — Compute 안 Set 감지 두 줄 | **조용히 틀림** — 오프셋이 한 파동 낡음(정답 7·218 대신 2·213), 다음 사건에 회복 | 이미 덮임 |
| 17 | `Quad0070` StoreBind 순환 사슬 | 결정만(2026-10-06 Q173 (a) — debug로) | State 값 사슬 순환 | 보인다 — 그 검사가 debug에 남음 | stack overflow(StoreBind 경로는 `Dispatch/init.luau`, Slot 경로는 `Brand.luau`/`State.luau` blame). Slot 원소 경로는 그 뒤 Slot이 망가진 채(원소 빠짐, 다음 Set `Quad0161`) | 이미 덮임 |

## 항목별 근거

프로브 사본과 출력은 같은 폴더 probes/ 아래에 있다(zzdbg_core, zzdbg_slot, zzdbg_debounce, zzdbg_roblox, zzdbg_claim31, zzdbg_propkey, zzdbg_claimorder; 출력은 같은 이름의 .head.out.txt·.after.out.txt). "after"는 HEAD 사본에서 결정된 가드를 지운 판이고, 지운 방법은 probes/after-patches.py에 적었다(실제 반영은 다르게 할 수 있다). 감지기 시험판은 probes/proto-detectors.py다. 레포의 `quad-base/test`·`quad-roblox/test`에 만든 프로브는 실행 뒤 지웠고, 시작할 때 `./scripts/test.sh`는 exit 0이었다.

**1. `H-198` `Get` 재시작 루프.** Compute fn이 자기 의존성을 `Set`하면, 옛 루프는 같은 `Get` 안에서 깨끗한 패스가 나올 때까지 다시 계산해 수렴값을 돌려줬다. 재현은 `up = Source(1)`에 `c = up:Compute(function(x) if x:Get() < 3 then up:Set(x:Get() + 1) end return x:Get() end)`를 두고 `c:Get()`를 세 번 부르는 것이다. 지금은 debug를 꺼도 켜도 세 번이 1, 2, 3을 돌려준다. 첫 `Get`이 에러 없이 한 파동 낡은 값을 주는 셈이다. 켜면 `Source: Set/Emit inside a Compute fn - a Compute only reads and combines (undefined)`가 한 줄 찍힌다(`quad-base/src/Source.luau` 50~55행 `checkWriteInCompute`, 호출은 87~88행). 감지기는 Source마다 한 번만 찍으므로, 같은 fn이 매 실행 되쓰는 경우에도 한 줄로 그친다.

**2. Q93·Q98 yield 가드.** Q93 재현: 코루틴 A가 1세대 fn에서 멈춘 사이 상류가 바뀌고 코루틴 B가 2세대로 들어가 멈춘 뒤, A가 돌아온다. 지금은 A가 돌아오면서 B의 표시를 지우므로 메인 스레드의 다음 `Get`이 2세대 fn을 한 번 더 돌린다(fn 실행 3회). 최종 값은 맞다. Q98 재현: A가 1세대에서 멈춘 사이 메인이 2세대를 끝내고, 그 뒤 A가 돌아와 유효한 2세대 캐시를 무효로 만든다. 그래서 다음 `Get`이 한 번 더 계산한다. 이것도 최종 값은 맞다(100). 두 장면 모두 켜면 `State: Compute fn entered while an earlier run of this node has not returned …`가 한 줄 찍힌다(`quad-base/src/State.luau` 104~115행 `checkOverlappingRun`, 호출 240~241행). 꺼 두면 부수효과 있는 fn이 조용히 두 번 돌 뿐이고, 정의된 값이 틀리지는 않는다. archive `archive/ub-mitigation-loops-and-guards-withdrawn.md`가 적은 대로 두 가드가 판별하던 사건과 감지기 (a)는 같은 사건이다.

**3. Observer 설치 재실행 루프·`Quad0262`.** 지금은 설치 fn 도중 온 변경을 보류(`_rerunRequired`)했다가 바인드·구독 때 한 번 재생한다(`quad-base/src/Observer.luau` 168행). 기존 되먹임 감지기(같은 파일 72~92행, 호출 163행)는 **실행할 수 있는 배달**에서만 묻는다. 설치 창은 실행할 수 없는 상태라 보류 갈래로 가고 거기엔 검사가 없다. 실측은 셋이다. 첫째, `Source(20)`을 10으로 깎는 clamp 설치 fn은 debug를 켜도 0줄이다. 바인드 뒤 fn이 10으로 한 번 더 돌고 끝 상태는 맞다. 둘째, 0에서 3까지 세는 설치 fn은 설치 때 0줄이다. 바인드 때 재생이 다시 `Set`하면서 그 배달이 실행 가능한 중첩이 되어 기존 감지기가 한 줄 찍는다. 셋째, 묶지도 구독하지도 않으면 0줄이고 fn은 옛 값(20)만 본 채 남는다. 레퍼런스(CHANGELOG `[Unreleased]` Changed의 Observer 합류 항목)는 설치 fn이 자기 대상을 바꾸는 것을 정의되지 않은 동작으로 적는다. 그러니 이 모양은 debug가 알려야 할 UB인데 지금은 안 알린다.

감지기 후보는 이렇다. 보류 갈래(`self._rerunRequired = true` 직전)에 기존 `checkUpstreamFeedback`과 같은 검사를 `if module.debug then … end` 한 줄로 둔다. 조건은 같다 — `_running`이 서 있고, 내부 Observer가 아니고, 가장 안쪽 프레임에서 바깥으로 걸을 때 부기 `recompute`보다 이 핸들의 `fn`을 먼저 만나는 것이다. 비용은 debug를 켰을 때 보류되는 배달마다 스택 걷기 한 번이고, 끄면 분기 하나다. 스크래치 사본에서 이 검사를 늘 켜고 quad-base·quad-roblox spec 전체를 돌렸다. 걸린 곳은 다섯이다. `spec.observer` 10의 세 장면은 그 절이 스스로 "관측 — 계약 아님 … 그건 Observer에게 UB다"라고 적은 진짜 되먹임이다. 나머지 둘은 `spec.refhandlers` 4(StoreBind의 설치 창, Ref Q4 장면)와 quad-roblox `spec.events` 9(`:List` 목록 Observer의 설치 창)이다. 이 둘은 내부 Observer가 `observer._internal = true`를 생성자가 설치 fn을 다 돌린 **뒤에** 받기 때문에 생겼다(`quad-base/src/StoreBind.luau` 103행, `quad-base/src/Slot/List.luau` 246행, `Slot/Tree.luau` 31행, `Bookkeeping.luau` 401행이 같은 모양). 그래서 넣는다면 내부 표시를 설치 전에 알 수 있게 하는 작은 조정이 함께 필요하다(생성 경로에 표시를 넘기는 비공개 인자 등). 이것도 새 모양이라 사용자 결정 거리다. 다만 StoreBind는 Q174 (a)(2026-10-06)로 `_internal`이 빠질 예정이고, 그러면 `spec.refhandlers` 4의 경고는 Q5·Q162 (a)가 UB로 정한 장면에 대한 정당한 경고가 된다. 그 밖의 spec(`spec.slot` Q73 장면, `spec.lengthoffset` 포함)에서는 0줄이었다. 다만 `H-886`(Slot을 다시 앉힐 때 `setOffsetSource` 경로의 오경보, 결정 없이 고칠 것으로 분류됨)과 같은 걸러내기 범위를 공유하므로, 그 수정이 이 확장에도 그대로 적용돼야 한다.

**4. `Quad0083`.** debug 층으로 옮긴 검사 자체라 켜면 그대로 에러다. 꺼진 쪽은 `spec.dispatch`(577~585행)가 고정한다 — 프로바이더 브랜드의 평범한 테이블이 "핸들러 없음"류 에러로 떨어진다. CHANGELOG `[Unreleased]`가 "대개 `Quad0076`"이라 적은 그대로이고, 조용히 지나가지 않는다.

**5. `Quad0143`.** 이것도 옮긴 검사 자체다. `spec.slot` 33절이 두 모드를 다 고정한다 — 꺼 두면 `{ { id = "a" }, extra = 1 }`의 `extra`를 조용히 무시하고 배열 부분만 맞추고, 켜면 `key "extra" is not an array position`로 에러다. 꺼진 쪽은 조용히 틀리지만 debug가 에러로 잡으므로 덮였다.

**6. `Quad0173`.** 켜면 `s:Add(s)`와 `b:Add(a)`(a가 b를 품은 뒤)가 Add 줄에서 `Quad0173`이다(`quad-base/src/Slot/init.luau` 62~71행, 호출 277~278행). 꺼 두면 Add가 통과한다. 그 뒤는 연산마다 다르다. 같은 Slot에 다음 Add는 통과하고, 마운트는 `Quad0160 … already mounted elsewhere`, `q.dispose`는 `Quad0179`이다. 두 Slot 고리에서는 `a:Remove(1)`이 `Quad0163 … ownership tracking is broken`(내부 불변식), 마운트는 `Quad0232`이다. 전부 원인과 먼 엉뚱한 에러라 꺼 두면 진단이 어렵다. 그 트리를 다시 건드리지 않으면 조용하다. debug가 정확히 잡으므로 덮였다. 이 연산별 차이는 원장 `H-891`(문서의 "다음 CRUD는 stack overflow" 단정 정정)과 같은 관측이다.

**7. `Quad0220`.** quad-roblox `spec.handlers` 14가 두 모드를 고정한다. 켜면 `Quad0220`, 꺼 두면 mock이 흉내 내는 엔진의 circular reference 에러다(자리는 이미 잡힌 뒤라 그 요소는 버린다). 조용하지 않다.

**8. `Quad0141`(`SlotDynamicPathGuard`·`RefDynamicPathGuard` 퇴역).** 문자 키 `Foo`에 놓인 Slot, `State<Slot>`, Ref는 두 모드 모두 `Quad0076 … brand: Slot) - a quad value at a string key: it belongs in a numeric (array) slot`이다. 켜면 그 앞에 `Slot: found at string key "Foo" - must be an array item …`(문자 키 경고, `quad-base/src/DebugKeyFilter.luau`)가 한 줄 더 나온다. 공개 `process`를 1.5 키로 부르면 두 모드 모두 `Quad0076 … no handler at an array position`이다. 퇴역한 가드가 하던 일이 남은 자리는 반영 프로퍼티 이름 키(`D.Frame{ Size = q.Slot() }`) 하나다. mock에서는 두 모드 모두 조용히 `Size`에 Slot이 저장되고, 켜면 문자 키 경고가 한 줄 나온다. 실기기에서는 엔진의 프로퍼티 대입이 타입 불일치로 에러를 낼 것으로 보이나 실측하지 않았다.

**9. `Quad0031`.** `q.Claim(root, M.Frame(M.Root)({ Size = 2, [2.5] = M.TextLabel("Title")(…) }))`은 두 모드 모두 `Quad0085 Dispatch.drive: array keys must be positive integers (got 2.5)`이다. claim은 이미 일어난 뒤다(root·자식 모두 claimed). 에러 문서(errors/06)가 적은 대로이고, 조용하지 않다.

**10. `Quad0261`.** `q.Operator.Clamp(0, 10, 5)`의 넘친 인자는 두 모드 모두 조용히 무시되고, 결과는 10으로 정상이다. 2026-10-01에 "다른 Lua 함수처럼 무시"를 정의된 동작으로 정했으므로 UB가 아니다. strict 타입 검사가 넘친 인자를 잡는다. debug 경고 한 줄을 붙일 수는 있지만 이번 범위(UB 가드)의 대상이 아니다.

**11. Debounce `Time` 진입 캐시와 `Flush` nil 가드(Q55 (b) 철거).** 이 가드가 막던 것은 UB 입력이 아니다. 잘못된 `Time` 값(받지 않는 값)이 **타이머 경로에서** 던져 남기는 반쪽 상태를 막는 "던진 뒤" 장치였다(followup 3절). 걷은 판은 `openWindow`가 다시 매번 `Time`을 읽게 한 것이다. 거기서 Throttle 창 안에 `Time` State를 −1로 바꾸고 창 끝을 넘겼다. 그러자 타이머 콜백 안에서 `Quad0039`가 났고(blame `quad-base/src/Debounce.luau`, 실기기라면 `task` 콜백 에러 출력), 게이트는 켜진 채 타이머 0개로 남았다. 다음 신호는 사용자의 `Set` 줄에서 같은 `Quad0039`이고, `Time`을 고치면 다음 신호가 보류됐다가 정상으로 흐른다. HEAD에서는 같은 장면의 첫 에러가 다음 신호 줄에서 나고 창 끝은 옛 `Time`으로 다시 열린다. 어느 쪽이든 시끄럽고 debug와 무관하다. 곁들여 "신호 하나 늦게"(followup 3절 장면)도 확인했다. HEAD는 t=2.01에 값 3이 통과했고, 걷은 판은 새 `Time`(5)을 바로 써서 아직 보류다.

**12. `H-570`(flush 중 `Cancel`을 round9 (h) UB로 되돌림).** 재현은 `spec.debounce` 13 그대로다. `Throttle{ Time = 1, Handle = h }`에서 하류 구독자가 값 2를 받으면 `h.Value:Cancel()`을 부른다. 걷은 판에서는 창 끝 뒤 타이머가 1개 남고(다시 열림), 다음 `s:Set(3)`이 보류됐다가 1초 뒤에 통과한다. HEAD에서는 타이머 0개, 3이 즉시 통과한다. 에러 없이 타이밍만 한 `Time` 틀리고 저절로 회복하므로, 꺼 두면 알아채기 가장 어려운 종류다. debug를 켜도 0줄이다. HEAD에서도 핸들 `Flush` 경로(probes D3)는 이미 이 동작이다 — followup 4절이 짚은 비대칭이고, UB로 되돌리면 두 경로가 같아진다.

감지기 후보는 이렇다. `h.Cancel` 머리(`quad-base/src/Debounce.luau` 256행)에서 debug일 때만 `debug.info`로 스택을 걸어, **이 게이트의** `commitIdle`(209행)이나 `h.Flush`(244행) 클로저 프레임을 만나면 한 줄을 찍는다. 클로저 신원으로 비교하므로 다른 게이트의 flush 안에서 부른 정당한 Cancel은 걸리지 않는다. followup 4절이 에러 갈래에서 걱정한 `_flushing` 같은 새 필드도 필요 없고, 던진 뒤 플래그가 남는 문제도 없다(스택은 저절로 풀린다 — Observer 감지기와 같은 이유). 비용은 debug를 켰을 때 Cancel마다 스택 깊이만큼이다. 시험판에서 늘 켜고 spec 전체를 돌렸더니 `spec.debounce` 13 한 곳(바로 그 UB 장면)만 걸렸다. 프로브의 타이머 경로·핸들 `Flush` 경로 둘 다 잡았다. 재진입 `h.Flush`(flush 안에서 같은 게이트 Flush)까지 넣을지는 round9 (h)가 "재진입 Flush도 같은 모양"이라 적었으므로 같이 결정할 거리다(시험판은 Cancel만 넣었다). 만약 Q166처럼 이 갈래도 사용자가 debug 경고를 원하면 `H-570`을 걷는 반영과 한 묶음으로 넣는 것이 자연스럽다.

**13. `H-877`(Q166 — 시체 위 새 값 콜백 차단을 걷고 debug 경고로).** 공개 `q.Dispatch.process`를 파괴된 Frame에 `Size = Tween{ …, Started, Completed, Cancelled }`로 부르는 장면이다. HEAD에서는 콜백 0회다(`quad-roblox/src/Handlers/Property.luau` 182행 `isClaimed` 게이트). 걷은 판에서는 `Started`가 불리고, `Time = 0` 스냅이면 `Started`·`Completed`가 불린다. 두 모드 모두 0줄이다. 같은 파일 머리 주석 말대로 그 `Started`의 짝 `Completed`/`Cancelled`는 영영 오지 않는다. HEAD에서도 파괴된 Frame에 `drive(h, { Size = 3, Name = "after" })`는 두 모드 모두 조용히 성공한다(레퍼런스 extend/02가 "핸들러가 전부 조용히 성공"이라 적은 UB). 사용자 코드의 정상 경로(State에 묶인 Tween, 인스턴스 `Destroy` 뒤 `Set`)는 수명이 구독을 풀어 아무것도 발화하지 않는 것을 같이 확인했다. 노출되는 건 확장 작성자의 직접 호출뿐이다.

감지기 후보는 사용자가 Q166 회신에서 낸 방향 그대로다. `Dispatch.process` 입구(`quad-base/src/Dispatch/init.luau` 370행; `drive`는 키마다 이 함수를 지나므로 한 자리로 둘 다 덮인다)에서 debug일 때만 `module.Backend.isClaimed(inst)`가 거짓이면 한 줄을 찍는다. 시험판에서 늘 켜고 spec 전체를 돌렸더니 quad-roblox `spec.tweenproperty` 13(시체 위 process 두 번 — 그 UB 장면) 두 줄뿐이었다. `D.<Class>` 생성, `Claim`, Slot 마운트, 숏핸드 관리 자식을 쓰는 다른 spec 전부에서 0줄이었다. 오경보가 없는 이유는 두 가지다. `Claim`은 모든 디스크립터를 `nativeClaim`한 뒤에 drive하고(`quad-base/src/Claim.luau` 164~180행, "claim before its drive"), `D`는 생성 때 claim한다. claim되지 않은 살아 있는 외래 인스턴스에 drive하면 수명 바인드가 필요한 자리에서 이미 `Quad0226`으로 막힌다(probes zzdbg_claimorder). 남은 확인 하나: `isClaimed`는 Deferred 시그널 모드에서도 끊긴 gcconn을 동기로 읽으므로(`H-548`) 파괴 직후 같은 프레임의 호출도 시체로 본다. 실기기에서 같은지는 미실측이다.

**14. `Quad0201`(Q176 — Q28로 되돌림).** 걷은 판에서 `t = { "a" }; t[2] = t; q.Tag(t)`는 두 모드 모두 `stack overflow`(blame `quad-base/src/Brand.luau` 116행 — quad 내부 줄)이다. HEAD에서 거부되던 정직한 100단 중첩은 이제 통과한다(`Tag("deep")`). 시끄럽게 끝나므로 debug 감지기가 필요 없다. Q28 사용자 원문("스택 오버는 다른 곳에서도 방어 안 했음")과 Q172 원칙("재귀 고리엔 한도를 두지 않는다")과도 맞다. 굳이 붙인다면 깊이가 아니라 방문 집합으로 자기 포함만 debug에서 찾는 모양이 정직한 중첩을 거부하지 않는다. 그러나 원칙상 권하지 않는다.

**15. Slot CRUD 사전 스캔(Q170 — 스캔 떼기).** 걷은 판은 `prepareElements`가 기존 원소를 `"held"`로 미리 표시하는 루프(`quad-base/src/Slot/init.luau` 234~237행)를 지운 것이다. raw 원소 재추가(마운트 전·후)와 "raw x를 넣은 뒤 `Source(x)` 추가"는 HEAD의 `Quad0170 … reorder with Move/Swap instead of adding it again` 대신 `Quad0172 … this element is already mounted …`이 같은 Add 줄에서 난다. 문구가 덜 구체적이지만 시끄럽다. 마운트된 Slot에 같은 Instance를 든 State 둘을 넣는 경우도 `Quad0172`다. 남는 하나가 Q170 본문이 짚은 경우다 — **마운트 전** Slot에 같은 Instance를 든 State 둘이면 Add는 통과하고, 마운트(drive 줄)에서 `Quad0156 Slot: this element is already mounted …`이 나며 Slot은 빈 채로 남는다. 어느 경우도 조용하지 않으므로 debug 감지기는 필요 없다. 선택지로 같은 스캔을 `if module.debug then … end` 안에 두면, debug에서 HEAD와 같은 문구와 Add 줄 blame을 되찾는다. 로직이 같아 오경보는 없고 비용은 debug일 때만 원소 수만큼이다. 실익은 문구 한 단계와 마운트 전 State 둘 경우의 blame이다.

**16. `H-240`(Q171 — 걷기 권고, 사용자 답 대기).** 재현은 round13 E73의 PBK다(`audit/round13-e73-mutation-2/`). 닫힌 Gate 뒤 길이 Compute의 fn이 다른 길이 Source를 `Set`해 앞자리 길이를 낮추는 장면이다. HEAD는 OF2 = 7, OF4 = 218로 맞다. 걷은 판(getOffsetAt 재시작 가지와 recompute 검사 ①②를 지운 판)은 OF2 = 2, OF4 = 213, `getOffsetAt(2)` = 2, `getOffsetAt(4)` = 213이다. 에러 없이 한 파동 낡은 오프셋을 내고, 다음 사건(`S1:Set`)에 7·218로 회복한다. debug를 켜면 HEAD·걷은 판 모두 Compute 안 Set 감지가 두 줄(`d2:Set`, `S1:Set` — Source마다 한 번)을 찍는다. 이 입력은 Compute 순수성(C2) 위반이라 일반형 감지기가 원인 자리에서 정확히 알린다. 그러니 걷어도 debug 가시성은 잃지 않는다.

**17. `Quad0070`(Q173 — 사슬 걷기를 debug로).** debug를 켜면 지금과 같은 검사가 그대로 돈다(옮기는 것이 그 결정이다). 걷은 판은 꺼진 쪽만 흉내 내려고 검사를 아예 끈 판이고, 그 판의 debug=true 출력은 의미가 없다. 꺼진 쪽은 경로마다 다르다. StoreBind 자리(`b:Set(a)`로 두 State 고리, `s:Set(s)`)는 `stack overflow`(blame `quad-base/src/Dispatch/init.luau` 371행)이고, 다음 정상 `Set`에 회복한다. Slot 원소 자리(마운트된 Slot 안 `st:Set(st)`)는 `stack overflow`(`Brand.luau`) 뒤 원래 원소가 빠진 채 남고, 다음 정상 `Set`이 `Quad0161 Bookkeeping.releaseOwner: element must not be nil`로 던진다 — Slot이 망가진 채다(예외 안전성 계약상 허용). 이미 순환인 State를 `Add`하면 Add는 통과하고 마운트에서 `stack overflow`(`State.luau`)다. 전부 시끄러우므로 debug 층이 정확한 메시지를 맡는 결정과 맞는다.

## 범위 밖으로 둔 것

- Q168 `getHandler` 재검사 걷기(2026-10-06 (a)) — 이미 검사된 값을 다시 검사하던 것이라 UB 입력을 막지 않는다.
- `H-517`(State 원소 현재값의 CRUD 줄 사전 게이트) — 유지 여부가 사용자 답 대기라 걷힌 것이 아니다.
- Q174 (a)(StoreBind Observer에서 `_internal` 빼기) — 가드 제거가 아니라 기존 감지기의 범위 넓히기다. 3번 감지기 확장과 맞물리는 점만 위에 적었다.
- `Quad0263`·`Quad0267`(늘 켜진 반복 한도) — 걷은 것이 아니다.

## 미완

- 실기기(Roblox Studio) 실측은 하지 않았다. 8번의 반영 프로퍼티 키(엔진 대입 에러로 추정), 11번의 `task` 콜백 에러 출력 모양, 13번의 Deferred 모드 `isClaimed`는 mock 기준이다.
- "걷은 뒤" 판은 반영을 흉내 낸 한 가지 방법이다(probes/after-patches.py). 실제 반영이 지우는 범위(예: `H-240`의 커서 증분 쓰기를 어디까지 되돌리는가, Q55 철거에서 `MaxTime` 읽기 위치)에 따라 꺼진 쪽 증상이 달라질 수 있다.
- 감지기 시험판 셋은 늘 켠 판으로 오경보만 쟀다. debug 플래그 아래로 옮긴 판, 경고 문구, spec은 만들지 않았다. 3번 확장에 필요한 내부 표시 순서 조정도 시험하지 않았다.
