# E33 — 레퍼런스 시그니처 전수 대조 (2026-09-27, HEAD `47fad75f`)

`docs/reference/**/*.md`(errors/ 제외)의 **시그니처** 블록(코드 블록형·인라인형 둘 다)·**인자** 표·**반환** 문장을
`quad-types/src/init.luau`·`quad-roblox/src/{types,init}.luau`·생성 `quad-roblox/src/Declaration/init.luau`·
`quad-error/src/init.luau`와 대조했다. 레포 파일 무변경, 산출물은 이 폴더뿐.

## 숫자

- 시그니처 블록 167개(`extract.py` → `extracted.json`), 그 안의 대조 항목 **205**(멤버 + 블록에 같이 적힌 `export type`) + extend/01 op 블록 20(라벨 없는 `name (params) -> ret` 목록, `backend_ops.py`) = **225**.
- 판정: **일치 222 / 불일치 3 / 미대조 0**(전수 표 `TABLE.md`, extend/01 20건은 전부 텍스트 일치). 불일치 셋 외에 타입 결함 둘·판단 필요 셋은 아래 발견에(텍스트는 일치하나 계약이 어긋나는 것).
- 11-predicates의 "전부 `(x: any) -> boolean`" 한 문장은 `Quad` 레코드 724~757행과 `RobloxExtension.isTween`에 대해 확인(일치).

## 방법

1. `extract.py` — 시그니처 블록/인라인 + 같은 절(다음 `#`/`---`까지)의 인자 표·반환 문장.
2. 정적(`static_compare.py` → `source_index.json`, `compare.py` → `static.json`) — 소스 레코드 필드를 괄호 균형으로 뽑아 주석·공백 정규화 후 텍스트 비교. 174 EQ, 나머지 30은 인덱서 한계(setmetatable 레코드·재수출 별칭·같은 이름 별칭)라 기계 프로브와 손으로 판정(`TABLE.md` 소스 열).
3. 기계(`gen_probe.py` → `probe_sigs.luau`, `run_probe.sh` = test.sh 79행 플래그 셋 그대로) — 각 문서 타입을 제네릭 프로브 함수 안에서 `type D = <문서 텍스트>`로 두고 **양방향** 대입(`local _: D = 실제`, `function(d: D) local _: typeof(실제) = d end`). 문서가 좁거나 넓으면 한쪽이 진단. 음성 대조 셋(NEGCTL1~3)을 파일 끝에 두어 프로브가 끝까지 살아 있음을 확인(셋 다 진단). 진단 39 = 전역 경고 1 + 음성 대조 3 + 동일 출력 30줄(19항목, 아래 한계) + 불일치 셋의 진단 4 + 이 폴더 별칭 선택으로 생긴 `Field` 1건(발견 C1과 같은 뿌리).
   - **한계**: 신 솔버는 제네릭 함수 타입끼리의 서브타이핑을 판정하지 못한다 — `AddPlugin`/`UseProvider`/`Source`/`Store`/`Slot`/`Ref`/`PreRef`/`PostRef`/`Peek`/`Alternative`/`Indexed`/`OnCreated`/`OnRendered`/`Fallback`/`Traceback`/`OnChangeFn`/`OutFn`/`:Single`은 expected·got이 **글자 그대로 같게** 찍히며 실패한다(`:Single`은 `t1/t2` 이름만 바뀜). 이 항목은 정적 텍스트 일치로 판정하고, `probe_calls.luau`에서 문서 시그니처대로 호출해 보강했다(전부 통과 — 단 `:Single` 매핑 형태는 발견 B1).
   - `probe_calls.out`의 진단 중 32행(`{ x :: any }`라 `T`가 unknown)·50행(무타입 `q.Modifier`의 `Peek`를 `<<T>>` 없이 부름)·83행(`D.New`를 `<<Frame>>` 없이 부름)은 프로브 작성 쪽 결함이고, 22·77·81행은 의도한 음성(EXPECT-ERR)이 난 것, 35행은 B1, 74행은 A3이다. EXPECT-ERR 중 61행(인라인 `:Compute`를 `q.Out`에)만 진단이 안 났다 — C3.
4. `probe_single*.luau`·`probe_onchange.luau` — 발견 B1·B2·C2 최소 재현. 모든 `.out`은 같은 플래그의 원본 출력. 모든 프로브 첫 줄의 `Type inference failed to complete`는 quad-types를 require만 해도 나는 전역 경고(최소 파일 `probe_single2.luau`에서도 남)라 판정에 쓰지 않았다.
5. `param_names.py` — 제목 괄호의 파라미터 이름 vs 시그니처 vs 인자 표(대부분 파서 잡음·가변 인자 명명 차이; 유효한 것 하나 A5).

## 발견

### (a) 문서 오류

- **A1** `docs/reference/core/09-tag-attr.md:63` — `q.Tag` 시그니처가 `setmetatable<{ Merged: (...TagMarker) -> Tag }, { __call: (self: any, ...TagNames) -> Tag }>`인데 실제(`quad-types/src/init.luau:370`)는 두 가변 인자 모두 `?`가 붙은 `...TagMarker?`·`...TagNames?`다(2026-09-21 `102a3935` "인자 자리 nil은 없음"). 같은 절의 인자 표는 `TagNames?`로 이미 고쳐져 있어 표와 시그니처 블록이 서로 다르다. 기계 대조에서 양방향 모두 진단(`probe_sigs.out` — "the 4th component of the union is `nil`" / "`TagMarker` is not exactly `nil`").
- **A2** `docs/reference/core/09-tag-attr.md:202`·`207` — `q.Tag.Merged` 시그니처 `(...TagMarker) -> Tag`가 실제 `(...TagMarker?) -> Tag`(init.luau:370)보다 좁고(DOC→ACTUAL 방향 진단), 동작 문단의 "`Tag`만 받는 엄격한 철자"도 nil 슬롯을 받는 런타임(`quad-base/src/Tag.luau:136~142`·`204~207` 주석, `q.Tag.Merged(tg, nil)`은 `probe_calls.luau`에서 타입도 통과)을 말하지 않는다.
- **A3** `docs/reference/core/09-tag-attr.md:364` — `type AttrKeyObject = { Name: string }`인데 실제는 `{ read Name: string }`(init.luau:386). 문서 타입대로라면 `k.Name = "Mp"` 쓰기가 되지만 실제 타입은 `Property Name of table 'AttrKeyObject' is read-only`로 거부한다(`probe_calls.out` 74행).
- **A4** `docs/reference/roblox/01-install.md:148~150` — "타입 재익스포트" 목록에 `OutFn`이 빠졌다(`quad-roblox/src/init.luau:197`에서 export). 나머지 열다섯 이름과 클래스별 블록은 실제 export와 일치.
- **A5** (표기만) `docs/reference/core/02-source.md:20` — 제목은 `q.Source(value)`, 시그니처와 인자 표는 `v`. 다른 제목들은 시그니처의 파라미터 이름을 쓴다.

### (b) 타입 결함 — 문서의 계약은 맞는데 타입이 따라오지 못함

- **B1** `docs/reference/core/06-slot.md:455`는 "`Source<string?>`로 `Slot<Instance>`를 `updateFn`으로 매핑해 모는 모양이 그대로 타입 검사를 통과합니다"라고 하지만, `Single: <Item, UD>(self, state: Item? | StateMarker<Item?>, updateFn: (...)?, opts?)`(init.luau:555)는 **명시 타입 인자 없이는** 매핑 형태를 통과시키지 못한다. `probe_single3.luau`: 무주석 람다 `sl:Single(name, function(ctx) return inst end)`는 람다 파라미터가 `unknown`으로 굳어 거부(V1, `Source` 대신 평범한 `string?` 값을 넘겨도 같음 V2); `ctx`를 `Item = string`으로 정확히 주석하면 `No valid instantiation could be inferred for generic type parameter Item … at least: <Source 전개> and at most: string`(V3·V6 — `Item?` 팔이 State 인자 자체를 `Item`의 하한으로 잡는다); 통과하는 것은 `sl:Single<<string, nil>>(…)`(V7)와 `ctx`를 `Item = any`로 주석한 모양(V5 — `quad-roblox/test/spec.slottypes.luau:24`가 바로 이 `Ctx<any, number>` 모양이라 게이트가 이 결함을 못 본다). `:List`는 같은 무주석 람다로 통과(V4 대조군) — 차이는 `updateFn`이 옵셔널이고 `state`에 `Item?` 맨 팔이 있다는 점. `typing-limits.md` 8.19의 "`Item?` 형태의 파라미터 추론은 문제 없었다(`Source<string?>` → `Item = string`)"도 이 실측과 어긋난다. round13 S10이 GS 14 §5 `:Single` 콜백을 8.13 사례로 기록했는데, 그 실패의 일부가 이 추론 결함일 수 있다(좁히지 않음).
- **B2** `docs/reference/roblox/05-onchange.md:50`은 "frozen 디스크립터"라 하고 런타임도 `table.freeze`(`quad-roblox/src/Handlers/OnChange.luau:72`)지만, 사용자가 받는 생성 타입 `OnChangeDescriptor<K> = { Name: K, Callback: … }`(`quad-roblox/src/Declaration/init.luau:2088`)은 `read`가 없어 같은 리터럴 쓰기(`d.Name = "Size"`)를 타입이 막지 않는다(`probe_onchange.luau` W1 — 다른 리터럴은 리터럴 불일치로만 거부). 영향은 작다(쓰면 런타임 에러).

### (c) 판단 필요

- **C1** `docs/reference/roblox/03-d-modifier.md:91`의 `Field<T> = FieldV<T> | ((old: FieldOut<T>?) -> FieldV<T>?)`에서 `FieldOut`은 생성 모듈의 별칭 `Types.FieldOut<T>` = `QuadTypes.FieldOut<T | Tween<T>>`(Declaration/init.luau:53, types.luau:111)인데, 이 페이지는 그 정의를 적지 않고 같은 이름을 `core/08-modifier.md:179`가 `type FieldOut<T> = T | State<T> | None`으로 정의한다. 같은 페이지 116행의 `FieldOutP`를 "Tween 없는 전체형"이라 적은 것으로 미루어 짐작은 되지만, core/08 정의를 따라 읽으면 변환 함수 `old`에 `Tween<T>`가 올 수 있다는 것을 놓친다(이 폴더 프로브에서 `FieldOut`을 quad-types 것으로 두자 `Field`가 불일치로 나온 것이 그 차이). core/08:42가 "백엔드가 생성한 Modifier의 Peek는 그 층을 이미 채워 둔다"고 말하므로 의도는 명확 — roblox/03에 정의를 한 줄 둘지, 그대로 둘지.
- **C2** 같은 이름 `OnChangeDescriptor`가 둘이다 — 패키지 루트가 재수출하는 것은 비제네릭 `{ read Name: string, read Callback: (any) -> () }`(`quad-roblox/src/types.luau:191` → `init.luau:186`)이고, `roblox/05-onchange.md:38`이 보여 주는 것은 생성 모듈의 제네릭 `OnChangeDescriptor<K>`(Declaration/init.luau:2088)다. roblox/01:149는 앞의 것을 재수출 목록에 올리므로, 05를 보고 `RobloxModule.OnChangeDescriptor<"Size">`라고 쓰면 `Generic type 'OnChangeDescriptor' expects 0 type arguments`(`probe_onchange.out` W2). 생성 디스크립터는 재수출 타입에 대입은 된다(W3). 어느 쪽을 공개 이름으로 볼지의 문제.
- **C3** `docs/reference/roblox/05-onchange.md:159` "`:Compute` 결과 같은 파생 `State`는 … 타입 검사에서 걸리고" — 주석 달린 `State<UDim2>` 변수는 거부되지만(`probe_single.luau` H2), 무주석 인라인 `q.Out("Size", s1:Compute(function() return UDim2.new() end))`는 진단 없이 통과한다(H). 새 구멍이 아니라 `typing-limits.md` 8.13의 P-S6b 결론(무주석 `:Compute` 결과는 에러 타입)이 이 자리에 그대로 나타난 것 — 문장에 "주석 달린 결과에 한해"를 붙일지.

### 두 페이지에 같은 심볼

- `state:Observer`(core/03:177 · core/05:70), `q.dispose`(core/06:559 · core/10:99), `q.Detach`/`q.KeyGone`(core/06 · core/10 — 주석 형태만 다름), `q.newMapperClass`(core/10:151 · roblox/04:209), `UseProvider`(core/01:122 · roblox/01:88), `GateEmit`(core/03:192 · sugar/06:127) — 전부 서로 같고 소스와 같다. 이름은 같은데 뜻이 다른 것은 C1(`FieldOut`)과 C2(`OnChangeDescriptor`) 둘.
- `<<T>>` 관행: 호출식·제목에서 `q.X<T>(` 꼴 위반 0건(`mod:As<Class>()`는 메소드 이름 자리표시자라 해당 없음).

## 미완

- 생성 `Declaration` 프로퍼티 팔은 Frame(`FrameParam` 발췌 셋 필드·`Size` setter·`AsFrame`/`AsTextLabel`/`AsGuiObject`)만 기계 대조했고 TextLabel·TextButton은 `probe_calls`에서 간접(설정 모듈 경유 호출)으로만 — 문서가 시그니처로 적은 클래스 예시가 Frame·GuiObject·TextBox(`Font` FieldP, 라벨 없는 블록이라 추출 밖)뿐이라 전용 샘플은 만들지 않았다.
- **인자**·**반환**은 표·문장 텍스트를 사람이 읽어 대조(기계화 안 함); 가변 인자 이름 차이(`...deps` vs `...any`)는 불일치로 세지 않았다.
- 제네릭 함수 19항목은 기계 대입이 솔버 한계로 판정 불가 — 정적 텍스트 일치 + 호출 프로브로 대신했다.
- B1의 GS 14 §5 연결, B1이 `:Single` 외(`OnCreated<<I>>` 등 옵셔널 없는 자리)에도 있는지는 좁히지 않았다.
