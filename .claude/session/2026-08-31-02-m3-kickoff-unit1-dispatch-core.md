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

**감사 6라운드(수렴 확인)** — 회신 반영 커밋 `da67a8c`의 diff 전수 점검,
**새 확실 발견 0건**(의심 1건: `H-217` 요약의 "mock 문구에 맞춤" 표현 정밀도
— "공통 접두를 딴 근사"로 정정). 감사 루프는 여기서 수렴.

## `/code-review high` — 10건 (`H-218`~`H-227`)

수렴 직후 리뷰가 10건을 냈다(감사자와 보는 축이 다르다는 관례 그대로).
분류·처리는 round12 요약 표가 소스 — 요지: ① 여섯 반영(`H-220` `BRAND_PROBES`
specific-first / `H-221` ROADMAP stale / `H-223` retractor 생략 error에 핸들러
특정 정보 / `H-224` M4 잔여 몫에 효과 수준 단언 복원 / `H-225` 이 파일의 루프
서술 stale / `H-227` `{} :: any` → 타입 주석 조립), ② 셋 §4 합류(`H-218`
chains 캡처 누수 — 거짓 GC 주장 둘은 사실 정정만 선반영 / `H-219` `drive`
경로의 error 도착지 / `H-222` 제공자 계약 위반의 level 분류), 기각 하나
(`H-226` 꼬리 병합 리팩터 — 확정 의사코드 1:1 유지 우선).

## 단위 1 마감 후 — 회신 연쇄와 단위 2 (같은 세션 계속)

탐사자까지 끝난 뒤 사용자 회신이 연달아 와 §4가 실시간으로 닫히고 새
설계가 둘 태어났다(개별 결정·인용의 소스는 round12 §4와 요약 표 — 여기선
흐름만):

- **회신 2** — `H-218`(a, retractFrom 의무화·`UI-11` 부분 역전)/`H-219`(a)/
  `H-222`(a, error 계약 표 제3 행). 되물음 *"Destroy 호출되는 것도 retract가
  안 먹어서 문제가 생긴다는 부분 아냐?"* → 검증 결과 **맞았다**(`H-229` —
  chains가 두 번째 강한 루트, gchold 섬이 무너져도 안 걷힘).
- **회신 3** — error 유틸 설계(사용자 실험 `error-util-ignoreme.luau`):
  `setFuncLevel` 맵 + `debug.info` 워커. 유의점("중간에 짤림"/최상단 하강)과
  중첩 진입 blame 질문(선택지) → **스캔 둘 다 제공**(`errorAtNearest` 쌍
  이름 사용자 선택), 사본 네임스페이스 분리 지적 → **상태 없는 `new()` +
  `Quad.errorNamespace` 공유**(사용자 구조 제안).
- **회신 4~5** — `H-229`(a, bindLifetime 확장 계약 — *"아무 타입과도 일치하지
  않으면 단순히 GC 릴레이션만"*) / `H-230`(a, 상수 quad-types) / `H-231`
  이관 승인(*"이관 할 부분을 이관하고 다음 단위 착수하자"*) → quad-error
  패키지 신설, M2·단위 1 error 전량 이관, 전 표면 태깅.
- **단위 2 구현** — Length/Offset 부기 전체(`getBookkeeping`/`getBlocker`/
  `getOffsetAt`/`recompute`/`setLength`/`setOffsetSource` + drive ⓪⓪'),
  `spec.lengthoffset` 8절. `bk`도 `H-71` 동형이라 `H-229` 패턴 적용, Slot
  owner 몫은 `H-232`로 분리 → **회신 8**로 (a) `slot._bk` 확정.
- **회신 7(툴체인)** — `H-234`: quad-base·quad-types target `luau` 전환 +
  rojo 트리 `luau_packages` + relink 꼬리 sourcemap(사용자 발견·결정).
- **단위 끝 절차** — 감사 5라운드(4→3+1→3→1(자기회귀)→0 수렴,
  `H-235`~`H-237`; 3라운드 반영이 볼드 태그 80자 초과 회귀를 만들어
  4라운드가 잡음 — §6에 전 코퍼스 태그 스윕 등재), `/code-review high`
  10건(`H-238`~`H-247`): ① 여덟 반영(mock 태깅, spec4 실단언, 태그 테이블
  순회, contribution 단일화, 잔존 주석, 소비자 갭 문서화, 이 세션 원문
  증보, `158c354` 게이트 위반 기록), ② 둘 §4 대기(`H-240` 🔴 Get-창 커서
  스톰프 / `H-241` drive 재진입 Blocker).

## 단위 3 — `None` 센티널 핸들러 쌍 (같은 세션 계속)

단위 2 끝 절차(탐사자 `H-248`~`H-252`까지) 종료·보고 후 곧바로 착수 —
§4 열린 셋(`H-240`/`H-241`/`H-250`)은 단위 3을 막지 않는다고 판단.
`Dispatch/None.luau`에 `NoneHandler`(재귀 전용)/`NilHandler`(0 등록 말단,
`H-39` 첫 적용) 합류, 반환이 `{ None, register }` 테이블로(`H-253` —
핸들러가 인스턴스별 `dispatch`를 클로저로 받아야 해서, `InitDispatch`
꼬리가 `register` 호출). `spec.nonenil` 5절 실측(해시 None→키 핸들러 nil
수신 / 배열 0 등록 / 값↔None 전환 / 매치 경계). "탑레벨 `None.luau`" 별도
파일은 안 만듦 — `slot-plan.md`의 재노출 선례가 소스(브리프 §1의 옛 예고
쪽이 어긋났던 것, 감사 1라운드가 잡아 브리프·ROADMAP 정정).

**단위 3 끝 절차** — 감사 3라운드 수렴(`H-254`, 2라운드가 1차 교정의
vacuous를 잡아 재교정 — `H-255`로 소급 원장), `/code-review high` 10건
(`H-255`~`H-263`): ① 여덟 반영, ② 둘 §4 합류(`H-256` 🔴 희소·비정수 키
부기 오염+영구 동결(재현) / `H-258` nil 값 자리 retractor 신호 충돌).

## 이 다음

탐사자(단위 3 범위) → 사용자에게 "§4를 보라" 한 줄(대기 다섯: `H-240` 🔴/
`H-241`/`H-250`/`H-256` 🔴/`H-258`) → 회신 반영 후 단위 4(Leaf·가드·종합).
