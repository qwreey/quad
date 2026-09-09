# 생성 `D`에 Deprecated/Hidden 프로퍼티 되살리기 — 스파이크 실측 (2026-09-09)

**계기**: docs 재작성 중 `Font = Enum.Font.X`가 생성 `D`에 없는 것을 발견(`session/2026-09-09-01-docs-polish.md`). 사용자: *"Font 도 있긴 해야해.
에이전트를 통해 일괄 quad v1 에서 v2 로 마이그레이션 하는 경우 … 자동완성 안 먹으면 타입 문제로 못 옮길수도 있고 그럼. deprecated 를 이제 타입에
달 수 있을텐데, 검색/확인해봐야할듯."* opus 스파이크 하나가 실측(원문은 세션 스크래치 — 이 파일이 요약본이자 소스).

## 실측

1. **`Font`는 Deprecated가 아니라 `Hidden`(+`NotReplicated`) 태그**(핀 덤프 `version-268c7d941ba34c1a`). `FontSize`/`TextWrap`이 Deprecated.
   `PROP_TAG_EXCLUDE`에서 Deprecated만 빼면 `Font`는 안 돌아온다 — Hidden도 열어야 한다.
2. **Luau `@deprecated`는 함수 전용**(luau 0.734 / luau-lsp 1.69.0, `mise.toml` 핀). `@deprecated local function`은 `DeprecatedApi` 린트가 나고
   `@[deprecated { use = "FontFace" }]`도 된다. 테이블 타입 필드 앞은 `SyntaxError: attributes are not allowed in declaration context`,
   `.d.luau`의 `declare extern type` 프로퍼티도 `Expected a method type declaration after attribute`. 핀 defs(`scripts/roblox-defs/globalTypes.d.luau`)도
   메소드에만 129곳, 프로퍼티엔 0곳. quad의 Modifier setter는 런타임 `__index`라 함수 정의 경로도 못 쓴다.
3. **에디터에 닿는 유일한 채널은 필드 위 `---` 독 주석** — LSP hover를 stdio로 찍어 확인: 멤버 접근(`m:Font(...)`) hover엔 붙고, 테이블 리터럴 키
   `D.TextLabel { Font = … }`의 자동완성 항목엔 documentation도 `deprecated` 태그도 안 실린다(`{"label":"Font","tags":null,"deprecated":false,"documentation":null}`).
   즉 **작성 지점 경고·린트는 불가**, 문서(마이그레이션 가이드)에 적어야 한다.
4. **버려지는 양**(보안·타입·defs 게이트 통과분만): Deprecated만 풀면 고유 10(슬롯 19) — `GuiObject.Draggable`(10클래스), `TextLabel/TextButton/TextBox`의
   `FontSize`·`TextWrap`, `BillboardGui.DistanceLowerLimit/UpperLimit`, `Camera.focus`. Hidden만 풀면 고유 6(슬롯 15) — `Font`×3, `GuiObject.Transparency`(10),
   내부용 `VideoFrame.InternalVideoUsage`·`MaximumResolution`. 둘 다 풀면 고유 24(슬롯 102) — `BackgroundColor`·`BorderColor`·`TextColor`(BrickColor),
   `Instance.archivable`(31), `GuiBase2d.Localize`(13), `Camera.CoordinateFrame`이 더 들어옴. 읽기 표면엔 `Object.className`(31)·`LocalizedText`(2).
5. **비용은 없다시피**: Deprecated∪Hidden 전부 + 독 주석 — `D/init.luau` 5030 → 5678줄, test.sh exit 0, "too complex" 없음, 제거해둔
   `LuauSolverConstraintLimit` 부활 불필요, 타입 검사 3.04~3.09s → 3.27~3.36s(+8%). 이름 화이트리스트판 5098줄, 3.12~3.16s. `D.TextLabel { Font = Enum.Font.GothamBold }`·
   `TextWrap`·`FontSize`·`Transparency`·`Draggable`·`BackgroundColor(BrickColor)`·State 팔·Modifier 체인 전부 신 솔버 통과, `Font = 42`만 에러. `PropTypes`/`PropTypesRead`의 `any` 붕괴 없음.
6. **⚠️ 막는 전제(미검증)**: `Handlers/Property.luau`의 런타임 매치는 `ReflectionService:GetPropertiesOfClass`가 준 디스크립터의 `Permits.Write`다. 그 서비스가
   Hidden/Deprecated 멤버를 목록에서 빼면 타입은 `Font`를 광고하는데 디스패치는 매치 실패 → 런타임 에러(지금의 타입 에러보다 나쁨). 스펙은 `mock.gameShim`이라 못 잡는다.
   **Studio 실측이 선행** — `HUMAN_TODO.md` 12번.
7. **부수 발견**: 핀 덤프를 CDN에서 받아 `normalize`하면 `classes`는 바이트 동일한데 dropped 노트가 5줄 적다(`WorldModel`의 `Wind`·`WindDirection`·`AutoSimulate`·
   `GravityDirection`·`SimulationRate` — 커밋본이 더 새 덤프에서 나옴). `test.sh`는 emit 결정성만 게이트(`gen-d.py check`)하고 normalize는 안 본다. 실제 적용 때
   어느 덤프로 재정규화할지부터 정할 것.

## 사용자 결정 (2026-09-09)

**Deprecated 태그는 통째로 + Hidden은 이름 허용목록(`Font`, `Transparency`)** — 옵션 셋(Deprecated∪Hidden 전부 / Deprecated만 / 실측 먼저) 중 선택.
근거(메인 권고): Deprecated 10개는 전부 v1 마이그레이션 재료라 쓰레기가 안 섞이고 덤프 갱신에 규칙이 그대로 살며, Hidden은 내부용(`VideoFrame` 둘)이 섞여
이름으로만 연다. 순수 이름 전역 화이트리스트는 파일 머리 "조용한 절단 금지"와 반대 방향이라 비추천. **적용은 6번 실측 뒤**(`todos.md` 00번).

## 남긴 패치

- `gen-d.all.patch` — Deprecated∪Hidden 전부 + 독 주석(`legacy_doc`/`legacy_note`). `git apply` 클린, test.sh 0.
- `gen-d.whitelist.patch` — 이름 화이트리스트판(`PROP_NAME_KEEP`). 같은 검증.
- **결정된 정책은 둘의 변형**: `keep = PROP_TAG_LEGACY if ("Deprecated" in mtags or m["Name"] in HIDDEN_NAME_KEEP)` — `HIDDEN_NAME_KEEP = {"Font", "Transparency"}`.
  적용 절차: 패치 적용 → 위 한 줄로 조건 변경 → `python3 scripts/gen-d.py` 재생성 → `./scripts/test.sh; echo $?` 0 → docs의 `FontFace` 안내를 `Font`도 된다로.
