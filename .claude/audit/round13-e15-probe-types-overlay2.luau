--!strict
local q = require("./round13-e15-probe-types-settings")
local D = q.Declaration
type Toast = { Id: number, Text: string }
local function Card(props: { read Text: string }): Frame
    return D.Frame { D.TextLabel { Text = props.Text } }
end
local SafeCard = q.Fallback(Card, function(_err: any): Instance return D.Frame {} end)
local toasts = q.Source<<{ Toast }>>({})
-- V1 how-to 09 §4 verbatim element
q.Slot<<Instance>>():List(toasts, function(ctx): (any, nil)
    if ctx.Item == q.KeyGone then return nil, ctx.UserData end
    if ctx.Prev then return ctx.Prev, ctx.UserData end
    return D.TextLabel { Text = ctx.Item.Text }, ctx.UserData
end, function(item) return item.Id end)
-- V2 Fallback-wrapped component element
q.Slot<<Instance>>():List(toasts, function(ctx): (any, nil)
    if ctx.Item == q.KeyGone then return nil, ctx.UserData end
    if ctx.Prev then return ctx.Prev, ctx.UserData end
    return SafeCard { Text = ctx.Item.Text }, ctx.UserData
end, function(item) return item.Id end)
-- V3 plain (unwrapped) component element
q.Slot<<Instance>>():List(toasts, function(ctx): (any, nil)
    if ctx.Item == q.KeyGone then return nil, ctx.UserData end
    if ctx.Prev then return ctx.Prev, ctx.UserData end
    return Card { Text = ctx.Item.Text }, ctx.UserData
end, function(item) return item.Id end)
-- V4 Fallback-wrapped, text pulled into a typed local first
q.Slot<<Instance>>():List(toasts, function(ctx): (any, nil)
    if ctx.Item == q.KeyGone then return nil, ctx.UserData end
    if ctx.Prev then return ctx.Prev, ctx.UserData end
    local item = ctx.Item :: Toast
    return SafeCard { Text = item.Text }, ctx.UserData
end, function(item) return item.Id end)
