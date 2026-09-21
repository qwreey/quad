# round11 실측 라운드 — Studio 샌드박스(2026-09-21~)

원장 `.claude/qa-request/post-implementation-review-round11.md`의 실기기 실측 항목(HUMAN_TODO 10~12, Q62 네 입구, B″-8, tweenSlots GC, 물리 순서)을 **작게 하나씩** sonnet 서브에이전트로 잰다. 조건(사용자 확인 2026-09-18): 샌드박스 실험 플레이스 `Place1.rbxl`, 스크래치 인스턴스만 만들고 전부 파괴, 기존 트리는 읽기도 고치기도 안 함. 사용자 지시(2026-09-21): **코드는 바꾸지 않고 사용자 의견을 기록해 나간다** — 반영은 뒤에 묶어서.

## 1. `GetPropertyChangedSignal("className")` — 소문자 Deprecated 별칭 (HUMAN_TODO 10, 탐사 J′)

**측정(2026-09-21, sonnet, `execute_luau` Edit)**: `f = Instance.new("Frame")`.

| 항목 | 결과 |
|---|---|
| `GetPropertyChangedSignal("className")` / `"archivable"` | ok, `RBXScriptSignal` 반환 |
| `GetPropertyChangedSignal("name")` / `"parent"` | 에러 `name is not a valid property name.` / `parent …` |
| 대조군 `"ClassName"`/`"Archivable"`/`"Name"` | ok |
| `f.className`/`f.archivable`/`f.name` 읽기 | ok (`"Frame"`/`true`/`"Frame"`) |
| `archivable` 시그널 + `f.Archivable = false` (+`task.wait` 둘) | **0회** |
| 대조군 `Archivable` 시그널 + 같은 변경 | **1회** |
| `className` 시그널 + `f.Name = …` | 0회 — 단 `ClassName`은 원래 안 바뀌므로 이 프로브는 "죽은 시그널" 증명이 아님(결론엔 무관: 어느 쪽이든 절대 발화 안 함) |

부수: Deferred 기본이라 뮤테이션 직후 동기 카운트는 0, `task.wait` 뒤에 잡힘(1차 시도 대조군까지 0 → 2차로 확인).

**사실**: 소문자 별칭은 표면이 일관되지 않다(`className`/`archivable`은 시그널이 만들어지지만 발화하지 않는 죽은 시그널, `name`/`parent`는 생성 자체 거부). 생성 표면의 소문자 별칭은 둘 — 읽기 `Object.className`(31 클래스), 쓰기 `Camera.focus`. Deprecated 태그로 실린 것은 열 개(`className`·`focus`·`Draggable`·`DistanceLowerLimit`/`DistanceUpperLimit`·`FontSize`×3·`TextWrap`×3), Hidden 허용목록 넷(`Font`×3·`Transparency`).

**사용자 의견(2026-09-21)**: *"소문자 별칭들에 대한 동작은 roblox 측에서도 deprecated 라서 우리가 보장할 것이 없어. 문서화로 끝나는 범위이고, 우리가 표면에서 주든 말든 큰 문제 없다 봄. Deprecated 를 통으로 유지한다기 보단, 자주 쓰이던 것들만 유지해준다였어. remove 나 destroy 처럼 안 쓰이는건 지워도 돼. 특히 소문자는 quad v1 이 있기도 전의 요소야. 그리고 v1 이 바로 compat 하게 연결되지 못한다는게, 중간자가 있어야한다는게 지금 상황이고 마이그레이션에 있어서 재작성은 불가피하기에 자잘한 요소는 멈춰둬도 돼. 다만 재작성에 노고가 많이 드는 Font 등 일부 표면을 놔둔다는건데."* — 즉 2026-09-09의 "Deprecated 통째" 규칙(`PROP_TAG_LEGACY`)은 메인이 넓게 적은 것이고 의도는 허용목록.

**메인 의견**: Hidden처럼 Deprecated도 허용목록으로. 남길 후보 `Font`·`Transparency`·`FontSize`·`TextWrap`, 뺄 후보 `className`·`Camera.focus`·`DistanceLowerLimit`/`DistanceUpperLimit`, `Draggable`은 사용자 판단. 타입 표면만 바뀌는 변경(BREAKING 주간 안), 생성기 규칙 + 표면 JSON. **결정(2026-09-21)**: 허용목록 `FontSize`·`TextWrap`(+Hidden `Font`·`Transparency`), `Draggable` 제외(사용자) — 같은 날 반영.

## 2. 물리 자식 순서(HUMAN_TODO 12, K′) — **실측 불가(환경), 보류**

**2026-09-21**: rojo serve(`0.0.0.0:34872`, 이 머신 `172.17.7.4`)를 사용자가 Connect해 `ReplicatedStorage`의 `quad-base`/`quad-roblox`가 HEAD로 갱신된 것까지 확인(`holdLifetime`·Q61 마커). 그러나 MCP `execute_luau` 스레드가 **제한 capability 스레드**로 돌아 rojo가 넣은 일반 ModuleScript를 `require`할 수 없다 — `The current thread cannot require 'quad_base' since 'quad_base' has additional values for the Capabilities property: LoadUnownedAsset (and 3 more)`. 9월 8·16일 실측(같은 클론+require 관용구)은 통과했으므로 그 뒤 Studio/MCP 플러그인의 Script Capabilities 처리가 바뀐 것. 우회 시험: 스크래치 폴더 `Sandboxed = true`면 클론·부모 대입·require 게이트는 지나지만 모듈에 `RunServerScript`가 없어 `cannot start`, `Capabilities` 대입은 `cannot extend 'Capabilities' (lacking capability LoadUnownedAsset)`로 거부(스레드가 권한을 부여할 수 없음). 스크래치는 전부 파괴. **사람 몫**: Studio Beta Features의 Script Capabilities 계열 베타를 끄거나(권장), 명령줄(전체 권한)에서 quad 폴더 둘을 샌드박스+capability로 설정. 그 전까지 남은 실측(2~5번, 전부 Slot 실기기)은 보류. 참고: `Enum.SecurityCapability` 목록과 `SecurityCapabilities.new(...)` 생성자는 그대로 쓸 수 있었다.

**해결(같은 날)**: Beta Features엔 끌 항목이 없었고(사용자), 사용자가 명령줄에서 quad 폴더 둘을 `Sandboxed` + capability로 설정했으나 그 집합에 든 `ScriptGlobals`가 실행 스레드에 없어 여전히 거부. 스레드의 capability를 전수 열거(스크래치 샌드박스 폴더에 하나씩 대입해 성공 여부로): **HAS** = RunClientScript·RunServerScript·AccessOutsideWrite·LoadString·CreateInstances·Basic·Audio·Physics·UI·CSG·Chat·Animation·Avatar·Input·Environment·RemoteEvent·LegacySound·Players·**CapabilityControl**·AssetRead·AssetManagement·DynamicGeneration·PlatformAvatarEditing·AssetCreateUpdate·Capture·SensitiveInput·Monetization·LoadOwnedAsset·Social·ServerCommunication·Logging·PromptExternalPurchase·Groups·Teleport·Consequences·Material·AvatarBehavior·AvatarAppearance / **LACKS** = AssetRequire·**ScriptGlobals**·DataStore·Network·Plugin·LocalUser·WritePlayer·RobloxScript·RobloxEngine·Unassigned·InternalTest·PluginOrOpenCloud·Assistant·RemoteCommand·LoadUnownedAsset. 스레드에 `CapabilityControl`이 있어 메인이 두 폴더의 `Capabilities`를 `RunServerScript·RunClientScript·Basic·CreateInstances·UI·Environment·Players·Physics·Input·Animation·Audio·AccessOutsideWrite·Logging`으로 다시 설정 — quad는 `_G`/`shared`/`getfenv`를 src에서 안 쓰므로(`getfenv` 심은 spec 쪽) `ScriptGlobals` 없이 정상. 스모크: 클론(스크래치 폴더도 `Sandboxed` + 같은 집합) → `Quad.New():UseProvider(QuadRoblox)` → `D.Frame{ Size = src, slot, D.TextLabel }` + `src:Set(q.Tween{…})` 통과. **이후 Studio 실측의 로드 관용구**: 스크래치 폴더를 `Sandboxed = true` + 위 집합으로 만든 뒤 `quad-roblox` 클론을 그 아래에, `require(clone.luau_packages.quad_base)`·`require(clone.src).QuadRoblox`.

**측정(같은 날, sonnet, 검증된 로드 관용구)**:

| 단계 | 물리 `GetChildren()` | quad 부기 `_elements` | Length/Offset |
|---|---|---|---|
| 마운트 `{s0, A(a1,a2), s1, B(b1,b2)}` | s0,a1,a2,s1,b1,b2 | A: a1,a2 / B: b1,b2 | A.Length 2, A.Offset 1, B.Offset 4 |
| `A:Add(a3)` | …,b2,**a3**(호스트 맨 끝) | A: a1,a2,a3 | A.Length 3, B.Offset 5 |
| `A:Move(1,3)` → `A:Swap(1,2)` | 변화 없음 | A: a3,a2,a1 | 그대로 |
| `A:Remove(2)` → `B:Add(b3)` | s0,a1,s1,b1,b2,a3,b3 | A: a3,a1 / B: b1,b2,b3 | A.Length 2, B.Offset 4 |
| `:List` [x,y,z] → `[z,x,y]` | x,y,z(변화 없음) | C: z,x,y | — |

**사실**: 물리 순서 = 부모 대입 순서, quad는 이후 안 건드린다(`Move`/`Swap`/`:List` 재정렬은 부기만; 새 원소는 논리 위치와 무관하게 호스트 자식 배열 끝). 부기(`Length`/`Offset`)는 전 단계 정확. 설계 그대로(`nativeMove`/`nativeSwap` 의도적 no-op, `nativeInsert` 오프셋 무시) — extend/01·core/06 `Move`/`Swap`·GS 13이 이미 서술. **판정**: 결함도 문서 공백도 아님. **사용자(2026-09-21)**: *"확인했어. 기록하고 넘어가자"* — HUMAN_TODO 12 닫음, 변경 없음.

## 3. Q62 — Instance 매개 순환의 네 입구 잔여 상태(HUMAN_TODO 11 전반)

**측정(2026-09-21, sonnet)**: `s = q.Slot(); s:Add(e1); host = D.Frame({ Name="host", s }); host.Parent = probe`(조상 케이스는 `anc = D.Frame{…}; host.Parent = anc`). 에이전트가 첫 라운드에 `D.Frame({…}, s)`(자식을 둘째 인자로 — 조용히 버려짐)로 잘못 불러 재실측.

| 입구 | 엔진 에러 | 직후 | 다른 Slot Add / dispose | 회복 | 이후 CRUD |
|---|---|---|---|---|---|
| `s:Add(host)` | `Attempt to set …host as its own parent` | `_elements` 2, `Length` 1, `host.Parent` 불변 | "already mounted" / "still held by a Slot" | `Extract(2)` → 정확히 복구, 새 Slot에 재추가 가능 | 정상 |
| `s:Replace(1, host)` | 같음 | `_elements` 1, `e1` 살아남음(파괴 안 됨) | 같음 | `Extract(1)` → 정상 | 정상 |
| `s:Splice(1, 0, host)` | 같음 | `_elements` 2, `Length` 1 | 같음 | `Extract(1)` 직후 카운트는 맞으나 **이후 `Length` 영구 고착**(`elements` 3, `Length` 1) | **동결** |
| `s:Splice(1, 1, host)` | 같음 | `e1` 살아남음 | 같음 | `Extract(1)` → 정상(이 배치는 우연히 자가치유) | 정상 |
| `s:Add(anc)` | `… would result in circular reference` | 같은 모양, `anc.Parent` 불변 | 같음 | `Extract(2)` 되지만 **`anc.Parent = nil`**(실제 부모에서 뜯김) | 정상 |

**사실·판정**:
- `Splice` 삽입 경로의 동결은 새 결함이 아니라 확정된 UB — `rawSplice`가 배치 Blocker를 켠 뒤 물리 op를 부르고 거기서 던지면 `OffWithoutEmit`에 못 가 재계산이 영영 멈춘다(round8 Q40 (a)·`H6-19`의 모양; 순환은 선행 패스가 못 걸러 창 안까지 들어간다).
- **문서의 회복 안내 "`slot:Remove(그 자리)`"는 틀렸다** — `Remove`는 `nativeRemove` → `element:Destroy()`라 host 자신을 넣은 경우 **host를 파괴**, 조상이면 **조상째(host 포함) 파괴**. 통하는 것은 `Extract`이고, 그것도 `nativeExtract`의 무조건 `element.Parent = nil`이 host/조상을 실제 부모에서 뜯어내므로 "Extract 뒤 원래 부모에 다시 붙여라, Splice로 넣었으면 그 Slot은 동결이라 버려라"가 정직한 안내. → **문서 정정 대상**(core/06 Q62 캐비엇, slot-plan Q42 항목의 "`Remove(1)`로 복구") — 반영은 뒤에 묶어서.
- `nativeExtract`의 `Parent = nil` 가드(`if element.Parent == target`)는 "물리 자식이었던 적 없는 원소"에만 의미가 있고 그 상태를 만드는 길은 순환뿐(다른 곳에 소유된 원소는 선행 패스 `claimOwnerAt`이 거부해 `_elements`에 못 들어감). **사용자(2026-09-21)**: *"3번은 정확히는 host 요소가 recursive 하거나 owned(unreleased) 인걸 끼워 넣는 경우임? 그렇다면 원칙상 보류에 동의해. 순환은 UB확정 난 맞다 봐."* — 순환뿐임을 확인, 가드 보류(드문 오용에 구조를 쓰지 않는다), 순환 UB 유지.

## 4. B″-8 — `releaseOwner` → `vacate` 창(HUMAN_TODO 11 후반)

**측정(2026-09-21, sonnet)**: 밖에서 파괴된 호스트(Q9 좀비) 위에서 `Extract`/`Remove`/`Add`/`Replace`/`Splice`/`dispose` 여섯 + 대조군.

| 케이스 | `Parent` 대입 throw | 결과 |
|---|---|---|
| `Extract(1)` / `Remove(1)` | 없음 | 배열 줄고 `Length` 정확; 뽑은 원소 재사용은 quad 게이트 "not claimed … a destroyed one", `dispose(s)`는 "still held … cannot be reused after its parent is destroyed" |
| `Add(e3)` / `Replace(1,e9)` / `Splice(1,1,e8)` | 없음 | 성공, 새 원소가 **시체 호스트에 물리적으로 붙음**(`e3.Parent == host`), `Length` 정상 증가, 동결 없음 |
| `dispose(s)`(선행 CRUD 없이) | — | quad 게이트로 거부, 그 뒤 `Add`는 계속 성공 |
| 대조군(산 호스트) | — | 다섯 연산 정상 |

**판정**: 창은 실기기에서 **도달 불가** — 엔진은 시체의 `Parent = nil`·산 것의 `Parent = 시체`를 조용히 통과시키고(H′), 시체 원소는 `H-548` 게이트가 선행 패스에서 막아 던질 입력이 없다. 관측된 모양은 알려진 Q9 좀비 UB 그대로. **사용자(2026-09-21)**: *"닫아도 될것 같아. UB로써 문서 추가를 준비해둬줘."* → HUMAN_TODO 11 완결. **문서 추가(준비, 반영은 뒤에 묶어서)** — core/06 "파괴된 Slot" 불릿 옆에: *"마운트 대상이 quad 밖에서 파괴된 Slot은 그 사실을 모릅니다 — `Add`/`Replace`/`Splice`는 계속 성공하고 새 원소는 죽은 인스턴스에 붙습니다(정의되지 않은 동작). 알아채는 자리는 `q.dispose`(`… cannot be reused after its parent is destroyed`)와 뽑아낸 원소의 재사용(`… a destroyed Instance cannot be reused`)뿐입니다 — 화면을 quad 밖에서 지웠다면 그 Slot도 버리세요."* 3번의 회복 안내 정정과 같은 묶음.

## 5. tweenSlots GC — 강하게 쥔 `Tween`이 대상 Instance를 붙잡는가(ROADMAP 백로그, `H-71` 모양 우려)

**측정(2026-09-21, sonnet, quad 없이 순수 엔진)**: N=20, weak-value 카나리 + 에포크당 `table.create(5000)`×20 할당 압력 + `task.wait(0.05)`, 상한 150에포크(전부 3~9에포크 수렴). Studio Edit 스레드의 `collectgarbage`는 `count`만(다른 인자는 에러 — 기존 기록과 일치).

| 그룹 | 남은 수/20 | hold 비운 뒤 |
|---|---|---|
| A 대조군(Tween 없음, Destroy) | 0 | — |
| B 강한 보유·Playing·Destroy | 0 | 0 |
| C 강한 보유·Completed·Destroy | 0 | 0 |
| D 강한 보유·Cancelled·Destroy | 0 | 0 |
| E 약한 보유·Playing | 0(Tween도 0) | — |
| F 강한 보유·Playing·`Parent = nil`만 | 0 | 0 |
| G 확증 | Frame 회수 시점에 Tween은 20/20 생존(`PlaybackState` Playing) | — |

**판정**: 강하게 쥔 `TweenService:Create()` 반환 객체는 대상 Instance의 userdata를 Lua GC 그래프에 **붙잡지 않는다**(세 상태·두 파괴 방식 모두; G에서 Tween 생존 + 대상만 먼저 회수 확인 — 연결은 엔진 내부 참조). 범위 한정: `Frame`·`Size`·Workspace 하위. → `tweenSlots`의 `{ Tween, Value }` 강한 저장은 안전, ROADMAP의 "완료된 Tween을 `{ Value }`로 낮추는 처방(`Completed` 연결)" 불필요, Q65의 기록 유지 결정도 GC 면에서 뒷받침. **사용자(2026-09-21)**: *"맨 처음에 해당 사실을 간접적으로 알고 있었어(그러나 사실 확인이 필요했음). 근데 실측 상 확정되었기에, 내 처음 의견인 처방이 필요 없다였는데, 네 의견과 일치해 닫아짐으로 두면 될것 같아."* → 닫힘. ROADMAP 백로그 문장 정정은 문서 묶음에 포함.

## 6. GS 07 `GuiService.SelectedObject` 예제(HUMAN_TODO 13)

**측정(2026-09-21, sonnet, 예제 그대로)**:

| 위치 | 결과 |
|---|---|
| (ii) `StarterGui` 아래 `ScreenGui`(정상 사용) | 10 → select, 11 → cleanup(`dying=false`) 뒤 재select, 3 → 해제 — 전부 **동기**. `card:Destroy()`는 cleanup `dying=true` 정확히 한 번, **지연**(`task.wait()` 뒤; 파괴 직후 동기 시점엔 죽은 버튼이 아직 선택돼 있음) |
| (i) GUI 트리 밖(`ServerStorage` 아래) | `GuiService.SelectedObject = inst`가 엔진 에러: `Cannot set GuiService.SelectedObject to … because it is not a descendant of a PlayerGui` |
| 대조군(quad 없이 선택 뒤 `Destroy`) | 엔진은 파괴된 선택을 스스로 비우지 않음(`task.wait()` 뒤에도 죽은 인스턴스) |

**판정**: 문서 서술은 정상 사용에서 그대로 성립하고, "사라진 버튼이 선택된 채 남지 않는다"는 보장은 **엔진이 아니라 quad의 cleanup**이 만든다(대조군). 부수 사실 둘 — 문서 묶음에 캐비엇으로: (a) PlayerGui 자손이 아니면 대입이 던진다(테스트용으로 밖에 두고 돌리면 fn이 던져 그 Effect는 죽음), (b) 파괴로 인한 cleanup은 Deferred라 한 틱 뒤(`H-291`과 같은 사실 — GS 07 문장은 즉시처럼 읽힘). `count:Set(11)`에서 `isBig`가 true→true인데 Effect가 재실행되는 것은 push-invalidate 모델의 알려진 동작(GS 07 mock 실측 주석과 같음). **사용자(2026-09-21)**: *"확인했어. 해당 사실대로 기록되면 될것 같아."* → HUMAN_TODO 13 닫음.

## 라운드 정리(2026-09-21)

여섯 후보 전부 실측. 라운드 중 코드 변경 0(사용자 지시). 결정·문서 묶음 — **[같은 날 반영 완료]**(생성기 `DEPRECATED_NAME_KEEP` + 표면 JSON + D 재생성, roblox/02·core/06·slot-plan·GS 07·CHANGELOG·todos; test.sh exit 0):
1. **Deprecated 허용목록**(1번): 남김 `Font`·`Transparency`·`FontSize`·`TextWrap`, 뺌 `className`·`Camera.focus`·`DistanceLowerLimit`/`DistanceUpperLimit`·**`Draggable`**(사용자: *"deprecated 의 draggable 은 딱히 포함하지 않아도 될것 같아"*). 생성기 `PROP_TAG_LEGACY` 통째 규칙 → 이름 허용목록(Hidden과 같은 모양) + 표면 JSON + D 재생성, 타입 BREAKING(창 안), CHANGELOG.
2. **Q62 회복 안내 정정**(3번): core/06 Slot 순환 캐비엇·slot-plan Q42 항목의 "`Remove(1)`로 복구" → "`Extract` 뒤 원래 부모에 재부착; `Splice`로 넣었으면 그 Slot은 동결(Q40)".
3. **Q9 좀비 UB 한 줄**(4번): core/06 "파괴된 Slot" 불릿 옆 문안(4번 절).
4. **GS 07 캐비엇 둘**(6번).
5. ROADMAP tweenSlots 메모(5번)는 반영 완료.

