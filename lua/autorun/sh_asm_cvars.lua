if SERVER then
	AddCSLuaFile()
	if file.Exists("scripts/sh_convarutil.lua", "LUA") then
		AddCSLuaFile("scripts/sh_convarutil.lua")
		print("[INFO][Air-to-Surface Missile] Using the utility plugin to handle convars instead of the local version")
	else
		AddCSLuaFile("scripts/sh_convarutil_local.lua")
		print("[INFO][Air-to-Surface Missile] Using the local version to handle convars instead of the utility plugin")
	end
end

if file.Exists("scripts/sh_convarutil.lua", "LUA") then
	include("scripts/sh_convarutil.lua")
else
	include("scripts/sh_convarutil_local.lua")
end

-- Must run before hook.Add
local cg = ConvarGroup("ASM", "Air-to-Surface Missile")
Convar(cg, false, "ttt_asm_shift_speed_modifier", 2, {FCVAR_ARCHIVE, FCVAR_NOTIFY, FCVAR_REPLICATED}, "Movement speed multiplier during the aiming sequence", "float", 0.01, 8, 2)
Convar(cg, false, "ttt_asm_alt_speed_modifier", 0.25, {FCVAR_ARCHIVE, FCVAR_NOTIFY, FCVAR_REPLICATED}, "Movement speed multiplier during the aiming sequence", "float", 0.01, 8, 2)
Convar(cg, false, "ttt_asm_mouse_speed_modifier", 3, {FCVAR_ARCHIVE, FCVAR_NOTIFY, FCVAR_REPLICATED}, "Speed multiplier applied to the mouse movement", "float", 0.01, 12, 2)
Convar(cg, false, "ttt_asm_aim_time", 15, { FCVAR_ARCHIVE, FCVAR_NOTIFY, FCVAR_REPLICATED }, "How much time do you have to aim the missile", "float", 1, 300, 1)
Convar(cg, false, "ttt_asm_missile_blast_damage", 110, {FCVAR_ARCHIVE, FCVAR_NOTIFY, FCVAR_REPLICATED}, "Damage of the missile blast", "int", 1, 3000)
Convar(cg, false, "ttt_asm_missile_blast_radius", 384, {FCVAR_ARCHIVE, FCVAR_NOTIFY, FCVAR_REPLICATED}, "Radius of the missile blast", "int", 100, 5000)
Convar(cg, false, "ttt_asm_allow_abort", 1, {FCVAR_ARCHIVE, FCVAR_NOTIFY, FCVAR_REPLICATED}, "Allows you to abort the aiming sequence", "bool")
Convar(cg, false, "ttt_asm_allow_abort_mid_flight", 0, {FCVAR_ARCHIVE, FCVAR_NOTIFY, FCVAR_REPLICATED}, "Allows you to move the camera after the missile was launched (At the end of the aiming sequence)", "bool")
Convar(cg, false, "ttt_asm_allow_camera_move_mid_flight", 1, {FCVAR_ARCHIVE, FCVAR_NOTIFY, FCVAR_REPLICATED}, "Whether or not the camera can still be moved after the missile was launched", "bool")
Convar(cg, false, "ttt_asm_show_colleagues", 1, { FCVAR_ARCHIVE, FCVAR_NOTIFY, FCVAR_REPLICATED }, "Makes your colleagues blue in the aiming sequence, so you don't accidentally hit them", "bool")
Convar(cg, false, "ttt_asm_damage_owner", 1, { FCVAR_ARCHIVE, FCVAR_NOTIFY, FCVAR_REPLICATED }, "Should the missile damage its owner", "bool")
Convar(cg, false, "ttt_asm_friendlyfire", 1, { FCVAR_ARCHIVE, FCVAR_NOTIFY, FCVAR_REPLICATED }, "Should the missile damage the owners teammates", "bool")
Convar(cg, false, "ttt_asm_show_debug", 0, { FCVAR_ARCHIVE, FCVAR_NOTIFY, FCVAR_REPLICATED }, "Show debug information, including the missile blast radius on impact", "bool")
--