# 구현 전 QA **5라운드** — 새 영역 + 심화 문항지

**상태**: **[2026-08-21] 완료·종결.** 작성 → 사용자 회신(`-response.md`) →
4차에 걸친 처리로 전량 반영 완료. **처리 결과의 소스는
`pre-implementation-qa-round5-followup.md`**(마지막 절이 최신) — 이 파일은
4라운드와 같이 **문항지 원본 그대로** 남긴다.

**왜 이 라운드가 있는가**: 사용자 요청 — *"5차 qa 를 할게, 4차에서 예로
넘어갔던건 스킵하고, 새로운 부분들이나 다른 깊은 부분을 예가 나와야 정상인
질문들을 쌓아보자."* 4라운드(510문항)는 `base/` 전 문서의 확정 주장을
**한 겹으로 전수** 훑었고, 그중 실제로 "아니오"가 나온 것들은 이미
`-followup.md`가 전량 처리했다. 그래서 이번엔 같은 자리를 다시 묻지 않고
아래 셋에만 집중한다:

1. **4라운드에 문항이 아예 없던 영역** — 신규 문서 `base/project-setup-plan.md`/
   `base/quad-types-plan.md`, 그리고 **문서가 아니라 실제로 커밋된 M1 코드**
   (`quad-base/src`, `quad-types/src`, `type-version-check/src`). 4라운드는
   `base/` 문서만 대상이었다.
2. **4라운드 회신 이후에 새로 확정된 것** — `Detach` 보존 주체
   (`slot._detached`), `KeyGone`, `Owned`, `attachSlot` 분해
   (`materializeSlotTree`/`mountSlotTree`), raw 3형제, `settle`/`releaseElement`,
   "부기가 물리보다 먼저"의 일반 계약 승격, flatten의 `ProcessedModifier`,
   `recompute`의 `nil` → `error`, `Tween<T>:Map`, `RunInit` 재설계 등. 전부
   **확정된 지 하루도 안 된 것들**이라 4라운드가 검증한 적이 없다.
3. **4라운드가 얕게만 훑은 큰 문서의 심화** — 예: `debounce-throttle-plan.md`는
   1100줄이 넘는데 4라운드 문항은 9개뿐이었다. 이번엔 그 안의 실제 의사코드/
   상태 전이/에러 경로를 묻는다.

**그래서 문항의 성격이 4라운드와 다르다.** 4라운드가 "문서에 적힌 확정을 그대로
문장으로 옮긴 것"이었다면, 이번엔 **문서가 명시적으로 말하지 않았지만 설계상
따라나와야 하는 귀결**을 많이 묻는다 — 그게 "아니오"가 나올 확률이 높은
자리이기 때문이다. 그런 문항은 `⭐`로 표시했다.

**회신 방법**: 각 문항은 `예/아니오`로 답할 수 있게 썼다. **`아니오`인 것만**
알려주면 되고(어디가·어떻게 틀렸는지 + 원래 뭐가 맞는지), 판단이 애매하면
"보류"라고만 해도 된다 — 4라운드처럼 풀어 쓴 답을 followup에 준비하겠다.

**표기**: `X-N`의 `X`는 영역 코드, `N`은 그 영역 안 문항 순번. **4라운드와
코드 체계가 다르다**(4라운드 `S-1`과 이 문서의 코드는 무관) — 이번엔 문서
단위가 아니라 **주제 단위**로 묶었다.

| 코드 | 영역 | 주 대상 |
|---|---|---|
| `PS` | 프로젝트 셋업 (4라운드 문항 없음) | `base/project-setup-plan.md` |
| `QT` | quad-types / 버전 체크 (4라운드 문항 없음) | `base/quad-types-plan.md` |
| `IM` | **실제 커밋된 M1 코드** (문서 아님) | `quad-base/src`, `quad-types/src`, `type-version-check/src` |
| `DE` | `Detach`/`_detached`/`KeyGone`/`Owned` (신규 확정) | `base/slot-plan.md` |
| `AS` | `attachSlot` 분해 (신규 확정) | `base/slot-plan.md`, `research/slot-attach-decomposition.md` |
| `DC` | 디스패치 코어 심화 | `base/dispatch-core-plan.md` |
| `SS` | Source/State 심화 | `base/source-state-plan.md` |
| `LC` | 생명주기 배관 심화 | `base/lifecycle-pattern.md`, `base/relate-plan.md` |
| `EF` | Effect/Observer 심화 | `base/effect-plan.md` |
| `MO` | Modifier 심화 | `base/modifier-plan.md` |
| `AT` | Attribute/Tag 심화 | `base/attribute-plan.md`, `base/tag-plan.md` |
| `TW` | Tween/숏핸드 심화 | `base/tween-plan.md`, `base/ui-shorthand-plan.md` |
| `DT` | Debounce/Throttle 심화 | `base/debounce-throttle-plan.md` |
| `ML` | 모듈 생명주기 심화 | `base/module-lifecycle-plan.md` |
| `TL` | 타입 한계 심화 | `base/typing-limits.md`, `base/store-plan.md` |
| `CR` | **크로스컷** — 여러 문서에 걸친 상호작용/순서/에러 경로 | 여러 문서 |

## 문항 수와 읽는 순서

**총 205문항**(이 문서가 그 수의 소스 — 다른 곳에 적지 않는다). 4라운드가
510문항이었던 것에 비해 적은 건 범위를 줄였기 때문이지 깊이를 줄인 게 아니다
— 이미 "예"로 넘어간 자리를 다시 묻지 않는다.

### 읽는 순서 권고

**작성한 에이전트의 추정이지 확정이 아니다.**

1. **`DE`/`AS`** — 어제 확정돼 아직 아무도 재심사 안 한 것. 잘못 굳으면
   M6 구현 전체가 그 위에 얹힌다.
2. **`IM`** — 유일하게 **실제로 돌아가는 코드**를 묻는 영역. 문서와 코드가
   갈라졌다면 여기서 드러난다.
3. **`CR`** — 문서 하나만 봐서는 안 보이는 자리라 stale이 가장 잘 낀다.
4. **`PS`/`QT`** — 새 문서. 확정이 맞는지보다 "이 결정을 계속 유지할
   것인가"(예: `pesde.lock` 커밋, symlink 수동 치환)를 묻는 문항이 섞여 있다.
5. **나머지** — 순서 무관.

---

## PS. `base/project-setup-plan.md` — 프로젝트 셋업 (4라운드 문항 없음)

### PS-1 — pesde 전환의 판정 기준
wally → pesde 전환의 근거는 "네이티브 workspace가 있다"가 아니라 **dev-dependency
1급 지원 등 툴링 전반이 낫다**는 사용자 판단이고, 모노레포 모양(루트 통합 개발 +
서브패키지별 독립 게시)이라는 **결론 자체는 wally 시절과 안 바뀌었다**. pesde의
workspace 기능은 그 모양에 맞아떨어진 부수 이득이다. → **예/아니오**

### PS-2 — 폴더 이름과 패키지 이름이 다르다
폴더는 하이픈(`quad-base`), `pesde.toml`의 `name`은 언더스코어(`qwreey/quad_base`)로
**의도적으로 다르게** 간다 — pesde 패키지 이름이 `a-z`/`0-9`/`_`만 허용해서다.
폴더 이름을 언더스코어로 통일하지 않는 이유는 `architecture.md`가 이미 확정한
소스 트리를 흔들지 않기 위해서다. → **예/아니오**

### PS-3 — 워크스페이스 의존성은 손으로 적는다
`pesde add`는 레지스트리 검색 전용이라 로컬 워크스페이스 형제를 못 찾는다.
`[dependencies]`의 `workspace = "scope/name"` 줄은 **항상 손으로 쓴다**. 이건
버그가 아니라 pesde의 설계이므로 우회 스크립트를 만들 계획도 없다. → **예/아니오**

### PS-4 — target이 다르면 `target =`을 명시
`quad-types`(target `roblox`)가 `type-version-check`(target `luau`)에 의존할 때는
`{ workspace = ..., version = "^", target = "luau" }`처럼 target을 명시해야 하고,
빠뜨리면 `no workspace member found ... and target roblox`로 **install 자체가
실패**한다(조용히 넘어가지 않는다). → **예/아니오**

### PS-5 — 툴체인은 mise, rokit은 폐기
`rokit.toml`은 완전히 폐기하고 `mise.toml`로 간다 — `pesde`/`rojo`/`luau-lsp`/
`selene` 넷을 핀한다. 채택 근거의 절반은 "이 샌드박스가 이미 mise를 쓰고 있어서
실제로 검증할 수 있었다"는 것이고, rokit은 끝내 한 번도 직접 검증하지 못했다.
→ **예/아니오**

### PS-6 — ⭐ `luau` 자체는 툴체인 핀에 없다
`mise.toml`이 핀하는 건 위 넷뿐이고 **`luau`/`luau-analyze` 자체는 안 핀한다** —
지금은 샌드박스가 제공하는 버전을 그대로 쓴다. 타입 스파이크 결과가 솔버 버전에
민감하다는 걸 `typing-limits.md`가 이미 아는데도 이걸 안 핀해둔 건 **의도된
현재 상태**이고, 사람이 로컬에서 다른 luau 버전으로 돌리면 결과가 갈릴 수 있다는
걸 감수한다. → **예/아니오**

### PS-7 — darklua 미채택의 정확한 경계
darklua를 안 쓰는 근거는 "Roblox가 require-by-string을 지원해서"가 아니라 더
좁다 — **예약 alias(`@self`/`@game`)는 darklua가 아예 안 건드리고 런타임이
직접 처리**하는 반면, **커스텀 alias(`@pkg` 등)는 darklua 같은 빌드 스텝
없이는 배포 시점에 해소된다는 근거가 없다.** quad가 커스텀 alias를 안 쓰기
때문에 지금은 불필요할 뿐이고, `@pkg/quad_base`류를 도입하고 싶어지는 순간
darklua(또는 동급 변환)가 실질적으로 필요해진다. → **예/아니오**

### PS-8 — `init.luau` 안의 상대경로 기준점
`init.luau` 안에서 `./X`는 **그 폴더의 형제**를 가리키므로, 같은 폴더 안 형제
파일에 접근하려면 `@self/X`를 써야 한다. 그래서 `quad-base/src/init.luau`는
`require("@self/Relate")`이고, `quad-base/src/Debug/init.luau`가 부모 폴더의
`Relate.luau`를 가져올 땐 `require("./Relate")`(`../Relate`가 아님)가 맞다.
→ **예/아니오**

### PS-9 — ⭐ 이 규칙이 조용히 깨진다
`@self` 대신 `./`를 쓰는 실수는 **런타임에선 크래시하지만 `luau-analyze`는
진단 0건으로 조용히 통과**한다(`Unifiable<Error>`로 샘). 즉 정적 검사만
돌리는 라운드는 이 실수를 절대 못 잡으므로, `init.luau`를 새로 추가하는
커밋은 **반드시 런타임으로 한 번 require해봐야** 한다. → **예/아니오**

### PS-10 — symlink 함정의 범위
`pesde install`이 워크스페이스 의존성을 symlink로 걸고, Luau standalone CLI의
require-by-string은 **보안상 의도적으로 symlink를 안 따라간다**. 이건 Rojo/Studio
경로와는 무관하고(`rojo sourcemap`/`rojo build` 둘 다 투명하게 통과함을 실측),
**순수하게 `luau`/`luau-analyze` CLI 실행만의 문제**다. → **예/아니오**

### PS-11 — ⭐ 그 우회는 아직 수동이다
지금 쓰는 우회는 "`pesde install` 후 `roblox_packages/.pesde/`의 심볼릭 링크를
실제 디렉토리 복사본으로 손으로 치환"이고, **스크립트/mise task로 정식화하지
않았다.** 다음 세션이 CLI 테스트를 돌리려면 같은 수동 작업을 반복해야 한다.
이 상태를 계속 두는 게 맞고, 정식 스크립트화는 "실제로 자주 아파질 때" 하면
된다. → **예/아니오**

### PS-12 — ⭐ 그런데 이 우회가 이제 출하 소스에도 걸린다
`quad-base/src/init.luau`가 `require("./roblox_packages/quad_types")`를 쓰게
되면서, 이 함정은 더 이상 "스파이크/mock 테스트에만 해당"이 아니다 — **실제
출하 진입점이 CLI에서 안 도는 상태**다. 그래도 배포 경로(Rojo/Studio)는 멀쩡하니
문제로 취급하지 않는 게 맞다. → **예/아니오**

### PS-13 — 패키지별 `selene.toml`
`selene`의 config 탐색이 파일 트리를 거슬러 올라가지 않고 **CWD 고정**이라,
루트 단일 설정을 두면 Luau 타입 문법이 전부 가짜 파싱 에러로 쏟아진다. 그래서
패키지마다 `selene.toml`을 두고 **항상 패키지 디렉토리 안에서** 실행한다.
→ **예/아니오**

### PS-14 — ⚠️ `pesde.lock` 커밋 여부는 아직 확정이 아니다
루트 1개 + 멤버마다 1개씩 생기고, **셋 다(=전부) 커밋**하는 게 지금의 **잠정**
권고다("게시물에 안 들어가므로 라이브러리 lockfile 딜레마가 성립 안 함"). 이건
아직 사용자 확정이 아니라 열려 있는 항목이 맞다. → **예/아니오**

### PS-15 — 아직 검증 안 된 것 셋
(a) 루트 `pesde.toml`의 `[target]`이 실제로 의미가 있는지, (b) Studio 실물
동기화(계정 분리 대기), (c) `roblox_sync_config_generator` 미설정 WARN의 실제
영향 — 셋 다 **지금은 방치가 맞고**, 실제로 문제가 드러날 때 열면 된다.
→ **예/아니오**

### PS-16 — `.luaurc` alias는 편집기 전용
`.luaurc`의 `quad-base`/`quad-roblox` alias는 런타임 require에서 **여전히 안
먹는다**(`could not jump to alias`). 이건 위 symlink 문제와 **다른 원인**이고,
`@self`가 예약 alias라 항상 동작하는 것과도 구분된다. alias는 편집기 자동완성/
타입체크용으로만 남긴다. → **예/아니오**

### PS-17 — ⭐ 패키지 디렉토리 이름은 의존 대상의 target을 따라간다
`roblox_packages/`와 `luau_packages/`가 갈리는 기준은 **의존하는 쪽**이 아니라
**의존 대상 패키지 자신의 target**이다. 그래서 `quad-types`(roblox)가
`type-version-check`(luau)를 쓸 때 경로가 `./luau_packages/type_version_check`가
된다. → **예/아니오**

### PS-18 — ⭐ CI가 없고, 당분간 만들 계획도 없다
이 저장소엔 `.github/` 워크플로가 없고, 스모크 테스트(`quad-base/test/*.luau`)는
**사람이나 에이전트가 직접 `luau`로 돌리는 것**이 전부다. `mise task`/`Justfile`
같은 태스크 러너도 아직 없다. M2 이후 코드가 붙기 시작해도 당분간 이 상태로
가는 게 맞다(테스트 하네스 자체가 ROADMAP 항목). → **예/아니오**

### PS-19 — ⭐ 테스트는 게시물에 안 들어간다
`quad-base/pesde.toml`의 `includes = ["src/*"]`라 `test/`는 게시 대상이 아니다.
그래서 테스트가 프로덕션 의존성을 늘리는 걱정 없이 자유롭게 mock을 둘 수 있고,
반대로 **소비자가 mock을 재사용할 방법은 없다**(의도된 것 — 필요해지면
`quad-mock`이 백로그에 있음). → **예/아니오**

---

## QT. `base/quad-types-plan.md` — 타입 계약 패키지 + 버전 체크 (4라운드 문항 없음)

### QT-1 — `quad-types`가 존재하는 진짜 이유
문제의 뿌리는 "타입만 쓰는 require도 **런타임에 실제로 실행된다**"는 Luau 사실
하나다. 그래서 `quad_base`를 dev-dependency로만 두면 게시 후 소비자 환경에서
그 require가 **그 자리에서 크래시**한다. `quad-types`는 "항상 안전하게 실
의존성으로 둘 수 있을 만큼 작은 것"이라는 자리를 채운다. → **예/아니오**

### QT-2 — 폴더로는 못 나눈다
pesde workspace 의존은 **패키지 단위**라 `quad-base/types/` 같은 서브폴더 의존
문법이 없다. 그래서 "가벼운 타입만" 효과를 실제로 얻으려면 반드시 별도
워크스페이스 멤버여야 한다. → **예/아니오**

### QT-3 — quad-base도 자기 타입을 재선언하지 않는다
`quad-base`는 `Quad` 타입을 스스로 선언하지 않고 `type Quad = QuadTypes.Quad`로
가져다 쓴다 — 진실을 한 곳에 두고, 구현이 계약과 어긋나면 구조적 타입에러로
자연히 드러나게 하기 위해서다. → **예/아니오**

### QT-4 — 이 패턴을 모든 백엔드가 따를 필요는 없다
`quad-spring`/`quad-spring-roblox` 같은 쌍은 타입 분리 없이 그냥 일반 의존성으로
둬도 된다. `quad-types` 분리는 **사실상 모든 패키지가 의존하는 핵심 계약**일
때만 값어치가 있다. → **예/아니오**

### QT-5 — `Version`은 리터럴 타입
`Version: "0.0.0"`은 `string`이 아니라 싱글턴 리터럴이고, 그 자체만으로도 이미
구조적 타이핑이 버전 불일치를 어느 정도 잡는다. `CheckVersion`이 더해주는 건
**감지**가 아니라 **사람이 읽을 수 있는 진단 메시지**다. → **예/아니오**

### QT-6 — `AddPlugin<Self, P>`의 `Self`는 반드시 제네릭
`Self`를 `Quad`로 고정하면 두 번째 `AddPlugin`이 첫 확장을 잃는다. 제네릭이라
`Quad & A & B`로 누적되는 게 실측 확인됐고, 플러그인 추가 전 그 메소드에
접근하면 정확히 `Key 'X' not found`로 거부된다. → **예/아니오**

### QT-7 — 런타임 `AddPlugin`은 mutate + 같은 테이블 반환
새 테이블을 만들지 않고 `self`를 직접 mutate해 그대로 반환한다 — `RunInit`의
멱등 추적이 `module` identity에 의존하므로, 새 테이블을 반환하면 그 추적이
끊기기 때문이다. → **예/아니오**

### QT-8 — ⭐ 그래서 플러그인 키 충돌은 조용히 덮어쓴다
`AddPlugin`이 확장 테이블의 필드를 그냥 대입하므로, **두 플러그인이 같은 키를
제공하면 나중 것이 이긴다** — 경고도 에러도 없다. 지금은 이걸 방어하지 않는
게 맞고, 실제로 충돌이 관측되면 그때 다룬다. → **예/아니오**

### QT-9 — `type-version-check`를 뺀 이유
정확 일치만 보면 독립 게시되는 플러그인 쌍(`quad-spring-roblox`류)이 매번
재게시를 요구받게 된다. 그래서 글롭/캐럿 패턴을 지원하는 **quad 비종속** 패키지로
분리했고, 파일 안에 `Quad`류 이름을 절대 안 섞는다(나중에 독립 저장소로
분리 예정이므로). → **예/아니오**

### QT-10 — 패턴 문법
`.`로 나뉜 각 자리가 `"*"`(와일드카드) / `"N^"`(N 이상) / 그 외(정확 일치)다.
자릿수가 다르면(`"0.0"` vs `"0.0.0"`) 그냥 불일치다. → **예/아니오**

### QT-11 — `type function`은 바깥 로컬을 못 본다
`Type function cannot reference outer local 'X'`로 **컴파일 자체가 실패**하므로,
런타임 `matchesPattern`과 `CheckVersion` 내부 매칭은 물리적으로 중복된 두 함수다
— 하나를 고치면 반드시 다른 하나도 고쳐야 하고, 이 중복은 없앨 방법이 없다.
→ **예/아니오**

### QT-12 — 함정 1: `error()` 대신 `print` + `types.never`
`type function` 안에서 `error()`를 부르면 "이 type function이 실행에 실패함"으로
판정돼 메시지가 안 뜬다. `print(...)` + `return types.never` 조합만 호출부에
`TypeError: <메시지>`로 뜬다. → **예/아니오**

### QT-13 — 함정 2: lazy 평가라 필드를 실제로 참조해야 한다
`local _ = checked.__versionCheck` 줄이 빠지면 **검사가 조용히 스킵**된다.
함수 본문 안의 로컬 타입 별칭(`type _Check = ...`)으로는 제네릭 인스턴스화
시점에 재평가되지 않아 아무 진단도 안 뜬다. → **예/아니오**

### QT-14 — 함정 3: `type function`을 거친 이력만으로 오염된다
패스스루(`return t`)여도 그 타입에 이후 `AddPlugin` 같은 제네릭 self 메소드를
부르면 `Expected this to be exactly 'P & Self', but got 'P & Self'`처럼 앞뒤가
같은 진단을 내며 깨진다. 그래서 `CheckVersion`은 원본을 **절대 반환하지 않고**
트리비얼한 `true`만 반환하며, 결과는 별도 필드(`__versionCheck`)로 완전히
격리한다. → **예/아니오**

### QT-15 — ⭐ 그 교훈은 일반 규칙이다
"검증/변형용 `type function`은 원본 타입을 절대 반환하지 말고 트리비얼한 마커만
반환해 별도 필드로 격리한다"는 건 이 한 사례의 우회가 아니라 **앞으로 quad가
`type function`을 쓸 때마다 따를 규칙**이고, `typing-limits.md`의 설계
체크리스트에 들어가야 한다. → **예/아니오**

### QT-16 — ⭐ 버전 문자열이 세 곳에 하드코딩돼 있다
지금 `"0.0.0"`은 (1) `quad-base/pesde.toml`의 `version`, (2) `quad-types`의
`Quad.Version` 리터럴 타입, (3) `quad-base/src/init.luau`가 대입하는 실제 값 —
**세 곳**에 각각 적혀 있고, 이걸 동기화해주는 기계 장치는 없다(주석의
"항상 맞출 것"이 전부). 버전을 올릴 땐 사람이 셋을 같이 고쳐야 하고, 지금
단계에선 그게 맞다. → **예/아니오**

### QT-17 — ⭐ `CheckedQuad`는 소비자가 자기 패턴을 고른다
`Pattern`이 타입 파라미터인 이유는 관계마다 엄격도가 달라야 하기 때문이다 —
같은 모노레포에서 함께 개발되는 quad-base/quad-roblox는 `"0.0.0"`(정확 일치),
독립 게시되는 플러그인은 `"0.*.*"` 같은 느슨한 패턴. **quad가 강제하는 기본
패턴은 없다.** → **예/아니오**

### QT-18 — ⭐ 런타임 버전 체크는 안 만든다
`CheckedQuad`는 **컴파일 타임 전용**이고, 런타임에 버전을 비교해 error를 내는
경로는 만들지 않는다(그러려면 quad-roblox 소스에 버전을 하드코딩해야 하는데
과하다는 사용자 판단). `type-version-check`가 런타임 `matchesPattern`을
export하는 건 테스트/문서화용이지 quad가 그걸 부르기 위한 게 아니다.
→ **예/아니오**

### QT-19 — `quad-roblox-types`는 백로그, 다만 관례는 지금부터
`quad-roblox`의 공개 타입을 단일 `src/init.luau`(또는 `types.luau`)에 몰아두는
관례는 **지금부터** 지킨다 — 나중에 `quad-roblox-types`를 쉽게 뽑기 위해서다.
패키지 자체를 지금 만들 필요는 없다. → **예/아니오**

---

## IM. 실제로 커밋된 M1 코드 (문서가 아니라 코드가 대상)

**이 영역만 성격이 다르다** — 4라운드는 `base/` 문서만 봤고, 아래는 지금
저장소에 실제로 들어 있는 `quad-base/src/init.luau`, `quad-base/src/Relate.luau`,
`quad-base/src/Debug/init.luau`, `quad-types/src/init.luau`,
`type-version-check/src/init.luau`, `quad-base/test/*`를 읽고 뽑은 문항이다.
**"문서가 이렇게 말한다"가 아니라 "코드가 실제로 이렇게 돼 있다"를 묻는다.**

### IM-1 — 최상위 반환값
`quad-base/src/init.luau`는 `return New()`로 **이미 만들어진 인스턴스**를
반환하고, 그 인스턴스가 자기 필드로 `New`를 갖는다. 즉 `Quad.New()`는 지금도
호출 가능한 상태이고, `architecture.md`가 말한 "지금 단계에선 `New` 필드가
아직 노출되지 않는다(싱글톤)"는 **더 이상 코드와 안 맞는다**(코드 쪽이
맞고 문서 표현이 stale). → **예/아니오**

### IM-2 — 메소드는 인스턴스마다 새 클로저
`RunInit`/`AddPlugin`은 공유 메타테이블이 아니라 `New()` 안에서 **매 인스턴스마다
새로 만들어지는 클로저**다. `New()`가 사실상 한 번만 불리는 지금은 이 비용이
무의미하고, 메타테이블로 바꿀 이유가 없다. → **예/아니오**

### IM-3 — 멱등 기록은 파일 스코프 `Relate` 하나
`runInitRelate`는 `New()` 안이 아니라 **파일 스코프**에 하나뿐이고, `module`을
weak 키로 쓴다. 그래서 `New()`로 만든 인스턴스들이 서로의 `RunInit` 기록을
공유하지 않으면서도(키가 다름) 별도 정리 코드가 필요 없다(module이 GC되면
기록도 같이 사라짐). → **예/아니오**

### IM-4 — 실행 전에 먼저 표시한다
`runInitRelate:SetStrong(self, initFn, true)`를 `initFn(self)` **호출 전에**
찍는다 — 순환 의존(`InitA`가 `InitB`를 부르고 그 반대도)에서 무한 재귀를
막기 위해서다. 그 결과 **`initFn`이 도중에 error를 던져도 "실행됨"으로
기록이 남고**, 다시 `RunInit`해도 재실행되지 않는다. 이건 알려진 트레이드오프로
그대로 두는 게 맞다. → **예/아니오**

### IM-5 — ⭐ `:: Quad` 캐스트가 타입 구멍을 만든다
`New()` 안에서 `module`은 `New`/`Version` 두 필드만 가진 채 `:: Quad`로
캐스트되고, `debug`는 그 뒤 `module:RunInit(InitDebug)`가 채운다. 그래서
**`RunInit(InitDebug)` 줄을 실수로 지워도 타입 에러가 안 나고** 런타임에
`Quad.debug`가 `nil`이 될 뿐이다(스모크 테스트만이 이걸 잡는다). 지금
단계에선 이 구멍을 감수하는 게 맞다. → **예/아니오**

### IM-6 — `InitDebug`는 자기 가드를 안 둔다
`Debug/init.luau`는 "이미 초기화됐는가"를 스스로 확인하지 않는다 — 멱등성은
**전적으로 호출부(`module:RunInit`)의 책임**이다. 앞으로 추가되는 모든
`InitXxx`도 같은 규약을 따른다(각자 가드를 두지 않는다). → **예/아니오**

### IM-7 — `Relate` 구현이 계획과 일치하는지
실제 `Relate.luau`는 (a) 바깥 `buckets`가 `__mode = "k"`, (b) 버킷과
`StrongMap`/`WeakMap`이 **각각 lazy 생성**, (c) `WeakMap`의 메타테이블은
파일 스코프 `WEAK_VALUE_MT` 하나를 모든 맵이 공유, (d) `Get*`는 서브맵이
없으면 만들지 않고 그냥 `nil` — `relate-plan.md`의 "실제 구조" 절 그대로다.
→ **예/아니오**

### IM-8 — ⭐ 삭제 API가 없다
`Relate`의 공개 표면은 `SetStrong`/`GetStrong`/`SetWeak`/`GetWeak` 넷뿐이고,
**`Delete`/`Clear` 같은 명시적 삭제 메소드가 없다** — 지우려면
`SetStrong(inst, key, nil)`을 부른다. `relate-plan.md`가 "명시적으로 만든 기록은
명시적으로 지울 것"이라고 강하게 요구하는데도 전용 API를 안 두는 게 맞다
(`nil` 대입으로 충분하므로). → **예/아니오**

### IM-9 — ⭐ 빈 버킷은 회수되지 않는다
어떤 `inst`의 마지막 키를 `nil`로 지워도 그 `inst`의 버킷 테이블(그리고 빈
`StrongMap`/`WeakMap`)은 그대로 남는다 — 버킷 자체는 `inst`가 GC될 때만
사라진다. 빈 버킷을 즉시 청소하는 로직은 **일부러 안 넣는다**(살아있는
`inst`당 작은 테이블 하나이고, 청소하면 다음 `Set`에서 다시 만들어야 함).
→ **예/아니오**

### IM-10 — `AddPlugin`의 런타임 계약
`pluginFn(self)`의 반환값을 **일반화 `for`로 순회해 그대로 `self`에 대입**한다.
그래서 (a) 반환값이 테이블이 아니면 그 자리에서 런타임 에러, (b) 배열
파트/해시 파트 구분 없이 전부 복사, (c) 검증/충돌 체크는 전혀 없다 — 지금
단계에선 이게 맞다. → **예/아니오**

### IM-11 — ⭐ 플러그인은 `self`를 이미 받는다
`pluginFn`이 인자로 받는 `self`는 **아직 자기 확장이 반영되기 전의 module**이다.
그래서 플러그인이 자기 확장 필드를 그 시점에 `self`에서 읽을 수는 없고,
반대로 자기가 반환하는 테이블 안에서 클로저로 `self`를 캡처하는 건 자유다
(그때는 이미 mutate가 끝나 있으므로). → **예/아니오**

### IM-12 — 테스트는 프레임워크 없는 assert 스크립트
`quad-base/test/*.luau`는 `assert` + `print("PASS")` 조합이고 테스트 러너가
없다 — 사람이/에이전트가 `luau quad-base/test/smoke.init.luau`처럼 직접
돌린다. 실패는 assert가 그 자리에서 터지는 것으로 표현된다. M2 이후에도
당분간 이 형태로 간다. → **예/아니오**

### IM-13 — mock의 의도적 범위 축소
`test/mock.luau`는 parent/children 트리 + 타입 검증 없는 property bag +
property별 변경 시그널만 만들고 `IsA()`/클래스별 스키마/`WaitForChild`를
안 만든다. Vide mock의 GC-독립 userdata 프록시 트릭도 **일부러 안 쓴다**
(그건 quad-roblox의 gcconn 트릭이 다루는 자리라 quad-base 정적 테스트
범위 밖). → **예/아니오**

### IM-14 — ⭐ 지금 코드에 없는 것
현재 `quad-base/src`에는 `Dispatch`도 `Source`/`State`도 `Slot`도 없고,
`Relate`/`Debug`/모듈 골격뿐이다. 즉 **4라운드·5라운드가 검증하는 설계 중
실제 코드로 존재하는 건 `Relate`와 모듈 생명주기뿐**이고, 나머지는 전부
의사코드 상태다. 이 인식이 맞다. → **예/아니오**

---

## DE. `Detach` / `_detached` / `KeyGone` / `Owned` — 2026-08-21 신설 확정

**4라운드 회신 이후에 확정된 것들이라 아직 아무도 재심사하지 않았다.**

### DE-1 — 보존 주체가 필드여야 하는 이유
detach된 요소를 `userdata`가 아니라 `slot._detached` **필드**가 들고 있어야 하는
이유는 셋 다다 — (1) `userdata`는 opaque라 `:List`가 뭘 죽여야 할지 모르고,
(2) 소유권 기록이 Slot에 남아야 남이 못 가져가고, (3) `destroySlotTree`의 walk가
닿아야 한다. → **예/아니오**

### DE-2 — GC 폴백이 아예 없다
`Parent = nil`인 detach 노드는 자기 gcconn 클로저가 자기를 캡처해 **아무도 안
들고 있어도 영원히 살아남는다.** 그래서 "언젠가 GC가 치운다"가 성립하지 않고
명시적 정리 경로가 필수다. → **예/아니오**

### DE-3 — raw 3형제가 갈리는 축은 둘
`rawRemove`(반납+파괴) / `rawUnmount`(반납+안 죽임) / `rawDetach`(**유지**+안 죽임)
— "파괴하는가"와 "소유권을 놓는가"가 독립된 두 축이고, 네 번째 조합(유지+파괴)은
의미가 없어 안 만든다. → **예/아니오**

### DE-4 — 재클레임 예외는 플래그로만
`Detach` 재마운트는 `rawUnmount`를 안 거치고 곧바로 `rawAdd`를 부르므로,
`claimOwner`에 `fromDetached` 플래그가 참일 때만 통과하는 **좁은 예외**를 뒀다.
이걸 "같은 owner면 통과"로 완화하면 `Slot { a, a }`가 다시 새어나가므로 절대
완화하면 안 된다. → **예/아니오**

### DE-5 — 재-`Detach`는 nop, `prev` 반환은 재마운트
이미 `_detached`에 있는 키에 또 `Detach`를 반환하면 아무 일도 안 일어나고,
그 요소를 `prev`로 그대로 반환하면 `_detached`에서 빠지며 재마운트된다. 매
사이클 filter에 걸리는 흔한 경로라 여기서 반복 작업이 생기면 안 된다.
→ **예/아니오**

### DE-6 — `ud`로 붙잡을 필요가 없어졌다
`reconcile`이 `mounted[key] or self._detached[key]`를 `prev`로 넘기므로
`updateFn`은 `return Detach, ud`만 하면 되고, 옛 서술의 `return Detach, { old = prev }`
관용구는 폐기됐다. `ud`에 담는 것 자체는 자유지만 `:List`가 정리해주지 않는다.
→ **예/아니오**

### DE-7 — ⭐ `_detached`는 모든 Slot이 갖는다
`settle`/`destroySlotTree`가 `self._detached[key]` / `pairs(slot._detached)`를
**조건 없이** 인덱싱하므로, `_detached`는 `:List`를 설치하지 않은 Slot에도
**생성 시점에 빈 테이블로 초기화돼 있어야** 한다(안 그러면 파괴 walk가 `nil`
인덱싱으로 터진다). 즉 `_owned`처럼 "없으면 기본값"으로 다루는 필드가 아니다.
→ **예/아니오**

### DE-8 — `KeyGone`의 인자 규약
키가 사라진 자리는 `updateFn(KeyGone, 0, offset, prev, ud)`로 한 번 더 묻고,
`index`는 `0`(자리가 없으므로), `offset`은 Slot의 것을 그대로 넘긴다. 반환값
의미는 정상 사이클과 같고, `prev`를 그대로 반환하는 것만 `error`다.
→ **예/아니오**

### DE-9 — ⭐⭐ `KeyGone`에 **새 값**을 반환하면 어떻게 되나
지금 의사코드는 소멸 루프에서도 같은 `settle`을 `pos = 0`으로 부르므로, `updateFn`이
`KeyGone`에 대해 **새 요소를 반환하면** 교체 분기로 들어가 `rawAdd(self, result, 0)`,
즉 **인덱스 0에 마운트**를 시도한다(`Add`는 범위 밖 인덱스에 clamp 없이 error).
"반환값 의미는 정상 사이클과 완전히 같다"는 서술과 이 코드가 어긋난다 —
**`KeyGone`에 새 값을 반환하는 것도 `prev` 반환처럼 `error`여야** 하는 게 맞나?
(대안: 마지막 위치에 붙이기 / 조용히 무시) → **예/아니오 + 어느 쪽인지**

### DE-10 — 다시 안 묻는다
소멸 루프가 **직전 사이클의 `keyIndex`**만 순회하므로 사라진 키는 다음 사이클
대상이 아니다 — "한 번만 묻는다"를 위한 별도 플래그가 필요 없다. → **예/아니오**

### DE-11 — ⭐ 그래서 홀드된 것은 owner가 죽을 때까지 남는다
`KeyGone`에 `Detach`로 답한 요소는 (a) 키가 다시 나타나 `prev`로 부활하거나
(b) owner가 죽어 `_detachCleanup`이 정리할 때까지 **무한정 `_detached`에 쌓인다.**
키 churn이 큰 리스트에서 이게 메모리 증가로 보일 수 있다는 걸 감수하고,
잘라내는 정책(LRU/최대 개수 등)은 만들지 않는다. → **예/아니오**

### DE-12 — 정리 Effect의 소유 층위
`_detachCleanup`은 `mountSlotTree`가 아니라 **`activateList`**가 만들고,
`_listObserver`와 **완전히 같은 취급**을 받는다 — 생성 1회, 언마운트 시
앵커만 해제하고 핸들 보존, 재마운트 시 새 target에 재앵커, 파괴 시 해제 후
`nil`. → **예/아니오**

### DE-13 — cleanup이 하는 일의 순서
`_detachCleanup`의 cleanup은 각 요소에 대해 **`releaseOwner`를 먼저, 두 분기
공통으로** 부르고 그 다음에만 `_owned ~= false`일 때 파괴한다. 반납을
빠뜨리면 `Owned = false` 요소가 죽은 Slot을 owner로 달고 남아, 사용자가 그
값을 다른 Slot에 넣을 때 GC 타이밍에 따라 "이미 마운트됨" error가 난다.
→ **예/아니오**

### DE-14 — ⭐ 상태 없는 `Effect`가 이 용도의 유일한 도구다
`Effect(function() return function() ... end end)`처럼 **state 없이** 쓰는 건
"leaf가 죽을 때 cleanup 1회"만 얻으려는 것이고, `bindLifetime`은 "실행해도
되는가"만 게이팅할 뿐 죽는 순간의 콜백을 안 주기 때문에 대안이 없다.
→ **예/아니오**

### DE-15 — `Owned`는 설치 시점에 고정되는 축
`Owned`는 사이클마다 달라지는 판단이 아니라 **설치 시점 플래그**(기본 `true`)이고,
`Detach`("지금은 안 쓰지만 내 것")와 **직교**한다. 그래서 반환값 계열에
"unowned replace" 센티널을 하나 더 만들지 않는다. → **예/아니오**

### DE-16 — `_owned`는 필드여야 한다
`destroySlotTree`/`dispose`가 읽어야 하므로 클로저 업밸류가 아니라 Slot 필드
(`slot._owned`)이고, 코드는 `_owned == false` / `_owned ~= false`로 판정한다
(= 미설정이면 owned). → **예/아니오**

### DE-17 — ⭐ `Owned = false`인데 `updateFn`이 새 요소를 만들면
`Owned`는 리스트 전체 단위라, `Owned = false`로 설치된 `:List`에서 `updateFn`이
자기가 만든 새 Instance를 반환하면 **그건 아무도 파괴해주지 않는다**(밀려날
때도 언마운트만, owner가 죽을 때도 언마운트만). 이건 "혼합은 표현 못 함"의
구체적 귀결이고, 그래도 지금은 새 축을 안 만드는 게 맞다. → **예/아니오**

### DE-18 — `Slot:Add(state)` sugar가 `Owned = false`의 유일한 정규 진입점
사용자가 직접 `opts.Owned = false`를 넘길 수도 있지만, 실제로 이게 필요한
정규 경로는 **반응형 raw 요소 sugar**(`:Single` + identity `updateFn`)다.
`state<Frame>` 교체가 이전 값을 파괴하지 않는다는 확정 의미론이 이걸로 지켜진다.
→ **예/아니오**

### DE-19 — ⭐ `opts`는 네 번째 위치 인자다
`Slot:List(data, updateFn, keyFn?, opts?)`라 `keyFn` 없이 `opts`만 주려면
`nil`을 명시적으로 끼워 넣어야 한다(`slot:List(data, fn, nil, { Owned = false })`).
테이블 하나로 합치거나 named 파라미터로 바꾸지 않고 이 모양으로 간다.
→ **예/아니오**

### DE-20 — `settle`을 뽑은 이유
정상 사이클과 소멸 루프가 **같은 처분 함수**를 공유해야 두 경로가 갈라지지
않는다. 그래서 `Detach`/`nil`/`prev`/교체 네 분기가 전부 `settle` 한 곳에만
있다. → **예/아니오**

### DE-21 — ⭐ `prev`가 그대로인데 위치도 같으면 아무 일도 안 한다
`result == prev`이고 detach 상태가 아니면 `keyIndex[key] ~= pos`일 때만
`rawMove`를 부른다 — 즉 값도 위치도 그대로인 흔한 경로는 **테이블 조회
몇 번이 전부**이고 물리 트리에 손을 안 댄다. → **예/아니오**

### DE-22 — ⭐ 언마운트 중에 들어온 데이터 변경은 재마운트가 따라잡지 않는다
`unmountSlotTree`가 `_listObserver`의 앵커만 풀기 때문에 언마운트 동안의 emit은
`canExecute`에서 걸러진다. 그리고 `activateList`의 재마운트 분기는 앵커만 다시
걸고 **`reconcile`을 다시 돌리지 않는다.** 그래서 포탈로 옮겨온 Slot은 다음
emit이 올 때까지 **옛 스냅샷 그대로**다 — 이게 의도된 동작이 맞나?
(대안: 재마운트 시 1회 강제 reconcile) → **예/아니오**

---

## AS. `attachSlot` 분해 — `materializeSlotTree` + `mountSlotTree` (2026-08-21 확정)

### AS-1 — 쪼갠 건 함수가 아니라 재귀다
공개 `attachSlot`은 이름/시그니처/호출부가 하나도 안 바뀌고 몸통만 두 줄이
됐다 — 실제로 갈라진 건 **트리를 도는 재귀 자체**(부기 재귀 / 물리 재귀)다.
그래서 다른 문서의 `attachSlot` 참조가 전부 그대로 유효하다. → **예/아니오**

### AS-2 — 분해의 진짜 동기
"책임이 일곱 개라 읽기 어렵다"가 아니라, **C6("부모에게 미는 길이는 최종값")과
C7("부기가 물리보다 먼저")이 단일 함수 안에서는 `setLength` 슬롯이 하나뿐이라
원리적으로 동시 만족 불가**였다는 것이 진짜 이유다. 분해로 둘이 처음 동시에
성립한다. → **예/아니오**

### AS-3 — 순서가 함수 경계로 강제된다
`_mounted`를 켜는 코드가 `materializeSlotTree`에는 **아예 없으므로**,
`RC-3`/`RC-4` 류(한 함수 안에서 줄 순서를 잘못 잡는) 실수 클래스가 구조적으로
사라진다. 이게 "지금 의사코드를 건들이는 비용이 추후 실수 누적 비용보다 싸다"의
구체적 내용이다. → **예/아니오**

### AS-4 — `materializeSlotTree` 안의 순서
`setOffsetSource`(즉시 계산) → `slot.Offset` 대입 → (`_listed`면) `activateList`
→ `blocker:On()` → 자식 루프(재귀 또는 `setOffsetSource(None)`+`setLength(1)`)
→ `OffWithoutEmit()` → `recompute` → **마지막에** `setLength(ownerKey, position,
slot.Length)`. 이 일곱 줄의 순서가 전부 실제로 밟은 버그에서 나온 제약이다.
→ **예/아니오**

### AS-5 — ⭐ `activateList`가 Blocker **밖**에서 불리는 게 맞나
지금 코드는 `blocker:On()`보다 **먼저** `activateList`를 부른다. 그 시점의
`:List` 최초 reconcile이 게이팅 없이 도는데도 `RC-1`류 크래시가 안 나는 이유는
**그 Slot이 아직 `_mounted == false`라 `rawAdd`가 `_elements`에만 넣고 끝나는
경로를 타기 때문**이고, 부기(`setLength`/`recompute`)를 아예 안 건드리므로
게이팅할 대상 자체가 없다. → **예/아니오**

### AS-6 — Blocker의 범위가 정의와 일치한다
이제 Blocker가 감싸는 건 **자식 등록 루프뿐**이고 물리 마운트는 감싸지 않는다
— "배치 등록 게이팅"이라는 이름과 실제 범위가 처음으로 정확히 같아졌다.
`mountSlotTree`는 Blocker가 필요 없다. → **예/아니오**

### AS-7 — 예외 시 Blocker가 켜진 채 남는 건 감수한다
자식 재귀가 예외를 던지면 `OffWithoutEmit()`에 도달하지 못해 그 Slot의
`recompute`가 영원히 게이팅되고 `Length`가 영구 stale해진다. `pcall`로 감싸지
않는 이유는 (1) 마운트 도중 예외는 quad가 복구를 보장하지 않는 상태이고
(에러 경계는 `Fallback`/`Traceback` 몫), (2) 실제로 밟은 적 없는 경로이며,
(3) 이건 분해가 만든 창이 아니라 옛 단일 `attachSlot`에도 있던 갭이기 때문이다.
→ **예/아니오**

### AS-8 — `mountSlotTree`는 정말로 물리 대입만 한다
`_mounted`/`_mountedInst` 세팅과 `Parent` 대입 재귀가 전부이고, `_detachCleanup`
설치가 `activateList`로 이관되면서 부기가 한 줄도 안 남았다. → **예/아니오**

### AS-9 — 관측 가능한 차이는 "부기 완료 후 일괄 물리"
`Parent` 대입 **순서 자체는 동일**하고(깊이 우선 같은 순서), 달라지는 건
부기와 물리가 더 이상 인터리브되지 않는다는 것뿐이다. 그래서 첫 `ChildAdded`
핸들러가 볼 때 서브트리의 `Length`/`Offset`이 이미 최종값이고(옛 코드는
`inner.Length == 0`인 미완성 스냅샷), `slot.Length` 구독자도 `0` → 최종 두 번이
아니라 최종값 한 번만 본다 — **엄밀히 더 정확해지는 방향**이다. → **예/아니오**

### AS-10 — ⭐ 재귀는 같은 `physicalTarget`을 그대로 내려보낸다
중첩이 아무리 깊어도 `materializeSlotTree`/`mountSlotTree`가 자식에게 넘기는
`physicalTarget`은 **트리 최상위의 물리 Instance 하나**다(`ownerKey`만 부모
Slot으로 바뀐다). 그래서 모든 중첩 Slot의 `bindLifetime` 앵커가 그 한 inst에
몰리고, **자식 Slot만 파괴돼도 그 inst는 살아있는 게 흔한 경우**라 파괴
경로가 `_listObserver`/자식 observer를 명시적으로 `unbindLifetime`해야 한다.
→ **예/아니오**

### AS-11 — 런타임 단건 `Add`는 여전히 게이팅 없이 `attachSlot` 한 줄
이미 마운트된 outer에 나중에 nested Slot을 `Add`하는 경로는 공개 `attachSlot`을
그대로 부르고 Blocker가 필요 없다 — 그 시점엔 앞선 모든 position이 이미 안정적으로
채워져 있어 `nil` 자리가 생길 여지가 없기 때문이다. → **예/아니오**

### AS-12 — 백엔드 seam
`mountSlotTree`가 부기를 안 건드리는 순수 walk라, 일괄 삽입이 유리한 백엔드
(웹 `DocumentFragment` 등)는 **이 함수 하나만** 갈아끼우면 된다. 그게 분해의
이득 넷 중 하나로 문서화돼 있다. → **예/아니오**

### AS-13 — ⭐ `attachSlot` 두 줄 사이에서 중단되는 상태를 정의하지 않는다
`materializeSlotTree`만 돌고 `mountSlotTree`가 아직 안 돈 중간 상태(부기는 있고
물리는 없음)는 **공개 API로 노출하지 않고**, 그 상태에 이름도 안 붙인다 —
공개 진입점이 항상 둘을 연달아 부르기 때문. 나중에 "prepare만 하고 나중에
mount"를 실제로 원하게 되면 그때 표면을 만든다. → **예/아니오**

### AS-14 — ⭐ `Dispatch.drive`는 같은 모양으로 안 맞춘다
분해 후보 (C)는 `Dispatch.drive`(일반 props 마운트)까지 같은 부기/물리 2단
모양으로 수렴시키는 것이었는데, 채택한 건 (B)라 **`drive`는 지금 형태 그대로**다.
Slot만 2단이고 일반 props는 아닌 비대칭을 감수한다. → **예/아니오**

---

## DC. 디스패치 코어 심화

### DC-1 — "부기 먼저"는 이제 일반 계약이다
`rawAdd` 한 곳의 관습이던 것이 **모든 `raw*`가 따르는 일반 계약**으로 승격됐고,
근거는 "일관성 있는 동작이 백엔드 작성자에게 전제를 준다"는 것이다(연산마다
선후가 다르면 백엔드가 매번 확인해야 함). → **예/아니오**

### DC-2 — 방향이 반대로 보이는 건 같은 원칙의 두 얼굴
"넣기는 부기 먼저"(`rawAdd`)와 "빼기는 물리 먼저"(`rawRemove`/`rawUnmount`/
`rawDetach`)는 모순이 아니라 **항상 좁은 쪽이 먼저**라는 하나의 원칙이다 —
빼면서 부기를 먼저 줄이면 아직 트리에 있는 요소가 순서 계산에서 빠지는
역전이 생긴다. → **예/아니오**

### DC-3 — 진짜 이유는 깜빡임이 아니다
`process`/`attachSlot` 체인 도중 코루틴 yield가 금지돼 있으므로 이 순서가
어긋나도 **사용자에게 보일 프레임이 그 사이에 없다.** 그래서 계약의 목적은
"안 지키면 깜빡인다"가 아니라 "백엔드가 전제할 수 있게 하나로 고정한다"이다.
→ **예/아니오**

### DC-4 — `Splice`와 `Move`/`Swap`
`Splice`는 "제거는 물리 먼저, 삽입은 부기 먼저"를 이어 붙인 것이고,
shift/recompute를 1회로 묶는 최적화는 **그 사이에서만** 일어난다.
`rawMove`/`rawSwap`은 `Parent`를 안 건드리므로 이 계약의 대상이 아니다.
→ **예/아니오**

### DC-5 — `recompute`의 `nil`은 skip이 아니라 `error`
`sourceList[i] == nil`은 도달 경로가 없다는 게 재추적 결론이므로(`bk.N`=실제
개수 / 배치 중엔 Blocker 게이팅 / 해제는 `None` / `spliceArraysDown`은 압축),
보이면 **부기가 깨진 것**이라 조용히 건너뛰지 않고 즉시 `error`다.
→ **예/아니오**

### DC-6 — ⭐ 그 `error`와 "Offset을 `nil`로 안 되돌린다"는 한 결정의 양면
해제 시 `slot.Offset`을 `nil`로 갈아치우지 않고 stale하게 두기로 한 것
(`SL-75` 정정)과, `sourceList`에 `nil`이 보이면 error를 내는 것은 **같은
불변식의 두 표현**이다 — "이 자리는 항상 실재하는 값(`Source` 또는 `None`)으로
채워져 있다". → **예/아니오**

### DC-7 — `bk.N`은 고정값이 아니라 그때그때 실제 개수
`setLength`가 새 최대 position을 등록할 때 늘고 `spliceArraysDown`이 줄인다.
**`setOffsetSource`는 `bk.N`을 안 건드리는데**, 그 이유는 호출 순서가 항상
`setOffsetSource(i)` → `setLength(i)`라서 `lengthList[i]`가 아직 안 채워진 채
`bk.N`만 먼저 커지는 창을 막기 위해서다. → **예/아니오**

### DC-8 — Blocker 게이팅의 현재 근거는 비용이다
`bk.N` 모델이 바뀌면서 "배치 중 `nil`을 읽어 크래시"는 더 이상 발생 경로가
아니고, 게이팅이 여전히 필요한 이유는 **등록마다 `recompute`가 도는 O(N²)를
배치 끝 1회로 줄이는 것**이다. → **예/아니오**

### DC-9 — ⭐⭐ 그런데 `setOffsetSource`의 즉시 계산이 O(N²)다
`setOffsetSource(ownerKey, i, source)`는 등록될 때마다 `bk.lengthList[1..i-1]`을
**매번 다시 합산**하므로, 배치 전체로 보면 그 자체가 O(N²)다 — Blocker로
`recompute`를 O(N²)→O(N)으로 줄인 이득이 여기서 상쇄된다. 그래도
(a) N이 보통 작고 (b) `recompute`의 비용은 순회가 아니라 `Set`이 트리거하는
다운스트림 캐스케이드라 성격이 다르므로, **누적합을 배치 상태로 들고
다니는 최적화는 지금 안 한다**가 맞나? → **예/아니오**

### DC-10 — `setOffsetSource`의 `None` 스킵
`source == None`이면 즉시 계산 자체를 건너뛴다 — 참여 안 하는 자리는 계산할
게 없기 때문이고, 이건 `recompute`가 `offset ~= None`일 때만 `Set`하는 것과
같은 판정이다. → **예/아니오**

### DC-11 — 배치 끝의 `recompute`는 명시적 1회 호출이다
`OffWithoutEmit()`이 스스로 recompute를 트리거하는 게 아니라, 배치를 연 쪽이
**끄고 나서 직접 한 번** `recompute(ownerKey, bk)`를 부른다. → **예/아니오**

### DC-12 — yield 금지는 새 방어 로직이 아니다
"`process`/`attachSlot` 체인 도중 yield 금지"는 런타임 검사를 넣겠다는 뜻이
아니라 **어기면 UB라는 계약 문서화**다(재진입/무한루프를 방어하지 않는다는
기존 원칙과 같은 톤). → **예/아니오**

### DC-13 — ⭐ 컴포넌트 함수도 그 계약 아래 있다
그래서 **사용자가 쓰는 컴포넌트 함수·`updateFn`·Handler 전부가 동기 함수여야
한다** — 안에서 `task.wait()`류로 yield하면 그 순간 UB다. 이건 quad의 공개
계약으로 문서에 나가야 하는 제약이다. → **예/아니오**

### DC-14 — `recompute` 재진입 가드는 없다
Slot마다 `Relate(자기 자신)`으로 독립된 `bk`를 가지므로 중첩만으로는 같은
`(ownerKey, bk)`가 재진입되는 경로가 없다. 사용자 코드가 `updateFn` 안에서
같은 Slot에 `Add`/`Remove`를 다시 거는 경우만 남는데 그건 사용자 버그로
간주한다. → **예/아니오**

### DC-15 — 배열 자리의 센티널 선택은 자리마다 다르다
`sourceList`/`flattened`처럼 "채워짐 여부"를 엄밀히 구별해야 하는 배열은
실재 센티널(`None`/`ProcessedPreRef`)을 쓰고, `Ref`의 콜백/대기자 배열은
**`nil`로 되돌아갔다**(`table.insert`가 구멍을 되찾아 쓰므로). 두 결정은
충돌이 아니라 서로 다른 요구에서 나온 것이다. → **예/아니오**

### DC-16 — props 순회: 계약은 그대로, 구현만 1회로
"배열 파트 전체가 해시 파트보다 먼저"는 여전히 base가 **보장하는 계약**이고
백엔드가 자기 드라이버를 짜도 지켜야 한다. 바뀐 건 quad-base 자신의 구현이
그 보장을 **단일 일반화 `for` 한 번**으로 얻는다는 것뿐이다. → **예/아니오**

### DC-17 — 그 전제는 `flattened`가 항상 평범한 Luau 테이블이라는 것
props는 사용자가 쓴 Lua 테이블 리터럴에서 오고 `flatten`도 그걸 제자리에서
뮤테이션할 뿐이라, `__pairs`/`__ipairs`를 갈아끼운 값이 들어올 경로가 없다.
**`inst`가 백엔드마다 다를 수 있다는 것과는 무관한 얘기**다. → **예/아니오**

### DC-18 — ⭐ 스파이크 `01`이 지금 계약과 안 맞는다
`luau-test/done/01-two-pass-array-hash-order.luau`는 두 루프 버전이라
재작성 대상이고, 재작성 시 확인할 것은 **"배열 파트 전체가 해시보다 먼저 +
배열 안에서는 index 순서"** 둘이다. 이 재작성은 M2 착수 전에 하는 게 맞다.
→ **예/아니오**

### DC-19 — `Get` 가드의 목적
`recompute`가 `offset:Get() ~= sum`일 때만 `Set`하는 건 순회 비용 때문이
아니라 **다운스트림 리액티브 캐스케이드**(이미 마운트된 원소들의 `LayoutOrder`
재적용)를 막기 위해서다. 같은 원칙이 `rawAdd`의 `Length:Set` 호출부에도
적용된다. → **예/아니오**

### DC-20 — `Slot.Length`는 개수가 아니라 기여도의 합
plain 요소는 1, nested Slot은 그 `.Length`를 기여한다. plain만 있는 흔한
경우엔 합 == 개수라 체감 차이가 없다. 그리고 수동 `Visible` 토글은 `Length`가
못 잡는 게 **맞다**(그건 사용자가 별도 State로 계산할 몫). → **예/아니오**

### DC-21 — 웹 백엔드는 offset 관측을 no-op으로 둔다
`insertBefore`류는 물리 삽입만으로 뒤 형제가 밀리므로, quad-web의 offset
핸들러는 아무것도 안 하고 숫자는 "다음에 스스로 insert/remove할 물리
인덱스"를 위해서만 부기된다. base 로직은 완전히 동일하다. → **예/아니오**

### DC-22 — 동적 자식의 유일한 정당 경로
`Slot` 또는 `state<Frame>`류 store-bind만이 `setLength`/`setOffsetSource`를
정확히 부르는 경로이고, 사용자가 `newInst.Parent = parentInst`로 직접 끼워
넣는 건 **방어 로직 없는 UB**다(부기가 조용히 어긋남). → **예/아니오**

---

## SS. Source/State 심화

### SS-1 — `invalid`는 전파 장치가 아니다
`invalid`는 "내 캐시가 낡았다"는 표시 하나뿐이고, 이미 `invalid`여도 신호는
그대로 아래로 전파된다. **평범한 State는 절대 신호를 삼키지 않으며**, 신호를
늦추거나 흡수할 수 있는 건 명시적 게이트(`Blocker`, 그리고 설계만 끝난 시간
기반 게이트)뿐이다. → **예/아니오**

### SS-2 — 다이아몬드에서 접는 것과 안 접는 것
중복 **재계산**은 pull + 캐시가 막고, 중복 **통지**는 의도적으로 안 막는다 —
`d` 아래의 Observer가 한 사이클에 두 번 우는 건 정상 동작이고, 접고 싶으면
`Blocker` 같은 명시적 게이트를 쓴다. → **예/아니오**

### SS-3 — 나중에 넣을 dedup은 파동 단위여야 한다
순회 비용이 실측에서 문제가 되면 "한 번의 전파 파동 안에서만 같은 노드를 두 번
방문하지 않는다"(방문 집합/에포크)를 넣을 수 있지만, **시간에 걸쳐 유지되는
`invalid` 플래그로 하면 절대 안 된다** — 그게 2026-08-14에 뒤집힌 바로 그
실수다. → **예/아니오**

### SS-4 — `table.clone`은 관측이 아니다
구조적 복사는 State 핸들을 옮길 뿐 `:Get()`을 안 부르므로 계산을 트리거하지
않는다. 그래서 Modifier의 clone 기반 체이닝과 "관측해야 실체화된다" 원칙이
충돌하지 않는다. → **예/아니오**

### SS-5 — ⚠️ 중간 State 생존은 여전히 열려 있다
`A → B → C → Observer`에서 중간 `B`/`C`를 **강하게 붙잡는 주체가 문서 어디에도
없다**는 게 미해결 항목이고, 해법 방향은 "구독 엣지는 하류로 weak, 상류로
strong"이다. **M3 착수 전에 (a) 불변식 명문화 여부와 (b) `luau-test` 실측이
둘 다 필요**하다. → **예/아니오**

### SS-6 — ⭐ `:Compute`가 "우연히" 안전한 것에 기대면 안 되는 이유
`:Compute`는 콜백 클로저가 상류를 캡처해 우연히 살릴 수 있지만 **`:With`가
만드는 pass-through 노드는 계산 함수가 없어** 그 우연이 없다. 즉 이 문제는
"거의 항상 괜찮은데 가끔 새는" 게 아니라 **`:With` 체인에서는 구조적으로
끊긴다**. → **예/아니오**

### SS-7 — ⭐ 상류 strong이 순환을 만들지 않는다
"상류 strong / 하류 weak"를 채택해도 A↔B 강참조 순환이 생기지 않는 이유는
방향이 한쪽뿐이기 때문이고, 그래서 `relate-plan.md`가 경고하는 두-`Relate`
상호 강참조(ephemeron 부재로 실제 누수)와는 다른 모양이다. → **예/아니오**

### SS-8 — `canBound`와 `canExecute`는 서로의 부정
`canBound(v) == not isBoundAlive(v)`, `canExecute(v) == isBoundAlive(v)`이고
판정 로직만 `isBoundAlive` 하나로 공유한다. 게이트 형태는 항상
`if not canBound(v) then error(...) end`이고, 전파 루프만 `canExecute`를 부정
없이 쓴다. → **예/아니오**

### SS-9 — 죽은 바인딩의 재사용은 허용이다
`inst`가 Destroy됐거나 `unbindLifetime`된 값은 `canBound`가 **참**이라 다시
다른 `inst`에 걸 수 있다 — 이 게이트는 **살아있는 바인딩만** 막는다.
→ **예/아니오**

### SS-10 — ⭐ 두 predicate가 벌어질 여지를 남겨둔 이유
지금은 정확히 부정 관계지만, 나중에 "구조적으로는 묶여 있으나 일시적으로 발화만
멈춘" 상태가 생기면 관계가 단순 부정에서 벌어질 수 있다 — 이름을 둘로 나눠 둔
게 그때를 위한 여지이기도 하다. 다만 **그런 상태를 지금 만들 계획은 없다.**
→ **예/아니오**

### SS-11 — `SetAndDispose`는 `Source`의 콜론 메서드
`source:SetAndDispose(value)`로 확정됐고 `:Set`과 한 세트다. `Apply` 오버라이딩
경로가 불가능한 이유는 `Source`→`State`가 **단방향**이라 `Apply`에 `Source`를
넘겨주는 시그니처가 타입으로 성립하지 않기 때문이다. → **예/아니오**

### SS-12 — ⭐ 그래서 `State`엔 `SetAndDispose`가 없다
쓰기 API가 `Source`에만 있다는 기존 원칙 그대로이고, `state:Apply(...)`
시그니처는 이 결정에 **전혀 영향받지 않는다**. → **예/아니오**

### SS-13 — ⭐ `dispose`는 여전히 "값을 지우는" 단일 경로다
`SetAndDispose`는 `Get()` → `Set(new)` → 옛 값 `dispose` 3단계의 sugar일 뿐
새 파괴 경로가 아니고, reconcile 도중 호출이 거부되는 등 `dispose`의 기존
제약을 그대로 물려받는다. → **예/아니오**

---

## LC. 생명주기 배관 심화 (`bindLifetime`/`Relate`)

### LC-1 — ⚠️ `bindLifetime`의 첫 인자는 Instance가 아닐 수 있다
`Dispatch.setLength(ownerKey, ...)`가 Slot-in-Slot에서 **Slot 자신**을 넘기므로,
백엔드의 `bindLifetime`은 이 경우를 반드시 핸들링해야 한다. gcconn 트릭은
`GetPropertyChangedSignal`에 의존해 평범한 Lua 테이블엔 못 건다. → **예/아니오**

### LC-2 — 계약 둘은 그대로, 구현만 갈린다
"(1) 바인딩이 유효한 동안 `value`가 최소한 `inst`만큼 산다" / "(2) `value`가
`inst`의 생존을 스스로 확인할 수 있다" 두 계약은 안 바뀌고, Slot일 땐 그걸
`Relate(slot)`의 `SetStrong`(또는 Slot 필드) + weak-keyed 기록으로 구현한다.
→ **예/아니오**

### LC-3 — ⚠️ `isBoundAlive`의 세 번째 분기가 아직 미확정
지금 스케치는 gcconn이 없으면 `.Subscribed` 폴백으로 떨어지는데, Slot-owned
바인딩은 **둘 다 없어서 살아있는데도 `canBound`가 참으로 잘못 나온다**(이중
바인딩 가드가 이 경로에선 안 걸림). 세 번째 분기의 정확한 형태는 M2/M3에서
정한다. → **예/아니오**

### LC-4 — ⭐ 그래서 지금 Slot-owned 바인딩엔 이중 바인딩 가드가 사실상 없다
그 상태를 M2/M3까지 안고 가는 게 맞고(그 경로를 만드는 건 quad 자신의 내부
배관뿐이라 사용자가 이중 바인딩을 만들 방법이 없음), 사용자 표면에 노출되는
가드에는 영향이 없다. → **예/아니오**

### LC-5 — `Subscribed`는 이 계약과 무관
`bindLifetime`/`unbindLifetime`은 `.Subscribed`를 **읽지도 쓰지도 않는다** —
그 필드는 전역 `:Subscribe()` 경로 전용이고, 옛 스케치가 여기서 그걸
세팅하던 게 오염 지점이었다. → **예/아니오**

### LC-6 — gcconn/gchold는 Instance **생성 시점**에 만든다
`bindLifetime`이 만드는 게 아니다. 그래서 quad가 만들지 않은 Instance를 키로
쓰는 건 UB이고, `Relate`의 `inst` 자리는 항상 weak다. → **예/아니오**

### LC-7 — ⭐ 단일 `Relate` 안의 자기참조가 안전한 조건
"값이 자기 키를 되참조해도 단일 `Relate` 안이면 안전"이라는 서술은, Luau에
ephemeron이 없다는 걸 감안하면 **그 값이 weak로 보관될 때**(또는 값이 키를
강하게 되잡지 않을 때)만 정확한 것 아닌가? `SetStrong`으로 보관하면서 값이
키를 캡처하면 단일 `Relate` 안에서도 그 엔트리가 영원히 안 죽는 것 아닌가?
(실제 코드는 gcconn/gchold를 전부 `SetWeak`으로 두어 이 문제를 피하고 있다)
→ **예/아니오**

### LC-8 — `SetStrong` 전에 물어야 할 것
"이 값을 붙잡는 다른 근거가 이미 있는가" — 있으면 `SetWeak`가 맞다. 이 규칙의
목적은 성능이 아니라 **"이 값의 수명이 어디서 끝나는가"의 답을 항상 하나로
유지하는 것**(디버깅 가능성)이다. → **예/아니오**

### LC-9 — 파괴 관측 지점은 지금 정확히 하나
Instance 파괴를 관측하는 quad 내부 지점은 **`Effect` 하나뿐**이고, 사용자가
Destroy-time 처리를 원하면 `Effect`(그 슈가 `OnDestroyed`)를 쓴다 —
`[Event "Destroying"]`을 직접 바인드하라는 안내는 정본이 아니다. → **예/아니오**

### LC-10 — quad는 라이프사이클 "중간"에 없다
엔진이 Destroy 시 Tag/Attribute/실행 중인 Tween을 정리해주므로 라이브러리가
따로 처리하지 않고, `retract`는 Destroy 시점에 호출되지 않는다. → **예/아니오**

---

## EF. Effect/Observer 심화

### EF-1 — leaf 바인딩된 핸들엔 `:Unsubscribe()`가 아예 안 먹는다
Observer와 정확히 같은 규칙으로 통일됐다 — `:Subscribe()`의 짝이 `:Unsubscribe()`,
leaf 해제는 `unbindLifetime` 전용. 옛 "안 되거나/최소한 cleanup을 앞당기면 안
됨"이라는 어정쩡한 서술은 폐기됐다. → **예/아니오**

### EF-2 — 그 통일이 dedup 시나리오를 원천 차단한다
"값이 안 바뀌어 retract가 no-op인데 `:Unsubscribe()`가 cleanup만 앞당겨 Effect가
조용히 죽는" 경로는 leaf에서 `:Unsubscribe()`가 안 먹으면서 **발생 경로 자체가
없어진다.** → **예/아니오**

### EF-3 — ⭐⭐ 그런데 `effect-plan.md`가 아직 "미해결"이라고 말한다
4라운드 followup A절은 `E-10`(dedup 경로의 process/retract 대칭)을 **"확인 완료 —
`relate`로 이전 값을 들고 `old ~= v` / `nextValue ~= v` 두 분기 안에서만 bind/unbind가
일어나므로 성립"**으로 처리하고 `effect-plan.md`에 반영했다고 적었는데, **실제
`effect-plan.md`에는 그 문장이 없고 여전히 "⚠️ 같이 확인해야 할 별건(미해결) …
M3 착수 전 확인할 것"이 그대로 남아 있다.** `.claude/todos.md`도 이 항목을 아직
열린 것으로 센다. 즉 **반영이 실제로는 안 됐다**(followup의 과잉 보고). 이
인식이 맞나? → **예/아니오**

### EF-4 — `EffectHandle`의 cascade 요구
`state`가 있는 Effect는 leaf 부착/`:Subscribe()` 어느 경로든 **내부 Observer까지
같이** 바인드/등록해야 한다 — 안 하면 그 Observer에겐 `canExecute` 판정 근거가
없어 재실행이 통째로 죽는다. `unbindLifetime(handle)`도 대칭으로 내부 Observer를
같이 푼다. → **예/아니오**

### EF-5 — ⭐ 그 cascade가 dedup 분기 **안**에 있어야 한다
`ObserverEffectLeafHandler`의 `if old ~= v then bindLifetime(...) end` /
`if nextValue ~= v then unbindLifetime(...) end` 짝 안에 **내부 Observer cascade도
같이** 들어가야 한다 — 한쪽만 dedup되면 handle과 내부 Observer의 바인딩 상태가
갈린다. 이게 `E-10`이 실제로 확인해야 하는 내용이다. → **예/아니오**

### EF-6 — `:Subscribe()`는 GC 원칙의 의도적 예외
강참조 레지스트리라 로컬 참조를 다 놓아도 GC되지 않고 계속 실행된다 —
quad의 다른 프리미티브가 전부 GC-native인 것과 정반대라 **사용자 문서에
명시적 경고가 필요하다**. 용도는 top-level 사이드 이펙트로 한정. → **예/아니오**

### EF-7 — leaf 부착과 `:Subscribe()` 동시 사용은 즉시 error
"같은 liveness 게이트를 공유하니 안전"이던 옛 판단은 뒤집혔고, 지금은
`canBound` 게이트로 **즉시 에러**다(한 핸들은 라이프사이클 경로를 하나만 갖는다).
→ **예/아니오**

### EF-8 — ⭐ `state` 없는 Effect의 `:Unsubscribe()`
`Effect(fn)`(state 없음)은 install이 호출 시점에 이미 끝났으므로
`:Unsubscribe()`는 "leaf-사망 cleanup을 수동으로 앞당기는 것"과 완전히 동치이고,
그 이상의 분기가 필요 없다 — 단 이것도 `:Subscribe()`한 핸들에서만 의미가 있다.
→ **예/아니오**

---

## MO. Modifier 심화 — flatten 확정 이후

### MO-1 — flatten은 새 테이블을 안 만든다
props 테이블 리터럴은 그 호출 한 번을 위해 만들어져 소비되고 끝이라 원본 보존
의무가 없으므로, flatten은 **입력을 제자리에서 뮤테이션**한다. `Pre`/`PostRef`
소진이 이미 `flattened`를 제자리에서 갈아치우는 것과 같은 취급이다.
→ **예/아니오**

### MO-2 — 소진 자리는 `ProcessedModifier` 센티널
Modifier를 뽑아낸 배열 자리를 그냥 지우면 구멍이 생겨 배열 파트 순서 보장을
잃으므로, `ProcessedModifier`로 채우고 전담 nop 핸들러
`ProcessedModifierHandler`가 정상 `process` 경로에서 캐치해
`setOffsetSource(None)`/`setLength(0)`을 등록한다 — **새 규칙이 하나도 안 는다.**
→ **예/아니오**

### MO-3 — 반복은 반드시 역순
"이미 있으면 건너뛴다"는 **먼저 쓴 쪽이 이기는** 규칙이라, 정방향으로 돌면
"배열 순서상 나중 modifier가 우선"이라는 확정 규칙과 정반대가 된다. 그래서
`for i = #input, 1, -1`이다. → **예/아니오**

### MO-4 — 인라인 우선은 `~= nil` 하나로 성립
인라인 해시 키는 flatten 전에 이미 테이블에 있고 명시적 unset(`None`)도
실재값이라, "이미 값이 있으면 건너뛴다" 검사 하나가 곧 "인라인이 modifier를
이긴다" 규칙이 된다 — 별도 분기가 없다. → **예/아니오**

### MO-5 — ⭐ 세 센티널이 같은 패턴을 공유한다
`ProcessedPreRef`/`ProcessedPostRef`/`ProcessedModifier`는 전부 "pre-pass가
소진한 배열 자리"를 표시하고 각각 nop 핸들러가 받는다 — 앞으로 pre-pass가
하나 더 생기면 **같은 모양을 그대로 복제**하는 게 맞고, 이걸 하나의 공용
"소진됨" 센티널로 합치지는 않는다(핸들러가 무엇을 소진했는지 구별해야 하므로).
→ **예/아니오**

### MO-6 — `None`만이 명시적 unsetter
`mod:X(nil)`은 "그 필드가 없는 새 Modifier", `mod:X(None)`은 "`None`으로 채워진
Modifier"이고 차이는 `Overridden`/`Peek`에서 관측된다. → **예/아니오**

### MO-7 — Getter를 안 만든다와 `:Peek`은 모순이 아니다
"Getter를 안 만든다"는 **필드별 setter의 짝 getter**를 말하는 것이고, `:Peek`은
키를 받는 범용 접근자라 층위가 다르다. → **예/아니오**

---

## AT. Attribute/Tag 심화

### AT-1 — `groupClaimKeys`는 이름만 확정됐다
위치별 claim 레지스트리의 이름은 `groupClaimKeys`로 확정됐지만 **키 설계는
여전히 미정**이다 — `(inst, groupValue) → k`인지 `groupKey` 단위인지,
`nameClaims`와 어떤 순서로 확인하는지는 M10 구현 전에 정한다. → **예/아니오**

### AT-2 — ⭐ 그래서 M10 전까지 `Frame { a, a }`는 여전히 뚫려 있다
그룹 Attribute를 같은 객체로 두 위치에 놓으면 지금 설계로는 claim 체크를
통과하고 `k=1` retract가 `k=2` 바인딩까지 철거한다 — **레지스트리를 실제로
구현하기 전까지 이 갭은 열린 채로 간다**(M10 전엔 그룹 Attribute 자체가 없으니
실사용 위험이 없음). → **예/아니오**

### AT-3 — `Tag`가 다른 이유는 자원의 성질이다
`Tag`는 자원이 "이름 집합"이라 겹치면 합집합이면 되고 위치별 참조 카운트로
안전하지만, 그룹 `Attribute`는 자원이 **값 하나**라 겹침이 곧 충돌이다.
→ **예/아니오**

### AT-4 — 생존 이름 최적화는 원리적으로 불가능
이름이 같아도 값이 바뀌었을 수 있고, 값을 비교하려면 `:Get()`이 필요한데 그건
State 계약 위반이다 — "부품이 늘어나서 안 한다"가 아니라 **할 수 없다.**
→ **예/아니오**

### AT-5 — `Attribute(a, b, ...)` 생성자는 뒤가 이긴다
`Merged`(겹치면 error) / `Overridden`(뒤가 이김)과 별개로 **생성자 자신의
겹침 정책은 "뒤가 이김"**이다. → **예/아니오**

### AT-6 — ⭐ `plain =`에 State/Source도 온다
`Attribute(store1, store2, { plain = ... })`의 plain 테이블 값 자리에는
raw 값뿐 아니라 `State`/`Source`도 올 수 있고, 이건 새 엔지니어링이 아니라
원래 그렇게 구현될 예정이었다 — 문서에 그렇게 적는 게 맞다. → **예/아니오**

### AT-7 — 해제→재클레임 순서는 Dispatch가 보장한다
같은 핸들러 재프로세스는 `process`가 이전 retractor를 먼저 굴리고 자기 일을
하는 모양(`process` → `retractor(v)` → 새 process)이고, 핸들러가 바뀌면
`retractFrom` → `process`다 — 어느 경로든 옛 claim 반납이 먼저다.
→ **예/아니오**

### AT-8 — `GetKey`는 비공개다
키를 반출하면 사용자가 같은 키를 두 자리에 놓아 claim으로도 못 잡는 수렴이
생긴다(0-W와 같은 형태의 갭). → **예/아니오**

---

## TW. Tween / UI 숏핸드 심화

### TW-1 — `mapTweenValue`는 공개 메소드로 승격됐다
로컬 헬퍼가 아니라 `Tween<T>`의 공개 메소드다 — `table.clone` 후 `Value`만
`fn(Value)`로 교체해 새 `Tween<U>`를 반환하고, 원본은 안 건드린다.
→ **예/아니오**

### TW-2 — ⚠️ 이름이 아직 안 정해졌다
`Map`과 `Mapped` 둘 다 열려 있고, 코퍼스의 `-ed` 관례(즉시 확정되는 raw 값은
과거분사)만 보면 **`Mapped`가 더 일관적**이다. 최종 결정이 필요하다.
→ **예/아니오 (+ 어느 쪽인지)**

### TW-3 — ⭐ 호출부 분기는 그대로 남는다
`isTween(v)`인지 판정하는 분기는 여전히 숏핸드 호출부에 있고, `Tween`이면
`v:Map(wrap)`, 아니면 `wrap(v)`다 — 승격된 건 변환 로직이지 분기가 아니다.
→ **예/아니오**

### TW-4 — 부수 이득은 좁다
`local FAST = Tween{Value = 0, Time = 0.15}`를 두고 `FAST:Map(...)`으로
옵션만 재사용하는 패턴이 열리지만 **사용 케이스가 넓지는 않을 것**으로 보고,
어차피 내부에 필요해서 만드는 걸 공개하는 것뿐이다. → **예/아니오**

### TW-5 — `CanAnimate`는 처음부터 `State<boolean> | boolean | nil`
`resolve`가 `:Get()`으로 푼다 — 4라운드 문항이 "단순 boolean"으로 축약한 게
부정확했을 뿐 문서는 처음부터 맞았다. → **예/아니오**

### TW-6 — 자식 파괴 시 `retractFrom`은 정석이 아니다
엔진이 Destroy 시 실행 중인 Tween을 알아서 정리하고 `PropertyHandler`의
retractor는 애초에 no-op이라, `retractFrom(child, prop, 1)`은 **두 겹으로
무의미**하다. → **예/아니오**

### TW-7 — 숏핸드 자식의 gcconn/gchold는 확인된 전제다
`process` 위임을 하는 이상 gcconn/gchold가 없으면 **옵저버 바인딩부터 실패**하므로
"조용히 미아"가 아니라 즉시 드러나는 전제 조건이고, `ensureManagedChild`가
일반 인스턴스 생성과 같은 경로를 타야 한다는 계약으로 승격됐다. → **예/아니오**

---

## DT. Debounce/Throttle 심화 (4라운드에선 9문항뿐이었던 영역)

### DT-1 — 두 도구의 차이는 정확히 한 비트
"신호가 창 타이머를 리셋하는가" 하나뿐이고 leading/trailing/통과 후 창
재개방은 **완전히 동일**하다. 그래서 공용 게이트 + `Reset` 불리언 하나로 둘
다 나온다. → **예/아니오**

### DT-2 — lodash식 `maxWait`로 throttle을 흉내내지 않는다
초안이 그 공식을 옮겼다가 **trailing 통과 직후 타이머를 회수해 바로 뒤 신호가
"창 밖"으로 판정돼 1초 안에 두 번 나가는 버그**를 냈고, 지금 정식화는 그
구멍이 구조적으로 없다. → **예/아니오**

### DT-3 — `MaxTime`은 디바운스 전용
"신호가 안 끊기면 영원히 발화 안 함"은 디바운스의 정의 그 자체라 안전장치가
필요하지만, 스로틀은 원래 주기적으로 발화하므로 필요 없다. → **예/아니오**

### DT-4 — 공개 `Blocker` API 위에는 못 얹는다
`Blocker`엔 "상류 신호가 지금 도착했다"는 통지가 없어서 타이머를 (재)시작할
순간을 알 수 없다. 그래서 게이트 노드 내부 훅이 필요하다. → **예/아니오**

### DT-5 — ⭐ 그래서 M3에서 해야 할 일이 하나 생긴다
`Blocker`를 구현할 때 게이티드 노드를 **공용 `Gate` 노드로 한 겹 일반화**해
두는 것만은 그 시점에 해야 한다(나중에 하면 같은 설계를 두 번 한다). 새 노드
종류를 만드는 게 아니라 이미 있는 하나에 이름을 붙여 꺼내는 것이다.
→ **예/아니오**

### DT-6 — 제어 핸들은 세 번째 모양으로 수렴했다
State 자신에 메소드를 붙이지도(타입이 갈림), `Blocker`식 공유 외부 객체도
아니고(상태 기계라 공유가 위험), **개별은 `Ref` 아웃파라미터(`Handle = Ref()`),
전체는 팩토리 자신의 `:Flush()`/`:Cancel()`**이다. → **예/아니오**

### DT-7 — 팩토리는 자기 게이트를 weak로만 추적한다
strong으로 잡으면 다운스트림이 다 죽어도 게이트가 GC되지 않아 "정리는 GC에
위임" 원칙과 충돌한다. → **예/아니오**

### DT-8 — `Flush`/`Cancel`의 의미
`Flush()`는 pending이면 창 끝을 안 기다리고 즉시 커밋(+창 재개방), pending이
없으면 no-op(idempotent). `Cancel()`은 타이머를 정리하고 pending을 **버린다**
(전파 없음). → **예/아니오**

### DT-9 — 주입 op는 base 범용 유틸 그룹이다
`setTimeout`/`clearTimeout`은 핸들러 op 3종(`addTag`/`removeTag`/`setAttribute`)이
아니라 `bindLifetime`/`canExecute`와 같은 층위이고, 게이트 전용도 아니다
(나중에 타이머가 필요한 다른 것이 재사용). → **예/아니오**

### DT-10 — JS 어휘를 고른 이유와 그 대가
`task.delay`를 안 따라간 건 **`task`가 한 엔진의 것이라 base 층에 새기면 안
되기 때문**이고, 그 대가로 Roblox 배선에서 인자 순서가 뒤집히는(시간이 먼저)
조용히 틀리기 좋은 자리가 생긴다 — 백엔드당 한 곳뿐이라 감당한다.
→ **예/아니오**

### DT-11 — 가변인자를 안 받는 이유
게이트 콜백은 게이트당 하나씩 만들어져 재사용되는 안정된 클로저(`onWindowEnd`)라
호출마다 새로 만들 필요가 없다 — varargs로 아낄 할당이 애초에 없다.
→ **예/아니오**

### DT-12 — `Timeout`은 마커 필드가 있는 전용 타입
`type Timeout = {}`는 구조적으로 모든 테이블과 호환이라, `__type_timeout: true`
싱글턴 마커로 사실상 nominal하게 만들고 **런타임에도 실제로 그 필드를 넣는다**
(`isTimeout` 판별이 공짜로 따라옴). `_native`는 백엔드 페이로드고 base는 절대
안 읽는다. → **예/아니오**

### DT-13 — `clearTimeout`은 모든 백엔드에 요구해도 되는 계약
네이티브 취소가 없는 엔진도 "플래그를 뒤집는 래퍼"로 항상 구현 가능하다.
다만 그 경우 타이머가 예정대로 깨어나 아무 일도 안 하므로 "대기 타이머가
게이트를 붙잡는다"는 성질은 남는다(유계라 문제 아님). → **예/아니오**

### DT-14 — `os.clock()`은 주입하지 않는다
Luau 표준이고 고정밀이라 base가 그냥 부른다. **단 절대 시각이 아니라 차이
계산 전용**이고, 이 설계는 전부 `deadline - os.clock()` 형태의 차이만 쓴다
(부수 이득: 벽시계 보정에 영향 안 받음). → **예/아니오**

### DT-15 — ⭐ 결국 순수 슈가라 우선순위가 낮다
제어 핸들까지 닫히고 나니 quad-base에 **새 코어 메커니즘을 추가하지 않는**
순수 슈가로 확인됐고, M0/M3를 막지 않는다 — 예외는 위 DT-5(`Gate` 일반화)뿐.
→ **예/아니오**

---

## ML. 모듈 생명주기 심화 — `RunInit` 재설계 이후

### ML-1 — 가드 소유 위치가 파일별에서 공유로 옮겨졌다
각 `InitXxx`가 자기 `Relate()`+`INITED` 센티널을 두던 옛 설계는 폐기되고,
`module` 인스턴스가 공유하는 `RunInit` 하나가 판단을 전담한다 — 결론(멱등)은
같고 **가드가 어디 있느냐만** 바뀌었다. → **예/아니오**

### ML-2 — 함수 자신이 릴레이션 키다
`(module, initFn) → boolean` 표가 곧 "이 함수를 이 모듈에 실행했는가"라서
센티널 키가 아예 필요 없다. → **예/아니오**

### ML-3 — 의존성 있는 `InitXxx`도 같은 패턴
자기 의존성을 `module:RunInit(InitLifetime)`처럼 부르기만 하면 되고 순서/중복은
`RunInit`의 멱등성이 흡수한다 — 최상위 `New()`가 순서를 관리하지 않는다.
→ **예/아니오**

### ML-4 — `_initializedBy`와는 계속 별개다
`RunInit`은 "이 **함수**가 이미 돌았는가"(멱등 실행)이고 `_initializedBy`는
"이 **슬롯**을 누가 채웠는가"(다른 팩토리면 error)라 표현하는 게 다르다.
억지로 합치면 두 의미가 한 API에 섞인다. → **예/아니오**

### ML-5 — ⭐ 그래서 backend 설치는 `RunInit`을 안 거친다
`InitRoblox(module)`은 `module:RunInit(InitRoblox)`로 부르는 게 아니라 자기가
`_initializedBy`를 직접 확인/기록한다 — 두 메커니즘이 한 호출에 겹치지 않는다.
→ **예/아니오**

### ML-6 — 타입 재익스포트는 실측 확인됐다
`type Dispatch = InitDispatch.Dispatch` 형태가 Luau에서 문제없이 동작하고,
이건 `typing-limits.md`의 재귀 제네릭 한계와 다른 자리(단순 alias)다.
→ **예/아니오**

### ML-7 — `Quad.debug`의 게이팅 범위
`Quad.debug`가 게이팅하는 건 **라이브러리가 스스로 콘솔에 쓰는 동작**뿐이고,
`Dispatch.listHandlers()`는 이 플래그와 무관하게 항상 호출 가능하다(목록을
반환만 하고 출력은 사용자 몫). → **예/아니오**

### ML-8 — ⭐ 다중 인스턴스에서 `debug`는 인스턴스별이다
`InitDebug`가 `module.debug = false`를 각 module에 설치하므로 `New()`로 만든
인스턴스마다 독립적이다 — "전역이냐 인스턴스별이냐"는 이제 미정이 아니라
**코드가 이미 인스턴스별로 답했다.** → **예/아니오**

---

## TL. 타입 한계 / Store 심화

### TL-1 — §6은 §1과 다른 한계다
§1(재귀 제네릭이 자기를 다른 인자로 반환)은 **Luau 솔버의 상위 한계라 기다리는
것**이고, §6(`type function`을 거친 이력이 제네릭 self 체이닝을 깨뜨림)은
**설계로 회피 가능한 것**이라 quad가 실제로 회피 규칙을 세웠다. → **예/아니오**

### TL-2 — 회피는 세 조각이 다 필요하다
①`error()` 대신 `print`+`types.never`, ②검증을 리턴/필드 타입 표현식 자체에
박아 호출부마다 재평가되게, ③원본을 절대 반환하지 않고 별도 필드로 격리 —
셋 중 하나라도 빠지면 안 된다. → **예/아니오**

### TL-3 — 체크리스트 7번이 그 일반화다
"`type function`으로 검사/변형한 값에 제네릭 self 메소드를 나중에 부를
계획인가?"가 새 항목으로 들어갔고, 앞으로 같은 조합을 설계할 때마다 이걸
먼저 본다. → **예/아니오**

### TL-4 — 진단 0건은 안전의 증거가 아니다
`luau-analyze` 0건이어도 타입이 제대로 해소됐다는 뜻이 아니므로
`--annotate`로 실제 추론 타입을 눈으로 확인하고, 음성 대조군(일부러 틀린
대입)을 같이 둔다. → **예/아니오**

### TL-5 — ⭐ 이 규율이 실제로 두 번 물렸다
(a) 재귀 제네릭이 조용히 `Unifiable<Error>`로 새던 것, (b) `init.luau`의
require 경로를 `@self` 없이 써서 런타임만 깨지고 정적 검사는 통과하던 것 —
원인은 다르지만 **"진단 0건이 통과가 아니다"라는 같은 함정**이다.
→ **예/아니오**

### TL-6 — Store 미선언 키 거부는 실측 확인됐다
`ProcessStoreType`이 합성한 레코드 타입엔 인덱서가 없어 미선언 키 접근이
정확히 `TypeError`로 거부된다(`luau-test/done/21-*`) — 더 이상 열린 항목이
아니다. → **예/아니오**

### TL-7 — ⚠️ `store:GetDynamic`의 위치는 여전히 미정
콜론 메서드로 두면 `GetDynamic`이 **모든 Store의 예약 키**가 되어 lazy
`__index`와 충돌한다는 게 확인된 문제이고, 탑레벨 함수로 둘지 아직 안 정했다.
**M3/M4 착수 전 결론이 필요**하다. → **예/아니오**

### TL-8 — ⭐ 그 충돌은 `Quad.debug`류와 성격이 다르다
`Quad`는 필드 집합이 고정된 모듈 테이블이라 이름을 추가해도 사용자 키와
안 부딪히지만, `Store`는 **사용자 키가 곧 필드**라 어떤 메서드 이름을
붙이든 그 이름이 예약어가 된다 — 그래서 Store엔 콜론 메서드를 늘리는
것 자체가 비용이다. → **예/아니오**

---

## CR. 크로스컷 — 여러 문서에 걸친 것

### CR-1 — ⭐⭐ followup 표를 신뢰 소스로 쓰면 안 된다
4라운드 followup의 "반영 완료" 표에 적혀 있어도 **실제 `base/`에 안 들어간
항목이 최소 하나 있다**(`E-10`, 위 `EF-3`). 그래서 "무엇이 확정됐나"의 소스는
언제나 `base/` 본문이고, followup은 경위 기록일 뿐이다 — 다음 세션이 followup만
읽고 "이건 이미 닫혔다"고 판단하면 안 된다. → **예/아니오**

### CR-2 — ⭐ `Tween:Map`/`Mapped` 이름이 어느 대기열에도 없다
`tween-plan.md`는 "최종 이름 미확정"이라고 적어뒀는데 `question.md` 1번(용어
정리)에도 `todos.md`에도 이 항목이 없다 — **결정이 필요한데 추적되지 않는
상태**다. `Owned`는 제대로 올라가 있는 것과 대비된다. → **예/아니오**

### CR-3 — ⚠️ M2가 M3의 `Blocker.luau`에 의존하는 순서 문제는 여전히 열려 있다
`Dispatch.drive`의 배치 등록이 Blocker 게이팅을 전제하므로, `Blocker`(또는
최소 표면)를 M2로 앞당길지 로드맵 순서를 유지할지 **M2 착수 전에** 정해야
한다. 지금은 ROADMAP에 각주만 달린 임시 상태다. → **예/아니오**

### CR-4 — ⭐ gcconn 전제가 여러 설계의 뿌리다
"quad가 만든 Instance는 참조를 놓아도 GC로 안 죽는다"는 사실 하나에서
(a) `userdata`에 quad Instance를 담지 말라는 제약, (b) `_detached`가 영구
누수라는 결론, (c) `dispose`라는 명시적 경로의 필요성이 **전부** 나온다.
→ **예/아니오**

### CR-5 — ⭐ 그런데 그 전제는 백엔드마다 다르다
gcconn 트릭은 quad-roblox의 것이고, mock/웹 백엔드에는 그런 장치가 없어 그냥
GC될 수 있다. 그러면 "detach 요소는 명시적으로 안 지우면 영구 누수"라는 논증도
**백엔드에 따라 참/거짓이 갈린다** — 그래도 base는 항상 명시적 정리를 하는
쪽(가장 강한 요구)으로 통일하는 게 맞다. → **예/아니오**

### CR-6 — ⭐ `userdata`만 GC에 맡기는 유일한 자리다
Slot이 죽을 때 `userdata`는 명시적으로 비우는 코드가 없고 `activateList`
클로저가 통째로 GC되는 것에 의존한다(그래서 파괴 경로가 `_listObserver`를
`unbindLifetime`하는 게 중요하다 — 안 풀면 `gchold`가 그 클로저를 계속
붙잡는다). 이 비대칭(`_detached`는 명시적, `userdata`는 GC)은 의도된 것이다.
→ **예/아니오**

### CR-7 — 사용자 표면의 파괴 경로는 셋뿐
`Slot:Remove`/`Clear`(명시적 CRUD), `dispose(value)`, 그리고 `:List`의
`Owned = true` 자동 처분 — 사용자가 직접 `Destroy()`를 부르는 건 quad가
관리 중인 값에 대해선 UB다. → **예/아니오**

### CR-8 — ⭐ M2 착수 전에 남은 것의 전체 목록
지금 열려 있어 M2/M3를 실제로 막을 수 있는 건 다음이 전부다 —
(1) M2 vs `Blocker` 순서(CR-3), (2) 중간 State GC 불변식 + 실측(SS-5),
(3) `store:GetDynamic` 위치(TL-7), (4) `E-10` dedup 대칭 확인(EF-3/EF-5),
(5) `isBoundAlive`의 세 번째 분기(LC-3), (6) 스파이크 `01` 재작성(DC-18),
(7) `table.insert` 구멍 재사용 실측, (8) `Tween:Map` 이름(CR-2),
(9) 그룹 `Attribute`의 `groupClaimKeys` 키 설계(M10 전). **이 목록에 빠진
게 없나?** → **예/아니오 (+ 빠진 것)**

### CR-9 — ⭐ 그중 (5)와 (8)은 어디에도 추적되지 않는다
`isBoundAlive`의 세 번째 분기는 `lifecycle-pattern.md` 본문에만 ⚠️로 있고
`question.md`/`todos.md` 어디에도 없다. `Tween:Map` 이름도 마찬가지(CR-2).
**둘 다 추적 목록에 올려야 한다.** → **예/아니오**

### CR-10 — 동기 계약은 공개 문서로 나가야 한다
"컴포넌트 함수/`updateFn`/Handler 안에서 yield 금지"는 지금 `dispatch-core-plan.md`
안쪽에만 있는데, 이건 **사용자가 지켜야 하는 공개 계약**이라 사용자 문서에도
반드시 나가야 한다. → **예/아니오**

### CR-11 — ⭐ 이 라운드 이후의 계획
4라운드 처리 때 "이후 stale만 잡는 것으로 끝낼 수 있어보임"이라고 했고 그래서
5라운드를 안 만들 예정이었는데, 실제로 만들어보니 **새 확정분(어제 것)과
아예 문항이 없던 영역이 남아 있었다.** 그러면 앞으로도 "큰 확정이 있은 뒤엔
그 부분만 대상으로 하는 소규모 라운드"를 두는 게 맞나, 아니면 이번이 마지막이고
이후엔 감사(`quad-doc-auditor`)+`/code-review`만으로 가는 게 맞나?
→ **둘 중 어느 쪽인지**

