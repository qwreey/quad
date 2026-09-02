# 모듈 라이프사이클 — Handler 패턴, bind/store는 누가 구현하는가 (base로 승격됨)

**상태**: base — "누가 store를 구현하는가"까지 포함해 전부 확정되어
`research/`에서 승격됨(`base/architecture.md`의 "구현 착수: 소스 트리 구조
확정" 절 참고). 원본:
`.claude/initreq/raw-userinput.md` "넘버 바인드는 누가 처리?" / "모듈은 스코핑
되는가" / "pluggable 하다면 해당 플러그를 초기화하는 건 누구 몫?" / "다시 돌아와서…
bind는 누가 어떻게 구현" / "스토어는 누가 구현해…" 절. 확정된 상위 결정은
`base/architecture.md` 12~14번 항목(멀티 백엔드, 싱글톤 모듈, 팩토리 초기화)
참고 — 이 문서는 그 안의 세부 미해결 사항만 다룸.

## 넘버 바인드(숫자 프로퍼티 등)는 누가 처리하는가

Slot과 맞물려서 잘 생각해서 구현해야 하는 부분. **기울어진 방향**: mount가
처리하는 게 맞아 보이지만, 그러면 확장성이 있을지가 문제. 결론: **표준 구현체는
인터페이스만 두고, 실제 구현은 `quad-roblox` 같은 백엔드 서브패키지가 해당
인터페이스를 구현**. 런타임에 Handler로 Roblox를 주입받는 방향(반대로
"Handler로 base를 받는" 게 아니라) — 이유: 여긴 가상돔이 없어서, base
쪽이 "누가 실제로 그려주는지" 모르는 채로 있다가 Roblox Handler를 주입받는
모양이 더 자연스러워 보임. (이름 자체는 이후 "Handler"로 확정 —
`base/dispatch-core-plan.md`의 핸들러 계약 절 참고, 이 문서는 여전히
초안 당시 표현인 "프로바이더"로 쓰여 있던 걸 정정.)

## pluggable 플러그 초기화는 누구 몫인가

RBVM처럼 `init namespace` 하나하나 부르는 방식은 별로(`base/lifecycle-pattern.md`
5번 항목에서 실제로 rbvm이 이렇게 되어 있는 걸 확인함 — `InitNamespace`/
`Registered`-가드/`NewLib` 3종 세트를 라이브러리마다 반복). 대신 **적절한 팩토리
함수 제공**: `InitRoblox(Module)` 식으로, 생성된 모듈을 뮤테이션할 수 있는 도구를
주고 사용자가 호출하도록. `base/architecture.md` 14번 항목과 동일한 결정 —
여기서는 "왜"만 보강.

## New()의 내부 구성 — InitXxx 팩토리 체이닝 (2026-08-19 신설)

> **⭐ [2026-08-28 `H-174`, 사용자 확정] 반응형 모듈도 같은 팩토리형이다.** M2 첫 단위가
> 생명주기 4종을 `InitLifetimeHandle(module)`로 **인스턴스별 필드**로 만들었으므로,
> `Source`/`State`/`Observer`/`Effect`처럼 그 게이트를 부르는 모듈은 `InitXxx(module)`이
> `module`을 클로저로 쥐고 **발화 시점에 `module.canExecute(self)`로 늦게 읽는다**(백엔드가
> `New()` 뒤에 덮어쓰므로 `Init` 시점 캡처는 스텁을 영원히 잡는다). 게이트를 안 부르는
> 잎 모듈만 인스턴스 간 공유된다 — 어느 파일이 잎인지는 **각 파일의 헤더 주석이 소스**
> (여기 나열하지 않는다, 실제로 한 번 갈라졌다). 소스는
> `base/lifecycle-pattern.md` "탑레벨 평범한 함수로 확정" 절의 `H-174` 문단.

바로 위 절이 확정한 `InitRoblox(Module)` 패턴(팩토리가 모듈 테이블을
뮤테이션)은 지금까지 서술상 **backend 주입**에만 적용되는 것처럼 보였는데,
`New()` **자신**이 quad-base 내부 서브시스템(Dispatch 등)을 구성하는
방식도 대칭적으로 같은 패턴을 쓴다 — 새 설계가 아니라 이미 확정된 원칙을
quad-base 자기 자신에도 적용한 구체화. 논의 원문은
`session/2026-08-19-01-new-initxxx-composition-relate-guard.md`.

**사용자 제안 원문 요지**(2026-08-19): *"생성형식 자체는 비싱글톤이고,
Dispatch 같은것도 `Init(module)` 을 받는 함수로써 ... `module.Dispatch = ...`
형식들로 구현되고 ... 재익스포트식으로 구현하겠다는 이야기였음. 처음부터
`InitModuleName` 식으로 구현하여 팩토리를 쌓아 모듈을 리턴하는 방식으로,
quad v1 의 방식을 가져와봄직 하다."*

**형태**(각 서브시스템 파일이 `Init` 함수를 export하고, 타입도 재익스포트):

```lua
-- Dispatch/init.luau
local function Init(module)
    local ... -- 여기서 레지스트리/릴레이션 생성
    module.Dispatch = ...
end
export type Dispatch = ...
return Init
```

```lua
-- 최상위 init.luau
local InitDispatch = require(...)
type Dispatch = InitDispatch.Dispatch -- 재익스포트

local function New(): { Dispatch: Dispatch, New: typeof(New), ... }
    local module = { New = New }
    InitDispatch(module)
    -- 서브시스템 개수만큼 InitXxx(module) 을 순서대로 쌓음
    return module
end

return New()
```

`module = {New = New}` 자기참조는 `base/architecture.md` "확정된 결정"
13번이 이미 확정해둔 것과 정확히 같은 형태 — 별도 결정이 아니라 그 결정이
실제로 어떻게 코드로 나오는지를 구체화한 것뿐.

**타입 재익스포트는 실측 확인됨**(2026-08-19, 사용자: "그거 타입 익스포트
잘 됨") — `type Dispatch = InitDispatch.Dispatch` 형태로 서브모듈의
export 타입을 최상위에서 그대로 재노출하는 게 Luau에서 문제없이 동작한다.
`base/typing-limits.md`가 우려하는 "명시 바인딩 필요" 케이스와는 다른
자리라는 뜻 — 거긴 재귀 제네릭이 자기를 다른 타입 인자로 반환하는 게
문제였고, 여긴 단순 alias라 그 한계에 안 걸린다.

**순서 의존성은 각 `InitXxx`를 `require`처럼 멱등하게 만들어서 해소한다**
(2026-08-19, 사용자 제안) — 서브시스템 간 호출 순서를 최상위 `New()`가
직접 관리할 필요가 없다.

**[2026-08-19 같은 날 후속 정정] 멱등 가드는 `RunInit` 하나로 통합됨 —
파일마다 `Relate()`/`INITED` 센티널을 따로 두지 않는다.** 원래는 각
`InitXxx` 파일이 자기 톱레벨에 `local relate = Relate()`를 두고 파일
전용 센티널 키(`INITED`)로 "이 `module`에 이미 Init됐는가"를 기록하는
보일러플레이트를 파일마다 반복했는데, **사용자 지적**: 그 반복 자체가
불필요하다 — **함수 자기 자신을 릴레이션 키로 쓰면** 센티널이 따로
필요 없다(`Relate<T, (any)->any, boolean>`이 곧 "이 함수, 이 모듈에
실행했는가" 표가 됨). `module` 인스턴스마다 공유하는 `RunInit` 메서드
하나가 이 판단을 전담하고, 개별 `InitXxx` 파일은 **가드 없이 그냥
뮤테이션만** 하면 된다:

```lua
-- 최상위 init.luau
local Relate = require(...)
local runInitRelate = Relate() -- (module, initFn) -> 이미 실행됐는가, 파일 스코프 공유

local function New(): Quad
    local module = { New = New } :: Quad

    function module.RunInit(self, initFn)
        if runInitRelate:GetStrong(self, initFn) then
            return -- 이 module 인스턴스에 이 initFn은 이미 실행됨, no-op
        end
        runInitRelate:SetStrong(self, initFn, true) -- 실행 전에 먼저 표시(순환 의존 대비)
        initFn(self)
    end

    module:RunInit(InitDebug)
    -- 서브시스템이 늘어날 때마다 이 자리에 module:RunInit(InitXxx)를 추가
    return module
end
```

```lua
-- Debug/init.luau — 가드 없이 그냥 뮤테이션만(RunInit이 이미 1회만 보장)
local function Init(module)
    module.debug = false
end
return Init
```

- **의존성을 갖는 `InitXxx`도 패턴이 그대로 유지된다** — 자기 의존성을
  `module:RunInit(InitLifetime)`처럼 부르기만 하면 되고, `RunInit` 자체가
  멱등하므로 여러 `InitXxx`가 같은 의존성을 부르는 순서/중복은 걱정할
  필요 없다(옛 설계와 결론은 같음, 가드 소유 위치만 파일별→공유로 이동).
- **GC와도 자연히 맞물림** — `relate-plan.md`의 "API" 절에 따르면
  `Relate`의 **첫 인자(`inst`, 여기선 `module`)는 항상 weak**이므로,
  `Quad` 인스턴스가 더 이상 참조되지 않아 수거되면 이 Init-완료 기록도
  같이 사라진다(별도 정리 로직 불필요, `value`는 `SetStrong` — boolean
  리터럴이라 GC 결과엔 무관하지만 "다른 곳에서 안전하게 유지되는 것만
  `SetWeak`" 일반 규칙에 맞음).
- **백엔드 설치 가드(`UseProvider`)와는 여전히 다른 층위** — 그건
  backend 팩토리가 유일 슬롯을 채웠는지 **누가** 채웠는지까지 구분해야
  하는 공개 계약(같은 프로바이더 재호출=no-op, 다른 identity=에러)이고,
  `RunInit`은 quad-base 내부 서브시스템이 **한 번만** 도는지만 보면 되는
  사적 구현 디테일이라 "다른 호출자면 에러" 분기 자체가 없다.
  **[2026-08-19 해소, 사용자 결정] `RunInit`은 backend 설치에 재사용
  안 함** — `RunInit`은 "이 함수가 이미 돌았는가"만 답하고, 슬롯 점유
  판정을 억지로 얹으면 "멱등 실행"과 "유일 슬롯 점유"라는 다른 두 의미가
  API 하나에 섞여 단순함이 깨진다. 이 절반은 그대로 유효하다 —
  `UseProvider`는 `RunInit`의 재사용이 아니라 **별도 진입점**이다.
  **⚠️ [2026-09-02 부분 역전 — `H-305` (d′), 사용자 확정] 슬롯 마커의
  구현은 문자열(`_initializedBy = "roblox"`)에서 `UseProvider`의
  **fn identity 락**으로 교체됐다.** 사용자 진단: 문자열 마커는 **다른
  곳에서 로드된 quad-roblox의 다른 사본**(특히 버전이 다른)을 구분 못 해
  두 번째 설치가 조용히 no-op으로 묵인된다 — *"다른 곳에서 로드된 두
  quad-roblox(특히 버전이 다르다던가 등) 은 실패 없이 묵인 처리 돼"*.
  identity 락은 require 캐싱 덕에 일반 케이스(같은 모듈 재-require)는
  같은 fn identity로 자연 통과하고(사용자 근거), 사본·버전이 갈리면
  identity가 갈려 시끄럽게 error난다. 락은 개별 팩토리가 아니라
  **quad-base의 `UseProvider` 본문**에 산다(프로바이더 작성자가 가드를
  빠뜨리는 `H-294`류 실수를 구조적으로 차단) — `providerRelate`
  (module 당 1슬롯, `runInitRelate`와 같은 weak-키잉). 이름도 사용자
  확정(*"UseProvider 쓰자"*) — `AddPlugin`(다수 허용·확장 누적)과 계약이
  달라 이름을 가른다. 경위 원문은
  `session/2026-09-02-04-h305-useprovider.md`.

  ```lua
  -- 실구현 스케치(quad-base/src/init.luau — 정본은 코드)
  function module.UseProvider(self, providerFn)
      local current = providerRelate:GetStrong(self, "provider")
      if current == providerFn then return self end -- 멱등 no-op
      if current ~= nil then
          Err.errorBefore("Quad module already has a provider; ...", SURFACE)
      end
      local extension = providerFn(self) -- 팩토리는 뮤테이션 + 타입드 확장 반환
      mergeExtension(self, extension) -- AddPlugin과 공용 병합 → Self & P
      providerRelate:SetStrong(self, "provider", providerFn) -- 마킹은 성공 후
      return self
  end
  ```

  마킹이 RunInit(실행 전 표시)과 달리 **성공 후**인 이유(리뷰 `H-307`,
  2026-09-02): RunInit의 선표시는 순환 의존 대비인데 프로바이더 설치엔 그
  계약이 없고, 선표시는 providerFn이 도중 던졌을 때 슬롯만 점유된 채
  재시도가 멱등 no-op로 삼켜지는 좀비를 만든다.

  `RunInit`(quad-base 내부 서브시스템)·`UseProvider`(backend 유일 슬롯)·
  `AddPlugin`(다수 확장)은 **서로 다른 메커니즘**으로 남는다. 백엔드
  팩토리(`RobloxFactory`)는 자기 가드 없이 ops를 뮤테이션하고 타입드
  확장(`RobloxExtension = { D: D }`)만 반환한다 — `q.D`가 `Self & P`
  교집합으로 캐스트 0에 풀 타입이 실리는 게 이 모양의 핵심 이득
  (round14 `H-305` (d) 실측 + `luau-test` 스파이크 23 선례).
- **플래그를 실제 작업 전에 먼저 세우는 이유**: 나중에 `InitA`↔`InitB`처럼
  상호 의존이 생기면([2026-08-19 기준] 지금은 없음, 대비만), 먼저
  표시해두지 않으면 무한 재귀에 빠진다 — `require`가 순환 참조 시
  미완성 exports를 돌려주는 것과 같은 이유로, 실제 작업 시작 전에 먼저
  "완료"로 표시해둔다.
- **실측**: `quad-base/src/init.luau`+`Debug/init.luau`가 위 코드
  그대로 구현돼 있고, `quad-base/test/smoke.init.luau`가 (a) 같은
  `initFn`을 여러 번 `RunInit`해도 1회만 실행, (b) `New()`로 만든
  서로 다른 인스턴스는 기록을 공유하지 않음(각자 독립 1회), (c) 서로
  다른 `initFn`은 서로의 실행 여부에 영향 안 줌 — 셋 다 `luau`/
  `luau-analyze`/`selene` 클린으로 확인.

## Bind는 누가, 어떻게 구현하는가

인터페이스 상 `bind`를 두고 이것도 pluggable하게 할지 고민 — 단 **1개만 존재할
수 있는 형태**로 구현하는 게 맞다고 기울어짐: 이미 bind 구현체가 있는데 또
init하려 하면 오류, 없는데 뭔가 생성해서 bind하려 해도 오류. 즉 "pluggable
슬롯이지만 유일하게 채워질 수 있는 슬롯" — 위의 `base/bind-system-plan.md`가
말하는 "여러 핸들러가 우선순위로 경쟁"하는 것과는 다른 층위: **핸들러
레지스트리 자체(그 배후의 실제 bind 구현/백엔드)는 유일해야 하고, 그 안에
등록되는 개별 핸들러들은 여럿+우선순위 경쟁이 맞는 모양.**

의존성을 부작용 식으로 주입해서 `quad-roblox` 바인드를 허용케 하는 건 괜찮아
보임(=`InitRoblox(Module)`가 하는 일이 바로 이 "유일 슬롯 채우기").

## Store는 누구 몫인가 — 상당 부분 확정됨

**사용자 확인 완료**: base가 `LifetimeHandle` 추상화(생명주기/`Connected`
계산 속성)를 소유하는 게 맞다고 확정. 추가로 명확해진 것 — **store 바인드가
수행하는 "처리된 값을 다시 `Dispatch.process(inst,k,realv)`로 넘기는" 재실행
로직 자체도 base가 한 번만 구현**해야 함(모든 백엔드/핸들러가 각자
재구현하면 안 됨). 근거: "모든 곳에서 다시 구현하는 건 나쁘니까." →
`base/dispatch-core-plan.md`의 "확정된 디스패치 모델"/`Dispatch` 네이밍 절이
바로 이 base 제공 로직.

부수적으로 확인된 것:
- **Store 자체의 연산은 더 단순해져도 됨** — v1의 `:Add`/`:With`/`:Tween` 같은
  이름 붙은 체이닝 연산(named modifier)은 명시적으로 안 만들기로 확정, 대신
  일반 함수를 받는 형태로 통일(`base/source-state-plan.md` 참고). "너무 verbose한
  연산들은 오히려 일관성을 해친다"는 게 이유. (주의: 아래의 v2 `:With(...)`는
  이름만 같을 뿐 여기서 안 만들기로 한 v1의 `:With`와는 다른 연산임 — v1은
  "함수/테이블에서 값을 가져오는" 가공 연산이었고, v2는 그냥 "여러 State를
  의존성으로 모으는" 수집 연산.)
- **여러 store 값을 묶어 유연하게 처리하는 방법**(`useEffect`류 dependency
  array)은 있으면 좋겠다는 요청이었고 — **API 시그니처도 확정됨**:
  `:With(...)`로 의존성을 모으고 `:Compute(fn)`으로 파생 State를 만드는
  형태, 상세는 `base/store-plan.md`의 "여러 스토어 값을 묶어 처리하는
  것" 절 참고.
- `can execute store bind` 후킹 자체는 `Connected` 계산 속성으로 대체된다는
  잠정 제안이 그대로 유지되고, 여기에 더해 **완전 소멸(Destroy) 시점엔 아무
  처리도 필요 없다**는 원칙까지 확정됨(`base/lifecycle-pattern.md`) — 즉 이
  질문은 "필요한가?"에서 "확정된 Connected 체크 하나로 충분하다"로 정리됨.
- 여러 `isHandlable`이 되는 플러그를 매번 우선순위 순으로 스캔하는 비용은
  여전히 실제 구현/벤치마크 단계에서 검증 필요 — 디자인 자체는 확정됐으므로
  더 이상 사용자 자문 대상이 아니라 구현 검증 대상.

## 모듈 스코핑 (참고, 확정은 `base/architecture.md` 13번)

한 Lua 스레드에서 둘 이상의 모듈 분화체(Roblox+비Roblox 동시)를 쓸 일이
거의 없을 거라 판단, 지금은 싱글톤으로 두고 필요해지면 다중 인스턴스화를
추가. **[정정, 2026-08-18, 재정정 2026-08-19]** "코드 변경 없이 자동으로
스코핑"되는 게 아니라 module-level state를 참조하는 코드들이 모듈
인스턴스를 인자로 받도록 손봐야 한다. 이름은 `Quad()`가 아니라
**`New()`가 맞음**(2026-08-18에 한 차례 `Quad()`로 잘못 정정됐다가
바로잡힘) — `Quad`(`require`의 반환값)는 이미 만들어진 기본 인스턴스고,
`New()`는 그 안에서 명시적으로만 부르는 opt-in 필드다. 상세는
`base/architecture.md` "확정된 결정" 13번이 소스.

## 모듈 표면의 디버그 플래그 — `Quad.debug` (2026-08-18 신설, 사용자 요구)

**`Quad.debug: boolean`(기본 `false`)** — 라이브러리 자체의 디버그 모드
스위치. 지금 이 플래그가 게이팅하는 것은 **핸들러 우선순위 동률 경고
print**(`base/dispatch-core-plan.md`의 "핸들러 계약" 절)이고, 앞으로
"개발 중에만 켜고 싶은" 진단 출력은 전부 여기 얹는다. 사용자 요구
원문과 배경은 그 문서에 있음.

- **기본이 `false`인 이유**: 라이브러리가 사용자 콘솔에 아무것도 안 찍는
  게 기본이어야 함. 켜는 건 명시적 opt-in.
- **[해소, 2026-08-24 6라운드 손 트레이싱 `H-48`] 다중 인스턴스화 시
  **인스턴스별**이다 — M1이 이미 그렇게 확정했다.** 여기 "미정"으로 남아
  있었지만, 커밋된 `quad-base/src/Debug/init.luau`가 `module.debug = false`로
  **인스턴스 필드**를 심고 `quad-types/src/init.luau`의 `Quad` 타입도
  `debug: boolean`을 필드로 갖는다. 결함은 아니지만 다음 세션이 "아직 정할
  게 남았다"고 읽고 전역으로 바꾸려 들 수 있어 여기서 닫는다.
- **[해소, 2026-08-20 구현 전 QA 4라운드 `D-8`/`ML-9`] `Dispatch.listHandlers()`는
  이 플래그와 무관하게 항상 호출 가능하다** — 순수 조회(목록 **반환**만 하고
  스스로 출력하지 않음)라 게이팅 대상이 아니다. 출력할지는 호출부가 정한다.
  상세는 `base/dispatch-core-plan.md`의 "우선순위 동률/매치 실패 처리" 절.

## Quad는 스크립트인가 라이브러리인가 (확정, 참고용)

이전엔 Instance를 보조하는 역할이라 "스크립트"로 분류했지만, 지금은 확실히
"라이브러리" — 구조화되어 있고 데이터 타입이 존재함. 기능을 각자 따로 묶는 게
아니라 하나의 시스템으로 돌 수 있게(pluggable 하게 두자는 논리의 근거이기도
함). `base/architecture.md` 도입부와 동일 결정.

## 열린 질문이었던 것 — 전부 해소됨 (2026-08-08 두 번째 세션 정리)

**이 문서 상단 "상태" 줄이 이미 "확정되어 승격됨"이라고 말하고 있었는데도
이 절 자체는 오래 stale로 방치돼 있었음** — 아래 4개 항목 중 2/3번은 그 뒤
`base/bind-system-plan.md`의 Handler 계약 확정으로 이미 풀렸는데 여기
반영이 안 됨. 원문은 남기고 각각에 해소 표시만 추가:

- **Store 책임 분리(base vs provider)는 확정됨** — 위 절 참고. ~~남은 건
  실제 구현 단계에서 base의 `LifetimeHandle`/재실행 유틸 API를 정확히
  어떻게 노출할지 정도~~ **[해소됨]** 노출 방식도 확정 — `bindLifetime`/
  `canExecute`는 네임스페이스 없는 탑레벨 함수(`base/lifecycle-pattern.md`),
  케이싱까지 포함해 `base/architecture.md` "코드 스타일 — 네이밍 케이싱"
  절 참고.
- ~~넘버 바인드/프로바이더 인터페이스의 정확한 함수 시그니처(base가 요구하는
  provider 인터페이스 계약)는 아직 미정~~ **[해소됨]** — 그 "provider
  인터페이스"가 곧 Handler 계약: `isHandlable(inst,key,value)`/
  `priority`/`process(inst,key,value,index)` **3종**(**[정정, 2026-08-13
  다섯 번째 세션]** 원래 별도 `retract(inst,key,value)` 필드가 있던 4종
  계약이었으나, `process`가 자기 retract 클로저(현행 시그니처는
  `(nextValue: any?, retracting: boolean) -> ()` — [2026-09-01 `H-258`])를
  반환하는 1-메소드로 합쳐짐), 정리할 게 없어도 `Void`(**[2026-08-28 `H-162`]** 단일 no-op)
  반환 생략 불가까지 확정. `base/dispatch-core-plan.md` "핸들러 계약" 절.
- ~~**네이밍 미정(2026-08-04 보강)**: "프로바이더"라고 불러온 개념을 정확히
  뭐라고 부를지("provider" vs "processor" vs 그냥 "plug") 아직 안 정함~~
  **[해소됨]** — **`Handler`로 확정**, 위 항목이 가리키는 계약의 정식 이름.
  `Dispatch`(그 계약을 스캔/실행하는 엔진, 프리미티브 아닌 탑레벨 싱글톤)와
  구분해서 쓸 것 — `base/dispatch-core-plan.md` "Dispatch는 프리미티브가
  아니다" 절. **왜 다른 후보들을 기각했는지(2026-08-08 세션, 재확인)**:
  `Processor`는 계약 메소드 자체가 `process`라 이름 안에 같은 단어가
  겹쳐 눈에 거슬림, `Provider`는 `canProvide`처럼 "뭔가를 공급한다"는
  늬앙스인데 Handler는 실제로 값을 공급하는 게 아니라 처리/반응하는
  쪽이라 의미가 안 맞고 React `Context.Provider`류 맥락(context) 패턴과도
  헷갈릴 수 있음, `Plug`는 "동적으로 꽂힌다"는 어감은 맞지만 "값을
  처리한다"는 의미가 빠져 있음 — `Handler`가 계약 전체
  (`isHandlable`/`priority`/`process`, 위 항목 참고)를 가장 정확히
  담는다는 결론.
- **[해소됨, 2026-08-12 열일곱 번째 세션]** provider(팩토리)가 아직 한
  번도 실행 안 된 상태에서 dispatch가 호출되면 어떻게 되는지
  (`pre-implementation-audit.md` 1-4) — 별도 케이스로 처리하지 않음.
  provider 미주입 상태는 결국 그 클래스의 핸들러가 레지스트리에 하나도
  없는 상태이므로, `base/dispatch-core-plan.md` "우선순위 동률/매치 실패
  처리" 절의 일반 "매치 실패 시 즉시 error" 규칙 하나로 자연히 커버됨.
- base 유틸(per-instance 상태 저장소, 생명 바인드 유틸)이 인터페이스만 두고
  실제 구현은 백엔드 팩토리(`RobloxFactory(BaseModule)`류)가 뮤테이션으로
  주입한다는 패턴이 확정됨. **[2026-08-13 열네 번째 세션] 주입 대상 목록에
  Tag/Attribute용 엔진 op이 추가됨** — `addTag(inst,{string})`/
  `removeTag(inst,{string})`/`setAttribute(inst,name,v)`(`v==nil`이면 삭제).
  **[2026-08-22 정정] 여기 "엔진 op 3개"라고 세어놨으나 그 셋이 전부가
  아니다** — 이후 `native*` 물리 조작 계층과 `setTimeout`/`clearTimeout`이
  같은 팩토리 뮤테이션 경로에 추가됐다. **주입 op 전체 목록의 소스는
  `base/architecture.md`의 소스 트리 안 `EngineOps.luau` 줄** — 여기서
  세지 않는다. `Tag`/`Attribute`의 부기
  알고리즘이 통째로 quad-base로 옮겨오면서, 엔진에 실제로 손대는 마지막
  한 줄만 이 경로로 주입받게 됨(`base/dispatch-core-plan.md` "base가
  소유하는 핸들러와 주입되는 엔진 op" 절). **`TagHandler`/
  `AttributeKeyHandler`/`AttributeGroupHandler` 자신은 참조 카운트/이름
  claim 알고리즘 구현일 뿐 스스로 등록되는 주체가 아님(2026-08-14 열두
  번째 세션 정정, 옛 "quad-base 모듈 로드 시점에 스스로 등록" 모델은
  `archive/tag-attribute-load-time-registration-reversed.md`) —
  `HANDLER_PRIORITY_FALLBACK`에 실제로 꽂히는 건 이걸 감싸는
  `TagFallbackHandler`/`AttributeKeyFallbackHandler`/
  `AttributeGroupFallbackHandler`이고, **[재역전, 2026-08-18 구현 전 QA]
  등록 주체는 백엔드 팩토리가 아니라 quad-base 자신**(백엔드 미로드
  상태에서도 안내 에러 경로가 돌아야 하기 때문 — `base/dispatch-core-plan.md`의
  "base가 소유하는 핸들러와 주입되는 엔진 op" 절이 소스. 이 문서의 일반
  원칙 "등록/구현은 팩토리 뮤테이션 시점"의 **명시적 예외**이고, 예외인
  이유는 이 핸들러들이 "아무도 자리를 안 가져갔을 때"를 위한 것이라
  누군가 자리를 가져가는 시점에 등록되면 자기 목적을 못 이루기 때문).**
  즉 이 경로에서 백엔드 팩토리가 뮤테이션으로 채우는 건 **핸들러가 아니라
  엔진 op 쪽**이다(**[2026-08-22 정정]** 여기 "`addTag`/`removeTag`/
  `setAttribute`**만**"이라고 셋으로 못박혀 있었으나 위와 같은 이유로
  그 셋이 전부가 아니다). 아직 아무 팩토리도 안 채운 슬롯의
  기본값은 quad-base가 명시적으로 에러내는 스텁으로 미리 채워둠(조용한
  no-op 추측 아님 — base가 임의 엔진의 "맞는 기본 동작"을 알 수 없어서).
  더 명확한 메시지나 진짜 원자적 실패(부기 mutation 0회)를 원하는
  백엔드는 opt-in으로 `HANDLER_PRIORITY_FALLBACK + 1`짜리 가로채기
  Handler를 추가로 등록할 수 있음 — 상세는
  `base/dispatch-core-plan.md`의 같은 절. **중복 호출
  가드/`New()`와의 관계는 2026-08-04 3차 라운드에서 확정**: 같은 팩토리로
  재호출하면 무시(no-op), 다른 팩토리로 재호출하면 에러(유일 슬롯 충돌 —
  바로 위 "Bind는 누가, 어떻게 구현하는가" 절의 원칙과 일치) — `New()`가
  실제로 호출되면 그 인스턴스별 테이블이 분리되므로 이 가드도 자연히
  인스턴스별로 스코핑됨(**[한정, 2026-08-18 `/code-review high`, 이름
  재정정 2026-08-19]** 위 "모듈 스코핑" 절의 정정과 맞춰 — "자동으로"는
  아니고 module-level state를 참조하는 코드는 손을 봐야 함, 그 손질까지
  하고 나면 이 가드 자체는 재설계 불필요라는 뜻). **이 결론이 Dispatch의
  handler 레지스트리에도
  그대로 적용된다는 게 2026-08-08 두 번째 세션에서 재확인/일반화됨** —
  `base/dispatch-core-plan.md` "Dispatch는 프리미티브가 아니다" 절.
