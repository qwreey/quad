---
title: "q.OnChange"
description: "프로퍼티 변경 신호를 숫자 키 자리 디스크립터로 붙이기 — 읽기 표면 PropTypesRead와 초기값 발화"
---
`GetPropertyChangedSignal` 바인딩을 **props의 숫자 키 자리에 놓는 값**으로 만든 것입니다.
[`Tag`](/reference/core/09-tag-attr/)나 [생명주기 훅](/reference/sugar/04-lifecycle-hooks/)과 같은 자리에 놓입니다.

이 페이지의 심볼: [`q.OnChange(name, fn)`](#qonchangename-fn) · [`q.Out(name, src)`](#qoutname-src)

:::note
`OnChange`는 `quad-roblox` 백엔드 전용입니다 — 신호를 찾는 일 자체가 엔진의 지식이라
백엔드가 소유합니다.
:::

```luau
-- 01장의 설정 모듈: quad_base에 quad_roblox를 설치하고 타입을 다시 내보낸다(시작하기 01 참고)
local q = require("@game/ReplicatedStorage/Client/UI/Quad")
local DeclarationModule = require(<quad-roblox 모듈 경로의 Declaration 하위 모듈>) -- 클래스별 OnChange 유니언 타입
local D = q.Declaration
```

---

## `q.OnChange(name, fn)`

**시그니처**

```luau
-- 생성 타입(quad-roblox/src/Declaration). `PropTypesRead`는 D 스코프 전체의 "읽기 가능한
-- 프로퍼티 이름 → 타입" 맵이고, 클래스 간 타입이 충돌하는 이름은 any다.
export type OnChangeFn = <K>(
	name: K & keyof<PropTypesRead>,
	fn: (index<PropTypesRead, K>) -> ()
) -> OnChangeDescriptor<K>

export type OnChangeDescriptor<K> = { Name: K, Callback: (index<PropTypesRead, K>) -> () }
```

**인자**

| 이름 | 타입 | 설명 |
|---|---|---|
| `name` | 프로퍼티 이름 문자열 | `PropTypesRead`의 키여야 한다 — 오타는 타입 에러 |
| `fn` | `(newValue) -> ()` | 그 프로퍼티가 바뀔 때 불린다. 파라미터 타입은 이름에서 추론된다 |

**`"Parent"`의 콜백 인자는 `Instance?`입니다.** 인스턴스가 트리에서 빠지는 순간 엔진이 `nil`을 주고, 그 순간을 잡는 것이 `Parent`를 지켜보는 주된 이유라서 타입이 그렇게 생성됩니다 — `function(p: Instance)`로 주석하면 타입 에러이고, 본문에서 `nil`을 먼저 걸러야 합니다. 같은 이유로 `AncestryChanged` 이벤트의 둘째 인자 `parent`도 `Instance?`입니다([`02-d`](/reference/roblox/02-d/) 이벤트 절).

**반환** — frozen 디스크립터 `{ Name, Callback }`. **캐시가 없어** 호출마다 새 값입니다.

**예제**

```luau
local size = q.Source(UDim2.fromScale(1, 0))

local box = D.Frame({
	Size = size,
	q.OnChange("AbsoluteSize", function(v: Vector2) -- 읽기 전용 프로퍼티도 된다
		print(v.X, v.Y)
	end),
	q.OnChange("Visible", function(v)               -- 주석을 생략해도 boolean으로 추론된다
		local _: boolean = v
	end),
})
```

**동작**

- 콜백은 **새 값**을 받습니다 — 핸들러가 `inst:GetPropertyChangedSignal(name)`에 연결하고, 신호가
  올 때 그 시점의 `inst[name]`을 읽어 넘깁니다. Deferred 신호 모드에서는 쓰기 한 번당 전달 한 번이고
  값은 전달 시점에 읽힙니다.
- **초기값도 콜백에 닿습니다 — 단, 쓰는 값이 엔진 기본값과 다를 때만.** props의 **숫자 키가 문자 키보다 먼저** 처리되므로, 같은 props에
  적은 프로퍼티 쓰기가 이미 연결된 바인딩에 도착합니다. 값이 기본값과 같으면(`Frame { Visible = true }`) 엔진이 동일값 대입에 시그널을 쏘지 않아 발화가 없습니다(엔진 0회 — 테스트용 mock 백엔드는 값 비교 없이 쏘므로 1회).

  ```luau
  local seen = {}
  D.TextLabel({
  	Text = "a", -- 문자 키: 아래 바인딩이 연결된 뒤에 쓰인다
  	q.OnChange("Text", function(v)
  		table.insert(seen, v) -- seen[1] == "a"
  	end),
  })
  ```
- **같은 이름을 두 번 적으면 둘 다 연결됩니다.** 문자 키 형태였다면 조용히 마지막 것만 남았을 자리라,
  일부러 숫자 키 자리 형태로 만든 것입니다.
- 숫자 키 자리를 차지하지만 **길이는 0**입니다 — 물리 자식이 아니라서 형제 자식의 오프셋에 기여하지
  않습니다.
- [`State`](/reference/core/03-state/)에 담아 반응형으로 바꿔 끼울 수 있습니다. `State<T>`는 불변이라
  **클래스별 유니언을 타입 인자로 명시**해서 만듭니다.

  ```luau
  local desc = q.Source<<DeclarationModule.FrameOnChange>>(q.OnChange("Visible", function(v: boolean) end))
  local box = D.Frame({ desc })
  ```

  그 자리에 [`q.None`](/reference/core/10-lifetime-sentinels/#qnone)을 발행하면 연결이 끊기고, 새
  디스크립터를 발행하면 하나만 다시 연결됩니다.
  같은 값 dedup은 없습니다(`Connect`가 멱등이 아니라서, 재발행마다 Disconnect+Connect 한 번).

**읽기 표면 — `PropTypesRead`**

`OnChange`가 쓰는 이름 집합은 **읽기 표면**입니다. 그래서 `D`의 props 문자 키로는 쓸 수 없는
읽기 전용 프로퍼티도 여기서는 유효합니다.

```luau
q.OnChange("AbsoluteSize", function(v: Vector2) end)     -- OK
q.OnChange("AbsolutePosition", function(v: Vector2) end) -- OK
q.OnChange("TextBounds", function(v: Vector2) end)       -- OK
```

이름이 어느 클래스에도 없으면 **타입 검사에서** 걸립니다. 타입을 우회해 넘긴 이름은 런타임에
엔진이 자기 에러를 냅니다 — quad는 프로퍼티 존재 여부를 다시 검사하지 않습니다.

**에러**

| 상황 | 문구 |
|---|---|
| 이름이 문자열이 아니거나 `""` | `Quad0221 OnChange: property name must be a non-empty string` |
| 콜백이 함수가 아님 | `Quad0222 OnChange: callback for "{name}" must be a function (got {typeof(fn)})` |

---

## `q.Out(name, src)`

**시그니처**

```luau
export type OutFn = <K>(
	name: K & keyof<PropTypesRead>,
	src: Source<index<PropTypesRead, K>> -- 쓸 수 있는 값(Source)만 — :Compute 결과는 여기서 거부된다
) -> OnChangeDescriptor<K>
```

엔진이 바꾼 프로퍼티 값을 **`Source`에 되쓰는** 슈거입니다. `OnChange` 위에 얹힌 팩토리라 돌려주는 값도 같은
디스크립터이고, 같은 숫자 키 자리에 놓습니다. 내려가는 방향은 평범한 문자 키 그대로라, 두 방향을 나란히 적습니다.

```luau
local text = q.Source("")

local box = D.TextBox({
	Text = text,          -- in: Source → 프로퍼티
	q.Out("Text", text),  -- out: 프로퍼티 → Source
})
-- 사용자가 타이핑하면 text:Get()이 따라오고, text:Set("…")하면 입력창이 따라간다
```

**인자**

| 이름 | 타입 | 설명 |
|---|---|---|
| `name` | 프로퍼티 이름 문자열 | `OnChange`와 같은 읽기 표면 `PropTypesRead`의 키 |
| `src` | `Source` | 되쓸 곳. **`:Compute` 결과 같은 파생 `State`는 안 됩니다** — `Set`이 없어 타입 검사에서 걸리고, 우회하면 런타임에 거부합니다 |

**동작**

- 신호가 올 때 새 값이 `src:Get()`과 **같으면 `:Set`하지 않습니다.** 왕복을 끊기 위해서가 아닙니다 — 엔진은 같은 값을 다시 대입해도
  변경 신호를 내지 않아 `Source → 프로퍼티 → 신호 → Source` 고리는 저절로 멈춥니다. 건너뛰는 이유는 **메아리**입니다: 숫자 키가 문자 키보다
  먼저 처리되므로 `Text = text`의 첫 쓰기가 이미 연결된 이 콜백에 닿는데, `Source:Set`은 같은 값에도 늘 전파하므로([`source:Set(v)`](/reference/core/02-source/#sourcesetv)) 건너뛰지 않으면
  `text`의 모든 구독자가 바인딩마다 한 번 더 헛돕니다.
- 그 밖은 `OnChange`와 같습니다 — 길이 0, 같은 이름 여럿 가능, `State`에 담아 바꿔 끼우기.
- 포커스나 커서는 건드리지 않습니다. 타이핑 중에 바깥에서 `text:Set`하면 입력창이 그 값으로 덮입니다 — 그런 정책이 필요하면
  `FocusLost` 이벤트로 확정하는 쪽을 직접 짜세요.

**에러**

| 상황 | 문구 |
|---|---|
| 이름이 문자열이 아니거나 `""` | `Quad0223 Out: property name must be a non-empty string` |
| 둘째 인자가 `Source`가 아님 | `Quad0224 Out: second argument for "{name}" must be a Source to write back into (got {…})` — `:Compute` 결과면 `got a read-only State (a :Compute result?)` |

---

**관련**

- [D — 숫자 키](/reference/roblox/02-d/#숫자-키--자식과-디스크립터)
- [02. 폼 검증 패턴](/how-to/02-form-validation-pattern/)
- [04. RemoteEvent와 엔진 입력을 상태로 브릿징하기](/how-to/04-network-and-input-bridge/)
