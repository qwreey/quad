local desc = q.Source<<RobloxModule.OnChangeDescriptor>>(q.OnChange("Visible", function(v: boolean) end)) -- 클래스별 `FrameOnChange` 유니언은 루트에 재수출되지 않아 공개 경로가 없습니다([2026-09-27 기준])
local box = D.Frame({ desc })
