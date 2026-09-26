# E30 — CHANGELOG 릴리즈된 절 대조 (2026-09-27, round13 자율 루프)

HEAD `b3947ee1` 기준. 레포 무변경, 과거 시점은 `git show`/`git diff`/`git archive`(스크래치)만. v1은 `/code/Projects/quad-v1`(브랜치 `v1-master` = `upstream/master` `4824bab`, 읽기만).

## 태그

| 태그 | 커밋 | 커밋 시각 | 종류 |
|---|---|---|---|
| `2.24` | `81d981d` | 2023-02-22 04:07 | 경량(v1) |
| `3.0.0` | `7a080e0` | 2026-09-10 15:06 | 주석(태그 시각 09-11 17:48, 소급) |
| `3.1.0` | `01818b5` | 2026-09-11 17:32 | 주석(09-11 17:48) |
| `3.2.0` | `d012eeb` | 2026-09-14 15:08 | 주석 |

게시 시점 확인: 3.0.0은 `8a58ea6b`(16:29 "게시 완료 반영") 전에 게시 — 태그와 그 사이 커밋 셋은 docs/site만 건드림. 3.1.0·3.2.0도 태그 뒤 첫 패키지 소스 변경(`34474585`, 09-15)이 게시 기록(`54b90a3d`, 09-14 15:28) 뒤라 게시본 = 태그.

## 구간별 대조표

| 절 | 절 줄 수 | 대조 일치 | (a) 절에 있는데 diff에 없음 | (b) diff에 있는데 절에 없음 | (c) 이름·옮기는 법 불일치 | (d) BREAKING 누락 |
|---|---|---|---|---|---|---|
| `[3.2.0]` (`3.1.0..3.2.0`, 34커밋, 패키지 소스 커밋 2: `ba156bc2`·`d012eeb1`) | 2 | 2 | 0 | 0 | 0 | 0 |
| `[3.1.0]` (`3.0.0..3.1.0`, 72커밋, 패키지 소스 커밋 5) | 4 | 4 | 0 | 0 | 0 | 0 (판단 1 — 아래 C1) |
| `[3.0.0]` (첫 게시, 2.24 대비·3.0.0 시점 표면) | 42 (Added 15·Changed 16·Removed 11) | 42 (Added 이름 전수, Changed/Removed는 v1 2.24·v2 3.0.0 양쪽 이름 존재 확인) | 0 | 0 | 0 | — |
| `2.x (quad v1)` | 32 | 헤딩 19개 버전·날짜·해시 전수 일치, 내용 샘플 10/10 | 0 | — | 0 | — |

### `[3.2.0]`
패키지 소스 diff의 코드 줄 변경: `q.D`→`q.Declaration`(RobloxFactory 반환 필드·`RobloxExtension` 필드), 루트 재수출 `D`/`DMapper`→`Declaration`/`DeclarationMapper`, 생성 모듈 `src/D`→`src/Declaration`(`DModifier`→`DeclarationModifier` 포함), 버전 리터럴. 나머지(`Dispatch/Modifier`·`None`·`quad-types`)는 주석뿐. 절 두 줄이 이를 전부 덮음.

### `[3.1.0]`
코드 줄 변경: `Operator.Index`→`Indexed`(quad-base·quad-types·에러 문구), `Slot:Single` `<UD>`→`<Item, UD>`(quad-types), nil 구멍 에러 문구(`Bookkeeping.luau:245`), `type_version_check` `CheckVersion`에서 `pcall` 제거, 버전 리터럴. 매니페스트 설명 문구(`type-version-check/pesde.toml` — 런타임 `matchesPattern` 명시, 함수 자체는 3.0.0에도 있었음)와 README 표는 문서. 절 네 줄이 전부 덮고, 인용한 에러 문구는 3.1.0 소스와 같다(소스의 `\{`는 보간 이스케이프).

### `[3.0.0]`
Added의 이름은 `git show 3.0.0:quad-types/src/init.luau`의 `Quad`·`State`·`Source`·`Store`·`Blocker`·`Ref`·`Modifier`·`Slot`·`EffectHandle`·`Observer`·`Context`·`Tag`·`Attr` 타입과 `3.0.0:quad-roblox/src/{RobloxFactory,Tween,types}.luau`·`src/D/init.luau`(`New`·`Mapper.Root`)에 전부 있다. 이 절은 3.0.0 시점 이름(`D`, `:With`, `Operator.Index`, `Owned` 언급 없음)으로 쓰여 있어 HEAD 이름 오염 없음. Changed/Removed의 v1 쪽 이름(`Corner`/`PaddingAll`/`PaddingAllOffset`/`Scale`/`RoundSize` — `2.24:src/class.lua:41-101`, `GetObjects`/`AddObject`/`CreatedAsync`/`RunTweens`/`StopTween`/`IsTweening`/`UpdateTriggers`/`EmitPropertyChangedSignal`/`Disconnecter`/`tracker`/`Getter`/`Setter`/`GetStore`/`AfterRender`/`Unload` 등)은 2.24 소스에 전부 존재. 링크 둘(`docs/how-to/08-migrating-from-v1.md`·`docs/overview/02-from-v1.md`)은 세 태그와 HEAD에 모두 있음.

### `2.x`
헤딩 버전 집합이 v1 원문 `v1-master:md/kr/changelogs.md`의 헤딩과 정확히 같다(2.10·2.16 없음). 인용 해시 17개 전부 `v1-master` 조상, 작성일(KST)이 각 헤딩 날짜와 일치, `dd980aa`만 2.24 태그 뒤(절이 "미배포 2.25"라 적은 그대로). 태그 `2.24` → `81d981d` 일치. 버전 상수 여섯 값(`1.14`·`2.14`·`2.18`·`2.22`·`2.24`·`2.25`)과 첫 등장 커밋(`7361c01`·`723d3f9`·`0689ad8`·`80242eb`·`dd980aa`)도 서문 서술과 일치. 내용 샘플 10(2.25 GetChildren/ChildAdded, 2.23 MountOne·`"Back"`·Ended/OnStepped 주석 처리, 2.22 `04916eb`, 2.18 AddObject, 2.17 CallBack 인자, 2.15 CurrentLocale/FailedMessage, 2.11 `&`, 2.9 PreloadAsync, 2.8 exports) 전부 해당 커밋 diff에 근거 있음.

## 중복·순서(`[Unreleased]` ↔ 릴리즈 절)
3.2.0 태그 시점 `[Unreleased]`는 안내문뿐이었고, `[3.2.0]`·`[3.1.0]` 절 본문은 각 태그 이후 HEAD까지 한 글자도 안 바뀜(`diff` 확인). `[Unreleased]`에 `Indexed`·`Declaration` 개명·`Single <Item, UD>`·`pcall`·nil 구멍 문구가 다시 나오는 줄 없음(`Indexed`/`Declaration`이 나오는 줄은 모두 3.2.0 뒤의 별개 변경). 중복 0·순서 오류 0.

## 버전 리터럴(태그 커밋)
각 태그의 트리를 스크래치에 풀어 **그 태그 시점의** `scripts/check-version.py`를 돌림 — 3.0.0/3.1.0/3.2.0 모두 exit 0(매니페스트·`quad-base` `Version`·`quad-types` `Version`·smoke·`VERSION_PATTERN` 일치). 매니페스트 다섯 + 루트 모두 태그 버전. 예외는 lock(아래 B1).

## 발견

### (a) CHANGELOG 문서 오류
없음. 소비자 언어 규약 위반(`.claude/` 경로·`H-nnn`·원장 번호)도 파일 전체에서 0건.

### (b) 릴리즈 절차 결함
- **B1** — 3.0.0 태그 커밋 `7a080e0`의 `pesde.lock` 여섯(루트·다섯 패키지)이 전부 `version = "0.0.0"`(그래프 키도 `qwreey/quad_base@0.0.0`)인데 매니페스트는 `3.0.0`이다. bump 뒤 `pesde install`을 안 돌린 상태로 태그가 달렸고, `check-version.py`는 lock을 보지 않아 통과했다. 3.1.0 bump(`01818b5`)에서 `pesde install`로 맞춰졌고 3.1.0·3.2.0 태그의 lock은 태그 버전과 같다. lock은 패키지 `includes`에 없어 게시본에는 영향 없음 — 레포 태그 시점의 불일치일 뿐.
- **B2** — 3.2.0에서 `q.D`→`q.Declaration`으로 개명했지만 게시되는 패키지 README(`includes`에 `README.md`)는 옛 이름을 그대로 적고 있다: `quad-roblox/README.md:3`("installs `D` (typed Instance constructors)"), 다섯 패키지 README 12행 표("Roblox backend (`D`, …)" — `quad-base`·`quad-roblox`·`quad-types`·`quad-error`·`type-version-check`), 루트 `README.md:43`("`D`/`Tween`/`Animate`/`OnChange`가 없습니다"). 3.2.0 태그와 HEAD 모두 같은 문장. 개명 커밋 `ba156bc2`가 "문서 43"을 고쳤지만 패키지 README는 범위 밖이었다. 원장의 `H-645`(README의 "다섯이 같은 버전" 문장)는 이 이름 문제를 다루지 않는다. 별칭 관례(`local D = q.Declaration`)로 읽으면 틀린 말은 아니나, "installs `D`"는 모듈 필드 이름으로 읽힌다.

### (c) 판단 필요
- **C1** — `[3.1.0]`의 `slot:Single` 줄은 "런타임 변화 없음"으로만 적고 BREAKING(타입만) 표시가 없다. 타입 매개변수가 `<UD>`에서 `<Item, UD>`로 바뀌어(`3.1.0:quad-types/src/init.luau` `Single`), 명시적 타입 인자로 부르던 코드(`slot:Single<<X>>(...)`)는 `X`가 `UD`에서 `Item`으로 뜻이 바뀐다. 기존 암묵 추론 호출은 넓어지기만 해서 안 깨진다. 3.2.0 뒤 `[Unreleased]`는 이런 경우에 "BREAKING(타입만)"을 쓰는 관례가 생겼는데, 그보다 앞선 절이라 표시 여부는 판단 몫(메서드 제네릭 명시 호출은 드묾).
- **C2** — `[3.0.0]` 절은 게시 뒤 `052b42e9`(2026-09-11, 3.1.0 태그 전)에서 재구성됐다. 3.0.0 태그 시점 판은 BREAKING 한 줄 + 2.x "원문 보존"이었고, 그 판의 2.x 서문("2.25는 `2.25B`", "버전 상수는 2.18에 처음 생겨")은 재구성판과 모순된다 — 재구성판이 맞다(v1 상수 이력 `1.14`→…→`2.25`, `2.25B` 없음). CHANGELOG는 패키지에 안 실려 게시본 영향은 없고, 릴리즈된 절을 사후 수정하는 것 자체를 허용할지는 정책 판단.
- **C3**(사소) — `3.1.0` 주석 태그 메시지("Operator.Index → Indexed, Slot:Single <Item, UD>, nil 구멍 에러 문구")가 같은 절의 Fixed(`pcall` 제거)를 빠뜨림. `3.2.0` 태그 메시지는 버전 문자열뿐.

## 미완
- 3.0.0 절 Changed 가운데 동작 서술(타입 검사 플래그 넷이 "없으면 실패", 정리·수명 서술, 에러 모양)은 3.0.0 시점에서 실행으로 재확인하지 않았다(이름 존재만 대조).
- `docs/` 공개 이름 변화는 CHANGELOG 대조 범위에서 이름 개명(`D`→`Declaration`, `Index`→`Indexed`)만 확인. 문서 본문 전수는 하지 않음.
- 2.x 내용은 지시대로 샘플 10줄만.
