q.Bookkeeping.setOffsetSource(ownerKey, position, q.None) -- 1. 발행 채널을 먼저 끊는다
q.Bookkeeping.setLength(ownerKey, position, 0)            -- 2. 길이를 0으로 접고 재계산
