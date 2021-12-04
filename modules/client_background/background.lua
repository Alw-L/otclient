-- private variables
local background
local infoWindow
local clientVersionLabel

local accesAccountLink = "http://delvine.net/?subtopic=createaccount"
local websiteLink = "http://delvine.net"

local infoTexts = {
 [1] = "Delvine Client",
 [2] = "Version 1.0",
 [3] = "Copyright (C) 2021",
 [4] = "",
 [5] = "All rights reserved.",
 [6] = "Official Website",
 [7] = "Delvine.net",
}

-- public functions
function init()
    background = g_ui.displayUI('background')
    background:lower()

    infoWindow = background:getChildById('infoBox')
    infoWindow:hide()

    if not g_game.isOnline() then
        addEvent(function() g_effects.fadeIn(infoWindow, 1500) end)
    end

    connect(g_game, {onGameStart = hide})
    connect(g_game, {onGameEnd = show})

    setClientInfo()
end

function terminate()
    disconnect(g_game, {onGameStart = hide})
    disconnect(g_game, {onGameEnd = show})

    g_effects.cancelFade(background:getChildById('infoBox'))
    infoWindow:destroy()
    background:destroy()

    background = nil
    clientVersionLabel = nil
end

function hide() background:hide() end

function show() background:show() end

function hideVersionLabel() background:getChildById('clientVersionLabel'):hide() end

function setVersionText(text) clientVersionLabel:setText(text) end

function getBackground() return background end

function infoShow()
  if not infoWindow:isVisible() then
     infoWindow:setVisible(true)
  end
end

function infoHide()
  if infoWindow:isVisible() then
    infoWindow:setVisible(false)
  end
end

function accesAccount()
   g_platform.openUrl(accesAccountLink)
end

function openWebsite()
   g_platform.openUrl(websiteLink)
end

function setClientInfo()
  for label, text in pairs(infoTexts) do 
    local label = infoWindow:getChildById('infoLabel' .. label)
    label:setText(text)
  end
end

function infoShow()
  if not infoWindow:isVisible() then
     infoWindow:setVisible(true)
  end
end

function infoHide()
  if infoWindow:isVisible() then
    infoWindow:setVisible(false)
  end
end

function accesAccount()
   g_platform.openUrl(accesAccountLink)
end

function openWebsite()
   g_platform.openUrl(websiteLink)
end

function setClientInfo()
  for label, text in pairs(infoTexts) do 
    local label = infoWindow:getChildById('infoLabel' .. label)
    label:setText(text)
  end
end
