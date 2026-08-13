# 2026-08-14 열 번째 세션 — `dispose(value)` 시그니처/범위 확정 (`question.md` 0-B 해소)

## 배경

이전 대화(다른 세션이 동시에 작업 중이라 이 세션은 처음엔 읽기 전용으로
시작)에서 사용자가 `question.md` 0-B(`dispose(any)` — 시그니처/범위,
2026-08-13 여섯 번째 세션 신설)에 대해 물었고, 남은 미확정 항목(시그니처,
Slot 외 대상 범위, `unbindLifetime`과의 역할 분담)을 확인하는 것으로
시작했다.

## 1차 논의 — Observer/Effect 범위 관련 오류와 정정

사용자가 먼저 "Observer/Effect는 dispose 범위에서 빼야 한다"는 결론을
제시하며 근거로 "`State<Observer>`/`State<Effect>`가 이미 지원 사양"이라고
주장했다. 어시스턴트는 처음에 이걸 검증하며 `modifier-plan.md`의 "Modifier
필드에 핸들러 계층 값(Ref/PreRef/PostRef/Observer/Effect/Slot/Modifier)이
들어오면 즉시 error" 규칙과 `slot-plan.md`의 Slot 원소 금지 규칙을 근거로
"State<Observer>가 지원된다는 명시적 문서는 없다"고 (잘못) 답했다.

사용자가 "modifier가 왜 나온 말인지 전혀 모르겠다"며 반박 — Modifier
필드 금지 규칙은 이 논의와 무관한 별개 컨텍스트였다. 재조사 결과 사용자
말이 맞았음이 확인됨:

- `base/architecture.md`(Leaf.luau 파일 설명)와 `base/effect-plan.md`가
  이미 **children 배열의 leaf 위치**(`k=number`)에 `Ref`/`PreRef`/`PostRef`
  뿐 아니라 **`Observer`/`Effect`도 명시적으로 지원 대상**으로 확정해뒀음
  (`Dispatch/Leaf.luau`가 `(i:number, v=Observer/Effect)`를 매치).
- `base/source-state-plan.md` "이중 바인딩 금지" 절이 "children 배열에
  Observer를 직접 놓으면 `Dispatch/Leaf.luau`가 매치해 내부적으로
  `bindLifetime(inst, observer)`를 호출한다"고 이미 명시 — leaf 부착이
  곧 `bindLifetime` 호출 그 자체.
- `base/dispatch-core-plan.md`의 `Dispatch/StoreBind.luau`는 "범용,
  엔진 무관"이고 **`k`는 무엇이든 받음** — 즉 children 배열의 `k=number`
  슬롯에도 똑같이 적용되는 일반 재귀 재디스패치 계층이라, `State<Observer>`/
  `State<Effect>`가 그 자리에 놓여도 StoreBind가 실체를 뽑아 재귀
  `Dispatch.process`로 넘기고 `Leaf.luau`가 풀린 값을 매치 — 새 메커니즘
  없이 이미 있는 일반 원칙("모든 (inst,k)는 T든 State\<T\>든 균일하게
  처리")의 자연스러운 귀결.
- Modifier 필드 금지 규칙(`modifier-plan.md:240`)과 Slot 원소 금지 규칙
  (`slot-plan.md:81`)은 **완전히 다른 컨텍스트**(Modifier 자신의 필드,
  `Slot:Add`/`:List`의 CRUD 원소)라 children 배열 leaf 위치와 무관함 —
  어시스턴트가 이 두 컨텍스트를 혼동한 게 오류의 원인이었음.

어시스턴트가 이 오류를 인정하고 정정, `State<Observer>`/`State<Effect>`가
실제로 확정 사양임을 사용자에게 재확인했다.

## 2차 논의 — 모델을 Opus로 올릴지 질문, 반영 시작

사용자가 "모델을 opus로 올리고 반영 시작할까? 너는 어렵게 느껴? 아니면
가능한 정도야?"라고 질문. 어시스턴트는 이번 반영 작업(정해진 패턴을
따라 문서 여러 곳에 확정된 결정을 박아넣는 기계적 작업)이 Sonnet으로
충분하다고 판단해 답변, CLAUDE.md의 "토큰 맥싱" 방침과도 일치한다고
설명. 사용자가 "가능하다면 문서 반영하고, 세션 기록 남겨. 다른쪽 전부
꺼서, 작업해도 좋음. 핸드오버 준비하고 커밋해줘"로 승인.

## 최종 확정 — `dispose(value)`

**범위**: `Slot` + 엔진 객체(`Instance`)만. **`Observer`/`Effect`는
명시적으로 제외**.

- **이유**: Observer/Effect는 children 배열 leaf에서 `bindLifetime`/
  `canExecute`/`unbindLifetime`(GC-native, gcconn 기반)로만 관리되고,
  Slot처럼 "죽는 순간 `elementOwner`/`lengthList`/`sourceList`가
  어긋나는" 트리 부기 자체가 없음. dispose가 막아야 하는 문제(quad 내부
  자료구조 붕괴)가 Observer/Effect에는 원천적으로 발생하지 않아 dispose가
  다룰 이유가 없음. 아무도 안 들고 있으면 그냥 GC, 조기에 끊고 싶으면
  `unbindLifetime`으로 충분.

**시그니처**: `dispose(value: Slot | Instance): ()` —
```lua
function dispose(value)
    if isSlot(value) then
        -- 기존 elementOwner 기반 소유권 판정 재사용: 요구 중이면 error, 아니면 재귀 파괴
        ...
    else
        disposeInst(value)  -- 백엔드 주입 op
    end
end
```

**base/backend 분리**: `isSlot`이 아닌 값은 `disposeInst(inst: any): ()`로
위임 — `base/dispatch-core-plan.md`의 "base가 소유하는 핸들러와 주입되는
엔진 op" 패턴(`addTag`/`removeTag`/`setAttribute`가 선례) 그대로 재사용.
quad-roblox는 `inst:Destroy()`로 구현.

**네이밍 경위**(사용자가 직접 검토): `free()`는 GC-native 언어 맥락과 안
맞아 기각. `Destroy`는 엔진 자체 `:Destroy()` 메소드와 동명이라 사용자가
"그냥 `:Destroy()` 부르는 거 아님?"으로 착각할 위험이 있어 기각. `dispose`
유지.

**`unbindLifetime`과의 역할 분담**: `dispose`는 트리 소유권 부기가 있는
대상(Slot/Instance)이 아직 요구되는데 강제로 죽이려는 시도를 막는 것,
`unbindLifetime`은 Observer/Effect류 GC 앵커의 조기 해제 — 축이 달라
대체 불가.

## 부수 해소 — `OnDestroyed` 이름 재검토 조건 종결

`base/lifecycle-hooks-plan.md`가 "0-B가 'quad가 만드는 모든 것의 유일한
파괴 경로'로 풀리면 `OnDisposed`와 이름을 맞추는 재검토가 자연스러워질 수
있다"는 조건부 열린 항목을 갖고 있었음. 이번 해소로 `dispose()`의 범위가
오히려 좁아지고(Slot+Instance만) Observer/Effect가 제외됐으므로, 그 조건은
**발동하지 않는 쪽으로 영구 종결** — `OnDestroyed`가 최종 이름, 용어 정리
대기열에서도 제외.

## 반영한 문서

- `.claude/question.md` — 0-B 섹션 제거(해소), 0-W만 남은 "결정 대기"
  항목으로 정리, `1. 용어 정리`의 `OnDestroyed` 조건부 항목 제거.
- `.claude/archive/question-resolved.md` — 0-B 결론+근거 추가(원 문서
  형식과 동일하게 "해소됨" 표시, 원문 요약 포함).
- `.claude/base/slot-plan.md` — `dispose(value)` 절 전면 갱신(범위/시그니처/
  disposeInst 위임/네이밍 근거 확정 반영).
- `.claude/base/dispatch-core-plan.md` — "base가 소유하는 핸들러와
  주입되는 엔진 op" 절에 dispose/disposeInst를 재사용 사례로 추가.
- `.claude/base/architecture.md` — `EngineOps.luau` 파일 설명에
  `disposeInst` 추가.
- `.claude/base/lifecycle-hooks-plan.md` — `OnDestroyed` 이름 컨벤션 절과
  "열린 질문" 절 모두 조건 종결로 갱신.
- `ROADMAP.md` — M6 `dispose(value)` 체크리스트 항목에 확정된 시그니처/
  분기 반영, "0-B 미확정" 문구 제거.
- `HUMAN_TODO.md` — 3번 항목에서 0-B를 해소로 갱신.
- `CLAUDE.md` — "지금 할 일" 0번 섹션에서 0-B를 해소로 갱신(0-W만 잔여).
- `.claude/README.md` — `slot-plan.md`/`lifecycle-hooks-plan.md`/
  `dispatch-core-plan.md` 세 행에 이번 세션 반영 내용 추가.

`doc-check.py` ERROR 0 유지 확인(WARN 84, 편집 전과 동일 — 새로 생긴
불일치 없음).

## 참고 — 세션 중 발견한 별개 사실

다른 세션(quad-4a)이 동시에 커밋한 `2c575d9`(PostRef 반영 후 코퍼스
정합성 감사)가 이 세션 시작 시점엔 이미 반영돼 있었음 — 대화 시작
시점의 CLAUDE.md 스냅샷(시스템 리마인더)이 살짝 stale했으므로, 실제
편집 전 `git log`/파일 재확인으로 최신 상태를 다시 잡고 작업함(세션
번호를 "아홉 번째" 다음인 "열 번째"로 올바르게 잡을 수 있었던 것도 이
재확인 덕분).
