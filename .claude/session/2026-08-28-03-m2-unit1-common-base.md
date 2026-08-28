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

## 다음

단위 끝 절차(규약 §4): 감사 루프 → `/code-review high` → 커밋 → fable 탐사자 →
사용자에게 "§4를 보라".
