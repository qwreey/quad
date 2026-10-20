# Changelog — quad-roblox-material

이 킷의 소비자가 겪는 변화를 적습니다. 형식은 루트 `CHANGELOG.md`와 같습니다(Added / Changed / Deprecated / Removed / Fixed, 호환이 깨지면 **BREAKING**과 옮기는 법 한 줄).

**아직 버전이 없습니다.** 킷은 게시 전이라 버전을 매기지 않고 `[Unreleased]`에 쌓습니다 — 버전·패키지화는 따로 정합니다. 이 파일을 만든 2026-10-20 이전의 변화는 git 기록에 있습니다.

## [Unreleased]

### Changed

- **BREAKING** quad 3.4.0 표면으로 옮겼습니다 — 킷은 `q.Elem`·`q.Modifier "Class"`를 쓰고 quad 3.3의 `q.Declaration`에서는 돌지 않습니다.
- **BREAKING** 컴포넌트의 `Modifier` 자리 타입이 `ModifierInto<Class>`(메소드 없는 마커)입니다 — 직접 만든 커스텀 클래스 Modifier는 넘기는 쪽에서 `:AsTextButton()`처럼 내려서 넘기세요.
