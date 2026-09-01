# 스파이크 `10` 완주 실측 — 생명주기 프리미티브 전량 + Attribute Instance 참조 + CollectionService

**상태**: 완료(2026-09-01). `luau-test/done/10-roblox-studio-checks.server.luau`
(실측 당시 `rewrite-required/`에서 A 섹션을 현행 모델로 재작성한 직후)를
**Studio MCP `execute_luau`(Edit datamodel)로 섹션별 분할 실행**해 전 구간
확인했다. `audit/gcconn-trick-verification.md`의 "아직 확인 안 된 것" 절이
요구 명세였고 — **그 목록 전부가 이 실측으로 해소됐다**(그 문서 상단 배너
참고). FAIL 0(아래 B의 구판 단언 1건은 "실패"가 아니라 **발견** — 본문),
GC 관찰 실패 0, ClassName 신호 발화 0.

**환경**: 별도 계정 `qwreey_selene` 컨테이너의 Studio(버전 0.736), Edit
모드 "Place1", MCP 프록시 경유(연결 경위는 `HUMAN_TODO.md` 1번). GC는
`gc-trigger-helper.server.luau`의 canary 기법 + 60초 상한 — 실측에선 모든
GC 대기가 **2~3 epoch(1초 미만)** 에 끝났다.

## 방법

파일의 프렐류드(현행 모델 최소 이식 — `newRelate` weak-key/weak-value 2단,
`nativeClaim`, `isBoundAlive`/`canBound`/`canExecute`, `bindLifetime`/
`unbindLifetime`)를 각 호출에 복제해 4개 청크로 나눠 실행(execute_luau
타임아웃 회피 — 각 do 블록은 자기완결). B는 구판 단언이 깨진 뒤 정밀 조사
2회를 추가로 돌리고, 갱신된 단언으로 재실행해 5/5 통과를 확인했다.

## A — 생명주기 프리미티브 (전부 PASS)

| 항목 | 결과 |
|---|---|
| A-0 ClassName 미발화 + Destroy 시 `Connected` 동기 전환 | ✅ 발화 카운터 전 구간 0, Destroy 직후(같은 줄기, GC·`task.wait` 없음) `false` |
| A-1 `canBound` 게이트 (a) — 살아있는 바인딩 재-bind는 error | ✅ 같은 inst·다른 inst 양쪽 모두 pcall false |
| A-2 게이트 (b) — `unbindLifetime` 후 재바인드 통과 + O(1) 개별 해제 | ✅ 같은 inst의 다른 값 무영향, 안 걸린 값 unbind no-op |
| A-3 게이트 (c) — Destroy 후 **다른 inst**로 재바인드 허용 | ✅ Destroy 직후(GC 안 기다림) `canBound` true → 새 inst 바인드 성공, `canExecute` 새 gcconn 기준 true |
| A-4 `canExecute`가 inst 없이 BindData 복사 gcconn만으로 판정 | ✅ 살아있는 동안 true / Destroy 직후 동기 false |
| A-5 Destroy+GC 후 weak 릴레이션 자기 정리 | ✅ BindData의 gcconn/gchold 항목이 스스로 비워짐(이후 `isBoundAlive`는 nil 분기로 false), gchold에만 매달린 value 수거(누수 없음) |
| A-6 X1 claim된 inst의 userdata 고정 | ✅ 강참조 없이 GC를 견디고 `FindFirstChild` 재조회가 **rawequal**(gcconn 클로저의 inst 캡처가 실제로 고정) |
| A-6 X2 **claim 없는 inst의 userdata 수거** | ✅ **1 GC 사이클 만에 수거됨** — workspace 트리에 엔진 객체가 살아있는데도 weak-value 항목이 nil이 됐고, 재조회는 새 userdata다. **`nativeClaim`의 존재 이유("재조회 시 다른 userdata가 나올 수 있다", `lifecycle-pattern.md` (0))가 실증됐다** |
| A-7 Instance를 `__mode="k"` weak key로 | ✅ Destroy(gcconn 순환 절단)+GC 후 항목 소멸 — plain table과 동일(`07`의 Instance판) |

## B — Attribute Instance 참조: 지원하되 **`InstanceHandle` 경유** (⭐ 발견)

구판 단언(`GetAttribute` 반환 `== target`)이 **깨졌고 그게 발견이다**:

- `SetAttribute(name, inst)`는 성공하지만 저장·반환되는 것은 Instance가
  아니라 **`typeof(x) == "InstanceHandle"`인 별도 타입**이다. 원본과
  `==`/`rawequal` 모두 false, 핸들끼리는 `==` true.
- **`handle:Get()`이 언랩 경로** — 반환이 원본 Instance와 rawequal.
  `Name`/`Parent` 등 Instance 멤버 인덱싱은 전부 error("not a valid member
  of InstanceHandle"), Instance 인자 자리(`IsAncestorOf` 등)에도 못 넣는다.
- target을 **Destroy해도 Attribute는 nil로 안 풀린다** — 핸들이 남고
  `:Get()`은 죽은 Instance(Parent=nil)를 그대로 준다. 생존 판정은 소비자
  몫(quad의 gcconn `Connected` 판정과 같은 결).
- `InstanceHandle.new(inst)` 생성자 존재, `SetAttribute`는 핸들도 직접
  수용(왕복 동일), `SetAttribute(name, nil)`은 삭제. — 전부 실측 확인.

**정체(사용자 설명, 2026-09-01 — 미문서화 Studio Beta)**: Attribute의
Instance 참조 지원 자체가 최근 일이고(발표 글:
devforum.roblox.com/t/studio-beta-reference-instances-directly-with-attributes/4753441),
`InstanceHandle`은 **복제 문제를 푸는 간접 참조**다 — 서버가 세팅한 참조가
클라이언트로 복제될 때 대상 Instance가 아직 스트리밍 안 됐을 수 있어서
(StreamingEnabled에서 특히), `:Get()`은 단순 얻기라 **nil일 수 있고**
`:Wait()`은 대상이 로컬에 실체화될 때까지 기다렸다가 반환한다. remote로
핸들을 직접 보내는 용법(`remote:FireClient(player, InstanceHandle.new(x))`)
이 본래 동기에 가깝다. Roblox가 문서화 없이 릴리즈로 움직이는 흔한 사례라는
것도 사용자 확인.

**이번 실측이 안 본 것**: `:Get()`이 nil을 주는 경로와 `:Wait()`의 대기 —
Edit 단일 컨텍스트라 스트리밍 미실체화 상황을 재현할 수 없다. 또
**ObjectValue는 이 Studio 버전 Edit 모드에선 옛 동작 그대로였다** —
`.Value` 읽기가 Instance를 직접 주고(`== target` true), 핸들 대입은
"Instance expected, got InstanceHandle"로 거부. 사용자 설명(ObjectValue
읽기도 핸들 반환)과 합치면 실체화 여부·롤아웃 단계에 따라 갈릴 가능성이
있는데, **단정하지 않고 관측만 남긴다**. Beta라 거동이 바뀔 수 있음.

**설계 영향**: quad의 Attribute **쓰기 경로는 무영향**(Instance를 그대로
넘기면 엔진이 자동 랩). 영향은 **읽기 쪽**이다 — `base/attribute-plan.md`가
ObjectValue 없이도 Ref 용도로 Attribute를 그대로 쓸 수 있다고 하던 서술은
"읽을 땐 `:Get()` 언랩 + nil/죽은 참조 처리 필요"로 조건부가 됐고(그
문서에 날짜 배너로 반영),
quad-debug처럼 Attribute를 읽는 소비자와 `InstanceAttribute` 타입 생성자의
읽기 타입은 이 사실 위에서 설계해야 한다(M5 이후 해당 마일스톤 몫).

## C — CollectionService 태그 왕복 (전부 PASS)

AddTag ×2 → `GetTagged` 2 / RemoveTag → 1 / **Destroy → 0(엔진이 태그
정리)**. quad-debug의 CollectionService 노출 전제
(`research/debug-tooling-plan.md`) 그대로.

## 잔여물

스파이크가 만든 `QuadSpike10_*` 인스턴스는 각 청크가 Destroy — 마지막
청크가 workspace 스캔으로 잔여 0을 단언했고, B 재실행·정밀 조사분도 각자
정리함.
