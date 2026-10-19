# 생성 Declaration 표면 재검토 — 클래스별 타입 복제 대신 타입 함수로 조립

> **상태 [2026-09-30 신설 — round13 묶음 8b 회신에서 사용자가 제기, 결정 없음]** 원장 round13 §4 Q87·Q122·Q127(생성기
> `scripts/gen-d.py`가 만드는 타입의 정책 셋)을 답하는 자리에서 사용자가 문제를 생성기 자체로 옮겼다. 셋은 이 문서가 정리될 때까지
> 보류한다(원장 각 문항 끝 보류 문단). 선행 결정: 2026-09-16 "생성 D = stable, 클래스 매개 type function 경로 = unstable 백로그"
> (`base/typing-limits.md` 8.22, `session/2026-09-16-01-d-typefunction-measurement.md`) — 이 문서는 그 백로그를 다시 연다.

## 1. 사용자 제기(2026-09-30, 원문)

> *"보조 맵을 내도 좋겠긴한데, 그럼 너무 verbose 해지지 않는지만 봐줘. 재수출은 되어도 될것 같은데, 변경 가능한 표면일 수도
> 있겠음. 대충 만들어진 표면같아. 좀 관측이 필요해. 깊게 다뤄보진 못한것 같음. (slot 이나 다른 이야기에 비해서) 사실상
> <Class>(Out|OnChange|Modifier|) 로 계속 뭔가 복제되고 있어서 define 규모가 너무 커질수도 있어. Out<Frame> 식으로 타입함수로 받는게
> 필요할지도. D 생성도 타입함수로 완화해서 필요에 따라 넣어야할것 같다고 해오긴 했어. 보통 lsp 가 안 열린 파일은 연산 안 해서
> New<<Frame>> "Frame" {} 식으로 쓴다 하면, 비록 DX관점에서 손으로 쓰기는 힘들지만 위에서 Frame = New<<Frame>> "Frame" 해둘 수
> 있거든. 이건 이미 quad1 에도 유사했어. 쓸것들 전부 위에서 나열해두고 썼어. q.Frame 식으로 나오면 힘드니까, 또 q의 자동완성도
> 많이 복잡해져. D자체가 가진 문제가 있는것 같아. 재수출이 계속 늘어나는것도 어찌보면 문제야. Modifier 나, Out, Frame 같은게
> 타입함수로 조립되고 필요한걸 유저가 local FrameModifier ... 식으로 만들어낼 수 있는 표면을 주고, 이미 실측한 studio 와 lsp 간
> 차이를 매꿀 수 있지 않나 생각이 들어. 타입 함수에서 예외처리를 넣어가며 처리하는게 더 나을지도. 큰 규모에서 보면 이것도 문제가
> 다른곳에서 오는것 같아. (gen d 생성기 자체가 문제다. 해키하게 코드를 생성하는 느낌)"*

## 2. 문제의 모양

- 클래스마다 같은 틀의 타입이 복제된다 — `<Class>Modifier`·`Into<Class>`·`<Class>Elem`(docs-review 2-2 (d) 재수출), 생성 모듈 안의
  `<Class>OnChange`, 그리고 Q87이 제안한 충돌 이름 보조 맵. 새 축(Out·OnChange…)이 생길 때마다 "클래스 × 축"으로 정의가 는다.
- 루트 재수출이 계속 는다(사용자: *"재수출이 계속 늘어나는것도 어찌보면 문제"*) — `q`의 자동완성도 복잡해진다.
- 생성기는 문자열 템플릿으로 Luau 타입을 찍어 낸다 — 예외(충돌 이름·Deprecated 허용목록·Hidden 되살림·nil 팔)가 생성기 분기로
  쌓인다(사용자: *"해키하게 코드를 생성하는 느낌"*).
- 대안 방향(사용자): 타입 함수로 조립 — `Out<Frame>`·`Modifier<Frame>` 같은 표면을 주고, 쓸 것을 사용자가 파일 위에서
  `local FrameModifier = …`/`Frame = New<<Frame>>("Frame")`처럼 꺼내 쓴다(v1에서도 쓸 것을 위에 나열하는 관행이 있었다). 열리지 않은
  파일은 LSP가 연산하지 않으니 비용이 필요한 곳에만 든다. 예외는 타입 함수 안에서 처리.

## 3. 이미 아는 제약(재측정 전 출발점)

- 8.22: 수출하는 type function은 정의 모듈에서 한 번 인스턴스화(프라이밍); 클래스 타입 데이터는 체커마다 다르고(Studio·luau-lsp·CLI)
  읽기 전용 표시는 어디에도 없다 — 2026-09-16 "stable 유지" 결정의 근거. 사용자는 이번에 그 차이를 타입 함수 안의 예외 처리로 메울 수
  있지 않냐고 본다.
- 8.18 정정: CLI "전 FFlag 켬"의 `LuauDoNotExportBrokenTypeFunction`은 실사용자 환경에 없다.
- 생성 D 크기·검사 시간 한도(8.28 — 한도 플래그 없이는 생성 Declaration 자리의 에러가 조용히 사라짐).

## 4. 이 문서가 정할 것(열림)

> **[2026-10-19 상태]** 3·4·5번도 5절 끝 문단에서 닫혔다(남은 것은 2차 실측 M1~M4와 이름 정리).
>
> **[2026-10-16 상태]** 1·2번은 5절에서 결정됐다. 3·4번은 실측으로 방향이 나왔고(Policy 데이터 흡수·생성기는 데이터만) 사용자 확인 대기, 5번은 Q87·Q127이 클래스 먼저 커리로 실측상 해소 가능·Q122는 이름표로 정리 가능 — 셋 다 사용자 결정 대기. 진행 상태의 소스는 5절.

1. 타입 함수 조립 표면의 모양 — 어떤 축(Modifier·Into·Elem·Out·OnChange·PropTypes)을 타입 함수로, 이름과 인자 모양.
2. 생성 D(`q.Declaration`)를 유지·축소·대체할지, 기존 재수출(`<Class>Modifier` 등)의 운명(3.x 안정화 구간 — BREAKING 허용 여부).
3. 체커 간 클래스 데이터 차이를 타입 함수 안에서 어떻게 흡수하는지 — 실측(Studio·VSCode luau-lsp·CLI) 필요.
4. 생성기의 남는 역할(엔진 API 덤프 → 데이터 테이블만?).
5. 보류된 문항의 처리: Q87(충돌 이름 `q.Out` — 스파이크 C4는 `OutFn`에 여섯 줄짜리 보조 맵, verbose하지 않음), Q122(`OnChangeDescriptor`
   두 벌), Q127(객체 참조 읽기 표면 `?`).

## 5. [2026-10-16] 트랙 재개 — `Spread`·`OnEvent`가 같이 들어옴

사용자가 `q.Spread`와 배열부 이벤트 디스크립터 `q.OnEvent`(2026-10-16 이름 확정 — sonnet·Gemini 둘 다 추천, `audit/naming-onevent-2026-10-16/`)의 타입을 이 트랙에서 같이 설계하기로 했다 —
*"타입 함수를 통해서 구성하는걸 생각해뒀던 부분도 처리를 해야할 때가 와가는 느낌 … 그걸 처리하면서 같이 Speard 를 생각해보는게 좋겠음"*, *"declaration 이 또 길어지겠다만, 타입 함수와 같이 처리가 가능해진다면 해소될 것으로 보이고, 이미 크기에 어쨋거나 필요한 일이였어서 다음 트랙에서 같이 설계하면 되겠음"*.
타입 모양(사용자): `Spread<Ty>({ ... })`는 만드는 자리에서 `New`와 같은 자동완성, 결과는 내용 타입이 없는 `SpreadMarker<Ty>`, `New`가 그 마커를 받는다; 안쪽 Spread는 만들 때 편다
(`research/component-flatten-sugar-plan.md` 5절 2026-10-16 문단). 첫 단계는 실측 — 프로브 `audit/decl-typefn-probe-2026-10-16/`(CLI·LSP 하네스는 에이전트, Studio·VSCode는 사용자 — 2026-09-16과 같은 방식).

**[2026-10-16 첫 실측 뒤 사용자]** *"덤프 데이터에서 타입 함수가 필요한 부분을 채워넣어주는건 있을 수 있겠다"* — 4절 4번(생성기의 남는 역할)의 방향: 생성기는 엔진 API 덤프에서 **데이터**(읽기 전용·제외 목록, Hidden·Deprecated 되살림, 필요하면 클래스별 허용목록 — 프로브의 `Policy`)만 뽑아 타입 함수에 채워 넣는다. 실측 결과는 `audit/decl-typefn-probe-2026-10-16/REPORT.md`, Studio·VSCode 관측은 사용자 진행 중.

**[2026-10-16 4절 1번 회신 — 사용자]** 실측은 `audit/decl-typefn-probe-2026-10-16/REPORT.md` 끝 절들, 이름 탐색은 `audit/naming-ctor-2026-10-16/`.
- **값은 이름, 타입은 클래스 타입** — 런타임에 부르는 것은 클래스 이름 문자열을 커리로 받고(`X "Frame"`, `Spread "Frame" {…}`, `Modifier "Frame"`, `Mapper "Frame"`),
  주석 쪽은 클래스 타입을 받는 타입 함수(`Props<Frame>`·`Modifier<Frame>`·`SpreadMarker<Frame>`… — 같은 날 이름표로 `Spread<C>`, `research/declaration-naming-table.md` 5절). 이름→클래스는 덤프가 채우는 클래스맵 데이터(전역 클래스 타입을 그대로 가리킴 — 실측).
- **Spread는 커리 `Spread "Frame" {…}`** — 사용자는 New와 모양을 맞추려 했고, 실측으로 두 인자 꼴이 틀린 꼴(같은 호출 안 테이블이 문맥 타입을 못 받아 맞는 테이블도 거부)이라 기술적으로도 갈렸다.
  마커는 이름 싱글턴만(*"체크는 상위에서 해주니까"*). 누적형 `:Add`는 Modifier처럼 메소드를 가진 값이 되고 타입·비용 모두 성립(hover만 길어짐).
  재사용은 *"Spread 는 mutable 경로고 재사용 불가하게는 단순히 하위 Ref등이 묶임에 따라 처리되니 위임"* — 그대로 간다.
- **꺼내 두기 권장** — 인라인은 한 파일 ~300 호출에서 붕괴, 꺼내 두면 평평. 사용자: 파일별이 아니라 *"quad.luau 를 만들게 되는 곳에서 필요한것을 미리 New"" 해두고 익스포트"*하는 꼴을
  권장할 수 있다(공용 모듈 실측도 평평). Compose처럼 위에 나열하는 스타일은 나쁜 DX가 아니라는 판단. 그 공용 테이블 이름은 **`D`를 권장**(기존 `D.Frame {…}` 코드가 그대로 — 사용자 동의). **[같은 날 아래 결정으로 낮춤]** 기본 권장은 파일별 꺼내 두기 — `D`는 공용 모듈 대안을 쓸 때의 이름.
- **X(생성자 꺼내기) 이름 — 사용자 기울기 `Elem`, 미확정.** 기존 타입 쪽 `Elem`(배열부 자식 유니언)이 *"자기서술적이지 못했던"* 것으로 보고 그쪽을 `ChildrenOf`·`ArrItem`류
  (배열 자리에 놓인다는 뜻이 드러나는 이름)로 옮기면 `Elem`이 값 쪽에 가장 어울린다는 생각. `Class`는 묶음처럼 보여 리프 느낌이 없고 Luau RFC의 `class` 문
  (https://rfcs.luau.org/syntax-classes.html)과 겹쳐 피한다. `New`는 무엇을 만드는지 서술하지 못하고 그 자리에서 만들어질 것처럼 읽힌다.
- **`q.New()` → `NewModule`** 개명 동의(에러 메시지 문구에 이름이 들어가 있음 — 번호는 그대로).
- **타입드 최상위는 quad-roblox 몫** — 사용자: Modifier 런타임은 base에 있지만 *"탑래벨에 얹는게 타입 상 들어갈 것을 아는 quad-roblox 가 담당해야"*, 그리고 타입 함수가 든 멤버를
  테이블에 흘렸을 때 q 타입이 온전한지가 관심사. 실측: 지금의 `Self & P` 병합 그대로 얹어도 온전(base `q.Modifier()`와 타입드 `q.Modifier "Frame"` 공존, base 표면 검사 유지).

**[2026-10-16 같은 날 — 사용자, 위 문단의 "타입드 최상위" 정정] 교집합에 얹지 말고 백엔드 계약으로 분리.** 사용자: *"무리하게 나중에 luau 가 바뀔 경우 어떻게 될 지 모르는, 단지 지금 관측일 뿐인
부분에 얹혀 있기 보다, breaking 이 날 위협이 있는 표면을 두기 보단 적절한 분리 표면이 있어야"* — `Self & P` 교집합에서 base `Modifier`와 타입드 `Modifier`가 공존한 것은 관측일 뿐.
*"처음부터 Modifier/Spread 가 base 만 있을 땐 타입이 무정의가 맞으니까, 이건 탑 래밸에 있을만한 것이 아니라"*, Ref<T>·Slot<T>(내부 요소만 받고 확장 없음)와 경계가 다르고
**정확히 Elem과 같은 경계**. 결정(사용자 *"전부 동의함"*):
- base `Quad` 타입에서 `Modifier`를 빼고 Spread·Mapper·Elem도 두지 않는다. base 런타임은 그 최상위 이름에 `notInstalled` 스텁(Quad0108 — Tag·Attr·생명주기 op와 같은 장치).
  quad-roblox가 런타임과 타입을 함께 채운다 — 이 집합(Elem·Spread·Modifier·Mapper·OnChange·OnEvent·Out)이 **백엔드 계약**(사용자: *"백엔드가 묶어야 진짜 프리미티브가 돼"*;
  `OnChange`는 이미 이 모양).
- 런타임·타입이 짝으로 떨어지는 것은 코틀린식 생성자 꼴, 그렇지 못한 base 원재료는 **`q.Raw` 네임스페이스**(사용자 제안 `new*`/`rawNew*`/`Raw.` 중 메인 권고 — Modifier 원재료가
  `Overridden`·`TypedFactory`·`DefineSubtype`이 딸린 묶음이라 평평한 이름으로 못 풂, `q.Backend`(백엔드가 채우는 op)와 대칭): `Raw.Modifier`(지금 `q.Modifier` 통째),
  `Raw.Spread`, `Raw.Mapper`(지금 `newMapperClass`). `Overridden`은 `Raw.Modifier.Overridden`과 메소드 꼴로 남고 타입드 `q.Modifier "Frame"`(함수)에는 매달지 않는다.
  `MapperRoot`는 base `Claim`의 센티널이라 base에 남는다.
- Spread가 클래스 이름을 런타임 태그로 심을지는 결정 불필요(사용자) — 타입만으로 충분.
- 근거 실측(2026-10-16): 킷 둘은 base `q.Modifier()`를 0곳, 타입드 `D.Modifier.<Class>`를 176곳 쓴다; `TypedFactory`·`DefineSubtype`·`newMapperClass`는 quad-roblox 소스만 쓴다.

**[2026-10-16 4절 2번 — 사용자] 이전 생성 D는 포기, 필요한 곳에서 생성.** 사용자: *"이전 D는 포기하자. 필요 부분에서 생성하는것으로 두어야한다고 생각해."* 근거 실측(`audit/decl-typefn-probe-2026-10-16/REPORT.md`
끝 절): 지금 생성 D는 Studio에서 이미 too complex로 무너져 있고(같은 날 첫 Studio 실측), 같은 범위를 타입 함수로 다시 지어 한 모듈로 내보내도 실사용자 설정에서 무너진다(Studio는 조용히 NEG 0).
이어서 사용자 질문: *"타입 검사 시점에서 그 *모듈* 밖으로 안 나가면 다른 모듈과 겹치지 않고 임계가 모듈에 가둬진다면 … 지금 q.Frame 식으로 만들라가 아니라 파일마다 만들라가 더 나을 수 있는 지점"* —
실측으로 한도는 모듈이 내보내는 타입에 걸리고 파일 안의 무게는 그 파일에 갇힌다(같은 절). 권장 꼴(파일별 vs 공용 모듈)은 사용자 결정 대기.
- **[결정] 파일별 꺼내 두기가 기본 권장** — 사용자: *"파일별을 기본 권장으로 가자"*. 파일 위에 쓸 것을 나열(`local Frame = Elem "Frame"`, `local FrameModifier = Modifier "Frame"` …).
  근거: 한도가 모듈 반환 타입에 걸려 공용 모듈은 커지면 Studio에서 표시 없이 타입 검사가 꺼지는 반면, 파일 안의 무게는 그 파일에 갇힌다(비용은 파일당 0.04~0.17 s로 선형).
  공용 모듈은 "작게 유지할 때만"이라는 단서를 단 대안 — 같은 날 앞 문단의 "공용 테이블 이름 `D` 권장"은 그 대안을 쓸 때의 이름으로 낮아진다.
- **[결정 — 4절 2번 나머지]** 사용자: *"그러도록 하자. 3.3 을 내고, 재수출 - 복제해서 안 하고. 만드는걸로. 이전 기간은안 둬도 돼. 아직 사용자는 나 뿐이야"*.
  재수출 142개 중 클래스별 복제 125개(`<C>Modifier` 47·`Into<C>` 47·`<C>Elem` 31)는 별칭 없이 타입 함수 제네릭으로 대체(`research/declaration-naming-table.md` 5절), `Declaration`·`DeclarationMapper`는 D와 함께 삭제.
  **이전 기간 없음** — 한 릴리즈에서 바꾼다(옛 D는 이미 Studio에서 타입 검사가 꺼져 있고 레포 밖 소비자 table-sim은 vendor rev 고정·재수출 타입 0회). **변환 스크립트**를 레포 `scripts/`에 두고
  킷·문서 이전에 먼저 쓴다(실측: 킷 파일당 생성자 중앙값 2·최대 9, 이름 충돌 0). **릴리즈 순서**: 지금 `[Unreleased]`로 3.3.0을 먼저 내고(같은 날 bump·게시 — 일부 재게시 남음) Declaration 개편은 3.4.0의 BREAKING.
  `NewChild`는 내보내지 않는다(킷·table-sim·base 0회 — 새 표면에선 `Policy.Child` 데이터, 사용자가 쓰는 이름은 `PropsArrayItem<C>`); `RobloxExtension`은 그대로(q 타입 뒤에 붙는 확장 이름 — 사용자).
  `OnChangeFn`·`OutFn` 이름은 나중에(사용자).

**[2026-10-19 — 사용자, 4절 3·4·5번 닫힘] 원천·클래스 맵·표면 모양.** 메인 정리(층 셋 — 원천 → 표면 모양 → 이름) 뒤 사용자 회신. 경과 `session/2026-10-19-01-decl-3-4-decisions.md`.
- **원천(4절 3·4번)**: 덤프는 걷어내지 않는다 — **클래스맵·Policy(Deny·DenyIn·Inject·Child)·Hidden/Deprecated 되살림을 채우는 데만** 쓴다. 규칙(클래스 사슬 걷기, 오버로드 메소드 거르기, Instance 계열 `T?`)은 타입 함수 안. **체커마다 다른 요소(API 버전 차이 — Studio WorldModel 13 대 defs 8 등)는 흡수하지 않고 문서화해 인정한다.** 사용자 근거: *"타입 함수 자체가 유저 입력을 받아 처리하는것이고, 그 타입이란 부분도 Instance/Part/Frame 식으로 입력해둔 것 자체가 다른거니까. 이건 꼭 quad 가 아니더라도 `p: Part` 식으로 두더라도 p가 달라지는 부분이라 원래부터 유저가 인지해야할 부분"*. 남는 위험(타입 함수 안엔 pcall이 없어 멤버 하나가 `parameters()`에서 죽으면 그 클래스 표면 전체가 never)은 Policy Deny와 레포 핀 defs 게이트로 다룬다(구현 때).
- **클래스 맵 둘**: `Elem`·`Mapper`용은 **만들 수 있는 클래스만**(추상 클래스 생성을 이름 단계에서 막음), `Modifier`·`Spread`용은 **추상 클래스 포함** — 사용자 동의. 31이라는 범위는 생성 D가 클래스마다 타입을 써 넣던 크기 한도에서 왔고, 타입 함수 꼴에선 맵이 전역 클래스를 가리키기만 하므로 넓힐 수 있는지 2차 실측(M4) 중 — 범위는 그 결과 뒤.
- **`Out`도 클래스 먼저 커리 `Out "ScrollingFrame" "CanvasSize" (src)`**(Q87 해소) — 사용자: *"OnChange Class Prop (Fn) 형태 커링에서 유사히 Out Class Prop (Source) 모양의 유사 짝이 되어서 더 맞기도"*. 착수 전 실측: ReadOnly를 빼지 않는 읽기 표면(킷의 `Out("AbsoluteSize")` — M2).
- **Q127 (a) 채택** — 읽기 표면에서 Instance 계열 extern 프로퍼티를 `T?`로(타입 함수 규칙). 쓰기 표면은 그대로(nil 쓰기는 `None`).
- **Q122 닫힘** — `OnChangeDescriptor<K>`·`OnEventDescriptor<K>` 하나씩(`read` 필드, K = 프로퍼티·이벤트 이름; `Out`도 `OnChangeDescriptor<K>`를 돌려줌). K를 이름으로 두는 것은 놓인 자리 검사가 "그 클래스에 이 이름이 있나"여야 맞는 배치(`OnChange "Frame" "Visible"`을 TextButton에)를 통과시키기 때문.
- **`OnChangeFn`·`OutFn`·`OnEventFn` 비노출** — 사용자 근거: 문서 없이는 오해를 부르는 이름(*"`OnChange .. .. (fn)` 자리의 fn 타입을 나타내는가? OnChange 함수 자체의 타입을 나타내는가?"*). 필요한 쪽은 `typeof(q.OnChange)` — 타입 함수가 든 서명이 `typeof`에서 깨지지 않는지 2차 실측(M1) 중.
- **매퍼 루트는 지금처럼 값·타입 짝** — 사용자: Source()·Source<T>처럼 프리미티브는 런타임·타입을 짝으로 내보내니 싱글턴인 MapperRoot도 None과 같은 처리가 일치. 메인 확인: 이미 그렇다 — quad-types가 `None`·`Detach`·`KeyGone`·`MapperRoot` 넷 다 같은 이름의 `export type`과 q 값을 짝으로 둔다(`quad-types/src/init.luau` 89·90·97·103행, 값 744~779행). 생성 D와 함께 사라지는 것은 별칭 `D.Mapper.Root`뿐.
- **이름 정리(읽기 쪽 맵 이름, 탈출구)는 "정리 이후 더 크게"**(사용자) — 2차 실측(M1~M4) 결과를 본 뒤.
