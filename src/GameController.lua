local GameConfig = import(".GameConfig")
local GameModel = import(".model.GameModel")
local GameController = class("GameController",game.base.BaseController)

function GameController:ctor(scene)
	GameController.super.ctor(self,scene)    

    self:init()

    
end

function GameController:dispose()

    GameController.super.dispose(self)
end


function GameController:init()
	local ctx = {}
    ctx.gameController = self
    ctx.scene = self.__scene

    ctx.model = GameModel.new(ctx)
    
    ctx.export = function(target)
        if target ~= ctx.model then
            target.ctx = ctx
            for k, v in pairs(ctx) do
                if k ~= "export" and v ~= target then
                    target[k] = v
                end
            end
        else
            rawset(target, "ctx", ctx)
            for k, v in pairs(ctx) do
                if k ~= "export" and v ~= target then
                    rawset(target, k, v)
                end
            end
        end
        return target
    end

    ctx.export(self)
    ctx.export(ctx.model)

end




function GameController:showMenuView()
    self.__scene:onShowMenuView()
end


function GameController:showPlayView()
    self.__scene:onShowPlayView()
end

function GameController:onBtnTouch( sender, eventType,callBack)
    if eventType == ccui.TouchEventType.began then
        transition.scaleTo(sender, {scale = 1.1, time = 0.1})
        game.SoundManager:playSound("btnClick/Balloon_003")
    elseif eventType == ccui.TouchEventType.ended or eventType == ccui.TouchEventType.canceled then
        transition.scaleTo(sender, {scale = 1, time = 0.1,delay=0.1})
        if callBack then
            callBack()
        end
    end
end




return GameController