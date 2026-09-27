# E75 — 에러 레퍼런스 "고치려면" 처방 실측 (2026-09-27, HEAD `00349a0f`)

대상은 `docs/reference/errors/*.md`의 `### QuadNNNN` 절 248개다. E28이 메시지 원문과 "언제"를 대조했으므로, 이 탐사는 **"고치려면"**만 본다. 절마다 두 가지를 했다. 먼저 mock 위에서 그 id를 정확히 내는 가장 작은 프로그램(trigger)을 돌렸다. 다음으로 같은 프로그램에 처방을 글자 그대로 적용한 판(fix)을 돌려, 에러가 사라지는지와 사용자가 원했을 동작이 실제로 되는지를 확인했다.

레포 파일은 바꾸지 않았다. 이 폴더가 산출물 전부다. 그룹 A·B·C는 opus 서브에이전트가, D·E·F는 메인이 직접 실측했다. 브리프는 `scripts/subagent-brief.md`에 있다.

## 파일

| 파일 | 내용 |
|---|---|
| `harness.luau`·`engine-globals.luau` | E70 하네스 사본(변경 없음): mock 백엔드와 실 quad-roblox 프로바이더, `D` |
| `runner.luau` | `R.case{id, trigger, fix}` — `@@E75 id TRIG=… 메시지 FIX=… 설명` 한 줄씩 출력 |
| `cases/A.luau` | 01-core-reactive + 09-sugar (서브에이전트) |
| `cases/B.luau`·`B_probe.luau`·`B_probe2.luau` | 02-dispatch-bookkeeping (서브에이전트) |
| `cases/C.luau` | 03-slot (서브에이전트) |
| `cases/D.luau`·`D_probe.luau`·`D_probe2.luau` | 04-ref-observer-effect |
| `cases/E.luau` | 05-tag-attr + 06-module-backend |
| `cases/F.luau`·`F_iso_version.luau` | 07-roblox + 08-roblox-tween (`Quad0228`은 버전을 바꾼 새 모듈을 따로 만들어 돌림) |
| `cases/smoke.luau` | 러너 확인용 (`Quad0145`) |
| `out/<그룹>.txt` | 각 케이스 파일의 실행 출력 |
| `out/A-notes.md`·`B-notes.md`·`C-notes.md`·`DEF-notes.md` | 그룹별 id 표, 발견 문단, 개수 |
| `scripts/anchors.py` → `out/anchors.txt` | 280개 링크 전부에 대해 파일과 헤딩 slug가 실재하는지 검사 |

실행 방법: 레포 루트에서 `mise exec -- luau .claude/audit/round13-e75-error-prescriptions/cases/<파일>.luau`. `./scripts/relink.sh`를 한 번 먼저 돌려야 한다.

## 개수

| 페이지 | 섹션 | 시도 | 정확 | 불충분 | 틀림 | 미도달 |
|---|---|---|---|---|---|---|
| 01-core-reactive | 46 | 45 | 43 | 2 (0037, 0044) | 0 | 1 (0192) |
| 02-dispatch-bookkeeping | 44 | 44 | 40 | 4 (0022, 0071, 0076, 0083) | 0 | 0 |
| 03-slot | 47 | 46 | 42 | 4 (0156, 0167, 0172, 0179) | 0 | 1 (0164) |
| 04-ref-observer-effect | 34 | 32 | 30 | 2 (0093, 0115) | 0 | 2 (0098, 0117) |
| 05-tag-attr | 26 | 24 | 22 | 2 (0016, 0237) | 0 | 2 (0004, 0009) |
| 06-module-backend | 25 | 25 | 25 | 0 | 0 | 0 |
| 07-roblox | 13 | 13 | 13 | 0 | 0 | 0 |
| 08-roblox-tween | 11 | 11 | 11 | 0 | 0 | 0 |
| 09-sugar | 2 | 2 | 2 | 0 | 0 | 0 |
| **합계** | **248** | **242** | **228** | **14** | **0** | **6** |

"틀림"(처방이 에러를 없애지 못하거나 없는 API를 가리킴)은 0건이다. 불충분의 뜻은 둘 중 하나다. 처방을 따르면 다른 에러로 바뀌거나, 에러는 사라지지만 원한 동작이 안 된다. 또는 페이지가 적은 갈래 가운데 일부에서 처방을 따를 수 없다.

## 발견 — 본문은 그룹 노트, 여기는 요지

- **처방을 따르면 다른 에러가 나는 것**:
  - `Quad0016`: 처방대로 새 `q.Attr`를 둘 만들면 `Quad0002`가 난다.
  - `Quad0022`: `setLength`만으로 등록하면 `Quad0023`이 난다.
  - `Quad0076`: `Store`를 숫자 키로 옮기면 같은 `0076`이 다시 난다.
  - `Quad0083`: 페이지의 예시 `D.Frame { q.Source(1) }`이 `Quad0076`을 낸다.
  - `Quad0156`: 두 키 변형에서 처방대로 `Extract`하면 `Quad0166`이 난다.
  - `Quad0167`: "Observer에서"가 마운트 중 발화하는 Observer이면 같은 `0167`이 다시 난다.
  - `Quad0172`/`0160`: 정적 자식에 `Parent = nil`을 해도 같은 에러가 난다. 뺄 공개 경로가 없다.
  - `Quad0179`: 숫자 키에 앉은 owner Slot을 dispose하면 같은 `0179`가 난다.
- **에러는 사라지지만 원한 동작이 안 되는 것**:
  - `Quad0093`/`0115`: 자리에 묶인 핸들은 `:WeakUnsubscribe()`가 조용히 통과할 뿐 아무것도 풀지 않는다.
  - `Quad0237`: `q.Tag(state)`의 반응형 의도로 가는 길을 안내하지 않는다.
  - `Quad0037`: 이미 `:Set`한 값을 지우는 경우를 다루지 않는다.
  - `Quad0044`: 팩토리를 공유하는 경우 새 Ref만으로는 효과가 없다.
- **처방이 없는데 공개 API로 닿는 것**: `Quad0071`. 사용자 핸들러가 같은 자리에 재진입할 때(UB로 확정된 부류) 도달한다. E28은 정적 대조만 했었다.
- **깨진 참고 앵커**: `Quad0182`(01-core-reactive.md:248)의 `#qsourcevalue`. 실제 앵커는 `#qsourcev`다.
- **메시지와 처방 불일치**: `Quad0108` 런타임 꼬리가 아직 `; tests use mock.installLifetime`이다(`quad-base/src/LifetimeHandle.luau:79`). 페이지 처방은 `H-745`에서 고쳐졌다.
- **blame이 quad 내부에 떨어지는 것**: `Quad0023`·`0024`·`0071`(`error(msg, 1)`), `Quad0123`의 Tag·Modifier 경로. 모두 E28이 이미 추적한 것이다. 나머지 도달 id는 전부 사용자 줄에 떨어진다.

## 확인만 한 것

E28이 지적했고 `H-745`로 고쳐진 처방을 현재 문구로 다시 재서 전부 동작함을 확인했다: `0048`, `0055`, `0089`/`0091`/`0111`/`0114`의 승격·강등, 죽은 핸들 여섯, `0108`의 페이지 쪽, `0141`, `0149`, `0168`, `0169`/`0242`, `0179` 꼬리, `0220`, `0226` 경로.

그 밖에 확인한 것:
- 07·08의 24개 처방 전부. 트윈 목표는 mock `tweenLog`에서 확인했다.
- `0228`의 버전 범위 서술을 `matchesPattern`으로 대조했다.
- 06의 `Claim`·수명·모듈 처방 25개 전부.

세부는 그룹 노트의 "확인만" 절에 있다.

## 미완

- 미도달 6개: `0004`·`0009`·`0098`·`0117`은 E28 판정(도달 경로 없음)을 그대로 따랐다. `0164`·`0192`는 공개 경로를 찾지 못했다.
- 실기기(Studio) 실측은 하지 않았다. 전부 mock이다. 특히 둘은 엔진 동작 확인이 필요하다: `D.Frame { outer }`가 마운트 중에 던진 뒤 호스트가 어떻게 되는지(`0167`), 정적 자식에 `Parent = nil`을 했을 때(`0172`).
- `0123`의 Tag·Modifier fix 두 갈래는 판정하지 않았다. 원래 의도가 State 없이는 성립하지 않는다.
