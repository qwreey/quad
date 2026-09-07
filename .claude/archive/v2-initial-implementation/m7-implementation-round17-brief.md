# M7 자율 구현 규약 — 17라운드 지시서 + 착수 문항지

> **이 파일이 무엇인가**: **[2026-09-03 신설 — §0 회신 대기]** M7(Modifier)
> 구현 구간의 규약이자 착수 문항지다. M5의
> `m5-implementation-round14-brief.md`와 같은 지위 — §0이 확정되면 이 파일이
> M7 규약 소스다. 산출물(발견 문서)은 `m7-implementation-round17.md`.
> 사용자 지시(2026-09-03): *"이거 끝나면 더 볼 것 없다면, M7 규약 문항지를
> 쓰자, 그런데 AttributeKey 부터 해결해야 할것 같아"* — AttributeKey 몫은
> round16 `H10-15`로 닫혔다(round16 열린 문항 0).
>
> **명명**: `mN-implementation-roundNN` 규약 그대로 — M7의 첫 라운드가
> **round17**, 발견 번호는 메인 직렬 라인이 round14에서 `H-308`까지 썼으므로
> **`H-309`부터**(fork 접두 `H6-`/`H10-`은 병렬 원장 전용이었고 M7은 메인
> 단일 맥락 직렬이다).
>
> **전제(이미 충족)**: 정본 `base/modifier-plan.md`는 열린 질문 0(문서 말미
> "열린 질문" 절 전부 `[해소됨]`), 두 Luau 동작은 실측 완료 —
> `luau-test/done/17`(제네릭 `__index` + `table.clone` 체이닝, 내부 저장소
> `FieldsKey`, 형제 분기 무오염) / `09`(`Overridden` 서브타입 합성은 정적
> 체크 포기 → `(...: any): any`). `isModifier` 런타임 가드는 **M2가 이미
> 심었다**(`Source.luau` 생성자·`:Set`, `State.luau` `:Compute` 캐시 — 7번 절)
> — M7은 실물 Modifier 값으로 그 가드를 spec에서 다시 밟기만 한다.
> `D` 파이프라인의 ③ flatten 자리는 M5가 **항등 함수**로 비워 뒀다
> (`D/init.luau` `flatten(props) return props`), `Claim`은 flatten을 안 거치고
> `drive`를 직접 부른다(`Claim.luau` 헤더 — "M7's flatten integration owns
> that seam"). 이 둘이 M7이 채울 실제 봉합선이다.
>
> §2~§5는 M5 규약(= M4 = M3 준용본)을 준용하고, 다른 자리에만 `[M7 변경]`
> 표시.

---

## §0 ⭐ 착수 문항 (배치 회신용)

| 문항 | 무엇 | 선택지 | 권고 | 권고 근거 |
|---|---|---|---|---|
| **Q1** | 규약 재사용 범위 | (a) M5 골격 그대로(세 갈래 / 커밋 게이트 두 층 / 단위 끝 절차 = 감사 루프(유한, 각도 교대) → `/code-review medium` 1회 → 탐사자(작으면 생략·기록) → doc-check ERROR 0 → 커밋 / 새 핸들러 전 "Handler 작성 체크리스트" 필독 게이트 / **Studio 실측은 엔진 대면 델타가 있는 단위에만**) / (b) 다른 방식 | **(a)** | 골격은 M2~M6·M10 일곱 구간에서 검증됐다. Modifier 런타임은 순수 Lua라(정본 "런타임은 클래스별 코드 없이" 절) Studio 축은 flatten이 `D`에 배선되는 단위에서만 의미가 있다 |
| **Q2** | 단위 절단 | (a) **세 단위**: ① `quad-base/src/Modifier.luau` — 값 런타임 전부(`Modifier()` 바닥 생성자, 제네릭 `__index` 필드 setter — 내부 저장소 `FieldsKey` + `table.clone` 둘, 리터럴/함수 × plain/State 4분기, 핸들러 계층 값 즉시 error, 예약 메소드 `Apply`/`Peek`/`Overridden` 우선, `Modifier.Overridden` 닷·콜론, `isModifier` 브랜드) + `spec.modifier`(M2 가드를 실물 Modifier로 재확인 포함) → ② flatten + `ProcessedModifier` 센티널 + `Dispatch/Modifier.luau`의 `ProcessedModifierHandler`(정본 `H-35` 의사코드 그대로) + `D` 파이프라인 ③·`Claim` 봉합(Q4) + `spec.flatten`·Studio 실측(Modifier 든 `D.Frame{}`가 실물에서 프로퍼티로 앉는가) → ③ 생성기 확장(`gen-d.py`) — 클래스별 `<Class>Modifier` 타입(`T' = T \| Tween<T>` 치환, `Parent` 제외 — 덤프 층이 이미 뺐음, 예약 메소드 셋 제외, Q3의 노출 표면) + `<Class>Elem`에 합류 + quad-types `Quad`의 `Modifier` 필드(`H-25`) + strict spec / (b) 둘로(런타임+flatten / 생성기) / (c) 다른 절단 | **(a)** | ①은 정본 3·4·8·9절의 1:1 전사라 독립 spec으로 닫히고, ②는 디스패치 배관(새 핸들러 + 파이프라인 봉합)이라 체크리스트 게이트와 Studio 축이 따로 붙는 게 맞으며, ③은 M5 생성기 선례(단위 ②)처럼 타입 표면만의 단위다 |
| **Q3** | **타입드 Modifier 생성자의 노출 표면**(새 이름 — 사용자 결정 필요). 정본은 "제네릭 생성자 + 클래스별 정적 필드" 패턴 재사용(5절)과 `D.FrameModifier`류 타입 접두만 적었고, 사용자가 `FrameModifier` **값**을 어떻게 얻는지는 미정 | (a) **`q.D.Modifier.Frame()`** — `D.Mapper`와 같은 자리(생성기가 클래스별 캐스트 별칭 `D.Modifier.<Class> = Modifier :: () -> <Class>Modifier`를 찍음; 런타임은 base `Modifier()` 하나) + 타입 `D.FrameModifier`류는 `<Class>Modifier`로 export / (b) `q.Modifier<<Frame>>()` 제네릭 인스턴스화(타입만 바뀌고 값은 같음 — 이중 꺾쇠 관례) / (c) `q.Modifier()` 하나만 두고 사용자가 `:: FrameModifier` 캐스트 | **(a)** | `D`가 "quad-* 전반의 declare 요소"로 확장 가능하다는 이름 확정 근거(bind-system "네임스페이스 이름은 `D`") 그대로이고, `D.Mapper.<Class>`가 "본체 하나 + 클래스별 캐스트 별칭" 선례를 이미 세웠다. (b)는 매 호출 타입 인자, (c)는 풀 타이핑 약속에 구멍 |
| **Q4** | **flatten의 호출 주체** — 정본 파이프라인은 `New`의 ③(`D` 안)인데, flatten은 base 로직(Modifier가 quad-base)이고 `Claim`은 `drive`를 직접 부른다(봉합선 미정, `Claim.luau` 헤더) | (a) **`Dispatch.drive`가 첫 pre-pass로 flatten을 소유** — `New` ③은 `drive` 호출로 흡수(항등 `flatten` 제거), `Claim`은 손대지 않아도 자동 봉합. drive가 이미 `Pre`/`PostRef` 소진 pre-pass를 소유하는 구조(bind-system `drive` 의사코드)와 동형 / (b) `quad.flatten`을 공개해 `New` ③과 `Claim`이 각자 부른다(정본 파이프라인 문구 그대로, 호출 자리 둘) / (c) 다른 방식 | **(a)** | 호출 자리가 하나면 `Claim`류 새 진입점이 생겨도 빠뜨릴 수 없다(`H-35`가 잡은 "색인에서 빠져 존재를 놓치는" 실패형의 구조적 예방). flatten은 `inst`를 안 받는 순수 변환이라 drive 안 어디에 있어도 의미가 같다. 정본 파이프라인의 ③④ 서술은 "③이 ④ 안으로 들어갔다"로 정정하면 되고 확정 역전은 아니다 |
| **Q5** | **상위 클래스 Modifier 타입**(`GuiObjectModifier` 등 — 정본 9-2가 서브타입 합성 우려의 전제로 든 것)을 생성할지 — D 스코프는 creatable 클래스뿐이라 추상 상위 클래스는 지금 생성 대상이 아니다 | (a) **지금은 D 스코프 클래스만**(`Overridden`이 `any`라 런타임 합성은 어차피 자유, 상위 클래스 프리셋 타입은 관측된 필요가 생기면 그때 — 설계 원칙 첫 항목) / (b) 상위 클래스도 같이 생성(`GuiObject`/`GuiButton`/`GuiBase2d`… — 각 필드 유니언을 상속 체인에서 계산) / (c) 다른 방식 | **(a)** | 스파이크 `09`가 서브타이핑이 어차피 안 선다고 실측했으므로 상위 타입을 찍어도 `Frame { guiObjectMod }`가 타입을 통과하지 않는다 — 생성해도 얻는 게 `Apply` 팩토리 시그니처의 명목뿐이라 실측 요구가 오기 전엔 비용만 든다 |

**⭐ [2026-09-04 회신 — 확정]** 사용자 원문: *"다른 부분은 다 권고대로
괜찮은데, Q5는 약간 애매한 부분이네. 보면 textbutton/textlabel 전부 Boldify
같은걸 쓸 수 있어야 할텐데, 안 해두면 둘 다 따로 만들어야 하는 부분이라서.
상위 클래스에 대해서 생성하는건 있을 필요가 있긴한 부분이라 생각해. 다만
지금 당장 할 필요가 있냐 하면 그건 아닐 수 있어. 실 사용에 영향을 주지만,
당장 개발에 다음 부분에 영향을 주는 부분은 아니긴 해. 그러나 최종 개발에
있어 적용되어야할 방식은 지금 권고대로 끝나는건 아쉬울 수 있다, 정도만
짚어주고 싶어"* — **Q1~Q4 권고 (a) 채택. Q5는 (a)로 착수하되 "보류"가
아니라 "후순위 확정"**: 상위 클래스 Modifier 타입(`TextButton`/`TextLabel`이
공유하는 `Boldify` 같은 프리셋의 타입 자리)은 최종 설계에 **있어야 하는
것**이고, M7 안에서 하지 않을 뿐이다 — `ROADMAP.md` M7 후순위 항목으로
등재(그때 스파이크 `09`의 "setter 반환이 자기 타입이라 서브타이핑이 안
선다" 한계를 어떻게 넘을지 — 상위 타입 팩토리가 하위 Modifier를 받는
메커니즘 — 가 함께 결정 대상). 착수 세션은 M5 관례대로 착수 조건(정본 절
↔ 부품 맞물림)을 검증 후 단위 ①에 착수한다.

## §1 범위 — 세 단위 (제안, Q2)

소스는 `ROADMAP.md` M7 체크박스(전부, 상세는 거기가 소스)와
`base/modifier-plan.md` 전 절. 정본 절:

1. **단위 ①** — `quad-base/src/Modifier.luau`. 3절(immutable + `table.clone`,
   `Modifier()` 바닥 생성자), 4절(setter — 리터럴/함수, `__index` 내부 저장소
   ⚠️ 블록, 핸들러 계층 값 error — `isRef`/`isPreRef`/`isPostRef`/`isObserver`/
   `isEffect`/`isSlot`/`isModifier` 중 M7 시점에 브랜드가 실재하는 것 전부,
   `State<Ref>`류 안쪽은 UB로 문서화만), 4-1절(4분기 표), 8절(`Apply`),
   9절(`Overridden` 닷·콜론, `Peek` 반환 `T | State<T> | None | nil`,
   예약 셋 우선), 2-1절(`None` 실재값·`nil`은 필드 부재). `H-238`: 공개 표면
   태깅. `spec.modifier`엔 M2 가드 재확인(`Source(mod)`/`:Set(mod)`/`:Compute`
   결과 `mod` → error)을 넣는다.
2. **단위 ②** — flatten(정본 의사코드: 역순 `for`, `~= nil` 건너뛰기,
   `ProcessedModifier` 소진, in-place) + `Dispatch/Modifier.luau`
   (`ProcessedModifierHandler` — `H-35` 의사코드: 매우 높은 우선순위,
   `v == ProcessedModifier`, `setOffsetSource(None)` → `setLength(0)` → `Void`)
   + Q4의 봉합. 착수 전 "Handler 작성 체크리스트" 필독 게이트. `H-39`
   부기 등록(길이 0)과 배열→해시 순서(`F-4-1`) 위에서 인라인 우선·나중
   modifier 우선을 spec으로 핀. Studio: `D.Frame { mod, Size = … }`가 실물
   프로퍼티로 앉고 형제 자식 오프셋에 영향 없음.
3. **단위 ③** — `gen-d.py`: `<Class>Modifier` 타입(필드 setter 시그니처
   `(self, value: T' | State<T'> | ((old) -> …)) -> <Class>Modifier`의 정확한
   모양은 정본 4·4-1·10절 — 함수 인자 타입은 `typing-limits` §1 관례대로
   명시 주석 전제) + Q3 표면 + `<Class>Elem`에 `<Class>Modifier | State<…>`?
   — **`State<Modifier>`는 7절이 error로 확정했으므로 `E`엔 Modifier 값만**
   넣는다(`State<<Class>Modifier>`는 타입에서도 빼서 정본과 맞춘다) +
   quad-types `Quad.Modifier`(`ModifierConstructor` — `Overridden`은
   `(...any) -> any`) + strict spec(`spec.modifiertypes` — `spec.onchangetypes`
   관례). 규모 캐비엇은 M10이 실측한 `LuauSubtypingIterationLimit`이 이미
   test.sh에 있다(typing-limits 8.7).

**미리 알려진 주의**: ① 필드 값은 `self` 리터럴 키에 절대 저장하지 않는다
(정본 ⚠️ 블록 — 재호출 패턴에서 `attempt to call a number value`). ②
`Overridden`/`Apply`/`Peek`는 예약 필드 — 생성기 제외 목록에 셋 다.
③ `mod:X(nil)`은 "필드 없는 새 Modifier", `None`만이 unsetter(2-1절 `M-5`).
④ flatten은 새 테이블을 만들지 않는다(in-place, 사용자 판정). ⑤ `Tween<T>`는
Modifier 필드로 담겨도 setter가 그대로 baked 저장(10절) — 판단은 M11
PropertyHandler 몫이라 M7 런타임에 Tween 인지 코드 0. ⑥ error 계약(메시지
영어, `errorBeforeNearest`/`errorBefore` 삼분, 테이블 경유 호출 함수에만 태그
`H-250`).

## §2 세 갈래 / §3 리뷰·감사 발견 / §4 관여 시점 / §5 탐사자 지시

M5 규약(`m5-implementation-round14-brief.md` §2~§5 = M4 = M3 준용본) 준용.
치환: 발견 문서는 `m7-implementation-round17.md`(`H-309`부터), 머리말 문구는
"M7 진행 중", 탐사자의 대조 중심 절은 `modifier-plan.md` 3·4·4-1·8·9절 /
"flatten의 정확한 형태" 절(의사코드 둘) / `dispatch-core-plan.md`의
Length/Offset 등록 책임 열거 / `architecture.md` 소스 트리 `Modifier.luau`
두 줄. M2~M6·M10 하자는 동형 규칙(경미하면 round17에 ①, 설계 결정
규모면 그 시점 다음 번호로 해당 마일스톤 라운드 신설). **[M7 변경]**
Studio 실측은 Q1 (a)대로 단위 ②에만 기본 — 단위 ①·③은 CLI로 닫히면
생략하고 발견 문서에 "생략" 기록.

## §6 단위 작업 계획 (승인 대상 — Q2 (a) 기준, 단위 ① 상세만 먼저)

| 파일 | 내용 | 옮겨 적는 절 |
|---|---|---|
| `quad-base/src/Modifier.luau` | `Modifier()` + 공유 메타테이블(고정 메소드 테이블 `Apply`/`Peek`/`Overridden` 먼저, 없으면 필드 setter 클로저 합성) + 내부 저장소 `FieldsKey` + 4분기 setter + 핸들러 계층 값 error + `ModifierBrand` 등록 + `H-238` 태깅. `flatten`/`ProcessedModifier`는 단위 ②(같은 파일에 두되 export는 ②에서) | 3·4·4-1·8·9·2-1절, `luau-test/done/17` 구조 |
| `quad-base/src/init.luau` | `Modifier` 필드(`Quad` 타입은 단위 ③에서 — 그 전엔 `H-25` 관례대로 마일스톤 말미 갱신) | `architecture.md` 최상위 export |
| `quad-base/test/spec.modifier.luau` | 바닥 생성자·immutable(원본 불변)·4분기·`None` vs `nil`·예약 메소드·핸들러 계층 값 error·`Overridden` 순서·`Peek` raw·`Apply` = `factory(self)`·M2 가드 재확인·blame | — |

**커밋 단위**: 단위당 커밋 하나 + 단위 끝 절차(M2~M6·M10 관례). 단위 ②·③의
상세 표는 각 단위 착수 시점에 §6에 이어 쓴다.

**[2026-09-04 후속] Q5 후순위는 같은 날 단위 ④로 닫혔다** — 상위 클래스 Modifier
타입(스코프 클래스의 조상 전부 — 개수는 `modifier-plan.md` 11절이 소스)이 검사형 `As<Desc>()`·`Into<Class>`와 함께 생성된다. 경위는
round17 `H-314`, 정본은 `modifier-plan.md` 11절.
