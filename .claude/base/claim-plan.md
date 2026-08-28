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
  (`Frame` vs `MapperDescriptor<Frame>`). 사용자: *"D.Frame 의 함수의 부분들을
  type FrameParam = {} 형태로 빼서 공유되는 타입 부분으로 D.Mapper.Frame 도
  구성되고, 리턴부분만 다르게"*. `base/bind-system-plan.md`의 `D.Frame =
  New<<Frame>> "Frame" :: ((…) -> Frame)` 캐스트가 인라인 타입 대신 이 이름을
  쓰게 되는 것뿐이고, `D`가 전량 생성기 산출물이라 손으로 쓸 곳은 없다.

  ```luau
  type FrameParam = { … }                                   -- 생성기 산출물 (필드 파트)
  D.Frame        :: (FrameParam) -> Frame
  D.Mapper.Frame :: (key: string | MapperRoot) -> (FrameParam) -> MapperDescriptor
  Claim          :: <T>(inst: T, desc: MapperDescriptor) -> T   -- T는 inst에서 그대로
  ```

  **⚠️ [2026-08-28 `/code-review`] 배열 파트는 그대로 공유할 수 없다** — `New`의
  children 배열엔 `MapperDescriptor`가 올 수 없고(오면 런타임 "매치 핸들러 없음"),
  매퍼의 배열엔 와야 한다(§2 예시의 `M.TextLabel "Title" {…}`). 사용자 인용은
  **필드 파트의 타입 공유**를 승인한 것이고 배열 파트를 어떻게 가를지는 정하지
  않았다 → §10-D. `base/bind-system-plan.md`의 `D` 생성기 절엔 아직 `<Class>Param`이
  없다 — 생성기 구현(`ROADMAP.md` M5 `D/init.luau`)이 이 문서를 같이 본다.

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
  (그 셋업을 누가 하는지는 §10-A).
- **디스크립터는 1회용** — `PreRef`의 `_fired`처럼 **디스크립터 객체에 소진
  플래그**를 세우고 재사용이면 `error(…, 2)`. **[2026-08-28 `/code-review` 정정]**
  `PreRef` 관용구의 다른 절반(배열 슬롯을 `ProcessedPreRef` 센티널로 교체)은
  **가져오지 않는다** — 매핑 자식의 배열 슬롯은 §4대로 **해석된 Instance로 교체**돼야
  `InstanceChildHandler`에 닿고, 루트 디스크립터는 배열에 있지도 않다. 사용자
  테이블을 in-place로 바꿀지 새 테이블을 만들지(그러면 `ProcessedModifier` 자리와
  인덱스가 `New`와 달라진다)와 Modifier 필드 안에 숨은 디스크립터를 DFS가 보는지는
  **구현 시 정할 것**(§9). **같은 `inst`를 두 번 `Claim`하는 것도 error**(§7-7) —
  어느 레지스트리로 판정하는지는 §10-B.
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
  (이 경로는 PlayerGui를 claim하지 않으므로 §6/§10-C의 한계와 무관).
  `Claim(PlayerGui, …)`은 **PlayerGui 전체를 그 스크립트가 소유하겠다**는 뜻이라
  한 번만 가능하고, 여러 스크립트가 PlayerGui 직하 `Slot`을 공유해야 하면
  **`Claim`을 한 번 하고 그 안에 Slot을 만들어 반환하는 중간 모듈**을 둔다
  (사용자: *"정확히는 두번 Claim 불가하다는 의미. 필요하다면 Slot 을 안에 만들고
  리턴하는 중간 모듈을 만들어야함"*) — 단 PlayerGui 자체를 claim하는 그 경우는
  §6/§10-C(엔진이 자식을 넣는 컨테이너)의 답에 걸린다.

## 6. 이 문서가 여는 것

- **루트 컨테이너**: `Claim(PlayerGui, M.PlayerGui(M.Root) { Slot {…} })` — PlayerGui가
  quad 소유 부모가 되어 Slot이 그 아래 산다(한 스크립트가 PlayerGui 전체를
  소유하는 경우). **⚠️ [2026-08-28 `/code-review`] 이건 own-all 계약(§3)의 한계
  사례다** — Roblox `PlayerGui`는 엔진이 `StarterGui`를 스폰·리스폰마다 새로 복제해
  넣는 컨테이너라(`ResetOnSpawn`), 디스크립터가 매핑할 수 없는 자식이 **quad 소유
  부모 아래 밖에서** 들어온다(`base/slot-plan.md`의 "동적 자식은 반드시" 절이 UB로
  못 박은 그것). 계약 그대로면 *"엔진이 자식을 넣는 컨테이너를 claim하는 것은 UB"*
  이고 흔한 경로는 §5의 `.Parent =`다 — 이 한계를 계약으로 명문화할지, `StarterGui`를
  안 쓰는 전제를 문서화로 둘지는 **§10-C**. 같은 자리: 매퍼 생성기 범위(GUI 클래스)에
  `PlayerGui`류 컨테이너가 들어가는지도 거기서.
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
   아닌 자리에)은 debug 검사 후보.
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

## 8. 검토 후 안 만들기로 한 것

- `Claim<<"Frame">>` 타입 인자 / 루트를 맨 테이블로(§7-1).
- 루트 컨테이너용 별도 얇은 표면, `Claim`의 부분 매핑 모드, 다중 claim(§7-7).
- claim 시 `nativeMove`로 물리 순서를 디스크립터에 맞추기(§7-2).
- 매핑된 자식 전용 핸들러(§7-8).
- `Mount(root, parent)`류 표면(`H-146`, §5).
- 이미 있는 Instance에 나중에 props를 재바인드(`archive/existing-instance-bind-rejected.md`,
  헤더).

## 9. 구현 체크리스트 (M5) · 문서화 대상

- `D.Mapper.<Class>` 생성기 산출 + `type <Class>Param` 필드 파트 공유(사용자 확정;
  배열 파트는 §10-D) + 루트 센티널(사용자 확정 — 놓는 자리 `D.Mapper.Root`는
  에이전트 제안) + 디스크립터 브랜드(`MapperDescriptor`는 가칭 — `Brand` 인스턴스
  브랜드로 만든다는 것은 `base/brand-plan.md`의 일반 규칙이지 새 결정 아님).
- `Claim(inst, desc) -> inst` — DFS 해석 → bottom-up `drive`, 소진 플래그(§2), 같은
  `inst` 이중 claim error(레지스트리는 §10-B), 이미 quad 소유인 inst의 gcconn/gchold
  셋업(§10-A). **구현 시 정할 것**: 사용자 테이블 in-place 교체 vs 새 테이블,
  Modifier 안의 디스크립터 처리, 패키지 안 정의 파일 위치(`quad-base/src/Claim.luau`
  가칭 — `base/architecture.md` 소스 트리에 반영은 M5 착수 때).
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

## 10. 사용자 판단 필요 — M5 착수 전 (2026-08-28 `/code-review high`가 낸 공백)

전부 **새 메커니즘이 필요한 공백**이라 `conventions.md` 규칙대로 결정 없이 본문에
넣지 않았다. M2 게이트 아님. `question.md`에도 같은 넷이 올라가 있다.

- **A. claim한 inst의 gcconn/gchold 셋업 자리.** §2는 *"`New`가 만든 것과 같은
  gcconn/gchold·부기"*를 약속하는데, 그 (0) 셋업은 quad-roblox `New` ②단계의
  **인라인 코드**(`base/bind-system-plan.md`의 `New` 의사코드 ② 단계, `lifecycle-pattern.md`
  (0))이고 `Claim`은 quad-base다. §4대로 `drive`만 부르면 claim된 루트 아래 첫
  `Slot`이 `bindLifetime`의 `gchold[value] = true`에서 nil 인덱스로 죽는다. 갈래:
  (a) 프로바이더가 (0) 셋업을 op로 노출(`nativeAdopt(inst)` 가칭)하고 `Claim`이
  해석한 inst마다 부른다 / (b) `Claim` 본체를 프로바이더에 둔다(quad-base는 순회
  알고리즘만) / (c) (0) 셋업 자체를 quad-base 함수로 옮기고 `New`도 그걸 쓴다.
  **권고 (a)** — `nativeFindChild`와 같은 모양이고 `New`의 경로가 안 바뀐다.
- **B. 같은 `inst` 이중 claim의 판정 레지스트리.** 기존 소유권 레지스트리
  `elementOwner`(`base/slot-plan.md`)에 기록하면 `claimOwner`가 §6의 *"claim한
  inst를 Slot 요소/정적 자식으로 그대로 쓴다"*를 error로 죽인다. 갈래: (a) (0)
  셋업이 만드는 per-inst `InstData`에 `claimed` 플래그 — 셋업과 같은 자리라 새
  Relate가 없다 / (b) 별도 weak-key 레지스트리. **권고 (a)** — A의 답에 따라
  자동으로 정해지는 모양.
- **C. 엔진이 자식을 넣는 컨테이너(`PlayerGui`)와 own-all 계약.** §6 첫 항목. 갈래:
  (a) 계약에 *"엔진이 자식을 넣는 컨테이너를 claim하는 것은 UB"*를 명문화하고
  흔한 경로는 `.Parent =`(§5)로 — `StarterGui`를 안 쓰는 프로젝트만 PlayerGui를
  claim / (b) 컨테이너용 부분 매핑 — §7-7에서 이미 기각. **권고 (a)**. 부수: 매퍼
  생성기 범위에 `PlayerGui`류 컨테이너를 넣을지(`base/bind-system-plan.md`의 생성 범위
  *"GUI에 쓰이는 모든 인스턴스"*엔 없다).
- **D. `type <Class>Param`의 배열 파트.** 필드 파트 공유는 확정(§2). children
  배열의 원소 유니언은 `New`(Instance·Slot·State…)와 매퍼(+ `MapperDescriptor`)가
  달라야 한다. 갈래: (a) `type FrameParam<C> = { [number]: C, …필드 }`처럼 원소
  타입을 파라미터로 — 생성기 한 줄 / (b) 필드 파트만 `FrameFields`로 빼고 배열은
  각자 — 타입 둘. **권고 (a)**. 어느 쪽이든 `luau-analyze` 스파이크로 확인
  (`base/typing-limits.md` 설계 체크리스트 6번 — *"추론만으로 … 확정하지 말 것"*).
