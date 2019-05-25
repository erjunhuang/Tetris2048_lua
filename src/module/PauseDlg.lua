
local PauseDlg = class("PauseDlg",game.ui.Panel)
local GameConfig = import("..GameConfig")
local path = GameConfig.res_path
function PauseDlg:ctor(playView)
   	PauseDlg.super.ctor(self)
  	self:enableNodeEvents()
    --背景
    local Bg = display.newSprite(path.."other/DialogBG.png")
    Bg:addTo(self)
    cc.bind(Bg,"touch"):setTouchEnabled(true)

    local BgSize = Bg:getContentSize()
    local titleTxt = ccui.Text:create()
	titleTxt:ignoreContentAdaptWithSize(true)
	titleTxt:setTextAreaSize({width = 0, height = 0})
	titleTxt:setFontName("tetris2048/res/Font/fangzheng.ttf")
	titleTxt:setFontSize(40)
	titleTxt:setString("PAUSE GAME")
	titleTxt:setAnchorPoint(0.5,0.5)
	titleTxt:addTo(Bg)
	titleTxt:setPosition(BgSize.width*0.5,BgSize.height*0.925)

    self.playView = playView

    local numTxt = ccui.Text:create()
	numTxt:ignoreContentAdaptWithSize(true)
	numTxt:setTextAreaSize({width = 500, height = 0})
	numTxt:setFontName("tetris2048/res/Font/fangzheng.ttf")
	numTxt:setFontSize(35)
	numTxt:setString("Whether to quit the game and return to the hall?")
	numTxt:setAnchorPoint(0.5,0.5)
	numTxt:addTo(Bg)
	numTxt:setPosition(BgSize.width/2,BgSize.height/2+50)

    local contentSize = Bg:getContentSize()
	local okBtn = ccui.ImageView:create(path.."other/OK.png")
 	okBtn:addTo(Bg)
 	okBtn:pos(BgSize.width/2-125,BgSize.height/2-150)
 	okBtn:setTouchEnabled(true)
 	okBtn:addTouchEventListener(handler(self,self.onOkClick))


	local cancleBtn = ccui.ImageView:create(path.."other/Cancle.png")
 	cancleBtn:addTo(Bg)
 	cancleBtn:pos(BgSize.width/2+125,BgSize.height/2-150)
 	cancleBtn:setTouchEnabled(true)
 	cancleBtn:addTouchEventListener(handler(self,self.onCancleClick))
end

function PauseDlg:onOkClick( sender, eventType )
	self.playView.ctx.gameController:onBtnTouch(sender,eventType,function ( ... )
		self.playView.ctx.gameController:showMenuView()
		self:onClose()
	end)
end

function PauseDlg:onCancleClick( sender, eventType )
	self.playView.ctx.gameController:onBtnTouch(sender,eventType,function ( ... )
		self.playView:startUpdate()
		self:onClose()
	end)
end

function PauseDlg:onCleanup()
end
return PauseDlg