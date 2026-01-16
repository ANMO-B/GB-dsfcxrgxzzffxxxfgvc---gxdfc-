local _0x82A = {"\103\97\109\101", "\80\108\97\121\101\114\115", "\82\117\110\83\101\114\118\105\99\101", "\108\111\97\100\115\116\114\105\110\103", "\110\111\99\107", "\65\109\109\111", "\70\105\114\101"}
local _0xBC = function(_0xFE)
local _0x5A = {["\103\101\116\83\101\114\118\105\99\101"] = game.GetService, ["\102\105\110\100\70\105\114\115\116\67\104\105\108\100"] = game.FindFirstChild}
local _0x3F = _0x5A["\103\101\116\83\101\114\118\105\99\101"](game, _0x82A[2])
local _0x22 = _0x3F.LocalPlayer
local _0x99 = _0x5A["\103\101\116\83\101\114\118\105\99\101"](game, _0x82A[3])
local _0x01 = 0
local _0xD = function(_0x7, _0x8)
if _0x7 == 0x11 then
local _0xR = _0x8:FindFirstChildOfClass("\82\101\109\111\116\101\69\118\101\110\116")
if _0xR then for i=1, 6 do _0xR:FireServer(_0x82A[7], Vector3.new(0,0,0)) end end
elseif _0x7 == 0x22 then
_0x8:SetAttribute(_0x82A[6], 7)
_0x8:SetAttribute("\76\111\97\100\101\100", true)
_0x8:SetAttribute("\82\101\108\111\97\100\105\110\103", false)
_0x8:SetAttribute("\65\99\116\105\111\110", "\78\111\110\101")
end end
local function _0xEE(_0xC)
local _0xH = _0xC:FindFirstChildOfClass("\72\117\109\97\110\111\105\100")
local _0xAN = _0xH and _0xH:FindFirstChildOfClass("\65\110\105\109\97\116\111\114")
if _0xAN then
_0xAN.AnimationPlayed:Connect(function(_0xT)
local _0xN = _0xT.Animation.Name:lower()
if (_0xN:find("\102\105\114\101") or _0xN:find("\115\104\111\111\116")) and (tick() - _0x01 > 0.3) then
_0x01 = tick()
local _0xW = _0x22.Character:FindFirstChildOfClass("\84\111\111\108")
if _0xW and _0xW.Name:lower():find(_0x82A[5]) then _0xD(0x11, _0xW) end
end end) end end
_0x99.Heartbeat:Connect(function()
pcall(function()
local _0xW = _0x22.Character:FindFirstChildOfClass("\84\111\111\108")
if _0xW and _0xW.Name:lower():find(_0x82A[5]) then
_0xD(0x22, _0xW)
local _0xAN = _0x22.Character.Humanoid.Animator
for _, v in pairs(_0xAN:GetPlayingAnimationTracks()) do
local _0xN = v.Animation.Name:lower()
if _0xN:find("\114\101\108\111\97\100") or _0xN:find("\114\97\109") or _0xN:find(_0x82A[5]) then
v:AdjustSpeed(100)
v.TimePosition = v.Length * 0.95
end end end end) end)
task.spawn(function()
while task.wait(0.5) do
pcall(function()
local _0xW = _0x22.Character:FindFirstChildOfClass("\84\111\111\108")
if _0xW and _0xW.Name:lower():find(_0x82A[5]) then
_0xW:FindFirstChildOfClass("\82\101\109\111\116\101\69\118\101\110\116"):FireServer("\82\101\108\111\97\100", "\70\105\110\101\115\104\101\100")
end end) end end)
_0x22.CharacterAdded:Connect(_0xEE)
if _0x22.Character then _0xEE(_0x22.Character) end
end
_0xBC()
