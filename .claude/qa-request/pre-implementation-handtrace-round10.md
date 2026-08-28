# 구현 전 손 트레이싱 **10라운드** — 발견 보고 + 배치 결정 문항지

> **이 파일이 무엇인가**: **[2026-08-28 신설]** 9라운드 후속(`H-143`~`H-146`)
> 반영 뒤 `/code-review high`가 낸 판단 대기 셋(`H-147`~`H-149`)을 씨앗으로,
> 신선한 탐사자가 **M2~M8 전 표면을 광범위하게** 손 트레이싱·실측한 결과를
> 여기 이어 쓴다(`H-150`~). 지시서는 `-round10-brief.md`. **사용자는 §4 표를
> 위에서 아래로 읽고 갈래만 회신한다**(배치). 결정이 나면 `-round10-followup.md`를
> 새로 만들고 `base/`에 반영한다 — **이 파일은 발견 당시의 기록**이라 각 항목의
> "갈래"는 선택 전 목록이니 반영 뒤엔 그대로 믿지 말 것.
>
> 상태: **[2026-08-28] 탐사 완료(발견 `H-150`~`H-157`, 🔴 0 · 🟡 5 · 🟢 3, §4 문항 7) → 같은 날 사용자와 대화형으로 전량 결정·반영 — 결정의 소스는 `-round10-followup.md`.** 후속 `H-158`~`H-162`도 같은 날 확정(`H-159`는 `/code-review` 권고 (a) `Refresh` 복원이 아니라 사용자 제안 **`_rerunRequired` 홀드**로). 미결은 `research/existing-mount-plan.md` §5의 갈래들뿐(개수는 거기가 소스). `H-147`~`H-149`는
> `H-143`~`H-146` 반영분에 `/code-review high`가 낸 10건 중 새 메커니즘·기존
> 결정 변경이라 문항으로 올린 셋(나머지 일곱은 반영 — `-round9-followup.md`의
> 마지막 code-review 절).

## 요약 표

| 번호 | 심각도 | 한 줄 | 주 대상 | 성격 | 실측 |
|---|---|---|---|---|---|
| `H-147` | 🟡 | `Rerun` 꼬리 `wasAlive`가 루프 머리 `_consumeCleanup()` **뒤**에 잡히고 공개 `Rerun()`에 게이트가 없어 **진입 시점에 이미 죽은 핸들**(직전 cleanup이 `self:Unsubscribe()` / 해제 뒤 타이머의 `self:Rerun()`)은 else 분기 → 고아 cleanup + `_installed = true` | `effect-plan.md` `Rerun` | `/code-review` 발견, 처방은 규칙 또는 새 플래그 | `t15`(재현 — §5) |
| `H-148` | 🟡 | `H-146`의 "`Parent` 거부는 **전용 문구**"가 새 메커니즘 — `isHandlable` 거부는 `Dispatch.process`의 **일반** 매치 실패 문구로 떨어지고 그 자리에 특수 분기는 두지 않기로 확정돼 있다. 사용자 회신에 문구 언급 없음(에이전트 선택이었음) | `bind-system-plan.md` `H-142` 항목, `ROADMAP.md` M5 | `/code-review` 발견, 처방은 새 핸들러 또는 철회 | — |
| `H-149` | 🟡 | `Observer:Subscribe`가 `self:WeakSubscribe()`로 위임하므로 거기 붙인 `error(…, 2)`가 `o:Subscribe()` 경로에선 사용자 호출부가 아니라 `Observer:Subscribe` 본문을 가리킴(`H-104` level 계약 위반). `EffectHandle`은 (b)로 인라인해 문제 없음 | `lifecycle-pattern.md` Observer 네 진입점 | `/code-review` 발견, 처방은 기존 결정("위임하므로 게이트 한 번") 변경 | `t19`(재현 — §5) |
| `H-150` | 🟡 | `Effect._blocker`는 **아무것도 억제하지 않는 죽은 부품**이다 — `fire`의 첫 줄 `canExecute(self)`가 생성자 구간(핸들이 아직 bind/Subscribe 안 됨)의 등록 즉시 1회를 전부 먼저 떨어뜨리고, 생성자 뒤로는 `_blocker`가 다시 `On()`되는 자리가 없다. 그런데 `effect-plan.md`는 억제 주체를 `_blocker`로 서술하고 `gate-plan.md` 7번은 아직 *"자기 내부 플래그로"*(폐기된 `_installing`)라 적혀 있다 | `effect-plan.md` 생성자 / `gate-plan.md` 7번 | 실측 발견, 처방은 부품 제거 또는 서술 정정(사용자 지시로 들어온 부품이라 문항) | `t18` |
| `H-151` | 🟡 | 게이트가 **두 경로에서 우회된다** — (1) `Effect`의 재바인드/재구독 캐치업 `_epochs:Refresh()`는 원천 `Epoch`의 `.Revision`을 직접 읽으므로 중간 `GateNode`가 유보 중이어도 `Rerun`이 돈다, (2) 게이트 없는 형제 dep이 emit하면 `fn`이 돌며 게이트된 dep의 최신값을 `:Get()`으로 그냥 본다. 둘 다 "값은 안 가린다" 계약의 따름정리지만 어디에도 적혀 있지 않다 | `gate-plan.md` / `effect-plan.md` `_bindDestroying` | 실측 발견, 처방은 문서화(권고) 또는 새 메커니즘 | `t16` |
| `H-152` | 🟡 | `gate-plan.md`의 `GateNode` 조립 절(필드 전부를 한 곳에 모은 절)에 **`StateBrand` 등록이 없다.** `_emitDown`은 `isState(sub)`로만 자식 노드를 가르므로 등록을 빠뜨리면 게이트는 `canExecute(sub)`(bind된 적 없음 → 거짓)로 떨어져 **조용히 영영 못 받는다** — `:Get()`은 멀쩡하고 통지만 죽는 모드. `brand-plan.md` 스스로 *"어느 브랜드에 등록하는 걸 빠뜨렸나"*를 조용한 버그로 경고한 그 자리 | `gate-plan.md` `GateNode` 조립 / `source-state-plan.md` `_emitDown` | 명시 누락(갈래 없음 — 한 줄 추가) | `t24`(재현) |
| `H-153` | 🟡 | Store 예약 이름(`Of`/`Names`/`__reservedCheck`)의 **런타임 갭** — `store:Of("Of")`는 구현 모양에 따라 메소드 함수를 그대로 돌려주거나(그림자=store 자신) 이후 `s:Of`를 가린다(프록시); `Store({ Of = Source(1) })`는 `isSource` 화이트리스트를 **통과**한 뒤 `s:Of(...)`가 *attempt to call a table value*로 죽는다. 타입 함수는 정적 키만 보고 동적 `Of(name)`과 `--!nocheck`엔 손이 안 닿는다(store-plan 자신이 `__reservedCheck`에 대해 절반은 인정) | `store-plan.md` 구현 스케치 / `Of` | 실측 발견, 처방은 **작은 런타임 가드**(새 검사라 문항) | `t23` |
| `H-154` | 🟡 | `InstanceChildHandler`의 retractor에 **같은 값 dedup이 없다** — `state<Frame>`이 같은 Frame을 다시 emit하면(spurious) `Parent = nil` → `Parent = inst`가 실제로 일어나고 `recompute(inst)`가 2회 돈다. 같은 자리의 `SlotHandler`(`slotValue == nextValue → return`)·`RefLeafHandler`(`old ~= v`)·Leaf(`old ~= v`)는 전부 dedup을 두고 있어 이 핸들러만 예외 | `dispatch-core-plan.md` `H-134` 문단 / `ROADMAP.md` M5 | 실측 발견, 처방은 한 줄 가드(동형 선례 있음, dedup 정책이라 문항) | `d23` |
| `H-155` | 🟢 | `ROADMAP.md` 체크박스 넷이 `base/`보다 낡았다 — M6 *"`recompute`는 `sourceList[i]`가 `nil`이어도 `None`처럼 skip"*(4라운드 `C-6`가 **즉시 error**로 뒤집음), M6 *"`destroySlotTree`가 자식 소유권 반납"*(`C-4`가 되돌림), M6 *"`self._mounted` 확인 후 즉시 활성화"*(6라운드 `H-2`가 `_physicalTarget`으로), M11 3-상태 슬롯 *"`RobloxTween \| true \| nil` … 엔진 객체=활성 트윈"*(tween-plan이 `{Tween, Value}` 테이블로 정정) | `ROADMAP.md` M6/M11 | stale(색인 레이어) | — |
| `H-156` | 🟢 | `debounce-throttle-plan.md` 7절의 `H-32` 문단이 *"`pending`을 없애고 Blocker의 `HasBlockedEmit`을 쓰면 … `OffWithoutEmit()`은 보류분을 버리면서 상태도 같이 비운다"*로 남아 있다 — 같은 절 배너가 7라운드 `H-86`(`HasBlockedEmit`은 정책이 읽을 수 없음)·`H-55`(`OffWithoutEmit`만으론 집합이 안 빔, `emit(false)` 필요)로 정확히 그 두 문장을 뒤집어놓고 본문은 안 고쳤다 | `debounce-throttle-plan.md` 7절 | 배너만 달고 본문 미수정 | — |
| `H-157` | 🟢 | `store-plan.md`의 *"빈 Store(`Store<<{}>>()`)는 아직 실측 안 됐다"*는 이제 실측됐다 — 최종형(§1 쪼개기 `Source<T>` + `CheckReservedKeys<keyof<T>>`)에 `Store({} :: {})`를 넣으면 `keyof<{}>`가 에러가 아니라 빈 유니온으로 풀려 **진단 0**, `empty:Names()`/`empty:Of(...)`도 정상 | `store-plan.md` 빈 Store 문단 | 실측 완료(서술 갱신만) | `ty11` |

## 상세

### `H-147` 🟡 — 이미 죽은 핸들에서 `Rerun()`이 불리면 (`H-143` 잔여)

`effect-plan.md` `Rerun`: 루프 머리 `_consumeCleanup()` → `local wasAlive =
canExecute(self)` → `fn` → `if wasAlive and not canExecute(self)`. "실행 중에
죽은" 건 잡지만 **"진입 시점에 이미 죽은"** 건 못 잡는다:
1. 직전 cleanup이 `self:Unsubscribe()`를 부름 → 루프 머리 소진 안에서 죽음 →
   `wasAlive` 거짓 → `fn` 실행 → else → 저장 + `_installed = true`. 고아 cleanup,
   이후 재`Subscribe`의 `resubscribeTail`이 `_installed` 참을 보고 재설치 생략.
2. `fn`이 `task.delay(1, function() self:Rerun() end)`를 걸고 사용자가 그 전에
   `Unsubscribe()`.
생성자 최초 `Rerun`("한 번도 산 적 없음")과 구분할 상태가 없다.
**갈래**: (a) "죽은 핸들에서의 `Rerun()`은 사용자 책임(UB)"으로 문서화 — 새
상태 없음; (1)은 "cleanup 안에서 자기 해제"를 지원 목록에서 빼는 것, (2)는
`Unsubscribe`가 도는 cleanup이 그 예약을 취소해야 하는 것(그게 cleanup의 일).
기존 "error 시 UB / 수렴 책임은 `fn`" 계약과 같은 결 / (b) `_everAlive` 플래그
하나(첫 `canExecute` 참 시점에 세움) → `Rerun` 진입에서 `everAlive and not
canExecute → return`. 필드 하나, 생성자 케이스도 가림 / (c) `wasAlive`를
`_consumeCleanup()` **앞**에서 잡기 — (1)만 닫히고 (2)는 그대로.
**권고 (a)** — 두 시나리오 다 "죽은 뒤에도 자기를 부르는 코드"고, `Unsubscribe`가
cleanup을 도는 이유가 바로 그런 예약을 거두라는 것.

### `H-148` 🟡 — `H-146`의 "전용 에러 문구"는 새 메커니즘이었다

`PropertyHandler.isHandlable`이 `"Parent"`를 거부하면 나오는 건 `Dispatch.process`의
**일반** 매치 실패 문구(*"no handler … check provider"*)이고, 그 자리에 특수
분기는 두지 않기로 확정돼 있다(`dispatch-core-plan.md`의 매치 실패 절). 전용
문구를 내려면 새 자리가 필요하다. 사용자 `H-146` 회신엔 문구 언급이 없었고
에이전트가 "배선 세부"라며 붙였다 — `conventions.md` 2026-08-27 규칙 위반.
**갈래**: (a) 전용 문구 **철회** — 일반 매치 실패 error 그대로, 오해는 사용자
문서("`Parent`는 props에 못 쓴다, 루트는 밖에서")로 흡수. 새 것 0 / (b) **가드
핸들러** — `k == "Parent"`에 매치해 `process`에서 전용 문구로 error. Observer/
Effect의 "동적 경로 가드"(`effect-plan.md`)와 같은 모양이라 새 *종류*는 아니나
핸들러 하나 + 숏핸드보다 위 우선순위 필요 / (c) `Dispatch.process` 매치 실패
문구에 키 이름을 싣기(일반 개선이지만 별도 결정).
**권고 (a)** — 원래 회신의 취지(새 API 없음, 최종 사용자 몫)와 같은 결. M5에서
실제로 밟아 헷갈리면 (b)를 그때 얹는 게 싸다.

### `H-149` 🟡 — `Observer:Subscribe`의 위임 때문에 `level 2`가 quad 내부 줄을 가리킨다

2026-08-27에 `Observer:WeakSubscribe`의 `error`에 `, 2`를 붙였는데(`H-104`
계약), `Subscribe`가 `self:WeakSubscribe()`로 위임하므로 `o:Subscribe()` 경로의
level 2는 **`Observer:Subscribe` 본문**을 가리킨다. 가장 흔한 오용(leaf 바인딩된
Observer에 `o:Subscribe()`)이 quad 내부 줄을 블레임한다. `EffectHandle` 쪽은 (b)로
게이트를 인라인해 문제 없음.
**갈래**: (a) Observer도 `Subscribe`에 게이트·등록 세 줄을 **인라인** — Effect와
같은 모양, level 2 정확. "게이트는 한 번만 돈다 — `Subscribe`가 `WeakSubscribe`에
위임"이라는 기존 문장이 "각자 한 번"으로 바뀜. 중복 세 줄은 같은 타입 안이라
dot 호출 로컬 헬퍼로 빼도 됨(가상 디스패치 없음) / (b) 내부 헬퍼
`weakSubscribe(self, level)`로 위임하고 `Subscribe`는 `level 3` — 코퍼스에
`level 3` 선례 없음 / (c) 그대로 두고 `Subscribe` 경로만 블레임이 한 단계 안쪽임을
문서화.
**권고 (a)** — "본문을 섞지 않는다"(2026-08-27 원칙)와 결이 같다.

### `H-150` 🟡 — `Effect._blocker`는 죽은 부품이다 (억제는 `canExecute`가 이미 한다)

**트레이스** — `base/effect-plan.md`의 "의사코드 — 생성자" 절 그대로:
`self._blocker:On()` → dep마다 `d:Observer(onStateFire)`(등록 즉시 1회 → `fire`) /
`d:WeakCallback(onRefFire)`(등록 즉시 1회 → `fire`) → `self._blocker:OffWithoutEmit()` →
`self:Rerun()`. `fire`의 순서는 `canExecute(self)` → `_blocker:IsOn()` → `Update`.
생성자 안의 `self`는 아직 `bindLifetime`도 `Subscribe`도 안 된 핸들이라
`isBoundAlive(self)`가 거짓 → **`canExecute`가 첫 줄에서 전부 떨어뜨린다.**
`_blocker:IsOn()` 줄엔 한 번도 도달하지 않는다. 생성자 뒤로 `_blocker:On()`을
다시 부르는 자리는 코퍼스 어디에도 없다(`_bindDestroying`/`Rerun`/네 진입점 전부
확인) — 즉 이 부품은 **어떤 실행 경로에서도 판정에 참여하지 않는다.**
실측(`t18`): `fire` 가드 판정을 훅으로 기록하니 dep 3개짜리 Effect의 생성자에서
`drop:canExecute` 3건, `drop:blocker` **0건**. 바인드 뒤 `Set`은 정상 발화.

**왜 문제인가** — 동작은 안 깨진다. 문제는 **서술**이다:
- `effect-plan.md`는 *"억제는 사적 `Blocker` 하나가 전담한다"*, `_installing`
  플래그가 *"생성자 구간만 덮어 바인드 구간을 놓쳤다"*고 근거를 적어뒀는데,
  실제 차단자는 `canExecute`다. 다음 구현자가 이 근거를 믿고 `_blocker`를
  건드리거나(예: 바인드 구간에도 `On()`을 걸어 "일관되게") 반대로 `canExecute`
  줄을 옮기면(예: `Update`를 먼저 해서 리비전을 앞당겨 기록하려고) 그때 처음으로
  `_blocker`가 진짜 역할을 갖게 되거나 캐치업이 어긋난다 — 사냥 목록의 *"두 뜻이
  같다"*형(문서가 두 장치를 같은 것처럼 서술) 자리다.
- `base/gate-plan.md` 7번은 더 낡았다 — *"`Effect`가 **자기 내부 플래그로** 설치
  중 발화를 누르고"*는 7라운드 `H-58`이 폐기한 `_installing` 서술이다(같은
  문서의 "확정 구조" 절과 `effect-plan.md`는 이미 `Blocker`로 바뀌어 있다).

**새 메커니즘 여부** — 없음. 제거 쪽이면 필드 하나·줄 셋이 준다.

**갈래**
- (a) **`_blocker`를 제거**하고 생성자 주석을 *"등록 즉시 1회는 `canExecute`가
  막는다(생성자 안에선 핸들이 아직 bound가 아니므로)"*로 정정. `gate-plan.md`
  7번도 같이 정정.
- (b) **유지**(belt-and-braces — 나중에 생성자 안에서 bound가 되는 경로가
  생기면 그때 의미를 가짐) + 문서를 *"실제 차단자는 `canExecute`, `_blocker`는
  예비"*로 정정. `gate-plan.md` 7번 정정은 동일.
- (c) 유지 + `fire`의 순서를 `_blocker:IsOn()` → `canExecute`로 뒤집어 `_blocker`가
  실제로 먼저 판정하게(문서와 코드를 맞추는 반대 방향).

**권고: (a).** 근거 — `conventions.md`의 "설계 원칙" 절(가상의 미래 요구까지
방어하지 않는다). (c)는 순서만 바꿀 뿐 `canExecute`가 거짓인 구간과 `_blocker`가
켜진 구간이 완전히 겹쳐 여전히 판정 차이가 0이다. 단 **이 부품은 7라운드 `H-58`에서
사용자가 `Blocker`를 쓰라고 직접 지시해 들어온 것**이라(그 인용은
`qa-request/pre-implementation-handtrace-round7-followup.md`의 `H-58`) 탐사자가
임의로 빼지 않고 문항으로 올린다 — 그 지시의 전제("등록 즉시 1회가 `Rerun`에
닿는다")가 `canExecute` 첫 줄 때문에 성립하지 않는다는 게 이 발견의 요지다.

**채택 시 고칠 자리** — `base/effect-plan.md` 생성자 의사코드·"확정 구조" 절·
`H-58` 정정 문단(`_blocker`/"전담" 서술), `base/gate-plan.md` 7번,
`ROADMAP.md` M2의 `Effect` 항목에 `_blocker`가 있으면 같이.

### `H-151` 🟡 — 게이트는 `Effect` 캐치업과 형제 dep 경로에서 우회된다

**트레이스 (1) — 재바인드 캐치업.** `g = s:Block(b)`, `e = Effect(fn, g)`,
`bindLifetime(inst, e)`. `b:On()` → `s:Set(2)` → `g:_receive` → 유보(`fn` 안 돎,
맞다). 이제 `e`를 unbind → 다른 inst에 rebind(포탈) → `_bindDestroying` →
`self._epochs:Refresh()`. `_epochs`의 키는 **원천 `Epoch`**(`s`)다 — 생성자가
`TrackFrom(g.valueEpochMap)`으로 `g`가 아는 원천을 그대로 복사했고, `Refresh`는
그 원천들의 `.Revision`을 **직접** 읽는다. `s.Revision`은 이미 바뀌었으므로
`depsChanged = true` → **`Rerun` — 게이트가 아직 닫혀 있는데 `fn`이 돈다.**
실측(`t16` 1·2): 게이트 유보 중 재바인드/재구독 → `fn` 1회 실행, 이후 `b:Off()`
flush에서 다시 1회(리비전이 이미 `Refresh`로 갱신됐는데도 flush 배치가 같은
원천을 싣고 오면 `Update`가 변화 없음으로 접어야 하나 — 실측에선 접혔다, 즉
두 번째는 안 돈다. 정확한 횟수는 §7).

**트레이스 (2) — 형제 dep.** `e = Effect(fn, g, u)`(`u`는 게이트 없는 Source).
`b:On()` → `s:Set(2)`(유보) → `u:Set(9)` → `u` 경로로 `fire` → `Update(u)` 참 →
`Rerun` → `fn` 안에서 `g:Get()`은 **최신값 2**를 준다(게이트는 값을 안 가린다,
`base/gate-plan.md` 확정). 즉 게이트로 "이 값의 변경은 나중에 보겠다"고 했는데
형제가 깨우면 그 값이 그대로 보인다. 실측(`t16` 4).

**왜 문제인가** — 둘 다 코드가 틀린 게 아니라 **계약이 안 적혀 있다.**
`gate-plan.md`는 *정책이 미루는 건 다운스트림 통지뿐*이라고만 하고, "통지가
emit이 아닌 경로(캐치업·형제)로 오면 어떻게 되는가"는 어디에도 없다.
`Debounce`/`Throttle` 사용자는 (1)에서 포탈 한 번에 창을 건너뛰는 실행을 보고,
(2)에서 debounce된 값이 형제 emit마다 새는 걸 본다 — 둘 다 "버그 리포트"로
들어올 모양이다.

**새 메커니즘 여부** — 문서화 갈래는 없음. 막는 갈래는 **새 메커니즘**이다:
(1)을 막으려면 `Refresh`가 원천 `.Revision`이 아니라 **dep 노드의
`emitEpochMap`**을 보고 비교해야 하는데, `EpochMap:Refresh`는 키가 `Epoch`인
맵을 라이브로 다시 읽는 연산이라 노드를 거치는 형태가 아니다(`EpochMap`
계약 변경). (2)를 막으려면 `fn` 실행 중 게이트된 dep의 `:Get()`이 유보 전
값을 돌려줘야 하는데 그건 `debounce-throttle-plan.md` 4절이 **철회한 (B)
value-hold**다.

**갈래**
- (a) **문서화** — `gate-plan.md`에 *"게이트는 emit 경로만 미룬다. `Effect`의
  재바인드/재구독 캐치업(`Refresh`)과 게이트 없는 형제 dep의 emit은 게이트를
  거치지 않고, 그때 `:Get()`은 최신값을 준다"*를 계약으로 명시.
  `debounce-throttle-plan.md` 11절(다른 결정과의 상호작용)의 `Effect` 항목에도
  같은 문장.
- (b) (1)만 막기 — `Effect`가 State dep에 대해선 `Refresh` 대신 dep의
  `emitEpochMap`을 비교(새 메커니즘, `EpochMap` 계약 변경).
- (c) 둘 다 막기 — value-hold 재개방(이미 기각된 안).

**권고: (a).** 근거 — (b)(c)는 각각 `state-epoch-plan.md`의 `Refresh` 계약과
2026-08-19 `(A) emit-gate` 확정을 되짚어야 하고, 실사용 빈도(게이트된 dep을
가진 Effect가 포탈되는 경우)가 낮다. (a)는 이미 성립하는 사실을 적는 것뿐이다.

**채택 시 고칠 자리** — `base/gate-plan.md`(계약 문장),
`base/debounce-throttle-plan.md` 11절, `base/effect-plan.md` `_bindDestroying`
캐치업 주석("dep이 변했으면"의 뜻이 원천 기준임을 한 줄).

### `H-152` 🟡 — `GateNode` 조립 절에 `StateBrand` 등록이 없다

**트레이스** — `base/gate-plan.md`의 "`GateNode` 조립" 절은 *"세 문서에 나뉘어
있어 한 곳에서 순서를 볼 수 없었다 … 구현자가 조립을 잘못할 여지를 없애려고
여기 모은다"*며 필드 여섯과 `_receive`/`_flush`를 적는데, **브랜드 등록이 없다.**
`base/source-state-plan.md`의 `_emitDown`은 `if isState(sub) then sub:_receive(from)
elseif canExecute(sub) then …`로 자식 노드를 **`isState`로만** 가른다.
`base/brand-plan.md`는 *"각 타입은 자기 브랜드에만 등록하고, 포함 관계는
predicate 한 곳에 쓴다"*라 `isState`가 참이려면 `GateNode`가 `StateBrand`에
등록돼야 한다. 빠뜨리면: 상류 `Set` → `_emitDown` → `isState(gate)` 거짓 →
`canExecute(gate)`(게이트는 bind/Subscribe된 적 없음) 거짓 → **조용히 건너뜀**.
`gate:Get()`은 `_hold`를 타고 올라가 최신값을 주므로 값 검사로는 안 잡힌다 —
통지만 죽는다. 실측(`t24`): 같은 메소드·다른 identity로 브랜드만 떼면 하류
Observer 발화 2 → **0**, `Get()`은 3으로 정상.

**왜 지금 잡나** — `GateNode`는 `ComputeNode`와 달리 State 생성자를 안 지나고
`Gate(self, setup)`가 직접 조립한다(위 절이 그 조립을 정의한다). 생성자가
공통이면 등록도 공통 자리에 있겠지만, 여기선 조립 절이 곧 생성자라 그 절에
없으면 어디에도 없다. `ROADMAP.md` M2 `GateNode` 항목에도 브랜드 언급이 없다.
사냥 목록 *"의사코드 순서 ≠ 산문"*의 변형 — 산문("게이티드 State 노드")은
State라 하고 의사코드는 State가 되는 줄이 없다.

**새 메커니즘 여부** — 없음(기존 `StateBrand:add(node)` 한 줄).

**갈래** — 없음. 조립 절 필드 목록 첫 줄(또는 `Gate(self, setup)` 본문)에
`StateBrand` 등록을 명시. 같은 절에 *"`isState(gate)`가 참이어야 `_emitDown`이
`_receive`로 보낸다"*를 근거로 한 줄.

**채택 시 고칠 자리** — `base/gate-plan.md` 조립 절, `ROADMAP.md` M2 `GateNode`
체크박스. 참고 구현 `core10.luau`는 `isState`에 `GateNode` 메타테이블을 **직접
넣어서** 이 문제를 우회하고 있었다(README의 "옮기며 고친 것" 참고).

### `H-153` 🟡 — Store 예약 이름의 런타임 갭 (`Of("Of")` / `defaults.Of`)

**트레이스** — `base/store-plan.md`의 구현 스케치: 생성자는
`table.clone(defaults or {})` + `isSource` 순회, `store:Of(name)`은 그림자 테이블에
`Source`를 lazy 생성. 스케치가 *"그림자 테이블"*이라고만 해서 **store 자신인지
별도 테이블인지**가 안 정해져 있다(같은 문서가 `store.key`는 *"평범한 레코드
필드"*라 하므로 store 자신일 가능성이 크다). 두 모양을 다 옮겨 실측(`t23`):

| | (I) 그림자 = store 자신(`__index` 메소드) | (II) 별도 그림자 + 프록시 |
|---|---|---|
| `s:Of("Of")` | **메소드 함수를 그대로 반환**(`Source` 아님), 이후 `Of` 정상 | `Source`를 만들어 그림자에 넣음 → 이후 `s:Of`가 **그 Source에 가려져** `attempt to call a table value` |
| `s:Names()` | 정상 | `Of`가 사용자 키로 섞여 나옴 |
| `Store({ Of = Source(1) })` | `isSource` 통과 → `s:Of(...)`가 **`attempt to call a table value`** | (동일) |

타입 쪽 `CheckReservedKeys<keyof<T>>`는 (H)처럼 **정적 키**만 잡는다(`ty11`에서
정확히 잡힘). `Of(name)`의 `name`은 타입에 안 실리고, `--!nocheck`/동적 코드는
`isSource` 화이트리스트(`H-122`)가 있어도 예약 이름을 안 보므로 통과한다.
`store-plan.md`는 `__reservedCheck`에 대해선 *"동적 키는 이름이 타입에 안
실리므로 못 막는다"*고 이미 인정하는데, 같은 문장이 `Of`/`Names` 자신에게도
성립한다는 건 안 적었다.

**왜 문제인가** — 죽긴 죽는데 **자리가 멀다**: `defaults` 예약 이름은 생성
시점이 아니라 첫 `s:Of(...)`에서, 메시지도 예약 이름과 무관한 *call a table
value*다. `H-122`가 `isSource` 화이트리스트를 둔 이유("조용히 받고 첫 `Get`에서
엉뚱한 에러로 죽는다")와 정확히 같은 모양의 구멍이 한 칸 옆에 남아 있다.

**새 메커니즘 여부** — 작은 런타임 검사(예약 이름 셋과 비교) — 새 개념은 아니나
새 검사이므로 문항. `archive/`·"검토 후 안 만들기로 한 것"류에서 런타임 예약 이름
가드를 기각한 기록은 **없다**(`archive/store-value-field-redesign-withdrawn.md`는
타입 함수 범위만 다룸).

**갈래**
- (a) **런타임 가드** — 생성자 `isSource` 순회에 `if RESERVED[k] then error(..., 2)`,
  `Of(name)`에 같은 검사(둘 다 `level 2`, 영어 메시지 — `architecture.md` error
  계약). 생성 시 1회 + `Of` 호출당 테이블 조회 1회라 hot path 아님.
- (b) 문서화만 — *"예약 이름을 동적으로 쓰면 UB"*.
- (c) 그림자를 (II) 별도 테이블로 못박고 `Of`만 가드(부분).

**권고: (a).** 근거 — `H-122`와 같은 자리·같은 논거(화이트리스트 검증은 이미
있고 비교 대상을 셋 늘리는 것뿐), fail-fast 톤(`Slot` CRUD·`KeyGone`의 선례).
부수로 스케치의 "그림자 = store 자신인가"도 같이 못박을 것(권고: (I) — `store.key`
레코드 필드 계약과 맞고 `Names()`가 메소드를 안 세려면 메소드는 `__index`에).

**채택 시 고칠 자리** — `base/store-plan.md` 구현 스케치·`Of` 절·
`__reservedCheck` 주석 (2), `ROADMAP.md` M2 Store 항목.

### `H-154` 🟡 — `InstanceChildHandler`는 같은 Frame 재발행에 물리 detach/attach를 한다

**트레이스** — `base/dispatch-core-plan.md`의 `H-134` 문단(그리고 `ROADMAP.md`
M5): `process` = `setOffsetSource(None)` → `v.Parent = inst` → `setLength(1)`,
retractor = `v.Parent = nil` → `setOffsetSource(None)` → `setLength(0)`. 하강
diff의 (A) 분기는 같은 핸들러면 **무조건** `retractor(v)` → `process`를 다시
부르므로(`Dispatch 체인` 절), `state<Frame>`이 **같은 Frame**을 다시 emit하면:
`A.Parent = nil` → `recompute(inst)` → `A.Parent = inst` → `recompute(inst)`.
실측(`d23`, round7 `chain.luau` 위에 그대로 옮김): 같은 값 재발행 1회에 `Parent`
대입 2회 + `recompute` 2회. 대조군 `SlotHandler`는 `slotValue == nextValue`면
얼리리턴, `RefLeafHandler`/Leaf는 `old ~= v` dedup — `dispatch-core-plan.md`의
"Handler 작성 체크리스트" 4번이 *"`Ref`의 spurious 재바인딩 dedup"*을 예로 든다.

**왜 문제인가** — Roblox에서 `Parent = nil` → `Parent = inst`는 `ChildRemoved`/
`ChildAdded`/`AncestryChanged`를 실제로 쏘고 레이아웃을 한 프레임 흔들 수 있다.
spurious 재발행은 `Source:Set`이 같은 값도 emit한다는 확정(`t18`로 재확인)
때문에 드물지 않다 — `store.child:Set(store.child:Get())` 한 줄이면 난다.

**새 메커니즘 여부** — 없음(선례와 같은 한 줄).

**갈래**
- (a) retractor 첫 줄에 `if nextValue == v then return end`(`SlotHandler`와 동형) —
  단 그러면 `process`가 다시 `setOffsetSource(None)`/`Parent = inst`/`setLength(1)`을
  하므로 부기는 멱등하고 `Parent` 대입은 같은 값 재대입(엔진 no-op).
- (b) 그대로 둔다 — "dedup은 성능 최적화라 핸들러마다 선택"으로 문서화.

**권고: (a).** 근거 — 같은 값 재발행의 dedup은 `Slot`/`Ref`/Leaf에서 이미 채택된
정책이고, 이 핸들러만 빠진 건 `H-134`가 늦게 생겨서다(설계 차이가 아님).

**채택 시 고칠 자리** — `base/dispatch-core-plan.md` `H-134` 문단, `ROADMAP.md` M5
`InstanceChildHandler` 항목.

### `H-155` 🟢 — `ROADMAP.md` 체크박스 넷이 `base/`보다 낡았다

넷 다 `base/`가 소스이고 ROADMAP만 안 따라온 것(색인 레이어 stale, 사냥 목록
"배너만 달고 본문 안 고침"의 ROADMAP판):

1. M6 *"`recompute`는 `sourceList[i]`가 `nil`이어도 `None`처럼 skip(방어)"* —
   `base/slot-plan.md`는 4라운드 `C-6`로 **즉시 `error`**(부기가 깨졌다는 신호).
2. M6 *"`destroySlotTree`가 자식 소유권 반납 + …"* — `slot-plan.md`는 `C-4`로 그
   수정을 **되돌렸다**(`State<Slot>` 재설정 표의 정정 문단이 명시).
3. M6 *"`self._mounted` 확인 후 즉시 활성화"* — 6라운드 `H-2`로 판정 기준이
   `_physicalTarget`.
4. M11 *"3-상태 릴레이션 슬롯(`RobloxTween | true | nil` … 엔진 객체=활성 트윈)"*
   — `base/tween-plan.md`의 "3-상태 저장" 절은 `{Tween, Value}` **테이블**
   (`Tween.Finish`가 목표값을 알아야 해서).

갈래 없음 — ROADMAP 넷을 `base/` 문장으로 교체.

### `H-156` 🟢 — `debounce-throttle-plan.md` 7절 `H-32` 문단이 배너와 모순

같은 절의 무효화 배너는 7라운드 `H-86`(*"읽는 통로는 `HasBlockedEmit`이 아니라
`emit`의 반환값"*)·`H-55`(*"`b:OffWithoutEmit()`만으로는 집합이 안 비므로
`emit(false)`가 필요"*)를 반영했는데, 바로 아래 `H-32` 문단은 여전히
*"`pending`을 없애고 Blocker의 `HasBlockedEmit`을 쓰면 … `Trailing = false`는
`OffWithoutEmit()`으로 표현되고, 그건 보류분을 버리면서 상태도 같이 비운다"*.
두 문장 다 배너가 뒤집은 것이다. 갈래 없음 — 그 문단을 *"`emit()`의 반환값으로
읽고 `emit(false)`로 버린다"*로 정정.

### `H-157` 🟢 — 빈 Store는 실측됐다

`base/store-plan.md`의 *"빈 Store는 아직 실측 안 됐다 … `keyof<{}>`가 빈
유니온이 되는지 에러가 되는지"*: `ty11`(최종형 — `StateData<T>`/`State<T>`
쪼개기, `Source<T>` 필드, `CheckReservedKeys<keyof<T>>`, 재귀 `Compute -> State<U>`
포함)에 `local empty = Store({} :: {})`를 넣으면 **진단 0**(`keyof<{}>` →
`never`가 아니라 빈 유니온으로 `components()`가 비어 검사가 그냥 통과),
`empty:Names(): {string}`/`empty:Of("dyn"): Source<number>` 정상. 같은 파일에서
키 있는 양성(A·B·C·E) 0건, 음성(D·F·`c4`) 정확히 그 줄, 예약 키(H) 진단 1건,
§1 구멍(G)은 알려진 대로 조용히 통과. 갈래 없음 — 문단을 "실측 완료"로 갱신,
`luau-test/STATUS.md`의 `16`/`21` 재작성 시 대조군 메모는 그대로 유효.

## §4 ⭐ 사용자 결정이 필요한 것 (배치 회신용)

| 문항 | 무엇 | 선택지 | 권고 |
|---|---|---|---|
| **`H-147`** | 죽은 핸들에서 `Rerun()` | (a) UB로 문서화(cleanup 안 자기 해제는 지원 목록 밖, 타이머 취소는 cleanup의 일) / (b) `_everAlive` 플래그 + 진입 게이트 / (c) `wasAlive`를 소진 앞에서 | **(a)** — 새 상태 없이 기존 UB 계약과 같은 결 |
| **`H-148`** | `Parent` 거부 문구 | (a) 전용 문구 철회, 일반 매치 실패 그대로 / (b) `Parent` 가드 핸들러(동적 경로 가드형) / (c) 일반 문구에 키 이름 | **(a)** — 회신 취지(새 API 없음) 그대로, 필요하면 M5에서 (b) |
| **`H-149`** | Observer `Subscribe` 위임과 `level 2` | (a) `Subscribe`에 게이트·등록 인라인(Effect와 동형) / (b) `level 3` 위임 / (c) 문서화만 | **(a)** — 본문 안 섞기 원칙과 동형 |
| **`H-150`** | `Effect._blocker`(죽은 부품) | (a) 제거 + "억제는 `canExecute`"로 서술 정정 / (b) 유지 + 서술 정정("실제 차단자는 `canExecute`, `_blocker`는 예비") / (c) 유지 + `fire` 순서를 `IsOn` → `canExecute`로 | **(a)** — 판정 차이 0인 부품, `conventions.md` 설계 원칙. 단 `H-58` 사용자 지시로 들어온 부품이라 문항 |
| **`H-151`** | 게이트 우회(캐치업 `Refresh` / 형제 dep) | (a) 계약으로 문서화(게이트는 emit 경로만 미룬다) / (b) 캐치업을 dep `emitEpochMap` 기준으로(새 메커니즘) / (c) value-hold 재개방(기각안) | **(a)** — 이미 성립하는 사실, (b)(c)는 확정 둘을 되짚음 |
| **`H-153`** | Store 예약 이름 런타임 가드 | (a) 생성자 순회 + `Of(name)`에 예약 이름 검사(`error(…, 2)`) / (b) 문서화만(UB) / (c) 그림자 (II) 고정 + `Of`만 가드 | **(a)** — `H-122` 화이트리스트와 같은 자리·논거. 부수: 그림자 = store 자신(I)로 못박기 |
| **`H-154`** | `InstanceChildHandler` spurious dedup | (a) retractor `if nextValue == v then return end`(`SlotHandler` 동형) / (b) 그대로(정책 문서화) | **(a)** — `Slot`/`Ref`/Leaf가 이미 채택한 정책 |
| **`H-159`** | **[2026-08-28 `/code-review`, 반영 뒤]** `H-151`이 잃은 캐치업 — 바인드 **전**에 온 emit(특히 `Ref`)은 다시 안 온다 | (a) `_bindDestroying`/`resubscribeTail`에 **"묶이는 시점 1회 `Refresh`"**만 되살림(emit 경로의 `_epochs` 갱신은 `H-151`대로 `Update`만) / (b) `Ref` dep만 바인드 시 `.Revision` 대조 / (c) 계약으로 두고 사용자에게 "`Ref`를 dep으로 쓰는 Effect는 그 leaf 뒤에 두라" 문서화 | **(a)** — `H-151`의 근거("다음 emit이 잡는다")가 `Ref`엔 성립하지 않는다; (a)는 `H-151`을 되돌리는 게 아니라 "emit 경로만 미룬다"는 계약과 양립(바인드는 emit 경로가 아님) |
| **`H-160`** | leaf `Destroying` 콜백이 도는 cleanup 안의 `self:Rerun()`/`dep:Set()` — `canExecute`가 아직 참이라 죽는 inst에서 `fn`이 돌고 새 cleanup이 영구 고아 | (a) `rawRerun` 진입에서 `_cleanupRunning`이면 **버린다**(no-op) — "cleanup은 자기 생명주기를 못 바꾼다"의 `Rerun`판 / (b) `Destroying` 콜백이 `_consumeCleanup` **전에** `.Subscribed`류 표식으로 죽음을 먼저 세움(새 상태) / (c) UB 문서화 | **(a)** — 새 상태 없이 기존 플래그 하나로, `Unsubscribe` 경로와 같은 결과 |
| **`H-161`** | `H-148` 이후 **M5에 승인된 루트 부착 경로가 없다** + 여러 스크립트가 같은 `PlayerGui`를 `Claim`하면 이중 claim error / 다중 quad UB라 `Claim`이 자기 동기 사례를 막는다 | (a) `Claim`을 **M5 스코프**로 당기고(프로바이더 마일스톤이라 자연스러움) `research/existing-mount-plan.md` §5-7·8 갈래를 같이 정한다 / (b) `Claim` 전까지 임시로 `H-146` 루트 예외(밖에서 `.Parent =`)를 M5 한정으로 되살림 / (c) 루트 컨테이너(부기 대상 아님)는 claim 없이 자식만 붙이는 얇은 표면 신설 | **(a)** — 임시 예외는 하루 만에 뒤집힌 것을 되살리는 것이고, (c)는 `Mount` 기각의 재개방. §5-7(다중 스크립트)은 `Claim`의 "전부 매핑" 계약이 **루트 컨테이너에는 안 맞는다**는 신호라 갈래를 그 문서에 적었다 |
| **`H-163`** ✅ (a) → **(a′)** | **[2026-08-28 `/code-review`, `H-159` 반영 뒤]** Slot 내부 Observer(`_listObserver`·`_baseObserver`)에도 홀드 발화가 걸려 재마운트의 `bindLifetime`이 `materializeSlotTree` **도중** `reconcile`을 동기 실행 → 자리 이중 등록, 중첩 Slot이면 `canBound` error | (a) Slot이 자기 내부 Observer를 다시 묶기 전에 `_rerunRequired`를 **지운다**(재마운트 캐치업은 `activateList`가 이미 명시적으로 한다 — 이중) / (b) 홀드 발화를 사용자 Observer에만(내부 Observer는 브랜드로 구분 — 새 구분) / (c) 홀드 발화를 `bindLifetime` 안이 아니라 `materializeSlotTree` 끝(`blocker:OffWithoutEmit()` 뒤)으로 미룸 | **(a) → (a′)** — (a)의 전제("재마운트 캐치업은 `activateList`가 이미 한다")는 감사 2라운드가 반증(그 분기는 앵커만 옮긴다) → 트리 확정 뒤 끄고 묶고 홀드가 있었으면 reconcile 1회. 소스는 `-round10-followup.md` |
| **`H-164`** ✅ (c) — 문항 전제 정정 | Observer 홀드 발화가 `emitFrom = nil`로 오면 계약("`nil` = 설치 발화")과 구분 불가 — `if emitFrom == nil then initOnly()`로 짠 소비자가 변경을 놓침 | (a) 홀드 시 **마지막 `from`을 보관**(`_rerunRequired = from`, 진리값으로 플래그 겸용)해 그것을 넘김 / (b) 전용 센티널(`HeldEmit`) / (c) 계약 문구만 "`nil` = 설치 **또는** 묶일 때 캐치업" | **(c) — 문항 전제 정정**: 홀드 발화는 출처 있는 통지가 아니라 "묶였으니 값을 읽어라"라 설치 발화와 같은 종류 — `nil` = 출처 없음(설치 또는 캐치업). (a)의 `from` 보관은 사용자 기각(여러 홀드가 오면 앞 것이 날아감, 보관할 이유 없음). 소스는 `-round10-followup.md` |

갈래 없는 것(회신 불필요, 반영만): `H-152`(브랜드 등록 한 줄), `H-155`(ROADMAP 넷),
`H-156`(`H-32` 문단), `H-157`(실측 완료 표기).

**[2026-08-28 추가] `H-159`~`H-161`은 §4 문항 7건을 반영한 뒤 `/code-review high`가
낸 10건 중 새 메커니즘·기존 결정 변경인 셋**(나머지 일곱은 반영 — `-round10-followup.md`
마지막 code-review 절). 상세는 아래.

### `H-159` 🟡 — `H-151`이 잃은 캐치업: 바인드 전에 온 emit은 다시 안 온다

`D.Frame { Effect(function(self) if ref.Value then … end end, ref), D.TextButton { ref } }`.
Lua는 배열 원소를 순서대로 평가한다 — `Effect(...)`가 먼저 생성돼 `fn`이 1회 돌고
(`ref.Value == nil`), 그다음 `D.TextButton { ref }`가 `ref:Set(button)` → `fire` →
`canExecute(E)` 거짓(아직 안 묶임) → **`_epochs`를 안 건드리고 버림**. 그 뒤 Frame의
`drive`가 E를 leaf에 묶음 → `_bindDestroying` → `_installed == true`라 `Rerun` 없음.
`Ref`는 `Set`될 때만 발화하므로 **`fn`은 영원히 버튼을 못 본다**(배열 순서를 바꾸면
된다 — 순서 의존 버그). 같은 구멍이 생성자 안에도 있다: `fn`이 자기 dep을 `Set`하면
그 emit은 `fire` 첫 가드에서 버려지고(`self:Rerun()`처럼 지연되지 않는다) `_installed`가
참이 돼 바인드가 재실행하지 않는다. 옛 `_epochs:Refresh()`는 둘 다 잡았다. `H-151`의
근거 *"죽어 있는 동안 떨어뜨린 emit은 다음 emit의 리비전 차이로 잡힌다"*는 **다음
emit이 오는 dep**에만 성립한다. 갈래·권고는 §4 표.

### `H-160` 🟡 — leaf `Destroying` 경로의 cleanup은 `canExecute`가 아직 참인 채 돈다

`SignalBehavior = Immediate`: `inst:Destroy()` → `Destroying` → `_unbindDestroying()`(
`_destroyConn`만 해제, gcconn은 아직 `.Connected`) → `_consumeCleanup()` → cleanup이
`self:Rerun()`(또는 `dep:Set()` → `fire`) → `rawRerun(false)`: `_running` 거짓,
`canExecute` **참** → 죽는 inst에서 `fn`이 돌고 `_cleanup = c2`, `_installed = true`;
`_destroyConn`은 이미 nil이라 c2를 소진할 연결이 없고, 나중 포탈 재바인드는
`_installed` 참을 보고 재설치를 건너뛴다(조용히 죽은 Effect). `Unsubscribe()` 경로가
안전한 건 `.Subscribed = false`를 소진 **전에** 세우기 때문 — `Destroying` 경로엔
그 대응물이 없다. `rawRerun` 주석의 *"해제 뒤 cleanup의 재요청 … 정의된 no-op"*은 이
경로에서 거짓. 갈래·권고는 §4 표.

### `H-161` 🟡 — M5에 승인된 루트 부착 경로가 없다 / `Claim`이 자기 동기 사례를 막는다

`H-148`이 `H-146`의 루트 예외를 폐기하고 `Claim`은 "M5 이후" 백로그라, M5(프로바이더·
`D`·`InstanceChildHandler`)가 끝나도 quad가 만든 트리를 `PlayerGui`에 붙이는 승인된
경로가 코퍼스에 없다. 그리고 `research/existing-mount-plan.md`의 *이중 claim은 error /
여러 quad가 한 트리를 claim은 UB / 부기 대상 자식은 전부 매핑* 계약을 그대로 두면
`Shop.client.luau`와 `Inventory.client.luau`가 각각 `Claim(PlayerGui, …)`하는 **가장
흔한 사례가 error**다 — 그 문서 §5엔 이 문항이 없었다(추가: §5-7·§5-8). 갈래·권고는
§4 표.

## §5 이상 없다고 확인한 것

전부 `audit/handtrace-round10-reference-impl/spikes/`의 참고 구현(`core10.luau`/
`dispatch10.luau`, `H-107`~`H-149` 계약으로 갱신) 위에서 값으로 확인한 것. 스파이크
이름은 §7.

- **레인 A — `EffectHandle` 상태 전이표(`t14`).** 네 진입점 × {미바인드/바인드/
  파괴 뒤/구독만} × `Rerun` 꼬리 × `_bindDestroying`: (1) 미바인드 `Subscribe` →
  `fire`가 살아나고 `Unsubscribe` → 죽음, (2) 바인드 중 `WeakUnsubscribe`는 관대
  (`H-133`), `Unsubscribe`는 엄격 error, (3) 파괴 뒤 `Subscribe`(재구독)는
  `resubscribeTail` 캐치업으로 재설치(`H-144` (b)), (4) 파괴 → 재바인드도 재설치,
  `_installed`/`_cleanup` 값이 전이마다 문서 표와 일치. `wasAlive and not canExecute`
  즉시 소진(`H-143`)은 `fn` 안에서 자기 inst를 동기 파괴하는 `t22`에서 cleanup이
  그 자리에서 1회 돎.
- **`H-147` 재현(`t15`)** — 죽은 핸들에서 `Rerun()`: 케이스 1(직전 cleanup이
  `self:Unsubscribe()`) → `fn`이 돌고 고아 cleanup + `_installed = true`;
  케이스 2(해제 뒤 타이머의 `Rerun`) 동일; 케이스 3(파괴된 inst에 bound였던 핸들)
  은 `BindData`에 죽은 gcconn이 남아 있어 `wasAlive`가 참 → 즉시 소진으로 구분됨.
  고아 cleanup은 나중에 재구독/재바인드가 오면 그때 소진된다(영구 누수는 아님) —
  §4 `H-147`의 (a)를 뒷받침.
- **`H-149` 재현(`t19`)** — `o:Subscribe()`의 `error(…, 2)`가 `core10.luau` 내부
  줄을 가리킴, `o:WeakSubscribe()`/`Effect` 진입점은 사용자 줄. (a) 인라인 처방으로
  사용자 줄이 됨(핸들 쪽 대조).
- **`state:Gate` × 재구독 × `EpochMap` 셋(`t16`)** — 7 시나리오: 유보 중 `Peek`은
  `emitEpochMap`을 안 덮음, flush가 배치를 unfold해 하류 `Update`가 한 번에 접음,
  게이트-게이트 중첩에서 중복 원천이 집합으로 접힘, `emit(false)`가 집합을 비움,
  `OffWithoutEmit` 반복에 집합이 단조 증가하지 않음(`H-55`/`H-67`). 우회 둘만
  `H-151`로 올렸다.
- **`_hold` 불변식(`t17`)** — 하류가 상류를 강하게 잡고(`s → c1 → c2`, 하류만
  참조해도 상류 생존) 상류는 하류를 weak로만(하류 참조를 놓으면 GC, 상류는 살아
  있음). 양성/음성 대조.
- **`Source:Set` 같은 값(`t18`)** — 같은 값도 `Revision`을 올리고 emit(확정대로),
  `Blocker` 게이팅 중엔 흡수 집합에 1건으로 접힘.
- **Store 최종형 타입(`ty11`, `luau-analyze`)** — `H-157` 참고. `Of<<T>>` 명시
  인스턴스화 양성/음성(`c3`/`c4`) 정확.
- **레인 C — 9라운드 결정 재실행.** `H-124`(되감기 판정을 `lengthList[i]` 읽기
  앞으로): `d10`/`d11`/`d13`/`d14` 네 케이스 전부 `dispatch10` 위에서 통과(옛
  `dispatch9`와 같은 결과). `H-136`(`reconcile` 배치 `ownsGate`): `d21` — 리스트
  사이클당 `recompute(L)` 정확히 1회, 물리 op이 최소(리오더 `{b,a,c}`가
  move 1 + insert 1), 중첩 Slot 요소의 `Length` 전파·리오더 뒤 `Offset`/
  `getOffsetAt` 값 정확. `H-145`(`bk.indexOfElement` weak-key): `d20` — 옛 Slot을
  언마운트하고 참조를 놓으면 GC 뒤 키가 사라짐, 마운트 중인 키는 `_elements`가
  잡아 유지. **단** Roblox `Instance`가 weak 키일 때의 거동은 CLI에서 실측
  불가(§6).
- **레인 B — `:List` × `Detach` × `KeyGone` × 재등장 × 파괴(`d22`)** — 사라진 키에
  `Detach` → `_detached` 보유·`Length` 감소·물리 extract 1회, 재등장 시 `prev`로
  재마운트(새로 만들지 않음, `indexOfElement` 갱신), `KeyGone`에 새 값 반환은
  error, `destroySlotTree`가 `_detached`까지 dispose, 파괴된 Slot 재마운트 error
  (`_destroyed`, 9라운드 Q2).
- **레인 B — 읽기로만 확인(값 트레이스 없음)**: `SlotHandler` 재발행/교체/A→B→A
  왕복의 `claimOwnerAt`·`unmountSlotTree`·재마운트 경로, `activateList`의
  `_detachCleanup` 바인드/언바인드 짝, `settle` 여덟 분기(`Owned` × `Detach` ×
  `KeyGone`), `rawMove` 규약 4의 `setLength` 재등록, `H-142` `Parent` 금지 +
  `H-146` 루트 예외, `H-138` 숏핸드 우선순위(`StoreBind` → 숏핸드 → `Property`),
  `Tag` 참조 카운트, `Attribute` 그룹 전용 키 + `groupClaimKeys` 순서, `Modifier`
  flatten 역순, `Tween` 3-상태, `OnChange` `v == nil` 얼리리턴, 훅 슈가 `guard`.
  모순은 위 `H-154`~`H-156`뿐.
- **레인 D** — `./scripts/test.sh` **ALL PASS**(`smoke.init`/`mock`/`plugin`,
  `luau-analyze` 클린). 커밋된 M1 코드와 `base/`(`RunInit` 멱등·`AddPlugin` mutate·
  `@self` require)에 어긋남 없음.

## §6 남은 의심 / 못 본 것

**값으로 안 돌려본 것(읽기만)** — 레인 B 중 `New`/`drive` 파이프라인(`H-139`
의사코드 자체), `Dispatch.process` (A)/(B) 분기 위의 `InstanceChildHandler` 이외
말단(`Tag`/`Attribute`/`OnChange`/`PropertyHandler`+`Tween`), `Modifier` flatten
(`luau-test/done/17`이 별도로 있음), `rawMove`/`rawSwap`(base에 의사코드가 없어
`H-29` 규약을 탐사자가 옮긴 것이라 그 자체가 검증 대상이 아님),
`collectLeaves`/`Extract`/`Splice`의 `native*` 인자, `dispose` 가드,
`Debounce`/`Throttle`(7절이 무효화 배너 아래라 옮길 의사코드가 없음),
`Fallback`/`Traceback`(백로그 `H-26` 그대로), `AttributeGroupHandler` 부분 실패
경로, `PostRef` pre-pass.

**로컬에서 실측 불가** — (1) `bk.indexOfElement`의 weak 키가 Roblox `Instance`일
때: `Instance`는 userdata라 weak 키 수거 조건이 Luau 테이블과 다르고
(`Destroy`된 뒤에도 Lua 쪽 참조가 있으면 남음), gcconn 자기순환이 그 참조를 들고
있다 — `d20`은 테이블 키로만 확인했다. (2) `Workspace.SignalBehavior = Deferred`
× `Destroying` cleanup × "지연 창 안에서 재바인드": `_bindDestroying`의
`_unbindDestroying()` 선행이 옛 연결을 끊지만, Deferred 큐에 이미 들어간 옛
`Destroying` 콜백이 새 연결 뒤에 도는 순서는 `ref-plan.md`의 실측 계획에만
있고 여기선 볼 수 없다. (3) `Parent = nil` → `Parent = inst`(`H-154`)가 실제로
`ChildAdded`/`AncestryChanged`를 몇 번 쏘는지.

**남은 의심** — (a) `H-151` (1)에서 캐치업 `Rerun` 뒤 게이트 flush가 같은 원천을
싣고 올 때 `Update`가 접는 건 실측됐지만, **`Ref` dep**(리비전이 `Set`마다
`bnot`으로 감기는 `Epoch`)에서 캐치업과 flush 사이에 `Set`이 한 번 더 오면
접히지 않고 두 번 돈다 — 정상 동작(두 번 바뀌었으니)이지만 `Refresh`가 "변화
있음"만 주고 횟수를 안 주는 게 맞는지는 안 따졌다. (b) `Effect(fn)`(dep 0개)의
`_epochs`가 빈 맵이라 `Refresh()`가 항상 거짓 → 재바인드 캐치업이 `not
_installed`로만 갈리는데, 그 경우 "파괴로 소진 → 재바인드 → 재설치"가 맞는 동작인지
(`OnDestroyed` 슈가가 이 경로로 두 번째 inst에도 cleanup을 달게 됨 — 아마 의도).
(c) `H-148`은 새 증거 없음. (d) 9라운드 §6이 남긴 `H-117`(`Of` 무주석 →
`Source<unknown>`)은 `ty11`에서 주석 있는 경우만 봤다. (e) `luau-test/STATUS.md`의
`rewrite-required/` 스파이크는 이번에 다시 안 돌렸다(상태는 그 파일이 소스).

## §7 레인 C 실행 기록

폴더 `audit/handtrace-round10-reference-impl/`(구성·갱신 내역·옮기며 고친 것은
그 `README.md`가 소스). 참고 구현 `core10.luau`(반응형 코어 — `EpochMap:Peek`,
Observer 3-인자, `Ref` `fn(value, ref)` + `WeakCallback`, `Effect` 생성자
`_blocker`/`fire`/`_bindDestroying`/`Rerun` `H-143` 꼬리/네 진입점 + `resubscribeTail`,
`GateNode` unfold + `emit(commit) -> boolean`, `Blocker:Policy`) /
`dispatch10.luau`(부기 — weak-키 `indexOfElement`, `H-124` `recompute`, 5-인자
`setLength`, Slot 생성자의 `Length`/`Offset`/`_baseObserver`/`_destroyed`,
`materializeSlotTree`/`mountSlotTree`, `raw*`, `:List`/`reconcile` `ownsGate`,
`mountTop` retractor). 전부 `luau <파일>`로 종료 0(2026-08-28 재실행), `ty11`은
`luau-analyze`.

| 스파이크 | 무엇 | 결과 |
|---|---|---|
| `t14_effect_state_matrix` | `EffectHandle` 네 진입점 × 상태 전이표 | 문서 표와 일치(§5) |
| `t15_rerun_dead_handle` | `H-147` 케이스 1·2·3 + 대조군 | 재현(§5) |
| `t16_gate_resub_refresh` | 게이트 × 재구독/재바인드 × `Refresh`/`Peek`/`Update` 7건 | 5건 확정대로, 2건 → `H-151` |
| `t17_hold_gc` | `_hold` 불변식 양성/음성 | 확정대로 |
| `t18_blocker_vestigial_and_set_same` | `Effect._blocker` 판정 횟수 / `Source:Set` 같은 값 | `drop:blocker` 0 → `H-150`; 같은 값 emit 확정대로 |
| `t19_observer_level2` | `H-149` blame 줄 | 재현 |
| `t22_fn_destroys_inst` | `fn` 안에서 자기 inst 동기 파괴(`H-143`) | cleanup 즉시 1회 |
| `t23_store_reserved_runtime` | 그림자 (I)/(II) × `Of("Of")` × `defaults.Of` | → `H-153` |
| `t24_gate_brand_missing` | `GateNode` 브랜드 누락 재현 | 발화 2 → 0 → `H-152` |
| `ty11_store_final` | 최종형 Store 타입 A~H + 빈 Store + `Of<<T>>` | 양성 0건·음성 정확 → `H-157` |
| `d10`/`d11`/`d13`/`d14` `_r10` | `H-124` 되감기 네 케이스(round9 스파이크를 `dispatch10`으로) | 전부 통과 |
| `d20_indexOfElement_weak` | `H-145` weak 키 GC | 확정대로(테이블 키 한정) |
| `d21_reconcile_batch` | `H-136` `reconcile` 배치 + 중첩 Slot 리오더 | 사이클당 `recompute(L)` 1 |
| `d22_detach_keygone` | `Detach`/`KeyGone`/재등장/파괴 | 확정대로 |
| `d23_instancechild_spurious` | `InstanceChildHandler` 같은 값 재발행 | `Parent` 2회 → `H-154` |

옮기며 발견한 것(발견 번호 없음, README에 기록): round7/ref9 참고 구현의
`_recompute`가 `fn`의 첫 인자로 **결과 노드**를 넘기고 있었다(base는 리시버의
lazy 핸들) — 그 스파이크들은 첫 인자를 안 써서 무해했지만 `t16`/`t17`은 그
자리에서 무한 재귀했다. 그리고 `core10.luau`의 `isState`는 `GateNode`를 직접
포함하는데, 그게 곧 `H-152`다.
