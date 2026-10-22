-- Allt spelaren ser: mynt, tärningen, kycklingen som rullas fram och inventoryt.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")

local Chickens = require(ReplicatedStorage.Shared.Chickens)
local ChickenModel = require(ReplicatedStorage.Shared.ChickenModel)
local Config = require(ReplicatedStorage.Shared.Config)
local Cutscene = require(script.Cutscene)
local Dice = require(script.Dice)
local Effects = require(script.Effects)
local Inventory = require(script.Inventory)
local Settings = require(script.Settings)
local UI = require(script.UI)

local player = Players.LocalPlayer
local remotes = ReplicatedStorage:WaitForChild("Remotes")
local function getRemote(name: string): any
	return remotes:WaitForChild(name)
end
local rollRemote = getRemote("Roll") :: RemoteFunction
local sellRemote = getRemote("Sell") :: RemoteFunction
local sellCommonRemote = getRemote("SellCommon") :: RemoteFunction
local potionRemote = getRemote("BuyPotion") :: RemoteFunction
local equipRemote = getRemote("Equip") :: RemoteFunction
local getStateRemote = getRemote("GetState") :: RemoteFunction
local settingsRemote = getRemote("SaveSetting") :: RemoteFunction
local stateRemote = getRemote("State") :: RemoteEvent
local announceRemote = getRemote("Announce") :: RemoteEvent

local GREEN = Color3.fromRGB(120, 255, 120)
local RED = Color3.fromRGB(255, 80, 80)
local GOLD = Color3.fromRGB(255, 215, 60)

---------------------------------------------------------------------
-- Gränssnittet
---------------------------------------------------------------------

local playerGui = player:WaitForChild("PlayerGui")
local gui = UI.new("ScreenGui", {
	Name = "KycklingRNG",
	ResetOnSpawn = false,
	IgnoreGuiInset = true,
	Parent = playerGui,
})
local effectsLayer = UI.new("ScreenGui", {
	Name = "KycklingEffekter",
	ResetOnSpawn = false,
	IgnoreGuiInset = true,
	DisplayOrder = 20,
	Parent = playerGui,
})
Effects.init(effectsLayer)

-- Allt som göms under cutscenen ligger i "hud".
local hud = UI.new("Frame", {
	Size = UDim2.fromScale(1, 1),
	BackgroundTransparency = 1,
	Parent = gui,
})

-- Mynt uppe till vänster.
local coinBox = UI.new("Frame", {
	Position = UDim2.fromOffset(20, 70),
	Size = UDim2.fromOffset(220, 54),
	BackgroundColor3 = UI.DARK,
	BackgroundTransparency = 0.2,
	Parent = hud,
}, { UI.corner(14), UI.stroke(3, GOLD, Enum.ApplyStrokeMode.Border) })
local coinScale = UI.new("UIScale", { Parent = coinBox })
local coinLabel = UI.label({
	Position = UDim2.fromOffset(12, 8),
	Size = UDim2.new(1, -24, 1, -16),
	TextXAlignment = Enum.TextXAlignment.Left,
	TextColor3 = GOLD,
	Text = "🪙 0",
	Parent = coinBox,
})

local potionButton = UI.button({
	Position = UDim2.fromOffset(20, 132),
	Size = UDim2.fromOffset(220, 44),
	BackgroundColor3 = Color3.fromRGB(150, 70, 220),
	Text = `🧪 Tur-dryck ({Config.POTION_COST} 🪙)`,
	Parent = hud,
})

local settingsButton = UI.button({
	Position = UDim2.fromOffset(20, 184),
	Size = UDim2.fromOffset(220, 44),
	BackgroundColor3 = Color3.fromRGB(90, 90, 110),
	Text = "⚙️ Inställningar",
	Parent = hud,
})

-- Kycklingen man fick senast (för de vanliga, utan cutscene).
local display = UI.new("Frame", {
	AnchorPoint = Vector2.new(0.5, 1),
	Position = UDim2.new(0.5, 0, 1, -215),
	Size = UDim2.fromOffset(240, 280),
	BackgroundTransparency = 1,
	Parent = hud,
})
local displayScale = UI.new("UIScale", { Parent = display })
local viewport = UI.viewport({
	Size = UDim2.fromOffset(240, 200),
	BackgroundColor3 = UI.DARK,
	BackgroundTransparency = 0.3,
	Parent = display,
})
UI.corner(20).Parent = viewport
local viewportStroke = UI.stroke(4, UI.WHITE, Enum.ApplyStrokeMode.Border)
viewportStroke.Parent = viewport

local nameLabel = UI.label({
	Position = UDim2.fromOffset(-30, 205),
	Size = UDim2.fromOffset(300, 40),
	Text = "Tryck på tärningen!",
	Parent = display,
})
local infoLabel = UI.label({
	Position = UDim2.fromOffset(-30, 247),
	Size = UDim2.fromOffset(300, 26),
	Text = "",
	Parent = display,
})

-- Tärningen längst ner i mitten.
local dice = Dice.new({
	AnchorPoint = Vector2.new(0.5, 1),
	Position = UDim2.new(0.5, 0, 1, -30),
	Size = UDim2.fromOffset(120, 120),
	Parent = hud,
})

local costLabel = UI.label({
	AnchorPoint = Vector2.new(0.5, 1),
	Position = UDim2.new(0.5, 0, 1, -155),
	Size = UDim2.fromOffset(300, 24),
	Text = `Kostar {Config.ROLL_COST} 🪙`,
	TextColor3 = GOLD,
	Parent = hud,
})
local luckLabel = UI.label({
	AnchorPoint = Vector2.new(0.5, 1),
	Position = UDim2.new(0.5, 0, 1, -180),
	Size = UDim2.fromOffset(340, 24),
	Text = "",
	Parent = hud,
})

local autoButton = UI.button({
	AnchorPoint = Vector2.new(0.5, 1),
	Position = UDim2.new(0.5, -160, 1, -50),
	Size = UDim2.fromOffset(150, 64),
	BackgroundColor3 = Color3.fromRGB(200, 70, 70),
	Text = "Auto: AV",
	Parent = hud,
})
local inventoryButton = UI.button({
	AnchorPoint = Vector2.new(0.5, 1),
	Position = UDim2.new(0.5, 160, 1, -50),
	Size = UDim2.fromOffset(150, 64),
	BackgroundColor3 = Color3.fromRGB(60, 140, 230),
	Text = "🎒 Inventory",
	Parent = hud,
})

-- Meddelanden högst upp, t.ex. när någon rullar något ovanligt.
local banner = UI.label({
	AnchorPoint = Vector2.new(0.5, 0),
	Position = UDim2.new(0.5, 0, 0, 60),
	Size = UDim2.fromOffset(700, 40),
	Text = "",
	TextTransparency = 1,
	Parent = gui,
})
local bannerStroke = banner:FindFirstChildOfClass("UIStroke") :: UIStroke
bannerStroke.Transparency = 1

---------------------------------------------------------------------
-- Tillstånd från servern
---------------------------------------------------------------------

local state = {
	coins = 0,
	rolls = 0,
	owned = {},
	discovered = {},
	equipped = nil,
}
local potionEnds = 0
local shownCoins = 0

local function animateCoins(target: number)
	local from = shownCoins
	shownCoins = target
	local counter = UI.new("NumberValue", { Value = from })
	counter.Changed:Connect(function(value)
		coinLabel.Text = `🪙 {Chickens.formatNumber(value)}`
	end)
	local t = TweenService:Create(counter, TweenInfo.new(0.4), { Value = target })
	t.Completed:Connect(function()
		coinLabel.Text = `🪙 {Chickens.formatNumber(target)}`
		counter:Destroy()
	end)
	t:Play()
	if target > from then
		coinScale.Scale = 1.15
		TweenService:Create(coinScale, TweenInfo.new(0.3, Enum.EasingStyle.Back), { Scale = 1 }):Play()
	end
end

local function updateLuck()
	local left = Config.LUCK_EVERY - (state.rolls % Config.LUCK_EVERY)
	if left == 1 then
		luckLabel.Text = `🍀 Nästa rullning: TUR x{Config.LUCK_MULTIPLIER}!`
		luckLabel.TextColor3 = GREEN
	else
		luckLabel.Text = `🍀 Tur x{Config.LUCK_MULTIPLIER} om {left} rullningar`
		luckLabel.TextColor3 = UI.WHITE
	end
end

local function updateCost()
	local free = state.coins < Config.ROLL_COST and next(state.owned) == nil
	costLabel.Text = if free then "Gratis rullning!" else `Kostar {Config.ROLL_COST} 🪙`
	costLabel.TextColor3 = if free then GREEN elseif state.coins < Config.ROLL_COST then RED else GOLD
end

local inventory = Inventory.new(gui, {
	sell = function(id, amount, from)
		local ok, earned = pcall(sellRemote.InvokeServer, sellRemote, id, amount)
		if ok and earned and earned > 0 then
			Effects.popup(`+{Chickens.formatNumber(earned)} 🪙`, GOLD, Effects.centerOf(from))
			Effects.confetti(Effects.centerOf(from), 8, { GOLD, UI.WHITE }, 0.4)
		end
	end,
	sellCommon = function(from)
		local ok, earned = pcall(sellCommonRemote.InvokeServer, sellCommonRemote)
		if ok and earned and earned > 0 then
			Effects.popup(`+{Chickens.formatNumber(earned)} 🪙`, GOLD, Effects.centerOf(from))
			Effects.confetti(Effects.centerOf(from), 20, { GOLD, UI.WHITE }, 0.6)
		end
	end,
	equip = function(id)
		pcall(equipRemote.InvokeServer, equipRemote, id)
	end,
})

-- Inställningar: ändras direkt här och sparas på servern.
local function applySetting(key: string, value: any)
	if key == "shake" then
		Effects.shakeEnabled = value
	elseif key == "confetti" then
		Effects.confettiEnabled = value
	end
end

local settings = Settings.new(gui, function(key, value)
	applySetting(key, value)
	task.spawn(pcall, settingsRemote.InvokeServer, settingsRemote, key, value)
end)

local settingsLoaded = false
stateRemote.OnClientEvent:Connect(function(newState)
	if not settingsLoaded and newState.settings then
		settingsLoaded = true
		settings.load(newState.settings)
		for key, value in newState.settings do
			applySetting(key, value)
		end
	end
	local oldCoins = state.coins
	state = newState
	potionEnds = os.clock() + newState.luckSeconds
	if state.coins ~= oldCoins then
		animateCoins(state.coins)
	end
	inventory.update(state)
	updateLuck()
	updateCost()
end)

---------------------------------------------------------------------
-- Visa kycklingar
---------------------------------------------------------------------

local currentModel: Model? = nil

local function showChicken(chicken: Chickens.Chicken)
	if currentModel then
		currentModel:Destroy()
	end
	currentModel = ChickenModel.build(chicken)
	currentModel.Parent = viewport
	local rarity = Chickens.rarityOf(chicken)
	nameLabel.Text = chicken.name
	nameLabel.TextColor3 = rarity.color
	viewportStroke.Color = rarity.color
end

local function animateRainbow(model: Instance, t: number)
	for _, part in model:GetDescendants() do
		if part:IsA("BasePart") and part:GetAttribute("Rainbow") then
			part.Color = Color3.fromHSV((t * 0.3 + part.Position.Y * 0.1) % 1, 0.9, 1)
		end
	end
end

local pets = workspace:WaitForChild("Kycklingar")
RunService.RenderStepped:Connect(function()
	local t = os.clock()
	local model = currentModel
	if model then
		model:PivotTo(CFrame.Angles(0, math.sin(t * 1.5) * 0.6, 0))
		animateRainbow(model, t)
	end
	animateRainbow(pets, t)

	-- Göm andra spelares kycklingar om man valt det i inställningarna.
	for _, pet in pets:GetChildren() do
		local hidden = pet.Name ~= player.Name and not settings.values.showPets
		for _, part in pet:GetDescendants() do
			if part:IsA("BasePart") then
				part.LocalTransparencyModifier = if hidden then 1 else 0
			end
		end
	end

	-- Tur-dryckens nedräkning
	local potionLeft = potionEnds - t
	if potionLeft > 0 then
		potionButton.Text = `🧪 Tur x{Config.POTION_MULTIPLIER}: {math.ceil(potionLeft)} s`
		potionButton.BackgroundColor3 = Color3.fromRGB(70, 190, 90)
	else
		potionButton.Text = `🧪 Tur-dryck ({Config.POTION_COST} 🪙)`
		potionButton.BackgroundColor3 = Color3.fromRGB(150, 70, 220)
	end
end)

local bannerToken = 0
local function showBanner(text: string, color: Color3)
	if settings.values.hideBanner then
		return
	end
	bannerToken += 1
	local token = bannerToken
	banner.Text = text
	banner.TextColor3 = color
	banner.TextTransparency = 0
	bannerStroke.Transparency = 0
	task.delay(4, function()
		if token == bannerToken then
			local info = TweenInfo.new(0.5)
			TweenService:Create(banner, info, { TextTransparency = 1 }):Play()
			TweenService:Create(bannerStroke, info, { Transparency = 1 }):Play()
		end
	end)
end

-- Under cutscenen göms allt annat.
local autoRoll = false
Cutscene.onStart = function()
	hud.Visible = false
	inventory.frame.Visible = false
	settings.frame.Visible = false
	return true
end
Cutscene.onEnd = function()
	hud.Visible = true
end

---------------------------------------------------------------------
-- Rulla!
---------------------------------------------------------------------

local rolling = false

local function setAuto(on: boolean)
	autoRoll = on
	autoButton.Text = if on then "Auto: PÅ" else "Auto: AV"
	autoButton.BackgroundColor3 = if on then Color3.fromRGB(70, 190, 90) else Color3.fromRGB(200, 70, 70)
end

local function roll()
	if rolling then
		return
	end
	rolling = true

	local ok, result = pcall(rollRemote.InvokeServer, rollRemote)
	if not ok or not result then
		rolling = false
		return
	end
	if result.error then
		Effects.popup(result.error, RED, Effects.centerOf(dice.button) - Vector2.new(0, 90))
		dice.button.Rotation = 0
		TweenService
			:Create(dice.button, TweenInfo.new(0.05, Enum.EasingStyle.Linear, Enum.EasingDirection.InOut, 5, true), {
				Rotation = 10,
			})
			:Play()
		setAuto(false)
		task.wait(0.4)
		rolling = false
		return
	end

	local chicken = Chickens.byId[result.id]
	local rarity = Chickens.rarityOf(chicken)
	local tier = Chickens.tierOf(chicken)

	if result.free then
		Effects.popup("Gratis!", GREEN, Effects.centerOf(dice.button) - Vector2.new(0, 90))
	else
		Effects.popup(`-{Config.ROLL_COST} 🪙`, RED, Effects.centerOf(coinBox) + Vector2.new(60, 30))
	end
	if result.luck > 1 then
		infoLabel.Text = `🍀 TUR x{result.luck}!`
		infoLabel.TextColor3 = GREEN
		Effects.ring(Effects.centerOf(dice.button), GREEN, 300, 0.5)
	else
		infoLabel.Text = ""
	end

	-- Tärningen snurrar medan kycklingar flimrar förbi.
	local spinning = true
	task.spawn(function()
		while spinning do
			showChicken(Chickens.list[math.random(1, 10)])
			task.wait(0.07)
		end
	end)
	dice:tumble(if settings.values.fastRoll then 0.35 else 0.9)
	spinning = false

	if tier >= settings.values.cutsceneTier then
		Cutscene.play(chicken, result.isNew, autoRoll and tier <= 2)
	end
	if result.sold > 0 then
		Effects.popup(`Såld: +{result.sold} 🪙`, GOLD, Effects.centerOf(coinBox) + Vector2.new(60, 30))
	end

	showChicken(chicken)
	infoLabel.Text = `{rarity.name} · {Chickens.formatOdds(chicken)}`
	infoLabel.TextColor3 = rarity.color
	displayScale.Scale = 1.2
	TweenService:Create(displayScale, TweenInfo.new(0.3, Enum.EasingStyle.Back), { Scale = 1 }):Play()
	if result.isNew then
		nameLabel.Text = `NY! {chicken.name}`
		Effects.confetti(Effects.centerOf(viewport), 25, { rarity.color, UI.WHITE, GOLD }, 0.6)
	end

	task.wait(0.25)
	rolling = false
end

dice.button.Activated:Connect(function()
	task.spawn(roll)
end)

autoButton.Activated:Connect(function()
	setAuto(not autoRoll)
end)

-- Bara en meny öppen åt gången.
inventoryButton.Activated:Connect(function()
	settings.frame.Visible = false
	inventory.toggle()
end)
settingsButton.Activated:Connect(function()
	inventory.frame.Visible = false
	settings.toggle()
end)

potionButton.Activated:Connect(function()
	local ok, bought = pcall(potionRemote.InvokeServer, potionRemote)
	local center = Effects.centerOf(potionButton)
	if ok and bought then
		Effects.confetti(center, 30, { Color3.fromRGB(150, 70, 220), GREEN, UI.WHITE }, 0.7)
		Effects.ring(center, GREEN, 400, 0.6)
		Effects.popup("Tur x2! 🍀", GREEN, center + Vector2.new(0, 50))
	else
		Effects.popup("Inte råd!", RED, center + Vector2.new(0, 50))
	end
end)

announceRemote.OnClientEvent:Connect(function(playerName: string, chickenId: string)
	local chicken = Chickens.byId[chickenId]
	local rarity = Chickens.rarityOf(chicken)
	showBanner(`{playerName} rullade {chicken.name} ({Chickens.formatOdds(chicken)})!`, rarity.color)
end)

-- Be servern om vårt sparade tillstånd.
task.spawn(function()
	pcall(getStateRemote.InvokeServer, getStateRemote)
end)

-- Auto-rullning
task.spawn(function()
	while true do
		if autoRoll and not rolling then
			task.spawn(roll)
		end
		task.wait(0.2)
	end
end)
