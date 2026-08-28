# 구현 전 손 트레이싱 **10라운드** — 결정과 반영 (2026-08-28)

> **이 파일이 무엇인가**: `-round10.md` §4 문항 7건(+ 갈래 없는 넷)에 대한
> 사용자 결정과 근거, 그리고 `base/` 반영 결과. **결정의 소스는 이 파일**이고
> 발견 원문은 `-round10.md`. 사용자가 *"하나하나 같이 보자"*라고 해 이번 라운드는
> 대화형으로 처리한다(배치 회신 대신) — 반영은 전부 정한 뒤 한 번에.

## 진행 표 (상태의 소스)

| 문항 | 무엇 | 상태 |
|---|---|---|
| `H-147` | 죽은 핸들에서 `Rerun()` | ✅ **확정 — 문항의 전제를 뒤집음**: `fn`/cleanup은 자기 생명주기를 못 바꾼다(A). `H-143`도 함께 소멸 |
| `H-148` | `Parent` 거부 문구 | ✅ **전제 정정** — 문구가 아니라 루트 마운트 표면의 부재. `research/existing-mount-plan.md` 신설(`Claim` + `D.Mapper`), `H-146` 루트 예외 폐기, 전용 문구 철회 |
| `H-149` | Observer `Subscribe` 위임과 `level 2` | ✅ **확정 (a)** — `Subscribe`/`Unsubscribe`도 게이트·등록을 인라인, 위임 없음 |
| `H-150` | `Effect._blocker` 죽은 부품 | ✅ **확정 (a)** — 제거, 억제는 Effect 핸들의 `canExecute` |
| `H-151` | 게이트 우회 계약 | ✅ **확정 — (a) 문서화 + `Refresh` 캐치업 폐기**: Effect의 `_epochs`는 emit 수신 때만 갱신, 재바인드/재구독은 초기 설치와 같다 |
| `H-158` | `state:Block(blocker)` 슈가 잔존 (이 대화에서 나옴) | ✅ **확정 폐기** → `state:Apply(blocker)`, 필드 `__apply` |
| `H-159` | 바인드 전 emit 캐치업 | ✅ **확정 — 사용자 제안 `_rerunRequired`(Gate식 홀드)**, `_installed` 흡수, Observer 대칭, `fire`는 `Update → Rerun`만 |
| `H-162` | `Void` no-op export (이 대화에서 나옴) | ✅ **확정** — quad-base export(잎 모듈 `Void.luau`), no-op 클로저 자리는 전부 `Void` |
| `H-163`/`H-164` | `H-159` 반영분에 `/code-review high`가 낸 둘 | ⏳ 판단 대기 — Slot 내부 Observer × 홀드 발화 / 홀드 발화의 `emitFrom == nil` |
| `H-160` | `Destroying` 경로 cleanup `Rerun` | ✅ **확정 (a) → `H-159`로 정정**: `rawRerun`이 `_cleanupRunning`이면 **버리지 않고 `_rerunRequired`로 홀드** + "error 나면 그 Effect는 죽는다" 계약 |
| `H-161` | M5 루트 부착·다중 스크립트 `Claim` | ✅ **확정 (a)** `Claim`을 M5 스코프로; §5-7 다중 스크립트는 미결 |
| `H-153` | Store 예약 이름 런타임 가드 | ✅ **확정 (a)** — 생성자·`Of(name)`에 예약 이름 검사(level 2), 그림자 = store 자신 (I) |
| `H-154` | `InstanceChildHandler` dedup | ✅ **확정 (a)** — retractor 첫 줄 `if nextValue == v then return end` |
| `H-152`/`H-155`~`H-157` | 갈래 없음 | ✅ 반영(`gate-plan.md` 조립 첫 줄 `StateBrand:register` / `ROADMAP.md` M6×3·M11 / `debounce-throttle-plan.md` 7절 `H-32` 문단 / `store-plan.md` 빈 Store 실측 완료) |

## `H-147` — 전제 정정: `fn`/cleanup은 자기 구독을 바꿀 수 없다 (A) — `H-143` 소멸 (`Rerun` 모양은 이후 `H-159`로 다시 바뀜 — 아래)

문항은 "(a) UB / (b) `_everAlive` / (c) `wasAlive` 위치"였는데, 대화 중에 **문제의
뿌리가 `H-143`의 허용 자체**라는 것이 드러났다.

**경위**:
1. 사용자가 *"canExecute 자체가 유저함수인 cleanup 아래 있으면"*을 제안 → 그러면
   생성자 최초 실행이 죽는 문제(감사 2라운드와 같은 함정)를 짚었고, `wasAlive`를
   cleanup 앞에서 잡는 절충을 냈다.
2. 사용자: *"처음부터 rerun 이 're'-run 인데도 초기 실행까지 담당하고 있잖아 …
   rerun 자체에 인자로써 force: boolean? 처럼 주거나, rawRerun(force: boolean) 을
   만들어 생성 시점과 실행 시점에서 이를 명시하는게 맞지 않아?"* → `wasAlive`는
   호출자가 아는 사실("초기 설치냐")을 상태로 추론하던 편법이었음을 인정,
   `rawRerun(self, force)` 분리 + `not force and not canExecute` 게이트 제안.
3. 사용자가 그것도 기각: *"not force 가지고 확인하면 안 될 부분같음. 초기
   설치에서도 본인을 직접 죽이거나 바운딩을 걸거나 할 수 있잖아. … 유저 함수가
   본인을 죽이고 살린다는점 자체가 모순이였다는 문제가 나와. 처음 실행해 unsub
   했는데, 아래에서 sub 해버릴 수도 있지. 이건 의도 동작일까? 게다가 unbind/bind
   는 본인이 못 해. 같은 계층으로 sub/unsub 가 본인이 할 수 있어야할 이유 제공
   자체가 큰 그림에서 무언가 잘못된거 아닐까?"*
4. 갈래 (A) `fn`/cleanup의 자기 구독 변경 금지(leaf와 대칭) / (B) 자기 해제만 허용
   (비대칭 감수)을 올렸고 **사용자 확정 (A)**: *"그런것 같아. 나는 지원 안 할 이유가
   안 보였었는데, 지금 보면 엄청난 모순이네. 나는 너의 권고처럼 A가 맞아보여."*

**확정된 것**:
- **Effect의 생애는 묶은 쪽이 소유한다** — leaf면 Instance, `:Subscribe()`면 그
  호출자. `fn`은 dep을 읽고 부작용을 내고 cleanup을 돌려주는 것까지. leaf가
  `fn` 안에서 unbind/bind를 못 하는 것과 **대칭**.
- **`Subscribe`/`Unsubscribe`/`WeakSubscribe`/`WeakUnsubscribe`는 `self._running`
  또는 `self._cleanupRunning`이면 error(level 2, "cannot change subscription from
  inside fn or cleanup")**. **[반영 뒤 감사 2라운드 정정]** 처음엔 `_running`
  하나로 적었는데 cleanup은 `rawRerun` 밖(`Unsubscribe()`·leaf `Destroying`)에서도
  돌아 그 안의 `self:Subscribe()`가 가드를 지났다(재`Unsubscribe`만 레지스트리
  가드에 걸렸다). 갈래 (a) `_consumeCleanup`이 `_running`을 세움 / (b) UB 문서화 /
  (c) 별도 플래그 → **사용자 확정 (c)** `_cleanupRunning`: *"_running 으로 묶어
  보는건 여전히 별로 괜찮은 이유가 없음. _cleanupRunning 같은걸 넣지 말아야할
  이유가 없는것"* — 한 플래그에 두 뜻을 얹지 않는다.
- **`fn` 안에서 자기 leaf `inst`를 파괴하는 것은 UB**(같은 감사 2라운드 미서술
  항목): `SignalBehavior = Immediate`면 `Destroying` 콜백이 `fn` 도중 동기 발화해
  cleanup이 영구 미소진. 사용자 확정: *"bind/unbind 에 간접 영향을 주는건데, UB
  인게 맞다는 생각."* — `effect-plan.md` `_bindDestroying` 아래 주석.
- **`H-143` 소멸** — `fn` 안 자기 해제 지원 철회. `Rerun` 본체는 원래 모양
  (`_consumeCleanup → fn → 저장`), `wasAlive`도 사후 판정도 없다. 종료 신호는
  다시 **둘**(강한 `Unsubscribe` / leaf 사망).
- **`rawRerun(self, force)` / 공개 `Rerun()` 분리** — "re"-run과 초기 설치는 다른
  일. 공개 `Rerun`은 진입에서 `canExecute` 게이트(죽은 핸들·안 묶인 핸들은
  **정의된 no-op**, `fire`와 같은 규칙), 생성자는 `rawRerun(self, true)`로 게이트만
  건너뛴다. (A)에서는 `fn`이 전이를 못 일으키므로 `force`가 건너뛰는 것은 정확히
  "아직 안 묶임" 하나. 사용자 확인: *"unsub 뒤에 오는 rerun 은 그냥 실행 안
  되는게 원래 정상적 형태"* — 맞다.
- **원샷("딱 한 번 처리하고 끝")은 지원 목록에서 빠진다** — 소유자가 밖에서
  `Unsubscribe`하거나, 나중에 `Once`류 슈가로 별도 결정. 코어에 넣지 않는다.

**반영 대상**: `base/effect-plan.md`(`Rerun` 의사코드 → `rawRerun`/`Rerun`, `H-143`
관련 서술 전부 — 꼬리 분기·"종료 신호 셋"·"`fn` 안 허용 호출" bullet·`self`를 주는
덕에 bullet, 네 진입점에 `_running` 가드, 실측 bullet), `base/lifecycle-pattern.md`
(포인터), `ROADMAP.md` M2 `Effect` 체크박스, `conventions.md`(원칙 사례로 추가 여부는
반영 시 판단), `-round9-followup.md` `H-143` 절에 소멸 배너, `-round9.md` 요약 표
`H-143` 행.

## `H-148` — 전제 정정: 문구 문제가 아니라 루트 마운트 표면의 부재 → `Claim` + `D.Mapper` (research 신설)

권고 (a)(전용 문구 철회)를 올렸더니 사용자가 더 큰 공백을 짚었다: *"slot 은
물리 장치에 mount 할 방법이 거의 존재하지 않음. … PlayerGui 가 상위에 있고
거기에 GUI 를 여럿 바운딩 해야해서 `Slot { Shop{} … }` 하는게 안 될것 같은
느낌이 듦. 이건 Parent 이상의 문제인것 같아."* → 이미 있는 트리를 quad가
소유하는 `Claim(inst, D.Mapper.<Class> "Name" {…})` 제안(원문·확정·갈래 전량은
`research/existing-mount-plan.md`).

**확정된 것**: 방향 자체 / 디스크립터는 `D.Mapper`에(`D.Frame`에 직접 얹지 않음)
/ `Claim` DFS(내려가며 해석 → 자식부터 `drive`)는 derive 위의 한 겹 / 부기 대상
자식은 전부 매핑, 숏핸드(`UI*`)는 부기 밖 — quad가 직접 쓰거나 실제 객체로
매핑하거나 / 이름 중복·부재는 UB + debug 모드 `seen` 검사 / `nativeFindChild`
프로바이더 op, 순회는 quad-base / 다중 quad 한 트리 UB / M5 스코프(`H-161`로 당김).
**따름**: 전용 문구 **철회**(일반 매치 실패 그대로), `H-146` (a)의 "루트는 밖에서
`.Parent =`" **폐기**(루트가 quad 소유). `H-142` 키 금지는 그대로.
**미결**(개수는 그 research 문서 §5가 소스)은 다음 배치 문항.

## `H-149` — Observer `Subscribe`/`Unsubscribe`도 인라인 (a)

**사용자 확정**: *"a 로 가는게 맞는듯. weak 나 아닌거나 줄 차이가 그리 안 커서,
분리할 큰 이유가 없음."* — `Observer:Subscribe`는 `self:WeakSubscribe()`에
위임하지 않고 게이트(`canBound`, `error(…, 2)`)·플래그·약한 등록·강한 킵을 자기
안에 펼친다. `Unsubscribe`도 같은 이유로 `self:WeakUnsubscribe()` 위임을 풀어
양쪽 레지스트리 삭제를 직접 한다(콜론 위임 자체를 남기지 않는다 — `H-144` (b)의
교훈). `lifecycle-pattern.md`의 *"게이트는 한 번만 돈다 — `Subscribe`가
`WeakSubscribe`에 위임하므로"* 문장은 "각 진입점이 자기 게이트를 한 번 돈다"로.
`EffectHandle`의 넷과 모양이 같아진다(거기에 `H-147` (A)의 `_running` 가드가
하나 더 붙는 것만 다름 — Observer엔 `_running`이 없다).

**반영 대상**: `base/lifecycle-pattern.md` Observer 네 진입점 의사코드 + "게이트는
한 번만 돈다" bullet, `base/effect-plan.md`의 `EffectHandle` 블록 머리 주석(Observer
위임 서술 참조 부분).

## `H-150` — `Effect._blocker` 제거 (a)

사용자가 확인한 전제: *"canExecute 와 별개로 처음 observer 생성에는 callback 이
실행되어야하는게 맞잖아. … 그러니까, Effect 의 canExecute 를 보겠다는거지? 그럼
그건 맞는것 같아."* — 두 층이 다르다: 내부 Observer/`Ref` 콜백의 **설치 발화는
그대로 일어나고**(그 계약 불변), 그 콜백이 부르는 `fire`의 첫 줄
`canExecute(self)`의 `self`가 **Effect 핸들**이라 생성자 안(아직 안 묶임)에선
거기서 흡수된다. `_blocker`는 같은 흡수를 한 번 더 하려던 장치라 어떤 경로에서도
판정에 닿지 않는다(실측 `t18`). `H-147` (A)로 `fn`이 생성자 안에서 자기를 묶을
수도 없어졌으니 "생성자 구간 = 안 묶임 = `canExecute` 거짓"은 불변식.

**확정**: `_blocker` 필드·`On()`/`OffWithoutEmit()` 제거. 생성자 주석은 *"등록
즉시 1회는 Effect의 `canExecute`가 막는다"*로. 7라운드 `H-58`의 지시(*"모든
옵저버와 callback 등록에 있어서 이를 수행해야할 것임"*)는 그 전제("등록 즉시
1회가 `Rerun`에 닿는다")가 성립하지 않았던 것으로 정정 배너.
**반영 대상**: `base/effect-plan.md` 생성자 의사코드·"확정 구조" 절·`H-58` 문단·
필드 목록, `base/gate-plan.md` 7번(`_installing` 잔재), `ROADMAP.md` M2 `Effect`
체크박스의 "선행: `Blocker` 기본 메커니즘" 문구(Effect 자체는 이제 Blocker 불필요
— `Blocker.luau` 선행 요구는 `GateNode`/Slot 쪽만).

## `H-151` — 게이트는 유보만 한다; Effect는 emit 받을 때만 `_epochs`를 갱신 (`Refresh` 캐치업 폐기 — "캐치업 없음"은 이후 `H-159`의 홀드로 대체, 아래)

**사용자 확정**: *"해당 우회는 더 크게 보면, 처음부터 Effect 가 Rerun 되는
경로라서 그건 맞아. 그리고 Observer 에서 받은 emit 의 epoch|{epoch:boolean} 를
받는 시점은 emit 되어야하는 시점이 맞기도 하지. 우린 애초에 Refersh 를 할 필요가
없는거야. 재진입은 초기 설정해주는 요소이고, 그건 처음 생성할때랑 같은거야. 사실
처음 생성할 때에도 Block 되어있던게 나중에 다시 들어오는 경로가 있어. 그 경우도
그냥 재실행 해주지. 또 observer 도 마찬가지야. block 은 단지 유보만 해줄뿐이라서.
- Effect 도 observer 랑 똑같게, 중간 state 랑 똑같게, emit 받을때에만 epoch 맵을
업데이트 하면 돼. 계약 추가로 끝나는 일로 보여"*

**확정된 것**:
- **계약(문항의 (a))**: 게이트는 emit 경로만 미룬다. 재바인드/재구독 캐치업과
  게이트 없는 형제 dep의 emit은 게이트를 거치지 않고, 그때 `:Get()`은 최신값.
  유보됐던 emit이 나중에 풀려 들어오면 그냥 재실행 — 생성 직후 유보분이 들어오는
  것과 같은 경로.
- **`_epochs`는 `fire`의 `Update(from)`에서만 갱신** — Observer·중간 State와
  같다. `_bindDestroying`·`resubscribeTail`의 `_epochs:Refresh()`와 `depsChanged`는
  **폐기**. 캐치업은 `if not self._installed then self:Rerun() end` 하나(초기 설치와
  같은 뜻 — 소진돼 있으면 다시 설치). `H-144`의 "`Refresh` 먼저" 하위 결정과
  그 단축평가 캐비엇(`ROADMAP.md`·`lifecycle-pattern.md`·`ref-plan.md`에 오늘 넣은
  두 줄 형태)은 전부 이 결정으로 **소멸**.
- 따름: 죽어 있는 동안 떨어뜨린 emit은 다음 emit 때 리비전 차이로 잡힌다 —
  Observer와 같은 정도의 "캐치업 없음"이고 계약으로 적는다. 재구독 뒤 게이트
  flush가 같은 값으로 한 번 더 도는 것(`H-144` 재트레이싱의 케이스)은 **허용**
  (유보가 풀리는 정상 재실행).
- `EpochMap:Refresh`는 State의 `rawInvalid == false` 경로(`state-epoch-plan.md`
  §4)에만 남는다 — Effect 소비자 삭제.

**반영 대상**: `base/effect-plan.md`(`_bindDestroying`·`resubscribeTail`·`H-65`
캐치업 서술·`H-144` 블록 주석), `base/gate-plan.md`(계약 문장),
`base/debounce-throttle-plan.md` 11절, `base/lifecycle-pattern.md` 357행 주석,
`base/ref-plan.md` 244·284·443행(`Refresh` 전제 서술 — 284행의 "다음 `Refresh()`
때에야" 추론은 재검토), `ROADMAP.md` M2·M6 캐치업 문구, `-round9-followup.md`
`H-144` 절에 소멸 배너.

## `H-158` — `state:Block(blocker)` 슈가 (이 대화에서 나옴, 미결)

사용자: *"`:Block` 은 이제 없는거 아냐? Apply(Blocker) 이긴 할꺼야 (표면은
:Gate 만 남아 Blocker 는 Apply 슈거와 Policy 를 주는 프리미티브)"* — 확인 결과
`base/blocker-plan.md`에 `state:Block(blocker)`가 `state:Gate(function(emit)
return b:Policy(emit) end)` 위의 슈가로 **아직 있다**(60·94·163·178·207행).
갈래: (a) `:Block` 폐기, Blocker가 `state:Apply(factory)` 프로토콜을 만족해
`state:Apply(blocker)`로 / (b) `:Block` 유지. **권고 (a)** — 동사 하나가 줄고
"Blocker = Policy를 주는 프리미티브 + Apply 슈가"로 뜻이 하나. 반영 시
`blocker-plan.md`·`gate-plan.md`·`debounce-throttle-plan.md`의 `:Block` 예시 전부.

## `H-153` — Store 예약 이름 런타임 가드 (a)

**사용자 확정**: *"나도 a 동의."* — 생성자의 `isSource` 순회에 `if RESERVED[k]
then error(…, 2) end`, `store:Of(name)`에 같은 검사. `H-122` 화이트리스트와 같은
자리·같은 논거(조용히 받고 엉뚱한 자리에서 죽는 것을 fail-fast로). 부수로
스케치의 "그림자 테이블"은 **store 자신**(I)으로 못박는다 — `store.key`가 평범한
레코드 필드라는 계약과 맞고, 메소드는 `__index`에 있어 `Names()`가 안 센다.
`RESERVED`는 메소드 이름 집합(`Of`/`Names`/… — 구현 시 `__index` 테이블의 키에서
자동 도출하면 두 곳에 안 적어도 된다, 권고).

**반영 대상**: `base/store-plan.md` 구현 스케치·`Of` 절·`__reservedCheck`
주석(동적 키는 런타임 가드가 맡는다고 명시), `ROADMAP.md` M2 Store 체크박스.

## `H-154` — `InstanceChildHandler` retractor에 같은 값 dedup (a)

**사용자 확정**: *"a 동의. … 간단한 dedup 이고 말단 핸들러가 v 를 정확히 알아서
retract 가 정확히 해소되는 부분이 맞네."* — retractor 첫 줄에 `if nextValue == v
then return end`(`SlotHandler` 동형). 같은 값 재발행에 `Parent = nil → inst`와
`recompute` 2회가 사라진다. **반영 대상**: `base/dispatch-core-plan.md` `H-134`
문단, `ROADMAP.md` M5 `InstanceChild.luau` 체크박스.

## 반영 기록 (2026-08-28)

`base/`: `effect-plan.md`(`rawRerun`/`Rerun` 분리, `_blocker` 제거, `Refresh` 캐치업
폐기, 네 진입점 `_running` 가드, `H-143` 관련 서술 전부) / `lifecycle-pattern.md`
(Observer `Subscribe`/`Unsubscribe` 인라인, 캐치업 주석) / `gate-plan.md`(7번 정정,
조립 첫 줄 브랜드, "계약 — 게이트는 emit 경로만 미룬다" 절 신설) /
`debounce-throttle-plan.md`(7절 `H-32` 문단, 11절 `Effect`) / `ref-plan.md`(`Refresh`
전제 셋) / `store-plan.md`(그림자 = store 자신, 예약 이름 가드 둘, 빈 Store 실측) /
`dispatch-core-plan.md`(`InstanceChildHandler` dedup) / `bind-system-plan.md`(전용 문구
철회, 루트 예외 폐기 배너) / `slot-plan.md`(각주 둘). `archive/existing-instance-bind-rejected.md`
부활 배너. `ROADMAP.md` 배너·M2 `Effect`/`GateNode`/Store·M5·M6×3·M8·M11·백로그.
`-round9-followup.md`/`-round9.md`의 `H-143`/`H-144`/`H-146` 소멸·정정 배너.

**남은 미결**: `H-158`(`state:Block` 슈가 폐기 → `state:Apply(blocker)`, 권고만) —
`question.md`에; `research/existing-mount-plan.md` §5 갈래 — 다음 배치. (이후 `H-158`은 확정, 아래 절.)

## 감사 루프 (2026-08-28, 10라운드 반영분)

`quad-doc-auditor` 한 턴에 하나, diff 범위, 각도 교체. 새 발견 3→5→2→3→1→**0**
(6라운드에서 수렴). 라운드별: 1 문구 잔존(ROADMAP 필드 목록 `_blocker` / 콜론 위임
현재형 둘 / `rawRerun` 선언 순서) · 2 의미론(README `effect-plan.md` 행 /
`StateBrand:add`→`register` / 예약 이름 도출 권고와 팬텀 필드 모순 /
**`_running` 가드가 `Unsubscribe`·`Destroying`의 cleanup을 안 덮음 → 사용자 결정
`_cleanupRunning`** / `fn` 안 자기 leaf 파괴 미서술 → UB) · 3 수정분 재검토(`Store:Of`
스니펫의 `shadow` 업밸류 / UB 괄호) · 4 전체 diff(`gate-plan.md` 새 절의 "4절"
인용에 문서명 / 인용문 한 구절 / README archive 행 부활 포인터) · 5 수렴
확인(`CLAUDE.md` 볼드 짝) · 6 형식·라벨 정합 **0건**.

## `/code-review high` (2026-08-28, 10라운드 반영분 + 감사 6라운드 뒤)

10건. **일곱 반영**, **셋은 새 메커니즘·기존 결정 변경이라 문항**(`-round10.md`
`H-159`~`H-161`, `question.md`).

반영한 일곱:
1. `bindLifetime` 경로에 (A)의 강제가 없었다 — `fn` 안 `New "Frame" { self }`로
   자기를 leaf에 묶을 수 있었다. `_bindDestroying` 첫 줄에 `isRunning` 가드.
2. `guardNotRunning` 헬퍼 안의 `error(…, 2)`가 헬퍼 호출 줄(quad 내부)을 가리킴
   (`H-104`, `H-149`와 같은 이유) — 술어 `isRunning`만 헬퍼로, `error`는 다섯 본문에
   인라인(`level 3` 선례를 만들지 않음). `lifecycle-pattern.md`의 *헬퍼로 빼도 된다* 문장에
   단서.
3. `RESERVED`가 어디에도 정의되지 않았고 예약 이름 셋이 네 곳에 리터럴 — `Of` 절에
   `local RESERVED = {…}` 단일 소스, 나머지는 가리키기만.
4. `H-154` 서술 정확화 — dedup이 없애는 건 물리 detach/attach와 `recompute` **1회**
   (2→1); process 쪽 skip은 옛 값을 몰라 안 둔다(`SlotHandler`의 `claimOwnerAt`과
   다른 점 명시).
5. 산문 ↔ 의사코드 모순 — *기존 플래그 재사용, 새 상태 없음* / *재`Unsubscribe`는
   레지스트리 가드* / *`fn` 안 직접 호출은 게이트하지 않는다* / `lifecycle-pattern.md`의
   *`_running` 가드*만 — 전부 `_cleanupRunning`·진입 게이트 반영.
6. `-round9-followup.md` 진행 표 행·`H-146` 절에 2026-08-28 소멸 표시, `todos.md`의
   *`Refresh` 먼저*·*뒤집힌 것 둘*→셋, *갈래 6개* 다섯 곳 → 개수는 §5가 소스.
7. stale 문장 — `effect-plan.md`의 *게이트가 아니라 `Blocker`를 쓰는 이유* / 포탈
   근거를 *`H-64` 캐치업*으로 적은 것(재마운트는 `_installed` 참이라 캐치업이 아예
   없다) / `source-state-plan.md`의 *구현이 한 벌*(위임 아님으로 정정).

## `H-158` — `state:Block(blocker)` 폐기 → `state:Apply(blocker)` (확정)

**사용자 확정**: *"H158은 폐기로 하자. 내가 이미 그렇게 정했었는데, 전파가 안 된
부분이라서. 이제 Compute 와 유사하게 Gate 만 놓일 뿐, Apply 로 Blocker 처리가 가능함.
왜냐면 펑터와 적용성펑터를 전부 허용하니까 ( map|{...map} ) 키는 __apply 로 하기로
했던거로 기억중임."* — `source-state-plan.md`의 "`state:Apply(factory)`" 절은
애플리커티브 팩토리를 "지정된 필드"로 받되 이름은 "구현 시"로 열어뒀었다 → 이
발언으로 **`__apply`**. `Blocker.__apply = function(state) return state:Gate(function(emit)
return self:Policy(emit) end) end`. 반영: `blocker-plan.md` 배너·API·이름 절,
`gate-plan.md`·`dispatch-core-plan.md`·`debounce-throttle-plan.md`·`ROADMAP.md`·
`README.md`의 `state:Block` 전부 치환, `qa-round2.md`의 절 인용.

## `H-160` — `rawRerun`은 `_cleanupRunning`이면 버린다 (a) + error 계약 상향 (→ `H-159`로 "홀드"로 정정. 문별 동작: `Rerun`/`fire` 경로는 조용히 홀드, 네 진입점·`_bindDestroying`은 error)

**사용자 확정**: *"H-160 는 a 동의. 그런데 이로 인해 cleanup 이 error 를 내면
cleanupRunning 플래그가 풀리지 않는 문제가 날듯. 모든 재 진입이 막히는건데, 문제 될
것은 없어보이나 문서화가 필요한것 같아. 한번 죽는게 나오면 Effect 가 전부 죽는다가
계약으로 상향되어도 문제는 없는듯. 이미 _running 도 그러한 제약을 받으니까."* —
`effect-plan.md` "error 시 UB" bullet을 **"그 Effect는 죽는다"** 계약으로.

## `H-161` — `Claim`을 M5 스코프로 (a); §5-7은 미결

**사용자 확정**: *"H-161 는 확인. M5 스코프로 올라가도 될것으로 보임."* — `ROADMAP.md`
M5 체크박스·`research/existing-mount-plan.md` 헤더·§5-6. 다중 스크립트/루트 컨테이너
(§5-7)는 답이 없어 미결 유지.

## `H-159` — `_rerunRequired` 홀드 플래그 (사용자 제안, 확정) — `_installed` 흡수, `H-160` 정정

`/code-review`의 권고 (a)("묶이는 시점 1회 `Refresh` 복원")를 올렸더니 사용자가
다른 모양을 냈다: *"observrer 는 생성과 동시에 바운딩 처리가 되는게 일반적임. 그리고
이건 또한 observer 에도 유사한 문제가 있는 부분으로 보임 - 바운딩 전에 바뀌다가,
바운딩 되면 그대로 다 씹힘. 따라서 Gate 와 유사하게 _rerunRequired 정도가 필요한듯.
언바운딩 상태에서 이것을 true 로 만들지 관리. canExecute 가 거짓이면 모두 홀드하는게
맞아보임. 각 둘의 정의는 '초기에 한번은 불러주고, 각 변경에 불러주겠다' 인데(바인드
빼고 보면) 바인드가 들어오면서 각 변경에 아에 스킵하는 경우가 생겨났다는 의미."*

**메인 세션 판단**: `Refresh` 복원보다 낫다 — 갱신 경로는 `fire`의 `Update` 하나로
유지(`H-151` 계약 그대로)하고, 실행 불가일 때 *버리는 대신 홀드*한다. Gate의 유보와
같은 그림이되 Effect는 "한 번 다시 돌면 된다"라 불리언 하나.

**대화로 다듬어진 것 넷**:
1. **`_cleanupRunning` 중의 변경도 홀드** — 처음 메인 세션이 "cleanup 중 `dep:Set()`은
   `_epochs`에 반영되니 버려도 된다"고 했는데 사용자가 정정: *"변경을 '아에 보고
   안함' 이라는 경로가 생김. State<Effect> 형태로 포탈을 만들었다고 가정하면, cleanup
   도중에도 여전히 _rerunRequired 는 셋업되어야함. 안 그러면 다음 바운딩에 최신값
   측정이라는 목표를 잃거든."* → `H-160`의 "버림"도 홀드로 정정. 세 상황이 갈린다:
   `fn` 실행 중 → `_pending`(같은 루프) / 실행 불가(안 묶임·죽음·cleanup 중) →
   `_rerunRequired`(다음 바인드) / 그 외 → 즉시. `_pending`과 `_rerunRequired`의 분리는
   사용자 *"완전 동의"*.
2. **`fire`는 `Update → Rerun`만** — 사용자: *"self._cleanupRunning 확인이 아래에
   있다면 … fire 는 그냥 rerun 을 호출해도 될것"*. 상태 판정은 `rawRerun` 한 곳.
3. **`_installed` 폐기 → `_rerunRequired`로 통합** — 사용자: *"rerun 의 force 가
   self._rerunRequired = true 하는것과 같은 동작을 낼것으로 보임. … '초기실행' 과
   '실행 안하던 중에 바뀐것' 이 사실 같은 요소"*. `_installed`는 그 플래그의
   부정형이었다. 세워지는 곳: 생성자·`_consumeCleanup`·`rawRerun` 홀드 / 내려가는 곳:
   `rawRerun`이 `fn`을 실제로 돌리는 자리 하나. **`force`는 시점 예외 하나만** —
   사용자: *"force 는 딱 하나의 역할을 해. canExecute 를 무시하고도 호출할 수 있냐.
   오직 그게 전부야."* 초기 실행을 바인드로 미룰 수 없다는 결정(순차 처리)은 유지.
4. **`fire`의 `from == nil` 가드는 유지** — 사용자가 *"ref<...> 가 Frame->nil 가는
   경로를 막을 이유가 없지 않나?"*라 물었는데 그건 오해: `from`은 값이 아니라 출처
   `Epoch`라 `Ref` 경로에선 항상 `ref` 객체이고, `nil`은 내부 Observer의 설치 발화
   (`emitFrom == nil`)뿐 — `Update(nil)`이 정의돼 있지 않아 걸러야 한다(2026-08-21
   `/code-review`가 잡았던 자리). 주석에 그 구분을 명시.

**Observer 대칭**: 전파 루프가 `canExecute(observer)` 거짓이면 `_rerunRequired`를 세우고,
`bindLifetime`·`Subscribe`·`WeakSubscribe`가 그 플래그를 보면 1회 발화(`emitFrom = nil`,
설치 발화와 같은 모양). 실효 범위는 "구독자 집합엔 있지만 아직 안 묶인" 창.
**[반영 뒤 감사 3라운드]** Observer의 "등록 시점 즉시 1회 실행"(2026-08-07 확정)은
생성자가 무조건 하는 것이라 이 플래그와 **별개** — Observer의 `_rerunRequired`는
거짓으로 시작한다(Effect는 생성자가 참으로 세우고 `force`로 즉시 돌리는 것과 대비).
감사자가 "초기화가 없어 한 번도 안 돈다"로 읽을 수 있음을 짚어 두 문서에 명시.

**반영**: `effect-plan.md`(`fire`·생성자·`rawRerun`·`_consumeCleanup`·`_bindDestroying`·
`resubscribeTail`·필드 목록·캐비엇·포탈 근거·`H-65` 문단), `lifecycle-pattern.md`
(bindLifetime Observer 분기·Observer `Subscribe`/`WeakSubscribe` 꼬리·주석),
`source-state-plan.md` 전파 루프, `ROADMAP.md` M2 넷·M6, `README.md`.

## `H-162` — `Void` no-op export (확정)

사용자: *"지금 상황에서 의도적으로 클린업이 없는 Void 함수를 많이 만들게 될 것으로
보이는데, 이걸 quad-base 에서 Void = function()end 를 제공하는게 편해보임."* —
quad-base가 단일 no-op 함수 `Void`를 export(quad-roblox 핸들러도 쓰므로 공개),
no-op 클로저를 돌려주는 자리(숏핸드 retractor 등)는 새 클로저 대신 `Void`. 사용자
Effect `fn`이 `return Void`로 "cleanup 없음"을 명시하는 것도 자연히 허용(반환 안 하는
것과 동일 취급). 반영: `dispatch-core-plan.md` 반환값 규칙, `ui-shorthand-plan.md` 둘,
`ROADMAP.md` M2 공통 기반.

## 감사 루프 (2026-08-28, `H-158`~`H-162` 반영분)

새 발견 7→6→1→**0**(4라운드에서 수렴). 1 문구 잔존(`Block` 현재형 / `__apply` 전파 /
`Void` 9곳 / "`fire`의 첫 줄 `canExecute`" stale 4곳 / `architecture.md` `Void` 자리 /
session 후속 절) · 2 의미론(**`_rerunRequired` 상태 기계 자체는 모순 없음**; debounce
`__apply` / `Void` 5곳 더 / session-summary 후속 / `init.luau` 모호 / gate 계약 절
포인터 / Observer 필드 목록 신설) · 3 수정분 재검토(Observer 생성자 1회 실행이
플래그와 별개임을 명시 — 감사자의 오독 가능성) · 4 수렴 **0건**.

## `/code-review high` (2026-08-28, `H-158`~`H-162` 반영분 + 감사 4라운드 뒤)

10건. **여덟 반영**, **둘 문항**(`H-163`/`H-164`, `-round10.md` §4).
반영: `__apply` 호출 규약(메소드형 `factory:__apply(state)`, 에이전트 배선) /
`Void`는 잎 모듈 `Void.luau`(최상위 `init.luau`에 두면 순환 require) / Observer 생성자
순서 `fn` 1회 → `_subs` 삽입 / `gate-plan.md` 계약 절 괄호 정정 / `effect-plan.md`
stale 셋(`Blocker` 억제·"`fire` 첫 줄"·"죽은 핸들은 no-op") / `ROADMAP.md` M2 `Rerun`
no-op → 홀드 / `lifecycle-pattern.md`의 *조용히 건너뜀* → 홀드 / "M5 이후" 잔존 셋 /
followup 절 제목 포인터·개수.
