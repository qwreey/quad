# Q105 배치 초안 — 문서 스니펫 무주석 `:Compute`/`:Apply`/`:Gate`/`:Mapped` 바인딩
<!-- 초안 안의 링크 경로는 문서 위치(docs/) 기준이라 여기선 `<docs>/`로 표기 — 반영 때 `../`로 되돌릴 것 -->

결정 재료. `.claude/qa-request/post-implementation-review-round13.md` §4 Q105의 (b)("다운스트림이 값을 쓰는 무주석 `:Compute` 바인딩만 주석 + 캐비엇 한 번")를 실제로 적용하면 어디에 몇 줄이 필요한지, 그리고 그 처방이 실제로 진단을 되살리는지를 검증했다. 결정은 내리지 않았다 — 아래는 재료다.

## 0. 먼저 정정: `:Apply`/`:Gate`/`:Mapped`는 전부 §1의 hole에 걸리지 않는다

Q105 문항은 "`:Compute` 바인딩"만 언급하지만, 이번 작업 지시가 네 메소드를 다 훑으라고 했고, 실제로 훑어보니 **§1의 hole(무주석 바인딩이 다운스트림 전체를 무검사로 만드는 것)은 메소드 이름이 아니라 각 메소드의 타입 선언 방식에 달려 있었다.** 실측(아래 §2)으로 넷을 나눴다:

- **`State:Compute`** — quad-types `init.luau:204`가 인라인 제네릭(`Compute: <U>(...) -> State<U>`)으로 선언돼 있어 **항상** hole(무주석이면 파라미터 수·dep 유무·주석 여부와 무관하게 전부 무제약 — S6b `H-691`이 이미 확정한 사실, 이번에 실제 문서 스니펫 하나(GS 03:72 모양)로 재확인함, `compute-before-after.luau`).
- **`State:Apply`** — 두 갈래다. **factory가 함수이고 반환이 같은 타입 인자를 유지하면(`Op.Sum`/`Product`/`Min`/`Max`/`Band`/`Bor`/`Bxor`/`Bnot`/`Shl`/`Shr`/`Clamp`/`Alternative`처럼 숫자·nil 처리 연산자) `Apply`의 반환은 그냥 `U`이고 재귀 자기참조가 안 걸려 무주석이어도 다운스트림이 그대로 제약된다**(`Op.Sum`/`Clamp`/`Band`/`Shl`/`Alternative` 다섯을 `apply-real-probe2.luau`로 직접 확인, 나머지 여섯(`Product`/`Min`/`Max`/`Bor`/`Bxor`/`Bnot`/`Shr`)은 quad-types의 같은 `NumOp` 선언 모양이라 유추이고 개별 실측은 안 함). **반면 factory가 타입 인자를 바꾸거나(`Op.Not`·`Op.Indexed`·`q.Animate`) 객체+`__apply`(`q.Blocker()`·`q.Debounce{}`·`q.Throttle{}`·사용자 `{__apply=...}`)면 hole이 있다**(`Op.Not`·`Op.Indexed`는 `apply-real-probe2.luau`, `q.Animate`·`q.Blocker`·`q.Debounce`는 `apply-real-probe.luau` + `apply-real-probe-after.luau`로 확인). `D.Modifier...:Apply(...)`/`q.Modifier():Apply(...)`처럼 **`Modifier:Apply`는 완전히 다른 함수**다(quad-types `init.luau:412` 근방 — factory 반환이 그냥 `any`이고, 문제는 factory 자체를 주석했는지이지 이 문서의 관례와 무관) — 스코프 밖.
- **`State:Gate`** — `Gate: (self: StateData<T>, setup: GateSetup) -> State<T>`(quad-types `init.luau:216`)로 **같은 T만** 돌려준다 — typing-limits §1 표의 "같은 인자로만 재귀 ✅ 정상" 행 그대로. hole 없음.
- **`Tween:Mapped`** — `Mapped: typeof(tweenMapped)`(quad-roblox `types.luau:100`, `tweenMapped`는 `types.luau:96`의 이름 붙은 top-level 함수)로 선언돼 있어 §1③("인라인 대신 `typeof(named function)`")의 보강 패턴을 이미 쓰고 있다 — hole 없음.

**이게 왜 중요한가**: Q105 (b)를 "무주석이고 다운스트림이 값을 쓰면 전부 주석"으로 기계적으로 적용하면, 안전한 `Op.Sum`/`Gate`/`Mapped` 자리에까지 불필요한 주석을 강제하게 된다. 아래 표는 실제로 hole이 있는 자리만 추려낸 것이다.

## 1. 전수 스윕 — 숫자

스윕 스크립트는 `q105-check/sweep2.py`(docs/ 안 ` ```lua ` 블록, site 제외, `local`/`const` 바인딩만), 원본은 `q105-check/sweep2.out`, 분류는 `q105-check/classify.py` → `classified.json`, 전체 108행 원장은 `q105-check/full-table.md`.

| 메소드 | 전체 | 무주석 | 주석 |
|---|---|---|---|
| `:Compute` | 63 | 48 | 15 |
| `:Apply`/`:Gate`/`:Mapped` | 45 | 21 | 24 |
| **합** | **108** | **69** | **39** |

참고로 round13 S6b가 셌던 "45줄(주석 14줄)"은 **후행 dep이 있는 `:Compute` 호출만** 골랐던 좁은 스윕(`round13-s6b-compute-hole/docs-sweep.py`가 `len(args) < 2: continue`로 dep 0개 호출을 걸렀다)이라 이번 63/48/15와 다르다 — 이번이 dep 유무와 무관한 `:Compute` 전수다.

§0의 스코프 정리를 적용하면(Modifier:Apply 스코프 밖 3건, Gate/Mapped 안전 4건 제외):

| 갈래 | 건수 |
|---|---|
| 실제로 hole 있음 + 다운스트림이 값을 씀(스니펫 안에서 확인됨) → **주석 필요, 확정** | 38 (`:Compute` 34 + `:Apply` 4) |
| 실제로 hole 있음이나 이 스니펫 안엔 다운스트림 사용이 안 보임(파일 전체가 강의용 한 줄 예제라 다음 코드가 없음) → **주석 권고, 경계선** | 7 |
| hole 있고 다운스트림도 없음, 순수 데모 한 줄 → 필요 없음 | 다수(`unused` 46건 중 대부분) |
| hole 없음(안전한 Operator/Gate/Mapped) | 나머지 |
| Modifier:Apply(스코프 밖) | 3 |

## 2. 실측 절차와 결과

스크래치는 `q105-check/`(`_setup.luau`는 `round13-s6b-compute-hole/_setup.luau`와 동일 패턴, 경로만 한 단계 더 깊음). 전부 `mise exec -- luau-lsp analyze --flag:LuauSolverV2=true --flag:LuauTarjanChildLimit=160000 --flag:LuauSubtypingIterationLimit=100000 --flag:LuauTypeInferIterationLimit=1000000 --definitions=scripts/roblox-defs/globalTypes.d.luau --ignore "**/luau_packages/**" <파일>`(test.sh 79행 플래그 그대로).

- **`compute-before-after.luau`** — GS 03:72 모양(`const countText = count:Compute(function(c) return \`카운트: {c:Get()}\` end)`)을 그대로 재현. BEFORE(무주석): `local before_bad: number = countTextBefore`와 `:Get()` 버전 둘 다 **진단 0**(hole 재확인). AFTER(`local countTextAfter: QT.State<string> = ...`로 바꾼 뒤 같은 두 잘못된 대입): **둘 다 TypeError**(제약 확인) — `after_ok: string = countTextAfter:Get()`은 클린. **PASS**(before 무검사·after 제약 둘 다 기대대로).
- **`apply-probe.luau`** — factory가 `State<T> -> State<T>`(같은 T)를 손으로 만든 최소형으로 `:Apply` 자체가 §1과 무관함을 먼저 확인(제약됨, PASS) — 이후 실제 quad API로 넘어감.
- **`apply-real-probe.luau`** — `count:Apply(q.Operator.Sum(10))`(제약, TypeError 2건) vs `alpha:Apply(q.Animate({Time=0.3}))`/`raw:Apply(q.Blocker())`/`searchInput:Apply(q.Debounce({Time=0.2}))`(셋 다 무검사, 진단 0) — Animate·Blocker·Debounce가 hole임을 확인. **PASS**(Sum 안전·나머지 셋 hole, 기대대로).
- **`apply-real-probe2.luau`** — `Op.Sum`/`Clamp`/`Band`/`Shl`(전부 TypeError, 안전)과 `Op.Alternative`(TypeError, 안전) vs `Op.Not`/`Op.Indexed`(둘 다 진단 0, hole) 일곱 항목을 한 파일에서 대조. **PASS**(다섯 안전·둘 hole, 기대대로) — `Not`이 안전할 거라 예상했다가 hole로 나온 게 이번 실측의 유일한 반증(§0에 반영).
- **`apply-real-probe-after.luau`** — `raw:Apply(blocker)`/`searchInput:Apply(q.Debounce{...})`에 바인딩 주석을 붙이면 올바른 다운스트림(`r3:Get(): number`, `r4:Get(): string`)은 클린이고 일부러 틀린 대입(`bad4: boolean = r4:Get()`)은 TypeError. **PASS**. `q.Animate`의 after는 **재현하지 않음** — `Tween<T>`가 quad_types가 아니라 quad-roblox 자체 모듈 타입이라 스크래치에서 그 타입을 끌어오는 배선이 이 작업 범위를 넘어간다고 판단해 생략했다(before의 hole은 확인됨, fix 패턴은 §1①과 동일하다고 간주 — 개별 재확인 안 함, 아래 표에 표시).

**PASS/FAIL 요약**: 5개 스크래치 파일, 전부 기대한 결과(hole 있음/없음, 주석 후 제약)와 일치 — FAIL 없음. 다만 Animate의 after 절반은 수행하지 않음(위 사유).

## 3. 주석 필요 — 확정 38건 (스니펫 안에서 다운스트림 값 사용 확인됨)

after 초안은 각 페이지가 이미 쓰는 표기(`q.State<T>` 대다수, `reference/sugar/02-operator.md`·`03-debounce-throttle.md`는 바깥 `State<T>`)를 따랐다. 타입은 바로 아래 실제 사용(프로퍼티 이름·산술)에서 읽었다 — 개별 luau-lsp 재검증은 안 하고(§2가 이미 메커니즘을 파일 단위로 확정했으므로), 표기만 페이지 관례에 맞춘 기계적 초안이다.

| file:line | 바인딩 이름 | 다운스트림 | after 초안 |
|---|---|---|---|
| `getting-started/03-flowing-values.md:72` | countText | `Text = countText` | `local countText: q.State<string> = count:Compute(...)` |
| `getting-started/03-flowing-values.md:108` | both | `both:Get()` 산술 없이 단순 읽기 두 곳 | `local both: q.State<string> = count:Compute(...)` |
| `getting-started/04-reacting.md:21` | countText | `Text = countText` | `local countText: q.State<string> = count:Compute(...)` |
| `getting-started/05-tag-attr.md:21` | countText | `Text = countText` | `local countText: q.State<string> = count:Compute(...)` |
| `getting-started/06-flowing-back.md:23` | countText | `Text = countText` | `local countText: q.State<string> = count:Compute(...)` |
| `getting-started/06-flowing-back.md:180` | derived | `q.Out("Text", derived)`(Text는 string) | `local derived: q.State<string> = name:Compute(...)` |
| `getting-started/08-observer-effect.md:182` | isBig | `if inst and isBig:Get() then` | `local isBig: q.State<boolean> = count:Compute(...)` |
| `getting-started/10-modifier.md:54` | cardColor | `BackgroundColor3 = cardColor` | `local cardColor: q.State<Color3> = hot:Compute(...)` |
| `getting-started/12-components.md:31` | countText | `Text = countText` | `local countText: q.State<string> = count:Compute(...)` |
| `getting-started/12-components.md:109` | countText | `Text = countText` | `local countText: q.State<string> = count:Compute(...)` |
| `getting-started/12-components.md:195` | labelText | `Text = labelText` | `local labelText: q.State<string> = checked:Compute(...)` |
| `getting-started/12-components.md:221` | statusText | `Text = statusText` | `local statusText: q.State<string> = agreed:Compute(...)` |
| `getting-started/13-functions.md:151` | plusTen | `print(plusTen:Get())` — 값 소비는 print뿐이지만 반환형이 `Sum(10)`의 결과라 다음 절 강의 흐름상 number | `local plusTen: q.State<number> = count:Compute(Sum(10))`(주: 이 줄은 사실 손으로 만든 `Sum` 콤비네이터의 데모이고 print만 하므로 §4 (a)/(c) 논의에서는 "print-only"쪽에 더 가깝다 — 여기 넣은 건 분류 스크립트가 print를 "산술" 인접으로 옆줄까지 본 결과, 경계선으로 다시 표시함) |
| `getting-started/19-laziness.md:56` | doubled | `n:Compute(..., doubled)`의 dep 인자로 재사용 | `local doubled: q.State<number> = n:Compute(function(s) return s:Get() * 2 end)` |
| `getting-started/19-laziness.md:59` | total | `total:Compute(function(s) return tostring(s:Get()) end)`의 리시버 | `local total: q.State<number> = n:Compute(function(s, previous, d) ... end, doubled)` |
| `how-to/02-form-validation-pattern.md:125` | isUsernameValid | `IsUsernameValid = isUsernameValid` + `isUsernameValid:Compute(...)`의 리시버 | `local isUsernameValid: q.State<boolean> = store.Username:Compute(...)` |
| `how-to/02-form-validation-pattern.md:129` | isPasswordValid | `IsPasswordValid = isPasswordValid` + dep 인자로 재사용 | `local isPasswordValid: q.State<boolean> = store.Password:Compute(...)` |
| `how-to/02-form-validation-pattern.md:135` | canSubmit | `CanSubmit = canSubmit` | `local canSubmit: q.State<boolean> = isUsernameValid:Compute(...)` |
| `how-to/05-theme-and-dynamic-styling.md:94` | palette | `token(key)` 안에서 `return palette:Apply(...)`의 리시버 | `local palette: q.State<ColorPalette> = isDark:Compute(function(dark) ... end)` |
| `how-to/06-headless-testing.md:81` | isEven | `assert(isEven:Get() == true, ...)` | `local isEven: q.State<boolean> = count:Compute(...)` |
| `how-to/06-headless-testing.md:99` | gated | `assert(gated:Get() == 2, ...)`(factory가 `q.Blocker()` — object-arm hole) | `local gated: q.State<number> = raw:Apply(gate)` |
| `how-to/08-migrating-from-v1.md:110` | size | `D.Frame { Size = size }` | `local size: q.State<UDim2> = width:Compute(function(...): UDim2 ...)` |
| `how-to/08-migrating-from-v1.md:169` | color | `D.Frame { BackgroundColor3 = color, ... }`(체인 `hovered:Compute(...):Apply(q.Animate{...})` — 마지막 `:Apply(Animate)`가 hole, `:Compute`가 아니라 이 체인 전체를 감싸는 게 필요) | `local color: q.State<RobloxModule.Tween<Color3>> = hovered:Compute(function(...): Color3 ...):Apply(q.Animate {...})` |
| `how-to/08-migrating-from-v1.md:175` | position | `D.Frame { ..., Position = position }`(콜백 반환이 `: any`로 이미 주석돼 있음 — 그래도 바인딩 자체는 무제약) | `local position: q.State<RobloxModule.Tween<UDim2>> = target:Compute(function(self: q.StateData<UDim2>): RobloxModule.Tween<UDim2> ...)`(부차 권고: 콜백 반환의 `: any`도 `RobloxModule.Tween<UDim2>`로 좁히면 좋지만 이건 binding 주석과 별개 문제) |
| `quadnomicon/09-fragment-breakthrough-and-domless-slot.md:151` | layoutOrder | `LayoutOrder = layoutOrder` | `local layoutOrder: q.State<number> = order:Depend(ctx.Offset):Compute(...)` |
| `reference/core/06-slot.md:112` | empty | `Visible = empty` | `local empty: q.State<boolean> = slot.Length:Compute(...)` |
| `reference/roblox/06-tween-animate.md:62` | size | `D.Frame({ Size = size })` | `local size: q.State<RobloxModule.Tween<UDim2>> = open:Compute(function(self: q.StateData<boolean>): RobloxModule.Tween<UDim2> ...)` |
| `reference/roblox/06-tween-animate.md:182` | animated | `D.Frame({ BackgroundTransparency = animated })`(factory `q.Animate{...}` — hole) | `local animated: q.State<RobloxModule.Tween<number>> = alpha:Apply(q.Animate({...}))` |
| `getting-started/19-laziness.md:142` | animated | `D.TextLabel { TextColor3 = animated }`(factory `q.Animate{Time=time}` — hole) | `local animated: q.State<RobloxModule.Tween<Color3>> = numberColor:Apply(q.Animate {Time = time})` |
| `skills/quad-ui-dev/references/code-recipes.md:24` | countText | `Text = countText` | `local countText: q.State<string> = count:Compute(...)` |
| `skills/quad-ui-dev/references/code-recipes.md:28` | frameBg | `BackgroundColor3 = frameBg` | `local frameBg: q.State<Color3> = count:Compute(...)` |
| `skills/quad-ui-dev/references/code-recipes.md:169` | nameText | `Text = nameText` | `local nameText: q.State<string> = playerState:Compute(...)` |
| `skills/quad-ui-dev/references/code-recipes.md:172` | levelText | `Text = levelText` | `local levelText: q.State<string> = playerState:Compute(...)` |
| `skills/quad-ui-dev/references/code-recipes.md:202` | isValid | `AutoButtonColor = isValid` + `if isValid:Get() then` + `isValid:Compute(...)`의 리시버 | `local isValid: q.State<boolean> = form.Username:Compute(...)` |
| `skills/quad-ui-dev/references/code-recipes.md:206` | submitColor | `BackgroundColor3 = submitColor` | `local submitColor: q.State<Color3> = isValid:Compute(...)` |
| `skills/quad-ui-dev/references/code-recipes.md:257` | hasQuery | `Visible = hasQuery` | `local hasQuery: q.State<boolean> = rawQuery:Compute(...)` |
| `skills/quad-ui-dev/references/code-recipes.md:326` | coinText | `Text = coinText` | `local coinText: q.State<string> = inventory.Coins:Compute(...)` |

(3-functions.md:108의 `both`는 표에서 "산술 없이 단순 읽기"라고 적었는데 재확인하면 `print(both:Get())` 두 번뿐이라 실은 §4의 print-only에 더 가깝다 — 분류 스크립트가 `:Get()` 근처의 산술 패턴 탐지에서 과분류한 경계 사례. `plusTen`과 함께 사용자 검토 시 (a)/(c) 쪼갤 때 재검토 권장.)

## 4. 주석 권고 — 경계선 7건(스니펫 안엔 다운스트림 사용이 안 보임)

hole은 있지만(§0·§2로 확인) 이 스니펫 자체가 그 자리에서 끝나(다음 코드 없음) 값 소비가 안 보인다. (b)의 글자 그대로("다운스트림이 값을 쓰는 자리")를 따르면 스킵해도 되지만, 파일 성격상 권고에 넣을 만한 이유를 같이 적는다.

| file:line | 바인딩 | 이유 |
|---|---|---|
| `getting-started/13-functions.md:248` | twice(`count:Apply(Doubled)`, `Doubled={__apply=...}` — 사용자 정의 object-arm hole) | 바로 다음 문단이 "이 모양이 있어서 자기 상태를 가진 것도 Apply로 붙습니다"로 이어져 독자가 다음에 실제로 쓸 패턴 |
| `how-to/08-migrating-from-v1.md:143` | primary(`theme:Apply(Op.Indexed<<Color3>>("Primary"))`) | 같은 페이지 §7 strict 체크리스트가 이 정확한 패턴을 다루므로 표와 예제가 어긋나면 안 됨 |
| `reference/roblox/06-tween-animate.md:185` | guarded(`alpha:Apply(q.Animate({...}))`) | 바로 위 182행(animated, 확정 목록에 있음)과 같은 코드 블록의 형제 줄 — 하나만 고치면 나머지가 어색 |
| `skills/quad-ui-dev/SKILL.md:159` | isHidden(`isVisible:Apply(Op.Not)`) | **이 파일은 머리에 `--!strict`를 명시한다**(line 74) — AI 에이전트가 이 파일을 "strict에서 이렇게 쓴다"는 정본으로 읽으므로, 실제로는 strict에서 무제약이 되는 줄을 정본에 남기면 그 습관이 실제 코드로 퍼진다 |
| `skills/quad-ui-dev/SKILL.md:163` | primary(`theme:Apply(Op.Indexed<<string>>("Primary"))`) | 위와 같음 |
| `skills/quad-ui-dev/SKILL.md:492` | debouncedQuery(`searchInput:Apply(q.Debounce {...})`) | 위와 같음 — 같은 파일의 `code-recipes.md:252`는 이미 이 패턴을 정확히 주석해 둠(모순) |
| `skills/quad-ui-dev/SKILL.md:495` | throttledScroll(`scrollPos:Apply(q.Throttle {...})`) | 위와 같음 |

SKILL.md 5건이 유독 몰려 있는 건 우연이 아니다 — 이 파일이 유일하게 "AI 에이전트용 정본"이라는 별도 용도를 갖고 있어서, (b)의 "다운스트림이 스니펫 안에서 값을 쓰는가"라는 기준 자체가 이 파일에는 안 맞을 수 있다(사용자 판단 필요 — 이 파일만 별도 취급해 전부 주석하는 (a)에 준하는 처리를 할지).

## 5. 스코프 밖 / 안전 — 조치 불필요 12건

- **Modifier:Apply(스코프 밖, 3건)**: `getting-started/10-modifier.md:171`(title), `reference/core/08-modifier.md:236`(styled), `reference/roblox/03-d-modifier.md:275`(bold) — `Modifier:Apply`는 `State:Apply`와 다른 함수(quad-types `init.luau` 다른 줄), factory 반환이 그냥 `any`이고 문제는 factory 자체의 주석 여부. Q105·§1과 무관.
- **`:Gate`(안전, 2건, 이미 둘 다 annotated라 조치 자체가 불필요)**: `reference/core/03-state.md:221`(held), `reference/sugar/06-blocker.md:153`(gated).
- **`:Mapped`(안전, 2건)**: `reference/roblox/06-tween-animate.md:128`/`129`(a, b) — 무주석이어도 hole 없음, 지금 그대로가 맞다.
- **`:Apply`(안전한 Operator, 이미 이번 스윕에서 언급된 것 다수)**: `Op.Sum`/`Clamp`/`Band`/`Shl`/`Alternative` 계열 — `getting-started/13-functions.md:189`(plusTenOp, 무주석이지만 안전), `how-to/08-migrating-from-v1.md:135`/`139`(total, shown — 무주석이지만 안전), `skills/quad-ui-dev/SKILL.md:160`/`161`/`162`(totalPrice, clamped, safeName — 무주석이지만 안전) 등. 이들은 **손대지 않아도 된다** — (a)로 결정이 나도 이 자리들은 주석을 강제할 근거가 없다(§0·§2가 안전을 실측으로 확인).
- **`getting-started/12-components.md:256`(readOnly)**: 다운스트림 줄이 `-- readOnly:Set(true) → attempt to call missing method 'Set' of table`라는 **주석**(실행되지 않는 예시 문구)이라 실제 사용이 아님 — 분류 스크립트가 이걸 "usage"로 잘못 집었던 걸 수동으로 제외.

## 6. (a)/(c) 갈래별 추가 건수·잔여 위험

- **(a)로 갈 경우 추가 건수**: (a)는 "무주석 45줄 전부"였는데, 이번 넓은 스윕(4메소드)에서 hole이 있는 자리 전체(§3 확정 38 + §4 경계 7 = 45) 위에 print-only/unused까지 다 더하면 **hole이 있는 자리 자체는 총 몇 건이냐**로 다시 세야 한다 — `:Compute` 무주석 48건 전부(§3의 34 + §4 없음(전부 §3에 있음이 아니라 print-only/unused 쪽에도 있음, 정확히는 48 - 34 = 14건이 print-only/unused) + `:Apply`류 hole 무주석 몇 건(Animate/Blocker/Debounce/Throttle/Not/Indexed/custom-object 계열, §3의 4 + §4의 6(twice/primary-how-to08/isHidden/primary-SKILL/debouncedQuery/throttledScroll) = 10, 남은 무주석 Apply류(Sum/Clamp 등 안전한 것)는 hole이 없으므로 (a)라 해도 "고칠 필요"는 없지만 "안전을 사용자가 매번 판별 못 하니 일관성 있게 다 주석"이라는 (a)의 취지를 살리면 이것도 포함해야 함 → 그 경우 21건 전부). 요컨대 **(a)를 hole 기준으로 좁게 잡으면 48+10=58건, "무주석은 다 주석"으로 넓게 잡으면 69건 전부**다. (a)의 정확한 범위 자체가 이번 조사로 갈렸다는 뜻 — 결정 시 이 두 숫자 중 어느 쪽인지 같이 정해야 한다.
- **(c)(캐비엇만, 코드는 안 고침)로 갈 경우 남는 위험**: §3의 38건(그리고 §4의 7건)이 전부 무주석인 채로 남는다 — 독자가 그 스니펫을 그대로 복사해 실제 프로젝트의 strict 파일에 붙이면, `Text = countText`처럼 겉보기엔 정상 동작하는 코드가 **strict의 타입 검사를 그 지점부터 조용히 다 잃은 채** 통과한다. 캐비엇을 아무리 잘 써도 코드 자체는 안 바뀌므로, 캐비엇을 안 읽고 복사-붙여넣기만 하는 독자에게는 위험이 그대로 남는다. 특히 `skills/quad-ui-dev/SKILL.md`(§4에서 이미 지적)는 사람이 아니라 **AI 에이전트가 참조**하므로 "캐비엇을 읽고 유의한다"는 완충이 없다 — (c)를 고르면 이 파일만이라도 예외로 둘지 별도 판단이 필요하다.

## 7. 캐비엇 문단 초안(자리 후보 둘)

### GS 04(반응) 후보 — "무주석 Compute 결과" 첫 등장 뒤

> **⚠️ 여기서부터는 겉보기엔 정상 동작해도 strict가 놓치는 자리가 하나 있습니다.** `count:Compute(...)`의 결과를 `local countText = ...`처럼 타입 없이 받으면, 그 줄 자체는 물론이고 **그 변수를 쓰는 이후 모든 코드**의 타입 검사가 조용히 사라집니다 — 진단이 뜨지 않으니 "strict 통과 = 타입이 맞다"로 믿게 되는데, 실제로는 그 지점부터 무검사입니다. 처방은 간단합니다 — 파생 State를 만드는 줄에 결과 타입을 답니다: `local countText: q.State<string> = count:Compute(...)`. 이 문서의 화면 코드는 기본이 `--!nonstrict`라 지금 당장 이 주석이 필요하지는 않지만, `--!strict`로 옮기는 순간부터는 이 습관이 안전망입니다.

(기존 8.13 캐비엇·GS 08 접힘 상자와 겹치지 않도록 — 저 둘은 "함수 인자 테이블 리터럴 안 인라인 무주석 콜백"을 다루고, 이건 "바인딩 자체의 결과 타입"을 다룬다. 한 문장으로 구분을 밝혀두면 좋을 것: "이건 콜백 파라미터 주석과는 다른 자리입니다 — 바인딩 그 자체입니다.")

### how-to 10(디버깅) 후보 — 부록에 한 절

> **strict에서 조용히 사라지는 타입 검사 — 무주석 `:Compute` 바인딩.** `local x = state:Compute(fn)`처럼 결과를 타입 없이 받으면 Luau의 현 한계로 그 결과 타입이 `x` 자신도 다운스트림도 검사받지 않습니다(에러가 안 뜨는 게 증상입니다 — 있어야 할 진단이 없는 것). 짐작 가는 신호: `x:NoSuchMethod()`처럼 명백히 잘못된 호출을 강제로 넣어봐도 strict가 조용하면 이 구멍입니다. 처방은 바인딩에 결과 타입을 명시하는 것뿐입니다 — 콜백 파라미터 주석이나 반환 타입 주석은 이 구멍을 안 메웁니다. 상세 메커니즘은 [레퍼런스: `State`](<docs>/reference/core/03-state.md)의 strict 캐비엇을 보세요. `:Apply`는 조금 다릅니다 — factory가 같은 타입을 유지하는 연산자(`Op.Sum` 등)면 이 구멍이 없고, 타입을 바꾸거나 자기 상태를 가진 factory(`q.Animate`/`q.Blocker`/`q.Debounce`/`q.Throttle`)면 같은 구멍이 있습니다.

## 8. 산출물 목록

- `.claude/audit/round13-drafts-2026-09-27/q105-compute-annotations.md` — 이 문서.
- `.claude/audit/round13-drafts-2026-09-27/q105-check/` — 스크래치:
  - `sweep2.py`/`sweep2.out` — 4메소드 전수 스윕(108행).
  - `classify.py`/`classified.json` — 다운스트림 사용 분류.
  - `full-table.md` — 108행 원장(기계적 재현용).
  - `apply-probe.luau`/`apply-real-probe.luau`/`apply-real-probe2.luau`/`apply-real-probe-after.luau`/`compute-before-after.luau` — 위 §2 실측 5건, 전부 `mise exec -- luau-lsp analyze`로 실행 확인.
  - `_setup.luau` — 공유 설치 헬퍼(`round13-s6b-compute-hole/_setup.luau`와 동일 패턴).

## 9. 미완/한계

- Animate의 "after"(바인딩 주석을 붙이면 다운스트림이 진짜 제약되는가)는 `Tween<T>`가 quad-roblox 자체 모듈 타입이라 스크래치 배선을 생략했다 — before의 hole만 확인, fix가 통할 거라는 건 §1①의 일반 메커니즘에 대한 유추다.
- `:Apply`의 안전 판정 열두 개(Sum/Clamp/Band/Shl/Alternative 다섯은 직접 실측, Product/Min/Max/Bor/Bxor/Bnot/Shr 일곱은 quad-types의 같은 `NumOp` 선언 모양으로 유추만 하고 개별 실측은 안 함).
- 108행 전부에 대해 "다운스트림 사용"을 코드 블록 안에서만 스캔했다 — 같은 페이지의 **다른 코드 블록**에서 변수 이름이 재등장해도(개념상 이어지는 예제일 수 있음) 별개 블록으로 취급해 못 잡을 가능성이 있다(수동으로 몇 건 대조해 이런 경우가 드묾을 확인했으나 108행 전부를 이 방식으로 재검증하진 않았다).
- §3·§4의 after 초안은 페이지 관례에 맞춘 **기계적** 초안이라 실제 반영 시 각 파일을 다시 luau-lsp로 개별 확인하는 절차가 필요하다(이번엔 메커니즘 확인용 대표 케이스만 실측).
