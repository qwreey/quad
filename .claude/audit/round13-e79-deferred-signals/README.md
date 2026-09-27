# E79 — Deferred 시그널 배달 심(shim)으로 본 OnChange·q.Out·이벤트·Debounce·Destroy·Slot·Tween (2026-09-27)

**주의: 여기 결과는 전부 Roblox `Workspace.SignalBehavior = Deferred`를 흉내 낸 CLI 심의 실측이지 Roblox 실측이 아니다.**
`quad-base/test/mock.luau`는 고치지 않았다 — 실행 시점에 mock `Signal` 메타테이블의 `Connect`/`Fire`와 mock 인스턴스
프록시의 `__newindex`를 덮어 쓰는 방식이다. 요구 경로는 `quad-roblox/luau_packages` 한 벌(`typing-limits.md` 8.34).

실행: 레포 루트에서 `./scripts/relink.sh` 뒤 `mise exec -- luau .claude/audit/round13-e79-deferred-signals/probe.luau`.

## 파일

| 파일 | 내용 |
|---|---|
| `env.luau` | 환경 + 심. 모드 셋: `mock`(mock 그대로 — 동기, 같은 값에도 발화), `imm`(동기 + 엔진식 같은 값 무발화 — Immediate 대역), `def`(같은 값 무발화 + 모든 `Fire`를 연결별 큐 항목으로 적재, `S.flush()`가 FIFO로 비움 — flush 중 새 발화는 큐 뒤에 붙어 같은 flush에서 처리). 배달 규칙: 명시적 `:Disconnect()`된 연결의 대기분은 버림(m10 Studio 실측), `Destroy`로 끊긴 연결의 대기분은 1회 배달(`H-291`, 토글 `S.deliverAfterDestroy`), 리스너 에러는 격리 기록. 타이머 콜백은 재개점이라 끝에 flush. quad-roblox 프로바이더 + mock 가상 시계 타이머 |
| `probe.luau` | 축 일곱(1a~1h, 2, 3, 4a~4d, 5a~5c, 6, 7a~7g)을 세 모드로 각각 실행 |
| `out-probe.txt` | 위 실행 출력(exit 0) |

## 결과 표 (동기 대 지연)

| 축 | mock / imm (동기) | def (지연 심) | 판정 |
|---|---|---|---|
| 1a `q.Out` 마운트 + 한 프레임에 "a","ab" 타이핑 | emits 3 `[quad,a,ab]`, src=ab | 마운트 메아리 배달 1(가드로 건너뜀), emits 2 `[quad,ab]`, src=ab | 수렴, 마지막 입력 유실 없음 — 문서 두 모드 모두 맞음 |
| 1b 대문자 변환 OnChange → 같은 Source | mock: C stack overflow(알려짐), imm: emits 4 `[A,A,AB,AB]` | emits 3 `[AB,AB,AB]`, 배달 3 | 수렴 |
| 1c TextBox 둘이 같은 Source에 in+out, 한 프레임에 b1="one" 뒤 b2="two" | 최종 two | **최종 one — 뒤의 엔진 쓰기 유실** | 동작 다름(발견 1) |
| 1d 타이핑 → 프로그램 Set / 그 역 | reset / progX | 같음 | 같음 |
| 1e 멱등 아닌 OnChange(v.."!") | 마운트 중 src="!"·Text="" 갈라짐(같은 키 재진입 UB), 마운트 뒤 입력 → C stack overflow(번호 없음) | 마운트 뒤 첫 flush에서 사슬이 콜백 자체 상한 300까지 한 flush 안에서 돎(maxQueue 1) | 사용자 코드 버그; 실기기 재진입 상한 후보 |
| 1f 가드 없는 OnChange, 한 프레임에 쓰기 셋 | emits `[1,2,3]` | emits `[3,3,3]` | 횟수 같음, 값은 전부 최종값 — how-to 03 §5 서술은 두 모드 모두 맞음 |
| 1g 되돌리기 버튼 Activated 대기 뒤 같은 프레임 키 입력 "ab" | name=ab | **name=quad — 키 입력 유실** | 동작 다름(발견 1) |
| 1h OnChange 콜백이 "bad"에서 던짐 | `src:Set("bad")`가 그 에러로 던짐(Q149 경로) | Set은 통과, 에러는 리스너 격리 | Q149 보강(발견 4) |
| 2 `Text = src:Compute(앞 3자)` + `q.Out(src)` | 마운트 직후 src=hel; `Set("world!!")` 직후 src=wor | 마운트 직후 src=hello(프레임 끝에 hel); Set 직후 src=world!!(프레임 끝에 wor); 두 Set 한 프레임 emits 9 대 10 | 수렴, 프레임 안에서는 갈라져 보임(발견 2) |
| 3 Activated → Set → Text → OnChange → … 네 단 | 이벤트 안에서 Set 직후 lv1=1·lv3=1 | 한 flush에 배달 5(maxQueue 4), 이벤트 안 Set 직후 읽기 lv1=0·lv3=0 | 사슬 길이 = 한 flush, 같은 프레임 읽기는 stale(발견 2) |
| 4a/4c 지연 배달이 타이머보다 먼저 | Debounce `[ab@0.59]` / Throttle `[a@0,ab@0.3]` | 같음 | 같음 |
| 4b Debounce, 0.3 타이머 재개점이 배달보다 먼저 | `[ab@0.59]` | **`[a@0.30, ab@0.60]` — 중간값 한 번 더 통과** | 동작 다름(발견 3), 엔진 순서 미실측 |
| 4d Throttle, 타이머가 먼저 | `[a@0,ab@0.3]` | 같음 | 같음 |
| 5a Activated 콜백이 호스트 Destroy, 같은 프레임 `src:Set("y")`로 쌓인 OnChange | 동기 순서라 Set은 파괴 뒤 → OnChange 0, `[act,OnDestroyed]` | 쌓인 OnChange 둘이 파괴 뒤 1회씩 돎 → 자식 콜백의 `slot:Add`가 파괴된 호스트의 Slot에 **통과**(Length 2), `OnDestroyed`는 그 뒤(FIFO), 번호 없는 에러 없음 | 알려진 Q9 좀비 UB에 도달 경로가 늘어남(발견 5) |
| 5b 같은 것, 파괴로 끊긴 대기분은 버리는 가정 | 위와 같음 | `[act]`만 — `OnDestroyed`까지 안 돎 | 엔진 규칙에 민감 — 실기기 후보 |
| 5c 대조: 동기 직접 경로 `host:Destroy()` 뒤 `slot:Add` | 통과, Frame이 시체 밑에 claim된 채 | 같음 | 지연과 무관한 기존 성질 |
| 6 `:List` updateFn이 만든 TextLabel의 OnChange가 data를 Set | 마운트 중 동기 발화 → 에러 없이 **유실**(Length 1, data 2) | 마운트 뒤 배달 → 정상 재조정(Length 2) | 동기 쪽은 core/06 399 UB(발견 6), 지연은 합법적으로 창 밖 |
| 7a 자연 종료 → flush | `[S,C]` 즉시 | flush 전 `[S]`, 뒤 `[S,C]` | 문서 맞음 |
| 7b 자연 종료 뒤 같은 프레임 호스트 Destroy | `[S,C]` | `[S]` — `isClaimed` 거짓이라 무시 | `H-594` 지연에서도 성립 |
| 7c Destroy 뒤 자연 종료 | `[S]` | `[S]` | 같음 |
| 7d 자연 종료 뒤 같은 프레임 새 Tween(지연 창 경로) | `[S,C,S]` | `[S,C,S]`(늦은 엔진 통지는 끊긴 연결이라 버려짐, 중복 C 없음) | 같음 |
| 7e 도는 중 교체 | `[S,X,S]` | 같음(엔진 Cancelled 통지 버려짐) | 같음 |
| 7f Completed 안에서 다음 Tween | `[S,X,C30,S40]` | 같음 | 같음 |
| 7g 7b + 파괴로 끊긴 대기분 버림 가정 | `[S,C]` | `[S]` | 같음 |

## 발견 (평문)

**발견 1 [LOW~MED — 동작 다름, 사용자 결정 필요] 같은 프레임 안에서 quad 쪽 쓰기가 나중에 온 엔진 쓰기를 덮어 마지막 입력이 사라진다.** OnChange 핸들러는 신호가 올 때 `inst[name]`을 다시 읽고(`quad-roblox/src/Handlers/OnChange.luau:130` `callback(inst[name])`), `q.Out`은 그 값이 `src:Get()`과 같으면 건너뛴다(같은 파일 98행). 지연 배달에서는 앞서 큐에 쌓인 콜백(버튼 `Activated`의 `name:Set("quad")`, 또는 다른 입력창의 `q.Out`)이 flush 중에 `Source`를 바꾸면 Property 핸들러가 그 자리에서 `Text`를 덮는다 — 그 프레임에 사용자가 이미 친 "ab"의 대기 배달은 덮인 값("quad")을 읽고, 그 값은 `src:Get()`과 같으니 가드가 건너뛴다. 그래서 1g에서 동기는 `ab`, 지연은 `quad`이고, 1c(같은 Source에 in+out을 건 입력창 둘)에서 동기는 뒤에 쓴 `two`, 지연은 앞에 쓴 `one`이다. 고리는 진동하지 않고 늘 수렴하지만, 수렴하는 값이 "실제 시간상 마지막 쓰기"가 아니라 "큐에서 먼저 배달된 쪽"이다. 문서: `docs/reference/roblox/05-onchange.md` 73~74행 "Deferred 신호 모드에서는 쓰기 한 번당 전달 한 번이고 값은 전달 시점에 읽힙니다"는 맞지만 이 결과를 말하지 않고, `docs/getting-started/06-flowing-back.md` 104행 "입력창에 타이핑하는 대로 … 되돌리기를 누르면 입력창도 quad로 되돌아갑니다"는 두 동작이 한 프레임에 겹치지 않는다는 전제다. quad 쪽에서 막을 방법은 사실상 없다(`GetPropertyChangedSignal`은 값을 싣지 않으니 쓰기 시점 값을 잡을 수 없다). 갈래: (a) 05-onchange `q.Out` "동작"에 한 문단 — "Deferred에서는 같은 프레임에 quad가 그 프로퍼티를 다시 쓰면 그보다 나중의 엔진 변경이 사라질 수 있다; 확정이 필요하면 `FocusLost`로" (지금 문서의 `FocusLost` 권고와 같은 결); (b) 엔진 성질로 보고 문서화하지 않음. 권고: 실기기에서 "클릭 입력과 텍스트 입력이 한 프레임에 이 순서로 배달되는가"를 먼저 확인한 뒤 (a).

**발견 2 [LOW — 문서가 동기를 전제한 자리] 같은 프레임 안에서는 OnChange가 먹이는 상태가 아직 옛 값이다.** 3에서 버튼 `Activated` 안에서 `count:Set` 직후 `btn.Text`는 이미 새 값(Property 쓰기는 두 모드 모두 동기)이지만 OnChange가 먹이는 `lv1`/`lv3`는 동기에선 1, 지연에선 0이다. 2에서도 `Text = src:Compute(앞 3자)` + `q.Out(src)`는 동기면 `Set("world!!")` 직후 `src:Get()`이 이미 `wor`, 지연이면 프레임 끝까지 `world!!`다(최종값은 같음). 문서 중 동기를 전제한 문장: `docs/reference/roblox/05-onchange.md` 84행 예제 주석 `table.insert(seen, v) -- seen[1] == "a"` — 생성 직후 읽으면 Deferred에서는 `seen`이 비어 있다(프레임 끝에 채워짐). `docs/how-to/08-migrating-from-v1.md` 332행 HTML 주석 "생성 직후 이미 1회 호출됐고"는 mock 실측 기록이라 공개 문장은 아니다. 갈래: (a) 84행 주석에 "(Deferred면 이 프레임 끝에)"를 붙인다; (b) 그대로. 권고 (a), 결정 불필요한 문서 손질에 가깝다.

**발견 3 [LOW — 엔진 순서 미실측] Debounce 타이머의 재개점이 입력 신호 배달보다 먼저 돌면 중간값이 한 번 더 통과한다.** 4b에서 "a"(0초)·"ab"(0.29초) 입력 뒤 0.3초 타이머가 "ab" 배달보다 먼저 재개되면 게이트가 그때의 최신 상류값 "a"를 내보내고, 뒤이은 배달이 창을 새로 열어 0.6초에 "ab"를 또 낸다(동기는 0.59초 "ab" 한 번). `docs/reference/sugar/03-debounce-throttle.md`가 적은 문구(통과 값은 통과 순간의 최신값)통과 값은 통과 순간의 최신값은 문자 그대로는 맞다(그 순간 상류는 아직 "a"). Throttle(4d)은 차이 없음. 엔진이 입력 처리 뒤 지연 큐를 먼저 비우고 `task.delay` 재개를 나중에 하는지가 관건이라 심으로는 판정할 수 없다. 갈래: (a) 실기기에서 순서를 재고, 타이머가 먼저인 순서가 실재하면 sugar/03에 한 줄; (b) 그대로. 권고 (a)의 실측 먼저.

**발견 4 [정보 — Q149 보강] Deferred에서는 OnChange 콜백이 던진 에러가 `Source:Set`으로 올라오는 경로 자체가 없다.** 1h에서 동기(mock·imm)는 `src:Set("bad")`가 콜백 에러로 던졌고, 지연 심은 Set이 통과하고 에러는 리스너에서 격리됐다(다음 Set 회복은 세 모드 같음). 즉 Q149가 걱정한 "Property 자리가 NOOP 표식으로 남는" 상태는 신형 기본인 Deferred에서는 엔진의 리스너 격리 여부와 무관하게 생기지 않고, Immediate에서만 엔진 격리 실측이 필요하다. 문서 변경 없음 — Q149 판단 재료.

**발견 5 [LOW — 알려진 UB의 도달 경로] Deferred에서는 호스트를 파괴한 콜백 뒤에 같은 프레임에 쌓인 형제 콜백이 시체 위에서 한 번 돈다.** 5a에서 `Activated`가 `btn:Destroy()`를 부른 뒤, 같은 프레임의 `src:Set("y")`로 쌓였던 `btn`과 그 자식 TextLabel의 OnChange가 파괴 뒤에 각각 1회 배달됐고(심은 `H-291`의 "Destroy가 연결을 끊어도 큐잉된 발화는 1회"를 모든 시그널에 적용), 자식 콜백의 `slot:Add(D.Frame{})`가 파괴된 호스트의 Slot에 에러 없이 들어가 claim된 Frame이 시체 밑에 붙었다(Length 2). 같은 일은 지연과 무관하게 동기 직접 경로(5c)에서도 일어나므로 새 결함이 아니라 round3 Q9(부모 Destroy 뒤 Slot 좀비 — 메시지+UB) 범위다. 번호 없는 에러는 나오지 않았고, `OnDestroyed`는 쌓인 OnChange들 뒤에 돌았다. 문서 쪽 빈칸: 이벤트·OnChange 콜백이 "파괴 뒤에도 이미 쌓인 것은 한 번 돌 수 있다"는 말이 레퍼런스 어디에도 없다(`core/05` 32행의 "기본 Deferred 설정에선 파괴 즉시"는 Observer 이야기). 5b(파괴로 끊긴 대기분을 버리는 가정)에서는 OnChange도 `OnDestroyed`도 안 돌아 결과가 엔진 규칙에 민감하다. 갈래: (a) 02-d 이벤트 절·05-onchange에 한 줄(Deferred에서 이미 쌓인 콜백은 파괴 뒤에도 1회 — 콜백 안에서 호스트 생존을 가정하지 말 것); (b) 그대로. 권고: 실기기에서 속성 변경 신호·일반 이벤트의 "파괴 전에 쌓인 대기분" 배달 여부를 먼저 확인.

**발견 6 [LOW — Immediate 한정 UB, 문서 문장 범위] `:List` updateFn 안에서 만든 원소의 OnChange가 동기로 발화해 data를 Set하면 조용히 유실된다.** 6에서 동기는 에러 없이 `data`는 두 항목, `outer.Length`는 1로 남았다(다음 무관한 Set에서 치유). 이것은 `docs/reference/core/06-slot.md` 399행 "updateFn이 이 Slot의 data State를 다시 :Set 하는 재진입은 정의되지 않은 동작" 그대로이고(Q73 계열의 "설치 발화 창" 유실과 같은 모양), Q52 게이트(`Quad0167`)는 조상 CRUD가 아니라 걸리지 않는다. Deferred에서는 OnChange가 마운트 뒤에 배달되어 정상 재조정(Length 2)되므로 지연은 창을 합법적으로 밖으로 옮긴다. 문서는 "updateFn이 Set"만 적어 "updateFn이 만든 원소의 시그널 콜백이 Immediate에서 동기로 Set"도 같은 UB라는 점이 드러나지 않는다. 갈래: (a) 399행에 "(Immediate 시그널 설정에서 updateFn 안에서 만든 원소의 `OnChange`·이벤트 콜백이 그 자리에서 발화해 Set하는 것도 같다)"; (b) 그대로. 권고 (a) 가벼운 문서화 — Q73 결정과 같이.

## 확인만 한 것

- 왕복 수렴: 1a·1b·2 모두 지연에서도 수렴, 진동 없음. 고리를 끊는 것은 엔진의 같은 값 무발화(심에서 재현)이고 `q.Out` 가드는 메아리 건너뛰기 — 05-onchange "동작"·06-flowing-back §3 서술은 두 모드 모두 맞다. 한 프레임에 여러 키 입력은 배달 수만큼 콜백이 돌지만 전부 최종값을 읽어 `q.Out`에서는 emit 하나로 합쳐진다(마지막 입력 유실 없음 — 발견 1의 끼어들기가 없을 때).
- 05-onchange 73~74행 "쓰기 한 번당 전달 한 번, 값은 전달 시점" — 심에서 그대로(1f `[3,3,3]`, m10 Studio 실측과 같은 모양).
- how-to 03 §5 "CanvasPosition은 한 프레임에도 여러 번 바뀔 수 있고, 바뀔 때마다 … 돕니다" — 횟수는 두 모드 같음(값만 지연에서 전부 최종값).
- 이벤트 → Set → Property → OnChange 사슬은 지연에서 한 flush 안에 다 돈다(3: 배달 5, 큐 최대 4). 이벤트 콜백 자체도 지연되므로 발화 직후엔 아무 것도 안 바뀐 상태.
- Throttle은 배달·타이머 순서와 무관하게 동기와 같다(4c·4d).
- Tween 콜백(7a~7g): `H-594`의 `isClaimed` 검사는 지연 배달 시점에도 파괴된 인스턴스를 거짓으로 본다(gcconn이 `Destroy`에서 동기로 끊기므로) — roblox/06 266행 "도는 사이 파괴됐으면 불리지 않습니다"는 두 모드 모두 맞다. 지연 창 경로(7d)에서 늦은 엔진 통지는 quad가 이미 끊은 연결이라 버려져 `Completed` 중복 없음; 교체 시 엔진 `Cancelled` 통지(7e)도 버려짐; `Completed` 안의 다음 Tween(7f) 정상.
- 1e: 동기에서 초기 쓰기 중 같은 Source를 `Set`하면 src와 Text가 갈라진다(같은 키 재진입 UB — `H-589`/dispatch-core Q5 (a) 그대로), 지연에서는 그 창이 없다. 멱등 아닌 되쓰기는 동기에서 번호 없는 C stack overflow, 지연 심에서는 한 flush 안의 끝없는 사슬 — 사용자 코드 결함이고 문서(05-onchange 주의 상자) 범위.
- 번호 없는 quad 에러는 어느 축에서도 새로 나오지 않았다(1b mock·1e 동기의 C stack overflow는 사용자 코드 무한 재귀).

## 미완

- **이건 심이다.** 실제 Roblox Deferred의 세부(리스너 순서, 재진입 깊이 상한, 파괴 전 쌓인 일반 신호의 배달 여부, `task.delay` 재개와 지연 큐의 상대 순서, 입력 이벤트와 텍스트 변경의 큐 순서)는 재지 않았다. 리스너 순서는 mock의 역순 그대로 뒀다(변수 하나만 바꾸려고).
- Roblox Deferred에는 같은 신호의 재진입 깊이 상한(기억상 10, "Maximum event re-entrancy depth exceeded")이 있는 것으로 알지만 심은 모델링하지 않았다 — 1e의 지연 결과(한 flush 300)는 엔진에서는 상한 에러로 끊길 가능성이 크다.
- `Ref:Wait`·`PreRef`/`PostRef`·생명주기 훅 `OnCreated`/`OnRendered` 순서, `ChildAdded`류 이벤트, Attr/Tag 신호, 퍼저(무작위 조합)는 하지 않았다 — 축 단위 프로브만.
- 파괴로 끊긴 대기분 규칙은 두 가정(5a/5b, 7b/7g)만 돌렸다.

## 실기기 확인 후보 (HUMAN_TODO 초안용)

1. 한 프레임 안에서 버튼 클릭(`Activated`)과 TextBox 키 입력의 `GetPropertyChangedSignal("Text")`가 어떤 순서로 배달되는가, 그리고 클릭 콜백이 `Text`를 다시 쓰면 그 프레임의 키 입력이 사라지는가(발견 1).
2. 입력으로 난 속성 변경 신호의 지연 배달과 `task.delay` 타이머 재개 중 어느 쪽이 먼저인가(발견 3).
3. `Destroy()` 전에 쌓인 `GetPropertyChangedSignal`·일반 이벤트(`Activated`) 대기분이 파괴 뒤에 배달되는가(`H-291`은 `Destroying` 쪽 실측 — 발견 5·5b·7g의 민감도).
4. Deferred에서 OnChange 콜백이 같은 프로퍼티를 계속 바꾸는 고리가 재진입 깊이 상한에서 끊기는가, 그때의 에러 문구(1e).
5. Immediate에서 연결 리스너가 던질 때 엔진이 격리하는가(Q149 — 발견 4로 Deferred에서는 무관해짐).
