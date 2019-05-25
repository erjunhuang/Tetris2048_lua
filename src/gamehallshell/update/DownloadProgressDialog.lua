local NewUpdateMgr = import(".NewUpdateMgr")
local NewConstantConfig = import(".NewConstantConfig")
local GameUpdateItemProgressBar = import(".GameUpdateItemProgressBar")

local GameConfig = require(require("GameHallShellConfig").GAME_CONFIG_PATH)
local gamehallshell_res_path = GameConfig.res_path.."gamehallshell/"

--[[
非大厅MainHallView下的下载进度提示/遮罩
]]
local DownloadProgressDialog = class("DownloadProgressDialog", game.ui.Panel)

local MODAL_BG = gamehallshell_res_path.."common/common_modal_texture.png"
local DEFAULT_GAME_ICON = gamehallshell_res_path.."hall/hall_base_game_icon.png"

local GAME_ITEM_WIDTH = 230
local GAME_ITEM_HEIGHT = 205

DownloadProgressDialog.ZORDERS = {
	CONTENT = 1,
	GAMENAME = 2,
	PROGRESS = 10,
	PROGRESS_TEXT = 11,
}

DownloadProgressDialog.DOWNLOAD_STATE = {
	NONE = 0,
	DOWNLOADING = 1,
	DOWNLOAD_ERROR = 2,
	INSTALLING = 3,
	DOWNLOAD_FINISHED = 4,
}

DownloadProgressDialog.DOWNLOAD_STATE_IMG = {
	INSTALLING = gamehallshell_res_path.."hall/game_installing.png",
	FAILED = gamehallshell_res_path.."hall/game_download_failed.png",
}

-- 如果游戏已经更新/下载，就不应该弹这个窗
function DownloadProgressDialog:ctor(gameid, afterSuccessCallback)
	DownloadProgressDialog.super.ctor(self, {display.width, display.height})

	self:enableNodeEvents()

	self.mGameId = tonumber(gameid)
	self.mAfterSuccessCallback = afterSuccessCallback

	if not self.mGameId then
		print("error create DownloadProgressDialog, invalid gameid", gameid)
	end

	self.mGameData = game.AllGames:getGameDataByGameId(gameid)
	dump(self.mGameData, "DownloadProgressDialog => self.mGameData => ")

	self:initUI()

	local cacheAm = NewUpdateMgr.getInstance():getAssetsManagerExCache(self.mGameId)
	if cacheAm then
		local state = cacheAm:getState()
		if cacheAm:isLuaUpdating() then
			-- 在下载
			if state == NewConstantConfig.ASSETS_MANAGER_EX_STATE.UPDATING then
				local percent = cacheAm:getCurrentPercent()
				self:setPercent(percent)
			end
			self.mAssetsManagerEx = cacheAm
			self.mAssetsManagerExCallback = handler(self, self.onGameUpdateCallback)
			NewUpdateMgr.getInstance():addAssetsManagerExCallback(self.mGameId, self.mAssetsManagerExCallback)
		else
			-- 不在下载，清除，再下载
			NewUpdateMgr:getInstance():releaseAssetsManagerEx(cacheAm)
			self:createEmptyManifestFilesAndDownload()
		end
	else
		-- 新下载
		self:createEmptyManifestFilesAndDownload()
	end
end

function DownloadProgressDialog:onCleanup(...)
	if self:getReferenceCount() <= 1 then
		self:dtor()
	end
end

function DownloadProgressDialog:createUpdateProcessView()
	if not self.mUpdateProgress then
		self.mUpdateProgress = GameUpdateItemProgressBar.new()
		self.mUpdateProgress:pos(0, -GAME_ITEM_HEIGHT/2-10)
		self:addChild(self.mUpdateProgress, self.ZORDERS.PROGRESS)
		self.mUpdateProgress:hide()

		local percent = self.mUpdateProgress:getPercent()
		self.mUpdateProgressText = display.newTTFLabel({text=string.format("%d%%", percent),color = cc.c3b(255,255,255), size = 24, align = cc.TEXT_ALIGNMENT_CENTER, valign = cc.VERTICAL_TEXT_ALIGNMENT_CENTER})
		self.mUpdateProgressText:pos(0, -GAME_ITEM_HEIGHT/2-10)
		self:addChild(self.mUpdateProgressText, self.ZORDERS.PROGRESS_TEXT)
		self.mUpdateProgressText:hide()

		self.mUpdateStateImgInstalling = display.newSprite(self.DOWNLOAD_STATE_IMG.INSTALLING)
		self.mUpdateStateImgInstalling:pos(0, -GAME_ITEM_HEIGHT/2-10)
		self:addChild(self.mUpdateStateImgInstalling, self.ZORDERS.PROGRESS_TEXT)
		self.mUpdateStateImgInstalling:hide()

		self.mUpdateStateImgDownloadFailed = display.newSprite(self.DOWNLOAD_STATE_IMG.FAILED)
		self.mUpdateStateImgDownloadFailed:pos(0, -GAME_ITEM_HEIGHT/2-10)
		self:addChild(self.mUpdateStateImgDownloadFailed, self.ZORDERS.PROGRESS_TEXT)
		self.mUpdateStateImgDownloadFailed:hide()
	end
end

function DownloadProgressDialog:initUI()
	self.mBg = display.newScale9Sprite(MODAL_BG,0,0, cc.size(self.__width, self.__height)):addTo(self)
	cc.bind(self.mBg, "touch"):setTouchEnabled(true)
	self.mBg:setSwallowTouches(true)
	
	self._gameIcon = game.ui.UrlImage.new(DEFAULT_GAME_ICON,{width=GAME_ITEM_WIDTH, height=GAME_ITEM_HEIGHT})
	self._gameIcon:setImageLoadCallback(handler(self, self.onGameIconLoaded))
	self._gameIcon:setCascadeColorEnabled(true)
	self:addChild(self._gameIcon)

	if self.mGameData then
		local gameName = self.mGameData.game_name or ""
		self.__gameName = display.newTTFLabel({text = gameName,color = ITEM_TEXT_COLOR,font = fontsPath, size = 40,align = cc.TEXT_ALIGNMENT_LEFT,})
		self.__gameName:pos(0, -GAME_ITEM_HEIGHT/4)
		self:addChild(self.__gameName, self.ZORDERS.GAMENAME)
	end

	self:createUpdateProcessView()

	if self.mGameData then
		local iconUrl = self.mGameData.game_icon
		if type(iconUrl) == "string" and #iconUrl > 5 then
			self._gameIcon:loadUrl(iconUrl)
		end
	end
end

function DownloadProgressDialog:dtor()
	self:releaseCheckUpdateCallback()
	self:releaseAssetsManagerExCallback()
	self:releaseAssetsManagerEx()
end

function DownloadProgressDialog:show()
	-- 不能关，居中，无动画
	self:showPanel_(true, true, false, false)
end

function DownloadProgressDialog:onGameIconLoaded(success, sprite)
	print("DownloadProgressDialog:onGameIconLoaded success = ", success)
	if success then
		if self.__gameName then
			self.__gameName:removeFromParent()
			self.__gameName = nil
		end
	end
end

function DownloadProgressDialog:close()
	-- 无动画
	self:hidePanel_(false)
end

function DownloadProgressDialog:update()
	if self.mAssetsManagerEx then
		self:setDownloadState(self.DOWNLOAD_STATE.DOWNLOADING)

		self.mAssetsManagerEx:luaUpdate()
	end
end

function DownloadProgressDialog:download()
	if NewUpdateMgr.getInstance():getCheckedGameUpdateResult(self.mGameId) then
		local urlPrefix = NewUpdateMgr.getInstance():getCheckedGameUpdateResult(self.mGameId)
		self:recreateAssetsManagerEx(urlPrefix)
		self:update()
	else
		self:requestCheckUpdate()
	end
end

function DownloadProgressDialog:createEmptyManifestFilesAndDownload()
	self:createEmptyManifestFiles()
	self:download()
end

function DownloadProgressDialog:createEmptyManifestFiles()
	local gameid = self.mGameId
	local packagePath = game.gameManager:getPkgName(gameid)
	local remoteManifestUrl = "project.manifest"
	local remoteVersionUrl = "version.manifest"
	NewUpdateMgr.getInstance():createEmptyManifestFilesByPackagePath(packagePath, remoteManifestUrl, remoteVersionUrl)
end

function DownloadProgressDialog:requestCheckUpdate()
	local gameid = self.mGameId
	NewUpdateMgr.getInstance():checkSingleGameUpdate(gameid, self, self.onHotUpdateResponse, 4)
end

function DownloadProgressDialog:releaseCheckUpdateCallback()
	NewUpdateMgr.getInstance():clearCheckGameUpdateCallback(self)
end

function DownloadProgressDialog:onHotUpdateResponse(result, url, params, data)
	dump(data, "DownloadProgressDialog:onHotUpdateResponse")
	if result then
		-- 成功状态200
		local code = data.code
		if checkint(code) == 1 then
			-- 下载
			self:download()
		else
			-- TODO PHP返回失败
			game.AlertDlg:ShowTip({msg="无法连接服务器"})
			self:close()
		end
	else
		-- http请求失败
		-- TODO 干啥
		game.AlertDlg:ShowTip({mgs="无法连接服务器"})
		self:close()
	end
end

function DownloadProgressDialog:releaseAssetsManagerExCallback()
	if self.mAssetsManagerExCallback then
		NewUpdateMgr.getInstance():removeAssetsManagerExCallback(self.mGameId, self.mAssetsManagerExCallback)
	end
end

function DownloadProgressDialog:recreateAssetsManagerEx(urlPrefix)
	local gameid = self.mGameId
	local pkgName = game.gameManager:getPkgName(gameid)

	if not pkgName then
		print(string.format("error cannot game.gameManager:getPkgName(%d)", gameid))
		-- TODO 这里要干啥？
		return
	end

	local versionManifest = NewUpdateMgr.getInstance():joinDirectorySeparator(pkgName) .. "version.manifest"
	local projectManifest = NewUpdateMgr.getInstance():joinDirectorySeparator(pkgName) .. "project.manifest"
	local storagePath = NewConstantConfig.LOCALPATH.UPDATES_PATH .. pkgName

	if self.mAssetsManagerEx then
		self:releaseAssetsManagerEx()
	end

	self.mAssetsManagerExCallback = handler(self, self.onGameUpdateCallback)
	self.mLastUrlPrefix = urlPrefix or self.mLastUrlPrefix
	local amEx = NewUpdateMgr.getInstance():createAssetsManagerEx(gameid, versionManifest, projectManifest, 
		storagePath, self.mAssetsManagerExCallback, self.mLastUrlPrefix)
	if amEx then
		-- 用于释放
		self.mAssetsManagerEx = amEx
	else
		print("cant not create a legal AssetsManagerEx")
		-- TODO 这里要干啥？
	end
	return amEx, listener
end

function DownloadProgressDialog:releaseAssetsManagerEx()
	-- TODO 这里如果同时有两个地方共用一个AssetsManagerEx就一定会有问题，想想怎么解决
	if self.mAssetsManagerEx then
		NewUpdateMgr:getInstance():releaseAssetsManagerEx(self.mAssetsManagerEx)
		self.mAssetsManagerEx = nil
	end
end

function DownloadProgressDialog:onGameUpdateCallback(event)
	-- print("DownloadProgressDialog:onGameUpdateCallback")
	local eventCode = event:getEventCode()
	if eventCode == cc.EventAssetsManagerEx.EventCode.ERROR_NO_LOCAL_MANIFEST
	or eventCode == cc.EventAssetsManagerEx.EventCode.ERROR_DOWNLOAD_MANIFEST
	or eventCode == cc.EventAssetsManagerEx.EventCode.ERROR_PARSE_MANIFEST
	or eventCode == cc.EventAssetsManagerEx.EventCode.UPDATE_FAILED then
		-- 没有localManifest文件，或者本地描述文件加载失败
		if self then
			if self.mGameData then
				game.AlertDlg:ShowTip({msg=(self.mGameData.game_name or "游戏") .. "下载失败"})
			end
			self:close()
		end
		
	elseif eventCode == cc.EventAssetsManagerEx.EventCode.NEW_VERSION_FOUND then
		-- 加载removteVersion或者remoteManifest后，发现有新版本
	elseif eventCode == cc.EventAssetsManagerEx.EventCode.UPDATE_FINISHED then
		-- 解压成功，更新成功
		if self then
			if self.mGameData then
				game.AlertDlg:ShowTip({msg=(self.mGameData.game_name or "游戏") .. "下载成功"})
			end
			game.gameManager:reInitGame(self.mGameId)
			if self.mAfterSuccessCallback then
				self.mAfterSuccessCallback()
			end
			self:close()
		end

	elseif eventCode == cc.EventAssetsManagerEx.EventCode.ASSET_UPDATED then
		-- 通知资源已更新，但并不代表成功
	elseif eventCode == cc.EventAssetsManagerEx.EventCode.UPDATE_PROGRESSION then
		-- 下载进度
		local assetId = event:getAssetId()
	    local percent = event:getPercent()
	    -- local strInfo = ""

	    if assetId == cc.AssetsManagerExStatic.VERSION_ID then
	        -- strInfo = string.format("Version file: %d%%", percent)
	    elseif assetId == cc.AssetsManagerExStatic.MANIFEST_ID then
	        -- strInfo = string.format("Manifest file: %d%%", percent)
	    else
	        -- strInfo = string.format("Game files: %d%%", percent)
	        self:setPercent(percent)
	    end
	    -- print("downloading progress:", strInfo)
	elseif eventCode == cc.EventAssetsManagerEx.EventCode.ALREADY_UP_TO_DATE then
		-- 检查更新时，比对localManifest和remoteManifest版本信息时，如果版本号相同，则判断为已经更新到最新版本
		-- game.AlertDlg:ShowTip({msg="游戏下载成功"})
		game.gameManager:reInitGame(self.mGameId)
		if self.mAfterSuccessCallback then
			self.mAfterSuccessCallback()
		end
		self:close()
	elseif eventCode == cc.EventAssetsManagerEx.EventCode.ERROR_DECOMPRESS then
		-- 解压文件失败，不会中断逻辑
	elseif eventCode == cc.EventAssetsManagerEx.EventCode.ERROR_UPDATING then
		-- 更新出错/失败（downloader出错/失败）
	end
end

function DownloadProgressDialog:setDownloadState(state)
	if self.mDownloadState == state then
		return
	end

	self.mDownloadState = state

	if self.mDownloadState == self.DOWNLOAD_STATE.NONE then
		-- 原则上不会回到NONE
	elseif self.mDownloadState == self.DOWNLOAD_STATE.DOWNLOADING then
		self:setPercent(0)

		self.mUpdateStateImgInstalling:hide()
		self.mUpdateStateImgDownloadFailed:hide()

		self.mUpdateProgress:show()
		self.mUpdateProgressText:show()

	elseif self.mDownloadState == self.DOWNLOAD_STATE.DOWNLOAD_ERROR then
		self.mUpdateStateImgInstalling:hide()
		self.mUpdateStateImgDownloadFailed:show()
		self.mUpdateProgress:hide()
		self.mUpdateProgressText:hide()

	elseif self.mDownloadState == self.DOWNLOAD_STATE.INSTALLING then
		self.mUpdateStateImgInstalling:show()
		self.mUpdateStateImgDownloadFailed:hide()
		self.mUpdateProgress:hide()
		self.mUpdateProgressText:hide()
	elseif self.mDownloadState == self.DOWNLOAD_STATE.DOWNLOAD_FINISHED then

		self.mUpdateStateImgInstalling:hide()
		self.mUpdateStateImgDownloadFailed:hide()
		self.mUpdateProgress:hide()
		self.mUpdateProgressText:hide()
	end
end

function DownloadProgressDialog:setPercent(percent)
	if type(percent) == "number" then
		if percent > 100 then percent = 100 end
		if percent < 0 then percent = 0 end
		if not self.mUpdateProgress then
			self:createUpdateProcessView()
		end

		if percent == 100 then
			self:setDownloadState(self.DOWNLOAD_STATE.INSTALLING)
			return
		end

		self.mUpdateProgress:setPercent(percent)
		self.mUpdateProgressText:setString(string.format("%d%%", percent))
	end
end

return DownloadProgressDialog