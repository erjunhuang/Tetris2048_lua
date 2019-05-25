
local SettingDlg = class("SettingDlg",game.ui.Panel)
local GameConfig = import("..GameConfig")
local path = GameConfig.res_path
function SettingDlg:ctor(content)
   	SettingDlg.super.ctor(self)
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
	titleTxt:setString("GAME SETTING")
	titleTxt:setAnchorPoint(0.5,0.5)
	titleTxt:addTo(Bg)
	titleTxt:setPosition(BgSize.width*0.5,BgSize.height*0.925)

    self.content = content

 --    local numTxt = ccui.Text:create()
	-- numTxt:ignoreContentAdaptWithSize(true)
	-- numTxt:setTextAreaSize({width = 450, height = 0})
	-- numTxt:setFontName("tetris2048/res/Font/fangzheng.ttf")
	-- numTxt:setFontSize(30)
	-- numTxt:setString("Whether to quit the game and return to the hall?")
	-- numTxt:setAnchorPoint(0.5,0.5)
	-- numTxt:addTo(Bg)
	-- numTxt:setPosition(BgSize.width/2,BgSize.height/2+50)

    local contentSize = Bg:getContentSize()
	local quitBtn = ccui.ImageView:create(path.."other/quit.png")
 	quitBtn:addTo(Bg)
 	quitBtn:pos(BgSize.width/2-125,BgSize.height/2-50)
 	quitBtn:setTouchEnabled(true)
 	quitBtn:addTouchEventListener(handler(self,self.onQuitClick))


 	self.soundBtn = ccui.ImageView:create(path.."other/sound.png")
 	self.soundBtn :addTo(Bg)
 	self.soundBtn :pos(BgSize.width/2+125,BgSize.height/2-50)
 	self.soundBtn :setTouchEnabled(true)
 	self.soundBtn :addTouchEventListener(handler(self,self.onSoundClick))

 	local hightSocre = cc.UserDefault:getInstance():getBoolForKey("2048SoundVolume",true)

 	if hightSocre then
 		self.soundBtn:loadTexture(path.."other/sound.png")
 	else
 		self.soundBtn:loadTexture(path.."other/prohibitSound.png")
 	end
end

function SettingDlg:onQuitClick( sender, eventType )
	self.content.ctx.gameController:onBtnTouch(sender,eventType,function ( ... )
		app:exit()
	end)
end

function SettingDlg:onSoundClick( sender, eventType )
	self.content.ctx.gameController:onBtnTouch(sender,eventType,function ( ... )
		local hightSocre = cc.UserDefault:getInstance():getBoolForKey("2048SoundVolume",true)
		if hightSocre then
			game.SoundManager:updateSoundVolume(0)
			game.SoundManager:updateMusicVolume(0)
			cc.UserDefault:getInstance():setBoolForKey("2048SoundVolume",false)
			self.soundBtn:loadTexture(path.."other/prohibitSound.png")
		else
			game.SoundManager:updateSoundVolume(100)
			game.SoundManager:updateMusicVolume(100)
			cc.UserDefault:getInstance():setBoolForKey("2048SoundVolume",true)
			self.soundBtn:loadTexture(path.."other/sound.png")
		end
	end)
end

function SettingDlg:onCleanup()
end
return SettingDlg