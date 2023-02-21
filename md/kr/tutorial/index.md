
# Getting Started

!!! example "실험적인 모듈"
    이 모듈은 업데이트가 빈번합니다! 항상 Github 를 확인해주세요!

---

## 머리말

이 페이지는 Quad 모듈을 쉽게 시작할 수 있도록 튜토리얼을 제공하고 있습니다. 이 페이지를 정독해 Quad 모듈의 전반적인 사용법을 파악해보세요!  

[변경 사항은 여기](changelogs)에서 확인할 수 있습니다.  

---

## 설치

3가지 방법중 가장 편한 방법을 선택해 모듈을 설치해주세요.  

### 드레그 엔 드롭 / rbxmx 파일

드레그해 스튜디오에 넣을 수 있는 모듈 파일입니다.  

[RBXMX 다운로드](https://github.com/qwreey75/Quad/releases/latest/download/Quad.rbxmx){ .md-button .md-button--primary }  

다운로드해 스튜디오에 옮겨주세요.  

### git clone

rojo 를 사용해 빌드하는 방법을 사용할 수 있다면 Quad 를 직접 빌드할 수 있습니다.  

```sh
git clone https://github.com/qwreey75/Quad Quad
cd Quad
make build
```

==윈도우의 경우 `make build` 대신 `rojo build default.project.json -o output.rbxmx` 를 입력해 주어야 합니다.==  

### git submodule

프로젝트가 rojo 를 사용하고 git 을 사용하는 경우 submodule 로 추가할 수 있습니다.  

```sh
# 이미 submodule 을 사용하고 있는 경우 입력할 필요가 없습니다
git submodule init
# 서브모듈의 루트는 직접 정해주세요
git submodule add https://github.com/qwreey75/Quad Quad
```

---

## 모듈 불러오기/초기화

```lua
local Quad = require(path.to.module).Init()
```

모듈을 셋업하기 위해서는 `#!ts .Init(QuadId:string?)` 을 이용합니다. 일반적으로 `QuadId` 값은 필요하지 않지만, 나중에 소개할 Store 와 같은 일부 기능들이 `#!ts QuadId:string` 에 영향받기도 합니다.  

`#!ts .Init(QuadId:string)` 함수는 `QuadId` 가 같은 불러오기가 이미 있었던 경우, 초기화 하지 않고 불러왔던것을 반환합니다.  
따라서 모듈들 끼리 `QuadId` 가 같은 경우 Store 같은것들이 공유됩니다.  

`QuadId` 가 비워진 경우 한번도 생성된 적 없는 새로운 Quad 가 생성됩니다  

```lua
local Quad = require(path.to.module).Init()
local Class = Quad.Class
```

불러오기가 끝났다면 이제 Quad 의 자원들을 이용할 수 있습니다!  
[다음 페이지로 넘어가 어서 활용해 봅시다](./1_import)

---

## 추가적 환경 설정

### 타입 불러오기

기본적으로 이 모듈은 로드시 타입을 반환하지만. 직접적으로 타입을 지정하고 싶은 경우 types.lua 를 불러올 수 있습니다  

```lua
local types = require(path.to.module.types)
local Quad = (require(path.to.module)::types.module).Init()
```

---

## 테스트 환경 준비

테스트 환경은 rojo 와의 개발통합을 위해 Play 버튼을 누르지 않고 미리보기를 사용할 수 있도록 만들어줍니다  
이를 통해 다른 코드 방식의 UI 프레임 워크보다 빠른 개발속도를 달성할 수 있습니다  

편의상을 위해 자동 리로드를 설정해 줄 수 있습니다.  

???+ Warning "주의"

    ==rojo 환경이 아니라면 자동 리로드는 랙을 동반할 수 있습니다==  
    > 일반적으로, 로컬 편집 환경에서 로블록스의 script editor 는 한글자 한글자 변경시 마다 .Source 를 업데이트합니다. 이는 곳 한글자 한글자 타이핑 시 마다 UI 가 업데이트 될 수 있음을 의미합니다. Quad 의 tracker 모듈은 순간적으로 많은양의 리로드가 발생하지 않도록 적절한 쿨타임과 시간분배를 가지고 있지만, 이 경우에도 Ctrl+S 를 눌러 저장해야 적용되는 vscode 와 같은 타 편집기와는 차이가 날 수 있습니다. 코드가 커짐으로 인해 자동 리로드에서 퍼포먼스적 이슈를 겪는다면, rojo 를 활용해 코드를 외부로 옮긴 후, vscode 를 스튜디오 위에 놓고 미리보기와 코드를 동시에 보면서 편집하세요.  
    > 프로젝트가 매우 거대하지 않다면 크게 걱정하지 않아도 됩니다.  

다음과 같은 코드트리를 만들어주세요.

```
 | Main (ModuleScript)
 |-- Loader (LocalScript)
 |-- Test (ModuleScript)
```

=== "Main"

    ```lua title="실제로 UI 들을 그리는 코드들이 담깁니다."
    local Quad = require(path.to.module).Init()
    local LocalPlayer = game.Players.LocalPlayer
    local ScreenGUI = Instance.new("ScreenGui",
        LocalPlayer and LocalPlayer.PlayerGui or game.StarterGui)
    ScreenGUI.Name = "MyGUI"
    ScreenGUI.ResetOnSpawn = false

    -- 실제 그리는 코드들이 들어갑니다.

    return function()
        -- 테스트가 끝나 만든걸 지워야 할 때 사용됩니다.
        -- 추후 설명될 Unmount() 를 이용하세요.
        ScreenGUI:Destroy()
    end
    ```

=== "Loader"

    ```lua title="게임을 플레이 할 때 코드가 로드될 수 있도록 만드는 로더입니다."
    require(script.Parent)
    ```

=== "Test"

    ```lua title="명령창에서 명령어 입력으로 테스트를 실행 할 수 있도록 만드는 코드들이 담깁니다."
    -- 모듈 위치로 알맞게 변경해주세요
    local Quad = path.to.module
    local tracker = require(Quad.tracker)

    local module = {}
    local function reload()
        if module.unload then pcall(module.unload) end
        if module.testingModule then pcall(module.testingModule.Destroy,module.testingModule) end
        module.testingModule = script.Parent:Clone()
        module.testingModule.Parent = script.Parent.Parent
        module.testingModule.Archivable = false
        module.testingModule.Name = module.testingModule.Name .. "_TESTING"
        module.unload = require(module.testingModule)
    end

    -- 자동 리로드를 켭니다. 이미 켜져있으면 다시 로드합니다
    function module.load()
        reload()
        if not module.autoreload then
            module.autoreload = tracker.new(script.Parent)
            module.autoreload:init(); wait()
            module.autoreload:connect("updated",reload)
        end
    end

    -- 자동 리로드를 끄고 테스트로 생긴것을 지웁니다
    function module.unload()
        if module.autoreload then pcall(module.autoreload.deinit,module.autoreload) end
        if module.unload then pcall(module.unload) end
        if module.testingModule then pcall(module.testingModule.Destroy,module.testingModule) end
        module.autoreload = nil
        module.unload = nil
        module.testingModule = nil
    end

    return module
    ```

이제 명령어 창에서 자동 리로드를 켜거나 끌 수 있습니다. rojo 나 편집기로 인해 코드가 변경되면 자동으로 업데이트됩니다!

```lua
require(path.to.your.module).load()
```
