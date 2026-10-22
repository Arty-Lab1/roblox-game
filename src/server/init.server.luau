-- Körs på servern när spelet startar.
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = require(ReplicatedStorage.Shared.Hello)

print(Shared.greet("servern"))
