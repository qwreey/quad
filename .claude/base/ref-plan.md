# Ref / PreRef / PostRef — 지연 없는 확정 값 박스

> **[2026-08-14 아홉 번째 세션] `PostRef` 확정·이 문서에 편입.**
> `base/lifecycle-hooks-plan.md`(당시 `research/`)가 백로그 후보로만 들고 있던 스케치를
> 사용자가 확정("Pre-Post 둘을 지원 안 할 이유가 없고 구현 난이도가 아주
> 낮음") — 아래 "`PostRef`" 절 신설, 그 문서도 `base/lifecycle-hooks-plan.md`로
> 같이 승격됨. **같은 계열 안의 fire 순서(복수 `PreRef`끼리, 복수
> `PostRef`끼리)는 배열 index 순서 그대로 보장** — 같은 세션에 이걸 잠깐
> "미보장"으로 뒤집었다가 곧바로 철회했음, 그 왕복의 기록은
> `archive/preref-order-unguaranteed-withdrawn.md`.

> **[2026-08-13 아홉 번째 세션] `bind-system-plan.md`에서 분리됨.** 그
> 문서가 2989줄까지 불어나 사람이 검토하기 어렵고 한 곳의 실수가 미치는
> 범위가 너무 커진다는 사용자 지적에 따른 1단계 분할. **내용은 옮기기만
> 했고 결정은 하나도 안 바뀜.**

**상태**: base — 확정. `Dispatch`/`Brand`와의 관계는
`base/dispatch-core-plan.md`(디스패치 코어)와 `base/brand-plan.md` 참고.

## Ref — 도입 확정, 단 용도는 재정의됨

**중요한 정정**: Ref는 Tween이 대상을 얻기 위해 필요한 게 아님(트윈을
실제로 처리하는 PropertyHandler도 `process(inst,k,v)`처럼 항상 대상
Instance를 직접 받으므로 — `base/dispatch-core-plan.md` "확정된 디스패치
모델" 참고, `base/tween-plan.md`도 이에 맞춰 갱신됨). Ref의 진짜 용도는 다름:

- v1의 `Frame "id" {}` + `Store.GetObject(id)` 식 id 매핑은 폐기 확정
  (`base/architecture.md` 5번 항목) — "비현실적"이라는 게 이유.
- 하지만 **"라이브러리가 자기 자신이 만들어낸 instance를 나중에 다루기 편하게"**
  하는 용도로 Ref는 여전히 필요. 구체 시나리오: 기존에 다른 라이브러리로
  관리되던 instance를 당장 quad로 옮기지 않고, ref를 따서 그 안에 자식을
  `Parent`로 마운트한다든가, 점진적으로 마이그레이션한다든가, 래퍼를 만든다든가
  하는 다양한 용도.
- Store는 이미 바깥에서 옵저빙 가능한 존재라 별도 취급 불필요 — Ref는 그와
  달리 "원하는 객체 자체를 직접 얻어오는" 경로. **얻어진 뒤에 그 참조를 어디에
  저장하고 어떻게 쓰는지는 라이브러리 책임 범위 밖**(사용자 자유).
  **권장 관례(2026-08-12, use-after-destroy 검토에서 명문화):** Ref는
  이를 만든 컴포넌트 자신이 쓰거나 자식에게 넘겨 쓰는 용도가 관례 —
  React `useRef`와 같은 스코프 감각. 컴포넌트 경계를 넘어 위로
  반출하거나 전역에 장기 보관하는 건 권장하지 않음 — Ref는 Destroy와
  완전히 무관하게 동작하므로(아래 "Destroy와는 무관" 절), 관례를 벗어난
  반출·장기보관은 use-after-destroy가 발생할 수 있는 사실상 유일한
  자리가 됨. quad는 이 케이스에 런타임 안전망을 두지 않기로 확정
  (`research/framework-comparison-findings.md` 3번 절 근거) — 대응은
  이 관례를 지키는 것뿐, 위반 시 결과는 완전한 UB.
- **바인드 방법**: children을 배열 아이템으로 넣듯 `Ref(default)`(또는
  `:Callback(fn)`을 미리 걸어둔 `Ref(default):Callback(fn)`) 인스턴스
  자체를 숫자 키 슬롯에 그대로 넣는 방식 — `(v=Ref)` 매치 핸들러가 이걸
  처리함. **별도 `CreatedRef` 래퍼 함수는 없음(2026-08-07 아홉 번째
  세션, 사용자 확인) — `Ref`/`PreRef`가 이미 Compose식 `Type(default)`
  팩토리 생성자로 확정됐으므로("생성자 스타일 확정" 절), 그 결과를 그대로
  children 배열에 놓는 것 자체가 바인드 관용구.** 원래 "`CreatedRef` 같은
  이름 미정의 래퍼"로 서술했던 것은 Ref가 아직 "instance 얻는 통로"로
  좁게 정의됐던 시절(2026-08-04)의 잔재였고, 2026-08-06 Ref 일반화 이후
  래퍼 자체가 불필요해졌는데 이름만 남아있던 것을 이번에 정리함.
  **[정정, 2026-08-07 세 번째 세션]** 정확한 순서 보장(자식 마운트
  전/후, 프로퍼티보다 먼저)은 위치와 `PreRef` 타입으로 갈렸음 — 아래
  "`phase` 옵션 폐기 → 위치로 표현, `PreRef` 신설" 절이 최신, 원래 있던
  "옵션(`{phase=...}`)으로 두 타이밍을 고른다"/"특수 처리 없는 평범한
  참가자" 서술은 `archive/ref-phase-option-reversed.md`로 옮김.
- **왜 값이 아니라 콜백인가**: quad는 React처럼 렌더 함수가 계속
  재실행되지 않음(플레인 함수를 한 번 호출해 트리를 만들고 끝) — 그래서
  "채워졌는지 매 렌더마다 다시 확인"하는 모델 자체가 없고, `useEffect`
  의존성 배열 같은 것도 없음. 즉 값이 채워지는 시점을 외부에서 알아낼
  방법이 콜백(또는 폴링, 채택 안 함 — `lifecycle-pattern.md`에서 폴링
  방식은 이미 기각된 패턴) 말고 없음. 값 자체를 나중에 다루고 싶으면
  콜백 안에서 원하는 곳(외부 변수, `self._button` 같은 필드, Store 등)에
  직접 대입해 캡쳐하면 됨 — `component-composition-plan.md` 31행 예제
  참고. 즉 "값으로도 얻어진다"는 요구는 별도 API가 아니라 콜백이 이미
  충족함.

### Ref 일반화 — 엔진 instance 전용이 아니라 범용 값 박스 (2026-08-06 후속 세션)

**결정**: Ref는 "quad가 만든 instance를 얻는 통로"로 좁게 남지 않고,
**아무 사용자 값이나 담을 수 있는 범용 "채워지길 기다리는 값 박스"**로
확장한다. 위 "코루틴 기반 대기 지원 여부는 미정"이었던 항목은 이걸로
해소됨(더 이상 열린 질문 아님).

- **object-ref/function-ref로 나누지 않음.** React의 `useRef`가 DOM
  노드든 임의의 사용자 값이든(함수 포함, `ref.current?.()`로 호출하는
  imperative-handle 패턴 포함) 같은 API로 다루는 것과 동일한 선례 —
  두 개념으로 쪼개면 사용자가 "이번엔 어느 쪽을 써야 하나" 매번
  판단해야 해서 나쁨. 엔진 instance도 그냥 "사용자 값의 한 종류"일 뿐.
- **구체 유스케이스**: 자식 컴포넌트가 비싸고 온디맨드로만 필요한 계산
  (예: 클릭 위치 기준 컨텍스트 메뉴를 그리기 위한 clip bounds 계산)을
  부모에 노출하고 싶을 때, 매 변경마다 push하는 대신 부모가 필요할 때만
  `ref.Value?.()`처럼 호출하는 함수를 Ref에 담아 넘기는 패턴 — React의
  imperative handle과 동일한 이유(비싼 연산이라 온디맨드가 맞음, 값이
  최신인지 아닌지도 애매해짐).
- **API 모양**: `.Value`(읽기 전용 필드) + `:Set(value) -> Ref<T>`(쓰기) +
  `:Callback(fn) -> Ref<T>`(콜백 등록, 복수 허용) + `:Wait(thread?) -> Ref<T>`
  (coroutine 컨텍스트에서 사용 — 렌더 함수 바디 안에서 `return` 위에 바로
  못 씀, 그래서 콜백도 같이 필요) **세 메소드로 확정(2026-08-07 여섯 번째
  세션)**. `:Set`/`:Callback`/`:Wait` 전부 **mutation 패턴이라 자기 자신
  (`Ref<T>`)을 반환** — `store.key:Set(value)`류 "값을 바꾸는 연산엔 `:`
  체이닝 허용" 원칙(`base/store-plan.md`의 "Store 값 설정 문법" 절)의 자연스러운 재적용.
  이 self-반환 덕에 Luau의 `if`-표현식과 결합해 흔한 관용구를 한 줄로
  쓸 수 있음(사용자 제시 예):
  ```luau
  local t = if ref.Value
    then ref.Value
    else ref:Wait().Value
  ```
  - 콜백은 이미 채워져 있으면 등록 즉시 그 값으로 1회 호출됨 — nil/미설정
    상태여도 그 상태 그대로 호출. React의 `useEffect`가 매번 `.current`
    존재 여부부터 체크하는 것과 같은 이유, Ref가 자식으로 전달되는 경우
    채워지는 시점이 더 늦어질 수 있어서 "이미 채워졌는지" 확인이 항상
    필요함. `:Wait()`의 대기자 리스트와 콜백 리스트는 같은 배열
    (`self.Callbacks`) 하나를 재사용(발화 후 해당 인덱스만 **`nil`로 소진**
    — 아래 구현 디테일 참고,
    **[재정정, 2026-08-09 열한 번째 세션] `None`이 아니라 `nil`이 맞음**,
    바로 아래 캐비엇 참고).
  - **[재설계, 2026-08-18 구현 전 QA] 콜백/대기자는 별도 필드
    `.Callbacks` 테이블에 담고, `.Value`는 그냥 평범한 hash 필드로 둔다.**
    옛 설계(2026-08-09 열한 번째 세션 보강)는 **Ref 객체 자신이 곧
    콜백/대기자 배열**(숫자 키 색인)이라, `T`가 함수/스레드일 때
    `for i, v in self do` 순회가 hash 파트의 `.Value`까지 훑어 오분류되는
    걸 막으려고 **`.Value`를 `__index` 메타메소드로** 구현해야 했다.
    사용자 판정: *"단순히 .Callbacks: {fun, thread} 등이 있는게 맞지
    않나라는 생각임. .Value 는 단순 해시필드로 주는게 더 간단해보임.
    엔지니어링 난이도구 단순 테이블 하나 더 만드는게 쉽고, 크게 비싸지도
    않다고 생각됨."* — 순회 대상이 `self`가 아니라 `self.Callbacks`가
    되므로 **hash 파트 충돌 자체가 안 생기고, `__index` 우회 기법을 쓸
    이유가 사라진다.** 대가는 Ref 하나당 테이블 하나가 더 만들어지는 것뿐
    (`.Callbacks`를 첫 등록 시점에 lazy로 만들지는 구현 재량).
  - **`:Wait(thread?)`의 `thread` 인자(2026-08-07 여섯 번째 세션, 사용자
    제안, 확정)**: 생략(`nil`)하면 `coroutine.running()`으로 호출 중인
    코루틴 자신을 캡처해 대기자로 등록하고 그 자리에서 `coroutine.yield()`로
    **자기 자신을 정지**시킴(값이 채워지면 재개). 명시적으로 다른 thread를
    넘기면 **그 thread를 대기자로 등록만 하고 정지 없이 즉시 `self`를
    반환** — 코루틴 역학상 `coroutine.yield()`는 지금 실행 중인 코루틴만
    정지시킬 수 있고, 어딘가 이미 정지해 있는 남의 thread를 여기서 대신
    정지시킬 수는 없기 때문(그 thread는 이미 정지 상태). 이 표면의
    용도: 사용자가 직접 관리하는 스케줄러가 이미 만들어 둔(어딘가 다른
    지점에서 정지시킨) thread 하나를 Ref에 등록해두고, 등록한 코드 자신은
    블록되지 않고 계속 진행하고 싶은 경우. 구현은 정말 단순함 — `thread`가
    `nil`이면 yield, 있으면 yield 안 함.
  - **구현 디테일(2026-08-07 세 번째 세션 제안, 여섯 번째 세션에서 resume
    payload 정정, 열한 번째 세션에서 소진 방식 최종 확정)**: 값이 새로
    `:Set()`될 때, 같은 배열 하나를 `for i, v in self.Callbacks do ... end`로
    한 번만 순회하면서(**[2026-08-18]** 순회 대상은 Ref 객체 자신이 아니라
    `.Callbacks` 테이블 — 위 재설계) `type(v) == "thread"`면 `:Wait()`가 만든 대기자로 보고
    **`coroutine.resume(v, self)`** (즉 값이 아니라 **Ref 자기 자신**을
    resume 인자로 넘김 — 위 self-반환 관용구가 `:Wait()`의 yield
    경로에서도 그대로 성립하게 하기 위해, `coroutine.yield()`의
    리턴값이 곧 `self`가 되도록 정정. 세 번째 세션 원안은 `value`를
    넘기는 것으로 적혀 있었으나 이러면 `ref:Wait().Value`가 안 풀려서
    정정) 후 **`[i] = nil`**로 소진(아래 "왜 `None`이 아니라 `nil`인가"
    참고), 아니면 일반 콜백 함수로 보고 그냥 `v(value)`(콜백은 여전히
    원래 값을 직접 받음, 소진 안 함, 계속 유지)로 분기하면 됨 — 대기자/콜백을
    서로 다른 배열로 나눌 필요 없이 값 타입 하나로 분기 가능
    (`type(v) == "thread"` → 대기자, `type(v) == "function"` → 콜백,
    `nil` → 빈 슬롯이라 스킵). **[정정, 2026-08-20 구현 전 QA 4라운드 `R-11`]
    새 콜백/대기자 등록은 그냥 `table.insert`를 쓴다** — 옛 서술은 "`table.insert`가
    아니라 비어있는 첫 슬롯을 선형 탐색해 재사용하는 등록 함수"였는데, 사용자
    판정으로 뒤집힘: *"table.insert 자체가 가장 처음 nil 이 등장하는 인덱스에
    넣어주기에 table.insert 가 맞음 … None 으로 바꾸면 무한정 불어나지만,
    nil이면 그렇지 않음."*
    - 즉 소진으로 생긴 구멍을 `table.insert`가 알아서 되찾아 쓰므로, 별도
      선형 탐색 등록 함수를 손으로 만들 이유가 없다. 아래 "왜 `None`이 아니라
      `nil`인가" 절이 들던 "`table.insert`의 `#t`가 구멍 있는 테이블에서
      미정의"라는 회피 근거도 이 배열에 대해서는 실무상 성립하지 않는 것으로
      정정 — 그 절의 결론(`nil` 소진)은 그대로이고 **우회 방법만 단순해짐**.
    - **⚠️ 실측 대상(M0/M8)**: 구멍 있는 테이블에서 `#t`가 반환하는 border는
      Lua 명세상 "어떤 border든" 이므로, "항상 첫 `nil` 자리"가 Luau 구현에서
      실제로 그렇게 나오는지는 스파이크로 확인할 것 — `luau-test`에 등록
      함수/소진을 반복하는 케이스를 추가. 결과가 다르면 이 항목만 되돌리면
      되고(옛 선형 탐색 버전), 나머지 설계엔 영향이 없다.
  - **왜 `None`이 아니라 `nil`인가(2026-08-09 열한 번째 세션, 최종 정정)
    — 2026-08-07 열 번째 세션에 `None`으로 바꿨던 것은 이 배열에는 안
    맞는 처방이었음, 되돌림.** `None`을 도입한 원래 근거(구멍 있는
    정수 키가 해시 파트로 튀어 순회 순서가 깨짐, `table.insert`의 `#t`가
    구멍 있는 테이블에서 미정의 동작)는 **순서가 실제로 중요한 배열**
    (`PreRef` pre-pass, Length/Offset의 `sourceList` — `1..N` 고정
    범위로 도는 `for` 루프라 구멍이 있으면 안 됨)에는 맞는 처방이지만,
    Ref의 콜백/대기자 배열은 애초에 **순서가 중요하지 않다**(어느 게
    먼저 fire되든 전부 fire되기만 하면 됨) — 일반화 `for i,v in tbl do`는
    구멍이 있어도 순서가 뒤섞여도 **모든 엔트리를 빠짐없이 방문**하므로
    "순서 보장이 깨진다"는 문제 자체가 이 배열엔 없음. 오히려 `None`을
    쓰면 소진된 슬롯이 영원히 non-nil로 채워진 채 남아 **매 `:Wait()`
    호출마다 배열이 끝없이 길어지는** 새 문제가 생김(등록이 항상 끝에만
    추가되고 예전 슬롯을 재사용 못 함) — `nil`로 지우면 다음 등록이 그
    빈 슬롯을 재사용할 수 있어 배열 크기가 동시 대기자 수만큼만 유지됨.
    `table.insert`의 `#t` 문제도 **`table.insert`를 아예 안 쓰고** 빈
    슬롯을 선형 탐색해 넣는 등록 함수로 우회하면 됨(`None`이 필요했던
    이유 자체가 없어짐). 결론: **순서가 안 중요하고 슬롯 재사용이
    필요한 배열(Ref 콜백/대기자)은 `nil` 소진, 순서가 중요한 배열은
    실재하는 센티널로 소진** — 두 패턴이 서로 다른 문제를 풀고 있었을 뿐,
    하나로 통일할 이유가 없었음.
    **[정정, 2026-08-18 구현 전 QA] 후자의 예시가 부정확했음** — 옛
    문장은 순서가 중요한 배열의 예로 "`PreRef` pre-pass 소진 슬롯,
    Length/Offset `sourceList`"를 들며 둘 다 `None`으로 채운다고 적었는데,
    **pre-pass가 소진시킨 자리는 `None`이 아니라 전용 센티널
    `ProcessedPreRef`/`ProcessedPostRef`** 로 채워지고 전용 nop
    핸들러가 정상 `Dispatch.process` 경로에서 그걸 캐치한다(아래 "PreRef"/
    "`PostRef`" 절, `base/dispatch-core-plan.md`는 2026-08-14에 이미 이렇게
    정정돼 있었고 이 문장만 갱신에서 빠졌음). `sourceList`가 `None`인 것은
    맞음.
  - **주의(문서화 대상, 방어 로직 없음)**: 이미 죽은(완료/에러난) thread를
    `:Wait(thread)`에 넘기면 나중에 `coroutine.resume`이 에러남 — 이건
    다른 UB 케이스들과 같은 결로 라이브러리가 방어하지 않고 호출부 책임으로
    둠.
- **제네릭 시그니처(2026-08-07 확정): `Ref<T>(T) -> Ref<T>` — 단일 타입
  파라미터.** React `useRef<T, U=T>(U): T|U`류 "초기값 타입과 최종 타입을
  분리"하는 2파라미터 설계도 검토했으나(예: `Ref<<HTMLDivElement>>(null)`
  → `HTMLDivElement|null`), Luau 솔버로는 명시된 타입 파라미터 하나와
  인자에서 추론되는 다른 타입 파라미터가 만드는 합집합이 깔끔하게
  풀리지 않고 미해소 제네릭 변수가 결과 타입에 남는 것으로 확인(사용자가
  직접 Luau 플레이그라운드류로 확인) — `Source<T> satisfies State<T>`나
  `State<Modifier>` 차단 검증 항목(`research/pre-implementation-audit.md`)
  에서 이미 반복 확인된 "Luau 제네릭 솔버는 복잡한 조합에서 잘 안 풀린다"는
  패턴과 같은 결. 단일 파라미터로 단순화하면 이 위험 자체가 없음 — 대신
  초기값만으로 좁은 타입이 추론되는 문제(`Ref(nil)`이 `Ref<nil>`로
  좁혀짐)는 `Ref<<Obj?>>(nil)`처럼 **명시적 제네릭 적용**(`f<<T>>(...)`
  패턴, `.claude/initreq/tbox/CLAUDE.md:40-41` 선례)으로 타입을 넓혀
  풀면 됨 — React `useRef<HTMLDivElement>(null)`도 명시적 타입 인자 없이는
  같은 문제를 겪으므로 이미 널리 받아들여진 UX, quad가 새로 감수하는
  트레이드오프 아님.
- **children 배열에 넣으면 dispatch가 자동으로 채워주는 것과의 관계**:
  이 절의 Ref가 그 범용 프리미티브 자체 — 위 "바인드 방법" 절대로 `Ref`
  인스턴스를 children 배열 숫자 슬롯에 그대로 놓으면 됨(quad가 만든
  instance에 한정된 경우). 정확한 타이밍 보장은 옵션 값이 아니라 위치
  기반 + `PreRef` 타입으로 표현됨 — 아래 "`phase` 옵션 폐기 → 위치로
  표현, `PreRef` 신설" 절이 최신.
- **해소됨 — 반복 재설정 가능(one-shot 아님), 사용자 확정.** React에서도
  자식이 재생성되는 경우 같은 방식(ref가 다시 채워짐)을 씀 — 예: 마우스
  호버/무브 시 `current` 확인 후 라벨 위치를 결정하는 라벨 컨테이너
  하나를 두고 라벨 내용만 스왑해가며 Ref를 재사용하는 패턴. 이런 고급
  패턴은 조심할 게 많지만 그건 라이브러리가 아니라 사용자가 신경 쓸
  몫. **따라서 콜백은 "발화 후 소진"이 아니라 매 `:Set()`마다 다시
  불림** — 소진되는 건 `:Wait()`가 만드는 개별 대기자(coroutine 재개는
  본질적으로 1회성)뿐, 콜백 리스트 자체는 유지됨.
- **⚠️ Ref는 의도적으로 lazy가 아니고 `:Compute` 파생을 지원하지 않음
  — State와의 이 차이가 중요함.** (예전엔 Store가 Ref와 비슷한 것도
  겸해서 지원한 적이 있었는데, State의 lazy 재계산 모델과 Ref의 즉시
  get/set 모델이 섞여서 좋지 않았음 — 그 경험에서 나온 의도적 분리.)
  Ref는 그냥 "지금 뭐가 들어있나/누가 채워주길 기다리나"만 다루는 즉시
  값 박스이고, 파생값이 필요하면 Store/State(`:With`+`:Compute`)를 쓸 것
  — 둘을 섞으려 하지 말 것.
- **[해소됨, 2026-08-08 다섯 번째 세션]** 위 정의 확장을 감안해도 `Ref`
  이름은 그대로 확정 — "지연 없는 확정된 값 박스"라는 정의가 leaf로
  담기는 용도/leaf에 바인딩하는 용도 둘 다에 여전히 맞아 더 나은 대안이
  없다는 결론, 용어 정리 대상에서 제외됨.

### `Ref`의 retract — `State<Ref>` 재바인드 시 이전 Ref에 `nil` (2026-08-12 여덟 번째 세션, `TagHandler`와 같은 메커니즘 재사용)

> **✅ [2026-08-13 열네 번째 세션] 하강 diff 재디스패치 반영 완료.**
> "이전 클로저가 먼저 불려 언바인딩, 그 다음 `process`가 바인딩"이라는
> **두 단계 자체는 그대로**이고, 그걸 일으키는 주체만 바뀌었음(래핑
> 핸들러의 선행 `retractFrom` → `Dispatch.process`의 핸들러 선비교).
> 클로저가 받는 값의 타입도 이제 계약으로 보장됨(항상 `Ref`이거나
> `nil`). 상세는 `base/dispatch-core-plan.md` "Dispatch 체인" 절, 옛
> 모델 원문은 `archive/dispatch-hintvalue-model-reversed.md`.

**배경**: `Ref`는 이미 "일반 프로퍼티/Modifier 필드/Store 값 어디든 자유롭게
들어감"(아래 "동적 경로 가드" 절)이 확정돼 있어 — `State<Ref>`가 실제로
가능하고, 그러면 Store 값이 `refA`에서 `refB`로 바뀌는 경우가 생김. 이때
`refA`가 계속 "확정된 값(대개 이전 `inst`)"을 들고 있으면, 그 자리가 이제
`refB`로 넘어갔다는 걸 모르는 코드가 `refA.Value`를 계속 유효하다고 믿는
조용한 버그가 남음 — `PreRef` 재사용 버그(위 절)와 같은 클래스의 문제.

**메커니즘 — retractor가 매번 불린다는 전제 위에서 언바인딩 전담
(2026-08-12 열한 번째 세션 정정, 2026-08-13 다섯 번째/열네 번째 세션에
서술 갱신).** 이전 `process`가 반환한 클로저는 store 값이 바뀔
때마다(핸들러 타입이 그대로여도) 무조건 불림 — 같은 핸들러면
`Dispatch.process`가 그 자리 클로저에 새 값을 넘기고 곧바로 `process`를
다시 부르기 때문(`base/dispatch-core-plan.md` "Dispatch 체인" 절 (A)
분기). 그래서 `refA→refB` 전환은 이전 클로저가 `nextValue=refB`로 먼저
불려 `refA`를 언바인딩하고, 그 다음 `process(inst,k,refB,index)`가
`refB`를 바인딩하는 두 단계로 자연히 갈림 — `process`가 old-vs-new diff를 따로 계산할
필요가 없어짐(그 일을 클로저가 매번 정확히 대신 해줌). **`process` 쪽엔
여전히 `Relate`가 필요** — "spurious하게 같은 Ref가 재발행되면 재통지
skip"이라는 dedup은 `process`가 "이전에 뭐가 있었는지"를 알아야 하는데,
그건 인자로 안 들어오고(클로저가 받는 건 다음 값이지 이전 값이
아님) 오직 여러 호출을 가로지르는 저장소로만 알 수 있음
(`base/dispatch-core-plan.md` "핸들러 내부 상태 저장" 절이 이런 경우엔 `Relate`가 여전히 맞다고 한 그 사례):

```lua
local relate = Relate()  -- Ref-leaf handler 전용, (inst,k)별 마지막으로 바인딩한 Ref 기억 —
                          -- process의 spurious 재바인딩 dedup 전용(클로저 캡처로는 대체 불가)

RefLeafHandler.isHandlable(inst, k, v) =
    type(k) == "number" and isRef(v) and not isPreRef(v) and not isPostRef(v)
    -- [2026-08-14 열두 번째 세션 정정] PostRef 도입(아홉 번째 세션) 당시 이 자리가
    -- 안 갱신돼 있었음 — 아래 "타입/판별" 절의 최종 공식과 일치시킴
    -- [2026-08-18 구현 전 QA] type(k) == "number" 체크가 빠져 있었음 — leaf 바인딩은
    -- 배열 전용이고(사용자 확정: "배열 전용이 맞음"), 짝인 ObserverEffectLeafHandler엔
    -- 이 체크가 필수라고 이미 명시돼 있었음. 빠지면 named 자리로 흘러온 Ref를 잡으려는
    -- HANDLER_PRIORITY_FALLBACK 가드(아래 "동적 경로 가드")가 죽은 코드가 된다.

function RefLeafHandler.process(inst, k, v, index)
    local old = relate:GetStrong(inst, k)
    if old ~= v then  -- 이미 같은 Ref가 이 자리를 차지 중이면 재통지 skip
        bindLifetime(inst, v)  -- v가 이미 다른 자리에 살아있으면 여기서 즉시 error —
                                -- 이중 배치 방지("이중 배치 방지" 절 참고), 별도 Relate 불필요
        v:Set(inst)
    end
    relate:SetStrong(inst, k, v)
    return function(nextValue)
        -- nextValue는 nil이거나 같은 핸들러가 곧 처리할 새 Ref(타입 보장됨) — v는
        -- 이 process 호출이 만든 클로저가 직접 캡처(Relate 재조회 불필요)
        if nextValue ~= v then
            unbindLifetime(v)  -- 점유 해제 — 이후 v는 다른 자리에 다시 bindLifetime 가능
            v:Set(nil)  -- 매 :Set()마다 콜백 재통지되는 기존 Ref 규칙(위 "해소됨 —
                        -- 반복 재설정 가능" 항목)을 그대로 재사용, 새 알림 경로 아님
            -- [정정, 2026-08-13 감사] relate 정리는 반드시 이 분기 *안*에 있어야
            -- 함 — 밖에 두면 spurious 재발행(nextValue == v)에서도 기록이
            -- 지워져, 곧바로 이어지는 process가 `old ~= v`를 항상 참으로 보고
            -- `v:Set(inst)`를 재실행함(콜백 헛 재통지). 즉 아래 dedup 항목이
            -- 약속한 "spurious면 둘 다 스킵"이 성립을 안 했음.
            if relate:GetStrong(inst, k) == v then relate:SetStrong(inst, k, nil) end
        end
    end
end
```

- **retractor가 언바인딩 전담, `process`는 바인딩 전담** — 겹치는 diff
  로직이 없음. `nextValue == v`(같은 Ref 객체가 스스로 재발행된
  spurious한 경우)만 둘 다 스킵해 콜백이 `nil`→`inst`로 헛되이 두 번 안
  불리게 함.
- **children 배열 리터럴 `Ref`도 같은 코드 경로를 그대로 씀** — 그 경우
  이전 클로저가 (StoreBind 경로가 아니라 이 리터럴 구성 자체가 처음이므로)
  아예 없고 `relate:GetStrong(inst,k)`도 `nil`이라 `process`가 바로
  `v:Set(inst)`로 끝남. "1회성 리터럴 구성"과 "반복 재바인드"가 하나의
  구현으로 자연히 커버됨, 케이스 분기 불필요.
- **타입: 비-nilable `T`도 정당한 용도(사용자 확인, 2026-08-12 여덟 번째
  세션)** — `Ref`는 "채워지길 기다리는 박스"뿐 아니라 "이미 확정된 값을
  여기저기서 부작용 없이 읽는" 용도로도 쓰일 수 있어 `Ref<T>`(T가
  non-nilable)를 계속 지원할 이유가 있음. 위 언바인딩(`old:Set(nil)`)이
  실제로 발생하는 자리는 **Store/Modifier 필드에 놓여 재바인드/retract가
  가능한 `Ref`뿐**이므로, 그 자리에 놓을 `Ref`는 **호출자가 직접
  `Ref<<T?>>(...)`로 명시**할 것 — 이미 있는 "초기값이 `nil`이면 명시적
  제네릭 적용으로 타입을 넓힌다"는 관용구(위 "제네릭 시그니처" 절)를
  그대로 재사용하는 것뿐, 새 타입 규칙 추가 아님. 프레임워크가 자동으로
  감지해 넓혀주지 않음 — non-nilable `T`로 선언해놓고 Store/Modifier
  자리에 놓으면 런타임에 `.Value`가 타입과 어긋나게 될 수 있는 caller
  책임의 UB(Luau 타입은 런타임에 지워짐, 다른 UB 케이스들과 같은 결).
- **Destroy와는 무관 — 별도 처리 없음(사용자 확정).** `Ref`의 언바인딩은
  오직 위 재바인드/retract 경로에서만 일어나고, 대상 Instance가
  `Destroy()`되는 것과는 별개 — Ref 자신은 Destroy를 감지하지도, 반응하지도
  않음. `Ref<Frame?>`가 이미 Destroy된 Frame을 계속 들고 있는 채로 남는 건
  정상적으로 가능하고, 그 이후 읽고 쓰는 건 그냥 UB(라이브러리가 방어
  안 함 — `:Wait(thread)`에 이미 죽은 thread를 넘기는 기존 UB와 같은 결).
  Destroy 시점에 실제로 정리가 필요하면 `Effect`(내부적으로 `bindLifetime`/
  `Observer` 위에서 동작, 또는 Roblox가 Destroy 시 알아서 `Disconnect`해주는
  이벤트 안에 로직을 두는 기존 관례)를 쓰도록 문서가 유도할 것 — Ref
  자신에 Destroy-awareness를 얹는 건 오버엔지니어링.

### 이중 배치 방지 — `question.md` 0-W 해소, (a) 선택 (2026-08-14 열한 번째 세션)

**같은 `Ref` 객체를 두 자리에 동시에 놓으면 뒤에 놓은 자리가 앞 자리의
바인딩을 조용히 지우는 문제**(`Frame1{r}`/`Frame2{r}`처럼 같은 `r`을 두
Frame의 children 배열에 각각 리터럴로 놓으면 — `Ref`는 항상 children
배열 아이템으로 놓이므로 `k`는 문자열 `"Ref"`가 아니라 그 자리의 배열
인덱스(숫자) — `r:Set(inst1)` 다음 `r:Set(inst2)`가 에러 없이 덮어씀,
`inst1` 자리가 나중에 retract되면 `r:Set(nil)`이 `inst2`의 정당한 값까지 지움)를
**즉시 error로 막기로 확정** — `Slot`의 `claimOwner`, `PreRef`/`PostRef`의
`_fired`, `Attribute`의 이름 claim과 같은 급의 방어를 `Ref`에도 채택.

**메커니즘 — 새 `Relate`를 안 만들고 `bindLifetime`/`unbindLifetime`을
그대로 재사용.** `bindLifetime(inst, value)`은 이미 자기 내부에 "이 value가
이미 다른 곳에 살아있는 바인딩을 갖고 있으면 즉시 error"라는 가드를 갖고
있음(`base/lifecycle-pattern.md`의 `canBound` 게이트) — `Ref`가 바인딩될
때마다 이 가드를 그대로 통과시키면 이중 배치가 저절로 막힘. 위
`RefLeafHandler.process`의 `bindLifetime(inst, v)`/`unbindLifetime(v)` 호출이
그것 — 실제 바인딩이 일어나는 분기(`old ~= v`)에서만 걸어서 spurious
재발행(같은 `v`가 다시 오는 경우)엔 안 걸림, 실제 언바인딩이 일어나는
분기(`nextValue ~= v`)에서만 풀어서 그 뒤 다른 자리에 재바인딩 가능.

**기존 dedup용 `relate`와는 별개 관심사** — `relate`는 "이 슬롯에 마지막으로
뭐가 있었는지"(spurious 재발행 dedup)를 기억하고, `bindLifetime`은 "이 `Ref`
객체가 지금 어딘가에 살아있게 물려 있는지"(이중 배치 방지)를 판정함. 서로
다른 축이라 하나가 다른 하나를 대체 못 함 — 계속 둘 다 필요.

**children 배열 리터럴 경로도 같은 코드를 그대로 타므로 자동으로 커버됨**
(`Frame1{r}`/`Frame2{r}`가 원래 문제였던 그 케이스) — 리터럴 구성은
`old`가 항상 `nil`이라 매번 `bindLifetime`이 불리고, 두 번째 자리에서
`r`이 이미 살아있는 바인딩을 갖고 있으니 그 즉시 에러.

`question.md`의 원 형제 프리미티브 대조 표(`Ref` 행 "없음")는 해소로 갱신,
상세는 `archive/question-resolved.md`.

### `phase` 옵션 폐기 → 위치로 표현, `PreRef` 신설 (2026-08-07 세 번째
세션 — 이 절이 당시 쓰던 `CreatedRef(fn, ...)` 래퍼 이름 자체도 이후
아홉 번째 세션에서 폐기됨, 위 "바인드 방법" 절 참고)

**children 배열에 놓는 Ref에 `{phase="created"|"mounted"}` 옵션으로 두
타이밍을 고르게 하던 것 자체를 없앤다.** `base/dispatch-core-plan.md`의
"확정된 디스패치 모델" 절에
새로 추가된 순서 보장(배열 파트는 index 순서대로, 그 다음 해시 파트)
덕분에, 같은 인스턴스 안에서 **일반 `Ref`를** 다른 children보다 앞/뒤
어디에 놓느냐가
이미 "그 형제가 마운트되기 전/후"를 그대로 결정함 — 각 자식은 자기
서브트리까지 전부 동기적으로 마운트를 끝내야 다음 형제로 넘어가므로,
"마지막에 놓기"만으로 "모든 자식 마운트 후" 의미가 공짜로 나옴. 별도
옵션 문법을 유지할 이유가 없어짐. **(아래 `PreRef`는 이 위치-의존 규칙의
예외 — 위치 영향을 아예 안 받고 호이스팅됨, 해당 절 참고.)**

**단, "프로퍼티/이벤트 세팅보다도 먼저"는 위치만으론 못 푼다.** 배열
파트가 해시 파트보다 항상 먼저 처리된다는 보장은 **그 인스턴스의 최초
props 테이블에 리터럴로 존재하는 항목에 한정**됨 — Modifier를 거쳐
flatten된 값은 해시 파트(프로퍼티 키)로 존재하게 되고, Store를 거쳐
나중에 도착하는 값은 애초에 이 최초 스캔 자체를 벗어난 시점(process/retract
재귀 경로)에 도착하므로 이 보장 밖. 그런데 "프로퍼티보다 먼저 채워져야
한다"가 실제로 필요한 이유가 있음 — quad-roblox 이벤트는 `self(Instance)`를
안 주기로 확정했으니(아래 절) self 접근은 Ref로 해야 하는데, Roblox
이벤트 중 일부(`ChildAdded`/`DescendantAdded`/`Changed`류)는 유저
인터랙션을 기다리지 않고 **setup 도중 프로퍼티 대입/Parent 세팅 자체의
부작용으로 동기적으로 발화**할 수 있음 — 이때 이벤트 핸들러가 아직 안
채워진 self-ref를 읽으면 터짐.

**해결**: 이 케이스만 별도 타입 `PreRef`로 분리.
- **구현은 `Ref` 그대로 재사용**(같은 `.Value`/`:Set()`/`:Callback()`/
  `:Wait()` API) — 브랜드 태그만 다른 nominal 타입. 런타임 코드 중복 없음.
  **소스 파일은 분리(2026-08-07 여섯 번째 세션)**: `Ref`는 이제 그 자체로
  충분히 완결된 프리미티브고 `PreRef`도 "children 배열 전용, 위치 무관
  호이스팅"이라는 특이한 제약을 가진 별개 프리미티브라, 기존 프리미티브당
  1파일 컨벤션(`modifier-plan.md`/`slot-plan.md`류, Blocker/Effect를
  같은 이유로 분리한 2026-08-07 네 번째 세션과 같은 판단)을 따라
  `Ref.luau`/`PreRef.luau` 두 파일로 쪼갬 — 런타임 로직은 여전히 공유
  (`PreRef.luau`가 `Ref.luau`를 그대로 불러다 브랜드 태그만 얹음), 파일
  분리는 순수 조직 문제라 위 재사용 결정과 상충 없음. `base/architecture.md`
  소스트리에 반영 완료.
- **오직 children 배열의 리터럴 아이템으로만 놓을 수 있다** — **Modifier
  필드 값으로도, Source/Store 값으로도 들어갈 수 없게 타입으로 차단.**
  - Modifier 필드로 막는 이유: 거기 들어가면 flatten 후 해시 파트로
    존재하게 돼 "배열 파트가 먼저"라는 보장 자체를 벗어남. 게다가
    Modifier는 여러 인스턴스에 재사용되는 값인데 PreRef는 정의상 "이
    인스턴스 하나의 construction 훅"이라 애초에 공유할 이유가 없음 —
    허용해도 얻는 유스케이스가 없는 오버엔지니어링.
  - Source/Store 값으로 막는 이유: Store 값은 항상 process/retract 재귀
    경로로 도착하는데, 그 경로는 정의상 최초 배열 스캔보다 나중(또는
    아예 스캔 밖)이라 "프로퍼티보다 먼저"를 구조적으로 만족시킬 방법이
    없음 — `State<Modifier>`를 막기로 한 것(`modifier-plan.md` 7번,
    2026-08-09 세션부터 `isModifier` 기반 명시적 error)과 정확히 같은
    원칙의 재적용.
- **`PreRef`는 배열 안 위치의 영향을 안 받는다 — 호이스팅.** 일반
  `Ref`와 달리, 같은 인스턴스의 배열 파트 안에서 다른
  children/`Ref`보다 뒤에 적었어도 그것들보다 먼저 fire됨(자바스크립트
  함수 선언 호이스팅과 같은 느낌으로 문서화). 이유: PreRef의 존재
  목적 자체가 "이 인스턴스에 뭐가 됐든 일어나기 전에" 채워지는 것인데,
  단순 위치 기반 순서만 따르면 그보다 앞선 형제(다른 child)가 먼저
  마운트되면서 그 형제가 부모에 Parent될 때 부모의 `ChildAdded`류가
  동기 발화할 수 있어 PreRef가 막으려는 문제가 그대로 재현됨. 그래서
  base 드라이버는 위 본체 루프(배열→해시 순서 계약)를 돌기 **전에** 별도의
  작은 pre-pass로 배열 파트를 훑어 `PreRef` 항목만 먼저 전부 fire하고,
  그 다음 나머지(children/일반 Ref/프로퍼티/이벤트)를 평소처럼 본체
  루프로 처리하면 됨 — 이 pre-pass는 오직 `PreRef` 타입만 골라내므로
  범위가 좁고, "확정된 디스패치 모델" 절의 배열→해시 순서 계약과 별개로 그
  앞에 얹히는 것.

  **⚠️ [2026-08-22 용어] 이 문서가 여러 곳에서 쓰는 "두 패스"는 이
  본체 루프의 옛 이름이다.** `Dispatch.drive`의 실제 구현은 **단일 일반화
  `for` + `type(k) == "number"` 분기** 한 번이고(`F-4-1`,
  `base/dispatch-core-plan.md`), "배열 파트 전체가 해시 파트보다 먼저"는
  그 루프가 지키는 **계약**이지 루프를 두 번 돈다는 뜻이 아니다. 아래
  "두 패스보다 먼저"/"두 패스가 전부 끝난 뒤" 같은 **시점** 표기는 그대로
  유효하다 — pre-pass와 `postRefList` 소비 루프가 본체 루프의 앞뒤에
  붙는다는 뜻이고, 그건 이번 정정과 무관하다. **다만 "두 패스로
  처리한다"처럼 구현을 단정하는 용법은 폐기**다.
  - **복수 `PreRef` 간 순서(2026-08-07 아홉 번째 세션 확정, 2026-08-14
    아홉 번째 세션 재확인) — 새 규칙 불필요, 배열 index 순서 그대로
    보장.** 같은 인스턴스에 `PreRef`가 여럿 있으면, 이 pre-pass는 위
    "props 순회 순서" 절이 이미 확정해둔 "배열 파트는 index 순서대로"
    계약을 그대로 재사용해 리터럴 순서대로 fire함 — 서로 다른 우선순위/
    순서 개념을 별도로 만들 필요 없음(호이스팅은 "PreRef 전체 대 나머지"에만
    적용되는 규칙이지, "PreRef끼리"에는 적용될 게 없음 — PreRef끼리는
    그냥 평범한 배열 순회). 아래 `PostRef`도 같은 규칙.
    - **왜 보장까지 하는가(2026-08-14 아홉 번째 세션, 한 번 미보장으로
      뒤집었다가 철회)** — 잠깐 "계열 안 순서에 의존하는 코드가 생겨선
      안 된다"는 이유로 미보장으로 갔었으나 같은 세션에 되돌림. 결정적
      반례는 사용자가 든 **`FastQuery(...) -> PreRef`류 조합**: 어떤
      팩토리가 `PreRef`를 반환하며 뭔가를 미리 해결해두면, **배열에서
      그 뒤에 오는 `OnCreated`가 "그게 이미 끝났다"를 전제로 동작**할 수
      있음 — 위치로 선후를 표현하는 이건 잘못된 구조가 아니라 이
      배열이 원래 제공하는 정당한 합성 방식임(children 마운트 순서가
      위치로 정해지는 것과 같은 성격). 비용도 0 — pre-pass가 어차피
      index 순서로 훑고, `base/dispatch-core-plan.md`가 이미 배열 파트
      index 순서를 **백엔드 이식성 때문에 명시적 계약**으로 못박아
      뒀으므로 여기서 새로 약속하는 게 하나도 없음(=미래 구현 자유를
      내주는 것도 없음). 상세한 양쪽 논거는
      `archive/preref-order-unguaranteed-withdrawn.md`.
    - **다만 스타일 권고는 남김**: 순서에 의존해야 할 정도로 두 훅이
      얽혀 있으면 대개 **하나의 훅 안에서 순서대로 부르는 게** 의도가
      더 잘 드러남 — 보장은 하되, 위 `FastQuery`처럼 "앞의 것이 뒤의
      것의 전제를 만들어주는" 명시적 합성이 아니면 기대지 말 것.
  - **호이스팅의 실제 구현 = "물리적 재배치"가 아니라 "완전히 별도의
    선행 스캔"(2026-08-07 아홉 번째 세션 후속, 사용자 질문에 답변).**
    `Dispatch.drive(inst, flattened)`는 같은 `flattened` 배열을 **두 번
    순회**한다(**[2026-08-14 아홉 번째 세션]** 그 뒤에 `postRefList` 소비가
    하나 더 붙지만, 그건 배열 재순회가 아니라 pre-pass가 만들어둔 짧은
    목록 하나를 도는 것 — 아래 "`PostRef`" 절) — (1) pre-pass: 배열 파트
    전체를 index 순서대로 훑으며
    `isPreRef(v)`인 슬롯을 찾아 그 자리에서 fire하고 즉시 **`flattened[i]
    = ProcessedPreRef`**로 소진(`nil`이 아님, 2026-08-07 열 번째 세션 정정: `nil`로
    지우면 그 순간 테이블이 "구멍 있는" 상태가 되어 이어지는 (2)의 순회
    순서 보장 자체가 깨질 위험이 있음 — 정확히 이 pre-pass가 의존하는
    바로 그 보장이라 치명적. **[주의, 2026-08-09 열한 번째 세션] Ref
    자신의 콜백/대기자 배열은 이 이유가 적용되지 않아 `nil` 소진으로
    되돌아갔음(위 "Ref 일반화" 절 참고) — 여기 PreRef pre-pass는 순서
    보장이 실제로 필요한 별개 케이스라 실재하는 센티널 소진이 계속 맞음, 두
    사례를 혼동하지 말 것**). **[정정, 2026-08-14 두 번째 세션] 소진 값은
    `None`이 아니라 전용 센티널 `ProcessedPreRef`(단일 `{}`, `None`과 같은
    급의 유니크 키 — 사용자 제안).** 옛 설계는 소진 값을 `None`으로 뭉뚱그려
    "그 자리가 원래부터 빈 자리"였던 경우(`props.Ref or None`)와 "한때
    PreRef였다가 방금 fire되어 소진된 자리"를 구별 못 했고, 그 결과
    아래 "Length/Offset" 계약(`base/dispatch-core-plan.md`, 2026-08-09
    여섯 번째 세션 확정)이 "이 위치를 처음 매치한 Handler가
    `setLength`/`setOffsetSource` 등록 책임을 진다"고 못박아 놨는데도
    `None` 소진 슬롯은 정의상 어떤 Handler도 안 거쳐서(아래 참고) "그럼
    누가 그 등록을 실제로 호출하는가"가 문서 어디에도 없는 갭이었음
    (2026-08-14 첫 번째 세션 조사에서 발견). `ProcessedPreRef`로 소진처를
    분리하면 이 갭이 구조적으로 사라짐 — 아래 `ProcessedPreRefHandler`
    참고. (2) 그 다음에야 비로소 평소의 배열→해시 본체 루프가
    **같은 테이블**을 다시 순회 — 이때 `ProcessedPreRef`로 소진된 슬롯은
    **정상 `Dispatch.process` 경로를 그대로 탄다**(아래
    `ProcessedPreRefHandler`가 매치, **[정정] 예전엔 `None`이라 본체
    루프 자신이 `if v == None then continue end`로 직접 건너뛰고 어떤
    Handler도 안 거쳤으나, 지금은 일부러 정상 경로를 태워 Length/Offset
    등록 책임을 기존 계약에 특수 취급 없이 그대로 얹음**). **[정정,
    2026-08-18 구현 전 QA] 원래부터 빈 자리인 `None`도 이제 정상 경로를
    탄다** — 여기 "여전히 두 패스 루프가 직접 건너뜀"이라고 적혀 있었으나
    그 스킵 분기 자체가 폐기됐다(아래 "[전면 정정, 2026-08-18 …]" 항목).
    지금은 `NoneHandler`(재귀만) → `NilHandler`(등록 담당)를 거친다.
    두 센티널은 **매치되는 Handler가 다를 뿐** 둘 다 정상
    `Dispatch.process` 경로다. "호이스팅"은 PreRef를 배열의 맨
    앞으로 물리적으로 옮기는 게 아니라, **PreRef 전용 선행 루프가
    통째로 먼저 끝난 뒤에야 나머지 처리가 시작된다는 뜻** — 그래서
    소스에서 마지막 child로 적었어도 무조건 다른 모든 처리보다 먼저
    fire됨. **PreRef 슬롯을 소진시키는 게 단순 최적화가 아니라 정확성
    요건인 이유**: 아래 "동적 경로 가드" Handler가 `(v=PreRef)`를
    매치하면 무조건 `error`를 던지므로, pre-pass가 슬롯을 안 지우면
    두 번째(정상) 패스가 이미 정당하게 처리된 그 PreRef를
    `Dispatch.process`로 다시 넘기게 되고, 그러면 이 가드 Handler가
    엉뚱하게 매치되어 **정상적인 PreRef 사용에도 에러가 터짐** — 소진은
    이 오탐을 막기 위해 반드시 필요(`ProcessedPreRef`는 `isPreRef(v)`가
    거짓이라 이 가드 Handler와는 애초에 안 겹침).
  - **`ProcessedPreRefHandler` — 소진된 슬롯이 Length/Offset에 "0 기여"를
    등록하는 전담 Handler (2026-08-14 두 번째 세션, 사용자 제안 — 위 갭의
    해소).**
    ```lua
    ProcessedPreRefHandler.priority = <매우 높음, NoneHandler와 동급>
    ProcessedPreRefHandler.isHandlable(inst, k, v) = (v == ProcessedPreRef)
    function ProcessedPreRefHandler.process(inst, i, v)
        -- [순서 정정, 2026-08-18 감사] setOffsetSource가 먼저 — setLength가
        -- 끝에서 gatedRecompute를 경유해 recompute를 돌리므로
        -- (`base/dispatch-core-plan.md`의 해제 순서 계약)
        Dispatch.setOffsetSource(inst, i, None)
        Dispatch.setLength(inst, i, 0)
        return function() end  -- no-op retract, 이 자리는 fire가 끝나
                                -- 되돌릴 상태 자체가 없음
    end
    ```
    `isHandlable`이 `v == ProcessedPreRef`만 잡으므로 배열 파트 전용(해시
    파트엔 이 센티널이 등장할 경로 자체가 없음). 이걸로 `base/
    dispatch-core-plan.md`의 "Length/Offset" 절이 확정해둔 "그 위치의
    말단 Handler가 등록 책임을 진다"는 계약을 특수 취급
    없이 그대로 만족시킴(**[정정, 2026-08-18]** 그 계약은 예전엔 "처음
    매치한 Handler"라고 적혀 있었으나 중간 노드가 매치되는 경우가 있어
    말단 기준으로 정정됨) — 매치되는 Handler 자신이 곧 등록자라 "누가
    등록하는가"라는 질문 자체가 안 생김. 반환하는 retract는 하드코딩된
    no-op인데, 이건 "PreRef는 취소 개념이 없다" 절(아래)이 말하는 것과
    같은 이유 — fire가 이미 실행한 부작용은 되돌릴 수 없으므로 이 자리가
    dispatch 체인에 실제로 올라가 있어도(**[정정] 예전 서술과 달리 이제는
    올라가 있음** — 아래 참고) retract가 할 일이 없는 것뿐.
  - **[전면 정정, 2026-08-18 구현 전 QA] 배열 파트의 `None`도
    `Dispatch.process`를 탄다 — 옛 "명확화(2026-08-09 열한 번째 세션)"는
    전제가 거짓이었음.** 그 서술은 *"배열 파트의 `None`은 애초에
    `Dispatch.process` 자체를 절대 안 탄다(본체 루프가
    `if v == None then continue end`로 걸러냄)"*, 따라서 *"`k=number`
    조합으로 `NoneHandler`가 실제로 매치되는 경우는 없음"*이라고 했는데,
    리터럴 `Frame{None}`만 보면 맞아 보여도 **`Frame{ State<Slot|None> }`
    처럼 반응형 값이 `None`을 내놓으면 그 `None`은 `StoreBind`의 재귀를
    타고 `Dispatch.process`에 그대로 도착**한다(사용자 지적).
    지금 확정된 모델은:
    - `Dispatch.drive`에 `None` 스킵 분기가 **없다** — 전부 `process`를 탄다.
    - `NoneHandler`는 `k` 타입과 무관하게 매치되고, 하는 일은
      **`nil`로 바꿔 재귀하는 것 하나뿐**.
    - `k`가 숫자면 그 재귀가 **`NilHandler`**(`k=number and v==nil` 전용,
      `base/dispatch-core-plan.md`의 "`NilHandler`" 절)에 도착해 거기서
      `setLength(0)`/`setOffsetSource(None)`을 등록한다.
    즉 이 자리에서 "매치되는 경우가 없다"가 아니라 **매치되고, 정상
    경로로 0 기여가 등록된다**가 정확한 설명이다.
  - **M0 스파이크 검증 항목 갱신(2026-08-07 열 번째 세션)**: 위 "props
    순회 순서" 절은 `{a=1, 2, b=3}`류 **구멍 없는** 테이블에서 배열
    파트가 해시 파트보다 먼저 나온다는 것만 실측 확인됨(2026-08-07 세
    번째 세션). 같은 세션에서 사용자가 직접 `{[1]=1,[2222]=2222,
    [211]=211,...}`류 **키가 듬성듬성한(sparse)** 테이블을 REPL로
    실측해, 그런 테이블은 순회 순서가 index 오름차순이 전혀 아님(해시
    버킷 순서)을 확인함 — 그래서 위 pre-pass는 (nil이 아니라) 실재하는
    센티널(`ProcessedPreRef`, 2026-08-14 두 번째 세션 이전엔 `None`)로
    소진해 테이블을 "구멍 없이 촘촘한" 상태로 계속 유지하는 전략으로
    이 위험을 원천 회피함(검증 불필요, 애초에 구멍을 안 만드므로).
    **여전히 M0에서 검증해야 하는 건 다른 케이스**: `props.Modifier`/
    `props.Ref`를 caller가 안 넘겨 생기는 리터럴 `nil`-hole(`{nil, ref,
    child}`, `research/pre-implementation-audit.md` 1-5)은 caller가 직접 쓰는 raw
    Lua 리터럴이라 프레임워크가 `None`으로 대신 못 채워줌 — 이번 REPL
    실측으로 그 케이스의 실제 위험도가 이전 서술("뒤 항목까지 무시될 수
    있음", 국소적 피해로 서술돼 있었음)보다 훨씬 큼이 드러남: 구멍이 하나만
    생겨도 **테이블 전체**가 해시 파트 취급으로 넘어가 그 인스턴스의
    배열 파트 전체가 순서 보장을 잃을 수 있음. M0 스파이크에서 반드시
    실측하고, 심각하면 "이런 nil-hole은 raw 리터럴로 하지 말고 항상
    `props.Modifier or Modifier()`처럼 non-nil을 보장하라"는 컨벤션
    문서화까지 검토할 것.
  - **pre-pass는 어디 사는가 — `Dispatch.drive(inst, flattened)` 자신,
    새 함수 불필요(2026-08-07 아홉 번째 세션, 사용자 제안 검토 후 확정).**
    `Dispatch.drive`가 이미 `(inst, flattened)`를 받아 배열→해시 순서로
    도는 함수로 확정돼 있으므로(**[2026-08-22 정정]** 여기 "두 패스를 도는
    함수"라고 적혀 있었으나 그 순서는 **계약**이고 구현은 단일 일반화
    `for`다 — `base/dispatch-core-plan.md`의 `F-4-1` 정정 문단),
    그 앞에 좁은 pre-pass 한 줄을 얹는 것만으로
    충분 — `Handler.process`와 이름이 겹치는 새 `Dispatch.process(inst,
    flatten, prerefs)`류 함수를 따로 만들 필요가 없음(그 이름은 이미
    다른 뜻으로 쓰이는 `Dispatch.process(inst,k,v)` 오케스트레이터와 겹쳐서
    안 좋음). **`flatten(nonFlatten) -> flatten` 함수 자체에 얹는 방안은
    검토 후 기각** — flatten은 Modifier 값을 합치는 순수 변환(현재 `inst`를
    안 받음). 원래 근거는 "`archive/existing-instance-bind-rejected.md`가
    다루던 '이미 마운트된 Instance 재바인드 시 Default→실값 flatten을 다시
    해야 하는가' 질문이 열려있어 flatten이 한 인스턴스 생애주기 동안
    **여러 번 재호출될 가능성이 있다**"였고, **[2026-08-14 세션] 그
    재바인드 기능 자체가 기각되며 이 위험은 사라졌지만 결론(기각)은
    유지** — flatten은 여전히 `inst`를 모르는 순수 변환이라 fire 지점으로
    부적절함 — 여기에 PreRef fire를 얹으면 재바인드마다
    PreRef가 또 fire되어 "이 인스턴스 하나의 construction 훅"이라는 PreRef의
    정의 자체가 깨짐. `Dispatch.drive`는 최초 마운트 시 정확히 한 번만
    불리는 게 이미 전제라 이 위험이 없음.
  - **동적 경로로 도착한 PreRef는 런타임에도 명시적으로 에러
    (2026-08-07 아홉 번째 세션, 사용자 제안 채택) — 아직 문서화 안 돼
    있었음, 지금 확정.** 위 "Modifier 필드로 막는 이유"/"Source/Store
    값으로 막는 이유" 절은 **타입 차단**만 다뤘음 — Luau 타입은 런타임에
    지워지므로(`:Peek`/`Overridden`/버그로 타입을 우회해 PreRef가 Modifier나
    Store 값으로 실제로 흘러들어오는 경우), 런타임에도 방어가 필요함.
    전용 `Handler`를 하나 등록: `{ priority = HANDLER_PRIORITY_FALLBACK,
    isHandlable = function(inst,k,v) return isPreRef(v) end, process =
    function(inst,k,v) error(`PreRef binding should be array index item,
    but got {typeof(k)}`) end }`(**[2026-08-18, `/code-review high`로
    누락 발견 — `PostRef`의 "동적 경로 가드 Handler도 거울상으로 하나 더" 절/
    `effect-plan.md`의 "동적 경로 가드" 절과 짝을 맞춤]** 에러 메시지에
    실제 `k` 타입을 실을 것) — `k` 타입은 안 가림(숫자든 문자열이든
    `isPreRef(v)`만 보고 매치). `NoneHandler`와 같은 결의 "한 값 종류만
    전담하는 Handler"
    패턴 재사용, 새 메커니즘 아님. **[2026-08-14 열한 번째 세션] 우선순위는
    `HANDLER_PRIORITY_FALLBACK`**(무조건 매치하는 하드 블록이 아니라
    `Tag`/`Attribute`와 같은 "base가 소유하지만 백엔드/특정 자리에서
    평범한 우선순위로 자기 핸들러를 등록하면 덮어쓸 수 있는" 자리 —
    지금은 그 자리를 아무도 안 가져가서 항상 이 가드가 매치돼 에러가
    나지만, 나중에 named 자리 바인드 같은 실제 기능이 확정되면 base
    가드를 건드리지 않고 그 기능의 Handler를 평범한 우선순위로 하나
    등록하는 것만으로 자연히 우선함, `base/dispatch-core-plan.md`의
    "base가 소유하는 핸들러와 주입되는 엔진 op" 절). 이
    Handler는 **`Dispatch.process`/`getHandler`의 정상 우선순위 스캔에
    등록**되는 반면(pre-pass처럼 그 밖에서 도는 게 아님), 리터럴 배열의
    `PreRef`는 pre-pass가 fire와 동시에 해당 슬롯을 소진(**[정정,
    2026-08-14 두 번째 세션] `None`이 아니라 `ProcessedPreRef` 처리**,
    위 "호이스팅의 실제 구현" 절)해 **이 가드 Handler(`isPreRef(v)`만
    매치)에는 다시 노출되지 않게** 하므로(정상 본체 루프 스캔 자체엔
    `ProcessedPreRefHandler`를 통해 여전히 노출됨 — "스캔에 안 걸림"이
    아니라 "이 가드에 안 걸림"이 정확한 설명), 이 Handler가 실제로
    매치되는 경우는 오직 "타입이 막았어야 했는데 어떻게든 동적으로
    새어들어온" 버그 케이스뿐 — 그래서 no-op이 아니라 즉시 `error`.
  - **PreRef는 "취소"라는 개념이 없다 — 1회용, 재사용은 즉시 error
    (2026-08-12 여섯 번째 세션, 사용자 제안 채택).** `Ref`가 "다른 값으로
    교체되면 `retract`로 취소됨"이라는 의미의 취소를 가질 수 있는 건 정상
    우선순위 스캔의 `(inst,k)` 디스패치 체인에 실제로 참여해서임 —
    `Dispatch.retractFrom`이 그 체인을 대상으로 동작함. **[정정,
    2026-08-14 두 번째 세션] "그 체인에 올라간 적이 없다"는 근거는 더 이상
    정확하지 않음** — `ProcessedPreRefHandler` 신설로 소진된 슬롯도 이제
    정상 `Dispatch.process` 경로를 타 체인에 올라감(위 "호이스팅의 실제
    구현" 절). "취소 개념이 없다"는 결론 자체는 그대로 유효하지만 이유가
    바뀜: 체인에 없어서가 아니라, **그 자리의 retract가 하드코딩된
    no-op이기 때문** — PreRef의 fire는 `fn(inst)`를 실제로 실행하는
    부작용이라 애초에 "되돌릴 상태"가 없고, 그래서 체인에 올라가 있어도
    retract가 할 일 자체가 없음. 진짜 위험은 취소가
    아니라 **재사용**: 이미 한 번 fire된 `PreRef` 객체를 두 번째
    construction의 children 배열에 다시 놓으면, 거기서 등록하는
    `:Callback(fn)`이 "이미 채워져 있으면 즉시 1회 호출"이라는 규칙(위
    "Ref 일반화" 절) 때문에 **의도한 새 인스턴스가 아니라 첫 번째 fire
    때 남은 stale `.Value`로 조용히 호출**됨 — 에러도 안 나고 엉뚱한
    값을 들고 실행되는, 디버깅하기 아주 어려운 버그. `State`/`:With`를
    "clone 빌더가 아니라 매번 새 노드"로 확정했던 원칙(2026-08-07 세
    번째 세션, "`:With`도 새 State 노드")과 같은 클래스의 문제이자 같은
    해법.
    - **구현**: pre-pass가 첫 fire 때 해당 `PreRef` 객체에 내부 플래그
      (`_fired = true`)를 세팅. pre-pass가 배열을 훑다 `isPreRef(v)`인
      슬롯을 만났는데 그 객체가 이미 `_fired`면, fire하지 않고 그 자리에서
      즉시 `error("PreRef는 1회용 — 이미 다른 construction에 쓰인
      PreRef를 재사용할 수 없음, 매번 새로 만들 것")`. 위 "동적 경로 가드"
      Handler(정상 본체 루프에서 매치)와는 별개 코드 경로 — 이 가드는
      pre-pass 자신 안에, `_fired`가 아닌 정상 fire는 그대로 통과.
    - **관용구**: `Slot:List`의 `updateFn`처럼 반복 호출되는 자리에서
      `PreRef`가 필요하면 **호출마다 새 `PreRef()`를 만들 것** — 클로저에
      캡처해 여러 construction에 걸쳐 재사용하지 말 것. (참고: `Slot`
      자체는 요소 타입으로 `Ref`/`PreRef`를 이미 금지하고 있어(위
      "요소 타입 제약" 절, `slot-plan.md`) 이 관용구가 실제로 문제되는
      자리는 `updateFn` 안에서 호출하는 컴포넌트 함수 내부뿐임.)
- **일반 `Ref`도 값으로서는 Modifier 필드/Store 값 어디로든 전달될 수
  있음** — Store를 통해 나중에 도착하는 Ref는 그냥 도착한 그 순간
  처리하면 됨, phase 개념 자체가 필요 없음("만난 순간 처리"로 충분).
  **[한정, 2026-08-18 구현 전 QA] 다만 leaf 바인딩이 일어나는 자리는
  배열(숫자 키) 전용이다** — 옛 문장("Modifier/Store 어디든 자유롭게
  들어감")은 "named 해시 키에 놓아도 leaf 바인딩이 된다"로 읽혔는데 그건
  틀리다. 어디로든 **흘러갈** 수 있다는 뜻이고, 실제로 `Ref:Set(inst)`가
  일어나는 건 배열 자리뿐(아래 `RefLeafHandler.isHandlable`의 `k` 체크).
  **왜 배열 전용인가(사용자 논거, 그동안 어디에도 안 적혀 있던 것)**:
  `Ref`끼리는 **배열 index 순서가 통하므로**, "다른 `Ref` 처리를 먼저 해야
  하는 순서 의존"이 있을 때도 그걸 표현할 수 있게 하려는 것 —
  `PreRef`/`PostRef`의 "계열 안 fire 순서는 배열 index 순서" 보장과 같은
  결의 근거다. 컴포넌트 함수에 `Ref`를 named 파라미터로 넘기는 건 이와
  무관하게 얼마든지 가능(그건 그 함수의 인자일 뿐 leaf 바인딩이 아님).
- **quad v1의 `OnCreated` 특수 키는 이식하지 않는다.**
  `Ref():Callback(function(inst) end)`를 children 배열에 넣는 것만으로
  완전히 대체됨(여러 개 등록도 자연히 지원, 별도 특수 키 불필요) —
  v1 대비 빠진 기능처럼 보이지 않도록 이 대체 관계를 문서에 남겨둠.
- **`:Wait()`는 PreRef에도 그대로 유효해야 함.** PreRef 자신의 fire는
  항상 동기적이지만, `:Wait()`를 호출하는 코드가 `task.spawn`이 아니라
  순수 `coroutine`로 실행 중이었다면(Roblox `task` 스케줄러의 순서 보장이
  없는 컨텍스트) 호출 시점에 아직 안 채워져 있어 실제로 yield-resume이
  필요한 경우가 생김 — "항상 동기적이니 `:Wait()`는 즉시 리턴할 것"이라고
  단정해 구현을 특수화하면 안 됨, 그냥 보통 `Ref`와 동일한 대기자
  리스트/coroutine.yield 구현을 그대로 씀. **문서화 필요**: "채워졌는지
  먼저 확인, 없으면 `:Wait()`" 방어적 패턴을 권장 관용구로 명시(콜백이
  "이미 채워져 있으면 즉시 1회 호출"하는 것과 대칭되는, 값이 없을 수도
  있다는 걸 항상 코드가 스스로 확인해야 한다는 Ref 전체의 일관된 원칙).
- **프로퍼티/이벤트가 항상 children/Ref보다 나중에 세팅된다는 사실 자체는
  "고치지" 않는다** — 두 패스 순서를 뒤집거나 재배치하는 시도는
  오버엔지니어링으로 판단해 안 함(이걸 원하면 애초에 PreRef를 쓰면 됨).
  이 결정과 이유는 나중에 `quadnomicon` 콘텐츠로 문서화 예정
  (`research/documentation-content-map.md` 후보로 메모). **[보강,
  2026-08-14 아홉 번째 세션]** "두 패스가 **전부 끝난 뒤**"라는 타이밍은
  이제 아래 `PostRef`가 제공함 — 그건 두 패스의 순서를 건드리는 게 아니라
  그 뒤에 얹히는 것이라 이 결정과 상충하지 않음.

### `PostRef` — 두 패스가 전부 끝난 뒤 fire, `PreRef`의 거울상 (2026-08-14 아홉 번째 세션 확정)

**확정.** `research/lifecycle-hooks-plan.md`(현
`base/lifecycle-hooks-plan.md`) ② 절이 "지금은 구현 안 함, 백로그 후보"로
남겨뒀던 스케치를 사용자가 착수 선택지 **(a)**(pre-pass 공동 수집 +
두 패스 뒤 `postRefList` 소비)로 확정 — 근거는 "Pre/Post 둘을 지원 안 할
이유가 없고, 구현 난이도가 아주 낮음". 이걸로 `OnRendered`도 같이 채택됨
(`base/lifecycle-hooks-plan.md`).

**정의**: `PostRef`는 `PreRef`와 마찬가지로 **`Ref` 런타임을 그대로 재사용하고
브랜드 태그만 다른 nominal 타입**(`.Value`/`:Set`/`:Callback`/`:Wait` 동일,
`base/brand-plan.md`). 다른 점은 **fire 시점 하나뿐** — `PreRef`가 "이
인스턴스에 뭐가 됐든 일어나기 **전**"이라면, `PostRef`는 "이 인스턴스의
배열 파트(children/Ref)와 해시 파트(프로퍼티/이벤트)가 **전부 끝난 뒤**".

**세 Ref의 타이밍 대조(이게 전부임)**:

| 타입 | fire 시점 | 계열 안 상대 순서 |
|---|---|---|
| `PreRef` | 두 패스보다도 **먼저**(호이스팅 pre-pass) | 배열 index 순서 **보장** |
| 일반 `Ref` | **정해진 시점 없음** — 그 값이 dispatch에 도착한 순간(배열 위치/Store 도착 시점에 따라 달라짐) | (해당 없음) |
| `PostRef` | 두 패스가 **전부 끝난 뒤** | 배열 index 순서 **보장**(= `postRefList` push 순서) |

- 일반 `Ref`의 "언제 채워지는지 모른다"는 건 결함이 아니라 원래 계약임 —
  그래서 "이미 채워졌는지 먼저 확인, 없으면 `:Wait()`/`:Callback()`"이
  Ref 전체의 관용구로 이미 확정돼 있음(위 "Ref 일반화" 절). `PreRef`/`PostRef`는
  그 관용구를 안 써도 되도록 **시점을 계약으로 고정한** 두 특수 케이스.
- **계열 안 순서를 둘 다 보장하는 근거**는 위 `PreRef` 절의 같은 항목
  참고(`FastQuery(...) -> PreRef`류 조합, 비용 0, 이미 있는 배열 파트
  index 순서 계약의 귀결) — `PostRef`의 `postRefList`도 그 index 순서
  스윕이 만드는 목록이라 push 순서 = 배열 순서.

**보장 범위 — 무엇이 끝나 있고 무엇이 안 끝나 있는가(중요)**

`PostRef`가 fire될 때 **끝나 있는 것**:
- **이 인스턴스의 모든 자식**, 그리고 그 자식들의 **서브트리 전체**. 배열
  파트는 "각 자식이 자기 서브트리까지 전부 동기적으로 마운트를 끝내야 다음
  형제로 넘어간다"가 이미 계약이고(위 "`phase` 옵션 폐기" 절), `Slot`도
  마운트 시점에 자기 초기 요소를 그 자리에서 주입하며(`base/slot-plan.md`),
  `State<Frame>`류 store-bind도 최초 값을 그 자리에서 동기적으로 처리함
  (`base/dispatch-core-plan.md`) — 즉 배열 파트가 끝난 시점엔 **정적으로
  선언된 트리가 전부 완성**돼 있음. 사용자 표현 그대로 "중간 for문에서
  모든 Slot/`State<Frame>`/`Frame` 요소의 마운트가 처리되므로, 바로 뒤에서
  실행하면 모든 트리가 완성된 이후".
- **이 인스턴스의 모든 프로퍼티/이벤트**(해시 파트) — `PreRef`가 존재하는
  이유였던 "이벤트가 setup 도중 동기 발화" 문제의 반대편 끝.

**끝나 있지 **않은** 것**(문서화 필수, 이름만 보고 오해하기 쉬움):
- **이 인스턴스 자신이 부모에 붙는 것(`.Parent` 대입)** — 부모가 이
  인스턴스를 자기 배열 파트에서 처리하는 건 이 `drive`가 **끝난 뒤**임
  (`Frame { Frame {...} }`처럼 리터럴로 중첩하면 안쪽 `Frame` 호출이 먼저
  완결되어야 바깥 `Frame`의 props 테이블이 완성됨). 즉 `PostRef`는
  **자기 아래(서브트리)의 완성만 보장하고, 자기 위(조상 체인)는 아직
  없을 수 있음** — "화면에 올라간 시점"이 아님. `OnRendered`라는 이름이
  React `componentDidMount`(DOM 삽입 후)처럼 읽힐 수 있으므로 이 차이를
  `base/lifecycle-hooks-plan.md`와 사용자 문서에 명시할 것.
- **나중에 동적으로 도착하는 것들** — Store를 통해 뒤늦게 바뀌는 값,
  `Slot:Add`/`:List`로 나중에 추가되는 요소는 정의상 이 `drive` 밖의
  사건이라 당연히 포함 안 됨.

**메커니즘 — pre-pass 한 스윕으로 `PreRef`/`PostRef` 둘 다 처리**

새 전체 순회를 추가하지 않는 게 핵심(사용자 제안). `Dispatch.drive`의
기존 pre-pass가 이미 배열 파트를 index 순서로 한 번 훑고 있으므로:

1. **pre-pass(기존 루프에 분기 하나 추가)**:
   - `isPreRef(v)`면 지금까지처럼 **그 자리에서 즉시 fire**하고
     `flattened[i] = ProcessedPreRef`로 소진.
   - `isPostRef(v)`면 **아직 fire하지 않고**, 이 `Dispatch.drive` 호출
     하나에만 로컬인 평범한 배열 `postRefList`에 그 인스턴스를 push한 뒤
     **즉시** `flattened[i] = ProcessedPostRef`로 소진. 1회용 재사용 가드
     (`_fired`)도 **이 시점에** 세팅 — "슬롯이 소진되는 시점"과 "재사용이
     막히는 시점"을 `PreRef`와 동일하게 맞춤(실제 콜백 fire와 시점이
     갈리는 건 아래 3번뿐).
   - `postRefList`는 **`Relate` 같은 별도 저장소가 아님** — 이 함수
     콜스택 안에서만 살면 되므로 그냥 로컬 테이블.
2. **정상 본체 루프**(배열 → 해시)가 평소대로 돎. `ProcessedPostRef`로
   소진된 슬롯은 `ProcessedPreRef`와 **완전히 대칭적으로** 정상
   `Dispatch.process` 경로를 타고 아래 전담 Handler에 매치됨.
3. **두 패스가 끝난 뒤 `Dispatch.drive`가 `postRefList`를 순회하며 각
   `PostRef`를 fire.** 추가 비용은 전체 배열 재순회가 아니라 **실제
   `PostRef` 개수만큼의 순회**뿐. push 순서 그대로 돌면 되고, 그게 곧
   배열 index 순서라 위 표의 보장이 자동으로 성립(별도 정렬 불필요).

**`ProcessedPostRefHandler` — `ProcessedPreRefHandler`의 거울상, 새 규칙 없음**

```lua
ProcessedPostRefHandler.priority = <매우 높음, ProcessedPreRefHandler와 동급>
ProcessedPostRefHandler.isHandlable(inst, k, v) = (v == ProcessedPostRef)
function ProcessedPostRefHandler.process(inst, i, v)
    -- [순서 정정, 2026-08-18 감사] setOffsetSource가 먼저(위 ProcessedPreRefHandler와 동일 이유)
    Dispatch.setOffsetSource(inst, i, None)
    Dispatch.setLength(inst, i, 0)
    return function() end  -- no-op retract, PreRef와 같은 이유(되돌릴 상태가 없음)
end
```

`ProcessedPreRefHandler`(위 절)와 한 글자 차이 — "이 위치를 처음 매치한
Handler가 `setLength`/`setOffsetSource` 등록 책임을 진다"는 `base/
dispatch-core-plan.md` "Length/Offset" 절의 계약을 특수 취급 없이 그대로
만족시킴. `ProcessedPostRef`도 `None`이 아니라 **전용 센티널**(단일 `{}`)인
이유는 `ProcessedPreRef`와 동일 — "원래부터 빈 자리(`None`)"와 구별돼야
등록 책임 소재가 분명해지고, 배열에 구멍이 안 생김.

### 동적 경로 가드 Handler도 거울상으로 하나 더

`PreRef`와 똑같이, `PostRef`도 **children 배열의 리터럴 아이템으로만** 놓을
수 있음 — Modifier 필드/Source/Store 값으로는 **타입으로 차단**(이유도
동일: flatten되면 해시 파트로 존재하게 돼 "배열 파트" 전제를 벗어나고,
Store 경로로 뒤늦게 도착한 값은 "이 인스턴스의 construction 훅"이라는
정의 자체를 만족시킬 수 없음). 타입은 런타임에 지워지므로 정상 우선순위
레지스트리에 `{ priority = HANDLER_PRIORITY_FALLBACK, isHandlable =
isPostRef(v), process = error(`PostRef binding should be array index item,
but got {typeof(k)}`) }` Handler를 등록(**[2026-08-18]** 에러 메시지에
실제 `k` 타입을 실을 것 — `base/source-state-plan.md`의 "동적 경로 가드" 절)(`k` 타입 안 가림 — `PreRef`의 "동적 경로
가드" 절과 완전히 같은 이유로 `HANDLER_PRIORITY_FALLBACK`, 2026-08-14
열한 번째 세션) — pre-pass가 이미 소진시키므로 이게 매치되면 곧 타입
차단을 우회한 버그라는 뜻.

**1회용, 재사용은 즉시 error** — `PreRef`와 같은 `_fired` 플래그를 그대로
재사용(위 "PreRef는 '취소'라는 개념이 없다" 절과 같은 근거: 이미 fire된
객체를 다시 놓으면 stale `.Value`로 콜백이 조용히 잘못 호출됨). "취소
개념이 없다"도 동일 — 체인엔 올라가지만 그 자리 retract가 하드코딩된
no-op이라 되돌릴 상태가 없음.

**타입/판별**: `isPostRef`는 `isPreRef`와 같은 층위의 가장 구체적인 항등
체크이고, `isRef`가 그 위에 얹히는 상위 개념 — `Dispatch/Leaf.luau`의
일반 Ref 매치는 이제 `isRef(v) and not isPreRef(v) and not isPostRef(v)`.
상세는 `base/brand-plan.md`.

**대표 유스케이스(사용자 제시)** — `ChildAdded` 같은 이벤트에서 **나중에
들어오는 것만** 처리하고 싶을 때, `PostRef`의 콜백이 `mounted = true`
같은 boolean 플래그를 세워두고 핸들러가 그 플래그를 먼저 보게 하는 패턴.
초기 construction 중에 발생한 이벤트와 그 이후 동적으로 들어온 것을
사용자 코드가 스스로 구분할 수 있게 해주는, `PreRef`만으론 표현이 안 되던
자리임.

