# E64 — `q.Dispatch` 핸들러 계약 참조 모델 차등 퍼저 (2026-09-27)

하네스 한 벌: `quad-roblox/luau_packages/quad_base`(typing-limits 8.34). 두 설치 모드 —
`base`(= `Quad.New()` + mock 백엔드, 내장 핸들러 19개만) / `prov`(= `Quad.New()` + 실 `QuadRoblox`
프로바이더를 mock 심 위에, 내장 24개 — Property/Event/InstanceShorthand/InstanceChild/OnChange 포함).
`relink.sh` 뒤 레포 루트에서 실행. 레포 파일 무변경.

| 파일 | 내용 |
|---|---|
| `env.luau` | 두 모드의 새 모듈 인스턴스 생성기(시드마다 새 레지스트리) |
| `fuzz.luau` | 참조 모델 R1~R15(머리 주석이 각 규칙의 문서·코드 줄) + 무작위 사용자 핸들러 2~8개 × 자리(인스턴스 2 × 키 9) × 연산 20~60 |
| `out-fuzz-*.txt` | base 1~30000, prov 1~20000 — 차등 0 |
| `out-mutants.txt` | 모델 변이 넷의 검출(아래) |
| `axes.luau` / `out-axes.txt` | 축 (a) 동률 (b) 내장과의 경쟁 (c) `retractFrom` index (d) `process` 반환값 (e') retractor throw (f) `addHandler` 게이트 (h) 백엔드 없음 |
| `axis-g-storebind-throw.luau` | StoreBind 등록 발화·후속 발화에서 던질 때 옵서버의 생사 |
| `axis-i-nilhint.luau` | `Quad0076` nil 꼬리(extend/02:165) |
| `perf.luau` / `out-perf.txt` | 핸들러 0/50/200 × 자리 1000 |
| `p0-list.luau` / `out-p0-list.txt` | 두 모드의 레지스트리 덤프 |

## 퍼저

사용자 핸들러: priority ∈ {HIGH+1, HIGH, NORMAL±1, NORMAL, LOW, FALLBACK, FALLBACK-1, 500, 7}(동률 다수 — 내장과의
동률 포함), `keyType` ∈ {nil,"string","number"}(술어의 키 가드와 어긋나게 선언된 것 포함), 술어 14종(값 타입·kind·
tag·키 이름·nil·None·전부 등) 하나 또는 둘의 OR, 래퍼(값 `W(x)`를 벗겨 `process(…, index+1)`)/잎, `BOOM` 값에
`process`가 던짐(위임 전/후), `EVIL` 값에 `isHandlable`이 던짐, 일부는 같은 테이블 재등록. 연산: 직접 `process`(index
1 / #chain+1 / #chain+2 / 중간 깊이; 값에 nil·None·State 포함), `retractFrom`(index 1 또는 1..#chain+2), State `:Set`,
`drive`(배열 부분 + 해시 부분). 스텝마다 사용자 `process`/retractor 호출 로그(핸들러·키·값·index·retractor 신원·
`nextValue`·`retracting`)와 에러 ID를 모델과 전부 대조, 시드 끝에 전 자리 철거 로그 대조, prov는 Property 자리의 최종
값도 대조.

**결과**: 규칙 15 · 시드 50,000(base 30,000 + prov 20,000) · 연산 약 200만 · 사용자 `process` 약 100만 · 모델 차등 0.
예상 에러(모델이 먼저 말한 것): `Quad0076` 44만·`Quad0075` 4.5만·`Quad0218`(Event) 3만·사용자 던짐 6만 전부 같은 ID·같은 자리.

**검출력**(시드 2000, 차등 시드 수 base/prov): `noA`(같은 핸들러도 늘 교체) 1579/1533, `retractHead`(얕은 층부터 철거)
976/974, `noNoop`(던진 뒤 표식 없이 비움) 151/119, `stable`(동률 = 등록 순서) 319/483 — 마지막은 "동률은 등록 순서로
풀린다"는 가정이 실제와 16~24% 시드에서 어긋난다는 뜻(아래 (c)1).

## 축 요약

- (a) 동률: 같은 등록 순서면 매번 같다(a1, 결정적 — `table.sort` 결정성). 그러나 **등록 순서가 아니다**(a3 top 동률 47회 중
  먼저 등록된 쪽 승 26회=55%), 그리고 **무관한 priority의 핸들러가 나중에 하나 등록될 때마다 기존 동률 순서가 다시
  섞인다**(a2: U1..U6 동률의 순서가 무관 등록 다섯 번에 여섯 가지). debug 진단은 둘째 핸들러 등록 순간에 한 줄(첫 동률
  상대만)이고 그 뒤 재배열은 알리지 않는다; 등록 뒤에 `q.debug`를 켜면 0줄(a4).
- (b) 내장과의 경쟁: HIGH+1 사용자 핸들러는 문자 키의 Ref(반영 이름 `Size` 포함)를 Property·가드보다 먼저 잡는다(b1 —
  Q135 자리를 사용자/플러그인이 스스로 막을 수 있음). HIGH+1로 `None`·State를 잡으면 NoneHandler/StoreBind가 가려져 언랩이
  사라진다(b3·b4, 열린 숫자 공간 그대로). 정확히 NORMAL(Property와 동률)·FALLBACK(가드와 동률)은 이번 설치에서 내장이
  이겼으나 미정의(b2·b5). LOW 핸들러는 반영 키에 영원히 안 닿는다(Property가 nil 포함 모든 값을 잡음, b6).
- (c) `retractFrom` index는 체인 깊이(배열 자리 아님, c9) — `(…, 2)`는 깊이 2..꼬리만 철거하고 깊이 1 래퍼는 남는다(c2),
  꼬리 밖 index는 no-op(c4), 0·1.5는 `Quad0073`, 체인 없는 키는 조용히 통과(c7).
- (d) `process` 반환값: nil만 `Quad0077`. 아래 (b)1.
- (e) 성능: 핸들러 50개(미선언)면 문자 키 연산당 0.92→1.68µs, 200개 4.38µs(선형 스캔); 50개를 `keyType="number"`로
  선언하면 문자 키 비용은 0개와 같다(0.89µs). `addHandler` 200회 5.3ms(매번 정렬+버킷 재구성). drive 1000 배열 자리 3.2→4.4ms.
- (g) StoreBind 등록 발화가 던지면 옵서버는 묶이지 않아 이후 `:Set`이 아무 데도 안 닿는다(유령 없음); 후속 발화에서
  던지면(`Quad0076`) 체인은 그대로·옵서버는 살아 다음 `:Set`에 회복(g3).
- (h) 백엔드 없는 `Quad.New()`: `getHandler`는 동작, `process`는 `Quad0108`.
- `addProcessedHandler`는 공개 표면이 아니다(`Dispatch/None.luau` 내부 공장 — `q`·`q.Dispatch`·docs 어디에도 없음); 만드는
  셋(`Processed*`)은 HIGH·keyType nil로 레지스트리에 보인다(`out-p0-list.txt`).

## 발견

- (a)1 `docs/quadnomicon/08-extensible-dispatch-engine.md:92` FALLBACK 행 "동적 경로로 온 `Ref`/`Observer`/`Effect`를 즉시
  거부하는 가드 셋" — 실제 가드는 여섯(`Ref`·`PreRef`·`PostRef`·`Observer`·`Effect`·`Slot` DynamicPathGuard, `out-p0-list.txt`).
- (a)2 extend/02 "한계와 주의"(379~385)는 `process`가 던지는 경우만 적고 retractor가 던지는 경우를 적지 않는다 — 그 슬롯은
  비워지지 않아(`init.luau:240` 호출이 `list[i] = nil`보다 먼저) 이후 그 키의 철거·교체가 매번 같은 retractor를 다시 불러 다시
  던지고, 얕은 층(래퍼)은 영영 철거되지 않는다(`axes` e1~e3). 계약(architecture "예외 안전성 계약")상 UB 부류.
- (b)1 `process`가 nil 아닌 비함수(true·5·{})를 돌려주면 `Quad0077` 게이트(`init.luau:356`·`372`, `== nil`만 봄)를 지나 저장되고,
  그 자리의 다음 재처리(`:353`)·철거(`:240`)에서 번호 없는 `attempt to call a boolean value`가 quad 내부 줄 blame으로 나며, 슬롯이
  안 비워져 이후 철거마다 반복된다(`axes` (d)). 문서(extend/02:39·167, errors/02 `Quad0077` "언제"/"고치려면")는 "retractor를
  돌려주지 않았을 때"·"항상 함수를"이라 적는다. `__call` 테이블은 통과·정상 동작(반면 `addHandler`는 `isHandlable`/`process`의
  `__call` 테이블을 `Quad0079`로 거부).
- (c)1 동률 순서는 "미정의"라고만 적혀 있지만(extend/02:96·383) 실제로는 "한 번 정해지면 고정"도 아니다 — 무관한 priority의
  핸들러 등록 하나로 기존 동률 둘의 승자가 바뀔 수 있다(a2). 문서에 "이후 등록으로도 바뀔 수 있음"을 적을지.
- (c)2 조건부 위임 래퍼: 같은 핸들러가 재처리하며 이번엔 위임하지 않으면 깊은 층이 살아 남는다(`axes` c8 — 깊이 2 잎 7이 최종
  철거까지 유지). extend/02:66 "아래 층을 건드리지 않습니다"와 일치하나, 래퍼 작성자가 이 경우 `retractFrom(inst, k, index + 1)`을
  직접 불러야 한다는 안내가 없다. 문서화할지 UB로 둘지.
