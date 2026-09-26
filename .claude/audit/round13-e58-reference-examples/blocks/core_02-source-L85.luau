local hp = q.Source(100)
hp:Set(80):Set(60) -- self를 돌려주므로 이어 쓸 수 있다
print(hp:Get()) --> 60
