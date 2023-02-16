
local IS_TEST = true
local VER = "1.14" .. (IS_TEST and "B" or "")

if IS_TEST then
    warn("You are using BETA version of quad now. Many features may change in the future and unstable. AS USING BETA VERSION OF QUAD, YOU SHOULD KNOW IT WILL BUGGY SOMETIME. still on development - you can ignore this message if have no issue. if you have issue on using quad, please report issue on github. VERSION: "..VER)
end

return {
    version = VER
}
