
# 화면에 UI 를 표시하기

일반적으로 *Quad* 모듈에서 모든 Parent 처리는 `#!ts Mount` 를 이용합니다. `#!ts Mount(to:any,...item:any?)->mounts` 함수를 이용하면 다루는 오브젝트가 로블록스 `Instance` 인지, 향후 소개될 Quad 확장 클래스인지 상관없이 알아서 Parent 가 처리됩니다.

```lua
--- StarterGui 안에 ScreenGui 를 넣고 로컬스크립트로 입력해보세요
local ScreenGUI = script.Parent
local Quad = require(path.to.module).Init()
local Class,Mount = Quad.Class,Quad.Mount

local Frame = Class "Frame"

Mount(ScreenGui,
    Frame {
        Name = "Wow!";
    }
    --[[
    , Frame {} , Frame {}
    더많은 오브젝트를 다같이 Mount 할 수 있습니다
    ]]
)
```

편의를 위해서 `Mount` 함수는 `mounts` 라는 객체를 반환합니다. 이것을 이용하면 필요에 따라서 Mount 상태를 해제하거나 추가 할 수 있습니다. `mounts` 객체는 다음과 같은 메소드를 가집니다.  

{!include/mounts.md!}

