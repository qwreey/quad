# quad vs Fusion/Vide/react-lua — 정직한 비교 (2026-08-06)

**상태**: research — 3개 에이전트가 각각 Fusion(`.claude/initreq/fusion` 실
소스), Vide(`.claude/initreq/vide` 실 소스), react-lua(로컬 클론 없어
웹 리서치)를 직접 읽고 quad의 확정 설계와 대조. 목적은 마케팅이 아니라
정직한 자가점검 — "quad가 진짜 나은 부분"(나중에 초심자/quadnomicon 문서의
"왜 quad인가" 소재)과 "quad가 진짜 불리한 부분, 그중 고칠 수 있는 것"을
사용자가 직접 검토하기 위함. **quad는 구현 0줄** 상태라 모든 비교가
"검증된 프로덕션 코드 vs 종이 설계"라는 근본적 비대칭을 안고 있음 — 아래
모든 강점/약점은 이 전제하에 읽을 것.

## 1. quad가 실제로 나은 점 (소스 근거 있음, 향후 "왜 quad인가" 문서 소재)

- **Slot 단일 마운트 가드 — Fusion·Vide 둘 다 없음, 실재하는 버그 클래스를 막음.**
  Fusion `Children.luau`엔 `-- TODO: check for ancestry conflicts here`
  주석이 그대로 남아있고 이미 마운트된 인스턴스를 조건 없이 재부모화함(조용한
  이중 마운트). Vide `mount.luau`도 중복 마운트 체크가 전혀 없음. quad의
  "이미 마운트된 Slot 재마운트 시 즉시 throw"는 둘 다에 없는 실질적 안전장치.
- **열린 우선순위 축 — Fusion의 하드코딩된 4단계보다 확장성 좋음.** Fusion
  `applyInstanceProps.luau`는 `{self, descendants, ancestor, observer}`
  정확히 4개 버킷만 갖고 5번째를 쓰면 에러남. quad의 열린 숫자 우선순위
  레지스트리는 커스텀 bind key를 라이브러리 수정 없이 임의 우선순위에
  끼워넣을 수 있음.
- **명시적 의존성이 여러 버그 클래스를 원천 차단.** Vide는 전역 `scopes`
  스택 기반 암묵 추적이라 리액티브 스코프 안 yield가 그래프를 깨는 걸 막기
  위해 별도 `ycall` 장치까지 둠(`graph.luau`). quad의 명시적 `:With`
  의존성 전달은 이 버그 클래스 자체가 발생하지 않음.
- **다이아몬드 의존성 재계산 dedup — Vide가 스스로 미해결로 남긴 문제를
  더 구조적으로 해결.** Vide `todo.md`가 diamond 그래프 중복 재평가 방지를
  미해결로 인정했고, 실제로 `test/tests.luau`의 "recursive queue flush
  diamond" 테스트가 이상적 2회 대신 3회 실행됨을 재현함. quad의 `invalid`
  플래그 dedup은 이걸 원시 레벨에서 막도록 설계됨.
- **fine-grained라 vdom 특유의 버그 클래스가 통째로 없음(vs react-lua).**
  react-lua는 리스트 diffing을 위해 key 관리가 필요하고(불안정하면 자식
  상태 유실), hooks 호출 순서 규칙이 있으며(위반 시 "Rendered fewer/more
  hooks" 에러), 고빈도 갱신엔 리렌더를 우회하는 별도 API(`Bindings`)를
  공식적으로 추가해야 했음(react-lua 스스로 "vdom 재조정만으론 부족하다"고
  인정한 셈). quad는 모든 값이 동일한 push-invalidate/pull-recompute
  모델이라 이 세 문제 자체가 없음.
- **Tween을 그래프 밖에 둬서 구조적 복잡도를 회피.** Fusion `Animation/
  Tween.luau`는 `Stopwatch`+`ExternalTime` 그래프 노드와
  `checkLifetime.bOutlivesA` 교차 lifetime 검증까지 필요한 3중 장치.
  quad엔 이 장치 자체가 없음(단, 반대급부는 아래 3번 참고).

## 2. quad가 불리한 점 중 — 고칠 만한 것(fixable, 검토 가치 있음)

- ~~Store dot-access가 매 접근마다 새 State를 할당~~ — **[해소됨,
  2026-08-06 세 번째 세션]** 이 항목이 직접 트리거가 되어 Source/State
  관계 자체를 재구성(`store-semantics.md` "Source가 State를 만족함" 절) —
  Store가 이제 생성 시 만들어둔 Source를 그대로 반환해 wrapper 할당 자체가
  없어짐, 구현 단계 최적화가 아니라 설계로 완전히 없앰(캐싱/풀링보다도 쌈).

## 3. quad가 불리한 점 중 — 못 고치는 것(의도된 트레이드오프, "고친다" 개념 자체가 안 맞음)

- **[2026-08-12 열여덟 번째 세션, 사용자 최종 판단 — 원래 2번(fixable)에
  있었으나 여기로 이전. 같은 날 후속 세션(스무 번째)에서 근거 보강]**
  use-after-destroy 검증 안전망 부재. Fusion `Memory/checkLifetime.luau`류
  사전 검증을 quad가 일반적으로 흡수하는 건 애초에 실행 불가능에 가까움 —
  제대로 하려면 (a) 등록된 모든 함수/클로저를 추적해 `inst` 사용을
  전부 조사하거나 (b) `inst` 자체를 래핑해 이후의 모든 읽기/쓰기를
  가로채야 하는데, 이건 quad가 손댈 수 있는 범위를 벗어나는 Instance
  가상화/추적 문제 — 정확히 이 목적으로 존재하는 rbvm 같은 전문
  Instance-래퍼 라이브러리의 영역. quad가 이걸 재발명하면 그 자체로
  중복·오버엔지니어링이고, 이 수준의 디버깅이 필요하면 quad-debug가
  rbvm 같은 도구를 병행하도록 안내하는 게 맞는 방향(quad 혼자서 모든
  `inst` 사용을 추적하는 건 못 함).
  또한 **quad-debug 자신의 스코프도 이 문제와 안 겹침** — quad-debug는
  quad-base/quad-roblox가 스스로 만들어낸 효과(Store/Dispatch/handler가
  뭘 왜 세팅했는지)를 설명하는 도구이고, `research/debug-tooling-plan.md`
  "외부 변경 감지" 절이 이미 "Ref로 얻은 raw Instance에 대한 직접 조작은
  애초에 `process()`를 거치지 않아 quad-debug의 계측 지점으로 절대 안
  잡힌다"고 명시해뒀음 — 외부에서 뭘 하는지는 원래부터 관심사가 아님.
  실제로 use-after-destroy가 발생할 수 있는 자리는 딱 하나로 좁혀짐 —
  quad가 케어 안 하기로 이미 확정한 `Ref`가 의도된 스코프를 벗어나
  외부로 반출/장기 보관되는 경우. 이건 이미 권장하지 않는 사용 패턴이고,
  Ref의 관례(React `useRef`와 동일한 수준 — 만든 컴포넌트 자신이 쓰거나
  자식에게 넘겨 쓰는 용도, 경계를 넘어 반출/전역 보관하지 않음)를
  `base/bind-system-plan.md`에 명시적으로 문서화하는 것으로 충분 —
  런타임 추적이 아니라 관례 문서화가 맞는 대응. `Tag`/`Attribute`/`Tween`
  같이 quad가 실제로 소유·관리하는 요소에 대해서는 더 자세한 전용
  디버깅 유틸(quad-debug 백로그)을 제공할 수 있고 그게 투자 대비 가치가
  더 큼 — 모든 것에 `Destroying`을 Connect해 범용 안전망을 만드는 방향은
  기각. 별도 검증 레이어(옵트인이든 아니든) 계획 없음.
- **[2026-08-12 열여덟 번째 세션, 사용자 최종 판단 — 원래 2번(fixable)에
  있었으나 여기로 이전]** `:With(...)` 정적 의존성(동적 재평가 미지원).
  동적 의존성 목록을 지원한다는 것 자체가 "State는 immutable하다"는 quad
  전역 가정과 모순 — 의존성 목록이 실행 중 바뀔 수 있다면 그 변경이 후행
  노드 전체에 파급되는 걸 허용해야 하는데, 이건 quad가 계속 원치 않아온
  것. 실사용 사례도 사실상 없음 — React의 `useMemo(fn, [...])`도 실무에서
  deps 배열을 동적으로 조립하는 경우가 거의 없고(그러면 그 훅이 거의 항상
  실행돼버려 메모이제이션 의미가 없어짐), 대부분 정적으로 나열함. 억지로
  끼워넣을 이유가 없는 의도적 비지원 요소로 확정. (State가 아닌 다른
  방법으로 유사한 걸 지원할 수 있는지 자체는 나중에 별도로 리서치해볼 수
  있으나, 이미 결론난 현재 State 설계에 손을 대는 방향은 아님.)
- **암묵적 추적의 인체공학적 우위(vs Vide)** — `derive()` 안에서 그냥
  호출하면 의존성이 잡히는 Vide 대비, quad는 전부 `:With`에 나열해야 해
  보일러플레이트가 늘어남. quad가 "Lua에서 암묵 추적은 부작용 관찰이
  필요해 지저분하다"는 이유로 의도적으로 거부한 결과라, 명시성을 유지하는
  한 고칠 개념 자체가 아님(경감책은 있을 수 있음 — 아래 4번 참고).
- **Tween이 그래프 밖이라 다른 Compute의 입력으로 자유롭게 합성 불가(vs
  Fusion/Vide)** — Fusion Tween/Spring, Vide `spring()`은 그래프 노드라
  다른 파생값의 입력으로 얽어 쓸 수 있음. quad는 Fusion을 반면교사 삼아
  의도적으로 이 경로를 포기한 것이라 원 설계 취지와 충돌. 필요해지면
  옵트인 브릿지 추가가 현실적 타협(지금 급한 건 아님).
- **GC-native 라이프사이클 자체가 안고 있는 리스크** — Vide는 GC와
  `Instance.Destroying` 순서가 비결정적이라는 알려진 함정 때문에 의도적으로
  eager·수동 cleanup을 택함. quad의 "수동 dispose 불필요"는 GC 의존을
  없애려면 결국 Vide식 수동 owner 트리로 돌아가야 해서 철학과 충돌 —
  다만 `base/lifecycle-pattern.md`의 rbvm 실물 검증 근거로 리스크는 이미
  어느 정도 완화돼 있음(기존 base 문서 참고).
- **DOMless+컴포넌트 1회 실행 때문에 "지금 트리가 어떻게 생겼는가"를
  한눈에 재구성하기 어려움(vs react-lua)** — react-lua는 렌더마다 전체
  서브트리를 선언적으로 다시 기술해 현재 상태가 코드 한 곳에 드러남. quad는
  변화가 개별 leaf bind에 흩어져 처리돼 복잡한 조건부 트리 추론이 어려움.
  근본 선택에서 필연적으로 따라오는 트레이드오프라 설계 변경으론 해소 안
  되고, quad-debug 같은 관측 도구로만 보완 가능(이미 백로그에 있음 —
  `research/debug-tooling-plan.md`).

## 4. 성숙도 격차 — 설계 결함 아니지만 지금 시점 비교에선 정직하게 명시해야 함

Fusion(~5000줄+테스트+수년 실사용), Vide(2800줄+테스트+0.1.0→0.4.1 하드닝
이력), react-lua(Roblox 사내 실사용+전용 벤치마크 레포)는 전부 실전에서
발견되고 고쳐진 문제들의 산물. quad는 구현이 0줄이라 이 비교의 강점 항목도
전부 M0 스파이크 이후 실제 Luau로 검증돼야 신뢰할 수 있고, 구현이 진행되면
유사한 이유로 비슷한 안전장치를 뒤늦게 추가하게 될 가능성이 있음(1번의
use-after-destroy 검증처럼). "hooks 없는 quad의 `:With`/`:Compute`가
React 커스텀 훅만큼의 합성성을 실사용 규모에서 주는가"도 지금은 데이터
없음 — 고칠 문제인지조차 판단 이를 정도로 이름.

## 다음 단계

**[2026-08-12 열여덟 번째 세션 — 해소됨]** 2번(fixable)에 남아있던 두 항목
모두 "고칠 필요 없음"으로 사용자가 최종 판단 — 3번(의도된 트레이드오프)으로
이전 완료, 상세 근거는 3번 절 참고. 2번은 이제 전부 해소된 항목만 남음, 이
문서 자체는 더 이상 사용자 판단 대기 상태가 아님.

- 1번 강점 목록은 `research/documentation-content-map.md`의 "왜 quad를
  쓰는가" 초심자/quadnomicon 콘텐츠 소재로 재사용 가능(유일하게 남은 재활용
  대상).
