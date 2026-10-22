-- Kod som både servern och klienten kan använda.
local Hello = {}

function Hello.greet(from: string): string
	return `Hej från {from}! Rojo fungerar.`
end

return Hello
