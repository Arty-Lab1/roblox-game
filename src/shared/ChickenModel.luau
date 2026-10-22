-- Bygger en 3D-kyckling av vanliga delar, utifrån en kyckling i Chickens.list.
-- Kycklingen står på punkten (0, 0, 0) och tittar mot -Z.
local Chickens = require(script.Parent.Chickens)

local ChickenModel = {}

local ORANGE = Color3.fromRGB(255, 150, 30)
local RED = Color3.fromRGB(220, 30, 30)
local BLACK = Color3.fromRGB(20, 20, 20)
local GOLD = Color3.fromRGB(255, 200, 40)

local function block(model: Model, size: Vector3, cframe: CFrame, color: Color3, material: Enum.Material?): Part
	local part = Instance.new("Part")
	part.Anchored = true
	part.CanCollide = false
	part.CastShadow = false
	part.TopSurface = Enum.SurfaceType.Smooth
	part.BottomSurface = Enum.SurfaceType.Smooth
	part.Size = size
	part.CFrame = cframe
	part.Color = color
	part.Material = material or Enum.Material.SmoothPlastic
	part.Parent = model
	return part
end

-- En "boll" som kan vara avlång (en vanlig Ball-del kan bara vara rund).
local function sphere(model: Model, size: Vector3, cframe: CFrame, color: Color3, material: Enum.Material?): Part
	local part = block(model, size, cframe, color, material)
	local mesh = Instance.new("SpecialMesh")
	mesh.MeshType = Enum.MeshType.Sphere
	mesh.Parent = part
	return part
end

-- En cylinder som står upp (Roblox-cylindrar ligger längs X annars).
local function cylinder(
	model: Model,
	height: number,
	width: number,
	cframe: CFrame,
	color: Color3,
	material: Enum.Material?
): Part
	local part =
		block(model, Vector3.new(height, width, width), cframe * CFrame.Angles(0, 0, math.rad(90)), color, material)
	part.Shape = Enum.PartType.Cylinder
	return part
end

local accessories = {}

function accessories.strawhat(model: Model)
	local tan = Color3.fromRGB(230, 190, 100)
	cylinder(model, 0.1, 2.2, CFrame.new(0, 3.6, -0.9), tan, Enum.Material.Fabric)
	cylinder(model, 0.5, 1.1, CFrame.new(0, 3.85, -0.9), tan, Enum.Material.Fabric)
	cylinder(model, 0.15, 1.15, CFrame.new(0, 3.7, -0.9), RED)
end

function accessories.tophat(model: Model)
	cylinder(model, 0.1, 1.6, CFrame.new(0, 3.6, -0.9), BLACK)
	cylinder(model, 0.9, 0.95, CFrame.new(0, 4.1, -0.9), BLACK)
	cylinder(model, 0.15, 1, CFrame.new(0, 3.75, -0.9), Color3.fromRGB(200, 170, 60))
end

function accessories.glasses(model: Model)
	for _, x in { -0.42, 0.42 } do
		local lens = block(
			model,
			Vector3.new(0.05, 0.5, 0.5),
			CFrame.new(x, 3.05, -1.6) * CFrame.Angles(0, math.rad(90), 0),
			BLACK,
			Enum.Material.Glass
		)
		lens.Shape = Enum.PartType.Cylinder
		lens.Transparency = 0.3
	end
	block(model, Vector3.new(0.35, 0.06, 0.06), CFrame.new(0, 3.1, -1.62), BLACK)
end

function accessories.headband(model: Model)
	cylinder(model, 0.3, 1.45, CFrame.new(0, 3.2, -0.9), RED)
	block(model, Vector3.new(0.12, 0.25, 0.7), CFrame.new(0.15, 3.1, -0.05) * CFrame.Angles(math.rad(-30), 0, 0), RED)
	block(model, Vector3.new(0.12, 0.25, 0.7), CFrame.new(-0.15, 3.0, -0.05) * CFrame.Angles(math.rad(-50), 0, 0), RED)
end

function accessories.eyepatch(model: Model)
	local patch = block(
		model,
		Vector3.new(0.06, 0.38, 0.38),
		CFrame.new(-0.45, 3.05, -1.57) * CFrame.Angles(0, math.rad(90), 0),
		BLACK
	)
	patch.Shape = Enum.PartType.Cylinder
	block(model, Vector3.new(1.5, 0.07, 0.07), CFrame.new(0, 3.2, -1.45) * CFrame.Angles(0, 0, math.rad(-20)), BLACK)
end

function accessories.crown(model: Model)
	cylinder(model, 0.35, 1, CFrame.new(0, 3.75, -0.9), GOLD, Enum.Material.Foil)
	for i = 0, 4 do
		local angle = i / 5 * math.pi * 2
		local offset = Vector3.new(math.cos(angle) * 0.42, 0, math.sin(angle) * 0.42)
		block(
			model,
			Vector3.new(0.15, 0.35, 0.15),
			CFrame.new(Vector3.new(0, 4.05, -0.9) + offset),
			GOLD,
			Enum.Material.Foil
		)
	end
	sphere(model, Vector3.new(0.2, 0.2, 0.2), CFrame.new(0, 3.8, -1.42), RED, Enum.Material.Neon)
end

function accessories.helmet(model: Model)
	local glass =
		sphere(model, Vector3.new(2, 2, 2), CFrame.new(0, 3, -0.95), Color3.fromRGB(170, 220, 255), Enum.Material.Glass)
	glass.Transparency = 0.65
	cylinder(model, 0.25, 1.7, CFrame.new(0, 2.15, -0.9), Color3.fromRGB(180, 180, 190), Enum.Material.Metal)
end

function accessories.halo(model: Model)
	for i = 0, 11 do
		local angle = i / 12 * math.pi * 2
		local offset = Vector3.new(math.cos(angle) * 0.6, 0, math.sin(angle) * 0.6)
		sphere(
			model,
			Vector3.new(0.22, 0.22, 0.22),
			CFrame.new(Vector3.new(0, 4.4, -0.9) + offset),
			GOLD,
			Enum.Material.Neon
		)
	end
end

function accessories.bigwings(model: Model)
	for _, side in { -1, 1 } do
		sphere(
			model,
			Vector3.new(0.25, 2.4, 1.3),
			CFrame.new(side * 1.5, 2.6, 0.7) * CFrame.Angles(0, 0, math.rad(-side * 35)),
			Color3.fromRGB(255, 255, 255),
			Enum.Material.Neon
		)
	end
end

function accessories.horns(model: Model)
	for _, side in { -1, 1 } do
		sphere(
			model,
			Vector3.new(0.25, 0.8, 0.25),
			CFrame.new(side * 0.45, 3.75, -0.8) * CFrame.Angles(0, 0, math.rad(-side * 25)),
			BLACK
		)
	end
end

function accessories.stars(model: Model)
	local rng = Random.new(42)
	for _ = 1, 10 do
		local position = Vector3.new(rng:NextNumber(-2.2, 2.2), rng:NextNumber(0.5, 4.5), rng:NextNumber(-1.5, 1.5))
		sphere(
			model,
			Vector3.new(0.15, 0.15, 0.15),
			CFrame.new(position),
			Color3.fromRGB(255, 255, 255),
			Enum.Material.Neon
		)
	end
end

function ChickenModel.build(chicken: Chickens.Chicken): Model
	local model = Instance.new("Model")
	model.Name = chicken.name

	local material = chicken.material
	local headColor = chicken.head or chicken.body
	local combColor = chicken.comb or RED
	local beakColor = chicken.beak or ORANGE
	local eyeColor = chicken.eyes or BLACK

	-- Delar som byter färg på regnbågskycklingar får en markering.
	local function colored(part: Part)
		if chicken.rainbow then
			part:SetAttribute("Rainbow", true)
		end
		return part
	end

	local body = colored(sphere(model, Vector3.new(2.2, 2, 2.6), CFrame.new(0, 1.5, 0), chicken.body, material))
	model.PrimaryPart = body
	colored(sphere(model, Vector3.new(1.4, 1.4, 1.4), CFrame.new(0, 2.9, -0.9), headColor, material))

	-- Vingar och stjärt
	for _, side in { -1, 1 } do
		colored(
			sphere(
				model,
				Vector3.new(0.4, 1.2, 1.6),
				CFrame.new(side * 1.1, 1.6, 0.1) * CFrame.Angles(0, 0, math.rad(side * 10)),
				chicken.body,
				material
			)
		)
	end
	colored(
		sphere(
			model,
			Vector3.new(0.6, 1.3, 0.8),
			CFrame.new(0, 2.2, 1.3) * CFrame.Angles(math.rad(-30), 0, 0),
			chicken.body,
			material
		)
	)

	-- Kam, näbb och slör
	for i, z in { -1.25, -0.9, -0.55 } do
		local height = i == 2 and 0.6 or 0.45
		sphere(model, Vector3.new(0.3, height, 0.35), CFrame.new(0, 3.55 + height / 4, z), combColor, material)
	end
	sphere(model, Vector3.new(0.35, 0.3, 0.6), CFrame.new(0, 2.8, -1.65), beakColor)
	sphere(model, Vector3.new(0.2, 0.35, 0.2), CFrame.new(0, 2.5, -1.5), combColor)

	-- Ögon
	for _, side in { -1, 1 } do
		sphere(
			model,
			Vector3.new(0.22, 0.22, 0.22),
			CFrame.new(side * 0.42, 3.05, -1.48),
			eyeColor,
			Enum.Material.SmoothPlastic
		)
	end

	-- Ben och fötter
	for _, side in { -1, 1 } do
		block(model, Vector3.new(0.15, 0.8, 0.15), CFrame.new(side * 0.45, 0.4, 0), ORANGE)
		block(model, Vector3.new(0.5, 0.1, 0.6), CFrame.new(side * 0.45, 0.05, -0.15), ORANGE)
	end

	for _, name in chicken.accessories or {} do
		accessories[name](model)
	end

	model.WorldPivot = CFrame.new()
	if chicken.scale then
		model:ScaleTo(chicken.scale)
	end
	return model
end

return ChickenModel
