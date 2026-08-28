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

## 단위 2 — `EpochMap` → `Source`/`State`/`Store` (같은 날, 이어서)

- 입력: 탐사자 색인으로 `base/` 의사코드 범위를 읽고, 10라운드 참조 구현
  `audit/handtrace-round10-reference-impl/spikes/core10.luau`를 출발점으로(단, `H-163` 이전
  모양이라 `_emitDown`은 `sub:_receive` 단일 인터페이스로 옮김), 타입은 `ty11_store_final.luau`
  최종형 그대로 `quad-types`에.
- 구현: `EpochMap.luau`(잎) / `State.luau`(`Init(module)` + `implFor`, `H-174`) / `Source.luau` /
  `Store.luau` / `init.luau` 배선 / spec 4개(epochmap·source·state·store). `./scripts/test.sh`
  ALL PASS, analyze 0.
- 발견 `H-176`(타입팩 deps 선언은 strict에서 기각 → `...any`), §5에 조립 세부·dep 검증·`Apply`
  유니온 추론 캐비엇 기록.

## 단위 2 끝 절차 — 진행 중에 중단 (사용자: *"커밋하고 멈춰줘. 집에 가서 작업할게"*)

- 감사 루프 3라운드까지 반영(발견 6→4→3, 커밋 `500ae29`/`cd65520`/`8aa13ed`). 4라운드를
  diff 범위 수렴 확인 각도로 띄웠다가 사용자 요청으로 **중단**(결과 없음).
- 아직 안 한 것: 감사 4라운드(0건 확인) → `/code-review high` → fable 탐사자(규약 §5) →
  "`round11.md` §4를 보라". §4엔 지금 새 문항 없음(단위 2 발견은 전부 ①: `H-176`, `H-177`).

## 2026-08-29 새벽 — 컨테이너 이사 뒤 재개 (사용자: *"내가 자는동안 많은 작업을 수행해도 좋아"*)

사용자 원문(01:00 KST): *"내가 자는동안 많은 작업을 수행해도 좋아. 코퍼스 전체를 순회하거나
구현을 계속하거나 등, opus 모델을 잘 섞어서 수행하면 괜찮아. 2개 정도까지 병렬로 돌려도
토큰 비용 문제 없어. … 내일 2시에서 4시 사이에 내가 돌아오게 될거야."* — 그래서 이 구간은
감사자 2개 병렬(`conventions.md`의 2026-08-18 "하나씩" 규칙의 비용 근거를 사용자가 걷음,
예외로 명문화). 감사자 모델은 sonnet 유지, 색인·탐사엔 opus.

- 이사 검증: `upstream/main`에서 26커밋 fast-forward, `pesde install`, ALL PASS. Studio MCP
  연결(`Place1`, Edit) — M5 전까지 안 씀.
- 단위 2 감사 4·5라운드 반영(`442d800`, `67fb61e`: `implFor` 호출자 정정, `EpochMap`도 공유 잎,
  `_hold` 본문 닫힘, `H-174` 잎 목록은 파일 헤더가 소스, `InitState` → `State.Init` 표기).
- **단위 3 구현** — `Observer.luau`(인스턴스별 임플 + 레지스트리 둘, 네 진입점 인라인)/
  `Effect.luau`(`rawRerun(force)`·`_rerunRequired` 홀드·`_cleanupRunning`·네 진입점 자기 본문)/
  `State:Observer` 위임/`LifetimeHandle`에 `onDestroying` 스텁/mock `onDestroying`/`quad-types`
  `Observer`·`EffectHandle`·`Quad.Effect`. spec.observer 8절·spec.effect 9절 ALL PASS, analyze 0.
  발견 `H-178`(사적 필드 `_` 접두, 기록만).

- 단위 2 감사 6라운드 수렴(0건). 단위 3 감사 1라운드: `todos.md` stale 1 + 의심 2(반영).
- **단위 4 구현** — `State.luau`에 `GateImpl`/`:Gate`, `Blocker.luau`(잎), `quad-types`에
  `GateSetup`/`Blocker`/`State.Gate`/`Quad.Blocker`, `spec.gate` 9절·`spec.blocker` 7절.
  발견 `H-179`(`Apply` 파라미터는 교집합 오버로드 — 스파이크 4개, `luau-test/done/26-*`),
  `H-180`(`:Block` 잔재). ROADMAP M2 체크박스 전부 `[x]`(`H-80` 포함).

- 단위 3·4 감사 루프 수렴(단위 3: 3→4→4→3→0, 단위 4: 4→3→1→0 — 전부 문서 stale·표기·
  마크업 파손, 그중 셋은 내 수정이 만든 것).
- `/code-review high`(단위 3·4) 10건: **① 넷** — `H-181` 🔴 `implByModule`(weak-key, 값이 키
  캡처 → ephemeron 없어 인스턴스 영구 핀) → `module._impl` 비공개 필드(`H-174` (a) 원문) /
  `H-188` 반쯤 만든 `GateNode` / `H-189` `Observer.Subscribed` 초기값 / `H-190` `Apply` 검증.
  **② 여섯** `H-182`~`H-187`(Destroy 파동 재실행 창 / Observer 설치 발화 재진입 / `bindLifetime`
  커밋-훅 순서 / cleanup 팩 / 교차 인스턴스 dep / 타입 별칭 이름 넷) → §4 표 + 코드 마커.

## 다음

fable 탐사자(단위 3·4) → 사용자에게 "`round11.md` §4를 보라". §4엔 문항 여섯(권고 전부 (a)).
M3은 이 자율 구간의 범위 밖(규약 §1은 M2 단위 넷까지).
