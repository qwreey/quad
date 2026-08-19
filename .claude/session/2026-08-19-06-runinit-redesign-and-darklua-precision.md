# 2026-08-19, 여섯 번째 세션 — `RunInit` 재설계, darklua 경계 정밀화

**요약**: 사용자가 두 가지를 요청. (1) 지난 darklua 기각 근거를 실측으로
정밀화, (2) `New()`의 멱등 Init 가드를 파일마다 `Relate`+센티널을 두는
대신 **함수 자체를 릴레이션 키로 쓰는 공유 `module:RunInit(initFn)`**로
재설계. 둘 다 실제로 구현·검증까지 완료. 이후 대화는 한국어로 진행하기로
합의.

## 1. darklua 경계 실측 — `@self`/`@game`은 안 건드리고, 커스텀 alias만 변환

`darklua` 0.19.0을 직접 설치해 참고 레포(`initreq/roblox-project-example`)에서
`pesde install`+`rojo sourcemap`+`darklua process`를 실제로 돌려봄:
- `require("@self/X")`/`require("@game/...")`는 `convert_require`가
  손을 안 대고 경고만 찍은 채 원문 그대로 통과(`unknown source name`).
- 커스텀 `.luaurc` alias(`@pkg`)는 실제로
  `require(game:GetService('ReplicatedStorage'):WaitForChild('roblox_packages'):WaitForChild('assets'))`로
  치환됨 — `.luaurc` 매핑 + Rojo sourcemap을 같이 읽어 해석.

결론: quad는 상대경로+`@self`만 쓰므로 지금 darklua는 정말 불필요하지만,
**나중에 `@pkg/quad_base`류 축약 alias를 쓰고 싶어지면 그때는 darklua가
실질적으로 필요해진다** — `project-setup-plan.md`에 이 경계를 정확히 반영.

## 2. `RunInit` 재설계

사용자 제안: 모듈 설정 완료 여부 릴레이션을 파일마다(`INITED` 센티널 +
`Relate()`) 따로 두지 말고, **함수 자체를 릴레이션 키로** 쓰고
`module.RunInit(initfun: (module)->any)`를 구현해 "실행한 적 없으면
실행"을 전담시키자는 것. 근거: `(any)->any : boolean?` 형태의 릴레이션이
간단하고, 파일마다 보일러플레이트를 반복할 이유가 없음.

실제로 반영:
- `quad-base/src/init.luau` — 최상위에 `runInitRelate = Relate()` 하나만
  두고, `module.RunInit(self, initFn)`이 `(module, initFn) -> boolean?`
  릴레이션으로 실행 여부를 판정. `Quad` 타입에 `RunInit` 필드 추가.
- `quad-base/src/Debug/init.luau` — 가드 보일러플레이트 전부 삭제, 그냥
  무조건 `module.debug = false`만(멱등은 호출부 `RunInit`이 보장).
- `quad-base/test/smoke.init.luau` 신설 — 같은 `initFn` 재호출 시
  1회만 실행, 서로 다른 `New()` 인스턴스는 기록 비공유, 서로 다른
  `initFn`은 서로 무간섭 — 3개 시나리오 전부 검증. `selene`이 `assert`
  메시지 누락/미사용 매개변수 몇 건을 잡아 같이 수정.
- `luau`/`luau-analyze`/`selene` 셋 다 클린.
- `module-lifecycle-plan.md` "New()의 내부 구성" 절 — 옛 파일별
  센티널 의사코드를 새 `RunInit` 의사코드로 교체, 근거·GC 특성·
  `_initializedBy`와의 층위 차이 재서술.

## 3. 미결 — `RunInit`을 backend 설치 진입점에도 재사용할지

사용자 질문: `RunInit`을 `QuadRoblox(Quad) -> QuadRoblox`(backend 주입
진입점) 내부에서도 그대로 써도 되는지. **답은 아직 안 냄** — `RunInit`은
함수 identity로만 추적하는데, backend 가드(`base/bind-system-plan.md`의
"Bind는 누가, 어떻게 구현하는가" 절)는 "같은 팩토리 재호출=no-op, **다른
팩토리=에러**"라는 계약이 있어서, `InitRoblox`/`InitGtk`처럼 서로 다른
함수가 같은 "백엔드 슬롯"을 다투는 상황을 `RunInit`은 구분 못함(둘 다
"아직 안 돈 함수"라 각자 조용히 실행되어 버림 — 에러가 나야 하는데 안
남). 슬롯 키를 별도로 감싸는 방안을 떠올렸으나 결론은 안 냄 —
`module-lifecycle-plan.md`에 ⚠️ 미결로 반영, M2/M5 착수 전 확인 필요.

## 4. 타입 관련 질문 — 답변 보류

사용자가 "pesde가 타입만 뽑아주는 게 있다고 들었다"며 quad-roblox가
quad-base 타입을 그걸로 갖게 되는지 물음. 워크스페이스 링크(심볼릭
링크로 연결된 실제 소스)를 통한 타입 추론은 이미 지난 세션에 실측
확인됐고 이 메커니즘과는 무관해 보이지만, `HUMAN_TODO.md` 8번이 말하는
"pesde의 타입 추출"(d.ts류, const 지원과 엮인) 기능 자체를 이 세션이
따로 조사하지 않아 정확한 답은 다음 턴에서 이어감.

## 5. 이후 진행

사용자 요청으로 이제부터 대화를 한국어로 진행.
