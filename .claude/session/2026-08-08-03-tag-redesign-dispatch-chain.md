<!-- quad-v2 세션 로그 원문 — CLAUDE.md에서 이전됨(2026-08-11 정리 세션). -->
<!-- 이 파일은 quadnomicon 개발로그 소재용 원자료로, 당시 시행착오(정정 전 서술 포함)를 그대로 보존함. -->
<!-- 현재 유효한 설계는 이 파일이 아니라 base//research//archive/가 최종 소스 — 이 파일 안의 판단이 이후 세션에서 뒤집혔을 수 있음. -->

## 2026-08-08 세 번째 세션 — Tag를 array-part 값 객체로 재설계, Dispatch
체인+`retractUnder`로 재귀 재-dispatch의 retract 전파 문제 해결

같은 날 이어진 세션. 사용자가 "Tag를 해시 파트 boolean 키 대신 array-part
값 객체로 바꾸는 게 낫지 않냐"는 질문으로 시작 — 상호배타 스타일 상태
(`btn1`/`btn2`/`btn3`류, 20개까지도 가능)를 표현하려면 구 모델은 태그
개수만큼 키를 갱신해야 해서 끔찍하다는 실사용 근거. 이 논의가 "retract가
새 값의 타입에 따라 이전 핸들러를 정확히 찾아 부를 수 있는가"라는 훨씬
근본적인 구멍(`pre-implementation-audit.md` 1-2번이 이미 지적해뒀던 것)을
직접 건드리게 됐고, 몇 차례 시행착오 끝에 사용자가 제시한 "체인+
`retractUnder`" 설계로 수렴. 세 갈래로 정리:

**1. Tag 재설계 — array-part 값 객체, `Modifier`와 같은 immutable clone
체이닝.** `Tag(name1, name2, ...)`(가변인자 생성자, 빈 `Tag()`도 유효),
`:Added`/`:Removed`(뮤테이션처럼 안 보이게 `-ed` 어미 — 실제로는 항상
clone 후 반환), `:Contains(name):boolean`, `:Apply(factory)`(Modifier와
동일한 순수 체이닝 설탕), `Tag.Merged(tag1,tag2,...)`(집합 합집합, 무손실
— Modifier의 `Override`는 필드 단위 덮어쓰기라 손실 있음, 그래서 이름도
다름). `None` 센티널은 불필요로 확인 — 동적 토글은 `Source`/`State`가
계산 결과로 `nil`을 리턴하면 되는 함수 인자 전달이라 테이블 리터럴의
nil-hole 문제 자체가 없음(정적 리터럴에서 조건부로 Tag를 넣고 뺄 때는
다른 array-part 값과 마찬가지로 기존 `None` 관용구가 그대로 유효, Tag
전용 규칙 아님). 구 모델(해시 파트 boolean, "핸들러 타입이 안 바뀌니
retract 불필요"가 결론이었음)은 `archive/tag-hash-key-model-reversed.md`로
역전 보존, `base/tag-plan.md` 전면 재작성. 값 타입+API(`Tag.luau`)는
quad-base, `CollectionService` 글루(`Handlers/Tag.luau`)만 quad-roblox —
이미 확정된 "base는 인터페이스/값, backend는 process·retract 글루"
패턴(`LifetimeHandle`)을 값 타입 수준까지 그대로 확장한 것으로 확인,
새 아키텍처 개념 아님.

**2. Tag 재설계가 "retract가 실제로 필요해지는" 첫 array-part store-bind
사례가 되며, 기존 "이전 핸들러 추적" 설계 공백이 정면으로 드러남.**
`pre-implementation-audit.md` 1-2번이 이미 "store-bind 재실행 모델에서
realv 타입이 매 갱신마다 바뀔 수 있는데 '이전 핸들러'를 누가 추적하는지
불명"이라고 짚어뒀던 것 — Tag가 `Tag(...)`↔`nil` 사이를 오가며 실제로
핸들러 타입이 바뀌는 구체 사례가 되어 더 이상 미룰 수 없어짐. 시행착오
과정:
- **1차 제안(제가 냄, 기각됨)**: Dispatch가 `(inst,k)`별로 "지금 누가
  담당 중인가"를 슬롯 하나로 추적. **재귀/래핑 핸들러(StoreBind 등)
  에서 깨짐** — 사용자가 직접 "A→B 구조에서 A가 바뀌면 B의 retract가
  실행되고, 재귀로 B로 다시 내려오면 retract가 없는 거 아니냐"고 반례를
  제시 — A 자신의 생명주기(예: Observer 구독)와 A가 재귀로 위임한 B의
  생명주기가 슬롯 하나를 두고 서로 덮어써서, A가 스스로 재-dispatch할
  때 자길 엉뚱하게 retract하거나 반대로 안 해야 할 때 안 하는 오작동이
  생김이 실제 트레이스로 확인됨.
- **2차 제안(제가 냄, 부분 기각)**: 각 래핑 핸들러가 자기 전용 `Relate`에
  위임 대상을 비공개로 저장(A→B→C면 A.retract가 수동으로 B.retract를
  부르고 B.retract가 수동으로 C.retract를 부르는 linked 구조). 동작은
  하지만 사용자가 두 가지 지적: (a) 나중에 재바인드(`existing-instance-
  bind-plan.md`) 지원을 생각하면 위임 정보가 핸들러별로 비공개 분산돼
  있어 외부에서 못 들여다봄, (b) 각 핸들러 작성자가 "내 retract에서
  위임 대상도 cascade해야 한다"는 걸 매번 기억해야 하는 규율 의존적
  설계.
- **최종 채택(사용자 제안) — Dispatch가 `(inst,k)`별 핸들러 체인(순서
  있는 배열)을 직접 소유, `Dispatch.retractUnder(inst,k,keep,v)`가
  꼬리부터 `keep` 앞까지 훑으며 정리.** `Dispatch.process`가 매치될
  때마다 체인에 push, 재귀/래핑 핸들러는 재-dispatch 전에
  `retractUnder(inst,k,self,newV)`를 먼저 불러 자기 밑을 정리 — 이
  한 번의 루프가 다단 체인(A→B→C) 전체를 순서대로 정리해주므로 개별
  핸들러의 `retract`는 더 이상 자기 위임 대상을 수동으로 안 쫓아가도
  됨(2차 제안의 (b) 해소), 체인이 Dispatch에 중앙화돼 있어 미래
  재바인드도 `retractUnder(inst,k,nil,newV);process(inst,k,newV)`
  두 줄로 자연스럽게 됨((a) 해소) — quad-debug의 "무엇이 무엇에
  연결됐는가" 그래프도 이 구조를 그대로 읽으면 됨. 배열이 항상 꼬리에서만
  추가/삭제되는 스택 모양이라 `None` 소진 이슈(구멍 있는 정수 키 순회
  문제)도 애초에 안 생김. **`retract`는 여전히 `(inst,k,v)` 3-인자
  유지** — 한 차례 제가 "v 제거"를 제안했다가 틀렸음(사용자가 Tag의
  전체삭제 vs diff 분기를 근거로 정정) — 다만 최종 설계에서 diff는
  `process`(같은 핸들러 유지 시)의 몫이고 `retract`는 항상 "더 이상
  매치 안 될 때만" 불리므로 Tag 한정으로는 `v`를 안 봐도 항상 전체
  삭제가 맞다는 것도 확인. 순환은 기존 "일반적 무한루프 방어 안 함"
  원칙(2026-08-04) 그대로 UB.

**3. 전부 `base/bind-system-plan.md`(신규 "Dispatch 체인" 절 + "확정된
디스패치 모델"/"None 센티널"/"Store 바인드는 특수 경우인가" 절 갱신)/
`base/tag-plan.md`(전면 재작성)/`archive/tag-hash-key-model-reversed.md`
(신규)/`base/architecture.md`(소스트리 `Tag.luau` 추가, 4번 항목 정정)/
`ROADMAP.md`(M2/M4/M10)/`research/pre-implementation-audit.md`(1-2번
해소 표시)에 반영 완료.**

**다음 세션이 할 일**: 안 바뀜(`ROADMAP.md` M0부터). M2/M4 스파이크
검증 목록에 `chains`/`retractUnder`가 다단 체인에서 실제로 정확히
동작하는지가 새로 추가됨(추론만으로 확정된 것, `pre-implementation-audit.md`
류 "실제 Luau로 부딪혀본 적 없는 것" 범주). `pre-implementation-audit.md`
1-1번(Tween이 유일한 store-bind 예시라 "일반 store-bind와 Tween이 같은
핸들러인지"가 불명확한 문제)은 Tag가 두 번째 구체 사례가 되면서 정황상
"별개 핸들러, 둘 다 `Dispatch/StoreBind.luau` 재사용"쪽에 힘이 실리지만
**아직 명시적으로 확정된 건 아님** — M2/M4 착수 전 마저 확인할 것.

