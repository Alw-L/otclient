function init()
    optionsWindow = g_ui.displayUI('options')
    optionsWindow:hide()

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

function openOnTab(tab)
    modules.client_options.openOnTab(tab)
    hide()
end

function openDiscord()
    modules.client_options_revamp.toggle()
    g_platform.openUrl("http://discord.com/invite/7wrXvUD2Wa")
end