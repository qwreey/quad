---
title: "19. 정리 — 여기서부터 어디로"
description: "열아홉 장에서 만든 것을 한 줄씩 되짚고, 다음에 읽을 문서를 고릅니다"
---
# [시작하기] 19. 정리 — 여기서부터 어디로

> **대상 독자**: [18. 자리에 놓인 값은 누가 처리하나](./18-handlers.md)까지 따라온 개발자
> **목표**: 만든 것을 되짚고, 다음에 읽을 곳 고르기

여기서 새로 배우는 것은 없습니다.

---

## 여기까지 만든 것

- [01](./01-setup.md) **설정 모듈** 하나에 `q`를 만들어 두고, 진입점에서 `ScreenGui`를 띄웠습니다.
- [02](./02-first-screen.md) `D.Frame`으로 **카드**를 그렸습니다 — 문자 키는 프로퍼티, 숫자 키는 자식, `Parent`는 밖에서.
- [03](./03-flowing-values.md) `q.Source`와 `:Compute`로 값이 **원천에서 프로퍼티까지 흐르게** 했습니다.
- [04](./04-reacting.md) 버튼 **이벤트**로 원천을 바꿔 카운터를 완결시켰습니다.
- [05](./05-tag-attr.md) `q.Tag`와 `q.Attr`로 인스턴스에 **이름표와 속성**을 달아 밖에서 찾을 수 있게 했습니다.
- [06](./06-ref.md) `q.Ref`/`q.PreRef`/`q.PostRef`로 **만들어진 인스턴스를 손에 쥐었습니다** — 언제 채워지는지와 `:Unwrap`/`:Callback`/`:Wait`까지.
- [07](./07-observer-effect.md) `:Observer`로 화면 밖에서 **관측**하고, `q.Effect`로 의존성 여럿과 **cleanup**을 다뤘습니다 — 화면 안쪽은 값으로, 바깥은 `Effect`로.
- [08](./08-lifecycle-hooks.md) `q.OnCreated`/`q.OnRendered`/`q.OnDestroyed`로 **생성·완성·파괴 한 번씩**을 잡았습니다 — 06·07의 재료로 손수 짜 본 뒤 같은 것에 이름을 붙였습니다.
- [09](./09-modifier.md) 반복되는 프로퍼티 묶음을 `Modifier` **값**으로 빼 모듈 하나에 모았습니다.
- [10](./10-slot.md) `q.Slot`으로 카드 안에 **자식이 들어갈 자리**를 잡고 넣고 뺐습니다 — `Offset`/`Length`가 따라 움직이는 것과, 자리 하나를 `State`로 갈아 끼우는 것까지.
- [11](./11-components.md) 카운터를 **컴포넌트**로 쪼개고, 그 `Slot`을 props로 넘겨받았습니다.
- [12](./12-functions.md) 지금까지 써 온 콜백·클로저·**팩토리**·커링에 이름을 붙이고, 팩토리를 컴포넌트에 넘겨 안쪽 상태에 붙였습니다.
- [13](./13-lists.md) `Slot:List`로 데이터에 맞춰 **목록**을 그렸습니다 — 살아남은 키는 재사용, 하나짜리는 `:Single`.
- [14](./14-context.md) `q.Context` 가방으로 값을 **층을 건너** 넘겼습니다 — 중간 컴포넌트는 안에 뭐가 들었는지 모른 채.
- [15](./15-animation.md) `q.Tween`과 `q.Animate`로 값이 **부드럽게 넘어가게** 했습니다.
- [16](./16-blocker.md) `q.Blocker`로 값 여럿을 바꾸는 구간을 묶어 **통지 한 번**으로 접었습니다.
- [17](./17-laziness.md) 그 모든 자리가 **언제 도는지**를 한자리에서 대조했습니다.
- [18](./18-handlers.md) props의 자리마다 **누가 값을 맡고 어떻게 놓는지** — `State<Tag>`·`State<Observer?>`·`State<Instance?>`가 한 원리였음을 봤습니다.

## 화면을 내릴 때

열아홉 장 동안 화면을 띄우기만 했으니 내리는 법도 한 번 적어 둡니다. 루트 하나를 `Destroy()`하면 됩니다.

```luau
-- 새 예시: 별도 스크립트(01장의 진입점에서 만든 screen을 내린다)
screen:Destroy()
```

**실행하면** 그 아래 인스턴스가 전부 함께 파괴되고, 그 인스턴스들의 숫자 키 자리에 매달려 있던 것 — `:Observer`, `q.Effect`(cleanup이 한 번 돕니다), 훅, 트윈 — 이 같이 멈춥니다. 07·08장에서 카드 하나로 본 일이 트리 전체에 한꺼번에 일어나는 것입니다. 따로 끊어야 하는 것은 하나뿐입니다 — `:Subscribe()`로 **직접** 건 강한 구독은 인스턴스와 무관하므로 `:Unsubscribe()`를 불러 주세요. 그리고 `Destroy()`한 트리는 다시 살릴 수 없으니, 화면을 잠깐 감출 거라면 `Enabled = false`(또는 `Visible = false`)로 두고 정말 버릴 때만 내립니다.
<!-- mock 실측 2026-09-11: gs.teardown.luau — screen:Destroy() 뒤 자리에 묶인 Observer는 멈추고 Effect cleanup 1회, :Subscribe()한 강한 구독은 계속 돈다 -->

---

## 다음에 읽을 곳

- **[실전 레시피](../how-to/01-component-conventions.md)** — 재사용 가능한 컴포넌트를 만들 때의 경계 규약이 첫 장입니다. 이어서 폼 검증, 긴 목록, 외부 신호 브릿지, 테마, 헤드리스 테스트, Studio 템플릿 `Claim`, 그리고 부록인 [에러 읽는 법](../how-to/09-debugging-and-troubleshooting.md)이 있습니다.
- **[API 레퍼런스](../reference/00-index.md)** — 타입당 한 페이지. 시그니처·인자·에러 문구를 찾을 때.
- **[The Quadnomicon](../quadnomicon/01-revision-and-epochmap.md)** — 위의 동작들이 내부에서 어떻게 구현돼 있는지. 초보자용은 아닙니다.
- **[왜 Quad인가](../overview/01-why-quad.md)** — 이 설계가 무엇을 포기하고 무엇을 얻었는지, 다른 도구와의 차이.

quad v1(`Quad.Init(id)` / `Class "Frame"`)을 쓰던 분이라면 걸리는 자리가 몇 군데 정해져 있습니다.

<details>
<summary><strong>v1을 쓰던 손버릇 중에 뭐가 안 통하나요?</strong></summary>

v1을 쓰던 분이 가장 자주 넘어지는 자리들입니다. 큰 그림(무엇이 왜 없어졌고 어떤 틀로 옮기는지)은 [quad v1에서 오는 분께](../overview/02-from-v1.md), 전체 이관 절차는 [08. quad v1에서 v2로 옮기기](../how-to/08-migrating-from-v1.md)에 있습니다.

- **`:With`는 이름만 같은 다른 것**입니다 — v1의 파생은 v2에서 `:Compute(fn, ...deps)`입니다.
- **`Mount(parent, obj)`는 없습니다** — 만들어진 뒤 `obj.Parent = parent`.
- **이벤트는 문자 키에, `self`는 오지 않습니다** — `[Event "Activated"] = fn(self, …)` → `Activated = fn(…)`.
- **`Class.Extend()`는 없습니다** — 컴포넌트는 props를 받아 인스턴스를 돌려주는 평범한 함수입니다.
- **`myStore "key"`는 `store.key`**입니다 — 문자열 레지스터가 아니라 그 자리에 넣은 `Source` 그 자체입니다.
- **id로 찾아오는 창구가 없습니다** — `Frame "id" {}` / `Store.GetObject(id)`는 폐지됐고, `Ref`는 그 대체재가 아닙니다.
- **`Style`은 `Modifier`이고 숫자 키 자리에 놓입니다** — 이름 매칭이 아니라 **놓인 순서**가 우선순위입니다.

</details>
