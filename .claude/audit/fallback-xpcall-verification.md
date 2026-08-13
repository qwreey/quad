# `Fallback`/`Traceback` — `xpcall`+`debug.traceback` 배선 실측 결과

**상태**: 전부 확인(2026-08-14). `base/fallback-plan.md`의 `Traceback`
메커니즘 스케치가 실제 Luau에서 그대로 동작하는지 `luau` 스파이크
(`fallback-xpcall-spike.luau`, 같은 폴더)로 검증 — 10개 검증 전부 통과,
`luau-analyze`도 클린(타입 에러 0).

## 배경

`base/fallback-plan.md`(당시엔 research/ 초안) 단계에서 열어뒀던 질문:
`xpcall`의 에러 핸들러 안에서 클로저
업밸류에 쓴 값(`trace`)이 `xpcall` 리턴 이후에도 바깥에서 정상적으로
보이는지, `debug.traceback`이 에러 시점 스택을 정확히 담는지 — 의사코드
수준이라 Luau로 직접 부딪혀본 적 없었음.

## 확인된 것

1. **성공 경로** — `onError`가 아예 안 불리고 `base`의 원래 반환값이
   그대로 통과함.
2. **실패 경로** — `onError`의 반환값이 최종 결과, 에러 메시지가
   `onError`에 정상 전달됨.
3. **클로저 업밸류 배선(가장 핵심)** — `xpcall`의 에러 핸들러 안에서
   업밸류 `trace`에 쓴 값이 `xpcall` 리턴 후 `onError` 호출 시점에
   정상적으로 채워져 있음.
4. **중첩 호출에서의 `debug.traceback`** — 3단 중첩(`level1→level2→level3`)
   호출에서도 `debug.traceback(nil, 2)`가 실패 지점(`level3`)까지 정확히
   담음. `level=2`가 익명 에러 핸들러 프레임 자체를 올바르게 스킵.
5. **`err: any`** — 비-문자열 에러 값(`error({code=42})`류 table)도
   손실 없이 `onError`에 그대로 전달됨. 사용자가 별도로 Luau REPL에서
   `error({aa=true})` → `pcall`로 잡은 뒤 `b.aa == true`를 직접 재확인,
   스파이크 결과와 일치.
6. **커링 관용구** — `onError` 자체를 클로저로 만들어 추가 컨텍스트를
   캡처하는 관용구가 `Fallback`/`Traceback` 쪽 손댈 것 없이 그대로 동작.
7. **`error(msg)`의 기본 위치 접두(신규 발견)** — 레벨 지정 없이
   (Luau 기본 level=1) `error("메시지")`를 호출하면 `onError`가 받는
   `err`엔 `"파일:줄: 메시지"`처럼 위치 접두가 자동으로 붙음.
   `error(msg, 0)`으로 호출해야 접두 없는 순수 메시지가 옴 — quad가
   붙이는 게 아니라 Luau `error()` 자체의 기본 동작.
8. **vararg 컴포넌트 시그니처** — `(Args...) -> Comp` 모양(여러 인자를
   받는 컴포넌트 함수)도 성공/실패 경로 둘 다 정상 동작.

## 실측 방법

`fallback-xpcall-spike.luau`(같은 폴더) — `base/fallback-plan.md`의
`Traceback` 의사코드를 그대로 옮겨 10개 assert로 검증.
`luau fallback-xpcall-spike.luau`로 실행,
`luau-analyze fallback-xpcall-spike.luau`로 타입 체크(무출력 = 클린).

## 참고

`Fallback`(순수 `pcall`, trace 없음) 쪽은 `Traceback`보다 메커니즘이
단순(에러 핸들러/업밸류 배선이 아예 없음)해서 별도 스파이크 없이도
`pcall` 자체의 기본 동작(성공/실패 경로, `err: any` 통과)으로 충분히
갈음됨 — 위 5번 확인이 그대로 적용됨.
