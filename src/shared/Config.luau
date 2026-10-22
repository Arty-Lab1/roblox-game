-- Inställningar för spelet. Ändra siffrorna här för att balansera det.
return {
	START_COINS = 100, -- mynt man börjar med
	ROLL_COST = 10, -- vad en rullning kostar
	ROLL_COOLDOWN = 0.8, -- minsta tid mellan rullningar (sekunder)

	LUCK_EVERY = 10, -- var 10:e rullning är en tur-rullning
	LUCK_MULTIPLIER = 2,

	POTION_COST = 250, -- tur-dryck
	POTION_MULTIPLIER = 2,
	POTION_SECONDS = 60,

	ANNOUNCE_ODDS = 1000, -- alla på servern ser när någon får 1 på 1000 eller ovanligare

	-- Inställningar spelaren kan ändra i menyn, och vad de är från början.
	DEFAULT_SETTINGS = {
		cutsceneTier = 2, -- cutscene från den här nivån (2 = Ovanlig), 7 = aldrig
		shake = true,
		confetti = true,
		fastRoll = false,
		autoSell = false, -- sälj Vanliga kycklingar direkt
		showPets = true, -- visa andra spelares kycklingar
		hideBanner = false,
	},
}
