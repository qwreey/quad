# 디자인 토큰 — 두 킷이 따로 만든 "파생되는 값 묶음"을 base가 받칠지

**[2026-10-20 신설 — 착수 아님, 사용자 결정 대기]** devplorer 보고 U9(파생 Style을 만들 길이 없어 `:: any`로 Style 표를 복제)에서 시작했다. 메인이 `style:With(overrides)`를 제안했고, 사용자가 "Modifier로 하면 안 되나"를 물었다. 그 답을 따라가다 이 패턴이 Modifier·Spread·Context·Store 어느 것과도 다르다는 것이 드러났다. 경과는 `session/2026-10-19-01-decl-3-4-decisions.md` §9 뒤.

## 1. 지금 상태 — 같은 모양이 두 번

- **devui `Style`**(`quad-roblox-devui/src/Style.luau`)
  - 색·투명도·지표 토큰을 `State`로 쥔다.
  - Scheme(Dark/Light)·Density 전환을 따라간다.
  - 덮어쓰기는 `Style.new(overrides)`에서 한 번에 굳는다.
- **material `Theme`**(`quad-roblox-material/src/Theme.luau`)
  - M3 색 역할을 `State`로 쥐고, 전환할 때 색이 크로스페이드한다.
  - 덮어쓰기는 `Theme.new`에서 한 번에 굳는다. 머리 주석 원문: "overrides are static; build a second Theme".
- **공통점**: 둘 다 위젯마다 `props.Style`·`props.Theme`으로 넘긴다. 둘 다 **"부모 묶음에서 몇 개만 바꾸고 나머지는 부모를 따라가는" 파생**이 없다.
- **quad 정본 레시피**: how-to 05 "디자인 토큰과 테마 전환"은 토큰을 `q.Context`로 흘리고 스타일은 `Modifier.Overridden`으로 겹친다. 두 킷 모두 이 레시피를 따르지 않았다.

## 2. 킷이 Modifier로 가지 못한 이유 (소스 확인)

1. **인라인 키가 Modifier를 이긴다.** Modifier 레퍼런스의 병합 규칙 1번이고, 위젯은 자기 모양을 인라인으로 쓴다. Window 머리 주석에도 "inline props still win"이 있다.
2. **토큰은 계산의 재료다.** hover·누름 색은 `Style.interactive`가 섞어 만들고, 지표는 여러 자식의 크기 계산에 들어간다. Modifier는 "이 요소의 이 프로퍼티"라 재료를 바꾸지 못한다.
3. **바꾸고 싶은 곳이 안쪽이다.** Combo 상자 너비 같은 안쪽 부품은 Modifier로 하려면 부품마다 자리가 늘어난다. 토큰 하나는 그 토큰을 쓰는 위젯 전부를 바꾼다.

## 3. 사용자 정리 — 다섯이 다 다르다 (2026-10-20)

사용자는 토큰이 CSS 변수(`--another: calc(var(--base) …)`)에 가깝다고 보았다. 사용자 원문: *"약간 css var 같은 느낌이네 … modifier 랑도 조금 다르고, spread 랑도 조금 다르고, context 랑도 다르고 store 랑도 달라보이는건 사실"*.

- **Store**: 전부 `:Set` 가능한 필드 집합이다. 한 필드를 다른 필드에서 파생하는 것을 허용하지 않는다.
- **Spread**: 런타임에 만든 조각을 그대로 펴 넣는다. 한 곳에서만 쓰이고, 변경 가능하다.
- **Modifier**: 변경 불가이고, 여러 곳에 쓰인다. 요소 하나의 프로퍼티를 덮는다.
- **Context**: 명시적으로 아래로 넘기는 값 가방이다.
- **토큰 묶음**: 토큰이 다른 토큰에서 계산되고, 파생 묶음은 일부만 바꾸고 나머지는 부모를 따라간다.

사용자 결론은 둘이다.
- 킷의 `Style`은 지금 그대로 둔다. `style:With`는 넣지 않는다.
- *"두 킷 모두 있으니 받쳐줄만하다는건 사실"*. 그리고 *"각자 존재 이유가 명확해서 문서화에서 뭐가 다른지 잘 짚어주고 정리해주는건 중요"*.

## 4. 열린 것

- **(가) base 원시 기능.** "파생되는 토큰 묶음"을 base에 둘지, 둔다면 어떤 모양인지. 후보 모양:
  - 부모 묶음 + 덮어쓰기. 덮어쓰지 않은 토큰은 부모의 State를 그대로 가리킨다.
  - 토큰을 다른 토큰의 계산으로 정의하는 꼴(`calc`).
  - 두 킷의 Scheme 전환과 크로스페이드가 그 위에 설지.
  - 새 메커니즘이라 사용자 결정이다.
- **(나) 토큰을 넘기는 길.** 지금처럼 `props.Style`·`props.Theme` 드릴링인지, how-to 05처럼 `q.Context`인지.
- **(다) 비교 문서.** 비슷해 보이는 다섯(Store·Context·Modifier·Spread·토큰)이 무엇이 다르고 언제 무엇을 쓰는지를 사용자 문서 한 곳에 둔다. Spread는 아직 런타임에 없으므로, Spread가 들어올 때 함께 쓰는 것이 자연스럽다(todos의 Spread 정의 확장 트랙).
- **조사 계획(제안).** 두 킷의 토큰 구현을 나란히 놓고, Store·Context·Modifier로 어디까지 되는지 실측한다. 근본 원인 쪽은 Gemini에게 다른 시각으로 한 번 보게 한다.
