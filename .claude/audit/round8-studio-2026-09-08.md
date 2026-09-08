# round8 실기기 실측 — Q41·Q42·Q47 + 엔진 에러 문구 (2026-09-08 밤)

**무엇**: round8 감사(`qa-request/post-implementation-review-round8.md`)가 "실기기 필요"로 남긴 셋과 CLI mock이 못 보는 엔진 문구를
`Place1.rbxl`(Edit 모드, MCP `execute_luau`, rojo 라이브 싱크 — 사용자가 172.17.7.3:34872로 Connect)에서 돌린 결과. 동기화 확인 마커는
`s:Add(s)`가 `H-500` 게이트 메시지로 거부되는 것(오늘 커밋). 스크립트 원문은 세션 `session/2026-09-08-03-cumulative-audit.md` 8절.

| 항목 | 결과 | 판정 |
|---|---|---|
| **Q41** `D.New("Frmae")` | 팩토리 반환은 성공, `D.New("Frmae")({})`에서 엔진 `Unable to create an Instance of type "Frmae"` — 위치 접두 없음(C 에러), 스택은 생성물 `D/init.luau` | 문구가 클래스 이름을 말한다. 사용자 결정 자리(§15) |
| **Q42** Instance 매개 순환 | `F = D.Frame{ s }; s:Add(F)` → 엔진 `Attempt to set Frame as its own parent`; 조부모면 `… would result in circular reference`. **raise 뒤 상태**: `IndexOf(F) == 1`인데 `Length == 0`, `F.Parent == nil`(요소는 들어갔고 부기·물리는 안 됨), 다음 `Add`는 정상(Length 1), `Remove(1)`이 F를 파괴해 복구된다 | 반쪽 상태가 남지만 복구 가능. 사용자 결정 자리(§15) |
| **Q47** Tween 슬롯 GC | `Size = src` Frame에 `src:Set(Tween{…})` 한 번 뒤 `Destroy` → GC 강제(가비지 생성 + `task.wait` 8프레임) 뒤 weak 참조 **회수됨**(plain·`UICorner` 관리 자식도 회수) | **mock 전용 문제** — 실물 Tween userdata는 Instance를 Lua 그래프에 안 쥔다. mock의 `Instance` 필드를 weak로(같은 커밋) |
| 엔진 문구 | `SetAttribute(name, {})`·메타테이블 테이블 → `Array is not a supported attribute type`; `Size = {}` → `Unable to assign property Size. UDim2 expected, got table`; `Size = "x"` → `… UDim2 expected, got string` | `H-498` Attr 게이트가 그 앞에서 사용자 줄로 막는 것 확인(실물에서 `Attr({ x = Slot })` 거부 메시지 그대로) |
| **부수 발견** `Connect(비함수)` | `signal:Connect(5)`가 **던지지 않고** `RBXScriptConnection`을 돌려주며 콘솔에만 *"Attempt to connect failed: Passed value is not a function"*(스택은 `Handlers/Event.luau:65`). `D.TextButton{ MouseButton1Click = 5 }`·`"str"`·`{}`·`State<number>` 전부 조용히 통과 | Event 헤더의 "엔진이 raise한다" 전제가 거짓 → **`H-507`** 값 게이트(같은 커밋, `spec.events` 8절). `OnChange("Name", 5)`는 생성자 게이트가 이미 막음 |

**운영 메모**: rojo serve는 이 쪽에서 `mise exec -- rojo serve --address 0.0.0.0 --port 34872`(백그라운드), Studio는 이미 MCP에 붙어 있었고
플러그인 Connect만 사용자가 눌렀다. Edit 모드 `execute_luau` 안에서 `task.wait`가 정상 동작(GC 프로브에 사용).
