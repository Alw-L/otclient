
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
    musicSoundVolume = 0,
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
    antialiasingMode = 1,
    renderScale = 100,
    walkingKeysRepeatDelay = 10,
    smoothWalk = true,
    precisionWalk = false
}
local renderScaleCombobox
local antialiasingModeCombobox
local optionWindows = {}
local actualOptions = {}

local options = {'general', 'graphic', 'console'}
function init()
    optionsWindow = g_ui.displayUI('options')
    optionsWindow:hide()

    for i,v in pairs(options) do
        optionWindows[v] = g_ui.displayUI(v)
        optionWindows[v]:hide()
    end

    for k, v in pairs(defaultOptions) do
        g_settings.setDefault(k, v)
        actualOptions[k] = v
    end


    addEvent(function() setup() end)
end

function terminate()
    g_keyboard.unbindKeyDown('Ctrl+F')
    g_keyboard.unbindKeyDown('Ctrl+N')
    optionsWindow:destroy()
    optionsButton:destroy()
    -- audioButton:destroy()
    circlePanel:destroy()
end

local function setupGraphicsEngines()
    local enginesRadioGroup = UIRadioGroup.create()
    local ogl1 =  optionWindows['graphic']:getChildById('opengl1')
    local ogl2 =  optionWindows['graphic']:getChildById('opengl2')
    local dx9 =  optionWindows['graphic']:getChildById('directx9')
    enginesRadioGroup:addWidget(ogl1)
    enginesRadioGroup:addWidget(ogl2)
    enginesRadioGroup:addWidget(dx9)
    if g_window.getPlatformType() == 'WIN32-EGL' then
        enginesRadioGroup:selectWidget(dx9)
        ogl1:setEnabled(false)
        ogl2:setEnabled(false)
        dx9:setEnabled(true)
    else
        ogl1:setEnabled(g_graphics.isPainterEngineAvailable(1))
        ogl2:setEnabled(g_graphics.isPainterEngineAvailable(2))
        dx9:setEnabled(false)
        if g_graphics.getPainterEngine() == 2 then
            enginesRadioGroup:selectWidget(ogl2)
        else
            enginesRadioGroup:selectWidget(ogl1)
        end

        if not dx9:isEnabled() then
            dx9:hide()
        end

        if g_app.getOs() ~= 'windows' then dx9:hide() end
    end

    enginesRadioGroup.onSelectionChange =
        function(self, selected)
            if selected == ogl1 then
                setOption('painterEngine', 1)
            elseif selected == ogl2 then
                setOption('painterEngine', 2)
            end
        end
end
function setupComboBox()
    antialiasingModeCombobox = optionWindows['graphic']:recursiveGetChildById(
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
    setupGraphicsEngines()
    setupComboBox()
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

function hideOption(option)
    if optionWindows[option] then
        optionWindows[option]:hide()
        show()
    end
end
function openOnTab(tab)
    hide()
end

function openWindow(option)
    if optionWindows[option] ~= nil then
        hide()
        optionWindows[option]:show()
        optionWindows[option]:raise()
        optionWindows[option]:focus()

    end
end
function openDiscord()
    modules.client_options_revamp.toggle()
    g_platform.openUrl("http://discord.com/invite/7wrXvUD2Wa")
end


--- Option handler

function toggleOption(key) setOption(key, not getOption(key)) end

function setOption(key, value, force)
    if not force and actualOptions[key] == value then return end

    local gameMapPanel = modules.game_interface.getMapPanel()

    if key == 'vsync' then
        g_window.setVerticalSync(value)
    elseif key == 'showFps' then
        modules.game_interface.setFpsVisible(value)
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
        optionWindows['graphic']:getChildById('backgroundFrameRateLabel'):setText(tr(
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
    --[[
    elseif key == 'turnDelay' then
        optionWindows['general']:getChildById('turnDelayLabel'):setText(tr(
                                                                'Turn delay: %sms',
                                                                value))
    elseif key == 'hotkeyDelay' then
        optionWindows['general']:getChildById('hotkeyDelayLabel'):setText(tr(
                                                                  'Hotkey delay: %sms',
                                                                  value))
    elseif key == 'walkingKeysRepeatDelay' then
        local text, v = value, value
        if value < 0 or value >= 250 then v = 250 end
        optionWindows['general']:getChildById('walkingKeysRepeatDelayLabel'):setText(tr('Walking keys auto repeat delay: %s ms', text))
        if(g_settings.getBoolean('precisionWalk')) then
            local gameRootPanel = modules.game_interface.getRootPanel()
            gameRootPanel:setAutoRepeatDelay(value)
        end
        ]]--
    elseif key == 'smoothWalk' then
        local gameRootPanel = modules.game_interface.getRootPanel()
        local precButton = optionWindows['general']:getChildById('precisionWalk')
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
        local smoothButton = optionWindows['general']:getChildById('smoothWalk')
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
    elseif key == 'renderScale' then
    end
    -- change value for keybind updates
    for _, panel in pairs(optionWindows) do
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
    actualOptions[key] = value
end

function getOption(key) 
    return actualOptions[key] 
end

function toggleHotkey()
    modules.game_hotkeys.toggle()
    hide()
end

function hideHotkey(save)
    if(save ~= nil) then
        modules.game_hotkeys.save()
        modules.game_hotkeys.hide()
    else 
        modules.game_hotkeys.cancel()
    end
    show()
end