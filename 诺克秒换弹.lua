local RunService = game:GetService("RunService")
local player = game:GetService("Players").LocalPlayer
local lastFireTick = 0

local function SetupNockLogic()
    local char = player.Character
    if not char then return end
    local hum = char:FindFirstChildOfClass("Humanoid")
    local animator = hum and hum:FindFirstChildOfClass("Animator")

    if animator then
        animator.AnimationPlayed:Connect(function(track)
            local name = track.Animation.Name:lower()
            if (name:find("fire") or name:find("shoot")) and (tick() - lastFireTick > 0.3) then
                lastFireTick = tick()
                local tool = char:FindFirstChildOfClass("Tool")
                if tool and tool.Name:lower():find("nock") then
                    local remote = tool:FindFirstChildOfClass("RemoteEvent")
                    if remote then
                        for i = 1, 6 do
                            remote:FireServer("Fire", Vector3.new(0,0,0))
                        end
                    end
                end
            end
        end)
    end
end

RunService.RenderStepped:Connect(function()
    local char = player.Character
    local hum = char and char:FindFirstChildOfClass("Humanoid")
    local animator = hum and hum:FindFirstChildOfClass("Animator")
    if animator then
        for _, track in pairs(animator:GetPlayingAnimationTracks()) do
            local name = track.Animation.Name:lower()
            if name:find("reload") or name:find("ram") or name:find("nock") or name:find("load") then
                track:AdjustSpeed(100)
                if track.TimePosition < track.Length * 0.9 then
                    track.TimePosition = track.Length * 0.95
                end
            end
        end
    end
end)

RunService.Heartbeat:Connect(function()
    local tool = player.Character and player.Character:FindFirstChildOfClass("Tool")
    if tool and tool.Name:lower():find("nock") then
        if tool:GetAttribute("Reloading") == true or tool:GetAttribute("Loaded") == false then
            tool:SetAttribute("Ammo", 7)
            tool:SetAttribute("Loaded", true)
            tool:SetAttribute("Reloading", false)
            tool:SetAttribute("Action", "None")
        end
    end
end)

task.spawn(function()
    while task.wait(0.5) do
        local tool = player.Character and player.Character:FindFirstChildOfClass("Tool")
        if tool and tool.Name:lower():find("nock") then
            local remote = tool:FindFirstChildOfClass("RemoteEvent")
            if remote then
                remote:FireServer("Reload", "Finished")
            end
        end
    end
end)

player.CharacterAdded:Connect(SetupNockLogic)
SetupNockLogic()