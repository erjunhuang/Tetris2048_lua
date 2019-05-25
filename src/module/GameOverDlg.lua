
local GameOverDlg = class("GameOverDlg",game.ui.Panel)
local GameConfig = import("..GameConfig")
local path = GameConfig.res_path
function GameOverDlg:ctor(playView)
   	GameOverDlg.super.ctor(self)
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
	titleTxt:setString("GAME OVER")
	titleTxt:setAnchorPoint(0.5,0.5)
	titleTxt:addTo(Bg)
	titleTxt:setPosition(BgSize.width*0.5,BgSize.height*0.925)

    self.playView = playView
    
    local numTxt = ccui.Text:create()
	numTxt:ignoreContentAdaptWithSize(true)
	numTxt:setTextAreaSize({width = 0, height = 0})
	numTxt:setFontName("tetris2048/res/Font/fangzheng.ttf")
	numTxt:setFontSize(50)
	numTxt:setString("Socre:"..self.playView.socre)
	numTxt:setAnchorPoint(0.5,0.5)
	numTxt:addTo(Bg)
	numTxt:setPosition(BgSize.width/2,BgSize.height/2+50)


	local backBtn = ccui.ImageView:create(path.."other/back.png")
 	backBtn:addTo(Bg)
 	backBtn:pos(BgSize.width/2-125,BgSize.height/2-150)
 	backBtn:setTouchEnabled(true)
 	backBtn:addTouchEventListener(handler(self,self.onBackClick))


	local restartBtn = ccui.ImageView:create(path.."other/Restart.png")
 	restartBtn:addTo(Bg)
 	restartBtn:pos(BgSize.width/2+125,BgSize.height/2-150)
 	restartBtn:setTouchEnabled(true)
 	restartBtn:addTouchEventListener(handler(self,self.onRestartClick))

 	game.SoundManager:playSound("Gameover")
end

function GameOverDlg:onBackClick( sender, eventType )
	self.playView.ctx.gameController:onBtnTouch(sender,eventType,function ( ... )
		self.playView.ctx.gameController:showMenuView()
		self:onClose()
	end)

end

function GameOverDlg:onRestartClick( sender, eventType )
	self.playView.ctx.gameController:onBtnTouch(sender,eventType,function ( ... )
		self.playView:initGame(true)
		self:onClose()
	end)
end

function GameOverDlg:onCleanup()
end
return GameOverDlg