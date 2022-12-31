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

--// Module
local CharacterManager = {}

--// Variables
local Spawns = workspace.Spawns or warn("No 'Spawns' folder in workspace")
local Animations = ReplicatedStorage.Animations

function CharacterManager.GetAnimations(Animal, QueriedAnimation: string): Animation | Folder
	local CurrentFolder = Animations[Animal]
	if QueriedAnimation then
		local Animation = CurrentFolder:FindFirstChild(QueriedAnimation)
		if not Animation then
			return warn(QueriedAnimation .. " animation does not exist")
		else
			return Animation:Clone()
		end
	else
		return CurrentFolder
	end
end

function CharacterManager.Spawn(Model: Model)
	local Spawn: SpawnLocation = Spawns:GetChildren()[math.random(1, #Spawns:GetChildren())]
	Model:PivotTo(Spawn.CFrame * CFrame.new(0, 5.5, 0))
	Model.Parent = workspace:WaitForChild("Players")
end

function CharacterManager.AddAnimations(Character: Model, Animal: string)
	local Animate: LocalScript = ServerStorage.Animate:Clone()
	local AnimationFolder: Folder = Animations[Animal]

	local Anims = {}

	Animate.Parent = Character
	for _, Animation: string in pairs({ "Run", "Idle", "Jump", "Fall", "Death" }) do
		local CurrentAnimation: Animation = AnimationFolder:WaitForChild(Animation)
		if Animation ~= "Idle" and Animation ~= "Death" then
			Animate:FindFirstChild(string.lower(Animation))[Animation .. "Anim"].AnimationId =
				CurrentAnimation.AnimationId
		elseif CurrentAnimation == "Idle" then
			Animate.idle.Animation1.AnimationId = CurrentAnimation.AnimationId
			Animate.idle.Animation2.AnimationId = CurrentAnimation.AnimationId
		end
	end

	Animate.Enabled = true
end

function CharacterManager.Died(StateMachine, _Character: Model, Animal)
	local Player: Player = StateMachine:Get("Player")
	local Humanoid: Humanoid = _Character:WaitForChild("Humanoid")

	local Connection

	Connection = Humanoid.Died:Connect(function()
		-- _Character.PrimaryPart.Anchored = true

		task.delay(3, function()
			local Character: Model = ServerStorage:FindFirstChild(Animal):Clone()

			local s, e = pcall(function()
				Player.Character = Character
			end)

			if not s then
				Character:Destroy()
				Connection:Disconnect()

				return
			end

			CharacterManager.Spawn(Character)
			Connection:Disconnect()
		end)
	end)
end

return CharacterManager
