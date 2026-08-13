# 이벤트 바인딩 — self 미전달, `false`로 disconnect

> **[2026-08-13 여덟 번째 세션] `bind-system-plan.md`에서 분리됨.**
> 사용자가 "이벤트 연결은 다른 base 문서가 되어야 할 듯"이라고 직접
> 지목한 부분. **내용은 옮기기만 했고 결정은 하나도 안 바뀜.**

**상태**: base — 확정.

**여기 없는 이벤트 관련 결정 하나**: 이벤트 *네이밍* 인체공학
(`On.EventName` 도트액세스를 안 쓰고 평범한 문자열 키 + reflection을
쓰기로 한 것)은 인스턴스 생성 관례와 한 절에 섞여 있어
`base/bind-system-plan.md` "인스턴스 생성 / 이벤트 네이밍 인체공학"
절에 그대로 뒀음 — 쪼개면 인스턴스 생성 쪽 서술이 반토막 나서.
`GetPropertyChangedSignal` 바인딩은 별도 문서 `base/onchange-plan.md`.

## 이벤트 핸들러는 self(Instance)를 받지 않는다 — 확정 (2026-08-06)

**결정**: v1의 `function(self, ...)` 관습(`self`/`this`로 이벤트 대상
Instance를 넘겨주는 것, `.claude/reference/quad-v1-architecture.md` 참고 —
실제로 `event.lua`의 `Bind`가 `func(self or this, ...)`로 넘겨줌)은
**채택하지 않는다.** quad-roblox의 이벤트 핸들러는 엔진이 네이티브로
주는 이벤트 인자만 받는다(React의 `onXxx`가 DOM 노드가 아니라
SyntheticEvent만 주는 것과 같은 모양).

**근거**:
1. **Ref가 이미 이 자리를 채움.** "생성 직후/마운트 후 ref 채우기"가 되는
   순간 Instance 접근이 필요하면 클로저 캡처로 해결됨(위 Ref 절) — self는
   그와 중복되는 두 번째 채널일 뿐이고, 두 채널이 있으면 "어느 쪽이
   authoritative냐"는 질문이 항상 따라붙음.
2. **thin wrapper를 제공하면 엔지니어링 구조 자체가 바뀜.** self로 얻는
   값이 mutable한 재바인드 가능 wrapper라면, 그건 Modifier의 정적
   flatten(`base/modifier-plan.md`)과 항상 경쟁하는 두 번째 쓰기 경로가
   생긴다는 뜻 — flatten된 뒤엔 wrapper 쪽에서 "이전 modifier가 뭐였는지"
   재구성할 방법이 없음. Modifier 핸들러가 KV 매치 기반이라는 걸 감안하면,
   wrapper 값을 처리하려면 핸들러가 "이게 flatten된 정적 값이냐, 아니면
   언제든 바뀔 수 있는 wrapper냐"를 매번 분기해야 함 — 오버엔지니어링이고
   hot path(매 `process` 호출)에 분기 비용이 붙음. 반대로 raw Instance를
   그대로 주는 선택지도 있지만, 그러면 quad가 스스로 지양하는 "quad가
   모르는 직접 mutate 경로"를 공식 API로 만들어주는 셈이라 (3)과 충돌.
3. **디버깅 관점에서 더 결정적.** quad-debug의 가치 제안이 "무엇이
   무엇에 연결됐는가"를 선언된 반응형 그래프로 추적하는 것인데
   (`research/debug-tooling-plan.md`), self로 얻은 Instance를 이벤트
   핸들러 안에서 직접 mutate하는 경로는 그 그래프 밖 — `base/
   purity-and-effects-plan.md`의 "재사용 가능한 컴포넌트는 store만
   파라미터로 받아야 한다"는 이식성 원칙과도 같은 결.
4. **성능/GC**: self를 넘겨주려면 원본 콜백을 클로저로 한 번 더 감싸야
   함(`event:Connect(function(...) func(self, ...) end)`) — Connect마다
   불필요한 클로저 할당 비용이 들고, 최적화에도 GC 흐름에도 좋을 게
   없음. self가 없으면 사용자가 준 함수를 그대로 `:Connect`에 넘기면
   충분함. quad는 어차피 라이프사이클 끝까지 바인딩을 들고 있으므로
   (`base/lifecycle-pattern.md`, rbvm 선례 — GC-native), Destroy되면
   해당 Connection도 자연히 같이 정리됨 — 별도 Disconnect 관리가 애초에
   불필요. **[정정, 2026-08-06 후속 세션] 동적으로 Connect/Disconnect를
   반복하고 싶은 케이스는 Ref로 수동 처리하는 대신 store-bind로 네이티브
   지원하기로 확정** — 아래 "이벤트도 store-bind 가능 — `false`로
   disconnect" 절 참고. 엔지니어링 비용이 예상보다 훨씬 낮다는 게 나중에
   확인됨(기존 store-bind 재실행 래핑을 그대로 재사용, 새 디스패치
   메커니즘 불필요).

**일반화**: 이 논거의 핵심은 Roblox에 국한되지 않는 원칙으로 정리됨 —
"엔진이 네이티브로 콜백에 뭘 주든, quad는 그걸 감싸지 않고 그대로
호출해줘도 무방하다"는 것. 다만 이벤트 등록 자체가 quad-roblox에만
있는 개념이라(다른 백엔드는 이벤트 모델이 다를 수 있음) 이건 base
문서가 아니라 quad-roblox 로컬 결정 — 다른 백엔드 구현체를 만들 때
참고할 만한 템플릿 정도로만 취급.

## 이벤트도 store-bind 가능 — `false`로 disconnect (2026-08-06 후속 세션)

**결정**: 이벤트 핸들러 값으로 State를 넘기는 것(reactive하게 콜백을
바꿔치기/해제하는 것)을 지원한다. quad-roblox 로컬 결정, base 변경 없음.

**엔지니어링 비용이 낮은 이유**: 이미 확정된 "Store 바인드는 pluggable
바인드를 재실행하는 래핑"(위 절, 핸들러의 `process`가 값이 바뀔 때마다
`Dispatch.process(inst,k,realv)`를 재귀 호출) + "재실행 래핑이 `retract`도
같이 호출한다"(Slot이 이미 이 조합을 씀, 같은 절)는 두 메커니즘이 이미 있음.
이벤트 핸들러가 할 일은 딱 하나: `process`에서 `:Connect()`한 Connection을
`process`의 로컬 변수로 들고, 반환하는 retract 클로저가 그걸 upvalue로
캡처해 `:Disconnect()`하는 것 — 새 디스패치 메커니즘 발명 필요 없이 기존
계약(`isHandlable`/`priority`/`process`)만 제대로 구현하면 됨(**[2026-08-13
다섯 번째 세션]** 예전엔 별도 `retract` 필드 + per-instance `Relate`
저장소였으나, 클로저 캡처로 저장소 자체가 불필요해짐).

**`false`로 disconnect, `nil` 아님.** `nil`은 Lua 테이블에서 "키가 아예
없음"과 구별이 안 됨(`pairs`에서도 안 보임) — "명시적으로 꺼짐"이라는
신호를 값으로 전달하기엔 부적합. 대신 `false`(Luau에서 실재하는 싱글톤
타입)를 "연결 없음" 센티널로 씀: `process(inst,k,false)`가 들어오면
`retract`가 하던 일(기존 Connection 해제)만 하고 새로 Connect 안 함.
이벤트인지 여부는 값이 아니라 키(리플렉션으로 판별)로 결정되므로, 다른
boolean 프로퍼티 핸들러와 `(k, false)` 매칭이 겹칠 위험 없음.

**quad가 미는 기본 패턴은 아님 — 부차적 옵션.** 저빈도 UI 이벤트(클릭류)를
조건부로 켜고 끄고 싶은 흔한 케이스는 사실 이 메커니즘 없이도 됨 — 핸들러
하나를 계속 연결해두고 안에서 분기하면 끝:

```lua
MouseButton1Click = function()
    if not store.enabled:Get() then return end
    ...
end
```

이 "핸들러 하나 + 내부 분기" 패턴이 Connect/Disconnect 자체가 없어서 더
싸고, Roblox/React 어디서든 이미 익숙한 관용구라 **기본 권장 패턴**.
store-bind 방식이 실제로 값어치 있는 지점은 고빈도 신호(Heartbeat/
RenderStepped/마우스 무브처럼 안 쓸 때 Connection을 살려두는 것 자체가
낭비인 경우)나, 단순 on/off가 아니라 로직 자체가 바뀌는 드문 케이스.
자주 재계산되는 State에 이벤트를 직접 물리면 매 재계산마다 Disconnect+
Connect가 도는 숨은 churn 비용도 있음(Store Set은 dedup 안 함,
`store-semantics.md`) — 그래서 남용하지 말라는 캐비엇.

**그래도 일관성 있게 지원은 해둠.** "저빈도엔 필요 없다"가 "그러니 예외로
빼고 못 하게 막자"로 이어질 이유는 없음 — 프로퍼티/태그/어트리뷰트가
전부 store-bind되는데 이벤트만 특별 취급해서 뺄 근거가 약하고, 구현
비용도 낮으니(위 "엔지니어링 비용이 낮은 이유" 참고) 일관되게 지원해두는
쪽을 택함. 그냥 "이런 것도 가능하다" 정도로 존재하고, quad가 이 패턴을
적극 권장하진 않는다는 톤으로 문서화(`research/documentation-plan.md`
3번 "권장 이벤트 핸들링 패턴" 문서에 이 대조까지 반영 예정).

