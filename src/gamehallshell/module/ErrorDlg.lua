local GameConfig = require(require('GameHallShellConfig').GAME_CONFIG_PATH)
local gamehallshell_res_path = GameConfig.res_path .. 'gamehallshell/'

local ErrorDlg = class('ErrorDlg', game.ui.Panel)

ErrorDlg.WIDTH = 1280
ErrorDlg.HEITHT = 720
local respath = gamehallshell_res_path .. 'error/'

function ErrorDlg:ctor(msg)
    print('ErrorDlg:ctor', msg)
    local exinfo = ''
    if game and game.gameManager then
        exinfo = exinfo .. ' hallversion:' .. tostring(game.gameManager:getGameVersion(GameType.HALL))
        local curGameId = game.gameManager:getCurGameId()
        if checkint(curGameId) > 0 and (checkint(curGameId) ~= checkint(GameType.HALL)) then
            exinfo = exinfo .. ' gameversion:' .. tostring(game.gameManager:getGameVersion(curGameId))
        end
    end
    if appconfig and appconfig.appid then
        exinfo = exinfo .. ' appid:' .. tostring(appconfig.appid)
    end
    if device and device.platform then
        exinfo = exinfo .. ' platform:' .. tostring(device.platform)
    end
    if game and game.userData then
        exinfo = exinfo .. ' mid:' .. tostring(game.userData['aUser.mid'])
    end
    exinfo = exinfo .. os.date(' time:%m/%d %H:%M', os.time())
    if exinfo ~= '' then
        msg = exinfo .. '\n' .. msg
    end

    ErrorDlg.super.ctor(self, {ErrorDlg.WIDTH, ErrorDlg.HEITHT})

    local touchLayer = display.newLayer():size(display.width, display.height):pos(-display.cx, -display.cy):addTo(self)
    cc.bind(touchLayer, 'touch'):setTouchEnabled(true)

    local bg = display.newSprite(respath .. 'bg.jpg'):addTo(self)

    bg:setScaleX(display.width / bg:getContentSize().width)
    bg:setScaleY(display.height / bg:getContentSize().height)

    display.newSprite(respath .. 'people.png'):pos(-200, 0):addTo(self)

    display.newSprite(respath .. 'tip.png'):align(display.LEFT_CENTER, 0, 55):addTo(self)

    game.ui.ScaleButton.new(respath .. 'exit.png', 1.05):addTo(self):align(display.LEFT_CENTER, 0, -65):onClick(
        function(...)
            self:hidePanel_(false)
            cc.Director:getInstance():restart()
        end
    )

    game.ui.ColorButton.new(respath .. 'info.png'):addTo(self):align(display.LEFT_BOTTOM, 300, -55 - 41):onClick(
        function(...)
            if self.infoNode then
                self.infoNode:show()
                return
            end

            self.infoNode =
                display.newScale9Sprite(
                respath .. 'info_bg.png',
                0,
                0,
                cc.size(display.width * 0.8, display.height * 0.8)
            ):addTo(self)

            display.newTTFLabel(
                {
                    size = 20,
                    text = msg,
                    color = cc.c3b(0xff, 0x00, 0x00),
                    dimensions = cc.size(display.width * 0.8 - 15, display.height * 0.8 - 15)
                }
            ):addTo(self.infoNode):align(display.LEFT_TOP, 15, display.height * 0.8 - 15)

            game.ui.ColorButton.new(respath .. 'close.png'):addTo(self.infoNode):pos(
                display.width * 0.8,
                display.height * 0.8 - 5
            ):onClick(
                function(...)
                    self.infoNode:hide()
                end
            )
        end
    )

    --游戏场景报错
    if game and game.runningScene and game.runningScene.__cname == 'GameScene' and game.server and game.server.sendMsg then
        game.ui.ScaleButton.new(respath .. 'diss.png', 1.05):addTo(self):align(display.LEFT_CENTER, 0, -65 - 100):onClick(
            function(...)
                if game and game.server and game.server.sendMsg then
                    game.server:sendMsg(0x1802)
                    game.server:sendMsg(0x1713)
                end
            end
        )
    end
end

function ErrorDlg:showPanel_(...)
    --报错以后，停止向逻辑层发包
    if game and game.server and game.server.pause then
        game.server:pause()
    end

    return ErrorDlg.super.showPanel_(self, ...)
end

return ErrorDlg
