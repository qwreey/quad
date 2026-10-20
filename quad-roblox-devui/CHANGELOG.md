# Changelog — quad-roblox-devui

이 킷의 소비자가 겪는 변화를 적습니다. 형식은 루트 `CHANGELOG.md`와 같습니다(Added / Changed / Deprecated / Removed / Fixed, 호환이 깨지면 **BREAKING**과 옮기는 법 한 줄).

**아직 버전이 없습니다.** 킷은 게시 전이라 버전을 매기지 않고 `[Unreleased]`에 쌓습니다 — 버전·패키지화는 따로 정합니다. 이 파일을 만든 2026-10-20 이전의 변화는 git 기록에 있습니다.

## [Unreleased]

### Added

- `InputText`·`InputNum`·`DragNum`의 `FieldSpread`, `SliderNum`의 `TrackSpread` — 안쪽 상자·트랙에 Ref·`q.OnEvent`·키 묶음을 펼쳐 넣는 자리(`q.Spread "TextBox" {…}` 등). 기본값 경로인 `FieldModifier`/`TrackModifier`는 그대로입니다.

### Changed

- **BREAKING** quad 3.4.0 표면으로 옮겼습니다 — 킷은 `q.Elem`·`q.Modifier "Class"`·`q.Spread "Class"`를 쓰고 quad 3.3의 `q.Declaration`에서는 돌지 않습니다.
- **BREAKING** `Modifier`·`FieldModifier`·`TrackModifier` 같은 Modifier 자리의 타입이 `ModifierInto<Class>`(메소드 없는 마커)입니다 — 직접 만든 커스텀 클래스 Modifier는 넘기는 쪽에서 `:AsTextButton()`처럼 내려서 넘기세요.
- 잘못된 prop·인자 에러가 `Devui.<컴포넌트>: <내용>` 한 형식입니다(예: `Devui.MenuToggle: give …`). 검사가 컴포넌트 몇 단계 안쪽에 있어도 에러는 그 컴포넌트를 부른 줄을 가리키고, 컴포넌트 안에서 quad가 내는 에러(잘못된 `Modifier` 등)도 이제 킷 안쪽 줄이 아니라 그 컴포넌트를 부른 줄을 가리킵니다. 에러 문구는 계약이 아니니 문구로 분기하지 마세요.
