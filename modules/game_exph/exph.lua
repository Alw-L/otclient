exphWindow = nil
exphSettings = nil
local timeOnline = 0

function init()
    connect(LocalPlayer, {
        onExperienceChange = onExperienceChange,
        onLevelChange = onLevelChange
    })
    connect(g_game, {
        onGameStart = online,
        onGameEnd = offline
    })

    exphWindow = g_ui.loadUI('exph')

    g_keyboard.bindKeyDown('Ctrl+J', toggle)

    exphSettings = g_settings.getNode('exph-hide')
    if not exphSettings then
        exphSettings = {}
    end

    refresh()
    exphWindow:setup()
end

function terminate()
    disconnect(LocalPlayer, {
        onExperienceChange = onExperienceChange,
        onLevelChange = onLevelChange
    })
    disconnect(g_game, {
        onGameStart = online,
        onGameEnd = offline
    })
    if expSpeedEvent then
        expSpeedEvent:cancel()
        expSpeedEvent = nil
    end

    g_keyboard.unbindKeyDown('Ctrl+J')
    exphWindow:destroy()

    exphWindow = nil
end

function expForLevel(level)
    return math.floor((50 * level * level * level) / 3 - 100 * level * level +
                          (850 * level) / 3 - 200)
end

function expToAdvance(currentLevel, currentExp)
    return expForLevel(currentLevel + 1) - currentExp
end

function toggleExph(id, state)
    local exph = exphWindow:recursiveGetChildById(id)
    exph:setVisible(state)
end

function setExphBase(id, value, baseValue)
    if baseValue <= 0 or value < 0 then return end
    local exph = exphWindow:recursiveGetChildById(id)
    local widget = exph:getChildById('value')

    if value > baseValue then
        widget:setColor('#008b00') -- green
        exph:setTooltip(baseValue .. ' +' .. (value - baseValue))
    elseif value < baseValue then
        widget:setColor('#b22222') -- red
        exph:setTooltip(baseValue .. ' ' .. (value - baseValue))
    else
        widget:setColor('#bbbbbb') -- default
        exph:removeTooltip()
    end
end

function setExphValue(id, value)
    local exph = exphWindow:recursiveGetChildById(id)
    local widget = exph:getChildById('value')
    widget:setText(value)
end

function online()
    exphWindow:setupOnStart() -- load character window configuration
    refresh()
end

function refresh()
    local player = g_game.getLocalPlayer()
    if not player then return end

    player.firstOnline = nil
    resetCounter()

    if expSpeedEvent then expSpeedEvent:cancel() end
    expSpeedEvent = cycleEvent(checkExpSpeed, 1000)

    onExperienceChange(player, player:getExperience())
    onLevelChange(player, player:getLevel(), player:getLevelPercent())

    local contentsPanel = exphWindow:getChildById('contentsPanel')
    exphWindow:setContentMinimumHeight(100)
    exphWindow:setContentMaximumHeight(100)
    exphWindow:setContentHeight(100)
end

function offline()
    exphWindow:setParent(nil, true)
    if expSpeedEvent then
        expSpeedEvent:cancel()
        expSpeedEvent = nil
    end
    g_settings.setNode('exph-hide', exphSettings)
end

function toggle()
    if(not g_game.isOnline()) then
        return
    end

    if exphWindow:isVisible() then
        closeWindow()
    else
        openWindow()
    end
end

function checkExpSpeed()
    local player = g_game.getLocalPlayer()
    if not player then return end
    if(player.firstOnline == nil) then
        player.firstOnline = g_clock.seconds()
    end

    local currentTime = g_clock.seconds()
    local timeOnline = currentTime-player.firstOnline
    local hours = math.max(0,math.floor(timeOnline / 3600))
    local minutes = math.max(0,math.floor(timeOnline / 60))
    sessionText = minutes..'m'
    if(hours > 0) then
        sessionText = hours..'h '..minutes..'m'
    end
    setExphValue('sessionTotal', sessionText)

    local currentExp = player:getExperience()
    if(currentExp > 0) then
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
end

function closeWindow()
    exphWindow:close()
end

function openWindow()
    exphWindow:open()
end

function resetCounter()
    local player = g_game.getLocalPlayer()
    player.firstExp = nil
    player.lastExps = nil
    player.expSpeed = nil
    checkExpSpeed()
    onExperienceChange(player, player:getExperience())
    onLevelChange(player, player:getLevel(), player:getLevelPercent())
end

function onExperienceChange(localPlayer, value)
    local player = g_game.getLocalPlayer()
    if not player then return end
    if value <= 0 then return end

    if(player.firstExp == nil) then
        player.firstExp = value
        setExphValue('expGained', postfixValue(0))
    else
        setExphValue('expGained', postfixValue(value-player.firstExp))
    end
end

function onLevelChange(localPlayer, value, percent)
    if localPlayer.expSpeed ~= nil then
        local expPerHour = math.floor(localPlayer.expSpeed * 3600)
        setExphValue('expPerHour', comma_value(expPerHour))
        local nextLevelExp = expForLevel(localPlayer:getLevel() + 1)
        local nextLevelExpLeft = (nextLevelExp - localPlayer:getExperience())
        setExphValue('expToLevel', comma_value(nextLevelExpLeft))
        if expPerHour > 0 then
            local hoursLeft = nextLevelExpLeft / expPerHour
            local minutesLeft = (hoursLeft - math.floor(hoursLeft)) * 60
            local secondsLeft = (minutesLeft - math.floor(minutesLeft)) * 60
            hoursLeft = math.floor(hoursLeft)
            minutesLeft = math.floor(minutesLeft)
            secondsLeft = math.floor(secondsLeft)
            local sessionText = secondsLeft..'s'
            if(minutesLeft > 0) then
                sessionText = minutesLeft..'m '..sessionText
            end
            if(hoursLeft > 0) then
                sessionText = hoursLeft..'h '..minutesLeft..'m'
            end
            setExphValue('timeToLevel', sessionText)
        else
            setExphValue('timeToLevel', 0)
        end
    end
end

function postfixValue(value)
    local postFix = ""
    if value > 1e15 then
      postFix = "B"
      value = math.floor(value / 1e9)
    elseif value > 1e12 then
      postFix = "M"
      value = math.floor(value / 1e6)
    elseif value > 1e9 then
      postFix = "K"
      value = math.floor(value / 1e3)
    end
    return comma_value(value) .. postFix
end