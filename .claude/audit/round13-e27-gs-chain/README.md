# round13 E27 — 시작하기(GS) 00~21 연쇄 실행 (2026-09-27)

HEAD `4b461ba4` 기준. GS 22편의 `luau` 펜스 125개를 튜토리얼 순서대로 이어 붙여 mock(CLI)에서 실행하고, strict/nonstrict로 검사했다.
레포 파일은 건드리지 않았다(이 폴더만 새로 만듦). 다시 돌리기: `./run-all.sh`(relink → mock 러너 넷 → 탐침 → 검사).

## 파일

| 파일 | 무엇 |
|---|---|
| `harness.luau`·`engine-globals.luau`·`s10-config.luau` | `../round13-s10-snippet-recheck/`의 사본. harness만 두 곳 고침(TextLabel/TextButton에 `TextScaled` 추가, `capture()` 헬퍼) |
| `check.luau` | PASS/FAIL 헬퍼 |
| `chain-a-ch01-10.luau` | 01~10 Main.client 누적 프로그램 — 장마다 "그 장 끝의 독자 코드"를 재구성해 64 검사 |
| `run-b-ch11.luau` | 11장(전부 별도 스크립트) 30 검사 |
| `chain-c-ch12-18.luau` | 12~18 — Counter/CounterBoard/Theme/Settings를 장별 모양대로 옮겨 54 검사 |
| `run-d-ch19-21.luau` | 19~21 조각 + 20장 표 대조 33 검사 |
| `strict.sh` | `scripts/test.sh` 79행 플래그 셋 그대로 luau-lsp analyze |
| `strict-a-ch01-10.luau`·`strict-separate.luau`·`strict-mod/` | 문서 코드를 `--!strict`로 검사(참고용 — 문서는 화면 코드를 nonstrict로 전제, 01 §1) |
| `nonstrict-*`·`nonstrict-mod/` | 같은 코드를 `--!nonstrict`로(문서 전제) |
| `probe-*.luau`·`probe-14s3/` | 발견별 최소 재현 |

## 결과표 (블록 = `장@시작줄`)

분류: **누적**(Main/모듈에 얹히는 코드) · **별도**("새 예시: 별도 스크립트"/"앞 장들과 별개") · **조각**(설명용 한두 줄, 실행한 경우 표시) · **확인**(확인용 블록).
mock ✓ = 실행됨, 출력 일치 ✓ = `-->`/본문 서술과 같음. strict 칸의 "전제 밖"은 무주석 props·콜백 계열(문서가 how-to 01 §6로 넘긴 것), nonstrict는 전 블록 클린(예외 14@175 하나).

| 블록 | 분류 | mock | 출력 일치 | strict | 비고 |
|---|---|---|---|---|---|
| 01@20 | 설정 모듈 | ✓(s10-config 사본) | — | 클린 | 경로만 로컬 |
| 01@50 | 조각 | ✓ | ✓ | 클린 | |
| 01@100 | 누적 | 부분(Players·Loaded 제외) | ✓ | 클린 | |
| 02@21 | 누적 | — | — | — | require 두 줄 |
| 02@33 / 02@52 / 02@87 | 누적 / 확인 / 누적 | ✓ | ✓ | 클린 | `Parent` 에러 문구는 mock이 `(value: table)` — mock 표기 차 |
| 02@119 | 별도 | ✓ | ✓ Quad0023 verbatim | 의도된 에러 | |
| 03@16~@104 (4) | 누적 | ✓ | ✓(카운트: 1 / 7 / 7회·7번, previous 첫 nil) | 클린 | |
| 04@16·@47 | 누적 | ✓ | ✓ | 클린 | |
| 05@18·@40·@92·@151 | 누적 | ✓ | ✓ | 05@151 뒤 확인 줄 `active:Set(q.None)` 진단 | C1 |
| 05@53 | 확인 | ✓(GetTagged 대신 GetTags) | ✓ | — | mock에 GetTagged 없음 |
| 05@73 / 05@122 / 05@175 / 05@212 | 조각 / 확인 / 확인 / 조각 | ✓ | ✓(엔진 호출 0·removeTag:Even 하나·Attr 셋·Quad0002) | 클린 | |
| 05@231 | 확인 | ✗ mock 불가 | — | 클린 | QueryDescendants는 엔진 API |
| 06@19·@40·@74·@90 | 누적 | ✓ | ✓ | 06@40 인라인 Compute 무주석 진단 | C5 |
| 06@110 | 확인 | ✓ | ✓ emits 1/1/2/3 | 클린 | |
| 06@152 / 06@179 | 조각 | ✓ | ✓ HEY / Quad0224 | 06@179 **진단 없음** | A5 |
| 07@23·@75·@115·@134 | 누적 | ✓ | ✓ | 전제 밖 둘(`.Value.ClassName`) | |
| 07@53 | 조각 | — | — | — | 타입 설명 |
| 07@188 | 별도 | ✓ | ✓ 자식 수: 2 | 클린 | |
| 08@20·@103·@141·@179 | 누적 | ✓ | ✓ | 08@179 `return nil` 진단 | C5 |
| 08@51·@72 | 조각 | ✓ | ✓ | 클린 | |
| 09@23·@88 | 누적 | ✓ | ✓ §1과 §2 출력 동일(자식 3) | 09@88 `#kids` 진단(8.20) | A7 |
| 09@128 | 조각(문서용 요지) | — | — | — | 실행 대상 아님 |
| 10@18·@28·@50 | 누적 | ✓ | ✓ | 클린 | |
| 10@76 | 조각 | ✓ | ✓ 16/24 | 클린 | |
| 10@103·@163 | 별도 | ✓ | ✓ | 클린 | |
| 10@120 | 별도 파일(Styles) | — | — | 클린 | 튜토리얼 뒤쪽에서 안 씀(문서대로) |
| 10@151 | 누적 | ✓ | ✓ | 클린 | `accent` 출처 C3 |
| 11@22~@234 (10) | 별도(11@51 strict 조각, 11@96 조각) | ✓ | ✓(Offset/Length 전부, 물리 순서 Inner1..Inner4) | 11@51 클린, 나머지 전제 밖 | 11@234 서술 A2 |
| 12@22·@100 | 새 파일 Counter | ✓ | ✓ | 전제 밖 | |
| 12@67·@145 | 누적 Main | ✓ | ✓ 독립 카운터 | 전제 밖 | A6 |
| 12@186 | 별도 파일 Checkbox | ✓ | ✓ | 전제 밖 | |
| 12@215 | "별도"라 표시됐으나 Main의 q·D·screen 사용 | ✓ | ✓ ☐/꺼짐→☑/켜짐 | 전제 밖 | C6 |
| 12@254 / 12@297 | 조각 | ✓ | ✓ 에러 문구 / Quad0076 key 1 boolean | — | |
| 12@271·@282 | 누적 | ✓ | ✓ 오른쪽만 덤 자식 | 전제 밖 | |
| 13@25·@38 | 조각 | ✓ | — | — | |
| 13@66·@80·@99·@110 | 누적 | ✓ | ✓ 노랑/파랑, Watch 로그 | 전제 밖 | |
| 13@141·@164·@187·@240 | 별도(이어짐) | ✓ | ✓ 10/11, 카운트: 0/1, Operator 14개, Doubled | 전제 밖 | |
| 13@202 | strict 조각 | — | — | **클린** | |
| 13@267 | 조각 | ✓ | ✓ | — | |
| 14@23·@37·@89·@107·@135 | 누적 | ✓ | ✓ | 전제 밖 | |
| 14@175 | 누적 | ✓ | ✓ 재사용·카운트 유지 | **nonstrict에서도 진단 1** | C2 |
| 14@203 | 조각 | ✓ | ✓ Detach 재마운트 | — | |
| 14@235·@263 | 별도 | ✓ | ✓ 3/왼쪽(수정)/true | 전제 밖 | |
| 14@291 | 별도 | ✓ | ✓ 4/5/4 | 기존 구멍(8.13, S10 기록) | |
| 15@24·@35·@53·@70 | 누적 | ✓ | ✓ 가방 색, Ctx 없으면 Lua 에러, Quad0038 | 전제 밖 | |
| 15@124 | strict 조각 | — | — | **클린** | |
| 16@18·@40·@51·@68·@82·@91 | 누적 | ✓ | ✓ 보폭 순환·보폭 3 적용 | 전제 밖 | |
| 16@27 | 누적(확인 표시 없음) | ✓ | ✗ §3 서술과 충돌 | — | A4 |
| 17@22·@58·@87·@99 | 누적 | ✓ | ✓ 1~9회 트윈 0·10회 1·✨·Cancelled·첫 세팅 즉시 | 인라인 부분 클린 | 17@58 C4 |
| 18@22~@141 (6) | 누적 | ✓ | ✓ 10 점→100 점→100 포인트, 3회/2회, 13 점 | 전제 밖 | 되돌림 지시 A3 |
| 19@34~@157 (6) | 조각 | ✓ | ✓ 0회, 1 "3"/2 "15", 1/1/2 60, 0/2/5, 트윈 Time 1.0, 3/2 | 전제 밖 | |
| 20@28 | 조각 | ✓ | ✓ 이름 다섯 존재 | — | 표 장 번호 A1 |
| 20@106·@137·@166 | 별도 | ✓ | ✓ A/A2/B/B, 이펙트 순서, true false→false true | 전제 밖 | |
| 21@42 | 별도 | ✓ | ✓ 관측 멈춤·cleanup·강한 구독 계속 | 클린 | |

mock 합계 181 검사 0 FAIL(러너 넷). **코드 결함(b)은 찾지 못했다** — 문서가 말하는 런타임 동작은 전부 재현됐다.

## 발견

### (a) 문서 사실 오류

- **A1** `docs/getting-started/20-handlers.md:47-49` — 핸들러 표의 장 번호 셋이 재번호(06~20 → 07~21) 전 값으로 남았다: `q.Ref(nil)(06)`은 07, `q.Effect(fn)(07)`은 08, `q.Slot {}(10)`은 11이어야 한다. 핸들러 이름 자체는 `run-d-ch19-21.luau` "20 표" 열 줄 전부 일치.
- **A2** `docs/getting-started/11-slot.md:259` — "`State` 자리에 지금 놓여 있는 원소는 `q.dispose`도 막지 않으니" — 실제로는 `Quad0179`로 막힌다(`probe-11s6-dispose.luau`: `pcall(q.dispose, a)` → false, a는 그대로 붙어 있음). 같은 사실을 `21-wrap-up.md:56`은 "같은 에러로 막힙니다"로 맞게 적었고 그 주석이 2026-09-17 변경을 기록한다 — 11장만 갱신이 빠졌다.
- **A3** `docs/getting-started/18-blocker.md:20` — 되돌림 지시("props.Ctx를 읽던 줄과 Theme require는 지웁니다")가 16장이 `Counter.luau`에 넣은 `Settings` require·`props.Ctx:Get(Settings.Provider)`·`+ 1` 버튼 `Activated`의 `settings.Step:Get()`을 언급하지 않는다. 지시를 문자 그대로 따르면 `settings`가 정의되지 않은 채 남아 `+ 1` 클릭이 던진다(mock: `attempt to index nil with 'Step'` — `chain-c-ch12-18.luau` "18 (c)"). strict에서는 그 이름이 Roblox 전역 `settings()`로 해석돼 `Type '() -> GlobalSettings' does not have key 'Step'`(`strict-mod/Counter18.luau`), nonstrict는 진단 없음 — 실기기에서는 함수 인덱싱 에러가 날 것(추정, 미실측). §3 "세 번 눌렀다면 `13 점`"은 보폭 1을 전제한다.
- **A4** `docs/getting-started/16-store.md:27-30`의 `settings.Step:Set(5)`는 "확인용·지운다" 표시 없이 Main 흐름에 놓여 있는데, 같은 장 `:105`는 "'보폭: 1' 버튼이 하나 뜨고, 누를 때마다 2, 3, 4, 5, 1"이라 한다. 그 줄을 남기면 `보폭: 5 → 1 → 2 → 3 → 4 → 5`(`probe-16-step5.luau`). 다른 장(03·05·10)은 같은 종류의 줄에 "확인이 끝나면 지웁니다"를 달아 두었다.
- **A5** `docs/getting-started/06-flowing-back.md:175-177` — "`q.Out`의 둘째 자리는 … `--!strict`에서 타입 검사가 먼저 막습니다" — 바로 아래 스니펫 그대로(`const derived = name:Compute(function(n) return n:Get() end)`, 무주석)는 strict 신 솔버(test.sh 플래그)가 **통과**시킨다. `derived: q.State<string>`처럼 주석을 달았을 때만 거부된다(`probe-06s5-out-strict.luau` — 줄 8 무진단, 줄 9 거부). 런타임 `Quad0224`는 문구까지 일치.
- **A6** 장 사이 누락 셋 — (1) `12-components.md:146-174`의 "Main.client.luau — 01장부터 지금까지 전체 모습"에 06장이 `screen`에 직접 붙인 `nameLabel`·`nameBox`·`resetButton`(와 `name`)이 없고, `:20`·`:176`의 "뺀 것" 목록도 그것을 언급하지 않는다(06 이후 어느 장도 그 이름을 다시 부르지 않음 — grep). (2) `12-components.md:65` "02~09에서 만들었던 `card`" — `card`는 10장(`10-modifier.md:30`·`:65`)에서도 다시 선언된다. (3) `10-modifier.md:36` "05~08장에서 붙인 숫자 키"와 같은 장 `:65` "05·07~09장" — 09장 훅 자리가 앞쪽에서 빠졌다.
- **A7** `.claude/base/typing-limits.md` 8.20 끝 "우회는 지역 변수 주석 `const kids: { Instance } = inst:GetChildren()`(GS 08이 그 형태)" — 훅 장은 지금 09이고, 그 주석은 `d3790cdc`("08 kids 타입 주석 제거")에서 빠져 `09-lifecycle-hooks.md:98`은 주석 없는 `const kids = inst:GetChildren()`이다. strict에서 8.20 진단이 그대로 난다(`strict-a-ch01-10.luau:172`, `probe-09-inline-hooks-strict.luau:5`). 같은 탐침에서 인라인 `q.OnCreated<<Frame>>`도 콜백 파라미터가 `Frame`이 아니라 사용처에서 구조 추론된다(줄 7) — 테이블 밖에서는 `Frame`(`probe-09-standalone-hooks-strict.luau` — 기대한 대로 `number` 대입에서 `got Frame`).

### (b) 코드 결함

- 없음. 181 mock 검사와 탐침에서 문서대로 했는데 quad가 잘못 동작한 사례는 찾지 못했다.

### (c) 판단 필요

- **C1** `05-tag-attr.md:182` `active:Set(q.None)` — 런타임은 문서대로 `Active` 삭제(`chain-a` 05@175), strict는 `Expected this to be 'boolean', but got 'None'`(`strict-a-ch01-10.luau:73`). 문서 전제(nonstrict)에선 안 보이지만 레퍼런스(`reference/core/09-tag-attr.md:293` `hp:Set(q.None)`)도 같은 모양이고 typing-limits에 이 항목은 없다(grep). 타입 표면을 바꿀지, 문서에 캐비엇을 둘지의 문제.
- **C2** `14-lists.md:181`(`+ 카운터` 버튼) `table.clone(props.Rows:Get())` — 문서 기본 모드 **nonstrict에서도** 신 솔버가 `Argument count mismatch. Function expects 1 argument, but none are specified`를 낸다(GS 전체 nonstrict 검사에서 유일한 진단). quad 없이 `return function(props) local v = table.clone(props.Rows:Get()) return v end` 한 줄로 재현되므로(`probe-14s3/pure4.luau`) Luau 쪽 추론 한계로 보인다(추정). 문서가 이 줄을 바꿀지·캐비엇을 둘지·그대로 둘지.
- **C3** `10-modifier.md:152` "위쪽 코드에 이어집니다(§3의 accent를 그대로 씁니다)" — §3의 `accent`는 "새 예시: 별도 스크립트"(`:104`)와 Styles 모듈(`:120`) 안에만 있어 Main 누적 코드에는 없다. 이 블록을 누적으로 읽을지 별도로 읽을지 표시가 엇갈린다.
- **C4** `17-animation.md:63-69` "콜백 셋을 더합니다"라면서 제시한 `q.Tween { … }`에서 첫 블록의 `Style = Enum.EasingStyle.Quad`·`Override = "Cancel"`이 빠졌다. 교체로 읽으면 이징이 기본값으로 바뀐다(동작 차이는 그것뿐 — mock에서 콜백 규칙은 전부 일치).
- **C5** strict에서만 보이는 문서 코드 진단 둘 — `06-flowing-back.md:48` 인라인 `name:Compute(function(n) …)`(다른 장은 인라인 Compute에 `q.StateData<T>`를 달고 "strict가 봅니다" 주석을 붙이는데 여기만 없음, `strict-a:80`), `08-observer-effect.md:204` `return nil`이 `Expected this to be '(...any) -> ()', but got 'nil'`(`strict-a:157`). 둘 다 nonstrict 클린.
- **C6** `12-components.md:216` "새 예시: 별도 스크립트(01장 진입점의 `screen`에 붙인다)" — 실제로는 Main의 `q`·`D`·`screen`을 쓰는 누적 코드다. 표시 문구만의 문제.

## 확인한 연속성(문제 없음)

- GS 본문의 "N장 M절" 참조 전수(grep 180여 줄) — A1 표 셋을 빼면 가리키는 절이 실제 내용과 맞다(예: 16 → "15장 4절" `:Set` 체이닝, 14 → "11장 5절" LayoutOrder, 09 → "07장 3절" `:Callback`, 20 → "11장 6절"·"05장 3절", 08 → "시작하기 10" 인라인 Compute 권고). how-to 절 번호(01 §1·§2·§3·§6, 08 §7, 10 함정 5)도 실재.
- 이름 연속성: `count`·`countText`·`card`·`buttonRef`·`Counter`·`CounterBoard`·`rows`·`ctx`·`settings`·`Theme`은 07~17에서 같은 모양으로 이어진다(A3·A6이 예외).

## 미완

- **미완** 05@231 `QueryDescendants`, 05@53 `GetTagged` — mock에 없는 엔진 API라 실행 못 함(Studio 금지 규칙).
- **미완** 01@100의 `Players`/`game.Loaded`/`playerGui`와 08@179의 실제 `GuiService`, 파괴 cleanup의 "한 틱 뒤" — mock 밖(셰임으로만).
- **미완** 06 §3의 "엔진이 같은 값 재대입엔 신호를 안 낸다" — mock은 같은 값에도 변경 신호를 내므로 그 고리 끊김 자체는 재현 못 함(결과 emits 1/1/2/3은 `q.Out`의 값 비교로 일치).
- **미완** 18 §1의 중간 상태 `100 점`은 버튼 본문을 줄 단위로 나눠 관측했다(버튼 안에서의 Property 쓰기 가로채기는 안 함).
- **미완** 컴포넌트 파일(Counter·CounterBoard·Checkbox)을 how-to 01 §6대로 주석 달아 strict 클린이 되는지는 보지 않았다(문서 전제가 nonstrict라 범위 밖으로 둠).
- **미완** A3의 실기기 에러 문구(추정 "attempt to index function with 'Step'")는 미실측.
