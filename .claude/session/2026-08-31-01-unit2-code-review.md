# 2026-08-31-01 — 체크포인트 재개: 단위 2 `/code-review high` 완주와 반영

## 맥락

2026-08-29 아침 체크포인트(`session/2026-08-28-03-m2-unit1-common-base.md` 마지막 절)의
재개 지점 둘 중, 사용자가 *"미완인 것 먼저 처리해줘"*로 (2) 단위 2 파일 리뷰를 먼저
지시했다. §4 문항 여섯(`H-182`~`H-187`)의 회신은 이 세션 시작 시점에 아직 없음.

부수 결정 하나 — 사용자: *"이건 pre-implementation 은 아닌듯 하네, 이름은 나중에
바꾸자"*. `pre-implementation-handtrace-round11*.md`는 구현 **중** 발견 문서라 이름이
안 맞는다는 것. **이름 변경은 §4 회신 처리 뒤로 미룸**(문항지·brief와 인용처를 한꺼번에
옮겨야 해서) — 아직 안 했고, 잊지 말 것.

## 포크 조기 반환과 재개

`/code-review high` + 경로 넷(`EpochMap`/`Source`/`State`/`Store`)으로 실행. 체크포인트가
기록한 실패 모드(하위 탐색자 완료 전 포크 조기 반환)가 **이번에도 재현**됐다 — 첫
notification 시점에 파인더 4개가 미완인 채 멈춤. 이번엔 opus 대체가 아니라
**`SendMessage`로 포크를 재개**(나머지 파인더 수거 → dedup → 검증 → `ReportFindings`까지
끝내고 턴을 닫으라고 명시)했고, 그걸로 완주했다. 다음에 같은 패턴이 나오면 이 방법을
먼저 쓸 것 — 재실행보다 싸고(이미 돈 파인더 결과를 버리지 않음) 잘 듣는다.

## 결과 — 8각도, 후보 22 → 검증 생존 10

정확성 8건 전부 실제 코드에 재현 스크립트로 확인. 효율 배치는 리뷰 스스로 "관측된
병목에만 구조" 원칙 위반으로 기각, 약한 정리 항목들은 심각도 미달 기각. 발견 상세와
처리의 소스는 `qa-request/pre-implementation-handtrace-round11.md`(요약 표
`H-198`~`H-207`, 상세 절 "단위 2 — `/code-review high`") — 여기선 갈래만:

- **① 여섯**(같은 커밋에서 반영): `H-199`(nil dep 조용한 탈락 — `collectDeps` + error),
  `H-201`(`Of` 이름 문자열 검증), `H-202`(`Compute` fn 검증), `H-204`(`defaults` 평범한
  테이블 검증), `H-206`(`implsOf` 세 벌 → `ImplRegistry.luau` 신설), `H-207`(`Source.Set`이
  `Emit` 꼬리 위임). 검증 셋은 `H-190`·단위 3 `fn` 검사와 같은 급(형제 검증과 동급),
  중복 제거 둘은 conventions 설계 원칙의 공유 허용 범위(데이터/순수 접근, 같은 타입).
- **② 넷**(§4 문항 + `TODO` 마커): `H-198` 🔴(닫힌 게이트 너머 `fn` 도중 `Set` → 영구
  stale 캐시 — **`state-epoch-plan.md` §4 확정 의사코드 자체의 구멍**, `H-85`와 같은 실패
  계열의 게이트 경유 변형), `H-200`(`Gate` setup throw 좀비 노드 — 예외 계약 UB냐
  `H-188` 연장이냐), `H-203`(`Blocker:Off` 순회 중 재차단 무시 — 탐사자는 §5에서 미지원
  연장으로 봤고 리뷰는 `IsOn` 불변식 위반으로 봄), `H-205`(Modifier 가드 level — lazy
  체인이라 어떤 고정 level도 항상은 유저 코드에 못 닿음).

리뷰가 확인한 "이상 없음" 목록과 기각 중 기록할 것 하나(Effect `Ref` dep의 생성 중
`onRefFire` 즉시 발화 — 신선한 Effect는 `canExecute` 거짓이라 실패 불가)는 round11.md의
"단위 2 리뷰가 이상 없다고 확인한 것" 절로.

## 이 시점 상태

`./scripts/test.sh` 전부 통과(`spec.state` 13절·`spec.store` 2·3절에 새 가드 테스트 추가),
`luau-analyze` 진단 0, 코드 마커 `TODO(H-)` 열 개 = §4 문항 열 개와 1:1. **재개 지점은
§4 배치 회신 하나로 줄었다**(여섯 + 이번 넷). M2 종료 보고는 그 회신 처리 뒤.

## 같은 날 후속 — §4 배치 회신 1차 처리 (2026-08-31)

사용자가 §4 열 문항(+ 앞 라운드 셋 재확인)을 자유서술로 회신. 갈래: **확정 일곱**
(`H-182` (a)+`_dying` 네이밍 / `H-183` (a) Observer `_running` / `H-184` (a)
`_assertBindable` 커밋 전 문의 / `H-185` 권고 기각 — 단일 cleanup 문서화 /
`H-187` (a) / `H-200` (b) detach-중-setup / `H-203` (a) 순회 중 `IsBlocked` 재확인),
**재질문 둘**(`H-186` — "새 메커니즘 불가피하지 않나?", `H-198` — 재시작 루프 대안),
**보류 하나**(`H-205`). 인용 원문과 반영 위치는 `round11.md` §4의 "[2026-08-31 회신 2]"
블록이 소스.

구현 요지: `Effect._dying`(Destroying 콜백이 세움, 재바인드·`Subscribe`류가 내림 —
죽은 바인딩 재사용 계약과의 충돌 때문에 재무장 자리가 셋), Observer `_running`
(모든 fn 실행 둘레 + 네 진입점 첫 줄, error 시 잔류는 설계상 인정), 공통 훅
`_assertBindable`(mock bindLifetime이 커밋 전 문의 — `H-147` 가드는 `_bindDestroying`
첫 줄에서 이 훅으로 이동, level 3), Gate 생성이 setup 동안 `_subs`에서 떼었다 성공 후
재등록, `Blocker.runHandles`가 핸들마다 `IsBlocked` 재확인. 문서는 `effect-plan`/
`lifecycle-pattern`/`source-state-plan`/`gate-plan`/`blocker-plan`/`ref-plan`(+
`documentation-content-map` `H-170` 항목, `quad-types-plan` `H-187`)에 반영. 스펙 넷 추가
(`spec.effect` 10 / `spec.observer` 9 / `spec.gate` 1 확장 / `spec.blocker` 8).
코드 마커는 셋 남음(`H-186`/`H-198`/`H-205`).

`H-186` 답변(메인): 비교 자체는 메타테이블 신원(임플 테이블 = `module._impl` 경유)으로
새 per-노드 등록 없이 가능하나 어쨌든 형제 임플 노출이 필요하고, §6 이웃(교차
`bindLifetime`)은 그걸로도 못 막음 — (b) UB 문서화를 권고로 되돌림. `H-198` 답변(메인):
재시작 루프는 성립하되 게이트 너머 움직임의 탐지는 결국 fn 직전 스냅샷 비교로 귀결 —
사용자 안 = 스냅샷 탐지 + `Get` 재시작 루프, 캐비엇은 자기-dep `Set`의 무한 재시작
(UB로 접을지 함께 결정 필요).

## 같은 날 후속 2 — §4 전량 종결 (2026-08-31, 회신 3)

사용자가 잔여 셋과 코드 검토 둘을 회신: `H-186` (b) UB 문서화("확인. UB로 놓는게
맞아보여" — `architecture.md` 13번 + content-map §4, 추후 생각해볼 점) / `H-198`
사용자 안 확정("이미 있는 표면들로 충분히 구현 가능해서 동의함") — 상류 스탬프를
`fn` 직전으로 + `Get` 재시작 루프, 무한 케이스 UB(구현이 루프라 관측은 스택오버플로우가
아니라 무한 재계산 — round11 §4 회신 3 블록에 각주) / `H-205` (a) level 3 /
`H-174`는 기결정 (a) 재확인 / **`H-208`** `Ref:Set` 스냅샷을 `table.clone`+집합
병합으로("더 싸") / **`H-209`** 전반 `pairs`/`ipairs` → generalized iteration
("최적화로 인해 더 빠르거든") — 메타테이블 있는 테이블(weak/`__index`)의 raw 순회를
스크래치로 실측 확인 후 src 전 파일 전환, 문서 의사코드 표기는 `H-178`과 같은 급으로
무변경. `H-198` 반영으로 **계약이 강화**됐다: `Get`은 이제 fn 도중 온 변경(재진입이든
게이트 유보든)을 같은 호출 안에서 수렴시켜 항상 최신을 돌려준다 — `spec.state` 6이
옛 계약("다음 Get이 재계산")을 단언하고 있어 새 계약으로 갱신, `spec.gate` 10에 리뷰
재현 시나리오(영구 stale이던 그것)가 "같은 Get에서 99 + flush는 통지만"으로 고정.
`spec.state` 12는 level 3 프레임 단언 추가. **§4 열린 문항 0, 코드 마커 0** — 남은
마무리는 파일명 변경(사용자와 이름 결정)과 M2 종료 보고.

## 같은 날 후속 3 — 툴링 픽스 둘(H-210/H-211)과 감사 반영

- **`H-210`** (사용자 발견): 루트 `default.project.json`에 `roblox_packages`가 없어
  rojo 통합 luau-lsp가 *"Unknown require: game/ReplicatedStorage/roblox_packages/
  quad_types"*. 처음엔 `ReplicatedStorage.roblox_packages` 하나로 붙였다가 **사용자
  정정**(*"quad-base quad-roblox 안에 따로 roblox_packages 가 들어가야"*) — 공유 하나면
  quad-roblox가 의존성을 갖는 순간 충돌. 패키지별 Folder 아래 `src`+`roblox_packages`
  형제 매핑으로(pesde 가이드의 멀티 패키지 판), `rojo sourcemap` + `luau-lsp analyze`로
  unknown-require 0 실측. 커밋 `274da35`, `project-setup-plan.md` 셋째 함정.
- **`H-211`** (사용자 발견): `Relate:SetWeak`의 캐스트 없는
  `bucket.WeakMap = setmetatable(…)` 대입이 IDE(strict)에서 TypeError — 메타테이블
  붙은 타입은 평범한 인덱서의 서브타입이 아님. 플레인 `luau-analyze`(test.sh 게이트)는
  솔버 차로 조용 — **IDE와 CLI가 다른 걸 본다는 사실 자체가 기록 대상**. 처방은 로컬
  주석 + `:: any` 경유(모든 솔버 통과). 전 파일 luau-lsp 스윕에서 이웃 `::` 직접
  캐스트들(Brand/EpochMap/Observer/Relate 생성자)이 신형 솔버 CLI에서만 "unrelated"로
  걸리는 것도 확인 — 사용자 IDE·현행 게이트 모두 무발화라 무변경(관측된 문제만),
  신형 솔버가 게이트가 되는 날 일괄 전환.
- 회신 3 감사 1라운드(확실 1·의심 1) 반영: `state-epoch-plan.md` H-85 절의 옛 계약
  문장("다음 Get이 반드시 재계산")을 H-198 재시작 루프로 정정, `todos.md` 00의 H-번호
  나열을 소스 포인터로 축소(머리말 규칙).
