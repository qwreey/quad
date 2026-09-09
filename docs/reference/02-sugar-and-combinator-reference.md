# [API Reference] 순수 슈거 및 오퍼레이터 레퍼런스 (Sugar & Combinators)

Quad의 코어 온톨로지(`Source`, `State`, `Store`, `Slot`, `Modifier`, `Ref`) 위에 얹힌 **순수 슈거**와 **오퍼레이터 콤비네이터**의 레퍼런스입니다. 여기 있는 것들은 전부 `quad-base`에 살고, 새 디스패치 개념이나 새 코어 메커니즘을 만들지 않습니다 — 이미 있는 프리미티브(`Ref`/`Blocker`+`state:Gate`/`Effect`/`:Compute`)와 주입된 시간 op 위의 얇은 층입니다.

이 문서의 모든 예제는 아래 프롤로그를 전제합니다.

```luau
-- 설치 경로는 프로젝트 구성에 따라 다르다(00-installation 참고)
local Quad = require(<quad-base 모듈 경로>)
local QuadTypes = require(<quad-types 모듈 경로>)
local QuadRoblox = require(<quad-roblox 모듈 경로>).QuadRoblox
local q = Quad:UseProvider(QuadRoblox) -- quad-roblox 백엔드 설치: D/Tween/Animate/OnChange가 생긴다
local D = q.D
```

---

## 1. `Ref:Unwrap()` — 런타임 보장 언랩

### 1.1 배경 및 목적

children 배열에 놓인 `PreRef`는 pre-pass에서 채워지고, 이벤트 콜백은 그 뒤에만 불립니다. 그래서 콜백 안에서 `.Value`가 nil일 수 없는데, 타입은 여전히 `Ref<TextButton?>`라 매번 `if inst then` 가드를 써야 했습니다. `ref:Unwrap()`은 그 자리를 위한 슈거입니다 — 값을 돌려주면서 **타입에서 `nil`만 벗깁니다**(`StripNil<T>` 타입 함수).

### 1.2 시그니처와 에러

`Unwrap: (self: Ref<T>) -> StripNil<T>` — `quad-types`의 `Ref<T>`에 붙어 있는 메소드입니다.

- **값이 있으면**: 그 값을 그대로 반환하고, 타입은 `T`에서 `nil` 성분만 제거됩니다(`number?` → `number`).
- **비어 있으면**: 호출한 줄을 blame하며 던집니다 —
  `Ref:Unwrap: the Ref is empty (Value is nil) — not filled yet, or never placed`

런타임 동작은 `Ref`/`PreRef`/`PostRef` 공통입니다. "런타임 보장이 있는 자리에서만 쓴다"는 **규약이지 강제가 아닙니다** — 빈 Ref에 부르면 그 줄에서 죽습니다.

### 1.3 사용 예제

```luau
local btnRef = q.PreRef(nil :: TextButton?)

local button = D.TextButton {
    btnRef,
    Text = "Send",
    Activated = function()
        -- 가드 없이 바로 쓴다(타입 체커도 통과)
        btnRef:Unwrap().BackgroundTransparency = 0.5
    end,
}
```

---

## 2. `Context` / `Context.Provider` — 명시적 타입드 컨텍스트

### 2.1 설계

Quad의 `Context`는 트리를 거슬러 올라가는 암묵적 컨텍스트가 **아닙니다**. 아무것도 트리에서 조회하지 않고, 컴포넌트는 이름 붙은 파라미터로 가방을 받아 자기 키만 읽습니다. 핵심은 중간 계층 — 앱의 스토어 스키마를 모르는 셸이나 레이아웃 컴포넌트가, 스토어 타입을 하나하나 적지 않고 `Context` 하나만 아래로 넘길 수 있게 하는 것입니다.

- **키는 테이블 신원**입니다. `Context.Provider(name?)`가 만드는 값은 매번 서로 다른 frozen 테이블이라 모듈 간 문자열 키 충돌이 없습니다. `name`은 에러 메시지와 `tostring`에만 쓰이는 선택 인자입니다.
- **가방은 강참조**로 값을 붙들고, 열거 표면은 없습니다. **`Set`은 부르는 그 가방을 변경**하고 self를 반환합니다(체이닝) — 부모 가방을 서브트리용으로 확장하려면 만드는 쪽이 먼저 복사해야 합니다.

### 2.2 API

가방 타입은 `QuadTypes.Context`, 키 타입은 `QuadTypes.Provider<T>`이고 메소드는 셋입니다.

```
Set:  <T>(self: Context, provider: Provider<T>, value: T) -> Context
Get:  <T>(self: Context, provider: Provider<T>) -> T
Peek: <T>(self: Context, provider: Provider<T>) -> T?
```

| 호출 | 동작 |
|---|---|
| `q.Context()` | 빈 가방 |
| `q.Context.Provider(name?)` | 고유 키. `T`는 팬텀 제네릭이라 `Get`의 결과 타입이 여기서 나온다 |
| `ctx:Set(p, v)` | 등록(덮어쓰기), self 반환. **`v`가 `nil`이면 에러** — 부재는 "안 넣은 것"이지 `nil`을 넣은 것이 아니다 |
| `ctx:Get(p)` | 값. **없으면 에러**(`no value for Provider(Theme)`) |
| `ctx:Peek(p)` | 값 또는 `nil` — "있는지" 확인용 |

키 자리에 Provider가 아닌 값을 넣으면 세 메소드 모두 `key must be a Provider from Context.Provider()`로 막습니다. `false`는 값입니다 — 부재로 취급되는 것은 `nil`뿐입니다.

**타입은 만드는 자리에서 한 번 붙입니다.** `Provider<T>`의 `T`는 값에 없는 팬텀이라 캐스트(`:: QuadTypes.Provider<T>`)나 명시적 타입 인자(`q.Context.Provider<<T>>("Theme")`) 중 하나로 적어주면, 그 뒤로는 `Get`이 알아서 추론됩니다(둘 다 구·신 솔버에서 통과).

```luau
type Theme = { ButtonBg: Color3 }
local ThemeProvider = q.Context.Provider("Theme") :: QuadTypes.Provider<Theme>
local UserProvider = q.Context.Provider("User") :: QuadTypes.Provider<{ Name: string }>
```

### 2.3 실전 사용 패턴

컴포넌트는 플레인 함수이므로, 중간 계층은 그냥 파라미터를 하나 더 받는 함수입니다.

```luau
-- 리프 컴포넌트 — 필요한 키만 꺼내 쓴다
local function ThemedButton(props: { Context: QuadTypes.Context }): TextButton
    local theme = props.Context:Get(ThemeProvider)
    return D.TextButton { BackgroundColor3 = theme.ButtonBg }
end

-- 중간 셸 — Theme/User가 뭔지 모른 채 가방만 내려보낸다
local function AppShell(props: { Context: QuadTypes.Context, Content: Instance }): Frame
    return D.Frame {
        ThemedButton({ Context = props.Context }),
        props.Content,
    }
end

local rootCtx = q.Context()
    :Set(ThemeProvider, { ButtonBg = Color3.fromRGB(40, 40, 40) })
    :Set(UserProvider, { Name = "q" })

local maybeUser = rootCtx:Peek(UserProvider) -- 없으면 nil
```

---

## 3. `Debounce` / `Throttle` — 시간 기반 반응형 게이트

### 3.1 메커니즘

`Debounce{...}` / `Throttle{...}`는 **팩토리**를 돌려주고, `state:Apply(factory)`로 붙입니다. `:Apply` 한 번이 게이트 노드 하나(자기 Blocker, 자기 타이머)를 만듭니다.

- **`Debounce`**: 상류 신호가 올 때마다 창을 다시 엽니다 — 신호가 멎은 뒤에 통과.
- **`Throttle`**: 창 길이가 고정입니다 — 신호가 창을 리셋하지 못합니다.
- 둘은 구현이 하나이고 `reset` 비트 하나만 다릅니다.

**게이트는 통지만 유보합니다.** 창이 열려 있는 동안에도 `:Get()`은 언제나 상류의 최신 값을 돌려줍니다 — 값을 가리는 게 아니라 하류 알림을 미루는 것입니다.

시간은 백엔드가 주입한 `setTimeout`/`clearTimeout` 위에서 흐릅니다(Roblox는 `task.delay`/`task.cancel`).

### 3.2 옵션

| 옵션 | 타입 | Debounce 기본값 | Throttle 기본값 | 설명 |
| :--- | :--- | :--- | :--- | :--- |
| `Time` | `number \| State<number>` | **필수** | **필수** | 창 길이(초). 음수·NaN은 에러 |
| `Leading` | `boolean?` | `false` | `true` | 창이 열릴 때 첫 신호를 즉시 통과시킬지 |
| `Trailing` | `boolean?` | `true` | `true` | 창이 닫힐 때 보류분을 통과시킬지 |
| `MaxTime` | `(number \| State<number>)?` | `nil` | **에러** | 신호가 안 끊겨도 최대 이 간격마다 강제 통과 |
| `Handle` | `Ref<GateHandle?>?` | `nil` | `nil` | 수동 Flush/Cancel 제어 핸들을 받을 Ref |

- `Leading`과 `Trailing`을 **둘 다 `false`로 주면 에러**입니다(아무것도 통과하지 못하므로).
- `MaxTime`은 **Debounce 전용**입니다. Throttle에 주면 `Throttle: MaxTime is Debounce-only (a throttle already passes every Time)`로 막힙니다.
- `Time`/`MaxTime`에 `State`를 줘도 **구독하지 않습니다** — 타이머를 거는 시점에만 한 번 읽습니다. 이미 걸린 타이머는 자기 지연을 유지합니다.

### 3.3 제어 핸들 (`GateHandle`)

`Handle`에 `q.Ref(nil :: QuadTypes.GateHandle?)`를 넘기면 **`:Apply` 시점에** 그 Ref가 제어 핸들로 채워집니다(마운트 시점이 아닙니다).

핸들 타입은 `QuadTypes.GateHandle`이고 메소드는 둘입니다.

```
Flush:  (self: GateHandle) -> ()   -- 보류분이 있으면 지금 통과(+창 재개방), 없으면 no-op
Cancel: (self: GateHandle) -> ()   -- 보류분을 버리고 idle로(전파 없음)
```

**Ref 하나는 `:Apply` 하나를 가리킵니다.**

이미 채워진 Ref를 다시 넘기면 — 팩토리를 재사용하며 같은 Handle을 쓰는 경우가 전형적입니다 — 그 자리에서 에러가 납니다:

```
Throttle: Handle is already filled — one Handle Ref per :Apply (make a new Ref, or drop
Handle and use the factory's :Flush()/:Cancel() broadcast; a Ref with a non-nil default is
rejected the same way)
```

기본값이 `nil`이 아닌 Ref도 같은 이유로 거부됩니다.

여러 게이트를 한꺼번에 제어하고 싶다면 Handle 대신 **팩토리 브로드캐스트**를 쓰십시오 — `factory:Flush()` / `factory:Cancel()`은 그 팩토리가 만든 모든 게이트에 전파됩니다.

### 3.4 실전 사용 예제

```luau
-- 검색창 디바운스(0.3초, 1초마다는 강제 실행)
local searchInput = q.Source("")
local debouncedSearch: QuadTypes.State<string> = searchInput:Apply(q.Debounce {
    Time = 0.3,
    MaxTime = 1.0,
})

-- Observer 콜백은 값이 아니라 대상 State 핸들을 받는다 — 값은 :Get()으로 읽는다.
-- 구독을 유지하려면 :Subscribe()(또는 children 배열에 넣어 인스턴스에 바인딩)해야 한다.
debouncedSearch:Observer(function(target)
    print("API 검색 실행:", target:Get())
end):Subscribe()
```

---

## 4. `Operator` — 선언적 함수형 콤비네이터

### 4.1 도입 목적

`:Compute(function(h) return not h:Get() end)` 같은 보일러플레이트를 없애고, **의존성 캡처가 어긋날 수 없는 재사용 가능한 이름**을 주기 위한 것입니다. 팩토리가 자기 deps를 직접 `:Compute`에 넘기므로, 한 번 이름 붙인 연산자를 여러 State에 `:Apply`해도 deps가 따라갑니다 — 그게 `:Compute`가 아니라 `:Apply`인 이유입니다.

숫자 인자는 **plain 숫자든 `State<number>`든** 됩니다. plain 값은 상수로 캡처되고, State는 의존성으로 등록됩니다. 인자가 `nil`이거나 타입이 안 맞으면 팩토리를 부르는 그 줄에서 에러입니다.

> **산술·비트 연산자는 숫자 전용입니다.** `Sum`/`Product`/`Min`/`Max`/`Clamp`와 `Band`~`Shr`는 인자뿐 아니라 **`:Apply`를 받는 State의 값도** 숫자여야 합니다. `UDim2`나 `Color3` 같은 타입에 쓰면 타입 검사에서 `None of the overloads for function that accept 2 arguments are compatible`로 막힙니다 — 그런 연산은 `:Compute`로 직접 쓰세요. 값 타입을 가리지 않는 것은 `Not`(어떤 값이든 받아 `State<boolean>`을 낸다), `Alternative`, `Index` 셋입니다.

### 4.2 전체 목록

| 연산자 | 모양 | 뜻 |
|---|---|---|
| `Not` | `state:Apply(Op.Not)` | 논리 부정(단항 — 팩토리 자체를 넘긴다) |
| `Sum` | `Op.Sum(...)` | self + 인자들 |
| `Product` | `Op.Product(...)` | self × 인자들 |
| `Min` | `Op.Min(...)` | self와 인자들의 최소 |
| `Max` | `Op.Max(...)` | self와 인자들의 최대 |
| `Clamp` | `Op.Clamp(lo, hi)` | `math.clamp` |
| `Band` | `Op.Band(...)` | `bit32.band` 폴딩 |
| `Bor` | `Op.Bor(...)` | `bit32.bor` 폴딩 |
| `Bxor` | `Op.Bxor(...)` | `bit32.bxor` 폴딩 |
| `Bnot` | `state:Apply(Op.Bnot)` | `bit32.bnot`(단항) |
| `Shl` | `Op.Shl(n)` | `bit32.lshift` |
| `Shr` | `Op.Shr(n)` | `bit32.rshift` |
| `Alternative` | `Op.Alternative(default)` | 널 병합 — `State<T?>` → `State<T>` |
| `Index` | `Op.Index<<V>>(key)` | 반응형 필드 읽기 |

**의도적으로 없는 것**: `And`/`Or`, 비교 연산(`Eq`/`Lt` 등), `Sub`/`Div`.

### 4.3 사용 예제

```luau
local Op = q.Operator
type State<T> = QuadTypes.State<T>

-- 1. 논리 부정 — 단항은 팩토리를 그대로 넘긴다(호출하지 않는다)
local isVisible = q.Source(true)
local isHidden: State<boolean> = isVisible:Apply(Op.Not)

-- 2. 산술 폴딩 — 인자는 State든 plain 숫자든 섞어 쓸 수 있다
local basePrice, taxState, shippingState = q.Source(1000), q.Source(100), q.Source(50)
local totalPrice: State<number> = basePrice:Apply(Op.Sum(taxState, shippingState, 500))

-- 3. 최소/최대/클램프
local posX, maxXState = q.Source(150), q.Source(100)
local boundX: State<number> = posX:Apply(Op.Clamp(0, maxXState))

-- 4. 비트 연산(bit32 래핑)
local flags = q.Source(0b1100)
local masked: State<number> = flags:Apply(Op.Band(0b1010))
local shifted: State<number> = flags:Apply(Op.Shl(2))
local inverted: State<number> = flags:Apply(Op.Bnot)

-- 5. 널 병합
local optionalName = q.Source(nil :: string?)
local safeName: State<string> = optionalName:Apply(Op.Alternative("Guest"))
```

### 4.4 `Index<<V>>(key)` — 결과 타입은 호출자가 준다

`Index`만 다른 연산자와 계약이 다릅니다. **키에서 결과 타입을 추론하는 형태는 지금 솔버로 표현할 수 없어서**, 값 타입을 호출자가 명시적 타입 인자로 직접 적습니다.

```luau
type Palette = { Primary: string, Size: number }
local palette = q.Source({ Primary = "red", Size = 10 } :: Palette)

local primary: State<string> = palette:Apply(Op.Index<<string>>("Primary"))
local size: State<number> = palette:Apply(Op.Index<<number>>("Size"))

-- 없는 키는 nil이다 — 게이트가 없다(타입을 적은 사람이 책임진다)
local missing: State<string?> = palette:Apply(Op.Index<<string?>>("Nope"))
```

런타임은 `h:Get()[key]` 한 줄입니다. 상류 값이 테이블이 아니면 읽는 시점에 에러입니다(`Operator.Index: value is not a table (got number) — cannot read [x]`). `key`가 `nil`이면 팩토리 호출 즉시 에러입니다.

---

## 5. 생명주기 훅 — `OnCreated` / `OnRendered` / `OnDestroyed`

셋 다 **순수 팩토리**입니다. 새 브랜드도, 새 디스패치 개념도 없습니다 — 돌려주는 값은 각각 `PreRef` / `PostRef` / `EffectHandle` 그 자체이고, children 배열에 그대로 놓입니다. 그래서 여러 번 등록하는 것은 그냥 배열 자리를 여러 개 쓰는 일이고, **같은 종류끼리의 상대 순서는 배열 index 순서**입니다.

| 훅 | 반환 | 불리는 시점 |
|---|---|---|
| `OnCreated(fn)` | `PreRef<I?>` | 인스턴스가 만들어진 직후, 이 인스턴스에 아무 일도 일어나기 전 |
| `OnRendered(fn)` | `PostRef<I?>` | 이 인스턴스의 children(과 그 서브트리 전체)·프로퍼티·이벤트가 **전부 세팅된 뒤** |
| `OnDestroyed(fn)` | `EffectHandle` | 묶인 인스턴스가 죽을 때 정확히 1회(설치 시점에는 안 돈다) |

`OnCreated`/`OnRendered`의 콜백은 `(inst, ref)` 두 인자를 받고, `inst`는 항상 non-nil입니다(nil 호출은 내부 가드가 걸러냅니다).

> **⚠️ `OnRendered`는 부모에 붙었음을 보장하지 않습니다.**
> `PostRef`가 보장하는 것은 **자기 아래**(서브트리)의 완성이지 자기 위(조상 체인)가 아닙니다. 리터럴 중첩으로 만들어졌다면 아직 부모가 없을 수 있고, `Claim`이나 미리 세팅된 `.Parent`로 왔다면 이미 붙어 있을 수 있습니다 — **어느 쪽도 보장하지 않습니다.** React `componentDidMount`가 DOM 삽입 *뒤*인 것과 다르므로, "화면에 올라간 뒤"라고 기대하지 마십시오. 화면 좌표·`AbsoluteSize` 같은 조상 의존 값을 여기서 읽으면 안 됩니다.

**요소 타입은 명시적 타입 인자(`<<Frame>>`)로 주십시오.** `q.OnCreated(function(inst: Frame) … end)`처럼 콜백 파라미터에만 적는 형태는 지금 타입 체커가 제네릭 자리를 풀지 못해 통과하지 못합니다(구·신 솔버 모두 실측).

```luau
local function AnimatedBox(): Frame
    return D.Frame {
        Size = UDim2.fromOffset(100, 100),

        q.OnCreated<<Frame>>(function(inst)
            print("생성됨:", inst.ClassName)
        end),

        q.OnRendered<<Frame>>(function(inst)
            print("자기 서브트리 완성:", inst.Size)
        end),

        q.OnDestroyed(function()
            print("파괴 및 정리됨")
        end),
    }
end
```

---

## 6. `Fallback` / `Traceback` — 에러 격리 경계

컴포넌트 함수 하나를 감싸서, 그 안에서 던져도 호출자까지 번지지 않고 대체 결과를 돌려주게 합니다. `pcall` / `xpcall`+`debug.traceback` 위의 순수 함수입니다.

### 6.1 시그니처

```
Fallback:  <Ok, Err, A...>(base: (A...) -> Ok, onError: (err: any) -> Err) -> (A...) -> Ok | Err
Traceback: <Ok, Err, A...>(base: (A...) -> Ok, onError: (err: any, trace: string) -> Err) -> (A...) -> Ok | Err
```

- 돌려주는 것은 **원본과 같은 인자를 받는 함수**입니다. 결과 타입은 `Ok | Err` — 성공 결과와 대체 결과의 유니언이라, 둘을 같은 타입으로 맞춰두면 호출부가 깔끔해집니다.
- **`err`는 `any`입니다.** Luau `error()`는 임의의 값을 던질 수 있고 이 층은 그걸 가공하지 않습니다 — 문자열이라고 가정하지 마십시오.
- `Traceback`의 `trace`는 항상 문자열이고, 던진 자리에서 떠집니다.

> **⚠️ 알려진 구멍: 던지기 전에 만들어진 부분 트리는 회수되지 않습니다.**
> 예외가 나기 전까지 이미 생성된 인스턴스들은 자기 GC 앵커로 스스로를 붙들고 있어서, 이 경계가 그것들을 정리해주지 않습니다. 대체 UI를 띄우더라도 그 잔재는 남습니다.

### 6.2 사용 예제

```luau
local function ProfileCard(props: { Name: string }): Instance
    return D.TextLabel { Text = props.Name }
end

local SafeProfileCard = q.Traceback(ProfileCard, function(err: any, trace: string): Instance
    warn("ProfileCard 렌더링 실패:", err, "\n", trace)
    return D.Frame {
        BackgroundColor3 = Color3.fromRGB(80, 20, 20),
        D.TextLabel {
            Text = "프로필을 불러올 수 없습니다.",
            TextColor3 = Color3.fromRGB(255, 100, 100),
        },
    }
end)

local card = SafeProfileCard({ Name = "q" })
```
