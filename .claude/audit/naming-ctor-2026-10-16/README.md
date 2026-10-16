# 이름 탐색 2026-10-16 — 클래스 이름으로 요소 생성자를 꺼내는 함수(X), `q.New()` 개명, 공용 모듈 네임스페이스

과제문 `prompt.md`(Declaration 트랙 4절 1번 — 값은 이름·타입은 클래스 타입, 커리 `X "Frame"`, 꺼내 두기 권장)를 sonnet(레포를 안 읽은 외부자, 채팅 보고 — 아래 요약)과
Gemini(`gemini.md`, 레포를 읽음)에 같은 과제로 맡겼다. 결정이 아니라 재료다.

**sonnet**: X 1순위 `Class`(`local Frame = Class "Frame"` — 동사가 아니라 "여기서 만든다" 오독이 없음, Spread·Modifier와 "클래스 이름 먼저" 가족), 2순위 `New`(Fusion 친숙,
대신 `local Frame = New "Frame"`이 즉시 생성으로 읽힐 위험), 그 밖 `Element`·`Create`·`Ctor`·`Of`. `q.New()`는 바꾸는 게 맞다 — 1순위 `NewModule`(`Fork`·`Isolate`는 뜻이 어긋남,
`Scope`는 Fusion 0.3과 충돌). 네임스페이스는 나눌 것(`UI.Frame` 별도 테이블 — 충돌 확인을 q 멤버가 늘 때마다 할 필요가 없어짐). 한 세트: `Class` + `NewModule` + `UI.<Class>`.

**Gemini**: X 1순위 `New`(조건부 — `q.New()`를 `NewModule`로 옮긴다면; Roblox `Instance.new`·Fusion `New`의 친숙도), 2순위 `Elem`(내부 `<Class>Elem`과 용어 일치),
그 밖 `Ctor`·`Create`(꺼내 두기 줄에서 오독이 가장 큼)·`Decl`. `q.New()`는 "반드시 바꿀 것" — 쓰는 곳이 거의 없는데 가장 값진 단어를 쥠, 1순위 `NewModule`. 네임스페이스는
`q.UI` 서브테이블 강력 권고(`Tween` 충돌 격리, 자동완성 도메인 분리). 한 세트: `New` + `NewModule` + `q.UI`.

**메인 검증**: Gemini 인용 중 생성 D의 기존 `D.New("Frame")`(`quad-roblox/src/Declaration/init.luau`의 `local function New<T>(className)`, `D = { New = New, … }`)와
`q.New()` 사용처(코드에선 드묾, 에러 메시지 Quad0106·NotInstalled 등과 `docs/reference/errors/06-module-backend.md`에 이름이 박힘 — 개명하면 메시지 문구가 바뀜)는 사실.
q 공개 이름과 Roblox 선언 이름(2236)의 교집합이 `Tween` 하나인 것은 메인 실측과 같다. Gemini가 놓친 점: 값 쪽 X를 `Elem`으로 하면 타입 쪽 `Elem<Frame>`(배열부 자식 유니언)과
같은 이름이 다른 것을 뜻하게 된다. sonnet이 놓친 점: Fusion의 `New "Frame"`도 props를 기다리는 함수를 돌려주므로 "즉시 생성 오독"은 Fusion 사용자에겐 이미 익숙한 모양이다.
