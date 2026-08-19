# 2026-08-19, 일곱 번째 세션 — `quad-types` 패키지 신설, `AddPlugin`/`CheckedQuad` 실측 설계

**요약**: `RunInit` vs backend 유일 슬롯 가드를 `_initializedBy`로 분리
확정한 뒤, 사용자가 "quad-roblox가 quad-base를 런타임 주입으로만 받으면
dev-dependency로도 타입이 못 산다"는 문제를 제기 — 실측으로 확인하고
`quad-types`(구현 없는 타입 계약 전용 워크스페이스 패키지)를 신설,
`AddPlugin<Self,P>` 플러그인 체이닝과 `CheckedQuad<T>` 컴파일 타임
버전 체크를 설계·구현·검증까지 전부 마침. 과정에서 새 Luau 함정을
하나 발견해 `typing-limits.md`에 승격.

## 1. `_initializedBy` 결정 반영

지난 턴에서 제기된 "`RunInit`을 backend 설치에도 재사용해도 되는가"
질문에 사용자가 짧게 답함: `_initializedBy`를 그대로 쓰자. `RunInit`은
함수 identity 추적이라 "다른 팩토리 재호출=에러"라는 backend 계약을
못 만족한다는 진단을 그대로 확정, `module-lifecycle-plan.md`에 반영
(예시 `InitRoblox` 의사코드 포함, 실제 구현은 M5).

## 2. dev-dependency 문제 제기 → `quad-types` 신설

사용자 문제 제기 요지: `QuadRoblox(Quad): QuadRoblox`처럼 quad-base를
런타임 주입으로 받으면 quad-roblox가 quad-base를 pesde 의존성으로
선언할 필요가 없어 보이는데, 실제로는 타입 참조 때문에 `require`가
필요하다. 이걸 dev-dependency로 두면 게시 후 소비자 환경에서 깨질 것
같은데, 정확히 왜/어떻게 깨지는지 실측해달라는 요청 + "quad-types
폴더를 quad-base 안에 넣고 그것만 링킹하는 게 되는지"/"버전 필드로
타입함수 검증하는 게 되는지" 두 구체적 대안 질문.

**실측 확인**:
- `require(...)`로 타입만 뽑아 쓰는 것도 **런타임에 실제로 실행됨** —
  대상 모듈을 지우고 돌려보니 진짜 크래시(`could not resolve child
  component`). dev-dependency 우려가 정확했음.
- pesde 워크스페이스 의존성은 **패키지 단위**만 가능 — `quad-base/types/`
  폴더로는 "가벼운 타입만" 효과를 못 얻음(전체 패키지가 통째로
  링크됨). **별도 워크스페이스 멤버로 뽑아야만** 실제로 가벼워짐.
- 버전 체크 타입함수 — 최소 재현으로 즉시 성공(`type function
CheckVersion` + `readproperty`/`value()`로 리터럴 비교).

**결론**: `quad-types` 3번째 워크스페이스 멤버 신설, `pesde.toml`
+ `quad-base`/`quad-roblox` 의존성 전환(quad-roblox는 quad-base 대신
quad-types만 의존)까지 실제로 실행 — `pesde install`로 링크 확인.
`quad-spring`/`quad-spring-roblox` 같은 가상의 다른 플러그인 쌍은 이
분리가 필요 없다고 사용자가 별도로 짚음(quad-base처럼 "거의 모든
패키지가 의존하는 핵심 계약"일 때만 값어치가 있음).

## 3. `AddPlugin<Self,P>` — 제네릭 self 체이닝 실측

`Quad:AddPlugin(pluginFn): T`에서 `T`가 정확히 "플러그인이 누적된
Quad"가 되는지 확인해달라는 요청("타입의 근간인 부분"). 여러 스파이크로
검증:
- `<Self, P>(self: Self, pluginFn: (Self) -> P) -> Self & P` — `Self`를
  제네릭으로 둬야 체이닝이 누적됨(고정하면 두 번째 호출이 첫 확장을
  잃음). 실제로 `Quad & SpringPlugin & OtherPlugin`까지 정확히 누적
  확인, 음성 대조군(플러그인 추가 전 접근)도 정확히 거부됨.
- 사용자도 독립적으로 같은 패턴을 직접 테스트해 성공 확인(대화 중
  "성공했어" 보고).
- quad-base에 실제 구현 — `pluginFn(self)`의 결과를 `self`에 mutate
  (새 테이블 안 만듦, `RunInit`의 identity 추적을 안 끊기 위해).
  `smoke.plugin.luau`로 mutate/identity/체이닝 전부 실행 레벨 검증.

## 4. `CheckedQuad<T>` — 배선하며 세 번 깨짐, 세 번째가 핵심 발견

사용자가 구체적 구현 지침을 줌: `error()` 말고 `print()`+`types.never`,
검증 결과는 `__versionCheck` 같은 가상 필드에, 성공 값은 트리비얼하게.
실제로 배선하며 순서대로:

1. **`error()` 시도 → 실패**: type function 자체가 실패로 판정됨.
   `print`+`types.never`로 교체 → 즉시 성공(호출부에 정확히
   "TypeError: <메시지>").
2. **함수 본문 로컬 타입 별칭 시도 → 무반응**: `type _Check =
   CheckVersion<T>`를 본문에 두면 제네릭 인스턴스화마다 재평가 안 됨.
   리턴 타입 표현식 자체로 옮기니 즉시 해결.
3. **[가장 중요] 패스스루(`return t`) 버전 → 단독으론 통과, `AddPlugin`
   체이닝과 조합하면 조용히 깨짐**: `CheckVersion<T> & RobloxExt` 뒤에
   `:AddPlugin(...)`을 부르면 "Expected this to be exactly 'P & Self',
   but got 'P & Self'"처럼 앞뒤가 같은 의미 없는 진단이 남. `&`로 안
   합쳐도, 패스스루만 거쳐도 동일하게 깨짐 — **재구성이 아니라 "type
   function을 거쳤다는 이력 자체"가 문제**. 최종 설계: `CheckVersion`이
   `T`를 절대 반환하지 않고(성공 시 `types.singleton(true)`만), 결과를
   `T & { __versionCheck: CheckVersion<T> }`처럼 원본과 완전히 격리된
   필드로만 노출 — 이 형태만 `AddPlugin` 체이닝과 완전히 호환됨(실측).
   `__versionCheck`는 실제로 참조해야 평가되는 lazy 필드라는 점도
   다시 확인(함정 2와 같은 결).

이 세 번째 발견은 quad 코퍼스에 없던 새 Luau 한계라 `typing-limits.md`
§6으로 승격(6번을 신설하며 기존 6/7/8을 7/8/9로 재번호, 내부 상호
참조 §6/§8도 같이 고침), §8 체크리스트에 항목 7 추가.

## 5. 부수 발견 — quad-base 자기 자신도 CLI symlink 함정에 걸림

`quad-base/src/init.luau`가 `quad-types`를 workspace 의존으로 받게
되며 `require("./roblox_packages/quad_types")`를 쓰게 됐는데, 이건
지난 세션에 발견한 심볼릭 링크 문제(Rojo는 괜찮고 standalone `luau`
CLI만 못 따라감)가 **이제 quad-base 자신의 프로덕션 진입점에도** 닥침 —
지난 세션엔 quad-roblox→quad-base(아직 코드 없음)만 영향권이라 여유가
있었는데, 이번엔 실제로 존재하는 quad-base의 `require`가 막힘. 이
세션은 `pesde install`이 만든 심볼릭 링크를 로컬 CLI 테스트용으로만
실제 디렉토리 복사본으로 치환하는 즉석 조치로 우회(`find ... -type l
... cp -r`) — 정식 스크립트화는 아직 안 함, `project-setup-plan.md`에
다음 세션이 알아야 할 것으로 남김.

## 6. 산출물

- `quad-types/`(신규 패키지: `pesde.toml`, `src/init.luau` —
  `Quad`/`CheckVersion`/`CheckedQuad`), `quad-types/selene.toml`.
- `quad-base/pesde.toml` — `quad_types` 의존성 추가.
- `quad-roblox/pesde.toml` — 의존성을 `quad_base`→`quad_types`로 전환.
- `pesde.toml`(루트) — `workspace_members`에 `quad-types` 추가.
- `quad-base/src/init.luau` — `Quad` 타입을 `quad-types`에서 가져오도록
  전환, `Version`/`AddPlugin` 실제 구현 추가.
- `quad-base/test/smoke.plugin.luau` 신규.
- `.claude/luau-test/done/23-type-quadtypes-checkversion-addplugin.luau`
  신규 — 실제 quad-types/quad-base 통합 검증.
- `.claude/base/quad-types-plan.md` 신규 — 전체 설계/함정/실측 근거.
- `.claude/base/typing-limits.md` — §6(신규, type function 이력 오염)
  추가 + 6/7/8 재번호(→7/8/9) + 체크리스트 항목 추가.
- `.claude/base/module-lifecycle-plan.md` — `_initializedBy` 결정 반영.
- `.claude/base/architecture.md`/`.claude/base/project-setup-plan.md`/
  `.claude/README.md`/`luau-test/README.md`/`STATUS.md` — 관련 갱신.

## 7. 다음

`quad-roblox`의 `QuadRoblox`/`CheckedQuad<T>` 실사용은 M5. 심볼릭 링크
로컬 우회의 정식 스크립트화는 다음에 필요해지면. 사용자 요청으로
대화는 계속 한국어로 진행 중.
