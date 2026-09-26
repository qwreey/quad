# E51 — `Tag` 참조 카운트 × `Attr` 이름 소유권 참조 모델 차등 퍼저 (2026-09-27, round13 자율 루프)

레포 파일 무변경. CLI `luau` + quad-base mock provider(`installTagAttrOps(q, log)` 관측 재설치), 설치본 한 벌
(`quad-roblox/luau_packages` — `typing-limits.md` 8.34). `relink.sh` 뒤 `.pesde/…/quad_base/src`와 작업 트리
`quad-base/src`가 `diff -r` 동일함을 확인. 퍼저는 mock op를 감싸 로그 줄마다 인스턴스를 붙인다(Quad0002/0016으로
오염된 인스턴스의 줄은 비교에서 빼고 "zombie"로 센다).

## 파일

| 파일 | 역할 |
|---|---|
| `harness.luau` | 프롤로그 — `Quad.New()` + `mock.mockProvider` + `installTagAttrOps(q, log)` |
| `rng.luau` | 결정적 PRNG(E48 사본) |
| `fuzz.luau` | 메인 차등 퍼저 — `luau fuzz.luau <seeds> <start> [v] [nc] [m1..m4]` (`nc` = 충돌 없는 모드, `mN` = 모델 결함 주입) |
| `axes.luau` | 별도 축 (a)~(g) → `out-axes.txt` |
| `probe-*.luau` | 사전 탐색(None/nil, 충돌 뒤 상태, 엔진 거부 뒤 잠김) → `out-probe-*.txt` |
| `out-fuzz-*.txt`, `out-mutants.txt` | 실행 결과 |

## 모델 규칙

| # | 규칙 | 정본 | 코드 |
|---|---|---|---|
| R1 | 자리에 Tag → 이름마다 위치 +1, 0→1인 이름만 모아 `addTag` 한 번 | core/09:53, GS05:70-79 | Tag.luau:285-299 |
| R2 | 물러남 → −1, 1→0인 이름만 모아 `removeTag` 한 번 | core/09:53 | Tag.luau:306-327 |
| R3 | 같은 불변 Tag 객체 두 자리 = 두 번 셈 | core/09:53 | Tag.luau:266-268 |
| R4 | `State<Tag>` 교체는 집합 차이만, 같은 집합이면 호출 0 | core/09:55, GS05:113-125 | Tag.luau:307-313 |
| R5 | 같은 객체 재발행은 순수 스킵 | tag-plan "메커니즘" | Tag.luau:303 |
| R6 | 자리 값 nil/None/Attr로 전환 → 전량 떼기 | spec.tag §3, E16 | Dispatch 핸들러 교체 |
| R7 | 이름 문 셋·인자 nil 건너뜀·`Merged` 합집합·`:Added/:Removed(nil)` | core/09:70-78·109·130·207 | Tag.luau:143-231 |
| R8 | 한 전이 안에서 `removeTag`가 `addTag`보다 먼저 | tag-plan, Dispatch retractor→process | Tag.luau:300 |
| R9 | 속성 이름당 주인 하나, 둘째 주인은 `Quad0002` | core/09:380, errors/05:18 | Key.luau:413-419 |
| R10 | 같은 그룹 객체 두 자리 → `Quad0016`(이름 claim 전) | core/09:282 | Attr/init.luau:258-263 |
| R11 | 물러나는 주인은 이름만 반납, 엔진 값 유지 | core/09:248, GS05:199 | Key.luau:424-430 |
| R12 | 값/State의 `nil`·`None` → `setAttr(name, nil)` | core/09:243-245 | Key.luau:422 |
| R13 | 새 그룹 객체는 이름마다 무조건 `setAttr`, 같은 객체 재발행은 0 | attribute-plan `H-154` | Attr/init.luau:271-277 |
| R14 | AttrKey 값 State는 같은 값 재Set에도 `setAttr`(중복 제거 없음) | Key.luau 헤더 "unconditional" | Key.luau:422 |
| R15 | 생성자·`Overridden`은 뒤 인자 승, `NumberAttr`은 한 항목 그룹 | core/09:272·339-354 | Attr/init.luau:150-184 |
| R16 | 파괴된 인스턴스는 뒤이은 Set에 엔진 호출 0 | E16 | 수명 해제 |
| R17 | 그룹 위임 중 충돌 → NameMap `pairs` 순서상 앞 이름들은 쓰이고 던짐 | attribute-plan `H-684` | Attr/init.luau:275-277 |

## 결과

- 충돌 모드 20000 시드(1~20000, 801,681 스텝, Quad0002 15,171·Quad0016 519 예측 전부 일치, 오염 인스턴스 zombie 줄 4,708) **차등 0**.
- 충돌 없는 모드(`nc`) 20000 시드(801,681 스텝, 파괴 27,746) **차등 0**.
- 모델 결함 주입 넷(m1 참조 카운트 무시, m2 생존 이름 무시, m3 그룹 재발행 스킵 없음, m4 AttrKey 주인 무시) 전부 검출.
- 축: `out-axes.txt` — 요지는 메인 원장 보고(E51) 참조.
