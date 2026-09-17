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
  D.Frame        :: (FrameParam<FrameElem>) -> Frame            -- FrameElem = NewChild | <OnChange 디스크립터 유니언>…
  D.Mapper.Frame :: (key: string | MapperRoot) -> (FrameParam<FrameMapperElem>) -> MapperDescriptor  -- = FrameElem | MapperDescriptor
  Claim          :: <T>(inst: T, desc: MapperDescriptor) -> T   -- T는 inst에서 그대로
  ```

  **[2026-09-03 표기 갱신]** 원소 유니언은 생성기가 클래스당 별칭
  `<Class>Elem`/`<Class>MapperElem`으로 찍고 타입과 런타임 캐스트가 같은 별칭을
  참조한다 — 별칭의 실제 구성(`NewChild` + 배열부 디스크립터 유니언 +
  그 `State`)은 `base/onchange-plan.md` "타이핑" 절 3번이 정본. 이 절의 요지
  ("`E`만 파라미터, 매퍼는 `| MapperDescriptor`")는 그대로다.

  **⚠️ [2026-08-28 `/code-review`] 배열 파트는 그대로 공유할 수 없다** — `New`의
  children 배열엔 `MapperDescriptor`가 올 수 없고(오면 런타임 "매치 핸들러 없음"),
  매퍼의 배열엔 와야 한다(§2 예시의 `M.TextLabel "Title" {…}`). 사용자 인용은
  **필드 파트의 타입 공유**를 승인한 것이고 배열 파트를 어떻게 가를지는 정하지
  않았다 → **[같은 날 확정, §7-12] 원소 타입을 파라미터로**: `type FrameParam<E> =
  { [number]: E, …필드 }`, `D.Frame`은 `E` = children 원소 유니언(생성 별칭 `<Class>Elem` — Instance·Slot·
  State…), `D.Mapper.Frame`은 거기에 `| MapperDescriptor`. `base/bind-system-plan.md`의
  `D` 생성기 절엔 포인터만 — 생성기 구현(`archive/v2-initial-implementation/roadmap.md` M5 `D/init.luau`)이 이 문서를 본다.

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
- **[2026-09-07 밤 `H-471`] 소진 표시(`_fired`)는 `nativeClaim` 성공 *뒤*에 선다** — 클레임이 던지면(이미
  claim된 root 등) 디스크립터는 그대로 남아 재시도가 진짜 원인을 보고한다(`H-425`의 원칙과 같다).
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
  in-place 교체 / DFS는 Modifier 필드를 안 봄(**[2026-09-04]** M7 단위 ②로 닫힘 — flatten은 `Dispatch.drive`가 소유해 Claim 경로도 같은 호출 자리를 지난다, round17 Q4 (a)) —
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
- **매칭은 프로바이더 주입 op** `nativeFindChild(inst, key, className?)`(**[2026-09-17]** 셋째 인자는 17번) — Roblox는
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
- **이름 중복은 UB**(사용자 확정; **부재는 [2026-09-16 `H-520`] fail-fast — 아래 15번**). **debug 모드**에선 `seen` 맵으로 중복을
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
    가 오는거지"*. `FrameParam<E>` — `D.Frame`은 `E` = children 원소 유니언(생성 별칭
    `FrameElem`, **[2026-09-03]** 배열부 `OnChange` 디스크립터가 합류 —
    `onchange-plan.md`), `D.Mapper.Frame`은 `E` = 그것 `| MapperDescriptor`
    (`FrameMapperElem`, §2). 실제 Luau에서 도는지는
    `luau-analyze` 스파이크로(§9). **[2026-09-02]** 그 스파이크는
    `luau-test/done/28-type-class-param-shared-generic.luau`로 통과했다
    (기대 음성 3건만 — 상태는 `STATUS.md`).
13. **[2026-09-07 회신 4차 Q20 — 사용자 확정]** 파괴된 quad Instance와 외부 Instance는 **가를 수 없다**(생성 직후·Clone 직후엔 Parent가 nil이라 game 조상 검사가 안 선다 — 전에 도입했다 철회). 그래서 `bindLifetime`의 미claim 메시지 하나가 둘을 함께 말한다(*"죽은것에 시도하거나 quad가 만진게 아니다"*), 파괴 요소 claim도 막지 않는다(아래 `H-293` UB 그대로). **[2026-09-02, round14 `H-293` — 사용자 기각·UB 확정] 이미 Destroy된
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
    문서화 대상 등재는 `archive/surveys/2026-08-06-documentation-content-map.md` §4.

14. **[2026-09-16 사용자 결정 — `question.md` §2 Slot foreign Instance]** **Slot은 미claim 요소를 받지 않는다** — 백엔드 계약 op `isClaimed(inst)`(quad-roblox: `nativeClaim`이 남긴 gchold 유무 **+ gcconn `.Connected`** — 이중 claim 판정과 같은 검사에 "파괴 즉시 미claim"을 더한 것, `lifecycle-pattern.md` 끝 절 `H-548`(2026-09-17); mock: lazy claim이라 mock 인스턴스면 참)를 `Slot/Elements.luau`의 요소 게이트가 부르고 거짓이면 `Slot: this element is not claimed by quad …`로 거부한다(Add·생성자·Replace·Extract·Splice는 배치 선행 패스에서 — `State`에 담긴 요소도 현재값으로; `:List`/`:Single`의 `updateFn` 반환값은 `H6-21`대로 사이클 안에서 항목마다, 배치 선행 패스가 아니다). **같은 날 code-review 뒤 사용자 결정 — 정적 자식 자리도 대칭**: `Handlers/InstanceChild.luau`의 `process`가 부기 전에 같은 술어로 거부한다(`InstanceChild: this Instance is not claimed by quad …`, `errorBefore`라 `D.<Class>` 줄 blame). `Add` 때 자동 claim(옛 메인 권고 (a))은 기각 — 사용자: *"명시적으로 claim 안 한게 다른 경로로 claim 될 수 있다는거고, 마법 아님?"* 배경 사실: `rawAdd`는 `elementOwner` 부기 + `_elements` 삽입 + 물리 op뿐이라 요소에 `bindLifetime`이 걸리지 않고(Slot의 `bindLifetime`은 전부 자기 옵저버를 `physicalTarget`에 묶는 것), 옛 현행은 foreign 요소가 조용히 들어가 밖에서 Destroy되면 부기가 stale해졌다. 판정 술어를 확인한 사용자: *"gchold 같은게 있는 경우가 claim 된 판정처럼 되는거지?"* — 맞음. 원문 `session/2026-09-16-01-d-typefunction-measurement.md`.

15. **[2026-09-16 round10 `H-520`]** 매퍼 키 **부재**는 UB(§3)였지만 실제 증상이 `LifetimeHandle.luau:59: Relate:GetWeak: inst must not be nil`(leaf 메시지)이라 `H-418`/`H-442`/`H-504` 부류로 닫았다 — `Claim: no child matched key … under … (mapper …)`로 fail-fast. 이름 **중복**은 여전히 UB(`FindFirstChild` 승리). 클래스 불일치 검사는 round10 §4 문항.

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
  `base/architecture.md` 주입 op 목록에 추가됨. **[2026-09-08 정정]** 옛 "조합 폴백 예외" 분류는 소멸 — 2026-09-07 회신 4차(Q6)로 폴백 규칙 자체가 철회돼 `native*` 여섯 전부 필수·미주입이면 안내 스텁 에러다(`slot-plan.md`의 "기본 구현(조합 폴백)" 절 배너).
- 프로바이더 op `nativeFindChild(inst, key, className?)`(**[2026-09-17]** 셋째 인자는 17번) — `base/architecture.md` 주입 op
  목록에 추가됨(quad-roblox는 `inst:FindFirstChild(key)` 뒤 `IsA`). 옛 "`native*` 조합 폴백의
  예외 — 조회라 조합으로 만들 수 없어 `isInst`처럼 미주입이면 명확한 error"는
  **에이전트 분류**였고(사용자 발언은 "필요 핸들을 구현하라고 남기는 건 괜찮다"까지),
  **[2026-09-08 정정]** 폴백 규칙 철회(위 항목) 뒤엔 "예외"가 아니라 여섯과 같은 기본 규칙이다.
- debug 모드 `seen` 맵(범위는 `research/debug-tooling-plan.md`가 소스).
- `archive/v2-initial-implementation/roadmap.md` M5 체크박스가 진행의 소스.
- **문서화 대상**(`archive/surveys/2026-08-06-documentation-content-map.md` §4): "전부 매핑" 계약과
  숏핸드 (i)/(ii) 규칙, 루트 `.Parent =`는 밖에서 / 그 아래는 절대 직접 하지 말 것,
  여러 스크립트의 PlayerGui는 각자 `ScreenGui` + 중간 모듈 패턴, claim된 inst에선
  `PreRef`/`OnCreated`가 "이미 있는 것 위에서" 뜬다는 것(§4).

## 10. [해소됨, 2026-08-28 같은 날] 승격 뒤 `/code-review high`가 낸 문항 넷

**전부 사용자가 같은 날 답해 §7의 9~12번으로 들어갔다** — A(gcconn/gchold 셋업 자리)
→ §7-9 `nativeClaim` / B(이중 claim 레지스트리) → §7-10 문항 자체가 틀림, 셋업 유무로
판정 / C(`PlayerGui` own-all) → §7-11 claim 대상이 아님 / D(`<Class>Param` 배열 파트)
→ §7-12 원소 타입 파라미터. 당시 갈래·권고 원문은 `session/2026-08-28-02-claim-promotion.md`
끝 절. 이 절 번호를 가리키던 바깥 문서들은 그 절로 가리키게 고쳤다.
16. **[2026-09-17 사용자 결정 — round10 Q48 (a)] 정적 자식·숏핸드 관리 자식도 Slot과 같은 `elementOwner` 레지스트리에 자리를 등록한다 — 레지스트리는 하나.** 14번의 `isClaimed` 축만으로는 "한 값은 한 자리" 불변식(`slot-plan.md` "핵심 제약: 소유권 귀속과 단일 마운트")이 Slot 경로에만 걸려 있었다 — 같은 Instance를 `D.Frame { c }` 둘에 놓으면 둘째가 조용히 가져가고 첫째의 retractor(`c.Parent = nil`)가 둘째 트리를 뜯었고, `{ c, c }`·`slot:Add(정적 자식)`·`q.dispose(정적 자식)`도 통과했다(round10 §4 Q48, 탐사 C 실행 재현; G-6: 숏핸드 관리 자식 `_quad_round` 등은 `q.dispose`가 조용히 파괴한 뒤 다음 발행이 시체에 써졌다). 사용자: *"처음부터 막으려고 했던 표면인데, 안 막혀있는 부분. 권고가 맞고, 다만 elementOwner 는 공유적으로 둘 다 대칭으로 들어간다 보는데, 두 곳에 놓을 이유가 있나 모르겠음"* — 레지스트리를 둘로 나누지 않는다. 구현: `Slot/init.luau`가 `claimOwnerAt`/`releaseOwner`를 `module.Bookkeeping`에 공개(SURFACE 태그, `QuadTypes.Bookkeeping`에 두 필드); `Handlers/InstanceChild.luau`는 `process` 머리(부기·물리 부착 전)에 `claimOwnerAt(v, inst, k)`, retractor 끝에 `releaseOwner(v, inst)`(SlotHandler와 같은 순서; `H-154` dedup 경로는 자리를 쥔 채 재`process`되므로 `false`를 받고 부착을 건너뛴다); `Handlers/InstanceShorthand.luau`는 관리 자식 생성 때 `claimOwnerAt(child, inst, childName)`, 파괴 직전 `releaseOwner`. 메시지 접두는 이제 어느 자리에서든 나므로 `Slot:` → `Bookkeeping.claimOwnerAt:`. BREAKING은 사용자 판단으로 허용: *"처음부터 오류를 내야했던 부분을 안 내던걸 막은거라 … 멀쩡한 소비자에는 큰 차이가 안 나"*. 스펙 `spec.handlers` 12·`spec.shorthand` 8. 자리에 앉은 값에 대한 `dispose` 거부는 기존 `elementOwner` 역조회가 그대로 덮는다(`slot-plan.md`의 dispose 절 — "새 부기가 필요 없음").

17. **[2026-09-17 사용자 결정 — round10 Q49 (a)] 매퍼 클래스는 자식 해석에 참여한다 — `nativeFindChild(inst, key, className?)`.** 디스크립터의 `_className`은 라벨로만 쓰이고 자식은 이름으로만 잡혀서, `M.TextLabel("Kid")`가 `ImageLabel`인 Kid를 props가 겹치면 조용히 claim해 잘못된 타입의 핸들을 돌려줬다(탐사 C F4). 이제 base가 클래스 이름을 셋째 인자로 넘기고 백엔드가 판정한다 — quad-roblox는 `FindFirstChild` 뒤 `IsA`(하위 클래스 통과), mock은 `ClassName ==`; 아니면 `nil`을 돌려 15번의 부재 fail-fast와 같은 자리에서 `Claim: no child matched key … — a child with that name must also be a {class}`. ~~부분 claim이 남는 정도도 15번과 같다(선행 자식·루트는 claim된 채 — Declaration 중간 throw의 일반 UB).~~ **[2026-09-17 round11 `H-539` 정정]** 해석 실패는 이제 아무것도 claim하지 않는다(19번). 사용자: *"엔진별 요소들을 너무 많이 알아야하나 싶었는데 그건 아니기도 하고, 흔한 실수인데 애매하게 터지는것 보단 작은 비용으로 처리 가능 … 이름만 보던 함수에 className 넣고 검사 한번 한다라면 난 동의"*. 디스크립터 훅 필드(b)는 새 메커니즘이라 기각. 프로바이더 계약 BREAKING(창 안). 스펙 `spec.claim` 11.

18. **[2026-09-17 사용자 결정 — round10 Q58 (가)] `q.dispose(Instance)`는 소유를 검사하지 않는다 — 계약은 "부기를 깨지 않고 안전히 제거"다.** code-review가 낸 "이 인스턴스가 claim한 것으로 좁히자"는 기각: 좁히면 `Instance.new`/`:Clone()` 결과의 `dispose` 호환이 깨지고 base는 "남의 것"과 "미claim"을 못 갈라 오진한다. 사용자: *"단순히 '우리가 가졌나? 부기를 깨지 않아 지울 수 있냐?'를 보고 지워줄 뿐, 소유하지 않더라도 부기에 없는 형태가 맞다면 지울 수 있다고 보는게 맞아보임 … 계약 자체를 '부기를 깨지 않는 조건을 성립하고 안전히 제거'에 가깝게 둬야하고, 문서화/케비엇 상 잡아줘야"*. 검사는 16번의 `elementOwner` 역조회(자리에 앉은 값 거부)와 `H-537`의 교차 인스턴스 Slot/State 문뿐; 다른 quad 인스턴스의 자리에 앉은 Instance는 이쪽 부기에 없어 통과 — 교차 인스턴스 UB(`H-186`) 범주. 레퍼런스 core/06·core/10 캐비엇. 같은 문항 (나): quad-roblox의 `Event`·`OnChange`를 `HANDLER_PRIORITY_NORMAL - 1`로(사용자: *"handler dispatch 는 결정론적으로 해석되지 않기 때문에 각각 오프셋 되어 슬롯을 가지는게 이롭게 보임"*) — 술어 배타적이라 동작 무변경, `q.debug` 동률 출력 0(`spec.handlers` 13).

19. **[2026-09-17 round11 `H-539`] `Claim`은 두 패스다 — 해석(검증)이 끝난 뒤에야 claim·drive.** **[같은 날 21번·code-review 정정 — 이 항목의 "계획 순서대로 nativeClaim"은 루트부터로 바뀌었고, "남는 비원자성은 drive 단계뿐"은 "drive 단계 + 자식이 이미 claim된 경우"다(Q64).]** round10 §5가 이월한 잔여("부재 raise가 `nativeClaim`/`_fired` 뒤라 고친 재시도가 already claimed")를 탐사 E′가 가짜 프로바이더로 재현했다: `nativeClaim(root)`이 자식 조회보다 먼저 무조건 커밋돼, 자식 부재·클래스 불일치(15·17번)·디스크립터 재사용 어느 실패에서도 루트와 앞선 형제가 claim된 채 남고 같은 루트로 고쳐 재시도하면 `nativeClaim: Instance is already claimed by quad`가 진짜 원인을 가렸다 — `H-425`/`H-471`이 props 게이트에 세운 원칙("디스크립터는 그대로 남아 재시도가 진짜 원인을 보고한다")과 어긋난다. 처방은 새 메커니즘이 아니라 `slot-plan.md`의 선행 패스 원칙(`H-30`/`H-31` — 여러 요소를 받는 연산은 mutate 전에 검증을 전부 통과)을 Claim에 적용한 것: 1패스 `resolve`가 `_fired`·`seen`(같은 디스크립터가 한 트리의 두 자리)·props 테이블·`nativeFindChild`를 트리 전체에 걸쳐 검사만 하고 `{ inst, desc, children }` 계획을 자식 먼저(bottom-up) 쌓는다, 2패스 `commit`이 계획 순서대로 `nativeClaim` → `_fired = true` → 배열 슬롯을 해석된 Instance로 교체 → `drive`. §4의 "claim은 그 inst의 drive 앞"(②가 ③④에 앞선다)은 그대로다 — 바뀐 것은 "루트 claim이 자식 조회에 앞선다"는 순서뿐이고 그건 §4가 요구한 적 없다. 남는 비원자성은 drive 단계(핸들러 throw)뿐 — Declaration 중간 throw의 일반 UB로 레퍼런스 roblox/04에 적었다. 스펙 `spec.claim` 12.

20. **[2026-09-17 round11 탐사 A′ — `H-544`·`H-545`·`H-546`, Q60] 공유 레지스트리의 산술·부기는 정합(모델 기반 퍼즈 1200시드 × 500스텝 + 400 × 200 무발견); 남은 것은 "거부·예외 뒤에 남는 상태" 축.** (1) **`H-544`** `D.<Class> { … }`가 중간에 던지면(nil 구멍·프로퍼티 오타) 그 전에 앉힌 정적 자식은 반쯤 지어진 Instance에 자리를 잡은 채 남고, 그 Instance는 호출자에게 안 돌아오므로 nil 구멍 메시지가 시키는 재시도가 "already mounted elsewhere"로 실패했다 — `dispose`도 거부, `retractFrom`도 NOOP retractor라 빠져나갈 길이 없었다. 원자성은 pcall 없이는 못 만드니(architecture "감싸지 않는다") 회수 경로를 문서화한다: 반쯤 지어진 Instance는 `child.Parent`로 닿으니 `q.dispose`하면 자식들이 같이 파괴된다(메시지에 구절 추가, 레퍼런스 core/06 캐비엇). (2) **`H-545`** 정적 자리에 Slot의 `H-500` 순환 가드 짝이 없어 mock에서 `src:Set(host)`가 `host.Parent == host`를 만들었고, 실기기라면 엔진의 circular-reference raise가 `claimOwnerAt`/`setOffsetSource` 뒤에 와 (1)의 모양이 됐을 것 — `InstanceChild.process` 머리에서 `inst`의 조상 사슬을 걸어 `v`를 만나면 `InstanceChild: cannot place an Instance inside itself or one of its own descendants (that would be a cycle)`(생성 경로는 `Parent`가 nil이라 O(1)). (3) **`H-546`** 공개된 `claimOwnerAt`/`releaseOwner`만 형제 여섯의 nil 게이트(`H-504`)가 없었다 — `claimOwnerAt(nil, …)`이 `Relate:GetWeak: inst must not be nil`(leaf blame)로 죽고, `claimOwnerAt(v, nil, k)`는 OWNER nil·OWNER_POS k를 쓰고 **true를 돌려줘** 프로바이더가 nil 소유자 아래 자식을 붙였다 — 넷 다 `Bookkeeping.<op>: … must not be nil`. 곁들여 F5(공개 `releaseOwner`에 남의 ownerKey를 넘기면 통과해 Slot 원소가 풀리고 그 Slot은 다음 CRUD에서 동결): 구조적으로 못 가르는 자리라 extend/02에 "자기가 잡은 자리만 푼다" 계약 한 줄. (4) **Q60(문항)** 정적 자식 State가 거부될 값(다른 자리에 앉은 인스턴스·미claim)을 받으면 옛 점유자가 **거부 전에** 이미 내려간다 — Dispatch가 옛 retractor를 돌린 뒤에야 새 `process`의 게이트에 닿기 때문. CHANGELOG는 미claim 팔에 대해 이미 그렇게 적었고 `claimOwnerAt` 팔에도 같은 구절을 붙였다; 거부 전 검증은 핸들러 계약에 검증 단계를 더하는 새 메커니즘이라 문항. 스펙 `spec.handlers` 14.

21. **[2026-09-17 round11 `H-551` — 탐사 A″ 1·4, 19번의 회귀 정정]** 19번이 claim을 bottom-up 계획 순서로 돌리자 `nativeClaim(root)`이 마지막 mutation이 돼, **이미 claim된 루트**(`D.New` 결과·이중 Claim — `spec.claim` 7의 경로)로 `Claim`하면 자식 트리 전체를 claim·drive·`_fired`까지 커밋한 뒤에야 "already claimed"가 났다(27b8306은 아무것도 안 건드렸다 — 회귀). 정정: `commit`은 claim을 **루트부터**(계획의 역순) 전부 먼저 하고 drive만 bottom-up으로 — §4 "claim은 그 inst의 drive 앞"은 그대로 성립하고 첫 mutation이 다시 루트 claim이라 루트 실패는 무손상. 자식이 이미 claim된 경우(외부 claim·같은 자식으로 해석되는 디스크립터 둘)는 루트와 앞선 형제가 claim된 채 남는 옛 모양 그대로인데, 그중 "서로 다른 디스크립터 둘이 같은 자식으로 해석"은 1패스 `seen[inst]`로 잡아 `Claim: two mapper descriptors resolved to the same Instance …`(아무것도 안 건드림). 스펙 `spec.claim` 13. 메모(탐사 A″ 2·6): `H-540`의 `Refresh`는 드리프트를 소비하므로 "던진 fn이 드리프트 재실행에서 또 던지고, 그 뒤 fn의 **State 아닌** 내부 상태로 고쳐진" 경우는 게이트 flush로 회복되지 않는다 — 미선언 의존성으로 고치는 것은 §8 stale UB 범주(`state-epoch-plan.md` 끝 절에 병기). `H-547`의 자리당 클로저는 plain 프로퍼티 500×4에서 +13%(자리당 ~155B) — 기록을 지울 retractor는 inst·k를 알아야 해 공유 불가, 수용.
