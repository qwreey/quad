# 이름 검토 — devui 창 메뉴바 자리·버튼 아이콘 (2026-10-21)

사용자 요청(*"이름은 아마 luna/gemini/sonnet 에게 묻는게 나을듯"*)으로 같은 프롬프트(`prompt.md`)를 세 계열에 물었다. 답 원문은 `codex-gpt-6-luna.md`·`gemini-3.8-flash-high.md`·`sonnet.md`.

- **창 메뉴바 자리**: luna `MenuBar`, Gemini `MenuBar`(`TopBar`는 Roblox 상단바와 겹쳐 오해 — 플래그), sonnet `Header`(위젯 이름과 겹쳐 `Window({ MenuBar = Devui.MenuBar(...) })`가 중복처럼 읽힘). 셋 다 위젯 `Devui.MenuBar`는 이름을 바꾸지 않고 범용으로 두라 함(`WindowMenuBar`는 창 전용처럼 보임). → 다수안이자 사용자가 먼저 동의한 `MenuBar`로 구현.
- **버튼 아이콘**: Gemini·sonnet `Icon`(`Style.Icons`와 같은 어휘, Window `Icon`과 같은 "이 요소를 나타내는 작은 이미지 id"라 호환), luna `IconImage`(Window `Icon`과 구분). → `Icon`으로 구현.
