-- Servern bestämmer vilken kyckling man får (så att ingen kan fuska),
-- håller koll på varje spelares samling och sparar den.
local DataStoreService = game:GetService("DataStoreService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Chickens = require(ReplicatedStorage.Shared.Chickens)

local COOLDOWN = 0.8 -- sekunder mellan rullningar
local LUCK_EVERY = 10 -- var 10:e rullning är en tur-rullning
local LUCK_MULTIPLIER = 2
local ANNOUNCE_ODDS = 1000 -- alla får se när någon rullar 1 på 1000 eller ovanligare

local remotes = Instance.new("Folder")
remotes.Name = "Remotes"
local rollRemote = Instance.new("RemoteFunction")
rollRemote.Name = "Roll"
rollRemote.Parent = remotes
local getDataRemote = Instance.new("RemoteFunction")
getDataRemote.Name = "GetData"
getDataRemote.Parent = remotes
local announceRemote = Instance.new("RemoteEvent")
announceRemote.Name = "Announce"
announceRemote.Parent = remotes
remotes.Parent = ReplicatedStorage

-- Sparning fungerar bara när spelet är publicerat och "Enable Studio Access to API Services" är på.
local storeOk, store = pcall(DataStoreService.GetDataStore, DataStoreService, "KycklingRNG_v1")
if not storeOk then
	store = nil
	print("Kyckling-RNG: sparning är avstängd här (spelet är inte publicerat). Spelet fungerar ändå.")
end

type PlayerData = { rolls: number, counts: { [string]: number } }
local playerData: { [Player]: PlayerData } = {}
local lastRoll: { [Player]: number } = {}
local rng = Random.new()

local function updateLeaderstats(player: Player)
	local data = playerData[player]
	local leaderstats = player:FindFirstChild("leaderstats")
	if not data or not leaderstats then
		return
	end
	leaderstats.Rullningar.Value = data.rolls

	local best = nil
	for _, chicken in Chickens.list do
		if (data.counts[chicken.id] or 0) > 0 then
			best = chicken
		end
	end
	leaderstats["Bästa"].Value = if best then Chickens.formatOdds(best) else "-"
end

local function onPlayerAdded(player: Player)
	local leaderstats = Instance.new("Folder")
	leaderstats.Name = "leaderstats"
	local rolls = Instance.new("IntValue")
	rolls.Name = "Rullningar"
	rolls.Parent = leaderstats
	local best = Instance.new("StringValue")
	best.Name = "Bästa"
	best.Value = "-"
	best.Parent = leaderstats
	leaderstats.Parent = player

	local data: PlayerData = { rolls = 0, counts = {} }
	if store then
		local ok, saved = pcall(store.GetAsync, store, tostring(player.UserId))
		if ok and type(saved) == "table" then
			data.rolls = saved.rolls or 0
			data.counts = saved.counts or {}
		end
	end
	playerData[player] = data
	updateLeaderstats(player)
end

local function save(player: Player)
	local data = playerData[player]
	if store and data then
		pcall(store.SetAsync, store, tostring(player.UserId), data)
	end
end

rollRemote.OnServerInvoke = function(player: Player)
	local data = playerData[player]
	local now = os.clock()
	if not data or (lastRoll[player] and now - lastRoll[player] < COOLDOWN) then
		return nil
	end
	lastRoll[player] = now

	data.rolls += 1
	local lucky = data.rolls % LUCK_EVERY == 0
	local chicken = Chickens.roll(if lucky then LUCK_MULTIPLIER else 1, rng)
	data.counts[chicken.id] = (data.counts[chicken.id] or 0) + 1
	updateLeaderstats(player)

	if chicken.odds >= ANNOUNCE_ODDS then
		announceRemote:FireAllClients(player.DisplayName, chicken.id)
	end

	return { id = chicken.id, count = data.counts[chicken.id], rolls = data.rolls, lucky = lucky }
end

getDataRemote.OnServerInvoke = function(player: Player)
	local waited = 0
	while not playerData[player] and waited < 10 do
		waited += task.wait()
	end
	local data = playerData[player]
	return {
		rolls = if data then data.rolls else 0,
		counts = if data then data.counts else {},
		luckEvery = LUCK_EVERY,
		luckMultiplier = LUCK_MULTIPLIER,
	}
end

Players.PlayerAdded:Connect(onPlayerAdded)
for _, player in Players:GetPlayers() do
	task.spawn(onPlayerAdded, player)
end

Players.PlayerRemoving:Connect(function(player)
	save(player)
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

print("Kyckling-RNG har startat! 🐔")
