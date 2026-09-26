--!strict
-- E15 (e) — how-to 09 §4+§5 combined: Fallback-wrapped Card as the toast element inside the toast updateFn + ErrorModal + Context trigger.
local q = require("./round13-e15-probe-types-settings")
local D = q.Declaration
type Toast = { Id: number, Text: string }
local function Card(props: { read Text: string }): Frame
    if props.Text == "" then
        error("Card: Text must not be empty")
    end
    return D.Frame { D.TextLabel { Text = props.Text } }
end
local errorState = q.Source<<any>>(nil)
local function onError(err: any): Instance
    errorState:Set(err)
    return D.Frame {}
end
local SafeCard = q.Fallback(Card, onError)
local toasts = q.Source<<{ Toast }>>({})
local toastList = q.Slot<<Instance>>()
toastList:List(toasts, function(ctx): (any, nil)
    if ctx.Item == q.KeyGone then
        return nil, ctx.UserData
    end
    if ctx.Prev then
        return ctx.Prev, ctx.UserData
    end
    return SafeCard { Text = ctx.Item.Text }, ctx.UserData
end, function(item)
    return item.Id
end)
export type ModalBag = { Open: q.Source<boolean> }
local ModalProvider = q.Context.Provider<<ModalBag>>("Modal")
local open = q.Source(false)
local ctx = q.Context():Set(ModalProvider, { Open = open })
local function DeleteButton(props: { read Ctx: q.Context }): TextButton
    local modal = props.Ctx:Get(ModalProvider)
    return D.TextButton {
        Text = "삭제",
        Activated = function()
            modal.Open:Set(true)
            local nxt = table.clone(toasts:Get())
            table.insert(nxt, { Id = #nxt + 1, Text = "" })
            toasts:Set(nxt)
        end,
    }
end
local visible: q.State<boolean> = errorState:Compute(function(e) return e:Get() ~= nil end)
local screen = D.ScreenGui {
    DeleteButton { Ctx = ctx },
    D.Frame { D.UIListLayout { Padding = UDim.new(0, 4) }, toastList },
    D.Frame { Visible = visible },
}
local _ = screen
