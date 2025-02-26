skillsWindow = nil
skillsSettings = nil

function init()
    connect(LocalPlayer, {
        onExperienceChange = onExperienceChange,
        onLevelChange = onLevelChange,
        onHealthChange = onHealthChange,
        onManaChange = onManaChange,
        --onSoulChange = onSoulChange,
        onFreeCapacityChange = onFreeCapacityChange,
        onTotalCapacityChange = onTotalCapacityChange,
        onStaminaChange = onStaminaChange,
        onOfflineTrainingChange = onOfflineTrainingChange,
        onRegenerationChange = onRegenerationChange,
        onSpeedChange = onSpeedChange,
        onBaseSpeedChange = onBaseSpeedChange,
        onMagicLevelChange = onMagicLevelChange,
        onBaseMagicLevelChange = onBaseMagicLevelChange,
        onSkillChange = onSkillChange,
        onBaseSkillChange = onBaseSkillChange
    })
    connect(g_game, {
        onGameStart = online,
        onGameEnd = offline
    })

    skillsButton = modules.client_topmenu.addRightGameToggleButton(
                       'skillsButton', tr('Skills') .. ' (Alt+S)',
                       '/images/topbuttons/skills', toggle)
    skillsButton:setOn(true)
    skillsWindow = g_ui.loadUI('skills')

    g_keyboard.bindKeyDown('Ctrl+S', toggle)

    skillsSettings = g_settings.getNode('skills-hide')
    if not skillsSettings then
        skillsSettings = {}
    end

    refresh()
    skillsWindow:setup()
    if g_game.isOnline() then
        online()
    end
end

function terminate()
    disconnect(LocalPlayer, {
        onExperienceChange = onExperienceChange,
        onLevelChange = onLevelChange,
        onHealthChange = onHealthChange,
        onManaChange = onManaChange,
        --onSoulChange = onSoulChange,
        onFreeCapacityChange = onFreeCapacityChange,
        onTotalCapacityChange = onTotalCapacityChange,
        onStaminaChange = onStaminaChange,
        onOfflineTrainingChange = onOfflineTrainingChange,
        onRegenerationChange = onRegenerationChange,
        onSpeedChange = onSpeedChange,
        onBaseSpeedChange = onBaseSpeedChange,
        onMagicLevelChange = onMagicLevelChange,
        onBaseMagicLevelChange = onBaseMagicLevelChange,
        onSkillChange = onSkillChange,
        onBaseSkillChange = onBaseSkillChange
    })
    disconnect(g_game, {
        onGameStart = online,
        onGameEnd = offline
    })

    g_keyboard.unbindKeyDown('Ctrl+S')
    skillsWindow:destroy()
    skillsButton:destroy()

    skillsWindow = nil
    skillsButton = nil
end

function expForLevel(level)
    return math.floor((50 * level * level * level) / 3 - 100 * level * level +
                          (850 * level) / 3 - 200)
end

function expToAdvance(currentLevel, currentExp)
    return expForLevel(currentLevel + 1) - currentExp
end

function resetSkillColor(id)
    local skill = skillsWindow:recursiveGetChildById(id)
    local widget = skill:getChildById('value')
    widget:setColor('#bbbbbb')
end

function toggleSkill(id, state)
    local skill = skillsWindow:recursiveGetChildById(id)
    skill:setVisible(state)
end

function setSkillBase(id, value, baseValue)
    if baseValue <= 0 or value < 0 then return end
    local skill = skillsWindow:recursiveGetChildById(id)
    local widget = skill:getChildById('value')

    widget:setColor('#bbbbbb') -- default
    skill:removeTooltip()
end

function setSkillValue(id, value)
    local skill = skillsWindow:recursiveGetChildById(id)
    local widget = skill:getChildById('value')
    widget:setText(value)
end

function setSkillColor(id, value)
    local skill = skillsWindow:recursiveGetChildById(id)
    local widget = skill:getChildById('value')
    widget:setColor(value)
end

function setSkillTooltip(id, value)
    local skill = skillsWindow:recursiveGetChildById(id)
    local widget = skill:getChildById('value')
    widget:setTooltip(value)
end

function setSkillPercent(id, percent, tooltip, color)
    local skill = skillsWindow:recursiveGetChildById(id)
    local widget = skill:getChildById('percent')
    if widget then
        widget:setPercent(math.floor(percent))

        if tooltip then widget:setTooltip(tooltip) end

        if color then widget:setBackgroundColor(color) end
    end
end

function checkAlert(id, value, maxValue, threshold, greaterThan)

     resetSkillColor(id)

end

function update()
    local offlineTraining =
        skillsWindow:recursiveGetChildById('offlineTraining')
    if not g_game.getFeature(GameOfflineTrainingTime) then
        offlineTraining:hide()
    else
        offlineTraining:show()
    end

    local regenerationTime = skillsWindow:recursiveGetChildById(
                                 'regenerationTime')
    if not g_game.getFeature(GamePlayerRegenerationTime) then
        regenerationTime:hide()
    else
        regenerationTime:show()
    end
end

function online()
    skillsWindow:setupOnStart() -- load character window configuration
    refresh()
end

function refresh()
    local player = g_game.getLocalPlayer()
    if not player then return end

    if expSpeedEvent then expSpeedEvent:cancel() end
    expSpeedEvent = cycleEvent(checkExpSpeed, 30 * 1000)

    onExperienceChange(player, player:getExperience())
    onLevelChange(player, player:getLevel(), player:getLevelPercent())
    onHealthChange(player, player:getHealth(), player:getMaxHealth())
    onManaChange(player, player:getMana(), player:getMaxMana())
    --onSoulChange(player, player:getSoul())
    onFreeCapacityChange(player, player:getFreeCapacity())
    onStaminaChange(player, player:getStamina())
    onMagicLevelChange(player, player:getMagicLevel(),
                       player:getMagicLevelPercent())
    onOfflineTrainingChange(player, player:getOfflineTrainingTime())
    onRegenerationChange(player, player:getRegenerationTime())
    onSpeedChange(player, player:getSpeed())

    local hasAdditionalSkills = g_game.getFeature(GameAdditionalSkills)
    for i = Skill.Fist, Skill.ManaLeechAmount do
        onSkillChange(player, i, player:getSkillLevel(i),
                      player:getSkillLevelPercent(i))
        onBaseSkillChange(player, i, player:getSkillBaseLevel(i))

        if i > Skill.Fishing then
            toggleSkill('skillId' .. i, hasAdditionalSkills)
        end
    end

    update()

    local maximumHeight = 25

    if g_game.isOnline() then
        local char = g_game.getCharacterName()

        if not skillsSettings[char] then
            skillsSettings[char] = {}
        end

        local skillsButtons = skillsWindow:recursiveGetChildById('experience'):getParent():getChildren()

        for _, skillButton in pairs(skillsButtons) do
            local percentBar = skillButton:getChildById('percent')

            if skillButton:isVisible() then
                maximumHeight = maximumHeight + 14
                if percentBar then
                    showPercentBar(skillButton, skillsSettings[char][skillButton:getId()] ~= 1)
                    if percentBar:isVisible() then
                        maximumHeight = maximumHeight + 6
                    end
                end
            end
        end
    end

    local contentsPanel = skillsWindow:getChildById('contentsPanel')
    skillsWindow:setContentMinimumHeight(44)
    skillsWindow:setContentMaximumHeight(maximumHeight ~= 25 and maximumHeight or 275)
end

function offline()
    skillsWindow:setParent(nil, true)
    if expSpeedEvent then
        expSpeedEvent:cancel()
        expSpeedEvent = nil
    end
    g_settings.setNode('skills-hide', skillsSettings)
end

function toggle()
    if(not g_game.isOnline()) then
        return
    end
    if skillsButton:isOn() then
        skillsButton:setOn(false)
    else
        skillsButton:setOn(true)
    end

    if skillsWindow:isVisible() then
        closeWindow()
    else
        openWindow()
    end
end

function checkExpSpeed()
    local player = g_game.getLocalPlayer()
    if not player then return end

    local currentExp = player:getExperience()
    local currentTime = g_clock.seconds()
    if player.lastExps ~= nil then
        player.expSpeed = (currentExp - player.lastExps[1][1]) /
                              (currentTime - player.lastExps[1][2])
        onLevelChange(player, player:getLevel(), player:getLevelPercent())
    else
        player.lastExps = {}
    end
    table.insert(player.lastExps, {currentExp, currentTime})
    if #player.lastExps > 30 then table.remove(player.lastExps, 1) end
end

function onMiniWindowOpen()
    modules.game_playerbars.skillsButton:setChecked(true)
end

function onMiniWindowClose()
    modules.game_playerbars.skillsButton:setChecked(false)
end

function closeWindow()
    modules.game_playerbars.skillsButton:setChecked(false)
    skillsWindow:close()
end

function openWindow()
    modules.game_playerbars.skillsButton:setChecked(1)
    skillsWindow:open()
    refresh()
end

function onSkillButtonClick(button)
    local percentBar = button:getChildById('percent')
    if percentBar then
        showPercentBar(button, not percentBar:isVisible())

        local char = g_game.getCharacterName()
        if percentBar:isVisible() then
            skillsWindow:modifyMaximumHeight(6)
            skillsSettings[char][button:getId()] = 0
        else
            skillsWindow:modifyMaximumHeight(-6)
            skillsSettings[char][button:getId()] = 1
        end
    end
end

function showPercentBar(button, show)
    local percentBar = button:getChildById('percent')
    if percentBar then
        percentBar:setVisible(show)
        if show then
            button:setHeight(21)
        else
            button:setHeight(21 - 6)
        end
    end
end

function onExperienceChange(localPlayer, value)
    local postFix = ""
    setSkillValue('experience', comma_value(value) .. postFix)
end

function onLevelChange(localPlayer, value, percent)
    setSkillValue('level', comma_value(value))
    local text = tr('You have %s percent to go', 100 - percent) .. '\n' ..
                     tr('%s of experience left', expToAdvance(
                            localPlayer:getLevel(), localPlayer:getExperience()))

    if localPlayer.expSpeed ~= nil then
        local expPerHour = math.floor(localPlayer.expSpeed * 3600)
        if expPerHour > 0 then
            local nextLevelExp = expForLevel(localPlayer:getLevel() + 1)
            local hoursLeft = (nextLevelExp - localPlayer:getExperience()) /
                                  expPerHour
            local minutesLeft = math.floor(
                                    (hoursLeft - math.floor(hoursLeft)) * 60)
            hoursLeft = math.floor(hoursLeft)
            text = text .. '\n' ..
                       tr('%s experience per hour', comma_value(expPerHour))
            text = text .. '\n' ..
                       tr('Next level in %d hours and %d minutes', hoursLeft,
                          minutesLeft)
        end
    end

    setSkillPercent('level', percent, text)
end

function onHealthChange(localPlayer, health, maxHealth)
    setSkillValue('health', comma_value(health))
    checkAlert('health', health, maxHealth, 30)
end

function onManaChange(localPlayer, mana, maxMana)
    setSkillValue('mana', comma_value(mana))
    checkAlert('mana', mana, maxMana, 30)
end

--function onSoulChange(localPlayer, soul) setSkillValue('soul', comma_value(soul)) end

function onFreeCapacityChange(localPlayer, freeCapacity)
    setSkillValue('capacity', comma_value(math.floor(freeCapacity)))
    checkAlert('capacity', freeCapacity, localPlayer:getTotalCapacity(), 20)
end

function onTotalCapacityChange(localPlayer, totalCapacity)
    checkAlert('capacity', localPlayer:getFreeCapacity(), totalCapacity, 20)
end

function onStaminaChange(localPlayer, stamina)
end

function onOfflineTrainingChange(localPlayer, offlineTrainingTime)

end

function onRegenerationChange(localPlayer, regenerationTime)
    if not g_game.getFeature(GamePlayerRegenerationTime) or regenerationTime < 0 then
        return
    end
    local minutes = math.floor(regenerationTime / 60)
    local seconds = regenerationTime % 60
    if seconds < 10 then seconds = '0' .. seconds end

    setSkillValue('regenerationTime', minutes .. ":" .. seconds)
    checkAlert('regenerationTime', regenerationTime, false, 300)
end

function onSpeedChange(localPlayer, speed)
    setSkillValue('speed', comma_value(speed))

    onBaseSpeedChange(localPlayer, localPlayer:getBaseSpeed())
end

function onBaseSpeedChange(localPlayer, baseSpeed)
    setSkillBase('speed', localPlayer:getSpeed(), baseSpeed)
end

function onMagicLevelChange(localPlayer, magiclevel, percent)
    setSkillValue('magiclevel', comma_value(magiclevel))
    setSkillPercent('magiclevel', percent,
                    tr('You have %s percent to go', 100 - percent))

    onBaseMagicLevelChange(localPlayer, localPlayer:getBaseMagicLevel())
end

function onBaseMagicLevelChange(localPlayer, baseMagicLevel)
    setSkillBase('magiclevel', localPlayer:getMagicLevel(), baseMagicLevel)
end

function onSkillChange(localPlayer, id, level, percent)
    setSkillValue('skillId' .. id, comma_value(level))
    setSkillPercent('skillId' .. id, percent,
                    tr('You have %s percent to go', 100 - percent))

    onBaseSkillChange(localPlayer, id, localPlayer:getSkillBaseLevel(id))
end

function onBaseSkillChange(localPlayer, id, baseLevel)
    setSkillBase('skillId' .. id, localPlayer:getSkillLevel(id), baseLevel)
end
