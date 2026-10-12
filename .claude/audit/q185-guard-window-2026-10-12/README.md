# Q185 — 가드 창 넓히기 (d) 시제품과 재진입 조합 프로브 (2026-10-12)

메인이 스크래치 사본(HEAD `4fee21ba`를 `cp -rL`)에서 실행, 레포 소스 무수정. 판정·결정은 원장
`qa-request/post-implementation-review-round14.md` §6 Q185. 이 폴더는 그 사본에서 옮겨 온 산출물이라 여기서 바로 돌지 않는다 —
다시 돌리려면 HEAD를 `cp -rL`로 떠서 `.claude/audit/<아무 폴더>/`에 `audit/h895-reentry-order-2026-10-07/probes/`의 파일과
이 폴더의 `probe4.luau`·`bench.luau`를 같이 두고 `luau`로 실행(프로브의 require가 그 위치 기준).

- `candD-guard.patch` — (d) 시제품(`quad-base/src/Slot/Tree.luau`·`Raw.luau`·`types.luau`, +48 −3줄). 내용: 하위 트리 물리 삽입 동안 그
  하위 트리의 Slot 전부에 `_materializing`(`raiseTree` walk 하나, `markMountedTree`가 내림); raw 연산의 엔진 호출 창(`rawAdd` 평범한 원소,
  `rawRemove`·`rawUnmount`·`rawDetach`, `rawReplace`의 떠나는/들어오는 호출, `rawSplice`의 묶음 호출)에서 그 Slot에 같은 플래그(저장·복원);
  `destroySlotTree`가 도는 동안 그 Slot에 플래그; `unmountSlotTree`는 논리 절반(`teardownTree`)을 엔진 호출 앞으로(그 시점엔 이미 평범한
  언마운트 상태라 CRUD가 부기만 고친다 — 던지지 않음). `Quad0167` 문구·문서·스펙은 시제품에 없다.
- `probe4.luau` — 10-07 프로브가 안 본 조합 다섯(콜백이 자기 에러를 격리 — 엔진이 리스너 에러를 격리하는 것처럼): N1 `Add` 중 앞쪽
  `Add`(이웃이 중첩 Slot), N2 `Replace` 중 앞쪽 `Add`(이웃이 중첩 Slot), N3 `Remove` 중 `Remove(1)`, N4 `Remove` 중 `Clear`, N5 파괴 중인
  중첩 Slot에 `Add`.
- `out/probe4-{base,s4,d}.txt`·`out/probe2-{base,s4,d}.txt` — 사본별 출력(`s4` = 10-07 후보 S4의 Slot 부분만 적용).
- `probe5.luau`·`out/probe5-{base,d}.txt` — 플래그가 어느 Slot에 서는지 확인하는 넷: N6·N7 안쪽 Slot의 평범한 원소 `Add`/`Remove` 도중 콜백이 **조상** Slot에 앞쪽 `Add`(HEAD·시제품 모두 imm = def로 동작 — 평범한 원소 연산은 조상 자리를 잡아 두지 않아 조상엔 플래그가 필요 없다), N8 무관한 Slot에 `Add`(둘 다 동작), N9 `Add`로 들어오는 Slot 자신에 `Add`(HEAD imm은 부기 `Length` 3·화면 2개로 어긋남, 시제품은 `Quad0167`).
- `bench.luau` — 비용 측정(mock, Deferred 셔임; 평평한 2000개 마운트, 중첩 200×10 마운트, 추가+제거 2만 회, 교체 2만 회).

## 결과

| 장면 | HEAD(imm) | (a) 후보 S4(imm) | (d) 시제품(imm) | def(셋 다 같음) |
|---|---|---|---|---|
| SL3 마운트 중 같은 Slot `Add` | 부기엔 있고 화면엔 없음 | 동작 | `Quad0167` | 동작 |
| SL4 한 겹 안쪽 원소가 바깥 Slot `Add` | `Quad0167`(기존 가드) | `Quad0167` | `Quad0167` | 동작 |
| SL5 언마운트 중 `Add` | 옛 호스트에 남음 | 동작 | 동작(재정렬) | 동작 |
| SL6 `Remove`/`Extract` 중 앞쪽 `Add` | 다른 원소가 빠짐 | 동작 | `Quad0167` | 동작 |
| SL8 `Splice`로 들어오는 Slot에 `Add` | 화면에 없음 | 동작 | `Quad0167` | 동작 |
| SL·SL2 `Add` 중 끝에 `Add` | 동작 | 동작 | `Quad0167` | 동작 |
| N1 `Add` 중 앞쪽 `Add`, 이웃이 Slot | `Length` 2(정답 4) | `Length` 2 | `Quad0167`, 상태 일관 | 동작 |
| N2 `Replace` 중 앞쪽 `Add`, 이웃이 Slot | `Length` 4(정답 5) | `Length` 4 | `Quad0167`, 상태 일관 | 동작 |
| N3 `Remove` 중 `Remove(1)` | 엉뚱한 원소가 남음 | 동작 | `Quad0167`, 상태 일관 | 동작 |
| N4 `Remove` 중 `Clear` | 원소 1개인데 `Length` 3 | 원소 1개인데 `Length` 3 | `Quad0167`, 상태 일관 | 동작 |
| N5 파괴 중인 중첩 Slot에 `Add` | 넣은 원소가 소유 없이 떠돎 | 같음 | `Quad0167` | `Quad0165`(파괴된 Slot) |

- 스펙: (d) 사본에서 스펙 파일 62개 전부 통과, `luau-analyze quad-base/src` 클린. (a) 사본도 62 통과.
- 비용(세 번씩, ms — HEAD / (d)): 평평한 2000개 마운트 3.50·3.58·3.51 / 3.68·3.79·3.57, 중첩 200×10 마운트 5.29·5.11·5.29 /
  5.94·5.20·5.56, 추가+제거 2만 회 865·861·859 / 858·834·859, 교체 2만 회 403·399·414 / 387·473·390. CRUD는 잡음 안, 마운트는
  0~10% 사이에서 흔들린다(추가된 것은 하위 트리 walk 한 번).
- 한계: (1) (d)가 "콜백만 죽고 바깥 연산은 끝난다"가 되려면 엔진이 리스너 에러를 호출 쪽으로 전파하지 않아야 한다(Roblox는 그렇다고
  알고 있으나 이 조사에서 실측하지 않음). 전파하는 환경(10-07 프로브의 imm 셔임이 그렇다 — `probe2-d.txt`의 "op threw")에서는 바깥
  연산이 중간에 끊기고 그 Slot은 플래그가 선 채 남는다(Q52의 "마운트 중 던지면 그 Slot은 못 쓴다"와 같은 상태). (2) `rawMove`·`rawSwap`의
  엔진 호출 창은 넣지 않았다(Roblox에서 `Parent`가 바뀌지 않는 연산). (3) 콜백이 `:List`의 데이터 State를 바꿔 같은 Slot의 재조정을
  엔진 호출 안에서 다시 일으키는 경로는 공개 CRUD가 아니라 이 가드 밖이다(`updateFn` 재진입과 같은 UB 범위).

## 후속 — "연산이 끝난 뒤 실행" 도구 검토 (2026-10-12)

(d)를 레포에 적용하자 devui 킷의 메뉴 스펙이 `Quad0167`로 실패했다(루트 팝업을 오버레이 Slot에서 `Remove` → 그 안 메뉴 행의
`q.OnDestroyed`가 서브메뉴 팝업을 같은 Slot에서 `Remove`; HEAD에서는 서브메뉴의 index가 항상 더 커서 우연히 맞았다). 사용자가
"미루는 도구 없이 가면 모든 패턴에서 어려워지지 않나", "`task.defer`를 쓰라는 것은 엔진 문제가 아닌 것을 엔진으로 푸는 것"이라 짚어,
필요 여부와 이름을 세 시선으로 검토받았다(서로의 결과를 모르는 채, 메인이 쓰던 이름은 주지 않음). 원문·재료는 `review-after-op/`
(`task-prompt.txt` 과제문, `gemini-report.txt` Gemini 보고서 원문, `insider-prototype-*.diff.txt` 내부자 시제품의 diff — sonnet 둘의
보고는 세션에만 있고 요지는 아래).

| 시선 | 필요한가 | 이름 1순위 / 차선 | 그 밖 |
|---|---|---|---|
| sonnet 외부자(공개 문서·킷 소스만) | 지금은 문서 보강(다만 "신호 설정에 따라 걸렸다 안 걸렸다 하는 에러"를 줄이는 장치의 값은 인정) | `WhenIdle` / `AfterOperation` | `task.defer`의 함정: 미뤄진 사이 Slot·원소가 죽는 경우의 가드를 호출자가 매번 |
| sonnet 내부자(결정 이력·소스) | 약한 찬성 — 세 환경(Immediate·Deferred·mock)에서 같은 코드가 되는 도구, mock에는 `task`가 없음 | `WhenIdle` / `After` | 사본 시제품 약 45줄 — 모듈 수준 대기 목록 하나, 대기분 없을 때 비용은 nil 검사 하나; 실행 지점은 진입점 끝마다(공개 CRUD·호스트 마운트/언마운트·dispose), `:List` 재조정 끝은 빠져 있어 imm에서 다음 연산까지 밀림 |
| Gemini(agy) | 강한 찬성 — 한 Slot에 팝업을 평평하게 두는 오버레이 구조에서는 주류 시나리오, quad-base의 규칙을 엔진 전역으로 풀게 하면 추상화 경계가 깨짐 | `Ready` / `AfterOp` (`WhenIdle`은 넷째 — 뜻은 맞으나 `requestIdleCallback` 연상) | 원소 기반 제거·훅 쪽 해결은 가드를 대체하지 못함; 콜백에 Slot을 인자로 |

메인 검증: 킷 사례는 직접 확인(devui `Menu.luau`·`PopupParts.luau`·`Combo.luau`의 `OnDestroyed`가 오버레이 Slot 닫기로 이어짐; material의
`task.defer` 둘은 이 규칙을 알고 피한 것이 아님 — `Snackbar`는 Observer 발화 순서 때문, `KeyNav`는 Slot과 무관). Gemini의 "`task.defer`는
1프레임 깜빡임"은 근거 없는 추정으로 본다(`task.defer`는 같은 프레임의 다음 재개 지점에서 돈다 — 실측하지 않음). 내부자 시제품의
스펙 통과는 메인이 다시 돌리지 않았다. 결정(만들지, 이름, 인자, 파괴된 Slot의 처리)은 원장 Q185.

**결정(2026-10-12)**: 사용자가 도구를 만드는 쪽으로 정했고 이름은 `slot:WhenIdle(fn)`, 콜백 인자는 Slot, 파괴된 Slot은 그냥 실행. 구현은
내부자 시제품의 뼈대(모듈 수준 대기 목록, 진입점 끝의 실행)에 `:List` 재조정·설치 끝을 더하고, 변이로 불필요함이 드러난 둘(언마운트 끝의
실행 지점, 목록 재시작)을 뺀 것이다 — 정본은 `base/slot-plan.md` 재진입성 항목의 2026-10-12 문단.
