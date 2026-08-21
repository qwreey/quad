# `Gate` — emit을 가로채는 공용 게이트 노드 (2026-08-21 신설)

**상태**: research — **방향은 사용자 확정, 정확한 표면이 미정.
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
2. **`:Apply` 팩토리인가, 독립 생성자인가.** `Debounce`/`Throttle`이
   `state:Apply(Debounce{...})` 관용구로 확정돼 있으므로 `state:Apply(Gate(setup))`가
   자연스럽다. 그런데 `Blocker()`는 **여러 state에 공유되는 외부 객체**라 모양이
   다르다 — `Blocker`가 `Gate` 위에 어떻게 얹히는지(`blocker`가 각 gated state마다
   `Gate`를 하나씩 만들어 자기 정책을 심는 형태?)를 같이 정해야 한다.
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
