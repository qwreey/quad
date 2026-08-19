# 2026-08-19, 여덟 번째 세션 — `type-version-check` 패키지 추출, `CheckedQuad<T, Pattern>` 확장

**요약**: 직전(일곱 번째) 세션이 만든 `CheckedQuad<T>`(정확 버전 일치만
지원)가 `quad-spring`/`quad-spring-roblox`류 독립 게시 플러그인엔 너무
빡빡하다는 사용자 지적으로 시작. 글롭(`"*"`)/캐럿(`"N^"`) 패턴 매칭을
지원하도록 `CheckedQuad<T, Pattern>`으로 확장하고, 그 매칭 로직 자체는
quad에 종속되지 않은 범용 워크스페이스 패키지 `type-version-check`로
분리·구현·검증까지 완료. 사용자 지시대로 지금은 quad 모노레포 안에
두고, 독립 저장소 분리는 `HUMAN_TODO.md`에 남김.

## 1. 문제 제기 — 정확 일치는 독립 게시 플러그인엔 과함

사용자 발언 요지: "quad-spring/quad-spring-roblox 같은건 버전 확인이
exactly 할 필요는 없다고 봄" — 최신 `quad-spring-roblox`가 과거
`quad-spring` 버전도 잘 다룰 가능성이 높으므로, 글롭(`"3.*.*"`)이나
캐럿(`"3.3^.4^"`, 마이너 3 이상 + 패치 4 이상) 패턴을 지원하는 게
"구현하기 정말 쉽고... 있으면 좋다"는 판단. 같이 제안된 것: (1) 미래
`quad-roblox-types` 패키지(지금 만들 필요는 없음, 다만 `quad-roblox`의
공개 타입을 지금부터 단일 파일에 몰아둬서 나중에 쉽게 분리되게만
준비), (2) 버전 체크 패턴 자체를 `qwreey/type-version-check`로 독립
추출(다른 프로젝트에도 쓸 수 있고, quad-spring-roblox류가 이것 때문에
quad-base 전체를 끌고 올 필요가 없어짐), (3) Luau 내장 `index<>` type
function으로 `Version` 필드를 뽑는 게 수동 `readproperty`보다 나아
보인다는 제안.

**사용자 명시적 지시**: "우선 이 프로젝트 안에 넣어둬줘. 나중에 내가
다른 프로젝트로 분리해줄게. Human todo 로 남기면 될듯 함."

## 2. `type-version-check` 패키지 구현

새 워크스페이스 멤버(`[target] environment = "luau"` — quad에 종속되지
않아 다른 멤버와 달리 roblox가 아님). 핵심:

- 런타임 유틸 `matchesPattern(actual, pattern)` — `.`로 나눈 각 자리를
  `"*"`(와일드카드) / `"N^"`(그 자리 숫자값이 N 이상이면 통과) / 그 외
  정확 일치로 비교.
- `export type function CheckVersion(actual: type, pattern: type): type` —
  `actual`/`pattern`을 문자열 리터럴로 검증 후 같은 매칭 로직을 타입
  레벨에서 재현, 성공 시 `types.singleton(true)`만 반환(원본 타입
  패스스루 금지 — 직전 세션이 확정한 함정 회피 원칙 그대로 유지).

**새로 발견한 Luau 함정 2건** (이전 세션들의 `typing-limits.md` §6과는
다른 결의 순수 문법 제약):
1. `type function`은 같은 파일의 바깥 스코프 로컬 함수를 못
   참조한다(`Type function cannot reference outer local 'X'`) —
   `matchesPattern`과 `CheckVersion` 내부의 매칭 로직은 물리적으로
   중복된 별개 함수로 유지해야 함.
2. cross-package 사용엔 `type function`이 아니라 `export type
   function`이 필요(안 그러면 `Unknown type 'Module.X'`), 그리고 명시적
   제네릭 인스턴스화가 2개 이상이면 단일 꺾쇠가 비교 연산자로
   오파싱되므로 이중 꺾쇠(`Foo<<A, B>>`)가 필요(코퍼스의 기존
   `AttributeKey<<T>>` 관례와 동일 이유).

`index<T, "Version">` 내장 type function으로 `Version` 필드 추출 —
사용자 제안대로 채택, 단독 스파이크와 `CheckVersion`에 실제로 물려서
둘 다 실측 확인.

selene `shadowing` 경고(중첩 스코프의 `actualValue` 재선언, 두 곳)를
안쪽 변수를 `actualNumber`로 리네임해 해소.

## 3. `quad-types` 쪽 배선

`quad-types/pesde.toml`에 `type_version_check = { workspace =
"qwreey/type_version_check", version = "^", target = "luau" }` 추가 —
`target` 없이는 `pesde install`이 "no workspace member found with name
qwreey/type_version_check and target roblox"로 실패(quad-types 자신의
기본 target이 roblox라 명시적 target 지정이 필요, `quad-types`↔`type-
version-check`가 서로 다른 target을 가진 첫 워크스페이스 의존 관계라서
이번에 처음 실측됨).

`CheckedQuad<T> = T & { __versionCheck: CheckVersion<T> }` →
`CheckedQuad<T, Pattern> = T & { __versionCheck:
TypeVersionCheck.CheckVersion<index<T, "Version">, Pattern> }`로 확장.

심볼릭 링크 로컬 CLI 우회(`project-setup-plan.md`가 이미 문서화한
워크어라운드)를 2단 깊이 의존 그래프(`quad-base`/`quad-roblox` →
`quad-types` → `type-version-check`)에 재적용 — 문제없이 일반화됨을
확인.

## 4. 검증

전 패키지(`quad-base`/`quad-roblox`/`quad-types`/`type-version-check`)
`luau-analyze`/`luau`/`selene` 전부 클린. 스파이크
`23-type-quadtypes-checkversion-addplugin.luau`를 새 시그니처로
재작성해 재검증 — 양성 경로(버전 일치 + `AddPlugin` 2회 체이닝) 클린,
음성 경로(버전 불일치)는 정확히 `TypeError: type-version-check: version
"9.9.9" does not match pattern "0.0.0"` 하나만 발생.

## 5. 문서 반영

`base/quad-types-plan.md`(`type-version-check` 절 신설 + `CheckedQuad<T,
Pattern>` 섹션 갱신 + 남은 것에 `quad-roblox-types` 백로그/HUMAN_TODO
포인터 추가), `base/architecture.md`(소스 트리에 `type-version-check/`
추가, 패키징 방식 문단 갱신), `base/project-setup-plan.md`(cross-target
워크스페이스 의존 함정 + 2단 심볼릭 링크 우회 재확인), `base/typing-
limits.md`(§6 예시 코드를 `CheckedQuad<T, Pattern>`으로 갱신 + 절 인용
수정), `.claude/README.md`/`luau-test/README.md`/`luau-test/STATUS.md`
(스파이크 23 설명 갱신), 루트 `HUMAN_TODO.md`(9번 — `type-version-check`
독립 저장소 분리는 사용자 몫).

## 감사 루프 (2라운드, 핸드오버 체크리스트대로)

1라운드는 `quad-types-plan.md`/`type-version-check` 자신의 파일/주석에
남아있던 구 `CheckedQuad<T>`(콤마 없는 단일 파라미터) 잔존 4건과
`architecture.md`의 `pesde.toml` 나열 누락, `luau-test/STATUS.md` 배너
stale 1건을 찾아 전부 수정. 2라운드(각도를 인덱스 레이어/교차 참조로
전환)는 `project-setup-plan.md`의 옛 2-멤버 트리 다이어그램과 "3개
패키지"/"총 3개" 개수 하드코딩(멤버가 2→4로 늘어난 걸 못 따라간 자리
2곳)을 찾아 `architecture.md`를 소스로 가리키게 일반화. 이후 3라운드는
새 발견 0건 — 여기서 감사 루프 종료.

## 다음에 확인할 것

없음 — 이 턴의 설계/구현/검증/문서화/2라운드 감사까지 전부 마무리.
`quad-roblox-types`는 사용자가 명시적으로 후순위 지정(지금 안 만듦),
`type-version-check` 독립 분리는 사용자 본인이 나중에 직접 진행.
