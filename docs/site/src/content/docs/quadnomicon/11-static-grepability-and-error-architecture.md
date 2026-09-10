---
title: "Vol. 11 — 정적 grep 가능성, 표면 blame, 에러 아키텍처"
description: "포맷 헬퍼 없이 grep 가능한 에러 문자열과 표면 blame으로 이루어진 quad 에러 아키텍처를 설명합니다"
---
> **작성 목적**: 프레임워크 아키텍트 및 고급 엔지니어를 위한 기술 해설서
> **관련 소스**: `quad-error/src/init.luau`, `quad-base/src/ErrorNamespace.luau`

> [!CAUTION]
> 이 권은 에러 시스템 설계와 진단 철학을 다룹니다. 애플리케이션을 만들려고 quad를 배우는 중이라면 [Getting Started](/getting-started/01-first-screen/)부터 보십시오.

---

## 1. "깔끔한" 에러 헬퍼의 함정

여러 모듈이 비슷한 모양의 에러를 던지면 자연히 포맷 헬퍼를 만들고 싶어집니다.

```luau
-- 흔한 유혹(quad는 이 길을 가지 않는다)
local function formatError(subject: string, reason: string, got: any): string
	return string.format("%s: %s (got %s)", subject, reason, typeof(got))
end

local function addDep(dep: any)
	if dep == nil then
		error(formatError("State", "dependency must not be nil", dep), 2)
	end
end

addDep(nil) -- State: dependency must not be nil (got nil)
```

quad의 코드 품질 자문에서도 정확히 이 헬퍼가 제안됐고, **기각됐습니다.** 근거는 코드
중복이 아니라 디버깅 가능성입니다 — 헬퍼가 있으면 에러 포맷이 조각으로 쪼개져, 로그에
찍힌 문장을 들고 소스로 되돌아갈 방법이 사라집니다. 특히 `Fallback` 같은 격리 유틸이
에러를 잡아 다시 던지는 경로가 끼면 스택트레이스만으로는 원인을 못 짚습니다.

---

## 2. 리터럴은 raise 줄에 통째로 남는다

> [!IMPORTANT]
> **규약**: 메시지 리터럴은 그것을 던지는 그 줄에 통째로 남깁니다. 포맷 헬퍼를 두지
> 않으므로, 로그의 문장으로 **소스의 자리**를 찾을 수 있습니다.

정확히 말하면 "메시지 전문이 소스에 그대로 있다"는 뜻은 아닙니다. 값이 끼는 자리에는
문자열 보간을 씁니다.

```luau
Err.errorBeforeNearest(`State: dep #{i + 1} is nil`, SURFACE)
```

로그에는 `State: dep #2 is nil`이 찍히지만 소스에는 `#{i + 1}`이 있습니다. **grep의
단위는 값이 끼기 전까지의 고정 접두사**(`State: dep #`)이고, 그 접두사는 한 줄
안에 온전히 있습니다. 헬퍼가 있었다면 접두사조차 다른 파일에 있었을 것입니다.

메시지 모양 자체도 하나로 맞춰 둡니다 — **`주어: 이유 (got X)`**.

- **주어**는 사용자가 부른 표면의 이름입니다. 메소드는 `Slot:List`, 네임스페이스 함수는
  `Dispatch.setOffsetSource`(`quad.` 접두는 붙이지 않습니다), 생성자·불변식은 타입
  이름만(`State:`, `Tween:`). 인자 값은 주어가 아니라 이유 쪽에 싣습니다.
- **이유**는 영어 한 절, `must be …`/`cannot …` 현재형. 부연은 em-dash(` — `) 뒤에.
- **받은 값**은 문장 끝에 괄호로 — `(got {typeof(x)})`. `, got X` 같은 쉼표형은
  쓰지 않습니다.

```
Slot:List: updateFn must be a function (got string)
Dispatch.setOffsetSource: source must be a Source<number> or None (got number)
```

---

## 3. 표면 blame — 스택을 걸어 사용자 줄을 찾는다

라이브러리 에러의 고질병은 **내부 blame**입니다. 사용자가 `D.Frame { Size = … }`를
잘못 쓰면 Luau는 실제로 던진 자리, 즉 라이브러리 내부 파일을 가리킵니다.

```
호출 스택:
[프레임 1] 사용자 스크립트: MyButton.luau:15  ──> D.Frame { ... }  (SURFACE 경계)
[프레임 2] quad-base:  Dispatch/init.luau      (drive / process)
[프레임 3] quad-roblox: Handlers/Property.luau ──> 여기서 던진다
```

`error(msg, n)`의 `n`은 프레임 수를 세는 값이라, 래퍼가 하나 늘 때마다 손으로 센 숫자가
전부 틀어집니다. 깊이가 가변인 파이프라인(디스패치 체인)에서는 애초에 셀 수가 없습니다.

그래서 quad는 숫자를 세지 않고 **함수에 층 번호를 태그**합니다. 공개 표면 함수들은
`setFuncLevel(SURFACE, fn, …)`로 한 번 태깅되고, 던질 때 워커가 `debug.info`로 살아
있는 스택을 훑어 그 태그를 가진 프레임을 찾습니다. 태그 없는 프레임은 **건너뛸 뿐**
스캔을 끊지 않습니다. 아무것도 못 찾으면 raise 자리로 떨어집니다.

방향과 도착지 조합으로 진입점이 넷입니다.

| | 최외곽(outermost) | 최근접(nearest) |
|---|---|---|
| 태그된 프레임 자신을 blame | `errorAt` | `errorAtNearest` |
| 그 프레임의 **호출자**를 blame | `errorBefore` | `errorBeforeNearest` |

- **최외곽**은 래퍼가 몇 겹이든 뚫고 사용자의 진입 줄까지 올라갑니다. 디스패치 매치
  실패처럼 "어디서 시작됐든 사용자 줄을 짚어야 하는" 자리의 몫입니다.
- **최근접**은 손으로 쓴 `level 2`/`3`과 같은 뜻이되 깊이에 안전합니다. 인자 검증이나
  재진입 가드처럼, 콜백 안에서 부른 표면이 **그 콜백의 줄**을 짚어야 하는 자리의
  몫입니다.

### 3.1 보장되지 않는 것

이 메커니즘에는 실측된 한계가 있고, 메커니즘을 더 만들어 덮지 않기로 했습니다.

- **태그된 표면을 C 프레임이 직접 부르면**(`pcall(drive, …)`처럼 함수를 그대로 넘기면)
  `errorBefore`의 목표가 C 프레임에 얹혀 **`파일:줄` 접두가 사라집니다.** 메시지는
  살아남습니다 — 메시지가 자기 설명적이어야 한다는 §2의 규약이 여기서 방어선이 됩니다.
  접두가 필요하면 클로저로 감쌀 것.
- **태그된 프레임이 스택의 최상단 자체일 때**(`task.spawn(surface, …)`,
  `coroutine.create(surface)`)도 같은 모양으로 접두가 빠집니다.
- **재진입 진입**(옵저버 콜백 안에서 다시 디스패치가 도는 경우) 최외곽 스캔은 바깥
  진입 줄을 blame합니다. 이건 방향의 내재적 성질이고, 안쪽을 짚어야 하는 자리는 최근접
  쌍의 몫입니다.
- **테이블 필드에 담겨 그 필드로 호출되는 함수만 태그할 수 있습니다.** 로컬로 직접
  호출되는 함수는 `-O2`에서 인라인되어 태그가 스택에서 사라집니다(그러면 무매치
  폴백 — 메시지는 맞고 위치만 퇴화합니다). quad의 모든 태깅 지점이 이 조건을 만족합니다.
- **코루틴 경계를 넘지 않습니다.** raise는 자기 코루틴의 스택만 걷습니다.

---

## 4. `setFuncLevel`의 가변 인자와 nil 구멍

예전 시그니처는 함수 하나짜리 `setFuncLevel(func, level)`이었고, 파일마다 배열
리터럴을 돌리는 루프가 붙어 있었습니다.

```
의사코드 — 옛 관용구

  for _, fn in { mod.foo, mod.bar, mod.baz } do setFuncLevel(fn, SURFACE) end
```

여기에 조용한 구멍이 있었습니다. 메소드 이름이 바뀌거나 사라지면 그 자리에 `nil`이
들어가고, 배열 순회는 그 구멍에서 **말없이 끊깁니다.** 뒤쪽 함수들의 태그가 사라져도
아무것도 실패하지 않고, 나중에 그 함수에서 난 에러가 사용자 대신 라이브러리 내부를
blame할 뿐입니다.

지금은 가변 인자로 뒤집혀 있고, 구멍이 **로드 시점 에러**가 됩니다
(`quad-error/src/init.luau` 발췌).

```luau
function ns.setFuncLevel(level: number, ...: any)
	if type(level) ~= "number" then
		error(`setFuncLevel: level must be a number (got {typeof(level)}) — the signature is setFuncLevel(level, ...fns)`, 2)
	end
	for i = 1, select("#", ...) do
		local func = select(i, ...)
		if type(func) ~= "function" then
			error(`setFuncLevel: argument #{i + 1} must be a function (got {typeof(func)}) — a renamed or missing method?`, 2)
		end
		funcLevels[func] = level
	end
end
```

`select("#", ...)`는 `nil`까지 **세므로** 구멍이 건너뛰어지지 않고, 함수가 아닌 인자는
그 자리에서 던집니다. 조용히 태그가 빠지는 실패 모드가 시끄러운 로드 실패로 바뀌었습니다.

또 하나 눈여겨볼 것: 이 워커의 네 진입점은 **일부러 공통 헬퍼로 묶여 있지 않습니다.**
`error(msg, n)`이 프레임을 세기 때문에 헬퍼를 하나 끼우면 프레임이 하나 늘고, 그
프레임의 존재 여부는 `-O2` 인라인 여부에 달려 있습니다 — 즉 최적화 옵션에 따라 blame이 한
칸 밀립니다. 여기서의 중복은 의도된 프레임 산술입니다.

---

## 5. 마치며 — Quadnomicon 11권

| 권 | 주제 |
|---|---|
| 1 | 32-bit Wrapping Revision과 EpochMap |
| 2 | Slot-in-Slot 부분합 트리 |
| 3 | Luau 메모리 토폴로지 |
| 4 | 불변성 우회: 공변 마커 |
| 5 | 비파괴 언마운트와 소유권 공리 |
| 6 | 단일 인자 생존 게이트 |
| 7 | 인스턴스 신원, 네이티브 GC, `Claim` 계약 |
| 8 | 확장 가능한 디스패치 엔진과 우선순위 파이프라인 |
| 9 | 컴포넌트가 형제 여럿을 반환하는 문제와 DOMless Slot 트리 |
| 10 | 다중 백엔드 추상 기계 |
| 11 | 정적 grep 가능성, 표면 blame, 에러 아키텍처 |
