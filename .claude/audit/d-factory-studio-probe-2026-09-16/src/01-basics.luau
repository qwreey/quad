--!strict
-- [P1] Studio의 스크립트 분석이 type function을 아는가 / 같은 파일 안에서 평가하는가.
-- 보고할 것: (1-a) 3번 항목에 빨간 밑줄이 뜨는가, 메시지 원문. (2) "[P1] ran" 줄이
-- 스크립트 분석 창(또는 출력 창)에 뜨는가.

type function Echo(t: type)
	print("[P1] ran; tag=" .. tostring(t.tag))
	return types.singleton(t:value())
end

-- (1-a) 이 줄은 에러여야 정상('"q"'를 기대했는데 number)
-- Studio(Echo<"q">): Type Error: [P1] ran; tag=singleton
-- Studio(5): Type Error: Expected this to be '"q"', but got 'number'
-- Vscode(5): TypeError: Expected this to be '"q"', but got 'number'
local a: Echo<"q"> = 5

-- (1-b) 이 줄은 에러가 없어야 정상
-- Studio(Echo<"q">): Type Error: [P1] ran; tag=singleton
local b: Echo<"q"> = "q"

return { a, b }
