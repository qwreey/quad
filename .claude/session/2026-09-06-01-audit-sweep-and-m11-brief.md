# 2026-09-06 (01) — 밤샘 자율 구간 착수: 감사 스윕 → fable 탐사 → M11

**맥락**: M7·M8이 완료된 직후(`c737a18`, 워킹 트리 클린). 사용자가 자러 가며
장기 자율 구간을 열었다. 이 파일은 그 착수 결정과 감사 스윕의 원문이다.

## 1. 사용자 지시 원문과 계획

> "다음 작업을 수행해 나갈래? 그 전에, 한번 fable 탐사자 던져서 지금까지
> 해온 작업이 문제 없었는지 보고싶어. 해당 탐사자는 서브에이전트를
> opus/sonnet 만 던질 수 있게 둬서 한번 굴려볼래? … 우선 페이블이 자잘한
> 문제를 덜 지적하고 큰 문제들에 집중할 수 있게 sonnet 기반 aduit 을 여러
> 각도로 계속 굴려서 자잘한 stale이나 베너 문제 등을 다 잡아간 다음 페이블
> 탐사를 굴리고, 다음 마일스톤들을 구현해 나가면 될것 같아. … 구현 문항지도
> 모두 같은 방법을 성공적으로 여러 마일스톤에서 수행했어서 그대로 형식을
> 사용하면 될듯 해. 내가 자러 가게 될듯 하니, 필요한 사전 질문은 지금 해줘.
> 해소되면 자유롭게 장기적으로 작업해도 좋아."

순서: ① sonnet 감사 루프(각도 교대, 밤샘 완화로 2 병렬) 0건까지 → ② 신선한
맥락 fable 탐사자 1개(fork 아님 — 새 general-purpose, model=fable; 그 안의
서브에이전트는 **프롬프트로** sonnet/opus 한정 — 하네스가 강제해 주지는
않는다) → ③ 다음 마일스톤 규약 문항지 + 구현.

## 2. 사전 질문 셋과 답(사용자, 2026-09-06)

1. **순서**: **M11(Tween) → M10 잔여 InstanceShorthand → M9(컴포넌트 합성)**
   — 권고 채택. 근거: Tween은 설계 전부 확정·Studio 검증 가능한 코드 작업,
   InstanceShorthand는 ROADMAP이 M11 이후 지정, M9는 설계 대화가 필요할 수
   있어 마지막.
2. **§0 회신**: **권고 (a)로 착수, 새 표면·메커니즘 문항만 멈춤** — 세 갈래
   규칙 그대로(그런 문항은 §4에 쌓고 그 단위를 멈춰 회신 대기).
3. **탐사 발견이 사용자 결정을 요구하면**: **영역이 겹칠 때만 착수를 막음**
   — §4에 쌓고, 다음 마일스톤이 만지는 영역과 겹치면 멈춤, 코드 상당 부분을
   무효화할 규모면 무조건 멈춤.

## 3. 감사 1라운드 (sonnet ×2 병렬 — 각도 A: base/·ROADMAP, 각도 B: 인덱스·원장)

각도 A 확실 3 + 의심 2, 각도 B 확실 4 + 의심 1. 전부 사실관계라 메인이 반영:

- ROADMAP M3 절 `H-39` 부모 체크박스 `[ ]` → `[x]`(자식 넷은 이미 완료).
- `ref-plan.md` "API 모양" 절에 `H-317` `<Self>` 정정 배너(문서엔 언급 0건이었다).
- `research/drive-hook-plan.md`에 "M8이 하드코딩 경로를 택했고 착수 전에 이
  문서를 안 열었다"를 기록 — 셋째 소비자가 생기면 다시 여는 리서치로 유지.
- `modifier-plan.md` 468행 "예약 메소드 셋" → 11절을 소스로 지시(단위 ④에서
  `As` 합류).
- `README.md`의 `modifier-plan`/`ref-plan` 색인 행이 8월 26일에 멈춰 있던 것 —
  M7/M8 완료 한 문장씩 추가.
- **날짜 정정**: 단위 ③(`76c0b20`)과 `H-317`(`c737a18`) 커밋은 2026-09-04가
  아니라 **2026-09-06 00시대 KST**다 — round18 §4·`H-321` 행, 머리말 3층의
  "같은 날 완료"를 고쳤다.
- `audit/m7-unit4-*.md` 표 5행에 `Define` 개명 전 표기 각주(8행만 각주가
  있었다).
- **스파이크 `22` 폐기 → `done/`**(메인 판단, 사용자 사후 확인 대상):
  재작성 지침이 요구한 전부를 M8 `spec.preref` 1절이 실물에 대고 상시
  회귀로 실측한다 — `01`/`04`/`05`/`15` 패턴. ROADMAP "재검증 대기" 항목·
  `luau-test/README.md`·`STATUS.md`(머리 배너·표 이동·`done/` 목록) 갱신.

## 4. M11 규약 문항지

`qa-request/m11-implementation-round19-brief.md` 신설(round19, `H-323`부터).
§0 일곱 문항 전부 권고 (a)로 착수(위 2번 결정). 새 표면이 걸리는 자리는
Q3(quad-types `Tween<T>`의 자리)·Q4(센티널 형태)인데, 둘 다 정본이 이미
"둘 중 하나"로 열어 둔 것을 코퍼스 관례(엔진 무관 quad-types / frozen
마커 센티널)로 닫는 것이라 멈추지 않고 진행한다 — 아침 검토에서 뒤집히면
비용이 낮다(타입 별칭·센티널 값 교체).

(이후 라운드·탐사·M11 진행은 이 파일 아래 절에 이어 쓴다.)

## 5. 감사 스윕 2~6라운드 (병렬 2, 각도 교대) — 종결

- R2 C(코드 주석·spec) 2건 + D(reference·research + R1 재검) 1건 — `Slot.luau`/`gen-d.py`/
  `spec.modifier` 헤더, `pre-implementation-audit` 2-5, session-summary 날짜 주석.
- R3 E(ROADMAP 전수) 3건 + F(M5/M6/M10 정본 vs 코드) 2건 — leaf 핸들러 체크박스,
  인덱스 3층 M11 착수 미반영, `architecture.md` 옛 `RobloxTween|true|nil`,
  attribute-plan `H10-8` 미반영(retractor/process 의사코드), onchange-plan `H10-12`
  "잔여" 표현, tag-plan 배치 포인터.
- R4 G(M2~M4 정본 vs 코드) 1건 + H(원장 체인·session) 2건 — `Handler.luau` 2-인자
  retractor, attribute-plan process 쪽 reemit, README round19 색인.
- R5 I(README 전수) 4건 + J(research/reference/archive 전수) 5건 — README 행
  넷(dispatch-core `H-277`/typing-limits 8.5~8.9/lifecycle `H-291`/`review-required`),
  `pre-implementation-audit` 헤더 태그·2-6·2-8·Destroying 모순·"다음 액션" 배너,
  framework-comparison "구현 0줄" 배너.
- R6 K(conventions·agents·audit) 1건 + L(루트·패키지 문서) 6건 — HUMAN_TODO 0번,
  STATUS 개수 표, ROADMAP `05` 포인터, luau-test README 타입체커 행, todos 한도
  리터럴, `.gitignore` 주석, project-setup-plan 52행.
- **종결 판단**: 6라운드까지 새 발견이 0으로 수렴하지 않았지만(3/5/3/9/7) 성격이
  전부 "오래된 부채의 미갱신"이고 각도(A~L)가 소진됐다 — conventions의 "유한
  절차" 규약대로 닫는다. 남긴 것: R6-L 7번(`project-setup-plan.md` 447행
  `roblox_sync_config_generator` WARN의 간접 해소 여부 — 사용자 판단), R3-E 4번
  (스파이크 `11` 조기 폐기 여부 — `16`/`21`과 묶어 사용자 판단).

## 6. M11 단위 ① — Tween 값 런타임·타입 (round19 `H-323`~`H-327`)

`Tween.luau`(팩토리·검증·frozen·`Mapped`·센티널) + `Brand.isTween` + quad-types +
`spec.tween`(5절) + `spec.tweentypes`(strict 양성) + `luau-test/33`. 실측으로
결정된 것 다섯은 원장이 소스. 트레이싱 중 오판 하나 기록: "타입별 별칭 `PVn`이
too complex를 풀었다"고 한 번 판정했으나 그 편집이 assert 실패로 적용되지
않았고 실제로는 `State<Tween<T>>` 멤버를 뺀 상태가 통과한 것이었다 — 재적용
뒤 별칭이 실제로 푸는 것을 다시 확인(1.8s, 음성 7/7). Q3 (a)의 정밀판 별칭은
`State<X>` 불변성으로 포기(`H-326`) — §4 확인 항목.

## 7. fable 탐사 (사용자 요청 — "지금까지 해온 작업이 문제 없었는지")

신선한 맥락 fable 1개, 서브에이전트 0(sonnet/opus 한정 지시는 프롬프트로만 —
하네스가 강제하지 않는다). 결과: **치명 0 / 중대 2 / 경미 2**, 코어 의미론은
퍼즈 3종(seed 8개, 3~4천 op)에서 모델과 전부 일치. 보고서
`audit/fable-exploration-2026-09-06.md`, 재현 스크립트는 같은 이름 폴더. 자율
갈래 셋(`H-330` blame·`H-331` Tag holders·`H-332` Observer 재진입)은 그 자리에서
반영·spec 추가, `H-329`(체인 리스트 잔존 — 해제 시점 메커니즘)는 §4 문항으로
— M11 영역과 겹치지 않아 착수를 막지 않는다(사용자 규칙 3).

## 8. M11 단위 ② — Property 핸들러 소비 (round19 `H-328`·`H-333`)

`Property.luau` `process`에 3-상태 슬롯 분기(정본 1~3 그대로), override 주체는
들어오는 값(`H-328`), mock `TweenService`/`TweenInfo` 심 + `spec.tweenproperty` 6절.
Studio는 재시작돼 플러그인이 재연결되지 않아(콘솔 "Couldn't connect" → WS 400)
런타임 모듈 다섯을 `.Source` 직접 패치로 올려 실측 — 첫 실행이 `TweenInfo.new`의
명시적 nil 거부(`H-333`)를 잡았고 기본값을 명시해 채운 뒤 **6/6 PASS**
(`audit/m11-unit2-studio-2026-09-06.md`). Studio Connect는 HUMAN_TODO 12에 추가.

## 9. M11 단위 ③ — `Animate` (round19 `H-334`)

정본 의사코드 그대로 `quad-roblox/src/Animate.luau`, `RobloxExtension`에 합류.
타입은 네 변형을 실측(정직한 `State<T | Tween<T>>` 슬롯 멤버 → too complex /
제네릭 factory → `:Apply` 인자 불일치 / `Animate`를 `<T>`로 → 호출 자리 T 불명 /
`self: State<any>` → 불변성 거부)한 끝에 `(self: any) -> State<Tween<any>>`로 —
교차-T 음성 하나만 잃는다(§4 확인 항목). spec 두 곳의 실패는 lazy Compute
전제 오류(옵션 State 변경 전 한 번 `Get`, 검증 error는 `Get`에서). Studio는
생략(엔진 대면 델타 없음). 단위 ② 감사 1라운드(확실 3·의심 2)도 같이 반영 —
tween-plan 본문 문장·dispatch-core `None` 캐비엇 M11 줄·머리말 3층·override 절
포인터·핸들러 체크리스트 0번(`errorBefore` 규칙, 세 번 반복된 실수).

## 10. M10 잔여 InstanceShorthand (round20 `H-335`~`H-337`)

문항지 `m10-shorthand-implementation-round20-brief.md`(Q1~Q6 권고 (a)로 착수) →
단위 ① 핸들러(룩업 표 하나, `D.New` 경로 자식, Relate 조회, `retractFrom` 뒤 파괴,
`:Mapped`, `NORMAL + 1`) + `spec.shorthand` 6절(첫 실행 통과) → 단위 ② 생성기
(GuiObject 계열 10클래스 Param·Modifier에 키 넷, `H-336`) — "too complex"는 이번엔
`LuauSolverConstraintLimit`이 푼다(`H-337`; Tarjan·TypeInfer 무효) → Studio 6/6
(`audit/m10-shorthand-studio-2026-09-06.md`). §4 열린 문항 0. **M10 잔여 없음.**

## 11. M9 — 컴포넌트 합성 관례 검증 (round21 `H-340`/`H-341`)

정본 "최종 결론" 관례를 `spec.component`(플레인 함수 `MaterialButton(props)` —
`props.Modifier or None`/`props.Ref or None`/자식 전달·`Overridden`·Slot 반환 `ItemList`·
커스텀 클래스 `As("TextButton")` 상향)와 `spec.componenttypes`(strict)로 정식화 —
새 배선 없음. 발견: 검사형 `As<Parent>`는 정본대로 하강 전용(상향 거부 정상)이지만,
**커스텀 필드를 벗겨 부모 클래스로 넘길 연산이 없다**(`:Field(None)`은 키 제거가
아니라 `None` 디스패치 → `no handler matched key Elevation`) — `H-340` 사용자 문항
(권고 `Without`). 경계 필드 이름은 brief Q2 문항(가칭 유지 권고). Slot 물리 순서는
백로그 항목 재확인(`H-341`). **열린 마일스톤 없음.**

## 12. 아침 회신 (2026-09-06)

`H-329` (a) 확정·구현(`retractRange` release, spec.dispatch 15절). Q2·`H-340`은
사용자 숙고로 보류 — *"커스텀 modifier는 peek로 하나하나 확인하는게 일반적 … 그걸
돕는 슈거"*, *"함수 인자는 유저가 마음대로 둘 수 있는 부분 … flatten을 돕는 도구"*;
에이전트도 `Without` 권고를 철회(flatten 슈거가 그 자리를 더 일반적으로 덮음).
`H-324`는 순수 함수 vs 콜러블 테이블 설명 뒤, **사용자가 `Override`를 문자열
싱글톤으로 결정(`H-343`)** — *"언어 기능이 권유하는 바를 우리가 너무 무시하고
있었을지도"*, Fusion의 `"lazy" | "eager"` 관례와 같다. 그 결과 `Tween`이 순수
제네릭 함수가 되어 `H-323`/`H-324`가 함께 소멸. rojo WARN 간접 해소·스파이크 `11`
폐기·Studio 플러그인 재연결(재싱크 8/8 확인).


## 13. 핸드오버 — 감사 A·B, 전체 코드 리뷰, 중단과 재실행 (2026-09-06 밤 ~ 09-07 새벽)

사용자 요청: *"flatten 슈거 … 백로깅 대상 … 이 세션 중 지식이 누락된게 있는지 보고,
세션 로그와 전반 구조를 audit 하고 코드리뷰 해줘, 전체 코드 리뷰를 해도 좋아. 사실상
마일스톤이 전부 끝난 상태라, 여럿 코드리뷰를 돌려보기 좋은 상황이야"*, 이어 *"qwreey/quad
에 만들 PR 타이틀과 내용을 써줘, pr 만드는건 내가 수행할게"* + compact 인자 요청.

- **감사 A·B**(sonnet, 세션 지식 누락·전반 구조) 반영 → `ba222e9`(ROADMAP 완료 배너,
  todos 00번 재구성, architecture 트리 등).
- **전체 코드 리뷰 여섯 동시**(사용자가 "여럿 돌려보기 좋은 상황"이라 허용): R1 코어·디스패치 /
  R2 값 모듈 / R3 quad-roblox·생성기·타입(opus 읽기 전용, 마지막 메시지 하나에 최종 목록) +
  `/code-review high`(포크 + 앵글 5). PR 제목·본문은 `scratchpad/pr.md`에 써서 채팅으로 전달.
- **중단 사고**: 사용자가 `/compact` 인자를 지우다 리뷰 9개가 전부 멈췄다(*"compact 인자가
  잘못 붙여져서 인자를 지우다가 에이전트들이 멈춰버렸는데, 다시 굴릴 수 있을까"*). 이어받기는
  안 되므로 같은 지시로 넷을 재실행했고, 사용자 제안(*"이전 것들은 스크립트 보고 뭔가 나온게
  있는지 … 서브에이전트로 확인하게 해볼래?"*)대로 sonnet이 중단 트랜스크립트 9개에서 발견
  후보를 추출했다 — 결론 텍스트 직전에 끊긴 실측 셋(Effect 비함수 cleanup / Splice 물리
  순서 / 활성 Tween에 `None`)은 전부 **정본·spec이 이미 의도로 규정한 것**이었고, 완주한
  품질 앵글 5개(Efficiency/Simplification/Reuse/Conventions/Altitude)의 목록은 `H-356`
  묶음으로 사용자 문항에 올렸다.
- **재실행 결과**: R3 5건 → R2 3건 → R1 4건(핵심 불변식 정본 일치, 전부 LOW). 메인이 직접
  실측으로 가른 것: `H-353`(유니언 PV가 State를 거부 — luau-lsp 재현 후 생성기 정정),
  Attribute "누수"(순수 Luau 약참조 키 테이블도 동일 32 B/cycle, 주기 GC면 0 — 기각),
  `H-354`(strict Slot 생성 관용구는 캐스트뿐). 원장 `qa-request/handover-review-2026-09-07.md`
  `H-344`~`H-356`, CLI 49/49.
- 교훈(규약 후보는 아님 — 한 번 관측): 백그라운드 리뷰가 많이 떠 있을 때 `/compact`는 위험하다.
  결과가 필요한 리뷰는 끝난 뒤 compact하거나, 최소한 트랜스크립트가 남는다는 걸 알고 추출로
  복구한다(이번에 실제로 복구됐다 — 중단분에서 `H-344`/`H-352`/`H-356`이 나왔다).
- **`/code-review high` 재실행분**(원장 §5): 10건 중 여섯은 첫 커밋(`27edd58`)이 이미 닫은 것을
  리뷰어가 스스로 제외한 뒤의 목록. 반영 ① 넷 — `H-357`(Effect `fn` 안 자기 leaf 철거 = 기존 UB의
  두 번째 트리거, 배너 확장) / `H-358`(`Slot.Init`이 `RunInit(InitDispatch)` 없이 순서에 기대던
  유일한 Init) / `H-359`(gen-d Enum 게이트가 부분문자열 — 정확 형으로, 재생성 diff 0) /
  `H-360`(무효화 표의 교체 행 — 코드·slot-plan·Bookkeeping 주석 셋 대 표 하나). 문항 둘 추가
  — Q4 실프로퍼티 키의 핸들 오용이 FALLBACK 가드 대신 엔진 에러(`H-361`), Q5 같은 키 간접
  재디스패치의 UB 명시. Property retractor `Void`의 트윈 미취소는 tween-plan 확정으로 기각.
  두 번째 커밋으로 마감 — CLI 49/49, doc-check ERROR 0. **핸드오버 완료, PR은 사용자 몫.**
- **야간 순회 지시**(사용자, 00:46 KST): *"KST 기준 2시 30분에 다시 코드리뷰 해줄래? 주간한도 널널하고
  월요일 4시 초기화라, 세번 정도 순회는 가능할것 같아. 적절히 처리할것 모이면 내가 나중에 처리할테니,
  그건 qa쪽에 봐야할 것으로 쌓아두고"* → 02:30 KST 기상 Monitor 예약(세션 한도 초기화 시점), ① 갈래는
  자율 반영·커밋, ② 갈래는 원장 §4에 순회 표시로 누적. 이어 *"지금은 딱 하나 더 코드리뷰를 굴려도
  될것 같아"* → **0순회**(`/code-review high`, 반영분 diff 중심): 10건 전부 ① — 그중 `H-362`/`H-363`은
  새벽의 `H-353` 생성기 변경이 만든 회귀(변환 람다 문맥 타이핑·`TweenData` 전체 유니언 팔 소실)라
  "수정분이 새 결함을 만든다"의 실례. 원장 §6, 세 번째 커밋.
- **1순회**(02:30 KST 타이머 기상, `/code-review high` 오늘 커밋 셋 diff 중심): 8건 전부 ① — HIGH `H-368`
  Attribute plain 가드가 브랜드(메타테이블 아님)를 못 봐 `AttributeKey`·함수 값이 펼쳐짐(브랜드 둘 제외 +
  함수 값 거부 — 리뷰어의 "교차 패키지 술어" ②는 함수 검사가 OnChange 디스크립터까지 잡아 불필요),
  MEDIUM `H-369` gen-d 게이트 정규식 `re.M` 누락(`State`의 `Compute`/`Observer`/`Gate`/`Apply` 미수확 — 잠복),
  `H-370` LifetimeHandle 스텁 깊이를 슬롯별로(`canBound`/`canExecute`는 nearest), 정본 동형화 셋
  (`H-371`/`H-372`/spec 헤더)·인덱스 둘. 원장 §7, 네 번째 커밋. 새 문항 0.
- **2순회**(opus general-purpose 전체 트리, 축 A~D): 4건 — ① `H-373` 조합 불가 엔진 op 셋(`isInst`/
  `nativeClaim`/`nativeFindChild`)의 미설치 스텁 부재(맨 `Quad.New()`에서 nil-call이 quad 내부를 blame),
  `H-374` mock 프로바이더가 `nativeClaim`/`nativeFindChild`를 안 심어 자기 인용 계약(`H-305` (d′)) 위반,
  `H-375` `wrapElement` 게이트 깊이를 호출부별로(콜백 안 직접 CRUD가 `:Set` 줄을 blame하던 것); ②
  `H-376` native* 조합 폴백 약속이 코드에 없음 → §4 **Q6**(권고 (a) 약속 철회). GC 축은 실재현으로 섬
  계약 성립 확인. 원장 §8, 다섯 번째 커밋.
- **3순회**(`/code-review high` 전체 트리, 마지막): 마지막 메시지가 중간 상태(검증자 1 잔여)여서 같은
  에이전트를 재개해 최종 목록을 받음(새 리뷰 아님 — 규약). 8건: ① HIGH `H-377` Modifier `isPlainFieldTable`의
  브랜드 구멍(`Modifier(AttributeKey)`가 `Name` 필드로 병합돼 조용히 rename — 술어를 `Brand.isPlainBranded`로
  공유), MED `H-378` 스텁 nearest 회귀(자기 태그 스텁이라 nearest = quad 내부 — `errorBefore` 복원), MED `H-380`
  Tag 이름 리스트가 `ipairs` 전용이라 Tag/Source/해시가 빈 목록으로 통과(`{string}` 배열 검증), LOW `H-381`
  gen-d 수확을 depth-0 스캐너로(파라미터 이름 오탐 제거), 정정 셋; ② `H-379` `Animate` nil/None 팔 없음(Q8)·
  Q7 스텁 무태그 여부. 원장 §9, 여섯 번째 커밋. **야간 순회 종료** — 매 순회가 직전 수정분의 회귀를 잡았다.

