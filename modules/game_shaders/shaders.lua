HOTKEY = 'Ctrl+U'
MAP_SHADERS = {
    {name = 'Map - Default', frag = nil},
    {name = 'Fog', frag = 'shaders/fragment/fog.frag', tex1 = 'images/clouds'},
    {name = 'Rain', frag = 'shaders/fragment/rain.frag'},
    {name = 'Snow', frag = 'shaders/fragment/snow.frag', tex1 = 'images/snow'},
    {name = 'Gray Scale', frag = 'shaders/fragment/grayscale.frag'},
    {name = 'Bloom', frag = 'shaders/fragment/bloom.frag'},
    {name = 'Sepia', frag = 'shaders/fragment/sepia.frag'},
    {name = 'Pulse', frag = 'shaders/fragment/pulse.frag'},
    {name = 'Old Tv', frag = 'shaders/fragment/oldtv.frag'},
    {name = 'Party', frag = 'shaders/fragment/party.frag'},
    {name = 'Radial Blur', frag = 'shaders/fragment/radialblur.frag'},
    {name = 'Zomg', frag = 'shaders/fragment/zomg.frag'},
    {name = 'Heat', frag = 'shaders/fragment/heat.frag'},
    {name = 'Noise', frag = 'shaders/fragment/noise.frag'}
}

OUTFIT_SHADERS = {
    {name = 'Outfit - Default', frag = nil},
    {name = 'Rainbow', frag = 'shaders/fragment/party.frag'},
    {
        name = 'Ghost',
        frag = 'shaders/fragment/radialblur.frag',
        drawColor = false
    }, {name = 'Jelly', frag = 'shaders/fragment/heat.frag'},
    {name = 'Fragmented', frag = 'shaders/fragment/noise.frag'}
}


-- Fix for texture offset drawing, adding walking offsets.
local dirs = {
    [0] = {x = 0, y = 1},
    [1] = {x = 1, y = 0},
    [2] = {x = 0, y = -1},
    [3] = {x = -1, y = 0},
    [4] = {x = 1, y = 1},
    [5] = {x = 1, y = -1},
    [6] = {x = -1, y = -1},
    [7] = {x = -1, y = 1}
}

shadersPanel = nil

function onWalkEvent()
    local player = g_game.getLocalPlayer()
    local dir = g_game.getLastWalkDir()
    local w = player:getWalkedDistance()
    w.x = w.x + dirs[dir].x
    w.y = w.y + dirs[dir].y
    player:setWalkedDistance(w);
end

function attachShaders()
    local map = modules.game_interface.getMapPanel()
    map:setMapShader(g_shaders.getShader('Default'))

    local player = g_game.getLocalPlayer()
    player:setOutfitShader(g_shaders.getShader('Default'))

    connect(g_game.getLocalPlayer(),
            {onWalkEnd = onWalkEvent --[[, onAutoWalk = function() end]] })
end

function init()
    connect(g_game, {onGameStart = attachShaders})

    if not g_graphics.canUseShaders() then return end

    g_ui.importStyle('shaders.otui')

    g_keyboard.bindKeyDown(HOTKEY, toggle)

    shadersPanel = g_ui.createWidget('ShadersPanel',
                                     modules.game_interface.getMapPanel())
    shadersPanel:hide()

    local mapComboBox = shadersPanel:getChildById('mapComboBox')
    mapComboBox.onOptionChange = function(combobox, option)
        local map = modules.game_interface.getMapPanel()
        map:setMapShader(g_shaders.getShader(option))
    end

    local outfitComboBox = shadersPanel:getChildById('outfitComboBox')
    outfitComboBox.onOptionChange = function(combobox, option)
        local player = g_game.getLocalPlayer()
        if player then
            player:setOutfitShader(g_shaders.getShader(option))
            local data = combobox:getCurrentOption().data
            player:setDrawOutfitColor(data.drawColor ~= false)
        end
    end


    local registerShader = function(opts, method)
        local fragmentShaderPath = resolvepath(opts.frag)
        local vertexShaderPath = resolvepath(
                                     opts.frag ~= nil and opts.vert or
                                         "shaders/core/vertex/default.vert")

        if fragmentShaderPath ~= nil then
            --  local shader = g_shaders.createShader()
            local shader = g_shaders.createFragmentShader(opts.name, opts.frag)

            if opts.tex1 then shader:addMultiTexture(opts.tex1) end
            if opts.tex2 then shader:addMultiTexture(opts.tex2) end

            -- Setup proper uniforms
            g_shaders[method](shader)
            g_shaders.registerShader(opts.name, shader)
        end
    end

    for _, opts in pairs(MAP_SHADERS) do
        registerShader(opts, 'setupMapShader')
        mapComboBox:addOption(opts.name, opts)
    end

    for _, opts in pairs(OUTFIT_SHADERS) do
        registerShader(opts, 'setupOutfitShader')
        outfitComboBox:addOption(opts.name, opts)
    end
end

function terminate()
    if g_game.getLocalPlayer() then
        disconnect(g_game.getLocalPlayer(),
                   {onWalkEnd = onWalkEvent, onAutoWalk = onAutoWalkEvent})
    end
    disconnect(g_game, {onGameStart = attachShaders})

    g_keyboard.unbindKeyDown(HOTKEY)
    shadersPanel:destroy()
    shadersPanel = nil
end

function toggle() shadersPanel:setVisible(not shadersPanel:isVisible()) end