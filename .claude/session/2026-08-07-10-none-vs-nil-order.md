<!-- quad-v2 세션 로그 원문 — CLAUDE.md에서 이전됨(2026-08-11 정리 세션). -->
<!-- 이 파일은 quadnomicon 개발로그 소재용 원자료로, 당시 시행착오(정정 전 서술 포함)를 그대로 보존함. -->
<!-- 현재 유효한 설계는 이 파일이 아니라 base//research//archive/가 최종 소스 — 이 파일 안의 판단이 이후 세션에서 뒤집혔을 수 있음. -->

## 2026-08-07 열 번째 세션 — 소진 슬롯을 `nil`이 아니라 `None`으로,
사용자가 Luau REPL 반례로 직접 발견

같은 날 이어진 세션. 사용자가 Luau REPL에서 직접
`for i,v in {[1]=1,[2222]=2222,[211]=211,[131]=131,[3]=3,[6]=6,
[122]=122,[11]=11,[312]=312,[821]=821,[991]=991} do print(i,v) end`을
돌려 순회 순서가 `1, 6, 122, 11, 991, 2222, 131, 312, 3, 821, 211`로
나온다는 걸 보여줌 — index 오름차순이 전혀 아님. 이건 위 아홉 번째
세션에서 "PreRef pre-pass가 fire된 슬롯을 `nil`로 지우면 된다"고 적은
것과 여섯 번째 세션에서 "Ref 콜백/대기자 배열도 `[i]=nil`로 소진하면
된다"고 적었던 것 둘 다를 뒤집는 반례 — 키가 촘촘한 저범위 정수에서
벗어나면(구멍이든 원래 듬성듬성이든) Luau/Lua 테이블이 해시 파트
취급으로 넘어가 순회가 해시 버킷 순서가 됨.

**해결 — 소진에 `nil` 대신 `None` 센티널 사용, 전 코퍼스에 전파.**
`None`은 `nil`이 아닌 실재하는 값이라 그 슬롯을 "차 있다"로 유지시켜서
테이블이 "구멍 없는 시퀀스"라는 불변식이 안 깨짐 — 두 가지를 동시에
해결: (1) 순서가 실제로 중요한 배열(PreRef pre-pass)의 순서 보장 유지,
(2) `table.insert`가 내부적으로 쓰는 `#t`가 Lua 명세상 구멍 있는
테이블에서 정의되지 않은 동작이라는 문제(Ref 콜백/대기자 배열이 새
등록 때 `table.insert`를 씀 — 순서 자체는 원래도 안 중요했지만 이
`#t` 안전성 문제는 진짜 버그였음). **배열 파트의 `None`은 해시 파트의
`None`(Modifier 필드 명시적 지우기, `NoneHandler` 경유)과 의미가
다름** — 배열 파트 `None`은 처리할 핸들러가 없는 순수 빈 슬롯 표시라
`Dispatch.process`/`NoneHandler`를 안 거치고 두 패스 루프 자신이 직접
`if v == None then continue end`로 스킵.

`base/bind-system-plan.md`의 "왜 `nil`이 아니라 `None`인가"(Ref
콜백/대기자 절)와 PreRef pre-pass 절에 반영, `ROADMAP.md` M0/M8
체크박스 갱신, 위 아홉/여섯 번째 세션 문단에 정정 표시 추가(원문은
유지, 틀렸던 부분만 짧게 정정 포인터).

**부수 발견 — `props.Modifier`/`props.Ref` nil-hole 위험도가 이전
서술보다 큼.** `pre-implementation-audit.md` 1-5가 이미 이 위험을
"뒤 항목까지 무시될 수 있음"으로 국소적 피해처럼 서술해뒀는데, 이번
REPL 실측으로 실제로는 구멍이 하나만 생겨도 **그 테이블 전체**가 순서
보장을 잃을 수 있다는 게 드러남 — M0 스파이크에서 반드시 실측하고,
심각하면 "raw 리터럴 대신 `props.Modifier or Modifier()`로 non-nil
보장" 컨벤션 문서화까지 검토하기로 `ROADMAP.md` M0에 메모 추가. 이
케이스는 caller가 직접 쓰는 raw Lua 리터럴이라 `None`으로 프레임워크가
대신 채워줄 수 없어서 별도 해법이 필요함 — `None` 소진 전략과 혼동하지
말 것.

**다음 세션이 할 일**: 안 바뀜(`ROADMAP.md` M0부터). M0 착수 시 위
nil-hole 위험도 실측이 우선순위 높아짐.

**같은 세션 세 번째 후속 — `props.Modifier`/`props.Ref` nil-hole
해법을 실제로 확정, 세션 clear 전 문서 완결성 점검하며 발견한 갭
3개도 같이 보강.** 사용자가 "컴포넌트에서는 꼭 `or None`이나
`Modifier()` 같은 걸로 nil 못하게 강제하는 걸 문서화하자"고 요청, 그
자리에서 결정하고 clear 전 세션 전체를 다시 훑어 새로 알게 됐지만
아직 문서에 없던 것들을 마저 채움:

1. **`props.Modifier or None`/`props.Ref or None`을 필수 관용구로
   확정** — `Modifier()`(빈 modifier 새로 생성)가 아니라 `None`을 쓰는
   이유는 이미 있는 array-part `None`-스킵 메커니즘(PreRef 논의에서
   확정)을 그대로 재사용해 새 코드/할당이 하나도 안 늘어나기 때문 —
   `flatten`이 `isModifier(None) == false`라 그냥 통과시키고, 이어지는
   두 패스 루프가 `None`을 만나면 스킵. `base/component-composition-plan.md`
   "필수 관용구" 절 신설, `ROADMAP.md` M0/`pre-implementation-audit.md`
   1-5/`question.md`에 반영(1-5는 해소로 표시).
2. **`Modifier()` 바닥 생성자가 문서 어디에도 없었던 갭 발견·보강** —
   `Source(default)`/`Ref(default)`/`Store({defaults})`와 나란히 있어야
   할 "`Type(args)` 팩토리" 4번째 예시가 원래 없었음(이전 아홉 번째
   세션에 `Modifier.Rounded(8)` stale 참조를 고치면서 실수로 체이닝
   예시인 `mod:UICorner(8)`로 잘못 채워 넣었던 것도 같이 바로잡음).
   `modifier-plan.md` 3번 절에 명시, `store-semantics.md` 예시 목록
   정정, `ROADMAP.md` M7 체크박스 추가.
3. **`Brand` 태그 목록에 `RefTag`/`PreRefTag`/`ModifierTag`가 빠져있던
   갭 발견·보강** — 이번 세션 내내 `isPreRef(v)`/`isModifier(v)`를
   이미 존재하는 predicate처럼 써왔는데 정작 여덟 번째 세션의 `Brand`
   태그 목록엔 없었음. 추가하면서 **`isRef`/`isPreRef`가 `isState`와
   달리 집합 멤버십이 아니라 단순 항등이라는 것도 명시** —
   `isRef(preRefInstance)`가 참이면 일반 `(v=Ref)` 핸들러가 `PreRef`도
   집어삼켜 PreRef 전용 pre-pass/가드 Handler 설계 전체가 무너지므로
   반드시 배타적이어야 함. `bind-system-plan.md`의 `Brand` 절,
   `ROADMAP.md` M2 체크박스에 반영.
4. **배열 파트 `None`과 해시 파트 `None`(`NoneHandler`)이 같은 센티널인데
   처리 경로가 다르다는 걸 `None` 센티널 절 자체에 명시적으로
   교차 참조 추가** — 이전엔 PreRef 절에만 있고 `None` 센티널 원래
   정의 절엔 이 예외가 안 적혀 있어서, 그 절만 읽으면 모든 `None`이
   `NoneHandler`를 탄다고 오해할 수 있었음.

전부 커밋 `98bd46a` 이후 아직 커밋 안 된 이번 대화 전체 변경사항에
포함 — 다음 세션이 새로 알아야 할 건 없음, `ROADMAP.md` M0부터 그대로
시작.

