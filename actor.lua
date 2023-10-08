local Unlocker, awful, rotation = ...
local disc = rotation.priest.disc
local current_mode = nil

if awful.player.class2 ~= "PRIEST" then
    return
end

awful.print("|cffFFFFFFDreams{ |cff00B5FFScripts |cffFFFFFF} - Disc Loaded!")
awful.print("|cffFFFFFFDreams{ |cff00B5FFScripts |cffFFFFFF} - Version: 2.0.0")

disc:Init(function()
    if rotation.settings.mode ~= current_mode then
        current_mode = rotation.settings.mode
        if rotation.settings.mode == "PvE" then
            awful.print("|cffFFFFFFDreams{ |cff00B5FFScripts |cffFFFFFF} - Roation Mode: PvE")
        elseif rotation.settings.mode == "PvP" then
            awful.print("|cffFFFFFFDreams{ |cff00B5FFScripts |cffFFFFFF} - Roation Mode: PvP")
        end
    end

    if rotation.settings.mode == "PvE" then
        rotation.apl_pve()
    elseif rotation.settings.mode == "PvP" then
        rotation.apl_pvp()
    end
end, 0.05)
