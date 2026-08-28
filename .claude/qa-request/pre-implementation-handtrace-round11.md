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
| `H-168` | **②** | 1 | 🟡 | `Ref<T>(T)`면 무인자 `Ref()`가 strict에서 TypeError("expects 1 argument") — 그런데 `ref-plan.md`/`lifecycle-hooks-plan.md`/`debounce-throttle-plan.md`가 `Ref()`/`PreRef()`를 관용구로 가르친다 | §4 대기 |
| `H-169` | **②** | 1 | 🟡 | `:Set` 블록이 스냅샷 콜백에 닫힌 인자 `value`를 넘겨서, 콜백 안 재진입 `ref:Set(new)` 뒤 남은 콜백이 **옛 값**을 받는다 — 문서 블록 그대로인데 문서의 "옛 값이 보이는 창이 없다"와 어긋남 | §4 대기 |
| `H-170` | **②** | 1 | 🟡 | `coroutine.resume(k, self)`는 에러를 올리지 않는다 — 대기자 안의 에러·죽은 thread resume이 `:Set`에서 조용히 삼켜짐. `ref-plan.md` *"나중에 `coroutine.resume`이 에러남"*은 사실이 아님 | §4 대기 |
| `H-171` | ① | 1 | 🟡 | mock lazy claim: Destroy된 inst에 다시 bind하면 GC 전엔 죽은 gcconn 재사용, GC 뒤엔 새 Connected gcconn — 결과가 GC 타이밍에 따라 갈림 | ✅ mock: 죽은 inst의 새 gcconn은 즉시 Disconnect(`spec.lifetime` 6b) |
| `H-172` | ① | 1 | 🟡 | mock `Destroy`가 자손을 안 죽이고(조상 파괴 계약 검증 불가), `Parent` 변경 시그널이 연결 해제 뒤라 관측 불가, 재귀 Destroy 무한 루프 | ✅ mock: Destroying → Parent nil → 자손 Destroy → 연결 해제, 이중 Destroy no-op(`spec.lifetime` 6c) |
| `H-173` | ① | 1 | 🟢 | `ROADMAP.md` M7 체크박스·`tween-plan.md` 352가 `isTween`/`TweenBrand`를 `Tween.luau`에 둔다고 아직 서술(감사 3라운드가 두 곳만 고침) | ✅ 반영 |

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

## §4 ⭐ 사용자 결정이 필요한 것 (배치 회신용)

| 문항 | 무엇 | 선택지 | 권고 | 권고 근거 | 옛 메커니즘 복원? |
|---|---|---|---|---|---|
| **`H-168`** | `Ref<T>(T)` vs 무인자 `Ref()` 관용구 | (a) 시그니처 유지, 문서의 빈 호출 관용구를 전부 `Ref<<T?>>()`(nil-able 파라미터는 생략 가능)로 고쳐 씀 / (b) `default: T?`, `.Value: T?`(H-167 이전 모양 — `Ref(5).Value`까지 nil 검사 강요) / (c) 두 오버로드 `Ref<T>(T)` ∪ `Ref<T>() -> Ref<T?>` | **(a)** | "제네릭 시그니처" 확정(단일 파라미터, 명시 확장으로 넓힘)을 그대로 두고 관용구만 그 규칙에 맞추는 것 — (b)는 문서가 기각한 모양, (c)는 그 절이 기각한 2-파라미터 솔버 문제의 재개방 | (b)가 그렇다 |
| **`H-169`** | 재진입 `:Set` 뒤 남은 콜백의 인자 | (a) 블록을 `k(self.Value, self)`로(항상 최신 값, 문서 불변식 그대로) / (b) 문서에 "재진입 시 바깥 파동의 남은 콜백은 자기 파동의 값을 받는다"로 계약화(코드 유지) / (c) 재진입 자체를 금지(error) | **(a)** | 문서 불변식(*"옛 값이 보이는 창이 없다"*)이 이미 (a)를 말하고 있고 한 토큰 차이 — (b)는 인자와 `.Value`가 다른 창을 계약으로 열고, (c)는 새 가드 | 아니오 |
| **`H-170`** | resume이 삼키는 에러 | (a) `local ok, err = coroutine.resume(k, self); if not ok then error(err, 0) end` — 대기자 에러를 `:Set` 호출부로 다시 올림 / (b) UB로 문서화(대기자 에러는 사라진다) / (c) 대기자 소진을 `task.spawn`류 주입 op로(Roblox `task.spawn`은 에러를 콘솔로 보냄) | **(a)** | `architecture.md` "예외 안전성 계약"(감싸지 않는다 = 에러는 전파)과 같은 결. 다만 **새 코드 두 줄(re-raise)** 이라 사용자 결정 자리. (c)는 새 주입 op | 아니오 |

코드 쪽 잔여 마커: `grep -rn "TODO(H-" quad-base/src` — 이 표의 문항과 1:1이어야
한다. **[2026-08-28 기준] 마커 0개** — 위 셋은 단위 1 모듈을 막지 않아 코드는 문서
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

**툴링 사실 둘**(설계 아님, 다음 단위가 알아야 함):
- `require("@self/X")`는 **`init.luau`에서만** 통한다 — 일반 파일에서 `@self`는 그 파일
  자신이라 `could not resolve child component`. 형제 모듈은 `./X`, 패키지는 `../roblox_packages/...`.
- GC 테스트 함정 둘: 같은 프레임의 죽은 레지스터가 임시값을 붙잡는다(별도 함수 안에서
  만들 것) / **불변 업밸류만 잡는 클로저는 Luau가 프로토에 캐시해 영영 GC되지 않는다**
  (테스트 클로저가 업밸류를 직접 변경하게 할 것 — `lifecycle-pattern.md` (0)의
  `false or` 트릭이 막는 것과 같은 최적화).

**단위 1 끝 절차 기록**: 감사 루프 8라운드(발견 3→4→1→2→4→4→1→0, 5·6라운드 절반은
각도를 넓혀 잡힌 옛 같은-파일 절 인용 부채) → `/code-review high` 1회 10건: ② 셋(`H-168`~
`H-170`), ① 셋(`H-171`~`H-173`), 잔손질 셋(`smoke.init` 5절 → typechecked `spec.init.luau` /
`conventions.md`의 단위 나열 제거 / 코드 주석의 절 인용을 제목 앞부분으로), 그리고
기각 셋(gcconn 슬롯 중복·mock claim 불멸·공유 본문 빌더 — 전부 `lifecycle-pattern.md`
(0)/(1) 그대로이거나 `claim-plan.md` §7-9가 이미 기각한 모양).

## §6 남은 의심 / 못 본 것
