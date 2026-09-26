# round13 E45 — `Slot:List` / `:Single` keyFn·updateFn 계약 매트릭스 (2026-09-27, HEAD `86523a1d`)

탐사 전용 산출물(레포 소스 무변경). 런타임은 `quad-base/test/mock.luau`의 `mock.newQuad()` + `Dispatch.drive(host, { slot })`
(엔진 무관 — `env.luau`), strict는 `quad-roblox/luau_packages` **한 벌**(`e45-config.luau`, `typing-limits.md` 8.34) +
luau-lsp 신 솔버 + test.sh 79행 한도 플래그 셋 + roblox defs. 실행: 레포 루트에서 `./scripts/relink.sh` 뒤
`luau .claude/audit/round13-e45-list-contract/<probe>.luau`. 각 `.out`이 원출력.

| 파일 | 축 |
|---|---|
| `probe-keys` | 키 타입 20종 × (첫 사이클·재정렬·키 이사·중복·KeyGone), 데이터 안의 센티널 항목, keyFn throw·비결정 keyFn |
| `probe-firstcycle` | 첫 사이클 vs 이후 사이클에서 던졌을 때 List가 살아남는가 |
| `probe-returns` | updateFn 반환 모양 × `OwnsElements` true/false × 사이클, UD 전달, 잘못된 반환 17종의 에러 ID |
| `probe-crosskey` | 다른 키의 원소 재사용(이름 바꾸기·Detach 보관분·맞바꾸기), 이후 사이클 quad 발 throw, State 반환 유령 |
| `probe-ctx` | `ctx.Index`/`ctx.Offset` 값, ctx 신선도, `:Single` 대표 칸, opts 비불리언·모르는 키 (Offset 구독 행은 미구독이라 무효 — `probe-offset`이 대체) |
| `probe-offset` / `probe-offset2` | `ctx.Offset` 구독(`:Subscribe()`)의 발화, 구독 콜백 throw 시 부모 동결(core/06:129 캐비엇) / 미구독 Observer 대조군 |
| `probe-addthrow` | 마운트된 부모에 `Add`로 들어가는 `:List` Slot의 첫 사이클 throw → 부모 상태 |
| `strict-*.luau` / `.out` | 대표 모양 strict — 문서 예제 원문·UD·Detach·State 반환·테이블 키·opts·무주석 람다·`<<string, nil>>` |
| `bench-keys` | 1000항목, 키 타입별 mount / 같은 키 재조정 / 역순 재조정 / keyFn+해시 단독 (중앙값 5회, `-O2`) |

## 매트릭스 요약

칸 약 126(런타임 101 + strict 20 + 벤치 5). 문서와 어긋난 칸 6, 문서 미정 칸 7. 나머지는 문서대로.

**문서대로인 것(대표)**: 키 타입 string/number/float/inf/boolean/table/Instance/function/`None` 전부 신원 키로 동작, `0`과 `-0`은 같은 키(`Quad0145`),
`1`과 `"1"`은 다른 키; nil·NaN 키 `Quad0144`, 중복 `Quad0145`(둘 다 게이트 전 선행 패스라 이후 사이클이면 무변경·회복); 키 이사 = 옛 키 KeyGone +
새 키 Prev nil; 기본 키(인덱스)는 재정렬해도 자리별 Prev; `ctx`는 호출마다 새 테이블; `ctx.Index`는 숫자 스냅샷(Slot 안 물리 위치,
중첩 Slot 원소 길이 반영, KeyGone 0, nil을 돌려준 항목도 후보 위치 값); `ctx.Offset`은 `slot.Offset`과 같은 State 핸들이고 구독하면 앞 형제
성장에 발화, 구독 콜백이 던지면 부모 부기가 에러 없이 멈춤(core/06:129 재현); 반환 새 원소/Prev/nil/None/Detach/(nil, ud) 전부 문서
표대로, `OwnsElements=false`는 교체·버림·Detach 어디서도 파괴 안 함, Detach는 완전 해제라 재등장 Prev nil(core/06:508); 잘못된 반환 ID
— 평범한 테이블·숫자·문자열 `Quad0240`, `KeyGone` `Quad0146`, Observer `Quad0238`, 파괴됐거나 claim 안 된 Instance `Quad0241`, 파괴된 Slot
`Quad0242`, 다른 Slot의 원소·다른 곳에 마운트된 Slot·자기 자신 `Quad0156`, KeyGone 호출의 새 원소 `Quad0147`; 이후 사이클 quad 발 throw는
문서대로 Length만 멈추고 재조정은 계속; keyFn throw는 사용자 줄 blame·무변경·다음 Set 회복. strict: 문서 core/06 예제 원문 통과, UD·Detach·State
반환·테이블 키·`OwnsElements=false` 통과, `OwnsElements="no"`와 `ctx.Index`를 string에 대입은 잡힘. 벤치: 키 타입 비용은 무시할 수준(keyFn+해시
0.03~0.09ms/1000), 역순 재조정 ~73ms는 키 타입과 무관한 기존 O(N²)(round13에 이미 문항).

## 발견

### (a) 문서 오류

- **A1** `docs/reference/core/06-slot.md:383`이 인용하는 `Quad0167` 문구에 코드(`quad-base/src/Slot/init.luau:148`)와
  `docs/reference/errors/03-slot.md:229`가 가진 꼬리 "(or an earlier mount into this Slot threw mid-way — then this Slot stays unusable:
  dispose its host Instance)"가 빠져 있다(`H-554`가 붙인 꼬리).
- **A2** core/06:400 "updateFn이 도중에 던지면 … 재조정 자체는 계속 돌아 항목이 붙고 떨어지지만 … Length가 더 이상 발행되지 않습니다"는
  이후 사이클에만 맞다. **첫 사이클**에서 던지면 `_activateList`가 `data:Observer(...)` 생성 도중 죽어 `_listObserver`가 없고
  `_listActivated=true`라 다시 설치되지도 않아, 그 뒤의 유효한 `data:Set`이 전부 조용히 무시된다(`probe-firstcycle.out` 4행: 첫 사이클
  `error("user boom")` → 이후 Set 두 번 ok, 원소 그대로·kids 비어 있음). 이미 마운트된 부모에 `Add`로 들어간 경우는 부모까지
  `Quad0167`로 막힌다(`probe-addthrow.out` — `H-554`의 설계 그대로).
- **A3** core/06:458의 괄호 "`:List`는 같은 무주석 람다로 통과합니다"와 `<<string, nil>>` 처방은 **반환이 한 갈래인 람다**에서만 맞다
  (E33 `probe_single3` V4·V7이 `return inst` 한 줄). 문서 자신의 관용구(KeyGone 갈래에서 `return nil` 먼저)는 `:List`·`:Single<<string, nil>>`
  둘 다 첫 `return`에서 반환이 `nil`로 굳어 거부된다(`strict-lambda2.out` A2·A4; 반환 팩만 주석하면 A5 통과 — core/06:410의 규칙이 여기도
  적용됨). 게다가 GS 14 §5 모양(`Text = ctx.Item`을 캐스트 없이)은 `<<string, nil>>` + 반환 팩 주석을 달아도 `No valid instantiation … Item`으로
  죽고(`strict-lambda3.out` b2), `ctx.Item :: string` 캐스트가 있어야 통과한다(b1). Q121의 범위를 넓히는 관측 — 명시 타입 인자만으로는
  문서 관용구가 strict를 통과하지 않는다.
- **A4** core/06:475 `:Single` "state가 State면 값이 바뀔 때마다 그 자리가 통째로 교체됩니다"는 항등(또는 매번 새 원소) `updateFn`에서만
  맞다 — 키가 상수(`true`)라 `updateFn`이 `ctx.Prev`를 돌려주면 x→y→(nil→KeyGone Detach)→z 내내 원소 하나가 유지된다
  (`probe-ctx.out` ":Single keep…" made=1). 같은 절 둘째 항목("같은 모양의 ctx")과 합쳐 읽으면 추론 가능하나 문장 자체는 과장.
- **A5(경미)** core/06:376 반환 표의 `q.Detach` 행("보관합니다. 다음에 ctx.Prev를 반환하면 그대로 다시 붙습니다")에
  `OwnsElements=false`면 보관이 아니라 해제라는 단서가 없다 — 같은 페이지 `q.Detach` 절(508행)에만 있다.

### (b) 코드 결함 / 자리 사이 비일관

- **B1** 첫 사이클의 **도메인 에러**(`Quad0142`/`0143`/`0144`/`0145`/`0146`)도 A2와 같은 결과를 낸다 — 문서(core/06:397, errors/03-slot)는
  이것들을 UB가 아닌 평범한 "재조정 중 에러"로 나열하지만, 첫 사이클에 나면 그 List는 영구히 무반응(`probe-firstcycle.out` 1·2·6행,
  `probe-addthrow.out` 마지막 행: 마운트된 빈 Slot에 `:List`를 걸다 중복 키 → 고친 데이터로 Set해도 Length 0), `Add` 경로면 부모 Slot까지
  `Quad0167`(`probe-addthrow.out` 1행). 같은 에러가 **이후 사이클**이면 게이트 전 선행 패스라 무변경·완전 회복(`probe-firstcycle.out` 3행
  "later dup key" → 다음 Set 정상). 원인: `_activateList`(`quad-base/src/Slot/List.luau:198-205`)가 첫 `reconcile`을 `data:Observer(...)`
  생성 안에서 돌리고, 선행 패스(107-121행)가 던지면 옵저버가 반환되지 않는데 `_listActivated`는 35행에서 이미 참. 최소 재현:
  `local s=q.Slot(); drive(host,{s}); local d=q.Source({"a","a"}); pcall(s.List, s, d, upd, function(x) return x end); d:Set({"a","b"})` →
  원소 0. 처방 제안 없음(판단 필요: 선행 패스 에러는 사용자 콜백 예외가 아니므로 "감싸지 않는다" 원칙과 부딪히지 않는 자리).
- **B2** `updateFn`이 **값이 마운트 불가인 State**(예: `q.Source({})`)를 돌려주면 `:List` 경로는 래퍼를 `rawAdd`로 넣은 **뒤에** 래퍼의
  재조정이 `Quad0240`을 던져, `_elements`에 유령 래퍼가 남고 그 키가 사라져도(KeyGone, Prev nil) 영구히 빠지지 않는다
  (`probe-crosskey.out` "later-cycle State<table> return": elements=2, 데이터를 `{"a"}`로 줄여도 elements=2). 같은 값을 CRUD `Add`로 넣으면
  선행 패스(`checkRawElement`가 State 현재 값을 봄, `Slot/Elements.luau:29-34` 주석의 hunt A)가 넣기 전에 던져 elements=0.
  `:List`의 `settle`(`List.luau:75`)은 `wrapElement`만 부르고 State 현재 값은 검사하지 않는다 — 원시 값(`Quad0240` 평범한 테이블)은 넣기 전에
  던져 유령이 없으므로 같은 `:List` 안에서도 팔 사이 비일관. updateFn 도중 quad 발 throw라 core/06:400의 UB 우산 아래이긴 하나, "유령이
  KeyGone으로도 안 빠짐"은 그 문단이 말하는 결과(Length만 멈춤)보다 넓다.

### (c) 판단 필요 (문서 미정 칸)

- **C1 원소가 키를 옮겨 가는 경로가 없다.** 같은 원소를 새 키에 돌려주면(이름 바꾸기 — 옛 키는 KeyGone 패스가 새 키 뒤에 오므로 아직 소유)
  `Quad0156`이고 그 뒤 Length가 멈춘다(`probe-crosskey.out` 1·2행; 다음 Set도 같은 throw). `OwnsElements=true`에서 Detach로 보관한 원소를
  다른 키가 돌려줘도 `Quad0156`("already mounted" — 실제론 보관 중)인데, `OwnsElements=false`면 Detach가 해제라 다른 키로 옮겨진다(3·4행).
  "키 = 신원이므로 키가 바뀌면 새 원소"가 의도라면 문서에 한 줄, 문구의 "mounted"가 보관분도 가리킨다는 점도 미정.
- **C2 KeyGone 호출이 돌려준 두 번째 값이 남는다.** KeyGone에서 `(nil, ud)`를 돌려주면 `userdata[key]`에 그대로 남아(`List.luau:175`) 같은 키가
  다시 나타날 때 `Prev=nil`·`UserData=ud`로 온다(`probe-returns.out` "(nil, ud)" 로그 `a:prev=nil,ud=gone-ud`). 다시 안 오는 키의 비-nil ud는
  List가 살아 있는 동안 계속 잡힌다. 문서의 "두 번째 반환값은 이 키의 다음 ctx.UserData"로 문자 그대로는 맞으나 KeyGone 행에서의 뜻은 미정.
- **C3 데이터 배열 안의 센티널 항목.** `q.KeyGone`을 항목으로 넣으면(기본 인덱스 키) `updateFn`이 `ctx.Item == q.KeyGone`인데 `ctx.Index ≠ 0`인
  호출을 받고, 관용구 첫 줄이 그걸 "사라진 키"로 처리해 조용히 빠진다(`probe-keys.out` "KeyGone item": `KG@2`); 반환 제한(`Quad0147`)도 안
  걸린다. `q.None` 항목은 `:Single`(None = 없음, `H-467`)과 달리 `:List`에선 평범한 항목으로 온다. 거부할지·UB로 적을지 미정.
- **C4 `OwnsElements`의 비불리언 값.** `"false"`·`0`은 조용히 소유(`== false`만 비소유 — `List.luau:244`); strict는 리터럴 문자열을 잡지만
  (`strict-shapes.out` 45행) `any` 경유는 못 잡는다. debug 진단은 E35 몫.
- **C5 키 `0`/`-0` 동일, `1`/`"1"` 별개** — Luau 테이블 의미 그대로이며 문서 미기재(서술할지 판단만).
- **C6 비결정 keyFn**(같은 데이터에 사이클마다 다른 키)은 에러 없이 매 사이클 전부 재생성 + 전부 KeyGone(`probe-keys.out` built=6 gone=4) —
  "안정적인 값"은 errors/03-slot `Quad0144` "고치려면"에만 있고 `keyFn` 인자 설명엔 없다.
- **C7 `ctx.Offset`을 구독 없이 `:Observer`만 만들면** 등록 1회만 돌고 이후 발화하지 않는다(`probe-offset.out` unheld, `probe-offset2.out`) —
  Observer 일반 계약(canExecute)이지만 `ctx.Offset` 설명("핸들")은 묶거나 `:Subscribe()` 해야 한다는 걸 가리키지 않는다.

## 미완

- `:Single`은 대표 칸(유지·KeyGone·Detach·항등 교체·같은 값 재Set)만; `State<Slot>` 반환·`OwnsElements=false` 래퍼 경로의 키 축은 안 봤다.
- quad-roblox 백엔드(실제 `Declaration` 원소·Property 바인딩)로는 돌리지 않았다 — 전부 mock 백엔드. Studio 미실측.
- B2 유령 래퍼가 구독을 쥐고 있는지(누수)·그 State가 나중에 유효 값이 되면 붙는지는 확인 안 함.
- 벤치는 CLI mock 기준(Roblox VM 아님).
