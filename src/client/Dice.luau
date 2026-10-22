-- Tärningen längst ner. Den visar olika sidor och snurrar när man rullar.
local TweenService = game:GetService("TweenService")

local UI = require(script.Parent.UI)

local Dice = {}
Dice.__index = Dice

-- Var prickarna kan sitta, och vilka som syns för varje sida.
local SPOTS = {
	TL = Vector2.new(0.25, 0.25),
	TR = Vector2.new(0.75, 0.25),
	ML = Vector2.new(0.25, 0.5),
	C = Vector2.new(0.5, 0.5),
	MR = Vector2.new(0.75, 0.5),
	BL = Vector2.new(0.25, 0.75),
	BR = Vector2.new(0.75, 0.75),
}
local FACES = {
	{ "C" },
	{ "TL", "BR" },
	{ "TL", "C", "BR" },
	{ "TL", "TR", "BL", "BR" },
	{ "TL", "TR", "C", "BL", "BR" },
	{ "TL", "TR", "ML", "MR", "BL", "BR" },
}

export type Dice = typeof(setmetatable(
	{} :: { button: TextButton, scale: UIScale, dots: { [string]: Frame }, face: number },
	Dice
))

function Dice.new(props: { [string]: any }): Dice
	props.BackgroundColor3 = UI.WHITE
	props.Text = ""
	props.AutoButtonColor = true
	local scale = UI.new("UIScale", {})
	local button = UI.new("TextButton", props, {
		UI.corner(24),
		UI.stroke(4, UI.BLACK, Enum.ApplyStrokeMode.Border),
		scale,
		UI.new("UIGradient", {
			Rotation = 90,
			Color = ColorSequence.new(UI.WHITE, Color3.fromRGB(210, 210, 225)),
		}),
	})

	local dots = {}
	for name, spot in SPOTS do
		dots[name] = UI.new("Frame", {
			AnchorPoint = Vector2.new(0.5, 0.5),
			Position = UDim2.fromScale(spot.X, spot.Y),
			Size = UDim2.fromScale(0.17, 0.17),
			BackgroundColor3 = Color3.fromRGB(30, 30, 30),
			Parent = button,
		}, { UI.corner(100) })
	end

	local self = setmetatable({ button = button, scale = scale, dots = dots, face = 1 }, Dice)
	self:setFace(math.random(1, 6))
	return self
end

function Dice.setFace(self: Dice, face: number)
	self.face = face
	for _, dot in self.dots do
		dot.Visible = false
	end
	for _, name in FACES[face] do
		self.dots[name].Visible = true
	end
	-- Sexan har röda prickar, som en lyckotärning.
	local color = if face == 6 then Color3.fromRGB(220, 40, 40) else Color3.fromRGB(30, 30, 30)
	for _, dot in self.dots do
		dot.BackgroundColor3 = color
	end
end

-- Snurrar tärningen och byter sida allt långsammare. Väntar tills den är klar.
function Dice.tumble(self: Dice, duration: number)
	local steps = 12
	local last = self.face
	for i = 1, steps do
		local face = math.random(1, 5)
		if face >= last then
			face += 1 -- aldrig samma sida två gånger i rad
		end
		last = face
		self:setFace(face)
		self.button.Rotation = math.random(-25, 25)
		self.scale.Scale = 1.15
		TweenService:Create(self.scale, TweenInfo.new(0.08), { Scale = 1 }):Play()
		task.wait(duration / steps * (0.4 + (i / steps) ^ 2 * 1.6))
	end
	TweenService:Create(self.button, TweenInfo.new(0.3, Enum.EasingStyle.Back), { Rotation = 0 }):Play()
	self.scale.Scale = 1.3
	TweenService:Create(self.scale, TweenInfo.new(0.35, Enum.EasingStyle.Bounce), { Scale = 1 }):Play()
end

return Dice
