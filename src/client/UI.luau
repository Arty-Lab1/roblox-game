-- Små hjälpfunktioner för att bygga gränssnitt i kod.
local UI = {}

UI.FONT = Enum.Font.FredokaOne
UI.WHITE = Color3.new(1, 1, 1)
UI.BLACK = Color3.new(0, 0, 0)
UI.DARK = Color3.fromRGB(30, 30, 45)

function UI.new(className: string, props: { [string]: any }, children: { Instance }?): any
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

function UI.corner(radius: number): UICorner
	return UI.new("UICorner", { CornerRadius = UDim.new(0, radius) })
end

-- På en Frame blir det en kant, på text blir det en kontur runt bokstäverna.
function UI.stroke(thickness: number, color: Color3?, mode: Enum.ApplyStrokeMode?): UIStroke
	return UI.new("UIStroke", {
		Thickness = thickness,
		Color = color or UI.BLACK,
		ApplyStrokeMode = mode or Enum.ApplyStrokeMode.Contextual,
	})
end

function UI.label(props: { [string]: any }): TextLabel
	props.BackgroundTransparency = props.BackgroundTransparency or 1
	props.Font = props.Font or UI.FONT
	props.TextColor3 = props.TextColor3 or UI.WHITE
	props.TextScaled = true
	return UI.new("TextLabel", props, { UI.stroke(2) })
end

function UI.button(props: { [string]: any }): TextButton
	props.Font = props.Font or UI.FONT
	props.TextColor3 = props.TextColor3 or UI.WHITE
	props.TextScaled = true
	props.AutoButtonColor = true
	return UI.new("TextButton", props, {
		UI.corner(12),
		UI.stroke(3, UI.BLACK, Enum.ApplyStrokeMode.Border),
		UI.stroke(2),
		UI.new("UIPadding", {
			PaddingTop = UDim.new(0.18, 0),
			PaddingBottom = UDim.new(0.18, 0),
			PaddingLeft = UDim.new(0, 6),
			PaddingRight = UDim.new(0, 6),
		}),
	})
end

-- En ViewportFrame med kamera riktad mot en kyckling.
function UI.viewport(props: { [string]: any }): (ViewportFrame, Camera)
	props.Ambient = props.Ambient or Color3.fromRGB(170, 170, 170)
	props.LightColor = UI.WHITE
	props.LightDirection = Vector3.new(-1, -1, 1)
	local viewport = UI.new("ViewportFrame", props)
	local camera = UI.new("Camera", {
		FieldOfView = 40,
		CFrame = CFrame.lookAt(Vector3.new(3.5, 3.5, -8), Vector3.new(0, 2, 0)),
		Parent = viewport,
	})
	viewport.CurrentCamera = camera
	return viewport, camera
end

return UI
