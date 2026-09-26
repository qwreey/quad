# E46 — Modifier 합성 대수 차등 퍼저 (2026-09-27, HEAD `836b5e7f`)

레포 파일 무변경, 이 폴더만 새로 만듦. 런타임 하네스는 E37 것을 복사(`harness.luau`·`engine-globals.luau` —
`quad-roblox/luau_packages/quad_base` relink 사본 한 벌만 require), strict는 `s10-config.luau`(소스 트리 한 벌) — 섞지 않았다(8.34).

## 파일

| 파일 | 무엇 |
|---|---|
| `model.luau` | 참조 모델 — "필드 → 모델 값" 맵 + 클래스 태그 위의 순수 함수. 규칙 R1~R20, 각 줄에 문서 파일:줄 |
| `fuzz.luau` → `fuzz.out` | 차등 퍼저. 필드 3~8(Frame/TextButton 실제 프로퍼티), 값 종류 여섯(리터럴·Source·파생 State·Tween·None·nil) + 변환 함수 셋, 연산 5~30(setter·변환·`Overridden` 두 형태·생성자 병합(무타입/타입드, 앞/뒤)·검사형/무검사 캐스트 12종·`Apply`·팩토리 재호출+dedup). 매 단계 `Peek`·태그·`tostring` 대조, 끝에 중간 값 전부 재대조(불변·형제 비오염), 인스턴스 둘에 같은 Modifier 재사용 마운트(앞뒤 Modifier·인라인 키 무작위) → Source 전부 `:Set`(Tween Source는 새 Tween, 가끔 `None`) → 한쪽 Destroy → 다시 `:Set` |
| `mutants.out` | 퍼저 감도 확인 — 모델을 일부러 틀리게 바꾼 다섯(첫 승/Overridden 태그 유지/상향 캐스트 허용/변환 즉시 평가/nil=None) 전부 500시드에서 차등 수백~수천 |
| `probe-basic*.luau`·`probe-axes.luau`·`probe-gc.luau`·`probe-registry.luau` (+`.out`) | 별도 축 (a)~(f)와 레지스트리(다중 부모·순서 무관·순환) |
| `strict-algebra.luau`·`strict-themed.luau` (+`.out`/`.full.out`) | (g) strict — 합성 결과 타입이 태그를 유지하는가, roblox/03 `Themed` 대체 문장 |

실행(레포 루트, `./scripts/relink.sh` 뒤): `luau .claude/audit/round13-e46-modifier-algebra/fuzz.luau -a <시드수> [시작] [v] [뮤턴트]`.
strict: `mise exec -- luau-lsp analyze --flag:LuauSolverV2=true --flag:LuauTarjanChildLimit=160000 --flag:LuauSubtypingIterationLimit=100000 --flag:LuauTypeInferIterationLimit=1000000 --definitions=scripts/roblox-defs/globalTypes.d.luau --ignore "**/luau_packages/**" <파일>`.

## 숫자

규칙 20(R1~R20), 시드 30,000(1..20000, 50001..60000), 연산 약 53만, 마운트 6만, 프로퍼티 대조 약 57만(파생 State 경유 약 8천, Tween 스냅 약 6.4만·재생 약 9천) — **차등 0**. 뮤턴트 다섯 전부 검출.

## 브리프 전제 정정

`Modifier`에는 `Merged`가 없다 — `Merged`(겹침 거부)는 `Tag`/`Attr`의 것이다(`quad-base/src/Tag.luau:218`, `Attr/init.luau:162`).
Modifier의 합성은 `q.Modifier(...)`/`TypedFactory` 생성자와 `Overridden` 둘뿐이고 **둘 다 겹침을 판정하지 않는다**(뒤가 이김, core/08:80·249·324).
`mod:Merged(x)`는 예약 메소드가 아니라 `Merged`라는 **필드 setter**다(probe-axes C4·C5: Modifier 인자면 `Quad0057`, 숫자면 마운트에서 `Quad0076 no handler matched key Merged`).
`Operator.Alternative`도 Modifier 연산이 아니라 `state:Apply` 팩토리다(sugar/02:242) — 변환 함수 자리에 그대로 넘기면 아래 (c)4.

## 발견

### (a) 문서 오류

1. **roblox/03:146-147 "리터럴이든 변환 함수의 반환이든 — 그 자리에서 던집니다"는 저장된 값이 State일 때 거짓.** 그 경우 변환은 `old:Compute(fn)`으로 들어가고 Compute는 lazy(core/03:48)라 setter 시점에 fn이 돌지 않는다. 변환이 `Ref`를 돌려주면 setter도 마운트도 통과하고 `Ref` 값이 프로퍼티 핸들러까지 가서 mock은 `ZIndex`에 `Ref(nil)`을 써 넣었다(probe-axes B3); Modifier를 돌려주면 setter는 통과하고 마운트 때 State 쪽 가드 `Quad0185`로 던진다(B5). 평범한 값일 때만 그 자리 `Quad0057`(B6). 같은 뜻의 코드 머리 주석(`quad-base/src/Dispatch/Modifier/init.luau:68-70`)도 같은 과장이고, 같은 파일 71행은 "`State<Ref>`식 안쪽 내용은 UB"라고 적어 둔다 — 문서 쪽엔 그 UB 문장이 없다. 변환이 던지는 경우도 같은 갈래: 평범한 값이면 setter 줄에서 던지고 원본은 그대로(B1), State면 setter는 조용히 통과하고 마운트 줄에서(B2), 나중 `:Set`에서 던지면 그 `:Set` 호출로 전파된 뒤 다음 `:Set`에서 회복(probe-basic2). core/08:130·roblox/03:128 어디에도 "State 갈래의 변환은 첫 `Get` 때까지 미뤄진다"가 없다.
2. **roblox/03:266 "`Themed`의 캐스트 줄을 비검사 `props.Modifier:As("TextButton")`으로 쓰거나"(E38 `H-777`이 넣은 문장)는 그 예제의 props 타입 그대로면 strict에서 깨진다.** `props.Modifier: IntoTextButton?`이고 `IntoTextButton`은 `{ AsTextButton: … }` 하나라 `Key 'As' not found in table 'IntoTextButton'`(strict-themed.luau 9행). `<Class>Modifier` 타입에서 불러도 `As(name)`은 `<T>(…) -> T`라 타입 인자 없이는 결과가 `unknown`이고, 그 값을 `D.Frame { … }` 배열부에 놓으면 거부된다(strict-algebra G22 = 31행). roblox/03:218 예제 `local retagged = D.Modifier.TextLabel():As("Frame")`도 같은 이유로 `retagged`가 `unknown`이다(G8 16행 — 주석 `TextButtonModifier` 자리에서 "got unknown"). 문서의 표(03:212-214)는 "`As(name)` = 다시 태그"만 적고, 타입이 따라오려면 `:As<<R.TextButtonModifier>>("TextButton")`처럼 타입 인자를 같이 줘야 한다는 말이 없다. 같은 이유로 `mod:As()`(인자 없음)도 주석 자리에서 `unknown`(G7 15행, G23 32행 `Type 'unknown' does not have key 'ZIndex'`) — core/08:271의 예는 `<<MyModifier>>`를 주므로 맞고, roblox/03:212 표 행 "`mod:As()` — 타입 레벨 캐스트만"은 타입 인자 없이는 캐스트가 되지 않는다는 점이 빠졌다.

### (b) 코드 결함

없음 — 모델과의 차등 0(30,000시드). 문서 계약(합성 순서·마지막 승·None 언셋·nil 부재·변환 두 갈래·태그 유지/무타입화·검사형 캐스트 조상 판정·무검사 캐스트 존재 검사·dedup·tostring·불변·재사용 마운트·Tween 첫 스냅/이후 재생)이 전부 코드와 일치.

### (c) 판단 필요(문서 미정 칸)

1. **타입드 생성자가 형제 클래스 Modifier를 검사 없이 재태그한다.** `D.Modifier.Frame(D.Modifier.TextButton { TextSize = 3 })`는 런타임에 `Modifier<Frame>`(TextSize 필드를 든 채)이 되고(probe-axes G1), strict도 통과한다(G4 12행 — 문서 시그니처는 `...(FrameModifier | { [string]: any })`인데 `TextButtonModifier`가 `{ [string]: any }` 팔로 들어간다). 반면 같은 변환을 검사형으로 하면 `D.Modifier.Frame{}:AsTextButton()`은 `Quad0056`(G3). roblox/03:206-214는 무검사 경로를 `As()`/`As(name)`/`As<<T>>()` 셋으로 적지만, 생성자에 Modifier를 넘기는 것은 넷째 무검사 재태그 경로다. 설계 본문(`base/modifier-plan.md` 11절 "`Modifier(...)`와 같은 병합 본문, `H-310`")으로는 의도된 동작일 수 있으나, "검사형 하강만 태그를 바꾼다"로 읽는 독자에게 이 경로가 문서에 없다. 무타입 래퍼 `q.Modifier(textButtonMod)`를 `D.Frame {}`에 넣는 것도 같은 모양으로 통과한다(G15 — 무타입 허용은 core/08:82대로).
2. **Tag/Attr 값을 필드 값으로 넣는 것은 Modifier 쪽 게이트가 없다.** core/08:89의 금지 목록은 핸들러 계층(`Ref`/`Observer`/`Effect`/`Slot`/`Modifier`)뿐이라 `q.Modifier { Name = q.Tag("a") }`·`mod:Foo(q.Attr{…})`는 만들어지고(probe-axes E3·E4), 마운트 때 프로퍼티 핸들러가 받는다(mock: `Property.luau:266: Name must be a string` — ID 없는 엔진 쪽 에러, E5). 숫자 키 자리가 제자리인 값 객체를 필드에 둔 오용이 어느 층에서 걸려야 하는지 문서가 정하지 않는다.
3. **`State<Ref>`류가 파생 State를 통해 프로퍼티에 닿는 것**((a)1의 뒤쪽) — 코드 주석은 UB, 문서엔 문장 없음. 문서화 여부.
4. **`Operator.Alternative(d)`를 변환 함수 자리에 그대로 넘기면** 평범한 값 필드에선 `Quad0123 Operator.Alternative: Apply target must be a State (got number)`(메시지가 `:Apply`를 가리킴), State 필드에선 `old:Compute(Alternative(d))`가 되어 **State를 값으로 내는 State**가 필드에 들어가고(`Peek(...):Get()`이 `State`), 마운트는 안쪽 사슬을 따라가 5 → 7로 맞게 나온다(probe-axes I1·I2). 올바른 모양은 필드에 넣기 전 `state:Apply(Alternative(d))`. 이 우연한 동작(중첩 State 자리 — sugar/06:107이 언급하는 `State<State<T>>`)을 문서가 다룰지.

## 별도 축 결과(확인만)

- (a) State 필드 Modifier를 두 인스턴스에 붙이면 `:Set` 한 번에 둘 다 갱신, 한쪽 Destroy 뒤 다른 쪽 유지(퍼저 매 시드). Destroy된 인스턴스는 Modifier·Source가 살아 있어도 수거됨(probe-axes A1), 파생 필드 Modifier도 수거(A3). Destroy 없이 버린 인스턴스는 수거 안 됨(A2) — 인라인 `ZIndex = s`도 똑같아(probe-gc) Modifier 고유가 아님(E42 영역).
- (b) 위 (a)1.
- (c) 겹침 판정 자체가 없음 — 같은 값·`None`·`nil` 어느 것도 에러 없음(C2·C3).
- (d) 체인 setter는 State를 받아 반응형(D1, strict G2 통과) — E31 GAP-3 재확인.
- (e) Modifier 안 숫자 키는 불가 — 테이블 `Quad0059`(E1), setter `Quad0058`(E2). 자식·Tag·Ref는 Modifier가 아니라 props 배열부에 놓이고 Modifier와 섞여도 순서대로 처리(E7: ZIndex=뒤 Modifier 값, 태그 t1,t2).
- (f) `tostring`: 무타입·`Overridden` 결과 `Modifier(n fields)`, 테이블/체인/`AsX`/`As(name)` `Modifier<Class>(n fields)`, 전부 `isModifier` true·frozen(probe-axes F).
- (g) strict: setter(리터럴·State·None·Tween·변환)·타입드 생성자·`AsX` 하강·`Apply`(주석 팩토리)는 `FrameModifier` 유지; `Overridden`은 `any`(기지 E14 I5); 검사형 상향 `AsGuiObject`는 타입에도 없음(G21 `Key 'AsGuiObject' not found` — 런타임 `Quad0056`과 일치); `As()`/`As(name)`은 타입 인자 없이는 `unknown`((a)2).
- 레지스트리: 다중 부모(두 번째 부모 경로로 하강 통과)·등록 순서 무관·자기 간선/순환 `Quad0067`·같은 간선 no-op·dedup 전부 문서대로(probe-registry R1~R11).

## 미완

- 퍼저의 변환 함수는 inc/→nil/→None 셋 — 변환이 State·Tween을 **돌려주는** 갈래와 변환 안에서 다른 State를 읽는 갈래는 퍼저 밖(State 반환은 probe로만: (c)4).
- 프로퍼티 값 대조는 mock(타입 무검사·보간 없음) — 엔진에서 `Ref`가 `ZIndex`에 쓰일 때의 실제 에러는 미실측(Studio 금지).
- `UDim2`/`Color3` 같은 비숫자 필드, 이벤트 이름 setter는 퍼저 밖(이벤트는 probe-axes H1로만: setter 시점에 fn이 한 번 불림 — core/08:133대로).
