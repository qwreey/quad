# 2026-08-13 열세 번째 세션 — 0-Y 재실측, 재귀 제네릭 반환 타입은 Luau 상위 한계로 확정

**한 줄 요약**: `question.md` 0-Y(`:Compute(fn)`의 lazy 핸들 계약)를
44개 스파이크로 재실측했더니 **여섯 번째 세션의 1차 판정("콜백이 raw
값을 받으면 완전 클린")이 틀렸음**이 드러났고, 진짜 원인은 콜백 계약이
아니라 **Luau가 재귀 제네릭의 다른 인자 반환을 못 다루는 것**으로
확정 — 계약은 그대로 유지, `base/typing-limits.md` 신설로 전역 규약화.

---

## 1. 발단 — 사용자가 직접 부딪혀본 흔적에서 시작

사용자가 레포 루트에 `test-ignoreme.luau`를 만들어 0-Y를 직접 파보고
있었음(try1~sub-try6: 명시 제네릭 인자, `Self` 자유 제네릭, `type
function`으로 State 자체를 만들기, `Echo<Self>` 지연 평가 등). 요청:

> "0-Y에 대해 가능한 모든 걸 시도해봐. try-ignoreme 폴더 만들고 거기
> 안에서 해. luau의 진짜 작동 방식을 봐야 하면 클론해도 좋아."

`luau`/`luau-analyze`가 처음엔 PATH에 없었는데 사용자가 env를 갱신해줘
사용 가능해짐. grounding용으로 `luau-lang/luau` HEAD(`c73bb37`)를 clone,
나중에 교차검증용으로 `luau-lsp` 1.69.0 바이너리도 받음.

## 2. 1차 결론 — 쪼개기로 풀었다고 판단 (나중에 절반만 맞았음이 드러남)

실험 `00`~`25`로 원인을 좁힘:

- **2×2 매트릭스**(`02`~`04`): T가 제네릭인지는 무관, **`Compute`가 자기
  로컬 제네릭 `U`를 가진 채 재귀 타입의 필드로 선언돼 있다는 것**이 원인.
- `:` 메소드 문법은 무관(`05`), 자유 함수로 빼면 재귀가 있어도 통과
  (`06`/`07`/`10`), 리턴 주석만으론 안 풀림(`09`/`12`), self를 자유
  제네릭으로 열어도 안 됨(`13`).
- **회피책 발견**(`14`): `State<T>`를 "Get만 있는 `StateData<T>`"와
  "`Compute` 등을 얹은 `State<T>`"로 쪼개고 메소드의 self/콜백 파라미터를
  `StateData<T>`로 가리키게 하면 무주석 람다가 통과.
- 스트레스 테스트(`19`/`23`/`24`)도 통과 — 체이닝, `State<State<T>>`,
  `Source` 서브타이핑, 이형 `With`까지.

이 시점에 리포트 초안을 썼고, **"쪼개기로 문제가 완전히 풀렸다,
코드 생성도 불필요하다"**고 결론냈음.

### 이 단계에서 낸 방법론 실수 (사용자가 잡아줌)

사용자가 "저거 error-type 가득하더라"고 지적해 `21`을 축소 재현하려
했는데, 그 직전 `cd`로 셸이 clone한 `luau/` 서브레포 안에 들어가 있는
걸 놓쳐서 **`21b`~`21e`가 존재하지 않는 파일을 대상으로 실행**됐음.
`luau-analyze`는 **파일이 없어도 exit 0 + 출력 없음**이라 이걸 "통과"로
오독 — 한동안 "분기가 두 개면 통과, 하나면 실패"라는 엉뚱한 결론을 낼
뻔했음. 사용자가 "23은 멀쩡하네"라고 짚어준 것도 재확인 계기가 됨
(23은 `cd` 전 결과라 실제로 맞았음). 올바른 디렉터리에서 전체 재실행해
바로잡음.

**교훈**: 도구가 "조용히 성공"하는 경로(없는 파일 = exit 0)를 항상
의심할 것. 이게 바로 아래 3절에서 훨씬 큰 스케일로 반복됨.

## 3. 결정적 반전 — 사용자가 체이닝을 더 넣어보고 발견

사용자가 `23` 아래에 직접 한 줄을 더 붙여봄:

```lua
local t = combined:Compute(function(self: StateData<number>)
    return true
end)
```

> "t는 error type 나오더라"

CLI로는 클린 통과였는데 에디터 진단이 달랐음. 원인을 쫓다가
**`luau-analyze --annotate`(추론된 실제 타입을 소스에 찍어주는 옵션)**를
써봤고, 여기서 진짜가 드러남:

```lua
local doubled:Unifiable<Error>=state:Compute(function(s:StateData<number>): number ...)
```

**"진단 0건으로 통과"했던 것들이 전부 `Unifiable<Error>`(Luau 내부
미해결/에러 타입)였음.** 즉 타입 체커가 조용히 포기한 상태였고, 겉으로만
성공처럼 보였던 것.

### 얼마나 나쁜지 확인 (`27`/`28`)

```lua
local s = n:Compute(function(x) return tostring(x:Get()) end) -- State<string>이어야 함
local wrong: number = s:Get()   -- ❌이어야 하는데 에러 안 남
```

LHS에 일부러 틀린 타입을 명시해도(`28`) 통과. `luau-lsp
--flag:LuauSolverV2=true`로도 동일 재현 — 도구 문제가 아님.

### 어떤 formulation으로도 안 풀림 (`30`/`31`/`34`)

| 실험 | 형태 | 결과 |
|---|---|---|
| `28` | 쪼개기 + 무주석 | 불안전 |
| `30` | 쪼개기 + 콜백 리턴 타입만 명시 | 불안전 |
| `31` | 쪼개기 없이 파라미터/리턴 둘 다 명시(선택지 1) | 불안전 |
| `34` | **raw 값 계약**(선택지 2) | 불안전 |

**`34`가 이 세션에서 가장 중요한 발견** — 여섯 번째 세션 audit이 "콜백이
raw 값을 받으면 완전 클린(0건)"이라고 적어둔 바로 그 케이스인데, 그건
**"에러가 안 뜬다"만 확인한 것**이었고 반환 타입은 확인한 적이 없었음.
`--annotate`로 열어보니 똑같이 `Unifiable<Error>`. **즉 0-Y의 선택지
1/2/3 프레이밍 자체가 잘못된 전제 위에 서 있었음.**

### 정확한 경계 (`32`/`33`/`35`)

대조군으로 좁힌 결과 **"제네릭을 감싸 반환하는 것" 자체는 문제가 아님**:

- `33`: 같은 T로만 재귀(`-> State<T>`) → ✅ 진짜 sound
- `35`: 재귀 아닌 컨테이너(`-> Box<U>`) → ✅ 진짜 sound
- `07`/`32`: 안 감싸고 그대로(`-> U`) → ✅ 진짜 sound

문제는 정확히 **"자기 이름을 자기 타입 파라미터와 다른 인자로 다시
감싸 반환"** 하나뿐.

## 4. 사용자가 RFC를 찾아옴 — 세션 방향이 여기서 정해짐

세션 중간에 사용자가 직접 리서치해 두 RFC를 보내옴:

> "https://rfcs.luau.org/relax-recursive-type-restriction.html,
> https://rfcs.luau.org/recursive-type-restriction.html 를 보면 미래에
> Promise<T>에 대한 andThen과 같은 흔한 유형을 위해 다른 유형 리컬션을
> 미래에 지원할 계획은 있어보임. 따라서 우리는 당장 luau가 타입으로써
> 그것을 제공하기 전까지는 제공 못 한다는 제약사항이 생겨도 될 것
> 같다는 결론이 나왔음."

fetch해보니 정확했음 — RFC가 **거부되는 예시로 직접 드는 게**
`Promise<T>.andThen: <U>(self: Promise<T>, callback: (T) -> Promise<U>)
-> Promise<U>`로, **우리 `Compute`와 글자 그대로 같은 모양**. 완화 근거는
"This pays for itself in the considerable gain in expressivity gained
for users of the type system"이고, 메커니즘은 "타입 별칭을 진짜 type
function처럼 취급해 lazy expansion"이라는 **순수 내부 변경(사용자 문법
변경 없음)**.

옛/새 솔버 대조로 상태도 정확히 파악: 옛 솔버는 이 패턴을 **선언
시점에 거부**, 새 솔버는 **선언은 받아주지만 인스턴스화는 아직 안 됨**
→ 그래서 "조용히 새는" 중간 상태.

## 5. 후속 질문 두 개

사용자 추가 요청:

> "State<T>:Compute<FromState, ToState>() 로써 직접 넣어주는 것.
> 혹은 RFC가 낙관적으로 보는 방향성이 가능하도록 플레이싱 홀드 해놓고
> 나중에 변경될 경우 자연히 등록될 수 있는 방식을 찾고 싶습니다."

### 5-1. 명시 제네릭 인자 — 문법은 실재하나 이 케이스엔 무효

Luau 소스(`Ast/src/Parser.cpp`의 `parseMethodCall`)를 직접 열어 확인:
메소드 호출 뒤 `<`가 **연달아 둘**(`<<`) 오면 `parseTypeInstantiationExpr`로
분기(단일 `<`는 비교 연산자와 충돌해서 안 됨). 이 정보는 새 솔버의
`ConstraintGenerator.cpp`(2818행)에서 실제로 읽혀 `FunctionCallConstraint`까지
전달됨 — 죽은 코드 아님.

- `42`(일반 제네릭 `identity<<string>>(...)`): ✅ 진짜 작동, 틀린 대입도 잡힘
- `40`(우리 `Compute<<string>>`): ❌ 여전히 `Unifiable<Error>`
- `41`(문제 A에 적용): ❌ 완전 무효과

→ **U를 명시로 못박아도 `State<U>` 확장 단계가 안 되므로 무용지물.**

### 5-2. 플레이스홀더 — 필요 없음(좋은 소식)

RFC 완화가 순수 내부 변경이고 우리 선언이 **이미 그 대상 모양 그대로**라,
지금 뭘 심어둘 필요가 없음. 오히려 **하지 말아야 할 것**이 분명해짐 —
한때 검토됐던 "T별 코드 생성(구울 때 인라이닝)"으로 갔다면 제네릭
자체를 없애버려 RFC 수혜 대상에서 스스로 이탈했을 것.

## 6. 사용자 최종 정리 → 확정

> "해당 제한이 풀리기 전까지는 명시적 타입바인딩으로 `:` 사용이
> 강제되나, 그것이 들어오고 난 뒤에는 풀리게 된다. 지금으로써 quad
> 프로젝트가 타입을 비틀어 해당 시도를 하는 건 전혀 적합하지 않고,
> 이것은 상위의 Luau의 현 한계다. RFC와 해당 이슈 해결의 수혜를 받게
> 될 때 해결될 이슈로써, 당장 우리가 할 수 있는 바 없다."

이 "명시적 타입 바인딩" 대응이 실효가 있는지는 문서화 전에 별도
실측(`43`)으로 확인했고, **먹힘**:

```lua
local s: State<string> = n:Compute(...)
local ok:  string = s:Get()      -- ✅ 통과
local bad: number = s:Get()      -- ✅ 에러남
local bad2 = s:NoSuchMethod()    -- ✅ 에러남
```

즉 구멍은 **"그 한 줄이 진짜 그 타입을 만드는가"** 하나로 좁혀지고,
나머지 코드베이스 전체는 정상적으로 타입 안전. 콜백 **안**의 로직도
진짜 체크됨(`29`).

## 7. 이번 세션의 문서 작업

사용자 지시: "try-ignoreme에서 luau 폴더와 luau-lsp-bin, lsp-settings.json,
v.luau를 지우고 `.claude/audit/type-recursion-issue` 등 적절한 폴더 안으로
이동. 또 이 리서치를 기반으로 타이핑 전역에 있어 우리의 한계, 우리가
해두어야 하는 지점을 정리. 전체 문서에 대해 이 사항을 적용."

1. **정리**: clone(24M)/lsp 바이너리(16M)/설정/스크래치 삭제,
   `REPORT.md` + `spikes/` 44개를 `.claude/audit/type-recursion-issue/`로
   이동(`try-ignoreme/`는 제거). audit 폴더에 스크립트를 같이 두는 건
   기존 관례의 예외라 그 이유를 문서에 명시.
2. **`base/typing-limits.md` 신설** — 흩어져 있던 타입 한계를 통합
   (재귀 제네릭 반환 / Modifier `Overridden` 서브타입 / Attribute 제네릭
   키 narrowing / nilable default 오버로드 / `store.key` type function),
   0번에 대전제("Luau 한계를 우회하려 타입/API를 비틀지 않는다"), 6번에
   "성립이 확인된 것"(오해 방지), **7번에 새 타입/API 설계 시 체크리스트**,
   8번에 미해결 추적.
3. **0-Y 해소 전파**: `question.md`에서 제거(최우선 2건→1건),
   `archive/question-resolved.md`에 해소 배너, `base/`
   (bind-system/modifier/tween/effect/store-semantics) 배너 5곳을 해소
   결론으로 교체, `research/`(operator-sugar/pre-implementation-audit) 2곳,
   인덱스 레이어(`CLAUDE.md`/`.claude/README.md`/`ROADMAP.md`/`HUMAN_TODO.md`),
   `luau-test/STATUS.md`+`README.md`(스파이크 `08`을 `done/`으로 `git mv`,
   `review-required/`가 **비었음**).
4. **가장 중요한 정정**: `audit/luau-test-first-run-2026-08-13.md`에
   정정 배너 + **본문 표/문단/결론까지** 수정 — 이 문서의 "raw 값 =
   완전 클린" 판정이 이번에 뒤집힌 당사자인데, 배너만 달고 본문을 안
   고치는 게 CLAUDE.md 체크리스트 2번이 경고하는 바로 그 실패 패턴이라
   전수 수정.
5. **HUMAN_TODO 6번 신설**: 에디터(`luau-lsp`)의 기본 솔버가 옛 솔버라
   CLI와 진단이 다른 문제 — M0 착수 때 확인(지금 막진 않음).

`doc-check.py` **ERROR 0** 유지 확인.

## 8. 교훈으로 남길 것

- **`luau-analyze`가 진단 0건이어도 타입이 해소됐다는 뜻이 아니다.**
  이번 건 전체가 이 함정 하나에서 비롯됨(여섯 번째 세션도, 이번 세션
  초안도 같은 함정에 빠졌음). 앞으로 타입 스파이크는 **`--annotate`로
  추론된 실제 타입을 눈으로 확인하고, "일부러 틀린 타입에 대입해서
  진짜 에러가 나는지" 음성 대조군을 같이 둘 것** —
  `base/typing-limits.md` 7번에 규칙으로 명문화했음.
- **사용자가 직접 한 줄 붙여본 게 두 번 다 결정적이었음**(체이닝 추가로
  `error type` 발견, RFC 검색). 에이전트가 "통과했다"고 보고한 걸 그대로
  믿지 않고 만져본 것이 초안의 잘못된 결론을 막았음.
- **도구의 조용한 성공 경로를 의심할 것** — 없는 파일에 exit 0을 주는
  `luau-analyze` 동작 때문에 중간에 잘못된 결론을 낼 뻔했음.
