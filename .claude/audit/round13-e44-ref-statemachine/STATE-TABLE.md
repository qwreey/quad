# E44 상태표 — Ref / PreRef / PostRef (문서 계약 → 참조 모델)

HEAD `86523a1d`. 칸마다 "문서가 정한 기대(파일:줄)" → "실측(mock, quad-roblox 핸들러 + quad-base/test/mock)".
`판정` 열: **문서** = 문서가 정하고 실측 일치 / **미정** = 문서가 정하지 않아 실측을 기록 / **오류** = 문서와 실측 불일치.
퍼저 모델 규칙은 `fuzz.luau`의 주석이 같은 줄을 인용한다.

상태: `E`(비어 있음, 안 묶임) · `F`(값 있음, 안 묶임) · `B`(살아 있는 인스턴스 자리에 묶임) · `Bd`(묶였던 인스턴스가 Destroy/dispose됨) · `W`(대기자 있음 — 다른 상태와 직교) · 일회용 `P0`(PreRef/PostRef 미소비) · `P1`(소비됨).

| # | 상태 | 이벤트 | 문서 기대 | 근거 | 실측 | 판정 |
|---|---|---|---|---|---|---|
| 1 | 전부 | `Set(v)` | Value 먼저 → Revision 변경 → 콜백 스냅샷 순회 | core/07:236-240 | 일치(퍼저 15만 op) | 문서 |
| 2 | 전부 | `Set(같은 값)` | 걸러내지 않음 — 매 `:Set`마다 Revision·콜백 | core/07:190, :240 | 발화·Revision 변경 | 문서 |
| 3 | 전부 | `Set(nil)` | 값 nil, 콜백 nil로 | core/07:236-240 | 일치 | 문서 |
| 4 | 전부 | `Set(q.None)` | (Ref는 None을 해석하지 않음 — 서술 없음) | — | None을 그대로 저장, `:Unwrap()`이 None 반환 | 미정 |
| 5 | 전부 | `Set(테이블/State/함수)` | `T` 값 그대로 | core/07:232 | 그대로 저장·전달, 묶임에 영향 없음 | 문서 |
| 6 | B | 사용자 `Set(x)` | (묶인 Ref에 직접 쓰기 — 서술 없음) | — | 값만 바뀌고 묶임 유지(`canBound` false) | 미정 |
| 7 | 전부 | `Callback(fn)` | 즉시 현재 값으로 1회 + 강한 등록 | core/07:276-277 | 일치 | 문서 |
| 8 | 전부 | `Callback(fn)` 재등록 | 집합 의미로 1개, 즉시 호출은 매번 | core/07:202, :277 | 일치(매 호출마다 즉시 1회) | 문서 |
| 9 | 전부 | `WeakCallback(fn)` | 즉시 1회, weak 키 | core/07:288 | 일치 | 문서 |
| 10 | 전부 | 강·약 둘 다 등록 | 순회는 합집합 — 1회 | core/07:218 | 1회 | 문서 |
| 11 | 전부 | `Uncallback(fn)` | 두 테이블에서 제거 | core/07:300 | 일치 | 문서 |
| 12 | 순회 중 | 콜백 안 `Uncallback(다른 fn)` | 순회 중 해제된 콜백은 건너뜀 | core/07:240 | 아직 안 불렸으면 건너뜀(순서 따라 0/1회) | 문서 |
| 13 | 순회 중 | 콜백 안 `Callback(새 fn)` | 이번 순회 불변 + 등록 즉시 1회 | core/07:240, :276 | 즉시 1회만 | 문서 |
| 14 | 순회 중 | 콜백 안 `Uncallback(f)`+`Callback(f)` | (두 규칙의 합성 — 서술 없음) | — | f가 같은 값을 **2회** 받음(재등록 즉시 1 + 스냅샷 순회 1) | 미정 |
| 15 | 순회 중 | 콜백 안 재진입 `Set` | 안쪽이 모두에게 새 값, 바깥은 멈춤, 낡은 값 없음 | core/07:242 | 일치(모든 콜백의 마지막 값 = 안쪽 값) | 문서 |
| 16 | 순회 중 | 대기자가 깨어나 재진입 `Set` | (15와 같은 규칙) | core/07:242 | 일치 | 문서 |
| 17 | 전부 | 콜백 순서 | 정해지지 않음(등록순 아님) | core/07:248 | 8개 등록 → `1 2 6 3 5 4 7 8` | 문서 |
| 18 | 순회 중 | 콜백 안 yield | UB | core/07:248 | 순회 중단(나머지 콜백 미호출 채 매달림) | 문서(UB) |
| 19 | 전부 | `Wait()` yield 가능 코루틴 | 다음 `Set`까지 대기, `self` 반환 | core/07:318-322 | 일치(반환값 = Ref, `.Value` = 새 값) | 문서 |
| 20 | F | `Wait()` | 이미 차 있어도 다음 `Set`을 기다림 | core/07:322 | 일치 | 문서 |
| 21 | 전부 | `Wait()` C 경계(`table.sort` 비교자·`__index` 안 pcall) | `Quad0134` | core/07:324, errors/04:238 | `Quad0134` | 문서 |
| 22 | 전부 | `Wait()` 메인 청크 | errors/04:238 "메인 스레드"는 `Quad0134` | errors/04:238 | CLI 메인 청크는 yield 가능 — `Quad0134` 안 남, 스크립트가 멈춤 | 오류(기존 관측 E5·E21·E38, Roblox 미실측) |
| 23 | 전부 | `Wait(123)` | `Quad0133` | core/07:326 | `Quad0133` | 문서 |
| 24 | 전부 | `Wait(thread)` 등록 | 등록만, 즉시 반환, 집합 | core/07:316, :325, :327 | 일치 | 문서 |
| 25 | W(thread=running) | `Set` | `Quad0130` | core/07:244-246 | `Quad0130` — 메인 스레드·코루틴 둘 다 | 문서 |
| 26 | W(thread=normal) | `Set` | `Quad0130`(바깥 코루틴) | core/07:244 | `Quad0130` — 두 단계 위 조상도 | 문서 |
| 27 | W(thread=running/normal) | `Set`이 던진 뒤 상태 | (서술 없음) | — | 대기자는 이미 소진(등록 풀림), Value·Revision은 새 값, 순회에서 그 뒤 콜백은 미호출 | 미정 |
| 28 | W(thread=suspended, 맨 yield) | `Set` | 소진 + `Ref`를 인자로 resume | core/07:244 | 일치, 스레드는 살아 있고 등록은 풀림 | 문서 |
| 29 | W(thread=다른 Ref의 `Wait()`에 멈춘 스레드) | `Set` | (서술 없음) | — | 그 스레드의 `r1:Wait()`가 **r1의 옛 값**으로 돌아옴, r1에는 등록이 남아 나중 `r1:Set`이 죽은 스레드 resume | 미정 |
| 30 | W(thread=dead) | `Set` | core/07 서술 없음(ref-plan:419-424는 UB·`:Set`이 에러로 올림) | ref-plan.md:419-424 | 번호 없는 `cannot resume dead coroutine`, 대기자 소진, 값은 이미 바뀜, 순회 중단 | 미정 |
| 31 | W(한 스레드를 두 Ref에 등록) | 한쪽 `Set` 뒤 다른 쪽 `Set` | (서술 없음) | — | 둘째 `Set`이 30과 같이 던짐, 그 Ref 콜백 미전달 | 미정 |
| 32 | W | 대기자 본문이 던짐 | 그 `:Set`(마운트/철거)으로 되던짐 | core/07:341 | 일치(f8 — retract 파동) | 문서 |
| 33 | E | `Unwrap` | `Quad0135` | core/07:358-360 | `Quad0135` | 문서 |
| 34 | F | `Unwrap` (`false`/None) | nil만 거부 | core/07:354 | `false`·None 통과 | 문서 |
| 35 | E/F | 숫자 키 `D.Frame{ref}` | 그 자리 처리 시점에 `Set(inst)` | core/07:91 | 일치, 해시 키(Size)보다 먼저 | 문서 |
| 36 | E/F | `D.Frame{ref, ref}` | `Quad0232` | core/07:64, errors/06:146 | `Quad0232`, Ref는 반쯤 지어진 고아에 묶인 채 | 문서 |
| 37 | B | 다른 인스턴스에 놓기 | `Quad0233` | core/07:64 | `Quad0233` | 문서 |
| 38 | B | 인스턴스 `Destroy` | Ref는 반응 안 함(값 유지) | core/07:92 | 값 유지, **묶임 풀림**(재놓기 가능) | 문서 |
| 39 | B | 인스턴스 `q.dispose` | 묶임 풀림(core/07:70), 값은? | core/07:70, :92 | 값 유지, 묶임 풀림 | 미정(값 쪽) |
| 40 | Bd | 재놓기 | 재사용 가능 | core/07:70 | 가능 | 문서 |
| 41 | B(State 자리) | `st:Set(다른 Ref)` | 옛 Ref `Set(nil)`, 새 Ref `Set(inst)` | core/07:91, ref-plan.md:511 | 일치 | 문서 |
| 42 | B(State 자리) | `st:Set(None)` | 옛 Ref `Set(nil)` | core/07:91 | 일치 | 문서 |
| 43 | B(State 자리) | `st:Set(같은 Ref)` | 재통지 없음(dedup) | ref-plan.md:511- | 0회 | 문서 |
| 44 | B(State 자리) | `st:Set(b)` — b가 다른 곳에 묶임 | `Quad0233` | core/07:64 | `Quad0233`(st:Set 줄), 옛 Ref는 이미 `Set(nil)`·풀림, 자리는 이후 정상 복구 | 문서 + 부분 상태 미정 |
| 45 | B(State 자리) | 자리 인스턴스 Destroy 뒤 `st:Set(b)` | (서술 없음) | — | 무동작 — 옛 Ref는 파괴된 인스턴스를 쥔 채, b는 안 채워짐, 에러 없음 | 미정 |
| 46 | B | 리터럴 + State 자리 같은 인스턴스 | `Quad0232` | core/07:64 | `Quad0232`(st:Set 줄) | 문서 |
| 47 | 전부 | 문자 키(반영 아닌 이름 `Foo`, `Parent`) | `Quad0137` | core/07:53, :58, :61 | `Quad0137` | 문서 |
| 48 | 전부 | 문자 키 = 그 클래스의 반영 프로퍼티(`Name`/`Size`/`Visible`) | core/07:61 "어느 이름이든" `Quad0137`; :53 PreRef/PostRef "전용 가드가 그 자리에서 던집니다" | core/07:53, :61, errors/04:258-262 | Property 핸들러가 먼저 잡아 **엔진 대입**: mock `Name` → 번호 없는 `Property.luau:266: Name must be a string`, `Size`/`Visible` → **에러 없이 Ref 테이블이 프로퍼티에 들어감**, PostRef 미소비 | 오류 |
| 49 | 전부 | 문자 키 = 이벤트(`Activated`) | (서술 없음 — 가드 문구 기대) | core/07:61 | `Quad0218 Event: handler … must be a function (got table)` | 오류(48과 같은 문장) |
| 50 | 전부 | Modifier 필드 | `Quad0064` | core/07:60 | `Quad0064` | 문서 |
| 51 | 전부 | `q.dispose(ref)` | 요소도 Slot도 아님 → `Quad0180` | core/10:117 | `Quad0180` | 문서 |
| 52 | P0 | PreRef 숫자 키 | pre-pass에서 위치 무관 먼저 | core/07:117 | 일치(pre → Ref → post) | 문서 |
| 53 | P0 | PostRef 숫자 키 | 숫자·문자 키 전부 뒤 | core/07:146 | 일치 | 문서 |
| 54 | P1 | 다시 놓기 | `Quad0069` | core/07:68, errors/02:234 | `Quad0069` | 문서 |
| 55 | P0 | 사용자 `Set` 뒤 놓기 | 사용자 `Set`만 한 값은 해당 없음 | errors/02:236 | 정상 발화 | 문서 |
| 56 | P0 | `State<PreRef/PostRef>` 자리 | `Quad0136`, 소비 안 됨 | core/07:56, :58 | `Quad0136`, 재사용 가능 | 문서 |
| 57 | P0(PostRef) | pre-pass 뒤 본문이 던짐 | 발화 없이 소진 | core/07:70, sugar/05 캐비엇 | 소진(`Quad0069`) — **던진 항목보다 뒤 자리의 PostRef도** | 문서 + 문구 오해 소지(아래 발견) |
| 58 | P0(PostRef) | 앞 자리 PreRef 콜백이 pre-pass에서 던짐 | (서술 없음) | — | 그 뒤 자리 PostRef는 **미소비**(재사용 가능), 앞 자리는 소비 | 미정 |
| 59 | P0(PostRef) | 앞 PostRef 콜백이 던짐 | (서술 없음) | — | 뒤 PostRef는 소비됐으나 미발화 | 미정 |
| 60 | P0 | `Fallback` 경계 | 소진 | sugar/05 캐비엇 | 소진 | 문서 |
| 61 | P0 | PreRef 콜백이 인스턴스 Destroy | (서술 없음) | — | drive 완주, PostRef가 파괴된 인스턴스로 발화, `D.Frame`이 파괴된 인스턴스 반환(E5와 같은 관측) | 미정 |
| 62 | 훅 | `OnCreated` 콜백 시점·인자 | 무엇보다 먼저, `inst` non-nil, `(inst, ref)` | sugar/04:25, :31 | 일치(Size 미설정·자식 0) | 문서 |
| 63 | 훅 | `OnRendered` | 서브트리·프로퍼티 뒤, 부모 부착 무보장 | sugar/04:26, :75 | 일치(리터럴 중첩 자식은 Parent nil, Slot 자식도 nil) | 문서 |
| 64 | 훅 | 종류 섞임 순서 | OnCreated들 → … → OnRendered들, 같은 종류는 숫자 키 순 | sugar/04:30 | 일치 | 문서 |
| 65 | 훅 | `OnDestroyed` 순서 | 미정, mock은 역순 | sugar/04:30 | 역순(D2 D1) | 문서 |
| 66 | 훅 | `OnDestroyed` State 자리 떼기/되꽂기/죽음 | 떼면 0, 죽으면 1 | sugar/04:90 | 0 → 1 | 문서 |
| 67 | 훅 | `OnDestroyed` + `q.dispose` | 죽을 때 1회 | sugar/04:27 | 1 | 문서 |
| 68 | 훅 | 훅 재사용 / State 자리 / 비함수 | `Quad0069` / `Quad0136` / `Quad0101` | sugar/04:32, core/07:68 | 일치 | 문서 |
| 69 | 훅 | 사용자가 훅 PreRef에 `Set(nil)` | nil 호출은 가드가 거름 | sugar/04:31 | 걸러짐 | 문서 |

칸 수 **69**, 판정 — 문서 54(UB 1, 44·57 포함) · 미정 12(4·6·14·27·29·30·31·39·45·58·59·61; 44의 부분 상태는 문서 쪽에 셈) · 오류 3(22·48·49, 22는 기존 관측).

