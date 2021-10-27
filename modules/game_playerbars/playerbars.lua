playerBarsWindow = nil
skillsButton = nil
battleButton = nil
vipButton = nil

function init()

connect(g_game, {
    onGameStart = online,
    onGameEnd = offline
})

  playerBarsWindow = g_ui.loadUI('playerbars')
  playerBarsWindow:disableResize()

  skillsButton = playerBarsWindow:recursiveGetChildById('SkillsButton')
  battleButton = playerBarsWindow:recursiveGetChildById('BattleButton')
  vipButton = playerBarsWindow:recursiveGetChildById('VipButton')

  connect(skillsButton, {onClick = onClickSkills})
  connect(battleButton, {onClick = onClickBattle})
  connect(vipButton, {onClick = onClickVip})
  
  playerBarsWindow:getChildById('contentsPanel'):setMarginTop(3)
  
  playerBarsWindow:setup()
  if g_game.isOnline() then
      online()
  end
end

function terminate()
  disconnect(g_game, {
      onGameStart = online,
      onGameEnd = offline
  })
  disconnect(skillsButton, {onClick = onClickSkills})
  disconnect(battleButton, {onClick = onClickBattle})
  disconnect(vipButton, {onClick = onClickVip})

  playerBarsWindow:destroy()
end

function offline()
  local lastPlayerBars = g_settings.getNode('LastPlayerBars')
  if not lastPlayerBars then
    lastPlayerBars = {}
  end

  local player = g_game.getLocalPlayer()
  if player then
    local char = g_game.getCharacterName()

    lastPlayerBars[char] = {
      checkSkill = getCheckedButtons(skillsButton),
      checkBattle = getCheckedButtons(battleButton),
      checkVip = getCheckedButtons(vipButton),
    }
    g_settings.setNode('LastPlayerBars', lastPlayerBars)
  end
end

function online()
  playerBarsWindow:setupOnStart() -- load character window configuration
  local player = g_game.getLocalPlayer()
  if player then
    local char = g_game.getCharacterName()
    local lastPlayerBars = g_settings.getNode('LastPlayerBars')
    if not table.empty(lastPlayerBars) then
      if lastPlayerBars[char] then

         skillsButton:setChecked(lastPlayerBars[char].checkSkill)
         battleButton:setChecked(lastPlayerBars[char].checkBattle)
         vipButton:setChecked(lastPlayerBars[char].checkVip)

      end
    end
  end
end

function getCheckedButtons(button)
 if button:isChecked() then
   return 1
 else
   return nil
 end
end

function onMiniWindowClose()
  playerBarsWindow:open()
end

function onClickSkills()
  modules.game_skills.toggle()
end
function onClickBattle()
  modules.game_battle.toggle()
end
function onClickVip()
  modules.game_viplist.toggle()
end

