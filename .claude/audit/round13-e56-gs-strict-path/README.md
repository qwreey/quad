# round13 E56 — 시작하기(GS) 코드를 문서가 약속한 strict 경로로 올리기 (2026-09-27)

HEAD `16dd5c32`. E27(`../round13-e27-gs-chain/`)의 strict 사본(누적 Main 01~10, 별도 블록 11·13·14·19~21, 컴포넌트 모듈 12~18)을
복사해 시작점으로 삼고, 문서가 안내하는 주석만 달아 `--!strict` 신 솔버(`scripts/test.sh` 79행 플래그 셋 그대로, `strict.sh`)가
클린해지는지 봤다. 레포 파일은 건드리지 않았다. 재실행: `./run.sh`.

**"문서 안"의 범위.** GS 01 §1이 "화면 코드를 strict로 올릴 때 붙이는 주석은 how-to 01 §6에 모아 두었다"고 하므로 §6과,
§6이 직접 가리키는 곳(how-to 08 §7 표, 레퍼런스 core/03 캐비엇), 그리고 how-to 01 §4(props 타입 예제)·GS 안의 strict 접이
(07:150 `:Wait():Unwrap()`, 11 "strict에서도", 13 "strict에서는 뭘 적나요", 15 Provider 타입)를 문서 안으로 쳤다.
그 밖(`:: any`, 캐스트, `<<Item, UD>>`, 지역 변수로 빼기 등)은 **문서 밖 우회(OUT)**. 참고로 how-to 01 §6의 실제 제목은
"재사용 로직 추출"이고 strict 안내는 그 절 끝 두 문장("손이 더 가는 자리는 둘")뿐이다.

## 하네스

- `bare/`: E27 strict 사본 그대로(주석 없음). `annotated/`: 문서 안 주석만. `minimal/`: 모듈에서 클린에 **필요한** 최소 주석만
  (§6 권장 중 없어도 되는 것을 걷어냄). `workaround/`: annotated + 문서 밖 우회. `howto01/`: how-to 01 펜스를 이어 붙인 것(4b).
- 설정 모듈 `Quad.luau`는 GS 01 §1 그대로, 경로만 **한 벌**(`quad-roblox/luau_packages/quad_base`·`quad_types` + `quad-roblox/src`).
  **E27의 `s10-config`/`strict-mod/Quad.luau`는 한 벌이 아니었다** — `quad-base/src`와 `quad-types/src`를 직접 require해
  `quad_types`가 세 파일에서 온다(typing-limits 8.34가 "S10·E27 하네스는 한 벌"이라 적은 것과 다름). 다만 bare 진단은 한 벌로
  바꿔도 E27의 47줄과 전부 같은 자리였고(그 뒤 bare Counter18을 HEAD 18장 지시로 갱신해 46줄 — `out/bare-strict.txt`), 이 폴더의 문서 안 경로(반환 팩만)도 섞은 판(`probes/mixed/`)에서 똑같이 클린이다.
- 음성 대조: `probes/negctl.luau`(대입 불일치 → 진단), `probes/derived-hole-b.luau`(주석판에서 `Text`에 number → 진단).
- mock: `harness.luau`·`engine-globals.luau`·`check.luau`는 E27 사본(한 벌).

## 결과 요약

| 판 | TypeError 줄 |
|---|---|
| bare(주석 없음, E27 사본; Counter18만 HEAD 지시로 갱신) | 46 |
| annotated(문서 안) | 16 (10자리, 그중 1은 02 nil 구멍 시연 — 의도) |
| minimal(모듈만) | 0 |
| workaround(+문서 밖) | 1 (02 의도) |
| how-to 01 펜스 | 1 (§1 블록 2 인라인 무주석 Compute) |

## 장별 표

"필요한 주석(문서 안)"은 클린에 실제로 필요했던 수(모듈은 `minimal/`로 확인). §6 권장(파생 결과 타입·비인라인 콜백 파라미터)은
진단을 없애는 데는 한 번도 필요하지 않았지만 무검사 구멍(Q105)을 막는다 — `annotated/`에는 달아 두었고 수에는 넣지 않았다.

| 장 | 파일 | 필요한 주석(문서 안) | 문서 밖 우회 수·종류 | 남은 진단(문서 안만) | 관련 |
|---|---|---|---|---|---|
| 01 | Quad.luau | 0 | 0 | 0 | — |
| 02 | Main(strict-a) | 0 | 0 | 1 — 02#5 `maybe` nil 구멍(문서가 에러를 보여 주려는 블록, 의도) | — |
| 03·04 | Main | 0 | 0 | 0 | — |
| 05 | Main | 0 (인라인 Tag Compute 주석은 문서에 이미) | 1 — `active:Set(q.None :: any)` | 1 `Expected 'boolean', got 'None'` | Q118 |
| 06 | Main | 0 (HEAD 문서 48행에 이미 — E27 사본은 H-741 이전) | 0 | 0 | 8.13·H-741 |
| 07 | Main | 2 — `buttonRef:Unwrap()`(07#1 확인 줄), `:Wait():Unwrap()`(07:150) | 0 | 0 | — |
| 08 | Main | 0 | 1 — `return nil :: any`(두 갈래 Effect) | 1 `Expected '(...any) -> ()', got 'nil'` | 새(b1) |
| 09 | Main | 0 (`<<Frame>>`은 문서에 이미) | 1 — `const kids: { Instance } = …` | 1자리(2줄) `#` on unknown | 8.20·H-743 |
| 10 | Main·Styles | 0 | 0 | 0 | — |
| 11 | 별도 | 1 — 중첩 `outer`에 `q.Slot<<Instance>>` | 1 — `(host:GetChildren()[2] :: TextLabel)`(엔진 타입) | 1 | GS 11 strict 접이 |
| 12 | Counter12·Checkbox·Main | 2 — props 타입 둘 | 0 | 0 | how-to 01 §4 |
| 13 | Counter13·별도 | 6 — Counter13 props, `highlightColor` 시그니처, `Sum`·`logWith` 시그니처, `Doubled` 안쪽 `c`, `twice: q.State<number>` | 1 — `__apply = function(self, state: any): any` | 1자리(2줄) `None of the overloads` | 새(b2) |
| 14 | CounterBoard·별도 14#6·14#8 | 8 — CounterBoard(props·`Slot<<Instance>>`·반환 팩·keyFn `item`), 14#6(`Slot<<Instance>>`·반환 팩·keyFn `item`), 14#8(반환 팩) | 7 — 14#6: `ctx.UserData` 캐스트 1·`ctx.Item` 캐스트 2 / 14#8: `:Single<<string, nil>>`·`ctx.Item :: string`·`ctx.Offset`을 타입 지역으로·`single:Get(1) :: TextLabel` | 4자리 | Q121·E45·8.33(props 타입이면 사라짐)·b3·b4 |
| 15 | Theme·ThemeTyped | 1 — `:: q.Provider<Theme>` | 0 | 0 | — |
| 16 | Settings·Counter16 | 2 — Settings Provider 캐스트(15의 모양을 옮김, `Store`가 재수출 안 돼 구조 타입 `{ Step: q.Source<number> }`), Counter16 props(`Ctx: q.Context`) | 0 | 0 | 4(d) |
| 17 | Counter17b | 0 (bare부터 클린) | 0 | 0 | — |
| 18 | Counter18 | 0 (E27의 진단 1은 H-739 문서 결함 — HEAD 지시대로 고친 판은 bare부터 클린) | 0 | 0 | H-739 |
| 19·20·21 | 별도 | 0 (20의 `which :: any`는 문서에 이미) | 0 | 0 | 8.32 |
| — | Main12to16(12~17 호출 쪽) | 0 — 모듈 props만 타이핑하면 호출 쪽은 무주석(`Watch` 람다·`Children = q.Slot {…}`)으로 통과 | 0 | 0 | 8.26(`Children` 무검사) |

합계: 코드가 있는 장 21(01~21) 중 **문서 안 주석만으로 클린 15**(05·08·09·11·13·14 제외), 필요한 문서 안 주석 22,
문서 밖 우회 12(엔진 캐스트 2 포함), 문서 안만의 남은 진단 16줄/10자리(의도 1 포함). 우회까지 쓰면 의도된 02 하나만 남는다.

오늘 잡힌 strict 함정이 GS에서 실제로 나온 횟수: Q121 `:Single` `<<Item, UD>>` 1(14 §5) · E45 반환 팩 3자리 + `ctx.Item` 캐스트 3 ·
8.13 인라인 무주석 Compute 0(HEAD GS는 전부 주석됨; how-to 01 §1에 1) · Q118 `Set(q.None)` 1 · Q126 setter `nil` 0 ·
8.20 `OnCreated/OnRendered<<Frame>>` 구조 추론 1(09) · 8.33 `table.clone(props.Rows:Get())` 0(props 타입을 달면 사라짐) · 8.34 0.

## how-to 01 §6(과 GS 01의 "모아 두었다")이 빠뜨린 안내 — 실제로 필요했던 순

1. **props 테이블 타입**(`props: { read Label: string, read Start: number?, … }`) — GS 컴포넌트 파일 bare 진단의 대부분이 여기서
   왔다(`props.Start or 0`이 `number | ~(false?)`, `props.Rows:Get()`이 unknown → 8.33 포함). how-to 01 §4 예제에만 있고 §6 "둘"엔 없다.
2. `:List`의 **keyFn 파라미터 타입**(`function(item: Row)`) — 없으면 `Item`이 안 정해져 KeyGone 불일치(`probes/cb-noitem`). 어디에도 없다.
3. `q.Slot<<Instance>>()` / 반환 팩 — 08 §7·GS 11 접이에 있지만 §6에는 없다.
4. **Context 열쇠 타입** — 15가 Theme에만 보여 주고 16 Settings는 무타입이라 `ctx:Get(Settings.Provider)`가 unknown. Store 값의 열쇠는
   `Store<T>`가 재수출되지 않아 구조 타입으로 적어야 한다.
5. **두 갈래 Effect의 `return nil`**, **`__apply` 객체**, **`Set(q.None)`**, **훅 안 `inst:GetChildren()`** — 문서 안 처방이 없다(아래 b1·b2, Q118, 8.20).
6. **`:Single` 매핑** — how-to 쪽 경로(§6·08 §7)엔 `<<Item, UD>>`가 없다(SKILL에만). GS 14 §5 모양은 그것으로도 모자라다(b3).
7. §6의 "둘"(파생 결과 타입·콜백 파라미터)은 **진단을 없애는 데가 아니라 무검사를 막는 데** 필요하다는 설명 — 없으면 독자가 "안 달아도 클린인데?"로 끝난다(`probes/derived-hole-a` 무진단 vs `-b` 진단).

## 별도 축

- **(a) 주석이 동작을 바꾸지 않았는가** — `mock-modules.luau`로 bare/annotated 모듈을 같은 조작(클릭·Watch·보드 추가·보폭·Blocker)으로
  돌린 로그 19줄이 한 글자도 같다(`out/mock-bare.txt` = `out/mock-annotated.txt`; bare Counter18만 HEAD 18장 지시로 `+ 1` 갱신).
  Main/별도 판에서 타입이 아닌 편집 셋(`:Unwrap()` 둘, `ctx.Offset` 지역화)은 `mock-runtime-edits.luau`로 원문과 같은 관측
  (07#1 TextButton·Wait 대기 후 진행·LayoutOrder 4→5→4). 나머지 편집은 타입 주석·`::`·`<<>>`라 런타임에 지워진다. E27 체인 러너 넷도
  HEAD에서 다시 돌려 181 검사 0 FAIL.
- **(b) how-to 01 예제 자체** — §3·§4·§5·§6 블록은 strict 클린(`howto01/`). §1 블록 2(`01-component-conventions.md:43`)의 인라인
  무주석 `isHovered:Compute(function(h)`만 진단 — 문서가 옆 주석으로 "지역 변수로 빼세요"라 적어 두었고, how-to 01 프롤로그엔 `--!strict`가 없다.
- **(c) SKILL vs how-to** — 본문 아래 발견 a3·c1.
- **(d) GS 01 재수출 아홉** — 문서 안 경로에서 쓴 이름은 `State`·`Source`·`Slot`·`StateData`·`Provider`·`Context`·`Effect` 일곱,
  `Ref`·`Observer`는 안 씀. 빠진 이름은 더 엄격한 길을 갈 때만 나온다 — 타입드 `ctx`(`KeyGone`·`SlotItem`), Settings를 Store로 적기
  (`Store`), how-to 01 §3식 props(`StateMarker`), Modifier 반환 타입(`RobloxModule.<Class>Modifier` — 재수출 대상이 아님, how-to 01
  프롤로그가 따로 require).

## 탐침(`probes/`)

`cb-*`(:List 경로 대조 — `cb-typo`·`cb-neg4`·`cb-neg6` 무진단이 b4), `effect-nil-min`(b1), `apply-obj`·`apply-obj2`(b2),
`single-var*`(b3), `styles-typed`(accent 타이핑은 재수출 이름으로 가능), `eff-*`(08 대안들), `derived-hole-*`, `negctl`, `mixed/`.
