# 라이프사이클 패턴 — rbvm의 `Connected` + GC 관용구 채택

**상태**: 결정됨(base) — quad-v2가 채택할 라이프사이클/정리(`retract`) 전략의 원본.
완료 개념 없음, 구현하면서 세부 조정 있을 수 있음.

**참고(2026-08-06)**: rbvm은 사용자가 직접 실행해 실제로 잘 동작하는 것을 확인한
코드베이스(프로덕션에서 검증됨) — 사람이 짠 코드라 무결성이 100% 보장되는 건
아니지만(실제로 아래 5번 항목에서 `Connected` 체크 방향 반전 버그, `__mode` 오타
버그가 발견됨), 다른 리서치 참고 레포보다 "실물로 돌아간다"는 근거가 확실한
비교 대상. 단 이건 참고용 비교 대상일 뿐 quad-v2가 반드시 따라야 할 규범은
아님 — 실제 채택 여부는 이 문서 각 절의 확정 내용(특히 아래 "확정" 두 절)을
따를 것, rbvm 코드를 그대로 베끼라는 뜻이 아님.

## 배경

`raw-userinput.md`(이하 사용자 원 메모): "레지스터의 실행은 내 생각엔 그냥 Destroy
되었는지를 라이프타임 홀더의 Connected 상태로 보는게 맞는듯", "여전히 connection
으로 해키한 방법 쓸듯. destroying으로 자료구조 계속 바꿔가는거 비용 큼. gc 네이티브
에 맡겨야함. 대신 이젠 Connected 필드로 이 연결이 살아 있는지 보고 설정 가능함.
이게 rbvm 쪽에서 구현되어있음."

rbvm(`.claude/initreq/rbvm/`)을 조사한 결과, 정확히 이 패턴이 존재함. 아래는
그 조사 결과 요약(전체는 이 문서 작성에 쓰인 리서치 세션 참고, 소스는
`.claude/initreq/rbvm/src/signal.luau`, `src/proxy/base.luau`, `src/namespace.luau`).

## 채택할 패턴

### 1. `Connected`는 저장되는 bool이 아니라 계산된 속성

rbvm의 `Connection` 타입(`signal.luau:21-24`)은 `Connected`를 실제 필드로 두지 않고
`__index` 메타메소드에서 계산함:

```luau
function ConnectionMeta.__index(self: Connection, key: string): any
    if key == "Connected" then
        local data = Connection.GetPrivate(self)
        return data.Signal ~= nil
    end
end
```

연결 해제 시 `data.Signal = nil`만 하면 됨(`Connection.Dispose`) — 자료구조를
바로 지우거나 재구성하지 않음.

> **⚠️ [전면 정정, 2026-08-20 구현 전 QA 4라운드 `LP-1`] quad는 이 rbvm 코드를
> 채택하지 않는다 — quad에서 `Connected`는 "계산된 속성"이 아니라 그냥 Roblox
> `RBXScriptConnection`의 네이티브 필드다.** 옛 서술("quad-v2도 이 모양을 그대로
> 채택: 라이프타임 홀더는 '내가 아직 살아있게 하는 뒷받침 참조'가 nil인지만
> 확인하면 됨")은 rbvm의 프록시 계층 사정을 quad에 잘못 옮긴 것이었다. 사용자
> 판정: *"Connected 는 단순히 RBXScriptConnect 안의 속성이고, Destroy 수행 시
> 모든 커넥션이 죽으니 자연스럽게 Connected 가 false 이 되는것 뿐임. nil로
> 참조를 만들 이유도 없음."*
>
> **quad의 실제 판정은 두 상태뿐**(`isBoundAlive`, 아래 "(1)" 코드 블록):
> 1. **gcconn 자체가 없음** — 아직 바인드 안 됐거나, 이미 GC돼서 weak 릴레이션
>    항목이 비워진 상태. `BindData:GetWeak(value, "gcconn")`이 `nil`.
> 2. **gcconn은 있는데 `.Connected == false`** — `inst`가 방금 Destroy됐고
>    아직 GC는 안 된 구간. 엔진이 Destroy 시점에 모든 커넥션을 끊어주므로
>    quad가 아무것도 안 해도 이 값이 저절로 뒤집힌다.
>
> **quad가 `Signal = nil`처럼 직접 참조를 끊는 자리는 없다** — 유일하게 "직접
> 끊는" 동작인 `unbindLifetime`도 `gchold[value] = nil`과 `BindData` 항목 제거일
> 뿐 커넥션 자체를 만지지 않는다. rbvm에서 실제로 가져오는 건 **"gcconn 트릭으로
> Instance 수명에 값을 매단다"는 관용구 하나**이고, `Connected`를 계산 속성으로
> 만드는 구현은 가져오지 않는다.

rbvm에서 실제로 재사용하는 부분은 아래 "(0)"/"(1)" 절의 gcconn/gchold
관용구이고, 위 `__index` 계산 속성 코드는 **참고용 원본 인용**으로만 남긴다.

### 2. Instance 파괴는 `Instance.Destroying` 훅 하나로만 관측

> **⚠️ [2026-09-02 실측, M5 단위 ① `H-291`] `Destroying` 콜백은 동기가
> 아닐 수 있다** — Deferred 시그널 동작(신형 플레이스 기본값)에서
> `Destroying`·`GetPropertyChangedSignal` 콜백은 Destroy와 같은 줄기가
> 아니라 **다음 재개 지점에 지연 배달**된다(Destroy가 연결을 끊어도 큐잉된
> 발화는 정확히 1회 돎 — Studio 실측). **`gcconn.Connected` 전환은
> 동기**라 `canBound`/`canExecute` 판정은 무영향이고, 영향 범위는 시그널
> 배달에 기대는 소비자뿐 — `onDestroying` → `Effect` cleanup은 "죽음과
> 같은 줄기"가 아니라 "죽음 직후 지연"일 수 있으니 동기 실행에 기대는
> 설계를 하지 말 것. 설정은 플레이스별(Immediate/Deferred)이라 quad는
> 양쪽 모두에서 정확해야 한다. 소스는
> `qa-request/m5-implementation-round14.md` `H-291` 행.

rbvm은 실제 Roblox Instance의 파괴를 감지하는 지점을 단 하나로 좁혀둠 —
`inst.Destroying:Connect(...)` (`proxy/base.luau:150-156`), `Destroyed` 같은
플래그를 그 콜백에서만 true로 뒤집음. `AncestryChanged`나 폴링 방식은 안 씀.
quad-v2도 동일: 인스턴스 라이프사이클 훅 지점은 `Destroying` 하나로 통일.

**[구체화, 2026-08-20 구현 전 QA 4라운드 `LP-2`] "예상보다 적을 수 있다"가 아니라
지금은 정확히 한 곳뿐이다 — `Effect`.** 아래 "2026-08-04 검증 라운드에서 보강된
내용" 절이 "이 훅을 쓰는 지점이 예상보다 적을 수 있다"고만 열어뒀던 걸 사용자가
확정해줌(*"당장은 Effect 뿐임"*). `Effect`의 leaf-death cleanup(`base/effect-plan.md`)이
이 훅을 쓰는 유일한 소비자이고, 그 위의 슈가 `OnDestroyed`(`base/lifecycle-hooks-plan.md`)도
결국 같은 경로다. 나머지(Observer 게이팅, Tag/Attribute 정리, Tween 취소)는 전부
gcconn `Connected` 판정이나 엔진 자체 정리로 커버되어 이 훅을 안 씀.

### 3. 정리(`retract`)는 기본적으로 GC에 위임, 예외적으로만 즉시(eager)

rbvm 전역에 약한 테이블(weak table, `__mode = "k"/"v"/"kv"`)로 private 데이터를
저장 — 홀더 객체를 아무도 안 들고 있으면 그 private 레코드도 자동으로 사라짐.
즉시 처리하는 예외는 딱 두 가지뿐이었음: (a) 가상 트리의 부모/자식 포인터처럼
방치하면 죽은 참조를 계속 순회하게 되는 "작고 유계(bounded)"인 것, (b) 네임스페이스
전체가 통째로 죽을 때의 순서 있는 dispose 훅. **quad-v2 원칙: 기본은 GC 위임,
즉시 정리는 "안 끊으면 죽은 참조를 순회하게 되는 작은 포인터"류에만 국한.**

### 4. (참고 기록) rbvm의 Signal 자체는 재사용 가능한 범용 emitter였음 — 실제로는 채택 안 함

`signal.luau`의 `Signal`/`Connection` 클래스는 rbvm 프록시 시스템에 의존하지
않는 범용 이벤트 emitter임 (`Connect`/`Once`/`Wait`/`Fire`/`Destroy`,
`IsInited`/`OnInit`/`OnUninit` 지연 활성화 훅 포함). 사용자 원 메모에는
"시그널 자체 구현은 아닌듯... 콜백 정도로도 충분"이라는 언급이 있어 한때
이 문서 초안 단계에서 상충하는 것처럼 보였으나, **이 질문은 2026-08-04
검증 라운드에서 최종 확정으로 재확인됨 — 더 이상 열린 질문 아님**
(`base/architecture.md` 11번 항목도 동일하게 명시). 결론은 아래 "확정: Signal
클래스는 안 만든다" 절 참고 — 커스텀 `Signal`/`Connection` 클래스는 만들지
않고, 콜백 + `Connected` 계산 속성만 채택한다.

### 5. rbvm에서 그대로 가져오면 안 되는 것 (버그 발견됨)

- `proxy/base.luau:72-78`의 `Proxy.DisposeNamespace`와 `signal.luau:401-408`의
  `SignalProxy.DisposeNamespace`가 `Connected` 체크 방향이 서로 뒤집혀 있음
  (하나는 "아직 연결되어 있으면 continue", 다른 하나는 정반대) — 후자가 맞는
  방향(`not Connected`일 때만 skip, 살아있으면 Disconnect). quad-v2 구현 시
  이 반전 버그를 복사하지 않도록 주의.
- `namespace.luau:5-6`의 `ItemNamespaceMap`은 `__mod = "k"`로 오타가 나 있어서
  실제로는 weak table이 아님(`__mode`가 맞음) — 그대로 베끼면 메모리 누수.
- `InitNamespace`/`Registered`-가드/`NewLib` 3종 세트로 "라이브러리마다 하나하나
  수동 init" 하는 방식은 정확히 사용자가 피하고 싶다고 한 패턴 — 순서 있는
  dispose-hook 리스트 자체는 재사용해도, 수동 init 관례는 그대로 베끼지 말 것
  (팩토리 함수로 대체 — `base/module-lifecycle-plan.md` 참고).

## 확정: Signal 클래스는 안 만든다

**사용자 확인 완료** — 콜백 + `Connected` 계산 속성만으로 간다. rbvm의 범용
`Signal`/`Connection` 클래스 전체는 가져오지 않음. rbvm에서 채용하는 건 오직
"`Connected`가 계산된 속성" 이라는 패턴 자체뿐.

## 확정: quad는 자신이 만든 Instance의 라이프사이클 "중간"에 있지 않다

이게 이 문서 전체의 핵심을 재정의하는 결정. rbvm의 proxy는 Instance와 소비자
사이에 자신을 끼워넣는(중간 계층) 설계라 "내가 사라질 때 무언가를 정리해야
하는가"라는 문제가 생기지만, **quad는 자신이 만든 Instance를 그 Instance의
생명주기 끝까지 그대로 들고 있는 소유자다 — 중간에 끼는 계층이 없음.**

결론: **Instance/바인드 전체가 Destroy될 때 실행해야 하는 정리(teardown) 로직은
없다.** 오히려 있으면 안 됨 — Destroy 이후에 그 Instance에 프로퍼티를 셋하거나
메서드를 호출하면(예: 이미 죽은 Tween에 `:Cancel()`) 그냥 에러남. 대상이
Destroy되면 그 대상에 묶인 것들(Tween 등)도 자연히 죽은 상태가 됨 — GTK 등
다른 백엔드도 마찬가지로 "run된 dispose를 관리"할 필요가 없는 구조로 봄.
**해야 할 일은 딱 하나: 생명주기가 끝난 뒤에 그 대상을 다시 건드리는 시도가
일어나지 않게 막는 것**(=처리를 그냥 멈춤) 뿐 — 자료구조 자체의 해제는
가능하면 GC에 맡김.

이 원칙 때문에 "값 교체 시 이전 처리를 무르는 것"(아래 `retract`)과 "완전
소멸 시 정리"는 **하나로 통일** — 후자는 애초에 안 만듦. `base/tween-plan.md`
와 `base/slot-plan.md`가 쓰던 용어 `cleanup` 표기는 대부분 `retract`로
갱신됨(이름 변경 근거는 아래) — 잔여 표기 확인은 진행 중, 해당 문서들은
각자 별도로 정리될 예정.

## 함수 안에서 만든 옵저버도 GC 대상이 되어야 함 — 범용 "생명 바인드 유틸" 필요

사용자 원 메모: "함수 안에서 옵저버 만들어버린 거, 그것도 gc 대상 되어야
할 텐데, 이건 아래쪽에 생성하는 실 객체에 유저가 바인드 할 수 있게 하는 약간의
유틸이 있긴 해야 할듯. connect 트릭 그대로 들고 와서 쓰면 될 것 같고. 옵저버는
canExecute 같은 람다 함수 하나 달게 해서 Connected 상태 보게 하여 실행 안 될
수 있게 만들어도 될 듯."

즉, 핸들러가 처리 도중 만든 구독/옵저버 클로저는 그 자체로는 아무것도 자동으로
GC에 묶이지 않음 — v1이 여기저기서 `PropertyChangedSignal`에 연결해 참조를
붙잡아두던 "GC 방지 핫팩"(`reference/quad-v1-architecture.md` 참고)과 같은 문제.
**base가 범용 유틸로 제공할 것: 임의의 클로저/구독을 실제 Roblox 객체의
생명주기에 바인드하는 도구** — 내부적으로 v1/rbvm이 쓰던 "connect 트릭"(어떤
신호에든 연결해서 참조를 죽을 때까지만 붙잡아두는 것)을 그대로 재사용. 이
도구로 바인드된 옵저버는 `canExecute` predicate로 게이팅되어, 살아있지 않으면
실행 자체를 건너뛸 수 있음(죽은 대상에 대한 처리 시도 방지, 위 원칙과 직결).

### `bindLifetime`/`canBound`/`canExecute`/`unbindLifetime` — 확정(2026-08-08 세션,
`unbindLifetime`은 2026-08-09 세션 추가, **시그니처는 2026-08-14 다섯
번째 세션에 `value` 단독으로 최종 정정**, **`canBound`는 2026-08-14 열한
번째 세션에 별도 진입점으로 재도입** — 아래 "(3)" 절)

> **[정정, 2026-08-18 구현 전 QA]** `canBound`의 **판정 방향이 뒤집혀
> 있었다** — 이름 그대로 "지금 묶을 수 있는가"(참 = 아직 안 묶여 있어서
> 묶어도 됨)여야 하는데, 문서 전체가 참 = "이미 묶여 있음"으로 쓰고
> 게이트를 `if canBound(v) then error(...)`로 적어뒀었다. 그대로 구현하면
> **정상적인 첫 바인드가 전부 에러나고 이중 바인드는 무사통과**한다.
> 아래 (1)~(3) 절은 전부 정정된 방향(`canBound(v) == not isBoundAlive(v)`,
> 게이트는 `if not canBound(v) then error(...)`)으로 다시 쓰여 있다.
> 사용자 판정 원문과 파급 목록은
> `.claude/qa-request/pre-implementation-qa-round1.md`의 `S-1`.

**탑레벨 평범한 함수로 확정, 네임스페이스에 안 숨김.** `Dispatch.process`/
`Handler.xxx`는 "시스템 내부 배관"이라 네임스페이스가 맞지만, `bindLifetime`/
`canBound`/`canExecute`/`unbindLifetime`는 `isState`/`isObserver`처럼
핸들러 작성자가 직접 호출하는 **1급 프리미티브 연산**이라
`LifetimeHandle.bind(...)`류로 감싸면 안 됨 — `LifetimeHandle.luau` 파일
안에 있어도 되지만 export는 평평한 함수. **[2026-08-28 정정, M2 첫 단위]
"평평한"은 모듈 인스턴스의 필드라는 뜻이다** — `quad.bindLifetime(inst, v)`처럼
`isState`와 같은 자리에 놓이는 것이고, 파일 `LifetimeHandle.luau` 자신이 이
넷을 return하는 게 아니다(파일은 `InitLifetimeHandle(module)`을 return하고, 그
팩토리가 `module.bindLifetime = …` 에러 스텁 4종을 심는다 — 백엔드가 같은 필드를
덮어쓴다, 아래 "`Connected` 체크는 rbvm 패턴을 그대로 베끼는 게 아니라" 절.
**[2026-09-01 명시]** 실코드 `LifetimeHandle.luau`는 생명주기 넷에 더해
엔진 op **`onDestroying` 스텁도 같이** 심는다 — 같은 백엔드가 채우는
주입이라서(그 파일 주석이 소스). 백엔드가 덮어쓸 필드는 총 다섯).
아래 시그니처의 이름은 그 필드 이름이다. **⭐ [2026-08-28 `H-174`, 사용자 확정]
반응형 모듈(`Source`/`State`/`Observer`/`Effect`…)은 이 넷을 `module.canExecute(self)`처럼
모듈 인스턴스에서 발화 시점에 늦게 읽는다** — 조립은 `InitXxx(module)` 팩토리가
`module`을 클로저로 쥐는 형태(`base/module-lifecycle-plan.md` "New()의 내부 구성")이고,
`Init` 시점에 `local canExecute = module.canExecute`로 캡처하면 백엔드가 `New()` 뒤에
덮어쓰기 전의 **스텁을 영원히 잡는다**. 이 문서와 `source-state-plan.md`/`effect-plan.md`
의사코드의 `canExecute(self)`/`canBound(self)`는 전부 그렇게 읽을 것(사용자: *"module.canExecute
로 lazy 하게 읽으면 되는거 아냐?"*).

```lua
bindLifetime(inst: any, value: any): ()   -- inst가 필요한 건 이것 하나뿐
unbindLifetime(value: any): ()
canBound(value: any): boolean     -- "지금 묶어도 되는가" — 참이면 아직 안 묶여 있음(구조적 점유 없음)
canExecute(value: any): boolean   -- "지금 발화해도 되는가" — emit 전파 게이팅
```

**[정정, 2026-08-14 다섯 번째 세션] `unbindLifetime`/`canExecute`는 `inst`를
안 받는다 — 옛 2-인자 시그니처(`(inst, value)`)는 오염이었음.** 역전 원문과
오염 경로 추적은 `archive/canexecute-inst-arg-reversed.md`. 요지: **"이 값이
지금 실행돼도 되는가"는 `value` 자신에게 물어야 하는 질문**이고, 실제로 물을
수 있다 — `bindLifetime`이 바인딩 시점에 `inst`의 gcconn 참조를 `value` 쪽
릴레이션으로 복사해두기 때문(아래 구현). `inst`가 필요한 건 "어느 홀더에
넣을 것인가"를 정해야 하는 `bindLifetime` 하나뿐.

이게 **구조적으로 중요한 이유**: `canExecute`의 실제 호출부는 State 전파
루프(`emit`)다 — 그 자리엔 `inst`가 없고 있어서도 안 됨(State는 자기가 어느
Instance에 걸렸는지 모르는 게 정상, 애초에 여러 곳에 걸릴 수 있음). 2-인자
시그니처는 그 호출부에서 **호출 자체가 불가능**했고, 그래서 지금까지 어느
문서에도 `canExecute`의 실제 호출부가 코드로 등장한 적이 없었음(서술만 있고
코드가 없던 이유가 이것). 1-인자로 돌아오면서 호출부가 자연스럽게 성립함
(아래 "실제 호출부" 절).

**`unbindLifetime` 추가 이유(2026-08-09 세션, `dispatch-core-plan.md`의
"Length/Offset" 논의에서 파생)**: `Dispatch.setLength`(같은 위치에 새
`State<number>`가 들어오면 이전 것에 걸어둔 Observer를 먼저 정리해야 함,
`State<Slot>` 교체가 대표 사례)처럼 **`inst` 전체 생명주기보다 먼저,
특정 값 하나만 콜백/구독을 끊어야 하는 경우**가 실제로 생김 —
`bindLifetime`만 있으면 그 호출부가 gchold의 내부 저장 구조(배열이든
`value`를 키로 쓰는 테이블이든)를 직접 알아야만 특정 항목을 지울 수
있어서 캡슐화가 깨짐. `unbindLifetime(value)`을 짝으로 추가하면
호출부는 내부 구조를 몰라도 됨 — 구현이 쉬운 이유도 여기 있음(아래
스케치처럼 gchold를 `value`를 키로 쓰는 테이블로 두면 `gchold[value] =
nil` 한 줄). 안 걸려있던 값에 불러도 안전한 no-op(`:Unsubscribe()`류
기존 관례와 동일).

**`unbindLifetime`이 `inst`를 안 받는 것의 실질 이득(2026-08-14 세 번째
세션)**: 호출부가 "이 값을 *어느* inst에 걸었더라"를 기억할 필요가 없어짐 —
`base/slot-plan.md`가 `unbindLifetime(slot._mountedInst, observer)`처럼
`_mountedInst`를 되짚어 넘기던 자리가 전부 `unbindLifetime(observer)`로
줄고, 그 과정에서 "`_mountedInst`가 이미 갈아치워졌거나 `nil`이면 해제가
조용히 빗나간다"는 잠재 버그 클래스가 원천 소멸함(값 자신이 자기 홀더를
알고 있으므로 빗나갈 대상이 없음).

base는 이 두 함수의 **인터페이스만**(타입 시그니처) 갖고, quad-roblox가
`BaseModule` 뮤테이션 시점에 실 구현을 채워넣는다는 원칙은 그대로(`canExecute`
관련 기존 절 참고) — 아래는 그 실 구현 스케치, `base/relate-plan.md`의
`Relate` 프리미티브 위에 얹힘(2026-08-08 세션, gchold를 `perInstanceState`
직접 조작 대신 `Relate`로 구현).

#### (0) gcconn/gchold는 **Instance 생성 시점**에 만든다 — `bindLifetime`이 아니라

**[2026-08-14 다섯 번째 세션 확정, 옛 lazy 생성에서 전환]** 예전 스케치는
`bindLifetime` 첫 호출에서 gcconn을 lazy 생성했는데, 이건 **`inst`를 키로
쓰는 모든 `Relate`의 전제를 깨는 구멍**이었음:

Roblox의 `Instance` 값은 엔진 객체 자체가 아니라 **엔진 객체를 가리키는
userdata 포인터**다. Lua 쪽에서 아무도 참조를 안 들고 있으면 그 userdata는
회수될 수 있고, 나중에 같은 엔진 객체를 `.Parent`/`:GetChildren()` 등으로
다시 얻으면 **다른 userdata**가 나올 수 있음 — 그러면 이전 userdata를 키로
저장해둔 `Relate` 항목 전체가 조용히 미아가 됨(`elementOwner`,
`nameClaims`, Tag 참조카운트 등 `inst`-키 릴레이션 전부 해당). 따라서 quad는
**자기가 만든 Instance마다 생성 즉시 Lua 쪽 강참조를 하나 심어** 바인딩이
살아있는 동안 userdata 동일성을 고정한다:

**[2026-08-28 `Claim` §7-9]** 아래 코드는 주입 op **`nativeClaim(inst)`**의 본체다 —
`New`의 ②단계와 `Claim`(이미 있는 트리를 소유할 때, `base/claim-plan.md`)이 같은
op를 부른다. quad가 소유하는 Instance마다 정확히 한 번.

```lua
-- quad-roblox: nativeClaim(inst) — Instance를 만든 직후 / claim 직후 무조건 실행
local nop = false or function(...) end -- local이라 상수 접힘/인라인 안 됨

local gchold = {}                       -- 이 inst에 매달린 값들의 강참조 홀더
local gcconn = inst:GetPropertyChangedSignal("ClassName"):Connect(function()
    nop(gchold, inst) -- 절대 발화 안 함. 클로저가 gchold와 inst를 업밸류로 붙잡는 게 전부
end)
gchold[1] = gcconn                      -- 배열 자리 1번은 gcconn 전용(값들은 해시 자리에)

InstData:SetWeak(inst, "gchold", gchold)
InstData:SetWeak(inst, "gcconn", gcconn)
```

- **`ClassName`은 절대 안 바뀌는 프로퍼티라 이 신호는 절대 발화하지 않음**
  (rbvm 패턴 그대로) — 2026-08-13 부분 실측 확인(미발화 + Destroy 시
  `Connected` 즉시 전환), `audit/gcconn-trick-verification.md`.
- **클로저가 `inst`까지 캡처하는 게 이번 변경의 핵심** — 예전 스케치는
  `gchold`만 캡처했음. `inst`를 캡처해야 위 userdata 동일성이 보장됨.
- **`InstData`는 `SetWeak`** — gchold/gcconn은 이미 위 클로저↔`gchold[1]`
  상호 참조로 안전하게 살아있으므로, 릴레이션은 약하게만 잡으면 됨.
  **"다른 곳에서 안전하게 유지되는 것은 항상 weak로 잡는다"**가 일반
  규칙(강참조를 중복으로 걸면 실제 수명이 어디서 끝나는지가 흐려져 GC
  버그를 만들기 쉬움) — `base/relate-plan.md`의 상호 순환 경고와 같은 결.
- **대가: quad가 만든 Instance는 참조를 놓는 것만으로는 회수되지 않고
  반드시 `Destroy`로 회수된다.** 클로저가 `inst`를 잡고, 그 클로저를
  `inst` 자신의 시그널이 잡는 순환이라 Destroy(=엔진이 커넥션을 끊음)가
  유일한 절단면. **실질적으로 새로 생긴 제약은 아님** — 실제 바인딩이
  하나라도 걸리면 그 Observer 클로저가 어차피 `inst`를 캡처해 같은 순환이
  생기므로(예: `dispatch-core-plan.md`의 `StoreBind.process`), 이번
  변경은 "아무것도 안 걸린 Instance"까지 같은 규칙으로 통일한 것뿐.

#### (0.5) `bindLifetime`의 확장 계약 — 모르는 타입이면 순수 GC 릴레이션 (2026-08-31, `H-229` 사용자 확정)

**`bindLifetime(inst, value)`는 `value`가 어떤 알려진 타입과도 일치하지
않으면(평범한 테이블/클로저) 단순히 GC 릴레이션만 한다** — gchold 강참조 +
gcconn 참조 복사, 타입별 후처리(`Observer:_catchUp`/`Effect:_bindDestroying`)
없음. 사용자 원문: *"bindLifetime이 할 일 같은데, 아무 타입과도 일치하지
않으면 단순히 GC 릴레이션만 해주는 건 어때?"* — 새 동작이 아니라 기존
구현(mock·(1)의 스케치)이 이미 그렇게 돌던 것을 **공개 계약으로 승격**한
것이다. 첫 소비자는 `Dispatch`의 체인 리스트 앵커(`H-229` —
`dispatch-core-plan.md`의 "Dispatch 체인" 절): "이 값의 수명을 inst의 바인드
수명에 묶는다"는 원래 일과 같은 일이라 별도 앵커 표면을 만들지 않는다
(표면이 커지는 대안을 사용자가 명시적으로 피함).

#### (1) `bindLifetime` / `unbindLifetime` / `canBound` / `canExecute`

```lua
-- quad-roblox 실 구현 스케치. [2026-08-28] 아래 `function bindLifetime(...)` 등은
-- 읽기 편하게 평범한 함수로 적었지만, 실제로는 InitLifetimeHandle이 심어둔
-- 모듈 인스턴스 필드(module.bindLifetime 등)에 최종 대입되는 본체다 — 위
-- "탑레벨 평범한 함수로 확정" 절의 정정 참고. mock 백엔드(test/mock.luau의
-- installLifetime)가 이 스케치를 그 모양으로 옮긴 실물이다.
local InstData = Relate() -- inst  -> gchold/gcconn (위 (0)에서 채워짐)
local BindData = Relate() -- value -> gchold/gcconn (bindLifetime이 채움)

-- 비공개(export 안 함) — canBound/canExecute가 공유하는 실제 판정.
-- "이 값이 구조적으로 이미 살아있는 바인딩을 갖고 있는가" 하나만 답한다.
-- 두 공개 진입점은 이걸 서로 반대 방향으로 감싼다(아래 "(3)" 절).
local function isBoundAlive(value)
    -- (a) inst-scoped 경로: bindLifetime이 복사해둔 gcconn을 value 자신에게서 찾음.
    --     inst가 Destroy되면 Connected가 즉시 false, 이후 GC가 항목까지 치움
    --     (gchold가 죽으면 gcconn을 강참조하는 게 없어지므로 weak 항목이 스스로 비워짐).
    local gcconn = BindData:GetWeak(value, "gcconn")
    if gcconn ~= nil and gcconn.Connected then
        return true
    end
    -- (b) 전역 경로: 구독 경로(강/약)가 세운 것. Observer/Effect에만 있는 필드.
    --     [2026-08-26, 8라운드 H-111] :WeakSubscribe()도 이 필드를 세운다 —
    --     갈라지는 건 레지스트리를 강하게 잡느냐뿐이다. 한때 ":Subscribe()가
    --     세운 것"이라고만 적혀 있었고, 그대로 읽으면 WeakSubscribe로만
    --     등록되는 Effect의 내부 Observer가 이 게이트를 영영 못 통과해
    --     Effect의 State dep 전량이 조용히 침묵한다.
    if isObserver(value) or isEffect(value) then
        return value.Subscribed == true
    end
    return false
end

function bindLifetime(inst, value)
    -- 이중 바인딩 금지(base/source-state-plan.md) — 게이트는 canBound.
    -- "지금 묶어도 되는가"를 묻는 자리이지 "지금 발화해도 되는가"를 묻는
    -- 자리가 아님(둘의 구분은 아래 "(3)" 절 참고). 못 묶는 경우만 에러.
    if not canBound(value) then
        -- 어느 경로로 묶여있는지만 메시지에 실어줌. `.Subscribed`를 무조건
        -- 인덱싱하면 안 됨 — 게이트는 값 타입을 안 가려서 value가 평범한
        -- 클로저일 수도 있음(그 경우 필드 접근 자체가 에러).
        local isGlobal = isObserver(value) or isEffect(value)
        if isGlobal then isGlobal = value.Subscribed == true end
        -- [2026-08-31 M3 단위 4 `H-272`] 리터럴 error(level 2)가 아니라 워커의
        -- 최외곽 스캔 — 단위 4 이후 bindLifetime의 주 호출부가 디스패치 깊이
        -- (Leaf.process)라 level 2는 quad 내부를 blame한다. errorBefore면 직접
        -- 호출(최외곽 태그 = bindLifetime 자신)과 디스패치 경유(최외곽 = drive)
        -- 양쪽에서 사용자 줄에 닿는다. 메시지도 error 계약대로 영어
        -- (`H-216` 부류의 잔존이 이 스케치에 남아 있었다).
        Err.errorBefore(if isGlobal
            then "bindLifetime: value is already subscribed"   -- [2026-08-26 H-111] 강/약 어느 쪽이든
            else "bindLifetime: value is already bound to another Instance", SURFACE)
    end

    -- ⭐ [2026-08-31 `H-184`, 사용자 확정] 값이 자기 훅 가드를 가지면(`Effect`/`Observer`의
    -- `_assertBindable` — `H-147`/`H-183`의 "fn 안에서 bind 금지") 부기를 커밋하기
    -- **전에** 먼저 묻는다 — 안 그러면 가드가 던질 때 이미 묶인 채(canExecute 참)
    -- `Destroying` 연결 없는 반쯤 묶인 핸들이 남는다(실측). 평범한 클로저처럼 훅이
    -- 없는 값은 물을 것이 없다. mock(installLifetime)과 실 구현
    -- (`quad-roblox/src/LifetimeHandle.luau` — [2026-09-02] M5 단위 ①로
    -- 구현됨) 둘 다 이 순서.
    if type(value) == "table" and value._assertBindable ~= nil then
        value:_assertBindable()
    end

    local gchold = InstData:GetWeak(inst, "gchold")
    gchold[value] = true -- 강참조: inst가 사는 동안 value 생존 보장(계약 1)
    -- value가 자기 홀더/생존 판정 근거를 직접 들고 있게 함(계약 2).
    -- 둘 다 weak — gchold는 위 (0) 클로저가, gcconn은 gchold[1]이 이미 안전히 붙잡고 있음.
    BindData:SetWeak(value, "gchold", gchold)
    BindData:SetWeak(value, "gcconn", InstData:GetWeak(inst, "gcconn"))

    -- **⭐ [신설, 2026-08-24 6라운드 손 트레이싱 `H-11`] `Effect`면 부수 배선까지
    -- 여기서 한다.** `LP-2`가 *"`Effect`가 `Destroying` 훅을 쓰는 유일한
    -- 소비자"*라고 확정해뒀는데 **그걸 실제로 거는 코드가 코퍼스 어디에도
    -- 없었다** — 그래서 leaf가 죽어도 cleanup이 영영 안 불렸고,
    -- `slot._detachCleanup`(Detach 요소를 파괴하는 유일 경로)과 `OnDestroyed`가
    -- 통째로 무동작이었다(`base/effect-plan.md`).
    -- **왜 이 자리인가**(사용자 판단 2026-08-24): `Destroying`은 엔진이 아는
    -- 요소라 엔진을 다루는 자리에 있어야 하고, `Effect`가 바인드되는
    -- 경로가 둘(children 배열 leaf / `activateList`의 `_detachCleanup` 직접
    -- 바인드)이라 **호출부 쪽에 두면 반드시 한쪽이 샌다.**
    --
    -- ⭐⭐ [2026-08-25 정정, 7라운드 `H-58`/`H-59`] **내부 Observer로 cascade하지
    --   않는다.** 여기 원래 `for _, observer in ipairs(value._observers) do
    --   bindLifetime(inst, observer) end`가 있었는데, 그 필드 자체가 폐기됐고
    --   (`_deps` 하나로 통합) dep 등록은 **생성자에서 한 번만** 일어난다
    --   (`WeakSubscribe`/`WeakCallback`). 그대로 두면 `_observers`가 `nil`이라
    --   순회에서 죽고, 피해 가도 **바인드마다 `Rerun`이 도는 `H-58`이
    --   되살아난다.** 발화 게이팅은 전부 `canExecute(handle)` 하나가 맡는다 —
    --   `base/effect-plan.md`의 "확정 구조" 절이 소스.
    if isObserver(value) then
        -- ⭐ [2026-08-28 `H-159`] Observer도 대칭 — 묶이기 전(생성~바인드 사이)에 온 emit은
        --   Observer 자신의 `_receive`가 `_rerunRequired`로 홀드해 두고(`source-state-plan.md`의
        --   `Observer:_receive` — 전파 루프는 `EmitReceive`로만 본다),
        --   묶이는 순간 1회 발화(출처 없음 — 설치 발화와 같은 모양). Observer엔 epoch가
        --   없으니 dedup은 없고 "놓친 게 있었다"만 기록된다. 본문은 `Observer:_catchUp`
        --   (같은 문서) — `Subscribe`/`WeakSubscribe`와 같은 한 곳.
        value:_catchUp()
    end
    if isEffect(value) then
        value:_bindDestroying(inst)   -- Destroying 연결 + **홀드된 변경 캐치업 1회**
                                      -- (`if self._rerunRequired then self:Rerun() end` —
                                      --   [2026-08-28 `H-151`/`H-159`] 옛 `_epochs:Refresh()`는 폐기,
                                      --   실행 불가 상태에 온 변경은 홀드됐다가 여기서 1회)
                                      -- 의사코드는 `base/effect-plan.md`가 소스.
                                      -- 그 안에서 주입 op `onDestroying(inst, fn)`을
                                      -- 부른다(base는 Instance를 모른다).
    end
end

function unbindLifetime(value)
    -- [2026-08-24 `H-11`] bind의 대칭 — **cleanup은 부르지 않는다.**
    -- cleanup을 여기서 부르면 `destroySlotTree`가 `_detachCleanup`을 손으로
    -- 비운 뒤 unbind하는 경로에서 이중 호출이 된다(`base/effect-plan.md`).
    --
    -- ⭐⭐ [2026-08-25 정정, 7라운드 `H-58`] **`Ref` 콜백도 내부 Observer도
    --   안 뗀다.** 둘 다 생성자에서 `Weak*`로 걸려 있고 발화는 `canExecute`가
    --   막는다 — 떼었다 붙이는 그 춤이 `H-58`의 원인이었다. 포탈은 이제
    --   "떼고 다시 걸기"가 아니라 **재바인드 시 조건부 캐치업 1회**로
    --   성립한다(`_bindDestroying`).
    if isEffect(value) then
        value:_unbindDestroying()     -- Destroying 연결만 끊는다
    end

    local gchold = BindData:GetWeak(value, "gchold")
    if gchold then
        gchold[value] = nil -- inst는 안 건드림, 이 value 하나만 조기 해제
    end
    BindData:SetWeak(value, "gchold", nil)
    BindData:SetWeak(value, "gcconn", nil)
end

-- "지금 묶어도 되는가" — 참이면 아직 아무 데도 안 묶여 있다는 뜻.
-- bindLifetime의 이중 바인딩 가드, Observer:Subscribe()의 이중 등록 가드,
-- Ref가 두 자리에 동시에 놓이는 걸 막는 가드(`base/ref-plan.md`)처럼
-- "이 값을 지금 묶어도 되는가"를 묻는 자리는 전부 이걸 씀. 호출부는
-- 항상 `if not canBound(v) then error(...) end` 모양이 된다.
function canBound(value)
    return not isBoundAlive(value)
end

-- "지금 발화해도 되는가" — State emit 전파 루프가 구독자를 게이팅할
-- 때만 씀(아래 "(4) 실제 호출부" 절). 같은 isBoundAlive를 공유하지만
-- canBound와는 **반대 방향**(canBound(v) == not canExecute(v))이고,
-- 호출부의 질문 자체도 다르므로 이름을 분리해둔다.
function canExecute(value)
    return isBoundAlive(value)
end
```

#### (1-1) ✅ [역전됨, 2026-08-21 구현 전 QA 5라운드 `C-4`] 첫 인자는 **항상 물리 Instance**다

여기 있던 절(4라운드 `D-56`)은 *"`Dispatch.setLength`의 `ownerKey`가 Slot일 수
있으니 백엔드의 `bindLifetime`이 비-Instance 첫 인자를 핸들링하고,
`isBoundAlive`에 세 번째 분기를 둬야 한다"*였다. **5라운드에서 뒤집혔다** —
`setLength`가 **부기 키(`ownerKey`)와 생명주기 앵커(`anchor`)를 따로 받도록**
바뀌면서, 앵커는 언제나 물리 target이 된다(모든 호출부가 이미 그 값을 알고
있다). 그래서:

- **`bindLifetime`/`unbindLifetime`/`isBoundAlive`는 예전처럼 물리 Instance만
  상대한다** — 백엔드에 추가 요구사항이 없고, `isBoundAlive`의 **세 번째
  분기도 필요 없다**(형태 미정인 채 열려 있던 항목이 이걸로 닫혔다).
- 근거와 트레이싱은 `base/dispatch-core-plan.md`의 "`setLength` 구현" 절
  바로 뒤 문단, 역전 전 원문은 `archive/bindlifetime-slot-owner-reversed.md`.

**`bindLifetime`이 `value`와 맺는 계약은 정확히 둘**(이 둘이 위 구현의 전부):

1. **바인딩이 유효한 동안 `value`는 최소한 `inst`만큼은 산다** — `gchold[value]`
   강참조가 그것.
2. **`value`는 `inst`가 살아있는지 스스로 확인할 방법을 갖는다** — `BindData`에
   복사된 gcconn 참조가 그것. `isBoundAlive`(따라서 `canBound`/`canExecute`)가
   `inst` 없이 성립하는 이유.

**`Subscribed`는 이 계약과 일절 무관하다 — 오직 전역 구독 경로 전용
필드**(**[2026-08-26 정정, `H-111`]** `:Subscribe()`뿐 아니라
`:WeakSubscribe()`도 세운다 — 위 `isBoundAlive` (b) 주석 참고). `bindLifetime`/`unbindLifetime`은 이 필드를 **읽지도 쓰지도
않음**. 옛 스케치가 `bindLifetime` 안에서 `value.Subscribed = true`를
세팅하던 것이 이 문서의 오염 지점이었고, 그게 "`canExecute`가 `inst`를
받아야 한다"는 잘못된 귀결까지 끌고 왔음(상세는
`archive/canexecute-inst-arg-reversed.md`).

#### (2) 전역 경로 — `:Subscribe()`/`:Unsubscribe()`

`inst`에 안 묶이는(모듈 최상위 디버그 print류) Observer/Effect 전용. 상세
규칙과 경고는 `base/source-state-plan.md`의 "`:Subscribe()`/`:Unsubscribe()`"
절이 소스이고, 여기선 `canBound`가 보는 상태만 못박음:

**⭐ [2026-08-26 재작성, 8라운드 `H-111`] 프리미티브는 `WeakSubscribe` 쪽이다** —
여기 한때 `Subscribe`/`Unsubscribe` 둘만 있는 블록이 있었는데, 그건
`:WeakSubscribe()`가 생기기 전(2026-08-25 이전) 서술이라 **약한 쪽이 어디서
`.Subscribed`를 세우는지가 통째로 빠져 있었다.** 아래가 **Observer의** 네
진입점 전량이고 소스다(사용자 원문 *"구현이 한 벌"*). **[2026-08-27 9라운드
`H-127`, 같은 날 (b)로 정정]** `EffectHandle`은 **같은 레지스트리 둘과 같은
`canBound` 게이트를 쓰되 네 진입점 본문은 자기 것**이다 — 한때 "같은 넷을
그대로 재사용(함수 배정)"으로 적었는데, 당시 `Subscribe`/`Unsubscribe`가
`self:WeakSubscribe()`/`self:WeakUnsubscribe()`로 **콜론 위임**하고 있어서 그 함수를
`EffectHandle`에 배정하면 위임이 `EffectHandle`의 오버라이드로 가서(재구독 꼬리
두 번, 첫 번째는 강한 킵 전) 깨졌다(감사 4라운드, `luau` 재현; **[2026-08-28
`H-149`]** 그 위임 자체도 이제 없다 — 아래 코드는 인라인). **사용자
확정**: *"observer 랑 effect 랑 헤테로지니어스한 타입인데 … '하나의 무언가가 두
일을 동작하지 않는가에 유의하자'"* — Observer 본문은 Observer만 쓴다. `Effect`
쪽 넷(`Unsubscribe`는 cleanup 소진, `Subscribe`/`WeakSubscribe`는
**[2026-08-27 `H-144`]** 등록 끝에 `_rerunRequired → Rerun`, 넷 다 첫 줄에
**[2026-08-28 `H-147`]** `_running`/`_cleanupRunning` 가드 — `fn`/cleanup은 자기 구독을
못 바꾼다)은
`base/effect-plan.md`의 "`EffectHandle:Subscribe()`" 절이 소스:

```lua
-- ⭐ [2026-08-29 `H-174`/`H-194`] 이 블록 전체는 `Observer.Init(module)`이 만드는 **인스턴스별 임플
-- 팩토리 안**이라고 읽을 것 — 두 레지스트리는 그 클로저 로컬(인스턴스마다 한 벌)이고,
-- `canBound`는 탑레벨 함수가 아니라 `module.canBound`(발화 시점에 읽는 인스턴스 필드)다.
-- ⭐ [2026-08-31 `H-183`, 사용자 확정] Observer도 `fn`이 자기 생명주기를 못 바꾼다
-- (`H-147` 대칭) — `_running` 플래그를 모든 `fn` 실행(설치 발화·`_receive`·`_catchUp`)
-- 둘레에 세우고, 네 진입점 첫 줄이 이를 거부하며, `bindLifetime`은 커밋 전
-- `_assertBindable`(같은 판정, level 3)로 묻는다(`H-184`). `fn`이 error로 죽으면
-- 플래그가 선 채 남는 건 인정된 설계다(사용자: *"오류가 날 때 구조가 깨짐은 설계 상
-- 인정한 부분"*). 아래 블록들의 첫 줄 가드는 지면상 생략 — 실물은 `Observer.luau`.
local Subscribed     = {}                                 -- 강한 레지스트리(살려두는 게 목적)
local WeakSubscribed = setmetatable({}, {__mode = "k"})   -- 약한 레지스트리

-- ── 프리미티브 ──────────────────────────────────────────────
function Observer:WeakSubscribe()
    if not module.canBound(self) then -- bindLifetime과 정확히 같은 게이트(같은 isBoundAlive 공유)
        error(if self.Subscribed
            then "이미 구독된 값"          -- 강/약 어느 쪽이든 이 분기
            else "이미 Instance에 바인딩된 값", 2)   -- [2026-08-27] `level 2` — 아래 둘과 같게
                                                     --   (자리표시자 문구, 실제 메시지는 영어)
    end
    self.Subscribed = true          -- ⭐ [H-111] 약한 쪽도 세운다 — 구독 경로 공용 플래그
    WeakSubscribed[self] = true
    self:_catchUp()                 -- [2026-08-28 `H-159`] 구독 전에 홀드된 변경 1회(바인드와 대칭)
    return self
end

function Observer:WeakUnsubscribe()
    -- ⭐ [2026-08-26, `/code-review high`] 강한 킵이 남아 있으면 error.
    --   이게 없으면 `o:Subscribe()` 뒤 `o:WeakUnsubscribe()`가
    --   `.Subscribed = false`로 **조용히 죽이면서** 강한 레지스트리엔 항목을
    --   남겨 **영원히 GC 안 되는** 반쪽짜리 해제가 된다(바로 아래에서 금지하는
    --   그것). 사용자 확정: fail-fast — `Subscribe()`로 건 건 `Unsubscribe()`로
    --   푼다. 아래 `Unsubscribe`는 이 함수에 위임하지 않고 양쪽을 직접 지우므로
    --   (**[2026-08-28 `H-149`]**) 이 가드와는 무관하다.
    if Subscribed[self] ~= nil then
        error("...: subscribed strongly; use :Unsubscribe()", 2)
    end
    -- ⭐ [2026-08-27 확정, 9라운드 `H-133`] 여기까지가 가드 전부다 — 구독한 적
    --   없는 값·이미 약하게 풀린 값은 **조용히 통과**(아래 두 줄이 no-op).
    --   의도된 관대함이지 누락이 아니다(아래 산문).
    WeakSubscribed[self] = nil
    self.Subscribed = false
    return self
end

-- ── 그 위의 "GC 안 되게 킵" 한 겹 ───────────────────────────
function Observer:Subscribe()
    -- ⭐ [2026-08-28 확정, 10라운드 `H-149`] `self:WeakSubscribe()`에 **위임하지 않고
    --   펼쳐 쓴다.** 위임하면 (1) `error(…, 2)`가 사용자 호출부가 아니라 이 본문을
    --   가리키고(`H-104` level 계약 위반), (2) 콜론 위임은 서브 테이블의 오버라이드를
    --   탄다(`H-144` (b)의 교훈). 사용자: *"weak 나 아닌거나 줄 차이가 그리 안 커서,
    --   분리할 큰 이유가 없음."*
    if not module.canBound(self) then
        error(if self.Subscribed
            then "이미 구독된 값"
            else "이미 Instance에 바인딩된 값", 2)
    end
    self.Subscribed = true
    WeakSubscribed[self] = true
    Subscribed[self] = true         -- 강한 킵 하나만 더
    self:_catchUp()                 -- [2026-08-28 `H-159`] 위 `WeakSubscribe`와 같은 꼬리
    return self
end

function Observer:Unsubscribe()
    -- ⭐ [2026-08-26, `/code-review high` 5차] `WeakUnsubscribe`의 가드와
    --   **대칭**으로 막는다(사용자 확정). 이게 없으면 `WeakSubscribe`로만
    --   등록된 값에 `Unsubscribe`가 **조용히 성공**해서, 범용 정리 코드가
    --   `Effect`의 내부 Observer(오직 `WeakSubscribe`로만 등록된다)를 죽이고
    --   **State dep 전량이 침묵**한다. 계약은 한 줄로: **건 경로로 푼다.**
    if Subscribed[self] == nil then
        error("...: not subscribed strongly; use :WeakUnsubscribe()", 2)
    end
    Subscribed[self] = nil          -- 강한 킵을 놓고
    WeakSubscribed[self] = nil      -- 약한 쪽도 직접(양쪽 테이블 대칭) — [`H-149`] 위임 없음
    self.Subscribed = false
    return self
end
```

- **각 진입점이 자기 게이트를 정확히 한 번 돈다** — **[2026-08-28 `H-149`]**
  한때 "`Subscribe`가 `WeakSubscribe`에 위임하므로 검사가 중복되지 않는다"였는데
  위임을 풀었다(위 주석). 중복되는 세 줄은 같은 타입 안이라 dot 호출 로컬
  헬퍼로 빼도 되지만 **`error(…, 2)` 줄만은 본문에 남길 것** — 헬퍼 안에서
  던지면 level 2가 헬퍼의 호출 줄(quad 내부)을 가리킨다(`H-104`).
- **해제는 반드시 양쪽을 지운다.** `Unsubscribe`가 `WeakSubscribed`를 안
  지우면 항목이 약한 테이블에 남아 반쪽짜리 해제가 된다 — 위임 대신 두 줄을
  직접 쓴다.
- **⭐ 해제는 *건 경로로* 푼다 — 양방향 대칭 가드**(사용자 확정 2026-08-26).
  강하게 구독된 값에 `WeakUnsubscribe`를 부르면 error, 약하게만 구독된 값에
  `Unsubscribe`를 부르면 error. 후자가 없으면 **조용히 성공**해서 범용 정리
  코드가 `Effect`의 내부 Observer(오직 `WeakSubscribe`로만 등록)를 죽이고
  State dep 전량이 침묵한다. **"둘 중 뭐든 풀어주는" 범용 해제는 없다** —
  필요하면 호출부가 `.Subscribed`가 아니라 어느 경로로 걸었는지를 알고 있어야
  한다(핸들을 만든 쪽이 안다).
- **⭐ [2026-08-27 확정, 9라운드 `H-133`] 그 대칭은 *경로 교차*만 막는다 —
  `WeakUnsubscribe`는 관대하고 `Unsubscribe`는 엄격하다.** 구독한 적 없는
  값·이미 약하게 풀린 값에 `WeakUnsubscribe`를 부르면 error 없이 지나간다
  (`WeakSubscribed[self] = nil; .Subscribed = false`가 그대로 no-op — 실측
  `t12_subscribe_failfast.luau`). 같은 값에 `Unsubscribe`는 error다. 사용자
  논거: *"WeakSubscribed 자체가 사라질 수 있는 요소라서, 그 사라지는걸 유저가
  정하게 하는 요소라서 에러를 내야할지 말아야할지 애매한 부분 … 다만 weak 에
  대한 홀드를 유저가 유지하는게 강제라면 b가 되긴 해야하나, 그럴 이유가 없어서
  a가 되는게 맞는듯"* — 약한 등록의 생존은 사용자가 쥔 참조에 달린 것이고
  quad는 그 홀드를 강제하지 않으므로, "없는 항목의 약한 해제"를 오류로 볼
  근거가 없다. 강한 등록은 quad가 살려두는 것이라 "없음"은 반드시 호출부
  실수다. **leaf 바인딩된 값에 `WeakUnsubscribe`를 불러도 같은 이유로
  통과**한다 — `.Subscribed = false` 대입만 하고 gcconn 경로는 안 건드려
  무해하다.
- **⚠️ `:Subscribe()`는 idempotent가 아니다.** 이미 구독됐거나 leaf에
  바인드된 값에 다시 부르면 `canBound` 게이트에 걸려 **error**다
  (**[2026-08-26 확정, `/code-review high`]** `base/source-state-plan.md`가
  한때 *"둘 다 idempotent … 에러 안 나고 그냥 no-op"*이라고 적었는데 그건
  2026-08-18에 `canBound` 게이트가 들어오기 전 서술이라 정면 충돌해 있었다 —
  **의사코드 쪽이 정본**이다).
  **⚠️ [2026-08-26 재정정, `/code-review high` 6차] `:Unsubscribe()`도
  idempotent가 아니다.** 여기 한때 *"게이트가 없어 구독 안 한 값에 불러도 그냥
  지나간다. 비대칭이 의도된 것"*이라고 적혀 있었는데, **같은 날 대칭 가드가
  들어오면서 거짓이 됐다**(위 의사코드: 약하게만 구독된 값이면 error).
  지금 계약은 한 줄이다 — **해제는 건 경로로 푼다.** 구독한 적 없는 값에
  부르는 것도 `Subscribed[self] == nil`이라 error다.
- **에러 메시지 분기는 그대로 성립한다** — `.Subscribed`가 참이면 "구독
  경로", 거짓인데 `canBound`가 거짓이면 "leaf 바인딩". 다만 **[2026-08-26]**
  옛 메시지 *"이미 `:Subscribe()`된 값"*은 `WeakSubscribe`로 들어온 경우까지
  가리키므로 *"이미 구독된 값"*으로 넓혔다(실제 문구는 영어 — error 계약은
  `base/architecture.md`).

`.Subscribed` 필드와 레지스트리 테이블이 **따로** 있는 이유: 테이블은
참조 루트(강한 쪽은 생존 보장, 약한 쪽은 멤버십 기록), 필드는
`canBound`/`canExecute`가 매번 읽는 O(1) 경로 + 에러 메시지에서 "구독이냐
leaf냐"를 가르는 판별자.

**⭐ [2026-08-26 정정, 8라운드 `H-111`] 필드와 *강한* 테이블은 한 세트가
아니다.** 여기 한때 *"둘은 항상 같이 쓰고 같이 지우는 한 세트"*라고 적혀
있었는데, `:WeakSubscribe()`가 생기면서 그게 거짓이 됐다 — 약한 구독은
**필드는 세우고 강한 `Subscribed` 테이블은 안 건드린다.** 그 문장 그대로면
`WeakSubscribe`의 정상 동작이 "반쪽짜리 해제"로 오독된다. 실제 짝은 위
의사코드대로 이렇게 갈린다:

| 진입점 | `.Subscribed` | `Subscribed`(강) | `WeakSubscribed`(약) |
|---|---|---|---|
| `:WeakSubscribe()` | `true` | — | 등록 |
| `:Subscribe()` | `true` | 등록 | 등록 |
| `:WeakUnsubscribe()` | `false` | — | 제거 |
| `:Unsubscribe()` | `false` | 제거 | 제거 |

**Observer 인스턴스 필드 목록 (2026-08-28 명문화)** — `fn`(콜백, `fn(targetState, self,
emitFrom)`), `_state`(리시버 State — `_hold`로 강참조, `source-state-plan.md`),
**`.Subscribed`**(공개 플래그, 위 표), **`_rerunRequired`**(**[2026-08-28 10라운드
`H-159`]** 묶이기 전에 온 emit을 자기 `_receive`가 홀드 — `bindLifetime`/`Subscribe`/
`WeakSubscribe`가 1회 발화. Effect와 같은 뜻("`fn`이 돌아야 하는데 아직 안 돌았다"):
생성 시 참 → `state:Observer(fn)` 생성자의 "등록 시점 즉시 1회 실행"이 돌면서 거짓 →
그 뒤 묶이기 전 사이에 온 변경이 다시 세운다), **`_running`**(**[2026-08-31 `H-183`]**
모든 `fn` 실행(설치 발화·`_receive`·`_catchUp`) 둘레에 서는 재진입 플래그 — 네 진입점과
`_assertBindable`이 거부에 쓴다, 위 (2) 배너), **`_receive(from)`**(`EmitReceive` —
`source-state-plan.md`의 `_emitDown` 아래), **`_catchUp()`**(홀드가 있었으면 출처 없이 1회 —
`bindLifetime`·`Subscribe`·`WeakSubscribe`가 부름, 내부 메소드). 레지스트리 두 테이블은 Observer 인스턴스의
필드가 아니라 **quad 인스턴스별 임플의 클로저 로컬**(`Observer.Init(module)`이 만든다, `H-174`;
**[2026-08-29 `H-194`]** 한때 "`Observer.luau`의 모듈 로컬"). Effect와 달리 epoch 맵·cleanup은 없다
(**[2026-08-31 정정]** 재진입 플래그는 `H-183`으로 생겼다 — 위 `_running`).

**여전히 참인 것**: 자기 짝은 반드시 같이 지운다 — `:Unsubscribe()`가
강한 테이블만 비우고 `WeakUnsubscribe`에 위임하지 않으면(또는 필드만
내리면) 그게 반쪽짜리 해제다.

#### (3) `canBound` vs `canExecute` — 문맥이 달라 다시 갈라짐

**[2026-08-14 열한 번째 세션, 다섯 번째 세션의 "canBound 폐기" 결정을
부분적으로 되짚음]** 원래 폐기 서사·오염 경로 추적은
`archive/canexecute-inst-arg-reversed.md`에 그대로 있음(그 문서가 고친
버그 — 2-인자 `canExecute(inst,value)`가 오염이었다는 것, `unbindLifetime`/
`canExecute`가 `inst`를 안 받아야 한다는 것 — 은 전부 그대로 유효, 이번에
되짚는 건 "판정을 하나의 이름으로 합칠지 두 이름으로 나눌지"뿐).

**왜 다시 나눴나(사용자 판단, `question.md` 0-W 논의 중 제기)**:
`canExecute`라는 이름 하나가 실제로는 서로 다른 두 호출 맥락을 겸하고
있었음:

1. **bound 문맥 — "이 값이 이미 어딘가에 유효하게 묶여 있는가"**(구조적
   점유 여부를 묻는 질문). `bindLifetime`의 이중 바인딩 가드,
   `Observer:Subscribe()`의 이중 등록 가드, 그리고 `Ref`가 두 자리에
   동시에 놓이는 걸 막는 가드(`question.md` 0-W, `base/ref-plan.md`
   "이중 배치 방지" 절)가 전부 이 질문만 물음 — 이 값들은 emit 전파에
   참여조차 안 하는 경우도 있음(`Ref`가 그 예).
2. **execute 문맥 — "지금 이 구독자가 발화해도 되는가"**. State emit
   전파 루프가 매 발화마다 각 구독자에게만 묻는 질문(아래 "(4)" 절) —
   `Effect`/`Observer`처럼 실제로 콜백을 실행하는 값에만 의미가 있음.

**[정정, 2026-08-18 구현 전 QA] 두 판정값은 같은 게 아니라 서로의
부정이다** — `canBound(v) == not isBoundAlive(v)`, `canExecute(v) ==
isBoundAlive(v)`. 열한 번째 세션은 "판정 로직도 같고 값도 항상 같은데
호출부의 질문만 다르다"를 이름 분리의 근거로 적었는데, 그건 `canBound`를
"이미 묶여 있는가"로 잘못 읽은 결과였다. 이름 그대로 읽으면 두 질문은
**반대 방향**이고, 공유하는 건 판정 **로직**(`isBoundAlive`) 하나뿐이다.
**부정 관계라는 사실은 이름 분리의 명분을 오히려 강화한다** — 같은 값을
두 이름으로 부르는 게 아니라, 서로 다른 방향을 묻는 두 predicate이기
때문에 호출부가 `not`을 붙이는지 여부로 의도가 드러난다.

여전히 유효한 것 — **호출부가 왜 묻는지가 서로 다르다**: `Ref`처럼
발화라는 개념 자체가 없는 값에게 "발화해도 되는가"(`canExecute`)를 묻는
건 개념이 안 맞고, 나중에 "구조적으로는 묶여 있지만 일시적으로 발화만
멈춘" 상태가 생기면(지금은 없음) 둘의 관계가 단순 부정에서 더 벌어질
여지도 있다.

**해법 — 이름은 둘, 판정 로직은 하나(사용자 제안).** 실제 gcconn/
`.Subscribed` 체크는 비공개 헬퍼 `isBoundAlive(value)`(위 (1) 코드
블록) 하나에만 있고, `canBound`/`canExecute`는 그 헬퍼를 각각 부정해서/
그대로 감싸는 얇은 진입점 — 코드 중복 없이 호출부의 의미만 분리됨.
**바뀐 호출부**: `bindLifetime`의 가드(위 (1))와 `Observer:Subscribe()`의
가드(위 (2))는 이제 `canBound`를 씀 — 형태는 항상 **`if not canBound(v)
then error(...) end`**(못 묶는 경우에만 에러). **안 바뀐 호출부**: State
전파 루프(아래 "(4)")만 여전히 `canExecute`를 쓰고, 거기선 부정 없이
그대로 씀.

부수 효과: **"바인딩이 죽은 뒤의 재사용은 허용"** — `inst`가
Destroy됐거나 `unbindLifetime`된 `value`는 `canBound`가 **참**이라
게이트를 통과함(다시 다른 `inst`에 걸 수 있음). 살아있는 바인딩만 막는
게 이 게이트의 의도.

#### (4) 실제 호출부 — Observer의 `_receive`가 `canExecute`로 게이팅한다

`canExecute`가 "어디서 불리는가"는 지금까지 어느 문서에도 코드로 없었음(위
정정 배너 참고). 확정된 위치는 **`Observer:_receive(from)`**(**[2026-08-28]** State의
전파 루프는 구독자를 `EmitReceive`로만 보고 `sub:_receive(from)`을 부른다 —
`base/source-state-plan.md`의 `_emitDown`; 판정·홀드는 Observer 자신의 몫):

- State는 자기 구독자를 **weak-키로** 담는다 — 살려두는 책임은 State가
  아니라 `gchold`(leaf) 또는 전역 `Subscribed` 테이블(전역)에 있고, 어디에도
  안 묶인 Observer는 그냥 GC되어 구독 목록에서 자연히 빠짐.
  **⭐ [2026-08-25 정정, 7라운드 `H-56`] 집합의 원소는 "Observer의 emit
  클로저"가 아니라 **Observer 값**이다.** `bindLifetime(inst, observer)`가
  Observer **값**을 키로 `BindData`에 gcconn을 복사하므로, 집합에 클로저를
  담으면 identity가 달라 `canExecute`가 **항상 거짓**이 된다.
- 발화 시 Observer 자신의 `_receive`가 `canExecute(self)`를 확인하고, 거짓이면
  **`_rerunRequired`만 세우고 건너뜀**(**[2026-08-28 `H-159`]** 옛 "조용히 건너뜀" —
  이제 묶일 때 1회 따라잡는다) — 죽은 `inst`를
  건드리는 시도가 일어나지 않게 막는 위 "해야 할 일은 딱 하나" 원칙의
  실제 구현 지점.
  **⭐⭐ [2026-08-25 정정, 7라운드 `H-56`] 자식 State 노드는 이 게이트를
  안 탄다.** 여기 한때 *"각 구독자에 대해"*라고만 적혀 있었는데, 그대로
  짜면 `:With`/`:Compute`/`:Gate`가 만든 자식 노드가 **전부 걸러진다**
  (자식은 `bindLifetime`된 적도 `:Subscribe()`된 적도 없어
  `isBoundAlive`가 항상 거짓) — `A:Set()`이 파생 State에 한 번도 안 닿아
  그 아래 모든 Observer가 침묵한다. **확정 의사코드는
  `base/source-state-plan.md`의 "전파 루프 — 확정 의사코드" 절이 소스**이고,
  자식 노드의 생존은 `canExecute`가 아니라 같은 문서의 `_hold` 불변식이
  책임진다.

**`state:Observer(fn)`의 "등록 즉시 1회 실행"은 이 게이팅과 무관**하다 —
그건 Observer 생성자 자체의 계약이라 `bindLifetime` 이전에 동기적으로
일어나고(그 시점엔 `canExecute`가 당연히 거짓), 게이팅 대상은 **그 이후의
재실행**뿐. `base/slot-plan.md`/`base/dispatch-core-plan.md`가 이미 같은
내용을 주석으로 달아둔 것과 같음.

**Instance당 gcconn/gchold는 하나로 공유** — `bindLifetime`을 여러 값에
대해 여러 번 불러도 같은 `inst`면 같은 `gcconn`/`gchold`를 재사용(위 (0)에서
Instance 생성 시 한 번만 만들어지고, 이후는 `InstData:GetWeak`으로 바로
찾음). 자세한 내부 구조는 `base/relate-plan.md`.

**실측 필요(M0/M2)**: `canExecute`가 매 발화마다 `BindData:GetWeak(value,
"gcconn")`(weak table 2단 조회)를 하는 비용이 실사용에서 문제되는지는
quad-roblox 구현 단계에서 실측 확인 대상 — 문제가 되면 gcconn을 `value`의
직접 필드로 내리는 선택지가 있음(옛 초안이 `self.Connection`으로 스케치했던
모양). 지금 `Relate` 쪽으로 둔 이유는 "Observer 값 자체에 부작용을 안
남기고 외부 weak 인덱싱을 선호"라는 기존 사용자 방침(`base/source-state-plan.md`의
"`state:Observer(fn)`" 절 구현 노트)이고, 성능 근거가 나오면 뒤집어도 되는
순수 구현 세부.

이건 `base/dispatch-core-plan.md`의 "핸들러 내부 상태 저장" 유틸(`Relate`
직접 사용)과 짝을 이루는 별도 유틸 — 하나는 "상태를 어디에 저장할지"
(`Relate:SetStrong`/`:SetWeak`), 다른 하나는 "언제까지 실행되어도 되는지"
(`bindLifetime` + `canBound`/`canExecute`)를 다룸. 후자의 **실 구현**은 전자가
제공하는 같은 `Relate` 프리미티브 위에 얹힘(위 절) — 별도 저장 메커니즘을
새로 만든 게 아니라 `Relate` 하나를 두 용도로 재사용. **[2026-08-28 정정, M2
첫 단위]** 다만 그 실 구현을 갖는 건 base가 아니라 **백엔드**다 — quad-base의
`LifetimeHandle.luau`는 `InitLifetimeHandle(module)`이 에러 스텁 4종을 모듈
인스턴스에 설치하는 인터페이스뿐이고 `Relate`를 require하지 않는다(아래
"`Connected` 체크는 rbvm 패턴을 그대로 베끼는 게 아니라" 절, `base/architecture.md` 소스 트리).
여기 한때 *"둘 다 base가 제공하는 범용 유틸로 확정"*이라 적혀 있었으나 그건
`Relate` 쪽에만 맞는 말이다.

**교차검증(2026-08-04 4차 라운드)**: 사용자가 공유해준 실제 참고 코드
(`.claude/initreq/artworks/EventDrivenProgramming/`, PA님 작성)는 GC-native가
아니라 전부 수동 `:unsubscribe()`/`:disconnect()`로 관리됨 — rbvm 기반
GC-native 원칙과 반대 선택이라 재확인했으나 **GC-native 유지로 확정**(지금까지
명시적 dispose가 꼭 필요할 만큼 큰 자원을 다루는 실제 사례가 없었음). **막다른
길은 아님을 기록**: rbvm처럼 관계를 양쪽 다 weak-keyed로 두고 모든 걸 connection
람다에 담아두는 방식이면, 나중에 GC만으로 부족한 케이스가 실제로 생겨도 그
connection을 얻어 `disconnect()`하는 명시적 dispose 경로를 추가로 얹는 게
가능한 디자인 — 필요성이 드러나면 그때 얹을 하이브리드 여지로만 남겨둠.

**재사용 사례(2026-08-04 2차 라운드)**: Store/State의 무효화(invalidate)
신호를 받는 리스너 클로저도 정확히 이 유틸로 등록됨 — `base/
store-plan.md`가 예전에 "state 옵저빙 결과로 slot을 조작할 때 생존
여부를 어떻게 확인할지" 미해결로 남겨뒀던 문제가, 사실은 새 메커니즘이
필요한 게 아니라 이 canExecute 게이트를 그대로 적용하면 되는 사례였음(별도
`isInit` 분기 불필요). 상세는 `base/source-state-plan.md`의 "Slot 생존 확인" 절 참고.

## 2026-08-04 검증 라운드에서 보강된 내용

**`Connected` 체크는 rbvm 패턴을 그대로 베끼는 게 아니라 base가 인터페이스로만
내보내는 것.** Roblox는 `RBXScriptConnection`에 이미 `Connected`가 존재하고
Destroy 시 모든 커넥션을 즉시 끊어주지만, 다른 엔진에서도 라이프사이클을
확인할 수 있어야 하므로 base는 "이 바인드가 아직 유효한가"를 묻는 람다/인터페이스만
정의하고, quad-roblox가 그 구현을 Roblox의 실제 `Connected`로 채워넣는다(구현
주입 방식 — 모듈 인스턴스 필드를 백엔드 팩토리가 뮤테이션 — 은
`base/module-lifecycle-plan.md`가 base 유틸 전반에 대해 일반화해둔 것과 같다). 이게
필요한 이유: rbvm처럼 GC 트릭으로 라이프사이클을 연결하면 GC가 즉발이 아니라서
중간에 죽은 참조가 남아있을 수 있고, 그 시점에 store에 새 값이 들어오면 죽은
대상에 처리를 시도하다 터질 수 있음 — 그래서 처리 직전에 유효성을 확인.

**`Destroying` 훅은 생각보다 덜 중요할 수 있음.** rbvm의 GC-네이티브 무효화
방식(자료구조를 직접 건드리지 않고 네이티브 GC에 후처리를 위임)이 성능상
유리해서, `Destroying` 훅에 명시적으로 의존하는 경로는 실제로는 거의 필요
없을 가능성이 큼 — 확정된 방향(Destroying 하나로 통일)은 유지하되, 실제
구현에서 이 훅을 쓰는 지점이 예상보다 적을 수 있다는 점을 열어둘 것.

**즉시(eager) 정리 예외 두 가지(작고 유계한 포인터, 네임스페이스 dispose)는
quad에는 거의 해당 안 될 가능성이 큼.** rbvm은 이미 존재하는 real DOM 위에
가상 계층을 얹는 구조라 "가상 계층이 필요 없어지면 지운다"는 문제가 있지만,
quad는 자신이 만든 instance를 항상 끝까지 들고 있어서 이런 종류의 즉시 정리
자체가 필요 없을 가능성이 높음 — 실제 구현 단계에서 필요성이 확인되면 그때
추가.

**retract는 Destroy 시점에 필요 없는 이유가 엔진 레벨에서 한 번 더 보강됨.**
Roblox 엔진 자체가 Destroy 시 Tag/Attribute/실행 중인 Tween을 전부 알아서
정리해준다 — 라이브러리가 따로 처리할 필요가 없음. Roblox 이외의 엔진에서
이런 정리가 필요하다면 그건 그 엔진의 `quad-X` 서브패키지가 책임질 문제(base
관심사 아님). 사용자가 커스텀 Destroy-time 처리가 필요하면 **`Effect`(그리고 그 슈가
`OnDestroyed`)를 쓰면 되는 구조**라, 라이브러리가 강제로 제공할 필요도 없음.
**[정정, 2026-08-20 구현 전 QA 4라운드 `LP-4`]** 옛 서술은 여기 정상 경로를
`[Event "Destroying"]`을 직접 바인드하는 것으로 적었는데, 그건 사용자가 엔진
이벤트를 손으로 다루라는 뜻이 되어 quad가 이미 제공하는 프리미티브를 우회하는
안내였다 — 사용자 판정: *"Effect 임. 그리고 그 슈거인 OnDestroyed 존재"*.
`Effect(fn)`이 반환하는 cleanup이 leaf 사망 시 정확히 1회 불린다는 계약
(`base/effect-plan.md`)이 정확히 이 용도이고, `OnDestroyed(fn)`은 그걸 감싼
순수 팩토리다(`base/lifecycle-hooks-plan.md`). `[Event "Destroying"]`을 직접
바인드하는 것도 물론 막히진 않지만 권장 경로가 아니다.

## 이름: `cleanup` → `retract`

"cleanup"이라는 이름은 부적절하다는 사용자 피드백(완전 소멸 정리로 오인되기
쉬움) — 실제 의미는 "이전에 적용한 처리를 무른다/멈춘다"이므로 **`retract`**
로 통일. (`revert`, `rescind`도 검토했으나 `retract`가 "이전에 취한 조치를
철회한다"는 의미로 가장 정확 — `process`/`retract` 쌍으로 자연스럽게 대구를
이룸.) 대부분의 문서에서 이 이름으로 갱신됨.

**[확인 완료, 2026-08-13,
`session/2026-08-13-06-commit-audit-dispatch-redesign-bugs.md`]
`base/effect-plan.md`가 쓰는 용어 `cleanup`은 잔여 stale이 아니라 의도된
별개 개념** — 매 감사마다 재지적되므로 여기
못박아 둠. 두 층위가 다름:
- **`retract`**: Handler 계약의 것. `process`가 반환하는 클로저로, quad
  **내부 배관**이 "이전 처리를 무른다".
- **`cleanup`**: `Effect(fn)`에서 **사용자가 작성한 `fn`이 반환하는 콜백**.
  React `useEffect`의 그것과 동형이고, 사용자 API 표면의 어휘라 `retract`로
  통일할 대상이 아님(오히려 통일하면 React 배경 사용자에게 더 낯설어짐).

즉 "cleanup 잔여 확인"은 `effect-plan.md`에 대해서는 **끝난 것**으로 봐도 됨.

**[2026-08-13 다섯 번째 세션] `retract`는 더 이상 Handler의 *필드*가
아니라 `process`가 반환하는 클로저의 *역할 이름*이다.** 개념/이름
자체는 그대로 유효하고(이 절의 결론은 안 바뀜), 다만 코드에서
`handler.retract(...)`를 찾으면 안 됨 — `local retractor =
handler.process(inst,k,v,index)` 형태로 받아서 `Dispatch`가 `chains`에
보관했다가 부름(`base/dispatch-core-plan.md` "핸들러 계약"/"Dispatch 체인"
절). 이 문서가 계속 쓰는 "retract 시점"/"retract가 불린다"는 표현은
전부 그 클로저가 호출되는 시점을 가리킴.
