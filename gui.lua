local Unlocker, awful, rotation = ...
local player = awful.player

if player.class2 ~= "PRIEST" then
    return
end

local blue = { 0, 181, 255, 1 }
local white = { 255, 255, 255, 1 }
local background = { 0, 13, 49, 1 }

local gui, settings, cmd = awful.UI:New('ds', {
    title = "Dreams{ |cff00B5FFScripts |cffFFFFFF }",
    show = true,
    width = 345,
    height = 220,
    scale = 1,
    colors = {
        title = white,
        primary = white,
        accent = blue,
        background = background,
    }
})

rotation.settings = settings

local status_frame = gui:StatusFrame({
    colors = {
        background = { 0, 0, 0, 0 },
        enabled = { 30, 240, 255, 1 },
    },
    maxWidth = 600,
    padding = 12,
})

status_frame:Button({
    spellId = 48066,
    var = "use_power_word_shield_pre_shield",
    text = "Pre Shield",
    size = 30
})

status_frame:Button({
    spellId = 48071,
    var = "use_flash_heal",
    text = "Flash Heal",
    size = 30
})

status_frame:Button({
    spellId = 988,
    var = "use_dispel_magic",
    text = "Dispel Magic",
    size = 30
})

status_frame:Button({
    spellId = 48171,
    var = "use_ooc",
    text = "Ooc",
    size = 30
})

local welcome = gui:Tab(awful.textureEscape(48161, 16) .. " Welcome")
welcome:Text({
    text = "|cff00B5FFInformation",
    header = true,
    paddingBottom = 10,
})

welcome:Text({
    text = "Set up Macros for your spells you want too use manually Divine Hymn, Mana Hymn etc.",
    paddingBottom = 10,
})

welcome:Text({
    text = "(See Macros tab for example)",
    paddingBottom = 10,
})

welcome:Text({
    text = "|cff00B5FFDiscord",
    header = true,
    paddingBottom = 10,
})

welcome:Text({
    text = "If you have any suggestions or questions, feel free to join the Discord and let me know!",
    paddingBottom = 10,
})

welcome:Text({
    text = "|cffFF0099discord.gg/axWkr4sFMJ",
})

local mode = gui:Tab(awful.textureEscape(48066, 16) .. " Rotation Mode")
mode:Text({
    text = "|cff00B5FFRotation Mode",
    header = true,
    paddingBottom = 10,
})

mode:Dropdown({
    var = "mode",
    tooltip = "Select the Rotation Mode.",
    options = {
        { label = awful.textureEscape(48066, 16) .. " PvE", value = "PvE", tooltip = "Use PvE Rotation" },
        { label = awful.textureEscape(48158, 16) .. " PvP", value = "PvP", tooltip = "Use PvP Rotation" },
    },
    placeholder = "None",
    header = "Select Rotation Mode",
})

local spells = gui:Tab(awful.textureEscape(53007, 16) .. " Spell Settings")
spells:Text({
    text = "|cff00B5FFSpell Settings (PvE)",
    header = true,
    paddingBottom = 10,
})

spells:Slider({
    text = awful.textureEscape(33206) .. "  Pain Supression (Tank)",
    var = "pain_supression_hp",
    min = 0,
    max = 100,
    default = 40,
    valueType = "%",
    tooltip = "Use Pain Supression if Tank has %HP or less"
})

spells:Slider({
    text = awful.textureEscape(48066) .. "  Power Word: Shield (Safe)",
    var = "power_word_shield_safe_hp",
    min = 0,
    max = 100,
    default = 60,
    valueType = "%",
    tooltip = "Use Power Word: Shield if any unit has %HP or less"
})

spells:Slider({
    text = awful.textureEscape(48066) .. "  Power Word: Shield (Tank)",
    var = "power_word_shield_tank_safe_hp",
    min = 0,
    max = 100,
    default = 60,
    valueType = "%",
    tooltip = "Use Power Word: Shield if Tank has %HP or less (Turn off or set HP low for better Rupture Management)"
})

spells:Slider({
    text = awful.textureEscape(53007) .. "  Pennance (Tank)",
    var = "penance_tank_hp",
    min = 0,
    max = 100,
    default = 80,
    valueType = "%",
    tooltip = "Use Pennance if Tank has %HP or less"
})

spells:Slider({
    text = awful.textureEscape(53007) .. "  Pennance",
    var = "penance_hp",
    min = 0,
    max = 100,
    default = 80,
    valueType = "%",
    tooltip = "Use Pennance if any unit has %HP or less"
})

spells:Slider({
    text = awful.textureEscape(48071) .. "  Flash Heal",
    var = "flash_heal_hp",
    min = 0,
    max = 100,
    default = 80,
    valueType = "%",
    tooltip = "Use Flash Heal if any unit has %HP or less"
})

spells:Slider({
    text = awful.textureEscape(48120) .. "  Binding Heal",
    var = "binding_heal_hp",
    min = 0,
    max = 100,
    default = 60,
    valueType = "%",
    tooltip = "Use Binding Heal if you and any other unit has %HP or less"
})

spells:Slider({
    text = awful.textureEscape(48173) .. "  Desperate Prayer",
    var = "desperate_prayer_hp",
    min = 0,
    max = 100,
    default = 40,
    valueType = "%",
    tooltip = "Use Desperate Prayer if you have %HP or less"
})

spells:Slider({
    text = awful.textureEscape(34433) .. "  Shadowfiend",
    var = "shadowfiend_mp",
    min = 0,
    max = 100,
    default = 20,
    valueType = "%",
    tooltip = "Use Shadowfiend on enemy target if you have %MP or less"
})

local names = {}
awful.fullGroup.loop(function(friend)
    table.insert(names, friend.name)
end)

local options = {
    { label = "None", value = "None", tooltip = "Casting Power Infusion on selected unit" },
}

if names then
    for i, name in ipairs(names) do
        table.insert(options, { label = name, value = name, tooltip = "Casting Power Infusion on selected unit" })
    end
end

spells:Text({
    text = awful.textureEscape(10060) .. "  Power Infusion (Unit)",
})

spells:Dropdown({
    var = "power_infusion_unit",
    tooltip = "Casting Power Infusion on unit (Reload if you dont see any names in your Group)",
    options = options,
    placeholder = "Select your unit",
})

spells:Dropdown({
    var = "power_infusion_conditions",
    multi = true,
    tooltip = "Choose the conditions under which to cast Power Infusion",
    options = {
        { label = "Execute Phase",   value = "Execute Phase" },
        { label = "After Bloodlust", value = "After Bloodlust" },
        { label = "At Boss Pull",    value = "At Boss Pull" },
        { label = "On CD",           value = "On CD", },
    },
    placeholder = "Select your conditions",
    header = awful.textureEscape(10060) .. " Power Infusion (Conditions)",
    default = { "Execute", "Bloodlust", "Pull" }
})

spells:Text({
    text = "|cff00B5FFSpell Settings (PvP)",
    header = true,
    paddingBottom = 10,
})

spells:Text({
    text = "|cff00B5FFNo Spell Settings for PvP",
    paddingBottom = 10,
})

local toggles = gui:Tab(awful.textureEscape(6064, 16) .. " Toggles")
toggles:Text({
    text = "|cff00B5FFToggles (PvE)",
    header = true,
    paddingBottom = 10,
})

toggles:Checkbox({
    text = "Use Inner Fire",
    var = "use_inner_fire",
    tooltip = "Use Inner Fire if not active",
    default = true
})

toggles:Checkbox({
    text = "Use Shadowfiend",
    var = "use_shadowfiend",
    tooltip = "Use Shadowfiend on enemy target (you need to have a target)",
    default = true
})

toggles:Checkbox({
    text = "Use Pain Supression",
    var = "use_pain_supression_tank",
    tooltip = "Use Pain Supression on Tank",
    default = true
})

toggles:Checkbox({
    text = "Use Power Word: Shield (Safe)",
    var = "use_power_word_shield",
    tooltip = "Use Power Word: Shield on any unit with Low HP",
    default = true
})

toggles:Checkbox({
    text = "Use Power Word: Shield (Tank)",
    var = "use_power_word_shield_tank",
    tooltip = "Use Power Word: Shield on Tank (Turn off or set HP too Low for better Rupture Management)",
    default = true
})

toggles:Checkbox({
    text = "Use Power Word: Shield (Pre Shield)",
    var = "use_power_word_shield_pre_shield",
    tooltip =
    "Use Power Word: Shield on any unit which dosent have Weakened Soul or Power Word: Shield (Pre Shield / Mass Shielding)",
    default = true
})

toggles:Checkbox({
    text = "Use Prayer of Mending (Tank)",
    var = "use_prayer_of_mending_tank",
    tooltip = "Use Prayer of Mending on Tank",
    default = true
})

toggles:Checkbox({
    text = "Use Pennance (Tank)",
    var = "use_penance_tank",
    tooltip = "Use Pennance on Tank",
    default = true
})

toggles:Checkbox({
    text = "Use Pennance",
    var = "use_penance",
    tooltip = "Use Pennance",
    default = true
})

toggles:Checkbox({
    text = "Use Renew (Tank)",
    var = "use_renew_tank",
    tooltip = "Use Renew on Tank",
    default = true
})

toggles:Checkbox({
    text = "Use Flash Heal",
    var = "use_flash_heal",
    tooltip = "Use Flash Heal",
    default = true
})

toggles:Checkbox({
    text = "Use Binding Heal",
    var = "use_binding_heal",
    tooltip = "Use Binding Heal",
    default = true
})

toggles:Checkbox({
    text = "Use Desperate Prayer",
    var = "use_desperate_prayer",
    tooltip = "Use Desperate Prayer",
    default = true
})

toggles:Checkbox({
    text = "Use Dispel Magic",
    var = "use_dispel_magic",
    tooltip = "Use Dispel Magic on unit that has a Magic debuff",
    default = true
})

toggles:Checkbox({
    text = "Use Cure Disease",
    var = "use_cure_disease",
    tooltip = "Use Cure Disease on unit that has a Disease",
    default = true
})

toggles:Checkbox({
    text = "Use Damage Spells (Gamma Dungeons)",
    var = "use_damage_gamma",
    tooltip = "Use Damage Spells in Gamma Dungeons on lowest unit if you have the Confessor's Wrath Buff active",
    default = true
})

toggles:Text({
    text = "|cff00B5FFToggles (PvP)",
    header = true,
    paddingBottom = 10,
})

toggles:Text({
    text = "|cff00B5FFNo Toggles for PvP",
    paddingBottom = 10,
})

local macros = gui:Tab(awful.textureEscape(1706, 16) .. " Macros")
macros:Text({
    text = "|cff00B5FFMacros",
    header = true,
    paddingBottom = 10,
})

macros:Text({
    text = awful.textureEscape(64843) .. "  Divine Hymn",
    header = true,
    paddingBottom = 10,
})

macros:Text({ text = "#showtooltip Divine Hymn" })
macros:Text({ text = "/awful cast Inner Focus" })
macros:Text({ text = "/awful cast Divine Hymn", paddingBottom = 10, })

macros:Text({
    text = awful.textureEscape(64901) .. "  Mana Hymn",
    header = true,
    paddingBottom = 10,
})

macros:Text({ text = "#showtooltip Mana Hymn" })
macros:Text({ text = "/awful cast Mana Hymn" })
