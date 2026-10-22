-- Inställningsmenyn ⚙️. Varje rad är en knapp som slår på/av eller byter värde.
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Chickens = require(ReplicatedStorage.Shared.Chickens)
local Config = require(ReplicatedStorage.Shared.Config)
local UI = require(script.Parent.UI)

local Settings = {}

local ON = Color3.fromRGB(70, 190, 90)
local OFF = Color3.fromRGB(200, 70, 70)

-- Raderna i menyn, i ordning.
local ROWS = {
	{ key = "cutsceneTier", text = "🥚 Cutscene" },
	{ key = "fastRoll", text = "⚡ Snabb rullning" },
	{ key = "autoSell", text = "💰 Sälj Vanliga direkt" },
	{ key = "shake", text = "📳 Skärmskakning" },
	{ key = "confetti", text = "🎉 Konfetti" },
	{ key = "showPets", text = "🐔 Visa andras kycklingar" },
	{ key = "hideBanner", text = "📢 Dölj meddelanden" },
}

local function describe(key: string, value: any): (string, Color3)
	if key == "cutsceneTier" then
		if value > #Chickens.rarities then
			return "Aldrig", OFF
		end
		return `Från {Chickens.rarities[value].name}`, Chickens.rarities[value].color:Lerp(UI.BLACK, 0.3)
	end
	return if value then "PÅ" else "AV", if value then ON else OFF
end

function Settings.new(parent: Instance, onChange: (key: string, value: any) -> ())
	local values = table.clone(Config.DEFAULT_SETTINGS)

	local panel = UI.new("Frame", {
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.45),
		Size = UDim2.fromOffset(420, 70 + #ROWS * 52),
		BackgroundColor3 = UI.DARK,
		BackgroundTransparency = 0.05,
		Visible = false,
		Parent = parent,
	}, { UI.corner(18), UI.stroke(4, UI.BLACK, Enum.ApplyStrokeMode.Border) })

	UI.label({
		Position = UDim2.fromOffset(16, 10),
		Size = UDim2.new(1, -80, 0, 36),
		TextXAlignment = Enum.TextXAlignment.Left,
		Text = "⚙️ Inställningar",
		Parent = panel,
	})
	local closeButton = UI.button({
		AnchorPoint = Vector2.new(1, 0),
		Position = UDim2.new(1, -12, 0, 10),
		Size = UDim2.fromOffset(38, 38),
		BackgroundColor3 = OFF,
		Text = "X",
		Parent = panel,
	})
	closeButton.Activated:Connect(function()
		panel.Visible = false
	end)

	local buttons: { [string]: TextButton } = {}

	local function refresh()
		for key, button in buttons do
			local text, color = describe(key, values[key])
			button.Text = text
			button.BackgroundColor3 = color
		end
	end

	for index, row in ROWS do
		local y = 58 + (index - 1) * 52
		UI.label({
			Position = UDim2.fromOffset(18, y + 8),
			Size = UDim2.new(1, -190, 0, 28),
			TextXAlignment = Enum.TextXAlignment.Left,
			Text = row.text,
			Parent = panel,
		})
		local button = UI.button({
			AnchorPoint = Vector2.new(1, 0),
			Position = UDim2.new(1, -16, 0, y + 2),
			Size = UDim2.fromOffset(160, 42),
			Text = "",
			Parent = panel,
		})
		buttons[row.key] = button
		button.Activated:Connect(function()
			local value = values[row.key]
			if row.key == "cutsceneTier" then
				-- Ovanlig → Sällsynt → Episk → Legendarisk → Mytisk → Aldrig → Ovanlig ...
				value = if value >= #Chickens.rarities + 1 then 2 else value + 1
			else
				value = not value
			end
			values[row.key] = value
			refresh()
			onChange(row.key, value)
		end)
	end
	refresh()

	return {
		frame = panel,
		values = values,
		toggle = function()
			panel.Visible = not panel.Visible
		end,
		-- Läser in sparade inställningar från servern.
		load = function(saved: { [string]: any })
			for key, value in saved do
				values[key] = value
			end
			refresh()
		end,
	}
end

return Settings
