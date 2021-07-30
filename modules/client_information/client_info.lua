-- private variables
local infoWindow = nil
local websiteLink = "http://www.tibia.com"

local infoTexts = {
	[1] = "Tibia Client",
	[2] = "Version 1.0",
	[3] = "Copyright (C) 2020",
	[4] = "By Aurelion",
	[5] = "All rights reserved.",
	[6] = "Official Website",
	[7] = "www.tibia.com",
}

-- public functions
function init()
	infoWindow = g_ui.displayUI('client_info')
	infoWindow:hide()
	
	connect(g_game, { onGameStart = hide })
  
	setClientInfo()
end

function show()
	infoWindow:show()
	infoWindow:raise()
	infoWindow:focus()
end

function terminate()
	disconnect(g_game, { onGameStart = hide })

	infoWindow:destroy()
	infoWindow = nil
end

function toggle()
    if infoWindow:isVisible() then
        hide()
    else
		show()
    end
end

function hide()
    infoWindow:hide()
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
