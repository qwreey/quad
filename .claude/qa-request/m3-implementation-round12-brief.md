# M3 자율 구현 규약(안) — 12라운드 지시서 + 착수 문항지

> **이 파일이 무엇인가**: **[2026-08-31 신설, §0 회신 대기]** M3(디스패치 엔진)
> 구현 구간의 규약 초안이자 착수 문항지다. **§0 표가 사용자가 읽을 유일한
> 자리** — 회신이 §0에 기록되면 이 파일이 M2의 `m2-implementation-round11-brief.md`와
> 같은 지위(규약 소스 + 단위 끝 탐사자 지시서)가 된다. 산출물(발견 문서)은
> 착수 시 `m3-implementation-round12.md`로 신설.
>
> **명명**: `mN-implementation-roundNN` 규약(2026-08-31 사용자 확정,
> `.claude/README.md` `qa-request/` 행이 소스) — 라운드 번호는 마일스톤을
> 가로질러 단순 증가라 M3의 첫 라운드가 **round12**, 발견 번호는 round11이
> `H-211`까지 썼으므로 **`H-212`부터**.
>
> §2~§5는 M2 규약을 준용하되 M3에 맞게 고친 자리에 `[M3 변경]` 표시를 달았다 —
> M2와 어디가 다른지는 그 표시만 훑으면 된다.

---

## §0 ⭐ 착수 문항 (배치 회신용)

| 문항 | 무엇 | 선택지 | 권고 | 권고 근거 |
|---|---|---|---|---|
| **Q1** | M2 규약의 재사용 범위 | (a) 골격 그대로 — 발견 세 갈래(§2) / 리뷰 발견 취급(§3) / 커밋 게이트 두 층·단위 끝 절차(감사 루프 → `/code-review high` → 커밋 → fable 탐사자 → "§4를 보라" 한 줄)(§4) — 에 **M3 전용 게이트 하나 추가**: 새 핸들러를 짜기 전 `dispatch-core-plan.md`의 "Handler 작성 체크리스트" 절 필독(실제 반복된 실수 목록이라 M2엔 대응물이 없던 것) / (b) 절차를 줄임(예: 탐사자 생략) / (c) 다른 방식 | **(a)** | M2 실측 — ③(즉시 중단) 0회, 배치 회신 3번으로 발견 47건(`H-165`~`H-211`) 처리, 단위 절단 덕에 관여 시점이 촘촘해 손실 구간이 없었다. 탐사자는 매 단위 ①만 내고도 문서-코드 어긋남을 7건(`H-191`~`H-197`) 잡은 실적이 있어 유지 가치가 실증됨 |
| **Q2** | 단위 절단 | (a) **넷** — §1의 제안(코어 → 부기 → `None`/`Nil` 핸들러 → Leaf·가드·종합) / (b) 셋(코어+부기 합침 — 단위당 비용 커짐) / (c) 다른 절단 | **(a)** | 의존이 단방향(코어 → 부기(NilHandler가 부기 API를 등록) → 핸들러 → 가드·종합)이고, M2와 단위당 규모가 비슷해 비용 감각이 검증된 눈금 그대로다. 단위 2가 M2 소비의 첫 실전(Observer 콜백·Blocker·접두합 캐시)이라 M2 결함이 있다면 일찍 드러난다 |
| **Q3** | M3 진행 중 **M2 하자**가 나올 때 | (a) 경미한 것(문서 stale·주석·기존 계약 **안**의 코드 오류)은 M3 라운드 파일(`m3-implementation-round12.md`)에 `H-nnn`으로 기록하고 ① 갈래로 자율 수정, **M2 설계 결정이 필요한 규모**(새 메커니즘·확정 역전)면 그때 `m2-implementation-round13`(그 시점의 다음 번호)을 새로 열어 §4 배치 문항으로 / (b) 규모 무관 전부 M3 파일에 / (c) 규모 무관 전부 M2 파일 신설 | **(a)** | 명명 규약의 취지(*"m3 을 진행하다 m2 에 하자가 있음을 확인하면 다시 m2 로 올라가 round 가 진행되다 돌아오는 경우"*) 그대로 — 접두가 소속을 담으려면 **결정이 필요한 것만** M2 라운드로 승격하고, 잔손질까지 파일을 쪼개면 발견 흐름이 갈라진다 |

**통보(문항 아님 — 규약·코드 배치라 여기 명시만)**: 발견 문서는 착수 시
`m3-implementation-round12.md` 신설, 번호 `H-212`부터. **mock 확장은 불필요** —
M3 핸들러가 부르는 건 quad-base 자기 부기 API(`setLength` 등)뿐이고 엔진
op(`addTag`/`setAttribute`/`native*`)는 M5/M10 몫이라 지금 mock(생명주기 4종 +
`onDestroying` + mock Instance)으로 충분하다. 코어 테스트는 실핸들러가 아직
없으므로 **spec 파일 로컬의 테스트 전용 핸들러**로 돌린다(코드 배치).

## §1 범위와 순서 — 단위 넷 (제안, Q2)

소스는 `ROADMAP.md` M3 체크박스(13개, 개수·상세는 거기가 소스). 단위 안의
순서는 체크박스 순서를 따르되 단위 배정은 아래:

1. **Handler 계약 + 디스패치 코어** — `Handler.luau`(계약 타입 3종:
   `isHandlable(inst,k,v)`/`priority`/`process(...) -> retractor`),
   `Dispatch/init.luau`(`getHandler`/`process`(하강 diff)/3-인자
   `retractFrom`/`addHandler`/`drive` 단일 일반화 `for`), `chains` 부기
   (Relate 기반), 계약 검증(`process`가 retractor를 안 돌려주면 즉시 error),
   우선순위 동률·매치 실패 처리, `quad-types` `Quad.Dispatch`(`H-25`).
   파이프라인 정본은 `base/dispatch-core-plan.md`와
   `base/bind-system-plan.md`의 "`New(name)(props)` 파이프라인 의사코드" 절.
2. **Length/Offset 부기** — `setLength`(+`anchor`/`element` 인자)/
   `setOffsetSource`/`getOffsetAt` + **접두합 캐시 계약 전체**(`bk.offsetCache`/
   `offsetCacheValidUpTo`/`offsetSetUpTo` 두 필드/`recomputeBlocker`/
   `bk.indexOfElement` weak-key, 무효화 자리는 `dispatch-core-plan.md`의
   무효화 표가 소스), len이 State일 때의 Observer 콜백. **M2 소비의 첫
   실전**(Observer·Blocker·Source).
3. **`None` 센티널 + `NoneHandler`/`NilHandler`** — 첫 실핸들러 둘.
   `H-39`(말단 핸들러의 `setOffsetSource(None)`→`setLength(0)` 등록 계약)의
   첫 적용이자 Handler 작성 체크리스트 게이트의 첫 실행. `architecture.md`
   소스 트리에 탑레벨 `None.luau` 줄도 이때 추가(ROADMAP가 예고).
4. **`Dispatch/Leaf.luau`(`ObserverEffectLeafHandler`) + Observer/Effect 동적
   경로 가드 등록 + mock 대상 종합 테스트**(ROADMAP M3 마지막 항목) —
   M2 값(Observer/Effect/bindLifetime)을 디스패치가 실제로 물어 올리는 자리.

- 각 모듈은 M2처럼 **"`base/` 확정 의사코드를 그대로 옮긴 구현 + 그 절의
  계약을 검증하는 spec"** 짝으로, 테스트는 `./scripts/test.sh`로만.
- **[M3 변경] 이름 해석 규칙 하나**: `base/` 의사코드의 자유 이름
  (`bindLifetime`/`canExecute`/`Effect`/`Blocker` 등)은 전부
  `InitDispatch(module)`이 쥔 `module.xxx`이고 생명주기 넷은 발화 시점에
  늦게 읽는다(`H-174` (a) — round11 §5의 M3 예고가 소스).
- **[M3 변경] 미리 알려진 주의 둘**(round11 §6): `H-186`(교차 인스턴스 UB)의
  이웃인 교차 `bindLifetime`은 UB로 닫혔으니 가드를 새로 만들지 말 것 /
  Slot 쪽(`materializeSlotTree`)이 Observer 사적 필드를 직접 쓰는 자리는
  M6 몫이되 그 경계가 이 마일스톤 코드에 들어오면 발견으로 올릴 것.

## §2 세 갈래 (M2 §2 준용)

`m2-implementation-round11-brief.md` §2 그대로 — ① 문서가 답을 가진 것은
`H-nnn` 기록 + `base/`·코드 같은 커밋 자율 수정 / ② 새
필드·인자·이름·메커니즘·확정 역전은 코드에 넣지 말고
`m3-implementation-round12.md` §4 표에 갈래+권고+근거로 배치(코드엔
`-- TODO(H-nnn)` 마커만, "옛 메커니즘 복원" 표시 포함) / ③ 짠 코드 상당
부분을 무효화할 규모면 즉시 중단·보고. **[M3 변경]** M2 하자는 §0 Q3의
결정을 따른다.

## §3 리뷰·감사 발견의 취급 (M2 §3 준용)

그대로 — 리뷰의 "새 메커니즘"은 ②로, 반영 전 소유자·기각 이력 grep.

## §4 관여 시점 (M2 §4 준용)

커밋 게이트 두 층(매 커밋 doc-check ERROR 0 / 단위 끝 감사 루프 →
`/code-review high` → 커밋 → fable 탐사자 → "§4를 보라" 한 줄), 세션 원문
규율, 인덱스 3층 갱신 — 전부 그대로. **[M3 변경]** 머리말 갱신 문구는
"M3 진행 중".

## §5 탐사자 지시 (단위 끝마다)

M2 §5를 그대로 쓰되 치환 셋: 대상 라운드 파일은
`m3-implementation-round12.md`, 이 파일의 §1~§3을 먼저 읽고, 대조 대상
`base/` 절은 `dispatch-core-plan.md`(특히 "Handler 작성 체크리스트" 절과
무효화 표)·`bind-system-plan.md`가 중심. `git stash` 금지·실행 우선·한 줄
대조·`grep -rn "TODO(H-"` 전수 확인은 동일.

## §6 첫 단위(코어) 작업 계획 — §0 회신 후 확정

Q1·Q2가 (a)로 닫히면 여기 M2 §6과 같은 급의 파일·spec 표를 채워 사용자
확정을 받는다(코드 배치는 그 계획이 소스). 초안 요지만: `Handler.luau`는
계약 타입만 담는 잎 / `Dispatch/init.luau`가 `InitDispatch(module)` 팩토리
(`module-lifecycle-plan.md`의 예시 그대로 — `H-174` (a)의 원형) /
`chains`는 `Relate` 인스턴스 / spec은 `spec.dispatch.luau` + spec-로컬
테스트 핸들러.
