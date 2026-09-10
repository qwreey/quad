---
title: "Claim과 D.Mapper"
description: "이미 있는 Instance 트리를 quad가 소유하고 드라이브하기 — 디스크립터 해석, 계약과 에러"
---
Studio에서 만든 GUI, `template:Clone()` 사본처럼 **이미 존재하는 트리**를 quad가 소유하고,
`D.<Class>{…}`로 만든 것과 똑같이 드라이브하게 만드는 경로입니다. `D.Mapper` 디스크립터가
"이 자리는 이름이 `Title`인 자식"이라고 지목하고, `Claim`이 그걸 실제 Instance로 해석합니다.

이 페이지의 심볼: [`q.Claim(inst, desc)`](#qclaiminst-desc) ·
[`D.Mapper.<Class>(key)(props)`](#dmapperclasskeyprops) · [`D.Mapper.Root`](#dmapperroot) ·
[`q.MapperRoot`](#qmapperroot) · [`q.newMapperClass(className)`](#qnewmapperclassclassname)

:::note
`Claim` 자체는 `quad-base`에 있지만, 자식을 찾는 op(`nativeFindChild`)와 소유 op(`nativeClaim`)는
백엔드가 주입합니다. `D.Mapper`는 `quad-roblox` 전용입니다.
:::

```luau
-- 설치 경로는 프로젝트 구성에 따라 다르다(00-installation 참고)
local Quad = require(<quad-base 모듈 경로>)
local QuadRoblox = require(<quad-roblox 모듈 경로>).QuadRoblox
local q = Quad:UseProvider(QuadRoblox)
local D = q.D
local M = D.Mapper
```

---

## `q.Claim(inst, desc)`

**시그니처**

```luau
Claim: <T>(inst: T, desc: MapperDescriptor) -> T
```

**인자**

| 이름 | 타입 | 설명 |
|---|---|---|
| `inst` | Instance | 소유할 트리의 루트. 설치된 백엔드의 Instance여야 한다 |
| `desc` | `MapperDescriptor` | `D.Mapper.<Class>(M.Root)(props)`로 만든 루트 디스크립터 |

**반환** — 넘긴 `inst` 그대로(타입도 그대로). 체이닝하기 좋습니다.

**예제**

```luau
-- template: Studio에서 만들어 둔(또는 Clone한) 트리
local function bindCard(template: Frame): Frame
	local title = q.Source("안녕")

	local root = q.Claim(template, M.Frame(M.Root)({
		BackgroundTransparency = 0.25,               -- 루트 자신의 props
		M.TextLabel("Title")({ Text = title }),      -- 이름이 "Title"인 직계 자식
		M.Frame("List")({                            -- 중첩도 된다
			M.TextLabel("Inner")({ Text = "깊은 자식" }),
		}),
	}))

	title:Set("반가워") -- claim한 트리도 반응형: 그대로 프로퍼티가 따라간다
	return root
end
```

**동작**

1. 인자를 검사합니다(아래 에러 표).
2. 디스크립터를 DFS로 내려가며, 자식 자리의 디스크립터를 **키로 자식을 찾아** 실제 Instance로
   해석합니다.
3. 해석된 Instance마다 **먼저 소유**하고(그 뒤에야 드라이브 — `D.New`의 순서와 같습니다),
   **안쪽부터 바깥으로** 드라이브합니다.
4. 해석된 자식이 있던 배열 자리는 **그 Instance로 치환**됩니다 — 그래서 그 뒤로는 평범한 정적 자식과
   구분이 없습니다.

props 테이블은 **제자리에서** 바뀝니다(사본을 만들지 않습니다). `D.<Class>{…}`가 쓰는 것과 같은
드라이브를 타므로 `Modifier` 소진, 배열/해시 순서, `q.None` 메꾸기가 전부 동일하게 동작합니다.

```luau
-- 새로 만든 자식과 매핑 자식을 한 배열에 섞어도 된다
local function bindMixed(template: Frame)
	return q.Claim(template, M.Frame(M.Root)({
		M.TextLabel("Title")({ Text = "매핑" }),
		D.TextLabel({ Text = "새로 만든 것" }),
		D.Modifier.Frame():BackgroundTransparency(0.5),
		q.None,
	}))
end
```

**에러**

| 상황 | 문구 |
|---|---|
| 첫 인자가 Instance가 아님 | `Claim: first argument must be an Instance of the installed backend (got {typeof(inst)})` |
| 둘째 인자가 디스크립터가 아님 | `Claim: second argument must be a D.Mapper descriptor` |
| 디스크립터를 두 번 씀 | `Claim: mapper descriptor was already used (descriptors are one-shot)` |
| 디스크립터의 props가 테이블이 아님 | `Claim: mapper props must be a table (got {typeof(desc._props)})` |
| 이미 quad가 소유한 Instance | `nativeClaim: Instance is already claimed by quad` |

`D.<Class>{…}`의 배열 부분에 디스크립터를 넣으면 매치되는 핸들러가 없어 일반 no-match 에러가
납니다 — 디스크립터는 `Claim` 전용입니다.

**계약 셋**

1. **한 번만 claim합니다.** 한 Instance는 생애 동안 정확히 한 번 소유됩니다. `D.New`로 만든 것은
   이미 소유된 상태라 다시 걸면 위의 "already claimed"입니다. 여러 quad 인스턴스가 한 트리를 나눠
   claim하는 것은 UB입니다. 이미 파괴된 Instance를 claim하는 것도 UB입니다 — 막지 않습니다.
2. **그려지는 직계 자식은 전부 매핑합니다.** quad는 claim한 Instance의 자식 자리를
   [부기](/reference/core/07-slot/)합니다. 그리는 직계 자식 중 매핑되지 않은 것이 남으면 삽입 위치와
   길이/오프셋 계산이 어긋납니다.
   - **디스크립터 배열의 순서가 정본**입니다. 기존 트리의 순서가 다르면 맞추는 건 사용자 책임입니다
     — quad는 재정렬하지 않습니다.
   - **[숏핸드 키](/reference/roblox/02-d/#숏핸드-키-넷)가 만든 `UI*`는 부기 대상이 아닙니다** — 그려지지 않고
     매달릴 뿐이라 quad가 자리로 세지 않습니다. 반대로 템플릿에 이미 있는 `UI*`를
     `M.UICorner("UICorner")({ … })`처럼 **디스크립터로 매핑하면 평범한 배열 자리**이고, 그건 부기
     대상입니다. 둘을 섞으면(템플릿에 `UICorner`가 있는데 숏핸드 키도 쓰면) `UICorner`가 둘 생기니
     한쪽만 쓰세요.
   - 이름 부재·중복은 UB입니다.
3. **`PlayerGui`/`CoreGui`는 대상이 아닙니다.** 엔진과 여러 스크립트가 자식을 넣고 빼는 공유
   컨테이너라 "소유"가 성립하지 않습니다. 런타임 검사가 아니라 **설계상 대상 밖**이라는 뜻이니
   걸지 마세요. 대신 quad 트리의 **루트는 밖에서 `.Parent`를 설정해도 됩니다**(루트의 부모는 어떤
   부기에도 속하지 않습니다).

   ```luau
   local function mount(existingScreenGui: ScreenGui, playerGui: Instance)
   	local screen = q.Claim(existingScreenGui, M.ScreenGui(M.Root)({}))
   	screen.Parent = playerGui -- 허용: 루트의 Parent는 부기 밖
   end
   ```

`props`에 `Parent`를 넣는 것은 `Claim`에서도 금지입니다 — [`D`와 같은 이유](/reference/roblox/02-d/#해시-부분--프로퍼티와-이벤트).

---

## `D.Mapper.<Class>(key)(props)`

**시그니처**

```luau
-- 클래스마다 하나씩 생성된 별칭. Frame이라면:
D.Mapper.Frame: (key: string | MapperRoot) -> (FrameParam<FrameMapperElem>) -> MapperDescriptor
```

**인자**

| 이름 | 타입 | 설명 |
|---|---|---|
| `key` | `string` 또는 `MapperRoot` | 이 자리에 놓일 자식의 이름. 루트 자리면 `M.Root` 센티널 |
| `props` | 클래스의 props 테이블 | `D.<Class>`와 **같은 모양** — 해시 부분·배열 부분 그대로 |

**반환** — `MapperDescriptor`. **1회용**입니다 — 한 번 `Claim`에 쓰이면 다시 못 씁니다.

**동작**

`D.<Class>`와 커링 모양이 같지만 한 단계 더 있습니다(`(key)` → `(props)`). props의 배열 부분에는
`D.<Class>`가 받는 것 전부에 더해 **다른 디스크립터**가 들어갑니다 — 그게 중첩 매핑입니다.

디스크립터를 재사용하려면 값을 저장하지 말고 **호출을 팩토리로 감싸세요**.

```luau
local function CardDescriptor(text: string)
	return M.Frame(M.Root)({ M.TextLabel("Title")({ Text = text }) })
end

local function bindAll(cards: { Frame })
	for _, card in cards do
		q.Claim(card, CardDescriptor("항목")) -- 매번 새 디스크립터
	end
end
```

생성되는 Mapper 별칭의 이름 집합은 `D`의 클래스 별칭과 **정확히 같습니다**(31개).

---

## `D.Mapper.Root`

`Claim`의 인자로 넘기는 **루트 디스크립터의 키** 자리에 쓰는 센티널입니다. "이 자리는 이름으로 찾지
말고 `Claim`이 받은 Instance 자신"이라는 뜻입니다.

```luau
q.Claim(template, M.Frame(M.Root)({ … }))
```

값은 `q.MapperRoot`와 같은 객체이고 `tostring`은 `MapperRoot`입니다.

---

## `q.MapperRoot`

`D.Mapper.Root`가 다시 내놓는 원본 센티널입니다([`quad-base` 소유](/reference/core/11-lifetime-sentinels/)).
`D`를 거치지 않고 디스크립터를 만들 때 쓰면 됩니다.

```luau
assert(D.Mapper.Root == q.MapperRoot)
```

---

## `q.newMapperClass(className)`

**시그니처**

```luau
newMapperClass: (className: string) -> (key: any) -> (props: any) -> MapperDescriptor
MapperRoot: MapperRoot -- export type MapperRoot = { read __quadMapperRoot: true }
```

`D.Mapper.<Class>` 별칭들이 얹혀 있는 **타입 없는 원본 팩토리**입니다
([`quad-base` 소유](/reference/core/11-lifetime-sentinels/) — `D.<Class>`와 `D.New`의 관계와 같습니다). `D.Mapper`에 별칭이 없는 클래스를 매핑해야 할 때만
쓰세요. props는 `any`라 클래스별 검사가 없습니다.

```luau
local MapPart = q.newMapperClass("Part")

local function bindModel(model: Model)
	return q.Claim(model, q.newMapperClass("Model")(q.MapperRoot)({
		MapPart("Body")({ Anchored = true }),
	}))
end
```

---

**관련**

- [07. Studio에서 만든 UI에 반응성 붙이기](/how-to/07-studio-ui-binding-and-claim/) — Clone 패턴과 실전 레시피
- [D — Instance 생성](/reference/roblox/02-d/) — props 테이블의 모양
- [Quadnomicon Vol. 7 — Instance 신원과 GC 철학](/quadnomicon/07-instance-identity-and-gc-philosophy/)
