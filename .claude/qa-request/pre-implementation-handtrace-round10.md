# 구현 전 손 트레이싱 **10라운드** — 발견 보고 + 배치 결정 문항지

> **이 파일이 무엇인가**: **[2026-08-28 신설]** 9라운드 후속(`H-143`~`H-146`)
> 반영 뒤 `/code-review high`가 낸 판단 대기 셋(`H-147`~`H-149`)을 씨앗으로,
> 신선한 탐사자가 **M2~M8 전 표면을 광범위하게** 손 트레이싱·실측한 결과를
> 여기 이어 쓴다(`H-150`~). 지시서는 `-round10-brief.md`. **사용자는 §4 표를
> 위에서 아래로 읽고 갈래만 회신한다**(배치). 결정이 나면 `-round10-followup.md`를
> 새로 만들고 `base/`에 반영한다 — **이 파일은 발견 당시의 기록**이라 각 항목의
> "갈래"는 선택 전 목록이니 반영 뒤엔 그대로 믿지 말 것.
>
> 상태: **[2026-08-28 기준] 탐사 진행 중 / 회신 대기.** `H-147`~`H-149`는
> `H-143`~`H-146` 반영분에 `/code-review high`가 낸 10건 중 새 메커니즘·기존
> 결정 변경이라 문항으로 올린 셋(나머지 일곱은 반영 — `-round9-followup.md`의
> 마지막 code-review 절).

## 요약 표

| 번호 | 심각도 | 한 줄 | 주 대상 | 성격 | 실측 |
|---|---|---|---|---|---|
| `H-147` | 🟡 | `Rerun` 꼬리 `wasAlive`가 루프 머리 `_consumeCleanup()` **뒤**에 잡히고 공개 `Rerun()`에 게이트가 없어 **진입 시점에 이미 죽은 핸들**(직전 cleanup이 `self:Unsubscribe()` / 해제 뒤 타이머의 `self:Rerun()`)은 else 분기 → 고아 cleanup + `_installed = true` | `effect-plan.md` `Rerun` | `/code-review` 발견, 처방은 규칙 또는 새 플래그 | — |
| `H-148` | 🟡 | `H-146`의 "`Parent` 거부는 **전용 문구**"가 새 메커니즘 — `isHandlable` 거부는 `Dispatch.process`의 **일반** 매치 실패 문구로 떨어지고 그 자리에 특수 분기는 두지 않기로 확정돼 있다. 사용자 회신에 문구 언급 없음(에이전트 선택이었음) | `bind-system-plan.md` `H-142` 항목, `ROADMAP.md` M5 | `/code-review` 발견, 처방은 새 핸들러 또는 철회 | — |
| `H-149` | 🟡 | `Observer:Subscribe`가 `self:WeakSubscribe()`로 위임하므로 거기 붙인 `error(…, 2)`가 `o:Subscribe()` 경로에선 사용자 호출부가 아니라 `Observer:Subscribe` 본문을 가리킴(`H-104` level 계약 위반). `EffectHandle`은 (b)로 인라인해 문제 없음 | `lifecycle-pattern.md` Observer 네 진입점 | `/code-review` 발견, 처방은 기존 결정("위임하므로 게이트 한 번") 변경 | — |

## 상세

### `H-147` 🟡 — 이미 죽은 핸들에서 `Rerun()`이 불리면 (`H-143` 잔여)

`effect-plan.md` `Rerun`: 루프 머리 `_consumeCleanup()` → `local wasAlive =
canExecute(self)` → `fn` → `if wasAlive and not canExecute(self)`. "실행 중에
죽은" 건 잡지만 **"진입 시점에 이미 죽은"** 건 못 잡는다:
1. 직전 cleanup이 `self:Unsubscribe()`를 부름 → 루프 머리 소진 안에서 죽음 →
   `wasAlive` 거짓 → `fn` 실행 → else → 저장 + `_installed = true`. 고아 cleanup,
   이후 재`Subscribe`의 `resubscribeTail`이 `_installed` 참을 보고 재설치 생략.
2. `fn`이 `task.delay(1, function() self:Rerun() end)`를 걸고 사용자가 그 전에
   `Unsubscribe()`.
생성자 최초 `Rerun`("한 번도 산 적 없음")과 구분할 상태가 없다.
**갈래**: (a) "죽은 핸들에서의 `Rerun()`은 사용자 책임(UB)"으로 문서화 — 새
상태 없음; (1)은 "cleanup 안에서 자기 해제"를 지원 목록에서 빼는 것, (2)는
`Unsubscribe`가 도는 cleanup이 그 예약을 취소해야 하는 것(그게 cleanup의 일).
기존 "error 시 UB / 수렴 책임은 `fn`" 계약과 같은 결 / (b) `_everAlive` 플래그
하나(첫 `canExecute` 참 시점에 세움) → `Rerun` 진입에서 `everAlive and not
canExecute → return`. 필드 하나, 생성자 케이스도 가림 / (c) `wasAlive`를
`_consumeCleanup()` **앞**에서 잡기 — (1)만 닫히고 (2)는 그대로.
**권고 (a)** — 두 시나리오 다 "죽은 뒤에도 자기를 부르는 코드"고, `Unsubscribe`가
cleanup을 도는 이유가 바로 그런 예약을 거두라는 것.

### `H-148` 🟡 — `H-146`의 "전용 에러 문구"는 새 메커니즘이었다

`PropertyHandler.isHandlable`이 `"Parent"`를 거부하면 나오는 건 `Dispatch.process`의
**일반** 매치 실패 문구(*"no handler … check provider"*)이고, 그 자리에 특수
분기는 두지 않기로 확정돼 있다(`dispatch-core-plan.md`의 매치 실패 절). 전용
문구를 내려면 새 자리가 필요하다. 사용자 `H-146` 회신엔 문구 언급이 없었고
에이전트가 "배선 세부"라며 붙였다 — `conventions.md` 2026-08-27 규칙 위반.
**갈래**: (a) 전용 문구 **철회** — 일반 매치 실패 error 그대로, 오해는 사용자
문서("`Parent`는 props에 못 쓴다, 루트는 밖에서")로 흡수. 새 것 0 / (b) **가드
핸들러** — `k == "Parent"`에 매치해 `process`에서 전용 문구로 error. Observer/
Effect의 "동적 경로 가드"(`effect-plan.md`)와 같은 모양이라 새 *종류*는 아니나
핸들러 하나 + 숏핸드보다 위 우선순위 필요 / (c) `Dispatch.process` 매치 실패
문구에 키 이름을 싣기(일반 개선이지만 별도 결정).
**권고 (a)** — 원래 회신의 취지(새 API 없음, 최종 사용자 몫)와 같은 결. M5에서
실제로 밟아 헷갈리면 (b)를 그때 얹는 게 싸다.

### `H-149` 🟡 — `Observer:Subscribe`의 위임 때문에 `level 2`가 quad 내부 줄을 가리킨다

2026-08-27에 `Observer:WeakSubscribe`의 `error`에 `, 2`를 붙였는데(`H-104`
계약), `Subscribe`가 `self:WeakSubscribe()`로 위임하므로 `o:Subscribe()` 경로의
level 2는 **`Observer:Subscribe` 본문**을 가리킨다. 가장 흔한 오용(leaf 바인딩된
Observer에 `o:Subscribe()`)이 quad 내부 줄을 블레임한다. `EffectHandle` 쪽은 (b)로
게이트를 인라인해 문제 없음.
**갈래**: (a) Observer도 `Subscribe`에 게이트·등록 세 줄을 **인라인** — Effect와
같은 모양, level 2 정확. "게이트는 한 번만 돈다 — `Subscribe`가 `WeakSubscribe`에
위임"이라는 기존 문장이 "각자 한 번"으로 바뀜. 중복 세 줄은 같은 타입 안이라
dot 호출 로컬 헬퍼로 빼도 됨(가상 디스패치 없음) / (b) 내부 헬퍼
`weakSubscribe(self, level)`로 위임하고 `Subscribe`는 `level 3` — 코퍼스에
`level 3` 선례 없음 / (c) 그대로 두고 `Subscribe` 경로만 블레임이 한 단계 안쪽임을
문서화.
**권고 (a)** — "본문을 섞지 않는다"(2026-08-27 원칙)와 결이 같다.

## §4 ⭐ 사용자 결정이 필요한 것 (배치 회신용)

| 문항 | 무엇 | 선택지 | 권고 |
|---|---|---|---|
| **`H-147`** | 죽은 핸들에서 `Rerun()` | (a) UB로 문서화(cleanup 안 자기 해제는 지원 목록 밖, 타이머 취소는 cleanup의 일) / (b) `_everAlive` 플래그 + 진입 게이트 / (c) `wasAlive`를 소진 앞에서 | **(a)** — 새 상태 없이 기존 UB 계약과 같은 결 |
| **`H-148`** | `Parent` 거부 문구 | (a) 전용 문구 철회, 일반 매치 실패 그대로 / (b) `Parent` 가드 핸들러(동적 경로 가드형) / (c) 일반 문구에 키 이름 | **(a)** — 회신 취지(새 API 없음) 그대로, 필요하면 M5에서 (b) |
| **`H-149`** | Observer `Subscribe` 위임과 `level 2` | (a) `Subscribe`에 게이트·등록 인라인(Effect와 동형) / (b) `level 3` 위임 / (c) 문서화만 | **(a)** — 본문 안 섞기 원칙과 동형 |

(탐사자의 문항은 아래에 이어 붙는다.)

## §5 이상 없다고 확인한 것

(탐사자가 채운다.)

## §6 남은 의심 / 못 본 것

(탐사자가 채운다.)

## §7 레인 C 실행 기록

(탐사자가 채운다 — `audit/handtrace-round10-reference-impl/`.)
