-- Servern bestämmer vilken kyckling man får (så att ingen kan fuska),
-- håller koll på mynt och inventory och sparar allt.
local DataStoreService = game:GetService("DataStoreService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Chickens = require(ReplicatedStorage.Shared.Chickens)
local ChickenModel = require(ReplicatedStorage.Shared.ChickenModel)
local Config = require(ReplicatedStorage.Shared.Config)

local remotes = Instance.new("Folder")
remotes.Name = "Remotes"

local function remote(className: string, name: string): any
	local instance = Instance.new(className)
	instance.Name = name
	instance.Parent = remotes
	return instance
end

local rollRemote = remote("RemoteFunction", "Roll")
local sellRemote = remote("RemoteFunction", "Sell")
local sellCommonRemote = remote("RemoteFunction", "SellCommon")
local potionRemote = remote("RemoteFunction", "BuyPotion")
local equipRemote = remote("RemoteFunction", "Equip")
local getStateRemote = remote("RemoteFunction", "GetState")
local settingsRemote = remote("RemoteFunction", "SaveSetting")
local stateRemote = remote("RemoteEvent", "State")
local announceRemote = remote("RemoteEvent", "Announce")
remotes.Parent = ReplicatedStorage

-- Kycklingar som följer efter spelarna.
local petFolder = Instance.new("Folder")
petFolder.Name = "Kycklingar"
petFolder.Parent = workspace

-- Sparning fungerar bara när spelet är publicerat och "Enable Studio Access to API Services" är på.
local storeOk, store = pcall(DataStoreService.GetDataStore, DataStoreService, "KycklingRNG_v1")
if not storeOk then
	store = nil
	print("Kyckling-RNG: sparning är avstängd här (spelet är inte publicerat). Spelet fungerar ändå.")
end

type PlayerData = {
	coins: number,
	rolls: number,
	owned: { [string]: number },
	discovered: { [string]: boolean },
	equipped: string?,
	luckUntil: number,
	pet: Model?,
	settings: { [string]: any },
}
local playerData: { [Player]: PlayerData } = {}
local lastRoll: { [Player]: number } = {}
local rng = Random.new()

local function sendState(player: Player)
	local data = playerData[player]
	if not data then
		return
	end
	local leaderstats = player:FindFirstChild("leaderstats")
	if leaderstats then
		leaderstats.Mynt.Value = data.coins
		leaderstats.Rullningar.Value = data.rolls
	end
	stateRemote:FireClient(player, {
		coins = data.coins,
		rolls = data.rolls,
		owned = data.owned,
		discovered = data.discovered,
		equipped = data.equipped,
		luckSeconds = math.max(0, data.luckUntil - os.clock()),
		settings = data.settings,
	})
end

local function setPet(player: Player, id: string?)
	local data = playerData[player]
	if data.pet then
		data.pet:Destroy()
		data.pet = nil
	end
	data.equipped = id
	if id then
		local pet = ChickenModel.build(Chickens.byId[id])
		pet:ScaleTo(pet:GetScale() * 0.55)
		for _, part in pet:GetDescendants() do
			if part:IsA("BasePart") then
				part.CanQuery = false
				part.CanTouch = false
			end
		end
		pet.Name = player.Name
		pet.Parent = petFolder
		data.pet = pet
	end
end

local function onPlayerAdded(player: Player)
	local leaderstats = Instance.new("Folder")
	leaderstats.Name = "leaderstats"
	for _, name in { "Mynt", "Rullningar" } do
		local value = Instance.new("IntValue")
		value.Name = name
		value.Parent = leaderstats
	end
	leaderstats.Parent = player

	local data: PlayerData = {
		coins = Config.START_COINS,
		rolls = 0,
		owned = {},
		discovered = {},
		luckUntil = 0,
		settings = table.clone(Config.DEFAULT_SETTINGS),
	}
	if store then
		local ok, saved = pcall(store.GetAsync, store, tostring(player.UserId))
		if ok and type(saved) == "table" then
			data.coins = saved.coins or Config.START_COINS
			data.rolls = saved.rolls or 0
			data.owned = saved.owned or saved.counts or {}
			data.discovered = saved.discovered or {}
			for id in data.owned do
				data.discovered[id] = true
			end
			data.equipped = saved.equipped
			for key, value in saved.settings or {} do
				if type(Config.DEFAULT_SETTINGS[key]) == type(value) then
					data.settings[key] = value
				end
			end
		end
	end
	playerData[player] = data
	if data.equipped and (data.owned[data.equipped] or 0) > 0 then
		setPet(player, data.equipped)
	else
		data.equipped = nil
	end
	sendState(player)
end

local function save(player: Player)
	local data = playerData[player]
	if store and data then
		pcall(store.SetAsync, store, tostring(player.UserId), {
			coins = data.coins,
			rolls = data.rolls,
			owned = data.owned,
			discovered = data.discovered,
			equipped = data.equipped,
			settings = data.settings,
		})
	end
end

local function hasAnyChicken(data: PlayerData): boolean
	for _, count in data.owned do
		if count > 0 then
			return true
		end
	end
	return false
end

-- Ta bort kycklingar ur inventoryt och ge mynt för dem.
local function sell(player: Player, id: string, amount: number): number
	local data = playerData[player]
	local chicken = Chickens.byId[id]
	local owned = data.owned[id] or 0
	amount = math.clamp(math.floor(amount), 0, owned)
	if amount == 0 then
		return 0
	end
	data.owned[id] = owned - amount
	if data.owned[id] == 0 then
		data.owned[id] = nil
		if data.equipped == id then
			setPet(player, nil)
		end
	end
	local earned = Chickens.valueOf(chicken) * amount
	data.coins += earned
	return earned
end

rollRemote.OnServerInvoke = function(player: Player)
	local data = playerData[player]
	local now = os.clock()
	if not data or (lastRoll[player] and now - lastRoll[player] < Config.ROLL_COOLDOWN) then
		return nil
	end

	-- Har man inga mynt och inget att sälja får man rulla gratis, så man aldrig fastnar.
	local free = data.coins < Config.ROLL_COST and not hasAnyChicken(data)
	if data.coins < Config.ROLL_COST and not free then
		return { error = "Du har inte råd! Sälj några kycklingar." }
	end
	lastRoll[player] = now
	if not free then
		data.coins -= Config.ROLL_COST
	end

	data.rolls += 1
	local lucky = data.rolls % Config.LUCK_EVERY == 0
	local luck = 1
	if lucky then
		luck *= Config.LUCK_MULTIPLIER
	end
	if data.luckUntil > now then
		luck *= Config.POTION_MULTIPLIER
	end

	local chicken = Chickens.roll(luck, rng)
	local isNew = not data.discovered[chicken.id]
	data.owned[chicken.id] = (data.owned[chicken.id] or 0) + 1
	data.discovered[chicken.id] = true

	if chicken.odds >= Config.ANNOUNCE_ODDS then
		announceRemote:FireAllClients(player.DisplayName, chicken.id)
	end

	-- Auto-sälj: Vanliga kycklingar blir mynt direkt (utom första gången och den utrustade).
	local sold = 0
	if data.settings.autoSell and Chickens.tierOf(chicken) == 1 and not isNew and data.equipped ~= chicken.id then
		sold = sell(player, chicken.id, 1)
	end
	sendState(player)

	return { id = chicken.id, isNew = isNew, lucky = lucky, luck = luck, free = free, sold = sold }
end

settingsRemote.OnServerInvoke = function(player: Player, key: unknown, value: unknown)
	local data = playerData[player]
	if not data or type(key) ~= "string" then
		return false
	end
	local default = Config.DEFAULT_SETTINGS[key]
	if default == nil or type(value) ~= type(default) then
		return false
	end
	if type(value) == "number" and (value ~= value or value < 1 or value > 7) then
		return false
	end
	data.settings[key] = value
	return true
end

sellRemote.OnServerInvoke = function(player: Player, id: unknown, amount: unknown)
	if
		not playerData[player]
		or type(id) ~= "string"
		or not Chickens.byId[id]
		or type(amount) ~= "number"
		or amount ~= amount
	then
		return 0
	end
	local earned = sell(player, id, amount)
	sendState(player)
	return earned
end

-- Säljer alla Vanliga och Ovanliga kycklingar, utom den man har utrustad.
sellCommonRemote.OnServerInvoke = function(player: Player)
	local data = playerData[player]
	if not data then
		return 0
	end
	local earned = 0
	for _, chicken in Chickens.list do
		if Chickens.tierOf(chicken) <= 2 and chicken.id ~= data.equipped then
			earned += sell(player, chicken.id, data.owned[chicken.id] or 0)
		end
	end
	sendState(player)
	return earned
end

potionRemote.OnServerInvoke = function(player: Player)
	local data = playerData[player]
	if not data or data.coins < Config.POTION_COST then
		return false
	end
	data.coins -= Config.POTION_COST
	data.luckUntil = math.max(data.luckUntil, os.clock()) + Config.POTION_SECONDS
	sendState(player)
	return true
end

equipRemote.OnServerInvoke = function(player: Player, id: unknown)
	local data = playerData[player]
	if not data then
		return false
	end
	if id == nil or id == data.equipped then
		setPet(player, nil)
	elseif type(id) == "string" and (data.owned[id] or 0) > 0 then
		setPet(player, id)
	end
	sendState(player)
	return true
end

getStateRemote.OnServerInvoke = function(player: Player)
	local waited = 0
	while not playerData[player] and waited < 10 do
		waited += task.wait()
	end
	sendState(player)
	return true
end

Players.PlayerAdded:Connect(onPlayerAdded)
for _, player in Players:GetPlayers() do
	task.spawn(onPlayerAdded, player)
end

Players.PlayerRemoving:Connect(function(player)
	save(player)
	local data = playerData[player]
	if data and data.pet then
		data.pet:Destroy()
	end
	playerData[player] = nil
	lastRoll[player] = nil
end)

game:BindToClose(function()
	for _, player in Players:GetPlayers() do
		save(player)
	end
end)

-- Spara då och då ifall servern kraschar.
task.spawn(function()
	while true do
		task.wait(60)
		for _, player in Players:GetPlayers() do
			save(player)
		end
	end
end)

-- Husdjurs-kycklingen hoppar efter spelaren.
RunService.Heartbeat:Connect(function(dt)
	local t = os.clock()
	for player, data in playerData do
		local pet = data.pet
		local character = player.Character
		local root = character and character:FindFirstChild("HumanoidRootPart") :: BasePart?
		local humanoid = character and character:FindFirstChildOfClass("Humanoid")
		if pet and root and humanoid then
			local groundY = root.Position.Y - humanoid.HipHeight - root.Size.Y / 2
			local behind = root.CFrame * CFrame.new(2.5, 0, 2.5)
			local hop = math.abs(math.sin(t * 6)) * 0.6
			local target = CFrame.new(behind.Position.X, groundY + hop, behind.Position.Z) * root.CFrame.Rotation
			local current = pet:GetPivot()
			pet:PivotTo(current:Lerp(target, math.min(1, dt * 10)))
		end
	end
end)

print("Kyckling-RNG har startat! 🐔")
