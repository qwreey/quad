-- Styles.luau
local Theme = require("./Theme")

return {
    Button = D.Modifier.TextButton()
        :Size(UDim2.new(0, 120, 0, 40))
        :BackgroundColor3(Theme.Tokens.Accent)
        :BorderSizePixel(0),
}
