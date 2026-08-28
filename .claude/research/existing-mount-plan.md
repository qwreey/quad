# 이미 있는 트리를 quad가 소유하기 — `Claim` + `D.Mapper` (가칭)

> **[2026-08-28 신설, 사용자 발의]** 10라운드 `H-148`(`Parent` 거부 문구)을
> 논의하다 **더 큰 표면의 공백**이 드러나 만든 문서. 상태: **설계 논의 중 —
> 방향은 사용자 확정, 갈래 몇 개 미결(§5)**. M2 착수 게이트 아님, **M5 스코프**
> (**[2026-08-28 `H-161`]** "M5 이후"에서 당김 — 루트 예외 폐기 뒤 M5의 유일한 루트
> 부착 경로; 프로바이더 op가 필요하니 M5가 자연스러운 자리). 결정이 나면 `base/`로
> 승격한다.
>
> **`archive/existing-instance-bind-rejected.md`(2026-08-14 기각)와의 관계**:
> 그 기각은 *"이미 있는 Instance에 나중에 새 props를 다시 바인드"*였고 사유는
> "quad가 만들지 않은 트리의 자식 구성을 바깥이 밀고 당기면 `setLength`/
> `setOffsetSource` 부기가 깨진다"였다. 이 문서는 그 반대 방향 — **한 번
> claim하면 quad가 소유하고 직계 자식은 사용자가 전부 매핑한다**는 계약이라
> claim 뒤엔 quad가 만든 트리와 같은 불변식이 성립한다. **재바인드는 여전히
> 미지원**(claim은 1회, 디스크립터는 `Processed`로 소진). 그 archive엔 "좁은
> 형태로 부활"이라는 배너를 달 것(반영 시).

## 1. 왜 필요한가 (사용자 원문)

`H-146`이 "루트는 사용자가 밖에서 `.Parent =`"로 닫혔는데, 사용자가 이어서
지적했다: *"slot 은 물리 장치에 mount 할 방법이 거의 존재하지 않음. Parent =
처럼 마운트 할 방법이 없는데? 그럼 PlayerGui 가 상위에 있고 거기에 GUI 를
여럿 바운딩 해야해서 `Slot { Shop{} … }` 하는게 안 될것 같은 느낌이 듦. 이건
Parent 이상의 문제인것 같아."* — 즉 **루트가 Slot일 수 없다**(Slot은 quad가
부기를 가진 부모 `inst` 아래에만 산다). 그리고: *"생성할 요소들 자체가 너무
많은 경우 Clone 이 엇청 더 싸서, 그 Clone 된 것 아래 quad 를 바인딩 할 방법이
있으면 좋은것도 사실인듯. … web 에서도 템플릿에 의해 유효한 요소일꺼고,
roblox 에서도 보면서 만들어낸 GUI를 바인딩하는건 흔한 요구라서 이 역시 흔한
필요일꺼야."*

결론(사용자): *"이런 방식으로, 이미 있는 PlayerGui 아래 마운트를 거는거지.
… 이것도 똑같이 Quad 가 소유하게 될 요소가 되는거지. … 이렇게 끝내면 parent
를 설정할 문제 자체가 사라져"* — **`H-146`의 루트 예외와 `H-148`의 문구 문제가
같이 소멸**한다.

## 2. 모양 (사용자 스케치 + 확정된 것)

```lua
local M = D.Mapper                      -- 정의는 D 안에 산다. 유저가 필요하면 꺼낸다
local cloned = Claim(template:Clone(), M.Frame "root" {   -- ← 루트 이름은 미결(§5-1)
    M.TextLabel "Title" { Text = title },
    M.Frame "List" {
        Slot { … },                     -- 기존 부모 아래 Slot — 이제 가능
    },
    BackgroundColor3 = color,           -- props는 New와 같은 derive 테이블
}) -- -> cloned (claim한 루트 Instance)
```

- **`D.Mapper.<Class> "Name" { … }`는 Instance를 만들지 않고 디스크립터만
  만든다**(브랜드 `Mapper`류) — derive 테이블 + 매칭 키. `D.Frame`에 직접 얹지
  않는다(사용자: *"D.Frame 에 바로 바인딩은 위험한듯. 의미가 겹쳐버려"*).
- **`Claim(inst, descriptor) -> inst`가 최상위**. `inst`는 quad 밖에서 온 것
  (PlayerGui, `Clone()` 결과, Studio에서 만든 GUI). 이 호출로 `inst`와 매핑된
  하위 전부가 **quad 소유**가 된다 — `New`가 만든 것과 같은 gcconn/gchold·부기.
- **처리 순서는 `New`와 반대 방향에서 시작한다.** `New`는 안쪽 생성자가 먼저
  평가돼 자연히 bottom-up이지만, 매퍼의 안쪽은 평가 시점에 자기 Instance를
  모른다(부모가 아직 없다). 그래서 `Claim`이 **DFS로 내려가며 이름으로 해석 →
  자식부터 `drive` → 올라오며 부모 `drive`**. 사용자: *"핸들러가 된다면 위험해.
  일반 생성과 다르게, 상위 부터 처리하거든 … DFS 로써, 내려가는게 먼저고 그
  뒤에서 derive 를 걸어야해. 이건 derive 에선 구현하지 않고, 그 위의 무언가로써
  구현되어야할듯."* — `drive`/핸들러 층은 안 바뀌고 그 **위의 한 겹**이다.
- **매핑된 정적 자식은 `InstanceChildHandler`와 같은 부기(`setLength(inst,k,1)`)만
  하고 `.Parent =`는 안 한다**(이미 거기 있다). Slot은 평소처럼 `native*`로
  기존 부모 아래 끼운다.
- **디스크립터는 1회용** — claim 뒤 `Processed`로 소진(`PreRef`와 같은 관용구).
  재사용·이중 claim은 error.
- **매칭은 프로바이더 주입 op** `nativeFindChild(inst, key)`(가칭) — Roblox는
  `Name`, web은 id/selector. **quad-base가 순회·부기 전반을 구현하고
  프로바이더는 이 핸들만 낸다**(사용자: *"quad-base 에서 전반을 구현해주고
  필요 핸들을 구현하라고 남기는건 괜찮은 생각"*).
- **여러 quad 인스턴스가 한 트리를 claim — UB**(사용자 확정).
- **`H-142`(props에 `Parent` 금지)는 그대로.** 루트가 quad 소유가 되므로
  `H-146`의 "루트는 밖에서 `.Parent =`" 예외는 **폐기**.

## 3. 계약 — 자식은 전부 매핑한다

사용자: *"모든 개체를 유저가 직접 네임을 매핑해서 derive 테이블 안에서 내부
요소를 전부 매핑해준다를 계약으로 잡으면 문제가 없다고 생각해."*

- **부기 대상(그려지는 자식)은 전부 매핑해야 한다.** 안 된 자식이 남으면
  `nativeInsert`의 삽입 위치(web은 곧 DOM 순서)와 Length/Offset이 어긋난다.
- **숏핸드(`UICorner` 등 `UI*`)는 부기 대상이 아니다** — 그려지지 않고 Roblox에만
  있으며 단순 `Parent` 대입 요소. 사용자 확정: *"숏핸드를 quad 에서만 직접
  쓰거나 … 아니면 실제 UI 객체를 바인딩해서 숏핸드를 안 쓰거나"* — 둘 중 하나:
  (i) 템플릿엔 `UI*`가 없고 quad가 숏핸드 키로 만든다, (ii) 템플릿의 `UI*`를
  `M.UICorner "UICorner" {…}`처럼 **실제 객체로 매핑**하고 그 부모에 숏핸드
  키는 안 쓴다. 섞으면(템플릿에 `UICorner`가 있는데 숏핸드 키도 씀) 둘이
  생기는 것은 UB.
- **이름 중복·부재는 UB**(사용자 확정). **debug 모드**에선 `seen` 맵으로 중복을
  잡아 error(사용자 제안) — 부재·클래스 불일치도 같은 자리에서 검사.

## 4. 이 문서가 여는 것

- **루트**: `Claim(PlayerGui, M.ScreenGui "…" { Slot {…} })` — PlayerGui가
  quad 소유 부모가 되어 Slot이 그 아래 산다. `ScreenGui`를 `New`로 만들어
  붙이는 경우도 `Claim(PlayerGui, M.PlayerGui(...) { New "ScreenGui" {…} })`처럼
  정적 자식으로 들어간다(→ §5-3 루트 이름 문제).
- **템플릿 대량 생성**: `template:Clone()` → `Claim` — 각 사본이 독립 소유.
  Claim이 Instance를 돌려주므로 **Slot 요소로도 그대로 쓸 수 있다**(요소는
  `inst`) — "요소가 너무 많은 경우"의 답.
- **비루트 사용**: `New "Frame" { Claim(clone, …) }` — 반환된 `inst`가 정적
  자식으로 들어가면 `InstanceChildHandler`가 `Parent =`와 부기를 한다. 평가
  순서상 `Claim`이 먼저 끝나므로 bottom-up이 유지된다.

## 5. 미결 — 다음 배치 문항

1. **루트 디스크립터의 이름** — 루트는 `Claim`이 `inst`를 직접 받으니 매칭 키가
   필요 없다. 사용자: *"최상위는 이름을 뭐로 둬야할지 아직 모르겠음. 비워두는걸
   D.Mapper.Frame{} 으로 제공하는건 더 나빠보이는데. 아니면 테이블로써
   MapperRoot = {} Mapper.Frame (MapperRoot) {} 모양이 되어도 될것같음."*
   갈래: (a) 센티널 `MapperRoot`(`M.Frame(MapperRoot) {…}`) / (b) 루트는
   `Claim(inst, { … })`처럼 클래스 없는 맨 테이블(클래스는 `inst`가 이미 안다)
   / (c) 이름을 받되 무시. **권고 (b)** — 루트 클래스를 두 번 말하지 않고,
   `M.<Class>`는 "찾아야 하는 자식"에만 쓰여 뜻이 하나가 된다. 단 타입(`D`
   생성기가 만든 props 타입)을 잃으므로 `Claim<<"Frame">>(inst, {…})`처럼
   타입 인자로 보완 — `New<<X>>`와 같은 관용구.
2. **물리 순서 계약** — 디스크립터 배열 순서와 기존 트리의 실제 순서가 다를 때.
   Roblox는 물리 순서가 의미 없어 무관, web은 DOM 순서라 `nativeInsert` 위치가
   어긋난다. 갈래: (a) 디스크립터 순서가 정본이고 일치는 사용자 책임(UB,
   debug 검사) / (b) claim 시 quad가 `nativeMove`로 실제 순서를 디스크립터에
   맞춘다. **권고 (a)** — "이미 있는 걸 그대로"의 취지, Roblox에선 비용 0.
3. **`New`로 만든 자식을 claim된 부모에 넣는 것** — 위 §4 첫 항목. 정적 자식이니
   `InstanceChildHandler`가 `Parent =`를 하면 되고 새 결정은 없어 보이나,
   "매핑(이미 있음)"과 "생성(새로 붙임)"이 한 배열에 섞이는 것이 계약상
   괜찮은지 확인 문항.
4. **debug 검사의 범위** — 이름 중복 / 부재 / 클래스 불일치 / 미매핑 부기
   대상 자식 / 같은 quad의 이중 claim 중 어디까지. 권고: 전부(debug에선 싸다).
5. **표면 이름** — `Claim`/`Mount`/`Adopt`, `D.Mapper`/`D.Existing`.
   `Mount(root, parent)`를 `H-146`에서 기각한 사유("부기 없는 대상에 quad 객체
   주입")는 여기 반대로 적용된다 — claim은 부기를 *세우는* 행위. 권고 `Claim`.
6. **마일스톤** — M5 이후(`nativeFindChild`가 프로바이더 표면). `ROADMAP.md`
   백로그에 포인터만. **[2026-08-28 `/code-review`, `H-161`]** 단 `H-146` 루트
   예외를 폐기한 지금 **M5에 승인된 루트 부착 경로가 없다** — (a) `Claim`을 M5
   스코프로 당김 / (b) `Claim` 전까지 M5 한정 임시 예외 / (c) 루트 컨테이너용
   얇은 표면. **사용자 확정 (a)**(*"M5 스코프로 올라가도 될것으로 보임"*) — 헤더와
   `ROADMAP.md` M5 체크박스에 반영. §5-7(다중 스크립트)은 여전히 미결.
7. **[2026-08-28 `/code-review`, `H-161`] 여러 스크립트/여러 quad가 같은 루트
   컨테이너를 쓰는 경우** — 위 "이중 claim error / 다중 quad UB / 부기 대상 자식
   전부 매핑"을 그대로 두면 `Shop.client.luau`와 `Inventory.client.luau`가 각각
   `Claim(PlayerGui, …)`하는 **가장 흔한 사례가 막힌다**. 이건 "전부 매핑" 계약이
   **루트 컨테이너**(부기 대상이 아닌 `PlayerGui`·`CoreGui`류 — 자식 순서가
   의미 없고 quad가 그 형제들을 관리하지 않는다)에는 안 맞는다는 신호다. 갈래:
   (a) `Claim`은 **부기를 갖는 노드**에만, 루트 컨테이너엔 "quad가 만든 자식
   하나를 붙이는" 별개 표면(부기 없음, 여러 스크립트 공존, 이름은 §5-5와 같이) /
   (b) `Claim`에 "이 노드의 다른 자식은 관리하지 않는다"(부분 매핑) 모드 — 단
   web처럼 물리 순서가 의미 있는 엔진에선 위험 / (c) 다중 claim을 허용하되 각
   claim이 자기가 매핑한 자식만 소유(UB 대신 정의) — 부기 충돌 없음이 조건.
   **권고 없음** — (a)는 `H-146`에서 기각한 `Mount(root, parent)`의 재개방과
   경계가 얇고, (b)(c)는 계약을 약화시킨다. 사용자 판단.
8. **매핑된 정적 자식의 `Parent` 대입** — §2는 "부기만, `.Parent =`는 안 한다"인데
   `InstanceChildHandler`는 `v.Parent = inst`가 계약(`dispatch-core-plan.md`
   `H-134`). 같은 핸들러를 쓰면 이미 거기 있는 자식에 같은 값을 재대입(엔진
   no-op)하는 것뿐이라 별도 핸들러가 필요 없어 보인다 — 확인 문항(권고: 같은
   핸들러, 재대입 감수).

## 6. 반영 시 고칠 자리 (승격 때 체크리스트)

`archive/existing-instance-bind-rejected.md` 배너 / `base/bind-system-plan.md`
`H-142` 항목의 `H-146` 루트 bullet(폐기 → 이 문서 포인터) / `base/slot-plan.md`
"동적 자식은 반드시" 절 각주 / `ROADMAP.md` M5 `Property.luau` 전용 문구 삭제 +
백로그 항목 / `research/documentation-content-map.md` / `question.md`.
