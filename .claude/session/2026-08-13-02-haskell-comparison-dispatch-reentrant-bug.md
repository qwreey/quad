# 2026-08-13 두 번째 세션 — Haskell Monad/Applicative 비교 리서치, `State<State<T>>` 재진입 디스패치 버그 발견·수정

## 배경

사용자가 "커링/레이지 이벨루에이션 말고 Haskell에서 가져올 만한 것(모나드,
애플리커티브 펑터 등)이 있는지"를 물으며 시작. 순수 탐색 질문이라 먼저
Explore 에이전트로 quad의 현재 반응형 코어(State/Source, `:Compute`,
`:With`, `:Apply`, `Operator.*` 카탈로그, Tag/Attribute/Modifier의
Merged/Overridden 병합, Slot의 store-bind 재구독, HKT 언급 여부,
`framework-comparison-findings.md`의 Haskell 비교 여부)를 그라운딩된 사실로
먼저 조사시킴.

## 1부 — Haskell 비교 조사 결과

- **Functor(`fmap`)/Applicative(`pure`+`<*>`)는 이미 사실상 가져와 있음** —
  `:Compute(fn)`이 fmap, `:With(...).Compute(fn)` + trailing-args sugar가
  applicative 결합. `pure`에 해당하는 값 승격도 `T | State<T>` 유니온
  패턴(`CanAnimate` 등)으로 이미 코퍼스 전반에 자연스럽게 녹아있음.
  진행 중인 `Operator.*` 콤비네이터 카탈로그도 사실상 애플리커티브 스타일
  결합자 모음이라 별도로 가져올 게 아니라 이미 백로그.
- **Semigroup/Monoid도 이미 있음** — `Tag.Merged`(가환)/`Modifier.Overridden`
  (비가환)/`Attribute.Merged`가 정적 결합 함수로 이미 구현됨, Haskell
  용어만 안 썼을 뿐.
- **Monad bind/join이 진짜 흥미로운 후보** — "State 값 자체가 또 다른
  State/컬렉션을 가리키고 그게 바뀌면 재구독"하는 패턴이 `StoreBind`,
  `Slot:Single`, `NoneHandler`의 재귀 재디스패치(`process(inst,k,nil)`)
  세 군데서 각자 따로 재구현돼 있음 — 이름도 없고 일반화도 안 됨. 중요한
  점: 이건 "동적 `:With` 의도적 비지원"과 충돌하지 않음 — 그 금지 대상은
  "의존성 *집합*이 런타임에 바뀌는 것"이고, join/bind는 의존성이 항상
  1개(바깥 State)인 채로 그 값의 *정체성*만 바뀌는 것이라 별개 축. 일반화
  후보로 남겨둠(착수는 안 함, 사용자가 원하면 research/로 승격 가능).
- **Traversable/sequence는 빈 자리** — `Store.Combine(array, fn)`이
  positional 정적 인자 버전으로 기각된 적은 있지만, 런타임 길이 배열을
  하나의 State로 합치는 Promise.all류 유틸은 논의 자체가 없었음. Slot이
  이미 배열 다루는 자체 메커니즘(`:List`)을 갖고 있어 실제 필요성은 불확실
  — 실사용 사례 나오면 재검토할 후보.
- **Alternative/`<|>`(fallback)는 가치 낮다고 처음엔 판단** — `if a then a
  else b end`로 충분하다고 봤으나, 후속 대화에서 사용자가 이의 제기(아래
  2부).
- **do-notation/모나드 트랜스포머/Arrow는 스킵 권장** — Luau가 higher-kinded
  type(타입 생성자 다형성)을 지원 안 함(코퍼스 전체 확인 결과 이 개념
  자체가 등장한 적 없음), 그래서 Haskell처럼 하나의 `Functor f => f a`
  인터페이스로 State/Slot/Ref를 통일 못 하고 지금처럼 타입별 개별 구현
  (구조적 타이핑, `store.key`의 type function 합성과 같은 접근) 유지가 맞음.

## 2부 — `Alternative` 재검토, `State<State<T>>` 재진입 버그 발견

사용자가 `Alternative`를 다시 꺼냄: `State<number|nil>:Apply(Alternative(1))`
꼴로 nil 대체값을 표현하면 편할 것 같다는 지적 + 두 가지 확인 요청:

1. `Operator` 카탈로그에 이미 있는지
2. **`State<State<T>>`가 UB로 명시돼 있는지, 그리고 `retractUnder`가 꼬리부터
   정리하는 구조인데 같은 키에서 "이미 사용된 핸들러가 재사용"되면 문제
   아닌지** — Attribute의 `rawNew(name)` 위임은 별도 키로 가니 괜찮을
   것 같지만, 순수 `State<State<T>>`는 문제가 실제로 날 것 같다는 가설.
   "이거 에러 안 나면 치명적일 수 있는데, 해시맵으로 막는 비용은 낮다"는
   결론까지 제시.

Explore(opus) 에이전트로 `bind-system-plan.md`의 `Dispatch`/`retractUnder`/
`StoreBind` pseudocode를 정확히 추적해 검증:

**질문 1 답**: `operator-sugar-plan.md` 카탈로그에 nil 대체 콤비네이터
없음 확인. `Clamp`/`Min`/`Max` 항목과 같은 형식으로 `Alternative(default)`
후보를 신설(카탈로그 확정 규칙 `factory(self)->State<U>`+`:Apply`에 그대로
맞음, 업계 선례로 RxJS `defaultIfEmpty`/Kotlin 엘비스 연산자 등 근거 있음).

**질문 2 답 — 사용자 가설 전부 확인됨, 실제 버그로 재현**:
`store.key = a`(State), `a:Get() = b`(State)일 때 pseudocode를 손으로
대입:
1. `Dispatch.process(inst,k,a)` → StoreBind 매치 → `list={SB}` → Observer
   즉시 실행 → `Dispatch.process(inst,k,b)` 재귀.
2. `b`도 State라 **같은 StoreBind 싱글톤 객체**가 또 매치 → `list={SB,SB}`
   — 같은 핸들러가 한 체인에 두 번. 안쪽 Observer가
   `relate:SetStrong(inst,k,·)`로 바깥 Observer 참조를 덮어써 바깥 것이
   유령 구독으로 샘.
3. 안쪽 Observer 즉시 실행이 부르는 `retractUnder(inst,k,SB,·)`는 첫
   매치를 찾는 루프(457행) 때문에 **항상 바깥쪽 인덱스**를 cutoff로
   잡음 → 실제 retract 대상은 다음 인덱스(안쪽 자기 자신) → **안쪽
   State 구독이 등록 직후 스스로 끊김** → 이후 `b:Set(...)`이 조용히
   무시되는 정지 버그.
4. 코퍼스 어디에도 UB로 명시된 적 없었고(오히려 `bind-system-plan.md:
   811-813`이 "다른 store여도 상관없이 처리 가능"이라 낙관적으로
   틀리게 서술), 막는 가드도 전혀 없었음(순환 UB 방어의 전제 —
   "각 핸들러는 최대 한 번씩만 그 키에서 호출됨" — 를 스택오버플로 없이
   조용히 깨는 경로였음).
5. Attribute의 `rawNew(name)` 위임은 별개 `(inst,key)` 체인으로 옮겨가는
   것뿐이라 이 버그를 원천적으로 피하지 못함 — 위임된 값 자체가
   `State<State<T>>`면 `AttributeKey` 체인 안에서 동일 재현.

## 3부 — 수정 반영 (같은 세션에 즉시)

- `Dispatch.process` pseudocode(`bind-system-plan.md`)에 "같은 `(inst,k)`에
  같은 핸들러 객체가 이미 체인에 있으면 즉시 error" 가드 추가(push 직전,
  가장 저비용 지점).
- "확정된 디스패치 모델" 절의 "순환은 UB" 불릿 바로 뒤에 이 발견 전문을
  신규 불릿으로 추가.
- 811-813행("심지어 다른 store"까지 낙관적으로 커버 가능하다던 서술)과
  "Store가 Store를 저장 가능한가" 절(Store *필드* 얘기와 State가 emit하는
  값 얘기가 다른 축이라는 스코프 혼동이 있었음)을 정정.
- **`operator-sugar-plan.md`에 `Alternative` 후보 신설** (2부 질문1 답).

## 4부 — 기존 스파이크 `04`의 사각지대 발견

`luau-test/04-dispatch-chain-retractUnder.luau`를 다시 읽어보니, 이 파일이
**이미 정확히 이 시나리오(storeA에 storeB를 다시 대입하는 "다단 체인
스트레스 테스트")를 다루고 있었음**을 발견. 그런데 손으로 재트레이싱해보니
이 스파이크의 `retract`가 print만 하는 완전 no-op이라(실제 구독 해제
로직이 없음), 안쪽 State가 "자기 자신을 스스로 retract"하는 버그가 실제로
일어나도 아무 부작용 없이 넘어가버려 겉보기엔(체인 길이만 보면) 3~4단계가
정상으로 통과하는 것처럼 보였음 — 즉 이 스파이크는 정확한 시나리오를
갖고 있었지만 검증 방식의 결함으로 이 버그를 절대 못 잡는 구조였음.
파일 자신의 주석("retract가 할 일이 '구독 해제'라는 본질은 같아서 로직
검증엔 영향 없음")이 바로 이 지점에서 틀렸던 것.

**수정**: 3단계를 "가드가 실제로 error하는가"(`pcall`로 감싸 `ok==false`
확인) + 4단계를 "가드 발동 후에도 같은 자리에 정상 재바인드가 되는가"(체인
길이 2로 복구)로 재작성. `Dispatch.process`에도 같은 중복 핸들러 가드를
이식. 파일 상단 주석과 확인 포인트 목록도 이 정정을 반영해 다시 씀.
`luau-test/README.md`의 04 행 요약, 갱신 이력(10차), "결과 확인 후 할 일"
체크리스트에도 추가 — 만약 실측 시 3단계가 error 없이 통과하면(`ok==true`)
가드 pseudocode 자체의 회귀이니 바로 알리라고 명시.

`luau` CLI가 이 환경엔 없어 실제 실행 검증은 못 함 — 손 트레이싱만 완료,
사용자가 실측할 때 확인 필요.

## 핸드오버 시점 코퍼스 동기화

- `.claude/README.md`의 `bind-system-plan.md`/`operator-sugar-plan.md` 행에
  이 세션 요약 추가.
- `.claude/question.md`의 `Operator` 항목에 `Alternative` 후보 언급 추가.
  `State<State<T>>` 건은 같은 세션에 발견+수정까지 끝나 "열린 질문"이
  아니므로 question.md에 별도 항목 안 만듦.
- 코퍼스 전체 grep으로 "심지어 다른 store" 류 낙관적 서술의 다른 사본,
  `Dispatch.process` pseudocode의 다른 인라인 사본이 더 있는지 확인 —
  `bind-system-plan.md`와 `luau-test/03`/`04`뿐이었고, `03`은 스스로
  "다단 체인(retractUnder)까지는 다루지 않음"이라고 이미 스코프를 좁혀둔
  파일이라 영향 없음(가드 이식 불필요, 확인만).

## 남은 것

- Monad bind/join 일반화(위 1부)는 착수 안 함 — 원하면 `research/`에 정식
  후보로 새로 남길 것.
- `Alternative`/`Clamp`/`Min`/`Max` 등 `Operator` 카탈로그 최종 이름·포함
  여부는 여전히 사용자 몫, 우선순위 최하(순수 슈가).
- `.claude/luau-test/` 전체 스파이크(20개, `04`는 이번에 시나리오
  재작성됨)는 여전히 사용자가 `luau`로 안 돌려봄 — M0 착수 전 최우선
  게이트 그대로 유지.
