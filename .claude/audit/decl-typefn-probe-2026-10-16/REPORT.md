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

## Declaration 타입 함수 표면 2차 실측 보고 (2026-10-19) [2026-10-19 — opus 서브에이전트, 본문 그대로 저장]

이 보고는 결정이 아니라 재료입니다. 재료와 지시문은 `.claude/audit/decl-typefn-probe-2026-10-16/` 아래에 있고, 1차 파일은 하나도 고치지 않았습니다. 바뀐 내용은 `src/Lib.luau`를 `src/Lib2.luau`로 복사해서 넣었습니다. 모드 이름은 1차와 같습니다. 기준은 **sync**(Roblox 동기 플래그, override 없음)이고, **vsc**는 사용자 VSCode(한도 override 셋 켬), **pin**은 레포에 핀 고정된 1.69.0과 `scripts/roblox-defs` 조합입니다. 판정은 새로 만든 `harness/diag-lines.py`가 줄 단위로 셉니다. 한 줄에 붙은 `-- NEG` / `-- OK` 표지를 대조하고, 린트 경고(LocalUnused 등)는 빼고 셉니다. 파일과 모드별 집계는 `out/r2/summary-neg-ok.txt`에 있고, 원 출력은 `out/r2/*.txt`에 줄을 잘라서 넣었습니다.

### 요약

- **M1(typeof로 서명 꺼내기)은 됩니다.** 제네릭이 무너지지 않고, 콜백 문맥 타입·이름 자동완성·오용 진단이 다 살아남습니다. 예외는 하나입니다. 다른 클래스로 부분 적용한 함수를 대입해도 막히지 않습니다.
- **M2(읽기 표면에 ReadOnly 포함)도 됩니다.** 다만 체커 쪽에는 읽기 전용 표시가 전혀 없습니다. 그래서 ReadOnly를 쓰기 표면에서 빼는 일은 덤프에서 온 데이터(`DenyWrite`)로 해야 합니다.
- **M3(Modifier의 As*/Into/Overridden/숏핸드)는 vsc에서는 킷이 쓰는 꼴이 전부 됩니다.** 그러나 sync에서는 `ModifierInto<GuiObject>`가 걸린 자리가 전부 "too complex"가 됩니다. 원인은 추상 클래스 Modifier의 As 트리 크기와, 따로 만들어진 사본끼리의 구조 비교입니다.
- **M4(전체 클래스 맵)는 맵 자체는 싸지만, 클래스 이름 바운드가 sync 한도를 넘습니다.** 361개 클래스를 한 바운드에 넣으면 큰 클래스나 유니언 뒤쪽 클래스의 꺼내기 줄마다 too complex가 납니다. NEG 판정은 잃지 않았습니다. 84개짜리 분야별 맵은 깨끗합니다.

---

### M1. typeof로 서명 꺼내기

파일은 `harness/compare/qtypeof/Ext2.luau`와 `use.luau`입니다. 1차 qmerge처럼 `QT.Quad & Ext`로 얹었습니다. `Ext`에는 확정 표면대로 `Elem`, 클래스 먼저 커리인 `OnChange`·`OnEvent`·`Out`이 들어 있고, `OnChange`·`Out`은 Lib2 readmap을 씁니다. Studio 사본은 `src/19-typeof-q.luau`(Ext2를 인라인)입니다.

**실측: 진단** (`run-cli.sh`, sync·vsc·pin 세 모드 모두 같음)
- NEG 25/26, OK 19/19이고 too complex는 0입니다. sync 비용은 0.81 s / 259 MiB입니다.
- 지역 별칭 `type OnChangeT = typeof(q.OnChange)`(use.luau 10~13행)에 담은 값으로 부를 때 다음이 전부 진단됩니다.
  - 본문 오용(21행), 이름 오타, 클래스 오타
  - `Out`의 틀린 Source(31행)
  - `Elem "Fraem"`, `Frame { Visible = 5 }`
- 래퍼 함수의 파라미터를 그 별칭으로 주석해도 같습니다. `withChangeBad`(41행), 이름 오타, `withOutBad`, `withElemBad`가 잡히고, `withChange(function() end)` 같은 틀린 인자도 잡힙니다.
- 부분 적용도 같습니다. `typeof(q.OnChange "Frame")`, `typeof(q.Elem "Frame")`, `typeof(q.Out "Frame")`를 꺼내도 본문 오용, 남의 이름(`fc "Text"`), 남의 생성자(`mk(q.Elem "TextLabel")`, 69행)가 잡힙니다. 확정 이름 `ElemCtor<Frame>`도 같은 결과입니다.
- 제네릭으로 흘려도 검사가 유지됩니다. `id(q.OnChange)`(84행)와 테이블 필드 `{ OnChange: OnChangeT }`(86행) 둘 다입니다.
- **놓친 하나는 65행 `local fcOther: FrameChange = q.OnChange "TextLabel"`입니다.** 바운드만 다른 두 제네릭 함수를 체커가 서로 대입 가능하다고 봅니다. 대입한 뒤의 `fcOther`는 Frame 이름표로 검사됩니다.

**실측: LSP** (`lspc.py`, sync·vsc·pin 같음)
- hover는 제네릭을 유지합니다.
  - `OnChange` → `function OnChange<C0>(class: C0 & ("BillboardGui" | …)) …`
  - `id(q.OnChange)` → `function oc2<C0>(…)`
  - 부분 적용 → `function fcPartial<K>(name: K & ("AbsolutePosition" | …))`
  - any나 unknown으로 무너진 곳은 없습니다. 다만 1차처럼 `keyof`가 리터럴로 풀려서 깁니다.
- 무주석 콜백 인자의 hover도 살아 있습니다.
  - 별칭으로 담은 지역: `v: boolean`, `x: number`
  - 래퍼 파라미터 경유: `count: number`
  - 부분 적용 별칭 경유: `v: boolean`
  - ReadOnly 경유: `v: Vector2`, `v.` 뒤에 `Magnitude`
- 자동완성 개수는 다음과 같습니다. 괄호 안 숫자는 하네스가 끼워 넣은 글자 1개를 포함한 값입니다.
  - 클래스 따옴표 안: 48 (0.6 s)
  - 이름 따옴표 안: Frame 읽기 표면 45
  - 래퍼 파라미터 안 이름: 45, 이벤트: 27
  - `input.` 뒤: 64
  - `Frame { ` 뒤: 68

---

### M2. 읽기 표면에 ReadOnly 포함

Lib2는 Policy를 두 갈래로 나눴습니다.
- `Deny`: 양쪽 표면에서 막습니다.
- `DenyWrite`: 쓰기 표면에서만 막습니다. 덤프의 readProps와 Parent가 들어갑니다.

readmap은 `collect(c, true)`로 `DenyWrite`를 건너뜁니다(`src/Lib2.luau`의 collect와 readmap). 파일은 `harness/compare/readsurf/use.luau`이고, Studio 사본은 `src/18-read-surface.luau`입니다.

**실측: 체커의 ReadOnly 표시** (Lib2 `rwreport` 모드, 타입 함수 안에서 `properties()`의 read/write 반쪽을 출력)
- 결과 줄은 sync·vsc·pin에서 md5까지 같습니다.
  `[RW] Frame AbsoluteSize=rw,AbsolutePosition=rw,TextBounds=-,ClassName=rw,Parent=rw,Size=rw,Text=-,Visible=rw write=38 readProps=44; TextLabel … write=57 readProps=67; ScrollingFrame … 55/63; TextBox … 65/75`
- **ReadOnly 프로퍼티도 read와 write 반쪽이 둘 다 있고 서로 같습니다.** defs 텍스트에도 `read`/`write` 표기가 0개입니다.
- 그래서 1차 8.22의 "표시 없음"이 타입 함수 API 수준에서도 사실입니다. **쓰기 표면에서 ReadOnly를 빼는 일은 덤프 데이터로 할 수밖에 없습니다.**
- Studio 체커가 다르게 표시하는지는 미측정입니다. 아래 Studio 후보 1번입니다.

**실측: 판정** (sync·vsc·pin 모두 NEG 16/16, OK 16/16, too complex 0; sync 0.98 s / 275 MiB)
- 킷 기준 사례가 통과합니다.
  - `Out "Frame" "AbsoluteSize" (pixels)`, 여기서 `pixels: Source<Vector2>` (26행)
  - `Out "TextLabel" "TextBounds"`, `Out "TextBox" "Text" (value)`
  - `TextBox { Out "TextBox" "Text" (value), Text = value }`
  - `OnChange "ScrollingFrame" "CanvasPosition" (function(pos: Vector2) end)`
  - 이름 붙은 콜백 `writeBack(text: string)`
  - `OnChange "Frame" "AbsoluteSize" (function(v) … v.X … end)`, hover `v: Vector2` (33행)
- 거부도 맞게 됩니다.
  - 틀린 Source 타입(40·41행), 본문 오용, 틀린 주석
  - Frame에 없는 이름, `DataCost`(양쪽 Deny)
- 쓰기 표면은 여전히 ReadOnly를 거부합니다. `Frame { AbsoluteSize }`(48행), `TextLabel { TextBounds }`, `Parent`, Modifier 세터 `:AbsoluteSize`(51행), Spread 전부입니다.
- **Q127 (a)와 같이 섭니다.**
  - `NextSelectionUp`의 읽기 타입은 `GuiObject?`이고, `OnChange`에서 non-nil 지역 변수에 담으면 거부됩니다.
  - `Parent`는 `Instance?`, `Size`는 `UDim2` 그대로입니다.
  - 새로 본 것이 하나 있습니다. **`Out "Frame" "NextSelectionUp"`에 non-nil인 `Source<GuiObject>`를 주면 Source가 불변이라서 거부됩니다(56행).** 소비자는 `Source<GuiObject?>`로 선언해야 합니다. 킷은 이 자리를 쓰지 않습니다.
- 디스크립터를 배열부에 넣으면 클래스의 읽기 이름과 대조됩니다. Lib2 elem에 `__quadChange` 팔을 추가했습니다. `Frame { Out "TextBox" "Text" (value) }`(63행)와 `Frame { Out "TextLabel" "TextBounds" … }`가 거부됩니다.
- 잡음: 틀린 Source 한 건에 진단이 94~95줄 붙습니다. 1차와 같은 모양입니다.

---

### M3. Modifier의 As* / Into / Overridden / 숏핸드 setter

**실측: 지금 생성 표면의 목록** (`quad-roblox/src/Declaration/init.luau`)
- `<Class>Modifier`는 47벌입니다(5050~5096행 ModifierNS). 예약 메소드는 모두 같습니다.
  - `Peek`
  - `Apply(self: any)`
  - `Overridden: (self, ...any) -> any`
  - 무검사 `As: <T>(self, name: string?) -> T`
  - 항등 `As<Self>`
- 추상 클래스는 스코프 안 하위 클래스마다 `As<Desc>`를 가집니다. GuiObject는 항등을 포함해 13개입니다(2637행부터). 잎 클래스는 항등뿐입니다(Frame, 2399~2401행).
- `Into<C> = { As<C>: (self: any) -> <C>Modifier }`가 47벌입니다(2446행 등).
- 숏핸드 setter 넷(`UICorner`, `UIPadding`, `UIPaddingOffset`, `UIScale`)은 GuiObject 계열 13개 타입에 있습니다.

**실측: 킷 grep** (quad-roblox-devui, quad-roblox-material)
- `D.Modifier.<C>` 사용처: Frame 134, TextButton 61, TextLabel 13, TextBox 5, GuiObject 3
- 이어 부르는 세터: Name 82, Size 57, LayoutOrder 28, BorderSizePixel 24, Position 22, BackgroundTransparency 13, AutomaticSize 8, AnchorPoint 6, FontFace·TextSize·LineHeight 각 3, ClipsDescendants·TextXAlignment 각 2, TextWrapped·AutoButtonColor·Text·ZIndex 각 1
- As 사용: `AsGuiObject` 4, `AsTextButton` 2, `AsFrame` 2. 자리는 material `Card.luau` 214·237행, `List.luau` 267·299행이고 모두 `props.Modifier:AsGuiObject():As…()` 꼴입니다.
- Into: `IntoGuiObject?`가 prop 타입으로 2곳(`Card.luau:81`, `List.luau:97`) 쓰이고, 나머지는 `Quad.luau`의 재수출뿐입니다.
- 쓰이지 않는 것: Modifier `Overridden` 0곳(`isOverridden`은 무관), Modifier 숏핸드 setter 0곳(props 꼴 `UICorner = …`만 씀), Modifier의 `:Apply` 0곳
- 나머지 꼴: prop 타입 `Modifier: <C>Modifier?` 약 120곳, 배열부에 `props.Modifier or q.None` 67곳, 모듈 수준 base Modifier를 다시 체인하는 꼴

**Lib2 구현** (프로브 선택이지 결정이 아님)
- `modOf`는 한 Build 호출 안에서 클래스별로 메모이즈하며 As 트리를 만듭니다. 하강 목록은 `Policy.Classes`(47 맵)에서 구합니다.
- `ModifierInto<C> = IntoWith<C, Modifier<C>>`입니다. 별도 타입 함수가 이미 만든 Modifier를 인자로 받습니다.
- 숏핸드는 별도 Policy 필드 `Shorthand`로 뺐습니다. `Inject`와 섞으면 한 데이터가 두 일을 하게 되기 때문입니다. 숏핸드 값의 State 팔은 nil과 None을 받습니다.
- 비교용 손잡이로 `AsDepth`를 넣었습니다. 0은 항등만, 1은 하강 결과에 2단 하강이 없는 꼴입니다.

**실측: 판정** (`harness/compare/modfull/use.luau`, Studio 사본 `src/20-modifier-as.luau`)
- **vsc: NEG 14/15, OK 29/30.** 킷 꼴이 전부 섭니다.
  - 모듈 수준 Name, 세터 체인, 저장한 base 재체인
  - `Modifier<TextButton>?` prop
  - `ModifierInto<GuiObject>?` prop과 `AsGuiObject():AsTextButton()` / `AsFrame()`, 커스텀 Into 구현
  - 2단 하강, `As<<T>>()` 명시
  - 숏핸드 setter와 props 숏핸드(GuiObject 밖에서는 거부)
  - 형제 클래스·무관 클래스 배치 거부, 잎에서의 하강 거부, 검사형 상향 거부
- **sync: OK 23/29, too complex 7.** Into가 걸린 줄(46·47·49·50·53·54행)이 전부입니다. NEG는 14/15로 유지됩니다.
- **놓친 b2(40행, `Modifier<TextButton>?` prop이 Frame Modifier를 받음)와 잡음 d7(62행, 주석만으로 `As()`의 T 추론)은 생성 D에서도 똑같습니다.** 대조 파일은 `harness/compare/modfull/gend-control.luau`(vsc)입니다. 14·16행이 MISS, 19행이 NOISE입니다.
  - 생성 D도 **옵셔널 함수 파라미터 `IntoGuiObject?`**에서 GuiObject Modifier를 거부합니다(8행).
  - Lib2도 같습니다(`into-ident.luau` 14·15·17행, vsc).
  - 킷이 쓰는 props 테이블 필드 꼴은 통과합니다.
  - 즉 이 셋은 타입 함수 때문이 아니라 원래 있던 솔버 동작입니다.

**실측: sync too complex의 원인 가르기** (`harness/compare/modfull/into-ident.luau`, use-as1/use-as0)
- 같은 `Modifier<GuiObject>`라도 표기가 다르면 too complex입니다. `L.Modifier<GuiObject>`에 `Modifier<index<ModClassMap,"GuiObject">>`를 대입하면 19행에서 too complex입니다. 표기가 같으면(20행) 통과합니다.
- IntoWith의 인자도 또 하나의 사본입니다.
- AsDepth 0은 표기가 달라도 통과합니다(27행). AsDepth 1은 실패합니다(26행). 잎 Frame은 전체 트리여도 통과합니다.
- AsDepth 0 변형 전체는 sync에서 too complex 0입니다. 대신 As 하강을 잃습니다.
- **추정:** 타입 함수 결과는 축약할 때마다 새 사본이라 이름 정체성이 없습니다. 그래서 큰 그래프(추상 클래스와 하위 13벌)끼리 구조 비교가 일어납니다. 생성 D는 이름 붙은 별칭이라 정체성 비교로 끝납니다.

**실측: 비용** (`harness/gen-modcost2.py` 생성, `cost-run.py`로 순차 실행)

| 변형 | 50 사용 | 300 사용 | 비고 |
|---|---|---|---|
| full, Into 없음 (sync·vsc 같음) | 0.63 s / 127 MiB | 1.19 s / 151 MiB | NEG 2/2 |
| full + Into, sync | too complex 11 | too complex 61 | NEG 2/2 |
| full + Into, vsc | 0.96 s | 2.37 s | too complex 0 |
| AsDepth 0 | 0.52 s / 94 MiB | 0.73 s / 118 MiB | |

**실측: hover와 자동완성** (sync)
- 팩토리 hover: `function FrameModifier(...: any): { Active: (*CYCLE*, …) … 47 more … }`
- 값 hover: `t1 where t1 = { … 47 more }`. 1차, 생성 D와 같은 전개입니다.
- `m:` 자동완성: Frame 47개(0.27 s), GuiObject 58개(As 13개 포함, 0.57 s)
- `Overridden`의 반환 hover는 `any`입니다. 확정대로 타입드 `q.Modifier "Frame"`에는 `Overridden`이 없고, 값 타입의 메소드 꼴만 남습니다. `Raw.Modifier.Overridden`은 base 몫이라 이 프로브 밖입니다.

**미측정**
- 숏핸드 유니언 값 `number | UDim`의 Tween 팔. 생성 FieldN에는 있고 프로브에서는 생략했습니다.
- 문자열 인자 As를 바깥 교집합으로 미루는 꼴. 세터가 self(Build 부분)만 돌려줘서 체인 뒤에 사라지는 구조라 시도만 검토하고 재지 않았습니다.

---

### M4. 클래스 맵 확장

**덤프 출처.** `scripts/gen-d.py normalize`는 setup.rbxcdn.com의 raw `<ver>-API-Dump.json`을 읽습니다. 커밋된 `quad-roblox/dump/api-surface.json`에는 31개 클래스뿐이라, raw 덤프 둘을 스크래치패드에 내려받았습니다.
- `version-268c7d941ba34c1a`: 지금 D가 만들어진 덤프입니다. 확장 defs에 353개 중 352개가 있습니다.
- `version-4f087c32742644ab`: 오늘의 Studio 0.743 덤프입니다. 확장 defs(`globalTypes.PluginSecurity.d.luau`, 2026-10-19 09:54 갱신)에 361개가 전부 있어서 이쪽을 썼습니다.

**실측: 개수** (4f08)

| 집합 | 클래스 수 |
|---|---|
| Instance 하위 전체 | 908 |
| 만들 수 있는 것(NotCreatable·Service 제외) | **361** (그중 Deprecated/NotBrowsable 45) |
| 위 361 + 그 조상 | **417** |
| Service가 아닌 것 전부 | 567 |

**생성물.**
- 생성기 `harness/gen-fullmaps.py`가 `src/FullMaps.luau`를 만듭니다(1027줄).
  - `CreatableMapFull` 361, `ModClassMapFull` 417
  - 이름 리터럴 유니언 둘
  - 정의 클래스(owner) 기준 Policy: `DenyIn` 142 owner / 596 이름, `DenyWriteIn` 78 / 159
  - 태그 규칙은 gen-d의 PROP_TAG_EXCLUDE, HIDDEN_NAME_KEEP, DEPRECATED_NAME_KEEP와 같습니다.
- `src/FullMapsKeep.luau`는 같은 생성기에 `--keep-hidden Position,Orientation,WorldPosition,WorldOrientation`을 준 것입니다.

**실측: 맵만 다는 비용**
- 모듈 단독: 0.44 s / 68 MiB
- 팩토리 셋의 타입만 단 소비 파일(`fullmap/maponly-full.luau`): 0.46 s / 67 MiB. 31 맵 대조군(`maponly-31`)과 같습니다.
- 견고성: `brief` 모드로 361개를 한 유니언에서 돌리면(`fullmap/brief-all.luau`) 전부 표면이 나옵니다. 빈 클래스 0, 최대 HumanoidRigDescription 115, 중앙값 18입니다. 타입 함수 런타임 에러는 없었습니다. 1.53 s / 1090 MiB입니다.

**실측: 판정** (`fullmap/use-lit.luau`, Studio 사본 `src/23-fullmap.luau`)
- sync·vsc 모두 **NEG 21/21**입니다.
- 통과하는 것:
  - `Elem "Part" { Anchored = true, Size = Vector3… }`
  - `Shape`, `Position`(Keep 판), `Transparency`, `CFrame`
  - `Sound`, `ParticleEmitter`(ColorSequence) 값
  - BasePart Modifier와 Spread를 Part에 넣기
- 거부하는 것:
  - `Anchored = 5`, `Size = UDim2`
  - ReadOnly `AssemblyMass`, `Sound.TimeLength`
  - `Parent`, Part에 `UICorner`
  - 추상 클래스, 서비스(`Workspace`), 오타
  - Part Modifier를 Frame에, GuiObject Modifier를 Part에, BasePart Spread를 Frame에 넣기
  - Frame에 `Touched` 디스크립터

**비GUI 클래스에서 Policy가 문제를 내는가 — 실측상 셋 냅니다.**
1. **1차 Lib의 전역 이름 Deny가 `Part.Shape`를 지웁니다.** `Shape`가 어느 GUI 클래스에서 드롭된 이름이라서입니다(`fullmap/lib2policy-part.luau` 5행 거짓 양성). 정의 클래스 기준으로 바꾸면 통과합니다.
2. **gen-d의 Hidden 규칙은 비GUI 핵심 프로퍼티를 지웁니다.** 덤프에서 BasePart의 `Position`·`Orientation`, Attachment의 `Position`·`Orientation`·`WorldPosition`·`WorldOrientation`이 Hidden 태그입니다. 그대로 두면 `Part { Position = … }`가 거부됩니다(`fullmap/use.luau` 22행). Keep 판에서는 통과하므로, 고치는 것은 허용목록 데이터를 늘리는 일입니다.
3. **API 버전이 흘렀습니다.** 4f08에서 `GuiObject.Transparency`가 Hidden·NotReplicated에 더해 **Deprecated**가 됐습니다. 지금 규칙(DEPRECATED_NAME_KEEP에 Transparency가 없음)대로면 다음 덤프에서 이 프로퍼티가 조용히 빠집니다. Frame props가 67 대 68로 갈린 이유입니다.

Child, Inject, Shorthand(GuiObject 키)는 비GUI에서 문제가 없었습니다.

**실측: too complex — 원인은 클래스 이름 바운드입니다.** 맵 크기가 아닙니다.
- `harness/compare/mapsize/`(반환이 클래스뿐): sync에서 `K & keyof<Map>`은 130개까지 깨끗하고 140개부터 too complex입니다. 이름을 리터럴 유니언으로 주면 361개에서도 깨끗합니다.
- `mapsize2/`(반환이 Elem 모양 생성자): keyof는 130개까지, 200개부터 실패입니다. 리터럴 유니언은 361개에서도 깨끗합니다. **단 클래스가 유니언 앞쪽에 있을 때만입니다.**
  - 같은 유니언을 알파벳순으로 두면(`lit-361-sorted`) Frame(143번째), Part(203번째), TextLabel(307번째)가 모두 too complex입니다. 역순도 같습니다.
  - GUI를 앞에 둔 361 유니언(`guifirst-big-361.luau`, Studio 사본 `src/22-mapsize-position.luau`)에서는 MeshPart@214, ParticleEmitter@231, Seat@279, SpawnLocation@294, Tool@327, Trail@331, TrussPart@333, VehicleSeat@344, WedgePart@352가 실패합니다. 프로퍼티가 많은 **Beam은 96번째인데도** 실패합니다. Part/Sound/Model@1~3은 통과합니다.
  - **즉 실패는 유니언 안의 위치와 클래스 표면 크기 둘 다에 걸립니다.**
  - `K & string`은 K가 string으로 넓어져 쓸 수 없고, `K & (Names | string)`이나 `keyof & string`도 실패합니다(`alt-*`).
- 모듈 경계를 넘을 때(`mapsize3/`): 앞쪽 배치 유니언은 361개에서도 깨끗하고, 팩토리째 export한 꼴도 깨끗합니다. `FullMaps`(알파벳순)에서 import했을 때만 실패합니다. 위치 효과입니다.
- vsc(override)에서는 361개 생성자 바운드가 통과합니다. 하지만 **417개 ModClass 바운드는 vsc에서도 늦은 이름에서 실패합니다.** 8건이고, `Spread "PVInstance"`와 `OnChange "Part"` 등입니다.
- **too complex가 나도 NEG는 잃지 않았습니다.** 전 파일에서 NEG가 다 잡혔고 타입은 흐릅니다. 대신 그런 꺼내기 줄마다 빨간 "Code is too complex" 에러가 남습니다.
- 대안 재료: **분야별 맵 84개(3D/월드)**(`mapsize2/cat3d.luau`, Studio 사본 `src/24-cat3d.luau`)는 sync에서 큰 클래스 전부 깨끗합니다.

**실측: 꺼내 둔 생성자의 사용량별 비용** (`harness/compare/fullcost/`, sync, 20 → 300 사용)

| 변형 | 20 사용 | 300 사용 | too complex |
|---|---|---|---|
| map31 | 0.48 s / 78 MiB | 0.50 s / 94 MiB | 0 |
| full | 0.75 s / 120 MiB | 0.78 s / 127 MiB | 5 (꺼내기 줄) |
| fullnongui | 0.72 s / 106 MiB | 0.70 s / 112 MiB | 4 |
| full, vsc | 1.53 s / 180 MiB | 1.64 s / 188 MiB | 0 |
| map31, vsc | 0.47 s | 0.55 s | 0 |

사용량에 대해서는 평평하고, 상수 비용이 sync 약 +0.3 s, vsc 약 +1.1 s 붙습니다.

**실측: 자동완성 지연** (최소 파일 `fullmap/lat-full.luau` 대 `lat-31.luau`)

| 자리 | 전체 맵 (sync / vsc) | 31 맵 |
|---|---|---|
| `Elem "` | 362개, 0.19 s / 0.50 s | 32개, 0.01 s |
| `Frame { ` | 0.36 s / 0.92 s | 0.02 s |

진단이 많은 큰 파일(use-lit)에서는 `Part { `가 1.20 s / 4.39 s였습니다.

**실측: 417개 맵 위의 전체 As 트리** (`fullmap/modas-*`, sync)

| 클래스 | 시간 / 메모리 |
|---|---|
| Part | 0.67 s / 109 MiB |
| BasePart | 0.90 s / 275 MiB |
| GuiObject | 0.83 s / 219 MiB |
| PVInstance | 1.10 s / 485 MiB |
| Instance | 3 GiB 상한에서 9.8 s 뒤 `std::bad_alloc` — 여기서 멈춤 |

Instance 행은 N을 줄여서 다시 돌리지 않았습니다.

**실측: pin 모드.** 확장 defs로 만든 맵은 레포 핀 defs에 없는 클래스를 가리킵니다(`Unknown type 'AdPlacement'` 등). 그래서 맵 전체가 깨지고 OK 0/20입니다.
- **추정:** 생성 시점의 덤프나 defs와 사용자 체커의 클래스 집합이 어긋나면 맵 모듈이 통째로 깨집니다. 타입 함수 안에서 전역 클래스를 나열하는 API는 없는 것으로 보입니다(미확인).

---

### 종합 (결정 재료)

1. **M1·M2는 확정 표면 그대로 섭니다.** M2에서 ReadOnly를 쓰기 표면에서 빼는 일은 체커에 표시가 없으므로 덤프 데이터(`DenyWrite`)로 갈라야 합니다. Q127 (a) 아래에서는 객체 참조를 쓰는 `Out`의 Source를 `T?`로 선언해야 합니다.
2. **M3.** 타입 함수 Modifier는 킷 꼴을 vsc에서 전부 재현합니다. sync에서는 **추상 클래스의 As 트리와 Into의 조합이 무너집니다.** 재료로 갈래 셋이 보입니다. 정하는 것은 사용자입니다.
   - (a) As 하강을 버리고 무검사 `As<<T>>()`만 둡니다. AsDepth 0이고, sync에서 깨끗합니다.
   - (b) Into·As용 이름 별칭만 생성기로 남깁니다. 정체성 비교가 되는 길입니다. 다만 사용자가 클래스별 복제를 제거하기로 한 결정과 부딪힙니다.
   - (c) 하강 대상 목록을 실사용(GuiObject→TextButton/Frame)으로 좁히는 데이터를 둡니다. 미측정입니다.
3. **M4.** 맵과 Policy 데이터 자체는 싸고, 정의 클래스 기준 Policy가 비GUI 오판을 고칩니다. 하지만 **한 바운드에 361~417개 이름은 sync 한도에서 서지 못합니다.** 갈래는 둘이 보입니다.
   - (a) 지금처럼 GUI 중심의 작은 맵을 유지합니다.
   - (b) 분야별로 100개 이하인 맵 여러 개로 나눕니다. 84개 실측은 깨끗했습니다.
   - 어느 쪽이든 Hidden 허용목록을 비GUI로 넓히는 일과 Transparency 드리프트 대응은 데이터 몫입니다.
4. 놓침과 잡음 가운데 b2, 옵셔널 Into 파라미터, `As()` 추론은 생성 D와 같은 동작입니다. 이번 전환으로 새로 생기는 결함이 아닙니다.

### Studio 확인 후보 (메인이 싱크해 `studio-analysis`로)

1. `src/18-read-surface.luau`: `[RW]` 진단 한 줄이 핵심입니다. Studio 체커가 ReadOnly를 `r`만으로 표시하는지, 아니면 리눅스처럼 `rw`인지 봅니다. NEG 16개의 대조도 같이 봅니다.
2. `src/20-modifier-as.luau`: 46~54행의 too complex가 Studio에서 sync와 같은지, 40행 MISS가 같은지 봅니다.
3. `src/21-into-ident.luau`: 표기가 다른 Modifier 사본 비교(19·26행)에서 too complex가 나는지 봅니다.
4. `src/22-mapsize-position.luau`: 어느 꺼내기 줄이 too complex인지, 위치와 크기 효과를 봅니다.
5. `src/FullMapsKeep.luau`와 `src/23-fullmap.luau`: **Studio의 클래스 집합에 없는 이름 때문에 생기는 `Unknown type` 개수가 핵심입니다.** too complex 줄도 같이 봅니다.
6. `src/24-cat3d.luau`: 진단이 3건(NEG만)이어야 정상입니다.
7. `src/19-typeof-q.luau`: M1의 NEG 대조입니다. 인라인 블록 때문에 줄 번호가 harness 판과 다릅니다.

### 새로 만든 파일

모두 `이 폴더 ` 아래입니다.
- `src/`
  - `Lib2.luau`
  - `FullMaps.luau`, `FullMapsKeep.luau` (생성물)
  - `18-read-surface.luau`, `19-typeof-q.luau`, `20-modifier-as.luau`, `21-into-ident.luau`, `22-mapsize-position.luau`, `23-fullmap.luau`, `24-cat3d.luau`
- `harness/` 도구
  - `diag-lines.py`
  - `gen-fullmaps.py`, `gen-modcost2.py`, `gen-fullcost.py`, `gen-mapsize.py`, `gen-mapsize2.py`, `gen-mapsize3.py`
- `harness/compare/` 프로브 폴더
  - `qtypeof/` (Ext2, use)
  - `readsurf/use.luau`
  - `modfull/` (use, use-as0, use-as1, into-ident, gend-control)
  - `modcost2/` (8개)
  - `fullmap/` (use, use-lit, iso-a~e, lat-31/full, maponly-31/full, modas-* 5개, lib2policy-part, brief-all)
  - `fullcost/` (12개), `mapsize/` (24개), `mapsize2/` (28개), `mapsize3/` (24개)
- `out/r2/`: 원 출력 29개와 `summary-neg-ok.txt`

raw 덤프는 레포 밖 스크래치패드에 있습니다. 다시 받는 방법은 `curl -s -o X https://setup.rbxcdn.com/version-4f087c32742644ab-API-Dump.json`입니다.

## Declaration 타입 함수 표면 M3 후속 실측 보고: Into 자리의 too complex (2026-10-19) [opus 서브에이전트, 본문 그대로 저장]

이 보고는 결정이 아니라 재료입니다. 기존 파일은 고치지 않았습니다. 새 파일은 `src/Lib3.luau`, `src/25~29-*.luau`, `harness/compare/modinto/` 아래에만 있습니다. git 조작은 하지 않았고 코어 덤프도 없습니다. 모든 실행은 `run-cli.sh`(choom 1000, prlimit 3 GiB)를 거쳐 순차로 돌렸고 `RLIMIT_CORE=0`을 걸었습니다. 모드 이름은 2차와 같습니다. sync가 기준이고, vsc는 override를 켠 상태, pin은 1.69.0입니다.

### 요약

- **(다) 하강 목록 좁히기는 효과가 있습니다.** 문턱은 다음과 같습니다(sync, Lib2 꼴 `IntoWith`).
  - GuiObject 하강이 **2~3개**면 킷 꼴(본문과 호출 자리)이 전부 깨끗하고 NEG도 전부 잡힙니다.
  - **4개**에서는 본문은 깨끗하지만 호출 자리(`Card({ Modifier = … })`)가 too complex입니다.
  - **5개 이상**이면 전체(13)와 똑같이 다 무너집니다.
  - 실사용 최소(Frame·TextButton)는 300 사용에서도 too complex가 0입니다.
- **(라) 얇은 Into는 sync에서 아무것도 바꾸지 못합니다.** 자기 생성 꼴, `IntoThinWith` 꼴, 같은 모듈 별칭 반환을 손으로 쓴 꼴, 생성 D 모양을 손으로 쓴 꼴 모두, 같은 As 트리 크기에서 전체 Into와 같은 줄이 무너집니다.
  - 원인은 태그가 아니라 **메소드 반환 `Modifier<GuiObject>`끼리의 사본 비교**입니다. 태그만 있거나, 태그에 `any`나 한 필드 테이블을 반환하는 메소드를 붙이면 전체 트리에서도 깨끗합니다.
- **곁가지 실측(새 메커니즘이라 사용자 문항감):** prop을 **태그만 있는 Into**로 두고 본문에서 **자유 함수** `ToGui(m)`로 바꾸면 전체 13 트리에서도 sync too complex가 0입니다. NEG도 다 잡힙니다. 킷 표기는 `props.Modifier:AsGuiObject()`에서 함수 호출로 바뀝니다.
- **vsc·pin에서는** (다)·(라) 모든 변형이 too complex 0이고 OK 전부 깨끗, NEG 전부 적중입니다.

### 공통 재료

- **Lib3**(`src/Lib3.luau`)은 Lib2를 복사한 뒤 다음을 더한 것입니다.
  - `Policy.AsTargets = { [Class]: { [Desc]: true } }`: 이 필드가 있으면 `modOf`가 나열된 하강만 만들고, 나열되지 않은 클래스는 항등만 가집니다(`modOf`의 `allow` 분기).
  - 정책 `PolicyT2/T2big/T3/T4/T5/T6/T7/T10/T13/T13n`과 `PolicyFull`(Lib2와 같은 트리)
  - `Build "intothin"`, `IntoThinWith`
  - 정책을 인자로 받는 별칭 `ModP/IntoP/IntoThinP/IntoThinWithP`
  - Deny 계열 export
- T 목록에서 조상 셋(GuiBase2d·GuiBase·Instance)은 `{ GuiObject }`만 갖도록 데이터로 넣었습니다. 그래야 조상 Modifier가 Into<GuiObject>에 들어갑니다.
- **템플릿 `modinto/gen-use.py`**는 변형마다 줄 번호가 같은 파일을 만듭니다(`use-<정책>-<Into꼴>[-direct].luau`, 27개).
  - 킷 꼴(22~32행): prop `Modifier: IntoG?`, 본문 `props.Modifier:AsGuiObject():AsTextButton()`/`AsFrame()`, 킷처럼 다른 props와 섞은 요소(25행), 체인 뒤 세터(26·27행), GuiObject·GuiBase2d·Instance Modifier 넣기
  - 부정 사례:
    - 하강 클래스(Frame·TextButton)와 형제 가지(ScreenGui)·무관 클래스(UIListLayout)를 Into에 넣기(34~37행)
    - 잘못된 요소나 세터(38~40행)
    - 잎·상향(48·49행)
    - 목록 밖 하강(50~56행, 정책마다 NEG/OK 표지가 바뀜)
  - 판정은 `diag-lines.py`로 했습니다. 64행 custom Into는 `-- SEMANTIC` 표지라 집계에서 뺐습니다.
- 출력: `modinto/out/summary-neg-ok.txt`(전 파일·전 모드), `out/<파일>-<모드>.txt`(원 출력, 줄을 잘랐음), `out/cost-*.txt`, `out/lsp-*.txt`

### (다) 하강 대상을 데이터로 좁히기

**실측(sync, `use-*-with.luau`, Into = Lib2 꼴 `IntoWith`, 팩토리는 `Modifier "X"`)**

| 정책 (GuiObject 하강 수) | 본문 23~27행 | 호출 자리 29~32행 | `local i: IntoG =` 42·43행 | i4 교차 표기 | NEG | too complex | 시간 / RSS |
|---|---|---|---|---|---|---|---|
| T2 (Frame, TextButton) | 깨끗 | 깨끗 | ✗ | 깨끗 | 18/18 | 2 | 0.67 s / 129 MiB |
| T2big (TextBox, ScrollingFrame) | (목록상 정상 에러) | 깨끗 | ✗ | – | 17/17 | 2 | 0.70 s / 129 MiB |
| T3 (+TextLabel) | 깨끗 | 깨끗 | ✗ | ✗ | 17/17 | 4 | 0.69 s / 144 MiB |
| T4 (+TextBox) | 깨끗 | **✗** | ✗ | ✗ | 17/17 | 9 | 0.83 s / 157 MiB |
| T5 (+ImageButton) | ✗ | ✗ | ✗ | ✗ | 17/17 | 20 | 0.80 s / 169 MiB |
| T6, T7, T10, T13(평평), T13n(2단) | ✗ | ✗ | ✗ | ✗ | 전부 적중 | 20 | 0.85~1.27 s / 179~270 MiB |
| full (Lib2 트리, 대조군) | ✗ | ✗ | ✗ | ✗ | 12/12 | 20 | 1.76 s / 423 MiB |

- 문턱은 **클래스 표면 크기가 아니라 트리의 노드 수**를 따라가는 것으로 보입니다. 큰 잎 둘인 T2big도 호출 자리가 깨끗합니다.
- 표의 노드 수는 GuiObject 하나에 하강 N개입니다. T 정책에서 조상 Modifier는 GuiObject 노드를 하나 더 가집니다.
- 지역 변수 주석 꼴 `local i1: IntoG = GuiObjectModifier()`는 T2에서도 too complex입니다. 킷은 이 꼴을 쓰지 않고 props 테이블 필드만 씁니다. 옵셔널 함수 파라미터 꼴은 이번에 재지 않았습니다.
- 목록 밖 하강은 정책 표지 그대로 전부 NEG로 잡힙니다.
  - 예: T2의 `AsTextLabel`·`AsScrollingFrame`·`AsViewportFrame`·`AsGuiButton():AsTextButton()`
  - `InstanceModifier():AsFrame()`과 `GuiBase2dModifier():AsTextButton()` 직행은 T 목록에서 NEG입니다. 생성 D는 Instance→46개 전부를 허용하므로 **의미가 달라집니다.**
- **vsc·pin**: T2~T13n과 full이 모두 too complex 0, OK 전부 깨끗, NEG 전부 적중입니다(`out/summary-neg-ok.txt`). pin은 느립니다(full 2.68 s / 697 MiB, T2 1.17 s / 168 MiB).
- 데이터 비용(추정): 이 목록은 "어느 클래스가 무엇으로 하강하는가"를 클래스마다 적는 데이터입니다. 목록에 없는 추상 클래스(GuiButton, UIComponent, LayerCollector 등)는 하강을 잃습니다. 조상→GuiObject 행처럼 조상 쪽 행도 따로 적어야 합니다.

### (라) 얇은 `ModifierInto<C>`

**실측(sync)**

| Into 꼴 | full 트리 | T2 | T7 | T13n |
|---|---|---|---|---|
| with (Lib2 `IntoWith`) | tc 20, 본문과 호출 ✗ | tc 2 (i1·i2만) | tc 20 | tc 20 |
| thin (자기 생성, 태그 + `As<C>`) | tc 21, 같은 줄 ✗ | – | – | – |
| thinwith (`IntoThinWith<C, Modifier<C>>`) | tc 21 | tc 2 | tc 21 | tc 21 |
| thinhand (손 별칭: 태그 + `AsGuiObject: (self: any) -> Mod<GuiObject>`) | tc 21 | tc 2 | tc 19 | tc 21 |
| hand (생성 D 모양, 태그 없음, 별칭 반환) | tc 20 | – | – | – |

- **대입 비교는 태그와 메소드 하나로 줄어들지 않습니다.** 메소드 반환 `Modifier<GuiObject>`와 값 쪽 `AsGuiObject`의 반환(값 자신의 그래프)을 사본끼리 구조 비교하기 때문입니다.
- 근거: `modinto/iso-thin-parts.luau`, full 트리, sync와 vsc 모두 NEG 3/3, OK 6/6, too complex 0입니다.
  - 태그만: 깨끗
  - 태그 + `AsGuiObject: (self: any) -> any`: 깨끗
  - 태그 + `-> { read __quadModifier: "GuiObject" }`: 깨끗
  - 즉 태그 검사는 싸고, Modifier 사본을 반환하는 메소드를 붙이는 순간만 무너집니다.
- **같은 모듈 별칭으로 반환을 명시해도(thinhand) 사본 비교가 일어납니다.**
- **팩토리를 직접 표기한 변형**(`-direct`: `(...any) -> Mod<GuiObject>`)도 재봤습니다.
  - hand와 thinhand에서만 같은 클래스 값(k1·k2)과 i4가 깨끗해집니다. 정체성이 맞기 때문입니다.
  - 조상 값(k3·k4)과 본문은 여전히 ✗입니다. 조상 그래프 안의 GuiObject 노드는 또 다른 사본입니다.
  - with와 thinwith는 직접 표기여도 k1·k2가 ✗입니다. 타입 함수 인자로 넘긴 Modifier는 정체성이 유지되지 않는 것으로 보입니다(추정).
- 의미 차이(실측): 태그 없는 custom Into(`{ AsGuiObject = function … }`, 64행)는 다음과 같습니다.
  - with와 hand는 받습니다.
  - thin 계열은 vsc·sync(T2)에서 `Expected 'IntoG?', got 'custom'`으로 거부합니다.
  - 킷은 custom Into를 쓰지 않습니다(2차 grep).
- vsc·pin: 모든 thin 변형이 too complex 0입니다. NEG와 OK는 with와 같고, 진단 줄이 하나 더 있는 것은 위 custom 거부입니다.

### 본문(`AsGuiObject():AsTextButton()`)이 무너지는 자리

`modinto/iso-into.luau`(full, 생성 D 모양의 hand Into, sync)에서 갈랐습니다.

| 꼴 | 행 | 결과 |
|---|---|---|
| `local x = m:AsGuiObject():AsTextButton()` | 14 | 깨끗 |
| 첫 홉만 지역에 담은 뒤 `TextButton { g:AsTextButton() }` | 16 | 깨끗 |
| 같은 표기 주석 | 17 | 깨끗 |
| Into 없이 `m: Mod<GuiObject>`로 같은 체인을 요소에 인라인 | 18·19 | 깨끗 |
| 요소 안 인라인 체인 | 15 | ✗ |
| 킷 꼴 `if m then … else None` | 20 | ✗ |
| if 식 전체를 지역에 담기 | 21 | ✗ |
| `:: Mod<TextButton>` 캐스트 | 22 | ✗ |
| 첫 호출을 괄호로 묶기 | 23 | ✗ |

- 에러 열은 체인 식의 시작입니다.
- **추정:** Into 메소드가 돌려준 Modifier에 다시 메소드를 부르는 식이 기대 타입(요소의 배열부 유니언이나 None 유니언)과 함께 검사될 때 한도를 넘습니다.
- `iso-body.luau`(Into 없음, 12꼴)는 줄 진단이 0입니다. 그러나 경로가 `../../../../../../../../..(1,1)`인 too complex가 한 건 붙습니다. 어느 모듈인지는 특정하지 못했습니다.

### 곁가지 실측: 태그만 있는 Into와 자유 함수

새 이름과 메커니즘이므로 결정이 아니라 문항감입니다.

- `modinto/iso-tagfn.luau`, full 트리입니다.
  - prop: `{ read __quadModifier: "GuiObject" | "GuiBase2d" | "GuiBase" | "Instance" }?`
  - 본문: `ToGui(props.Modifier):AsTextButton()`, 여기서 `ToGui: (m: IntoTag) -> Mod<GuiObject>`
- 결과: sync와 vsc 모두 NEG 4/4, OK 5/5, too complex 0입니다.
  - 잡히는 것: Frame·ScreenGui 값 거부, 잘못된 요소, Frame에 Text
  - 통과하는 것: 조상 Instance 값, 체인 뒤 세터
- 비용(300 사용, sync): 1.34 s / 181 MiB입니다. Into를 쓰지 않는 대조군은 1.35 s / 151 MiB입니다.
- 킷 표기는 메소드 꼴 `props.Modifier:AsGuiObject()`에서 함수 꼴로 바뀝니다.

### 비용

`modinto/gen-cost3.py`로 생성하고 `cost-run.py`로 순차 실행했습니다. sync 기준이며, 5번째 사용마다 GuiObject Modifier를 Card에 넘깁니다. 출력은 `out/cost-sync.txt`, `out/cost-vsc.txt`입니다.

| 변형 | 50 사용 | 300 사용 | too complex (50 / 300) |
|---|---|---|---|
| full, Into 없음 | 0.71 s / 127 MiB | 1.35 s / 151 MiB | 0 / 0 |
| full + with | 0.89 s / 173 MiB | 1.75 s / 198 MiB | 11 / 61 |
| full + tagfn | 0.78 s / 156 MiB | 1.34 s / 181 MiB | 0 / 0 |
| T2, Into 없음 | 0.60 s / 102 MiB | 0.80 s / 126 MiB | 0 / 0 |
| T2 + with | 0.66 s / 111 MiB | 1.09 s / 135 MiB | 0 / 0 |
| T2 + thinwith | 0.65 s / 111 MiB | 1.07 s / 135 MiB | 0 / 0 |
| T3 + with | 0.65 s / 115 MiB | 1.19 s / 139 MiB | 0 / 0 |
| T4 + with | 0.64 s / 122 MiB | 1.01 s / 147 MiB | 10 / 60 |
| T7 + with | 0.75 s / 137 MiB | 1.20 s / 162 MiB | 11 / 61 |

- vsc 수치: T2+with 0.67 s / 1.12 s, full+tagfn 0.79 s / 1.42 s, full+with(300) 2.67 s. 모두 too complex 0입니다.
- T4의 10→60은 호출 자리 수와 정확히 같습니다. **too complex는 모듈 전체 예산이 아니라 자리마다 납니다**(실측).
- NEG 2/2는 모든 파일에서 유지됐습니다.

### hover와 `m:` 자동완성

`out/lsp-sync.txt`, `out/lsp-vsc.txt`에 있습니다.

| 파일 | `GuiObjectModifier():` 개수 (As 수) | Into `props.Modifier:` | Into 체인 뒤 `AsGuiObject():` |
|---|---|---|---|
| full-with | sync 58 (14), 1.17 s / vsc 58, 1.12 s | 1개(AsGuiObject), 2.07 s | **sync는 쓰레기 1개(`AAsTextButton`)로 깨짐** / vsc 58 |
| T2-with | 48 (4: As, AsFrame, AsGuiObject, AsTextButton), 0.22 s | 1개, 0.39 s | sync 48, 0.22 s / vsc 48 |
| T3-with | 49 (5), 0.26 s | 1개, 0.50 s | 49 |
| T13n-with | 58 (14), 0.83 s | 1개, 1.52 s | sync 깨짐 |
| full-thinhand | 58 (14), 1.37 s | 1개, 2.38 s | sync 깨짐 |
| T2-thinwith | 48 (4), 0.23 s | 1개(태그 필드는 안 보임), 0.49 s | 48 |

- hover: Modifier 값은 2차와 같은 `t1 where t1 = {…}` 전개입니다.
- Into prop hover:
  - with 꼴은 `AsGuiObject: (any) -> { Active: … }`로 트리 전체를 펼칩니다(full 1.05 s, T2 0.18 s).
  - thinhand 꼴은 `AsGuiObject: (self: any) -> t16, … 1 more …`로 나옵니다. 별칭 이름은 유지되지 않습니다.

### 따로 표시: 2차의 b2(40행)와 d7(62행)

이번 템플릿에는 넣지 않았습니다. 생성 D와 같은 솔버 동작으로, 2차의 `modfull/use.luau`·`gend-control.luau` 판정 그대로입니다. 위 집계와는 무관합니다.

### 미측정

- 모듈 경계 넘기: Into 별칭과 팩토리를 다른 모듈에서 import하는 실제 킷 구조에서의 정체성과 문턱
- 옵셔널 함수 파라미터 꼴 Into
- Into<C>에서 C가 GuiObject가 아닌 경우
- pin 모드 LSP
- Studio

### 종합 (재료)

1. **(다)가 sync에서 킷 꼴을 살리는 유일한 갈래였습니다.** 단 GuiObject 하강을 2~3개로 좁혀야 합니다. 킷 실사용은 Frame·TextButton 둘입니다.
   - 4개면 호출 자리가, 5개 이상이면 전부 무너집니다.
   - 대가는 셋입니다. 목록에 없는 하강과 조상 직행 하강이 NEG가 되고, 하강 목록 데이터를 따로 유지해야 하며, 목록이 늘면 문턱을 다시 넘습니다.
   - 지역 주석 꼴 Into는 T2에서도 too complex입니다.
2. **(라)는 sync에서 효과가 없습니다.** 메소드 반환이 Modifier 사본인 한 비교 비용이 그대로이고, 태그 없는 custom Into를 거부하는 의미 차이만 생깁니다.
3. **태그만 있는 Into와 자유 변환 함수**는 전체 트리에서도 sync가 깨끗했습니다. 다만 킷 표기와 공개 표면이 바뀌므로 사용자 결정 사항입니다.
4. vsc·pin에서는 어느 갈래든 다 섭니다. 문제는 override 없는 sync(Studio 기본 한도)에만 있습니다.

### Studio 확인 후보 (메인이 싱크해 `studio-analysis`로)

각 사본은 원본과 줄 번호가 같습니다(2행만 안내문으로 바꿨고, require는 `./Lib3`).

1. `src/25-modinto-t2.luau`: too complex가 42·43행 두 줄뿐인지, NEG 18개가 맞는지 봅니다.
2. `src/26-modinto-t4.luau`: 호출 자리 29~32행만 too complex인지 봅니다(문턱 확인).
3. `src/27-modinto-full-thinhand.luau`: (라)가 Studio에서도 같은 줄(23~32, 42, 43, 45, 64, 67, 68행)에서 무너지는지 봅니다.
4. `src/28-modinto-tagfn.luau`: 진단 4건(NEG만)이 정상입니다.
5. `src/29-modinto-iso-into.luau`: 15·20~23행만 too complex인지 봅니다(체인 위치 효과).

### 새 파일

- `이 폴더 src/Lib3.luau`
- `이 폴더 src/25-modinto-t2.luau`, `26-modinto-t4.luau`, `27-modinto-full-thinhand.luau`, `28-modinto-tagfn.luau`, `29-modinto-iso-into.luau` (같은 폴더)
- `이 폴더 harness/compare/modinto/` 아래:
  - `gen-use.py`, `use-*.luau` 27개
  - `iso-body.luau`, `iso-into.luau`, `iso-thin-parts.luau`, `iso-tagfn.luau`
  - `split-body.luau`, `split-call.luau`
  - `gen-cost3.py`, `cost/*.luau` 18개
  - `out/`: `summary-neg-ok.txt`, `cost-sync.txt`, `cost-vsc.txt`, `lsp-sync.txt`, `lsp-vsc.txt`, 파일·모드별 원 출력
- 스크래치(레포 밖): `/tmp/claude-0/-code-Projects-quad/375233bc-c5ce-4803-af8f-62ebd7b9d5c7/scratchpad/runall.py`(순차 실행기), 같은 폴더의 `r3/`(원 출력 원본)

### 메인 추가 실측 — 놓기만 하는 prop은 마커로 [2026-10-19, 메인]

계기: 킷의 Into 자리(material `Card.luau` 214·237행, `List.luau` 267·299행)는 하강한 Modifier에 세터를 더 부르지 않고 요소에 **놓기만** 한다. 런타임은 놓는 자리에서 태그를 보지 않는다(`quad-base/src/Dispatch/Modifier/init.luau` 84행 "a tag only ever gates `As<Name>()`"). 그래서 As 없이 놓는 꼴 둘을 쟀다(정책 full, `harness/compare/modinto/`).
- **`main-place.luau`** — prop을 전체형 `Modifier<GuiObject>?`로 두고 As 없이 놓기, 그리고 원래 설계의 헬퍼 꼴 `Bold(m: Into<TextLabel>)`(`base/modifier-plan.md` 11절). sync: too complex 7(23·24행 호출 자리, 31·35행 GuiObject Modifier를 잎 Into에), NEG 5/7·OK 5/9; vsc: too complex 0, NEG 5/7(25·26행 MISS — Frame·ScreenGui Modifier가 `Modifier<GuiObject>?`에 들어감, 2차 b2와 같은 솔버 동작), OK 9/9. 즉 **사본 비교 문제는 Into 고유가 아니다** — 추상 클래스 Modifier를 다른 표기의 주석 자리로 넘기면 어디서든 sync에서 무너진다(잎 클래스 사이는 2차대로 깨끗).
- **`main-marker.luau`** — prop을 마커 `{ read __quadModifier: "GuiObject" | "GuiBase2d" | "GuiBase" | "Instance" }?`(C와 조상 태그만, 메소드 없음)로 두고 `props.Modifier or None`을 TextButton·Frame에 그대로 놓기. **sync·vsc·pin 모두 too complex 0, NEG 5/5, OK 5/5** — 조상 Instance Modifier 통과, Frame·ScreenGui Modifier 거부(전체형이 놓치던 둘), 없는 세터·숫자 거부, 비GUI 요소(UIListLayout)에 놓기 거부.

## Studio 확인 (2차 실측 파일) [2026-10-20, 메인]

- **`studio-analysis`가 목록 일부만 읽는다.** quad-test에 프로브 전체를 싱크하자 Script Analysis 요약은 경고 1334건인데 읽힌 행은 224~232줄이었다. 늘 17번 파일 근처에서 끊겼고, 12분을 기다려도 같았다. 도구의 `notes`에는 아무것도 없었다(조용히 끊김).
- **우회: 2차 파일만 남김.** `probe-r2.project.json`으로 18~29번과 라이브러리만 싱크하고, Studio에서 00~17번을 지웠다. 원본은 레포에 있고 전체 싱크로 다시 들어간다. 그러자 요약은 1027건, 읽힌 행은 104줄이었고 그중 2차 파일은 18번 하나뿐이었다(27줄). 여전히 도구 쪽 한계로 보인다 — 사용자 툴링 문제로 보고.
- **18번 `[RW]` 줄은 리눅스 sync·vsc·pin과 글자까지 같다**(`out/r2/studio-analysis-r2d.json`). Studio 체커에도 읽기 전용 표시가 없다(`AbsoluteSize=rw`). 쓰기 표면에서 ReadOnly를 빼는 일은 덤프 데이터(`DenyWrite`)가 맡는다는 2차 M2 결론이 Studio에서도 선다.
- **19~29번의 Studio 진단은 아직 못 읽었다**(미완). 파일 하나씩 남겨 읽거나 도구가 고쳐진 뒤에 읽는다.

## Declaration 3.4.0 킷 규모 시험 보고 (2026-10-20) [opus 서브에이전트, 본문 그대로 저장]

결정이 아니라 판단 재료입니다. 킷 원본, quad 소스, 기존 프로브 파일은 고치지 않았습니다. git stash·checkout·commit도 하지 않았습니다. 무거운 실행은 모두 `choom 1000`과 `prlimit 3 GiB`를 걸고 순차로 돌렸고, 코어 덤프는 막았습니다.

**한 줄 결론:** 두 킷 전체(330파일)를 기계로 바꾼 결과, 마커 결정 때문에 생긴 새 오류는 0건입니다. too complex도 세 모드 모두 0입니다. sync에서 지금 킷은 타입 검사가 사실상 꺼져 있는데(파일마다 심은 오류를 0/194 잡음), 변환본은 194/194를 잡습니다.

### 1. 무엇을 만들었나
- **Lib4** (`src/Lib4.luau`, Lib3 복사본)
  - `ModifierInto<C>`는 타입 함수 모드 `intomarker`가 만듭니다. `chainOf`로 클래스 사슬을 걷고 `Policy.Classes`(ModClassMap)에 있는 이름만 남겨 `{ read __quadModifier: "C" | 조상들 }`을 돌려줍니다. 메소드는 없습니다.
  - Modifier 값의 As 트리는 2차와 같은 full 정책 그대로입니다.
- **Lib3 대비 꼭 필요했던 보강 셋(실측).** 모두 Lib3에 없던 빈칸이라 (다)로 분류합니다. 각 보강을 하나씩 되돌려 sync에서 잰 킷 오류 줄 수입니다.
  - 진짜 `NewChild`(quad-roblox `types.luau`. Slot·Tag·Attr·Observer·Effect 마커 포함): 없으면 +113줄
  - 배열부의 Ref 마커 팔 `{ read __quadRefAccepts: (C) -> () }`와 그 State 팔: 없으면 +43줄
  - 쓰기 자리 State 팔을 `StateMarker<T | Tween<T>>`로: 없으면 +10줄
- **확장 모듈** (`harness/compare/kit-trial/Ext4.luau`)
  - 값 `Elem`·`Spread`(:Add 포함)·`Modifier`·`Mapper`·`OnChange`·`OnEvent`·`Out`. 모두 클래스를 먼저 받는 커리입니다.
  - 지금 RobloxExtension에서 Declaration 밖 멤버(`Animate`·`Tween`·`isTween`).
  - 타입 `Modifier<C>`·`ModifierInto<C>`·`Spread<C>`·`Props<C>`·`PropsArrayItem<C>`·`ElemCtor<C>`·`OnChangeDescriptor<K>`·`OnEventDescriptor<K>`.
  - quad_types는 킷이 쓰는 사본(`quad-roblox/luau_packages/quad_types`)에서 가져옵니다.
- **실측: base `Modifier`는 바깥에서 뺄 수 없습니다.** 테이블에서 키를 빼는 타입 함수 `OmitKeys<QT.Quad,"Modifier">`를 시도했지만, Quad 멤버 하나가 `CheckReservedKeys<keyof<T>>` 꼴이라 "Type functions do not currently support…" 에러가 나고 q 전체가 무너집니다. 그래서 1차와 같은 교집합 `QT.Quad & Ext`로 갔습니다. 실제 3.4.0에서는 quad-types를 직접 고쳐야 합니다.
- **변환 범위:** 킷의 `test/run.sh` strict 패스와 같습니다. src·gallery·test·stories를 넣고, test/support와 gallery/*.client.luau는 뺐습니다. 330파일에 설정 모듈 5개입니다.
- **설정 모듈(`Quad.luau`)**
  - `local q: Ext.Q = …UseProvider(...) :: any`로 바꿨습니다.
  - 클래스별 재수출 `<C>Modifier`·`Into<C>`·`OnChangeFn`·`Field`·`FieldOut`을 지우고 위 제네릭 여덟 개로 바꿨습니다.
  - quad-roblox는 `(require :: any)`로 불러 생성 D 모듈이 검사에 들어오지 않게 했습니다(3.4.0 근사).
  - 진짜 require로 한 번 더 돌린 변형(`new-req`)도 킷 진단은 같았습니다. 의존성 쪽 too complex 5건만 늘었고, 이는 생성 D 모듈 자체에서 나옵니다.

### 2. 기준선 대 변환본 (실측, 킷 파일의 고유 진단 줄 기준)

| | pin 기준선 | pin 변환본 | sync 기준선 | sync 변환본 | vsc 기준선 | vsc 변환본 |
|---|---|---|---|---|---|---|
| 킷 진단 줄 (material+devui) | 0 | 4 | 50 | 8 | 5 | 8 |
| 그중 too complex | 0 | 0 | 14 | 0 | 0 | 0 |
| 파일마다 심은 오류 194개 중 잡힌 수 | 194 | 194 | **0** | **194** | 194 | 194 |
| 카나리 NEG (mat 5 / dev 4) | 5 / 3 | 5 / 4 | 3 / 2 | 5 / 4 | 5 / 3 | 5 / 4 |
| 전체 검사 시간·max RSS, material | 15.8 s / 209 MiB | 10.1 s / 164 MiB | 5.1 s / 150 MiB | 7.0 s / 151 MiB | 8.9 s / 182 MiB | 6.8 s / 151 MiB |
| 전체 검사 시간·max RSS, devui | 8.0 s / 200 MiB | 4.0 s / 123 MiB | 2.9 s / 119 MiB | 2.6 s / 115 MiB | 5.0 s / 163 MiB | 3.0 s / 116 MiB |
| 파일당 차가운 검사 중앙값/p90/최대 (src 173파일) | 1.72/2.67/10.99 s | 1.18/1.54/5.04 s | 1.08/1.28/2.82 s | 0.74/1.00/3.65 s | 1.25/1.63/5.56 s | 0.74/0.98/3.51 s |
| 파일당 RSS 중앙값/최대 | 112/212 MiB | 98/145 MiB | 107/129 MiB | 86/133 MiB | 108/183 MiB | 86/132 MiB |

- sync 기준선이 빨라 보이는 것은 생성 D가 too complex로 일찍 포기하기 때문입니다. 차가운 파일 검사 173회 중 154회에 too complex가 붙었습니다.
- 파일당 차가운 검사는 파일 하나와 그 파일이 require하는 것 전부를 한 프로세스로 잰 값입니다. 파일당 순수 증분이 아닙니다. 타임트레이스는 이 빌드에서 동작하지 않았습니다.

**거짓 클린 배제:**
- 카나리(킷 모듈을 require해서 쓰는 한 줄짜리 NEG/OK)를 넣어 돌렸습니다.
- 생성자를 쓰는 파일 194개마다 같은 스코프에 `{ Name = 5 }`를 하나씩 심어 전부 걸리는지 봤습니다. 위 표의 행입니다.

### 3. 새 오류 원인별 (변환본에서 기준선에 없던 것)
- **(가) 마커 결정 때문: 0건.** 마커 prop에 세터를 부르는 꼴의 오류("missing key")도 0건입니다.
- **(나) 변환 스크립트 결함 또는 기계로 못 바꾼 자리**
  - 진단이 남은 것: `src/BottomSheet/Sheet.luau` 237·242·245행(3줄). 놓을 요소를 못 찾아 바꾸지 않은 OnChange입니다.
  - 진단 없이 숨은 것: `test/spec.textfield.luau` 391·393행의 `local D = (require("../src/Quad") :: any).Declaration`. any라서 타입 검사는 깨끗하지만 3.4.0 런타임에서는 깨집니다.
  - 시제품 첫 판의 결함 넷(stories/Quad.luau를 설정 모듈로 못 알아봄, `local q = H.attach(Q)` 별칭, 줄을 넘긴 `D.Modifier\n.TextButton()`, 가림 처리 때문에 require 문자열을 못 봄)은 고쳤고, 위 표는 고친 판의 결과입니다.
- **(다) 새 표면 자체의 빈칸**
  - 남은 것: pin에서만 `src/Elevation.luau:90`의 `ShowBehindParent`(UIShadow)가 거부됩니다. 레포 핀 defs에 그 프로퍼티가 없기 때문입니다. 생성 D는 덤프에서 가져와 갖고 있었습니다. 2026-10-19에 "체커마다 다른 요소는 문서화해 인정"하기로 한 범주가 킷에서 실제로 처음 걸린 사례입니다.
  - Lib3 시절 빈칸 셋(+113 / +43 / +10줄)은 Lib4에서 메웠습니다(1절).
  - 숏핸드·Spread·Mapper 꼴은 킷에서 0회라 빈칸이 드러나지 않았습니다. 숏핸드 props(`UICorner =`·`UIScale =`)는 쓰이고 통과합니다.
- **(라) 원래 있던 것(기준선 vsc에도 있음):** `src/Dialog.luau:450`(기준선 443행) `Cannot call ((GuiObject) -> ()) & ~nil`, `test/spec.progress.luau` 4줄. 1.70.1 바이너리에서만 나고 pin에는 없습니다.

### 4. 마커로 바꿔서 해결된 것 (실측)
- **옛 b2 놓침(형제 클래스 Modifier가 들어가던 것).** 변환으로 생긴 입력 prop 103개 가운데 export된 81개를 필드 단위로 검사했습니다(`index<M.Props,"Modifier">`).
  - 기준선: 형제 클래스 Modifier를 pin·vsc에서 79/81, sync에서 81/81 통과시켰습니다. 거부한 둘은 `IntoGuiObject` 자리입니다.
  - 변환본: 세 모드 모두 81/81 거부, 같은 클래스 81/81 통과.
  - 조상 클래스 Modifier(Frame 자리에 GuiObject 등)는 양쪽 모두 통과합니다. 마커에서는 설계상 통과입니다.
  - devui 카나리: TextLabel Modifier를 ProgressBar의 `FrameModifier?` 자리에 넣는 줄을 기준선은 세 모드 모두 놓쳤고 변환본은 잡았습니다.
- **sync(override 없는 사용자 설정)에서 검사가 살아납니다.** 심은 오류를 기준선은 0/194 잡고 변환본은 194/194 잡습니다. 킷 too complex는 14줄에서 0줄이 됩니다. 테이블 연산 ambiguous 30줄처럼 error 타입에서 번진 연쇄 오류도 사라집니다.
- **As 체인 4곳이 그냥 놓기로 바뀌었습니다.** `props.Modifier:AsGuiObject():AsTextButton()` 꼴을 `props.Modifier`로 바꿨습니다(Card 214·237, List 267·299). M3 후속에서 sync가 무너지던 자리가 사라진 셈입니다.

### 5. 입력 Modifier에 메소드가 필요한 자리: 0곳
- 변환 스크립트의 같은 파일 필드명 검출에서 0곳이고, 타입 검사에서도 마커에 세터·Peek·Apply를 부르는 오류가 0건입니다.
- 입력 자리 103곳은 모두 테이블 타입 필드였고 함수 파라미터는 0곳입니다. 필드 이름은 `Modifier` 96, `FieldModifier` 3, `modifier` 3, `TrackModifier` 1입니다.
- 전체형으로 남은 12곳은 입력이 아닙니다. 반환 타입, 지역 변수 주석, 모듈 수준 이름 캐시 맵(`{ [string]: q.Modifier<Frame> }`)입니다.
  - material: Tooltip 143, Util 142·143, Button/init 161, Button/Group 252, gallery/Selection 274
  - devui: Tree 31·32, Inputs/Choice 17·18, Inputs/NumberField 30·31

### 6. 기계 변환 성공률
- 코드 안의 `D.<C>`·`D.Modifier.<C>`·`q.Declaration.*`: 1384곳 중 1382곳(spec.textfield의 any 캐스트 2곳 제외)
- 파일 머리 꺼내 두기: 생성자 지역 506개, Modifier 지역 120개. 이름 충돌 0
- 타입 재작성 115/115: 입력 → `ModifierInto<C>` 103(`<C>Modifier` 101 + `Into<C>` 2), 그 밖 → `Modifier<C>` 12
- As 체인 지우기 4/4
- 동적 꼴 `(D.Modifier :: any)[cls]`를 `(q.Modifier :: any)(cls)`로 2/2
- 살려 두기용 `local _ = D` 1곳 삭제
- OnChange/Out 코드 13곳 중 12곳 변환: 감싼 요소에서 클래스를 정한 것 8, 변수를 따라가서 정한 것 4(NavigationBar 129, NavigationRail 222, devui InputText 68·75 — 이 둘은 `writeBack: any`라 원래 검사가 꺼진 자리). 1곳은 못 정함.
- 주석·문서 문자열은 손대지 않았습니다. `D.` 48곳, 옛 타입 이름 36곳, `q.OnChange(` 8곳은 별도 문서 패스가 필요합니다.

### 7. 기계로 못 바꾼 자리
- `quad-roblox-material/src/BottomSheet/Sheet.luau:235`: `local hostHook = q.OnChange("AbsoluteSize", …)`을 `HostHook`으로 내보내고 놓는 곳은 다른 모듈입니다. 요소 클래스를 기계로 정할 수 없습니다. 추상 클래스 `OnChange "GuiObject" "AbsoluteSize"`로 두는 방법은 재지 않았습니다.
- `quad-roblox-material/test/spec.textfield.luau:391` (393행에서 사용): `(require(...) :: any).Declaration`으로 묶은 D. 스크립트가 감지하지 못하고 any라서 타입 검사도 침묵합니다.

### 8. 3.4.0 실제 변환 스크립트(`scripts/`)로 옮길 때 고칠 점
1. 설정 모듈은 파일 이름이 아니라 `UseProvider`가 있는지로 찾을 것. stories/Quad.luau가 있었습니다.
2. Quad 별칭 추적: `local q = Quad`, `local q = H.attach(Q)`, `local q = H.attach(require(...))`.
3. `(... :: any).Declaration` 같은 캐스트 경유 묶음과 D를 값으로 쓰는 자리를 반드시 목록으로 낼 것. 타입 검사가 못 잡는 런타임 잔재입니다.
4. 공백·줄바꿈 허용(`D.Modifier\n.TextButton()`), 동적 인덱스 규칙, 살려 두기용 줄 처리.
5. 분석은 주석·문자열을 가린 사본에서 하되, require 문자열은 원문에서 읽을 것.
6. OnChange/Out 클래스는 "감싼 요소, 아니면 변수의 첫 사용"으로 정하고, 모듈 밖으로 나가는 훅은 사람이 정하도록 목록으로 낼 것.
7. 입력/전체형 판정 규칙: 테이블 타입 필드와 파라미터는 마커, `local`·반환·`]:`·캐스트는 전체형. 메소드 호출 검출은 같은 파일만 보므로 다른 파일 쪽은 타입 검사가 받쳐 줍니다.
8. 보고서 줄 번호는 원본 기준으로 낼 것. 머리 삽입으로 줄이 밀리고, 이번에 프로브 생성기가 실제로 한 번 틀렸습니다.
9. 주석·문서는 별도 패스(92곳).
10. Lib4 보강 셋(진짜 `NewChild`, Ref 팔, `StateMarker<T|Tween<T>>`)은 실제 타입 함수 구현에 필수입니다.
11. base `Modifier`를 Quad에서 빼는 일은 quad-types를 직접 고쳐야 합니다(1절).

### 9. 종합 (재료)
- 마커 결정은 킷 규모에서 비용 없이 섰습니다: 새 오류 0, 메소드가 필요한 입력 0곳.
- override 없는 설정(Studio 기본 한도)에서 타입 검사가 되살아나고, 옛 b2 놓침이 81/81 닫힙니다.
- 검사 시간·메모리는 세 모드 모두 같거나 줄었습니다. sync 전체 검사만 숫자상 늘었는데, 기준선이 무너져 일찍 끝나서입니다.
- 남은 비용:
  - 모듈 밖으로 나가는 OnChange 훅 1곳은 사람이 정해야 합니다.
  - any 캐스트로 묶은 D처럼 타입이 못 보는 잔재를 스크립트가 반드시 보고해야 합니다.
  - 핀 defs와 확장 defs 차이(ShowBehindParent)가 새 표면에서는 진단으로 드러납니다.
- **미측정:** Studio, LSP의 hover·자동완성(킷 파일 안), 추상 클래스로 OnChange를 거는 꼴, export되지 않은 입력 타입 22곳의 필드 검사, 심은 오류를 Modifier 쪽 위반으로 넣는 것.

### 10. 새 파일 (`.claude/audit/decl-typefn-probe-2026-10-16/` 아래)
- `src/Lib4.luau`, `harness/codemod-proto.py`
- `harness/compare/kit-trial/`:
  - 확장 모듈 `Ext4.luau`
  - 도구 `run.py`, `summarize.py`, `inject-neg.py`, `neg-tally.py`, `props-probe.py`, `perfile.py`, `pf-stats.py`
  - 카나리 `canary-{mat,dev}-{base,new}.luau` (레포 위치에서는 require가 안 풀리는 참고 사본)
- `harness/compare/kit-trial/out/`:
  - `summary.txt` — 위 표들의 원천
  - `codemod-report.json`
  - `codemod.diff` — 변환 전후 전체, 13k줄
  - `raw/` — 모드·변형별 원 출력. 중복 줄을 지우고 400자에서 잘랐습니다. 파일당 시간 TSV, 오류를 심은 자리 목록 포함
  - `probe/props-probe-{mat,dev}-{base,new}.luau`
- 참고: 마지막에 본 `git status`에서 `kit-trial/Ext4.luau`와 `props-probe.py`가 `M`(이미 추적 중)으로 나옵니다. 작업 도중 메인 세션이 커밋한 것으로 보입니다. 그 뒤 제가 바꾼 것은 Ext4 머리 주석 한 줄과 props-probe의 줄 번호 수정입니다.
- 스크래치(레포 밖): `/tmp/claude-0/-code-Projects-quad/375233bc-c5ce-4803-af8f-62ebd7b9d5c7/scratchpad/kit-trial/`
  - `base`: 기준선 사본
  - `new`: 변환본
  - `new-req`: quad-roblox를 진짜 require한 변형
  - `base-neg`·`new-neg`: 오류를 심은 사본
  - `base-pp`·`new-pp`: 필드 프로브
  - `gap-{child,ref,tween}`: Lib3 빈칸 되돌림
  - `out/`: 원 출력 원본

메인 확인: 심은 오류 집계(`harness/compare/kit-trial/out/summary.txt` 149~154행 — 기준선 sync 0/194, 변환본 세 모드 194/194)와 기준선 sync의 Card·List As 체인 too complex(같은 파일 21~26행)를 원 출력에서 대조했다.

## 탈출구 모양·읽기 쪽 맵 — `harness/compare/escape/`, 스크래치 `index<>` 확인 [2026-10-20, 메인]

이름 정리(읽기 쪽 맵·탈출구) 재료. 정책 데이터는 `src/FullMapsKeep.luau`(M4 산물)를 그대로 썼다. 모드 sync·vsc.
- **클래스 타입을 직접 주는 탈출구**(`typed.luau` — `ElemOf<<Part>>("Part")`, `ModifierOf<<BasePart>>`, `SpreadOf<<BasePart>>`): M4에서 이름 바운드 때문에 too complex였던 큰 클래스(Beam·MeshPart·VehicleSeat·Tool·Trail·HumanoidRigDescription)가 sync·vsc 모두 깨끗, NEG 7/7(값·ReadOnly·Spread 값), OK 줄 무진단. 약점: 이름과 타입을 대조하지 못한다 — `ElemOf<<Part>>("Frame")` 통과(예상대로 MISS).
- **사용자 클래스 맵을 받는 탈출구**(`usermap.luau` — `local W = With<<{ Part: Part, Beam: Beam, … }>>()` 뒤 `W.Elem "Part"`·`W.Modifier`·`W.Spread`): sync·vsc 모두 NEG 전부(오타 `W.Elem "Prt"`는 사용자 맵 이름 유니언으로 거부), too complex 0, 0.52 s. 맵을 모듈에서 꺼내 내보내고 다른 파일에서 쓰는 꼴(`worldmod.luau`→`worlduse.luau`)도 같은 진단 10건, too complex 0. 약점: 맵의 키와 타입이 어긋나는 것(`{ Part: Frame }`)과 추상 클래스 생성은 사용자 몫.
- **읽기 쪽**: 체커의 클래스 타입에 `index<Frame, "AbsoluteSize">`·`index<Part, "Position">`이 ReadOnly를 포함해 그대로 읽히고 틀린 값은 거부(스크래치 확인). 따로 내보낸 읽기 맵과의 차이는 Q127 규칙(Instance 계열 `T?`)뿐.
