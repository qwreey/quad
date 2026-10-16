# 이름 탐색 2026-10-16 — 배열부 이벤트 디스크립터(`OnChange`의 짝)

사용자 1안 `OnEvent`를 sonnet(레포를 안 읽은 외부자, 채팅 보고)과 Gemini(`gemini.md`)에 같은 과제로 맡겼다. **둘 다 따로 `OnEvent` 추천** — `OnChange`와
`On + 대상` 짝으로 읽히고, Fusion의 `OnEvent`/`OnChange` 쌍과 같은 구도라 Roblox 선언형 UI 사용자에게 설명이 필요 없다. 약점은 생명주기 훅 `OnCreated` 등과
`On` 접두가 같다는 것인데, 훅은 `(fn)` 하나·디스크립터는 `(name, fn)`이라 호출 모양으로 갈리고 문서 한 줄로 막힌다(둘 다 같은 판단). 차선은 갈림 — sonnet `On`(가장 짧음,
대신 `On*` 무더기에 묻힘), Gemini `Connect`(Roblox 관용어로 다중 연결이 선명, 대신 `OnChange`와 비대칭·명령형). 훅 혼동을 가장 걱정할 때의 대안은 `OnSignal`(sonnet).
