local UIS = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")
local player = Players.LocalPlayer

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
-- UI 构建 (包含移动端飞行控制)
----------------------------------------------------------------

local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "Gemini_Universal_UI"
ScreenGui.ResetOnSpawn = false
ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
ScreenGui.Parent = game:GetService("CoreGui")

-- 移动端飞行控制按键 (▲/▼)
local flyUpBtn = Instance.new("TextButton")
local flyDownBtn = Instance.new("TextButton")

local function createMobileFlyControls()
    local btns = {flyUpBtn, flyDownBtn}
    local icons = {"上", "下"}
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

-- 隐藏/显示切换按钮
local ToggleButton = Instance.new("TextButton")
ToggleButton.Name = "ToggleButton"
ToggleButton.Size = UDim2.new(0, 80, 0, 30)
ToggleButton.Position = UDim2.new(0, 10, 0.5, -15)
ToggleButton.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
ToggleButton.BackgroundTransparency = 0.4
ToggleButton.Text = "显示/隐藏"
ToggleButton.TextColor3 = Color3.fromRGB(255, 255, 255)
ToggleButton.Font = Enum.Font.GothamMedium
ToggleButton.TextSize = 12
ToggleButton.Draggable = true
ToggleButton.Parent = ScreenGui
local ToggleCorner = Instance.new("UICorner", ToggleButton)
ToggleCorner.CornerRadius = UDim.new(0, 8)

-- 主面板
local MainFrame = Instance.new("Frame")
MainFrame.Name = "MainFrame"
MainFrame.Size = UDim2.new(0, 200, 0, 320)
MainFrame.Position = UDim2.new(0.5, -100, 0.5, -160)
MainFrame.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
MainFrame.BorderSizePixel = 0
MainFrame.Active = true
MainFrame.Draggable = true 
MainFrame.Parent = ScreenGui
local MainCorner = Instance.new("UICorner", MainFrame)
MainCorner.CornerRadius = UDim.new(0, 10)

local Title = Instance.new("TextLabel")
Title.Size = UDim2.new(1, 0, 0, 40)
Title.BackgroundColor3 = Color3.fromRGB(35, 35, 35)
Title.Text = "GB 圣赛四金牙 1.8"
Title.TextColor3 = Color3.fromRGB(255, 255, 255)
Title.Font = Enum.Font.GothamBold
Title.TextSize = 15
Title.Parent = MainFrame
local TitleCorner = Instance.new("UICorner", Title)

-- 彻底关闭按钮
local CloseButton = Instance.new("TextButton")
CloseButton.Name = "CloseButton"
CloseButton.Size = UDim2.new(0, 60, 0, 25)
CloseButton.Position = UDim2.new(1, -70, 0, 10)
CloseButton.BackgroundColor3 = Color3.fromRGB(150, 0, 0)
CloseButton.Text = "销毁脚本"
CloseButton.TextColor3 = Color3.fromRGB(255, 255, 255)
CloseButton.Font = Enum.Font.GothamMedium
CloseButton.TextSize = 10
CloseButton.Parent = ScreenGui
local CloseCorner = Instance.new("UICorner", CloseButton)

-- 按钮容器
local functionButtonContainer = Instance.new("ScrollingFrame")
functionButtonContainer.Size = UDim2.new(1, -10, 1, -50)
functionButtonContainer.Position = UDim2.new(0, 5, 0, 45)
functionButtonContainer.BackgroundTransparency = 1
functionButtonContainer.CanvasSize = UDim2.new(0, 0, 0, 450) 
functionButtonContainer.ScrollBarThickness = 2
functionButtonContainer.Parent = MainFrame

local UIListLayout = Instance.new("UIListLayout", functionButtonContainer)
UIListLayout.Padding = UDim.new(0, 6)
UIListLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
UIListLayout.SortOrder = Enum.SortOrder.LayoutOrder

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
    local corner = Instance.new("UICorner", btn)
    corner.CornerRadius = UDim.new(0, 6)
    return btn
end

----------------------------------------------------------------
-- 逻辑变量与飞行配置
----------------------------------------------------------------

local killAuraActive = false
local espEnabled = false
local zombieEspEnabled = false
local attackBarrels = false
local autoRotateEnabled = false 
local attackDraculaEnabled = false
local killAuraConnection = nil

local playerHighlights = {}
local zombieHighlights = {}

-- 飞行变量
local flying = false
local flySpeed = 50
local upPressed, downPressed = false, false
local flyBV, flyGyro, virtualLadder = nil, nil, nil

----------------------------------------------------------------
-- 飞行核心逻辑 (防拉回适配)
----------------------------------------------------------------

local function toggleFly()
    local char = AnimationController.Character
    local root = char and char:FindFirstChild("HumanoidRootPart")
    local hum = char and char:FindFirstChildOfClass("Humanoid")
    if not root or not hum then return end

    flying = not flying
    flyUpBtn.Visible = flying
    flyDownBtn.Visible = flying
    
    if flying then
        -- 针对无梯子地图创建物理锚点
        virtualLadder = Instance.new("Part")
        virtualLadder.Name = "FlyAnchor"
        virtualLadder.Size = Vector3.new(4, 4, 1)
        virtualLadder.Transparency = 1
        virtualLadder.CanCollide = false
        virtualLadder.Parent = char
        
        local weld = Instance.new("Weld", virtualLadder)
        weld.Part0 = root
        weld.Part1 = virtualLadder
        weld.C0 = CFrame.new(0, 0, 0.5)
        
        flyBV = Instance.new("BodyVelocity", root)
        flyBV.MaxForce = Vector3.new(1e7, 1e7, 1e7)
        
        flyGyro = Instance.new("BodyGyro", root)
        flyGyro.MaxTorque = Vector3.new(1e7, 1e7, 1e7)

        task.spawn(function()
            while flying and char.Parent do
                -- 强制 Climbing 状态绕过反作弊
                hum:ChangeState(Enum.HumanoidStateType.Climbing)
                
                local moveDir = hum.MoveDirection
                local cam = workspace.CurrentCamera
                
                local velocity = moveDir * flySpeed
                if upPressed then velocity = velocity + Vector3.new(0, flySpeed, 0)
                elseif downPressed then velocity = velocity + Vector3.new(0, -flySpeed, 0) end
                
                flyBV.Velocity = velocity
                flyGyro.CFrame = cam.CFrame
                RunService.Heartbeat:Wait()
            end
            if flyBV then flyBV:Destroy() end
            if flyGyro then flyGyro:Destroy() end
            if virtualLadder then virtualLadder:Destroy() end
            hum:ChangeState(Enum.HumanoidStateType.Running)
        end)
    end
end

----------------------------------------------------------------
-- 原有核心攻击逻辑
----------------------------------------------------------------

local function getMelee()
    local char = AnimationController.Character
    if not char then return nil end
    for _, item in pairs(char:GetChildren()) do if item:GetAttribute("Melee") then return item end end
    for _, item in pairs(player.Backpack:GetChildren()) do if item:GetAttribute("Melee") then return item end end
    return nil
end

local function distance(target)
    if not AnimationController.Character or not target or not target:FindFirstChild("HumanoidRootPart") then return math.huge end
    return (target.HumanoidRootPart.Position - AnimationController.Character.HumanoidRootPart.Position).magnitude
end

local function performAttack(target, isDracula)
    local weapon = getMelee()
    if not weapon or not target:FindFirstChild("Head") then return end
    local range = (weapon.Name == "Pike") and 11 or (weapon.Name == "Axe" and 9 or 10)
    if weapon.Parent ~= AnimationController.Character then weapon.Parent = AnimationController.Character task.wait(0.05) end
    if autoRotateEnabled then
        local pos = target.HumanoidRootPart.Position
        AnimationController.Character.HumanoidRootPart.CFrame = CFrame.lookAt(AnimationController.Character.HumanoidRootPart.Position, Vector3.new(pos.X, AnimationController.Character.HumanoidRootPart.Position.Y, pos.Z))
    end
    if weapon.Name == "Axe" and target:FindFirstChild("State") and target.State.Value ~= "Stunned" then
        weapon.RemoteEvent:FireServer("BraceBlock")
        weapon.RemoteEvent:FireServer("StopBraceBlock")
        weapon.RemoteEvent:FireServer("FeedbackStun", target, target.HumanoidRootPart.Position)
    end
    if distance(target) <= range then
        weapon.RemoteEvent:FireServer("Swing", "Side")
        weapon.RemoteEvent:FireServer("HitZombie", target, target.Head.Position, true, isDracula and "Head" or nil)
    end
end

----------------------------------------------------------------
-- ESP 逻辑 (保持原样)
----------------------------------------------------------------

local function getZombieColor(zombie)
    local name = zombie.Name:lower()
    if name:find("dracula") or name:find("boss") then return Color3.fromRGB(170, 0, 255) end
    if name:find("tank") or name:find("brute") then return Color3.fromRGB(255, 120, 0) end
    return Color3.fromRGB(255, 50, 50)
end

local function createBillboard(parent, text, color)
    local billboard = Instance.new("BillboardGui")
    billboard.Name = "CustomESPNameTag"
    billboard.Size = UDim2.new(0, 200, 0, 50)
    billboard.StudsOffset = Vector3.new(0, 3, 0)
    billboard.AlwaysOnTop = true
    billboard.Adornee = parent:FindFirstChild("Head") or parent:FindFirstChild("HumanoidRootPart")
    billboard.Parent = parent
    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(1, 0, 1, 0)
    label.BackgroundTransparency = 1
    label.Text = text
    label.TextColor3 = color
    label.Font = Enum.Font.GothamBold
    label.TextSize = 14
    label.TextStrokeTransparency = 0.5
    label.Parent = billboard
end

local function removeESP(obj, list)
    if list[obj] then list[obj]:Destroy() list[obj] = nil end
    local tag = obj:FindFirstChild("CustomESPNameTag")
    if tag then tag:Destroy() end
end

local function updateAllESP()
    for _, p in ipairs(Players:GetPlayers()) do
        if espEnabled and p ~= player then
            local char = p.Character
            if char and not playerHighlights[p] then
                local hl = Instance.new("Highlight", char)
                hl.FillColor = p.TeamColor.Color
                playerHighlights[p] = hl
                createBillboard(char, p.DisplayName, p.TeamColor.Color)
            end
        else removeESP(p.Character or p, playerHighlights) end
    end
end

----------------------------------------------------------------
-- UI 按钮实例化与交互
----------------------------------------------------------------

local killAuraButton = createButton("KillAura", "杀戮光环", Color3.fromRGB(80, 80, 80))
local flyButton = createButton("FlyBtn", "飞行模式: 关闭", Color3.fromRGB(60, 60, 60))
local espButton = createButton("PlayerESP", "开启玩家透视", Color3.fromRGB(80, 80, 80))
local zombieEspButton = createButton("ZombieESP", "透视僵尸", Color3.fromRGB(80, 80, 80))
local noBarrelsButton = createButton("NoBarrels", "攻击炸药桶: 取消", Color3.fromRGB(60, 60, 60))
local autoRotateButton = createButton("AutoRotate", "自动转向: 关闭", Color3.fromRGB(60, 60, 60))
local attackDraculaButton = createButton("AttackDracula", "攻击德古拉: 关闭", Color3.fromRGB(60, 60, 60))

noBarrelsButton.Visible = false
autoRotateButton.Visible = false
attackDraculaButton.Visible = false

-- 飞行按键逻辑
flyUpBtn.MouseButton1Down:Connect(function() upPressed = true end)
flyUpBtn.MouseButton1Up:Connect(function() upPressed = false end)
flyDownBtn.MouseButton1Down:Connect(function() downPressed = true end)
flyDownBtn.MouseButton1Up:Connect(function() downPressed = false end)

flyButton.MouseButton1Click:Connect(function()
    toggleFly()
    flyButton.Text = "飞行模式: " .. (flying and "开启" or "关闭")
    flyButton.BackgroundColor3 = flying and Color3.fromRGB(0, 150, 200) or Color3.fromRGB(60, 60, 60)
end)

-- 杀戮光环逻辑
killAuraButton.MouseButton1Click:Connect(function()
    killAuraActive = not killAuraActive
    killAuraButton.Text = killAuraActive and "杀戮光环: 运行中" or "杀戮光环: 已关闭"
    killAuraButton.BackgroundColor3 = killAuraActive and Color3.fromRGB(0, 120, 255) or Color3.fromRGB(80, 80, 80)
    noBarrelsButton.Visible = killAuraActive; autoRotateButton.Visible = killAuraActive; attackDraculaButton.Visible = killAuraActive
    if killAuraActive then
        killAuraConnection = RunService.Heartbeat:Connect(function()
            if not killAuraActive or not AnimationController.Character then return end
            local zs = workspace:FindFirstChild("Zombies")
            if zs then
                for _, z in pairs(zs:GetChildren()) do
                    if z:IsA("Model") and z:FindFirstChild("HumanoidRootPart") then
                        if z:GetAttribute("Type") == "Barrel" and not attackBarrels then continue end
                        if distance(z) <= 12 and z:FindFirstChild("State") and z.State.Value ~= "Spawn" then
                            performAttack(z, false)
                        end
                    end
                end
            end
            if attackDraculaEnabled then
                local drac = workspace:FindFirstChild("Transylvania") and workspace.Transylvania.Modes.Boss:FindFirstChild("Dracula")
                if drac and drac:FindFirstChild("HumanoidRootPart") and distance(drac) <= 12 then performAttack(drac, true) end
            end
        end)
    else
        if killAuraConnection then killAuraConnection:Disconnect() end
    end
end)

-- 其他按钮逻辑
espButton.MouseButton1Click:Connect(function()
    espEnabled = not espEnabled
    updateAllESP()
end)

autoRotateButton.MouseButton1Click:Connect(function()
    autoRotateEnabled = not autoRotateEnabled
    autoRotateButton.Text = "自动转向: " .. (autoRotateEnabled and "开启" or "关闭")
end)

ToggleButton.MouseButton1Click:Connect(function() MainFrame.Visible = not MainFrame.Visible end)

CloseButton.MouseButton1Click:Connect(function()
    flying = false
    killAuraActive = false
    if killAuraConnection then killAuraConnection:Disconnect() end
    ScreenGui:Destroy()
end)
