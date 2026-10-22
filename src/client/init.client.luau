-- Körs hos varje spelare (klienten) när de går med.
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = require(ReplicatedStorage.Shared.Hello)

print(Shared.greet("klienten"))
