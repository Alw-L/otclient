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

--[[local function toggle()
	local minimapWindow = controller.widgets.minimapWindow
	if minimapWindow:isOn() then
		minimapWindow:close()
	else
		minimapWindow:open()
	end
end]]--


local localPlayerEvent = EventController:new(LocalPlayer, {onPositionChange = updateCameraPosition})

controller = Controller:new()
controller:attachExternalEvent(localPlayerEvent)

function controller:onInit()
	--local minimapButton = modules.client_topmenu.addRightGameToggleButton('minimapButton', tr('Minimap') .. ' (Ctrl+M)', '/images/topbuttons/minimap', toggle)
	--minimapButton:setOn(true)

	local minimapWindow = g_ui.loadUI('minimap')

	minimapWindow:setContentMinimumHeight(120)
	minimapWindow:setContentMaximumHeight(120)
  	--minimapWindow:getChildById('minimizeButton'):hide()
 	--minimapWindow:getChildById('closeButton'):hide()
 	--minimapWindow:getChildById('miniwindowTopBar'):hide()
 	minimapWindow:getChildById('bottomResizeBorder'):hide()

	local minimapWidget = minimapWindow:recursiveGetChildById('minimap')

	local gameRootPanel = modules.game_interface.getRootPanel()
	self:bindKeyPress('Alt+Left', function() minimapWidget:move(1, 0)	end, gameRootPanel)
	self:bindKeyPress('Alt+Right', function() minimapWidget:move(-1, 0) end, gameRootPanel)
	self:bindKeyPress('Alt+Up', function() minimapWidget:move(0, 1) end, gameRootPanel)
	self:bindKeyPress('Alt+Down', function() minimapWidget:move(0, -1) end,	gameRootPanel)
	self:bindKeyPress('Alt+1', function() minimapWidget:zoomIn() end,	gameRootPanel)

	--self:bindKeyDown('Ctrl+M', toggle)
	
	--self:registerWidget('minimapButton', minimapButton)
	self:registerWidget('minimapWindow', minimapWindow)
	self:registerWidget('minimapWidget', minimapWidget)


	--minimapWindow:setup()
	localPlayerEvent:connect()
end

controller:onGameStart(function()
		controller.widgets.minimapWindow:setupOnStart()
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

		if g_resources.fileExists(minimapFile) then
			loadFnc(minimapFile)
		end

		local minimapWidget = controller.widgets.minimapWidget
		minimapWidget:load()
end)

controller:onGameEnd(function()	
		controller.widgets.minimapWindow:setParent(nil, true)
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
	--controller.widgets.minimapButton:setOn(true)
	localPlayerEvent:connect()
	localPlayerEvent:execute('onPositionChange')
end

function onMiniWindowClose()
	--controller.widgets.minimapButton:setOn(false)
	localPlayerEvent:disconnect()
end

function onResize()
	print('h')
end