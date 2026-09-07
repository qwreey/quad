# M10 잔여(InstanceShorthand) 자율 구현 — 20라운드 발견 원장

> **[2026-09-06 신설]** 규약은 `m10-shorthand-implementation-round20-brief.md`
> (§0 권고 (a)로 착수 — 사용자 결정). 세 갈래는 M11 규약 준용. 번호는 `H-335`부터.
> **상태의 소스는 이 파일의 표.**

## 요약 표

| ID | 갈래 | 심각도 | 무엇 | 처리 |
|---|---|---|---|---|
| `H-335` | ① | 🟢 | **[단위 ① — `UIPadding`/`UIPaddingOffset`은 관리 자식을 공유]** 정본(과 v1)대로 둘 다 `_quad_padding` 하나에 위임하므로 한 인스턴스에 둘을 같이 쓰면 같은 `(child, PaddingX)` 체인(index 1)을 두 키가 번갈아 process해 **나중 것이 이기고**, 어느 한 키를 `nil`로 내리면 공유 자식이 파괴된다(다른 키의 값도 사라짐). v1도 같았고 두 키를 동시에 쓸 이유가 없어(같은 뜻의 두 표기) 그대로 둔다 — 문서화 대상 캐비엇 | ✅ 핸들러 헤더·spec 5절. 정본 "메커니즘" 절에 각주 |
| `H-336` | ① | 🟢 | **[단위 ② — 생성기]** 숏핸드 키 넷을 GuiObject 계열(자기 또는 조상에 `GuiObject` — 스코프 31클래스 중 10)의 `<Class>Param`과 `<Class>Modifier` setter에 실프로퍼티와 같은 값 유니언(`PVn`, 타입 `number \| UDim`/`UDim`/`number`)으로 얹었다. `PropTypes`/OnChange엔 넣지 않음(실프로퍼티가 아님). 상위 클래스 Modifier(`GuiObjectModifier`)에도 메소드가 실린다 | ✅ `gen-d.py`, `spec.shorthandtypes`(양성), 음성 5/5(스크래치) |
| `H-337` | ① | 🟡 | **[단위 ② — 체커 한도]** 키 넷 × 10클래스만으로 `export type D`(UIStroke 자리)가 "too complex" — `LuauTarjanChildLimit`·`LuauTypeInferIterationLimit` 상향 무효, **`LuauSolverConstraintLimit`(기본값 작음)이 이 증상을 푼다**(100만으로 핀, 1.9s). 8.8절이 "올리면 지점만 옮겨감"이라 적은 건 재귀 메소드 테이블 유니언(M7 ③) 때 얘기 — 증상별로 듣는 한도가 다르다 | ✅ `scripts/test.sh` 플래그 넷째, typing-limits 8.5절 보강 |

## §4 배치 회신 대기 (② 갈래)

**열린 문항 0, 확인 항목 1**:
- 확인 — 숏핸드 `isHandlable`은 키만 본다(대상 클래스 검사 없음): non-GuiObject에 `UICorner`를 넣으면(타입을 우회한 무타입·직접 `Dispatch.process`) 조용히 `_quad_round` 자식을 만든다 — **UB로 문서화**(타입이 1차 방어, 런타임은 무해; 2차 리뷰 `H-342` ④). `inst:IsA("GuiObject")` 검사를 넣으려면 mock 주입면이 하나 늘어난다 — 원하시면 그때.
