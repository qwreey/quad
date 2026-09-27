# E77 — 서브시스템 전부를 섞은 무작위 앱의 철거 불변식 퍼저 (CLI `luau` 0.734 + mock)

HEAD `f547c3c8`(시작 `7ba5d586`), 2026-09-27. 레포 파일은 바꾸지 않았고 이 폴더만 새로 만들었다. 하네스는 E70의
`harness.luau`·`engine-globals.luau` 사본이다(`quad-roblox/luau_packages` 한 벌 + 실 `QuadRoblox` 프로바이더 + `D`,
`typing-limits.md` 8.34). 사본에서 바꾼 것은 가상 `task` 큐 조회(`pending`/`now`/`clearQueue`)와 task 에러 훅뿐이다.
재현: 레포 루트에서 `./scripts/relink.sh` 뒤 `mise exec -- luau .claude/audit/round13-e77-teardown-invariants/<파일> -a <인자…>`.

E19~E72의 퍼저들은 서브시스템 하나씩을 참조 모델과 대조했고 E42는 서브시스템별 GC를 쓸었다. 이 퍼저는 모델 대조가 아니라
**앱 생성기**다 — 한 트리 안에 D 요소(Frame/TextButton/TextLabel/TextBox), 프로퍼티(모듈 수명 `Source`·`Compute`·Blocker 게이트·
Debounce/Throttle 게이트·Context 값), Event(`Activated`), `OnChange`·`q.Out`, Tag·Attr·AttrKey, Modifier, Ref/PreRef/PostRef,
Observer, 모듈 수명 신호에 연결하고 cleanup에서 끊는 Effect, OnCreated/OnRendered/OnDestroyed, `Size`에 `q.Tween`(콜백 셋)·`Animate`,
수동 Slot·`:List`(`OwnsElements` 무작위, `q.Detach` 무작위)·`:Single`·중첩 Slot·`State<Instance?>` 자리, 핸들·디스크립터를 담은
`State` 자리(Tag/Attr/Observer/Effect/OnChange), `Fallback`(30%는 빌드 전에 던짐), Debounce/Throttle의 `Handle` + `OnDestroyed`에서
`:Cancel()`을 섞는다. 그 위에 무작위 상호작용 10~40스텝(모듈 Source Set, 버튼 발화, 외부 `Text` 쓰기, 가상 시계 진행, `:List`
데이터 뒤섞기, `:Single` 교체, 자리 교체, Blocker 토글, 트윈 완료 통지, 수동 Slot CRUD)을 돌린 뒤 **철거 경로 열셋** 중 하나로
지운다: `q.dispose(root)`·`root:Destroy()`·앱 `State` 자리 `Set(nil)` 뒤 dispose·앱 Slot `Clear`·`ExtractAll` 뒤 dispose·`Remove`,
그리고 콜백 안 dispose 일곱(모듈 Source Observer, 닫기 버튼 `Activated`, `OnChange`("close" 입력), 페이드 트윈 `Completed`,
형제 트리 Effect의 cleanup, Debounce 타이머로 발화하는 Observer(토스트 자동 닫기), 루트 Slot에 새로 넣은 자식의 `OnRendered`).

잘 짜인 프로그램만 만든다: `State<Instance?>`에서 떼어진 자식·`Extract` 결과·`OwnsElements=false` 키 소멸 원소는 그 스텝 끝에
프로그램이 dispose한다(계약상 사용자 몫 — core/06 404·406, GS 20). 철거 뒤에는 엔진이 할 일(재생 중 트윈 완료 통지)과 모듈 수명
쪽의 움직임(Source Set, 외부 신호 발화, Blocker On/Off, Context 값 Set, 시계 10초)을 한 번씩 흘리고 불변식을 잰다.

## 불변식

1. **GC** — 시드 동안 만든 추적 대상(인스턴스·Source·게이트·Observer·Effect·Slot·Ref·Modifier·OnChange/Out 디스크립터·트윈 값·
   Context 가방과 값)을 약한 테이블에 넣고, 시드의 참조를 전부 놓은 뒤 `mock.resetTweenLog()`(E42 mock 한계 M2)와 `collect` 반복
   (E42 `fullgc`) 뒤 남은 수.
2. **연결·타이머** — 시드의 Effect가 모듈 수명 신호에 건 연결 중 살아 있는 것, 트리 인스턴스의 `Destroying`·`Activated` 연결 수,
   철거 뒤 흘린 자극에 트리 콜백(Observer·Effect fn·게이트 Observer·OnChange·Event·Ref·트윈 콜백·자리 핸들)이 불린 횟수, 시계 10초
   뒤 남은 타이머, 트윈 `Completed` 연결 수.
3. **에러** — 모든 연산을 `pcall`로 감싸고, 격리한 신호 핸들러·task 에러까지 모아 `QuadNNNN` 있음 / 사용자 `boom` / id 없음으로 분류.
4. **횟수** — Effect `fn` 실행 수 = cleanup 수, `dying = true` cleanup은 정확히 1(살아 있을 때 cleanup이 던져 Effect가 죽은 경우만 0 —
   core/05·E55), OnDestroyed 1회, 트윈 `Completed + Cancelled ≤ Started`, 트리 인스턴스 전부 파괴됨.
5. **교차 잔재** — 같은 태그·속성 이름·Provider·모듈 Source·Blocker·외부 신호를 쓰는 고정 시나리오(`canon`)를 시드마다 철거 직후
   돌려, 시작 때 같은 `q`에서 뽑은 기준 트레이스와 한 글자라도 다르면 차등. 기준은 새 모듈(`Quad.New():UseProvider`)에서 뽑은
   트레이스와도 같다(`canon equal: true`).

## 결과

| 실행 | 시드 | 노드 | 스텝 | (1) GC 잔여 | (2) 연결/사후 콜백/타이머/트윈 연결 | (3) id 없는 에러 | (4) 횟수 위반 | (5) 교차 차등 |
|---|---|---|---|---|---|---|---|---|
| Immediate(핸들러 격리) `out-fuzz-immediate-1-8000.txt` | 8,000 | 123,942 | 203,249 | 0 (추적 82만) | 0 / 0 / 0 / 0 | 0 (에러 26,479 전부 사용자 `boom`) | 0 | 0 |
| Deferred(`Destroying`을 호출 뒤 배달) `out-fuzz-deferred-8001-14000.txt` | 6,000 | 93,534 | 151,384 | 0 (추적 61만) | 0 / 0 / 0 / 0 | 0 (19,686 전부 `boom`) | 0 | 0 |

철거 경로 열셋이 시드당 약 1/13씩 고르게 뽑혔다. "trigger missed"(형제 Effect cleanup으로 지우는 경로에서 루트가 안 죽은 것,
Immediate 108·Deferred 59)는 같은 `flag:Set` 파동에서 먼저 도는 트리 안 cleanup이 사용자 `boom`을 던져 파동이 끊긴 경우로, E55 (b)
"한 파동에 throw가 있으면 첫 throw가 파동을 끊는다"와 같다 — 그 시드는 뒤이어 `q.dispose(root)`로 지우고 불변식을 똑같이 쟀다.
트윈 콜백 합계는 S 24,947 / C 23,696 / X 136(Immediate): 철거 때 재생 중이던 트윈은 철거 뒤 엔진 완료 통지를 흘려도 `Completed`가
불리지 않았고(`H-594`), `Cancelled`도 불리지 않았다(roblox/06 271 — 브리프의 "진행 중이면 Cancelled"는 문서와 다르다, E50 C2와 같은 정정).

### 검출력 (`out-mutants.txt`, 시드 500씩)

| 변이 | 무엇을 망가뜨리나 | 잡은 불변식 |
|---|---|---|
| `skipCleanup` | 생성기 Effect의 cleanup이 외부 신호 연결을 안 끊음 | (2) 497/500 시드·사후 콜백 9,578, (5) 500 |
| `holdStrong` | 트리 인스턴스 하나를 전역 강한 테이블에 둠 | (1) 489/500 (`inst`) |
| `noDestroying` | 백엔드 `onDestroying`을 무연결로 | (2)·(4)·(5) 496~500 |
| `claimedAlways` | `isClaimed`를 항상 참(`H-594` 게이트 무력화) | (2) 사후 `tweenCompleted` 62 시드 |
| `strongSub` | 게이트 Observer를 호스트 대신 `:Subscribe()` | (1)·(2)·(5) 488~500 |
| `plainError` | 엔진 `AddTag`가 id 없는 에러를 던짐 | (3) id 없는 에러 431 + 반쯤 지어진 트리 잔재로 (1)·(2)·(4)·(5) |

### 성능 모양 (`out-perf*.txt`, mock — 상대 모양만)

혼합 컴포넌트(Tween·Debounce·Tag 둘·Attr·Effect+연결·Observer 둘·OnDestroyed·Ref·손자 둘)를 `:List`로 n개 늘어놓고 dispose:
원소당 1.9µs(n=100) → 7.7µs(n=6400). 깊은 사슬은 0.6 → 2.1µs(n=50 → 3200). `Destroy`도 같은 모양. 부착물을 하나씩만 단
`perf-attach.luau`는 어느 종류든 부착물 몫이 원소당 0.2~1.5µs로 거의 일정하고, 증가분은 부착물 없는 대조군(`none` 1.5 → 4.0µs)이
그대로 갖는다. 그 대조군의 증가는 mock 자체(`perf-mock-baseline.luau`: quad 없이 자식 n개 Destroy가 원소당 0.9 → 2.9µs — mock
`Parent = nil`의 형제 목록 `table.find`와 `Disconnect`의 `table.find`가 O(n))와 힙 크기(GC)로 설명된다. **quad 쪽 철거 비용은
부착물 수에 선형**으로 본다. 단 GC를 멈출 수 없어(Luau `collectgarbage`에 stop 없음) 힙 효과를 따로 떼지는 못했다.

## 발견

**1 (LOW, 문서 — 확장 작성자 표면).** 이미 `D`가 만든 요소에 `q.Dispatch.drive(inst, { a, b })`를 한 번 더 부르면, 그 배열이 차지하는
숫자 키 자리(1·2…)에 원래 앉아 있던 값이 **파괴가 아니라 철거**된다. 거기가 Effect였으면 `cleanup(false)`가 그 자리에서 돌고
인스턴스가 나중에 죽어도 `dying = true` cleanup은 영영 없고, OnDestroyed였으면 조용히 떼어져 파괴 때 불리지 않는다
(`probe-redrive.luau`: `fn |drive{1,2} cleanup(false) |kids=1 |Destroy` — OnDestroyed 무호출, 3번 자리 자식은 남음). 이것은
"같은 자리에 다른 핸들러가 오면 옛 층을 무르고 새로 설치"(extend/02 66)의 당연한 귀결이라 코드 결함은 아니다. 다만
extend/02 195행 `drive` 절은 "props 테이블 하나를 요소에 통째로 적용하는 파이프라인"이라고만 적고, 이미 만든 요소에 다시 부를 때
같은 번호 자리를 덮는다는 말이 없다. 이 퍼저가 처음에 "루트에 자식을 붙이려고" 이 호출을 썼다가 Deferred 모드에서만 cleanup
횟수 위반 25시드로 보였다(Immediate에선 파괴가 철거보다 먼저 와 가려짐 — `probe-onrendered-deferred.luau`의 옛 판). 코드
`quad-base/src/Dispatch/init.luau` 463(`drive`) → 309(`process`); 문서 `docs/reference/extend/02-dispatch-handler-contract.md` 195.
갈래: (a) `drive` 절에 "이미 만든 요소에 다시 부르면 그 숫자 키 자리를 `process`로 다시 처리한다 — 앉아 있던 값은 철거된다(Effect
`cleanup(false)`, OnDestroyed 해제); 자식을 덧붙이려면 처음부터 선언해 둔 Slot에 `Add`" 한 문장 / (b) 그대로. 새 이름·메커니즘 없음.

그 밖의 코드 결함·새 문서 오류는 찾지 못했다.

## 확인만 한 것

- 위 표의 다섯 불변식 전부, 두 배달 모드, 철거 경로 열셋에서 위반 0. 특히 콜백 안에서 루트를 dispose하는 일곱 자리(모듈 Source
  Observer·버튼 Activated·OnChange·트윈 Completed·형제 Effect cleanup·Debounce 타이머 Observer·새 자식의 OnRendered)가 전부 cleanup
  `true` 1회·OnDestroyed 1회·사후 발화 0·GC 0.
- 퍼저 밖 dispose 자리 열둘(`axes-dispose-sites.luau`): `:List` updateFn·keyFn(데이터 뒤섞기 중), Ref `Callback`, Tween `Started`·
  `Cancelled`, Effect `fn`, 자기 호스트의 Observer, Throttle 타이머 Observer, `q.Out` 되쓰기 뒤 Observer, `Slot.Offset` Observer, 만드는
  중인 자식의 OnCreated, Context 값 Observer — 전부 에러 없이 루트가 죽고 cleanup `true` 1회·OnDestroyed 1·사후 0·GC 0.
- 만드는 중인 자식의 OnCreated가 호스트를 dispose한 뒤 그 자식을 호스트의 Slot에 `Add`하면(`probe-oncreated-child.luau`) `Add`는
  성공하고 자식은 파괴된 호스트 밑에 붙어 파괴되지 않으며 `q.dispose(자식)`는 `Quad0179`, 참조를 놓아도 GC 뒤 남는다 — core/06 617
  "마운트 대상이 파괴된 Slot은 그 사실을 모릅니다"(UB)의 한 사례로, 새 항목 아님.
- `Fallback`이 삼킨 예외(여기선 한 인스턴스에 같은 이름 `q.Attr` 둘 → `Quad0002`)가 남긴 반쯤 지어진 트리는 모듈 수명 Source에
  계속 반응하고(Observer 3/3 발화, Effect 재실행), 그 cleanup이 던지면 **무관한 호출자의** `flag:Set`으로 올라온다
  (`probe-orphan-live.luau`). sugar/05 34·core/06 609·E5-2 관측표("아무것도 안 하면 전부 잔존")와 같다. 생성기 초기판이 자리 교체에서
  같은 이름 Attr을 겹쳐 이 경로를 밟았을 때 (5) 교차 잔재가 그대로 드러났다(외부 연결 +4~30, 캐논 도중 고아 cleanup의 `boom`).
- 철거 뒤 흘린 트윈 완료 통지가 죽은 트리의 `Completed`에 닿지 않는 것은 `isClaimed` 게이트 덕이다(`claimedAlways` 변이에서 62시드
  위반) — `H-594` 그대로.
- 핸들을 담은 `State` 자리: `q.Modifier`는 Source 값이 될 수 없다(`Quad0182`, `probe-api.luau`), Tag/Attr/Observer/Effect/OnChange
  자리는 교체·nil 모두 문서대로(Attr는 물러나도 엔진 값 유지 — `probe-seats.luau`).
- 모듈 인스턴스 둘(같은 `q`의 시드 뒤 / 새 `Quad.New()`)의 캐논 트레이스가 같다 — 철거 뒤 교차 잔재 0.

## 미완

- 실기기(Studio) 대조 없음 — 엔진의 Deferred 배달·`Destroying` 순서·파괴된 부모에 `Parent` 대입은 mock 가정 그대로(E50·E79·Q157 쪽).
- (1)의 "잔류 경로"는 잔여가 0이라 쓸 일이 없었다 — 경로 추적 도구는 만들지 않았다.
- 생성기가 쓰지 않은 것: `Claim`, `q.Store`, `Operator`, 문자 키 숏핸드(UICorner 등), `Ref:Wait`, 끝나지 않는 트윈(`RepeatCount=-1`),
  계속 발화하는 상류 위 게이트(Q129 — 철거 뒤 자극은 한 번씩만 흘림), 여러 모듈 인스턴스가 한 트리를 섞는 경우, 콜백 안 yield.
- 콜백 동작은 없음·읽기·모듈 Source Set·던지기 넷뿐 — 죽어 가는 Slot CRUD(Q139 ③ UB)는 일부러 뺐다.
- Deferred 모드는 `Destroying`만 미룬다 — 프로퍼티 변경·이벤트 신호의 Deferred(Q157)는 흉내 내지 않았다.
- 시드는 앞 시드가 모듈 Source에 남긴 값을 이어받으므로 개별 시드 단독 재실행은 전체 실행과 다를 수 있다(위반 0이라 재현이 필요한
  시드는 없었다).
- 성능은 mock 위 상대 모양이고 GC를 떼지 못했다.

## 파일

| 파일 | 내용 |
|---|---|
| `harness.luau`, `engine-globals.luau` | E70 하네스 사본(+ 타이머 큐 조회·task 에러 훅) |
| `fuzz.luau` | 앱 생성기 + 철거 경로 열셋 + 불변식 다섯. `-a <첫 시드> <개수> [v\|q] [변이] [deferred]` |
| `out-fuzz-immediate-1-8000.txt`, `out-fuzz-deferred-8001-14000.txt` | 본 실행 둘 |
| `out-mutants.txt` | 변이 여섯 검출 결과 |
| `axes-dispose-sites.luau` → `out-axes-dispose-sites.txt` | 퍼저 밖 콜백 자리 열둘에서 dispose |
| `probe-redrive.luau` → `out-probe-redrive.txt` | 발견 1 — 이미 만든 요소에 `drive` 재호출 |
| `probe-onrendered-deferred.luau` → `out-probe-onrendered-deferred.txt` | OnRendered 안 dispose, Immediate/Deferred 모양 여섯(깨끗한 모양) |
| `probe-oncreated-child.luau` → `out-probe-oncreated-child.txt` | 호스트를 지운 자식의 `Add` 뒤 운명 |
| `probe-orphan-live.luau` → `out-probe-orphan-live.txt` | Fallback이 삼킨 뒤 반쯤 지어진 트리의 반응 |
| `probe-api.luau`, `probe-seats.luau` → `out-probe-api.txt`, `out-probe-seats.txt` | 생성기에 쓴 표면 확인 |
| `perf.luau` → `out-perf.txt` | 철거 시간 대 트리 크기(넓게·깊게, dispose·Destroy). `-a noExt\|noPulse\|bare` 변형 |
| `perf-attrib.luau`, `perf-attach.luau`, `perf-mock-baseline.luau` → `out-perf-attrib.txt`, `out-perf-attach.txt`, `out-perf-mock-baseline.txt` | 성능 원인 분리 |
