# `Gate` — emit을 가로채는 게이트 노드 (2026-08-21 확정)

**상태**: **표면 확정.** `Blocker`/`Debounce`/`Throttle`이 공유하는 게이팅
메커니즘을 `state:Gate(setup)` **메소드**로 확정했다 — *"Gate 는 따로 프리미티브
없이 `state:Gate( (emit) -> ()->() )` 처럼 선언되고 마치 Compute 처럼
GateNode(ComputeNode 처럼) 생성된다 그리고 Blocker 는 해당 내부 배선을 따른다
← 동의합니다 해당 방법대로 확정하면 됩니다."* 구현은 **M2**(반응형 코어 —
**[2026-08-24 정정]** 2026-08-22에 디스패치 쪽으로 앞당겼다가 마일스톤 순서
교체로 되돌아옴, `ROADMAP.md`). **남은 것은 아래 "아직 안 정한 것"의 생명주기와 마일스톤 범위뿐이고, 둘 다
구현 시 정하면 되는 것들이다 — 사용자 판단이 필요한 항목은 없다** — `/code-review high`가 잡았던 4번(유보된 emit이 싣는 출처)은 같은
날 흡수 집합으로 닫혔고, **`setup` 시그니처는 안 바뀌었다.**
(**[2026-08-22 표기 정정]** 여기와 4번 제목에 `emit(self)`라 적혀 있었으나
그건 `Epoch` 일반화 **이전** 표기다 — 지금 싣는 건 떼어낸 `EpochSet`
스냅샷이고 게이트 노드 자신은 안 싣는다, 바로 아래 ⚠️ 문단이 소스.)

**⚠️ 처음 방향이 한 번 바뀌었다.** 신설 당시엔 *"공용 `Gate` 프리미티브를 꺼내고
`Blocker`가 그걸 컴포지션한다"*였는데, 확정된 형태는 **프리미티브를 따로 안
만들고 State 메소드 하나로 끝낸다**이다 — *"Gate 프리미티브를 만들고 Blocker 가
컴포지션 하는걸 생각했는데, 그럴 필요가 없네요. `:Gate` 는 또 Apply 에서 쓸만한
표면을 주기도 하구요."* 아래 본문 중 "공개 프리미티브로 꺼낸다"류 서술은 그
이전 시점 표현이니 이 배너 기준으로 읽을 것.

**⚠️ [2026-08-21 반영 완료] emit 페이로드는 `Epoch | EpochSet`이다**
(`EpochSet = { [Epoch]: true }` — **배열이 아니라 집합**,
`base/state-epoch-plan.md` §3) — 하류가
게이트 identity를 한 번도 안 쓰므로 게이트 노드 자체는 안 싣고 **떼어낸
`Epoch` 집합 스냅샷**만 넘긴다(근거 기록은
`reference/epoch-brand-composition.md`). 아래 4번의 기제(흡수 집합, flush 시
스왑, 게이트-게이트 unfold, 빈 배치 무통지)는 그대로다.

**한 줄**: `Blocker`가 쓰던 "게이티드 State 노드"를 한 겹 일반화해서, **상류
emit을 가로채 내려보낼지 말지를 정책이 정하는** 노드를 **`state:Gate(setup)`
공개 메소드**로 낸다(탑레벨 생성자가 아니라 — 위 배너 참고).
`Blocker`/`Debounce`/`Throttle`이 그 위에 얹히는 서로 다른 정책이 된다.

## 왜 지금인가 — 두 갈래가 같은 자리를 가리켰다

1. **`CR-3`(마일스톤 순서)** — `Dispatch.drive`의 배치 등록이 Blocker 게이팅을
   전제하므로 M3가 M2의 `Blocker.luau`에 구조적으로 의존한다. 사용자 결정:
   **게이팅을 먼저 만든다.** (이건 그 결정에 이르게 된 *당시* 상태 서술이다 —
   **[2026-08-24] 지금은 `Blocker.luau`가 M2(반응형 코어)에 있고 그 M2가
   먼저 지어진다**, 아래 9번. 2026-08-22에 잠깐 디스패치 쪽으로 옮겼던 것은
   마일스톤 순서 교체로 되돌려졌다 — `state:Gate`가 State 메소드이고
   `GateNode`/`Blocker`가 State 위에 얹히는 이상 게이팅을 State보다 먼저 둘
   수는 없었고, 그래서 **반응형 전체를 앞으로 옮기는** 쪽으로 풀렸다.)
2. **`DT-4`(Debounce/Throttle)** — 공개 `Blocker` API 위에는 시간 기반 게이트를
   못 얹는다. `base/debounce-throttle-plan.md`가 이미 "게이티드 노드를 내부 공용
   `Gate`로 일반화하고 그 위에 정책을 얹으라"고 권고해뒀고, Blocker를
   만들 때 같이 해두지 않으면 같은 설계를 두 번 하게 된다(항목 1과 마찬가지로
   **당시** 서술은 "반응형 마일스톤에서 Blocker를 만들 때"였다 —
   **[2026-08-24]** 지금은 `Blocker.luau`도 M2다, 아래 9번).

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
   -- setup: (emit: (commit: boolean?) -> boolean) -> (onUpstreamEmit: () -> ())
   local gated = state:Gate(setup)   -- ComputeNode처럼 GateNode를 하나 만든다
   ```

   **⭐⭐ [2026-08-25 확정, 7라운드 `H-55`/`H-86`] `emit`에 인자와 반환값이
   붙는다.** 인자 목록이 늘지 않으므로 `H-49`의 *"`setup` 시그니처는 안
   바뀐다"*를 최소로만 되짚는다.

   | 호출 | 뜻 |
   |---|---|
   | `emit()` / `emit(true)` | 평소대로 흡수 집합을 flush하고 전파 |
   | `emit(false)` | **흡수 집합을 버리고** 전파하지 않는다 |
   | 반환값 | "실제로 내보내거나 버릴 게 있었는가"(= 집합이 비어 있지 않았는가) |

   - **왜 필요한가 (1) — 버릴 수가 없었다(`H-55`).** 아래 4번은 *"emit 없이
     푸는 경로는 집합을 **버려야** 한다"*고 확정하는데, `Blocker`가
     `blocker:Policy(emit)` **값**으로 떨어져 나온 뒤로 정책이 손에 쥔 건
     `emit` 하나뿐이라 **집합에 닿는 통로가 없다.** 그래서
     `Trailing = false`/`Cancel`/`OffWithoutEmit`이 "버린다"가 아니라
     "미룬다"가 되어, 버리기로 했던 옛 원천들이 **다음 버스트에 실려
     나간다**(4번이 경고한 바로 그 모양이 정책 분리로 되살아난 것).
   - **왜 필요한가 (2) — 읽을 수가 없었다(`H-86`).** 5번이 *"`pending` 같은
     정책 상태는 `HasBlockedEmit`으로 흡수한다"*고 확정했는데, `blocker-plan.md`가
     `HasBlockedEmit`을 **게이트 노드의 `withheld`**로 흡수해버려 **양쪽 다
     안 들고 있다.** 그 결과 `Throttle`의 창이 idle로 못 돌아가
     **leading이 첫 버스트 이후 영구 소실**되고 타이머 체인이 안 끝나
     `base/debounce-throttle-plan.md`의 "8. 라이프사이클 / GC 분석" 절이 확정한 "유계 GC"가 깨진다(실측 확인).
   - **`Throttle`의 `onWindowEnd`가 이 한 줄로 닫힌다**:
     ```lua
     if not emit() then window = nil   -- 보류분 없었음 → 완전 idle 복귀
     else rearm() end
     ```
   - **기각된 안**: `setup(emit, discard, hasWithheld)`처럼 핸들을 늘리는 것
     (인자 목록 자체가 바뀌어 `H-49`를 더 크게 되짚는다), 정책이 자기
     `pending`을 다시 드는 것(`H-32`를 손으로 다시 막아야 하고 버리기는
     여전히 안 닫힌다).

   `Blocker`는 **그 위에 얹히는 별개 프리미티브**로, `state:Apply(blocker)`가
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
     것으로 끝난다 — **[2026-08-28 `H-158` 정정]** 그 메소드는 폐기됐고 지금은
     정확히 반대로 `blocker` 객체를 `state:Apply(blocker)`에 넘긴다(`blocker:__apply(state)`가
     `state:Gate(...)`를 감싼다 — 메소드형, `self`는 blocker). 결과 노드가 `GateNode`인 건 같다.
   - **`__call`은 안 쓴다.** 사용자도 *"이상적이여 보이지는 않음"*이라 했고,
     타입 쪽 근거가 하나 더 있다 — `__call` 테이블이 Luau에서 `(State<T>) -> U`
     함수 타입 자리에 그대로 들어가는지가 불확실하다(들어가지 않는 쪽이 유력).
     **⭐ [2026-08-25 실측 확정, 7라운드 `H-94`] 안 들어간다.**
     `luau-analyze`로 재현했고(제네릭·비제네릭 양쪽), 타입 레벨 `__call`은
     `self`도 못 받는다. 여기서 *"확인할 필요도 없어졌다"*고 접었지만
     **`Debounce`/`Throttle` 쪽엔 그 불확실성이 그대로 남아 있었다** — 바로
     아래 항목이 *"`Debounce`/`Throttle`은 `:Apply` 그대로 둔다"*를 확정하기
     때문. 그래서 애플리커티브 팩토리는 `__call`이 아니라 **지정된 필드**로
     자기를 노출한다(`base/source-state-plan.md`의 "`state:Apply(factory)`" 절).
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
   `base/state-epoch-plan.md`가 이 계약에 **의존**한다 — 그 문서가 "게이트를
   에포크 경계로 만드는" 대안을 기각한 이유가 정확히 이 계약을 뒤집지 않기
   위해서다 — 그 문서 §8의 "기각된 대안 — 게이트를 에포크 경계로" 항목.
4. **[2026-08-21 해소] 게이트가 유보했다 내보내는 emit — 흡수 집합
   스냅샷.** 문제는 실재했다: 확정 `setup`은 `(emit: () -> ()) -> (() -> ())`라
   양쪽 다 출처를 안 받는데 `base/state-epoch-plan.md`의 수신 규칙은 전부
   `[epoch]` 키로 판정하므로, `blocker:Off()`가 묶어뒀던 배치 emit이 아무
   원천도 못 지목한 채 도착해 **하류에서 삼켜진다**(2026-08-21
   `/code-review high` 발견).

   **확정 기제**(사용자 안, 에이전트가 냈던 (a) `nil` 전체 확인 / (b) 소스마다
   개별 emit은 기각 — 각각 O(1) 판정을 깨거나 `Blocker`의 "정확히 1회"를 깬다):

   - `GateNode`가 **자기를 거쳐간 `Epoch` 집합**을 들고 있는다 —
     `withheld : { [epoch] : true }`, **weak key**(`EpochMap`과 같은 이유,
     `state-epoch-plan.md` §3).
   - **⭐ [2026-08-21 단순화] 통과와 유보를 구분하지 않는다.** 상류 emit이
     오면 **정책을 실행하기 전에 무조건** 그 출처를 `withheld`에 넣고, 그
     다음 정책을 실행한다. 정책이 `emit()`을 부르면 게이트가 하류에 전파하고,
     안 부르면 집합에 그대로 쌓인다.
     - **⚠️ [2026-08-21 `/code-review high`] "무조건"은 *정책의 통과/유보와
       무관하게*라는 뜻이지 *수신 규칙을 건너뛴다*는 뜻이 아니다.** 게이트도
       평범한 노드처럼 `state-epoch-plan.md` §4의 규칙 1~3을 **먼저** 적용하고,
       3번(둘 다 같음)으로 삼켜진 emit은 **정책도 안 돌고 집합에도 안
       들어간다.** 안 그러면 다이아몬드(`A→B→G`, `A→C→G`)에서 `A:Set()` 한
       번에 정책이 두 번 돌아, `Throttle`의 leading 통과 직후 두 번째 emit이
       `pending`을 세워 **이미 전달한 변경에 대한 유령 trailing emit**이
       나간다.
   - **⭐⭐ 정책이 받는 `emit`은 "이 값을 내보내라"가 아니라 "쌓인 걸 지금
     흘려보내라"(flush)** — 페이로드를 정책이 정하지 않는다. 그래서 배치를
     떼어내는 것도 **그 핸들 안**에서 일어난다.
     `base/debounce-throttle-plan.md`가 이미 같은 것을 `gate:passThrough()`
     ("invalid 세팅 + 아래로 1회 전파")로 부르고 있다.
   - **전파 페이로드는 `withheld` 자체가 아니라 flush 진입 시점에 떼어낸
     스냅샷이다.** **[2026-08-21 정정]** 여기 한때 "전파가 반환된 뒤에
     `table.clear`"라고 적었는데 그게 틀렸다 — 전파가 스택에 남아 있는 동안
     제어가 같은 게이트로 되돌아오면(하류 Observer가 상류를 `:Set()`,
     `debounce-throttle-plan.md`의 `onWindowEnd` 주석이 이미 대비하는 경우)
     중첩 flush의 `clear`가 돌아 **바깥 전파의 남은 갈래가 빈 집합**을 받는다.
     **모델이 아니라 그 의사코드가 문제였다** — `emit()`이 flush인 이상 들어가는
     순간 떼어내는 게 원래 모양이고, 그러면 그 경로 자체가 없다:
     ```lua
     -- ⭐ [2026-08-25 보강, 7라운드 `H-89`] 아래 8번과 `H-89`가 확정한
     --   **네 단계**를 그대로 적는다. 한때 이 스니펫이 가운데 둘만 갖고
     --   있어서, 이걸 보고 짜면 "빈 배치도 통지" + "`emitEpochMap`을 언제
     --   `Sync`하는지 불명" 두 실수가 난다.
     function GateNode:_flush(commit: boolean?)
         if next(self._withheld) == nil then return false end  -- (1) 빈 배치 얼리리턴
         local batch = self._withheld
         self._withheld = newWeakK()                           -- (2) 새 테이블. clear가 아니다
         if commit == false then return true end               -- 버리기(H-55) — 전파도 Sync도 안 함
         self.emitEpochMap:Sync(batch)                         -- (3) 전파 **앞**에서 한꺼번에
         emitDownstream(self, batch)                           -- (4) 떼어낸 batch를 페이로드로
         return true
     end
     ```
     반환값이 `emit(commit) -> boolean`의 그 반환값이다 — **"실제로
     내보내거나 버릴 게 있었는가"**(위 2번, `H-55`/`H-86`).
     **⚠️ [정정, 2026-08-24 6라운드 손 트레이싱 `H-9`] 그 새 테이블도 weak여야
     한다.** 여기 원래 `self._withheld = {}`라고 적혀 있었는데, 그러면 위에서
     **weak key로 확정한 집합이 첫 flush 스왑에서 평범한 테이블로 바뀐다** —
     그 뒤로는 그 게이트가 죽은 `Epoch`를 붙잡을 수 있다. `OffWithoutEmit`의
     스왑도 같다. `newWithheld()`(= `setmetatable({}, {__mode = "k"})`) 헬퍼
     하나로 생성 지점을 통일한다.
     하류가 순회하는 것은 `gate._withheld`가 아니라 **받은 `batch`** 다.
     중첩 파동은 새 테이블에 쌓이므로 바깥 전파와 안 섞인다. 같은 리비전이
     중첩으로 두 번 도달하는 경우는 애초에 문제가 아니다 — 하류 맵이 이미
     최신이라 규칙 3으로 삼켜진다.
   - **그래서 게이트는 언제나 자기(와 그 배치)를 출처로 낸다** — 그냥
     통과시킬 때도 상류 출처를 그대로 넘기지 않는다. 사용자: *"후행 노드들은 한개가 지연된거로
     생각이 될 수 있겠지만, 사실 여기서 지연과 비지연을 구분할 이유가
     없습니다."* 하류가 보는 차이는 집합의 원소가 하나냐 여럿이냐뿐이고 판정
     규칙은 완전히 같다.
   - 하류가 **평범한 노드**면 그냥 `EpochMap:Update(batch)`가 집합을 순회하고,
     하나라도 걸리면 **받은 배치를 그대로** 더 아래로 넘긴다
     (`state-epoch-plan.md` §4 — 단일이든 집합이든 같은 규칙이다).
   - **⭐ [2026-08-21 신설] 하류가 또 다른 게이트면 — 받은 집합을 풀어
     자기 `withheld`에 합친다.** 게이트가 게이트 emit을 받는 경우가 정의돼
     있지 않던 구멍이었다(사용자 발견). **출처를 그대로 넘기면 안 된다** —
     상류 게이트가 넘기는 배치는 **그 전파에만 쓰이는 일회성 스냅샷**이라,
     하류 게이트가 그 참조만 들고 유보했다가 나중에 풀면 이미 지나간 배치를
     내보내게 된다. 그래서 수신 시점에 **풀어서 옮겨 담아야** 한다:
     ```
     -- 출처가 Epoch 하나면 그 하나를, 배치면 그 배치 전부를 편다
     for epoch in unfold(from) do
         self._withheld[epoch] = true
     end
     -- 그 다음 평소대로 정책 실행
     ```
     게이트가 몇 겹으로 겹쳐도 각 층이 자기 집합을 들고 있으므로 어느 층이
     먼저 풀리든 정보가 안 샌다.
   - **게이트의 `emitEpochMap`은 수신 때가 아니라 실제로 전파할 때** 갱신한다
     (집합 전체에 대해 한꺼번에, `:Sync(batch)`).
     **⭐ [2026-08-25 명시, 7라운드 `H-89`] `:Sync(batch)`는 전파 *앞*이다** —
     flush 순서는 **빈 배치 얼리리턴 → 스왑 → `:Sync(batch)` → 전파**다.
     지금까지 *"실제로 전파할 때"*라고만 적혀 앞/뒤가 안 정해져 있었다.
     그리고 **수신 시점의 판정에는 `:Peek`을 쓴다** — `:Update`는 덮으므로
     이 예외와 양립하지 않는다(`base/state-epoch-plan.md` §3). **이건 `state-epoch-plan.md`
     §4 의사코드의 유일한 예외이고, 그 문서에 예외로 기록돼 있다.** 그래야 "내가 하류로 던진
     리비전"이라는 맵의 뜻이 게이트에서도 참이 된다 — 유보 중 같은 리비전이
     다른 경로로 또 오면 규칙 2로 걸려 정책을 한 번 더 태우는데, 이미 집합에
     있으므로 무해하다.
   - **⭐ [2026-08-21 `/code-review high`] emit 없이 푸는 경로는 집합을
     *버려야* 한다.** `blocker:OffWithoutEmit()`은 정의상 "밀린 전파를 버리며
     끈다"(`base/blocker-plan.md`)이므로, 그 경로도 **`withheld`를 비운다**
     (전파는 안 하고 새 테이블로 스왑). 안 그러면 `Dispatch.drive`의 배치
     게이팅이 매 프레임 `On()` → … → `OffWithoutEmit()`을 도는 동안 집합이
     **단조 증가**하고, 나중에 아무 `Epoch`나 한 번 통과하는 순간 **버리기로
     했던 옛 원천들이 같이 실려 나가** 하류가 폐기된 통지로 무효화된다.
     - **⭐⭐ [2026-08-25 정정, 7라운드 `H-67`] 여기 근거로 든 용례가
       틀렸다.** `Dispatch.drive`의 배치 게이팅은 `base/blocker-plan.md`가
       *"이 용례는 `state:Apply(blocker)`를 전혀 호출하지 않으므로 gated state도 …
       생기지 않는다"*고 명시한 경로라 **애초에 `withheld` 집합이 없다.**
       결론(비워야 한다)은 그대로 유효하고 **근거가 될 용례만 바꾼다** —
       `state:Apply(b)`로 만든 gated state에 `b:OffWithoutEmit()`을 반복해
       거는 경우, 또는 `Throttle{Trailing = false}`가 창마다 버리는 경우가
       실제로 집합이 단조 증가하는 자리다.
     - **⭐⭐ [2026-08-25] 정책은 이걸 스스로 할 수 없다** — 위 2번의
       `emit(false)`가 그 통로다(`H-55`).
   - 그렇게 비우고 나면 하류의 `emitEpochMap`은 뒤에 남지만, 그 `Epoch`의
     다음 진짜 emit이 규칙 1/2로 걸려 **스스로 낫는다** — 별도 조치 불필요.

   **⭐ 그래서 `setup`의 인자 목록은 안 바뀐다.** 집합을 **채우는** 건 정책이
   아니라 **노드**이고, 노드는 정책이 뭘 하는지 들여다볼 필요조차 없다(위
   단순화). **[2026-08-25 정정]** 다만 집합을 **버리고/읽는** 것은 정책이
   해야 하는 일이었고 통로가 없었다 — 그래서 위 2번의
   `emit(commit: boolean?) -> boolean`이 생겼다. 인자 **목록**은 그대로다.
   정책은 소스를 몰라도 되고, `Throttle`처럼 나중에 타이머에서 `emit()`을
   부르는 경우도 그대로 동작한다 — 그때 쌓여 있던 집합이 그대로 나간다.

### ⭐⭐ `GateNode` 조립 — 필드 목록과 `:_receive`/`:_flush` (2026-08-25 신설)

**새 결정이 아니라 조립이다.** 판정 규칙은 `base/state-epoch-plan.md` §4,
흡수 집합은 위 4번, `emit` 시그니처는 위 2번 — 지금까지 **세 문서에 나뉘어
있어 한 곳에서 순서를 볼 수 없었다.** 구현자가 조립을 잘못할 여지를
없애려고 여기 모은다.

```lua
-- 필드 (ComputeNode와 같은 층위)
-- ⭐ [2026-08-28 확정, 10라운드 `H-152`] 조립의 **첫 줄은 `StateBrand:register(node)`**다.
--   **[2026-08-29 `H-193` 근거 갱신]** 당시 근거(*"`_emitDown`이 `isState(sub)`로 가른다"*,
--   *"State 생성자를 안 지난다"*)는 `H-163`·단위 4 이전 모양 — 지금 `_emitDown`은
--   `sub:_receive(from)` 단일 인터페이스라 등록 여부로 안 가르고, 게이트는 `canExecute`를
--   안 타며(`H-56`), 코드의 `Impl.Gate`는 `newNode({self}, passThrough, GateImpl)`로 만들어
--   `newNode` 첫 줄이 등록한다. 등록이 여전히 필요한 이유는 **소비자가 술어**이기 때문 —
--   `newNode`/`Effect`의 dep 검증과 `isState`(`spec.gate.luau` 1)가 본다.
GateNode = {
    _hold          = { <상류 State/Source> },   -- 하류 → 상류 강참조(`source-state-plan.md`)
    _subs          = <weak-키 구독자 집합>,      -- 원소는 Observer 값 / 자식 State
    valueEpochMap  = EpochMap(),                -- §4 규칙: 값이 낡았는가
    emitEpochMap   = EpochMap(),                -- ⚠️ 수신 때가 아니라 **flush 때** 갱신
    _withheld      = newWeakK(),                -- 흡수 집합 { [Epoch] = true }
    onUpstreamEmit = <정책이 돌려준 클로저>,     -- setup(emit)의 반환값
}

function GateNode:_receive(from)
    -- (1) 판정은 §4 규칙 1~3을 **그대로** 돈다. 단 emit 쪽은 `Peek`이다 —
    --     `Update`는 덮으므로 "유보 중엔 아직 안 던졌다"는 맵의 뜻이 깨진다.
    local valueChanged = self.valueEpochMap:Update(from)
    local emitChanged  = self.emitEpochMap:Peek(from)
    if valueChanged then self:_invalidate() end          -- 캐시 카운터 갱신
    if not (valueChanged or emitChanged) then return end -- 규칙 3: 삼킨다
                                                         -- (정책도 안 돌고 집합에도 안 넣는다)

    -- (2) 통과한 것만 흡수 집합에 합친다. `from`이 집합이면 unfold해서 합친다
    --     — 게이트-게이트 중첩에서 중복이 저절로 접힌다(집합이라서).
    if isEpochSet(from) then   -- (의사 술어 — 실제 코드는 `isEpoch(from)`의 반대 분기,
                               --  `state-epoch-plan.md` §5 "런타임 분기는 `isEpoch`로"; 단위 4)
        for epoch in from do self._withheld[epoch] = true end
    else
        self._withheld[from] = true
    end

    -- (3) 정책에 넘긴다. 정책은 손에 `emit` 하나만 쥐고 있고,
    --     그걸로 flush(`emit()`)도 버리기(`emit(false)`)도 조회(반환값)도 한다.
    self.onUpstreamEmit()
end

function GateNode:_flush(commit: boolean?): boolean   -- 이게 정책이 받는 `emit`
    if next(self._withheld) == nil then return false end  -- (1) 빈 배치면 아무것도 안 함
    local batch = self._withheld
    self._withheld = newWeakK()                           -- (2) 새 테이블. clear가 아니다
    if commit == false then return true end               -- 버리기 — 전파도 Sync도 안 함
    self.emitEpochMap:Sync(batch)                         -- (3) 전파 **앞**에서 한꺼번에
    self:_emitDown(batch)                                 -- (4) 떼어낸 batch가 페이로드
    return true
end
```

- **반환값이 곧 위 2번의 `emit(commit) -> boolean`**이다 — "실제로 내보내거나
  버릴 게 있었는가"(`H-55`/`H-86`).
- **`valueEpochMap`도 있다는 걸 여기서 명시한다** — 지금까지 *"규칙 1~3을
  그대로 돈다"*는 문장에서 추론해야 했다.
- **`_emitDown`은 State와 같은 것**이다(`base/source-state-plan.md`의
  "전파 루프 — 확정 의사코드" 절) — 게이트가 전파 루프를 따로 갖지 않는다.

5. **생명주기.** 게이트 노드가 잡는 자원(타이머/플래그)이 언제 죽는가 —
   지금 설계대로면 다운스트림이 다 죽으면 GC(팩토리는 weak 추적,
   `debounce-throttle-plan.md` 5-4).

   **⭐ [2026-08-24 해소, 6라운드 손 트레이싱 `H-33`/`H-49`] `Gate` 노드엔
   `Flush`/`Cancel` 같은 표면을 두지 않는다 — 정책이 `Blocker`를 조종한다.**
   확정된 `state:Gate(setup)`는 **State 하나만** 돌려주고 노드 객체를 노출하지
   않으므로, 제어 표면을 얹으려면 그 확정을 되돌려야 했다. 사용자 확정으로
   방향이 반대로 잡혔다:

   - **`Blocker`가 자기 정책을 값으로 낸다 — `blocker:Policy(emit) -> onUpstreamEmit`.**
     `state:Apply(b)`는 그 위의 얇은 래퍼가 된다. 노출되는 새 표면은 이 하나뿐이다.
     **⚠️ [2026-08-24 표기 정정, `/code-review high` 지적]** 여기 한때
     `state:Gate(b:Policy)`라고 적었는데 **그건 문법 오류다**(인자 목록 없는
     `b:Policy`). `b.Policy`로 고쳐도 **언바운드 메소드**라 `Gate`가
     `setup(emit)`으로 부르면 `emit`이 `self` 자리에 들어가 정책의 `emit`이
     `nil`이 된다. 정확한 형태는 클로저로 묶는 것이다:
     ```lua
     state:Apply(b)  ==  state:Gate(function(emit) return b:Policy(emit) end)
     ```
   - **`Debounce`/`Throttle`은 보류 판정·`pending` 부기를 직접 구현하지
     않는다 — `Blocker`에 위임한다.**
     > **⚠️ [2026-08-26 정정, 8라운드 `H-118`]** 이 항목은 한때
     > *"`Debounce`/`Throttle`은 `emit`을 아예 안 쥔다"*로 시작했는데
     > **그 문장이 틀렸다.** `setup(emit)`이 곧 계약이므로 **`emit`은 정의상
     > 정책 손에 있고**, 정책은 그걸 `b:Policy(emit)`에 넘겨야 배선이
     > 성립한다. 위임되는 것은 `emit` 자체가 아니라 **"emit된 적 있던가"의
     > 부기**다(사용자 정리: *"emit 을 blocker 가 쥔다는건 정확하게는,
     > 'emit 된 적 있던가?' 를 저장하기 위함 … 그 구현을 나눠 쓰지 않기
     > 위함"*). 그래서 위 2번(`H-55`/`H-86`)이 확정한 **타이머 경로의
     > `emit()`/`emit(false)` 직접 호출과 이 항목은 충돌하지 않는다** —
     > 경로가 둘이고 각각 자기 몫이 있다:
     > | 경로 | 무엇을 부르나 |
     > |---|---|
     > | 상류 emit 도착(동기) | `pass()` — 보류 여부는 Blocker가 판정 |
     > | 타이머/제어 핸들(flush·버리기·조회) | `emit()` / `emit(false)`, 반환값도 씀 |
     >
     > 두 경로가 같은 파동에 겹쳐도 안전하다 — 두 번째 flush는 **빈 배치
     > 얼리리턴**(아래 8번)에 걸려 아무것도 안 한다.

     정책은 자기 `Blocker`를
     사적으로 하나 갖고 **언제 `On()`/`Off()`할지** 정하며, 상류 emit이
     도착하는 경로의 발화/보류 판정은 전부 Blocker에 위임한다. 동기 실행이라
     같은 호출 안에서 정책이
     바꾼 Blocker 상태를 그 다음 줄의 `pass()`가 그대로 본다:
     ```lua
     state:Gate(function(emit)
         local b = Blocker()
         local pass = b:Policy(emit)   -- 실제 emit/보류는 전부 여기 위임
         return function()             -- 상류 emit 도착 (동기)
             -- ...타이머 리셋 / b:On() / b:Off() 시점 판단만...
             pass()
         end
     end)
     ```
   - **Blocker는 설정당 하나가 아니라 적용 핸들당 하나**다(사용자 지적) —
     `Debounce{...}` 커링 결과는 여러 곳에 적용될 수 있으므로 `Apply` 시점에
     생성된다.
   - **`pending` 같은 정책 상태는 `HasBlockedEmit`으로 흡수한다** — "보류된 게
     있는가"를 Blocker가 이미 들고 있으므로 중복 상태를 안 만든다.
     `Trailing = false`는 `OffWithoutEmit()`, `Flush`는 `Off()`로 매핑된다.
   - **정책 합성은 손으로 중첩한다** — `setup`이 곧 `(emit) -> onUpstreamEmit`
     이라 그 자체가 합성 가능한 타입이다. `state:Gate(p1, p2, ...)` 같은
     가변인자 슈가는 **두지 않는다**(누가 상류인지가 코드에 그대로 드러나는
     편이 낫다).
   - **기각된 배선(기록)**: "블로커를 바깥에 중첩"
     (`blocker:Policy(debounceOnEmit)`)은 unblock 시 흘러나온 emit이 디바운스
     창을 **새로 시작**시켜 창이 안 끝난다(사용자 지적).
6. **[2026-08-21 정리 — 열린 항목 아님] 재진입.** 여기 한때 *"`onUpstreamEmit`
   안에서 같은 게이트의 `emit()`을 재귀적으로 부르는 경우"*라고 적혀 있었는데
   **잘못 옮긴 서술이었다**(사용자 지적). `blocker-plan.md`의 "재진입(네스팅)"
   절이 말하는 건 **같은 `Blocker` 인스턴스를 중첩해 `On()`/`Off()` 하는 것**
   이고, 정책이 `emit()`을 호출하는 것과는 무관하다 — 애초에 정책이 flush를
   부르는 건 재귀가 아니라 **평범한 통과 경로**다. 지금 계약은 셋으로 정리된다:
   - **끝나지 않는 되먹임은 UB.** `base/dispatch-core-plan.md`의 2026-08-04
     확정 원칙 그대로 — *"일반적인 재진입/무한루프는 방어 안 함,
     provider/사용자 코드 버그로 간주"*. 게이트가 따로 가드를 두지 않는다.
   - **유한한 재진입은 지원한다.** 전파 도중 소비자가 동기적으로 상류를
     `:Set()`하는 건 이미 대비된 경우이고(`debounce-throttle-plan.md`의
     `onWindowEnd` 주석), 게이트 쪽에서 그걸 안전하게 만드는 장치가 위 4번의
     **flush 진입 시 스왑**이다.
   - **같은 게이트/`Blocker` 인스턴스를 중첩해 쓰지 않는다** — `Blocker`의
     기존 규칙이 그대로 적용된다(겹치는 배치는 새 인스턴스).
7. **[2026-08-21 해소] `Effect(fn, ...deps)`의 최초 1회 억제는 `Gate`
   소비자가 **아니다**.** 한때 이 용례까지 게이트가 커버해야 한다고 적어뒀으나,
   위 8번(빈 배치는 통지 안 함)으로 **성립하지 않는 게 확인됐다** — 설치 구간엔
   어떤 `Set`도 안 일어나 쌓이는 소스가 없으므로 게이트가 내보낼 것 자체가 없다.
   `Effect`가 설치 중 발화를 누르고 마지막에 한 번 직접 실행하면 되고, 새
   메커니즘이 필요 없다(**[2026-08-28 10라운드 `H-150`]** 그 억제 주체는 "자기
   내부 플래그"도 그 뒤의 사적 `Blocker`도 아니라 Effect 핸들 쪽 가드다 — **[2026-08-29
   `H-192` 정정]** 정확히는 `fire`의 `from == nil` 가드가 설치 발화를 거른다(`canExecute`는
   `H-159` 뒤 버리지 않고 홀드하므로 그게 주체였다면 첫 바인드에서 `fn`이 한 번 더 돈다),
   `base/effect-plan.md` 생성자 의사코드). `base/effect-plan.md`의 그
   항목에 달려 있던 "⚠️ `Gate` 설계에 딸려 있다"도 같이 해소됐다. 아래는
   원 서술:
   2026-08-21 5라운드 `C-6`에서 확정된 다중 의존성 `Effect`는, 의존성마다 구독을
   걸면 각 구독의 "등록 즉시 1회 실행"이 N번 발화하므로 **설치 구간 동안 발화를
   눌러뒀다가 마지막에 한 번만 실행**해야 한다(`base/effect-plan.md`의 그 절).
   즉 `Gate`(또는 `Blocker`의 직접 사용)가 **"설치 구간을 감싸 최초 발화를 한
   번으로 접는" 용례까지 커버해야** 한다 — 설계할 때 이 소비자를 같이 볼 것.
8. **[2026-08-21 해소] 소스 없는 emit(빈 배치) — 아무것도 안 한다.**
   `/code-review high`가 "정책이 상류 신호와 무관하게 flush를 부르면 빈 배치가
   나가 하류가 조용히 삼킨다"를 문제로 제기했고, 에이전트는 "빈 배치 = 무조건
   통지"를 권고했다. **사용자 기각**:

   > *"빈 배치면 이미 하류로 한번 다 던져서 더 던질게 없다는 의미입니다. 마치
   > 두번 흘러들어온 같은 카운트의 emit 과 유사한데요. 그건 전파 안 합니다. …
   > 애초에 Gate 는 중간에 emit 을 할 수 있는 핸들을 노출하는, `Source:Emit`
   > 같은걸 주는 요소도 아니고, 쌓아두다 뒤로 넘기는건데, 쌓아둔것 자체가
   > 없는데 뒤로 넘긴다는건 이상합니다."*

   **확정: `next(withheld) == nil`이면 통지 자체를 안 한다.** 그래야 다른
   State와 동작이 같아진다 — 빈 배치를 흘리는 건 표면적으로 **State 중간에
   `Source:Emit`을 추가하는 격**이고, `Gate`는 그런 요소가 아니다.
   - **새 규칙이 아니라 기존 계약의 일반화다.** `base/blocker-plan.md`는 이미
     *"이미 `HasBlockedEmit`이 false면 `emit` 값과 무관하게 아무 것도 안 함
     (idempotent)"*이라고 확정해뒀다 — 즉 `HasBlockedEmit`은
     `next(withheld) ~= nil`의 특수형이다. `Debounce`/`Throttle`도
     `if pending`일 때만 `passThrough()`를 부른다
     (`base/debounce-throttle-plan.md`의 `onWindowEnd`).
   - **3번 항목의 "`emit`은 언제든 부를 수 있다"는 그대로 유효하다** — 언제
     불러도 되지만, 쌓인 게 없으면 그 호출은 no-op이라는 뜻으로 읽는다.
   - **따름정리: `Effect(fn, ...deps)`의 설치 구간 억제는 `Gate` 소비자가
     아니다** — 아래 7번 참고.

9. **마일스톤 범위 — [2026-08-24 재확정] `Gate`와 `Blocker` 둘 다 M2(반응형
   코어)다.** `Dispatch.drive`의 배치 등록이 실제로 쓰는 건
   `blocker:On()`/`OffWithoutEmit()`/`IsOn()`이므로(배치 게이팅 절) 최소한
   그 세 메서드가 도는 형태까지는 M3(디스패치)가 요구한다. 2026-08-22엔
   그래서 `EpochMap.luau`/`GateNode`/`Blocker.luau` 체크박스를 디스패치
   쪽으로 **앞당겼는데**, 셋 다 State 위에 얹히는 이상 그걸로는 순환이 안
   닫혔다 — 디스패치가 여전히 `Source.luau`/`State.luau`를 필요로 했다.
   **2026-08-24에 마일스톤 순서 자체를 교체**(반응형이 M2, 디스패치가 M3)해
   그 앞당김은 되돌려졌고, 셋은 반응형 쪽으로 복귀했다. 결과적으로
   "게이팅 먼저"는 그대로 지켜진다 — 게이팅이 디스패치보다 먼저 지어진다.
   `Blocker`는 `GateNode`를 다시 만들지 말고 그 위의 정책으로 얹을 것.

## 계약 — 게이트는 emit 경로만 미룬다 (2026-08-28 확정, 10라운드 `H-151`)

게이트가 하는 일은 **다운스트림 통지의 유보**뿐이고, 값은 안 가린다
(`base/debounce-throttle-plan.md` 4절이 확정한 (A) emit-gate). 그래서 통지가 emit이 아닌 경로로 오면 게이트를 **거치지 않는다**(**[같은 날 `H-159`]** 그 캐치업의 메커니즘은 `_epochs:Refresh()`가 아니라 `rawRerun`이 세우는 `_rerunRequired` 홀드 플래그 — `base/effect-plan.md`. 재구독 시 소진돼 있었으면(`_consumeCleanup`이 플래그를 세운다) 게이트 상태와 무관하게 재설치로 한 번 돌고, 유보분은 flush 때 `Update`로 또 한 번 — 둘 다 정상):
- **`Effect`의 재바인드/재구독 캐치업** — 소진된 핸들이 다시 묶이면 초기 설치와
  같은 뜻으로 `fn`이 돈다(`base/effect-plan.md` `_bindDestroying`). 유보 중이어도
  돈다.
- **게이트 없는 형제 dep** — `Effect(fn, gated, plain)`에서 `plain`이 깨우면 `fn`
  안의 `gated:Get()`은 최신값이다.
- 유보됐던 emit이 나중에 풀려 들어오면 그냥 재실행 — 생성 직후 유보분이 들어오는
  것과 같은 경로. `Effect`의 `_epochs`는 emit을 받을 때만 갱신된다(Observer·중간
  State와 같다).

**사용자 원문**: *"block 은 단지 유보만 해줄뿐이라서. - Effect 도 observer 랑
똑같게, 중간 state 랑 똑같게, emit 받을때에만 epoch 맵을 업데이트 하면 돼. 계약
추가로 끝나는 일로 보여"*. 막는 갈래(캐치업이 dep 노드의 `emitEpochMap`을 보게
하기 / value-hold 재개방)는 둘 다 기각 — 전자는 `EpochMap` 계약 변경, 후자는
`base/debounce-throttle-plan.md` 4절이 철회한 (B). 발견 원문은 `qa-request/pre-implementation-handtrace-round10.md` `H-151`.

## 관련 문서

- `base/blocker-plan.md` — 현행 `Blocker` 확정(이 문서가 일반화하려는 대상).
- `base/debounce-throttle-plan.md` — "공개 `Blocker` API 위엔 못 얹음" 절이
  `Gate` 일반화를 처음 권고한 자리, 그리고 정책 쪽 설계 전량.
- `base/dispatch-core-plan.md` — "배치 등록을 안전하게 만드는 Blocker 게이팅"
  절이 M3가 실제로 요구하는 표면.
- `ROADMAP.md` M2/M3.
