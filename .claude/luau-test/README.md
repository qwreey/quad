# .claude/luau-test — M0 착수 전 실 Luau 기술검증 스파이크 모음

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
독립 실행 가능한 스크립트로 만들었음. **내가(에이전트) 직접 실행은 못
했음** — 이 환경엔 `luau`/`luau-analyze` 바이너리가 없어서, 전부 사용자가
직접 돌려보고 결과를 알려줘야 함.

각 파일 맨 위 주석에 다음이 전부 적혀있음: 뭘 검증하는지, 어느 base 문서/
ROADMAP 항목 근거인지, 어떻게 실행하는지, 실행 후 뭘 확인해야 하는지.

## 실행 환경 세 갈래

| 환경 | 필요한 것 | 해당 파일 |
|---|---|---|
| **순수 Luau CLI** (`luau`) | [luau-lang/luau 릴리즈](https://github.com/luau-lang/luau/releases)의 `luau` 인터프리터, 또는 `lune` | 01, 02, 03, 04, 05, 06(런타임 부분), 07, 11, 13(런타임 부분), 17 |
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
| `01-two-pass-array-hash-order.luau` | 배열 파트(children/Ref) 먼저, 해시 파트(프로퍼티/이벤트) 나중이라는 두 패스 순회 계약 | `bind-system-plan.md` "props 순회 순서", ROADMAP M0-4 |
| `02-none-sentinel-vs-nil-holes.luau` | **[2026-08-09 커밋 f198fd9 반영해 전면 재작성]** 순서가 중요한 배열(PreRef pre-pass, sourceList)은 `None` 소진이 맞고, 순서가 안 중요하고 재사용이 필요한 배열(Ref 콜백/대기자)은 `nil`+슬롯 재사용이 맞다는 최종 구분 + `None`을 잘못 쓰면 배열이 무한정 자라는 버그의 정량적 재현 | `bind-system-plan.md` "왜 None이 아니라 nil인가"(2026-08-09 열한 번째 세션 최종 정정), ROADMAP M0-4 |
| `03-recursive-store-bind-dispatch.luau` | `process`/`retract` 재귀 재-dispatch 기본 모델, 우선순위 스캔 | `bind-system-plan.md` "확정된 디스패치 모델", ROADMAP M0-3 |
| `04-dispatch-chain-retractUnder.luau` | `Dispatch` 체인 + `retractUnder`가 다단(A→B→C) 재-dispatch에서 정확한지 | `bind-system-plan.md` "Dispatch 체인", 2026-08-08 세 번째 세션 |
| `05-store-state-diamond-propagation.luau` | push-invalidate/pull-recompute가 다이아몬드 의존성에서 중복 재계산 없이 동작하는지 | ROADMAP M0-1 |
| `06-component-boundary-nil-hole-props.luau` | `props.Modifier or None` 관용구가 컴포넌트 경계 nil-hole을 막는지 + `Params` 타입 체크 | `component-composition-plan.md` "필수 관용구", ROADMAP M0-5 |
| `07-relate-weak-table-gc.luau` | `Relate`의 lazy 서브테이블 생성 + weak-key GC가 실제로 동작하는지 | `relate-plan.md` "M2 착수 시 실측 확인" |
| `08-type-source-satisfies-state.luau` (타입체크 전용) | `Source<T>`가 `State<T>`를 구조적으로 만족하는 제네릭 타입이 솔버에서 안전한지 | `store-semantics.md` "검증 필요", ROADMAP M0-2 |
| `09-type-modifier-overridden-subtype.luau` (타입체크 전용) | `FrameModifier <: GuiObjectModifier`처럼 서브타입 관계인 Modifier를 `Overridden`으로 섞을 때 타입이 통과하는지 | `modifier-plan.md` 9-2번, ROADMAP M7 |
| `10-roblox-studio-checks.server.luau` (Studio 전용) | (A) `bindLifetime`/`unbindLifetime`/`canExecute`/`canBound`의 gcconn 트릭 + 이중 바인딩 게이트(Destroy 시 Connected 전환 포함), (B) Attribute의 Instance 참조 타입 지원, (C) CollectionService 태그/GetTagged 왕복 | `lifecycle-pattern.md`, `bind-system-plan.md` "이중 바인딩 금지", CLAUDE.md 2026-08-06 세션, `debug-tooling-plan.md` |
| `11-modifier-illegal-value-error.luau` | Modifier 필드에 Ref/PreRef/Observer/Effect/Slot/Modifier가 들어오면 즉시 error, State/Source가 확정하는 값이 Modifier면 즉시 error(2026-08-09 세션에 "UB"에서 전환된 규칙) | `modifier-plan.md` "핸들러 계층 값 즉시 error" 절 + 7번 절 |
| `12-type-attribute-generic-key-narrowing.luau` (타입체크 전용) | `[AttributeKey<<T>> "name"] = value`(구 `Attribute<<T>>`)처럼 제네릭 DI 키를 쓸 때 `value`의 타입이 실제로 `T`로 좁혀지는지 — base 문서 자신이 "미검증"이라 명시한 항목 | `attribute-plan.md` "[실측 필요, M0/M10]" (2026-08-09 열한 번째 세션 신설) |
| `13-type-ref-preref-subtype.luau` | (A, 타입) `PreRef<T>`가 `Ref<T>`를 구조적으로 만족하는지, (B, 런타임) `isRef`/`isPreRef` 합성이 재정정대로 동작하는지(`isRef(preRefInstance)`가 이제 `true`) + Leaf 핸들러가 `isRef(v) and not isPreRef(v)`로 명시적으로 좁혀야 하는 이유 | `bind-system-plan.md`의 `Brand` 절(2026-08-09 열한 번째 세션 재정정) |
| `14-type-nilable-default-overload.luau` (타입체크 전용) | `Source(default)`/`Ref(default)`의 `default` 생략이 `T`가 nilable일 때만 안전하다는 캐비엇을, 함수 오버로드(교차 타입)로 실제로 타입 레벨에서 막을 수 있는지 | `bind-system-plan.md` "[보강, 2026-08-09 열한 번째 세션]" 절 |
| `15-type-compute-trailing-deps-typepack.luau` (타입체크 전용) | `:Compute(fn, ...)`의 trailing deps를 `fn`에 위치 인자(lazy State 핸들)로도 노출하는 확장, 최종 시그니처 `fn(self, previous?, ...deps)` — 이형(heterogeneous) 다중 deps를 제네릭 타입 팩(`U...`)으로 표현 가능한지, `previous?`가 팩 앞(정정된 순서)에서만 통과하고 팩 뒤(옛 순서)에서는 막히는지 | `bind-system-plan.md` "trailing deps를 fn에 lazy positional 인자로도 노출" 절(2026-08-11 후속 세션, 순서는 같은 날 세 번째 세션에 정정) |
| `16-type-store-key-typefunction.luau` (타입체크 전용) | `Store<T>`가 `T`의 각 필드를 `Source`로 감싼 타입을 Luau `type function`(`types.newtable`/`:setproperty`/`ty:properties()`)으로 실제 합성 가능한지, 결과가 구조적으로 `Source<T>` 필드를 만족하는지 | `bind-system-plan.md` "`store.key` 레코드 필드 타이핑" 절(2026-08-12 열일곱 번째 세션), `pre-implementation-audit.md` 1-10 |
| `17-modifier-index-tableclone-chaining.luau` | Modifier의 제네릭 `__index`+`table.clone` 체이닝 — 임의 필드 이름에 대해 즉석 setter가 만들어지는지, `table.clone`이 메타테이블을 참조로 공유해 여러 단계 clone에서도 체이닝이 안 끊기는지, 원본이 mutate 안 되는지, 형제 분기끼리 오염 안 되는지 | `modifier-plan.md` "런타임은 클래스별 코드 없이 base에 딱 하나만 있으면 됨" 절 + "`table.clone`의 정확한 동작 — 확인됨" 절(2026-08-12 열일곱 번째 세션), `pre-implementation-audit.md` 1-11 |

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
  제네릭 DI 키의 값 타입 narrowing(12), Ref/PreRef 구조적 서브타입 +
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

## 결과 확인 후 할 일

각 파일 결과를 알려주면, 실제로 걸리는 부분이 있는지 보고 필요하면
`.claude/base/` 문서를 그 자리에서 고침(ROADMAP.md M0 통과 기준 그대로:
"안 되면 여기서 관련 base/ 문서부터 고치고 재시도"). 특히:

- `08`/`09`가 luau-analyze에서 에러를 내면 어떤 정확한 에러 메시지인지가
  다음 타입 설계 방향(펼쳐 쓰기 vs `any` fallback)을 결정하는 데 중요함.
- `07`이 예상대로 GC가 안 되는 것처럼 보이면(90개 안 죽는 것 같으면),
  `collectgarbage("count")` 수치 변화를 같이 알려줄 것 — 정확한 판정이
  어려운 항목이라 참고 신호로만 쓸 것.
- `10`의 A 섹션에서 만약 `warn`이 실제로 뜨면(ClassName Changed가
  발화함), gcconn 트릭 전체를 재검토해야 하는 심각한 발견이니 바로 알려줄 것.
  A-2(재-bindLifetime 허용 여부)가 실패하면 `canBound`/`unbindLifetime`
  설계 자체를 재검토해야 함.
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
