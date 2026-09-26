# E21 blame 매트릭스 (자동 생성 — build_table.py)

판정 기호: USER = 사용자 호출 줄 / USER-INNER = 콜백 안 호출 줄 / OUTER = 콜백을 일으킨 바깥 `s:Set` 줄(outermost) / USER-P·USER-T = 2줄 변형에서 값을 만든 줄·마운트/Set 줄 / LEAF 파일:줄 = quad 잎.

| ID | 호출 표면(최소 호출) | 레벨 | 관측 blame — 직접/2줄 | 관측 blame — 콜백(Observer fn 안) | 문서 "언제" | 메시지 vs 문서 | 비고 |
|---|---|---|---|---|---|---|---|
| Quad0001 | AttrKey(''); AttrKey(5) | BeforeNearest | USER×2 | USER-INNER×2 | 일치 | 일치 |  |
| Quad0002 | AttrKey vs group same name | Before(outermost) | USER | OUTER | 일치 | 일치 |  |
| Quad0003 | — | BeforeNearest | 도달 불가/내부 | — | **불일치** — `Store`가 빈 이름을 못 가짐(생성자·`:Of` 둘 다 `Quad0193`이 먼저) | 소스=문서 | 도달 못함(다른 ID가 먼저 — 비고); 문서는 도달 가능하게 적었지만 0004/0009처럼 공개 표면에서 닿지 않음 |
| Quad0004 | — | BeforeNearest | 도달 불가/내부 | — | 일치(문서도 도달 불가라고 씀) | 소스=문서 | flattenArg(Store, overwrite=false) — no public caller (Merged/Overridden gate isAttr first);  |
| Quad0005 | Attr.Merged dup | BeforeNearest | USER | USER-INNER | 일치 | 일치 |  |
| Quad0006 | Attr({[1]=5}) | BeforeNearest | USER | USER-INNER | 일치 | 일치 |  |
| Quad0007 | Attr fn value | BeforeNearest | USER | USER-INNER | 일치 | 일치 |  |
| Quad0008 | Attr table value | BeforeNearest | USER | USER-INNER | 일치 | 일치 |  |
| Quad0009 | — | BeforeNearest | 도달 불가/내부 | — | 일치(문서도 도달 불가라고 씀) | 소스=문서 | flattenArg(plain, overwrite=false) — no public caller;  |
| Quad0010 | Attr(5) | BeforeNearest | USER | USER-INNER | 일치 | 일치 |  |
| Quad0011 | Attr.Merged(5) | BeforeNearest | USER | USER-INNER | 일치 | 일치 |  |
| Quad0012 | Attr.Overridden(5) | BeforeNearest | USER | USER-INNER | 일치 | 일치 |  |
| Quad0013 | NumberAttr('',1); StringAttr('',x) | BeforeNearest | USER×2 | USER-INNER×2 | 일치 | 일치 |  |
| Quad0014 | StringAttr(a,nil) | BeforeNearest | USER | USER-INNER | 일치 | 일치 |  |
| Quad0015 | BooleanAttr(a,5); StringAttr(a,5) | BeforeNearest | USER×2 | USER-INNER×2 | 일치 | 일치 |  |
| Quad0016 | group at two positions | Before(outermost) | USER | OUTER | 일치 | 일치 |  |
| Quad0017 | Blocker:Policy(5) | BeforeNearest | USER | USER-INNER | 일치 | 일치 |  |
| Quad0018 | Blocker:__apply(5) | BeforeNearest | USER | USER-INNER | 일치 | 일치 |  |
| Quad0019 | getOffsetAt(f,0); setEmpty(f,0); setLength(f,0,0); setOffsetSource(f,1.5,None) | BeforeNearest | USER×4 | USER-INNER×4 | 일치 | 일치 |  |
| Quad0020 | getOffsetAt(nil,1); setEmpty(nil,1); setLength(nil,1,0) | BeforeNearest | USER×3 | USER-INNER×3 | 일치 | 일치 |  |
| Quad0021 | setLength State -1 on Set; setLength(f,1,-1) | BeforeNearest | USER×2 | USER-INNER×2 | 일치 | 일치 |  |
| Quad0022 | getOffsetAt far inside List updateFn; getOffsetAt far inside updateFn, mount [2줄]; getOffsetAt(f,5) | Before(outermost) | USER×2, USER-T | OUTER×2 | 일치 | 일치 | Q89(getOffsetAt) |
| Quad0023 | handler-author: setLength without setOffsetSource; optional props.Ref nil hole; props nil hole {a,nil,b} | error(…,1/2) | LEAF Bookkeeping.luau:248×3 | LEAF Bookkeeping.luau:248×3 | 일치 | 일치 | `error(…, 1)` — 세 경로(리터럴 `{a,nil,b}`·옵셔널 `props.Ref` nil·핸들러 작성자의 setLength 단독) 전부 `Bookkeeping.luau:248` (Q88 보강 E16과 같은 자리) |
| Quad0024 | setOffsetSource w/o setLength | error(…,1/2) | LEAF Bookkeeping.luau:288 | LEAF Bookkeeping.luau:288 | 부분 — 문서는 '내부 불변식'이라 했지만 공개 `q.Bookkeeping` op로 핸들러 작성자가 닿음 | 일치 | `error(…, 1)` → `Bookkeeping.luau:288`; 메시지가 핸들러 작성자에게 말하는데 그 사람의 줄이 안 나옴 |
| Quad0025 | setOffsetSource(f,1,5) | BeforeNearest | USER | USER-INNER | 일치 | 일치 |  |
| Quad0026 | newMapperClass('') | BeforeNearest | USER | USER-INNER | 일치 | 일치 |  |
| Quad0027 | descriptor twice | Before(outermost) | USER | OUTER | 일치 | 일치 | Claim 1패스(디스크립터 모양) — outermost, 콜백 안에선 바깥 줄(Q89 표에 없음) |
| Quad0028 | two descriptors same inst | Before(outermost) | USER | OUTER | 일치 | 일치 | Claim 1패스 — outermost(Q89 표에 없음) |
| Quad0029 | Claim D-made root | Before(outermost) | USER | OUTER | 일치 | 일치 | Claim 1패스 — outermost(Q89 표에 없음) |
| Quad0030 | mapper props not table | Before(outermost) | USER | OUTER | 일치 | 일치 | Claim 1패스 — outermost(Q89 표에 없음) |
| Quad0031 | Claim [0] key | Before(outermost) | USER | OUTER | 일치 | 일치 | Claim 1패스 — outermost(Q89 표에 없음) |
| Quad0032 | no child matched | Before(outermost) | USER | OUTER | 일치 | 일치 | Claim 1패스 — outermost(Q89 표에 없음) |
| Quad0033 | Claim(5) inside List updateFn; Claim(5) inside updateFn, mount [2줄]; Claim(5,desc) | Before(outermost) | USER×2, USER-T | OUTER×2 | 일치 | 일치 | Q89 — 인자 검증인데 outermost |
| Quad0034 | Claim(inst,5) | Before(outermost) | USER | OUTER | 일치 | 일치 | Q89 |
| Quad0035 | Provider(5) | BeforeNearest | USER | USER-INNER | 일치 | 일치 |  |
| Quad0036 | ctx:Get(5); ctx:Peek(5); ctx:Set(5,1) | BeforeNearest | USER×3 | USER-INNER×3 | 일치 | 일치 |  |
| Quad0037 | ctx:Set(P,nil) | BeforeNearest | USER | USER-INNER | 일치 | 일치 |  |
| Quad0038 | ctx:Get unset | BeforeNearest | USER | USER-INNER | 일치 | 일치 |  |
| Quad0039 | Time State -1 at signal | Before(outermost) | USER | OUTER | 일치 | 일치 |  |
| Quad0040 | Debounce{} | BeforeNearest | USER | USER-INNER | 일치 | 일치 |  |
| Quad0041 | Time=-1 | BeforeNearest | USER | USER-INNER | 일치 | 일치 |  |
| Quad0042 | Leading=5 | BeforeNearest | USER | USER-INNER | 일치 | 일치 |  |
| Quad0043 | factory:__apply(5) | BeforeNearest | USER | USER-INNER | 일치 | 일치 |  |
| Quad0044 | Handle reused | Before(outermost) | USER | OUTER | 일치 | 일치 |  |
| Quad0045 | Debounce(5); Throttle(5) | BeforeNearest | USER×2 | USER-INNER×2 | 일치 | 일치 |  |
| Quad0046 | Throttle MaxTime | BeforeNearest | USER | USER-INNER | 일치 | 일치 |  |
| Quad0047 | Handle=5 | BeforeNearest | USER | USER-INNER | 일치 | 일치 |  |
| Quad0048 | both false | BeforeNearest | USER | USER-INNER | 일치 | 일치 |  |
| Quad0049 | Peek('') | BeforeNearest | USER | USER-INNER | 일치 | 일치 |  |
| Quad0050 | Apply(5) | BeforeNearest | USER | USER-INNER | 일치 | 일치 |  |
| Quad0051 | As(5) | BeforeNearest | USER | USER-INNER | 일치 | 일치 |  |
| Quad0052 | As('NoSuch') | BeforeNearest | USER | USER-INNER | 일치 | 일치 |  |
| Quad0053 | Overridden() | BeforeNearest | USER | USER-INNER | 일치 | 일치 |  |
| Quad0054 | Overridden(5) | BeforeNearest | USER | USER-INNER | 일치 | 일치 |  |
| Quad0055 | AsUnknownClass() | BeforeNearest | USER | USER-INNER | 일치 | 일치 |  |
| Quad0056 | TextLabel mod AsFrame | BeforeNearest | USER | USER-INNER | 일치 | 일치 |  |
| Quad0057 | mod:Size(Ref); mod:Size(fn→Ref) | error(…,1/2) | USER×2 | USER-INNER×2 | 일치 | 일치 |  |
| Quad0058 | mod[5] | BeforeNearest | USER | USER-INNER | 일치 | 일치 |  |
| Quad0059 | Modifier{['']=1} | BeforeNearest | USER | USER-INNER | 일치 | 일치 |  |
| Quad0060 | Modifier{Peek=1} | BeforeNearest | USER | USER-INNER | 일치 | 일치 |  |
| Quad0061 | Modifier{AsFrame=1} | BeforeNearest | USER | USER-INNER | 일치 | 일치 |  |
| Quad0062 | Modifier{__x=1} | BeforeNearest | USER | USER-INNER | 일치 | 일치 |  |
| Quad0063 | Modifier{Size=fn} | BeforeNearest | USER | USER-INNER | 일치 | 일치 |  |
| Quad0064 | Modifier{Size=Ref} | BeforeNearest | USER | USER-INNER | 일치 | 일치 |  |
| Quad0065 | Modifier(5) | BeforeNearest | USER | USER-INNER | 일치 | 일치 |  |
| Quad0066 | DefineSubtype('',x); TypedFactory('') | BeforeNearest | USER×2 | USER-INNER×2 | 일치 | 일치 |  |
| Quad0067 | DefineSubtype cycle | BeforeNearest | USER | USER-INNER | 일치 | 일치 |  |
| Quad0068 | Modifier at string key | Before(outermost) | USER | OUTER | 일치 | 일치 |  |
| Quad0069 | PreRef twice | Before(outermost) | USER | OUTER | 일치 | 일치 |  |
| Quad0070 | State value chain cycle | Before(outermost) | USER | OUTER | 일치 | 일치 |  |
| Quad0071 | — | error(…,1/2) | 도달 불가/내부 | — | 일치(내부 불변식) | 소스=문서 | retractRange chain hole — internal invariant (process gates the gap with Quad0075); `process`가 구멍 index를 `Quad0075`로 먼저 막음 |
| Quad0072 | getHandler(nil,...); process(nil,...); retractFrom(nil) | BeforeNearest | USER×3 | USER-INNER×3 | 일치 | 일치 |  |
| Quad0073 | process index 0; retractFrom index 1.5 | BeforeNearest | USER×2 | USER-INNER×2 | 일치 | 일치 |  |
| Quad0074 | getHandler key nil; process key nil | BeforeNearest | USER×2 | USER-INNER×2 | 일치 | 일치 |  |
| Quad0075 | process gap index | BeforeNearest | USER | USER-INNER | 일치 | 일치 |  |
| Quad0076 | no handler [{}]=1; typo key size=1 | helper→errorBefore | USER×2 | OUTER×2 | 일치 | 일치 | 문서 템플릿은 `brand:` 조각을 항상 쓰지만 브랜드 없는 값에선 조각이 빠짐(템플릿 표기상 조건부 — 글자 불일치 아님으로 처리) |
| Quad0077 | handler no retractor | helper→errorBefore | USER | OUTER | 일치 | 일치 |  |
| Quad0079 | addHandler(5) | BeforeNearest | USER | USER-INNER | 일치 | 일치 |  |
| Quad0080 | addHandler NaN priority | BeforeNearest | USER | USER-INNER | 일치 | 일치 |  |
| Quad0081 | addHandler keyType x | BeforeNearest | USER | USER-INNER | 일치 | 일치 |  |
| Quad0082 | drive(f,5) | Before(outermost) | USER | OUTER | 일치 | 일치 | Q89(drive) |
| Quad0083 | D.Frame(Source); drive(f,Source) | Before(outermost) | USER×2 | OUTER×2 | 일치 | **불일치** | Q89(drive); 문서 템플릿에 `\{ ... \}` 백슬래시 잔재 |
| Quad0084 | drive(nil,{}) | Before(outermost) | USER | OUTER | 일치 | 일치 | Q89(drive) |
| Quad0085 | drive [0] | Before(outermost) | USER | OUTER | 일치 | 일치 | Q89(drive) |
| Quad0086 | Effect returns 5; Effect returns 5, mount [2줄] | Before(outermost) | USER, USER-P | OUTER | 일치 | 일치 |  |
| Quad0087 | bind own Effect from its cleanup; rebind own Effect in fn after disposing its inst | Before(outermost) | USER×2 | OUTER×2 | **불일치** — 문서는 'fn/cleanup 안에서 **새로 만든** Effect'라 했지만 새 핸들은 통과(NO-RAISE). 실제 조건은 **그 Effect 자신**을 fn/cleanup 실행 중에 다시 묶을 때(fn 안에서 자기 inst를 dispose한 뒤 재바인딩, 또는 `:Unsubscribe()`가 부른 cleanup 안에서 바인딩) | 일치 | Q7 예외(outermost) — 콜백 열 OUTER |
| Quad0088 | WeakSubscribe inside fn | BeforeNearest | USER | USER-INNER | 일치 | 일치 |  |
| Quad0089 | Subscribe then WeakSubscribe | BeforeNearest | USER | USER-INNER | 일치 | 일치 |  |
| Quad0090 | Subscribe inside fn | BeforeNearest | USER | USER-INNER | 일치 | 일치 |  |
| Quad0091 | Subscribe twice | BeforeNearest | USER | USER-INNER | 일치 | 일치 |  |
| Quad0092 | WeakUnsubscribe strong | BeforeNearest | USER | USER-INNER | 일치 | 일치 |  |
| Quad0093 | Unsubscribe never | BeforeNearest | USER | USER-INNER | 일치 | 일치 |  |
| Quad0094 | Effect(5) | BeforeNearest | USER | USER-INNER | 일치 | 일치 |  |
| Quad0095 | Effect dep nil | BeforeNearest | USER | USER-INNER | 일치 | 일치 |  |
| Quad0096 | Effect dep 5 | BeforeNearest | USER | USER-INNER | 일치 | 일치 |  |
| Quad0097 | Effect at string key | Before(outermost) | USER | OUTER | 일치 | 일치 |  |
| Quad0098 | — | error(…,1/2) | 도달 불가/내부 | — | 일치(내부 조립 순서) | 소스=문서 | Effect.implFor before Effect.Init — internal assembly order;  |
| Quad0099 | Fallback(5,fn); Traceback(5,fn) | BeforeNearest | USER×2 | USER-INNER×2 | 일치 | 일치 |  |
| Quad0100 | Fallback(fn,5) | BeforeNearest | USER | USER-INNER | 일치 | 일치 |  |
| Quad0101 | OnCreated(5); OnDestroyed(5); OnRendered(5) | BeforeNearest | USER×3 | USER-INNER×3 | 일치 | 일치 |  |
| Quad0102 | bindLifetime(nil,{}) | Before(outermost) | USER | OUTER | 일치 | 일치 | Q89(bindLifetime) |
| Quad0103 | bindLifetime(f,nil) | Before(outermost) | USER | OUTER | 일치 | 일치 | Q89(bindLifetime) |
| Quad0104 | bindLifetime(f,subscribed); subscribed Observer mounted | Before(outermost) | USER×2 | OUTER×2 | 일치 | 일치 | Q89(bindLifetime) |
| Quad0105 | unbindLifetime(nil) | BeforeNearest | USER | USER-INNER | 일치 | 일치 |  |
| Quad0106 | List(other-instance State); Slot:Add(other-instance Slot); other-instance Slot mount; other-instance State at prop | helper→errorBefore | USER×4 | OUTER×2, USER-INNER×2 | 일치 | 일치 | `:List(State)`는 Nearest(사용자 줄), 트리 자리는 outermost |
| Quad0108 | bare Slot:Add; bare setTimeout | Before(outermost) | USER×2 | OUTER×2 | 일치 | 일치 | 스텁 직접 호출도 outermost(백엔드 op 직접 호출 전용) |
| Quad0109 | rebind own Observer in fn after disposing its inst | Before(outermost) | USER | OUTER | **불일치** — 0087과 같음: 새 Observer는 통과, 실제 조건은 **그 Observer 자신**을 fn 실행 중 재바인딩(fn 안에서 자기 inst dispose 뒤) | 일치 | Q7 예외(outermost) |
| Quad0110 | WeakSubscribe inside fn | BeforeNearest | USER | USER-INNER | 일치 | 일치 |  |
| Quad0111 | Subscribe then WeakSubscribe | BeforeNearest | USER | USER-INNER | 일치 | 일치 |  |
| Quad0112 | WeakUnsubscribe strong | BeforeNearest | USER | USER-INNER | 일치 | 일치 |  |
| Quad0113 | Subscribe inside fn | BeforeNearest | USER | USER-INNER | 일치 | 일치 |  |
| Quad0114 | Subscribe twice | BeforeNearest | USER | USER-INNER | 일치 | 일치 |  |
| Quad0115 | Unsubscribe never | BeforeNearest | USER | USER-INNER | 일치 | 일치 |  |
| Quad0116 | Observer at string key | Before(outermost) | USER | OUTER | 일치 | 일치 |  |
| Quad0117 | — | error(…,1/2) | 도달 불가/내부 | — | 일치(내부 조립 순서) | 소스=문서 | Observer.implFor before Observer.Init — internal assembly order;  |
| Quad0118 | Sum(1,nil) | BeforeNearest | USER | USER-INNER | 일치 | 일치 |  |
| Quad0119 | Sum('x') | BeforeNearest | USER | USER-INNER | 일치 | 일치 |  |
| Quad0120 | Operator nil arg via mount [2줄]; Sum(nil State) mount; Sum(nil State):Get | Before(outermost) | USER×2, USER-T | OUTER×2 | 일치 | 일치 |  |
| Quad0121 | Sum(State 'x'):Get | Before(outermost) | USER | OUTER | 일치 | 일치 |  |
| Quad0122 | 'x':Apply(Sum(1)):Get | Before(outermost) | USER | OUTER | 일치 | 일치 |  |
| Quad0123 | Not(5); Sum(1)(5); mod:Apply(Not); tag:Apply(Not) | BeforeNearest | LEAF Dispatch/Modifier/init.luau:189, LEAF Operator.luau:85, LEAF Tag.luau:195, USER | LEAF Dispatch/Modifier/init.luau:189, LEAF Tag.luau:195, OUTER, USER-INNER | 일치 | 일치 | `Op.Sum(1)(5)` 직접: 잎 `Operator.luau:85`, 콜백 안에선 **무관한 바깥 `s:Set` 줄**(태그 없는 커링 안쪽 → nearest가 바깥 태그 프레임까지 올라감); `tag:Apply(Op.Not)` `Tag.luau:195`·`mod:Apply(Op.Not)` `Modifier/init.luau:189` (Q89 보강·Q104) |
| Quad0124 | Clamp(2,1):Get | Before(outermost) | USER | OUTER | 일치 | 일치 |  |
| Quad0125 | Indexed(nil) | BeforeNearest | USER | USER-INNER | 일치 | 일치 |  |
| Quad0126 | Indexed(State) | BeforeNearest | USER | USER-INNER | 일치 | 일치 |  |
| Quad0127 | Indexed on number:Get | Before(outermost) | USER | OUTER | 일치 | 일치 |  |
| Quad0128 | Alternative(nil) | BeforeNearest | USER | USER-INNER | 일치 | 일치 |  |
| Quad0129 | Alternative(nil State):Get | Before(outermost) | USER | OUTER | 일치 | 일치 |  |
| Quad0130 | Set from waiting coroutine; mount from waiting coroutine (handler) | BeforeNearest | LEAF Ref/init.luau:244, USER | LEAF Ref/init.luau:244, USER-INNER | 일치 | 일치 | 직접 `r:Set`은 사용자 줄, 핸들러 경유(`D.Frame { r }`)는 `Ref/init.luau:244` (Q88 가족) |
| Quad0132 | Ref:Callback(5); Ref:Uncallback(5); Ref:WeakCallback(5) | BeforeNearest | USER×3 | USER-INNER×3 | 일치 | 일치 |  |
| Quad0133 | Ref:Wait(5) | BeforeNearest | USER | USER-INNER | 일치 | 일치 |  |
| Quad0134 | Ref:Wait() in non-yieldable (table.sort cmp — luau CLI main is yieldable) | BeforeNearest | USER | USER-INNER | 일치(엔진 조건) | 일치 | luau CLI는 메인도 yield 가능 → `table.sort` 비교자(C 경계) 안에서 재현 |
| Quad0135 | Ref:Unwrap empty | BeforeNearest | USER | USER-INNER | 일치 | 일치 |  |
| Quad0136 | PreRef via State at array | Before(outermost) | USER | OUTER | 일치 | 일치 |  |
| Quad0137 | Ref at string key | Before(outermost) | USER | OUTER | 일치 | 일치 |  |
| Quad0138 | Relate:GetWeak(nil,k) | error(…,1/2) | USER | USER-INNER | 일치 | 일치 |  |
| Quad0139 | Relate:GetWeak(t,nil) | error(…,1/2) | USER | USER-INNER | 일치 | 일치 |  |
| Quad0140 | disposed Slot via State; mount disposed Slot | Before(outermost) | USER×2 | OUTER×2 | 일치 | 일치 |  |
| Quad0141 | Slot at string key | Before(outermost) | USER | OUTER | 일치 | 일치 |  |
| Quad0142 | List data→5 | Before(outermost) | USER | OUTER | 일치 | 일치 |  |
| Quad0143 | List data→dict | Before(outermost) | USER | OUTER | 일치 | 일치 |  |
| Quad0144 | keyFn nil; keyFn nil (keyFn on its own line) [2줄] | Before(outermost) | USER, USER-T | OUTER | 일치 | 일치 |  |
| Quad0145 | keyFn dup | Before(outermost) | USER | OUTER | 일치 | 일치 |  |
| Quad0146 | updateFn returns KeyGone | Before(outermost) | USER | OUTER | 일치 | 일치 |  |
| Quad0147 | KeyGone returns element; KeyGone returns element, data:Set [2줄] | Before(outermost) | USER, USER-T | OUTER | 일치 | 일치 |  |
| Quad0148 | List twice | BeforeNearest | USER | USER-INNER | 일치 | 일치 |  |
| Quad0149 | List on manual Slot | BeforeNearest | USER | USER-INNER | 일치 | 일치 |  |
| Quad0150 | List updateFn 5 | BeforeNearest | USER | USER-INNER | 일치 | 일치 |  |
| Quad0151 | List data 5 | BeforeNearest | USER | USER-INNER | 일치 | 일치 |  |
| Quad0152 | List keyFn 5 | BeforeNearest | USER | USER-INNER | 일치 | 일치 |  |
| Quad0153 | List opts 5 | BeforeNearest | USER | USER-INNER | 일치 | 일치 |  |
| Quad0154 | Single updateFn 5 | BeforeNearest | USER | USER-INNER | 일치 | 일치 |  |
| Quad0155 | Single opts 5 | BeforeNearest | USER | USER-INNER | 일치 | 일치 |  |
| Quad0156 | List returns already-mounted; List returns its own Slot; List returns same element for two keys; List updateFn returns mounted element, moun | Before(outermost) | USER×3, USER-T | OUTER×3 | 부분 — 문서는 '이미 다른 자리에 마운트된 값을 다시 마운트'(정적 자식·숏핸드 포함)라 했지만, 정적 자리는 `Quad0160`, Slot CRUD는 `Quad0172`가 먼저 — 실측으로 0156은 `:List/:Single` updateFn 결과(settle→claimOwner)에서만 났다 | **불일치** | List가 같은 원소를 두 키에 돌려줄 때·자기 Slot을 돌려줄 때도 0156(0171/0173 문구가 아님) |
| Quad0157 | claimOwnerAt(nil) | BeforeNearest | USER | USER-INNER | 일치 | 일치 |  |
| Quad0158 | claimOwnerAt(e,nil) | BeforeNearest | USER | USER-INNER | 일치 | 일치 |  |
| Quad0159 | claimOwnerAt(e,f,nil) | BeforeNearest | USER | USER-INNER | 일치 | 일치 |  |
| Quad0160 | Slot mounted twice; disposed Slot nested in mounted Slot; static child twice | Before(outermost) | USER×3 | OUTER×3 | 일치 | **불일치** | 문서 템플릿에 ZOMBIE_NOTE 꼬리 없음 |
| Quad0161 | releaseOwner(nil) | BeforeNearest | USER | USER-INNER | 일치 | 일치 |  |
| Quad0162 | releaseOwner(e,nil) | BeforeNearest | USER | USER-INNER | 일치 | 일치 |  |
| Quad0163 | releaseOwner not owned | BeforeNearest | USER | USER-INNER | 일치 | 일치 |  |
| Quad0164 | — | Before(outermost) | 도달 불가/내부 | — | **불일치** — 문서는 `materializeSlotTree` 첫 검사로 적었지만 공개 경로에선 `Quad0140`(핸들러 사전검사)·`0160`·`0179`가 먼저 | 소스=문서 | 도달 못함(다른 ID가 먼저 — 비고); 시도: 파괴 Slot을 State로 감싸 마운트 → 0140, 중첩 → 0160 |
| Quad0165 | CRUD on disposed | BeforeNearest | USER | USER-INNER | 일치 | 일치 |  |
| Quad0166 | CRUD after List | BeforeNearest | USER | USER-INNER | 일치 | 일치 |  |
| Quad0167 | ancestor CRUD in nested updateFn, mount [2줄]; mutate ancestor while mounting | BeforeNearest | USER, USER-P | USER-INNER | 일치 | 일치 |  |
| Quad0168 | Add index 1.5; Remove(1.5) | BeforeNearest | USER×2 | USER-INNER×2 | 일치 | 일치 |  |
| Quad0169 | Add State(disposed Slot) | BeforeNearest | USER | USER-INNER | 일치 | 일치 |  |
| Quad0170 | Add existing element; Replace(1, own element) | BeforeNearest | USER×2 | USER-INNER×2 | 일치 | 일치 |  |
| Quad0171 | Splice dup; initial dup | BeforeNearest | USER×2 | USER-INNER×2 | 일치 | 일치 |  |
| Quad0172 | Add statically mounted; Replace with mounted; Slot{mounted} | BeforeNearest | USER×3 | USER-INNER×3 | 일치 | **불일치** | 문서 템플릿에 ZOMBIE_NOTE 꼬리 없음 |
| Quad0173 | Add self; Add(parent) cycle | BeforeNearest | USER×2 | USER-INNER×2 | 일치 | 일치 |  |
| Quad0174 | Splice oob; Splice(1,-1) | BeforeNearest | USER×2 | USER-INNER×2 | 일치 | 일치 |  |
| Quad0175 | Get('x') | BeforeNearest | USER | USER-INNER | 일치 | 일치 |  |
| Quad0176 | Slot(frame) | BeforeNearest | USER | USER-INNER | 일치 | 일치 |  |
| Quad0177 | Slot{x=1} | BeforeNearest | USER | USER-INNER | 일치 | 일치 |  |
| Quad0178 | dispose(nil) | BeforeNearest | USER | USER-INNER | 일치 | 일치 |  |
| Quad0179 | dispose held | BeforeNearest | USER | USER-INNER | 일치 | **불일치** | 문서 템플릿에 ZOMBIE_NOTE 꼬리 없음 |
| Quad0180 | dispose({}) | BeforeNearest | USER | USER-INNER | 일치 | 일치 |  |
| Quad0181 | Source:Set(Modifier); Source:Set(Modifier) in Observer | BeforeNearest | USER×2 | USER-INNER×2 | 일치 | 일치 |  |
| Quad0182 | Source(Modifier) | BeforeNearest | USER | USER-INNER | 일치 | 일치 |  |
| Quad0183 | Compute dep 5 | BeforeNearest | USER | USER-INNER | 일치 | 일치 |  |
| Quad0184 | Compute cycle :Get; Compute cycle mount; cycle, mount (Get inside fn) [2줄]; same-gen reread after throw, :Get; same-gen reread after throw,  | BeforeNearest | LEAF Animate.luau:54, LEAF Animate.luau:91, LEAF Bookkeeping.luau:360, LEAF Debounce.luau:85×2, LEAF Dispatch/StoreBind.luau:69×10, LEAF Operator.luau:111, LEAF Operator.luau:188, LEAF Operator.luau:211, LEAF Operator.luau:53×2, LEAF Operator.luau:96, LEAF Slot/List.luau:200×2, LEAF Slot/List.luau:280, LEAF Slot/init.luau:221×2, LEAF State.luau:241×3, USER×3, USER-P | LEAF Dispatch/StoreBind.luau:69, USER-INNER×3 | 일치 | 일치 | 사용자 fn 안 `:Get`은 사용자 줄; **quad 내부 읽기** 14자리가 잎 — `잎 blame 자리` 절 |
| Quad0185 | Compute returns Modifier | Before(outermost) | USER | OUTER | 일치 | 일치 |  |
| Quad0186 | Depend(nil) | BeforeNearest | USER | USER-INNER | 일치 | 일치 |  |
| Quad0187 | Compute(5) | BeforeNearest | USER | USER-INNER | 일치 | 일치 |  |
| Quad0188 | Gate(5) | BeforeNearest | USER | USER-INNER | 일치 | 일치 |  |
| Quad0189 | Gate setup returns 5; Gate setup returns 5 on Get? | BeforeNearest | USER×2 | USER-INNER×2 | 일치 | 일치 |  |
| Quad0190 | Observer(5) | BeforeNearest | USER | USER-INNER | 일치 | 일치 |  |
| Quad0191 | Apply(5) | BeforeNearest | USER | USER-INNER | 일치 | 일치 |  |
| Quad0192 | — | error(…,1/2) | 도달 불가/내부 | — | 일치(내부) | 소스=문서 | State.implFor before State.Init — internal assembly order;  |
| Quad0193 | Attr(Store{''}); Store{['']}; store:Of('') | BeforeNearest | USER×3 | USER-INNER×3 | 일치 | 일치 |  |
| Quad0194 | Store{Of=} | BeforeNearest | USER | USER-INNER | 일치 | 일치 |  |
| Quad0195 | Store(5) | BeforeNearest | USER | USER-INNER | 일치 | 일치 |  |
| Quad0196 | Store(Source) | BeforeNearest | USER | USER-INNER | 일치 | 일치 |  |
| Quad0197 | Store(AttrKey) | BeforeNearest | USER | USER-INNER | 일치 | 일치 |  |
| Quad0198 | Store{a=5} | BeforeNearest | USER | USER-INNER | 일치 | 일치 |  |
| Quad0199 | Tag(''); Tag('') in Compute (mount); Tag('') in Compute, mount [2줄]; Tag('') inside updateFn, mount [2줄]; Tag({''}) list; tag:Added(''); tag | BeforeNearest | USER×5, USER-P×2 | USER-INNER×5 | 일치 | 일치 |  |
| Quad0200 | Tag(AttrKey) | BeforeNearest | USER | USER-INNER | 일치 | 일치 |  |
| Quad0201 | Tag self-nesting list | BeforeNearest | USER | USER-INNER | 일치 | 일치 |  |
| Quad0202 | Tag({x='a'}) | BeforeNearest | USER | USER-INNER | 일치 | 일치 |  |
| Quad0203 | Tag list with hole | BeforeNearest | USER | USER-INNER | 일치 | 일치 |  |
| Quad0204 | Tag(5); tag:Added(5) | BeforeNearest | USER×2 | USER-INNER×2 | 일치 | 일치 |  |
| Quad0205 | Contains(5) | BeforeNearest | USER | USER-INNER | 일치 | 일치 |  |
| Quad0206 | tag:Apply(5) | BeforeNearest | USER | USER-INNER | 일치 | 일치 |  |
| Quad0207 | Tag.Merged(5) | BeforeNearest | USER | USER-INNER | 일치 | 일치 |  |
| Quad0208 | RunInit(5) | BeforeNearest | USER | USER-INNER | 일치 | 일치 |  |
| Quad0209 | UseProvider returns 5 | BeforeNearest | USER | USER-INNER | 일치 | 일치 |  |
| Quad0210 | AddPlugin(5) | BeforeNearest | USER | USER-INNER | 일치 | 일치 |  |
| Quad0211 | AddPlugin returns nil | BeforeNearest | USER | USER-INNER | 일치 | 일치 |  |
| Quad0212 | UseProvider(5) | BeforeNearest | USER | USER-INNER | 일치 | 일치 |  |
| Quad0213 | second provider | BeforeNearest | USER | USER-INNER | 일치 | 일치 |  |
| Quad0214 | Animate(5) | BeforeNearest | USER | USER-INNER | 일치 | 일치 |  |
| Quad0215 | setTimeout(5,1) | Before(outermost) | USER | OUTER | 일치 | 일치 | 백엔드 op 직접 호출 인자 검증인데 outermost |
| Quad0216 | setTimeout(fn,-1) | Before(outermost) | USER | OUTER | 일치 | 일치 | 같음 |
| Quad0217 | clearTimeout(5) | Before(outermost) | USER | OUTER | 일치 | 일치 | 같음 |
| Quad0218 | Event handler 5; Event handler via State →5 | Before(outermost) | USER×2 | OUTER×2 | 일치 | 일치 |  |
| Quad0219 | State child →foreign (Set); foreign static child; static State child →foreign, Set [2줄] | Before(outermost) | USER×2, USER-T | OUTER×2 | 일치 | 일치 |  |
| Quad0220 | child cycle via drive; parent into own child | Before(outermost) | USER×2 | OUTER×2 | 일치 | 일치 |  |
| Quad0221 | OnChange('') | BeforeNearest | USER | USER-INNER | 일치 | 일치 |  |
| Quad0222 | OnChange(Text,5) | BeforeNearest | USER | USER-INNER | 일치 | 일치 |  |
| Quad0223 | Out('') | BeforeNearest | USER | USER-INNER | 일치 | 일치 |  |
| Quad0224 | Out(Text,5) | BeforeNearest | USER | USER-INNER | 일치 | 일치 |  |
| Quad0225 | nativeClaim twice | Before(outermost) | USER | OUTER | 일치 | 일치 | 백엔드 op 직접 호출 — outermost |
| Quad0226 | bindLifetime(foreign) | Before(outermost) | USER | OUTER | 일치 | 일치 | 백엔드 op 직접 호출 — outermost |
| Quad0227 | Tween:Mapped(5) | BeforeNearest | USER | USER-INNER | 일치 | 일치 |  |
| Quad0228 | version mismatch | Before(outermost) | USER | OUTER | 일치 | 일치 |  |
| Quad0229 | getOffsetAt hole below N | Before(outermost) | USER | OUTER | 일치 | 일치 | 0022의 짝 — outermost |
| Quad0230 | bound then WeakSubscribe | BeforeNearest | USER | USER-INNER | 일치 | 일치 |  |
| Quad0231 | bound then Subscribe | BeforeNearest | USER | USER-INNER | 일치 | 일치 |  |
| Quad0232 | same Effect twice one inst | Before(outermost) | USER | OUTER | 일치 | 일치 |  |
| Quad0233 | same Effect two insts | helper→errorBefore | USER | OUTER | 일치 | 일치 |  |
| Quad0234 | bound then WeakSubscribe | BeforeNearest | USER | USER-INNER | 일치 | 일치 |  |
| Quad0235 | bound then Subscribe | BeforeNearest | USER | USER-INNER | 일치 | 일치 |  |
| Quad0236 | Add index 5; Extract(5); Move(1,5); Remove(5); Replace(5,e); Splice(5,0); Swap(1,5) | BeforeNearest | USER×7 | USER-INNER×7 | 일치 | 일치 |  |
| Quad0237 | Tag(metatabled) | BeforeNearest | USER | USER-INNER | 일치 | 일치 |  |
| Quad0238 | Add(Ref); List updateFn returns Ref (data:Set); List updateFn returns Ref (mount); List updateFn returns Ref, data:Set [2줄]; List updateFn r | raise→Nearest(기본) | USER×6, USER-T×2 | OUTER×3, USER-INNER×3 | 일치 | 일치 | updateFn 결과 경로는 마운트/`data:Set` 줄(값을 만든 줄 아님) — 한계 2 설계 |
| Quad0239 | Add(nil); Slot{None}; Slot{State(nil)} fine? then List none | raise→Nearest(기본) | USER×3 | USER-INNER×3 | 일치 | 일치 |  |
| Quad0240 | Add(5); List updateFn returns 5 (data:Set); List updateFn returns 5 (mount); List updateFn returns 5, mount [2줄]; Single State →5, Set [2줄]; | raise→Nearest(기본) | USER×7, USER-T×3 | OUTER×5, USER-INNER×2 | 일치 | 일치 | 같음(updateFn·Single·State 원소 경로) |
| Quad0241 | Add(foreign); List updateFn returns foreign; List updateFn returns foreign, mount [2줄]; Splice foreign | raise→Nearest(기본) | USER×3, USER-T | OUTER, USER-INNER×2 | 일치 | 일치 | 같음 |
| Quad0242 | Add(disposed Slot); List updateFn returns disposed Slot; List updateFn returns disposed Slot, mount [2줄] | raise→Nearest(기본) | USER×2, USER-T | OUTER, USER-INNER | 일치 | 일치 | 같음 |
| Quad0243 | Animate{Time='x'}; Animate{Time=State('x')} at run; Tween Time='x'; Tween built in Compute (mount); Tween in Compute, mount [2줄] | fail→Nearest(기본)/Before(Animate) | USER×4, USER-P | OUTER, USER-INNER×3 | 일치 | 일치 | Animate의 State 옵션은 실행 시점 errorBefore(설계) — 콜백 열 OUTER |
| Quad0244 | Reverses=5 | fail→Nearest(기본)/Before(Animate) | USER | USER-INNER | 일치 | 일치 |  |
| Quad0245 | Dedup=5 | fail→Nearest(기본)/Before(Animate) | USER | USER-INNER | 일치 | 일치 |  |
| Quad0246 | Completed=5 | fail→Nearest(기본)/Before(Animate) | USER | USER-INNER | 일치 | 일치 |  |
| Quad0247 | Override='x' | fail→Nearest(기본)/Before(Animate) | USER | USER-INNER | 일치 | 일치 |  |
| Quad0248 | Tween(5) | fail→Nearest(기본)/Before(Animate) | USER | USER-INNER | 일치 | 일치 |  |
| Quad0249 | Tween{}; Tween{} in prop | fail→Nearest(기본)/Before(Animate) | USER×2 | USER-INNER×2 | 일치 | 일치 |  |
| Quad0250 | Tween Value=State | fail→Nearest(기본)/Before(Animate) | USER | USER-INNER | 일치 | 일치 |  |
| Quad0251 | Tween Value=None | fail→Nearest(기본)/Before(Animate) | USER | USER-INNER | 일치 | 일치 |  |

## 잎 blame 자리(ID별)

- Quad0023: Bookkeeping.luau:248 ← handler-author: setLength without setOffsetSource; Bookkeeping.luau:248 ← optional props.Ref nil hole; Bookkeeping.luau:248 ← props nil hole {a,nil,b}
- Quad0024: Bookkeeping.luau:288 ← setOffsetSource w/o setLength
- Quad0123: Dispatch/Modifier/init.luau:189 ← mod:Apply(Not); Operator.luau:85 ← Sum(1)(5); Tag.luau:195 ← tag:Apply(Not)
- Quad0130: Ref/init.luau:244 ← mount from waiting coroutine (handler)
- Quad0184: Animate.luau:54 ← same-gen: Animate option State (Time) [2줄]; Animate.luau:91 ← throw then same-gen Animate read (Q88) [2줄]; Bookkeeping.luau:360 ← throw then same-gen setLength State read [2줄]; Debounce.luau:85 ← same-gen: Debounce MaxTime read [2줄]; Debounce.luau:85 ← throw then same-gen Debounce Time read [2줄]; Dispatch/StoreBind.luau:69 ← same-gen reread after throw, mount; Dispatch/StoreBind.luau:69 ← same-gen: Attr group State<Attr> [2줄]; Dispatch/StoreBind.luau:69 ← same-gen: AttrKey value State [2줄]; Dispatch/StoreBind.luau:69 ← same-gen: Event handler State [2줄]; Dispatch/StoreBind.luau:69 ← same-gen: Tween Mapped? Out src [2줄]; Dispatch/StoreBind.luau:69 ← throw then same-gen Attr State read [2줄]; Dispatch/StoreBind.luau:69 ← throw then same-gen Out src? / OnChange [2줄]; Dispatch/StoreBind.luau:69 ← throw then same-gen State child read [2줄]; Dispatch/StoreBind.luau:69 ← throw then same-gen Tag State read [2줄]; Dispatch/StoreBind.luau:69 ← throw then same-gen mount (Q88) [2줄]; Operator.luau:111 ← same-gen: Operator Not target [2줄]; Operator.luau:188 ← same-gen: Operator Indexed target [2줄]; Operator.luau:211 ← same-gen: Operator Alternative default [2줄]; Operator.luau:53 ← same-gen: Operator Clamp bound [2줄]; Operator.luau:53 ← throw then same-gen Operator read (Q88) [2줄]; Operator.luau:96 ← same-gen: Operator Apply target [2줄]; Slot/List.luau:200 ← same-gen: List install on mounted Slot [2줄]; Slot/List.luau:200 ← throw then same-gen List data read (Q88) [2줄]; Slot/List.luau:280 ← throw then same-gen Slot Single read [2줄]; Slot/init.luau:221 ← same-gen: Slot State element mount [2줄]; Slot/init.luau:221 ← same-gen: Slot:Add(State) on mounted Slot [2줄]; State.luau:241 ← same-gen: Blocker gate Apply read [2줄]; State.luau:241 ← same-gen: Debounce Apply read [2줄]; State.luau:241 ← throw then same-gen Gate upstream read [2줄]

## 메시지 ≠ 문서 템플릿(런타임 문구 기준)

- Quad0083
  - 문서: `Dispatch.drive: props must be a plain \{ ... \} table — a quad value needs the braces (got {brandNameOf(flattened) or "a table with a metatable"})`
  - 실제: `Dispatch.drive: props must be a plain { ... } table — a quad value needs the braces (got Source)`
- Quad0156
  - 문서: `Slot: this element is already mounted — multiple mounts are not allowed`
  - 실제: `Slot: this element is already mounted — multiple mounts are not allowed (if its owner was destroyed outside quad — `inst:Destroy()` — the value went with it and cannot be reused after its parent is destroyed; extract it before destroying, as with an Instance)`
- Quad0160
  - 문서: `Bookkeeping.claimOwnerAt: this element is already mounted elsewhere — multiple mounts are not allowed`
  - 실제: `Bookkeeping.claimOwnerAt: this element is already mounted elsewhere — multiple mounts are not allowed (if its owner was destroyed outside quad — `inst:Destroy()` — the value went with it and cannot be reused after its parent is destroyed; extract it before destroying, as with an Instance)`
- Quad0172
  - 문서: `{surface}: this element is already mounted — multiple mounts are not allowed`
  - 실제: `Slot: this element is already mounted — multiple mounts are not allowed (if its owner was destroyed outside quad — `inst:Destroy()` — the value went with it and cannot be reused after its parent is destroyed; extract it before destroying, as with an Instance)`
- Quad0179
  - 문서: `dispose: this value is still held by a Slot or a mounted position — Remove/Extract it from a manual Slot, drop its key from a :List Slot's data, destroy the owner Slot (a detached element goes with its owner), or take it off its numeric-key seat first (Set(nil) the State holding it; a shorthand-managed child goes with its key)`
  - 실제: `dispose: this value is still held by a Slot or a mounted position — Remove/Extract it from a manual Slot, drop its key from a :List Slot's data, destroy the owner Slot (a detached element goes with its owner), or take it off its numeric-key seat first (Set(nil) the State holding it; a shorthand-managed child goes with its key) (if its owner was destroyed outside quad — `inst:Destroy()` — the value went with it and cannot be reused after its parent is destroyed; extract it before destroying, as with an Instance)`

## 의도한 ID와 다른 ID가 난 시도(참고)

- 의도 Quad0003 → Quad0193 [Attr(Store{''})] direct USER round13-e21-blame/e21.luau:88
- 의도 Quad0003 → Quad0193 [Attr(Store{''})] cb USER-INNER round13-e21-blame/e21.luau:88
- 의도 Quad0087 → - [doc wording: NEW Effect bound inside fn] direct NO-RAISE -
- 의도 Quad0087 → - [doc wording: NEW Effect bound inside fn] cb NO-RAISE -
- 의도 Quad0109 → - [doc wording: NEW Observer bound inside fn] direct NO-RAISE -
- 의도 Quad0109 → - [doc wording: NEW Observer bound inside fn] cb NO-RAISE -
- 의도 Quad0164 → Quad0140 [disposed Slot via State] direct USER round13-e21-blame/e21.luau:291
- 의도 Quad0164 → Quad0140 [disposed Slot via State] cb OUTER round13-e21-blame/e21.luau:51
- 의도 Quad0164 → Quad0160 [disposed Slot nested in mounted Slot] direct USER round13-e21-blame/e21.luau:292
- 의도 Quad0164 → Quad0160 [disposed Slot nested in mounted Slot] cb OUTER round13-e21-blame/e21.luau:51
- 의도 Quad0171 → Quad0156 [List returns same element for two keys] direct USER round13-e21-blame/e21.luau:436
- 의도 Quad0171 → Quad0156 [List returns same element for two keys] cb OUTER round13-e21-blame/e21.luau:51
- 의도 Quad0173 → Quad0156 [List returns its own Slot] direct USER round13-e21-blame/e21.luau:437
- 의도 Quad0173 → Quad0156 [List returns its own Slot] cb OUTER round13-e21-blame/e21.luau:51
- 의도 VM → - [mod:Apply(Animate)] direct LEAF Animate.luau:91
- 의도 VM → - [mod:Apply(Animate)] cb LEAF Animate.luau:91

## VM·비ID 스윕(e21-vm.luau — 공개 표면에 틀린 타입, 번호 없는 에러·잎)

- getHandler({},Size,1): LEAF Reflection.luau:30 - — `./quad-roblox/src/Reflection.luau:30: table index is nil`
- holdLifetime(nil,{}): LEAF LifetimeHandle.luau:124 Quad0138 — `./quad-roblox/src/LifetimeHandle.luau:124: Quad0138 Relate:GetWeak: inst must not be nil`
- releaseLifetime(nil): LEAF LifetimeHandle.luau:146 Quad0138 — `./quad-roblox/src/LifetimeHandle.luau:146: Quad0138 Relate:GetWeak: inst must not be nil`
- nativeInsert(nil,f,1): LEAF EngineOps.luau:47 - — `./quad-roblox/src/EngineOps.luau:47: attempt to iterate over a number value`
- nativeFindChild(nil,'a'): LEAF EngineOps.luau:102 - — `./quad-roblox/src/EngineOps.luau:102: attempt to index nil with 'FindFirstChild'`
- addTag(nil,'a'): LEAF EngineOps.luau:125 - — `./quad-roblox/src/EngineOps.luau:125: attempt to iterate over a string value`
- setAttr(nil,'a',1): LEAF EngineOps.luau:138 - — `./quad-roblox/src/EngineOps.luau:138: attempt to index nil with 'SetAttribute'`
- onDestroying(nil,fn): LEAF EngineOps.luau:94 - — `./quad-roblox/src/EngineOps.luau:94: attempt to index nil with 'Destroying'`
- mod:Size(Animate): LEAF Animate.luau:90 - — `./quad-roblox/src/Animate.luau:90: attempt to index nil with 'Compute'`
- tag:Apply(Animate): LEAF Animate.luau:90 - — `./quad-roblox/src/Animate.luau:90: attempt to call missing method 'Compute' of table`
- Tween at Name: LEAF Handlers/Property.luau:161 - — `./quad-roblox/src/Handlers/Property.luau:161: Name must be a string`
- AttrKey value table: LEAF EngineOps.luau:138 - — `./quad-roblox/src/EngineOps.luau:138: table is not a supported attribute type`
- Fallback onError throws: USER - — `./.claude/audit/round13-e21-blame/e21-vm.luau:58: b`

참고: msgdiff.raw.txt(소스 리터럴 정적 비교)는 파서 잡음(`\{` 이스케이프·연결 식)이 섞여 있다 — 글자 비교의 소스는 위 런타임 절.
