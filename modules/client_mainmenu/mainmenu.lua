mainmenuWindow = nil

function init()
  
  connect(g_game, { onGameStart = mainMenuHide,
                    onGameEnd = mainMenuShow })

  mainmenuWindow = g_ui.displayUI('mainmenu')
  --mainmenuWindow:disableResize()
  --mainmenuWindow:setup()
end

function terminate()
  disconnect(g_game, { onGameStart = mainMenuHide,
                       onGameEnd = mainMenuShow })

  mainmenuWindow:destroy()
  mainmenuWindow = nil
end

function toggle()
  if mainmenuWindow:isVisible() then
    mainmenuWindow:hide()
  else
    mainmenuWindow:show()
  end
end

function mainMenuHide()
  mainmenuWindow:hide()
end
function mainMenuShow()
  mainmenuWindow:show()
  --print('show')
end

--function offline()
  --healthInfoWindow:recursiveGetChildById('conditionPanel'):destroyChildren()
--end