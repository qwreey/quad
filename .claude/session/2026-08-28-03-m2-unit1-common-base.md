# 2026-08-28 (03) — M2 착수: 자율 구현 규약 채택 + 첫 단위(공통 기반) 구현

## 경위

- 다른 에이전트가 초안한 "M2 자율 구현 규약" 프롬프트를 사용자가 가져와 *"어떻게
  봐? 진행 하면 될것같아?"* — 대조 결과 **순서 오류 하나**(`EpochMap`이 `Effect` 뒤;
  `ROADMAP.md` "반응형 본체"는 `EpochMap`이 State 본체보다 먼저라 못 박음)와 소스
  단일화 몇 건(규약 위치는 `base/`가 아니라 `conventions.md` 한 줄 + brief 파일 /
  `Void` 체크박스 부재 / `HUMAN_TODO.md` 2번 / 커밋 게이트 두 층 / `TODO(H-nnn)`
  마커 형식 / 단위를 넷으로)을 지적. 사용자: *"수정하고 너가 진행하자. epochmap
  순서 하나 고치고 진행할 수 있겠니?"* → 규약 커밋 `f94234a`.
- 첫 단위 계획(§6)의 배치 결정 셋(브랜드 인스턴스를 `Brand.luau` 한 파일에 / mock
  생명주기를 `mock.luau` 안에 / 테스트 `spec.*` + analyze)을 보여주고 사용자
  *"진행하면 될것 같아"* → `92721d7`.

## 구현 (전부 `./scripts/test.sh` ALL PASS, `luau-analyze` 0건)

- `Void.luau` / `Brand.luau`(생성자 + 인스턴스 15 + `is*` 11) / `LifetimeHandle.luau`
  (`InitLifetimeHandle` — 모듈 인스턴스에 에러 스텁 4종) / `Ref.luau` 최소형 /
  `init.luau` 재export / `quad-types`의 `Quad`·`Ref<T>`·`Relate`·`Epoch` 타입 /
  `Relate.luau`는 타입만 `quad-types`에서 재export(구현 무변경, 대조 일치).
- `test/mock.luau`: `installLifetime(quad)`(`lifecycle-pattern.md` (0)/(1) 스케치
  그대로) + `Destroy`가 모든 Connection을 끊도록 보강(gcconn 판정의 근거).
- `scripts/test.sh`: `spec.*` 수집 + `luau-analyze quad-base/src + spec + mock`.
- spec 5개(brand/relate/lifetime/ref/void).

## 발견 (`qa-request/pre-implementation-handtrace-round11.md`)

- `H-165` ① pesde shim은 생성 시점 export 타입만 안다 → `pesde install` 재실행,
  `project-setup-plan.md`에 둘째 함정으로 기록.
- `H-166` ① `Ref.Revision` 초기값 미정 → `0`, `ref-plan.md`.
- 툴링 사실: `@self`는 `init.luau` 전용 / GC 테스트 함정 둘(죽은 레지스터, 불변
  업밸류 클로저 캐시) — §5.
- ②/③ 갈래 발견 **없음** — §4 표는 비어 있다.

## 단위 끝 절차 (같은 날, 뒤이어)

- 감사 루프 **8라운드** 수렴(3→4→1→2→4→4→1→0). 잡힌 것: `todos.md` 5번 stale /
  `smoke.init` 갱신 누락 / `quad-types-plan.md` `Quad` 블록 stale → 코드 포인터 /
  mock docstring 자기모순 / `architecture.md` 소스 트리(`Brand.luau` 누락·`LifetimeHandle`
  "내부는 Relate"·`Tween.luau`) / **`H-167`** `Ref<T>(T?)`로 옮겨 놓은 자기 실수 →
  문서대로 `Ref<T>(T)` / `TweenBrand` 위치 / `ROADMAP` "`Brand.luau` 트리에 없음" /
  `lifecycle-pattern.md`의 옛 "base가 Relate로 구현" 서술·원 확정 문단·순환 절 인용 /
  `ref-plan.md` 같은-파일 절 인용 둘 / 개수 리터럴 / `conventions.md` 단위 나열.
  **내 수정이 새 결함을 만든 것 둘**(순환 절 인용, 단위 나열 5세그먼트) — 코퍼스의
  기록된 실패 모드 그대로.
- `/code-review high` 10건 → ② `H-168`(`Ref()` 무인자 vs `Ref<T>(T)`) / `H-169`(재진입
  `:Set`의 옛 `value`) / `H-170`(resume이 에러를 삼킴)은 §4 표로, ① `H-171`(mock lazy
  claim GC 타이밍) / `H-172`(mock `Destroy` 의미론) / `H-173`(M7 `TweenBrand` 잔재) 반영,
  잔손질 셋 반영, 기각 셋.

- fable 탐사자: 🔴 `H-174`(생명주기 4종이 인스턴스 필드인데 반응형 의사코드는 자유
  함수 — 조립 형태 미정) / 🟢 `H-175`(클로저 캐시 규칙 범위) → "§4를 보라".

## 배치 회신 (같은 날)

사용자가 §4 넷을 한 번에 답함(원문은 `round11.md` §4). `H-174` 팩토리형 +
`module.canExecute` 늦게 읽기 / `H-169` **사용자 안** — 순회가 자기 리비전이 바뀌면 놓고
후행 `Set`이 전부 호출(권고 `k(self.Value, self)`는 콜백 이중 호출을 남겨 기각) /
`H-168` 시그니처 유지, 관용구는 `Ref<<T?>>()` / `H-170` 즉시 반환 `false`만 올림.
반영: `Ref.luau`(리비전 가드·resume 확인) + `spec.ref` 10·11, `ref-plan.md` `:Set` 블록·
재진입 절·`:Wait` 정정·"제네릭 시그니처" 규칙, `lifecycle-hooks`/`debounce-throttle`
배너, `lifecycle-pattern.md`·`module-lifecycle-plan.md`·`ROADMAP` 반응형 본체에 `H-174`.

## 다음

단위 2(`EpochMap` → `Source`/`State`/`Store`) 착수 — 게이트 없음.
