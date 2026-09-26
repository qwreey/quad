# E28 — 에러 레퍼런스(`docs/reference/errors/*.md`) ↔ raise 자리 전수 대조 (2026-09-27, HEAD `4b461ba4`)

레포 파일 무변경. 이 폴더가 산출물 전부다.

## 방법

1. `scripts/patch.py` — 레포 사본(스크래치)의 `*/src`·`luau_packages/**/src` 모든 모듈 머리에 `error` 지역 래퍼를 끼워, `QuadNNNN`이 든 메시지를 던질 때마다 `@@QERR\t<원문>`을 찍게 한다(레벨은 +1 보정). quad-error의 `errorBefore`류도 내부적으로 `error`를 부르므로 같이 잡힌다.
2. 사본에서 스모크·spec 전부(quad-base 43 + quad-roblox 20)를 돌려 `out/spec-capture.txt`(565줄)를 얻었다 — spec 전부 exit 0.
3. spec이 안 낸 id는 `triggers/e28trig_*.luau`(메인)와 `triggers/e28probe_{A..F}_*.luau`(그룹별 opus 서브에이전트, 브리프 `scripts/subagent-brief.md`)로 직접 트리거 → `out/trig-capture.txt`, 사람이 읽을 결과는 `out/trigger-results.txt`·`out/probe-results.txt`. 트리거 스크립트는 **패치된 사본의 `quad-base/test/`(또는 `quad-roblox/test/`)에 두고** 돌리는 전제다(`require("./mock")`, `../src`).
4. `scripts/xref.py` — 문서 절의 메시지 템플릿(`{…}` → `.+?`)을 캡처 원문에 fullmatch. `scripts/placeholders.py` — 코드 리터럴의 `{…}` 자리와 문서 자리의 이름·순서 정적 대조. 결과 `out/rows.json`.
5. 언제·고치려면·참고는 문서 페이지별 여섯 그룹(A=01, B=02, C=03, D=04+09, E=05+06, F=07+08)으로 나눠 코드 조건·호출자·공개 표면·앵커와 대조했고, 메인이 각 그룹의 핵심 주장을 프로브 출력으로 재확인했다.

## 숫자

- 전체 id 248(소스·문서 양쪽 일치 — 문서에만 있거나 소스에만 있는 id 0, 문서의 소스 파일 표기 불일치 0, 한 id 두 자리 0).
- 트리거 성공 241(spec 223 + 프로브 18) / 정적 대조만 7(`Quad0004`·`Quad0009` 도달 불가, `Quad0071`·`Quad0098`·`Quad0117`·`Quad0192` 내부 불변식·Init 누락, `Quad0164` 선행 게이트 셋이 먼저 막음).
- 메시지 문구: 248 전부 일치(fullmatch 236 + 문서가 "꼬리 붙음"을 적은 PREFIX 3 + 꼬리 힌트 넷을 요약 표기한 `Quad0076` 1 + 정적 7(자리 이름·순서 일치)). 예외 하나: `Quad0179`은 런타임 꼬리(ZOMBIE_NOTE)를 문서가 안 적었다.
- 언제·고치려면·참고: 일치 208 / 불일치 40(아래 표의 마지막 열). 참고 앵커는 전부 실재.

## 발견 — 본문은 이 README를 부른 탐사 보고(E28)가 소스

(여기는 id 목록만: (a) 문서 오류 — 0002·0003·0018·0020·0022·0027·0043·0048·0053·0055·0068·0069·0076·0083·0087/0088/0090/0109/0110/0113(죽은 핸들)·0089·0091·0108·0111·0114·0123·0130·0136·0141·0149·0168·0169·0179·0185·0192·0198·0220·0226·0229·0237; (b)/(d) 코드 쪽 — 0055 힌트, 0022/0229 함수 이름, 0071 함수 이름, 0123 blame, 0002 주체, 0169/0242 한 조건 두 id, 0209/0211 죽은 갈래, 0020/0158/0162, 0098 호출자 없음, 0226 주체; (c) 문구 판단 다수.)

## 전수 표

| id | 문서 | raise 자리 | 메시지 대조 | 트리거 | 언제/고치려면/참고 |
|---|---|---|---|---|---|
| Quad0001 | 05-tag-attr.md:10 | quad-base/src/Attr/Key.luau:58 | FULL | spec | OK |
| Quad0002 | 05-tag-attr.md:18 | quad-base/src/Attr/Key.luau:112 | FULL | probe+spec | when+fix |
| Quad0003 | 05-tag-attr.md:26 | quad-base/src/Attr/init.luau:99 | FULL | probe | when(도달성) |
| Quad0004 | 05-tag-attr.md:34 | quad-base/src/Attr/init.luau:102 | NOTRIG | 정적만 | OK |
| Quad0005 | 05-tag-attr.md:42 | quad-base/src/Attr/init.luau:109 | FULL | spec | OK |
| Quad0006 | 05-tag-attr.md:50 | quad-base/src/Attr/init.luau:128 | FULL | spec | OK |
| Quad0007 | 05-tag-attr.md:58 | quad-base/src/Attr/init.luau:132 | FULL | spec | OK |
| Quad0008 | 05-tag-attr.md:66 | quad-base/src/Attr/init.luau:138 | FULL | probe+spec | OK |
| Quad0009 | 05-tag-attr.md:74 | quad-base/src/Attr/init.luau:141 | NOTRIG | 정적만 | OK |
| Quad0010 | 05-tag-attr.md:82 | quad-base/src/Attr/init.luau:146 | FULL | probe+spec | OK |
| Quad0011 | 05-tag-attr.md:90 | quad-base/src/Attr/init.luau:167 | FULL | probe+spec | OK |
| Quad0012 | 05-tag-attr.md:98 | quad-base/src/Attr/init.luau:179 | FULL | probe | OK |
| Quad0013 | 05-tag-attr.md:106 | quad-base/src/Attr/init.luau:195 | FULL | spec | OK |
| Quad0014 | 05-tag-attr.md:114 | quad-base/src/Attr/init.luau:198 | FULL | spec | OK |
| Quad0015 | 05-tag-attr.md:122 | quad-base/src/Attr/init.luau:201 | FULL | spec | OK |
| Quad0016 | 05-tag-attr.md:130 | quad-base/src/Attr/init.luau:262 | FULL | probe+spec | OK |
| Quad0017 | 01-core-reactive.md:10 | quad-base/src/Blocker.luau:94 | FULL | spec | OK |
| Quad0018 | 01-core-reactive.md:18 | quad-base/src/Blocker.luau:117 | FULL | spec | when |
| Quad0019 | 02-dispatch-bookkeeping.md:10 | quad-base/src/Bookkeeping.luau:57 | FULL | spec | OK |
| Quad0020 | 02-dispatch-bookkeeping.md:18 | quad-base/src/Bookkeeping.luau:66 | FULL | spec | when |
| Quad0021 | 02-dispatch-bookkeeping.md:26 | quad-base/src/Bookkeeping.luau:137 | FULL | spec | OK |
| Quad0022 | 02-dispatch-bookkeeping.md:34 | quad-base/src/Bookkeeping.luau:201 | FULL | probe+spec | when+fix |
| Quad0023 | 02-dispatch-bookkeeping.md:42 | quad-base/src/Bookkeeping.luau:248 | FULL | probe+spec | OK |
| Quad0024 | 02-dispatch-bookkeeping.md:50 | quad-base/src/Bookkeeping.luau:288 | FULL | probe | OK |
| Quad0025 | 02-dispatch-bookkeeping.md:58 | quad-base/src/Bookkeeping.luau:380 | FULL | spec | OK |
| Quad0026 | 06-module-backend.md:10 | quad-base/src/Claim.luau:64 | FULL | spec | OK |
| Quad0027 | 06-module-backend.md:18 | quad-base/src/Claim.luau:99 | FULL | probe+spec | when |
| Quad0028 | 06-module-backend.md:26 | quad-base/src/Claim.luau:105 | FULL | spec | OK |
| Quad0029 | 06-module-backend.md:34 | quad-base/src/Claim.luau:115 | FULL | probe+spec | OK |
| Quad0030 | 06-module-backend.md:42 | quad-base/src/Claim.luau:121 | FULL | spec | OK |
| Quad0031 | 06-module-backend.md:50 | quad-base/src/Claim.luau:134 | FULL | spec | OK |
| Quad0032 | 06-module-backend.md:58 | quad-base/src/Claim.luau:148 | FULL | spec | OK |
| Quad0033 | 06-module-backend.md:66 | quad-base/src/Claim.luau:188 | FULL | spec | OK |
| Quad0034 | 06-module-backend.md:74 | quad-base/src/Claim.luau:191 | FULL | probe+spec | OK |
| Quad0035 | 01-core-reactive.md:26 | quad-base/src/Context.luau:52 | FULL | spec | OK |
| Quad0036 | 01-core-reactive.md:34 | quad-base/src/Context.luau:72 | FULL | spec | OK |
| Quad0037 | 01-core-reactive.md:42 | quad-base/src/Context.luau:79 | FULL | spec | OK |
| Quad0038 | 01-core-reactive.md:50 | quad-base/src/Context.luau:89 | FULL | spec | OK |
| Quad0039 | 01-core-reactive.md:58 | quad-base/src/Debounce.luau:88 | FULL | probe+spec | OK |
| Quad0040 | 01-core-reactive.md:66 | quad-base/src/Debounce.luau:98 | FULL | spec | OK |
| Quad0041 | 01-core-reactive.md:74 | quad-base/src/Debounce.luau:104 | FULL | spec | OK |
| Quad0042 | 01-core-reactive.md:82 | quad-base/src/Debounce.luau:110 | FULL | spec | OK |
| Quad0043 | 01-core-reactive.md:90 | quad-base/src/Debounce.luau:143 | FULL | spec | when |
| Quad0044 | 01-core-reactive.md:98 | quad-base/src/Debounce.luau:155 | FULL | spec | OK |
| Quad0045 | 01-core-reactive.md:106 | quad-base/src/Debounce.luau:323 | FULL | probe | OK |
| Quad0046 | 01-core-reactive.md:114 | quad-base/src/Debounce.luau:340 | FULL | spec | OK |
| Quad0047 | 01-core-reactive.md:122 | quad-base/src/Debounce.luau:343 | FULL | spec | OK |
| Quad0048 | 01-core-reactive.md:130 | quad-base/src/Debounce.luau:349 | FULL | probe+spec | when+fix |
| Quad0049 | 02-dispatch-bookkeeping.md:74 | quad-base/src/Dispatch/Modifier/init.luau:178 | FULL | spec | OK |
| Quad0050 | 02-dispatch-bookkeeping.md:82 | quad-base/src/Dispatch/Modifier/init.luau:187 | FULL | spec | OK |
| Quad0051 | 02-dispatch-bookkeeping.md:90 | quad-base/src/Dispatch/Modifier/init.luau:201 | FULL | spec | OK |
| Quad0052 | 02-dispatch-bookkeeping.md:98 | quad-base/src/Dispatch/Modifier/init.luau:204 | FULL | probe+spec | OK |
| Quad0053 | 02-dispatch-bookkeeping.md:106 | quad-base/src/Dispatch/Modifier/init.luau:216 | FULL | spec | when |
| Quad0054 | 02-dispatch-bookkeeping.md:114 | quad-base/src/Dispatch/Modifier/init.luau:222 | FULL | spec | OK |
| Quad0055 | 02-dispatch-bookkeeping.md:122 | quad-base/src/Dispatch/Modifier/init.luau:248 | FULL | probe+spec | fix(+메시지 힌트) |
| Quad0056 | 02-dispatch-bookkeeping.md:130 | quad-base/src/Dispatch/Modifier/init.luau:252 | FULL | spec | OK |
| Quad0057 | 02-dispatch-bookkeeping.md:138 | quad-base/src/Dispatch/Modifier/init.luau:293 | FULL | spec | OK |
| Quad0058 | 02-dispatch-bookkeeping.md:146 | quad-base/src/Dispatch/Modifier/init.luau:327 | FULL | spec | OK |
| Quad0059 | 02-dispatch-bookkeeping.md:154 | quad-base/src/Dispatch/Modifier/init.luau:367 | FULL | spec | OK |
| Quad0060 | 02-dispatch-bookkeeping.md:162 | quad-base/src/Dispatch/Modifier/init.luau:373 | FULL | spec | OK |
| Quad0061 | 02-dispatch-bookkeeping.md:170 | quad-base/src/Dispatch/Modifier/init.luau:376 | FULL | spec | OK |
| Quad0062 | 02-dispatch-bookkeeping.md:178 | quad-base/src/Dispatch/Modifier/init.luau:382 | FULL | spec | OK |
| Quad0063 | 02-dispatch-bookkeeping.md:186 | quad-base/src/Dispatch/Modifier/init.luau:388 | FULL | spec | OK |
| Quad0064 | 02-dispatch-bookkeeping.md:194 | quad-base/src/Dispatch/Modifier/init.luau:391 | FULL | spec | OK |
| Quad0065 | 02-dispatch-bookkeeping.md:202 | quad-base/src/Dispatch/Modifier/init.luau:396 | FULL | spec | OK |
| Quad0066 | 02-dispatch-bookkeeping.md:210 | quad-base/src/Dispatch/Modifier/init.luau:404 | FULL | spec | OK |
| Quad0067 | 02-dispatch-bookkeeping.md:218 | quad-base/src/Dispatch/Modifier/init.luau:438 | FULL | spec | OK |
| Quad0068 | 02-dispatch-bookkeeping.md:226 | quad-base/src/Dispatch/Modifier/init.luau:497 | FULL | probe+spec | when |
| Quad0069 | 02-dispatch-bookkeeping.md:234 | quad-base/src/Dispatch/Ref.luau:52 | FULL | probe+spec | when |
| Quad0070 | 02-dispatch-bookkeeping.md:242 | quad-base/src/Dispatch/StoreBind.luau:78 | FULL | spec | OK |
| Quad0071 | 02-dispatch-bookkeeping.md:250 | quad-base/src/Dispatch/init.luau:238 | NOTRIG | 정적만 | OK |
| Quad0072 | 02-dispatch-bookkeeping.md:258 | quad-base/src/Dispatch/init.luau:254 | FULL | spec | OK |
| Quad0073 | 02-dispatch-bookkeeping.md:266 | quad-base/src/Dispatch/init.luau:264 | FULL | spec | OK |
| Quad0074 | 02-dispatch-bookkeeping.md:274 | quad-base/src/Dispatch/init.luau:270 | FULL | spec | OK |
| Quad0075 | 02-dispatch-bookkeeping.md:282 | quad-base/src/Dispatch/init.luau:332 | FULL | spec | OK |
| Quad0076 | 02-dispatch-bookkeeping.md:290 | quad-base/src/Dispatch/init.luau:206 | NONE | spec | fix |
| Quad0077 | 02-dispatch-bookkeeping.md:300 | quad-base/src/Dispatch/init.luau:214 | FULL | spec | OK |
| Quad0079 | 02-dispatch-bookkeeping.md:308 | quad-base/src/Dispatch/init.luau:394 | FULL | spec | OK |
| Quad0080 | 02-dispatch-bookkeeping.md:316 | quad-base/src/Dispatch/init.luau:402 | FULL | spec | OK |
| Quad0081 | 02-dispatch-bookkeeping.md:324 | quad-base/src/Dispatch/init.luau:414 | FULL | spec | OK |
| Quad0082 | 02-dispatch-bookkeeping.md:332 | quad-base/src/Dispatch/init.luau:468 | FULL | spec | OK |
| Quad0083 | 02-dispatch-bookkeeping.md:340 | quad-base/src/Dispatch/init.luau:481 | FULL | probe+spec | when |
| Quad0084 | 02-dispatch-bookkeeping.md:348 | quad-base/src/Dispatch/init.luau:484 | FULL | spec | OK |
| Quad0085 | 02-dispatch-bookkeeping.md:356 | quad-base/src/Dispatch/init.luau:505 | FULL | probe+spec | OK |
| Quad0086 | 04-ref-observer-effect.md:10 | quad-base/src/Effect.luau:119 | FULL | probe+spec | OK |
| Quad0087 | 04-ref-observer-effect.md:18 | quad-base/src/Effect.luau:156 | FULL | probe+spec | when+fix(죽은 핸들) |
| Quad0088 | 04-ref-observer-effect.md:26 | quad-base/src/Effect.luau:234 | FULL | spec | when+fix(죽은 핸들) |
| Quad0089 | 04-ref-observer-effect.md:34 | quad-base/src/Effect.luau:237 | FULL | probe | when |
| Quad0090 | 04-ref-observer-effect.md:50 | quad-base/src/Effect.luau:252 | FULL | probe+spec | when+fix(죽은 핸들) |
| Quad0091 | 04-ref-observer-effect.md:58 | quad-base/src/Effect.luau:255 | FULL | spec | when+fix |
| Quad0092 | 04-ref-observer-effect.md:74 | quad-base/src/Effect.luau:276 | FULL | spec | OK |
| Quad0093 | 04-ref-observer-effect.md:82 | quad-base/src/Effect.luau:285 | FULL | spec | OK |
| Quad0094 | 04-ref-observer-effect.md:90 | quad-base/src/Effect.luau:297 | FULL | spec | OK |
| Quad0095 | 04-ref-observer-effect.md:98 | quad-base/src/Effect.luau:325 | FULL | spec | OK |
| Quad0096 | 04-ref-observer-effect.md:106 | quad-base/src/Effect.luau:328 | FULL | spec | OK |
| Quad0097 | 04-ref-observer-effect.md:114 | quad-base/src/Effect.luau:425 | FULL | spec | OK |
| Quad0098 | 04-ref-observer-effect.md:122 | quad-base/src/Effect.luau:439 | NOTRIG | 정적만 | OK |
| Quad0099 | 09-sugar.md:10 | quad-base/src/Fallback.luau:30 | FULL | spec | OK |
| Quad0100 | 09-sugar.md:18 | quad-base/src/Fallback.luau:33 | FULL | spec | OK |
| Quad0101 | 04-ref-observer-effect.md:130 | quad-base/src/LifecycleHooks.luau:35 | FULL | spec | OK |
| Quad0102 | 06-module-backend.md:82 | quad-base/src/LifetimeHandle.luau:123 | FULL | spec | OK |
| Quad0103 | 06-module-backend.md:90 | quad-base/src/LifetimeHandle.luau:126 | FULL | spec | OK |
| Quad0104 | 06-module-backend.md:98 | quad-base/src/LifetimeHandle.luau:139 | FULL | spec | OK |
| Quad0105 | 06-module-backend.md:106 | quad-base/src/LifetimeHandle.luau:180 | FULL | spec | OK |
| Quad0106 | 06-module-backend.md:114 | quad-base/src/ModuleIdentity.luau:25 | FULL | spec | OK |
| Quad0108 | 06-module-backend.md:122 | quad-base/src/NotInstalled.luau:30 | FULL | spec | fix |
| Quad0109 | 04-ref-observer-effect.md:138 | quad-base/src/Observer.luau:118 | FULL | probe+spec | when+fix(죽은 핸들) |
| Quad0110 | 04-ref-observer-effect.md:146 | quad-base/src/Observer.luau:125 | FULL | spec | when+fix(죽은 핸들) |
| Quad0111 | 04-ref-observer-effect.md:154 | quad-base/src/Observer.luau:129 | FULL | probe+spec | when |
| Quad0112 | 04-ref-observer-effect.md:162 | quad-base/src/Observer.luau:146 | FULL | spec | OK |
| Quad0113 | 04-ref-observer-effect.md:170 | quad-base/src/Observer.luau:156 | FULL | probe+spec | when+fix(죽은 핸들) |
| Quad0114 | 04-ref-observer-effect.md:178 | quad-base/src/Observer.luau:162 | FULL | probe+spec | when+fix |
| Quad0115 | 04-ref-observer-effect.md:186 | quad-base/src/Observer.luau:176 | FULL | spec | OK |
| Quad0116 | 04-ref-observer-effect.md:194 | quad-base/src/Observer.luau:274 | FULL | spec | OK |
| Quad0117 | 04-ref-observer-effect.md:202 | quad-base/src/Observer.luau:288 | NOTRIG | 정적만 | OK |
| Quad0118 | 01-core-reactive.md:138 | quad-base/src/Operator.luau:37 | FULL | spec | OK |
| Quad0119 | 01-core-reactive.md:146 | quad-base/src/Operator.luau:43 | FULL | spec | OK |
| Quad0120 | 01-core-reactive.md:154 | quad-base/src/Operator.luau:60 | FULL | spec | OK |
| Quad0121 | 01-core-reactive.md:162 | quad-base/src/Operator.luau:62 | FULL | spec | OK |
| Quad0122 | 01-core-reactive.md:170 | quad-base/src/Operator.luau:78 | FULL | spec | OK |
| Quad0123 | 01-core-reactive.md:178 | quad-base/src/Operator.luau:85 | FULL | probe+spec | when (+blame) |
| Quad0124 | 01-core-reactive.md:186 | quad-base/src/Operator.luau:164 | FULL | probe+spec | OK |
| Quad0125 | 01-core-reactive.md:194 | quad-base/src/Operator.luau:178 | FULL | spec | OK |
| Quad0126 | 01-core-reactive.md:202 | quad-base/src/Operator.luau:183 | FULL | spec | OK |
| Quad0127 | 01-core-reactive.md:210 | quad-base/src/Operator.luau:190 | FULL | spec | OK |
| Quad0128 | 01-core-reactive.md:218 | quad-base/src/Operator.luau:200 | FULL | spec | OK |
| Quad0129 | 01-core-reactive.md:226 | quad-base/src/Operator.luau:213 | FULL | spec | OK |
| Quad0130 | 04-ref-observer-effect.md:210 | quad-base/src/Ref/init.luau:101 | FULL | spec | when |
| Quad0132 | 04-ref-observer-effect.md:218 | quad-base/src/Ref/init.luau:124 | FULL | spec | OK |
| Quad0133 | 04-ref-observer-effect.md:226 | quad-base/src/Ref/init.luau:155 | FULL | spec | OK |
| Quad0134 | 04-ref-observer-effect.md:234 | quad-base/src/Ref/init.luau:164 | FULL | probe | OK |
| Quad0135 | 04-ref-observer-effect.md:242 | quad-base/src/Ref/init.luau:190 | FULL | spec | OK |
| Quad0136 | 04-ref-observer-effect.md:250 | quad-base/src/Ref/init.luau:275 | FULL | spec | when |
| Quad0137 | 04-ref-observer-effect.md:258 | quad-base/src/Ref/init.luau:277 | FULL | spec | OK |
| Quad0138 | 06-module-backend.md:130 | quad-base/src/Relate.luau:28 | FULL | spec | OK |
| Quad0139 | 06-module-backend.md:138 | quad-base/src/Relate.luau:29 | FULL | spec | OK |
| Quad0140 | 03-slot.md:10 | quad-base/src/Slot/Handler.luau:37 | FULL | probe | OK |
| Quad0141 | 03-slot.md:18 | quad-base/src/Slot/Handler.luau:61 | FULL | probe+spec | when |
| Quad0142 | 03-slot.md:26 | quad-base/src/Slot/List.luau:95 | FULL | probe | OK |
| Quad0143 | 03-slot.md:34 | quad-base/src/Slot/List.luau:102 | FULL | spec | OK |
| Quad0144 | 03-slot.md:42 | quad-base/src/Slot/List.luau:114 | FULL | spec | OK |
| Quad0145 | 03-slot.md:50 | quad-base/src/Slot/List.luau:117 | FULL | probe | OK |
| Quad0146 | 03-slot.md:58 | quad-base/src/Slot/List.luau:138 | FULL | spec | OK |
| Quad0147 | 03-slot.md:66 | quad-base/src/Slot/List.luau:172 | FULL | spec | OK |
| Quad0148 | 03-slot.md:74 | quad-base/src/Slot/List.luau:214 | FULL | spec | OK |
| Quad0149 | 03-slot.md:82 | quad-base/src/Slot/List.luau:215 | FULL | probe+spec | when |
| Quad0150 | 03-slot.md:90 | quad-base/src/Slot/List.luau:221 | FULL | spec | OK |
| Quad0151 | 03-slot.md:98 | quad-base/src/Slot/List.luau:226 | FULL | probe+spec | OK |
| Quad0152 | 03-slot.md:106 | quad-base/src/Slot/List.luau:232 | FULL | spec | OK |
| Quad0153 | 03-slot.md:114 | quad-base/src/Slot/List.luau:238 | FULL | spec | OK |
| Quad0154 | 03-slot.md:122 | quad-base/src/Slot/List.luau:265 | FULL | spec | OK |
| Quad0155 | 03-slot.md:130 | quad-base/src/Slot/List.luau:268 | FULL | spec | OK |
| Quad0156 | 03-slot.md:138 | quad-base/src/Slot/Owner.luau:28 | PREFIX | probe | OK |
| Quad0157 | 03-slot.md:146 | quad-base/src/Slot/Owner.luau:41 | FULL | spec | OK |
| Quad0158 | 03-slot.md:154 | quad-base/src/Slot/Owner.luau:44 | FULL | spec | OK |
| Quad0159 | 03-slot.md:162 | quad-base/src/Slot/Owner.luau:47 | FULL | spec | OK |
| Quad0160 | 03-slot.md:170 | quad-base/src/Slot/Owner.luau:54 | PREFIX | spec | OK |
| Quad0161 | 03-slot.md:178 | quad-base/src/Slot/Owner.luau:63 | FULL | spec | OK |
| Quad0162 | 03-slot.md:186 | quad-base/src/Slot/Owner.luau:66 | FULL | spec | OK |
| Quad0163 | 03-slot.md:194 | quad-base/src/Slot/Owner.luau:72 | FULL | probe | OK |
| Quad0164 | 03-slot.md:202 | quad-base/src/Slot/Tree.luau:34 | NOTRIG | 정적만 | OK |
| Quad0165 | 03-slot.md:211 | quad-base/src/Slot/init.luau:131 | FULL | spec | OK |
| Quad0166 | 03-slot.md:219 | quad-base/src/Slot/init.luau:137 | FULL | probe+spec | OK |
| Quad0167 | 03-slot.md:227 | quad-base/src/Slot/init.luau:148 | FULL | probe+spec | OK |
| Quad0168 | 03-slot.md:235 | quad-base/src/Slot/init.luau:170 | FULL | probe+spec | when |
| Quad0169 | 03-slot.md:251 | quad-base/src/Slot/init.luau:239 | FULL | probe+spec | when |
| Quad0170 | 03-slot.md:259 | quad-base/src/Slot/init.luau:249 | FULL | probe+spec | OK |
| Quad0171 | 03-slot.md:267 | quad-base/src/Slot/init.luau:252 | FULL | probe+spec | OK |
| Quad0172 | 03-slot.md:275 | quad-base/src/Slot/init.luau:255 | PREFIX | probe+spec | OK |
| Quad0173 | 03-slot.md:283 | quad-base/src/Slot/init.luau:266 | FULL | spec | OK |
| Quad0174 | 03-slot.md:291 | quad-base/src/Slot/init.luau:329 | FULL | probe+spec | OK |
| Quad0175 | 03-slot.md:299 | quad-base/src/Slot/init.luau:365 | FULL | spec | OK |
| Quad0176 | 03-slot.md:307 | quad-base/src/Slot/init.luau:442 | FULL | probe+spec | OK |
| Quad0177 | 03-slot.md:315 | quad-base/src/Slot/init.luau:448 | FULL | probe+spec | OK |
| Quad0178 | 03-slot.md:323 | quad-base/src/Slot/init.luau:472 | FULL | spec | OK |
| Quad0179 | 03-slot.md:331 | quad-base/src/Slot/init.luau:478 | PREFIX | probe+spec | 메시지 꼬리 미기재 |
| Quad0180 | 03-slot.md:339 | quad-base/src/Slot/init.luau:491 | FULL | probe | OK |
| Quad0181 | 01-core-reactive.md:234 | quad-base/src/Source.luau:84 | FULL | spec | OK |
| Quad0182 | 01-core-reactive.md:242 | quad-base/src/Source.luau:96 | FULL | spec | OK |
| Quad0183 | 01-core-reactive.md:250 | quad-base/src/State.luau:111 | FULL | spec | OK |
| Quad0184 | 01-core-reactive.md:258 | quad-base/src/State.luau:191 | FULL | probe+spec | OK |
| Quad0185 | 01-core-reactive.md:266 | quad-base/src/State.luau:213 | FULL | probe+spec | when |
| Quad0186 | 01-core-reactive.md:274 | quad-base/src/State.luau:252 | FULL | spec | OK |
| Quad0187 | 01-core-reactive.md:282 | quad-base/src/State.luau:268 | FULL | spec | OK |
| Quad0188 | 01-core-reactive.md:290 | quad-base/src/State.luau:326 | FULL | spec | OK |
| Quad0189 | 01-core-reactive.md:298 | quad-base/src/State.luau:339 | FULL | spec | OK |
| Quad0190 | 01-core-reactive.md:306 | quad-base/src/State.luau:350 | FULL | probe | OK |
| Quad0191 | 01-core-reactive.md:314 | quad-base/src/State.luau:360 | FULL | spec | OK |
| Quad0192 | 01-core-reactive.md:322 | quad-base/src/State.luau:378 | NOTRIG | 정적만 | when(도달 불가) |
| Quad0193 | 01-core-reactive.md:330 | quad-base/src/Store.luau:63 | FULL | probe+spec | OK |
| Quad0194 | 01-core-reactive.md:338 | quad-base/src/Store.luau:66 | FULL | probe+spec | OK |
| Quad0195 | 01-core-reactive.md:346 | quad-base/src/Store.luau:115 | FULL | spec | OK |
| Quad0196 | 01-core-reactive.md:354 | quad-base/src/Store.luau:118 | FULL | spec | OK |
| Quad0197 | 01-core-reactive.md:362 | quad-base/src/Store.luau:121 | FULL | spec | OK |
| Quad0198 | 01-core-reactive.md:370 | quad-base/src/Store.luau:128 | FULL | spec | when |
| Quad0199 | 05-tag-attr.md:138 | quad-base/src/Tag.luau:76 | FULL | spec | OK |
| Quad0200 | 05-tag-attr.md:146 | quad-base/src/Tag.luau:104 | FULL | spec | OK |
| Quad0201 | 05-tag-attr.md:154 | quad-base/src/Tag.luau:114 | FULL | probe+spec | OK |
| Quad0202 | 05-tag-attr.md:162 | quad-base/src/Tag.luau:119 | FULL | spec | OK |
| Quad0203 | 05-tag-attr.md:170 | quad-base/src/Tag.luau:128 | FULL | spec | OK |
| Quad0204 | 05-tag-attr.md:178 | quad-base/src/Tag.luau:131 | FULL | spec | OK |
| Quad0205 | 05-tag-attr.md:186 | quad-base/src/Tag.luau:173 | FULL | spec | OK |
| Quad0206 | 05-tag-attr.md:194 | quad-base/src/Tag.luau:193 | FULL | probe+spec | OK |
| Quad0207 | 05-tag-attr.md:202 | quad-base/src/Tag.luau:226 | FULL | spec | OK |
| Quad0208 | 06-module-backend.md:162 | quad-base/src/init.luau:129 | FULL | spec | OK |
| Quad0209 | 06-module-backend.md:170 | quad-base/src/init.luau:145 | FULL | spec | OK |
| Quad0210 | 06-module-backend.md:178 | quad-base/src/init.luau:154 | FULL | spec | OK |
| Quad0211 | 06-module-backend.md:186 | quad-base/src/init.luau:164 | FULL | spec | OK |
| Quad0212 | 06-module-backend.md:194 | quad-base/src/init.luau:197 | FULL | spec | OK |
| Quad0213 | 06-module-backend.md:202 | quad-base/src/init.luau:208 | FULL | spec | OK |
| Quad0214 | 08-roblox-tween.md:10 | quad-roblox/src/Animate.luau:67 | FULL | spec | OK |
| Quad0215 | 07-roblox.md:10 | quad-roblox/src/EngineOps.luau:146 | FULL | spec | OK |
| Quad0216 | 07-roblox.md:18 | quad-roblox/src/EngineOps.luau:149 | FULL | probe+spec | OK |
| Quad0217 | 07-roblox.md:26 | quad-roblox/src/EngineOps.luau:156 | FULL | spec | OK |
| Quad0218 | 07-roblox.md:34 | quad-roblox/src/Handlers/Event.luau:79 | FULL | spec | OK |
| Quad0219 | 07-roblox.md:42 | quad-roblox/src/Handlers/InstanceChild.luau:64 | FULL | spec | OK |
| Quad0220 | 07-roblox.md:50 | quad-roblox/src/Handlers/InstanceChild.luau:76 | FULL | spec | when(방향 반대) |
| Quad0221 | 07-roblox.md:58 | quad-roblox/src/Handlers/OnChange.luau:67 | FULL | spec | OK |
| Quad0222 | 07-roblox.md:66 | quad-roblox/src/Handlers/OnChange.luau:70 | FULL | spec | OK |
| Quad0223 | 07-roblox.md:74 | quad-roblox/src/Handlers/OnChange.luau:91 | FULL | spec | OK |
| Quad0224 | 07-roblox.md:82 | quad-roblox/src/Handlers/OnChange.luau:95 | FULL | probe+spec | OK |
| Quad0225 | 07-roblox.md:90 | quad-roblox/src/LifetimeHandle.luau:68 | FULL | spec | OK |
| Quad0226 | 07-roblox.md:98 | quad-roblox/src/LifetimeHandle.luau:135 | FULL | probe+spec | when(표면 누락) |
| Quad0227 | 08-roblox-tween.md:18 | quad-roblox/src/Tween.luau:162 | FULL | spec | OK |
| Quad0228 | 07-roblox.md:106 | quad-roblox/src/init.luau:229 | FULL | spec | OK |
| Quad0229 | 02-dispatch-bookkeeping.md:66 | quad-base/src/Bookkeeping.luau:202 | FULL | probe | when |
| Quad0230 | 04-ref-observer-effect.md:42 | quad-base/src/Effect.luau:237 | FULL | probe | OK |
| Quad0231 | 04-ref-observer-effect.md:66 | quad-base/src/Effect.luau:255 | FULL | probe | OK |
| Quad0232 | 06-module-backend.md:146 | quad-base/src/LifetimeHandle.luau:140 | FULL | spec | OK |
| Quad0233 | 06-module-backend.md:154 | quad-base/src/LifetimeHandle.luau:141 | FULL | spec | OK |
| Quad0234 | 04-ref-observer-effect.md:266 | quad-base/src/Observer.luau:129 | FULL | probe | OK |
| Quad0235 | 04-ref-observer-effect.md:274 | quad-base/src/Observer.luau:162 | FULL | probe | OK |
| Quad0236 | 03-slot.md:243 | quad-base/src/Slot/init.luau:171 | FULL | spec | OK |
| Quad0237 | 05-tag-attr.md:210 | quad-base/src/Tag.luau:105 | FULL | probe+spec | when |
| Quad0238 | 03-slot.md:347 | quad-base/src/Slot/Elements.luau:38 | FULL | probe+spec | OK |
| Quad0239 | 03-slot.md:355 | quad-base/src/Slot/Elements.luau:41 | FULL | probe+spec | OK |
| Quad0240 | 03-slot.md:363 | quad-base/src/Slot/Elements.luau:44 | FULL | probe+spec | OK |
| Quad0241 | 03-slot.md:371 | quad-base/src/Slot/Elements.luau:52 | FULL | probe+spec | OK |
| Quad0242 | 03-slot.md:379 | quad-base/src/Slot/Elements.luau:68 | FULL | probe+spec | OK |
| Quad0243 | 08-roblox-tween.md:26 | quad-roblox/src/Tween.luau:103 | FULL | spec | OK |
| Quad0244 | 08-roblox-tween.md:34 | quad-roblox/src/Tween.luau:107 | FULL | spec | OK |
| Quad0245 | 08-roblox-tween.md:42 | quad-roblox/src/Tween.luau:110 | FULL | spec | OK |
| Quad0246 | 08-roblox-tween.md:50 | quad-roblox/src/Tween.luau:115 | FULL | spec | OK |
| Quad0247 | 08-roblox-tween.md:58 | quad-roblox/src/Tween.luau:120 | FULL | spec | OK |
| Quad0248 | 08-roblox-tween.md:66 | quad-roblox/src/Tween.luau:131 | FULL | spec | OK |
| Quad0249 | 08-roblox-tween.md:74 | quad-roblox/src/Tween.luau:134 | FULL | probe+spec | OK |
| Quad0250 | 08-roblox-tween.md:82 | quad-roblox/src/Tween.luau:139 | FULL | spec | OK |
| Quad0251 | 08-roblox-tween.md:90 | quad-roblox/src/Tween.luau:146 | FULL | spec | OK |

## 발견 본문 (E28 보고와 같은 내용)

### (a) 문서 오류
- **Quad0220** — 07-roblox.md:54 "자기 조상의 자리"는 방향이 반대. 코드 InstanceChild.luau:73-79는 호스트에서 조상 사슬을 올라가며 `ancestor == v`를 보므로 "놓이는 값이 자기 자신이나 자기 **자손**의 자리에 놓일 때"(메시지 원문도 descendants).
- **Quad0089/0111** — 04:38·:158 "이미 강하게 구독됐을 때"만 적음. `canBound`는 `.Subscribed`만 보고 WeakSubscribe도 그걸 세우므로 WeakSubscribe 두 번도 이 에러(프로브 D_1 "E weak,weak"·"O weak,weak").
- **Quad0091/0114** — 04:62·:182 "중복 `:Subscribe()`"만. 약→강 승격도 거부(spec.effect:209-213, 프로브 "O weak,strong"), 고치려면 "다시 부르지 마세요"는 승격하려는 사용자를 못 풀어 줌(`:WeakUnsubscribe()` 뒤 `:Subscribe()`가 기존 경로).
- **Quad0087/0088/0090/0109/0110/0113(죽은 핸들)** — fn이 던지거나 Quad0086으로 죽은 Effect/Observer는 `_running`이 영구 true라 fn 밖에서 부른 Subscribe/바인드도 "inside fn" 문구(프로브 "E dead resub/bind"·"O dead resub/bind"). 04의 언제·고치려면은 fn 안 호출만 서술, 0086 절도 핸들이 죽는다는 말 없음.
- **Quad0136** — 04:254 `{kind}`에 `Ref`를 넣음. 숫자 키 평 Ref는 RefLeafHandler가 먼저 받으므로(spec.refhandlers:80-82) 0136은 PreRef/PostRef만(캡처도 그렇다).
- **Quad0130** — 04:214 "`ref:Wait()`로 대기 중인 그 코루틴"은 불가(인자 없는 Wait은 suspended). 실제는 `Wait(thread)`로 등록한 현재/조상 스레드에서 `:Set`(spec.ref:329-338).
- **Quad0018/0043** — 01:22·:94 "`state:Apply(...)` 대상이 State가 아닐 때"는 불가(`state:Apply`의 self는 늘 State). 닿는 길은 `__apply` 직접 호출뿐(spec.blocker:213, spec.debounce:59).
- **Quad0123** — 01:182 같은 서술. 실제 경로는 `tag:Apply`/`modifier:Apply`/팩토리 직접 호출(프로브 A_1).
- **Quad0185** — 01:270 "Compute 함수가 Modifier 반환"만. Operator `Alternative(modifier)`·`Indexed`로도 남(프로브 A_2) — 메시지 "a Compute function returned"도 그 경우 사용자에겐 낯섦.
- **Quad0048** — 01:134 "둘 다 false로 줄 때". Debounce는 Leading 기본 false라 `Trailing = false` 하나로도 남(프로브), 고치려면도 이 경우 `Leading = true`가 필요함을 말하지 않음. sugar/03 옵션 서술도 같은 구멍.
- **Quad0198** — 01:374 "(또는 `:Of`가 만든 필드)"는 틀림 — `Impl.Of`는 `Source(nil)`을 만들 뿐 검사 없음(Store.luau:92-99), 0198은 생성자 루프에서만.
- **Quad0192** — 01:326 "State API가 설치 전에 닿으면"은 도달 불가(유일 호출자 Source.luau:46이 바로 앞에서 RunInit).
- **Quad0022/0229** — 02:38·:70 `getOffsetAt`만 적음. `setOffsetSource(owner, i, src)`도 내부에서 getOffsetAt을 불러 같은 raise(프로브 B_1 "setOffsetSource pos3 fresh owner" → "Bookkeeping.getOffsetAt: … at most 1 may be queried"). 0022 고치려면의 "`setOffsetSource`로 먼저 등록"은 오히려 같은 에러를 냄 — 등록이 되는 건 `setLength`/`setEmpty`뿐(Bookkeeping.luau:186). 0229는 배치 게이트 안에서만 닿음(프로브 "getOffsetAt hole3").
- **Quad0020** — 02:22 "모든 공개 `q.Bookkeeping` 함수" — `releaseOwner`는 0162, `claimOwnerAt`는 0158(Owner.luau:44·66).
- **Quad0055** — 02:127 고치려면 "`mod:As(name)`을 쓰세요"(메시지 힌트도 같음)는 미등록 클래스를 못 벗어남 — `:As`도 `known[name]`을 봐서 Quad0052(프로브 "As(name) unknown").
- **Quad0069** — 02:238 "다른 인스턴스에" + "`v:Set(inst)`로 발화한" — 같은 인스턴스 두 자리도 남(프로브 "preref-twice-same"), 표시는 drive 선행 패스의 `_fired`라 사용자 `:Set`은 표시 안 함, 발화 전 PostRef도 해당.
- **Quad0068** — 02:230 "문자 키"만. 연속 배열부 밖 숫자 키(`[5] = mod`)도 해시 부분으로 걸림(프로브) — 메시지 "place it in the array part"가 이미 숫자 키를 쓴 사람에게 혼란((c)).
- **Quad0083** — 02:344 "메타테이블을 가진 값"만. 술어는 `or brandNameOf(...) ~= nil`이라 메타테이블 없는 브랜드(AttrKey)도(프로브 "drive AttrKey").
- **Quad0053** — 02:110 콜론 형태 `mod:Overridden()`도 트리거처럼 적었으나 self가 첫 인자라 불가(프로브: 0 fields 반환).
- **Quad0076** — 02:296-297 고치려면이 가장 흔한 원인(오타·읽기 전용 프로퍼티·`Parent`, 읽기는 `q.OnChange`)을 안 적음; 설치된 상태에서 "provider … initialized" 힌트는 오도((c)).
- **Quad0169** — 03:255 "이미 파괴된 Slot을 넣을 때" 전반으로 서술. 코드(Slot/init.luau:231-240)는 State가 쥔 파괴된 Slot만; 날 Slot은 Quad0242(프로브 C_1). 0242 절(03:383)과 모순.
- **Quad0141** — 03:22 문자 키만. `q.Dispatch.process(inst, 0|-2|1.5, slot, 1)`도 이 폴백 가드로 와서 "not the value of a number key"라는 모순된 문구(프로브 C_2; 같은 가드 모양이 0137·0116·0097에도 — 문구 미확인).
- **Quad0168** — 03:239 `index < 1` 경우 누락(Remove(-1) → 0168).
- **Quad0149** — 03:86 "initial 원소를 준 생성자" — 빈 `q.Slot({})`도 잠김(`initial ~= nil`, 프로브).
- **Quad0002** — 05:22-23 "서로 다른 AttrKey 객체" + "캐시된 같은 키를 쓰라". 공개 `q.AttrKey`로는 같은 이름에 다른 객체가 안 나오고(클레임 중 강참조), 실제 경로는 그룹 `q.Attr` 둘 또는 그룹+`[AttrKey]`(그룹은 이름마다 비캐시 키, Attr/init.luau:237-244; 프로브 "0002 gg") — 처방이 그룹 대 그룹을 못 풂.
- **Quad0003** — 05:30 "[2026-09-27 실측] 닿는 호출 없음"은 틀림: `s[""] = q.Source(2); q.Attr(s)`로 닿음(Store에 `__newindex` 없음, core/04-store.md:156이 직접 대입을 막지 않는다고 명시). 0004·0009는 도달 불가 맞음.
- **Quad0237** — 05:214 "(브랜드가 아닌 커스텀 메타테이블)" — 코드는 메타테이블 있으면 브랜드 무관(State·Attr 모두 0237, 프로브 E_2). 가장 흔한 실수 `q.Tag(state)`를 배제하는 것처럼 읽힘.
- **Quad0027** — 06:22 "이미 한 번 Claim에 쓰인" — 한 Claim 트리 안 두 자리(`seen[desc]`)도(프로브 E_3).
- **Quad0108** — 06:127 고치려면 "`mock.installLifetime`"은 배포 안 되는 테스트 내부물(how-to/06:117-124).
- **Quad0226** — 07:102 `q.Backend.bindLifetime` 직접 호출만. 실사용 경로는 D·Claim 밖 인스턴스에 대한 `Dispatch.process`/Store bind로 Effect/Observer/Ref/Slot을 놓는 것(프로브 F_1 → "Quad0226 bindLifetime: …").
- **Quad0179** — 03:333 메시지 줄에 ZOMBIE_NOTE 꼬리가 없음(0156·0160·0172 절은 적음).

### (b) 코드 쪽
- **Quad0022/0229** — `setOffsetSource`에서 와도 "Bookkeeping.getOffsetAt: … may be queried"로 사용자가 하지 않은 질의를 말함(Bookkeeping.luau:393·199-203).
- **Quad0071** — 메시지는 늘 `Dispatch.retractFrom`인데 `retractRange`는 `process`(:366)에서도 불림(도달 경로는 못 찾음).
- **Quad0055** — 메시지 힌트 "(or use :As(name) …)"가 자기 조건을 못 벗어남(위).
- **Quad0002** — 주체 "AttrKey:"인데 실제 발화 대부분은 사용자가 AttrKey를 안 쓴 그룹 대 그룹.
- **Quad0226** — 주체 "bindLifetime:"인데 사용자는 bindLifetime을 부른 적 없음(process 경로).
- **Quad0123** — `Not`/`Bnot`이 SURFACE 태그라 `tag:Apply(q.Operator.Not)`·`modifier:Apply(q.Operator.Bnot)`는 Tag.luau:196·Modifier/init.luau:190(quad 자신)을 blame(프로브 A_1).
- **Quad0023/0024** — `error(msg, 1)`로 Bookkeeping.luau 자신을 blame, `recomputeBlocker:On()` 창 안이라 owner 동결 — 문서 무언급.
- **한 조건 여러 id** — 0169/0242(파괴된 Slot 원소, 날 값 vs State), 0020/0158/0162(nil ownerKey), 0209/0211(AddPlugin 갈래의 0209는 죽은 경로 — 문서 "사실상 UseProvider"는 "UseProvider에서만"), 0018/0043/0123(Apply 대상), 0039/0216(시간 값, 층 다름 — 정당).
- **Quad0098** — 호출자 없음(Effect.implFor를 부르는 곳이 없다 — 죽은 코드).

### (c) 판단 필요
- `(got {typeof(x)})` 꼬리가 정보 없음·자기모순: 0039·0041·0216(음수/NaN이 "(got number)"), 0008(항상 "(got table)"); `tostring` 꼬리가 문자열을 숫자처럼 보임: 0019·0021·0168(`"1"` → "(got 1)").
- 0215/0216 "Debounce/Throttle이 내부에서 이 op를 씀" — 그 경로론 안 닿음(0039가 먼저).
- 0214 둘째 문장은 0243~0247(필드 검증) 서술이 섞임; `q.Animate(q.Source({...}))`는 조용히 통과.
- 0243~0247 헬퍼 주체 "Tween:"이 Animate 경로에도 — 문서가 Animate 경로 무언급. 0249는 `Mapped` fn이 nil 반환해도 남(Tween.luau:170).
- 0124류 Operator 던짐 뒤 같은 세대 재읽기는 0184로 바뀜. 0039 언제에 MaxTime은 Trailing일 때만·평 숫자도 `_opts` 참조로 신호 시점에 재검. 0126 옛 동작 현재형. 0134 "메인 스레드"는 Roblox에선 부적절. 0087 예시에 설치 중 self 바인드 누락. 0230·0231·0234·0235 고치려면에 "자리에서 빼고 다시" 경로 누락. 0142는 `:Single`로 못 닿음. 0148·0166 고치려면이 데이터 State 전제. 0167 자기 `:List` Slot은 0166이 먼저. 0238(+0170·0239~0241) 입구 목록에 `Extract(i, new)` 누락. 0106 `{what}` 설명(자리 이름이 아니라 값 종류·표면). 0108 참고가 bindLifetime 절(UseProvider 절이 맞아 보임)·op 빠진 커스텀 프로바이더도 해당. 0029 "D.New"만. 0213 흔한 원인(사본·버전 차이) 누락. 0070 참고가 Quadnomicon Vol.8. 0004·0009 "(문서 미정)" 표기.
- 패킷 밖: extend/01-backend-provider-contract.md ~105행 `isClaimed`가 "Destroying 연결"을 본다는 서술 — 실제는 `nativeClaim`의 ClassName 변경 연결(quad-roblox LifetimeHandle.luau:64·94-96). roblox/03-d-modifier.md:9 테이블형이 "drive에서 Quad0063" — 0063은 `D.Modifier.<Class>({...})` 생성 시점. core/05-observer-effect.md:276-282 `effect:WeakSubscribe()`에 **에러** 줄 없음.
