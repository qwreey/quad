# `Gate` — emit을 가로채는 게이트 노드 (2026-08-21 확정)

**상태**: **표면 확정.** `Blocker`/`Debounce`/`Throttle`이 공유하는 게이팅
메커니즘을 `state:Gate(setup)` **메소드**로 확정했다 — *"Gate 는 따로 프리미티브
없이 `state:Gate( (emit) -> ()->() )` 처럼 선언되고 마치 Compute 처럼
GateNode(ComputeNode 처럼) 생성된다 그리고 Blocker 는 해당 내부 배선을 따른다
← 동의합니다 해당 방법대로 확정하면 됩니다."* 구현은 **M2**("게이팅 먼저"
결정, `ROADMAP.md`). **남은 것은 아래 "아직 안 정한 것"** — 그중 **4번(유보된
emit이 싣는 source)은 `setup` 시그니처를 바꿀 수 있어 M2 착수 전 판단이
필요하다**(2026-08-21 `/code-review high` 발견).

**⚠️ 처음 방향이 한 번 바뀌었다.** 신설 당시엔 *"공용 `Gate` 프리미티브를 꺼내고
`Blocker`가 그걸 컴포지션한다"*였는데, 확정된 형태는 **프리미티브를 따로 안
만들고 State 메소드 하나로 끝낸다**이다 — *"Gate 프리미티브를 만들고 Blocker 가
컴포지션 하는걸 생각했는데, 그럴 필요가 없네요. `:Gate` 는 또 Apply 에서 쓸만한
표면을 주기도 하구요."* 아래 본문 중 "공개 프리미티브로 꺼낸다"류 서술은 그
이전 시점 표현이니 이 배너 기준으로 읽을 것.

**한 줄**: `Blocker`가 쓰던 "게이티드 State 노드"를 한 겹 일반화해서, **상류
emit을 가로채 내려보낼지 말지를 정책이 정하는** 노드를 **`state:Gate(setup)`
공개 메소드**로 낸다(탑레벨 생성자가 아니라 — 위 배너 참고).
`Blocker`/`Debounce`/`Throttle`이 그 위에 얹히는 서로 다른 정책이 된다.

## 왜 지금인가 — 두 갈래가 같은 자리를 가리켰다

1. **`CR-3`(마일스톤 순서)** — `Dispatch.drive`의 배치 등록이 Blocker 게이팅을
   전제하므로 M2가 M3의 `Blocker.luau`에 구조적으로 의존한다. 사용자 결정:
   **게이팅을 먼저 만든다.**
2. **`DT-4`(Debounce/Throttle)** — 공개 `Blocker` API 위에는 시간 기반 게이트를
   못 얹는다. `base/debounce-throttle-plan.md`가 이미 "게이티드 노드를 내부 공용
   `Gate`로 일반화하고 그 위에 정책을 얹으라"고 권고해뒀고, M3에서 Blocker를
   만들 때 같이 해두지 않으면 같은 설계를 두 번 하게 된다.

**사용자 논거(`DT-4`)** — Blocker + Observer 조합으로는 왜 안 되는가:
*"스로틀/디바운싱에 Observer 를 걸어야하는데, 이 옵저버의 emit 이 먼저이냐
후행 Blocker 로 생성된 요소의 emit 이 먼저이냐가 문제되기 때문에 Blocker/Observer
가지고는 구현 못 한다. 순서를 보존해야한다는 전재가 생기는데 중간이 비어 해시가
되면 이를 전혀 못 지키기 때문."* → 게이트가 **emit 경로 자체에 끼어들어야**
하고, 바깥에서 관측만 해서는 순서를 보장할 수 없다.

**공개 여부**: 사용자 판단 — *"이 API가 비공개일 이유는 없어보인다."* 즉
내부 배관이 아니라 **공개 표면**으로 낸다. **[2026-08-21]** 다만 그 표면은
탑레벨 프리미티브가 아니라 **State 메소드 `:Gate`** 다(아래 2번).

## 제안된 모양 (사용자 스케치 그대로)

```lua
Gate(function(emit)
    -- 이 `emit`은 setup 밖으로 캡처해 **언제든** 부를 수 있다(타이머 콜백 등).
    return function()
        -- 상류 emit이 도착할 때마다 호출된다.
        -- 여기서 `emit()`을 부를지 말지는 정책 마음.
    end
end)
```

- `setup(emit) -> onUpstreamEmit` 2단 구조. 바깥 함수는 게이트 인스턴스가
  만들어질 때 1회, 반환된 함수는 상류 emit마다.
- `Blocker`는 이 위의 정책 하나가 된다 — "켜져 있으면 `emit()`을 안 부르고
  플래그만 세워두고, 꺼질 때 한 번 부른다"(`HasBlockedEmit`이 그 플래그).
- `Debounce`/`Throttle`도 정책 — 타이머를 걸고 창이 끝날 때 `emit()`.

## 아직 안 정한 것 (사용자 판단 필요)

1. **[2026-08-21 해소] 이름 — `Gate`.** 원래 걸림돌은 *"프리미티브 명을
   Gater? 뭔가 이상하게 들어간다"*였는데, **탑레벨 프리미티브를 안 만들기로
   하면서 문제 자체가 사라졌다** — 이름이 놓이는 자리가 `Blocker()` 같은
   생성자가 아니라 `state:Gate(...)` **메소드**이고, 메소드 자리에서 `Gate`는
   `:With`/`:Compute`/`:Observer`와 나란히 자연스럽다. 노드 타입 이름은
   `ComputeNode`와 짝을 맞춘 **`GateNode`**.
2. **[2026-08-21 해소] `:Apply`가 아니라 State의 메소드다 — `state:Gate(setup)`.**
   **확정 형태**:

   ```lua
   -- setup: (emit: () -> ()) -> (onUpstreamEmit: () -> ())
   local gated = state:Gate(setup)   -- ComputeNode처럼 GateNode를 하나 만든다
   ```

   `Blocker`는 **그 위에 얹히는 별개 프리미티브**로, `state:Block(blocker)`가
   내부에서 이 배선을 그대로 쓴다. 탑레벨 `Gate(...)` 생성자는 **안 만든다.**
   `:Gate`가 메소드라고 `:Apply`와 배타적인 것도 아니다 — 사용자 지적대로
   *"`:Gate` 는 또 Apply 에서 쓸만한 표면을 주기도"* 하므로,
   `Debounce{...}` 같은 유저랜드 팩토리가 내부에서 `s:Gate(policy)`를 부르는
   형태로 `state:Apply(Debounce{...})` 관용구가 그대로 성립한다.

   **사용자 확정**: *"gate 는 apply 불가하다고 판단함. 순수 슈가가 아니기 때문,
   state 의 전파를 손대는 작업이라 with 처럼 다른 노드가 나는게 맞음."*
   - **정확한 경계**: `Apply`는 `factory(self)`일 뿐이라(`base/source-state-plan.md`의
     "`state:Apply(factory)`" 절) 팩토리가 노드를 만드는 것 **자체는** 금지가
     아니다 — 확정 예시의 `capAt(100)`도 `:With` 노드를 만든다. 갈리는 지점은
     **누가 프리미티브인가**다: `:With`/`:Compute`처럼 **전파 경로에 새 종류의
     노드를 끼우는 것은 State의 메소드**, 그 프리미티브들을 조합한 **유저랜드
     팩토리는 `:Apply`**. `Gate`는 전자다.
   - **그래서 `Debounce`/`Throttle`은 `:Apply` 그대로 둔다** —
     `Debounce{...}`가 돌려주는 팩토리가 내부에서 `s:Gate(policy)`를 부르면
     되므로 `base/debounce-throttle-plan.md`의 확정 관용구는 안 건드려도 된다.
   - **`Blocker` 배선 문제도 같이 사라진다.** `base/blocker-plan.md`가 이미
     **`state:Block(blocker) -> state`(새 gated state 반환)** 라는 **메소드**로
     확정해뒀으므로, `Block`이 내부에서 `self:Gate(blocker의 정책)`을 부르는
     것으로 끝난다 — `blocker` 객체를 `Apply`에 넘길 일이 없다.
   - **`__call`은 안 쓴다.** 사용자도 *"이상적이여 보이지는 않음"*이라 했고,
     타입 쪽 근거가 하나 더 있다 — `__call` 테이블이 Luau에서 `(State<T>) -> U`
     함수 타입 자리에 그대로 들어가는지가 불확실하다(들어가지 않는 쪽이 유력).
     `Apply`를 쓸 이유 자체가 없어졌으므로 확인할 필요도 없어졌지만, 혹시
     되살아나면 `luau-test` 스파이크 한 개로 판정할 것.
   - **2단 구조는 그대로 유효하다** — 사용자 관찰(*"Gate 의 callback 으로 얻어진
     emit과, 리턴해낸 클로저가 호출되는걸로 배선은 가능"*) 대로, 바깥 함수가
     **그 노드의 `emit`을 캡처**하고 반환 클로저가 상류 emit마다 정책을 태운다.
     `Blocker`처럼 **여러 노드가 공유하는 정책**은 공유 상태를 바깥 객체가 들고,
     노드별 `emit`만 2단 구조로 받아 등록하면 된다.
3. **[2026-08-21 확정] `Get()`과의 관계 — 값이 아니라 통지만 막는다.**
   `Blocker`가 이미 그렇고(`base/blocker-plan.md`의 "`:Get()`엔 영향 없음"),
   `Debounce`/`Throttle`도 emit-gate로 확정돼 있어(`base/debounce-throttle-plan.md`
   §4) `Gate`도 같은 계약으로 통일한다. 공개 계약 문구: **"게이트를 통과하지
   않은 값도 `:Get()`으로는 보인다."**
   `base/state-epoch-plan.md`가 이 계약에 **의존**한다 — 그 문서 §5의 3번이
   "게이트를 에포크 경계로 만드는" 대안을 기각한 이유가 정확히 이 계약을
   뒤집지 않기 위해서다.
4. **⭐⭐ [2026-08-21 신설 — M2 표면에 영향] 게이트가 유보했다 내보내는 emit은
   어느 source를 싣는가.** 확정된 `setup`은 `(emit: () -> ()) -> (() -> ())`로
   **양쪽 다 source를 안 받는다.** 그런데 `base/state-epoch-plan.md` §2의 수신
   규칙 셋은 전부 `[source]` 키로 판정한다 — 게이트가 `A:Set(); Z:Set()`을
   묶어뒀다가 `blocker:Off()`로 한 번에 내보내면, 그 emit이 **어떤 source도
   지목하지 못한 채** 하류에 도착한다. 그러면 하류는 3번 규칙으로 **삼켜버리고
   배치 통지가 통째로 사라진다.** 5라운드 M절이 이미 *"`nil` 규약만 `Gate`
   설계와 같이 확정하면 된다"*고 짚어뒀는데 표면 확정 때 같이 안 닫혔다
   (2026-08-21 `/code-review high` 발견).
   후보 셋 — 어느 쪽이든 `setup`/`emit` 시그니처가 바뀐다:
   - **(a) `emit(nil)` = 전체 확인.** 받는 쪽이 `sourceCountMap` 전체를 훑는다.
     M절의 원안. 비용은 2~4칸 순회라 작지만, "판정은 O(1)"이라는 §3 서술에
     예외가 하나 생긴다.
   - **(b) 게이트가 유보한 source 집합을 기억했다가 해제 때 각각 emit.**
     판정은 O(1) 그대로. 대신 유보된 소스가 N개면 하류가 **N번** 통지받아
     `Blocker`의 "정확히 1회"가 깨진다 — `Blocker` 목적과 정면 충돌이라
     그대로는 못 쓴다.
   - **(c) `GateNode` 자신을 source처럼 취급.** 해제 emit이 `emit(self)`를
     싣고 게이트가 자기 count를 하나 올린다. 하류는 정확히 1회 통지받고
     판정도 O(1). 대신 하류의 맵에 루트 Source가 아닌 노드가 섞이므로 §2의
     "루트 Source들의 에포크"라는 서술을 넓혀야 한다.
   **에이전트 권고는 (c)** — `Blocker` 계약("정확히 1회")과 O(1) 판정을 둘 다
   지키는 유일한 안이고, "게이트가 하류에게는 새 원천처럼 보인다"는 게 게이트의
   실제 의미와도 맞는다. 단 `Get()` 계약(통지만 막음)은 그대로 유지된다 —
   §5-3이 기각한 "게이트를 **에포크 경계**로 만들기"와는 다르다. 그건 하류가
   루트 Source를 **못 보게** 만드는 안이고, (c)는 루트 Source를 그대로 보면서
   게이트를 **하나 더** 얹는 것뿐이다.
5. **생명주기.** 게이트 노드가 잡는 자원(타이머/플래그)이 언제 죽는가 —
   지금 설계대로면 다운스트림이 다 죽으면 GC(팩토리는 weak 추적,
   `debounce-throttle-plan.md` 5-4). `Gate` 자체에 `Flush`/`Cancel` 같은 표면을
   둘지, 그건 정책(Debounce)만의 것으로 둘지.
6. **재진입.** `Blocker`의 "재진입 의도적 미지원"(`blocker-plan.md`)이 `Gate`
   레벨의 계약으로 올라가는지 — 즉 `onUpstreamEmit` 안에서 같은 게이트의
   `emit()`을 재귀적으로 부르는 경우.
7. **⭐ 소비자가 하나 더 있다 — `Effect(fn, ...deps)`의 최초 1회 억제.**
   2026-08-21 5라운드 `C-6`에서 확정된 다중 의존성 `Effect`는, 의존성마다 구독을
   걸면 각 구독의 "등록 즉시 1회 실행"이 N번 발화하므로 **설치 구간 동안 발화를
   눌러뒀다가 마지막에 한 번만 실행**해야 한다(`base/effect-plan.md`의 그 절).
   즉 `Gate`(또는 `Blocker`의 직접 사용)가 **"설치 구간을 감싸 최초 발화를 한
   번으로 접는" 용례까지 커버해야** 한다 — 설계할 때 이 소비자를 같이 볼 것.
8. **M2 범위.** M2에 `Gate`만 넣고 `Blocker`는 M3에 그대로 둘지, 아니면
   `Blocker`까지 같이 앞당길지. `Dispatch.drive`의 배치 등록이 실제로 쓰는 건
   `blocker:On()`/`OffWithoutEmit()`/`IsOn()`이므로(배치 게이팅 절), **최소한
   그 세 메서드가 도는 형태까지는 M2에 필요**하다.

## 관련 문서

- `base/blocker-plan.md` — 현행 `Blocker` 확정(이 문서가 일반화하려는 대상).
- `base/debounce-throttle-plan.md` — "공개 `Blocker` API 위엔 못 얹음" 절이
  `Gate` 일반화를 처음 권고한 자리, 그리고 정책 쪽 설계 전량.
- `base/dispatch-core-plan.md` — "배치 등록을 안전하게 만드는 Blocker 게이팅"
  절이 M2가 실제로 요구하는 표면.
- `ROADMAP.md` M2/M3.
