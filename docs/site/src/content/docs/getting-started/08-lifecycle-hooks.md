---
title: "08. 생성만 보고 싶다면 — 생명주기 훅"
description: "만들어질 때·다 그려졌을 때·없어질 때를 PreRef/PostRef/Effect로 직접 짜 본 뒤, 그것과 정확히 같은 것인 OnCreated/OnRendered/OnDestroyed로 바꿔 봅니다"
---
> **대상 독자**: [07. 관측하기](/getting-started/07-observer-effect/)를 끝낸 개발자
> **목표**: "만들어질 때 한 번 / 다 그려졌을 때 한 번 / 없어질 때 한 번"을 가장 짧게 적기

06장과 07장에서 `Ref`와 `Effect`를 봤습니다. 그런데 실제로 가장 자주 필요한 것은
그 둘의 **아주 좁은 쓰임 하나**입니다 — **만들어질 때 한 번**, **다 그려졌을 때
한 번**, **없어질 때 한 번**. 값을 계속 지켜볼 것도, 상자를 나중에 꺼내 쓸 것도
아닌데 상자를 만들고 콜백을 걸고 `nil` 가드까지 쓰는 건 그 수요엔 번거롭습니다.

먼저 지금까지의 재료만으로 직접 짜 보고, 그 다음에 이름을 붙이겠습니다.

---

## 1. 먼저 손으로 짜 봅니다

`card`에 세 자리를 더합니다. 전부 07장까지 나온 것뿐입니다.

```luau
-- … 위쪽 코드에 이어집니다(card를 이렇게 고칩니다)
const created = q.PreRef<<Frame?>>(nil)
created:Callback(function(inst)
    if inst then
        print("만들어짐:", inst.ClassName)
    end
end)

const rendered = q.PostRef<<Frame?>>(nil)
rendered:Callback(function(inst)
    if inst then
        const kids: { Instance } = inst:GetChildren()
        print("다 그려짐: 자식", #kids, "개")
    end
end)

const card = D.Frame {
    -- …프로퍼티 생략(UICorner = 12까지 그대로)…

    created,
    rendered,
    q.Effect(function()
        return function()          -- ← 의존성 없이 cleanup만: 이게 곧 파괴 콜백
            print("없어짐")
        end
    end),

    D.TextLabel { --[[ …생략… ]] },
    D.TextButton { --[[ …생략… ]] },
}
```

**실행하면** 카드가 만들어지는 동안 두 줄이 순서대로 찍힙니다.

```
만들어짐: Frame
다 그려짐: 자식 3 개
```

그리고 나중에 `card:Destroy()`를 하면 그때 `없어짐`이 한 번 찍힙니다.
자식이 셋인 것은 라벨과 버튼에 더해, `UICorner = 12`가 만들어 붙인 관리 자식까지 세기 때문입니다.
<!-- mock 실측 2026-09-11: gs.hooks2.luau — 손으로 짠 셋과 이름 붙은 셋의 출력이 동일(만들어짐 Frame / 다 그려짐 3 / Destroy에 없어짐) -->

셋이 각자 다른 시점을 잡는 이유는 06·07장에서 이미 봤습니다. `PreRef`는 그
인스턴스에 아무 일도 일어나기 전에 채워지고, `PostRef`는 자식과 프로퍼티가 전부
끝난 뒤에 채워지며, **의존성이 없는 `Effect`**는 만들어질 때 한 번 돌고 돌려준
cleanup만 남겨 두었다가 매달린 인스턴스가 죽을 때 그것을 한 번 실행합니다.

<details>
<summary><strong>왜 <code>nil</code> 가드가 필요한가요?</strong></summary>

`ref:Callback(fn)`은 [06장 3절](/getting-started/06-ref/)에서 본 대로 **등록하는 그 자리에서 지금 값으로 한 번 즉시 불립니다.** 위에서는 카드를 만들기 전에 등록했으니 그 첫 호출이 받는 값은 `nil`입니다.

그래서 `if inst then`이 없으면 "만들어짐"이 실제 생성보다 먼저, 그것도 빈 값으로 한 번 더 찍힙니다. 가드는 그 등록 시점의 한 번을 걸러 내는 것뿐입니다.

</details>

---

## 2. 이 셋에는 이름이 있습니다

같은 것을 quad가 이미 이름 붙여 두었습니다. 위 코드를 이렇게 줄일 수 있습니다.

```luau
-- … 위쪽 코드에 이어집니다(1절에서 만든 상자 둘을 지우고 card를 이렇게 고칩니다)
const card = D.Frame {
    -- …프로퍼티 생략…

    q.OnCreated<<Frame>>(function(inst)
        print("만들어짐:", inst.ClassName)
    end),
    q.OnRendered<<Frame>>(function(inst)
        const kids: { Instance } = inst:GetChildren()
        print("다 그려짐: 자식", #kids, "개")
    end),
    q.OnDestroyed(function()
        print("없어짐")
    end),

    D.TextLabel { --[[ …생략… ]] },
    D.TextButton { --[[ …생략… ]] },
}
```

**실행하면** 출력이 §1과 한 줄도 다르지 않습니다.

셋이 돌려주는 값은 각각 **`PreRef` / `PostRef` / `EffectHandle` 그 자체**라서,
1절에서 상자를 놓았던 그 숫자 키 자리에 그대로 놓습니다. 콜백이 받는 첫 인자는
**항상 인스턴스**입니다 — `nil` 가드가 안에 들어 있습니다.

요소 타입은 `q.OnCreated<<Frame>>(...)`처럼 **타입 인자**로 줍니다(`quad-base`는
백엔드의 요소 타입을 모르므로 그 자리가 제네릭이고, 콜백 파라미터 주석으로는
채워지지 않습니다). `OnDestroyed`만 타입 인자가 없습니다 — 콜백이 인스턴스를
받지 않기 때문입니다.

---

## 3. 안이 이렇게 생겼습니다

이 셋은 **새로 만들어진 물건이 아닙니다.** `quad-base`의 LifecycleHooks 모듈에
들어 있는 것도 사실상 이 열 줄이 전부입니다.

```luau
-- (문서용으로 다듬은 요지 — 인자 검사·에러 위치 지정 줄과 타입 인자는 뺐습니다)
local function guard(fn)
    return function(value, ref)
        if value ~= nil then            -- 등록 시 한 번 오는 nil 호출을 건너뛴다
            fn(value, ref)
        end
    end
end

local function OnCreated(fn)
    return q.PreRef(nil):Callback(guard(fn))
end

local function OnRendered(fn)
    return q.PostRef(nil):Callback(guard(fn))
end

local function OnDestroyed(fn)
    return q.Effect(function()
        return fn                       -- 의존성 없는 Effect의 cleanup이 곧 파괴 콜백
    end)
end
```

**새 브랜드도, 새 디스패치 개념도 없습니다.** 1절에서 당신이 손으로 짠 것과
글자까지 같은 모양이고, 그래서 두 절의 출력이 같았던 것입니다. 훅을 여러 개
등록하는 것도 그저 **숫자 키 자리를 여러 개 쓰는 일**이라, 같은 종류끼리는 숫자 키에
적은 순서대로 불립니다.

---

## 4. 알아 둘 것 둘

**`OnRendered`가 보장하는 것은 자기 아래까지입니다.** 이 훅이 불리는 기준은
그 인스턴스의 숫자 키·문자 키 처리가 끝난 시점이지, **부모에 붙는 시점이
아닙니다.** 그때 `Parent`는 아직 **모르는 상태**입니다 — 리터럴 중첩으로
만들어졌다면 대개 `nil`이고, 이미 트리에 있는 인스턴스를 넘겨받았다면 이미 차
있습니다. 게다가 그 뒤로 `Parent`가 **영영 바뀌지 않을 수도** 있으므로,
"나중에 Parent가 설정되면 그때 재자"는 식의 코드는 한 번도 안 돌 수 있습니다.
화면 좌표나 `AbsoluteSize`처럼 조상에 따라 달라지는 값은 여기서 읽지 마세요
([레퍼런스: 생명주기 훅](/reference/sugar/04-lifecycle-hooks/)).

**`OnDestroyed`는 숫자 키 자리에 놓아야 삽니다.** 인스턴스에 매달린 `Effect`의
cleanup이라, 어디에도 놓지 않으면 묶일 인스턴스가 없어 그 함수가 불릴 일도
없습니다. 07장의 `Observer`·`Effect`와 같은 규칙입니다.

---

## 더 알고 싶다면

- [레퍼런스: 생명주기 훅](/reference/sugar/04-lifecycle-hooks/) — 셋의 시그니처와 불리는 시점, `OnRendered`가 보장하지 않는 것, 여러 개 등록했을 때의 순서
- [레퍼런스: `Ref`](/reference/core/07-ref/) — 이 훅들이 얹혀 있는 `PreRef`/`PostRef` 프리미티브
- [레퍼런스: `Observer` / `Effect`](/reference/core/05-observer-effect/) — cleanup이 도는 세 자리
