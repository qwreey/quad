# 검토 과제 — quad Declaration 새 표면 이름표가 체계로서 일관된가

결정이 아니라 발견을 내는 과제다. 결정은 라이브러리 저자(사용자)가 한다.

먼저 읽을 것: `.claude/research/declaration-naming-table.md`(이 과제의 대상 — 원칙·빈도 실측·이름표 초안·Elem 토론). 배경이 필요하면
`.claude/research/declaration-surface-plan.md` 5절(오늘 결정들), `.claude/audit/decl-typefn-probe-2026-10-16/REPORT.md`(실측), `.claude/audit/decl-typefn-probe-2026-10-16/src/Lib.luau`(타입 함수 프로브),
`quad-roblox/src/init.luau`·`quad-types/src/init.luau`(지금 공개 이름). 결정된 것(값은 이름·커리, 백엔드 계약, `q.Raw`, `NewModule`, 공용 모듈 `D`, Spread 커리·누적)은 다시 열지 말 것.

## 낼 것

1. **표 전체 체계 검토** — 각 행이 1절 원칙(빈도에 맞춘 길이·자기서술·부모 접두로 묶기·값과 타입이 같은 이름이면 같은 것·안 쓰는 부품은 안 내보내기)과 맞는가. 어긋나는 행마다:
   무엇이 어긋나는지, 대안 이름(근거와 함께), 그 대안이 다른 행과 새로 충돌하지 않는지. 특히 볼 것: `Into<C>`(자주 쓰는데 무엇으로 into인지가 이름에 없음), `SpreadMarker<C>`(누적형이면 메소드가
   붙는데 `Marker`가 맞나), `Field<T>`→`ModifierField<T>`, `PropTypes`/`PropTypesRead`, 부품을 안 내보내는 선택지의 비용(사용자가 그 부품이 필요해지면?), Roblox 전역 이름·quad 기존 이름과의 충돌
   (Roblox 정의는 `scripts/roblox-defs/globalTypes.d.luau` — 직접 grep해서 확인).
2. **값 쪽 `Elem` 판정** — 표 4절의 사용자 근거(`type Elem<T> = Ctor<T>`, `Elem "Frame": Elem<Frame>`, Modifier와의 평행·차이)가 실제로 근거가 되는지: 타입 `Elem<Frame>`이 함수 타입을, 타입
   `Modifier<Frame>`이 값 타입을 가리키는 비대칭이 원칙 4를 지키는가 깨는가. 유지 쪽과 바꾸는 쪽 각각 가장 강한 논거, 그리고 네 판정. 바꾸는 쪽이면 대안 이름 2~3개.
3. 표에 빠진 축이 있으면(지금 생성 D가 내는 이름 중 표에 없는 것) 적을 것.

근거는 파일:줄 또는 grep 결과로. 평문 한국어.
