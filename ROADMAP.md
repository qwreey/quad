# ROADMAP.md

quad-v2 구현 단계 실행 계획. 설계 근거/아키텍처 자체는 여기 안 옮겨적음 —
`.claude/base/`가 소스, 여긴 **순서와 진행 상황**만. 마일스톤 시작할 때
체크박스를 세분화해서 늘려도 되고, 끝나면 체크만 하면 됨 — 살아있는 문서.

**2026-08-04 세션에 준비만 해둔 상태로 신설, 이후 여러 세션에 걸쳐 설계가
확정될 때마다 각 마일스톤 체크박스가 계속 갱신돼왔음.**

> **✅ [2026-08-24 기준] M0/M1의 *원래* 체크박스는 전부 닫혔고 다음은
> M2(반응형 코어)** — 단 M0에는 **[2026-08-22] "재검증 대기" 미체크
> 항목들이 새로 붙었습니다**(설계가 바뀌어 무효화된 스파이크들, 아래 그
> 절이 소스). 그건 아직 열린 작업이므로 "M0 완료"로 읽고 넘어가면 안 됩니다.
> **[2026-08-24] 착수를 막던 마일스톤 순서 문제는 해소됐습니다** — M2와
> M3의 번호를 맞바꿔 반응형을 먼저 짓기로 확정했습니다(아래 M2 배너가
> 소스). **⭐ [2026-08-25] 그 교체로 올라왔던 항목 둘도 닫혔습니다** —
> 중간 State GC는 `_hold` 불변식(하류 → 상류 강함)으로, 동적 키 표면
> 위치는 `store:Of<<T>>(name)` 하나로(옛 `GetDynamic` 흡수) + 예약 키
> 충돌은 예약 키 진단 타입 함수로. `.claude/question.md`
> 최우선 절은 지금 **비어 있습니다**. 결정 전량의 소스는
> `.claude/qa-request/pre-implementation-handtrace-round7-followup.md`,
> 그리고 **[2026-08-26] 8라운드 몫은 `-round8-followup.md`**(7라운드
> 반영분을 겹쳐 재트레이싱한 발견 17건 — 역전 없이 누락·충돌만 닫았습니다.
> **[2026-08-27] 9라운드 몫은 `-round9-followup.md`** — Q1~Q3(`recompute` 되감기
> 순서 / Slot 생성자의 `Offset`·`_baseObserver`·`_destroyed` / `bk.indexOfElement`로
> 토큰 폐기)에 이어 같은 날 Q4~Q10·`H-138`·`H-139`·`H-142`까지 **전량**
> 반영됐습니다(`EffectHandle` 진입점 / M2에 `Ref` 최소형 / `InstanceChildHandler`
> 부기 / `reconcile` 배치 Blocker / `New`·`drive` 파이프라인 / props `Parent` 금지),
> 그 반영분에 `/code-review`가 낸 `H-143`~`H-146`(`Rerun` 꼬리 실행 중 사망이면 즉시
> 소진 / 재구독 꼬리 + 진입점은 `EffectHandle` 자기 것 / `bk.indexOfElement`
> weak-key / 루트 부착은 사용자 몫)도 같은 날 확정·반영. **[2026-08-28] 10라운드**
> (`-round10-followup.md`가 소스) — 그중 둘은 하루 만에 다시 뒤집혔다: `fn`/cleanup은
> 자기 구독을 못 바꾼다(`H-147`, `H-143` 소멸 · `rawRerun(force)`/`Rerun` 분리) /
> 이미 있는 트리는 **quad가 `Claim`으로 소유**(`H-148`, `base/claim-plan.md`,
> **M5 스코프** — `H-161`; 같은 날 갈래까지 전량 확정 — 그 과정에서 **루트의
> `.Parent =`는 밖에서 허용으로 복원**, 요지는 M5 `Claim` 체크박스; `/code-review`가
> 낸 M5 착수 전 문항 넷도 같은 날 확정 — 그 문서 §7-9~12). 그 밖에 `_epochs`는 emit 때만 갱신
> (`Refresh` 캐치업 폐기, `H-151`) / `Effect._blocker` 제거(`H-150`) / Observer
> 진입점 인라인(`H-149`) / `GateNode` 브랜드 등록(`H-152`) / Store 예약 이름
> 런타임 가드(`H-153`) / `InstanceChildHandler` dedup(`H-154`).
> **어느 체크박스가 바뀌었는지는 여기서 세지 않습니다** — 해당 체크박스에
> 각각 `H-1xx` 표시가 붙어 있으니 그게 소스입니다. M2/M3 양쪽에 걸쳐
> 있습니다). M1까지의 산출물은
> quad-base/quad-roblox 폴더+pesde.toml, 루트
> default.project.json/.luaurc, mock 테스트 하네스, `New()`/`RunInit`/
> `AddPlugin` 골격. **다만 M0의 검증 스파이크 여러 개가 설계 변경으로
> 재작성 대기 상태입니다** — 아래 "재검증 대기" 절 참고(개수·현황의
> 소스는 `.claude/luau-test/STATUS.md`, 여기서도 그 절에서도 세지 않음).
>
> **[2026-08-24] 이 문서에 이번에 반영된 것**: M2(반응형)와 M3(디스패치)의
> **번호·순서 교체**, 그에 따라 `Brand`/`Relate`/`LifetimeHandle`
> 인터페이스가 M2 앞머리로 이동하고 `EpochMap`/`GateNode`/`Blocker`가 M2로
> 복귀, Observer/Effect 동적 경로 가드 등록과 `ObserverEffectLeafHandler`가
> M3로 이동.
>
> **[2026-08-22] 그 전 회차에 반영된 것**: `Dispatch.drive`가 두 패스가
> 아니라 단일 일반화 `for`(`F-4-1`) / 물리 조작 주입 op 이름이 `native*`로
> 확정 / `None`이 M7에서 디스패치로 이동 / `[x]` 표기 의미 분리
> (바로 아래).
>
> **⚠️ `[x]`의 의미** — 체크박스는 **"짜야 할 코드"만** 담습니다.
> "설계가 확정됐다"/"타입을 실측해봤다"는 사실은 체크박스가 아니라 각
> 마일스톤의 **`### 확정된 것`** 절(항목이 여럿일 때) 또는
> **`- **[확정된 것 — 코드 아님]**`** 불릿(하나뿐일 때)에 둡니다. 예전엔
> 둘이 같은 목록에 섞여 있어 `[x]`만 보고는 코드가 있는지 알 수
> 없었습니다 — M0/M1의 `[x]`는 실제 구현이고, M2/M6/M11에 섞여 있던
> `[x]`는 설계 확정·실측이었습니다. **새 항목을 추가할 때도 이 구분을
> 지킬 것.**

> M1 착수 도중
> wally→pesde 전환이 확정돼(`base/project-setup-plan.md`) M1 체크박스의
> `wally.toml` 표기도 `pesde.toml`로 정정. 부수로 M2가 의존하는
> `quad-types`/`type-version-check` 두 워크스페이스 멤버도 이 과정에서
> 먼저 신설됨(`base/quad-types-plan.md`).

> **✅ [2026-08-13 열네 번째 세션] M0 착수를 막던 결정이 전부 해소됐음.**
> `0-Y`(13차 세션), `0-Z`(Attribute 이름 소유권)/`0-A`(재디스패치 하강
> diff, 둘 다 14차 세션) 확정·반영 완료 — `.claude/question.md`의 최우선
> 칸이 비었습니다.
>
> **다만 M0 착수 전에 반드시 읽을 구현 규약 두 개**:
> `.claude/base/typing-limits.md`(0-Y의 산물 — 파생 State마다 결과 타입을
> 명시 주석으로 바인딩)와 `.claude/base/dispatch-core-plan.md`(0-A/0-Z의
> 산물 — 하강 diff 재디스패치, 3-인자 `retractFrom`, Handler 작성
> 체크리스트 8개, `HANDLER_PRIORITY_FALLBACK`, 주입되는 엔진 op).
> (특히 "파생 State를 만드는 자리마다 결과 타입을 명시 주석으로 바인딩"과
> 7번 체크리스트).

## M0 — 스켈레톤 + 기술검증 (스파이크, "진짜" 마일스톤 아님)

최종 소스 트리를 그대로 만들기 전에, 지금까지 **추론만으로 확정하고 실제
Luau 코드로 부딪혀본 적 없는 세 가지**를 던지는 코드로 검증하는 단계 —
`.claude/base/` 감사에서 나온 결론(2026-08-04). 여기서 뭔가 어긋나면
`architecture.md`/`bind-system-plan.md` 등을 이 시점에 고치는 게 정상 —
실패가 아니라 이 단계의 목적.

- [x] Store/State push-invalidate → pull-recompute propagation을 실제로
      짜보기(다이아몬드 의존성 케이스 포함 — **[2026-08-14 정정]** 확인할
      것은 "이미 invalid면 전파 중단되는지"가 **아니라** 그 반대:
      **emit은 자기 invalid 상태와 무관하게 전파되고**, 중복 재계산은
      `:Get()` 시점 캐시로만 막히는지(**[2026-08-21]** 그 뒤 "항상"에서
      "같은 `Epoch`의 같은 리비전이 두 번째로 도착했을 때만 접힘"으로 좁혀졌다 — 아래 참고). 특히 `:Get()`을 안 부르는
      `Observer`가 매 변경마다 계속 울리는지 — 옛 모델에선 두 번째부터
      침묵했음(`archive/invalidate-dedup-propagation-reversed.md`).
      스파이크 `05-store-state-diamond-propagation.luau`는 **[2026-08-19
      재작성 완료]** 그 모델("emit은 항상 전파 + `:Get()` 시점 캐시로만
      dedup")로 재검증 통과 — **[2026-08-21] 그 모델이 다시 바뀌어
      `rewrite-required/`로 되돌아갔다**(`Epoch` 리비전 비교 채택으로 다이아몬드
      Observer가 이제 변경당 **1회**만 울어야 함, `base/state-epoch-plan.md`))
- [x] Source가 State를 구조적으로 만족하는 제네릭 타입(`:Compute<U>(self:
      Source<T>, ...) -> State<U>`류, self 타이핑 + State 참조 혼합)이
      Luau 솔버에서 안전하게 추론되는지 확인(2026-08-06 세 번째 세션,
      `base/source-state-plan.md` "Source가 State를 만족함" 절 — `State<T>`가
      `Source`를 참조하지 않는 단방향 의존으로 두면 위험한 상호 재귀는
      피할 수 있어 보이나 실제 검증 전엔 확정 아님. **[통과]**
      `luau-test/done/08-type-source-satisfies-state.luau` — 핵심 케이스
      통과, 잔여 자기재귀 케이스는 Luau 한계로 별도 확정
      (`base/typing-limits.md`), 설계 영향 없음)
- [x] `process`(+반환 retractor 클로저) 재귀 재-process 디스패치를 실제로
      짜보기(store-bind 핸들러 하나 + `isHandlable` 우선순위 스캔 포함 —
      `luau-test/done/03-recursive-store-bind-dispatch.luau` 통과)
- [x] props 순회의 "배열 파트 먼저, 해시 파트 나중" **계약**이 실제
      Luau 테이블에서 관찰한 대로 동작하는지 확인, `PreRef` pre-pass +
      일반 `Ref`의 위치 기반 순서까지 최소 스파이크로 검증
      (**[2026-08-21 정정]** 이 계약을 **두 패스로 구현**한다는 서술은
      `F-4-1`로 폐기 — 구현은 단일 일반화 `for`, 계약은 그대로. 그래서
      두 루프로 짜인 스파이크 `01`이 `rewrite-required/`로 갔다 — 아래
      "재검증 대기" 참고)
      (2026-08-07 세 번째 세션, `base/ref-plan.md` "`phase` 옵션
      폐기 → 위치로 표현, `PreRef` 신설" 절) — **PreRef pre-pass의 소진은
      `nil`이 아니라 실재하는 센티널로(2026-08-07 열 번째 세션 정정, 사용자가
      Luau REPL로 반례 제시 — 키가 듬성듬성해지면 순회가 index 순서를
      전혀 안 지킴), 이 경로는 nil-hole 위험이 아예 없도록 설계됐으므로
      "구멍 있는 테이블 순회" 자체를 검증할 필요는 없어짐(같은 절 "왜
      `nil`이 아니라 `None`인가" 참고). **[정정, 2026-08-14 두 번째 세션]
      소진 값은 이제 `None`이 아니라 전용 센티널 `ProcessedPreRef`** —
      정상 본체 루프가 그 자리를 `ProcessedPreRefHandler`로 매치해
      `Dispatch.setLength(0)`/`setOffsetSource(None)`을 등록하도록 재설계됨
      (`base/ref-plan.md` "PreRef" 절, `base/dispatch-core-plan.md`
      "Length/Offset" 절) — 아래 `PreRef` pre-pass/동적 경로 가드
      체크리스트 항목도 이 값으로 스파이크할 것.
- [x] `props.Modifier`/`props.Ref` named-parameter로 받는 컴포넌트 하나 작성,
      `export type Params = {...}`로 타입 체크되는지 확인
      (`component-composition-plan.md` 최종 결론 1번) — **`props.Modifier or
      None`/`props.Ref or None` 관용구(2026-08-07 열 번째 세션 확정,
      `component-composition-plan.md` "필수 관용구" 절)로 nil-hole을 막는
      케이스를 반드시 포함할 것 — caller가 Modifier/Ref를 안 넘겨도
      `or None`이 항상 non-nil을 보장하므로 `{nil, ref, child}`류 리터럴
      구멍 자체가 안 생김(`research/pre-implementation-audit.md` 1-5).
      M0에서 검증할 것은 "어떻게 막을지"가 아니라 이 관용구가 실제로
      타입 체크/런타임 양쪽에서 문제없이 동작하는지** —
      `luau-test/done/06-component-boundary-nil-hole-props.luau` 통과
- [x] 위 과정에서 소스 트리/메커니즘 문서에 고칠 부분이 생기면 그 자리에서
      `.claude/base/` 갱신 — 실제로 여러 차례 발생, 그때마다 반영됨(각
      스파이크 항목의 "정정"/"재작성" 표시가 그 기록)

**통과 기준**: 위 항목들이 Luau에서 자연스럽게 짜이는 게 확인되면 M1
진행 — **[2026-08-19] 전부 통과, M1 진행 중**(개수는 `luau-test/STATUS.md`가
소스, 여기서 세지 않음).

### 재검증 대기 — 위 `[x]`가 검증했던 스파이크 일부가 무효화됨

**⚠️ [2026-08-22 신설]** M0의 *원래* 체크박스는 전부 닫혔지만, 그 뒤 설계가 바뀌면서
**당시 통과했던 스파이크 몇 개가 지금 계약을 검증하지 않는 상태**가 됐다.
`rewrite-required/`로 되돌아간 것들이고, **어느 마일스톤 체크박스에도
없어서 그냥 잊히기 쉬운 자리**라 여기 모은다. **무엇이 지금 어느 폴더에
있는지의 소스는 항상 `.claude/luau-test/STATUS.md`** — 여기서 세지 않는다.

- [x] **`01`(props 순회 순서)** — **[2026-08-31 닫힘, 재작성 안 함]** M3
      단위 1의 `spec.drive.luau` 1번이 재작성이 물어야 했던 언어 동작
      (일반화 `for` 한 번이 배열 파트 전체를 해시보다 먼저, 배열 안은 index
      순서)을 실제 `Dispatch.drive`에 대고 상시 회귀로 실측 — 스파이크는
      폐기, `done/`으로 이동(round12 brief §6 사용자 승인,
      `luau-test/STATUS.md`의 그 행이 소스)
- [x] **`05`(다이아몬드 전파)** — **[2026-08-29 닫힘, 재작성 안 함]** M2
      구현의 `spec.state.luau` 3번(다이아몬드 규칙 3, 조인 1회)·
      `spec.effect.luau` 3번이 실제 구현에서 같은 것을 고정해 스파이크는
      폐기, `done/`으로 이동(`luau-test/STATUS.md`의 그 행이 소스)
- [x] **`04`(Dispatch 체인 retractFrom)** — **[2026-08-31 닫힘, 재작성 안
      함 — `H-215` (a) 사용자 확정]** M3 단위 1의 `spec.dispatch.luau`가
      검증 대상 대부분(체인 깊이·레벨별 힌트·3-인자 `retractFrom`·`SetStrong`
      음성 대조군)을 실제 구현에 대고 실측 — 스파이크는 폐기, `done/`으로
      이동. 잔여 몫(실제 `StoreBind` 경유 재귀 재발행 경로 — spec은 로컬
      핸들러 근사)은 **M4 mock 테스트 항목이 명시적으로 진다**(그 체크박스에
      적어둠)
- [ ] **`19`(소유권/참조카운트 Relate 패턴)** — **B 섹션만** 낡음
      (공개 `AttributeKey(name)` + 인덱스 1 점유 체크가 폐기되고 그룹 전용
      키 + `AttributeKeyHandler`의 이름 claim으로 바뀜, `0-Z` 확정).
      A/C 섹션은 손댈 것 없음 — **Attribute 소관이므로 M10 착수 시 같이
      처리**(**[2026-08-22 정정]** 여기 "M6"라고 적었으나 B 섹션이 검증하는
      건 Slot이 아니라 Attribute 이름 소유권이다)
- [ ] **`22`(Ref/PreRef/PostRef 브랜드)** — `Brand`가 인스턴스 브랜드로
      전면 재작성되며 옛 `Brand.set`/`Brand.get` 구현에 의존하던 부분이
      깨짐(검증 대상인 `isRef`/`isPreRef` 포함 관계 자체는 그대로).
      **M8 착수 시 같이 처리**
- [x] **`15`(`:Compute` trailing deps 타입팩)** — **[2026-08-28 닫힘, 재작성
      안 함]** M2 단위 2가 실제 `quad-types` 선언에서 타입팩 형태를 실측해
      **기각**했다(`m2-implementation-round11.md` `H-176`: strict에서 콜백
      dep 추론이 깨짐 → deps 자리 `...any` 확정). 물으려던 답이 나와 폐기,
      `done/`으로 이동
- [x] **`10`(Roblox Studio 확인)** — `bindLifetime`/`canExecute`/
      `unbindLifetime` 재정정으로 무효화됐던 것. **[2026-09-01 닫힘]** A
      섹션을 현행 모델로 재작성해 Studio MCP로 완주(전 항목 PASS,
      `done/` 이동) — 결과 전문은 `audit/spike10-full-run-2026-09-01.md`
- [ ] **`11`(modifier 불법 값 error) / `16`·`21`(Store 타입)** —
      **[2026-08-31 소급 등재]** 셋 다 이 절 신설(08-22) **이후** 합류
      (`11`은 8라운드 `H-122`/`H-123`으로 08-26에, `16`/`21`은 Store 재설계로
      08-25에)했는데 이 목록에 안 올라 있었다 — `11`은 ROADMAP 어디에도
      없었고 `16`/`21`은 이제 닫힌 M2 본문 속 한 줄뿐. 재작성 지침은
      `luau-test/STATUS.md`의 각 행이 소스. **단 `11`은 폐기 후보다** —
      재작성이 검증하려는 것(`isModifier` 가드는 `Source` 생성자/`Set`/
      `Compute` 캐싱, Store는 `isSource` 화이트리스트)을 M2 구현의
      `spec.source.luau`·`spec.store.luau`가 이미 실제 구현에서 고정하고
      있어 `05`/`15`와 같은 근거가 성립한다 — 다음 라운드에서 판정할 것
- [x] **아직 파일이 없던 실측 항목 — 중간 State GC** — **[2026-08-28 닫힘]**
      `_hold` 불변식(하류 → 상류 강함; 설계는 2026-08-25 사용자 확정으로
      `question.md`에서 이미 내려가 있었다)을 M2 구현의 `spec.state.luau`
      11번이 양성(체인 생존)·음성(하류를 놓으면 수거) 둘 다 실측 —
      별도 스파이크는 안 만든다(`luau-test/STATUS.md` "만들어야 할 스파이크"
      절의 그 행이 소스). **[2026-08-24 정리]** 여기 같이 적혀 있던
      `R-11`의 `table.insert` 구멍 재사용은 6라운드 `H-7`로
      **전제 자체가 없어져 폐기**됐다(`Ref.Callbacks`가 해시맵 셋이 되어
      구멍 개념이 없음) — `luau-test/STATUS.md`가 소스

## M1 — 실제 스캐폴딩

- [x] `quad-base/`, `quad-roblox/` 폴더 + 각 `pesde.toml`(**[2026-08-19
      정정]** 이 체크박스는 원래 `wally.toml`이라 적혀 있었으나 같은 날
      wally→pesde 전환이 확정돼 `pesde.toml`로 정정 —
      `base/project-setup-plan.md` 참고. `quad-roblox/src`는
      **[2026-09-02]** M5 단위 ①부터 채워지는 중 — 아래 M5 체크박스가
      진행 소스)
- [x] 루트 `default.project.json`, `.luaurc`(`architecture.md` "구현 착수:
      소스 트리 구조 확정" 절 그대로)
- [x] **[2026-08-24 소급 등재, 6라운드 `H-47`/`H-48`] `quad-base/src/Debug/init.luau`**
      — `InitDebug(module)`이 `module.debug = false`를 심는다. **이미 커밋돼
      있었는데 이 목록에도 `architecture.md` 소스 트리에도 없었다**(`ROADMAP.md`
      전체에 "Debug"가 0건이었다). `ROADMAP.md`가 진행 상황의 소스인데 M1
      체크박스만 보면 이 모듈의 존재도 완료 여부도 알 수 없던 상태.
      같이 확인된 것: **`Quad.debug`의 스코프는 "인스턴스별"로 이미 확정돼
      있다**(이 파일이 인스턴스 필드를 심고 `quad-types`의 `Quad`도
      `debug: boolean`을 필드로 갖는다) — `base/module-lifecycle-plan.md`가
      "미정"이라 적어둔 걸 `H-48`이 닫았다
- [x] quad-base용 최소 mock 테스트 하네스(Vide `test/mock.luau` 선례, 순수
      `luau` CLI, `architecture.md` "테스트 전략" 절 참고) —
      `quad-base/test/mock.luau` + `smoke.*.luau` — **[2026-08-25 정정,
      7라운드 `H-78`] "전부 PASS"엔 전제조건이 있었다.** `luau` CLI가
      **심볼릭 링크를 못 타는데**(디렉토리·파일 둘 다) pesde의 워크스페이스
      링크가 전부 심볼릭이라, 그대로는 `smoke.init`/`smoke.plugin`이
      `could not resolve child component "src"`로 죽고 `luau-analyze`는
      **조용히 통과**한다(모듈을 `any`로 떨어뜨림 — "거짓 클린").
      **`./scripts/test.sh`로 돌릴 것** — 그게 `scripts/relink.sh`를 먼저
      돌려 심볼릭을 실제 복사로 바꾼다. 그 뒤 셋 전부 PASS 확인
- [x] 최상위 `New()`/`InitXxx(module)` 팩토리 체이닝 골격 — 각 서브시스템
      Init이 `module`을 파라미터로 받아 뮤테이션, `Relate` 기반 인스턴스별
      멱등 가드(`base/module-lifecycle-plan.md`의 "New()의 내부 구성" 절
      그대로, 2026-08-19 확정) — `quad-base/src/init.luau`의 `New()`/
      `RunInit`/`AddPlugin`으로 구현·smoke 테스트 검증 완료
- [x] 이 시점부터 `.claude/qa-request/`/`.claude/archive/` 폴더 실사용
      시작(**[2026-08-19 확인]** 두 폴더 모두 M1 이전인 설계 단계부터
      이미 쓰이고 있었고 — QA 라운드/역전 결정 기록 — M1 착수 이후에도
      계속 같은 방식으로 쓰이는 중이라 "실사용 시작"이라는 조건은 사실상
      항상 충족돼 있었음)

## M2 — 반응형 코어 (Source/State/Store)

> **⭐ [2026-08-24 순서 교체] 옛 M3(반응형)와 옛 M2(디스패치)의 번호를
> 맞바꿨습니다.** 의존이 양방향처럼 보였지만 실제로는 한 방향이었고
> (디스패치 → 반응형이 본체 의존, 반대는 핸들러 등록 표면뿐), 옛 순서로는
> 디스패치의 Length/Offset 배관도 그 마일스톤의 `mock 대상 테스트`도 State
> 없이 짤 수 없었습니다. 근거와 기각된 선택지는
> `.claude/archive/question-resolved.md`의 "마일스톤 경계" 절.
>
> **⚠️ 이 날짜 이전에 쓰인 `session/`·`archive/`·`qa-request/` 문서의
> `M2`/`M3`는 옛 의미**(M2=디스패치, M3=반응형)입니다 — 히스토리 문서라
> 소급 수정하지 않았습니다. 라이브 문서(`base/`/`research/`/`reference/`/
> `luau-test/`/인덱스 레이어)는 전부 새 번호로 맞췄습니다.
>
> 부수로 **`Brand`/`Relate`/`LifetimeHandle` 인터페이스가 디스패치에서 이
> 마일스톤 앞머리로 왔습니다** — 반응형이 이 셋을 먼저 요구하기 때문:
> `Source`가 `SourceBrand`+`EpochBrand`에 등록되고(`Brand`), State 전파
> 루프가 매 발화마다 `canExecute`를 부르며(`LifetimeHandle`), 그 판정이
> `Relate`에 복사해둔 gcconn 위에 얹힙니다. 반대로 2026-08-22에 여기서
> 디스패치로 옮겼던 **`EpochMap`/`GateNode`/`Blocker`는 되돌아왔습니다** —
> 앞당길 이유 자체가 순서 교체로 사라졌고, "게이팅 먼저"는 그대로
> 지켜집니다.
>
> **⭐ [2026-08-28 착수] M2는 자율 구현 구간으로 돕니다** — 규약(세 갈래 분류,
> 단위 넷, 관여 시점)은 `.claude/qa-request/m2-implementation-round11-brief.md`가
> 소스, 발견은 `-round11.md`. 단위 순서는 이 문서의 체크박스 순서 그대로이되
> **`H-97`의 mock 생명주기 4종은 첫 단위(공통 기반)로 당겨** 짠다 — 그게 없으면
> 두 번째 단위부터 전파 루프 테스트가 안 돈다.

### 공통 기반 — 반응형보다 먼저 (구 M2, 지금의 M3에서 이동)

> 여기 있는 것 전부 State-free이자 dispatch-free라 어느 쪽에도 안 걸립니다.
> 이 절이 끝나야 아래 반응형 본체를 짤 수 있습니다.

- [x] **[2026-08-28 완료 — `quad-base/src/Brand.luau` + `test/spec.brand.luau`, 브랜드 인스턴스 전부와 M2 `is*`가 이 잎 파일에 — 개수는 그 파일이 소스]** `Brand.luau`(**[2026-08-21 재작성]** 인스턴스 브랜드 — `Brand()`가
      브랜드마다 weak-key 집합 하나를 들고 `:register(x)`/`:is(x)`,
      **다중 태깅 허용**(`Source`가 `SourceBrand`이면서 동시에 `EpochBrand`).
      옛 공유 레지스트리 + `Brand.get(x) -> tag`는
      `archive/brand-shared-registry-reversed.md`. **[2026-08-22] `isEpoch`도
      여기 포함** — `Epoch` 인터페이스 확정으로 `EpochBrand`가 생겼고
      `base/state-epoch-plan.md`/`base/source-state-plan.md`가 "런타임 분기는
      `isEpoch`로"라고 확정했다 — `isState`뿐 아니라 `isObserver`/`isEffect`/`isTag`/
      `isAttributeKey`/`isAttribute`/`isTween`/`isBlocker`/`isSource`/
      `isStore`/`isSlot`/`isRef`/`isPreRef`/`isModifier`(2026-08-07 열 번째
      세션 추가 — 원래 태그 목록에서 빠져있었음. **[정정, 2026-08-09
      열한 번째 세션]** `isRef`/`isPreRef`는 `isState`처럼 상위-하위 관계로
      재정정됨 — `isPreRef`가 가장 구체적인 항등, `isRef`는 그 위에 얹혀
      `isPreRef`도 `true`로 통과시킴(PreRef가 Ref 런타임을 재사용하는
      것과 정합). `(v=Ref)` children leaf 매치 핸들러는 이제
      `isRef(v) and not isPreRef(v) and not isPostRef(v)`로 명시적으로
      좁혀야 함(**[2026-08-14 아홉 번째 세션]** `PostRef` 확정으로 제외
      항 하나 추가, `isPostRef`도 `isRef` 아래 형제로 신설). `isModifier`는
      여전히 단순 항등, 상위 개념 없음. **[정정, 2026-08-11 아홉 번째
      세션]** `isAttribute` 하나였던 게 `isAttributeKey`(단일 키 특수 키
      predicate, 해시파트 `k`를 판별)와 `isAttribute`(그룹 값 predicate,
      array-part `v`를 판별, `isTag`와 같은 결)로 분리됨 — 그룹
      `Attribute(...)` 프리미티브 신설로 같은 이름이 서로 다른 두
      대상(키 vs 값)을 가리키게 돼서 갈라짐, `base/attribute-plan.md`
      참고) 전부의 기반. `isNone`은 레지스트리를 안 쓰고 `x == None` 항등
      비교이지만 **`Brand.luau`가 `None`을 참조하지는 않는다**
      (**[2026-08-18 정정]** `brand-plan.md`가 *"`Brand → None` 의존을 만들지
      않는다"*로 확정 — `isNone`은 `None.luau`(M3) 쪽에 산다. 이 마일스톤
      분리로 처음 눈에 띈 잔재를 **[2026-08-24]** 정정한 것) —
      `brand-plan.md`의 `Brand` 절, 2026-08-07 여덟 번째 세션 신설)
- [x] **[2026-08-28 완료 — `relate-plan.md` 대조 일치, `test/spec.relate.luau`, 타입은 `quad-types`로 옮겨 재export]** `Relate.luau`(전체가 quad-base, 순수 Lua — `base/relate-plan.md`) —
      **[2026-08-28 확인] 파일은 M1 커밋 `205af32`에 이미 있다**(`RunInit`이
      쓴다) — 이 체크박스의 남은 일은 `base/relate-plan.md` 대조와 테스트뿐.
      `Relate()` 비싱글톤 생성자, `:SetWeak`/`:GetWeak`/`:SetStrong`/`:GetStrong`.
      `inst`(첫 인자)는 항상 weak, `StrongMap`/`WeakMap` 서브테이블은 lazy
      생성(첫 `Set` 호출 시에만), `WeakMap`은 공유 메타테이블(`{__mode="v"}`)
      재사용 — 구 `base.perInstanceState(inst)`/`PerInstanceState.luau`를
      대체(2026-08-08 세션 신설).
- [x] **[2026-08-28 완료 — `InitLifetimeHandle(module)`이 모듈 인스턴스에 영어 `level 2` 에러 스텁 4종 설치, `test/spec.lifetime.luau`]** `LifetimeHandle.luau` **인터페이스만**(`bindLifetime(inst,value)`/
      `unbindLifetime(value)`/`canBound(value)`/`canExecute(value)` 탑레벨
      함수 타입 계약, 실 구현 없음 — quad-roblox 실 구현은 ~~M8~~
      **[2026-09-02]** M5 단위 ①로 앞당겨 완료, 아래 M8 항목 참고) — 원래
      M8에만 있었으나 M4(StoreBind의 `Connected` 확인)/M6(Slot의
      `canExecute`)이 이미 이 인터페이스를 전제로 서술돼 있어 로드맵
      순서가 역전돼 있었음(`pre-implementation-audit.md` 우선순위1-9 —
      2026-08-07 네 번째 세션에 반영. **[2026-08-22 정정]** 여기 있던
      `question.md` 번호 참조는 그 항목이 해소되며 이미 깨져 있었고,
      지금 그 번호는 다른 항목이 쓰고 있어서 지웠다).
      **[정정, 2026-08-14 다섯 번째 세션] `unbindLifetime`/`canExecute`는
      `inst`를 안 받는다** — 옛 2-인자 시그니처(`(inst, value)`)는 오염이었음.
      `bindLifetime`이 바인딩 시점에 `inst`의 gcconn 참조를 `value` 쪽
      `Relate`로 복사해두므로 "지금 실행돼도 되는가"를 `value` 하나로 물을 수
      있고, `canExecute`의 실제 호출부(State 전파 루프)엔 `inst`가 없어서
      2-인자로는 호출 자체가 불가능했음. 판정은 (a) 복사된 gcconn의
      `.Connected` 또는 (b) Observer/Effect의 `.Subscribed` 둘 중 하나 —
      **`.Subscribed`는 전역 구독 경로 전용 필드라
      `bindLifetime`/`unbindLifetime`이 읽지도 쓰지도 않음**
      (**[2026-08-26 표기 정정, 8라운드 `H-111`]** *"전역 `:Subscribe()` 전용"*
      이라고 적혀 있었으나 `:WeakSubscribe()`도 이 필드를 세운다 — 강·약이
      갈리는 건 레지스트리를 강하게 잡느냐뿐이다. 이 문장의 요지
      (`bindLifetime`이 안 건드린다)는 그대로 유효). 역전 원문은
      `archive/canexecute-inst-arg-reversed.md`.
      **`unbindLifetime(value)` 추가(2026-08-09 여섯 번째 세션)** —
      `inst` 전체 죽기 전에 특정 값 하나만
      조기 해제(`Dispatch.setLength`가 State 재등록 시 이전 Observer를
      정리하는 데 씀), gchold 내부 구조를 호출부가 몰라도 되게 캡슐화.
      `bindLifetime`/`unbindLifetime`/`canBound`/`canExecute` 넷 다
      네임스페이스 없이 탑레벨 함수로 export(`Dispatch.xxx`류 시스템
      네임싱과 구분, `isState`/`isObserver`와 같은 1급 프리미티브 취급) —
      `base/lifecycle-pattern.md`의 "`bindLifetime`/`canBound`/
      `canExecute`/`unbindLifetime` — 확정" 절 참고. **이중 바인딩 금지
      게이트는 `canBound`**(`canExecute`는 emit 전파 게이팅 전용 —
      **[2026-08-14 열한 번째 세션] `canBound`가 별도 진입점으로 재도입되어
      다시 갈라짐, 판정 로직은 공유하는 비공개 헬퍼 하나 — M2 체크박스
      참고**), children 배열 leaf 부착이 실제로는 `bindLifetime` 호출이라
      이 게이트를 그대로 탐
- [x] **[2026-08-28 완료 — `quad-base/src/Ref.luau` + `test/spec.ref.luau`(`:Set` 순서·`bit32` 랩·dedup·weak GC·스냅샷 순회·thread 소진)]** **⭐ [2026-08-27 9라운드 `H-128` 신설] `Ref.luau` 최소형** — 아래
      `Effect(fn, ...deps)`의 `Ref` dep 분기(`isRef(d)` →
      `d:WeakCallback(onRefFire)` → `self._epochs:Sync(d)`)가 **M2 안에서
      실제로 돌려면** 필요한 표면만: `.Value`/`.Revision`/`:Set(value)`/
      `:WeakCallback(fn)`/`:Callback(fn)`/`:Uncallback(fn)`/`isRef` +
      `EpochBrand:register(self)`(`Epoch`를 만족하는 데 필요한 것 전부).
      `PreRef`/`PostRef`/`:Wait`/디스패치 핸들러(`(v=Ref)` 매치, `Processed*`)는
      **M8 그대로**. 근거: `Ref`가 `Epoch`인 것 자체가 M2의 결정
      (`H-58`/`H-64`/`H-70`)이고, `Effect`의 `isEpoch` 분기를 M2의 mock
      테스트가 한 번은 실제로 태워야 한다 — 그 전엔 M8 머리가 *"M2가 이미 이
      표면을 전제한다"*고 **인정만** 하고 M2 쪽엔 앞으로 참조가 없어, 구현자가
      `isRef` 스텁으로 비워두기와 M8 절반 앞당기기 중 임의로 고르게 돼 있었다.
      소스는 `base/ref-plan.md`의 "`Ref`는 `Epoch`를 만족한다" 절.
      **[2026-08-27 `/code-review`]** 아래 `H-80` 탑레벨 목록의 규칙(*"이
      마일스톤이 얹는 탑레벨 값 전부"*)대로 **`quad-types`의 `Quad`에 `Ref`
      생성자 필드도 여기서** 추가한다 — M8의 `H-25` 체크박스는 이걸로 흡수.
- [x] **[2026-08-28 완료 — `quad-base/src/Void.luau` + `test/spec.void.luau`]** **[2026-08-28 `H-162`] `Void`** — 단일 no-op 함수 export. no-op 클로저를
      돌려주는 자리는 새 클로저 대신 이것. 아래 `H-80` 탑레벨 목록에만 있고
      여기 체크박스가 없어 "개수·목록은 소스 하나" 규약에 어긋나던 것을 M2
      착수 규약 커밋에서 신설.

### 반응형 본체

> **[2026-08-28 `H-174`, 사용자 확정]** 이 절의 모듈은 `InitXxx(module)` 팩토리로 조립하고
> 생명주기 게이트는 `module.canExecute(self)`로 **발화 시점에** 읽는다(`Init` 시점 캡처
> 금지 — 백엔드가 `New()` 뒤에 덮어쓴다). 의사코드의 `canExecute(self)`는 전부 그 뜻.
> 소스는 `base/lifecycle-pattern.md`의 `H-174` 문단.

- [x] **[2026-08-28 완료 — 단위 2]** **`EpochMap.luau`** (**[2026-08-24]** 2026-08-22에 디스패치로 옮겼다가 순서 교체로 되돌아옴) — 재사용 가능한 에포크
      부기 객체(`:Update(Epoch|EpochSet) -> boolean`이 "뒤로 전파가
      필요한가"를 답함, `:Refresh`/`:Sync`/`:TrackFrom`. `EpochSet =
      {[Epoch]: true}`로 **배열이 아니라 집합**). `State.luau`에 묻지 말고
      별도 모듈로 낼 것 — `GateNode`(아래)와 `State`/`Effect`가
      전부 같은 것을 쓴다. `Epoch` 인터페이스 자체(`{ Revision: number }`)와
      리비전 갱신(`bit32.bnot(-rev)`)도 여기서 확정 — `base/state-epoch-plan.md`
- [x] **[2026-08-28 완료 — 단위 2]** **[2026-08-21 5라운드 — 채택 확정, 같은 날 `Epoch`로 일반화]** State의
      재계산/전파 판정은 **`Epoch` 리비전 비교**다(`base/state-epoch-plan.md`)
      — `invalid` 플래그가 아니다. **아래 `Source.luau`/`State.luau`가 이걸
      전제로 짜여야 하므로 `EpochMap.luau`(위 항목)가 State 본체보다 먼저
      온다**(`State`가 `valueEpochMap`/`emitEpochMap` 둘을 컴포지션한다 —
      **[2026-08-24] 감사에서 순서가 반대로 놓여 있던 걸 잡아 앞으로 옮김**): `Source`가 `type Epoch = { Revision: number }`를
      구조적으로 만족하고(`EpochBrand`에도 등록), 부기는 재사용 가능한
      **`EpochMap`**(`:Update(Epoch|EpochSet) -> boolean`, `:Refresh`, `:Sync`,
      `:TrackFrom` — `EpochSet = {[Epoch]: true}`, **배열 아님**)
      으로 떼어내며, State가 그걸 **둘** 컴포지션한다 — `valueEpochMap`(값
      유효성)/`emitEpochMap`(전파 dedup). emit은 값도 리비전도 안 싣고
      **출처(`Epoch`나 그 집합)만** 싣고, 순회는 **캐시 카운터가 같을 때만**(옛 `rawInvalid == false` 자리 — **[2026-08-25 `H-85`]** 불린이 `cacheTargetCount`/`cacheCurrCount` 쌍으로 교체됐다)
      돌며 **값만 앞당기고 통지는 상류 emit을 기다린다**. 다이아몬드 중복
      통지가 접히므로 스파이크 `05`도 그에 맞춰 재작성해야 한다
      (`luau-test/STATUS.md`).
- [x] **[2026-08-28 완료 — 단위 2]** `Source.luau`/`State.luau`/`Store.luau` — `State.Init`/`InitSource`/`InitStore` 팩토리(`H-174`), `test/spec.{epochmap,source,state,store}.luau`
- [x] **[2026-08-28 완료 — 단위 2]** **[2026-08-28 10라운드 `H-153`]** Store 생성자의 `isSource` 순회와 `store:Of(name)`에
      **예약 이름 런타임 가드**(`error(…, 2)`) — 동적 키는 타입이 못 막는다;
      그림자 = store 자신(`base/store-plan.md`).
- [x] **[2026-08-28 완료 — 단위 2]** **[2026-08-18 신설, 2026-08-25 확정]** `store:Of<<T>>(name): Source<T>` —
      런타임에 이름이 정해지는 동적 키의 정식 창구(옛 `store "key"` 문자열
      커링은 기각). **콜론 메소드로 확정**했고, 예약 키
      (`Of`/`Names`/**`__reservedCheck`** — **[2026-08-26 `/code-review high`]**
      팬텀 필드가 교집합 안에 살아 자기 이름도 예약해야 한다) 충돌은
      `CheckReservedKeys<keyof<T>>` 타입 함수가 사용
      지점에서 잡는다(**[2026-08-26 `H-112`]** 옛 이름·배선은
      `CheckReserved<T>`였는데 `T`를 통째로 넘기면 실사용 `T`에서 아예 안
      돈다 — `base/store-plan.md`의 "타입 추론 문제" 절).
      `<<T>>`가 값 호출부에서 실제로 `T`를 묶는 것도 실측 확인됨.
      **[2026-08-25] 옛 이름은 `GetDynamic`이었다 — `Of`가 흡수했다**
- [x] **[2026-08-28 완료 — 단위 2]** **[2026-08-25 신설]** `store:Names(): { string }` — 선언된 키 집합
      열거(그림자 테이블의 키). 그룹 `Attribute(...)`/`attr:NameMap()`이
      요구한다(`base/attribute-plan.md`)
- [x] **[2026-08-28 완료 — 단위 2, `quad-types`에 `export type function`으로 구현]** **[2026-08-25 신설, 2026-08-26 배선 정정 `H-112`]** `CheckReservedKeys`
      타입 함수 — **`T`가 아니라 `keyof<T>`**(키 싱글톤 유니온)를 받아
      예약 키를 검증만 하고, 팬텀 필드 `__reservedCheck`로 격리한다.
      `error()`가 아니라 `print(...)` + `return types.never`를 써야 한다.
      **`T`를 통째로 넘기는 옛 배선은 실사용 `T`에서 아예 안 돈다** —
      최종 Store의 `T`는 `{hp: Source<number>, …}`이고 그 `Source`가
      `*error-type*`을 품어 **유효한 Store 전부**에 스퓨리어스 타입 함수
      에러가 뜬다(실측). 근거·통과 배선은 `base/store-plan.md`.
      **타입 함수는 이 용도(진단)까지만 쓴다** — `base/typing-limits.md` §0
- [x] **[2026-08-28 완료 — 단위 2]** **[2026-08-25 신설]** **명시적 초기화** — 타입 인자에 `Source<T>`를
      직접 쓰고 `defaults`에도 `Source(v)`를 직접 넣는다. 옛 lazy `__index`
      (없는 키를 그 자리에서 만들어 저장)는 **폐기**. 그래서 `defaults`가
      곧 선언 키 집합이고 `Names()`가 성립한다
- [x] **[2026-08-28 완료 — 단위 2: `State.luau`의 `_emitDown`, 구독자 전부 `sub:_receive(from)`; Observer 쪽 `_receive`는 단위 3]** **State 전파 루프 — 구독자는 weak, 발화마다 `canExecute` 게이팅**
      (2026-08-14 다섯 번째 세션 확정, `base/lifecycle-pattern.md`의 "실제 호출부" 절) —
      State는 구독자를 **weak-키로만** 담고, 살려두는
      책임은 `gchold`(leaf) 또는 전역 `Subscribed` 테이블(전역)에 있음
      (어디에도 안 묶인 Observer는 GC되어 목록에서 자연히 빠짐).
      **⭐⭐ [2026-08-25 정정, 7라운드 `H-56`] 확정 의사코드는
      `base/source-state-plan.md`의 "전파 루프 — 확정 의사코드" 절이
      소스다.** 여기 한때 적혀 있던 두 가지가 틀렸었다 —
      (a) 집합의 원소는 "Observer의 emit 클로저"가 아니라 **Observer
      값**이다(`bindLifetime`이 그 identity를 쓰므로 클로저를 담으면
      `canExecute`가 항상 거짓), (b) **`canExecute`는 Observer/Effect
      구독자에만 적용된다 — 자식 State 노드는 이 게이트를 안 탄다.**
      "각 구독자에 대해"로 짜면 `:With`/`:Compute`/`:Gate`가 만든 파생
      노드가 **전부 걸러져** 그 아래 모든 Observer가 침묵한다. 자식
      노드의 생존은 `canExecute`가 아니라 같은 문서의 **`_hold`
      불변식**(하류 → 상류 강함)이 책임진다.
      ```lua
      sub:_receive(from)   -- [2026-08-28 `EmitReceive`] 구독자 전부 같은 인터페이스 — State 노드는 §4 규칙,
                           --   Observer:_receive가 canExecute 판정·홀드(`_rerunRequired`)를 자기 안에서
      ```
      (한때 여기서 `isState`/`canExecute`로 갈라 Observer의 `fn`을 직접 불렀다 —
      계층 지식이 섞여 사용자 지시로 인터페이스화, `base/source-state-plan.md`)
      `canExecute`가 `inst`를 인자로 받을 수 없는 이유는 그대로다(State는
      자기가 어느 Instance에 걸렸는지 모름). `state:Observer(fn)`의
      "등록 즉시 1회 실행"은 `bindLifetime` 이전에 동기적으로 일어나므로
      이 게이팅과 무관.
      **순회 전 스냅샷 필수**(`H-23`) — `pairs` 순회 중 새 키 추가는
      미정의다
- **[확정된 것 — 코드 아님]** `store.key` dot-access 타입 추론 확인 —
      **[2026-08-25 재작성]** 옛 `WrapStore`/`ProcessStoreType` 합성 접근은
      **폐기**됐고(`archive/store-value-field-redesign-withdrawn.md`), 지금은
      **타입 함수를 안 쓰고** 타입 인자에 `Source<T>`를 직접 써서 평범한
      레코드로 짓는다(같은 날 `index<>`/`keyof<>` + 팬텀 필드 안을 넣었다가
      §0 원칙에 따라 철회 —
      `archive/store-value-field-redesign-withdrawn.md`). `luau-analyze`로 양성 9건 +
      음성 대조군 전부 확인 — `base/store-plan.md`의
      "`store.key` 레코드 필드 타이핑" 절이 소스. 스파이크 `16`/`21`은
      폐기된 접근을 검증한 것이라 재작성 대기
      (`luau-test/STATUS.md`)
- [x] **[2026-08-28 완료 — 단위 2]** `:Compute(fn, ...)` — trailing args로 추가 의존성 직접 받는 sugar
      (2026-08-11 세션, `base/source-state-plan.md` "`:Compute(fn, ...)`"
      절) — `:With(...):Compute(fn)` 체인과 달리 노드 1개(Compute 노드
      자신에 구독만 추가)로 끝나야 함, 새 노드 생성 없이 구현되는지 M0/M2
      스파이크에서 확인. **[2026-08-24 정정, 6라운드 `H-13`]** 여기 원래
      *"`Effect`/`Observer`는 대칭 sugar 없이 `:With` 명시 유지"*라고 적혀
      있었는데 **`Effect`는 `C-6`에서 이미 역전됐다** — 각 dep에 구독을 따로
      걸면 합치는 노드 자체가 안 생겨 감출 비용이 없다. **기각으로 남은 건
      `Observer` 하나**이고 근거도 새로 쓰였다("Observer는 리시버 State
      하나에 붙는 구독, 여럿을 엮는 건 Effect가 대신한다")
- [x] **[2026-08-28 완료 — 단위 2]** `state:Apply(factory)`(`base/source-state-plan.md` "`state:Apply(factory)`"
      절, 2026-08-07 일곱 번째 세션) — `factory(self)`를 체이닝 문법으로
      부르는 순수 설탕, `factory: (State<T>) -> U): U`로 열린 타입. Source도
      기존 `:With`/`:Compute` 델리게이션에 얹혀 자동 포함
- [x] **[2026-08-29 완료 — 단위 3]** **`Observer.luau`** — `Observer` 객체와 **`:Subscribe()`/`:WeakSubscribe()`
      전역 레지스트리의 소유 모듈**. `EpochMap.luau`와 같은 이유로
      `State.luau`에 묻지 않는다(`Effect`/`GateNode`/leaf 핸들러가 전부 이
      레지스트리를 본다) — `base/architecture.md` 소스 트리, 7라운드 `H-99`
- [x] **[2026-08-29 완료 — 단위 3]** `state:Observer(fn)` — children 배열 leaf 참가자, **등록 즉시 1회
      실행 확정**(`base/source-state-plan.md`의 Observer 절), `isObserver`
      판별자, canExecute 게이팅, `:Subscribe()`/`:Unsubscribe()` +
      **`:WeakSubscribe()`/`:WeakUnsubscribe()`**(Weak 쪽이 프리미티브,
      7라운드 `H-58`/`H-59`).
      **⭐⭐ [2026-08-26 추가, `H-109`/`H-110`; `/code-review high` 7차가 누락을
      잡음] `fn`의 시그니처는 세 자리 `fn(targetState, self, emitFrom)`이고,
      생성 시 `observer._state = state`(리시버 강참조)를 세운다** — 전파 루프가
      그 필드를 1번 인자로 읽는다(위 루프 스니펫). 이걸 빼고 `Observer.luau`를
      짜면 `sub._state`가 `nil`이라 **모든 콜백이 리시버 자리에 `nil`을 받고**
      무인자 유틸이 `nil:Get()`으로 죽는다 — `H-109`가 고치려던 그 크래시.
      `observer._state`는 Observer의 `_hold` 상당이기도 하다(`H-110`).
      **무인자 `state:Observer()`의 내부 콜백은
      `function(targetState) targetState:Get() end`**(`H-61`; **[2026-08-26]**
      파라미터 이름이 `self`였는데 1번 자리는 Observer가 아니라 리시버다). **동적
      경로 가드**(`{priority = HANDLER_PRIORITY_FALLBACK, isHandlable = v
      is Observer, process = error(...)}`, `k` 타입 안 가림, 2026-08-14
      열한 번째 세션 — `PreRef`와 같은 패턴)도 같이 등록
      **⚠️ [2026-08-24] 단 그 가드를 `Dispatch.addHandler`로 등록하는 것
      자체는 M3다** — 레지스트리가 거기서 생긴다(M3의 그 항목).
- [x] **[2026-08-29 완료 — 단위 3]** `Effect(fn, ...deps)` — ~~**⚠️ 선행: `Blocker`의 기본 메커니즘**~~
      (**[2026-08-28 10라운드 `H-150`]** 선행 요구 **해소** — 생성자의 사적
      `Blocker`는 `canExecute`(지금은 `rawRerun` 진입, `H-159`)가 이미 같은 억제를 해서 한 번도
      판정에 닿지 않는 죽은 부품이라 제거됐다. `Blocker.luau`는 이제 `GateNode`/
      Slot 쪽 요구뿐.) (`base/effect-plan.md`, **[2026-08-21 5라운드
      `C-6`]** 옛 시그니처는 `Effect(fn, state?)`) — deps 생략 시 설치
      1회+leaf 사망 시 확정 정리, deps 지정 시 **각각에 맞는 구독**
      (State/Source는 `Observer`, `Ref`는 `:WeakCallback` — **[2026-08-27
      9라운드 `H-129`]** 옛 `:Callback` 표기는 `H-58`이 정정한 것의 잔재로,
      강한 셋에 걸면 `Ref`가 `Effect`를 영원히 붙든다)을 걸어
      재실행+cleanup 체이닝(React `useEffect` 동형). **`EffectHandle`이
      `EpochMap`을 하나 들어** 공통 상류로 인한 중복 발화를 접고, 설치 구간
      억제 플래그가 그 `Update`보다 먼저 와야 함
      (`base/state-epoch-plan.md`). Observer 구현 이후에 착수(의존 관계).
      `EffectHandle:Subscribe()`/`:Unsubscribe()`도 추가(leaf 없이 쓰는
      모듈/스크립트 레벨 Effect) — `:Unsubscribe()`는 Observer와 달리
      마지막 cleanup을 1회 트리거해야 함(2026-08-07 일곱 번째 세션).
      **[2026-08-28 10라운드 `H-147`]** `rawRerun(self, force)` 본체 + 공개
      `Rerun()`(진입에서 `canExecute` 게이트 — 죽은·안 묶인 핸들의 요청은 **[`H-159`]** `_rerunRequired`로 홀드),
      생성자는 `rawRerun(self, true)`. **`fn`/cleanup은 자기 구독을 못 바꾼다** —
      네 진입점 첫 줄에 `_running` 가드(2026-08-27의 "`fn` 안 `Unsubscribe` 지원"
      `H-143`과 `wasAlive` 꼬리는 소멸). 네 진입점은 **`EffectHandle` 자기 것**
      (`H-144` (b) — 공유는 `Observer.luau`의 레지스트리 둘과 `canBound`뿐),
      `Subscribe`/`WeakSubscribe`는 등록 끝에 `_rerunRequired → Rerun`(재구독
      재설치 + 홀드된 변경; **[`H-151`/`H-159`]** `_epochs:Refresh()` 캐치업은 폐기 —
      `_epochs`는 `fire`의 `Update`에서만 갱신하고, 실행 불가 상태에 온 변경은
      `rawRerun`이 `_rerunRequired`로 홀드) — 의사코드는 `base/effect-plan.md`.
      **동적 경로 가드**도 Observer와 같은 패턴으로 등록(`base/effect-plan.md`
      "동적 경로 가드" 절, 2026-08-14 열한 번째 세션)
      **⚠️ [2026-08-24] 단 그 가드를 `Dispatch.addHandler`로 등록하는 것
      자체는 M3다** — 레지스트리가 거기서 생긴다(M3의 그 항목).
- [x] **[2026-08-29 완료 — 단위 3]** **⭐ [2026-08-24 신설, 6라운드 / 2026-08-25 7라운드로 필드 재편]
      `Effect` 구현 시 같이 만들 것** —
      **`handle._deps`**(`{[Ref|State] = fn|Observer}`, **강참조** — 옛
      `_observers`/`_refDeps`/`_refCallbacks` 셋이 여기로 통합됐다) ·
      **`handle._epochs`**(`EpochMap` — `Ref`도 `Epoch`라 dep 종류가 균일) ·
      **⭐ [2026-08-26 추가, 8라운드 `H-107`/Q2-후속] dep 등록 클로저는 종류별로
      *둘*이다** — `onRefFire(_, ref)`(Ref 콜백은 `fn(value, ref)`라 출처가
      **2번째**)와 `onStateFire(_, _, from)`(Observer는
      `fn(targetState, self, emitFrom)`라 출처가 **3번째**). **하나로 합치려
      들지 말 것** — 한때 effect-plan에 *"클로저는 하나로 통일한다"*고 적혀
      있었으나 근거 없는 서술이라 삭제됐다(사용자 확정: 두 콜백은 이질적이고,
      Observer엔 자기 epoch가 없지만 `Ref`는 그 자체가 epoch다). dedup은
      클로저 identity가 아니라 `_deps`/`_epochs` 맵이 한다 ·
      ~~**`handle._blocker`**~~(**[2026-08-28 `H-150`]** 제거 — 등록 구간의
      즉시-1회 호출은 별도 필드 없이 `fire`의 `from == nil` 가드와 `rawRerun`의 `canExecute`가 억제한다(`H-159`); 옛
      `_installing` 플래그도 생성자 구간만 덮어 폐기됐었다) ·
      **`handle._cleanup`**(직전 cleanup 보관, `Rerun`과 `Destroying` 클로저가
      같은 자리를 읽는다) · **`handle._rerunRequired`**(`fn`이 돌아야 하는데 아직 안 돌았다 — 생성 직후 /
      소진 뒤 / 실행 불가 상태에 온 변경; **[2026-08-28 `H-159`]** 옛 `_installed`를 흡수.
      `fn`의 cleanup 반환이 **선택**이라 `_cleanup`의 유무로는 판정할 수 없다) ·
      **`handle._running`/`_pending`**(`Rerun` 재진입
      지연) · **`handle._destroyConn`** ·
      **`:_bindDestroying(inst)`/`:_unbindDestroying()`**
      (`bindLifetime`/`unbindLifetime`이 `isEffect`일 때 부르는 훅, `H-11`) ·
      **`:Rerun()`**(정의는 `H-60`이 채웠다 — 실행 중 재진입은 **지연
      재실행**, error는 UB) · **`:_consumeCleanup()`**(읽고 → 지우고 → 실행).
      `fn` 시그니처는 **`fn(self: EffectHandle) -> ...(() -> ())`**이고
      (**[2026-08-25 `H-95`]** 가변 반환 팩 — 옛 `-> (() -> ())?`는 콜백이
      "선언보다 적게 반환"할 때 strict에서 막혀 정상 용례가 전부 안 통과했다)
      **`...deps`는 `fn`에 안 넘어간다**(`H-14`).
      **⭐ dep 등록은 생성자에서 한 번만** — `:WeakSubscribe()`/
      `:WeakCallback()`으로 걸고, 바인드/언바인드는 dep을 아예 안 건드린다
      (`H-58`/`H-59`). 발화 게이트는 전부 **`canExecute(handle)`** 하나다
      (`H-7`). 캐치업은 바인드 직후 **`_rerunRequired`면 1회**(`if self._rerunRequired then
      self:Rerun() end` — **[2026-08-28 `H-151`/`H-159`]** 옛 `_epochs:Refresh()`는 폐기,
      `_epochs`는 emit 받을 때만 갱신하되 실행 불가 상태의 변경은 홀드 — `H-64`/`H-65`). 의사코드는 `base/effect-plan.md`가 소스
- [x] **[2026-08-28 완료 — 단위 2]** **[2026-08-24 `H-23`]** State 전파 루프는 구독자 집합을 **배열로
      스냅샷한 뒤** 돈다 — 순회 중 새 구독자 추가가 정상 경로인데 Lua에서
      미정의라, 실측에서 실행마다 결과가 달라지고 한 Observer가 통째로
      누락됐다. "이번 파동 중에 붙은 구독자는 다음 파동부터"가 계약
- [x] **[2026-08-29 완료 — 단위 3]** Observer/Effect 이중 바인딩 금지 — `canBound(value)` 게이트로
      `:Subscribe()`(전역)와 `bindLifetime`(inst-scoped, leaf 부착도
      내부적으로 이걸 호출)이 동시에 걸리면 즉시 `error`(`base/source-state-plan.md` "이중 바인딩 금지" 절, 2026-08-07 일곱 번째
      세션 신설, 2026-08-09 여섯 번째 세션에서 "leaf 부착=bindLifetime
      호출"로 정정 — 진짜 독립 경로는 둘뿐).
      **[2026-08-14 다섯 번째 세션에 별도 predicate `canBound(handle)`을
      폐기하고 `canExecute` 하나로 합쳤다가, 같은 날 열한 번째 세션에
      다시 갈라짐]** — "지금 묶어도 되는가"(bound 문맥)와 "지금
      발화해도 되는가"(execute 문맥)는 호출부의 질문이 다르고
      **[2026-08-18 구현 전 QA 정정] 판정값도 같은 게 아니라 서로의
      부정**이라(`canBound(v) == not canExecute(v)`, 게이트는 항상
      `if not canBound(v) then error(...)`), `Ref` 이중 배치
      방지(`question.md` 0-W)를 계기로 `canBound`가
      별도 진입점으로 재도입됨 — 판정 로직(비공개 `isBoundAlive` 헬퍼)은
      공유해 코드 중복은 없음. **이 절이 쓰는 게이트는 이제 `canBound`**
      (emit 전파 게이팅 전용 `canExecute`가 아님). `.Subscribed` 필드가
      leaf 경로와 무관하다는 것, leaf 생존 판정을 `bindLifetime`이 `value`
      쪽 `Relate`에 복사해둔 gcconn으로 하는 것은 안 바뀜 — `base/
      lifecycle-pattern.md`의 "`canBound` vs `canExecute`" 절, 역전 경위는
      `archive/canexecute-inst-arg-reversed.md`. 부수 효과로 **바인딩이
      죽은 뒤(`Destroy`/`unbindLifetime`)의 재사용은 게이트를 통과**
      (살아있는 바인딩만 막는 게 의도, 안 바뀜)
- [x] **[2026-08-29 완료 — 단위 4]** **`state:Gate(setup)` + `GateNode`** (**[2026-08-24]** 위 `EpochMap`과 같이 되돌아옴) —
      emit을 가로채 유보했다가 한 번에 내보내는 공용 게이트 노드
      (`ComputeNode`와 같은 층위, 탑레벨 `Gate(...)` 프리미티브는 안 만듦).
      **[2026-08-28 10라운드 `H-152`] 조립 첫 줄은 `StateBrand:register(node)`** —
      빠지면 `_emitDown`의 `isState`가 거짓이라 통지만 조용히 죽는다(`base/gate-plan.md`
      조립 절). **[`H-151`]** 게이트는 emit 경로만 미룬다는 계약(같은 문서).
      유보 배치는 `withheld : { [epoch] : true }`(집합), flush 때 테이블을
      통째로 갈고, **내보내는 emit이 싣는 건 그렇게 떼어낸 `EpochSet`
      스냅샷뿐이다 — 게이트 노드 자신은 안 싣는다**(하류가 게이트 identity를
      한 번도 안 쓴다, `base/state-epoch-plan.md` §5). **빈 배치는
      아무것도 안 함**. `emitEpochMap`을 쓰므로 위 `EpochMap.luau`가 선행 —
      `base/gate-plan.md`. **"게이팅 먼저" 결정의 산물**
      (사용자: *"게이팅 먼저. 게이팅을 base 에 만들 준비를 해야한다"*).
      **⭐⭐ [2026-08-25 갱신, 7라운드 `H-55`/`H-72`/`H-86`] `setup` 계약이
      바뀌었다** — `setup: (emit: (commit: boolean?) -> boolean) ->
      (onUpstreamEmit: () -> ())`. 인자 **목록**은 그대로지만
      `emit(false)`가 **흡수 집합을 버리고**(정책이 그걸 할 통로가 없었다),
      반환값이 **"실제로 내보내거나 버릴 게 있었는가"**를 준다(정책이
      `pending`을 읽을 통로가 없어 `Throttle`의 창이 idle로 못 돌아왔다).
      그리고 **수신 시점 판정은 `emitEpochMap:Peek`**을 쓴다 — `:Update`는
      덮으므로 "유보 중엔 아직 안 던졌다"는 맵의 뜻과 양립하지 않는다.
      flush 순서는 **빈 배치 얼리리턴 → 스왑 → `:Sync(batch)` → 전파**
- [x] **[2026-08-29 완료 — 단위 4]** **`Blocker.luau`** (**[2026-08-24]** 위 둘과 같이 되돌아옴) — 위 `GateNode` 위에
      얹히는 **정책**(다시 노드를 만들지 말 것).
      **⭐ [2026-08-25 추가, 7라운드 `H-63`] onunblock 핸들 보관 세 자리**:
      (1) **weak-키 해시맵 셋**(`__mode = "k"`) — 값-weak 배열이면 구멍에서
      `ipairs`가 멈춰 뒤의 살아있는 게이트가 `Off()`를 못 받는다,
      (2) **강한 주인은 정책이 반환하는 `onUpstreamEmit` 클로저**(upvalue로
      잡는다) — Blocker가 강하게 들면 거기 걸렸던 모든 gated state와 상류
      체인이 영원히 산다, (3) `Off()`/`OffWithoutEmit()`은 **스냅샷 뒤 순회**. 여러 Source를 한꺼번에
      바꿔도 파생값 재계산/재대입이 한 번만 되게 하는 primitive
      (`base/blocker-plan.md`). **M3의** `Dispatch.setLength`/`setOffsetSource`의
      배치 등록이 `:On()`/`:IsOn()`/`:OffWithoutEmit()` **세 메서드**를
      호출하므로(`base/gate-plan.md` 9번이 소스 — Blocker 인스턴스를 lazy
      조회하는 `getBlocker(ownerKey)`는 Blocker 메서드가 아니라 Dispatch
      쪽 헬퍼다) **최소한 그 셋이 도는 형태까지는 M3(디스패치)가 요구**
- [x] **[2026-08-29 완료 — 단위 1~4분 전부(`Relate`/`Void`/`Ref`/`is*`/생명주기 4종+`onDestroying`/`Source`/`Store`/`Effect`/`Blocker` + `State`·`Source`·`Store`·`Observer`·`EffectHandle`·`Blocker`·`GateSetup` 타입)가 `quad-types` `Quad`에 추가됨 — M2 몫은 닫힘]** **[2026-08-24 `H-25` 파생, 2026-08-25 `H-80`으로 목록 확장]**
      `quad-types`의 `Quad`에 **이 마일스톤이 얹는 탑레벨 값 전부** 추가 —
      `Source` / `Store` / `Effect` / `Blocker` / `Relate` / **`Void`**(단일 no-op 함수 export — no-op 클로저를 돌려주는 자리는 새 클로저 대신 이것, **[2026-08-28 `H-162`]**) / **`Ref`**(최소형,
      2026-08-27 `H-128`) /
      `is*` 전량(`isState`/`isSource`/`isStore`/`isRef`/`isObserver`/
      `isEffect`/`isEpoch`/`isModifier` …) / `bindLifetime`·`unbindLifetime`·
      `canBound`·`canExecute` 4종. **⚠️ `State`는 런타임 생성자가 없다** —
      파생(`:With`/`:Compute`/`:Gate`)으로만 생기므로 **타입만** 재수출한다.
      옛 목록(`Source`/`State`/`Store` 셋)은 M2가 실제로 얹는 것의 일부만
      담고 있었고, 빠진 것 전부가 `H-25`가 만든 바로 그 벽에 부딪힌다.
      **규칙 요지**: `New(): Quad`가 닫힌 레코드이고
      `RunInit`은 반환값이 없어 타입을 못 넓히므로, 서브시스템을 붙이는
      마일스톤마다 `quad-types`의 `Quad`에 그 필드와 타입 재수출을 같이
      추가한다. 안 하면 그 마일스톤 완료 후 `quad.Store` 접근이 런타임엔
      되는데 `luau-analyze`에선 타입에러다(`H-25` 실측). **순서 교체로
      이 마일스톤이 그 규칙의 첫 적용 지점**이고, 규칙의 정본은
      `base/quad-types-plan.md`의 "`Quad` 타입 — 확정된 표면" 절
      (M3의 `H-25` 항목이 같은 규칙을 `Dispatch` 기준으로 서술한다)
- [x] **[2026-08-28 단위 2 — 런타임은 완료(`fn(self, previous?, ...deps)`), 타입은 `...any`: 타입팩 `D...`로 좁히는 형태는 strict에서 콜백 dep 추론이 깨져 실측 기각(`round11.md` `H-176`)]** trailing deps를 `fn`에 lazy positional 인자로도 노출(**⚠️ [2026-08-24
      `H-14`] 이 항목은 `:Compute` 한정이다** — `Effect`의 `fn`엔 deps가 안
      넘어간다) — (`fn(self,
      previous?, dep1, ..., depN)` — 순서는 Luau 값 레벨 `...`가 파라미터
      리스트 맨 끝이어야 하는 것과 같은 이유로 `previous?`가 deps 팩
      **앞**에 와야 함, 2026-08-11 후속 세션 제안 → 같은 날 세 번째
      세션에 순서 정정, `base/source-state-plan.md` "trailing deps를 fn에
      lazy positional 인자로도 노출" 절) — 방향/순서는 확정,
      **[2026-08-28 실측 전 서술 — 결과는 위 배너, 아래는 원문]**
      `luau-test`의 `15-type-compute-trailing-deps-typepack.luau`로
      이형 다중 deps를 제네릭 타입 팩으로 표현 가능한지만 실측 필요(안
      되면 동종 타입 dep 1개로 한정 — 실측 결과 채택된 건 이 대안이 아니라
      deps 자리 `...any` + 콜백 주석이다)
- [x] **[2026-08-29 완료 — 단위 2에서 `:With`/`Source:Emit()`, 단위 4에서 `state:Apply(blocker)`(`Blocker.__apply` → `state:Gate`, `spec.blocker` 2번)]** **[2026-08-25 신설, `H-84`]** `:With(...)` / `state:Apply(blocker)` /
      `Source:Emit()` — `:Compute`/`:Apply`/`:Observer`는 각각 체크박스가
      있는데 이 셋만 빠져 있었다
- [x] **[2026-08-28 완료 — 단위 2]** **[2026-08-25 신설, `H-81`; 2026-08-26 자리 정정 `H-122`]**
      `isModifier` 런타임 가드 — 적용 지점이
      **전부 이 마일스톤의 코드**다: **`Source(...)` 생성자** / `Source:Set` /
      State의 `:Compute` 결과 캐싱. 체크박스가 M7에만 있었다.
      **[2026-08-26]** 여기 한때 *"Store 생성 시 eager `Source(default)`"*가
      적혀 있었으나 명시적 초기화 이후 **`defaults` 경로엔 그 지점이 없다**
      (**[2026-08-26 정밀화]** 동적 키 창구 `store:Of(name)`은 여전히 만든다) —
      가드를 `Source` 생성자에 두면 그 둘이 **한 번에 커버**된다
      (`base/modifier-plan.md` 7번이 소스)
- [x] **[2026-08-28 완료 — 단위 2]** **[2026-08-26 신설, `H-122`]** `Store` 생성자의 `defaults` 런타임
      검증 — 값 전량에 `isSource` 화이트리스트, 거짓이면 `error(..., 2)`
      (영어 메시지). 타입은 `Source<T>`를 요구하지만 `--!nocheck`/동적
      코드가 raw 값을 넘기면 지금 스케치(`table.clone`)는 조용히 받고 첫
      `:Get()`에서 엉뚱한 에러로 죽는다. 생성 시 1회라 hot path 아님
- [x] **[2026-08-28 완료 — 첫 단위로 당겨서 `test/mock.luau`의 `installLifetime(quad)`, `lifecycle-pattern.md` (0)/(1) 스케치 그대로; mock `Destroy`가 모든 Connection을 끊도록 보강]** **[2026-08-25 신설, `H-97`]** mock 백엔드용 생명주기 4종 최소 구현 —
      `bindLifetime`/`unbindLifetime`/`canBound`/`canExecute`. 안 하면
      **아래 "mock 대상 테스트"가 전파 루프를 한 번도 못 돈다**(루프가 매
      발화마다 `canExecute`를 부르는데 그건 M8 구현이고 미주입 슬롯은
      에러 스텁이다). 커밋된 `quad-base/test/mock.luau`에 signal/Connection이
      이미 있으므로 그 `Destroying`을 그대로 쓰면 된다
- [x] **[2026-08-29 완료 — 단위 3: `spec.observer.luau` 2·`spec.effect.luau` 2가 mock Instance에 묶은 채 전파 루프를 실제로 돌린다(홀드 → 바인드 캐치업 → 발화 → 파괴)]** mock 대상 테스트 — **전파 루프를 실제로 돌릴 것**(위 항목이 선행).
      M2의 핵심이 전파 루프인데 그걸 한 번도 안 돌려보고 M3로 넘어가면
      7라운드가 찾은 종류의 결함을 그대로 낳는다

## M3 — 디스패치 엔진

> **✅ [2026-09-01 종결]** 자율 구현 구간(규약 `qa-request/
> m3-implementation-round12-brief.md`, 원장 `-round12.md`)으로 2026-08-31
> 착수, 단위 넷 + §4 배치 회신 두 라운드 + 감사·리뷰·탐사까지 완주. **M3
> 자기 몫 체크박스는 전부 `[x]`** — 아래 `[ ]`로 남은 항목은 이 목록이
> 계속 추적하는 **다른 마일스톤의 잔여 몫**(children-array leaf의
> Ref/PreRef/PostRef 매칭 — M8 `Ref.luau`(`H-278`), 말단 핸들러 체크리스트의
> 잔여 3종 — M8/M10)이다. 회신 라운드의 구조 확정 셋(`H-277` Bookkeeping
> 분리 / `H-278` 등록 소유권 / `H-279` pre-hook 리서치)은 round12 §4가 소스.

> **✅ [2026-08-13 열네 번째 세션] 재디스패치 모델 교체 완료 — 아래
> 체크리스트는 새 모델("하강 diff") 기준으로 갱신됐습니다.** 래핑 핸들러의
> 선행 `retractFrom`은 폐기됐고, `Dispatch.process`가 슬롯의 `handler`를
> 먼저 비교해 (같으면 그 자리 클로저에 새 값을 넘기고 자기 `process`
> 재호출, 다르면 그 자리부터 전량 철거) 처리합니다. 정본은
> `.claude/base/dispatch-core-plan.md`(같은 세션에 `bind-system-plan.md`에서
> 분리 신설), 뒤집힌 옛 모델은
> `.claude/archive/dispatch-hintvalue-model-reversed.md`.

> **⭐ [2026-08-24 순서 교체] 이 마일스톤은 옛 M2입니다** — 번호를 반응형
> 코어와 맞바꿔 그 뒤로 옮겼습니다(경위는 M2 배너가 소스, 여기서 반복하지
> 않음). 2026-08-22에 여기로 옮겼던 `EpochMap`/`GateNode`/`Blocker`와,
> 반응형이 먼저 요구하는 `Brand`/`Relate`/`LifetimeHandle` 인터페이스는
> M2로 갔습니다. 여기 남은 것은 전부 디스패치 배관이고, **이제 이
> 마일스톤은 M2 위에 단방향으로 얹힙니다.** 개념상 역방향이던 둘
> (Observer/Effect 가드 등록, `ObserverEffectLeafHandler` — "핸들러를
> 등록한다"뿐인 것)은 **맨 아래 두 항목으로 여기 옮겨져** 있으므로,
> **빌드 순서상 역방향 간선은 없습니다.**


- [x] **[2026-08-31 M3 단위 1]** `Dispatch/init.luau` — `Dispatch.getHandler(inst,k,v): Handler?`(순수
      스캔, `isHandlable`+`priority`) / `Dispatch.process(inst,k,v,index)`
      (오케스트레이터: getHandler → **그 인덱스의 기존 핸들러와 비교** →
      같으면 그 자리 클로저에 새 값을 넘기고 같은 핸들러의 `.process`로
      자리 교체, 다르면 `retractFrom` 후 새로 설치. 반환값이 `nil`이면
      즉시 error) / **3-인자** `Dispatch.retractFrom(inst,k,index)`
      (아래 항목) / `Dispatch.addHandler(handler)`(레지스트리 등록,
      quad-roblox가 팩토리 뮤테이션 시점에 호출) / `Dispatch.drive(inst,
      flattened)`(**일반화 `for` 한 번**으로 순회하며 각 `(k,v)`에
      `Dispatch.process(inst,k,v,1)` 호출 — `dispatch-core-plan.md`의 `None`
      센티널 절, 2026-08-07 여덟 번째 세션에 네이밍 확정).
      **[2026-08-27 9라운드 `H-139`]** `New` ①~④ + `drive` (a)~(c) 전체
      파이프라인 의사코드는 `base/bind-system-plan.md`의 "`New(name)(props)`
      파이프라인 의사코드" 절 — 배치 Blocker를 여닫는 자리와 빈 배열 파트
      가드도 거기.
      **[2026-08-21 구현 전 QA 4라운드 `F-4-1`] 순회는 두 패스가 아니라
      단일 일반화 `for`다** — "배열 파트 전체가 해시 파트보다 먼저"는 여전히
      base가 보장하는 **계약**이지만, `flattened`가 항상 평범한 Luau
      테이블이라 일반화 `for` 한 번이 그 순서를 그대로 주고 두 층위는
      `type(k) == "number"` 분기로 가른다(`base/dispatch-core-plan.md`의
      `F-4-1` 정정 문단). 옛 "명시적 두 패스" 서술은 구현까지 2회 순회로
      못박은 것처럼 읽혀 정정됨 — 그 때문에 스파이크 `01`도 재작성 대기였다가
      **[2026-08-31]** `spec.drive.luau`가 대체하며 폐기(`luau-test/STATUS.md`).
      **[2026-08-31 단위 1 범위 절단(round12 brief §6)]** 지금 커밋된 `drive`는
      파이프라인 (b) 본체 루프만이다 — ⓪/⓪' 배치 Blocker 게이팅은 M3 단위
      2(`getBlocker`/부기가 생기는 자리)에서, (a) pre-pass와 (c) `postRefList`는
      M8(`PreRef`/`PostRef` 본체)에서 배선된다
- [ ] **⭐ [2026-08-24 신설, 6라운드 손 트레이싱 `H-39`] 말단 핸들러는 예외
      없이 자기 배열 자리의 `setOffsetSource(inst,k,None)` → `setLength(inst,k,0)`을
      등록한다** — 이 계약을 핸들러 작성 체크리스트에 넣고, 실제로 넷이
      빠져 있었으니 각 마일스톤에서 확인할 것: `TagHandler`(M10) /
      `AttributeGroupHandler`(M10) / `RefLeafHandler`(M8) /
      `ObserverEffectLeafHandler`(이 마일스톤, 맨 아래). 안 하면 `bk.N`이 다른 자리 등록으로
      커질 때 그 구멍이 범위 안에 끼어 `recompute`가 **명시적 error로 죽는다**
      (`Frame { Tag("card"), TextLabel{} }`처럼 말단이 앞에 오는 흔한 배치).
      **배열 맨 끝이면 안 터지므로 "가끔 되고 가끔 터지는" 형태로 드러난다.**
      소스는 `base/dispatch-core-plan.md`의 등록 책임 절
- [x] **[2026-08-31 M3 단위 1 완료]** **⭐ [2026-08-24 신설, 6라운드 손 트레이싱 `H-25`] `quad-types`의 `Quad`
      타입에 `Dispatch` 필드와 그 타입 재수출을 추가** — `Quad`가 5필드 닫힌
      레코드이고 `RunInit`은 반환값이 없어 타입을 못 넓히므로, 이걸 안 하면
      `module:RunInit(InitDispatch)` 뒤의 `quad.Dispatch` 접근이 **런타임엔
      되는데 `luau-analyze`에선 타입에러**다(실측 재현). `base/architecture.md`의
      확정된 결정 13번이 그 접근을 표준 사용법으로 못박아뒀다.
      상세는 `base/quad-types-plan.md`의 "`Quad` 타입 — 확정된 표면" 절.
      **⚠️ 이건 M3 한 번으로 끝나는 일이 아니고, 첫 적용은 오히려 M2다** —
      그 문서가 *"마일스톤마다 갱신한다 … 이후 서브시스템도 같은 규칙을
      따른다"*로 확정했으므로, **서브시스템을 붙이는 모든 마일스톤이 같은
      항목을 진다**: **M2(`Source`/`State`/`Store`, 규칙이 처음 적용되는
      자리)** · M6(`Slot`) · M7(`Modifier`) · M8(`Ref`) ·
      M10(`Tag`/`Attribute`). (**[2026-08-24]** 규칙 자체는 `Dispatch`를
      계기로 쓰였지만 마일스톤 순서 교체로 M2가 앞에 오게 됐다 — M2를 짜는
      사람이 이 항목을 앞으로 참조하지 않아도 되게, 규칙 요지는 M2의
      `H-25` 파생 항목에도 적어뒀다.) 빠뜨리면 그 마일스톤 완료 후
      `quad.Store`/`quad.Slot` 접근이 런타임엔 되는데 `luau-analyze`에선
      타입에러인, `H-25`가 실측한 그 문제가 **마일스톤마다 반복된다.**
- [x] **[2026-08-31 M3 단위 1]** `Handler.luau`(핸들러 계약 타입: `isHandlable(inst,k,v)`/`priority`/
      `process(inst,k,v,index) -> (hintValue)->()` **3종** — `isHandlable`도
      `inst`를 받도록 확정(2026-08-07 여덟 번째 세션), 별도 `retract` 필드는
      `process` 반환값으로 합쳐짐(2026-08-13 다섯 번째 세션))
- [x] **[2026-08-31 M3 단위 3 — `spec.nonenil.luau` 5절 실측(해시 None 재귀 /
      배열 0 등록 / 값↔None 전환 / 매치 경계). 센티널 값 자체는 `H-233`으로
      단위 2에 선행 생성됐고, "탑레벨 `None.luau`" 별도 파일은 없다 — 정의는
      `Dispatch/None.luau`(+`register`), 최상위 `init.luau`가 값 재export
      (`slot-plan.md`의 재노출 서술 그대로)]**
      **[2026-08-22 M7에서 이동] `None.luau`(센티널) + `Dispatch/None.luau`
      (`NoneHandler` + `NilHandler`)** — `None`은 modifier 전용 값이 아니라
      디스패치 배관이라 여기 소속(`architecture.md`의 소스 트리에 있는 건
      핸들러 쪽 `Dispatch/None.luau`뿐 — **[2026-08-22] 탑레벨 센티널
      `None.luau`는 그 트리에 아직 줄이 없다** — ~~M3 구현 시 트리도 같이
      채울 것~~(**[2026-08-31 단위 3]** 별도 탑레벨 파일을 안 만들기로
      확정돼 채울 줄 자체가 없다 — 위 배너와 `H-253`). **[2026-08-28]** 여기 같이 적혀 있던 `Brand.luau`는 M2 첫
      단위에서 줄이 생겼다).
      `NoneHandler`는 배열/해시 구분 없이 `Dispatch.process(inst,k,nil,index+1)`
      **재귀만** 하고(선행 `retractFrom` 없음 — 하강 diff), 실제 정리는
      `NilHandler`(`isHandlable`이 `type(k) == "number" and v == nil`일 때만
      매치하는 말단)가 `Dispatch.setOffsetSource(inst,k,None)` →
      `Dispatch.setLength(inst,k,0)` 등록으로 맡는다(**[2026-08-31 `H-265`]**
      나열 순서를 해제 계약(offsetSource 먼저)에 맞게 정정 — 같은 문서의
      `H-39` 항목과 갈라져 있었다).
      **`Dispatch.drive`에 `None` 스킵 분기는 없다**(반응형 값이 내놓는
      `None`은 어차피 `process`에 도착하므로 — 2026-08-18 재설계) —
      `base/dispatch-core-plan.md`의 "`None` 센티널"/"`NilHandler`" 절.
      Modifier 쪽 표면(인라인 키로 필드 지우기, `Peek` 반환 타입)은 M7
- [x] **[2026-08-31 M3 단위 2 — 접두합 캐시·두 필드·재진입 게이트·되감기·배치
      게이팅까지 `spec.lengthoffset.luau` 8절 실측. 무효화 표의 splice/`rawMove`류
      자리는 그 함수들이 생기는 M6 몫, `_baseObserver` 자리도 M6(Slot 생성자)]**
      `Dispatch.setLength(ownerKey,i,len:number|State<number>,anchor?,element?)`
      (**[2026-08-27, 9라운드 Q3]** 5번째 `element` = 그 자리의 `inst|slot` —
      `gatedRecompute`가 인덱스 대신 이걸 캡처해 **`bk.indexOfElement`**를
      조회한다. 옛 `bk.tokens`/`indexOfToken`(사용자가 정한 적 없는 `token = {}`
      신원)은 폐기. 상수 길이 자리(`Nil`/`None` 핸들러)는 생략)/
      `Dispatch.setOffsetSource(ownerKey,i,offset:Source<number>|None)`/
      **`Dispatch.getOffsetAt(ownerKey,i)`** —
      **[2026-08-21 구현 전 QA 5라운드 반영]** `setLength`의 4번째 인자
      `anchor`(생명주기 앵커, 항상 물리 Instance — 부기 키와 분리, **생략 시
      `ownerKey`로 폴백**이라 최상위 호출부는 3-인자 그대로),
      `setOffsetSource`는 `None`이면 얼리 리턴(그 `None`은 "발행 채널 없음"이지
      "참여 안 함"이 아니다 — 참여 여부는 `setLength`가 답),
      숫자가 필요한 쪽(예: 물리 삽입 위치)은 `getOffsetAt`으로 pull.
      **⭐ [2026-08-24 6라운드 `H-3`/`H-4`/`H-19`] `getOffsetAt`의 접두합 캐시
      계약을 반드시 같이 구현할 것** — 이게 빠지면 형제 Slot이 커져도 뒤 형제의
      `Offset`이 **영원히 고정**된다(`sum`은 매번 새로 더하므로 위로는 맞고
      옆으로만 틀려 알아채기 특히 어렵다):
      (a) `getBookkeeping`이 `bk.offsetCache = {}`, **`bk.offsetCacheValidUpTo = 0`,
      `bk.offsetSetUpTo = 0`**, `bk.recomputeBlocker = Blocker()`,
      `bk.indexOfElement = setmetatable({}, { __mode = "k" })`(**[2026-08-27
      Q3]**, weak-key는 **[2026-08-27 `H-145`]** — 최상위 Slot 교체 시 해제
      `setLength(…, 0)`이 옛 키를 못 지우므로)으로
      초기화(`nil` 시작이면 첫 `setOffsetSource`가 `nil` 비교에서 죽는다),
      (b) **캐시를 앞으로 당기는 자리**(개수는 `base/dispatch-core-plan.md`의
      무효화 표가 소스) — `setLength` 본문과 그 자리 length가
      State일 때 다는 Observer 콜백(**두 필드 다** `math.min(…, i)`),
      `spliceArraysUp`/`spliceArraysDown`(**두 필드 다 `math.min(…, i - 1)`** —
      **[2026-08-26 정정, 8라운드 `H-113`]** 한때 `setLength`와 "같은 식"이라
      적혀 있었으나 `i`로 당기면 `recompute`의 커서가 정확히 `i`일 때
      "변경 없음"과 구분이 안 돼 되감기가 안 걸린다),
      `slot._baseObserver` 콜백
      (베이스가 바뀐 경우라 `0`), 그리고 **⭐ [2026-08-26 신설,
      `/code-review high`] `rawMove`/`rawSwap`/`rawExtract`류**(자리 수는
      그대로, 순서만 바뀜 — 두 필드 다 `math.min(…, minPos - 1)`, `H-29` 규약
      3번). **전부 `recompute`보다 먼저.**
      (c) **`recompute` 호출은 `setLength`의 단독 책임**이다 — `rawAdd`/
      `rawReplace`의 명시 호출은 삭제됐고, 자리가 없어지는 경로
      (`rawRemove`/`rawUnmount`/`rawDetach`)만 예외로 직접 부른다.
      **⭐ [2026-08-26 추가, 8라운드 `H-119`] 그 명시 호출도 재진입 게이트를
      먼저 본다** — `blocker:IsOn() or bk.recomputeBlocker:IsOn()`이면
      건너뛴다(건너뛴 몫은 splice가 당겨둔 `offsetSetUpTo`로 바깥 루프의
      되감기가 복구). 안 그러면 `Add`는 안전한데 `Remove`만 중첩 `recompute`가
      완주해 바깥의 `Length`를 낡은 합으로 덮는다. `_baseObserver` 콜백도
      같은 게이트 + **두 필드 `0`**.
      **⭐⭐ [2026-08-26 신설, `/code-review high` 4차] 부기 필드가 하나에서
      둘로 갈라졌다** — `bk.offsetCacheValidUpTo`(`offsetCache`가 여기까지
      정확, `getOffsetAt`이 올림)와 `bk.offsetSetUpTo`(offset `Source`에
      여기까지 `:Set` 완료, **`recompute`만** 올림). 옛 단일 `invalidAfter`는
      두 뜻을 겸했고, 그래서 `getOffsetAt`의 부수효과가 되감기 신호를 조용히
      지웠다. 무효화는 **둘 다** 내린다. `base/dispatch-core-plan.md`의
      "두 필드" 절이 소스.
      `recompute`는 owner의 베이스(Slot이면 자기 `.Offset`, 최상위면 0)에서
      시작하고 중첩 Slot은 자기 `Offset`을 관측해 자식 offset을 다시 민다.
      **이 셋이 하는 일**: array part 형제 순서 보장(Length/Offset 누적합→
      `LayoutOrder` 리액티브
      바인딩), array part 모든 number 인덱스에 대해 둘 다 호출 필수(생략
      UB, Handler 구현체 작성자만의 계약) — `recompute`는 leaf-lifetime
      경로(`bindLifetime`/`unbindLifetime`)로 등록, `:Subscribe()` 아님
      (2026-08-09 여섯 번째 세션, `base/dispatch-core-plan.md` "Length/Offset"
      절 — `base/slot-plan.md` "여러 Slot이 섞일 때 순서 보장" 해소).
      **[2026-08-18 구현 전 QA 2라운드 후속] `bk.N≥2`인 자리가 처음
      채워지는 동안 크래시하던 경로(`RC-1`)는 owner별 `Blocker` 게이팅으로
      해결됨** — `setLength`/`setOffsetSource`가 배치 등록 중엔
      `recompute`를 미루고 배치가 끝나면 명시적으로 한 번만 돎, 상세는
      `base/dispatch-core-plan.md`의 "배치 등록을 안전하게 만드는 Blocker
      게이팅" 절. **[정정, 2026-08-18 구현 전 QA 3라운드] 그 크래시 자체는
      `bk.N`의 정의(그때그때 실제 개수로 확정, 같은 문서 "저장 위치" 절)가
      바뀌며 사라졌음** — 지금 이 두 함수 구현이 여전히 `Blocker`
      (`:On()`/`:IsOn()`/`:OffWithoutEmit()` 세 메서드 + 그 인스턴스를
      lazy 조회하는 Dispatch 쪽 헬퍼 `getBlocker(ownerKey)`)를 호출하는 이유는
      크래시 방지가 아니라 배치 등록 비용(O(N²)→O(N)) 절감.
      **[2026-08-24 정정] 그래서 필요한 `GateNode`/`Blocker`/`EpochMap`은
      M2(반응형 코어)에 체크박스로 있다** — 2026-08-22엔 각주로만 예고돼
      있던 걸 이 마일스톤으로 앞당겼었는데, 같은 달 24일 마일스톤 순서
      교체로 M2가 먼저 지어지게 되면서 셋 다 그리로 되돌아갔다(앞당길 이유가
      사라짐). 여기서는 **M2가 이미 만들어둔 것을 호출하기만 한다.**
      결정 경위("게이팅 먼저", 그리고 앞당기는
      대상이 `Blocker` 자체가 아니라 그 아래 공용 `Gate` 노드로 바뀐 것)는
      `qa-request/pre-implementation-qa-round5-followup.md`와
      `base/gate-plan.md`가 소스 — 여기서 반복하지 않는다.
- [x] **[2026-08-31 M3 단위 1]** 핸들러 계약 검증: `process`가 retractor 클로저를 **반환하지 않는**
      핸들러를 등록하면 리뷰/린트에서 걸러내기(정리할 게 없어도 항상
      `Void`(**[2026-08-28 `H-162`]** 단일 no-op)를 반환 — `Dispatch.retractFrom`이 nil 체크 없이
      호출, `base/dispatch-core-plan.md` "핸들러 계약" 절, 2026-08-08 세션
      / **2026-08-13 다섯 번째 세션에 별도 `retract` 필드가 `process`
      반환값으로 합쳐지며 대상만 바뀜**)
- [x] **[2026-08-31 M3 단위 1 — 같은 날 `H-214` (a) 사용자 확정으로 계약에
      선택 필드 `name: string?`(진단 전용)이 추가돼 목록의 "이름"도 닫힘,
      `listHandlers`는 핸들러 객체 배열(사본) 반환]** 우선순위 동률/매치 실패 처리(2026-08-12 열일곱 번째 세션 확정,
      `base/dispatch-core-plan.md` "우선순위 동률/매치 실패 처리" 절) —
      `HANDLER_PRIORITY_HIGH`/`_NORMAL`/`_LOW`/**`_FALLBACK`**(base 제공
      핸들러의 기본 밴드 — 백엔드가 평범한 우선순위로 자기 핸들러를
      등록하면 언제나 이김, 2026-08-13 열네 번째 세션 신설) 등 목적별 상수,
      매치 실패(`isHandlable`을 만족하는 핸들러 없음)는 `Brand`+`typeof(v)`
      출력 후 즉시 error(provider 초기화 확인 안내 포함 — provider
      미주입 상태도 이 경로로 자동 커버, `pre-implementation-audit.md`
      1-3/1-4), 핸들러 등록/정렬 시점 동률 감지 print 경고 +
      `Dispatch.listHandlers()` 디버그 유틸. **[2026-08-18]** 동률 경고는
      무조건 찍지 않고 **모듈 표면의 `Quad.debug`(boolean, 기본 `false`)가
      참일 때만** — `Quad.debug` 자체가 이번에 신설된 새 공개 표면이다
      (`base/module-lifecycle-plan.md`의 "모듈 표면의 디버그 플래그" 절)
- [ ] children-array leaf 매칭 Handler들 — `(i:number, v=Ref/Observer/
      Effect/PreRef/PostRef)`, quad-base 소속(2026-08-08 두 번째 세션).
      **⚠️ [2026-09-01 `H-278` 사용자 확정 — 파일 배치 역전]** 옛 확정지
      `Dispatch/Leaf.luau`는 해체됐다 — 등록 소유는 **각 값의 선언 모듈**
      ("각 객체를 아는 곳은 각 객체가 선언된 곳"): Observer/Effect 몫
      (`ObserverLeafHandler`/`EffectLeafHandler` + 가드 둘)은
      `Observer.luau`/`Effect.luau`의 `registerDispatchHandlers`로 **구현
      완료**(아래 단위 4 항목들), 남은 것은 `Ref`/`PreRef`/`PostRef` 몫이
      **`Ref.luau`에** 합류하는 것(M8 — `base/ref-plan.md`)뿐이라 `[ ]` 유지
- [x] **[2026-08-31 M3 단위 1]** `chains`(Relate 기반, `{[inst(weak)]={[k]={[index]={handler, retractor}}}}`
      — **재귀 깊이 인덱스 → (담당 핸들러, 그가 반환한 retractor 클로저)**) +
      **3-인자** `Dispatch.retractFrom(inst,k,index)` — 재귀 재-dispatch
      (StoreBind/NoneHandler)의 정리를 다단 체인까지 정확히 전파(2026-08-08
      신설 → 2026-08-13 다섯 번째 세션 인덱스화 → **같은 날 열네 번째 세션
      하강 diff로 전면 교체**, `base/dispatch-core-plan.md` "Dispatch 체인"
      절, `pre-implementation-audit.md` 1-2번 "이전 핸들러 추적" 항목 해소).
      **구현 시 반드시 지킬 것**:
      - **재디스패치는 하강 diff** — 래핑 핸들러는 선행 `retractFrom`을
        부르지 않고 그냥 `Dispatch.process(inst,k,realv,index+1)`. 비교는
        `Dispatch.process` 안에서: 슬롯의 `handler`가 같으면 그 자리
        클로저에 새 값을 넘긴 뒤 같은 핸들러의 `process`로 자리 교체,
        다르면 `retractFrom(inst,k,index)` 후 새로 설치
      - `chains:SetStrong(inst,k,list)`는 `handler.process` 호출 **전에** —
        뒤에 두면 재귀 위임이 자기 테이블을 만들었다가 바깥이 덮어써
        하위 retractor가 통째로 유실됨(2026-08-13 감사에서 잡힌 버그)
      - 새 자리를 여는 (B) 분기에선 `handler.process` 호출 전에 no-op
        점유 마커를 박아 `list`를 구멍 없는 시퀀스로 유지(hole 있는
        테이블의 `#`는 Lua가 보장 안 함)
      - `process`가 `nil`을 반환하면 (A)/(B) 양쪽에서 즉시 error
      - 다른 키로 위임할 땐 항상 `index=1`, 같은 키 재귀는 `index+1`;
        `Dispatch.drive`의 진입도 항상 `1`
      - **소유권 충돌 감지는 Dispatch의 일이 아님**(옛 점유 error 폐지) —
        필요한 도메인이 직접(Attribute 이름 claim, M10)
- [x] **[2026-08-31 M3 단위 4 — FALLBACK 가드 둘(`H-278`로 등록 소유가
      `Observer.luau`/`Effect.luau`로 이동), `spec.leaf.luau` 6·7이
      메시지·override 의미론 실측]**
      **[2026-08-24 M2에서 이동] Observer/Effect 동적 경로 가드 등록** —
      `{priority = HANDLER_PRIORITY_FALLBACK, isHandlable = v가
      Observer/Effect, process = error(...)}` 둘을 `Dispatch.addHandler`로
      등록(`k` 타입 안 가림, `PreRef`와 같은 패턴 —
      `base/source-state-plan.md`의 Observer 절, `base/effect-plan.md`의
      "동적 경로 가드" 절). **M2에서 Observer/Effect 본체를 짤 때는 이 등록만
      빼고 간다** — 레지스트리(`Dispatch.addHandler` + `Handler.luau` 계약)가
      이 마일스톤에서 생기기 때문. **M2가 M3에 개념상 지던 의존은 이 항목과
      바로 아래 항목뿐이었고, 둘 다 "핸들러를 등록한다"뿐이라 이쪽으로 미룰
      수 있었다** — 그래서 빌드 순서엔 역방향 간선이 남지 않는다.
      순서 교체(2026-08-24)의 근거
- [x] **[2026-08-31 M3 단위 4 — HIGH 밴드("base 소속 핸들러가 전부 여기
      오는 게 아님"의 `Leaf`), `old ~= v` dedup + `H-57` 값 교체 cleanup
      소진까지 — `spec.leaf.luau` 1~5; `H-278`로 소유가
      `Observer.luau`/`Effect.luau`의 모듈별 핸들러 둘로 이동]**
      **[2026-08-24 M2에서 이동, `H-39`]** `ObserverEffectLeafHandler.process`가
      자기 배열 자리의 `setOffsetSource(inst,k,None)`/`setLength(inst,k,0)`을
      등록 — 빠져 있었다(위 말단 핸들러 항목)
- [x] **[2026-08-31 M3 단위 4]** mock 대상 테스트 — `spec.integration.luau`
      4절(혼합 drive 한 트리 / 자리 타입 교대와 오프셋 이동 / Destroy는
      retract 없이 발화만 멎음 / `H-229` GC end-to-end)

## M4 — 첫 end-to-end 반응형 업데이트

> **✅ [2026-08-13 열네 번째 세션] 재디스패치 모델 교체 완료** — 아래
> 항목은 `base/dispatch-core-plan.md`의 하강 diff 기준으로 읽을 것.


- [x] `Dispatch/StoreBind.luau`(재귀 재실행 로직, 엔진 무관 — **선행
      `retractFrom` 없이** `Dispatch.process(inst,k,realv,index+1)` 한 줄
      (2026-08-13 열네 번째 세션 하강 diff), 반환 클로저는 자기 Observer
      구독만 해제. `base/dispatch-core-plan.md` "Dispatch 체인" 절)
      **[2026-09-01 완료, M4 round13]** — 정본 절 의사코드 그대로, 등록은
      `InitDispatch` 꼬리(`None.luau` 선례 — round13 §0 Q3 (a)), 우선순위
      HIGH 밴드. quad-types 갱신 없음 확인(공개 표면 아님 — `H-25` 이번 몫)
- [x] mock 대상으로 "store 값 바꾸면 `process`가 다시 호출된다" +
      "이전 값이 다른 타입이면 이전 `process`가 반환했던 retractor 클로저가
      정확히 불린다" 확인 + **`State<State<T>>`(값이 또 State/Source)가
      인덱스 N/N+1로 안 겹치고 정상 동작하는지**(2026-08-13 다섯 번째
      세션에 UB→정상 지원으로 재정정) + **최초 마운트 직후 첫 재발행에서
      인덱스 2의 retractor가 실제로 불리는지**(위 M3의 `SetStrong` 순서
      버그가 정확히 여기서 증상으로 나타남).
      **[2026-08-31 `H-215` (a)]** 이 항목이 폐기된 스파이크 `04`의 잔여
      몫도 진다 — M3 단위 1 `spec.dispatch.luau`는 재귀 재발행을 로컬
      wrapping 핸들러로 근사했으므로, **실제 `StoreBind` 경유** 재발행에서
      깊은 인덱스부터 정리되는 것까지 여기서 실측할 것.
      **[2026-08-31 보강, 리뷰 지적]** 순서 단언만으로 닫지 말 것 — `04`가
      존재 이유로 명시했던 **효과 수준 검증**(retractor가 로그가 아니라
      실제로 옛 store 구독을 끊는다: 재발행 후 옛 store 구독 0, 죽은
      store를 건드려도 값이 안 덮인다)까지 단언해야 잔여 몫이 닫힌다
      **[2026-09-01 완료, M4 round13]** — `spec.storebind.luau` 6절: 위 전
      항목 + 효과 수준(구독 0은 GC 후 `_subs` 계수, 죽은 store `Set` 불덮임)
      + 스파이크 `03` 몫(배열 자리 `None`→`nil` 핸드오프·재귀 종료·부기
      반응형 이동, §0 Q4 (a)로 `03` 폐기 — `luau-test/STATUS.md`가 소스)

## M5 — quad-roblox 최소 프로바이더

> **[2026-08-21 5라운드] 주입 표면이 늘었다 — `native*` 물리 트리 조작 계층.**
> `nativeInsert`/`nativeExtract`/`nativeRemove`/`nativeMove`/`nativeSwap`/
> `nativeDispose`. base가 `Parent`를 모른다는 원칙을 실제로 지키기
> 위한 것이고, **미주입이면 에러가 아니라 조합 폴백**이라 최소 구현 부담은
> `nativeInsert`/`nativeExtract`/`nativeDispose` 셋이다(나머지는 이득 있을 때만
> 덮어씀 — Roblox는 `nativeRemove`를 "그 자리에서 바로 `Destroy`"로 융합하는 게
> 실익). 상세는 `base/slot-plan.md`의 "물리 조작은 주입 op다" 절.
>
> **⚠️ [2026-08-24 정정, 6라운드 손 트레이싱 `H-34`/`H-44`] 위 "최소 구현 부담은
> 셋" 서술을 좁힌다 — Roblox 백엔드는 `nativeMove`/`nativeSwap`도 반드시
> 덮어써야 한다.** 조합 폴백(`nativeMove` = `nativeExtract` + `nativeInsert`)은
> 여기선 "느린 정답"이 아니라 **관측 가능한 동작 차이**를 만든다:
> `Move`/`Swap`을 공개 CRUD에 추가한 근거 자체가 *"`Extract`+`Add`는 실제
> Parent 조작이 두 번(detach+reattach) 일어남"*을 피하려는 것이었는데, 폴백은
> 정확히 그 두 번을 되돌려 `AncestryChanged` 재발화·깜빡임·재바인딩 비용을
> 다시 만든다. offset을 무시하는 백엔드에서 순서 이동은 애초에 물리 조작이
> 아니므로 **no-op으로 덮어쓰면 된다.**
> 그리고 **주입 op이 둘 더 늘었다**(6라운드) — **`isInst`**(`H-40`): 요소 타입
> 검증을 화이트리스트로 뒤집으면서 생긴 판정 술어, 조합 폴백이 불가능해
> **미주입이면 에러**다(quad-roblox 구현은 `typeof(v) == "Instance"` 한 줄).
> **`onDestroying(inst, fn)`**(`H-11`): `Effect`의 leaf 사망 cleanup을 발화시키는
> 훅으로, `bindLifetime`이 `isEffect`일 때 부른다(quad-roblox 구현은
> `inst.Destroying:Connect(fn)`). 이것도 조합으로 못 만들므로 미주입이면 에러다.
> **[2026-08-28]** 셋째·넷째로 **`nativeFindChild(inst, key)`**(`Claim`의 조회 op,
> 예외 분류는 에이전트 판단)와 **`nativeClaim(inst)`**(gcconn/gchold 셋업의 유일한
> 자리 — `New` ②단계도 이걸 부른다, 사용자 확정) — 아래 `Claim` 체크박스·
> `base/claim-plan.md` §7-9. 전체 목록의 소스는 `base/architecture.md`.

> **⚠️ 구현 관례**: `quad-roblox`의 공개 타입은 지금부터 단일 파일
> (`src/init.luau` 또는 `types.luau`)에 몰아둘 것 — 나중에 필요해지면
> 백로그 `quad-roblox-types`(가칭, `quad-types`와 같은 패턴)로 쉽게
> 분리할 수 있게 하기 위함. `base/quad-types-plan.md`의 "남은 것" 절이
> 소스.

- [x] `RobloxFactory.luau`(BaseModule 뮤테이션, 재호출 가드) — 진입점
      `QuadRoblox(Quad): QuadRoblox`가 `QuadTypes.CheckedQuad<T, Pattern>`으로
      주입받은 quad-base 버전을 확인(`base/quad-types-plan.md` 참고)
      **[2026-09-02 완료, M5 단위 ① round14]** `_initializedBy` 가드(같은
      팩토리 no-op/다른 팩토리 error) + LifetimeHandle·EngineOps 설치 +
      `H-238` SURFACE 태그. M5 몫 EngineOps(native* 여섯 — Roblox는
      `nativeMove`/`nativeSwap` no-op 덮어쓰기, `isInst`/`onDestroying`/
      `nativeFindChild`; Q4 (a)로 Tag/Attribute/setTimeout은 M10·백로그
      몫 그대로 미설치)와 생명주기 4종 실구현까지 이 단위 —
      `quad-roblox/test/spec.robloxfactory.luau` + Studio 스모크 14/14
      (발견 `H-290`/`H-291`은 round14가 소스)
- [x] `D/init.luau`(제네릭 생성자 `New` + 생성기가 찍는 정적 별칭 필드 — **[2026-08-18]** 범위는 "GUI에 쓰이는 모든 인스턴스", 이벤트 필드의 콜백 타입까지 생성, `base/bind-system-plan.md`의 "인스턴스 생성 / 이벤트 네이밍 인체공학" 절). **[2026-08-27 9라운드 `H-142`] 생성되는 props 타입에서 `Parent`를 제외할 것** — props에 `Parent`는 올 수 없다(부모가 하는 일, 같은 문서의 파이프라인 절). `New` ①~④ 순서는 그 절의 의사코드가 소스
      **[2026-09-02 완료, M5 단위 ② round14]** `scripts/gen-d.py`(§4
      `H-295`~`H-297` (a) + `H-301` 실측 보강) → 정규화 산출물
      `quad-roblox/dump/api-surface.json` + 생성 `D/init.luau`(클래스 목록·
      개수는 그 json이 소스), 값 유니언 정본은 bind-system-plan 신설 절
      (`H-298`; `None`도 합류 — `H-300` (a) 확정·반영, 센티널 마커 필드 → `QuadTypes.None`). `Parent`는
      덤프 층 제외 + `test.sh` grep 게이트. `spec.d.luau` + Studio 실생성
      전량 확인. `D`는 `RobloxFactory`가 `module.D`로 설치(`H-299`)
- [ ] `Handlers/Property.luau`(**[2026-08-27 9라운드 `H-142`]** `isHandlable`이 `"Parent"` 키를 **거부**한다 — 매치 핸들러가 없어지면 `Dispatch.process`의 "매치 핸들러 없음 → 즉시 error"에 걸리는 것으로 런타임 가드가 공짜로 생긴다, 새 메커니즘 없음. **사용자 확정은 "props에 `Parent` 금지"라는 규칙이고, 이 거부 배선은 에이전트 선택** — `base/bind-system-plan.md`의 `H-142` 항목이 그렇게 갈라 적음. **[2026-08-28 10라운드 `H-148`]** 전용 문구는 **철회**(일반 매치 실패 그대로). 루트 부착 경로가 무엇인지는 아래 `Claim` 체크박스가 소스), `Handlers/InstanceChild.luau`(**[2026-08-28 `H-154`]** retractor 첫 줄 `if nextValue == v then return end` — 같은 값 재발행 dedup, `SlotHandler` 동형) —
      **⭐ [2026-08-27 9라운드 `H-134`] `InstanceChildHandler`도 말단이라
      부기를 등록한다**: `process`에서 `setOffsetSource(inst, k, None)` →
      `v.Parent = inst` → `setLength(inst, k, 1, inst)`(정적 단일 자식은 상수
      `1`, 5번째 인자 없음). 반환 클로저는 `v.Parent = nil`(내리기만, 파괴
      아님) → `setOffsetSource(inst, k, None)` → `setLength(inst, k, 0)`.
      **[2026-08-27 `/code-review` 정정]** 옛 순서(`setLength` → `Parent`)와
      "5번째 인자 `v`"는 틀렸었다 — 근거는 `base/dispatch-core-plan.md`의 그
      문단. 빠뜨리면
      `Frame { Frame{}, Slot() }`이 첫 마운트에서 죽는다 —
      `base/dispatch-core-plan.md`의 `H-39` 블록(그 다섯째 항목)이 소스.
- [ ] **[2026-08-28 M5 스코프, `H-161`; 같은 날 갈래 전량 확정]** `Claim(inst, D.Mapper.<Class>(key) {…}) -> inst` — 이미 있는 트리(PlayerGui·`Clone()` 사본·Studio GUI)를 quad가 소유(`base/claim-plan.md`가 소스, 구현 체크리스트는 그 §9). 요지: `drive` 위의 한 겹(DFS 이름 해석 → bottom-up `drive`), 매핑된 자식은 `InstanceChildHandler` 그대로(별도 핸들러 없음), 루트 키 센티널 `D.Mapper.Root`, `type <Class>Param`을 `D.<Class>`와 공유, `Claim`은 타입 인자 없음, 같은 `inst` 이중 claim error, `Processed` 소진. 프로바이더 op **`nativeFindChild(inst, key)`**(조회라 조합 폴백 예외 — 미주입이면 error). **루트 부착의 흔한 경로는 이게 아니라 밖에서 `.Parent =`** — 루트의 `Parent`는 부기 밖이라 허용(`base/claim-plan.md` §5가 소스; 10라운드 `H-148`에서 한때 "루트도 `Claim`으로만"으로 폐기됐다가 같은 날 복원). **[같은 날 후속]** `/code-review`가 낸 문항 넷도 확정(`base/claim-plan.md` §7-9~12): gcconn/gchold 셋업은 주입 op **`nativeClaim(inst)`**에만(`New` ②단계도 호출) / 이중 claim은 그 셋업 유무로 error(레지스트리 없음) / **`PlayerGui`류 공동 소유 컨테이너는 claim 대상 아님**(루트는 `ScreenGui`·`SurfaceGui`) / `D/init.luau` 생성기는 `type <Class>Param<E>`(원소 타입 파라미터)를 `D.<Class>`·`D.Mapper.<Class>`가 공유하도록 찍는다 — `luau-analyze` 스파이크 필요.
- [ ] **Instance 생성 시점의 gcconn/gchold 셋업**(2026-08-14 다섯 번째 세션
      확정, 옛 "`bindLifetime` 첫 호출에서 lazy 생성"에서 전환 — `base/
      lifecycle-pattern.md`의 "(0) gcconn/gchold는 Instance 생성 시점에
      만든다" 절) — quad가 만든 모든 Instance에 대해 **핸들러/바인딩 유무와
      무관하게 생성 직후 무조건** `GetPropertyChangedSignal("ClassName")`
      연결(절대 발화 안 함)로 gcconn을 만들고 `gchold[1]=gcconn`,
      `InstData:SetWeak(inst,"gchold"/"gcconn",...)`. **클로저가 `gchold`와
      `inst`를 둘 다 캡처해야 함** — Instance userdata 포인터 동일성을
      고정하는 게 목적이고, 그래야 `inst`를 키로 쓰는 모든 `Relate`
      (`elementOwner`/`nameClaims`/Tag 참조카운트 등)가 성립함. 대가는
      "quad가 만든 Instance는 참조를 놓는 것만으로 회수되지 않고 반드시
      `Destroy`가 필요" — 바인딩이 하나라도 걸리면 어차피 같은 순환이
      생기므로 실질적 신규 제약은 아님. **[2026-08-28 `Claim` §7-9]** 이
      셋업은 `New` 안 인라인이 아니라 **주입 op `nativeClaim(inst)`의 본체**로
      구현한다 — `New` ②단계와 `Claim`(이미 있는 트리, 위 체크박스)이 같은
      op를 부르고, 이미 셋업된 inst면 error(이중 claim 판정). 사용자 확정
      *"gchold/gcconn 경로를 여기에 전부"*.
      **[2026-09-02 op 자체는 완료 — 단위 ①]** `nativeClaim` 구현·이중
      claim error·미claim `bindLifetime` fail-fast(`H-290`)까지
      `quad-roblox/src/LifetimeHandle.luau`(본체 배치 사유는
      `architecture.md` 그 줄). **이 체크박스의 잔여는 "`New` ②단계가 이
      op를 부르는 배선"**(단위 ②의 `D` 생성기 몫)이라 체크는 그때 —
      스모크로 실물 검증까지 끝난 상태.
- [ ] 실제 Roblox에서 첫 `Frame{...}` 렌더 확인 — Studio 작업, `SAFETY.md`
      준수. **[2026-09-01 게이트 해소]** 여기 걸려 있던 선행 조건
      (`HUMAN_TODO.md` 1번 계정 분리)은 충족됐고, MCP `execute_luau`로
      에이전트가 직접 확인할 수 있다(스파이크 `10` 완주가 선례 —
      `audit/spike10-full-run-2026-09-01.md`. gcconn/`nativeClaim` 실기기
      전제도 그 완주가 미리 닫아둠)

## M6 — Slot

> **✅ [2026-08-13 열네 번째 세션] 재디스패치 모델 교체 완료** — 아래
> "`SlotHandler.process`는 claim 실패 시에도 파괴적 클로저를 반환해야 함"
> 항목은 새 모델에서도 그대로 유효함(체인은 클로저를 early-return
> 여부와 무관하게 항상 소비 — `base/dispatch-core-plan.md`의
> "Handler 작성 체크리스트" 1번). 클로저가 받는 값이 항상 `Slot`이거나
> `nil`임이 계약으로 보장된다는 점만 새로 추가됨.

### 확정된 것 — 코드 아님, 구현 전 필독

아래는 **설계가 확정됐다**는 사실이지 짠 코드가 아니다 — 체크박스로
두면 `[x]`가 "구현 완료"와 구분이 안 돼서 문서 머리 규약대로 분리했다
(**[2026-08-22]**).

- **"여러 Slot이 형제로 섞일 때 순서 보장" 해소**(2026-08-09 여섯 번째
  세션) — `Dispatch.setLength`/`setOffsetSource` 메커니즘, `base/
  dispatch-core-plan.md` "Length/Offset" 절. `Slot.Length: State<number>`도
  이때 확정(CRUD/`:List` 여부 무관 항상 노출, 순서 계산과 "n개 검색됨"
  UI 둘 다 겸함) — 구현 시 이 두 API를 `:List`/CRUD의 `raw*`가 호출.
  **`recompute` 트리거 모델의 크래시(`RC-1`)는 Blocker 게이팅으로
  해결됨**, 위 M3의 `Dispatch.setLength`/`setOffsetSource` 항목 참고.
- **Slot의 `Add`/`Remove`/`Extract`/`ExtractAll`/`Clear`/`Move`/`Swap`/
  `Get`/`IndexOf`/`Splice` CRUD 의미론 확정** (2026-08-09 세 번째 세션,
  2026-08-09 열한 번째 세션에 식별 기준 재정정, `Splice`는 2026-08-12
  열다섯 번째 세션 신설 — **[2026-08-13 5차 감사에서 추가] `Splice`가
  이 체크리스트에 누락돼 있었음, `luau-test/20`으로 산술 실측 통과됨**)
  — 에러 조건까지 전부 확정
  (`base/slot-plan.md` "CRUD API 확정"). "재마운트 시 즉시 throw"도
  `isMounted` 이중 추적 분리로 개별 element/Slot 컨테이너 기준이
  명확히 갈림(같은 문서 "`isMounted` 이중 추적 분리" 절).
  **[정정, 2026-08-09 열한 번째 세션] 식별 기준을 element 레퍼런스에서
  인덱스 기준으로 전환** — `Remove(index)`/`Extract(index, newElement?)`
  (O(n) 또는 O(1))/`Move(oldIndex, newIndex)`(O(n))/`Swap(indexA,
  indexB)`(O(1)) 전부 인덱스, `Add(element, index?)`만 element를 직접
  받음(새로 넣는 대상이라 참조가 당연히 있음). 호출부가 `Add` 리턴값을
  안 담고 흘려버리는 경우가 흔해 레퍼런스 기준이 오히려 실사용과 안
  맞았음 — 레퍼런스만 있으면 `IndexOf(element): number?`로 인덱스를
  구하면 됨. `ExtractAll(): {T}`(Clear의 비파괴 버전), `Get(index): T?`
  신설(`get`/`set` 드롭했던 걸 재추가). `Extract(index, newElement?)` —
  `newElement` 지정 시 O(1) 제자리 교체(이전 element 반환), 기존엔
  교체하려면 Extract+Add 이중 O(n) 시프트가 필요했던 문제 해결. 공개
  mutate 메소드 전부 "가드 확인 + `raw*` 위임" 얇은 wrapper(`Get`/
  `IndexOf`는 순수 읽기라 가드 대상 아님).
  **[2026-08-21 5라운드]** `Replace(index, newElement)` 추가(그 자리 교체
  + 이전 것 **파괴** — `Extract`의 파괴 짝, `Remove` ↔ `Extract`와 같은 축)와
  `rawReplace`/`rawAdd` 의사코드 확정, 그리고 **래핑/언래핑 한 쌍**
  (`State`를 요소로 받으면 내부적으로 `:Single` 래퍼 Slot이 되는데,
  `Get`/`IndexOf`/`Extract`가 돌려주는 값과 `:List`의 `prev`는 전부
  **언래핑된 원래 값**이다). base/roblox 경계에
  mount/unmount 외 reposition 훅 추가됨. **`Slot<T>()` 제네릭화, 요소
  타입 제약 확정** — **[2026-08-24 6라운드 `H-40`로 전면 정정] 판정은
  블랙리스트가 아니라 화이트리스트다**: `isSlot` → `isState`(래퍼 Slot으로
  풀어 재귀) → **주입 술어 `isInst`**, 셋 중 어디에도 안 걸리면 error.
  관문은 `wrapElement` 하나(공개 CRUD와 `:List`의 `settle`이 둘 다 지난다).
  아래 나열은 이제 **그 화이트리스트의 따름정리**다(에러 메시지는 계속
  구분해 낸다) — `nil`/`None` 둘 다 raw 요소로 금지(Slot 안엔
  실제 마운트 가능한 `T`만), 핸들러 계층 값(Ref/PreRef/Observer/
  Effect/Modifier)은 self-ref 컨텍스트가 없어 의미 불성립이라 즉시
  error(`Modifier` 필드와 같은 판별 메커니즘 재사용) — `D.InstSlot =
  Slot<<Instance>>`(**[2026-08-18]** `D` 네임스페이스 이름 확정 —
  옛 `question.md` 1번 용어정리 항목은 해소되어
  `archive/question-resolved.md`로 이전됨)가 quad-roblox의 사실상 유일한
  Slot 타입.
- **`Slot:Single(state, updateFn?, opts?)` 확정** — (**[2026-08-26 표기 정정,
  8라운드 `H-123`]** 3번째 `opts`(= `Owned`)는 `H-22` 확정 의사코드가 받아
  `:List`로 전달한다 — 여기와 아래가 2-인자 표기로 남아 있었다.)
  `:List`를 0/1개짜리
  배열로 감싸는 순수 sugar, `index` 없이 `offset`/`prev`/`userdata`만
  전달, 고정 key로 `prev` 재사용 보장(2026-08-11 세션, `base/
  slot-plan.md` "`Slot:Single`" 절). **[2026-08-11 일곱 번째 세션]**
  `updateFn`이 선택 인자로 완화됨(기본값 identity) — 아래 반응형
  raw 요소 항목 참고.
- **Slot-in-Slot 중첩 확정** — 요소 타입 제약에서 `Slot` 배제 해제
  (`T = Instance | Slot<Instance>`, 자기 참조 제네릭은 실측 필요).
  `Dispatch.setLength`/`setOffsetSource`를 물리 inst 대신 **Slot
  자신을 owner 키**로 재사용하는 재귀 `attachSlot`으로 최상위/중첩
  마운트 통합(새 프리미티브 없음). `Slot.Length`가 raw 개수에서
  "요소별 기여도의 합"으로 의미 변경. 파괴는 재귀적 `Clear()`가
  아니라 flat `destroySlotTree`(파괴 walk + `unbindLifetime` walk,
  outer 쪽 recompute는 1회만) — 물리 target이 살아있는 채로 논리
  서브트리만 죽는 경우 명시적 `unbindLifetime` 필요(GC-native 정리의
  예외 케이스). DOM 백엔드가 nested Slot을 실제 `<div>` 중첩으로
  매핑하는 안은 기각(Fragment와 같은 이유로 wrapper-less 유지 필요) —
  숫자 기반 메커니즘이 web에도 그대로 필요하나, `insertBefore`/
  `removeChild`가 물리적으로 밀고 당겨줘서 이미 배치된 형제 재작성은
  불필요(2026-08-11 세션, `base/slot-plan.md` "Slot-in-Slot 중첩" 절).
  **[2026-08-21 5라운드]** 그 web 경로가 실제로 삽입 위치를 알 수 있도록
  물리 조작이 **`native*` 주입 op 계층**으로 정리됐고(M5 배너가 목록,
  시그니처는 `base/slot-plan.md`의 "물리 조작은 주입 op다" 절 —
  **[2026-08-22 정정]** 여기 확정 전 가칭 `mountInst`/`unmountInst`/
  `disposeInst`가 남아 있었음), 중첩 offset이 부모 베이스를 못 받던 결함과
  재마운트가 `Offset` Source를 새로 만들던 결함도 같이 수정됐다.
  **`recompute` 트리거 모델의 크래시(`RC-1`)는 Blocker 게이팅으로
  해결됨 — 위 M3의 `Dispatch.setLength`/`setOffsetSource` 항목
  참고(`base/slot-plan.md` "재귀 메커니즘" 절).**
  **[재설계, 2026-08-21] `attachSlot`은 비공개 재귀 둘로 분해됨** —
  `materializeSlotTree`(부기만, Blocker가 감싸는 건 이제 여기뿐) +
  `mountSlotTree`(물리 `Parent` 대입만, Blocker 불필요), 그리고 그 둘을
  순서대로 부르는 **두 줄짜리 공개 `attachSlot`**(이름/시그니처/호출부
  전부 그대로). 이걸로 "부모에게 알리는 길이가 최종값"과 "부기가 물리보다
  먼저"가 처음으로 **동시에** 만족되고, 배치 밖 재마운트의 부모
  `recompute`가 2회→1회로 준다. 순서 제약이 줄 순서가 아니라 **함수
  경계로 강제**되므로 `RC-1`/`RC-3`/`RC-4` 같은 "줄 순서를 잘못 잡아서"
  나던 버그 클래스가 구조적으로 사라짐. 근거 기록은
  `reference/slot-attach-decomposition.md`.
  **관측 가능한 변화 하나**: `Parent` 대입 순서는 그대로지만 물리 마운트가
  "부기 완료 후 일괄"이 되어, `ChildAdded` 핸들러가 볼 때 서브트리 전체의
  `Length`/`Offset`이 이미 최종값이다(옛 코드는 미완성 스냅샷을 보여줬음).
- **`Slot(initial?: {T})` 생성자로 확장** — "인자 없는 빈 생성자로
  확정"을 뒤집음, `:Add` 반복 호출 sugar일 뿐(새 마운트 로직 없음).
  `initial ~= nil`이면(빈 테이블도) 즉시 `_crudUsed = true` — 상태상
  `Add→Remove`와 동일하므로. **`_crudUsed` ↔ `_listed` 상호 배타
  가드 신설** — 기존엔 `:List` 설치 후 수동 CRUD만 막았지 반대(수동
  CRUD 후 `:List` 설치)는 안 막아서 `:List`의 reconcile이 기존
  요소를 모른 채 충돌하는 gap이 있었음(2026-08-11 세션, `base/
  slot-plan.md` "CRUD API 확정" 절).
- **`recompute` off-by-one 버그 수정**(2026-08-11 세션, `base/
  dispatch-core-plan.md` "Length/Offset" 절) — `sum` 누적과
  `offset:Set` 순서가 뒤바뀌어 `Offset`이 자기 자신을 포함해버리던
  버그(예: 유일한 자식인데도 `Offset`이 0이 아니게 됨) 수정. 재진입
  방지 가드는 검토 후 기각 — 각 Slot이 `Relate(자기 자신)`으로
  독립된 `bk`를 가져서 nesting만으로는 같은 `bk`가 재진입되는 경로
  자체가 없음이 재추적으로 확인됨. 진짜 재진입(부작용이 recompute
  도중 같은 Slot의 length에 다시 쓰기)은 `Source⊇State`의 "단방향"
  원칙과 같은 카테고리의 위반으로 **명시적 UB 명명**(방어 로직 없음,
  기존 "일반적 재진입 방어 안 함" 원칙과 정합). `offset`/`sum`은
  0-based 개수, `index`는 1-based Lua 관례라는 것도 명시.
- **반응형 raw 요소 — `State<T>`/`Source<T>`도 Slot 요소로 허용**
  (2026-08-11 일곱 번째 세션, 같은 세션에 정정) — `Slot:Add`가 받는
  실제 타입은 `T | State<T> | Source<T>`(임의 깊이 조합 가능).
  **[정정] 최초 검토한 "position-keyed StoreBind 구독 + Length를
  Compute로 파생" 안은 기각**(nilable 지원하려면 배열 파트 `None`을
  다시 끌어들여야 하고, Length 계산에 예외가 생기고, `Move`/`Swap`이
  인덱스-구독 동기화 부담을 짐 — `:List`가 element 아닌 `key` 기준인
  이유와 정면 충돌) — **새 메커니즘 없이 순수 `:Single` sugar로
  확정**: `isState(element)`면 그 자리에 내부적으로 `Slot():
  Single(element)`(updateFn 생략 시 identity 기본값)를 대신 삽입.
  `_elements`엔 `None`이 절대 안 들어감(비어있는 nested Slot이 자연히
  Length 0 기여), raw 직접 전달 요소에만 여전히 non-nil 요구.
  `:Single`의 `updateFn`도 이 sugar가 성립하도록 선택 인자로 완화
  (`Slot:Single(state, updateFn?, opts?)`, 기본값 identity). `:Single`/`:List`와는
  대체 관계가 아니라 같은 메커니즘 위의 다른 `updateFn`일 뿐 — raw
  `State<T>` 요소(identity)는 coarse swap, `updateFn` 직접 지정 시
  `prev`/`userdata` patch-reuse + `offset` 접근(`:Single`이 애초에
  생긴 이유). **부수 발견(사용자)**: `:List`의 `reconcile`이
  nested-Slot 결과를 반환하는 아이템 다음 형제의 `index`가 그 결과의
  물리 개수만큼 건너뛰어야 함 — 안 그러면 멀티루트 아이템 다음 형제의
  LayoutOrder가 겹침. `base/slot-plan.md` "반응형 raw 요소" 절.
  **⚠️ [2026-08-24 6라운드 `H-2`] 그 의도를 구현하던 옛 공식
  (`pos = candidateIndex - 1 + (isSlot(result) and result.Length:Get() or 1)`)은
  폐기됐다** — 두 좌표계(리프 개수 / `_elements` 자리)를 한 변수에 겹쳐 써서
  `table.insert(t, 0, x)`로 조용한 영구 고아를 만들었고, `.Length`를 읽는
  시점이 **항상 0**(마운트 전이라 `recompute`가 아직 안 돎)이라 애초에
  아무것도 반영하지 못했다. 확정된 해법은 배열 자리를 `slotPos`로 따로 세고
  `updateFn`의 `index`는 **`Dispatch.getOffsetAt`에서 뽑는** 것 — 같은 문서의
  `reconcile` 의사코드가 소스.

### 짜야 할 것

- [ ] **⭐ [2026-08-24 신설, 6라운드 손 트레이싱 `H-46`] top-level
      `quad-base/Slot.luau` — 값 타입 본체가 들어가는 파일.** 생성자(**[2026-08-31
      `H-232` (a)]** `slot._bk`도 여기서 — Slot-owner 부기의 강한 앵커,
      `base/slot-plan.md` 생성자 절), 공개
      CRUD 11종, `:List`/`:Single`, `raw*` 세트, `wrapElement`/`unwrapElement`,
      `attachSlot` 3형제(`materializeSlotTree`/`mountSlotTree`),
      `elementOwner`/`claimOwner`/`releaseOwner`, `reindexFrom`,
      `collectLeaves`, `dispose`, `Detach`/`KeyGone`. 아래 불릿들이 전부 이
      파일의 내용이다. **`Dispatch/Slot.luau`(맨 아래)는 핸들러/부기만** —
      다른 값 타입(`Modifier`/`Tag`/`Tween`/`Ref`/`Effect`)이 전부 top-level
      파일을 갖는 것과 같은 대칭이고, `base/slot-plan.md`의 `attachSlot`
      블록이 이미 머리에 이 파일명을 적어뒀다
- [ ] **⭐ [2026-08-24, 6라운드] 이 마일스톤에서 새로 생긴 필드·헬퍼**
      (구현 항목으로 드러나야 놓치지 않는다):
      **`bk.indexOfElement`**(물리 요소→`_elements` 인덱스 역방향 맵,
      `indexOfRaw`가 이걸 O(1)로 조회하는 **기본 경로**. **[2026-08-27, 9라운드
      Q3]** 옛 이름 `slot._elemIndex` — 같은 뜻의 맵이 Slot 층과 Dispatch 층에
      따로 살던 것을 **Dispatch 부기 하나**로 통일했다, `base/dispatch-core-plan.md`
      `setLength` 절) ·
      **`reindexFrom(self, from)`**(`_elements`를 시프트하는 **모든** 자리가
      부른다 — 실체화 여부와 무관하게 항상; 갱신 대상은 위 `bk.indexOfElement`) ·
      **⭐ [2026-08-27, 9라운드 Q2] 생성자에서 나는 `Offset`/`_baseObserver`**
      (`Length`와 같은 자리 — 마운트 시점에 만들면 첫 마운트/재마운트가 갈려
      재마운트 캐시가 낡았다, `H-125`. 둘 다 bind/unbind로만 관리하고
      제거/생성하지 않는다) · **`slot._destroyed`**(파괴됨은 이 플래그 하나만
      말한다 — 핸들을 `nil`로 지워 그 뜻을 겸하게 하지 않는다. 마운트·공개
      CRUD·`:List` 진입에서 error level 2, 이중 `dispose`는 no-op,
      `base/slot-plan.md`의 "파괴된 Slot은 재사용 불가" 절) ·
      **`slot._physicalTarget`**(실체화 시점부터의 생명주기 앵커,
      `_mountedInst`는 "마운트됨"만 뜻하게 좁혀졌다) ·
      **`collectLeaves(slot)`**(중첩 Slot의 물리 리프 평탄화 —
      `Move`/`Swap`/`Extract`/`Splice`가 `native*`에 넘길 `elements` 배열을
      만드는 데 필요, 없어서 그 넷이 미작성이었다) ·
      `:List`의 **`prevKeys`**(옛 `keyIndex`의 강등판, 단순 키 집합).
      전부 `base/slot-plan.md`가 소스
- [ ] **[2026-08-24 `H-25` 파생]** `quad-types`의 `Quad`에 `Slot` 필드 추가
      (위 M3 항목의 "마일스톤마다" 규칙)
- [ ] **[2026-08-13 여섯 번째 세션 — 이 세션의 Slot 결정 전부, 구현 전 필독]**
      - **`State<Slot>` 교체 = 파괴가 아니라 언마운트**(`state<Frame>`와 동일).
        비파괴 경로 `unmountSlotTree`를 `destroySlotTree`와 별도로 구현 —
        차이는 딱 둘: 실제 `Destroy()`를 안 하고, 자식 `releaseOwner`도 안 함
        (자식은 계속 그 slot 소유라 통째로 재마운트 가능 = 포탈).
        **쓰는 자리**: `SlotHandler.process`가 반환하는 클로저, 그리고
        `:List`의 `reconcile` 중 **`Owned = false` 설치와 `Detach` 경로**
        (**[재정정, 2026-08-21]** 값 교체는 `Owned = true`면 파괴가 맞다 —
        `updateFn`이 만든 걸 자기 손으로 못 지우기 때문. `state<Frame>`
        의미론은 `Owned = false`가 담당).
        **여전히 파괴인 것**: 명시적 `Remove`/`Clear`/`dispose`, 그리고
        **[재정정, 2026-08-18 구현 전 QA] `:List`에서 `updateFn`이
        `nil`/`None`을 반환하거나 키가 데이터에서 사라진 경로**(2026-08-13의
        "reconcile은 전부 비파괴" 일반화가 `:List`엔 안 맞았음 —
        `base/slot-plan.md`의 "`nil` 리턴은 파괴가 기본" 절이 소스).
      - **해제 시 owner 등록 되돌리는 순서 고정** —
        `setOffsetSource(inst,k,None)` **먼저**, `setLength(inst,k,0)` **나중**.
        반대로 하면 `setLength` 안의 `recompute`가 죽는 중인 서브트리의 offset
        `Source`에 헛된 `:Set()`을 날림. `recompute`는 `sourceList[i]`가 `nil`이면
        **즉시 `error`**(부기가 깨졌다는 신호 — 4라운드 `C-6`; **[2026-08-28
        `H-155`]** 여기 한때 "`None`처럼 skip(방어)"라 적혀 있었다, `base/slot-plan.md`가 소스). (**⚠️ [2026-08-27 정정, 9라운드 `H-140`]**
        여기 한때 *"해제 시 `slot.Offset = nil`"*이 붙어 있었는데 그건 4라운드
        `SL-75`/`D-60`이 **폐기**한 문장이다 — `nil`로 갈아치우면 그 Source를
        구독 중인 다운스트림이 끊겨 포탈이 깨진다. `slot.Offset`은 생성자에서
        나서 Slot과 함께 죽는다(위 `_baseObserver` 항목과 같은 불변식).)
      - **소유권 판정을 둘로 분리** — nested(`rawAdd`)는 엄격 `claimOwner`
        (같은 owner 재클레임도 error, `Slot{a,a}` 차단, 반환값 없음),
        top-level은 `claimOwnerAt(element, inst, k)`(정확히 같은 `(inst,k)`의
        spurious 재발행만 `false`, `Frame{slot,slot}`은 error).
        `releaseOwner`는 불일치 시 즉시 error.
      - **`rawRemove`가 `releaseOwner`를 부를 것**(옛 의사코드에서 누락돼 있었음),
        ~~**`destroySlotTree`가 자식 소유권 반납 + `_mounted`/`_mountedInst` 복원**~~
        (**[2026-08-28 `H-155`]** 이 수정은 5라운드 `C-4`로 **되돌려졌다** —
        `base/slot-plan.md`의 `State<Slot>` 재설정 표 정정 문단이 소스).
      - **`SlotHandler.process`는 claim 실패 시에도 파괴적 클로저를 반환해야 함**
        — no-op을 반환하면 다음 진짜 교체 때 정리 주체가 사라짐(`retractFrom`은
        클로저가 early-return해도 체인에서 항상 소비하므로).
      - 전부 `base/slot-plan.md`에 반영돼 있고, `luau-test/19` C 섹션이
        소유권 분기를 음성 대조군까지 포함해 실측 검증함.
- [ ] **`dispose(value: Slot | Instance)`** — 대상이 아직 어느 트리에 의해
      살아있길 요구되면 **파괴를 거부하고 즉시 error**(떼어내주지 않음 —
      떼는 건 `Set`=언마운트의 몫). 엔진은 `Destroy`/`Clear`에 에러를 안
      내지만 quad 자료구조가 깨지므로, quad가 관리 중인 값을 안전하게
      지우는 유일한 경로. 마운트 위치는 `elementOwner`가 이미 알고 있어
      새 부기 불필요. `isSlot(value)`면 그 경로, 아니면 백엔드가 주입하는
      `nativeDispose(element): ()`(`addTag`/`removeTag`/`setAttribute`와 같은
      "base 소유+op 주입" 패턴, quad-roblox는 `inst:Destroy()`)로 위임
      (**[2026-08-22 정정]** 여기 `disposeInst`라 적혀 있었으나 이름은
      2026-08-21에 `native*` 계층으로 확정됨 — M5 배너 참고).
      **`Observer`/`Effect`는 범위 밖**(GC-native `bindLifetime`/
      `unbindLifetime`만으로 충분, 트리 부기 없음) — 2026-08-14 열 번째
      세션에 `question.md` 0-B 해소, 정본은 `base/slot-plan.md`
      "`dispose(value)`" 절

- [ ] `Slot:List(data, updateFn, keyFn?)` — 키 기반 동적 컬렉션 재조정,
      `keyFn(item, index) -> key` 생략 시 원본 `data` 배열 위치(raw index)를
      그대로 key로 사용(중간 삽입/삭제 시 identity 보존 안 됨, 캐스케이드
      갱신 — 흔한 업계 관행과 같은 트레이드오프).
      `updateFn<UD=any>(item, index: number, offset: Source<number>, prev: T?,
      userdata: UD?): (T|nil, UD?)`가 **매 reconcile 사이클마다 호출**
      (filter/toggle 지원 — 첫 반환값 `nil` 시 실제 파괴, `Visible` 토글
      아님, 200+ 항목에서 lazy하지 않은 문제 회피), `prev` 그대로 반환하면
      저비용 재사용 경로.
      **[2026-08-18 신설, 이름 2026-08-19 확정, 2026-08-21 보존 주체 정정]
      `Detach` 반환 경로** — `updateFn`이 `Detach`를 반환하면 그 자리는
      **파괴하지 않고 `Parent = nil`로만 내려와** Slot에서 빠진다.
      **보존 주체는 `userdata`가 아니라 `slot._detached` 필드**(Slot 필드여야
      `destroySlotTree` walk가 닿고 소유권도 유지됨 — `ud`로는 최종 처분이
      불가능). reconcile이 `prev`로 그대로 돌려주므로 `ud`에 담을 필요 없이
      **그대로 반환하면 재마운트**되고, 이미 detach 상태에서 또 `Detach`면
      **nop**. 언마운트는 소유권을 유지하는 `rawDetach`를 씀(`rawUnmount`
      아님). `Instance.new`/`Destroy` 비용을 아끼는 filter용 경로. 공개
      표면은 `None`과 같이 패키지 최상위 export(`base/slot-plan.md`의
      "Detach된 요소는 `slot._detached`가 보유한다" 절).
      **[2026-08-21 해소] "키가 사라졌을 때 홀드 중이던 요소의 처분"은
      `KeyGone` 센티널로 확정** — `updateFn(KeyGone, 0, offset, prev, ud)`로
      한 번 더 물어 처분을 받고, owner가 죽으면 `activateList`가 건
      `Effect`가 `_detached`를 전부 정리한다(같은 문서의 "`KeyGone`" 절).
      **⚠️ [2026-08-24 `H-50`] 단 그 마지막 절반은 아직 "될 예정"이지 "된다"가
      아니었다** — `Effect`의 leaf 사망 cleanup을 실제로 발화시키는 배선이
      코퍼스 어디에도 없었다(6라운드 `H-11`). 같은 날 확정으로
      **`bindLifetime`/`unbindLifetime`이 `isEffect(value)`를 보고 `Destroying`을
      걸고/끊는 것**으로 닫혔고(`base/effect-plan.md` +
      `base/lifecycle-pattern.md`의 그 의사코드), 이 문장은 그 배선이 구현된
      뒤에야 참이 된다 — M2 `Effect` 구현이 M6의 이 항목을 **선행**한다는 뜻이다.
      (**[같은 날 재결정]** 처음엔 *"`EffectHandle`이 자기 `bindLifetime` 직후에
      건다"*였으나 `/code-review high`가 **그 호출부가 실재하지 않는다**는 걸
      지적했다 — 핸들은 남이 자기를 bind하는 걸 관측할 수 없고, `Effect`가
      바인드되는 경로가 둘이라 호출부 쪽에 두면 반드시 한쪽이 샌다.)
      **`Owned` 옵션 신설** — `:List`/`:Single`의 설치 시점 플래그(기본
      `true`), `false`면 어떤 경로로도 파괴하지 않고 언마운트만(사용자가
      `state`에 담아 넘긴 요소용, `Slot:Add(state)` sugar가 이걸로 설치). 파라미터 순서는 반환값 순서(`prev`류 먼저,
      `userdata`류 나중)와 맞춤(2026-08-11 세션 정정, 원래 `userdata`가
      `prev`보다 앞이었음).
      **`updateFn`의 `index`는 `keyFn`의 raw `index`(원본 `data` 배열
      위치)와 다른 값** — "이번 사이클에 살아남으면 차지할 압축된 마운트
      위치"(`candidateIndex`, filter로 압축됨), `key`와도 무관(순서/레이아웃
      전용, 식별 목적 아님) — 문서화 시 셋(원본 raw index/`key`/`updateFn`의
      `index`)을 혼동하지 않게 주의. **`offset`은 `Slot.Offset`을 그대로
      전달**(형제 Slot/정적 자식 누적합, `base/dispatch-core-plan.md`의
      "Length/Offset" 절) — `index`/`offset` 둘 다 **raw 값으로만 전달,
      `Slot`/Handler가 `LayoutOrder` 등을 자동으로 세팅해주지 않음**
      (2026-08-11 세션 확정 — 자동 바인딩은 컴포넌트가 이미 지정한 값을
      매직으로 덮어쓰는 문제가 있어 기각, 실제 반영은 전적으로 `updateFn`
      몫). `:List`가 `Source`를 대신 안 만듦 — item/index를 반응형으로
      감쌀지는 `updateFn`이 `userdata`에 직접 관리, **"버림(`nil` 반환)/
      다시 그림(`prev==nil`, 항상 새 `Source`로 처음부터 올바른 값 생성)/
      source만 갱신(`prev` 재사용, 값 다를 때만 `:Set`)" 세 갈래를
      `updateFn`이 명시적으로 나눠야 낭비 없음** — 재사용 중인 Source에
      미리 `:Set()`해뒀다가 결국 새로 그리게 되면 그 `:Set()`은 아무도
      안 구독한 상태라 무의미한 연산이 됨, `updateFn`만 이 갈래를 정확히
      알아 낭비를 피할 수 있음(반환값 두 개는 서로 독립, `result`가 `nil`이어도
      `userdata`는 명시적으로 반환 안 하는 한 안 지워짐). 정리 루프는
      `mounted`가 아니라 직전 사이클의 키 집합 `prevKeys` 전체를 순회해야 함
      (**[2026-08-24 `H-1`]** 옛 이름은 `keyIndex`였고 인덱스 맵이었으나,
      역방향 맵(지금은 `bk.indexOfElement` — 2026-08-27 Q3로 Dispatch 부기에
      통일, 그때 이름은 `slot._elemIndex`)이 생기며 **단순 키 집합으로 강등**됐다)
      (`userdata`만 살아있는 채로 key가 완전히 사라지는 케이스 커버).
      `userdata = userdata or {}` lazy-init 패턴이 Luau 제네릭에서 잘
      좁혀지는지 실측 필요. **`userdata`는 GC-native 값만 허용,
      `:Subscribe()`한 Observer류 명시적 cleanup 필요한 값은 UB** —
      `item`을 nilable로 바꿔 최종 제거 시 정리 훅을 한 번 더 부르는 안은
      기각(Slot 부모 자체가 Destroy되는 경로에선 이 훅이 전혀 안 불려서
      절반만 동작, `retract`가 Destroy 시 안 불리는 것과 같은 이유).
      (2026-08-09 세 번째 세션 확정, `offset`/raw `index`/세 갈래 구조는
      2026-08-11 세션 추가 확정, `base/slot-plan.md` "`Slot:List(data, updateFn, keyFn?)`" 절)
      구현.
      **`data:Observer(fn)` 구독은 `:List()` 호출 시점이 아니라 Slot
      마운트 시점까지 lazy — `Dispatch.setLength`와 같은 패턴으로
      `bindLifetime(inst,observer)`(마운트 이후 `:List()`가 불리면
      `self._physicalTarget` 확인 후 즉시 활성화 — **[2026-08-28 `H-155`]** 옛
      `_mounted` 기준은 6라운드 `H-2`로 바뀌었다)** (2026-08-09 일곱 번째 세션,
      `base/slot-plan.md` "`Slot:List(data, updateFn, keyFn?)`"의 "구독 시점" 절)
      **`Slot.Offset: Source<number>`도 `Slot.Length`처럼 공개 필드로
      노출 — `Length`와 같은 자리, 즉 생성자에서 `Source(0)`으로 만들고 마운트
      시점엔 `Dispatch.setOffsetSource`가 그 Source를 **등록만** 한다**
      (2026-08-11 세션, `base/dispatch-core-plan.md`의 "Slot.Length와 Slot.Offset은
      별개" 절. **[2026-08-27 정정, 9라운드 `H-125`/Q2]** 여기 한때 *"마운트
      시점에 `setOffsetSource`가 등록하는 바로 그 Source를 `self.Offset`으로도
      저장"*이었다 — 그러면 첫 마운트와 재마운트가 갈려 재마운트 캐시가 낡는다)
- [ ] base `Dispatch/Slot.luau`(추상 재조정, mount/unmount/reposition 3훅) +
      quad-roblox `Handlers/Slot.luau`(실제 Parent 조작 + reposition —
      `SetSiblingIndex` 또는 `LayoutOrder` 기반이면 no-op, 구현 선택)
## M7 — Modifier

- [ ] **[2026-08-27 9라운드 `H-142` 후속, `/code-review`]** 생성기가 찍는
      `FrameModifier`류 메소드 목록에서도 **`Parent`를 제외**할 것 — props
      타입에서만 빼면 `Modifier():Parent(x)`가 타입을 통과하고 `flatten`이
      `Parent`를 해시 파트로 merge해 런타임에서야 죽는다. `PreRef`/`PostRef`가
      Modifier 타입으로 차단되는 것과 같은 자리(`base/bind-system-plan.md`의
      `H-142` 항목).

- [ ] `Modifier()`(빈 인스턴스 바닥 생성자, 2026-08-07 열 번째 세션
      명시 — `Source(default)`/`Ref(default)`/`Store({defaults})`와 같은
      `Type(args)` 팩토리 관습, `modifier-plan.md` 3번)
- [ ] flatten-before-dispatch(`isModifier(v)`로 배열 항목 중 Modifier만
      판별해 필드 merge, 나머지는 안 건드리고 통과 — 2026-08-07 열 번째
      세션 명시, `modifier-plan.md` 1번), immutable `table.clone` 체이닝 —
      `table.clone`이 메타테이블을 복사 아닌 참조로 공유해 제네릭 `__index`
      기반 체이닝이 안 끊긴다는 메커니즘은 확인됨(2026-08-12 열일곱 번째
      세션, `modifier-plan.md` "`table.clone`의 정확한 동작" 절) — 실제
      Luau 실행 확인은 `luau-test`의 `17-modifier-index-tableclone-chaining.luau`
- [ ] `Modifier.Overridden(mod1, mod2, ...)`(이름 확정, 구 `Merge`→`Override`,
      2026-08-08 세션) — 필드별 raw 덮어쓰기, 특별한 State/함수 분기
      불필요(`modifier-plan.md` 9번)
- [ ] `Overridden`가 서브타입 관계인 서로 다른 Modifier 타입(예: `FrameModifier`/
      `GuiObjectModifier`)을 섞을 때의 타입 시그니처 — **[해소됨,
      2026-08-13 첫 실측 라운드]** `luau-test/09`로 실측 완료, 우려대로
      깨짐 확인됨 → `Overridden(...: any): any`로 느슨하게 열어두는 게
      실제 구현 방향(`modifier-plan.md` 9-2번)
- [ ] `State<Modifier>` 조합에 `isModifier` 기반 명시적 error 적용
      (`modifier-plan.md` 7번, 2026-08-09 세션 확정) — 타입 차단은
      되면 좋은 보너스로 선택 검증(필수 아님)
- [ ] `:Apply(factory)` 팩토리 함수 체이닝(`modifier-plan.md` 8번, 예약 키
      `Apply`가 제네릭 `__index` 필드 setter와 안 겹치는지 확인)
- [ ] `:Peek<<T>>(key): T|State<T>|nil` 필드 읽기 접근자 +
      `isState(x)`/`isSource(x): boolean`(**[2026-08-21 갱신]** 인스턴스
      브랜드 멤버십 기반 — `isSource(x)`는 `SourceBrand:is(x)`, `isState`는
      그 위에 `StateBrand:is(x)`를 OR로 얹은 상위 개념. 옛 "공유 레지스트리 +
      `Brand.get(x) == SourceTag`" 서술은 역전됨,
      `archive/brand-shared-registry-reversed.md`. `modifier-plan.md` 9번,
      `brand-plan.md`의 "`isX` wrapper" 절, M2의 `Brand.luau`에 이미
      구현돼 있어야 함)
> **[2026-08-22 이동] `None` 센티널 + `Dispatch/None.luau`(`NoneHandler`/
> `NilHandler`)는 M3로 옮겼습니다** — `None`은 modifier 전용 값이 아니라
> quad-base 디스패치 배관이고(`architecture.md`의 소스 트리에서도
> `Dispatch/None.luau`), M0의 `props.Modifier or None` 관용구 · M3의
> `Dispatch.drive` · M6의 `setOffsetSource(..., None)`이 전부 이미 전제합니다.
> M7에서는 **Modifier 쪽 표면만** 다룹니다 — 인라인 키/setter로 필드를
> 지우는 용법과 `Peek` 반환 타입에 `None`을 추가하는 것(`modifier-plan.md`
> 2-1번).
- [ ] 프로퍼티류 필드 타입에 `T' = T | Tween<T>` 치환 반영(타입 생성
      스크립트가 `Position: UDim2` 자리를 `UDim2 | Tween<UDim2>`로 만들면
      끝, Modifier 런타임/`__index` 자체엔 변경 없음 — `modifier-plan.md`
      10번, 2026-08-10 세션, `base/tween-plan.md`)
- [ ] **⭐ [2026-08-24 신설, 6라운드 손 트레이싱 `H-35`]
      `quad-base/Dispatch/Modifier.luau` — `ProcessedModifierHandler`.**
      `flatten`이 배열 자리를 `ProcessedModifier` 센티널로 소진하고, 이 전담
      nop 핸들러가 정상 `Dispatch.process` 경로에서 캐치해
      `setOffsetSource(None)`/`setLength(0)`만 등록한다(`Pre`/`PostRef`의
      `Processed*` 핸들러와 완전히 같은 모양). **`Modifier`가 하나라도 든
      `Frame{...}` 호출은 전부 이 핸들러를 거치는데** 색인 두 곳에서 통째로
      빠져 있어 구현자가 존재 자체를 놓칠 수 있던 자리다. 의사코드는
      `base/modifier-plan.md`의 flatten 절이 소스
- [ ] **[2026-08-24 `H-25` 파생]** `quad-types`의 `Quad`에 `Modifier` 관련
      표면이 노출돼야 하면 같이 갱신(위 M3 항목의 "마일스톤마다" 규칙)

## M8 — Ref

- [x] ~~**[2026-08-24 `H-25` 파생]** `quad-types`의 `Quad`에 `Ref` 필드 추가~~
      — **[2026-08-27 `H-128` 후속]** `Ref` 최소형과 함께 M2 공통 기반으로
      이동(그 체크박스). `PreRef`/`PostRef` 필드는 아래 항목이 얹는다
- [ ] `Ref.luau`의 **나머지** — `:Wait(thread?)`(self 반환). **[2026-08-27
      9라운드 `H-128`] 최소형은 M2 "공통 기반" 절로 앞당겨졌다**(표면 목록은
      그 체크박스가 소스 — 여기 반복하지 않는다) — `Ref`가 `Epoch`를 만족한다는 2026-08-25 확정
      (7라운드 `H-58`/`H-64`/`H-70`: `.Revision`은 `:Set()`이 `Source`와 같은
      `bit32.bnot(-rev)`로 갱신, `Weak` 쪽이 프리미티브이고 `:Callback`이 그
      위에 "GC 킵"을 얹은 것, `Effect` 생성자가 `self._epochs:Sync(d)`로 태움)은
      그 표면의 일부라 M2 몫이다 — 세부는 체크박스에 재서술하지 않고
      `base/ref-plan.md`의 "`Ref`는 `Epoch`를 만족한다" 절이 소스. + `PreRef.luau`/`PostRef.luau`(별도 파일, Ref
      런타임 재사용 + children 배열 전용, Modifier/Store 타입 차단,
      위치 무관 호이스팅 pre-pass — `base/ref-plan.md` "`phase`
      옵션 폐기 → 위치로 표현, `PreRef` 신설" 절 + "API 모양" 절)
- [ ] `(v=Ref)` 매치 핸들러 — children 배열의 숫자 슬롯에 놓인
      `Ref(default)` 인스턴스를 인식해 바인드(별도 `CreatedRef` 래퍼
      없음 — 이름 자체가 폐기됨, 아래 참고)
- [ ] **이중 배치 방지**(`question.md` 0-W, 2026-08-14 열한 번째 세션
      해소) — `RefLeafHandler.process`가 실제 바인딩 분기에서
      `bindLifetime(inst, v)`를, 실제 언바인딩 분기에서 `unbindLifetime(v)`를
      호출. 새 `Relate` 불필요 — `bindLifetime`이 이미 내장한 `canBound`
      이중 바인딩 가드를 재사용하는 것뿐(같은 `Ref`가 이미 다른 자리에
      살아있으면 그 자리에서 즉시 error) — `base/ref-plan.md` "이중 배치
      방지" 절
- [ ] `PreRef`/`PostRef` pre-pass — 새 `Dispatch.*` 함수 없이
      `Dispatch.drive(inst, flattened)` 자신이 **본체 루프 전에** 배열
      파트를 **한 번** 훑어(**[2026-08-22 정정]** 여기 "두 패스(배열→해시)
      루프 전에"라고 적혀 있었으나 본체는 단일 일반화 `for`다 — `F-4-1`), `PreRef`는 그 자리에서 fire하고
      `PostRef`는 로컬 `postRefList`에 push만 함(Dispatch.process/getHandler
      우회하는 raw 루프, `flatten` 함수에는 얹지 않음 — 재바인드 시 flatten
      재호출 가능성과 충돌하므로 기각). **복수 `PreRef`/`PostRef`의 계열 안
      상대 순서는 배열 index 순서 그대로 보장**(별도 규칙 없음 — 배열 파트
      index 순서 계약의 귀결. 2026-08-14 아홉 번째 세션에 잠깐 미보장으로
      뒤집었다가 같은 세션에 철회 —
      `archive/preref-order-unguaranteed-withdrawn.md`, `FastQuery(...) ->
      PreRef`류 조합이 반례). fire/수집된 슬롯은 그 자리에서 소진(**[정정, 2026-08-14 두
      번째 세션] `None`이 아니라 전용 센티널 `ProcessedPreRef`/
      `ProcessedPostRef` 처리** — 아래 `Processed*Handler` 항목이 그 자리를
      정상 본체 루프로 마저 처리)
      — `base/ref-plan.md` "PreRef" 절 / "`PostRef`" 절
- [ ] **[2026-08-14 아홉 번째 세션 신설]** `PostRef.luau` + 본체 루프 뒤
      `postRefList` 소비 루프 — `PreRef.luau`와 같은 방식(`Ref` 런타임
      재사용 + 브랜드 태그만 다름, children 배열 리터럴 전용, Modifier/Store
      타입 차단, `_fired` 1회용 가드). `Dispatch.drive`가 해시 파트까지
      끝낸 뒤 `postRefList`를 순회하며 각 `PostRef`를 fire — 배열 재순회가
      아니라 실제 개수만큼의 짧은 루프. **보장 범위 주의**: 자기 서브트리
      완성은 보장하되 **이 인스턴스가 부모에 붙는 것보다는 먼저**임
      — `base/ref-plan.md` "`PostRef`" 절
- [ ] `PostRef` 동적 경로 가드 Handler — `PreRef`의 것과 완전한 거울상
      (`{priority = HANDLER_PRIORITY_FALLBACK, isHandlable = v is PostRef,
      process = error(...)}`), 같은 절 참고
- [ ] `PreRef` 동적 경로 가드 Handler — `{priority =
      HANDLER_PRIORITY_FALLBACK, isHandlable = v is PreRef, process =
      error(...)}` 형태로 정상 우선순위 레지스트리에 등록(`k` 타입 안
      가림), `NoneHandler`와 같은 "한 값 종류 전담" 패턴. 리터럴 배열
      경로는 pre-pass가 이미 소진시키므로 이 Handler가 매치되면 곧 타입
      차단을 우회한 버그라는 뜻 — 같은 절 참고. **[2026-08-14 열한 번째
      세션]** 우선순위가 하드 블록이 아니라 `FALLBACK`인 이유(나중에 named
      자리 바인드가 확정되면 평범한 우선순위 Handler로 덮어쓸 수 있게 —
      `Tag`/`Attribute`와 같은 이유)와 `Observer`/`EffectHandle`에도 같은
      패턴의 가드가 추가됨은 `base/source-state-plan.md`/`base/effect-plan.md`의
      "동적 경로 가드" 절 참고
- [ ] **[2026-08-14 두 번째 세션 신설]** `ProcessedPreRefHandler` +
      **[아홉 번째 세션] `ProcessedPostRefHandler`**(완전한 거울상, 코드
      한 글자 차이) — `{isHandlable = v == Processed*Ref, process =
      setLength(0)+setOffsetSource(None)+no-op retract}` 형태로 정상
      우선순위 레지스트리에 등록, `NoneHandler`와 같은 "한 값 종류 전담"
      패턴. pre-pass가 소진시킨 자리가 Length/Offset에 "0 기여"를 등록할
      책임을 지는 자리 — `base/ref-plan.md` "PreRef" 절 / "`PostRef`" 절,
      `base/dispatch-core-plan.md` "Length/Offset" 절
- [ ] Ref 콜백/대기자 실행 루프 — **[2026-08-24 6라운드 `H-7`로 재작성]**
      `.Callbacks`는 **`{[callback|thread] = true}` 해시맵 셋**이다(배열 아님).
      `:Set(value)`는 **`.Value`를 먼저 쓰고**, **순회 전 스냅샷을 뜬 뒤**
      (`pairs` 순회 중 새 키 추가가 Lua에서 미정의라 — `H-23`과 같은 처방)
      키 타입으로 분기: `type(k) == "thread"`면 `Callbacks[k] = nil`로 소진 후
      `coroutine.resume(k, self)`(값이 아니라 **Ref 자신**), 함수면
      **`k(value, self)`** 호출 + 유지(**[2026-08-26, 8라운드 `H-107`]** 두 번째
      인자로 `Ref` 자신 = `Epoch`을 준다 — `Effect`가 `Update(from)`에 넘길
      통로다). **순회 대상은 두 테이블** — `.Callbacks`(강)와
      `.WeakCallbacks`(weak-키)를 각각 스냅샷한다(`H-108`). 그리고 `.Value`
      대입 **직후·순회 전**에 `self.Revision = bit32.bnot(-self.Revision)`
      (순서 계약: **값 → 리비전 → 콜백**). **중복 등록은 dedup이 계약**이고
      해제는 **`:Uncallback(fn)`**(양쪽 테이블을 다 본다).
      **⭐ [2026-08-25 추가, 7라운드 `H-58`/`H-59`] 약하게 등록하는 짝
      `:WeakCallback(fn)`이 신설됐고 그쪽이 프리미티브다** —
      `:Callback(fn)`은 거기에 "GC 안 되도록 킵" 하나를 더 얹은 것이다.
      약한 등록은 **weak-키 테이블**(`__mode = "k"`)로 `.Callbacks`와
      **별도**이고(Lua의 weak 모드는 테이블 단위), 발화 순회는 둘 다
      훑으며 `:Uncallback`은 양쪽을 본다.
      의사코드는 `base/ref-plan.md`가 소스.
      **⚠️ 옛 배열 설계(빈 슬롯 선형 탐색 등록, `[i] = nil` 소진, `#t` border
      실측)는 전부 폐기됐다** — 해시맵엔 구멍도 border도 없다.
      `:Wait(thread?)`는 그대로 — `thread`가 `nil`이면
      `coroutine.running()` 캡처+yield, 있으면 등록만 하고 즉시 `self`
      반환(남의 thread를 여기서 대신 정지시킬 수 없어서)
- [ ] **[2026-08-24 신설, 6라운드 `H-7` / 2026-08-25 범위 축소, 7라운드 `H-58`]**
      `Ref:Uncallback(fn)` — 해제 경로(강·약 두 테이블을 다 본다).
      **⚠️ `Effect`는 더 이상 이걸 안 부른다** — 여기 한때 *"`Effect`가 자기
      `Ref` dep 콜백을 뗄 때 쓰고(`_refCallbacks`에 보관해둔 바로 그 클로저를
      값으로 뗀다), `unbindLifetime`/`:Unsubscribe()`가 부른다"*고 적혀 있었는데
      그 계약은 `base/effect-plan.md`가 명시적으로 retract했다. 지금은
      `Effect`가 **생성자에서 `:WeakCallback`으로 한 번만** 걸고 강한 주인은
      `_deps`이며(`_refCallbacks`는 폐기된 필드), 바인드/언바인드는 `Ref`를
      아예 안 건드린다. `:Uncallback`은 **사용자가 직접 건 콜백을 떼는**
      공개 표면으로 남는다
- [x] `LifetimeHandle` quad-roblox 실제 구현 — `bindLifetime`/
      `unbindLifetime`/`canBound`/`canExecute` 본체(인터페이스 자체는
      M2로 이동됨, `Relate` 자체는 quad-base라 quad-roblox 쪽 재구현
      없음). **[2026-09-02 M5 단위 ①로 앞당겨 완료 — round14 brief §1
      (사용자 §0 (a) 승인), 진행 기록은 M5 체크박스 1이 소스.** 탐사자가
      이 이중 등재를 잡기 전까지 여기 미체크로 남아 진행 소스가 둘이었다
      — 컨벤션 체크리스트 4번의 그 실패 모드.]
      **[2026-08-14 다섯 번째 세션 정정] gcconn/gchold를 여기서 lazy 생성하지
      않는다** — 생성은 M5의 Instance 생성 경로가 이미 끝내둔 것이고, 이
      함수들은 `InstData`에서 찾아 쓰기만 함. `bindLifetime`은
      `gchold[value]=true`(강참조로 생존 보장)와 `BindData:SetWeak(value,
      "gchold"/"gcconn", ...)`(값이 자기 생존 판정 근거를 직접 들고 있게)
      둘을 하고, `unbindLifetime(value)`은 그걸 되돌림.
      **⭐ [2026-08-24 6라운드 `H-11`, 2026-08-25 7라운드 `H-58`로 축소]
      그리고 `isEffect(value)`면 분기가 하나 더 붙는다** —
      `value:_bindDestroying(inst)` / `:_unbindDestroying()`를 부른다.
      여기 원래 *"둘만 하고"*라고 적혀 있었는데 이 분기와 직접 모순이었다.
      **⚠️ [2026-08-25 정정] `handle._observers` 전부로 cascade하지
      않는다** — 그 필드 자체가 폐기됐다(`_deps` 하나로 통합). 그리고
      `_bindDestroying`은 **`Ref` dep 콜백을 (재)등록하지 않는다** —
      dep 등록은 생성자에서 끝나고, 여기서 하는 건 `Destroying` 연결과
      **홀드 캐치업 한 줄**(`if self._rerunRequired then self:Rerun() end` —
      **[2026-08-28 `H-151`/`H-159`]** 옛 `Refresh()` 판정은 폐기)뿐이다. **이게 `Effect`의 leaf 사망 cleanup을 실제로
      발화시키는 유일한 배선**이고, M6의 `_detached` 정리가 여기 의존한다
      (그 항목의 `H-50` 각주 참고). 의사코드는 `base/lifecycle-pattern.md`와
      `base/effect-plan.md`가 소스. **[2026-08-14
      열한 번째 세션] `canBound(value)`/`canExecute(value)`는 비공개
      헬퍼 `isBoundAlive(value)` 하나(복사된 gcconn의 `.Connected` 또는
      `.Subscribed`를 봄)를 공유하는 얇은 진입점 둘로 분리** — `bindLifetime`/
      `Observer:Subscribe()`의 이중 바인딩 가드는 `canBound`, State emit
      `Observer:_receive`만 `canExecute`(**[2026-08-28 `EmitReceive`]** 옛 표현 "전파 루프만").
      **저장은 전부 `SetWeak`**(`SetStrong` 아님 — gchold/gcconn은 아래 M5
      클로저↔`gchold[1]` 상호 참조로 이미 안전하게 살아있고, "다른 곳에서
      안전하게 유지되는 것은 항상 weak로 잡는다"가 일반 규칙).
      `base/lifecycle-pattern.md`의 "`bindLifetime` / `canBound` /
      `canExecute` / `unbindLifetime`" 절

## M9 — 컴포넌트 합성 레이어

- [ ] 플레인 함수 컴포넌트 관례 문서화/예제
- [ ] `props.Modifier`/`props.Ref` 전달 관례를 정식 컴포넌트로 검증(M0
      스파이크를 정식화)

## M10 — Event / OnChange / Attribute / Tag

> **✅ [2026-08-13 열네 번째 세션] 0-Z(Attribute 이름 소유권)/0-A(하강
> diff) 확정 완료** — 이 마일스톤의 Tag/Attribute 항목은 **quad-base로
> 재배치**됐고(엔진 op `addTag`/`removeTag`/`setAttribute`만 주입),
> 이름 소유권은 그룹 전용 키 + `AttributeKeyHandler`의 이름 claim이
> 판정함. 정본은 `base/attribute-plan.md`/`base/tag-plan.md`.
>
> **[2026-08-14 열두 번째 세션 정정]** `TagHandler`/`AttributeKeyHandler`/
> `AttributeGroupHandler`는 참조 카운트/이름 claim **알고리즘 구현**일
> 뿐 — `HANDLER_PRIORITY_FALLBACK`에 실제로 등록되는 건 이를 감싸는
> 별도 파일 `TagFallbackHandler`/`AttributeKeyFallbackHandler`/
> `AttributeGroupFallbackHandler`이고, **[재역전, 2026-08-18 구현 전 QA]
> 등록 주체는 백엔드 팩토리가 아니라 quad-base 자신**(백엔드 미로드
> 상태에서도 안내 에러 경로가 돌아야 하기 때문 —
> `base/dispatch-core-plan.md`의 해당 절). 아래 체크리스트의
> `Handler` 파일 항목은 전부 이 구분을 반영하도록 갱신됨 — 뒤집힌
> 옛 모델은
> `archive/tag-attribute-load-time-registration-reversed.md`.


- [ ] **[2026-08-24 `H-39`]** `TagHandler`/`AttributeGroupHandler`가 자기 배열
      자리의 `setOffsetSource(inst,k,None)`/`setLength(inst,k,0)`을 등록 —
      **둘 다 0건이었다**(위 M3의 그 항목). 같이 **`type(k) == "number"` 가드**도
      추가(`H-52` — `RefLeafHandler`가 2026-08-18에 받은 수정을 이 둘은 못 받았다)
- [ ] **[2026-08-24 `H-41`]** `AttributeGroupHandler.process`에 `groupClaimKeys`
      위치 claim 배선 — 5라운드 `AT-1`에서 `(inst, groupValue) → k`로 확정해놓고
      의사코드에 안 들어가 있었다. **`nameClaims`보다 먼저** 해야 절반만 기록되는
      중간 상태가 안 생긴다
- [ ] **[2026-08-24 `H-27`]** `OnChangeHandler.process`에 `v == nil` 얼리리턴 —
      없으면 `None`으로 콜백을 끄는 게 실제로는 **나중에 터질 Connection을 새로
      심는** 동작이 된다
- [ ] **[2026-08-24 `H-25` 파생]** `quad-types`의 `Quad`에 `Tag`/`Attribute`
      필드 추가(위 M3 항목의 "마일스톤마다" 규칙)
- [ ] `Handlers/Event.luau`(`ReflectionService` 기반 자동 판별)
- [ ] `Handlers/OnChange.luau`(`OnChange(name)` 특수 키 팩토리+Handler,
      `GetPropertyChangedSignal` 바인딩 — 제네릭 없이 콜백 타입은 인라인
      명시, 이름별 weak 캐시로 `OnChange(a) == OnChange(a)` 동등성 보장
      (`AttributeKey`와 동일 기법), `base/onchange-plan.md`, 2026-08-10
      세션 확정·2026-08-11 아홉 번째 세션 후속(캐시))
- [ ] **[2026-08-13 열네 번째 세션 재배치] `quad-roblox/EngineOps.luau`의
      Tag/Attribute 몫** — `addTag(inst,{string})`/`removeTag(inst,{string})`
      (`CollectionService`), `setAttribute(inst,name,v)`(`v==nil`이면 삭제).
      `RobloxFactory`가 `BaseModule`에 주입(`bindLifetime`/`canExecute`와
      같은 패턴) — 아래 base 핸들러들이 이걸 호출함
      (`base/dispatch-core-plan.md` "base가 소유하는 핸들러와 주입되는
      엔진 op" 절). **[2026-08-22 정정] 여기 "주입되는 엔진 op 3개"라고
      적혀 있었으나 이 파일이 담는 op은 그 셋이 전부가 아니다** — M5의
      `native*` 계층이 같은 파일에 들어오고 백로그의 `setTimeout`/
      `clearTimeout`도 예정돼 있다. **주입 op 전체 목록의 소스는
      `base/architecture.md`의 소스 트리 안 `EngineOps.luau` 줄** — 여기서
      세지 않는다.
- [ ] `quad-base/AttributeKey.luau`(단일 키 `AttributeKey<<T>>(name)` +
      이름별 weak 캐시로 동등성 보장 + 스칼라 편의 패밀리
      `String`/`Number`/`BooleanAttribute` — 엔진 고유 타입 패밀리
      (`Color3Attribute`류)만 quad-roblox의 `D`(Declarative) 층에서 각자 추가.
      타입 파라미터화 이름만 착수 전 확인, `base/attribute-plan.md`)
- [ ] `quad-base/Dispatch/AttributeKey.luau`(`AttributeKeyHandler` —
      `setAttribute(inst,name,v)`를 `v`가 뭐든 무조건 호출 + **이름
      claim**(`nameClaims` Relate, 다른 키 객체가 같은 이름에 들어오면
      즉시 error, 반환 클로저는 자기 claim만 반납하고 엔진 부작용 없음).
      알고리즘 구현일 뿐 스스로 등록되진 않음(아래
      `AttributeKeyFallbackHandler` 항목 참고). `question.md` 0-Z 결정 —
      `base/attribute-plan.md` "이름 소유권" 절)
- [ ] **[2026-08-14 열두 번째 세션 신설]** `quad-base/Dispatch/
      AttributeKeyFallback.luau`(`AttributeKeyFallbackHandler` — 위
      `AttributeKeyHandler`를 그대로 감싸 `HANDLER_PRIORITY_FALLBACK`으로
      등록되는 별도 이름의 엔티티. **[재역전, 2026-08-18] 등록 주체는
      `RobloxFactory`가 아니라 quad-base 자신** —
      `base/dispatch-core-plan.md` "base가 소유하는 핸들러와 주입되는
      엔진 op" 절)
- [ ] `Attribute.luau`(quad-base — 그룹 값 타입+API: `Attribute(store1,
      store2, ...)`/`Merged`/**`Overridden`**/`:NameMap`, `Tag`와 동형
      array-part 값 객체, `base/attribute-plan.md`. **[2026-08-18]**
      `Merged`는 이름이 겹치면 error, `Overridden`은 뒤가 이김 — 둘 다 제공)
- [ ] `quad-base/Dispatch/Attribute.luau`(`AttributeGroupHandler` — 이름마다
      **그룹 전용 키**(비공개 `GetKey`, 그룹 값 객체별·이름별 메모이즈)로
      `Dispatch.process(inst,key,source,1)`만 부르고, 반환 클로저가 자기가
      등록한 키 전부에 `Dispatch.retractFrom(inst,key,1)`.
      **`process` 안에서 `retractFrom`을 먼저 부르면 안 됨**(철거는 전적으로
      클로저 몫). 실제 `setAttribute`/store-bind 구독/이름 claim은 전부 단일
      키 경로 재사용 — `base/attribute-plan.md` "메커니즘" 절. 알고리즘
      구현일 뿐 스스로 등록되진 않음, 아래 `AttributeGroupFallbackHandler`
      항목 참고)
- [ ] **[2026-08-14 열두 번째 세션 신설]** `quad-base/Dispatch/
      AttributeGroupFallback.luau`(`AttributeGroupFallbackHandler` — 위
      `AttributeGroupHandler`를 그대로 감싸 `HANDLER_PRIORITY_FALLBACK`으로
      등록되는 별도 이름의 엔티티, 등록 주체는 `AttributeKeyFallbackHandler`와
      동일하게 **quad-base 자신** — [재역전, 2026-08-18])
- [ ] `Tag.luau`(quad-base — 값 타입+immutable clone 체이닝: `Tag(...)`/
      `:Added`/`:Removed`/`:Contains`/`:Apply`/`Merged`/`:Names`,
      `base/tag-plan.md` — 2026-08-08 세 번째 세션 array-part 값 객체로
      재설계, 구 해시 파트 모델은 `archive/tag-hash-key-model-reversed.md`)
- [ ] `quad-base/Dispatch/Tag.luau`(`TagHandler` — `isHandlable`은 `isTag(v)`.
      **`addTag`는 온전히 `process`, `removeTag`는 온전히 반환 클로저** —
      이름별 홀더 집합(`tagNameMap`, 위치 `k` 기준 참조 카운트)이 비었을
      때만 실제 `removeTag`, 그마저도 클로저가 받은 새 값이 그 이름을
      `Contains`하면 skip해 깜빡임 방지. 제거할 이름은 모아서 **한 번에**
      `removeTag(inst, names)`. `process` 쪽 별도 diff 없음, `kTagMap`도
      불필요(클로저가 `v`를 직접 캡처) — 2026-08-12 열한 번째 /
      2026-08-13 네·다섯·열네 번째 세션, `base/tag-plan.md`. 알고리즘
      구현일 뿐 스스로 등록되진 않음, 아래 `TagFallbackHandler` 항목 참고)
- [ ] **[2026-08-14 열두 번째 세션 신설]** `quad-base/Dispatch/
      TagFallback.luau`(`TagFallbackHandler` — 위 `TagHandler`를 그대로
      감싸 `HANDLER_PRIORITY_FALLBACK`으로 등록되는 별도 이름의 엔티티,
      등록 주체는 `AttributeKeyFallbackHandler`와 동일하게 **quad-base
      자신** — [재역전, 2026-08-18])
- [ ] **[2026-08-14 세션에 누락 발견, 신규]** `quad-roblox/Handlers/
      InstanceShorthand.luau` — UI 편의 숏핸드 `UICorner`/`UIPadding`
      (+`UIPaddingOffset`)/`UIScale`(`base/ui-shorthand-plan.md`). 이
      마일스톤 전후로 구현하기로 그 문서가 이미 지정해뒀는데 체크리스트에
      항목 자체가 없었음. 구현 포인트: (a) 재사용 대상은 quad가 만든 고정
      이름(`_quad_corner`류) 자식으로 한정, (b) `v == nil`이면 그 자식 제거,
      (c) **자식 프로퍼티는 직접 대입하지 말고 `Dispatch.process(child,
      prop, wrapped, 1)`로 위임** — 이걸로 Tween이 공짜로 따라옴(해석은
      `PropertyHandler` 하나에만 남음), (d) 스칼라→프로퍼티 타입 `wrap`은
      `Tween<T>`의 `.Value`에만 적용되도록 들어올릴 것, (e) `UIPadding`은
      자식 프로퍼티 4개에 각각 위임, (f) 자식을 없앨 때 `retractFrom(child,
      prop, 1)`도 같이. M11(Tween) 이후에 하면 (c)~(d)를 바로 검증 가능

## M11 — Tween

**[2026-08-10 세션, 구조 재설계]** 독립 Dispatch 핸들러 모델에서 값-레벨
`Tween<T>` 래퍼 모델로 전환 — 상세는 `base/tween-plan.md`(전면
재작성), 구 모델은 `archive/tween-special-bind-key-reversed.md`.

### 확정된 것 — 코드 아님, 구현 전 필독

아래는 **설계가 확정됐다**는 사실이지 짠 코드가 아니다 — 체크박스로
두면 `[x]`가 "구현 완료"와 구분이 안 돼서 문서 머리 규약대로 분리했다
(**[2026-08-22]**).

- **override 정책 확정 완료**(2026-08-12 세션, `base/tween-plan.md`
  "확정: `Tween{...}` 최종 모양" 절) — 검토했던 4가지가 **`Tween.Cancel`
  (기본)/`Tween.Finish` 2값으로 압축**됨(로블록스 `TweenBase` API 현실상
  나머지가 관찰상 Cancel과 동일). Tween→plain 전환도 두 옵션 모두
  "정리 후 즉시 덮어쓰기"로 수렴해 5번째 옵션 불필요로 확정.
  **구현 시 순서 주의**: 이전 트윈 정리 → 그 다음 새 값 세팅
- **트윈 옵션 값 모양 확정 완료**(2026-08-12 세션, `base/tween-plan.md`)
  — `Info: TweenInfo?` 우선 + 편의 필드(`Time`/`Style`/...) 폴백,
  기본값은 로블록스 `TweenInfo.new()` 자체 기본값과 일치. 옵션 필드는
  전부 plain만(State 불가)
- **`initValue`(진입 애니메이션) — 에이전트 범위 제외로 확정**
  (2026-08-12 세션, 사용자가 직접 처리하기로) — 재검토 항목 아님

### 짜야 할 것

- [ ] `quad-base/Tween.luau`(값 타입만 — `Tween(opts)` 팩토리가 `TweenBrand`에
      등록, **[2026-08-28]** 브랜드 인스턴스와 `isTween`은 `Brand.luau`에 추가,
      `Value: T` plain만 받고 State 재귀 없음)
- [ ] `Handlers/Property.luau`에 `isTween(realv)` 분기 추가(기존
      `Handlers/Tween.luau` 독립 핸들러는 폐기) + 3-상태 릴레이션 슬롯
      (**[2026-08-28 `H-155`]** `base/tween-plan.md`의 "3-상태 저장" 절이 소스 —
      활성 트윈은 엔진 객체가 아니라 `{Tween, Value}` **테이블**, `Tween.Finish`가
      목표값을 알아야 해서; 옛 표기 `RobloxTween | true | nil`) + 첫 세팅은 무조건 애니메이션 없이
      스냅(hasBeenSet 억제) + 활성 트윈 정리는 override 정책 완료 후에만
      새 값 세팅(순서 뒤바뀌면 트윈 다음 프레임이 방금 세팅한 값을 덮어씀)
- [ ] `quad-roblox/Animate.luau` — **시그니처도 이미 확정 완료**(2026-08-12
      두 번째/세 번째 세션, `base/tween-plan.md`): `Tween` opts(`Value` 제외)를
      `T|State<T>`로 받아 각 필드를 resolve한 뒤 `Tween{...}`을 반환하는
      `function(self)...end` — `:Apply(Animate{...})`로 체이닝(`:Compute`가
      아님, `research/operator-sugar-plan.md` "왜 `:Apply`인가"). `CanAnimate`
      필드 포함(`false`면 `Tween`으로 안 감싸고 plain 값 그대로). M11은
      **구현만** 하면 됨
## 특정 마일스톤에 안 묶이고 병행 가능

- [ ] 용어 정리 스윕 — `State`/`Slot` 등(`PerInstanceState`는 `Relate`로
      대체·해소됨, `DI`→`D`는 2026-08-18 확정·반영 완료) — `.claude/question.md` 1번, 최종 이름 확정되는 대로
      아무 시점에나
- [ ] 각 마일스톤 완료 시 `.claude/qa-request/`/`.claude/archive/`에 기록,
      필요하면 `.claude/session-summary.md` "세션 히스토리"도 갱신(전체 원문은
      `.claude/session/`에, `.claude/session-summary.md`엔 2~4줄 요약+링크만
      — 2026-08-11 재구조화 세션 참고)

## 백로그 (스코프 밖 — 필요성이 실제로 드러나면 그때 설계)

- [ ] 범용 렌더 디버깅 도구로서의 quad-mock(Tween mock 등 동적 동작 포함,
      M1의 quad-base 테스트용 mock과는 별개)
- [ ] `quad-debug`/`quad-debug-roblox-plugin` — 실물 Instance→코드 위치
      역추적 Studio 플러그인(`research/debug-tooling-plan.md`). 위
      quad-mock과 목적이 다름(오프라인 검증 vs 실시간 라이브 관찰) —
      단 trace 이벤트 스키마를 공유할 여지는 있음, 그 문서 참고. M2/M3/M5
      구현 시 훅 확장 지점만 고려해두면 이 항목 자체는 지금 착수 불필요.
- [ ] v1 마이그레이션 가이드(`objectListClass.__newIndex` 오타 기능 재현
      테스트는 2026-08-13 세 번째 세션에 불필요로 해소됨 —
      `archive/question-resolved.md` 참고, v2엔 대응 개념 자체가 없음)
- [ ] Slot 형제 순서 보장(다중 백엔드 관점) — Roblox만이면 급하지 않음
- [ ] **[2026-08-14 신설, 2026-08-19 설계 전부 해소 후 `base/`로 승격]**
      시간 기반 전파 게이트 `Debounce`/`Throttle`(`base/debounce-throttle-plan.md`)
      — 제어 핸들 설계까지 닫히면서 quad-base에 새 코어 메커니즘을
      추가하지 않는 **순수 슈가**로 확인됨(`Blocker`의 gated state + `Ref` +
      아래 주입 op 2개 위에 전부 얹힘, 그 문서 13절). **[정정, 2026-08-24]
      그 공용 `Gate` 추출은 M2(반응형 코어)에서 이뤄진다** — 2026-08-21에
      "게이팅 먼저" 결정으로 디스패치 쪽에 앞당겨뒀다가, 2026-08-24 마일스톤
      순서 교체(위 M2 배너)로 반응형이 먼저가 되면서 앞당길 필요 자체가
      사라졌다. `Blocker`/`Debounce`/`Throttle`이 공유할 노드를 거기서 같이
      빼둔다(따로 하면 같은 설계를 두 번 함). **[2026-08-21] 표면 확정 —
      `state:Gate(setup)` 메소드**, `base/gate-plan.md`.
      프리미티브 자체는 그 위에 나중에 얹으면 되고 M0/M2를 막지 않음.
      주입 op 2개(`setTimeout(func, delay) -> Timeout` / `clearTimeout`,
      Roblox는 `task.delay`/`task.cancel`로 배선 — **인자 순서가 반대라
      주의**)가 `bindLifetime`/`canExecute`와 같은 base 범용 유틸 그룹에
      추가될 예정이라는 것만 M1 설계 시 인지. `os.clock()`은 Luau 표준
      라이브러리라 주입 대상 아님(단 절대 시각이 아니라 diff 전용)
- [ ] **[2026-08-14 아홉 번째 세션 신설]** 생명주기 훅 슈가
      `OnCreated`/`OnRendered`/`OnDestroyed`(`base/lifecycle-hooks-plan.md`)
      — 각각 `PreRef():Callback(guard(fn))`/`PostRef():Callback(guard(fn))`/
      `Effect(function() return fn end)`를 반환하는 순수 팩토리 함수
      (**⚠️ [2026-08-26, 8라운드 `H-120`] `guard`는 생략할 수 없다** —
      `Ref` 콜백은 "등록 즉시 1회, 값이 nil이어도" 호출되므로 default 없는
      `PreRef()`에 맨 `fn`을 걸면 **생성 시점에 `fn(nil)`이 먼저 불려**
      `inst`를 바로 쓰는 콜백이 pre-pass 전에 죽는다.
      `guard(fn) = function(v, r) if v ~= nil then fn(v, r) end end` — **2-인자를
      그대로 흘린다**, `Ref` 콜백이 `fn(value, ref)`라 1-인자로 짜면 `Epoch`를
      조용히 삼킨다)
      3개라, 착수 시점에 그 문서의 코드 스케치를 그대로 옮기면 끝(새 타입/
      Dispatch 개념 없음, 패키지는 quad-base 확정). **설계는 확정됐지만
      구현은 형제 백로그(`quad-mock`/`quad-debug`/`Operator`/`Fallback`)와
      동급으로 맨 뒤** — 없어도 프리미티브를 직접 쓰면 되므로 기능 격차
      없음. 단 이들이 얹히는 `PostRef` 자신은 슈가가 아니라 디스패치
      코어의 일부라 **M8에서 `PreRef`와 같이 구현됨**(위 M8 참고).
