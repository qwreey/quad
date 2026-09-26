local function AnimatedBox(): Frame
    return D.Frame {
        Size = UDim2.fromOffset(100, 100),

        q.OnCreated<<Frame>>(function(inst)
            print("생성됨:", inst.ClassName)
        end),

        q.OnRendered<<Frame>>(function(inst)
            print("자기 서브트리 완성:", inst.Size)
        end),

        q.OnDestroyed(function()
            print("파괴 및 정리됨")
        end),
    }
end
