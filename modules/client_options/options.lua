local defaultOptions = {
    vsync = true,
    showFps = true,
    showPing = true,
    fullscreen = false,
    classicControl = true,
    smartWalk = false,
    preciseControl = false,
    autoChaseOverride = true,
    moveStack = false,
    showStatusMessagesInConsole = true,
    showEventMessagesInConsole = true,
    showInfoMessagesInConsole = true,
    showTimestampsInConsole = true,
    showLevelsInConsole = true,
    showPrivateMessagesInConsole = true,
    showPrivateMessagesOnScreen = true,
    showLeftPanel = false,
    showRightExtraPanel = false,
    openMaximized = false,
    backgroundFrameRate = 201,
    painterEngine = 0,
    enableAudio = false,
    enableMusicSound = false,
    musicSoundVolume = 100,
    drawViewportEdge = false,
    floatingEffect = false,
    displayNames = true,
    displayHealth = true,
    displayMana = true,
    displayText = true,
    dontStretchShrink = false,
    turnDelay = 30,
    hotkeyDelay = 30,
    antiAliasing = true,
    renderScale = 100,
    walkingKeysRepeatDelay = 10,
    smoothWalk = true,
    precisionWalk = false
}

local optionsWindow
local optionsButton
local optionsTabBar
local options = {}
local miscPanel
local generalPanel
local consolePanel
local graphicsPanel
-- local soundPanel
-- local audioButton

local crosshairCombobox
local renderScaleCombobox
local chooseSkillComboBox

skillsLoaded = false

local function setupGraphicsEngines()
end

function init()
    for k, v in pairs(defaultOptions) do
        g_settings.setDefault(k, v)
        options[k] = v
    end

    optionsWindow = g_ui.displayUI('options')
    optionsWindow:hide()

    optionsTabBar = optionsWindow:getChildById('optionsTabBar')
    optionsTabBar:setContentWidget(optionsWindow:getChildById(
                                       'optionsTabContent'))

    g_keyboard.bindKeyDown('Ctrl+F',
                           function() toggleOption('fullscreen') end)
    g_keyboard.bindKeyDown('Ctrl+N', toggleDisplays)

    generalPanel = g_ui.loadUI('general')
    optionsTabBar:addTab(tr('General'), generalPanel, '/images/optionstab/option_button')

    graphicsPanel = g_ui.loadUI('graphics')
    optionsTabBar:addTab(tr('Graphics'), graphicsPanel,
                         '/images/optionstab/option_button')

    consolePanel = g_ui.loadUI('console')
    optionsTabBar:addTab(tr('Console'), consolePanel,
                         '/images/optionstab/option_button')

    miscPanel = g_ui.loadUI('misc')
    optionsTabBar:addTab(tr('Misc'), miscPanel, '/images/optionstab/option_button')

    -- soundPanel = g_ui.loadUI('audio')
    -- optionsTabBar:addTab(tr('Audio'), soundPanel, '/images/optionstab/option_button')

    --optionsTabBar:addSeparator()
    
    --optionsTabBar:addButton(tr('Export Map'), nil, '/images/optionstab/option_button')
    
    optionsTabBar:addSeparator()


    optionsButton = modules.client_topmenu.addLeftButton('optionsButton',
                                                         tr('Options'),
                                                         '/images/topbuttons/options',
                                                         toggle)
    -- audioButton = modules.client_topmenu.addLeftButton('audioButton',
    --                                                    tr('Audio'),
    --                                                    '/images/topbuttons/audio',
    --                                                    function()
    --     toggleOption('enableAudio')
    -- end)

    --addEvent(function() setup() end)
end

function terminate()
    g_keyboard.unbindKeyDown('Ctrl+F')
    g_keyboard.unbindKeyDown('Ctrl+N')
    optionsWindow:destroy()
    optionsButton:destroy()
    -- audioButton:destroy()
    circlePanel:destroy()
end

function setupComboBox()
    antialiasingModeCombobox = graphicsPanel:recursiveGetChildById(
                                   'antialiasingMode')

    antialiasingModeCombobox:addOption('None', 0)
    antialiasingModeCombobox:addOption('Antialiasing', 1)
    antialiasingModeCombobox:addOption('Smooth Retro', 2)

    antialiasingModeCombobox.onOptionChange =
        function(comboBox, option)
            setOption('antialiasingMode', comboBox:getCurrentOption().data)
        end
end

function setup()
    --setupComboBox()
    --setupGraphicsEngines()

    -- load options
    for k, v in pairs(defaultOptions) do
        if type(v) == 'boolean' then
            setOption(k, g_settings.getBoolean(k), true)
        elseif type(v) == 'number' then
            setOption(k, g_settings.getNumber(k), true)
        elseif type(v) == 'string' then
            setOption(k, g_settings.getString(k), true)
        end
    end
end

function toggle()
    if optionsWindow:isVisible() then
        hide()
    else
        show()
    end
end

function show()
    optionsWindow:show()
    optionsWindow:raise()
    optionsWindow:focus()
end

function hide() optionsWindow:hide() end

function toggleDisplays()
    if options['displayNames'] and options['displayHealth'] and
        options['displayMana'] then
        setOption('displayNames', false)
    elseif options['displayHealth'] then
        setOption('displayHealth', false)
    else
        if not options['displayNames'] and not options['displayHealth'] then
            setOption('displayNames', true)
        else
            setOption('displayHealth', true)
        end
    end
end

function toggleOption(key) setOption(key, not getOption(key)) end

function setOption(key, value, force)
    if not force and options[key] == value then return end

    local gameMapPanel = modules.game_interface.getMapPanel()

    if key == 'vsync' then
        g_window.setVerticalSync(value)
    elseif key == 'showFps' then
        modules.client_topmenu.setFpsVisible(value)
    elseif key == 'optimizeFps' then
        g_app.optimize(value)
    elseif key == 'forceEffectOptimization' then
        g_app.forceEffectOptimization(value)
    elseif key == 'drawEffectOnTop' then
        g_app.setDrawEffectOnTop(value)
    elseif key == 'showPing' then
        modules.game_interface.setPingVisible(value)
    elseif key == 'fullscreen' then
        g_window.setFullscreen(value)
    elseif key == 'enableAudio' then
        if g_sounds then g_sounds.setAudioEnabled(value) end
        -- if value then
        --     audioButton:setIcon('/images/topbuttons/audio')
        -- else
        --     audioButton:setIcon('/images/topbuttons/audio_mute')
        -- end
    elseif key == 'enableMusicSound' then
        if g_sounds then
            g_sounds.getChannel(SoundChannels.Music):setEnabled(value)
        end
    elseif key == 'musicSoundVolume' then
        if g_sounds then
            g_sounds.getChannel(SoundChannels.Music):setGain(value / 100)
        end
        -- soundPanel:getChildById('musicSoundVolumeLabel'):setText(tr(
                                                                    --  'Music volume: %d',
                                                                    --  value))
    elseif key == 'showLeftPanel' then
        modules.game_interface.getLeftPanel():setOn(value)
    elseif key == 'showRightExtraPanel' then
        modules.game_interface.getRightExtraPanel():setOn(value)
    elseif key == 'backgroundFrameRate' then
        local text, v = value, value
        if value <= 0 or value >= 201 then
            text = 'max'
            v = 0
        end
        graphicsPanel:getChildById('backgroundFrameRateLabel'):setText(tr(
                                                                           'Game framerate limit: %s',
                                                                           text))
        g_app.setMaxFps(v)
    elseif key == 'drawViewportEdge' then
        gameMapPanel:setDrawViewportEdge(value)
    elseif key == 'floatingEffect' then
        g_map.setFloatingEffect(value)
    elseif key == 'painterEngine' then
        g_graphics.selectPainterEngine(value)
    elseif key == 'displayNames' then
        gameMapPanel:setDrawNames(value)
    elseif key == 'displayHealth' then
        gameMapPanel:setDrawHealthBars(value)
    elseif key == 'displayText' then
        gameMapPanel:setDrawTexts(value)
    elseif key == 'dontStretchShrink' then
        addEvent(function() modules.game_interface.updateStretchShrink() end)
    elseif key == 'preciseControl' then
        g_game.setScheduleLastWalk(not value)
    elseif key == 'turnDelay' then
        generalPanel:getChildById('turnDelayLabel'):setText(tr(
                                                                'Turn delay: %sms',
                                                                value))
    elseif key == 'hotkeyDelay' then
        generalPanel:getChildById('hotkeyDelayLabel'):setText(tr(
                                                                  'Hotkey delay: %sms',
                                                                  value))
    elseif key == 'walkingKeysRepeatDelay' then
        local text, v = value, value
        if value < 0 or value >= 250 then v = 250 end
        generalPanel:getChildById('walkingKeysRepeatDelayLabel'):setText(tr('Walking keys auto repeat delay: %s ms', text))
        if(g_settings.getBoolean('precisionWalk')) then
            local gameRootPanel = modules.game_interface.getRootPanel()
            gameRootPanel:setAutoRepeatDelay(value)
        end
    elseif key == 'smoothWalk' then
        local gameRootPanel = modules.game_interface.getRootPanel()
        local precButton = generalPanel:getChildById('precisionWalk')
        if value then
            gameRootPanel:setAutoRepeatDelay(200)
            if precButton:isChecked() then
                precButton:setChecked(false)
            end
        else
            if not precButton:isChecked() then
                precButton:setChecked(true)
                gameRootPanel:setAutoRepeatDelay(g_settings.getNumber('walkingKeysRepeatDelay'))
            end
        end
    elseif key == 'precisionWalk' then
        local smoothButton = generalPanel:getChildById('smoothWalk')
        local gameRootPanel = modules.game_interface.getRootPanel()
        if value then
            gameRootPanel:setAutoRepeatDelay(g_settings.getNumber('walkingKeysRepeatDelay'))
            if smoothButton:isChecked() then
                smoothButton:setChecked(false)
            end
        else
            gameRootPanel:setAutoRepeatDelay(200)
            if not smoothButton:isChecked() then
                smoothButton:setChecked(true)
            end
        end
    elseif key == 'enableHighlightMouseTarget' then
        gameMapPanel:setDrawHighlightTarget(value)
    elseif key == 'floorShadowing' then
        gameMapPanel:setFloorShadowingFlag(value)
        floorShadowingComboBox:setCurrentOptionByData(value, true)
    elseif key == 'antialiasingMode' then
        gameMapPanel:setAntiAliasingMode(value)
        antialiasingModeCombobox:setCurrentOptionByData(value, true)
    end
    -- change value for keybind updates
    for _, panel in pairs(optionsTabBar:getTabsPanel()) do
        local widget = panel:recursiveGetChildById(key)
        if widget then
            if widget:getStyle().__class == 'UICheckBox' then
                widget:setChecked(value)
            elseif widget:getStyle().__class == 'UIScrollBar' then
                widget:setValue(value)
            end
            break
        end
    end

    g_settings.set(key, value)
    options[key] = value
end

function getOption(key) return options[key] end

function addTab(name, panel, icon) optionsTabBar:addTab(name, panel, icon) end

function removeTab(v)
    if type(v) == "string" then v = optionsTabBar:getTab(v) end

    optionsTabBar:removeTab(v)
end

function addButton(name, func, icon) optionsTabBar:addButton(name, func, icon) end

function openOnTab(tab)
    show()
    optionsTabBar:selectTab(optionsTabBar:getTab(tab)) 
end