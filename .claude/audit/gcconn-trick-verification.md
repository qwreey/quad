# gcconn 트릭 — 부분 실측 검증 결과

**상태**: 부분 확인(2026-08-13). `10-roblox-studio-checks.server.luau`(현재
`luau-test/rewrite-required/`)의 공식 스크립트가 아니라 사용자가 별도로
작성한 저수준 검증 스크립트로 확인됨 — `bindLifetime`/`unbindLifetime`
자체의 이중 바인딩 로직과 Part B/C는 여전히 미검증. **아래 "아직 확인 안
된 것"이 전부 해소되기 전까진 공식 `10` 파일을 완주한 것으로 치지 말 것.**

**[2026-08-14 다섯 번째 세션] 아래 실측 결과 자체는 전부 그대로 유효하고,
오히려 더 중요해졌음** — `bindLifetime`/`canExecute`/`unbindLifetime`
재정정으로 `canExecute(value)`가 **`value` 쪽 릴레이션에 복사된 gcconn의
`.Connected`를 직접 읽는 것**이 leaf 경로 생존 판정의 전부가 됐기 때문
(`base/lifecycle-pattern.md`의 "`bindLifetime`/`canBound`/`canExecute`/
`unbindLifetime` — 확정" 절). **[재정정, 2026-08-14 열한 번째 세션] `canBound`는 폐기되지
않고 별도 진입점으로 재도입됨** — 이중 바인딩 게이트(`bindLifetime`/
`Observer:Subscribe()`)는 `canBound`, State emit 전파 게이팅만
`canExecute`(판정 로직은 비공개 헬퍼 하나를 공유, `base/lifecycle-pattern.md`의
"`canBound` vs `canExecute`" 절) — 공식 `10` 파일은 이 재분리도 반영해
재작성해야 함, 계속 `rewrite-required/`에 있음. 역전 경위는
`archive/canexecute-inst-arg-reversed.md`(추가된 절 포함).

## 배경

`base/lifecycle-pattern.md`의 `bindLifetime`/`canExecute` 구현은 두 가지
Roblox 엔진 의존 가정에 기대고 있고, 둘 다 문서만으로는 확정할 수 없어
Studio 실측이 필요했음:

1. `GetPropertyChangedSignal("ClassName")`은 절대 발화하지 않는다(엔진이
   `ClassName`을 변경 불가능한 프로퍼티로 취급하므로 — 콜백 클로저가
   `gchold`를 업밸류로 캡처해 살려두는 용도로만 씀).
2. `RBXScriptConnection.Connected`는 `inst:Destroy()` 시점에 GC를 기다릴
   필요 없이 동기적으로 즉시 `false`로 바뀐다 — `canExecute`가 이 값
   하나로 생존을 판단하므로, 이게 틀리면 설계 전체가 무너짐.

`luau-test/README.md`는 이 스파이크(`10`의 A 섹션)가 실패하면(신호 발화
또는 재바인딩 게이트 실패) "gcconn 트릭 전체를 재검토해야 하는 심각한
발견"이라고 못 박아둔 상태였음.

## 실측 방법

Studio에서 실행된 사용자 자작 스크립트(공식 `10` 파일이 아님) — 요지:

- `weak = setmetatable({}, {__mode="v"})`에 target을 담아 GC 생존 여부 관찰.
- `inst:GetPropertyChangedSignal("ClassName"):Connect(...)`로 gcconn
  트릭과 동일한 신호를 구독, 콜백 클로저가 `target`을 업밸류로 캡처.
- Connection을 변수로 안 잡는 경우(Test 1)와 잡는 경우(Test 2) 둘 다 확인.
- `triggerGC()`로 GC 완료를 간접 관찰(기법 상세는
  `gc-trigger-helper.server.luau`, `luau-test/not-run/` — 이 헬퍼는 그대로
  `not-run/`에 있음).

## 확인된 것

1. **`ClassName` PropertyChangedSignal 미발화** — 6 epoch(각 GC 사이클)
   동안, 그리고 `Destroy()` 전후 모두 `warn`이 한 번도 안 뜸. 트리거
   조건 1(신호 발화)은 회피 확인.
2. **연결이 살아있는 동안 콜백 클로저가 캡처한 값이 GC 안 됨** — Test 1/2
   둘 다 `weak[1]`이 6 epoch 내내 살아있음. `lifecycle-pattern.md`의
   "gcconn/gchold는 Instance 생성 시점에 만든다" 주장과 일치. **[2026-08-14 세 번째
   세션]** 이 스크립트가 실제로 업밸류로 캡처한 값이 `target`(=Instance)
   자체였다는 점에서, 새 모델이 요구하는 **"클로저가 `gchold`뿐 아니라
   `inst`까지 캡처해 userdata 동일성을 고정한다"**는 조치의 전반부도 같이
   뒷받침됨 — 다만 "같은 엔진 객체를 다시 얻었을 때 userdata가 동일한가"
   자체는 이 스크립트가 확인한 바 없음(아래 미확인 목록).
3. **`Connection.Connected`가 `Destroy()` 직후 동기적으로 `false`로 전환**
   — GC를 기다리지 않고 즉시 확인됨(Test 2). `canExecute(value)`의 유일한
   하드 의존성이 실측으로 확인됨. **[2026-08-14 다섯 번째 세션]** 재정정
   이후 이 항목의 무게가 더 커짐 — `canExecute`는 이제 `value` 쪽
   릴레이션에 복사된 gcconn의 `.Connected` **하나만** 보고 leaf 경로
   생존을 판정하므로(`inst`를 조회하는 경로가 아예 없음), 이 전환이
   즉발이 아니면 죽은 `inst`에 처리를 시도하는 것을 막을 방법이 없음.
4. **Destroy 이후 GC를 한 번 더 돌리면 클로저가 캡처했던 값이 실제로
   수거됨** — `conn` 변수 자체는 스크립트 스코프에 여전히 남아있어도
   (Connection 객체 자체는 안 죽음), disconnect되면 콜백의 upvalue 참조는
   놓아준다는 것도 확인 — 메모리 누수로 안 남는다는 근거.

## 아직 확인 안 된 것

- **이중 바인딩 게이트 + unbind/Destroy 후 재바인딩 허용** — `bindLifetime`/
  `unbindLifetime` 로직 자체는 이 스크립트에 없음(순수 GC/Connection
  메커니즘만 테스트함). **[2026-08-14 열한 번째 세션 재갱신, 2026-08-18
  방향 정정]** 게이트는 `canBound(value)`이고(`if not canBound(v) then
  error(...) end` — `canBound` 참 = "지금 묶어도 됨", `canExecute`는
  emit 게이팅 전용으로 분리되며 둘은 서로의 부정 —
  `lifecycle-pattern.md` "`canBound` vs `canExecute`" 절),
  검증해야 할 명제는 안 바뀜: (a) 살아있는 바인딩을 가진
  값을 다시 `bindLifetime`하면 error, (b) `unbindLifetime(value)` 후에는
  통과, (c) **`inst`가 Destroy된 뒤에도 통과**(모델이 명시적으로 허용).
  전부 미해소이고, 공식 `10` 파일은 **재작성 후에야** 이걸 확인할 수
  있음(현재 `luau-test/rewrite-required/`).
- **`bindLifetime`이 복사해둔 gcconn만으로 판정이 성립하는가** —
  **[2026-08-14 다섯 번째 세션 신규]** `canBound`/`canExecute`가 `inst`를
  안 받고 `BindData:GetWeak(value, "gcconn")` 하나로 생존을 판정하는
  경로 자체는 아직 실측된 적 없음(위 3번은 gcconn을 `inst` 쪽에서
  직접 들고 있는
  형태로 확인한 것). weak 릴레이션에 복사해둔 참조가 gchold 사망 후
  기대대로 비워지는지도 같은 항목.
- **Instance userdata 포인터 동일성** — **[2026-08-14 다섯 번째 세션 신규]**
  "Lua 쪽 강참조를 안 들고 있으면 나중에 같은 엔진 객체에서 다른
  userdata가 나올 수 있다"는 전제(gcconn/gchold를 Instance 생성 시점에
  만들기로 한 이유, `inst`-키 `Relate` 전체가 여기 기대고 있음)는 아직
  미검증.
- **Part B (Attribute의 Instance 참조 타입 지원)**, **Part C
  (CollectionService 태그/`GetTagged` 왕복)** — 미실행.
- **`inst` 자체를 `__mode="k"` weak key로 쓰는 경로** — 실제 `Relate`
  구조(`base/relate-plan.md`)는 바깥 테이블이 `inst`를 weak key로 잡는데,
  이 스크립트는 `__mode="v"` + 정수 리터럴 키만 썼음. `inst`가 다른 곳에서
  안 참조되면 relate 엔트리(gcconn/gchold/value 전체)가 실제로 죽는
  경로는 미검증 — `canExecute`가 `.Connected`만으로 정확히 동작하는 한
  정합성보다는 메모리 누수 방지 쪽 문제라 상대적으로 덜 치명적이지만,
  완전히 별개 항목이니 열어둘 것. weak-key-on-table 자체는
  `07-relate-weak-table-gc.luau`가 순수 luau CLI에서 이미 확인했음 —
  Instance가 plain table과 동일하게 weak key로 동작하는지는 아직 별개로
  미확인.

## 부수 발견 — Roblox Studio에서도 GC 완료를 간접 관찰 가능

`07-relate-weak-table-gc.luau`의 기존 서술("Roblox 실제 게임 스크립트
환경에는 `collectgarbage()`가 노출되지 않아 GC 타이밍 검증이 불가능,
그래서 순수 luau CLI에서만 해야 함")은 **"명시적 `collectgarbage()` API가
없다"는 부분은 여전히 맞지만, "그래서 Studio에서 GC 검증 자체가 불가능하다"는
결론은 이번에 반증됨** — weak-value 테이블에 canary를 넣어두고
할당 압력(`table.create` 반복)을 걸며 `task.wait`로 기다리면, incremental
GC가 실제로 완료되는 시점을 간접 관찰 가능함(사용자가 이번 검증에서
확인). `07`의 docstring과 이 기법 자체는 `gc-trigger-helper.server.luau`(`luau-test/not-run/`)로
분리해뒀음 — Studio 기반 스파이크(`10` 등)가 GC 완료를 기다려야 할 때
그 파일의 `waitForGC`를 그대로 복붙하면 됨.

## 다음 확인 시 참고

**[2026-08-14 다섯 번째 세션 갱신] 공식 `10`은 그대로 돌리면 안 됨** — A
섹션이 폐기된 모델(`canBound`, `bindLifetime`의 `.Subscribed` 세팅, 2-인자
`canExecute`)을 검증 중이라 `luau-test/rewrite-required/`에 있음. 순서는
**A 섹션 재작성 → Studio 실행**.

- 이 문서의 "확인된 것"과 겹치는 A 섹션 앞부분(ClassName 신호 미발화,
  Destroy 시 `Connected` 즉시 전환)은 다시 안 봐도 됨 — 단 **재작성 시
  이 두 검증은 반드시 남길 것**(새 모델에서 `canExecute`의 유일한 근거).
- 반드시 실제로 돌려봐야 하는 것은 위 "아직 확인 안 된 것" 전부 —
  `canExecute` 게이트 3케이스(a/b/c), `value` 쪽 복사 gcconn만으로의 판정,
  Instance userdata 동일성, 그리고 손 안 댄 Part B/C.
