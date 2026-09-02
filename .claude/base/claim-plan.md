# 이미 있는 트리를 quad가 소유하기 — `Claim` + `D.Mapper`

> **[2026-08-28 신설·같은 날 확정 — `research/`에서 승격(옛 파일명 `existing-mount-plan`)]**
> 10라운드 `H-148`(`Parent` 거부 문구)을 논의하다 **루트 마운트 표면의 부재**가
> 드러나 사용자 발의로 만든 문서. 방향(§1~§4)은 `session/2026-08-28-01-handtrace-round10-resolution.md`에서,
> 갈래(§7)는 `session/2026-08-28-02-claim-promotion.md`에서 사용자가 확정했다.
> **M5 스코프**(`H-161` — 프로바이더 op `nativeFindChild`가 필요하니 프로바이더
> 마일스톤이 자연스러운 자리). M2 착수 게이트 아님. 구현 체크리스트는 §9.
>
> **`archive/existing-instance-bind-rejected.md`(2026-08-14 기각)와의 관계**:
> 그 기각은 *"이미 있는 Instance에 나중에 새 props를 다시 바인드"*였고 사유는
> "quad가 만들지 않은 트리의 자식 구성을 바깥이 밀고 당기면 `setLength`/
> `setOffsetSource` 부기가 깨진다"였다. 이 문서는 그 반대 방향 — **한 번
> claim하면 quad가 소유하고 직계 자식은 사용자가 전부 매핑한다**는 계약이라
> claim 뒤엔 quad가 만든 트리와 같은 불변식이 성립한다. **재바인드는 여전히
> 미지원**(claim은 1회, 디스크립터는 `Processed`로 소진).

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
… 이것도 똑같이 Quad 가 소유하게 될 요소가 되는거지."* — quad 밖에서 온
트리(PlayerGui, `Clone()` 사본, Studio에서 만든 GUI)를 **quad 소유**로 만드는
표면이다. 루트의 `.Parent`를 밖에서 만지는 일은 이것과 별개로 **계속 허용**된다
(§5 — 처음엔 "parent 를 설정할 문제 자체가 사라져"로 봤으나 §7-7에서 좁혀 복원).

## 2. 모양

```lua
local M = D.Mapper                       -- 정의는 D 안에 산다. 유저가 필요하면 꺼낸다
local cloned = Claim(template:Clone(), M.Frame(M.Root) {   -- 루트는 이름 대신 센티널
    M.TextLabel "Title" { Text = title },
    M.Frame "List" {
        Slot { … },                      -- 기존 부모 아래 Slot — 이제 가능
    },
    BackgroundColor3 = color,            -- props는 New와 같은 derive 테이블
}) -- -> cloned (claim한 루트 Instance — 타입은 넣은 inst의 타입 그대로)
```

- **`D.Mapper.<Class>(key) { … }`는 Instance를 만들지 않고 디스크립터만
  만든다**(브랜드 `Mapper`류) — derive 테이블 + 매칭 키. `D.Frame`에 직접 얹지
  않는다(사용자: *"D.Frame 에 바로 바인딩은 위험한듯. 의미가 겹쳐버려"*).
  `key`는 자식이면 이름(`string`), 루트면 센티널 `D.Mapper.Root`(§7-1).
- **props 타입은 `D.<Class>`와 공유한다.** 생성기가 클래스마다 `type FrameParam
  = { … }`를 찍고 `D.Frame`과 `D.Mapper.Frame`이 그 하나를 쓴다 — 리턴만 다르다
  (`Frame` vs `MapperDescriptor` — 산문의 옛 제네릭 표기는 정정: 타입은 비제네릭, §7-12 코드 블록이 정본). 사용자: *"D.Frame 의 함수의 부분들을
  type FrameParam = {} 형태로 빼서 공유되는 타입 부분으로 D.Mapper.Frame 도
  구성되고, 리턴부분만 다르게"*. `base/bind-system-plan.md`의 `D.Frame =
  New<<Frame>> "Frame" :: ((…) -> Frame)` 캐스트가 인라인 타입 대신 이 이름을
  쓰게 되는 것뿐이고, `D`가 전량 생성기 산출물이라 손으로 쓸 곳은 없다.

  ```luau
  type FrameParam<E> = { [number]: E, … }                    -- §7-12: 원소 타입이 파라미터
  D.Frame        :: (FrameParam<NewChild>) -> Frame            -- NewChild = 기존 children 유니언
  D.Mapper.Frame :: (key: string | MapperRoot) -> (FrameParam<NewChild | MapperDescriptor>) -> MapperDescriptor
  Claim          :: <T>(inst: T, desc: MapperDescriptor) -> T   -- T는 inst에서 그대로
  ```

  **⚠️ [2026-08-28 `/code-review`] 배열 파트는 그대로 공유할 수 없다** — `New`의
  children 배열엔 `MapperDescriptor`가 올 수 없고(오면 런타임 "매치 핸들러 없음"),
  매퍼의 배열엔 와야 한다(§2 예시의 `M.TextLabel "Title" {…}`). 사용자 인용은
  **필드 파트의 타입 공유**를 승인한 것이고 배열 파트를 어떻게 가를지는 정하지
  않았다 → **[같은 날 확정, §7-12] 원소 타입을 파라미터로**: `type FrameParam<E> =
  { [number]: E, …필드 }`, `D.Frame`은 `E` = 기존 children 원소 유니언(Instance·Slot·
  State…), `D.Mapper.Frame`은 거기에 `| MapperDescriptor`. `base/bind-system-plan.md`의
  `D` 생성기 절엔 포인터만 — 생성기 구현(`ROADMAP.md` M5 `D/init.luau`)이 이 문서를 본다.

- **`Claim(inst, descriptor) -> inst`가 최상위이고 타입 인자를 받지 않는다.**
  사용자: *"Claim 자체는 타입을 받는건 말이 안되어보임. New 와는 완전 다른
  계열이라서: New 는 후행 입력에 대한 타입을 선언시키는 D 계열이지만, Claim 은
  공유 부분이고 … 엔진 요소를 알 수 없어"*. 반환 타입은 **넣은 `inst`의 타입
  그대로**(`<T>(inst: T, …) -> T`) — 처음엔 "디스크립터가 클래스 타입을 실어 `inst`와
  대조·반환을 좁힌다"(에이전트 제안)로 적었으나 **[2026-08-28 `/code-review`]**
  실사용 `inst`는 `template:Clone()`·`PlayerGui` 둘 다 `Instance` 타입이라 그 추론은
  성립하지 않는다(좁히려면 사용자가 `::` 캐스트 — `New<<X>>`의 "범위 밖은 `any`"와
  같은 취급). 디스크립터 클래스 ↔ `inst` 클래스 대조는 **debug 검사**(§3)의 몫.
  `inst`는 quad 밖에서 온 것. 이 호출로 `inst`와
  매핑된 하위 전부가 **quad 소유**가 된다 — `New`가 만든 것과 같은 gcconn/gchold·부기
  (그 (0) 셋업은 아래 `nativeClaim` — §7-9).
- **디스크립터는 1회용** — `PreRef`의 `_fired`처럼 **디스크립터 객체에 소진
  플래그**를 세우고 재사용이면 error(**[2026-09-02 정정, 단위 ④]** 여기
  `error(…, 2)`라 적혀 있었으나 실 구현은 §7-9/-10 정정과 같은 이유로
  `errorBefore(SURFACE)`다 — 재사용 검사가 DFS 재귀 안이라 더더욱). **[2026-08-28 `/code-review` 정정]**
  `PreRef` 관용구의 다른 절반(배열 슬롯을 `ProcessedPreRef` 센티널로 교체)은
  **가져오지 않는다** — 매핑 자식의 배열 슬롯은 §4대로 **해석된 Instance로 교체**돼야
  `InstanceChildHandler`에 닿고, 루트 디스크립터는 배열에 있지도 않다. 사용자
  테이블을 in-place로 바꿀지 새 테이블을 만들지(그러면 `ProcessedModifier` 자리와
  인덱스가 `New`와 달라진다)와 Modifier 필드 안에 숨은 디스크립터를 DFS가 보는지는
  ~~구현 시 정할 것~~ **[2026-09-02 `H-303` 재량 확정 — 뒤집기 가능]**
  in-place 교체 / DFS는 Modifier 필드를 안 봄(M7 flatten 통합의 몫) —
  전체 재량 목록은 round14 `H-303` 행과 `quad-base/src/Claim.luau` 헤더가 소스. **같은 `inst`를 두 번 `Claim`하는 것도 error**(§7-7) —
  판정은 위 `nativeClaim` 항목(§7-10).
- **⭐ [2026-08-28 후속, §7-9] 소유는 프로바이더 주입 op `nativeClaim(inst)`** —
  `lifecycle-pattern.md` (0)의 gcconn/gchold 셋업(클로저가 `gchold`와 `inst`를 캡처해
  userdata 동일성을 고정하고 `InstData:SetWeak`)이 **이 op 안에만** 산다. `New`의
  ②단계도 인라인이 아니라 같은 op를 부른다(`base/bind-system-plan.md`). `Claim`은
  DFS로 해석한 inst마다(루트 포함) `drive` **앞에** `nativeClaim`을 부른다 — ②가
  ③④보다 앞인 것과 같은 이유(그 뒤부터 `inst`를 키로 쓰는 `Relate`가 생긴다).
  **이미 quad 데이터가 있는 inst**(`InstData:GetWeak(inst, "gchold") ~= nil` — 앞서
  claim됐거나 `New`가 만든 것)면 error — 이것이 "같은 `inst` 이중 claim
  error"의 전부이고 별도 레지스트리는 없다(§7-10). **[2026-09-02 정정, M5
  단위 ① 탐사자]** 여기 `error(…, 2)`라 적혀 있었으나 실 구현은
  **`errorBefore(SURFACE)`**다(`quad-roblox/src/LifetimeHandle.luau`) —
  `H-272` 관례의 확장: 리터럴 level 2는 `Claim`의 DFS 경유 호출에서 quad
  내부를 blame하고, 최외곽 표면 걷기면 직접 호출·`Claim` 경유 양쪽에서
  사용자 줄에 닿는다.
- **매칭은 프로바이더 주입 op** `nativeFindChild(inst, key)`(가칭) — Roblox는
  `Name`, web은 id/selector. **quad-base가 순회·부기 전반을 구현하고
  프로바이더는 이 핸들만 낸다**(사용자: *"quad-base 에서 전반을 구현해주고
  필요 핸들을 구현하라고 남기는건 괜찮은 생각"*). 주입 op 전체 목록의 단일
  소스는 `base/architecture.md`의 소스 트리(`EngineOps.luau` 줄) — 거기 추가한다.
- **여러 quad 인스턴스가 한 트리를 claim — UB**(사용자 확정). 같은 quad의 이중
  claim은 위처럼 error.
- **`H-142`(props에 `Parent` 금지)는 그대로.** 매퍼 디스크립터의 props도 `New`와
  같은 derive 테이블이라 같은 금지를 받는다.

## 3. 계약 — 자식은 전부 매핑한다

사용자: *"모든 개체를 유저가 직접 네임을 매핑해서 derive 테이블 안에서 내부
요소를 전부 매핑해준다를 계약으로 잡으면 문제가 없다고 생각해."*

- **부기 대상(그려지는 자식)은 전부 매핑해야 한다.** 안 된 자식이 남으면
  `nativeInsert`의 삽입 위치(web은 곧 DOM 순서)와 Length/Offset이 어긋난다.
- **디스크립터 배열 순서가 정본이다**(§7-2 (a)). 기존 트리의 실제 순서가
  다르면 일치는 사용자 책임 — quad는 `nativeMove`로 맞추지 않는다. Roblox는
  물리 순서가 의미 없어 비용 0, web에선 어긋나면 UB(debug 검사 대상).
- **숏핸드(`UICorner` 등 `UI*`)는 부기 대상이 아니다** — 그려지지 않고 Roblox에만
  있으며 단순 `Parent` 대입 요소. 사용자 확정: *"숏핸드를 quad 에서만 직접
  쓰거나 … 아니면 실제 UI 객체를 바인딩해서 숏핸드를 안 쓰거나"* — 둘 중 하나:
  (i) 템플릿엔 `UI*`가 없고 quad가 숏핸드 키로 만든다, (ii) 템플릿의 `UI*`를
  `M.UICorner "UICorner" {…}`처럼 **실제 객체로 매핑**하고 그 부모에 숏핸드
  키는 안 쓴다. 섞으면(템플릿에 `UICorner`가 있는데 숏핸드 키도 씀) 둘이
  생기는 것은 UB.
- **이름 중복·부재는 UB**(사용자 확정). **debug 모드**에선 `seen` 맵으로 중복을
  잡아 error(사용자 제안). 검사 범위를 어디까지 넓힐지(부재·클래스 불일치·
  미매핑 부기 대상·물리 순서 불일치·이중 claim)는 **디버깅 도구 설계의 몫**으로
  옮겼다(§7-4 → `research/debug-tooling-plan.md`의 "열린 질문" 절) — 여기선
  "debug 검사가 있다"까지만 확정.

## 4. 처리 순서 — `drive` 위의 한 겹

**`New`와 반대 방향에서 시작한다.** `New`는 안쪽 생성자가 먼저 평가돼 자연히
bottom-up이지만, 매퍼의 안쪽은 평가 시점에 자기 Instance를 모른다(부모가
아직 없다). 그래서 `Claim`이 **DFS로 내려가며 이름으로 해석 → 자식부터
`drive` → 올라오며 부모 `drive`**. 사용자: *"핸들러가 된다면 위험해. 일반
생성과 다르게, 상위 부터 처리하거든 … DFS 로써, 내려가는게 먼저고 그 뒤에서
derive 를 걸어야해. 이건 derive 에선 구현하지 않고, 그 위의 무언가로써
구현되어야할듯."* — `drive`/핸들러 층은 안 바뀌고 그 **위의 한 겹**이다.

- 매핑된 정적 자식은 부모의 derive 테이블에서 **평범한 정적 자식**(배열 자리의
  Instance)으로 보인다 — 해석이 끝난 뒤엔 `InstanceChildHandler`가 그대로 받아
  `setOffsetSource(inst, k, None)` → `v.Parent = inst` → `setLength(inst, k, 1, inst)`
  (`base/dispatch-core-plan.md`의 `H-134` 문단). **별도 핸들러는 없다**(§7-8) —
  이미 거기 있는 자식에 같은 `Parent`를 재대입하는 것은 엔진 no-op이고, `H-154`
  문단이 이미 *"`Parent = inst`(같은 값, 엔진 no-op)"*으로 전제한 사실.
- Slot은 평소처럼 `native*`로 기존 부모 아래 끼운다.
- **⚠️ [2026-08-28 `/code-review`] `PreRef`/`OnCreated`의 불변식이 약해진다.**
  `drive`를 그대로 쓰므로 claim된 inst에서도 `PreRef`가 먼저 발화하지만, `New`가
  보장하던 *"아직 자식도 프로퍼티도 없다"*(`base/bind-system-plan.md`)·*"이 인스턴스에
  뭐가 됐든 일어나기 전"*(`base/lifecycle-hooks-plan.md`)은 **거짓**이다 — inst는 이미
  템플릿의 자식·프로퍼티를 갖고 있고, 매핑 자식의 `ChildAdded`는 아예 안 뜬다.
  `Claim`에서 `PreRef`가 뜻하는 것은 "quad가 이 inst에 무언가 하기 전"뿐. §4가
  특수 분기를 금지하므로 지키려 하지 않고 **문서화 대상**(§9)으로 둔다.

## 5. 루트의 `Parent`는 부기 밖이다 — 밖에서 `.Parent =` 허용

**`H-146`의 루트 예외는 좁혀서 복원된다**(§7-7). 사용자: *"밖에서 .Parent
설정하는건 괜찮아. 루트도 quad 소유이긴 한데, .Parent 를 밖에서 설정하는건
괜찮음. 정확히는 ScreenGUI 가 이미 존재해도 똑같음."*

- **quad 트리의 루트**(`New`로 만든 것이든 `Claim`한 것이든)의 `.Parent`는
  어느 Length/형제 순서 부기에도 속하지 않는다 — 그래서 사용자가 밖에서
  `root.Parent = PlayerGui`로 붙이고 떼는 것은 **허용**이고, `H-146`의 사용자
  논거(*"부기가 없는 객체에 Quad 의 객체를 주입하는 성격의 API 는 아니거든 …
  해당 부분은 각 엔진을 사용하는 최종 사용자의 몫"*)가 그대로 성립한다.
  `Mount(root, parent)`류 표면은 여전히 만들지 않는다.
- **금지는 그대로 "quad가 소유한 부모 *아래*"다** — Slot 요소·정적 자식 자리에
  밖에서 끼우거나 빼는 것(`base/slot-plan.md`의 "동적 자식은 반드시" 절). 루트의
  부모는 quad가 소유하지 않은 것이라 이 금지 밖이다.
- **props의 `Parent`는 여전히 금지**(`H-142`) — 붙이는 건 props가 아니라 밖의 한 줄.
  거부 배선의 에러 문구는 일반 매치 실패 그대로(`H-148`), 오해는 사용자 문서가 맡는다.
- **여러 스크립트가 한 `PlayerGui`를 쓰는 흔한 경우는 이걸로 닫힌다** — 각
  스크립트가 자기 `ScreenGui`를 `New`(또는 `Claim`)하고 `.Parent = PlayerGui`
  (PlayerGui는 붙이는 자리일 뿐 claim 대상이 아니다 — §7-11).
  **`PlayerGui` 자체는 claim 대상이 아니다**(§7-11 — 공동 소유 컨테이너). 여러
  스크립트가 한 `Slot`을 공유해야 하면 **`ScreenGui` 하나를 만들거나 claim하고 그 안에
  Slot을 만들어 반환하는 중간 모듈**을 둔다(사용자: *"정확히는 두번 Claim 불가하다는
  의미. 필요하다면 Slot 을 안에 만들고 리턴하는 중간 모듈을 만들어야함"* — 그 모듈의
  루트가 `ScreenGui`인 것이 §7-11의 따름).

## 6. 이 문서가 여는 것

- **루트**: `Claim(existingScreenGui, M.ScreenGui(M.Root) { Slot {…} })` — Studio에서
  만들어 둔 `ScreenGui`(또는 `SurfaceGui`·`BillboardGui`)를 quad 소유 부모로 삼아 그
  아래 Slot을 둔다. **`PlayerGui`/`CoreGui`류 공동 소유 컨테이너는 claim 대상이
  아니다**(§7-11 — 엔진이 `StarterGui`를 리스폰마다 복제해 넣고 여러 스크립트가
  나눠 쓰는 자리라 "소유"가 성립하지 않는다). 그런 컨테이너엔 §5의 `.Parent =`로
  붙일 뿐이다. 처음 스케치의 `Claim(PlayerGui, M.PlayerGui(M.Root) {…})`는 **폐기**.
- **템플릿 대량 생성**: `template:Clone()` → `Claim` — 각 사본이 독립 소유.
  Claim이 Instance를 돌려주므로 **Slot 요소로도 그대로 쓸 수 있다**(요소는
  `inst`) — "요소가 너무 많은 경우"의 답.
- **비루트 사용**: `New "Frame" { Claim(clone, …) }` — 반환된 `inst`가 정적
  자식으로 들어가면 `InstanceChildHandler`가 `Parent =`와 부기를 한다. 평가
  순서상 `Claim`이 먼저 끝나므로 bottom-up이 유지된다.
- **claim된 부모 안의 `New` 자식**: `M.Frame "List" { New "Frame" {…} }` — 매핑
  (이미 있음)과 생성(새로 붙임)이 한 배열에 섞여도 된다(§7-3). `New` 자식은
  디스크립터 테이블이 평가될 때 이미 다 구워져(자기 서브트리 `drive` 완료) 있고,
  `Claim`이 올라오며 부모를 `drive`할 때 정적 자식으로 부기된다 —
  `New "Frame" { New "Frame" {} }`과 같은 모양. **위치는 프로바이더의 몫**:
  Roblox는 `.Parent =`라 순서가 무의미하고, **web은 정적 자식 핸들러가
  `nativeInsert(offset)`을 써야 디스크립터 순서 자리에 놓인다** — 안 그러면 맨 뒤
  (그리고 **이미 붙어 있는 매핑 자식**엔 그 핸들러가 `nativeInsert`를 다시 부르면
  안 된다 — 같은 부모 안 재삽입은 이동이라 §3 "quad는 `nativeMove`로 맞추지 않는다"와
  어긋난다; web 정적 자식 핸들러는 "이미 그 부모의 자식이면 건너뜀"을 가져야 한다)
  (사용자: *"Add 가 위치를 진짜 실어서 보내지 않으면 맨 뒤에 놓인다는게 문제일
  뿐"*). §3 "디스크립터 순서가 정본"의 따름정리이고 `Claim`의 결정이 아니다.

## 7. 결정 기록 — `research/` 시절 §5 갈래의 답 (2026-08-28)

당시 갈래 목록(a/b/c 선택지 원문)은 `session/2026-08-28-02-claim-promotion.md`
끝의 "옛 §5 원문" 절에 전문 보존. 번호는 그 research 문서의 §5 번호 그대로.

1. **루트 디스크립터의 키 — (a) 센티널.** 갈래 (b)("클래스 없는 맨 테이블 +
   `Claim<<"Frame">>`", 에이전트 권고)는 **기각** — 사용자: *"권고 b는 문제가
   생겨. 루트에 대해서 {} 안의 타입체크와 타입 자동완성이 전혀 안 먹음."* 그리고
   `Claim`이 타입 인자를 받는 것 자체가 `New` 계열과 어울리지 않는다(§2 인용).
   (c)("이름을 받되 무시")도 안 씀. 센티널은 사용자 스케치 `MapperRoot = {}
   Mapper.Frame (MapperRoot) {}` 그대로이고, **놓는 자리 `D.Mapper.Root`는
   에이전트 제안**(매퍼 옆에 두면 `M.Frame(M.Root)`로 읽힌다) — 이름만 바뀔 수
   있는 항목. 자식 디스크립터에 센티널을 주는 것(`M.Frame(M.Root)`가 루트가
   아닌 자리에)은 debug 검사 후보 — **[2026-09-02 단위 ④ 탐사자, 대칭 등재]**
   역방향(루트 자리에 문자열 키 — 키를 읽지 않아 조용히 통과, 행동상 기각된
   (c)와 같아짐)도 같은 debug 검사 후보다. 런타임 가드는 안 둔다(§3 원칙).
2. **물리 순서 — (a) 디스크립터 순서가 정본, 일치는 사용자 책임.** 사용자:
   *"나는 처음에 A 를 생각했어. 권고 그대로 가줘."* (b)(`nativeMove`로 quad가
   맞춤)는 기각.
3. **claim된 부모 안의 `New` 자식 — 허용.** 사용자: *"새로 붙임 자체는 한 배열에
   섞이는게 문제는 없어보여. 그 경우에서도 순차 마운트 Add 는 작동할것이거든."*
   지적한 순서·위치 문제는 §6 마지막 항목(프로바이더 요구사항)으로.
4. **debug 검사의 범위 — 여기서 정하지 않고 `research/debug-tooling-plan.md`로
   이동.** 사용자: *"디버깅 도구 만들 때 고려해야할 점으로 옮겨져야해. 부분 부분
   디버깅 가능성을 아직 다 논한게 없어서 지금 그림으로 보면 작은 그림을 먼저
   그리는거라서, 미결상황으로, 위치 이동이 필요함"*. 이 문서엔 "debug 검사가
   있다"(§3)만 남는다.
5. **표면 이름 — `Claim` + `D.Mapper`.** 사용자: *"표면 이름은 Claim 이 가장
   마음에 들어. D.Mapper 가 이미 있는걸 매핑해서 내가 가진다는 의미적으로 가장
   맞고."* `Mount`/`Adopt`/`D.Existing` 기각.
6. **마일스톤 — M5**(`H-161`, 헤더).
7. **여러 스크립트가 한 `PlayerGui` — (α) `Claim`은 1회·전체 소유, 루트의
   `.Parent =`는 밖에서 허용.** 문항 원문은 "여러 스크립트/여러 quad"를 나란히
   놓았지만 실제 흔한 경우는 **한 quad·여러 스크립트**(같은 `quad` 모듈을
   require — 다중 quad UB가 아니라 이중 claim error에 걸린다)라, 그 사례를 막는 게
   진짜 문제였다. 갈래 (a)(루트 컨테이너용
   별도 표면 — `H-146` 인용문이 정확히 반대한 것) / (b)(부분 매핑 모드 — web에서
   offset이 남의 자식을 못 봐 `Claim`의 의미가 엔진 의존이 됨) / (c)(다중 claim,
   각자 자기 자식만 소유 — (b)와 같은 약화) 전부 기각. 확정은 §5 — 사용자 원문
   그대로 *"정확히는 두번 Claim 불가하다는 의미. 필요하다면 Slot 을 안에 만들고
   리턴하는 중간 모듈을 만들어야함. 밖에서 .Parent 설정하는건 괜찮아. 루트도
   quad 소유이긴 한데, .Parent 를 밖에서 설정하는건 괜찮음. 정확히는 ScreenGUI 가
   이미 존재해도 똑같음."* 마지막 문장이 `Claim`한 루트에도 같은 허용을 준다 —
   루트의 `Parent`는 만든 방법과 무관하게 부기 밖.
8. **매핑된 정적 자식의 `Parent` 대입 — 같은 핸들러, 재대입 감수.** 사용자:
   *"5-8 확인완료."* 근거는 §4.

**[2026-08-28 후속 — 승격 뒤 `/code-review high`가 낸 문항 넷(옛 §10 A~D)의 답]**

9. **gcconn/gchold 셋업 자리 — 프로바이더 op `nativeClaim(inst)`, (0) 경로는 거기에만.**
   사용자: *"nativeClaim 을 만들고 gchold/gcconn 경로를 여기에 전부 두면 되지 않을까
   생각중."* "전부"이므로 `New` ②단계의 인라인 코드도 이 op 호출로 바뀐다(에이전트
   읽기 — `New`가 다른 경로를 따로 가지면 "전부"가 아니다). 리뷰 갈래 (b) `Claim`
   본체를 프로바이더로 / (c) (0)을 quad-base로는 안 씀. 이름 `nativeAdopt`(리뷰 가칭)
   폐기.
10. **이중 claim — 레지스트리 없음, "이미 quad 데이터가 있는 inst"면 error.** 사용자:
    *"정확히는, claim 은 slot 이랑 무관하지 않아? 이중 claim 자체가 무슨 상황이야."*
    — 리뷰가 세운 `elementOwner`(Slot 소유권) 충돌은 **문항 자체가 틀린 것**: claim은
    Slot 요소 소유권과 다른 축이다. 이중 claim이 실제로 뜻하는 상황은 둘 — 같은
    inst를 `Claim`에 두 번 넣는 것, 그리고 `New`가 만든(이미 quad 소유인) inst를
    claim하는 것. 둘 다 9번의 셋업이 이미 있다는 사실 하나로 판정된다(§2).
11. **`PlayerGui`는 claim 대상이 아니다 — 공동 소유 컨테이너.** 사용자: *"애초에
    PlayerGui 자체를 Own 한다는게 좀 잘못되었어. 공동 소유 가능 객체인데 그러는거지.
    ScreenGui/SurfaceGui 등으로 생각해야지."* own-all 계약(§3)은 손대지 않고 **대상
    정의**가 답이다: claim은 배타 소유가 성립하는 요소(`ScreenGui`·`SurfaceGui`·
    `BillboardGui`·`Frame`류·`Clone()` 사본)에만. 리뷰 갈래 (a) "UB로 명문화"는
    계약이 아니라 대상 밖이라는 뜻으로 흡수, (b) 부분 매핑은 §7-7대로 기각. 매퍼
    생성기 범위에 컨테이너를 넣을 일도 없다(`D`와 같은 범위).
12. **`type <Class>Param`의 배열 파트 — 원소 타입을 파라미터로.** 사용자: *"내가
    생각한게 원소를 파라미터로 받는거였어. 거기에 Instance 또는 Instance|MapperDescriptor
    가 오는거지"*. `FrameParam<E>` — `D.Frame`은 `E` = 기존 children 원소 유니언,
    `D.Mapper.Frame`은 `E` = 그것 `| MapperDescriptor`(§2). 실제 Luau에서 도는지는
    `luau-analyze` 스파이크로(§9). **[2026-09-02]** 그 스파이크는
    `luau-test/done/28-type-class-param-shared-generic.luau`로 통과했다
    (기대 음성 3건만 — 상태는 `STATUS.md`).
13. **[2026-09-02, round14 `H-293` — 사용자 기각·UB 확정] 이미 Destroy된
    inst를 claim(직접 `nativeClaim` 포함)하는 것은 UB다 — 가드를 만들지
    않는다.** 실기기 실측으로 증상은 확정돼 있다(Destroy된 inst에 새
    Connect가 성공하고 `Connected`가 영원히 true — 영구 발화 가능 판정 +
    절단면 없는 캡처 누수). 그래도 가드가 없는 이유(사용자): (1) *"​:Clone()
    을 하게 된다면 기본적으로 Parent 가 없는 상태인데, 이것을 Claim 할 수
    없다면, 처음부터 어딘가 Parent 를 넣어 실체화 해야하게 된다"* — 트리
    소속 검사류는 정당한 parentless claim을 막는 부작용이 더 크고, (2)
    *"인스턴스의 생성과 죽음 까지 quad 는 관리하고 소유하게 된다는 개념"*
    상 Destroy된 객체 투입 자체가 의도된 입력이 아니며, (3) *"방어하지
    못할 부분을 방어하려고 애매한 방법을 택할 이유가 없다"*(실물 Roblox엔
    깨끗한 destroyed 술어가 없다 — 후보 검출식은 실측으로 기각됨). 즉시
    error 주 방어선 원칙의 경계 사례 — **방어는 방어할 수 있을 때 제공**.
    문서화 대상 등재는 `research/documentation-content-map.md` §4.

## 8. 검토 후 안 만들기로 한 것

- `Claim<<"Frame">>` 타입 인자 / 루트를 맨 테이블로(§7-1).
- 루트 컨테이너용 별도 얇은 표면, `Claim`의 부분 매핑 모드, 다중 claim(§7-7).
- claim 시 `nativeMove`로 물리 순서를 디스크립터에 맞추기(§7-2).
- 매핑된 자식 전용 핸들러(§7-8).
- `Mount(root, parent)`류 표면(`H-146`, §5).
- 이미 있는 Instance에 나중에 props를 재바인드(`archive/existing-instance-bind-rejected.md`,
  헤더).
- **[2026-08-28 후속]** 이중 claim용 별도 레지스트리·`elementOwner` 기록(§7-10) /
  `nativeAdopt`라는 이름, `Claim` 본체를 프로바이더에 두기, (0) 셋업을 quad-base로
  옮기기(§7-9) / `PlayerGui`·`CoreGui`류 공동 소유 컨테이너 claim, 매퍼 생성 범위에
  컨테이너 추가(§7-11) / 필드 파트만 빼고 배열은 각자 두는 타입 둘(§7-12).

## 9. 구현 체크리스트 (M5) · 문서화 대상

- `D.Mapper.<Class>` 생성기 산출 + `type <Class>Param<E>`(사용자 확정, §7-12 — `E`
  파라미터가 실제 Luau에서 `D.Frame`/`D.Mapper.Frame` 둘을 통과시키는지 `luau-analyze`
  스파이크, `luau-test/STATUS.md`에 등록) + 루트 센티널(사용자 확정 — 놓는 자리
  `D.Mapper.Root`는 에이전트 제안) + 디스크립터 브랜드(`MapperDescriptor`는 가칭 —
  `Brand` 인스턴스 브랜드로 만든다는 것은 `base/brand-plan.md`의 일반 규칙이지 새 결정
  아님).
- `Claim(inst, desc) -> inst` — DFS 해석 → 해석한 inst마다 `nativeClaim` → bottom-up
  `drive`, 소진 플래그(§2), 이중 claim은 `nativeClaim` 앞의 `InstData` 검사(§7-10).
  ~~구현 시 정할 것~~ **[2026-09-02 `H-303` 재량 확정 — 뒤집기 가능, round14가 소스]**: 사용자 테이블 in-place 교체 vs 새 테이블(→ in-place), Modifier 안의
  디스크립터 처리, 패키지 안 정의 파일 위치(`quad-base/src/Claim.luau` 가칭 —
  `base/architecture.md` 소스 트리에 반영은 M5 착수 때).
- 프로바이더 op **`nativeClaim(inst)`**(§7-9) — `lifecycle-pattern.md` (0)의 코드가 본체,
  `New` ②단계가 같은 op를 부르도록 `base/bind-system-plan.md` 의사코드 주석 갱신됨.
  `base/architecture.md` 주입 op 목록에 추가됨(조합 폴백 예외 — 셋업이라 조합 불가).
- 프로바이더 op `nativeFindChild(inst, key)`(이름 가칭) — `base/architecture.md` 주입 op
  목록에 추가됨(quad-roblox는 `inst:FindFirstChild(key)`). "`native*` 조합 폴백의
  예외 — 조회라 조합으로 만들 수 없어 `isInst`처럼 미주입이면 명확한 error"는
  **에이전트 분류**(사용자 발언은 "필요 핸들을 구현하라고 남기는 건 괜찮다"까지).
- debug 모드 `seen` 맵(범위는 `research/debug-tooling-plan.md`가 소스).
- `ROADMAP.md` M5 체크박스가 진행의 소스.
- **문서화 대상**(`research/documentation-content-map.md` §4): "전부 매핑" 계약과
  숏핸드 (i)/(ii) 규칙, 루트 `.Parent =`는 밖에서 / 그 아래는 절대 직접 하지 말 것,
  여러 스크립트의 PlayerGui는 각자 `ScreenGui` + 중간 모듈 패턴, claim된 inst에선
  `PreRef`/`OnCreated`가 "이미 있는 것 위에서" 뜬다는 것(§4).

## 10. [해소됨, 2026-08-28 같은 날] 승격 뒤 `/code-review high`가 낸 문항 넷

**전부 사용자가 같은 날 답해 §7의 9~12번으로 들어갔다** — A(gcconn/gchold 셋업 자리)
→ §7-9 `nativeClaim` / B(이중 claim 레지스트리) → §7-10 문항 자체가 틀림, 셋업 유무로
판정 / C(`PlayerGui` own-all) → §7-11 claim 대상이 아님 / D(`<Class>Param` 배열 파트)
→ §7-12 원소 타입 파라미터. 당시 갈래·권고 원문은 `session/2026-08-28-02-claim-promotion.md`
끝 절. 이 절 번호를 가리키던 바깥 문서들은 그 절로 가리키게 고쳤다.
