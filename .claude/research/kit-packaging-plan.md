# 공식 킷 둘의 패키지화 — 폴더·이름·버전·`Kit(q)` 주입

**[2026-10-22 신설 — 계획서, 결정 아님(1절은 이미 닫힌 것)]** devui·material 두 킷을 quad가 직접 관리하는 공식 킷으로 게시하기 위한 계획. 경위와 사용자 원문은 `session/2026-10-22-01-official-kits.md`, 루트 `ROADMAP.md` 백로그의 킷 버전·패키지화 항목이 이 문서를 가리킨다.

## 1. 이미 닫힌 것 (사용자 결정 2026-10-22)

- **공식 킷 둘** — quad가 직접 관리하고 함께 검증한다. 근거(사용자): 흩어진 킷은 "업데이트를 받을 수 있나"라는 신뢰 문제, 바로 써 볼 킷이 눈앞에 있다는 것, 그리고 릴리즈 전에 설계 결함을 실제 소비로 잡는 방어선(*"설계 결함이라 철회해야하는 경우는 릴리즈 하고 나서는 늦어"*). 공식은 둘로 끝.
- **조건** — 킷은 quad 공개 표면만 쓴다(기계 검사로), "필요에 따라 넓히는 참고 킷"(완전 커버리지 약속 없음), best practice를 보여 주고 자기 디자인 언어로 킷을 만드는 사람(과 그들의 AI)이 참고 자료로 쓸 수 있게.
- **폴더** — `kits/roblox-devui/`, `kits/roblox-material/`(나중 도구는 `tools/…`). pesde 실측(0.7.4): 중첩 워크스페이스는 안 되고 루트 `workspace_members`의 글롭 `kits/*`는 된다 — 격리는 폴더·킷별 게이트·문서로.
- **패키지 이름** — 소유자/패키지그룹_서브그룹_이름: `qwreey/quad_kit_roblox_devui`, `qwreey/quad_kit_roblox_material`. 범위는 `qwreey/` 유지(사용자: 소유자가 달라 보이면 trust 범위를 나눠 정의해야 하고, 실제로 개인 프로젝트다). `quad_kit_devui`는 기각 — Roblox 것인지 안 보이고 다른 쪽(웹) 구현과 일치하는 것처럼 읽힌다.
- **버전 `A.B.C`** — A는 킷이 요구하는 quad 메이저, B는 킷 자신의 breaking마다 오르고 A가 바뀌어도 내려가지 않으며 **A만 바뀔 때는 오르지 않는다**(3.7.2 다음 quad 4 포팅은 4.7.0 — B가 킷 API 세대를 뜻함), C는 breaking 아닌 변경 전부. 본체와 lockstep이 아니다(2026-10-22 앞선 권고를 대체). 소비자는 `~A.B.C`로 적는다 — pesde `^`는 B 상승(=킷 breaking)을 받아들인다. 본체도 3.x minor가 breaking이라 문서의 `^3.4.0` 안내는 `~`가 맞다.
- **라이선스** — 킷 폴더마다 `LICENSE`(MIT)·`NOTICE.md`, material은 `LICENSE.material-icons`(범위 서술 + Apache 2.0 원문, 2026-10-22 반영).
- **주입 형태** — 킷 전체가 팩토리 `Kit(q)`. **설치 함수가 아니다**(사용자: 킷은 quad의 소비자이고 quad의 동작을 바꾸지 않으므로 quad에 설치되면 안 된다). `Kit(q)`의 결과는 q와 따로 둔다 — 근거는 타입 비용(`&`로 엮을수록 복잡해지고 큰 export 타깃 하나가 생긴다). 다만 런타임 어디서든 `Kit(q)`를 불러도 한 번만 만들어지고 이미 있으면 그것을 돌려준다(사용자 안: `q.__kit_roblox_material` 같은 자리).

## 2. 지금 모양 (2026-10-22 실측)

킷마다 설정 모듈 `src/Quad.luau` 하나가 quad를 잡는다: `quad_base`를 직접 require하고 `Quad:UseProvider(QuadRoblox)`를 부른 뒤 타입을 재export한다. 그 모듈을 모듈 로드 시점에 require하는 파일이 devui 55개 중 39개, material 136개 중 110개다(대부분 `local Frame = q.Elem "Frame"`처럼 로드 시점에 q를 쓴다). 킷 안에는 모듈 수준 상태가 있다 — devui `Overlay.getDefault()`·`Style.default`·`Pointer`, material `Theme` 기본값 등.

문제(사용자 지적): 같은 quad 사본이면 게임과 킷이 한 모듈을 나눠 쓰지만(`UseProvider`가 같은 프로바이더에 멱등), 두 킷이 다른 quad 버전에 묶여 사본이 갈리면 한 킷의 State가 다른 킷 위젯에서 같은 것으로 인식되지 않는다. 그리고 킷이 `UseProvider`를 부르는 것 자체가 "quad에 설치하지 않는다"와 어긋난다.

quad 쪽에 이미 있는 것: q는 quad_base 모듈 표 자체(`Version = "3.4.0"` 필드가 있고 얼어 있지 않음), `RunInit(initFn)`(같은 모듈에 같은 함수는 한 번 — 키가 함수 신원이라 킷 사본이 둘이면 둘 다 돈다), `AddPlugin`(q에 병합 — 설치라서 쓰지 않음), quad-roblox는 `TypeVersionCheck.matchesPattern(q.Version, "3.4^.0^")`로 버전을 검사한다. Roblox 프로바이더가 설치됐는지 묻는 공개 술어는 없다(확장이 더한 `q.Animate`·`q.Tween` 등으로 짐작만 가능).

## 3. 정할 것

**3.1 킷 안 모듈이 q를 받는 방법.** 두 갈래.

- (가) **모듈마다 팩토리** — 모든 모듈이 `return function(ctx) … end`가 되고 `Kit(q)`가 순서대로 엮는다. 킷 하나를 q마다 여러 벌 만들 수 있다. 비용: 149개 파일의 기계적 변환, 형제 모듈을 `require` 대신 ctx로 받으면서 타입이 끊기기 쉽다(ctx 타입을 손으로 써야 함), 읽는 사람에게 낯선 모양 — best practice 참고 자료라는 목표와 부딪힌다.
- (나) **킷 사본 하나 = q 하나에 묶기(늦은 결합)** — `Quad.luau`가 값을 갖지 않는 자리가 되고, `Kit(q)`가 그 자리에 q를 넣은 **뒤에** 안쪽 모듈 트리를 require한다(모듈 코드는 지금 모양 그대로 `require("./Quad")`). 같은 사본에 다른 q가 오면 에러로 알린다. 비용: 파일 대부분을 안 건드린다, 대신 한 사본으로 q 둘은 못 섬긴다(Roblox에서는 ModuleScript 트리를 Clone해 새 사본을 만들 수 있으나 그건 관측된 필요가 생길 때).

메인 권고: **(나)**. 한 게임이 q를 둘 쓰는 경우는 관측된 적이 없고("드문 오용이나 가상의 미래 요구까지 방어하려고 구조를 복잡하게 만들지 않는다"), (가)는 참고 자료로서 킷 코드의 읽기 쉬움을 크게 깎는다. 사용자가 짚은 문제(킷마다 다른 quad)는 (나)에서도 풀린다 — 킷이 quad를 직접 require하지 않고 게임이 넘긴 q를 쓰기 때문이다.

**[2026-10-22 사용자 회신 — 3.1 (나) 기각, (가) 쪽으로 더 판다]** 사용자: require 경로에 따라 비결정적인 코드는 그 자체로 디버깅 문제이고, 안쪽 요소 하나를 `require` 경로로 골라 쓰면 바로 깨진다. ctx 타입이 끊기는 문제는 킷이 아니라 **상위 표면**의 문제 — 바깥에서 `Quad & QuadRoblox`를 타입으로 구성하고 기대할 수 있어야 한다(2026-10-16 백엔드 계약 논의의 "적절한 분리 표면"이 여기서 다시 보인다). 이어서: 타입으로 검사를 넣는 것은 무거워서 별로, 대신 **base에 표면 둘이 필요해 보인다** — (1) 프로바이더가 설치됐는지 보는 런타임 확인(가칭 `CheckProvider`), (2) `require("./Common")(q)`에서 같은 q면 결과를 캐싱하는 표면(*"단순 함수 실행 했다면 다시 실행은 안 한다가 아니라, 이 quad 에서 실행했던걸 캐싱한다"* — `UseProvider`와 그 상위 구현은 프로바이더·내부용이고 중립적 툴킷·컴포넌트킷을 위한 자리가 base에 없다). 메인 정리(결정 아님): 캐싱 표면은 키로 아무 값이나 받는 하나(`q:Memo(key, build)` 꼴 — 모듈 팩토리는 함수 신원, 킷 루트는 3.2의 문자열 키), 만드는 중 같은 키 재호출은 에러(`RunInit`과 달리 돌려줄 값이 없음), `RunInit`은 그대로; 프로바이더 확인은 **함수 신원 비교 금지** — 킷의 quad-roblox 사본과 게임이 설치한 사본이 다르면 같은 프로바이더인데 "없음"이 된다(막으려던 바로 그 상황) → 프로바이더가 이름·버전을 밝히고 이름 + 버전 패턴으로 확인; 팩토리의 q 매개변수엔 여전히 `Quad & RobloxExtension` 꼴 주석이 필요(검사 아닌 주석) — 비용은 스파이크로 잰다(격리 worktree, devui `Button` 수직 조각). 둘 다 base의 새 공개 표면 → 다음 3.x minor에 본체가 먼저, 이름은 세 모델 검토.

**[2026-10-22 스파이크 결과 — (가) 모듈마다 팩토리, devui `Button` 수직 조각 일곱 모듈, 격리 worktree `.claude/worktrees/agent-a5126c2276e3d8b27`(커밋 안 함)]** 타입은 잃지 않는다 — 심은 오류(`Text = 42`, `OnClick = 5`)가 원본 경로와 바이트 단위로 같은 메시지, 팩토리 본문 안 `q.Elem`·`q.Modifier`·`q.Source`도 정밀 타입 유지, 반환 타입 유지; 모르는 prop(`Txet`)은 원본에서도 안 잡힘(신 솔버가 인자 테이블 리터럴의 여분 필드 허용 — 기존 한계). 덤: provider 없는 q를 넘기면 `Quad is not a subtype of RobloxExtension` 타입 진단이 새로 생긴다(주석만으로 공짜). 분석 비용은 잡음 수준(조각 0.934 → 0.946 s 최솟값), 복잡도·한도 진단 0. 런타임(Lune) 통과. **구조 비용**: 모듈마다 이름 둘(타입용 require 결과 `StyleM`, 값 `Style = StyleM(q)`), q에 기대는 형제를 쓰는 헬퍼가 본문으로 연쇄 이동, 모듈 수준 상태·공개 스위치가 q별로 갈림(`Overlay.warnUnmounted`, 레지스트리 — quad를 안 쓰는 Pointer 등은 공유로 남음), 들여쓰기 churn(킷 약 8800줄, 최상위 `local X = q.…` 162줄), 값에서 나온 타입은 한 곳(`GuiHook = typeof(q.PostRef(…))` → `typeof(((nil :: any) :: Q).PostRef(…))`로 최상위 유지). **메모 누수(실측)**: q를 약한 키로 쥐는 표에 q를 붙잡는 클로저가 값으로 들어가면 GC가 항목을 안 거둔다(Luau에 ephemeron 없음 — `NewModule`로 q를 계속 만드는 스펙·도구에서 킷 한 벌씩 샘) → 캐싱 자리는 **q 자신**이어야 한다(base가 q의 비공개 자리에 두면 q와 함께 사라짐 — 사용자의 처음 안 `q.__kit_…`과 같은 결론, 다른 패키지가 q에 필드를 다는 게 아니라 base 표면이 하는 일). 순환 require는 지금과 같고, 빌드 중 자기 재호출은 무한 재귀 → base 캐싱 표면이 "만드는 중"을 에러로.

**[2026-10-22 사용자 회신 + 메인 실측 — 모양 정리]** (1) 킷은 함수 값 없이 `quad-roblox-types`(타입 패키지)만 의존한다 — 생성 `Data.luau`와 서페이스 타입 결정까지 types 쪽으로(ROADMAP 백로그 `quad-roblox-types`와 합류). (2) 3.2의 `q.__kit_…`도 캐싱 표면이 없어서 나온 것 — 킷 루트도 같은 표면으로 묶는다. (3) 들여쓰기: 루트 `stylua-ignoreme.luau` 꼴(팩토리 머리 `return function(q: Q)`와 꼬리 `end`만 `-- stylua: ignore start/end`로 감싸고 본문은 들여쓰지 않음)이 stylua를 통과한다 — 스코프가 모듈에서 q로 바뀔 뿐 여전히 최상위 스코프라 문제없다(사용자), churn 없음. (4) GC — 사용자 안: 키를 `tostring(func)`로, 결과와 함께 대상 func 자체도 q에 묶는다. 메인 실측(luau, GC 5회): 약한 곁 표(q 키, 값이 q를 붙잡음)는 q가 **안 거둬짐**, memo를 **q 자신 안에** 두면 함수 키든 `tostring` 키든 **둘 다 거둬짐** → 누수를 푸는 것은 키 모양이 아니라 **자리(q 안)**. 주의: base의 `Relate`도 소유자(q)를 약한 키로 쥐는 버킷이라 그 안에 결과를 두면 누수가 재현된다 — 표면은 q의 비공개 필드에 직접 담아야 한다.

**[2026-10-22 사용자 확정 — 캐싱 자리]** 문제는 키가 아니라 강/약이었다 — 팩토리 함수와 결과는 GC상 서로 무관한 둘이라 q 안의 `{ strong k : strong v }` 단일 표로 풀린다. `tostring` 키는 안 쓴다, `Relate` 위에도 얹지 않는다(사용자: Relate는 연관을 잡기 위한 구조이고, 여기선 단일 테이블이 가장 쉽고 싸다). 키는 아무 값(모듈 팩토리는 함수 자체, 킷 루트는 이름·B 문자열 — 메인 권고, 사용자 이견 없음). 남은 것: 두 표면의 이름(세 모델 검토), 프로바이더 확인이 실패 때 던질지 참·거짓만 줄지.

**[2026-10-22 이름 — 세 모델 검토 `audit/naming-base-2026-10-22/` 뒤 사용자 결정]** 캐싱 표면 `q:GetOrCreate(key, build)`(다수안, 사용자 동의 — `Memo`는 반응형 memo/computed로 읽힘). 실패 시 던지는 단언 `q:AssertProvider(name, versionPattern)`(사용자: Check 말고 assert — Lua `assert`처럼 에러가 자연스럽고 내부 `_assert…`와 맞음; 다수안). 선언 자리는 `q.Backend` 아래(사용자: *"Backend.Provider = { Name, Version } 이 되면 짝이 맞겠다"*) — 프로바이더는 이미 `quad.Backend.nativeInsert = …`처럼 Backend를 직접 채우므로 같은 방식으로 적고, base에 병합 장치가 따로 필요 없다; 최상위 병합이 아니라서 `q.Version`을 덮는 문제도 없다. `UseProvider`라는 이름이 `Backend.*`·`BackendStubs` 옆에서 뜬금없어 보이는 것은 더 위의 걸림이지만, 사용자 판단으로 문제 아님(*"Provider 라는 말이 중립적 … quad 에 암묵적으로 Backend 가 필요하고 그걸 프로바이딩 한다는 맥락은 문제는 없는것 같기도"*). 열린 것: `Backend` 멤버가 전부 camelCase op(`nativeInsert`, `setTimeout`…)라 필드 대소문자 — 메인 권고 `Backend.provider = { name, version }`.

**3.2 "한 번만" 자리.** `Kit(q)`가 결과를 어디에 기억하는가.

- (가) **q에 문자열 키** — 사용자 안. 킷 사본이 둘이어도 같은 q면 같은 결과를 돌려준다. 키에 B(킷 API 세대)를 넣어야 한다 — `3.7.x` 사본과 `3.8.x` 사본이 한 키를 나누면 한쪽이 다른 API를 받는다. 예: `q.__quad_kit_roblox_material_7`. q 표에 필드가 생기지만 동작을 바꾸지 않는 캐시다.
- (나) **킷 쪽 약한 표(q를 키로)** — q를 건드리지 않지만 킷 사본마다 따로라 사본이 둘이면 두 번 만든다.
- (다) **quad에 공개 메모 장치** — 예: `q:Memo(key, factory)`. 새 공개 표면이라 사용자 결정이 필요하고, 킷 말고 쓸 곳이 아직 없다.

메인 권고: **(가)**, 키는 `__quad_kit_<이름>_<B>`. 같은 B의 두 사본(3.7.1과 3.7.4)은 먼저 만든 쪽을 나눠 쓴다 — C만 다르니 API가 같다는 것이 이 버전 규칙의 약속이다.

**3.3 프로바이더와 버전 확인.** **[2026-10-22 3.2·3.3 사용자 동의; quad는 4부터 엄밀한 semver(react처럼 — 사용자)]** 킷은 `UseProvider`를 부르지 않는다(설치 금지). `Kit(q)`는 (1) `q.Version`이 A와 맞는지 quad-roblox와 같은 방법(`TypeVersionCheck.matchesPattern`)으로 보고, (2) Roblox 프로바이더가 이미 설치돼 있는지 확인해, 아니면 "게임의 설정 모듈에서 `UseProvider(QuadRoblox)`를 먼저"라고 알린다. (2)의 확인 수단이 문제 — 확장 필드로 짐작(`type(q.Animate) == "function"`)하거나, quad-roblox가 공개 술어를 내놓거나(새 표면 — 사용자 결정). 메인 권고: 지금은 짐작으로(오탐 경로가 "다른 프로바이더가 같은 이름을 넣은 경우"뿐), 공개 술어는 필요가 관측되면.

**3.4 타입.** 킷의 공개 타입(Style·props·핸들)은 킷 루트 모듈이 정적으로 export하고(`local DevuiKit = require(Packages.quad_kit_roblox_devui)`, `type Style = DevuiKit.Style`), `DevuiKit(q)`는 평범한 표 타입(킷 공개 함수 묶음)을 돌려준다 — q와 `&`로 엮지 않는다(1절 근거). 열린 점: 지금 킷 모듈들이 `Quad.luau`가 재export하는 quad 타입(`State<T>` 등)을 쓰는데, 늦은 결합에서도 그 타입은 `quad_types`에서 정적으로 온다 — 실측으로 확인할 것(타입이 q 값에 매이지 않는지).

**3.5 모듈 수준 상태.** (나)에서는 킷 사본 하나가 q 하나에 묶이므로 `Overlay.getDefault()`·`Style.default` 같은 모듈 수준 기본값은 지금 그대로 "그 사본의 기본"이다 — 바꿀 것 없음. (가)였다면 전부 ctx로 옮겨야 했다.

**3.6 레포 안 개발·시험.** 스펙·스토리·갤러리는 레포의 q로 `Kit(q)`를 불러 쓴다. 지금 `Quad.luau`가 하는 "레포 안에서는 워크스페이스 사본을 가리킨다"는 시험용 진입 모듈 하나로 옮긴다. devplorer(레포 밖 소비자)는 vendor 경로와 진입 방식이 바뀌므로 넘김 문서에 적는다.

## 3.7 base 표면 둘 — 작업 계획 (2026-10-22, 사용자 결정 위에)

**선언 자리 확정(사용자 2026-10-22)**: `q.Backend.provider = { name, version }` — camelCase(*"실제로 백엔드가 주입해야할 목록으로 늘어났다고 보면 … 똑같이 데이터일 뿐 생성자는 아니니까"*). 백엔드가 주입하는 목록에 한 줄이 느는 것: quad-types `Backend` 타입에 `provider: { read name: string, read version: string }?`, base는 아무것도 넣지 않는다(스텁 대상 아님 — 없으면 `AssertProvider`가 알린다). quad-roblox는 `EngineOps`가 op를 채우는 자리 옆에서 `{ name = "quad-roblox", version = <자기 버전> }`.

**`q:GetOrCreate(key, build)`**: 저장은 `New()` 안의 지역 표 하나(q의 메서드 클로저가 쥠 — q에 필드를 안 늘리고, 강-강이며 q와 함께 사라짐; `Bookkeeping`은 Length/Offset 부기 네임스페이스라 다른 일을 섞지 않는다). 첫 호출은 "만드는 중" 표시 → `build(q)` → 결과 저장; 만드는 중인 키를 다시 부르면 에러, `build`가 던지면 표시를 지우고 그대로 다시 던진다(재시도 가능 — `UseProvider`의 "마킹은 성공 후"와 같은 교훈), `build`가 nil을 돌려주면 에러(nil은 "없음"과 구별 불가). 입구 검사: key nil, build가 함수 아님.

**`q:AssertProvider(name, versionPattern)`**: `Backend.provider`가 없으면 "게임 설정 모듈에서 `UseProvider`를 먼저", 이름이 다르면 둘 다 보여 주는 에러, 버전이 패턴에 안 맞으면 그 에러; 반환 없음. 입구 검사: 둘 다 문자열.

**열린 점 하나 — 버전 패턴 검사기**: quad-roblox는 `type_version_check`의 `matchesPattern`을 쓴다(`3.4^.0^` 꼴). base가 같은 문법을 받으려면 quad-base가 `type_version_check`에 새로 의존해야 한다(작고 엔진 무관, 4.0 전 lockstep 다섯 중 하나) — 메인 권고: 의존을 더한다(문법을 둘로 만들지 않음).

**같은 단위에 들어갈 것**: 에러 코드 `Quad0282~`(`scripts/error-codes.py --next`) + `docs/reference/errors/` 절, 레퍼런스 문서 두 항목, 스펙(캐시 재사용·키별 분리·순환 에러·build 실패 후 재시도·NewModule 분리·GC로 q와 함께 사라짐; 단언 세 실패·통과), quad-roblox의 `provider` 기록과 스펙, 본체 CHANGELOG Added. 버전은 다음 3.x minor(3.5.0). 이 단위가 끝난 뒤 킷 `Kit(q)` 전환(4절 2번).

## 4. 순서

1. **폴더 이동 + 공개 표면 검사** — `kits/roblox-devui`·`kits/roblox-material`로 옮기고 test.sh·`consumer-kits.project.json`·문서 경로·`run.sh`를 고친다. 킷이 quad 내부 경로(`quad-base/src/…` 같은 공개 패키지 루트 밖)를 require하지 않는지 보는 검사를 게이트에 넣는다. 문서의 `^3.4.0` 안내를 `~`로.
2. **`Kit(q)` 주입** — devui 먼저(작음), 그다음 material. 3.1~3.4가 정해진 뒤.
3. **패키지화** — 매니페스트(`kits/*` 글롭 멤버 여부 포함), 첫 버전(A=3, B=0 → `3.0.0`), CHANGELOG `[Unreleased]` 절단, 게시 도구(`check-version.py`·`publish.py`)가 킷을 따로 다루게.
4. **"킷 만드는 법" 안내 문서** — 패턴별로 킷의 어느 파일을 보면 되는지, 따라 할 패턴과 참고만 할 곳(devui `Window/Manager.luau`처럼 제품 수준 복잡도)을 갈라 적는다.

## 5. 이 문서 밖으로 미룬 것

- 이전 quad(v1, `master` 2.x)의 이름 — 사용자 제기(2026-10-22): "quad2"는 시리즈 이름이라 잘못된 지칭이고, 이전 것을 `quad-legacy` 류로 부르는 게 싸다(패키지로 올라간 적 없고 옛 클론은 `master`를 가리킨다). 나중에 `legacy/` 아래 재구현체 `quad-legacy`(인터페이스 같음·버그만 고침)와 `quad-legacy-compat`을 묶는 방향 — `v1-compat-plan.md`에 적는다.
- 도구(`tools/`: 디버그 플러그인, material icons 플러그인, 웹 도구) — 마켓플레이스로 나가므로 도구마다 자기 버전·CHANGELOG(메인 의견, 사용자 이견 없음). 착수는 각 계획서(`debug-tooling-plan.md`, `icon-pack-plan.md`).
