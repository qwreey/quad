--!nocheck
local q = require("./core"); local D = require("./dispatch")
-- RETUNE = true면 splice가 이동된 observer의 위치 인덱스를 실제 위치로 다시 맞춘다
local function run(RETUNE)
    local function spliceArraysDown(ownerKey, index)
        local bk = D.getBookkeeping(ownerKey)
        for i = index, bk.N - 1 do
            bk.lengthList[i] = bk.lengthList[i + 1]
            bk.sourceList[i] = bk.sourceList[i + 1]
            bk.observers[i]  = bk.observers[i + 1]
        end
        bk.lengthList[bk.N] = nil; bk.sourceList[bk.N] = nil; bk.observers[bk.N] = nil
        bk.N -= 1
        bk.invalidAfter = math.min(bk.invalidAfter, index)
        if RETUNE then
            for i = index, bk.N do
                local o = bk.observers[i]
                if o and o.box then o.box.pos = i end
            end
        end
    end
    local owner, s = {}, {}
    for i = 1, 3 do s[i] = D.newSlot("s" .. i) end
    local bl = D.getBlocker(owner); bl:On()
    for i = 1, 3 do
        D.setOffsetSource(owner, i, s[i].Offset)
        D.setLength(owner, i, s[i].Length, owner)
        s[i].Length:Set(1)
    end
    bl:OffWithoutEmit(); D.recompute(owner, D.getBookkeeping(owner))
    spliceArraysDown(owner, 1)
    D.recompute(owner, D.getBookkeeping(owner))
    s[2].Length:Set(5)
    print(("[%s] s3.Offset = %d (기대 5) | invalidAfter = %d")
        :format(if RETUNE then "위치 재조정함" else "확정 설계 그대로", s[3].Offset:Get(),
                D.getBookkeeping(owner).invalidAfter))
end
run(false)
run(true)
