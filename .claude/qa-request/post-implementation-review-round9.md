# 구현 뒤 리뷰 round9 — 슈거 구간(Debounce/Throttle · 생명주기 훅 · Fallback) 리뷰·감사 (2026-09-08 밤)

> **입력**: 2026-09-08 밤 슈거 구현(`session/2026-09-08-04-sugar-implementation.md`)의 미커밋 diff. 절차는 conventions의
> 단위 끝 루틴 — opus 단일 맥락 코드 리뷰 1회(서브에이전트 없음, 발견은 평문, 마지막 메시지 하나) + `quad-doc-auditor`(sonnet)
> 1패스(diff 범위). 발견은 전부 메인이 코드·스펙으로 검증한 뒤 반영했다. 발견 번호 `H-509`~`H-516`. 판정: test.sh exit 0(스펙 54),
> doc-check ERROR 0.

## §1 결론 한 줄

HIGH 없음. 리뷰가 정본 손 트레이스 여섯(기본 Debounce·1-1절 Throttle 시나리오·Leading/Trailing=false 버스트·MaxTime 연속·idle
Flush·Cancel 뒤 신호·flush 중 재진입)을 전부 통과시켰고 창 이중 개방·타이머 누수·보류분 유실은 없었다. MED 셋 중 둘은 반영
(`H-509` 상태 변경 순서, `H-512` gate-plan 옛 문장), 하나는 증상 확정·처방 미정으로 문항(Handle 덮어쓰기). 감사자는 배너가
부정하는 옛 "맨 뒤·백로그" 문장 다섯을 잡았다(전부 반영).

## §2 반영한 것

- **`H-509` (MED) `openWindow`가 던질 수 있는 읽기 앞에서 Blocker를 켰다.** `b:On()` 뒤에 `readTime`·`setTimeout`이 오므로 `Time`
  State가 숫자가 아니거나 백엔드가 미주입이면 Blocker는 On인데 창도 타이머도 없는 상태가 남아 보류분이 갇히고 leading이 한 번
  사라졌다(리뷰 실측). `H-392`/`H-445` 선례대로 읽기·스케줄을 먼저 하고 상태 변경은 뒤로. spec.debounce 7b절이 회귀 가드.
- **`H-510` (LOW) `held`가 사실을 서술하지 않았다.** idle 분기에서 `leading`이면 무조건 "통과"로 두었는데, 타이머 경로 커밋 중
  재진입한 신호는 창이 없어도 Blocker가 On이라 보류된다 — 그러면 MaxTime 캡이 안 걸렸다. 진입 시점의 `b:IsOn()`으로 유도.
- **`H-511` (LOW) 명목 `Timeout`이 타입 단계에서 강제되지 않았다.** 두 백엔드의 `setTimeout` 반환 타입이 `any`라 정본 6절이 마커
  타입을 택한 유일한 근거(`clearTimeout(1)`을 타입 에러로)가 실현되지 않았다. 반환 타입을 `QuadTypes.Timeout`으로.
- **`H-512` (MED) `gate-plan.md` 5번의 두 문장이 구현과 반대였다.** *"`pending` 같은 정책 상태는 `HasBlockedEmit`으로 흡수한다"*
  (`H-86`이 뒤집은 통로 — 같은 항목의 `H-118` 배너가 형제 문장만 고쳤다)와 *"`Trailing = false`는 `OffWithoutEmit()`, `Flush`는
  `Off()`로 매핑된다"*(구현은 `emit(false)` 뒤 idle / `emit()` 직접 — `OffWithoutEmit`은 집합을 안 비우고 `Off()`는 반환값을 못
  준다). 취소선 + 정정.
- **`H-513` (LOW) GC 상한이 한 창 짧게 적혀 있었다.** 통과가 창을 다시 열므로 마지막 신호 뒤 실제 상한은 `2 × Time`(헤더·정본
  8절). 그리고 사용자가 쥔 `Handle` Ref가 게이트를 고정한다는 사실이 어디에도 없었다 — 헤더·5-4절에 한 줄.
- **`H-514` (LOW) mock 헤더가 실측과 반대를 적었다.** "Roblox `task.cancel`은 dead thread에 에러"라고 썼는데 같은 diff의
  EngineOps 주석·`audit/sugar-studio-2026-09-08.md`는 무해한 no-op으로 실측. 문장 정정.
- **`H-515` (LOW) 스펙 구멍 둘 + 제목 하나.** 배너 (4) *"Flush는 Trailing과 무관"*을 지키는 스펙이 없었고(7b절 신설), 헤더의 중심
  주장인 타이머 경로 재진입("보류되고 창은 하나")은 10절이 idle 경로만 봤다(10b절 신설). spec.hooks 4절 제목이 없는
  `Unsubscribe`를 말했다(제목 정정).
- **`H-516` (LOW) 정본·색인의 옛 표기.** `debounce-throttle-plan.md` 5-4절 괄호 *"팩토리 호출 시에 h가 채워짐"*은 틀렸다(`:Apply`
  시점 — 스펙 7절 "empty before Apply"). `base/README.md` `debounce-throttle-plan.md` 행이 `Timeout`을 옛 `__type_timeout`으로
  서술 — 옛 표기임을 명시. `Debounce.luau` 헤더 불변식 *"Blocker는 창이 열려 있는 동안에만 On"*은 한 방향만 참(커밋 구간엔
  창 없이 On) — 문장 정정.
- **감사자 다섯 건(문서).** `fallback-plan.md`·`lifecycle-hooks-plan.md`의 머리 배너 바로 아래 *"구현 우선순위는 여전히 맨 뒤"*와
  두 문서의 "우선순위" 절, `debounce-throttle-plan.md` 13절, `base/README.md` `fallback-plan.md` 행 꼬리, `todos.md` 4번 — 전부
  취소선/배너로 "착수 전 서술"임을 명시.

## §3 확인만 한 것 (코드 변경 없음 — 재발견 금지)

- 에러 blame 레벨은 형제와 일관(생성자 게이트 Nearest·`readTime` outermost·`__apply` 게이트는 직접 호출로만 닿으므로 Nearest가
  맞다 — outermost로 바꾸면 틀려진다).
- `LifecycleHooks.luau`·`Fallback.luau`는 정본 스케치 그대로, 어긋난 곳 없음. `question.md` 0절의 인용은 코드와 일치.
- 리뷰 미완: quad-roblox 타입(`luau-lsp` 플래그 넷)과 `spec.robloxfactory` 실행은 리뷰어 사본에서 못 돌렸다 — 메인의 test.sh가
  둘 다 덮는다(exit 0).

## §4 사용자 문항 (평문 한 문단 — `question.md` 0절 (h)~(j))

**(h) 커밋 중 하류가 `Cancel`을 부르면 한 줄 뒤에 창이 다시 열린다.** 창 끝 커밋은 `emit()`으로 flush한 뒤 "재진입이 창을 안
열었고 통과분이 있었으면" 창을 다시 여는데, 그 flush 도중 하류 Observer가 `handle:Cancel()`을 부르면 Cancel이 타이머를 정리하고
Blocker를 끈 직후 상위 커밋이 그 사실을 모르고 창을 다시 연다(재진입 `Flush`도 같은 모양). 발산하지 않고 다음 창 끝에 빈 집합으로
idle이 되지만 5-4절의 "Cancel은 타이머를 정리한다"와 어긋난다. 갈래는 (1) 핸들 테이블에 세대 카운터 같은 필드를 하나 두어 커밋이
자기 flush 중 Cancel/Flush를 감지하게 하기(새 필드) / (2) "flush 콜백 안에서 같은 게이트의 핸들을 부르는 것"을 UB로 명문화. 권고는
(2) — 실사용 사례가 없고 원칙(관측된 문제에만 구조)에 맞다.

**(i) 재진입 leading 통과가 "창 하나당 최대 한 번"을 깬다.** idle 상태에서 leading으로 통과시키는 도중 하류가 상류를 `:Set`하면
아직 창이 안 열려 두 번째 신호도 창 밖으로 판정돼 같은 파동에서 또 통과한다(스펙 10절이 `count == 2`로 고정). 정본 7절 의사코드도
`passThrough()`가 `openWindow()` 앞이라 같은 형태이고, 1-1절 표는 Throttle을 "창 하나당 최대 한 번"이라 한다. 갈래는 (1) 지금
그대로(의사코드 그대로, 스펙이 계약) / (2) 창(타이머)을 먼저 열고 leading 통과 뒤 `b:On()` — 표면 변경 없는 정책 변경. 권고는 (1).

**(j) 하나의 `Handle` Ref로 팩토리를 두 번 `:Apply`하면 첫 게이트의 핸들이 조용히 사라진다.** 5-1절은 팩토리 재사용을 권장하고
5-4절은 `Handle`이 "특정 `:Apply()` 호출 하나"를 겨냥한다고 하는데, `Handle`이 팩토리 옵션에 살아 두 번째 `:Apply`가 같은 Ref를
덮어쓴다(리뷰 실측 — 첫 게이트는 브로드캐스트로만 닿는다). 증상 확정, 처방 미정: (1) 두 번째 `:Apply`에서 `Handle.Value ~= nil`이면
에러(`ref-plan.md`의 이중 배치 가드와 같은 결) / (2) 문서로만 / (3) 그대로. 권고는 (1).

## §5 교훈

- 상태 변경과 "던질 수 있는 읽기"의 순서는 새 코드에서도 반복된다(`H-392`·`H-445`·`H-509` 세 번째) — 정책 코드를 쓸 때 첫 체크.
- 헤더의 불변식 문장은 리뷰어가 코드로 반증한다 — "정확히 ~일 때만" 같은 양방향 주장은 한 방향만 참인지 먼저 볼 것.
