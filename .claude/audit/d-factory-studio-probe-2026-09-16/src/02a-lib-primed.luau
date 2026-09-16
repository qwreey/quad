--!strict
-- [P2] 다른 모듈에서 가져온 type function이 평가되는가 — 이 모듈은 **자기가 한 번 인스턴스화**한다.
-- (리눅스 luau-lsp 1.69.0 실측: 정의한 모듈이 한 번이라도 인스턴스화해 두면 소비자 쪽에서
--  임의의 인자로 써도 평가된다. 안 해 두면 소비자 쪽이 조용히 무진단.)
export type function Echo(t: type)
	return types.singleton(t:value())
end
export type Primed = Echo<"seed">

-- 이것은 이 파일 내에서 테스트한 부분이다.
-- Studio: Type Error: Expected this to be '"seed"', but got '"no"'
-- Vscode: TypeError: Expected this to be '"seed"', but got '"no"'
-- 에러 규격이 *완전히 동일* 하다. studio 안에서 Type Error 해딩 부분은 누르면 문서로 간다.
-- Vscode 는 뒤의 Luau(1000) 형태를 통해 연결된다. 그 차이 말고는 없고, 내부적으로 쓰는 lsp 는 같은 가능성이 보임.
-- local FallTest: Primed = "no"
-- local OkTest: Primed = "seed"
-- 후행 02c 에서 다시 테스트한다.

return {}
