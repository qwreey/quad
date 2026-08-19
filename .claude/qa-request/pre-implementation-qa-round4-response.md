### D-3 — retractor는 자기 자원만 정리
retractor는 자기 하위 위임까지 쫓아가 정리할 필요가 없다 —
`Dispatch.retractFrom`이 **항상 깊은 인덱스부터 얕은 쪽으로** 정리하므로 이
클로저가 불릴 시점엔 자기 아래는 이미 정리된 뒤다. → **예/아니오**
-> 방향이 그게 맞나? 방향을 더 서술해주길 바람. 실제 process 에선 retract 가 인덱스 1 부터 5, 6, ... 순으로 작동함. 그런데 달라질 때 5, 4, 3, 2 ... 순이 되는건 아니지? '깊은 인덱스' 라는게 무슨 의미?

### D-8 — `Quad.debug` 플래그
동률 경고 print는 모듈 표면의 불리언 `Quad.debug`(기본 `false`)가 참일 때만
찍는다. `Quad.debug`는 새 공개 API 표면이라 `module-lifecycle-plan.md`에도
반영이 필요하고, 다중 인스턴스화 시 인스턴스별인지 전역인지는 그때 정한다.
`Dispatch.listHandlers()`가 이 플래그와 무관하게 항상 호출 가능한지도 구현 시
정한다. → **예/아니오**
-> listHandlers 는 항상 실행 가능. 유저가 필요하면 수행 시 목록들을 단순 반환해주고 출력하고 싶다면 출력하는 용도임.

### D-10 — 두 패스 순회 계약
`Dispatch.drive`는 Lua 테이블의 우연한 순회 순서에 기대지 않고 **명시적으로 두
패스**(배열 파트 먼저, 해시 파트 나중)로 돈다. 이유는 (1) 다른 백엔드의
이식성, (2) 어차피 구분 비용이 드니 순서 고정이 거의 공짜. **M0 스파이크에서
실제 Luau로 순회 동작을 검증**할 항목이다. → **예/아니오**
-> 루아우의 일반화된 반복 for 이 이를 그냥 지원함. 어떻게 실제로 이해했는지 확인 필요

### D-32 — 재위임 핸들러의 (A) 분기 의무
재위임하는 핸들러는 (A) 분기에서도 **반드시 다시 재위임**해야 한다. 조건부로만
재위임하는 핸들러를 만들면 건너뛰는 자리에서 `Dispatch.retractFrom(inst,k,index+1)`을
직접 불러야 한다. → **예/아니오**
-> 무슨말인지 확인 필요

### D-56 — `setLength`의 생명주기 경로
`setLength`가 만드는 Observer는 `:Subscribe()`가 아니라 `bindLifetime(ownerKey,
observer)`로 묶인다 — `ownerKey`가 죽을 때 같이 죽어야 하는 내부 배관이기 때문.
`setLength` 자신은 `recompute`를 직접 부르지 않고 항상 `gatedRecompute`를
경유하며, Observer의 "등록 즉시 1회 실행"으로 촉발되는 최초 호출도 예외 없이 이
게이트를 통과한다. → **예/아니오**
-> 맞음. 그런데 ownerKey 가 Slot일 수도 있음. 각 엔진의 bindLifetime 은 이를 잘 핸들링 해줘야함. 즉, Slot안에, 또는 바깥에 SetStrong 으로 gchold 비슷한걸 수행하면 됨.

### D-58 — 마운트보다 offset 갱신이 먼저
`rawAdd`는 `self.Length:Set(newCount)`(다운스트림 offset/LayoutOrder 갱신이 여기서
동기적으로 끝남) → `element.Parent = target` 순서로 호출해야 한다 — 안 그러면
Roblox의 실시간 `UIListLayout` reflow에서 한 프레임 순서가 깨진 채 노출된다.
-> 추가적으로 보면, Length 설정도 마운트 전임. 액티베이션으로 length 가 결정되었을 때 그걸 넣어주고 나서 최종 마운트를 함.

### D-60 — `Slot.Length`와 `Slot.Offset`은 별개
`Length`는 Slot이 스스로 노출하는 출력값(지금 실제 마운트된 개수, "n개 검색됨"
UI에 그대로 써도 됨)이고 `Offset`은 Dispatch가 등록받아 `recompute`가 채우는
입력값이다 — 서로 다른 두 `Source<number>`다. `Offset`은 마운트 전엔 `nil`이다.
-> 마운트 전에는 0 이긴 함. 다만 list 의 관측으로 실체화된 값이 나오는게 offset 설정 이후라서 그 땐 0 이 아닐 수 있을 뿐

### LP-1 — `Connected`는 계산 속성
`Connected`는 저장되는 bool이 아니라 "내가 아직 살아있게 하는 뒷받침 참조가
nil인지"를 확인하는 **계산된 속성**이고, 해제는 그 참조를 `nil`로 만드는
것뿐이다(자료구조를 즉시 재구성하지 않음). → **예/아니오**
-> 무슨 말인지 모르겠음. Connected 는 단순히 RBXScriptConnect 안의 속성이고, Destroy 수행 시 모든 커넥션이 죽으니 자연스럽게 Connected 가 false 이 되는것 뿐임. nil로 참조를 만들 이유도 없음. gc 되어 아에 gcconn 이 없거나, 아직 gc 는 안 되었는데 Destroy 직후라 false 이거나 한것 뿐임.

### LP-2 — Instance 파괴 관측 지점
Instance 파괴 관측 지점은 `Destroying` **하나로 통일**하고 `AncestryChanged`나
폴링은 안 쓴다. 다만 실제로는 이 훅을 쓰는 지점이 예상보다 적을 가능성이 크다.
-> 당장은 Effect 뿐임.

### LP-4 — 엔진 레벨 보강
Roblox 엔진 자체가 Destroy 시 Tag/Attribute/실행 중인 Tween을 정리해주므로
라이브러리가 따로 처리할 필요가 없고, 커스텀 Destroy-time 처리가 필요한
사용자는 `[Event "Destroying"]`을 직접 바인드하면 된다.
-> Effect 임. 그리고 그 슈거인 OnDestroyed 존재

### BR-7 — duck-typing 기각 근거
duck-typing을 안 쓰는 이유는 (a) 우연히 비슷한 모양의 값에 false positive,
(b) 일부 Roblox userdata는 정의 안 된 키 인덱싱 자체에서 에러를 던져 `pcall`로
감싸야 하거나 최악의 경우 엔진이 죽는 상황까지 생김 — 둘 다다. → **예/아니오**
-> 더 설명좀 필요

### M-2 — flatten의 판별 수단
flatten은 배열을 훑으며 `isModifier(v)`가 참인 항목만 필드를 뽑아 merge하고
나머지는 전혀 안 건드리고 배열 파트에 그대로 남긴다(그래서 `None`은 flatten을
그냥 통과한다). → **예/아니오**
-> 이것도 이 이후 ProcessedModifier / ProcessedModifierHandler 를 만들면 될듯.
Post/Pre Ref 와 유사히 처리 가능하다고 생각함.

### M-5 — `None`은 raw 저장 계층에만 있는 실재 센티널
`{ TextColor3 = None, mod }`도 `mod:TextColor3(None)`도 둘 다 지원되고, Modifier
setter/`Overridden`/인라인 props는 `None`을 그냥 평범한 raw 값으로 저장·교체할
뿐 특별 취급이 전혀 없다. 실제 "지우기"는 디스패치 단계의 `NoneHandler`가
담당한다.
-> 예, 다만 mod:TextColor3(nil) mod 그룹에서 제거된걸 생성하게됨. None 이 오직 명시적 'unsetter' 임. 이미 그렇게 구현되겠지만, 문서화에 유의를 두지 않았다면 확인해두어야할 부분.

### M-9 — Setter는 리터럴과 변환 함수 둘 다
`:FontSize(value)`와 `:FontSize(function(current) ... end)` 둘 다 지원하고,
**Getter는 안 만든다**(변환 함수 하나가 getter가 필요했던 유일한 케이스를
인라인으로 커버). `old`는 항상 "현재 저장된 그대로" 넘어간다(plain이면 raw 값,
State면 State 핸들 그 자체).
-> 사실 Peek 가 게터라고 봐도 되긴 함, 그래서 애매한 질문이였음.

### BK-9 — `HasBlocked` 신설 안 함
`IsBlocked`/`HasBlockedEmit` 필드는 그대로 유지하고 Blocker 자신의 새 최상위
플래그(`HasBlocked`)는 **신설하지 않는다** — `OffWithoutEmit()`이 각 gated
state의 기존 `HasBlockedEmit`을 리셋해주는 것으로 충분하다.
-> 있는게 어렵지 않다고 보긴 하나, 사용 케이스가 없었을 뿐임. 단순 백로깅 상태로 두어도 되나, 당장 개발에 필요 없음. 나중에 사용 필요 요구가 나오면 그 때 구현하여도 될 요소로 보임. 아마 HasBlockedState 로 하나가 신설될 가능성이 존재하지 않는다고 못 박기는 이름.

### E-10 — ⚠️ 미해결 항목 확인: dedup 경로의 대칭
그 dedup 경로에서 retract가 아무것도 안 한 뒤 `process` 쪽도 정말 아무것도 안
하는지 대칭이 실제로 성립하는지는 **아직 확인 안 된 항목**이고, 특히
`EffectHandle`의 내부 Observer cascade가 dedup 분기 안에 제대로 들어가 있는지는
별도 확인 대상이다(M3 착수 전).
-> 확인해봐야한다 생각함. 이로 인해 relate 로 effect 핸들러 쪽에서 old 값을 직접 들고 있어야 하고 dedup 이면 retract 에서 old 를 안 지워주고 process 로 조회해보고 같으면 deup 되어야하는듯.

### E-11 — `:Subscribe()`한 핸들의 `:Unsubscribe()` 의미 확장
Observer의 `:Unsubscribe()`는 "미래 재실행만 끊는다"로 충분하지만, Effect의
계약은 "생애주기가 끝나는 시점에 마지막 cleanup이 정확히 1회"이므로
`:Unsubscribe()`도 "지금 끝났다"는 신호로 취급해 (1) 내부 Observer 구독을 끊고
(2) 직전 cleanup을 정확히 1회 호출하며 (3) 이후 leaf가 실제로 죽어도 중복
호출되지 않는다. → **예/아니오**
-> 뭔가 애매함. 옵저버에선 leap 바인딩에 Unsubscribe 못 하는것 처럼, Effect 또한 리프 바인딩에 있어서는 Unsubscribe 안 먹어야 하는거 아님? State<Effect> 오고 emit 당함 process 다시 나는데 문제가 안 되는거임? '(3) 이후 leaf가 실제로 죽어도 중복 호출되지 않는다.' 가 좀 이상해보임.

### R-11 — 분기와 소진
`type(v) == "thread"`면 대기자로 보고 resume 후 `[i] = nil`로 소진,
`"function"`이면 콜백으로 보고 호출만 하고 소진 안 함, `nil`이면 빈 슬롯이라
스킵한다. 새 등록은 `table.insert`가 아니라 **빈 슬롯을 선형 탐색해 재사용**한다.
-> 아니요. table.insert 자체가 가장 처음 nil 이 등장하는 인덱스에 넣어주기에 table.insert 가 맞음. 단순 for 문에서는 해시 슬롯이든 어레이 슬롯이든 상관 없이 전부 for 가능해서, 여기선 callback 들 순서가 큰 상관 없어서 중간에 nil이 허용됨. 그리고 그 중간중간에 table.insert 가 잘 넣어주는게 맞음. None 으로 바꾸면 무한정 불어나지만, nil이면 그렇지 않음.

### SL-4 — 핸들러 계층 값 금지의 근거
`Dispatch/Leaf.luau`가 처리하는 leaf 케이스는 **그 컴포넌트가 지금 만들고 있는
Instance 자기 자신을 가리키는 self-ref 캡처**라 `inst`가 고정돼야 의미가
성립하는데, **Slot은 이미 존재하는 부모에 나중에 독립적으로 붙는 동적 리스트라
그 전제 자체가 없다** — Slot 안의 Ref가 무엇을 가리켜야 하는지 정의가 안 된다.
대체 경로(`slot:Add(Frame { Ref = myRef })`, 여기서 `Frame`은 `Ref`라는 named
파라미터를 받는 **컴포넌트 함수**)가 있어 능력 손실도 없다.
-> 맞고, 틀린건 없는데 Frame {} 로 두면 리프 노드로 보일 가능성이 있어보임. 실 문서상 그렇게 있다면 MyComponent 정도로 바꿔주는게 혼선의 여지가 없음.

### SL-5 — `isMounted` 이중 추적 분리
Slot 컨테이너 자신은 `self._mounted` 필드 하나로, 개별 element는 전역 멤버십
(`elementOwner`)으로 추적한다. `self._mounted`의 트리거 시점은 **Instance
`Parent` 대입 완료가 아니라 `Dispatch.process`가 이 Slot에 대해 실제로 호출된
순간**이다 — 다른 모든 "마운트됨" 판정이 dispatch-process 시점 기준이라 여기만
post-effect 기준이면 일관성이 깨진다.
-> 더 풀어 서술해주길 바람. 판단 보류

### SL-40, SL-43 SL-45
slot 에서 키가 사라지면 nil 로 updateFn 호출되는거 맞지? 근데 데이터 자체가 nil 일수도 있다는 생각. Detach 와 유사한 'KeyGone' 등의 상태지정 enum/싱글톤을 제공해버리고, T|KeyGone 하는게 안전해보인다는 생각.
'`updateFn`이 새 값을 반환하면 밀려난 `prev`는 **언마운트만**' 는 이상한듯. 새 값으로 밀려난 prev 는 dispose 되는게 맞음. updateFn 은 직접 destroy 를 호출 못함(reconcile 중 빼는게 안 되니까)
그래서 지울 방법이 존재하지 않고, 지워주는게 맞다고 봄.
Detach 홀드 중 키 소멸은 KeyGone으로 처리되면 해결될듯. updateFn 은 위에서 if v == KeyGone then ... 처리하는게 있는게 나아보임.
소멸 루프가 `keyIndex`를 순회하는 것 - 또한, 단순히 KeyGone 을 주고, userdata 를 지울지 말지는 유저가 결정하게 위임해버리는게 가장 깔끔하다고 보이는 부분임. 이것으로 SL-45 도 닫아짐.

### SL-48 — Destroy 이후가 공짜로 해결되는 이유
`inst`가 Destroy되면 gcconn이 죽어 `canExecute`가 거짓이 되고, `gchold`가
`Relate(inst)` 아래 있어 그 안에 붙잡힌 Observer/클로저(`mounted`/`userdata`/
`keyIndex` 포함)가 전부 GC 대상이 된다 — 명시적으로 구독을 끊는 새 코드가 필요
없다.
-> 더 나아가 slot in slot 에서도 유효한가 생각해보아야함. 아마 그런것으로 알고있음. 피지컬 홀더랑 오너가 다르거든.

### SL-51 — `:Single`은 `:List` 위의 순수 sugar
`:Single`은 `:List`를 0/1개짜리 배열로 감싸는 sugar이고, **key를 고정값으로
두는 게 핵심**이다(값 자체를 key로 쓰면 매번 다른 item 취급돼 파괴+재생성이
강제됨). `index`를 안 넘기는 이유는 형제가 자기 하나뿐이라 항상 상수라서다.
-> 주의할 점이 보임. state<Frame> -> slot {frame} 형태가 될 때 이전 state 에서 변경으로 다른게 와도, slot 이 이전 frame 을 destroy 해버리면 안 됨. 뽑는게 안되면 안된다는건데, list 슈거에서 Detach 가 사용중인지 확인이 필요해보임. 또, Slot 안에 State 가 오면 이를 Slot으로 감싸주는게 유효할텐데, 거기서 안전한지도 봐야함(SL-66 에서 사용되는걸로 보이긴 하나, 안전 유무는 별도의 문제로 보임)

### SL-58 — 배치 밖 단독 재마운트의 엣지 케이스
`state<Slot>` 값이 steady state에서 교체될 때는 부모 Blocker가 이미 꺼져 있어
부모의 `gatedRecompute`가 아직 flush 안 끝난 `slot.Length`로 한 번 계산할 수
있지만, flush가 끝나면 자기 교정된다 — 크래시도 영구 오류도 아닌 한 프레임짜리
낭비라 **손대지 않기로** 했다.
-> offset 을 먼저 설정해 주어, 계산된 오프셋을 받은 다음 리스트의 액티베이션 이후 Length 를 확정된걸 setLength 하고 나서 마운팅 처리를 하는데, 이 경우 length 가 여러번 계산되어 낭비가 나진 않는거로 알고있음. 단순 위치계산 루프가 한번 돌지만, offset 이 전부 같아 set 안 일어나고 가벼운거로 아는데, 아님?

### SL-59 — 재귀적 `Clear()` 금지
죽는 서브트리 내부에서 요소 수만큼 shift+recompute가 반복되므로, 순수 파괴 walk만
하고 outer 쪽 recompute는 자기 위치 하나에 대해 한 번만 돈다. → **예/아니오**
-> 실 상황에 대한 설명 더 필요함. 이 글만 보아서는 어떤 상황인지 정확히 판단 어려워보임. 판단 보류.

### SL-63 — Length 변경은 offset 변경으로만 전파
`recompute`가 `:Set()`하는 대상은 (a) 뒤 형제들의 offset, (b) owner가 Slot이면 그
`.Length` 둘뿐이고, Length 값 자체는 읽히기만 한다 — 새 전파 채널이 아니다.
-> (b) 가 뭔가 이상함. 오너의 length 를 직접 설정하지는 않을것임. 자신 length 를 변경하면, 자동으로 observer 에 등록된것으로 인해 length 가 업데이트 되는 방식일텐데, 그렇지 않음? 최종 리컴퓨팅 결과가 length 가 되는거 아니였음? 그걸 위해 blocker 로 전부 블록 하고도 레이아웃이 멀쩡하지만, 아래에서 offset/length 확인 순회 도는거 아녔음?

### SL-72 — `dispose` 범위에서 Observer/Effect 제외
Observer/Effect는 생존이 gcconn만으로 판정되고 "죽는 순간 트리 부기가 어긋나는"
문제가 원천적으로 없어 dispose 대상이 아니다 — 조기에 끊으려면
`unbindLifetime`으로 충분하다.
-> 우린 조기에 끊는걸 명시적으로 unbindLifetime 로 지원하지 않음. 그건 유저에게 드러나는 표면이 아니고, State<Observer?> 를 사용하는게 적절.

### SL-74 — ⚠️ 미해결 항목 확인: `SetAndDispose`
`Get()` → `Set(new)` → 옛 값 `dispose`라는 3단계가 불편하다는 지적에서 나온
`source:Apply(SetAndDispose(new))` 또는 `source:SetAndDispose(new)` 후보가 열려
있고, 전자는 `Apply`가 `State`가 아니라 **`Source`를 넘겨주는 함수**여야 하므로
`state:Apply` 시그니처에 영향이 갈 수 있어 **M3 착수 전 방향만이라도** 정해야
한다.
-> 타입 문제 때문에 Apply 를 오버라이딩 해서 source 타입을 함수에 건내주는건 못함. 그럼 source -> state 가 안전히 성립 못해서, Apply 라는 이름을 그대로 쓰지는 못함. 따라서 영향이 안 가고, 그냥 SetAndDispose() 로만 Set() 와 세트로 주는게 나아보이고, 그걸로 확정지어야할것 같다는 생각임.

### SL-75 — 해제 = 0/`None` 재등록
별도 unregister API는 필요 없고 `setOffsetSource(None)` → `setLength(0)` 재등록이
곧 해제다. 순서가 중요한 이유는 값이 틀려져서가 아니라 **죽는 중인 Source에
쓰기가 날아가기 때문**이고, 해제 시 `slot.Offset = nil`도 같이 해야 stale한
Offset을 공개하지 않는다.
-> 아님. nil 로 만들면 안 되는게, 포탈로 옮기는게 안 됨. 이미 offset 을 들고 가 바운딩 했다면 큰 문제가 생김. 그냥 stale하게 있는게 맞고, 나중에 offset이 멀쩡히 다시 설정되는게 옳음. 언마운트 시 offset stale 은 단순히 맞는 행동이고, 처음 생성 시 0 인것과 유사 동작임.

### SL-76 — `recompute`는 `nil`도 관대하게 skip
정상 상태에선 항상 `None`이 계약이지만 해제/재마운트 전이 구간에서 `nil`이
관측돼도 크래시 대신 skip이어야 한다 — 계약 완화가 아니라 순수 방어이고 등록
쪽은 여전히 `None`을 쓸 의무가 있다.
-> 말을 더 정리해주길 바람. 애초에 해제에서 nil이 관측 될 일이 없다고 생각하는데, 그게 아니라면 다시 더 자세히 말을 해주길 바람. 이것만으로는 판단이 어려움

### SL-78 — nested-Slot 결과의 Length만큼 건너뛰기
`updateFn`이 nested Slot을 반환하면 그 아이템은 물리적으로 `result.Length`개를
차지하므로 `pos`가 그만큼 건너뛴다. 남는 캐비엇은 `index`가 raw 스냅샷이라 nested
Slot의 Length가 outer reconcile 없이 나중에 바뀌면 이후 형제들의 `index`가 갱신
안 된다는 것이고, 이건 "`index`는 raw number" 설계의 당연한 연장이라 실시간
정확성이 필요하면 `updateFn`이 직접 처리해야 한다. → **예/아니오**
-> 의미를 모르겠음. 애초에 slot 내의 index 와, length 로 구해진 offset 은 다른 개념인데, 너무 섞어 말하는것 아닌지 생각해보길 바람. 또, Length 업데이트는 상위 slot 이 observe 하기에 형제 slot 갱신에 무관한데, 그 이야기가 아닌것임? LayoutOrder 내에서 index 만 쓰는게 아니다를 말하고 싶은건지, 더 자세히 말해주길 바람.

### AT-11 — ⚠️ 열린 항목 확인: `Frame { a, a }`
같은 그룹 객체를 두 위치에 놓으면 `groupKey(v, name)`이 그룹 객체별·이름별
메모이즈라 **완전히 같은 키**가 나와 claim 체크를 통과하고, 두 위치가 하나의
체인을 공유하다가 `k=1` retract가 `k=2`의 바인딩까지 철거한다. `Ref`처럼
`bindLifetime`으로 막을 수 **없는** 이유는 그룹 Attribute 값은 여러 곳에서 쓸 수
있어야 하기 때문이고, 그래서 **위치별 claim 레지스트리를 하나 더** 두기로 방향은
확정됐으나 **키를 무엇으로 할지와 `nameClaims`와의 공존은 미정**이다.
-> groupClaimKeys 정도로 확정. 더 나은 답이 있다면 적어주길 바람. 다만 충분하다고 생각하는 이름임.

### AT-13 — 해제→재클레임 순서는 Dispatch가 보장
같은 핸들러 재프로세스는 `retractor(v)` → `process`, 핸들러가 바뀌면
`retractFrom` → `process`라 어느 경로든 옛 claim 반납이 먼저다.
-> 정확히는 같은 핸들러 재프로세스는 retractor 를 process 에서 굴리고 자기 작업을 함. 따라서 process → calls retractor(v) → process new one 이 맞는걸로 보이는데. 단순 축약상 정보유실인것 뿐이지, 실제 구현은 저렇게 알고 있는게 맞음?

### AT-20 — 생존 이름도 매 사이클 철거→재등록
클로저는 인자(새 값)를 안 보고 자기가 등록한 키 전부를 균일하게 철거하며, 비용은
`StoreBind` 재구독과 같은 값 `setAttribute` 한 번뿐이다. 그룹 전용 체인이 된
지금은 최적화도 가능하지만 옛 이름 집합을 또 들고 있어야 해 부품이 늘어나므로
**기본은 균일 철거 유지**다.
-> 생존 이름에 대해서 최적화 불가함. 실 value 자체가 바뀌고 같은 값인지 비교를 해야하는데, 그러면 값을 진짜 까봐야 하고, 이전 값을 알아야하기 때문. 이름 목록의 변경으로 최적화가 되는 요소가 아님.

### TW-12 — `CanAnimate`
생략하면 기본 `true`이고, `false`로 resolve되면 `Tween`으로 안 감싸고
`self:Get()`을 그대로 반환한다 — reduceMotion류 접근성 우회가 이 필드 하나로
표현된다. 케이싱은 나머지 필드와 맞춰 `CanAnimate`(PascalCase)다.
-> 단순 boolean 으로만 설명했는데, 정확히는 CanAnimate: state<boolean> | boolean | nil 이다. 이미 그럴것으로 보이고, 아니라면 정정해야함. 다른것과 똑같게, 필요 시 바로 Get()

### TW-16 — `initValue`는 에이전트 범위 밖
초기 진입 애니메이션은 필요해지면 **사용자가 직접 코드베이스+문서를 만지기로**
확정됐고, 에이전트는 임의로 착수하지 않는다.
-> 틀리진 않았는데, Human todo 에 언급이 없음.

### UI-5 — ⚠️ 확인 필요 항목
숏핸드가 만드는 **자식**도 quad가 만든 Instance이므로 gcconn/gchold 셋업을
거치는지 구현 시 확인해야 하고, 안 거치면 여기서만 조용히 미아가 된다.
-> 애초에 똑같이 process 로 위임하는 이상, gcconn/gchold 없으면 옵저버 바인딩 부터 실패함. 일반 요소처럼 똑같이 UI...{} 처럼 생성되어도 되고, 어떤 방식으로든 gcconn/gchold 가 셋업되는게 맞음. 확인했고 해소된 요소가 될듯.

### UI-8 — `mapTweenValue`가 필요한 이유
`v`가 `Tween<number>`면 `wrap` 변환을 **`Tween`을 벗기지 않고 `.Value`에만**
적용해야 하므로, `table.clone` 후 `Value`만 교체해 `Tween(opts)`로 다시 만든다.
`wrap`이 항등인 키도 분기 없이 이 헬퍼를 거친다.
-> 그냥 펑터 구조를 그대로 줘도 무방한듯. :Map 정도로써 새 Tween 을 새 관측된 Value 로 형성. Tween<T>:Map(T) -> Tween<T> 가 타입 상 안전히 가능하다. 이는 Tween<T> 에 대한 기본 정의를 두고 다른곳에서 Map 해서 재사용하는 구현도 가능케 할수도 있게 보이긴 하나, 사용 케이스가 넓지는 않을것. 단 외부에 보이는게 무해하고, 어차피 내부 구현 상 필요하므로 같이 만들어도 좋아보임. 혹은 Mapped 의 immutable 의 ed 형태를 써도 좋아보임.

### UI-11 — 자식 파괴 시 `retractFrom` 호출
자식을 파괴할 때 실행 중인 엔진 Tween이 남아있을 수 있으므로
`Dispatch.retractFrom(child, prop, 1)`을 같이 부르는 게 정석이고, retractor 안에서
**다른 키**에 대한 `retractFrom`은 허용된 경로다. → **예/아니오**
-> 자식 파괴 시 사실 Tween 은 엔진에 의해 자동 멈춤/무효/삭제 처리되고, 트윈 자체가 retract 되어도 아무것도 안 하는 nop 라 의미가 없을것이다.

### ML-5 — 멱등 가드는 `module`을 키로 하는 `Relate`
각 `InitXxx`가 파일 스코프에 `Relate()` 하나를 두고 `module`을 키로 "이 인스턴스에
이미 Init됐는지"를 기록한다. `require` 캐시로는 부족한 이유는 그게 **파일**
단위인데 `New()`는 여러 `module` 테이블을 만들 수 있어서다. → **예/아니오**
-> 새로운 커밋에서 이것이 달라짐.

### ML-9
`Quad.debug: boolean`(기본 `false`)은 라이브러리 자체의 디버그 스위치이고 지금
게이팅하는 건 핸들러 우선순위 동률 경고 print다. 기본이 `false`인 이유는
라이브러리가 사용자 콘솔에 아무것도 안 찍는 게 기본이어야 하기 때문이고,
다중 인스턴스화 시 인스턴스별인지 전역인지와 `listHandlers()`가 이 표면에
속하는지는 **미정**이다.
-> D-8 가 해소시킴

### LH-8 — 스코프 판단이 틀렸던 것
"(a) 자기 프로퍼티만 / (b) 서브트리 전체" 중 "(a) 메커니즘은 (b)를 못 준다"는
판단이 틀렸음이 드러났다 — 배열 파트 루프가 각 자식의 마운트를 동기적으로
끝내므로 (a) 메커니즘이 사실상 (b) 스코프를 공짜로 준다. 진짜 경계는
(a)/(b)가 아니라 **"자기 아래 vs 자기 위"**였다.
-> 사람이 너무 이해하기 어려운 표현임. 틀린말은 아닌듯 한데, 너무 어려워서 이것만 보고 판단은 안될듯. 풀어 보여줘야함.

+
`OnRendered`라는 이름이 `componentDidMount` 같은거 구현 가능하면 좋긴하겠는데 별로 애매한가 생각중... 화면 그려지기 전에 애니메이션이 된다던가 하지 않게 하는 방안이 있음 좋아보임. 하지만 나중에 얹어져도 좋을 이야기이고, 당장은 사용사례가 안 보이므로 추가 프리미티브에 백로깅만 하고, 나중에 필요하다는 의견이 나오면 재생각 해볼 예정.

+
destroySlotTree 가 소유를 명시적으로 지워야할 이유가 있냐 의문. Destroy 된 요소는 다른곳에 원래 마운트 못하는게 보통 엔진 정상이고, 또, 릴리즈 안 되어 다른곳에 마운트 막혀도 상관 없고, 그게 정상 동작일 수 있어보임. 정확한 형태가 어떤지 알아봐야할 상황.

+
Length 를 통해 '먼저 밀어내고 나서' 그 공간에 넣는다가 지금 관행인데, 다른 crud 와 list 도 이게 통하는지 봐야함. 만약 밀어내고 당기지 않은 상태에서 그 공간에 넣는다 하면, 밀어내는걸 구현해야하는 백엔드에서 골치아파짐. 지금 어떤 상황인지 확인해볼것

+
지금 명시적으로 Attribute(store1, store2, ..., {plain = "table도 됨"}) 로만 되어있고, plain= 에 state/source/T 가 올 수 있음을 안 알려주는 모양으로 나오는데, 그렇게 적어도 된다 생각함. 엔지니어링 비용이 없고, 그냥 이미 그렇게 구현되도록 만들 계획이였다고 생각함. 그리고 뒤에 오는기 이기는 것 또한, 잘 명시되어있나 봐야함.
