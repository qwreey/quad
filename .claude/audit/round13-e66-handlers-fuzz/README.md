# E66 — quad-roblox 핸들러 다섯의 연결·프로퍼티 쓰기 부기 차등 퍼저 (2026-09-27)

대상: `quad-roblox/src/Handlers/{Event,OnChange,InstanceChild,InstanceShorthand,Property}.luau` + `EngineOps.luau`를
"(인스턴스, 자리)마다 살아 있는 엔진 연결 수·쓰기 기록" 문제로 본다. 하네스는 E64 `env.luau`의 `prov` 모드 사본
(`Quad.New()` + 실 `QuadRoblox` 프로바이더를 mock 심 위에; 설치 한 벌 `quad-roblox/luau_packages/quad_base`,
typing-limits 8.34). 연결 수는 mock 시그널의 `connections` 표를 직접 읽는다(mock 무변경). `relink.sh` 뒤 레포 루트에서
`mise exec -- luau <파일>`. 레포 파일 무변경.

| 파일 | 내용 |
|---|---|
| `env.luau` | E64 env 사본 + `TextButton`에 `MouseButton1Click`, Reflection 심에 `UIScale`/`UICorner` |
| `rng.luau` | E64와 같은 xorshift |
| `fuzz.luau` | 참조 모델 M1~M10(머리 주석에 각 규칙의 문서·코드 줄) + 무작위 연산 |
| `out-fuzz-1-25000.txt` | 시드 1~25000 — 차등 0 |
| `out-mutants.txt` | 모델 변이 여섯의 검출 |
| `axes.luau` / `out-axes.txt` | 축 (a)~(k), (g2) |
| `perf.luau` / `out-perf.txt` | 자리 종류별 emit당 비용 |

## 퍼저

인스턴스 `TextButton` 2~3개 × 자리 일곱(`Activated`·`MouseEnter` 이벤트, `Text` 프로퍼티, `UIScale` 숏핸드, 숫자 키
1·2 = `OnChange` 디스크립터(`Text`/`Visible`), 숫자 키 3 = 정적 자식(인스턴스마다 전용 Frame 둘)). 값: 새 함수·기존
함수(같은 fn 재발행)·`nil`·`q.None`·비함수 `5`(→ `Quad0218`)·도메인별 `Source`(이벤트용 둘·디스크립터용 둘·Text·Scale·
자식용 — 한 Source가 여러 인스턴스 자리에 동시에 묶임). 연산: 직접 `q.Dispatch.process(inst,k,v,1)`, `retractFrom(inst,k,1)`,
`Source:Set`, 이벤트 `Fire`, 밖에서 `inst.Text/Visible` 대입, 인스턴스 `Destroy`, 죽은 자리에 `D.TextButton(props)` 재생성
(숫자 키·문자 키 섞은 props — 배열부 먼저). 스텝마다 대조: 이벤트별 연결 수와 연결된 함수의 신원, 재처리마다 **새** 연결
객체인지(같은 fn이어도), `GetPropertyChangedSignal(Name)`의 연결 수 = 그 이름 디스크립터를 쥔 자리 수, 콜백 로그(누가 어떤
값으로 불렸나 — 다중집합), 자식 집합·`Parent`·파괴 여부, 관리 자식 `_quad_scale` 존재와 `Scale`, `Text` 쓰기 횟수(원시 카운터
연결로)와 값. 파괴된 인스턴스는 연결 0, 이후 `Set`이 아무 데도 닿지 않음. 시드 끝에 전부 파괴하고 한 번 더 `Set`.

**결과**: 시드 25,000 · 연산 약 100만(process 35.7만·Set 28.7만·retract 10.7만·Fire 8.9만·밖 대입 7.1만·Destroy 3.6만·
재생성 2.7만) · 모델 차등 0. 예상 에러는 `Quad0218` 3,976회 전부 모델이 먼저 말한 자리.

**검출력**(시드 2000, 차등 시드 수): `evdedup`(같은 fn 재발행 시 연결 유지) 384, `retractkeeps`(retract가 이벤트 연결을
남김) 556, `shdestroy`(숏핸드 retract가 관리 자식 파괴) 304, `propdedup`(같은 값 프로퍼티 쓰기 생략) 279, `evnilkeeps`
(`nil`/`None`이 옛 연결을 남김) 672, `hashfirst`(drive가 문자 키 먼저) 452.

## 축 요약(`out-axes.txt`)

- (a) 이벤트 콜백이 던지면 mock은 그 에러를 `Fire` 부른 쪽으로 올리고(blame은 사용자 줄) 같은 스냅숏의 나머지 리스너를
  건너뛴다; 연결은 남아 다음 `Fire`도 던진다. `OnChange` 콜백이 `Property` 쓰기 안에서 던지면 `s:Set`이 던지고 값은 이미
  써져 있으며, 다음 `Set`은 정상 — 엔진은 리스너 에러를 올리지 않으므로 mock 전용 경로(아래 발견 2).
- (b) 콜백이 자기를 몰고 있는 State를 `Set`: 발화 중 교체는 다음 `Fire`부터 반영(스냅숏), 연결은 늘 1; 자기를 `nil`로 → 0.
- (c) Destroy 뒤 `Set` → 연결 0(StoreBind 수명 해제); 콜백 안에서 자기 인스턴스를 Destroy하고 `Set` → 무에러·0. 파괴된
  인스턴스에 직접 `q.Dispatch.process`하면 Event는 새 연결(엔진 d7과 같은 "영원히 Connected"), OnChange 연결, Property 대입,
  숏핸드는 시체 밑에 새 관리 자식을 만든다(발견 3).
- (d) 되먹임: 가드 있는 clamp(`if c ~= v then s:Set(c)`)는 mock(동기)에서 같은 키 재진입을 거쳐 수렴(ZIndex 5, 콜백 3회).
  가드 없는 되쓰기 `function(v) s:Set(v) end`는 mock에서 `C stack overflow`(blame `OnChange.luau:130` 클로저) — 엔진은 같은 값
  재대입에 신호가 없어 한 번 메아리 뒤 멈춘다(발견 1). `q.Out` 바인드+타이핑 추가 emit 0. Out + Compute 두 프로퍼티 연쇄 정상.
- (e) 1000회 교체(State 경로·직접 process·OnChange State 스왑) 뒤 연결 1, 옛 콜백 클로저는 GC로 전부 수거(업밸류 있는
  클로저로 측정 — 업밸류 없는 클로저는 Luau가 한 객체로 캐시해 "1000개 생존"으로 잘못 보인다), retract 뒤 0, 그 뒤 `Set`은 재연결 안 함.
- (f) 클래스에 없는 이벤트 → `Quad0076`(nil이면 nil 꼬리 힌트), 호출 가능 테이블 → `Quad0218`, `None` → 연결 0.
- (g) 앉아 있는 정적 자식을 밖에서 Destroy한 뒤 스왑·retract·dispose: mock 무에러. (g2) Parent 잠금 변형 두 가지 — "시체의 모든
  Parent 대입이 던짐"이면 `InstanceChild.luau:89`(`v.Parent = nil`)가 매번 던져 자리가 굳지만, **Studio 실측된 엔진 동작은
  "시체에 `Parent = nil`은 조용히 통과, 살아 있는 부모로만 잠김"**(`.claude/base/lifecycle-pattern.md` 986행, round11 H′)이고
  그 변형에서는 전부 통과 — 결함 아님.
- (h) 밖에서 다른 부모로 옮긴 정적 자식을 같은 값으로 재발행하면 `H-154` dedup이라 되돌아오지 않고, 이어 `Set(nil)`하면 quad가
  남의 부모에서 떼어 낸다(계약 밖 — Q5 (a)와 같은 결).
- (i) 프로퍼티 평값은 같은 값도 emit마다 쓴다(1,1,2,2 → 4회). 숏핸드도 emit마다 `Scale` 쓰기, `nil`이면 관리 자식 파괴 후 새로 만듦.
- (j) 파괴 뒤 `Out` 연결 0, 시체에 쓰기는 Source에 안 닿음.
- (k) 같은 디스크립터 값을 두 자리에 → 연결 2·발화 2(Instance와 달리 한 값 한 자리 규칙 없음 — 문서의 "같은 이름 두 번"과 일치).

## 성능(`out-perf.txt`, mock, 상대 모양만)

`Source:Set` 단독 0.13µs; 프로퍼티 1.6µs(같은 값도 같음 — dedup 없음); 이벤트 1.8µs(Disconnect+Connect); OnChange 스왑 3.4µs;
정적 자식 스왑 4.9µs, 같은 자식 재발행 1.9µs(dedup); 숏핸드 값 2.3µs, `nil`↔값 토글 8.5µs(매번 관리 자식 파괴·`Declaration.New`
재생성). 한 시그널에 형제 연결 1000개면 OnChange 스왑 7.7µs(mock `Disconnect`의 `table.find` O(k) — 엔진 비용과 무관).

## 확인만 한 것

M1~M10 전부(퍼저 차등 0), 축 (b)(c)(e)(f)(i)(j)(k), (g2)의 실측 변형, `q.Out` 메아리 0, drive의 배열부 먼저(초기값 발화).

## 미완

- 엔진 Deferred 배달 변형은 만들지 않았다 — 퍼저의 콜백 로그 대조가 동기 배달을 전제한다.
- Studio 미연결(2026-09-27 `list_roblox_studios` 빈 목록) — 엔진에서 "리스너 에러가 다른 리스너·쓰기 쪽에 영향 없음"(발견 2의
  전제)과 `GetPropertyChangedSignal`에 이벤트 이름을 줄 때의 문구는 기억 근거이고 이번에 실측하지 않았다.
- `Slot` 원소가 밖에서 파괴된 경우의 `nativeExtract`/`nativeRemove`는 이번 범위 밖(E1·Q9 (b) UB).
- UICorner/UIPadding 숏핸드는 퍼저에 넣지 않았다(UIScale만; 공유 자식은 E2-2가 다룸).

## 발견(평문)

1. **[LOW, 문서]** `docs/reference/roblox/05-onchange.md` 187행의 충돌 이름 여섯 우회 `q.OnChange(name, function(v) src:Set(v) end)`에는
   같은 페이지 12행 우회와 167행 설명이 필요하다고 말하는 값 비교 가드(`if v ~= src:Get() then`)가 없다. 엔진에서는 바인드와 외부
   변경마다 `src`의 구독자가 한 번씩 더 도는 메아리가 생기고(167행이 `q.Out`이 막는다고 설명하는 바로 그것), 문서가 헤드리스 검사로
   권하는 mock에서는 같은 값 대입도 신호를 쏘므로 `Set → Property 쓰기 → 신호 → Set`이 끝나지 않아 `C stack overflow`
   (`OnChange.luau:130` 클로저 blame, 축 (d) d2). 곁: 시작하기 06(`docs/getting-started/06-flowing-back.md` 11행)은 그 가드를
   "값 비교로 왕복을 끊는 부분"이라 부르는데 05 167행은 "왕복을 끊기 위해서가 아닙니다 — 메아리"라고 한다. 187행에 가드를 넣고
   06의 이유 문구를 05와 맞추면 된다.
2. **[LOW, mock 충실도 — Q120 계열, E29 표에 없는 행]** mock `Signal:Fire`(`quad-base/test/mock.luau` 82~91행)는 리스너가 던지면 그
   에러를 `Fire`를 부른 쪽(= 프로퍼티를 쓴 쪽)으로 올리고 남은 리스너를 건너뛴다. 엔진은 리스너마다 따로 돌려 에러를 출력 창에만
   남긴다(기억 근거 — 미실측). 결과: mock에서 `OnChange` 콜백이 던지면 `Property.luau` 336행 `inst[k] = v`가 던진 것이 되어
   `Source:Set`이 던지고, 그 Property 자리는 `H-103` NOOP 표식으로 남아 retractor를 잃는다(평값은 무해; 트윈 체인이면 철거 때
   Cancel이 안 불림). 엔진에서는 나지 않는 상태를 spec이 단언할 수 있다는 뜻이고, 지금 그 경로를 타는 spec이 있는지는 세지 않았다.
3. **[LOW, 문서/계약]** 파괴된 인스턴스에 공개 `q.Dispatch.process`(또는 `drive`)를 부르면 다섯 핸들러 모두 조용히 동작한다 —
   Event는 영원히 `Connected`인 연결을(엔진 d7 실측과 같음), OnChange도 연결을, 숏핸드는 시체 밑에 새 관리 자식을 만든다(축 (c)).
   `Dispatch/init.luau`의 `process` 입구에는 생존 게이트가 없고, `docs/reference/extend/02-dispatch-handler-contract.md` 385행은 Destroy
   때 retractor가 안 불린다는 것만 적는다. 사용자 코드가 StoreBind로는 닿지 않으므로(수명 해제 확인) 확장 작성자만의 경로다.
   갈래: (a) extend/02 "한계와 주의"에 "파괴된 요소에 process/drive는 UB" 한 줄 / (b) `process` 입구에 `isClaimed` 게이트(새 raise
   자리 — 사용자 결정) / (c) 그대로.
