local Unlocker, awful, rotation = ...
local disc = rotation.priest.disc
local Spell = awful.Spell
local player, target, focus = awful.player, awful.target, awful.focus

if player.class2 ~= "PRIEST" then
    return
end

awful.Populate({
    fear_ward            = Spell(6346),
    desperate_prayer     = Spell(48173, { ignoreMoving = true, beneficial = true }),
    power_word_shield    = Spell(48066, { ignoreUsable = true, beneficial = true }),
    prayer_of_mending    = Spell(48113, { beneficial = true }),
    penance              = Spell(53007, { beneficial = true }),
    binding_heal         = Spell(48120, { beneficial = true }),
    flash_heal           = Spell(48071, { beneficial = true }),
    renew                = Spell(48068, { beneficial = true }),
    shadowfiend          = Spell(34433, { beneficial = true }),
    holy_fire            = Spell(48135, { damage = "magic" }),
    mind_blast           = Spell(48127, { damage = "magic" }),
    smite                = Spell(48123, { damage = "magic" }),
    holy_nova            = Spell(48078, { radius = 10, ignoreCasting = true, ignoreChanneling = true }),
    pain_suppression     = Spell(33206, { ignoreControl = true, beneficial = true }),
    shackle_undead       = Spell(10955, { ignoreFacing = true }),
    psychic_scream       = Spell(10890, { ignoreFacing = true, cc = "fear", effect = "magic" }),
    mass_dispel          = Spell(32375, { ignoreFacing = true, radius = 15 }),
    dispel_magic         = Spell(988, { beneficial = true }),
    inner_fire           = Spell(48168, { beneficial = true }),
    auto_attack          = Spell(6603, { ignoreChanneling = true, ignoreCasting = true }),
    shadow_word_death    = Spell(48158, { ignoreFacing = true, ignoreCasting = true, ignoreChanneling = true }),
    devouring_plague     = Spell(48300, { ignoreFacing = true, damage = "magic" }),
    shadow_word_pain     = Spell(48125, { ignoreFacing = true, damage = "magic" }),
    abolish_disease      = Spell(552, { ignoreFacing = true }),
    power_word_fortitude = Spell(48161, { beneficial = true }),
    power_infusion       = Spell(10060, { beneficial = true }),
}, disc, getfenv(1))

local function find_tremor_totem()
    if awful.fighting("SHAMAN") then
        return awful.totems.find(function(obj)
            return obj.id == 5913
        end)
    end
    return nil
end

local tremor = find_tremor_totem()

-- Draw
local Draw = awful.Draw
Draw(function(draw)
    local fx, fy, fz = focus.position()
    local px, py, pz = player.position()

    if focus.exists and not focus.buff(6346) and not tremor then
        draw:SetColor(204, 153, 255, 100) -- ready
        draw:Circle(px, py, pz, 8)

        draw:SetColor(102, 255, 102, 100) -- ready
        draw:FilledCircle(fx, fy, fz, 1)
    else
        draw:SetColor(255, 51, 51, 100) -- not ready
        draw:FilledCircle(fx, fy, fz, 1)
    end
end)

local spell_stop_casting = awful.unlock("SpellStopCasting")

local preemptive = {
    ["Blind"] = true,
    ["Gouge"] = true,
    ["Repentance"] = true,
    ["Scatter Shot"] = true,
    ["Polymorph"] = true,
    ["Seduction"] = true,
    ["Freezing Arrow"] = true
}

awful.onEvent(function(info, event, source, dest)
    if event == "SPELL_CAST_SUCCESS" then
        if not source.enemy then
            return
        end

        local _, spell_name = select(12, unpack(info))
        if preemptive[spell_name] then
            spell_stop_casting()
            shadow_word_death:Cast(source)
            return
        end
    end
end)

local on_cast = {
    ["Polymorph"] = true,
    ["Seduction"] = true,
    ["Fear"] = true,
}

-- Shadow Word: Death
shadow_word_death:Callback("polymorph", function(spell)
    awful.enemies.loop(function(enemy)
        if on_cast[enemy.casting] and enemy.castPct >= 60 then
            spell_stop_casting()
            if spell:Cast(enemy) then
                awful.alert(spell.name .. "SWD: Polymorph", spell.id)
                return
            end
        end
    end)
end)

shadow_word_death:Callback("seduction", function(spell)
    awful.enemyPets.loop(function(pet)
        if on_cast[pet.casting] and pet.castPct >= 60 then
            spell_stop_casting()
            if spell:Cast(pet) then
                awful.alert(spell.name .. "SWD: Seduction", spell.id)
                return
            end
        end
    end)
end)

shadow_word_death:Callback("burst", function(spell)
    awful.enemies.loop(function(enemy)
        if enemy.hp < 20 and player.hp > 60 then
            if spell:Cast(enemy) then
                awful.alert(spell.name .. " (Burst)", spell.id)
                return
            end
        end
    end)
end)

local function check_for_fear_debuff(obj)
    return obj.debuff(10890) and not obj.isPet
end

shadow_word_death:Callback("tremor", function(spell)
    awful.totems.stomp(function(totem, uptime)
        if uptime < 0.3 then
            return
        end
        if totem.id == 5913 and awful.enemies.around(player, 30, check_for_fear_debuff) > 0 then
            if spell:Cast(totem) then
                SpellStopCasting()
                awful.alert("Destroying " .. totem.name, spell.id)
                return
            end
        end
    end)
end)

-- Auto Attack
auto_attack:Callback("totems", function(spell)
    awful.totems.stomp(function(totem, uptime)
        if uptime < 0.3 then
            return
        end

        if totem.id == 5913 and totem.distanceLiteral < 5 then
            if not spell.current then
                if totem.setTarget() then
                    awful.call("StartAttack")
                    if spell:Cast(totem) then
                        awful.alert("Destroying " .. totem.name, spell.id)
                        return
                    end
                end
            end
        end
    end)
end)

-- Devouring Plague
devouring_plague:Callback(function(spell)
    awful.enemies.loop(function(enemy)
        if enemy.hp < 60 and not enemy.debuff(48300) then
            if spell:Cast(enemy) then
                awful.alert(spell.name, spell.id)
                return
            end
        end
    end)
end)

devouring_plague:Callback("burst", function(spell)
    if not target.exists or not target.enemy or target.dead then
        return
    end

    if target.distanceLiteral < spell.range and not target.debuff(48300) then
        if spell:Cast(target) then
            awful.alert(spell.name, spell.id)
            return
        end
    end
end)

-- Shadow Word Pain
shadow_word_pain:Callback(function(spell)
    awful.enemies.loop(function(enemy)
        if enemy.hp < 60 and not enemy.debuff(48125) then
            if spell:Cast(enemy) then
                awful.alert(spell.name, spell.id)
                return
            end
        end
    end)
end)

shadow_word_pain:Callback("burst", function(spell)
    if not target.exists or not target.enemy or target.dead then
        return
    end

    if target.distanceLiteral < spell.range and not target.debuff(48125) then
        if spell:Cast(target) then
            awful.alert(spell.name, spell.id)
            return
        end
    end
end)

-- Desperate Prayer
desperate_prayer:Callback(function(spell)
    if player.hp < 40 then
        if spell:Cast(player) then
            awful.alert(spell.name, spell.id)
            return
        end
    end
end)

-- Power Word: Shield
power_word_shield:Callback(function(spell)
    if awful.prep then
        return
    end

    awful.fullGroup.loop(function(friend)
        if friend.debuff(6788) or friend.buff(48066) then
            return
        end

        if friend.hp < 95 then
            if spell:Cast(friend) then
                awful.alert(spell.name, spell.id)
                return
            end
        end
    end)
end)

-- Prayer of Mending
prayer_of_mending:Callback(function(spell)
    if awful.prep then
        return
    end

    print("Debug: PvP")
    awful.fullGroup.loop(function(friend)
        if friend.buff(41635) then
            return
        end

        if friend.hp < 90 then
            if spell:Cast(friend) then
                awful.alert(spell.name, spell.id)
                return
            end
        end
    end)
end)

-- Penance
penance:Callback(function(spell)
    if awful.prep then
        return
    end

    awful.fullGroup.loop(function(friend)
        if player.moving then
            return
        end

        if friend.hp < 85 then
            if spell:Cast(friend) then
                awful.alert(spell.name, spell.id)
                return
            end
        end
    end)
end)

penance:Callback("burst", function(spell)
    if not target.exists or not target.enemy or target.dead then
        return
    end

    if target.distance < spell.range and awful.fullGroup.lowest.hp > 60 then
        if spell:Cast(target) then
            awful.alert(spell.name, spell.id)
            return
        end
    end
end)

-- Binding Heal
binding_heal:Callback(function(spell)
    if awful.prep then
        return
    end

    awful.friends.loop(function(friend)
        if player.moving then
            return
        end

        if friend.hp < 80 and player.hp < 80 then
            if spell:Cast(friend) then
                awful.alert(spell.name, spell.id)
                return
            end
        end
    end)
end)

-- Flash Heal
flash_heal:Callback(function(spell)
    if awful.prep then
        return
    end

    awful.fullGroup.loop(function(friend)
        if player.moving then
            return
        end

        if friend.hp < 80 then
            if spell:Cast(friend) then
                awful.alert(spell.name, spell.id)
                return
            end
        end
    end)
end)

-- Renew
renew:Callback(function(spell)
    if awful.prep then
        return
    end

    awful.fullGroup.loop(function(friend)
        if not friend.buff("Renew") and friend.hp > 20 and friend.hp < 90 then
            if spell:Cast(friend) then
                awful.alert(spell.name, spell.id)
                return
            end
        end
    end)
end)

-- Shadowfiend
shadowfiend:Callback(function(spell)
    awful.enemies.loop(function(enemy)
        if player.manaPct < 40 or enemy.hp < 40 then
            if spell:Cast(enemy) then
                awful.alert(spell.name, spell.id)
                return
            end
        end
    end)
end)

-- Holy Fire
holy_fire:Callback(function(spell)
    awful.enemies.loop(function(enemy)
        if enemy.hp < 80 and awful.fullGroup.lowest.hp > 60 then
            if spell:Cast(enemy) then
                awful.alert(spell.name, spell.id)
                return
            end
        end
    end)
end)

holy_fire:Callback("burst", function(spell)
    if not target.exists or not target.enemy or target.dead then
        return
    end

    if target.distance < spell.range then
        if spell:Cast(target) then
            awful.alert(spell.name, spell.id)
            return
        end
    end
end)

-- Mind Blast
mind_blast:Callback(function(spell)
    awful.enemies.loop(function(enemy)
        if enemy.hp < 80 and awful.fullGroup.lowest.hp > 60 then
            if spell:Cast(enemy) then
                awful.alert(spell.name, spell.id)
                return
            end
        end
    end)
end)

mind_blast:Callback("burst", function(spell)
    if not target.exists or not target.enemy or target.dead then
        return
    end

    if target.distance < spell.range then
        if spell:Cast(target) then
            awful.alert(spell.name, spell.id)
            return
        end
    end
end)

-- Smite
smite:Callback(function(spell)
    awful.enemies.loop(function(enemy)
        if enemy.hp < 80 and awful.fullGroup.lowest.hp > 80 then
            if spell:Cast(enemy) then
                awful.alert(spell.name, spell.id)
                return
            end
        end
    end)
end)

-- Holy Nova
holy_nova:Callback("snakes", function(spell)
    if player.debuff(30981) then
        spell:Cast()
        return
    end
end)

holy_nova:Callback("moving", function(spell)
    if player.moving and player.hp < 40 then
        if spell:Cast() then
            awful.alert(spell.name, spell.id)
            return
        end
    end
end)


holy_nova:Callback("stealth", function(spell)
    awful.enemies.loop(function(enemy)
        if enemy.buff(51713) then
            return
        end

        if enemy.stealth and enemy.distance <= 10 then
            SpellStopCasting()
            if spell:Cast() then
                awful.alert(spell.name, spell.id)
                return
            end
        end
    end)
end)

-- Pain Suppression
pain_suppression:Callback(function(spell)
    awful.fullGroup.loop(function(friend)
        if friend.hp <= 40 then
            if spell:Cast(friend) then
                awful.alert(spell.name, spell.id)
                return
            end
        end
    end)
end)

-- Shackle Undead
shackle_undead:Callback("gargoyle", function(spell)
    awful.enemyPets.loop(function(enemy)
        if enemy.id == 27829 and not enemy.debuff(10955) then
            if spell:Cast(enemy) then
                awful.alert(spell.name, spell.id)
                return
            end
        end
    end)
end)

shackle_undead:Callback("lich", function(spell)
    awful.enemies.loop(function(enemy)
        if enemy.buff(49039) and not enemy.debuff(10955) then
            if spell:Cast(enemy) then
                awful.alert(spell.name, spell.id)
                return
            end
        end
    end)
end)

local fear_immunity = { 6346, 49039, 48707, 642, 31224 }

-- Psychic Scream
psychic_scream:Callback("mutiple", function(spell)
    if awful.enemies.around(player, 6.5, function(enemy)
            return enemy.los and enemy.ccRemains < 1.0 and not enemy.isPet and not enemy.buffFrom(fear_immunity) and
                not tremor
        end) >= 2 then
        if spell:Cast() then
            awful.alert(spell.name .. " (Mutiple)", spell.id)
            return
        end
    end
end)

psychic_scream:Callback("focus", function(spell)
    if focus.exists and focus.los and focus.distanceLiteral < 9 and focus.ccRemains < 1.0 and
        not focus.buffFrom(fear_immunity) and not tremor then
        if spell:Cast() then
            awful.alert(spell.name .. " (Focus)", spell.id)
            return
        end
    end
end)

psychic_scream:Callback("lowhp", function(spell)
    awful.enemies.loop(function(enemy)
        if enemy.distanceLiteral < 9 and player.hp < 20 then
            if spell:Cast() then
                awful.alert(spell.name, spell.id)
                return
            end
        end
    end)
end)

-- Mass Dispel
local dispel_immune = {
    ["Hand of Protection"] = true,
    ["Divine Shield"] = true,
    ["Ice Block"] = true
}

mass_dispel:Callback("immune", function(spell)
    awful.enemies.loop(function(enemy)
        for i, buff in ipairs(enemy.buffs) do
            local name = unpack(buff)
            if dispel_immune[name] and awful.fullGroup.lowest.hp > 40 then
                if spell:SmartAoE(enemy) then
                    awful.alert(spell.name .. " (Immune)", spell.id)
                    return
                end
            end
        end
    end)
end)

mass_dispel:Callback("combat", function(spell)
    awful.enemies.loop(function(enemy)
        if enemy.debuff("Sap") and not player.combat then
            if spell:SmartAoE(enemy) then
                awful.alert(spell.name .. " (Getting combat)", spell.id)
                return
            end
        end
    end)
end)

local dispel_disease = {
    ["Disease"] = true
}

-- Abolish Disease
abolish_disease:Callback(function(spell)
    awful.fullGroup.loop(function(friend)
        for i = 1, #friend.debuffs do
            local _, _, _, type = unpack(friend['debuff' .. i])
            if dispel_disease[type] and not friend.buff(552) and friend.hp > 40 then
                if spell:Cast(friend) then
                    awful.alert(spell.name, spell.id)
                    return
                end
            end
        end
    end)
end)

local dispel_defensive = {
    ["Earthgrab"] = true,
    ["Psychic Scream"] = true,
    ["Psychic Horror"] = true,
    ["Entrapment"] = true,
    ["Polymorph"] = true,
    ["Seduction"] = true,
    ["Frost Nova"] = true,
    ["Howl of Terror"] = true,
    ["Earthbind"] = true,
    ["Faerie Fire"] = true,
    ["Cone of Cold"] = true,
    ["Silencing Shot"] = true,
    ["Deep Freeze"] = true,
    ["Pin"] = true,
    ["Hammer of Justice"] = true,
    ["Flame Shock"] = true,
    ["Fear"] = true,
    ["Entangling Roots"] = true,
    ["Freezing Arrow Effect"] = true,
    ["Freezing Trap"] = true,
    ["Chains of Ice"] = true,
    ["Immolate"] = true,
    ["Frostbolt"] = true,
    ["Dragon's Breath"] = true,
    ["Turn Evil"] = true,
    ["Repentance"] = true,
    ["Shadowflame"] = true,
    ["Hungering Cold"] = true,
    ["Hibernate"] = true,
    ["Freeze"] = true,
    ["Freezing Trap Effect"] = true,
    ["Strangulate"] = true,
    ["Death Coil"] = true,
    ["Silence"] = true,
    ["Shadowfury"] = true,
    ["Slow"] = true
}

local dispel_blacklist = {
    ["Unstable Affliction"] = true
}

dispel_magic:Callback("defensive", function(spell)
    awful.fullGroup.loop(function(friend)
        for i, debuff in ipairs(friend.debuffs) do
            local name = unpack(debuff)
            if dispel_blacklist[name] then
                return
            end
            if dispel_defensive[name] then
                if spell:Cast(friend) then
                    awful.alert(spell.name .. " (Defensive)", spell.id)
                    return
                end
            end
        end
    end)
end)

local dispel_offensive = {
    -- Druid
    ["Thorns"] = true,
    ["Barkskin"] = true,
    ["Rejuvenation"] = true,
    ["Regrowth"] = true,
    ["Lifebloom"] = true,
    ["Abolish Poison"] = true,
    ["Mark of the Wild"] = true,
    ["Predator's Swiftness"] = true,
    ["Gift of the Wild"] = true,
    ["Nature's Swiftness"] = true,
    ["Innervate"] = true,

    -- Mage
    ["Icy Veins"] = true,
    ["Ice Barrier"] = true,
    ["Arcane Intellect"] = true,
    ["Focus Magic"] = true,
    ["Arcane Brilliance"] = true,
    ["Mana Shield"] = true,
    ["Combustion"] = true,

    -- Paladin
    ["Hand of Sacrifice"] = true,
    ["Blessing of Wisdom"] = true,
    ["Greater Blessing of Wisdom"] = true,
    ["Hand of Freedom"] = true,
    ["Avenging Wrath"] = true,
    ["Beacon of Light"] = true,
    ["Sacred Shield"] = true,
    ["Blessing of Kings"] = true,
    ["Greater Blessing of Kings"] = true,
    ["Blessing of Might"] = true,
    ["Greater Blessing of Might"] = true,
    ["Divine Protection"] = true,

    -- Priest
    ["Prayer of Mending"] = true,
    ["Prayer of Fortitude"] = true,
    ["Power Word: Fortitude"] = true,
    ["Pain Suppression"] = true,
    ["Divine Spirit"] = true,
    ["Fear Ward"] = true,
    ["Power Word: Shield"] = true,
    ["Renew"] = true,
    ["Prayer of Spirit"] = true,
    ["Power Infusion"] = true,
    ["Mind Control"] = true,
    ["Grace"] = true,
    ["Inspiration"] = true,
    ["Divine Aegis"] = true,
    ["Prayer of Shadow Protection"] = true,
    ["Shadow Protection"] = true,

    -- Shaman
    ["Bloodlust"] = true,
    ["Elemental Mastery"] = true,
    ["Heroism"] = true,
    ["Riptide"] = true
}

dispel_magic:Callback("offensive", function(spell)
    awful.enemies.loop(function(enemy)
        for i, buff in ipairs(enemy.buffs) do
            local name = unpack(buff)
            if dispel_offensive[name] and player.manaPct > 20 and awful.fullGroup.lowest.hp > 40 then
                if spell:Cast(enemy) then
                    awful.alert(spell.name .. " (Offensive)", spell.id)
                    return
                end
            end
        end
    end)
end)

-- Dispel Magic
local dispel_regeneration = {
    -- Priest
    ["Fear Ward"] = true,

    -- Paladin
    ["Divine Plea"] = true,
    ["Divine Illumination"] = true,

    -- Druid
    ["Innervate"] = true
}

dispel_magic:Callback("focus", function(spell)
    awful.enemies.loop(function(enemy)
        for i, buff in ipairs(enemy.buffs) do
            local name = unpack(buff)
            if focus.exists and dispel_regeneration[name] and awful.fullGroup.lowest.hp > 40 then
                if spell:Cast(focus) then
                    awful.alert(spell.name .. " (Offensive)", spell.id)
                    return
                end
            end
        end
    end)
end)

-- Fear Ward
fear_ward:Callback(function(spell)
    awful.enemies.loop(function(enemy)
        -- If the enemy is a Priest and within 20 yards and has Fear Ward on cooldown, cast Fear Ward on the player.
        if enemy.class == "Priest" and enemy.distanceLiteral <= 20 and enemy.cooldown(10890) == 0 then
            spell_stop_casting()
            if spell:Cast(player) then
                awful.alert(spell.name, spell.id)
                return
            end
        end

        -- If the enemy is a Warrior and within 20 yards and has Intimidating Shout on cooldown, cast Fear Ward on the player.
        if enemy.class == "Warrior" and enemy.distanceLiteral <= 20 and enemy.cooldown(5246) == 0 then
            spell_stop_casting()
            if spell:Cast(player) then
                awful.alert(spell.name, spell.id)
                return
            end
        end

        -- If the enemy is a Warlock and within 20 yards and has Death Coil on cooldown or is casting Fear on the player, cast Fear Ward on the player.
        if enemy.class == "Warlock" and enemy.distanceLiteral <= 20 and
            (enemy.cooldown(17928) == 0 or enemy.casting == "Fear" and enemy.castTarget.isUnit(player)) then
            spell_stop_casting()
            if spell:Cast(player) then
                awful.alert(spell.name, spell.id)
                return
            end
        end
    end)
end)

-- Inner Fire
inner_fire:Callback(function(spell)
    if not player.buff(48168) and player.hp > 40 then
        if spell:Cast(player) then
            awful.alert(spell.name, spell.id)
            return
        end
    end
end)

-- Power Infusion
power_infusion:Callback("burst", function(spell)
    if not target.exists and not target.enemy then
        return
    end

    if not player.buff(10060) then
        if spell:Cast(player) then
            awful.alert(spell.name, spell.id)
            return
        end
    end
end)

-- Power Word Fortitude
power_word_fortitude:Callback(function(spell)
    if awful.prep then
        return
    end

    awful.fullGroup.loop(function(friend)
        if not (friend.buff(48161) or friend.buff(48162)) and friend.hp > 60 then
            if spell:Cast(friend) then
                awful.alert(spell.name, spell.id)
                return
            end
        end
    end)
end)
