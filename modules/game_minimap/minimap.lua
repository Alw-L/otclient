local otmm = true
local fullmapView = false
local oldZoom = nil
local oldPos = nil

local function updateCameraPosition()
	local player = g_game.getLocalPlayer()
	if not player then
		return
	end

	local pos = player:getPosition()
	if not pos then
		return
	end

	local minimapWidget = controller.widgets.minimapWidget
	if minimapWidget:isDragging() then
		return
	end

	if not fullmapView then
		minimapWidget:setCameraPosition(pos)
	end

	minimapWidget:setCrossPosition(pos)
end

local function toggleMinimapWidgetButtons(state)
	local minimapWidget = controller.widgets.minimapWidget
	if minimapWidget then
		minimapWidget:getChildById('floorUp'):setVisible(state)
		minimapWidget:getChildById('floorDown'):setVisible(state)
		minimapWidget:getChildById('zoomIn'):setVisible(state)
		minimapWidget:getChildById('zoomOut'):setVisible(state)
		minimapWidget:getChildById('reset'):setVisible(state)
	end
end

local function toggleFullMap()
	local minimapWindow = controller.widgets.minimapWindow
	local minimapWidget = controller.widgets.minimapWidget
	if fullmapView then
		minimapWidget:setParent(minimapWindow:getChildById('contentsPanel'))
		minimapWidget:addAnchor(AnchorTop, 'parent', AnchorTop)
		minimapWidget:addAnchor(AnchorLeft, 'parent', AnchorLeft)
		minimapWidget:setSize({width = 121, height = 106})
		minimapWidget:setMarginLeft(8)
		minimapWidget:setMarginTop(6)
		toggleMinimapWidgetButtons(false)
	else
		minimapWidget:setParent(modules.game_interface.getRootPanel())
		minimapWidget:setMargin(0)
		minimapWidget:fill('parent')
		toggleMinimapWidgetButtons(true)
	end

	fullmapView = not fullmapView
	minimapWidget:setAlternativeWidgetsVisible(fullmapView)

	local zoom = oldZoom or 0
	local pos = oldPos or minimapWidget:getCameraPosition()
	oldZoom = minimapWidget:getZoom()
	oldPos = minimapWidget:getCameraPosition()
	minimapWidget:setZoom(zoom)
	minimapWidget:setCameraPosition(pos)
end

local localPlayerEvent = EventController:new(LocalPlayer, {
    onPositionChange = updateCameraPosition
})

controller = Controller:new()
controller:attachExternalEvent(localPlayerEvent)

function controller:onInit()
    local minimapWindow = g_ui.loadUI('minimap', modules.game_interface.getTopRightPanel())   

    local minimapWidget = minimapWindow:recursiveGetChildById('minimap')

    local gameRootPanel = modules.game_interface.getRootPanel()
    self:bindKeyPress('Alt+Left', function() minimapWidget:move(1, 0) end,
                      gameRootPanel)
    self:bindKeyPress('Alt+Right', function() minimapWidget:move(-1, 0) end,
                      gameRootPanel)
    self:bindKeyPress('Alt+Up', function() minimapWidget:move(0, 1) end,
                      gameRootPanel)
    self:bindKeyPress('Alt+Down', function() minimapWidget:move(0, -1) end,
                      gameRootPanel)

    --self:bindKeyDown('Ctrl+M', toggle)
    --self:bindKeyDown('Ctrl+Shift+M', toggleFullMap)

    --self:registerWidget('minimapButton', minimapButton)
    self:registerWidget('minimapWindow', minimapWindow)
    self:registerWidget('minimapWidget', minimapWidget)
    toggleMinimapWidgetButtons(false)

    --minimapWindow:setup()

    localPlayerEvent:connect()
end

controller:onGameStart(function()
    --controller.widgets.minimapWindow:setupOnStart() -- load character window configuration

    -- Load Map
    g_minimap.clean()

    local minimapFile = '/minimap'
    local loadFnc = nil

    if otmm then
        minimapFile = minimapFile .. '.otmm'
        loadFnc = g_minimap.loadOtmm
    else
        minimapFile = minimapFile .. '_' .. g_game.getClientVersion() .. '.otcm'
        loadFnc = g_map.loadOtcm
    end

    if g_resources.fileExists(minimapFile) then loadFnc(minimapFile) end

    local minimapWidget = controller.widgets.minimapWidget
    minimapWidget:load()
end)

controller:onGameEnd(function()

    -- Save Map
    if otmm then
        g_minimap.saveOtmm('/minimap.otmm')
    else
        g_map.saveOtcm('/minimap_' .. g_game.getClientVersion() .. '.otcm')
    end

    local minimapWidget = controller.widgets.minimapWidget
    minimapWidget:save()
end)

function onMiniWindowOpen()
   -- controller.widgets.minimapButton:setOn(true)
    localPlayerEvent:connect()
    localPlayerEvent:execute('onPositionChange')
end

function onMiniWindowClose()
    --controller.widgets.minimapButton:setOn(false)
    localPlayerEvent:disconnect()
end
