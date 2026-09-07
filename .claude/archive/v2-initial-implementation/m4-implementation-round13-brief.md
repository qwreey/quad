# M4 자율 구현 규약 — 13라운드 지시서 + 착수 문항지

> **이 파일이 무엇인가**: **[2026-09-01 신설, 같은 날 §0 확정 — 규약 확정]**
> M4(첫 end-to-end 반응형 업데이트) 구현 구간의 규약이자 착수 문항지다. M3의
> `m3-implementation-round12-brief.md`와 같은 지위 — §0 확정으로 이 파일이
> M4 규약 소스다. 산출물(발견 문서)은 `m4-implementation-round13.md`.
>
> **명명**: `mN-implementation-roundNN` 규약 그대로 — 라운드 번호는
> 마일스톤을 가로질러 단순 증가라 M4의 첫 라운드가 **round13**, 발견 번호는
> round12가 `H-286`까지 썼으므로 **`H-287`부터**.
>
> §2~§5는 M3 규약(= M2 준용본)을 준용하고, 다른 자리에만 `[M4 변경]` 표시.

---

## §0 ⭐ 착수 문항 (배치 회신용)

| 문항 | 무엇 | 선택지 | 권고 | 권고 근거 |
|---|---|---|---|---|
| **Q1** | 규약 재사용 범위 | (a) M3 골격 그대로(세 갈래 / 리뷰 발견 취급 / 커밋 게이트 두 층·단위 끝 절차·새 핸들러 전 "Handler 작성 체크리스트" 필독 게이트) + **2026-09-01 신설 운용 규약을 절차에 통합**: 감사·리뷰는 유한 절차(각도 소진 시 잔여 보고 후 종결), `/code-review`는 흐름당 1회에 **강도는 diff 규모로**(M4는 파일 하나+spec 규모라 `high`가 아닌 낮은 강도가 기본 후보 — 돌리기 전 규모 보고 판단), 문서 추론형 작업 비분할 / (b) 절차 축소(탐사자 생략 등) / (c) 다른 방식 | **(a)** | M2·M3 두 구간 실측으로 골격은 검증됐고, 운용 규약은 conventions에 이미 사용자 확정으로 명문화돼 있어(2026-09-01) 절차에 접는 것만 남았다 |
| **Q2** | 단위 절단 | (a) **단위 하나** — `StoreBind` 구현 + mock 대상 end-to-end spec(ROADMAP M4 체크박스 둘이 한 호흡: 구현 없이 spec이 없고 spec 없이 잔여 몫(스파이크 `04`)이 안 닫힘) / (b) 둘로(구현 / 종합 분리) / (c) 다른 절단 | **(a)** | M4는 M2·M3가 만든 부품의 첫 합류점이라 새 코드가 작다(핸들러 하나 + spec 하나). 단위 끝 절차 1회로 충분하고, 쪼개면 절차 비용이 코드 비용을 넘는다 |
| **Q3** | `StoreBind`의 등록 소유 — `H-278` 원칙("각 객체를 아는 곳은 각 객체가 선언된 곳")을 여기도 확장할지 | (a) **`Dispatch/StoreBind.luau` 유지**(architecture 트리 그대로, `InitDispatch` 꼬리가 register — `None.luau` 선례) / (b) `H-278` 확장 — State/Source 선언 모듈이 등록 / (c) 다른 방식 | **(a)** | `H-278`의 결정 범위는 **leaf 핸들러·가드**(특정 값 타입 하나의 바인딩)였다. StoreBind는 값 하나의 소유물이 아니라 **하강 diff의 재귀 그 자체**(래핑 중간 노드 — 어떤 값 종류든 반응형이면 언랩)라 None과 같은 결의 "디스패치 자신의 개념"이고, 매치가 `isState`(구조적으로 Source 포함) 브랜드 계열 전체에 걸쳐 단일 선언 모듈이 없다. 정본 절 제목부터 "Store 바인드는 특수 경우인가, 아니면 pluggable 바인드를 재실행하는 래핑인가"(dispatch-core 소속) |
| **Q4** | 스파이크 `03`(StoreBind 재귀 재-dispatch) 처분 — STATUS.md 2026-08-31 메모가 "M4 구현 시점에 판단"으로 예약해둔 것 | (a) **폐기 확정** — `spec.storebind`가 같은 질문(재귀 종료·`None→nil` 핸드오프·우선순위 스캔)을 실구현 상시 회귀로 대체(`01`/`04`/`05` 폐기와 같은 근거 구조), `done/` 행에 기록 / (b) 재작성 존치 / (c) 다른 방식 | **(a)** | 폐기 근거의 나머지 절반(실제 `StoreBind` 경유)이 정확히 이 단위에서 생긴다 — 스파이크는 격리 근사라 실구현 spec보다 약하다는 것이 네 번 반복된 판정 |

**⭐ [2026-09-01 회신 — 조건부 승인으로 확정]** 사용자 원문: *"M4 진행
가능해보여? … 수행 계획인데, 수행 가능하다면, 막는게 없다면 M4 구현
시작해보자. 혹은 구현 전에 먼저 감사를 도는게 더 나아보이면, 구현을 멈추고
이 지점에서 다시 페이서 논의를 시작해도 좋고(의사코드 부족 등, 실 구현에
있어 부딛힐 부분이 많다면)"* — 개별 문항 반대 없이 "막는 게 없으면 착수"를
지시한 것이라 **Q1~Q4 전부 권고 (a)를 채택**하고, 착수 세션이 조건
(실 구현 가능성)을 먼저 검증했다: 정본 절 의사코드가 실코드 부품
(`Dispatch/init.luau`의 (B) 점유 마커 선행 — 주석이 StoreBind 재귀를 정상
경로로 명시 / `state:Observer(fn)` 등록 즉시 1회 발화 / mock
`bindLifetime`·`canExecute` / `Brand.isState`의 Source 포함 합성)과 전부
맞물림을 확인 — **막는 것 없음, 착수.** 이 읽기가 틀렸다면(어느 문항이든
(a)가 아니라면) 다음 검증 패스에서 사용자가 뒤집으면 된다.

## §1 범위 — 단위 하나 (제안, Q2)

소스는 `ROADMAP.md` M4 체크박스(둘, 상세는 거기가 소스):

1. **`Dispatch/StoreBind.luau`** — 재귀 재실행 핸들러. 정본은
   `dispatch-core-plan.md`의 "Store 바인드는 특수 경우인가" 절 의사코드
   (선행 `retractFrom` 없이 `Dispatch.process(inst,k,realv,index+1)` 한 줄,
   `state:Observer(fn)` 재사용 + `bindLifetime(inst, observer)`, 반환
   클로저는 `unbindLifetime(observer)`뿐). 우선순위는 HIGH 밴드("base 소속
   핸들러가 전부 여기 오는 게 아님" 절이 StoreBind를 골격으로 명시).
2. **mock 대상 end-to-end spec**(`spec.storebind.luau` 가칭) — ROADMAP
   체크박스 둘째의 전 항목: store 값 변경 → `process` 재호출 / 타입 교대 시
   이전 retractor 호출 / `State<State<T>>` 인덱스 N·N+1 비충돌 / 최초 마운트
   직후 첫 재발행에서 인덱스 2 retractor 실호출(`SetStrong` 순서 버그의 증상
   자리) / **스파이크 `04` 잔여 몫**: 실제 StoreBind 경유 재발행에서 깊은
   인덱스부터 정리 + **효과 수준 단언**(재발행 후 옛 store 구독 0, 죽은
   store를 건드려도 값이 안 덮임 — 순서 로그만으로 닫지 말 것, 리뷰 보강).

- **quad-types 갱신 없음(확인 사항)**: StoreBind는 공개 표면이 아니라
  `H-25`의 "마일스톤마다 갱신" 규칙에서 이번 몫은 "갱신할 것 없음 확인"이다
  — 어긋나면 발견으로 올릴 것.
- **[M4 변경] 미리 알려진 주의**: ① 재발행의 정본 경로가 정확히 이 핸들러다
  — `drive` 재호출은 형상 불문 UB(`H-275`), spec도 `process` 경유로만 재발행
  흉내낼 것. ② retractor 2번째 인자 `retracting`(`H-258`)은 StoreBind
  retractor에선 무시해도 정확(자기 Observer 해제뿐, nil을 값으로 안 받음).
  ③ round12 §6의 미검증 실질 후보 셋(`H-286` — Effect 드레인 vs cleanup 중
  `Rerun` / `_catchUp` 에포크 랩)은 이 구간 감사 라운드가 한 각도로 파볼 것
  (M6 몫인 unbind-relate 축은 제외). ④ 새 핸들러 게이트: 착수 전
  "Handler 작성 체크리스트" 절 필독(특히 8번 — 조건부 재위임 없음 확인).

## §2 세 갈래 / §3 리뷰·감사 발견 / §4 관여 시점 / §5 탐사자 지시

M3 규약(`m3-implementation-round12-brief.md` §2~§5) 준용. 치환:
발견 문서는 `m4-implementation-round13.md`(`H-287`부터), 머리말 문구는
"M4 진행 중", 탐사자의 대조 중심 절은 dispatch-core의 "Store 바인드는
특수 경우인가" 절 + "Dispatch 체인" 절. **[M4 변경]** §4의 단위 끝 절차에서
`/code-review` 강도는 Q1 (a)의 운용 규약을 따른다(돌리기 전 diff 규모 보고
판단·흐름당 1회). M3 하자는 M3 브리프 §0 Q3 (a) 규칙의 동형 — 경미하면
round13에 ①, 설계 결정 규모면 `m3-implementation-round14`(그 시점 다음
번호) 신설.

## §6 단위 작업 계획 (승인 대상 — Q2 (a) 기준)

| 파일 | 내용 | 옮겨 적는 절 |
|---|---|---|
| `quad-base/src/Dispatch/StoreBind.luau` | 핸들러 정의 + `register(dispatch, module)`(배치는 Q3 결정 따름; (a)면 `None.luau` 선례 그대로 `InitDispatch` 꼬리 호출). `isHandlable`은 브랜드 술어 기반(`isState` 계열 — 정확한 술어 구성은 정본 절 확인이 첫 작업, 어긋나거나 미정이면 발견으로) | dispatch-core "Store 바인드는 특수 경우인가" 절 의사코드 그대로(Observer 재사용 정정·`bindLifetime` 기준·클로저 upvalue 캡처 포함) |
| `quad-base/test/spec.storebind.luau` | §1의 2번 전 항목 + 스파이크 `03` 대체 몫(재귀 종료·`None→nil` 핸드오프가 실구현에서) — GC/구독 검증은 기존 관례(팩토리 패턴·`mock.assertBlamesUser`·`addSpecLeaf`) 재사용 | ROADMAP M4 체크박스 둘째가 소스 |
| `.claude/luau-test/STATUS.md` | Q4 결정 반영(`03` 행) | — |

**커밋 단위**: 모듈 하나라 커밋 하나(구현+spec+`base/` 정정 동커밋) 후
단위 끝 절차. 종료 시 M4 마감(머리말 3층)까지 — M2·M3 관례 그대로.
