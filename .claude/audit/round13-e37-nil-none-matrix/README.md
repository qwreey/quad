# E37 — `nil`과 `q.None`의 자리별 의미 매트릭스 (2026-09-27, HEAD `b1884617`)

문서가 말하는 것 vs mock 실측 vs strict 타입. 레포 파일 무변경, 이 폴더만 새로 만듦.

## 파일

| 파일 | 무엇 |
|---|---|
| `harness.luau`·`engine-globals.luau`·`s10-config.luau` | `round13-s10-snippet-recheck/`에서 복사. harness만 `COMMON`에 `NextSelectionUp`(객체 참조 프로퍼티) 한 줄 추가 |
| `run-matrix.luau` → `.out` | 1차 런타임 프로브(P/M/E/S/C/SL/T/A/ST/R/CX/O/OP/DS 행) |
| `run-matrix2.luau` → `.out` | 마운트된 Slot 변형·같은 Modifier 안 변환·Operator 단항 올바른 모양 등 보정 |
| `run-matrix3.luau` → `.out` | `:List` 데이터 구멍, OnChange/Observer/Effect 자리 nil, Animate 콜백과 nil |
| `run-setdedup.luau` → `.out` | `Source:Set`이 같은 nil/None에도 전파하는지(한다 — 1차 ST6의 fires=1은 Subscribe 안 한 프로브 결함) |
| `strict-matrix*.luau` → `*.out` / `*.full.out` | luau-lsp 신 솔버, test.sh 한도 플래그 셋 그대로. 줄 번호 → 행 라벨은 각 줄 주석(T*/U*/W*) |
| `strict-tagcall.luau`·`strict-out.luau` | `q.Tag(...)` `__call` 무검사 재확인, 객체 참조 읽기 표면 |

실행: `luau .claude/audit/round13-e37-nil-none-matrix/run-matrix.luau`(레포 루트에서, `relink.sh` 뒤),
strict는 `mise exec -- luau-lsp analyze --flag:LuauSolverV2=true --flag:LuauTarjanChildLimit=160000 --flag:LuauSubtypingIterationLimit=100000 --flag:LuauTypeInferIterationLimit=1000000 --definitions=scripts/roblox-defs/globalTypes.d.luau --ignore "**/luau_packages/**" <파일>`.
런타임 harness는 `quad-roblox/luau_packages/quad_base`(relink 사본) 한 벌, strict config는 소스 트리 한 벌 — 섞지 않았다(8.34).

**mock의 한계**: mock 인스턴스는 엔진 기본값을 모른다(안 쓴 프로퍼티는 `nil`로 읽힘) → "기본값 복원"은 mock으로 관측 불가. 프로퍼티 타입 검사도 없어 `Text = nil` 쓰기가 그대로 저장된다(엔진은 던진다 — Q33 결정의 전제). mock 트윈은 보간하지 않는다.

## 매트릭스

열: ① 리터럴 `nil` ② 리터럴 `q.None` ③ State가 처음부터 `nil` ④ State가 나중에 `nil` ⑤ State가 `None`으로 ⑥ Tween/Animate 안의 nil/None.
칸 표기: **런타임(mock)** / *타입(strict)* / 문서. ⚠ = 셋이 어긋남, — = 해당 없음. 프로브 라벨은 괄호.

| # | 자리 | ① nil | ② None | ③ State 처음 nil | ④ State → nil | ⑤ State → None | ⑥ Tween/Animate |
|---|---|---|---|---|---|---|---|
| 1 | 프로퍼티(엔진이 nil 거부: `Text`/`TextTransparency`) | 부재 — 핸들러 안 돎(P1) / *통과(T1)* | nil 씀(P2) / *통과(T2)* / roblox/02:115·121 | nil 씀(P3) / *거부(T3)* | nil 씀(P4) / *거부(U1)* / 문서에 State-nil 행 없음 | nil 씀(P5) / *거부(T4,W5)* / ⚠ sugar/02:249 "비움" | `Tween{Value=nil}` Quad0249·`None` Quad0251(P9) / *거부(T8,T9)*; Animate nil/None 통과해 nil 씀(P10,P10b) / *무검사(T7 — 문서화됨 roblox/02:119)* |
| 2 | 프로퍼티(객체 참조: `NextSelectionUp`) | 부재 | nil 씀 / *통과* / roblox/02:115 "객체 참조를 놓는 방법" | nil 씀 / ⚠ *거부(T5)* | nil 씀(P8) / ⚠ *거부(T5)* | nil 씀 / ⚠ *거부(W3)* / Quad0251 "None 자체를 방출" | Tween 팔 없음(문서) |
| 3 | 이벤트(`Activated`) | 부재(E4) | 연결 안 함(E1) / *통과(T10)* | 연결 안 함(E3) / ⚠ *거부(T11)* | 끊김(E2) / ⚠ *거부(T11)* / roblox/02:133 "State가 계산한 nil" | 끊김(E2) / ⚠ *거부(W6)* | — |
| 4 | OnChange 디스크립터 / `q.Out` | `OnChange(name, nil)`·`None` → Quad0222(O5) | 숫자 키 State → None: 끊김(OC1) / roblox/05:100 | — | State<desc> → nil 끊김(OC1) | 끊김(OC1) | 엔진이 객체 참조에 nil을 주면 `Out`이 Source에 nil을 씀(O2,O3) / ⚠ *읽기 표면 non-nil(`PropTypesRead.NextSelectionUp: GuiObject`, strict-out X1·X2 통과)* |
| 5 | 숏핸드(`UICorner`) | 부재 | 자식 안 만듦(S1) / *통과(T12)* | 안 만듦(S4) / ⚠ *거부(T13)* | 관리 자식 파괴, 다시 값 → 재생성(S2) / ⚠ *거부(T13)* / roblox/02:322 | 파괴(S3) / ⚠ *거부(W4)* | Animate nil → 파괴(S5); `Tween{Value=nil}` Quad0249(S6) |
| 6 | 숫자 키 자식 자리 | 중간 Quad0023(C1)·끝은 통과(C1b) / GS 02:117·133 일치 | 빈 자리(C2) / *통과(T14)* | 빈 자리(C3) / *통과(T15,W7)* | 떼기만, 파괴 안 함(C3) / GS 11 §6 일치 | 떼기만(C3b) | — |
| 7 | 숫자 키 값 객체(State<Tag/Attr/Ref/Observer/Effect/Slot>) | — | — | Tag: 없음 → 나중 값 붙음(C5b) / *통과(W10)* | Tag 떨어짐(C5)·Attr 엔진 값 남음(C6)·Ref 비움(C7)·Observer 정지(OB1)·Effect cleanup 1회(EF1)·Slot 트리 떼기(C4) / GS 20 표 일치 | 같음(C5,C6b) | — |
| 8 | Slot 원소(`q.Slot{}`·`:Add`) | 배열 중간 구멍 → 뒤 무시(SL4m) / core/06:78 UB 일치; `:Add(nil)` Quad0239(SL2) / *거부(T17)* | Quad0239(SL1,SL3) / *거부(T16)* | `:Add(State)` 빈 채 len 0(SL5b) / ⚠ *거부(T18)* | 원소 내려옴, 파괴 안 함(SL5,SL5m) / ⚠ *거부(T18)* / core/06:403 | 내려옴(SL5) / ⚠ *거부(W9)* | — |
| 9 | `slot:Single(state)` | — | — | 원소 없음, updateFn 안 불림(SL6m) / *통과(T19)* / core/06:473 | KeyGone 호출·항등이면 파괴(SL6,SL6b) / core/06:490 일치 | 같음(SL6b) / *통과(W8)* | — |
| 10 | `slot:List` 데이터·updateFn | data State가 nil → Quad0142(SL7d,f); keyFn nil → Quad0144(SL7g); 데이터 배열 구멍 → ⚠ 뒤 키 잘림 + 그 원소 파괴(L1) / core/06 :List 절에 없음 | data None → Quad0142(SL7e); 데이터 안 None은 평범한 항목(SL7i); updateFn이 None 반환 → 버림(SL7b) / core/06:375 일치 | — | updateFn nil 반환 → 버림(SL7) / 일치 | KeyGone에 요소 반환 Quad0147(SL7c) / 일치 | — |
| 11 | Tag 이름 | 인자 nil = 없음(T1,T2), 리스트 안 구멍 Quad0203(T3), `Contains(nil)` Quad0205(T6) / core/09:70·78·79 일치 | Quad0237(T4,T5) / ⚠ *`q.Tag(None)`·`q.Tag("A", None)` 통과(U6,U7 — `__call` 무검사, 기지)*, `:Added(None)` 거부(T22) / 에러 페이지 0237에 None 언급 없음 | — | State<Tag>를 내던 Compute가 nil → 태그 떨어짐(T7) | — | — |
| 12 | `q.Attr` 그룹 값 | 항목 조용히 없음(A1) / ⚠ core/09:248·GS 05:199 "거부" | 삭제(A2) / *통과(T23)* | 안 심음(A3) / *통과(T24)* | 삭제(A4) / *통과* / core/09:245 | 삭제(A4) / *통과(W1)* | State가 Tween을 내면 엔진 op 원문 에러(A7, ID 없음 — 범위 밖 메모) |
| 13 | 타입드 Attr 슈거(`String/Number/BooleanAttr`) | Quad0014(A5) / *거부(T25)* / 일치 | 삭제(A5b) / *통과* | — | 삭제(A5c) / ⚠ *거부(T26,U8)* / core/09:416 "State와 None 그대로 통과"·GS 05:201 주석 | 삭제 / ⚠ *거부(W2)* | — |
| 14 | `[q.AttrKey(k)] =` | 부재 | 삭제(A6) | — | 삭제(A6b) | — | (strict에선 키 자체가 거부 — 기지 8.17, core/09:387) |
| 15 | Store 필드 | `{hp = nil}` → 필드 없음(ST2) | Quad0198(ST1) / ⚠ *통과(T27 — 평범한 레코드라 설계상 무검사)* | `Source(nil)` 필드는 Attr(store)에서 안 심음(A8) | `Attr(store)` 삭제(A8) | — | — |
| 16 | `q.Source` 초기값·`:Set` | `Source(nil)`/`Source()` → nil(ST3,ST5) / core/02:38 | `Source(None)` → None 보관(ST4) / *통과(T28)* | 같은 nil `:Set`도 전파(run-setdedup) | 전파 | 전파 | — |
| 17 | Compute 반환·`previous` | — | — | 첫 `previous` nil | nil 반환 뒤 다음 `previous`도 nil(P7b — "직전 결과값 자체"와 일치, 구분 불가) / 하류 프로퍼티에 nil 씀(P7) / *State<string?> → Text 거부(U1)* | — | — |
| 18 | Modifier 필드 setter | 필드 부재(M1)·앞 Modifier 값 남음(M2c) / ⚠ *`mod:X(nil)` 거부(U3)* / core/08:131·roblox/03:106 | 필드 None → nil 씀(M2b), 인라인 키가 이김(M2) / *통과(U2)* / 일치 | — | State 필드 → nil 씀, 앞 Modifier로 안 돌아감(M4,M5) / ⚠ *State<T?> 거부(U4,U5)* | nil 씀(M4) | 변환이 nil: plain → 부재(M3,M3a)·State → nil 씀(M3b) / core/08:132 일치; Animate nil → nil(M6) |
| 19 | `q.Tween { Value }` | Quad0249(P9) / *거부(T8)* / roblox/06:123 | Quad0251(P9b) / *거부(T9)* / 일치 | — | State가 `Tween{Value=nil}` 발행 → Quad0249(P9c) | State<Tween> → None: nil 씀 + Cancelled 1회(TW1,AN2) | — |
| 20 | `Animate` | — | — | 첫 nil 씀, 다음 값은 스냅이 아니라 트윈 경로(P10d,P10d′) | nil 통과·nil 씀·돌던 트윈 Cancelled 1회(P10,AN1), Started/Completed 없음(P10c) / ⚠ roblox/06:206 "객체 참조를 놓는 경로" | 같음(P10b) | — |
| 21 | Context 값 | `:Set(P, nil)` Quad0037(CX1) / *거부(T31)* / sugar/01:98 일치 | 값으로 보관, `:Get`→None(CX2,CX5) / *Provider<number>면 거부(T32)* / 문서 침묵 | — | — | — | — |
| 22 | `Ref:Set` | nil 보관(R1) / *Ref<Frame?>만 통과(T33,T34)* | None 보관(R2) / *거부(T35)* | 숫자 키 자리 철거 → `:Set(nil)`(C7,R3) / core/07:91 일치 | — | — | — |
| 23 | Operator | `Alternative`: nil → 기본값(OP2); `Not nil` → true(OP4) | `Alternative`: None 통과(OP1) / sugar/02:249; `Not None` → false(OP3); `Indexed` None → nil(OP5); `Sum` None → Quad0122(OP6) | 없는 키 `Indexed` → nil이 Text에 씀(IX1) / *`:Apply` 결과 무검사(U11 — 문서화됨)* | — | — | — |
| 24 | `q.dispose` | Quad0178(DS1) | Quad0180 일반 문구(DS2) | — | — | — | — |

**규모**: 행 24 × 열 6 = 144칸, 그중 해당 있는 칸 약 90. ⚠(셋이 어긋남) **24칸** — 절반 이상(17칸)이 한 뿌리(아래 (c)1: 입력 자리 `StateMarker<T>`가 nil·None을 배제)이다. 에러 ID는 실측 18종(0014·0023·0037·0038·0142·0144·0147·0178·0180·0198·0203·0205·0222·0224·0237·0239·0249·0251) 전부 `docs/reference/errors/`의 메시지 줄과 글자 그대로 일치.

## 발견

### (a) 문서 오류

**a1. Operator 레퍼런스가 프로퍼티 자리의 None을 "비움"이라고 한다.** `docs/reference/sugar/02-operator.md:249`는 `Alternative`가 `None`을 그대로 내려보내고 "프로퍼티 자리에서는 '비움'으로 처리"된다고 적는다. 실측은 Property 핸들러가 `nil`을 쓴다(P5·OP1, `quad-roblox/src/Handlers/Property.luau` 246~250행 Q33 주석)이고, Q33 결정(round3 §11)의 계약은 "nil을 못 받는 프로퍼티면 엔진이 던진다"이다. `Alternative`의 흔한 대상이 `Text` 같은 문자열 프로퍼티라 "비움"을 믿으면 실기기에서 엔진 에러를 만난다. 같은 틈이 `docs/reference/roblox/02-d.md` 109~122행에도 있다 — 표에는 리터럴 `q.None` 행만 있고 121행의 "엔진이 자기 에러를 던진다"도 `None`으로 쓴 nil만 말하며, **State가 nil/None을 내놓을 때 nil을 쓴다**는 행이 없다(이벤트 절 133행에는 있다).

**a2. `Attr`의 리터럴 `nil`은 "거부"되지 않고 조용히 빠진다.** `docs/reference/core/09-tag-attr.md:248`과 `docs/getting-started/05-tag-attr.md:199`는 "리터럴 `nil`이 그 자리에서 거부되는 것은 … 항목이 조용히 사라지기 때문"이라고 적는다. 그룹 `q.Attr({ A = nil, B = 1 })`은 에러 없이 `{B=1}`로 끝난다(A1) — "거부"는 타입드 슈거(`StringAttr` 등, Quad0014, A5)에만 맞는 말이다. 문장 뒷부분이 실제 이유를 말하고 있어 해가 크진 않지만, 거부라는 낱말은 에러를 기대하게 한다.

**a3. `Slot:List` 데이터 배열의 nil 구멍이 레퍼런스에 없다 — 그리고 파괴적이다.** `docs/reference/core/06-slot.md`는 `initial` 배열의 구멍만 UB로 적었고(78행) `:List` 절(328~400행)은 데이터 배열 구멍을 말하지 않는다. 코드 주석(`quad-base/src/Slot/List.luau` 98행)은 "documented UB"라고 부른다. 실측(L1): `data = {"a","b","c"}`로 세 원소를 만든 뒤 `data:Set({"a", nil, "c"})` → Length 1, 그리고 **여전히 데이터에 있는 `"c"`의 원소가 KeyGone 경로로 파괴된다**(`isClaimed(c) == false`). 조용한 파괴라 문서 위치가 없으면 찾기 어렵다.

**a4. Modifier setter에 리터럴 `nil`을 넘기는 것을 문서는 입력으로 싣지만 strict가 거부한다.** `docs/reference/core/08-modifier.md:131`(표 "`nil` — 그 필드가 결과에서 사라집니다")과 `docs/reference/roblox/03-d-modifier.md:106`은 `nil`을 setter 인자의 한 갈래로 든다. 런타임은 그대로(M1·M2c), 하지만 `D.Modifier.Frame():BackgroundTransparency(nil)`은 신 솔버에서 타입 에러다(U3, `strict-matrix2.full.out` 11행). 조건부 코드 `mod:X(if c then v else nil)`이 막힌다.

**a5. Quad0237 에러 페이지가 `q.None`을 말하지 않는다.** `q.Tag(q.None)`과 `tag:Added(q.None)`는 `Quad0237 … (got a table with a metatable)`로 떨어진다(T4·T5). `docs/reference/errors/05-tag-attr.md`의 0237 "언제"는 `State`·`Attr`만 예로 든다. 숫자 키 자리에서 `or q.None`을 익힌 사용자가 Tag 인자에도 같은 습관을 쓰기 쉽고, `q.Tag(...)`는 `__call` 인자 무검사라 strict도 못 잡는다(U6·U7·V2 — 이미 알려진 한계, `.claude/base/typing-limits.md` 703행 부근). Tag 인자 자리의 "없음"은 `nil`이다(core/09:70).

### (b) 코드 결함 — 자리 사이 일관성

**b1. nil 구멍의 처리가 자리마다 세 갈래이고, 그중 하나만 파괴적이면서 계약이 아니다.** 같은 "배열 중간의 nil"이 props 숫자 키에서는 `Quad0023`으로 던지고(C1, GS 02:117), Tag 이름 리스트에서는 `Quad0203`으로 던지며(T3), Slot `initial`에서는 뒤를 조용히 무시하고(SL4m, 문서화된 UB), `:List` 데이터에서는 조용히 뒤를 잘라 **이미 있던 원소를 파괴한다**(L1). 앞의 셋은 문서가 계약으로 적었거나 UB로 선언했지만 넷째는 레퍼런스 어디에도 없다(a3). 최소 재현은 `run-matrix3.luau`의 L1 한 블록. 처방은 제안하지 않는다 — 증상은 "데이터에 남아 있는 키의 원소가 에러 없이 파괴된다"이다.

그 밖의 자리 간 비교는 문서가 계약으로 적은 차이였다: `State<Tag>`가 nil이면 태그가 떨어지고 `State<Attr>`는 엔진 값이 남는 것(C5·C6)은 GS 20 표 "Attr 줄만 결이 다릅니다"가, 숫자 키 자리의 `State<Instance>`는 떼기만 하고 `:Single` 항등은 파괴하는 것(C3·SL6)은 GS 11 §6과 core/06:490이 각각 적었다.

### (c) 판단 필요

**c1. 입력 자리의 `StateMarker<T>`가 nil과 None을 둘 다 배제해서, 문서가 기능으로 적은 "State가 nil/None을 내놓는 경로"가 strict에서 여섯 자리 막힌다.** 런타임은 모든 자리에서 State의 nil/None을 똑같이 처리한다(프로퍼티 nil 쓰기, 이벤트 끊기, 숏핸드 파괴, Attr 삭제, Slot 원소 내림). 그런데 타입은 자리마다 갈린다 — **받는 곳**: 숫자 키 자리(T15·W7·W10), 그룹 `q.Attr`(T24·W1), `slot:Single`(T19·W8). **거부하는 곳**: 객체 참조 프로퍼티(T5·W3), 이벤트(T11·W6), 숏핸드(T13·W4), 타입드 Attr 슈거(T26·U8·W2), `slot:Add`(T18·W9), Modifier setter(U4·U5). 문서는 그 거부된 경로를 쓰라고 적는다: 이벤트 "State가 계산한 nil이면 끊는다"(roblox/02:133), 숏핸드 "값이 nil/None이 되면 파괴"(roblox/02:322), 타입드 슈거 "State와 q.None은 그대로 통과"(core/09:416), Quad0251 고치려면 "None 자체를 그 자리에 방출하세요"(errors/08), 그리고 Q33이 nil 쓰기를 되살린 이유였던 객체 참조 해제(`Adornee`/`NextSelection*`)는 리터럴 `q.None`(생성 시 한 번)으로만 타입을 통과하고 반응형으로 놓는 길은 없다. 엔진이 nil을 거부하는 프로퍼티(`Text` 등)에서의 거부(T3·U1)는 엔진 에러를 막아 주므로 이득이다 — 어느 자리에서 State<T?>/State<T|None>을 받아야 하는지는 사용자 판단이다.

**c2. 객체 참조 프로퍼티의 읽기 표면이 non-nil이라, `q.Out`/`OnChange`가 엔진의 nil을 받아도 타입은 모른다.** 생성 `PropTypesRead`는 `Adornee: Instance`·`NextSelectionUp: GuiObject`·`PrimaryPart: BasePart`(`quad-roblox/src/Declaration/init.luau` 1838·1970·1989행)이고 `Parent`만 `Instance?`다(round11 Q66이 핀 defs의 optional 표기를 기준으로 범위를 닫았고, defs는 `NextSelectionUp: GuiObject`·`Adornee: PVInstance`/`Instance`로 non-optional — `scripts/roblox-defs/globalTypes.d.luau` 9278·12218·12527행). 그래서 `q.Out("NextSelectionUp", q.Source(x :: GuiObject))`와 `OnChange("NextSelectionUp", function(v) local _: GuiObject = v end)`가 strict를 통과하고(strict-out X1·X2), mock에서 엔진 쪽 값이 nil이 되면 `Source<GuiObject>`에 nil이 들어간다(O3). roblox/05:185는 반대 방향(`Source<T?>`는 안 들어간다)만 적었다.

**c3. `Animate`의 nil/None 통과가 문서의 근거와 맞는 자리가 없다.** roblox/06:206~207은 "프로퍼티 핸들러가 nil을 씁니다(객체 참조를 놓는 경로)"라고 적는다. 그런데 `Animate`가 의미 있는 곳은 보간 가능한 타입(`number`·`UDim2`·`Color3` …)뿐이고 그 프로퍼티들은 전부 엔진이 nil을 거부한다; 객체 참조에 `Animate`를 걸면 roblox/02:119대로 둘째 값부터 엔진이 거부한다. 그러니 통과된 nil은 실사용에서 늘 엔진 에러로 끝날 것으로 보인다(실기기 후보 R1·R4). 또 nil/None 발행에서는 `Started`/`Completed`가 불리지 않는다 — `CanAnimate = false`에 콜백을 달아 "모션을 껐어도 끝났을 때의 처리는 돈다"(roblox/06:200~204)를 기대한 코드도 nil에서는 콜백이 없다(P10c). 돌던 트윈의 `Cancelled`는 온다(AN1). 이 동작은 round3 Q8 (a) 결정 그대로이고 문서도 통과는 적었으니, 판단할 것은 근거 문장과 콜백 침묵을 적을지다.

**c4. `Context:Set(P, q.None)`은 값으로 보관된다.** `nil`은 Quad0037로 막히고(CX1) sugar/01:98은 "부재로 취급되는 것은 `nil`뿐"이라 적는다. `None`은 에러 없이 들어가 `:Get`이 `None`을 돌려준다(CX2·CX5). `Provider<number>`면 타입이 거부하지만(T32) 넓은 Provider나 무타입에선 통과한다. 다른 자리에서 None은 "없음/지움"이라 소비자가 `Get`의 결과를 부재로 읽을지 값으로 읽을지 문서가 말하지 않는다.

**c5. 작은 비대칭 둘.** `q.dispose(nil)`은 전용 문구(Quad0178)인데 `q.dispose(q.None)`은 일반 문구 `Quad0180 … cannot dispose this value`다(DS1·DS2). `Ref:Set(q.None)`은 None을 그대로 담는다(R2) — `Ref`는 그릇이라 자연스럽지만, 숫자 키 자리 철거가 `:Set(nil)`을 쓰는 것(C7)과 나란히 두면 `ref.Value == nil` 검사가 None을 놓친다.

## 실기기 후보

- **R1** 엔진이 nil을 거부하는 프로퍼티에 State가 nil/None을 내놓을 때(`Text = s`, `s:Set(nil)`; `TextTransparency`·`BackgroundColor3`도): 엔진 에러 문구와 blame 줄, 그리고 그 뒤 같은 State가 정상 값을 내면 다시 쓰이는지(P4·P5·P7 — mock은 nil을 그대로 저장).
- **R2** 객체 참조 프로퍼티(`NextSelectionUp`/`BillboardGui.Adornee`)에 State nil로 해제 — Q33은 사용자의 `Part0` 읽기 실측에 기댔고 quad 경로의 쓰기는 mock뿐(P8).
- **R3** `q.Out`/`OnChange`가 걸린 객체 참조 프로퍼티의 대상이 파괴될 때 변경 신호가 nil로 오는지(c2, O3는 mock에서 대입으로 흉내).
- **R4** `Animate`가 걸린 `TextTransparency`에 nil 발행 → 엔진 에러인지, 그리고 처음부터 nil인 State에 `Animate`를 건 경우(P10d) 생성 줄에서 던지는지.
- **R5** (참고) 엔진 기본값 복원은 어느 경로에서도 일어나지 않는다 — quad는 nil을 쓰거나(문자 키) 떼기만 한다(숫자 키). "기본값으로 돌아간다"는 서술은 문서에 없어 확인 대상은 아니나, 엔진이 특정 프로퍼티에서 nil 대입을 기본값 리셋으로 해석하는지(예: `FontFace`)는 미실측.

## 미완·프로브 결함

- mock은 엔진 기본값·프로퍼티 타입을 몰라 "기본값 복원/엔진 거부" 칸은 전부 실기기 몫(R1~R5).
- `UIScale`/`UIPadding` 숏핸드 nil 행(S8)은 harness 반사 표에 `UIScale` 클래스가 없어 `Quad0076 no handler matched key Name`으로 죽음 — 프로브 결함, `UICorner` 행으로 대체.
- 1차 ST6(`fires=1`)은 Observer를 `Subscribe`하지 않은 결함 — `run-setdedup`으로 대체(같은 nil/None `:Set`도 전파).
- 1차 P11(`State<Modifier>`)은 Quad0182로 설계상 불가 — 문자 키 프로퍼티가 "자리에서 철거"되는 경로는 숏핸드·트윈 철거(roblox/06:257)뿐이라 프로퍼티 철거 행은 따로 두지 않음.
- `q.Store`의 `{hp = q.None}` 무검사(T27)는 평범한 레코드 설계라 발견으로 올리지 않음.
- Compute의 `previous`가 "첫 계산"과 "직전 결과가 nil"을 구분 못 하는 것(P7b)은 문서 정의(core/03:75 "직전 결과값 자체")와 일치해 발견으로 올리지 않음.
