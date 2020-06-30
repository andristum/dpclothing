if not Config.GUI.Enabled then return end

local Sounds = { -- In case you wanna change out the sounds they are located here.
	["Close"] = {"TOGGLE_ON", "HUD_FRONTEND_DEFAULT_SOUNDSET"},
	["Open"] = {"NAV_LEFT_RIGHT", "HUD_FRONTEND_DEFAULT_SOUNDSET"},
	["Select"] = {"SELECT", "HUD_FRONTEND_DEFAULT_SOUNDSET"}
}
function SoundPlay(which)
	if not Config.GUI.Sound then return end
	local Sound = Sounds[which]
	PlaySoundFrontend(-1, Sound[1], Sound[2])
end

local function Distance(x1, y1, x2, y2)
	local dx = x1 - x2
	local dy = y1 - y2
	return math.sqrt(dx * dx + dy * dy)
end

local function DisableControl()
	DisableControlAction(1, 1, true)
	DisableControlAction(1, 2, true)
	DisableControlAction(1, 18, true)
	DisableControlAction(1, 68, true)
	DisableControlAction(1, 69, true)
	DisableControlAction(1, 70, true)
	DisableControlAction(1, 91, true)
	DisableControlAction(1, 92, true)
	DisableControlAction(1, 24, true)
	DisableControlAction(1, 25, true)
	DisableControlAction(1, 14, true)
	DisableControlAction(1, 15, true)
	DisableControlAction(1, 16, true)
	DisableControlAction(1, 17, true)
	DisablePlayerFiring(PlayerId(), true)	-- We wouldnt want the player punching by accident.
	ShowCursorThisFrame()
end

local function GetCursor() -- This might break for people with weird resolutions? Im really not sure.
	local sx, sy = GetActiveScreenResolution()
	local cx, cy = GetNuiCursorPosition()
	local cx, cy = (cx / sx) + 0.008, (cy / sy) + 0.027
	return cx, cy
end

local function DrawButton(b)
	local B = Config.GUI.ButtonColor
	local Rot = b.Rotate or 0.0
	if b.Shadow then
		DrawSprite("dp_clothing", "circle", b.x, b.y, b.Size.Circle.x/0.80, b.Size.Circle.y/0.80, Rot, b.Colour.r, b.Colour.g, b.Colour.b, b.Alpha)
	end
	DrawSprite("dp_clothing", b.Sprite, b.x, b.y, b.Size.Sprite.x/0.68, b.Size.Sprite.y/0.68, b.Rotation, 255, 255, 255, b.Alpha)
	if IsDisabledControlJustPressed(1, 24) then
		local x,y = GetCursor()
		local Distance = Distance(b.x+0.005, b.y+0.025, x, y)
		if Distance < 0.025 then return true end
	elseif IsDisabledControlJustPressed(1, 25) and Config.Debug then
		local x,y = GetCursor()
		local Distance = Distance(b.x+0.005, b.y+0.025, x, y)
		if Distance < 0.025 then
			DevTestVariants(FirstUpper(b.Sprite))
		end
	end
	return false
end

local function Check(ped) -- We check if the player should be able to open the menu.
	if IsPedInAnyVehicle(ped) and not Config.GUI.AllowInCars then
		return false
	elseif IsPedSwimmingUnderWater(ped) then
		return false
	elseif IsPedRagdoll(ped) and not Config.GUI.AllowWhenRagdolled then
		return false
	elseif IsHudComponentActive(19) then -- If the weapon wheel is open, we close!
		return false
	end
	return true
end

local DefaultButton = {x = 0.0254, y = 0.0445}
local DefaultCircle = {x = 0.0345 / 1.2, y = 0.06 / 1.2}
local Buttons = {}
local ExtraButtons = {}
local InfoButtonRot = 0.0
MenuOpened = false

local function GenerateTheButtons() -- We generate the buttons here to save on a little bit of performance.
	local x, y, rx, ry = Config.GUI.Position.x, Config.GUI.Position.y, 0.1, 0.175
	for k,v in pairs(Config.Commands) do
		local i = v.Button
		local Angle = i * math.pi / 7 local Ptx, Pty = x + rx * math.cos(Angle), y + ry * math.sin(Angle)
		Buttons[i] = {
			Command = k,
			Desc = v.Desc or "",
			Rotation = v.Rotation or 0.0,
			Size = {Sprite = DefaultButton},
			Sprite = v.Sprite,
			Text = v.Name,
			x = Ptx, y = Pty,
			Rotation = 0.0
		}
	end
	if Config.ExtrasEnabled then -- The extra buttons arent tied to the wheel, and can be moved with simple offsets.
		for k,v in pairs(Config.ExtraCommands) do
			local Enabled = v.Enabled if Enabled == nil then Enabled = true end
			ExtraButtons[k] = {
				Command = k,
				Desc = v.Desc or "",
				OffsetX = v.OffsetX, OffsetY = v.OffsetY,
				Size = { Circle = {x = DefaultCircle.x, y = DefaultCircle.y}, Sprite = {x = DefaultButton.x/1.35, y = DefaultButton.y/1.35}},
				Sprite = v.Sprite,
				SpriteFunc = v.SpriteFunc,
				Text = v.Name,
				Enabled = Enabled,
				Rotate = v.Rotate,
				Rotation = 0.0
			}
		end
	end
end

local function PushedButton(button, extra, rotate, info) -- https://www.youtube.com/watch?v=v57i1Ze0jB8
	Citizen.CreateThread(function()	
		SoundPlay("Select")
		local Button = nil
		if extra then Button = ExtraButtons[button] elseif info then Button = InfoButton else Button = Buttons[button] end
		if rotate then
			for i = 1, 18 do
				if not info then Button.Rotation = -i*20+0.0 Wait(1) else InfoButtonRot = -i*20+0.0 Wait(1) end
			end return
		end
		if not extra then
			Button.Size = {Sprite = {x = DefaultButton.x/1.1, y = DefaultButton.y/1.1}}
			Wait(100)
			Button.Size = {Sprite = {x = DefaultButton.x, y = DefaultButton.y}}
		else
			Button.Size = { Circle = {x = DefaultCircle.x, y = DefaultCircle.y}, Sprite = {x = DefaultButton.x/1.3/1.1, y = DefaultButton.y/1.3/1.1}}
			Wait(100)
			Button.Size = { Circle = {x = DefaultCircle.x, y = DefaultCircle.y}, Sprite = {x = DefaultButton.x/1.35, y = DefaultButton.y/1.35}}
		end
	end)
end

local function HoveredButton()
	local x,y = GetCursor()
	for k,v in pairs(Buttons) do
		local Distance = Distance(v.x+0.005, v.y+0.025, x, y)
		if Distance < 0.025 then
			Text(Config.GUI.Position.x, Config.GUI.Position.y-0.10, 0.3, v.Text, false, false, true)
			Text(Config.GUI.Position.x, Config.GUI.Position.y-0.08, 0.22, v.Desc, {210,210,210}, false, true, {x = 0.1, y = 0.2})
		end
	end
	for k,v in pairs(ExtraButtons) do
		if v.Enabled then
			local Distance = Distance(Config.GUI.Position.x+v.OffsetX+0.005, Config.GUI.Position.y+v.OffsetY+0.025, x, y)
			local ShouldDisplay = true
			if v.SpriteFunc then
				local SpriteVar = v.SpriteFunc()
				if SpriteVar then
					ShouldDisplay = true
				else
					ShouldDisplay = false
				end
			end
			if ShouldDisplay then
				if Distance < 0.025 then
					Text(Config.GUI.Position.x, Config.GUI.Position.y-0.10, 0.3, v.Text, false, false, true)
					Text(Config.GUI.Position.x, Config.GUI.Position.y-0.08, 0.22, v.Desc, {210,210,210}, false, true, {x = 0.1, y = 0.2})
				end
			end
		end
	end
	local Distance = Distance(Config.GUI.Position.x+0.005, Config.GUI.Position.y+0.025, x, y)
	if Distance < 0.015 then
		Text(Config.GUI.Position.x, Config.GUI.Position.y-0.09, 0.3, Lang("Info"), false, false, true)
	end
end

--[[
		This is the function that draws the GUI, im using native DrawSprites and Texts.
		Its not the most efficient thing ms wise, but it does the job pretty well, and i dont have to bother with NUI HTML stuff.
		If you have any performance tips, let me know.
]]--

local function DrawGUI()
	DisableControl() -- Disable control while GUI is active.
	HoveredButton()	 -- This checks if you are hovering a button, and if you are it displays name and description.
	local x, y, rx, ry = Config.GUI.Position.x, Config.GUI.Position.y, 0.1, 0.175
	for k,v in pairs(Buttons) do
		local Colour local Alpha
		if LastEquipped[FirstUpper(v.Sprite)] then
			Alpha = 180 Colour = {r=0,g=100,b=210,a=220}
		else 
			Alpha = 255 Colour = {r=0,g=0,b=0,a=255}
		end
		DrawSprite("dp_wheel", k.."", x, y, 0.4285, 0.7714, 0.0, Colour.r, Colour.g, Colour.b, Colour.a)
		local Button = DrawButton({	-- Lets draw the buttons!
			Alpha = Alpha,
			Colour = Colour,
			Rotation = v.Rotation,
			Size = v.Size,
			Sprite = v.Sprite,
			Text = v.Text,
			x = v.x, y = v.y,
			Rotation = v.Rotation,
		})
		if Button and not Cooldown then	-- If the button is clicked we execute the command, just like if the player typed it in chat.
			if v.Sprite == "gloves" then
				if not LastEquipped["Shirt"] then
					PushedButton(k)  ExecuteCommand(v.Command)  
				else
					Notify(Lang("NoShirtOn"))
				end
			else
				PushedButton(k)  ExecuteCommand(v.Command)  
			end
			
		end
	end
	for k,v in pairs(ExtraButtons) do
		if v.Enabled then
			local Colour local Alpha
			if LastEquipped[FirstUpper(v.Sprite)] then
				Alpha = 180 Colour = {r=0,g=100,b=210,a=220}
			else 
				Alpha = 255 Colour = {r=0,g=0,b=0,a=255}
			end
			local sprite = v.Sprite
			if v.SpriteFunc then
				local SpriteVar = v.SpriteFunc()
				if SpriteVar then
					sprite = SpriteVar
				else
					sprite = false
				end
			end
			if sprite then
				local Button = DrawButton({
					Alpha = Alpha,
					Colour = Colour,
					Shadow = true,
					Size = v.Size,
					Sprite = sprite,
					Text = v.Text,
					x = x + v.OffsetX,
					y = y + v.OffsetY,
					Rotation = v.Rotation,
				})
				if Button and not Cooldown then
					PushedButton(k, true, v.Rotate) ExecuteCommand(v.Command)  
				end
			end
		end
	end
	if Cooldown then Text(x, y+0.05, 0.28, Lang("PleaseWait"), false, false, true) end 		-- Cooldown indicator, if theres a cooldown we display a little text.
	local InfoButton = DrawButton({
		Alpha = 255,
		Colour = {r=0,g=0,b=0},
		Shadow = true,
		Size = {Circle = {x = 0.0345, y = 0.06}, Sprite = {x = 0.0234, y = 0.0425}},
		Sprite = "info",
		Text = Lang("Info"),
		x = x, y = y,
		Rotation = InfoButtonRot,
	})
	if InfoButton then 			
		PushedButton(k, true, true, true)										
		Notify(Lang("Information"))
		for k,v in pairs(LastEquipped) do log(k.." : "..json.encode(v)) end		-- If the info button is pressed we log all "LastEquipped" items, for debugging purposes.
	end
end

local TextureDicts = {"dp_clothing", "dp_wheel"}
Citizen.CreateThread(function()
	for k,v in pairs(TextureDicts) do while not HasStreamedTextureDictLoaded(v) do Wait(100) RequestStreamedTextureDict(v, true) end end
	GenerateTheButtons()
	while true do Wait(0)
		if not Config.GUI.Toggle then
			if IsControlPressed(1, Config.GUI.Key) then
				local Ped = PlayerPedId() 
				if Check(Ped) then MenuOpened = true end
			else MenuOpened = false end
			if IsControlJustPressed(1, Config.GUI.Key) then
				local Ped = PlayerPedId() 
				if Check(Ped) then SoundPlay("Open") SetCursorLocation(Config.GUI.Position.x, Config.GUI.Position.y) end
			elseif IsControlJustReleased(1, Config.GUI.Key) then
				if Check(Ped) then MenuOpened = false SoundPlay("Close") end
			end
		else
			if IsControlJustPressed(1, Config.GUI.Key) then
				local Ped = PlayerPedId() 
				if Check(Ped) then SoundPlay("Open") SetCursorLocation(Config.GUI.Position.x, Config.GUI.Position.y) MenuOpened = not MenuOpened end
			end
		end
		if MenuOpened then DrawGUI() end
		if Config.Debug then DrawDev() end
	end
end)