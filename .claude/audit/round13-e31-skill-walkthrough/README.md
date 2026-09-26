# E31 — 에이전트 스킬 `docs/skills/quad-ui-dev/` 따라 짜기 (2026-09-27, HEAD `47fad75f`)

처음 보는 코딩 에이전트처럼 `SKILL.md`를 위에서부터 읽고 시키는 대로만 (a) 카운터 + `Slot:List` 목록 + 모달 토글 + Tween
하나인 화면, (b) 컴포넌트 둘(props·Slot 자식·Modifier 팩토리)을 짰다. 그다음 스킬 폴더의 모든 `luau` 펜스를 개별로
mock 실행 + strict 검사하고, 산문 주장(에러 ID·규칙)을 `run-claims.luau`로, 이름 존재를 `run-names.luau`로 대조했다.
레포 파일 무변경. Studio/MCP 안 씀.

## 재현

```sh
./scripts/relink.sh
python3 .claude/audit/round13-e31-skill-walkthrough/gen.py --extract   # blocks/ 재추출 + run-*/strict-* 재생성
.claude/audit/round13-e31-skill-walkthrough/run-all.sh                 # mock.log, strict.log
```

- `blocks/<file>-L<줄>.body.luau` = 펜스 원문 그대로(머리 한 줄에 출처). `ui-*.body.luau` = 손으로 짠 walkthrough.
- `tails/<id>.luau` = mock 러너 끝에 붙는 실행부(함수만 정의하는 블록을 실제로 부르고 결과를 찍는다).
- `run-*.luau`(mock, `--!nocheck`, S10 `harness.luau` 복사본) / `strict-*.luau`(스킬 §1.1 프롤로그, `test.sh` 79행 플래그 셋).
- 스킬 §1.1·recipes 머리의 프롤로그 블록(`require(<quad-base module>)` 자리표시자)은 그 자체로 못 돌리므로 strict 머리말이 곧 그 재현이다.

**⚠️ 하네스 주의(H1)**: 처음엔 S10의 `s10-config.luau`처럼 `quad-base/src` + `quad-types/src`를 직접 require했는데, 이러면
**`Slot:List`에 `ctx` 주석을 단 모든 예제(스킬 §4.2·recipes §2·레퍼런스 core/06 예제·`spec.slottypes`의 몸통까지)가 strict에서
`No valid instantiation could be inferred for generic type parameter Item`으로 죽는다.** 원인은 타입이 두 개의 다른 `quad_types`
파일(워크스페이스 원본과 `luau_packages` 사본)에서 오는 것 — `probe-req1`(한 설치본)은 통과, `probe-req2`/`probe-req3`(섞음)은
실패. 실사용자(pesde 설치, `roblox_packages/` 하나)에는 해당 없으므로 이 폴더의 strict는 `quad-roblox/luau_packages`의 한 벌로
돈다. S10의 strict 판정 중 제네릭 `ctx` 주석이 든 블록은 이 혼합 때문에 오판했을 수 있다(S10 §3.3 한 블록은 해당 없음).

## 블록 표

| 블록 | mock | strict | 비고 |
|---|---|---|---|
| SKILL §1.1 프롤로그 (L73) | — | 0 (머리말로) | 자리표시자라 단독 실행 불가. `DeclarationModule`을 바인딩하지 않음(A1) |
| SKILL §2.1 (L126) | OK — `Ada Lovelace`→`Ada Byron` | 0 | 산문 "`dep .. ""`는 에러 없음"은 틀림(A3) |
| SKILL §2.3 (L152) | OK — `false 108 100 Guest red` | 0 | |
| SKILL §3.1 (L180) | OK — Activated 인자 `inputObj 2`, Modifier 반영 | 0 | 주석의 `DeclarationModule.IntoTextButton` 대안은 strict 실패(A2) |
| SKILL §3.3 (L214) | OK — BT 0.5 / Text ok / Visible true | 0 | S10 결과 재확인. 산문의 ID 괄호는 부정확(A6) |
| SKILL §3.4 (L236) | OK | 0 | |
| SKILL §4.2 (L271) | OK — 재사용·LayoutOrder·KeyGone 파괴 | 0 | 한 설치본 기준(H1) |
| SKILL §4.3 (L321) | OK — 옛 원소 파괴 안 됨, `Parent=nil` | 0 | `updateFn` 없는 형태만 통과 — 주석 단 `updateFn`은 B1 |
| SKILL §5 (L336) | OK(※) | 0 | ※ mock Instance에 `:Clone()`이 없어 Clone 대역을 넘김 |
| SKILL §6.1 (L375) | OK — 스냅 S→C, 교체 Cancelled→Started, 자연 종료 Completed, Dedup 무발화, `CanAnimate=false` S,C | 0 | 산문 전부 일치 |
| SKILL §6.3 (L447) | OK — 클릭 뒤 색 변경 | 0 | |
| SKILL §6.4 (L490) | OK — 0.3s 뒤 `ab` 한 번 | 0 | |
| SKILL §6.5 (L504) | OK | 0 | |
| recipes §1 (L20) | OK — `Count: 6`, Animate 트윈 1 | 0 | 프롤로그 주석이 `Out`을 빠뜨림·`D`라 부름(A4) |
| recipes §2 (L82) | OK | 0 | 한 설치본 기준(H1) |
| recipes §3 (L162) | OK — `Bo,Lv. 4` | 0 | |
| recipes §4 (L194) | OK — 유효·초록 | 0 | |
| recipes §5 (L248) | OK — 디바운스 1회, X 버튼 | 0 | |
| recipes §6 (L312) | OK — `Coins: 100` | 0 | |
| rules §2.2 (L60) | OK | 0 | `DeclarationModule` 미바인딩(A1) |
| rules §2.3 (L75) | OK | 1 (예상) | 조각(`Activated = …` 맨 대입) — 전역 미정의 1건은 조각이라 정상 |
| rules §2.4 (L93) | OK | 0 | |
| walkthrough (a) `ui-a-screen` | OK — 카운트 2, 행 재사용·KeyGone, 모달 열기/닫기(파괴), 트윈 스냅→1→2 | 0 | `:Single`의 `ctx.Item`을 `any`로 둬야 통과(B1) |
| walkthrough (b) `ui-b-components` | OK — 인라인 > 뒤 Modifier, `Overridden` B 승, State 필드 Modifier 반응 | 0 | `TextButtonModifier?`/`FrameModifier?` 사용(how-to 01) |
| walkthrough (b) 첫 시도 `ui-b0-into-boundary` | OK | 2 | 스킬 §3.1대로 `IntoTextButton?`/`IntoFrame?` → `props.Modifier or q.None` 자리 TypeError(A2 근거) |

산문 주장 대조(`run-claims.luau` → `claims.log`): 인용된 에러 ID 43개 중 32개는 실제로 던지게 해 문구를 확인했고, 나머지 11개(`0134`·`0140`·`0156`·`0164`·`0165`·`0167`·`0169`·`0172`·`0179`·`0225`·`0226`)는 소스 raise 문자열과만 대조했다 — 전부
일치. 어긋난 것은 A3·A5·A6뿐. 이름 대조(`run-names.luau`): 스킬이 쓰는 `q.*`·`D.*`·Operator·Slot·Ref 이름은 전부 존재,
옛 이름(`q.D`·`:With`·`EffectHandle`·`tag:Names`)은 모두 없음. 스킬 본문에 옛 이름 사용은 없다(`:With`는 v1 맥락에서만).
strict 주장 대조(`probe-strict-claims.luau`·`probe-hook-uses-inst.luau`·`probe-flags.luau`): 스킬·v1-migration 표의 진단
머리(OnCreated `*error-type*`, `() -> ()` 핸들러 거부, `Slot<unknown>`, `Ref<nil>`, `Text = 42`, `D.New` unknown, 불변 State,
AttrKey, `self` 핸들러, `q.State` unknown type, 플래그 없을 때 두 진단) 전부 문구대로 재현.

## 문서 공백 (지시만으로 못 채워 docs/·소스를 본 자리)

- **GAP-1 타입 경로** — §1.1·§3.1·§3.3과 rules §2.2가 `DeclarationModule.X`를 쓰는데 프롤로그는 그 이름을 바인딩하지 않고 경로도
  안 준다. 소스(`quad-roblox/src/init.luau` 머리 주석)와 how-to 01을 보고서야 공개 경로가 quad-roblox **루트 재수출**
  (`require(<quad-roblox>).TextButtonModifier`)임을 알았다(→ A1).
- **GAP-2 `Source:Set` 의미** — 같은 테이블을 고쳐 다시 `:Set`해도 되는지(값 비교 dedup 여부), `:Emit()`이 뭘 하는지 스킬에 없음.
  목록 데이터는 매번 새 테이블로 넘기는 쪽을 추측으로 골랐다. 답은 reference core/02 78행("같은 값도 언제나 전파").
- **GAP-3 Modifier 팩토리** — "Modifier를 돌려주는 함수"와 그 반환 타입(`GuiObjectModifier` 등), 체인 setter가 `State`를 받는지가
  스킬에 없음. 실측으로 확인(체인 setter에 `State<Color3>` → 반응형으로 동작).
- **GAP-4 자식을 받는 컴포넌트** — 스킬은 "컴포넌트는 Instance나 Slot을 돌려준다", "Slot은 배열부"까지만 말하고, 호출자가 자식을
  넘기는 관용구(how-to 01이 통일한 `props.Children: Slot<Instance>?` + `or q.None`)와 `q.Slot<<T>>(initial)`의 `initial` 모양을
  안 보여 준다. how-to 01을 보고 짰다.
- **GAP-5 모달/오버레이** — 스킬 본문에 레시피가 없고 §0 지도만 how-to 09를 가리킨다. `Visible` 토글과 `:Single` 중 무엇을
  권하는지 스킬만으로는 모름 → §4.3의 `:Single`을 골랐다가 B1을 밟았다.
- **GAP-6 `:Single` + strict** — §4.3 "`List`와 같은 `updateFn(ctx)` 모양, 하나로 둘 다"와 §4.2 "strict에선 ctx에 주석"을 합치면
  죽는다. `ctx.Item: any`로 우회(B1).
- **GAP-7 화면 붙이기** — `Parent`는 prop이 아니니 밖에서 `.Parent`를 대입하라는 것까지만 있고 진입점(`PlayerGui`에 `ScreenGui`
  붙이기) 예시는 없음. 사소 — `.Parent = playerGui`로 충분했다.
- **GAP-8 지도 누락** — §0 지도의 `overview/`가 01·02만 적고 `03-from-the-web`을 빠뜨림. `reference/roblox/02`를 여전히 "`D`"로
  부름(페이지 제목은 "Declaration — Instance 생성").

## 발견

### (a) 문서 오류

- **A1 `DeclarationModule`은 스킬이 준 어떤 경로로도 닿지 않는다(MED).** `SKILL.md:89-90`, `:185`, `:224`,
  `references/rules-and-invariants.md:63`, 그리고 `rules-and-invariants.md:56`("the generated `D` module")가 타입을 생성 모듈
  `DeclarationModule`에서 꺼내라고 하지만, 프롤로그(`SKILL.md:73-81`, `code-recipes.md:6-14`)는 그 이름을 만들지 않고 require
  경로도 없다. `quad-roblox/src/init.luau` 머리 주석은 "pesde 설치에선 생성 모듈 경로가 `.pesde/…` 밑뿐이라 루트 재수출이 유일한
  공개 경로 — 공개 계약은 이 루트가 내보내는 이름뿐"이라고 적고, how-to 01 22·26행도 루트(`RobloxModule.TextButtonModifier`)를
  쓴다. 재현: gen.py는 `strict-skill-L214.luau`·`strict-rules-L60.luau`에 레포 전용 경로
  `require("…/quad-roblox/src/Declaration")`를 끼워 넣었다. 그 줄을 뺀 `probe-noDeclModule.luau`는 **진단 0으로 조용히 통과한다** —
  바인딩 안 된 `DeclarationModule.TextLabelModifier`가 에러 없이 무검사 타입이 되므로, 스킬대로 쓴 에이전트는 타입이 사라진 줄도
  모른다.
- **A2 §3.1 "or `DeclarationModule.IntoTextButton` for a typed boundary"는 그대로 쓰면 strict가 깨진다(MED).** `SKILL.md:185`.
  `IntoTextButton`은 `{ AsTextButton: … }`인 인터페이스 타입이라 같은 블록의 `props.Modifier or q.None` 배열부 자리에 들어가지
  않는다 — `strict-ui-b0-into-boundary.luau` 39·54행 `the 1st component of the union is 'IntoTextButton', which is not a subtype
  of …`. how-to 01은 `TextButtonModifier?`를 쓰고, `IntoTextButton?`은 "꽂을 때 `props.Modifier:AsTextButton()`으로 내려받으라"는
  조건과 함께만 권한다(178행). `TextButtonModifier?`로 바꾼 `ui-b-components`는 진단 0.
- **A3 "`dep .. ""`는 에러 없이 쓰레기값"은 틀렸다(LOW).** `SKILL.md:123-124`와 §7 표 `SKILL.md:528`("concatenation is
  garbage"). State 핸들엔 `__concat`이 없어 `attempt to concatenate table with string`으로 던진다(`claims.log` §2.1). 조용히
  쓰레기가 되는 것은 `#dep`(0)과 문자열 보간 `` `{dep}` ``(`Source(table: …)`) 쪽이다.
- **A4 프롤로그 주석의 설치 목록(LOW).** `SKILL.md:79` "installs D / OnChange / Out / …", `code-recipes.md:12` "installs D /
  OnChange / Animate / Tween / isTween". 설치되는 필드 이름은 `Declaration`이고(`q.D`는 nil — `run-names.luau`), recipes 쪽은
  `Out`을 빠뜨렸다(`RobloxExtension` = Declaration·OnChange·Out·Animate·Tween·isTween). 로컬 별칭 `D = q.Declaration`은 문서
  관례라 문제없지만 "installs D"는 `q.D`로 읽힐 수 있다.
- **A5 `q.Tag(q.None)`의 ID가 틀렸다(LOW).** `SKILL.md:429` "A nil hole … and `q.None` are errors (`Quad0203`)". `q.None`은
  `Quad0237 Tag: … (got a table with a metatable)`이다(`claims.log` §6.2). rules 표 18행은 문구는 맞게 적었지만 ID를 안 붙였다.
- **A6 §3.3 괄호 "(Quad0076/Quad0063)"의 대응이 부정확(LOW).** `SKILL.md:216-218`. `{ Sise = 1 }` → `Quad0076`(drive), `{ Activated
  = fn }` → `Quad0063`이지만 drive가 아니라 **Modifier를 만드는 순간**, `{ Size = "x" }` → quad는 값 타입을 안 본다(Property
  핸들러에 raise 자리 없음 — mock에선 조용히 통과, 실엔진에선 엔진의 대입 에러일 것으로 추정, 실기기 미확인). 레퍼런스
  roblox/03 9행도 `Size = "x"`를 "drive에서 `Quad0076` 등으로"에 묶는다(c1 참고).

### (b) 코드 결함

- **B1 `slot:Single(state, updateFn)`에 `ctx.Item`을 구체 타입으로 주석하면 strict가 막힌다(MED, 타입 표면).** 최소 재현
  `probe-single-a.luau`: `q.Source(false)` + `ctx: { Item: boolean | QuadTypes.KeyGone, … }` →
  `No valid instantiation could be inferred for generic type parameter Item … at least: <Source<boolean> 전개> | boolean | KeyGone …
  at most: boolean`. `Source<boolean?>`(`probe-single-b`), `Source<string?>`(`probe-single-e` 16행), 명시 타입 인자
  `:Single<<boolean, nil>>`(같은 파일 21행)도 전부 같은 에러. `ctx.Item: any`(`probe-single-c`)만 통과하고,
  `spec.slottypes.luau`도 `Ctx<any, number>`로만 검사해 이 경로를 덮지 않는다. 시그니처 `state: Item? | StateMarker<Item?>`에서
  넘긴 `Source` 자체가 `Item?` 팔의 하한으로 잡히는 것으로 보인다. 같은 `ctx` 주석이 `:List`에선 통과하므로(`probe-list-*`) 스킬
  §4.3의 "하나의 `updateFn`으로 둘 다"가 strict에선 성립하지 않는다. S10 (1)이 본 GS 14 §5 `:Single` strict 실패와 같은 뿌리일
  가능성이 있다(S10은 8.13 반환형 쪽으로 판정).

### (c) 판단 필요

- **C1 `{ Size = "x" }`를 무엇이 잡는다고 적을까.** 스킬 §3.3과 레퍼런스 roblox/03은 "런타임에 잡힌다"고 하지만 quad 쪽 검사는
  없다. 엔진 대입 에러로 잡힌다고 고쳐 적을지(실기기 실측 필요), "quad는 값 타입을 안 본다"로만 적을지의 선택.
- **C2 스킬에 컴포넌트 자식 관용구를 넣을지.** how-to 01은 자식 전달을 `Slot`으로 통일했는데(224행 부근) 스킬에는 받는 쪽 예가
  없고, `v1-migration.md` 33·98행은 how-to 08과 같이 `{ table.unpack(children) }`을 이관 번역으로 제시한다. 이관 문서로서는 how-to
  08과 일치하므로 틀린 것은 아니지만, 스킬만 읽은 에이전트는 새 코드에도 `table.unpack`을 쓸 것이다(GAP-4).
- **C3 모달 레시피를 스킬에 넣을지, 넣는다면 `Visible` 토글과 `:Single` 중 무엇을.** B1이 풀리기 전까지 `:Single`로 쓰면
  strict에서 `Item: any` 우회가 필요하다(GAP-5·6).
- **C4 하네스 H1을 S10 판정에 소급할지.** 이 폴더는 한 설치본으로 돌렸다. S10의 `s10-config`(혼합 require)로 strict를 본 블록 중
  제네릭 `ctx` 주석이 있는 것(GS 14 등)은 다시 볼 가치가 있다 — 실패가 문서 탓인지 하네스 탓인지 갈린다.

## 미완

- 라이브 사이트 `.md.txt` URL(§0)은 오프라인이라 실제로 가져와 보지 않았다(`astro.config.mjs`에 `starlight-md-txt`
  `.md.txt` 설정과 `/changelog-versions/` 설정이 있는 것만 확인).
- A6/C1의 `{ Size = "x" }` 실엔진 동작, `Claim`의 실제 `:Clone()` 경로는 Studio 금지라 미확인.
- `v1-migration.md`의 strict 표는 스킬·walkthrough가 밟는 행(열 가지 남짓)만 대조했고 전 행은 보지 않았다.
