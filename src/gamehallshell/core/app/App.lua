require("config")
require("cocos.init")
require("core.init")
require("app.init")
-- require "app.games.gamecommon.utils.init"

print("load app")
local App = class("App", cc.load("mvc").AppBase)

function App:ctor()
    App.super.ctor(self)
end

function App:run(gameId)

    cc.Device:setKeepScreenOn(true)
    game.gameManager:startGame(gameId or GameType.HALL)
end


function App:enterScene(scenePackageName,isPushScene,transitionType, time, more , ...)
    -- local scenePackageName = sceneName
    local sceneClass = require(scenePackageName)
    local scene = sceneClass.new(...)
    if not isPushScene then
        display.runScene(scene,transitionType, time, more)
    else
        display.pushScene(scene,transitionType, time, more)
    end

end


function App:onEnterBackground()
	App.super.onEnterBackground(self)
	-- audio.pauseMusic()
end

function App:onEnterForeground()
	App.super.onEnterForeground(self)
	-- audio.resumeMusic()
end


return App
