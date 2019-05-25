
local RankDlg = class("RankDlg",game.ui.Panel)
local GameConfig = import("..GameConfig")
local path = GameConfig.res_path
function RankDlg:ctor()
   	RankDlg.super.ctor(self)
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
	titleTxt:setString("GAME DATA")
	titleTxt:setAnchorPoint(0.5,0.5)
	titleTxt:addTo(Bg)
	titleTxt:setPosition(BgSize.width*0.5,BgSize.height*0.925)

    local hightSocre = cc.UserDefault:getInstance():getIntegerForKey("2048HightScore")

    local numTxt = ccui.Text:create()
	numTxt:ignoreContentAdaptWithSize(true)
	numTxt:setTextAreaSize({width = 0, height = 0})
	numTxt:setFontName("tetris2048/res/Font/fangzheng.ttf")
	numTxt:setFontSize(50)
	numTxt:setString("HightScore:"..hightSocre)
	numTxt:setAnchorPoint(0.5,0.5)
	numTxt:addTo(Bg)
	numTxt:setPosition(BgSize.width/2,BgSize.height/2)
end

function RankDlg:onCleanup()
end
return RankDlg