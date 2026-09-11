---
title: "06. Roblox Studio 없이 헤드리스로 테스트하기"
description: "Studio 없이 quad의 반응형 로직과 디스패치를 헤드리스로 검증하는 방법을 설명합니다"
---
> **대상 독자**: 반응형 로직과 컴포넌트 조립을 Studio를 켜지 않고 검증하고 싶은 개발자
> **다루는 개념**: `quad-base`의 엔진 무관성, 프로바이더 주입, mock 백엔드, `./scripts/test.sh`
> **범위**: 갖다 쓸 수 있는 **공개 mock 패키지는 아직 없습니다**(§3). 이 문서가 다루는 것은 이 저장소의 테스트 구조와, 자기 프로바이더를 직접 붙여 헤드리스로 검증하는 방법입니다.

---

## 1. `quad-base`는 엔진을 모른다

`quad-base`는 Roblox 전역(`Instance`, `game`, `task` …)을 참조하지 않습니다.
물리 트리를 만지는 일은 전부 **프로바이더가 주입하는 엔진 op**를 통해서만
일어납니다. 그래서 `Source`/`State`/`Store`/`Blocker`/`Slot` 같은 반응형·부기
로직은 **평범한 `luau` CLI에서 그대로 돌아갑니다.**

이 구조를 테스트에 쓰는 방법은 세 층이고, 앞의 둘이 CLI에서 돕니다.

```
1. 반응형 그래프 (Source, State, Store, Blocker, Compute)   → 백엔드 없이 그냥 돈다
2. 디스패치/Slot 부기 (Slot:List, 재조정, 생명주기)          → mock 백엔드 위에서 돈다
3. 실제 Roblox 프로퍼티/이벤트/Tween                          → Roblox Studio에서 직접 확인해야 한다
```

UI 버그가 났을 때 1·2층에서 재현되면 Studio를 열 필요가 없습니다.

---

## 2. 반응형 그래프만 테스트하기

백엔드 설치 없이 `quad-base`만 있으면 됩니다.

```luau
-- 설치 경로는 프로젝트 구성에 따라 다르다(시작하기 00 참고)
local Quad = require("@game/ReplicatedStorage/roblox_packages/quad_base")

local count = Quad.Source(0)
local isEven = count:Compute(function(c)
    return c:Get() % 2 == 0
end)

assert(count:Get() == 0, "초기값은 0")
assert(isEven:Get() == true, "0은 짝수")

count:Set(1)
assert(count:Get() == 1 and isEven:Get() == false, "파생 상태가 따라온다")
```

`Blocker`도 같은 층입니다. 다만 **`Blocker`는 `state:Apply(blocker)`로 붙인
노드만 게이트한다**는 점에 주의하세요 — 그냥 만들어 두기만 하면 아무것도
막히지 않습니다. 그리고 막히는 것은 **전파**이지 값이 아닙니다.

```luau
local raw = Quad.Source(0)
local gate = Quad.Blocker()
local gated = raw:Apply(gate)

gate:On()
raw:Set(1)
raw:Set(2)
assert(gated:Get() == 2, "값 자체는 항상 최신 — 막히는 것은 아래로의 전파다")
gate:Off()          -- 여기서 밀린 전파가 정확히 한 번
-- gate:OffWithoutEmit() -- 밀린 전파를 버리며 연다
```

---

## 3. 백엔드가 필요한 것 — 프로바이더 주입

`Observer`/`Effect`/`Slot`은 **인스턴스 수명**에 묶여 동작하므로, 생명주기 op를
심는 프로바이더가 있어야 합니다. 설치 표면은 하나입니다.

```luau
local q = Quad.New():UseProvider(myProvider)
```

- `UseProvider`는 **모듈당 한 슬롯**입니다. 같은 프로바이더 함수로 다시 부르면
  아무 일도 안 하고(멱등), 다른 함수를 넣으면
  `UseProvider: this Quad module already has a provider — a module cannot serve two backends`
  에러입니다.
- `require(quad-base)`가 돌려주는 값은 이미 만들어진 기본 인스턴스입니다.
  테스트마다 격리된 인스턴스가 필요하면 `Quad.New()`를 쓰세요.

참고로 이 저장소의 mock 프로바이더는 물리 트리 조작·판정·훅·생명주기 넷·
태그/어트리뷰트·시간 op를 모두 심고, 그 위에 얹는 공개 표면은 없습니다(빈 확장 —
`D`가 없습니다). op 하나하나가 무엇을 요구하는지는
[백엔드 프로바이더 규약](/reference/extend/01-backend-provider-contract/)이
다룹니다. 다만 백엔드가 실제로 채워야 하는 op 목록의 정본은 그 백엔드의
엔진 op 파일이니, 자기 프로바이더를 쓸 생각이라면 문서를 계약으로 믿지 말고
그쪽을 보세요.

> ⚠️ **공개 mock 패키지는 아직 없습니다.** 이 저장소가 쓰는
> `quad-base/test/mock.luau`는 테스트 내부물이고 배포되지 않습니다
> (범용 렌더 디버깅 도구 `quad-mock`은 백로그입니다). 지금 헤드리스로
> 컴포넌트를 검증하려면 자기 프로바이더를 직접 쓰거나, 이 저장소의 spec을
> 본보기로 삼으세요.

### 생명주기에 묶이기 전까지 `Observer`는 발화하지 않는다

헤드리스 테스트에서 가장 자주 걸리는 함정입니다.

```luau
local hp = q.Source(100)
local runs = 0
local observer = hp:Observer(function()
    runs += 1
end)
assert(runs == 1, "등록 즉시 1회 발화한다")

hp:Set(90)
assert(runs == 1, "아직 아무 인스턴스에도 안 묶였다 — 변경은 보류된다")

q.bindLifetime(host, observer)   -- host는 이 백엔드가 소유한 인스턴스
assert(runs == 2, "묶는 순간 보류분이 한 번 재생된다")

hp:Set(80)
assert(runs == 3, "이후 변경은 그대로 발화")

host:Destroy()
hp:Set(70)
assert(runs == 3, "인스턴스가 죽으면 더 이상 발화하지 않는다")
```

실제 컴포넌트 코드에서는 `bindLifetime`을 직접 부르지 않습니다 —
`Observer`/`Effect`를 **props의 숫자 키 자리에** 넣으면 quad가 그 인스턴스 수명에
묶어 줍니다.

---

## 4. 트리 조립 검증

백엔드가 설치된 인스턴스라면 `Slot`의 재조정을 물리 자식 수로 직접 검증할 수
있습니다.

```luau
local data = q.Source({ { id = "a" }, { id = "b" } })
local slot = q.Slot():List(data, function(item: any, _index, _offset, prev, ud): (any, any)
    if item == q.KeyGone then
        return nil, ud
    end
    return prev or makeElement(), ud
end, function(item)
    return item.id
end)

q.Dispatch.drive(parent, { slot })
assert(#parent:GetChildren() == 2, "두 요소가 붙었다")

data:Set({ { id = "b" } })
assert(#parent:GetChildren() == 1, "사라진 키의 요소는 파괴된다")
```

`q.Dispatch.drive`는 이 저장소의 spec이 쓰는 디스패치 진입점입니다 — 컴포넌트
코드에서 직접 부를 일은 없고, 안정된 테스트 API로 약속된 표면도 아닙니다.

Roblox 프로퍼티/이벤트까지 태우려면 `quad-roblox`를 설치한 채 반사(reflection)
조회와 `Instance.new`를 테스트용으로 갈아끼워야 합니다 — 이 저장소의
`quad-roblox/test/spec.*.luau`가 그 관용구를 보여줍니다.

---

## 5. 테스트 돌리기

이 저장소의 진입점은 **`./scripts/test.sh` 하나**입니다.

```bash
./scripts/test.sh; echo $?
```

- **판정은 종료 코드입니다.** 스크립트는 타입 검사 진단이 있어도 개별 테스트
  실행을 계속하므로, 출력에 찍힌 `ALL PASS` 줄 개수를 세면 안 됩니다. `0`이
  아니면 실패입니다.
- 스크립트는 먼저 `scripts/relink.sh`를 돌립니다. **`luau` CLI가 심볼릭 링크를
  못 타기 때문**입니다 — 패키지 링크를 실제 복사로 바꿔놓지 않으면 스모크가
  죽고, 더 나쁘게 `luau-analyze`는 모듈을 `any`로 떨어뜨린 채 **조용히
  통과**합니다("거짓 클린").
- 그다음 타입 검사 두 그룹이 돕니다. 엔진 무관 그룹(`quad-base`/`quad-types`/`quad-error`/`type-version-check`)은
  **Roblox 정의 없이** 구 솔버와 신 솔버 두 패스로 분석해서 엔진 전역이 새어 들어오면 그 자리에서
  걸립니다. `quad-roblox`만 Roblox 타입 정의를 얹고 봅니다.
- 그다음 `quad-base/test/smoke.*.luau`, `quad-base/test/spec.*.luau`,
  `quad-roblox/test/spec.*.luau`를 하나씩 실행하고, 마지막으로 문서 커버리지와 버전 정합성 게이트가 돕니다.

테스트 프레임워크는 쓰지 않습니다. 각 spec은 그냥 `assert`와 `print`로 된
평범한 Luau 스크립트이고, 실패하면 `assert`가 그 자리에서 던집니다.

```luau
print("=== 1. 무엇을 검증하는지 ===")
do
    -- ... assert들 ...
    print("PASS")
end
```
