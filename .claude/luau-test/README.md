# .claude/luau-test — M0 착수 전 실 Luau 기술검증 스파이크 모음

> **⚡ 지금 뭘 봐야 하는지부터 보려면 [`STATUS.md`](STATUS.md)** — 이
> README는 각 파일이 **무엇을 왜 검증하는지**(의도·배경)만 담고, 상태는
> **폴더 구조 + STATUS.md**가 소스.

**[2026-08-13 아홉 번째 세션] 폴더가 곧 상태** — 파일이 평평하게 21개
쌓여 있어 사람이 "지금 내가 볼 게 뭔지" 못 고르겠다는 사용자 지적으로
재편:

| 폴더 | 뜻 | 누가 처리 |
|---|---|---|
| `review-required/` | **설계가 걸림 — 사람 결정 필요**(**[2026-08-13 13차 세션] 현재 비어 있음** — 마지막 한 건이던 `08`이 해소돼 `done/`으로 감) | ⭐ 사용자 |
| `rewrite-required/` | 스파이크가 낡음 — 코드가 깨졌거나(`13`/`15`), **설계가 바뀌어 옛 모델을 검증 중**(`04`/`19`, 2026-08-13 14차 세션 하강 diff / `10`, **[2026-08-14 5차 세션]** `canExecute` 1-인자 재정정 / `05`, **[2026-08-14 8차 세션]** "emit은 항상 전파" 정정) — **`16`은 [2026-08-15] 통과로 `done/`에 있음**(아래 참고) | 에이전트 |
| `not-run/` | 이 환경에서 못 돌림 — **[2026-08-14 5차 세션] 스파이크는 0건**(`10`이 `rewrite-required/`로 감), GC 헬퍼만 남음 | 사용자 or MCP 연결 후 |
| `done/` | 통과 or 판정 끝, 더 할 일 없음 | — |

**스파이크를 고치거나 돌렸으면 파일을 해당 폴더로 `git mv`하고 STATUS.md의
줄도 같이 옮길 것** — 그게 곧 상태 갱신이다. 아래 파일 목록의 경로는
폴더 접두어를 생략하고 파일명만 적음(옮겨 다니므로).


**[2026-08-09 이동]** 처음엔 레포 루트 `luau-ignoreme/`(git 자동 제외
폴더)에 만들었으나, 사용자가 직접 확인해볼 만한 검증 코드라 커밋해서
레포에 남기기로 함 — `.claude/luau-test/`로 옮기고 일반 추적 대상으로
전환(더 이상 `*-ignoreme*` gitignore 패턴에 안 걸림). 위치만 바뀌었을 뿐
내용/역할은 그대로 — 아직 M0가 공식 시작 전인 상태에서 미리 돌려보는
사전 검증 스파이크 모음.

## 왜 이게 필요한가

`.claude/base/`와 `ROADMAP.md` M0가 "추론만으로 확정하고 실제 Luau 코드로
부딪혀본 적 없는 것"으로 명시적으로 지목한 항목들, 그리고 이후 세션들에서
"M0/M2 스파이크 검증 목록에 추가됨"으로 흩어져 있던 항목들을 모아 각각
독립 실행 가능한 스크립트로 만들었음. **[2026-08-13 갱신]** 처음엔 이
환경에 `luau`/`luau-analyze` 바이너리가 없어 에이전트가 못 돌렸으나,
여섯 번째 세션에 바이너리가 생겨 **첫 실측이 끝남** — 지금은 에이전트가
직접 돌릴 수 있고, 사용자 손이 필요한 건 Studio 전용(`not-run/`)뿐.

각 파일 맨 위 주석에 다음이 전부 적혀있음: 뭘 검증하는지, 어느 base 문서/
ROADMAP 항목 근거인지, 어떻게 실행하는지, 실행 후 뭘 확인해야 하는지.

## 실행 환경 세 갈래

| 환경 | 필요한 것 | 해당 파일 |
|---|---|---|
| **순수 Luau CLI** (`luau`) | [luau-lang/luau 릴리즈](https://github.com/luau-lang/luau/releases)의 `luau` 인터프리터, 또는 `lune` | 01, 02, 03, 04, 05, 06(런타임 부분), 07, 11, 13(런타임 부분), 17, 18, 19, 20 |
| **Luau 타입체커** (`luau-analyze` 또는 `luau-lsp`) | 같은 릴리즈에 포함된 `luau-analyze`, 또는 `luau-lsp analyze`/에디터 인라인 진단 | 06(타입 부분), 08, 09, 12, 13(타입 부분), 14, 15, 16 |
| **Roblox Studio** | 별도 계정으로 로그인(`HUMAN_TODO.md` 1번, `SAFETY.md` 준수) | 10 |

**16은 특히 `type function`이라는 비교적 최근/계속 진화 중인 Luau 기능을
쓰므로, luau-analyze 버전이 오래되면 아예 문법 자체를 못 알아볼 수 있음**
— 그 경우는 실패가 아니라 "이 Luau 버전에서 type function 자체가 아직
지원 안 됨"이라는 별개의 신호이니 버전 정보와 함께 알려줄 것.

**12/13/14는 특히 `luau-lsp`로 확인해달라고 요청받은 것들** — `luau-analyze`도
같은 타입 솔버를 쓰므로 원리적으로는 같은 결과가 나와야 하지만, `luau-lsp`가
에디터에서 인라인으로 에러 위치/메시지를 보여줘서 "정확히 어느 표현식이
막히는지"를 확인하기 더 편함. sourcemap/Roblox 전역 타입 없이도 그대로
확인 가능하게 만들어뒀음(전부 순수 Luau 타입 문법만 씀).

로컬에 `luau`/`luau-analyze`가 없으면 위 GitHub 릴리즈에서 플랫폼에 맞는
바이너리를 받으면 됨. Roblox Studio 파일은 스크립트 내용을 그대로
`ServerScriptService`에 붙여넣은 `Script`로 만들어 Play(F5)하면 됨.

## 파일 목록 — 뭘 검증하는지 요약

| 파일 | 검증 대상 | 근거 문서 |
|---|---|---|
| `01-two-pass-array-hash-order.luau` | 배열 파트(children/Ref) 먼저, 해시 파트(프로퍼티/이벤트) 나중이라는 두 패스 순회 계약 | `dispatch-core-plan.md` "props 순회 순서", ROADMAP M0-4 |
| `02-none-sentinel-vs-nil-holes.luau` | **[2026-08-09 커밋 f198fd9 반영해 전면 재작성]** 순서가 중요한 배열(PreRef pre-pass, sourceList)은 `None` 소진이 맞고, 순서가 안 중요하고 재사용이 필요한 배열(Ref 콜백/대기자)은 `nil`+슬롯 재사용이 맞다는 최종 구분 + `None`을 잘못 쓰면 배열이 무한정 자라는 버그의 정량적 재현 | `ref-plan.md` "왜 None이 아니라 nil인가"(2026-08-09 열한 번째 세션 최종 정정), ROADMAP M0-4 |
| `03-recursive-store-bind-dispatch.luau` | `process`/`retract` 재귀 재-dispatch 기본 모델, 우선순위 스캔 | `dispatch-core-plan.md` "확정된 디스패치 모델", ROADMAP M0-3 |
| `04-dispatch-chain-retractFrom.luau` | **[⚠️ 2026-08-13 열네 번째 세션: 하강 diff 확정으로 낡음 → `rewrite-required/`]** 아래는 옛 모델 기준 설명 — **[2026-08-13 감사에서 전면 재작성 + 파일명 변경]** 인덱스 기반 `chains`/`Dispatch.retractFrom`이 다단 재귀 위임에서 정확한지 — 3단 체인이 인덱스 1/2/3으로 안 겹치고 쌓이는지(= `State<State<T>>` **정상 동작**, UB 아님), 안/바깥 store 재발행 시 깊은 인덱스부터 정리되는지, hint가 target 인덱스에만 가는지 + **음성 대조군**: `chains:SetStrong`을 `handler.process` 뒤에 두면 최초 마운트에서 하위 retractor가 유실되는 버그 재현. 옛 버전은 핸들러 identity 기반 추적과 "중복 push 즉시 error" 가드를 검증했는데 그 가드는 다섯 번째 세션 재설계로 **없어져서** 설계와 정반대를 테스트하고 있었음 | `dispatch-core-plan.md` "Dispatch 체인"(2026-08-13 다섯 번째 세션 재설계) + 2026-08-13 감사 |
| `05-store-state-diamond-propagation.luau` | push-invalidate/pull-recompute가 다이아몬드 의존성에서 중복 재계산 없이 동작하는지. **[2026-08-19 재작성 완료 → `done/`]** 현행 모델("emit은 자기 invalid 상태와 무관하게 항상 전파, 중복 재계산은 `:Get()` 시점 캐시로만 막힘")로 다시 짜서 통과 — 핵심 회귀 방지 장치는 `:Get()`을 안 부르는 Observer가 다이아몬드에서 source 변경마다 경로 수(2)만큼 계속 우는지(옛 모델이면 두 번째부터 침묵) | ROADMAP M0-1 |
| `06-component-boundary-nil-hole-props.luau` | `props.Modifier or None` 관용구가 컴포넌트 경계 nil-hole을 막는지 + `Params` 타입 체크 | `component-composition-plan.md` "필수 관용구", ROADMAP M0-5 |
| `07-relate-weak-table-gc.luau` | `Relate`의 lazy 서브테이블 생성 + weak-key GC가 실제로 동작하는지 | `relate-plan.md` "M2 착수 시 실측 확인"  **[2026-08-13 보강]** 4번 섹션 신설 — `_countEntries()`(테스트 전용) + weak-value canary로 **"inst가 죽으면 중첩 StrongMap 안의 payload까지 연쇄 GC되는가"를 직접 검증**(원래는 sanity check만 하고 헤더의 핵심 주장은 미검증이었음). 파일이 스스로 적어둔 "weak table 엔트리를 셀 표준 API가 없다"는 전제도 틀렸음 — outer가 `__mode="k"`라 GC 후 `pairs`에서 사라짐 |
| `08-type-source-satisfies-state.luau` (타입체크 전용) | `Source<T>`가 `State<T>`를 구조적으로 만족하는 제네릭 타입이 솔버에서 안전한지 | `base/source-state-plan.md` "Source가 State를 만족함", ROADMAP M0-2 |
| `09-type-modifier-overridden-subtype.luau` (타입체크 전용) | `FrameModifier <: GuiObjectModifier`처럼 서브타입 관계인 Modifier를 `Overridden`으로 섞을 때 타입이 통과하는지 | `modifier-plan.md` 9-2번, ROADMAP M7 |
| `10-roblox-studio-checks.server.luau` (Studio 전용) | **[⚠️ 2026-08-14 다섯 번째 세션: A 섹션이 폐기된 모델을 검증 중 → `rewrite-required/`, 열한 번째 세션에 `canBound` 재도입으로 재작성 사유 하나 더 추가]** (A) `bindLifetime`/`unbindLifetime`/`canBound`/`canExecute`의 gcconn 트릭 + 이중 바인딩 게이트(Destroy 시 Connected 전환 포함), (B) Attribute의 Instance 참조 타입 지원, (C) CollectionService 태그/GetTagged 왕복. **A는 재작성 대상** — 파일 속 옛 `canBound`(9차 세션 정의)와 `bindLifetime`의 `value.Subscribed = true` 세팅, 2-인자 `canExecute(inst, value)`는 전부 낡음(현재 게이트는 이중 바인딩 확인은 `canBound(v)`, emit 게이팅은 `canExecute(v)` — 둘 다 `value` 단독 1-인자로 비공개 헬퍼를 공유, gcconn/gchold는 **Instance 생성 시점**에 생성). **[2026-08-13]** A 섹션 앞부분(ClassName 신호 미발화, Destroy 시 Connected 즉시 전환)은 사용자 자작 스크립트로 부분 확인됐고 **새 모델에서도 그대로 유효**(오히려 더 중요 — `canBound`/`canExecute`가 `.Connected`를 직접 읽는 게 leaf 경로 판정의 전부), `audit/gcconn-trick-verification.md` 참고. 이중 바인딩 게이트/재바인딩 허용/B/C는 이 공식 파일로 아직 확인 안 됨 | `lifecycle-pattern.md` "`bindLifetime`/`canBound`/`canExecute`/`unbindLifetime` — 확정", `archive/canexecute-inst-arg-reversed.md`, `source-state-plan.md` "이중 바인딩 금지", `.claude/session-summary.md` 2026-08-06 세션, `debug-tooling-plan.md` |
| `11-modifier-illegal-value-error.luau` | Modifier 필드에 Ref/PreRef/Observer/Effect/Slot/Modifier가 들어오면 즉시 error, State/Source가 확정하는 값이 Modifier면 즉시 error(2026-08-09 세션에 "UB"에서 전환된 규칙) | `modifier-plan.md` "Modifier 필드에 핸들러 계층 값(Ref/PreRef/PostRef/Observer/Effect/Slot/Modifier)이 들어오면 즉시 error" 절 + 7번 절 |
| `12-type-attribute-generic-key-narrowing.luau` (타입체크 전용) | `[AttributeKey<<T>> "name"] = value`(구 `Attribute<<T>>`)처럼 제네릭 특수 키를 쓸 때 `value`의 타입이 실제로 `T`로 좁혀지는지 — base 문서 자신이 "미검증"이라 명시한 항목 | `attribute-plan.md` "[실측 필요, M0/M10]" (2026-08-09 열한 번째 세션 신설) |
| `13-type-ref-preref-subtype.luau` | (A, 타입) `PreRef<T>`가 `Ref<T>`를 구조적으로 만족하는지, (B, 런타임) `isRef`/`isPreRef` 합성이 재정정대로 동작하는지(`isRef(preRefInstance)`가 이제 `true`) + Leaf 핸들러가 `isRef(v) and not isPreRef(v)`로 명시적으로 좁혀야 하는 이유. **[2026-08-14 아홉 번째 세션] 재작성 시 `PostRef`도 같이 커버할 것** — 같은 `Ref` 런타임 재사용 + 브랜드 태그만 다른 형제라 A/B 둘 다 그대로 확장되고, Leaf predicate도 `isRef(v) and not isPreRef(v) and not isPostRef(v)`로 늘어남 | `brand-plan.md`의 `Brand` 절(2026-08-09 열한 번째 세션 재정정) |
| `14-type-nilable-default-overload.luau` (타입체크 전용) | `Source(default)`/`Ref(default)`의 `default` 생략이 `T`가 nilable일 때만 안전하다는 캐비엇을, 함수 오버로드(교차 타입)로 실제로 타입 레벨에서 막을 수 있는지 | `source-state-plan.md` "State는 쓰기 대상이 아님" 절의 `default` 생략 캐비엇 |
| `15-type-compute-trailing-deps-typepack.luau` (타입체크 전용) | `:Compute(fn, ...)`의 trailing deps를 `fn`에 위치 인자(lazy State 핸들)로도 노출하는 확장, 최종 시그니처 `fn(self, previous?, ...deps)` — 이형(heterogeneous) 다중 deps를 제네릭 타입 팩(`U...`)으로 표현 가능한지, `previous?`가 팩 앞(정정된 순서)에서만 통과하고 팩 뒤(옛 순서)에서는 막히는지 | `source-state-plan.md` "trailing deps를 fn에 lazy positional 인자로도 노출" 절(2026-08-11 후속 세션, 순서는 같은 날 세 번째 세션에 정정) |
| `16-type-store-key-typefunction.luau` (타입체크 전용) | `Store<T>`가 `T`의 각 필드를 `Source`로 감싼 타입을 Luau `type function`(`types.newtable`/`:setproperty`/`ty:properties()`)으로 실제 합성 가능한지, 결과가 구조적으로 `Source<T>` 필드를 만족하는지. **[2026-08-15] 통과 → `done/`** — 원인은 설계가 아니라 `types.newfunction` API 버전 드리프트였음, `audit/type-recursive-issue-with-typeof/REPORT.md` 6-1절 | `typing-limits.md` "`store.key` 레코드 필드 타이핑" 절(2026-08-12 열일곱 번째 세션), `pre-implementation-audit.md` 1-10 |
| `17-modifier-index-tableclone-chaining.luau` | Modifier의 제네릭 `__index`+`table.clone` 체이닝 — 임의 필드 이름에 대해 즉석 setter가 만들어지는지, `table.clone`이 메타테이블을 참조로 공유해 여러 단계 clone에서도 체이닝이 안 끊기는지, 원본이 mutate 안 되는지, 형제 분기끼리 오염 안 되는지 | `modifier-plan.md` "런타임은 클래스별 코드 없이 base에 딱 하나만 있으면 됨" 절 + "`table.clone`의 정확한 동작 — 확인됨" 절(2026-08-12 열일곱 번째 세션), `pre-implementation-audit.md` 1-11 |
| `18-relate-mutual-cycle-gc.luau` | **[2026-08-13 신규]** 서로 다른 두 `Relate`가 서로의 키를 상대방의 강한 값으로 제공하는 상호 순환은 Luau에 ephemeron이 없어 GC가 못 푼다는 주장(지금까지 공식 문서 인용으로만 뒷받침됨) — 음성 대조군(순환 재현)과 양성 대조군(한쪽을 weak-value로 낮추면 풀리는지) 둘 다 실측 | `relate-plan.md` "위험한 패턴" 절(2026-08-12 열세/열네 번째 세션), `slot-plan.md`의 `kSlotMap`/`slotOwner`/`elementOwner` 실사례 |
| `19-ownership-refcount-relate-patterns.luau` | **[2026-08-13 신규, 같은 날 B/C 전면 재작성 — 지금은 현행 설계 기준]** 세 소유권/참조카운트 알고리즘 검증. **A**: Tag `tagNameMap` 참조 카운트(여러 위치가 같은 이름을 겹쳐 가져도 마지막 홀더가 빠질 때만 실제 `RemoveTag`. 옛 `kTagMap`은 클로저 캡처로 대체돼 삭제됨). **B**: Attribute 이름 소유권 — 공개 `AttributeKey(name)` 캐시 + `Dispatch.process`의 인덱스 1 **점유 체크**가 충돌을 잡는지(옛 `rawNew`+`owners` 수동 레지스트리는 폐기). **C**: Slot 소유권 — nested 엄격 `claimOwner`(같은 owner 재클레임도 error) vs top-level `claimOwnerAt(inst,k)`(정확히 같은 자리 재발행만 no-op). **셋 다 음성 대조군 포함** — 옛 로직이 `Slot{a,a}`/`Frame{slot,slot}`을 조용히 통과시키는 걸 재현. **[2026-08-13 열네 번째 세션] 0-Z가 확정되며 B 섹션이 낡음 → `rewrite-required/`** — 이제 "그룹 전용 키 + `AttributeKeyHandler`의 이름 claim"을 검증해야 함(A/C는 그대로 유효) | `tag-plan.md` "메커니즘", `attribute-plan.md` "이름 소유권", `slot-plan.md` "요소 소유권" |
| `20-slot-splice-index-arithmetic.luau` | **[2026-08-13 신규]** `Slot:Splice(index, removeCount, ...newElements)`의 shift+recompute 1회 계산이, `Extract`/`Add` 반복으로 재현한 참조 구현과 항상 같은 결과를 내는지 — 제거/삽입 길이가 다를 때(delta 양수/음수) 뒤 요소가 밀리는 방향과 양을 헷갈리는 off-by-one 위험(이 프로젝트가 `Dispatch.recompute`에서 실제로 냈던 것과 같은 클래스의 버그)을 경계값 케이스로 검증 | `slot-plan.md` "확정" CRUD 표 + "`Splice` 신설" 절(2026-08-12 열다섯 번째 세션), `dispatch-core-plan.md`의 `recompute` off-by-one 수정 사례(2026-08-11 여섯 번째 세션) |
| `21-type-store-undeclared-key-rejected.luau` (타입체크 전용) | **[2026-08-19 신규]** `Store<{field: T}>`로 선언 안 된 이름에 dot-access하면 `type function`이 합성한 결과 타입(`ProcessStoreType`, `16`과 동일)에 그 프로퍼티가 없어 타입 시간에 거부되는지 — `store-plan.md`가 "아마 그럴 것"으로만 적어뒀던 걸 M0에서 실측. 통과: 미선언 키 접근 2건이 정확히 `TypeError`로 걸림 | `store-plan.md` "Store = Source들의 이름 붙은 모음" 절의 "[확인 요구, 2026-08-18 구현 전 QA]" 항목, `todos.md` 00번 |

## 공통 유틸리티

- `gc-trigger-helper.server.luau` — Roblox Studio(collectgarbage() 미노출
  환경)에서 GC 완료를 간접 관찰하는 `waitForGC()` 스니펫. Studio 기반
  스파이크(`10` 등)가 "GC가 끝날 때까지 기다렸다가 weak 참조가 사라졌는지
  확인"해야 할 때 그대로 복붙해서 쓸 것. 순수 luau CLI 스크립트(`07` 등)는
  `collectgarbage()`를 직접 부르면 되므로 이 헬퍼가 필요 없음 — 발견 경위는
  `audit/gcconn-trick-verification.md` 참고.

## 갱신 이력

**1차 (2026-08-09 저녁, `8169b90`~`5836c2d` 반영)**: 01/02/05/06/07/08/09는
검증 대상 API가 그대로였고, `03`/`04`에 참고 노트 추가, `10` Part A 갱신
(canBound/unbindLifetime 반영), `11` 신규 추가.

**2차 (2026-08-09 커밋 `f198fd9`, "중간검토(질문 모드)에서 발견된 설계
결함 다수 수정" 반영)** — 사용자가 직접 `.claude/base/` 전체를 훑으며
찾은 정정들 중 이 폴더(당시 `luau-ignoreme/`)에 영향 있는 것만:

- `02`: **전면 재작성.** 이전 버전은 "Ref 콜백/대기자 배열도 None으로
  소진해야 한다"고 잘못 적어뒀는데, 이게 실제로는 무한 성장 버그였음이
  드러나 `nil`로 되돌아감(순서가 안 중요하고 슬롯 재사용이 필요한
  배열은 `nil`, 순서가 중요한 배열(PreRef pre-pass/sourceList)은
  계속 `None` — 두 카테고리로 나눠 각각 재현).
- `12`/`13`/`14`: **신규 추가.** 사용자 요청으로 "타입 관련 실측 필요
  항목, 특히 luau-lsp로 확인해야 하는 것"을 새로 찾아 만듦 — Attribute
  제네릭 특수 키의 값 타입 narrowing(12), Ref/PreRef 구조적 서브타입 +
  `isRef`/`isPreRef` 재정정(13), Source/Ref의 nilable-default 캐비엇을
  오버로드로 막을 수 있는지(14). 셋 다 base 문서가 "미검증"/"실측 필요"
  로 스스로 표시해둔 지점이거나(12, 14) 이번 f198fd9에서 뒤집힌 결정
  (13)이라 기존 파일 중 커버하는 게 없었음.
- `01`/`03`~`11`(위 02 제외)은 f198fd9의 다른 변경(Slot CRUD 인덱스
  기준 전환, Source 리프 직접 바인딩 정상 경로 재확인, Dispatch 직접
  호출 UB 명시, Tag retract 전제 명시, Attribute 타입 파라미터화 확정
  등)과 대조해본 결과 검증 대상 API에 영향 없어 안 건드림.

**3차 (2026-08-09, 폴더 이동)**: `luau-ignoreme/` → `.claude/luau-test/`로
이동, git 추적 대상으로 전환. 내용 변경 없음 — 경로 참조하는 문구만
동기화.

**4차 (2026-08-11, `15` 신규)**: `:Compute(fn, ...)`의 trailing deps를
`fn`의 위치 인자로도 노출하는 확장(같은 날 두 번째 세션) — 이형 다중
deps의 제네릭 타입 팩 표현 가능 여부와 `previous?`를 팩 뒤에 붙일 수
있는지가 base 문서 자신이 "실측 필요"로 명시한 새 항목이라 추가.

**5차 (2026-08-11, 같은 날 세 번째 세션, `previous` 순서 정정)**:
4차에서 "previous를 팩 뒤에"로 적었던 순서가 틀렸음이 드러남 — Luau
값 레벨 `...`가 파라미터 리스트 맨 끝이어야 하는 것과 같은 제약으로
`previous?`는 deps 팩 **앞**(self 바로 다음)에 와야 함. `15`의 (C)를
"틀린 순서가 막히는지 보는 음성 대조군"으로 재정의하고, 정정된 순서를
검증하는 (D) 양성 대조군을 신규 추가 — 이제 진짜 불확실성은 (B)
이형 다중 deps의 제네릭 팩 표현 가능 여부 하나뿐.

**6차 (2026-08-12, 열일곱 번째 세션, `16`/`17` 신규)**: `pre-implementation-audit.md`
우선순위1의 마지막 두 항목(1-10 `store.key` 타이핑, 1-11 Modifier
`__index`+`table.clone` 트릭)이 이 세션에 설계 레벨로는 해소됐지만, 실제
Luau로 부딪혀본 적은 없다는 걸 핸드오버 점검 중 발견 — `16`(type function
스케치, 타입체크 전용)/`17`(제네릭 __index 체이닝, 런타임)로 신규 추가.
둘 다 이전까지 이 폴더 어디에도 커버 대상이 없던 완전히 새 항목.

**7차 (2026-08-13)**: `10`의 A 섹션 앞부분(ClassName 신호 미발화,
`Destroy()` 시 `Connection.Connected` 즉시 전환)을 사용자가 공식 파일이
아닌 자작 스크립트로 먼저 실측 — 결과는 `.claude/audit/
gcconn-trick-verification.md`에 정리(부분 확인, A-1/A-2/B/C는 아직 official
`10`으로 재확인 필요). 부수적으로 Studio에서도 GC 완료를 간접 관찰하는
기법을 발견해 `gc-trigger-helper.server.luau`로 분리, `07`의 "Studio에서
GC 검증 불가" 서술도 이에 맞춰 정정.

**8차 (2026-08-13)**: `18` 신규 추가 — 2026-08-12 열세/열네 번째 세션에서
`relate-plan.md`에 확정된 "두 `Relate` 상호 강참조 순환은 ephemeron 없이는
GC가 안 풂" 주장이 지금까지 공식 문서 인용으로만 뒷받침돼 있었고 실제
Luau로 재현해본 적이 없었던 갭 — `Slot`의 `kSlotMap`/`slotOwner` GC 수정
사례(session 13/14) 전체가 이 사례 하나에 기대고 있어 우선순위 있게 추가.

**9차 (2026-08-13)**: `.claude/session-summary.md` 세션 8~21(대부분 2026-08-12) 전체를 대상으로
"새 메커니즘 중 실 Luau로 안 부딪혀본 게 더 있는가"를 재점검 — Ref/Slot의
`Relate` diff 기반 retract(세션 8/9)는 03/04번이 이미 검증한 것과 같은
클래스의 재귀 dispatch/체인 로직이라 스킵. 반면 Tag 참조 카운트(세션 11/16)
+ Attribute `rawNew` 소유권(세션 10) + Slot `elementOwner` 소유권 판정
(세션 12, GC 쪽은 이미 18번이 커버)은 "여러 위치가 하나의 이름/자리를
공유"하는 셋 다 새로운 알고리즘 모양이라 `19` 하나로 묶어 신규 추가.
`Slot:Splice`(세션 15)는 순수 index 산술이지만 이 프로젝트가 같은 클래스
(`recompute` off-by-one)에서 실제 버그를 낸 전례가 있어 `20`으로 별도
신규 추가. 그 외(`Tag:Added`의 vararg→`string|{string}` 전환, Attribute의
"retract 완전 no-op" 재정정 등)는 단순 분기/타입 정리라 스파이크 불필요로
판단, 추가 안 함.

**10차 (2026-08-13)**: 사용자가 Haskell Monad/Applicative 리서치 중
`retractUnder`의 꼬리부터-cutoff 로직을 직접 되짚다가 "같은 키에서 핸들러가
재사용되면 문제 아닌가"를 제기 — 손으로 트레이싱해 `State<State<T>>`(store가
emit하는 값 자체가 또 State/Source)가 실제로 체인을 파손시킴을 확인
(`dispatch-core-plan.md` "확정된 디스패치 모델" 절 신규 항목). 기존 `04`가
정확히 이 시나리오(store-in-store)를 이미 스트레스 테스트로 다루고 있었지만,
`retract`가 print만 하는 no-op 스텁이라 자기-retract 버그의 실제 증상(구독이
조용히 끊기는 것)을 절대 드러낼 수 없었다는 사각지대도 같이 발견 —
`Dispatch.process`에 중복 핸들러 가드(push 전 체인에 같은 객체가 있으면
error)를 추가하고, `04`의 3~4단계를 "가드가 실제로 걸리는지 + 걸린 뒤에도
정상 복구되는지" 확인으로 재작성. `operator-sugar-plan.md`엔 별개로 nil 대체
콤비네이터 `Alternative` 후보를 신설(카탈로그에 이전엔 없었음).

**11차 (2026-08-13, 여섯 번째 세션) — 처음으로 실제 실행함.**
`luau`/`luau-analyze` 바이너리가 사용 가능해져, 2026-08-09 열두 번째 세션에
스파이크를 만들기 시작한 이래 **처음으로 돌려본 라운드**. 결과 전문은
`.claude/audit/luau-test-first-run-2026-08-13.md`. 요지:

- **런타임 8개 통과**(01/02/03/04/05/06/18/20) — 설계를 흔드는 결과 없음.
- **`04`가 이번 세션 감사에서 찾은 버그를 음성 대조군으로 재현** — 체인
  깊이가 3 대신 1로 무너지고, 죽은 store가 나중에 UI를 덮어쓰는 것까지
  실측됨. 감사→수정 사이클이 실측으로 닫힘.
- **`07`은 보강해야 실제 검증이 됐음** — 3번 섹션이 sanity check만 하고
  있었고 헤더의 핵심 주장(연쇄 GC)은 미검증이었음. 파일이 스스로 적어둔
  "weak table 엔트리를 셀 방법이 없다"는 전제가 틀렸음(outer가
  `__mode="k"`라 GC 후 `pairs`에서 그냥 사라짐) — `_countEntries()` +
  weak-value canary로 4번 섹션 신설, **GC-native 아키텍처의 핵심 전제가
  실측 확인됨**.
- **`18`이 `relate-plan.md`의 상호 순환 경고를 실증** — 추측이 아니라
  실제로 GC가 안 됨. `Slot`의 두-`Relate` 수정이 필수 조치였음이 입증.
- **`17` 크래시**(44행, 아무것도 검증 못 함), **`11`의 "다른 Modifier"
  케이스가 엉뚱한 이유로 통과** — 둘 다 스파이크 코드 결함, 수정 대상.
- 타입 스파이크(08/09/12/13/14/15/16)는 음성 대조군이 섞여 있어 헤더 의도와
  대조해야 판정 가능 — 별도 진행. `15`는 `SyntaxError`로 파싱 자체가
  안 되는 상태(= 아무것도 검증 못 함)인 것만 먼저 확정.

**12차 (2026-08-14, 다섯 번째 세션, `10` → `rewrite-required/`)**:
`bindLifetime`/`canExecute`/`unbindLifetime` 시그니처가 재정정되면서
(`canExecute`/`unbindLifetime`이 `inst`를 안 받는 1-인자, `.Subscribed`는
전역 `:Subscribe()` 전용이라 `bindLifetime`과 무관, 별도 predicate
`canBound` 폐기, gcconn/gchold는 Instance 생성 시점 생성) `10`의 A 섹션이
폐기된 모델을 검증하게 됨 — 코드 본문은 그대로 두고 헤더에 재작성 사유만
달아 이동. **A가 검증하려던 것 중 "ClassName 신호 미발화 / Destroy 시
Connected 즉시 전환"은 새 모델에서도 유효**(재작성 시 살릴 것). 정본은
`base/lifecycle-pattern.md`, 역전 경위는
`archive/canexecute-inst-arg-reversed.md`.

## 결과 확인 후 할 일

각 파일 결과를 알려주면, 실제로 걸리는 부분이 있는지 보고 필요하면
`.claude/base/` 문서를 그 자리에서 고침(ROADMAP.md M0 통과 기준 그대로:
"안 되면 여기서 관련 base/ 문서부터 고치고 재시도"). 특히:

- `08`/`09`가 luau-analyze에서 에러를 내면 어떤 정확한 에러 메시지인지가
  다음 타입 설계 방향(펼쳐 쓰기 vs `any` fallback)을 결정하는 데 중요함.
- `07`이 예상대로 GC가 안 되는 것처럼 보이면(90개 안 죽는 것 같으면),
  `collectgarbage("count")` 수치 변화를 같이 알려줄 것 — 정확한 판정이
  어려운 항목이라 참고 신호로만 쓸 것.
- `10`은 **[2026-08-14 다섯 번째 세션] A 섹션을 먼저 재작성해야 함**(현재
  `rewrite-required/`) — 아래 판정 기준은 재작성 후에 적용할 것.
  - `warn`이 실제로 뜨면(ClassName Changed가 발화함) gcconn 트릭 전체를
    재검토해야 하는 심각한 발견이니 바로 알려줄 것 — **[2026-08-13] 이
    조건은 이미 회피 확인됨**(`audit/gcconn-trick-verification.md`),
    재확인 불필요.
  - **[2026-08-14 열한 번째 세션 재정정, 2026-08-18 방향 정정]** 이중
    바인딩 게이트는 **`canBound(value)`**다(`if not canBound(v) then
    error(...) end` — `canBound` 참 = "지금 묶어도 됨") —
    `canExecute`는 State emit 전파 게이팅 전용으로 남고, `canBound`가
    별도 진입점으로 재도입됨(판정 로직은 비공개 헬퍼 하나를 공유하되
    **서로의 부정**, `lifecycle-pattern.md` "`canBound` vs `canExecute`"
    절). 판정 기준은 안 바뀜: `unbindLifetime(value)` 이후 같은 값을 다시
    `bindLifetime`할 수 있어야 하고(게이트가 `canBound` **참**이라
    통과), **`inst`가 Destroy된 뒤의 재바인딩도 명시적으로 허용**임
    (살아있는 바인딩만 막는 게 게이트의 의도). 이게 실패하면 이
    재분리 설계 자체를 재검토해야 함 — **아직 미확인.**
  - 새로 검증할 항목: `bindLifetime`이 `value` 쪽 릴레이션에 복사해둔
    gcconn만으로 `inst` 생존을 판정할 수 있는가(=`canBound`/`canExecute`가 `inst`
    없이 성립하는가), gcconn/gchold를 **Instance 생성 시점**에 만들 때
    클로저가 `inst`까지 캡처해 userdata 동일성이 유지되는가.
- `04`는 **[2026-08-13 여섯 번째 세션에 전면 재작성 — 옛 판정 기준 폐기]**
  두 시나리오를 연달아 돌림. **정상 설계**는 [1] 체인 깊이 3, [3] 옛 inner
  구독 0, [4] `STALE` 미반영이 기대값. **음성 대조군**은 [1] 깊이가 **1**로
  무너지고 [4]에서 `STALE`이 반영되는 게 기대값(= 버그가 재현돼야 정상).
  대조군이 정상 시나리오와 똑같이 나오면 스파이크 모델링이 실제 구현과
  어긋난 것이니 스파이크 쪽을 먼저 의심할 것. (옛 기준이던 "3단계에서
  error로 막혔는가"는 다섯 번째 세션이 그 가드 자체를 없애서 폐기됨.)
- `11`은 전부 PASS가 기대값 — FAIL이 하나라도 있으면 어느 케이스인지
  그대로 알려줄 것(특히 "변환 함수가 반환한 값" 케이스는 놓치기 쉬운
  경로라 실제 구현에서도 잘 짜였는지 중요한 신호).
- `02`의 Part B-2("None + table.insert" 대조군)가 실제로 배열 길이 1000까지
  자라는 게 확인되면 사용자가 찾은 버그가 정량적으로 재현된 것 — 반대로
  안 자란다면 정정 근거 자체를 재검토해야 하니 꼭 알려줄 것.
- `12`/`14`는 **어느 쪽으로 나와도 유용한 정보** — 통과하면 그 타입
  패턴을 실제 설계로 채택, 실패하면 `any`/정적 타입 패밀리로 fallback한다는
  각 파일의 결론 그대로 base 문서에 반영하면 됨. 정확한 luau-lsp 에러
  메시지(어느 줄, 어떤 문구)를 그대로 붙여서 알려주면 다음 문서 갱신이
  빠름.
- `13`은 A(타입)/B(런타임) 둘 다 확인해줄 것 — B의 assert가 실패하면
  `Dispatch/Leaf.luau` 설계(`isRef(v) and not isPreRef(v)`) 자체가
  잘못 짜인 것이니 우선순위 높게 알려줄 것.
- `16`은 **어느 쪽으로 나와도 유용** — 통과하면 `store.key` 타이핑을 이
  type function 방식으로 그대로 채택, API 이름이 틀려서 막히면(`type
  function`이 비교적 새 기능이라 가능성 높음) 정확한 에러 메시지를 그대로
  알려줄 것 — 다음 시도의 API 이름을 고치는 데 바로 쓰임. 아예 이 Luau
  버전이 `type function` 자체를 지원 안 하면 그것도 알려줄 것(다른 대안
  필요).
- `17`은 전부 PASS가 기대값 — 특히 (B) 메타테이블 참조 동일성 assert가
  실패하면 M7 전체 설계("클래스별 런타임 코드 불필요")의 핵심 전제가
  무너지는 것이니 최우선으로 알려줄 것.
- `18`은 1번 섹션이 true/true, 2번 섹션이 false/false로 나와야 기대값 —
  둘 중 하나라도 다르면(특히 `warn`이 뜨면) `relate-plan.md` "위험한 패턴"
  절과 `slot-plan.md`의 `kSlotMap`/`slotOwner`/`elementOwner` GC 설계
  전체를 최우선으로 재검토해야 함(Slot GC 안전성의 유일한 근거였음).
- `19`는 전부 PASS가 기대값 — A 섹션이 FAIL이면 `tag-plan.md`의 참조
  카운트 알고리즘 자체를, C 섹션이 FAIL이면 `slot-plan.md`의 `elementOwner`
  설계를 최우선으로 재검토할 것. **[2026-08-13 판정 기준 정정]** C의 기대
  동작이 바뀌었음 — 예전의 "같은 owner 재클레임은 no-op"은 버그로 판정돼
  둘로 쪼개짐: **nested `claimOwner`는 같은 owner 재클레임도 error**(엄격),
  **top-level `claimOwnerAt(element,inst,k)`만** 정확히 같은 `(inst,k)`의
  재발행에서 `false`. 옛 문구를 그대로 적용하면 정상 동작(nested error)을
  실패로 오판함 — C가 깨지면 재귀 재emit마다 마운트된 서브트리 전체가
  파괴됐다 재생성되는 파괴적 버그로 직결됨.
- `20`도 전부 PASS가 기대값 — FAIL이 있으면 어느 케이스(특히 delta 부호가
  바뀌는 경계값)인지와 최종 배열/제거분이 어떻게 달랐는지 그대로 알려줄
  것, `Slot:Splice`의 shift 방향/양 계산에 off-by-one이 있다는 뜻이라
  `slot-plan.md` "확정" CRUD 표를 바로 고쳐야 함.
