-- Alla kycklingar i spelet: namn, odds och utseende.
-- Lägg till en ny kyckling genom att lägga till en rad i listan nedan.
local Chickens = {}

export type Chicken = {
	id: string,
	name: string,
	odds: number, -- "1 på odds"
	body: Color3,
	head: Color3?,
	comb: Color3?,
	beak: Color3?,
	eyes: Color3?,
	material: Enum.Material?,
	scale: number?,
	rainbow: boolean?,
	accessories: { string }?,
}

local rgb = Color3.fromRGB

-- Sorterad från vanligast till ovanligast.
Chickens.list = {
	{ id = "vanlig", name = "Vanlig Kyckling", odds = 2, body = rgb(245, 245, 240) },
	{ id = "brun", name = "Brun Höna", odds = 4, body = rgb(140, 90, 50) },
	{ id = "svart", name = "Svart Höna", odds = 8, body = rgb(40, 40, 45), comb = rgb(200, 30, 30) },
	{ id = "unge", name = "Kycklingunge", odds = 10, body = rgb(255, 225, 60), comb = rgb(255, 200, 40), scale = 0.7 },
	{ id = "rosa", name = "Rosa Kyckling", odds = 25, body = rgb(255, 150, 200) },
	{ id = "bonde", name = "Bondkyckling", odds = 50, body = rgb(230, 200, 160), accessories = { "strawhat" } },
	{ id = "nord", name = "Nörd-kyckling", odds = 100, body = rgb(200, 230, 255), accessories = { "glasses" } },
	{
		id = "ninja",
		name = "Ninja-kyckling",
		odds = 250,
		body = rgb(25, 25, 30),
		eyes = rgb(255, 255, 255),
		accessories = { "headband" },
	},
	{
		id = "is",
		name = "Is-kyckling",
		odds = 500,
		body = rgb(160, 220, 255),
		comb = rgb(80, 160, 255),
		material = Enum.Material.Ice,
	},
	{
		id = "guld",
		name = "Guld-kyckling",
		odds = 1000,
		body = rgb(255, 200, 40),
		comb = rgb(255, 120, 0),
		material = Enum.Material.Foil,
	},
	{
		id = "pirat",
		name = "Pirat-kyckling",
		odds = 2500,
		body = rgb(120, 70, 40),
		accessories = { "tophat", "eyepatch" },
	},
	{
		id = "lava",
		name = "Lava-kyckling",
		odds = 5000,
		body = rgb(255, 90, 0),
		head = rgb(255, 160, 0),
		comb = rgb(255, 230, 0),
		material = Enum.Material.Neon,
	},
	{ id = "kung", name = "Kung-kyckling", odds = 10000, body = rgb(140, 40, 180), accessories = { "crown" } },
	{
		id = "rymd",
		name = "Rymd-kyckling",
		odds = 25000,
		body = rgb(230, 230, 240),
		material = Enum.Material.SmoothPlastic,
		accessories = { "helmet" },
	},
	{ id = "regnbage", name = "Regnbågskyckling", odds = 50000, body = rgb(255, 0, 0), rainbow = true },
	{
		id = "angel",
		name = "Ängel-kyckling",
		odds = 100000,
		body = rgb(255, 255, 240),
		comb = rgb(255, 220, 120),
		material = Enum.Material.Neon,
		accessories = { "halo", "bigwings" },
	},
	{
		id = "demon",
		name = "Demon-kyckling",
		odds = 250000,
		body = rgb(120, 0, 0),
		head = rgb(60, 0, 0),
		eyes = rgb(255, 230, 0),
		comb = rgb(20, 20, 20),
		accessories = { "horns" },
	},
	{
		id = "galax",
		name = "Galax-kyckling",
		odds = 1000000,
		body = rgb(60, 20, 140),
		head = rgb(20, 10, 60),
		eyes = rgb(255, 255, 255),
		comb = rgb(0, 255, 255),
		material = Enum.Material.Neon,
		rainbow = true,
		accessories = { "crown", "halo", "stars" },
	},
} :: { Chicken }

Chickens.byId = {} :: { [string]: Chicken }
for _, chicken in Chickens.list do
	Chickens.byId[chicken.id] = chicken
end

-- Sällsynthetsnivåer. En kyckling får den högsta nivån vars minOdds den når.
Chickens.rarities = {
	{ name = "Vanlig", minOdds = 1, color = rgb(200, 200, 200) },
	{ name = "Ovanlig", minOdds = 10, color = rgb(90, 220, 90) },
	{ name = "Sällsynt", minOdds = 100, color = rgb(70, 150, 255) },
	{ name = "Episk", minOdds = 1000, color = rgb(190, 90, 255) },
	{ name = "Legendarisk", minOdds = 10000, color = rgb(255, 200, 40) },
	{ name = "Mytisk", minOdds = 100000, color = rgb(255, 60, 90) },
}

function Chickens.rarityOf(chicken: Chicken)
	local result = Chickens.rarities[1]
	for _, rarity in Chickens.rarities do
		if chicken.odds >= rarity.minOdds then
			result = rarity
		end
	end
	return result
end

-- Slumpar en kyckling. Vi börjar med den ovanligaste och går nedåt.
-- luck = 2 betyder dubbelt så stor chans på varje kyckling.
function Chickens.roll(luck: number, rng: Random): Chicken
	for i = #Chickens.list, 2, -1 do
		local chicken = Chickens.list[i]
		if rng:NextNumber() < luck / chicken.odds then
			return chicken
		end
	end
	return Chickens.list[1]
end

-- 1000000 -> "1 000 000"
function Chickens.formatNumber(n: number): string
	local spaced = tostring(math.floor(n)):reverse():gsub("(%d%d%d)", "%1 "):reverse()
	return (spaced:gsub("^ ", ""))
end

function Chickens.formatOdds(chicken: Chicken): string
	return "1 på " .. Chickens.formatNumber(chicken.odds)
end

return Chickens
