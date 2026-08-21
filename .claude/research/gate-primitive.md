# `Gate` — emit을 가로채는 공용 게이트 노드 (2026-08-21 신설)

**상태**: research — **방향은 사용자 확정, 정확한 표면이 미정(단 [2026-08-21]
"`:Apply`가 아니라 State 메소드"까지는 확정됨 — 아래 2번).
[2026-08-21] 사용자 지시로 설계 자체는 다음 세션으로 미룸** — *"고칠것이 많으므로
Gate 는 다음 세션에 다루겠음. 해당 부분은 정정이 아니고 추가이고, 새 인터페이스를
고민해야하므로 해결해야할 일로 남겨두길 바람. 단지 지금 세션 상 지식만 이전될 수
있게 두세요."* 그래서 이 문서는 **다음 세션이 바로 이어받을 수 있게 재료만**
모아둔 상태다(아래 "아직 안 정한 것"이 그 목록). 구현 전 QA
5라운드(`CR-3`/`DT-4`)에서 "M2 전에 게이팅부터 만들 준비를 하고, 실질적 모양을
정의해야 한다"는 사용자 결정이 나와 신설. 회신 원문은
`qa-request/pre-implementation-qa-round5-response.md`.

**한 줄**: `Blocker`가 쓰는 "게이티드 State 노드"를 한 겹 일반화해서, **상류
emit을 가로채 내려보낼지 말지를 정책이 정하는** 노드를 공개 프리미티브로 꺼낸다.
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
내부 배관이 아니라 공개 프리미티브로 낸다.

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

1. **⭐ 이름.** 사용자 지적: *"프리미티브 명을 Gater? 뭔가 이상하게 들어간다는게
   약간의 문제."* — 코퍼스 관례가 `Blocker`/`Modifier`/`Observer`처럼 `-er`가
   많아서 형태만 맞추면 `Gater`인데 영어로 어색하다.
   **에이전트 권고: `Gate` 그대로.** `blocker`/`modifier`와 달리 `gate`는 이미
   **행위자가 아니라 장치를 가리키는 명사**라 `-er`를 붙일 이유가 없다
   (`Source`/`Ref`/`Slot`/`Tween`도 전부 `-er` 없는 명사). 대안 후보:
   `Valve`(밸브 — 흐름 제어라는 뜻은 더 정확하지만 코퍼스 어휘와 멀다),
   `Relay`(전기 릴레이 — "받아서 다시 보낸다"는 뜻은 맞으나 "중계"로 오독 여지).
2. **[2026-08-21 해소] `:Apply`가 아니라 State의 메소드다 — `state:Gate(setup)`.**
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
3. **`Get()`과의 관계.** `Blocker`는 `:Get()`에 영향이 없고(`base/blocker-plan.md`),
   `Debounce`/`Throttle`도 emit-gate로 확정됐다(`base/debounce-throttle-plan.md` §4).
   `Gate`도 **값이 아니라 통지만 막는다**로 통일하는 게 맞는지 확인 필요 —
   맞다면 "게이트를 통과하지 않은 값도 `:Get()`으로는 보인다"가 공개 계약이 된다.
4. **생명주기.** 게이트 노드가 잡는 자원(타이머/플래그)이 언제 죽는가 —
   지금 설계대로면 다운스트림이 다 죽으면 GC(팩토리는 weak 추적,
   `debounce-throttle-plan.md` 5-4). `Gate` 자체에 `Flush`/`Cancel` 같은 표면을
   둘지, 그건 정책(Debounce)만의 것으로 둘지.
5. **재진입.** `Blocker`의 "재진입 의도적 미지원"(`blocker-plan.md`)이 `Gate`
   레벨의 계약으로 올라가는지 — 즉 `onUpstreamEmit` 안에서 같은 게이트의
   `emit()`을 재귀적으로 부르는 경우.
6. **⭐ 소비자가 하나 더 있다 — `Effect(fn, ...deps)`의 최초 1회 억제.**
   2026-08-21 5라운드 `C-6`에서 확정된 다중 의존성 `Effect`는, 의존성마다 구독을
   걸면 각 구독의 "등록 즉시 1회 실행"이 N번 발화하므로 **설치 구간 동안 발화를
   눌러뒀다가 마지막에 한 번만 실행**해야 한다(`base/effect-plan.md`의 그 절).
   즉 `Gate`(또는 `Blocker`의 직접 사용)가 **"설치 구간을 감싸 최초 발화를 한
   번으로 접는" 용례까지 커버해야** 한다 — 설계할 때 이 소비자를 같이 볼 것.
7. **M2 범위.** M2에 `Gate`만 넣고 `Blocker`는 M3에 그대로 둘지, 아니면
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
