---
title: "09. 부록 — quad 에러 읽는 법과 런타임 디버깅"
description: "quad 에러 메시지를 읽고 표면 blame으로 문제의 소스 줄을 추적하는 법을 설명합니다"
---
> **대상 독자**: quad 런타임 에러를 빠르게 추적하려는 개발자
> **다루는 개념**: 표면(surface) 블레임, 자주 밟는 함정 여섯과 해결책

```luau
-- 설치 경로는 프로젝트 구성에 따라 다르다(00-installation 참고)
local Quad = require(<quad-base 모듈 경로>)
local QuadRoblox = require(<quad-roblox 모듈 경로>).QuadRoblox
local QuadTypes = require(<quad-types 모듈 경로>)
local q = Quad:UseProvider(QuadRoblox) -- quad-roblox 백엔드 설치: D/Tween/Animate/OnChange가 생긴다
local D = q.D
```

---

## 1. quad의 에러는 "사용자 줄"을 가리키려 한다

quad는 공개 표면 함수에 태그를 달아두고, 에러를 낼 때 **스택에서 태그된
프레임을 걷어내 그 바깥의 사용자 줄**을 blame합니다.

```
ServerScriptService.Components.UserProfile:42: Event: handler for "Activated" must be a function (got table)
```

### 기대할 수 있는 것

- **메시지 형식이 `주어: 이유 (got X)` 하나로 고정돼 있고**, 메시지 리터럴은
  **raise하는 줄에 통째로** 남아 있습니다(포맷 헬퍼를 쓰지 않습니다) — 눈에
  띄는 조각을 소스에서 `grep`하면 던진 자리가 바로 나옵니다. 보간은 값
  부분에만 들어갑니다.
- 대부분의 경우 `파일:줄` 접두는 **사용자의 선언 줄**을 가리킵니다.

### 기대하면 안 되는 것 — 알려진 한계 둘

1. **C 프레임이 태그된 표면을 직접 부르면 `파일:줄` 접두가 사라집니다**
   (`pcall(q.Dispatch.drive, ...)` 같은 직전달). 메시지는 살아남습니다 —
   접두가 필요하면 `pcall(function() ... end)`으로 감싸세요.
2. **재진입 진입에서는 바깥 진입 줄이 blame됩니다.** observer 콜백 안에서
   다시 디스패치를 유발하면 최외곽 스캔이 바깥 진입 줄을 가리킵니다.

---

## 2. 자주 밟는 함정 여섯

### 함정 1: nil-hole — 숫자 키 자리에 구멍 내기

- **증상**: 숫자 키 자리에 넘긴 값이 무시되거나, 자식 위치 부기가 어긋남.
- **원인**: 숫자 키 자리의 `nil`은 테이블을 sparse하게 만듭니다. 디스패치는 숫자 키 자리를
  구멍 없는 시퀀스로 전제하고(순회에서 그 자리가 빠지고, 부기 쪽은 길이 `#`에
  기대는데 구멍 있는 테이블의 `#`는 명세되지 않음) 따라서 배열 구멍은
  **정의되지 않은 동작(UB)** 입니다. 실제 결과는 구멍의 위치에 따라 갈립니다 —
  1번 자리나 중간이 구멍이면 위치 부기가 어긋나 그 자리에서 에러가 나고
  (`Dispatch.recompute: sourceList[1] is nil — a nil hole in the numeric-key part of props ({ a, nil, b })? fill the optional slot with q.None; …` — 물음표까지가 사용자에게 하는 말이고 세미콜론 뒤는 핸들러 작성자용입니다),
  꼬리 구멍은 우연히 통과합니다.
- **해결책**: 선택적 값 뒤에는 **`or None`**을 붙입니다.

```luau
-- ❌ props.Modifier가 nil이면 배열에 구멍이 생긴다
D.Frame { props.Modifier, props.Ref, Size = UDim2.new() }

-- ✅
D.Frame { props.Modifier or q.None, props.Ref or q.None, Size = UDim2.new() }
```

---

### 함정 2: `Ref:Wait()`에서 영원히 멈춤

- **증상**: 스레드가 `myRef:Wait()`에서 재개되지 않음.
- **원인**: `Ref:Wait()`는 **항상 다음 `:Set` 호출**을 기다립니다 — `Ref<T?>`
  에서 `nil`도 정당한 값이라 "이미 채워졌는지"를 `Wait` 안에서 판정할 수 없기
  때문입니다. 이미 채워진 Ref에 걸면 새 `:Set`이 없는 한 깨어나지 않습니다.
- **해결책**: 채워졌는지를 먼저 직접 확인합니다.

```luau
-- ✅ 이미 있으면 즉시, 없으면 다음 채워짐을 대기
local inst = if myRef.Value then myRef.Value else myRef:Wait().Value
```

값이 있어야만 진행되는 자리에서는 `:Unwrap()`이 더 짧습니다. 비어 있으면
호출한 줄에서 던집니다:

```
Ref:Unwrap: the Ref is empty (Value is nil) — not filled yet, or never placed
```

또 `Wait()`는 양보 가능한 코루틴 안에서만 부를 수 있습니다 — 아니면
`Ref: Wait() must be called from a yieldable coroutine (pass a thread to register a waiter without yielding)`.

---

### 함정 3: `Ref`를 `Modifier` 안에 넣기, 또는 문자 키로 넘기기

- **증상**: `Modifier`에 넣으면
  `Modifier: field "Ref" cannot hold a handler-layer value (Ref/Observer/Effect/Slot/Modifier)`.
  문자 키로 주면 값에 따라
  `PreRef: must be an array item, not the value of a string key` 또는
  `Dispatch: no handler matched key Ref (value: table, brand: Ref) — check that the provider for this value (e.g. quad-roblox) is initialized`.
- **원인**: `Modifier`는 여러 인스턴스에 재사용되는 스타일 가방이라, 단일
  인스턴스에 바인딩되는 핸들러 층 값(`Ref`/`Observer`/`Effect`/`Slot`/
  `Modifier`)을 담을 수 없습니다. 그리고 이 값들은 props의 **숫자 키 자리**에
  놓는 것이 계약입니다 — `Ref = ...`처럼 문자 키로 주면 어떤 핸들러도 그
  키를 받지 않습니다.

```luau
-- ✅ 숫자 키 자리에 그대로
local function CustomInput(props: { InputRef: QuadTypes.Ref<TextBox?>? })
    return D.TextBox {
        props.InputRef or q.None,
        PlaceholderText = "...",
    }
end
```

---

### 함정 4: 이미 claim된 인스턴스에 다시 `Claim`

- **증상**: `nativeClaim: Instance is already claimed by quad`.
- **원인**: 한 인스턴스는 생애 동안 한 번만 claim됩니다. `D.New`가 만든
  인스턴스도 이미 claim된 상태이고, 부모를 `Claim`할 때 매핑된 자식도 같이
  claim되므로 그 자식에 다시 걸면 여기서 막힙니다. 자세한 계약은
  [07. Studio UI 바인딩과 Claim](/how-to/07-studio-ui-binding-and-claim/).
- 이미 파괴된 인스턴스를 다시 쓰면 사촌 격 에러가 납니다 —
  `bindLifetime: Instance is not claimed by quad — it was not created or claimed through quad, or it has already been destroyed (a destroyed Instance cannot be reused)`.

---

### 함정 5: `Source`에 `Modifier`를 담기

- **증상**: `Source: cannot hold a Modifier as a Source value`.
- **해결책**: 바뀌는 것은 스타일 **필드**이므로, 필드마다 `Source`를 두고
  `Modifier`가 그 `Source`를 참조하게 합니다(그 방향은 정상입니다).

```luau
local themeColor = q.Source(Color3.fromRGB(255, 0, 0))

-- 빌더 체인
local dynamicStyle = D.Modifier.Frame():BackgroundColor3(themeColor)

-- 초기 필드 테이블도 같은 값
local dynamicStyle2 = D.Modifier.Frame { BackgroundColor3 = themeColor }
```

---

### 함정 6: `State<Store>`의 필드를 그냥 꺼내려 하기

- **증상**: 스토어를 통째로 갈아끼우는 `currentStore:Set(newStore)`를 넣었는데,
  `currentStore.Hp` 같은 접근이 `nil`이거나 타입 에러.
- **원인**: **중첩 `State`는 지원됩니다** — `State<State<T>>`는 프로퍼티 자리에서
  재귀적으로 풀립니다. 문제는 `State`에 값의 필드를 꺼내는 dot-access가 없다는
  것입니다. `Store`를 담은 `State`의 필드를 반응형으로 읽으려면 명시적인 읽기
  콤비네이터가 필요합니다.
- **해결책 (a)**: 필드 읽기는 `q.Operator.Indexed`로. 결과 타입은 호출자가 직접
  지정합니다(키에서 추론하지 않습니다).

```luau
local theme = q.Source({ Primary = "red", Size = 10 })
local primary: QuadTypes.State<string> = theme:Apply(q.Operator.Indexed<<string>>("Primary"))
-- theme:Set({ Primary = "blue", Size = 12 }) → primary:Get() == "blue"
```

값이 테이블이 아니면 읽는 시점에
`Operator.Indexed: value is not a table (got number) — cannot read [Primary]`.

- **해결책 (b)**: 폼 리셋처럼 스토어를 새로 만들 이유가 없다면, 스토어를 바꾸지
  말고 필드를 리셋하세요.

```luau
local function resetForm(store)
    store.Username:Set("")
    store.Age:Set(0)
    store.AgreedToTerms:Set(false)
end
```

---

## 3. 디버깅 체크리스트

| 점검 항목 | 올바른 작성법 |
|---|---|
| **선택적 값 전달** | `props.Modifier or q.None` — 숫자 키 자리의 `nil`은 구멍이다 |
| **핸들러 층 값 자리** | `Ref`/`PreRef`/`PostRef`/`Observer`/`Effect`/`Slot`/`Modifier`는 숫자 키 자리 |
| **Ref 대기** | `if ref.Value then ref.Value else ref:Wait().Value`, 또는 `ref:Unwrap()` |
| **프로퍼티 감시** | `q.OnChange("PropertyName", function(v) ... end)` — 숫자 키 자리 |
| **어트리뷰트 삭제** | `q.Attr { MyKey = q.None }` — 그룹에서 이름을 빼는 것만으로는 지워지지 않는다 |
| **부모 붙이기** | `Parent`는 props가 아니다 — 만든 뒤 밖에서 `inst.Parent = ...` |
| **이벤트 콜백** | 엔진 인자만 온다(self 없음). self가 필요하면 `PreRef`로 인스턴스를 잡아둘 것 |
