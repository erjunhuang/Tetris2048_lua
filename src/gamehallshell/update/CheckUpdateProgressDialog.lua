local NewUpdateMgr = import(".NewUpdateMgr")
local NewConstantConfig = import(".NewConstantConfig")
local GameConfig = require(require("GameHallShellConfig").GAME_CONFIG_PATH)

-- 检查更新时显示的菊花
local CheckUpdateProgressDialog = class("CheckUpdateProgressDialog", game.ui.Panel)

local gamehallshell_res_path = GameConfig.res_path.."gamehallshell/"
local resBg = gamehallshell_res_path.. "common/common_modal_texture.png"
local resJuhua = "Default/juhua.png"

-- 如果已经检查过更新，不应该显示这个
function CheckUpdateProgressDialog:ctor(gameid, upCallback, noUpCallback)
	self.mGameId = tonumber(gameid)
	self.mShouldUpdateCallback = upCallback
	self.mNoUpdateCallback = noUpCallback
	if not self.mGameId then
		print("error invalid gameid: ", gameid)
	end
	self.mBg = display.newScale9Sprite(resBg,0,0, cc.size(self.__width, self.__height)):addTo(self)
	self:initUI()
end

function CheckUpdateProgressDialog:dtor()
	self:releaseCheckUpdateCallback()
end

function CheckUpdateProgressDialog:onCleanup(...)
	if self:getReferenceCount() <= 1 then
		self:dtor()
	end
end

function CheckUpdateProgressDialog:initUI()
	self.mBg = display.newScale9Sprite(resBg,0,0, cc.size(self.__width, self.__height)):addTo(self)
	cc.bind(self.mBg, "touch"):setTouchEnabled(true)
	self.mBg:setSwallowTouches(true)

	self.mJuhua = display.newSprite(resJuhua):addTo(self)
	self.mJuhua:runAction(cc.RepeatForever:create(cc.RotateBy:create(100, 36000)))
end

function CheckUpdateProgressDialog:checkGameUpdate()
	NewUpdateMgr.getInstance():checkSingleGameUpdate(self.mGameId, self, self.onCheckUpdateResponse, 4)
end

function CheckUpdateProgressDialog:releaseCheckUpdateCallback()
	NewUpdateMgr.getInstance():clearCheckGameUpdateCallback(self)
end

function CheckUpdateProgressDialog:onCheckUpdateResponse(result, url, params, data)
	dump(data, "CheckUpdateProgressDialog:onCheckUpdateResponse")
	if result then
		local code = tonumber(data.code)
		if code == 1 then
			local urlPrefix, version = NewUpdateMgr.getInstance():getCheckedGameUpdateResult(self.mGameId)
			local nowGameVersion = game.gameManager:getGameVersion(self.mGameId)
			local isNewer = NewUpdateMgr.getInstance():isFullVersionNewer(version, nowGameVersion)
			print("version => ", version,  "nowGameVersion => ", nowGameVersion,  "result => ", isNewer)
			if isNewer then
				if self.mShouldUpdateCallback then
					self.mShouldUpdateCallback()
				end
			else
				NewUpdateMgr.getInstance():setGameUpdatedRecord(self.mGameId)
				if self.mNoUpdateCallback then
					self.mNoUpdateCallback()
				end
			end
			if self and self.close then
				self:close()
			end
		else
			game.AlertDlg:ShowTip({msg="服务器连接失败"})
			if self and self.close then
				self:close()
			end
		end
	else
		game.AlertDlg:ShowTip({msg="服务器连接失败"})
		if self and self.close then
			self:close()
		end
	end
end

function CheckUpdateProgressDialog:show()
	-- 不能关，居中，无动画
	self:showPanel_(true, true, false, false)
	self:checkGameUpdate()
end

function CheckUpdateProgressDialog:close()
	self:dtor()
	-- 无动画
	self:hidePanel_(self, false)
end

return CheckUpdateProgressDialog