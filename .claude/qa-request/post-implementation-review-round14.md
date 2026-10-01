# 구현 뒤 리뷰 round14 — round13 남은 문항 이관 + 원칙 재검토 (2026-10-01~)

**[2026-10-01 신설 — 사용자 지시]** *"round 13 이 지금 너무 방대해. 남은 문항은 round 14 로 옮기던가 하자. 또, 거기 문항도 지금처럼, 코드리뷰의 말이 충분히 검토되지 않아 생긴 문제가 있을지 없을지 모를것 같아. 14 로 옮기고 재검토 한번 돌고 나서 처리하는거 어때? 그러면서 한번 프로젝트 전체에 원칙 문제를 보고 시작하자. 뭔가 더 꼬이면 풀기 힘들어지겠어."* (`session/2026-09-28-01-round13-batch-reply.md` 2026-10-01 끝 절)

**순서**: (1) 프로젝트 전체 원칙 감사(`audit/round14-principle-audit/` — 판정 기준 `PRINCIPLES.md`, 서브시스템별 읽기 전용 넷) → (2) 아래 이관 문항 각각을 같은 기준으로 재검토(그 문항의 발견·권고가 리뷰·탐사 입력을 사용자 결정처럼 받아 원칙을 넘는지 — 2026-10-01 회고에서 Q111·Q76·round1 Q4·`H-101`이 그 사고였다) → (3) 사용자 회신으로 처리. 발견 번호는 round13의 `H-nnn`을 이어 쓰고 문항 번호는 `Q`를 이어 쓴다(새 문항은 `Q160`부터).

**이관 방식**: 문항 본문(상황·갈래·권고·근거)은 round13 §4에 그대로 두고 여기엔 포인터와 재검토 결과만 쌓는다 — 본문을 복사하면 두 곳이 갈라진다(conventions "개수·목록·상태는 소스를 하나만"). 각 문항의 원문은 `post-implementation-review-round13.md` §4에서 `**Qnn [`로 찾는다. round13에서 **보류**로 닫힌 것(Q76·Q87·Q122·Q127, Q90 ⑬)은 이관하지 않는다 — 보류 결정이 그대로 유효하고, 재론은 사용자 지시 때.

## §0 이관 문항

| 문항 | 요지(round13 §0 표에서) | 심각도 | 재검토(원칙 감사 뒤) |
|---|---|---|---|
| Q75 | 배치·파동 중 `native*`에 stale offset | LOW | |
| Q86 | Luau 옵셔널 제네릭 무검사 상류 보고 | MED | |
| Q97 | 철거 retractor 등치가 float32에서 거짓 | LOW | |
| Q117 | 에러 ID 전수 대조(E28)의 코드 쪽 — 죽은 raise 자리 셋(`0098`·`0192`·`0209` AddPlugin 갈래), 한 조건 여러 id 셋(0169/0242·0020/0158/0162·0018/0043/0123), blame 둘(0023/0024 `e… | LOW~MED | |
| Q119 | 릴리즈된 CHANGELOG 절의 사후 편집 정책 — 3.0.0 절은 게시 뒤 `052b42e9`에서 재구성됐고(태그 시점 본문과 다름), 3.1.0 `slot:Single` 줄엔 타입 BREAKING 표시 없음, 3.1.0 주석 태그 메시지엔 Fixed 항목 누락 | LOW | |
| Q120 | mock 충실도 — 엔진과 다른 넷(같은 값 재대입 발화·Parent 잠금 없음·순환 Parent 허용·같은 부모 재대입 시 자식 이동)을 mock에 맞출지, nil 쓰기를 단언하는 spec 두 절(mock 전용)을 둘지, mock op 문구에 `QuadNNNN` 없음 | LOW | |
| Q121 | `Slot:Single<Item, UD>`의 매핑 `updateFn` 호출이 strict에서 타입 인자 명시 없이는 통과하지 못함(`Item?` 팔이 State를 `Item` 하한으로) — 문서 약속과 어긋남 | LOW~MED | |
| Q124 | `type_version_check` 문법의 미정의 구석 — `N^`의 "숫자"(런타임 `tonumber` vs 파이썬 포트 `int`: nan/inf/hex/지수/2^53 정밀도/음수 하한이 갈림), `^`·`x^`처럼 N이 숫자 아닌 자리(항상 false — 문서 … | LOW | |
| Q125 | `Slot:List` 데이터 배열 `nil` 구멍 — 자리마다 다른 처리(props 숫자 키 `Quad0023`·Tag 리스트 `Quad0203`은 던짐, Slot `initial`은 조용히 무시, `:List` 데이터만 조용히 뒤를 잘라 **기존 원소 파괴**) | MED | |
| Q131 | 릴리즈 리허설(3.3.0·4.0.0 사본) — 게시 타르볼은 전부 맞으나 게이트 넷 구멍(bump 뒤 `pesde install` 없이도 test.sh exit 0 — E30 B1 재현, bump 잔여 목록이 정확 문자열만 찾아 README 27행·`^3.0.0`·"3… | MED | |
| Q139 | 파괴 순서·파동 계약의 미정 셋 — Immediate 시그널에서 자손 `OnDestroyed`의 `Set`이 **다른 호스트**(이미 Destroying이 끝난 조상)의 Observer를 한 번 더 돌림(core/05 32는 "같은 호스트"만; mock 순서 — 부모 … | LOW | |
| Q140 | Attr 이름이 먼저 claim되고 그다음 `setAttr` — 엔진이 값(타입)·이름(공백·`RBX`·100자)을 거부하면 claim만 남아 그 이름이 영구 잠김(`Key.luau` 420~422; `H-684`는 "다른 이름에서 던짐"만) → 값을 고쳐도 `Quad… | LOW~MED | |
| Q142 | Debounce/Throttle 문서 미정 칸 — 같은 시각 두 신호(Throttle 첫 leading·둘째 보류), 창 끝과 같은 시각의 새 신호(mock은 타이머 먼저 — 엔진 `task.delay` 순서 미실측), `Time = 0`(같은 `advanceTime(… | LOW | |
| Q144 | `:Apply`의 객체 팔 `{ __apply: (self: any, state: any) -> any }`가 사용자 `__apply` 테이블을 거부 — `state` 무주석·`q.State<number>`·반환 타입 주석 전부 "None of the overloads… | LOW | |
| Q145 | `EffectFn` 반환 `...((dying: boolean) -> ())`이 두 갈래 `fn`(한 갈래 cleanup·다른 갈래 `return nil`)을 거부 — `return nil`·`((dying) -> ())?` 주석·빈 `return`·`return` 제… | LOW~MED | |
| Q149 | mock `Signal:Fire`(`mock.luau` 82~91)가 리스너의 throw를 발화 원인 쪽으로 그대로 올리고 스냅샷의 나머지 리스너를 건너뜀 — 엔진은 리스너마다 격리 실행·로그만(E66 기억, **미실측**). 그래서 mock에서는 `OnChange` … | LOW | |
| Q153 | `quad-base/test/mock.luau` 645 `mockProvider(quad: any): { [any]: any }` 반환 주석이 8.35의 strict 함정 모양 — how-to 06이 본보기로 권함(문서엔 `H-826`으로 경고) | LOW | |
| Q154 | 변이 테스트(E69, 손으로 고른 계약 자리 243곳): 죽음 195·생존 48(동등 20·추정 동등 3·**실제 공백 25** — 확인 22·미확인 3), 원점수 80.2%·보정 88.6%; Bookkeeping 44%·Slot 66%가 낮음. 최대 구멍은 기준 오프… | MED(테스트 정책) | |
| Q155 | 리터럴 정적 자식(`D.Frame({ el })`)으로 앉은 값은 옮길 공개 경로가 없다 — `el.Parent = nil`을 해도 `Quad0172`/`Quad0160`(레지스트리는 그대로), 숫자 키 리터럴 자리의 Slot도 `q.dispose(slot)`이 `Qu… | LOW~MED | |
| Q157 | Roblox `SignalBehavior = Deferred`(새 경험 기본) 아래의 `OnChange`/이벤트/`q.Out` 동작을 문서가 다루지 않음 — Deferred **셔임**으로 잰 차이 셋: (F1) 한 프레임 안에 앞선 `Activated`가 `Set`한… — 남은 것: F1·F5(실기기 묶음 — F6은 닫힘) | LOW~MED | |
| Q123 | 남은 것: 모달 레시피(Q121 뒤) — SKILL.md 문서 공백 — 자식 받기 관용구(`props.Children: Slot`)·모달 레시피·진입점·`:Set` dedup/`:Emit` 뜻·Modifier 팩토리 반환 타입이 없어 스킬만 읽은 에이전트가 `docs/`를 더 봐야 함(공백 여덟) | LOW | |
| Q129 | 남은 것: 실기기 재확인(잠정 닫힘) — 계속 발화하는 긴 수명 상류 위의 Debounce/Throttle 게이트는 호스트 파괴 뒤에도 상류가 조용해질 때까지 살아 창 처리를 되풀이(GC 잔여 비결정 — 57/163/1000) | LOW~MED | |
| Q137 | 남은 것: ④ `Quad0123` 문구(묶음 9) — Modifier 합성의 문서 미정 칸 넷 — 타입드 생성자가 형제 클래스 Modifier를 검사 없이 재태그(`D.Modifier.Frame(D.Modifier.TextButton{…})` → `Modifier<Frame>`, strict 통과 — 무검사 경로 넷째),… | LOW | |

## §1 원칙 감사 결과

(감사 진행 중 — `audit/round14-principle-audit/`)

## §2 재검토

## §4 새 문항
