# 2026-08-31 (02) — M3 착수: round12 규약 확정 + 단위 1(디스패치 코어) 구현

## 무엇이 있었나

사용자 지시 *"M3 를 작업 시작하자. m3-implementation-round12 문서를 보면 돼"*로
시작. `m3-implementation-round12-brief.md`가 §0 회신 대기 상태였고, §6(첫 단위
계획)은 "Q1·Q2가 (a)로 닫히면 채워 사용자 확정을 받는다"였다.

## 규약 확정 (대화형 선택지)

§6 초안을 먼저 채운 뒤 §0 세 문항과 §6 승인을 **한 번의 대화형 선택지**로
물었다(밤샘 배치가 아니라 사용자가 자리에 있던 시점). 회신:

- **Q1 (a)** — M2 골격 그대로 + M3 전용 게이트(새 핸들러 전 "Handler 작성
  체크리스트" 필독) 하나 추가.
- **Q2 (a)** — 단위 넷(코어 → 부기 → `None`/`Nil` 핸들러 → Leaf·가드·종합).
- **Q3 (a)** — M2 하자는 규모로 가름(경미 = round12에 ① / 설계 결정 규모 =
  그때 `m2-implementation-round13` 신설).
- **§6 승인** — "승인 — 이대로 착수". 요지: `Dispatch/Handler.luau` 타입 전용
  잎 / `InitDispatch(module)` 팩토리, `chains`는 인스턴스별 `Relate`, 우선순위
  상수도 이 파일 / `drive`는 단위 1에서 (b) 본체 루프만(⓪⓪'는 단위 2, (a)(c)는
  M8) / `spec.dispatch` + `spec.drive`(spec-로컬 테스트 핸들러) / 스파이크 `01`
  재작성은 `spec.drive`가 상시 회귀로 대체.

기록 커밋 `f14ba09`(brief §0 회신 블록 + `round12.md` 스켈레톤 + 인덱스 3층).

## 단위 1 구현 (커밋 `590b0fe`, `a6d0c7f`)

- 타입은 quad-types 소유(`Handler`/`Dispatch` export + `Quad.Dispatch` 필드,
  `H-25`), `Dispatch/Handler.luau`는 재export 잎. **`H-165`를 예고대로 밟았다** —
  pesde shim이 새 export type을 몰라 analyze가 Unknown type, `pesde install`
  재실행으로 해소.
- `Dispatch/init.luau`: "Dispatch 체인" 절 의사코드를 그대로 옮김. 옮기다 나온
  발견 셋은 `round12.md`가 소스 — `H-212`(① base 의사코드 error가 한국어·level
  없음 — error 계약(08-25)이 미반영, 문서·코드 같은 커밋 정정), `H-213`(①
  우선순위 밴드 리터럴 값은 문서 미정 — 1000/0/-1000/-1000000 채움),
  `H-214`(② `listHandlers`·동률 경고가 원하는 핸들러 **이름**이 계약 3종에
  없음 — §4 문항으로, 코드는 핸들러 객체 배열 반환 + `TODO(H-214)` 마커).
- 매치 실패 메시지의 브랜드 출력은 기각된 Brand 역조회를 재도입하지 않고
  모듈 공개 술어(`is*`) 프로브로(실패 경로에서만).
- 신 솔버 타입 이슈 둘: `type(x)=="function"` 내로잉이 콜러블이 아님(캐스트),
  `table.sort` 비교자 파라미터 무주석이 unknown — 둘 다 주석/캐스트로.
- 테스트: `./scripts/test.sh` 전부 PASS, `luau-analyze` 클린, selene 에러 0.
  `spec.drive` 1번이 `F-4-1` 언어 동작(일반화 `for`의 배열→해시 순서)을 실측 —
  스파이크 `01` 폐기·`done/` 이동(STATUS.md·ROADMAP 재검증 대기 절 `[x]`).
- ROADMAP M3 체크박스 중 단위 1 몫 여섯을 `[x]`(drive 범위 절단 주석 포함).

## 단위 끝 절차 — 감사 루프 5라운드 + §4 배치 회신

감사 루프(`quad-doc-auditor` 한 턴 하나, 라운드마다 각도 변경): 1라운드
4건(CLAUDE.md 볼드 중첩 / STATUS.md 요약 표 7·17 / quad-types-plan M3 완료
표시 / luau-test README `01` 행) → 2라운드 2건+판단 1(STATUS.md "합류" 문단
해소 표시·done 나열 갱신 / 스파이크 `04` 처분 → `H-215` §4 등재) → 3라운드
2건(`dispatch-core-plan.md` Length/Offset 절·주입 op 스텁 error 영어화 —
`H-212` 확장 / `H-214` 근거 정정: "이름으로 덤프"는 같은 문서 자기 자신) →
4라운드 회귀 0 + 정보성 1(`slot-plan.md` 한국어 error 11곳 → `H-216` ①로
정리) → 5라운드 2건(`H-216` 계수 12→11 / 잔여 4곳 → `H-217` ①: attribute·
debounce-throttle·ref(`"PreRef instance reused"` 문구 통일)·source-state
(mock 실구현 문구에 맞춤)). **base/ 코드 리터럴의 한국어 error 0.**

**§4 배치 회신(사용자, 감사 5라운드 도중)**: *"배치 문항은 중간확인 완료했어.
전부 권고안에 동의해. 나중에 천천히 반영해줘"* — `H-214`·`H-215` 전부 (a).
반영: Handler 계약에 선택 필드 `name: string?`(진단 전용 — quad-types /
동률 경고에 이름 / `TODO` 마커 제거 / 계약 절 신설 항목 / spec 11번), 스파이크
`04` 폐기·`done/` 이동(잔여 `StoreBind` 경유 재발행 경로는 ROADMAP M4 mock
항목에 명시). 테스트·analyze·doc-check 전부 클린.

## 이 다음

`/code-review high` → 커밋 → fable 탐사자(round12.md에 발견 이어붙임) →
사용자에게 "§4를 보라" 한 줄.
