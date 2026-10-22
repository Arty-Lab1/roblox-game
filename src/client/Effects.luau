-- Effekter: konfetti, skakningar, blixtar, ringar och flytande text.
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")

local UI = require(script.Parent.UI)

local Effects = {}

local layer: ScreenGui -- konfetti och text hamnar här, ovanför allt annat

function Effects.init(screen: ScreenGui)
	layer = screen
end

---------------------------------------------------------------------
-- Konfetti
---------------------------------------------------------------------

type Particle = {
	frame: Frame,
	position: Vector2,
	velocity: Vector2,
	spin: number,
	life: number,
	maxLife: number,
}
local particles: { Particle } = {}

-- Skjuter ut konfetti från en punkt på skärmen (i pixlar).
function Effects.confetti(origin: Vector2, count: number, colors: { Color3 }, power: number?)
	local strength = power or 1
	for _ = 1, count do
		local angle = math.random() * math.pi * 2
		local speed = (300 + math.random() * 700) * strength
		local size = math.random(8, 16)
		local isStar = math.random() < 0.3
		local frame = UI.new("Frame", {
			AnchorPoint = Vector2.new(0.5, 0.5),
			Size = UDim2.fromOffset(size, if isStar then size else size * 0.5),
			BackgroundColor3 = colors[math.random(1, #colors)],
			BorderSizePixel = 0,
			Rotation = math.random(0, 360),
			ZIndex = 50,
			Parent = layer,
		}, if isStar then { UI.corner(100) } else nil)
		local maxLife = 1.5 + math.random() * 1.5
		table.insert(particles, {
			frame = frame,
			position = origin,
			velocity = Vector2.new(math.cos(angle), math.sin(angle) - 0.6) * speed,
			spin = math.random(-720, 720),
			life = maxLife,
			maxLife = maxLife,
		})
	end
end

RunService.RenderStepped:Connect(function(dt)
	for i = #particles, 1, -1 do
		local p = particles[i]
		p.life -= dt
		if p.life <= 0 then
			p.frame:Destroy()
			table.remove(particles, i)
		else
			p.velocity = Vector2.new(p.velocity.X * (1 - dt * 1.5), p.velocity.Y + 900 * dt)
			p.position += p.velocity * dt
			p.frame.Position = UDim2.fromOffset(p.position.X, p.position.Y)
			p.frame.Rotation += p.spin * dt
			p.frame.BackgroundTransparency = math.clamp(1 - p.life / p.maxLife * 2, 0, 1)
		end
	end
end)

---------------------------------------------------------------------
-- Skakning (både kameran och utvalda gränssnitt)
---------------------------------------------------------------------

local shakePower = 0
local shakeUntil = 0
local shakeTargets: { [GuiObject]: UDim2 } = {}

function Effects.shake(power: number, duration: number)
	shakePower = math.max(shakePower, power)
	shakeUntil = math.max(shakeUntil, os.clock() + duration)
end

-- Gör så att ett gränssnitt också skakar när skärmen skakar.
function Effects.addShakeTarget(frame: GuiObject)
	shakeTargets[frame] = frame.Position
end

function Effects.removeShakeTarget(frame: GuiObject)
	local base = shakeTargets[frame]
	if base then
		frame.Position = base
		shakeTargets[frame] = nil
	end
end

RunService:BindToRenderStep("KycklingShake", Enum.RenderPriority.Camera.Value + 1, function()
	local now = os.clock()
	if now > shakeUntil then
		shakePower = 0
		for frame, base in shakeTargets do
			frame.Position = base
		end
		return
	end
	local power = shakePower * math.clamp((shakeUntil - now) * 3, 0, 1)
	local dx = (math.random() - 0.5) * 2 * power
	local dy = (math.random() - 0.5) * 2 * power
	local camera = workspace.CurrentCamera
	camera.CFrame *= CFrame.Angles(math.rad(dy * 0.15), math.rad(dx * 0.15), 0)
	for frame, base in shakeTargets do
		frame.Position = base + UDim2.fromOffset(dx, dy)
	end
end)

---------------------------------------------------------------------
-- Blixtar, ringar och text
---------------------------------------------------------------------

function Effects.flash(color: Color3, strength: number, duration: number)
	local frame = UI.new("Frame", {
		Size = UDim2.fromScale(1, 1),
		BackgroundColor3 = color,
		BackgroundTransparency = 1 - strength,
		BorderSizePixel = 0,
		ZIndex = 60,
		Parent = layer,
	})
	local tween = TweenService:Create(frame, TweenInfo.new(duration), { BackgroundTransparency = 1 })
	tween.Completed:Connect(function()
		frame:Destroy()
	end)
	tween:Play()
end

-- En ring som växer ut från en punkt och tonar bort.
function Effects.ring(origin: Vector2, color: Color3, size: number, duration: number)
	local ring = UI.new("Frame", {
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromOffset(origin.X, origin.Y),
		Size = UDim2.fromOffset(20, 20),
		BackgroundTransparency = 1,
		ZIndex = 45,
		Parent = layer,
	}, { UI.corner(1000) })
	local stroke = UI.stroke(10, color)
	stroke.Parent = ring
	local info = TweenInfo.new(duration, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
	TweenService:Create(ring, info, { Size = UDim2.fromOffset(size, size) }):Play()
	local fade = TweenService:Create(stroke, info, { Transparency = 1, Thickness = 1 })
	fade.Completed:Connect(function()
		ring:Destroy()
	end)
	fade:Play()
end

-- Text som flyger upp och försvinner, t.ex. "+20 mynt".
function Effects.popup(text: string, color: Color3, origin: Vector2)
	local popup = UI.label({
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromOffset(origin.X, origin.Y),
		Size = UDim2.fromOffset(220, 40),
		Text = text,
		TextColor3 = color,
		ZIndex = 55,
		Parent = layer,
	})
	local stroke = popup:FindFirstChildOfClass("UIStroke") :: UIStroke
	local info = TweenInfo.new(1.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
	TweenService:Create(popup, info, {
		Position = UDim2.fromOffset(origin.X + math.random(-30, 30), origin.Y - 90),
		TextTransparency = 1,
	}):Play()
	local fade = TweenService:Create(stroke, info, { Transparency = 1 })
	fade.Completed:Connect(function()
		popup:Destroy()
	end)
	fade:Play()
end

-- Mitten av ett gränssnitt i pixlar på skärmen.
function Effects.centerOf(frame: GuiObject): Vector2
	return frame.AbsolutePosition + frame.AbsoluteSize / 2
end

return Effects
