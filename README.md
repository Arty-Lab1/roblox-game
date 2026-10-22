# Roblox game

Spelets kod ligger här och synkas till Roblox Studio med [Rojo](https://rojo.space).

## Mappar

| Mapp | Hamnar i Studio | Vad det är |
|---|---|---|
| `src/server` | ServerScriptService › Server | Kod som bara körs på servern |
| `src/client` | StarterPlayer › StarterPlayerScripts › Client | Kod som körs hos varje spelare |
| `src/shared` | ReplicatedStorage › Shared | Moduler som båda sidor kan använda |

## Kom igång (en gång)

1. Installera [Rokit](https://github.com/rojo-rbx/rokit/releases) (verktygshanterare).
2. Öppna en terminal i den här mappen och kör `rokit install`. Då installeras Rojo med rätt version.
3. Installera Rojo-pluginet i Studio: kör `rojo plugin install`, eller hämta "Rojo" från Creator Store.

## Varje gång du jobbar

1. Kör `rojo serve` i den här mappen.
2. Öppna din plats i Roblox Studio, klicka på **Rojo** i Plugins-fliken och sen **Connect**.
3. Tryck Play. I Output ska det stå "Kyckling-RNG har startat! 🐔" och tärningen syns längst ner.

## Spelet: Kyckling-RNG

Tryck på tärningen för att rulla fram en kyckling. Varje kyckling har egna odds, från 1 på 2 till 1 på 1 000 000.

- Kycklingarna och deras odds finns i `src/shared/Chickens.luau`. Lägg till en rad där för en ny kyckling.
- Utseendet (hattar, kronor, glorior …) byggs i `src/shared/ChickenModel.luau`.
- Varje rullning kostar mynt. Kycklingarna hamnar i inventoryt, där man kan sälja dem eller utrusta en som följer efter en.
- Kycklingar som är 1 på 10 eller ovanligare får en cutscene (`src/client/Cutscene.luau`).
- Var 10:e rullning är en tur-rullning med dubbel chans, och en tur-dryck ger dubbel tur en stund.
- Ovanliga kycklingar (1 på 1000 eller mer) visas för alla på servern.
- Priser och odds-gränser ändrar du i `src/shared/Config.luau`.

Ändringar i `src/` syns direkt i Studio. Gör ändringar i filerna här, inte i Studio, annars skrivs de över.

## Bygga en platsfil

`rojo build -o game.rbxl` skapar en fil du kan öppna i Studio.
