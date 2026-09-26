# round13이 남긴 실기기(Studio) 실측 후보 — 초안 (S9)

`post-implementation-review-round13.md`(HEAD `190bc315`) §0 표의 "실기기" 열과 §1(H-*)·§2(E1~E23·T2·P-TWEEN 등) 본문의 "미실측/미완/엔진 지식/실기기" 표현을 전수로 훑어 모은 표. **결정 아님, 반영 아님** — 메인이 이 초안을 보고 (1) `HUMAN_TODO.md`에 어떤 모양으로 얹을지, (2) 지금 실측할지 뒤로 미룰지 고른다.

## 1. 결정을 막는 것 (실측 없이는 Q들의 처방을 고를 수 없음)

| 항목 | 출처 | 확인할 엔진 사실 | 왜 필요한가 | 프로브 한 줄 |
|---|---|---|---|---|
| 트윈 float32/정수 round-trip | Q97, 묶음1·2 조합검증 잔여 | `BackgroundTransparency`류 float 프로퍼티에 `0.1`을 쓰고 바로 읽으면 `== 0.1`인가; UDim `Offset`(정수)은 절삭되는가 | Q81 (b)(Tween Dedup을 기록이 아니라 `inst[k]` 실측값과 비교)를 채택하려면 Q97 (b)(허용 오차 비교)가 선행 조건 — 정확 비교로 가면 같은 목표가 매번 재생됨 | `local f=Instance.new("Frame"); f.BackgroundTransparency=0.1; print(f.BackgroundTransparency==0.1)` / `local p=Instance.new("UIPadding"); p.PaddingLeft=UDim.new(0,7); print(p.PaddingLeft)` |
| 트윈 보간 중 매 프레임 Changed 신호 | Q78, `H-601` | 진행 중인 Tween이 프레임마다 `GetPropertyChangedSignal`을 실제로 발화하는가(초당 몇 회) | `q.Out`+`Animate` 캐비엇((a))과 "두 Source로 가르는 관용구"((c))가 전제로 까는 사실 — Q81과 같은 자리에서 결정 | `TweenService:Create(f, TweenInfo.new(1), {Position=UDim2.new(1,0,0,0)})`; `f:GetPropertyChangedSignal("Position"):Connect(function() n+=1 end)`; `:Play()`; 1초 뒤 `print(n)` |
| 같은 프레임에 끝나는 여러 트윈의 통지 순서·`PlaybackState` 선행 | Q91, Q99, 묶음1·2 조합검증 잔여, 기존 `audit/tween-completed-2026-09-21`(부분 실측) | `UIPadding`처럼 한 Tween이 프로퍼티 여럿을 같은 프레임에 끝낼 때 `Completed`가 오는 순서, 그리고 `PlaybackState`가 통지보다 먼저 바뀌는가 | Q91 (b)의 OLD-FIRST/NEW-FIRST 선택, Q99 처방(b2 vs c) 선택이 이 순서에 의존 | 기존 `audit/tween-completed-2026-09-21/infinite-tween-probe.md` 관용구를 `PaddingLeft/Right/Top/Bottom` 4프로퍼티 한 Tween으로 확장, 각 콜백에 `os.clock()`+`PlaybackState`를 로그 |
| 철거 뒤에도 연결을 안 끊으면 지연된 완료 통지가 오는가 | Q99 b2 | Tween 목표 도달 직후(통지 도착 전) 그 자리를 다른 값으로 갈아 끼워도(연결은 유지) 엔진이 나중에 `Completed`를 여전히 전달하는가 | Q99 후보 b2(연결 유지, `isClaimed` 게이트로 무시)가 성립하려면 이 전제가 참이어야 함 — 거짓이면 b2는 버리고 c(철거 창은 `Cancelled`로 통일)만 남음 | Tween 걸고 목표 근접 시각에 `Instance.new` 새 값으로 프로퍼티 자리 교체(연결 미해제) → 이후 `Completed` 도착 여부 로그 |
| Claim 자식 경로의 `IsA` 상속(추상 클래스) | Q84 | `q.newMapperClass("GuiObject")`처럼 추상 클래스를 넘긴 매퍼가 실제 서브클래스 인스턴스에 `IsA`로 참을 반환하는가(Roblox 표준 동작이라 확신도 낮음) | Claim 루트 클래스 op 채택 시 자식 경로 통일(V1/V2, Q49 역전 여부)의 마지막 빈 칸 — 다만 Roblox 공식 문서상 자명해 결정 자체를 막지는 않음(§0 표도 Q84 실기기 열을 "아니오"로 적음) | `print(workspace:FindFirstChildWhichIsA("Frame", true):IsA("GuiObject"))` |

## 2. 정보만 (결정을 막지 않음 — 기록되면 캐비엇 문장을 확정/삭제)

한 엔진 사실을 여러 탐사가 적었으면 출처를 합쳤다.

| 항목 | 출처 | 확인할 엔진 사실 |
|---|---|---|
| `task.delay(0)` 재개 시점 | E11, E12 | 다음 프레임인가 즉시(같은 프레임 뒤)인가 |
| `task.delay(math.huge)` | E11, E12, Q100 | 에러/경고 없이 영원히 대기하는가(Q100 (a) 유한성 검사 채택은 이 실측 없이도 가능 — 정보용) |
| 계속 발화하는 RunService성 상류 위 Debounce/Throttle 게이트의 GC 잔여 | E42, Q129 | 호스트 파괴 뒤 상류가 계속 발화하는 동안 게이트가 몇 개 남고 얼마나 걸려 사라지는지(CLI mock은 57~1000개, 상류 멈추면 3초 안 0) — 의도된 보유(권고 (a))가 실사용에서 체감되는 규모인지(정보용) |
| 실행 중 스레드의 `task.cancel` | E11, E12 | 실행 중인(yield 없이 돌고 있는) 스레드를 취소하면 어디서 멈추는가 |
| `FindFirstChild` 숫자/`nil` 키 | E11 | 숫자나 `nil`을 이름 인자로 주면 에러인지 `nil` 리턴인지 |
| `SetAttribute` 이름 규칙 | E11, E16, `H-659` | 속성 이름에 허용되는 문자·길이 제한 |
| CollectionService 태그 이름 제약 | E11, E16 | 태그 이름 길이·문자 제한(mock은 공백·10만자·한글 전부 통과) |
| `nativeFindChild`/Claim의 `IsA` 하위 클래스 매칭 | E6-2, E11, E17 | mock은 `ClassName ==`만 하는데 엔진은 `IsA`로 서브클래스까지 통과하는지(roblox/04 문서 약속의 실측) |
| 파괴된 인스턴스의 CollectionService 태그 잔존 | E16 | `Destroy()` 뒤에도 태그가 남는지 |
| 여러 리스너가 있을 때 `Destroying` 발화 순서 | E16 | 등록 순서 보장 여부(문서 미정) |
| `:Clone()`의 Attr/Tag 복사 | E17, `HUMAN_TODO` C13 | 클론이 속성·태그를 같이 복사하는지 |
| 실제 `RemoteEvent` 네트워크 타이밍 | E17 | how-to 04 레시피의 서버-클라 지연이 mock 가정과 맞는지 |
| 미파괴·무부모 claim 트리의 GC | E17(`H-293` UB) | 부모 없이 떠 있는 Instance 트리가 실제로 수거되는지 |
| 레거시/현행 별칭 동시 사용 시 우선순위 | `H-640`, E10 | `Font`+`FontFace`처럼 옛 이름과 새 이름을 한 props에 같이 쓰면 엔진이 어느 쪽을 반영하는지(mock은 해시 순회 순서라 미정) |
| `UIDragDetector`/스크롤이 쓴 값과 Tween Dedup 상호작용 | E10 | 사용자 조작(드래그·스크롤)이 프로퍼티를 바꿀 때 Q81 Dedup 판정과 부딪히는지 |
| `LocalScript` 보안 문맥의 `Permits.Write` | E10 | 보안 등급이 있는 Write 프로퍼티가 LocalScript에서 실제로 막히는지 |
| 다른 quad-base 사본의 State를 quad-roblox 문자 키 자리에 놓았을 때 | E18, `H-697` | mock은 `Name`이 잎에서 죽고 `Visible`은 조용히 테이블을 대입하는데 실제 엔진 반응은? |
| `OnDestroyed` 훅 여럿의 발화 순서 | `H-683`, E16(공통 계약 절) | mock은 백엔드 시그널 LIFO — 엔진에서도 그런지 |
| Immediate 파동 중 `bindLifetime` 호출 | E9 | 실기기에서도 문서 서술대로 동작하는지 |
| Ref/Observer가 놓인 자리가 파동 도중 교체되는 경우 | E9 | 실기기 동작(mock 계약과 같은지) |
| 참조 없이 버린 `RBXScriptConnection`의 GC | Q94, E9, E11 | Lua 쪽 참조를 전부 버려도 연결 userdata가 계속 살아 발화하는지(mock은 Signal이 강하게 들어 이 문제를 가림) — Q94 심각도 판단 재료지만 (a)+(b) 권고 자체는 이 실측 없이도 채택 가능 |
| `table.sort` 비교자 안 yield | E21 | Roblox 메인 스레드가 CLI처럼 비교자 안에서 yield 가능한지(`Quad0134` 재현 조건) |
| `CanvasPosition` 클램핑 | 묶음1·2 조합검증 잔여 | `ScrollingFrame.CanvasPosition`에 범위 밖 값을 대입하면 클램핑되는지 |
| 엔진 쪽에서 우리 트윈을 취소한 뒤 `PlaybackState` 전환 시점 | 묶음1·2 조합검증 잔여 | 우리가 만들지 않은 취소(다른 스크립트·엔진)가 일어난 뒤 `PlaybackState`가 언제 `Cancelled`로 바뀌는지 |
| debug 모드 동률 경고의 실제 출력 | E18 | 핸들러 동률 경고가 (등록 **전**에 debug를 켰을 때) Studio 출력창에 실제로 찍히는지 |
| GS 07 §3 `:Wait` 코루틴 | E16 | mock은 심(가짜)만 확인했음 — 실제 코루틴 동작 확인 |

### 2-E29 추가(2026-09-27, mock 충실도 대조가 낸 여덟 — 이미 위에 있는 IsA 상속·속성/태그 이름·`task.delay(0)`·Destroying 순서·별칭 우선순위는 제외)

1. 파괴된 부모 아래로 부모 지정 — `core/06-slot.md` 613행 "[mock 관측]": 부모 `Destroy()` 뒤 새 Frame `.Parent` 대입을 pcall로 돌려 성공 여부·결과 Parent.
2. 없는 이름의 `GetPropertyChangedSignal` — `roblox/05-onchange.md` 113~114행·`OnChange.luau` 헤더 전제: `D.Frame { q.OnChange("Text", fn) }`을 pcall로 돌려 문구·blame 줄.
3. 보간 불가 타입의 `TweenService:Create` — `roblox/02-d.md` 119행 "둘째 값부터 엔진이 거부": Animate를 건 `Text`에 값 둘 `Set`.
4. nil을 못 받는 프로퍼티에 `q.None` — `roblox/02-d.md` 121행: 문구, blame이 `Property.luau`인지, 활성 트윈 취소 여부, 그 뒤 같은 목표 재애니메이션.
5. 같은 부모 재대입(Claim 재삽입 경로) — `GetChildren` 순서·`task.wait()` 뒤 Parent 신호 횟수.
6. 레거시 별칭의 변경 신호 교차 — `Font` 쓰기에 `FontFace` 신호 횟수, 반대 방향.
7. `Destroying` 핸들러 안에서 보이는 상태 — Parent·자식 수·자식의 Parent.
8. `Name = 5` — 숫자가 `"5"`로 바뀌는지(mock은 거부 — 엄격한 행).

### 2-E37 추가(2026-09-27, nil/None 매트릭스가 낸 다섯)

1. R1 — State가 `nil`/`None`을 `Text`·`TextTransparency`·`BackgroundColor3`에 내놓을 때의 엔진 에러 문구·blame 줄, 그 뒤 정상 값이 다시 쓰이는지.
2. R2 — 객체 참조(`NextSelectionUp`/`Adornee`)를 quad 경로의 State `nil`로 해제하는 동작(Q33은 사용자의 `Part0` 읽기 실측에만 기댔음).
3. R3 — `q.Out`·`OnChange`가 걸린 객체 참조의 대상이 파괴될 때 변경 신호가 `nil`로 오는지(Q127).
4. R4 — Animate가 걸린 프로퍼티에 `nil` 발행, 처음부터 `nil`인 State에 Animate를 걸 때 생성 줄에서 던지는지.
5. R5 — `nil` 대입을 엔진이 기본값 리셋으로 해석하는 프로퍼티가 있는지(quad엔 기본값 복원 경로가 없음).

### 2-E48 추가(2026-09-27, Claim 트리 퍼저가 낸 넷)

1. `newMapperClass("GuiObject")` 같은 추상 클래스 매퍼가 자식 `IsA`를 통과하는가, 루트에서는(E6-2에서 열린 것과 같음).
2. `FindFirstChild`에 숫자 키 `1`이 `"1"`로 변환되는가, `true`/`nil` 키의 원시 에러(1패스라 claim은 없음).
3. 이름 `""`·`" "`·`"a.b"`의 정확 일치 조회.
4. 직접 자식 1000+ 프리팹의 Claim 시간(mock 16ms — 1패스가 자식 수의 제곱).

### 2-E50 추가(2026-09-27, 파괴 순서 퍼저가 낸 셋 — Q139)

1. Immediate `SignalBehavior`에서 부모의 엔진 연결이 끊기는 시점이 자손의 Destroying 발화보다 앞인지 뒤인지(core/05 32 "같은 호스트" 범위가 이 답에 달림).
2. Destroying 발화 순서(부모 먼저인지·형제 순서)와 핸들러가 던질 때 `Destroy`가 끝까지 도는지.
3. 파괴 중인 인스턴스에 Destroying 핸들러 안에서 자식을 붙이면(거부/함께 파괴/잔존).

### 2-E51 추가(2026-09-27, Tag/Attr 퍼저가 낸 넷)

1. `CollectionService` 태그 이름 규칙(공백·`RBX` 접두·100자 초과·`\0`)과 거부될 때 에러가 나는 위치(quad는 `""`만 막음).
2. `SetAttribute` 이름 규칙 거부가 Q140의 영구 잠김으로 실제로 이어지는지.
3. Destroy된 인스턴스가 `CollectionService` 태그 목록에서 빠지는지(E16 미완과 같음).
4. 같은 파동에서 여러 자리가 내는 `addTag`/`removeTag` 호출 순서.

### 2-E44·E54·E55·E60 추가(2026-09-27 v4 교차 검토가 누락 지적)

1. (E44, Q135) 반영 프로퍼티 문자 키에 `Ref`를 두었을 때 엔진 대입 에러 문구·blame(`Size = ref` — mock은 조용히 대입).
2. (E54, Q142) 같은 시각 `task.delay` 둘의 발화 순서(창 끝과 새 신호가 같은 시각), `Time = 0`의 재개점.
3. (E55, Q146) Tween `Started`가 던진 뒤 다음 값 전에 철거가 오면 NOOP 표식 때문에 취소가 되는지.
4. (E60, Q147) `SetAttribute`에 숫자 이름(`1`)·테이블 값을 넣었을 때의 엔진 거동.

## 3. HUMAN_TODO 편입 제안 (결정은 메인)

- **1절 다섯 항목(float32·프레임당 신호·같은 프레임 순서·b2 통지·IsA 상속)은 이미 서로 얽혀 있어(§0 "문항 사이 의존" 절) 기존 C 섹션 스타일대로 "Tween 실기기 프로브 팩" 하나로 묶는 게 자연스럽다** — 기존 프로브 팩 형식(`.claude/audit/studio-editor-probe-2026-09-26/`처럼 `rojo serve` + 관측표)과 같은 모양, 결과 하나가 Q78·Q81·Q91·Q97·Q99 다섯 문항의 처방을 동시에 좌우한다.
- **2절 중 "수명/GC" 성격 넷**(RBXScriptConnection GC, Immediate 파동 중 bind, Ref/Observer 자리 파동 중 교체, 무부모 claim 트리 GC)은 별도의 작은 프로브 팩으로 묶을 만하다 — 전부 GC 타이밍이 걸려 있어 같은 세션에서 확인하는 게 효율적.
- **2절 중 "엔진 API 규칙" 성격의 나머지**(FindFirstChild 키·SetAttribute/Tag 이름 규칙·IsA 하위 클래스·CollectionService 태그 잔존·Destroying 순서·Clone Attr/Tag·LocalScript Permits.Write)는 기존 `HUMAN_TODO.md` 18-C(실기기 목록)에 개별 항목으로 추가하는 것이 맞아 보인다 — 이미 그 섹션이 "결과만 알려 주면 문장 확정은 에이전트가" 형식으로 개별 나열 중이라 성격이 같다.
- **task.delay/시간 op 셋**(재개 시점·`math.huge`·실행 중 취소)은 Q100 결정 자체를 막지 않으므로 낮은 우선도 — 위 GC 팩과 같이 돌리거나 별도로 뒤로 미뤄도 무방.
- **나머지 개별 항목**(RemoteEvent 실 타이밍, 다른 사본 State 엔진 에러, `OnDestroyed` 순서, debug 동률 경고 출력, `table.sort` yield, CanvasPosition 클램핑, 엔진 쪽 취소 후 PlaybackState, 별칭 우선순위, UIDragDetector/스크롤 간섭)은 각자 독립된 시나리오라 하나의 프로브 팩으로 묶기 어렵다 — 개별 항목으로 유지하거나, 우선순위가 낮은 것들은 "언젠가" 절로 미뤄도 될 후보.

## 미완

- §4 본문 전수는 안 읽었다(§0 표 + §1 H-엔트리 + §2 확인만 절 + 해당 Q들의 §4 상세 문단은 읽었지만, 표에 없는 Q73/Q74/Q76/Q77/Q90의 §4 전체 문단 등 일부는 grep 매칭 문단만 발췌해 읽음 — 문맥 손실 가능성 낮음, 실기기 키워드 기준 전수는 확인함).
- Q100·Q103·Q105 등 "묶음 8/9"의 세부는 실기기 후보가 없어 표에서 뺐다(확인함, 누락 아님).
- 이 초안은 새 이름·ID를 만들지 않았고 `HUMAN_TODO.md`·`docs/`·`.claude/base/`를 고치지 않았다.
