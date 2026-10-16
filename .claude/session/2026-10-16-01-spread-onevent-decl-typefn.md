# 2026-10-16 — Spread·OnEvent 결정, 문서 정리, 킷 QA, table-sim 리뷰, Declaration을 타입 함수로(표면·이름·생성 D 포기)

메인 opus 5.5(high). Studio `quad-test`(PlaceId 105962699098904로 확인). 흐름과 사용자 논거만 적는다 — 실측·판정 원문은 각 audit 폴더. 10-15 세션(`session/2026-10-15-01-release-recheck-kits-list-lazy.md`)의
이어지는 날이고, 중간에 맥락 압축이 한 번 있었다(압축 전 부분은 요약에서 옮김 — 원문 대화가 없는 부분은 결론과 남은 인용만).

## 1. 압축 전 — devui 핸들, `q.Spread`·`q.OnEvent`, 문서 정리, UI Labs QA, table-sim 리뷰

- **devui 창 제어**: 핸들 없이 — `open:Set(true)`로 올리기, `Focused` 출력 Source. 깊은 곳은 Store/Context + 밖의 함수 패턴(사용자: *"이미 있는걸 잘 안 써서 생긴 문제"*), devui 내장 키는 소비자가 생길 때.
- **`q.Spread`(이름 확정 — `audit/naming-spread-2026-10-15/`)**: 같은 키는 뒤가 이김(props만 — 사용자: *"props 는 진짜로 경쟁이 있으면 안 되는게 맞긴함"*), 재사용 허용, 펴기 순서
  Spread→Modifier→PreRef→본문·배열 값은 놓인 자리에, 내용 타입 포기 + `Spread<Ty>`/`SpreadMarker<Ty>`(안쪽 Spread는 만들 때 펴짐). 누적형(`:Add`, 놓이면 잠김)은 사용자 아이디어로 기록.
  `research/component-flatten-sugar-plan.md` 5절.
- **`q.OnEvent(name, fn)` 확정**(`audit/naming-onevent-2026-10-16/` — sonnet·Gemini 둘 다): 배열부 이벤트 디스크립터, OnChange의 짝, 문자 키 이벤트는 그대로.
- **문서 정리**(Gemini, `audit/doc-cleanup-2026-10-15/`): `backlog/` 신설, upward-flow archive, 회신 끝난 round1~12·round14 반영표 archive, question·todos 정리.
- **UI Labs QA**(`feedback/consumer-kits-uilabs-2026-10-16.md`): material TextField placeholder·affix 페이드, DatePicker 입력 모드 정본 맞춤, 스토리 스크롤.
- **table-sim 리뷰**(`feedback/table-sim-2026-10-16.md`): 스킬 보강 A1~A8, UB 셋, distinct 파생 공백, 누적 Spread 필요 다섯 곳 — 후속은 사용자 결정 대기.
- **Declaration 트랙 재개**: 사용자 *"q.Spread 부터 보러 가고 싶어. quad 를 어느정도 이제 끝내 놓으려고"* → 프로브 `audit/decl-typefn-probe-2026-10-16/`(CLI·LSP 하네스, 사용자 Roblox 동기 FFlag
  재구성). 사용자 방향: *"덤프 데이터에서 타입 함수가 필요한 부분을 채워넣어주는건 있을 수 있겠다"* — 생성기는 데이터만.

## 2. Studio 진단 읽기 — `studio-analysis`

압축 직전 사용자가 업스트림 툴링에 Windows UIA로 Script Analysis 창을 읽는 도구를 만들었다(`studio-analysis --place quad-test --json`, 짝 `studio-output`). 이걸로 프로브 진단을 통째로 읽었다:
01~06은 리눅스와 위치·문구까지 같고, **06b(지금 생성 D)는 Declaration 모듈 안 too complex 4건으로 NEG 0/2** — 9/16 Studio와 달라짐, 킷도 같은 Declaration을 쓰므로 Studio에서 킷 D 타입 검사가
꺼진 상태. 사용자 관측(Studio 자동완성·VSCode)도 하네스와 같았다.

## 3. 무주석 OnChange 콜백 — 문서 정정

사용자 VSCode에서 `OnChange("Visible", function(v) end)`의 `v`가 `unknown`. 하네스로 갈라 보니 오용은 `function(v)` 자리에서 잡히고(검사) hover·자동완성은 없다 → `base/typing-limits.md` 8.7 3번·
`base/onchange-plan.md`·`docs/reference/roblox/05-onchange.md`·생성기 머리 주석을 "검사만 된다"로 정정.

## 4. 4절 1번 — 표면 모양

- 메인이 클래스맵 + `keyof`/`index`로 **이름만으로 클래스를 잡는 꼴**(`New("Frame")`)을 먼저 실측(CLI·Studio 성립)해 가져감. 사용자: *"나도 그 방법을 생각하긴 했었어. 다만 그게 타입 자원을
  먹는지가 궁금함"* → 클래스맵의 `Frame`은 전역 클래스 그 자체(타입 함수 `==` 참), 맵 비용은 측정에 안 잡힘.
- **값은 이름, 타입은 클래스 타입**(사용자 동의). Spread는 사용자가 New와 맞추려 커리 `Spread "Frame" {…}`를 제안 — 실측상 두 인자 꼴은 같은 호출 안 테이블이 문맥 타입을 못 받아 맞는 테이블도
  거부(틀린 꼴)라 기술적으로도 갈림. 마커는 이름 싱글턴만(사용자: *"체크는 상위에서 해주니까"*). 누적형 `:Add`는 메소드를 가진 값이 되지만 비용 평평·hover만 길어짐; 재사용은 사용자:
  *"Spread 는 mutable 경로고 재사용 불가하게는 단순히 하위 Ref등이 묶임에 따라 처리되니 위임"*.
- **꺼내 두기**: 인라인은 한 파일 ~300 호출에서 붕괴, 꺼내 두면 평평. Modifier 값은 메소드 표면 + 태그(마커 아님), 주석은 평평.
- **백엔드 계약**: 메인이 `Self & P` 교집합에 타입드 멤버를 얹어도 온전함을 실측했으나 사용자: *"무리하게 나중에 luau 가 바뀔 경우 어떻게 될 지 모르는, 단지 지금 관측일 뿐인 부분에
  얹혀 있기 보다 … 적절한 분리 표면이 있어야"*, *"처음부터 Modifier/Spread 가 base 만 있을 땐 타입이 무정의가 맞으니까 … 탑 래밸에 있을만한 것이 아니라"*, *"백엔드가 묶어야 진짜
  프리미티브가 돼"* → base는 그 이름에 `notInstalled` 스텁, quad-roblox가 런타임·타입을 채움, 원재료는 `q.Raw`(메인 권고 — Modifier 원재료가 묶음이라). `q.New()` → `NewModule`.
- 이름 탐색 둘(`audit/naming-ctor-2026-10-16/`, `audit/naming-arritem-2026-10-16/`): 생성자 꺼내기 X — sonnet `Class`, Gemini `New`; 사용자 둘 다 기각(`Class`는 Luau RFC `class` 문·묶음처럼
  보임, `New`는 즉시 생성으로 읽힘), `Elem`으로 기울고 지금 타입 쪽 `Elem`을 비키게. 배열 자리 타입 — sonnet `Entry`, Gemini `Content`(Roblox `Content` 타입과 충돌, 메인 확인); 사용자:
  `Entry`는 *"작지만 네이밍을 소진시켜"*, 그리고 질문을 넓힘 — *"새로 들어올 Build 를 쓰는 네이밍들이 모두 자기서술적이고, 사용 빈도에 비해서 네이밍이 그게 맞는가"*.

## 5. 이름표 — `research/declaration-naming-table.md`

메인이 실제 사용 빈도(킷·문서)를 세어 원칙(빈도에 맞춘 길이·자기서술·부모 접두·값과 타입 같은 이름·안 쓰는 부품 비노출)으로 표를 짰다. 검토 `audit/naming-table-review-2026-10-16/`(Gemini
체계 검토 + sonnet 찬반 토론 — 사용자: *"Elem 관해서는 토론을 붙여보는 쪽이 맞아보임"*). 사용자 근거 *"type Elem<T> = Ctor<T> … 다만 이것은 커링 함수가 생성자 결과인것이고, Modifier 는
생성자가 커링된것"*(본인 단서: *"주관적이므로 과신하진 말고"*) — 토론이 "값·타입 이름을 갈라도 되나"로 좁혀짐. 결정: 값 `Elem "Frame"` + 생성자 타입 `ElemCtor<C>`, `ModifierInto<C>`,
`Spread<C>`(마커는 입력 자리 전용 — quad-types 정의), `ModifierField<T>`(변형 열은 *"지금은 내지 않고"*), `PropertyMap` 계열, `PropsArrayItem<C>`·`PropsHashPart<C>`.

## 6. OnEvent·OnChange 커리

사용자: *"커리 꼴이 되면 타이핑 문제에 해결이 보일것 같다 … 오버라이딩으로 선택될 수 있는지"* → 클래스 먼저 커리 `OnEvent "Frame" "MouseEnter" (fn)`를 제네릭·오버로드 둘로 실측: 둘 다 콜백에
문맥 타입이 흐르고(본문 줄에서 오용이 잡힘, Studio 같음) 오버로드는 이름 자동완성을 잃음. 확정: 제네릭 — 사용자: *"모양 자체는 커링으로 같기에. breaking 자체는 없을것임. 지금 가장 안정적인
방법인 그것으로 가자"*.

## 7. 4절 2번 — 생성 D 포기, 파일별 꺼내 두기

같은 범위(생성자 31 + Modifier 47 + Mapper 31)를 타입 함수로 다시 지어 한 모듈로 내보내면 실사용자 설정에서 무너지고 Studio는 조용히 NEG 0 — 한도는 모듈 반환 타입에 걸린다(생성자 31 +
Modifier 32는 삶, 40은 넘침; 반환하지 않으면 정상). 사용자: *"이전 D는 포기하자. 필요 부분에서 생성하는것으로"*, 이어서 *"임계가 모듈에 가둬진다면 … 파일마다 만들라가 더 나을 수 있는
지점"* → 실측: 파일 안의 무게는 그 파일에 갇힘(파일마다 31 + 47을 꺼내도 무너지지 않음, 파일당 0.04~0.17 s 선형). 결정: *"파일별을 기본 권장으로 가자"* — 공용 모듈은 작을 때의 대안.

## 남은 것

- 4절 2번 나머지(재수출 142개의 운명·킷 이전·CHANGELOG), 3·4번 정리, 5번(Q87·Q122·Q127), 이름표에 빠진 축 다섯의 이름(Field 변형은 보류).
- 사용자 결정 대기(그대로): table-sim 후속 넷, 3.3.0 bump 시기, 아이콘 팩 다섯, DatePicker 카드 높이.
