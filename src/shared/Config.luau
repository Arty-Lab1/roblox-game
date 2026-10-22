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

	CUTSCENE_ODDS = 10, -- cutscene för 1 på 10 eller ovanligare
	ANNOUNCE_ODDS = 1000, -- alla på servern ser när någon får 1 på 1000 eller ovanligare
}
