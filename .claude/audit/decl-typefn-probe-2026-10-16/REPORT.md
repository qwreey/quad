# 결과 — Declaration 타입 함수 조립 첫 실측 (2026-10-16, CLI·LSP 하네스 — Studio·VSCode는 사용자 몫, `README.md`)

opus 서브에이전트가 만들고 돌렸다(보고 본문을 메인이 요약해 저장). 결정이 아니라 재료다 — 정할 것은 `research/declaration-surface-plan.md` 4·5절.

**환경 재구성(실측).** 사용자 VSCode = code-server의 luau-lsp 확장 1.70.1, `--no-flags-enabled` + 확장 globalStorage defs. 확장 `dist/extension.js`의 플래그 동기 로직을 옮겨(PCStudioApp `Luau` 키 633개, 2026-10-16) 네 모드로 돌렸다:
`vsc`(확장 1.70.1 + 동기 + 워크스페이스 한도 override = 사용자 VSCode), `sync`(override 없음 — Roblox 동기값 그대로), `pin`/`pinsync`(레포 핀 1.69.0 + `scripts/roblox-defs`). 하네스 `harness/lspc.py`는 stdio JSON-RPC로 completion·hover·진단을 받는다.
`src/Lib.luau`는 디스패처 타입 함수 `Build<Mode, C, Policy>` 하나가 클래스 체인을 걸으며 모든 축을 만들고, 체커 차이는 생성기 분기가 아니라 `Policy` 데이터(Deny·DenyIn·Inject)로 넣었다.

1. **`New<<Frame>>("Frame")`(괄호 없는 `New<<TextLabel>> "TextLabel"` 포함)** — 됨: 클래스 이름 싱글턴 검사, 중괄호 안 프로퍼티·이벤트 자동완성(Frame 62), 값 진단은 생성 D와 같은 자리·같은 뜻, 읽기 전용·Studio 전용 이름 거부(생성 D와 같은 두 건짜리 에러), 상속 이름. 약함: 주석만으로는 C가 안 채워짐(명시 `<<C>>` 필수), `Props<GuiObject>` 값을 하위 생성자에 못 넘김(배열부 인덱서 불변 — 상위 공통은 Spread·Modifier 마커로만), 추상 클래스 `New<<GuiObject>>`를 못 막음, **hover가 별칭 이름 없이 구조 전체로 전개**(생성 D는 이름이 남음).
2. **`Modifier<<C>>()`** — 메소드 자동완성(Frame 40), 값·키 진단, 태그 유지, `types.generic` 제네릭 메소드가 체인 뒤에도 동작(`m:Peek<<UDim2>>` → `UDim2?`), 상위 Modifier는 하위 요소에 들어가고 형제는 거부. 약함: detail·hover가 재귀 전개로 김, 생성 `FrameModifier`와 양방향 대입 불가(공존은 요소 자리 마커로만). `As*`/`Into`/`Overridden`·숏핸드 setter는 미측정.
3. **`Spread<<C>>({...})` → `SpreadMarker<C>`** — 만드는 자리 자동완성(63)·진단이 `New`와 같고 결과는 `{ read __quadSpread: "Frame" }`, 자기·조상 마커만 배열부 통과, 안쪽 Spread 가능(하위 묶음을 상위에 넣으면 거부), 팩토리 `Hoverable(...): SpreadMarker<GuiObject>`가 Frame·TextButton 양쪽에 들어감. 겹치는 키는 런타임 몫.
4. **`OnEvent(name, fn)`** — 이름 자동완성(49, 클래스 무관), 오타 진단, 놓이는 자리에서 클래스 소속 대조(Spread 안이면 Spread의 C로 거름), 클래스를 아는 변형 `OnEventIn<<Frame>>(…)`·`OnEventFor<<Frame>>()`(Frame 이벤트 26으로 좁힘). **가장 중요한 안 되는 것: 무주석 콜백 인자가 문맥 타입을 못 받는다**(`OnEvent("MouseEnter", function(x, y) end)`의 x = `unknown`, 고정 인자 수 변형도 같음). **지금의 생성 `OnChangeFn`도 같다**고 보고(1.70.1·1.69.0 모두 `v`가 unknown — `base/typing-limits.md` 8.7 3번과 어긋남, 메인 미확인). 되는 꼴은 **커리 `OnEventC("MouseEnter")(function(x, y) … end)`** — x가 number, `input.` 자동완성 64.
5. **체커 차이 흡수(사용자 가설)** — 두 defs에서 정책 적용 뒤 Frame 등 개수 일치, 31 클래스 키 집합이 생성 D `<Class>Param`과 글자까지 같은 것이 vsc 28/31·pin 29/31. 남은 차이는 전부 **API 버전 차이**(defs가 덤프보다 새것/오래됨) — 예외 데이터로 못 메움(타입 함수 표면은 사용자 체커를, 생성 D는 덤프를 따름). 발견: Object까지 걸어야 `Changed`, 오버로드 메소드(intersection)는 걸러야 함, **멤버 하나가 `parameters()`에서 죽으면 표면 전체가 never**(타입 함수 안엔 pcall 없음, 8.18).
6. **비용** — (a) 파일 위에 한 번 만드는 타입 함수 꼴: 20 → 930 호출 0.48 → 0.77 s, 79 → 200 MiB, `sync`에서도 too complex 0. (b) 생성 D: 0.86 → 1.19 s, **`sync`(override 없는 실사용자 환경)에서 too complex 6건·NEG 0/2, `D.Frame({` 자동완성 0, hover `*error-type*`** — 8.28의 실사용자판 재현(사용자 VSCode는 override가 있어 괜찮음). (c) 호출마다 `L.New<<C>>`를 인스턴스화: 620 호출 too complex, 930 호출 2.8~3.07 GiB에서 예산 정지 → 파일 위에 한 번 만드는 꼴이 사실상 강제.

**미완**: Studio·VSCode 관측 전부, 숏핸드·`As`/`Into`의 타입 함수화, Q87·Q127, 생성 D `Apply` hover 직접 대조, 930 호출 이상의 인라인 꼴.
