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

## 3. 사용자 추가 요청(세션 중)

외부 모델(Gemini 등) 감사용 클린 컨텍스트 진입점 — `qa-request/external-review-entry.md` 신설
(읽는 순서·중복 제외 규칙·각도·결과 파일 형식·금지·붙여 넣을 요청문). 사용자: *"gemini 는 완전 다른 시각을
가지고 있어 … 값이 싼 편이라 돌려보기 좋아 … 좀더 정형화된 감사를 위한, 클린 컨텍스트에서 읽을 진입점"*.

## 4. 남은 사용자 몫

8절 `Attr` 축약, 10-4 D 정적 굽기(§0 타입 함수 예외 여부), round3 §4 Q27(프로바이더 브랜드 프로브 등록),
Q25·Q26, 사후 확인(마커 필드·별칭 이름, Property 슬롯 `Source`). `question.md` 2절이 소스.
