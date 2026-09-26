-- source: SKILL.md:504-513
local function ProfileCard(userId: number): TextLabel
    return D.TextLabel { Text = `user {userId}` }   -- may error
end

local SafeProfile = q.Fallback(ProfileCard, function(err)
    return D.TextLabel { Text = "Failed to load profile" }
end)
local Traced = q.Traceback(ProfileCard, function(err, trace) return D.TextLabel { Text = trace } end)
