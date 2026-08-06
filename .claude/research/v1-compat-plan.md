# v1 하위호환(compat) 레이어 타당성 검토

**상태**: research — 신규 조사(2026-08-06 세션, 사용자 질문으로 착수). 설계
확정 아님, "얇은 래퍼가 가능한가"에 대한 타당성 평가만 담음.

**배경**: 사용자가 "quad v1에 대한 하위호환 레이어를 v2가 얇은 래퍼로 제공할
수 있을지" 질문. 폐기된 재작성 시도 `quad2-try`에 `quad-compat`이라는
서브패키지가 있어서 "이미 한 번 시도했다 실패한 것"으로 짐작했으나, 조사
결과 아래처럼 사실이 아니었음 — 완전히 새로 검토할 만한 주제.

## 1. 선행 조사: quad2-try의 `quad-compat`은 실제로 시도된 적 없음

`base/bind-system-plan.md:715`에서 quad2-try의 서브패키지 9개(`quad-docs`,
`quad-debug`, `quad-compat`, `quad-2`, `quad-roblox`, `quad-lang`, `quad-gtk`,
`quad-core` 등)를 나열하며 "`quad-core` 밖엔 참고할 게 없다"고 기록돼있는데,
직접 확인한 결과 `out/quad-compat/`은 **파일이 0개인 완전히 빈 디렉토리**.
compat.lua나 어댑터 코드는 전혀 없고, README/커밋 메시지에도 "왜 포기했는지"
단서가 없음 — 애초에 착수된 적이 없다는 뜻.

→ `question.md:110`이 "OOP 상속/커스텀 파서/Slot 스텁/`Pipe` COW는 확인된
죽은 접근"이라고 명시한 목록에 compat은 **포함돼 있지 않음**(정확한 서술).
즉 CLAUDE.md의 "반복 조사 금지"는 compat에는 적용되지 않는다 — 이 문서를
쓰는 게 규칙 위반이 아님.

## 2. v1 공개 API 표면 — 두 계층으로 나뉨

v1(`.claude/initreq/quad/src`) 조사 결과, API는 성격이 다른 두 계층으로
나뉜다:

**(a) 표면 문법** — 개별 함수/헬퍼로 비교적 독립적:
- 이벤트 핸들러가 첫 인자로 `self`(or `this`)를 받는 관습(`event.lua:81-83`)
- 프로퍼티 테이블의 특수 키(`RoundSize`/`Corner`/`PaddingAll`/`Scale`,
  `class.lua:134-213`)
- `target()`(정확히는 컴포넌트 내부 `self("이름")` 호출)을 통한 named
  child 등록 + 시그널 중계(Linker, `class.lua:112-131,352-358,511-521`) —
  **정정(2026-08-06)**: 최초 조사 때 "양방향 바인딩"으로 잘못 서술했음.
  실제로는 데이터 동기화가 아니라, Linker 값을 숫자 키(자식 위치)에 놓으면
  생성된 자식을 `target[name]`에 한 번 등록(`Link`의 `indexType=="number"`
  분기, `rawset`)하고, 문자열 키(이벤트 값)에 놓으면 자식 이벤트 발생마다
  `target:GetPropertyChangedSignal(name)`을 대신 Fire하는 시그널 중계일
  뿐 — "이름 있는 자식 참조 등록"에 더 가까움.
- `store.GetObjects("a,b&c")` 쿼리 문법의 오브젝트 태그 저장소(`store.lua:103-190`)

**(b) 핵심 런타임** — v1 컴포넌트 모델 그 자체:
- `Class.Extend()`가 반환하는 단일 메타테이블이 상속 체인을 대신 (`class.lua:361`)
- 인스턴스화 시 생성자 인자를 자동으로 store로 감싸고(`class.lua:367`),
  이후 `comp.Text = "hi"`처럼 프로퍼티를 재대입하면 `__newindex`가 자동으로
  내부 store에 위임 + `UpdateTriggers`에 걸리면 자동 재렌더까지 발생
  (`class.lua:524-566`) — CLAUDE.md에 이미 "이 자동 위임/재렌더 매직은
  v2에서 폐기하기로 확정"이라 기록된 바로 그 메커니즘.

## 3. 계층별 실현 가능성

### 3-1. (a)는 얇게 재현 가능 — opt-in 서브패키지로 격리하면 근거 문제도 해소됨

- **이벤트 self 관습**: 클로저 한 겹으로 재현 가능. `base/bind-system-plan.md`
  "이벤트 핸들러는 self를 받지 않는다" 절이 든 반대 근거 4가지(Ref 중복
  채널, Modifier 정적 flatten과 경쟁, quad-debug 추적 밖 mutate 경로, 클로저
  비용)는 **코어에 넣을 때** 문제가 되는 것들 — 별도 opt-in 패키지
  (`quad-compat` 부활)로 격리하면 비용은 compat 사용자만 부담하고 코어 KV
  핸들러 분기도 안 생김. 단, "quad-debug 추적 밖 mutate 경로가 생긴다"는
  근거(4번)는 격리해도 남는 문제라 별도 검토 필요.
- **RoundSize 등 특수 키**: `Corner`/`PaddingAll`/`Scale`은 이미
  `research/ui-shorthand-plan.md`에서 네이티브 포팅 확정됨 — 별도 compat
  작업 불필요. `RoundSize`(이미지 9-slice 라운드 트릭)만 UICorner 없던
  시절 워크어라운드라 재현 자체가 불필요하다고 이미 결론남.
- **`target()`/Linker**: 위 정정대로 "이름 있는 자식 등록 + 시그널 중계"일
  뿐이라, v2 쪽에서 굳이 흉내낼 이유가 약함 — v2엔 이미 Ref가 있고(컴포넌트
  경계로 참조를 넘기는 표준 경로), 시그널 중계는 아래 4번 브리지 메커니즘이
  흡수함.
- **오브젝트 태그 조회**: v2엔 대응 개념이 아예 없음 — `CollectionService`
  태그로 유사 구현은 가능하나 새 서브시스템에 가까워 "얇다"고 하기 애매.

### 3-2. (b)는 얇게 안 됨 — 컴포넌트 정체성 모델 자체가 충돌

`Class.Extend()` 자동-store 위임 + 자동 재렌더는 v1 컴포넌트 작성 경험의
본질인데, v2는 정확히 이 매직("자기 store 자동 소유")을 이미 폐기하기로
확정한 상태(`base/component-composition-plan.md` §1, 사용자 확정 발언
"마법 안쓴다 그것도 동의함"). 이유는 이름 문제가 아니라 **컴포넌트
정체성을 다르게 정의**하기 때문:

- v1: 컴포넌트는 렌더 후에도 "살아있는 오브젝트"로 남아 `.Text = ...`
  재대입을 전제 — mutate 기반.
- v2: 반응형 소스(Store/State)를 갈아끼우는 방식, 컴포넌트는 "특정 상태의
  store를 받는 함수"(`architecture.md`) — 만들어진 후의 컴포넌트 인스턴스를
  밖에서 mutate하는 접점 자체가 없음.

이 격차를 메우려면 compat 레이어가 컴포넌트마다 "가짜 OOP 인스턴스"를
만들어 내부적으로 v2 Store/State를 대신 조작해주는 shim을 새로 설계해야
함 — 몇 줄짜리 어댑터가 아니라 사실상 v1 런타임을 v2 위에 재구현하는 것.
참고 사례로 Vue 2→3의 `@vue/compat`이 있으나, 그것도 별도 빌드 모드 +
다수의 호환 플래그 + 성능 오버헤드 경고가 딸린 규모라 "얇다"고 부르기
어려움.

## 4. 사용자 제안 — v1/v2 병행 사용 + 경계 리졸브 브리지 (2026-08-06 후속, 유력 방향)

사용자가 3-2의 "얇게 안 됨" 결론에 대한 대안으로 제시한 방향: v1 런타임을
v2 위에 재현하려 하지 말고, **v1을 그대로, 수정 없이 계속 돌리면서** v2와
병행 사용하고, 두 시스템의 경계(v2가 만든 반응형 값을 v1 쪽에 넘겨야 하는
지점)에서만 작은 브리지를 둔다는 아이디어. 검토 결과 **이쪽이 3-1/3-2보다
분명히 나은 방향** — 아래 근거.

### 왜 이게 작동하는가

1. **구조적 합성은 이미 공짜** — `architecture.md:11,18`의 DOMless 원칙상
   v1/v2 둘 다 렌더 결과가 그냥 평범한 Roblox Instance라, v1이 만든
   Instance를 v2 트리 안에 자식으로 두거나 그 반대나 특별한 어댑터 없이
   Roblox 부모-자식 관계만으로 합성됨. 3-2가 문제 삼은 "컴포넌트 정체성
   충돌"은 **v1 컴포넌트 자체를 v2로 재구성하려 할 때만** 발생하는 문제고,
   "v1 컴포넌트를 그대로 두고 옆에 놓기"에는 애초에 적용되지 않음.
2. **v2→v1 값 전달(사용자가 든 예시)도 이미 있는 재료로 충분히 얇음**:
   - v2 쪽: `state:Observer()`를 인자 없이 호출하면 "이 State를 계속
     능동 관측 상태로 유지"하는 유틸로 동작(`base/bind-system-plan.md:441`)
     — 이걸로 lazy를 포기하고 항상 최신값이 계산되게 강제하는 부분이 이미
     설계돼 있음. 사용자가 말한 "포기하고 전부 관측된 값으로" 정확히 이 API.
   - v1 쪽: 만들어진 v1 인스턴스에 `instance.Text = value`처럼 그냥
     재대입하면 v1의 진짜 공개 API(`class.lua:543-566`의 `__newindex`)를
     타고 v1 자신의 업데이트 파이프라인(`UpdateTriggers`, 재렌더)이 정상
     작동함 — v1 내부를 뜯어 흉내낼 필요 없이 v1이 원래 하던 일을 밖에서
     호출만 하는 것.
   - 합치면: `state:Observer(function() v1Instance.Text = state:Get() end)`
     한 줄 수준의 브리지로 "v2 State가 바뀔 때마다 v1 인스턴스 프로퍼티에
     써주기"가 됨 — 3-2에서 우려한 "v1 런타임 재구현"이 전혀 필요 없음.
3. **정반대 방향(v1→v2)도 필요하다면 대칭적으로 얇음(미검증, 방향성만)**:
   v1은 `GetPropertyChangedSignal`/`EmitPropertyChangedSignal`
   (`class.lua:407-437`)을 이미 공개 API로 노출하므로, 그 시그널을 구독해서
   매번 v2 `Source:Set()`(또는 clone 불가 값이면 `:Emit()`)을 호출해주는
   것도 같은 패턴 — 다만 사용자가 예시로 든 건 v2→v1 한 방향뿐이라, 실제로
   양방향이 필요한지는 아래 열린 질문으로 남김.
4. **경계 코드의 라이프사이클 정리도 새로 설계할 필요 없음** — 브리지용
   Observer 구독을 v1 인스턴스(진짜 Roblox Instance)의 `Destroying`에
   묶으면 됨, 이미 채택된 rbvm `Connected`+GC 관용구(`base/
   lifecycle-pattern.md`)를 그대로 재사용.

### 3-1(문법 설탕 compat)과의 관계

이 방향은 3-1의 "이벤트 self 관습, 프로퍼티 특수 키" 같은 **v1 쪽 표현을
v2 문법으로 흉내내는 작업 자체를 없앰** — v1 코드는 그냥 v1 문법 그대로
남아있고, v2는 v1을 흉내낼 필요가 없음. 즉 "compat 레이어가 v1처럼 보이게
만드는" 문제가 "v1이 원래 하던 일을 그대로 하게 두고 데이터만 새 파이프로
갈아끼우는" 훨씬 좁은 문제로 축소됨.

## 5. 결론 / 권장

- **1순위(신규 권장)**: 4번의 "병행 사용 + 경계 리졸브 브리지" — v1을
  그대로 두고 v2와 나란히 돌리되, 반응형 값이 경계를 넘는 지점만 각 쪽의
  기존 공개 API(v2 `state:Observer()`, v1 프로퍼티 재대입/시그널)로 잇는
  얇은 글루 코드. 3-2가 지적한 "컴포넌트 정체성 모델 충돌"을 재구현이
  아니라 회피로 해결 — 사실상 strangler-fig식 점진 마이그레이션 패턴.
- **2순위(보조)**: 3-1의 문법 설탕 어댑터(이벤트 self 등) — 위 1순위로
  충분하다면 불필요할 수 있음, "v1 문법 자체를 v2 컴포넌트 함수 안에서
  쓰고 싶다"는 별도 니즈가 있을 때만 검토.
- **"v1 코드를 완전히 무수정으로 v2 런타임 위에서 돌리는 것"(3-2, OOP
  mutate 재구현)은 여전히 비권장** — 1순위 방향이 그 문제 자체를 안 만들기
  때문에 불필요.

## 6. 확정된 것 (2026-08-06 후속 라운드)

- **방향: v2→v1 단방향만.** 4번 3항목의 v1→v2(시그널 구독 → `Source:Set()`)
  방향은 사용자가 "필요성 모르겠다"고 확정 — 설계 범위에서 제외. 굳이
  대칭성 때문에 만들 필요 없음.
- **패키지명: `quad-roblox-v1-compat`.** `quad-compat`처럼 엔진 무관을
  가장하는 이름 대신, v1 자체가 애초에 Roblox 전용이라(quad가 엔진 무관화에
  실패한 전례가 있다는 사용자 확인) 이 브리지도 처음부터 `quad-roblox`
  계열의 Roblox 전용 패키지로 이름 붙임 — `quad-base`/`quad-roblox` 확정
  트리에 세 번째로 추가되는 패키지.
- **번역 경계 원칙 확정**: v1의 원시 타입(Linker, v1 store의
  `registerClass` 객체, `Class.Extend().New()`가 만드는 `this` OOP
  인스턴스)이 v2 코드 쪽으로 그대로 흘러들어가지 않고, v2의 원시 타입
  (Source/State/Store/Modifier/Ref)도 v1 코드 쪽으로 흘러들어가지 않는다
  — `quad-roblox-v1-compat`의 공개 표면은 오직 (a) 리졸브된 평범한 값과
  (b) Roblox Instance만 주고받는다. 두 런타임의 내부 핸들 타입이 서로의
  영역을 침범하지 않는 게 핵심 — 아래 7번의 구체적 규칙들이 전부 이 원칙의
  적용.

## 7. 기술 계획 — 두 임베딩 방향 + Slot 조사 결과 (2026-08-06 후속)

v1/v2를 병행 사용할 때 실제로 쓰이는 모양은 두 가지다: (A) 신규로 짜는
v2 트리 안에 과거 v1 컴포넌트를 리프로 박아넣는 것, (B) 기존 v1 앱 안의
요소를 하나씩 v2로 교체하는 것. 둘 다 지원 가능한지 v1 `mount.lua`/
`class.lua`와 v2 `base/slot-plan.md`를 대조 조사했다.

### 7-1. (A) v2 트리 안에 v1 컴포넌트를 리프로 박기

제안: `quad-roblox-v1-compat`에 `EmbedV1(v1ClassOrFactory, propsBuilder)`류
어댑터 — v1 컴포넌트를 생성하고 루트 Instance를 v2 Slot/`InstanceChild`가
받을 수 있는 leaf 값으로 반환. 내부에 흘려줄 v2 State는 4번에서 확정한
`state:Observer()` 브리지로 v1 인스턴스 프로퍼티에 재대입.

- **근거**: v1의 `mount()`(`mount.lua:49-87`)는 부모-자식 관계에 소유권
  검사가 전혀 없음(누가 만든 Instance든 그냥 Parent 세팅 + `__child`
  등록) — v2가 v1이 만든 루트 Instance를 자기 Slot에 끼우는 것 자체는
  막힘 없음.
- **위험 + 제안 규칙**: v1의 `mountClass:Unmount()`(`mount.lua:21-46`)는
  `this`가 Instance면 무조건 `this:Destroy()`를 직접 호출함. 반대로 v2
  Slot의 retract(교체) "폐기" 시맨틱이 quad가 안 만든(v1이 만든) foreign
  Instance에 대해 뭘 하는지는 `slot-plan.md`에 명시가 없음(7-2 참고).
  **→ v2 Slot이 `EmbedV1` 결과물을 폐기할 때 절대 직접 `:Destroy()`를
  부르지 말고, 반드시 `EmbedV1`이 반환한 핸들의 v1 쪽 정식 `Unmount()`를
  거치게 한다** — 이게 6번 "번역 경계 원칙"의 구체적 적용 하나.

### 7-2. (B) v1 트리 안 요소를 하나씩 v2로 교체

제안: `quad-roblox-v1-compat`에 `EmbedV2(v2Component, props)`류 반대쪽
어댑터 — v2 컴포넌트를 렌더한 루트 Instance를 v1 prop 테이블의 숫자 키
자식으로 그냥 꽂을 수 있는 값으로 반환.

- **위험 1 — 재렌더 시 파괴**: v1의 `Update()`(`class.lua:452-491`)는
  루트 Instance를 파괴 후 재생성하되, `__child`에 정식 등록된(=`mount()`/
  `mountfunc` 경로를 거친) 자식만 새 루트로 재부모 지정하고, 그 외(직접
  `.Parent=` 대입 등)는 옛 루트와 함께 파괴됨. **→ `EmbedV2` 결과물은
  반드시 v1의 정식 children 경로(prop 테이블의 숫자 키)로만 붙여야 함,
  `.Parent=` 직접 대입 금지.**
- **위험 2 — Clone 함정**: `ProcessQuadProperty`(`class.lua:209-212`)는
  같은 prop 테이블이 여러 인스턴스 생성 호출에 걸쳐 재사용되면(첫 번째
  인자, `iprop==1`이 아닌 경우) 그 안의 자식 Instance를 통째로 `Clone()`함
  — v2 루트가 Clone되면 원본과 반응형 그래프 연결이 끊긴 죽은 복제본이
  생김. **→ `EmbedV2` 결과물은 절대 공유/캐시된 prop 테이블(`Import`의
  defaultProperties, 재사용 style 테이블 등)에 넣지 말고, 매번 새로 만드는
  최초(iprop==1) prop 테이블에만 넣도록 문서화** — 가능하면 구현 시점에
  Clone 감지 가드(예: 복제 발생 시 error) 추가 검토.
- **거저 얻는 이득 — 파괴 방향은 이미 맞물림**: v1은 자기가 파괴될 때
  children을 순회하며 개별 Destroy하지 않고 Roblox 엔진의 cascading
  destroy에 의존함(`class.lua:494-508`에 순회 로직 없음, 확인 완료). v2의
  라이프사이클은 이미 `Destroying` 훅 기반 GC-native 패턴
  (`base/lifecycle-pattern.md`)이라 "누가 파괴를 트리거했든 Destroying만
  감지하면 됨" — v1이 자기 루트를 Destroy()해서 안에 박힌 v2 서브트리가
  cascading으로 같이 파괴돼도 v2 쪽 정리가 별도 브리지 코드 없이 자동으로
  맞물림.

### 7-3. Slot — 조사했지만 완전히 못 푼 부분 (사용자가 예상한 대로)

- `base/slot-plan.md`엔 "엄격한 단일 마운트 소유권"(`isMounted` 관리,
  재마운트 시 즉시 `error()`)은 확정돼 있지만, **Slot이 이미 만들어진
  임의 Instance를 동적 배열 원소로 받을 수 있는지, 아니면 그건 별도
  `InstanceChild`(정적 단일 삽입) 핸들러 전용인지가 문서에 명시 안 됨.**
  `EmbedV1`의 반환값을 v2 쪽에서 Slot(동적 배열)에 넣을 수 있는지
  `InstanceChild`(정적 단일)로만 넣을 수 있는지는 실제 Dispatch/Slot
  구현 시점에 가서야 확인 가능.
- Slot의 retract "폐기"가 quad가 안 만든 Instance에 대해 정확히 뭘 하는지
  (그냥 `:Destroy()`인지, 다른 처리인지)도 문서 밖 — 7-1에서 제안한
  "직접 Destroy 금지, Unmount 경유" 규칙을 Dispatch 엔진의 어느 지점에
  훅으로 강제할지도 Slot 실제 구현 시점 확인 필요.
- **결론: 지금 결정 불가.** M0 이후 Slot 코어 로직 구현 라운드
  (`question.md`의 "여러 Slot이 형제로 섞일 때 순서 보장" 항목과 같은
  시점)에서 이 두 가지를 실제 구현과 함께 재확인해야 함.

## 8. 남은 확인 사항 (추가 리서치 후보, 지금 결정 불필요)

- v1이 자기 루트 Instance의 `Destroying`(또는 유사 신호)을 듣고 Lua측
  부기(`store.AddObject` 태그 레지스트리 등)를 스스로 청소하는 경로가
  있는지 미확인 — 7-1의 "v2가 v1 임베딩을 Destroy 대신 Unmount 경유해서
  정리하라"는 규칙이 얼마나 엄격히 지켜져야 하는지가 여기 달림(v1이
  Destroying만 들어도 알아서 청소한다면 직접 Destroy해도 무방해질 수
  있음).
- v1 store의 `registerClass` 체이닝 기능(`:Tween`/`:Default` 등)까지
  브리지가 흡수해야 하는 케이스가 있는지 — 단순 프로퍼티 재대입만으로
  충분한 범위인지 실사용 예시로 확인 필요.
- (2순위 문법 설탕 어댑터를 실제 채택할 경우) 이벤트 self 관습을 compat에서
  되살릴 때, `base/bind-system-plan.md`가 명시한 반대 근거 4번(quad-debug
  추적 밖 mutate 경로)을 어떻게 처리할지 — quad-debug는 어차피 후순위라
  지금 결정 불필요할 수도 있음.

## 착수 시점

지금 당장 설계/착수 불필요 — `CLAUDE.md` "지금 할 일" 1번(구현 착수,
ROADMAP M0)이 최우선. 7-3의 Slot 관련 두 항목은 M0 이후 Slot 구현
라운드에서 실제 코드와 함께 재확인해야 풀림 — 그 전까진 이 문서의 제안
(7-1/7-2 규칙들)이 최선의 추정치.
