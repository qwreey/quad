# M2 구현 **11라운드** — 발견 원문 + 배치 문항지

> **이 파일이 무엇인가**: **[2026-08-28 신설]** M2 자율 구현 구간
> (`-round11-brief.md`가 규약)에서 나온 발견 전부. 앞 라운드들과 달리 **종이
> 트레이싱이 아니라 실제 코드를 옮기고 돌리다 나온 것**이다. 번호는 `H-165`부터
> (10라운드 후속이 `H-164`까지 썼다).
>
> **갈래 표기**(규약 §2): **①** 자율로 고침(같은 커밋에서 `base/`+코드) /
> **②** §4 표에 쌓아 배치 회신 대기 / **③** 즉시 중단·보고.
>
> **상태의 소스는 이 파일 자신** — 요약 표의 상태 열이 최신.

## 요약 표

| 번호 | 갈래 | 단위 | 심각도 | 한 줄 | 상태 |
|---|---|---|---|---|---|
| `H-165` | ① | 1 | 🟡 | `quad-types`에 `export type`을 더하면 pesde shim이 그걸 모른다 — `pesde install` 재실행 없이는 `QuadTypes.Ref`가 Unknown type | ✅ 반영(`project-setup-plan.md`) |
| `H-166` | ① | 1 | 🟢 | `Ref.Revision` 초기값을 어느 문서도 안 정했다 | ✅ 반영(`ref-plan.md`: `0`) |
| `H-167` | ① | 1 | 🟡 | 옮기며 `Ref<T>(default: T?)`/`.Value: T?`로 바꿔 놓았다 — 문서는 `Ref<T>(T)` 단일 파라미터, nil은 `Ref<<T?>>(nil)`로 | ✅ 코드를 문서에 맞춤(감사 2라운드) |
| `H-168` | **②** | 1 | 🟡 | `Ref<T>(T)`면 무인자 `Ref()`가 strict에서 TypeError("expects 1 argument") — 그런데 `ref-plan.md`/`lifecycle-hooks-plan.md`/`debounce-throttle-plan.md`가 `Ref()`/`PreRef()`를 관용구로 가르친다 | ✅ (a) 사용자 확정 — 시그니처 유지, 관용구는 `Ref<<T?>>()`로 읽음(`ref-plan.md` "제네릭 시그니처") |
| `H-169` | **②** | 1 | 🟡 | `:Set` 블록이 스냅샷 콜백에 닫힌 인자 `value`를 넘겨서, 콜백 안 재진입 `ref:Set(new)` 뒤 남은 콜백이 **옛 값**을 받는다 — 문서 블록 그대로인데 문서의 "옛 값이 보이는 창이 없다"와 어긋남 | ✅ 사용자 확정(권고 (a) 아님) — 순회가 자기 리비전이 바뀌면 놓고 후행 `Set`이 전부 호출(`spec.ref` 11) |
| `H-170` | **②** | 1 | 🟡 | `coroutine.resume(k, self)`는 에러를 올리지 않는다 — 대기자 안의 에러·죽은 thread resume이 `:Set`에서 조용히 삼켜짐. `ref-plan.md` *"나중에 `coroutine.resume`이 에러남"*은 사실이 아님 | ✅ (a) 사용자 확정 — 즉시 반환된 실패만 `error(err, 0)`(`spec.ref` 10) |
| `H-171` | ① | 1 | 🟡 | mock lazy claim: Destroy된 inst에 다시 bind하면 GC 전엔 죽은 gcconn 재사용, GC 뒤엔 새 Connected gcconn — 결과가 GC 타이밍에 따라 갈림 | ✅ mock: 죽은 inst의 새 gcconn은 즉시 Disconnect(`spec.lifetime` 6b) |
| `H-172` | ① | 1 | 🟡 | mock `Destroy`가 자손을 안 죽이고(조상 파괴 계약 검증 불가), `Parent` 변경 시그널이 연결 해제 뒤라 관측 불가, 재귀 Destroy 무한 루프 | ✅ mock: Destroying → Parent nil → 자손 Destroy → 연결 해제, 이중 Destroy no-op(`spec.lifetime` 6c) |
| `H-173` | ① | 1 | 🟢 | `ROADMAP.md` M7 체크박스·`tween-plan.md` 352가 `isTween`/`TweenBrand`를 `Tween.luau`에 둔다고 아직 서술(감사 3라운드가 두 곳만 고침) | ✅ 반영 |
| `H-174` | **②** | 1→2 | 🔴 | 생명주기 4종은 **`New()` 인스턴스마다 다른 필드**(이 단위가 그렇게 만들었고 `spec.lifetime` 8이 고정)인데, 단위 2·3의 `base/` 의사코드(`Observer:_receive`의 `canExecute(self)`, `Subscribe` 넷의 `canBound(self)`, `EffectHandle.rawRerun`)는 **자유 함수**로 부른다 — `Observer.luau`/`Source.luau`가 자기 인스턴스의 필드에 어떻게 닿는지 어느 문서도 안 정했다. 결정 없이는 단위 2의 `_receive`를 쓸 수 없다 | ✅ (a) 사용자 확정 — 팩토리형, `module.canExecute(self)`를 발화 시점에 늦게 읽음(`lifecycle-pattern.md`·`module-lifecycle-plan.md`·`ROADMAP` 반응형 본체) |
| `H-176` | ① | 2 | 🟡 | `:Compute`의 trailing deps를 타입팩 `D...`로 좁히는 선언은 strict에서 콜백 dep 추론이 깨져 정상 호출까지 막힌다(스파이크 15가 "미검증"으로 남긴 자리) | ✅ `...any` + 콜백 주석으로 확정, `source-state-plan.md` 실측 기록 |
| `H-177` | ① | 2 | 🟢 | `InitSource`/`InitStore`가 `State.implFor`만 불러 `New()`의 `RunInit` 순서에 의존했다 — `module-lifecycle-plan.md`는 "각 `InitXxx`가 `require`처럼 멱등하게 자기 의존성을 당겨온다"로 확정 | ✅ 각 Init이 `module:RunInit(dep)`를 직접 호출(감사 3라운드) |
| `H-181` | ① | 2~4 | 🔴 | 인스턴스별 임플을 `module` 키의 weak-key 맵에 뒀는데 값(임플 클로저)이 키(`module`)를 캡처 — Luau엔 ephemeron이 없어 `Quad.New()`마다 영영 안 죽고 그 강한 레지스트리의 Observer/Effect 그래프까지 핀됨 | ✅ 임플을 `module._impl`(비공개 필드 — `H-174` (a)안 원문 모양)에, `spec.init` 2 |
| `H-182` | **②** | 3 | 🟡 | leaf `Destroying` 콜백이 cleanup을 소진한 뒤에도 같은 파동 안에서는 `canExecute`가 참(gcconn은 마지막에 끊김) → 파동 후반의 dep 변경이 죽는 leaf 위에서 `fn`을 다시 돌리고 아무도 소진 안 할 cleanup을 저장 | §4 대기 (`-- TODO(H-182)`) |
| `H-183` | **②** | 3 | 🟡 | Observer 설치 발화 안에서 `self:Subscribe()`/`bindLifetime(inst, self)`를 부르면 `_catchUp`이 `fn`을 중첩 재생하고 생성자가 "already subscribed"로 죽음 — Effect의 `isRunning` 가드(`H-147`)에 해당하는 것이 Observer엔 없음 | §4 대기 (`-- TODO(H-183)`) |
| `H-184` | **②** | 1·3 | 🟡 | `bindLifetime`이 부기를 커밋한 **뒤** `_bindDestroying`의 `isRunning` 가드가 던지면 Effect가 묶인 채(`canExecute` 참) `Destroying` 연결 없이 남음 — 순서는 `lifecycle-pattern.md` (1) 그대로라 quad-roblox도 상속 | §4 대기 (`-- TODO(H-184)`) |
| `H-185` | **②** | 3 | 🟢 | `EffectFn`은 `-> ...(() -> ())` 팩(H-95)인데 런타임은 첫 반환만 cleanup으로 저장 — `return stopA, stopB`가 타입은 통과하고 `stopB`는 조용히 버려짐 | §4 대기 (`-- TODO(H-185)`) |
| `H-186` | **②** | 3 | 🟡 | 교차 인스턴스 dep(`A.Effect(fn, B.Source(0))`)을 막지도 정의하지도 않음 — dep의 백엔드가 게이팅하고 에러가 엉뚱한 인스턴스를 가리킴; `architecture.md` 13번은 다중 `New()`를 지원으로 서술 | §4 대기 (`-- TODO(H-186)`) |
| `H-187` | **②** | 3·4 | 🟢 | `quad-types`의 새 타입 별칭 이름 넷(`ObserverFn`/`EffectFn`/`GateEmit`/`GateSetup`)이 `base/`에 없는 이름 — 시그니처는 문서 그대로, 이름은 구현이 붙임 | §4 대기 (`-- TODO(H-187)`) |
| `H-188` | ① | 4 | 🟡 | `state:Gate(setup)`가 검증 실패로 error할 때 반쯤 만든 노드가 상류 `_subs`에 남아 다음 `Set`이 `nil` 호출로 죽음(GC 타이밍 의존) | ✅ 실패 시 detach + setup 전 `_onUpstreamEmit = Void`, `spec.gate` 1 |
| `H-189` | ① | 3 | 🟢 | `Observer.Subscribed`가 초기화되지 않아 `nil`(타입은 `boolean`, Effect는 `false`) | ✅ `false`로, `spec.observer` 1 |
| `H-190` | ① | 2 | 🟢 | `Apply`의 비함수 분기가 검증 없이 `factory:__apply`를 불러 quad 내부 줄을 가리키는 raw 에러 | ✅ `level 2` 검증(형제 생성자들과 같은 급), `spec.state` 10 |
| `H-179` | ① | 4 | 🟡 | `state:Apply(factory)`의 파라미터를 유니온 하나로 선언하면 `state:Apply(blocker)`가 strict에서 막힌다(필드가 더 있는 객체는 제네릭 `U` 자리에서 너비 서브타이핑 실패) | ✅ 교집합 오버로드로 확정(`luau-test/done/26-*`, `typing-limits.md` §1②) |
| `H-180` | ① | 4 | 🟢 | 폐기된 `state:Block` 표기가 라이브 문서 둘에 남아 있었다(`source-state-plan.md` `_hold` 파생 노드 목록, `blocker-plan.md` 사용 예시) | ✅ 정정 |
| `H-178` | ① | 3 | 🟢 | 코드의 사적 필드는 `_` 접두(`_valueEpochMap`·`_emitEpochMap`·`_subs`·`_hold`…)인데 `base/` 의사코드는 `valueEpochMap`처럼 접두 없이 쓴다 — 이름은 1:1이고 밑줄만 다르다 | ✅ 기록만(문서 무변경 — 코드 관례, `H-174` 조립 세부와 같은 급) |
| `H-175` | ① | 1 | 🟢 | §5 "불변 업밸류만 잡는 클로저는 프로토에 캐시"는 범위가 넓다 — 실제 규칙은 **업밸류가 없거나 전부 톱레벨(함수 깊이 0) 불변 로컬**일 때만(컴파일러 `shouldShareClosure`). 함수 인자·지역을 잡는 클로저(단위 3 `Effect`의 콜백 모양)는 정상 GC됨을 실측 | ✅ §5·`spec.ref` 주석 좁힘 |
| `H-191` | ① | 3 | 🟡 | `effect-plan.md` "`Ref` 의존성의 해제 경로" 절 꼬리가 아직 *"`Ref` 콜백은 본문 맨 앞에서 `canExecute(handle)`를 확인하고 거짓이면 그대로 리턴"*(= 버림)이고 절 머리 배너가 그걸 *"그대로 유효"*라 재확인한다 — `H-159` 뒤 코드는 `fire`가 판정 없이 `Update → Rerun`, `rawRerun`이 **홀드**(안 묶인 채 온 `ref:Set`이 바인드 때 1회 재생 — `spec.effect` 2) | ✅ 반영(2026-08-29, 메인 세션)|
| `H-192` | ① | 3·4 | 🟢 | 설치 발화 N회의 억제 주체가 두 문서에서 `canExecute`로 서술됨(`gate-plan.md` 7번 *"첫 가드에서 떨어진다"*, `effect-plan.md` "`Effect(fn, ...deps)`" 절 *"설치 발화를 전부 떨어뜨리므로"*) — 실제 억제는 `fire`의 `from == nil` 가드(같은 문서 생성자 주석·코드). `H-159` 뒤 `canExecute` 경로는 버리는 게 아니라 홀드라, 그리로 갔다면 첫 바인드에서 `H-58`(바인드마다 재실행)이 되살아난다 — 실측 3-dep `Effect`: 생성 `runs=1`, `_rerunRequired=false`, 바인드 뒤에도 1 | ✅ 반영(2026-08-29, 메인 세션)|
| `H-193` | ① | 4 | 🟢 | `gate-plan.md` "`GateNode` 조립"의 `H-152` 주석이 `H-163` 이전 모양 — *"`_emitDown`은 자식을 `isState(sub)`로만 가르므로 … `canExecute(gate)`도 거짓"*, *"GateNode는 State 생성자를 안 지나고 이 절이 곧 생성자"*. 지금 `_emitDown`은 `EmitReceive`만 부르고 게이트는 `canExecute`를 안 타며, 코드는 `newNode`가 만들어 첫 줄에서 등록한다(결론 "등록"은 유효 — `newNode` dep 검증·`Effect` deps·`isState`가 본다) | ✅ 반영(2026-08-29, 메인 세션)|
| `H-194` | ① | 3 | 🟢 | `H-174` 잔재 둘 — `effect-plan.md` "`EffectHandle:Subscribe()`" 절 블록 머리 *"`canBound` 게이트(`LifetimeHandle.luau`의 탑레벨 함수)"*, `lifecycle-pattern.md` "Observer 인스턴스 필드 목록" *"레지스트리 두 테이블은 … `Observer.luau`의 모듈 로컬"* — 지금은 인스턴스 필드 `module.canBound` / 인스턴스별 임플 클로저 로컬(`Impl._Subscribed`) | ✅ 반영(2026-08-29, 메인 세션)|
| `H-195` | ① | 3 | 🟢 | `effect-plan.md` "의사코드 — 생성자" 절의 `_consumeCleanup` 머리 주석 *"`_cleanup`의 유무가 곧 '설치돼 있는가'가 된다"*가 바로 아래 ⚠️ 문단(*"`_cleanup`의 유무로 판정하면 안 된다"*)·코드 주석과 정면 충돌 | ✅ 반영(2026-08-29, 메인 세션)|
| `H-196` | ① | 3 | 🟢 | `source-state-plan.md` "`state:Observer(fn)`" 절(*"owning leaf가 이미 죽었으면 no-op"*)·"Slot 생존 확인" 절(*"거짓이면 그냥 no-op"*)이 `H-159` 이전 서술 — 지금은 홀드 뒤 재바인드 시 1회 | ✅ 반영(2026-08-29, 메인 세션)|
| `H-197` | ① | 3·4 | 🟢 | `spec.init.luau` 1이 `Effect`/`Blocker`/`onDestroying`의 존재를 안 본다 — 그 파일 헤더가 *"이 런타임 확인이 유일한 가드"*라 하는 `H-80` 드리프트 가드에 단위 3·4 값이 빠짐 | ✅ 반영(2026-08-29, 메인 세션)|

## 상세

(단위별로 `### \`H-nnn\` 🔴/🟡/🟢 — 제목` 절을 이어 붙인다. 각 절엔 (1) 어디서
(파일:줄 / `base/` 절), (2) 무엇이, (3) 문서가 이미 답을 갖고 있는가, (4) 어떻게
처리했는가(①이면 커밋 해시).)

### 단위 1 — 공통 기반 (2026-08-28)

### `H-165` 🟡 — pesde shim은 생성 시점의 export 타입만 안다

- **어디서**: `quad-base/roblox_packages/quad_types.luau`(pesde 생성물, 커밋 안 됨) /
  `base/project-setup-plan.md`의 `test.sh` 절.
- **무엇이**: `quad-types/src/init.luau`에 `Ref<T>`/`Relate`/`Epoch`를 `export type`으로
  추가하고 `test.sh`를 돌리자 `luau-analyze`가 `Unknown type 'QuadTypes.Ref'`. shim이
  `export type Quad = module.Quad` / `CheckedQuad`만 손으로 나열한 파일이라
  `return module`로는 타입이 안 넘어온다. `relink.sh`는 복사만 갱신한다.
- **문서가 답을 갖고 있었나**: 아니다 — 첫 함정(심볼릭 링크)만 적혀 있었다.
- **처리**: `pesde install` 재실행으로 shim 재생성(같은 세션 실측), `project-setup-plan.md`에
  둘째 함정으로 기록. `test.sh`가 이제 `luau-analyze`를 같이 돌려 조용히 지나가지 않는다.

### `H-166` 🟢 — `Ref.Revision` 초기값이 문서에 없다

- **어디서**: `base/ref-plan.md` "`Ref`는 `Epoch`를 만족한다" 절 / `base/state-epoch-plan.md` §2.
- **무엇이**: 갱신식(`bit32.bnot(-rev)`)과 표만 있고 시작값이 없다.
- **처리**: `0`으로 구현하고 그 절에 한 줄 추가. 계약이 `==`/`~=`뿐이라 값은 무관.

### `H-167` 🟡 — 구현이 `Ref` 시그니처를 `T?`로 바꿔 놓았다 (자기 실수)

- **어디서**: `quad-types/src/init.luau`·`quad-base/src/Ref.luau` vs `base/ref-plan.md`
  "제네릭 시그니처(2026-08-07 확정)".
- **무엇이**: 문서는 `Ref<T>(T) -> Ref<T>`, `.Value: T` — nil이 올 수 있는 자리는 호출자가
  `Ref<<T?>>(nil)`로 넓힌다(그 문서의 언바인딩 절도 같은 전제). 옮기면서 `Ref()` 관용구를
  타입에서 받으려고 `default: T?`/`Value: T?`로 적었는데 그러면 `Ref(5).Value`까지
  nil 검사를 강요한다 — 문서가 이미 기각한 모양. 감사 2라운드가 발견.
- **처리**: 코드를 문서대로 되돌림. 테스트의 `Ref()`는 `Ref<<number?>>(nil)`로.

### `H-168` 🟡 — `Ref<T>(T)`와 무인자 `Ref()` 관용구가 양립하지 않는다 (②)

- **어디서**: `quad-base/src/Ref.luau` 생성자 / `base/ref-plan.md` "제네릭 시그니처" vs 같은
  문서의 `Ref():Callback(fn)` 관용구(`H-120` 문단), `base/lifecycle-hooks-plan.md`의
  `PreRef():Callback(guard(fn))`, `base/debounce-throttle-plan.md`의 `Handle = Ref()`.
- **무엇이**: `H-167`로 `default: T`가 되자 `local r = Quad.Ref()`가 strict에서 *"Argument
  count mismatch. Function expects 1 argument, but none are specified"*(리뷰 재현). 문서는
  명시 확장 `Ref<<T?>>(nil)`만 다루고 **빈 호출**은 안 다룬다. M8 훅 슈가가 문서대로
  짜이면 타입 검사를 못 통과한다.
- **갈래**: §4.

### `H-169` 🟡 — 재진입 `:Set` 뒤 남은 콜백이 옛 `value`를 받는다 (②)

- **어디서**: `Ref.luau` `:Set`의 `k(value, self)` — `base/ref-plan.md` "`:Set(value)`의 순서"
  블록을 그대로 옮긴 것.
- **무엇이**: 콜백 A가 `ref:Set(2)`를 다시 부르면 안쪽 파동이 먼저 다 돌고, 바깥 파동의 남은
  콜백 B는 `.Value == 2`인 채로 인자 `value == 1`을 받는다(리뷰 재현: B가 `(2,2)` 다음
  `(1,2)`). 문서의 *"모든 콜백이 새 값을 본다 … 옛 값이 보이는 창이 없다"*와 어긋남.
  문서가 재진입을 안 다뤄서 **문서 블록 수정이 필요한 자리** — 코드 임의 변경 금지.
- **갈래**: §4.

### `H-170` 🟡 — `coroutine.resume`은 에러를 올리지 않는다 (②)

- **어디서**: `Ref.luau` `:Set`의 `coroutine.resume(k, self)` / `base/ref-plan.md` `:Wait(thread)`
  절 *"나중에 `coroutine.resume`이 에러남"* / `spec.ref.luau` 9번의 꼬리 `Set`.
- **무엇이**: resume은 `(false, err)`를 **반환**하지 던지지 않는다. 대기자 안에서 난 에러와
  죽은 thread resume이 `:Set`에서 조용히 사라진다 — `architecture.md` "예외 안전성 계약 —
  감싸지 않는다"의 취지(에러는 전파된다)와 어긋나고, 문서 서술과 테스트 주석의 전제가
  틀려 있었다(주석은 고침).
- **갈래**: §4.

### `H-171` 🟡 — mock lazy claim이 GC 타이밍에 따라 갈린다

- **처리**: `claim`이 이미 Destroy된 inst면 새 gcconn을 즉시 `Disconnect` — Roblox에선
  `nativeClaim`이 생성 시 1회라 이 경로가 없다. `spec.lifetime.luau` 6b가 GC 전/후 둘 다 고정.

### `H-172` 🟡 — mock `Destroy` 의미론

- **처리**: Destroying 발화 → Parent nil(변경 시그널 관측 가능) → 자손 재귀 Destroy → 연결
  해제, 이미 파괴됐으면 no-op. 6c가 조상 파괴 계약(5라운드 *"조상 파괴 시 unowned 요소도
  같이 죽는다"*)을 mock에서 검증 가능하게 한다.

### `H-173` 🟢 — `TweenBrand`/`isTween` 위치 잔재 둘

- **처리**: `ROADMAP.md` M7 체크박스, `tween-plan.md` "base 프리미티브 아님" 문단.

### 단위 1 — 탐사자 (2026-08-28, 커밋 `d9898d6`..`325f3f0`)

### `H-174` 🔴 — `canExecute`/`canBound`는 인스턴스 필드인데 반응형 의사코드는 자유 함수로 부른다 (②)

- **어디서**: `quad-base/src/LifetimeHandle.luau`(`Init(module)`이 `module.bindLifetime = …`
  네 슬롯을 **인스턴스마다** 심음) + `quad-base/test/mock.luau` `installLifetime(quad)`(그
  `quad` 하나만 덮어씀) + `spec.lifetime.luau` 8("다른 `New()`엔 안 퍼짐"을 고정) —
  vs `base/source-state-plan.md` "전파 루프 — 확정 의사코드"의 `Observer:_receive`
  (`if canExecute(self) then`), `base/lifecycle-pattern.md` (2)의 `Observer:WeakSubscribe`
  (`if not canBound(self) then`), `base/effect-plan.md`의 `rawRerun`(`canExecute(self)`)과
  `EffectHandle` 네 진입점.
- **무엇이**: 이 단위가 확정대로 옮긴 결과 네 함수는 **자유 함수가 아니라 `quad` 인스턴스의
  필드**다(`lifecycle-pattern.md` 186행 *"평평한은 모듈 인스턴스의 필드라는 뜻"*, `architecture.md`
  13번 *"모듈이 하나의 인스턴스(… canExecute 등 계약 필드 하나)"*). 그런데 다음 단위가
  옮길 의사코드는 전부 `canExecute(self)`처럼 **어느 인스턴스인지 말하지 않고** 부른다.
  `Ref.luau`처럼 `Source.luau`/`State.luau`/`Observer.luau`를 인스턴스 간 공유되는 잎
  모듈로 쓰면(`spec.init` 27행이 `Ref`/`Void`/`Relate`에 대해 고정한 모양) 발화 시 **어느
  `quad`의 `canExecute`를 부를지 알 수 없다** — 백엔드가 둘이면(mock + roblox, `New()`의
  존재 이유) 잘못된 인스턴스의 게이트를 타거나, 아직 스텁인 인스턴스에서 `error`가 난다.
  코퍼스를 grep해도(`InitSource`/`InitState`/`InitObserver`/`_quad`/`_module`) 반응형 모듈의
  조립 형태를 정한 문장이 없다 — `module-lifecycle-plan.md` "New()의 내부 구성"이 정한 건
  `InitDispatch(module)` 하나의 예시뿐이고, `ROADMAP.md` "반응형 본체" 체크박스도 침묵한다.
- **같이 걸리는 하위 함정(결정과 무관하게 참)**: 백엔드는 `New()`가 **끝난 뒤** 필드를
  덮어쓴다(mock도 같은 순서). 그래서 반응형 모듈이 `Init` 시점에 `local canExecute =
  module.canExecute`로 **스텁을 캡처하면 영원히 스텁**이다 — 발화 시점마다
  `module.canExecute(self)`로 **늦게 읽어야** 한다. `spec.lifetime` 8은 `quad.bindLifetime ==
  before`(재설치 무시)만 보고 이 순서는 안 본다.
- **문서가 답을 갖고 있나**: 아니다. `architecture.md` 13번의 *"module-level state를
  참조하는 코드들이 모듈 인스턴스를 인자로 받도록 손을 대야 한다 — `InitModule(module)`
  등"*이 방향만 준다. 어느 모양이든 **새 조립 메커니즘**이라 §4.
- **갈래**: §4. 단위 1 코드는 어느 선택지에서도 그대로다(③ 아님).

### 단위 2 — `EpochMap` → `Source`/`State`/`Store` (2026-08-28)

### `H-176` 🟡 — 타입팩 deps 선언은 strict에서 안 산다 (①)

- **어디서**: `quad-types/src/init.luau` `State<T>.Compute` / `base/source-state-plan.md` "trailing
  deps를 `fn`에 lazy positional 인자로도 노출"의 "(B) 이형 다중 deps를 제네릭 팩으로".
- **무엇이**: `<U, D...>(self, fn: (self, U?, D...) -> U, D...)`로 선언하자 `spec.state.luau`의
  정상 호출 셋(3·7·9)이 *"Expected `{ read Get: (t1) -> (number, ...unknown) }` but got
  `Source<number>`"*로 막혔다 — 팩이 콜백 파라미터 쪽으로 역추론되며 `Get`을 read-only
  `...unknown` 반환으로 뒤튼다. 문서가 "실측 필요"로 남겨둔 바로 그 (B)다.
- **처리**: deps 자리 `...any`, 콜백 안에서 `dep: StateData<U>` 주석(콜백 파라미터 주석 관례
  그대로). 런타임 계약 무변경. 문서에 실측 기록, 스파이크 `15` 닫힘.

### `H-177` 🟢 — 반응형 Init의 순서 의존 (①)

- **어디서**: `quad-base/src/{Source,Store}.luau`의 `Init` / `init.luau`의 `RunInit` 순서 주석 vs
  `base/module-lifecycle-plan.md` "New()의 내부 구성" 절의 *"순서 의존성은 각 `InitXxx`를
  `require`처럼 멱등하게 만들어서 해소한다"*.
- **무엇이**: 단위 2 첫 커밋은 `init.luau`가 State → Source → Store 순서를 지키게 하고
  `implFor`가 어기면 error하게 했다 — 동작은 하지만 문서 원칙과 다른 길. 감사 3라운드가
  "사용자 판단"으로 올렸으나 문서가 이미 답을 갖고 있어 ①.
- **처리**: `Source.Init`이 `module:RunInit(State.Init)`, `Store.Init`이 `module:RunInit(InitSource)`를
  직접 호출. `init.luau` 순서 주석을 "무관"으로.

### 단위 3 — `Observer` → `Effect` (2026-08-29)

### 단위 4 — `GateNode` → `Blocker` (2026-08-29)

### `H-179` 🟡 — `:Apply`의 파라미터 타입 표기 (①)

- **어디서**: `quad-types/src/init.luau` `State<T>.Apply` / `base/source-state-plan.md`
  "`state:Apply(factory)`"(`H-94`: *"함수 또는 그 필드를 가진 객체를 받고 반환 `U`만
  열어둔다"*) / `base/typing-limits.md` §1②.
- **무엇이**: 단위 2가 `((State<T>) -> U) | { __apply: (self, State<T>) -> U }` 유니온으로
  적었고 함수 팩토리·`__apply`만 가진 객체는 통과했는데, 단위 4의 실제 `Blocker`(필드가
  더 있음)를 `s:Apply(b)`에 넣자 *"Expected this to be t1 where t1 = … | { __apply: … }"*.
  스파이크 4개(유니온·인덱서·제네릭 `__apply`·`any` 파라미터)로 좁힌 결과 유니온-제네릭
  파라미터에서 추가 필드가 있는 객체의 너비 서브타이핑이 안 된다. **교집합 오버로드**
  (함수 쪽 제네릭 `U` / 객체 쪽 `-> any`)만 양쪽을 다 받고 음성 대조군도 잡는다.
- **처리**: 그 표기로 확정, 스파이크를 `luau-test/done/26-*`로 보존, `typing-limits.md`
  §1②에 기록. `H-94`의 뜻(둘 다 받고 반환은 열어둔다)은 그대로 — 객체 쪽 반환이 `any`라
  호출부가 결과 타입을 명시한다(§1① 관례).

### 단위 3·4 `/code-review high` (2026-08-29) — 10건 중 ① 넷(`H-181`/`H-188`/`H-189`/`H-190`) 반영, ② 여섯(`H-182`~`H-187`) §4

### `H-181` 🔴 — 인스턴스별 임플의 저장 자리가 인스턴스를 영영 살렸다 (①)

- **어디서**: `State.luau`/`Observer.luau`/`Effect.luau`의 `implByModule`(weak-key, `module` 키).
- **무엇이**: 값인 임플의 메소드 클로저가 `module`을 캡처 — weak-key 테이블의 값이 키를 되참조하면
  ephemeron이 없는 Luau에선 절대 수거되지 않는다(`relate-plan.md`가 `H-71`로 경고한 바로 그
  모양). `init.luau`가 `New()`마다 세 Init을 무조건 돌리므로 **아무것도 안 써도** 모든 인스턴스가
  핀되고, 강한 레지스트리(`Subscribed`)에 든 Observer/Effect 그래프까지 같이 산다. 리뷰 실측.
- **처리**: 임플을 `module._impl`(비공개 필드)에 둔다 — `H-174` (a)안 원문이 *"RunInit 뒤의
  비공개 필드로 형제 Init에 넘김"*이라 새 모양이 아니다. `module ↔ impl` 순환은 자기완결이라
  인스턴스를 놓으면 통째로 수거된다(`spec.init.luau` 2). `State.Impl._module` 미사용 필드도 제거.

### `H-188` 🟡 — 반쯤 만든 `GateNode` (①)

- **처리**: 검증 실패 시 `self._subs[node] = nil`로 떼고 error; setup이 돌기 전 `_onUpstreamEmit`을
  `Void`로 두어 setup이 던져도 나중 `Set`이 `nil`을 부르지 않게(예외 후 부기는 UB라는 계약은
  그대로 — 이건 우리가 통제하는 검증 경로만 닫은 것).

### `H-189` 🟢 / `H-190` 🟢 (①)

- `Observer` 생성자에 `Subscribed = false`; `Apply`의 객체 분기에 `type(factory.__apply) ==
  "function"` 검증(`level 2`). 둘 다 형제 코드와 같은 급.

### `H-182` ~ `H-187` (②) — 코드엔 `-- TODO(H-nnn)` 마커만, 결정은 §4

- **`H-182`**: `Destroying` 콜백(cleanup 소진·연결 해제) 뒤 같은 파동에서 `canExecute`가 아직
  참. 리뷰 실측: 부모 Effect A(dep `count`) / 자식 Effect B의 cleanup이 `count:Set(...)` →
  `parent:Destroy()`에 `parent-run:0, child-run, parent-clean, parent-run:-1, child-clean`,
  끝에 `A._cleanup ~= nil`, `A._destroyConn == nil`. `H-160`은 cleanup **실행 중**만 막았다.
- **`H-183`**: 설치 발화(`o.fn(state, o, nil)`) 중 `_rerunRequired`가 아직 참이라 그 안의
  `Subscribe`가 `_catchUp`으로 `fn`을 중첩 재생. `H-147`의 원칙(*"`fn`은 자기 생명주기를 못
  바꾼다"*)을 Observer에도 적용할지, UB로 문서화할지.
- **`H-184`**: `bindLifetime`의 순서(부기 커밋 → 훅). 훅의 `isRunning` 가드가 던지면 반쯤 묶임.
- **`H-185`**: cleanup 팩. 런타임이 첫 반환만 쓴다.
- **`H-186`**: 교차 인스턴스 dep. 리뷰 실측: `A.Effect(fn, B.Source(0))`가 B의 미주입 스텁
  에러로 죽는다(A는 다 갖췄는데).
- **`H-187`**: 타입 별칭 이름 넷.

### `H-180` 🟢 — `state:Block` 잔재 (①)

- **처리**: `source-state-plan.md`의 `_hold` 파생 노드 목록과 `blocker-plan.md` 사용 예시에서
  `:Apply(blocker)`로. `gate-plan.md` 149-151은 정정 문구가 이미 뒤따라 그대로.

### `H-178` 🟢 — 사적 필드의 `_` 접두 (①)

- **어디서**: `effect-plan.md` 생성자 의사코드의 `d.valueEpochMap` / `state-epoch-plan.md` §4의
  `self.valueEpochMap` vs 코드 `_valueEpochMap`(단위 2부터).
- **무엇이**: 단위 2가 State의 사적 필드를 전부 `_` 접두로 옮겼고(`_subs`/`_hold`/`_cache`/
  카운터 둘/맵 둘), 단위 3 `Effect`가 `d._valueEpochMap`로 읽는다. 문서는 접두 없음. 뜻·개수는
  1:1이라 문서를 고칠 이유가 없고(의사코드는 문서 안에서 자기완결), 코드 쪽 관례로 기록만.
- **처리**: 없음 — 다음 단위(`GateNode`가 `valueEpochMap`을 컴포지션)도 같은 접두로.

### `H-175` 🟢 — 클로저 캐시 규칙의 범위 (①)

- **어디서**: 이 파일 §5 "툴링 사실 둘"의 둘째 항, `spec.ref.luau` 7번 주석.
- **무엇이**: *"불변 업밸류만 잡는 클로저는 프로토에 캐시돼 영영 GC되지 않는다"*는 범위가
  넓다. Luau 컴파일러 `shouldShareClosure`의 실제 조건은 **업밸류가 없거나, 전부
  `functionDepth == 0`(톱레벨) 불변 로컬**일 때뿐이다 — 함수 안의 지역/인자를 잡는 클로저는
  불변이어도 공유되지 않는다(컴파일러 주석: 공유하면 *"임시 객체가 영구가 된다"*라
  휴리스틱으로 좁혀둠). 실측(스크래치, `luau`): `mk(handle)`가 돌려준 클로저는 GC됨,
  업밸류 없는 클로저는 GC 뒤에도 살아남음(생존 1/2). 단위 3 `Effect`가 `handle`을 잡고
  `ref:WeakCallback(cb)`로 거는 모양을 그대로 흉내내면 `WeakCallbacks` 항목이 0으로
  사라진다 — 즉 지금 문장대로면 단위 3 GC 테스트가 잘못 경보를 낼 수 있다.
- **처리**: ✅ 반영(2026-08-28, 메인 세션). §5 문장을 *"업밸류가 없거나 톱레벨 불변 업밸류만
  잡는 클로저"*로 좁히면 된다.

### 단위 3·4 — 탐사자 (2026-08-29, 커밋 `dca789e`..`3670e88`)

전부 ①이고 전부 **문서 쪽**이다 — 코드는 확정 의사코드를 그대로 옮겼고(대조 결과는 §5),
어긋난 자리는 모두 "더 최근 결정(`H-159`/`H-163`/`H-174`)이 옛 문장을 못 지운 것"이다.
②·③ 없음. `H-182`~`H-187`은 재발견하지 않았고 반박 근거도 없다(`H-186`에 이웃 실측 하나를
§6에 보탰다).

### `H-191` 🟡 — `Ref` 콜백의 "거짓이면 리턴"은 `H-159` 이전 모양 (①)

- **어디서**: `base/effect-plan.md` "`Ref` 의존성의 해제 경로" 절 끝 문단(*"확정된 형태: `Effect`가
  거는 `Ref` 콜백은 본문 맨 앞에서 자기 핸들에 대해 `canExecute(handle)`를 확인하고, 거짓이면
  그대로 리턴한다"*)과 그 절 머리 배너(*"아래 `canExecute` 게이팅은 그대로 유효하다 — 뒤쪽
  절반"*) vs `quad-base/src/Effect.luau`의 `fire`/`rawRerun`.
- **무엇이**: 코드는 `onRefFire → fire(ref) → _epochs:Update(ref) → Rerun → rawRerun`이고
  실행 불가면 `_rerunRequired`로 **홀드**한다 — 콜백 본문엔 판정이 없다(`H-159` *"fire 는 그냥
  rerun 을 호출해도 될것"*). 관측 차이가 있다: 문서대로면 안 묶인 채 온 `ref:Set`은 **버려지고**
  `_epochs`도 안 움직이는데, 코드는 홀드했다가 바인드 때 1회 재생한다(`spec.effect` 2가 이걸
  고정 — `r:Set(2)` 뒤 `bindLifetime` → `runs == 2`). 같은 문서의 생성자 의사코드는 이미
  `H-159` 모양이라 **문서 안에서 두 절이 서로 다른 계약**을 말한다.
- **문서가 답을 갖고 있나**: 있다 — `H-159`(`qa-request/pre-implementation-handtrace-round10-followup.md`)와 같은 문서의 생성자 블록.
- **처리**: ✅ 반영. 그 문단을 "`fire`는 판정하지 않고 `rawRerun`이 홀드한다(생성자 블록이
  소스)"로, 배너의 "뒤쪽 절반"도 같은 뜻으로 좁히면 된다.

### `H-192` 🟢 — 설치 발화 억제 주체 서술이 둘로 갈린다 (①)

- **어디서**: `base/gate-plan.md` 7번(*"생성자 안에선 아직 안 묶여 있어 설치 발화가 첫 가드에서
  떨어진다"*), `base/effect-plan.md` "`Effect(fn, ...deps)`" 절의 "최초 1회를 한 번만 돌리는
  장치" 항목(*"`canExecute`(지금은 `rawRerun` 진입에서 본다)가 설치 발화를 전부
  떨어뜨리므로"*) vs 같은 문서 생성자 의사코드 주석(*"즉시-1회 호출(설치 발화)은 `fire`의
  `from == nil` 가드가 거른다(옛 `Blocker`/`canExecute` 억제 서술은 폐기)"*)과 코드.
- **무엇이**: 내부 Observer의 설치 발화는 `onStateFire(_, _, nil) → fire(nil) → return`에서
  끝난다 — `rawRerun`에 닿지 않는다. `H-159` 뒤 `rawRerun`의 `canExecute` 가드는 **버리는
  게 아니라 홀드**이므로, 그리로 갔다면 dep마다 `_rerunRequired = true`가 서고 첫 바인드에서
  `fn`이 한 번 더 돈다 — 바로 `H-58`이다. 실측(스크래치): `Effect(fn, s1, s2, s3)` 생성 직후
  `runs == 1`, `_rerunRequired == false`, `bindLifetime` 뒤에도 `runs == 1`.
- **처리**: ✅ 반영. 두 자리를 "설치 발화는 `from == nil` 가드가 거른다(`canExecute`는 그
  뒤의 진짜 emit을 홀드한다)"로.

### `H-193` 🟢 — `GateNode` 조립의 `H-152` 근거가 `H-163` 이전 모양 (①)

- **어디서**: `base/gate-plan.md` "`GateNode` 조립" 블록 머리 주석(`H-152`) vs
  `base/source-state-plan.md` "전파 루프 — 확정 의사코드"(`H-163`)와 `quad-base/src/State.luau`.
- **무엇이**: 주석은 *"`_emitDown`은 자식을 `isState(sub)`로만 가르므로 … 등록이 빠지면 상류
  emit이 `_receive`로 안 오고 `canExecute(gate)`도 거짓이라"*, *"GateNode는 State 생성자를 안
  지나고 이 절이 곧 생성자"*라 한다. 지금 `_emitDown`은 `sub:_receive(from)`만 부르고
  (`isState` 분기 없음), 게이트는 `canExecute`를 안 타며(`H-56`), 코드의 `Impl.Gate`는
  `newNode({self}, passThrough, GateImpl)`로 만들어 **`newNode` 첫 줄**에서 `StateBrand:register`
  한다 — 별도 생성자가 아니다. 등록 자체는 여전히 필요하다(`newNode`의 dep 검증, `Effect`
  deps 검증, `Quad.isState`가 본다 — `spec.gate` 1이 고정).
- **처리**: ✅ 반영. 근거 문장만 지금 모양(`newNode` 공유, 등록의 소비자는 검증·술어)으로.

### `H-194` 🟢 — `H-174` 잔재 둘 (①)

- **어디서**: `base/effect-plan.md` "`EffectHandle:Subscribe()`" 절 블록 머리(*"`canBound`
  게이트(`LifetimeHandle.luau`의 탑레벨 함수)"*), `base/lifecycle-pattern.md`
  "Observer 인스턴스 필드 목록" 끝(*"레지스트리 두 테이블은 인스턴스 필드가 아니라 `Observer.luau`의
  모듈 로컬"*).
- **무엇이**: `H-174` (a) 뒤 게이트는 `module.canBound`(인스턴스 필드, 발화 시점에 늦게 읽음)
  이고, 레지스트리 둘은 `Observer.Init(module)`이 만드는 **인스턴스별 임플의 클로저 로컬**
  (`Impl._Subscribed`/`_WeakSubscribed`, `spec.observer` 8이 인스턴스 분리를 고정)이다.
  `lifecycle-pattern.md`의 `H-174` 문단은 게이트 쪽만 정정했고 레지스트리 문장은 안 건드렸다.
- **처리**: ✅ 반영. 두 문장만(`effect-plan.md` 쪽은 스윕이 먼저 고쳤다).

### `H-195` 🟢 — `_consumeCleanup` 머리 주석의 자기모순 (①)

- **어디서**: `base/effect-plan.md` "의사코드 — 생성자" 절, `_consumeCleanup` 블록 위 주석
  *"이 순서라야 이중 호출이 없고, `_cleanup`의 유무가 곧 '설치돼 있는가'가 된다"* vs 바로 아래
  ⚠️ 문단 *"'설치돼 있는가'를 `_cleanup`의 유무로 판정하면 안 된다 — 별도 플래그"*와
  `Effect.luau`의 같은 자리 주석(*"`_cleanup`'s presence is not 'installed' — the flag is"*).
- **처리**: ✅ 반영. 주석 뒷절 삭제.

### `H-196` 🟢 — Observer 쪽 "죽었으면 no-op" 둘 (①)

- **어디서**: `base/source-state-plan.md` "`state:Observer(fn)`" 절의 *"발화 시점과 처리 시점
  사이에 owning leaf가 이미 죽었으면 no-op"*, 같은 문서 "Slot 생존 확인" 절의 *"거짓이면 그냥
  no-op"*.
- **무엇이**: `H-159` 뒤 `Observer:_receive`는 거짓이면 `_rerunRequired`를 세우고, 재바인드
  (`bindLifetime`)·`Subscribe`·`WeakSubscribe`가 `_catchUp`으로 1회 재생한다 — 죽은 leaf에
  묶인 채로는 no-op과 같지만 `H-65`(죽은 바인딩의 재사용)와 겹치면 관측이 다르다
  (`spec.observer` 2: Destroy 뒤 `Set` → 홀드). 같은 절의 두 줄 위는 이미 "홀드"로 고쳐져 있어
  한 절 안에서 표현이 갈린다.
- **처리**: ✅ 반영. "no-op" → "홀드(재바인드 시 1회)".

### `H-197` 🟢 — `spec.init` 1이 단위 3·4 탑레벨 값을 안 본다 (①)

- **어디서**: `quad-base/test/spec.init.luau` 1절 vs 그 파일 헤더(*"`init.luau`의 `{...} :: Quad`
  캐스트는 빠진 필드를 안 잡으므로 이 런타임 확인이 유일한 가드"*).
- **무엇이**: `Relate`/`Void`/`Ref`/`Source`/`Store`/술어 11/생명주기 4만 단언하고
  `Effect`/`Blocker`/`onDestroying`은 없다 — 단위 3·4가 `Quad` 타입에 더한 셋이 가드 밖이다
  (`spec.init` 2가 `q.Effect`를 부르긴 하지만 그건 `H-181` GC 검사다).
- **처리**: ✅ 반영. 1절에 세 줄.

## §4 ⭐ 사용자 결정이 필요한 것 (배치 회신용)

| 문항 | 무엇 | 선택지 | 권고 | 권고 근거 | 옛 메커니즘 복원? |
|---|---|---|---|---|---|
| **`H-168`** | `Ref<T>(T)` vs 무인자 `Ref()` 관용구 | (a) 시그니처 유지, 문서의 빈 호출 관용구를 전부 `Ref<<T?>>()`(nil-able 파라미터는 생략 가능)로 고쳐 씀 / (b) `default: T?`, `.Value: T?`(H-167 이전 모양 — `Ref(5).Value`까지 nil 검사 강요) / (c) 두 오버로드 `Ref<T>(T)` ∪ `Ref<T>() -> Ref<T?>` | **(a)** | "제네릭 시그니처" 확정(단일 파라미터, 명시 확장으로 넓힘)을 그대로 두고 관용구만 그 규칙에 맞추는 것 — (b)는 문서가 기각한 모양, (c)는 그 절이 기각한 2-파라미터 솔버 문제의 재개방 | (b)가 그렇다 |
| **`H-169`** | 재진입 `:Set` 뒤 남은 콜백의 인자 | (a) 블록을 `k(self.Value, self)`로(항상 최신 값, 문서 불변식 그대로) / (b) 문서에 "재진입 시 바깥 파동의 남은 콜백은 자기 파동의 값을 받는다"로 계약화(코드 유지) / (c) 재진입 자체를 금지(error) | **(a)** | 문서 불변식(*"옛 값이 보이는 창이 없다"*)이 이미 (a)를 말하고 있고 한 토큰 차이 — (b)는 인자와 `.Value`가 다른 창을 계약으로 열고, (c)는 새 가드 | 아니오 |
| **`H-170`** | resume이 삼키는 에러 | (a) `local ok, err = coroutine.resume(k, self); if not ok then error(err, 0) end` — 대기자 에러를 `:Set` 호출부로 다시 올림 / (b) UB로 문서화(대기자 에러는 사라진다) / (c) 대기자 소진을 `task.spawn`류 주입 op로(Roblox `task.spawn`은 에러를 콘솔로 보냄) | **(a)** | `architecture.md` "예외 안전성 계약"(감싸지 않는다 = 에러는 전파)과 같은 결. 다만 **새 코드 두 줄(re-raise)** 이라 사용자 결정 자리. (c)는 새 주입 op | 아니오 |
| **`H-182`** (`/code-review`, 단위 3) | Destroy 파동 안 cleanup 뒤의 재실행 창 | (a) `Destroying` 콜백이 `_dying = true`를 세우고 `rawRerun`이 `canExecute`와 함께 본다(재바인드 `_bindDestroying`이 내림) / (b) `_destroyConn == nil`이면서 gcconn이 살아 있는 상태를 "죽는 중"으로 판정(새 필드 없음, 단 `Subscribe`로 묶인 핸들과 구분 못 함) / (c) UB 문서화(`fn` 안 `inst:Destroy()` UB의 이웃) | **(a)** | `H-160`이 "cleanup 중"을 홀드로 닫은 것과 같은 결 — 파동 후반은 같은 상태의 연장. 새 플래그 하나 | 아니오 |
| **`H-183`** (`/code-review`, 단위 3) | Observer 설치 발화 재진입 | (a) Observer에도 `_running` 가드 — 네 진입점·`bindLifetime` 훅 첫 줄 `error(…, 2)`(`H-147` 대칭) / (b) 생성자 순서만 바꿔(플래그 내림 → fn) 중첩 재생을 없애고 나머지는 UB / (c) UB 문서화 | **(a)** | `H-147`의 근거("유저 함수가 본인을 죽이고 살린다는 점 자체가 모순")가 Observer에도 그대로 — Effect만 막을 이유가 없다 | 아니오 |
| **`H-184`** (`/code-review`, 단위 1·3) | `bindLifetime` 부기 커밋 vs 훅 가드 순서 | (a) `bindLifetime`이 `isEffect(value)`면 훅 가드를 **먼저** 묻고(예: `value:_assertBindable()` 훅 하나) 통과 후 커밋 / (b) 훅이 던지면 부기를 되감음 / (c) UB(`fn` 안 bind는 `H-147`로 이미 금지) | **(a)** | (b)는 pcall 없이는 못 하고 예외 안전성 계약과 충돌; (c)는 반쯤 묶인 핸들이 남아 이후 bind가 전부 "already bound"로 막히는 실측이라 UB로 두기엔 무겁다 | 아니오 |
| **`H-185`** (`/code-review`, 단위 3) | cleanup 팩 vs 첫 반환만 | (a) 런타임이 반환 전부를 cleanup 목록으로 소진(역순) / (b) 타입을 `-> (() -> ())?`류로 좁힘(`H-95`가 기각한 모양 — 무반환 `fn`이 막힘) / (c) 문서·타입 주석에 "첫 반환만" 명시 | **(a)** | 타입이 이미 팩을 광고하고 다중 자원 정리는 자연스러운 용례 — 소진 순서만 정하면 됨(`_consumeCleanup` 한 곳) | 아니오 |
| **`H-186`** (`/code-review`, 단위 3) | 교차 인스턴스 dep | (a) `Effect`/`Observer`/`Compute` 생성 시 dep의 인스턴스가 다르면 `error(…, 2)`(임플이 `module`을 아니 판정 가능) / (b) UB 문서화 / (c) 지원(dep의 백엔드가 게이팅 — 지금 동작) | **(a)** | 지금 동작은 두 백엔드가 한 핸들을 나눠 판정해 에러 귀속이 틀린다; `architecture.md` 13번의 다중 `New()`는 "같은 인스턴스 안"이 전제 | 아니오 |
| **`H-187`** (`/code-review`, 단위 3·4) | 타입 별칭 이름 넷 | (a) 그대로 승인(`ObserverFn`/`EffectFn`/`GateEmit`/`GateSetup`) / (b) 인라인으로 풀어 이름을 없앰 / (c) 다른 이름 | **(a)** | 시그니처는 문서 그대로이고 이름이 없으면 `quad-types` 선언이 세 배로 길어진다 | 아니오 |
| **`H-174`** (탐사자, **단위 2 착수 전 필요**) | 반응형 모듈이 자기 `quad` 인스턴스의 `canExecute`/`canBound`에 닿는 법 | (a) `Source.luau`/`State.luau`/`Observer.luau`/`Effect.luau`를 `InitSource(module)`류 **팩토리**로 — 클래스와 `Subscribed`/`WeakSubscribed` 레지스트리를 `module`을 닫은 클로저 안에서 만들고 `module.Source = …`로 심음(`InitDispatch`와 같은 모양, `EpochMap`/`Brand`/`Ref`는 그대로 잎). 공개 필드가 없는 `State`/`Observer` 클래스는 `Init`의 반환값이나 `module.RunInit` 뒤의 비공개 필드로 형제 `Init`에 넘김 / (b) 잎 모듈 유지 + 값마다 역참조 필드(`observer._quad`)를 두고 `self._quad.canExecute(self)` / (c) 잎 모듈 유지 + 모듈 로컬 슬롯 하나를 백엔드가 채움(인스턴스 격리 포기) | **(a)** | `architecture.md` 13번(*"모듈 인스턴스를 인자로 받도록"*)과 `module-lifecycle-plan.md` "New()의 내부 구성"이 이미 이 모양이고, `Observer`의 두 레지스트리가 인스턴스별이 되어 *"완전히 별도의 새 Quad 네임스페이스"*와 맞음. (b)는 새 필드 + 값이 자기 모듈을 강참조(`Relate` 되참조 계열 위험), (c)는 `spec.lifetime` 8·`New()`의 존재 이유와 충돌. 어느 쪽이든 **필드는 발화 시점에 늦게 읽는다**(상세 절의 하위 함정) | 아니오 |

**[2026-08-28 회신 — 단위 1 배치 전량 확정]** 사용자 원문: *"174 는 module.canExecute 로
lazy 하게 읽으면 되는거 아냐? Set 재진입 같은 경우는, 반복문을 자신 epoch 를 보며
달라져버렸다면 놓으면 될듯. 후행 Set 이 전부 호출하도록. (진짜 항상 콜백이 받는건
최신임) / ref 쪽에서는 `local function A<T>(a: T)end A<<{}?>>()` 로 쓰면 없어도 호출
가능해짐. 시그니처 유지 권고를 따르고자 해. / coroutine.resume 은 애초에 에러가 날지 안
날지 후행 yield 로 나가는건 우리가 처리 어렵긴 해. 그치만 당장 돌아오는 결과 false 은
확인 해줄 수 있는듯. a 권고사항 따르기로"*. `H-169`만 권고 (a)(`k(self.Value, self)`)가
아니라 **사용자 안**(리비전 비교로 파동을 놓음)으로 — 권고안은 같은 파동에서 콜백이 두
번 불리는 문제를 남겼다. 반영 위치는 위 표의 상태 열.

코드 쪽 잔여 마커: `grep -rn "TODO(H-" quad-base/src` — 이 표의 문항과 1:1이어야
한다. **[2026-08-28 기준] 마커 0개**였고 **[2026-08-29 단위 3·4 리뷰 뒤] `H-182`~`H-187` 여섯 개 마커**가 코드에 있다(`grep -rn "TODO(H-" quad-base quad-types`) — 위 셋(`H-168`~`H-170`)은 단위 1 모듈을 막지 않아 코드는 문서
블록 그대로 두고 문항만 올렸다(`H-168`은 코드가 아니라 M8 문서의 관용구 문제).

## §5 이상 없다고 확인한 것

(탐사자가 실제로 돌려보고 계약대로였던 자리 — 다음 탐사자가 다시 파지 않게.)

**단위 1 (메인 세션, 2026-08-28)**:
- `Relate.luau`(M1) ↔ `relate-plan.md` "API"/"실제 구조": 4 메서드, lazy 서브테이블,
  공유 `{__mode="v"}` 메타테이블, `inst` weak — 전부 일치(`spec.relate.luau`가 고정).
- `lifecycle-pattern.md` (0)/(1) 스케치는 mock 시그널 위에 그대로 돌아간다 — `Destroy` →
  `gcconn.Connected=false` → `canExecute` false/`canBound` true, gchold 강참조, 조기
  해제, 이중 바인드 게이트 모양. 스케치의 한국어 에러 문구는 같은 문서가 이미
  *"실제 문구는 영어"*라 밝힌 자리표시자라 문서 결함 아님(코드는 영어 + `level 2`).
- `ref-plan.md` `:Set` 블록을 한 줄씩 옮겼고 계약 9개가 테스트로 고정됐다. 함수키
  dedup(강+약 동시 등록 시 1회)과 순회 중 해제 skip이 실제로 성립한다.
- `brand-plan.md` 합성 술어(`isState = isSource or StateBrand`, `isRef = isPreRef or
  isPostRef or RefBrand`)와 weak-key 멤버십 — 성립.

**단위 2 (메인 세션, 2026-08-28)**:
- `EpochMap` 6 연산 ↔ `state-epoch-plan.md` §3 일치(`spec.epochmap`). `Update`의 "한 번 다름을
  찾으면 나머지는 쓰기만" 최적화 포함. 키 weak 실측.
- `State:_receive` 규칙 1~3, 시딩(`Sync`/`TrackFrom` 분기), 카운터 쌍(`curr = nil` 시작, 재계산
  도중 무효화·`fn` 예외 케이스), `Get`의 `Refresh` 순회(값만, 통지 없음), 다이아몬드 접힘 —
  전부 `spec.state`가 고정. `_hold` 불변식(하류→상류 강, 상류→하류 weak) GC 실측 통과 —
  `luau-test/STATUS.md`의 "만들어야 할 스파이크"(중간 State GC)는 이걸로 대신한다.
- `Source:Set` 동일값 갱신(`H-68`), `Emit`, `isModifier` 가드 셋(생성자/`Set`/`Compute` 캐싱).
- `Store`: `H-122`/`H-153`/`H-83` 전부 `spec.store`. `Names()`는 `pairs(self)` — 메소드가
  `__index`라 안 센다는 `H-153` 전제가 실측으로 성립.
- **조립 세부**(`H-174`의 구현, 새 표면 아님): `State.luau`는 `Init(module)`이 인스턴스별 임플을
  만들고 `implFor(module)`로 `Source` Init에 건넨다(`Store` Init은 이 임플을 직접 안 받고 `module.Source`를 통해서만 State에 닿는다; 각 Init이 `module:RunInit(dep)`로
  의존성을 직접 당겨오므로 `New()` 순서 무관 — `H-177`; `implFor`의 level 1 error는 그래도 남겨둔
  불변식 검사). `Source`의 `__index` 체인이 그 임플을 가리켜 `With`/`Compute`/
  `Apply`가 위임된다. 그 시점(단위 2 끝)의 인스턴스 간 공유 잎은 `Ref`/`Void`/`Relate`/`Brand`/`EpochMap` — 이후의 소스는 각 파일 헤더 주석(`module-lifecycle-plan.md` `H-174` 배너), 이 줄은 스냅샷.
- **입력 검증 하나 추가**(`architecture.md` error 계약의 예 *"dep #3 is not a State/Source/Ref"*
  그대로): `newNode`가 dep이 `isState`가 아니면 `error(…, 3)` — 없으면 `dep._subs` nil 인덱스로
  quad 내부 줄에서 죽는다. 새 메커니즘이 아니라 계약이 이미 요구하는 자리라 ①로 둔다.
- `Apply`의 팩토리 파라미터가 유니온(함수 | `__apply` 객체)이라 **콜백 파라미터 무주석
  추론이 안 된다** — `typing-limits.md` §1②가 이미 캐비엇으로 적어둔 자리(`:Apply`의 factory는
  주석 필요). 테스트는 주석으로.

**단위 3 (메인 세션, 2026-08-29)**:
- `Observer` — 생성자 순서(fn 1회 → 플래그 내림 → `_subs`), `_receive`의 `canExecute` 게이팅과
  홀드, `_catchUp`이 유일한 재생 자리(출처 `nil`), 네 진입점(Weak 프리미티브·인라인 게이트·
  관대/엄격·양쪽 테이블 해제), 강/약 GC, 파동 중 구독자 스냅샷 — `spec.observer.luau` 8절.
- `Effect` — deps 검증 셋(`H-70`), dep 종류별 클로저 둘(`H-107`), `fire`의 `from == nil` 가드,
  `_epochs` 갱신은 `fire`뿐(`H-151`), 다이아몬드 1회, cleanup 세 자리(루프 머리/`Unsubscribe`/
  `Destroying`), cleanup 없는 `fn`의 재바인드 무재실행(`H-58` 회귀), 재진입 지연(`_pending`),
  네 진입점의 `isRunning` 가드가 `fn`·cleanup 안 전부 막음(`H-147`), 에러 시 사망 계약, 강한
  주인 GC — `spec.effect.luau` 9절.
- **조립 세부**: `Observer.luau`가 인스턴스별 레지스트리 둘(`_Subscribed`/`_WeakSubscribed`)을
  임플에 매달고 `Effect.luau`가 `implFor`로 받는다(`H-99`의 "모듈 내부 export, 이름은 구현 시").
  `State.Init`이 `Observer.Init`을 당겨 `state:Observer`를 `ObserverImpl.new`로 위임.
- **`onDestroying` 스텁의 자리**: `LifetimeHandle.luau`의 `Init`이 생명주기 4종과 같이 에러
  스텁을 설치(주입 op 목록의 소스는 `architecture.md` EngineOps 줄 — 스텁 파일 배치는 코드
  배치). mock은 `installLifetime`이 `inst.Destroying:Connect(fn)`으로 채운다.
- 색인이 짚은 문서 긴장(`base/source-state-plan.md` "`state:Observer(fn)`" 절의 *"Effect의 내부 Observer가 이 설치 발화를 `from == nil`로 거르는 이유이기도 하다"* — 한때 여기 `ss:1197`이라는 색인 약호로 적혀 있었다 —
  vs `H-164`)은 코드에서 모순 없음 — Observer 계약은 `nil` = 출처 없음이고, Effect의
  `fire`가 그걸 `Update` 못 하는 값으로 **자기 사정**으로 거를 뿐이다.
- 테스트 작성 함정: `table.insert(t, nil)`은 길이를 안 늘린다 — `emitFrom == nil` 발화를 셀 땐
  래퍼로 기록할 것(한 번 오진했다).

**단위 4 (메인 세션, 2026-08-29)**:
- `GateNode`는 `State.luau` 안(`architecture.md` 소스 트리가 `:Gate`를 `State.luau` 소속으로
  둠) — `newNode({self}, passThrough, GateImpl)`로 만들어 `StateBrand` 등록·시딩·`_hold`를
  그대로 받고, `_receive`(emit 맵은 `Peek`, unfold 합류, 정책 호출)와 `_flush`(빈 배치
  false → 스왑 → `Sync(batch)` → `_emitDown(batch)`; `emit(false)`는 버리기)만 덮어쓴다.
  `Get`은 상속(pass-through + 카운터). 값은 안 가린다(3번) — `spec.gate.luau` 9절.
- `Blocker.luau`는 잎 모듈(게이트 표면을 안 만짐 — §6의 상속 우려는 해당 없음): `On`/`Off`/
  `OffWithoutEmit`/`IsOn`/`Policy`/`__apply`, 핸들 weak-key 셋 + 강한 주인은 `onUpstreamEmit`
  클로저(그 클로저가 `handle(true)`로 통과시켜 업밸류를 산 채로), `Off`류는 스냅샷 순회 —
  `spec.blocker.luau` 7절(GC 실측 포함).
- 단위 3 감사 1라운드 잔여: `Observer`/`Effect` 생성자의 `fn` 타입 검사(`error(…, 2)`)는
  문서에 없고 코드가 더한 입력 검증 — `newNode` dep 검증과 같은 급(`architecture.md` 계약의
  예), 기록만. 스파이크 `05`는 `spec.state`/`spec.effect` 3번이 대체 → `done/`.
- `Impl.Gate`의 `setup` 타입 검사와 `setup(emit)` 반환값 검사(`error(…, 2)`) 둘도 문서에
  없고 코드가 더한 입력 검증 — `newNode` dep 검증·단위 3의 `fn` 검사와 같은 급, 기록만.
- `Debounce`/`Throttle`·`setTimeout`/`clearTimeout` 주입 op는 백로그 — 이번 단위에 없음.

**툴링 사실 둘**(설계 아님, 다음 단위가 알아야 함):
- `require("@self/X")`는 **`init.luau`에서만** 통한다 — 일반 파일에서 `@self`는 그 파일
  자신이라 `could not resolve child component`. 형제 모듈은 `./X`, 패키지는 `../roblox_packages/...`.
- GC 테스트 함정 둘: 같은 프레임의 죽은 레지스터가 임시값을 붙잡는다(별도 함수 안에서
  만들 것) / **업밸류가 없거나 전부 톱레벨(함수 깊이 0) 불변 로컬인 클로저는 Luau가
  프로토에 캐시해 영영 GC되지 않는다**(**[`H-175` 정정]** 함수 인자·지역을 잡는 클로저는
  정상 GC됨 — 테스트의 탑레벨 클로저는 업밸류를 직접 변경하게 할 것,
  `lifecycle-pattern.md` (0)의 `false or` 트릭이 막는 것과 같은 최적화).

**단위 1 (탐사자, 2026-08-28)** — 커밋 `d9898d6`..`325f3f0`, 신선한 컨텍스트, `git stash` 안 씀:
- **실행**: `./scripts/test.sh` 전체 — relink 30 갱신, `luau-analyze quad-base/src + spec.* +
  mock.luau` 진단 0, 9파일 전부 `ALL PASS`. `grep -rn "TODO(H-" quad-base/src` 0건(§4 표와
  1:1 — 표의 넷은 전부 코드 밖 문항).
- **한 줄 대조(코드 ↔ `base/` 절), 어긋난 곳 없음**: `Brand.luau` ↔ `brand-plan.md` "구현 —
  인스턴스 브랜드"/"`isX` wrapper"(생성자·15 인스턴스·11 술어·합성 방향·소문자 메소드·`None`
  무의존) / `Relate.luau` ↔ "API (확정)"/"실제 구조 (확정, 2026-08-08 세션)"(범위 안 diff는
  타입 재export뿐, 본문 무변경 확인) / `LifetimeHandle.luau` ↔ `lifecycle-pattern.md` "탑레벨
  평범한 함수로 확정"의 2026-08-28 정정 + `architecture.md` error 계약(영어, `level 2`, 스텁은
  조용한 no-op 아님) / `Ref.luau` ↔ `ref-plan.md` "`:Set(value)`의 순서" 블록(토큰 단위 동일 —
  `H-169`/`H-170`은 블록 자체의 문제), "API 모양"(self 반환, 등록 즉시 1회, `fn(value, ref)`),
  "`.Callbacks`는 배열이 아니라", "`:WeakCallback(fn)`"(weak-key 별도 테이블, `Uncallback`은
  양쪽), "`Ref`는 `Epoch`를 만족한다"(`Revision` 공개, `EpochBrand` 다중 태깅),
  `state-epoch-plan.md` §2(`bit32.bnot(-rev)`) / `mock.luau` `installLifetime` ↔ (0)/(1)/(2)
  스케치(`isBoundAlive` 두 경로, 게이트 모양, `gchold[value]`, `BindData` 둘 다 weak, Observer
  `_catchUp`/Effect `_bindDestroying`·`_unbindDestroying`, `unbindLifetime`이 cleanup·콜백을 안
  뗌) — mock만의 추가는 `isMockInstance` 검사와 `H-171` 분기뿐 / `init.luau`·`quad-types`
  `Quad` ↔ brief §6 표(재export 목록·술어 11개 이름 일치).
- **다음 단위가 쓸 표면, 타입 레벨 실측(`luau-analyze`, strict, 진단 0)**: `Ref<T>`가
  `QuadTypes.Epoch`에 그대로 들어감(`sync(e: Epoch)`에 `Ref(5)`), `Ref<number>` → `Ref<any>`
  인자 전달 OK(`Effect(fn, ...deps)`의 dep 합집합에 필요), `{ [Epoch]: number }` weak-key 맵에
  `Ref`를 키로 OK(`EpochMap` 내부 모양), `Epoch | Ref<any>` 합집합 OK, 콜백 인자 생략
  (`function(v)`/`function()`) OK, 두 번째 인자를 `Epoch`로 넘기기 OK. **`H-168`의 전제와
  (a) 둘 다 실측**: `Quad.Ref()`는 *"Function expects 1 argument"*, `Quad.Ref<<number?>>()`는
  **인자 없이도 진단 0**이고 `.Value: number?` — 권고 (a)의 관용구가 실제로 성립한다.
- **런타임 실측(스크래치, 인라인)**: mock의 `.Subscribed` 경로는 지금 이미 돈다(`ObserverBrand`
  등록 + `Subscribed = true` → `canExecute` true/`canBound` false, `bindLifetime` → *"already
  subscribed"*) / `ObserverBrand` 등록값을 `_catchUp` 없이 바인드하면 `attempt to call missing
  method '_catchUp'` — 단위 2의 `Observer`가 이 메소드를 반드시 갖는다는 뜻(`EffectBrand`는
  `_bindDestroying`/`_unbindDestroying`, 단위 3) / `Ref`를 `bindLifetime`의 value로 — 정상(바인드
  후 `canExecute` true, `Destroy` 후 false) / `Effect` 모양(`handle`을 잡는 클로저를
  `WeakCallback`)의 항목은 `handle`을 놓으면 GC 뒤 0개(`H-175`) / thread 키를 **양쪽** 테이블에
  넣으면 첫 `:Set`이 `.Callbacks`만 비우고 둘째 `:Set`이 죽은 코루틴을 **조용히** resume —
  `ref-plan.md`가 적은 불변식(*"대기자는 `.Callbacks`에만"*)은 가드가 아니라 관례이고 M8
  `:Wait`가 유일한 쓰기 지점이므로 지금은 문제 아님.
- **mock의 인스턴스 불멸성(툴링 사실)**: `claim`된 mock 인스턴스는 참조를 놓아도 `Destroy`
  전엔 GC되지 않는다(실측: inst를 떨어뜨리고 GC 2회 뒤에도 묶인 값 생존). 이유는 의도가
  아니라 **`dataOf`가 weak-key·강한 값(Luau엔 ephemeron 없음)**이라 `data → changed 시그널 →
  gcconn 클로저 → inst`로 키가 자기 값을 통해 살아남기 때문. 결과적으로 `lifecycle-pattern.md`
  (0)의 *"quad가 만든 Instance는 … 반드시 `Destroy`로 회수된다"*와 같은 관측을 주지만 근거가
  다르다 — 다음 단위 GC 테스트는 만든 인스턴스를 **반드시 `Destroy`**할 것(안 하면 그
  인스턴스에 묶인 값 전부가 뒤 테스트의 GC 단언에 남는다).

**단위 1 끝 절차 기록**: 감사 루프 8라운드(발견 3→4→1→2→4→4→1→0, 5·6라운드 절반은
각도를 넓혀 잡힌 옛 같은-파일 절 인용 부채) → `/code-review high` 1회 10건: ② 셋(`H-168`~
`H-170`), ① 셋(`H-171`~`H-173`), 잔손질 셋(`smoke.init` 5절 → typechecked `spec.init.luau` /
`conventions.md`의 단위 나열 제거 / 코드 주석의 절 인용을 제목 앞부분으로), 그리고
기각 셋(gcconn 슬롯 중복·mock claim 불멸·공유 본문 빌더 — 전부 `lifecycle-pattern.md`
(0)/(1) 그대로이거나 `claim-plan.md` §7-9가 이미 기각한 모양).

**단위 3·4 (탐사자, 2026-08-29)** — 커밋 `dca789e`..`3670e88`, 신선한 컨텍스트, `git stash` 안 씀:
- **실행**: `./scripts/test.sh` 전체 — relink 39 갱신, `luau-analyze quad-base/src + spec.* +
  mock.luau` 진단 0, 20파일 전부 `ALL PASS`. `grep -rn "TODO(H-" quad-base quad-types` —
  추적 파일에 여섯(`H-182`~`H-187`), §4 표와 1:1(`roblox_packages/` 안의 `quad_types` 사본에
  `H-187`이 한 번 더 보이는데 relink 복사본이고 무시 대상).
- **한 줄 대조(코드 ↔ `base/` 절), 코드가 어긋난 곳 없음** — 어긋난 건 전부 문서 쪽 옛 문장
  (`H-191`~`H-196`): `Observer.luau` ↔ `source-state-plan.md` "전파 루프 — 확정 의사코드"
  (`_receive` 게이팅·홀드, `_catchUp` 유일 재생 자리, 생성자 순서 fn → 플래그 → `_subs`,
  `alwaysObserve`가 `targetState:Get()`), `lifecycle-pattern.md` "(2) 전역 경로"(네 진입점
  토큰 단위 동일 — 인라인 게이트, `H-133` 관대/엄격, 양쪽 테이블 해제, `error(…, 2)`가 본문에) /
  `Effect.luau` ↔ `effect-plan.md` "의사코드 — 생성자"(`select("#")` 검증 셋, dep 종류별 클로저
  둘, `fire`의 `from == nil` → `Update` → `Rerun`, `isEpoch` 시딩 — `TrackFrom(d.valueEpochMap)`
  자리만 단위 2의 `d:_track(map)` 훅), `_bindDestroying`/`_unbindDestroying`/`_consumeCleanup`/
  `rawRerun`/`Rerun`(토큰 단위 동일, `local function` 선언 순서까지), "`EffectHandle:Subscribe()`"
  (네 진입점 + `resubscribeTail` + `isRunning` 술어) / `State.luau`의 `GateImpl` ↔ `gate-plan.md`
  "`GateNode` 조립"(`_receive`: `Update`/`Peek`/invalidate/규칙 3 리턴/unfold/정책; `_flush`:
  빈 배치 false → 스왑 → `Sync(batch)` → `_emitDown(batch)`, `emit(false)` 버리기, 스왑 테이블도
  weak `H-9`), 2번(`emit(commit) -> boolean`)·3번(값 안 가림)·8번(빈 배치 no-op) /
  `Blocker.luau` ↔ `blocker-plan.md` "메커니즘 (확정)"(`On`/`Off` 순서/`OffWithoutEmit`/`IsOn`/
  `Policy`/`__apply` 전부, `H-63` 셋 — weak-key 셋, 강한 주인은 `onUpstreamEmit` 클로저의
  업밸류 `handle`, 스냅샷 순회) / `quad-types` ↔ 각 절의 시그니처(`ObserverFn` 세 자리·`emitFrom?`,
  `EffectFn` 팩, `GateEmit`/`GateSetup` 2단, `Blocker` 여섯, `Quad`에 `Effect`/`Blocker`/
  `onDestroying`). 코드가 문서보다 더 가진 것은 이미 기록된 입력 검증(`fn`/`setup` 타입,
  `setup` 반환 검사, `Apply` 객체 검사)과 `H-188`의 detach뿐.
- **런타임 실측(스크래치 프로브 21건, 전부 계약대로)**: (a) `gate-plan.md` "계약 — 게이트는
  emit 경로만 미룬다"의 셋 — 유보 중 형제 plain dep이 깨우면 `fn` 안 `gated:Get()`이 최신 /
  `Unsubscribe`(소진) → `Subscribe`가 유보 중이어도 재설치 1회 / 풀린 배치로 1회 더, 빈 flush는
  무. (b) `H-65` — leaf `Destroy` → cleanup → `canBound` 참 → 다른 inst에 재바인드 → 재설치
  1회 → 새 inst에서 발화. (c) 죽은 바인딩 재사용 — Destroy 뒤 `Observer:Subscribe()` 통과·발화.
  (d) 한 번도 안 묶인 `Effect`/`Observer`/plain에 `unbindLifetime` — 전부 no-op(단위 1 §6의
  의심 닫힘 — `_unbindDestroying`은 `_destroyConn == nil`이면 아무것도 안 한다). (e) leaf-bound
  Effect에 `WeakUnsubscribe` — 조용히 통과하고 gcconn 경로는 그대로(`canExecute` 참, 계속 발화) /
  `Unsubscribe` — `E-11` 그대로 error, cleanup 무손. (f) 다이아몬드 — `Effect(fn, a, a:Compute)`
  1회 / `Effect(fn, a, a:Apply(b))`는 유보 중 직접 dep로 1회, `b:Off()`의 배치는 같은 리비전이라
  **추가 실행 없음**(`_epochs` 키 dedup이 게이트 배치에도 성립). (g) `Ref` dep 재진입(`fn` 안
  `r:Set`) — `_pending` 지연 1회. (h) `H-192` 실측(위). (i) Observer `fn` 예외 — `Set` 밖으로
  전파, Observer는 죽지 않음(재진입 플래그 없음 — 다음 `Set`에 정상 발화; Effect와 다른 계약이고
  문서도 Observer엔 사망을 안 정했다). (j) `H-160` — `Unsubscribe` 경로 cleanup 안 `dep:Set` →
  홀드, 재구독 꼬리 1회. (k) `setup` 안에서 `emit()` — 빈 배치 false, `_onUpstreamEmit = Void`
  덕에 크래시 없음. (l) `GateNode`를 `Compute` dep·`Effect` dep로 — `Get`/`_track` 상속으로
  유보 중 값 가시, 풀리면 하류 1회. (m) unbind → 변경 둘(홀드) → 다른 inst → 정확히 1회. (n)
  `WeakSubscribe`된 Observer에 `bindLifetime` — error 뒤 상태 무변경. (o) 설치 `fn`이 자기
  dep을 `Set` — `_pending` 1회, 플래그 전부 내려감. (p) deps 0개 `Effect`(`slot-plan.md`의
  `_detachCleanup` 모양) — bind/unbind/rebind 무재실행, Destroy 소진, 죽은 뒤 `unbindLifetime`
  안전.
- **M3(디스패치)가 이 코어를 부르는 모양 — 막히는 자리 없음**: `dispatch-core-plan.md`의
  `len:Observer(gatedRecompute)` + `bindLifetime(anchor, observer)`(콜백이 인자를 안 받아도
  됨 — `fn(targetState, self, from)`은 여분 인자), `unbindLifetime(oldObserver)` 뒤 재등록,
  store-bind의 `state:Observer(fn)` + `bindLifetime(inst, observer)` + 클로저의
  `unbindLifetime`; `slot-plan.md`의 `Effect(function() return function() … end end)` deps 0개 +
  `bindLifetime(physicalTarget, …)`/언마운트 `unbindLifetime`/재마운트 재바인드(무재실행)/파괴
  시 `unbindLifetime`(cleanup 미소진 — 손으로 비웠으니 의도); `getBlocker` → `Blocker()` 직접
  사용(`On`/`IsOn`/`OffWithoutEmit`, gated state 없음 — 핸들 0개라 `Off`류가 no-op). 전부
  지금 표면에서 그대로 돈다(위 프로브). **M3가 옮길 때 바꿀 것은 이름 해석 하나** — 문서의
  자유 이름 `bindLifetime`/`canExecute`/`Effect`/`Blocker`는 `InitDispatch(module)`이 쥔
  `module.bindLifetime`…이고 생명주기 넷은 발화 시점에 늦게 읽는다(`H-174` (a)). `quad-types`의
  `Quad`엔 M3가 읽을 값이 전부 있다(`Effect`/`Blocker`/`onDestroying`/생명주기 4/술어 11).
  Slot 재마운트 캐치업(`H-163`)은 `bindLifetime` 안의 `_catchUp()` 한 줄이 맡는다 — mock이
  그렇게 하고 있고 quad-roblox도 같은 줄이 필요하다(`lifecycle-pattern.md` (1)).
- **백엔드 없는 인스턴스(스텁만)의 실제 동작**(툴링 사실): `s:Observer(fn)` 생성과 deps 0개
  `Effect(fn)`은 되지만, `Effect(fn, dep)`은 내부 Observer의 `WeakSubscribe`에서, Observer가
  달린 State의 첫 `Set`은 `_receive`에서 **스텁 에러**가 난다(*"canBound/canExecute is not
  available"*, 위치는 `Observer.luau` 안 — 스텁의 `level 2`가 quad 내부를 가리킨다). 설계대로
  "조용한 no-op 아님"이고, M5가 기본 인스턴스를 감싸기 전엔 반응형을 못 쓴다는 뜻.
- **관측만(발견 아님)**: `b:Off()` 순회 중 하류 Observer가 `b:On()`을 다시 켜도 스냅샷의
  남은 핸들은 그대로 flush된다(`blocker-plan.md` "재진입(네스팅)" 미지원 그대로).

## §6 남은 의심 / 못 본 것

**단위 1 (탐사자, 2026-08-28)**:
- **`H-174`의 결정이 `EpochMap`엔 안 걸리지만 `GateNode`/`Blocker`(단위 4)엔 걸릴 수 있다** —
  `GateNode`는 State 노드라 `canExecute`를 안 보지만(`H-56`), `Blocker`가 Observer/Effect의
  구독 표면을 만지면 같은 인스턴스 문제를 상속한다. 단위 4 전에 다시 볼 것.
- **`unbindLifetime`을 한 번도 안 묶인 `EffectBrand` 값에 부르면 `value:_unbindDestroying()`이
  먼저 돈다**(mock·스케치 동일) — 단위 3의 `_unbindDestroying`은 미연결 상태에서 no-op이어야
  한다(`unbindLifetime`의 *"안 걸려있던 값에 불러도 안전한 no-op"* 계약을 지키려면). 문서엔
  그 요구가 명시돼 있지 않다 — 단위 3 탐사자 몫.
- **quad-roblox 쪽 마일스톤 표기가 둘로 갈린다**: `ROADMAP.md` M5의 `RobloxFactory.luau`가
  `bindLifetime`/`canExecute`를 주입한다고 하고(`architecture.md` 소스 트리 300행도 같음),
  실 구현 체크박스는 M8(1523행)이다. `LifetimeHandle.luau` 도크스트링은 M8을 따랐다. 이
  단위 범위 밖(코드는 어느 쪽이든 같음)이라 발견으로 세지 않고 여기만 적는다.
- **못 본 것**: `Relate` 핫패스 비용(`relate-plan.md` "M2 착수 시 실측 확인")은 측정하지
  않았다 — 아직 핫패스를 부르는 코드가 없다. `ref-plan.md` "API 모양"의 *"`.Value`(읽기
  전용 필드)"*는 타입 레벨(`read` 프로퍼티)로는 강제하지 않는다 — 문서가 타입 강제를
  요구하지 않으므로 발견으로 안 올림.

**단위 3·4 (탐사자, 2026-08-29)**:
- **`H-186`의 이웃(같은 문항에 실어 답할 것, 새 번호 없음)**: dep뿐 아니라 **생명주기
  진입점도** 교차한다 — 실측: `quad`의 Observer `o`에 `other.bindLifetime(inst, o)`를 부르면
  **조용히 성공**하고 `other.canExecute(o) == true`인데 `o`의 `_receive`는 자기 `quad.canExecute(o)`
  (거짓)를 읽어 **영영 안 울린다**. `H-186` (a)를 택한다면 판정 자리가 하나 더 있다(`bindLifetime`
  쪽은 백엔드 코드라 base가 못 막고, 핸들 쪽에서 막으려면 핸들이 자기 `module`을 알아야 한다 —
  임플이 `module`을 닫고 있으니 가능).
- **M3가 Observer의 사적 필드를 직접 쓴다**: `slot-plan.md`의 `materializeSlotTree`가
  `slot._baseObserver._rerunRequired = false`를 대입한다(`H-163` 결정). 접근자는 없고 Luau가
  막지도 않지만 계층 경계를 넘는 쓰기라, M3 탐사자가 다시 볼 자리(이 단위 밖).
- **못 본 것**: `lifecycle-pattern.md` (4)의 *"실측 필요(M0/M2)"* — `canExecute`가 매 발화마다
  `BindData:GetWeak` 2단 조회를 하는 비용은 측정하지 않았다(핫패스 코드가 아직 없음).
  `Debounce`/`Throttle`(백로그)이 `GateNode` 위에 실제로 얹히는지는 정책 스텁(`switchPolicy`)으로만
  확인했다 — 타이머 경로(`setTimeout` 주입 op)는 없다.
- **`H-184`의 마커가 mock에만 있다** — quad-roblox의 `bindLifetime`도 같은 순서라(`lifecycle-pattern.md`
  (1)) 결정이 나면 두 곳(스케치·M8 구현)에 같이 반영해야 한다.
