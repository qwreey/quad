---
title: "18. 자리에 놓인 값은 누가 처리하나 — 핸들러 맛보기"
description: "props의 자리마다 어떤 핸들러가 값을 맡는지, State가 어떻게 한 겹 벗겨지는지, 자리를 갈아 끼울 때 이전 것이 어떻게 빠지는지를 밖에서 보이는 만큼 봅니다"
---
# [시작하기] 18. 자리에 놓인 값은 누가 처리하나 — 핸들러 맛보기

> **대상 독자**: [17. 값은 언제 흐르나](./17-laziness.md)까지 따라온 개발자
> **목표**: props의 자리 하나가 값을 어떻게 맡고 어떻게 놓는지 감 잡기 — 남이 써 둔 코드를 읽을 수 있을 만큼

앞에서 같은 모양을 세 번 만났습니다. [05장](./05-tag-attr.md)에서는 숫자 키 자리에 `Tag`를 내놓는
`State`를 놓아 이름표를 갈아 끼웠고, [07장](./07-observer-effect.md)에서는 같은 자리에 관측 핸들을
담은 `State`를 놓아 관측을 껐고, [10장](./10-slot.md)에서는 자식 인스턴스 하나를 담은 `State`를
놓아 화면을 갈아 끼웠습니다. 세 장이 각각 "이렇게도 된다"고 말했지만, 셋은 **같은 원리 하나**입니다.

이 장은 그 원리를 **밖에서 보이는 만큼만** 봅니다. 나오는 이름 둘(`q.Dispatch.listHandlers()`와
`q.Dispatch.getHandler(...)`)은 무언가를 만드는 도구가 아니라 지금 상태를 **들여다보는** 창구입니다.

---

## 1. 자리마다 누가 맡을지 고른다

`D.Frame { ... }`을 쓸 때 quad가 보는 단위는 테이블 전체가 아니라 **자리 하나하나**입니다 — 문자 키
하나가 한 자리, 숫자 키 하나가 한 자리. 자리마다 quad는 등록된 **핸들러** 목록을 위에서 아래로
훑으며 "이 값, 네가 맡을래?"를 묻고, **처음 손을 든 하나**에게 넘깁니다.

목록은 직접 찍어 볼 수 있습니다.

```luau
-- (이 장의 예제들은 앞 장들과 별개로 돌려 보는 짧은 조각입니다)
for _, handler in q.Dispatch.listHandlers() do
    print(handler.name)
end
```

**실행하면** `SlotHandler`, `StoreBind`, `Event`, `InstanceChild`, `Property` 같은 이름이 **우선순위
순으로** 쭉 찍힙니다. 한 자리가 실제로 훑는 것은 그중 그 키 타입에 해당하는 것들뿐이고, 우선순위가
같은 것들끼리의 순서는 정해져 있지 않습니다. 이름은 **진단용**이라 버전이나 백엔드에 따라 달라질 수 있습니다 — 외우지
말고 "이런 것들이 줄 서 있구나" 정도로 보면 됩니다.

어떤 값이 그중 누구에게 가는지는 `q.Dispatch.getHandler(inst, key, value)`로 물어볼 수 있습니다.
앞 장들에서 놓아 온 것들을 하나씩 물어보면 이렇습니다.

| 어디에 무엇을 놓았나 | 맡는 핸들러 |
|---|---|
| 숫자 키에 `q.Tag("Card")`(05) | `TagFallbackHandler` |
| 숫자 키에 `q.Attr { Kind = "counter" }`(05) | `AttrGroupFallbackHandler` |
| 숫자 키에 `q.Ref(nil)`(06) | `RefLeafHandler` |
| 숫자 키에 `q.Effect(fn)`(07) | `EffectLeafHandler` |
| 숫자 키에 `q.Slot {}`(10) | `SlotHandler` |
| 숫자 키에 `D.Frame {}`(02) | `InstanceChild` |
| 문자 키 `Text`에 문자열(02) | `Property` |
| 문자 키 `Activated`에 함수(04) | `Event` |
| **숫자 키든 문자 키든** `q.Source(...)`(03) | `StoreBind` |

<!-- mock 실측 2026-09-11: gs.handlers9.luau — 위 아홉 자리의 getHandler(...).name -->

앞 장들이 하나씩 "숫자 키 자리엔 자식만 오는 게 아니다"라고 말해 온 것이 이 표입니다. 자식
인스턴스는 **특권을 가진 것이 아니라** 저 목록의 한 줄(`InstanceChild`)일 뿐입니다.

<details>
<summary><strong>문자 키에 <code>Tag</code>를 넣으면요?</strong></summary>

아무도 손을 들지 않아 그 자리에서 던집니다. 문자 키 자리에서 값을 맡는 것은 프로퍼티·이벤트(와
그것을 감싼 `State`)뿐이고, `Tag`나 `Effect` 같은 값은 애초에 **숫자 키 자리의 값**으로만 선언돼 있기 때문입니다.

```
Dispatch: no handler matched key Foo (value: table, brand: Tag) — check that the provider for this value (e.g. quad-roblox) is initialized
```

`Effect`처럼 자기 자리를 아는 값은 더 친절한 문구를 따로 답니다.

```
Effect: must be an array item, not the value of a string key
```

첫 메시지가 "프로바이더가 초기화됐는지 보라"고 말하는 이유는, 같은 증상이 **키를 잘못 쓴 경우**와
**그 값을 맡을 핸들러를 심는 쪽이 아직 안 붙은 경우** 둘 다에서 나기 때문입니다.

</details>

---

## 2. `State`가 오면 벗겨서 한 칸 아래로

표의 마지막 줄이 이 장의 핵심입니다. `State`는 숫자 키에서도 문자 키에서도 **같은 핸들러**
(`StoreBind`)가 맡습니다. 그리고 그 핸들러가 하는 일은 값을 어딘가에 쓰는 것이 아니라 **한 겹
벗기는 것**입니다 — 그 `State`를 구독해 두고, 지금 담긴 실제 값을 **같은 자리의 한 칸 아래로**
다시 넘깁니다. 그 아래 칸에서 "이 값, 누가 맡을래?"가 처음부터 다시 돕니다.

그래서 이런 등식이 성립합니다.

> **`State<X>`가 그 자리에 되는가** = **`X`가 그 자리에 되는가**

05·07·10장이 전부 여기서 나옵니다. `Tag`가 숫자 키 자리에 되니까 `State<Tag>`도 되고, 관측 핸들이
되니까 `State<Observer?>`도 되고, 자식 인스턴스가 되니까 `State<Instance?>`도 됩니다. 셋을 따로
지원한 것이 아니라, **한 칸 아래로 내려간 뒤에는 셋을 구분할 이유가 없어지는** 것입니다.

[03장](./03-flowing-values.md)에서 파이프가 프로퍼티에 닿았던 것도 정확히 같은 경로입니다.
`Text = count:Compute(...)`의 자리에서 `StoreBind`가 먼저 잡고, 벗긴 문자열이 한 칸 아래에서
`Property`에게 갑니다. "파이프를 프로퍼티에 꽂는다"는 표현은 그 두 칸을 줄여 부른 것입니다.

칸은 한 번만 생기는 것도 아닙니다. `State` 안에 `State`를 담으면 칸이 하나 더 생길 뿐입니다.

```luau
-- 새 예시: 별도 스크립트
const a = q.Source("A")
const b = q.Source("B")
const which = q.Source(a)      -- State를 담은 State

const label = D.TextLabel { Text = which }
print(label.Text)   --> "A"

a:Set("A2")
print(label.Text)   --> "A2"

which:Set(b)
print(label.Text)   --> "B"

a:Set("A3")
print(label.Text)   --> "B"    -- a는 이제 이 자리와 무관하다
```

**실행하면** 마지막 줄이 `B` 그대로입니다. `which`가 `b`를 가리키는 순간 `a`를 보던 아래 칸이
통째로 걷혔기 때문입니다. 다음 절이 그 "걷힌다"를 봅니다.
<!-- mock 실측 2026-09-11: gs.ch18.luau "18 §2 C" — A / A2 / B / B -->

---

## 3. 갈아 끼우면 이전 것은 어떻게 빠지나

걷히는 자리가 구독 하나뿐이면 신경 쓸 일이 없습니다. 그런데 `Effect`처럼 **뒤처리가 딸린 것**을
자리에 놓았다면 이야기가 다릅니다. 자리를 떠나는 `Effect`의 cleanup이 도는지, 아니면 조용히
버려지는지가 실제로 문제가 됩니다.

```luau
-- 새 예시: 별도 스크립트
const count = q.Source(0)

local function makeEffect(label)
    return q.Effect(function()
        print(`{label} run {count:Get()}`)
        return function()
            print(`{label} cleanup`)
        end
    end, count)
end

const which = q.Source(makeEffect("A"))   --> A run 0      (만드는 자리에서 한 번)
const host = D.Frame { which }

count:Set(1)                              --> A cleanup, A run 1
which:Set(makeEffect("B"))                --> B run 1 (B를 만들 때), 이어서 A cleanup (A가 자리를 떠나며)
count:Set(2)                              --> B cleanup, B run 2
host:Destroy()                            --> B cleanup
```

**실행하면** `A cleanup`이 자리를 떠나는 시점에 **정확히 한 번** 찍힙니다. 그 뒤로 `count`를 아무리
바꿔도 A는 다시 돌지 않습니다. 07장이 cleanup이 도는 네 자리 중 하나로 꼽았던 "그 숫자 키 자리를
다른 값으로 갈아 끼울 때"가 이것입니다.
<!-- mock 실측 2026-09-11: gs.effectswap.luau — A run 0 / A cleanup / A run 1 / B run 1 / A cleanup / B cleanup / B run 2 / B cleanup -->

`Ref`도 같은 식으로 빠집니다. 자리를 떠나는 상자는 **비워집니다.**

```luau
-- 새 예시: 별도 스크립트
const refA = q.Ref<<TextLabel?>>(nil)
const refB = q.Ref<<TextLabel?>>(nil)
const which = q.Source(refA)

const label = D.TextLabel { which, Text = "안녕" }
print(refA.Value ~= nil, refB.Value ~= nil)   --> true   false

which:Set(refB)
print(refA.Value ~= nil, refB.Value ~= nil)   --> false  true
```

[06장](./06-ref.md)에서는 반대 이야기를 했습니다 — **담긴 인스턴스를 `Destroy()`해도 상자는 스스로
비워지지 않는다**고요. 두 서술은 어긋나지 않습니다. 여기서 비워지는 이유는 인스턴스가 죽어서가
아니라 **그 상자가 자리를 떠났기** 때문입니다. `Ref`는 대상의 죽음을 모르고, 자기가 앉은 자리가
걷히는 것만 압니다.

값 종류마다 "빠진다"가 무슨 뜻인지는 이렇습니다.

| 자리의 `State`가 내놓던 것이 바뀌면 | 일어나는 일 |
|---|---|
| `Tag` | 두 집합의 **차이만** 엔진에 나갑니다. 같은 집합이면 호출이 하나도 없습니다 |
| `Attr` 그룹 | 떠나는 그룹은 이름을 **반납만** 하고 엔진에 심긴 값은 **그대로 남습니다**. 새 그룹은 **이름 전부를 다시 심습니다** — 값이 같은 이름까지 다시 |
| `Ref` | 떠나는 상자가 **비워지고**(`:Callback`도 `nil`로 한 번 불립니다) 새 상자가 채워집니다. `nil`을 놓으면 둘 다 빈 채로 남습니다 |
| `Observer` | 떠나는 것은 그 시점부터 멈춥니다. 새 것은 놓이는 순간 최신값으로 한 번(보류분 재생) 뒤 계속 받습니다 |
| `EffectHandle` | 떠나는 것의 cleanup이 **한 번** 돕니다. 새 것은 놓이기 전, 만들어질 때 이미 한 번 돌아 있습니다 |
| 자식 `Instance` | 옛 것은 트리에서 **떼어지기만** 하고 파괴되지 않습니다(10장 6절 그대로) |

<!-- mock 실측 2026-09-11: gs.handlerslot.luau — 여섯 종류를 각각 q.Source에 담아 :Set으로 갈아 끼운 관측 -->

`Attr` 줄만 결이 다릅니다 — `Tag`처럼 "차이만"이 아닙니다. 05장 3절이 "교체하면 옛 속성 값이 그대로
남는다"를 함정으로 짚은 것이 이 줄입니다.

여섯 줄을 관통하는 규칙은 하나입니다. **같은 핸들러가 그 칸을 계속 맡으면** 아래 칸은 건드리지
않고, 앉아 있던 것이 새 값을 받아 자기 전이를 합니다(전이의 내용이 종류마다 다른 것이 위 표의
차이입니다). **핸들러가 바뀌거나 `nil`이 오면** 그 칸과 그 아래를 깊은 쪽부터 전부 되돌린 뒤
새로 설치합니다. Effect의 cleanup, Observer의 정지, Ref의 비움, 인스턴스 떼기가 전부 그
"되돌리기"의 얼굴입니다.

<details>
<summary><strong><code>Destroy()</code>할 때도 이 되돌리기가 도나요?</strong></summary>

아닙니다. `Destroy()`는 자리를 갈아 끼우는 일이 아니라 **수명을 수거하는** 일이라, 그 인스턴스에
매달려 있던 것이 자리별 되돌리기를 거치지 않고 통째로 수거됩니다. `Effect`의 cleanup이 그때도 한 번
도는 것은 수명 쪽 경로에 따로 걸려 있기 때문이지, 위 표의 전이가 돌아서가 아닙니다([19장](./19-wrap-up.md)의
"화면을 내릴 때"가 그 경로입니다). 그래서 `Destroy()`한 트리는 다시 못 살리지만, 자리를 떠났을 뿐인
것은 다시 놓으면 그대로 돌아옵니다.

</details>

---

## 4. 왜 알아 두나

첫째, **남이 써 둔 코드를 읽을 때** 기준이 하나로 줄어듭니다. `D.Frame { someState }` 같은 줄을
만나면 `someState`가 무엇을 하는 물건인지 추적할 필요가 없습니다 — **그 State가 무엇을 내놓는지**만
보면 됩니다. `Tag`를 내놓으면 이름표 자리이고, `Instance`를 내놓으면 자식 자리이고, `nil`이 될 수
있으면 그때 그 자리가 비는 것입니다. 자리와 값 종류만으로 읽힙니다.

둘째, **처음 보는 값을 쓰는 코드**를 만나도 당황할 일이 줄어듭니다. 위에서 본 핸들러 목록은 고정된
것이 아니라 **등록되는** 것이라, 백엔드가 넣은 프로퍼티·이벤트·트윈도 누가 따로 만들어 붙인 값
타입도 같은 줄에 서서 같은 질문을 받습니다. `D.Frame { ... }` 안의 낯선 값은 문법이 아니라
**어딘가에서 등록된 핸들러 하나**입니다.

값에 처리를 맡기는 창구가 props만인 것도 아닙니다. [16장](./16-blocker.md)에서 `q.Blocker()`를
`:Apply`에 넘길 수 있었던 것도 결이 같습니다 — `state:Apply(factory)`는 넘어온 것이 함수면 그대로
부르고, `__apply` 메소드를 가진 테이블이면 그 메소드를 부릅니다. 다만 이건 위 핸들러 목록과 **다른
창구**입니다. 닮은 것은 "규약을 만족하는 값이면 라이브러리가 그 값을 몰라도 자리에 앉는다"이지,
같은 목록에 등록된다는 뜻이 아닙니다.

여기서부터는 만드는 쪽 이야기라 시작하기 트랙을 벗어납니다 — 핸들러를 직접 하나 등록해 보고
싶어지면 레퍼런스가, 왜 중앙 분기 대신 이 모양이 됐는지가 궁금해지면 Quadnomicon이 그 이야기입니다.

---

## 더 알고 싶다면

- [레퍼런스: 디스패치 핸들러 계약](../reference/extend/02-dispatch-handler-contract.md) — 핸들러 레코드, 되돌리기 함수의 계약, 우선순위 밴드, 직접 등록해 보는 예제
- [Quadnomicon Vol. 8](../quadnomicon/08-extensible-dispatch-engine.md) — 자리의 칸이 어떻게 쌓이고, 값이 바뀔 때 어디까지 다시 도는지
- [레퍼런스: `State`](../reference/core/03-state.md#stateapplyfactory) — `:Apply`가 받는 두 모양(함수와 `__apply`)
- [레퍼런스: `Tag` / `Attr`](../reference/core/09-tag-attr.md) — 집합·이름 규칙과 에러 문구 전체
