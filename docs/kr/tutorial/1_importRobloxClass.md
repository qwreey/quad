
# 로블록스 오브젝트 불러오기

Frame 과 같은 UI 오브젝트를 만들고 싶은 경우 먼저 import 를 이용해주어야 합니다.
다음과 같이 입력해보세요!

```lua
local Quad = require(path.to.module).Init()
local Class = Quad.Class

local Frame = Class "Frame"

print(
    Frame {
        Name = "Wow!";
        -- 다음과 같이 자식을 추가할 수 있습니다
        Frame {
            Name = "Child";
        };
    }
)
```

나중에 자신만의 UI 오브젝트를 생성할 수 있지만, 일반적인 로블록스가 지원하는 오브젝트의 경우 `Class(ClassName:string)` 으로 불러올 수 있습니다  

불러온 Class 에 기본값을 설정할 수도 있습니다  

```lua
local Quad = require(path.to.module).Init()
local Class = Quad.Class

local FrameWithoutBorder = Class "Frame"
FrameWithoutBorder.BorderSizePixel = 0

local FrameWithBorder = Class "Frame"
FrameWithBorder.BorderSizePixel = 1

local frame1 = FrameWithoutBorder {}
local frame2 = FrameWithBorder {}
print(frame1.FrameWithBorder)
print(frame2.FrameWithBorder)
```

이제 그려낸 프레임을 화면에 그려보고 싶나요? 다음 튜토리얼 Mount 를 확인해보세요!

[다음 튜토리얼](./2_mount)
