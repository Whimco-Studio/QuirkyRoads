--[[
CharacterManager

    A short description of the module.

SYNOPSIS

    -- Lua code that showcases an overview of the API.
    local foobar = CharacterManager.TopLevel('foo')
    print(foobar.Thing)

DESCRIPTION

    A detailed description of the module.

API

    -- Describes each API item using Luau type declarations.

    -- Top-level functions use the function declaration syntax.
    function ModuleName.TopLevel(thing: string): Foobar

    -- A description of Foobar.
    type Foobar = {

        -- A description of the Thing member.
        Thing: string,

        -- Each distinct item in the API is separated by \n\n.
        Member: string,

    }
]]

-- Implementation of CharacterManager.

--// Services
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")

--// Modules
local Animations = require(script.Parent.Animations)
local Knit = require(ReplicatedStorage.Packages.Knit)

--// KnitServices

--// Module
local CharacterManager = {}

--// Variables
local Spawns = workspace:FindFirstChild("Spawns") or warn("No 'Spawns' folder in workspace")
local PlayerStates = Knit.PlayerStates

-- local Animations = ReplicatedStorage.Animations

local AnimationPrefix = "rbxassetid://"

function CharacterManager.GetAnimations(Animal, QueriedAnimation: string): Animation | Folder
	local CurrentFolder = Animations[Animal]
	if QueriedAnimation then
		local Animation = CurrentFolder[QueriedAnimation]
		if not Animation then
			return warn(QueriedAnimation .. " animation does not exist")
		else
			return Animation:Clone()
		end
	else
		return CurrentFolder
	end
end

function CharacterManager.Spawn(Player: Player, Model: Model, StateMachine)
	local SpawnPointCFrames = StateMachine:Get("SpawnPointCFrames")

	if SpawnPointCFrames and #SpawnPointCFrames > 0 then
		Model:PivotTo(SpawnPointCFrames[math.random(1, #SpawnPointCFrames)] * CFrame.new(0, 5.5, 0))
		Model.Parent = workspace:WaitForChild("Players")
	else
		local Spawn: SpawnLocation = Spawns:GetChildren()[math.random(1, #Spawns:GetChildren())]
		Model:PivotTo(Spawn.CFrame * CFrame.new(0, 5.5, 0))
		Model.Parent = workspace:WaitForChild("Players")
	end
end

function CharacterManager.AddAnimations(Character: Model, Animal: string)
	local Animate: LocalScript = ServerStorage.Animate:Clone()
	local AnimationDictionary: Folder = Animations[Animal]

	local Anims = {}

	Animate.Parent = Character
	for _, Animation: string in pairs({ "Run", "Idle", "Jump", "Fall", "Death", "Bounce", "Spin", "Fear" }) do
		local CurrentAnimation: number = Animation ~= "Fall" and AnimationDictionary[Animation]
			or AnimationDictionary["Fly"]
		if Animation ~= "Idle" and Animation ~= "Death" then
			local Target = Animation

			if Target == "Bounce" then
				Target = "Dance"
			elseif Target == "Spin" then
				Target = "Dance2"
			elseif Target == "Fear" then
				Target = "Dance3"
			end

			for i, AnimationFile: Animation in pairs(Animate:FindFirstChild(string.lower(Target)):GetChildren()) do
				AnimationFile.AnimationId = AnimationPrefix .. CurrentAnimation
			end
		elseif Animation == "Idle" then
			Animate.idle.Animation1.AnimationId = AnimationPrefix .. AnimationDictionary[Animation]
			Animate.idle.Animation2.AnimationId = AnimationPrefix .. AnimationDictionary[Animation .. "2"]
		end
	end

	Animate.Enabled = true
end

function CharacterManager.Respawn(Player, Animal, StateMachine)
	local Character: Model = ServerStorage:FindFirstChild(Animal):Clone()

	local s, e = pcall(function()
		Player.Character = Character
	end)

	if not s then
		Character:Destroy()
		return
	end

	CharacterManager.Spawn(Player, Character, StateMachine)
end

function CharacterManager.Died(StateMachine, _Character: Model, Animal)
	local Player: Player = StateMachine:Get("Player")
	local Humanoid: Humanoid = _Character:WaitForChild("Humanoid")

	local Connection
	local Connection2

	Connection2 = _Character.ChildRemoved:Connect(function()
		if _Character.PrimaryPart == nil then
			CharacterManager.Respawn(Player, Animal, StateMachine)

			Connection:Disconnect()
			Connection2:Disconnect()
		end
	end)

	Connection = Humanoid.Died:Connect(function()
		task.delay(1.5, function()
			CharacterManager.Respawn(Player, Animal, StateMachine)

			Connection2:Disconnect()
			Connection:Disconnect()
		end)
	end)
end

return CharacterManager
