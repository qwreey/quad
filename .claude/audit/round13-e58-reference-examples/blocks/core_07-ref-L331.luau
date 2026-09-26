local ref = q.Ref<<string?>>(nil)
task.spawn(function()
    local value = ref:Wait().Value -- 다음 :Set 까지 여기서 멈춘다
    print("도착", value)
end)
ref:Set("hello")
