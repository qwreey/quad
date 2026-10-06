# 소비자 타입 표면 조사 — 제네릭 State 추론(A1)·공변(A2)·인라인 Compute(F1)·훅 콜백(A5b) (2026-10-06)

> **[2026-10-06 신설]** `feedback/consumer-kits-2026-10-05.md` A절·F절의 타입 마찰 넷을 멤버 단위로 좁히고, 갈래를
> 실측한 기록이다. 레포 소스·`base/`·quad-types는 고치지 않았다 — 실험은 전부 세션 스크래치에 레포 트리를 복사해
> 그 사본의 quad-types 세 벌(원본·quad-base 사본·quad-roblox 사본)을 고쳐 돌렸다. 새 공개 타입·시그니처 변경은 전부
> **사용자 결정 거리**이고 이 문서는 발견이다. 도구: luau-lsp 1.69.0 신 솔버 + `scripts/test.sh` 79행의 한도 플래그 셋 +
> 핀 고정 Roblox defs(교차 확인 일부는 luau-analyze 0.734).

## 머리 요약

A1(`State<T>`를 받는 제네릭이 `T`를 못 추론)의 원인은 **멤버 하나가 아니라 "교집합 + 그 안에서 `T`가 불변·반공변 자리에 서는 것"의 조합**이다. quad와 무관한 순수 Luau 재현이 있다 — `{ read v: T } & { read f: (T) -> () }`나 `{ v: T } & {}`를 받는 제네릭은 같은 "at least `X | nil`, at most `X`" 에러로 죽고, 같은 멤버를 한 테이블에 두면 통과한다. quad에서 그 조합을 만드는 것은 `State<T> = StateData<T> & {…}`(교집합)와 `StateData`의 `Get: (self: StateData<T>) -> T`(읽기·쓰기 필드라 불변이고, `self` 자리에 `T`가 있어 반공변)다 — `State`의 메소드 다섯을 전부 지워 `StateData<T> & {}`로 만들어도 A1은 그대로였다. A2(`State<EnumItem>` 자리에 `Source<Enum.EasingStyle>` 거부)는 같은 멤버들이 만드는 **불변성**이 원인이라 뿌리가 겹치고, `Get`을 `read`로 바꾸는 것과 수신자 `self`를 `any`로 바꾸는 것이 **둘 다** 있어야 풀린다. F1(프롭 자리 인라인 `:Compute`)과 A5b(`PreRef:Callback` 무주석)는 다른 뿌리다 — "다른 호출의 인자인 테이블 리터럴 안에서 호출에 넘긴 람다는 기대 타입으로 매개변수가 정해지지 않는다"는 luau-lsp 1.69.0(Luau release 729)의 순수 Luau 한계이고, F1은 거기에 `Get`의 `self: StateData<T>`가 겹쳐 에러가 된다(`Get`의 `self`만 `any`로 바꾸면 F1은 풀린다). A5b는 quad 타입 모양과 무관해 quad 쪽 수선으로는 못 푼다. 갈래 셋을 실측한 결과: **(c) 문서 처방만으로도 기존 공개 타입 `StateMarker<T>`로 읽기 전용 제네릭 매개변수의 A1·A2가 오늘 풀린다**(본문에서 캐스트 한 줄), 쓰기 가능한 매개변수(`Source<T>`)는 **(b) 새 평평한 마커형 타입 하나**(가칭)로 A1·A2가 풀리고 음성 검사도 유지된다, **(a) `State`/`Source` 모양 변경**은 A1·A2·F1을 크게 줄이고 게이트·두 킷 회귀 0이지만 **`state:Apply(…)` 결과 타입 검사가 사라지는 회귀**(`Operator.Sum`·주석 단 함수 팩토리)가 따라오고 `Source<T>` 제네릭 매개변수는 여전히 못 푼다. 권고 초안은 (c) 먼저, (b)는 사용자 결정, (a)의 최소판(`Get`의 `self`만)은 F1 전용 문항으로 따로.

## 방법

스크래치에 quad-base·quad-types·quad-roblox·quad-error·type-version-check·두 킷·`scripts/roblox-defs`를 `cp -rL`로 복사한
트리를 갈래마다 하나씩 만들었다(원본 트리, `getany`, `cov`, `stflat`, `flat`, `flatov`). 각 트리에서 같은 프로브 묶음과
회귀 묶음을 돌렸다.

- **순수 Luau 축소**: quad 타입을 쓰지 않는 최소 모양을 하나씩 바꿔 가며 어느 조합에서 에러가 나는지 이분했다(`probes/pure`).
- **quad 타입 사본 축소**: `StateData`/`State`/`Source`/`Observer` 정의를 그대로 옮긴 독립 헤더(`probes/variants`의 `*.txt`)에서
  멤버를 하나씩 지우거나 `read`/`self` 모양만 바꿔 같은 본문(`body*` 파일 — 양성 줄과 `EXPECT` 표시 음성 줄)을 검사했다.
  판정기는 `probes/tools/check.py` — `EXPECT` 줄은 에러가 나야 하고 나머지는 없어야 하며 어긋남만 찍는다.
- **실물 트리**: 갈래를 quad-types 세 벌에 패치(`probes/tools/patch_*.py`)한 트리에서 실제 `q.Source`·`q.Declaration`으로 쓴
  프로브(`probes/real`)를 돌렸다.
- **회귀**: 갈래 트리마다 `scripts/test.sh`의 타입 검사 세 그룹(luau-analyze 엔진 무관 그룹, luau-lsp 신 솔버 엔진 무관 그룹,
  quad-roblox 그룹 — 같은 플래그·같은 파일 목록), 두 킷의 `src`·`test`·`stories` strict(킷 `test/run.sh`의 첫 패스와 같은 명령,
  `play/`는 제외), 그리고 시작하기 strict 하네스 `audit/round13-e56-gs-strict-path/`(bare·annotated·minimal·workaround·howto01
  다섯 판)를 돌려 진단 줄 수를 비교했다(`probes/tools/regress.sh`). 스펙 런타임은 타입만 바뀌므로 돌리지 않았다.

재현 메모: `probes/tools`의 스크립트는 스크래치 경로가 박혀 있고, `probes/real`의 프로브는 사본 트리 루트 아래 `probes/`에
두고 돌리는 전제(`require("../quad-roblox/…")`)라 이 폴더에서 바로 돌지 않는다. 숫자 원문은 `probes/results.txt`(프로브별 어긋남)와
`probes/regress-counts.txt`(갈래별 회귀 진단 수).

## 원인

### A1 — 교집합 안의 불변·반공변 `T`가 하한에 `nil`을 섞는다

**순수 Luau 재현**(probes/pure의 repro_a1_pure — luau-lsp 1.69.0과 luau-analyze 0.734 둘 다 같은 세 줄이 실패). 같은 꼴의
`local function id<T>(x: W<T>): W<T> return x end; id(w)`(w: `W<number>`)에서:

| 모양 | 결과 |
|---|---|
| `{ read v: T } & { read f: (T) -> () }` — 교집합, `T`가 공변·반공변 둘 다 | **실패** "at least: number \| nil, at most: number" |
| `{ read v: T, read f: (T) -> () }` — 같은 멤버, 한 테이블 | 통과 |
| `{ v: T } & {}` — 읽기·쓰기 필드(불변) 하나 + 교집합 | **실패** |
| `{ v: T }` — 같은 필드, 교집합 없음 | 통과 |
| `{ read v: T } & { read x: number }` — 교집합이지만 `T`는 공변뿐 | 통과 |
| `{ read v: T, read g: (self: any) -> T } & {}` — quad `cov` 갈래의 `StateData` 모양 | 통과 |
| `{ read v: T, read g: (self: W<T>) -> T } & {}` — quad 지금 `StateData` 모양(`self`가 `T`를 품음) | **실패** |

즉 **교집합 자체도, `T`가 반공변인 것 자체도 혼자서는 문제가 아니다** — 둘이 같은 타입 안에서 만날 때(그리고 읽기·쓰기 필드는
불변이라 반공변 쪽을 겸한다) 신 솔버의 제네릭 추론이 하한에 `nil`을 섞는다. 왜 하필 `nil`인지는 솔버 소스를 보지 않아 좁히지
않았다(추정: 교집합의 조각 가운데 그 필드가 없는 조각을 쓰기 쪽에서 `nil`로 다루는 것). quad 없이 서므로 **업스트림 보고감**이다.

**quad에서의 원인 멤버.** quad-types 사본에서:

- `State`의 다섯 멤버(`Compute`·`Depend`·`Apply`·`Observer`·`Gate`)를 하나씩 지워도, 다섯을 한꺼번에 지워 `State<T> = StateData<T> & {}`로
  만들어도 A1은 그대로였다(probes/variants/bisect — min0·bis_*·add_*, 결과는 results.txt 끝). 원인은 `State`의 메소드가 아니라 **교집합의 첫 조각
  `StateData<T>` 안**에 있다.
- `StateData<T> = { read __quadState: true, read __quadStateValue: T, Get: (self: StateData<T>) -> T }`의 `Get`이 두 겹으로 그 조건을 만든다 —
  `read`가 없는 읽기·쓰기 필드라 불변이고, `self: StateData<T>`가 `T`를 반공변 자리에 둔다. `Get`을 `read`로만 바꾸거나(`sdonly`,
  `cov_selfSD`) `self`만 `any`로 바꾸는 것(`cov_noread`)으로는 A1이 안 풀리고, **`StateData`·`State`의 모든 멤버를 `read` + 수신자
  `self: any`로 바꾼 `cov`에서만** `id<T>(x: State<T>)`·`State<{ T }>`·제네릭 본문 안 사용이 통과했다.
- `Source<T>`는 `Set(v: T)`가 본질적으로 반공변이고 `Source = State<T> & {…}`가 교집합이라, `cov`에서도 `idS<T>(x: Source<T>)`는 실패한다.
  게다가 `cov`에서도 `State<T>`가 교집합이므로 **소비자 쪽 props에 `T`가 불변·반공변으로 하나라도 더 있으면**(`Options: { T }`,
  `OnChange: ((T) -> ())?`, 읽기·쓰기 `Option: T`) 다시 실패한다(Combo·Radio 꼴 — real_body L76·L83, body4).
- `State`를 교집합 없이 한 테이블로 펴면(`stflat`) 그 경우까지 풀린다. 단 `Apply`의 오버로드 교집합 `(<U>(…) -> U) & ((…) -> any)`도
  "`T`를 품은 교집합"이라 같이 걸려, 단일 시그니처(팩토리 자리를 유니언)로 바꿔야 했다. `Source`까지 펴면(`flat`) `Source<T>` 제네릭도
  풀리지만 `Source<boolean>`이 `State<boolean>?`(옵션 자리)에 안 들어가게 돼 두 킷 진단이 64·114건, quad-base 스펙 3건이 생긴다 — 기각.

대표 출력(원본 트리, real_body L15): *"No valid instantiation could be inferred for generic type parameter T. It was expected to be at least:
number | nil and at most: number"*.

**같은 가족이 아닌 것 — keyFn.** 피드백이 A1의 가족으로 적은 "제네릭 안에서 `Slot:List`의 keyFn"(*"Expected '((T, number) -> any)?' but got
'(T) -> string'"*)은 뿌리가 다르다. 순수 Luau에서 **비제네릭으로도** 재현된다 — 매개변수가 적은 **함수 값**(`key: (string) -> string`)은
매개변수가 더 많은 함수 타입 `((string, number) -> any)?` 자리에 안 들어간다(람다 리터럴은 맞춰져서 통과 — 피드백이 "비제네릭 자리에선
통과"라 본 것은 람다를 넘긴 경우로 보인다). probes/pure의 repro_arity_pure, 두 빌드 모두 실패. 처방은 소비자가 key 매개변수를
`(T, number) -> any`로 적는 것(real_body L69 통과).

### A2 — `State<T>`가 불변인 이유 둘

A2는 A1과 같은 멤버가 만드는 **불변성**이다. `State<number>`가 `State<number | string>` 자리에, `Source<Enum.EasingStyle>`이 `State<EnumItem>`
자리에 못 들어가는 이유가 독립적으로 둘 있다 — (1) `Get`이 읽기·쓰기 필드라 불변, (2) 모든 메소드의 수신자 `self: StateData<T>`가 `T`를 반공변
자리에 둔다. 사본 실험에서 한쪽만 고친 `cov_noread`·`cov_selfSD`는 A2가 그대로였고 둘 다 고친 `cov`에서 풀렸다. `Source`는 `Set(v: T)` 때문에
`cov`에서도 불변으로 남는다(음성 `takesSrcWide`가 계속 거부 — 쓰기 가능한 값은 불변이 맞다). 에러 길이: 원본 트리에서 A2 양성 줄 하나가
12.3KB, 진짜 타입 불일치(`State<string>` 자리에 `q.Source(1)`)는 11.7KB였고 `cov`에서는 양성이 통과하고 진짜 불일치가 7.7KB.

### F1 — 테이블 안 호출의 람다 + `Get`의 `self`

순수 Luau 재현(probes/pure의 repro_inline_lambda_pure): `take({ cb(function(inst) … end) })`처럼 **호출의 인자인 테이블 리터럴 안**에서 호출에 넘긴
람다는 기대 함수 타입으로 매개변수가 정해지지 않고 본문 사용에서 구조 타입이 추론된다(`inst`가 `{ Visible: boolean }`). 테이블이 인자가 아니거나
(`local t = { cb(…) }`), 테이블이 없으면(`take(cb(…))`) 통과한다. **luau-lsp 1.69.0에서는 실패, luau-analyze 0.734에서는 같은 파일이 통과**한다 —
더 새로운 Luau 빌드에서 고쳐졌을 가능성이 높다(quad 실물 코드로는 확인 못 함 — luau-analyze에 Roblox defs가 없다). typing-limits 8.13·8.30이
"원인 미확정"으로 남긴 현상이 이것으로 보인다.

F1이 에러가 되는 것은 거기에 quad 모양이 겹쳐서다. 람다의 `self`가 사용에서 `{ read Get: (t1) -> a }`로 추론되는데, 실제 값 `StateData<number>`의
`Get: (self: StateData<number>) -> number`는 `self` 자리가 반공변이라 `t1`(마커 필드 없음)을 받지 못해 그 구조 타입의 하위 타입이 아니다 — 피드백이
본 *"got (t1) -> string where t1 = { read Get: … }"*. `Get`의 `self`만 `any`로 바꾼 `getany` 트리에서 F1 양성(real_body L29, 시작하기 하네스의 GS 03·06
인라인 `Compute` 두 자리)이 통과했다. 대가: 같은 자리에서 **결과가 `self:Get()`을 그대로 넘기는 무주석 람다는 검사가 사라진다**(real_body L31 —
`Text = num:Compute(function(self) return self:Get() end)`가 통과; `self:Get() + 1`처럼 본문이 값을 제약하면 여전히 잡힌다). 원본 트리에서 그 줄이
에러였던 것은 양성 줄도 같이 죽는 F1 에러 때문이라 "검사"였다고 보기 어렵다 — Q105(무주석 파생 결과 무검사)와 같은 결의 구멍이다.

### A5b — quad 타입과 무관한 같은 Luau 한계

A5b는 F1의 첫 재료만으로 생긴다. 실물 트리에서 `q.PreRef(nil :: Frame?):Callback(function(inst) … end)`는 **독립 문장·`return` 문·함수 인자로는
통과**하고(킷의 `Util.preHook` 꼴), **`D.Frame({ … })`의 자식 배열 안에 인라인으로 넣을 때만** *"Expected '(Frame?, Ref<Frame?>) -> ()' but got
'({ Visible: boolean }) -> ()'"*로 죽는다(real_body L56). 순수 Luau에서 `Callback`을 `<Self>` 제네릭·비제네릭·`read`+`self: any` 넷 중 무엇으로 선언해도
똑같이 재현되므로(스크래치 a5 계열 — 결과는 이 문단에만 적음, 파일은 남기지 않았다) quad의 `Ref`/`PreRef` 모양을 바꿔서는 못 푼다. 처방은 지금처럼
`inst: Frame?` 주석이고, 더 새 luau-lsp가 나오면 다시 볼 것.

### 이미 알려진 한계와의 구분

- **8.11(공변 마커)** — 마커 `StateMarker<T>`가 공변이고 교집합이 아니므로 A1의 조건(교집합 + 불변·반공변 `T`)에 걸리지 않는다. 그래서 소비자
  매개변수에 마커를 쓰면 오늘 A1·A2가 풀린다(아래 (c)). 피드백의 "마커는 `:Get`이 없어 못 쓴다"는 반만 맞다 — 본문에서 `(x :: any) :: State<T>` 캐스트
  한 줄로 메소드를 부르면 된다(real_marker 전부 통과).
- **8.13·8.30(인라인 Compute·Observer)** — F1·A5b와 같은 뿌리로 보인다(위). 8.13의 "순수 Luau 최소 재현은 실패(Box<T> 모사는 클린)"는 이번에 테이블-인-호출
  모양으로 재현됐다.
- **8.19·Q121(`Slot:Single`의 `Item?` 하한)** — 같은 "하한에 `nil`" 문구지만 그쪽은 `Item? | StateMarker<Item?>` 팔에서 `nil`이 하한으로 들어오는 것이라
  메커니즘이 다르다. 이번 갈래들로 Q121을 다시 재 보지는 않았다(미완).
- **8.25(`Source`를 "마커 + `{ read Set }`"로 못 받음)** — **정정 후보.** 8.25는 "왼쪽 교집합의 모든 조각이 만족해야 한다"를 원인으로 적었는데, `cov` 트리에서
  8.25의 비제네릭 두 모양(`{ read Set: (self: any, value: string) -> any }`, `StateMarker<string> & { read Set: … }`)이 `q.Source("")`를 받고 음성(주석 단
  `State<string>`, `q.Source(5)`)은 계속 거부했다(real_825). 그리고 원본 트리에서도 `self: never`로 적은 평평한 쓰기 마커(아래 (b))는 `q.Source`를 받는다.
  즉 8.25의 실제 원인은 교집합 조각 규칙이 아니라 **`Source`의 수신자 `self: Source<T>`가 목표의 `self: any`와 반공변으로 안 맞는 것**일 가능성이 높다.
  8.25의 제네릭 모양(`<T>(… M<T> & { read Set })`)은 `cov`에서도 실패하는데 그건 A1(교집합 + 반공변 `T`)이다. 정본 정정 여부는 메인 판단.
- **8.29(선언된 테이블 타입의 제네릭 함수 필드는 `U`가 결과를 제약하지 않음)** — 아래 (a)의 회귀가 이 현상으로 보인다. 원본 `State.Apply`는 `self: StateData<T>`라
  `U`가 결과를 제약했는데(`n:Apply(q.Operator.Sum(1))`를 `State<string>`에 넣으면 에러), `self: any` + `read`로 바꾸면 8.29처럼 무검사가 된다.
- **Q145(Effect cleanup `return nil`)** — 이번 범위에서 다루지 않았다(미완).

## 갈래

갈래마다 프로브 결과와 회귀 수를 같은 묶음으로 쟀다. 회귀 묶음의 원본 기준값: test.sh 타입 검사 세 그룹 0·0·0, devui 0, material 0, 시작하기
하네스 bare 58·annotated 16·minimal 0·workaround 1·howto01 1(진단 줄 수). 시간은 갈래 사이 차이가 측정 잡음 안이었다(quad-roblox 그룹 4.1~4.3s,
material 10.0~10.8s).

| 갈래 | 풀리는 것 | 깨지는 것 | 비용 | 기존 결정과 충돌 |
|---|---|---|---|---|
| **(a-최소) `getany`** — `StateData.Get`의 `self`만 `any`로(필드는 읽기·쓰기 그대로) | F1(프롭 자리 인라인 무주석 `:Compute`). 하네스 bare 58→55, howto01 1→0 | 같은 자리에서 결과가 `self:Get()`을 그대로 넘기는 무주석 람다의 결과 검사가 사라진다(real_body L31). A1·A2·A5b·keyFn은 그대로 | quad-types 한 줄. 게이트·킷 회귀 0, 시간 차 없음 | 없음(문서의 "인라인 `Compute`는 `self` 주석" 처방이 선택이 된다) |
| **(a-공변) `cov`** — `StateData`·`State`·`Source`의 모든 메소드 필드를 `read`로, 수신자를 `self: any`로 | A1 중 `State<T>`만 받는 제네릭(`id`·`show`·`State<{ T }>`), A2(`State` 자리 넓히기), F1, 8.25의 비제네릭 모양. 하네스 bare 58→53, annotated 16→13, howto01 1→0. 진짜 불일치 에러 11.7KB→7.7KB | **`state:Apply` 결과 무검사** — `n:Apply(q.Operator.Sum(1))`를 `State<string>`에, 주석 단 함수 팩토리 결과를 `number`에 넣어도 통과(원본은 둘 다 에러, real_apply). F1의 L31 무검사(위와 같음). 못 푸는 것: `Source<T>` 제네릭 매개변수, props에 `T`가 불변·반공변으로 더 있는 경우(`Options: { T }`·`OnChange`), A5b, keyFn | quad-types 열 줄(메소드 필드). 게이트 셋·두 킷·type-surface-check 회귀 0, 시간 차 없음 | 레퍼런스 `core/03-state.md` 30행·`roblox/05-onchange.md` 92행의 "State는 불변" 서술과 Quadnomicon Vol. 4의 마커 동기 일부가 바뀐다. 8.11의 마커 규칙 자체(예산 근거)와는 충돌 없음. 2026-09-15 `read` 필드 결정((5))과 같은 방향 |
| **(a-평탄) `stflat`** — `cov` + `State`를 교집합 없는 한 테이블로 펴고 `Apply`를 단일 시그니처(팩토리 자리 유니언)로; `Source`는 `State<T> & {…}` 유지 | `cov`의 전부 + props에 다른 `T` 자리가 있는 `State<T>` 제네릭(Combo의 `Options: { T }`·`OnChange`). 하네스 bare 58→51, annotated 16→11(bare에서 `cov`보다 하나 더 풀린 자리는 GS 13 `count:Apply(Doubled)` — `Apply`가 무검사가 돼서 통과한 것이라 순수 이득이 아님) | `cov`와 같은 `Apply` 결과 무검사. `Source<T>` 제네릭 매개변수·A5b·keyFn은 못 품 | quad-types 스무 줄 안팎. 게이트·킷 회귀 0, 시간 차 없음 | `cov`와 같음 + typing-limits §1②("데이터부/메소드부 쪼개기")의 모양이 `State` 쪽에서 바뀐다(콜백 `self`는 여전히 `StateData<T>` — 무주석 콜백 추론은 프로브에서 유지) |
| (a-전부, 기각) `flat` — `Source`까지 한 테이블로 | 사본에선 `Source<T>` 제네릭까지 | `Source<boolean>` → `State<boolean>?` 거부(8.26 이웃): devui 64·material 114 진단, quad-base 스펙 3, 하네스 minimal 0→2 | — | — |
| **(b) 평평한 쓰기 마커 내보내기**(이름 가칭) — `{ read __quadState: true, read __quadStateValue: T, read Get: (self: never) -> T, read Set: (self: never, v: T) -> any }`; 읽기 전용은 기존 `StateMarker<T>` | **지금 타입 그대로** A1 전부(쓰기 가능한 `Source<T>` 자리 포함, `Options: { T }`·`OnChange`와 섞여도), A2. 음성 유지 — 다른 `T` 거부, 파생 `State`를 쓰기 자리에 넣으면 거부, quad 입력 자리(`Text = v`)에 그대로 들어감(real_never·real_marker 전부 통과) | 깨지는 것 없음(새 타입 추가). 못 푸는 것: F1, A5b, keyFn | 라이브러리 본문이 그 매개변수로 메소드를 부를 때 `(p.Value :: any) :: Source<T>` 캐스트 한 줄(`self: never`라 직접 `:Get()`은 에러 — 그 점이 material `Radio.ValueSource`와 같은 이유로 캐스트한 것) | **새 공개 타입 = 사용자 결정.** 8.11 "입력 자리 = 마커"를 라이브러리 저자의 props로 넓히는 것이라 원칙과는 맞는다. `self: any`로 적은 뷰는 원본 타입에선 `q.Source`를 못 받는다(real_view — `cov`가 있어야 됨) |
| **(c) 문서 처방만** | 읽기 전용 제네릭 매개변수: `StateMarker<T>` + 본문 캐스트로 A1·A2(real_marker), 또는 `StateData<T>`로 A1만(A2 안 됨, `:Get` 외 메소드 없음), 또는 호출자 `<<T>>`. 쓰기 가능: `<<T>>` 또는 킷 지역 평평한 쓰기 마커. F1: `self` 주석. A5b: 매개변수 주석. keyFn: `(T, number) -> any`로 적기 | 없음 | 문서 몇 줄(how-to 01 strict 안내·라이브러리 저자 절, typing-limits 한두 줄) | 없음 |

## 메인이 사용자에게 낼 권고 초안

라이브러리 저자가 제네릭 컴포넌트를 만들 때 막히는 핵심(A1·A2)은 **quad가 이미 세운 "입력 자리 = 마커" 원칙(typing-limits 8.11)을 라이브러리
저자의 props에도 그대로 적용하면 오늘 풀립니다.** 읽기만 하는 State 매개변수는 기존 공개 타입 `StateMarker<T>`로 받으면 `T`가 추론되고 넓은
자리(`StateMarker<EnumItem>`에 `Source<Enum.EasingStyle>`)에도 들어가며, 본문에서 메소드가 필요하면 `(x :: any) :: State<T>` 캐스트 한 줄을
씁니다. 그래서 첫째 권고는 **(c) 문서 처방**입니다 — how-to 01(또는 라이브러리 저자용 새 절)과 typing-limits에 "제네릭 컴포넌트의 State props는
마커로 받는다"와, 같은 자리에서 마주치는 나머지 셋(인라인 `Compute`는 `self` 주석, 자식 배열 안의 `PreRef:Callback`은 매개변수 주석, `:List`에 넘길
key는 `(T, number) -> any`)을 적는 것. 비용이 문서 몇 줄이고 BREAKING이 없습니다.

둘째는 **쓰기 가능한 매개변수**(`RadioButton { Value: Source<T> }`)입니다. 이건 문서만으로는 "`<<T>>`를 쓰게 하라"밖에 답이 없고, 실측상 해법은
평평한 쓰기 마커 타입 하나입니다(`self: never`로 적은 `Get`/`Set` — 원본 타입 그대로 `q.Source`를 받고, 파생 State는 거부하며, `T`가 추론됩니다).
quad-types가 이걸 내보낼지, 이름을 무엇으로 할지는 **새 공개 타입이라 사용자 결정**입니다(material 킷이 같은 모양을 이미 손으로 만들어 쓰고 있다는 것이
수요 근거). 내보내지 않으면 문서에 그 모양을 레시피로 싣는 것이 대안입니다.

셋째, **F1만 따로 떼어 낼 수 있는 작은 타입 변경**이 있습니다 — `StateData`의 `Get`을 `(self: any) -> T`로 바꾸는 한 줄로 프롭 자리 인라인
`:Compute`가 주석 없이 통과하고 게이트·킷 회귀는 없었습니다. 대가는 그 자리에서 `self:Get()`을 그대로 돌려주는 무주석 람다의 결과가 검사되지 않는
것(Q105와 같은 결의 구멍)이라, **공개 타입 시그니처 변경으로서 사용자 결정**에 올릴 만합니다. 다만 F1의 진짜 뿌리는 luau-lsp 1.69.0의 한계이고 더
새로운 Luau(0.734)에서는 순수 재현이 통과하므로, "다음 luau-lsp를 기다린다"도 같은 무게의 선택지입니다.

넷째, **`State`/`Source`의 모양 자체를 공변으로 바꾸는 갈래**(`cov`·`stflat`)는 A1·A2·F1을 가장 넓게 줄이지만 `state:Apply`의 결과 타입 검사가 사라지는
회귀(`Operator` 콤비네이터 결과를 엉뚱한 타입에 넣어도 통과)가 확인돼 **지금은 권하지 않습니다.** `Apply`의 수신자만 `{ read __quadState: true }`로 적으면
`Operator` 쪽 검사는 돌아오는 것을 사본 헤더에서 봤지만 주석 단 함수 팩토리 쪽은 여전히 무검사였고 실물 트리에서는 재 보지 않았습니다(미완). 고르더라도
`Source<T>` 제네릭 매개변수는 둘째의 쓰기 마커가 따로 필요합니다.

곁가지 둘: A1의 순수 Luau 재현(교집합 + 불변·반공변 `T`)과 테이블-인-호출 람다 재현은 업스트림(luau-lang/luau) 보고감입니다(후자는 0.734에서 이미 고쳐졌을
수 있어 최신 빌드 확인이 먼저). 그리고 typing-limits 8.25의 원인 서술은 위 "이미 알려진 한계와의 구분"의 근거로 정정 후보입니다.

## 미완

- 레퍼런스 문서(`docs/reference/`)·how-to(01 외)의 코드 펜스는 갈래별 strict 회귀를 돌리지 않았다 — 시작하기 하네스(HEAD `16dd5c32` 시점 사본)와
  how-to 01 펜스만 봤다.
- 스펙 런타임(`luau` 실행)과 `scripts/test.sh` 전체는 갈래 트리에서 돌리지 않았다 — 타입 검사 세 그룹·type-surface-check(`cov` 트리, 0건)만.
- `Apply` 수신자 마커형(`{ read __quadState: true }`)은 사본 헤더에서만 쟀다.
- Q121(`Slot:Single`)·Q145(Effect cleanup `return nil`)·A4(분기 대입 `*error-type*`)·A3은 이번 갈래들로 다시 재지 않았다.
- F1·A5b가 luau-analyze 0.734 계열 빌드에서 quad 실물 코드로도 풀리는지는 못 봤다(그 CLI에 Roblox defs 옵션이 없다).
- 쓰기 마커를 실제 킷(devui `RadioButton` 등)에 넣고 `<<T>>`를 걷어 내는 실물 시험은 하지 않았다 — 같은 모양의 프로브(real_never)로만 확인.
- `audit/README.md` 색인에 이 폴더를 넣지 않았다(이 조사 범위 밖 — 메인이 판단).

## 파일

- `probes/pure/` — quad 없는 재현 셋(repro_a1_pure, repro_inline_lambda_pure, repro_arity_pure; 각 파일 머리 주석에 기대 결과).
- `probes/variants/` — 독립 헤더(base·cov·stflat·cf_union·flat 등 `*.txt`)와 본문(body·body2~5·bodyS). `run.sh`가 헤더+본문을 붙여 검사한다.
- `probes/real/` — 실물 트리 프로브(real_body·real_neg·real_apply·real_kitlike·real_never·real_marker·real_view·real_viewbase·real_825).
- `probes/tools/` — 패치(`patch_cov.py`·`patch_stflat.py`·`patch_flat.py`), 실행(`lsp.sh`·`run.sh`·`runreal.sh`·`regress.sh`), 판정(`check.py`).
- `probes/results.txt` — 프로브별 어긋남 목록(트리 × 프로브, 헤더 × 본문). `probes/regress-counts.txt` — 갈래별 회귀 진단 수.
