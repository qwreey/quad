# Effect — leaf 죽음에 확정 정리, 재실행 개념 없음

**상태**: base — `research/additional-primitives-plan.md`(다른 프레임워크
대비 갭 분석)에서 갈라져 나온 확정 프리미티브. `base/blocker-plan.md`(같은
조사에서 나온 다른 확정 프리미티브)와는 서로 무관 — Effect는 Store/State
작업이나 Ref/PreRef와도 파생 관계가 아닌 완전히 독립된 요소라 별도 파일로
둔다(2026-08-07 문서 정리에서 한 파일로 합쳤던 걸 다시 분리).

**Observer와는 별개의, 완전히 새로운 요소로 확정** — Ref/PreRef 같은
서로 파생된 관계가 아니라 독립적으로 존재하는 primitive. Roblox엔
`task.spawn`으로 코루틴에 반복문/타이머를 돌리는 패턴이 흔하고, Luau
테이블엔 `__gc` 같은 GC 시점 훅이 없어서 "이게 진짜 사라지는 순간"을 아는
유일한 방법은 `Instance.Destroying`류 명시적 신호뿐 — 이런 케이스(타이머
시작 → leaf가 죽을 때 반드시 정지)를 위한 별도 primitive로 합의됨.

```
Effect(fn) -> EffectHandle   -- fn을 즉시 1회 실행, 리턴값(nil | () -> ())은
                              -- 이 Effect가 바인드된 leaf가 죽을 때 정확히 1회 호출
```

**재실행 개념이 없다** — 값 변화에 반응해 다시 도는 건 Observer(+클로저로
직접 짠 cleanup)의 영역이고, Effect는 순수하게 "설치 + 확정 정리" 페어
하나만 담당한다. children 배열에 leaf로 놓는 기존 Observer 바인딩 패턴을
그대로 재사용(그 leaf가 살아있는 동안만 유효, leaf가 죽으면 정리 콜백
호출). 비용은 leaf당 실제 Destroying 바인딩 하나(공유 weak table로 되는
Observer보다 비쌈) — 필요할 때만 쓰는 걸로 충분.

**Observer에 cleanup 반환 계약을 추가하는 안은 기각됨** — React `useEffect`류로
`fn`이 `nil | () -> ()`를 반환하면 다음 재실행 직전에 그걸 불러주는 안을
검토했으나, 클로저 업밸류로 이미 쉽게 되고 잘 작동해서(`local lastConn;
state:Observer(function() if lastConn then lastConn:Disconnect() end;
lastConn = ... end)`) 프레임워크가 이걸 대신해줄 이유가 약하다는 판단 —
`state:Observer(fn)` 자체는 여전히 재실행 계약만 갖고, Effect가 별도로
"1회 설치 + 확정 정리"를 담당하는 이 분리 구조가 유지됨.

## ⚠️ 미해결 — Effect와 Observer의 관계, 사용자 확인 필요

**임의로 결론내지 않고 열어둠(2026-08-07 문서 정리 세션)**: 위 스펙은
`Effect(fn)`를 State에 종속되지 않는 완전한 자유 함수로 서술하지만, 아래
두 가지가 문서상 명확히 확인되지 않음:

1. **`Effect`가 실제로는 `state:Effect(fn)`처럼 State의 메소드(=Observer의
   변형, "재실행 없음 + 확정 정리 추가"만 다른 버전)로 구현/노출되어야
   하는 것 아닌가?** — 그렇다면 "독립 존재 가능한 프리미티브 vs 원천에
   종속된 파생 데이터"(`base/store-semantics.md`) 분류상 Effect도
   Observer처럼 후자(자유 함수 생성자 없음, 항상 `:` 메소드)로 재분류해야
   함. 지금 이 문서는 이전 조사(`research/additional-primitives-plan.md`)를
   따라 자유 함수로 서술했지만, 이게 최종 확정인지는 불명확.
2. **`state:Observer(fn)`가 생성 시점에 `fn`을 즉시 1회 실행하는지가 문서
   어디에도 명시돼 있지 않음** — `base/bind-system-plan.md`의 Observer
   절은 "값을 안 실어줌, `fn` 본문에서 `Get()`을 다시 읽어야 함"만
   명시할 뿐 "생성 즉시 1회 호출되는지"는 다루지 않는다. Effect는
   "즉시 1회 실행"이 스펙에 명시돼 있어 이 부분만 보면 둘이 겹쳐
   보인다.

이 두 질문이 풀리면 Effect가 (a) 완전히 별개인 자유 함수 primitive로
남는지, (b) `state:Effect(fn)`로 Observer 계열에 합류하는지가 갈린다.
**확인 전까지는 위에 적은 자유 함수 스펙을 잠정 스펙으로 두되, 구현
착수(M3~M4 전후) 전에 반드시 사용자와 다시 확인할 것** — `.claude/
question.md`에 같은 항목 등재됨.
