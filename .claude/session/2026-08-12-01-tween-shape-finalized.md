<!-- quad-v2 세션 로그 원문 — CLAUDE.md에서 이전됨(2026-08-11 정리 세션에서 확립된 관례를 따름). -->
<!-- 이 파일은 quadnomicon 개발로그 소재용 원자료로, 당시 시행착오(정정 전 서술 포함)를 그대로 보존함. -->
<!-- 현재 유효한 설계는 이 파일이 아니라 base//research//archive/가 최종 소스 — 이 파일 안의 판단이 이후 세션에서 뒤집혔을 수 있음. -->

## 2026-08-12 세션 — Tween 옵션 값 모양+override 정책 전면 확정, `research/tween-plan.md`의 마지막 열린 항목 대부분 마감

2026-08-10 세션에서 구조(값-레벨 `Tween<T>` 래퍼)까지만 확정되고 옵션
값 모양/override 정책 이름/`Animate` 시그니처가 열려있던 `research/
tween-plan.md`를 사용자가 직접 구체안을 들고 와서 마감. 사용자가 5개
결정을 한 번에 제안했고, 각각 검증 후 전부 동의로 확정됨.

**1. 옵션 값 모양 — `Info: TweenInfo?` 우선, 없으면 편의 필드 폴백.**
이미 만든 `TweenInfo`를 재사용하고 싶은 경우(비용 절감)와 매번 값이
바뀌는 인라인 케이스(개별 필드가 편함) 둘 다 지원. 편의 필드
(`Time`/`Style`/`Direction`/`RepeatCount`/`Reverses`/`DelayTime`)의
기본값은 로블록스 `TweenInfo.new()` 자신의 기본값(`Time=1`,
`Style=Quad`, `Direction=Out`, ...)과 우연히 정확히 일치한다는 걸
확인 — 별도 기본값 상수 정의 불필요, 그냥 로블록스 기본값을 그대로
물려받으면 됨.

**2. Tween 옵션 필드는 전부 plain 값만, `State<T>` 안 받음.** `Value`에
이미 적용됐던 "같은 일 하는 두 번째 경로를 만들지 않는다" 원칙을
`Time`/`Style` 등 나머지 필드로 확장 — 동적으로 바꾸고 싶으면 바깥
`:Compute`가 `Tween{...}` 테이블 자체를 새로 만들면 됨. 이 논의 중
"Blocker로 감싼 State를 옵션 필드로 읽다가 블록 중이면 어떻게 되는가"
(대안: Blocker가 블록 중 `:Get()`을 에러내게 만드는 안)이 사용자로부터
나왔으나, `base/blocker-plan.md`가 이미 "`Blocker`는 emit 전파만
지연시키고 `:Get()`엔 전혀 영향 없음"을 크로스컷팅 원칙으로 확정해뒀다는
걸 다시 확인하고 기각 — Get()이 항상 라이브 값을 준다는 보장을 Tween
하나 때문에 깰 이유 없음, 애초에 이번 결정(옵션 필드가 State를 안
받음)으로 이 문제 자체가 Tween 범위에선 무관해짐. **문서화 가치 있는
포인트로 남김**: Blocker는 emit만 막지 Get을 막지 않으므로, 블록 도중
어디서든 Get해도 항상 최신으로 재계산된 값을 받는다 — 이 안전성이
바로 Blocker가 다른 데서도 마음 놓고 조합 가능한 이유.

**3. 릴레이션 슬롯 3번째 상태를 `TweenBase` 하나에서 `{Tween, Value}`
테이블로 확장.** override 옵션에 `Finish`(트윈을 목표값으로 스냅 후
재시작)가 추가되려면 그 목표값을 알아야 하는데, 로블록스 `TweenBase`가
자신의 목표 PropertyTable을 역으로 노출하는 공식 API가 없음(`:Cancel()`이
값을 안 되돌리는 것과 같은 이유) — 그래서 세팅 시점의 `Value`를 릴레이션
슬롯에 같이 저장해야 한다는 걸 사용자가 직접 짚음. `Value`는 로블록스
프로퍼티에 쓰이는 lerp 가능한 원시값이라 테이블 aliasing 걱정 없이 그대로
저장해도 안전하다는 것도 사용자가 확인.

**4. override 정책을 4가지에서 `Tween.Cancel`(기본)/`Tween.Finish` 2가지로
압축.** 사용자가 "로블록스 Tween 객체가 `:Cancel()` 말고 없다"는 API
현실을 근거로 제안 — 다시 보니 기존 "오버라이드"(트윈 재사용)와 "삭제 후
재시작"은 `TweenBase`가 애초에 진행 중인 트윈의 목표를 바꿔치기할 API가
없어서(재사용 불가, 매번 새 Tween 인스턴스) 관찰 가능한 결과가 "현재
보간값에서 새로 시작"으로 Cancel과 완전히 동일했다는 게 드러남 — 4개 중
실질적으로 구별되는 건 "현재값에서 이어감(Cancel)" vs "목표값으로 점프 후
재시작(Finish)" 두 가지뿐. 필드 이름은 기존 문서가 계속 써온 "override
정책" 용어를 살려 `Override`로 확정.

**5. `initValue`는 사용자가 직접 처리하기로 확정, 에이전트 범위에서
제외.** 이유는 사용자가 직접 설명: Tween 정보가 부족한 에이전트가
`hasBeenSet` 억제 동작과의 상충을 판단하기엔 미묘하고, 반대로 Tween
자체는 다른 base 요소와 깊게 안 얽혀 있어(`Handlers/Property.luau` 한
파일 + 릴레이션 슬롯에 거의 다 들어있음) 사용자가 직접 처리하는 데
범위상 문제가 없음. Property setter handler 쪽 리팩터 방향(`k=string,
v=isTween(realv)` 분기를 PropertyHandler가 잡고, 실제 트윈 로직은 별도
파일로 캡처)도 언급 — 기존 "패키지 경계" 절 방향과 일치함을 확인만 함.

**`Animate` 콤비네이터 시그니처는 의도적으로 다음 세션으로 연기** —
사용자가 "단순 Tween을 돕는, `Slot:List` 같은 슈거에 가깝다"고 직접
분류, 급하지 않은 후속 논의로 명시적으로 미룸.

**반영된 파일**: `research/tween-plan.md`(전면 갱신 — 3-상태 저장 절의
릴레이션 슬롯 값 모양, override 정책, 옵션 값 모양, `initValue`/`Animate`
절 전부), `.claude/README.md`(`tween-plan.md` 행 갱신, 우선순위 "중"→"하"),
`.claude/question.md`(트윈 요약 행 갱신).

**여전히 열려있는 것**(다음 세션 이후, 급하지 않음): `Animate` 콤비네이터
정확한 시그니처(조건/옵션 분리 vs 통합), 자연 완료(Completed) 시
per-instance 북키핑 정리 여부(`research/pre-implementation-audit.md`
2-10번). `initValue`는 질문 목록에서 완전히 빠짐 — 필요해지면 사용자가
직접.

**다음 세션이 할 일**: 안 바뀜(`ROADMAP.md` M0부터, `.claude/luau-test/`
결과 확인 우선) — 이번 세션도 순수 설계 확정이라 M0 착수 우선순위 자체는
그대로.
