# 루트 초안 여덟의 팩트체크 (2026-09-21, sonnet 둘 — 메인 검토)

> 대상: 이 폴더의 여덟 파일(사용자가 2026-09-17에 루트에 `-ignoreme`로 둔 외부 모델 초안). 두 sonnet이 코드·레퍼런스·정본과 대조한 원문 보고를 그대로 잇는다. 종합 판정과 흡수 계획은 `research/upward-flow-plan.md`가 소스. `proposal-two-way-binding-and-motion.md`는 메인이 직접 읽고 판정(같은 문서 4절).

---

# A. web-vs-quad 다섯

# web-vs-quad 초안 다섯 편 팩트체크

먼저 전체에 걸친 메타 발견부터 적는다. 이 다섯 초안이 다루는 소재 대부분—EpochMap과 32비트 리비전으로 다이아몬드 의존성을 접는 이야기, Slot의 부분합(prefix-sum) 부기 트리로 가상 DOM 없이 형제 여럿을 다루는 이야기, `nativeClaim`의 `gcconn` 핀으로 GC를 붙잡는 이야기, 우선순위 기반 열린 디스패치 핸들러 레지스트리 이야기—는 이미 `docs/quadnomicon/01-revision-and-epochmap.md`, `02-slot-prefix-sum-tree.md`, `07-instance-identity-and-gc-philosophy.md`, `08-extensible-dispatch-engine.md`, `09-fragment-breakthrough-and-domless-slot.md`로 공식 문서화되어 있다. Quadnomicon 1권의 도입부("정밀 반응형(Fine-grained Reactivity) 시스템을 구축할 때 모든 라이브러리가 반드시 마주치는 구조가 있습니다. 바로 다이아몬드 의존성입니다")는 `web-vs-quad-reactivity-and-glitch-ignoreme.md` 1절과 문장 단위로 거의 동일하다. 즉 이 다섯 초안을 "새로 흡수할 내용"으로 볼 게 아니라, 상당 부분은 "이미 흡수된 내용을 다른 진입점(웹 개발자 대조)으로 다시 쓴 것"으로 봐야 한다. 아래 파일별 팩트체크에서 이 중복을 다시 언급하지 않고 여기 한 번만 적는다.

## 1. web-vs-quad-architecture-ignoreme.md

이 글의 핵심 주장은 "Quad는 프로퍼티 차원에서는 DOMless이지만, Bookkeeping이라는 수치적 부분합 기반의 논리적 범위 트리를 자식/Fragment/동적 리스트 문제를 풀기 위해 내부에 두고 있다"는 것과, Quad의 `Slot`이 웹 컴포넌트의 `<slot>`과 이름만 같고 방향이 정반대(상위에서 만들어 하위로 주입하는 1급 객체)라는 것이다. 이 두 핵심 주장은 코드로 정확히 확인된다. `quad-base/src/Bookkeeping.luau`에는 초안이 언급한 `lengthList`, `sourceList`, `offsetCache`, `offsetCacheValidUpTo`, `offsetSetUpTo`, `indexOfElement`, `getOffsetAt` 필드/함수가 실제로 그 이름 그대로 존재하고(86~98행, 175행), `getOffsetAt`은 앞선 자리들의 길이를 누적해 캐시 커서를 전진시키는 부분합 로직을 그대로 구현하고 있다(175~219행) — 이 절은 맞음.

Slot의 지연 활성화(lazy materialization) 서술도 정확하다. `quad-base/src/Slot/Tree.luau`에 `materializeSlotTree`, `_physicalTarget == nil`(미물질화 판정), `_elements`(마운트 전 가벼운 원소 배열)가 실제로 그 이름으로 존재한다(4, 26, 33, 58행). "상위에서 Slot을 만들어 하위 컴포넌트의 props로 넘긴다"는 방향성 서술, "Slot 안에 Slot을 다시 넣을 수 있다"는 서술도 Slot이 `_elements` 배열에 임의의 원소(다른 Slot 포함)를 받는 구조와 부합해 맞음으로 판정한다. "물리 트리에서 Slot 자체는 흔적 없이 사라지고 자식들이 부모 아래 평탄하게 마운트된다"는 것도 DOMless 설계의 핵심 전제이고 Quadnomicon 9권이 같은 내용을 공식 서술하고 있어 맞음.

다만 두 군데는 부분적으로만 맞다. 첫째, 6절의 "데이터 목록 렌더링" 예제에서 `listSlot:List(dataState, function(ctx) return Card{...}, {...} end, keyFn)`의 `updateFn(ctx)` 안에서 `ctx.Index`와 `ctx.Offset`을 둘 다 "반응형 재료(reactive material)"로 묶어 서술하는데, 실제로는 `quad-types/src/init.luau` 544행의 타입 선언에서 `Index: number`(평범한 숫자, 갱신 시점의 스냅샷)이고 `Offset: State<number>`(진짜 반응형)로 서로 다르다. `Index`는 State가 아니므로 "반응형"이라는 수식어를 `Index`에도 붙인 것은 부정확하다 — 뒤에 나오는 코드 예제(`LayoutOrder = order:Depend(ctx.Offset):Compute(...)`) 자체는 `Offset`만 쓰고 있어 코드 예제는 맞지만 그 앞 산문 설명이 틀렸다. 둘째, 4절의 "리액티브 전파와 커서 캐싱" 서술에서 "ButtonGroup의 버튼이 2개에서 3개로 늘면 상위 부모의 관측자가 캐시 커서를 되감는다"는 흐름 자체는 맞지만, 그 재계산이 `:Get()` 시점의 지연 평가(pull)로 일어난다는 점—즉 "즉시 반영"이 아니라 "다음에 누가 그 위치를 물어볼 때" 반영된다는 점—을 명시하지 않아 오해의 소지가 있다(이는 2번째 초안이 정확히 다루는 내용이라 상호 보완적이다).

이 글에서 확인할 수 없었던 부분은 웹 프레임워크 역사 서술(Knockout, Lit, SolidJS의 내부 구현 세부)이다 — quad 레포 안에서는 검증 대상이 아니고, 저자의 웹 지식에 의존하는 부분이라 확인 불가로 남긴다.

**이 글에 대한 총평**: Quad 내부 구조에 대한 구체적 주장(필드명, 함수명, 동작 방식)은 전부 코드와 정확히 일치하고, 이미 Quadnomicon 2권·9권에 공식 서술된 내용과 겹친다. 흡수할 가치가 있는 부분은 "웹의 Slot과 Quad의 Slot이 이름만 같고 방향이 반대"라는 대조 프레임 자체인데, 이것도 이미 공식 문서에 없는 각도는 아니므로 "완전히 새로 추가할 내용"이라기보다는 "웹 개발자 온보딩용 다른 진입점"으로서의 가치가 크다. `ctx.Index`를 반응형으로 잘못 서술한 부분은 흡수 전에 고쳐야 한다. 웹 프레임워크 역사 비교 부분은 순수 배경지식이라 quad 자체에 대한 주장은 아니며, 사실 여부를 이 레포에서 판단할 수 없다.

## 2. web-vs-quad-reactivity-and-glitch-ignoreme.md

이 글은 다섯 편 중 가장 기술적으로 촘촘하고, 검증 결과도 가장 정확했다. 핵심 코드 인용 세 개—`self.Revision = bit32.bnot(-self.Revision)`(Source.luau), `Impl._receive`의 `_valueEpochMap:Update(from)` / `_emitEpochMap:Update(from)` 로직(State.luau), `Impl.Get`의 `while true do ... _cacheCurrCount ~= _cacheTargetCount ... end` 루프—는 전부 실제 소스 코드를 거의 토씨 하나 틀리지 않고 그대로 옮긴 것이다. 특히 `_receive` 함수 안의 `emitDown(self, from) -- rules 1/2: forward the SAME source; rule 3: swallow`라는 주석은 quad 소스 코드 자체에 그대로 있는 문구로(149~157행), 이 글이 서술하는 "Rule 1(무효화)/Rule 2(같은 출처 그대로 하류 전파)/Rule 3(두 번째 파동 삼킴)"이라는 3규칙 프레임 자체가 quad 팀이 실제로 쓰는 내부 어휘와 일치한다. 다이아몬드 의존성에서 `D`가 `B`를 통해 받은 신호를 캐시에 먼저 반영하고, `C`를 통해 받은 두 번째 신호는 `EpochMap:Update`가 이미 같은 리비전을 기록해 두었기 때문에 `false`를 반환해 전파가 거기서 멈춘다는 메커니즘도 `EpochMap.luau`의 `updateOne` 함수(맵에 적힌 리비전과 현재 리비전이 다를 때만 갱신하고 `true`를 반환)와 정확히 일치한다 — 이 글의 핵심 기술 주장은 전부 맞음이다.

"암묵적 의존성 추적을 거부하고 `:Depend`/`:Compute(fn, ...deps)`로 명시적 선언을 강제한다"는 주장도 `State.luau`의 `Impl.Depend(self, ...)`/`Impl.Compute(self, fn, ...)` 시그니처(260, 264행)와 일치해 맞음이다. Quad에 전역 추적 스택이 없다는 것도 코드에 그런 전역 상태가 없다는 점에서 맞다고 볼 수 있다(다만 "전역 스택이 없다"는 부재 증명은 완전할 수 없어 확인 불가에 가깝지만, 설계 문서 어디에도 ambient-tracking 메커니즘이 등장하지 않는다는 점에서 정황상 맞음으로 판단한다).

"fine-grained reactivity"라는 용어 사용은 quad 공식 문서(Quadnomicon 1권)가 스스로 "정밀 반응형(Fine-grained Reactivity)"이라고 칭하고 있어 용어 선택 자체는 맞음이다. 다만 이 글이 가정하는 "SolidJS/Vue가 쓰는 fine-grained reactivity와 완전히 같은 의미"라는 전제에는 미묘한 차이가 있다. SolidJS류의 fine-grained reactivity는 보통 "값이 바뀌면 그 값을 구독한 DOM 갱신 함수 하나만 정확히 재실행된다(컴포넌트 함수 재실행 없음)"는 것을 뜻하는데, Quad는 컴포넌트 함수가 한 번만 실행되고 State/Compute가 개별 프로퍼티에 직접 바인딩된다는 점에서 이 정의를 만족한다 — 이 부분은 맞음. 그러나 SolidJS의 신호는 기본적으로 "동기 즉시 전파(값이 바뀌는 즉시 그 자리에서 하류가 갱신)"인 반면(이 글 스스로도 2절에서 "웹 진영은 eager push-invalidate 뒤 lazy pull"이라고 정확히 구분해서 쓰고 있다), Quad는 `_receive`가 push하는 것은 "무효화 신호"뿐이고 실제 재계산은 오직 `:Get()`이 불릴 때만 일어나는 완전한 pull 모델이다. 이 차이 자체는 이 글도 3절에서 정확히 짚고 있어("모든 State는 오직 `:Get()` 시점 Lazy Pull") 자기모순은 아니다. 다만 6절 결론에서 "두 진영이 다이아몬드 의존성 해결의 핵심 통찰(Push Invalidate + Pull Recompute)을 공유한다"고 뭉뚱그리는 것은, Preact/TC39 Signals는 값을 읽는 순간(pull) 재계산하는 반면 Quad는 화면에 실제로 대입하는 시점의 `:Get()`이 pull을 트리거한다는 점에서 얼개는 같지만 "언제 값을 읽는가"의 구체적 트리거 지점이 프레임워크마다 다르다 — 이 뭉뚱그림은 부분적으로만 정확하다.

"Roblox의 태스크 스케줄러와 코루틴이 매우 빈번히 쓰이고, 함수 내부에서 yield가 일어나면 전역 추적 컨텍스트가 오염된다"는 주장, 그리고 "Vide 같은 라이브러리는 yield를 막는 방어 장치를 둘러야 했다"는 주장은 quad 자체의 설계 문서(`state-epoch-plan.md`)가 yield 재진입 문제를 실제로 다루고 있다는 점에서 Quad 쪽 서술은 신빙성이 있지만(맞음), Vide의 실제 구현이 어떻게 yield를 방어하는지는 이 레포 안에서 검증할 수 없어 확인 불가로 남긴다.

**이 글에 대한 총평**: 코드 인용의 정확도가 매우 높고(거의 verbatim 수준), quad의 실제 내부 알고리즘과 설계 근거를 정확히 짚어냈다. 이미 Quadnomicon 1권과 내용이 겹치지만, "웹의 Signals 계열과 나란히 놓고 Push-Pull 모델의 공통점과 차이(암묵적 추적 vs 명시적 선언)를 대조한다"는 프레임은 Quadnomicon 1권에 없는 각도이므로 이 글의 대조 프레임 자체는 흡수할 가치가 있다. 다만 6절 결론에서 웹 진영과 Quad를 지나치게 동질화하는 문장("핵심 통찰을 공유한다")은 정밀도를 낮추므로, 흡수할 때는 pull 트리거 시점의 차이를 더 명확히 구분해서 옮기는 편이 낫다. 이 글에 담긴 주장 중 사실과 다른 부분은 없었다.

## 3. web-vs-quad-lifecycle-and-dispatch-ignoreme.md

1~2절의 `nativeClaim`/`gcconn` 핀 메커니즘 서술은 코드와 정확히 일치한다. `quad-roblox/src/LifetimeHandle.luau`의 `nativeClaim` 함수가 실제로 `inst:GetPropertyChangedSignal("ClassName"):Connect(...)`로 절대 발화하지 않는 커넥션을 만들고, 그 콜백 클로저가 `gchold`와 `inst`를 업밸류로 캡처해 엔진이 강하게 참조하도록 만드는 방식이 코드에 그대로 있다(61~68행). "`Destroy()`가 호출되면 엔진이 커넥션을 끊고, `isBoundAlive`/`canBound`/`canExecute`가 그 끊김을 감지해 동기적으로 후속 반응형 발화를 차단한다"는 서술도 `quad-base/src/LifetimeHandle.luau`의 `isBoundAlive` 함수(100행)와 `canBound`/`canExecute`(114, 118행)가 정확히 그 이름과 역할로 존재해 맞음이다. "Quad가 만든 인스턴스는 단순 변수 참조를 nil로 놓는 것만으로 회수되지 않고 반드시 Destroy를 거쳐야 한다"는 트레이드오프 서술도, `nativeClaim`의 주석이 "claim되지 않은 인스턴스의 userdata는 한 GC 사이클 안에 회수된다"는 실측(`.claude/audit/spike10-full-run-2026-09-01.md` A-6)을 근거로 들고 있는 것과 일치해 맞음이다.

3절의 디스패치 엔진 서술도 핵심 개념은 맞지만, 제시된 `Handler` 타입 코드 스니펫은 실제 타입과 세부가 다르다. 실제 `quad-types/src/init.luau`(431~467행)의 `Handler` 타입은 `keyType: ("number" | "string")?`로 선택적 필드이고 리터럴은 `number`와 `string` 두 가지뿐이며 초안이 적은 `"any"`라는 리터럴은 존재하지 않는다(필드를 아예 생략하면 사실상 모든 키 타입에 매치되는 효과이지만, 그것을 "any"라는 값으로 표현하지는 않는다). 또한 `process`는 `(inst, key, value)` 세 인자가 아니라 `(inst, key, value, index)` 네 인자를 받고, 반환값은 초안이 이름 붙인 "Retractor"라는 명명 타입이 아니라 `(nextValue: any?, retracting: boolean) -> ()` 형태의 익명 클로저다(코드 안에서 "retractor"라는 말은 변수명이나 에러 메시지에는 쓰이지만 공식 타입 이름은 아니다). 개념 자체—우선순위로 정렬된 순수 판별자·처리기 레지스트리이고 Roblox를 모르는 코어 위에 프로바이더가 핸들러를 등록하는 구조라는 것—는 맞지만, 제시된 코드는 실제 시그니처와 다르므로 이 부분은 부분으로 판정한다.

3절 (2)의 "`Tween`은 프로퍼티 핸들러가 소비하는 특수한 값 타입 핸들러"라는 서술과, "`UseProvider(QuadRoblox)`로 설치되는 `PropertyHandler`/`EventHandler`/`OnChange`/`Modifier`/`Slot`/`Ref` 모두 평범한 핸들러에 불과하다"는 서술은 `quad-roblox/src/Handlers/`와 `quad-roblox/src/init.luau`의 실제 파일 구성(Property.luau, Event.luau, OnChange.luau)과 부합해 맞음이다. 다만 `Slot`과 `Ref`는 quad-roblox가 아니라 quad-base가 이미 등록하는 핸들러라는 점(둘 다 `quad-base/src/Slot/`, `quad-base/src/Ref/`, `quad-base/src/Dispatch/Ref.luau`에 있다)은 초안이 명시하지 않아 "quad-roblox가 설치하는 목록"으로 오해될 소지가 있다 — 부분으로 판정한다.

4절의 Modifier 규칙 서술("숫자 키 자리에서 뒤에 선언된 것이 앞의 것을 덮어쓴다", "인라인 문자 키는 Modifier를 무조건 이긴다")은 `quad-base/src/Dispatch/Modifier/init.luau`의 `flatten` 함수(477행 이하)를 정확히 반영한다 — 이 함수는 배열을 뒤에서부터 순회하며 나중에 선언된 Modifier가 먼저 필드를 쓰게 하고(`for i = n, 1, -1`), 이미 채워진 키(`input[key] ~= nil`, 인라인 키 포함)는 건너뛰므로 인라인 키가 항상 이긴다 — 맞음.

**이 글에 대한 총평**: 핵심 메커니즘(gcconn 핀, 디스패치의 열린 레지스트리, Modifier 병합 규칙)에 대한 설명은 전부 정확하고 코드로 뒷받침된다. 다만 `Handler` 타입 스니펫은 실제 타입 정의와 다르므로(키 타입 리터럴, process 인자 개수, 반환 타입 이름) 이 코드 블록 자체를 그대로 문서에 옮기면 안 되고 실제 타입에서 다시 인용해야 한다. Slot/Ref 핸들러가 quad-base 소속이라는 점도 명시가 필요하다. 이 글 역시 Quadnomicon 7권·8권과 소재가 겹친다.

## 4. web-vs-quad-advanced-concepts-ignoreme.md

1절의 `Claim`/`D.Mapper` 서술은 코드와 잘 맞는다. `q.Claim(inst, desc)`는 `quad-base/src/Claim.luau`의 `local function Claim(inst, desc)`(181행)와 일치하고, `D.Mapper.Frame(key)(props)` 형태는 `docs/reference/roblox/04-claim-mapper.md`가 공식 서술하는 `D.Mapper.Frame: (key: string | MapperRoot) -> (FrameParam<...>) -> MapperDescriptor` 시그니처와 정확히 일치한다. "디스크립터는 1회용이고 재사용하면 에러가 난다"는 서술도 같은 문서의 에러 메시지 표("`Claim: mapper descriptor was already used (descriptors are one-shot)`")와 일치해 맞음이다. 다만 `_fired = true`라는 구체적 내부 필드명은 실제 `Declaration/init.luau` 소스에서 그 이름으로 확인되지 않았다(다른 파일의 `_fired` 필드—`PreRef`/`PostRef`—와 혼동했을 가능성이 있다) — "1회 소진"이라는 동작 자체는 맞지만 내부 구현 디테일(필드명)은 확인 불가로 남긴다.

2절의 `PreRef`/`Ref`/`PostRef` 3단계 타이밍 서술은 정확하다. `quad-base/src/Ref/PreRef.luau`의 주석이 "Timing: fires BEFORE anything else happens to the instance — the pre-pass hoists every PreRef regardless of its array position"이라고 명시하고, `PostRef.luau`의 주석이 "fires AFTER this instance's array part (children, subtrees) and hash part (properties, events) are all done"이라고 명시해 초안의 서술과 정확히 일치한다 — 맞음. 다만 초안의 다이어그램은 "PreRef 발화 → 핸들러 파이프라인 실행 → Ref 발화 → PostRef 발화"처럼 평범한 `Ref`가 핸들러 파이프라인이 끝난 뒤 별도의 세 번째 단계로 발화하는 것처럼 그리고 있는데, 실제로 평범한 `Ref`는 `quad-base/src/Ref/init.luau`에 등록된 `RefLeafHandler`(`priority = HANDLER_PRIORITY_HIGH`, `keyType = "number"`)로서 다른 배열 원소들과 같은 본문 순회(body loop) 안에서, 자신이 배치된 배열 인덱스 위치와 우선순위에 따라 처리되는 평범한 핸들러다. 즉 "언제나 프로퍼티/자식 처리가 다 끝난 뒤에 발화하는 고정된 세 번째 단계"라는 그림은 과장이고, 실제로는 PreRef/PostRef만 그런 특권적 훅 지점(pre-pass/post-pass)이고 평범한 Ref는 그 사이 어딘가—대체로 우선순위가 높아 이른 시점—에서 발화한다. 이 부분은 부분으로 판정한다. "`.Value`/`.Revision`/`:Callback`/`:Wait`" 등 Ref의 API 모양은 `quad-base/src/Ref/init.luau`의 헤더 주석과 정확히 일치해 맞음이다.

3절의 `Observer`/`Effect` 비교표는 정확하다. `state:Observer(fn)`는 `quad-base/src/Observer.luau`가 서술하듯 단일 State에 대한 메소드이고(헤더 주석 "state:Observer(fn)" 섹션 인용), cleanup을 반환할 수 없다. `Effect(fn, ...deps)`는 `quad-base/src/Effect.luau`의 헤더 주석("`Effect(fn, ...deps)`; `fn(self) -> ...cleanup`")대로 복수 의존성과 cleanup 반환을 지원한다 — 표의 모든 행이 코드와 일치해 맞음이다.

4절의 `Fallback`/`Traceback` 서술도 정확하다. `Fallback(base, onError)`가 `pcall(base, ...)`을 감싸고 실패 시 `onError(resultOrErr)`를 호출하는 코드(`quad-base/src/Fallback.luau` 37~46행), `Traceback`이 `xpcall`과 `debug.traceback(nil, 2)`로 트레이스 문자열을 만들어 `onError(err, trace)`로 넘기는 코드(50~60행)가 초안의 서술과 정확히 일치한다 — 맞음. "래퍼 인스턴스를 만들지 않는다"는 것도 이 함수들이 순수 고차 함수이고 인스턴스를 직접 다루지 않는다는 점에서 맞음이다. 다만 이 파일 자체의 주석이 밝히는 "미해결 갭"—에러가 나기 전에 부분적으로 만들어진 트리가 `gcconn`을 통해 스스로를 계속 참조해 회수되지 않는다는 점—은 초안이 언급하지 않은 캐비엇이라, "완벽하게 해결됐다"는 인상을 주는 4절 서두의 어조는 이 한도까지는 과장이다.

**이 글에 대한 총평**: `Claim`/`Ref` 3단계/`Observer` vs `Effect`/`Fallback` 네 소재 모두 코드와 대체로 정확히 맞아떨어지는 우수한 팩트체크 결과다. 유일하게 고칠 지점은 평범한 `Ref`가 "핸들러 파이프라인 이후의 고정된 세 번째 단계"처럼 그려진 다이어그램으로, 실제로는 PreRef/PostRef만 특별한 pre/post-pass이고 Ref는 그 사이의 평범한 우선순위 핸들러라는 점을 반영해 다이어그램을 고쳐야 한다. `Fallback`의 부분 트리 미회수 캐비엇을 언급하지 않은 것도 흡수 시 보완할 부분이다.

## 5. web-vs-quad-benchmarking-and-patterns-ignoreme.md

이 글은 "Quad에 이미 있는 기능"을 팩트체크하는 2절과 "Quad에 없는, 향후 검토할 아이디어"를 제시하는 3절로 나뉘는데, 2절에서 사실과 다른 부분이 여러 군데 발견됐다.

(1) 배치 트랜잭션 항목의 "`q.Blocker()`와 `q.Gate()`가 이미 1급 객체로 존재합니다"라는 문장은 절반만 맞다. `q.Blocker`는 `quad-base/src/init.luau`(84행)에 `Blocker = Blocker`로 실제 최상위 export가 있어 `q.Blocker()`라는 생성자 호출이 유효하다. 그러나 `q.Gate()`라는 독립된 생성자는 존재하지 않는다 — `init.luau`의 export 목록 어디에도 `Gate`가 없고, "Gate"는 오직 `State.luau`의 인스턴스 메소드 `state:Gate(setup)`(324행)로만 존재한다("state:Gate(setup); setup(emit) -> onUpstreamEmit; Returns a State<T>"라는 주석, 323행). 즉 사용자가 어떤 State를 이미 갖고 있어야 그 위에서 `:Gate(...)`를 호출해 게이트가 걸린 새 State를 얻는 구조이지, 웹의 `batch()`처럼 아무 데서나 `q.Gate()`를 불러 쓰는 독립 객체가 아니다. 이 문장은 틀림으로 판정한다.

(2) 에러 바운더리 항목(`q.Fallback`)은 위 4번째 파일에서 검증한 대로 정확하다 — 맞음.

(3) 디바운스/쓰로틀 항목의 "`q.Debounce(source, delay)`와 `q.Throttle(source, delay)`가 1급 반응형 State 래퍼로 완벽히 구현되어 있습니다"라는 문장은 기능 존재 자체는 맞지만 제시된 시그니처는 틀렸다. 실제 `quad-base/src/Debounce.luau`(359~373행)의 `Debounce`/`Throttle`은 `Debounce{ Time, Leading?, Trailing?, MaxTime?, Handle? } -> factory` 형태로 옵션 테이블 하나만 받아 팩토리를 반환하고, 그 팩토리를 대상 State에 `state:Apply(factory)`로 적용해야 실제 게이트가 걸린 State가 나온다(헤더 주석에 이 시그니처가 명시돼 있다). 즉 소스와 지연시간을 인자로 바로 받는 `q.Debounce(source, delay)` 같은 API는 없다 — 부분(기능 존재는 맞음, 시그니처는 틀림)으로 판정한다.

(4) `q.Operator` 콤비네이터 항목은 `quad-base/src/Operator.luau`의 `Operator.Not`, `Operator.Sum`, `Operator.Clamp`가 실제로 그 이름과 `state:Apply(Operator.Clamp(0, max))` 형태의 사용법으로 존재해(129~166행) 예시 코드까지 정확히 맞음이다.

(5) `q.Context()` 항목도 `quad-base/src/Context.luau`의 `Context()`/`Context.Provider(name?)`/`ctx:Set`/`ctx:Get`/`ctx:Peek` 시그니처와 정확히 일치하고, "트리를 거슬러 올라가는 암묵적 스캔이 아니라 컴포넌트 경계를 건너뛸 때 명시적으로 전달하는 가방"이라는 성격 설명도 파일 헤더 주석("an EXPLICIT, typed value container passed down props... NOT the ambient tree-wide context")과 정확히 일치해 맞음이다.

3절의 미래 아이디어(Resource, Virtualization, `q.Bind` 양방향 바인딩, AnimatePresence류)는 모두 "지금 없고 향후 검토해볼 만하다"는 추측으로 명시적으로 서술돼 있어 사실 주장이 아니라 제안이다. `q.Bind`, `q.Resource` 같은 이름은 실제로 존재하지 않는다는 것을 확인했으며(코드 전체에 `Bind`/`Resource` export가 없다), 초안도 이를 "존재한다"고 주장하지 않고 "만들 수 있다"는 제안으로만 쓰고 있어 이 자체는 문제 없다. 다만 (3) 양방향 바인딩 예제에서 "현재 Quad에서 TextBox를 바인딩하려면" 이렇게 써야 한다며 제시한 코드,

```
D.TextBox {
    Text = text,
    OnChange = {
        Text = function(newText) text:Set(newText) end,
    },
}
```

가 실제 현재 API와 다르다는 것이 중요한 발견이다. `OnChange`는 해시 키에 테이블을 놓는 형태(`OnChange = { Text = fn }`)가 아니라, `quad-roblox/src/Handlers/OnChange.luau`의 헤더 주석이 명시하듯 **배열부 원소**로 `OnChange("Text", function(v) ... end)`를 넣는 형태다. 게다가 해시 키 형태는 quad가 한때 실제로 구현했다가 2026-09-03에 명시적으로 역전(폐기)한 옛 API로, `.claude/base/onchange-plan.md`가 "2026-09-03 역전·재확정 — 해시... 옛 모양은 구현까지 됐다가 같은 날 뒤집혔다"고 기록하고 있다(`archive/onchange-hash-key-reversed.md`도 참고). 즉 이 예제는 "지금 이렇게 써야 하는 번거로운 현재형"으로 제시됐지만 실제로는 존재한 적 있다가 폐기된 API를 현재형으로 잘못 인용한 것이다 — 틀림으로 판정한다. (참고로 "프로퍼티와 이벤트를 두 벌로 따로 써야 한다"는 번거로움 자체의 요지는—배열부 `OnChange("Text", fn)` 형태로 고쳐도—여전히 성립하므로, 이 항목이 제안하는 `q.Bind` 아이디어의 동기 자체는 무효화되지 않는다.)

(2) "Quad 내부에는 이미 `rawDetach`라는... 메커니즘이 갖추어져 있습니다"라는 서술은 `quad-base/src/Slot/Raw.luau`의 178행에 정확히 `local function rawDetach(self, index)`가 있어(초안이 인용한 파일 경로와 줄 번호까지 정확히 일치) 맞음이다.

**이 글에 대한 총평**: 2절 "이미 있는 기능"을 검증하는 이 글의 취지 자체가 가장 위험한 실수를 유발했다 — Fallback/Operator/Context/rawDetach 넷은 정확했지만, `q.Gate()`라는 존재하지 않는 생성자를 언급하고 `q.Debounce(source, delay)`라는 실제와 다른 시그니처를 제시했으며, 결정적으로 "현재 이렇게 써야 한다"고 제시한 양방향 바인딩 예제가 2026-09-03에 폐기된 API를 그대로 쓰고 있다. 이 세 군데는 문서에 흡수하기 전에 반드시 실제 시그니처(`Debounce{Time=...}` + `:Apply()`, `state:Gate(setup)`, `OnChange("Text", fn)` 배열부 형태)로 고쳐야 한다. 3절의 미래 아이디어 제안들은 사실 주장이 아니라 제안이므로 팩트체크 대상이 아니며, quad에 아직 없다는 점도 확인했다.

---

# B. fine-grained-reactivity-analysis · quad-architectural-impressions

# 두 초안 문서 팩트체크 — fine-grained-reactivity-analysis-ignoreme.md / quad-architectural-impressions-ignoreme.md

## 0. 먼저 짚어야 할 것 — 지시문과 실제 파일 내용이 어긋난다

작업을 시작하며 `fine-grained-reactivity-analysis-ignoreme.md`를 통째로 읽었는데, 이 파일은 "quad는 fine-grained reactivity다"라는 결론과 그 근거만 100% 긍정적으로 서술하고 있고, "입력값 변경에 반응하려면 `q.OnChange`가 매번 반복된다"는 진단도, `bind` 같은 해법 제안도 전혀 들어있지 않다(`q.OnChange`, `bind`, `양방향`, `two-way` 키워드로 두 파일을 전부 grep했지만 `OnChange`는 `StoreBind`/`Property.luau` 인용 두 곳뿐이고 전부 다른 맥락이다). 그 진단과 `q.Bind` 제안은 실제로는 레포 루트의 또 다른 gitignore 파일 `proposal-two-way-binding-and-motion-ignoreme.md`에 있다(1.1절 "왜 필요한가? (기존 방식의 피로도)"가 정확히 그 내용). 요청받은 두 파일에는 이 문제의식이 없으므로, 지시문의 (a)(b)(c) 질문은 사실상 그 세 번째 파일과 짝을 이루는 질문이다. 지시받은 범위(`fine-grained-reactivity-analysis-ignoreme.md`/`quad-architectural-impressions-ignoreme.md`)만 팩트체크 대상으로 삼되, (a)(b)(c)는 코드를 직접 조사해 답했고, 그 답은 세 번째 파일의 진단이 타당한지 판단하는 데도 그대로 쓸 수 있다. 세 번째 파일 자체의 전체 내용은 이 보고서의 팩트체크 대상이 아니다(요청 범위 밖) — 다만 관련된 부분만 아래 (c)에서 다룬다.

---

## 1. `fine-grained-reactivity-analysis-ignoreme.md` 항목별 검증

이 문서는 문제 진단이 없는 순수 포지셔닝/마케팅 문서다. 주장은 크게 "quad가 fine-grained reactivity의 정의를 충족한다"는 결론과 그 근거 7가지, 그리고 4가지 차별점 설명, 대외용 문구 제안으로 이뤄진다.

**컴포넌트가 상태 변경 시 재실행되지 않고 최초 1회만 돈다는 주장(1번 근거)** — 맞음. `docs/overview/01-why-quad.md`의 비교표와 "(1) 가상 DOM을 두지 않는다" 절이 "`D.Frame { ... }`이 그 자리에서 실제 Instance를 만들어 돌려주고, 변화는 개별 프로퍼티 바인드에만 도달한다"고 명시하고, 실제 소스에도 컴포넌트를 나중에 재호출하는 경로가 없다. `component-composition-plan.md`도 "컴포넌트 = 그냥 함수"로 확정해 놓았다.

**Source/State/Observer가 컴포넌트 단위가 아니라 독립된 반응형 원자로 존재한다는 주장(2번 근거)** — 맞음. `quad-base/src/Source.luau`, `State.luau`, `Observer.luau`, `Effect.luau`가 실제로 각각 독립 모듈로 존재하고, 인용된 API(`Source(default)`, `State:Compute(fn, ...deps)`, `state:Observer(fn)`)가 코드에 그대로 있다.

**`StoreBind`를 통해 상태 변화가 `Instance[prop]`에만 1:1로 직결된다는 주장(3번 근거)** — 맞음. `quad-base/src/Dispatch/StoreBind.luau`는 `state:Observer(fn)`으로 구독해 값이 바뀔 때마다 `dispatch.process(inst, k, realv, index + 1)`를 호출하는 게 전부이고, 최종적으로 `quad-roblox/src/Handlers/Property.luau`의 `process`가 `inst[k] = v`라는 한 줄로 실제 프로퍼티에 쓴다. 중간에 별도 트리나 diff 단계가 없다.

**Push-Invalidate/Pull-Recompute 2단계 파이프라인이 다이아몬드 글리치를 막는다는 주장(4번 근거)** — 맞음. `State.luau`의 `_receive`는 `emitDown`으로 무효화 신호만 내려보낼 뿐 사용자 함수를 부르지 않고, 실제 계산은 `Get()`이 불릴 때 `_recompute`가 세대 카운터(`_cacheTargetCount`/`_cacheCurrCount`)를 비교해 필요할 때 딱 한 번만 돈다. `A -> B, A -> C, B,C -> D` 형태로 신호가 두 경로로 D에 도달해도 D의 `fn`은 `Get()` 시점에 한 번만 실행된다 — 코드로 직접 확인했다.

**quad가 스스로를 "정밀 반응형(Fine-grained Reactivity) 시스템"이라 부른다는 인용(`docs/quadnomicon/01-revision-and-epochmap.md` L17)** — 맞음. 해당 줄을 직접 읽었고 "정밀 반응형(Fine-grained Reactivity) 시스템을 구축할 때 모든 라이브러리가 반드시 마주치는 구조가 있습니다"라는 문장이 정확히 그 줄에 있다.

**3절의 표(7개 항목 "일치" 판정)** — 전부 위와 같은 근거로 실제로 일치한다. 다만 표의 언어("100% 충족", "일치 (우수)")는 판정 자체는 사실에 부합하지만 수사가 과장돼 있다(아래 2절 마지막에서 다시 언급).

**4.1절 "암묵적 추적 대신 명시적 선언을 택했다"는 설계 서술** — 맞음. `State.luau`의 `newNode`는 `deps` 배열을 노드 생성 시점에 한 번 순회해 `isState(dep)` 검증 후 구독을 건다(런타임에 새로 추적하지 않는다). `:Compute(fn, ...deps)`/`:Depend(...)`가 실제 시그니처와 일치한다. "Vide가 yield 방어 장치를 덧붙여야 했다"는 서술은 Vide 소스가 이 레포에 없어 직접 재검증은 못 했지만, quad 자신의 감사된 비교 문서(`docs/overview/01-why-quad.md` 6절 표)가 "Vide: 암묵적(전역 스코프 스택) — 리액티브 스코프 안 yield를 막는 별도 장치가 필요"라고 같은 주장을 이미 정리해 두고 있어 이 문서만의 새로운 주장은 아니다.

**"GC 낭비 제거(Zero-Allocation Steady State)" 주장** — 부분적으로만 맞음, 여기가 이 문서에서 가장 과장된 대목이다. 의존성 엣지(`_hold`, `_subs`)는 확실히 노드 생성 시점에 한 번만 만들어지고 재계산 때 새로 만들어지지 않는다(`newNode`, `_recompute` 확인). `EpochMap.luau`도 `Update`/`Sync`가 생성자에서 한 번 만든 `self._map` 테이블을 계속 재사용해 갱신마다 새 테이블을 만들지 않는다. 하지만 `State.luau`의 `emitDown` 함수(93~104줄)는 구독자 순회 때마다 `local snap = {}`로 새 배열 테이블을 매번 할당한다(반복 중 구독자 추가가 정의되지 않은 동작이라 스냅샷을 뜨기 위함, 주석에 그 이유가 적혀 있다) — 즉 `Set`/`Emit` 한 번마다 최소 테이블 하나는 할당된다. "정적 엣지 고정, 할당 없음"이라는 표현은 의존성 그래프 구조 자체에 대해서는 맞지만 문자 그대로 "무할당"은 아니다 — "매 실행마다 링크 노드를 새로 만드는" SolidJS류 암묵적 추적 방식보다 할당이 훨씬 적다는 상대적 주장으로 읽어야 정확하다.

**5절/6절 홍보 문구와 FAQ** — 사실 주장이 아니라 대외 포지셔닝 카피라서 검증 대상이 아니다. 다만 "완전히 배제", "100% 일치", "무결점" 같은 절대적 표현이 반복되는데, 위에서 확인한 사실관계 자체는 대부분 참이지만 이 표현들은 기술 문서보다는 마케팅 카피의 어투에 가깝다.

---

## 2. `quad-architectural-impressions-ignoreme.md` 항목별 검증

이 문서는 quad 코드베이스와 Quadnomicon 11권을 훑은 인상기 + 프레임워크 비교표 + 문서화 제안 4가지로 이뤄진다. Quadnomicon 각 권의 제목·번호 대응은 실제 `docs/quadnomicon/` 폴더의 11개 파일(01-revision-and-epochmap부터 11-static-grepability-and-error-architecture까지)과 정확히 일치했다 — 이 문서가 실제로 그 문서들을 읽고 썼다는 신뢰도 있는 근거다.

**① 32-bit Wrapping Revision — `self.Revision = bit32.bnot(-self.Revision)`** — 맞음. `Source.luau`의 `bumpAndEmit`에 정확히 이 식이 있다(`State.luau`의 `_invalidate`도 같은 식으로 `_cacheTargetCount`를 갱신한다). Push 단계가 `_valueEpochMap`만 갱신하고 유저 함수를 안 돌린다는 것, Pull 단계가 `:Get()` 시점에 `cacheCurrCount == cacheTargetCount` 비교로 재계산을 판단한다는 것도 모두 코드와 일치한다.

**② Slot을 순수 부기 노드로 만들어 DOMless 환경에서 Fragment(형제 다중 반환)를 구현했다는 주장** — 맞음, 구조적으로 확인했다. `quad-base/src/Slot/Tree.luau`와 `Slot/init.luau`에 `offsetCacheValidUpTo`/`offsetSetUpTo`/`getBookkeeping` 같은 부분합류 부기 필드가 실제로 있고, Slot이 물리 Instance가 아니라 논리적 부기 개념이라는 것은 `.claude/base/slot-plan.md`의 설계와도 일치한다. "부분합(Prefix-sum) 트리"라는 정확한 자료구조 명칭은 `docs/quadnomicon/02-slot-prefix-sum-tree.md`라는 파일명 자체가 뒷받침한다.

**③ Ephemeron 테이블 부재 + userdata 신원 불안정성 + `nativeClaim`의 `GetPropertyChangedSignal("ClassName")` 앵커 트릭** — 맞음, 매우 정확하다. `.claude/base/lifecycle-pattern.md`의 "(0) gcconn/gchold는 Instance 생성 시점에 만든다" 절이 "Roblox의 Instance 값은 엔진 객체 자체가 아니라 엔진 객체를 가리키는 userdata 포인터다 … 나중에 같은 엔진 객체를 다시 얻으면 다른 userdata가 나올 수 있다"고 정확히 같은 주장을 하고, 실제 `quad-roblox/src/LifetimeHandle.luau`의 `nativeClaim` 함수가 `inst:GetPropertyChangedSignal("ClassName"):Connect(...)`로 절대 발화하지 않는 커넥션을 걸어 클로저가 `gchold`와 `inst`를 함께 캡처하게 만드는 코드가 그대로 있다. "Luau에 ephemeron이 없다"는 것도 `.claude/base/relate-plan.md`가 `luau.org/compatibility` 공식 확인을 근거로 이미 정리해 둔 사실이다. Destroy가 유일한 절단면이라는 "Teardown 철학" 서술도 `dispatch-core-plan.md`의 "Destroy → gchold 섬 붕괴" 서술과 일치한다.

**④ `State<T>`가 새 솔버에서 불변으로 판정되는 문제와 `StateMarker<T>` 공변 마커 해법** — 맞음, 필드명까지 정확하다. `quad-types/src/init.luau` 55번째 줄에 `export type StateMarker<T> = { read __quadState: true, read __quadStateValue: T }`가 정확히 이 문서가 인용한 모양 그대로 있다. `LuauTarjanChildLimit`과 "Code is too complex to typecheck" 에러도 `.claude/base/typing-limits.md` 8.5절·8.11절에 실측 기록이 있다.

**⑤ 비파괴 언마운트(`rawUnmount`)로 포탈이 별도 프리미티브 없이 공짜로 성립한다는 주장** — 맞음, 방향도 정확하다. `.claude/base/slot-plan.md`의 "여섯 번째" 세션 항목이 "State<Slot> 교체가 파괴에서 언마운트로 뒤집힘"을 확정하며 "오래 '오버엔지니어링'으로 기각돼 있던 포탈이 별도 기능이 아니라 이 결정의 자연스러운 귀결이 됨"이라고 명시적으로 적어 두었다 — 이 문서의 표현과 사실상 같은 문장이다.

**⑥ `canExecute(inst, value)` 2인자 구조의 결함을 발견해 `canExecute(value)` 단일 인자로 일원화했다는 주장** — 맞음. `.claude/base/lifecycle-pattern.md`가 "뒤의 둘은 inst를 안 받음(bindLifetime이 바인딩 시점에 gcconn 참조를 value 쪽 Relate로 복사해두므로 value 하나로 생존을 물을 수 있고, 실제 호출부인 State 전파 루프엔 애초에 inst가 없음)"이라 확정 서술하고 있고, "옛 2-인자 모델은 archive/canexecute-inst-arg-reversed.md"라는 실제 역전 기록까지 존재해 이 발견이 실제로 있었던 설계 전환임을 뒷받침한다.

**⑦ `Handler` 레코드(`isHandlable`/`priority`/`process`)로 열린 디스패치 엔진을 만들고 대칭적 retractor로 롤백한다는 주장** — 맞음, 계약 명세까지 정확히 일치한다. `quad-base/src/Dispatch/Handler.luau`의 문서 주석이 이 문서가 서술한 계약(`process`가 반드시 되돌리는 클로저를 반환해야 하고 `nil` 반환은 계약 위반이라는 것 포함)을 그대로 담고 있다. `Property`, `Event`, `Slot`, `StoreBind`가 전부 이 하나의 우선순위 레지스트리를 쓴다는 것도 실제로 `dispatch.addHandler({...})` 호출들로 구현돼 있다.

**⑧ `quad-base`가 엔진 전역을 전혀 참조하지 않는 추상 기계라는 주장, `UseProvider` 한 줄로 백엔드가 부착된다는 주장** — 맞음. `quad-base/src/*.luau` 전체를 `game.`/`workspace.`/`Instance.new`/`task.wait` 등으로 grep했을 때 실제 호출은 한 건도 없었고(주석 속 예시 문구 하나만 있었다), `quad-base/src/init.luau`에 `module.UseProvider(self, providerFn)`가 실제로 존재한다.

**⑨ 포맷 헬퍼 없이 에러 문자열을 grep 가능하게 유지하고 `setFuncLevel(SURFACE, fn)`로 표면(호출자) 프레임을 짚어낸다는 주장** — 맞음. 여러 소스 파일(`Source.luau`, `OnChange.luau` 등)에서 `Err.setFuncLevel(SURFACE, ...)` 패턴과 에러 메시지가 리터럴 문자열 템플릿(``` `State: dep #{i} is not a State/Source` ```류)으로 그 자리에 그대로 박혀 있는 것을 확인했다.

**3절 비교 매트릭스(React/Vide/Fusion/SolidJS/quad)** — quad 열의 서술은 위에서 검증한 코드·문서와 일치한다. Vide/Fusion/React/SolidJS 쪽 서술(예: "Vide는 다이아몬드 중복 재평가를 미해결로 남김", "Fusion은 생성순 정렬로 글리치 방어")은 이 레포 안에 그 세 라이브러리 소스가 없어 1차 소스로 재검증하지 못했다 — 다만 quad 자체의 `docs/overview/01-why-quad.md` 6절 표가 거의 동일한 문장으로 이미 정리해 둔 내용이라, 이 문서가 근거 없이 지어낸 것은 아니고 quad 팀이 이미 조사·검토해 둔 내용을 재인용한 것으로 보인다(레포 밖 1차 소스는 확인 불가로 남겨둔다).

**4절 문서화 제안 4가지(멘탈모델 다이어그램, 로제타 스톤 표, "왜 명시적 의존성인가" 챕터 보강, 디스패치 확장 쇼케이스)** — 이건 사실 주장이 아니라 제안이라 참/거짓 판정 대상이 아니다. 다만 로제타 스톤 표 안에 있는 구체적 API 표기 하나(`D.Modifier.ClassName { ... }`)는 오해의 소지가 있다: 실제 API는 `D.Modifier.<Roblox 클래스 이름>({...})` 형태이고(코드 주석에 `D.Modifier.Frame(...)` 예시가 있다), "ClassName"이라는 리터럴 이름의 함수나 필드가 있는 게 아니라 "여기에 클래스 이름이 들어간다"는 자리표시자로 쓴 것으로 보인다 — 표기가 그 의도를 충분히 드러내지 못해 그대로 읽으면 오독하기 쉽다.

**개수 주장(21페이지 시작하기 → "20단계", 9개 How-To, 11권 Quadnomicon)** — How-To(9개)와 Quadnomicon(11권)은 정확히 일치한다. Getting Started는 `00-installation.md`부터 `20-wrap-up.md`까지 총 21개 파일이 있는데, "체계적인 20단계"라는 표현은 00번(설치)을 본편 앞의 준비 단계로 보고 01~20을 "20단계"로 헤아린 것으로 읽히며 그 해석대로면 정확하다 — 파일 총량(21개)과 "20단계"라는 표현이 언뜻 안 맞아 보이지만 실질적인 오류는 아니다.

---

## 3. 지시받은 세 질문에 대한 답 — 코드를 직접 조사한 결과

**(a) 지금 quad에서 사용자 입력(TextBox 텍스트, 토글, 슬라이더)을 State로 되돌려 받는 경로, 그리고 "이게 반복된다"는 진단이 타당한가.** 지금 유일한 공식 경로는 `q.OnChange(propertyName, fn)`이다(`quad-roblox/src/Handlers/OnChange.luau`). 이건 props의 숫자 키 자리에 놓는 디스크립터 값으로, `GetPropertyChangedSignal(name)`을 연결해 신호가 올 때마다 `fn(inst[name])`을 부르는 게 전부다 — 보통은 `q.OnChange("Text", function(v) source:Set(v) end)`처럼 콜백 안에서 유저가 직접 `:Set`을 호출해야 한다. 즉 "화면 → State" 방향은 `OnChange` 콜백을 쓰고 "State → 화면" 방향은 그 State를 `Text = source`처럼 그대로 프로퍼티에 물리는 것이라, 입력 필드 하나를 완전히 양방향으로 만들려면 항상 두 자리(프로퍼티 대입 + `OnChange` 호출)를 따로 적어야 한다. `.claude/base/onchange-plan.md`를 보면 이 반복은 우연한 미비가 아니라 의도된 설계다 — dedup도 quad가 대신 해주지 않고 "== 비교가 엄청 싸서 그 안에서 dedup 하면 되는 부분"이라며 사용자 몫으로 명시적으로 남겨 두었다. 그래서 "TextBox 하나, 토글 하나마다 이 두 줄이 반복된다"는 진단 자체는 코드·문서와 정확히 일치하는 사실 서술이다 — 다만 이게 quad 설계상 "문제"인지 "의도된 트레이드오프"인지는 별개 판단이고, 아래 (c)에서 보듯 quad는 이걸 의도적으로 선택했다.

**(b) quad의 반응형 모델이 SolidJS류 "fine-grained reactivity"(노드별 구독, VDOM 없음, push 기반, 동기)와 실제로 일치하는가, epoch 모델이 다이아몬드/글리치를 어떻게 다루는가.** 코드로 직접 추적한 결과 대체로 일치한다. 노드별 구독은 각 `State`/`Source`가 자신의 `_subs`(약한 키 집합)에 하위 구독자를 직접 들고 있는 구조로 확인되고(전역 디펜던시 그래프가 아니라 노드마다 자기 구독자 목록), VDOM은 정말 없으며(`StoreBind` → `Property` 핸들러가 `inst[k] = v`를 직접 쓴다), 값 전파는 동기적이다 — `State.luau`의 `_receive`가 `Observer`/`Effect`의 `fn`을 `Set` 호출과 같은 콜스택 안에서 즉시 실행한다(`Observer.luau`의 `_receive`가 `self.fn(...)`을 바로 부르는 것으로 확인). 다만 엄밀히 말하면 quad는 "순수 push"가 아니라 "push(무효화 신호만) + pull(값은 :Get() 시점에 계산)"의 하이브리드다 — Effect/Observer처럼 값을 실제로 "쓰는" 최종 소비자는 동기·즉시로 돌지만, 중간의 `:Compute` 파생 노드는 신호를 받아도 계산을 미루고 캐시만 무효화해 둔다. 이건 SolidJS의 실제 내부 구현(시그널은 즉시 알리고 메모는 지연 계산, 이펙트는 동기 실행)과 본질적으로 같은 패턴이라 "SolidJS식 fine-grained reactivity와 다르다"고 보기는 어렵다. 다이아몬드/글리치 처리는 `_cacheTargetCount`/`_cacheCurrCount` 세대 카운터로 해결한다 — A가 바뀌면 B와 C 양쪽 경로로 D에 무효화 신호가 두 번 와도, D는 `_invalidate`만 두 번 하고 실제 `fn` 실행은 `Get()`이 불릴 때 세대가 안 맞으면 딱 한 번만 돈다(코드로 직접 확인). 따라서 "다이아몬드에서 중복 계산이나 일시적 불일치가 없다"는 주장은 코드 구조상 사실이다.

**(c) 제안된 해법(특히 `bind`류)이 이미 기록된 결정과 충돌하는가.** `.claude/base/component-composition-plan.md` "1. 컴포넌트 = 그냥 함수, '자기 store 자동 소유' 매직은 폐기" 절이 정확히 이 주제를 다룬 적이 있다. quad v1은 `self(name)` 링커가 인스턴스 프로퍼티 변경을 컴포넌트 store로 자동으로 역방향 전파하는 진짜 양방향 바인딩(문서 표현 그대로 "자동 흡수 매직")을 갖고 있었는데, v2에서는 이 역할을 의도적으로 갈라서 폐기했다 — Ref가 "값을 잡아두는" 역할을, "Source 직접 전달"이 값 전달 역할을 대신하고, 되돌리기(쓰기) 방향은 React식 `value(State) + onChange(callback)` 패턴(=지금의 `Text = source` + `q.OnChange`)이 기본이 됐다. 이 결정에는 사용자 본인의 인용문이 직접 달려 있다 — "마법 안쓴다 그것도 동의함", 그리고 "callback을 쓰는게 일반적이여 보이긴 해. 타입으로도 편하기도 하고 디버깅도 편함". 즉 "값 변경을 프레임워크가 알아서 State에 되써주는" 방식의 자동/암묵적 바인딩은 이미 한 번 검토된 뒤 명시적으로 기각된 설계다. 따라서 어떤 형태로든 "State와 프로퍼티를 한 번에 엮어 프레임워크가 되쓰기까지 대신해주는" `bind` 계열 제안은 이 기록된 결정과 정면으로 충돌한다 — 되살리려면 그 결정을 뒤집는 새로운 사용자 판단이 필요하다는 뜻이고, 이는 `conventions.md`의 "리뷰 발견이 새 메커니즘을 요구하면 그건 사용자 문항이다"라는 관례와도 맞물린다. (참고로 `.claude/archive/existing-instance-bind-rejected.md`는 이것과는 다른 주제 — "이미 있는 Instance에 새 props를 나중에 다시 바인드하는 것"의 기각이라 혼동하지 않게 구분해 둔다.)

---

## 4. 파일별 한 문단 총평

**`fine-grained-reactivity-analysis-ignoreme.md`**: 사실관계 자체는 거의 다 맞다 — 컴포넌트 1회 실행, 독립 반응형 원자, 1:1 프로퍼티 직결, push-invalidate/pull-recompute, quad 스스로의 "정밀 반응형" 자기 서술까지 전부 코드와 문서로 확인됐다. "GC 낭비 제거"를 "Zero-Allocation"이라고 못박은 대목만 과장이다(emitDown이 매 발행마다 스냅샷 테이블을 할당하므로 문자 그대로 무할당은 아니다). 다만 이 문서는 문제 진단이 전혀 없는 순수 대외 포지셔닝 문서이고, "100%", "무결점" 같은 절대적 수사가 반복돼 엔지니어링 문서보다는 마케팅 카피에 가깝다 — 채택할 가치가 있는 건 근거(코드·문서 인용)이지 그 절대적 어투는 아니다.

**`quad-architectural-impressions-ignoreme.md`**: 이 두 파일 중 훨씬 신뢰도가 높다. Quadnomicon 11권의 각 권 핵심 주장(비트 리비전, Slot 부분합, ephemeron 부재와 앵커 섬, 공변 마커, 비파괴 언마운트, 단일 인자 생존 게이트, 디스패치 엔진, 다중 백엔드, grep 가능 에러)을 하나하나 짚었는데, 필드명·함수명·에러 문구·파일 경로까지 실제 소스와 정확히 일치했다 — 단순히 문서를 요약한 게 아니라 소스코드 레벨까지 대조해 쓴 것으로 보인다. 흠잡을 대목은 로제타 스톤 표의 `D.Modifier.ClassName` 표기가 실제로는 클래스 이름이 들어가는 자리표시자인데 리터럴 이름처럼 읽힐 수 있다는 것 정도이고, Vide/Fusion 관련 서술은 이 레포에서 1차 소스로 재검증은 못 했지만 quad 자신의 기존 조사 문서와 일치해 근거 없는 창작으로 보이진 않는다. 이 문서는 사실 왜곡 없이 흡수해도 되는 수준이고, 4절의 문서화 제안(로제타 스톤, 멘탈모델 다이어그램, 디스패치 쇼케이스)은 사실 주장이 아니라 아이디어라 그대로 검토해 볼 만하다.
