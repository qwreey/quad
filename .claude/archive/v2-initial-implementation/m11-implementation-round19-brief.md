# M11 자율 구현 규약 — 19라운드 지시서 + 착수 문항지

> **이 파일이 무엇인가**: **[2026-09-06 신설]** M11(Tween — 값-레벨 래퍼
> `Tween<T>` + `PropertyHandler` 소비 + `Animate` 콤비네이터) 구현 구간의
> 규약이자 착수 문항지다. M8의 `m8-implementation-round18-brief.md`와 같은
> 지위 — §0이 확정되면 이 파일이 M11 규약 소스다. 산출물(발견 문서)은
> `m11-implementation-round19.md`.
>
> **착수 근거(사용자, 2026-09-06)**: 다음 마일스톤 순서를 **M11 → M10 잔여
> InstanceShorthand → M9**로 확정했고(선택지 셋 중 첫째 — Tween은 설계가
> 전부 확정돼 있고 Studio로 검증 가능한 코드 작업이라 밤샘 자율에 맞다,
> InstanceShorthand는 ROADMAP이 M11 이후를 지정, M9는 설계 대화가 필요할 수
> 있어 마지막), **§0은 권고 (a)로 착수하되 새 표면·메커니즘을 정하는 문항만
> 멈춘다**(*"해소되면 자유롭게 장기적으로 작업해도 좋아"* — 세 갈래 규칙
> 그대로: 그런 문항은 §4에 쌓고 그 단위를 멈춰 회신을 기다린다). fable
> 탐사자의 발견이 사용자 결정을 요구하면 **영역이 겹칠 때만** 착수를 막는다
> (사용자 선택). 이 세 결정의 원문은
> `session/2026-09-06-01-audit-sweep-and-m11-brief.md`.
>
> **명명**: `mN-implementation-roundNN` 규약 그대로 — M11의 첫 라운드가
> **round19**, 발견 번호는 메인 직렬 라인이 round18에서 `H-322`까지 썼으므로
> **`H-323`부터**. InstanceShorthand는 M11이 끝난 뒤 **자기 문항지**(round20)
> 를 따로 쓴다 — 이 파일의 범위가 아니다.
>
> **전제(이미 충족)**:
> - 정본 `base/tween-plan.md`엔 **열린 질문이 없다**("열린 질문 — 전부
>   해소됨" 절). 값 모양(`Info` 우선 + 편의 필드 폴백, 기본값은
>   `TweenInfo.new()` 자신의 것), override 두 값(`Tween.Cancel`/`Tween.Finish`),
>   3-상태 릴레이션 슬롯(`{Tween, Value} | true | nil` — `H-155`), 첫 세팅
>   스냅, `Animate(info)`는 `factory(self) -> State`로 `:Apply` 전용,
>   `Tween<T>:Mapped(fn)`, 자연 완료 시 정리 없음, `initValue`는 **에이전트
>   범위 제외** — 전부 확정.
> - `TweenBrand` 인스턴스는 `Brand.luau`에 이미 있다. **`isTween` 술어는
>   없다**(quad-types `Quad` 타입의 술어 목록 주석이 *"남은 것은 `isTween`"*
>   이라 적어 둠) — 단위 ①이 채운다.
> - quad-roblox `src/types.luau`에 **타입 `Tween<T>`가 M5부터 선행**해
>   있다(생성 `D`의 스칼라 유니언 `T | State<T> | Tween<T> | None`이 이걸
>   쓴다 — round14 `H-298` (a)). `Override: any?`는 *"센티널이 M11에 온다"*
>   고 스스로 적어 뒀다. 그러니 M11의 타입 작업은 "신설"이 아니라 **quad-base
>   런타임과 이 선행 타입을 잇는 것**이다(§0 Q3).
> - `Handlers/Property.luau`는 M5가 짰고 헤더가 *"`isTween(realv)` 분기 +
>   3-상태 릴레이션 슬롯 — M11, 이 파일이 그 분기를 키운다"*고 자리를 비워
>   뒀다. `game`은 cache-miss 경로에서 lazy로 읽어 CLI spec이 `getfenv` 심
>   (`mock.gameShim`)을 꽂는다 — `TweenService`도 **같은 seam**을 탄다.
> - StoreBind 언랩은 `isState(v)`만 보고 재귀하므로 `Tween<T>`(브랜드된
>   plain 테이블)는 `realv`로 그대로 도착한다("타입 대수" 절) — 디스패치
>   코어·핸들러 매치 규칙은 **손대지 않는다**("왜 `retract`가 더 이상 필요
>   없는가" 절: 매치는 여전히 `PropertyHandler` 하나).
> - **범위 밖**: `initValue`(정본이 사용자 몫으로 못박음), 스프링
>   (`research/spring-plan.md`), InstanceShorthand(round20), `quad-mock`의
>   Tween mock(백로그 — 이번 CLI 심은 spec 전용 최소형).
>
> §2~§5는 M8 규약(= M7 = M5 = M4 = M3 준용본)을 준용하고, 다른 자리에만
> `[M11 변경]` 표시.

---

## §0 ⭐ 착수 문항 (배치 회신용)

| 문항 | 무엇 | 선택지 | 권고 | 권고 근거 |
|---|---|---|---|---|
| **Q1** | 규약 재사용 범위 | (a) M8 골격 그대로(세 갈래 / 커밋 게이트 두 층 / 단위 끝 절차 = 감사 루프(유한, 각도 교대) → `/code-review medium` 1회 → 탐사자(작으면 생략·기록) → doc-check ERROR 0 → 커밋 / Studio 실측은 엔진 대면 델타가 있는 단위에만) / (b) 다른 방식 | **(a)** | M2~M8·M10 아홉 구간에서 검증된 골격. M11은 엔진 `TweenService`가 실체라 Studio 축이 특히 무겁고, 나머지는 작다 |
| **Q2** | 단위 절단 | (a) **세 단위**: ① 값 런타임 — `quad-base/src/Tween.luau`(`Tween(opts)` 팩토리 — clone·검증·`TweenBrand` 등록·freeze, `Tween.Cancel`/`Tween.Finish` 센티널(Q4), `tween:Mapped(fn)`, `H-238` 태깅) + `Brand.luau`의 `isTween` + quad-types(Q3) + `quad.Tween`/`quad.isTween` + `spec.tween`(순수 Lua) → ② 소비 — `Handlers/Property.luau`의 `isTween(realv)` 분기·3-상태 `Relate` 슬롯·override 정책·`TweenInfo` 조립(`Info` 우선) + `mock.gameShim`의 최소 `TweenService` 심(`Create` 기록·`Play`/`Cancel` 상태만, 보간 없음) + CLI spec + **Studio 실측**(Q7) → ③ `quad-roblox/src/Animate.luau`(`factory(self) -> State`, `resolve`, `CanAnimate`) + `RobloxExtension`에 `Animate` 합류 + strict 타입 spec(CLI로 닫히면 Studio 생략·기록) / (b) 둘로(값+소비 / Animate) / (c) 다른 절단 | **(a)** | ①은 엔진 무관이라 CLI로 닫히고, ②가 M11의 실체(엔진 대면 — 첫 세팅 스냅·Cancel 유지·Finish 스냅은 실기기에서만 참이 확인된다), ③은 슈가라 마지막. M8과 같은 3분할 |
| **Q3** | **`Tween<T>` 타입의 자리** — 런타임 `Tween(opts)`는 quad-base(엔진 무관)인데 옵션 필드 타입(`TweenInfo`/`Enum.EasingStyle`)은 Roblox 전역이라 quad-types(defs 없이 분석)가 이름할 수 없다. 지금은 quad-roblox `types.luau`에만 정밀 타입이 있다 | (a) **quad-types에 엔진 무관 `Tween<T>`를 두고 quad-roblox 정밀판은 유지** — quad-types: `Tween<T> = { read Value: T, read Info: any?, read Time: number?, read Style: any?, read Direction: any?, read RepeatCount: number?, read Reverses: boolean?, read DelayTime: number?, read Override: TweenOverride?, read __quadTween: true, Mapped: … }`(엔진 타입 자리만 `any`, `Mapped`는 typing-limits 1번 ③ `typeof(named function)` 스타일), `Quad.Tween: <T>(opts: TweenOptions<T>) -> Tween<T>`, `Quad.isTween`; quad-roblox `Types.Tween<T>`는 `Info: TweenInfo?`/`Style: Enum.EasingStyle?`로 정밀하게 남겨 생성 `D` 유니언이 계속 쓴다 — 두 타입은 `any` 자리 덕에 양방향 호환(단위 ① strict spec으로 실측, 안 맞으면 `H-nnn`) / (b) quad-roblox `RobloxExtension`이 타입드 `Tween` 팩토리를 얹는다(`OnChange` 선례) — base `quad.Tween`과 `Self & P` 교집합이 제네릭 함수 오버로드가 되어 새 솔버에서 위험 / (c) 다른 | **(a)** | quad-types는 "엔진 무관"이 정체성이고(`quad-types-plan.md`), `Enum.EasingStyle.Bouncy` 같은 오타는 `Enum` 자체가 잡으므로 `any` 자리가 잃는 건 `Style = 3` 같은 드문 오용뿐 — "드문 오용에 구조를 쓰지 않는다". (b)는 8.7절이 기각한 오버로드 교집합 모양 |
| **Q4** **[2026-09-06 사용자 역전 — `H-343`: (b) 문자열 싱글톤으로]** | **`Tween.Cancel`/`Tween.Finish` 센티널의 형태** — 정본은 *"문자열이든 전용 테이블이든 동등성 비교만 되면 된다"*고 열어 뒀고, 타입은 `typeof(Tween.Cancel) \| typeof(Tween.Finish)`로 적었다 | (a) **frozen 마커 테이블 둘** `{ __quadTweenOverride = "Cancel" }` / `"Finish"`(+ `__tostring`), 타입 `TweenOverride = { read __quadTweenOverride: "Cancel" \| "Finish" }` — `None`의 `H-300` 마커 선례와 같은 모양 / (b) 문자열 리터럴 `"Cancel"`/`"Finish"`(타입은 싱글톤 유니언) / (c) 다른 | **(a)** | 코퍼스의 센티널(`None`/`Detach`/`KeyGone`/`MapperRoot`/`Processed*`)이 전부 frozen 테이블 + 마커 필드라 한 모양을 유지한다. (b)는 사용자가 `Override = "cancel"`처럼 문자열을 손으로 쓰는 표면을 열어 런타임 검증(Q5)이 문자열 사전 대조가 된다 |
| **Q5** | **`Tween(opts)`의 검증 범위**(quad-base — 엔진 타입은 못 본다) | (a) `opts`가 테이블 / `Value` 키 존재(`nil` 금지 — 정본 `Value: T`는 필수) / `Override`가 있으면 두 센티널 중 하나 / `Time`·`RepeatCount`·`DelayTime`은 number, `Reverses`는 boolean(있을 때만) / `Info`·`Style`·`Direction`은 **무검사**(엔진 타입 — 틀리면 `TweenInfo.new`/`TweenService:Create`의 엔진 원시 에러가 `process` 안에서 나고 `H-103` NOOP 마커가 고착된다는 기존 캐비엇 그대로 — plain `inst[k] = 틀린 값`과 같은 부류) / 전부 `errorBeforeNearest` SURFACE / (b) 테이블·`Value`만 / (c) 다른 | **(a)** | 엔진 무관 스칼라는 싸게 잡히고, 엔진 타입은 quad가 검사할 수단이 없다. 미검사 항목은 정본 "`None` 센티널" 캐비엇(dispatch-core-plan)에 M11 자리로 한 줄 등재 |
| **Q6** | `Animate`의 `CanAnimate` 케이싱 — 정본이 *"확정은 아님, 뒤집혀도 비용 낮음"*으로 남겨 둔 유일한 자리 | (a) **`CanAnimate` 유지**(같은 테이블의 `Value`/`Style`/`Time`과 PascalCase 통일) / (b) `canAnimate` | **(a)** | 정본의 판단 그대로. 이번에 "확정"으로 닫는다 |
| **Q7** | 단위 ② Studio 실측 항목 | (a) **여섯**: 첫 세팅 스냅(마운트 시 `Tween{…}`이 애니메이션 없이 즉시 값) / `Cancel`(기본) 재시작이 현재 보간값에서 이어지는지(`:Cancel()`이 프로퍼티를 되돌리지 않음) / `Finish`가 `prev.Value`로 스냅 뒤 재시작 / Tween→plain 전환이 "정리 후 즉시 덮어쓰기" / `Info` 우선·편의 필드 폴백(기본값이 `TweenInfo.new()`와 같은지) / 인스턴스 `Destroy` 뒤 활성 트윈이 무해한지(슬롯은 `Relate` weak-key GC) — `audit/m11-unit2-studio-<날짜>.md` / (b) 줄임 | **(a)** | 전부 엔진 시맨틱이라 CLI 심으로는 참을 확인할 수 없는 항목만 골랐다 |

## §1 범위 — 세 단위 (제안, Q2)

소스는 `ROADMAP.md` M11 체크박스(셋, 상세는 거기가 소스)와
`base/tween-plan.md` 전 절. 정본 절:

1. **단위 ①** — "확정: `Tween{...}` 최종 모양" 절(옵션 값 모양·override
   정책·최종 타입), "`Tween<T>:Mapped(fn)`" 절(clone 후 `Value`만 교체 →
   `Tween(opts)` 재호출, 선언은 typing-limits 1번 ③), "패키지 경계" 절
   (quad-base엔 값 타입만). `Tag.luau`가 raw 값 모듈의 본보기(callable
   네임스페이스 + frozen 인스턴스 + `H-238` 태깅). `Init(module)`은
   `module.Tween`/`module.isTween`만 — 핸들러 등록 없음(dispatch 참가자가
   아니다).
2. **단위 ②** — "3-상태 저장" 절(분기 1~3 의사코드 1:1 — 순서 불변식:
   **이전 트윈 정리 → 그 다음 새 값**), "`Tween{...}`의 모든 필드는 plain
   값만 받음" 절, "자연 완료(Completed) 시 per-instance 북키핑" 절(정리
   없음). `Handlers/Property.luau`의 `isHandlable`은 **그대로**(키 매치만),
   `process`만 자란다. `TweenService`는 `game:GetService`를 process 안에서
   lazy로 읽어 CLI 심 seam을 유지. 3-상태 슬롯은 install 스코프의
   `quad.Relate()` 하나(`GetStrong`/`SetStrong`, 키는 프로퍼티 이름).
3. **단위 ③** — "`Animate` 콤비네이터" 절(의사코드 1:1 — `resolve`는
   `if-then-else`, `CanAnimate` 생략 시 `true`, `Style`류 State는 deps로
   안 넘김), "왜 `:Apply`로 정정됐는가" 절. `RobloxExtension = { D,
   OnChange, Animate }`. 타입은 `Animate: (info: AnimateInfo) -> <T>(self:
   State<T>) -> State<T>` 꼴 — 실측으로 확정(파생 State 명시 바인딩 규약).

**미리 알려진 주의**: ① `Mapped`를 `Tween<T>` 안의 인라인 제네릭 메소드로
선언하면 체커가 **조용히 통과**한다(`H-24` 실측) — ③ 스타일 필수, 단위 ①
strict spec에 음성 케이스를 둔다. ② `v == nil` skip-defense는 Tween 분기
**앞**에 그대로(`Tween{Value = nil}`은 Q5가 생성 시점에 막는다). ③ 첫 세팅
분기(`prev == nil`)는 `realv`가 Tween이어도 **`Value`를 즉시 대입**하고
슬롯 `true` — 엔진 트윈을 만들지 않는다. ④ `Finish` 스냅은 `prev.Value`를
**먼저 대입**한 뒤 새 값/새 트윈. ⑤ 활성 트윈 슬롯은 `{ Tween = <엔진
객체>, Value = realv.Value }` **테이블**(`H-155`) — 엔진 객체 하나가 아니다.
⑥ plain 값 세팅도 슬롯을 `true`로 만든다(모든 프로퍼티 쓰기가 슬롯을
남긴다 — 정본 "3-상태 저장"의 정의). ⑦ 이 핸들러의 retractor는 여전히
`Void` — 트윈 취소는 다음 `process`의 분기 3이 한다. ⑧ error 계약(메시지
영어, `errorBeforeNearest` SURFACE는 팩토리·`Mapped`, 핸들러 안은
`errorBefore`). ⑨ `Animate`가 반환한 factory는 항상 `State`를 반환한다는
불변식 — `CanAnimate == false` 분기도 `self:Compute` 안에서 plain을
반환하는 것이지 factory가 plain을 반환하는 게 아니다.

## §2 세 갈래 / §3 리뷰·감사 발견 / §4 관여 시점 / §5 탐사자 지시

M8 규약(`m8-implementation-round18-brief.md` §2~§5 = M7 = M5 = M4 = M3
준용본) 준용. 치환: 발견 문서는 `m11-implementation-round19.md`(`H-323`
부터), 머리말 문구는 "M11 진행 중", 탐사자의 대조 중심 절은
`tween-plan.md`의 "3-상태 저장" 절(분기 셋) / "확정: `Tween{...}` 최종
모양" 절 / "`Animate` 콤비네이터" 절(의사코드) / "`Tween<T>:Mapped(fn)`" 절
/ `architecture.md` 소스 트리의 `Tween.luau`·`Property.luau`·`Animate.luau`
세 줄. M2~M8·M10 하자는 동형 규칙. **[M11 변경]** §0 회신을 기다리지
않는다 — 권고 (a)로 착수하고, 진행 중 **새 표면·메커니즘을 정해야 하는
문항**이 생기면 §4에 쌓고 그 단위를 멈춘다(사용자 2026-09-06). Studio
실측은 단위 ②에만 기본(Q7) — ①·③은 CLI로 닫히면 생략하고 발견 문서에
"생략" 기록.

## §6 단위 작업 계획 (Q2 (a) 기준, 단위 ① 상세만 먼저)

| 파일 | 내용 | 옮겨 적는 절 |
|---|---|---|
| `quad-base/src/Tween.luau`(신설) | callable `Tween`(`__call`: Q5 검증 → `table.clone(opts)` → `TweenBrand:register` → freeze), `Tween.Cancel`/`Tween.Finish`(Q4), `TweenImpl.Mapped(self, fn)`(clone·`Value = fn(Value)`·재구성), `Init(module)`(`module.Tween`, `module.isTween`) | "확정: `Tween{...}` 최종 모양" 절, "`Tween<T>:Mapped(fn)`" 절 |
| `quad-base/src/Brand.luau` | `isTween` 술어 + export | "패키지 경계" 절 |
| `quad-types/src/init.luau` | `Tween<T>`(Q3 (a)), `TweenOptions<T>`, `TweenOverride`, `Quad.Tween`/`Quad.isTween`(`H-80` 탑레벨 목록 규칙) | "최종 타입" 절 |
| `quad-base/src/init.luau` | `Tween`/`isTween` 필드 (~~`RunInit(TweenModule.Init)`~~ — 구현에서 제거: dispatch 참가자가 아니라 등록할 핸들러가 없고 `H-238` 태깅은 파일 스코프에서 끝난다, 2026-09-06) | `architecture.md` 최상위 export |
| `quad-roblox/src/types.luau` | `Override: TweenOverride?`로 정밀화, 헤더의 "M11에 온다" 문구 정정 | — |
| `quad-base/test/spec.tween.luau` | 생성·freeze·브랜드·검증 error 여섯·`Mapped`(원본 불변·옵션 보존·`Tween<U>`)·센티널 항등·strict 양성/음성(`Mapped` 누수 음성) | — |

**커밋 단위**: 단위당 커밋 하나 + 단위 끝 절차(M2~M8 관례). 단위 ②·③의
상세 표는 각 단위 착수 시점에 §6에 이어 쓴다.

**[2026-09-06 단위 ① 완료 — round19 `H-323`~`H-327`]** 위 표대로 + 생성기
(`scripts/gen-d.py`: 슬롯 유니언 `+ State<Tween<T>>`·타입별 별칭 `PVn`·`Field<T>`)
와 `quad-roblox/test/spec.tweentypes`·`luau-test/done/33`. Q3 (a)의 정밀판은
실측으로 포기(`H-326`), Q4 (a)의 마커는 `sentinel(name)` 재사용(`H-323`),
`TweenConstructor`는 8.6 예외(`H-324`) — §4 확인 항목 둘.

**단위 ② 계획(착수 시 작성 — 2026-09-06)**

| 파일 | 내용 | 옮겨 적는 절 |
|---|---|---|
| `quad-roblox/src/Handlers/Property.luau` | `process`에 3-상태 슬롯(install 스코프 `quad.Relate()`, 키 = 프로퍼티 이름): `prev == nil` → `Value`(또는 plain) 즉시 대입·슬롯 `true`(엔진 트윈 없음) / `prev == true` → plain이면 대입, Tween이면 `TweenService:Create(inst, info, { [k] = v.Value }):Play()`·슬롯 `{ Tween, Value }` / `prev`가 테이블 → **먼저** `prev.Tween:Cancel()`, 정책이 `Finish`면 `inst[k] = prev.Value` 스냅, **그 다음** 새 값(plain 대입·슬롯 `true` / 새 트윈·새 슬롯). `TweenInfo`는 `Info`가 있으면 그대로, 없으면 `TweenInfo.new(Time, Style, Direction, RepeatCount, Reverses, DelayTime)`에 ~~nil을 그대로 넘겨~~ **[Studio 실측 `H-333`]** 명시적 nil은 엔진이 거부(enum 자리) — 빠진 필드는 엔진 기본값(1/Quad/Out/0/false/0)을 **명시해** 채운다(정본 "별도 기본값 상수 없음"의 정정). `TweenService`는 `game:GetService`를 process 안에서 lazy(캐시 1회) — CLI 심 seam | "3-상태 저장" 절 분기 1~3, "옵션 값 모양" 절, "override 정책" 절 |
| (해석) override 정책의 **주체** | 정본은 `Override`를 `Tween{...}` 옵션에 두고 슬롯엔 `{ Tween, Value }`만 저장한다(`H-155` — `Finish`가 목표값을 알아야 해서). 그러면 활성 트윈이 있을 때 참조되는 정책은 **들어오는 값의 `Override`**(= "이 트윈이 앞의 것을 어떻게 덮을지")이고, 들어오는 값이 plain이면 정책이 없어 `Cancel`과 같다(정본 "Tween→plain 전환은 두 옵션 모두 정리 후 즉시 덮어쓰기") — 슬롯에 정책을 안 넣는 정본 모양과 유일하게 맞는 해석. 발견 `H-328`로 기록, §4 확인 항목 | "override 정책" 절 |
| `quad-base/test/mock.luau` | `gameShim`에 `TweenService` 심 — `Create(inst, info, props)`는 호출을 기록하고 `{ Play, Cancel, PlaybackState }`(보간 없음 — Cancel 시 프로퍼티 그대로)를 돌려준다. `TweenInfo` 전역은 Property env에 심(`getfenv`) — 인자 그대로 기록하는 테이블 | — |
| `quad-roblox/test/spec.tweenproperty.luau` | 첫 세팅 스냅(Tween이어도 `Create` 0회) / plain→Tween(Create 1·Play 1·슬롯) / Tween→Tween Cancel(이전 Cancel 1, 스냅 없음, 새 Create) / Tween→Tween Finish(이전 Cancel 뒤 `prev.Value` 대입 → 새 Create) / Tween→plain(Cancel 뒤 대입, Create 없음) / `Info` 우선(편의 필드 무시)·편의 필드 nil 전달 / `State<Tween>` 재발행 경로(StoreBind 언랩 뒤 같은 분기) / `v == nil` skip 유지 / Mapped 값 | — |
| **Studio**(Q7 여섯) | `audit/m11-unit2-studio-2026-09-06.md` — rojo 싱크 후 `task.wait`로 보간 관측 | — |

**[2026-09-06 단위 ② 완료 — `H-328`(구현)·`H-333`]** 위 표대로 + `spec.tweenproperty`(6절)·mock `TweenService`/`TweenInfo` 심, Studio 6/6(플러그인 미연결로 런타임 모듈 다섯을 Source 패치해 실측 — audit 경위).

**단위 ③ 계획·결과(2026-09-06 — `H-334`)**

| 파일 | 내용 | 옮겨 적는 절 |
|---|---|---|
| `quad-roblox/src/Animate.luau`(신설) | `install(quad) -> Animate` — 정본 의사코드 1:1(`resolve`는 if-then-else, `CanAnimate` 생략 = true, false면 plain 반환, 옵션 State는 deps 아님, `Tween{...}`엔 plain만), `H-238` 태깅 | "`Animate` 콤비네이터" 절 |
| `RobloxFactory.luau` / `init.luau` | `RobloxExtension = { D, OnChange, Animate }` | "패키지 경계" 절 |
| `types.luau` | `AnimateInfo`(필드 `T \| State<T>`), `AnimateFn = (info) -> (self: any) -> State<Tween<any>>` — 정직한 `State<T \| Tween<T>>`·제네릭 factory·`State<any>` 전부 실측 실패(`H-334`) | "타입 대수" 절 배너 |
| `spec.animate`(런타임 4절)·`spec.tweentypes`(Animate 양성) | 옵션 resolve·CanAnimate 토글·옵션 State 비-deps·검증 blame / `:Apply` 경유 슬롯·setter·주석 | — |

Studio: 생략(엔진 대면 델타 없음 — `Tween{...}` 생성뿐, 발견 문서에 기록).

