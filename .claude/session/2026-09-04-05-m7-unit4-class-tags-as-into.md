# 2026-09-04 (05) — M7 단위 ④: 클래스 태그·`Define`·`As`·`Into`·상위 클래스 Modifier

> 원문 로그. 정본은 `base/modifier-plan.md` 11절(구성), `base/typing-limits.md`
> 8.8·8.9절(솔버 규칙), `audit/m7-unit4-as-modifier-2026-09-04.md`(실측),
> `archive/v2-initial-implementation/m7-implementation-round17.md` `H-314`(발견 원장). 이 파일은 대화의
> 흐름과 사용자 발언 원문만 남긴다.

## 1. 출발 — 사용자 제안 스파이크 둘

§4 회신 반영(`392326f`) 직후 사용자가 둘을 제안했다 — *"__quadModifier 를 string
으로 두고 허용되는 목록을 E | { __quadModifier: "...Modifier" } | {...} 형태로
두는걸로 갈 수 없어? 그리고 지금 형태에서는 D 출력물 결과가 여러 같은 공유되는
Props 가 아주 남발되는데 (예: Archivable 등) 그건 바깥에서 & 하면 될 것으로
보이는듯. { [number]: E | ... } & TextBase... 가 되는게 맞는지 실측하고 도입을
고려해볼래?"* 컨텍스트 83%라 커밋 뒤 compact를 먼저 돌리고 착수했다.

스크래치 생성기(변형 D 여러 벌)로 실물 규모를 찍은 결과:
- 문자열 마커 유니언은 네 변형 전부 too complex 없이 2.9s 통과 — 그런데
  **음성이 하나도 안 잡혔다.** 격리 12조합으로 규칙을 찾았다: 서브타입의 자기
  참조 함수 필드 + 유니언 멤버의 같은 이름 함수 필드 → 통과. `Tag.Apply`/
  `State.Apply` ↔ `<Class>Modifier.Apply`가 그 자리. `Apply`를 `(self: any,
  factory: (any) -> U)`로 두면 닫힌다(`self: any`만으론 factory 인자의 재귀로
  샌다).
- 교집합 Param은 양성이 전부 에러(`{}`조차) — 인덱서 conjunct가 문자열 키를
  거부. 시간도 차이 없음. 도입 불가.

보고 뒤 사용자: *"그렇다면, 차라리 :As<T>() -> T 를 제공해야겠다 싶어. …
상위 Text 부분에 있어서는 :As<<TextLabel>>() 이 가능한거지. … Params 부분에
있어서는 그냥 겹치는 부분의 비용을 무시하고 전부 인라인으로 두고, E| 부분만
잡는건 가능해? apply 의 재귀를 포기하고 다른 부분의 편의를 택하는건 동의해.
apply 보다 이게 더 편의가 높거든."*

## 2. `As` 모양 실측

상위 클래스 Modifier(조상 16종)를 같이 생성해 네 모양을 대조 — 문자열 인자형
(`K & keyof<Descendants>` + `index<>`)과 오버로드 교집합은 선언부 too complex
(플래그 10종 무효), **클래스별 메소드 `AsTextLabel()`만 통과**(음성 9/9), 무검사
`As<<T>>()`는 통과하되 검사 없음. 상위 클래스 캐스트 자리와 상위 팩토리 `Apply`
자리가 `LuauTypeInferIterationLimit`에 걸려 100만 핀(3.2s).

사용자: *"AsXXX 형식은 단편적으로 보면 자동완성도 돕고, 바꿀 수 있는게 뭐가
있는지 바로 보여서 좋은 생각이야. 그러나 한가지 단점, 상위 요소가 하위 요소를
알아야해, 그리고 상위 요소를 바꾸지 않으면 하위 요소를 못 만들어. … D 에
없는걸 만들어야 해서 확장해야하는 경우 걸림이 될 수 있어. 따라서 :As 무검사
방식도 같이 있어야한다고 보여. 그리고 Rust 처럼 Into 같은걸 제공할 수 있게
될것 같아. 예를 들어 {AsTextLabel} 을 만족하는 모든 것에 대해서 받아 처리하는걸
만들 수 있지. 일종의 인터페이스화야. … 자기 자신으로 TextLabel 이 AsTextLabel
도 구현한다면 좋을 수 있어(특히 텍스트 처리자를 보면 그러함). 후행에서는 Into
를 거쳐 As....:As목적지 로 옮겨갈 수 있지."*

실측: `Into<Class> = { As<Class>: (self: any) -> … }`가 상위·항등·커스텀 구현체를
받고 불만족을 거부, `self`는 `any`여야 함. 상향 `As<Ancestor>`까지 넣으면
왕복은 되지만 3.1s → 8.5s — 하향+항등만 권고, 사용자 동의.

## 3. 런타임 — "As가 프로퍼티처럼 동작하면 안 된다"

사용자: *"그냥 :As... 를 막아두지 않으면 프로퍼티처럼 작동할 수 있게됨을
생각해보아야해. As로 시작하는건 전부 Cast 프리디파인드로 두고 시작해야할것
같아. 문제는 런타임에서라도 에러를 내려면 뭔가 큰 개편이 필요해보이는 시점.
… 지금은 타입도, 런타입도 잡아주지 못하는 문제가 생길 것으로 보이는게 약간
문제야."* — 옛 런타임에선 `m:AsTextLabel()`이 setter 클로저를 받아 필드
`AsTextLabel = nil`의 조용한 no-op이었다.

첫 제안: `^As%u` 접두를 base에서 예약 + 캐스트 검증 자료(클래스 → 조상 표)는
**프로바이더가 `EngineOps`처럼 주입**. 사용자가 되돌렸다 — *"내가 MaterialButton
를 만들었고, 거기에 대한 MaterialButtonModifier 도 만들었다고 쳐. … 엔진 단에
그걸 가능하게 둔다는건 커스텀 modifier 를 허용하지 않게 된다는 말이 될 것
같아. Modifier 자체는 어느 엔진이든, 가상객체에 대한 상태이든 포괄해. …
preref, ref, postref 를 추출하고 modifier 를 flatten 한 테이블을 만들어주는
슈거 함수로 나중에 외부에 둘 생각이였지. … 그런 확장성을 막을것 같아."*

수정안(사용자 승인 *"좋아, 그 수정안으로 착수해"*): 레지스트리는 base의 공개
API `Modifier.Define(name, parent?)`이고 프로바이더는 첫 사용자일 뿐; 커스텀
Modifier는 타입 별칭 + Define 한 줄; 컴포넌트가 무엇을 받을지는 자기 param
타입(`Into<…>`); 무검사 `As`에 이름 인자(존재 검사만); 레지스트리는 모듈 수준.

## 4. 구현

- `quad-base/src/Modifier.luau`: 태그(`true` | 클래스명), `Define`(부모 먼저,
  재등록 idempotent, 생성자 반환 — 병합 본문 `construct` 공유), `methods.As`
  (무검사), `__index` 순서 예약 메소드 → `^As%u` 캐스트 클로저(미등록/비조상
  error — 처음엔 손 카운트 level 3이었고 5절의 리뷰로 태그 클로저 +
  `errorBeforeNearest`가 됨) → setter(태그 유지), `Overridden`
  무타입, `retag`는 frozen fields 재동결 회피.
- quad-types: `Apply` any, `As`, `ModifierClassConstructor`/`Define`.
- `gen-d.py`: normalize가 `chain`/`owner` 기록 → emit이 조상 16종 Modifier 타입
  (하위 `As<Desc>`+항등+무검사 `As`, `Into<Class>`), `<Class>Elem` 조상 체인 마커,
  `DModifier`/`ModifierNS`는 `Define` 체인 깊이 순, 게이트 셋. test.sh
  `LuauTypeInferIterationLimit=1000000`.
- spec: `spec.modifier` 9~12절, `spec.modifiertypes` 재작성, `spec.d`(새 솔버
  `type(x) == "function"` 좁힘이 호출을 막는 함정 — 변수 분리), luau-test
  `31`. 실물 음성 12/12, Studio 8/8(첫 FAIL은 스모크의 상향 오기).
- `H-313` 소멸, Q5 닫힘, ROADMAP M7 `[ ]` 0 — **M7 완료.** 확인 항목 `H-314`
  (Define이 생성자를 돌려줌 — 에이전트 재량).

## 5. 끝 절차

감사 2라운드(6건 → 8건 중 7건 반영, research 분류는 후순위 관례로 보류),
`/code-review medium` 5건 — 생성기 게이트의 정규식 둘이 실제로 아무것도
못 잡고 있었다(defs의 `with` 접미, 한 줄 선언 넘침) → 균형 파싱 + 못 찾으면
`SystemExit`; 죽은 루프 제거; `castTo`의 손 카운트 레벨을 대상별 캐시·태그
클로저 + `errorBeforeNearest`로(`H-231` 계약); 단일 이름 공간은 11절에 문서화.
doc-check ERROR 0, test.sh 38 파일 통과.

## 6. `Define` 분리 — 사용자 결정

확인 항목 설명을 듣고 사용자: *"Define 은 단순해져야해. 하나의 동작만 하도록
만들고 싶어. 갈래 상 다중상속을 전혀 지원하지 않는게 일반적이지만.(로블록스 엔진
기준) 인터페이스를 쓴다던가 등 해서 여럿을 Define 으로 넣고 싶다면? modifier
자체는 그게 지원 될 수 있다고 봄. 값이 있거나 없을 수 있고, 서브타입으론 멀쩡히
계속 내려가거든. 따라서 DefineSubtype(Parent, Subtype) 처럼 서브타입이 내려가는
구조에, TypedFactory<T>('name') -> T 식이 되는게 맞다고 봐. … 나머지는 다
괜찮아보여. 그리고 Dedup 은 되는거겠지?"* → `TypedFactory<<T>>(name)` +
`DefineSubtype(parent, subtype)`(부모 여럿, 순서 자유, 순환만 거부, 둘 다 dedup).
부수로 재량 항목 2("다른 부모 재등록 error")·3("부모 먼저")이 사라졌고, 나머지
재량은 사용자 수용 — round17 §4 열린 문항 0. Studio 8/8 재실측.

