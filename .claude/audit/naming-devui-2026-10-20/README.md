# devui 이름 검토 — 세 모델 계열 (2026-10-20)

같은 프롬프트(`prompt.md`)를 세 계열에 줬다. Gemini는 "파일을 보지 말라"는 지시와 달리 레포를 읽었으므로 입력이 완전히 같지는 않다. 인용 사실(`Selectable.Selected`, Roblox `AbsoluteContentSize`)은 메인이 확인했다.

- `codex-gpt-6-luna.md` — codex-cli 0.163.0, `gpt-6-luna`, effort medium. uid 61000, 빈 디렉터리, read-only 샌드박스.
- `sonnet.md` — Claude sonnet 서브에이전트.
- `gemini-3.8-flash-high.md` — agy, 격리 worktree.

**수렴**
- 켜짐 단추: 셋 다 `Checked` 대신 `Toggled`.
- `NoPages`·`TabRounding`: 셋 다 유지.
- `VirtualRows`: 둘이 유지(codex만 `VirtualList`). `ScrollTo`는 둘이 행 번호를 드러내게 바꾸자고 했다.
- `Focused`: 셋 다 Window(출력)와 InputText(양방향)의 방향이 섞인다는 점을 짚었다.

**갈림**
- 드래그 콜백: sonnet·Gemini는 `OnFrame`(`tick()`과 혼동), codex는 `OnTick` 유지.
- `ContentSize`: sonnet 유지, codex는 `AvailableContentSize`, Gemini는 높은 위험(Roblox `AbsoluteContentSize`는 반대 뜻).

**사용자 결정 (2026-10-20, "전부 동의해")** — 메인 권고를 그대로 받았다.
- 새 이름: `Toggled`·`NoPages`·`TabRounding`·`OnFrame`.
- 개명: `ContentSize`→`AvailableSize`, `ScrollTo`→`ScrollToRow`.
- `Window.Focused` 양방향(받치는 `ManagerSlot:Blur()`는 메인이 더함).
- `Source` 방향 규약 셋(양방향·출력·명령)을 README 값 규약에.
