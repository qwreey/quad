# M2 자율 구현 규약 — 11라운드 지시서

> **이 파일이 무엇인가**: **[2026-08-28 신설]** M2(반응형 코어) 구현을 자율 구간으로
> 돌리기 위한 규약이자, 단위가 끝날 때마다 띄우는 **11라운드 탐사자**에게 그대로
> 주는 지시서다. 산출물은 `pre-implementation-handtrace-round11.md`(발견 원문 +
> §4 배치 문항지). 9·10라운드 지시서(`-round9-brief.md`/`-round10-brief.md`)와
> 같은 관례이되, **이번 라운드는 종이가 아니라 실제 코드가 감사 도구다** —
> 10라운드 지시서가 *"이후로는 M2 구현 자체가 더 나은 감사 도구"*라고 예고한
> 그 자리.
>
> **왜 이 규약인가**: 사용자 결정(2026-08-28) — 별도 에이전트가 초안한
> 규약을 검토해 순서 오류 하나(`EpochMap`이 `Source/State` 뒤에 가 있던 것)와
> 소스 단일화 몇 건을 고친 뒤 채택. 사용자 원문: *"수정하고 너가 진행하자.
> epochmap 순서 하나 고치고 진행할 수 있겠니?"* 원칙은 10라운드와 같다 —
> *"인간을 기다리는거 엄청 비효율이라서 … batch 로 처리될 필요가 있는듯"*
> (`-round10-brief.md`). 발견을 하나씩 물으러 오지 말 것.
>
> `conventions.md`의 "작업 방식"에 짧은 항목이 있고 **본문은 이 파일이 소스**다.

---

## §1 범위와 순서

- **단위(unit)** 넷. 단위 하나가 끝날 때마다 §4 "관여 시점"으로 온다.
  1. **공통 기반** — `ROADMAP.md`의 "공통 기반 — 반응형보다 먼저" 절 전부:
     `Brand.luau` / `Relate.luau`(M1에 이미 커밋됨 — 남은 건
     `base/relate-plan.md` 대조 + 테스트) / `LifetimeHandle.luau` 인터페이스 /
     `Ref.luau` 최소형(`H-128`) / `Void`(`H-162`). **여기에 `H-97`의 mock 생명주기
     4종**(`bindLifetime`/`unbindLifetime`/`canBound`/`canExecute`의 mock 백엔드
     구현)을 끼운다 — `ROADMAP.md`엔 M2 꼬리에 있지만 이게 없으면 두 번째 단위부터
     "구현 + 테스트 짝" 원칙이 성립하지 않는다(전파 루프가 매 발화마다
     `canExecute`를 부른다).
  2. **`EpochMap` → `Source`/`State`/`Store`** — **`EpochMap.luau`가 State 본체보다
     먼저다.** `ROADMAP.md` "반응형 본체" 절이 *"`Source.luau`/`State.luau`가 이걸
     전제로 짜여야 하므로 `EpochMap.luau`(위 항목)가 State 본체보다 먼저 온다"*로
     못 박아 뒀다(`State`가 `valueEpochMap`/`emitEpochMap`을 컴포지션). 초안
     규약이 `EpochMap`을 `Effect` 뒤에 뒀던 것이 이 규약이 고친 유일한 순서
     오류다.
  3. **`Observer` → `Effect`** — `Effect`는 Observer 뒤(의존).
  4. **`GateNode` → `Blocker`** + `quad-types`의 `Quad` 탑레벨 값 전부(`H-80`) +
     **mock 대상 전파 루프 테스트**(`ROADMAP.md` M2 마지막 항목).
  단위 안의 순서는 `ROADMAP.md` 체크박스 순서를 따른다.
- **각 모듈은 "`base/` 의사코드를 그대로 옮긴 구현 + 그 절의 계약을 검증하는
  테스트"로 짝지어** 진행한다. 테스트는 **`./scripts/test.sh`로만** 돌린다 —
  `luau` CLI가 심볼릭 링크를 못 타서 그냥 돌리면 거짓 클린이 난다
  (`project-context.md`).
- **코드 배치와 테스트 파일 이름**은 첫 단위 계획(§6)이 정한다 — 이 규약이
  아니라 그 계획이 소스.

## §2 세 갈래 — 발견은 이렇게 분류해서 처리한다

1. **자율로 고치고 넘어가는 것**: `base/` 의사코드를 옮기다 드러나는 오류(순서,
   빠진 `end`, 이름 불일치, 문서 간 stale), 테스트 실패 중 **"문서가 이미 답을 갖고
   있는 것"**.
   → `H-nnn` 번호를 매겨 `pre-implementation-handtrace-round11.md`에 기록하고
   **`base/`와 코드를 같은 커밋에서** 고친다. 묻지 않는다. 번호는 **`H-165`부터**
   (10라운드 후속이 `H-164`까지 썼다).
2. **모아서 올리는 것**: 새 필드·인자·이름·표면·메커니즘이 필요해지는 것, 확정을
   뒤집어야 하는 것, "이 갈래들이 공유하는 전제"가 흔들리는 것.
   → **코드에 넣지 말고** `round11.md` §4 표에 **갈래 + 권고 + 권고 근거**로 쌓는다.
   권고가 "옛 메커니즘 복원"이면 **그 표시를 단다** — 2026-08-28의 `Refresh` 복원
   권고(`H-159`)가 `_rerunRequired`로 뒤집혔듯, 그런 자리는 사용자가 다른 모양을
   갖고 있을 가능성이 높다.
   막힌 부분은 코드에 **`-- TODO(H-nnn): 한 줄 요지`** 마커 + 문항 번호로 남기고
   그 모듈의 나머지를 계속 진행한다. 마커 형식을 이 하나로 고정하는 이유:
   `quad-doc-auditor`는 코드를 안 보므로 `grep -rn "TODO(H-" quad-base/src`가
   잔여를 전수 확인하는 유일한 수단이다.
3. **즉시 멈추고 사용자를 부르는 것**: 2번 중에서 **이미 짠 코드의 상당 부분을
   무효화할 규모**의 전제 흔들림 — 그 위에 코드를 더 쌓으면 손해인 경우만. 멈추고
   상황을 한 문단으로 보고한다(자율 구간이라 사용자가 즉답할 수 없으니, 보고 자체가
   그 세션의 끝이다).

## §3 리뷰·감사 발견의 취급

- `/code-review`와 `quad-doc-auditor`가 **"새 메커니즘"으로 분류한 발견은 반영하지
  말고 2번으로 쌓는다.** 이 코퍼스의 반복 실패 모드(`token`, 전용 에러 문구,
  `wasAlive`)가 정확히 "리뷰 제안을 승인된 것처럼 넣은 것"이었다
  (`conventions.md`의 *"새 필드·인자·이름·메커니즘은 발견이지 결정이 아니다"*
  항목이 소스).
- 반영 전에 (a) 그 책임의 현재 소유자와 (b) 그 모양이 과거에 기각된 적 있는지를
  먼저 grep한다 — `base/`의 "검토 후 안 만들기로 한 것"류 목록과 `archive/`.

## §4 관여 시점

- **커밋 게이트는 두 층이다.**
  - **매 커밋**: `python3 .claude/tools/doc-check.py` ERROR 0. 1번 갈래는 커밋
    단위가 작아 단위 하나에 커밋이 여럿 생기는데, 그 중간 커밋도 이 게이트를 탄다.
  - **단위 끝**: 감사 루프(`quad-doc-auditor` **한 턴에 하나**, diff 범위,
    **`git stash` 금지**를 프롬프트에 직접 명시, 새 발견 0건까지) → doc-check
    ERROR 0 → `/code-review high` → 커밋. 그 뒤 **신선한 컨텍스트의 fable 탐사자
    하나**를 이 파일(§5)을 지시서로 띄워 실제 코드를 돌려보고 `round11.md`에
    발견을 이어 붙이게 한 다음, 사용자에게 **"`round11.md` §4를 보라"고 한
    줄로** 알린다. 사용자는 §4 표만 읽고 갈래를 배치로 회신한다.
- 세션이 일단락될 때마다 `session/YYYY-MM-DD-NN-slug.md` 원문을 남기고,
  `todos.md` 00번·`project-context.md`·`CLAUDE.md` 머리말을 **"M2 진행 중"**으로
  갱신한다(`conventions.md`의 세션 원문 규율 그대로).
- 비용 참고: 단위당 감사 루프 + `/code-review high` + 탐사자 조합은 수십만 토큰이다.
  그래서 단위를 넷으로 쪼갰다 — 관여 시점이 촘촘해지고 3번 갈래의 손실도 작아진다.

## §5 탐사자 지시 (단위 끝마다 띄우는 fable 탐사자에게)

당신은 Roblox 엔진용 DOMless UI 렌더러 **quad**의 M2 구현을 감사한다. 저장소
루트가 작업 디렉토리다. 당신은 신선한 컨텍스트에서 시작한다 — 앞선 세션의 가정을
물려받지 않는 것이 당신의 가치다. **`git stash`를 쓰지 말 것**(작업 트리 대조는
`git show HEAD:<경로>` / `git diff HEAD -- <경로>`).

1. 먼저 읽을 것: `CLAUDE.md` → `.claude/conventions.md`(특히 *"새 필드·인자·이름·
   메커니즘은 발견이지 결정이 아니다"*와 *"하나의 무언가가 두 일을 하고 있지
   않은지"*) → 이 파일 §1~§3 → `pre-implementation-handtrace-round11.md`(지금까지의
   발견, 당신의 번호는 마지막 번호 다음부터).
2. 대상: 이번 단위의 커밋 범위(`git log`로 확인)에 들어온 `quad-base/src/`·
   `quad-base/test/`와, 그 코드가 옮겨 적은 `base/` 절.
3. 할 일: (a) **코드를 실제로 돌린다** — `./scripts/test.sh` 전체, 그리고 계약
   절이 요구하는데 테스트가 없는 경로는 임시 스크립트로 직접 태운다(임시 파일은
   `quad-base/test/`에 남기지 말고 발견 본문에 인라인). (b) 코드와 `base/` 절을
   **한 줄씩 대조**한다 — 옮기다 바뀐 것, 문서에 없는 분기, 문서엔 있는데 코드에
   없는 것. (c) `grep -rn "TODO(H-" quad-base/src`로 남은 마커를 전수 확인한다.
4. 산출물: `round11.md`에 `H-nnn`으로 이어 붙인다. **§2의 세 갈래로 분류해서
   적되, 1번 갈래도 직접 고치지 말고 발견으로만 남긴다**(수정은 메인 세션이
   한다). 2번 갈래는 §4 표에 갈래 + 권고 + 권고 근거, "옛 메커니즘 복원" 표시.
5. 이상 없다고 확인한 자리도 §5 형식으로 적는다(다음 탐사자가 다시 파지 않게).

## §6 첫 단위(공통 기반) 작업 계획 — **[2026-08-28 사용자 확정]** (*"진행하면 될것 같아"*)

소스는 `ROADMAP.md` "공통 기반 — 반응형보다 먼저" 절 + `H-97`. 여기 적힌 배치
결정 셋(브랜드 인스턴스 위치 / mock 생명주기 위치 / 테스트 파일 이름)은 `base/`가
정하지 않은 **코드 배치**라 이 계획이 소스다 — 설계 결정이 아니다.

**소스 (`quad-base/src/`)**

| 파일 | 내용 | 옮겨 적는 절 |
|---|---|---|
| `Brand.luau` | `Brand()` 생성자 + **브랜드 인스턴스 열다섯을 이 잎 파일에**(`brand-plan.md` 스니펫이 한 자리에 선언하는 그대로 — `EpochBrand`를 `Source`/`Ref`/`GateNode`가 공유하므로 타입 모듈마다 두면 순환 require) + M2 타입의 `is*`(`isEpoch`/`isSource`/`isState`/`isStore`/`isObserver`/`isEffect`/`isBlocker`/`isRef`/`isPreRef`/`isPostRef`/`isModifier`). `isTag`/`isAttribute*`/`isTween`/`isSlot`은 그 타입의 마일스톤에서 | `base/brand-plan.md` "구현 — 인스턴스 브랜드" / `isRef` 계층 절 |
| `Relate.luau` | **기존 파일**(M1). 코드 변경 없음 — `base/relate-plan.md` "API"/"실제 구조" 대조 + 테스트만 | `base/relate-plan.md` |
| `LifetimeHandle.luau` | 4종 타입 시그니처 + **미주입 에러 스텁**(영어, `error(…, 2)`) + 공유 술어 `isBoundAlive`는 백엔드 몫이라 여기 없음 | `base/lifecycle-pattern.md` "확정" 절, `module-lifecycle-plan.md` 주입 절 |
| `Ref.luau` | 최소형 — `.Value`/`.Revision`/`:Set`/`:Callback`/`:WeakCallback`/`:Uncallback`, `Callbacks`(강) + `WeakCallbacks`(weak-key), `:Set` 순서 값→리비전(`bit32.bnot(-rev)`)→스냅샷 순회·함수키 dedup·thread 소진, `EpochBrand`+`RefBrand` 등록 | `base/ref-plan.md` "`Ref`는 `Epoch`를 만족한다" 절 + `H-128` |
| `Void.luau` | `return function() end` | `H-162`, `architecture.md` 잎 모듈 |
| `init.luau` | `Relate`/`Void`/`Ref`/`is*`/생명주기 4종 스텁 재export | `H-80` |
| `quad-types/src/init.luau` | `Quad` 타입에 위 탑레벨 값 추가(`Source`/`Store`/`Effect`/`Blocker`는 각 단위에서) | `H-80`/`H-25` |

**mock (`quad-base/test/mock.luau`)** — `H-97` 4종을 **이 파일 안에** `installLifetime(quad)`로
둔다(quad-roblox가 할 모듈 뮤테이션을 그대로 흉내; `Destroying:Connect`의 `Connection`을
`Relate` weak 슬롯 `"gcconn"`에 두고 `.Connected`로 판정, `.Subscribed` 경로는 단위 3에서
합류). 별도 파일을 안 만드는 이유: mock 백엔드가 곧 이 파일 하나다.

**테스트 (`quad-base/test/spec.<module>.luau`)** — `scripts/test.sh`의 glob을
`smoke.*` + `spec.*`로 넓히고, relink 뒤 `luau-analyze quad-base/src`도 같이 돌린다
(relink가 거짓 클린의 원인을 없애므로 analyze가 이제 의미 있다).

| 파일 | 검증하는 계약 |
|---|---|
| `spec.brand.luau` | register/is · 다중 태깅 · 브랜드 간 독립 · weak-key(GC 뒤 사라짐) · `isRef(PreRef 등록값) == true`, `isPreRef`/`isPostRef` 배타 |
| `spec.relate.luau` | 4 메서드 · 서브테이블 lazy 생성 · `WeakMap` 값 GC · `inst` weak-key GC · 공유 메타테이블 |
| `spec.lifetime.luau` | 미주입 스텁이 영어 메시지로 error · 주입 후 `bindLifetime` → `canBound` false/`canExecute` true · `Destroy` → 반대 · `unbindLifetime` 조기 해제 · 이중 바인드 게이트 모양 `if not canBound then error(…, 2)` |
| `spec.ref.luau` | 초기 `Revision` · `:Set` 순서(콜백이 볼 때 이미 새 값·새 리비전) · `bit32` 랩(0 → 4294967295) · `Callback`/`WeakCallback`/`Uncallback` · `fn(value, ref)` · 같은 fn 양쪽 등록 시 1회 · weak 콜백 GC 뒤 침묵 · 발화 중 `Uncallback` 안전(스냅샷) · thread 콜백 1회 소진 · `isRef`/`isEpoch` |
| `spec.void.luau` | 반환값 없음 · 항등(항상 같은 함수) |
| `smoke.init.luau`(갱신) | 탑레벨 값 존재·타입 |

**커밋 단위**: 모듈마다 하나(구현 + spec + `base/` 정정이 있으면 같은 커밋), 마지막에
`test.sh`/`quad-types` 커밋. 단위 끝 절차는 §4.
