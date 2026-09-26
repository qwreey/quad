type ThemedProps = {
	read Modifier: RobloxModule.IntoTextButton?,
	read Text: string?,
}

local function Themed(props: ThemedProps): TextButton
	return D.TextButton({
		if props.Modifier then props.Modifier:AsTextButton() else q.None,
		Text = props.Text or "",
	})
end

Themed({ Modifier = D.Modifier.GuiObject():ZIndex(2), Text = "a" }) -- 조상 클래스도 OK
Themed({ Modifier = D.Modifier.TextButton():TextSize(18) })          -- 자기 클래스(항등 캐스트)
