# 2026-08-19, 다섯 번째 세션 — rokit→mise 전환, selene 린터 도입, darklua 검토 후 기각

**요약**: 사용자가 `Word30210/roblox-project-example`(참고용 GitHub 레포)의
`mise.toml`을 보여주며 "요즘은 rokit보단 mise로 까는듯 하네" 언급.
`initreq/roblox-project-example`로 클론해 구조 전체를 훑고 흡수할 요소를
찾음 — mise 전환, selene 린터, darklua 세 후보 중 사용자가 앞의 둘만
채택.

## 1. 참고 레포 훑기

`packages/`(독립 게시 패키지)+`places/`(멀티 플레이스 게임 프로젝트)+
`scripts/`(빌드 도구) 구조, 각 서브패키지가 독립 `pesde.toml`/
`selene.toml`/`stylua.toml`/`.luaurc`/`.vscode`를 가짐. `Justfile`로
`refresh`/`clean`/`dev` 태스크 러너(각 패키지를 순회하며 `pesde
install`+`darklua process` 반복). `.darklua.json`의 `convert_require`
룰이 경로 기반 require를 Rojo sourcemap 기준 `script.Parent`류로 빌드
시점에 변환. `places/main`의 `default.project.json`(로컬 dev, `src`
직결)과 `build.project.json`(`dist`, darklua 처리 결과) 분리. `optional`
path 문법(`{"$path": {"optional": "roblox_packages"}}`)으로 설치 전에도
Rojo 에러 안 나게 함.

`packages/assets/src/init.luau`가 `require("@self/assets")`를 실제로
씀 — 지난 세션에 발견한 `@self` 규칙의 세 번째 교차 확인(tbox, 이번
세션 자체 실측에 이어).

## 2. 사용자 선택 — mise 전환 + selene 채택, darklua는 보류

멀티셀렉트로 네 후보(mise 전환/selene/darklua/Justfile) 제시,
사용자 답: mise 전환(추천)과 selene은 채택. darklua에는 직접 반박 —
*"roblox 안에서도 이미 string require가 적용되긴 하고, @self와 @game이
먹는다. 같은 동작을 하지만, ./ 등으로 위치를 어떻게 두냐에 유의가
필요할 뿐임. 따라서 darklua의 필요성은 잘 모르겠다"* — 즉 실제 Roblox
엔진도 이 세션들이 확인해온 require-by-string 의미론을 그대로 지원하므로
변환 계층이 불필요하다는 판단(Justfile은 언급 안 돼 도입 안 함).

## 3. mise 전환 — 실제 검증까지 완료

`/tmp`에서 먼저 `mise install`로 pesde/rojo를 테스트 — **GitHub artifact
attestation + SLSA provenance 검증까지 거쳐 설치됨**(이전 세션이 `curl`로
직접 받던 것보다 공급망 신뢰도가 높음). `rokit`은 이 샌드박스에 없어
한 번도 못 써봤던 것과 대비되게, `mise`는 이 샌드박스 자체가 이미
`luau` 설치에 쓰고 있어 실제 검증이 가능했음. `rokit.toml` 삭제,
`mise.toml` 신설(`github:`/`aqua:` 백엔드 접두사 문법 — `rokit.toml`의
평문 `owner/repo@ver`와 형태가 다름) — `pesde`/`rojo`/`luau-lsp`/
`selene` 넷 다 `mise install`+`mise exec`로 버전 일치까지 재확인.

## 4. selene 도입 — CWD 상대 config 탐색 함정 발견

참고 레포의 `scripts/selene.toml`을 그대로 채택. 처음 루트에 단일
`selene.toml`을 두고 `selene quad-base/`를 저장소 루트에서 돌렸더니
`type Quad = {...}` 같은 평범한 타입 선언까지 전부 파싱 에러(30여 건) —
"이 selene 빌드가 Luau 타입 문법 자체를 지원 안 하나?"로 오인했다가,
최소 재현으로 `std = "luau"`가 CWD에 없으면 조용히 Lua 5.1 std로
폴백한다는 걸 확인(`--config`가 파일 트리를 안 거슬러 올라감, CWD 기준
고정 경로). 참고 레포처럼 **패키지별 독립 `selene.toml`**로 전환하고
`cd quad-base && selene .`처럼 패키지 안에서 실행하는 걸로 확정.

부수로 `quad-base/test/smoke.mock.luau`의 `assert(cond)` 3건(메시지
없음)이 selene의 `incorrect_standard_library_use`(deny)에 걸려 실제
수정(메시지 추가) — 도입하자마자 실제 코드 품질 개선.

## 5. 산출물

- `mise.toml`(루트, `rokit.toml` 대체), `quad-base/selene.toml`,
  `quad-roblox/selene.toml` 신설.
- `.claude/base/project-setup-plan.md` — "툴체인" 절 전면 갱신(mise 전환
  경위, darklua 기각 근거), "`selene` 린터" 절 신설.
- `.claude/base/architecture.md`/`.claude/README.md`의 `rokit.toml`
  잔여 참조 정정.
- `quad-base/test/smoke.mock.luau` — selene이 잡은 `assert` 메시지
  누락 3건 수정.
- `initreq/roblox-project-example` 클론 보존(읽기 전용 참고 레포,
  `.gitignore`로 이미 제외되는 `initreq/` 하위라 커밋 대상 아님).
