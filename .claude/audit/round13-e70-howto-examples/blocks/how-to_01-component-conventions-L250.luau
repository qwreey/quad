local function CharacterBadge(props: { read Name: string, read Level: QuadTypes.StateMarker<number> }): Frame
    return D.Frame {
        -- [1] CollectionService 태그 (여러 자리의 요구를 합집합으로 관리)
        q.Tag("PlayerBadge", "Interactable"),

        -- [2] 어트리뷰트 그룹 — 값은 리터럴이어도 State여도 된다
        q.Attr {
            CharacterName = props.Name,
            Level = props.Level,
            Guild = "Alpha",
        },

        D.TextLabel {
            Text = props.Name,
        },
    }
end
