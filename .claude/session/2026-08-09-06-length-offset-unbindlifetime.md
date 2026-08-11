<!-- quad-v2 세션 로그 원문 — CLAUDE.md에서 이전됨(2026-08-11 정리 세션). -->
<!-- 이 파일은 quadnomicon 개발로그 소재용 원자료로, 당시 시행착오(정정 전 서술 포함)를 그대로 보존함. -->
<!-- 현재 유효한 설계는 이 파일이 아니라 base//research//archive/가 최종 소스 — 이 파일 안의 판단이 이후 세션에서 뒤집혔을 수 있음. -->

## 2026-08-09 여섯 번째 세션 — 여러 Slot이 형제로 섞일 때 순서 보장 완전
해소(Length/Offset), `unbindLifetime` 신설

**출발점**: 사용자가 미래의 `quad-web`을 가정하며 `{ Slot, Element, Slot }`처럼
Slot이 여럿 형제로 섞일 때 최종 순서를 어떻게 보장하는지 물음 —
2026-08-04부터 "Roblox 단일 백엔드로는 급하지 않음"으로 후순위 열려있던
질문(`slot-plan.md` "여러 Slot이 섞일 때 순서 보장" 절)을 실제로 라이브
설계해서 완전히 풀어낸 긴 단일 스레드. 시행착오를 거쳐 최종 수렴한 결론만
정리(중간 대안들 — "구간 예약"/`:With`+`:Compute` 체인 — 은 채택 안 됨,
사용자가 제시한 "정확한 누적합 + 플랫 재계산 루프"가 최종안):

- **핵심 전환**: "각 원소가 절대 위치를 계산해서 전파"가 아니라 "각
  구조적 위치가 자기 앞 형제들의 개수 누적합(`offset`)만 알면 됨" —
  Roblox `LayoutOrder`가 이미 `Instance.Parent` 물리 순서와 분리된
  정수 프로퍼티라는 사실이 이 전환을 공짜로 성립시킴.
- **`Dispatch.setLength(inst,i,len:number|State<number>)`/
  `Dispatch.setOffsetSource(inst,i,offset:Source<number>|None)`** —
  둘 다 Handler→Dispatch 등록(push) 방향, array part의 **모든** number
  인덱스에 대해 반드시 호출(생략 UB — Handler 구현체 작성자만의 계약,
  일반 사용자 영향 없음). `recompute`는 매번 `1..N` 전체를 도는 단순
  루프(N은 저작 시점에 고정된 배열 리터럴 길이라 무시 가능)로, 각
  `offset:Set()` 호출 앞에서만 `Get() ~= sum` 가드를 걸어 실제로 안
  바뀐 위치의 캐스케이드(다운스트림 `LayoutOrder` 재적용)를 막음 —
  전체 순회 비용과 `Set` 캐스케이드 비용을 분리해서 후자만 최적화.
- **각 원소의 `LayoutOrder`는 `localIndex+offset`의 State를 기존
  store-bind 프로퍼티 바인딩에 그냥 얹는 것** — 이게 이 설계의 가장
  큰 단순화 지점: "offset 변경 시 이미 마운트된 원소를 다시 써야 한다"는
  요구가 새 push/observer 메커니즘 없이 **이미 있는** store-bind
  재실행 모델(`state:Observer(fn):Subscribe()`) 재사용만으로 공짜로
  풀림.
- **`setLength`의 내부 Observer는 leaf-lifetime 경로(`bindLifetime`)를
  씀, `:Subscribe()` 아님** — 이 Observer는 특정 leaf가 아니라 `inst`
  자신에 종속된 내부 배관이라, `inst` Destroy 시 자동으로 안 죽는
  `:Subscribe()` 경로는 안 맞음. `State<Slot>` 교체처럼 `inst` 전체가
  죽기 전에 특정 위치 하나만 조기 재등록해야 하는 경우를 위해
  **`unbindLifetime(inst,value)`을 `bindLifetime`/`canExecute`의
  세 번째 짝으로 신설** — `Dispatch.setLength`가 gchold 내부 저장
  구조(배열/키드 테이블)를 몰라도 이전 등록을 블랙박스로 해제할 수
  있게 캡슐화. quad-roblox 구현 스케치도 gchold를 배열 대신 `value`를
  키로 쓰는 테이블로 바꿔 `unbindLifetime`을 O(1)로(`gchold[value] =
  nil`) — base 결정은 아니고 참고용 스케치.
- **동기 순서 요구사항**: Slot의 `rawAdd`는 `Length:Set(newCount)`
  (다운스트림 offset/LayoutOrder 캐스케이드가 여기서 동기적으로 끝남)
  다음에 `element.Parent = target`을 호출 — Source:Set()이 옵저버
  체인을 동기적으로 끝까지 도는 기존 모델 덕에 별도 배리어 없이 순서만
  지키면 자동 성립. 안 지키면 Roblox의 실시간 `UIListLayout` reflow가
  한 프레임 잘못된 순서를 노출할 위험.
- **`Slot.Length: State<number>`가 CRUD/`:List` 여부와 무관하게 항상
  노출되는 프리미티브 필드로 확정** — 사용자가 직접 "n개 검색됨" UI에도
  쓸 수 있다고 지적, `setLength`가 내부적으로 읽는 값과 완전히 동일(두
  용도를 겸함, 별도 State 아님). `:List`의 filter=진짜 Remove 확정
  덕에 "Visible 토글은 안 잡힘"이 자연히 성립(새 캐비엇 아님).
- **웹 백엔드(quad-web) 일반화 — base 로직 100% 재사용, backend
  Handler의 "offset 변경 시 할 일"만 달라짐**: DOM `insertBefore`는
  물리적 삽입 시 뒤 형제를 자동으로 밀어주므로, offset이 바뀌어도
  이미 마운트된 노드를 실제로 옮길 필요가 없음 — quad-web Handler는
  offset 변경 관측 시 no-op, 숫자는 그 위치가 **다음** insert/remove
  때 쓸 물리 인덱스로만 부기됨. 처음 검토했던 "구간 예약"(고정 gap)이나
  "앵커 기반 상대 삽입" 안보다 이 방식이 dense global rank라 두 종류
  백엔드(순서-분리 프로퍼티형/물리-순서형) 모두에 더 직접적으로 맞음.
- **백로그로만 남김**: `Slot():Single(state, updateFn?)` — `:List`의
  key-map 없이 "0 또는 1"만 다루는 가벼운 편의 메소드, 상세 설계 미착수.

**같은 세션 후속 — `bindLifetime`/`unbindLifetime`이 실제로 뭘 하는지,
`canBound`(이중 바인딩 금지)와의 관계를 여러 차례 시행착오 끝에 정확히
확정.** `Dispatch.setLength`가 이전 Observer 등록을 정리할 때 뭘 불러야
하는지를 두고 제가 세 번 틀렸다가 사용자가 매번 정정 — 경위와 최종
결론을 구분해서 기록:

1. **1차 시도(틀림)**: `unbindLifetime`이 `canExecute`를 즉시 `false`로
   만들어준다고 서술 — 틀림. `gchold`(순수 GC 방지용 강참조 테이블)는
   `canExecute`가 보는 값(Observer/Effect의 `.Subscribed`, 또는 `inst`의
   공유 `gcconn.Connected`) 어디에도 안 들어감, 완전히 무관한 테이블.
2. **2차 시도(틀림)**: 그래서 "`unbindLifetime`은 필요 없고 `:Unsubscribe()`
   만 쓰면 된다"로 후퇴 — 이것도 틀림. 사용자 정정: `:Subscribe()`/
   `:Unsubscribe()`는 **`inst`와 아예 무관한 전역/독립** Observer(모듈
   최상위 디버그 print 등, leaf도 없고 특정 Instance에도 안 묶인 경우)를
   GC로부터 지키기 위한 **전역** 강참조 테이블(`SubscribedObservers[observer]
   = true/nil`)일 뿐 — `Dispatch.setLength`의 Observer처럼 처음부터
   `inst` 하나에 종속된 내부 배관에는 원래부터 안 맞는 도구. "`inst`
   연관은 전부 `bindLifetime`/`unbindLifetime`으로"가 맞는 원칙.
3. **최종 확정**: 진짜 독립된 라이프사이클 경로는 **`:Subscribe()`(전역)
   와 `bindLifetime`(inst-scoped) 둘뿐** — "children 배열 leaf 부착"은
   세 번째 경로가 아니라 **`bindLifetime` 호출 그 자체**(`Dispatch/
   Leaf.luau`가 Observer/Effect leaf를 매치하면 그 자리에서
   `bindLifetime(inst, v)`를 호출), 이걸 제가 처음에 "leaf 부착/
   `:Subscribe()`/`bindLifetime` 셋 다 상호 배타"로 잘못 일반화했다가
   사용자가 "leaf 부착 자체가 bindLifetime을 호출하는 거라 동일 동작,
   상호배타는 아니다"로 정정. `canBound`의 내부 플래그도 새 필드가
   아니라 **`canExecute`가 이미 보는 `.Subscribed` 그 자체** —
   `bindLifetime`/`unbindLifetime`도(Observer/Effect 값에 한해) 이
   필드를 세팅/해제해야 `bindLifetime`으로 등록된 Observer가
   `canExecute`에서 정상적으로 "살아있음"으로 인식됨. Effect는 내부적으로
   Observer를 조합하므로 이 확장을 몰라도 자동으로 커버(사용자 확인).
4. **부수 정리**: 이미 확정돼 있던 StoreBind의 자기 재실행 Observer
   예제(`observer:Subscribe()`)도 같은 이유로 틀렸던 것이었음 확인 —
   `bindLifetime`/`unbindLifetime`으로 교체. "`:Unsubscribe()`는 자동
   (리프) 케이스에도 동일하게 씀"이라던 기존 서술도 같은 이유로 정정
   (리프/`bindLifetime` 경로의 조기 해제는 `unbindLifetime` 전용,
   `:Unsubscribe()`는 `inst`를 몰라 대신 처리 못 함).

전부 `base/bind-system-plan.md`(신규 "Length/Offset" 절, "이중 바인딩
금지" 절 정정 — 2-way로 재확정, StoreBind 예제 교체)/`base/slot-plan.md`
(열린 질문 해소, `Slot.Length` 절, `:Single` 백로그 절)/`base/
lifecycle-pattern.md`(`unbindLifetime` 추가 + `canBound`/`.Subscribed`
연동 반영)/`ROADMAP.md`(M2/M3/M6)/`.claude/question.md` 반영 완료.

**다음 세션이 할 일**: 안 바뀜(`ROADMAP.md` M0부터) — 이번 세션도 순수
설계 확정이라 M0 착수 우선순위 자체는 그대로.

