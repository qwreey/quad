-- source: SKILL.md:375-396
local hoverSrc, targetSrc = q.Source(false), q.Source(UDim2.new())

-- Animate: applicative sugar over a derived State
local btnColor = hoverSrc:Compute(function(self)
    return if self:Get() then Color3.fromRGB(60, 60, 60) else Color3.fromRGB(35, 35, 35)
end):Apply(q.Animate { Time = 0.2, Style = Enum.EasingStyle.Quad })

-- Tween: a first-class value emitted from a Compute
local flash = q.Source(false)
local positionState = targetSrc:Compute(function(self)
    return q.Tween {
        Value = self:Get(),   -- plain value; a State here errors
        Time = 0.5,
        Override = "Cancel",  -- "Cancel" (default) or "Finish"
        Dedup = true,         -- skip when the target equals the recorded one
        Started = function() flash:Set(true) end,     -- all three: () -> (), no args
        Completed = function() flash:Set(false) end,
        Cancelled = function() flash:Set(false) end,
    }
end)
