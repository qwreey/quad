# 결과 — Declaration 타입 함수 조립 첫 실측 (2026-10-16, CLI·LSP 하네스 — Studio·VSCode는 사용자 몫, `README.md`)

opus 서브에이전트가 만들고 돌렸다(보고 본문을 메인이 요약해 저장). 결정이 아니라 재료다 — 정할 것은 `research/declaration-surface-plan.md` 4·5절.

**환경 재구성(실측).** 사용자 VSCode = code-server의 luau-lsp 확장 1.70.1, `--no-flags-enabled` + 확장 globalStorage defs. 확장 `dist/extension.js`의 플래그 동기 로직을 옮겨(PCStudioApp `Luau` 키 633개, 2026-10-16) 네 모드로 돌렸다:
`vsc`(확장 1.70.1 + 동기 + 워크스페이스 한도 override = 사용자 VSCode), `sync`(override 없음 — Roblox 동기값 그대로), `pin`/`pinsync`(레포 핀 1.69.0 + `scripts/roblox-defs`). 하네스 `harness/lspc.py`는 stdio JSON-RPC로 completion·hover·진단을 받는다.
`src/Lib.luau`는 디스패처 타입 함수 `Build<Mode, C, Policy>` 하나가 클래스 체인을 걸으며 모든 축을 만들고, 체커 차이는 생성기 분기가 아니라 `Policy` 데이터(Deny·DenyIn·Inject)로 넣었다.

1. **`New<<Frame>>("Frame")`(괄호 없는 `New<<TextLabel>> "TextLabel"` 포함)** — 됨: 클래스 이름 싱글턴 검사, 중괄호 안 프로퍼티·이벤트 자동완성(Frame 62), 값 진단은 생성 D와 같은 자리·같은 뜻, 읽기 전용·Studio 전용 이름 거부(생성 D와 같은 두 건짜리 에러), 상속 이름. 약함: 주석만으로는 C가 안 채워짐(명시 `<<C>>` 필수), `Props<GuiObject>` 값을 하위 생성자에 못 넘김(배열부 인덱서 불변 — 상위 공통은 Spread·Modifier 마커로만), 추상 클래스 `New<<GuiObject>>`를 못 막음, **hover가 별칭 이름 없이 구조 전체로 전개**(생성 D는 이름이 남음).
2. **`Modifier<<C>>()`** — 메소드 자동완성(Frame 40), 값·키 진단, 태그 유지, `types.generic` 제네릭 메소드가 체인 뒤에도 동작(`m:Peek<<UDim2>>` → `UDim2?`), 상위 Modifier는 하위 요소에 들어가고 형제는 거부. 약함: detail·hover가 재귀 전개로 김, 생성 `FrameModifier`와 양방향 대입 불가(공존은 요소 자리 마커로만). `As*`/`Into`/`Overridden`·숏핸드 setter는 미측정.
3. **`Spread<<C>>({...})` → `SpreadMarker<C>`** — 만드는 자리 자동완성(63)·진단이 `New`와 같고 결과는 `{ read __quadSpread: "Frame" }`, 자기·조상 마커만 배열부 통과, 안쪽 Spread 가능(하위 묶음을 상위에 넣으면 거부), 팩토리 `Hoverable(...): SpreadMarker<GuiObject>`가 Frame·TextButton 양쪽에 들어감. 겹치는 키는 런타임 몫.
4. **`OnEvent(name, fn)`** — 이름 자동완성(49, 클래스 무관), 오타 진단, 놓이는 자리에서 클래스 소속 대조(Spread 안이면 Spread의 C로 거름), 클래스를 아는 변형 `OnEventIn<<Frame>>(…)`·`OnEventFor<<Frame>>()`(Frame 이벤트 26으로 좁힘). **가장 중요한 안 되는 것: 무주석 콜백 인자가 문맥 타입을 못 받는다**(`OnEvent("MouseEnter", function(x, y) end)`의 x = `unknown`, 고정 인자 수 변형도 같음). **지금의 생성 `OnChangeFn`도 같다**고 보고(1.70.1·1.69.0 모두 `v`가 unknown — `base/typing-limits.md` 8.7 3번과 어긋남, 메인 미확인). 되는 꼴은 **커리 `OnEventC("MouseEnter")(function(x, y) … end)`** — x가 number, `input.` 자동완성 64.
5. **체커 차이 흡수(사용자 가설)** — 두 defs에서 정책 적용 뒤 Frame 등 개수 일치, 31 클래스 키 집합이 생성 D `<Class>Param`과 글자까지 같은 것이 vsc 28/31·pin 29/31. 남은 차이는 전부 **API 버전 차이**(defs가 덤프보다 새것/오래됨) — 예외 데이터로 못 메움(타입 함수 표면은 사용자 체커를, 생성 D는 덤프를 따름). 발견: Object까지 걸어야 `Changed`, 오버로드 메소드(intersection)는 걸러야 함, **멤버 하나가 `parameters()`에서 죽으면 표면 전체가 never**(타입 함수 안엔 pcall 없음, 8.18).
6. **비용** — (a) 파일 위에 한 번 만드는 타입 함수 꼴: 20 → 930 호출 0.48 → 0.77 s, 79 → 200 MiB, `sync`에서도 too complex 0. (b) 생성 D: 0.86 → 1.19 s, **`sync`(override 없는 실사용자 환경)에서 too complex 6건·NEG 0/2, `D.Frame({` 자동완성 0, hover `*error-type*`** — 8.28의 실사용자판 재현(사용자 VSCode는 override가 있어 괜찮음). (c) 호출마다 `L.New<<C>>`를 인스턴스화: 620 호출 too complex, 930 호출 2.8~3.07 GiB에서 예산 정지 → 파일 위에 한 번 만드는 꼴이 사실상 강제.

**미완**: Studio 자동완성·hover 인상, VSCode 관측 전부, 숏핸드·`As`/`Into`의 타입 함수화, Q87·Q127, 생성 D `Apply` hover 직접 대조, 930 호출 이상의 인라인 꼴.

## Studio 진단 실측 [2026-10-16 — `studio-analysis`로 메인이 읽음]

사용자 업스트림 툴링에 새로 생긴 `studio-analysis --place quad-test --json`(Windows UIA로 Script Analysis 창 목록을 읽음)으로 quad-test(HEAD `a8617c92` 싱크)의 진단을 통째로 받았다 — declprobe·Declaration 줄은 `out/studio-analysis.txt`. 자동완성·hover는 이 도구로 안 보이니 여전히 사람 몫.

- **01·02·03·06a·06c는 리눅스 `vsc`와 진단이 위치·문구까지 같다**(14·7·7·2·2). 04는 16 대 18 — 빠진 둘은 `LocalUnused` 린트라 Studio 린트 설정 차이일 뿐 타입 결과는 같다.
- **`[BRIEF]`**: `Frame 38/26; TextLabel 57/26; TextButton 63/34; ImageButton 58/34; UIScale 5/9; WorldModel 13/9; UIShadow 13/9`. `+` 표시가 하나도 없다 — Studio 체커는 Transparency·FontSize·TextWrap을 원래 가져서 `Inject`가 빈다(9/16과 같은 결론). `!` 표시도 없다. 05의 `[R]` 줄도 `MouseEnter=event:(number, number) -> ()`라 extern 경로가 Studio에서 돈다. 유일한 차이는 **WorldModel 13 대 8** — Studio에는 AutoSimulate·GravityDirection·SimulationRate·Wind·WindDirection이 더 있다(API 버전 차이). 타입 함수는 체커가 가진 클래스를 읽으므로 이 차이를 저절로 따라간다.
- **06b(지금 생성 D) 진단 0건 — NEG 0/2.** 그 대신 `ReplicatedStorage.quad-roblox.src.Declaration` 모듈 안에 `Internal error: Code is too complex to typecheck!` 4건(5055·5056·5059·5062행 — `ModifierNS.GuiBase`·`GuiBase2d`·`GuiObject`·`Instance` 배정)이 났다. 리눅스 `sync`(override 없음)에서 본 붕괴와 같은 모양이고, 9/16 Studio(그때는 too complex 없음)와 달라졌다. 킷도 같은 `ReplicatedStorage.quad-roblox.src.Declaration`을 require하므로 **지금 Studio에서는 킷 코드의 D 타입 검사도 조용히 꺼진 상태로 봐야 한다**(한 번 읽은 결과, 반복 측정은 안 함).
- **06a·06c(타입 함수 꼴)는 NEG 2/2, too complex 0** — 같은 Studio·같은 크기(k20m5)에서 타입 함수 쪽은 살아남았다.

같이 읽힌 킷 쪽 Studio 진단(이번 트랙 밖, 기록만): material gallery의 `table.insert` 오버로드 모호 29건, `Code is too complex` 9건(devui `Inputs.InputText` 68·75행, material `Card`·`List`·`TextField.Field`·`ColorPicker.Material.Fields` 등), `Overlay` 404행 `*error-type*` 호출 1건, quad_base 3.2.0 패키지 사본의 `test/spec.versioncheck`(Unknown type·require 8건 — 패키지에 테스트가 딸려 들어간 것).

## 사람 관측 — Studio 자동완성·VSCode 대조 [2026-10-16, 사용자]

**Studio**(quad-test, 타입 함수 꼴): 01 24행 `Frame({ ` 뒤 `Back` → `BackgroundTransparency`(`number | …`)가 뜬다(`BackgroundColor3`는 같은 테이블에 이미 있어 빠진 것). 04 18행 따옴표 안 `Mouse` → MouseEnter·Leave·Moved…가 뜨고 서명 `OnEvent(name: K & ("Activated" | …))`이 보인다. **커리 76행 `input.`**은 처음에 Instance 멤버부터 뜨고 `User`로 좁히면 `UserInputType`·`UserInputState` 둘 — 문맥 타입이 흐른다. **비커리 36행은 안 뜬다.** 하네스 결과와 같다 — 타입 함수 표면은 Studio 편집기에서도 자동완성이 산다.

**VSCode**(`harness/compare/gend-lsp.luau`, 지금 생성 D): `D.Frame({ `·`D.TextLabel({ ` 자동완성이 뜨고 항목 타입은 `(None | StateMarker<(TweenData<number> & t1) | number> | …)? where t1 = { Mapped: … }… *TRUNCATED*`. **지연: `D.Frame({`·`D.TextLabel({`는 약 1초, `m:`는 즉시**(한 번 열고 닫은 뒤 다시 부르면 조금 빠름). **생성 Modifier `m`의 hover도 `local m: t26 where t1 = { Subscribe: …` 구조 전개**다 — 1번의 "생성 D는 이름이 남음"은 Modifier에는 맞지 않는다(hover가 긴 것은 두 꼴 공통). `bad`(Visible = 5)는 에러가 난다(override 있는 사용자 VSCode에선 생성 D가 산다 — 리눅스 `vsc`와 같음).

**OnChange 무주석 콜백(typing-limits 8.7 3번 확인)**: `oc`의 타입은 `{ Callback: (boolean) -> (), Name: "Visible" }`인데 **`v` hover는 `unknown`**(사용자). 하네스 `harness/compare/onchange-infer.luau`로 갈랐다 — 무주석 `v`를 잘못 쓰면(`local s: string = v`, 멤버 경유 `local s: string = v.X`) `function(v)` 자리에 `Expected this to be 'boolean', but got 'string'`이 뜨고, 틀린 주석(`function(v: string)`)도 잡힌다. 그러나 `v.` 자동완성은 없다. 즉 **검사는 되고 편집기 도움은 없다** — 본문 사용으로 `v`가 먼저 굳은 뒤 콜백 전체가 대조된다. `base/typing-limits.md` 8.7 3번·`base/onchange-plan.md`·`docs/reference/roblox/05-onchange.md`를 이 사실로 정정했다. 커리 꼴(4-g)만 문맥 타입이 파라미터로 흘러든다.

## 이름만으로 클래스 잡기 — `src/07-new-by-name.luau` [2026-10-16 추가, 4절 1번 정리 전 메인이 채움]

`<K>(name: K & keyof<ClassMap>) -> (Props<index<ClassMap, K>>) -> index<ClassMap, K>`(`ClassMap = { Frame: Frame, … }` — 31 클래스, 덤프에서 나올 데이터)로
**`NewN("Frame")` 한 번에 클래스가 정해진다** — 명시 `<<Frame>>` 불필요. vsc·sync(override 없음) 같고 Studio(4 클래스 맵으로 싱크해 `studio-analysis`)도
진단이 위치·문구까지 같다: 오타 `NewN("Fraem")` 에러(`Property '"Fraem"' does not exist on type 'ClassMap'`), 따옴표 안 클래스 이름 자동완성 32,
`Frame({ ` 자동완성 64·0.02 s, 값 에러·남의 프로퍼티(`Frame({ Text = … })`) 에러, 인라인 `NewN("Frame")({ Visible = 5 })`도 에러, 반환 hover `local ok2: TextLabel`.
생성자 hover는 여전히 구조 전개. 맵을 "만들 수 있는 클래스"로만 채우면 추상 클래스 생성(1번의 약점)도 이름 단계에서 막힌다(맵 분리는 미측정).

## Spread 모양·클래스맵 신원·인라인 비용 — `src/08-spread-shape.luau`, `harness/compare/inline/` [2026-10-16 추가]

- **클래스맵이 전역 클래스를 재사용하는가**: 타입 함수 안에서 `ClassMap`의 `Frame` 자리와 전역 `Frame`이 `==` 참(`rawequal`은 거짓 — 타입 함수에 넘어오는 핸들이
  매번 새 래퍼라서). 반환 hover에 클래스 문서(`A 2D user interface element…`)가 붙는 것도 선언된 클래스 그 자체라는 뜻. 31 클래스 맵을 단 파일이 600 호출에서
  113 MiB로 평평 — 맵 비용은 측정에 안 잡힌다.
- **두 인자 `Spread("Frame", {...})`는 틀린 꼴**: 올바른 `{ BackgroundTransparency = 0.5 }`가 `Expected this to be '<Props…>' but got '{ BackgroundTransparency: number }'`로
  거부되고, 틀린 값도 값 자리가 아니라 테이블 통째로 잡힌다 — 같은 호출 안에서는 테이블 리터럴이 문맥 타입을 못 받는다(무주석 콜백과 같은 이유). 자동완성은 뜬다(64).
  **커리 `Spread "Frame" {...}`는 정상**(값 자리 에러, 자동완성 64), 결과 마커는 `{ read __quadSpread: "GuiObject" }` — 이름 싱글턴만 남는다.
- **인라인 비용(`NewN "C" {…}`·`SpreadC "C" {…}`를 호출마다, 5 클래스 순환)**: sync 기준 50 호출 0.63 s/192 MiB, 150 → 0.98 s/440 MiB, 200 → 572 MiB, 250 → 692 MiB에서
  멀쩡하다가 **300 호출에서 too complex 1 + 가짜 에러 402**(600 호출 1389). 사용자 VSCode 설정(vsc, 한도 override)도 같은 자리에서 무너진다 — 조용히 사라지지 않고
  가짜 에러가 쏟아지는 꼴. **파일 위에 꺼내 두면(`local Frame = NewN "Frame"` 뒤 `Frame {…}`) 50~600 호출이 0.52~0.62 s/92~113 MiB로 평평** — 인스턴스화가 바인딩마다 한 번.

## Claim/Mapper 축·공용 모듈 꼴 — `src/09-mapper.luau`, `harness/compare/central/` [2026-10-16 추가]

- **Mapper**: `Lib`에 `MapperPolicy`(Policy의 `Child`에 `MapperDescriptor`만 더함)와 `MapperProps<C> = Build<"props", C, MapperPolicy>`를 넣어 **같은 `Build`를 데이터만 바꿔 재사용** —
  생성 `<Class>MapperElem = <Class>Elem | MapperDescriptor`와 같은 모양. 표면 `Mapper "Frame"` → `(key: string | Root) -> (props) -> MapperDescriptor`(커리 셋).
  sync에서 `Claim(template, MFrame(Root)({ … MLabel "Title" {…}, MFrame "List" { MLabel "Inner" {…} }, Frame {…} }))` 무진단·hover `local ok: Frame`,
  인라인 `MapperN "TextLabel" "Sub" {…}`·꺼내 둔 `MFrame "X" {…}` 자동완성 83/64. 부정 다섯 전부 잡힘: 값 둘, **New 요소 안의 Mapper 디스크립터 거부**(생성 `<Class>Elem`과 같음),
  이름 오타, 키에 숫자.
- **공용 모듈(사용자 2026-10-16 — 프로젝트 `quad.luau`에서 꺼내 export)**: 31 클래스의 생성자·Spread 62개를 한 모듈에서 꺼내 반환하는 `Ui.luau` 0.64 s/171 MiB,
  그걸 require해 600 호출하는 파일 0.74 s/172 MiB(모듈 검사 포함) — 파일별 꺼내 두기와 같은 평평한 비용이 모듈 경계를 넘어서도 유지. 소비 쪽 `UI.` 자동완성 62,
  `UI.Frame { ` 자동완성 64(0.11 s), 값 에러 둘 잡힘.

## Modifier는 마커가 아니다 — 비용 `harness/compare/modcost/` [2026-10-16 추가, 사용자 질문]

Modifier 값의 타입은 Spread와 달리 **메소드 표면 전체 + 태그**(`read __quadModifier: "Frame"`)다 — 만든 뒤에도 `m:Visible(true)`·`:Peek`·`:Apply`로 계속 쓰기 때문. 놓이는 자리의
검사(`Elem<C>`의 `{ read __quadModifier: "Frame" | 조상 }` 팔)만 태그 글자로 한다. 비용(sync): 함수 주석 `m: Modifier<Frame>, g: Modifier<GuiObject>` 50→300개 0.48→0.67 s,
92→93 MiB(별칭 인스턴스화는 한 번); 인라인 `Modifier<<Frame>>():Visible(true)` 50→300번 0.57→1.26 s, 156→622 MiB(무너지진 않았지만 New 인라인처럼 자란다) — 이름 꼴 `Modifier "Frame"`이
돌려주는 팩토리를 꺼내 두고(`local FrameModifier = Modifier "Frame"`) 쓰는 자리마다 `FrameModifier()`를 부르면 꺼내 두기와 같은 비용이 될 것(미측정).

## 누적형 Spread(`:Add`) — `harness/compare/spread-acc.luau`, `harness/compare/modcost/spreadacc-*` [2026-10-16 추가, 사용자 질문]

마커에 `Add: (self, props: Props<C>) -> self`를 단 `SpreadAcc<K, C> = { read __quadSpread: K, Add: … }`(값은 Modifier처럼 메소드를 가진 값이 된다; 이름 맵에는 추상 클래스
GuiObject·GuiButton·GuiBase2d를 더함). sync: `s:Add { ` 자동완성 63(메소드 호출은 self가 C를 정해 두어 테이블이 문맥 타입을 받는다 — 커리와 같은 이유), 체인
`FrameSpread {}:Add {…}:Add {…}`, `Frame { s, chained }`·`TextButton { s }` 무진단(메소드가 붙어도 요소 자리는 태그 팔만 본다), 틀린 값·남의 프로퍼티·`TextButton { Frame 묶음 }` 거부.
비용: 꺼내 둔 `GuiSpread`로 `{…}:Add {…}` 뒤 요소에 넣기 50→300 호출 0.50→0.60 s, 92→97 MiB(평평). 잃는 것은 hover뿐 — `chained`가 `t1 where t1 = { Add: (self: t1, props: { [number]: …`로
props 표면까지 펼쳐진다(마커 꼴은 `{ read __quadSpread: "GuiObject" }` 한 줄). 놓인 뒤 잠김(`:Add` 에러)은 런타임 몫 — 타입은 표현 못 함.

## q 타입에 타입 함수 멤버를 얹기 — `harness/compare/qmerge/` [2026-10-16 추가, 사용자 질문]

지금 q의 타입은 `UseProvider`가 돌려주는 `Self & P`(`Quad & RobloxExtension`, quad-types 672행)다. 실제 quad-types `Quad`에 타입 함수로 타이핑한 확장
`{ Elem, Spread(:Add), Modifier, Mapper, OnEvent(커리) }`를 같은 교집합으로 얹어(`Ext.luau`) 소비 파일에서 쟀다(sync): 0.47 s/93 MiB, 맞는 줄 무진단,
부정 넷(값·추상 클래스 `Elem "GuiObject"`·Frame Modifier를 TextButton에·base `Source:Set` 타입) 전부 잡힘 — **base 표면 검사도 그대로 산다**.
**`Modifier`처럼 base와 이름이 겹치는 멤버**: 교집합이 되어도 `q.Modifier "Frame"`은 타입드(메소드 자동완성 40), `q.Modifier()`는 base `Modifier`(오류 메시지로 확인 —
hover는 참조 타입까지 펼쳐 이상하게 보이나 타입은 `Modifier`), `q.Modifier.TypedFactory`도 보인다. `q.` 자동완성 base 64 → 68(새 이름 넷), `q.Sp`·`q.OnE`에
서명이 뜬다. 즉 런타임은 base, 타입은 quad-roblox가 지금의 병합 경로 그대로 실을 수 있다(새 메커니즘 없음).

## 클래스를 먼저 받는 커리 OnEvent·OnChange — `src/10-class-curry-events.luau`, `harness/compare/change-big.luau` [2026-10-16 추가, 사용자 질문]

꼴 `OnEvent "Frame" "MouseEnter" (function(x, y) … end)`·`OnChange "Frame" "Visible" (function(v) … end)`. 둘째 호출 두 가지를 비교: **G**(제네릭 `K & keyof<Events<C>>`, 콜백 `index<…, K>`)와
**O**(오버로드 교집합 — 이름마다 `(name) -> (fn) -> desc` 하나, Lib 모드 `eventoverloads`/`changeoverloads`; 프로퍼티는 쓰기 표면 `propmap` — 읽기 표면은 ReadOnly를 빼지 않는 정책이 필요, 미측정).
- **둘 다 콜백에 문맥 타입이 흐른다** — 무주석 `x` hover `number`, `v` `boolean`, `input.` 자동완성 64, 오용(`local s: string = x`)이 **본문 줄**에서 `Expected 'string', got 'number'`로 잡힘
  (비커리 `OnChange(name, fn)`은 `function(v)` 자리에서 잡히고 hover `unknown`이었다). 인라인 `OnEvent "Frame" "MouseMoved" (…)`도 같음. 클래스에 없는 이름 거부(G는 긴 메시지, O는 `None of the overloads …`).
- **차이는 이름 자동완성**: G는 둘째 호출 따옴표 안에 그 클래스 이벤트 이름이 뜬다(27), **O는 0** — 오버로드로 고르는 꼴은 이름 목록을 잃는다.
- O 비용: 프로퍼티 63개 TextButton·ScrollingFrame의 OnChange 오버로드도 too complex 없이 0.46 s/93 MiB(8.7의 "오버로드 교집합 37개부터 죽는다"는 235-이름 스코프 전체 교집합 이야기 —
  클래스별로 나누면 버틴다). 파일 전체 0.48 s/93 MiB.
- **Studio**(`studio-analysis`): 10번 진단이 위치·문구까지 CLI와 같다.

## 생성 D 범위를 타입 함수로 다시 지으면 — 한도는 "모듈이 내보내는 타입"에 걸린다 — `src/11~16`, `harness/compare/fulld/`·`multi/` [2026-10-16 추가, 4절 2번]

- **통째 D(`11-full-d`: 생성자 31 + Modifier 47 + Mapper 31을 한 모듈이 반환)**: sync(override 없음)에서 모듈 (1,1)에 too complex, 소비 파일(`12`) NEG 0 — vsc(override)에서만 NEG 3/3.
  **Studio는 11·12 모두 진단 0건**(too complex 표시도 없이 NEG가 사라짐 — CLI보다 나쁜 조용한 실패).
- **무엇이 넘기나(sync)**: 생성자+Mapper만 반환 171 MiB 정상, Modifier 47만 반환 정상, 생성자 31 + Modifier 32 반환 정상, **생성자 31 + Modifier 40 반환에서 too complex**.
  리터럴을 나눠도(v2) 같고, **같은 양을 반환하지 않으면(v5 — 파일 안에서만 씀) 정상** — 한도는 모듈 반환 타입이 경계를 넘을 때 걸린다.
- **쪼개 내보내기**(`13` 생성자+Mapper 모듈, `14` Modifier 47 모듈, `15`가 둘 다 require): sync·Studio 모두 NEG 3/3 — 모듈마다 한도 아래면 산다.
- **파일별 vs 공용 모듈**(`multi/`, 파일 20개가 같은 생성자 8 + Modifier 4를 씀, 한 프로세스로 전체 검사, sync): 파일별 1 → 5 → 20개 0.53 → 0.66 → 1.26 s, 공용 모듈 0.47 → 0.53 → 0.80 s,
  둘 다 93 MiB·NEG 전부 — 파일별이 파일당 ~0.04 s 더 든다. **무거운 파일별**(`multi/heavy/` — 파일마다 생성자 31 + Modifier 47을 꺼내 둠, 내보내지 않음): 1 → 5 → 20개 0.71 → 1.37 → 3.95 s,
  185 → 192 MiB, 어느 파일도 무너지지 않고 NEG 전부; Studio(`16-heavy-local`)도 NEG 잡힘. 즉 **한 파일의 무게는 그 파일에 갇히고 다른 모듈로 새지 않는다** — 넘치는 것은 내보낼 때뿐.

## round13 Q87·Q127을 클래스 먼저 커리로 — `src/17-out-curry.luau`, `harness/compare/out-curry.luau` [2026-10-16 추가, 4절 5번]

세 보류 문항(Q87 충돌 이름 여섯에서 `q.Out` 거짓 양성, Q122 디스크립터 두 벌, Q127 객체 참조 읽기 표면 non-nil)의 공통 뿌리는 31 클래스를 한 이름 맵(`PropTypesRead`)에 합친 것 —
같은 이름이 클래스마다 다른 타입이면 `any`가 된다. 클래스 먼저 커리 `Out "ScrollingFrame" "CanvasSize" (src)`(Lib 모드 `readmap` — 클래스별 맵)로 재면(sync):
- **Q87 해소**: `ScrollingFrame.CanvasSize`←`Source<UDim2>`, `UIGradient.Color`←`Source<ColorSequence>`, `UIGradient.Transparency`←`Source<NumberSequence>`, `UIStroke.Transparency`←`Source<number>` 무진단;
  `CanvasSize`←`Source<Vector2>`, `UIGradient.Transparency`←`Source<number>`, `Frame`에 `"Text"`는 거부. (거부 메시지가 Source 메소드마다 펼쳐져 한 줄에 95건 — 지금 `OutFn`의 음성도 90건이었다, 모양만의 잡음.)
- **Q127 (a)를 생성기가 아니라 타입 함수 규칙으로**: `readmap`이 Instance 계열(부모 사슬에 `Instance`가 있는 extern) 프로퍼티를 `T?`로 — `Out "Frame" "NextSelectionUp" (Source<GuiObject?>)`·
  `Out "BillboardGui" "Adornee" (Source<Instance?>)` 통과, `OnChange "Frame" "NextSelectionUp" (function(v) local g: GuiObject = v end)`는 `nil`이 안 들어간다고 거부, `Size`는 그대로 `UDim2`.
  타입 함수 안에서 클래스와 값 타입(UDim2 등)은 둘 다 `extern` 태그라 사슬 검사가 필요하다(`harness/compare/tagprobe.luau`).
- 읽기 표면(ReadOnly 포함)은 이 프로브에서 아직 쓰기 표면 — 구현 때 ReadOnly를 빼지 않는 정책 데이터.
