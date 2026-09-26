# round13 E43 — 다음 릴리즈 리허설 (2026-09-27)

HEAD `221ba458`을 `git archive HEAD | tar -x`로 레포 밖 스크래치 셋에 풀어 돌렸다(원본 레포·`.git` 무변경, 실 게시·태그·푸시·리모트 없음).
사본: `…/scratchpad/e43-release`(3.3.0), `e43-release-v4`(4.0.0), `e43-release-nolock`(lock 게이트 재현). 스테이징은 `publish.py --keep --stage-dir`로 스크래치 아래.

## 단계별 결과

| 단계 | 결과 |
|---|---|
| bump 3.3.0 | exit 0. 바뀐 파일 10: 매니페스트 넷(루트·base·roblox·types), `quad-base/src/init.luau` Version, `quad-types/src/init.luau` Version 리터럴 타입, `quad-base/test/smoke.plugin.luau`, `quad-roblox/src/init.luau` `VERSION_PATTERN` `"3.2^.0^"`→`"3.3^.0^"`, `quad-roblox/test/spec.robloxfactory.luau` 두 자리(패턴 에코·재시도 버전), `CHANGELOG.md`. 범용 둘(`quad-error`·`type-version-check`)은 3.2.0 그대로(설계대로). |
| CHANGELOG 절단 | 정상 — `## [Unreleased]` + 안내문 + `---` 유지, 그 아래 `## [3.3.0] - 2026-09-27`에 Added/Changed/Fixed 전부 이동, 옛 `---`(Unreleased↔3.2.0 사이) 제거. 3.3.0↔3.2.0 사이엔 hr 없음(3.2.0↔3.1.0과 같은 모양). |
| 태그 명령 | `git tag -a 3.3.0 -m "quad 3.3.0" && git push origin 3.3.0` 한 줄(두 명령) + github/upstream 태그 푸시 안내 주석. `pesde install` 안내는 출력에 없음. |
| docs 잔여 목록 | `docs/`(site 제외) 안 "3.2.0" 문자열 20줄을 찍음 — q.Out 캐비엇 셋·설치 문서·에러 07·레퍼런스 01/07/09/02/05·how-to 06·agents 01·overview 03. 루트 `README.md:27`("3.2.0이 게시돼")은 목록에 없음(아래 b2). |
| pesde install → lock | 여섯 중 lockstep 넷(루트·base·roblox·types)이 3.3.0, 범용 둘은 3.2.0(설계대로). `quad_base`/`quad_types`의 그래프는 `quad_error@3.2.0`·`type_version_check@3.2.0`을 가리킴. |
| test.sh (3.3.0) | exit 0(스펙 56), check-version `canonical 3.3.0, VERSION_PATTERN 3.3^.0^`. |
| publish dry-run (기본) | **5건** OK(quad-types·quad-base·rbx-quad-types·rbx-quad-base·quad-roblox), 스테이징 test.sh exit 0(스펙 56). 범용 둘은 "게시 안 함(이미 올라간 번호여야 한다)". |
| publish `--with quad-error,type-version-check` | 9건 OK(`--no-test`). 범용 둘도 3.2.0으로 dry-run 통과 — 이미 게시된 번호라 `--real`이면 레지스트리가 거부할 것(dry-run은 모름). |
| publish `--with a --with b`(반복형) | **마지막 하나만 적용**(7건, `quad_error`는 "게시 안 함") — 에러·경고 없음. |
| 스테이징 산출물 | 매니페스트: lockstep 셋 `version = "3.3.0"`, 서로 `^3.3.0`, 범용 둘은 `^3.2.0`; rbx 쌍둥이 `environment = "roblox"`·`build_files = ["src"]`·의존 `target = "roblox"`; `quad_roblox` dev_dep `quad_base ^3.3.0` roblox. includes는 `src/**`·README·LICENSE·pesde.toml(CHANGELOG는 범용 둘만 포함). require: 스테이징 7패키지 317개 상대 require 전부 실재 경로로 해소, roblox 타깃 src에 `luau_packages/` 잔존 0, luau 타깃 src에 `roblox_packages/` 0. README 다섯 전부 `Declaration` 표기(`H-747` 해소 확인). |
| bump 4.0.0 (bump-package 둘 → bump) | exit 0, 14파일. `VERSION_PATTERN` `"4.0^.0^"`, 범용 둘 CHANGELOG에 `[4.0.0]` 절(안내문·hr 보존), lock 여섯 모두 4.0.0, test.sh exit 0(스펙 56), publish `--with …` 9건 OK — 전 의존 `^4.0.0`. |
| 사이트 (3.3.0 사본) | 4321 리스너 없음 확인 뒤 사본에서 `sync-docs.py` → `npx astro build` 성공(193페이지). 헤더 배지 `v3.3.0`, `/changelog/`에 `#330---2026-09-27` 절, 사이드바 버전 항목 `/changelog-versions/version/3-3-0/` 생성. 설치 문서 등 본문 "3.2.0"은 손 수정 전이라 그대로(b2와 같은 목록). |

## 발견

### (a) 문서 오류

- a1. `HUMAN_TODO.md` 20번이 "둘이 먼저 올라가야 quad 패키지의 `^`가 `^4.0.0`으로 풀린다"라고 적었는데, dry-run 실측으로는 `version = "^"`의 풀림은 업로드 순서가 아니라 게시 시점 워크스페이스 매니페스트 버전에서 온다(범용 둘을 올리지 않은 dry-run에서도 `^4.0.0`). 업로드 순서가 레지스트리 검증에 필요한지는 이 리허설로 확인 못 함.
- a2. `docs/site/src/version.ts:2`가 "다섯 패키지의 버전은 check-version.py가 lockstep으로 묶어 두므로"라고 적었으나 2026-09-15부터 lockstep은 셋이다(범용 둘은 `bump-package`). 배지는 quad_base만 읽으므로 동작 영향은 없음.
- a3. `quad-roblox/src/init.luau:34` 주석 "floor within major 3"은 bump가 고치지 않아 4.0.0 뒤엔 틀린 서술이 된다(코드 주석).
- a4. `conventions.md` 2026-09-10 항목은 게시 도구를 `publish.py --with <폴더>`(단수)로 적는데 실제 문법은 쉼표 목록 한 번(`--with a,b`)이고 반복하면 마지막만 남는다(b3). `HUMAN_TODO.md` 20번의 쉼표형이 맞다.

### (b) 스크립트·게이트 결함

- b1. **bump 뒤 `pesde install`을 빠뜨려도 게이트가 통과한다(E30 B1 재현).** 재현: 사본에서 `pesde install`(3.2.0) → `check-version.py bump 3.3.0` → install 없이 `./scripts/test.sh` → exit 0, `pesde.lock` 여섯은 모두 3.2.0. `check-version.py`(test.sh 게이트)는 매니페스트·소스만 보고 lock을 읽지 않으며, bump 출력도 install 단계를 안내하지 않는다(태그 명령만). 게시본 자체는 안전하다 — `publish.py` 스테이징이 매번 `pesde install`을 새로 돌리므로 타르볼의 버전·의존 범위는 맞다. 어긋나는 건 커밋·태그되는 레포 트리의 lock이다.
- b2. bump의 "docs still mention" 잔여 목록은 `docs/**.md`의 정확한 옛 버전 문자열만 본다. 놓치는 것: 루트 `README.md:27`("pesde 레지스트리에 3.2.0이 게시돼"), 그리고 4.0.0일 때 메이저 범위 표현 전부 — `README.md:22-24,47`, `docs/getting-started/00-installation.md:44-46,55,62`의 `^3.0.0`/"3.x 안에서", `docs/overview/01-why-quad.md:336` "3.x는 안정화 구간", `docs/site/sync-docs.py:44` 설명 "3.x 릴리즈마다". 4.0.0 bump에서 이 목록은 3.3.0과 같은 20줄만 찍고 `^3.0.0` 설치 스니펫(4.0.0을 받지 못함)은 한 줄도 안 찍는다.
- b3. `publish.py --with`가 argparse 단일 저장이라 `--with quad-error --with type-version-check`는 앞의 것을 조용히 버린다(재현: 위 표, 7건·"quad_error 게시 안 함"). 에러도 경고도 없다.
- b4. `publish.py`는 `--with`로 지정된 범용 패키지의 번호가 이미 게시된 번호인지 보지 않고, 지정 안 된 쪽의 "이미 올라간 번호여야 한다"도 확인하지 않는다(dry-run은 레지스트리를 안 봄). 재현: 3.3.0 사본에서 `--with quad-error,type-version-check` → 3.2.0 두 건이 dry-run OK. 반대로 `bump-package` 후 `--with` 없이 돌리면 새 번호(4.0.0)의 `^4.0.0`에 걸린 lockstep 패키지만 올라가고 범용 둘은 안 올라간다 — dry-run은 통과, 실게시에서야 의존 해소가 깨질 수 있음(레지스트리 동작은 미실측).

### (c) 판단 필요

- c1. **3.3.0 경로에서만:** 게시될 quad 3.3.0 셋은 범용 둘을 `^3.2.0`으로 문다(스테이징 매니페스트 실측). `HUMAN_TODO.md` 20번 계획은 최종 고정 릴리즈 뒤 범용 둘의 3.x를 전부 yank하고 4.0.0을 첫 독립 번호로 낸다 — 그 뒤엔 3.3.0(과 3.0~3.2)이 yank된 의존을 가리키고, 범용 4.0.0은 `^3.2.0`에 안 들어간다. 4.0.0 경로(범용 둘 먼저 `bump-package 4.0.0`)에선 이 문제가 없다(전 의존 `^4.0.0` 실측). 3.3.0을 낼 때 범용 둘을 3.2.0으로 둘지는 이 yank 계획과 함께 봐야 한다.
- c2. **4.0.0 경로에서만:** `bump 4.0.0`만 하고 `bump-package`를 빠뜨리면 quad 4.0.0이 범용 둘 `^3.2.0`을 물고 나가는데 어떤 게이트도 잡지 않는다(check-version은 범용 둘을 보지 않음). HUMAN_TODO 20의 순서 서술에만 의존.
- c3. 태그 이름 공간: 릴리즈 태그 규약은 `N.N.N`이고 `bump-package`는 태그 명령을 출력하지 않는다. 4.0.0 경로에서 quad와 범용 둘이 모두 4.0.0이 되고, 이후 범용 쪽이 독자 번호(예 4.1.0)를 낼 때 quad 태그와 같은 이름이 될 수 있다 — 범용 패키지 릴리즈를 태그로 표시할지·어떤 이름으로 할지 정해진 곳이 없다.
- c4. 설치 문서·README가 권하는 `^3.0.0`은 3.3.0이 나오면 그대로 받아 들인다 — `[Unreleased]`의 BREAKING 여럿이 마이너로 들어온다(오버뷰 01 §8 "3.x 마이너에도 깨질 수 있음"과는 일치, 설치 문서의 고정 권고 문구는 "같은 버전으로 고정"만 말함). 3.3.0으로 낼 때 설치 문서 쪽 안내가 충분한지는 사용자 판단.

## 미완

- 레지스트리 쪽 동작(이미 게시된 번호 재게시 거부, 미게시 의존 버전을 가리키는 패키지 게시 거부)은 `--real` 없이 확인 불가 — 추정으로만 적었다.
- `--with …` 두 번은 `--no-test`로 돌렸다(기본 dry-run·4.0.0 사본 test.sh는 게이트 전부 exit 0).
- 사이트는 3.3.0 사본만 빌드(4.0.0 사본은 안 함).
