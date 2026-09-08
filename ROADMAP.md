# ROADMAP.md

quad-v2 구현 단계 실행 계획. 설계 근거/아키텍처 자체는 여기 안 옮겨적음 —
`.claude/base/`가 소스, 여긴 **순서와 진행 상황**만. 살아있는 문서.

> **⭐⭐⭐ [2026-09-07 기준] v2 초기 구현 구간 M0~M11 전부 완료 — 열린 마일스톤 없음.**
> 각 마일스톤의 본문(체크박스·배너·`H-nnn` 표시·"확정된 것"/"짜야 할 것" 절, 2026-08-04
> 신설 이후의 히스토리 blockquote 전부)은 **2026-09-07 사용자 결정으로 원문 그대로
> `.claude/archive/v2-initial-implementation/roadmap.md`로 이동**했다 — 마일스톤별 규약·발견
> 원장(`mN-implementation-roundNN(-brief).md`, pre-implementation 라운드 1~10)도 같은 폴더.
> 구현 뒤 코드 리뷰(순회) 원장은 `.claude/qa-request/post-implementation-review-round1.md`.
> 남은 것은 아래 "특정 마일스톤에 안 묶이고 병행 가능"·"백로그" 절뿐(착수 순서는 사용자와).

## 완료된 마일스톤 (요약 표 — 본문은 archive)

| 마일스톤 | 무엇 | 종결 | 규약·원장(`archive/v2-initial-implementation/`) |
|---|---|---|---|
| M0 | 스켈레톤 + 기술검증 스파이크(`luau-test/`, 상태는 `STATUS.md`) | 2026-08-13 첫 실측, 재검증 대기분은 이후 라운드에서 흡수 | pre-implementation QA 1~5·손 트레이싱 6~10 |
| M1 | 실제 스캐폴딩(pesde 워크스페이스, `New()`/`RunInit`/`AddPlugin`/`Relate`/`Debug`, mock 하네스) | 2026-08-24 | — |
| M2 | 반응형 코어(Source/State/Store, Brand/Relate/LifetimeHandle, Gate) | 2026-08-28~31 | `m2-implementation-round11(-brief).md` |
| M3 | 디스패치 엔진(process/retract, Bookkeeping, Observer/Effect leaf) | 2026-08-31~09-01 | `m3-implementation-round12(-brief).md` |
| M4 | 첫 end-to-end 반응형 업데이트(`Dispatch/StoreBind`) | 2026-09-01 | `m4-implementation-round13(-brief).md` |
| M5 | quad-roblox 최소 프로바이더(팩토리·주입 op·생명주기·`D`·Property/InstanceChild·`Claim`) | 2026-09-02 | `m5-implementation-round14(-brief).md` |
| M6 | Slot(공개 CRUD·`List`/`Single`·Deferred 실측) | 2026-09-03(fork 탐사 + 잔여 마감) | `m6-implementation-round15(-brief).md` |
| M7 | Modifier(클래스 태그·`TypedFactory`·`As`/`Into`) | 2026-09-04 | `m7-implementation-round17(-brief).md` |
| M8 | Ref/PreRef/PostRef(`:Wait`, drive pre-pass, 반공변 마커) | 2026-09-04~06 | `m8-implementation-round18(-brief).md` |
| M9 | 컴포넌트 합성 레이어 — 관례 검증(`spec.component`) | 2026-09-06 | `m9-implementation-round21(-brief).md` |
| M10 | Event/OnChange/Attr/Tag + InstanceShorthand | 2026-09-03~06 | `m10-implementation-round16(-brief).md`, `m10-shorthand-implementation-round20(-brief).md` |
| M11 | Tween(값·타입, Property 소비, `Animate`, `Override` 문자열 싱글톤) | 2026-09-06 | `m11-implementation-round19(-brief).md` |

## 특정 마일스톤에 안 묶이고 병행 가능

- [ ] 용어 정리 스윕 — `State`/`Slot` 등(`PerInstanceState`는 `Relate`로
      대체·해소됨, `DI`→`D`는 2026-08-18 확정·반영 완료) — `.claude/question.md` 1번, 최종 이름 확정되는 대로
      아무 시점에나
- [ ] 각 마일스톤 완료 시 `.claude/qa-request/`/`.claude/archive/`에 기록,
      필요하면 `.claude/session-summary.md` "세션 히스토리"도 갱신(전체 원문은
      `.claude/session/`에, `.claude/session-summary.md`엔 2~4줄 요약+링크만
      — 2026-08-11 재구조화 세션 참고)

## 백로그 (스코프 밖 — 필요성이 실제로 드러나면 그때 설계)

- [ ] **[2026-09-07 신설, 사용자 결정] 최적화 후보 목록 — 관측된 병목이 없어 보류한 것을 쌓아두는 자리**(사용자:
      *"당장은 더 치명적인 문제들이 있는지 확인해보자. 물론 보는 김에 최적화 할 대상을 쌓아둬도 좋아"*, 원장
      `qa-request/post-implementation-review-round1.md` §15). 실측된 병목이 생기면 그때 착수, 그 전엔 여기만 늘린다:
      - `Slot:List` 재정렬 O(N²)(N=1000 역순 실측 82ms, 100은 1ms — round7 Q38)·~~reconcile마다 `table.clone(prevKeys)`~~(**[2026-09-08 `H-480`]** 제거됨)·`prepareElements` 전체
        재스캔(Q3 ①; **[2026-09-08 `H-506`]** 생성자 배치는 닫음 — 단일 `Add` N회 반복만 잔존). 아이디어(사용자): `rawOrder(newOrder)`식 일괄 재정렬 — 단 *"reconcile 자체가 재정렬 된건지 그런
        상황을 쉽게 알긴 어려울거야. 모든 순서 변경을 미뤘다가 나중에 하는걸 만들기에도 복잡해"* — 리서치 목록에만.
        **[2026-09-08 round7 Q38 사용자 결정 — 백로그 확정]** 2-pass 순열(`rawPermute`: 사이클 끝에 순열 하나로 `_elements`·부기 세 배열을
        한 번에 재배치, 새 raw op + 백엔드 `nativeMove` 의미 결정 필요)은 *"순수 최적화이고 외부 표면은 나오지 않고 … 정식 릴리즈
        전"*이라 사용자가 큰 틀을 본 뒤에. 재정렬 분석 문서의 옵저버 잔류·stale 인덱스 난제는 현재 코드엔 없다(round7 §3).
        **[2026-09-08 round8 L 실측 추가]** `:List` **전체 키 교체**도 O(N²)(1000개 87ms, 8000개 5.5s — 옛 요소 N개가 남은 2N 배열 중간에
        `rawAdd`(`table.insert`+역맵+`spliceArraysUp` 각 O(N)) 뒤 KeyGone 패스가 하나씩 `vacate`) — 같은 `rawPermute`/"KeyGone 먼저" 계열.
        가운데 한 개 삭제의 O(N²)는 `H-505`(`reindexRange`)로 닫음.
      - **[2026-09-08 round8 L-3]** 마운트된 Slot의 **단발 CRUD**(Add/Remove/Swap/Move/Replace/Extract)는 꼬리 `recompute`가 `i = 1`부터
        전 자리를 훑어 호출당 O(N)(5000자리 `Swap(1,2)` 한 번 0.63ms; N회 반복 O(N²)) — `Splice`/`Clear`/reconcile은 배치 Blocker로
        1회라 선형. 후보: recompute를 `offsetSetUpTo` 커서부터 재개(캐시된 접두합 신뢰 — `H-240`/`H-124` 되감기 계약과 대조 필요, 설계 판단).
      - **[2026-09-08 round8 L-5/L-6]** `addHandler` N개 등록 O(N²)(등록마다 정렬 + `H-484` 버킷 재구축; 실사용 22개라 무해),
        Modifier 필드 수천 개 체이닝 초선형(immutable clone 설계 그대로; 실사용에 없음).
      - **[2026-09-08 `H-479` 대부분 닫힘]** `Slot:Clear`/`ExtractAll`의 요소마다 recompute와 `ExtractAll`의 역순 `table.insert` O(n²)는 배치화됨(recompute 1회, ExtractAll은 `rawSplice` 한 번) — 남은 잔여는 `Clear`의 요소별 `nativeRemove`뿐(파괴가 요소 단위라 의도)
        (Q3 ⑨; round2 G-09의 원자성 논거 — 배치로 접으면 중간 길이 파동 노출도 사라진다).
      - `drive`의 recompute 호출부가 배치 `blocker:IsOn()`을 안 보는 것(Q3 ⑧ — `_handles`가 in-tree에서 비어 공허).

- [ ] **[2026-09-08 밤 신설 — 사용자 제기, 결정 대기 `question.md` 0절]** 렌더 스텝 op(`onStep(fn) -> cancel`류) — 시간 op와 같은 base 주입 경로에 예약 슬롯으로 둘지(`spring`이 그 위에 얹힘), 이름·계약(델타 시간 인자·프레임 안 순서·취소 뒤 미발화)은 사용자 결정 뒤 정본에 적는다. 지금은 아무것도 안 심었다.
- [x] **[2026-09-08 밤 구현 — 사용자 범위 확정]** `Operator` 콤비네이터(`Operator.luau`, `research/operator-sugar-plan.md` 머리 배너), `Context`/`Provider`(`Context.luau`, `base/context-plan.md` — 불변 확장은 사용자 결정으로 안 만듦), `ref:Unwrap()`(`ref-plan.md`).
- [ ] **[2026-09-08 밤 신설 — 사용자 결정으로 `operator-sugar-plan.md`에서 분리한 백로그 넷]** 릴리즈를 막지 않고, 문서 재개편 없이 이미 있는 슈거 그룹 절에 더해지는 것들(사용자: *"이미 구현된 슈거를 통해 먼저 문서화를 어느정도 다듬어 두면, 나중에 추가는 쉬워"*):
      - 분기 콤비네이터 `IfElse`(+ 그때 비교 `Eq`/`Lt`/`Gt`/`Lte`/`Gte`)와 컬렉션 계열 `Concat`/`Sorted`/`Filtered` — 순수 슈거지만 **타입 표면 결정이 필요**해 미구현(`operator-sugar-plan.md` "컬렉션 계열 후보" 절).
      - Attr 그룹 명시적 unset 유틸 — 오퍼레이터가 아니라 별도(`operator-sugar-plan.md` "Attr 그룹 명시적 unset 유틸" 절).
      - 중첩 평탄화 `State<State<T>>` → `State<T>` — 코어 로직 재검증이 필요(`operator-sugar-plan.md` "중첩 State 평탄화" 절).
      - 타입드 `Index` 콤비네이터(`Apply(Index<<Theme>>("key"))`) — 사용자 제안, 지금 솔버로는 불가(`typing-limits.md` 8.15 실측); 무타입판은 조건 미달이라 안 넣음.
- [ ] **[2026-09-08 신설, round7 Q39 사용자 결정 백로그]** 루트 `README.md`(라이브러리 사용자 대면 — 한 줄 소개·설치·최소 예제·비교 링크) — *"루트 readme 는 그냥 백로깅에 두고싶음"*. 문서 사이트(`research/documentation-plan.md`)와 같은 시기(폴리싱·문서화 기간, 정식 릴리즈 전).
- [ ] **[2026-09-06 신설, 사용자 결정 백로그]** 컴포넌트 경계 flatten 슈거(`research/component-flatten-sugar-plan.md`) — round21 §4 Q2·`H-340`의 후속. 순수 슈거, 코어 변경 없음. 스캐폴딩 계획만 있고 사용자 답 대기.
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
- [ ] **[2026-09-07 신설, 회신 4차 Q6 사용자 확정]** `native*` 조합 기본 구현 — 백엔드가 여섯 op 중 이득 있는 것만 심고
      나머지(`nativeRemove` = extract+dispose 반복, `nativeMove` = extract+insert, `nativeSwap` = move 2회)는 base가
      조합해 주는 것. 정본의 약속은 코드 사실에 맞춰 철회했고(`slot-plan.md` "기본 구현(조합 폴백)" 절 배너), 셋째 백엔드가
      실제로 나올 때 착수. 사용자: *"있는게 맞다이고, 지금 필요하지 않고 없어도 치명적이지 않을 뿐"*.
- [x] **[2026-09-08 구현 완료 — 사용자 결정 "슈거를 먼저 간단히 만들어 놓고 다듬기", 문서화는 뒤로]** `Debounce.luau` + 시간 op 둘(base 스텁·Roblox `task` 배선·mock 가상 시계), Studio 실측 일치. 구현 중 정한 것 다섯은 그 문서 머리 배너 + `question.md` 0절(사용자 확인 대기). 아래는 착수 전 서술.
      **[2026-08-14 신설, 2026-08-19 설계 전부 해소 후 `base/`로 승격]**
      시간 기반 전파 게이트 `Debounce`/`Throttle`(`base/debounce-throttle-plan.md`)
      — 제어 핸들 설계까지 닫히면서 quad-base에 새 코어 메커니즘을
      추가하지 않는 **순수 슈가**로 확인됨(`Blocker`의 gated state + `Ref` +
      아래 주입 op 2개 위에 전부 얹힘, 그 문서 13절). **[정정, 2026-08-24]
      그 공용 `Gate` 추출은 M2(반응형 코어)에서 이뤄진다** — 2026-08-21에
      "게이팅 먼저" 결정으로 디스패치 쪽에 앞당겨뒀다가, 2026-08-24 마일스톤
      순서 교체(`archive/v2-initial-implementation/roadmap.md`의 M2 배너)로 반응형이 먼저가 되면서 앞당길 필요 자체가
      사라졌다. `Blocker`/`Debounce`/`Throttle`이 공유할 노드를 거기서 같이
      빼둔다(따로 하면 같은 설계를 두 번 함). **[2026-08-21] 표면 확정 —
      `state:Gate(setup)` 메소드**, `base/gate-plan.md`.
      프리미티브 자체는 그 위에 나중에 얹으면 되고 M0/M2를 막지 않음.
      주입 op 2개(`setTimeout(func, delay) -> Timeout` / `clearTimeout`,
      Roblox는 `task.delay`/`task.cancel`로 배선 — **인자 순서가 반대라
      주의**)가 `bindLifetime`/`canExecute`와 같은 base 범용 유틸 그룹에
      추가될 예정이라는 것만 M1 설계 시 인지. `os.clock()`은 Luau 표준
      라이브러리라 주입 대상 아님(단 절대 시각이 아니라 diff 전용)
- [x] **[2026-09-08 구현 완료]** `LifecycleHooks.luau`(훅 셋) + `Fallback.luau`(`Fallback`/`Traceback`, `base/fallback-plan.md` — 부분 트리 미회수는 같은 밤 UB로 닫힘). 아래는 착수 전 서술.
      **[2026-08-14 아홉 번째 세션 신설]** 생명주기 훅 슈가
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
      코어의 일부라 **M8에서 `PreRef`와 같이 구현됨**(`archive/v2-initial-implementation/roadmap.md`의 M8).
