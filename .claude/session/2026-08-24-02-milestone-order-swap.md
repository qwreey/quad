# 2026-08-24-02 — M2/M3 마일스톤 순서 교체 (반응형 먼저)

**요청**: *"질문절에 마일스톤 순서 이슈는 (a) M2와 M3의 순서를 바꾼다 를
택하는게 맞겠던데 어떻게 봐?"* → 검토 후 동의, *"진행해줘"*로 전량 반영.

## 1. 발단

2026-08-22 `ROADMAP.md` 전반 점검이 남긴 마지막 열린 항목. 옛 M2(디스패치
엔진)와 옛 M3(Store/State/Source)의 의존이 양방향이라 그 순서로는 M2를
끝까지 짤 수 없었다. 설계 결정이 아니라 **순서** 문제라 `question.md`의
최우선 절이 아니라 2번 항목으로 따로 뒀었다.

## 2. 검토 — (a)에 동의한 근거

사용자가 이미 (a)로 기울어 있었고, 확인 결과 방향은 맞았다. 근거 셋:

1. **의존의 비대칭이 명확하다.** 디스패치 → 반응형은 *본체* 의존이라
   우회 불가(`setLength`가 `State<number>`를, `setOffsetSource`가
   `Source<number>`를 받고 `recompute`가 `offset:Set()`을 부름). 반대는
   *등록 표면* 의존(핸들러 3개 등록)이라 뒤로 미루면 그만이다.
2. **옛 순서면 디스패치 마일스톤의 `mock 대상 테스트` 체크박스가 원리적으로
   불가능했다** — `setLength`/`recompute`를 State 없이 테스트할 수 없다.
   반대로 반응형 코어는 순수 Lua라 `luau`만으로 단독 테스트가 된다.
3. **2026-08-22의 `EpochMap`/`GateNode`/`Blocker` 앞당김이 불필요해진다.**
   그 이동은 "디스패치가 먼저인데 디스패치가 쟤들을 호출한다"는 이유였다.
   순서를 바꾸면 마일스톤 내용이 의존 계층과 그대로 일치하고 끌어온 항목이
   0개가 된다. "게이팅 먼저"도 그대로 지켜진다(게이팅이 디스패치보다 먼저).

**(b) 분할을 안 고른 이유**: 참조 비용이 오히려 크다 — 기존 `M2` 참조
전부가 "M2a인가 M2b인가"로 애매해지는데 순서 교체처럼 기계적으로 못 푼다.
`Brand`를 앞으로 빼는 일은 (b)에서도 똑같이 해야 하고, 얻는 건 "디스패치
코어를 조금 일찍 짠다"뿐인데 M4 전까지 그걸 소비하는 게 없다.
**(c) 유지를 안 고른 이유**: `project-context.md`가 못박은 "순서의 소스는
`ROADMAP.md`"를 스스로 무효화한다.

## 3. 그냥 맞바꾸기로는 안 끝났다 — 공통 기반 셋

검토 중 드러난 것. 옛 M2 안에 **반응형보다 먼저 와야 하는** 항목이 셋
섞여 있었고, State-free이자 dispatch-free라 어느 쪽에도 안 걸린다:

- `Brand.luau` — `Source`가 `SourceBrand`+`EpochBrand`에 등록돼야 함.
- `Relate.luau` — `bindLifetime`/`unbindLifetime`이 그 위에 구현됨.
- `LifetimeHandle.luau` 인터페이스 — State 전파 루프가 매 발화마다
  `canExecute`를, 이중 바인딩 게이트가 `canBound`를 부름.

새 M2 앞머리에 `### 공통 기반` 절을 만들어 셋을 옮겼다. 반대로 새 M3로
넘어간 것은 둘 — Observer/Effect **동적 경로 가드 등록**과
**`ObserverEffectLeafHandler`**(`H-39`). 결과적으로 역방향 간선이 없다.

## 4. 실행 중 낸 실수 하나 — 한글 인접 `M2`가 안 바뀌었다

첫 일괄 치환에 `re.sub(r'\bM([23])\b', ...)`를 썼는데, **Python `re`의
`\w`는 유니코드라 한글도 단어 문자**다. 그래서 `M2는`/`M2로`/`M2가`처럼
한글이 바로 뒤에 오는 경우 `\b`가 성립하지 않아 **155건만 바뀌고 93건이
그대로 남았다** — 코퍼스가 옛 번호와 새 번호가 섞인 상태가 됐다.

`git checkout -- .`은 하네스가 막아서(destructive) `git show HEAD:<경로>`로
26개 파일을 되돌린 뒤, ASCII 경계만 보는
`(?<![0-9A-Za-z_])M([23])(?![0-9A-Za-z_])`로 다시 돌려 **248건 전량**을
바꿨다. **교훈: 한국어 문서에서 `\b`로 영숫자 토큰 경계를 잡지 말 것.**

## 5. 부작용 — 게이트 둘이 "바로 다음"으로 올라왔다

순서 교체의 실질적 대가. `question.md`의 낮은 우선순위 절에 있던 둘이
반응형(옛 M3)의 게이트였는데, 반응형이 M2가 되면서 **착수 직전 항목**이
됐다 — 그래서 최우선 절로 승격했다:

- **중간 State GC 미검증** — 상류 strong / 하류 weak 불변식 명문화 여부 +
  `luau-test` 실측(`base/source-state-plan.md`).
- **`store:GetDynamic` 위치** — 콜론 메소드 vs 탑레벨 함수
  (`base/store-plan.md`).

순수한 *설계* 결정 대기는 여전히 0건이다(하나는 실측 미완, 하나는 표면
위치 선택).

## 6. 번호 재부여의 사각지대

라이브 문서의 `M2`/`M3` 참조는 전부 새 번호로 맞췄다 — 코퍼스의 참조가
거의 전부 "그 내용이 사는 마일스톤"을 가리켜서 기계적 맞교환으로 의미가
보존된다. 반면 **`session/`·`archive/`·`qa-request/`는 히스토리 문서라
소급 수정하지 않았다.** 2026-08-24 이전에 쓰인 그 문서들의 `M2`/`M3`는
옛 의미(M2=디스패치, M3=반응형)다 — 이 경고를 `ROADMAP.md` M2 배너,
루트 `CLAUDE.md`, `project-context.md`, `todos.md`, `archive/
question-resolved.md`에 같이 박아뒀다.

## 7. 반영 범위

실제로 diff에 남은 파일은 **25개 + 이 세션 로그**다(정확한 목록은
`git show --stat`이 소스 — 여기서 세지 않는다). 갈래만 적으면:

- `ROADMAP.md` — 두 절 재편 + 최상단 배너 + 흩어진 마일스톤 참조. diff의
  대부분이 여기다.
- `question.md` — 마일스톤 경계 항목 삭제·아카이브 이관, 3번→2번 재번호,
  최우선 절 재작성(두 항목 승격), 번호 재사용 경고.
- `archive/question-resolved.md` — 해소 기록 신설.
- `base/gate-plan.md`/`blocker-plan.md`/`debounce-throttle-plan.md`/
  `state-epoch-plan.md`/`source-state-plan.md` — 2026-08-22 앞당김 서술을
  되돌림 서술로. 뒤의 둘엔 "동적 경로 가드 등록은 M3" 캐비엇도 신설.
- `base/effect-plan.md` — 같은 캐비엇.
- `base/quad-types-plan.md` — "마일스톤마다 갱신" 규칙의 첫 적용 지점이
  M2가 된 것.
- `base/store-plan.md`/`attribute-plan.md`/`slot-plan.md`/
  `dispatch-core-plan.md`/`project-setup-plan.md`,
  `research/operator-sugar-plan.md`/`debug-tooling-plan.md`,
  `luau-test/STATUS.md` — 번호 참조 갱신.
- `research/pre-implementation-audit.md` — 번호 갱신 + 히스토리 블록 정정
  (8절 참고).
- 인덱스 레이어: `.claude/README.md`/`todos.md`/`project-context.md`/
  루트 `CLAUDE.md`/`HUMAN_TODO.md`.
- `session-summary.md` + 이 파일.

**⚠️ diff에 *안* 남은 파일이 있다는 게 오히려 중요하다.**
`base/relate-plan.md`·`base/lifecycle-pattern.md`·`luau-test/README.md`·
`luau-test/`의 스파이크 둘·`reference/slot-attach-decomposition.md`는
일괄 치환으로 한 번 바뀌었다가 감사 1라운드 수정으로 **HEAD와 글자 단위로
같아졌다**. 그 참조들이 가리키는 것(`Relate`/`LifetimeHandle`)이 구 M2에서
신 M2로 **두 번 옮겨져 번호가 우연히 보존**됐기 때문이다 — 즉 "치환하면
안 되는 자리"였고, 감사가 그걸 잡아 되돌린 결과 diff가 비었다.

## 8. 검증 — 감사 7라운드 수렴 후 `/code-review high`가 5건 더

`quad-doc-auditor` 루프는 라운드마다 각도를 바꿔 **7라운드에서 새 발견
0건으로 수렴**했다(라운드별 10→8→1→1→2→2→0, 총 24건 수정). 각도는
순서대로 — (1) 마일스톤 번호 정합성, (2) 인덱스 레이어와 이번에 새로 쓴
서술의 자기모순, (3) `base/` 본문의 선행관계 서술, (4) 완결성(열거),
(5) 구현 순서 시뮬레이션, (6) 관례 준수와 2차 stale, (7) 조사가 가장 적게
닿은 파일.

**가장 값이 컸던 건 5라운드(구현 순서 시뮬레이션)**다. 문서 정합성이
아니라 *"이 로드맵대로 실제로 코드를 짤 수 있는가"*를 물었더니, 새 M2에서
`Source`/`State`/`Store`가 `EpochMap.luau`보다 **앞에** 놓여 있는 게
드러났다 — State가 `valueEpochMap`/`emitEpochMap` 둘을 컴포지션하므로 그
순서로는 `State.luau`를 못 짠다. 같은 라운드가 **순서 교체의 전제 자체도
검증**했다(새 M2 전체를 디스패치 심볼로 훑어 "가드 등록 둘 말고는 없음"
확인).

**그리고 수렴 뒤 사용자가 돌린 `/code-review high`가 5건을 더 잡았고 전부
유효했다** — `conventions.md`의 *"`/code-review`는 감사자를 대체하지
않는다"*가 또 한 번 실측으로 재확인된 셈이다. 다섯 중 **넷이 "라벨은
치환됐는데 그 라벨을 설명하던 산문이 안 고쳐진" 종류**였고, 그중 둘
(아래 두 번째·세 번째)은 같은 뿌리 — `quad-types`의 "마일스톤마다 갱신"
규칙이 M3에 앵커된 채 첫 적용 지점만 M2로 옮겨간 것이다:

- **(HIGH)** M3의 `setLength` 항목이 여전히 *"필요한 `GateNode`/`Blocker`/
  `EpochMap`은 이제 **이 마일스톤에** 체크박스로 있다(위 세 항목)"*라고
  말하고 있었다 — 셋은 M2로 되돌아갔고, "위 세 항목"이 가리킬 대상이 M3에
  없으며, 15줄 위의 M3 배너가 정반대를 말한다. 핸드오버 체크리스트 2번
  ("배너를 달았으면 그 배너가 부정하는 문장을 같은 커밋에서 고쳤는지")의
  전형적 실패.
- **(MEDIUM)** `quad-types`의 "마일스톤마다 갱신" 규칙이 M3에 앵커돼 있는데
  **첫 적용 지점은 M2**가 됐다 — M2 구현자가 아직 안 나온 마일스톤을 앞으로
  참조해야 규칙을 알게 되는 구조. 규칙 요지를 M2 항목에도 적었다
  (`base/quad-types-plan.md`와 `ROADMAP.md` M2/M3 항목).
- **(MEDIUM)** 같은 뿌리의 다른 자리 — `.claude/README.md`의 `quad-types-plan.md`
  색인 행이 *"**M3(`Dispatch`)를 시작으로** M2/M6/M7/M8/M10에 체크박스가
  뿌려졌다"*로 치환돼 **나열 순서가 뒤집혔다**. M2가 먼저 지어지므로
  "M3를 시작으로 … M2"는 성립하지 않는다 — 서브시스템을 붙이는 모든
  마일스톤을 순서대로 적고 "계기는 `Dispatch`, 첫 적용은 M2"로 갈라 썼다.
- **(MEDIUM)** `research/pre-implementation-audit.md`의 **히스토리 블록**이
  기계 치환을 맞았다 — *"M1·M3(디스패치) 투자가 먼저 이뤄진 뒤에야
  검증되는 셈"*이라는 원래 우려가 새 번호에선 **문장 그대로 거짓**이 됐다
  (Store/State가 이제 디스패치보다 먼저다). `session/`·`archive/`·
  `qa-request/`는 소급 수정 대상에서 뺐는데 **`research/` 안의 명시적
  히스토리 블록은 그 방침에서 새어 있었다.**
- **(LOW)** M2로 옮겨온 `Brand.luau` 항목이 `isNone`을 자기 책임처럼 적고
  있었는데, `brand-plan.md`는 2026-08-18에 *"`Brand → None` 의존을 만들지
  않는다"*로 확정해뒀다 — 마일스톤이 갈리면서 처음 눈에 띈 잔재.

**교훈**: 기계 치환은 *토큰*을 바꾸지 *주장*을 바꾸지 않는다. 치환 대상이
많을수록 "그 토큰을 설명하던 산문"과 "히스토리 블록"을 따로 훑어야 한다.
