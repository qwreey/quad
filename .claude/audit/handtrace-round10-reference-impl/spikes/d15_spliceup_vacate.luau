--!nocheck
-- spliceArraysUp이 비운 자리(index)의 observers/tokens를 명시적으로 nil로 두지 않으면?
-- (요구 목록은 lengthList=0/sourceList=None 자리표시자만 말한다)
local q = require("./core9"); local D = require("./dispatch9")
local function run(vacate)
    local inst = q.newInst("inst")
    local A, B = D.newSlot("A", {{name="a"}}), D.newSlot("B", {{name="b"}})
    local O = D.newSlot("O", { A, B })
    D.mountTop(inst, O)
    local bk = D.getBookkeeping(O)
    -- 손으로 spliceArraysUp(O, 1)을 "복사 루프" 방식으로 흉내: i→i+1 복사, 비운 자리는 vacate 여부에 따라
    local N = bk.N
    for i = N, 1, -1 do
        bk.lengthList[i+1] = bk.lengthList[i]; bk.sourceList[i+1] = bk.sourceList[i]
        bk.observers[i+1] = bk.observers[i]; bk.tokens[i+1] = bk.tokens[i]
        bk.indexOfToken[bk.tokens[i+1]] = i+1
    end
    bk.lengthList[1] = 0; bk.sourceList[1] = D.None
    if vacate then bk.observers[1] = nil; bk.tokens[1] = nil end
    bk.N = N + 1
    bk.offsetCacheValidUpTo = math.min(bk.offsetCacheValidUpTo, 0); bk.offsetSetUpTo = math.min(bk.offsetSetUpTo, 0)
    table.insert(O._elements, 1, {name = "new"})
    D.setOffsetSource(O, 1, D.None)
    D.setLength(O, 1, 1, inst)      -- oldObserver가 있으면 unbindLifetime한다
    -- 이제 A(2번 자리)의 길이가 바뀌면 B가 밀려야 한다
    A.Length:Set(3)
    print(("[vacate=%s] A.Length=3 후 B.Offset = %d (기대 4) | canExecute(observers[2]) = %s | indexOfToken[tokens[2]] = %s")
        :format(tostring(vacate), B.Offset:Get(), tostring(q.canExecute(bk.observers[2])), tostring(bk.indexOfToken[bk.tokens[2]])))
end
run(true); run(false)
