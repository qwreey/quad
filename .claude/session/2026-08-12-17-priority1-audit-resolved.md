# 2026-08-12 열일곱 번째 세션 — `pre-implementation-audit.md` 우선순위1 마지막 넷 전부 해소

**배경**: 이전 세션(열여섯 번째)까지 `research/pre-implementation-audit.md`의
우선순위1 11개 중 7개는 해소됐지만 4개(1-3/1-4/1-10/1-11)가 열려있었음.
사용자가 이번 세션에서 4개 전부에 대해 구체적인 결정을 한 번에 제시.

## 1-3. 우선순위 스캔 동률/매치 실패 처리

사용자 판단: 동률(같은 `priority`)을 엄격한 tiebreak 규칙(예: 등록 순서)으로
잡으려 하면 `None`/`Store`처럼 이미 `isHandlable`이 안 겹치는 내장 핸들러까지
전부 그 규칙을 신경 써야 하고, 나중에 서드파티 핸들러가 늘어나면 계속
골치아파짐. 대신 **목적별로 이름 붙은 우선순위 상수**(`HANDLER_PRIORITY_HIGH`
등, 열린 숫자 공간 위의 편의 상수라 `+1`류 세밀 조정도 가능 — "우선순위
밴드+오프셋"은 여러 업계에서 흔한 패턴)로 애초에 동률이 잘 안 나오게 유도.
실제로 동률이 나면 대개 설계 실수이므로, 강제 규칙보다 **디버그 모드**(핸들러
등록/정렬 시점에 동률 감지 시 print 경고, `Dispatch.listHandlers()`류 전체
핸들러 목록 조회 함수)로 대응 — 구현 비용이 거의 없고 실제 개발에 바로
도움이 되는 항목이라 M2 기본 기능으로 확정.

## 1-4. provider(팩토리) 미주입 상태에서 dispatch 호출

사용자 판단: 별도 처리 불필요. 핸들러가 없으면(`isHandlable`을 만족하는
핸들러가 하나도 없으면) `Brand`/`typeof(v)`를 출력하고 그냥 에러로 죽으면
됨 — "quad-roblox 등 provider가 초기화됐는지 확인하라"는 안내 문구 정도만
추가. 이게 1-3의 "매치 실패=즉시 error" 규칙과 정확히 같은 경로라는 걸
이번 세션에 확인 — provider 미주입 상태는 결국 "그 클래스의 핸들러가
레지스트리에 없는 상태"이므로 매치 실패와 별개 케이스가 아님. 오타 키/
미지원 조합/provider 미주입을 서로 다른 에러로 구분할 필요 없음(다른
라이브러리에서도 흔한 패턴).

## 1-10. `store.key` 레코드 필드 타이핑

사용자가 Luau `type function`(https://luau.org/types/type-functions/,
https://luau.org/types-library/) 기반 구체적 구현 방법을 제시 — `T`가
테이블 타입이면 `ty:properties()`로 각 필드를 순회하며 `Source`로 감싼
새 타입을 조립하는 `WrapStore`/`ProcessStoreType` 타입함수 스케치.
`ProcessStoreType<{ty: string}>` → `{ty: Source<string>}`가 나오는데, 이건
선언 시점에 이름 붙은 `Source<string>` 자체가 아니라 구조를 풀어낸 익명
타입이지만 Luau가 이름이 아니라 "만족하는가"로 구조적 일치를 검사하므로
문제없이 대입 가능 — 오히려 이 방식과 정확히 맞는 조합이라는 걸 확인.
`type function`은 TBox에서도 이미 쓰이는 검증된 패턴. 이걸로 "검증 난이도"
자체가 사라져 M0/M3 어느 시점에 실제로 부딪혀봐도 막힐 위험 없음 —
`ROADMAP.md`의 M0/M3 배치를 억지로 옮길 필요는 없어짐.

## 1-11. `table.clone` + `__index` 메타테이블 트릭

사용자가 `table.clone`의 정확한 동작을 직접 확인해줌: 새 빈 테이블을 만들고
원본 키를 네이티브 슬롯 단위로 얕은 복사(깊은 복사 아님), 그 다음 원본의
`getmetatable` 결과를 그대로 새 테이블에 `setmetatable` — **메타테이블
자체는 복사되는 게 아니라 같은 참조를 공유**. 이걸로 M7 전체 설계가
의존하던 두 Luau 동작(제네릭 `__index`가 임의 key를 잡아 즉석 클로저를
만드는 것, `table.clone`이 메타테이블 참조를 보존하는 것) 모두 공식
동작대로 확인됨.

**추가 논의 — Property에 Attribute식 소유권 레지스트리를 적용하는 안,
검토 후 기각.** 사용자가 "프로퍼티도 Attribute처럼 처리해도 될까" 생각해봤다가
스스로 기각한 근거를 공유: Attribute 이름은 호출자가 자유롭게 짓는
네임스페이스라 자기 전용 키 객체를 만들 수 있지만, Instance 프로퍼티
이름은 엔진이 이미 정해둔 유한 집합이라 호출자가 전용 키를 새로 못 만듦.
그래서 "이 프로퍼티를 지금 누가 소유하고 있는가"라는 질문 자체가 원천적으로
성립 안 함(여러 modifier가 같은 프로퍼티를 건드리는 게 오히려 정상 시나리오,
테마 오버라이드 등) — 이게 Property가 소유권 추적 대신 Modifier의 override
우선순위 패턴을 쓰는 이유라는 걸 명문화.

## 결과

- `base/bind-system-plan.md`: "우선순위 동률/매치 실패 처리" 절 신설(핸들러
  계약 절), "`store.key` 레코드 필드 타이핑" 절 신설(타입 추론 문제 절
  바로 뒤).
- `base/module-lifecycle-plan.md`: provider 미주입 케이스 해소 표시 추가.
- `base/modifier-plan.md`: `table.clone` 정확한 동작 절 추가, Property
  소유권 레지스트리 기각 절 추가.
- `research/pre-implementation-audit.md`: 1-3/1-4/1-10/1-11 전부
  `[해소됨]` 표시, "다음 액션 제안" 절 갱신 — **우선순위1 11개 전부 해소**.
- `.claude/question.md` 2번 절 동기화.

M0 착수 전 남은 유일한 게이트는 `.claude/luau-test/` 스파이크 실측
결과 확인(아직 사용자가 안 돌려봄) — 설계 자체는 더 이상 막힌 게 없음.

## 핸드오버 점검(같은 세션, 후속) — 누락된 스파이크 파일 발견

사용자가 "세션 중 알게된 지식 누락/stale 점검" 요청 — 위 문서 반영을 다시
훑던 중, 1-10/1-11은 `pre-implementation-audit.md`/`base/`에 "확인됨"으로
표시했지만 실제로는 **사용자의 설명/지식을 바탕으로 한 설계 레벨 확인이지,
실제 Luau 코드로 돌려본 적은 없다**는 걸 재확인. 그런데 `.claude/luau-test/`
15개 파일 중 이 둘(Luau `type function`으로 `store.key` 타이핑, 제네릭
`__index`+`table.clone` 체이닝)을 커버하는 스파이크가 하나도 없었음 —
둘 다 이번 세션에 처음 나온 구체 메커니즘이라 이전 스파이크 라운드
(1~5차)에 있을 수 없었던 게 당연하지만, 그렇다고 "실측 대상"이라고만
말해두고 실제 파일을 안 만들어두면 다음에 또 놓치기 쉬움.

**조치**:
- `.claude/luau-test/16-type-store-key-typefunction.luau` 신규(타입체크
  전용) — 사용자가 준 `WrapStore`/`ProcessStoreType` 스케치를 그대로
  옮김, `luau-analyze`/`luau-lsp`로 실측.
- `.claude/luau-test/17-modifier-index-tableclone-chaining.luau` 신규
  (런타임) — 제네릭 `__index` 체이닝(A), 메타테이블 참조 동일성(B),
  원본 불변(C), 형제 분기 비오염(D) 네 갈래로 assert.
- `.claude/luau-test/README.md` 파일 목록 표/실행환경 표/"결과 확인 후
  할 일"/갱신 이력(6차) 갱신.
- `ROADMAP.md`도 같이 감사 — M2에 우선순위 동률/매치실패 처리(디버그
  모드 `Dispatch.listHandlers()` 포함) 체크리스트 항목이 통째로 빠져있던
  것, M3/M7의 `store.key`/`table.clone` 항목에 새 스파이크 파일 링크가
  없던 것을 같이 보강.
- `pre-implementation-audit.md`의 1-10/1-11 해소 블럭과 "다음 액션 제안"에
  새 스파이크 파일 이름을 명시적으로 링크.

**교훈**: "설계는 확정됐다"와 "실제로 실행해서 확인했다"를 같은 `[해소됨]`
마커로 뭉뚱그리면, 정작 실측이 필요한 지점이 조용히 새는 패턴이 생김 —
앞으로 `[해소됨]` 표시를 붙일 때 그 해소가 (a) 순수 설계 결정인지 (b) 실측
검증까지 끝난 것인지 구분해서 적을 것.
