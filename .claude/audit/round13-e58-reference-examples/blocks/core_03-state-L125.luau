local text = q.Source("hello")
local locale = q.Source("ko")

-- text의 값 그대로, 다만 locale이 바뀌어도 다시 흐른다
local shown: q.State<string> = text:Depend(locale)
print(shown:Get()) --> hello
