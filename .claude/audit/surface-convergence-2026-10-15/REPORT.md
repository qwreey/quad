# 3.3.0 전 공개 표면 수렴 점검 (2026-10-15)

opus 서브에이전트가 읽기 전용으로 쓴 보고를 메인이 저장했다(하네스가 서브에이전트의 파일 쓰기를 막아 본문으로 돌아옴). 범위는 태그 `3.2.0`과
HEAD `752cbc1c` 사이, 판정 기준은 `audit/round14-principle-audit/PRINCIPLES.md`. 줄 번호는 [2026-10-15 기준] 그 HEAD의 줄이다.
**메인 검증**(맨 끝 절)과 처리 결과도 끝에 붙였다.

규모(실측): `[Unreleased]`는 루트 `CHANGELOG.md` 7~172행, BREAKING 표기 31. `git log 3.2.0..HEAD` 459커밋(문서·킷 포함), 다섯 패키지 소스 diff 59파일 +5368/−2529.

## 1. `[Unreleased]` 사실 대조

맞는 것(실측): 인용한 에러 식별자 38개 전부 raise 자리와 `docs/reference/errors/` 절이 있음(소스에 없는 것은 "폐기" 표시된 `Quad0262` 하나), 인용 메시지 조각 18개
전부 소스에 있음, `scripts/error-codes.py check` 261 id·257 자리·미태그 0. 타입 쪽 BREAKING 줄은 `quad-types/src/init.luau`의 3.2.0 대비 diff와 하나하나 맞음
(`EffectHandle`→`Effect`, `blocker.Blocking`, Brand `:Register`/`:Is`, `Provider` 불변, `read` 필드, `OwnsElements`, `updateFn(ctx)`, `Length`/`Offset` State, Tag `__iter`,
`q.Backend`/`q.Bookkeeping`, `Protocols`, `moduleIdentity`, Store `__` 예약). `VERSION_PATTERN`, Event/OnChange 우선순위, `StateHandler`, 109행 Operator, 161행 Debounce도 맞음.

틀렸거나 낡은 줄:

- **1-1. 101행 — 범용 패키지 둘의 버전 줄이 뒤집힌 결정을 적음.** "같은 번호를 쓰지 않고 첫 독립 릴리즈가 4.0.0, `^4.0.0`으로 옮기세요" — 2026-10-12 사용자 결정
  (`qa-request/post-implementation-review-round14.md:256`)으로 둘은 4.0.0 전까지 lockstep이고 도구도 그대로 돈다(`scripts/check-version.py` 4~10행, 두 폴더 CHANGELOG 머리).
  3.3.0 bump는 다섯을 모두 3.3.0으로 올리므로 이 줄은 없는 4.0.0으로 옮기라고 시킨다. `a4ceb4e9`(09-15)에서 들어와 10-12 결정 때 안 고쳐짐(`git log -S`).
- **1-2. 139행과 53행 (4) — `Quad0220` 정적 자식 순환 가드.** 3.2.0 트리에는 이 검사가 없고(09-17 `3348a68d`가 평소 경로로 넣음 → 10-01 debug로 내림), 3.2.0 대비 순효과는
  "debug 끄면 3.2.0과 같음(엔진의 순환 에러), 켜면 새로 `Quad0220`". 139행은 무조건 거부로, 53행은 "매번 돌던 검사를 내렸다"로 적어 둘 다 틀림. 같은 오류가 `docs/reference/core/01-quad-module.md:201`.
- **1-3. 143행과 53행 (2) — `Quad0143` `:List` 데이터 키.** 3.2.0 `List.luau`에는 키 검사가 없었다. 순효과는 "배열 부분이 빈 딕셔너리는 늘 `Quad0143`(새로), 배열에 키가 덧붙은 것은
  debug에서만". 143행은 덧붙은 키까지 늘 거부한다고, 53행은 있던 검사를 내린 것처럼 적음. 53행 (1) `Quad0083`·(3) `Quad0173`은 3.2.0에 실제로 늘 돌던 검사라 맞음.
  1-2와 같은 뿌리 — 한 라운드가 Fixed로 넣고 다음 라운드가 debug로 내리며 두 줄을 합치지 않음.
- **1-4. 113행과 158행 — 마운트 창 안의 조상 Slot CRUD 거부.** 3.2.0엔 가드 자체가 없었다(`_materializing` 0건; 09-17 `e5a90c77` 부모만 → 10-01 `644dfbd1` 사슬 전체).
  3.2.0 기준으로는 "가드 없음 → 사슬 전체를 `Quad0167`로 + 창 안에서 던지면 사슬 동결" 한 줄. 113행의 "전에는 바로 위 부모만"은 게시된 적 없는 상태. 옮기는 법도 `task.defer`가 아니라
  15행의 `slot:WhenIdle`이어야 함(43행과 `Quad0167` 메시지는 `WhenIdle`을 안내). 같은 서술이 `docs/reference/errors/03-slot.md:235`.
- **1-5. 126행 — Tween 힌트.** 39행의 `q.Protocols.DispatchHint` 결정 뒤 Tween은 문자 키에서 "this key may not be a field of this element…"를 낸다(`quad-roblox/src/Tween.luau:156-160`).
- **1-6. 74행 — 한 항목 안에서 앞뒤가 부정.** 괄호 안 "BREAKING(타입만)"과 끝의 "기존 코드는 그대로 통과". strict 실행은 미완. BREAKING 표시가 항목 머리에 없음.
- **1-7. 작은 것.** 108행 "(아래 개명)"은 "위". BREAKING이 Added(26행)·Fixed(162행)에 섞임, 제거된 것이 Removed 없이 Changed에. 109·26행 옮기는 법 없음. 중복 두 쌍(57·146, 131·144 — 모순 아님).

미완: 줄 전수 실행 대조, strict(96·74행)·런타임(59·125행) 주장 실행, `test.sh`.

## 2. 빠진 줄

방법: 진입·타입 파일 diff 전부, 주요 모듈 20여 개 코드 줄 diff, 문서의 "다음 릴리즈부터" 37자리 대응(전부 있음). 아예 없는 것은 거의 없다.

- **2-1.** `type_version_check`의 BREAKING(패턴 문법 `|`·`N^`, 꼬리 없는 패턴이 rc를 더 받지 않음)이 그 폴더 CHANGELOG에만 있다. 3.3.0에서 같이 게시되고 `CheckedQuad`·`VERSION_PATTERN`이
  이 문법을 쓰니 루트에 포인터 한 줄. `quad_error`는 해당 없음.
- **2-2.** 새 export 타입 이름(`Bookkeeping`, `Backend`, `TagIter`, `OutFn`, `TweenCallback`, `TweenCallbacks`, `TweenCallbackHandle`) — 값 표면은 이미 있음, 적을지는 판단.
- **2-3.** 릴리즈 때 문서의 "다음 릴리즈부터" 37자리를 "3.3.0부터"로(`HUMAN_TODO.md` 84행), 1-2~1-4의 레퍼런스 두 자리.

## 3. 앞으로 BREAKING을 낼 수 있는 열린 결정

닫힌 것 확인(실측): `research/public-surface-pre-adoption-review.md` 전부 닫힘, round14 §0 23문항·Q160~Q187 닫힘, `research/upward-flow-plan.md` 구현됨,
`research/drive-hook-plan.md`는 "표면 무변경" 백로그, `question.md` 열린 항목은 추가·무관, 소스 `TODO` 0.

- **3-1. 생성 Declaration 표면 재검토와 이번에 처음 게시하는 클래스 타입 109개.** `research/declaration-surface-plan.md`(09-30, 결정 없음)가 클래스별 복제를 생성기 문제로 보고
  타입 함수 조립을 다시 열었고 그 4절이 "기존 재수출의 운명(BREAKING 허용 여부)"을 정할 것으로 둔다. `[Unreleased]` 29행이 바로 그 재수출(`quad-roblox/src/init.luau` GENERATED 블록)을
  처음 게시한다. 묶여 보류된 round13 Q122 (a)·Q127 (a)·Q87 (a)도 결정되면 타입 BREAKING. bump 전에 "그대로 / 잠정 표시 / 빼기"를 정할 것(추론).
- **3-2. Tween 콜백 — 사용자가 "잠정"이라 한 표면이 Added에 있음.** `research/tween-callback-structure.md` 머리(09-29 사용자 *"잠정 변경이 있어서 나중에 더 파봐야할 표면"*). 16·17·112행.
  발화 계약은 바뀌어도 타입 에러 없이 동작만 달라진다. bump 전에 게시 여부·잠정 표기를(추론).
- **3-3. 에러 일관성 패스(P5)와 식별자 계약.** 18행은 "번호는 바뀌지 않으니 분기는 번호로". 그러나 미룬 P5(`qa-request/round14-reflection-plan.md:14`, Q170 (4))는 같은 실수를 어느 에러로
  알리나를 맞추는 패스이고 번호가 갈린 묶음이 있다(`0020`/`0158`/`0162`, `0018`/`0043`/`0123`). 게시 뒤 조건↔번호 대응이 바뀌면 번호로 분기한 코드가 조용히 다른 갈래로 간다.
  (가) 번호 대응을 바꾸는 부분만 먼저, (나) 18행을 "어떤 실수가 어느 번호로 보고되는지는 4.0.0 전까지 다듬어질 수 있다"로 좁힘(추론).
- **3-4. `Slot:List` 전체 교체 O(N²)(round13 Q76 보류).** 처방이 `updateFn` 호출 순서를 바꾸는데 `docs/reference/core/06-slot.md:433`이 그 순서를 계약처럼 적음. 미뤄도 되나,
  그 문장을 지금 "순서는 정하지 않는다"로 완화하면 나중 처방이 BREAKING이 아니게 됨 — 사용자 결정.
- **3-5. 성능 Studio 회차**(`research/perf-measurement-plan.md`) — 4.0.0 기준, 미뤄도 됨(3.3.0을 "수렴한 판"으로 소개하지 않는 전제).
- **3-6. 렌더 스텝 op** — 상시 경로 op면 프로바이더 작성자에게 BREAKING, 미설치 스텁이면 추가. 미뤄도 됨.
- **3-7. flatten 슈거** — 대부분 추가, `docs/reference/extend/02-dispatch-handler-contract.md`의 drive 순서 문장만 작은 Changed. 미뤄도 됨.
- **3-8. 그 밖** — 추가가 대부분. 타입드 `Indexed`(시그니처), 에러 컨텍스트 래핑(`research/deferred-hardening-plan.md` 2절 — 18행 "식별자가 맨 앞"과 충돌)은 착수 계획 없음.

## 4. 종합 의견(opus)

3.x는 4.0.0까지 BREAKING 허용이라 "수렴"은 (가) CHANGELOG가 3.2.0→HEAD를 정확히 말하는가, (나) 뒤집힐 것으로 알려진 표면을 처음 내보내는가. (가)는 지금 그대로는 내지 않는 게 좋다
(1-1·1-2·1-3·1-4·1-5 — 전부 문서 수정). (나)는 3-1·3-2·3-3을 bump 전에 정하는 게 좋다 — 셋 다 이번에 처음 게시하는 표면이라 게시 전엔 바꾸는 비용이 0. 의견: 3-1·3-2는 "잠정 표시해 낸다"
(킷과 table-sim이 이미 HEAD 해시로 쓰고 있어 빼는 쪽이 비쌈), 3-3은 18행을 좁힘. 3-4~3-8은 뒤로. 미루는 비용: BREAKING 31, 문서와 게시본 사이 37자리, table-sim은 커밋 해시 고정.

## 메인 검증 (2026-10-15)

1-1(10-12 결정과 대조), 1-2(3.2.0 트리의 "inside itself"는 Slot 쪽 하나뿐, `InstanceChild.luau`의 `Quad0220`은 debug 전용), 1-3(3.2.0 `List.luau`는 `typeof` 검사뿐, HEAD 152행은 키 전수가
`module.debug` 안), 1-4(3.2.0에 `_materializing` 0건), 1-5(`Tween.luau` `__dispatchHint`)를 직접 확인 — 전부 맞음. 처리: 1절·2-1은 `[Unreleased]`가 아직 게시 전이라 사실 정정으로 바로 고침
(같은 날 커밋), 3-1·3-2·3-3·3-4는 사용자 문항.
