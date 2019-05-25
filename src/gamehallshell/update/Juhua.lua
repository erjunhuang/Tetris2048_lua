local GameConfig = require(require("GameHallShellConfig").GAME_CONFIG_PATH)

local Juhua = class("Juhua", function()
  return display.newNode()
end)

local gamehallshell_res_path = GameConfig.res_path.."gamehallshell/"

local default_juhua1 = gamehallshell_res_path.."common/common_juhua.png"
local default_juhua2 = "Default/juhua.png"

function Juhua:ctor(filename)
  self._loadingBar = display.newSprite(filename or default_juhua1)
    :addTo(self)
  self:enableNodeEvents()
end

function Juhua:onEnter()
  self._loadingBar:runAction(cc.RepeatForever:create(cc.RotateBy:create(100, 36000)))
end

function Juhua:onExit()
  self:stopAllActions()
end

return Juhua