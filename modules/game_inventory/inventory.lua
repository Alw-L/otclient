InventorySlotStyles = {
    [InventorySlotHead] = "HeadSlot",
    [InventorySlotNeck] = "NeckSlot",
    [InventorySlotBack] = "BackSlot",
    [InventorySlotBody] = "BodySlot",
    [InventorySlotRight] = "RightSlot",
    [InventorySlotLeft] = "LeftSlot",
    [InventorySlotLeg] = "LegSlot",
    [InventorySlotFeet] = "FeetSlot",
    [InventorySlotFinger] = "FingerSlot",
    [InventorySlotAmmo] = "AmmoSlot"
}

Icons = {}
Icons[PlayerStates.Poison] = {
    tooltip = tr('You are poisoned'),
    path = '/images/game/states/poisoned',
    id = 'condition_poisoned'
}
Icons[PlayerStates.Burn] = {
    tooltip = tr('You are burning'),
    path = '/images/game/states/burning',
    id = 'condition_burning'
}
Icons[PlayerStates.Energy] = {
    tooltip = tr('You are electrified'),
    path = '/images/game/states/electrified',
    id = 'condition_electrified'
}
Icons[PlayerStates.Drunk] = {
    tooltip = tr('You are drunk'),
    path = '/images/game/states/drunk',
    id = 'condition_drunk'
}
Icons[PlayerStates.ManaShield] = {
    tooltip = tr('You are protected by a magic shield'),
    path = '/images/game/states/magic_shield',
    id = 'condition_magic_shield'
}
Icons[PlayerStates.Paralyze] = {
    tooltip = tr('You are paralysed'),
    path = '/images/game/states/slowed',
    id = 'condition_slowed'
}
Icons[PlayerStates.Haste] = {
    tooltip = tr('You are hasted'),
    path = '/images/game/states/haste',
    id = 'condition_haste'
}
Icons[PlayerStates.Swords] = {
    tooltip = tr('You may not logout during a fight'),
    path = '/images/game/states/logout_block',
    id = 'condition_logout_block'
}
Icons[PlayerStates.Drowning] = {
    tooltip = tr('You are drowning'),
    path = '/images/game/states/drowning',
    id = 'condition_drowning'
}
Icons[PlayerStates.Freezing] = {
    tooltip = tr('You are freezing'),
    path = '/images/game/states/freezing',
    id = 'condition_freezing'
}
Icons[PlayerStates.Dazzled] = {
    tooltip = tr('You are dazzled'),
    path = '/images/game/states/dazzled',
    id = 'condition_dazzled'
}
Icons[PlayerStates.Cursed] = {
    tooltip = tr('You are cursed'),
    path = '/images/game/states/cursed',
    id = 'condition_cursed'
}
Icons[PlayerStates.PartyBuff] = {
    tooltip = tr('You are strengthened'),
    path = '/images/game/states/strengthened',
    id = 'condition_strengthened'
}
Icons[PlayerStates.PzBlock] = {
    tooltip = tr('You may not logout or enter a protection zone'),
    path = '/images/game/states/protection_zone_block',
    id = 'condition_protection_zone_block'
}
Icons[PlayerStates.Pz] = {
    tooltip = tr('You are within a protection zone'),
    path = '/images/game/states/protection_zone',
    id = 'condition_protection_zone'
}
Icons[PlayerStates.Bleeding] = {
    tooltip = tr('You are bleeding'),
    path = '/images/game/states/bleeding',
    id = 'condition_bleeding'
}
Icons[PlayerStates.Hungry] = {
    tooltip = tr('You are hungry'),
    path = '/images/game/states/hungry',
    id = 'condition_hungry'
}

Skulls = {}
Skulls[SkullWhite] = { tooltip = tr('White skull'), path = '/images/game/skulls/condition_skull_white', id = 'skull_white' }
Skulls[SkullGreen] = { tooltip = tr('Green skull'), path = '/images/game/skulls/condition_skull_green', id = 'skull_green' }
Skulls[SkullRed] = { tooltip = tr('Red skull'), path = '/images/game/skulls/condition_skull_red', id = 'skull_red' }


inventoryWindow = nil
inventoryPanel = nil
--soulLabel = nil
capLabel = nil
inventoryButton = nil
purseButton = nil
conditionPanel = nil
conditionHolder = nil

fightOffensiveBox = nil
fightBalancedBox = nil
fightDefensiveBox = nil
chaseModeBox = nil
standModeBox = nil

safeFightButton = nil
fightModeRadioGroup = nil
inventoryMinimized = false

function init()
    connect(LocalPlayer, {
        onInventoryChange = onInventoryChange,
        onBlessingsChange = onBlessingsChange
    })
    connect(g_game, {
        onGameStart = online,
        onGameEnd = offline
    })
    
    g_keyboard.bindKeyDown('Ctrl+I', toggle)
    
    inventoryButton = modules.client_topmenu.addRightGameToggleButton(
    'inventoryButton', tr('Inventory') .. ' (Ctrl+I)',
    '/images/topbuttons/inventory', toggle)
    inventoryButton:setOn(true)
    
    inventoryWindow = g_ui.loadUI('inventory')
    inventoryWindow:disableResize()
    
    conditionPanel = inventoryWindow:recursiveGetChildById('conditionPanel')
    conditionHolder = conditionPanel:recursiveGetChildById('conditionHolder')

    fightOffensiveBox = inventoryWindow:recursiveGetChildById('fightOffensiveBox')
    fightBalancedBox = inventoryWindow:recursiveGetChildById('fightBalancedBox')
    fightDefensiveBox = inventoryWindow:recursiveGetChildById('fightDefensiveBox')
    
    chaseModeBox = inventoryWindow:recursiveGetChildById('chaseModeBox')
    standModeBox = inventoryWindow:recursiveGetChildById('standModeBox')
    safeFightButton = inventoryWindow:recursiveGetChildById('safeFightBox')
    
    fightModeRadioGroup = UIRadioGroup.create()
    fightModeRadioGroup:addWidget(fightOffensiveBox)
    fightModeRadioGroup:addWidget(fightBalancedBox)
    fightModeRadioGroup:addWidget(fightDefensiveBox)
    
    chaseModeRadioGroup = UIRadioGroup.create()
    chaseModeRadioGroup:addWidget(standModeBox)
    chaseModeRadioGroup:addWidget(chaseModeBox)
    
    
    connect(fightModeRadioGroup, { onSelectionChange = onSetFightMode })
    connect(chaseModeRadioGroup, { onSelectionChange = onSetChaseMode })
    connect(safeFightButton, { onCheckChange = onSetSafeFight })
    
    connect(LocalPlayer, {
        onInventoryChange = onInventoryChange,
        --onSoulChange = onSoulChange,
        onFreeCapacityChange = onFreeCapacityChange,
        onStatesChange = onStatesChange,
        onSkullChange = updateCreatureSkull
    })
    
    connect(g_game, {
        onGameStart = online,
        onGameEnd = offline,
        onFightModeChange = update,
        onChaseModeChange = update,
        onSafeFightChange = update,
        onWalk = check,
        onAutoWalk = check
    })
    connect(LocalPlayer, {onOutfitChange = onOutfitChange})
    
    inventoryPanel = inventoryWindow:getChildById('contentsPanel')
    --soulLabel = inventoryWindow:recursiveGetChildById('soulLabel')
    capLabel = inventoryWindow:recursiveGetChildById('capLabel')
    inventoryWindow:getChildById('contentsPanel'):setMarginTop(3)
    
    for k,v in pairs(Icons) do
        g_textures.preload(v.path)
    end
    
    purseButton = inventoryWindow:recursiveGetChildById('purseButton')
    local function purseFunction()
        local purse = g_game.getLocalPlayer():getInventoryItem(
        InventorySlotPurse)
        if purse then g_game.use(purse) end
    end
    purseButton.onClick = purseFunction
    
    if g_game.isOnline() then
        local localPlayer = g_game.getLocalPlayer()
        --onSoulChange(localPlayer, localPlayer:getSoul())
        onFreeCapacityChange(localPlayer, localPlayer:getFreeCapacity())
        onStatesChange(localPlayer, localPlayer:getStates(), 0)
        updateCreatureSkull(localPlayer, localPlayer:getSkull())
        refresh()
    end
    
    inventoryWindow:setup()
    if g_game.isOnline() then
        online()
    end
end

function terminate()
    if g_game.isOnline() then
        offline()
    end
    
    disconnect(LocalPlayer, {
        onInventoryChange = onInventoryChange,
        onBlessingsChange = onBlessingsChange,
        --onSoulChange = onSoulChange,
        onFreeCapacityChange = onFreeCapacityChange,
        onStatesChange = onStatesChange,
        onSkullChange = updateCreatureSkull
    })
    disconnect(g_game, {
        onGameStart = online,
        onGameEnd = offline,
        onFightModeChange = update,
        onChaseModeChange = update,
        onSafeFightChange = update,
        onWalk = check,
        onAutoWalk = check
    })
    disconnect(LocalPlayer, {onOutfitChange = onOutfitChange})
    
    g_keyboard.unbindKeyDown('Ctrl+I')
    
    inventoryWindow:destroy()
    inventoryButton:destroy()
    
    fightModeRadioGroup:destroy()
    
    conditionPanel = nil
    conditionHolder = nil
    fightOffensiveBox = nil
    fightBalancedBox = nil
    fightDefensiveBox = nil
    safeFightButton = nil
    fightModeRadioGroup = nil
    inventoryPanel = nil
    inventoryButton = nil
    purseButton = nil
end

function toggleAdventurerStyle(hasBlessing)
    for slot = InventorySlotFirst, InventorySlotLast do
        local itemWidget = inventoryPanel:getChildById('slot' .. slot)
        if itemWidget then itemWidget:setOn(hasBlessing) end
    end
end

function offline()
    inventoryWindow:setParent(nil, true)
    local lastCombatControls = g_settings.getNode('LastCombatControls')
    if not lastCombatControls then lastCombatControls = {} end
    
    local player = g_game.getLocalPlayer()
    if player then
        local char = g_game.getCharacterName()
        lastCombatControls[char] = {
            fightMode = g_game.getFightMode(),
            chaseMode = g_game.getChaseMode(),
            safeFight = g_game.isSafeFight()
        }
        
        if g_game.getFeature(GamePVPMode) then
            lastCombatControls[char].pvpMode = g_game.getPVPMode()
        end
        
        -- save last combat control settings
        g_settings.setNode('LastCombatControls', lastCombatControls)
    end
end

function update()
    local fightMode = g_game.getFightMode()
    if fightMode == FightOffensive then
        fightModeRadioGroup:selectWidget(fightOffensiveBox)
    elseif fightMode == FightBalanced then
        fightModeRadioGroup:selectWidget(fightBalancedBox)
    else
        fightModeRadioGroup:selectWidget(fightDefensiveBox)
    end
    
    local chaseMode = g_game.getChaseMode()
    if chaseMode == ChaseOpponent then
        chaseModeRadioGroup:selectWidget(chaseModeBox)
    else
        chaseModeRadioGroup:selectWidget(standModeBox)
    end
    
    local safeFight = g_game.isSafeFight()
    safeFightButton:setChecked(not safeFight)
    
end

function check()
    if modules.client_options.getOption('autoChaseOverride') then
        if g_game.isAttacking() and g_game.getChaseMode() == ChaseOpponent then
            chaseModeRadioGroup:selectWidget(standModeBox)
            g_game.setChaseMode(DontChase)
        end
    end
end

function online()
    inventoryWindow:setupOnStart() -- load character window configuration

    local player = g_game.getLocalPlayer()
    if player then
        local char = g_game.getCharacterName()
        
        local lastCombatControls = g_settings.getNode('LastCombatControls')
        
        if not table.empty(lastCombatControls) then
            if lastCombatControls[char] then
                g_game.setFightMode(lastCombatControls[char].fightMode)
                g_game.setChaseMode(lastCombatControls[char].chaseMode)
                g_game.setSafeFight(lastCombatControls[char].safeFight)
                if lastCombatControls[char].pvpMode then
                    g_game.setPVPMode(lastCombatControls[char].pvpMode)
                end
            end
        end
    end

    update()
    refresh()
end

function refresh()
    local player = g_game.getLocalPlayer()
    for i = InventorySlotFirst, InventorySlotPurse do
        if g_game.isOnline() then
            onInventoryChange(player, i, player:getInventoryItem(i))
        else
            onInventoryChange(player, i, nil)
        end
        toggleAdventurerStyle(player and
        Bit.hasBit(player:getBlessings(),
        Blessings.Adventurer) or false)
    end
    
    purseButton:setVisible(g_game.getFeature(GamePurseSlot))
    if player then
        local char = g_game.getCharacterName()
        
        local lastCombatControls = g_settings.getNode('LastCombatControls')
        
        if not table.empty(lastCombatControls) then
            if lastCombatControls[char] then
                g_game.setFightMode(lastCombatControls[char].fightMode)
                g_game.setChaseMode(lastCombatControls[char].chaseMode)
                g_game.setSafeFight(lastCombatControls[char].safeFight)
                if lastCombatControls[char].pvpMode then
                    g_game.setPVPMode(lastCombatControls[char].pvpMode)
                end
                onInventoryMinimize(lastCombatControls[char].inventoryMinimize)
            end
        end
    end
    update()
end

function toggle()
    if inventoryButton:isOn() then
        inventoryWindow:close()
        inventoryButton:setOn(false)
    else
        inventoryWindow:open()
        inventoryButton:setOn(true)
    end
end

function onOutfitChange(localPlayer, outfit, oldOutfit)
end

local excessIcons = {}
function toggleIcon(bitChanged)
    if(bitChanged == PlayerStates.Pz) then
        return
    end

    local icon = conditionHolder:getChildById(Icons[bitChanged].id)
    local childCount = conditionHolder:getChildCount()
    if icon then
        icon:destroy()
        if(#excessIcons > 0) then
            excessIcons[1]:setVisible(true)
            table.remove(excessIcons, 1)
        end
    else
        icon = loadIcon(bitChanged)
        icon:setParent(conditionHolder)
        if(conditionHolder:getChildCount() > 6) then
            icon:setVisible(false)
            excessIcons[#excessIcons + 1] = icon
        end
    end
    adjustConditionHolder()
end

function toggleSkullIcon(skullId)
    if skullId == 0 then return end
    local icon = conditionHolder:getChildById(Skulls[skullId].id)
    if not icon then
        icon = loadSkull(skullId)
        icon:setParent(conditionHolder)
        if(conditionHolder:getChildCount() > 6) then
            icon:setVisible(false)
            excessIcons[#excessIcons + 1] = icon
        end
    end
    adjustConditionHolder()
end

function adjustConditionHolder()
    if(conditionHolder:getChildCount() > 3) then
        conditionHolder:setMarginLeft(3)
        conditionHolder:setMarginTop(2)
        conditionHolder:getLayout():setCellSize(tosize('8 8'))
    elseif(conditionHolder:getChildCount() == 1) then
        conditionHolder:setMarginTop(6)
        conditionHolder:setMarginLeft(11)
    elseif(conditionHolder:getChildCount() <= 3) then
        conditionHolder:setMarginTop(6)
        conditionHolder:setMarginLeft(1)
        conditionHolder:getLayout():setCellSize(tosize('9 9'))
    end
end

function loadIcon(bitChanged)
    local icon = g_ui.createWidget('ConditionWidget')
    icon:setId(Icons[bitChanged].id)
    icon:setImageSource(Icons[bitChanged].path)
    icon:setTooltip(Icons[bitChanged].tooltip)
    return icon
end

function loadSkull(bitChanged)
    local icon = g_ui.createWidget('ConditionWidget')
    icon:setId(Skulls[bitChanged].id)
    icon:setImageSource(Skulls[bitChanged].path)
    return icon
end

function onStatesChange(localPlayer, now, old)
    if now == old then return end
    local bitsChanged = bit32.bxor(now, old)
    for i = 1, 32 do
        local pow = math.pow(2, i-1)
        if pow > bitsChanged then break end
        local bitChanged = bit32.band(bitsChanged, pow)
        if bitChanged ~= 0 then
            toggleIcon(bitChanged)
        end
    end
end

function updateCreatureSkull(creature, skullId)
    local player = g_game.getLocalPlayer()
    if creature ~= player then return end
    local skullIcons = {SkullGreen, SkullWhite, SkullRed}
    local childCount = conditionHolder:getChildCount()
    if(#excessIcons > 0) then
        excessIcons[1]:setVisible(true)
        table.remove(excessIcons, 1)
    end
    for k,v in pairs(skullIcons) do
        icon = conditionHolder:getChildById(Skulls[v].id)
        if icon then
            icon:destroy()
        end
    end
    toggleSkullIcon(skullId)
end

function offline()
    conditionHolder:destroyChildren()
    local lastCombatControls = g_settings.getNode('LastCombatControls')
    if not lastCombatControls then
        lastCombatControls = {}
    end
    
    local player = g_game.getLocalPlayer()
    if player then
        local char = g_game.getCharacterName()
        lastCombatControls[char] = {
            fightMode = g_game.getFightMode(),
            chaseMode = g_game.getChaseMode(),
            safeFight = g_game.isSafeFight(),
            inventoryMinimize = inventoryMinimized
        }
        
        if g_game.getFeature(GamePVPMode) then
            lastCombatControls[char].pvpMode = g_game.getPVPMode()
        end
        -- save last combat control settings
        g_settings.setNode('LastCombatControls', lastCombatControls)
    end
end

-- hooked events
function onInventoryChange(player, slot, item, oldItem)
    if slot > InventorySlotPurse then return end
    
    if slot == InventorySlotPurse then
        if g_game.getFeature(GamePurseSlot) then
            purseButton:setEnabled(item and true or false)
        end
        return
    end
    
    local itemWidget = inventoryPanel:getChildById('slot' .. slot)
    if item then
        itemWidget:setStyle('InventoryItem')
        itemWidget:setItem(item)
    else
        itemWidget:setStyle(InventorySlotStyles[slot])
        itemWidget:setItem(nil)
    end
end

function onBlessingsChange(player, blessings, oldBlessings)
    local hasAdventurerBlessing = Bit.hasBit(blessings, Blessings.Adventurer)
    if hasAdventurerBlessing ~= Bit.hasBit(oldBlessings, Blessings.Adventurer) then
        toggleAdventurerStyle(hasAdventurerBlessing)
    end
end

--function onSoulChange(localPlayer, soul)
--    soulLabel:setText(soul)
--end

function onFreeCapacityChange(player, freeCapacity)
    if not freeCapacity then return end
    freeCapacity = freeCapacity
    local decorator = ''
    if freeCapacity > 999999 then
        freeCapacity = math.floor(freeCapacity/10^6) .. "m"
    elseif freeCapacity > 99999 then
        freeCapacity = math.floor(freeCapacity/10^5) .. "kk"
    end

    capLabel:setText(math.floor(freeCapacity) .. decorator)
end

function onSetFightMode(self, selectedFightButton)
    if selectedFightButton == nil then return end
    local buttonId = selectedFightButton:getId()
    local fightMode
    
    if buttonId == 'fightOffensiveBox' then
        fightMode = FightOffensive
    elseif buttonId == 'fightBalancedBox' then
        fightMode = FightBalanced
    else
        fightMode = FightDefensive
    end
    g_game.setFightMode(fightMode)
end

function onSetChaseMode(self, checked)
    if checked == nil then return end
    local checked = checked:getId() == 'chaseModeBox'
    if checked then
        chaseMode = ChaseOpponent
    else
        chaseMode = DontChase
    end
    g_game.setChaseMode(chaseMode)
end

function onSetSafeFight(self, checked)
    g_game.setSafeFight(not checked)
end

function onMiniWindowClose()
    inventoryWindow:open()
    --inventoryButton:setOn(false)
end

function onInventoryMinimize(value)
    --soulPanel = inventoryWindow:recursiveGetChildById('soulPanel')
    capPanel = inventoryWindow:recursiveGetChildById('capPanel')
    optionsButton = inventoryWindow:recursiveGetChildById('optionsButton')
    exphButton = inventoryWindow:recursiveGetChildById('exphButton')
    stopButton = inventoryWindow:recursiveGetChildById('stopButton')
    miniwindowScrollBar = inventoryWindow:recursiveGetChildById('miniwindowScrollBar')
    miniwindowScrollBar:hide()
    
    minimizeButton = inventoryWindow:recursiveGetChildById('minButton')
    
    local function hideSlots(value)
        for slots = 1, 10 do
            local slot = inventoryWindow:recursiveGetChildById('slot' .. slots)
            if value then slot:hide() else slot:show() end
        end
    end

    if value then
        fightOffensiveBox:setMargin(0,78)
        fightBalancedBox:setMargin(0,58)
        fightDefensiveBox:setMargin(0,38)
        
        standModeBox:setMargin(22,78)
        chaseModeBox:setMargin(22,58)
        safeFightButton:setMargin(22,38)
        
        capPanel:setMargin(-120, 74)
        conditionPanel:setMargin(-100, 13)
        --soulPanel:setMargin(-100, 13)
        
        optionsButton:setMargin(4, 5)
        exphButton:setMargin(26, 5)
        
        --conditionPanel:setMargin(2, -62, 0, 0)
        stopButton:hide()
    else
        fightOffensiveBox:setMargin(15,24)
        fightBalancedBox:setMargin(35,24)
        fightDefensiveBox:setMargin(55,24)
        
        standModeBox:setMargin(15,1)
        chaseModeBox:setMargin(35,1)
        safeFightButton:setMargin(55,1)
        
        capPanel:setMargin(3,0)
        conditionPanel:setMargin(3,0)
        --soulPanel:setMargin(3, 0)
        
        optionsButton:setMargin(105,4)
        exphButton:setMargin(127,4)
        
        -- conditionPanel:setMargin(3,0)
        stopButton:show()
    end
    inventoryMinimized = value
    hideSlots(value)
    minimizeButton:setOn(value)
	inventoryWindow:setHeight(value and 51 or 155)
end
