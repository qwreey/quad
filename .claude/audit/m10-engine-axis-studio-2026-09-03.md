# M10 엔진 축(Tag/Attribute op) — Studio 실기기 실측 (2026-09-03)

**무엇을**: quad-roblox `EngineOps.luau`에 심은 `addTag`/`removeTag`
(CollectionService)/`setAttribute`(`inst:SetAttribute`, nil = 삭제)가 base
핸들러(`Tag.luau`/`Attribute/Key.luau`/`Attribute/init.luau`)의 호출 계약대로 실물
Instance에 닿는가. CLI 쪽은 `quad-roblox/test/spec.tagattribute.luau`(mock
CollectionService 심)가 같은 단언을 한다.

**어떻게**: Edit 모드 `execute_luau`, rojo 싱크본을 `ServerStorage.QuadTestRun`에
폴더째 클론해 `require(clone.src)`(`audit/m5-unit5-first-render-2026-09-02.md`
관용구), 싱크 확인(`EngineOps.Source`에 `CollectionService` 존재),
`Quad.New():UseProvider(require(qr.src).QuadRoblox)`, 루트는 `q.D.Frame { … }`.

## 결과

| 시나리오 | 단언 | 결과 |
|---|---|---|
| T1 `Source(Tag("a","b"))` 자식 | `CollectionService:GetTags` = `a,b` | PASS |
| T2 `:Set(Tag("b","c"))` | `b,c` — `a`만 제거·`c`만 추가(깜빡임 없는 diff는 base 몫, 엔진엔 결과만) | PASS |
| T3 `:Set(nil)` | 태그 전량 제거 | PASS |
| A1 `[AttributeKey("Hp")] = Source(5)` / `[AttributeKey("Title")] = "quad"` / `Attribute({ Level = 3 })` | `GetAttribute` 셋 다 기록(그룹은 단일 키 경로 위임) | PASS |
| A2 `hp:Set(9)` | 반응형 값 반영 | PASS |
| A3 `hp:Set(nil)` | `Hp` 삭제, `Title` 유지 | PASS |
| S1 프로바이더 없는 `Quad.New()` | `addTag` 안내 스텁 error("addTag is not available") | PASS |

최종 마커: 7/7 PASS, FAIL 0 (`check()` 단언 수).

## 후속 실측 — 타입드 스칼라 슈가 (같은 날, round16 `H10-15`)

`D.Frame { StringAttribute("Title", "quad"), NumberAttribute("Hp", src), BooleanAttribute("Alive", true), [AttributeKey "Tint"] = Color3 }`:

| 항목 | 관측 |
|---|---|
| 초기 | `Title=quad Hp=3 Alive=true Tint=1, 0, 0` — 슈가 셋(그룹 경로)과 무타입 `AttributeKey`(Color3, 엔진 고유 타입)가 같이 앉음 |
| `src:Set(4)` / `src:Set(None)` | `Hp=4` → `Hp=nil`(삭제) — StoreBind 반응형·None 삭제가 그룹 위임 경로 그대로 |
| `NumberAttribute("X", "nope")` | `AssistantCommand:26: NumberAttribute("X"): value must be a number (or State/None), got string` — 사용자 줄 blame |
| `StringAttribute("X", nil)` | `…:27: StringAttribute("X"): value must not be nil — use None to delete` |
| 같은 이름 슈가 둘 | `…:28: attribute "Dup" is already bound by another owner` — 그룹의 개인 키 claim 그대로 |

## 잔여·부수

- `ServerStorage.QuadTestRun`은 실측 산출물(다음 실측이 시작 때 지운다).
- Attribute 읽기 소비자(`InstanceHandle` 언랩 — ROADMAP M10 Q6 각주)는 쓰기
  경로와 무관해 이 실측 범위 밖(읽기 API가 생길 때).
