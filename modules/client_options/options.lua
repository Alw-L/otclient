local defaultOptions = {
    vsync = true,
    showFps = true,
    showPing = true,
    fullscreen = false,
    classicControl = false,
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
    enableLights = true,
    drawViewportEdge = false,
    floatingEffect = false,
    ambientLight = 0,
    displayNames = true,
    displayHealth = true,
    displayMana = true,
    displayText = true,
    dontStretchShrink = false,
    turnDelay = 30,
    hotkeyDelay = 30,
    crosshair = 'default',
    enableHighlightMouseTarget = true,
    antiAliasing = true,
    renderScale = 100,
    shadowFloorIntensity = 15,
    hpmpHealthCircle = true,
    hpmpManaCircle = true,
    hpmpExpCircle = false,
    hpmpSkillCircle = false,
    hpmpChooseSkill = 'magic',
    hpmpDistanceCenter = 0,
    hpmpCircleOpacity = 0.35,
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
    local enginesRadioGroup = UIRadioGroup.create()
    local ogl1 = graphicsPanel:getChildById('opengl1')
    local ogl2 = graphicsPanel:getChildById('opengl2')
    local dx9 = graphicsPanel:getChildById('directx9')
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
    
    circlePanel = g_ui.loadUI('hpmpcircle')
    optionsTabBar:addTab(tr('Health/Mana Circle'), circlePanel, '/images/optionstab/option_button')

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

function setupComboBox()
    crosshairCombobox = miscPanel:recursiveGetChildById('crosshair')

    crosshairCombobox:addOption('Disabled', 'disabled')
    crosshairCombobox:addOption('Default', 'default')
    crosshairCombobox:addOption('Full', 'full')

    crosshairCombobox.onOptionChange = function(comboBox, option)
        setOption('crosshair', comboBox:getCurrentOption().data)
    end

    renderScaleCombobox = graphicsPanel:recursiveGetChildById('renderScale')

    renderScaleCombobox:addOption('50%', 50)
    renderScaleCombobox:addOption('75%', 75)
    renderScaleCombobox:addOption('100%', 100)
    renderScaleCombobox:addOption('150%', 150)
    renderScaleCombobox:addOption('200%', 200)

    renderScaleCombobox.onOptionChange =
        function(comboBox, option)
            setOption('renderScale', comboBox:getCurrentOption().data)
        end
end

function setupCirclePanel()
    -- UI values
    chooseSkillComboBox = circlePanel:recursiveGetChildById(
                              'hpmpChooseSkill')

    -- ComboBox start values
    chooseSkillComboBox:addOption('magic')
    chooseSkillComboBox:addOption('fist')
    chooseSkillComboBox:addOption('club')
    chooseSkillComboBox:addOption('sword')
    chooseSkillComboBox:addOption('axe')
    chooseSkillComboBox:addOption('distance')
    chooseSkillComboBox:addOption('shielding')
    chooseSkillComboBox:addOption('fishing')
    -- Prevent skill overwritten before initialize
    skillsLoaded = true
end

function setup()
    setupComboBox()
    setupGraphicsEngines()
    setupCirclePanel()

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
        setOption('displayMana', false)
    else
        if not options['displayNames'] and not options['displayHealth'] then
            setOption('displayNames', true)
        else
            setOption('displayHealth', true)
            setOption('displayMana', true)
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
        graphicsPanel:getChildById('backgroundFrameRateLabel'):setText(tr(
                                                                           'Game framerate limit: %s',
                                                                           text))
        g_app.setMaxFps(v)
    elseif key == 'enableLights' then
        gameMapPanel:setDrawLights(value and options['ambientLight'] < 100)
        graphicsPanel:getChildById('ambientLight'):setEnabled(value)
        graphicsPanel:getChildById('ambientLightLabel'):setEnabled(value)
    elseif key == 'ambientLight' then
        graphicsPanel:getChildById('ambientLightLabel'):setText(tr(
                                                                    'Ambient light: %s%%',
                                                                    value))
        gameMapPanel:setMinimumAmbientLight(value / 100)
        gameMapPanel:setDrawLights(options['enableLights'])
    elseif key == 'shadowFloorIntensity' then
        graphicsPanel:getChildById('shadowFloorIntensityLevel'):setText(tr(
                                                                            'Shadow floor Intensity: %s%%',
                                                                            value))
        gameMapPanel:setShadowFloorIntensity(1 - (value / 100))
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
    elseif key == 'displayMana' then
        gameMapPanel:setDrawManaBar(value)
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
    elseif key == 'crosshair' then
        local crossPath = '/images/game/crosshair/'
        local newValue = value
        if newValue == 'disabled' then newValue = nil end
        gameMapPanel:setCrosshairTexture(
            newValue and crossPath .. newValue or nil)
        crosshairCombobox:setCurrentOptionByData(newValue, true)
    elseif key == 'enableHighlightMouseTarget' then
        gameMapPanel:setDrawHighlightTarget(value)
    elseif key == 'floorShadowing' then
        gameMapPanel:setFloorShadowingFlag(value)
        floorShadowingComboBox:setCurrentOptionByData(value, true)
    elseif key == 'antiAliasing' then
        gameMapPanel:setAntiAliasing(value)
    elseif key == 'renderScale' then
        gameMapPanel:setRenderScale(value)
        renderScaleCombobox:setCurrentOptionByData(value, true)
        if not force and value > 100 then
            displayInfoBox(tr('Warning'), tr(
                               'Rendering scale above 100%% will drop performance and visual bugs may occur.'))
        end
    elseif key == 'hpmpHealthCircle' then
        modules.game_healthcircle.setHealthCircle(value)
    elseif key == 'hpmpManaCircle' then
        modules.game_healthcircle.setManaCircle(value)
    elseif key == 'hpmpExpCircle' then
        modules.game_healthcircle.setExpCircle(value)
    elseif key == 'hpmpSkillCircle' then
        modules.game_healthcircle.setSkillCircle(value)
    elseif key == 'hpmpChooseSkill' then
        modules.game_healthcircle.setSkillType(value)
    elseif key == 'hpmpDistanceCenter' then
        circlePanel:getChildById('distFromCenLabel'):setText(
            tr('Distance: %s', value)
        )
        modules.game_healthcircle.setDistanceFromCenter(value)
    elseif key == 'hpmpCircleOpacity' then
        circlePanel:getChildById('opacityLabel'):setText(
            tr('Opacity: %s%%', value)
        )
        modules.game_healthcircle.setCircleOpacity(value / 100)
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