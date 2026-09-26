-- source: references/code-recipes.md:194-239
local function RegistrationForm()
    local form = q.Store {
        Username = q.Source(""),
        Password = q.Source(""),
    }

    -- one compute node; both deps arrive as State handles
    local isValid = form.Username:Compute(function(self, prev, pwd)
        return #self:Get() >= 3 and #pwd:Get() >= 6
    end, form.Password)

    local submitColor = isValid:Compute(function(self)
        return if self:Get() then Color3.fromRGB(0, 180, 80) else Color3.fromRGB(80, 80, 80)
    end)

    return D.Frame {
        Size = UDim2.fromOffset(300, 200),

        D.TextBox {
            PlaceholderText = "Username (min 3 chars)",
            q.OnChange("Text", function(newText)
                form.Username:Set(newText)
            end),
        },

        D.TextBox {
            PlaceholderText = "Password (min 6 chars)",
            q.OnChange("Text", function(newText)
                form.Password:Set(newText)
            end),
        },

        D.TextButton {
            Text = "Submit",
            BackgroundColor3 = submitColor,
            AutoButtonColor = isValid,
            Activated = function()
                if isValid:Get() then
                    print("Submitting:", form.Username:Get())
                end
            end,
        },
    }
end
