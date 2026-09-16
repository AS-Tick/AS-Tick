-- AS EGG GAME - ONE CLICK STUDIO INSTALLER
-- Paste this whole code into Roblox Studio Command Bar and RUN.
-- Creates ServerScript + LocalScript automatically.

local ServerScriptService = game:GetService("ServerScriptService")
local StarterPlayer = game:GetService("StarterPlayer")
local StarterPlayerScripts = StarterPlayer:WaitForChild("StarterPlayerScripts")

-- Remove old versions
local oldServer = ServerScriptService:FindFirstChild("AS_Server")
if oldServer then oldServer:Destroy() end

local oldClient = StarterPlayerScripts:FindFirstChild("AS_Client")
if oldClient then oldClient:Destroy() end

--------------------------------------------------
-- SERVER CODE
--------------------------------------------------

local serverCode = [==[
local Players = game:GetService("Players")
local DataStoreService = game:GetService("DataStoreService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Store = DataStoreService:GetDataStore("AS_EggGame_Save_1")

local remotes = ReplicatedStorage:FindFirstChild("AS_Remotes")
if not remotes then
	remotes = Instance.new("Folder")
	remotes.Name = "AS_Remotes"
	remotes.Parent = ReplicatedStorage
end

local Hatch = remotes:FindFirstChild("Hatch") or Instance.new("RemoteEvent")
Hatch.Name = "Hatch"
Hatch.Parent = remotes

local GetState = remotes:FindFirstChild("GetState") or Instance.new("RemoteEvent")
GetState.Name = "GetState"
GetState.Parent = remotes

local State = remotes:FindFirstChild("State") or Instance.new("RemoteEvent")
State.Name = "State"
State.Parent = remotes

local Notify = remotes:FindFirstChild("Notify") or Instance.new("RemoteEvent")
Notify.Name = "Notify"
Notify.Parent = remotes

--------------------------------------------------
-- GAME DATA
--------------------------------------------------

local Eggs = {
	{
		Name = "Common Egg",
		Pet = "Bunny",
		Rarity = "Common",
		Income = 2
	},
	{
		Name = "Forest Egg",
		Pet = "Fox",
		Rarity = "Rare",
		Income = 8
	},
	{
		Name = "Crystal Egg",
		Pet = "Dragon",
		Rarity = "Epic",
		Income = 35
	},
	{
		Name = "Rift Egg",
		Pet = "Void Dragon",
		Rarity = "Legendary",
		Income = 180
	}
}

local playerData = {}

local function defaultData()
	return {
		Cash = 250,
		Speed = 16,
		SpeedLevel = 1,
		Eggs = 0,
		PetSlots = 3,
		Pets = {}
	}
end

local function sendState(player)
	local d = playerData[player]
	if not d then return end

	State:FireClient(player, {
		Cash = d.Cash,
		Speed = d.Speed,
		SpeedLevel = d.SpeedLevel,
		Eggs = d.Eggs,
		PetSlots = d.PetSlots,
		Pets = d.Pets
	})
end

local function notify(player, text)
	Notify:FireClient(player, text)
end

--------------------------------------------------
-- WORLD
--------------------------------------------------

local world = workspace:FindFirstChild("AS_World")
if world then
	world:Destroy()
end

world = Instance.new("Folder")
world.Name = "AS_World"
world.Parent = workspace

local function part(name, size, position)
	local p = Instance.new("Part")
	p.Name = name
	p.Size = size
	p.Position = position
	p.Anchored = true
	p.Parent = world
	return p
end

-- Floor
part("MainFloor", Vector3.new(180, 2, 180), Vector3.new(0, -1, 0))

-- Spawn
local spawn = Instance.new("SpawnLocation")
spawn.Name = "AS_Spawn"
spawn.Size = Vector3.new(8, 1, 8)
spawn.Position = Vector3.new(0, 1, 0)
spawn.Anchored = true
spawn.Parent = world

--------------------------------------------------
-- EGG CREATION
--------------------------------------------------

local eggPositions = {
	Vector3.new(-25, 3, 0),
	Vector3.new(-8, 3, 0),
	Vector3.new(10, 3, 0),
	Vector3.new(28, 3, 0)
}

local function createEgg(info, pos, index)

	local egg = Instance.new("Part")
	egg.Name = info.Name
	egg.Shape = Enum.PartType.Ball
	egg.Size = Vector3.new(5, 5, 5)
	egg.Position = pos
	egg.Anchored = true
	egg.Parent = world

	local prompt = Instance.new("ProximityPrompt")
	prompt.ActionText = "Collect Egg"
	prompt.ObjectText = info.Name
	prompt.HoldDuration = 0.4
	prompt.MaxActivationDistance = 12
	prompt.Parent = egg

	-- Info above egg
	local billboard = Instance.new("BillboardGui")
	billboard.Name = "EggInfo"
	billboard.Size = UDim2.new(0, 260, 0, 100)
	billboard.StudsOffset = Vector3.new(0, 5, 0)
	billboard.AlwaysOnTop = true
	billboard.Parent = egg

	local text = Instance.new("TextLabel")
	text.Size = UDim2.fromScale(1, 1)
	text.BackgroundTransparency = 1
	text.TextScaled = true
	text.Font = Enum.Font.GothamBold
	text.TextStrokeTransparency = 0.2
	text.Text = "🥚 "..info.Name..
		"\n🐾 "..info.Pet.." • "..info.Rarity..
		"\n💰 $"..info.Income.."/sec"
	text.Parent = billboard

	prompt.Triggered:Connect(function(player)

		local d = playerData[player]
		if not d then return end

		d.Eggs += 1

		notify(player, "+1 "..info.Name)
		sendState(player)
	end)
end

for i, info in ipairs(Eggs) do
	createEgg(info, eggPositions[i], i)
end

--------------------------------------------------
-- TREADMILL
--------------------------------------------------

local treadmill = part(
	"Speed Treadmill",
	Vector3.new(14, 2, 7),
	Vector3.new(0, 1, 20)
)

local treadmillPrompt = Instance.new("ProximityPrompt")
treadmillPrompt.ActionText = "Upgrade Speed"
treadmillPrompt.ObjectText = "Treadmill"
treadmillPrompt.HoldDuration = 0.5
treadmillPrompt.MaxActivationDistance = 12
treadmillPrompt.Parent = treadmill

treadmillPrompt.Triggered:Connect(function(player)

	local d = playerData[player]
	if not d then return end

	local cost = d.SpeedLevel * 100

	if d.Cash < cost then
		notify(player, "Need $"..cost)
		return
	end

	d.Cash -= cost
	d.SpeedLevel += 1
	d.Speed += 2

	local character = player.Character
	if character then
		local humanoid = character:FindFirstChildOfClass("Humanoid")
		if humanoid then
			humanoid.WalkSpeed = d.Speed
		end
	end

	notify(player, "Speed upgraded! ⚡")
	sendState(player)
end)

--------------------------------------------------
-- RIFT
--------------------------------------------------

local rift = part(
	"AS Rift",
	Vector3.new(10, 10, 4),
	Vector3.new(0, 5, -25)
)

local riftPrompt = Instance.new("ProximityPrompt")
riftPrompt.ActionText = "Enter Rift"
riftPrompt.ObjectText = "AS Rift"
riftPrompt.HoldDuration = 1
riftPrompt.MaxActivationDistance = 14
riftPrompt.Parent = rift

local riftCooldown = {}

riftPrompt.Triggered:Connect(function(player)

	local now = os.clock()

	if riftCooldown[player] and now - riftCooldown[player] < 60 then
		local left = math.ceil(60 - (now - riftCooldown[player]))
		notify(player, "Rift cooldown: "..left.."s")
		return
	end

	riftCooldown[player] = now

	local d = playerData[player]
	if not d then return end

	d.Cash += 5000

	notify(player, "Rift reward: +$5000 💎")
	sendState(player)
end)

--------------------------------------------------
-- HATCH
--------------------------------------------------

local function chooseEgg()
	return Eggs[math.random(1, #Eggs)]
end

local function makePet(info)

	local mutation = "Normal"
	local multiplier = 1

	local roll = math.random(1, 100)

	if roll <= 5 then
		mutation = "Rainbow"
		multiplier = 12
	elseif roll <= 10 then
		mutation = "Golden"
		multiplier = 5
	end

	local size = math.random(80, 140) / 100

	return {
		Name = info.Pet,
		Rarity = info.Rarity,
		Mutation = mutation,
		Size = size,
		Income = info.Income * multiplier
	}
end

Hatch.OnServerEvent:Connect(function(player)

	local d = playerData[player]
	if not d then return end

	if d.Eggs <= 0 then
		notify(player, "Collect an egg first 🥚")
		return
	end

	if #d.Pets >= d.PetSlots then
		notify(player, "Pet slots full!")
		return
	end

	d.Eggs -= 1

	local info = chooseEgg()
	local pet = makePet(info)

	table.insert(d.Pets, pet)

	notify(
		player,
		"🎉 "..pet.Mutation.." "..pet.Name..
		" • $"..pet.Income.."/sec"
	)

	sendState(player)
end)

--------------------------------------------------
-- PLAYER DATA
--------------------------------------------------

local function loadPlayer(player)

	local data

	local success, result = pcall(function()
		return Store:GetAsync("P_"..player.UserId)
	end)

	if success and type(result) == "table" then
		data = result
	else
		data = defaultData()
	end

	playerData[player] = data

	player.CharacterAdded:Connect(function(character)

		task.wait(0.5)

		local humanoid = character:FindFirstChildOfClass("Humanoid")

		if humanoid then
			humanoid.WalkSpeed = data.Speed
		end
	end)

	sendState(player)
end

local function savePlayer(player)

	local d = playerData[player]
	if not d then return end

	pcall(function()
		Store:SetAsync("P_"..player.UserId, d)
	end)
end

Players.PlayerAdded:Connect(loadPlayer)

Players.PlayerRemoving:Connect(function(player)

	savePlayer(player)

	playerData[player] = nil
	riftCooldown[player] = nil
end)

game:BindToClose(function()

	for _, player in ipairs(Players:GetPlayers()) do
		savePlayer(player)
	end
end)

--------------------------------------------------
-- GET STATE
--------------------------------------------------

GetState.OnServerEvent:Connect(function(player)
	sendState(player)
end)

--------------------------------------------------
-- PET INCOME
--------------------------------------------------

task.spawn(function()

	while true do

		task.wait(2)

		for player, d in pairs(playerData) do

			local income = 0

			for _, pet in ipairs(d.Pets) do
				income += tonumber(pet.Income) or 0
			end

			if income > 0 then
				d.Cash += income * 2
				sendState(player)
			end
		end
	end
end)

]==]

--------------------------------------------------
-- CLIENT CODE
--------------------------------------------------

local clientCode = [==[
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local player = Players.LocalPlayer
local remotes = ReplicatedStorage:WaitForChild("AS_Remotes")

local Hatch = remotes:WaitForChild("Hatch")
local GetState = remotes:WaitForChild("GetState")
local State = remotes:WaitForChild("State")
local Notify = remotes:WaitForChild("Notify")

--------------------------------------------------
-- GUI
--------------------------------------------------

local gui = Instance.new("ScreenGui")
gui.Name = "AS_GUI"
gui.ResetOnSpawn = false
gui.Parent = player:WaitForChild("PlayerGui")

--------------------------------------------------
-- MAIN WINDOW
--------------------------------------------------

local main = Instance.new("Frame")
main.Name = "Main"
main.Size = UDim2.new(0, 360, 0, 430)
main.Position = UDim2.new(0.5, -180, 0.5, -215)
main.BackgroundColor3 = Color3.fromRGB(18, 18, 25)
main.BorderSizePixel = 0
main.Parent = gui

local corner = Instance.new("UICorner")
corner.CornerRadius = UDim.new(0, 18)
corner.Parent = main

--------------------------------------------------
-- HEADER
--------------------------------------------------

local header = Instance.new("Frame")
header.Size = UDim2.new(1, 0, 0, 60)
header.BackgroundTransparency = 1
header.Parent = main

local title = Instance.new("TextLabel")
title.Size = UDim2.new(1, -70, 1, 0)
title.Position = UDim2.new(0, 15, 0, 0)
title.BackgroundTransparency = 1
title.Text = "AS  ✓   EGG LAB"
title.TextColor3 = Color3.fromRGB(255, 255, 255)
title.Font = Enum.Font.GothamBold
title.TextSize = 22
title.TextXAlignment = Enum.TextXAlignment.Left
title.Parent = header

--------------------------------------------------
-- MINIMIZE
--------------------------------------------------

local minimize = Instance.new("TextButton")
minimize.Size = UDim2.new(0, 45, 0, 45)
minimize.Position = UDim2.new(1, -52, 0, 8)
minimize.Text = "—"
minimize.TextSize = 25
minimize.Font = Enum.Font.GothamBold
minimize.TextColor3 = Color3.fromRGB(255,255,255)
minimize.BackgroundColor3 = Color3.fromRGB(35,35,45)
minimize.Parent = header

Instance.new("UICorner", minimize).CornerRadius = UDim.new(0, 12)

--------------------------------------------------
-- STATS
--------------------------------------------------

local stats = Instance.new("TextLabel")
stats.Size = UDim2.new(1, -30, 0, 80)
stats.Position = UDim2.new(0, 15, 0, 65)
stats.BackgroundColor3 = Color3.fromRGB(27,27,37)
stats.TextColor3 = Color3.fromRGB(255,255,255)
stats.Font = Enum.Font.GothamBold
stats.TextSize = 16
stats.TextWrapped = true
stats.Text = "Loading..."
stats.Parent = main

Instance.new("UICorner", stats).CornerRadius = UDim.new(0, 14)

--------------------------------------------------
-- HATCH BUTTON
--------------------------------------------------

local hatchButton = Instance.new("TextButton")
hatchButton.Size = UDim2.new(1, -30, 0, 58)
hatchButton.Position = UDim2.new(0, 15, 0, 160)
hatchButton.BackgroundColor3 = Color3.fromRGB(70, 55, 150)
hatchButton.TextColor3 = Color3.fromRGB(255,255,255)
hatchButton.Font = Enum.Font.GothamBold
hatchButton.TextSize = 19
hatchButton.Text = "🥚  HATCH EGG"
hatchButton.Parent = main

Instance.new("UICorner", hatchButton).CornerRadius = UDim.new(0, 14)

hatchButton.MouseButton1Click:Connect(function()
	Hatch:FireServer()
end)

--------------------------------------------------
-- PET LIST
--------------------------------------------------

local petsLabel = Instance.new("TextLabel")
petsLabel.Size = UDim2.new(1, -30, 0, 145)
petsLabel.Position = UDim2.new(0, 15, 0, 230)
petsLabel.BackgroundColor3 = Color3.fromRGB(27,27,37)
petsLabel.TextColor3 = Color3.fromRGB(255,255,255)
petsLabel.Font = Enum.Font.Gotham
petsLabel.TextSize = 14
petsLabel.TextWrapped = true
petsLabel.TextYAlignment = Enum.TextYAlignment.Top
petsLabel.Text = "🐾 PETS"
petsLabel.Parent = main

Instance.new("UICorner", petsLabel).CornerRadius = UDim.new(0, 14)

--------------------------------------------------
-- NOTIFICATION
--------------------------------------------------

local notification = Instance.new("TextLabel")
notification.Size = UDim2.new(0, 330, 0, 50)
notification.Position = UDim2.new(0.5, -165, 0.08, 0)
notification.BackgroundColor3 = Color3.fromRGB(25,25,35)
notification.TextColor3 = Color3.fromRGB(255,255,255)
notification.Font = Enum.Font.GothamBold
notification.TextSize = 16
notification.Visible = false
notification.Parent = gui

Instance.new("UICorner", notification).CornerRadius = UDim.new(0, 14)

--------------------------------------------------
-- FLOATING AS BUTTON
--------------------------------------------------

local floating = Instance.new("TextButton")
floating.Size = UDim2.new(0, 65, 0, 65)
floating.Position = UDim2.new(0, 20, 0.75, 0)
floating.BackgroundColor3 = Color3.fromRGB(55, 45, 120)
floating.Text = "AS\n✓"
floating.TextColor3 = Color3.fromRGB(255,255,255)
floating.TextSize = 18
floating.Font = Enum.Font.GothamBold
floating.Visible = false
floating.Parent = gui

Instance.new("UICorner", floating).CornerRadius = UDim.new(1, 0)

--------------------------------------------------
-- MINIMIZE ACTION
--------------------------------------------------

minimize.MouseButton1Click:Connect(function()
	main.Visible = false
	floating.Visible = true
end)

floating.MouseButton1Click:Connect(function()
	floating.Visible = false
	main.Visible = true
end)

--------------------------------------------------
-- STATE UPDATE
--------------------------------------------------

State.OnClientEvent:Connect(function(data)

	stats.Text =
		"💰 Cash: $"..tostring(data.Cash)..
		"\n🥚 Eggs: "..tostring(data.Eggs)..
		"     ⚡ Speed: "..tostring(data.Speed)

	local text = "🐾 PETS\n\n"

	if #data.Pets == 0 then
		text ..= "No pets yet.\nCollect an egg and hatch it!"
	else

		for i, pet in ipairs(data.Pets) do

			text ..=
				i..". "..tostring(pet.Mutation)..
				" "..tostring(pet.Name)..
				"  $"..tostring(pet.Income).."/sec\n"
		end
	end

	text ..=
		"\nSlots: "..tostring(#data.Pets)..
		"/"..tostring(data.PetSlots)

	petsLabel.Text = text
end)

--------------------------------------------------
-- NOTIFICATIONS
--------------------------------------------------

Notify.OnClientEvent:Connect(function(text)

	notification.Text = tostring(text)
	notification.Visible = true

	task.delay(2.5, function()
		notification.Visible = false
	end)
end)

GetState:FireServer()

]==]

--------------------------------------------------
-- CREATE SERVER SCRIPT
--------------------------------------------------

local serverScript = Instance.new("Script")
serverScript.Name = "AS_Server"
serverScript.Source = serverCode
serverScript.Parent = ServerScriptService

--------------------------------------------------
-- CREATE CLIENT SCRIPT
--------------------------------------------------

local clientScript = Instance.new("LocalScript")
clientScript.Name = "AS_Client"
clientScript.Source = clientCode
clientScript.Parent = StarterPlayerScripts

print("====================================")
print("AS EGG GAME INSTALL COMPLETE!")
print("AS_Server created")
print("AS_Client created")
print("Press PLAY to test the game.")
print("====================================")
