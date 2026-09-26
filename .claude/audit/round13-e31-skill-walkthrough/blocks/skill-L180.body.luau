-- source: SKILL.md:180-201
export type ButtonProps = {
    Text: string | QuadTypes.State<string>,
    -- the handler type must match the engine signature exactly, arity included
    OnClick: (inputObject: InputObject, clickCount: number) -> (),
    Modifier: any?,   -- or DeclarationModule.IntoTextButton for a typed boundary
}

local function Button(props: ButtonProps)
    return D.TextButton {
        -- 1. inline properties (highest priority)
        Text = props.Text,
        AutoButtonColor = true,

        -- 2. events: engine arguments only, no `self`
        Activated = props.OnClick,

        -- 3. modifiers / children in the array part
        props.Modifier or q.None,
    }
end
