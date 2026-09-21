# 되돌아오는 흐름 — 엔진이 바꾼 값을 상태로 올리기: `OnChange`와 `Bind`

**상태**: research — 착수 안 함, 사용자 결정 대기(문항은 `question.md` 2절). **[2026-09-21 신설]**

**계기**: 문서 검토 합본 `research/docs-review-2026-09-14.md` 1-4("엔진이 바꾼 값을 받는 법"이 시작하기에 없다)를 닫으려다
사용자가 방향을 바꿨다 — *"howto 는 순서대로 안 볼 가능성이 있고, 그걸 how to 안에서 설명하는것 또한 특성에 안 맞아. 입력의
변경에 따라 무언가 처리하는건 흔한 작업이고, gemini 조사 또한 이게 반복된다, onchange 를 두어야하는 구조적 문제가 있다 했어.
bind 같은걸 제안했고 … 그 안에서 bind 부분과 onchange 를 묶는 문서를 만들어보는게 좋을수도 있어. 지금은 값을 흐르게 한다로
단방향 흐름은 보여줬지만 현실 세계에서 다시 위로 올라가야하는 흐름도 있으니까."* 같은 요청으로 루트의 외부 모델 초안 여덟
(`-ignoreme`)을 레포로 들였다 — 원문과 팩트체크는 `archive/surveys/2026-09-17-root-drafts/`, 흡수 계획은 이 문서 6절.

## 1. 문제 — 위로 올라가는 흐름이 문서에 없고, 있는 길은 매번 손으로 쓴다

시작하기는 값이 **내려가는** 흐름(원천 → 파이프 → 프로퍼티)만 가르친다. 04장은 이벤트로 상태를 바꾸는 것까지 보여 주고, 엔진이
스스로 바꾸는 프로퍼티(입력창의 `Text`, 스크롤의 `CanvasPosition`)를 상태로 들이는 길은 *"시작하기에서는 다루지 않으니 레퍼런스를
보라"*로 넘긴다(`docs/getting-started/04-reacting.md` 끝 문단). 그런데 how-to 02·03·04가 전부 그 길(`q.OnChange`)을 쓴다 — how-to는
순서대로 읽히지 않고, 개념을 가르치는 자리도 아니다.

있는 길은 하나뿐이다. `q.OnChange("Text", function(v) text:Set(v) end)`를 숫자 키 자리에 놓는 것 — 프로퍼티마다 같은 세 줄이
반복되고, 같은 값 걸러내기는 사용자 몫이라고 정본이 명시한다(`base/onchange-plan.md`). 외부 모델의 진단 *"이게 반복된다"*는
코드와 대조해 정확하다(`archive/surveys/2026-09-17-root-drafts/factcheck-2026-09-21.md` B (a)).

## 2. 이미 결정된 것 — 되돌아오는 흐름은 v2에서 한 번 논의됐다

`base/component-composition-plan.md` 2절·4절: v1은 `self "Text"` 링커 하나로 인스턴스 프로퍼티 변경을 컴포넌트 store로
**역방향 전파**했다(양방향 바인딩 — 자동 흡수 매직). v2는 이걸 갈랐다 — (1) 인스턴스 잡기는 `Ref`, (2) 값 흐름은 "Source 직접
전달". 그리고 4절의 사용자 확정: *"isenabled가 여러 조건에 영향 받으면 바로 문제가 생기는거지. 따라서 실제 사용은 제한적일듯.
callback을 쓰는게 일반적이여 보이긴 해. 타입으로도 편하기도 하고 디버깅도 편함"* → **React식 `value(State) + onChange(callback)`이
기본**. 같은 절이 문을 하나 열어 뒀다: *"런타임에 '이게 Source면 역방향 쓰기까지 걸고 싶다'처럼 구분하고 싶은 경우는 `isSource`류
판별자로."* 즉 기각된 건 **암묵적**(Source를 넘기면 저절로 되돌아오는) 양방향이고, **명시적으로 고른 값**이 되돌아오는 것은
열린 채였다. `Bind` 제안은 그 문 안에 있다 — 다만 새 표면이므로 사용자 결정이다.

선례(레포 밖 참조 `/code/Projects/quad-scratch/refs/`): Fusion(`dphfox/Fusion@2790f7b`, `src/Instances/`)은 `Out`과 `OnChange`
둘 다 별도 심볼로 두고(제안서 서술 맞음), Vide(`centau/vide@452060a:src/changed.luau`)는 `changed(property, callback)`을 배열부에
놓는 액션 — 제안서의 *"`Changed = function(rbx)`"* 서술은 모양이 틀렸고, 실제 Vide는 오히려 quad의 `OnChange("Text", fn)`과 같은
꼴이다. 두 라이브러리 다 양방향 단일 심볼은 없다.

## 3. 지금 quad에서 위로 올리는 길 셋 (사실)

1. **이벤트 → 상태**: `Activated = function() on:Set(not on:Get()) end` — 04장이 가르친다. 토글·버튼·슬라이더(직접 만든 것)는
   전부 이 길이다. 엔진이 프로퍼티를 스스로 바꾸는 GUI 요소는 사실 소수 — `TextBox.Text`/`CursorPosition`, `ScrollingFrame.CanvasPosition`,
   그리고 읽기 전용 `Absolute*`류(이건 되돌릴 게 없고 관측만).
2. **프로퍼티 변경 → 상태**: `q.OnChange(name, fn)`(quad-roblox, 숫자 키 자리). 초기 발화·`PropTypesRead` 타입은
   `docs/reference/roblox/05-onchange.md`가 소스. 되돌려 쓰는 관용구는 `fn = function(v) src:Set(v) end`.
3. **내려가는 쪽**: `Text = src`(Source 직접 바인딩 — 정상 경로, component-composition 5절). 2와 3을 같이 쓰면 왕복이 된다:
   사용자가 타이핑 → 엔진이 `Text` 변경 → (Deferred면 다음 재개점에) `OnChange` → `src:Set(text)` → Property 핸들러가 `inst.Text = text`
   (**같은 값**) → 엔진이 같은 값 대입에 변경 시그널을 내지 않아서 여기서 멈춘다. quad는 같은 값 `Set`도 아래로 통지하고 plain 쓰기는
   항상 쓰므로(`H-478`·Q33), 이 왕복이 끊기는 근거는 **엔진의 같은 값 재대입 무발화**뿐이다 — 그리고 그건 이미 실측됐다
   (`audit/studio-docs-2026-09-10.md` A절: `Visible = true`(현재값과 같음) 0회, 같은 값 재대입 추가 0회, `Changed`도 동일;
   `base/onchange-plan.md`의 `H-429` 확정 문단). 처음 쓸 땐 `todos.md`의 옛 "실기기 몫" 문구를 믿고 미확인으로 적었다가 감사자가 잡았다.
   시작하기에 되돌리기를 적을 때 이 한 줄("같은 값을 되쓰면 엔진이 시그널을 내지 않아 왕복이 멈춘다")이 들어가야 한다.

## 4. `Bind` 제안 검토 — 메인 판단이지 결정 아님

제안서(`archive/surveys/2026-09-17-root-drafts/proposal-two-way-binding-and-motion.md` Part 1)의 핵심 셋을 quad의 결정과 대조했다.

- **Deferred 핑퐁 방어** — 동기 플래그는 못 쓴다는 지적은 맞다(`H-291`: Deferred는 콜백 배달만 늦추고 `Connected` 전환은 동기).
  제안의 `lastSynced` 값 비교 가드는 엔진이 같은 값 재대입에 무발화라는 실측(3절)이 있으므로 **왕복을 끊는 데는 불필요**하다 —
  남는 쓸모는 포커스 권위(아래)와 결합해 "내가 방금 쓴 값이 돌아온 것"을 가르는 것뿐이고, 그것도 같은 값이면 시그널이 안 오니 없다.
- **포커스 권위**(타이핑 중엔 외부 `Text` 덮어쓰기 억제, `FocusLost`에 확정) — 커서 복원 마법을 안 부린다는 점에서 quad 결과
  맞다. 다만 이건 **`TextBox` 전용 정책**이라 범용 `Bind`의 옵션이지 본체가 아니다.
- **제안서의 "현재 보일러플레이트" 예시는 옛 모양**(`OnChange = { Text = fn }` 해시 키)이다 — 2026-09-03에 배열부로 뒤집혔다
  (`archive/onchange-hash-key-reversed.md`). 진짜 현재 관용구는 3절 2번.

모양은 갈래가 셋이고 어느 것도 기존 결정이 답을 주지 않는다:

- **(i) 숫자 키 자리 값** `q.Bind("Text", src, opts?)` — `OnChange`·`Tag`·생명주기 훅과 같은 자리 규칙("quad 값은 숫자 키 자리",
  `must be an array item` 가드가 지키는 것). 핸들러 하나가 내려 쓰기(`inst[k] = v`, 트윈 없음 — 입력 필드는 트윈하지 않는다)와
  올려 구독을 같이 한다. 대신 같은 인스턴스에 `Text = other`를 같이 쓰면 두 핸들러가 한 프로퍼티를 다투므로 규칙이 하나 필요하다
  (가장 단순한 건 "겹치면 에러").
- **(ii) 문자 키 값** `Text = q.Bind(src)` — 제안서의 모양. Property 핸들러보다 높은 우선순위의 `BindHandler`가 같은 키를 잡는다.
  자연스럽지만 **문자 키에 quad 값을 두는 첫 사례**라 위 자리 규칙과 그 가드·문서·스킬 서술을 전부 예외로 만들어야 한다.
- **(iii) 슈거 없이 관용구 문서화** — 3절 2번 세 줄을 "되돌리기 관용구"로 시작하기에 적는다. 반복은 남지만 새 표면이 없다.

옵션은 `CommitOn = "Change" | "FocusLost"`, 포커스 권위 켜기 정도인데 둘 다 `TextBox` 전용이라 (i)에서는 `q.Bind`가 아니라
`q.BindText`처럼 클래스 특화 슈거가 더 정직할 수도 있다 — 이름·범위는 사용자 결정. 메인 권고: **문서를 먼저 (iii)로 닫고**,
(i)를 후보로 사용자가 결정한다. (ii)는 자리 규칙을 깨는 값이 커서 권하지 않는다.

## 5. 문서 전략 — docs-review 1-4를 이 문서가 대체한다

사용자 요지대로 how-to는 자리가 아니다. 갈래: **(a)** 04장을 "반응하기 — 내려보내고 되돌리기"로 넓힌다(시작하기에서 가장 얇은
장이기도 하다): 이벤트로 올리기(있음) → `OnChange`로 올리기(3절 2번 관용구 + Deferred 왕복이 왜 안 도는지 한 줄) → 나중에 `Bind`가
생기면 그 절이 여기 붙는다. 번호를 안 밀고 `q.OnChange`가 04장의 이름을 얻는다. **(b)** 04 뒤에 새 장 "되돌아오는 흐름"을 넣고
05~20을 다시 민다(오늘 15장 신설로 한 번 밀었다). **(c)** 오버뷰에 개념 페이지 하나(순서 무관) + 04장에서 링크. 메인 권고 **(a)** —
04장의 얇음과 이 주제가 정확히 맞물리고, 되돌리기는 "반응하기"의 반쪽이라 같은 장이 자연스럽다.

## 6. 흡수 계획 — 루트 초안 여덟

원문은 `archive/surveys/2026-09-17-root-drafts/`(처음 만든 날짜 2026-09-17로 이름), 팩트체크는 같은 폴더 `factcheck-2026-09-21.md`.
판정 요약과 갈 곳:

| 초안 | 팩트체크 요지 | 갈 곳(권고) |
|---|---|---|
| `proposal-two-way-binding-and-motion` | Part 1 `Bind`: Deferred·포커스 논거 맞음, 현재 관용구 예시는 옛 모양, Vide 서술 모양 틀림. Part 2 `PresenceList`: `rawDetach → nativeExtract → Parent = nil`이라 퇴장 애니메이션에 못 쓴다는 코드 인용 맞음(`Slot/Raw.luau`·`EngineOps.luau`) | Part 1은 이 문서 4절. Part 2는 ROADMAP 백로그(방향 A 유저랜드 슈거가 코어 불변식을 안 건드려 권고) |
| `fine-grained-reactivity-analysis` | 포지셔닝 문서 — 실질 주장 전부 맞음(단일 패스 컴포넌트·Source/State/Observer 독립·`StoreBind` 1:1·push 무효화/pull 재계산). 과장 하나: "Zero-Allocation Steady State"(`emitDown`이 emit마다 스냅샷 테이블을 만든다 — 의존 간선이 무할당이라는 게 정확) | 오버뷰·README 문구 재료(고쳐서) |
| `quad-architectural-impressions` | 11개 주장 전부 소스·정본과 거의 축자 일치. 흠 하나: `D.Modifier.ClassName {…}`은 자리표시자 | Quadnomicon 재료로 거의 그대로 |
| `web-vs-quad-architecture` | Bookkeeping·Slot 서술 맞음. 틀림 하나: `ctx.Index`는 `number`(반응형은 `ctx.Offset`만) | 아래 (가) |
| `web-vs-quad-reactivity-and-glitch` | `bit32.bnot(-Revision)`·`EpochMap:Update`·`Get()` 루프 인용이 소스와 거의 축자 일치, 틀린 주장 없음. 끝 문장이 pull 트리거 차이를 뭉갬 | 아래 (가) |
| `web-vs-quad-lifecycle-and-dispatch` | `nativeClaim`/gcconn·Modifier 우선순위 맞음. `Handler` 타입 스니펫 틀림(`"any"` keyType 없음, `process` 4인자·익명 클로저 반환), Slot/Ref 핸들러는 quad-base 것 | 아래 (가), 스니펫 고친 뒤 |
| `web-vs-quad-advanced-concepts` | `Claim`/`D.Mapper`·`PreRef`/`PostRef`·`Fallback`/`Traceback` 맞음. 과장 하나: plain `Ref`는 별도 3단계가 아니라 높은 우선순위의 보통 배열 자리 핸들러 | 아래 (가) |
| `web-vs-quad-benchmarking-and-patterns` | `Fallback`·`Operator`·`Context`·`rawDetach` 맞음. 틀림 셋: `q.Gate()` 없음(`state:Gate(setup)`만), `q.Debounce(source, delay)` 시그니처 틀림(`Debounce{ Time }` + `:Apply`), `OnChange` 해시 키 예시는 옛 모양 | 아래 (가), 셋 고친 뒤 |

(가) web-vs-quad 다섯은 대부분 Quadnomicon 01·02·07·08·09가 이미 다루는 내용의 웹 개발자 시점 재서술이다. 갈래: **(a)** 오버뷰에
"웹에서 오셨다면" 한 페이지(랜딩의 "React를 쓰다 오셨다면" 절과 짝, 위 오류를 고친 대조표 중심) **(b)** Quadnomicon 권 하나
**(c)** 안 가져오고 archive만. 메인 권고 **(a)** — 내부 구조는 Quadnomicon이 이미 있고, 부족한 건 웹 용어로 진입하는 문이다.

루트의 `test-ignoreme.luau`는 사용자 메모다 — *"D 에 대해선 이전 gen 을 사용하는 static declaration 형태의 바리에이션 패키지가
가능할것 같음. quad-roblox 는 범용 타입함수를 가지고, 타입 함수로 처리에 실패하는 곳에 대해서 static declaration 패키지가
있고(global 을 구워서 타입으로 줌)"*. ROADMAP의 type function 백로그 항목에 이 구상을 붙였다(파일은 안 옮긴다).

## 7. 정해야 할 것 (→ `question.md` 2절)

1. ~~3절 실측을 지금 돌릴지~~ — **닫힘**: 이미 2026-09-10에 실측돼 있었다(감사자 발견, 3절 정정). 문항 아님.
2. `Bind` 채택 여부와 모양 (i)/(ii)/(iii) — 권고: 문서는 (iii)로 먼저, (i)는 후보로 두고 사용자 결정.
3. 문서 위치 (a) 04장 확장 / (b) 새 장 / (c) 오버뷰 페이지 — 권고 (a).
4. web-vs-quad 다섯의 흡수 (a) 오버뷰 페이지 / (b) Quadnomicon / (c) archive만 — 권고 (a).
5. 루트 `-ignoreme` 원본 여덟은 archive 사본이 생겼으니 사용자가 지울지(에이전트는 사용자 파일을 지우지 않는다).
