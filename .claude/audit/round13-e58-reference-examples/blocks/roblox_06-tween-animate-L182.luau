local alpha = q.Source(0)
local animated = alpha:Apply(q.Animate({ Time = 0.3, Style = Enum.EasingStyle.Quad }))

local reduceMotion = q.Source(false)
local guarded = alpha:Apply(q.Animate({
	Time = 0.3,
	CanAnimate = reduceMotion:Compute(function(self: q.StateData<boolean>): boolean
		return not self:Get()
	end),
}))

local box = D.Frame({ BackgroundTransparency = animated })
