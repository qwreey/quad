--!strict
-- [Studio 확인용, 2026-10-16] Studio에는 진단을 한꺼번에 복사할 방법이 없어(공식 API·Script Analysis 창 모두 — 메인 조사), 05번의 질문을
-- **진단 한 줄**로 모았다. 이 파일의 `[BRIEF] …` 진단 하나만 hover해서 복사하면 된다.
-- 리눅스 vsc(사용자 VSCode 재구성) 기대값은 아래 CLI 줄. Studio에서 볼 것: 개수가 같은가, inj가 비는가(Studio는 Hidden·Deprecated를
-- 원래 가진다 — 9/16), BgColor·DataCost가 `-`(Deny가 먹음)인가, MouseEnter가 `(number, number) -> ()` 꼴인가(extern 경로).
-- `Build`가 Studio에서 런타임 에러를 내면 그 메시지가 대신 뜬다 — 그대로 적을 것.
local L = require("./Lib")

type B = L.Brief<Frame | TextLabel | TextButton | ImageButton | UIScale | WorldModel | UIShadow>

-- CLI vsc(사용자 VSCode 재구성) — 209자:
--   [BRIEF] Frame 38/26 +Transparency; TextLabel 57/26 +FontSize,TextWrap,Transparency; TextButton 63/34 +FontSize,TextWrap,Transparency; ImageButton 58/34 +Transparency; UIScale 5/9; WorldModel 8/9; UIShadow 13/9
-- 읽는 법: `클래스 프로퍼티수/이벤트수`, `+…`는 정책이 채워 넣은 것(Studio에선 비어야 정상), `!BgColor`·`!DataCost`는 Deny가 안 먹은 것, `ME=…`는 MouseEnter 콜백 모양이 다른 것.
-- Studio( )
