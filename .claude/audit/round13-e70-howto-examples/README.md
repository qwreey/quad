# E70 — how-to·오버뷰·Quadnomicon·랜딩 예제 블록 전수 mock + strict (2026-09-27)

HEAD `6381f253`. E58(레퍼런스)이 안 본 나머지 — `docs/how-to/01~10`, `docs/overview/*`, `docs/quadnomicon/*`, 랜딩
`docs/site/src/content/docs/index.mdx`의 ```luau 펜스 105개(```lua 펜스는 없음)를 뽑아 E58 방법 그대로 분류하고, 실행 대상(a)·조각(c)·
Roblox 셔임(d)은 mock 실행 + `--!strict` 신 솔버(`scripts/test.sh` 79행 한도 플래그 셋 그대로 — `run-strict.sh`)를 돌렸다. P(프롤로그)는
strict 머리로만 쓰고, b(Quadnomicon의 내부 소스 발췌·타입 선언·옛 모양)는 실행하지 않고 **현재 소스와 한 줄씩 대조**했다. 레포 파일은
건드리지 않았다. 재실행: 레포 루트에서 `./.claude/audit/round13-e70-howto-examples/run.sh`.

앞선 실행과의 경계: E15/E17은 how-to 02·03·04·05·07·09 레시피를 **조합 시나리오**로 돌렸고, S1(2026-09-26)은 how-to 블록을 장 단위로
이어 붙여 mock만 돌렸다. 이번은 블록 **하나하나**를 페이지 프롤로그 + 필요한 앞 블록(`with`)만 붙여 mock·strict 둘 다 돌린 것이고, 그
앞 라운드가 이미 적은 발견(`H-677`~`H-680`, `H-692`~`H-694`, `H-797`, `H-800`, E17 F4, Q121/E45)은 다시 보고하지 않았다.

## 파일

| 파일 | 뭐 하는가 |
|---|---|
| `extract.py` | 대상 네 곳의 펜스 → `blocks/<슬러그>-L<펜스 여는 줄>.luau` + `index.tsv` |
| `spec.py` | 블록별 분류·보강. E58 형식에 `with`(같은 페이지 앞 블록 이어 붙이기)·`module`(최상위 `return` 블록 — mock은 함수로 감싸 `__mod_<이름>`, strict는 `strict/<이름>.luau`로 써서 진짜 `require`)·`pre2`·`mpre`/`spre`(mock/strict 전용 보강)·`ssub`(양쪽 치환)를 더함 |
| `gen.py` | `mock/`(러너)·`strict/`(strict 파일)·`strict-offsets.tsv`(블록 본문 줄 범위) 생성 |
| `harness.luau`·`engine-globals.luau` | E58 사본 — 한 벌(`quad-roblox/luau_packages`). engine-globals만 변경: UDim2 `__add`(how-to 08 §4의 UDim2 덧셈), `Vector2.zero`, `Enum.KeyCode.Tab`, `Enum.UserInputType.MouseMovement` |
| `strict/Quad.luau` | GS 01 §1 설정 모듈 한 벌 사본(E58·E56과 같음) |
| `run-mock.sh`·`run-strict.sh` | E58 사본(`luau`는 `mise exec --`로) |
| `probes/*.luau` | 산문 주장·strict 갈래 확인용 프로브 다섯(아래) |
| `report.py` → `out/table.md` | 블록 표 + 폴더별 집계. strict TypeError는 **블록 본문 줄 범위 안**의 것만 그 블록에 센다 |
| `out/mock/<키>.txt`·`out/mock-summary.tsv`·`out/strict.txt`·`out/probe-*.txt` | 원출력 |

블록 키·표의 줄 번호(`-L<n>`)는 E58과 같이 **펜스 여는 줄**이다(본문은 n+1부터).

mock 쪽 require 처리: 설정 모듈은 하네스의 `q`, `quad_types`는 빈 테이블(타입 전용), `quad_roblox`는 `QuadRoblox`, how-to 06의
`../luau_packages/quad_base`는 **프로바이더 없는 새 인스턴스 `Quad.New()`**(문서의 "`quad_base`만 깐 luau 프로젝트" 대역), 같은 폴더 모듈
(`./Theme`·`@game/…/ModalContext` 등)은 `__mod_<이름>`. Studio 템플릿은 `Instance.foreign`로 짓고, mock에 `:Clone`이 없어 `__clone`(foreign
사본)으로 바꿨다. `ReplicatedStorage`·`UserInputService`·`RemoteEvent`·`Players`는 블록마다 최소 셔임.

## 집계

| 폴더 | 블록 | P | b | a | c | d | 실행 | mock 통과 | strict 대상 | strict 클린 |
|---|---|---|---|---|---|---|---|---|---|---|
| how-to | 76 | 9 | 0 | 41 | 17 | 9 | 67 | 66 | 67 | 60 |
| overview | 2 | 0 | 0 | 1 | 1 | 0 | 2 | 2 | 2 | 1 |
| quadnomicon | 26 | 1 | 20 | 3 | 2 | 0 | 5 | 5 | 5 | 3 |
| landing | 1 | 0 | 0 | 1 | 0 | 0 | 1 | 1 | 1 | 1 |
| **합** | **105** | 10 | 20 | 46 | 20 | 9 | **75** | **74** | **75** | **65** |

- mock 실패 1 = how-to 10:205(발견 1 — 문서 오류, 하네스 한계 아님).
- strict TypeError가 있는 블록 10: 발견 1(how-to 10:205), **새 유형 1(how-to 06:149·180 → 발견 3)**, 의도 2(how-to 01:93·10:64 — ❌ 줄을 strict가
  잡음), 기지 5(how-to 01:34·overview 01:31 = 8.13 인라인 무주석 Compute, 문서 옆 주석이 안내 / how-to 07:26 = E17 F4 / quadnomicon 09:139 =
  Q121·E45 무주석 `ctx` 람다 / quadnomicon 05:92 = 정의 없는 변수를 `Source<Instance?>`로 보강했을 때만 — 확인만 참고).
- lint(LocalUnused 등) 185줄은 조각 예제의 미사용 지역·보강용 `H` — 판정 대상 아님.
- 출력 불일치: 발견 1·2의 셋. 나머지 블록은 주석·산문이 말한 값·상태와 전부 일치(`out/table.md`).

## 발견

1. **(문서 오류, 중) how-to/10-debugging-and-troubleshooting.md:209·213(펜스 205) 함정 "수동 Slot에 :List" 예제의 ✅ 줄이 그 자체로 던진다.** 두 줄 다
   `D.Frame { Text = ctx.Item }`인데 Frame에는 `Text` 프로퍼티가 없어서, "처음부터 :List"로 고친 ✅ 모양도 요소를 만드는 순간
   `Quad0076 Dispatch: no handler matched key Text (value: string)`로 끝난다(`out/mock/how-to_10-debugging-and-troubleshooting-L205.txt`). ❌ 줄은 문서
   말대로 `Quad0149 Slot: cannot install :List/:Single on a manual Slot`이 먼저 나서 이 문제가 가려진다. strict도 두 줄 모두에서 `Text` 키를
   거부한다(`out/strict.txt` L205 14·18행). `D.TextLabel`로 바꾸면 mock은 자식 2개로 정상(`out/probe-howto10-slot-fixed.txt`)이고, strict는 무주석
   `ctx` 람다라 Q121 계열 진단이 남는다(`out/probe-strict-variants.txt` V7) — 그러니 고칠 때 `D.TextLabel { Text = ctx.Item :: string }` 모양까지
   가면 둘 다 조용하다(E45가 확인한 처방). 고칠 곳: 209·213의 `D.Frame` 두 자리를 `D.TextLabel`로(+ 선택적으로 캐스트).
2. **(문서 오류, 낮음) how-to/01-component-conventions.md:94(주석 "props.Modifier가 없으면 1번 자리가 구멍이 된다 — 그 자리에서 에러")와
   how-to/10-debugging-and-troubleshooting.md:58~61(산문 "1번 자리나 중간이 구멍이면 … 그 자리에서 에러가 나고")이 가장 흔한 경우에 틀린다.**
   `props`에 `Modifier`도 `Ref`도 없으면 테이블 `{ nil, nil, Text = "x" }`의 숫자 키 부분이 통째로 비어 구멍을 감지할 원소가 없고, 버튼은 에러
   없이 만들어진다(`out/mock/how-to_01-component-conventions-L93.txt` "both-nil ❌ line: true TextButton", how-to 10:64도 같음). 에러는 뒤에 값이 있는
   경우(`Ref`만 있을 때)에만 난다(`Quad0023 … sourceList[1] is nil`, 같은 파일). how-to 01 88행의 "조용히 넘어가는 것은 꼬리 구멍뿐" 규칙에
   비추면 이 경우는 선두이자 꼬리 구멍이라 그 규칙과는 맞지만, 예제 주석과 how-to 10 산문의 "1번 자리가 구멍이면 에러"는 조건 없이 적혀 있다.
   strict는 두 문서의 ❌ 줄을 항상 잡는다(옵셔널 Modifier·Ref를 숫자 키 자리에 그대로 두면 `nil`이 자식 유니언에 안 들어감 — `out/strict.txt`).
   고칠 곳: 주석을 "뒤에 값이 오면 그 자리에서 에러, 둘 다 없으면 우연히 통과(꼬리 구멍) — 어느 쪽이든 계약 밖"류로 한정.
3. **(새 strict 유형, 낮음~중) how-to/06-headless-testing.md:134·149·180 — `Quad.New():UseProvider(myProvider)`로 만든 `q`는 프로바이더의 반환
   타입이 `any`거나 인덱서 테이블(`{ [any]: any }`)이면 strict에서 모든 `q.<멤버>` 호출이 `Cannot call a value of type *error-type* in union`이
   된다.** `UseProvider`의 선언(`quad-types/src/init.luau:653` `<Self, P>(self: Self, providerFn: (Self) -> P) -> Self & P`)에서 `Self & any`나
   `Self & { [any]: any }`가 멤버 조회를 `(원래 타입) | *error-type*`로 만든다. 프로브 `probes/strict-useprovider.luau`: 반환 `{}`·`{ Foo: number }`·실제
   `QuadRoblox`는 무진단, `{ [any]: any }`·`any`는 진단(`out/probe-strict-useprovider.txt` 10·12행). 이 문서가 본보기로 권하는 이 저장소의 mock
   프로바이더(`quad-base/test/mock.luau:645` `mockProvider(quad: any): { [any]: any }`)가 바로 인덱서 반환이라, 그걸 베껴 헤드리스 테스트를 `--!strict`로
   쓰면 §3의 모든 줄이 진단을 받는다(런타임은 정상 — how-to 06 네 블록 mock 전부 통과, 단언 전부 성립). `typing-limits.md` 8.x에 이 모양은
   없다(6절은 type function을 거친 뒤의 `Self & P` 체이닝이라 다른 것). 사용자 문항 후보: (a) how-to 06 §3에 "프로바이더 반환에 인덱서/`any`
   주석을 달지 말 것(구체 레코드나 무주석)" 한 줄 + `typing-limits.md`에 기록, (b) 기록만 하고 문서는 그대로(헤드리스 테스트는 보통 무검사),
   (c) `mockProvider` 반환 주석을 바꾸는 것까지 — (c)는 테스트 코드 변경이라 결정 대상.
4. **(문서 경미) how-to/09-overlays-modal-toast.md:115~128(펜스 114) "조건부 자식으로 바꾸면요?" 예제가 바로 아래 131행 자기 권고를 안 따른다.** 131행은
   "옛 인스턴스는 파괴되지 않고 떼어지기만 합니다 — 다시 쓸 일이 없으면 `q.dispose`로 직접 정리하세요 … 매번 새로 만드는 이 모양은 열 때마다
   확실히 버릴 생각이 있을 때"라고 하는데, 예제의 `OnConfirm`/`OnCancel`은 `activeModal:Set(nil)`만 하고 버리지 않는다. 호스트에 놓고 돌려 보면
   확인 뒤 호스트 자식 0·옛 모달 `isDestroyed = false`(`out/mock/how-to_09-overlays-modal-toast-L114.txt` 둘째 줄) — 열 때마다 모달 하나가 떼어진 채
   남는다. 자기 `Activated` 안에서 `Set(nil)` 뒤 `q.dispose(모달)`이 정상 동작하는 것은 E15가 이미 확인했다. 고칠 곳: 두 콜백에 옛 값을 잡아
   `q.dispose`하는 두 줄을 넣거나, 131행을 "이 예제는 정리를 생략했다"로 한정.
5. **(문서 경미, 낡은 경로) quadnomicon/04-covariant-markers.md:99 주석 "생성된 `D/init.luau`의 실제 한 줄"** — 생성 폴더는 2026-09-14 개명 뒤
   `quad-roblox/src/Declaration/init.luau`이고, 인용된 `type PV2 = …` 줄 자체는 그 파일 61행과 글자 그대로 일치한다. 이 경로 이름을 쓰는 곳은
   `docs/` 원문에서 이 한 줄뿐(사이트 `dist/` 빌드 산출물 제외). 고칠 곳: `Declaration/init.luau`로.

코드 결함: 0. 새 strict 유형: 1(발견 3).

## 확인만 한 것

- how-to 06 §2 산문 "프로바이더 없이 `Observer`를 단 원천에 `:Set` → `Quad0108 quad: isHeld is not available …` 그 자리에서 던짐": 등록 1회 발화 후
  `Set`이 문구 그대로 던지고 값은 이미 90으로 바뀌어 있음(`out/probe-howto06-noprovider-set.txt`). §3의 `Quad0213` 문구·같은 프로바이더 재호출 멱등,
  §3 Observer 보류→바인딩 재생→`q.dispose` 뒤 정지 단언 전부, 트리 조립 두 단언 전부 성립.
- how-to 10:82 `myRef:Wait().Value` 갈래: 빈 Ref에서 코루틴이 대기하다 `D.Frame { myRef }`로 채워지는 순간 깨어나 그 인스턴스를 받음(`out/probe-howto10-ref-wait.txt`).
- how-to 03 §4 VirtualList: 스크롤 0 → 행 17, 1000 → 행 20(첫 행 Y 850 = (18−1)×50), 창 높이 100 → 행 10 — 본문 산식 그대로. §2 `updateFn`의 `LayoutOrder = Index + Offset`.
- how-to 08 §2 "defaults에 평범한 값 → 생성자 에러" = `Quad0198 Store: default for "Color" is not a Source`. how-to 08 §4 `Op.Sum`·`Alternative`·`Indexed`·UDim2 덧셈, §5 Animate/Tween 트윈 2, §7 재정렬 `LayoutOrder`, §8 훅 셋·`OnChange`·PreRef `:Unwrap()` 순서대로 발화.
- how-to 05: `Context:Get` 빈 가방 `Quad0038`·`:Peek` nil, `Modifier.Overridden`이 호출자 필드만 덮음, 테마 토글이 토큰을 따라감. how-to 09 모달·토스트(3초 뒤 제거)·Fallback 자리표시·ErrorModal 표시/해제, Context 깊은 트리 버튼.
- quadnomicon 발췌 20블록을 현재 소스와 대조: 01의 `Revision` 뒤집기(`Source.luau:70`)·`_receive`(`State.luau:149~158`)·`Get` 루프(`State.luau:227~236`), 02의
  `rawSplice` 흐름(`Slot/Raw.luau:350~386`, "발췌"라 `if mounted` 가드 생략), 04의 `StateMarker`/`SlotMarker`(`quad-types/src/init.luau:55·57`)·`PV2`,
  05의 `setOffsetSource`/`setLength`(+ `setEmpty`가 같은 순서, `Bookkeeping.luau:409~417`), 06의 `isHeld`/`isBoundAlive`/`canBound`/`canExecute`
  (`quad-roblox/src/LifetimeHandle.luau:104~110`, `quad-base/src/LifetimeHandle.luau:100~120`)·`holdLifetime`·`bindLifetime` 순서·Observer `_receive`
  게이트, 06:32의 두 인자 `canExecute`는 절 제목대로 "옛 모양"이라 현재 한 인자와 어긋나도 맞음, 07의 `nop`/`gchold`/`gcconn` 셋업
  (`quad-roblox/src/LifetimeHandle.luau:49·70~76`), 08의 `Handler` 타입(`quad-types/src/init.luau:448~457`), 10의 `UseProvider` 본문(`quad-base/src/init.luau:195~221`),
  11의 `Quad0186` 줄(`State.luau:252`)과 `setFuncLevel`(`quad-error/src/init.luau:108~119`) — 이름·인자 수·에러 ID 전부 일치(발견 5의 경로 이름만 예외).
- quadnomicon 09 §2 "root의 실제 자식은 넷", §4 `:List` 재정렬 `LayoutOrder`(Offset 1 반영), quadnomicon 05 §3 맨 State가 `OwnsElements=false`로 감싸져 호스트
  파괴 때는 같이 파괴, quadnomicon 07 §5 Claim 반환 = 넣은 인스턴스, quadnomicon 11 §1 `formatError` 메시지, overview 01 두 블록, 랜딩 카운터 카드.
- quadnomicon 05:92 strict: 정의 없는 `myInstanceState`를 `Source<Instance>`·`State<Instance>`로 보강하면 무진단, `Source<Instance?>`로 보강하면
  `q.Slot<<Instance>> { … }` 초기 원소 자리(`StateMarker<Instance>`)가 거부(`out/probe-strict-variants.txt` V1~V3). 같은 `State<Instance?>`를 `D.Frame`
  숫자 키 자리에 맨 채로 두면 자식 유니언의 `StateMarker<(…)?>` 팔이 받는다 — 두 입구의 nil 허용이 다르지만 문서는 이걸 "감싸진 모양" 설명으로만
  쓰므로 판단 재료로만 남김.

## 미완

- Roblox 전용(d) 9블록은 셔임 위에서만 돌았다(실 `RemoteEvent`·`UserInputService`·`Players`·Studio 템플릿 `:Clone()`은 미실측 — E17 미완과 같음).
- how-to 03:194의 Throttle "0.1초 창마다 한 번 통지"는 값만 봤고 통지 횟수는 세지 않았다(E15가 Throttle 조합을 이미 봄).
- 구 솔버·nonstrict는 돌리지 않았다. how-to 06의 pesde.toml·bash 펜스는 대상 밖(```luau/```lua만).
- 발견 3의 원인을 솔버 층까지 좁히지 않았다(선언 `Self & P`에서 `P`가 `any`/인덱서일 때라는 관측까지).
