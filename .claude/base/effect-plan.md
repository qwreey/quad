# Effect — 설치 + 확정 정리, `state` 있으면 Observer를 감싸 재실행도 지원

**상태**: base — `research/additional-primitives-plan.md`(다른 프레임워크
대비 갭 분석)에서 갈라져 나온 확정 프리미티브. `base/blocker-plan.md`(같은
조사에서 나온 다른 확정 프리미티브)와는 서로 무관 — Store/State 작업이나
Ref/PreRef와 파생 관계는 아니라 별도 파일로 둔다(2026-08-07 문서 정리에서
한 파일로 합쳤던 걸 다시 분리). 단 `state` 인자를 받는 형태는 내부적으로
Observer를 조합해서 만들어짐(아래 참고, 2026-08-07 여섯 번째 세션 확정) —
"Observer와 무관한 완전 독립 프리미티브"였던 이전 서술은 정정됨.

**Effect와 Observer의 관계 확정(2026-08-07 여섯 번째 세션)**: 별개의
독립 프리미티브이되, `state`를 받는 형태의 Effect는 내부적으로 Observer를
**조합(compose)**해서 만들어짐 — Ref/PreRef처럼 브랜드 태그만 다른 재사용이
아니라, Observer(재실행 신호) 위에 자동 cleanup 배선을 얹은 한 단계 위
계층. **자유 함수인 이유는 여전히 유효**: `state` 없이도 성립하는
mount/unmount 전용 유스케이스가 있고, 실제 leaf 생명주기 바인딩은 (Observer와
마찬가지로) children 배열 위치에 거는 것이라 `state`가 그 바인딩을 소유하지
않음 — Roblox엔 `task.spawn`으로 코루틴에 반복문/타이머를 돌리는 패턴이
흔하고, Luau 테이블엔 `__gc` 같은 GC 시점 훅이 없어서 "이게 진짜 사라지는
순간"을 아는 유일한 방법은 `Instance.Destroying`류 명시적 신호뿐 — 이런
케이스(타이머 시작 → leaf가 죽을 때 반드시 정지)를 위한 별도 primitive로
합의됨.

```
Effect(fn, state?) -> EffectHandle
```

**`state` 생략 시**: `fn()`을 즉시 1회 실행, 리턴값(`nil | () -> ()`)은
이 Effect가 바인드된 leaf가 죽을 때 정확히 1회 호출. 재실행 없음
(mount/unmount 전용, React `useEffect(fn, [])`와 동형).

**`state` 지정 시(2026-08-07 여섯 번째 세션 확정)**: Effect는 내부적으로
`state:Observer(...)`를 감싸는 걸로 구현 — `fn`은 포지셔널 인자로 `state`를
받고(`fn(state)`, `:Compute`의 `fn(self)` 포지셔널-self 패턴 재사용,
모듈화 목적 — 클로저 캡처 없이 `fn`을 독립적으로 정의/재사용 가능),
Observer가 이제 등록 즉시 1회 실행되므로(아래 Observer 절 참고) 그 첫
실행이 "설치"를 겸함. 이후 `state`가 무효화될 때마다 **직전 `fn` 호출이
리턴한 cleanup을 먼저 호출한 뒤 `fn`을 재호출**, 그리고 Effect가 바인드된
leaf가 죽을 때 **마지막 cleanup을 한 번 더 호출**. 결과적으로 React
`useEffect(fn, [dep])`와 동형(설치+재실행 사이/최종 cleanup 전부 같은
반환 계약 하나로 처리).

- **다수 의존성은 `:With(...)`로 먼저 하나의 State로 묶어서 넘길 것** —
  React식 별도 deps 배열을 새로 만들지 않음, quad가 이미 가진 다중 의존성
  결합 관용구(`base/bind-system-plan.md` "`:With` + `:Compute`" 절)를
  그대로 재사용해 같은 일 하는 두 번째 경로를 안 만듦.
- **`fn`은 커링 스타일도 권장(2026-08-07 여섯 번째 세션, 사용자 제안)** —
  `Effect(makeLogger("mount"), state)`처럼 팩토리 함수가 실제 `fn(state)`를
  만들어 반환하는 패턴, `Modifier`의 `Boldify(10)` 커링 관용구(`modifier-plan.md`
  8번)와 같은 결. `state:Observer(fn)`도 동일하게 커링 스타일을 권장 대상으로
  같이 문서화(아래 Observer 절 참고) — 모듈화가 필요하면 둘 다 이 패턴을 쓸 것.
- **재실행이 필요 없는 케이스와 혼동하지 말 것**: 값 변화와 무관하게 설치+최종
  정리만 필요하면 `state` 없이 `Effect(fn)`을 씀 — `state`를 굳이 넘겨서
  재실행을 유발할 필요 없음.

children 배열에 leaf로 놓는 기존 Observer 바인딩 패턴을 그대로 재사용(그
leaf가 살아있는 동안만 유효, leaf가 죽으면 최종 정리 콜백 호출). 비용은
leaf당 실제 Destroying 바인딩 하나(공유 weak table로 되는 Observer보다
비쌈) — 필요할 때만 쓰는 걸로 충분.

**Observer 자체에 cleanup 반환 계약을 추가하는 안은 여전히 기각** — React
`useEffect`류로 `fn`이 `nil | () -> ()`를 반환하면 다음 재실행 직전에 그걸
불러주는 안을 검토했으나, 클로저 업밸류로 이미 쉽게 되고 잘 작동해서(`local
lastConn; state:Observer(function() if lastConn then lastConn:Disconnect()
end; lastConn = ... end)`) **Observer 자체**가 이걸 대신해줄 이유는 여전히
약함. **이 기각과 위 Effect 설계는 상충하지 않는다** — 그때 기각한 건
"Observer 자체에 이 복잡도를 넣지 말자"였지 "이 패턴 자체가 무용하다"가
아니었음. 자동 cleanup 배선이 필요한 사람만 opt-in으로 쓰는 별도 계층
(Effect)으로 분리해 얹었을 뿐, Observer의 기본 계약(재실행 신호만, cleanup은
클로저로 직접)은 그대로 가볍게 유지됨.

## 해결됨 — Effect/Observer 관계 (2026-08-07 여섯 번째 세션, 이전 미해결 절 대체)

**과거 미해결이었던 두 질문 모두 확정**:
1. Effect는 자유 함수로 확정(`state:Effect(fn)` 메소드 아님) — 위 "Effect와
   Observer의 관계 확정" 절 참고. `state` 인자가 있어도 실제 leaf 생명주기
   바인딩을 `state`가 소유하지 않아서 메소드로 만들 필연성이 없었음.
2. `state:Observer(fn)`는 등록 즉시 1회 실행되는 것으로 확정(`base/
   bind-system-plan.md`의 Observer 절 참고) — 이 덕에 Effect가 `state`를
   받을 때 Observer를 그대로 조합해 재사용할 수 있게 됨(별도 "설치 시
   1회 실행" 로직을 Effect가 따로 만들 필요 없음).

`.claude/question.md` 0번의 관련 항목도 해소됨으로 갱신 완료.
