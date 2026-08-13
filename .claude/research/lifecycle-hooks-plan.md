# 생명주기 훅 슈가 — `OnCreated`/`OnDestroyed`(+백로그 후보 `OnRendered`/`PostRef`)

**상태**: research — 사용자 제안(2026-08-14 세션)으로 신설, 착수 전
백로그. 이미 확정된 `PreRef`/`Ref`(`base/ref-plan.md`)와
`Effect`(`base/effect-plan.md`) 프리미티브 위에 얹는 순수 슈가 후보 —
`research/component-fallback-plan.md`의 `Fallback`이
`additional-primitives-plan.md`의 기존 결론 위에 얹혔던 것과 같은 관계,
이 문서도 그 프리미티브들의 확정 사항을 하나도 안 뒤집음. 우선순위는 그
형제 백로그들(`quad-mock`/`quad-debug`/`Operator`/`Fallback`)과 동급 —
"quad 개발 상당 부분 끝난 뒤"로 볼 것.

## 동기 (사용자 원 메모)

React/Vue류 프레임워크의 `OnCreated`/`OnRendered`/`OnDisposed` 생명주기
훅을 quad에도 두면 좋겠다는 제안. 처음엔 `Frame{[OnCreated] = fn}`처럼
싱글톤 프리미티브를 해시 파트 DI 키로 쓰는 안을 검토했으나, `:Compute`
콜백에 `State<function>`이 들어올 때의 처리가 까다로워질 것 같다는 우려로
스스로 기각 — 대신 `OnCreated(fn)`이 이미 있는 `PreRef` 인스턴스를 반환하는
**순수 팩토리 함수**(children 배열에 놓는 슈가)라면 그 우려 자체가 안
생긴다는 데 도달했음. 이후 방향이 더 좁혀져 **핵심 우선순위는
`OnCreated`/`OnDestroyed` 둘**로 확정되고(`OnDisposed`라는 최초 가칭
대신 `OnDestroyed`를 사용자가 선호 — 아래 "이름 컨벤션" 절 참고), 두
훅 모두 **여러 번 나란히 등록 가능**하다는 게 이 제안의 특징으로
명시됐음. `OnRendered`는 사용자가 **지금은 의도적으로 구현 안 하기로
확정**(디스패치 코어에 실제 post-pass가 필요해 공짜가 아니라서) —
다만 나중에 만들 때 `PreRef`의 거울상인 `PostRef`로 구현하면 될
것 같다는 구체 스케치를 남겼고(아래 ② 절), 이 문서는 그 스케치를
백로그 후보로 보존하는 용도.

## 핵심 논지 — 이 셋은 사실 새로운 타입/개념이 아니다

`OnCreated`/`OnDestroyed`가 "정말 공짜"인 이유는 단 하나로 귀결됨:
**이것들은 Dispatch/Brand/타입 시스템이 알아야 하는 새 개념이 아니라,
호출되는 즉시 평가되어 이미 존재하는 프리미티브의 인스턴스로 사라지는
plain 함수일 뿐**이기 때문.

```lua
local function OnCreated(fn: (inst: Instance) -> ()): PreRef<Instance>
    return PreRef():Callback(fn)
end

local function OnDestroyed(fn: () -> ()): EffectHandle
    return Effect(function() return fn end)
end
```

호출 즉시 `PreRef():Callback(fn)`/`Effect(...)`가 실행되고, children
배열에 실제로 놓이는 건 **그 결과인 `PreRef`/`EffectHandle` 인스턴스
자체**임 — `OnCreated`라는 이름이나 개념은 이 시점 이후 어디에도
안 남음. `Dispatch`는 이미 아는 `(v=PreRef)`/`(v=EffectHandle)` 매치
핸들러로 정확히 똑같이 처리하고, 새 브랜드 태그조차 필요 없음(이미
존재하는 `Brand`로 그대로 식별됨).

이게 바로 사용자가 처음에 걱정했던 **"`:Compute` 콜백에 `State<function>`이
들어오면 처리가 까다로워지지 않을까"** 문제가 애초에 안 생기는 이유와
정확히 같은 뿌리: 그 우려는 `OnCreated`가 **해시 파트 DI 키**(예:
`[OnCreated] = fn`)였다면 실제로 발생했을 문제임 — DI 키는 Store/Dispatch
디스패치 경로를 거쳐야 하고, 그 값이 `State<function>`으로 감싸이는
경우까지 핸들러가 다뤄야 함. 반면 팩토리 함수 호출은 **Store/Dispatch
경로를 아예 안 탐** — 순수 Lua 함수 호출이 즉시 평가되어 끝나고, 그
결과(`PreRef`/`EffectHandle`)가 이미 Store/State 값이 아니라 확정된
객체로서 children 배열에 얹히기 때문. 즉 `State<function>` 문제는
"이 값이 언제/어떻게 디스패치되는가"의 문제인데, 팩토리 접근은 애초에
디스패치될 "값"을 안 만들고 곧장 "결과 객체"를 만들어버림.

## ① 이미 거의 확정적인 슈가 둘

### `OnCreated(fn)`

`PreRef():Callback(fn)`를 반환하는 순수 팩토리. `PreRef`의 기존 계약을
그대로 물려받음(`base/ref-plan.md` "`phase` 옵션 폐기 → 위치로 표현,
`PreRef` 신설" 절) — 다른 모든 children/프로퍼티/이벤트보다 먼저
호이스팅되어 fire, 즉 "이 인스턴스에 뭐가 됐든 일어나기 전"에 콜백이
불림. 새 Dispatch 메커니즘 불필요, `PreRef` 그대로 재사용.

**v1과의 관계 — 이름이 같아 보여도 메커니즘은 다름.** `base/ref-plan.md`
510~513행에 이미 이렇게 확정돼 있음:

> quad v1의 `OnCreated` 특수 DI 키는 이식하지 않는다.
> `Ref():Callback(function(inst) end)`를 children 배열에 넣는 것만으로
> 완전히 대체됨(여러 개 등록도 자연히 지원, 별도 특수 키 불필요) — v1
> 대비 빠진 기능처럼 보이지 않도록 이 대체 관계를 문서에 남겨둠.

이 문장이 거부한 건 v1식 **"특수 DI 키"** 메커니즘(해시 파트에 매직
키를 두고 Dispatch가 그 키를 특별 취급하는 것)이지, **"팩토리 함수가
기존 `Ref`/`PreRef`를 반환해서 children 배열에 놓는 것"**과는 층위가
다름 — 이 문서의 `OnCreated(fn)`은 정확히 저 문단이 이미 권장한
관용구(`Ref()`/`PreRef():Callback(fn)`)를 이름 하나로 감싼 것뿐이라
모순이 아니라 그 결론의 자연스러운 재포장임. 이름이 v1과 같아 헷갈릴
수 있다는 점만 "이름 컨벤션" 절에서 별도로 짚음.

### `OnDestroyed(fn)`

`Effect(function() return fn end)`를 반환하는 팩토리. `Effect(fn, state?)`가
`state` 생략 시 "설치 시 즉시 1회 실행 + 반환값이 leaf 사망 시 정확히
1회 호출되는 cleanup"이라는 기존 계약(`base/effect-plan.md` 28행)을
그대로 재사용 — 다만 여기서는 **설치 단계에서 실행되는 함수가 `fn`
자신이 아니라 `function() return fn end`라는 래퍼**라는 점에 주의.
그 래퍼의 "즉시 1회 실행"은 그냥 `fn`을 감싸 리턴하는 것뿐이라 부작용이
없고, **`fn` 자신은 leaf가 죽을 때(cleanup 시점)에만 실제로 호출됨** —
`fn`을 설치 단계에서 안 부르고 cleanup으로만 등록하는 트릭. 새
Dispatch/Effect 메커니즘 불필요, 기존 계약 재사용만으로 정확히
"Destroy 시 1회 호출"이 나옴.

### 다중 등록 가능 — 이 제안의 핵심 특징

```lua
Frame {
    OnCreated(fn1),
    OnCreated(fn2),
    OnDestroyed(cleanupA),
    OnDestroyed(cleanupB),
}
```

`OnCreated(fn)`/`OnDestroyed(fn)` 호출마다 `PreRef()`/`Effect(...)`
**생성자가 매번 새로 불려 독립된 인스턴스**를 만들어냄 — children
배열의 서로 다른 숫자 슬롯에 놓이므로, 같은 인스턴스에 여러 개를
나란히 등록하는 게 자연히 지원됨. 이건 `Ref():Callback(fn)` 단일
슈가 관용구나 v1의 단일 DI 키 관례와 달리, **팩토리-함수 접근이 주는
공짜 이점**임(v1처럼 "이 키엔 콜백 하나만" 같은 제약이 아예 성립할
자리가 없음 — 애초에 키가 아니라 매번 새로 만들어지는 값이므로).

**`PreRef`의 "1회용, 재사용 시 error" 가드와 안 충돌하는 이유
(`base/ref-plan.md` "`phase` 옵션 폐기 → 위치로 표현, `PreRef` 신설" 절의
`_fired` 관련 대목)**: 그 가드가 막는 건 **같은 `PreRef` 객체를 두 번째
construction에 재사용**하는 것("이미 한 번 fire된 PreRef 객체를 다시
놓으면 stale `.Value`로 콜백이 조용히 잘못 호출됨") — "여러 개의 서로
다른 `PreRef`를 나란히 쓰지 마라"가 아님. `OnCreated(fn1)`과
`OnCreated(fn2)`는 각각 `PreRef()`를 독립적으로 호출해 서로 다른 객체를
만드므로, 이 가드가 막으려는 재사용 시나리오 자체가 발생하지 않음.

## ② `OnRendered`(+`PostRef`) — 의도적으로 지금 구현 안 함, 백로그 후보만

**[결정, 2026-08-14 세션]** `OnCreated`/`OnDestroyed`와 달리 지금 착수
안 함 — 아래 이유로 새 디스패치 단계가 실제로 필요해서, 착수 여부
자체를 지금 정하지 않고 **백로그 후보로만 남겨둠**. 아래는 나중에
꺼내볼 때 바로 쓸 수 있도록 정리해두는 조사 결과.

`base/dispatch-core-plan.md`의 "확정된 디스패치 모델" 절이 계약하는
두 패스(배열 파트 먼저, 해시 파트 나중) 기준으로 현재 base가 제공하는
훅들의 타이밍을 정리하면:

| 훅 | 시점 |
|---|---|
| `PreRef` | 두 패스보다도 **먼저**(호이스팅 pre-pass) |
| 일반 `Ref`/`Effect`(children 배열 위치) | **배열 파트** 처리 시점(아직 해시 파트 전) |
| (없음) | 해시 파트(프로퍼티/이벤트)까지 **전부 끝난 뒤** |

즉 "이 인스턴스의 프로퍼티/이벤트까지 전부 세팅된 뒤"를 보장하는 훅이
**현재 base 설계엔 없음**. 이건 기존 프리미티브 재사용만으로는 안 되고
디스패치 코어에 실제로 새 단계가 필요하다는 뜻이라, `OnCreated`/
`OnDestroyed`와 달리 **진짜로 공짜가 아님** — 그래서 지금 채택하지
않기로 함.

**`PostRef` 스케치(사용자 제안, 2026-08-14)** — 완전히 새로운
메커니즘을 발명할 필요는 없어 보임. `PreRef`의 pre-pass가 "두 패스
루프를 돌기 **전에** 배열 파트를 미리 한 번 훑어 fire하고 소진하는"
별도 선행 스캔이었던 것(`base/ref-plan.md` "PreRef" 절, "호이스팅의
실제 구현" 항목)과 **정확히 대칭인 후행 스캔**을 만들면 됨 — 두 패스가
끝난 **뒤에** 배열 파트를 다시 한번 훑어 `PostRef` 슬롯만 골라 fire.
`PreRef`가 이미 갖고 있는 장치(호이스팅 없이 그냥 후행이면 되므로 오히려
더 단순할 수 있음, 1회용 `_fired` 가드, `None` 소진 대신 이 시점엔
순서 보장이 더 이상 필요 없으니 `nil` 소진도 검토 가능)를 그대로
거울상으로 재사용하는 구현이라 **새 개념이 아니라 기존 `PreRef` 코드의
변형**에 가까움 — 다만 `Dispatch.drive`에 실제 루프 한 번이 추가되는
비용은 여전히 있으므로 "공짜"까지는 아님. `OnRendered(fn)`은
`PostRef():Callback(fn)`을 반환하는 팩토리로, 위 `OnCreated`와 완전히
같은 패턴이 됨.

**스코프도 여전히 불명확함**: "렌더 완료"가 (a) 이 인스턴스 자신의
프로퍼티/이벤트 세팅만 끝나면 되는지, (b) 이 인스턴스의 **자식들까지
전부 마운트를 끝내야** 하는지 — React류 `on*Rendered` 이름들은 보통
(b)(서브트리 전체 완료)를 뜻하는 경우가 많아, 이름만 보고 (a)로 기대하는
사람과 실제 구현이 (b)라면(또는 반대라면) 기대치가 어긋날 위험이 있음.
`PostRef` 후행 스캔은 자연스럽게 (a)만 줌 — (b)를 원하면 자식 서브트리
전체의 마운트 완료를 기다리는 별도 신호가 있어야 해서 훨씬 큰 작업.

**착수 시점에 판단할 선택지(지금은 고르지 않음)**:
- (a) 위 `PostRef` 스케치대로 진짜 post-pass를 만든다 — (a) 스코프
  (자기 자신 세팅 완료)의 정확한 보장.
- (b) 새 메커니즘 없이 일반 `Ref`로 근사한다 — Store를 통해 늦게
  도착하는 값으로 "대충 렌더 이후"를 흉내내되, "완전한 보장은 없음"을
  문서에 명시하는 선에서 타협.
- (c) 계속 스코프 아웃 — `OnCreated`/`OnDestroyed`만 쓰고 `OnRendered`는
  필요해질 때까지 안 만듦.

## 이름 컨벤션

- **`On` 접두 자체는 이미 선례가 있음** — `base/onchange-plan.md`의
  `OnChange(name)`(`GetPropertyChangedSignal` 바인딩용 DI 키). 단
  **메커니즘은 다름**: `OnChange`는 이름을 인자로 받아 캐시된 키 객체를
  반환하는 **해시 파트 DI 키 팩토리**(`base/onchange-plan.md` "확정"
  절)인 반면, 이 문서의 `OnCreated`/`OnDestroyed`는 **배열 파트에
  놓이는 값(`PreRef`/`EffectHandle`)을 만드는 팩토리**라 이름 패턴만
  같고 소속 카테고리가 다름 — `OnChange` 쪽 "다른 특수 DI 키와의 대조"
  표에 이 둘을 끼워 넣을 필요는 없어 보임(별도 표로 다루는 게 맞음).
- `OnCreated`/`OnDestroyed`는 거의 확정적인 후보 — 다만 v1이 이미
  `OnCreated`라는 이름을 다른 메커니즘(특수 DI 키)으로 썼던 전례가
  있어 위 "①" 절의 대조 설명 없이 이름만 보면 헷갈릴 수 있음, 문서화
  시 명시할 것.
- `OnDestroyed`는 최초 가칭이던 `OnDisposed`보다 사용자가 선호 —
  **최종 이름 결정은 여전히 열려있음.** `OnDisposed`가 제안된 이유는
  미래 `dispose()` 함수(`question.md`
  "0-B. `dispose(any)` — 시그니처/범위")와 이름을 맞추자는 발상이었는데,
  대조해보면 트리거 자체가 다름:
  - `dispose(value)`는 사용자가 **의도적으로** 부르는 명시적 파괴
    API로 설계 중(대상이 아직 트리에 의해 살아있길 요구되면 파괴를
    **거부하고 error**, `question.md` 0-B). "언제 부를지"를 호출자가
    고르는 능동적 경로.
  - 반면 이 문서의 훅은 `Effect`의 leaf-death cleanup에 얹히므로,
    실제 트리거는 **물리 Instance가 죽는 시점**(엔진 `Destroying`
    신호, `bindLifetime`이 감시하는 이벤트)임 — 그 죽음이 `dispose()`를
    거쳤는지, 누가 직접 `:Destroy()`를 불렀는지, reconcile이 알아서
    정리했는지는 이 훅 입장에서 구분도 안 되고 상관도 없음.
  - 그래서 `OnDisposed`는 "`dispose()`를 불렀을 때만 발화한다"는
    잘못된 인상을 줄 위험이 있고, `OnDestroyed`가 실제 트리거(엔진
    `Destroying`)를 더 정직하게 반영함 — **지금 추천은 `OnDestroyed`**.
  - 단 이 판단은 **0-B가 아직 미확정**이라는 전제 위에 있음: 만약
    나중에 `dispose()`가 "Slot뿐 아니라 Instance/Effect까지 포함해
    quad가 만드는 모든 것의 유일한 파괴 경로"로 확정되면(0-B의
    "미확정: 대상 범위" 항목이 그쪽으로 풀리면), 그때는 `dispose()`와
    이름을 맞추는 재검토가 자연스러워질 수 있음.
  - 이름 자체는 런타임에 아무 의미가 없는 순수 네이밍(값은 그냥
    `PreRef`/`EffectHandle`)이라 바꾸는 비용은 0에 가까움 — 그래서
    지금은 위험 부담 낮은 `OnDestroyed`를 잠정 1순위로 두고,
    `dispose()` 범위가 확정되면 재검토하는 게 결론. 최종 결정은
    여전히 사용자 몫.
- `OnRendered`/`PostRef`는 위 "②" 절의 스코프가 아직 안 정해져서 이름도
  가결정 — "렌더"라는 단어가 quad엔 없는 개념(React식 재렌더 루프가
  없음, `base/architecture.md`)이라 `OnRendered`라는 이름 자체가 오해를
  부를 수 있다는 점도 고려 대상. `PostRef`는 `PreRef`와의 대칭성이
  이름에서 바로 읽혀서 유력한 후보.

## 패키지 배치

`Ref`/`PreRef`/`Effect`가 전부 quad-base 프리미티브이므로,
`OnCreated`/`OnDestroyed`는 그 위의 순수 함수일 뿐이라 **quad-base가
자연스러워 보임** — `Operator`/`Fallback`과 같은 결(엔진 지식이 전혀
필요 없는 순수 조합). `OnRendered`/`PostRef`를 실제로 만들게 되면
post-pass 자체는 `Dispatch.drive`(quad-base) 소유가 맞겠지만, 이건 ②가
착수될 때에나 확정할 문제. 최종 판단은 열어둠.

## 우선순위

**형제 백로그 항목들과 동급, 맨 뒤** — `quad-mock`/`quad-debug`/
`Operator`/`Fallback`과 같이 "quad 개발 상당 부분 끝난 뒤"로 볼 것.
`OnCreated`/`OnDestroyed`는 착수 시점에 위 코드 스케치를 그대로 옮기면
될 만큼 단순하지만, 순수 슈가라 없어도 `Ref():Callback(fn)`/
`Effect(fn)`를 직접 쓰면 되므로 기능 격차는 없음. `OnRendered`/`PostRef`는
그 형제들보다도 더 뒤 — 채택 여부 자체가 아직 결정 안 됨(위 ② 절),
백로그 후보로만 존재.

## 열린 질문

**[2026-08-14 세션] `OnRendered` 채택 여부는 이미 답이 나옴 — "지금은
안 함", 그래서 `question.md`엔 안 올림(사용자가 답할 활성 질문이 아니라
그냥 보류된 백로그 후보).** 착수하기로 결정되는 시점에 다시 열어볼
것들만 남음:
- `PostRef`의 정확한 메커니즘/스코프(위 ②의 (a)/(b)/(c) 중 선택,
  선택 시 (a)/(b) 하나 고르면 스코프도 자연히 정해짐).
- 이름 최종 확정 — `OnDestroyed`가 잠정 1순위 후보(위 "이름 컨벤션"
  절의 `OnDisposed` 대조 참고, `dispose()`의 대상 범위(`question.md`
  0-B)가 확정되면 재검토 여지 있음). `OnRendered`/`PostRef`는 착수
  결정 전엔 가결정.
- 패키지 배치 최종 확인(quad-base로 거의 확정적이나 착수 시점 재확인).
- 그 외 확정된 결정 없음 — 착수 시점에 위 항목들을 순서대로 확인.
