# 공개 표면 사전 점검 — 쓰기 시작하기 전에 정할 것 (2026-09-13)

**상태**: 의견 — 코드 변경 없음. 사용자가 항목마다 결정하면 `[결정]`을 머리에 적고 그때 반영한다(사용자 지시: *"D처럼 당장 코드 변경을 요구하는건 바로 하지 말고, 의견을 정리해 주길"*).
**발단**: 사용자 원문 — *"D=Declaration 유사한 사람들이 쓰기 시작하기 전 미리 고쳐놔야 큰 마이그레이션 필요한 breaking 안 나는거 미리 더 생각해놓기가 필요함. 코드를 보고 확인해야함."* 그리고 동료 의견 — *"D 는 Declaration 으로 풀로 쓰는게 차라리 나아보인다 … 유저가 직접 const D = ... 형식으로 가져오는게 관례라면 작게 적어야할 이유가 사라지는데다가, Quad. 으로 자동완성을 할 때 명시적 이름이 보여서 훨씬 괜찮다"*, *"지금은 사용하는 개발자가 없는 단계라 메이저 버전을 올릴 필요까지 없는 정도라 지금 결정해도 되는데, 어떻게 봐?"*
**방법**: opus 하나가 공개 표면 정본(`quad-types/src/init.luau`, 두 `init.luau`, `scripts/gen-d.py`, 매니페스트, `docs/reference/00-index.md`)과 `base/` 결정 이력을 읽고 후보 열일곱을 냈다(읽기 전용). 메인이 핵심 사실을 코드로 재확인했다 — `D`의 어원(`base/bind-system-plan.md` 2026-08-18 항목 — 옛 가칭 DI = Declarative Instance → `D`(Declarative)), `quad-roblox/src/init.luau`의 `VERSION_PATTERN = "3.1.0"` 정확 일치, `Store.luau`의 `RESERVED` 셋, `quad_error`·`type_version_check` 매니페스트 `3.1.0`. 항목별 실비용(예: `read` 전환의 캐스트 개수)은 미실측 — 결정 뒤 착수 때 잰다.

## 메인 의견 요약 — `D` 이름

**(a)에 동의한다: 모듈 필드·타입을 풀 이름으로 바꾸고, 문서의 별칭 관례 `const D = q.<풀 이름>`은 유지한다.** 근거는 아래 (1)이 적은 그대로다 — 2026-08-18의 근거 셋 중 "타입 프리픽스가 짧아야 한다"는 M7에서 타입 이름이 `FrameModifier`가 되면서 만료됐고, 남은 둘은 이름 길이와 무관하다. 별칭을 유지하면 문서 본문 4,729곳의 `D.` 표기는 그대로이고 바뀌는 것은 `q.D` 393곳(대부분 `const D = q.D` 154곳)뿐이라 기계 치환이다. 코드는 여섯 자리 + 스펙. 사용자가 없는 지금이 비용이 가장 싸고, 3.2.0에 **BREAKING**으로 한 줄이면 된다(메이저 불필요라는 사용자 판단에 동의).

**낱말은 사용자 결정** — 정본 어원은 형용사 *Declarative*, 동료 제안은 명사 *Declaration*, 대안은 동사 *Declare*. 네임스페이스로는 명사가 자연스럽다(`q.Declaration.Frame`). 같이 정할 것 둘: 옛 `q.D` 별칭을 남기지 않는다(자동완성에 둘이 뜨면 목적이 무너진다 — 권고), `export type D`·`DMapper`·`DModifier` 타입 이름도 같이 옮긴다(권고). `base/bind-system-plan.md`의 2026-08-18 확정과 `architecture.md`의 "`Declaration` 네임스페이스와 그 필드" 절 표기 규약은 같은 커밋에서 "`D`는 `q.<풀 이름>`의 관례 별칭"으로 바꾼다.

**같이 하면 싼 것**: (2) 백엔드 버전 게이트를 `"3.*.*"`로 — base 패치마다 다섯 패키지 lockstep 게시를 강제하는 지금 값은 SemVer 약속보다 좁다. (10) 생성기에 `New`/`Mapper`/`Modifier`(`Mapper`엔 `Root`) 이름 충돌 게이트 세 줄 — 개명 커밋에 얹는다. (11-i) "에러 문구는 진단이지 API가 아니다" 한 줄 — 3.1.0에서 이미 문구를 바꿨다.

## 결정 문항 (항목당 하나 — 상세는 아래 번호)

1. (1) **[닫힘 2026-09-14 — `Declaration`으로, (a) 채택]** `D` → 풀 이름으로 바꿀지, 바꾸면 `Declaration` / `Declare` / 다른 낱말 중 무엇으로.
2. (2) `quad-roblox`의 `VERSION_PATTERN`을 `"3.*.*"`로 풀지. **[닫힘 2026-09-15 — `"3.2^.0^"`(메이저 고정 하한, bump가 하한을 올림) + `N^` 사전식 하한]**
3. (3) `quad_error`·`type_version_check`를 lockstep에서 빼고 자기 번호(1.0.0)를 줄지, 영원히 lockstep인지. **[닫힘 2026-09-15 — 뺌, 번호는 이어서 4.0.0부터·옛 3.x yank]**
4. (4) `slot.Length`/`slot.Offset`(과 `updateFn`의 `offset`)을 `State<number>`로 좁힐지. **[닫힘 2026-09-15 — `State<number>`로 업캐스트, BREAKING(타입)]**
5. (5) 공개 값 타입의 상태 필드(`Ref.Value`/`Revision`, `Observer.Subscribed`, `Blocker.IsBlocked` 등)에 `read`를 붙일지(`Handler`·`q.debug` 제외). **[닫힘 2026-09-15 — 붙임, BREAKING(타입)]**
6. (6) `Store` 예약 키 확장 정책 — `__` 접두 예약 / 확장 자리 하나 / "메소드 추가 안 함" 중 하나. **[닫힘 2026-09-15 — 메소드 동결 + `__` 접두 전부 예약, BREAKING]**
7. (7) `Slot:List`/`:Single`의 `updateFn` 인자 모양 — 테이블 하나 / `:Single`에도 `index` / `opts`만 마지막으로 통일 / 그대로. **[닫힘 2026-09-15 — 매 호출 새 테이블 `updateFn(ctx)`, 필드 PascalCase, BREAKING]**
8. (8) 무타입 `Modifier():Peek<<T>>`의 `T` 의미("값 대수 전부")를 레퍼런스에 못 박을지, 이름을 가를지. **[닫힘 2026-09-15 — (나) 층 나눔 유지, 백엔드마다 레퍼런스에 명시; 프로바이더 재타이핑 기각]**
9. (9) `AddPlugin`이 기존 필드를 덮을 때 — 에러 / `q.debug` 경고 / 허용. **[닫힘 2026-09-15 — 허용 + `q.debug` 경고]**
10. (10) 생성기에 `D` 예약 이름 충돌 게이트를 넣을지. **[닫힘 2026-09-15 — 게이트 넣음]**
11. (11) "에러 문구로 분기하지 말 것" 정책 한 줄을 레퍼런스·extend에 적을지.
12. (12) `H-186`(인스턴스 교차 값 혼용)을 영원히 UB로 못 박을지, 3.2.0에 절반 가드를 둘지. **[닫힘 2026-09-15 — `q.moduleIdentity` 빈 토큰 + 서브시스템별 가드]**
13. (13) `Brand`의 `register`/`is`를 `Register`/`Is`로 올릴지(quad-types 공개 팩토리가 된 뒤 소문자 근거가 소멸). **[닫힘 2026-09-15 — 올림, BREAKING]**
14. (14) `SlotListOpts.Owned` 이름을 `OwnsElements`/`DestroyElements`로 바꿀지. **[닫힘 2026-09-15 — `OwnsElements`, BREAKING]**
15. (15) `state:With(...)` 이름을 뜻이 드러나는 것(`Watching`/`Also`/…)으로 바꿀지. **[닫힘 2026-09-15 — `Depend`로 개명, BREAKING]**
16. (17) "`_` 접두 필드는 비공개"를 extend/01에 명시할지. **[닫힘 2026-09-15 — 명시(내부 계약, 언제든 바뀜)]**

---

## 후보 열일곱 (opus 점검 원문 — 메인 검증 표시는 각 항목 머리)

## (1) `D` 네임스페이스 이름 — 코디네이터가 전달한 사용자 문항

**[결정 2026-09-14 — 사용자: *"지금이 가장 좋은 포인트"*] (a) 채택, 낱말은 `Declaration`.** 모듈 필드·타입을
풀 이름으로 옮겼다 — `q.Declaration`, `export type Declaration`/`DeclarationMapper`/`DeclarationModifier`,
생성 폴더 `quad-roblox/src/Declaration/`(옛 `D/`). 문서의 별칭 관례 `const D = q.Declaration`은 유지(본문의
`D.Frame {…}` 표기는 그대로). 옛 `q.D` 별칭은 남기지 않는다. 사용자가 없는 단계라 메이저 없이 3.2.0에
**BREAKING** 한 줄. `base/bind-system-plan.md`의 2026-08-18 확정과 `base/architecture.md`의 표기 규약은
같은 커밋에서 정정했다. 아래 본문은 **결정 전** 조사 원문이라 `q.D`·옛 타입 이름이 그대로 남아 있다.

**무엇** — 모듈 필드 이름 `D`. 런타임은 `quad-roblox/src/RobloxFactory.luau:54`(`D = InitD(module)`), 타입은 `quad-roblox/src/init.luau:44`(`export type D = DModule.D`)와 `:61`(`RobloxExtension`의 `D` 필드), 생성기는 `scripts/gen-d.py:704`(`export type D = {`)와 `:738`(런타임 테이블 조립), 내부 사용처 하나가 `quad-roblox/src/Handlers/InstanceShorthand.luau:80`(`quad.D.New(...)`)입니다.

**먼저 사실 정정 하나** — 이 프로젝트에서 `D`는 **Declaration이 아니라 Declarative**입니다. 출처는 `.claude/base/bind-system-plan.md:137-148`: PA님 실 코드의 옛 `DeclarativeInstance.luau`에서 온 가칭 `DI`("Declarative Instance")를 2026-08-18에 `D`(Declarative)로 확정했고, 근거 셋을 명시했습니다 — (1) Instance 전용이 아니라 quad-* 전반의 declare 요소로 확장 가능, (2) 엔진 종속 없이 다른 백엔드에서도 재사용 가능, (3) *"`D.FrameModifier`류 타입 프리픽스가 짧아야 한다"*. 단점은 *"한 글자 식별자라 grep이 어렵고 이름만으로 뜻이 안 드러나는 게 유일한 단점"*이라 적혀 있고, 보완책이 `architecture.md:534-540`의 문서 표기 규약(*"문서에서 `D`가 처음 나오는 자리에서는 항상 `D`(Declarative)로 풀어쓸 것"*)입니다.

**그때 근거가 지금도 성립하는가** — 셋 중 (3)이 **만료됐습니다.** 같은 문단이 스스로 괄호로 정정해 뒀습니다: *"**[2026-09-04 M7 단위 ③]** 실물은 타입 `<Class>Modifier`(생성 `D` 모듈 export) + 값 `D.Modifier.<Class>()`"*. 즉 타입 이름은 `D.FrameModifier`가 아니라 `FrameModifier`라 **타입 프리픽스가 짧아야 할 이유가 애초에 사라졌습니다.** (1)·(2)는 이름의 길이와 무관한 논거라 그대로 성립하고, 긴 이름으로 바꿔도 훼손되지 않습니다. 그리고 유일한 단점으로 적힌 "이름만으로 뜻이 안 드러난다"가 정확히 동료분이 짚은 그 지점이고, 보완책이 문서 규약(사람이 지켜야 하는 것)뿐이라는 것도 그대로입니다.

**비용 실측** — 코드 쪽은 작습니다. 실제로 바꿔야 하는 자리는 위에 적은 **여섯 곳**(RobloxFactory 반환 키, init.luau의 `export type D`와 `RobloxExtension` 필드, gen-d.py의 타입 이름·런타임 테이블, InstanceShorthand의 내부 읽기 한 줄)에 스펙 파일 몇 개(`quad-roblox/test/spec.d.luau`·`spec.component.luau` 등 `q.D`를 읽는 파일 열 개 남짓)입니다. 생성 파일 옛 `quad-roblox/src/D/init.luau`(지금은 `Declaration/`)는 생성기를 고치고 재생성하면 되고 `gen-d.py check` 게이트가 정합성을 잡아 줍니다. 문서 쪽은 기계 치환입니다 — `docs/` 전체에서 `q.D`가 **393곳**, 그 중 별칭을 만드는 `const D = q.D` 꼴이 **154곳**이고, 별칭 뒤의 `D.<무엇>` 사용은 **4,729곳**인데 **별칭 관례를 유지하면 이 4,729곳은 한 글자도 안 바뀝니다.** 실질 치환 대상은 `q.D`가 나오는 393곳 + `docs/skills/quad-ui-dev` 두 곳뿐입니다.

**갈래별 판단**

- **(a) 모듈 필드·타입을 풀 이름으로 바꾸고 `const D = q.Declaration` 별칭 관례는 유지.** 자동완성에서 `q.` 뒤에 뜻이 보이는 이름이 서고, `q.D`가 코드 검색에서 잡히지 않던 문제(문서 규약으로 때우던 그 단점)가 구조적으로 사라집니다. 길이 걱정은 사실상 없습니다 — 긴 이름을 타이핑하는 자리는 파일당 별칭 한 줄뿐이고, 나머지는 전부 `D.`로 그대로입니다. **부수 이득 하나**: 지금은 라이브러리가 사용자 파일에서 `D`라는 한 글자를 쓰라고 사실상 지시하는 셈인데(`D`는 사용자 코드에서 델타·행렬 등으로 흔히 쓰이는 글자입니다), 이름을 옮기면 **그 한 글자를 쓸지 말지가 사용자 선택으로 내려갑니다**(`const Dec = q.Declaration`도, 아예 `q.Declaration.Frame`도 가능). 이게 (a)의 가장 강한 논거라고 봅니다.
- **(b) 별칭 `D`까지 문서에서 버리기.** 4,729곳을 `Declaration.`으로 늘리는 것이고, `Declaration.Modifier.TextButton():TextSize(18)` 같은 줄이 예제마다 길어집니다. 선언형 UI 코드는 가로폭이 이미 빠듯해서 손해가 이득보다 큽니다. **비권장.**
- **(c) 그대로.** 만료된 근거 (3) 위에 남는 게 (1)·(2)뿐인데 둘 다 이름 길이와 무관하므로, 유지의 실질 근거는 "이미 그렇게 적혀 있다"뿐입니다. 사용자 본인이 *"지금은 사용하는 개발자가 없는 단계"*라고 판단했다면 그 근거는 약합니다.

**권고 — (a).** 다만 **낱말을 사용자가 골라야 합니다.** 정본은 *Declarative*(형용사)인데 동료분 제안은 *Declaration*(명사)입니다. 네임스페이스 이름으로는 명사가 자연스럽고(`Declaration.Frame` = "Frame 선언"), `Declarative.Frame`은 형용사라 어색합니다. 세 번째 후보로 동사 `Declare`가 있습니다(`Declare.Frame{...}` = "Frame을 선언한다", 7글자로 더 짧음). 어느 쪽이든 **`bind-system-plan.md:140`과 `architecture.md:534-540`의 "`D`(Declarative)" 표기 규약을 같은 커밋에서 고쳐야** 코퍼스가 자기모순에 빠지지 않습니다. 함께 정할 것 둘: 옛 `q.D`를 deprecated 별칭으로 남길지(**남기지 말 것을 권고** — 자동완성에 두 개가 뜨면 개명의 목적 자체가 무너집니다), 그리고 `export type D`/`DMapper`/`DModifier` 세 타입 이름도 같이 옮길지(**같이 옮길 것을 권고** — `D`가 사라지면 `D` 접두 타입만 고아가 됩니다).

**같은 논리가 `D.New`/`D.Mapper`/`D.Modifier`에도 미치는가** — **미치지 않습니다.** 그 셋은 이미 별칭 뒤에 있어서 사용자가 쓰는 실제 문자열은 `D.Modifier.Frame(...)`으로 지금과 동일하고(개명은 별칭 정의 한 줄만 건드립니다), 이름 자체도 한 글자 약어가 아니라 뜻이 드러납니다. `Declaration.Modifier.Frame`이 길다는 걱정은 별칭을 쓰는 한 나타나지 않는 문자열입니다. 다만 그 세 이름에는 **별개의 문제**가 하나 있는데 아래 (10)번으로 따로 적었습니다.

**확신: 높음**(사실관계·비용 실측). 낱말 선택은 취향이라 사용자 몫.

---

## (2) quad-roblox의 버전 게이트가 **정확히 일치**라서 base 패치 하나가 백엔드 릴리즈를 강제한다

**[결정 2026-09-15 — 메이저 고정 하한 + 사전식 `^`]** 사용자(아래 (23)/(24)와 한 회신): *"선행 요소가 up이면 후행이 무시 가능하게 두는게 가장 멀쩡해보임. 선행 3 에는 ^ 하지 마(나중에 릴리즈 이후 breaking 생기면 그 땐 진짜 올릴 부분이라)"*. 메인 해석: `N^`는 사전식 하한((24) (가)), 메이저 자리엔 `^`를 두지 않는다. 반영: `VERSION_PATTERN = "3.2^.0^"`, `check-version.py bump`가 새 릴리즈의 `M.m^.p^`로 하한을 올림(패턴 반영 스펙 줄도 같이 — 검사는 이제 VERSION_PATTERN과 대조), `spec.robloxfactory`에 같은 메이저 안 새 base 설치 양성, 레퍼런스 core/01·roblox/01, CHANGELOG Changed.

**무엇** — `quad-roblox/src/init.luau:38`의 `local VERSION_PATTERN = "3.1.0"`. 설치 시점에 `TypeVersionCheck.matchesPattern(q.Version, VERSION_PATTERN)`로 검사하고 어긋나면 `UseProvider` 줄에서 즉시 raise합니다(`:78-83`). `type-version-check/src/init.luau` 헤더가 적어 두었듯 패턴 문법은 자리별 `*`(와일드카드)·`N^`(이상)·정확 일치를 지원하므로 **`"3.*.*"`나 `"3^.*.*"`가 이미 표현 가능합니다** — 지금 정확값을 쓰는 건 문법 제약이 아니라 선택입니다.

**왜 나중에 바꾸기 어려운가** — 두 층입니다. 첫째, 이건 **게시된 아티팩트 안에 굳는 값**이라 quad_roblox 3.1.0은 영원히 quad_base 3.1.0만 받습니다. 설치 문서(`docs/getting-started/00-installation.md:44-46`)는 `^3.0.0`을 권하는데, base만 3.2.0이 먼저 올라가거나 사용자가 `quad_roblox`만 고정하면 **해석은 성공하고 첫 `UseProvider`에서 죽습니다** — pesde가 막아 주지 못하는 조합입니다. 둘째, 헤더 주석이 *"독립 게시 백엔드는 여기만 느슨한 패턴으로 바꾸면 된다"*고 적어 둔 그 규약을, **정작 1호 백엔드가 정확값으로 시범 보이고 있습니다** — 서드파티 백엔드 작성자는 이 파일을 본보기로 삼을 것이고, 그들의 게시본에 박힌 패턴은 당신이 나중에 고칠 수 없습니다.

**지금 바꾼다면** — `VERSION_PATTERN`을 `"3.*.*"`(메이저 고정) 한 줄. `scripts/check-version.py`는 이미 *"VERSION_PATTERN이 그 버전을 받는지"*만 검사하므로(`:7`·`:92`) 느슨한 패턴도 그대로 통과하고, `bump`가 패턴을 새 버전으로 덮는 동작(`:8`)만 "패턴은 건드리지 않음"으로 바꾸면 됩니다. 총 두 줄 + 스펙 문구 하나(`quad-roblox/test/spec.robloxfactory.luau`).

**두면 어떤 대가** — 다섯 패키지 lockstep 게시가 **영구 의무**가 됩니다. quad-base의 오타 수정 하나에도 다섯 개를 다 올려야 하고, 하나라도 누락되면 소비자가 설치 단계에서 부서집니다.

**권고 — 지금 바꿈.** 메이저 안에서 base가 호환을 지킨다는 게 SemVer의 약속이므로 백엔드가 그보다 더 좁게 잠글 이유가 없습니다. **확신: 높음.**

---

## (3) 범용 패키지 둘(`quad_error`·`type_version_check`)이 quad의 버전 번호를 짊어지고 있다

**[결정 2026-09-15 — (나) lockstep에서 빼고 번호는 이어서]** 메인 보강: 레지스트리에 3.0.0~3.2.0이 이미 있어 1.0.0 새 출발은 번호 역전이라, 갈래를 (가) 영원히 lockstep / (나) 빼고 이어서(문법 좁힘이 자기 SemVer로 4.0.0) / (다) 1.0.0 + 3.x yank로 다시 올림. 사용자: *"나는 (나) 가 맞다고 봐. 확실히 처리된 이후 4.0.0 으로 내고, 3.x.x 는 전부 yank 해줄게. 이로써 quad 와 그 둘은 분리되어 버전이 올라. 이전 버전을 다시 어라운드 해서 1.0.0 으로 가는건 비동의."* 메인 해석: 둘 다 4.0.0(3.x 전부 yank면 `quad_error`도 새 번호가 있어야 설치된다). 반영: `check-version.py`(lockstep 넷 매니페스트만 + `bump-package`), `publish.py --with`(새 번호일 때만 게시, 쌍둥이에 CHANGELOG), 두 폴더 `CHANGELOG.md` 신설(문법 BREAKING 항목을 루트에서 이동), 매니페스트 includes, 두 README, 설치 문서 00, 루트 CHANGELOG 한 줄, conventions 버전 정책, HUMAN_TODO 20(게시 순서)·9. 저장소 분리(HUMAN_TODO 9)는 별개로 여전히 사용자 몫.

**무엇** — `quad-error/pesde.toml`과 `type-version-check/pesde.toml`이 둘 다 `version = "3.1.0"`이고, 설명문에는 스스로 *"engine-agnostic, **not quad-specific**"*이라고 적혀 있습니다. `type-version-check/src/init.luau` 헤더는 한 발 더 나가 *"사용자가 나중에 독립 저장소로 직접 분리할 예정(`HUMAN_TODO.md` 참고) — 그래서 이 파일 안에 `Quad`류 quad 전용 이름/타입을 절대 안 섞는다"*고 선언합니다.

**왜 나중에 바꾸기 어려운가** — 지금은 quad와 무관한 사람도 `qwreey/type_version_check@^3.1.0`을 쓸 수 있고, 실제로 쓰기 시작하면 **번호를 되돌릴 수 없습니다.** quad가 Slot 때문에 4.0.0으로 가면 이 두 패키지도 유령 메이저를 따라 올라가야 하고(안 올리면 lockstep이 깨짐), 반대로 독립 저장소로 떼어낼 때 `1.0.0`으로 되돌리는 건 레지스트리에서 불가능합니다. 지금 쓰는 사람이 없는 이 시점이 유일한 창입니다.

**지금 바꾼다면** — 두 패키지만 lockstep에서 빼고 자기 번호(예: `1.0.0`)를 주는 것. `scripts/check-version.py`의 자리 목록에서 둘을 빼고, 나머지 셋이 이들을 `workspace = ..., version = "^"`로 참조하는 지금 방식은 그대로 두면 됩니다(워크스페이스 참조라 번호가 갈려도 링크는 깨지지 않습니다). 부수 비용: 게시 절차에 "이 둘은 바뀔 때만 올린다"는 판단이 하나 늘어납니다.

**두면 어떤 대가** — 헤더가 선언한 분리 계획을 실행할 때 번호를 이어갈 수밖에 없고(quad_error 4.x로 시작하는 독립 저장소), 그 번호가 무엇을 뜻하는지 아무도 설명할 수 없게 됩니다.

**권고 — 지금 결정만**(하려면 3.2.0 때 같이, 미루려면 "영원히 lockstep"을 명시). **확신: 중상.** 분리 의사가 정말 있는지는 사용자만 압니다 — 분리 계획을 접는다면 그냥 lockstep이 맞습니다.

---

## (4) `slot.Length`/`slot.Offset`이 **쓰기 가능한 `Source<number>`**로 노출돼 있다

**[결정 2026-09-15 — `State<number>`로 업캐스트]** 사용자: *"ReadonlySource? ReadSource? 등으로 두거나, 아에 State 로 업케스팅 하는걸 검토해볼만 한듯. readonly 라는 의미 자체를 state 가 먹고 있어서 괜찮은거 같고, 내부적 다운캐스팅이 필요한건 케비엇이지만, 내부 계약이라 문제가 없어."* 새 이름(`ReadonlySource`)을 만들지 않고 기존 `State`가 읽기 전용의 뜻을 진다. 반영: `Slot`의 `read Length`/`read Offset: State<number>`, `:List`/`:Single` `updateFn`의 `offset: State<number>`; 실물은 여전히 Source이고 부기(`Bookkeeping.luau`)가 `any` 경로로 쓴다(추가 캐스트 불필요했음). 음성 실측: strict에서 `slot.Length:Set(99)` 거부. 문서 core/06·how-to 03·08·GS 13·스킬 둘, CHANGELOG BREAKING.

**무엇** — `quad-types/src/init.luau:516-517`. 레퍼런스(`docs/reference/core/06-slot.md:90-102, 116-126`)는 읽는 법만 설명하고 *"`Source`이므로 `:Compute`/`:Observer`로 그대로 구독할 수 있습니다"*라고 안내합니다. 그런데 타입이 `Source`라 `slot.Length:Set(99)`가 strict를 그냥 통과합니다. 실제 쓰기 주체는 부기뿐입니다 — `quad-base/src/Bookkeeping.luau:302`의 `ownerKey.Length:Set(sum)` 한 곳.

**왜 나중에 바꾸기 어려운가** — 사용자가 `:Set`을 부르면 접두합이 실제 자식 수와 어긋나 **조용히** 레이아웃이 틀어집니다(예외 안전성 계약상 quad는 복구하지 않습니다 — `architecture.md`의 "예외 안전성 계약 — 감싸지 않는다" 절). 나중에 `State<number>`로 좁히는 것은 타입 레벨 breaking이고, 방어 가드를 넣는 것은 hot path 비용입니다.

**지금 바꾼다면** — 공개 타입에서 두 필드를 `State<number>`로 선언(`State`엔 `:Set`/`:Emit`이 없고 `:Get`/`:Compute`/`:Observer`는 그대로 있으므로 문서가 안내하는 사용법은 전부 살아 있습니다). 내부 쓰기 한 줄(`Bookkeeping.luau:302`)은 impl 쪽 타입으로 읽거나 캐스트 하나면 됩니다. `Slot.List`의 `updateFn`이 넘겨받는 `offset: Source<number>`(`:532`, `:546`)도 같이 좁혀야 일관됩니다.

**두면 어떤 대가** — "부기를 사용자가 손으로 깰 수 있다"가 영구 UB로 남습니다. 위 (1)~(3)과 달리 이건 **틀린 코드가 에러 없이 도는** 종류라, 아래 (12)에서 말하는 "UB는 대체로 그냥 둔다" 원칙의 예외에 해당합니다.

**권고 — 지금 바꿈.** **확신: 높음.**

---

## (5) 공개 값 타입의 필드가 대부분 `read` 없이 선언돼 있다

**[결정 2026-09-15 — 붙임]** 사용자: *"5 도 확인해봤는데, read 를 타입에 붙이는건 단순해서 가능한것 같아."* 반영: `Ref`의 `Value`/`Revision`/`Callbacks`/`WeakCallbacks`, `Source.Revision`, `Epoch.Revision`(안 붙이면 `Source`가 `Epoch`에 안 들어간다 — 실측), `Observer`·`EffectHandle`의 `Subscribed`, `Blocker.IsBlocked`, `AttrKeyObject.Name`, `Timeout._native`. `Handler`·`q.debug` 제외. 실비용은 `Ref/init.luau`의 `:Set` 두 줄 캐스트뿐(Observer/Effect/Blocker/Source는 impl 타입으로 써서 무변경). 음성 실측: `ref.Value = 5`·`observer.Subscribed = true` strict 거부. 레퍼런스 시그니처 블록 네 페이지, CHANGELOG BREAKING.

**무엇** — `quad-types/src/init.luau`에서 마커 필드는 의도적으로 `read __quad*`인데(같은 파일 55·57·71·83행 등) 정작 사용자가 읽는 상태 필드들은 전부 쓰기 가능합니다: `Ref`의 `Value`/`Revision`/`Callbacks`/`WeakCallbacks`(159-162), `Observer.Subscribed`(195), `EffectHandle.Subscribed`(207), `Blocker.IsBlocked`(225), `Source.Revision`(405), `AttrKeyObject.Name`(332), `Timeout._native`(241). 레퍼런스는 전부 **읽는 것**으로만 서술합니다(예: `docs/reference/core/07-ref.md:172` *"지금 담긴 값. 직접 읽습니다"*, `sugar/06-blocker.md:82` *"`IsBlocked`를 그대로 읽는 얇은 접근자"*).

**왜 나중에 바꾸기 어려운가** — `read`를 나중에 붙이는 건 타입 레벨 breaking입니다. 지금 `ref.Value = x`나 `observer.Subscribed = true`를 쓰는 코드는 전부 내부 불변식을 깨는 잘못된 코드지만, 컴파일은 되므로 누군가는 씁니다. 그리고 `Revision`은 `Epoch` 계약의 핵심 값이라(`:113`) 사용자가 손대면 변경 감지가 통째로 어긋납니다.

**지금 바꾼다면** — 위 목록에 `read`를 붙이는 것. **공짜는 아닙니다**: `Ref`의 impl이 `self.Value = v`로 쓰는 자리가 있어서, 내부는 별도 impl 타입이나 캐스트를 써야 합니다(quad는 이미 impl/공개 타입을 가르는 패턴을 여러 곳에서 씁니다). `Handler` 레코드 필드(428-438)는 **사용자가 직접 만들어 넣는 것**이라 `read`를 붙이면 안 되고, `q.debug`(555)는 문서가 `q.debug = true`를 명시적으로 권하므로(`docs/reference/core/01-quad-module.md:170`) 제외해야 합니다.

**두면 어떤 대가** — 표현이 영구히 고정됩니다. 예컨대 `Ref.Callbacks`를 나중에 다른 자료구조로 바꾸고 싶어도 "사용자가 직접 넣을 수 있었다"는 이유로 못 바꿉니다.

**권고 — 지금 바꿈**(단 `Handler`·`q.debug` 제외). **확신: 중상** — 방향은 확실하고, 내부 캐스트 비용만 실제로 짜 봐야 정확합니다.

---

## (6) `Store`의 예약 키가 셋뿐이고 **확장 정책이 없다**

**[결정 2026-09-15 — (i)+(iii): 메소드 동결 + `__` 접두 예약]** 메인 권고(보이는 메소드는 `Of`/`Names`로 계약상 동결하고 새 기능은 `q.` 쪽 함수·슈거로, 팬텀·마커 필드가 늘 자리는 `__` 접두 전체 예약; 계획된 Store 메소드 없음 grep 확인), 사용자: *"나도 가/나 에 동의."* 반영: `Store.luau` `isReserved`(RESERVED + `__` 접두)·quad-types `CheckReservedKeys` 사본, `spec.store` §3에 `__anything`, 레퍼런스 core/04 "예약 키" 절(메소드 동결 약속), CHANGELOG BREAKING, `base/store-plan.md` 배너.

**무엇** — `quad-base/src/Store.luau:47`의 `RESERVED = { Of = true, Names = true, __reservedCheck = true }`와 그 타입 쪽 사본 `quad-types/src/init.luau:473-485`(`CheckReservedKeys`). `Store<T> = T & { Of, Names, __reservedCheck }`(488-492)라 **사용자 필드와 Store 메소드가 같은 이름 공간에 삽니다.**

**왜 나중에 바꾸기 어려운가** — `Store`에 새 메소드를 하나 붙이는 순간(`:Has`, `:Keys`, `:Observe`, `:Clear` 무엇이든) 그 이름을 필드로 쓰던 모든 사용자 코드가 깨집니다. 게다가 `store.hp` 같은 평범한 단어가 쓰이는 자리라 충돌 확률이 낮지 않습니다. **이 위험을 막는 메커니즘(타입 함수 진단)은 이미 있는데, 늘릴 자리를 미리 잡아두는 *정책*이 없습니다.**

**지금 바꾼다면** — 셋 중 하나를 지금 정하면 됩니다. (i) 접두어 예약 — `__`로 시작하는 키를 전부 예약으로 선언하고 앞으로의 메소드는 거기 두거나, (ii) 확장 자리 하나 예약 — 지금 `Of`/`Names`만 두고 미래 메소드는 전부 한 필드 아래로(예약 키를 하나 더 잡아두는 것), (iii) "Store는 앞으로 메소드를 추가하지 않는다"를 명시적 계약으로 못 박기. 어느 쪽이든 코드 변경은 `RESERVED` 테이블과 타입 함수 사본을 같이 고치는 몇 줄입니다(두 곳을 같이 고치라는 주의는 `Store.luau:20-22`에 이미 적혀 있습니다).

**두면 어떤 대가** — Store가 영원히 못 자라거나, 자라는 순간 breaking을 냅니다.

**권고 — 지금 결정만.** **확신: 중상.**

---

## (7) `Slot:List`와 `Slot:Single`의 인자 순서·개수가 갈라져 있다

**[2026-09-15 사용자 논의 — 테이블 방향, 결정 전]** 사용자: *"updateFn 이 list/single 공유되게 사용될 수 있다는 점에서 index 가 0 으로 의미없는게 single 에도 들어가더라도 괜찮을것 같아. 그런데 인자 나열이 확장성이 없고, 자동완성 상 입력할 것도 많고 불편 … 인자의 순서에 따라 민감하고 실수 가능 표면이 너무 넓어서, 테이블 사용이 편해보여. 다만 테이블을 한번 만들고, 계속 set 해서 재활용 … update 패스 이후엔 table.clear … 해시 키가 코드줄에 그대로 있으면 … 프리해싱도 먹을거라, 빨라. 다른 필드를 직접 쓰는건 저장되지 않는다는 … 케비엇을 남기가만 하면"*. 메인 의견: 입력만 테이블(반환 `(result, userdata)`는 유지), 재사용 비용 논거는 맞다. 걸리는 셋 — (a) `updateFn` 안에서 만드는 `:Compute`·이벤트 콜백이 `ctx`를 클로저로 붙잡으면 클리어 뒤 nil/다른 항목 값을 조용히 읽는다(React 16 SyntheticEvent 풀링이 같은 문제로 17에서 제거된 선례) → 경고문 대신 `__index` 메타메소드 가드(없는 키 읽기에서만 불림 — 활성 중엔 nil, 비활성이면 "필드를 지역으로 옮겨라" 에러); (b) 재진입 — 모듈 공용이면 중첩 Slot reconcile이 덮으므로 최소 Slot마다, 같은 Slot 동기 재진입 경로가 있으면 활성 중일 때만 새 테이블; (c) 타입 — `Slot<T>` 재귀 그룹 안에서 메소드 제네릭을 받는 별칭은 거부된 기록(`quad-types` `Slot` 주석)이라 인라인 레코드가 필요할 수 있음. 제안 순서: 스파이크(두 솔버 타입·재진입 경로·1000항목 새 테이블 vs 재사용 측정) → 재사용 + 가드. BREAKING(모든 `updateFn`).

**[2026-09-15 실측 → 새 테이블]** 사용자: *"t.clear 와 그냥 계속 생성하는 테이블 간 성능 편차를 실즉하고, 별다른 문제가 없다면 후자로 단순 생성하는게 나아보여. 클로저를 생각 못 했어서 … 의미 없는 선재 최적화로 약점을 만들게 될 수도"*. 실측 원장 `audit/updatefn-ctx-table-bench-2026-09-15/REPORT.md`(스크립트 둘 동봉): 호출당 새 테이블은 재사용보다 27~50 ns 더 들고(-O0~-O2·codegen 전부), 매 호출 `clear`는 새 테이블보다 느리다. 실제 mock reconcile 1000항목 갱신 패스(가장 가벼운 `updateFn`)에서 새 테이블 − 재사용 ≈ 패스당 0.1~0.15 ms — 조건 충족으로 **매 호출 새 테이블**. 재진입·클로저 가드 문제는 이걸로 사라진다. 남은 것: (c) 타입 모양 스파이크(인라인 레코드 vs 별칭, 두 솔버), 반환 `(result, userdata)` 유지 확인, 필드 이름 확정(`item`/`index`/`offset`/`prev`/`userdata`), 구현·문서·CHANGELOG BREAKING.

**[결정 2026-09-15 — 새 테이블, PascalCase]** 사용자: *"새 테이블의 유일한 약점은 gc 압력이 높아진다인데, 그것 조차 이점에 비해서 무의미한것 같아"*, 필드 케이싱은 선택 문항에서 PascalCase(`Item`/`Index`/`Offset`/`Prev`/`UserData` — quad가 채워 넘기는 읽기용 레코드라 `Ref.Value`·`slot.Offset`·옵션 키 `Owned`와 같은 줄; lowercase 선례는 사용자가 채우는 `Handler` 레코드뿐). 반영: `Slot/List.luau` 두 호출 자리가 매 호출 `{ Item, Index, Offset, Prev, UserData }`, `:Single`은 래퍼 없이 같은 `updateFn`을 `:List`에 그대로 넘긴다(`Index`도 실제 물리 위치). 타입은 두 시그니처에 인라인 레코드(별칭은 `Slot<T>` 재귀 그룹 제약으로 안 뺌) — 필드에 `read`를 안 붙인다(사용자가 평범한 레코드로 주석을 달면 반공변 자리에서 어긋남). 사용자 쪽 별칭 `type Ctx<Item, UD> = {...}` 주석이 strict에서 서는 것은 `spec.slottypes.luau`로 확인(두 솔버 test.sh). 반환 `(result, userdata)` 유지. 공개 별칭 타입(예: `SlotUpdateContext`)은 새 이름이라 만들지 않았다 — 요구가 보이면 문항.

**무엇** — `quad-types/src/init.luau:529-548`. 사용자가 보는 모양은 `slot:List(data, updateFn, keyFn?, opts?)`와 `slot:Single(state, updateFn?, opts?)`이고, `updateFn`이 받는 인자는 각각 `(item, index, offset, prev, ud)`와 `(item, offset, prev, ud)`입니다. 레퍼런스도 이 차이를 그대로 적습니다(`docs/reference/core/06-slot.md:124` *"`:Single`에서는 `index`가 빠져 두 번째"*).

**왜 나중에 바꾸기 어려운가** — 두 가지가 겹칩니다. 첫째, `:Single`에서 `:List`로(또는 반대로) 옮겨 쓰는 리팩터에서 **인자가 조용히 한 칸 밀립니다** — `offset`(Source)을 `index`(number)로 받아 산술을 하면 타입 에러가 나겠지만, `prev`/`ud` 자리는 둘 다 밀려도 타입이 느슨해 통과할 수 있습니다. 둘째, `opts`가 `:List`에선 4번째, `:Single`에선 3번째라 **`opts`만 주려면 `:List`에선 `keyFn` 자리에 `nil`을 채워야 합니다**(`slot:List(data, fn, nil, { Owned = false })`).

**지금 바꾼다면** — 두 갈래입니다. (i) `updateFn`의 인자를 **테이블 하나**로 통일(`fn(ctx)` — `ctx.item`/`ctx.index`/`ctx.offset`/`ctx.prev`/`ctx.ud`): 두 API가 같은 모양이 되고 인자가 늘어도 안 밀립니다. 비용은 호출마다 테이블 하나(hot path — `:List`는 항목마다 돕니다)와 문서·스펙 전면 개정. (ii) `:Single`의 `updateFn`에도 `index`를 넣어 **자리만 맞추기**(항상 1) — 훨씬 싸지만 의미 없는 인자가 생깁니다. (iii) 그대로 두고 `opts`만 마지막 자리로 통일.

**두면 어떤 대가** — 두 API를 오가는 사용자가 밀린 인자에 걸립니다. 다만 **이건 조용히 깨지기보다 대체로 타입 에러로 잡히는 종류**라 (4)만큼 위험하진 않습니다.

**권고 — 지금 결정만.** 개인적으로는 (i)이 옳지만 hot path 비용이 실측되지 않았고, `:Single`의 `<Item, UD>` 시그니처는 바로 이틀 전(2026-09-11, D10)에 사용자가 직접 확정한 것이라 다시 여는 데 비용이 있습니다. **확신: 중** — 문제는 실재하나 최선의 모양은 불확실합니다.

---

## (8) `Modifier:Peek<<T>>`의 `T`가 "프로퍼티 타입"이 아니라 "값 대수 전부"다

**[2026-09-15 사용자 회신 — 잠정 변경 표면임에 동의, 설계는 검토 중(결정 아님)]** 사용자: *"nil 도 존재하고, T 를
받아 T | State<T> | None | nil 형태로 던져주는건 가능해보이는데, T 를 T | Tween<T> 까지 확장시키는건 엔진 표면을
모르는 우리가 못 해. 아마 그건 유저의 책임 같아. 전체 T 를 쓰는걸 유저 책임으로 둘지, 아니면 엔진 표면은 직접
써야하고, 필요에 맞춰 써야하지만 내부적 요소들은 확장을 해줄지"*. 갈래는 둘이다 — (가) `T`는 저장된 값 전체라
호출자가 `State`/`None`까지 적는다(`Peek<<UDim2 | State<UDim2> | None>>`), (나) base가 소유한 층(`State`·`None`·`nil`)은
base가 감싸고 백엔드가 소유한 층(`Tween` 등)만 호출자가 `T` 안에 넣는다. **(나)가 지금 코드의 실제 모양**이다
(`FieldOut<T> = T | State<T> | None`, 반환 `?`). 메인 의견은 (나) 유지 + 레퍼런스에 층 나눔을 규칙으로 적기 —
base는 백엔드의 값 층을 열거할 수 없고(quad-spring이 `Spring<T>`를 더할 수 있다), 생성 `<Class>Modifier:Peek`는
백엔드가 층을 이미 채워 주므로 호출자 몫은 무타입 `q.Modifier()`를 프로바이더 아래에서 쓸 때만 생긴다.

**[결정 2026-09-15 — (나) 유지 + 백엔드마다 레퍼런스에 층 나눔 명시]** 사용자: *"8번에 대한 네 생각은 나도 동의해. 세번째 가능성은 너무 오버엔지니어링 같음. 각 백엔드 마다 층 나눔을 레퍼런스에 적는게 가장 간단하고, 다른 백엔드에 있어서도 처리가 가능케 두는것 같음. 만일 처리를 넣는다 하면 다른 백엔드에서 온 modifier 조작기가 그대로 통과하는 등 다른 표면 문제를 낼 가능성이 있지 않을까 직감적으로 느껴지거든."* 기각: 프로바이더가 `UseProvider` 반환 교집합으로 base `Modifier`의 `Peek`를 다시 입히는 안(오버엔지니어링 + 다른 백엔드 조작기 통과 위험). 반영: 레퍼런스 core/08(base 층 규칙)·roblox/03(Tween 층·무타입 호출 예)·extend/01(백엔드의 문서화 의무). 코드 무변경.

**무엇** — `quad-types/src/init.luau:352`와 그 위 주석 376-383. 주석이 스스로 경고합니다: *"⚠️ 프로바이더 아래에서도 base `Modifier()`의 `Peek`는 이 정의를 쓰므로 `Peek<<UDim2>>`는 Tween 팔이 없다 — 그 필드가 Tween을 품을 수 있으면 `Peek<<UDim2 | Tween<UDim2>>>`로 부를 것"*.

**왜 나중에 바꾸기 어려운가** — 명시 타입 인자의 **의미**가 계약이 됐습니다. 사용자는 `Peek<<UDim2>>`라고 쓰면 "UDim2 프로퍼티를 본다"는 뜻이길 기대하는데 실제 뜻은 "저장된 값이 정확히 `UDim2 | State<UDim2> | None`이다"입니다. 나중에 `T`의 의미를 "프로퍼티 타입"으로 바꾸면 **기존 호출부가 전부 틀린 타입을 받습니다**(에러가 아니라 잘못된 좁힘 — 가장 나쁜 종류의 breaking).

**지금 바꾼다면** — 생성 `<Class>Modifier`의 `Peek`는 이미 별칭으로 덮어 올바른 대수를 주므로(같은 주석), 문제는 **무타입 base `Modifier()`의 `Peek`뿐**입니다. 그 자리의 이름을 갈라 두는 방법이 있습니다(예: base 쪽은 `PeekRaw`, 또는 `Peek`의 `T`를 "프로퍼티 타입"으로 재정의하고 반환을 `FieldOut<T | Tween<T>>`가 아니라 백엔드가 별칭하게). 어느 쪽이든 지금은 호출부가 거의 없어 싸고, 쓰기 시작한 뒤엔 불가능합니다.

**두면 어떤 대가** — `Peek`는 쓰는 사람이 많지 않은 표면이라 피해 범위가 좁습니다. 대신 이 관행이 `store:Of<<U>>`·`Operator.Indexed<<V>>` 등 다른 `<<T>>` 자리의 해석 기준으로 굳습니다.

**권고 — 지금 결정만**(적어도 "T는 값 대수 전부"를 레퍼런스 본문에 못 박을 것 — 지금은 타입 파일 주석에만 있습니다). **확신: 중상.**

---

## (9) `AddPlugin`이 충돌을 전혀 검사하지 않는다

**[결정 2026-09-15 — 허용 + `q.debug` 경고]** 사용자: *"사용자층 문제가 아니라 플러그인 프로바이더측 문제이긴 하나,
막는게 아주 쉽고 런타임 내내 실행이 아니라 플러그인 추가에서만 체킹되므로 괜찮은것 같음. 내 권고는 debug 모드일 때
알려주는것, 의도적으로 코어 부품을 확장하는 경우를 완전히 닫아버릴 이유는 크게 존재하지 않는다고 보임. 단 확실히
문제를 일으키고 위험한 표면이기에 디버거에 눈에 띄어야할 이유는 존재함."* 반영: `module.AddPlugin`이 `module.debug`일
때 기존 값과 다른 값으로 덮는 키마다 `print` 한 줄(Dispatch 동률 경고와 같은 층), `UseProvider`는 제외(프로바이더는
수명 스텁 등 기존 슬롯을 덮는 게 계약). 레퍼런스 core/01, CHANGELOG Added, `smoke.plugin.luau` 4절.

**무엇** — `quad-base/src/init.luau`의 `mergeExtension`(`for k, v in extension do self[k] = v end`)과 그것을 부르는 `module.AddPlugin`. `UseProvider`는 바로 아래에 1슬롯 identity 락이 있고 두 번째 프로바이더에 명시적 에러를 냅니다. **`AddPlugin`에는 아무것도 없습니다** — 플러그인이 `Source`나 `Dispatch`를 통째로 덮어써도 조용히 지나갑니다.

**왜 나중에 바꾸기 어려운가** — 이건 **의도적 확장점**입니다(*"라이브러리를 고치지 않고 props의 특수 키를 추가할 수 있습니다"* — CHANGELOG 3.0.0). 플러그인 생태계가 생긴 뒤 "코어 필드 섀도잉은 에러"를 넣으면 그때 돌던 플러그인이 깨집니다. 반대로 지금 정하면 공짜입니다.

**지금 바꾼다면** — `mergeExtension`에서 `self[k] ~= nil`이면 에러(또는 `q.debug`일 때 경고). 몇 줄이고, 플러그인끼리 덮어쓰는 것과 코어를 덮어쓰는 것을 가르고 싶으면 코어 키 집합 하나가 더 필요합니다.

**두면 어떤 대가** — 진단 불가능한 버그 한 종류가 영구히 열립니다(플러그인 두 개를 깔았더니 `q.Source`가 남의 것이 되는 상황이 아무 신호 없이 일어납니다).

**권고 — 지금 결정만**(에러/경고/허용 중 하나를 `architecture.md`나 `extend/01`에 명시). 막는 쪽이면 지금 바꾸는 게 맞습니다. **확신: 중상.**

---

## (10) `D` 네임스페이스에 클래스 이름과 예약 이름이 **같은 테이블에** 살고, 충돌 게이트가 없다

**[결정 2026-09-15 — 게이트 넣음]** 사용자: *"10번은 생성기 게이트를 두는게 맞는것 같아."* 반영: `scripts/gen-d.py`의
`names` 조립 직후 클래스 이름이 `New`/`Mapper`/`Modifier`/`Root` 중 하나면 `SystemExit`(Declaration·DeclarationMapper
두 테이블의 예약 이름을 한 집합으로). 지금 충돌 없음 — `gen-d.py check` 통과, 동작 변화 0.

**무엇** — `scripts/gen-d.py:738`이 `local D = { New = New, Mapper = Mapper, Modifier = ModifierNS }`를 만든 뒤 `:739-741`에서 클래스마다 `D.<name> = ...`를 찍습니다. `DMapper`도 같은 모양으로 `Root`와 클래스 이름이 섞입니다(`:693-698`, `:733`). **Roblox가 `New`/`Mapper`/`Modifier`라는 클래스를 내놓으면 그 대입이 예약 필드를 조용히 덮어씁니다.** 생성기에는 이 충돌을 잡는 게이트가 없습니다 — 반면 `<Class>Modifier`의 예약 메소드 충돌은 제대로 막혀 있습니다(`:618-627`, `property collides with a reserved Modifier method`로 `SystemExit`).

**왜 나중에 바꾸기 어려운가** — 충돌이 실제로 나면 **출구가 없습니다.** 예약 이름을 옮기면 모든 사용자 코드가 깨지고, 클래스를 빼면 그 클래스를 못 씁니다. 지금 게이트를 넣으면 그날 생성기가 멈춰서 사람이 결정할 기회를 얻습니다.

**지금 바꾼다면** — 생성기에 `if name in {"New","Mapper","Modifier"}: raise SystemExit(...)`(그리고 `DMapper`엔 `Root`) 몇 줄. 이미 있는 예약 메소드 게이트와 완전히 같은 패턴입니다. 지금 실제 충돌은 없으므로 동작 변화 0입니다.

**두면 어떤 대가** — 확률이 낮은 대신 발생하면 회복 불가입니다. 비용이 0에 가까우므로 *"실제로 관측된 문제에만 구조를 쓴다"* 원칙과 충돌하지 않습니다 — 구조가 아니라 게이트 세 줄이고, 그 프로젝트의 다른 게이트들과 같은 층입니다.

**권고 — 지금 바꿈**(생성기 게이트). (1)번 개명을 한다면 그 커밋에 같이. **확신: 중상.**

---

## (11) 에러 문구가 유일한 계약인데 **안정성 정책이 없다**

**[결정 2026-09-15 — 지금은 (i) 정책 한 줄, 잠정 방향은 (i)+(ii) 둘 다 — (ii)는 리서치 백로그]** 사용자: *"11 번은 권고가 맞다고 봐. 에러는 처음부터 '믿을 수 있는 정보 근원' 은 아니야. 분기 근원이 되어선 안 돼. 다만 문서에 grep 할 수 있는 표면이 없다는건 아쉽게 느껴져. 보통 luau 의 문제들이나 ts 의 문제들이 나면 뒤에 TS2339: Property does not exist on type. 같은게 달려 … 문서에 ref 를 걸 때 깨짐을 어떻게 잡느냐도 중요해 … 가, 나 둘 다 적절히 택하는게 맞다고 봐. 다만 이건 완전 비파괴적이고(우리가 에러 자체에 대한 선언을 바뀔 수 있다 두니까) 백로깅 하고 유심히 더 살펴봐야할것 같아. 당장은 따라서 가, 그러나 잠정은 가 나 둘다"*. 반영: 레퍼런스 core/01 `q.errorNamespace`·extend/01 머리에 정책, 스킬 진단표 머리 문장(진단용이지 분기용 아님), CHANGELOG 문서 명시, ROADMAP 백로그(에러 식별자·문서 앵커 리서치). 같은 회신의 부수 결정: 필드를 메소드 대신 쓸 때 생기는 strict 좁힘 캐비엇(Blocker `Blocking`·`Subscribed`)은 런타임 비용을 들여 고치지 않고 캐비엇으로 — 사용자 *"생각보다 부적합함이 느껴지긴 하네. 다만 이건 Subscribed 에도 있는 문제라 케비엇이 되는게 맞아보임. 런타임 비용을 포기하고 타입 좁힘을 해소하려 하기엔 다소 복잡"* → 레퍼런스 sugar/06·core/05.

**무엇** — 문서·스킬이 에러 문구를 verbatim으로 싣고(레퍼런스 여러 페이지), `architecture.md`의 2026-09-08 결정이 *"메시지 리터럴은 raise 줄에 통째로 남긴다"*로 헬퍼를 명시적으로 기각했습니다. 모양은 `주어: 이유 (got X)`로 통일돼 있습니다. 그런데 **quad-error에는 에러 *식별자*가 없습니다** — `quad-error/src/init.luau`의 `errorAt`/`errorBefore`/`*Nearest`는 전부 문자열(`content: any`)을 `error()`로 던질 뿐이고, 코드·태그·타입이 없습니다. 사용자가 특정 에러를 프로그램적으로 구분하려면 `string.find`밖에 없습니다.

**왜 나중에 바꾸기 어려운가** — 사용자가 문자열 매칭을 시작하면 **모든 문구가 영구 API가 됩니다.** 오타 하나 고치는 것도 breaking이 되고, 실제로 3.0.0→3.1.0에서 이미 문구 하나를 바꿨습니다(nil 구멍 에러 — CHANGELOG `[3.1.0] Changed`). 그때는 *"동작 변화 없음"*으로 적었는데, 문자열을 매칭하던 사람에겐 동작 변화입니다.

**지금 바꾼다면** — 두 갈래이고 비용이 크게 다릅니다. (i) **정책 한 줄**: "에러 메시지는 진단이지 API가 아니다 — 문구로 분기하지 말 것"을 `docs/reference/core/01-quad-module.md`의 `q.errorNamespace` 절과 `extend/01`에 명시. 비용 거의 0. (ii) **식별자 도입**: 에러를 테이블로 던지거나 코드를 붙이는 것. quad-error의 설계(사용자 본인 실험을 as-is로 채택)를 건드리는 일이고 `Fallback`/`Traceback`의 `err: any` 계약과도 엮여 규모가 큽니다.

**두면 어떤 대가** — 문구를 손볼 자유를 잃습니다. 특히 (i)을 안 적으면 "안 적었으니 안정적인 줄 알았다"는 주장을 반박할 근거가 없습니다.

**권고 — (i)을 지금.** (ii)는 실제 요구가 관측될 때까지 열지 말 것(관측된 문제에만 구조를 쓴다는 원칙 그대로). **확신: 높음**(정책 한 줄에 한해서).

---

## (12) 문서가 UB로 둔 것들 — 지금 조일지, 영원히 UB로 못 박을지

**[결정 2026-09-15 — 가드, 모양은 사용자 설계]** 메인 실측으로 전제 정정: 의존성 간선은 인스턴스를 넘어도 멀쩡하고, 깨지는 건 인스턴스별 생명주기 레지스트리(다른 인스턴스 Effect 결합 시 실행 안 됨·이중 결합 검사 갈림, Roblox 백엔드도 같은 구조). 메인 권고 (나) 핸들에 모듈 기록 + 결합 자리 비교. 사용자: *"권고가 맞다고 봐. 프로바이더 측 문제가 아니라 유저측 문제고, 조용히 섞이면 디버깅이 치명적이게 힘들어서, 가드 비용에 비해서 싼 필드 하나는 좋아. 근데 gc 영향을 주지 않는 방어적으로 코딩하기 위해 identity 를 잡는 테이블 같은건 비어있는걸 써서 비교해야한다고 봐. 다만 외부 객체에 대해서 섞이는건 방어하지 못해서, 반쯤만 막히는걸수도 있어. … 난 그래서 가장 단순하게 가고싶어. 각 모듈들이 처리해야할 부분이 되고, quad-base 는 단순히 Quad.identity (또는 명시적 moduleIdentity) 를 제공해. 그냥 테이블 하나고, 필요한 곳에서 끌어가서 붙이고 비교해야하도록 둬야할듯 해. 각 모듈 구조를 아는 구현자만이 그걸 어떻게 저장할 지 알 수 있거든. userdata 면 릴레이션을 해야할 수도 있고, 단순 테이블이면 필드가 가장 싸고."* 이름은 선택지 질문으로 `moduleIdentity`(항등 함수 뜻 `identityUpdateFn`과 구분). 반영: `New()`의 `moduleIdentity = {}`, quad-types `read moduleIdentity: {}`, `ModuleIdentity.luau`(dispatch 깊이/직접 호출 두 blame), Observer·Effect·State·Slot 인스턴스별 Impl에 `_moduleIdentity`, 받는 문 다섯(Observer/Effect/Slot 핸들러·StoreBind·`:List` 데이터), `spec.moduleidentity`, 레퍼런스 core/01(`q.New()` 경고 + `q.moduleIdentity` 절), CHANGELOG Added·Changed, `architecture.md` 13번 역전 배너. Ref·Blocker(공유 잎)·백엔드 op 직접 호출·`Claim` 이중 claim은 범위 밖(UB).

**무엇** — 지금 열려 있는 UB 목록: 인스턴스를 가로지르는 값 혼용(`architecture.md` 13번의 `H-186`), 같은 키 재진입, 숫자 키 자리의 `nil` 구멍, `D.New`의 클래스 이름 오타(Q41 — *"(c) 그대로·재개봉 금지"*로 닫힘), Instance를 매개로 한 Slot 순환(Q42 — UB), `Slot:Clear`의 창 안 파괴로 인한 동결(Q40 — (a) 그대로), `Fallback`/`Traceback`의 부분 트리 미회수(0절 (e) — UB).

**방향의 비대칭성을 먼저 짚습니다** — **조이는 변경(UB → 에러, 허용 → 검증)은 돌던 코드를 깨고, 푸는 변경(에러 → 허용)은 절대 안 깹니다.** 그래서 UB의 기본 권고는 **"그대로 두고 문서화"**이고, 예외는 **UB가 에러 없이 조용히 망가지는 경우**뿐입니다. 위 목록 대부분은 이미 시끄럽게 실패하거나(엔진이 raise) 사용자가 회신으로 닫은 것이라 다시 열 이유가 없습니다.

**예외 하나 — `H-186`(인스턴스 교차 값 혼용).** `architecture.md` 13번은 *"막는 가드를 일부러 안 둔다 — dep 쪽 가드는 절반만 막고(교차 `bindLifetime`은 base가 못 봄), 완전히 막으려면 주입 op 계약까지 번진다"*고 적고 *"M5에서 실 백엔드가 둘이 되면 재검토"*로 남겼습니다. **그 결정은 사용자가 하나도 없던 시점에 내려졌고, 다중 인스턴스 사용은 정확히 게시 이후에 늘어납니다.** 그리고 이 UB는 조용히 망가지는 쪽입니다(A의 Source에 B의 Effect를 걸면 레지스트리가 갈려 발화가 안 되거나 수명이 안 묶입니다 — 에러 없이).

**지금 바꾼다면** — 완전 방어는 여전히 비쌉니다(위 인용 그대로). 값싼 절반만 있습니다: 값에 자기 모듈 인스턴스를 기록하고 dep 수집 자리에서만 검사(교차 `bindLifetime`은 여전히 못 봄). 절반짜리 가드는 "막힌 줄 알았는데 안 막혔다"는 더 나쁜 오해를 만들 수 있어 조심해야 합니다.

**권고 — 지금 결정만**(둘 중 하나를 명시적으로: "영원히 UB, 문서로만" vs "3.2.0에 절반 가드"). 나머지 UB는 **그대로 + 문서화.** **확신: 중** — `H-186`을 다시 여는 판단은 사용자 몫이고, 근거는 "결정 시점에 사용자가 없었다"는 것 하나입니다.

---

## (13) `Brand`의 소문자 메소드 — 근거가 만료됐다

**[결정 2026-09-15 — 올림]** 사용자: *"13번 Brand 메소드를 대문자로 바꾼다 -> 동의"*. `Register`/`Is`로 개명(quad-types
정의, quad-base·quad-roblox 호출부·스펙, `base/brand-plan.md`·`architecture.md` 케이싱 절). CHANGELOG `[Unreleased]`
BREAKING — 브랜드를 직접 만드는 백엔드·플러그인 작성자만 해당. `Brand`라는 이름 자체는 그대로(`question.md` 1절).

**무엇** — `quad-types/src/init.luau:748-763`의 `Brand = { register, is }`. 소문자인 근거는 `architecture.md:505-560`의 케이싱 규칙이 명시합니다: *"`Brand`는 생성자가 있지만 **사용자 표면이 아닌 base 내부 유틸**"*. `question.md` 1절도 *"메소드 케이싱도 같이 볼 것 — `:register`/`:is`가 소문자인데 quad 공개 표면 관례는 PascalCase다… base 내부 유틸이라 지금은 기존 관례를 이었지만, 이름을 정할 때 같이 정리"*로 열어 뒀습니다.

**그때 근거가 지금도 성립하는가** — **아닙니다.** 2026-09-07 사용자 결정으로 `Brand()` 팩토리가 quad-base에서 **quad-types의 반환 테이블로 옮겨졌고**(`:772-773`), 그 자리의 주석이 이유를 적습니다: *"브랜드 **인스턴스**는 각 패키지가 자기 `Brand.luau`에 만든다(quad-base·quad-roblox·**장래 quad-spring의 `SpringBrand`**) — 팩토리가 여기 있어야 quad-base 없이도 브랜드를 만들 수 있다"*. 즉 이건 이제 **서드파티 백엔드 작성자가 쓰라고 게시한 공개 표면**이고, "base 내부 유틸"이라는 소문자 근거는 소멸했습니다.

**지금 바꾼다면** — `register`/`is` → `Register`/`Is`. 호출부는 각 패키지의 `Brand.luau`들과 술어 구현부라 수십 곳이지만 전부 이 레포 안입니다(사용자에게 노출되는 건 `q.isState` 같은 래퍼들이라 소비자 코드는 안 바뀝니다). 다만 `.claude/base/brand-plan.md`가 정본이니 같이 고쳐야 합니다.

**두면 어떤 대가** — 공개 표면에 케이싱 예외가 하나 영구히 남고, 그 예외의 근거 문장은 이미 거짓입니다. 서드파티가 `SpringBrand:register(x)`를 쓰기 시작하면 못 고칩니다.

**권고 — 지금 바꿈**(또는 최소한 케이싱 규칙에 "Brand는 의도적 예외"를 새 근거와 함께 명기 — 지금 적힌 근거로는 설명이 안 됩니다). 같은 절이 열어 둔 `Brand`라는 **이름 자체**는 별개 문제인데, 지금 하는 일이 집합 멤버십(`SomeBrand:is(x)`)이라 `Brand`가 나쁘지 않고 대안도 안 나와 있으니 **그대로**를 권고합니다. **확신: 중상.**

---

## (14) `Owned` 옵션 키 — 프로젝트가 스스로 "잠정"이라 표시해 둔 이름

**[결정 2026-09-15 — `OwnsElements`]** 사용자(아래 독립 조사 둘을 본 뒤): *"?.Owned 로 앞을 가리고 보면 의도가 완전히 희석되는데다가, 내부적으로 사용될 뿐에 가깝고 실질적으로 사용되는 표면은 아닌 정도라서, OwnsElements처럼 되어도 별 상관 없는것으로 보여. 이미 KeyGone 처럼 두 단어 조합으로 명료한 단어선택을 했던 적도 있고, 서브 flag 라서 바꾸지 말아야할 이유도 존재하진 않아. 장점을 포기해야할 단점이 보이지 않는 점에서"*. 반영: quad-types `SlotListOpts`, `Slot/List.luau`·`Elements.luau`와 주석, 스펙 둘, 문서 아홉(레퍼런스 core/06·10, GS 10·13, how-to 03, overview 02, Quadnomicon 5권, README, 스킬), `base/slot-plan.md` 배너·`question.md` 1절 해소, CHANGELOG BREAKING(옛 키는 조용히 무시되고 debug면 알림). 내부 필드 `_owned`는 그대로.

**[2026-09-15 독립 조사 둘(sonnet, 원장·`question.md` 차단) — 둘 다 `Owned` 유지 1순위, `OwnsElements` 2순위, `DestroyElements` 비권장]** 사용자는 `OwnsElements`에 동의하는 쪽이며 객관 확인을 요청(*"15처럼 반박이 나올 수도 있어서 깨끗한 맥락에서"*). 두 조사가 코드로 같은 사실을 확인했다 — `Owned = false`는 파괴 여부 하나가 아니라 **요소 수명 책임 모드 전체**를 바꾼다: (a) 빠진 요소를 파괴 대신 떼기만(`Slot/Raw.luau` `releaseElement`), (b) `Detach` 반환이 보관이 아니라 완전 해제로 격하되어 같은 키가 돌아와도 `ctx.Prev`가 nil(`Slot/List.luau` `settle`, 레퍼런스 core/06이 이미 가르침), (c) Slot 자신이 파괴될 때 자식을 파괴하지 않고 떼기만(`Slot/Tree.luau` `destroySlotTree`). 그래서 `DestroyElements`는 (b)를 약속하지 않는 좁은 이름이라 "`DestroyElements=false`인데 왜 `Prev`가 안 오지"라는 오독을 이름이 만든다(두 조사 공통). (i) **생태계 선례 조사**: 같은 뜻의 불리언 옵션 표준 이름은 못 찾음(Fusion은 불리언이 아니라 destructor 함수 `cleanup`/`doNothing`, Vide는 매핑 안 `cleanup()` — 미확인, 웹 UI 킷의 `destroyOnClose`는 `DestroyElements`와 같은 과소 서술). 결론 `Owned` 유지(중상), 바꾼다면 `OwnsElements`(중) — 방향 모호성("Slot이 소유당하는가?")을 없애는 게 유일한 실익, `ManagesElements`는 새 어휘라 약함, `KeepElementsAlive`/`RetainElements`는 `Detach`의 "보관"과 충돌. (ii) **코퍼스 정합·오독 조사**: 결론 `Owned` 유지(높음) — Quadnomicon 5권(`docs/quadnomicon/05-non-destructive-portal-and-ownership.md`)이 Ref·Attr·Slot 전역 "소유권 공리"를 이 어휘로 가르치고, 옵션 테이블의 다른 불리언(`Leading`/`Trailing`)이 한 낱말 형용사라 `OwnsElements` 같은 동사구 옵션 키는 선례가 없다; 극성 반전 `Borrowed = true`는 비용만 커서 기각. 방향 오독은 이 옵션이 요소를 들이는 `:List`/`:Single`에만 있어 문맥상 좁혀진다고 봄. **메인 정리**: 반박의 핵심은 "`OwnsElements`가 틀렸다"가 아니라 "`Owned`로도 충분하고 형용사 관례에 맞다"이며, `OwnsElements`의 실익(주어 방향 명시)은 두 조사 모두 인정했다. 둘 사이 선택은 표기 관례(한 낱말 형용사) 대 자기 설명성의 저울질이라 사용자 판단 대기. (부수 — 조사 (i)이 적은 "(c)에서 사용자가 만든 비소유 Slot은 자식의 `elementOwner` 기록도 풀지 않는다"는 메인이 `Slot/Tree.luau` `destroySlotTree`로 확인: 맞다 — 슈거 래퍼만 `releaseSugarWrapper`로 풀고, 사용자 Slot은 claim을 유지한다. 같은 함수의 Q14 (a) "두 루프 모두 해제"는 소유 Slot 쪽 분기 이야기라 모순 아님. 즉 (c)는 "파괴 안 함 + 소유 기록 유지"라 역시 파괴 한 축으로 안 줄어든다.)

**무엇** — `quad-types/src/init.luau:507`의 `SlotListOpts = { Owned: boolean? }`. `question.md` 1절이 직접 적습니다: *"`elementOwner`/`claimOwner`/`releaseOwner`와 같은 뿌리라 골랐지만 **잠정 이름**이다 — 형용사라 옵션 테이블 키로는 자연스러운데, 실제로 묻는 건 '이 Slot이 요소의 수명을 책임지는가'라서 `OwnsElements`처럼 주어를 드러내는 쪽이 나을 수도 있음."*

**왜 나중에 바꾸기 어려운가** — 옵션 테이블 키는 사용자 코드에 리터럴로 박히고, Luau는 잘못된 키를 strict에서 잡아 주므로(닫힌 레코드) 개명은 확실한 breaking입니다. 다만 이 옵션을 명시적으로 쓰는 사람은 드뭅니다(기본값 `true`).

**지금 바꾼다면** — 타입 한 줄 + 런타임 읽는 자리 두어 곳 + 문서. 매우 쌉니다.

**두면 어떤 대가** — `Owned = false`만 보고는 "무엇이 소유되지 않는다는 건지"(Slot이? 요소가?) 알 수 없습니다. 실제 뜻은 "이 Slot이 요소를 파괴하지 않는다"입니다.

**권고 — 지금 결정만**(바꿀 거면 지금이 마지막으로 싼 시점). 후보: `OwnsElements`(잠정 항목이 제안한 것), `DestroyElements`(실제 동작을 직접 말함). **확신: 중** — 이름 취향이라 사용자 판단.

---

## (15) `state:With(...)` — v1과 같은 이름, 다른 뜻이고, 이름이 뜻을 안 드러낸다

**[2026-09-15 사용자 논의 — 바꾸는 방향엔 동의, 낱말은 열어 둠]** 사용자 제안 `Watch`: *"Compute 처럼 일반형 동사로 Watch 붙이는거, 후행 생성 state 가 그것들을 '바라볼' 뿐, 값의 변경을 따라 자신도 업데이트가 될 뿐 그걸 직접 읽어오지 않는다는 점을 잘 드러내는 자기설명적 이름"*. `Observer`와의 구분(사용자): *"Observer 는 fn 이 해당 state 를 관측하는것(물론 get 이 안날 수도 있지만), Watch 는 state 가 다른 state 의 변경을 따라가는것"* — 개명하면 레퍼런스에 이 한 줄을 적는다. 대안 `Track`을 사용자가 제기해 **당장은 열린 표면**으로 남김. 메인 의견(`Watch` 쪽): `With`는 실제로 오독된 기록이 있고(`base/slot-plan.md` 8라운드 — `:With(offset):Compute(function(i, o))`의 `o`를 offset으로 읽음), `Track`은 반응형 어휘에서 "읽을 때 의존성을 기록"(Vue 코어 `track()`, MobX tracking)이나 "값을 추적해 따라감"으로 읽혀 값이 넘어온다는 같은 오해를 부를 수 있다. `Watch`의 약점은 Vue식 `watch(source, callback)` 습관인데, 함수를 넘기면 dep 검증(`H-70`)이 즉시 던지므로 조용히 틀리지 않는다. 개명 시 같이 할 것: GS 12·13장의 사용자 prop 이름 `props.Watch`(콜백 — Vue식 뜻) 변경, 옛 이름 별칭 없음, CHANGELOG BREAKING, v1 이관 문서의 "이름만 같은 다른 API" 각주 제거. 비용: 코드 `:With(` 6곳 + 타입·구현, 문서 28곳. **시한**: BREAKING이라 다음 릴리즈 bump 전에 정할 것.

**[2026-09-15 독립 조사 둘(sonnet, 이 절을 읽지 않게 차단) — 위 메인 의견(`Watch` 쪽)을 뒤집음]** 사용자 요청(*"객관적으로 어느 어휘가 맞는지"*). (i) **생태계 선례**: 순위 `With` > `DependOn` > `Track` > `Watch`. `watch`는 Vue `watch(source, cb)`로 "콜백이 돈다"가 압도적으로 굳어 있다(확신 높음). `track`은 Vue 코어·MobX·Vide `untrack`에서 "읽을 때 자동 등록" 뜻의 내부 용어이고 명시 인자로 부르는 선례가 없다. 같은 연산의 선례는 Fusion 내부 `depend(dependent, dependency)`(`dphfox/Fusion@2790f7b:src/Graph/depend.luau`, 사용처 Tween·Spring·Computed — 비공개 함수)와 RxJS `sample(notifier)`(동형, 이름이 생소). `With`의 약점은 RxJS `withLatestFrom` 잔상("with면 값을 가져온다"). (ii) **코퍼스 정합·읽기 오독**: 순위 `With` > `Track` ≈ `Watch`(둘 다 기각 쪽), 추가 후보 `Widen`(충돌 없음, 문장으로 어색). `Track`은 `docs/overview/01-why-quad.md`가 quad의 정체성으로 반복하는 "암묵 의존성 **추적**이 없다"와 같은 낱말이라 자기모순으로 읽힌다. `Watch`는 GS 12의 `props.Watch`(콜백을 받는 사용자 prop — 예제 이름이라 바꿀 수는 있음)와 겹치고, 체인 `a:Watch(b):Compute(fn)`이 두 단계 다 콜백이 있는 것처럼 읽힌다. `With`는 이웃 중 유일하게 콜백을 받지 않는 파생 메소드라 전치사의 중립성이 오히려 맞다. v1 충돌은 이관 문서 경고 여덟 곳으로 이미 치른 비용. **메인 종합**: 두 축이 독립적으로 같은 방향 — `Watch`·`Track`은 접는 게 맞다. 남는 선택은 `With` 존치(오독 기록 — `slot-plan.md` 8라운드 `o`를 offset으로 읽은 사례 — 은 RxJS식 "값이 따라온다" 오해와 같은 축이라 약점이 실재) vs 콜백·값 함의가 없는 서술형 동사(`DependOn` — Fusion 동형 선례, 두 낱말이라 quad의 짧은 동사 관례와 어긋남). 사용자 판단 대기.

**[2026-09-15 사용자 논의 — `Depend`]** 사용자: *"DependOn 은 아주 깔끔하게 맞아떨어지긴 해. Depend 로 적는건 너무 문법 파괴같음? 내 눈으로 봤을 때에도 With(offset):Compute(function(i, o)) 는 확실히 어색함이 드러나고, Watch():Compute() 도 둘 다 돌것 같음 … watch 안에서 cb 불릴 느낌"*, 이어서 *"compute 안에 deps 도 그렇고, effect 쪽도 deps 로 적는데 유사하고 의미론적으로 일치하는 맥락이라, 짝이 맞다는 장점"*. 메인 의견: `Depend` 찬성 — (1) 전치사 생략은 API 이름에서 흔하고 같은 연산의 선례 Fusion `depend(dependent, dependency)`도 `on`을 뗐다, 메소드 문법이라 리시버가 주어(`text:Depend(locale)` = text가 locale에 의존) — 방향 오독 여지 작음; (2) `:Compute(fn, ...deps)`·`q.Effect(fn, ...deps)`의 인자 이름과 같은 낱말이라 `:Depend(...deps)`가 "그 deps만 따로 거는 것"으로 짝이 맞는다(사용자 논거와 같음); (3) 콜백·값 전달 함의가 없다 — 반응형 어휘에서 dependency는 곧 "재계산 트리거"; (4) quad의 한 낱말 동사 관례(`Compute`/`Apply`/`Gate`)에 맞고 `DependOn`보다 짧다; (5) 한국어 문서의 "의존성"과 1:1. 코퍼스 충돌 없음(조사 (ii)·메인 grep — 주석 하나뿐). 약점: 영어 원어민에겐 `Depend(x)`가 살짝 어색할 수 있음(치명 아님). 확정되면 위 "개명 시 같이 할 것"에서 `props.Watch` 변경은 불필요(충돌 사라짐).

**[결정 2026-09-15 — `Depend`]** 사용자: *"15 번의 Depend도 나도 이견이 없는 부분이고, 지금 이름보다 훨씬 좋다고 생각해서 … 다른 어휘도 검토해 보았는데, Depend 가 가장 나아"*. 반영: quad-types `State.Depend`, `State.luau` `Impl.Depend`(+`setFuncLevel`), 스펙 셋, 레퍼런스 core/03(+`:Observer`와의 구분 한 줄·"값을 읽어 오지 않는다")·00-index, 나머지 문서(opus 위임), CHANGELOG BREAKING. 옛 `With` 별칭 없음. v1 `register:With(fn)` 역사 서술은 유지.

**무엇** — `quad-types/src/init.luau:391`, 레퍼런스 `docs/reference/core/03-state.md:102-118`. 뜻은 *"값은 그대로 두고 구독 범위만 넓히는 노드"*입니다. v1의 `register:With(fn)`은 파생(지금의 `:Compute`)이었고, CHANGELOG가 이미 경고합니다: *"3.x의 `state:With()`는 이름만 같은 다른 API입니다."*

**왜 나중에 바꾸기 어려운가** — 이름만이 계약인 메소드라 개명은 순수 breaking입니다.

**얼마나 위험한가 — 생각보다 낮습니다.** v1 사용자가 습관대로 `s:With(function() ... end)`를 쓰면 함수가 dep 자리에 들어가고, dep 검증이 State/Source/Ref만 받으므로(`H-70`) **즉시 에러가 납니다.** 조용히 틀리는 경로가 아닙니다. 남는 문제는 이름이 뜻을 안 드러낸다는 것뿐입니다 — `s:With(a, b)`만 보고 "a, b도 구독한다"를 읽어내긴 어렵습니다.

**지금 바꾼다면** — `:Watching(...)`/`:Also(...)`/`:DependingOn(...)` 류. 타입 한 줄 + 구현 + 문서 몇 곳. 쌉니다.

**두면 어떤 대가** — v1 이관 문서가 영구히 각주를 달아야 하고, 이름이 뜻을 안 드러내는 유일한 State 메소드로 남습니다(`:Get`/`:Compute`/`:Apply`/`:Gate`/`:Observer`는 전부 자기 설명적입니다).

**권고 — 지금 결정만.** 에러로 잡히므로 급하진 않지만, 바꿀 거면 지금입니다. **확신: 중.**

---

## (16) `Tag`/`Attr`/`Modifier`의 합성 어휘가 셋 다 다르다

**무엇** — `quad-types/src/init.luau`에서 `TagConstructor`는 `Merged`만(316), `AttrConstructor`는 `Merged` + `Overridden`(327-330), `ModifierConstructor`는 `Overridden`만(371-375, 그 외 `TypedFactory`/`DefineSubtype`). 세 형제 값 타입이 "여러 개를 하나로 합치는" 연산에 서로 다른 어휘를 씁니다.

**왜 나중에 바꾸기 어려운가 — 사실 어렵지 않습니다.** 없는 쪽에 **추가**하는 것은 비파괴적입니다(`Tag.Overridden`을 나중에 붙여도 기존 코드는 안 깨집니다). 문제는 있는 것을 **없애거나 옮길 때**뿐인데 그럴 이유가 없습니다.

**두면 어떤 대가** — 학습 부담(사용자가 매번 "이 타입엔 뭐가 있더라"를 찾아봐야 함)과, 각 타입에서 빠진 연산이 "일부러 없는 것"인지 "아직 없는 것"인지 문서로 알 수 없다는 것.

**권고 — 그대로**(필요하면 나중에 추가). 다만 **레퍼런스에 "왜 Tag엔 `Overridden`이 없는가"를 한 줄 적는 것**은 지금 공짜입니다(Tag는 이름 집합이라 덮어쓰기 개념이 없고, Attr은 이름→값이라 있습니다). **확신: 높음**(추가가 비파괴적이라는 점에서).

---

## (17) 모듈 표면에 선언되지 않은 언더스코어 필드 둘

**[결정 2026-09-15 — 명시, 권고보다 강하게]** 사용자: *"17번도 동의, _ 언더스코어 필드는 언제나 바뀔 수 있고, 내부
계약이지 외부 노출 표면은 아닌걸로 못박어도 될것 같음."* 반영: 레퍼런스 core/01(`AddPlugin` 절 뒤)·extend/01(1절 끝)과
`base/architecture.md` 케이싱 절에 "`_` 접두 필드는 공개 표면이 아닌 내부 계약, 언제든 바뀜". 이름을 바꾸거나 숨기지는 않는다.

**무엇** — `quad-base/src/` 전수에서 모듈에 대입되는 필드 중 `Quad` 타입에 없는 것이 둘입니다: `module._bookkeeping`, `module._slotInternal`. `quad-types/src/init.luau:241`의 `Timeout._native`도 같은 계열(공개 타입 안의 언더스코어 필드)입니다.

**왜 문제일 수 있는가** — 타입에 없으니 strict 사용자는 못 읽지만 런타임엔 존재합니다. 언더스코어가 "내부"를 뜻한다는 건 관례일 뿐이고, 이 프로젝트가 그 관례를 어디에도 명문화하지 않았습니다.

**권고 — 지금 결정만**(한 줄: "`_`로 시작하는 필드는 비공개이며 예고 없이 바뀐다"를 `extend/01`에 명시). 이름을 바꾸거나 숨길 필요는 없습니다. **확신: 중상.**

---

## 찾았지만 문제 아님 (같은 걱정을 두 번 하지 않도록)

- **`q`라는 한 글자** — 이건 사용자가 자기 파일에서 만드는 지역 이름이지 API가 아닙니다(`const q = require(...)`). 라이브러리가 강제하는 게 없습니다. 위 (1)에서 `D`가 문제인 이유는 **라이브러리가 `q.D`라는 필드 이름을 소유하기 때문**이고, `q`는 그렇지 않습니다.
- **[2026-09-15 정정 — (29)] 아래 "실제 표면 전체가 이 규칙을 따릅니다"는 틀렸다** — 규칙 문장이 관행을 다 설명하지 못했고, 문장을 고쳤다(`base/architecture.md` 케이싱 절 배너).
- **`isState`/`canBound` 등 소문자 vs `Source`/`Ref` 대문자** — `architecture.md:505-560`이 일관된 규칙을 명문화해 뒀습니다: *"이게 특정 프리미티브 타입 하나의 전용 소유물인가?"* — 그렇다면 대문자, 범용 유틸이거나 프리미티브가 아닌 엔진 소속이면 소문자. 실제 표면 전체가 이 규칙을 따릅니다. 재론 불필요합니다(유일한 예외가 위 (13)의 `Brand`).
- **`q.Ref<<Frame?>>(nil)`의 명시 타입 인자** — 결정이 끝났고 근거도 여전히 유효합니다(`base/ref-plan.md:421-442`, `H-167`/`H-168`). 2파라미터 React식 설계는 Luau 솔버가 미해소 제네릭 변수를 남겨 기각됐고, `default: T?`로 넓히는 안은 `Ref(5).Value`까지 nil 검사를 강요해 기각됐습니다. 보일러플레이트로 보이지만 React `useRef<HTMLDivElement>(null)`과 같은 UX입니다.
- **`Operator.Indexed<<V>>`·`OnCreated<<I>>`·`Single`의 명시 타입 인자** — 셋 다 **솔버 제약이지 설계 선택이 아닙니다**(`typing-limits.md` 8.15·8.16·8.19에 각각 실측 기록). 추론이 좋아지면 시그니처를 안 바꾸고 그냥 생략 가능해지는 종류라, 지금 손댈 것이 없습니다.
- **`state:Compute(fn, ...deps)`의 `fn` 위치** — `q.Effect(fn, ...deps)`와 같은 모양이고, 가변 인자가 뒤에 와야 하므로 `fn`이 앞일 수밖에 없습니다. 대안이 없습니다.
- **에러 메시지가 영어인 것** — 2026-08-25 사용자 확정이고(`architecture.md` error 계약 절), 문서 대조도 그 결정에 맞춰져 있습니다.
- **`hintValue` → `nextValue`** — 내부 클로저 파라미터 이름이라 소비자에게 보이지 않습니다. `question.md` 1절이 이미 "대기열에만 올림"으로 처리했고 그 판단이 맞습니다.
- **센티널 이름 `None`/`Detach`/`KeyGone`/`Void`/`MapperRoot`** — 각각 뜻이 고유하고 충돌 없습니다. `None`은 이미 확정 이력이 있습니다.
- **`q.D`/`q.Tween`이 백엔드 설치 전엔 nil인 것** — 타입 쪽이 정직합니다. `Quad` 타입에 `D`가 **아예 없고** `UseProvider`의 반환 교집합 `Self & P`로만 실리므로, 설치 전에 `q.D`를 쓰면 타입 에러가 납니다. 런타임 nil과 타입이 어긋나지 않습니다.
- **`Dispatch` 멤버가 소문자(`addHandler`)인데 상수는 대문자(`HANDLER_PRIORITY_HIGH`)인 것** — 위 케이싱 규칙(Dispatch는 프리미티브가 아니라 엔진 네임스페이스)과 상수 관례가 각각 따로 있고, 둘 다 일관 적용돼 있습니다.
- **`Handler` 레코드 필드가 쓰기 가능한 것** — 사용자가 **직접 만들어 넣는** 구조체라 `read`를 붙이면 안 됩니다. (5)번에서 제외한 이유입니다.
- **`Peek`가 `Modifier`와 `Context`에서 다른 일을 하는 것** — 둘 다 "평소 보장 없이 들여다본다"는 같은 결이고(`Modifier:Peek`는 저장된 원형, `Context:Peek`는 없으면 nil), 서로 다른 타입의 메소드라 혼동 가능성이 낮습니다.
- **`gen-d.py`의 `<Class>Modifier` 예약 메소드 충돌** — 이미 게이트가 있습니다(`:618-627`). 걱정할 필요 없습니다. 빠진 건 (10)의 `D` 네임스페이스 쪽뿐입니다.

---

## 미완·확인 못 한 것

**[2026-09-15 둘 다 닫힘]** 처음 이 절에 있던 미완 둘은 결정 반영 때 실측으로 닫혔다 — (5)번 `read` 전환 실비용은 `Ref/init.luau` `:Set`의 캐스트 두 줄뿐(나머지는 impl 타입으로 써서 무변경, (5)번 결정 줄), (7)번 `updateFn` 테이블화 hot path 비용은 `audit/updatefn-ctx-table-bench-2026-09-15/REPORT.md`(호출당 27~50 ns, 1000항목 패스당 0.1~0.15 ms — (7)번 실측 줄). 원장 밖 릴리즈 전 추가 탐사 결과는 이 절 아래에 쌓는다.

---

## 원장 밖 추가 탐사 (2026-09-15, opus 셋 — 타입 표면·런타임 계약과 패키징·문서 약속)

**[회신 4차 2026-09-15 — 이 절 결정 요약]** (19) **debug 층 경고** — 사용자: *"런타임 체킹을 넣기도 애매하고 … 클론을 하거나 처리를 넣어야할 필요는 모르겠음. debug 모드에서 블래임 해주는건 괜찮다고 봐 … 런타임 비용이 큰 블래임은 debug 모드에 넣는게 난 이롭다 … debug 는 치명적 부분 아니면 기본적으로 계속 실행은 시켜주자"* → 원칙은 `base/architecture.md`의 "debug 층" 절(신설), 반영: `Debounce`/`Throttle`·`Slot:List`/`:Single` opts·`Tween`·`Animate`에서 `q.debug`일 때 모르는 키 `print`(얕은 복사·에러 없음 — "살아 있는 옵션"도 그대로). (20) **UB 명시**(사용자 *"UB명시가 맞는것 같아"*) → 레퍼런스 core/03·05·07. (21) **동작 그대로 + UB 문서화** — 사용자: *"이미 언급되었던 것이야 … 라이브러리 잘못이 아니라, 유저 잘못임 … UB에 가깝고, 이 또한 debug 플래그 따라서 처리를 더할 순 있어도, 동작을 변경시킬 필요는 없다고 봐"* → core/06, `architecture.md` 예외 안전성 절에 한 줄(debug 처리는 이번엔 안 넣음). (22) **identity dedup** — 사용자: *"이건 내가 RunInit 처럼 dedup 하자고 했었음 … 구현 자체에 답이 있는듯"* → `AddPlugin`에 `pluginRelate`, 표시는 성공 후(UseProvider `H-307`과 같은 이유 — 메인 선택, RunInit의 실행 전 표시와 다름), `smoke.plugin` 5절. (24) **사전식 하한**(위 (2) 결정 줄). (23) 매니페스트 쪽은 사용자가 `^`를 메이저 고정 caret으로 유지하는 것으로 읽었다 — 다만 이미 게시된 3.2.0이 새 `quad_types`와 섞일 때의 Brand 런타임 호환 문제는 별도 문항으로 사용자에게 올림(대화형). (25) 사용자: *"어떻게 막히는지 보여주면 될듯"* → 스크래치 시연 뒤 결정. 문서 약속 묶음(라)은 사용자 *"알아서 고칠 수 있는 부분에 대해서는 확인했고, 괜찮다"* → 반영(랜딩 둘·GS 15·17·core/01·02·06·07·스킬·CHANGELOG 빈틈 셋; 스킬의 에러 문구 매칭 권고는 (11)과 같이). **체크포인트 리뷰(`/code-review high 1a7c4dc..04e8bad`) 문항 둘 — 같은 날 회신**: (i) 프리릴리즈 bump가 꼬리를 떼 rc 빌드끼리 섞이던 것 → (가) 꼬리 붙인 하한 `M.m^.p^-rc.N`, 사용자 *"프리릴리즈와 릴리즈 요소를 섞는건 안 되도록 하면 될것 같음. (나) 의 의도도 약간 실어서 막지만, (가) 도 필요해"*(설치 문서에 이유 한 줄 — 나머지 방향, 꼬리 없는 릴리즈 패턴이 rc base를 받는 것은 matcher의 2026-09-10 규칙이라 사용자에게 확인 중); **[2026-09-15 같은 날 — `type_version_check` 패턴 문법 재설계, 사용자 설계]** 위 (i)의 반대 방향(꼬리 없는 릴리즈 패턴이 rc base를 받음)을 물었더니 사용자가 (가)(매처) + (나)(쓰는 쪽이 고름)를 섞고, spring류 서드파티 백엔드의 한계를 짚어 문법 확장을 제안: *"breaking changes 가 나올 때 마다 메이저를 올려야하니, 변경 없는데 버전만 범핑된 spring 이 나올 수도 … 하위 호환성을 잃어서, 터져. 그렇다고 3^ 식을 하면 아에 추후 나오는 릴리즈 내에서 변경으로 터질수도 … 이전 요소에 이어 쓰는게 안 되는게 약간 문제"* → *"`|` 로 스프릿 하는걸 … 앞에 두는게 나아보임. 3.2^.0^|4.0^.0^ … 이전에 사용하던 구조는 여전히 허용되나, | or 집합이 허용된다는 확장 뿐"*, *"rc 꼬리의 경우는 %- 나눔 이후, 중간에 숫자가 아닌 글자가 오면 그건 단순 match 로 보고 그건 ^ 가 없고, 뒤 숫자는 동일히 *^ 가 가능"*, *"느슨한 패턴이 안 받는건 나쁠것 없어보여"*. 세부 회신: core에서 넘어도 prerelease는 따로 판정(*"rc 를 적을 땐 기본적으로 선행 부분이 확정 버전인걸 아는 경우 … | 를 넣었으니 처리가 가능"*), 자리 개수 불일치는 불일치, 첫 `-`에서만 나눔·build 먼저 제거. 확정 문법: `|` 대안 → build 제거 → 첫 `-` 분할 → 꼬리 유무 일치 → core·prerelease 각각 `.` 자리 판정(`*`/사전식 `N^`/정확). 반영: 런타임·type function·`check-version.py` 포트 세 벌(포트는 스펙 표 62건과 대조 0 불일치), 프리릴리즈 bump 패턴은 하한이 아니라 그 빌드 정확히(`M.m.p-rc.N`), `spec.versioncheck` 1~7절 재작성, 레퍼런스 core/01·extend/01·roblox/01·type-version-check README, CHANGELOG BREAKING(좁아진 한 규칙). 확인: pesde 0.7.4 바이너리는 Rust `semver::VersionReq`(Greater/GreaterEq/Less 비교자)를 써서 매니페스트에도 `>=3.2.0, <5.0.0` 같은 범위를 적을 수 있어 보인다(심볼 확인, 실제 해석은 미실측). (ii) 서로를 설치하는 플러그인 순환의 무한 재귀 → (가) UB 문서화, 사용자 *"디펜던시 부분에서도 꼬여서 패키지 부터 복잡해지는 일이라, 존재하기가 어렵고 막으려 처리를 넣을 이유가 없다 … pesde 상으로도 구성하기 힘들꺼라서"*. (18)·(26)~(32)와 원장 (3)·(6)·(11)·(12)는 사용자 지시 *"나머지는 하나하나 인터랙티브로 나에게 물어보면서"*로 대화형 진행.

사용자 요청: *"원장 내용 이외에 릴리즈 전에 더 처리해야할 내용이 나오는지 보고싶어"*. 셋 다 읽기 전용, 원장 1~17과 `[Unreleased]`를 먼저 읽고 겹치지 않게. 실측 스크래치는 세션 스크래치(`hunt-types/`·`hunt-runtime/`·`hunt-docs/`, 레포 밖)에 있었다. 메인이 직접 재확인한 것은 "메인 확인"으로 적는다. 아래 번호 (18)~는 이 절 안의 번호다. **새 필드·이름·메커니즘이 필요한 것은 전부 사용자 문항**이고 코드는 아직 안 건드렸다.

### 가. 동작 — 조용히 틀리는 것 (조이는 방향이라 지금이 싸다)

**[결정 2026-09-15 — (가) 돌려받는 즉시 던짐]** 사용자: *"(가) 로 두는게 맞는듯. 프로바이더에 의해 발생하는 규격보단 유저의 실수이고, 실수를 잡는데 런타임 타입 검사 하나로 싸게 처리 가능함. 빈번히 발생하는걸, 라이브러리 문제를 확인하기 위해 debug 를 켜는 방향에 결합할 이유는 없다고 봐 … Disconnect 같은걸 처리해주는 연결 객체 같은걸 만들고 싶으면, 그건 팩토리&커링 함수를 넣어서 해결이 가능한 표면이라서 새로운 규격을 내야할 이유도 없고, 순수 슈거로 처리 가능해. 코어를 확장할 이유는 안 보여 … 유용성이 있다고 생각하면 백로그에 두는건 나쁘지 않아보여. 순수 슈거 추가 표면이고 breaking 이 전혀 없음."* 반영: `Effect.luau` 재실행 루틴의 반환값 검사(최외곽 blame), `spec.effect` 절 하나(생성 시점·전파 시점), 레퍼런스 core/05, CHANGELOG Changed. (다) 연결 객체 인정은 기각 — 코어 확장 없이 순수 슈거(Disconnector류, 위치는 base 밖 어디든)로 ROADMAP 백로그. debug 층 원칙과의 경계(사용자): 흔한 사용자 실수를 싼 검사로 잡을 수 있으면 debug에 묶지 않는다.

**(18) Effect `fn`이 함수도 nil도 아닌 값을 돌려주면 그 자리에선 통과하고, 다음 재실행에서 quad 내부 줄이 터진 뒤 그 Effect가 영구히 죽는다** — 실측: `fn`이 `42`를 돌려주면 첫 의존성 변경에서 `Effect.luau`의 cleanup 호출이 *"attempt to call a number value"*, 다음 `Set`부터는 에러도 실행도 없이 조용하고, `:Unsubscribe()`는 사실과 다른 *"cannot change subscription from inside fn or cleanup"*으로 거부. React·Fusion 습관으로 연결 객체(`{ Disconnect = … }`)를 돌려주는 경우도 같다. 인스턴스 파괴 경로면 이 에러가 엔진 Destroying 시그널 안에서 난다. 사용자가 던진 게 아니라 quad가 받아들인 값 때문이라 예외 안전성 계약("사용자 코드가 던지면 죽는다") 밖이고, 위 (12)의 비대칭 원칙이 말한 "조용히 망가지는" 예외에 해당한다. 갈래: (가) 반환 직후 `function`/`nil`만 받고 나머지는 사용자 줄을 가리키는 에러(몇 줄), (나) 연결 객체·Instance도 받아 주기(새 메커니즘 — (가) 뒤에 넓혀도 비파괴). 탐사자 권고 (가), 확신 높음.

**(19) 옵션 테이블의 모르는 키(오타)가 런타임에서도 타입에서도 조용히 통과한다** — 실측: `q.Debounce({ Time = 0.3, leading = true })`, `q.Throttle({ …, MaxTimee = 1 })`, `slot:List(…, { owned = false })`가 에러 없이 만들어지고 오타 옵션은 무시된다; 구·신 솔버 둘 다 진단 없음(같은 파일의 음성 대조는 둘 다 잡음). `q.Debounce({ Time = "x" })`도 두 솔버에서 진단이 없었다(원인 미조사 — 옵션 타입이 사실상 느슨하다는 신호일 수 있음). 코드 판독: `Animate{}`는 고정 목록만 읽어 `Duration = 0.3` 같은 오타는 기본 시간으로 돈다. 같은 뿌리 하나 더: `Debounce`/`Throttle`은 옵션 테이블을 참조로 들고 창마다 `opts.Time`을 다시 읽고 `Animate`도 매 실행 다시 읽어, 만든 뒤 옵션 테이블을 고치면 동작이 따라 바뀌고 생성 시 검증도 우회된다(동적 값의 정식 통로 `State<number>`는 이미 있다). 갈래: (가) 모든 옵션 테이블에 "모르는 키는 에러" + 생성 시 얕은 복사(설치 시점 한 번, hot path 비용 없음), (나) `q.debug`일 때만 경고, (다) 문서화만. 정책이라 사용자 문항, 탐사자 권고 (가) 확신 중상.

**(20) 반응형 콜백 안의 yield에 계약이 없고, 실제 동작이 조용히 이상하다** — 실측: Observer `fn`이 첫 호출에서 `coroutine.yield()`하면 파동이 그 자리에서 멈추고, 그동안 바깥 `Unsubscribe`는 사실과 다른 "inside its own fn"으로 거부되며, 다른 스레드의 `Set`이 같은 `fn`을 동시에 재진입시킨다(로그 `A1start, A2start, A2end, A1end`). Roblox는 이벤트 핸들러가 전부 코루틴이라 콜백 안 `task.wait`는 흔한 실수다. 문서의 yield 언급은 `Ref:Wait`뿐. 갈래: (가) "Observer·Effect·Compute·Ref 콜백과 cleanup 안의 yield는 UB"를 core/03·05·07에 명시(비용 0), (나) `q.debug`일 때 yield 감지 경고(새 메커니즘 — 문항). 탐사자 권고 최소 (가), 확신 중상.

**(21) `:List`의 `updateFn`이 도중에 던지면 그 Slot이 영구히 재계산되지 않는다(문서에 없음)** — 메인 확인(`quad-base/src/Slot/List.luau` `reconcile`): 배치 Blocker를 켠 뒤(`ownsGate`) 끄는 줄은 정상 종료 때만 돈다 — 다음 사이클은 `blocker:IsOn()`이 이미 참이라 `ownsGate`가 거짓이고 끄는 사람이 없다. quad 자신의 에러도 같은 창에서 난다(이미 마운트된 원소를 반환해 `settle`이 던질 때, KeyGone에 원소를 돌려줄 때). 키 계산의 두 에러(nil·중복 키)는 Blocker를 켜기 전이라 안전. 같은 부류를 `:Clear`는 Q40 (a) "그대로"로 닫았고 레퍼런스 `06-slot.md`가 `:Clear`에만 경고한다. 탐사자 제안은 동작 그대로 + `:List` 절에 같은 경고 한 줄. 메인 의견: Q40과 같은 부류라 문서화가 일관되나, `:List`는 사용자 `updateFn`이 매 갱신마다 도는 자리라 `:Clear`보다 밟기 쉽다 — 경고로 둘지 끄는 줄을 보장할지(`pcall` 없이는 불가 — 감싸지 않는다는 계약과 충돌)는 사용자 판단.

**(22) `AddPlugin`에 멱등성이 없다** — 실측: 핸들러 하나를 등록하는 플러그인을 두 번 `AddPlugin`하면 두 번 실행되어 같은 이름 핸들러가 `listHandlers()`에 둘, `q.debug`에선 자기 필드를 덮는다고 경고까지 낸다. `UseProvider`는 "require 캐시가 같은 identity를 주므로 여러 스크립트가 불러도 no-op"을 이유로 identity 락이 있는데, 여러 LocalScript가 공유 설정 모듈 밖에서 각자 `AddPlugin`하는 같은 상황이 플러그인엔 없다. 갈래: (가) 같은 `pluginFn` identity 재호출은 no-op(`RunInit` 가드와 같은 모양, 새 필드 없음), (나) "한 번만 부를 것" 문서화. 위 (9)의 경고 설계와 겹쳐 사용자 문항. 탐사자 권고 (가), 확신 중상.

### 나. 패키징·버전 — 다음 릴리즈 자체가 걸린 것

**(23) 패키지끼리 `version = "^"`로 물려 있는데 다음 릴리즈에 런타임 BREAKING(Brand 개명)이 마이너로 실린다** — 메인 확인: `quad-base/pesde.toml`·`quad-roblox/pesde.toml`이 `quad_types`/`quad_error`/`type_version_check`/`quad_base`를 `workspace = …, version = "^"`로 참조한다. `[Unreleased]`의 `:register` → `:Register`는 타입만이 아니라 런타임 호출이라, 소비자 트리가 "quad_roblox 3.2.0(고정) + quad_types 3.3.x"로 풀리면 3.2.0의 `Brand.luau`/`Tween.luau`가 없는 소문자 메소드를 불러 require 시점에 죽는다. 설치 문서는 `^3.0.0`과 "정확한 버전으로 고정하려면 `version = "3.2.0"`"을 둘 다 안내하므로 한쪽만 고정하는 조합을 문서가 만든다. 미확인 둘: pesde가 게시 때 `"^"`를 `^3.2.0`으로 치환하는지, 해석기가 두 범위를 한 버전으로 합치는지(합치지 않으면 크래시 대신 quad_types 사본이 둘로 갈린다). pesde 0.7.4 바이너리에 워크스페이스 버전 종류 Caret/Tilde/Exact 문자열이 있어 `version = "="`가 가능해 보인다(미실측). 갈래: (가) quad 패키지끼리 참조를 이번 릴리즈부터 `"="`로 — lockstep을 매니페스트가 강제, (나) 마이너 BREAKING을 멈추고 메이저를 올림, (다) 그대로. (가)는 위 (3)(범용 둘을 lockstep에서 뺄지)과 같이 정해야 한다 — 뺀다면 그 둘만 `^`. 탐사자 권고 Brand 개명이 나가기 전에 (가), 확신 중(미확인 둘 때문). **위 (2) `VERSION_PATTERN` 완화와도 얽힌다** — 매니페스트가 `=`로 묶으면 패턴 완화의 실익(베이스 패치마다 전 패키지 lockstep 릴리즈 강요 해소)과 방향이 반대다. 셋((2)·(3)·(23))을 한 문항으로 볼 것.

**[결정 2026-09-15 — (23)의 게시본 Brand 호환: (다) 두기 + 설치 문서 한 줄 + deprecate/yank]** 사용자: *"(다) 가 맞다고 봐. pesde 는 deprecated 가 가능해. 신규 깔림을 특수 flag 없이 막고, lock 이 있음 깔 순 있어. 그러나 경고해. pesde yank를 통해 릴리즈 주간 전 요소들을 사용을 멈춰줄 수 있어. 최종 고정 릴리즈가 생기면 그걸 최상위 앵커로 두고 쌓아나가면 된다"*. 반영: 옛 소문자 별칭 없음(오늘의 방침 유지), GS 00 설치에 "적은 패키지를 모두 같은 버전으로 고정", 사람 몫 `HUMAN_TODO.md` 20(최종 고정 릴리즈 뒤 이전 3.x deprecate·yank). 매니페스트 `^` 참조는 그대로(메이저 고정 caret).

**(24) `type_version_check`의 `N^`가 SemVer caret이 아니라 자리마다 독립으로 "이상"을 본다** — 메인 확인: `type-version-check/src/init.luau` 헤더가 *"`N^` — 그 자리 값이 N 이상이면 통과(caret)"*, 예시 `"3.3^.4^"`(마이너 3 이상 + 패치 4 이상). 실측: `matchesPattern("3.3.0", "3.2^.1^")`가 false("3.2.1 이상"을 뜻하려던 패턴이 3.3.0을 거부), `("4.0.0", "3^.2^.0^")`도 false, 헤더 예시 `"3.3^.4^"`는 3.4.0을 거부한다(하한으로 못 씀); 프리릴리즈 규칙 때문에 `("3.2.0-rc.1", "3.2^.*")`는 true. 서드파티 백엔드 작성자가 헤더의 "(caret)"을 믿고 게시하면 base 마이너가 오르는 날 `UseProvider`에서 터진다. 갈래: (가) `N^`를 "이 자리부터 오른쪽까지 사전식 이상"으로 재정의(참이던 쌍이 거짓이 되는 경우가 없어 순수하게 넓힘; 런타임과 type function 두 벌), (나) 뜻 유지 + 헤더·README에 "자리별 독립, caret 아님" 경고와 올바른 예시. 탐사자 권고 (가), 확신 중상. (3)(이 패키지를 lockstep에서 뺄지)과 같은 자리.

### 다. 타입 표면

**[결정 2026-09-15 — (가) 막음]** 사용자(스크래치 시연 뒤): *"가 로 확인했어. 그리고 TypeScript 환경에서 React의 Ref 타입은 기본적으로 불변(Invariant) 임 … 원래 읽고 쓸 수 있는 필드는(Mutable) Invariant 인게 일반적 … RefObject<HTMLButtonElement>를 RefObject<HTMLElement>에 대입했는데, HTMLButtonElement 를 쓰던 중에 다른쪽에서 HTMLDivElement 를 덮는게 가능한게 Covariant 에서 생겨서 … 새로운 개념이 아니야. … 다만 그 케비엇이 문서에 있는지가 중요"*. 반영: quad-types `Provider<T>`에 `read __quadProviderAccepts: (T) -> ()`, `Context.luau` Provider 값에 `Void`, 캐비엇을 레퍼런스 sugar/01(Provider)·core/07(Ref — 그동안 불변성 캐비엇이 어디에도 없었다)·GS 14에, `base/context-plan.md` 배너, CHANGELOG BREAKING(타입만). 같은 회신의 확인 요청(context가 불변 확장·복제를 기각한 이유가 적혀 있는가): `base/context-plan.md` "불변 확장은 만들지 않는다" 절에 진실 원천 하나·디버깅 근거는 있었으나 **"복제하면 위로 넘기는 동작을 따로 구현해야 한다"** 근거는 없어 보강. 사용자 문서엔 sugar/01·GS 14에 "불변 복제 API 없음, 가방은 하나의 진실"만 있고 이유는 없다.

**(25) `Context:Set`이 Provider의 타입과 다른 값을 막지 못한다** — 실측(두 솔버): `Provider<T>`의 `T`가 읽기 전용 팬텀 필드 하나에만 실려 공변이라 `ctx:Set(p, "not a number")`(p는 `Provider<number>`)가 `T`를 `number | string`으로 넓혀 통과한다. 대조군 `Ref<number>`에 문자열은 에러. 결과적으로 `ctx:Get(p)`가 `number`라 약속하는데 문자열이 나올 수 있다. 막는 모양: `Ref`가 이미 쓰는 방식대로 반공변 팬텀 필드 하나 추가(예 `read __quadProviderAccepts: (T) -> ()`, 런타임 값 `Void`) — 스크래치 복제본에서 잘못된 `Set`만 에러, 명시 인자·레퍼런스의 캐스트·`Get` 추론·체이닝은 통과(실제 quad-types·`spec.context`·문서 스니펫엔 미실험). 조이는 변경이라 `Provider<Frame>`을 `Provider<Instance>` 자리에 넘기던 코드도 거부된다. 새 필드라 사용자 문항, 대안은 "알려진 구멍"으로 레퍼런스에만. 탐사자 권고 이번 창에 막기, 사실 확실·모양 중상.

**[결정 2026-09-15 — Tag는 `__iter`로, `:Names()` 제거; Store·Attr 그대로]** 메인 권고 (가)(Tag도 배열)에 사용자가 반대: *"tag 는 그 자체로 Names 를 쓸 이유가 적어. 담는 내용 자체가 string 고정인 컨테이너 요소임. 아주 단순하게 __iter 도 존재해 … :Iter() 를 제공하는것도 방법처럼 들리지만, 새로운 표면을 제공할 이유를 모르겠음. 이터레이터는 새로운 데이터를 생성하지 않고, __iter 로 묶는게 luau 에 관례같거든. 오히려 Names 는 다른 쪽에서 GetChildren()->{Instance} 처럼 테이블 하나 만들어 주는게, 메서드에선 일반적"*(근거 문서 luau.org/syntax 일반화 반복, rfcs.luau.org/generalized-iteration). `pairs(tag)` 캐비엇에 대해: *"pairs 쓰는건 원래부터 외부 타입에 대해서 그 방식을 강제하는거라 … luau 의 관례에 안 맞는거라, 유저의 잘못이고 케비엇 정도"*, `__pairs`는 `__iter`로 대체돼 지원 대상이 아님(luau.org/compatibility Lua 5.2 절). 스크래치 실측: 평범한 레코드 타입은 두 솔버 모두 반복 불가 → `setmetatable<{…}, { __iter: TagIter }>`로 감싸면 체이닝·마커·`TagNames` 대입까지 통과. 반영: quad-types `Tag`, `Tag.luau` `__iter`, `spec.tag`, 레퍼런스 core/09·00-index, CHANGELOG BREAKING; 레포 전체 타입 영향은 test.sh로 실측.

**(26) `Tag:Names()`와 `store:Names()`가 이름은 같고 모양이 다르다** — `Tag`는 이터레이터 함수(`for name in tag:Names()`), `Store`는 배열(`for _, n in store:Names()`), `Attr`는 세 번째 모양 `:NameMap()`. 두 레퍼런스도 각자 다르게 적었다. 신 솔버는 둘 다 반복을 허용해 틀려도 타입 에러가 안 날 수 있다(부분 실측). 갈래: Tag도 배열로 맞춤(태그 집합은 작아 할당 무의미), Tag 쪽 이름만 바꿈(새 이름 — 문항), 레퍼런스에 대비 한 줄. 탐사자 권고 배열로 맞춤, 확신 중.

**[결정 2026-09-15 — 필드 `Blocking` 하나, `:IsOn()` 제거]** 사용자: 메인 권고 (가)(필드만 남김)에 동의하며 이름을 재검토 — *"Is 가 들어가면 체크 메서드이고, quad 타입 표면에서도 isState 같은 함수들이 있어서, Is 프리픽싱의 이익이 있는가는 모호해 … IsOn 을 남겨두는건 순수 필요 없는 함수 호출을 늘리는 부분"*, `Enabled` 대안도 제기. 메인 권고 `Blocked`(Enabled는 켜지면 흐름이 도는 것으로 뒤집혀 읽힘)에 사용자가 오독 경로("무언가 block 해냈는지")를 짚고 sonnet 독립 조사 둘 요청: (i) 생태계 선례 — `Blocked` > `Holding` > `Paused`, `Enabled`·`Active` 비권장(Roblox `ParticleEmitter.Enabled` 등 true=흐름), 약점으로 Qt `signalsBlocked`의 주어가 신호라 `blocker.Blocked`는 수동태로 읽힘을 인정; (ii) 코퍼스 정합 — `Blocking` > `IsBlocked` > `Blocked` > `Active`, `On`은 필드가 `:On()` 메소드를 가려 런타임 에러라 탈락, 레퍼런스 설명 "지금 막고 있는지"와 시제가 맞음. 사용자 확정: *"되었던 과거 상태와, 지금도 blocking 중 은 완전 다른거라 blocking 으로 두는거 동의해. 다른 표면이랑 형태가 다른 이름인건 맞지만, 의도가 분명"*. 반영: quad-types·`Blocker.luau`, 내부 `:IsOn()` 여덟 곳, 스펙 넷, 레퍼런스 sugar/06·00-index·GS 16·Quadnomicon 2권, CHANGELOG BREAKING(+`read` 목록 이름), `base/blocker-plan.md` 배너.

**(27) `Blocker`에 같은 상태를 읽는 공개 경로가 둘이다** — 필드 `IsBlocked`와 메소드 `:IsOn()`(런타임은 `return self.IsBlocked` 한 줄), 레퍼런스도 둘을 따로 싣는다. 형제 `Observer`/`EffectHandle`은 필드 `Subscribed` 하나뿐이고, 두 이름이 다른 낱말("Blocked" 대 "On")이라 같은 것인지 한눈에 안 보인다. 갈래: 둘 다 유지하고 별칭 명시 / `IsOn` 제거 / `IsBlocked` 제거. 어느 쪽을 남길지는 사용자 몫.

**[결정 2026-09-15 — 잠정 (가): 루트 자동 생성 재수출 블록, 지금은 안 바뀌는 것만]** 메인 제시 (가) 공개 목록을 루트에서 재수출 / (나) typeof 우회 / (다) 그대로. 사용자: *"사실 이건 부분적으로 보면 그대로 둬야한다 생각해. 나중에 타입 함수를 결합하는 안도 있고, 유저 표면은 확장이지 닫아짐은 아니라서 당장 못 고쳐. … 내 안은 일부 export 표면이 자동화 될 수 있도록, auto gen 영역이 init 에 박히는것 말곤 깔끔한 해법이 없는것 같고, 가급적 D 에서 빼낼 수 있는 부분은 빼낸다는거야. … 잠정 권고안이 맞다고 봐. - 하지만 D자체의 구조는 변경될 수 있고, 그게 감안되어야해"* → 시제품(클래스별 `<Class>Modifier`·`Into<Class>` + `Field`/`FieldOut`/`FieldP`/`FieldOutP`, 타입 검사 3.16s → 3.22s·에러 0·음성 대조 확인) 뒤 사용자: *"일단 넣지마. 바뀌지 않을 것만 넣어줘."* — Roblox luau-lsp에서 `keyof<Model>`·`index<Model, "IsA">`가 정직하게 동작해 D를 타입 함수로 팩토리화하는 게 가능하다고 보고 **다음 작업(급함)**으로 지정. 반영: `gen-d.py`가 `quad-roblox/src/init.luau` 표시 사이에 재수출 블록을 찍고 `check`가 검사, 지금 블록은 `Field<T>`/`FieldOut<T>` 둘뿐(생성 모듈 export는 떼지 않음), `spec.rootexports`, CHANGELOG Added. 클래스별 타입 공개 경로(HUMAN_TODO D)는 팩토리화 뒤.

**(28) 생성 `Declaration` 모듈의 export 목록이 통째로 계약이 되려 한다** — 생성기가 도움 별칭까지 전부 `export type`으로 찍는다(클래스마다 `<Class>Elem`·`MapperElem`·`RefMarker`·`OnChange`·`Param`, `<Class>Modifier`·`Into<Class>`, 값 별칭 `Field`/`FieldV`/`FieldP`/`FieldPV`/`FieldOut`/`FieldOutP`). 스펙이 사용자처럼 쓰는 건 `Field<T>`·`FieldOut<T>`·`Into<Class>`·`<Class>Modifier`·`<Class>RefMarker`이고, 보간 불가 타입 커스텀 setter엔 이름에서 뜻이 안 보이는 `FieldP`가 필요하다. 클래스별 타입의 공개 경로는 `HUMAN_TODO.md` D에 이미 열려 있으니, **그 결정 때 export 목록도 같이 정할 것**이 새로 짚은 점 — 경로가 열리는 순간 지금 export 전체가 계약이 된다. 탐사자 권고 D와 한 문항으로 묶어 공개 목록을 고르고 나머지는 `export` 없이; `FieldP` 류 이름은 새 이름이라 문항.

**[결정 2026-09-15 — (가) 규칙 문장만 관행에 맞게, 이름 무변경; `Claim` 분류는 열림]** 사용자: *"나도 권고를 따르고 싶음. dispose 는 누가 소유하는 함수도 아니고, 네임스페이스가 없을 뿐 setLengthSource 같은것 과도 유사함. 근데 claim 은 확실히 더 생각해보고싶네. 예외인 부분으로 두는게 뭔가 애매한 느낌"*. 반영: `base/architecture.md` 케이싱 절 머리 정정 배너(새 기준 한 줄), 아래 "찾았지만 문제 아님"의 케이싱 항목 정정. **`Claim` — 같은 날 확정: 대문자 유지 + 규칙에 부류 추가("quad의 태어남 진입점 `New`/`Claim`")**, 사용자 *"처음 의도로 나도 기울어서 1이 맞다"*(근거: 받기만 해도 bk·소유 등록이 생기는 생명주기 시작점). 소문자 `claim`(백엔드 `nativeClaim`과 경계 흐림·BREAKING)·`D.Claim` 이동(패키지 경계·BREAKING) 기각.

**(29) 케이싱 규칙 문장과 실제 사용자 함수가 어긋난다** — 위 "찾았지만 문제 아님"은 "실제 표면 전체가 이 규칙을 따른다"고 적었는데 반례가 있다. 기준 문장("특정 프리미티브 타입 하나의 전용 소유물이면 대문자, 아니면 소문자")과 달리 프리미티브가 아닌 사용자 함수 `q.Claim`·`Fallback`·`Traceback`·`OnCreated`/`OnRendered`/`OnDestroyed`·`Debounce`/`Throttle`이 대문자이고, 레퍼런스 core/10이 사용자용으로 싣는 `q.dispose`와 `q.newMapperClass`는 소문자다 — 특히 `Claim`(넘겨받음)과 `dispose`(파괴)는 짝인데 갈린다. 실제 관행은 "앱 개발자가 부르면 대문자, 백엔드 계약·술어는 소문자"로 보인다. 갈래: 규칙 문장을 관행에 맞게 고치기(비파괴) / 관행대로 `dispose` → `Dispose`(BREAKING, 이번 창이 마지막). 사용자 문항, 확신 중.

**[결정 2026-09-15 — (나) 네임스페이스 이동: `q.Backend` + `q.Bookkeeping`, BREAKING]** 메인 권고는 (가) 명시만(비용: 내부 읽기 src 146곳·스펙 198곳·문서 32곳)이었으나 사용자: *"난 나 로 기울어. Dispatch 나 module._bookkeeping 등 말이야. 특히 Bookkeeping 같은 경우 핸들러 추가하는 처리자가 필요한데, 공개 표면도 아님. 이미 Dispatch 가 있고, 똑같이 Bookkeeping 네임스페이스도 확립해서 타이핑 대상으로 둬도 될것 같고, Backend 도 마찬가지임. 요소가 많기 전 정의해 흩뿌려져있었지만, 지금 정리하는게 가장 싸고 나중엔 처리를 못하는지라, 비용을 고려하지 않고 볼 때 가장 적합한 구현은 네임스페이스 추가야. 자동완성이 장황한것도 정리가 돼. 대상은 native* 과 brand 안 쓰는 isInst, add/remove tag 와 attr 백엔드 계약, *Lifetime 과 타이머계약, can* 계약이 이에 해당하는것 같아. export type Quad = {...} 가 방대한것도, 타입이 분리되어 더 읽기 편해지는지라 그 부분도 좋고, 실익이 절대적으로 커서 나를 택하는게 맞다고 봐"* 세부는 선택지 질문 넷으로 확정(전부 권고안): `q.Backend` 하나·평평, 멤버 이름 그대로(`q.Backend.nativeInsert`), 경계 — `onDestroying`은 Backend로(백엔드가 심는 것 전부), `newMapperClass`(base Claim 소유)·`dispose`(앱용)는 `q.`에; `q.Bookkeeping` 공개·타입화하고 Dispatch의 재수출은 제거(한 곳이 소스).

**(30) 백엔드가 심는 연산들이 사용자 네임스페이스 `q.`에 평평하게 산다** — `nativeInsert` 등 여섯, `isInst`, `onDestroying`, `nativeClaim`, `nativeFindChild`, `addTag`/`removeTag`/`setAttr`, `setTimeout`/`clearTimeout`, 생명주기 넷, `newMapperClass`가 전부 `Quad` 타입 필드라 앱 개발자의 자동완성에 섞이고, `q.setTimeout(fn, 1)`은 Roblox 백엔드에서 실제로 돈다. 나중에 하위 필드로 옮기면 서드파티 백엔드와 그걸 부른 앱 코드가 같이 깨진다. 지금 옮기는 비용도 크다("모듈 필드는 매번 `module.x`로 읽는다" 규약이라 내부 읽기 자리 수십 곳). 갈래: 레퍼런스에 "백엔드 계약이지 앱 API 아님" 명시(비용 거의 0) / 하위 네임스페이스로 이동(새 이름 — 문항). 탐사자 권고 최소 명시, 확신 중하.

**(31) `Observer`와 `EffectHandle` 타입 이름의 비대칭** — `state:Observer(fn)`은 `Observer`, `q.Effect(fn)`은 `EffectHandle`(마커 `ObserverMarker`/`EffectHandleMarker`, 술어 `isObserver`/`isEffect`). 설정 모듈 문서가 `EffectHandle`을 재수출하게 해 이미 사용자 주석에 들어간다. Luau는 타입·값 이름 공간이 따로라 `Effect` 타입 이름을 막는 제약은 없어 보이나 `effect-plan.md`에서 근거를 못 찾음. 확신 하(취향 비중 큼) — 올리기만 한다.

**(32) 비파괴 — 옵션 테이블 셋과 `q.Slot` 첫 인자가 `read` 규칙을 안 따른다** — `typing-limits.md`가 적은 규칙(읽기만 하는 옵션 타입은 필드를 `read`로 — 탐사자 인용, 절 제목 아님)을 `TweenOptions`·`AnimateInfo`는 따르나 `DebounceOptions`·`ThrottleOptions`·`SlotListOpts`와 `q.Slot`의 `initial: { SlotElement<T> }?`는 안 따라, 옵션을 변수에 담아 넘기면 두 솔버가 거부한다(`local opts = { Owned = false }`를 `:List`에). `read`를 붙이면 받는 입력이 넓어질 뿐이라 **BREAKING 창과 무관** — 언제 해도 됨, 확신 높음. (19)의 "모르는 키 에러"와 같이 손대면 편하다.

참고(판단 재료 약함): 무타입·생성자·클래스별 `Modifier.Overridden`이 전부 `any`를 돌려준다(기록된 솔버 제약). 나중에 `Modifier`로 좁히면 `local m: FrameModifier = …Overridden(a, b)`가 깨질 수 있어, 좁힐 계획이 있으면 이번 창에 재측정할 가치가 있다(미실측).

### 라. 문서 약속 — 문구를 좁히거나 채울 것 (새 이름·메커니즘 없음, 대부분 메인 자율 가능)

**확실한 잔재·오류 (게시 전 고칠 것)**: 사이트 수기 랜딩 `docs/site/src/content/docs/index.mdx`(두 곳)·`en/index.mdx`(한 곳)가 아직 옛 위치 인자 이름(`prev` 반환, 넘겨받은 `index`/`offset`) — `sync-docs.py`가 복사하지 않는 파일이라 오늘 치환에서 빠졌다; 랜딩과 `getting-started/15-animation.md` 머리 설명의 "`:Apply(q.Animate)` 슈거"는 실제 모양 `:Apply(q.Animate { … })`와 달라 그대로 따라 쓰면 State가 옵션 자리로 간다; `docs/reference/core/06-slot.md`의 Offset 설명("첫 원소가 시작하는 절대 물리 위치")이 1부터 세는 값으로 읽히나 실제(GS 10 퀴즈·extend/01과 같이)는 앞에 있는 물리 자식 수, 0부터; `:Single`의 KeyGone 서술("값이 nil이거나 None이면 `ctx.Item`으로 KeyGone")이 넘친다 — 처음부터 nil이면 `updateFn`이 아예 안 불리고, 있다가 없어지는 전이에서만 온다.

**약속을 좁히거나 "정해져 있지 않음"을 적을 것**: (i) 같은 원천의 Observer·Effect, 같은 Ref 콜백의 발화 순서 — 실측으로 한 프로세스 안에서도 매번 달랐다(weak 키 `_subs` 해시 순회); core/02·05·07에 "순서 정의 안 됨, 등록 순서도 아님"(나중에 보장하는 건 비파괴). (ii) KeyGone 호출끼리의 순서(`pairs(prevKeys)`) — core/06의 사이클 세 단계 서술 옆에. (iii) `source.Revision`이 "`bit32` 랩어라운드로 감소하는 방향"까지 약속(core/02) — core/07처럼 "일치 비교만 의미"로. (iv) `ref.Callbacks`/`WeakCallbacks`의 자료 모양(키가 콜백인 집합, weak, `:Wait` 코루틴이 `thread` 키)을 core/07이 자세히 적어 `read`로 막은 표현을 읽기 쪽으로 다시 계약화 — "진단용, 모양은 바뀔 수 있음"을 붙일지 사용자 판단. (v) `AddPlugin` 경고는 돌려준 확장 테이블만 본다 — `pluginFn` 안의 직접 대입은 조용하니 core/01 문장을 "돌려준 테이블이 덮는 필드"로. (vi) GS 17 "원천이 한 번 움직였을 때 계산은 한 번만" — 계산 중 상류가 움직이면 수렴까지 다시 돈다(레퍼런스 core/03은 이미 그렇게 씀), 추정·영향 낮음.

**CHANGELOG `[Unreleased]`**: `read` 목록의 `Timeout._native`가 바로 위 "`_` 필드는 공개 표면 아님"과 부딪친다(빼거나 괄호); `Epoch.Revision` `read`로 자기 값에 Epoch를 직접 구현하던 백엔드 작성자도 깨지는데 옮기는 법이 quad 메소드만 안내한다("자기 impl 타입이나 캐스트로"); `ref.Value = x` → `ref:Set(x)`는 콜백 발화·Revision 갱신이 새로 붙는 동작 변화라는 한 줄(추정).

**스킬**: `docs/skills/quad-ui-dev/references/rules-and-invariants.md`가 에러 문구에 "match on them"을 권한다 — 위 (11) 정책과 반대, (11)을 닫을 때 같이. `SKILL.md`의 "`q.State<T>` does not exist"는 레퍼런스가 설정 모듈 재수출 전제로 `q.State<T>`를 쓰는 것과 같이 읽으면 모순 — "설정 모듈을 거치지 않을 때" 조건을 붙일 것.

**탐사자가 미완으로 표시한 것**: how-to·시작하기 본문 전수 대조(약속 낱말 247줄 중 계약성 있는 것만 봄), Tween/Animate·OnChange·Claim·Context·Operator 레퍼런스 동작 주장 대조, 랜딩 FAQ "`D.<Class>` 31개" 개수. 런타임 탐사의 미완: Tween·Animate 모르는 키 런타임 실측, `Time = "x"` 무진단 원인, pesde 게시 매니페스트 치환·버전 합치기.

**세 탐사가 확인하고 문제없다고 한 것(다시 볼 필요 없음)**: 오늘 바꾼 표면의 잔재는 위 랜딩 둘 말고 없음(의도된 v1 역사 서술 제외); 사이트 사본 동기화; `Source:Set`·`Ref:Set`의 같은 값 발행; `UseProvider` 멱등·실패 시 재시도 가능; `q.debug`는 설치 시점 출력 두 곳뿐; `Unsubscribe` 두 번 에러 대 `WeakUnsubscribe` 관대(문서화됨); `unbindLifetime` 미바인드 no-op·nil 에러; `KeyGone` 반환 검증; keyFn nil·중복 에러; `Context:Set(nil)`·미설정 `:Get` 에러; Debounce/Throttle 기본값·둘 다 false 에러; Tween 옵션 검증; `Blocker:Off` 멱등; PreRef/Ref/PostRef 순서 계약; 숫자 키 먼저 처리(spec.drive 감시, 스크래치 실측); Gate `emit`; Observer 등록 즉시 한 번 발화; `ctx` 매 호출 새 테이블·KeyGone `Index = 0`; CHANGELOG의 Brand·Depend·updateFn·Length/Offset 옮기는 법; `quad-base` 엔진 전역 무참조; 생성 `PV0`~`PV75` 비export; `q.Slot()` 무캐스트 `Slot<unknown>`(기록된 관용구); `RunInit`·`ObserverFn`·`Operator.Alternative`·`Tag.Contains`는 나중에 넓혀도 비파괴; `Ref.Unwrap` 두 솔버 깨끗.
- `docs/quadnomicon/`·`docs/how-to/`의 개별 문장까지 전수 대조하지는 않았습니다 — 공개 표면의 **정본**(quad-types·두 init.luau·생성기·매니페스트)과 레퍼런스 색인을 기준으로 삼았습니다.