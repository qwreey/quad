# 소비자 킷 피드백 — 디버그 UI 킷·Material 3 킷을 만들며 (2026-10-05)

> **[2026-10-05 신설]** quad의 첫 실사용 소비자 둘(`quad-roblox-devui`·`quad-roblox-material`, 이름은 가칭 —
> 계획은 `research/consumer-kits-plan.md`)을 만들며 quad 쪽에서 겪은 마찰을 모았다. 구현은 서브에이전트
> 여럿이 나눠 했고, 각자의 보고에 적힌 항목을 오케스트레이터가 다시 재현해 판정했다. **"버그(재현됨)"는
> 최소 재현을 직접 돌려 확인한 것**, "의심"은 읽기로만 본 것이다. 재현 파일은 레포 밖에 두지 않고 문단 안에
> 코드로 적었다. 새 API·이름 제안은 전부 **사용자 결정 필요** — 이 문서는 발견이지 결정이 아니다.
>
> 전체 판단: **정상 경로로 컴포넌트 킷 둘(위젯 마흔 남짓)을 끝까지 만들 수 있었다.** quad 런타임 결함으로
> 막힌 일은 0건이다. 마찰은 거의 전부 **타입 표면**(제네릭 추론·불변성)과 **소비자용 테스트 도구 부재**,
> 그리고 **라이브러리 저자 관점의 문서 공백**에 몰려 있다.
>
> **[2026-10-05 메인 세션 검증·기존 원장 대조]** 메인이 직접 다시 돌린 것 넷 — A1(`id<T>(x: State<T>)`에 `State<number>` →
> *"at least number | nil, at most number"*)·A2(`State<EnumItem>` 자리 `Source<Enum.EasingStyle>` 거부, 출력 13.8KB)·
> A7(두 갈래 `return nil` 거부)은 luau-lsp 신 솔버(test.sh 한도 플래그)로, C0(`q.dispose(host)` 뒤 `slot:Add` 성공·
> `child.Parent == host`·`q.debug` 출력 0)은 mock으로 재현됐다. 기존 원장과 겹치는 것: **A7은 round13 `Q145`와 같은
> 문항**(열림 — 새 문항이 아니다), A1은 `Q121`(`Slot:Single`의 `Item?` 하한)과 같은 가족(하한에 `nil`이 섞임)이지만
> 자리가 `State<T>` 매개변수 자체라 범위가 더 넓다, C0은 round3 `Q9`(quad 밖 파괴 뒤 Slot 좀비 — "Instance와 동형,
> 메시지+UB 문서화"로 닫힘)·round14 `Q166`(debug에서 미claim 인스턴스 경고 — 반영 대기)과 인접한다(여기는
> `q.dispose`로 quad가 직접 죽인 호스트), C3의 "의존의 상류에 쓰기"는 2026-10-02 사용자 결정(Effect가 자기 의존과 그
> 상류를 Set하는 것은 정의 — 반영 대기 묶음, `session/2026-09-28-01-round13-batch-reply.md`)이 이미 답한 범위이고
> 두 Effect가 서로의 의존을 쓰는 교차 루프만 남는다.
>
> **[2026-10-06 사용자 회신]** C0 — debug일 때 Slot CRUD 입구에서 마운트 호스트의 claim 확인(감지기 3과 같은 계열, round14 Q170 아래 "debug 감지기 셋" 문단), 공개 "호스트 생존" 질의는 안 함. C3 — 10-02 결정(Effect 상류 Set 정의)과 같은 메커니즘: 수렴하면 정의, 수렴하지 않으면 UB(`Quad0263`) — core/05·quadnomicon에 "다른 Effect를 거쳐도 같다" 한 줄. C7 — Modifier 자리가 아님, 팩토리 출력이 flatten에서 펴지는 값 방향으로 백로그(`research/component-flatten-sugar-plan.md` 4절), 지금 결정 안 함. A1·A2·F1·A5b — 타입 표면 조사 진행(`audit/consumer-type-surface-2026-10-06/`).
>
> **[2026-10-06 사용자 회신 2]** **C0 — `isClaimed` 계약 명시**: 사용자 *"명시적 계약이 되어도 될 것 같아. 그걸 전재하고 개발되었으니까"* — 그간 레퍼런스 extend/01의 "파괴되면 즉시 거짓"은 `H-548`(2026-09-17 탐사 반영)으로 들어와 사용자 원문이 없었고, Q71(`H-594`)·감지기 3·C0이 그 전제 위에 서 있었다. **정의**(사용자): *"Quad 손에 닿았냐 그리고 살아있냐 … 살아있는 동안 quad에 닿았고 지금도 살아있냐"*(Destroy 뒤 claim은 UB). **다른 백엔드**: 사용자 *"엔진이 지원하기 어려워도 이 프로바이더에선 quad 가 죽여야, quad 시점에선 죽은거로 본다가 성립할 수 있거든"* — 엔진이 파괴를 동기로 알려 주지 못하면 백엔드는 quad의 제거 경로(`q.dispose`·Slot 철거)에서 죽음을 기록(약한 맵 등)하고, 그 경로 밖의 파괴는 그 백엔드에서 UB로 좁힌다(이미 문서가 `dispose`를 쓰라고 안내하므로 성립); Roblox는 gcconn 끊김이 `Destroy` 안에서 동기라 엔진 직접 파괴도 즉시 거짓. **소비자 공개**: `q.Backend.isClaimed`를 소비자 문서에 위 정의로 소개(새 이름 없음) — 사용자: *"무언가 살아 있나 보고자 하는건 거의 당연해 … defer 되는 destroying 에서는 effect 만 가지고 히트비트를 정리한다 하면 그 사이 여백이 미정의야 … 막아두는건 이득이 없는거 같아. 이미 내부적으로도 그 용도로 사용하니까, 권고에 동의해"*. **추가 제안(사용자, 미결)**: `canExecute`(지금 `q.Backend.canExecute`, Effect·Observer의 "지금 돌 수 있나" = 묶여 있고 대상이 살아 있음, 또는 전역 구독)도 공개 표면 후보 — Effect `fn(self)`가 이미 self를 넘기므로 이벤트 클로저가 self를 업밸류로 잡아 동기 생존 확인에 쓰면 인스턴스를 모르는 팩토리·Source만 받은 Effect에서도 동작. 사용자가 짚은 걸림: 설치 발화(바인드 전)에도 거짓이라 "죽었는데 Destroying이 미뤄진 것"과 "아직 바인드 전"을 못 가린다 — 메인 분석은 채팅(다음 회신 대기).
> **타입(A1·A2) 회신**: (a-공변·평탄)·(a-전부) 기각 확인. **(b) 평평한 쓰기 마커 공개 — 기각**: 사용자 *"일시적 타입을 제공하는 꼴 같아서 … marker 를 만들게 된 것에서는 타입 검사의 시간을 줄이자라는 목표도 있었기 때문이야. 그리고 marker 는 cast 할 수 있는 형태다라고 정의했지 어디까지 노출할것이냐를 정의하지도 못했어 … source 에만 선택적으로 이걸 풀어준다는건 다른 곳도 나도 해줘요 하고 나올 이유가 충분해. 지금은 cast 해서 내부적으로 source 로 바꿔 써야하지 않나 싶어. 그게 정본같음. 정확히 문제는 우리에게서 안 나왔고 luau 의 최적화와 타입 문제에서 나온거고, luau 가 바뀌면 변경되어야할 부분인데 그러면 무조건 breaking changes 가 없으면 과거의 잔재를 못 지우게 될 것 같아"*. 정본: 제네릭 State props는 `StateMarker<T>`로 받고 본문에서 캐스트(`(x :: any) :: State<T>`/`Source<T>`) — 문서 레시피(c)로만, 새 공개 타입 없음. material 킷의 손수 만든 뷰 타입(`Radio.ValueSource<T>`)은 이 정본으로 바꿀 킷 정리 거리. (a-최소)는 메인 권고대로 안 함(luau-lsp 대기), 업스트림 보고 두 건은 최신 빌드 재확인 뒤 초안.

## A. 타입 표면

**A1. `State<T>`/`Source<T>`를 받는 제네릭 함수는 `T`를 추론하지 못한다 — 버그(재현됨, 가장 큰 마찰).**
라이브러리 저자는 `RadioButton<T>{ Value: Source<T>, Option: T }`, `Combo<T>`, `Table<T>`, `Tabs<K>`처럼 값의 타입을
제네릭으로 받는 컴포넌트를 자연스럽게 만든다. 그런데 신 솔버 strict에서 가장 단순한
`local function id<T>(x: q.State<T>): q.State<T> return x end; id(c1)`조차 `c1: State<Color3>`·`State<number>`·
`q.Source(Color3.new())` 어느 것을 넘겨도 *"No valid instantiation could be inferred for generic type parameter T.
It was expected to be at least: Color3 | nil and at most: Color3"*로 죽는다. 같은 함수를 `StateData<T>`로 받으면
추론이 되고, 호출자가 `id<<Color3>>(c1)`처럼 타입 인자를 적어도 된다. 원인은 `quad-types/src/init.luau`의
`State<T> = StateData<T> & { Compute: <U>(…, fn: (self: StateData<T>, previous: U?, …) -> U, …) -> State<U>, …,
Observer: (…, fn: ObserverFn<T>?) … }`(198~232행 부근)처럼 `T`가 `T?`·콜백 매개변수 자리에도 서 있어 하한에 `nil`이
섞이는 것으로 보인다(정확한 멤버는 좁히지 않았다). 킷 쪽 우회는 셋이었다 — 호출자에게 `<<T>>`를 쓰게 하고 헤더에
적기(RadioButton·SelectableOption·TabBar·Table·ChipSet·ListData), 매개변수를 `StateData<T>`로 받기, 그리고
material의 `Radio.ValueSource<T>`처럼 `self: never`인 구조적 읽기 전용 뷰 타입을 직접 정의하기. 같은 가족:
`Slot:List`의 `keyFn`을 제네릭 함수 안에서 넘기면 *"Expected '((T, number) -> any)?' but got '(T) -> string | number'"*
(비제네릭 자리에서는 통과), `q.State<{ T }>`를 받는 제네릭(`ChipSet`)도 같은 하한 `T | nil`. 제안: 라이브러리
저자용으로 `typing-limits.md`/how-to 01에 "제네릭 컴포넌트는 `StateData<T>`로 받거나 `<<T>>`를 쓰게 하라"를
한 줄 두는 것이 최소이고, 근본 수선(어느 멤버가 하한을 오염시키는지 좁혀 공개 타입 모양을 바꾸는 것)이나
`quad-types`가 제네릭 매개변수용 읽기 전용 뷰 타입을 내보내는 것은 **사용자 결정 필요**(새 공개 타입).

**A2. `State<T>`도 불변이라 `State<Enum.EasingStyle>`을 `State<EnumItem>` 자리에 못 넣고, 에러 문구가 36KB다 — 버그(재현됨).**
`ComboEnum`이 아무 Enum이나 받으려고 `Value: Source<EnumItem>`을 받자 `q.Source(Enum.EasingStyle.Quad)`가 거부됐다.
쓰기가 있는 `Source<T>`의 불변성은 당연하지만, 읽기 전용이어야 할 `State<EnumItem>` 매개변수에도 같은 값이
안 들어간다(`local function takesState(v: q.State<EnumItem>) end; takesState(q.Source(Enum.EasingStyle.Quad))`).
luau-lsp 출력은 같은 줄에 *"Expected this to be exactly 'EnumItem', but got 'Enum.EasingStyle'"*를 수십 번 반복해
36KB에 이른다. quad는 이미 입력 자리를 공변 마커(`StateMarker`)로 바꿔 생성 Declaration의 같은 문제를 풀었는데
(typing-limits 8.11), 그 마커는 `:Get`이 없어 소비자가 "읽기만 하는 State 매개변수"로 쓸 수 없다. 우회:
호출자가 `q.Source<<EnumItem>>(...)`로 넓혀 만든다. 제안: A1과 같은 해법(읽기 전용 공변 뷰 타입) 하나로 둘 다
닫힐 가능성이 높다 — **사용자 결정 필요**.

**A3. 빈 Slot에 주석만 달면 안 된다 — 문서에 이미 있음(작은 마찰).** `local s: Slot<Instance> = q.Slot()`은
`Slot<unknown>`으로 추론돼 거부되고 `q.Slot<<Instance>>()`만 통과한다. SKILL §4.2가 이미 `q.Slot<<Instance>>()`를
요구하므로 결함은 아니고, 기대(주석이 추론으로 흘러감)와 어긋난다는 기록만 남긴다.

**A4. 분기에서 대입한 `State` 지역 변수의 메소드 호출이 `*error-type*` 유니언이 된다 — 의심(솔버 쪽).**
`local v: State<boolean>; if c then v = q.Source(true) else v = src:Compute(...) end; v:Compute(...)`가
*"Cannot call a value of type \*error-type\* in union"*으로 죽는다. 한 번만 대입하면 통과한다. quad 타입 모양보다
솔버의 분기 합류 문제로 보이며, 우회는 값을 돌려주는 헬퍼 함수(반환 주석 `State<T>`)로 만드는 것. 제안: 없음
(재현만 기록).

**A5. 라이프사이클 훅에 클래스 타입 인자를 안 주면 strict가 죽는다 — 문서에 있음.** `q.OnCreated(function(inst:
GuiObject) … end)`가 *"Type functions do not currently support types of the form '\*error-type\*'"*. SKILL §6.3에
적혀 있고, 킷은 `q.PreRef(nil :: GuiObject?):Callback(fn)`을 감싼 `Util.preHook`/`postHook`으로 우회했다. 제안:
문서 그대로 두되, 비제네릭 오버로드는 사용자 판단 거리(**사용자 결정 필요**).

**A5b. `PreRef:Callback`의 콜백 매개변수에 주석이 없으면 strict가 죽는다 — 버그(재현됨, 작음).** `q.PreRef(nil :: Frame?):Callback(function(inst) … end)`가
*"Expected '(Frame?, Ref<Frame?>) -> ()'"* 계열 에러로 거부되고, `inst: Frame?`로 주석을 달면 통과한다(A5와 같은 "훅 콜백 추론" 가족). 우회: 주석.
제안: 레퍼런스 07(Ref)에 한 줄.

**A6. 프롭 오타가 조용히 무시된다 — 언어 한계.** `Devui.Button({ Text = "x", Bogus = 1 })`이 strict를 통과한다
(Luau에 초과 프로퍼티 검사가 없다). 선택 프롭 오타(`OnClik`)는 그냥 사라진다. quad 쪽 원인은 아니지만, 소비자
킷이 `q.debug` 때 알려진 프롭 목록과 대조하는 검사를 붙일지 고민할 거리.

**A7. Effect의 cleanup 반환은 "생략 가능"인데 `return nil`은 거부된다 — 버그(재현됨, 작음).** 레퍼런스 05와 SKILL은
"cleanup 반환은 선택"이라 적고, 실제로 어떤 경로에서 맨 `return`만 쓰면 통과한다. 그런데 같은 자리에 `return nil`을 쓰면
*"Expected this to be '(boolean) -> ()', but got 'nil'"*로 죽는다(`q.Effect(function() if not on:Get() then return nil end
return function(_d: boolean) end end, on)`). 반환 팩 타입이 `(...(boolean) -> ())`라 nil이 팩 원소로 들어가지 못하는 것으로
보인다. 킷 에이전트 하나는 맨 `return`도 실패한다고 보고했으나 재현되지 않았다. 우회: 맨 `return` 또는 공유 no-op cleanup.
제안: cleanup 자리를 `((boolean) -> ())?`로 넓히기(**사용자 결정 필요** — 공개 타입 변경).

**A8. 해시+배열이 섞인 props 테이블을 동적으로 조립할 타입이 없다 — 언어/타입 한계(재현됨).** 조건부 자식을 `table.insert`로
붙이려고 `local row: { any } = { Name = "x", D.UIListLayout({}) }`라 쓰면 *"Expected 'number', got '\"Name\"'"*. 킷은 각 자리를
`if cond then x else q.None`으로 적는 정적 생성자로 바꿨다(quad 관용구와도 맞다). 또 `Compute`를 인자 자리에 인라인으로 넘기면
(`Foo({ Text = src:Compute(function(self) … end) })`) 콜백의 `self`가 `{ read Get: … }`로 추론돼 거부되는 경우가 있어
지역 변수에 `State<T>` 주석을 단 뒤 넘겼다 — devui 헤더와 typing-limits의 "파생 State는 주석"과 같은 처방. Enum을 돌려주는
`:Compute`도 `State<EnumItem>`으로 넓게 추론돼 `SelectionBehaviorUp` 같은 구체 Enum 프로퍼티에 안 들어가 `State<Enum.SelectionBehavior>`
주석이 필요했다. 제안: 없음(기록). 덧붙여, `require("@self/X")`를 `init.luau`가 아닌 파일에서 써도 luau-lsp strict는 잡지 않고
런타임(Lune)만 실패했다 — quad 문제는 아니지만 quad 문서가 require 관례를 한 줄 짚으면 좋다(C8 (2)와 같은 자리).

## B. 소비자용 테스트 도구

**B1. 소비자가 쓸 mock 하네스가 없고, `luau` CLI로는 UI 킷 모듈을 실을 수조차 없다 — 공백(재현됨).** how-to 06이
"공개 mock은 아직 없다"고 적어 두었고, 실제로 킷은 `quad-base/test/mock.luau`를 직접 썼다. 더 큰 문제는 CLI의
샌드박스다: 모듈마다 읽기 전용 전역을 바탕으로 한 env를 받으므로 **모듈 최상위**에서 `Color3.new`·`UDim2`·
`Enum`을 쓰는 모듈(테마 토큰 모듈이 전형)은 `getfenv(fn).X = shim`으로 고칠 길이 없다(quad 자신의 spec이 이
기법으로 도는 건 quad가 로드 시점에 엔진 전역을 안 쓰기 때문이다). 킷은 Lune 0.10.5(실 Roblox 데이터 타입 제공,
모듈 간 전역 공유)로 옮겨 갔는데, Lune은 `const`와 `f<<T>>(x)`를 파싱하지 못해 — 둘 다 quad 문서의 관용구다 —
줄 수를 보존하며 둘을 지운 사본(`test/support/mirror.py`)에서 스펙을 돌린다. 하네스(`test/support/harness.luau`)는
반사 표(api-surface.json에서 생성), 가짜 서비스(UserInputService/RunService/GuiService/TextService), 가상 시계,
`print` 포착(`q.debug` 진단이 print라서)을 깐다. 제안: 백로그의 `quad-mock`을 만들 때 "모듈 최상위 엔진 전역"을
지원하는 러너(또는 Lune 경로)가 핵심 요구사항이라는 실측 근거로 쓸 것. 두 킷의 `test/support/`가 출발점이 될 수
있다. how-to 06에 이 한계(CLI 샌드박스와 모듈 최상위 전역)를 한 줄 적는 것은 비용이 싸다.

**B2. 테스트 mock의 충실도 구멍 넷 — 테스트 내부물(낮음).** (1) 새 mock 인스턴스의 `AbsolutePosition`/`AbsoluteSize`가
`nil`이라 `input.Position - inst.AbsolutePosition`이 스펙에서 터진다(엔진은 언제나 값이 있다). (2) `simulateCompleted`가
문자열 `"Completed"`를 쏘아, 실제 `Enum`을 쓰는 런타임(Lune)에서는 `Property.luau:377`의
`state == Enum.PlaybackState.Completed`가 거짓이라 Tween `Completed` 콜백이 안 불린다. (3) `IsA`가 ClassName 동치라
`IsA("GuiObject")`가 거짓이고, 반사 프로퍼티의 엔진 기본값이 없다(`ScrollingFrame.ScrollingEnabled`가 `nil` — 엔진은 `true`). (4) 같은 값을 다시 써도 변경 시그널이 발화한다(엔진은 안 한다) — Classic 색 선택기 스펙에서
두 TextBox가 함께 포커스된 비현실적 상황이 commit/echo 핑퐁으로 C 스택 오버플로를 냈다. 그 밖에 `CaptureFocus`/
`ReleaseFocus`/`FindFirstChildOfClass`가 없고, `Destroying`을 즉시·부모 먼저 쏘아 Deferred 시그널에서만 나는 순서 버그를
재현할 수 없다. 킷 하네스가 (1)(2)와 TextBox 포커스를 감쌌다. 제안: `quad-mock` 착수 때
목록으로 쓸 것.

**B3. Lune에는 `collectgarbage`가 없어 GC·누수 스펙을 못 쓴다 — 도구 한계.** 리뷰어가 GC 대조를 평범한 `luau`로 따로
돌렸다. B1의 러너 선택과 묶어 볼 거리.

## C. 문서·관용구 공백(라이브러리 저자 관점)

**C1. "quad 위에 라이브러리를 얹는 법"이 없다.** 시작하기 01은 게임의 설정 모듈을 다루지만, 킷처럼 **라이브러리가**
quad에 기대는 경우 — 라이브러리도 자기 설정 모듈에서 싱글턴에 `UseProvider`를 거는 게 맞는지, require 경로를 어떻게
바깥에 맡기는지, 같은 설치본이 아니면 값이 안 섞이는 문제를 소비자에게 어떻게 알릴지 — 가 흩어져 있다. 두 킷은
`src/Quad.luau` 하나에 require 세 줄을 모으고 나머지는 상대 경로로 쓰는 모양을 택했다. 제안: how-to에 한 절.

**C0. 호스트가 이미 죽은 Slot에 CRUD하면 조용히 성공한다 — 버그(mock에서 재현됨, `q.debug`도 침묵).** 킷의 첫 오버레이
설계가 모듈 싱글턴 레이어(C2)를 쓰다 그 레이어가 죽은 뒤에도 Dialog·Menu·Snackbar가 "열렸다"고 믿고 상태를 쌓았다. 원인은
quad 쪽에 있다: `local slot = q.Slot({}); local host = D.Frame({ slot }); q.dispose(host); slot:Add(D.TextLabel({ Text = "late" }))`가
에러도 경고도 없이 통과하고 새 TextLabel이 **파괴된 Frame 아래로** 붙는다(mock에서 `child.Parent == host`, `q.debug = true`인데
출력 0줄). 엔진에서 파괴된 인스턴스를 부모로 삼는 대입이 어떻게 되는지는 실기기 확인이 필요하지만, 어느 쪽이든 그 요소는
화면에 안 나오고 회수도 안 된다. how-to 09는 `:List`에 대해서만 비슷한 동작을 적어 둔다. 제안: 최소한 `q.debug` 때 "호스트가
파괴된 Slot에 대한 CRUD" 경고 한 줄(입구 한 줄 검사라 비용이 싸다 — 2026-09-30 원칙 보정의 범위로 보임); 에러로 올릴지는
**사용자 결정 필요**. 같은 뿌리의 두 번째 마찰: Deferred 시그널에서는 자손의 `Destroying` 처리기가 호스트(레이어)의
`OnDestroyed`보다 먼저 돌 수 있어, 팝업을 닫는 킷 코드가 "레이어가 이미 죽었는지" 알 길이 없다 — 공개된 "이 Slot의 호스트가
살아 있나" 질의가 없어 킷은 `entry.Parent ~= layer` 같은 엔진 휴리스틱으로 막았다. 질의 하나, 또는 죽은 호스트 Slot의 `Remove`를
정의된 no-op으로 두는 것도 선택지다(**사용자 결정 필요**).

**C2. 모듈 수준 싱글턴이 quad 인스턴스를 들고 있으면 첫 호스트와 함께 죽는다.** 두 킷 모두 처음에 `Overlay.default`를
require 시점에 만든 Frame 하나로 두고 "앱 ScreenGui에 정적 자식으로 놓으라"고 안내했는데, 그 ScreenGui를 버리거나
(디버그 UI 닫기, 리스폰 리셋) 다시 만들면 `Quad0219 … a destroyed Instance cannot be reused`로 끝난다(리뷰가 프로브로
재현). quad 쪽 동작은 정확하고 메시지도 좋다 — how-to 09의 "화면 루트에 한 자리"에 "모듈 싱글턴으로 들고 있지 말 것"을
한 줄 더하면 같은 함정을 막는다.

**C3. 서로의 의존을 쓰는 두 Effect(양방향 다리)가 정의된 경우인지 문서가 말하지 않는다.** devui 데모가 메뉴 토글을
스타일 Source와 동기화하려고 Effect A(flag → other), Effect B(other → flag)를 `SetIfChanged`로 맞물렸다. 레퍼런스 05는
"Effect가 자기 의존을 Set하는 것"만 정의된 경우로 적고 Observer 쪽에만 "다른 핸들을 거쳐도"를 명시한다. material의
`ColorPicker` `Model.Sync` Effect도 비슷하게 자기 의존의 **상류**(HSV Source)와 호출자 Source를 쓴다. 제안: 교차 Effect
루프와 "의존의 상류에 쓰기"가 정의 범위 밖인지 한 문장으로 못 박기(설계 판단이라 **사용자 결정 필요**). 킷은 데모 쪽을
단일 Source + Compute로 바꾸는 방향으로 고쳤다.

**C4. "인스턴스 수명에 묶인 연결" 레시피가 없다.** Heartbeat 같은 외부 연결을 "보일 때만 연결, 죽으면 해제"로 다루는
모양을 킷마다 다시 만들었다(OnRendered+OnDestroyed 쌍, PostRef로 mounted Source를 켜는 Effect 게이트). `q.Effect`의 첫
실행이 바인딩 전(호스트가 아직 없음)이라는 점도 레퍼런스엔 "등록 즉시 1회"로만 적혀 있어 외부 연결을 거는 Effect에
게이트가 필요하다는 걸 소비자가 스스로 알아내야 했다. 제안: how-to에 짧은 레시피.

**C5. `q.Out`/`OnChange`로 엔진 텍스트를 "같은 값"으로 되돌릴 땐 `:Set`이어야 한다.** TextField의 `MaxLength`는
`OnChange`에서 잘라 원천에 다시 쓰는데, 원천이 이미 한도 값이면 잘린 문자열이 원천과 같아 `SetIfChanged`는 아무 일도
안 하고 TextBox엔 넘친 글자가 남는다. `:Set`(같은 값 재발행)이라야 `Text = value` 바인딩이 엔진 쪽을 되돌린다.
how-to 02 §6 패턴이 이 경우를 다루지 않는다. 제안: `q.Out`/`OnChange` 레퍼런스에 한 문장.

**C6. 오버레이가 소유한 지연 생성 자식이 자기 체인을 알아야 할 때의 관용구.** devui `Menu`는 열릴 때마다 자식을
팩토리로 만들고, 항목 클릭이 메뉴 체인 전체를 닫고 하위 메뉴를 여는 데 필요한 "scope"를 자식마다 명시적으로 넘긴다
(트리 탐색이 없으니). 동작은 하지만 저자가 `Scope =`를 빠뜨리기 쉽다. 제안: how-to 09에 이 모양을 예로.

**C7. 정적 자식을 가진 컴포넌트가 효과(Effect)를 함께 돌려줄 길이 없다.** material `HexField`가 kit `TextField`(Frame
반환)를 감싸며 모델 ↔ 필드 동기화 Effect가 필요했는데 붙일 자리가 없어 `{ Field, Sync }` 쌍을 돌려주고 부모가 `Sync`를
배열부에 놓았다. 비슷하게 위젯마다 "추가 훅을 받는 프롭"(`Hooks`)을 킷이 직접 만들었다. 같은 뿌리: **Modifier는 이벤트
핸들러를 실을 수 없어**(`{ Activated = fn }` → `Quad0063`) 재사용 가능한 "행동 묶음"(hover·drag·focus)을 Modifier로
만들 수 없고, 킷은 PostRef + 직접 `:Connect`로 "훅"을 발명했다. 제안: 이벤트+수명을 함께 실을 배열부 값(가칭 behaviour
bundle)은 새 메커니즘이라 **사용자 결정 필요**; 당장은 "배열부 추가 항목을 받는 프롭" 관용구를 how-to 01에 적는 정도.

**C8. 작은 것들.** (1) SKILL §3.1은 `props.Modifier:AsTextButton()`이라 적지만 프롭 타입이 `IntoGuiObject`이면 그 키가
없고 `:AsGuiObject():AsTextButton()`이어야 한다. (2) 폴더 `init.luau` 안에서는 형제 모듈이 `./X`(그 폴더의 부모 기준)이고
폴더 안 파일은 `../X`라 처음 쓰는 사람이 자주 틀린다(Luau require 의미론 — quad 문서가 한 줄 짚어 주면 좋다).
(3) `Slot:List`의 `ctx` 타입 별칭이 공개돼 있지 않아 킷마다 `RowCtx`를 다시 선언한다(재귀 때문에 일부러 안 내보낸
것으로 주석에 있음).

## D. 킷 쪽 결함으로 판정한 것(참고 — quad 결함 아님)

리뷰에서 나온 것 중 quad가 아니라 킷 설계 탓인 것: 상태 레이어(전체 크기 Frame)와 `UIPadding`/`UIListLayout`을 같은
호스트에 두어 엔진에서 레이어가 안쪽으로 밀리거나 리스트 항목으로 배치되는 문제(Button·List·Card·Snackbar — `Content`
프레임 분리로 수정), devui `Table`의 행 구분선이 가로 `UIListLayout` 형제로 들어간 문제, 창 z-순서가 계속 올라가 팝업
레이어(ZIndex 1000)를 넘는 문제, 숨겨진 섹션에서도 Heartbeat가 도는 데모, 드래그 한 픽셀마다 미리보기를 다시 만드는
스타일 편집기. 레이아웃 계열은 mock에 레이아웃 엔진이 없어 **스펙으로는 못 잡고 코드 읽기로만 잡혔다** — B1의 도구
제안과 묶이는 교훈이다.

## E. 재현하지 못했거나 기각한 것

- "Source를 State 타입 필드에 넣으려면 `read`가 필요하다"(material 에이전트) — 최소 재현(`type Rec = { Hovered:
  State<boolean> }; local r: Rec = { Hovered = q.Source(false) }`)은 통과했다. 특정 맥락의 솔버 동작일 수 있어 기각하지
  않고 미확인으로 둔다.
- "명시 타입 인자 `f<<string>>(v, "a")`도 실패한다"(material 에이전트) — 재현 결과 통과. 기각.
- `Slot:List`가 데이터가 바뀔 때마다 모든 키에 `updateFn`을 다시 부르는 것 — 문서화된 동작(`ctx.Prev`로 유지). 결함 아님.
- Lune에서 `EnumItem`을 테이블 키로 쓰면 조회가 빗나간다 — Lune 쪽 사정, quad 무관.

## F. UI Labs 스토리를 붙이며 (2026-10-05 2차 과제)

두 킷에 UI Labs(Studio 플러그인) Generic 스토리를 붙였다 — 어댑터 하나(`stories/StoryKit.luau`)가 컨트롤 값마다 `q.Source`를
만들고 UI Labs `subscribe`는 그 Source에 `:SetIfChanged`만 하며, 컴포넌트는 앱에서 쓰는 그대로 Source를 받는다. 정리는 마운트한
루트·오버레이 레이어의 `q.dispose`뿐이다. quad 쪽 결과는 좋았다 — "패널 값 = Source"가 코어 변경 없이 그대로 됐고, 스펙(가짜
target·subscribe로 전 스토리를 그려 컨트롤을 한 번씩 바꾸고 정리)에서 정리 뒤 남는 인스턴스 0을 확인했다.

**F1. 반응형 프롭 자리에 인라인 `:Compute`를 쓰면 strict가 죽는다 — 버그(재현됨, 자주 밟음).** `D.TextLabel({ Text =
src:Compute(function(self) return \`{self:Get()}\` end) })`가 *"Expected (StateData<string>, string?, ...any) -> string but got
(t1) -> string where t1 = { read Get: … }"*로 거부되고, 같은 람다를 평범한 함수 인자로 넘기면 통과한다. 스토리 작성 에이전트
셋이 모두 밟았다. 우회는 `self: q.StateData<string>` 주석 또는 결과를 주석 단 지역 변수로 빼는 것(A8과 같은 가족). 생성
Declaration 필드 자리(`Field<T>` 입력 유니언)에서 콜백 매개변수의 기대 타입이 흘러들지 않는 것으로 보인다. 제안: 시작하기 04/
레퍼런스 03에 "프롭 자리 인라인 Compute는 `self`를 주석"을 한 줄, 근본 수선은 **사용자 결정 필요**.

**F2. A1(제네릭 State 추론)이 스토리 헬퍼에서도 그대로 — 재현됨.** `StoryKit.rebuild(state, build)`, `ListData`, 표시용 `show(src)`
같은 작은 제네릭 헬퍼마다 `<<T>>`를 강제당했다. A1의 처방이 정해지면 같이 풀린다.

**F3. 도구: Lune 0.10.5는 인덱스 타입(`T["Field"]`)도 못 읽는다.** `const`·`<<T>>`처럼 줄 보존 재작성으로 지울 수 없는 문법이라
킷은 인덱스 타입 대신 문자열 유니언을 인라인했다. B1(소비자 테스트 런타임) 선택의 또 하나의 근거.

**F4. UI Labs와의 궁합(기록).** UI Labs는 스토리마다 가상 require로 모듈을 새로 싣는다 — quad 싱글턴(`require(quad_base)`의
`UseProvider`)도 스토리마다 새 인스턴스라 스토리 사이 상태가 섞이지 않는다(좋음). 문자열 require 리졸버는 `./`·`../`·`@self`·
`@game`를 `FindFirstChild` 이름 탐색으로 푼다(소스 `PepeElToro41/ui-labs@1e8f45f:src/Utils/HotReloader/Utils.ts`의
ResolveStringPath) — 이름에 점이 든 `.pesde`·`3.2.0` 폴더도 이름 그대로 찾으므로 풀릴 것으로 읽히지만 **실기기 미확인**.
플러그인 위젯 안에선 `UserInputService`가 입력을 못 받아 킷마다 입력 주입 모듈(`src/Input.luau`)을 두었다 — quad 코어는
엔진 입력을 직접 만지지 않으므로 해당 없음.
