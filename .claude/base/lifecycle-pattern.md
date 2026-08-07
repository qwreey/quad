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
바로 지우거나 재구성하지 않음. quad-v2도 이 모양을 그대로 채택: 라이프타임
홀더는 "내가 아직 살아있게 하는 뒷받침 참조"가 nil인지만 확인하면 됨.

### 2. Instance 파괴는 `Instance.Destroying` 훅 하나로만 관측

rbvm은 실제 Roblox Instance의 파괴를 감지하는 지점을 단 하나로 좁혀둠 —
`inst.Destroying:Connect(...)` (`proxy/base.luau:150-156`), `Destroyed` 같은
플래그를 그 콜백에서만 true로 뒤집음. `AncestryChanged`나 폴링 방식은 안 씀.
quad-v2도 동일: 인스턴스 라이프사이클 훅 지점은 `Destroying` 하나로 통일.

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
소멸 시 정리"는 **하나로 통일** — 후자는 애초에 안 만듦. `research/
tween-plan.md`/`base/slot-plan.md`의 "cleanup" 표기는 대부분 `retract`로
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

**`canExecute`의 시그니처는 `(handle) -> boolean`이지 `() -> boolean`이
아님(2026-08-07 여덟 번째 세션, 정정)** — 처음엔 "바인딩마다 클로즈오버된
zero-arg 람다"로 적었으나, 그러면 등록마다 클로저를 새로 만들어야 해서
아래 "base 유틸은 인터페이스, 실제 구현은 백엔드 팩토리가 주입" 절의 패턴
(base는 타입만 갖고, quad-roblox가 `BaseModule`을 뮤테이션해서 실 구현체를
채워넣음)과 잘 안 맞음 — 그 패턴이 성립하려면 `canExecute`는 **quad-roblox가
한 번만 주입하는 공유 함수**여야 하고, 그러려면 "어떤 등록을 확인할지"를
가리키는 인자(`handle`, 아래 gchold 스케치의 Connection이 이 역할)가 있어야
함. base 입장에선 `handle`은 `any`(엔진마다 실체가 다를 수 있음).

**quad-roblox 구현 스케치(rbvm 패턴 재사용, base 결정 아님 — 참고용)**:
Instance당(꼭 하나일 필요는 없지만 보통 그게 싸서 하나로 감) weak-keyed
per-instance 저장소(`base.perInstanceState(inst)`)에 "gchold" 배열을 둠.
그 배열엔 절대 발화하지 않도록 골라 만든 신호에 연결한 Connection을
넣는데, 이 Connection의 콜백 클로저 안에 실제로 살려두고 싶은 옵저버를
업밸류로 캡쳐해둠(콜백은 안 불려도 클로저 자체가 살아있는 한 업밸류는
안 죽음) — `inst`가 GC되면 gchold 배열째로 같이 죽으므로 옵저버도 자연히
GC됨(`base/bind-system-plan.md` "핸들러 내부 상태 저장" 절의 weak-keyed
중첩 구조와 같은 원리). `canExecute(handle)`은 이 Connection(또는 이를
감싼 핸들)을 받아 `.Connected`를 확인하는 정도로 구현될 것.
**미확인 세부사항**: 옵저버 → Connection 역참조를 별도 weak 릴레이션으로
둘지, 아니면 그냥 Observer 테이블 안 평범한 필드로 넣을지(정적 해싱된
필드 접근이 weak 테이블 조회보다 싸서 후자가 나을 수 있음) — quad-roblox
구현 단계에서 실측 확인 필요, base 설계에 영향 없음.

이건 `base/bind-system-plan.md`의 "핸들러 내부 상태 저장" 유틸과 짝을
이루는 별도 유틸 — 하나는 "상태를 어디에 저장할지"(weak-keyed per-instance
저장소), 다른 하나는 "언제까지 실행되어도 되는지"(생명 바인드 + canExecute)를
다룸. 둘 다 base가 제공하는 범용 유틸로 확정.

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
store-semantics.md`가 예전에 "state 옵저빙 결과로 slot을 조작할 때 생존
여부를 어떻게 확인할지" 미해결로 남겨뒀던 문제가, 사실은 새 메커니즘이
필요한 게 아니라 이 canExecute 게이트를 그대로 적용하면 되는 사례였음(별도
`isInit` 분기 불필요). 상세는 `base/bind-system-plan.md`의 "Store/State/
Source 온톨로지" 절 참고.

## 2026-08-04 검증 라운드에서 보강된 내용

**`Connected` 체크는 rbvm 패턴을 그대로 베끼는 게 아니라 base가 인터페이스로만
내보내는 것.** Roblox는 `RBXScriptConnection`에 이미 `Connected`가 존재하고
Destroy 시 모든 커넥션을 즉시 끊어주지만, 다른 엔진에서도 라이프사이클을
확인할 수 있어야 하므로 base는 "이 바인드가 아직 유효한가"를 묻는 람다/인터페이스만
정의하고, quad-roblox가 그 구현을 Roblox의 실제 `Connected`로 채워넣는다(구현
주입 방식은 아래 "base 유틸은 인터페이스, 구현은 백엔드 팩토리" 절 참고). 이게
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
관심사 아님). 사용자가 커스텀 Destroy-time 처리가 필요하면 `[Event
"Destroying"]`을 직접 바인드해서 처리하면 되는 구조라, 라이브러리가 강제로
제공할 필요도 없음.

## 이름: `cleanup` → `retract`

"cleanup"이라는 이름은 부적절하다는 사용자 피드백(완전 소멸 정리로 오인되기
쉬움) — 실제 의미는 "이전에 적용한 처리를 무른다/멈춘다"이므로 **`retract`**
로 통일. (`revert`, `rescind`도 검토했으나 `retract`가 "이전에 취한 조치를
철회한다"는 의미로 가장 정확 — `process`/`retract` 쌍으로 자연스럽게 대구를
이룸.) 대부분의 문서에서 이 이름으로 갱신됨 — 잔여 "cleanup" 표기가 남은
문서가 있을 수 있으며, 그 확인/정리는 진행 중.
