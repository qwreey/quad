# 2026-08-19 — `PopOnly` → `Detach` 리네임 + 공개 표면 위치 확정

**요청**: `base/slot-plan.md`에 가칭으로 남아있던 `PopOnly`(`:List`
reconcile에서 "파괴하지 말고 자리만 비우라"는 반환 센티널)의 이름을 사용자가
직접 못 정해 아이디어를 요청 — "지금은 다른 에이전트들이 있어서 쓰지는
말아달라"는 조건으로 브레인스토밍만 먼저 진행.

## 1. 메커니즘 재확인

`base/slot-plan.md`의 "`nil` 리턴은 파괴가 기본" 절을 다시 읽고 의미를
정리: `:List` reconcile에서 `updateFn`이 반환하는 sentinel로, 이 자리를
언마운트(`Parent = nil`)는 하되 **파괴는 하지 말고 userdata를 들고 있다가
나중에 재사용**하라는 지시 — 목적은 `Instance.new`/`Destroy` 비용을 아끼는
재사용(오브젝트 풀링에 가까움). `nil` 반환(파괴)과도, 새 값 반환(언마운트만,
즉시 교체)과도 구분되는 세 번째 경로.

## 2. 이름 후보 제시

풀링/보관 은유 계열(`Bench`/`Stash`/`Shelve`/`Park`), "언마운트+보류" 계열
(`Hold`/`Detach`/`Suspend`), 기존 조어 구조를 살리는 계열(`PopKeep`/
`KeepOnly`/`SoftPop`)을 제시하고 `Bench`(가장 직관적인 은유) 또는 `Hold`
(문서가 이미 "홀드"라는 용어를 쓰고 있어 도입 마찰이 적음) 둘 중 하나를
추천.

## 3. 사용자가 `Detach` 선택 — 근거 검증

사용자: *"Detach 많이 괜찮아보이는데, Slot 에서 뽑아내다라는 Extract 를
지금 쓰고 있으니까, 이미 있는 Extract 를 쓰긴 뭐하니 Detach 를 넣는건
어때보임?"*

`Extract`/`ExtractAll`은 호출자가 직접 부르는 **명령형** 추출(소유권을
통째로 호출자에게 넘김)인 반면, `Detach`(구 `PopOnly`)는 reconcile 내부에서
여전히 userdata로 추적하며 화면(부모 계층)에서만 떼는 **선언적** sentinel —
"소유권 이관" vs "내부 보류 상태"로 성격이 갈려 `Extract`와 이름이 겹쳐도
혼동 소지가 적다고 판단, 채택 추천. Roblox 개발자가 `Attachment`/
`WeldConstraint`류의 물리적 "detach"를 먼저 연상할 여지는 있지만 "부모
계층에서 떼어낸다"는 실제 동작과 크게 어긋나지 않아 큰 문제 아니라고 정리.
`Detach` 채택 확정.

## 4. 공개 표면 위치 — 최상위 export

사용자: *"근데 그러면, Detach 는 어디에서 던져줘야한다 생각함? 그냥 base
모듈 바로 최상위? Slot 이랑 연관인데 Slot 옆에 존재하게 되는게 뭔가 느낌이
애매한거 같긴 함. 그런데 Slot 은 또 함수라서, 뭔가 넣기 애매해. 넣으려면
메타테이블이 되어야하기도 하고. 그냥 최상위가 좋음?"*

`architecture.md`의 패키지 트리를 확인해 `None` sentinel의 선례를 찾음 —
`None`도 Slot 요소/Attribute/offsetSource 등 여러 곳에서 쓰이는 sentinel
이지만, 공개 표면은 패키지 최상위(`quad-base/src/init.luau` 재노출)이고
실제 정의는 관련 로직 옆(`Dispatch/None.luau`)에 있음(공개 표면과 구현
위치가 분리돼 있는 기존 패턴). `Detach`도 같은 성격의 sentinel이므로 같은
자리(최상위)에 두는 게 일관적이라고 판단 — `Slot`이 함수라 `Slot.Detach`
형태로 붙이려면 callable-table+메타테이블이 새로 필요한데, sentinel 상수
하나 때문에 그 구조를 들이는 건 `conventions.md`의 "드문 오용이나 가상의
미래 요구까지 방어/최적화하려고 구조를 복잡하게 만들지 않는다" 원칙에
안 맞음. 정의 파일 위치(`Slot.luau` 또는 `Dispatch/Slot.luau`)는 `None`과
같은 패턴(정의는 관련 로직 옆, 재노출만 `init.luau`에서)을 따르되 정확한
배치는 M6 구현 시점에 확정하기로 함.

## 5. 반영

사용자: *"이거 base/slot-plan.md에 정리해서 반영해줘. 세션 기록도
남겨주고, 핸드오버 준비해줘. 적절히 정해진것 같아서 커밋해줘도 될듯."*

`base/slot-plan.md`("이름은 가칭" 불릿을 "이름 확정"/"공개 표면 위치 확정"
두 불릿으로 교체, 본문 전체의 `PopOnly` 표기를 `Detach`로 치환하되 사용자
발언 직접 인용과 히스토리 서술은 유지), `question.md`(용어 정리 1번 항목을
`DI`→`D`와 같은 형식의 `[해소됨]` 항목으로 교체, 3번의 남은 열린 항목 이름만
치환), `todos.md`(00번/2번 항목 갱신), `archive/question-resolved.md`(새
`[해소됨, 2026-08-19]` 절 추가), `ROADMAP.md`(M6 체크리스트의 `PopOnly`
표기 치환)에 반영. 인덱스 레이어(`README.md`)와 `session-summary.md`도
같이 갱신, 이 문서가 그 포인터.
