# quad v1 내부 구조 (재작성 이전 기준선)

**상태**: reference — 온디맨드 참고 자료, "완료" 개념 없음. **[2026-08-07
문서 정리에서 `base/`→`reference/`로 이동]** v1 자체에 대한 스냅샷일 뿐 v2의
결정 사항이 아니라서 항상 읽어야 하는 base 컨텍스트는 아님 — 다른 문서가
"v1은 이랬는데"를 인용할 때만 열어볼 것. v2 설계 시 "이 문제를 안 반복하려면"의
기준선으로 근거 인용되는 용도는 그대로 유지(각 인용 지점은 여전히
`base/`에 있음, 이 문서는 그 인용의 원본 소스). 아래는 리서치 에이전트가
file:line까지 확인한 내용의 요약 — 정확한 인용이 필요하면
`.claude/initreq/quad/src/*.lua` 원본을 볼 것.

## 공개 API 개요

```lua
local Quad = require(path).Init(QuadId?)   -- id 생략 시 격리된 인스턴스
local Class, Store, Mount, Event, Style, Signal, Lang, Tween = Quad.Class, ...

local Frame = Class "Frame"
Frame {
  Name = "Wow!";
  Frame { Name = "Child" };                     -- [1] = child
  [Event "Activated"] = function(self,...) end; -- 이벤트 바인드 키
  BackgroundColor3 = myStore "color";            -- store 바인드
  myStyle;                                       -- style 오브젝트도 숫자 키로
}
Mount(ScreenGui, Frame {...})
```

`Class.Extend()`로 재사용 컴포넌트(`Init/Render/AfterRender/Getter/Setter/
UpdateTriggers/Unload`) 정의 가능. `Store.GetObject(id)`류 id 기반 전역 조회는
v2에서 대체될 예정 — Ref 도입과 네임스페이싱 판단까지 포함해 최신 상세는
`base/architecture.md` 5번 항목 참고.

## 핵심 내부 동작 요약

- **`class.lua`의 `ProcessQuadProperty`**(하드코딩된 if/elseif 디스패처)가 사실상
  전체 "키 핸들러"임 — 숫자 키(children/style), `quad_register`/`quad_linker`/
  `quad_style` 같은 `__type` 문자열 태그가 붙은 테이블, 그리고 `"Event::"` 접두
  문자열 세 가지를 런타임 `typeof`/`type` sniffing으로 구분. 새 특수 키를
  추가하려면 이 중앙 함수 자체를 고쳐야 함 — **v2가 pluggable bind 시스템을
  원하는 직접적인 이유**.
- **`store.lua`의 register 체이닝이 바로 사용자가 "별로였다"고 한 metatable
  체이닝**: `:With`/`:Add`/`:Tween`/`:Default` 각각이 이전 register를 `__index`로
  가리키는 새 1-필드 테이블을 만드는 방식 — 매 호출마다 테이블+메타테이블 할당,
  같은 메서드 두 번 호출하면 마지막 것만 남음(합성 안 됨), `Register`/`Observe`는
  반대로 루트 스토어를 직접 mutate — 일관성 없는 순수/불순 혼합.
- **정리(cleanup)에 대한 통일된 모델이 없음** — 여러 곳에서 각자
  `PropertyChangedSignal("ClassName")`에 연결해 참조를 붙잡아두는 "GC 방지 핫팩"이
  중복 등장(`class.lua`에 2곳, `lang.lua`에 1곳). 대칭되는 해제(dispose) 경로가
  없어서 weak table GC에만 의존. `Uninit(id)`도 실제 파괴 없이 참조만 끊는 스텁.
- **`mount.lua`는 실제로 부모/자식 부기(bookkeeping) + 라이프사이클 파괴까지
  담당하는 무거운 모듈**(`rawget/rawset`로 Extend 내부 필드를 직접 건드림) —
  사용자 원 메모의 "이전 quad는 mount가 별다른 행동 안 함"은 더 오래된 스냅샷
  기준일 가능성.
- **`event.lua`는 이벤트 연결 후 해제(disconnect) 추적이 전혀 없음** — fire-and-forget.
  `signal.lua`는 완전 커스텀 Signal 구현체(Roblox BindableEvent 미사용)이지만
  class.lua/mount.lua의 정리 경로에 연결되어 있지 않음.
- **`style.lua`는 이름 매칭(문자열 패턴) 기반, 선언 순서 의존적** — 실행 순서가
  꼬이면 스타일이 안 먹는 문서화된 함정.
- **`tracker.lua`는 실제로 `exports.lua`에서 require조차 안 되는 죽은 코드** —
  Rojo 트리(`DescendantAdded`/`.Changed`) 변경을 감지해 debounce 후 "updated"를
  쏘는 핫리로드 감시자였지만 현재 공개 API에 연결 안 됨. v2는 아예 구현 안 하기로
  이미 결정됨(스토리북 라이브러리가 대체, `base/architecture.md` 참고).
- **`lang.lua`의 로케일 상태(`CurrentLocale`/`langList`)가 module-local 전역이라
  `Quad.Init(id)`의 id 스코프를 무시함** — Store/Style은 id별로 스코프되는데 Lang만
  전역 공유, 일관성 없는 스코핑. v2는 lang 모듈 자체를 분리해서 안 만들기로 결정됨.
- **문자열 DSL(`"a,b"`, `"a&amp;b,c"` 같은 콤마/앰퍼샌드 파싱)로 구현된 구조적 기능**들이
  주석 처리된 죽은 코드(`__newIndex` 대문자 오타로 절대 안 불리는 메타메소드 등)와
  섞여 있어 신뢰도가 낮음.

## v2가 명시적으로 피하려는 것 (이 문서에서 근거로 인용)

1. Metatable 체이닝으로 "불변 빌더" 흉내내기 → 대신 팩토리 함수로 필요한 곳만 복사
   (`raw-userinput.md` "복사 구현은 지양" 항목, `.claude/initreq/raw-userinput.md:83-86`).
2. 하드코딩된 중앙 디스패처 → pluggable `isHandlable(key,value)` + 우선순위 핸들러
   레지스트리 (`base/dispatch-core-plan.md`).
3. 흩어진 "GC 안 되게 참조 붙잡기" 핫팩 → rbvm 스타일 `Connected` 계산 속성 +
   명시적 라이프타임 홀더 (`base/lifecycle-pattern.md`).
4. mount가 여러 책임(부모 부기+파괴+child 레지스트리)을 한 모듈에 다 지는 구조 →
   Slot이 child CRUD를 전담, mount는 단일-마운트 강제만 전담
   (`base/slot-plan.md`).
5. tracker.lua, lang.lua 내장 → 둘 다 라이브러리 범위 밖으로 분리(스토리북/
   외부 로케일 라이브러리에 위임).

## 열려 있는 확인 사항

**[해소됨, 2026-08-13]** `objectListClass.__newIndex`(오타, 항상 미발동)로
문서화됐던 "GetObjects() 리스트에 일괄 프로퍼티 설정" 기능 — 사용자가 당시
실수였음을 확인. v2는 오브젝트에 id를 주입하고 id로 조회하는 개념
(`GetObjects`류) 자체가 없어져 이 기능의 재현 여부와 무관하게 v2
마이그레이션 가이드에서 다룰 대상이 아님(있었다 해도 v1 전용 기능) — 재현
테스트 불필요, 더 이상 열려있는 항목 아님.
