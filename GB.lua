local UIS = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")
local HttpService = game:GetService("HttpService")
local player = Players.LocalPlayer

----------------------------------------------------------------
-- 核心控制器
----------------------------------------------------------------
local AnimationController = {
    Character = player.Character or player.CharacterAdded:Wait(),
    Humanoid = nil
}

local function updateCharacterRefs(char)
    AnimationController.Character = char
    AnimationController.Humanoid = char:WaitForChild("Humanoid", 5)
end
player.CharacterAdded:Connect(updateCharacterRefs)
if player.Character then updateCharacterRefs(player.Character) end

----------------------------------------------------------------
-- 逻辑变量 (完整保留)
----------------------------------------------------------------
local killAuraActive = false
local espEnabled = false
local zombieEspEnabled = false
local attackBarrels = false
local autoRotateEnabled = false 
local attackDraculaEnabled = false
local killAuraConnection = nil

-- 飞行配置
local flying = false
local flySpeed = 50
local upPressed, downPressed = false, false
local flyBV, flyGyro, virtualLadder = nil, nil, nil

----------------------------------------------------------------
-- UI 核心构建 (包含所有移动端控制)
----------------------------------------------------------------
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "Gemini_Universal_UI_V1.8"
ScreenGui.ResetOnSpawn = false
ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
ScreenGui.Parent = game:GetService("CoreGui")

-- 移动端飞行控制按键 (▲/▼)
local flyUpBtn = Instance.new("TextButton")
local flyDownBtn = Instance.new("TextButton")

local function createMobileFlyControls()
    local btns = {flyUpBtn, flyDownBtn}
    local icons = {"▲", "▼"}
    local offsets = {-75, 15}
    
    for i, btn in ipairs(btns) do
        btn.Size = UDim2.new(0, 60, 0, 60)
        btn.Position = UDim2.new(0.85, -60, 0.5, offsets[i])
        btn.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
        btn.BackgroundTransparency = 0.5
        btn.Text = icons[i]
        btn.TextColor3 = Color3.new(1, 1, 1)
        btn.Font = Enum.Font.GothamBold
        btn.TextSize = 25
        btn.Visible = false
        btn.Parent = ScreenGui
        local corner = Instance.new("UICorner", btn)
        corner.CornerRadius = UDim.new(1, 0)
    end
end
createMobileFlyControls()

-- 切换主面板可见性按钮
local ToggleButton = Instance.new("TextButton")
ToggleButton.Size = UDim2.new(0, 80, 0, 30)
ToggleButton.Position = UDim2.new(0, 10, 0.5, -15)
ToggleButton.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
ToggleButton.BackgroundTransparency = 0.4
ToggleButton.Text = "显示/隐藏"
ToggleButton.TextColor3 = Color3.new(1, 1, 1)
ToggleButton.Font = Enum.Font.GothamMedium
ToggleButton.Draggable = true
ToggleButton.Parent = ScreenGui
Instance.new("UICorner", ToggleButton).CornerRadius = UDim.new(0, 8)

-- 主面板
local MainFrame = Instance.new("Frame")
MainFrame.Name = "MainFrame"
MainFrame.Size = UDim2.new(0, 220, 0, 420) -- 增加高度容纳新功能
MainFrame.Position = UDim2.new(0.5, -110, 0.5, -210)
MainFrame.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
MainFrame.Active = true
MainFrame.Draggable = true 
MainFrame.Parent = ScreenGui
Instance.new("UICorner", MainFrame).CornerRadius = UDim.new(0, 10)

local Title = Instance.new("TextLabel")
Title.Size = UDim2.new(1, 0, 0, 40)
Title.BackgroundColor3 = Color3.fromRGB(35, 35, 35)
Title.Text = "GB 圣赛四金牙 1.8 (稳定版)"
Title.TextColor3 = Color3.new(1, 1, 1)
Title.Font = Enum.Font.GothamBold
Title.TextSize = 14
Title.Parent = MainFrame
Instance.new("UICorner", Title)

-- 彻底销毁脚本
local CloseButton = Instance.new("TextButton")
CloseButton.Size = UDim2.new(0, 60, 0, 25)
CloseButton.Position = UDim2.new(1, -65, 0, 7)
CloseButton.BackgroundColor3 = Color3.fromRGB(150, 0, 0)
CloseButton.Text = "销毁脚本"
CloseButton.TextColor3 = Color3.new(1, 1, 1)
CloseButton.TextSize = 10
CloseButton.Parent = MainFrame
Instance.new("UICorner", CloseButton)

-- 滚动功能容器
local functionButtonContainer = Instance.new("ScrollingFrame")
functionButtonContainer.Size = UDim2.new(1, -10, 1, -50)
functionButtonContainer.Position = UDim2.new(0, 5, 0, 45)
functionButtonContainer.BackgroundTransparency = 1
functionButtonContainer.CanvasSize = UDim2.new(0, 0, 0, 600) 
functionButtonContainer.ScrollBarThickness = 2
functionButtonContainer.Parent = MainFrame

local UIListLayout = Instance.new("UIListLayout", functionButtonContainer)
UIListLayout.Padding = UDim.new(0, 6)
UIListLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center

local function createButton(name, text, color)
    local btn = Instance.new("TextButton")
    btn.Name = name
    btn.Size = UDim2.new(1, -10, 0, 35)
    btn.BackgroundColor3 = color
    btn.Text = text
    btn.TextColor3 = Color3.new(1, 1, 1)
    btn.Font = Enum.Font.GothamMedium
    btn.TextSize = 14
    btn.Parent = functionButtonContainer
    Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 6)
    return btn
end

----------------------------------------------------------------
-- 【功能重写】透视逻辑 (ESP)
----------------------------------------------------------------
local function clearESP(obj)
    if not obj then return end
    local hl = obj:FindFirstChild("GB_Highlight")
    if hl then hl:Destroy() end
    local tag = obj:FindFirstChild("GB_Tag")
    if tag then tag:Destroy() end
end

local function applyESP(model, name, color)
    clearESP(model)
    -- 穿墙高亮
    local hl = Instance.new("Highlight")
    hl.Name = "GB_Highlight"
    hl.FillColor = color
    hl.OutlineColor = Color3.new(1, 1, 1)
    hl.FillTransparency = 0.5
    hl.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
    hl.Parent = model
    
    -- 名字标签
    local head = model:FindFirstChild("Head") or model:FindFirstChild("HumanoidRootPart")
    if head then
        local bg = Instance.new("BillboardGui")
        bg.Name = "GB_Tag"
        bg.Size = UDim2.new(0, 150, 0, 50)
        bg.StudsOffset = Vector3.new(0, 3, 0)
        bg.AlwaysOnTop = true
        bg.Parent = model
        
        local tl = Instance.new("TextLabel")
        tl.Size = UDim2.new(1, 0, 1, 0)
        tl.BackgroundTransparency = 1
        tl.Text = name
        tl.TextColor3 = color
        tl.Font = Enum.Font.GothamBold
        tl.TextSize = 13
        tl.TextStrokeTransparency = 0
        tl.Parent = bg
    end
end

local function updateESP()
    -- 玩家透视
    for _, p in ipairs(Players:GetPlayers()) do
        if espEnabled and p ~= player and p.Character then
            applyESP(p.Character, p.DisplayName, p.TeamColor.Color)
        elseif not espEnabled then
            if p.Character then clearESP(p.Character) end
        end
    end
    -- 僵尸透视
    local zs = workspace:FindFirstChild("Zombies")
    if zs then
        for _, z in ipairs(zs:GetChildren()) do
            if zombieEspEnabled and z:FindFirstChild("HumanoidRootPart") then
                applyESP(z, z.Name, Color3.fromRGB(255, 50, 50))
            elseif not zombieEspEnabled then
                clearESP(z)
            end
        end
    end
end

----------------------------------------------------------------
-- 【功能重写】注入逻辑
----------------------------------------------------------------
local function injectExternal()
    local url = "https://raw.githubusercontent.com/ANMO-B/GB-dsfcxrgxzzffxxxfgvc---gxdfc-/c0a977f50939fe962a3747627513fce2811e1c77/GB%20By.lua"
    task.spawn(function()
        local success, result = pcall(function()
            return game:HttpGet(url)
        end)
        if success then
            loadstring(result)()
        else
            warn("脚本拉取失败，请检查网络或执行器环境")
        end
    end)
end

----------------------------------------------------------------
-- 战斗与飞行核心 (保持完整)
----------------------------------------------------------------
local function getMelee()
    local char = AnimationController.Character
    if not char then return nil end
    for _, item in pairs(char:GetChildren()) do if item:GetAttribute("Melee") then return item end end
    for _, item in pairs(player.Backpack:GetChildren()) do if item:GetAttribute("Melee") then return item end end
    return nil
end

local function performAttack(target, isDracula)
    local weapon = getMelee()
    if not weapon or not target:FindFirstChild("Head") then return end
    local range = (weapon.Name == "Pike") and 11 or (weapon.Name == "Axe" and 9 or 10)
    if weapon.Parent ~= AnimationController.Character then weapon.Parent = AnimationController.Character end
    
    if autoRotateEnabled then
        local pos = target.HumanoidRootPart.Position
        AnimationController.Character.HumanoidRootPart.CFrame = CFrame.lookAt(AnimationController.Character.HumanoidRootPart.Position, Vector3.new(pos.X, AnimationController.Character.HumanoidRootPart.Position.Y, pos.Z))
    end
    
    local dist = (target.HumanoidRootPart.Position - AnimationController.Character.HumanoidRootPart.Position).Magnitude
    if dist <= range then
        weapon.RemoteEvent:FireServer("Swing", "Side")
        weapon.RemoteEvent:FireServer("HitZombie", target, target.Head.Position, true, isDracula and "Head" or nil)
    end
end

local function toggleFly()
    flying = not flying
    flyUpBtn.Visible = flying
    flyDownBtn.Visible = flying
    local char = AnimationController.Character
    local root = char and char:FindFirstChild("HumanoidRootPart")
    local hum = char and char:FindFirstChildOfClass("Humanoid")
    if not root or not hum then return end

    if flying then
        flyBV = Instance.new("BodyVelocity", root)
        flyBV.MaxForce = Vector3.new(1e7, 1e7, 1e7)
        flyGyro = Instance.new("BodyGyro", root)
        flyGyro.MaxTorque = Vector3.new(1e7, 1e7, 1e7)

        task.spawn(function()
            while flying and char.Parent do
                hum:ChangeState(Enum.HumanoidStateType.Climbing)
                local velocity = hum.MoveDirection * flySpeed
                if upPressed then velocity = velocity + Vector3.new(0, flySpeed, 0)
                elseif downPressed then velocity = velocity + Vector3.new(0, -flySpeed, 0) end
                flyBV.Velocity = velocity
                flyGyro.CFrame = workspace.CurrentCamera.CFrame
                RunService.Heartbeat:Wait()
            end
            if flyBV then flyBV:Destroy() end
            if flyGyro then flyGyro:Destroy() end
            hum:ChangeState(Enum.HumanoidStateType.Running)
        end)
    end
end

----------------------------------------------------------------
-- UI 交互与按钮绑定
----------------------------------------------------------------

-- 1. 注入脚本
local injectBtn = createButton("InjectBtn", "注入外部脚本 (完全体)", Color3.fromRGB(120, 0, 200))
injectBtn.MouseButton1Click:Connect(function()
    injectExternal()
    injectBtn.Text = "注入成功"
    task.wait(1)
    injectBtn.Text = "再次注入"
end)

-- 2. 杀戮光环
local killAuraBtn = createButton("KillAura", "杀戮光环: 关闭", Color3.fromRGB(80, 80, 80))
killAuraBtn.MouseButton1Click:Connect(function()
    killAuraActive = not killAuraActive
    killAuraBtn.Text = killAuraActive and "杀戮光环: 运行中" or "杀戮光环: 关闭"
    killAuraBtn.BackgroundColor3 = killAuraActive and Color3.fromRGB(0, 120, 255) or Color3.fromRGB(80, 80, 80)
    
    if killAuraActive then
        killAuraConnection = RunService.Heartbeat:Connect(function()
            if not killAuraActive or not AnimationController.Character then return end
            local zs = workspace:FindFirstChild("Zombies")
            if zs then
                for _, z in pairs(zs:GetChildren()) do
                    if z:FindFirstChild("HumanoidRootPart") and (z.HumanoidRootPart.Position - AnimationController.Character.HumanoidRootPart.Position).Magnitude <= 12 then
                        performAttack(z, false)
                    end
                end
            end
        end)
    else
        if killAuraConnection then killAuraConnection:Disconnect() end
    end
end)

-- 3. 玩家透视
local espBtn = createButton("PlayerESP", "玩家透视: 关闭", Color3.fromRGB(80, 80, 80))
espBtn.MouseButton1Click:Connect(function()
    espEnabled = not espEnabled
    espBtn.Text = espEnabled and "玩家透视: 开启" or "玩家透视: 关闭"
    espBtn.BackgroundColor3 = espEnabled and Color3.fromRGB(0, 150, 0) or Color3.fromRGB(80, 80, 80)
end)

-- 4. 僵尸透视
local zEspBtn = createButton("ZombieESP", "僵尸透视: 关闭", Color3.fromRGB(80, 80, 80))
zEspBtn.MouseButton1Click:Connect(function()
    zombieEspEnabled = not zombieEspEnabled
    zEspBtn.Text = zombieEspEnabled and "僵尸透视: 开启" or "僵尸透视: 关闭"
    zEspBtn.BackgroundColor3 = zombieEspEnabled and Color3.fromRGB(150, 0, 0) or Color3.fromRGB(80, 80, 80)
end)

-- 5. 飞行模式
local flyBtn = createButton("FlyBtn", "飞行模式: 关闭", Color3.fromRGB(60, 60, 60))
flyBtn.MouseButton1Click:Connect(function()
    toggleFly()
    flyBtn.Text = "飞行模式: " .. (flying and "开启" or "关闭")
    flyBtn.BackgroundColor3 = flying and Color3.fromRGB(0, 150, 200) or Color3.fromRGB(60, 60, 60)
end)

-- 6. 自动转向
local autoRotateBtn = createButton("AutoRotate", "自动转向: 关闭", Color3.fromRGB(60, 60, 60))
autoRotateBtn.MouseButton1Click:Connect(function()
    autoRotateEnabled = not autoRotateEnabled
    autoRotateBtn.Text = "自动转向: " .. (autoRotateEnabled and "开启" or "关闭")
end)

----------------------------------------------------------------
-- 循环更新任务
----------------------------------------------------------------
RunService.RenderStepped:Connect(function()
    updateESP()
end)

-- 飞行按键交互
flyUpBtn.MouseButton1Down:Connect(function() upPressed = true end)
flyUpBtn.MouseButton1Up:Connect(function() upPressed = false end)
flyDownBtn.MouseButton1Down:Connect(function() downPressed = true end)
flyDownBtn.MouseButton1Up:Connect(function() downPressed = false end)

ToggleButton.MouseButton1Click:Connect(function() MainFrame.Visible = not MainFrame.Visible end)

CloseButton.MouseButton1Click:Connect(function()
    flying = false
    killAuraActive = false
    espEnabled = false
    zombieEspEnabled = false
    if killAuraConnection then killAuraConnection:Disconnect() end
    ScreenGui:Destroy()
end)
