local GameConfig = import(".GameConfig")


local MenuView = import(".views.MenuView")
local PlayView = import(".views.PlayView")

local GameController = import(".GameController")

local res_path = GameConfig.res_path
local GameScene = class("GameScene", game.base.BaseScene)



function GameScene:ctor()
	GameScene.super.ctor(self,"GameScene",GameController.new(self))


	--test---
	-- self:showMenuView_()

    self.touchLayer_ = display.newLayer(cc.c4b(0,0,0,55))
    :setContentSize(display.width,display.height)
    self:addChild(self.touchLayer_)

	self:onShowMenuView()

end



function GameScene:onShowMenuView( ... )
    print("GameScene:onShowMenuView===")
    if self.__playView then
        self.__playView:playHideAnim()
        self.__playView = nil
    end
    self:showMenuView_()
end

function GameScene:onShowPlayView( ... )
    print("GameScene:onShowPlayView===")
    if self.__menuView then
        self.__menuView:playHideAnim()
        self.__menuView = nil
    end
    self:showPlayView_()
end

function GameScene:onTouch(touch,event)
    if  self.__playView then
         self.__playView:onTouch(touch,event)
    end
end

function GameScene:onEnter()
   self:playBGMDelay(GameConfig.BGM)
   cc.bind(self.touchLayer_,"touch"):setTouchEnabled(true):addTouchListener(handler(self, self.onTouch))
end

function GameScene:playBGMDelay(bgm)
    self.__enterPlayBGMTimerId = self:performWithDelay(function(...)
        if type(bgm) == "table" and #bgm > 0 then
            local index = math.random(#bgm)
            self.__musicId = game.SoundManager:playBGMForGame(bgm[index],true)
        elseif type(bgm) == "string" then
            self.__musicId = game.SoundManager:playBGMForGame(bgm,true)
        end
    end, 2)
end

function GameScene:stopBGMTimer()
    if self.__enterPlayBGMTimerId then
        self:stopAction(self.__enterPlayBGMTimerId)
        self.__enterPlayBGMTimerId = nil
    end
end

function GameScene:showMenuView_( ... )
	 self.__menuView = MenuView.new(self.__controller.ctx)
        :addTo(self.touchLayer_)
    self.__menuView:playShowAnim()

end


function GameScene:showPlayView_( ... )
	self.__playView = PlayView.new(self.__controller.ctx)
        :addTo(self.touchLayer_)
    self.__playView:playShowAnim()
end





function GameScene:onCleanup( ... )
    GameScene.super.onCleanup(self)
    game.SoundManager:stopMusic(self.__musicId)
end
return GameScene

