# `quad-types` — 구현 없는 `Quad` 타입 계약 + 컴파일 타임 버전 체크

**상태**: base — 2026-08-19 세션에 신설·구현·검증까지 완료. 워크스페이스
세 번째 멤버 `quad-types`의 존재 이유, `AddPlugin`/`CheckedQuad`의 정확한
사용법, 그 배선에서 실제로 깨졌던 Luau 함정들을 정리. **[같은 날 후속]**
버전 패턴 매칭 자체는 quad에 종속되지 않은 범용 패키지
`type-version-check`(워크스페이스 네 번째 멤버)로 분리됐고, `CheckedQuad<T>`는
`CheckedQuad<T, Pattern>`으로 확장돼 그 위에 얹힌다 — 아래 "`type-version-check`"
절.

## 왜 필요한가 — dev-dependency로는 못 푸는 문제

`quad-roblox`는 `QuadRoblox(Quad): QuadRoblox`처럼 quad-base 인스턴스를
**런타임에 함수 인자로 주입**받는다(`base/module-lifecycle-plan.md`
"Bind는 누가, 어떻게 구현하는가" 절이 확정해둔 팩토리 패턴 — quad-roblox
자신은 quad-base를 `require`할 필요가 없어 보인다).

**그런데 타입 주석 하나 때문에 얘기가 달라진다.** `QuadRoblox`의 시그니처가
`Quad` 타입을 참조하려면 그 타입이 정의된 모듈을 `require`해야 하고,
**이 require는 "타입만 쓰려는 목적이어도 런타임에 실제로 실행된다"**
(실측 확인, 2026-08-19 — `require`가 반환하는 모듈에서 export 타입만
꺼내 써도 그 `require` 문 자체는 평범한 런타임 호출이라, 대상이 없으면
그 자리에서 크래시함). 그래서:

- `quad_base`를 **일반 의존성**으로 두면: 소비자가 `quad-roblox`를 설치할
  때마다 무거운 quad-base 전체가 통째로 딸려온다(quad-base를 이미 따로
  설치해서 `QuadRoblox(Quad)`에 넘기는 상황이면 완전히 중복).
- `quad_base`를 **dev-dependency**로 두면: 로컬 개발 중엔 문제없지만,
  `quad-roblox`가 게시된 뒤 **소비자 환경엔 dev-dependency가 전파되지
  않아** 그 타입-전용 require가 못 찾고 그 자리에서 런타임 크래시난다.

**해법**: `Quad`의 타입 계약만 담은, 런타임 구현이 사실상 없는 세 번째
워크스페이스 패키지 `quad-types`를 두고, `quad-roblox`는 이것만 **일반
의존성**으로 둔다 — 항상 안전하게 실 의존성으로 넣을 수 있을 만큼
작고, quad-base 전체를 안 끌고 온다.

## `quad-base` 안에 폴더로 두면 안 되는가 — 안 됨

pesde의 워크스페이스 의존성은 **패키지 단위**로만 걸린다
(`{ workspace = "scope/name" }`) — 서브폴더 단위 의존 문법이 없다.
`quad-base/types/`처럼 폴더로 만들어도 `quad-roblox`가 그걸 가져오려면
결국 `quad_base` 패키지 전체를 의존성으로 선언해야 하고, 실제로 링크되는
것도 quad-base 전체 소스 트리다(어느 파일을 실제로 require하는지와
무관). 그래서 **반드시 별도 pesde 패키지**(`workspace_members`의 새
멤버)여야 "가벼운 타입만" 효과가 실제로 생긴다.

## 구조

```
quad-types/
├── pesde.toml            # name = "qwreey/quad_types", type_version_check workspace 의존
└── src/init.luau         # export type Quad, export type CheckedQuad<T, Pattern>

type-version-check/       # 워크스페이스 네 번째 멤버, quad에 종속되지 않음
├── pesde.toml            # name = "qwreey/type_version_check", environment = "luau"
└── src/init.luau         # matchesPattern(런타임), export type function CheckVersion
```

- `quad-base`는 `quad_types`에 workspace 의존 — **자기 `Quad` 타입을
  따로 선언하지 않고 `type Quad = QuadTypes.Quad`로 그대로 가져다 씀**
  (한 곳에만 진실이 있게, 구현이 계약과 어긋나면 구조적 타입에러로
  자연히 드러남). 실제로 `quad-base/src/init.luau`에 반영됨.
- `quad-roblox`도 `quad_types`에 workspace 의존(quad-base 아님).
- **[참고, 2026-08-19 사용자 판단] 모든 백엔드/플러그인 패키지가 이
  패턴을 따를 필요는 없다** — 예: 가상의 `quad-spring`/`quad-spring-roblox`
  쌍은 타입 분리 없이 `quad-spring-roblox`가 `quad-spring`을 평범하게
  일반 의존성으로 둬도 된다("주입만 하면 Spring이 같이 따라오도록").
  `quad-types` 분리는 **quad-base처럼 사실상 모든 패키지가 의존하는
  핵심 계약**일 때만 값어치가 있다.

## `Quad` 타입 — 확정된 표면

**[2026-08-28] 필드 목록의 소스는 실제 코드 `quad-types/src/init.luau` 하나다** —
여기 있던 M1 시점 코드 블록(`Version`/`debug`/`New`/`RunInit`/`AddPlugin`)은 M2 첫
단위가 `Relate`/`Void`/`Ref`/`is*`/생명주기 4종을 얹으면서 stale해져 지웠다(감사가
발견). 마일스톤별로 무엇이 추가돼야 하는지는 `ROADMAP.md`의 `H-80` 체크박스가
소스이고, 이 문서는 아래처럼 **왜 그 모양인지**만 적는다.

**⭐⭐ [2026-08-24 신설, 6라운드 손 트레이싱 `H-25` — 실측] 이 레코드는 **닫혀
있고**, 마일스톤마다 서브시스템 필드를 여기 추가해야 한다.**

실제 커밋된 `quad-base/src/init.luau`의 `New(): Quad`가 이 별칭을 그대로 반환
타입으로 쓰는데, `RunInit`은 `(self: Quad, initFn: (Quad) -> any) -> ()`로
**반환값이 없어 타입을 못 넓히고**, 타입을 넓히는 유일한 경로인
`AddPlugin<Self, P>`는 이 문서 자신이 **외부 플러그인**용이라고 선을 긋는다.
그런데 `base/architecture.md`의 확정된 결정 13번은 *"`require(quad)`가 돌려준
걸 바로 `Quad.Dispatch`처럼 씀"*을 **표준 사용법으로 확정**해뒀다.

실측(`InitDebug`와 완전히 같은 모양의 `InitDispatch`로 재현):
```lua
local quad = New()
quad.Dispatch.addHandler(function() end)
```
`luau-analyze` → `TypeError: Key 'Dispatch' not found in table 'Quad'`.
즉 M3가 `Dispatch.luau`를 만들고 `module:RunInit(InitDispatch)` 패턴(이 문서가
이미 예시로 보여준 그 패턴)으로 붙이면 **런타임엔 붙지만 타입엔 영원히 안
보인다.** `ROADMAP.md` M5의 quad-roblox 주입 경로도 같은 벽에 부딪힌다 —
quad-roblox는 `quad-types`의 좁은 `Quad`만 본다.

**확정(사용자, 2026-08-24): `quad-types`의 `Quad`를 마일스톤마다 갱신한다.**
- 규칙이 쓰인 계기는 `Dispatch`이고, **M3**가 `Dispatch: Dispatch` 필드와
  그 타입 재수출을 여기 추가한다 — `ROADMAP.md` M3 체크리스트에 **항목으로
  명시**한다(지금까지 아무도 이 필요성을 항목화해두지 않았다).
- **[2026-08-24 정정] 다만 규칙이 *처음 적용되는* 마일스톤은 M2다** —
  마일스톤 순서 교체로 반응형 코어가 앞에 오면서, `Source`/`State`/`Store`
  필드 추가가 `Dispatch`보다 먼저 온다(`ROADMAP.md` M2의 `H-25` 파생 항목).
- 이후 서브시스템도 같은 규칙을 따른다 — 서브시스템을 붙이는 **모든**
  마일스톤(M2 · M3 · M6 · M7 · M8 · M10)이 같은 항목을 진다.
- **"가벼운 타입 계약"이라는 이 패키지의 존재 이유와 상충하지 않는다** —
  타입만 재수출하므로 런타임 무게는 안 는다.
- 검토했다 기각된 둘: **quad-base 내부만 넓은 로컬 교차 타입**
  (`New(): Quad & { Dispatch: Dispatch }`) — quad-roblox도 결국
  `Dispatch.addHandler`를 부르므로 그 경로엔 별도 노출이 또 필요해진다.
  **`(quad :: any).Dispatch` 캐스트** — 가장 싸지만
  `base/typing-limits.md`가 시종 강조하는 명시 바인딩 원칙과 정면으로
  배치되고 quad-base 자기 코드가 `--!strict`의 이득을 잃는다.

`Version`은 리터럴(singleton) 타입 — `string`이 아니라 정확히 `"0.0.0"`.
이 리터럴이 아래 `CheckVersion`의 판정 근거이자, 그 자체로도 평범한
구조적 타이핑만으로 이미 어느 정도 버전 불일치를 잡아준다(다른 리터럴
`"0.1.0"`은 `"0.0.0"`과 구조적으로 호환 안 됨) — `CheckVersion`이 주는
추가 가치는 **감지 자체**가 아니라 사람이 읽을 수 있는 진단 메시지다
(아래 절).

## `AddPlugin<Self, P>` — 실측 검증된 플러그인 체이닝

```lua
AddPlugin: <Self, P>(self: Self, pluginFn: (Self) -> P) -> Self & P
```

`Self`를 고정된 `Quad`가 아니라 **제네릭**으로 둬야 체이닝이 누적된다
(고정하면 두 번째 `AddPlugin` 호출이 첫 번째 확장을 잃어버림). 실측
확인(2026-08-19):
- `quad:AddPlugin(springFn)`(→ `Quad & SpringPlugin`)`:AddPlugin(otherFn)`
  체이닝 결과가 정확히 `Quad & SpringPlugin & OtherPlugin`로 누적됨.
- 플러그인 추가 전 그 메소드에 접근하면 정확히 `Key 'X' not found`로
  거부됨(음성 대조군).

**런타임 구현**(quad-base, 실제 반영됨): `pluginFn(self)`를 호출해 얻은
확장 테이블의 필드를 `self`에 **직접 mutate**하고 `self` 그대로 반환 —
새 테이블을 만들지 않는다. 이유: `RunInit`의 멱등 추적이 `module`
identity에 의존하므로(`base/module-lifecycle-plan.md`의 "New()의 내부 구성" 절),
`AddPlugin`이 새 테이블을 반환하면 그 추적이 끊긴다.

## `type-version-check` — 범용 버전 패턴 매칭 패키지

**[2026-08-19 신설]** 처음엔 `CheckVersion<T>`가 정확 일치(`"0.0.0"`)만
보는 quad-types 내부 함수였다. 그런데 정확 일치는 `quad-spring`/
`quad-spring-roblox`처럼 **독립적으로 게시되는 백엔드 플러그인** 쌍엔 너무
빡빡하다 — 최신 `quad-spring-roblox`가 예전 `quad-spring`도 잘 다루는
경우가 흔할 텐데, 정확 일치를 강제하면 그때마다 재게시가 필요해진다
(**사용자 판단**: "구현해주는것 정말 쉽고... 있으면 좋다고 생각함").
그래서 글롭/캐럿 패턴을 지원하는 별도 패키지로 뺐다 — quad 전용 이름을
안 섞어서 quad-spring류가 quad-base 전체를 끌고 올 필요 없이 이것만
가볍게 의존하게 하기 위함이기도 하다.

**[2026-08-19] 지금은 quad 모노레포 워크스페이스의 네 번째 멤버로 두지만,
사용자가 나중에 독립 저장소로 직접 분리할 예정** — `HUMAN_TODO.md` 참고.

**패턴 문법**(`.`로 나뉜 각 자리): `"*"` = 와일드카드, `"N^"` = 그 자리
숫자값이 N **이상**이면 통과(caret), 그 외 = 정확히 같은 문자열이어야
통과. 예: `"3.*.*"`(메이저만 고정), `"3.3^.4^"`(마이너 3 이상 + 패치
4 이상), `"0.0.0"`(정확 일치 — quad-types가 지금 쓰는 패턴).

```lua
export type function CheckVersion(actual: type, pattern: type): type
```

`actual`/`pattern` 둘 다 문자열 리터럴(singleton) 타입이어야 하고, 일치하면
트리비얼한 `true`(`types.singleton(true)`) 하나만 반환 — `quad-types`
"함정 3"과 같은 이유로 원본 타입을 절대 반환하지 않는다.

**Luau 신규 실측 함정 2건**(이 세션에 처음 발견, `typing-limits.md`가
다루는 "타입 시스템 해석 한계"와는 결이 달라 여기 기록):
- **`type function`은 같은 파일의 바깥 스코프 로컬 함수를 아예 참조 못
  한다** — `Type function cannot reference outer local 'X'`로 컴파일
  자체가 실패. 그래서 런타임용 `matchesPattern`과 `CheckVersion` 내부의
  매칭 로직은 **물리적으로 별개 함수로 중복**돼 있다
  (`type-version-check/src/init.luau`) — 하나를 고치면 반드시 다른
  하나도 같이 고칠 것.
- **cross-package 사용엔 `export type function`이 필요**하다(`type
  function`만으론 안 됨) — 안 그러면 다른 파일에서 `Unknown type
  'Module.CheckVersion'`으로 막힌다. 그리고 명시적 제네릭 인스턴스화가
  **2개 이상**이면 단일 꺾쇠(`Foo<A, B>`)가 비교 연산자로 오파싱되니
  반드시 이중 꺾쇠(`Foo<<A, B>>`)를 써야 한다(코퍼스에 이미 있던
  `AttributeKey<<T>>` 관례와 같은 이유).
  **⭐ [2026-08-25 확장, 7라운드 `H-73`] 이 관례는 타입 자리 전용이
  아니다** — Luau의 generic type instantiation은 **값 호출부**에서도,
  **콜론 메소드**에서도 동작해 `T`를 실제로 묶는다
  (`store:Of<<number>>("x")`). `luau-analyze` 음성 대조군까지
  확인했다 — 상세는 `base/store-plan.md`의 "타입 추론 문제" 절.

`Version` 필드는 Luau 내장 `index<T, "Version">` type function으로 뽑는다
(수동 `t:readproperty(...)`보다 간결 — **사용자 제안**으로 채택, 실측 확인
완료).

## `CheckedQuad<T, Pattern>` — 버전 불일치를 컴파일 타임에 사람이 읽을 메시지로

**왜 필요한가**: `quad-roblox`가 `quad_base`를 pesde `[dependencies]`로
선언하지 않고 런타임 주입으로만 받게 되면서, **pesde 자신의 semver 충돌
방지 장치가 이 관계엔 전혀 안 걸린다** — 선언된 의존성이 아니라 그냥
함수 인자라서. `CheckedQuad<T, Pattern>`이 그 빈자리를 메꾸는 컴파일 타임
대체 안전장치다(사용자 판단: "런타임 에러까지 내려면 quad-roblox
소스에 버전을 하드코딩해야 하는데 그건 과함 — 타입 에러만 내는 걸로
충분"). `Pattern`은 위 `type-version-check`의 글롭/캐럿 패턴 문자열 —
quad-base/quad-roblox처럼 같은 모노레포에서 항상 같이 개발되는 관계는
정확 일치(`"0.0.0"`)를, quad-spring-roblox류 독립 게시 플러그인은
`"0.*.*"` 같은 느슨한 패턴을 직접 골라 쓴다.

```lua
export type CheckedQuad<T, Pattern> = T & { __versionCheck: TypeVersionCheck.CheckVersion<index<T, "Version">, Pattern> }
```

**사용법**:
```lua
local function CheckQuad<T>(quad: T): QuadTypes.CheckedQuad<T, "0.0.0">
	return quad :: any
end

local checked = CheckQuad(injectedQuad)
local _ = checked.__versionCheck -- ⚠️ 필수 — 아래 "함정 2" 참고
local quad = checked:AddPlugin(installRobloxBackend) -- 이후 정상적으로 체이닝
```

### 실측으로 깨진 시도들 (전부 순서대로 실제로 시도하고 버림)

**함정 1 — `error()`로 에러 내면 안 됨.** `type function` 안에서
`error()`를 부르면 "이 type function 자체가 실행에 실패함"으로 판정돼
버려져서 원하는 메시지가 안 뜬다. **`print("메시지")` + `return
types.never` 조합만 호출부에 정확히 `TypeError: <메시지>`로 뜬다**
(실측 확인 — 3줄짜리 최소 재현으로 검증).

**함정 2 — 함수 본문 안의 로컬 타입 별칭으론 절대 평가 안 됨.**
```lua
-- ❌ 이렇게 하면 아무 진단도 안 뜬다(제네릭 인스턴스화 시 재평가 안 됨)
local function QuadRoblox<T>(quad: T): T
	type _Check = CheckVersion<T>
	return quad
end
```
체크는 **리턴 타입/필드 타입처럼 호출부마다 실제로 해석되는 자리**에
박아 넣어야 한다. 이게 `CheckedQuad<T, Pattern>`이 함수 파라미터/반환
타입 표현식 안에 직접 나타나야 하는 이유고, `__versionCheck` 필드도 **실제로
참조해야만** 평가된다(lazy) — 위 사용법 예제의 `local _ =
checked.__versionCheck` 줄이 빠지면 검사가 조용히 스킵된다.

**함정 3 — [가장 중요, 가장 늦게 발견] 값이 한 번이라도 `type
function`을 거치면 이후 제네릭 self 메소드 체이닝이 조용히 깨진다.**
처음엔 `CheckVersion<T>`가 성공 시 `T`를 그대로 패스스루(`return t`)하는
버전으로 짰다 — 단독으로는 완벽히 통과했다(리턴 타입 표현식에 직접
써서 즉시 평가되고, `AddPlugin`도 안 뭉개지는 것처럼 보였다). 그런데
**`CheckVersion<T>`의 결과를 다른 타입과 `&`로 합친 뒤 `AddPlugin`을
호출하는 조합**에서 `Expected this to be exactly 'P & Self', but got
'P & Self'`처럼 **앞뒤가 똑같은, 의미 없는 진단**이 뜨며 깨졌다. 더
좁혀보니, 심지어 **`&`로 안 합쳐도, `CheckVersion<T>`를 거친 값에
`AddPlugin`을 부르기만 해도 똑같이 깨졌다** — 재구성 비용(값을
`types.newtable()`로 다시 조립하는 것) 문제가 아니라, **"이 타입이
`type function`을 거쳤다는 이력 자체"**가 이후 제네릭 self 추론을
방해하는 것으로 보인다. 그래서 최종 설계는 **`CheckVersion`이 `T`를
전혀 참조/반환하지 않고**(성공 시 트리비얼한 `types.singleton(true)`
하나만), 검증 결과를 원본과 절대 안 섞이는 **별도 필드**
(`__versionCheck`)로 완전히 격리한다 — `T` 자신은 `type function`을
한 번도 거치지 않은 "순수한" 타입으로 계속 흘러가므로, 그 뒤
`AddPlugin` 체이닝이 몇 번이 되든 전혀 안 깨진다(실측 확인).

**교훈**: `type function`의 부작용은 "재구성이 원본을 뭉갠다"는 상상보다
넓다 — **패스스루도 이력만으로 오염된다.** 검증/변형용 `type function`을
설계할 때는 원본 타입을 **절대 반환하지 말고**, 트리비얼한 마커만
반환해서 완전히 별도 필드로 격리할 것 — `typing-limits.md`의 "새
타입/API를 설계할 때 체크리스트"에 추가할 후보.

## 실측 근거

`.claude/luau-test/done/23-type-quadtypes-checkversion-addplugin.luau` —
실제 `quad-types`/`quad-base`/`type-version-check`를 `require`해서 위
사용법 그대로 재현: 양성 경로(버전 일치 + `AddPlugin` 2회 체이닝 + 이전
확장 필드 유지) 전부 클린, 음성 경로(버전 불일치)는 정확히 그 줄에서
`TypeError: type-version-check: version "9.9.9" does not match pattern
"0.0.0"` 하나만.

`quad-base/test/smoke.plugin.luau` — 실제 런타임 `AddPlugin` 구현(mutate
+ identity 보존 + 체이닝)을 실행 레벨로 검증.

## 남은 것

- `quad-roblox`가 실제로 `CheckedQuad<T, Pattern>`을 쓰는 진입점
  (`QuadRoblox` 등) 구현은 M5 — 지금은 quad-roblox/src가 비어 있어 이
  문서의 사용법 예제가 실제 위치는 아직 없음.
- `_initializedBy`(별도 문자열 마커, backend 유일 슬롯 가드)와의 관계는
  `base/module-lifecycle-plan.md`의 "New()의 내부 구성" 절 참고 — `CheckedQuad`는
  **버전** 호환성만 보고, **누가 이미 backend를 설치했는지**는 별개
  문제로 계속 `_initializedBy`가 담당한다.
- **[백로그, 2026-08-19 신설]** `quad-roblox-types`(가칭) — `quad-types`와
  같은 패턴으로, `quad-roblox` 전체 대신 그 타입만 필요한 모듈을 위한
  패키지. **사용자가 지금 만들 필요는 없다고 명시적으로 후순위 지정** —
  다만 이후 쉽게 뽑을 수 있게 `quad-roblox`의 공개 타입은 지금부터 단일
  `src/init.luau`(또는 `types.luau`) 형태로 몰아두는 걸 관례로 유지할 것
  (quad-types 자신이 이미 이 형태 — `Quad`/`CheckedQuad` 둘 다
  `src/init.luau` 하나에 있음).
- **[HUMAN_TODO]** `type-version-check`는 사용자가 나중에 독립 저장소로
  직접 분리할 예정 — 루트 `HUMAN_TODO.md` 참고.
