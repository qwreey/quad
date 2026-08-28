# 세션 히스토리 (요약 색인)

루트 `CLAUDE.md`가 `@import` 하지 **않음 — 의도적**. 세션마다 계속 자라는
히스토리 문서라 통째로 매 세션 컨텍스트에 올릴 이유가 없다는
판단(2026-08-16). 선행 맥락이 필요할 때만 grep해서 읽는 온디맨드 자료.

**[2026-08-16 기준] 이 파일은 아직 손으로 관리 중이지만, 곧 전체 자동생성으로
전환 예정** — 각 `.claude/session/*.md`가 자기 요약을 마커 블록으로 들고 있고
생성기가 그걸 모아 이 파일을 통째로 다시 쓰는 방식(설계는
`.claude/research/doc-include-plan.md`). **전환이 끝나면 이 파일은 직접 편집
금지 대상이 됨** — 그때부턴 요약을 고치려면 해당 세션 파일의 마커 블록을 고칠 것.


전체 설계는 여러 세션에 걸쳐 대화로 확정됐음. **아래는 탐색용 압축 요약이고,
지금 유효한 설계의 소스는 항상 `.claude/base/`** — 여기 요약이나 세션 원문과
`base/`가 어긋나면 `base/`가 맞음(더 최근 결정이 반영돼 있음). 각 항목의
원문(시행착오·정정 전 서술 포함, `quadnomicon` 개발로그 소재용)은
`.claude/session/`에 그대로 보존돼 있음 — 결정의 배경/논쟁 과정이 궁금할
때만 열어볼 것.

**이 파일을 갱신하는 방법(중요, 반복 방지용)**: 세션이 끝나면 (1) 전체
서술은 `.claude/session/YYYY-MM-DD-NN-slug.md`로 새로 저장하고, (2) 여기엔
2~4줄 압축 요약 + 그 파일로의 링크만 추가할 것. **절대 여기에 전체 논의
과정을 그대로 쌓지 말 것** — 그게 바로 루트 `CLAUDE.md`가 3000줄 넘게 불어나
성능 저하를 유발했던 원인(2026-08-11 정리 세션에서 발견, 상세는
`.claude/session/2026-08-11-08-claude-md-restructure.md` 참고 — 그때 세션
원문을 `session/`으로 뺐고, 2026-08-16에 요약까지 이 파일로 마저 뺐음).
base/research/archive 반영이 그 세션 안에서 끝났는지 먼저 확인 후에 여기
추가할 것 — 반영 안 된 게 있으면 archive/session 이전보다 그 반영이 항상
먼저.

**2026-08-04 — 로드맵 인수인계** (`session/2026-08-04-01-roadmap-handoff.md`)
Modifier 메커니즘 전체 확정(immutable clone 체이닝), 컴포넌트화 논의 완결
(modifier/Ref는 named parameter로 컴포넌트 경계 통과, "멀티루트" 개념 폐기),
`.claude/` 코퍼스 전체 감사·정리, quad-base 테스트 mock 방향 확정,
`ROADMAP.md` 신설 — 설계 단계 종료, 다음 세션부터 M0 착수 예정.

**2026-08-06 세션 — quad-debug 설계** (`session/2026-08-06-01-quad-debug-design.md`)
런타임 디버깅 플러그인 `quad-debug` 설계(백로그, "quad 개발 상당 부분 끝난
뒤" 착수). Studio 플러그인↔Play 중 게임 간 BindableEvent 채널이 실제로
작동함을 사용자가 직접 실측 검증. UICorner/UIPadding/UIScale 인라인 숏핸드,
Attribute 타입 파라미터화 논의 신설.

**2026-08-06 후속 세션 — 이벤트 self 관습, rbvm GC, 코퍼스 정리**
(`session/2026-08-06-02-event-self-rbvm-corpus.md`)
이벤트 핸들러가 v1처럼 self(Instance)를 받는 관습은 채택 안 하기로 확정
(Ref가 이미 커버, 이중 쓰기 경로 방지). `Store:Emit`/`:Compute`의 `previous`
인자/`state:Observer(fn)`/Ref 일반화(범용 값 박스로 확장) 확정. Observer
이름 확정, 생성자 스타일(`Type(args)`) 통일, "독립 프리미티브 vs 파생
데이터" 원칙 신설.

**2026-08-06 세 번째 세션 — 문서 사이트 구조, 프레임워크 비교, Source⊇State**
(`session/2026-08-06-03-docsite-source-state.md`)
문서 사이트 4축(초심자/api/심화/`quadnomicon`) 구조 확정. quad vs
Fusion/Vide/react-lua 정직 비교 완료. **핵심**: `Source<T>`가 구조적으로
`State<T>`를 만족하는 서브타입 재구성 — `StoreSource` 프록시 폐기,
`store.key = value` 대입 문법 폐기하고 `:Set()`으로 전환.

**2026-08-06 네 번째 세션 — M0 착수 직전 크리티컬 감사**
(`session/2026-08-06-04-pre-implementation-audit.md`)
`.claude/base/` 전체를 모호성/지연결정리스크/단순화후보 세 렌즈로 재감사,
`research/pre-implementation-audit.md` 신설(우선순위1 11개 등). 대부분은
이후 세션에서 해소됨(우선순위1 11개 전원) — 현재 상태의 원본은
`research/pre-implementation-audit.md`.

**2026-08-07 세션 — `:With`도 새 State 노드** (`session/2026-08-07-01-with-new-node.md`)
`:With(...)`는 clone 빌더가 아니라 매번 새 State 노드를 만드는 것으로 확정
— 디버그 그래프가 코드 호출 체인과 1:1 대응해야 함, `:With(a,b,c)` 가변인자로
노드 남발 문제는 해소.

**2026-08-07 두 번째 세션 — `Modifier:Apply`** (`session/2026-08-07-02-modifier-apply.md`)
Jetpack Compose류 커스텀 확장 함수 패턴을 콤비네이터로 흉내낸
`mod:Apply(factory)` sugar 채택 — `function(self,factory) return factory(self) end`.

**2026-08-07 세 번째 세션 — `PreRef` 신설** (`session/2026-08-07-03-preref.md`)
base 디스패치 드라이버가 "배열(children/Ref) 먼저, 해시(프로퍼티/이벤트)
나중" 두 패스를 명시적으로 계약. `CreatedRef`의 `phase` 옵션 폐기(배열
위치로 공짜 표현). 이벤트보다도 먼저 채워져야 하는 self-ref 전용으로
`PreRef` 신설(호이스팅, 동적 경로 도착 시 error).

**2026-08-07 네 번째 세션 — 코퍼스 전반 재편** (`session/2026-08-07-04-corpus-reorg.md`)
`reference/` 폴더 신설(v1 스냅샷/Fusion·Vide 비교를 온디맨드 자료로 분리),
`ui-shorthand-plan.md`를 `base/`로 승격, `Blocker`/`Effect` 확정 승격(`Batch`/
`Context`는 기각→archive), archive 제목 컨벤션을 `[역전됨]`/`[기각됨]`으로 분화.

**2026-08-07 다섯 번째 세션 — `Overridden`/`Peek`/`isState`, FuncSource 기각**
(`session/2026-08-07-05-override-peek-isstate.md`)
`Modifier.Override(mod1,mod2,...)`(뒤 인자가 필드 단위로 이김) 확정,
`:Peek(key)`(raw union 그대로 반환)/`isState` 신설. FuncSource(람다로
계산+self-emit하는 Source) 기각 — 이미 확정된 원칙들의 논리적 귀결.

**2026-08-07 여섯 번째 세션 — Ref/PreRef API, Tween GC 구조**
(`session/2026-08-07-06-ref-preref-api.md`)
Ref API를 `.Value`+`:Set`/`:Callback`/`:Wait`(전부 self 반환)로 확정,
Ref/PreRef 파일 분리. Tween per-instance 저장소가 GC-안전함을 확인.
Effect/Observer 관계 해소 시작(`state:Observer(fn)`는 등록 즉시 1회 실행).

**2026-08-07 일곱 번째 세션 — `:Compute` 커링, `state:Apply`, 이중 바인딩 금지**
(`session/2026-08-07-07-state-apply-effect-subscribe.md`)
`:Compute`/Effect/Observer의 `fn`은 커링 스타일 권장. `state:Apply(factory)`
sugar 확정(`Modifier:Apply`와 동형). `EffectHandle:Subscribe`/`:Unsubscribe`
신설. Observer/Effect 이중 바인딩은 `Bound` 플래그로 즉시 error.

**2026-08-07 여덟 번째 세션 — `None` 센티널, Dispatch 네이밍, `Brand`**
(`session/2026-08-07-08-none-sentinel-dispatch-brand.md`)
인라인 필드를 명시적으로 지우는 `None` 센티널 확정 — `NoneHandler`가
`process(inst,k,nil)`로 재귀 재디스패치(Tween store-bind와 같은 패턴, 새
메커니즘 아님). `Dispatch.getHandler`/`.process`/`.addHandler`/`.drive` 이름
공식화. `Tag`/`Attribute` 전용 문서 신설. `Brand` 통합 판별 메커니즘(`isState`를
10종으로 일반화) 신설.

**2026-08-07 아홉 번째 세션 — 코퍼스 정합성 감사, `CreatedRef` 폐기**
(`session/2026-08-07-09-corpus-audit-createdref.md`)
stale 참조 12개 수정, `archive/agent-mistake.md` 신설(에이전트 자체 개념
혼동 정정 이력 전용 카테고리). `CreatedRef` 이름 완전 폐기 — `Ref(default)`/
`PreRef(default)` 인스턴스를 children 배열에 직접 놓으면 되므로 별도 래퍼
불필요했음이 드러남. `PreRef` pre-pass 위치/순서/동적 경로 가드 확정.

**2026-08-07 열 번째 세션 — 소진 슬롯은 `None`, Ref 콜백 배열은 별개**
(`session/2026-08-07-10-none-vs-nil-order.md`)
사용자가 Luau REPL로 "정수 키가 촘촘하지 않으면 순회 순서가 안 보장됨"을
직접 실증 — 순서가 중요한 배열(PreRef pre-pass)은 `None`으로 소진.
`props.Modifier or None`/`props.Ref or None` 필수 관용구 확정.

**2026-08-08 세션 — `Relate` 신규 프리미티브** (`session/2026-08-08-01-relate-bindlifetime.md`)
`bindLifetime`/`canExecute`(inst,value) 탑레벨 함수로 확정, 그 저장소로
`inst`를 weak 키로 하는 범용 릴레이션 `Relate` 신설(구 `perInstanceState`
placeholder 대체). `retract` 필드는 no-op이어도 생략 불가로 확정.

**2026-08-08 두 번째 세션 — Dispatch는 싱글톤, 네이밍 케이싱 컨벤션**
(`session/2026-08-08-02-dispatch-singleton-naming.md`)
Dispatch는 프리미티브가 아니라 탑레벨 싱글톤으로 확정(재귀 호출 배관
비용 때문). children 배열의 Ref/Observer/PreRef leaf Handler는
`Dispatch/Leaf.luau`(quad-base)로 확정. Handler는 "독립 프리미티브 vs
파생 데이터" 분류의 세 번째 카테고리로 명문화. 네이밍 케이싱 컨벤션
(생성자/메소드=대문자, 탑레벨 유틸=소문자) 문서화.

**2026-08-08 세 번째 세션 — Tag 재설계, Dispatch 체인+`retractUnder`**
(`session/2026-08-08-03-tag-redesign-dispatch-chain.md`)
`Tag`를 해시 파트 boolean 키에서 array-part 값 객체(`Tag(...)`, `:Added`/
`:Removed`/`:Contains`/`:Apply`/`Merged`)로 재설계 — 상호배타 스타일
상태 표현이 쉬워짐. 이 재설계로 "retract가 실제로 필요한 첫 사례"가
드러나, Dispatch가 `(inst,k)`별 핸들러 체인을 직접 소유하고
`Dispatch.retractUnder`가 꼬리부터 정리하는 모델로 확정(다단 재귀
위임의 retract 전파 문제 해결).

**2026-08-08 네 번째 세션 — `Overridden` 이름 확정** (`session/2026-08-08-04-overridden-naming.md`)
`Override`→`Overridden`(불규칙 과거분사)으로 이름 확정 — `-ed`/분사 어미가
"즉시 커밋 뮤테이션이 아니라 계산되어 반환되는 새 값"을 신호한다는
`Tag`의 `Added`/`Removed` 관례와 통일.

**2026-08-08 다섯 번째 세션 — 용어 정리 라운드** (`session/2026-08-08-05-terminology-round.md`)
`Ref`/`PreRef`/`Peek`/`isState`/`None`/`NoneHandler`/"프로바이더"→`Handler`
전부 이름 확정. `DI`→`D`, `canExecute`→`isAlive`는 계속 미정으로 재확인.

**2026-08-09 세션 — `canBound`, Modifier 핸들러 값 UB→error**
(`session/2026-08-09-01-canbound-modifier-error.md`)
`Bound`→`canBound(handle)` 탑레벨 함수로 확정. `:Compute`의 `previous`
인자는 오버엔지니어링 의심 기각(현재 설계 유지), 스코핑을 결과 State
노드 자신에 귀속으로 명확화. Modifier 필드/`State<Modifier>`에 핸들러
계층 값(Ref/PreRef/Observer/Effect/Slot/Modifier)이 들어오면 UB 대신
즉시 error로 전환(Slot만 예외 — 정상 dispatch 참가자라 계속 허용).
Tween `initValue`/`useTween` 논의 신설(미확정).

**2026-08-09 두 번째 세션 — 코퍼스 stale 감사, 무효화 서사 archive 이전**
(`session/2026-08-09-02-corpus-audit-archive-move.md`)
`.claude/` 전체 stale 마커/모순 7개 파일 수정. 뒤집힌 설계가 정정 표시만
붙은 채 본문에 전체 서술로 남아있던 4곳을 `archive/*-rejected.md`로 이전
(quad2-try 리서치 전문, Observer cleanup 계약 기각, 키드 컬렉션 State
메소드 기각, quad-debug ReplicatedStorage 채널 기각).

**2026-08-09 세 번째 세션 — Slot CRUD 완전 확정, `Slot:List`**
(`session/2026-08-09-03-slot-crud-list.md`)
`Add`/`Remove`/`Extract`/`Clear` CRUD 확정(당시엔 element 레퍼런스 기준 —
이후 열한 번째 세션에서 인덱스 기준으로 재정정됨). 키 기반 동적 컬렉션
재조정이 `Slot:List(data, updateFn, keyFn?) -> Slot` 메소드로 통합·승격
(Fusion `ForPairs`/`ForKeys`/`ForValues` 3분할을 하나로). `Move`/`Swap`
CRUD 추가, Slot 요소 타입 제약(`nil`/핸들러 계층 값 금지) 확정.
`renderFn`→`updateFn` 개명, `Source` 생성 권한을 `:List`가 아니라
`userdata`로 이전.

**2026-08-09 여섯 번째 세션 — Length/Offset, `unbindLifetime`**
(`session/2026-08-09-06-length-offset-unbindlifetime.md`)
여러 Slot이 형제로 섞일 때 순서 보장을 "각 위치가 앞 형제 개수 누적합만
알면 됨" 모델로 완전히 풂 — `Dispatch.setLength`/`Dispatch.setOffsetSource`
신설, 각 원소 `LayoutOrder`는 기존 store-bind 재실행 모델에 얹힘(새
메커니즘 없음). `bindLifetime`의 조기 해제를 위한 `unbindLifetime` 신설.

**2026-08-09 일곱 번째 세션 — `Slot:List` 구독도 lazy `bindLifetime`**
(`session/2026-08-09-07-list-observer-lazy.md`)
`data:Observer(fn)` 구독이 `:List()` 호출 즉시 만들어져 `inst`를 몰라
`bindLifetime`이 안 걸려있던 gap 발견·수정 — Slot 컨테이너 마운트 시점에
lazy하게 구독하도록 변경, Destroy 후 재실행 gap 해소.

**2026-08-09 여덟 번째 세션 — `base/` 전체 중간검토(질문 모드)**
(`session/2026-08-09-08-midreview-defects.md`)
서브에이전트로 `base/` 전체를 그라운딩된 리스팅으로 뽑아 6배치로 나눠
사용자가 직접 확인 — 24개 질문 중 1/3에서 실제 설계 결함 발견·즉시 수정
(Ref 콜백 배열 소진을 `None`→`nil`로 되돌림, Slot CRUD를 인덱스 기준으로
재정정, `isRef`/`isPreRef` 포함관계 재정정 등). 상세는 파일 참고.

**2026-08-09 열두 번째 세션 — `.claude/luau-test/` 신설**
(`session/2026-08-09-12-luau-test-spikes.md`)
M0가 검증해야 할 스파이크 항목을 독립 실행 스크립트 15개로 미리 작성 —
사용자가 `luau`/`luau-analyze`/`luau-lsp`/Studio로 직접 돌려보기로 함.
(당시엔 결과 미확인 — **[2026-08-13 여섯 번째 세션에 첫 실측 완료]**,
현재 상태는 `luau-test/STATUS.md`가 소스.)

**2026-08-10 세션 — `Slot:Add`가 삽입 인덱스 반환**
(`session/2026-08-10-01-slot-add-return-index.md`)
`Slot:Add(element, index?): number`로 확정(계산된 위치를 공짜로 반환).
범위 밖 `index`는 clamp 대신 즉시 error.

**2026-08-10 세션 — 동적 자식 추가/제거는 `Slot`/`state<Frame>`만 정당**
(`session/2026-08-10-02-dynamic-children-ub.md`)
quad가 마운트한 부모 Instance에 `Slot`/store-bind 경로를 안 거치고 직접
`.Parent =` 대입하는 것은 `Length`/`offset` 계산을 조용히 깨뜨리는 UB —
기존 문서에 빠져있던 갭을 명문화만 함(새 방어 로직 없음).

**2026-08-10 두 번째 세션 — Tween 전면 재설계** (`session/2026-08-10-03-tween-redesign.md`)
독립 Dispatch 핸들러(우선순위 경쟁하는 특수 bind key) 모델을 폐기하고,
`Tween(opts) -> Tween<T>` 값-레벨 래퍼로 전환 — PropertyHandler가
`realv`를 다 풀어낸 뒤 `isTween(realv)`로 직접 분기. 이걸로
"일반 반응형 바인딩도 Tween 파일을 거쳐가는가"라는 오래된 구조적 모호함
(`pre-implementation-audit.md` 1-1)이 구조적으로 해소됨. 3-상태 릴레이션
슬롯으로 진입 애니메이션 버그 방지, `T'=T|Tween<T>` 타입 치환만으로 해결.

**2026-08-10 세 번째 세션 — `OnChange` 특수 키** (`session/2026-08-10-04-onchange-key.md`)
`GetPropertyChangedSignal` 바인딩용 `OnChange(name)` DI 키 신설 — `Attribute`와
달리 제네릭 타입 파라미터 없음(콜백 타입은 인라인 명시). 전부 quad-roblox.

**2026-08-11 세션 — `:Compute(fn, ...)` trailing-args sugar**
(`session/2026-08-11-01-compute-trailing-args.md`)
`:Compute`가 trailing args로 추가 의존성을 바로 구독하는 sugar 채택(이미
만들 노드에 엣지만 얹는 진짜 공짜 최적화). `Effect`/`Observer`는 의도적으로
제외 — 다중 의존성 병합은 실제 새 노드가 필요해 `:With`를 명시적으로
남겨야 함.

**2026-08-11 두 번째 세션 — trailing deps를 `fn`에 위치 인자로 노출**
(`session/2026-08-11-02-trailing-deps-positional.md`)
trailing args `a,b,c`를 `fn(self,a,b,c)`처럼 값 자체로도 노출하는 안 채택
— 커링 시 중복/드리프트 위험 해소. `previous`와의 타입 팩 순서 충돌 발견,
`.claude/luau-test/15` 실측 항목 신규.

**2026-08-11 세 번째 세션 — `previous`는 팩 앞** (`session/2026-08-11-03-previous-before-pack.md`)
직전 세션의 "`previous`는 팩 뒤" 순서가 Luau 문법 제약(제네릭 팩은 맨 끝만
가능)과 부딪힐 가능성이 높다는 걸 발견 — `fn(self, previous?, ...deps)`로
정정(구조적으로 유일하게 안전한 순서).

**2026-08-11 네 번째 세션 — `Slot:List`는 `LayoutOrder`를 자동 세팅 안 함**
(`session/2026-08-11-04-slot-list-layoutorder-index.md`)
"Handler가 마운트 시점에 `LayoutOrder`를 자동 바인딩해준다"는 원 서술이
매직이라는 지적으로 정정 — `Slot.Offset`/`index`(raw number)만 `updateFn`에
전달하고 실제 반영은 전부 `updateFn` 몫. `candidateIndex` 트릭으로
"버림/다시 그림/source만 갱신" 세 갈래를 단일 forward pass로 정리, 이중
write 제거.

**2026-08-11 다섯 번째 세션 — Slot 문서화 프레이밍** (`session/2026-08-11-05-slot-doc-framing.md`)
Slot을 "동적 렌더링을 가능하게 하는 도구"로 문서화하기로 확정(순수 톤 결정,
새 런타임 설계 없음).

**2026-08-11 여섯 번째 세션 — `Slot:Single`, Slot-in-Slot 중첩**
(`session/2026-08-11-06-slot-single-nesting.md`)
`Slot():Single(state, updateFn?)`을 `:List` 위의 sugar로 확정. Slot을 다른
Slot 안에 넣을 수 있는 Slot-in-Slot 중첩 확정 — `Dispatch.setLength`/
`setOffsetSource`를 Slot 자신을 owner 키로 재귀 호출하는 것만으로 풀림(새
프리미티브 불필요). `Dispatch.drive`의 `recompute` off-by-one 버그(offset이
자기 자신을 포함해 누적되던 것)를 실측 시뮬레이션 중 발견·수정.

**2026-08-11 일곱 번째 세션 — 반응형 raw 요소** (`session/2026-08-11-07-reactive-raw-elements.md`)
`Slot:Add`가 `State<T>`/`Source<T>`도 요소로 받도록 확장 — 내부적으로
`Slot():Single(element)`를 대신 삽입하는 순수 sugar(최초 검토한 별도
position-keyed 구독 안은 `None`/Length/Move-Swap 문제로 기각). nested
Slot을 반환하는 `:List` 아이템은 `.Length`만큼 다음 형제 `index`를
건너뛰도록 `reconcile`의 `pos` 커밋 공식도 같이 수정.

**2026-08-11 여덟 번째 세션 — CLAUDE.md 재구조화(3000줄+ → 세션 로그 분리)**
(`session/2026-08-11-08-claude-md-restructure.md`)
CLAUDE.md가 세션 로그 누적으로 3196줄까지 불어나 컨텍스트 성능 저하를
유발한다는 사용자 지적 — 세션별 전체 원문을 `.claude/session/`(38개
파일)으로 이전하고, CLAUDE.md엔 세션당 2~4줄 요약+링크만 남기는 구조로
재편. `base/`/`research/`/`question.md`가 이미 매 세션 반영을 성실히
해왔음을 `README.md`/`question.md` 대조로 확인(반영 누락 없음 — archive
이전 전 처리 불필요). 새 서사가 CLAUDE.md에 다시 쌓이지 않도록 "이 절을
갱신하는 방법" 절을 세션 히스토리 맨 위에 명문화.

**2026-08-11 아홉 번째 세션 — 그룹 `Attribute(...)` 프리미티브, 단일 키 `AttributeKey`로 리네임, 이름별 weak 캐시**
(`session/2026-08-11-09-attribute-group-primitive.md`)
여러 Store를 한 번에 attribute로 묶는 `Attribute(store1, store2, ...)`를
`Tag`와 동형인 array-part 값 객체로 신설(`Merged`로 헤테로지니어스 합성,
retract는 Tag처럼 확실히 청소). 이름 충돌 방지로 기존 단일 키
`Attribute<<T>>`를 `AttributeKey<<T>>`로 즉시 리네임(용어정리 대기열이
아니라 지금 바로 적용, 최종 이름만 대기열에 남김). **후속**: `AttributeKey(name)`이
이름별 weak 캐시로 동등성(`AttributeKey(a) == AttributeKey(a)`)을 보장하도록
확정되며, 최초안이던 "그룹 Handler 자기 완결형(Dispatch 재진입 없음)"을
뒤집고 메모이즈된 키로 기존 단일 키 경로에 재귀 위임하는 걸로 재개정
(중복 구현 제거) — `base/attribute-plan.md` 등 관련 문서 전체 반영 완료.

**2026-08-12 세션 — Tween 옵션 값 모양+override 정책 확정, `tween-plan.md` 마감**
(`session/2026-08-12-01-tween-shape-finalized.md`)
사용자가 5개 결정을 한 번에 제안해 전부 확정: 옵션 값은 `Info: TweenInfo?`
우선+편의 필드(`Time`/`Style`/...) 폴백(기본값이 로블록스 `TweenInfo.new()`
자체 기본값과 일치), 옵션 필드는 전부 plain만(State 불가, Blocker의
`:Get()`은 블록 중에도 항상 최신값이라는 기존 원칙 재확인), 릴레이션 슬롯
3번째 상태를 `{Tween, Value}`로 확장(Finish가 목표값을 알아야 함), override
정책을 `Tween.Cancel`(기본)/`Tween.Finish` 2값으로 압축(로블록스
`TweenBase` API 현실상 나머지 옵션들이 관찰상 Cancel과 동일했음), `initValue`는
에이전트 범위 제외하고 사용자가 직접 처리하기로 확정. `Animate` 시그니처와
자연완료 북키핑만 다음 세션으로 연기.

**2026-08-12 두 번째 세션 — `Animate` 콤비네이터 확정, `.claude/` and/or 삼항 관용구 감사**
(`session/2026-08-12-02-animate-confirmed-and-or-audit.md`)
"다음 세션"으로 미뤘던 `Animate`를 사용자가 곧바로 간단한 구체안으로
확정: `Tween` opts(`Value` 제외)를 `T|State<T>`로 받아 각 필드를 resolve한
뒤 `Tween{...}`을 반환하는 `function(self)...end` — `:Compute(fn)`의
`self`-lazy-핸들 계약과 정확히 일치해 `state:Compute(Animate{...})`로
바로 연결(구 `useTween` 2-인자 스케치 대체). 옵션이 State여도 값 변경이
재애니메이션을 트리거하지 않는 게 의도된 동작임을 확정. 별도로 사용자가
Luau `if-then-else` 표현식을 언급하며 `.claude/base` 전역 and/or 삼항
관용구를 감사 — `bind-system-plan.md`의 `Dispatch.retractUnder`에서 실제
falsy-값 버그(`v`가 `false`일 때 `nil`로 새는 문제) 발견·수정, 나머지
히트는 가운데 값이 테이블/숫자라 안전 확인. `research/tween-plan.md`는
이걸로 자연완료 북키핑 하나만 남기고 사실상 마감.

**2026-08-12 세 번째 세션 — `Animate`에 `CanAnimate` 필드 추가, Luau 문법 공식성 문서화**
(`session/2026-08-12-03-cananimate-luau-syntax-note.md`)
`Animate(info)`에 빠져있던 `CanAnimate: State<boolean>|boolean|nil` 필드
추가(`nil`=기본 `true`, `false`면 `Tween`로 안 감싸고 plain 값 그대로 —
reduceMotion류 우회가 이걸로 표현됨). `base/architecture.md`에 "코드
스타일 — Luau 문법 관례" 절 신설 — `if-then-else`(2021년 정식 도입)와
`const` 바인딩 둘 다 공식 Luau 문법임을 명문화(에이전트가 모르고
`and`/`or`로 되돌리는 회귀 방지), `const`는 툴링 미성숙으로 지금은 보류.

**2026-08-12 네 번째 세션 — `:Compute` 콜백 인자 `:Get()` 누락 버그 전역 감사**
(`session/2026-08-12-04-compute-self-get-audit.md`)
사용자가 `Animate`의 `CanAnimate` 예시(`not r`)가 `r:Get()`이어야
한다고 지적 — `:Compute`의 `fn(self, ...)` 인자가 raw 값이 아니라 lazy
State 핸들이라는 기존 확정 계약을 놓친 버그. 같은 클래스의 실수를
`.claude/` 전역에서 찾아 `base/slot-plan.md` 2곳(`LayoutOrder` 예시,
`Slot:Single`)과 `base/tag-plan.md` 1곳에서 추가로 발견·수정.
`bind-system-plan.md`에 "이 실수가 반복되기 쉬움" 주의 노트 추가.

**2026-08-12 다섯 번째 세션 — `Operator` 콤비네이터 슈가 신설, `Animate`
호출 경로를 `:Compute`→`:Apply`로 정정** (`session/2026-08-12-05-operator-sugar-plan.md`)
기본 연산(산술/논리/비트)을 콤비네이터로 쓰는 슈가 제안(`Not`/`Sum` 등,
새 프리미티브 아님). 처음엔 0항은 `:Compute`, N항은 `:Apply`로 나눴으나
후속 논의로 **재사용 가능한 이름 붙은 콤비네이터는 전부 `:Apply`가 맞다는
쪽으로 정정** — quad가 암묵적 자동 추적을 기각했기 때문에(`base/
bind-system-plan.md`) `local addTax = Sum(a,b)`처럼 만든 값을 `:Compute`에
바로 꽂으면 캡처된 deps가 구독 목록에 안 걸려 조용히 멈추는 진짜 버그가
됨 — 스타일이 아니라 정합성 문제. 같은 근거로 `research/tween-plan.md`의
`Animate` 호출 경로도 `:Compute(Animate{...})`→`:Apply(Animate{...})`로
정정(시그니처/동작 자체는 그대로), `base/bind-system-plan.md`의 `:Apply`
절에 이 관용구를 일반 원칙으로 추가. 네임스페이스 이름(`Operator`/`Op`/`Ops`
중 미정)만 열린 질문으로 남음. 우선순위는 여전히 사용자가 맨 마지막으로
직접 지정(순수 슈가, 함수 간 의존 없음) — 구현 착수 안 함. 사용자가
`:Apply` 통일에 동의, `Sum(a,b,Sum(c,d))` 중첩 flatten 최적화(약한
`Relate`로 클로저의 operand 목록 추적) 아이디어도 나왔으나 실사용
사례 나오면 재검토로 보류. `base/architecture.md`의 stale `Animate`
2-인자 시그니처 코멘트도 이 김에 수정.

**2026-08-12 여섯 번째 세션 — Tween 자연완료 북키핑 확정, `tween-plan.md`
`base/`로 승격** (`session/2026-08-12-06-tween-completed-bookkeeping-promoted.md`)
`tween-plan.md`의 마지막 열린 질문(자연완료 시 per-instance 북키핑 정리
여부)을 사용자가 확정 — 정리 안 해도 됨(자연완료는 유저가 원한 목표값에
도달한 상태라 남은 참조가 부작용 없음, `Value`가 항상 lerp 가능한
프리미티브라 메모리 문제도 없음, 별도 Completed 이벤트 정리 장치는
오버엔지니어링). 이걸로 열린 설계 질문이 없어져 `research/tween-plan.md`를
`base/tween-plan.md`로 승격, 라이브 크로스레퍼런스 전부 갱신(session/
과거 기록은 원문 보존을 위해 그대로 둠).

**2026-08-12 일곱 번째 세션 — `PreRef`는 취소 개념 없음, 재사용은 error**
(`session/2026-08-12-07-preref-single-use-no-cancel.md`)
`documentation-content-map.md`에 미정으로 남아있던 "`PreRef` 취소 가능성"
해소: `PreRef`는 pre-pass에서 fire와 동시에 소진돼 정상 `retract` 체인에
아예 안 올라가므로 취소 개념 자체가 없음(사용자 직관과 기존 구조가
정확히 일치). 진짜 위험은 취소가 아니라 재사용(stale `.Value`로 콜백이
조용히 잘못 호출됨)이라고 판단해, 이미 fire된 `PreRef`를 다시 놓으면
pre-pass가 즉시 `error`하는 가드 확정(`_fired` 플래그, 거의 공짜 구현) —
1회용, use only once. `Slot:List`의 `updateFn`처럼 반복 호출되는 자리에선
매번 새 `PreRef()`를 만들라는 관용구도 같이 명문화.

**2026-08-12 여덟 번째 세션 — `Ref`의 retract, `TagHandler`와 같은 패턴으로
확정** (`session/2026-08-12-08-ref-retract-tagged-pattern.md`)
`State<Ref>`가 `refA→refB`로 바뀌는 경우 이전 Ref가 stale하게 남는 문제를
사용자가 지적 — 처음엔 "retract가 `Set(nil)`"로 단순 답했으나,
`Dispatch`의 일반 계약("핸들러 타입이 안 바뀌면 retract 없이 process가
diff")과 대조해 `TagHandler` 선례와 정확히 같은 메커니즘이어야 함을
발견·정정: `refA→refB`는 `process`가 `Relate`로 기억해둔 이전 값과 diff해
언바인딩(`old:Set(nil)`), `retract`는 그 자리가 아예 Ref이길 그만둘 때만.
사용자가 추가로 확정: 비-nilable `Ref<T>`도 "확정값을 부작용 없이 읽는"
정당한 용도라 계속 지원하되, Store/Modifier 자리에 놓을 땐 호출자가 직접
`Ref<<T?>>(...)`로 명시(기존 관용구 재사용, 새 규칙 아님). Ref의
언바인딩은 Instance `Destroy()`와 완전히 무관 — Destroy된 대상을 계속
들고 있는 채로 남는 건 UB로 허용, 정리가 필요하면 `Effect`를 쓰도록
문서가 유도.

**2026-08-12 아홉 번째 세션 — `Slot`의 store 재바인드도 `Ref`와 같은
`Relate` diff 패턴** (`session/2026-08-12-09-slot-retract-same-pattern.md`)
직전 세션의 `Ref` 패턴이 `Slot`에도 적용되는지 사용자가 확인 요청 —
`slot-plan.md`의 "store 바인드 핸들러가 retract하고 다시 process" 서술이
`Ref`에서 고쳤던 것과 같은 부정확한 서술이었음을 발견(실제 `Dispatch/
Slot.luau`의 `process`엔 이전 값 비교 자체가 없었고 `destroySlotTree`도
store-bind retract 경로에 연결된 적 없는 진짜 갭). `Ref`와 같은 `Relate`
기반 패턴으로 정정하되, Slot은 이미 확정된 "폐기, 옮기지 않음"(portal
없음) 정책 때문에 세밀한 diff 대신 **identity 비교**로 단순화 — 같은
바인딩이면 완전 무시, 다르면 이전 것 통째로 폐기 후 새로 마운트. 이
no-op 가드는 Tag/Ref보다 Slot에서 훨씬 중요함(가드 없으면 재귀 재emit마다
마운트된 서브트리 전체가 파괴됐다 재생성돼 자식의 스크롤/포커스/애니메이션
상태가 전부 유실됨).

**2026-08-12 열 번째 세션 — Attribute 이름 소유권, `rawNew` 전용 키로
그룹/직접 쓰기 충돌 방지** (`session/2026-08-12-10-attribute-name-ownership.md`)
`Ref`/`Slot`에 이어 `Attribute`도 확인 — 그룹 `Attribute(...)`의 위임
메커니즘이 공개 `AttributeKey(name)` 캐시(이름별 weak 캐시로 항상 같은
객체)를 그대로 쓰다 보니, 직접 리터럴 `[AttributeKey "name"]=v`와 배열파트
`Attribute(store)`(또는 서로 다른 두 그룹)가 같은 이름을 동시에 관리하면
같은 `(inst,k)` 자리로 수렴해 조용히 마지막 쓰기가 이기는 충돌이 실제로
가능함을 확인. Claude가 처음 제안한 별도 `Relate` claimant 레지스트리 대신,
사용자가 더 단순한 안을 제시해 채택: 그룹이 캐시를 우회하는 `rawNew(name)`로
이름마다 자기 전용 키 객체를 만들어 자기 릴레이션에 캐싱하면(그룹 값 교체를
넘어 유지), "이 이름에 지금 어느 키 객체가 적용돼 있는가" 조회만으로
`AttributeKeyHandler`에서 바로 소유권 판정(다르면 error) 가능 — 별도
claimant 타입 없이 AttributeKey 객체 identity 자체를 재사용하는 더 적은
부품의 설계. 기존 diff 로직(사라진 이름만 nil, 남은/새 이름은 갱신)은
그대로 맞물림, 캐시가 그룹 값 교체를 넘어 영속돼야 한다는 조건만 명시.

**2026-08-12 열한 번째 세션 — "retract는 항상 불림" 전면 정정, `Tag`
참조 카운트 재설계** (`session/2026-08-12-11-retract-always-fires-correction.md`)
`Tag`도 Attribute와 같은 참조 카운트 문제(서로 다른 위치의 `Tag(...)`가
같은 이름을 겹쳐 가질 수 있음, 웹 `className` 합집합)가 있다는 사용자
지적에서 출발 — 논의 중 사용자가 "retract가 v=Tag(nil 아님)를 받는
경우"를 전제로 설계를 제안했고, 이게 기존 `assert(v==nil)`과 모순됨을
Claude가 지적했으나, 사용자가 "덮여 쓰여지는 즉시 retract 실행, 전체
트랙을 retract하고 리빌드하는 맥락"이라고 재확인. `bind-system-plan.md`
자기 "확정된 디스패치 모델" 절(2026-08-04 원문)을 재대조하니 `StoreBind`가
재-dispatch 전에 무조건 `retractUnder`를 부른다고 이미 명시돼 있었음 —
"핸들러 타입이 안 바뀌면 retract 생략"이라는 2026-08-07 정정 서술이
자기 문서와 처음부터 모순돼 있었고, `Tag`의 `assert(v==nil)`을 액면
그대로 믿고 거꾸로 일반 규칙을 잘못 추론한 게 오류의 출처였음이 드러남.
**이 오류가 이번 대화에서 만든 `Ref`/`Slot`/`Attribute` 설계 전부에도
그대로 이어받아져 있었음** — 전부 한 세션에 정정: `retract`는 store
재발행마다 항상 불리고 `v`는 대체 값 자체일 수 있음(`nil` 가정 금지),
"이전 기여 제거는 `retract`, 새 기여 등록은 `process`"로 분업하면
`process`의 별도 diff가 필요 없어짐. `Tag`는 `kTagMap`(위치→Tag)+
`tagNameMap`(이름→Tag set) 참조 카운트로 재설계(`AddTag`는 온전히
`process`, `RemoveTag`는 온전히 `retract`, `Contains` 힌트로 flicker
방지). `Attribute`의 그룹 위임도 "남아있는 이름"에서 `retractUnder`를
생략하면 체인이 계속 쌓이는 누수를 추가로 발견·정정. 역전 사례는
`archive/retract-always-fires-reversed.md`에 원문·근거·영향 범위 보존.

**2026-08-12 열두 번째 세션 — `Slot`의 `slot→inst` 소유권 relate,
`retractUnder` 4-인자 이유** (`session/2026-08-12-12-slot-owner-relate-retractunder-args.md`)
직전 세션에서 고친 `Slot`의 의사코드를 사용자가 검토 — 위치별 relate로
"같은 값인가"를 비교하는 대신, Slot이 이미 갖고 있는 "한 element가
어디에도 중복 마운트 안 됨" 전역 불변식을 Slot 컨테이너 자신에도
그대로 적용해 `Relate<slot→inst>`로 소유권을 직접 추적하는 게 더
정확하다고 지적(위치 비교로는 같은 Slot이 동시에 다른 위치에도
마운트된 경우를 못 잡음) — `owner==inst`면 단순 emit 전파로 무시,
다른 inst면 즉시 error, 없으면 정상 바인딩으로 재작성. 별도로
`Dispatch.retractUnder(inst,k,keep,v)`가 왜 4-인자인지 질문받아 답변:
`keep`(체인 어디까지 지울지, 구조적)과 `v`(새로 들어올 값 힌트,
Tag/Ref/Slot/Attribute가 이번 대화 내내 의존해온 그 메커니즘)는 서로
다른 용도라 하나로 안 합쳐짐 — old value를 각 핸들러가 자기 `Relate`로
저장한다는 원래 결정과는 무관, `retractUnder`는 old를 옮긴 적이 없음.

**2026-08-12 열세 번째 세션 — `Slot`의 두-`Relate` 상호 GC 순환 수정**
(`session/2026-08-12-13-slot-gc-cycle-fix.md`)
사용자가 직전 세션의 `slotOwner`(slot→inst)/`kSlotMap`(inst→slot)이 둘 다
`SetStrong`이면 서로가 서로를 살려주는 순환이 생겨 GC가 안 된다고 지적 —
`bindLifetime`이 이미 쓰는 "값이 자기 키를 다시 참조"하는 단일 테이블
자기참조(`Dispatch.setLength`의 `observer` 클로저가 `inst` 캡처,
`Ref.Value=inst`)는 그 키가 테이블 바깥에서 독립 reachable한지만
판별하면 돼서 안전하지만, **서로 다른 두 `Relate`가 서로의 키를 상대방
값으로 제공하는 상호 순환**은 판별 자체가 서로에게 의존해버려 Lua
5.2+ ephemeron이 풀려던 바로 그 사례라는 걸 Claude가 재확인. `grep`으로
base/ 전체 `Relate()` 인스턴스를 감사한 결과 `inst`가 아닌 다른 값을
바깥 키로 쓰는 건 `slotOwner`가 유일했음(나머지는 담긴 값이 `inst`로
되돌아가는 back-reference가 없거나, 있어도 단일 테이블이라 안전).
`kSlotMap`/`slotOwner` 둘 다 `SetWeak`로 낮추고, 실제 GC 앵커는
`bindLifetime`/`unbindLifetime` 하나로 통일 — `attachSlot`에
`bindLifetime(physicalTarget, slot)`, `destroySlotTree`에 짝인
`unbindLifetime(slot._mountedInst, slot)` 추가(기존엔 자식 observer들의
unbindLifetime만 있고 slot 자신의 앵커/해제가 빠져 있었음).

**2026-08-12 열네 번째 세션 — Luau에 ephemeron 없음, 공식 확인·문서화**
(`session/2026-08-12-14-luau-no-ephemeron-confirmed.md`)
사용자가 직전 세션의 "Luau가 두-`Relate` 상호 순환을 올바르게 처리하는지
검증된 바 없음"이라는 방어적 서술에 공식 출처를 제시 — Luau는 복잡성
때문에 Lua 5.2의 ephemeron 테이블을 도입하지 않음
(https://luau.org/compatibility/ "Lua 5.2" 섹션 "Ephemeron tables" 항목).
`base/slot-plan.md`의 해당 문단을 "추측성 방어"에서 "공식 확인된 필수
조치"로 정정, `base/relate-plan.md`에 "위험한 패턴 — 서로 다른 두
`Relate`의 상호 강참조 순환" 절을 신설해 단일 `Relate` 자기참조(안전)와
두-`Relate` 상호 순환(위험, 실제로 GC 안 됨)을 명확히 구분하고 일반
규칙으로 명문화 — 앞으로 비슷한 설계에서 Slot 사례를 매번 재발굴하지
않도록. 열한~열네 번째 세션에 걸친 "retract는 항상 불림" 정정과 그
파생 GC 이슈 시리즈가 이걸로 마무리됨.

**2026-08-12 열다섯 번째 세션 — Slot-in-Slot relate 범위 확인, `Tag:Added`
vararg, `Slot:Splice` 신설** (`session/2026-08-12-15-slot-in-slot-relate-scope-tag-splice-additions.md`)
사용자가 최근 확정 설계 4개를 재확인 질문 — 3개(Slot-in-Slot의
`slotOwner`/`kSlotMap` relate가 최상위 마운트에만 걸림, `Animate` 반환
타입이 `State<Tween<T>|T>`, Slot retract는 전부 파괴·포탈 없음)는 문서와
일치해 확인만. 1개(`Tag:Added`/`:Removed`가 문서상 단일 `name`만 받던 것)는
불일치 발견해 정정 — 처음엔 vararg로 갔다가, `table.unpack(t)`가 인자
목록 tail 위치일 때만 완전히 펼쳐진다는 Lua 문법 한계(조건절로 조립한
여러 동적 테이블은 한 vararg 호출로 못 합침) 때문에 같은 세션 안에
`string | {string}`(내부 flatten)로 재수렴(self-return 최적화는 매번
멤버십을 먼저 읽어야 해서 기각, `tag-plan.md`). 추가로 `Slot:Splice(index,
removeCount, ...newElements)` CRUD 신설 — 구간 제거+삽입을 shift/recompute
1회로 묶는 순수 최적화. `newElements`는 `Tag:Added`와 달리 의도적으로
vararg 유지(요소 개수가 대개 소수로 고정, 동적이면 Slot-in-Slot으로 흡수
가능, `T|{T}`는 `Slot<T>`가 base 레벨에선 `T`가 뭔지 모르는 제네릭이라
바깥 `{}`가 단일 T인지 배열인지 원천적으로 판별 불가능해서 오히려
모호해짐 — `Slot`의 T에 우연히 Slot이 섞여서가 아님, `slot-plan.md`).

**2026-08-12 열여섯 번째 세션 — 코퍼스 전체 감사, Attribute retract 전면
재설계, Slot 소유권 일반화** (`session/2026-08-12-16-corpus-audit-attribute-retract-slot-owner.md`)
7개 에이전트로 `.claude/` 코퍼스 전체를 감사해 stale 서술 다수 정정
(retract-always-fires 정정 전파 누락, Tween research→base 승격 반영
누락, `Relate` API 인자 개수 버그, `pre-implementation-audit.md` 열린
항목 개수 오류 등). 이어서 사용자가 diff를 직접 검토하며 Attribute
`retract`를 다단계로 재설계 — **최종: retract는 완전 no-op(SetAttribute는
오직 `process(inst,k,nil)`), Attribute는 오직 명시적 `None`/`nil`로만
지워짐(그룹이 사라진 이름을 자동으로 안 지워줌 — Ref의 "Destroy 무관"
철학과 통일), 단 사라진 이름의 *구독*은 끊음(값은 안 지워도 리소스는
안 새게)**. 일반 규칙 2개 신설(retract의 `v` 타입 미보장 → `isX(v)`
가드 필수, retract 안에서 `process` 호출은 UB). Slot도 `slotOwner`를
`elementOwner`로 일반화해 top-level/nested 이중 마운트 gap 폐쇄,
`bindLifetime`을 top-level 전용으로 축소(nested는 `_elements` 강참조로
transitively 생존). `and`/`or` 삼항 관용구 전면 금지(기존 "항상-truthy면
예외" 조항 폐기), 코퍼스 전체 실제 코드 6곳을 `if-then-else`로 교체.
Attribute 자동 unset이 필요해지면 쓸 `:Apply` opt-in 유틸을
`research/operator-sugar-plan.md`에 백로그로 추가(착수 안 함).

**2026-08-12 열일곱 번째 세션 — 우선순위1 마지막 넷 전부 해소**
(`session/2026-08-12-17-priority1-audit-resolved.md`)
`pre-implementation-audit.md` 우선순위1 중 열려있던 마지막 넷을 사용자가
한 번에 확정: 우선순위 동률/매치실패(1-3, tiebreak 강제 대신
`HANDLER_PRIORITY_*` 상수+디버그 모드 동률 감지/핸들러 목록 함수, 매치실패는
즉시 error), provider 미주입 dispatch(1-4, 매치실패 규칙에 자연 흡수),
`store.key` 레코드 필드 타이핑(1-10, Luau `type function`으로 `Store<T>`→
`{[K]: Source<V>}` 합성 가능함을 구체 스케치로 확인), Modifier
`__index`+`table.clone` 트릭(1-11, 메타테이블이 복사 아닌 참조 공유임을
확인). 부수적으로 Property에 Attribute식 소유권 레지스트리를 적용하는 안을
검토 후 기각(엔진이 정한 유한 프로퍼티 이름 집합은 호출자가 전용 키를 못
만들어 소유권 판정 불가 — Property가 override 우선순위를 쓰는 이유).
**우선순위1 11개 전원 해소** — M0 착수 전 남은 건 `.claude/luau-test/`
스파이크 실측뿐. **핸드오버 점검 중 발견**: 1-10/1-11은 설계는 확정됐지만
이를 실제로 실측할 스파이크 파일 자체가 없었던 갭 — `16-type-store-key-
typefunction.luau`/`17-modifier-index-tableclone-chaining.luau` 신규
추가(총 17개), `ROADMAP.md` M2/M3/M7 체크리스트에도 누락됐던 항목(디버그
모드 동률 감지+`listHandlers`, `store.key`/`table.clone` 실측 링크) 보강.

**2026-08-12 열여덟 번째 세션 — `framework-comparison-findings.md` 남은
두 항목 "고칠 필요 없음"으로 최종 판단**
(`session/2026-08-12-18-framework-comparison-fixables-closed.md`)
"고칠 만한 것"으로 분류돼 있던 use-after-destroy 검증 안전망 부재,
`:With`의 동적 의존성 미지원 두 항목을 사용자가 확정 판단 — 둘 다 "의도된
트레이드오프"로 문서 3번 절로 이전. use-after-destroy 검증은 `bindLifetime`/
`Effect`로 이미 커버되는 영역에 별도 장치를 얹으면 GC-native 아키텍처와
모순(항상 명시적 Destroy를 강제하게 됨) — 완전한 UB로 남기고 문서화로만
대응. 동적 With는 State immutable 가정과 정면 모순, 실사용 사례도 거의
없음(React `useMemo` deps도 대부분 정적) — 의도적 비지원으로 확정.
`question.md`도 동기화.

**2026-08-12 열아홉 번째 세션 — `Operator` 콤비네이터 슈가 외부 리서치**
(`session/2026-08-12-19-operator-sugar-external-research.md`)
서브 에이전트로 `research/operator-sugar-plan.md`의 `Operator.*` 카탈로그를
다른 리액티브 라이브러리 실제 선례와 대조. 논리(`Not`/`And`/`Or`)/`Sum`/
`Clamp`/`Min`/`Max`는 선례 뚜렷(VueUse `@vueuse/math` 등), 비트연산·비교
연산자·`Sub`/`Div`는 리액티브 콤비네이터로서 선례 전무(드랍 후보). 업계
표준 카테고리인 Debounce/Throttle 부재를 발견했으나 `Blocker`(타이머 없는
값 기반 게이트)와는 다른 메커니즘이라 quad-roblox 쪽 별도 프리미티브
가능성으로 분리. `Filtered`를 Slot 밖에선 plain transform, Slot 안에선
별도 프리미티브로 나눈 기존 판단이 ReactiveUI/SolidJS 선례로 뒷받침됨.
네임스페이스는 Python `operator` 모듈이 `Operator`의 가장 강한 선례 —
최종 확정은 여전히 사용자 몫, `question.md` 3번 동기화.

**2026-08-12 스무 번째 세션 — `State` 이름 최종 확정, use-after-destroy
안전망 근본 재검토 후 최종 기각**
(`session/2026-08-12-20-state-name-final-usedaftedestroy-scoped-out.md`)
용어 정리 1순위였던 `State`를 현재 이름 그대로 유지로 확정
(`Computed`/`Derived` 검토 종료). use-after-destroy는 열여덟 번째
세션에서 이미 "고칠 필요 없음"으로 정리했으나 사용자가 근본부터 재검토
요청 — 일반적 검증은 Instance 가상화/추적이 필요해 rbvm 같은 전문
라이브러리의 영역(quad가 재발명하면 오버엔지니어링), quad-debug는
quad 자신이 만든 효과만 설명하는 스코프라 외부 조작은 원래 관심사
아님(`research/debug-tooling-plan.md`가 이미 명시), 실제 위험 지점은
`Ref`가 관례를 벗어나 반출되는 경우뿐(React `useRef`급 스코프 관례를
`base/bind-system-plan.md`에 이번에 명문화) — 전부 동의로 최종 기각,
근거를 `research/framework-comparison-findings.md`에 보강.

**2026-08-12 스물한 번째 세션 — 네이밍 정리 후속: `Pipe` 기각, `Compute`
vs `Computed`, `:With`/`Tag`·`Modifier` clone 대조 명문화**
(`session/2026-08-12-21-naming-clarity-pipe-compute-with-clone-contrast.md`)
`:With`가 `Tag`/`Modifier`의 clone 체이닝과 겉보기엔 같은 `:` 문법이라
혼동될 여지를 `bind-system-plan.md`에 경고 문단으로 명문화. `State` 대안으로
검토됐던 `Pipe`는 "캐시한다"는 동작이 파이프 비유와 안 맞고 노드 단위로
보기도 애매해 기각. `Compute`(현재 이름) vs `Computed`(만약이었다면) 논의—
Vue/Svelte는 lazy인데도 `computed`를 쓰지만, quad 자기 코퍼스 안에서는
`Tag.Added`/`Modifier.Overridden`이 이미 "-ed = clone 후 즉시 확정된 값"
관례를 선점해뒀어서 lazy한 State에 재사용하면 자기 관례와 충돌 — `Compute`가
더 정확하다는 데 동의, `bind-system-plan.md`에 근거 추가.

**2026-08-13 첫 번째 세션 — gcconn 트릭 부분 실측, `Relate` 상호 순환
스파이크 신규, README 동기화**
(`session/2026-08-13-01-gcconn-audit-relate-cycle-spike-readme-sync.md`)
사용자가 Studio에서 gcconn 트릭의 핵심 가정(ClassName 신호 미발화, Destroy
시 `Connected` 즉시 전환) 둘을 자작 스크립트로 실측 — 결과를
`.claude/audit/gcconn-trick-verification.md`에 정리(부분 확인, `luau-test/10`의
A-1/A-2/B/C는 미해소로 명확히 구분). GC 강제 트리거 기법을
`gc-trigger-helper.server.luau`로 문서화하면서 `07`의 "Studio에서 GC 검증
불가" stale 서술도 정정. 코퍼스를 다시 훑다가 `relate-plan.md`의 "두
`Relate` 상호 순환은 ephemeron 없이 GC 안 됨" 주장이 공식 문서 인용으로만
뒷받침돼 실측된 적 없었던 갭을 발견해 `18` 신규 작성, CLAUDE.md 자신의
"지금 할 일"이 이미 해소된 `State` 용어 논쟁을 stale하게 open으로 남겨뒀던
것도 발견·수정. 서브에이전트에 위임한 코퍼스 스윕으로 세션 8~21(마지막
전체 감사인 세션 16 이후) 변경사항이 `.claude/README.md` 요약 테이블에
안 반영돼 있던 8개 행 동기화(base/research 문서 본문 자체는 이미 최신,
색인 레이어만 밀렸던 것) + `attribute-plan.md` 행의 실제 오류(폐기된
중간 단계 서술) 수정 + 새 소유권/참조카운트 알고리즘(Tag/Attribute/Slot)과
`Slot:Splice` 산술을 커버하는 `19`/`20` 스파이크 추가(총 20개).

**2026-08-13 두 번째 세션 — Haskell Monad/Applicative 비교, `State<State<T>>`
재진입 디스패치 버그 발견·수정**
(`session/2026-08-13-02-haskell-comparison-dispatch-reentrant-bug.md`)
"커링/레이지 이벨루에이션 말고 Haskell에서 가져올 것"을 조사 — Functor/
Applicative/Semigroup은 `:Compute`/`:With`+trailing-args/`Merged`·`Overridden`로
이미 사실상 가져와 있음 확인, Monad bind/join은 `StoreBind`/`Slot:Single`/
`NoneHandler`가 각자 따로 재구현 중인 미일반화 후보로 식별(착수 안 함),
Traversable/sequence는 진짜 빈 자리로 식별(백로그), do-notation류는 Luau에
HKT가 없어 스킵 권장. 후속으로 사용자가 `Alternative`(nil 대체값)를
`Operator` 카탈로그에 넣자고 제안하며 `retractUnder`의 꼬리부터-cutoff
로직을 직접 되짚어 "같은 키에서 핸들러가 재사용되면 문제 아닌가" 제기 —
손 트레이싱으로 `State<State<T>>`(store가 emit하는 값 자체가 또
State/Source)가 같은 `(inst,k)`에 같은 핸들러를 중복 push시켜
`retractUnder`의 첫-매치 cutoff가 안쪽 자신을 잘못 retract하는 실제 체인
파손 버그(구독이 등록 직후 스스로 끊김)로 확인됨 — 코퍼스 어디에도 UB로
명시된 적 없었고 막는 가드도 전혀 없었던 진짜 갭. `Dispatch.process`에
중복 핸들러 즉시 error 가드 추가, 낙관적으로 틀렸던 "다른 store여도
상관없이 처리 가능" 서술 정정. 부수적으로 `luau-test/04`가 이미 이
시나리오를 스트레스 테스트로 갖고 있었지만 `retract`가 no-op 스텁이라
이 버그를 절대 못 잡는 사각지대였음을 발견해 3~4단계를 "가드가 실제로
걸리는지" 검증으로 재작성. `operator-sugar-plan.md`에 `Alternative` 후보
신설, `.claude/README.md`/`question.md` 동기화.

**2026-08-13 세 번째 세션 — v1 `objectListClass.__newIndex` 오타 기능,
v2 논의 대상 아님으로 확정** (`session/2026-08-13-03-v1-newindex-typo-scoped-out.md`)
`question.md`의 v1 `__newIndex` 오타(항상 미발동) 재현 테스트 필요 항목을
사용자가 정리 — 당시 실수였던 건 맞지만, v2는 오브젝트 id 주입/조회
(`GetObjects()`류) 개념 자체가 없어져 재현 여부와 무관하게 v2 마이그레이션
가이드에서 다룰 대상이 아님(있었다 해도 v1 전용 기능). `question.md`/
`reference/quad-v1-architecture.md` 둘 다 해소로 반영.

**2026-08-13 네 번째 세션 — 사각지대 손 트레이싱 라운드, `Dispatch.processAs`/
`retractSelfAndUnder` 체크포인트 핸들러 신설**
(`session/2026-08-13-04-blind-spot-audit-checkpoint-handlers.md`)
직전 세션의 `State<State<T>>` 발견 방식(합성 시나리오를 pseudocode에 손
대입)을 서브에이전트 4개로 코퍼스 전체에 반복 — 실제 버그 3건 발견:
Tag 참조 카운트가 객체 identity 기준이라 같은 Tag 객체 재사용 시 깨짐,
Attribute 그룹이 이름을 놓았다 다시 포함하면 자기 자신과 소유권 충돌,
(Slot의 이중 State 언랩은 사용자 확인 결과 버그가 아니라 기존
`State<State<T>>` UB 범위였음, 과다 보고 정정). 사용자가 Attribute
설계를 직접 재검토하며 `owners`/`rawNew` 수동 레지스트리를 통째로
버리고, `isHandlable` 없는(스캔 불가) 순수 체크포인트 핸들러를
`Dispatch.processAs`로 명시 push + `Dispatch.retractSelfAndUnder`(target
자신 포함 철거, 신설)로 통째 정리하는 설계로 전환 — 소유권 충돌 감지가
기존 재진입 가드로 공짜로 해결됨. Slot의 `releaseOwner` 불일치 무시를
error로 강화, `bindLifetime` 위치를 Handler 층위로 이동해 `unbindLifetime`과
대칭 맞춤. `Brand`/`isXX`의 nil 처리는 서브에이전트 확인 결과 안전.
`base/bind-system-plan.md`/`tag-plan.md`/`attribute-plan.md`/`slot-plan.md`
전부 반영 완료. **[정정, 같은 날 다섯 번째 세션]** 이 세션에서 신설한
`Dispatch.processAs`/`retractSelfAndUnder` 체크포인트 패턴은 바로 다음
세션에 더 근본적인 인덱스 기반 재설계로 대체되며 전부 걷어내짐 — 아래
다섯 번째 세션 항목 참고, 원문은 `archive/checkpoint-handler-pattern-reversed.md`.

**2026-08-13 다섯 번째 세션 — `Dispatch` 인덱스 기반 전면 재설계,
`State<State<T>>` UB 해제** (`session/2026-08-13-05-dispatch-index-based-redesign.md`)
사용자가 체크포인트 패턴에 "왜 최상단에서 뭔가 지우는 일을 만들었냐,
가정이 늘어나는 건 안 좋다"고 문제 제기하며 시작 — `chains`가 핸들러
**객체 identity**로 위치를 추적하는 것 자체가 `State<State<T>>`를 UB로
만든 근본 원인이라는 데까지 논의가 이어짐. 최종 설계: `chains`를
**재귀 깊이 인덱스**로 추적(같은 키 재귀는 `index+1`, 다른 키 위임은
항상 `1`부터, 0이 아니라 1인 이유는 Luau `ipairs`/`#` 관례), `Handler`
계약이 `process`/`retract` 2-메소드에서 `process`가 자기 retract
클로저(`(hintValue)->()`)를 반환하는 1-메소드로 축소, `Dispatch.process`가
핸들러를 부르기 전에 그 인덱스 점유 여부를 먼저 체크(핸들러 부작용 낭비
없음, 도메인 특화 에러 메시지가 없는 건 의도된 트레이드오프 — 에러=패닉
상태라 상세 설명 비용을 들일 이유가 없다는 데 사용자 동의),
`retractUnder`/`retractSelfAndUnder`도 `Dispatch.retractFrom(inst,k,index,v)`
하나로 통합(자기 포함/미만 여부는 호출자가 넘기는 인덱스 자체로 표현).
이 재설계로 `State<State<T>>`가 UB에서 정상 지원 대상으로 재정정되고,
전날 만든 체크포인트 패턴 전체(`AttributeGroupKeyHandler`/`processAs`/
`retractSelfAndUnder`)가 통째로 불필요해짐 — Attribute 그룹은 이제
공개 `AttributeKey(name)`으로 항상 인덱스 1에 직접 위임, 점유 체크가
소유권 충돌 감지를 대신함. 부수 효과로 여러 핸들러(StoreBind/Ref/Tag/
Slot/Attribute)의 private `Relate` 상태 저장소가 대거 줄어듦(process가
반환하는 클로저가 upvalue로 직접 캡처하므로 process→retract 사이 단발성
handoff용 저장이 불필요해짐 — `Relate`는 여러 위치/사이클을 가로지르는
누적 상태에만 남음). `bind-system-plan.md`/`tag-plan.md`/
`attribute-plan.md`/`slot-plan.md`/`architecture.md`/store-semantics.md(현 `store-plan.md`/`source-state-plan.md`)/
`modifier-plan.md` 전부 반영, `archive/checkpoint-handler-pattern-reversed.md`
신설.

**2026-08-13 여섯 번째 세션 — c33ae04 감사(버그 4건), Slot 언마운트 전환,
재디스패치 재설계안, 첫 실측 라운드**
(`session/2026-08-13-06-commit-audit-dispatch-redesign-bugs.md`,
실측 결과는 `audit/luau-test-first-run-2026-08-13.md`)
직전 커밋을 직접 정독해 인덱스 재설계 의사코드의 실제 버그 4건 발견·수정
(`chains:SetStrong` 순서로 하위 retractor 유실, Attribute 그룹의 점유 체크
무력화, `SlotHandler`의 claim 실패 시 이중 파괴, `Ref` dedup 무력화).
이어 사용자 결정으로 **`State<Slot>` 교체를 파괴→언마운트로 전환**(포탈이
그 귀결이 됨), **`dispose(value)`**(트리가 요구하면 파괴 거부·error) 신설,
**재디스패치를 "하강 diff"로 재설계**(당시 `research/`의 설계안 —
**base 미반영, `question.md` 0-Z 하나 남음**이었고 14차 세션에 확정·반영 후
`archive/dispatch-hintvalue-model-reversed.md`로 이전). `ROADMAP.md`/base 계약 개수
모순/`luau-test` stale도 정리. 마지막으로 `luau` 바이너리가 생겨 **첫 실측**
— 런타임 12개 전원 통과, `04`가 위 버그를 음성 대조군으로 재현, `07` 보강으로
GC-native 전제 확정, `18`이 `Relate` 순환 경고 실증. 타입에선 `:Compute(fn)`
lazy 핸들 계약이 Luau 추론과 충돌하는 게 드러나 `question.md` **0-Y** 신설.
스파이크 상태는 이제 **`luau-test/STATUS.md`가 소스**(pass/사람 결정 필요/
스파이크 깨짐/미실행 분류). 마지막으로 코퍼스 전반 모순·stale 감사 —
`ROADMAP.md`가 최우선 게이트(0-Z)를 전혀 안 짚고 M11 Tween을 이미 끝난
결정인데 미결로 두던 것, `slot-plan.md` 앞부분이 뒤집힌 "폐기, portal 안 함"을
여전히 "확정"으로 자칭하던 것(구현자가 앞에서부터 읽으면 구 모델로 짤 위험),
`reconcile`이 여전히 파괴 경로였던 것(→ `rawUnmount` 신설) 등을 정정.

**2026-08-13 일곱 번째 세션 — 코퍼스 전반 6라운드 감사, 수렴까지 반복**
(`session/2026-08-13-07-corpus-audit-six-rounds.md`)
"수렴할 때까지 반복 감사"를 사용자가 명시 요청 — 영역별 병렬 에이전트
5개씩을 5라운드(+검증 1라운드) 돌리며 매번 발견 즉시 직접 수정·커밋
(`9f9e83b`/`1aa01c6`/`b228efc`/`91fd7b8`/`6e097c9`). 반복되는 두 패턴을
찾아냄 — (1) Slot 요소 제거가 파괴→언마운트로 바뀐 여섯 번째 세션 전환이
`slot-plan.md` 여러 곳에 미반영, (2) 0-Y/0-Z가 실제로 의존하는 계약을
서술하는 문서(`architecture.md`가 가장 중요 — 모든 세션이 "먼저 읽으라"는
진입점인데 0-Z 포인터 전무, `tween-plan.md`/`effect-plan.md`/
`operator-sugar-plan.md`도 마찬가지)에 포인터 부재 — 3~4라운드에서 grep
전수 스윕으로 완전히 해소. 그 외 `DI`→`D` 리네임이 미확정인데 두 곳에서
앞서 확정된 것처럼 쓰인 것, `Slot:Splice`가 ROADMAP 체크리스트에서 누락된
것, 이미 실측 통과된 `Overridden` 서브타입 이슈가 "미검증"으로 잔존한
것도 발견·수정. 발견 건수 추이(8→7→11→9→4→0)와 마지막 라운드에 미검토
파일 전체 정독해도 새 문제 없었던 것으로 수렴 판단, 종료. 새로 열린 설계
질문 없음 — 전부 기존 서술 정합성 문제.

**2026-08-13 여덟 번째 세션 — 직전 6라운드 감사를 손으로 재검증(서브에이전트 없이)**
(`session/2026-08-13-08-direct-verification-audit.md`)
사용자가 "감사가 수렴했다는 주장 자체"를 순차 직접 검증으로 재확인 요청
(에이전트 위임 금지 — 맥락 붕괴/토큰 낭비 방지). 6라운드 더 돌려 **16건
추가 발견**(9→2→3→2→0→0, 커밋 `d3f8c4d`/`09b22d0`/`316ed6a`/`1221512`).
그중 **1건은 문서 정합성이 아니라 실제 의사코드 결함** — `Dispatch.retractFrom`의
`if retractor then` 가드가 "핸들러가 retractor 반환을 생략"한 계약 위반을
조용히 삼켜서, 문서가 주장하던 크래시가 안 나고 대신 `list`에 구멍이 뚫려
`#list` 미정의 + **점유 체크(소유권 충돌 감지)가 조용히 꺼지는** 경로였음 →
즉시 error로 전환. 그 외 큰 것: `CLAUDE.md` 1번 본문이 "스파이크를 아직
안 돌려봄"이라고 서술 중이었던 것(첫 실측이 이미 끝났는데 4라운드가 헤더
배너만 달고 본문을 안 고침), `HUMAN_TODO.md`가 6라운드 동안 한 번도 안
열려 "막고 있는 항목 없음"으로 남아 있던 것(0-Y/0-Z가 정확히 사람이
결정할 항목인데), 0-Z 반영 목록에서 `architecture.md`/`ROADMAP.md` 누락,
Slot 언마운트 전환 미반영 6곳. 뒤집힌 "폐기, 옮기지 않음 + portal 안 함"
서사는 `archive/slot-discard-no-portal-reversed.md`로 이전(slot-plan.md
1982→1919줄). **감사 사각지대 둘을 일반 교훈으로 남김**: (1) 정정 배너를
달면 그 배너가 부정하는 *본문 문장*까지 같은 커밋에서 고쳤는지 확인할 것,
(2) 영역 분할 감사는 "아무 영역에도 안 속한 파일"을 통째로 빠뜨리므로
레포 루트 파일 목록으로 커버리지를 먼저 체크할 것.

**2026-08-13 아홉 번째 세션 — 구조 재편(luau-test/bind-system/question) + 재발 방지 도구**
(`session/2026-08-13-09-structure-and-guardrails.md`)
"사람이 읽을 수 없는 문서" 문제를 사용자가 세 건 지적하고 재발 방지법을 물음.
(1) `luau-test/`를 **상태별 폴더**로 재편(`done`/`review-required`/
`rewrite-required`/`not-run`, 폴더 이동이 곧 상태 갱신 — 그래서 다른 문서는
경로 아닌 **파일명**으로 참조하도록 정규화). (2) `bind-system-plan.md`
**1단계 분할**(2989→2263줄, `ref-plan.md`/`event-plan.md`/`brand-plan.md`로
순수 이동) — 남은 디스패치·반응형 코어는 0-Z 반영 때 **어차피 전면 재작성**
대상이라 그 패스에서 같이 가르는 게 총 변경량·위험이 작다고 판단해 의도적
연기(당시 재디스패치 설계안 6절에 지시 — 14차 세션에 실제로 그렇게 처리됨). (3) `question.md`를
**사용자가 답할 것만**으로 축소(525→279줄, 해소분은
`archive/question-resolved.md`). (4) 재발 방지는 규율 문서가 아니라
**검사기**로 — `.claude/tools/doc-check.py` 신설(깨진 파일/절 참조, 색인
누락, 날짜 없는 시한부 주장, 미반영 배너). **같은 세션에 실효 증명**: 분할
중 "이중 바인딩 금지" 절 참조 4곳을 잘못 옮긴 걸 스크립트가 잡아내 되돌림.
CLAUDE.md "작업 방식"에 중대 변경 핸드오버 체크리스트 6단계도 명문화.

**2026-08-13 열 번째 세션 — 병렬 에이전트 코퍼스 감사, 실제 부정확성 7건**
(`session/2026-08-13-10-corpus-audit-parallel-agents.md`)
사용자 요청으로 세션 기록 대조 전수 감사(미확정 항목은 문제로 안 셈,
`doc-check.py` 선실행 후 기계가 못 잡는 것만 6개 병렬 Explore 에이전트로
분담). 아홉 번째 세션의 구조 변경(폴더 재편/분할/트림) 반영 누락이
대부분: luau-test 재편 후 깨진 flat 경로 참조 9곳, `bind-system-plan.md`
분할 후 자기참조/외부참조 깨짐 8곳, **`ref-plan.md`에 0-Z 배너가 안
옮겨와 옛 재디스패치 모델을 무배너로 서술 중이던 것**(반영 대상
6개→7개로 정정), "8차 세션"으로 잘못 표기된 9차 세션 작업 17곳(git
커밋 타임스탬프로 교차검증), `question.md` 트림 중 빠진 열린 질문 1건,
트림 후 깨진 참조 2곳, `ROADMAP.md` M0 섹션의 0-Y/0-Z 게이트 표시 누락.
발견 즉시 24개 파일에 직접 반영, `doc-check.py` ERROR 0 유지 확인. 새로
연 설계 질문 없음.

**2026-08-13 열한 번째 세션 — 서브 에이전트 없이 순차 직접 감사, 부정확성 4건**
(`session/2026-08-13-11-corpus-audit-sequential-direct.md`)
사용자 요청으로 에이전트 위임 없이 `.claude/base`(20개)/`research`(9개)/
`reference`(3개)/`luau-test`/`audit`/`archive`(18개) 전체를 순서대로 직접
정독. 열 번째 세션이 이미 고친 것과 같은 종류의 stale이 두 곳 더 남아있던
게 핵심 발견 — `question.md` 0-Z/0-A와 `HUMAN_TODO.md` 4번이 여전히
"6개 문서"(ref-plan.md 누락)로 서술 중이던 것을 "7개"로 정정(같은 정정이
재디스패치 설계안/`CLAUDE.md`엔 이미 반영돼 있었으나 이
두 파일엔 안 퍼져 있었음). 별도로 `ROADMAP.md` 백로그의
`objectListClass.__newIndex` 재현 테스트 항목이 세 번째 세션에 이미
불필요로 해소됐는데 그 반영이 이 파일에만 안 퍼져 있던 것도 정정. base/
research/reference/luau-test/archive 전체는 정합성 문제 없음 확인 —
`doc-check.py` ERROR 0 유지. 새로 연 설계 질문 없음.

**2026-08-13 열두 번째 세션 — 다시 서브 에이전트 없이 순차 직접 감사, 문제 없음**
(`session/2026-08-13-12-corpus-audit-sequential-no-issues.md`)
열한 번째 세션의 수정이 안정적으로 유지되는지 재확인하는 목적의 반복
감사 — `doc-check.py`(ERROR 0) + `base/`(20)·`research/`(9)·`reference/`(3)·
`luau-test/`(STATUS.md·README.md와 실제 폴더 구조 대조)·`audit/`(2)·
`archive/`(README.md 색인 18개와 실제 디렉토리 대조) 전체를 순서대로
직접 정독, 알려진 재발 패턴("6개 문서" stale, "8차 세션" 오표기) grep
재확인. **새로 발견된 부정확성 0건** — 순수 검증 라운드로 종료.

**2026-08-13 열세 번째 세션 — 0-Y 해소: 재귀 제네릭 반환은 Luau 상위 한계로 확정, `base/typing-limits.md` 신설**
(`session/2026-08-13-13-type-recursion-limit-resolved.md`)
사용자가 직접 파보던 흔적(`test-ignoreme.luau`)에서 출발해 44개 스파이크로
0-Y를 재실측 — **여섯 번째 세션의 "콜백이 raw 값을 받으면 완전 클린"
판정이 틀렸음이 드러남**(그건 "진단 0건"만 확인한 것이었고, `luau-analyze
--annotate`로 열어보니 반환 타입이 `Unifiable<Error>`로 조용히 새고
있었음 — 틀린 대입도 안 잡힘). 진짜 원인은 콜백 계약이 아니라 **`Compute`가
`State<U>`(자기 이름을 다른 타입 인자로 감싼 타입)를 반환한다는 것 자체**로,
사용자가 찾아온 RFC(`relax-recursive-type-restriction`)가 `Promise<T>.andThen`으로
예시 든 바로 그 패턴. **결론: 계약은 그대로 유지, quad가 타입을 비틀 일이
아니라 Luau의 현 한계 — 당장 할 수 있는 바 없음**(RFC는 순수 내부 변경이라
지금 선언 그대로 두면 자동 수혜, 추적 `luau-lang/luau#2380`). 대응은
**"파생 State를 만드는 자리마다 결과 타입을 명시 주석으로 바인딩"** 관례
하나(그 한 줄만 검증 안 되고 다운스트림 전체는 정상 체크됨을 실측 확인).
흩어져 있던 타입 한계 5건을 **`base/typing-limits.md`로 통합 신설**(대전제
"Luau 한계를 우회하려 타입/API를 비틀지 않는다" + 새 API 설계 체크리스트),
실측 근거는 `audit/type-recursion-issue/`(REPORT + spikes 44개, audit
폴더에 스크립트를 같이 둔 첫 예외). `question.md` 최우선이 2건→1건(0-Z만),
스파이크 `08`이 `done/`으로 가며 `review-required/`가 비었음. **가장
중요한 정정**: 판정이 뒤집힌 당사자인 `audit/luau-test-first-run-2026-08-13.md`에
배너뿐 아니라 본문 표·문단·결론까지 전수 수정(체크리스트 2번 준수).
교훈 — **`luau-analyze` 진단 0건은 타입 해소를 뜻하지 않음**, 타입
스파이크는 `--annotate` + 음성 대조군 필수.

**2026-08-13 열네 번째 세션 — 0-Z(`Attribute:GetKey`) 확정, 하강 diff 재디스패치
전면 반영, Tag/Attribute를 quad-base로 재배치**
(`session/2026-08-13-14-attribute-getkey-dispatch-diff-reflected.md`)
사용자가 `Attribute:GetKey(name)`으로 0-Z를 다시 열었고, 트레이싱 결과
**권고안 (a)(그룹 안 claimant `Relate`)가 그룹↔직접 쓰기 충돌을 못 잡는다**는
게 드러나(두 경로가 만나는 말단 핸들러에서 공개 키는 같은 객체라 소유자
구분 불가) **그룹 전용 키(비공개 `GetKey`) + `AttributeKeyHandler`의 이름
claim**으로 확정. 이걸로 마지막 게이트가 열려 **0-A(하강 diff 재디스패치)까지
한 패스로 base 전면 반영** — 9차 세션이 미뤄뒀던 `bind-system-plan.md`
2단계 분할을 같이 수행해 디스패치 코어를 **`base/dispatch-core-plan.md`로
분리·재작성**(선행 `retractFrom` 폐기, `chains` 슬롯에 `handler` 동거,
`retractFrom`이 **3-인자**로 축소, `isX(hintValue)` 가드 규칙 폐지, 깊은
체인 힌트 유실 캐비엇 삭제, 점유 체크 폐지). 사용자 제기로 **Tag/Attribute의
부기 알고리즘을 통째로 quad-base로 재배치**하고 백엔드는
`addTag`/`removeTag(inst,{string})`/`setAttribute(inst,name,v)` 3개 op만
주입(웹 `className`/`data-*` 대응 — 안 그러면 같은 참조카운트/소유권
알고리즘이 백엔드마다 복제됨), 그 실패 모드를 위해 **`HANDLER_PRIORITY_FALLBACK`**
신설(사용자 제안 — base 핸들러는 최하위 밴드, 백엔드가 덮어쓰면 언제나
이김). 옛 모델은 `archive/dispatch-hintvalue-model-reversed.md`로 이전,
스파이크 `04`(체인/`retractFrom`)와 `19`(B 섹션 = Attribute 소유권)는 옛
모델을 검증 중이라 `rewrite-required/`로 이동 — `19`의 A/C 섹션은 그대로
유효.
**M0 착수를 막는 결정이 이제 없음** — 새로 연 것은 사소한 셋뿐
(`Attribute.Merged` 이름 중복, `hintValue` 이름 재검토, 그룹 `process`
부분 실패 롤백). **[2026-08-14 후속 리뷰 라운드]** 다른 에이전트 감사 +
사용자 트레이싱으로 의사코드 결함 3건 수정 — `nameClaims`가 `Relate`의
3-인자 계약을 위반, `TagHandler`가 생존 이름의 홀더를 비웠다 되돌려
`addTag`를 헛되이 재호출(+`addTag` 배치 누락), 그룹 `process` 부분 실패
경로 미문서화. 더 큰 수확은 **`doc-check.py` 자신의 사각지대 발견** —
`REF` 정규식이 줄 단위라 파일명과 절 제목이 줄바꿈에 걸친 인용을 통째로
놓치고 있었고, 고치자 이번 분할뿐 아니라 **9차 세션 1단계 분할의 stale
참조까지** 무더기로 드러나 30여 곳 정정.

**2026-08-14 첫 번째 세션 — 컴포넌트 에러 격리 유틸 `Fallback` 백로그 신설**
(`session/2026-08-14-01-component-fallback-plan.md`)
사용자가 컴포넌트마다 손으로 `pcall`을 감싸는 게 번거롭다며, 컴포넌트
함수를 감싸 에러 시 자동으로 플레이스홀더를 그려주는
유틸(`Fallback(original, onError)`)을 제안하고 백로그 문서화를 요청 —
워크트리에서 작업.
`research/additional-primitives-plan.md`가 이미 확정한 "Error Boundary는
빈 자리 아님, `pcall(MyComp,props)`로 충분"이라는 결론을 뒤집는 게 아니라
그 위에 얹는 순수 슈가(`Operator`가 `:Compute`/`:Apply` 위에 얹힌 것과
같은 관계)로 판단해 새 research 문서 신설(세 번째 세션에
`base/fallback-plan.md`로 승격, 이하 경로는 신설 당시 기준) —
`xpcall`+`debug.traceback` 메커니즘 스케치, 커링 관용구, 열린 질문(pcall
vs xpcall, 패키지 배치, 이름, 프로덕션 동작) 정리, 설계 확정은 아직 없음.
부수적으로 워크트리가 계획 문서 없이 빈 채로 시작되는 걸 발견 —
**[정정, 후속 `/code-review`]** 처음엔 "`.claude/`가 git에 안 커밋돼
있어서"로 잘못 진단했으나, 실제로는 `EnterWorktree` 기본값이
`origin/master`에서 갈라치는데 `SAFETY.md`(GitHub push 금지) 때문에
계획 문서가 로컬 `main`에만 있고 `origin`엔 애초에 없는 것(의도된 것)이
원인 — 필요한 파일만 메인 체크아웃(로컬 `main`)에서 복사해 편집 후 다시
복사하는 방식으로 처리, 상세 정정은
`session/2026-08-14-01-component-fallback-plan.md` 참고.

**2026-08-14 두 번째 세션 — `Fallback` 메커니즘 `xpcall` 실측 확인**
(`session/2026-08-14-02-fallback-xpcall-spike-verified.md`)
직전 세션이 열어둔 "`xpcall` 에러 핸들러 배선의 실측 필요"를 새 워크트리에서
`luau` 스파이크(현재 `audit/fallback-xpcall-spike.luau`로 이동)로 확인 —
클로저 업밸류 배선, 3단 중첩 `debug.traceback` 캡처 등 10개 검증 전부
통과. 부수 발견으로 `error(msg)` 기본 호출(level=1)이 위치 접두
("파일:줄: ")를 자동으로 붙인다는 캐비엇을 새로 확인해 문서에 반영 —
당시 research 문서(현재 `base/fallback-plan.md`)의 해당 열린 질문을
해소로 표시, 백로그 우선순위 자체는 그대로.

**2026-08-14 세 번째 세션 — `Fallback`/`Traceback` 승격**
(`session/2026-08-14-03-fallback-traceback-promoted.md`)
사용자가 `Fallback`/`Traceback`으로 분리(`pcall` 기반 vs `xpcall`+trace
기반), 정확한 제네릭 시그니처(`Traceback`은 `onError`가 `trace: string`도
받는 것만 `Fallback`과 다름 — 전체 시그니처는 `base/fallback-plan.md`
참고), `err: any`(사용자 REPL로 테이블 에러 통과 재확인), 패키지
(`quad-base`), 이름(`Fallback`/`Traceback` 그대로 점유)까지 한 번에
확정 — 남은 열린 질문이 없어져 research/ 초안을 `base/fallback-plan.md`로
승격(파일 이동), 스파이크는
`audit/fallback-xpcall-spike.luau`로 옮기며 내부 함수명도 `Traceback`으로
정정. `README.md`/`question.md`/`archive/question-resolved.md`/
`research/lifecycle-hooks-plan.md`의 상호 참조 전부 동기화.

**2026-08-14 네 번째 세션 — `ProcessedPreRef` 신설로 Length/Offset 등록
갭 해소, `PostRef` 완전 대칭화**
(`session/2026-08-14-04-processedpreref-postref-symmetry.md`, 아래
`여섯 번째 세션`이 신설한 `research/lifecycle-hooks-plan.md`의 `PostRef`
스케치를 이어받아 갱신 — 그 세션의 실제 작업은 이 세션보다 먼저
있었으나, 다른 세션과의 병합 조율로 커밋이 이 세션 이후로 밀림)
사용자의 "PreRef 소진으로 생기는 공백이 setLength/setOffsetSource를
안 깨뜨리는가" 질문을 읽기 전용으로 조사한 결과, 소진 값이 `None`이라
정상 두 패스가 그 자리를 아예 안 거쳐 "누가 그 등록을 호출하는가"가
문서 어디에도 없는 진짜 갭임을 발견. 사용자가 전용 센티널
`ProcessedPreRef`+`ProcessedPreRefHandler`(매치되는 Handler 자신이
`setLength(0)`/`setOffsetSource(None)`을 등록)로 해소를 제안, `base/
ref-plan.md`/`dispatch-core-plan.md`/`ROADMAP.md`에 반영(파생 서술 3곳
정정 포함). 백로그 `PostRef`(`research/lifecycle-hooks-plan.md`)도 같은
원리로 갱신하되, 사용자 제안으로 더 단순화 — 별도 후행 재순회 없이
PreRef pre-pass 한 스윕에서 `isPostRef`도 같이 소진해 `postRefList`에
적재해두는 안으로 Pre/Post 소진 메커니즘이 완전 대칭됨.
`doc-check.py` ERROR 0 유지 확인 후 커밋(`e0ef7ce`). 같은 세션에
`/code-review high`를 두 차례 시도했으나 둘 다 파인더 완료 전에 결과가
도착하지 않아 리뷰 반영은 못 함 — 나중에 결과 도착 시 별도 검토 필요.

**2026-08-14 다섯 번째 세션 — `canExecute(inst,value)` 2-인자 역전,
`.Subscribed` 오염 제거·`canBound` 폐기**
(`session/2026-08-14-05-canexecute-value-scoped.md`)
`canExecute`/`unbindLifetime`이 `inst`를 받던 2-인자 시그니처를 폐기하고
`value` 단독으로 정정 — 뿌리는 2026-08-08에 들어온 "`bindLifetime`이
`.Subscribed`를 세팅한다"는 오염이었고(그 필드는 전역 `:Subscribe()`
전용), `bindLifetime`이 gcconn 참조를 `value` 쪽 `Relate`로 복사해두면
생존을 `value` 하나로 물을 수 있음. 이 오염 위에 세워졌던 `canBound`는
폐기되어 `canExecute` 하나로 통합, gcconn/gchold 생성도 lazy에서
**Instance 생성 시점**으로 올라가며 클로저가 `inst`까지 캡처(userdata
포인터 동일성 = `inst`-키 `Relate` 전체의 전제). 여섯 세션을 살아남은
이유가 "`canExecute`의 실제 호출부(State 전파 루프)가 어느 문서에도
코드로 없었음"이라, 교훈으로 "계약을 정할 때 호출부를 최소 하나는
의사코드로 같이 적을 것"을 남김. 정본은 `base/lifecycle-pattern.md`,
역전 원문은 `archive/canexecute-inst-arg-reversed.md`.

**2026-08-14 여섯 번째 세션 — 생명주기 훅 `OnCreated`/`OnDestroyed` 백로그
신설, `OnRendered`는 의도적 보류** (`session/2026-08-14-06-lifecycle-hooks-plan.md` —
실제 작업은 위 네 번째 세션보다 먼저였으나, 다른 세션과 메인에서 동시
작업 중이라 병합·커밋 조율에 시간이 걸려 세션 번호가 뒤로 밀림)
사용자가 React/Vue류 `OnCreated`/`OnRendered`/`OnDisposed`를 `PreRef`/
`Effect` 위 슈가로 구현할 수 있을지 제안, 워크트리에서 조사 요청. 확인
결과 `OnCreated(fn)`→`PreRef():Callback(fn)`, `OnDestroyed(fn)`→
`Effect(function() return fn end)`는 호출 즉시 평가돼 기존 프리미티브
인스턴스로 사라지는 순수 팩토리라 새 Dispatch/Brand 개념이 전혀 안
생김(다중 등록도 자연 지원) — 이게 사용자가 처음 우려했던
`:Compute`의 `State<function>` 문제가 애초에 안 생기는 이유와 같은
뿌리임을 확인. `OnDisposed`(미래 `dispose()`와 이름 맞추기 제안)는
검토 후 기각 — 훅의 실제 트리거는 `dispose()` 호출이 아니라 엔진
`Destroying` 신호라 `OnDestroyed`가 더 정직함(`dispose()` 대상 범위가
0-B로 아직 미확정이라 나중에 재검토 여지는 남겨둠). `OnRendered`는
프로퍼티/이벤트 세팅 완료를 보장하는 훅이 base에 없어 `Dispatch.drive`에
실제 post-pass가 필요하다는 게 드러나 공짜가 아님을 확인 — 사용자가
**지금은 의도적으로 구현 안 하기로 확정**, 다만 `PreRef`의 거울상인
`PostRef`(같은 메커니즘을 후행 스캔으로 뒤집기만 하면 됨)로 구현하면
될 것 같다는 구체 스케치를 남겨 백로그 후보로 보존 — 네 번째 세션이
이 스케치를 이어받아 `ProcessedPreRef` 기반으로 갱신함(위 참고).
`question.md`엔 안 올림(이미 "지금 안 함"으로 답이 나온 질문이라).
**[역전, 같은 날 아홉 번째 세션]** 이 "지금은 구현 안 함" 결정은 뒤집혔음
— `PostRef`/`OnRendered` 둘 다 채택 확정되어 `base/ref-plan.md`/
`base/lifecycle-hooks-plan.md`로 승격됨(아래 아홉 번째 세션 항목).
"공짜가 아니다"라는 판단 자체는 그대로 맞고, 그 비용을 지불하기로 한 것.
`research/lifecycle-hooks-plan.md` 신설, README 인덱스 반영, 별도
워크트리에서 작업 후 메인에 수동 반영(다른 세션이 동시에 메인에서
작업 중이라 병합 타이밍을 사용자와 직접 조율) — 커밋 `9f9a68f`. 같은
세션 후속으로, CLAUDE.md 세션 기록에 직접 편집하던 중 다른 세션이
동시에 같은 파일에 uncommitted 내용을 넣고 있던 걸 발견해 커밋을
잠시 보류했다가, 그 세션이 정리된 뒤 이 항목을 원래 자리(세 번째)에서
지금 자리(여섯 번째)로 옮기고 번호를 재조정 — 동시 편집 충돌 시
"내용은 안 섞여도 순서/번호가 꼬일 수 있다"는 사례로 남김.

**2026-08-14 일곱 번째 세션 — UI 숏핸드 Tween 지원, existing-instance-bind
기각, `bind-system-plan.md` 3단계 분할(`store-plan`/`source-state-plan` 신설)**
(`session/2026-08-14-07-store-source-split-shorthand-tween.md`)
사용자가 한 메시지로 세 건 지시. (1) **UI 숏핸드 Tween 지원** — 새 기능
추가가 아니라 **역전 반영**이었음(`ui-shorthand-plan.md`가 "트윈까지 지원할 필요 없음"이라 못박아둔 것은 Tween이 아직 독립 Dispatch 핸들러이던 시절 판단인데 2026-08-10
값-레벨 래퍼 재설계를 안 따라와 있었음). 확정 메커니즘은 사용자 제안 그대로
— 숏핸드가 자식을 만들거나 찾은 뒤 프로퍼티를 **직접 대입하지 않고**
`Dispatch.process(child, prop, ..., 1)`로 위임하면 Tween이 공짜로 따라옴
(해석 코드는 `PropertyHandler` 하나에만 남는 불변식 유지). "process 중
`inst`를 바꾸는 것은 키를 바꾸는 것과 같은 층위라 UB 아님"을
`dispatch-core-plan.md`에 일반 규칙으로 명문화(위임한 자식의 수명 책임은
위임한 핸들러). 새로 필요한 부품은 스칼라→프로퍼티 `wrap`을 `Tween<T>.Value`
에만 적용되도록 들어올리는 헬퍼 하나뿐. **ROADMAP M10에 UI 숏핸드 항목이
통째로 빠져 있던 갭도 발견·보강.** (2) **`existing-instance-bind` 기각** —
"열린 가능성"에서 미지원 확정으로, `archive/existing-instance-bind-rejected.md`
(사유: Length/Offset 등 quad가 만든 트리를 전제한 부기를 바깥에서 밀고
당기는 버그 표면이 치명적으로 넓어짐). "열려 있음"을 전제로 쓰인 본문
문장 7곳(특히 `architecture.md`의 "아직 미정" 절 — 유일 항목이었음,
`ref-plan.md`의 flatten 기각 근거)까지 같은 커밋에서 정정.
(3) **문서 분할** — 사용자가 합당성 판단을 먼저 요청했고, 두 문서(`bind-system-plan.md` + store-semantics.md)가 같은
주제를 반씩 나눠 갖고 서로를 "상세는 저쪽" 핑퐁하던 게 실재해 **합당하다고
판단 후 수행**: `base/store-plan.md`(Store=이름 붙은 Source 모음)와
`base/source-state-plan.md`(반응형 코어) 신설, store-semantics.md는 완전
흡수되어 삭제, `bind-system-plan.md`는 1238→203줄(인스턴스 생성·이벤트
네이밍 + 분할 색인만). 캐비엇으로 "남은 내용보다 파일 이름이 넓어졌지만
리네임 churn이 커서 이번엔 제목만 변경"을 보고. **교훈** — `doc-check.py`의
`OURS` 패턴이 `-plan`류 접미사 기준이라 store-semantics.md 같은 이름은
삭제해도 ERROR가 아니라 WARN으로만 잡힘, 그래서 ERROR 목록만 믿지 말고
grep 전수를 같이 돌려야 함. 최종 ERROR 0 / WARN 85(작업 전 101).

**2026-08-14 여덟 번째 세션 — Debounce/Throttle 백로그 신설 + "emit은 항상
전파" 정정(base 역전)**
(`session/2026-08-14-08-debounce-throttle-backlog.md`)
사용자 요청("`Blocker`와 유사하게 만들어야 함, 너가 먼저 다 정의해봐라")으로
**워크트리**에서 `research/debounce-throttle-plan.md`를 만들고, 네 번의 리뷰
왕복으로 다듬은 뒤 메인에 필요한 변경만 이식. **확정된 것**: (1)
Debounce/Throttle은 `Blocker`가 이미 쓰는 게이티드 노드의 **릴리스 트리거만
타이머로 바꾼 것** — 새 전파 메커니즘이 아니고, 공개 `Blocker` API엔 "상류
신호 도착" 통지가 없어 그 위엔 못 얹으므로 **M3에서 게이트를 공용으로 뺄 것**,
(2) **두 도구의 차이는 "신호가 창 타이머를 리셋하는가" 한 비트뿐**(공개
생성자 2개 + 내부 구현 1개) — 초안이 옮겨온 lodash식 `maxWait` 공식엔 trailing
통과 직후 **이중 발화** 버그가 있었고 이 정식화로 구조적으로 사라짐,
(3) 알고리즘은 **quad-base + 주입 op 2개**(`setTimeout(func, delay) -> Timeout`
/ `clearTimeout`, Roblox는 `task.delay`/`task.cancel` — **인자 순서 반대 주의**;
`task`가 표준도 Luau의 것도 아닌 한 엔진의 것이라 엔진 중립 JS 어휘를 택함),
`os.clock()`은 Luau 표준 라이브러리라 주입 대상 아님(단 **절대 시각이 아니라
diff 전용**), 취소 없는 엔진도 래핑+유효 플래그로 대응 가능,
`Timeout = { __type_timeout: true, _native: any }`.
**⭐ 가장 큰 수확은 부수 발견** — 사용자가 **"emit은 항상 재전파된다"**고
지적해, `source-state-plan.md`의 무효화 dedup 서술("이미 invalid였다면 그
아래로 더 전파하지 않는다", 다이아몬드 중복 워크 방지)이 **확정된 `Observer` 계약(`fn`이 `:Get()`을
안 불러도 됨)과 정면 충돌**함이 드러남 — 액면대로면 `:Get()` 안 하는 Observer는
**한 번 울고 영구 침묵**. `architecture.md`가 같은 문제를 pull-recompute로
설명하는 것과도 어긋나 있었음. 정정 모델: `invalid`는 **캐시 낡음 표시**일
뿐이고 emit은 자기 상태와 무관하게 **항상 전파**, 중복 **재계산**은
pull-recompute+캐시가 막고 중복 **통지**는 안 접음(접으려면 `Blocker` 같은
명시적 게이트). base/reference/research/ROADMAP/스파이크/audit 전면 정정,
`05-store-state-diamond-propagation.luau`는 옛 모델을 통과 상태로 검증
중이었어서 `rewrite-required/`로 이동. 역전 기록은
`archive/invalidate-dedup-propagation-reversed.md`. **교훈** — 이 오류 위에
그 문서의 "가장 중요한 발견"(파생 State 위 debounce 퇴화)이 두 라운드나
쌓였다가 통째로 철회됨. **확정 문서의 한 문장을 근거로 새 설계를 세울 땐,
그 문장이 *같은 문서의 다른 확정 문장*과 모순되지 않는지까지 확인할 것** —
`doc-check.py`는 참조 존재는 봐도 서술 간 모순은 못 봄.

**2026-08-14 아홉 번째 세션 — `PostRef` 확정·`OnRendered` 채택, 계열 안
fire 순서는 미보장으로 갔다가 철회(보장 유지), `lifecycle-hooks-plan.md`
base 승격**
(`session/2026-08-14-09-postref-confirmed.md`)
사용자가 백로그 후보로만 남아 있던 `PostRef`를 확정(선택지 (a) — pre-pass
공동 수집 + 두 패스 뒤 `postRefList` 소비, "Pre-Post 둘을 지원 안 할 이유가
없고 구현 난이도가 아주 낮음"). `PreRef`의 거울상이라 소진 센티널
(`ProcessedPostRef`)·전담 Handler·동적 경로 가드·`_fired`·타입 차단이 전부
복제 — `base/ref-plan.md`에 "`PostRef`" 절로 편입. **원 문서가 열어뒀던
(a)/(b) 스코프 구분은 애초에 잘못된 축이었음이 드러남**: 배열 파트 루프가
각 자식 마운트를 동기적으로 끝내므로 (a) 메커니즘이 (b)(서브트리 완성)를
공짜로 줌 — 진짜 경계는 **"자기 아래 vs 자기 위"**로, `PostRef`는 서브트리
완성은 보장하되 **이 인스턴스가 부모에 붙기 전**에 불림(React
`componentDidMount`와 다름, `OnRendered` 이름 때문에 문서화 필수 캐비엇).
같은 세션에 **`PreRef`/`PostRef` 계열 안 fire 순서**를 미보장으로 뒤집었다가
**곧바로 철회, "배열 index 순서 보장" 유지**(2026-08-07 결정 그대로) —
사용자가 든 반례가 `FastQuery(...) -> PreRef`류 조합(앞자리 항목이 뒤
항목의 전제를 만들어주는 정당한 합성)이었고, 보장 비용이 0인 데다 배열
파트 index 순서가 이미 백엔드 이식성 때문에 명시적 계약이라 새로 내주는
자유도 없음이 확인됨. 양쪽 논거는
`archive/preref-order-unguaranteed-withdrawn.md`. `OnRendered` 채택으로
`lifecycle-hooks-plan.md`의 마지막 열린 항목이 닫혀 `base/`로 승격, 남은
건 `OnDestroyed` 이름 재검토 여지 하나(0-B 확정 시, `question.md` 용어
대기열 3순위). ROADMAP M8/백로그·README·brand/architecture/slot/modifier/
typing-limits 전파 완료, `doc-check.py` ERROR 0.

**2026-08-14 열 번째 세션 — `dispose(value)` 시그니처/범위 확정, `question.md` 0-B 해소**
(`session/2026-08-14-10-dispose-scope-resolved.md`)
사용자가 0-B의 남은 미확정(시그니처/대상 범위/`unbindLifetime`과의 역할
분담)을 직접 확정: **범위는 `Slot`+엔진 객체(`Instance`)만, `Observer`/
`Effect`는 명시적으로 제외**(둘은 children 배열 leaf에서 `bindLifetime`/
`canExecute`(GC-native)만으로 관리되고 Slot 같은 트리 부기 자체가 없어
dispose가 막는 문제가 원천적으로 안 생김). 시그니처는 `dispose(value:
Slot | Instance)` — `isSlot`이면 기존 `elementOwner` 판정 재사용, 아니면
`disposeInst(inst)`(`addTag`/`removeTag`/`setAttribute`와 같은 "base
소유+op 주입" 패턴)로 위임. 네이밍은 `free`(GC 언어 맥락과 안 맞음)/
`Destroy`(엔진 `:Destroy()`와 혼동 위험) 둘 다 기각하고 `dispose` 유지.
과정에서 어시스턴트가 "Observer/Effect가 `State<>`로 지원되는지"를 처음에
Modifier 필드 금지 규칙과 혼동해 잘못 답했다가 사용자 지적으로 정정 —
실제로는 children 배열 leaf(`Dispatch/Leaf.luau`)가 이미 `Observer`/
`Effect`를 지원 대상으로 확정해뒀고, `StoreBind`가 "범용, `k`는 무엇이든
받음"이라 `State<Observer>`도 별도 설계 없이 기존 재귀 디스패치 원칙만으로
됨. 부수 해소로 `base/lifecycle-hooks-plan.md`의 `OnDestroyed` 이름
재검토 조건("0-B가 모든 것의 유일한 파괴 경로로 풀리면")도 반대 방향
(범위가 좁아짐)으로 확정되며 발동 없이 영구 종결. `question.md`/
`archive/question-resolved.md`/`base/slot-plan.md`/
`base/dispatch-core-plan.md`/`base/architecture.md`/
`base/lifecycle-hooks-plan.md`/`ROADMAP.md`/`HUMAN_TODO.md`/`README.md`
전부 반영, `doc-check.py` ERROR 0 유지.

**2026-08-14 열한 번째 세션 — 코퍼스 전체 감사(서브에이전트 6개 병렬),
`canBound`/`canExecute` 재분리로 `question.md` 0-W 해소**
(`session/2026-08-14-11-corpus-audit-canbound-resplit.md`)
6개 병렬 서브에이전트 감사로 stale 서술 15개 파일 정정, `question.md`
0-W(`Ref` 이중 배치 방지) 확정 — `canBound`를 `canExecute`와 별도
진입점으로 재도입(판정 로직은 `isBoundAlive` 하나로 공유). 후속으로
`PreRef`/`PostRef`/`Observer`/`Effect`의 non-number 키 유입을
`HANDLER_PRIORITY_FALLBACK` 동적 경로 가드로 통일, Tag/Attribute
백엔드 op 미주입 처리 정책을 네 라운드 정정 끝에 확정(**그 최종
결론 중 "TagHandler가 quad-base 모듈 로드 시점에 스스로 등록"은
**[역전, 같은 날 열두 번째 세션]** — 원문·근거는
`archive/tag-attribute-load-time-registration-reversed.md`). 이어진
`git diff` 자기 감사와 `/code-review high`가 각각 추가로 3건씩 발견·
수정(대부분 `canBound` 재도입 때문에 stale해진, 이 세션이 안 건드린
파일들 — 자기 감사가 "건드린 파일만" 훑는 사각지대를 재확인).
`doc-check.py` ERROR 0 유지.

**2026-08-14 열두 번째 세션 — Observer/Effect Leaf에 `Ref`와 같은 dedup 추가(성능)**
(`session/2026-08-14-12-observer-effect-leaf-dedup.md`)
`State<Observer>`/`State<Effect>`가 재-dispatch될 때 안쪽 값이 안 바뀌어도
Dispatch는 값 비교 없이 매번 `retractor`+`process`를 다시 부름 — 처음엔
`bindLifetime`/`unbindLifetime`이 저렴한 weak-table 쓰기뿐이라(실제
Roblox 커넥션은 Instance 생성 시 한 번만 만들어짐) 버그가 아니라고
결론지었으나, 사용자가 "`==` 비교가 매번 도는 해싱 비용보다 항상 싸다"고
지적 — correctness와 무관하게 순수 성능 이유로 `RefLeafHandler`와 같은
`old ~= v` dedup을 그대로 채택. `base/dispatch-core-plan.md`(4번 절)
정정 + `base/source-state-plan.md`에 새 절 "Observer/Effect Leaf dedup"
신설(pseudocode 포함).

**같은 세션 후속 — `/code-review` findings 11건 전부 반영.**
`isHandlable`이 `k` 타입을 안 봐서 죽어있던 FALLBACK 가드 수정,
`bindLifetime` pseudocode의 `canExecute`→`canBound` 정정,
"동적 경로 가드"(볼드 텍스트뿐 실제 헤딩 아니었음) 3곳을 `###`으로
승격, `question.md`/`CLAUDE.md`/`HUMAN_TODO.md`가 공통으로 갖고 있던
"결정 대기가 비어 있다"는 서술을 "그 헤딩 자체가 삭제됐다"로 정정,
11번째 세션 기록 ~103줄→~13줄 압축(전문은
`session/2026-08-14-11-corpus-audit-canbound-resplit.md`에 보존).
**가장 큰 건**: 고치던 중 사용자가 "Tag/Attribute를 base가 스스로
등록한다는 게 사실이 아님"을 지적 — 열한 번째 세션이 네 라운드
정정 끝에 확정했던 그 결론 자체가 틀렸음이 드러남(`base/
lifecycle-pattern.md`가 이미 거부해둔 `InitNamespace`류 top-level
부작용 패턴과 같은 클래스). 정정: `TagHandler`류는 참조 카운트
**알고리즘 구현**일 뿐 스스로 등록 안 됨 — `HANDLER_PRIORITY_FALLBACK`엔
별도 이름의 `TagFallbackHandler`류가 꽂히고, 등록 주체는 quad-base
모듈이 아니라 **백엔드 팩토리**(`BaseModule` 뮤테이션 시점, 자기 전용
Handler들과 같이 — `module-lifecycle-plan.md`가 이미 확정해둔 패턴
그대로, 새 예외 아님). `dispatch-core-plan.md`/`tag-plan.md`/
`attribute-plan.md`/`architecture.md`/`module-lifecycle-plan.md` 전부
재반영, 뒤집힌 원문은 `archive/
tag-attribute-load-time-registration-reversed.md`. `doc-check.py`
ERROR 0 유지.

**같은 세션 후속 — 같은 실수의 다른 잔존 여부 전수 확인.** "모듈
로드 시점에 스스로 등록"류 주장을 코퍼스 전체 grep — 두 매치는
오탐(정적 lookup 테이블, React DevTools 비교 서술), 일반 Handler
등록 절(`dispatch-core-plan.md` 492~516줄)은 이미 정확했음. 진짜
갭은 `ROADMAP.md` M10 체크리스트 — 새로 분리된
`TagFallbackHandler`/`AttributeKeyFallbackHandler`/
`AttributeGroupFallbackHandler` 파일 자체가 체크리스트에 없어서
구현자가 만들 필요를 몰랐을 상태였음, 세 항목 추가 + 배너 정정 +
`architecture.md` 파일 트리 설명 보강.

**같은 세션 후속 — 두 번째 `/code-review high`가 3건 더 발견.**
`tag-plan.md:155`의 `TagHandler.priority = HANDLER_PRIORITY_FALLBACK`
pseudocode가 프로즈 정정과 모순됐던 것(가장 심각 — 실제 코드로
복붙될 블록), `dispatch-core-plan.md:612`의 opt-in 예시가 여전히
"`TagHandler` 자신(FALLBACK)"이라 서술하던 것 — 둘 다 정정 +
`TagFallbackHandler` 래퍼 pseudocode 신설. 별개로 `ref-plan.md:257`의
`RefLeafHandler.isHandlable`이 `and not isPostRef(v)`를 빠뜨린
**사전 존재 버그**(PostRef 도입 9차 세션 때 안 갱신됨, 이번 세션과
무관)도 같이 잡혀 정정, `architecture.md`의 `Leaf.luau` 파일 트리에
빠져있던 `Effect` 타입도 보강. `doc-check.py` ERROR 0 유지.

**2026-08-14 열세 번째 세션 — `quad` 재귀 약어 브레인스토밍**
(`session/2026-08-14-13-recursive-acronym-brainstorm.md`)
GNU/WINE류로 `Quad`를 재귀 약어화하는 순수 카피 브레인스토밍 —
설계 결정/착수 게이팅과 무관. 자학 개그 방향(`Quad Undoes All (that
v1) Did` 등)은 톤이 안 맞아 기각, 사용자가 실제로 내걸고 싶어한
지연평가·재귀/커링·펑터·일급 익명 클로저 방향으로 `Quad Unwinds,
Applies, Defers` 등 4개 후보 정리 — `research/quad-recursive-acronym.md`
신설(나중에 README.md 헤딩 후보용), 최종 문구는 미확정.

**2026-08-14 열네 번째 세션 — 코퍼스 전체 사실관계 감사, `doc-include.py`
백로그 신설** (`session/2026-08-14-14-corpus-audit-doc-include-backlog.md`)
서브에이전트 4개 병렬(base/research+reference/luau-test+audit/archive+root)로
전 코퍼스 재감사 — `bind-system-plan.md` 3단계 분할 후 stale 참조 11곳,
`HUMAN_TODO.md`의 `canBound` 재도입 미반영, 날짜 없는 완결 주장 4건 등
13개 파일 20건 수정, `doc-check.py` ERROR 0 유지(커밋 `f829487`). 이어
사용자가 반복된 stale 원인(같은 사실이 여러 곳에 중복 서술)을 근본적으로
줄이는 방법으로 마커 기반 include 도구(원본에 요약 구간을 마커로 표시,
인용 문서가 기계적으로 추출해 붙여넣음)를 제안 — AsciiDoc tagged
include/markdown-magic이 선례임을 확인 후 build-vs-buy 논의, 문제가 좁고
기존 도구는 새 Node/npm 의존성을 들여온다는 이유로 **직접 제작**(Python,
`doc-check.py`와 짝) 채택. 오늘은 플랜만 `research/doc-include-plan.md`로
작성 — 파일럿은 부작용이 가장 작은 CLAUDE.md 세션 히스토리부터, 마커
문법·소급 적용 범위 등 열린 질문은 **사용자가 내일 직접 다듬기로 함**,
구현 착수 안 함.

**2026-08-15 세션 — `typeof(named fn)` 간접참조로 0-Y 우회 실측,
`luau-test/16` 복구** (`session/2026-08-15-01-typeof-recursive-generic-workaround.md`)
사용자가 발견한 "재귀 메소드를 인라인 대신 이름 붙은 함수 + `typeof`로
선언하면 0-Y(재귀 제네릭 반환 leak)가 안 생기는 것 같다"는 관찰을
`--annotate`+양성/음성 대조군+체이닝 깊이 1~50 스윕으로 검증 —
**확인됨**(LHS 명시 없이도 다운스트림 안전, 콜백 파라미터 명시 주석은
여전히 필요). `typing-limits.md` §1에 ③으로 추가(①을 대체하지 않는
보강). 도중 시도한 `setmetatable<{...}, {__index: typeof(fn<<T>>())}>`
확장은 quad의 실제 self-핸들 콜백 계약에서 **모순되는 진단 두 개가
동시에 남는 Luau 0.733 솔버 버그**를 만나 채택 안 함(quad와 무관한
버그로 판단, 최소 재현 9줄 남김). 병행: `luau-test/16(type function으로
`Store<T>` 필드 합성)`이 API 버전 드리프트로 깨져있던 걸 복구 —
`typing-limits.md` §5를 "미검증"→"검증 완료"로 승격,
`done/`으로 이동. type function으로 0-Y 자체를 우회하는 시도는
`stack overflow`로 막다른 길 확인. 전체 실측:
`audit/type-recursive-issue-with-typeof/`.

**2026-08-15 두 번째 세션 — 콜백 파라미터 무주석 추론 전방위 재시도,
`/code-review` 2회전 정합성 수정**
(`session/2026-08-15-02-try-callback-investigation-and-review-fixes.md`)
사용자 요청으로 "콜백 파라미터는 명시 주석 필요" 캐비엇을 type
function/메타테이블/제네릭 등으로 전방위 재시도(`audit/
type-recursive-issue-try-callback/`, spikes 35개) — **결론은 그대로
"안 됨"**이지만 근본 원인이 재귀 특유가 아니라 "제네릭 콜백 인자엔
컨텍스트 타입 전파 자체가 안 됨"이라는 더 일반적 한계임이 드러났고,
`/code-review high`가 지적한 이중 꺾쇠 명시 인스턴스화(`Compute<<T,U>>(fn)`)
후속 조사까지 포함해 near-miss 세 개(중간 변수 고정/monomorphize
헬퍼/명시 인스턴스화) 전부 §0 대전제(API를 타입 사정으로 비틀지 않음)
위반으로 기각. `typing-limits.md` §1에 각주로만 반영, 원칙 자체는
안 바뀜. 이어진 `/code-review` 2회전이 이 작업과 직전 세션 산출물
전반에서 정합성 문제(옛 솔버 캐비엇 누락, 체크리스트 항목 간 모순,
`type-recursion-issue/REPORT.md`의 실제 틀린 서술(`06`이 통과한다는
잘못된 주장, 재귀가 아니라 "self가 제네릭인가"가 진짜 분기점이었음),
스파이크 개수 off-by-one 2건, 이 세션 자체의 히스토리 누락 등) 다수
발견·수정.

**2026-08-16 세션 — 코퍼스 감사 서브에이전트/워크플로 신설, CLAUDE.md 4분할**
(`session/2026-08-16-01-subagent-audit-and-claudemd-split.md`)
사용자가 "핸드오버 전/커밋 전에 code-review 같은 걸 스스로 돌게 만들 수
있나"에서 출발 — hook은 셸 명령만 실행해 스킬/서브에이전트를 직접 못
부르므로, **읽기 전용 감사자 `.claude/agents/quad-doc-auditor.md`**(발견만
리포트 — 처음엔 `memory: project`를 켰으나, 그게 켜져 있으면 에이전트 등록
목록에 Write/Edit이 같이 딸려오는 것으로 보여 같은 세션 후속 작업에서 다시
뺐음. **[2026-08-16 기준] 옵션을 뺀 뒤에도 Write/Edit이 그대로 주어져 원인
진단은 미확정**. **[2026-08-16 정정]** 한때 `.claude/agent-memory/quad-doc-auditor/`를
"아무도 로드하지 않는 잔여물"로 적어뒀으나, 옵션을 뺀(02:03) 뒤 돌린 감사에서도
그 디렉토리에 새 기록이 쌓이는 게 실측돼(02:11) 반증됨 — 메모리는 여전히
로드·기록되고 있으니 잔여물로 취급하지 말 것. 최신 상태는
`.claude/agents/quad-doc-auditor.md` 상단 배너가 소스. 어느 쪽이든 읽기
전용은 도구 유무가 아니라 프롬프트의 행동 규약으로 못박음)와 **다회·병렬 수렴 루프
`.claude/workflows/quad-handover-audit.js`**(라운드당 병렬 3회 감사 +
파일별 즉시 반영을, 새 발견 없는 라운드가 연속 2번 나올 때까지 최대
6라운드 — 이 상수들은 튜닝 대상이라 소스는 `quad-handover-audit.js` 상단,
여기 숫자는 도입 당시 값)로 나눠 구성. 첫 실측은 `.claude/agents/`가 세션 도중 생긴
디렉토리라 6개 전원 `agentType not found`로 실패 — **더 중요한 건 그
실패가 `converged:true`로 보고된 것**(감사 패스가 전멸해도 `fresh`가 비어
"깨끗한 라운드"와 구분이 안 됐음). 감사 도구 최악의 실패 모드라 즉시
가드 추가(전멸이면 throw, 반영 에이전트 실패 시 그 발견을 `seen`에서
빼 다음 라운드가 재시도). 이어 사용자 지적으로 **루트 `CLAUDE.md`
1537줄을 4분할** — `conventions.md`(관례+작업 방식) /
`project-context.md` / `todos.md`를 `@import`하고,
**`session-summary.md`(분할 전 `CLAUDE.md`의 80%)는 의도적으로 import 안 함**
(그 문서 스스로 "항상 읽을 필요 없음, `base/`가 소스"라고 명시해왔음) —
매 세션 로드가 분할 전 `CLAUDE.md` 분량의 극히 일부로 줄었음(구체적인 줄
수는 계속 바뀌니 여기 안 적음 — 궁금하면 그때 `wc -l`). 부수 수확: 공식 문서에서 (a) 권장치가 파일당
200줄이고 초과 시 **지침 준수도 자체가 떨어진다**는 것, (b) `@import`는
컨텍스트를 **안 줄인다**는 것, (c) CLAUDE.md 계열의 블록 HTML 주석은
주입 전 제거돼 **에이전트가 못 본다**는 것을 확인(자기 변경에서 실제로
이 함정을 밟았다가 정정). 분할로 깨진 상호참조 20여 곳을 병렬 에이전트
3개로 정정했고, 그 중 하나가 **내가 준 전제("`dispatch-core-plan.md:41`은
stale")가 틀렸음**을 잡아냄(실제로는 `initreq/tbox/CLAUDE.md`를 가리키는
유효 참조). `doc-check.py`도 갱신 — 새 파일 4개를 `OURS`에 등록(안 하면
깨진 참조가 WARN으로만 잡힘, 7차 세션 `store-semantics.md` 사각지대 재발
방지 — 그때 삭제된 store-semantics 문서가 WARN으로만 잡혔던 건)하고
`session-summary.md`를 `archive/`와 같은 히스토리 문서로 면제.
`research/doc-include-plan.md`는 이 분할로 **설계 절반이 불필요해져**
양방향 마커 → 단방향 생성으로 단순화(목적지가 통째로 생성되는 파일이라
`<!--#include-->` 마커 자체가 필요 없어짐).

**2026-08-16 두 번째 세션 — 감사 툴링 재시작 검증, 핸드오버 감사 첫 실동(수렴 실패)**
(`session/2026-08-16-02-audit-tooling-verification-and-first-real-run.md`)
전 세션이 남긴 재시작 검증 3건을 전부 닫음 — `@import` 로드 ✅, 
`quad-doc-auditor` 등록 ✅, frontmatter `model: sonnet` 반영 ✅(트랜스크립트
기록 기준). **가장 큰 수확은 워크플로 정의 해석이 호출 방식에 따라
갈린다는 것을 1차 증거로 확정한 것** — `Workflow({name})`은 세션 시작 시점
스냅샷을 쓰고(실행된 스크립트가 세션 시작 상태와 바이트 단위로 동일, 같은
세션의 편집 반영 0), `Workflow({scriptPath})`는 디스크에서 실시간으로
읽는다(세션 시작 후 새로 만든 스크립트가 실행되고 편집도 반영됨).
**워크플로 정의를 고쳤으면 재시작 말고 `scriptPath`로 부를 것.** 처음엔 이걸
"정의 파일 전반이 스냅샷"으로 일반화해 적었다가 `scriptPath` 미검증을
지적받고 좁힘 — 에이전트 정의 쪽 stale 정황은 자기 보고뿐이라 근거 등급이
낮고, 우회 수단이 없어 재시작이 보수적 해법. 전 세션 감사가
남긴 "Grep/Glob 미지급"은 **두 소스가 어긋나는 미해결 불일치**로 정리(호출
세션이 보는 등록 목록엔 포함돼 있는데 실행된 에이전트는 자기 도구에 없다고
보고) — 어느 쪽도 확정하지 말고 재시작 직후 실행에서 볼 것. 전 세션이
"존재하지 않는 원칙 인용" 3건으로 넘긴 것은 재분류돼 **2건이 인용 대상
오류**로 판명(`v1-compat-plan.md`→`component-composition-plan.md`+
`store-plan.md`, `pre-implementation-audit.md`→`ROADMAP.md`), 진짜 출처 없는
1건(`modifier-plan.md:536`)만 `question.md` 3번으로 올려 사용자 판단 대기.
`quad-handover-audit` 첫 실동은 에이전트 67개/6라운드에 **수렴 실패**(새 발견
28→15→16→7→11→6, 라운드5에서 되레 증가) — 단조 감소 전제와 `MAX_ROUNDS`
재검토 필요. **마지막 라운드의 발견 6건은 반영만 되고 재감사되지 않은 채
커밋됨**(diff는 손으로 검토·핵심 주장은 1차 근거 확인) — 다음 실동의 첫
임무. 수정 품질 자체는 높았음: `slot-plan.md`의 정정 배너가 그 뒤
재역전된 걸 놓치고 있던 것, `spikes 44개`(실제 48개) 류 하드코딩 개수의
단일 소스화, `doc-check.py` docstring이 검사 심각도를 실제 코드와 다르게
서술하던 것 등을 잡음. 워크플로도 개선 — 반환값에 `findings` 추가(커밋 전
diff 리뷰 근거), `totalFindingsFixed`→`findingsSentToFix` 개명(과대계상),
반영 에이전트 `model: 'sonnet'` 명시.

**[같은 세션 후반, 사용자 결정 2건]** (1) **감사 루프 구조 재설계** — 첫
실동이 에이전트 67개·4.6M 토큰을 쓰고도 수렴 못 한 걸 보고 사용자가
"토큰이 미친듯이 갈린다 / 감사 두 개, 끝나면 한 명이 일괄처리 / 마치
code-review 처럼"으로 구조 자체를 바꾸기로 함. 폐기 근거 셋: 토큰 과다,
파일별 픽스 에이전트가 **또 부정확한 서술을 생산**하고 파일 충돌 회피에
처리 낭비, 서브에이전트는 **사용자에게 못 물어서** 판단 항목이 임의 처리됨.
메커니즘은 사용자가 Agent 직접 호출을 선택 →
`.claude/workflows/quad-handover-audit.js` **삭제**, 절차는 `conventions.md`
"작업 방식"이 소스(감사 2개 병렬 → 메인이 일괄 검토·수정 → 애매하면 즉시
사용자 보고 → 새 발견 없는 라운드 2연속까지 반복, 수렴 못 하면 보고하고
멈춤). 감사 에이전트 출력 형식에 **`사용자 판단`** 등급 추가. (2) **출처
없던 원칙을 명문화** — `modifier-plan.md`가 인용해온 "드문 오용/가상 미래
요구까지 방어/최적화하려고 구조를 복잡하게 만들지 않는다"를 (a)안으로
`conventions.md`에 "설계 원칙" 절 신설해 정식화. 사용자 추정("내가 세션 중
했던 말을 옮겨적지 않은 경우로 보이기도 함")에서 파생돼 **"사용자 발언을
인용할 때는 결론만 적지 말고 논거까지 남긴다"는 새 관례**도 같이 신설됨.

**[같은 세션, 재정정]** 위 "워크플로 정의 해석" 결론은 새 절차의 첫 감사
라운드가 더 정밀하게 갈아치웠다 — **정의 파일은 워킹트리가 아니라 커밋된
HEAD에서 읽힌다**(감사 패스가 받은 지시문이 *세션 도중 만든* HEAD 커밋의
blob과 바이트 단위로 동일, 메인이 `git rev-parse`로 독립 확인). 즉 규칙이
"재시작"에서 **"고쳤으면 커밋한 뒤 돌린다"**로 싸짐. 이 정정이 오래
미확정이던 (d)도 같이 풀었음 — **`memory: project`가 Write/Edit을
딸려온다는 진단이 맞았고**, "빼도 그대로"로 보였던 건 그 제거가 아직 커밋
안 됐던 탓. 남은 미해결은 `tools:` 필드 미반영뿐(적힌 Grep/Glob이 안
주어지고 안 적은 `advisor`가 주어짐). 첫 감사 라운드는 그 외에 자기
메모리 2개의 stale 서술(폐기된 워크플로를 살아있는 것처럼 서술),
`documentation-content-map.md`의 "943줄, 최대 문서"(실측 203줄, 최대는
`slot-plan.md` 1970줄), `README.md`의 패스 수 하드코딩을 잡았고, 직전
커밋의 미재감사 6건은 **회귀 없음**으로 확인해 `todos.md`의 ⚠️ 블록을 닫음.

**[같은 세션, 사용자 결정]** `.claude/agent-memory/`(감사 에이전트가 스스로
쓰는 영속 메모리)를 **커밋해서 추적하기로 확정**. 사용자 논거: 개발 환경이
다수라 메모리가 레포를 따라다녀야 하고, 실 기록이지 빌드 디펜던시가 아니며,
환경 노출 위험은 `SAFETY.md`의 파이프라인(컨테이너 개발 → 프라이빗 git →
검토 후 머징)의 마지막 사람 감사가 방어선이라는 것. 커밋 전 노출 스캔은
깨끗했고, 메모리 안에 남아 있던 낡은 "캐시 가설" 서술을 커밋된 HEAD 모델로
고쳐서 넣음.

**[같은 세션, 재재정정 — 중요]** 위 "정의 파일은 커밋된 HEAD에서 읽힌다"도
**틀렸다.** 2라운드 감사자 둘이 독립적으로, 자기가 받은 정의가 **어느
커밋과도 일치하지 않는 하이브리드**(배너는 구버전, 출력 형식은 신버전)임을
보고했고 메인이 `git log -S`로 확인 — 그건 커밋된 적 없는 중간 워킹트리
상태였다. 이 세션은 같은 문제에 세 번 결론을 냈고 앞의 둘이 다 틀렸으므로
**세 번째 가설을 세우지 않고 관측표만 남김**(`agents/quad-doc-auditor.md`
상단 배너가 소스). 남는 실무 규칙은 하나 — **정의를 고쳐도 반영됐다고
가정하지 말고, 중요하면 마커 문구를 넣어 감사자에게 물어 확인할 것**(이
반증이 그 방법으로 나왔음). `memory: project`→Write/Edit 결론은 제거 이후
후보 텍스트가 전부 그 옵션을 안 가져서 영향 없이 유지되고, 미해결은
`tools:` 미반영뿐. 감사자 모델은 다섯 실행 전부 sonnet으로 재확인했고,
실행마다 `message.usage.iterations[]`에 opus 항목이 딱 1개씩 붙는 게
"감사자가 opus"로 보이는 원인.

**[같은 세션, 해소]** "감사자가 opus로 돈다"는 반복 관측은 **뷰잉 이슈**로
판명 — 서브에이전트 뷰 최상단에 보이는 `Opus 5 · Claude Max`는 Claude Code
**세션 헤더**(메인 모델)이지 서브에이전트 모델이 아니다(사용자가 화면 직접
확인). 감사자는 다섯 실행 전부 sonnet이고 frontmatter `model: sonnet`은
정상 동작. 모델을 잘못 읽을 자리가 셋이었음 — (1) `"model"` 문자열 grep이
`message.usage.iterations[]`의 opus 항목에 낚임, (2) 화면 최상단 세션 헤더,
(3) 폐기된 워크플로의 픽스 에이전트 49개는 실제로 opus였던 것. 신뢰할
소스는 트랜스크립트 최상위 `message.model` 하나.

**[같은 세션, 감사 3·4라운드]** 3라운드는 `agent-memory/`가 재재정정을 안
따라온 걸 두 감사자가 독립으로 잡음(정정 커밋이 그 폴더를 안 건드림 —
"변경한 세션은 자기가 뭘 안 건드렸는지 모른다"의 교과서적 사례, 게다가 같은
파일이 한 세션에 두 번 연속 stale). 고치면서 그 메모리가 결론을 복제하지
않고 정의 배너를 **가리키기만** 하도록 바꿔 근본 원인을 제거. 4라운드는
코퍼스 확실 발견 0건이고 대신 (1) `todos.md`의 개수 하드코딩 2건(이 세션과
무관한 기존 항목), (2) `base/architecture.md`의 `const` 미채택 사유에 날짜
없음을 잡음. 4라운드 부수 실측 둘 — 에이전트 정의는 이번엔 HEAD보다 1커밋
전이었고(뒤처지는 폭이 실행마다 다름), **`CLAUDE.md` `@import` 컨텍스트는
세션 시작 시점에 고정**됨을 확인(메인 세션도 옛 `conventions.md`/`todos.md`를
들고 있었음). 후자는 동작이 명확해서 `conventions.md`에 규칙으로 명시 —
**`@import` 파일을 고친 세션은 파일을 직접 `Read`해서 따를 것.**
`const` 건은 사용자가 전제를 정정 — pesde의 types emit 같은 툴링 체인 지원
시점은 에이전트가 관측할 수 없으므로 `HUMAN_TODO.md` 8번(사용자가 파악하거나
가능해질 때 알림)으로 이관.

## 2026-08-16 세 번째 세션 — 표기 컨벤션으로 doc-check 정규식 줄이기

원문: [`session/2026-08-16-03-doc-check-section-convention.md`](session/2026-08-16-03-doc-check-section-convention.md)

사용자 제기 — `doc-check.py`가 정규식으로 결정론적 판정을 하는데 표기가
흔들리면 문제가 커지니, 정규식을 늘리기보다 "예상 가능 범위"를 컨벤션으로
좁히는 게 싸지 않냐. **실측 결과 날짜 표기는 이미 문제가 아니었다** —
`20NN-NN-NN` 1864건 중 1864건이 균일(강제 장치 없이). 드리프트는 다른 데
있었고, WARN 86건 중 **절 참조 불일치가 78건(91%)**이었다.

**핵심 발견: 78건은 코퍼스가 지저분한 게 아니라 검사기가 못 읽는 것이었다.**
이 코퍼스는 `**볼드**` 선두 줄을 하위 절로 쓰는데 `headings()`가 `#`만
수집했다. 다만 볼드를 통째로 인정하면 검사가 장식이 된다(볼드는 `#` 헤딩보다
압도적으로 흔함 — 수치는 세션 원문). 여러 규칙을 실측 대조해 **`#` 헤딩은
부분문자열, 볼드 절은 빈 줄/리스트 머리 + 앞부분일치**라는 비대칭 규칙 채택 —
느슨한 규칙과 해소 건수가 같으면서 매칭 표면만 좁다. 부수로 인용 길이 상한
60→160자(넘으면 검사에서 **조용히** 빠져나갔음), 공백 무시 비교(줄바꿈 인용
대응), 선두 상태·날짜 태그 정규화, `initreq/` 대상 면제.

**결과: 절 참조 불일치 78 → 0.** 36건은 검사기 수정으로 사라졌고(애초에
위양성이었다는 뜻), 42건은 인용을 실제 절 제목으로 손으로 고쳤다 — 라운드별
내역은 세션 원문이 소스. 마지막 15건은 서브에이전트 3개에 병렬
위임해 추적했고 — **설계 서술이 유실된 건은 0건**, 대부분 "애초에 절이
아닌 것(코드 주석·본문 문장·의역)을 절로 인용해온 것"이었다. 부수로
`onchange-plan.md`가 9차 분할 때 일부러 안 옮긴 절을 잘못된 파일로 가리키던
것, `brand-plan.md`가 이미 이행된 정정을 "정정 대상"이라 부르던 것이 드러나
같이 고침.

**커밋 전 감사가 이 세션 자신의 실수를 하나 잡았다** —
`pre-implementation-audit.md`의 "아직 안 고침" 절에 있는
`State<Modifier>` 항목이 해소된 것 같아 해소 마커를 달았는데, 바로 아래
문단에 **2026-08-09 세션이 단 `[완전 해소]` 마커가 이미 있었다.** 중복인
데다 해소 시점을 2026-08-16으로 잘못 읽히게 만들어 되돌림. 이 항목이
해소 표시를 달고도 "아직 안 고침" 헤더 아래 남아 있는 것은 이 세션 이전부터
있던 별개 부채라 사용자에게 보고했고, **사용자 결정으로 "이미 고침" 절로
옮김** — 그 헤더 아래엔 이제 진짜 미해소인 `Destroying` 훅 건만 남는다.

사용자 결정 셋 — (1) 절 인용 규약 + 세션 파일 ID 지칭 채택, (2) 날짜 마커
라벨 어휘 닫기는 **기각**("에이전트가 순서 섞였을 때 최신의, 옳은 요소 선택에
도움이 되는 정보에 가깝지 이게 warn을 만들지는 못할듯" — 기계 검사 대상이
아니라 읽는 쪽 판단 재료), (3) (C) 추적은 컨텍스트 보호를 위해 서브에이전트
위임. `conventions.md`에 "문서 표기 규약" 절 신설.

## 2026-08-18 — 구현 전 QA 결과를 `base/`에 일괄 반영

원문: `session/2026-08-18-01-pre-implementation-qa-applied.md`

`.claude/qa-request/pre-implementation-qa-round1.md`(사용자가 `base/` 확정 문서를 문항으로
재심사해 "아니오"가 나온 것만 모아둔 문서)를 실제 문서에 반영. **그대로
구현하면 반대로 돌던 두 건**이 닫혔다 — `canBound`가 이름과 반대 방향으로
쓰이고 있어 정상 첫 바인드가 전부 에러날 뻔한 것(정정 결과 `canBound`와
`canExecute`는 값이 같은 게 아니라 **서로의 부정**이고, 그게 오히려 이름
분리의 명분이 됨), 그리고 gcconn/gchold를 `SetStrong`으로 적어 같은 문서가
경고하는 두-`Relate` 상호 강참조 누수에 정확히 걸리던 것.

설계가 바뀐 것: `Dispatch.drive`의 `None` 스킵 폐기 → `NoneHandler`는 재귀
전담 + **`NilHandler` 신설**(깨진 전제는 "배열 파트의 `None`은 `process`를
안 탄다" — `Frame{State<Slot|None>}`이면 탄다), 이벤트 disconnect 센티널
`false`→`None`/`nil`, `Ref` 내부 구조를 `.Callbacks` 분리로 단순화,
`:List` reconcile의 `nil` 리턴을 **다시 파괴**로 되돌리고 `PopOnly`(가칭)
신설, base Fallback Handler 등록 주체를 **quad-base 로드 시로 재역전**
(백엔드 미로드 상태에서 안내 에러 경로가 안 도는 게 이유 — `InitNamespace`
거부 원칙과의 양립 근거를 새로 씀). **"이벤트 콜백 시그니처는 Luau가 검증
못 한다"가 거짓**임이 사용자 반례로 확인돼 `onchange-plan.md`가 그걸 근거로
쓰던 자리까지 같이 무너졌고(결론은 유지, 근거만 교체), 겸해서 `New` 커링과
"`D`는 전량 코드 생성된 순수 별칭 테이블"이 명문화됨.

이름 쪽: **`DI` → `D`(Declarative) 확정**(2026-08-08부터 1순위로 열려 있던
항목) — 코퍼스 전수 반영, 미뤄온 유일한 사유였던 한 글자 식별자의 검색성은
"처음 나올 때 항상 `D`(Declarative)로 풀어쓴다" 표기 규약으로 보완.
`Attribute.Merged`/`Overridden`을 **둘 다 제공**하는 제3안으로 이름 겹침
정책도 해소.

판단이 갈리던 네 건(`PopOnly` 채택, D-7 재역전, `NoneHandler`/`NilHandler`
역할 분담, 동적 키 `GetDynamic`)은 그 자리에서 사용자에게 물어 확정.
남은 착수 금지 게이트(중간 State GC 미검증 등)는 `question.md` 3번과
`todos.md` 00번이 소스. `doc-check.py` ERROR 0.

**커밋 전 검증에서 배운 것**: `quad-doc-auditor` 1패스가 "배너는 고쳤는데
그 배너가 부정하는 본문 bullet은 안 고친" 건을 하나 잡았고, 이어서 사용자가
직접 돌린 `/code-review high`가 **10건을 더** 잡았다(전부 유효, 전부 반영) —
감사자가 못 본 것들이라 **두 도구가 서로를 대체하지 않는다는 게 실측으로
드러났다**(감사자는 코퍼스 전체 정합성, code-review는 diff 자체의 결함).
그중엔 ROADMAP이 SL-3 역전을 안 따라와 M8 체크리스트대로 짜면 방금 되돌린
결함을 다시 만드는 건, 그리고 **설계 갭 2건**(`GetDynamic` 콜론 메소드가
Store의 lazy `__index`와 충돌 / `PopOnly` 홀드 중 키가 사라지면 파괴도 반환도
안 됨)이 있어 새 열린 질문으로 올렸다. **감사 비용 메모**: 감사자 한 패스가
서브에이전트 토큰 21만이라(코퍼스 전체를 다시 읽는 정의라서) 계획했던 4패스를
중단했음. **그래서 사용자 지침으로 감사 절차 자체를 바꿨다** — 병렬 금지(한
턴에 하나), 범위는 diff로 좁히고 라운드마다 각도를 바꿈, 종료 조건은 무발견
1회(옛 "2연속"은 병렬 전제라 완화). `conventions.md`의 감사 루프 절이 소스.

## 2026-08-19 — `New()` 내부 구성(InitXxx + Relate 멱등 가드) 확정, 세션 기록 공백 발견

원문: `session/2026-08-19-01-new-initxxx-composition-relate-guard.md`

사용자가 `New()`를 v1 스타일 `InitXxx(module)` 팩토리 체이닝으로 짜자고
제안(이미 확정된 `InitRoblox(Module)` backend 주입 패턴을 quad-base 자기
내부에도 대칭 적용) → 채택, `module-lifecycle-plan.md`에 "New()의 내부
구성" 절 신설. 이어서 서브시스템 간 호출 순서 문제를 "Init을 `require`처럼
멱등하게"(각 `InitXxx` 파일 톱레벨에 `Relate()` 하나 두고 `module`을 weak
key로 완료 여부 기록) 방식으로 직접 해소하는 아이디어도 제안·반영 —
`relate-plan.md`의 기존 확정 API/관례와 정확히 부합함을 확인. 핸드오버
감사 2라운드를 거치며 라운드 1의 수정 자체가 절 인용 사각지대를 새로
만든 걸 라운드 2가 잡는 등 실제로 반복 라운드가 필요함을 다시 확인.

**부수 발견 — session/ 기록 공백**: 2026-08-18에 커밋 10개(QA 1~2라운드
포함)가 있었는데 그날 session/ 파일은 1개뿐, 2026-08-19는 이 세션 전까지
(QA 3라운드 커밋 1개가 있었음에도) 0개였음. 과거 대화 트랜스크립트에 접근 불가라 그 공백을 사후 재구성하는 건
허위 기록 위험이 있어 보류 — 처리 방침은 사용자 확인 대기.

## 2026-08-19 — `PopOnly` → `Detach` 리네임 + 공개 표면 위치 확정

원문: `session/2026-08-19-02-detach-naming-and-placement.md`

가칭으로 남아있던 `:List` reconcile의 비파괴 반환 sentinel `PopOnly`의
이름을 사용자 요청으로 브레인스토밍(풀링/보관 은유 계열, "언마운트+보류"
계열, 기존 조어 구조 계열 후보 제시) → 사용자가 이미 있는 `Extract`(명령형
추출)와 동사가 안 겹치면서 "화면에서만 떼고 관리 주체는 그대로"라는 뜻을
살릴 수 있다는 이유로 `Detach`를 골라 확정. 이어서 공개 표면 위치("Slot이
함수라 `Slot.Detach`로 못 붙임")도 논의 — `None` sentinel의 선례(공개
표면은 패키지 최상위 export, 실제 정의는 관련 로직 옆)를 그대로 따르기로
확정. `base/slot-plan.md`/`question.md`/`todos.md`/
`archive/question-resolved.md`/`ROADMAP.md` 전량 반영, `doc-check.py`
ERROR 0.

## 2026-08-19 — `Debounce`/`Throttle` 마지막 판단 대기 4개 닫음, `base/`로 승격

원문: `session/2026-08-19-03-debounce-throttle-final-close.md`

`research/debounce-throttle-plan.md` 12절에 남아있던 이름/의미론/제어
핸들/`Time=0`을 리뷰 — 이름은 유지+문서 경고로 사용자가 먼저 확정, 나머지
셋은 논의를 거쳐 (A) emit-gate 채택(값-지연 (B)는 laziness와 상충해
철회), 제어 핸들은 개별 `Ref` 아웃파라미터+전체 팩토리 브로드캐스트(weak
레지스트리)로 수렴, `Time=0`은 허용으로 확정. 부수로 `Time`/`MaxTime`을
`number|State<number>`로 확장(스케줄 시점에만 폴링, 구독 아님)도 결정.
전부 닫히면서 문서가 `research/`에서 `base/`로 승격됐고, 제어 핸들 설계가
`Blocker`의 gated state + `Ref` + 주입 op 2개 위에 전부 얹힌다는 게
드러나 **순수 슈가로 재평가**(옛 "실제 기능 갭이라 우선순위 위" 서술
철회). `ROADMAP.md`/`question.md`/`todos.md`/`README.md`/
`source-state-plan.md`/`blocker-plan.md` 전량 반영.

## 2026-08-19 — M0/M1 스캐폴딩 첫 시도, wally→pesde 전환, `@self` require 함정

원문: `session/2026-08-19-04-pesde-migration-and-project-setup.md`

`ROADMAP.md` M0(스파이크 3종)/M1(스캐폴딩)을 revert 가능한 상태로 실제로
짜보는 시도 — `quad-base/`/`quad-roblox/` 폴더, `Relate.luau` 전량 구현,
`Debug/init.luau` + 최상위 `init.luau`, mock+스모크 테스트까지 작성. 그
과정에서 크로스파일 require가 전부 깨지는 진짜 버그를 찾았으나 원인
진단은 처음에 틀렸음(CWD 기준설로 오판) — 사용자가 Luau RFC를 근거로
`init.luau`는 `@self/X`가 필요한 특수 케이스라고 직접 정정. 이어서 사용자
결정으로 패키지 매니저를 wally에서 pesde로 전환, tbox 참고 후 실제 설치해
워크스페이스 전체를 검증. 산출물은 `base/project-setup-plan.md`(신설)와
`architecture.md`의 "패키징 방식" 절 정정.

**커밋 후 후속(같은 세션, §5)**: 사용자가 "전부 차근차근"이라고 답해 이어서
4가지 진행 — Rojo를 직접 설치해 `rojo sourcemap`/`rojo build`가 워크스페이스
symlink를 투명하게 따라감을 확인(Luau standalone CLI 전용 문제였음을
재확인, Studio 실물 검증만 계정 분리 대기로 남음), 스파이크 `13`을
타입 전용/런타임(`22` 신규) 두 파일로 분리해 `PreRef`/`PostRef` 배타성까지
검증, `luau-lsp`를 직접 설치해 새 Luau 솔버 필요성을 재귀 제네릭 스파이크로
재확인하고 `.vscode/settings.json`에 반영, 스파이크 `05`/`21` STATUS.md
텍스트 갱신.

## 2026-08-19 — rokit→mise 전환, selene 린터 도입, darklua 검토 후 기각

원문: `session/2026-08-19-05-mise-migration-and-selene-linter.md`

사용자가 참고 GitHub 레포 `Word30210/roblox-project-example`의
`mise.toml`을 제시("요즘은 rokit보단 mise로 까는듯") → 클론해 구조 전체를
훑고 mise 전환/selene 린터/darklua/Justfile 네 후보를 멀티셀렉트로 제시,
사용자는 mise 전환과 selene만 채택. darklua는 사용자가 직접 반박해 보류
— "Roblox 엔진 자체가 이미 `@self`/`@game` string require를 지원하므로
변환 계층이 불필요"라는 논거. mise 전환은 GitHub artifact attestation +
SLSA provenance 검증까지 거쳐 실제 설치·검증 완료.

## 2026-08-19 — `RunInit` 재설계, darklua 경계 정밀화, 한국어 진행 합의

원문: `session/2026-08-19-06-runinit-redesign-and-darklua-precision.md`

사용자 요청 두 가지: (1) darklua 기각 근거를 실측으로 정밀화 — 직접
설치해 돌려보니 `@self`/`@game`은 안 건드리고 커스텀 `.luaurc` alias만
변환한다는 정확한 경계 확인(지금은 불필요하지만 나중에 축약 alias를 쓰면
필요해질 수 있음을 `project-setup-plan.md`에 반영). (2) `New()`의 멱등
Init 가드를 파일마다 `Relate`+센티널을 두는 대신 **함수 자체를 릴레이션
키로 쓰는 공유 `module:RunInit(initFn)`**로 재설계 — 실제 구현+3개
시나리오 스모크 테스트까지 완료. 이후 대화를 한국어로 진행하기로 합의.

## 2026-08-19 — `quad-types` 패키지 신설, `AddPlugin`/`CheckedQuad` 실측 설계

원문: `session/2026-08-19-07-quad-types-package-addplugin-checkversion.md`

`RunInit` vs backend 유일 슬롯 가드를 `_initializedBy`로 분리 확정한 뒤,
사용자가 "quad-roblox가 quad-base를 런타임 주입으로만 받으면
dev-dependency로도 타입이 못 산다"는 문제를 제기 — 실측으로 확인하고
`quad-types`(구현 없는 타입 계약 전용 워크스페이스 패키지)를 신설,
`AddPlugin<Self,P>` 플러그인 체이닝과 `CheckedQuad<T>` 컴파일 타임
버전 체크를 설계·구현·검증까지 전부 마침. 과정에서 "값이 한 번이라도
`type function`을 거치면 이후 제네릭 self 체이닝이 조용히 깨진다"는 새
Luau 함정을 발견해 `typing-limits.md` §6으로 승격.

## 2026-08-19 — `type-version-check` 패키지 추출, `CheckedQuad<T, Pattern>` 확장

원문: `session/2026-08-19-08-type-version-check-package-extraction.md`

직전 세션의 `CheckedQuad<T>`(정확 버전 일치만)가 `quad-spring`/
`quad-spring-roblox`류 독립 게시 플러그인엔 너무 빡빡하다는 사용자 지적
→ 글롭(`"*"`)/캐럿(`"N^"`) 패턴을 지원하는 `CheckedQuad<T, Pattern>`으로
확장. 버전 매칭 로직 자체는 quad에 종속되지 않은 범용 워크스페이스 멤버
`type-version-check`로 분리(사용자 지시: 지금은 모노레포 안에 두고 독립
저장소 분리는 나중에 직접 — `HUMAN_TODO.md` 9번). 새 Luau 함정 2건 발견
(`type function`은 outer local 참조 불가, cross-package엔 `export type
function` + 이중 꺾쇠 제네릭 인스턴스화 필요). 핸드오버 감사 2라운드로
구 시그니처 잔존/개수 하드코딩 8건 발견·수정 후 커밋.

## 2026-08-19 — 구현 전 QA 4라운드 문항지 작성 (회신 대기)

원문: `session/2026-08-19-04-qa-round4-questionnaire.md`

사용자 요청("모든 확정 부분에 있어서 예가 되어야하는 질문들을 계속 …
서브에이전트는 쓰지 말아줘")으로 `base/` 확정 주장 전체를 한 맥락에서 읽으며
"예가 나와야 정상인 문항"으로 전수 문항화. **설계 결정도 정정도 하나도 안
내리고** 문항지(`qa-request/pre-implementation-qa-round4.md`)만 남긴 채 회신
대기로 끝난 세션.

## 2026-08-19 — 핸드오버 준비, `session-summary.md`/`ROADMAP.md` stale 대청소

원문: `session/2026-08-19-09-handover-prep-roadmap-status-sync.md`

`quad-roblox-types` 언급 확인 요청에서 시작했으나 훨씬 큰 공백 둘을 발견 —
이 색인에 당일 세션 5개(04~08)가 통째로 빠져 있었고,
`CLAUDE.md`/`project-context.md`/`ROADMAP.md`가 "구현 아직 시작 전"이라는
낡은 전제를 깔고 있었다(실제로는 M0/M1이 이미 완료·커밋됨). 둘 다 즉시
반영하고 감사 라운드로 재검증.

## 2026-08-20 — QA 4라운드 회신 1차 처리 + 업스트림 스캐폴딩 병합

원문: `session/2026-08-20-01-qa-round4-response-processing.md`

업스트림 12커밋(pesde 전환, mise/selene, RunInit 재설계, quad-types/
type-version-check 신설, M0 스파이크)을 먼저 rebase로 병합한 뒤, 사용자
회신을 (a) 바로 반영 / (b) 설명 보강 후 재질문 / (c) 사용자 판단 필요 /
(d) 조사해서 답이 나옴으로 갈라 (a)만 `base/`에 반영. 나머지는
`pre-implementation-qa-round4-followup.md`로 정리해 남김.

## 2026-08-21 — `Detach` 보존 주체/`KeyGone`/`Owned` 확정, `attachSlot` 분해

원문: `session/2026-08-21-01-detach-keygone-owned-and-attachslot-decomposition.md`

QA 4라운드의 마지막 열린 항목이 닫힌 세션. gcconn 트릭 때문에 detach된
quad-제작 Instance는 **GC 폴백이 없다**는 걸 근거로 보존 주체를
`userdata` → **`slot._detached` 필드**로 뒤집고, 키 소멸 처분을 **`KeyGone`
센티널**로 확정(재-`Detach`는 nop, `prev` 반환은 재마운트). `Detach`(사이클
단위)와 **`Owned`**(설치 단위)를 직교 축으로 분리해 `state<Frame>` 의미론
충돌도 해소. 같이 **`attachSlot`을 `materializeSlotTree`+`mountSlotTree`로
분해** — "부모에게 미는 길이는 최종값"과 "부기가 물리보다 먼저"가 한 함수
안에선 동시 만족 불가라는 진단이 근거였고, 사용자가 "지금 의사코드를
건들이는 비용이 추후 실수가 누적되는 비용보다 싸다"로 확정.

## 2026-08-21-02 — QA 5라운드 전량 처리 + `Gate` 표면·State 에포크 확정, `Epoch`/`Brand` 제안

원문: `session/2026-08-21-02-qa-round5-and-gate-epoch-research.md`

4라운드 종결 때 "안 만든다"고 했던 5라운드를 사용자 요청으로 신설 —
**4라운드에 문항이 없던 영역**(`project-setup-plan.md`/`quad-types-plan.md`,
그리고 문서가 아닌 **실제 커밋된 M1 코드**), **그 이후 확정된 것**
(`Detach`/`KeyGone`/`Owned`/`attachSlot` 분해), **큰 문서의 심화**로 범위를
좁힌 205문항. 같은 세션에 회신까지 받아 14건 즉시 반영 — `slot._detached`
lazy화, `KeyGone`엔 새 값 반환도 error, **`Owned=false`에서 `Detach`는
`_detached`에 안 들어감**, 조상 파괴 시 unowned도 같이 죽는다는 계약 신설,
`groupClaimKeys` 키 확정, `Tween<T>:Mapped` 확정, 4라운드가 빠뜨렸던 `E-10`
실반영, **"게이팅 먼저"(M2로 앞당김)**. 새로 열린 두 갈래는 `research/`로 —
공용 **`Gate`** 노드(emit을 가로채는 정책 노드, `Blocker`/`Debounce`가 그 위)와
**State 에포크 검증**(DFS 전파 중 `Get()`이 섞인 값을 캐시하는 glitch를
정확성 문제로 다룸). **2차 회신으로 되물은 6건도 같은 세션에 전부 확정** —
`Slot:Replace` 신설(교체가 시프트 2회 → 0회), 물리 조작을 주입 op로
(`mountInst`/`unmountInst`, base는 `Parent`를 모른다), `rawAdd` 의사코드 신설,
`rawAdd`의 `Length:Set` 제거, **래핑/언래핑 한 쌍**(`wrapElement`/`unwrapElement`),
**`setLength`에 `anchor` 인자**(4라운드 `D-56` 역전 → `isBoundAlive` 세 번째
분기 항목까지 닫힘), `Effect(fn, ...deps)`(`Ref`도 의존성). **3·4차에선 `mountInst`가 삽입 위치를 못 받는다는 지적에서
시작해 offset 부기 모델이 정리됨** — `None`의 뜻을 "발행 채널 없음"으로 좁히고
`Dispatch.getOffsetAt` 신설(pull), 그 과정에 **중첩 offset이 부모 베이스를 못
받던 결함**(depth ≥ 2에서 통째로 밀림)과 **재마운트가 `Offset` Source를 새로
만들던 결함**(포탈이 깨지는 자리)까지 발견·수정. **커밋 전 감사 2라운드가 또 실질적인 걸 잡았다** — 확정한 `Owned`가
`Slot:List` 시그니처에 배선이 안 돼 코드에 도달 못 하던 것, `effect-plan.md`가
역전 배너 없이 자기모순이던 것, 그리고 **손대지 않은 문서**(`ROADMAP` 백로그
문단·`debounce-throttle-plan.md`)가 "Gate는 M3에서"로 남아 있던 사각지대.
감사 회신 자리에서 **`raw*`의 index 통일**(오래 열린 캐비엇 종결), **래핑은
`raw*` 바깥**, **`getOffsetAt` 접두합 캐시**까지 확정. 마지막 라운드에선 **`native*` 물리 조작 계층**(Slot 스코프의 `raw*`와 갈리는,
확정된 offset/length 기반 여섯 op)이 확정되고 그 여파로 **4라운드 `C-7`("부기가
물리보다 먼저")이 역전**됐다 — base엔 자리를 비워둘 수단이 없고 미는 주체는
백엔드 삽입 연산 자신이라, 규칙이 "자기 자리 먼저 / 뒤를 미는 것 나중" 하나로
줄었다. **`Gate`만 사용자 지시로 다음 세션 — M2를 막는 유일한 항목.**

**같은 세션 후반 — 리서치로 신설했던 둘이 그 자리에서 확정됐다.**
`Gate`는 **탑레벨 프리미티브 없이 `state:Gate(setup)` 메소드 + `GateNode`**로,
State의 재계산/전파 판정은 **소스 에포크 비교 채택**으로 닫히며 두 문서가
`research/` → `base/`로 승격(`base/gate-plan.md`, `base/state-epoch-plan.md`).
그 여파로 `source-state-plan.md`의 확정 서술 둘("emit은 **항상** 전파 / quad가
접지 않는 것은 중복 *통지*뿐")이 역전돼
`archive/always-propagate-no-dedup-superseded.md`로 갔다 — **2026-08-14의
`invalid` 기반 dedup 금지를 되돌린 게 아니라는 것**을 세 곳에 못박았고,
스파이크 `05`는 핵심 assert가 정반대가 되어 `rewrite-required/`로 돌아갔다.

**에포크 기제는 네 라운드에 걸쳐 사용자 정정으로 다듬어졌다** — 순회 조건이
`rawInvalid == false`로 뒤집히고, emit은 count 없이 출처만 싣고, 순회가 값만
앞당기고 통지는 상류 emit을 기다리게 하려고 맵이
`sourceCountMap`/`sourceEmitMap` 둘로 갈렸다(에이전트가 한 번 철회했던 분리가
**다른 근거로** 되살아난 것). 새 노드의 두 맵은 **비대칭 초기화**
(emit 맵은 비우고, count 맵은 실제 값으로 채운 뒤 `rawInvalid = true`).
게이트는 흡수 집합을 들고 **flush 시 스왑**해 배치를 떼어 넘기며, 게이트가
게이트 emit을 받으면 **풀어서 자기 집합에 합치고**, **빈 배치면 통지 자체를
안 한다**(기존 `HasBlockedEmit` 계약의 일반화). 그 따름정리로
`Effect`의 설치 구간 억제가 `Gate` 소비자에서 빠졌다.

**`/code-review high`를 두 번 돌려 19건이 나왔고 전부 유효했다** — 그중
재진입 시 빈 배치가 새던 것과 `OffWithoutEmit`이 흡수 집합을 안 비우던 것은
실제 유실 경로였다. 반대로 리뷰가 제기한 것 중 **에이전트 서술 자체가
틀렸던 것도 셋** — "Gate 재진입 계약"은 `Blocker`의 인스턴스 중첩 규칙을
잘못 옮긴 것이었고, "다중 소스 배치의 중복 계산"은 동기 전파를 놓친 것이었고,
"빈 배치 = 무조건 통지" 권고는 State 층에 `Source:Emit`을 추가하는 격이라
기각됐다.

**마지막으로 사용자가 `Epoch`/`EpochMap`/`Brand` 재구성을 제안**했다 — 에포크
부기를 State에서 떼어 컴포지션하고, emit 페이로드를 `Epoch` 인터페이스
(`{Revision: number}`, 그 자체로 키)로 일반화하고, 그러려면 `Brand`를
**인스턴스 브랜드**(다중 태깅)로 바꾸는 안. 발단은 **다중 의존성 `Effect`에서
한 파동에 `fn`이 두 번 도는 갭**(공통 하류가 없어 에포크 dedup이 못 접는다)이고,
`Effect`가 자기 `EpochMap`을 들면 그게 공통 하류가 되어 닫힌다. **사실상 전량
확정됐으나 세션 길이 때문에 `base/` 승격은 다음 세션으로 미뤄졌다** —
`reference/epoch-brand-composition.md`가 소스, `todos.md` 000번이 진입점.

---

## 2026-08-21 (세 번째) — `Epoch`/`EpochMap`/`Brand` 전면 승격, 그리고 해소 기록 flatten

원문: `session/2026-08-21-03-epoch-brand-promotion-and-flatten.md`

앞 세션이 미뤄둔 승격을 실제로 수행했다. **`Epoch`**(`{Revision: number}`,
그 자체로 키가 되는 unique 테이블 — `Source`가 구조적으로 만족하고
`EpochBrand`에도 등록됨)와 **`EpochMap`**(`:Update(Epoch|{Epoch}) -> boolean`이
"뒤로 전파가 필요한가"를 답함, `:Refresh`/`:Sync`)이 `base/`에 들어갔고,
State는 그걸 **둘** 컴포지션한다(`sourceCountMap`/`sourceEmitMap` →
`valueEpochMap`/`emitEpochMap`). **`Brand`는 인스턴스 브랜드로 전면
재작성**됐다 — `Brand()` + `:register`/`:is`, **다중 태깅 허용**, 역조회
`Brand.get`은 제거(옛 표면은 `archive/brand-shared-registry-reversed.md`).
그 부수로 **`effect-plan.md`의 다중 의존성 중복 발화 미해결 항목이
닫혔다**(`EffectHandle`이 자기 `EpochMap`을 들어 첫 번째만 통과시킴).
**마지막 미정이던 리비전 갱신 방식도 같은 세션에 `bit32.bnot(-rev)`로
확정**됐다 — 사용자 논거는 *"2^53 포화는 어차피 도달 불가능한데 그걸
피하겠다고 값을 double 영역까지 키울 이유가 없다, 매번 도는 코드라 값싸게
가고 싶다"*. **에이전트가 이 형태를 `band(rev + 1, mask)`로 잘못 옮기고
"그러니 `bit32`가 더 싼 건 아니다"라는 단서까지 붙였다가 사용자에게
정정당했다**(*"제가 말한건, bit32.bnot(-a) 입니다"*) — 사용자가 근거로 든
REPL 출력 셋이 예시가 아니라 **연산 자체**였다. `luau` 실측 결과
`bit32.bnot(-a)`는 `a > 0`이면 `a - 1`, `0`이면 `4294967295`인 **랩어라운드
감소**이고 갱신과 랩이 **FASTCALL 하나**로 끝난다. 즉 사용자 서술이 맞았고
에이전트 단서가 틀렸다. 따름정리로 리비전은 **증가가 아니라 감소**하며,
`==`/`~=`만 쓰는 지금 규칙에서만 무해하다는 경고를 `base/`에 남겼다.
**`Epoch`/`EpochMap`/`Brand`에 열린 설계 항목은 없다.**

커밋 전 `/code-review high`가 **9건을 더 냈고 전부 유효**했다(감사자 3라운드가
수렴한 뒤였다 — 둘이 보는 축이 다르다는 `conventions.md` 서술의 재확인).
치명적인 둘은 **표기가 실제 메커니즘과 안 맞던 것**이다: (1) `{Epoch}`가
Luau에선 **배열**인데 실제 게이트 배치는 `{[Epoch]: true}` **집합**이라, 그대로
`ipairs`로 구현하면 유보됐다 풀린 emit이 전부 삼켜진다 → `EpochSet`으로 확정,
(2) 새 노드 시딩("상류의 `Epoch`를 전부 끌어와")이 **확정된 `EpochMap` 표면으로
표현 불가능**했다(`:With`의 상류는 State이지 `Epoch`가 아니고, 키 열거/병합
연산이 없었음) → `:TrackFrom` 신설. 그 외 `GateNode` 예외 미기록, 설치 발화의
`from`이 non-optional, `2^32` 랩을 "똑같이 도달 불가능"이라 한 **틀린 수치
근거**(같은 척도로 285년 vs 72분 — 실제 안전 근거는 도달 시간이 아니라 충돌
조건이 한 점이라는 것), 옛 이름 잔재(`TweenTag` 3곳/`Effect(fn, state?)` 4곳),
`§` 참조 3곳.

**에이전트가 이름 붙인 연산 둘은 사용자 검토로 확정**됐다 — `:Refresh`는 그대로
(*"Update 에 인자 없는건 좀 아니야 … 리프레시는 내가 받았던걸 처리하겠다는거라
표면적 의미 자체가 다르지"*), `:Absorb`는 **`:TrackFrom`으로 개명**
(*"absorb 는 … 상위 요소에서 제거할것만 같은 이름"* + `gate-plan.md`가 이미
"흡수 집합"을 다른 뜻으로 씀). 이 세션의 반복 교훈은 하나 — **승격은 문장을
옮기는 작업이 아니라 표기가 가리키는 것이 실제로 성립하는지 확인하는
작업**이다(`bit32` 형태, `{Epoch}` 타입, 시딩 표현 셋 다 같은 유형이었다).

**확정된 결정의 근거 기록이 갈 자리를 정했다 — `reference/`.**
`slot-attach-decomposition.md`와 `epoch-brand-composition.md` 둘 다
`research/`(아직 상의 필요)도 `archive/`(뒤집혔거나 기각됨)도 아니라
"`base/`가 근거로 인용하는 온디맨드 자료"이므로. 폴더 기준 자체에 이 용도를
명문화했다.

**flatten** — 사용자 지적("재정정 기록이 쌓인 부분")대로 세 군데를 걷어냈다.
`question.md`가 스스로 정한 규칙(해소되면 archive로 옮김)을 어기고 다시
절반이 `[해소]`로 차 있어 **16건을 일괄 이관**(421→208줄), `todos.md`의
"M3 착수 전 필요" 목록도 절반 넘게 해소 항목이라 실제로 열린 둘만 남겼다.
이관한 히스토리의 원문은 소급해 고치지 않고 **머리에 "그 뒤 이름이 바뀌었다"
경고만** 달았다.

## 2026-08-24 — 6라운드 손 트레이싱 전량 처리·반영, 그리고 세 번의 재검토

원문: `session/2026-08-24-01-handtrace-round6-resolution.md`.
결정과 근거의 소스는 `qa-request/pre-implementation-handtrace-round6-followup.md`.

발견 `H-1`~`H-54`를 문항지로 만들지 않고 **갈래 선택이 필요한 것만 급한 순서로**
사용자에게 물어(사용자 요청: *"같이 하나하나 처리해나가보자. 질문 모드로 계속
물어보며"*) 전량 결정하고 `base/` 24개 문서에 반영했다. **M2/M3를 막던 것이
전부 닫혔다** — 말단 핸들러 4종의 `setLength`/`setOffsetSource` 미등록(`H-39`),
`New(): Quad`가 닫힌 타입이라 `quad.Dispatch`가 타입에러인 것(`H-25`),
`Effect`의 leaf 사망 cleanup 배선 부재(`H-11`), `:List`의 좌표계 결함 둘.

**구조가 바뀐 것 넷**: `slot._elemIndex`(역방향 인덱스 맵) 신설로 `keyIndex`가
단순 키 집합으로 강등 / `_mounted`가 "물리 인스턴스 유무"만 뜻하게 좁혀지고
`slot._physicalTarget` 신설(부기는 실체화 시점부터 항상) / `Ref.Callbacks`가
해시맵 셋 + `:Uncallback` / `blocker:Policy(emit)` 노출로 `Debounce`/`Throttle`이
자기 Blocker를 조종하는 정책이 됨. 요소 타입 검증은 블랙리스트에서 **주입 술어
`isInst` 기반 화이트리스트**로 뒤집혔다.

**사용자가 에이전트의 갈래를 뒤집은 자리가 여럿**이고 그게 결과를 크게 바꿨다 —
`H-1`(제 세 갈래가 전부 차선, 역방향 맵을 raw 층에 두는 역제안), `H-2`(부기와
물리 마운트를 분리하라는 되물음), `H-40`(브랜드 판정이 성립 불가임을 지적,
`isInst` 주입 제안), `H-33`(제 중첩 합성안이 디바운스 창을 안 끝나게 만든다는
지적). `Ref.Callbacks` 해시맵화와 `Ref` 콜백의 `canExecute` 확인은 **사용자가
먼저 발견**했다.

**반영 후 세 번의 재검토가 19건을 더 잡았고, 그 실패 패턴이 이 세션의 교훈이다.**
`/code-review high` 7건 중 **셋이 이번 반영이 만든 회귀**였다 — 상태가 셋이
됐다고 산문에 쓰고 코드엔 경계 하나만 남겨 생성자가 크래시하던 것, `native*`를
`_mounted`로 가리면서 그게 곧 파괴였다는 걸 놓쳐 영구 누수를 만든 것, "`:List`와
CRUD는 상호배타"라며 승인받은 분기가 **재마운트 경로를 안 봐서** 포탈을 깬 것.
셋 다 코퍼스 정합성 각도로는 구조적으로 안 보이는 종류라
`conventions.md`의 *"`/code-review`는 감사자를 대체하지 않는다"*가 실측으로 재확인됐다.
`quad-doc-auditor` 감사 루프는 **9라운드에서 새 발견 0건으로 수렴**했고 총 34건을
고쳤다(라운드별 5→7→2→2→3→9→2→4→0, 각도와 목록은 followup의 E절이 소스).
**라운드마다 각도를 바꾼 게 실제로 작동했다** — 가장 많이 잡은 6라운드(9건)는
문서 정합성이 아니라 *"이 체크박스로 코드를 짜면 무엇이 나오는가"*를 물은
라운드였고, `ROADMAP.md`의 미완료 항목이 대거 stale인 게 그때 드러났다
(폐기된 `pos` 공식이 "확정"으로, 접두합 캐시 무효화 계약이 통째로 부재,
`bindLifetime`이 "둘만 한다"고 적혀 `H-11`과 직접 모순).
**반복된 실패 패턴은 하나 — "고쳐야 할 자리가 N개인데 일부만 고쳤다"**:
배너를 달고 그 배너가 부정하는 문장을 안 고침(1라운드), `base/` 19개를 바꾸고
`.claude/README.md`를 한 줄도 안 고침(2라운드), 그 README를 고칠 때 11행 중
6행만(7·8라운드). **셋 다 핸드오버 체크리스트가 명시적으로 경고하는
항목**(2번·6번)이라, 규율이 없어서가 아니라 **지켰는지 스스로 확인하지
않아서** 생긴 실패다 — 8라운드를 아예 완결성 축("새 이름 하나당 나타나야 할
자리 넷을 열거해 세기")으로 잡은 게 그래서고 거기서 4건이 더 나왔다.
감사에서 파생된 새 결정 셋(주입 op `onDestroying` 신설, `EffectHandle`의 필드
다섯, `quad-types`의 `Quad` 갱신을 M3/M6/M7/M8/M10에도 항목화)도 같이 반영했다.

## 2026-08-24-02 — M2/M3 마일스톤 순서 교체 (반응형 먼저)

2026-08-22가 남긴 마지막 열린 항목(마일스톤 순서)을 사용자가 **(a) 순서 교체**로
닫았다 — 이제 **M2=반응형 코어, M3=디스패치 엔진**이다. 의존이 양방향처럼
보였지만 디스패치→반응형만 본체 의존이었고, 옛 순서로는 디스패치 마일스톤의
`mock 대상 테스트`조차 State 없이 불가능했다. 부수로 **`Brand`/`Relate`/
`LifetimeHandle` 인터페이스가 M2 앞머리 "공통 기반" 절로** 왔고(반응형이 이 셋을
먼저 요구), 2026-08-22에 디스패치로 앞당겼던 `EpochMap`/`GateNode`/`Blocker`는
**되돌아왔다**(앞당길 이유가 사라짐, "게이팅 먼저"는 그대로). 역방향으로 남은
건 "핸들러를 등록한다"뿐인 둘(동적 경로 가드, `ObserverEffectLeafHandler`)이라
M3로 넘겼다 — 그래서 빌드 순서상 역방향 간선이 없다.
**대가 하나** — 반응형이 앞으로 오면서 그 게이트 둘(중간 State GC 실측,
`store:GetDynamic` 위치)이 낮은 우선순위에서 **`question.md` 최우선 절로
승격**됐다. **실행 중 실수 하나** — 일괄 치환에 `\bM([23])\b`를 써서 한글이
바로 뒤에 오는 `M2는`/`M2로` 93건이 안 바뀌었다(Python `\w`는 유니코드라 한글도
단어 문자). `git show HEAD:<경로>`로 되돌린 뒤 ASCII 경계 lookaround로 재실행해
248건 전량 교체. **라이브 문서만 새 번호로 맞췄고 `session/`·`archive/`·
`qa-request/`는 히스토리라 소급 수정하지 않았다** — 그 경고를 인덱스 레이어
다섯 곳에 박아뒀다. 원문은 `session/2026-08-24-02-milestone-order-swap.md`.

**검증**: `quad-doc-auditor` 루프가 **7라운드에서 새 발견 0건으로 수렴**
(10→8→1→1→2→2→0, 총 24건 수정, 라운드마다 각도 교체). 가장 값이 큰 건
5라운드(구현 순서 시뮬레이션) — 새 M2에서 `Source`/`State`/`Store`가
`EpochMap.luau`보다 앞에 놓여 **그 순서로는 `State.luau`를 못 짜는** 걸
잡았고(State가 `valueEpochMap`/`emitEpochMap`을 컴포지션), 같은 라운드가
순서 교체의 전제("M2가 디스패치 없이 완주 가능한가")도 검증했다.
**수렴 뒤 `/code-review high`가 5건을 더 잡았고 전부 유효** — 다섯 중 넷이
*"라벨은 치환됐는데 그 라벨을 설명하던 산문이 안 고쳐진"* 종류(그중 둘은
`quad-types`의 "마일스톤마다 갱신" 규칙이 M3에 앵커된 채 첫 적용만 M2로
옮겨간 같은 뿌리)였고, 그중
하나는 `research/` 안의 **히스토리 블록**이 치환을 맞아 원래 논거가 문장
그대로 거짓이 된 것이었다(소급 수정 제외 대상을 `session/`·`archive/`·
`qa-request/`로만 잡은 게 샜다). `conventions.md`의 *"`/code-review`는
감사자를 대체하지 않는다"*가 또 재확인됐다.

## ⚠️ 2026-08-25 — `session/` 원문 공백 (기록만, 재구성 안 함)

**그날 `session/` 파일이 하나도 없다.** 2026-08-25는 7라운드 손 트레이싱
(6패스)과 그 검증·처리가 전부 일어난 날이고, 커밋 9개에 걸쳐 `Ref`의 `Epoch`
승격 · `WeakSubscribe`/`WeakCallback` · `_hold` 불변식 · Store 명시적 초기화 ·
`recompute` 재진입과 되감기(`H-101`/`H-102`)가 확정됐다 — 지금 M2 계약의
상당 부분이 그날 정해졌는데 원문 로그가 없다.
`.claude/conventions.md`의 *"설계 결정이 오간 세션은 끝나기 전에
`session/YYYY-MM-DD-NN-slug.md` 원문을 반드시 남길 것"*을 어긴 공백이고,
**그 규칙 자체가 2026-08-18/19의 같은 공백에서 만들어졌으므로 재발 사례다.**

**처분: 재구성하지 않는다.** 2026-08-19에 사용자가 정한 선례를 그대로
따른다 — 그 시점 대화 원문에 접근할 수 없는 채로 "원문"을 지어내면 그
자체가 허위 기록이 된다. 대신 공백을 여기 명시해 다음 세션이 "찾다가 없어서
헤매는" 일만 막는다. **그날의 결정 내용 자체는 유실되지 않았다** — 결정과
근거는 `qa-request/pre-implementation-handtrace-round7-followup.md`가,
발견 원문은 `qa-request/pre-implementation-handtrace-round7.md`와 그 검증 패스가, 재현 코드는
`audit/handtrace-round7-reference-impl/`이 들고 있다. 없는 건 **논의 과정과
시행착오**(`quadnomicon` 개발로그 소재로 쓰였을 부분)뿐이다.

(2026-08-26 8라운드 처리 중 감사 7라운드가 발견.)

## 2026-08-26-01 — 8라운드 손 트레이싱 처리 (`H-107`~`H-123`)

8라운드 발견 17건의 결정 문항 Q1~Q10을 사용자와 대화형으로 처리해 `base/`에
전량 반영. **역전은 없다** — 고친 건 전부 7라운드 확정이 `base/`에 내려앉을
때 생긴 누락·충돌(하루 차로 확정된 결정들이 서로를 못 본 자리)이다. 계약이
바뀐 것 넷: `Ref` 콜백 `fn(value, ref)` / Observer `fn`이 세 자리
`fn(targetState, self, emitFrom)` + `observer._state` 강참조 /
`WeakSubscribe`도 `.Subscribed`를 세움 / 예약 키 진단 타입 함수가 `T`가 아니라
`keyof<T>`를 받음(`T`를 통째로 넘기는 배선은 실사용 `T`에서 아예 안 돈다 —
실측). **⭐ 사용자가 문항의 전제를 두 번 정정했다** — `Ref` 콜백과 Observer
콜백은 애초에 통합 대상이 아니고(*"observer 에는 epoch 란게 존재하지 않음 …
ref 는 그 자체로 epoch임"*), `H-118`은 소유권 문제가 아니라 `gate-plan` 5번의
문장이 틀린 것(🟡→🟢). 결정의 소스는
`qa-request/pre-implementation-handtrace-round8-followup.md`, 진행 경위와
교훈은 `session/2026-08-26-01-handtrace-round8-resolution.md`.
**커밋 전 검증: 감사 11라운드(44건, 0건으로 수렴) + `/code-review high`
7라운드(42건) = 86건.** ⚠️ **감사가 0으로 수렴한 직후 code-review가 42건을
냈고**, 그중엔 `H-101`의 *"새 필드를 안 만든다"*를 **역전**시킨 설계 구멍도
있었다(부기 필드가 `offsetCacheValidUpTo`/`offsetSetUpTo` 둘로 갈라짐). 그 루프가
남긴 교훈 셋 — (1) 계약을 고칠 때 가장 새기 쉬운 자리는 `base/`가 아니라
그걸 요약·복사해 든 `ROADMAP`/`README`/`architecture.md`다(19건 중 15건),
(2) **넓게 퍼진 계약은 문서군이 아니라 *토큰*으로 전수 grep해야 잡힌다** —
`H-111` 잔재가 두 라운드 연속 새로 나오다 토큰 각도에서 4건이 한 번에 나왔다,
(3) **고치는 과정이 회귀를 만든다** — code-review 42건의 절반 이상이 직전
수정의 산물이었고, **같은 실수를 네 번 반복했다**(토큰을 바꾸고 그 토큰이 든
문장은 안 읽음; 한 번은 정정 배너 안의 **역사 인용문**까지 치환해 자기모순을
만들었다). 규칙: **전역 치환은 인용문·절 제목·정정 배너를 건드리지 말 것.**
상세는 그 세션 파일의 "검증 (커밋 전)" 절.

## 2026-08-27-01 — 9라운드 손 트레이싱 실행 + Q1~Q3 결정·반영 (`H-124`~`H-141`)

8라운드가 써둔 지시서대로 커밋 `9dd8213`의 델타를 재트레이싱해 발견 18건을
냈고(🔴 둘 다 실측 재현 — `recompute`가 되감기 판정보다 먼저 `lengthList[i]`를
읽어 `sum += nil` / 재마운트 시 `_baseObserver`가 unbind 상태라 옛 베이스
캐시), 그중 Q1~Q3를 확정·반영. **Q2는 사용자가 문항을 넘어섰다** — `Offset`/
`_baseObserver`를 Slot **생성자**로 올려 첫 마운트/재마운트 분기 자체를 없앴고,
파괴는 `_destroyed` 플래그 하나가 말한다(*"두 일을 겸하는걸 만들다가 사고가
난 적 많아"*). **Q3에서 `token`이 사용자가 정한 적 없는 것으로 드러났다** —
2026-08-25 `/code-review`가 발명해 사용자 인용문 옆에 앉아 있던 것(`H-141`);
`element → index`는 `bk.indexOfElement` 하나로 통일, `slot._elemIndex`·토큰
폐기, `setLength` 5번째 인자 `element`. 그 대화에서 메인 세션도 새 개념을 세 번
제안했다 철회했고, `conventions.md`에 *"새 필드·인자·이름·메커니즘은 발견이지
결정이 아니다"* 규칙을 신설했다. 감사 6라운드(1→1→3→1→1→0)로 수렴, `/code-review
high`는 Q4~Q10 반영 뒤로. 결정의 소스는
`qa-request/pre-implementation-handtrace-round9-followup.md`, 경위는
`session/2026-08-27-01-handtrace-round9-q1-q3.md`. **Q4~Q10은 다음 세션.**

## 2026-08-27-02 — 9라운드 Q4~Q10 결정·반영 + `H-138`/`H-139`/`H-142` (전량 처리)

Q4(`EffectHandle` 네 진입점 의사코드 — Observer 것 재사용, `Unsubscribe`만 게이트
통과 뒤 cleanup) / Q5(M2 공통 기반에 `Ref` 최소형) / Q6(`WeakUnsubscribe` 관대 —
약한 홀드를 강제하지 않으므로) / Q7(폐기 블록 `archive/effect-internal-observer-cascade-reversed.md`)
/ Q8(`InstanceChildHandler` 부기) / Q10(`reconcile` 재실행도 배치 Blocker,
네스팅 불가라 `ownsGate`). **Q9는 문항의 전제가 틀렸다** — Tween 절 스케치의
`hint == nil` 줄이 `v == nil` 규칙의 복사 오류, 파괴 경로는 `process(nil)` 하나.
`H-138` 숏핸드 우선순위 > `PropertyHandler`(충돌 방지는 `UI` 접두어). **`H-139`
파이프라인 의사코드**(`New` ①~④ + `drive` (a)~(c), `bind-system-plan.md`)를
쓰면서 배치 닫는 자리·빈 배열 파트 가드·`Parent` 순서가 드러났고, 마지막은
**`H-142` — props에 `Parent` 금지**(*"그건 부모에서 할 일"*)로 순서 문제 자체가
소멸. 감사 8라운드 뒤 `/code-review high` 10건 — 여섯 반영(그중 셋이 이 세션의
`H-134` 반영분이 만든 것), **넷은 새 메커니즘이라 문항으로**(`H-143`~`H-146`,
`question.md` 최우선 절). 결정의 소스는
`qa-request/pre-implementation-handtrace-round9-followup.md`, 경위는
`session/2026-08-27-02-handtrace-round9-q4-q10.md`.

- **`session/2026-08-27-03-handtrace-round9-h143-h146.md`** — 9라운드 후속:
  `/code-review`가 낸 새 메커니즘 넷 **전부 권고 (a) 확정·반영**. `H-143`
  `Rerun` 꼬리가 **실행 중에 죽었으면**(`wasAlive and not canExecute`) 반환
  cleanup 즉시 소진 + 재요청 버림(`fn` 안 `self:Unsubscribe()` 지원 — 처음 쓴
  `not canExecute` 하나짜리 판정은 생성자 최초 설치를 죽여 감사 2라운드가 정정) / `H-144` `Subscribe`·`WeakSubscribe` 등록 끝에
  `_epochs:Refresh()` + `not _installed or depsChanged → Rerun` 꼬리(사용자
  요청으로 재구독 뒤 emit·epoch·Blocker 상호작용을 재트레이싱, leaf
  `_bindDestroying`과 동형) — **그리고 감사 4라운드가 Q4의 "Observer 함수
  배정"이 콜론 위임 때문에 이 꼬리를 두 번 태우는 걸 잡아 (b) `EffectHandle`
  네 진입점 자기 것으로 확정**(*"하나의 무언가가 두 일을 동작하지 않는가"* →
  `conventions.md` 설계 원칙) / `H-145` `bk.indexOfElement` weak-key / `H-146`
  루트 부착은 금지 범위 밖 — `Mount` 표면 없이 사용자 몫(*"각 엔진을 사용하는
  최종 사용자의 몫"*), `Parent` 거부는 전용 문구. `question.md` 최우선 절 비움.
  결정의 소스는 `qa-request/pre-implementation-handtrace-round9-followup.md`.
  **[2026-08-28]** 감사 8라운드 수렴 → `/code-review high` 10건(일곱 반영, 셋은
  판단 필요) → 사용자 판단으로 **10라운드 문항지**(`-round10.md`, `H-147`~`H-149`
  씨앗 + 광범위 탐사)로 이관.
- **`session/2026-08-28-01-handtrace-round10-resolution.md`** — 10라운드 7문항 대화형
  결정·반영. **뒤집힌 것 둘**: `fn`/cleanup은 자기 구독을 못 바꾼다(`H-147` (A) —
  어제 `H-143`의 원샷 지원 소멸, `rawRerun(force)`/`Rerun` 분리, 네 진입점 `_running`
  가드) / 루트는 밖에서 `.Parent =`가 아니라 **quad가 `Claim`으로 소유**(`H-148` →
  `base/claim-plan.md`, 2026-08-14 기각과 다른 claim-once·own-all).
  나머지: Observer 진입점 인라인(`H-149`) / `Effect._blocker` 제거(`H-150`) /
  `_epochs`는 emit 때만 갱신, `Refresh` 캐치업 폐기 + "게이트는 emit 경로만 미룬다"
  계약(`H-151`) / `GateNode` 브랜드 등록(`H-152`) / Store 예약 이름 런타임
  가드(`H-153`) / `InstanceChildHandler` dedup(`H-154`) / ROADMAP·debounce·store
  stale(`H-155`~`H-157`). **같은 세션 후속**으로 `/code-review` 3건 + `H-158`~`H-162`도
  확정 — `:Block` 폐기(`__apply`) / **`_rerunRequired` 홀드 플래그**(사용자 제안,
  `_installed` 흡수, Observer 대칭) / `Claim` M5 스코프 / `Void` export. 미결은
  `Claim` 갈래(특히 다중 스크립트)뿐. **후속 2**: `H-163`/`H-164` → **`EmitReceive`**
  (전파 루프는 `sub:_receive(from)`만, 사용자 지시) · Slot 재마운트 캐치업 (a′) ·
  `emitFrom == nil` = 출처 없음 · `Observer:_catchUp()`. 소스는
  `qa-request/pre-implementation-handtrace-round10-followup.md`.
- **`session/2026-08-28-02-claim-promotion.md`** — 10라운드가 남긴 `Claim` 갈래 여덟을
  사용자가 한 메시지로 답하고(1~5) 에이전트가 §5-7을 "한 quad·여러 스크립트" 문제로
  다시 세워 되물은 뒤 전량 확정 → `research/existing-mount-plan`을 **`base/claim-plan.md`로
  승격**. 루트 키 센티널(맨 테이블 + `Claim<<T>>`는 타입 자동완성 손실로 기각, `type
  <Class>Param` 공유) / 디스크립터 순서 정본 / `New` 자식 허용(위치는 프로바이더 몫) /
  debug 검사 범위는 `debug-tooling-plan.md`로 / 이름 `Claim`·`D.Mapper` / **루트의
  `.Parent =`는 밖에서 허용으로 복원**(`H-146` 예외가 `Claim`한 루트까지 넓혀 복원,
  `Claim`은 1회·전체 소유, PlayerGui 직하 Slot 공유는 중간 모듈) / 매핑된 자식은
  `InstanceChildHandler` 그대로. `nativeFindChild` 주입 op 등록. `question.md` 최우선 절 비움.
  감사 6라운드(발견 2→3→1→3→2→0, 3~5라운드는 전부 낮의 "폐기" 배너가 저녁의 복원을
  모르던 것) → `/code-review high` 10건: 서술·라벨·stale 여섯 반영, **새 메커니즘 넷**은
  `base/claim-plan.md` §10 + `question.md` 문항으로(gcconn/gchold 셋업 자리 / 이중 claim
  레지스트리 / `PlayerGui` own-all vs `ResetOnSpawn` / `<Class>Param` 배열 파트). 리뷰가
  잡은 실질 정정: `Claim<T>` 추론은 `Clone()`이 `Instance`를 돌려줘 성립 안 함 →
  반환은 inst 타입 그대로 / `Processed` 관용구는 플래그 절반만 / claim된 inst에선
  `PreRef`/`OnCreated` 불변식이 약해짐. **같은 날 문항 넷도 답이 와 닫힘**(§7-9~12):
  주입 op **`nativeClaim(inst)`**에 gcconn/gchold (0) 경로 전부(`New` ②도 호출) /
  이중 claim은 셋업 유무로 error(*"claim 은 slot 이랑 무관"* — 리뷰 전제 기각) /
  **`PlayerGui`는 공동 소유 객체라 claim 대상 아님**, 루트는 `ScreenGui`·`SurfaceGui` /
  `FrameParam<E>` 원소 타입 파라미터.
