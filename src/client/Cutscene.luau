-- Cutscenen som spelas när man får en kyckling som är 1 på 10 eller ovanligare.
-- Ett ägg dyker upp, nivåerna klättrar uppåt (Vanlig → Ovanlig → ...),
-- ägget spricker, exploderar och kycklingen visas.
local Lighting = game:GetService("Lighting")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Chickens = require(ReplicatedStorage.Shared.Chickens)
local ChickenModel = require(ReplicatedStorage.Shared.ChickenModel)
local Effects = require(script.Parent.Effects)
local UI = require(script.Parent.UI)

local Cutscene = {}

local player = Players.LocalPlayer
local GOLD = Color3.fromRGB(255, 215, 60)

local blur = UI.new("BlurEffect", { Name = "KycklingBlur", Size = 0, Parent = Lighting })
local colorCorrection = UI.new("ColorCorrectionEffect", { Name = "KycklingFärg", Parent = Lighting })

local function tween(
	instance: Instance,
	duration: number,
	goal: { [string]: any },
	style: Enum.EasingStyle?,
	direction: Enum.EasingDirection?
)
	local t = TweenService:Create(
		instance,
		TweenInfo.new(duration, style or Enum.EasingStyle.Quad, direction or Enum.EasingDirection.Out),
		goal
	)
	t:Play()
	return t
end

local function rainbow(t: number, offset: number?): Color3
	return Color3.fromHSV((t * 0.5 + (offset or 0)) % 1, 0.85, 1)
end

-- Spelar cutscenen och väntar tills spelaren klickat vidare.
-- fast = kortare version (används för Ovanliga när auto-rull är på).
function Cutscene.play(chicken: Chickens.Chicken, isNew: boolean, fast: boolean)
	local targetTier = Chickens.tierOf(chicken)
	local target = Chickens.rarities[targetTier]
	local isMythic = targetTier >= 6
	local speed = if fast then 0.45 else 1

	local function pause(seconds: number)
		task.wait(seconds * speed)
	end

	---------------------------------------------------------------
	-- Bygg scenen
	---------------------------------------------------------------
	local gui = UI.new("ScreenGui", {
		Name = "Cutscene",
		IgnoreGuiInset = true,
		ResetOnSpawn = false,
		DisplayOrder = 10,
		Parent = player:WaitForChild("PlayerGui"),
	})

	local darkness = UI.new("Frame", {
		Size = UDim2.fromScale(1, 1),
		BackgroundColor3 = UI.BLACK,
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		Parent = gui,
	})

	local topBar = UI.new("Frame", {
		Size = UDim2.fromScale(1, 0),
		BackgroundColor3 = UI.BLACK,
		BorderSizePixel = 0,
		ZIndex = 20,
		Parent = gui,
	})
	local bottomBar = UI.new("Frame", {
		AnchorPoint = Vector2.new(0, 1),
		Position = UDim2.fromScale(0, 1),
		Size = UDim2.fromScale(1, 0),
		BackgroundColor3 = UI.BLACK,
		BorderSizePixel = 0,
		ZIndex = 20,
		Parent = gui,
	})

	-- Allt i mitten ligger i "stage", som skakar när skärmen skakar.
	local stage = UI.new("Frame", {
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.5),
		Size = UDim2.fromScale(0.6, 0.6),
		BackgroundTransparency = 1,
		Parent = gui,
	}, { UI.new("UIAspectRatioConstraint", { AspectRatio = 1 }) })
	local stageScale = UI.new("UIScale", { Parent = stage })

	-- Ljusstrålar som snurrar bakom ägget.
	local rays = UI.new("Frame", {
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.5),
		Size = UDim2.fromScale(2.4, 2.4),
		BackgroundTransparency = 1,
		Parent = stage,
	})
	local rayFrames: { Frame } = {}
	for i = 0, 11 do
		local ray = UI.new("Frame", {
			AnchorPoint = Vector2.new(0.5, 0.5),
			Position = UDim2.fromScale(0.5, 0.5),
			Size = UDim2.fromScale(if i % 2 == 0 then 0.07 else 0.04, 1),
			Rotation = i * 15,
			BackgroundColor3 = UI.WHITE,
			BackgroundTransparency = 1,
			BorderSizePixel = 0,
			Parent = rays,
		}, {
			UI.new("UIGradient", {
				Rotation = 90,
				Transparency = NumberSequence.new({
					NumberSequenceKeypoint.new(0, 1),
					NumberSequenceKeypoint.new(0.5, 0),
					NumberSequenceKeypoint.new(1, 1),
				}),
			}),
		})
		table.insert(rayFrames, ray)
	end

	-- Ett runt sken bakom ägget.
	local glow = UI.new("Frame", {
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.5),
		Size = UDim2.fromScale(0.75, 0.75),
		BackgroundColor3 = UI.WHITE,
		BackgroundTransparency = 1,
		Parent = stage,
	}, {
		UI.corner(1000),
		UI.new("UIGradient", {
			Transparency = NumberSequence.new({
				NumberSequenceKeypoint.new(0, 1),
				NumberSequenceKeypoint.new(0.5, 0.3),
				NumberSequenceKeypoint.new(1, 1),
			}),
		}),
	})

	local viewport, camera = UI.viewport({
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.5),
		Size = UDim2.fromScale(1, 1),
		BackgroundTransparency = 1,
		Ambient = Color3.fromRGB(200, 200, 200),
		Parent = stage,
	})
	local viewportScale = UI.new("UIScale", { Scale = 0, Parent = viewport })
	camera.CFrame = CFrame.lookAt(Vector3.new(0, 1.8, -8.5), Vector3.new(0, 1.4, 0))

	local cracks = UI.new("Frame", {
		Size = UDim2.fromScale(1, 1),
		BackgroundTransparency = 1,
		Parent = stage,
	})

	local tierLabel = UI.label({
		AnchorPoint = Vector2.new(0.5, 1),
		Position = UDim2.fromScale(0.5, 0.1),
		Size = UDim2.fromScale(1.3, 0.16),
		Text = "",
		Parent = stage,
	})
	local tierScale = UI.new("UIScale", { Parent = tierLabel })

	local subLabel = UI.label({
		AnchorPoint = Vector2.new(0.5, 0),
		Position = UDim2.fromScale(0.5, 0.86),
		Size = UDim2.fromScale(1.2, 0.08),
		Text = "",
		Parent = stage,
	})

	Effects.addShakeTarget(stage)

	---------------------------------------------------------------
	-- Animation varje bildruta
	---------------------------------------------------------------
	local egg: Model? = ChickenModel.buildEgg()
	egg.Parent = viewport
	local chickenModel: Model? = nil
	local rayColor = UI.WHITE
	local raySpeed = 20
	local rayAlpha = 1 -- 1 = osynliga
	local wobble = 0.05
	local hop = 0
	local spin = 0
	local chickenScale = 0
	local rainbowRays = false
	local start = os.clock()

	local connection = RunService.RenderStepped:Connect(function(dt)
		local t = os.clock() - start
		rays.Rotation += raySpeed * dt
		for index, ray in rayFrames do
			ray.BackgroundColor3 = if rainbowRays then rainbow(t, index / 12) else rayColor
			ray.BackgroundTransparency = rayAlpha
		end
		glow.BackgroundColor3 = if rainbowRays then rainbow(t) else rayColor
		glow.BackgroundTransparency = math.clamp(rayAlpha * 0.8 + math.sin(t * 6) * 0.08, 0, 1)

		if egg then
			local tilt = math.sin(t * 18) * wobble
			egg:PivotTo(CFrame.new(0, hop, 0) * CFrame.Angles(0, math.sin(t * 2) * 0.3, tilt))
			hop = math.max(0, hop - dt * 4)
		end
		local model = chickenModel
		if model then
			spin = spin + (0 - spin) * math.min(1, dt * 3)
			model:PivotTo(CFrame.Angles(0, math.sin(t * 1.5) * 0.5 + spin, 0))
			model:ScaleTo(math.max(0.01, chickenScale * (chicken.scale or 1)))
			for _, part in model:GetDescendants() do
				if part:IsA("BasePart") and part:GetAttribute("Rainbow") then
					part.Color = Color3.fromHSV((t * 0.3 + part.Position.Y * 0.1) % 1, 0.9, 1)
				end
			end
		end
		if rainbowRays then
			tierLabel.TextColor3 = rainbow(t)
		end
	end)

	---------------------------------------------------------------
	-- 1. Öppning: mörkt, suddigt och svarta filmkanter
	---------------------------------------------------------------
	local hudHidden = Cutscene.onStart and Cutscene.onStart()
	tween(topBar, 0.5, { Size = UDim2.fromScale(1, 0.1) })
	tween(bottomBar, 0.5, { Size = UDim2.fromScale(1, 0.1) })
	tween(darkness, 0.5, { BackgroundTransparency = 0.35 })
	tween(blur, 0.5, { Size = 24 })
	tween(colorCorrection, 0.5, { Saturation = -0.8, Brightness = -0.1, Contrast = 0.2 })
	tween(viewportScale, 0.6, { Scale = 1 }, Enum.EasingStyle.Back)
	subLabel.Text = "Något händer..."
	pause(0.7)

	---------------------------------------------------------------
	-- 2. Nivåerna klättrar uppåt
	---------------------------------------------------------------
	local firstTier = if fast then targetTier else 1
	for tier = firstTier, targetTier do
		local rarity = Chickens.rarities[tier]
		local isLast = tier == targetTier

		-- Innan Mytisk: allt blir tyst och mörkt en stund...
		if isLast and isMythic and not fast then
			tierLabel.Text = "..."
			tierLabel.TextColor3 = UI.WHITE
			subLabel.Text = "Vänta lite..."
			tween(darkness, 0.4, { BackgroundTransparency = 0.05 })
			rayAlpha = 1
			wobble = 0.02
			task.wait(1.4)
			tween(darkness, 0.2, { BackgroundTransparency = 0.35 })
		end

		rayColor = rarity.color
		rayAlpha = math.max(0.1, 0.75 - tier * 0.1)
		raySpeed = 20 + tier * 25
		wobble = 0.05 + tier * 0.05
		hop = 0.4 + tier * 0.1
		rainbowRays = isLast and isMythic

		tierLabel.Text = string.upper(rarity.name) .. (if isLast then "!" else "?")
		tierLabel.TextColor3 = rarity.color
		tierScale.Scale = 1.8
		tween(tierScale, 0.3, { Scale = 1 }, Enum.EasingStyle.Back)
		subLabel.Text = if isLast then "" else string.rep(".", tier)

		for _, part in (egg :: Model):GetDescendants() do
			if part:IsA("BasePart") and part:GetAttribute("Spot") then
				part.Color = rarity.color
				part.Material = if tier >= 3 then Enum.Material.Neon else Enum.Material.SmoothPlastic
			end
		end

		local center = Effects.centerOf(stage)
		Effects.ring(center, rarity.color, stage.AbsoluteSize.X * (0.8 + tier * 0.15), 0.6)
		Effects.confetti(center, tier * 4, { rarity.color, UI.WHITE }, 0.5)
		Effects.shake(2 + tier * 2, 0.25)
		tween(colorCorrection, 0.3, { TintColor = rarity.color:Lerp(UI.WHITE, 0.6) })

		-- Hjärtslag: hela scenen pulserar för de ovanliga nivåerna.
		if tier >= 4 then
			stageScale.Scale = 1.08
			tween(stageScale, 0.25, { Scale = 1 })
		end

		if isLast then
			pause(0.9 + tier * 0.15)
		else
			pause(math.max(0.25, 0.65 - tier * 0.07))
		end
	end

	---------------------------------------------------------------
	-- 3. Ägget spricker
	---------------------------------------------------------------
	local crackCount = if fast then 1 else math.clamp(targetTier, 2, 4)
	for _ = 1, crackCount do
		local point = Vector2.new(0.5 + (math.random() - 0.5) * 0.12, 0.42 + (math.random() - 0.5) * 0.2)
		local angle = math.random() * 360
		for _ = 1, 4 do
			local length = 0.04 + math.random() * 0.05
			angle += math.random(-50, 50)
			local direction = Vector2.new(math.cos(math.rad(angle)), math.sin(math.rad(angle)))
			local middle = point + direction * length / 2
			UI.new("Frame", {
				AnchorPoint = Vector2.new(0.5, 0.5),
				Position = UDim2.fromScale(middle.X, middle.Y),
				Size = UDim2.new(length, 0, 0, 5),
				Rotation = angle,
				BackgroundColor3 = target.color,
				BorderSizePixel = 0,
				Parent = cracks,
			}, { UI.stroke(1.5, UI.BLACK) })
			point += direction * length
		end
		hop = 0.6
		wobble += 0.08
		Effects.shake(5 + targetTier * 2, 0.2)
		Effects.confetti(Effects.centerOf(stage), 6, { target.color, UI.WHITE }, 0.4)
		pause(0.45)
	end

	---------------------------------------------------------------
	-- 4. PANG! Ägget exploderar
	---------------------------------------------------------------
	wobble = 0.6
	pause(0.35)
	local center = Effects.centerOf(stage)
	local stageSize = stage.AbsoluteSize.X
	Effects.flash(UI.WHITE, 1, 0.7)
	Effects.shake(6 + targetTier * 3, 0.6 + targetTier * 0.1)
	for i = 0, 2 do
		task.delay(i * 0.12, function()
			Effects.ring(center, if i == 1 then UI.WHITE else target.color, stageSize * (1.6 + i * 0.4), 0.8)
		end)
	end
	local confettiColors = { target.color, UI.WHITE, GOLD }
	if isMythic or chicken.rainbow then
		confettiColors = {}
		for i = 0, 7 do
			table.insert(confettiColors, Color3.fromHSV(i / 8, 0.85, 1))
		end
	end
	Effects.confetti(center, 50 + targetTier * 25, confettiColors, 1 + targetTier * 0.15)
	if targetTier >= 4 then
		-- Extra konfetti-regn från skärmens kanter.
		local screen = gui.AbsoluteSize
		task.delay(0.3, function()
			Effects.confetti(Vector2.new(0, screen.Y * 0.6), 40, confettiColors, 1.2)
			Effects.confetti(Vector2.new(screen.X, screen.Y * 0.6), 40, confettiColors, 1.2)
		end)
	end

	if egg then
		egg:Destroy()
		egg = nil
	end
	cracks:ClearAllChildren()
	tween(blur, 0.4, { Size = 12 })
	colorCorrection.Brightness = 0.4
	tween(colorCorrection, 0.8, { Brightness = 0, Saturation = 0.2, TintColor = UI.WHITE })
	rayAlpha = 0.1
	raySpeed = 60

	---------------------------------------------------------------
	-- 5. Kycklingen visas
	---------------------------------------------------------------
	camera.CFrame = CFrame.lookAt(Vector3.new(3.5, 3.5, -8), Vector3.new(0, 2, 0))
	chickenModel = ChickenModel.build(chicken)
	chickenModel.Parent = viewport
	spin = math.pi * 4
	local scaleValue = UI.new("NumberValue", { Value = 0.1 })
	scaleValue.Changed:Connect(function(value)
		chickenScale = value
	end)
	tween(scaleValue, 0.7, { Value = 1 }, Enum.EasingStyle.Back)

	tierLabel.Text = chicken.name
	tierLabel.TextColor3 = target.color
	tierScale.Scale = 3
	tween(tierScale, 0.45, { Scale = 1 }, Enum.EasingStyle.Back)
	subLabel.Text = `{target.name} · {Chickens.formatOdds(chicken)} · värd {Chickens.formatNumber(
		Chickens.valueOf(chicken)
	)} mynt`
	subLabel.TextColor3 = target.color

	if isNew then
		local badge = UI.label({
			AnchorPoint = Vector2.new(0.5, 0.5),
			Position = UDim2.fromScale(0.85, 0.2),
			Size = UDim2.fromScale(0.3, 0.1),
			Rotation = -15,
			Text = "NY!",
			TextColor3 = GOLD,
			Parent = stage,
		})
		local badgeScale = UI.new("UIScale", { Scale = 0, Parent = badge })
		task.delay(0.4, function()
			tween(badgeScale, 0.5, { Scale = 1 }, Enum.EasingStyle.Elastic)
		end)
	end

	-- Små stjärnor som blinkar runt kycklingen.
	local twinkling = true
	task.spawn(function()
		while twinkling do
			local star = UI.label({
				AnchorPoint = Vector2.new(0.5, 0.5),
				Position = UDim2.fromScale(math.random(5, 95) / 100, math.random(10, 85) / 100),
				Size = UDim2.fromScale(0.07, 0.07),
				Text = "✦",
				TextColor3 = if isMythic then rainbow(os.clock()) else target.color:Lerp(UI.WHITE, 0.4),
				TextTransparency = 1,
				Parent = stage,
			})
			tween(star, 0.3, { TextTransparency = 0, Rotation = 90 })
			task.delay(0.5, function()
				tween(star, 0.4, { TextTransparency = 1, Rotation = 180 }).Completed:Connect(function()
					star:Destroy()
				end)
			end)
			task.wait(0.12 / math.max(1, targetTier - 1))
		end
	end)

	---------------------------------------------------------------
	-- 6. Vänta på klick, sen stäng
	---------------------------------------------------------------
	pause(1)
	local continueLabel = UI.label({
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.95),
		Size = UDim2.fromScale(0.5, 0.035),
		Text = "Klicka för att fortsätta",
		ZIndex = 21,
		Parent = gui,
	})
	tween(continueLabel, 0.6, { TextTransparency = 0.6 }, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut)

	local clicked = false
	local clickArea = UI.new("TextButton", {
		Size = UDim2.fromScale(1, 1),
		BackgroundTransparency = 1,
		Text = "",
		ZIndex = 30,
		Parent = gui,
	})
	clickArea.Activated:Connect(function()
		clicked = true
	end)
	local timeout = os.clock() + (if fast then 1 else 6)
	while not clicked and os.clock() < timeout do
		task.wait()
	end

	twinkling = false
	tween(topBar, 0.4, { Size = UDim2.fromScale(1, 0) })
	tween(bottomBar, 0.4, { Size = UDim2.fromScale(1, 0) })
	tween(darkness, 0.4, { BackgroundTransparency = 1 })
	tween(blur, 0.4, { Size = 0 })
	tween(colorCorrection, 0.4, { Saturation = 0, Contrast = 0, Brightness = 0, TintColor = UI.WHITE })
	tween(viewportScale, 0.3, { Scale = 0 }, Enum.EasingStyle.Back, Enum.EasingDirection.In)
	tween(stageScale, 0.4, { Scale = 0.6 })
	for _, label in { tierLabel, subLabel, continueLabel } do
		tween(label, 0.3, { TextTransparency = 1 })
		local stroke = label:FindFirstChildOfClass("UIStroke")
		if stroke then
			tween(stroke, 0.3, { Transparency = 1 })
		end
	end
	rayAlpha = 1
	task.wait(0.45)

	connection:Disconnect()
	Effects.removeShakeTarget(stage)
	gui:Destroy()
	scaleValue:Destroy()
	if hudHidden and Cutscene.onEnd then
		Cutscene.onEnd()
	end
end

-- Sätts av huvudskriptet för att gömma och visa resten av gränssnittet.
Cutscene.onStart = nil :: (() -> boolean)?
Cutscene.onEnd = nil :: (() -> ())?

return Cutscene
