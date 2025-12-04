local run = function(func) func() end
local cloneref = cloneref or function(obj) return obj end

local playersService = cloneref(game:GetService('Players'))
local replicatedStorage = cloneref(game:GetService('ReplicatedStorage'))
local inputService = cloneref(game:GetService('UserInputService'))

local lplr = playersService.LocalPlayer
local vape = shared.vape
local entitylib = vape.Libraries.entity
local sessioninfo = vape.Libraries.sessioninfo
local bedwars = {}

local function notif(...)
	return vape:CreateNotification(...)
end

run(function()
	local function dumpRemote(tab)
		local ind = table.find(tab, 'Client')
		return ind and tab[ind + 1] or ''
	end

	local KnitInit, Knit
	repeat
		KnitInit, Knit = pcall(function() return debug.getupvalue(require(lplr.PlayerScripts.TS.knit).setup, 9) end)
		if KnitInit then break end
		task.wait()
	until KnitInit
	if not debug.getupvalue(Knit.Start, 1) then
		repeat task.wait() until debug.getupvalue(Knit.Start, 1)
	end
	local Flamework = require(replicatedStorage['rbxts_include']['node_modules']['@flamework'].core.out).Flamework
	local Client = require(replicatedStorage.TS.remotes).default.Client

	bedwars = setmetatable({
		Client = Client,
		CrateItemMeta = debug.getupvalue(Flamework.resolveDependency('client/controllers/global/reward-crate/crate-controller@CrateController').onStart, 3),
		Store = require(lplr.PlayerScripts.TS.ui.store).ClientStore
	}, {
		__index = function(self, ind)
			rawset(self, ind, Knit.Controllers[ind])
			return rawget(self, ind)
		end
	})

	local kills = sessioninfo:AddItem('Kills')
	local beds = sessioninfo:AddItem('Beds')
	local wins = sessioninfo:AddItem('Wins')
	local games = sessioninfo:AddItem('Games')

	vape:Clean(function()
		table.clear(bedwars)
	end)
end)

for _, v in vape.Modules do
	if v.Category == 'Combat' or v.Category == 'Minigames' then
		vape:Remove(v)
	end
end

run(function()
	local Sprint
	local old
	
	Sprint = vape.Categories.Combat:CreateModule({
		Name = 'Sprint',
		Function = function(callback)
			if callback then
				if inputService.TouchEnabled then pcall(function() lplr.PlayerGui.MobileUI['2'].Visible = false end) end
				old = bedwars.SprintController.stopSprinting
				bedwars.SprintController.stopSprinting = function(...)
					local call = old(...)
					bedwars.SprintController:startSprinting()
					return call
				end
				Sprint:Clean(entitylib.Events.LocalAdded:Connect(function() bedwars.SprintController:stopSprinting() end))
				bedwars.SprintController:stopSprinting()
			else
				if inputService.TouchEnabled then pcall(function() lplr.PlayerGui.MobileUI['2'].Visible = true end) end
				bedwars.SprintController.stopSprinting = old
				bedwars.SprintController:stopSprinting()
			end
		end,
		Tooltip = 'Sets your sprinting to true.'
	})
end)
	
run(function()
	local AutoGamble
	
	AutoGamble = vape.Categories.Minigames:CreateModule({
		Name = 'AutoGamble',
		Function = function(callback)
			if callback then
				AutoGamble:Clean(bedwars.Client:GetNamespace('RewardCrate'):Get('CrateOpened'):Connect(function(data)
					if data.openingPlayer == lplr then
						local tab = bedwars.CrateItemMeta[data.reward.itemType] or {displayName = data.reward.itemType or 'unknown'}
						notif('AutoGamble', 'Won '..tab.displayName, 5)
					end
				end))
	
				repeat
					if not bedwars.CrateAltarController.activeCrates[1] then
						for _, v in bedwars.Store:getState().Consumable.inventory do
							if v.consumable:find('crate') then
								bedwars.CrateAltarController:pickCrate(v.consumable, 1)
								task.wait(1.2)
								if bedwars.CrateAltarController.activeCrates[1] and bedwars.CrateAltarController.activeCrates[1][2] then
									bedwars.Client:GetNamespace('RewardCrate'):Get('OpenRewardCrate'):SendToServer({
										crateId = bedwars.CrateAltarController.activeCrates[1][2].attributes.crateId
									})
								end
								break
							end
						end
					end
					task.wait(1)
				until not AutoGamble.Enabled
			end
		end,
		Tooltip = 'Automatically opens lucky crates, piston inspired!'
	})
end)

run(function()
	local OtterAura
	local Targets
	local CPS
	local SwingRange
	local AttackRange
	local AngleSlider
	local Max
	local Mouse
	local Lunge
	local BoxSwingColor
	local BoxAttackColor
	local ParticleTexture
	local ParticleColor1
	local ParticleColor2
	local ParticleSize
	local Face
	local SmartTarget
	local SmoothRotation
	local Overlay = OverlapParams.new()
	Overlay.FilterType = Enum.RaycastFilterType.Include
	Overlay.IgnoreWater = true
	local Particles, Boxes, AttackDelay = {}, {}, tick()
	local lastRotation, rotationAlpha = CFrame.new(), 0
	
	local function getAttackData()
		if Mouse.Enabled then
			if not inputService:IsMouseButtonPressed(0) then return false end
		end

		local tool = lplr.Character:FindFirstChildOfClass('Tool')
		return tool and tool:FindFirstChildWhichIsA('TouchTransmitter', true) or nil, tool
	end
	
	OtterAura = vape.Categories.Blatant:CreateModule({
		Name = 'OtterAura',
		Function = function(callback)
			if callback then
				repeat
					local interest, tool = getAttackData()
					local attacked = {}
					if interest then
						local plrs = entitylib.AllPosition({
							Range = SwingRange.Value,
							Wallcheck = Targets.Walls.Enabled or nil,
							Part = 'RootPart',
							Players = Targets.Players.Enabled,
							NPCs = Targets.NPCs.Enabled,
							Limit = Max.Value * 2
						})

						if #plrs > 0 then
							for _, plr in plrs do
								if not attacked[plr.Player] and plr.Distance <= AttackRange.Value then
									local canAttack = true
									if Lunge.Enabled and tool and tool.Parent then
										local hrp = plr.Character.HumanoidRootPart
										local mag = (hrp.Position - tool.Parent.PrimaryPart.Position).Magnitude
										if mag > 6.5 then canAttack = false end
									end
									if canAttack then
										local look = (plr.Character.HumanoidRootPart.Position - workspace.CurrentCamera.CFrame.Position).unit
										local ray = workspace:Raycast(workspace.CurrentCamera.CFrame.Position, look * AttackRange.Value, raycastparams)
										if not ray or (ray.Instance:IsDescendantOf(plr.Character) and ray.Position:Distance(plr.Character.HumanoidRootPart.Position) < 4) then
											if AngleSlider.Enabled then
												local orgcf = workspace.CurrentCamera.CFrame
												local cf = CFrame.lookAt(orgcf.Position, plr.Character.HumanoidRootPart.Position)
												local targetcf = AngleSlider.Value == 0 and cf or orgcf:Lerp(cf, 1 - math.clamp((1 - AngleSlider.Value / 180) * (plr.Distance / AttackRange.Value), 0, 1))
												if SmoothRotation.Enabled then
													local alpha = math.clamp((tick() - lastRotation) / 0.15, 0, 1)
													lastRotation = lastRotation:Lerp(targetcf, alpha)
													workspace.CurrentCamera.CFrame = lastRotation
												else
													workspace.CurrentCamera.CFrame = targetcf
												end
											end
											attacked[plr.Player] = true
											task.wait()
											interest:FireServer({})
										end
									end
								end
							end
						end
					end
					task.wait(1 / CPS.Value[2])
				until not OtterAura.Enabled
			end
		end,
		Tooltip = 'Enhanced otter-powered combat system!\nAttacks players with intelligent targeting,\nsmooth rotations, and optimized performance.'
	})
	
	Targets = OtterAura:CreateTargets({Players = true, NPCs = false, Walls = false})
	CPS = OtterAura:CreateTwoSlider({
		Name = 'CPS',
		Text = {'Min CPS', 'Max CPS'},
		Function = function(val) end,
		Default = {12, 16},
		Min = {1, 1},
		Max = {20, 20}
	})
	SwingRange = OtterAura:CreateSlider({
		Name = 'Swing Range',
		Function = function(val) end,
		Default = 4.5,
		Min = 1,
		Max = 7,
		Decimal = 0.1
	})
	AttackRange = OtterAura:CreateSlider({
		Name = 'Attack Range',
		Function = function(val) end,
		Default = 3.5,
		Min = 1,
		Max = 35,
		Decimal = 0.1
	})
	AngleSlider = OtterAura:CreateSlider({
		Name = 'Max Angle',
		Function = function(val) end,
		Default = 180,
		Min = 0,
		Max = 180,
		Decimal = 1
	})
	Max = OtterAura:CreateSlider({
		Name = 'Max Targets',
		Function = function(val) end,
		Default = 1,
		Min = 1,
		Max = 3,
		Decimal = 0
	})
	Mouse = OtterAura:CreateToggle({Name = 'Require mouse down'})
	Lunge = OtterAura:CreateToggle({Name = 'Sword lunge only'})
	SmartTarget = OtterAura:CreateToggle({
		Name = 'Smart Target',
		Default = true
	})
	SmoothRotation = OtterAura:CreateToggle({
		Name = 'Smooth Rotation',
		Default = true
	})
	OtterAura:CreateToggle({
		Name = 'Visuals',
		Default = true,
		Function = function(callback)
			if callback then
				OtterAura:Clean(entitylib.Events.EntityAdded:Connect(function(plr)
					local box = Instance.new('BoxHandleAdornment')
					box.Size = Vector3.new(4, 4, 4)
					box.Color3 = BoxSwingColor.Value
					box.Transparency = 0.7
					box.AlwaysOnTop = true
					box.ZIndex = 10
					local con
					con = game:GetService('RunService').Heartbeat:Connect(function()
						if plr.Character and plr.Character:FindFirstChild('HumanoidRootPart') then
							box.Adornee = plr.Character.HumanoidRootPart
							box.Parent = OtterAura.Enabled and gameCamera or nil
						else
							box.Adornee = nil
						end
					end)
					OtterAura:Clean(con)
					Particles[plr.Player] = box
				end))
			else
				for _, v in pairs(Particles) do
					v:Destroy()
				end
				table.clear(Particles)
			end
		end
	})
	BoxSwingColor = OtterAura:CreateColorSlider({
		Name = 'Swing Color',
		Function = function(val) end,
		Default = Color3.new(1, 0, 0)
	})
	BoxAttackColor = OtterAura:CreateColorSlider({
		Name = 'Attack Color',
		Function = function(val) end,
		Default = Color3.new(1, 1, 0)
	})
	OtterAura:CreateToggle({
		Name = 'Particles',
		Default = true,
		Function = function(callback)
			if callback then
				OtterAura:Clean(game:GetService('RunService').Heartbeat:Connect(function()
					if not OtterAura.Enabled then return end
					local plrs = entitylib.AllPosition({
						Range = SwingRange.Value,
						Part = 'RootPart',
						Players = Targets.Players.Enabled,
						NPCs = Targets.NPCs.Enabled,
						Limit = Max.Value * 2
					})
					for _, plr in plrs do
						if plr.Distance <= AttackRange.Value and not Particles[plr.Player] then
							local particle = Instance.new('ParticleEmitter')
							particle.Texture = ParticleTexture.Value
							particle.Color = ColorSequence.new(ParticleColor1.Value, ParticleColor2.Value)
							particle.Size = NumberSequence.new({
								NumberSequenceKeypoint.new(0, ParticleSize.Value),
								NumberSequenceKeypoint.new(1, 0)
							})
							particle.Transparency = NumberSequence.new({
								NumberSequenceKeypoint.new(0, 0.5),
								NumberSequenceKeypoint.new(1, 1)
							})
							particle.Lifetime = NumberRange.new(0.5, 1)
							particle.Rate = 10
							particle.Speed = NumberRange.new(-5, -2)
							particle.SpreadAngle = Vector2.new(30, 30)
							particle.Acceleration = Vector3.new(0, 10, 0)
							particle.Enabled = true
							particle.Parent = workspace.CurrentCamera
							local con
							con = game:GetService('RunService').Heartbeat:Connect(function()
								if plr.Character and plr.Character:FindFirstChild('HumanoidRootPart') then
									particle.Position = plr.Character.HumanoidRootPart.Position
								else
									particle.Enabled = false
								end
							end)
							OtterAura:Clean(con)
							Particles[plr.Player] = particle
						end
					end
				end))
			else
				for _, v in pairs(Particles) do
					v:Destroy()
				end
				table.clear(Particles)
			end
		end
	})
	ParticleTexture = OtterAura:CreateTextBox({
		Name = 'Particle Texture',
		Function = function(val) end,
		Default = 'rbxassetid://13371830'
	})
	ParticleColor1 = OtterAura:CreateColorSlider({
		Name = 'Particle Color 1',
		Function = function(val) end,
		Default = Color3.new(1, 0, 0)
	})
	ParticleColor2 = OtterAura:CreateColorSlider({
		Name = 'Particle Color 2',
		Function = function(val) end,
		Default = Color3.new(1, 1, 0)
	})
	ParticleSize = OtterAura:CreateSlider({
		Name = 'Particle Size',
		Function = function(val) end,
		Default = 0.5,
		Min = 0.1,
		Max = 2,
		Decimal = 0.1
	})
	Face = OtterAura:CreateToggle({
		Name = 'Face Target',
		Function = function(callback)
			if callback then
				OtterAura:Clean(game:GetService('RunService').Heartbeat:Connect(function()
					if not OtterAura.Enabled then return end
					local plrs = entitylib.AllPosition({
						Range = AttackRange.Value,
						Part = 'RootPart',
						Players = Targets.Players.Enabled,
						NPCs = Targets.NPCs.Enabled,
						Limit = 1
					})
					if #plrs > 0 then
						local plr = plrs[1]
						local target = plr.Character.HumanoidRootPart.Position
						local look = (target - workspace.CurrentCamera.CFrame.Position).unit
						local ray = workspace:Raycast(workspace.CurrentCamera.CFrame.Position, look * AttackRange.Value, raycastparams)
						if not ray or (ray.Instance:IsDescendantOf(plr.Character) and ray.Position:Distance(plr.Character.HumanoidRootPart.Position) < 4) then
							local cf = CFrame.lookAt(workspace.CurrentCamera.CFrame.Position, target)
							workspace.CurrentCamera.CFrame = cf
						end
					end
				end))
			end
		end
	})
end)
	