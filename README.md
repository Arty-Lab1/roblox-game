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
3. Tryck Play. I Output ska det stå "Hej från servern! Rojo fungerar."

Ändringar i `src/` syns direkt i Studio. Gör ändringar i filerna här, inte i Studio, annars skrivs de över.

## Bygga en platsfil

`rojo build -o game.rbxl` skapar en fil du kan öppna i Studio.
