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
2. ~~`Bind` 채택 여부와 모양~~ — **[2026-09-21 밤 사용자 결정 — 모양 확정, 이름은 탐사 뒤]** 순수 슈거로, **in 하나·out 하나를 명시적으로 나란히**:
   ```luau
   TextBox {
       Text = textSrc,          -- in: 상태 → 프로퍼티 (있던 길)
       Bind("Text", textSrc),   -- out: 프로퍼티 → 상태 (OnChange 위에 얹는 슈거, 같은 값 걸러내기까지)
   }
   ```
   사용자: *"순수 슈거로 만들고 싶음. 명시적으로 out 으로 나가는 부분 하나, in 으로 들어가는 부분 하나 … 이러면 OnChange 위에
   얹어지는 슈거가 되고 diff 까지 가능. inout 은 in 에 out 을 얹는다 구조가 가장 이롭고 구현이 쉽고, 핸들러 둘이 분기로 돌아간다가
   바로 보이는 부분이라고 생각함. Bind 는 이름을 대신 Out 으로 하든, 어떤게 좋은지는 sonnet 으로 더 탐사해보아야한다고 생각함.
   모양과 구조가 우리 컨벤션에서 나올 수 있는건 이게 최선이라고 생각함. 유의점은 compute 해서 in 을 넣으면 안 된다는건데, 그걸
   캐비엇으로 남기더라도 명확함의 이점이 더 큰것 같음."* 즉 4절의 (i)에서 "핸들러 하나가 둘 다"를 뺀 꼴 — 내려 쓰기는 Property
   핸들러 그대로, 새 값은 `OnChange` 디스크립터를 만드는 팩토리일 뿐이라 핸들러도 브랜드도 새로 생기지 않는다. 캐비엇: in 자리에
   파생 State(`:Compute` 결과)를 넣으면 out이 되쓸 곳이 없다 — 타입은 `Source<T>`를 받게 해 strict에서 막고, 문서에 한 줄.
   **이름 `Out` — 사용자 *"Out 권고대로 가면 될것 같아"*(같은 날 밤). 구현 완료**: `q.Out(name, src)`(`Handlers/OnChange.luau` 팩토리, `RobloxExtension.Out`, 타입은 전체형 `Source<…>` — 마커+`Set` 교집합은 신 솔버가 거부, `typing-limits.md` 8.25), 스펙 `spec.events` 4b·`spec.onchangetypes`, 레퍼런스 roblox/05·01, CHANGELOG Added, 정본 `onchange-plan.md` 끝 절.
3. ~~문서 위치~~ — **닫힘(사용자, 9절 탐사 뒤)**: 분리, 자리는 **05 뒤** — *"5 뒤로, 다만 반응하기 위에서 있는게 … 흐름 상 맞지만, tag/attr 도 아래로 내려보냄을 보여주는 부분이라 괜찮다 봐"*. 새 `06-flowing-back.md`(다시 위로 올려보내기 — `q.Out`), 06~20 → 07~21 재번호, 05장은 `tag:Added(if … else nil)` 관용구·그룹 `q.Attr`의 State·전환 문장까지(sonnet 작성·mock `gs.flowingback.luau`, 메인 대조).
4. ~~web-vs-quad 다섯의 흡수~~ — **닫힘(사용자 *"권고대로. 해당 부분은 어디서 온 사람이 보기 좋게 포장해주는 그런건데 심층 문서에 갈 이유가 없고, 안 붙여놓을 이유도 없음"*)**: 오버뷰 `03-from-the-web.md`("웹에서 오셨다면" — 대응표 + fine-grained 설명 + 없는 것·다른 것, 팩트체크에서 틀린 주장은 고쳐서; sonnet 작성·메인 대조).
5. ~~루트 `-ignoreme` 원본 여덟~~ — **닫힘(사용자 *"지워도 돼"* — sonnet이 archive 사본 바이트 동일·흡수 경로·잔여 참조 없음을 확인한 뒤 아홉 파일(`test-ignoreme.luau` 포함) 삭제, 2026-09-21 밤)**.

## 8. 이름·걸러내기 탐사 (2026-09-21 밤, sonnet 둘 — 원문 `archive/surveys/2026-09-21-writeback-naming-exploration.md`)

두 각도가 **같은 답으로 수렴했다 — `Out`**. 외부자(Fusion/Vide를 써 본 Roblox 개발자 시점): `Bind`는 WPF/Avalonia의 `Binding`처럼
양방향이거나 모드가 있는 일반 명사라, 같은 테이블에 `Text = textSrc` 줄이 있는데 아래에 `Bind("Text", textSrc)`가 또 있으면 "한 줄이면
양방향이 다 되고 위 줄은 필요 없어지는 게 아닌가"라는 **실제 동작과 반대되는 멘탈 모델**을 첫눈에 심는다 — 다른 후보의 단순한 낯섦과는
질이 다른 문제. `Out`은 "이 값이 인스턴스 밖으로 나온다"가 단어에 있어 위 줄과 다른 일임이 바로 읽히고, Fusion의 `Out`이 하는 일(프로퍼티가
바뀔 때마다 미리 준 값 객체에 `:set`)과 뜻이 정확히 같아 전이 학습이 된다. 구조 차이(Fusion은 해시 키 특수 심볼, 여기는 배열부 값)는
`02-d.md`를 한 번 훑으면 풀리는 얕은 마찰. `Sync`는 `Bind`보다 더 양방향처럼 들리고, `Writeback`은 동작이 그대로 드러나 2순위,
`OnChangeSet`은 `q.OnChange`와 겹쳐 보여 남매인지 대체인지 헷갈린다. 이름이 "OnChange 기반"임을 담을 필요는 없다 — 슈거는 결과만 말하는
편이 오래간다.

내부자(코퍼스 규약·충돌 실측): `Bind`는 quad-base 110건·quad-roblox 13건이 매치되는데 양보다 **뜻**이 문제 — `bindLifetime`/`unbindLifetime`
(값의 GC 수명을 Instance에 묶는 핵심 계약, `lifecycle-pattern.md`)·`BindData`가 이미 전혀 다른 의미로 코드 전역에 박혀 있어, `question.md` 1절이
경계하는 "다른 뜻으로 이미 쓰이는 단어" 패턴 그대로다. `Out`은 `FieldOut<T>`(Modifier `Peek`의 "저장된 그대로" 타입)와만 스치고 오히려 어감이
어울린다. `Sync`는 `EpochMap:Sync`, `Into`는 `Into<Frame>` 타입 패턴과 겹친다. `On*` 관례(숫자 키 자리 팩토리)로는 `On*`도 후보지만 `OnChangeSet`류는
"OnChange의 옵션 변형"으로 오독될 약한 위험. **메인 보충**: `On*`는 이 코퍼스에서 콜백·훅을 받는 팩토리(`OnChange`·`OnCreated`류)에 붙고, 콜백
없는 배열부 값(`Tag`·`Attr`·`PreRef`·`PostRef`)은 맨 파스칼이다 — `Out`은 콜백을 안 받으니 `Tag`·`Attr` 부류가 맞다.

**타입**: `Source<T> = State<T> & { Set, Emit, Revision }`라 시그니처를 `<K>(name: K & keyof<PropTypesRead>, src: Source<index<PropTypesRead, K>>) ->
OnChangeDescriptor<K>`로 두면 `:Compute` 결과(`State<U>`, `Set` 없음)는 strict에서 구조적으로 거부된다 — 마커·브랜드 불필요, `OnChangeFn`·
`PropTypesRead`(전역 단일 타입)를 그대로 재사용하므로 gen-d도 안 건드린다. **[구현 실측]** 8.11 규칙대로 마커+`{ read Set }`로 받으려던 첫 시도는 신 솔버가
왼쪽 교집합을 조각마다 대조해 양성까지 거부 — 전체형 `Source<…>`만 통과·음성 거부·값 타입 검사 셋을 다 한다(`typing-limits.md` 8.25, `type-surface: allow` 예외 첫 사례). 사용자 캐비엇("compute 해서 in 을 넣으면 안 된다")은 타입이 먼저
막고 문서가 한 줄 보탠다.

**걸러내기의 뜻 — 넣는 게 맞다, 그리고 루프 방지가 아니라 echo 방지다.** 엔진이 같은 값 재대입에 시그널을 안 쏘므로 루프는 저절로 끊긴다.
그런데 초기 바인딩에 구체적 echo가 있다: 배열부(`Out`의 `OnChange` 연결)가 해시부(`Text = textSrc` 대입)보다 먼저 돌고(`onchange-plan.md` 순서
계약), 그 뒤 해시부 대입이 엔진 기본값과 다르면 시그널이 쏘여 이미 연결된 콜백이 그 값으로 돈다 → 콜백이 무조건 `src:Set(v)`하면 `Source:Set`은
같은 값도 항상 emit(`H-68`)이라 **그 Source의 모든 구독자가 초기 바인딩마다 한 번 더 헛돈다**. `if v ~= src:Get() then src:Set(v) end`가 정확히
이걸 막고(콜백 시점에 `src`는 자기가 흘린 값을 들고 있다), 바깥에서 진짜 바뀐 값만 `Set`한다. `src:Get()`은 단순 필드 읽기라 콜백 안에서 안전
(quad엔 앰비언트 의존성 추적이 없다). 포커스·타이핑 정책은 값 동등성과 다른 범주라 슈거에 넣지 않는다(외부자: "논의 없이 슬쩍 들어오면 가장
우려스럽다").

**구현(사실)**: quad-roblox에 함수 하나 — `OnChange(name, function(v) if v ~= src:Get() then src:Set(v) end end)`를 돌려준다. 새 브랜드·핸들러·
`Dispatch` 변경 없음, `Handlers/OnChange.luau` 무변경. 이름은 사용자 결정(→ 7절 2번).

## 9. 문서 위치 탐사 (2026-09-21 밤, sonnet 외부자 — 원문 `archive/surveys/2026-09-21-upward-chapter-placement.md`)

사용자 선호(*"분리되어, 다시 위로 올려보내기 섹션을 만드는게 더 보기 좋다 … 두 맥락 섞지 말고, 하나하나 가르치는게 덜 혼란"*)는 알리지 않고
(A) 04장 확장 / (B) 04 뒤 새 장을 중립으로 물었다. 외부자 판정 **(B) 분리**. 근거 셋: (1) 이벤트(`Activated`)는 **문자 키**에 이름으로 적는
콜백이고, `q.Out`/`q.OnChange`는 **숫자 키**에 이름 없이 놓는 디스크립터 — 레퍼런스 스스로 `Tag`·생명주기 훅 부류로 분류한다. "숫자 키 자리에
자식이 아닌 값도 온다"는 문법은 05장 도입부가 처음 여는 개념이라, 04장에 섞으면 문자 키/숫자 키라는 이 언어의 더 근본적인 구분선을 한 장 안에서
교차시키는 꼴. (2) 04장이 얇은 건 결함이 아니라 "버튼 하나로 카운터 완결"이라는 짧고 강한 성취점을 주려는 설계 — (A)는 제목까지 바꿔야 해서
사실상 새 장을 만드는 것과 같은 개편이고 그 완결감을 다음 화제(왕복·echo 방지)로 덮는다. 이 튜토리얼은 분량이 아니라 개념 경계로 장을 자른다
(06 Ref·09 Modifier·14 Context·15 Store·17 Blocker — 08 생명주기 훅은 순수 슈거인데도 독립 장). (3) "함수 하나짜리 장" 걱정은 없다 — 숫자 키
디스크립터 문법, `OnChange` 위의 `Out`이라는 관계, 읽기 표면(`PropTypesRead`), 왕복이 루프가 안 되는 이유와 echo 방지까지 작은 장 하나 분량.
중립 사실 하나: 자라는 카운터 예제엔 엔진이 되돌려 쓸 프로퍼티가 없어 어느 갈래든 TextBox 하나를 데모용으로 끼워야 한다.

**덧붙인 관찰 — 위치는 04 바로 뒤보다 05(Tag·Attr) 뒤가 낫다**: 04 뒤에 두면 독자는 아직 "숫자 키에 값을 놓는다"를 모르는 채 `q.Out`을 만나고,
05 뒤에 두면 Tag·Attr 다음의 자연스러운 다음 걸음으로 받아들인다. 사용자 결정 대기: 분리는 합의됐고, **자리(04 뒤 / 05 뒤)** 와 장 제목·예제.

