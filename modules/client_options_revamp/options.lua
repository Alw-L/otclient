local optionWindows = {}
local options = {'general', 'graphic'}
function init()
    optionsWindow = g_ui.displayUI('options')
    optionsWindow:hide()
    optionWindows['general'] = g_ui.displayUI('general')
    optionWindows['general']:hide()

    for i,v in pairs(options) do
        optionWindows[v] = g_ui.displayUI(v)
        optionWindows[v]:hide()
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

function setup()
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

function hideGeneral()
    general:hide()
end

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