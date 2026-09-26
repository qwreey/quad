local function rounded(mod: any)
    return mod:BorderSizePixel(0):BackgroundTransparency(0.1)
end

local styled = q.Modifier():Apply(rounded)
