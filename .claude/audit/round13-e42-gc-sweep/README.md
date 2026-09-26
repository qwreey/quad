# round13 E42 — 서브시스템별 GC 누수 스윕 (CLI `luau` 0.734, mock 백엔드)

HEAD `1440b9ca`, 2026-09-27. 레포 파일 무변경 — 이 폴더만 새로 만들었다.

## 방법

- `harness.luau`·`engine-globals.luau`는 `round13-s10-snippet-recheck/`의 **복사본**이다(`quad-roblox/luau_packages` 한 벌 +
  `quad-roblox/src` + `quad-base/test/mock.luau`; QuadRoblox 프로바이더의 **실제** `LifetimeHandle`(gcconn/gchold)이 mock 인스턴스 위에서 돈다;
  `task`는 가상 시계 심).
- `gclib.luau`: `fullgc()` = `collectgarbage("collect")`을 최소 3회, 카운트 변화가 0.5KB 미만이 될 때까지(최대 12회).
  `measure(name, scen, N)` = 같은 시나리오를 N=0(기준선)과 N으로 돌리고, weak-key 추적자(`__mode="k"`)에 남은 객체 수(**잔여**)와
  기준선을 뺀 KB 증분을 찍는다. `rounds()` = 같은 시나리오를 여러 번 돌려 누적 KB가 **단조 증가**하는지(추적 안 한 객체의 누수) 본다.
- **판정은 잔여 수가 기준이다.** 단발 KB 증분은 weak 테이블·해시 용량의 고수위 때문에 ±수백 KB씩 흔들린다(맨 `Quad.New()` 1000개가
  회차별 +121/+1/−63/+65KB — 탐색 중 실측, 프로브는 남기지 않음). 그래서 KB는 `rounds`의 단조 증가 여부만 누수 신호로 썼다.
- 재현: 레포 루트에서 `./scripts/relink.sh` 뒤, 이 폴더에서 `mise exec -- luau probe-X.luau`. 출력은 `out/`.

## 시나리오 표 (N=1000, 달리 적힌 것 제외)

| # | 시나리오 | 잔여 | 판정 | 프로브 |
|---|---|---|---|---|
| (a) | `D.Frame{}` → `q.dispose` / `:Destroy()` | 0 / 0 | 잔여 0 | a1·a3 |
| (a′) | `D.Frame{}` 만들고 참조만 놓음 | 1000 inst | **계약**(quad가 만든 Instance는 Destroy로만 회수 — Quadnomicon 3 §3) + mock 한계 겹침(아래 M1) | a2 |
| (b) | 부모 `Destroy`/`q.dispose` — 자식의 Source·Compute·Observer·Effect·Ref·Tag·Attr·Slot·Slot 원소; UICorner/UIPadding 관리 자식; 유일 Tag·AttrKey 이름 | 0 | 잔여 0 (`rounds` 1.2→1.4MB에서 평탄 — 용량 고수위) | a-b·b-rounds·b2·shorthand |
| (c) | `Slot:Add`/`Remove`·`Clear`·`Extract`+dispose·중첩 Slot·`:List` 데이터 교체(새 키/같은 키)·중첩 `:List`·`:Single` 교체·호스트 Destroy/dispose·미마운트 Slot dispose | 0 | 잔여 0 (`rounds` 평탄; 중첩 `:List`는 5회차부터 2.4MB 평탄) | c·c2·c9·c9b |
| (c′) | `Extract` 뒤 버림 / `Source(frame)`로 넣고 `Remove` / 미마운트 Slot을 버림 / `OwnsElements=false` 키 소멸 | 1000 elem (Slot 자체는 수거) | **계약**(살아서 나온 원소·State 소유 원소는 사용자가 dispose — core/06 L404·L406) | c1c·c1e·c7·c10 |
| (d) | `Compute` 사슬(깊이 3·다중 의존)을 상류만 두고 버림; 미구독 Observer; `WeakSubscribe` Observer/Effect 버림; `Subscribe`→`Unsubscribe`; `Apply(Blocker)` 게이트 버림 | 0 (`up._subs` 0) | 잔여 0 — 약한 구독 계약 그대로 | d |
| (d′) | `:Subscribe()` 해 두고 버림 | 1000 obs | **계약**(강한 구독은 모듈 수명 — core/05 L153) | d6 |
| (e) | 긴 수명 Source·Ref에 묶인 Observer/Effect(+cleanup)·던져 죽은 Effect·`State<Observer?>`/`State<Effect?>` 자리 교체(호스트 생존 중)·OnCreated/OnRendered/OnDestroyed·PreRef/PostRef, Destroy/dispose | 0 (`up._subs`·`ref.Callbacks` 0) | 잔여 0 | e·e2 |
| (e′) | 긴 수명 Ref를 N개 인스턴스에 차례로 앉히고 파괴 | 1 inst (마지막 것) | **계약**(Ref는 Destroy를 감지하지 않는다 — core/07 L92) | e9·e10 |
| (f) | 재생 중·완료된 Tween(콜백 유무)·`Animate`, 인스턴스 Destroy/dispose; 살아 있는 인스턴스에서 트윈 1000회 교체 | 0 (교체 시나리오는 현재 트윈 1) | 잔여 0 — 2026-09-21 Studio `tweenSlots` 실측과 일치 | f |
| (f′) | 위와 같되 `mock.tweenLog`를 비우지 않음 | 1000 inst | **mock 한계**(M2) | f6 |
| (g) | Store 생성·버림(필드가 인스턴스에 묶임)·긴 수명 Store 값 교체·Context 가방/Provider 생성·버림·긴 수명 가방의 값 교체·Context 값 Source를 컴포넌트에 묶고 Destroy | 0 | 잔여 0 | g |
| (g′) | 긴 수명 Store에 `:Of(새 이름)` N번 / 긴 수명 가방에 새 Provider N개 `:Set` | 1000 | **계약**(`:Of`는 만들어 저장 — core/04; 가방은 강하게 쥔다 — sugar/01 L35) | g3·g6 |
| (h) | Debounce/Throttle(Leading·MaxTime) 창이 열린 채 호스트 Destroy → 2×Time 흘림; 긴 수명 팩토리로 게이트 N개; `Handle` Ref | 0 | 잔여 0 (흘리기 전·창 안에선 게이트+상류 잔여 — 문서의 "마지막 신호 뒤 2×Time" 그대로) | h |
| (h′) | **상류가 계속 Time보다 촘촘히 발화**하는 동안, 파괴된 호스트의 게이트 | 1000 gate, 60초 내내 | **판단 필요 (C1)** — 상류가 조용해지면 3초 안에 0 | h2·h3-min |
| (i) | `Claim`(foreign mock 트리, 반응형 props·Slot·Observer) → root Destroy/dispose; 해석 패스에서 실패한 Claim 버림 | 0 | 잔여 0 | i |
| (i′) | 적용 단계에서 던진 Claim, Destroy 없이 버림 | 2000 (root·자식) | **계약/UB**(roblox/04 L107 — 적용 단계 throw는 claim이 남는 UB; Destroy하면 0, i6) | i5 |
| (j) | `q.Out`+`Text = src`·`OnChange`(긴 수명 Source 캡처)·Event 키 콜백, Destroy; `State<OnChange?>` 자리 교체 | 0 (보이는 `cb=1`은 Luau 클로저 캐시 — M4) | 잔여 0 | j·j-closurecache |
| (k) | Modifier 세터 체인 1000개(정적 필드 이름)·Modifier를 Frame에 적용 후 Destroy | 0 (`rounds` 평탄) | 잔여 0 — 세터 캐시는 이름 수로 유계 | k |
| (k′) | 계산된 세터 이름 / 새 `TypedFactory` 이름 | 캐시 +~200KB/1000이름 단조 / ctor 1000 | **이미 문서화**(Modifier/init.luau L262-268·L232-238 "ROADMAP backlog", round11 L′4) / 클래스 레지스트리는 모듈 수명(설계) | k3·k4 |
| (l) | `Quad.New()` 1000개 버림; +`UseProvider(QuadRoblox)`; +`AddPlugin(최상위 fn)`; +Frame 만들고 Destroy | 0 | 잔여 0 | l·l2 |
| (l′) | 모듈을 캡처한 인라인 `AddPlugin`/`RunInit` 클로저 | 1000 module | **계약**(core/01 L90 그대로 재현) | l5·l7 |
| (l″) | 모듈이 만든 Frame을 Destroy하지 않고 모듈·Frame 둘 다 버림 | 모듈·inst 200/200 | **계약**의 파생(C2 참고) | l9 |

요약: **quad 쪽 강한 참조 잔여(코드 결함) 0건.** 비0 잔여는 전부 문서화된 계약·설계이거나 mock 한계였고, 설명이 모자란 자리 둘(C1·C2)이 판단 문항이다.

## 발견

### (a) 문서 오류

없음. 문서가 약속한 수거(약한 구독·약한 `_subs`·gchold 앵커·트윈 슬롯·Ref 콜백 해제·팩토리의 약한 게이트 목록·`q.dispose`/Destroy 경로)는
전부 잔여 0으로 재현됐고, 문서가 "남는다"고 적은 것(강한 구독, 캡처 플러그인, State 소유 원소, Ref.Value, 적용 단계 throw Claim, `:Of` 필드,
Context 가방)도 전부 적힌 대로 남았다. C1의 서술 범위 문제는 결정 사안이라 (c)로 올렸다.

### (b) 코드 결함

없음.

### (c) 판단 필요

**C1 — 계속 발화하는 긴 수명 상류 위의 Debounce/Throttle 게이트는 호스트가 죽어도 상류가 조용해질 때까지 산다.** 컴포넌트 안에서
`hot:Apply(q.Debounce { Time = 1 })`(또는 Throttle)처럼 모듈 수명의 상류(마우스 위치·매 프레임 시계 같은 것)에 게이트를 걸고 그 결과를
프로퍼티에 묶은 뒤 호스트를 Destroy하면, 게이트는 대기 타이머 콜백이 쥐고 있고 상류의 약한 `_subs`에도 그대로 남아 있어서 다음 발화를
또 받는다. Debounce는 신호마다 창을 다시 시작하고 Throttle은 통과가 창을 다시 여므로, 상류가 Time보다 촘촘히 발화하는 한 타이머가 끊기지
않아 게이트(와 상류 사슬 캐시)가 영원히 수거되지 않고, 발화마다 죽은 게이트 전부가 창 처리를 되풀이한다. `probe-h3-min.luau`에서
Time=1 게이트 1000개(호스트 전부 파괴)가 10Hz 상류 아래 60초 내내 1000개로 남았고, 상류를 멈추자 3초 안에 0이 됐다(Debounce·Throttle 둘 다).
호스트 파괴 직후 상류가 한 번이라도 발화하느냐에 따라 남는 개수가 GC 진행에 좌우되므로(파괴와 첫 발화 사이에 GC가 먼저 수거한 게이트는 안
남는다 — `probe-h2`에서 1000개 중 57·163개), 실제 게임에선 "가끔 몇 개"로 보이는 비결정 잔여로 나타난다. 문서 쪽 근거는
`.claude/base/debounce-throttle-plan.md` 8절(1108~1116행 "마지막 신호 뒤 최대 2 × Time … 유계이고 자가 치유됨", 위험 조합은 "긴 Time + 빠른
생성/파괴"만)과 `quad-base/src/Debounce.luau` 58~60행 머리 주석("bounded, self-healing")이다. "마지막 신호 뒤"라는 문구로는 틀리지 않지만,
그 전제(상류가 언젠가 조용해진다)가 적혀 있지 않고 공개 레퍼런스 `docs/reference/sugar/03-debounce-throttle.md`에는 이 수명 이야기가 아예 없다.
이것이 의도된 보유(상류가 사는 동안 게이트가 따라 사는 것은 `Compute` 사슬과 같은 성격)로 보고 문서에 전제와 조합을 적을지, 아니면
결함으로 볼지가 판단 사안이다. 제어 핸들의 `:Cancel()`(8절이 이미 드는 기존 수단)이나 `OnDestroyed`로 부르는 것이 지금 있는 회피로이며, 새
메커니즘은 제안하지 않는다. 대조: 같은 상류 위의 평범한 `Compute`는 잔여 0(`probe-h2` control).

**C2 — 모듈 인스턴스는 자기가 만든 Instance가 Destroy되지 않으면 함께 남는다.** `docs/reference/core/01-quad-module.md` 34행은 "인스턴스는
참조를 놓으면 수거됩니다. 모듈을 키로 삼는 전역 맵이 인스턴스를 붙잡지 않습니다"라고만 적는다. 전역 맵에 관한 서술은 사실이지만,
`Quad.New():UseProvider(QuadRoblox)`로 Frame을 하나 만들고 Destroy 없이 모듈과 Frame을 둘 다 버리면 둘 다 남는다(`probe-l2` l9 — Frame의
gchold가 체인 리스트·리트랙터를 거쳐 그 모듈의 클로저를 붙든다; Destroy하면 둘 다 0, l8). "quad가 만든 Instance는 Destroy로만 회수된다"는
계약(Quadnomicon 3 §3)의 당연한 파생이라 결함은 아니고, 같은 페이지가 90행에서 플러그인 캡처로 모듈이 남는 경우는 적어 두었으니 이 경우도
한 줄 덧붙일지(주 사용처는 모듈을 만들고 버리는 테스트 하네스) 정도의 사소한 판단이다.

## mock·측정 한계 (quad 쪽 발견과 분리)

- **M1 — mock `dataOf`는 ephemeron이 아닌 weak-key/strong-value 표다**(`quad-base/test/mock.luau` 118행). quad가 만든 mock 인스턴스는
  gcconn 콜백(값 `data` → `data.changed.ClassName` 시그널 → 클로저 → 프록시)이 제 키를 되참조하므로, Destroy(연결 해제) 전엔 mock 자체가
  영구 보유한다. 엔진 계약("Destroy로만 회수")과 결론이 겹쳐서 a2·c1c·c7 같은 "버렸지만 Destroy 안 함" 시나리오에서는 quad가 붙드는지
  mock이 붙드는지를 CLI로 가를 수 없다(둘 다 붙든다). Destroy된 인스턴스에 대해서는 mock이 모든 연결을 끊으므로 판정이 유효하다.
- **M2 — `mock.tweenLog`가 기록마다 `inst`를 강하게 쥔다**(`mock.luau` 918행 `{ inst = inst, … }`). `resetTweenLog()` 없이 재면 트윈이
  걸렸던 인스턴스가 전부 남는다(f6, 1000개). 트윈 객체 자체는 인스턴스를 약하게 쥐도록 이미 고쳐져 있다(880~883행).
- **M3 — 하네스 `task` 심 큐**가 대기 중 콜백을 쥔다. 엔진 `task.delay`와 같은 성격이라 한계라기보다 대응물이다(h1·h3의 창 안 잔여).
- **M4 — Luau 클로저 캐시**: 업밸류가 반복마다 바뀌지 않는 클로저(`function(v) shared:Set(v) end`, `function() end`)는 반복마다 **같은
  객체**다(`probe-j-closurecache` — 5회 반복에 서로 다른 클로저 1개). j2·j4·j5의 `cb=1` 잔여는 이 캐시 한 개이며, 반복 변수를 캡처하면 0이다(j2b).
- 합성 KB 수치는 테이블 용량 고수위 때문에 단발로는 의미가 약하다 — `rounds`의 평탄/단조만 봤다. 단조 증가는 k3(문서화된 세터 캐시)
  하나뿐이었다.

## 미완

- 실기기(Studio) 대조는 안 했다(지시로 금지). C1의 실제 영향(RunService 주도 상류)은 엔진에서 한 번 볼 가치가 있다.
- `Fallback`/`Traceback`·`Operator`·`Void`·`EpochMap` 단독 시나리오는 따로 돌리지 않았다(앞의 시나리오 안에서 간접으로만 지남).
- mock 한계 M1 때문에 "Destroy 안 된 인스턴스를 quad가 추가로 붙드는가"는 CLI로 판정 불가.

## 파일

`gclib.luau`(측정 헬퍼), `harness.luau`·`engine-globals.luau`(복사본), `probe-*.luau`(시나리오), `out/*.txt`(출력).
