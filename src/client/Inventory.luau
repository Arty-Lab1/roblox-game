-- Inventoryt: alla kycklingar man har, med knappar för att sälja och utrusta.
-- Kycklingar man inte hittat än visas som svarta siluetter.
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Chickens = require(ReplicatedStorage.Shared.Chickens)
local ChickenModel = require(ReplicatedStorage.Shared.ChickenModel)
local UI = require(script.Parent.UI)

local Inventory = {}

export type Callbacks = {
	sell: (id: string, amount: number, from: GuiObject) -> (),
	sellCommon: (from: GuiObject) -> (),
	equip: (id: string) -> (),
}

type Card = {
	frame: Frame,
	viewport: ViewportFrame,
	name: TextLabel,
	count: TextLabel,
	sellOne: TextButton,
	sellAll: TextButton,
	equip: TextButton,
	discovered: boolean?,
}

local function setModel(viewport: ViewportFrame, chicken: Chickens.Chicken, silhouette: boolean)
	for _, child in viewport:GetChildren() do
		if child:IsA("Model") then
			child:Destroy()
		end
	end
	local model = ChickenModel.build(chicken)
	if silhouette then
		for _, part in model:GetDescendants() do
			if part:IsA("BasePart") then
				part.Color = UI.BLACK
				part.Material = Enum.Material.SmoothPlastic
				part.Transparency = 0
				part:SetAttribute("Rainbow", nil)
			end
		end
	end
	model:PivotTo(CFrame.Angles(0, 0.4, 0))
	model.Parent = viewport
end

function Inventory.new(parent: Instance, callbacks: Callbacks)
	local panel = UI.new("Frame", {
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.45),
		Size = UDim2.fromOffset(560, 470),
		BackgroundColor3 = UI.DARK,
		BackgroundTransparency = 0.05,
		Visible = false,
		Parent = parent,
	}, { UI.corner(18), UI.stroke(4, UI.BLACK, Enum.ApplyStrokeMode.Border) })
	UI.new("UISizeConstraint", { MaxSize = Vector2.new(560, 470), Parent = panel })

	local title = UI.label({
		Position = UDim2.fromOffset(16, 10),
		Size = UDim2.new(1, -250, 0, 36),
		TextXAlignment = Enum.TextXAlignment.Left,
		Text = "Inventory",
		Parent = panel,
	})

	local sellCommonButton = UI.button({
		AnchorPoint = Vector2.new(1, 0),
		Position = UDim2.new(1, -60, 0, 10),
		Size = UDim2.fromOffset(170, 38),
		BackgroundColor3 = Color3.fromRGB(230, 150, 30),
		Text = "Sälj vanliga",
		Parent = panel,
	})
	sellCommonButton.Activated:Connect(function()
		callbacks.sellCommon(sellCommonButton)
	end)

	local closeButton = UI.button({
		AnchorPoint = Vector2.new(1, 0),
		Position = UDim2.new(1, -12, 0, 10),
		Size = UDim2.fromOffset(38, 38),
		BackgroundColor3 = Color3.fromRGB(220, 60, 60),
		Text = "X",
		Parent = panel,
	})
	closeButton.Activated:Connect(function()
		panel.Visible = false
	end)

	local scroll = UI.new("ScrollingFrame", {
		Position = UDim2.fromOffset(12, 58),
		Size = UDim2.new(1, -24, 1, -70),
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		ScrollBarThickness = 8,
		AutomaticCanvasSize = Enum.AutomaticSize.Y,
		CanvasSize = UDim2.new(),
		Parent = panel,
	}, {
		UI.new("UIGridLayout", {
			CellSize = UDim2.fromOffset(160, 210),
			CellPadding = UDim2.fromOffset(10, 10),
			SortOrder = Enum.SortOrder.LayoutOrder,
		}),
		UI.new("UIPadding", { PaddingTop = UDim.new(0, 4), PaddingLeft = UDim.new(0, 4) }),
	})

	local cards: { [string]: Card } = {}
	for index, chicken in Chickens.list do
		local rarity = Chickens.rarityOf(chicken)
		local frame = UI.new("Frame", {
			LayoutOrder = index,
			BackgroundColor3 = rarity.color:Lerp(UI.DARK, 0.65),
			Parent = scroll,
		}, { UI.corner(12), UI.stroke(3, rarity.color, Enum.ApplyStrokeMode.Border) })

		local viewport = UI.viewport({
			Position = UDim2.fromOffset(5, 5),
			Size = UDim2.new(1, -10, 0, 95),
			BackgroundTransparency = 1,
			Parent = frame,
		})
		setModel(viewport, chicken, true)

		local name = UI.label({
			Position = UDim2.fromOffset(5, 100),
			Size = UDim2.new(1, -10, 0, 20),
			Text = "???",
			Parent = frame,
		})
		UI.label({
			Position = UDim2.fromOffset(5, 120),
			Size = UDim2.new(1, -10, 0, 15),
			Text = Chickens.formatOdds(chicken),
			TextColor3 = rarity.color,
			Parent = frame,
		})
		local count = UI.label({
			AnchorPoint = Vector2.new(1, 0),
			Position = UDim2.new(1, -8, 0, 6),
			Size = UDim2.fromOffset(60, 22),
			TextXAlignment = Enum.TextXAlignment.Right,
			Text = "",
			Parent = frame,
		})

		local sellOne = UI.button({
			Position = UDim2.fromOffset(6, 140),
			Size = UDim2.new(0.5, -9, 0, 30),
			BackgroundColor3 = Color3.fromRGB(230, 150, 30),
			Text = "Sälj 1",
			Parent = frame,
		})
		local sellAll = UI.button({
			Position = UDim2.new(0.5, 3, 0, 140),
			Size = UDim2.new(0.5, -9, 0, 30),
			BackgroundColor3 = Color3.fromRGB(200, 90, 30),
			Text = "Sälj alla",
			Parent = frame,
		})
		local equip = UI.button({
			Position = UDim2.fromOffset(6, 174),
			Size = UDim2.new(1, -12, 0, 30),
			BackgroundColor3 = Color3.fromRGB(60, 140, 230),
			Text = "Utrusta",
			Parent = frame,
		})

		local card: Card = {
			frame = frame,
			viewport = viewport,
			name = name,
			count = count,
			sellOne = sellOne,
			sellAll = sellAll,
			equip = equip,
		}
		cards[chicken.id] = card

		sellOne.Activated:Connect(function()
			callbacks.sell(chicken.id, 1, sellOne)
		end)
		sellAll.Activated:Connect(function()
			callbacks.sell(chicken.id, 1e9, sellAll)
		end)
		equip.Activated:Connect(function()
			callbacks.equip(chicken.id)
		end)
	end

	local function update(state)
		local found = 0
		local total = 0
		for _, chicken in Chickens.list do
			local card = cards[chicken.id]
			local owned = state.owned[chicken.id] or 0
			local discovered = state.discovered[chicken.id] == true
			total += owned
			if discovered then
				found += 1
			end
			if discovered ~= card.discovered then
				card.discovered = discovered
				setModel(card.viewport, chicken, not discovered)
				card.name.Text = if discovered then chicken.name else "???"
			end
			card.count.Text = if owned > 0 then `x{Chickens.formatNumber(owned)}` else ""
			card.sellOne.Visible = owned > 0
			card.sellAll.Visible = owned > 0
			card.equip.Visible = owned > 0
			local equipped = state.equipped == chicken.id
			card.equip.Text = if equipped then "Utrustad ✓" else "Utrusta"
			card.equip.BackgroundColor3 = if equipped then Color3.fromRGB(70, 190, 90) else Color3.fromRGB(60, 140, 230)
			card.sellOne.Text = `Sälj 1 ({Chickens.formatNumber(Chickens.valueOf(chicken))})`
		end
		title.Text = `Inventory · {found}/{#Chickens.list} hittade · {Chickens.formatNumber(total)} st`
	end

	return {
		frame = panel,
		update = update,
		toggle = function()
			panel.Visible = not panel.Visible
		end,
	}
end

return Inventory
