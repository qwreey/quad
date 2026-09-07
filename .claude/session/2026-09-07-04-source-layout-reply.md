# 2026-09-07 세션 04 — 소스 구조 재편 회신 반영(Tag 유니언·Brand→quad-types·Tween→quad-roblox·마커 전면화·패밀리 폴더)

**앞 세션**: `session/2026-09-07-03-*.md`(회신 3·4차, Q24, 체크포인트 `e9c7ffd`). 이 세션은 compact 뒤
루트 `layout-usernote-ignoreme.md`(구조 재편 여덟에 대한 사용자 회신, 커밋 제외)를 읽고
`research/source-layout-plan.md` 9절 순서대로 반영했다. 결정 원문과 상태는 그 문서 각 절 머리의
`[결정]` 줄과 10절이 소스 — 여기선 경위와 시행착오만.

## 1. 회신 요지(사용자 원문은 source-layout-plan 각 절)

1절 Slot 분할 "권고대로", 2절 Tween은 권고 (c) 대신 **통째 이동**(*"전부 엔진 어휘가 되어야한다"*),
3절 Tag 유니언 "권고대로"(+ 마커로 비용 절감), 4절 패밀리 접기만·대분류 안 함(5·6·7절 포함), 8절 `Attr`
축약은 **미답**. 추가 넷: Brand 팩토리를 quad-types로(quad-spring의 `SpringBrand` 선재), None/Tag/
Attribute/Observer/EffectHandle 마커화, quad-types 단일 파일 재배치(마커 위/구현 가운데/Quad 아래),
`...Param`을 타입 함수로 조립·정적 굽기(→ 리서치, 10-4).

## 2. 순서와 커밋

1. `02adb01` Tag 유니언 — `TagNames = string | { read [number]: TagNames } | TagMarker`. 스파이크: 가변 `{T}`
   인덱서는 불변이라 `{ tag, "x" }` 리터럴을 거부, `read` 인덱서가 답. 해시 테이블은 타입이 못 잡는다
   (인덱서 없는 테이블이 인덱서 타입을 통과) — 런타임 `flattenInto`가 그대로 잡는다.
2. `2c9ad89` Brand→quad-types + Tween→quad-roblox. 시행착오 하나: 생성 D의 `FieldOut<T>`를
   `QuadTypes.FieldOut<T | Tween<T>>`로 바꾸자 `export type D`가 "too complex" — 제약 한도 플래그를 올리면
   통과하므로 제약 수 문제. 정밀 엔진 타입·quad-types 정의 위치·인라인 유니언을 각각 되돌려도 실패, HEAD로
   되돌리면 통과 → 파일별 누적 적용으로 D의 그 한 줄이 원인임을 확정. `types.luau`가 별칭을 만들고 D는
   재별칭만 하면 통과(`typing-limits.md` 8.12). 플래그는 되살리지 않았다.
   또 하나: 이동한 `spec.tween` 6절이 `mock.newQuad()`(quad-base/src)의 Source를 `Quad`(relink 사본)의
   `Tween`에 넣어 `isState` 실패 — 두 사본은 브랜드 집합이 다르다(하네스 산물). 같은 사본의 `Quad.Source`로.
3. `82a13eb` 마커 전면화 + quad-types 재배치(줄 다중집합 diff 0 + 절 머리 9줄).
4. 패밀리 폴더 — `Ref/`·`Attribute/`·`Dispatch/Modifier/`는 메인이 직접(비-init 파일의 `./` → `../`,
   `Dispatch/Modifier/init.luau`는 `./`가 `Dispatch/`라 `./None`), Slot 여섯 분할은 opus 서브에이전트에
   위임(내부 표 `S`로 늦은 조회 — 전방 선언의 파일 판). `doc-check.py`가 `.luau` 경로를 검사하도록 확장
   (소스 색인 접미 일치, 패키지 루트부터 적은 경로는 ERROR·이름만은 WARN, `initreq` 외부 소스는 이름 폴백).
   기존 `.luau` 인용 143줄을 새 경로로 치환(Slot은 줄 문맥으로 하위 파일 판정).

## 2-1. 이동 뒤 순회(9절 5번)

감사자 1라운드(diff 범위, sonnet): **16건, 전부 같은 원인** — 옛 경로 인용을 기계 치환하면서 "옛 `Ref.luau`"처럼
옛 이름을 서술하는 자리(내가 방금 쓴 `architecture.md` 트리 항목 머리 포함)까지 새 이름으로 덮어 자기모순·동어반복
(`source-layout-plan.md` 5절 "`Slot/Handler.luau` → `Slot/Handler.luau`")을 만들었고, 2절 헤더가 기각된 권고를
제목으로 달고 있었으며, round1 Q3 ⑤의 중의적 `Ref.luau`가 틀린 쪽(`Ref/init.luau`)으로 확정됐다(실제는
`Dispatch/Ref.luau`). 전부 원문대로 되돌림. 재발 방지: `doc-check.py`가 인용 앞 40자에 `옛`이 있으면 건너뛰고,
`conventions.md` 표기 규약에 "옛 이름은 `옛 \`X.luau\``, 치환은 그 앞을 제외" 신설. 2라운드는 각도 교대
(코드 헤더↔정본·인덱스 레이어·배너 아래 본문·luau-test/audit): **2건** — `source-layout-plan.md` §5~§7이 자기 규약
("결정은 절 머리 `[결정]` 줄")을 안 지켜 §9와 갈렸고 §2에 결정 전 분석이 현재형으로 남음(배너·마커 추가), 외부 감사
진입점이 패키지 다섯을 내용까지 나열해 세 번째 사본을 만듦(`architecture.md` 포인터로 축약). 사소: 하드코딩 `G-14/S-10`
제거, `옛` 예외 창 40→120자. 3라운드는 수정분 + 코드 헤더의 옛 경로 grep. `/code-review`(파인더 8·검증자 4 opus, 미완 1)는
**10건** → round3 §9 `H-453`~`H-462`(① 여덟: doc-check 폴백 구멍·성능, 코드 헤더 옛 경로 열 곳, tween-plan 본문,
`S` 과잉 공개 열넷, `Merged` 중복·Tree 전방 선언, 정밀 엔진 타입 음성 스파이크 36, `Peek` 캐비엇) + **Q28**(Tag
자기 참조 리스트 — 스택 오버플로·내부 blame)·**Q29**(`S` 타입). 리뷰가 잡은 tween-plan 본문 stale은 doc-check
폴백 구멍이 통과시켰던 것 — 도구 결함 하나가 감사 두 라운드를 통과시켰다.
감사자 3라운드: 코드 주석의 옛 경로 11건(7건은 리뷰 반영 때 이미 고침)·의심 2 → 잔여 grep 0으로 닫음. **감사 루프는
3라운드(16→2→4)에서 각도 소진으로 종료** — 4라운드 대신 src/test 전체 grep으로 옛 경로 0 확인.

## 2-2. Q28·Q29 회신(대화형)

Q28 (a) UB. Q29는 내 권고 (a)가 아니라 사용자의 원래 생각 — `S`를 풀어내지 않고 `S.x`를 그대로 쓰되 타입을 `Slot/`
안 `types.luau`에 두는 것(내부 구현 타입은 quad-base, 외부 계약만 quad-types). 같이 받은 질문 "S.bindLifetime은 왜?
다른 곳에도 그런 패턴이 있나?" — 조사 결과 그 래퍼 셋은 M6 fork가 남긴 것이고 코퍼스에 그것뿐, 다른 모듈은 인라인
`module.x(...)`(스무 곳). 래퍼 제거·인라인, `SlotInternal` 타입, 재캡처 제거(`function S.Slot_mt.List` 포함),
`architecture.md` 코드 스타일 절 신설. test.sh exit 0.

## 3. 사용자 추가 요청(세션 중)

외부 모델(Gemini 등) 감사용 클린 컨텍스트 진입점 — `qa-request/external-review-entry.md` 신설
(읽는 순서·중복 제외 규칙·각도·결과 파일 형식·금지·붙여 넣을 요청문). 사용자: *"gemini 는 완전 다른 시각을
가지고 있어 … 값이 싼 편이라 돌려보기 좋아 … 좀더 정형화된 감사를 위한, 클린 컨텍스트에서 읽을 진입점"*.

## 4. 남은 사용자 몫

8절 `Attr` 축약, 10-4 D 정적 굽기(§0 타입 함수 예외 여부), round3 §4 Q27(프로바이더 브랜드 프로브 등록),
Q25·Q26, 사후 확인(마커 필드·별칭 이름, Property 슬롯 `Source`). `question.md` 2절이 소스.

## 5. 탐사 순회 — opus 탐사자 둘 + Gemini 5차 판정 (같은 밤 후속)

사용자: *"제미니 도는 동안 너도 탐사자 하나 띄워서 … opus 정도 2개 정도 띄우는거로 충분 … 작은 모델로 여러패스를
굴려 자잘한 버그를 실측하는게 맞아보이는데 … 다만 그게 진짜인지 실측은 메인인 너가"*. 동의하고 A(quad-base 코어)·B
(quad-roblox·타입·생성기)를 각각 단일 맥락·읽기 전용으로 띄웠다(원장 grep으로 기추적 제외, 마지막 메시지 하나, 평문).
B 9건·A 5건, 같은 시간에 도착한 Gemini 5차 7건(`G-15`~`G-21`)을 전부 스크래치 프로브(`probe.tmp.luau` — 돌리고 지움)로
실측했다. 결과는 round3 §10: ① 열(`H-463`~`H-472`), ② 넷(Q33~Q36), ③ 오탐·확인 여섯.

**교훈 둘.** (1) Gemini 다섯 건이 같은 틀린 전제("nil 키 읽기가 VM 에러")를 공유했다 — 외부 리뷰의 언어 사실 주장은
실측 전엔 믿지 말 것(진입점 §6에 규칙 추가). 사용자 회신 Q32는 그 틀린 전제 위에서 나왔지만 결정 자체("조용히
성공하는 nil 케이스 방지")는 실제 동작(조용한 nil/false 반환)에 더 정확히 맞아 그대로 반영했다. (2) 탐사자 발견도
셋 중 하나는 스펙 grep으로 뒤집혔다(B-9 — `spec.events`에 이미 있음). 탐사자 코스트: A 36만·B 27만 토큰(opus).
Gemini가 `README.md` 색인 행까지 직접 고쳐 놓았다(round5 항목) — 원문 유지하고 판정 포인터만 덧붙임.

`/code-review`는 이번 흐름에 돌리지 않았다 — diff가 게이트·메시지·스펙 위주 열 건이고 사용자가 이 순회의 규모를
"opus 둘"로 못 박았기 때문(감사자 1패스는 돌림).

**후행.** Gemini가 종료 보고와 함께 round5 §6(후행 배치 — `G-22` Ref 콜백 타입 가드, `S-16` = 내 전제 정정과 같은 결론, Q31
심층: `unbindLifetime(nil)`도 에러)을 덧붙였고 — 그때 파일을 통째로 다시 써서 내 판정 배너가 지워졌다(다시 넣음) —
감사자 1패스(sonnet)가 Q31 미반영·`G-22` 미배정·slot-plan 정본 코드 블록 잔존·dispatch-core "경로가 없다" 문장 충돌을
잡았다 → `H-473`·`H-474` + 문서 정정. 감사자 발견 넷 중 둘이 "원문에 나중에 붙은 절을 못 봤다"는 것 — 외부 리뷰 파일은
종료 보고를 받은 뒤 다시 읽을 것. test.sh exit 0(스펙 49).

## 6. 회신 5차 — Q33~Q36 (2026-09-08 새벽, 대화형)

사용자가 round5 Q30~Q32가 본인 회신임을 확인. Q33은 내 권고(Reflection으로 nillable 판별)보다 단순한 답 — *"nil로 셋
되는건 정상적 경로 … 안 받으면 엔진이 에러를 내줘"* → skip-defense 자체를 제거(M10 캐비엇·`H-352` 역전). Q34 (a)
생성기 `TWEENABLE`·`FieldP<T>`(D 31 클래스 재생성, `FieldOutP = QuadTypes.FieldOut<T>` 재별칭은 8.12 한도 무해 —
타입 검사 통과). Q35 (a) `Parent` 읽기 표면. Q36은 열지 않음(사용자 재량 — `userdata` 계약). 시행착오: spec에서 mock
트윈 로그 모양(`log[i].tween.cancels`)을 잘못 읽어 한 번 실패. test.sh exit 0(스펙 49), doc-check ERROR 0.
