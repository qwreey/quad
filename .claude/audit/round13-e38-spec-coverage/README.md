# E38 — 공개 표면의 spec 커버리지 지도 (2026-09-27, HEAD `886626ea`)

레포 파일 무변경. 이 폴더가 산출물 전부다(`scripts/` 계측, `out/` 원자료, `probes/` 미커버 자리 mock 실측, `drafts/` 스펙 초안 — `spec.` 접두 없음).

## 방법

1. `scripts/surface.py` — `scripts/doc-coverage.py`를 **import해서**(수정 없음) 같은 추출(`block_fields`·`INJECTED`·`MEMBER_TYPES`)로 공개 심볼 202개(모듈 키 62 + quad-roblox 확장 6 + 멤버 134)를 뽑는다 → `out/surface.json`.
2. 스크래치 사본(레포 밖)에서 `scripts/patch_copy.py`(줄 번호 보존 — 기존 줄 앞에 붙임): src 모듈에 `error` 래퍼(`@@QERR` — E28 방식), spec/smoke 파일에 지역 `pcall`/`xpcall`(실패 시 `@@PC`)와 지역 `string.find`/`match`(성공 시 그 문자열에 든 `QuadNNNN`마다 `@@FIND`) 심. `scripts/patch_opts.py` — 옵션 소비 입구 다섯(`Debounce.make`·`Tween.newTween`·`Animate`·`Slot:List`·`Slot:Single`) 같은 줄에 옵션 키·값 로그(`@@OPT`).
3. `scripts/run_cov.sh` — smoke 3 + quad-base spec 39 + quad-roblox spec 20 = 62개를 `luau --coverage`(네이티브 lcov: 함수별 FNDA·줄별 DA)로 각각 실행, 전부 exit 0. `scripts/merge_cov.py`가 패키지 사본 경로(`luau_packages/.pesde/…/quad_base/src/X`)를 레포 경로로 접어 합산 → `out/fn.json`·`out/lines.json`, 실행 로그는 `out/logs/`.
4. `scripts/members.py`(표 1), `scripts/errors.py`(표 3), 옵션은 `@@OPT` 집계(표 2), 문서 약속은 opus 서브에이전트 둘이 페이지별 핵심 주장 3~8개를 뽑아 spec grep으로 대조(`out/claims-A.tsv`·`out/claims-B.tsv`, 표 4).
5. 미커버로 나온 자리 — 실행 안 된 src 줄 89개(`out/uncovered-lines.txt`), 어느 spec도 안 던지는 에러 id, 비기본값을 안 받는 옵션 키, 미단언 문서 약속 — 중 공개 경로로 닿는 것을 mock에서 하나씩 밟았다(`probes/*.luau` + `.out.txt`; 실행하려면 스크래치 사본의 `quad-base/test/`·`quad-roblox/test/`에 두고 `luau`).

## 숫자

- **src 커버리지**: 함수 635개 중 미호출 21(대부분 E28 방식 `error` 래퍼 자신·도달 불가 `implFor`·`__tostring` 둘·타입 전용 `tweenMapped`), **줄 4402개 중 미실행 89**(`out/uncovered-lines.txt` — Slot/List 14·Slot/Raw 12·Bookkeeping 12·Slot/Tree 11·Effect 6 …).
- **표 1 멤버**: 202 / 미커버 0. spec이 직접 부르지 않고 간접으로만 실행되는 것 2(`q.isMapperDescriptor` — Claim 내부 1266회; `effect:Rerun()` — Effect 내부 40회, spec 직접 호출 0). `q.Backend` hold op 넷은 `spec.lifetime`이 이름 문자열 루프로 부른다(정적 grep 0이지만 직접 커버).
- **표 2 옵션 키**: 36(Debounce 5·Throttle 4·SlotListOpts 1·TweenOptions 13·AnimateInfo 13) / 비기본 유효값 미사용 9(`Tween.Direction`·`Tween.RepeatCount`, `Animate`의 `Info`·`Direction`·`RepeatCount`·`Reverses`·`DelayTime`·`Started`·`Cancelled`) + 부분 1(`Tween.Reverses`는 필드 보존만 단언, TweenInfo 위치 인자 대조 없음).
- **표 3 에러 ID**: 248 / 메시지 단언(MSG) 189 / 실패만 단언(FAIL) 34 / 트리거만(TRIG) 0 / 미커버(NONE) 25(공개 경로로 닿는 15 + 내부 불변식·도달 불가 10). spec이 던진 id 223 = E28의 "spec 223"과 일치.
- **표 4 문서 약속**: 표본 131(core 9페이지 51 + 나머지 15페이지 80) / 단언 97 / 부분 18 / 미단언 14 / 엔진 전용 2. 미단언·부분 중 mock으로 닿는 것 13건을 밟아 봄 — 12건 문서대로, 1건 문서 오류(아래 발견 (a)1).

## 표 2 — 옵션 키 (비기본 유효값이 소비 입구에 닿았나)

| 옵션 | 키 | spec이 넘긴 값(유효) | 판정 |
|---|---|---|---|
| Debounce | Time / Leading / Trailing / MaxTime / Handle | number·State / true / false / number·State / Ref | 전부 커버 |
| Throttle | Time / Leading / Trailing / Handle | number·State / false / false / Ref | 전부 커버 |
| SlotListOpts | OwnsElements | false(List 37·Single 29) | 커버 |
| TweenOptions | Value·Info·Time·Style·DelayTime·Override·Dedup·Started·Completed·Cancelled | 유효값 | 커버 |
| TweenOptions | Reverses | true — `spec.tween:35` 필드 보존만 | 부분 |
| TweenOptions | **Direction** | 한 번도 안 넘김 | 미커버 (MED) |
| TweenOptions | **RepeatCount** | `true`(거부 테스트)만 | 미커버 (MED) |
| AnimateInfo | Time·Style(State)·Override·CanAnimate(false·State)·Dedup·Completed | 유효값 | 커버 |
| AnimateInfo | **Info·Direction·RepeatCount·Reverses·DelayTime·Started·Cancelled** | 한 번도 안 넘김 | 미커버 (MED — Animate가 필드별 `resolve`로 Tween에 싣는 경로) |

프로브 `probes/e38probe_tween.luau`: 아홉 다 문서대로 — TweenInfo 위치 인자 `(Time, Style, Direction, RepeatCount, Reverses, DelayTime)`가 정확히 채워지고(`0.5,Quad,In,2,true,0.25`), Animate의 State 값 `Direction`은 다음 값 변경 때 반영(값 변경 없이 State만 바뀌면 새 트윈 없음), `Started`는 첫 스냅과 엔진 재생에서 한 번씩, `Cancelled`는 교체 때 1회.

## 표 3 — 에러 ID (MSG 아닌 59건)

→ `out/tables-1-3.md`의 표 3(전수), 원자료 `out/errors.json`. 요지:
- **NONE 공개 경로 15**(0003·0012·0045·0089·0134·0140·0142·0145·0156·0180·0190·0230·0231·0234·0235): `probes/e38probe_effect|misc|slot`에서 전부 트리거, 메시지·조건 모두 문서(`docs/reference/errors/*.md`)대로. 0134는 CLI의 메인 청크가 yield 가능이라 `table.sort` 비교자·`__index` 안에서만 난다(문서의 "메타메소드/C 호출 경계"와 일치).
- **NONE 내부 10**(0004·0009 도달 불가, 0024·0071·0098·0117·0163·0192 내부 불변식, 0164 선행 게이트가 먼저 막음, 0229 차단기 창 안에서만) — E28 결론 그대로, 위험도 LOW.
- **FAIL 34**: 실패는 단언하지만 id·문구를 안 본다(대부분 blame만 `assertBlamesUser`로 봄) — 0001·0006·0011·0014·0015(Attr), 0051~0057·0063~0067(Modifier), 0088·0090~0094(Effect), 0147·0165·0166·0168·0174·0242(Slot), 0188·0189(Gate), 0207(Tag), 0222·0223(OnChange), 0034(Claim). 다른 id로 바뀌어도 spec이 못 잡는다 — LOW.

## 표 1 — 멤버

→ `out/tables-1-3.md` 표 1(202행), `out/members.tsv`. 미커버 0, 간접만 2(`q.isMapperDescriptor` LOW, `effect:Rerun()` MED — 아래 발견 참고).
생성 `Declaration`: 클래스 32 중 spec이 생성하는 것 10(Frame·TextLabel·TextButton·ScrollingFrame·ImageButton·ImageLabel·TextBox·UIStroke·UIListLayout·UIGradient) + `New`·`Mapper`·`Modifier`. 나머지 22(BillboardGui·Camera·CanvasGroup·Folder·ScreenGui·SurfaceGui·UI* 제약·레이아웃류·VideoFrame·ViewportFrame·WorldModel)는 생성기가 같은 팩토리를 찍어 내는 자리라 LOW(런타임 경로 동일, 타입은 `spec.d`·`gen-d check`가 본다).

## 표 4 — 문서 약속

전수는 `out/claims-A.tsv`(core 01~07·10·11)·`out/claims-B.tsv`(core 08·09, extend/02, roblox 01~06, sugar 01~06). 미단언(14)과 핵심 부분 — 옆은 mock 실측 결과(`probes/e38probe_claims|b|into|effect`):

| 페이지:줄 | 약속 | 분류 | 실측 |
|---|---|---|---|
| core/01:58 | 던진 `initFn`은 다시 `RunInit`해도 no-op | 미단언 | 문서대로(calls 1) |
| core/04:79 | 선언 안 한 키 점 읽기는 nil, 지연 생성 없음 | 미단언 | 문서대로 |
| core/05:300 | `WeakUnsubscribe`는 cleanup을 안 건드림 | 미단언 | 문서대로(0회, 뒤 `Unsubscribe`에서 1회) |
| core/06:157 | `Add` 범위 밖 Quad0236·비정수 Quad0168 | 미단언(`Add` 입구) | 문서대로(0·-1도 0168) |
| core/06:397 | `:List` 중복 키 Quad0145 | 미단언 | 문서대로, 거부 뒤 목록 그대로·다음 Set 정상 |
| core/06:404 | State에 담은 원소는 어느 버림 경로에서도 안 죽음 | 부분(Remove·Extract만) | Replace·Clear(마운트 전후)·Splice·KeyGone·`dispose(slot)`·부모 Remove 전부 문서대로 |
| core/10:182 | `unbindLifetime`은 Effect cleanup을 안 부름 | 부분 | 문서대로 |
| core/05:155 등 | "already bound to an Instance" 넷(0230·0231·0234·0235) | 부분 | 문서대로 |
| core/08:132 | 변환이 nil을 돌려줌: 평범한 값이면 필드 사라짐, State면 `State<nil>` | 미단언 | 문서대로 |
| extend/02:343 | `releaseOwner` 남의 ownerKey → Quad0163 | 미단언 | 안 밟음(내부 부기 계약, LOW) |
| roblox/03:239 | `Into<Class>` 자리에 커스텀 클래스 Modifier도 들어옴 | 부분 | **문서 오류 — 발견 (a)1** |
| roblox/05:181 | `q.Out`+Tween 같은 프로퍼티면 첫 프레임에 멈춤(캐비엇) | 미단언 | 안 밟음(문서가 mock 실측 인용) |
| sugar/02:30 | 호출 안 한 팩토리 `Apply(Op.Sum)`은 함수를 조용히 돌려줌 | 미단언 | 문서대로(`:Get`에서 VM 에러) |
| sugar/02:249 | None: Alternative 통과·Indexed nil·산술 거부 | 미단언 | 문서대로(Quad0122) |
| sugar/03:45 | 타이머 통과 중 하류가 던지면 leading 하나 잃음(캐비엇) | 미단언 | 안 밟음 |
| sugar/03:97 | `Debounce{ Trailing = false }` 하나만으로 Quad0048 | 부분 | 문서대로 |
| sugar/04:75 | OnRendered 시점 부모 부착 보장 없음(캐비엇) | 미단언 | 엔진 쪽 — 안 밟음 |
| sugar/05:25 | 첫 반환값만 경계를 넘음 | 미단언 | 안 밟음(LOW) |
| sugar/06:105 | OffWithoutEmit 뒤 중첩 State 안쪽 구독이 옛 안쪽에 남음(캐비엇) | 미단언 | 안 밟음(문서가 mock 실측 인용) |

## 발견

### (a) 문서 오류

1. **`docs/reference/roblox/03-d-modifier.md:239-262` — 커스텀 클래스 Modifier를 문서 예시대로 받으면 런타임에 던진다.** 239줄은 "`As<Class>()`를 구현한 커스텀 클래스의 것도 다 들어옵니다", 259~262줄은 `TypedFactory`+`DefineSubtype`으로 만든 커스텀 클래스가 "`Into<Class>` 자리에서 `FrameModifier`와 같은 지위"라고 적고, 바로 위 `Themed` 예시는 `props.Modifier:AsTextButton()`을 부른다. 그런데 `DefineSubtype("TextButton", "MaterialButtonSpec")`으로 만든 하위 클래스 값에 검사형 `:AsTextButton()`을 부르면 `Quad0056 Modifier: cannot cast a "MaterialButtonSpec" modifier to "TextButton" — not an ancestor (use :As(name) to force)`로 던진다(검사형 As는 하강 전용 — `quad-roblox/test/spec.component.luau:131`이 "checked upcast is rejected by design"으로 단언하고, 거기 컴포넌트는 무검사 `:As("TextButton")`을 쓴다). 문서 예시의 `Themed`에 커스텀 클래스 Modifier를 넘기면 깨진다 — 타입 층에서만 맞는 약속을 런타임까지 늘여 쓴 서술. 재현 `probes/e38probe_into.luau`(+`.out.txt`). 서브에이전트 B가 짚었고 메인이 재현.

### (b) 코드 결함

없음. 미실행 src 줄 89개 중 공개 경로로 닿는 것을 전부 mock에서 밟았고 전부 문서대로였다: Slot `Replace`/`Extract`의 Slot↔plain 교체(마운트 상태)·마운트 전 교체, `:List`의 `OwnsElements=false` Detach·보관 키가 새 원소로 돌아옴·보관 원소의 주인 Slot 파괴/부모 Instance 파괴 동반사·이미 마운트된 빈 Slot에 `:List` 설치·중복 키·비배열 data, Debounce `MaxTime` 캡 해제(창이 먼저 닫힘·Flush·Cancel), `effect:Rerun()` 네 갈래(즉시·보류 뒤 Subscribe에서 1회·fn 안 재요청 병합·cleanup 안 요청), 공개 경로 NONE 에러 id 15, Tween/Animate 옵션 아홉. 남은 미실행 줄은 내부 불변식 raise, 재진입 되감기(`quad-base/src/Bookkeeping.luau:213-216·262-264·294-296` — 길이 State의 `Get`이 같은 owner를 바꿀 때만, Compute 순수성 원칙상 UB 자리), 도달 불가 `return Void` 넷, 방어 nil 게이트(`quad-roblox/src/LifetimeHandle.luau:84·106·115`), 그리고 `quad-base/src/Slot/Raw.luau:213-220`(마운트 walk 창 안의 "materialize됐지만 미마운트" 상태에서만 — `_materializing` 게이트가 CRUD를 막음; State<Slot> 자리에서 빠진 Slot은 `_physicalTarget`까지 지워져 203줄 갈래로 간다, `probes/e38probe_slot2`).

### (c) 판단 필요

1. **언마운트된 Slot의 `Length`는 마지막 마운트 값에서 멈춘다(문서 공백).** `core/06-slot.md`의 `slot.Length` 절은 "마운트 전에는 0"만 말하는데, 한 번 마운트됐다가 떨어진 Slot(State<Slot> 자리에서 교체됨, 부모에서 `Extract`됨)은 `Length`가 마지막 값으로 남고 그 뒤의 `Add`·`Remove`·`Replace`를 반영하지 않다가 다시 마운트되면 맞춰진다(`probes/e38probe_len`: 언마운트 뒤 Add·Add·Remove → 원소 3개인데 Length 2; Extract된 Slot에 Add → 그대로 1). "물리 원소의 총 개수"라는 동작 문장과도 어긋나 보인다. 동작을 바꿀지 문서에 "떨어져 있는 동안은 마지막 값에 멈춘다"를 적을지는 결정 — 부기 재계산이 마운트 뒤에만 도는 설계의 자연한 결과이고 문서가 반대를 약속하지도 않아 결함으로 단정하지 않았다.
2. **spec으로 올릴 후보** — `drafts/uncovered-assertions.luau`(`spec.` 접두 없음, HEAD에서 ALL PASS): 위 (b) 목록의 base 쪽 전부. Tween/Animate 옵션 아홉은 `probes/e38probe_tween.luau`가 초안 겸 실측. FAIL 34건에 id 문자열 단언을 더할지도 판단 몫(지금은 다른 id로 바뀌어도 spec이 못 잡음).
3. 생성 `Declaration` 32클래스 중 spec이 인스턴스를 만드는 건 10 — 같은 생성 팩토리라 LOW로 뒀다.

## 미커버 상위 10 (위험도순)

1. `effect:Rerun()` — 공개 메소드, spec 직접 호출 0 (MED)
2. `:List` 보관(Detach) 원소의 주인 Slot 파괴·부모 Instance 파괴 동반사 — `Slot/Tree.luau:203-206`, `Slot/List.luau:188-192` (MED)
3. `:List` 중복 키 Quad0145·비배열 data Quad0142 (MED)
4. `Slot:Replace`/`Extract`의 Slot↔plain 교체(마운트 상태) — `Slot/Raw.luau:231-232·241-242` (MED)
5. `:List` 보관 키가 새 원소로 돌아옴 — `Slot/List.luau:77-79` (MED)
6. 이미 마운트된 빈 Slot에 `:List` 설치 — `Slot/List.luau:256-257` (MED)
7. `Tween.Direction`·`RepeatCount` 유효값, Animate의 `Info`·`Direction`·`RepeatCount`·`Reverses`·`DelayTime`·`Started`·`Cancelled` 전달 (MED)
8. "already bound to an Instance" 넷(0230·0231·0234·0235)과 `WeakSubscribe` 이중 0089 (MED)
9. Debounce `MaxTime` 캡 해제 경로 — `Debounce.luau:178-179` (LOW-MED)
10. `slot:Add` 입구의 인덱스 게이트(0236·0168), FAIL 34건 id 미단언 (LOW)

## 미완

- 문서 약속은 페이지당 3~8개 표본(131) — 문장 전수 아님. 미단언 중 6건(`releaseOwner` 0163, `q.Out`+Tween, Debounce leading 손실, OnRendered 부모, Fallback 다중 반환, OffWithoutEmit 중첩)은 밟지 않았다.
- 멤버 표의 `stat`은 정적 이름 매칭이라 흔한 이름(`Set`/`Get`/`Apply`)은 과대계수 — 판정은 `dyn`(함수 실행)을 우선했다. 필드·값(`Length`·`None` 등)은 `stat`만 있다.
- 엔진 전용 2건(Claim IsA 하위 클래스, OnChange 기본값 무발화)은 CLI에서 볼 수 없다.
