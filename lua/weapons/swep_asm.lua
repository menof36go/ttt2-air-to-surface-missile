SWEP.PrintName = "Air-to-Surface Missile"
SWEP.Author = "Otger"
SWEP.Purpose = "Air-to-Surface Controllable Missile."
SWEP.Instructions = "Left click to launch an air-to-surface missile attack from the sky above the aimed position.\nUse the mouse or the movement keys to direct it.\nLeft click to launch, right click to abort."
SWEP.Slot = 4
SWEP.SlotPos = 1
SWEP.BounceWeaponIcon = true
SWEP.DrawAmmo = true
SWEP.DrawCrosshair = true
SWEP.Base = "weapon_tttbase"
SWEP.Kind = WEAPON_EQUIP1
SWEP.CanBuy = { ROLE_TRAITOR }
SWEP.AutoSpawnable = false
SWEP.AmmoEnt = "item_ammo_pistol_ttt"
SWEP.InLoadoutFor = nil
SWEP.AllowDrop = true
SWEP.IsSilent = false
SWEP.NoSights = false
SWEP.Icon = "vgui/ttt/icon_asm_64.jpg" -- Text shown in the equip menu
SWEP.EquipMenuData = { type = "Missile", desc = "Left click to launch an air-to-surface missile attack from the sky above the aimed position.\nUse the mouse or the movement keys to direct it.\nLeft click to launch, right click to abort."};
SWEP.Weight = 7
SWEP.AutoSwitchTo = false
SWEP.AutoSwitchFrom = false
SWEP.Spawnable = true
SWEP.AdminSpawnable = true
SWEP.Primary.ClipSize = -1
SWEP.Primary.DefaultClip = -1
SWEP.Primary.Automatic = false
SWEP.Primary.Ammo = "none"
SWEP.Secondary.ClipSize = -1
SWEP.Secondary.DefaultClip = -1
SWEP.Secondary.Automatic = false
SWEP.Secondary.Ammo = "none"
SWEP.CountdownEnd = 0
SWEP.LastPosInBounds = nil
SWEP.UserID = -1

if SERVER then
    AddCSLuaFile()
    resource.AddFile("materials/VGUI/swep_asm.vmt")
    resource.AddFile("materials/VGUI/swep_asm.vtf")
    resource.AddFile("materials/VGUI/ttt/icon_asm_64.jpg")
    --resource.AddFile("materials/HUD/asm_available.vmt")
    --resource.AddFile("materials/HUD/asm_available.vtf")
    resource.AddFile("materials/HUD/killicons/asm_missile.vmt")
    resource.AddFile("materials/HUD/killicons/asm_missile.vtf")
    if util.IsValidModel("models/weapons/v_c4.mdl") then
        SWEP.ModelC4 = true
        SWEP.ViewModel = "models/weapons/v_c4.mdl"
        SWEP.WorldModel = "models/weapons/w_c4.mdl"
    else
        SWEP.ModelC4 = false
        SWEP.ViewModel = "models/weapons/v_toolgun.mdl"
        SWEP.WorldModel = "models/weapons/w_toolgun.mdl"
    end
end

local SndReady = Sound("npc/metropolice/vo/isreadytogo.wav")
local SndReadyB = Sound("buttons/blip2.wav")
local SndRequested = Sound("buttons/button24.wav")
local SndInbound = Sound("npc/combine_soldier/vo/inbound.wav")
local Debug = GetConVar("ttt_asm_show_debug"):GetBool()
local CountdownLength = GetConVar("ttt_asm_aim_time"):GetFloat()
local ShiftSpeedModifier = GetConVar("ttt_asm_shift_speed_modifier"):GetFloat()
local AltSpeedModifier = GetConVar("ttt_asm_alt_speed_modifier"):GetFloat()
local MouseSpeedModifier = GetConVar("ttt_asm_mouse_speed_modifier"):GetFloat()
local AllowAbort = GetConVar("ttt_asm_allow_abort"):GetBool()
local AllowAbortMidFlight = GetConVar("ttt_asm_allow_abort_mid_flight"):GetBool()
local AllowCameraMoveMidFlight = GetConVar("ttt_asm_allow_camera_move_mid_flight"):GetBool()

local function debugPrint(...)
    if (Debug) then
        local arg = {...}
        if (CLIENT) then
			print("Client", unpack(arg))
	    elseif (SERVER) then
			print("Server", unpack(arg))
		end
	end
end

util.PrecacheModel("models/props_junk/PopCan01a.mdl")
util.PrecacheModel("models/props_c17/canister01a.mdl")

function SWEP:Initialize()
    Debug = GetConVar("ttt_asm_show_debug"):GetBool()
    CountdownLength = GetConVar("ttt_asm_aim_time"):GetFloat()
    ShiftSpeedModifier = GetConVar("ttt_asm_shift_speed_modifier"):GetFloat()
    AltSpeedModifier = GetConVar("ttt_asm_alt_speed_modifier"):GetFloat()
    MouseSpeedModifier = GetConVar("ttt_asm_mouse_speed_modifier"):GetFloat()
    AllowAbort = GetConVar("ttt_asm_allow_abort"):GetBool()
    AllowAbortMidFlight = GetConVar("ttt_asm_allow_abort_mid_flight"):GetBool()
    AllowCameraMoveMidFlight = GetConVar("ttt_asm_allow_camera_move_mid_flight"):GetBool()
    self.Delay = 0
    self.Status = 0
    self.ThirdPerson = false

    if self.ModelC4 then self:SetWeaponHoldType("slam")
    else self:SetWeaponHoldType("pistol") end

    if CLIENT then
        self.FadeCount = 0
        self.Load = 0
        killicon.Add("sent_asm","HUD/killicons/asm_missile",Color(255,0,0,255))
        language.Add("sent_asm","Air-to-surface Missile")
        hook.Add("HUDPaint","ASMSwepDrawHUD", function() 
            if IsValid(self) then
                if IsValid(self.Owner) then
                    if IsValid(LocalPlayer()) then
                        if (self.Owner == LocalPlayer()) then
                            if (type(self.DrawInactiveHUD) == "function") then
                                self:DrawInactiveHUD()
                            else
                                hook.Remove("ASMSwepDrawHUD")
                            end
                        end
                    end
                end
            end
        end)
    end
end

function SWEP:OnDrop()
    local ply = Player(self.UserID)
    if IsValid(ply) then
        ply:SetViewEntity(ply)
    end
    self:UnlockPlayer()
    if IsValid(self.Camera) then
        debugPrint("Air-To-Surface-Missile: OnDrop - Camera valid")
        if IsValid(self.Owner) then
            debugPrint("Air-To-Surface-Missile: OnDrop - Owner valid")
            if (self.Owner:GetViewEntity() == self.Camera) then
                debugPrint("Air-To-Surface-Missile: OnDrop - Reset View Entity")
                self.Owner:SetViewEntity(self.Owner)
            end
        end
        self.Camera:Remove()
    end
end

function SWEP:OnRemove()
    if SERVER then
        debugPrint("Air-To-Surface-Missile: OnRemove - Camera valid")
        self:UnlockPlayer()
        if IsValid(self.Camera) then
            debugPrint("Air-To-Surface-Missile: OnRemove - Camera valid")
            if IsValid(self.Owner) then
                debugPrint("Air-To-Surface-Missile: OnRemove - Owner valid")
                if (self.Owner:GetViewEntity() == self.Camera) then
                    debugPrint("Air-To-Surface-Missile: OnRemove - Reset View Entity")
                    self.Owner:SetViewEntity(self.Owner)
                end
            end
            self.Camera:Remove()
        end
    end
    if CLIENT then
        if self.HtmlIcon && self.HtmlIcon:IsValid() then self.HtmlIcon:Remove() end
        self.HtmlIcon = nil
        if(self.Menu && self.Menu:IsValid()) then
            self.Menu:SetVisible(false)
            self.Menu:Remove()
        end
        debugPrint("Remove hud hook")
        hook.Remove("HUDPaint","AsmSwepDrawHUD")
    end
end

function SWEP:Deploy()
    if SERVER then
        self:SendWeaponAnim(ACT_VM_DRAW)
    end
    return true
end

function SWEP:Holster()
    if(self.Status>0) then 
        return false 
    end
    return true
end

function SWEP:ShouldDropOnDie() 
    return false 
end

function CheckFriendly(team, ent)
    debugPrint("Check friendly", IsValid(ent) and ent:IsPlayer() and ent:GetName(), team, ent, IsValid(ent), ent:IsPlayer(), ent.GetTeam)
    if team ~= nil and IsValid(ent) and ent:IsPlayer() then
        if TTT2 and ent.GetTeam then
            return ent:GetTeam() == team
        else
            return ent:GetRole() == team
        end
    end
    return false
end

-- SERVER --

if SERVER then
    util.AddNetworkString("ASM-Update")
    util.AddNetworkString("ASM-Msg")

    function SWEP:PrimaryAttack()
        if(self.Status == 0) then
            if self.Delay > CurTime() then return end

            local tr = self.Owner:GetEyeTrace()
            local vPos = self:FindInitialPos(tr.HitPos)

            if vPos then
                self:SpawnCamera(vPos)
                self.Owner:ConCommand("firstperson")
                self:SendWeaponAnim(ACT_VM_PRIMARYATTACK)
                self.Owner:SetAnimation(PLAYER_ATTACK1)
                self:EmitSound(SndRequested)
                
                self:LockPlayer()
                self:SetStatus(1,1.75)
            else
                self:SendMessage(1)
            end
        elseif(self.Status == -1) then
            self:SendMessage(2)
        end
        self:SetNextPrimaryFire(CurTime()+1)
    end

    function SWEP:SecondaryAttack() end

    function SWEP:Reload() end

    function SWEP:Equip()
        --if !self.ModelC4 then self:SendMessage(0) end
        if IsValid(self.Owner) then
            self.UserID = self.Owner:UserID()
        end
    end

    function SWEP:Think()
        if CurTime() < self.Delay then 
            return 
        end

        if self.Status == 1 then
            self:SetStatus(2,0.5)
        -- Try start missile
        elseif self.Status == 2 then
            self.Owner:SetViewEntity(self.Camera)
            self:SendWeaponAnim(ACT_VM_IDLE)
            self:SetStatus(3,0)
        elseif (self.Status>2) &&(self.Status<6) then
            local pos = self.Camera:GetPos()
            local tr = util.TraceLine({
                start = pos,
                endpos = Vector(pos.x, pos.y, -10000),
                mask = MASK_NPCWORLDSTATIC,
                filter = { self.Camera }
            })
            if (tr.Hit == false) then
                if (self.LastPosInBounds) then
                    self.Camera:SetPos(self.LastPosInBounds)
                    pos = self.LastPosInBounds
                end
            else
                self.LastPosInBounds = pos
            end
 
            if (self.Status==3) then --[[unused]] end
            if self.Status < 5 then
                if self.Owner:KeyDown(IN_ATTACK) or self.Owner:KeyDown(IN_USE) or (self.CountdownEnd - CurTime() <= 0) then
                    if not IsValid(self.Missile) then
                        self:SpawnMissile(pos)
                        -- We skip the slow stage and immediately go to the boost stage
                        self:SetStatus(4,0)
                        if (self.Missile) then
                            self.Missile:Boost()
                        end
                        self.Camera:SetVelocity(-self.Camera:GetVelocity())
                    end
                end
                if (AllowAbort and self.Owner:KeyDown(IN_ATTACK2)) then
                    if (IsValid(self.Missile) and AllowAbortMidFlight) then
                        self:MissileEndPhase()
                    elseif (not IsValid(self.Missile)) then
                        self.Owner:SetViewEntity(self.Owner)
                        self:UnlockPlayer()
                        self:SetStatus(6,0)
                    end
                end
                -- Only allow moving the camera if the missile isn't already fired
                if not IsValid(self.Missile) or AllowCameraMoveMidFlight then
                    local mVel = Vector(0,0,0)
                    local kVel = Vector(0,0,0)
                    local treshold = 0.9
                    local cmd = self.Owner:GetCurrentCommand()
                    local SpeedModifier = 1
                    local maxVal = 300
                    local maxValMouse = maxVal * MouseSpeedModifier

                    if self.Owner:KeyDown(IN_FORWARD) then kVel=kVel+Vector(maxVal - 0.1,0,0) end
                    if self.Owner:KeyDown(IN_BACK) then kVel=kVel+Vector(-maxVal - 0.1,0,0) end
                    if self.Owner:KeyDown(IN_MOVELEFT) then kVel=kVel+Vector(0,maxVal - 0.1,0) end
                    if self.Owner:KeyDown(IN_MOVERIGHT) then kVel=kVel+Vector(0,-maxVal - 0.1,0) end
                    if self.Owner:KeyDown(IN_SPEED) then 
                        SpeedModifier = ShiftSpeedModifier
                    elseif self.Owner:KeyDown(IN_WALK) then 
                        SpeedModifier = AltSpeedModifier
                    end

                    mVel=mVel+Vector(0,-cmd:GetMouseX() * 3 * MouseSpeedModifier,0)
                    mVel=mVel+Vector(-cmd:GetMouseY() * 3 * MouseSpeedModifier,0,0)

                    if (math.abs(mVel.x) > treshold or math.abs(mVel.y) > treshold) then
                        if (math.abs(kVel.x) > treshold or math.abs(kVel.y) > treshold) then
                            if (math.abs(kVel.x) > maxVal or math.abs(kVel.y) > maxVal) then
                                kVel.x = math.Clamp(kVel.x, -maxVal, maxVal)
                                kVel.y = math.Clamp(kVel.y, -maxVal, maxVal)
                            end
                        end
                        mVel:Add(kVel)
                        if (math.abs(mVel.x) > maxValMouse or math.abs(mVel.y) > maxValMouse) then
                            mVel.x = math.Clamp(mVel.x, -maxValMouse, maxValMouse)
                            mVel.y = math.Clamp(mVel.y, -maxValMouse, maxValMouse)
                        end
                        self.Camera:SetVelocity(mVel * SpeedModifier - self.Camera:GetVelocity() * 0.7)
                        --debugPrint(mVel * SpeedModifier - self.Camera:GetVelocity())
                    elseif (math.abs(kVel.x) > treshold or math.abs(kVel.y) > treshold) then
                        if (math.abs(kVel.x) > maxVal or math.abs(kVel.y) > maxVal) then
                            kVel.x = math.Clamp(kVel.x, -maxVal, maxVal)
                            kVel.y = math.Clamp(kVel.y, -maxVal, maxVal)
                        end
                        self.Camera:SetVelocity(kVel * SpeedModifier - self.Camera:GetVelocity() * 0.7)
                        --debugPrint(kVel * SpeedModifier - self.Camera:GetVelocity())
                    else
                        local drag = self.Camera:GetVelocity()
                        drag = -0.7 * drag
                        self.Camera:SetVelocity(drag)
                    end
                end
            end
        -- Missile already exploded
        elseif self.Status == 6 then
            self:UnlockPlayer()
            self:SetStatus(-1,0)
            timer.Simple(3, function()
                if IsValid(self) then
                    if self.Status == -1 then self:SetStatus(0,0) end
                end
            end)
        end
    end

    function SWEP:SetStatus(status,delay)
        self.Status = (status or 0)
        if delay > 0 then self.Delay = CurTime() + delay end
        if IsValid(self.Owner) then
            local send = -1
            if (status == 2) then
                self.CountdownEnd = CurTime() + CountdownLength
                send = self.CountdownEnd 
                debugPrint("Send", send)
            end
            net.Start("ASM-Update")
            net.WriteDouble(send)
            net.WriteEntity(self.Weapon)
            net.WriteInt(status or 0, 32)
            net.Send(self.Owner)
        end
    end

    function SWEP:SendMessage(id)
        net.Start("ASM-Msg")
        net.WriteInt(id, 32)
        net.Send(self.Owner)
    end
    
    function SWEP:CreateCamera()
        local ent = ents.Create("prop_physics")
            ent:SetModel("models/props_junk/PopCan01a.mdl")
            ent:SetPos(self.Owner:GetPos())
            ent:SetAngles(Angle(90,0,0))
        ent:Spawn()
        ent:Activate()
        ent:SetMoveType(MOVETYPE_NOCLIP)
        ent:SetSolid(SOLID_NONE)
        ent:SetRenderMode(RENDERMODE_NONE)
        ent:DrawShadow(false)
        return ent
    end

    function SWEP:SpawnCamera(vPos)
        if !IsValid(self.Camera) then 
            self.Camera = self:CreateCamera() 
        end

        self.Camera:SetPos(vPos+Vector(0,0,-56))
        self.Camera:SetAngles(Angle(90,0,0))
    end

    function SWEP:SpawnMissile(vPos)
        local mis = ents.Create("sent_asm")
            mis:SetPos(vPos+Vector(0,0,mis:OBBMins().z-48))
            mis:SetAngles(Angle(90,0,0))
        mis:Spawn()
        mis:Activate()
        mis:Launch()
        if IsValid(self.Owner) then
            if TTT2 then
                mis.AssociatedTeam = self.Owner:GetTeam()
            else
                mis.AssociatedTeam = self.Owner:GetRole()
            end
            mis.UserID = self.Owner:UserID()
        end

        if IsValid(mis) then
            mis.Owner = self.Owner
            mis.SWEP = self

            self.Missile = mis
            self:SetNWEntity("Missile",mis)
            return true
        end
        return false
    end

    local function ASMSetVis(ply)
        local wep = ply:GetActiveWeapon()
        if IsValid(wep) && wep:GetClass() == "swep_asm" then
            if (wep.Status==2) or (wep.Status==3) then
                if IsValid(wep.Camera) then AddOriginToPVS(wep.Camera:GetPos()) end
            end
        end
    end
    hook.Add("SetupPlayerVisibility", "ASMSetupVis", ASMSetVis)

    local function ASMGetDmg(ent,dmginfo)
        if (ent:GetClass() ~= "player") then
            return
        end
        local inflictor = dmginfo:GetInflictor() -- The SWEP
        local attacker = dmginfo:GetAttacker() -- The SENT or the Owner
        local output = ""
        if IsValid(inflictor) and inflictor.GetClass then
            local infClass = inflictor:GetClass()
            if infClass != "swep_asm" and infClass != "sent_asm" then
                return
            end
            if infClass == "sent_asm" then
                local nI = ents.Create("swep_asm")
                debugPrint("Changed inflictor", inflictor, nI)
                inflictor = nI
                dmginfo:SetInflictor(nI)
            end
            local class = attacker:GetClass()
            if (class == "sent_asm" or class == "player") then
                local team = nil
                local id = nil
                if (class == "player" and IsValid(attacker)) then
                    output = output .. "Hit by the blast!"
                    if TTT2 then
                        team = attacker:GetTeam()
                    else
                        team = attacker:GetRole()
                    end
                    id = attacker:UserID()
                else
                    output = output .. "Hit right on the head, ouch!"
                    team = attacker.AssociatedTeam
                    id = attacker.UserID
                    local nA = Player(attacker.UserID)
                    if nA then
                        debugPrint("Changed attacker", attacker, nA)
                        attacker = nA
                        dmginfo:SetAttacker(nA)
                    end
                end
                output = output .. " | Attacker - team: " .. tostring(team) .. " id " .. tostring(id)
                local entID = nil
                entID = ent:UserID()
                if (entID ~= nil) then
                    output = output .. " | Hit: " .. ent:GetName()
                    if (id == entID) && !GetConVar("ttt_asm_damage_owner"):GetBool() then
                        output = output .. " | No damage, because owner damage is disabled!"
                        dmginfo:SetDamage(0)
                    elseif !GetConVar("ttt_asm_friendlyfire"):GetBool() && CheckFriendly(team, ent) then
                        output = output .. " | No damage, because friendlyfire damage is disabled!"
                        dmginfo:SetDamage(0)
                    end
                end
            end
            debugPrint(output)
        end
    end
    hook.Add("EntityTakeDamage", "ASMSetupDamage", ASMGetDmg)

    function SWEP:LockPlayer()
        self.LastMoveType = self.Owner:GetMoveType()
        self.Owner:SetMoveType(MOVETYPE_NONE)
    end

    function SWEP:UnlockPlayer()
        debugPrint("Air-To-Surface-Missile: Unlock player")
        if IsValid(self.Owner) then
            if (self.Owner:GetMoveType() == MOVETYPE_NONE) then
                debugPrint("Air-To-Surface-Missile: Actually unlock player")
                self.Owner:SetMoveType(self.LastMoveType or MOVETYPE_WALK)
            end
        end
    end

    function SWEP:MissileEndPhase()
        debugPrint("Air-To-Surface-Missile: Missile is in air or destroyed")
        if IsValid(self.Owner) then
            self.Owner:SetViewEntity(self.Owner)
            self:UnlockPlayer()
            debugPrint("Air-To-Surface-Missile: Missile end phase - Reset View Entity")
        end
        if IsValid(self.Camera) then
            self.Camera:SetParent(nil)
        end
        if(self.Status>1) then
            self:SetStatus(6,0.5)
			self:Remove()
        end
    end

    function SWEP:FindInitialPos(vStart)
        local td = {}
            td.start = vStart+Vector(0,0,-32)
            td.endpos = vStart
            td.endpos.z = 16384
            td.mask = MASK_NPCWORLDSTATIC
            td.filter = {}
        local bContinue = true
        local nCount=0
        local tr = {}
        local vPos = nil

        while bContinue && td.start.z <= td.endpos.z do
            nCount = nCount + 1
            tr = util.TraceLine(td)
            if tr.HitSky then
                vPos = tr.HitPos
                bContinue = false
            elseif !tr.Hit then
                td.start = tr.HitPos - Vector(0,0,64)
            elseif tr.HitWorld then
                td.start = tr.HitPos + Vector(0,0,64)
            elseif(IsValid(tr.Entity)) then
                table.insert(td.filter, tr.Entity)
            end
            if nCount>128 then break end
        end
        return vPos
    end


    
    function SWEP:CheckFriendly(ent)
        if GetConVar("ttt_asm_show_colleagues"):GetBool() then
            if IsValid(self.Owner) then
                local teamOwn = nil
                if TTT2 then
                    teamOwn = self.Owner:GetTeam()
                else
                    teamOwn = self.Owner:GetRole()
                end
                return CheckFriendly(teamOwn,ent)
            end
            return false
        else
            if ent:Disposition(self.Owner) == 1 then
                return false 
            end
            return true
        end
    end
end

-- CLIENT --

if CLIENT then

    surface.CreateFont("AsmScreenFont", {
      size = 18,
      weight = 400,
      antialias = false,
      shadow = false,
      font = "Trebuchet MS"})

    surface.CreateFont("AsmCamFont", {
      size = 22,
      weight = 700,
      antialias = false,
      shadow = false,
      font = "Courier New"})

    --local texScreenOverlay = surface.GetTextureID("effects/combine_binocoverlay")
    --local matMissileAvailable = Material("HUD/asm_available")
    
    local SndNoPos = Sound("npc/combine_soldier/vo/sectorisnotsecure.wav")
    local SndNoPosB = Sound("buttons/button19.wav")
    local SndNotReady = Sound("buttons/button2.wav")
    local SndLost = Sound("npc/combine_soldier/vo/lostcontact.wav")

    function SWEP:Think() end

    net.Receive("ASM-Update", function(len,ply) 
        local countdownEnd = net.ReadDouble()
        local ent = net.ReadEntity()
        local status = net.ReadInt(32)
        if IsValid(ent) && ent:GetClass() == "swep_asm" then
            ent:UpdateStatus(status)
            if not (countdownEnd == -1) and status == 2 then
                ent.CountdownEnd = countdownEnd
            end
        end
    end)

    net.Receive("ASM-Msg", function(len,ply) 
        local nId = net.ReadInt(32)
        if(nId==0) then
            MsgN("[Air-to-surface Missile SWEP] Counter-Strike: Source is not mounted. Using Toolgun model.")
        elseif(nId==1) then
            notification.AddLegacy("Could not find open sky above the specified position",NOTIFY_ERROR,5)
            LocalPlayer():EmitSound(SndNoPos)
            LocalPlayer():EmitSound(SndNoPosB)
        elseif(nId==2) then
            notification.AddLegacy("Missiles currently unavailable",NOTIFY_ERROR,5)
            LocalPlayer():EmitSound(SndNotReady)
        elseif(nId==3) then
            notification.AddLegacy("Lost contact with the missile",NOTIFY_GENERIC,5)
            LocalPlayer():EmitSound(SndLost)
        end
    end)

    function SWEP:UpdateStatus(status)
        local nLastStatus = self.Status
        self.Status = status
        if status == 0 then
            if (self.HtmlIcon) then self.HtmlIcon:SetVisible(true) end
            if nLastStatus == -1 then
                self:EmitSound(SndReady)
                self:EmitSound(SndReadyB)
            end
        else
            if (self.HtmlIcon) then self.HtmlIcon:SetVisible(false) end
            if status == 1 then
                self.Load = CurTime()+1.75
            elseif status == 2 then
                self:EmitSound(SndInbound)
                self.FadeCount = 0
            elseif status == 3 then
                self.FadeCount = 255
            end
        end
        if self.Menu && status > 0 then
            self.Menu:SetVisible(false)
        end
    end

    function SWEP:DrawInactiveHUD()
        if self.Status == 0 then
            draw.RoundedBoxEx(8,ScrW()-50,60,50,60,Color(224,224,224,255),true,false,true,false)
            draw.DrawText("Missile\nReady","HudHintTextLarge",ScrW()-4, 26,Color(224,224,224,255),TEXT_ALIGN_RIGHT)
        end
    end

    function SWEP:CheckFriendly(ent)
        if GetConVar("ttt_asm_show_colleagues"):GetBool() then
            if IsValid(self.Owner) then
                local teamOwn = nil
                if TTT2 then
                    teamOwn = self.Owner:GetTeam()
                else
                    teamOwn = self.Owner:GetRole()
                end
                return CheckFriendly(teamOwn,ent)
            end
            return false
        else
            if ent == LocalPlayer() then 
                return true 
            end
            return false
        end
    end

    function SWEP:DrawHUD()
        if self.Status > 1 then
            if self.Status == 2 then
                surface.SetDrawColor(0,0,0,self.FadeCount)
                surface.DrawRect(0,0,ScrW(),ScrH())

                if(self.FadeCount < 255) then
                    self.FadeCount=self.FadeCount+5
                end
            elseif self.Status > 4 then
                surface.SetDrawColor(0,0,0,self.FadeCount)
                surface.DrawRect(0,0,ScrW(),ScrH())

                if(self.FadeCount > 0) then
                    self.FadeCount=self.FadeCount-5
                end
            elseif self.Status == 3 or self.Status == 4 then
                local col = {}
                    col["$pp_colour_addr"] =0
                    col["$pp_colour_addg"] = 0
                    col["$pp_colour_addb"] = 0
                    col["$pp_colour_brightness"] = 0.1
                    col["$pp_colour_contrast"] = 1
                    col["$pp_colour_colour"] = 0
                    col["$pp_colour_mulr"] = 0
                    col["$pp_colour_mulg"] = 0
                    col["$pp_colour_mulb"] = 0
                DrawColorModify(col)
                DrawSharpen(1,2)

                local h = ScrH()/2
                local w = ScrW()/2
                local ho = 2*h/3

                surface.SetDrawColor(160,160,160,255)
                surface.DrawOutlinedRect(w-48,h-32,96,64)

                surface.DrawLine(w, h-32, w, h-128)
                surface.DrawLine(w, h+32, w, h+128)
                surface.DrawLine(w-48, h, w-144, h)
                surface.DrawLine(w+48, h, w+144, h)

                surface.DrawLine(w-ho, h-ho+64, w-ho, h-ho)
                surface.DrawLine(w-ho, h-ho, w-ho+64, h-ho)
                surface.DrawLine(w+ho-64, h-ho, w+ho, h-ho)
                surface.DrawLine(w+ho, h-ho, w+ho, h-ho+64)
                surface.DrawLine(w+ho, h+ho-64, w+ho, h+ho)
                surface.DrawLine(w+ho, h+ho, w+ho-64, h+ho)
                surface.DrawLine(w-ho+64, h+ho, w-ho, h+ho)
                surface.DrawLine(w-ho, h+ho, w-ho, h+ho-64)

                local camera = GetViewEntity(LocalPlayer())
                local pos = camera:GetPos()
                surface.SetFont("AsmCamFont")
                surface.SetTextColor(64,64,64,255)

                surface.SetTextPos(24,16)
                surface.DrawText(tostring(math.Round(pos.x)).." "..tostring(math.Round(pos.y)).." "..tostring(math.Round(pos.z)))

                surface.SetTextPos(24,40)
                local dist = self.Owner:GetEyeTrace().HitPos:Distance(pos-Vector(0,0,pos.z))
                surface.DrawText(tostring(math.Round(dist)).." : "..tostring(math.Round(camera:GetVelocity():Length())))

                surface.SetTextPos(24,64)
                surface.DrawText("5 295 ["..math.Round(CurTime()).."]")
                surface.SetTextPos(24,84)
                surface.SetFont("CloseCaption_Bold")
                local Countdown = math.Round((self.CountdownEnd - CurTime()) * 10) / 10.0
                if (math.fmod(math.Round(Countdown), 2) == 0) then
                    surface.SetTextColor(220,220,220,255)
                else
                    surface.SetTextColor(220,0,0,255)
                end
                surface.DrawText("Time remaining: ".. Countdown)
                surface.SetFont("Default")
                surface.SetTextColor(64,64,64,255)

                local tEnts = player.GetAll()
                for _,ent in pairs(tEnts) do
                    if (IsValid(ent)) then
                        local vPos = ent:GetPos()+Vector(0,0,0.5*ent:OBBMaxs().z)
                        local scrPos = vPos:ToScreen()
                        if self:CheckFriendly(ent) then
                            if (ent == LocalPlayer()) then
                                surface.SetDrawColor(64,255,64,160)
                                surface.DrawLine(scrPos.x-16,scrPos.y-16,scrPos.x+16,scrPos.y+16)
                                surface.DrawLine(scrPos.x-16,scrPos.y+16,scrPos.x+16,scrPos.y-16)
                            else
                                surface.SetDrawColor(64,64,255,160)
                                surface.DrawLine(scrPos.x-16,scrPos.y,scrPos.x+16,scrPos.y)
                                surface.DrawLine(scrPos.x,scrPos.y+16,scrPos.x,scrPos.y-16)
                            end
                        else
                            surface.SetDrawColor(255,64,64,160)
                        end
                        surface.DrawOutlinedRect(scrPos.x-16, scrPos.y-16,32,32)
                    end
                end
		surface.SetTextColor(0,255,0,255)
		surface.SetTextPos(24,108)
		surface.SetFont("CloseCaption_Bold")
		surface.DrawText("You are green")
		surface.SetTextPos(24,132)
		surface.SetTextColor(0,0,255,255)
		surface.SetFont("CloseCaption_Bold")
		surface.DrawText("Your teammates are blue")
		surface.SetTextColor(255,0,0,255)
		surface.SetTextPos(24,156)
		surface.SetFont("CloseCaption_Bold")
		surface.DrawText("Your enemies are red")
            end
        end
    end
    
    local GlowMat = CreateMaterial("AsmLedGlow","UnlitGeneric",{
        ["$basetexture"] = "sprites/light_glow01",
        ["$vertexcolor"] = "1",
        ["$vertexalpha"] = "1",
        ["$additive"] = "1",
    })
    
    function SWEP:GetViewModelPosition(pos,ang)
        if self:GetModel() == "models/weapons/v_toolgun.mdl" then
            local offset = Vector(-6,5.6,0)
            offset:Rotate(ang)
            pos = pos + offset
        end
        return pos,ang
    end

    local function drawAxis(debugC, rot)
        local xa = Vector(20,0,0)
        local ya = Vector(0,20,0)
        local za = Vector(0,0,20)
        xa:Rotate(rot)
        ya:Rotate(rot)
        za:Rotate(rot)
        local x = debugC + xa
        local y = debugC + ya
        local z = debugC + za
        --print(debugC)
        --print(rot)
        render.DrawLine(debugC, x, Color(255,0,0))
        render.DrawLine(debugC, y, Color(0,255,0))
        render.DrawLine(debugC, z, Color(0,0,255))
    end

    local function drawOffset(debugC, offset, rot)
        local offcop = Vector(offset.x, offset.y, offset.z)
        offcop:Rotate(rot)
        local l = debugC + offcop
        render.DrawLine(debugC, l, Color(255,0,0))
    end

    function SWEP:ViewModelDrawn()
        --[[if (self.Status ~= 3) && (self.Status ~= 4) then
            --drawAxis(self.Owner:GetPos() + Vector(0,0,50) + self.Owner:GetAimVector()*70, self.Owner:GetAngles())
            drawAxis(Vector(48,-172,-12250), Angle(0,0,0))
            drawAxis(Vector(48,-172 + 2*30,-12250), Angle(90,0,0))
            drawAxis(Vector(48,-172 + 4*30,-12250), Angle(0,90,0))
            drawAxis(Vector(48,-172 + 6*30,-12250), Angle(0,0,90))
            
            local ent = self.Owner:GetViewModel()
            local pos,ang,offset,res,height,z
            if ent:GetModel() == "models/weapons/v_c4.mdl" then
                pos,ang = ent:GetBonePosition(ent:LookupBone("v_weapon.c4"))
                --pos = ent:GetPos()
                LocalPlayer():ChatPrint(tostring(pos) .. " " .. tostring(ent:GetPos() + Vector(0,0,0.46)))
                if self.Status == 1 then
                    print("here")
                    --offset = Vector(-1.6,2.8,-0.25)
                    --offset:Rotate(ang)
                    -- The lamp
                    --render.SetMaterial(GlowMat)
                    --render.DrawQuadEasy(pos+offset,ang:Right() * -1,1.5,1.5,Color(255,128,128,255))
                    offset = Vector(-2.5,4.6,2.0)
                else
                    offset = Vector(-1.58,4.6,2.7)
                end
                --local ang = self.Owner:GetAngles()
                local ang = EyeAngles()
                --local v = EyeAngles()
                --local y = Vector(ang.pitch - v.pitch, ang.yaw - v.yaw, ang.roll - v.roll)
                --LocalPlayer():ChatPrint(tostring(ang) .. " " .. tostring(y))
                
                --offset = Vector(0,0,2.7)
                drawOffset(pos, Vector(0,0,2.6), Angle(0,0,0))
                drawOffset(pos, offset, ang)
                local pp = self.Owner:GetPos()
                --drawOffset(Vector(48,-172 - 2*30,-12230), Vector(0,0,-30), Angle(0,0,0))
                --local a = ang:Forward()
                --local b = LocalPlayer():GetAimVector()
                --local normal = Vector(a.y*b.z-a.z*b.y,a.z*b.x-a.x*b.z,a.x*b.y-a.y*b.x)
                --render.DrawLine(pos, pos+offset)
                --render.DrawLine(pos, pos+LocalPlayer():GetAimVector(), Color(0,0,255))
                --render.DrawLine(pos, pos+normal, Color(255,0,0))
                offset:Rotate(ang)
                --LocalPlayer():ChatPrint(tostring(pos - pp) .. " " .. tostring(pos + offset - pp))
                --render.DrawLine(pos, pos+ang:Forward(), Color(255,255,0))
                --render.DrawLine(pos, pos+ang:Up(), Color(0,255,0))

                --render.DrawLine(pos, pos+ang:Right(), Color(0,255,255))
                --render.DrawLine(pos, pos+offset, Color(255,0,0))
                --ang:RotateAroundAxis(ang:Forward(),-90)
                --notification.AddLegacy(tostring(offset) .. " " .. tostring(ang),3,1) 
                --LocalPlayer():ChatPrint(tostring(offset) .. " " .. tostring(ang))
                --ang:RotateAroundAxis(ang:Up(),180)
                --render.DrawLine(pos, pos+ang:Forward(), Color(255,255,0))
                res = 0.03
                height = 53
                z = 16
            else
                return --too lazy, this was throwing errors for a few seconds
            end
            pos = pos + offset
            drawOffset(pos, Vector(0,0,-30), Angle(0,0,0))
            cam.Start3D2D(pos,Angle(ang.pitch,ang.yaw,-ang.roll + 90),res)
            --cam.Start3D2D(Vector(48,-172 - 2*30,-12230),Angle(0,ang.yaw,-ang.roll + 90),res)
                surface.SetDrawColor(4,32,4,255)
                surface.DrawRect(0,0,96,height)
                if self.Status == -1 then
                    draw.SimpleText("Missiles","AsmScreenFont",48,z,Color(80,192,64,255),TEXT_ALIGN_CENTER,TEXT_ALIGN_CENTER)
                    draw.SimpleText("unavailable","AsmScreenFont",48,z+16,Color(80,192,64,255),TEXT_ALIGN_CENTER,TEXT_ALIGN_CENTER)
                elseif self.Status == 0 then
                    draw.SimpleText("Waiting for","AsmScreenFont",48,z,Color(80,192,64,255),TEXT_ALIGN_CENTER,TEXT_ALIGN_CENTER)
                    draw.SimpleText("target...","AsmScreenFont",48,z+16,Color(80,192,64,255),TEXT_ALIGN_CENTER,TEXT_ALIGN_CENTER)
                elseif self.Status == 1 then
                    draw.SimpleText("Requesting...","AsmScreenFont",48,z,Color(80,192,64,255),TEXT_ALIGN_CENTER,TEXT_ALIGN_CENTER)
                    surface.SetDrawColor(80,192,64,255)
                    surface.DrawOutlinedRect(11,z+15,74,10)
                    surface.SetDrawColor(112,224,96,255)
                    surface.DrawRect(12,z+16,72*(1-((self.Load-CurTime())/1.75)),8)
                else
                    draw.SimpleText("Inbound","AsmScreenFont",48,z+8,Color(80,192,64,255),TEXT_ALIGN_CENTER,TEXT_ALIGN_CENTER)
                end
                --surface.SetTexture(texScreenOverlay)
                --surface.DrawTexturedRectUV(0,0,96,height,96,height)
            cam.End3D2D()--the rotation of the text is broken and i quite frankly couldnt care less about the text, so there it goes i guess
        end]]
    end
    
    function SWEP:FreezeMovement()
        if (self.Status > 0) && (self.Status ~= 5) then
            return true
        end
        return false
    end
    
    function SWEP:HUDShouldDraw(el)
        if(self.Status > 2 && self.Status < 7) then
            if (el=="CHudGMod") then return true end
            return false
        end
        return true
    end

    -- Explosion effect

    local EFFECT = {}
    function EFFECT:Init(data)
        self.Pos = data:GetOrigin()
        self.Radius = data:GetRadius()

        sound.Play("ambient/explosions/explode_4.wav", self.Pos, 100, 140, 1)
        sound.Play("npc/env_headcrabcanister/explosion.wav", self.Pos, 100, 140, 1)

        local em = ParticleEmitter(self.Pos)
        for n=1,180 do
            local wave = em:Add("particle/particle_noisesphere",self.Pos)
                wave:SetVelocity(Vector(math.sin(math.rad(n*2)),math.cos(math.rad(n*2)),0)*self.Radius*3)
                wave:SetAirResistance(128)
                wave:SetLifeTime(math.random(0.2,0.4))
                wave:SetDieTime(math.random(3,4))
                wave:SetStartSize(64)
                wave:SetEndSize(48)
                wave:SetColor(160,160,160)
                wave:SetRollDelta(math.random(-1,1))
            local fire = em:Add("effects/fire_cloud1",self.Pos+VectorRand()*self.Radius/2)
                fire:SetVelocity(Vector(math.random(-8,8),math.random(-8,8),math.random(8,16)):GetNormal()*math.random(128,1024))
                fire:SetAirResistance(256)
                fire:SetLifeTime(math.random(0.2,0.4))
                fire:SetDieTime(math.random(2,3))
                fire:SetStartSize(80)
                fire:SetEndSize(32)
                fire:SetColor(160,64,64,192)
                fire:SetRollDelta(math.random(-1,1))
        end
        for n=1,16 do
            local smoke = em:Add("particle/particle_noisesphere", self.Pos+48*VectorRand()*n)
                smoke:SetVelocity(VectorRand()*math.Rand(32,96))
                smoke:SetAirResistance(32)
                smoke:SetDieTime(8)
                smoke:SetStartSize((32-n)*2*math.Rand(8,16))
                smoke:SetEndSize((32-n)*math.Rand(8,16))
                smoke:SetColor(160,160,160)
                smoke:SetStartAlpha(math.Rand(224,255))
                smoke:SetEndAlpha(0)
                smoke:SetRollDelta(math.random(-1,1))
        end
        em:Finish()
    end

    function EFFECT:Think() return false end
    function EFFECT:Render() end

    effects.Register(EFFECT,"ASM-Explosion")
end
