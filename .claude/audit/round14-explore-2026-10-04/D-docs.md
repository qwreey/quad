# round14 탐사 D — 공개 문서를 이번 주 코드로 실행·대조

> opus 탐사자 원문(2026-10-04, 읽기 전용, 공통 규칙 `round14-explore-2026-10-04/common-rules.md`). 서브에이전트가 파일을 쓰지 않아 메인이 보고 본문을 옮겼다. 결정 아님 — 메인·검증자 판정 전 원문.

## round14 탐사 — 각도 D(공개 문서를 이번 주 코드로 실행하고 대조)

- 기준 HEAD는 `bdd3e0bd`(직전 `8592751f`에 세션 파일 한 줄만 더한 커밋)입니다.
- 실측 사본은 `/tmp/claude-0/-code-Projects-quad/375233bc-c5ce-4803-af8f-62ebd7b9d5c7/scratchpad/r14x-d/`이고, 패키지 다섯과 `scripts/`를 `cp -rL`로 복사한 뒤 relink를 돌렸습니다.
- 공통 하네스는 `quad-roblox/test/r14d_h.luau`입니다. mock 위에 Reflection·이벤트·TweenService·task 가상 시계를 얹었습니다.
- 프로브는 `quad-roblox/test/r14d_p1.luau`~`r14d_p20.luau` 스무 개입니다. 전부 `ulimit -v 4000000; timeout 600`으로 돌렸고 무거운 실행은 없었습니다.
- 레포는 고치지 않았습니다.

### (1) 문서 실행 — 발견 넷

**D-1. core/05의 `Quad0109`·`Quad0087` 안내가 H-714 정정 전의 뒤집힌 서술로 남아 있습니다.**
- 상황: `docs/reference/core/05-observer-effect.md` 114행(Observer)과 239행(Effect)은 "콜백 안에서 만든 핸들을 숫자 키 자리에 놓는 경우는 `Quad0109`/`Quad0087`"이라고 적습니다.
- 재현(`r14d_p3.luau`·`r14d_p4.luau`): 다른 핸들의 콜백 안에서 새로 만든 Observer·Effect를 `D.Frame { inner }`에 놓으면 둘 다 에러 없이 통과합니다(`inner bind true`, `eff inner-created bind true`). 에러는 핸들이 자기 콜백 안에서 자기 자신을 놓을 때(`D.Frame { self }`)만 납니다. 출력은 `Quad0109 Observer: cannot bind an Observer from inside its own fn`과 `Quad0087 Effect: cannot bind an Effect from inside its own fn or cleanup`입니다.
- 입력 분류: 정의된 사용입니다.
- 이전 결정: round13 `H-714`(2026-09-27 E21)가 같은 반전을 `errors/04`에서만 고쳤습니다. 지금 errors/04 22행과 142행은 "새로 만든 핸들은 통과 … 예전 서술이 반대로 적혀 있었습니다"라고 적고 있고, core/05의 두 줄만 옛 서술 그대로입니다. 원장·감사 파일에서는 이 잔여를 찾지 못했습니다.
- 판정: (가) 문서와 코드의 불일치입니다. 고칠 쪽은 문서이고, 코드는 errors/04와 일치합니다.
- 처방: 결정 없이 고칠 수 있습니다(errors/04 문장을 옮기면 됩니다).
- 확신도: 높음.

**D-2. q.debug를 끈 채 Slot 순환을 만들었을 때의 결과를 core/01·SKILL.md·rules-and-invariants가 실제와 다르게 단정합니다.**
- 상황: 세 곳이 같은 결과를 적습니다.
  - core/01 203행: "꺼져 있으면 넣는 줄은 통과하고 그 트리의 다음 CRUD·해체가 스택 오버플로로 죽습니다"
  - `docs/skills/quad-ui-dev/SKILL.md` 598행: "the `Add` passes and the next CRUD dies in a stack overflow"
  - `references/rules-and-invariants.md` 37행: 같은 서술
- 재현(`r14d_p13`~`r14d_p15`, 자기 순환과 둘 순환 각각에 연산 열 가지 이상, `q.debug = false`):
  - `Add`·`Move`·`Swap`·`Replace`·`IndexOf`는 통과합니다.
  - `Remove`·`Clear`는 `Quad0163 Bookkeeping.releaseOwner: this element is not owned by this ownerKey`로 죽습니다.
  - `Extract`·`ExtractAll`·`Splice`만 `Brand.luau:122: stack overflow`로 죽습니다.
  - 마운트는 `Quad0160`으로 거부됩니다.
  - `q.dispose`는 `Quad0179`로 거부됩니다.
  - 이미 마운트된 Slot에 넣는 순환은 `Quad0172`로 막힙니다.
- 입력 분류: debug 검사가 꺼진 채 들어온 잘못된 입력입니다. 2026-10-01 사용자 결정으로 `Quad0173`이 debug 층으로 내려갔고(`expensive-checks.md` 3행 "2026-10-01 사용자"), 그 뒤의 부기 무결은 약속하지 않습니다. 사실상 정의되지 않은 동작입니다.
- 문서: core/06 167행과 errors/03 285행은 이미 "스택 오버플로나 내부 불변식 에러로 죽습니다(그 뒤의 부기 무결은 약속하지 않습니다)"로 적어 실제와 거의 맞습니다. 세 곳만 "다음 CRUD → 스택 오버플로"로 단정합니다.
- 판정: (나) UB의 결과를 확정된 사실처럼, 그것도 부정확하게 적었습니다.
- 처방: 결정 없이 고칠 수 있습니다(core/06 문구로 맞추고 관측 표시를 붙이면 됩니다).
- 확신도: 높음.

**D-3. GS 20이 "Tween 같은 프로바이더 브랜드도 문자 키에서 '숫자 키로 가라'는 안내를 받는다"고 적는데, Tween에는 틀린 안내입니다.**
- 상황: `docs/getting-started/20-handlers.md` 76~77행(이번 주에 추가된 괄호)이 이렇게 적습니다.
- 재현(`r14d_p17.luau`):
  - `D.Frame { Foo = q.Tween{…} }`는 `Quad0076 … (value: table, brand: Tween) - a quad value at a string key: it belongs in a numeric (array) slot`입니다.
  - 안내대로 숫자 키에 놓으면 `Quad0076 … key 1 … - this quad value has no handler at an array position`이 다시 납니다. Tween이 갈 자리는 프로퍼티 키인데, 안내가 막다른 곳으로 보냅니다.
- 입력 분류: 정의된 오용 진단입니다.
- 이전 결정: `noMatchMessage` 주석이 인용한 2026-10-01 사용자 결정은 "등록된 술어에 걸리면 주인이 설치된 것"까지입니다. 즉 "프로바이더 미설치" 꼬리를 고친 결정이고, 숫자 키로 보내는 안내를 승인한 것은 아닙니다. 같은 모양을 Context·Provider에서 고친 선례가 round13 E80입니다(주석 "the old hint sent it to a numeric slot, which raises Quad0076 again"). 브랜드별 안내를 각 브랜드가 등록하는 구조는 열린 **기존 Q161**이고, Tween은 그 문항의 새 사례입니다.
- 판정: 메시지는 API가 아니라(D3) 코드 결함은 아닙니다. 다만 문서가 틀린 안내를 일반 규칙처럼 서술합니다.
- 처방은 둘로 갈립니다.
  - GS 20의 Tween 괄호를 빼거나 바로잡는 것은 결정 없이 할 수 있습니다.
  - 메시지 자체는 Q161 결정을 기다립니다.
- 확신도: 중.

**D-4. "던진 Effect는 죽는다"가 계약인지 관측인지, 두 결정이 갈라져 있습니다.**
- 상황: 다음 문서들이 던진 뒤의 상태를 사실로 적습니다.
  - core/05 242행: "`fn`이 예외를 던지면 그 `Effect`는 죽습니다", 관측 표시 없음
  - core/05 109행: 첫 발화가 던지면 핸들이 수거될 때까지 콜백이 돌지 않음, 관측 표시 없음
  - errors/04 22·30·54행(Effect)과 142·150·174행(Observer): "`[2026-09-27 실측]` fn이 한 번 던졌거나 … 표시가 풀리지 않은 채 남으므로 … 이 에러가 납니다"
- 재현(`r14d_p3`, `r14d_p5`): 서술은 전부 맞습니다.
  - 던진 Effect는 재실행이 멈추고, 재구독은 `Quad0088`/`Quad0090`, `Unsubscribe`는 통과합니다.
  - 던진 Observer는 콜백이 계속 불리고(n=3), 재구독은 `Quad0113`, 묶기는 `Quad0109`입니다.
  - 첫 발화가 던진 Observer는 이후 돌지 않습니다.
- 입력 분류: 던진 뒤의 상태입니다.
- 이전 결정이 둘입니다.
  - `base/effect-plan.md` 547행: `H-160`(2026-08-28) 사용자 확정, *"한번 죽는게 나오면 Effect 가 전부 죽는다가 계약으로 상향되어도 문제는 없는듯"* — "계약으로 명문화".
  - `architecture.md` 예외 안전성 절(2026-10-02) 및 Q160 닫힘(10-04): 계약으로 두는 회복은 Observer 자가 치유 하나이고 "그 밖의 '던진 뒤' 서술은 전부 관측"이라고 적습니다.
  - 계약으로 두는 Effect 죽음(H-160)이 이 "그 밖"에 드는지, Observer 자가 치유에 "재구독은 굳는다"가 함께 계약인지가 어디에도 적혀 있지 않습니다. 레퍼런스 00-index의 규약상 errors/04의 날짜 태그는 "관측"으로 읽히므로, H-160과 반대로 읽히는 셈입니다. 원장과 감사 파일에 이 충돌은 없습니다(Q160·Q177과 이웃한 주제).
- 판정: 이전 결정 사이의 경계가 불명확합니다. 코드는 두 결정 어느 쪽과도 맞습니다.
- 처방: 사용자 결정이 필요합니다. 갈래는 둘입니다.
  - (a) H-160을 계약 목록에 명시하고, errors/04의 날짜 태그는 근거 표기로 바꿉니다.
  - (b) Effect 죽음도 관측으로 내리고, core/05 242행과 errors/04 여섯 줄에 관측 표시를 답니다.
  - Observer 재구독이 굳는 것에도 같은 질문이 따라옵니다.
- 확신도: 중.

### (1) 확인했고 문제 없음(약 150개 주장, 프로브 20개)

**core/02 Source**
- `:Set`은 같은 값도 리비전을 올리고 전파합니다.
- `:SetIfChanged`
  - 같은 값이면 무동작이고 리비전도 그대로이며 self를 돌려줍니다.
  - NaN은 늘 씁니다.
  - 같은 `__eq`면 같은 값으로 보고, 메타메서드가 다르면 씁니다.
  - Modifier 검사가 비교보다 먼저입니다(`Quad0181`).
  - Effect clamp 예제는 100입니다. `:Set`으로 쓰면 `Quad0263`입니다.
- `:SetAndDispose`
  - 예제 세 줄이 문서대로 동작합니다.
  - 같은 참조는 파괴하지 않고, None·nil은 건너뜁니다.
  - 숫자 옛 값은 쓰기 뒤 `Quad0180`입니다.
  - Debounce를 거친 경로는 `Quad0179`입니다.
  - Store 필드에서도 그대로 씁니다.
- `Emit`, `print` 출력, `Quad0182`.

**core/05 Observer/Effect**
- Observer 예제의 개수 1·1·2·3이 맞습니다.
- 에러: `Quad0104`(강·약 구독 둘 다), `Quad0235`/`0234`/`0231`, `Quad0116`/`0097`.
- 해제는 콜백 안에서도 됩니다.
- 첫 발화 throw 뒤 상태, 묶는 순간 재생에서 던진 뒤 `Quad0233`.
- 115행의 관측(안쪽 즉시 재호출, 무조건 되쓰기는 stack overflow).
- 111행: Source를 직접 보면 같은 리비전으로 다시 돌지 않습니다.
- Effect
  - 다이아몬드는 한 번 돌고, deps 중복은 합칩니다.
  - 에러: `0094`/`0095`/`0096`/`0086`.
  - cleanup 안 Set은 한 사이클로 끝나고, fn 안 Set은 한 번 더 돕니다.
  - `dying` 플래그가 네 자리에서 문서대로 옵니다.
  - `Quad0263` 뒤 죽고 `0090`입니다.
  - 첫 실행 안 `Rerun`, cleanup 안 이중 `Unsubscribe`(`Quad0093`), fn 안 해제 뒤 즉시 소진.
  - 게이트 유보 중에 만든 Effect는 한 번 더 돕니다.

**core/01·03 debug 층**
- 진단 줄 셋(Compute 안 Set, 새 세대 위 yield, Observer 되먹임)이 나오고, `SetIfChanged`가 같은 값이면 진단이 없습니다.
- 반영 프로퍼티 키에 놓인 Observer·Tag 경고는 같은 요소·키당 한 번입니다.
- debug 검사(`Quad0077`, `0083` 프로바이더 브랜드, `0143`, `0173`, `0220`)는 켰을 때만 돌고, 상시 갈래는 꺼져도 잡습니다(딕셔너리 `0143`, 메타테이블 값 `0083`).

**나머지 레퍼런스**
- core/06 `Quad0267`은 spec에 있어 그것으로 확인했습니다.
- core/07: Ref는 `0076`에 문자 키 꼬리, PreRef/PostRef는 `0137`.
- errors/03: Slot의 `0141` 폐기는 `0076 brand: Slot`, State에 담긴 Slot도 같습니다.
- `Quad0085`: 0, 2.5, -1.
- GS 02의 `Parent`, GS 12의 `false`, SKILL.md 표의 `Activated`/`Sise` 메시지.
- BrandPredicates: 미등록 `is*`는 무시하고, 미등록 브랜드는 프로바이더 꼬리, 등록하면 브랜드 이름이 실리고, debug off에서 `D.Frame(v)`는 통과합니다.
- `Quad0265`, `Quad0264`, Operator(Clamp 넘친 인자는 무시, `Band()` 정규화, 에러 우선순위, ±0).
- roblox/05: `q.Out` 메아리 0, 왕복, `OnChange`+`SetIfChanged` 우회, `:Set` 우회는 mock에서 C stack overflow(문서대로), `0223`/`0224`.
- roblox/06과 how-to 04: Dedup 드래그 카드(false면 트윈이 다시 생기고 true면 건너뜀).

**how-to·GS·SKILL.md 실행**
- how-to 02 §6: 권하지 않는 모양(동기 mock에서 `"a"` 한 번, `hellow`)과 권하는 모양(FocusLost 뒤 소비자 1회).
- how-to 09 조건부 모달 전체 실행: 재열기 시 옛 모달 파괴, 확인 시 자기 모달 파괴, 에러 없음.
- how-to 10 State 고르기 스니펫.
- SKILL.md: `Quad0176`, `Quad0149`, 체인 setter의 State 반응.

### (2) 에러 레퍼런스 "고치려면" 전수 분류

- 대상은 `docs/reference/errors/01`~`09`의 `### QuadNNNN` 264절입니다. 폐기 넷(0031·0141·0261·0262)은 "고치려면"이 없어 실제 대상은 260줄이고, 전부 한 줄짜리입니다.
- 원인을 고치는 법만 적은 (i)이 대부분입니다.

**(ii) — 던진 뒤 남는 상태와 그 정리·회수 절차가 섞인 것, 8건**

| ID | 위치 | 섞인 부분 | 비고 |
|---|---|---|---|
| Quad0023 | errors/02 47행 | "이 에러가 난 뒤 그 Instance는 반쯤 지어진 채 남습니다 … 호스트를 dispose하고 자식도 새로 만들어 처음부터" | Q177이 지목한 자리 |
| Quad0267 | errors/02 387행 | "그 부모의 부기는 멈춘 채 남습니다 — 그 부모는 새로 만드세요" | |
| Quad0124 | errors/01 191행 | "보통은 경계가 다음 세대에 돌아오면 회복됩니다" | Q160 관측화 대상 |
| Quad0184 | errors/01 263행 | "직전 계산이 던졌다면 상류 값을 고쳐 `:Set`하면 회복됩니다 — 단 …" | Q160과 연결, yield 관측 괄호도 이 줄 안 |
| Quad0167 | errors/03 230행 | "이미 이 에러가 났다면 … 이 Slot과 그 조상 Slot들은 계속 쓸 수 없습니다 … 호스트 Instance를 q.dispose … 버리고 새로 만드세요" | Q177의 `Quad0167` 계열 |
| Quad0086 | errors/04 15행 | "이 에러가 난 Effect는 … 멈춰 … 고친 뒤에는 새 Effect를 만드세요" | |
| Quad0263 | errors/04 294행 | "이 에러가 난 Effect는 … 멈추므로, 고친 뒤에는 새 Effect를 만드세요" | |
| Quad0002 | errors/05 23행 | "이 에러가 한 번 났으면 … 부분만 써진 채 남고 앞선 이름들이 잠기므로 … 인스턴스를 새로 만드는 편이 안전합니다" | 엔진 거부 관측 문장도 함께 |

**경계 사례 — 던진 핸들 재사용, 6건**
- 해당 줄: `Quad0087`(errors/04 23행), `0088`(31행), `0090`(55행), `0109`(143행), `0110`(151행), `0113`(175행).
- 공통 문장: "fn(콜백)이 던졌던 핸들이라면 다시 구독·바인딩할 수 없으니 새로 만드세요".
- 이 에러의 한 원인이 "앞서 던졌음"이라 그 갈래의 처방이 곧 던진 뒤의 정리입니다. 문장을 어디로 옮길지는 D-4 결정을 따릅니다.

**(i)로 둔 경계 사례**
- Quad0037: "이미 `:Set`한 값을 되돌리는 것은 지원하지 않습니다"는 의도한 연산이 없다는 안내입니다.
- Quad0156: owner가 quad 밖에서 파괴된 경우의 안내입니다.
- Quad0140·0164·0165·0169·0242: "파괴된 Slot은 되살릴 수 없습니다 — 새로"는 파괴된 값을 쓴 것이 원인이라 원인 처방입니다.
- Quad0029: dispose한 뒤 새로 만들라는 것은 이미 claim된 것이 원인이라 원인 처방입니다.
- Quad0071: 내부 버그 신고 안내입니다.

### (3) 내부자 표기 전수(대상은 `docs/` 원본 88파일, `docs/site/` 제외)

**H-nnn·roundNN·Qnnn: 0건**
- `round` 검색에 걸린 두 줄은 "랩어라운드"라는 낱말입니다(README 99행, quadnomicon/01 65행).

**괄호 날짜 태그 `[YYYY-MM-DD …]`: 196건(전부 본문)**

종류별 개수:
- 실측·관측류 110건: `[날짜 mock 실측]` 59, `[날짜 실측]` 27, `[날짜 mock 관측]` 9, `[… — 관측, 계약 아님]` 12, strict·mock·strict 2, 드래그 흉내 1
- 기준·날짜만 73건: `[날짜 기준]` 52, `[날짜 기준, 다음 릴리즈부터]` 7, `[날짜]` 14
- 이력 13건: 신설 5, 폐기 4, 정정 1, 재구성 1, 사용자 결정 2

실측·관측 태그를 붙은 문장으로 가르면 다음과 같습니다. 대부분 레퍼런스이고, GS·how-to에는 근거형 몇 개만 있습니다.

1. 관측(UB·던진 뒤) 문장에 붙고 본문에도 관측 표시가 있는 것, 18건 — 태그를 지워도 표시가 남습니다.
   - 00-index 15
   - core/05 111, 235
   - core/06 383, 392, 403, 405, 407, 623
   - core/07 70, 94, 123, 355
   - core/09 380
   - extend/02 252, 377, 382
   - sugar/06 95
2. 관측 표시가 태그 자체에만 있는 것, 10건 — 지우면 표시도 사라지므로 문장을 고쳐야 합니다.
   - core/06 104, 515
   - core/09 53
   - errors/02 47
   - errors/04 238, 262
   - errors/05 23
   - extend/01 245
   - roblox/06 250
   - sugar/06 107
   - 이 중 core/09 53, errors/04 238, extend/01 245, roblox/06 250은 사실상 근거형입니다(정의된 동작을 mock에서 관측했다는 뜻).
3. 관측(UB·던진 뒤) 문장인데 관측 표시가 없는 것, 13건 — D1 후보입니다.
   - core/03 80, core/07 254, sugar/02 66
   - core/06 402
   - errors/02 254
   - errors/03 230
   - errors/04 22, 30, 54, 142, 150, 174 (D-4)
   - roblox/03 155
4. 사실 확인 근거로 붙은 것, 약 69건 — 정의된 동작·타입 검사·순서 미정 확인입니다.
   - GS 01 43
   - how-to 01 309, how-to 04 173, how-to 06 134, how-to 09 132, how-to 10 70, 167, 256
   - core/01 34, 140
   - core/03 86, 216
   - core/04 55, 59, 159
   - core/05 37, 220(둘), 231, 236
   - core/06 132, 368, 381, 401, 465
   - core/07 93, 246, 256
   - core/08 130
   - core/09 223, 269
   - errors/01 103, 326
   - errors/02 39, 70
   - errors/03 140, 141, 173, 205, 278, 334
   - errors/04 22, 87, 126, 142, 191
   - errors/05 22, 30, 135, 215
   - errors/06 22
   - errors/07 104
   - extend/02 68, 98, 202, 371
   - roblox/03 242, 283, 287, 294
   - roblox/05 188
   - roblox/06 286
   - sugar/02 64, 68
   - sugar/03 40, 46, 100
   - sugar/06 97(둘)

기준·날짜만 태그 73건은 대부분 "게시된 3.2.0엔 없음" 같은 릴리즈 공지나 "미실측" 시한부 표기입니다.
- 관측 문장 안에 든 것은 5건입니다: core/07 70, errors/02 246, errors/07 94, extend/02 256, sugar/05 39.
- 나머지 68건의 위치는 다음과 같습니다.
  - README 43, 47, 48, 72, 117
  - GS 00 17, GS 06 11, 200, 205, GS 11 60, 262, GS 21 59
  - how-to 01 213, how-to 02 380, 382, how-to 04 93, 102, how-to 05 210, how-to 08 423, how-to 09 92, 134
  - overview/01 62, 336, 337, 339, overview/02 22, overview/03 24
  - quadnomicon/08 94, 201
  - core/01 196, 198, core/02 98, 142, core/05 240, core/06 34, 167, 404, core/07 62, core/10 166
  - errors/02 262, 278, 346, 386, errors/03 36, 229, 285, errors/04 293, errors/06 118, errors/07 54
  - extend/01 143, extend/02 129, 145, 220
  - roblox/02 209, 211, 226, 322, roblox/05 12, 94, 184, 188
  - sugar/02 59, sugar/03 109

이력 태그 13건:
- `docs/README.md` 44, 47, 54, 64, 81, 85, 94, 112
- GS 13 234(주석 안), errors/01 390, errors/03 22, errors/04 286, errors/06 54

**그 밖의 내부 표기**
- `docs/README.md`에 내부 검토 번호와 결정 표기가 남아 있습니다. 같은 파일 §3이 금지하는 것("내부 검토 번호는 적지 않고")입니다. 이 파일은 사이트에는 안 가지만 저장소에는 공개됩니다.
  - 72행 "사용자 결정", "docs-review 2-4"
  - 112행 "사용자 결정(docs-review 3-7)"
  - 66행 "2026-09-11 사용자 지적·mock 실측"
- GS 20 112행의 코드 주석 "(레퍼런스 typing-limits)"는 내부 문서 이름입니다.
- HTML 주석은 105개입니다.
  - 63개가 내부 스크래치·spec 파일 이름을 담습니다(`gs.refprobe.luau`, `quad-roblox/test/gs.flowingback.luau`, `spec.gs15scratch.luau` 등). README §3 규칙(주석에 내부 경로 금지)에 어긋납니다. 위치는 GS 02·05·06·07·08·09·11·12·13·14·16·18·19·20·21, how-to 01·02·07·08, overview/01, core/06, core/09입니다.
  - 9개는 규칙대로 "근거: … (저장소 내부 기록)" 꼴입니다.
  - 나머지는 날짜와 실측 메모입니다. how-to 08에는 "v1 소스 확인 2026-09-11 …"이 열네 개 몰려 있습니다.
  - `sync-docs.py`의 `strip_html_comments`가 한 줄 주석을 지우므로 사이트 사본에 남은 주석은 0개입니다. README §3의 "사이트 `.md.txt` 원문에 그대로 보인다"는 stale일 가능성이 있습니다(추정 — 빌드는 안 돌렸습니다).
- 태그 없이 본문에 쓴 측정 출처 표기는 약 25곳입니다.
  - "mock 확인"·"mock에서 … 흉내 내 확인": core/07 62, 70, roblox/02 226, 322, roblox/05 76, 184, sugar/05 39
  - "(실측: …)": how-to 02 306, 310, 314
  - "미실측": roblox/02 209, 211, 228, roblox/05 184, how-to 02 382, GS 06 205, errors/04 238, sugar/02 181, sugar/04 30
  - mock 동작 대조: sugar/03 97, sugar/04 30
  - "mock CLI" 수치: core/06 170
  - 헤드리스 테스트 주제로서의 mock(extend/01, how-to 06, GS 01 72·90, overview/01, agents/01, SKILL.md 29)은 독자용 개념이라 제외했습니다.
- 규약 쪽 사실 하나: `reference/00-index.md` 15행("관측과 계약" 절)과 `base/docs-handover-registry.md` 19행이 **날짜 태그 자체를 공개 "관측" 표시로 정의**하고 있습니다. 태그를 걷어내려면 위 2·3번 묶음(관측 표시를 태그에만 의존하거나 아예 없는 줄)부터 문장으로 "관측(계약 아님)"을 넣어야 합니다.

### 미완
- core/06의 `Quad0267`·Offset 고리는 roblox 스택에서 따로 재현하지 않았습니다(base spec `lengthoffset` round14 절로 갈음).
- 실측·관측 태그 분류는 문장 단위 휴리스틱에 손 보정을 더한 것이라, 근거형 69건 안에 관측형이 몇 개 더 섞였을 수 있습니다.
- GS 01~21과 how-to 03·05·07·08의 스니펫 중 이번 주 표면과 무관한 것은 실행하지 않았습니다.
- Roblox 엔진 쪽 서술(Deferred 시그널, 커서 위치)은 실기기 몫이라 다루지 않았습니다.
