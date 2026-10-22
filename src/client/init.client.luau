-- Allt spelaren ser: tärningsknappen, kycklingen som rullas fram och samlingen.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")

local Chickens = require(ReplicatedStorage.Shared.Chickens)
local ChickenModel = require(ReplicatedStorage.Shared.ChickenModel)

local player = Players.LocalPlayer
local remotes = ReplicatedStorage:WaitForChild("Remotes")
local rollRemote = remotes:WaitForChild("Roll") :: RemoteFunction
local getDataRemote = remotes:WaitForChild("GetData") :: RemoteFunction
local announceRemote = remotes:WaitForChild("Announce") :: RemoteEvent

local FONT = Enum.Font.FredokaOne
local WHITE = Color3.new(1, 1, 1)

-- Liten hjälpfunktion för att skapa UI snabbt.
local function new(className: string, props: { [string]: any }, children: { Instance }?): any
	local instance = Instance.new(className)
	for key, value in props do
		if key ~= "Parent" then
			(instance :: any)[key] = value
		end
	end
	for _, child in children or {} do
		child.Parent = instance
	end
	instance.Parent = props.Parent
	return instance
end

local function corner(radius: number)
	return new("UICorner", { CornerRadius = UDim.new(0, radius) })
end

local function stroke(thickness: number, color: Color3?)
	return new("UIStroke", { Thickness = thickness, Color = color or Color3.new(0, 0, 0) })
end

local function label(props: { [string]: any }): TextLabel
	props.BackgroundTransparency = props.BackgroundTransparency or 1
	props.Font = props.Font or FONT
	props.TextColor3 = props.TextColor3 or WHITE
	props.TextScaled = true
	return new("TextLabel", props, { stroke(2) })
end

---------------------------------------------------------------------
-- Gränssnittet
---------------------------------------------------------------------

local gui = new("ScreenGui", {
	Name = "KycklingRNG",
	ResetOnSpawn = false,
	IgnoreGuiInset = true,
	Parent = player:WaitForChild("PlayerGui"),
})

-- Vit blixt när man får något ovanligt.
local flash = new("Frame", {
	Size = UDim2.fromScale(1, 1),
	BackgroundColor3 = WHITE,
	BackgroundTransparency = 1,
	ZIndex = 10,
	Parent = gui,
})

-- Kycklingen som visas i mitten.
local display = new("Frame", {
	AnchorPoint = Vector2.new(0.5, 1),
	Position = UDim2.new(0.5, 0, 1, -170),
	Size = UDim2.fromOffset(300, 360),
	BackgroundTransparency = 1,
	Parent = gui,
})

local viewport = new("ViewportFrame", {
	Size = UDim2.fromOffset(300, 260),
	BackgroundColor3 = Color3.fromRGB(30, 30, 45),
	BackgroundTransparency = 0.3,
	Ambient = Color3.fromRGB(170, 170, 170),
	LightColor = WHITE,
	LightDirection = Vector3.new(-1, -1, 1),
	Parent = display,
}, { corner(20) })
local viewportStroke = stroke(4, WHITE)
viewportStroke.Parent = viewport

local camera = new("Camera", {
	FieldOfView = 40,
	CFrame = CFrame.lookAt(Vector3.new(3.5, 3.5, -8), Vector3.new(0, 2, 0)),
	Parent = viewport,
})
viewport.CurrentCamera = camera

local nameLabel = label({
	Position = UDim2.fromOffset(0, 265),
	Size = UDim2.fromOffset(300, 45),
	Text = "Tryck på tärningen!",
	Parent = display,
})

local infoLabel = label({
	Position = UDim2.fromOffset(0, 312),
	Size = UDim2.fromOffset(300, 30),
	Text = "",
	Parent = display,
})

-- Tärningen längst ner i mitten.
local diceButton = new("TextButton", {
	AnchorPoint = Vector2.new(0.5, 1),
	Position = UDim2.new(0.5, 0, 1, -25),
	Size = UDim2.fromOffset(120, 120),
	BackgroundColor3 = WHITE,
	Text = "",
	AutoButtonColor = true,
	Parent = gui,
}, { corner(24), stroke(4) })

-- Prickarna på tärningen (en femma).
for _, dot in { { 0.25, 0.25 }, { 0.75, 0.25 }, { 0.5, 0.5 }, { 0.25, 0.75 }, { 0.75, 0.75 } } do
	new("Frame", {
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(dot[1], dot[2]),
		Size = UDim2.fromScale(0.17, 0.17),
		BackgroundColor3 = Color3.fromRGB(30, 30, 30),
		Parent = diceButton,
	}, { corner(100) })
end

local luckLabel = label({
	AnchorPoint = Vector2.new(0.5, 1),
	Position = UDim2.new(0.5, 0, 1, -150),
	Size = UDim2.fromOffset(300, 22),
	Text = "",
	Parent = gui,
})

local function sideButton(text: string, xOffset: number, color: Color3): TextButton
	return new("TextButton", {
		AnchorPoint = Vector2.new(0.5, 1),
		Position = UDim2.new(0.5, xOffset, 1, -45),
		Size = UDim2.fromOffset(130, 60),
		BackgroundColor3 = color,
		Font = FONT,
		TextColor3 = WHITE,
		TextScaled = true,
		Text = text,
		Parent = gui,
	}, { corner(14), stroke(3), new("UIPadding", { PaddingTop = UDim.new(0, 8), PaddingBottom = UDim.new(0, 8) }) })
end

local autoButton = sideButton("Auto: AV", -150, Color3.fromRGB(200, 70, 70))
local collectionButton = sideButton("Samling", 150, Color3.fromRGB(60, 140, 230))

-- Meddelanden högst upp, t.ex. när någon rullar något ovanligt.
local banner = label({
	AnchorPoint = Vector2.new(0.5, 0),
	Position = UDim2.new(0.5, 0, 0, 60),
	Size = UDim2.fromOffset(700, 40),
	Text = "",
	TextTransparency = 1,
	Parent = gui,
})
local bannerStroke = banner:FindFirstChildOfClass("UIStroke") :: UIStroke
bannerStroke.Transparency = 1

-- Samlingen: en lista över alla kycklingar.
local collectionPanel = new("Frame", {
	AnchorPoint = Vector2.new(1, 0.5),
	Position = UDim2.new(1, -20, 0.5, 0),
	Size = UDim2.fromOffset(340, 440),
	BackgroundColor3 = Color3.fromRGB(30, 30, 45),
	BackgroundTransparency = 0.1,
	Visible = false,
	Parent = gui,
}, { corner(16), stroke(3) })

local collectionTitle = label({
	Position = UDim2.fromOffset(0, 8),
	Size = UDim2.new(1, 0, 0, 34),
	Text = "Samling",
	Parent = collectionPanel,
})

local list = new("ScrollingFrame", {
	Position = UDim2.fromOffset(10, 50),
	Size = UDim2.new(1, -20, 1, -60),
	BackgroundTransparency = 1,
	BorderSizePixel = 0,
	ScrollBarThickness = 6,
	AutomaticCanvasSize = Enum.AutomaticSize.Y,
	CanvasSize = UDim2.new(),
	Parent = collectionPanel,
}, { new("UIListLayout", { Padding = UDim.new(0, 6), SortOrder = Enum.SortOrder.LayoutOrder }) })

local rows: { [string]: { name: TextLabel, count: TextLabel } } = {}
for index, chicken in Chickens.list do
	local rarity = Chickens.rarityOf(chicken)
	local row = new("Frame", {
		LayoutOrder = index,
		Size = UDim2.new(1, -8, 0, 44),
		BackgroundColor3 = rarity.color,
		BackgroundTransparency = 0.6,
		Parent = list,
	}, { corner(10) })
	rows[chicken.id] = {
		name = label({
			Position = UDim2.fromOffset(8, 3),
			Size = UDim2.new(0.62, -8, 0, 22),
			TextXAlignment = Enum.TextXAlignment.Left,
			Text = "???",
			Parent = row,
		}),
		count = label({
			Position = UDim2.new(0.62, 0, 0, 3),
			Size = UDim2.new(0.38, -8, 0, 22),
			TextXAlignment = Enum.TextXAlignment.Right,
			Text = "",
			Parent = row,
		}),
	}
	label({
		Position = UDim2.fromOffset(8, 25),
		Size = UDim2.new(1, -16, 0, 16),
		TextXAlignment = Enum.TextXAlignment.Left,
		TextColor3 = rarity.color,
		Text = `{rarity.name} · {Chickens.formatOdds(chicken)}`,
		Parent = row,
	})
end

---------------------------------------------------------------------
-- Visa kycklingar
---------------------------------------------------------------------

local currentModel: Model? = nil
local counts: { [string]: number } = {}
local totalRolls = 0
local luckEvery = 10
local luckMultiplier = 2

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

-- Kycklingen gungar lite, och regnbågskycklingar byter färg.
RunService.RenderStepped:Connect(function()
	local model = currentModel
	if not model then
		return
	end
	local t = os.clock()
	model:PivotTo(CFrame.Angles(0, math.sin(t * 1.5) * 0.6, 0))
	for _, part in model:GetDescendants() do
		if part:IsA("BasePart") and part:GetAttribute("Rainbow") then
			part.Color = Color3.fromHSV((t * 0.3 + part.Position.Y * 0.1) % 1, 0.9, 1)
		end
	end
end)

local function updateCollection()
	local found = 0
	for _, chicken in Chickens.list do
		local count = counts[chicken.id] or 0
		local row = rows[chicken.id]
		if count > 0 then
			found += 1
			row.name.Text = chicken.name
			row.count.Text = `x{Chickens.formatNumber(count)}`
		end
	end
	collectionTitle.Text = `Samling ({found}/{#Chickens.list})`
end

local function updateLuck()
	local left = luckEvery - (totalRolls % luckEvery)
	if left == 1 then
		luckLabel.Text = `🍀 Nästa rullning: TUR x{luckMultiplier}!`
		luckLabel.TextColor3 = Color3.fromRGB(120, 255, 120)
	else
		luckLabel.Text = `🍀 Tur x{luckMultiplier} om {left} rullningar`
		luckLabel.TextColor3 = WHITE
	end
end

local bannerToken = 0
local function showBanner(text: string, color: Color3)
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

local function flashScreen()
	flash.BackgroundTransparency = 0.2
	TweenService:Create(flash, TweenInfo.new(0.8), { BackgroundTransparency = 1 }):Play()
end

---------------------------------------------------------------------
-- Rulla!
---------------------------------------------------------------------

local rolling = false
local autoRoll = false

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
	local chicken = Chickens.byId[result.id]
	local rare = chicken.odds >= 1000

	-- Snurra igenom slumpade kycklingar, och sakta ner mot slutet.
	-- Ovanliga kycklingar får en längre och spännande snurr.
	infoLabel.Text = if result.lucky then "🍀 TUR-RULLNING!" else ""
	infoLabel.TextColor3 = Color3.fromRGB(120, 255, 120)
	local spins = if rare then 18 else 10
	for i = 1, spins do
		local teaser = Chickens.list[math.random(1, math.min(#Chickens.list, 12))]
		showChicken(teaser)
		task.wait(0.03 + (i / spins) ^ 3 * (if rare then 0.35 else 0.15))
	end

	showChicken(chicken)
	local rarity = Chickens.rarityOf(chicken)
	infoLabel.Text = `{rarity.name} · {Chickens.formatOdds(chicken)}`
	infoLabel.TextColor3 = rarity.color

	local isNew = (counts[chicken.id] or 0) == 0
	counts[chicken.id] = result.count
	totalRolls = result.rolls
	updateCollection()
	updateLuck()

	if isNew then
		nameLabel.Text = `NY! {chicken.name}`
	end
	if rare then
		flashScreen()
	end

	-- Tärningen studsar till.
	diceButton.Rotation = 0
	TweenService:Create(diceButton, TweenInfo.new(0.25, Enum.EasingStyle.Back), { Rotation = 360 }):Play()

	task.wait(if rare then 1.5 else 0.3)
	rolling = false
end

diceButton.Activated:Connect(function()
	task.spawn(roll)
end)

autoButton.Activated:Connect(function()
	autoRoll = not autoRoll
	autoButton.Text = if autoRoll then "Auto: PÅ" else "Auto: AV"
	autoButton.BackgroundColor3 = if autoRoll then Color3.fromRGB(70, 190, 90) else Color3.fromRGB(200, 70, 70)
end)

collectionButton.Activated:Connect(function()
	collectionPanel.Visible = not collectionPanel.Visible
end)

announceRemote.OnClientEvent:Connect(function(playerName: string, chickenId: string)
	local chicken = Chickens.byId[chickenId]
	local rarity = Chickens.rarityOf(chicken)
	showBanner(`{playerName} rullade {chicken.name} ({Chickens.formatOdds(chicken)})!`, rarity.color)
end)

-- Hämta sparad samling från servern.
task.spawn(function()
	local ok, data = pcall(getDataRemote.InvokeServer, getDataRemote)
	if ok and data then
		counts = data.counts
		totalRolls = data.rolls
		luckEvery = data.luckEvery
		luckMultiplier = data.luckMultiplier
	end
	updateCollection()
	updateLuck()
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
