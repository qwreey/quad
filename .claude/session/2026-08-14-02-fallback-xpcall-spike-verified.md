# 2026-08-14 두 번째 세션 — `Fallback` 메커니즘 `xpcall` 실측 확인

## 배경

직전 세션(`2026-08-14-01-component-fallback-plan.md`)에서
`research/component-fallback-plan.md`를 신설하며 "`xpcall` 에러 핸들러
배선의 실측 필요"를 열린 질문으로 남겨뒀음. 사용자가 새 워크트리로 이동해
직접 `luau`로 확인해보라고 요청, 메인 체크아웃은 다른 에이전트가 쓰는
동안 워크트리를 벗어나지 말라고 지시.

## 한 일

`.claude/research/component-fallback-xpcall-spike.luau` 스파이크 작성 —
문서의 `Fallback` 의사코드를 그대로 옮겨 `luau`로 10개 검증:

1. 성공 경로 — `onError` 안 불리고 원래 반환값 그대로 통과
2. 실패 경로 — `onError`의 반환값이 최종 결과, 에러 메시지 전달됨
3. 에러 핸들러 안에서 클로저 업밸류(`trace`)에 쓴 값이 `xpcall` 리턴 후
   `onError` 호출 시점에 정상적으로 보임(가장 핵심적인 확인 대상)
4. 3단 중첩 호출(`level1→level2→level3`)에서도 `debug.traceback(nil, 2)`가
   실패 지점(`level3`)까지 정확히 담음, level=2가 익명 에러 핸들러
   프레임을 올바르게 스킵
5. 비-문자열 에러 값(`error({...})`)도 손실 없이 `onError`에 전달됨
6. 문서의 "추가 상태 필요하면 커링" 관용구가 그대로 동작
7. vararg 컴포넌트 시그니처(`(T...) -> Comp`)도 정상 동작

**전부 통과**, `luau-analyze`도 클린(타입 에러 0).

**부수 발견 — 문서에 없던 캐비엇**: `error(msg)`를 레벨 지정 없이(Luau
기본 level=1) 호출하면 `onError`가 받는 메시지에 Luau가 자동으로
`"파일:줄: "` 위치 접두를 붙임 — `Fallback`이 붙이는 게 아니라 `error()`
자체의 기본 동작. `error(msg, 0)`으로 호출하면 접두 없이 순수 메시지만
전달됨. 최초 스파이크 작성 시 이걸 몰라 커링 테스트가 실패했었고
(exact-match assert가 접두 포함 문자열과 안 맞아서), 원인 확인 후 전용
테스트(6번)를 추가하고 기존 assert를 contains 방식으로 고쳐서 재통과시킴
— 테스트 버그가 아니라 실제 Luau 동작이었음을 별도 `pcall` 디버그로
먼저 확인한 뒤 정식 반영.

## 반영

`research/component-fallback-plan.md`:
- 메커니즘 스케치 절에 실측 완료 표시 + 위치 접두 캐비엇 추가
- "열린 질문 — `xpcall` 에러 핸들러 배선의 실측" 항목을 **해소**로 표시
- "프로덕션에서의 동작" 항목에 위치 접두가 raw 정보에 포함된다는 점 추가
- 상단 상태 요약에 스파이크 파일 포인터 추가

`README.md` research 표 갱신. 새로 연 설계 질문 없음 — 백로그
우선순위(맨 뒤, 착수 안 함)는 그대로.

## 워크트리 메모

이번엔 처음부터 필요한 파일(`README.md`/`CLAUDE.md`/`component-fallback-plan.md`/
`doc-check.py`)만 메인 체크아웃(로컬 `main`)에서 복사해 워크트리 안에서
편집 — 직전 세션에서 정정한 원인(`EnterWorktree` 기본값이
`origin/master`에서 갈라치는데 계획 문서는 `SAFETY.md` 때문에 로컬
`main`에만 있음)을 그대로 재확인, 새로 놀랄 것 없었음.
