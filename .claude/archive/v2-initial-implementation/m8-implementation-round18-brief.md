# M8 자율 구현 규약 — 18라운드 지시서 + 착수 문항지

> **이 파일이 무엇인가**: **[2026-09-04 신설, 같은 날 §0 확정]** M8(Ref /
> PreRef / PostRef) 구현 구간의 규약이자 착수 문항지다. M7의
> `m7-implementation-round17-brief.md`와 같은 지위 — §0이 확정되면 이 파일이
> M8 규약 소스다. 산출물(발견 문서)은 `m8-implementation-round18.md`. 사용자
> 지시(2026-09-04, M7 완료 직후): *"M8 규약 문항지를 쓰자"*.
>
> **명명**: `mN-implementation-roundNN` 규약 그대로 — M8의 첫 라운드가
> **round18**, 발견 번호는 메인 직렬 라인이 round17에서 `H-314`까지 썼으므로
> **`H-315`부터**.
>
> **전제(이미 충족)**:
> - `Ref` 최소형은 **M2가 이미 구현**했다(`quad-base/src/Ref.luau` +
>   `spec.ref` — `.Value`/`.Revision`/`:Set`/`:Callback`/`:WeakCallback`/
>   `:Uncallback`/`isRef`/`EpochBrand`, ROADMAP M2 "공통 기반" 체크박스).
>   `Effect`의 `Ref` dep 분기가 이걸 실제로 타고 있다. M8이 얹는 것은
>   **`:Wait`, `PreRef`/`PostRef`, 디스패치 핸들러 넷, drive의 pre-pass**뿐.
> - 브랜드 `PreRefBrand`/`PostRefBrand`/`isPreRef`/`isPostRef`는 `Brand.luau`에
>   이미 있고(`isRef`는 셋의 합), `Dispatch/init.luau`의 `drive`는 M8 자리를
>   주석으로 비워 뒀다(*"(a) PreRef/PostRef pre-pass and (c) postRefList join
>   in M8"* — flatten pre-pass 바로 뒤, 배치 판정 앞).
> - `bindLifetime`/`unbindLifetime`/`canBound`는 M5가 quad-roblox에 실물로,
>   `quad-base/test/mock.luau`가 mock 백엔드로 갖고 있다 — `RefLeafHandler`의
>   이중 배치 가드는 그 위에 얹기만 한다(정본 "이중 배치 방지" 절).
> - `Processed*Handler` 셋의 원형은 M7 단위 ②의 `Dispatch/Modifier.luau`
>   (`ProcessedModifierHandler` — `setOffsetSource(None)` → `setLength(0, inst)`
>   → `Void`)이고 정본 의사코드가 "한 글자 차이"라고 못박은 그 모양이다.
> - 정본 `base/ref-plan.md`엔 열린 질문이 없다. 단, 정본 자신이 **M8로
>   미뤄 둔 판단이 하나** 있다(`RefLeafHandler` 재진입 UB — §0 Q4).
> - **범위 밖**: `OnCreated`/`OnRendered`/`OnDestroyed` 훅 슈가는
>   `base/lifecycle-hooks-plan.md`대로 백로그(순수 팩토리 슈가 — M8 프리미티브
>   위에 나중에 얹는다). `D` 생성기는 §0 Q3의 타입 표면 외엔 손대지 않는다.
>
> §2~§5는 M7 규약(= M5 = M4 = M3 준용본)을 준용하고, 다른 자리에만 `[M8 변경]`
> 표시.

---

## §0 ⭐ 착수 문항 (배치 회신용)

| 문항 | 무엇 | 선택지 | 권고 | 권고 근거 |
|---|---|---|---|---|
| **Q1** | 규약 재사용 범위 | (a) M7 골격 그대로(세 갈래 / 커밋 게이트 두 층 / 단위 끝 절차 = 감사 루프(유한, 각도 교대) → `/code-review medium` 1회 → 탐사자(작으면 생략·기록) → doc-check ERROR 0 → 커밋 / 새 핸들러 전 "Handler 작성 체크리스트" 필독 게이트 / Studio 실측은 엔진 대면 델타가 있는 단위에만) / (b) 다른 방식 | **(a)** | M2~M7·M10 여덟 구간에서 검증된 골격. M8은 핸들러 넷 + pre-pass라 체크리스트 게이트가 특히 무겁다 |
| **Q2** | 단위 절단 | (a) **세 단위**: ① `Ref.luau` 나머지(`:Wait(thread?)`) + `PreRef.luau`/`PostRef.luau`(Ref 런타임 재사용 + 브랜드 태그 + `_fired` 1회용 가드, children 배열 전용) + quad-types `PreRef<T>`/`PostRef<T>` 타입·`Quad` 필드 + `spec.ref` 확장·`spec.preref`(순수 Lua) → ② 디스패치 — `RefLeafHandler`(`Ref.luau`가 등록 소유, `H-278` 형: `isHandlable = number k ∧ isRef ∧ ¬isPreRef ∧ ¬isPostRef`, `H-39` 부기, `Relate` dedup(`GetWeak`/`SetWeak`), `bindLifetime` 이중 배치 가드, retractor 언바인딩 + `v:Set(nil)`) + `PreRef`/`PostRef` 동적 경로 가드 둘(`HANDLER_PRIORITY_FALLBACK`, `k` 타입 실은 error) + `ProcessedPreRefHandler`/`ProcessedPostRefHandler` + `Dispatch.drive`의 (a) pre-pass(`isPreRef` → 그 자리 fire·`ProcessedPreRef` 소진 / `isPostRef` → `postRefList` push·`_fired`·`ProcessedPostRef` 소진)와 (c) `postRefList` 소비 루프 + `spec.refhandlers`(mock quad) + **Studio**(실물 gcconn 위의 이중 배치·재바인드 언바인딩·`PreRef`가 이벤트 동기 발화보다 먼저인가·`PostRef`가 서브트리 완성 뒤인가) → ③ 타입 표면 — quad-roblox `NewChild`/`<Class>Elem` 확장(Q3)·strict spec / (b) 둘로(런타임 / 디스패치+타입) / (c) 다른 절단 | **(a)** | ①은 순수 Lua라 CLI로 닫히고, ②는 M8의 실체(핸들러 넷·pre-pass·생명주기)라 체크리스트 게이트와 Studio 축이 따로 붙는 게 맞으며, ③은 M7 단위 ③·④ 선례처럼 타입 표면만의 단위이고 Q3의 실측이 앞에 선다 |
| **Q3** | **children 자리의 `Ref` 타입 표현** — `NewChild` 원장(bind-system-plan)이 M8 확장을 예고했지만 모양은 미정. `Ref<T>`는 `Set` 파라미터 때문에 `State<T>`처럼 **불변**이라 `Ref<Frame>`은 `Ref<Instance>`의 서브타입이 아니고(typing-limits 8.7 캐비엇 5), 리터럴 관용구는 `Ref()`(= `Ref<nil>`)이며 재바인드 자리는 `Ref<<T?>>`다. 그리고 **8.9절 결함이 정면으로 걸린다**: `Ref<T>`의 메소드는 자기 타입을 반환하고(`Set`/`Callback`…), children 유니언의 `OnChange` 디스크립터가 같은 이름의 함수 필드 `Callback`을 가진다 → 유니언에 `Ref<…>`를 직접 넣으면 검사가 조용히 통과할 가능성이 높다 | (a) **착수 전 소형 스파이크로 결정** — `luau-test/32`: `<Class>Elem`에 `Ref<<Class>?>`(+ `Ref<nil>`?)를 직접 넣었을 때 (1) 다른 클래스의 Ref 거부 여부, (2) `Callback` 이름 충돌로 새는지, (3) 실물 규모 too complex 여부를 재고 → 새면 M7 단위 ④와 같은 처방(마커 `{ read __quadRef: true }` + 클래스 소속은 `:Set` 자리가 맡는다 — 잃는 것 명시) / (b) 실측 없이 마커부터 / (c) 실측 없이 `Ref<Instance?>` 하나만 | **(a)** | M7 단위 ③·④가 "유니언에 재귀 테이블"의 함정을 두 번 밟았다 — 이번엔 이름 충돌 조건(`Callback`)이 이미 보이므로 먼저 재고 정한다. 스파이크 결과는 발견(`H-315`~)으로 기록하고, 마커로 가야 하면 그 자리에서 사용자 확인 |
| **Q4** | **`RefLeafHandler` 재진입 UB**(정본 의사코드 안의 M8 유보 사항, round12 §6 `H-286` 잔여) — `v:Set(inst)`가 사용자 콜백을 `relate:SetWeak` **전**에 동기 실행하므로, 그 콜백이 같은 `(inst, k)`를 같은 `v`로 재귀 재디스패치하면 `old ~= v`가 참으로 보여 `bindLifetime`의 `canBound` 가드가 크래시한다 | (a) **`relate:SetWeak(inst, k, v)`를 `v:Set(inst)` 앞으로**(`bindLifetime` → `SetWeak` → `Set`) — 재진입 시 `old == v`로 dedup에 걸려 안전, 순서 변경 한 줄이고 새 구조 없음 / (b) 기존 원칙("일반적인 재진입/무한루프는 방어 안 함")으로 UB 문서화만 / (c) 다른 방식 | **(a)** | (b)의 원칙은 "방어에 구조를 쓰지 않는다"인데 (a)는 구조가 아니라 **이미 있는 두 줄의 순서**다. 정본 의사코드 순서를 바꾸는 것이라 확정 정정이 필요해 문항으로 올린다 |
| **Q5** | **`:Wait(thread?)`의 "이미 채워짐" 처리** — 정본은 시그니처(`thread` nil이면 `coroutine.running()` 캡처 + yield, 있으면 등록만 하고 self 반환)와 관용구 `if ref.Value then ref.Value else ref:Wait().Value`만 적었고, 채워진 Ref에 `Wait`를 부르면 어떻게 되는지는 침묵 | (a) **항상 다음 `:Set`까지 기다린다** — 관용구가 `if ref.Value` 선검사를 전제하고, `Ref<<T?>>`에서 `nil`은 정당한 값이라 "채워짐"을 런타임이 판정할 수 없다 / (b) `.Value ~= nil`이면 즉시 self 반환 / (c) 다른 방식 | **(a)** | `:Callback`의 "등록 즉시 1회 호출"과 달리 `Wait`는 스레드를 멈추는 연산이라 조건부 반환은 호출부 흐름을 두 갈래로 만든다. (b)는 `nil`이 값인 Ref에서 영원히 기다리는 것과 즉시 반환이 뒤섞인다 |
| **Q6** | `PostRef` 발화와 **부모 부착 순서**의 실물 확인 — 정본은 "자기 서브트리 완성은 보장, 부모에 붙는 것보다 먼저"를 문서화 필수로 못박았다 | (a) 단위 ② Studio에서 `Frame { Frame { PostRef():Callback(fn) } }`로 콜백 시점의 `.Parent`가 `nil`임을 실측해 audit에 남긴다 / (b) 문서만 | **(a)** | 이름(`OnRendered`)이 오해를 부르는 자리라 정본이 실측 요구를 이미 적어 뒀고, Studio 세션이 어차피 열린다 |

**⭐ [2026-09-04 회신 — 확정]** 사용자 원문: *"Q3: 좋음. 마커필드로써 노미널
타이핑 하는건 quad에서 흔한 동작이 되어서, 동의함 / Q4: 동의. 다른 내가 못
본 동작 변이가 있는지만 보고, 괜찮다면 택해줘 / Q5: 항상 기다리면 돼. 그럴
땐 Option/Monad 같은 값을 제공하면 된다고 생각함 Just/Some, Nothing/... 우리
입장에선 Just/Nothing 이 좀더 맞겠지만, 사실 당장 필요하지도 않고 유저가
간단히 만들어 주입 가능한 타입임 … 좀더 명문화 하고 싶으면 개념을 직접
도입시켜주면 돼 / Q6: 사실, '먼저다' 는 아니긴 함. Claim 을 건다던가, 어딘가
이미 Parent 가 셋팅 되든 우린 상관 안 함. 우리가 정의할 수 있는건 단지
자식이 다 붙은 다음이지, 부모에게 붙었을 지 안 붙었을 지 그건 보장하는 바가
아님. 기본적으론 안 붙는게 맞다는건 맞지만. | 언급 안 한 부분인 Q1, Q2 는
괜찮은듯"* — **Q1~Q5 권고 (a) 채택. Q6는 문항의 전제가 정정됐다**: 실측은
하되 계약은 "부모 부착 여부 무보장"(정본 "`PostRef`" 절·ROADMAP 정정 반영).
Q4는 지시대로 다른 동작 변이를 훑었다 — 같은 v 재진입만 고쳐지고, 다른
v'로의 재진입은 순서와 무관하게 기존 UB 그대로, 콜백 error 중단은 no-pcall
계약상 실질 차이 없음 → (a) 채택, 정본 의사코드 순서 정정 반영. Q5의 Option
값은 정본 "API 모양" 절에 사용자 논거와 함께 "필요 시 사용자 결정"으로 등재.

## §1 범위 — 세 단위 (제안, Q2)

소스는 `ROADMAP.md` M8 체크박스(전부, 상세는 거기가 소스)와
`base/ref-plan.md` 전 절. 정본 절:

1. **단위 ①** — `Ref.luau`의 `:Wait(thread?)`("API 모양" 절 + Q5) — 대기자는
   `.Callbacks`에 thread 키로(`:Set`이 이미 thread 키를 소진·`resume`한다),
   `PreRef.luau`/`PostRef.luau`("`phase` 옵션 폐기 → 위치로 표현, `PreRef`
   신설" 절 / "`PostRef`" 절 — Ref 런타임 그대로 + 브랜드 + `_fired`, 재사용
   즉시 error, 생성자는 `PreRef(default?)`/`PostRef(default?)`), quad-types
   (`PreRef<T>`/`PostRef<T>` nominal 별칭 + `Quad.PreRef`/`Quad.PostRef` —
   `H-80` 탑레벨 목록 규칙), `spec.ref` 확장(`Wait` yield/resume·self 반환·
   dedup·thread 소진과 콜백 공존) + `spec.preref`(브랜드 삼분·`_fired`).
2. **단위 ②** — 정본 "`Ref`의 retract" 절(`RefLeafHandler` 의사코드 1:1 +
   Q4), "이중 배치 방지" 절, "PreRef" 절의 pre-pass·`ProcessedPreRefHandler`·
   동적 경로 가드, "`PostRef`" 절·"동적 경로 가드 Handler도 거울상으로 하나
   더" 절, `dispatch-core-plan.md`의 Length/Offset 등록 책임·핸들러 체인(A)
   분기, `lifecycle-pattern.md`의 `bindLifetime`/`canBound`. 등록 소유는
   `H-278` 형(각 모듈이 자기 핸들러를 등록 — `Ref.luau`/`PreRef.luau`/
   `PostRef.luau`, `InitDispatch`가 호출). 착수 전 "Handler 작성 체크리스트"
   필독 게이트. Studio 축은 Q2·Q6.
3. **단위 ③** — Q3의 결과대로 `quad-roblox/src/types.luau` `NewChild` 또는
   `<Class>Elem`(생성기) 확장 + `<Class>MapperElem`(Claim 자식 자리도 같은
   별칭) + `spec.reftypes`(strict 양성; 음성은 스파이크 `32`) — M7 단위 ③·④
   선례. **[2026-09-04 결과]** `<Class>Elem` 쪽(`<Class>RefMarker`), `NewChild`는
   그대로 — `H-321`/`H-322`.

**미리 알려진 주의**: ① 세 Ref의 매치는 서로소 — `RefLeafHandler`는
`isRef ∧ ¬isPreRef ∧ ¬isPostRef`, 가드 둘은 각자 `isPreRef`/`isPostRef`,
`Processed*`는 센티널 항등. ② `bindLifetime`은 실제 바인딩 분기(`old ~= v`)
안에서만, `unbindLifetime`은 실제 언바인딩 분기(`nextValue ~= v`) 안에서만
— 밖으로 나가면 spurious 재발행에서 error/이중 해제가 난다(정본 정정
이력). ③ `relate` 정리는 언바인딩 분기 **안**에(정본 2026-08-13 정정).
④ `Processed*` 센티널은 `None`이 아니라 전용 값(`ProcessedModifier`와 같은
frozen+`__tostring` 모양). ⑤ pre-pass는 `flatten` 뒤·배치 판정 앞, 배열
파트 한 번, `Dispatch.process` 우회 raw 루프 — `flatten` 함수에 얹지 않는다
(정본 기각 사유: 재바인드 시 flatten 재호출과 충돌). ⑥ `PostRef` 소비
루프는 본체 루프(배열→해시) **뒤**, 배열 재순회가 아니라 `postRefList`
길이만큼. ⑦ error 계약(메시지 영어, `errorBeforeNearest`/`errorBefore` 삼분,
가드 핸들러는 `errorBefore` 최외곽 스캔 — 정본 명시). ⑧ `Ref`는 Destroy를
모른다(정본 "Destroy와는 무관") — 정리는 `Effect` 몫, M8이 얹지 않는다.

## §2 세 갈래 / §3 리뷰·감사 발견 / §4 관여 시점 / §5 탐사자 지시

M7 규약(`m7-implementation-round17-brief.md` §2~§5 = M5 = M4 = M3 준용본)
준용. 치환: 발견 문서는 `m8-implementation-round18.md`(`H-315`부터), 머리말
문구는 "M8 진행 중", 탐사자의 대조 중심 절은 `ref-plan.md`의 "`Ref`의
retract" 절(의사코드) / "PreRef" 절·"`PostRef`" 절(pre-pass 메커니즘·
`Processed*Handler` 의사코드) / "이중 배치 방지" 절 / `dispatch-core-plan.md`
Length/Offset 등록 책임 / `lifecycle-pattern.md`의 `bindLifetime` 절 /
`architecture.md` 소스 트리의 `Ref.luau`·`PreRef.luau`·`PostRef.luau`. M2~M7·
M10 하자는 동형 규칙. **[M8 변경]** Studio 실측은 단위 ②에만 기본(Q2·Q6) —
단위 ①·③은 CLI로 닫히면 생략하고 발견 문서에 "생략" 기록.

## §6 단위 작업 계획 (승인 대상 — Q2 (a) 기준, 단위 ① 상세만 먼저)

| 파일 | 내용 | 옮겨 적는 절 |
|---|---|---|
| `quad-base/src/Ref.luau` | `:Wait(thread?)`(Q5 (a): `thread` nil → `coroutine.running()`을 `.Callbacks`에 키로 넣고 `coroutine.yield()`, 재개 값은 `:Set`이 넘기는 Ref 자신; 있으면 등록만 하고 self 반환), `H-231` 태깅. `RefLeafHandler` 등록 함수는 단위 ②(같은 파일, `H-278` 형) | "API 모양" 절, `:Set`의 thread 분기(이미 구현됨) |
| `quad-base/src/PreRef.luau` / `PostRef.luau` | `Ref(default)`를 만들고 `PreRefBrand`/`PostRefBrand`를 추가 등록(다중 태깅 — `EpochBrand` 선례), `_fired = false`. 각자의 가드/`Processed*` 핸들러 등록 함수는 단위 ② | "`phase` 옵션 폐기…" 절, "`PostRef`" 절, `brand-plan.md` |
| `quad-types/src/init.luau` | `PreRef<T>`/`PostRef<T>`(구조는 `Ref<T>`와 같고 마커 필드로 nominal — 8.9절 규칙: 유니언 대조는 단위 ③ 스파이크가 정한다), `Quad.PreRef`/`Quad.PostRef` | "타입/판별" 문단 |
| `quad-base/src/init.luau` | `PreRef`/`PostRef` 필드 | `architecture.md` 최상위 export |
| `quad-base/test/spec.ref.luau` / `spec.preref.luau` | `Wait` yield→`:Set`→resume(Ref 자신 받음)·외부 thread 등록·dedup·콜백과 공존 / 브랜드 삼분(`isRef` 셋 다 참, `isPreRef`/`isPostRef` 서로소)·`_fired`·blame | — |

**커밋 단위**: 단위당 커밋 하나 + 단위 끝 절차(M2~M7 관례). 단위 ②·③의
상세 표는 각 단위 착수 시점에 §6에 이어 쓴다.

**[2026-09-04 단위 ① 완료 — round18 `H-315`]** 위 표대로 구현. 부수 발견
`H-316`(정본의 "Modifier 필드 어디든" 옛 문장 한정).

**단위 ② 계획(착수 시 작성, 같은 날 완료 — `H-319`)**

| 파일 | 내용 | 옮겨 적는 절 |
|---|---|---|
| `quad-base/src/Dispatch/Ref.luau`(신설) | `ProcessedPreRef`/`ProcessedPostRef` 센티널, `prePass(inst, flattened) -> postRefList?`(index 순서 한 번 — PreRef: `_fired` 가드·슬롯 소진·`v:Set(inst)`, PostRef: 가드·소진·push), `firePostRefs`, `register(dispatch)`(Processed 둘 — `ProcessedModifierHandler` 모양). **배치 근거**: 센티널은 Dispatch의 개념이고 `Ref.luau`가 Dispatch를 require하므로 Dispatch 쪽이 Ref를 require하면 순환 — M7 `Dispatch/Modifier.luau`와 같은 이유 | "PreRef" 절 pre-pass·`ProcessedPreRefHandler` 블록, "`PostRef`" 절 메커니즘 1~3 |
| `quad-base/src/Dispatch/init.luau` | `drive`: `flatten` 뒤·배치 판정 앞에 `prePass`, 본체 루프 뒤·배치 닫기(⓪') **앞** `firePostRefs`(게이트 켜진 채 — `H-17`); InitDispatch가 Processed 둘 등록 | bind-system 파이프라인 (a)/(c)/⓪', dispatch-core `H-17` 절 |
| `quad-base/src/Ref.luau` | `registerDispatchHandlers`(`H-278`): `RefLeafHandler`(HIGH, `number k ∧ isRef ∧ ¬isPreRef ∧ ¬isPostRef`, `H-39` 부기, `Relate` dedup, `bindLifetime` → `SetWeak` → `Set`(Q4), retractor 언바인딩·`Set(nil)`·조건부 relate 정리), `PreRef`/`PostRef` 동적 경로 가드(FALLBACK, `typeof(k)` 실은 `errorBefore`). 모듈 반환이 `{ Ref, Init }`으로 바뀜 | "`Ref`의 retract" 절, "이중 배치 방지" 절, "동적 경로 가드 Handler도 거울상으로 하나 더" 절 |
| `quad-base/test/spec.refhandlers.luau` | leaf 바인딩·이중 배치·`State<Ref>` 재바인드(spurious 포함)·Q4 재진입·PreRef 호이스팅/순서/부기/재사용·PostRef 순서/부모 무보장/재사용·가드 셋 | — |

**단위 ③(같은 날, `H-321` 확정 뒤 — `H-322`)**: quad-types `Ref<T>`에
`read __quadRefAccepts: (T) -> ()` + 런타임 `Void`, 생성기 `<Class>RefMarker`와
`<Class>Elem` 합류(`+ State<…>`), `spec.reftypes`. **M8 완료.**
