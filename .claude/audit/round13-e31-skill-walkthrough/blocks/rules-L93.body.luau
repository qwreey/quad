-- source: references/rules-and-invariants.md:93-99
D.TextBox {
    q.OnChange("Text", function(newText: string)
        print("Text changed to:", newText)
    end),
}
