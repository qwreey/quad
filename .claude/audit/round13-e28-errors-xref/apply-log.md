# E28 (a) 반영 로그 (2026-09-27, 편집자 opus, HEAD `789b54c5` 워킹트리)

형식: `id | 파일:절 줄 | 무엇을 어떻게(전→후 요지) | 근거 | 반영/미반영`. 파일은 `docs/reference/errors/` 기준(범위 밖은 경로 전체). 코드·스펙·`.claude/` 기존 문서 무변경.

| id | 파일:줄 | 전→후 요지 | 근거 | 결과 |
|---|---|---|---|---|
| Quad0018 | 01:18 | 언제 "state:Apply(blocker) 대상이 State 아님"(불가) → "`blocker:__apply(x)` 직접 호출에 State 아닌 값"; 고치려면 → `state:Apply(blocker)`로 붙이기 | Blocker.luau:114-117, State.luau:359-362(self 전달), probe A_1 `tag:Apply(blocker)`→0206 | 반영 |
| Quad0043 | 01:90 | 같은 방식(`factory:__apply(x)` 직접 호출) | Debounce.luau:141-144 | 반영 |
| Quad0048 | 01:130 | "둘 다 false로 줄 때" → 기본값 적용 결과 둘 다 false; Debounce는 Leading 기본 false라 `Trailing = false` 하나로도 해당, 고치려면 `Leading = true` 같이 | Debounce.luau:346-349, probe A_1 "debounce trailing=false only" | 반영 |
| Quad0123 | 01:178 | "state:Apply 대상이 State 아님" → Tag/Modifier `:Apply`에 넘기거나 콤비네이터 직접 호출; 고치려면 `state:Apply(...)`로만 | Operator.luau:83-86, Tag.luau:190-197, Modifier/init.luau:183-190, probe A_1·A_2 | 반영 |
| Quad0185 | 01:266 | Operator `Alternative` 기본값·`Indexed` 읽은 값이 Modifier일 때도 추가(메시지는 Compute라 말함), 고치려면에 Operator 경우 | State.luau:207-214, probe A_2 | 반영 |
| Quad0192 | 01:322 | 언제에 "유일 호출자 Source 설치가 바로 앞에서 State 설치 → 도달 없음 [2026-09-27 실측]", 고치려면 → Quad0004 꼴 "(문서 미정 — 현재 도달 경로가 없습니다)" | State.luau:375-379, Source.luau:41-46, grep `State.implFor` 호출자 1곳 | 반영 |
| Quad0198 | 01:370 | "(또는 `:Of`가 만든 필드)" 삭제 → 생성자에서만, `:Of`는 새 Source를 만들 뿐 | Store.luau:92-99·124-130 | 반영 |
| Quad0020 | 02:18 | "공개 함수" → 부기 함수 여섯 이름 명시, `claimOwnerAt`=0158·`releaseOwner`=0162 | Bookkeeping.luau:64-66·71·109·176·333·375·410, Slot/Owner.luau:44·66 | 반영 |
| Quad0022 | 02:34 | `setOffsetSource`도 내부 `getOffsetAt`로 같은 메시지(부르지 않은 함수 이름) 추가; 고치려면 "setLength/setOffsetSource로 등록" → 등록은 `setLength`/`setEmpty`뿐, `setOffsetSource`는 앞 위치 조회 | Bookkeeping.luau:186-204·393·348-349, probe B_1 "setOffsetSource pos3 fresh owner" | 반영 |
| Quad0229 | 02:66 | 언제 끝에 "[2026-09-27 실측] 부기 차단기가 켜진 동안에만 보임, 밖에선 재계산이 0023/0024로 먼저" | probe B_1 "getOffsetAt hole/hole2"(→0023)·"hole3"(차단기 On → 0229) | 반영 |
| Quad0053 | 02:106 | "콜론 형태도 같은 함수(트리거)" → 콜론 형태는 self가 첫 인자라 나지 않음 | Modifier/init.luau:213-217, probe B_1 "Overridden colon" true | 반영 |
| Quad0055 | 02:122 | 고치려면 "`:As(name)`을 대신" 제거 → `:As(name)`도 등록 검사를 해 Quad0052(메시지 힌트는 조상 검사 우회일 뿐) | Modifier/init.luau:203-204·247-248, probe B_1 "As(name) unknown"→0052 | 반영 |
| Quad0068 | 02:226 | 문자 키만 → 배열부 밖 숫자 키(`[5] = mod`)도, 고치려면 "1부터 빈틈 없이" | Modifier/init.luau:484-498, probe B_1 "modifier at [5]" | 반영 |
| Quad0069 | 02:234 | "발화한 것을 다른 인스턴스에" → 처리된 값을 또 놓을 때(같은 props 두 자리 포함), 표시는 처리 시점(PostRef 발화 전도, 사용자 `ref:Set`만은 아님) | Dispatch/Ref.luau:50-72, probe B_1 "preref-twice-same"/"preref-userSet-then-place" | 반영 |
| Quad0076 | 02:290 | 고치려면에 흔한 원인(오타 이름·읽기 전용 프로퍼티→`q.OnChange`·`Parent`→밖에서 `inst.Parent =`) 추가, 프로바이더 확인은 "설치 전이라면"으로 | spec-capture Bogus/Parent/AbsoluteSize(quad-roblox spec.handlers), roblox/02-d.md:164-168 | 반영(힌트 문구 오도는 (c)라 미손) |
| Quad0083 | 02:340 | "메타테이블 가진 값" → + 메타테이블 없는 quad 브랜드 값(`q.AttrKey`) | Dispatch/init.luau:474-481, probe B_1 "drive AttrKey" | 반영 |
| Quad0141 | 03:18 | `q.Dispatch.process`로 0·음수 숫자 키 자리에 놓으면 같은 가드, 메시지 "number key"; drive는 0085로 먼저 막음 | Slot/Handler.luau:54-61, probe C_2 "process k=0/-2", C_1 "0141 k=0/1.5"→0085 | 반영 |
| Quad0149 | 03:82 | "initial 원소를 준 생성자" → initial 테이블을 준(빈 `{}` 포함), 거부된 CRUD는 표시 안 함; 고치려면 "인자 없는 `q.Slot()`" | Slot/init.luau:133-141·451, List.luau:215, probe C_1 "0149 empty"/"0149 after failed add" | 반영 |
| Quad0168 | 03:235 | `index < 1`(0·-1·NaN) 추가, 고치려면 "1 이상의 정수" | Slot/init.luau:163-174, probe C_1 "0168 -1/nan" | 반영 |
| Quad0169 | 03:251 | "파괴된 Slot 전반" → State가 쥔 현재값이 파괴된 Slot일 때(생성자 포함), 직접이면 0242 | Slot/init.luau:222-240, probe C_1 "raw destroyed"→0242, "state destroyed"/"ctor state destroyed"→0169 | 반영 |
| Quad0179 | 03:331 | 메시지 줄에 ZOMBIE_NOTE 꼬리를 코드 원문 그대로 붙임(안에 백틱이 있어 이중 백틱 코드 스팬) | Slot/init.luau:93·478, probe C_1 "0179" | 반영 |
| Quad0086 | 04:10 | 고치려면에 "이 에러가 난 Effect는 멈춰 이후 구독·바인딩이 0087/0088/0090, 새 Effect를" | Effect.luau:112-119(주석 "_running stays"), probe D_1 "E dead resub/bind" | 반영 |
| Quad0087 | 04:18 | 언제에 죽은 Effect(fn 던짐·0086)는 fn 밖에서도 이 에러 [2026-09-27 실측], 고치려면에 새 Effect | Effect.luau:78-79·136, probe D_1 "E dead bind" | 반영 |
| Quad0088 | 04:26 | 같은 죽은 핸들 문장·처방 | Effect.luau:233-234 + 위 | 반영(WeakSubscribe 쪽은 코드 동일 조건으로 판정, 프로브는 Subscribe만) |
| Quad0090 | 04:50 | 같은 | Effect.luau:251-252, probe "E dead resub" | 반영 |
| Quad0089 | 04:34 | "강하게 구독돼 있을 때"만 → 강·약 무관(WeakSubscribe 두 번도); 고치려면 강→약 전환은 `:Unsubscribe()` 뒤 `:WeakSubscribe()` | LifetimeHandle.luau:99-113(`.Subscribed`만), Effect.luau:236-237, probe D_1 "E weak,weak" | 반영 |
| Quad0091 | 04:58 | 약→강 승격도 거부; 고치려면 `:WeakUnsubscribe()` 뒤 `:Subscribe()` | Effect.luau:254-255, spec.effect:209-216 | 반영 |
| Quad0098 | 04:122 | 도달 불가 표기(호출자 없음 [2026-09-27 실측]), 고치려면 Quad0004 꼴 | Effect.luau:436-439, grep `Effect.implFor` 호출자 0 | 반영 |
| Quad0109 | 04:138 | 콜백이 던진 Observer는 "실행 중" 표시가 남아(콜백은 계속 불림) 밖에서도 이 에러, 새 Observer | Observer.luau:81-90, probe D_1 "O dead bind" | 반영 |
| Quad0110 | 04:146 | 같은 | Observer.luau:125 + 위 | 반영(코드 동일 조건 판정) |
| Quad0113 | 04:170 | 같은 | probe D_1 "O dead resub" | 반영 |
| Quad0111 | 04:154 | 0089와 같은 교정 | Observer.luau:127-129, probe "O weak,weak" | 반영 |
| Quad0114 | 04:178 | 0091과 같은 교정 | Observer.luau:160-162, probe "O weak,strong" | 반영 |
| Quad0130 | 04:210 | "`ref:Wait()` 대기 코루틴에서"(불가) → `Wait(thread)`로 등록한 코루틴이 현재/바깥 코루틴일 때; 고치려면 그런 코루틴을 등록하지 말 것 | Ref/init.luau:91-101(status running/normal) | 반영 |
| Quad0136 | 04:250 | `{kind}`에서 `Ref` 제외 — 평범한 Ref는 State/Store 경유 숫자 키도 정상 처리 | Ref/init.luau:285-291(Ref 가드는 PreRef/PostRef 제외), spec.refhandlers:75-82 | 반영 |
| Quad0002 | 05:18 | "서로 다른 AttrKey 객체" → 두 주인; 흔한 경로는 같은 이름 그룹 `q.Attr` 둘 또는 그룹+`[q.AttrKey]`(그룹은 이름별 전용 키), 고치려면 `q.Attr.Overridden`으로 합치기 | Attr/Key.luau:106-112, Attr/init.luau:237-244, probe E_1 "0002 gg"; 그룹+AttrKey는 코드 근거만(프로브 없음) | 반영 |
| Quad0003 | 05:26 | "닿는 호출 없음" → 직접 대입 `store[""] = q.Source(2)` 뒤 `q.Attr(store)`로 닿음 [2026-09-27 실측]; 고치려면 생성자/`:Of`로 | Attr/init.luau:95-99, probe E_1 "0003", core/04-store.md:156 | 반영 |
| Quad0237 | 05:210 | "(브랜드가 아닌 커스텀 메타테이블)" → 메타테이블 있으면 State·Attr 포함(`q.Tag(state)`도), 무메타 브랜드는 0200 | Tag.luau:100-105, probe E_2 "0237 state/attr" | 반영 |
| Quad0027 | 06:18 | 한 Claim 트리 두 자리 같은 디스크립터도 | Claim.luau:97-99(`seen[desc]`), probe E_3 | 반영 |
| Quad0108 | 06:122 | 고치려면 "`mock.installLifetime`"(배포 안 됨) → 자기 프로바이더 `quad:UseProvider` + how-to/06 링크 | how-to/06-headless-testing.md §3 | 반영 |
| Quad0220 | 07:50 | "자기 조상의 자리" → "자기 자손의 자리"(호스트에서 조상 사슬을 올라가며 그 Instance를 만나는지) | quad-roblox Handlers/InstanceChild.luau:73-79 | 반영 |
| Quad0226 | 07:98 | 직접 호출만 → `Dispatch.process`로 미claim Instance에 Effect 등을 놓거나 `holdLifetime` 직접 호출도(메시지는 bindLifetime), 고치려면 밖 Instance는 `q.Claim` 먼저 | quad-roblox LifetimeHandle.luau:125-136, probe F_1 "effect-on-unclaimed"/"holdLifetime-direct" | 반영 |
| (범위 밖) isClaimed | extend/01-backend-provider-contract.md:105 | "`Destroying` 연결" → nativeClaim이 만든 `ClassName` 변경 시그널 `gcconn`(파괴 시 엔진이 끊음) | quad-roblox LifetimeHandle.luau:77-80·94-96 | 반영 |
| (범위 밖) Quad0063 | roblox/03-d-modifier.md:9 | "런타임 drive에서 0076/0063" → 이름·값은 drive(0076 등), 함수 값은 테이블로 Modifier를 만드는 순간 0063 | Modifier/init.luau:384-388(생성자 필드 루프), spec-capture spec.modifier | 반영 |
| (범위 밖) WeakSubscribe 에러 줄 | core/05-observer-effect.md:~279 | `effect:WeakSubscribe()` 절에 **에러** 줄 추가: 0089 / 0230 / 0088(Subscribe 절 형식) | Effect.luau:233-237 | 반영 |
| (짝) Debounce 옵션 | sugar/03-debounce-throttle.md:95 | "둘 다 false로 주면" → 기본값 적용 결과; Debounce는 `Trailing = false` 하나로도, `Leading = true`를 같이 | Debounce.luau:346-349 | 반영 |

미반영: 없음. 단, 확신 제한 표시 둘 — Quad0002의 "그룹 + `[q.AttrKey]`" 경로는 코드 근거만(프로브는 그룹 대 그룹만), Quad0088/Quad0110 죽은 핸들 문장은 프로브가 Subscribe 쪽만 돌렸고 WeakSubscribe 쪽은 같은 `isRunning`/`_running` 조건으로 판정.
