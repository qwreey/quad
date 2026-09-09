# [Quadnomicon Vol. 6] 단일 인자 생존 게이트: 물리 수명과 반응형 전파의 분리

> **작성 목적**: 프레임워크 아키텍트 및 고급 엔지니어를 위한 기술 해설서
> **관련 소스**: `quad-roblox/src/LifetimeHandle.luau`, `quad-base/src/LifetimeHandle.luau`, `quad-base/src/Observer.luau`

> [!CAUTION]
> 이 권은 반응형 실행 게이트의 저수준 수명 동작을 다룹니다. 애플리케이션을 만들려고 quad를 배우는 중이라면 [Getting Started](/quad/ko/getting-started/01-core-mental-model/)부터 보십시오.

---

## 1. 문제: 수명이 둘이다

Roblox에서 UI Instance는 서로 독립적인 두 수명을 갖습니다.

1. **Lua 메모리 수명** — 루트로부터의 도달 가능성으로 GC가 정합니다.
2. **엔진 수명** — 데이터 모델이 `inst:Destroy()`로 정합니다.

엔진에서 파괴된 뒤에도 그 userdata 참조는 이벤트 클로저나 반응형 노드가 계속 들고 있을 수 있습니다. 그러면 발화가 죽은 인스턴스를 계속 건드리게 됩니다. **해야 할 일은 하나뿐입니다 — 죽은 대상을 건드리는 시도가 아예 일어나지 않게 막는 것.**

`inst.Parent == nil`을 검사하는 방식은 quad에서 특히 안 맞습니다. quad의 언마운트는 비파괴라서(Vol. 5) **부모가 없는 살아 있는 인스턴스가 일상적**이기 때문입니다 — 부모 유무는 "떨어져 있다"를 말할 뿐 "죽었다"를 말하지 않습니다. 게다가 이 검사를 하려면 게이트가 매번 `inst`를 손에 쥐고 있어야 합니다.

---

## 2. 두 인자 설계와 그것이 깨진 이유

### 2.1 옛 모양

```luau
canExecute(inst: any, value: any): boolean
```

그리고 `bindLifetime`이 바인딩할 때 `value.Subscribed = true`를 세워, `canExecute`가 그 필드와 `inst`의 gcconn을 함께 보는 구조였습니다.

### 2.2 무엇이 오염이었나

**`.Subscribed`는 전역 `:Subscribe()` 경로 전용 필드입니다** — `inst`에 붙은 플래그가 아니라 `Observer`/`Effect` 핸들 자신의 필드이고, `bindLifetime`과는 이해관계가 없습니다. 옛 설계는 여기에 "leaf 바인딩도 살아 있음"이라는 두 번째 뜻을 겹쳐 얹었고, 그 순간 **leaf 경로의 생존을 `value`에게 물을 방법이 사라졌습니다.** 남은 유일한 경로가 "`inst`의 gcconn을 조회한다"였고, 두 인자 시그니처는 그 오염의 **증상**이었지 원인이 아니었습니다.

정확한 분해는 이렇습니다:

| 묻는 것 | 근거 | `value`만으로 가능? |
|---|---|---|
| 전역으로 등록됐나 | `value.Subscribed` 필드 | O |
| 묶인 `inst`가 살아 있나 | `bindLifetime`이 `value` 쪽 릴레이션에 **복사해둔 gcconn** | O |

두 조건이 독립적이라는 관찰 자체는 맞았지만, 거기서 "`inst`를 인자로 받아야 한다"는 결론은 나오지 않습니다 — 바인딩 시점에 gcconn 참조를 `value` 쪽으로 복사해두면 둘 다 `value` 하나로 물을 수 있습니다.

### 2.3 왜 여섯 세션이나 안 드러났나

**`canExecute`의 실제 호출부가 어느 문서에도 코드로 등장한 적이 없었기 때문입니다** — 전부 "발화 시 `canExecute`로 게이팅됨"이라는 서술만 하고 넘어갔습니다. 실제 호출부는 **State의 전파 루프**인데, 거기엔 `inst`가 없고 있어서도 안 됩니다(State는 자기가 어느 Instance에 걸렸는지 모르는 게 정상이고, 여러 곳에 걸릴 수도 있습니다). 즉 두 인자 시그니처는 **진짜 호출부에서 호출 자체가 불가능**했고, 아무도 그 코드를 써보지 않아 드러나지 않았을 뿐입니다.

> **교훈**: 계약(시그니처)을 정할 때 호출부를 최소 하나는 의사코드로 같이 적어둘 것. "어디선가 게이팅됨"은 검증할 수 없는 문장입니다.

### 2.4 `canBound`는 폐기됐다가 다시 갈라졌다

정정 당시엔 `canExecute` 하나로 합쳤지만, 나중에 호출 문맥이 둘이라는 이유로 이름이 다시 갈렸습니다.

- **bound 문맥** — "이 값이 이미 어딘가에 유효하게 묶여 있는가". `bindLifetime`의 이중 바인딩 가드, `Observer:Subscribe()`의 이중 등록 가드, `Ref`가 두 자리에 동시에 놓이는 걸 막는 가드. `Ref`처럼 발화라는 개념이 아예 없는 값도 이 질문은 받습니다.
- **execute 문맥** — "지금 이 구독자가 발화해도 되는가". 실제로 콜백을 실행하는 값에만 의미가 있습니다.

두 판정값은 같은 게 아니라 **서로의 부정**입니다: `canBound(v) == not canExecute(v)`. 공유하는 건 값이 아니라 판정 **로직** 하나이고, 호출부가 `not`을 붙이는지로 의도가 드러납니다.

---

## 3. 단일 인자 아키텍처

### 3.1 셋업 ①: `nativeClaim` — GC 앵커는 여기서 생긴다

Instance를 만드는 시점(또는 기존 트리를 `Claim`하는 시점)에 정확히 한 번 돕니다:

```luau
local gchold: { [any]: any } = {}
local gcconn = inst:GetPropertyChangedSignal("ClassName"):Connect(function()
    nop(gchold, inst) -- never fires; the capture is the point
end)
gchold[1] = gcconn
InstData:SetWeak(inst, "gchold", gchold)
InstData:SetWeak(inst, "gcconn", gcconn)
```

`ClassName`은 절대 안 바뀌는 프로퍼티라 이 신호는 발화하지 않습니다. 목적은 콜백이 `gchold`와 `inst`를 업밸류로 잡는 것이고, 부수적으로 **`gcconn.Connected`가 Destroy 시점에 즉시 뒤집힙니다** — 그게 곧 생존 판정의 근거입니다.

### 3.2 셋업 ②: `bindLifetime(inst, value)`

```luau
gchold[value] = true                                   -- 강참조: value는 최소한 inst만큼 산다
BindData:SetWeak(value, "gchold", gchold)              -- 둘 다 weak — 섬은 위 클로저가 살린다
BindData:SetWeak(value, "gcconn", InstData:GetWeak(inst, "gcconn"))

if isObserver(value) then value:_catchUp() end
if isEffect(value) then value:_bindDestroying(inst) end
```

**`bindLifetime`은 `Destroying`을 듣지 않습니다.** GC 앵커는 위 `ClassName` 커넥션이고, `Destroying` 훅업은 오직 `Effect`에만 붙습니다(`_bindDestroying`). 그리고 이 함수는 이미 살아 있는 바인딩을 가진 값을 거부합니다 — 그 판정도 아래 술어 하나로 합니다.

### 3.3 판정: `isBoundAlive`와 두 진입점

```luau
local function isBoundAlive(value: any): boolean
    if value == nil then
        return false
    end
    local gcconn = BindData:GetWeak(value, "gcconn")
    if gcconn ~= nil and gcconn.Connected then
        return true
    end
    if isObserver(value) or isEffect(value) then
        return value.Subscribed == true
    end
    return false
end

local function canBound(value: any): boolean
    return not isBoundAlive(value)
end

local function canExecute(value: any): boolean
    return isBoundAlive(value)
end
```

읽을 때 반드시 짚어야 할 세 가지:

1. **묶이지 않은 값은 `canExecute`가 거짓입니다.** 자유롭게 발화하는 게 아니라 그 반대입니다. `nil`도 거짓입니다.
2. **`canBound`/`canExecute`는 던지지 않습니다** — 둘 다 순수 boolean입니다. 에러는 `bindLifetime`과 `Observer:Subscribe()`가 `if not canBound(v) then error(...)` 형태로 냅니다.
3. **엔진 리플렉션이 0은 아닙니다.** `gcconn.Connected`를 읽습니다. 정확한 주장은 "`inst.Parent`를 묻지 않고, `inst` 인자 자체가 필요 없다"입니다.

### 3.4 왜 "묶이지 않으면 거짓"이 버그가 아닌가

이 게이트를 타는 값은 **`Observer`와 `Effect`뿐입니다.** 파생 State 노드(`:With`/`:Compute`/`:Gate`가 만든 것)는 이 게이트를 타지 않습니다 — 만약 탄다면 자식 노드는 `bindLifetime`된 적도 `:Subscribe()`된 적도 없으니 전부 걸러지고, 루트의 `:Set`이 파생 State에 한 번도 닿지 못할 것입니다. 파생 노드의 생존은 `canExecute`가 아니라 State 그래프의 `_hold` 불변식이 책임집니다.

실제 호출부는 `Observer:_receive`입니다:

```luau
function Impl._receive(self: any, from: any)
    if module.canExecute(self) then -- read at fire time
        ...
        self.fn(self._state, self, from)
        ...
    else
        self._rerunRequired = true -- 바인딩 전 변경은 붙들었다가 묶일 때 한 번 따라잡는다
    end
end
```

거짓일 때 그냥 버리는 게 아니라 `_rerunRequired`를 세워, 나중에 묶이는 순간 한 번 따라잡습니다. State는 구독자를 **weak 키로** 담으므로, 어디에도 안 묶인 `Observer`는 살려두는 주체가 없어 자연히 GC되고 구독 목록에서 빠집니다.

### 3.5 부수 효과: 죽은 뒤의 재사용은 허용

`inst`가 Destroy됐거나 `unbindLifetime`된 `value`는 `canBound`가 다시 참이 되어 다른 `inst`에 걸 수 있습니다. 이 게이트가 막는 건 **살아 있는 바인딩의 중복**이지 재사용이 아닙니다.

---

## 4. 불변식 요약

| 게이트 | 시그니처 | 언제 | 무엇을 막나 |
|---|---|---|---|
| `canBound` | `(value) -> boolean` | 바인드/구독 시점 | 살아 있는 바인딩을 가진 값을 다시 묶는 것 |
| `canExecute` | `(value) -> boolean` | emit 전파 시점 | 죽은 바인딩을 가진 `Observer`/`Effect`가 발화하는 것 |
| `bindLifetime` | `(inst, value) -> ()` | 마운트 시점 | — (수명을 잇는 쪽; 거부는 `canBound`로 판정) |
| `unbindLifetime` | `(value) -> ()` | 조기 해제 | — (`gchold[value]`만 지움, cleanup은 부르지 않음) |

`canBound(v) == not canExecute(v)`이고, 둘 다 백엔드가 소유한 비공개 술어 `isBoundAlive` 하나를 감쌉니다. quad-base 쪽에는 이 넷의 **인터페이스만** 있고 기본 구현은 소리 나는 스텁입니다 — 엔진을 모르는 코어가 임의의 "옳은 기본값"을 추측할 수 없기 때문입니다.
