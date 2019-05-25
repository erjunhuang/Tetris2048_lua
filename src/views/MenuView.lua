
local CURRENT_MODULE_NAME = ...
CURRENT_MODULE_NAME = game.getPkgName(CURRENT_MODULE_NAME)

local MenuView = class(MenuView,cc.load("mvc").ViewBase)

MenuView.LRESOURCE_FILENAME = CURRENT_MODULE_NAME ..  ".MenuView_UI"


local RankDlg = import("..module.RankDlg")
local SettingDlg = import("..module.SettingDlg")
function MenuView:ctor(ctx)
	MenuView.super.ctor(self)
	self:enableNodeEvents()
	self:doLayout()

	self.ctx = ctx


	local playBtnBtn = self.resourceNode_:getChildByName("playBtn")
    playBtnBtn:setTouchEnabled(true)
	playBtnBtn:addTouchEventListener(handler(self,self.onPlayBtnClick))

	local btnsCfg = 
    {
        {"settingBtn",handler(self,self.onSettingBtnClick)}, 
        {"rankBtn",handler(self,self.onRankBtnClick)},
    }
    
    local buttonView = self.resourceNode_:getChildByName("buttonView")
    
    for i,v in ipairs(btnsCfg) do
        local btn = buttonView:getChildByName(v[1])
        btn:setTouchEnabled(true)
 		btn:addTouchEventListener(v[2])
    end
end

function MenuView:onPlayBtnClick(sender, eventType )
	self.ctx.gameController:onBtnTouch(sender,eventType,function ( ... )
	 	self.ctx.gameController:showPlayView()
	end)
end

function MenuView:onSettingBtnClick( sender, eventType )
	self.ctx.gameController:onBtnTouch(sender,eventType,function ( ... )
		SettingDlg.new(self):showPanel_()
	end)
end

function MenuView:onRankBtnClick( sender, eventType )
	self.ctx.gameController:onBtnTouch(sender,eventType,function ( ... )
		RankDlg.new():showPanel_()
	end)
end

function MenuView:playShowAnim( ... )
	-- body
end

function MenuView:playHideAnim( ... )
	self:removeFromParent()
end

return MenuView

