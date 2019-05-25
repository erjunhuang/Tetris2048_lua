-- 游戏Item更新的进度条效果
local NewUpdateMgr = import(".NewUpdateMgr")
local NewConstantConfig = import(".NewConstantConfig")
local GameUpdateItemProgressBar = import(".GameUpdateItemProgressBar")
local GameConfig = require(require("GameHallShellConfig").GAME_CONFIG_PATH)

local GameUpdateProgressItem = class("GameUpdateProgressItem", function() return ccui.Layout:create() end)

local gamehallshell_res_path = GameConfig.res_path.."gamehallshell/"

local GAME_ITEM_WIDTH = 230
local GAME_ITEM_HEIGHT = 205
local PROGRESS_WIDTH = 170
local PROGRESS_HEIGHT = 10

GameUpdateProgressItem.ZORDERS = {
	CONTENT = 1,
	GAMENAME = 2,
	PROGRESS = 10,
	PROGRESS_TEXT = 11,
}

GameUpdateProgressItem.DOWNLOAD_STATE = {
	NONE = 0,
	DOWNLOADING = 1,
	DOWNLOAD_ERROR = 2,
	INSTALLING = 3,
	DOWNLOAD_FINISHED = 4,
}

GameUpdateProgressItem.DOWNLOAD_STATE_IMG = {
	INSTALLING = gamehallshell_res_path.."update/game_installing.png",
	FAILED = gamehallshell_res_path.."update/game_download_failed.png",
}

function GameUpdateProgressItem:ctor(gamedata)
	self:enableNodeEvents()
	self.mGameData = clone(gamedata)
	self.mGameData.game_id = checkint(self.mGameData.game_id)

	self.mDownloadState = self.DOWNLOAD_STATE.NONE
	self:createUpdateProcessView()

	local cacheAm = NewUpdateMgr.getInstance():getAssetsManagerExCache(self.mGameData.game_id)
	if self:isGameUpdated() then
		-- 本次应用启动已经更新过
		-- 啥都不干
	elseif cacheAm then
		-- 有缓存的AssetsManagerEx
		if cacheAm:isLuaUpdating() then
			-- self:setDownloading(true)
			self:setDownloadState(self.DOWNLOAD_STATE.DOWNLOADING)

			local state = cacheAm:getState()
			if state == NewConstantConfig.ASSETS_MANAGER_EX_STATE.UPDATING then
				-- 处于更新状态，还原一下进度
				local percent = cacheAm:getCurrentPercent()
				print("GameUpdateProgressItem:ctor() => resume current percent = ", percent)
				self:setPercent(percent)
			end
		end
		self.mAssetsManagerEx = cacheAm
		self.mAssetsManagerExCallback = handler(self, self.onGameUpdateCallback)
		NewUpdateMgr.getInstance():addAssetsManagerExCallback(self.mGameData.game_id, self.mAssetsManagerExCallback)		
	end
end

function GameUpdateProgressItem:onCleanup(...)
	if self:getReferenceCount() <= 1 then
		-- 只有在真正delete前才释放
		-- 只释放监听回调，不释放AssetsManagerEx，用于AssetsManagerEx在后台继续工作
		print("GameUpdateProgressItem:onCleanup")
		self:removeAssetsManagerExCallback()
		self:releaseCheckUpdateCallback()
	end
end

function GameUpdateProgressItem:isGameUpdated()
	return NewUpdateMgr.getInstance():isGameUpdated(self.mGameData.game_id)
end

function GameUpdateProgressItem:createUpdateProcessView()
	if not self.mUpdateProgress then
		self.mUpdateProgress = GameUpdateItemProgressBar.new()
		self.mUpdateProgress:pos(GAME_ITEM_WIDTH/2, -10)
		self:addChild(self.mUpdateProgress, self.ZORDERS.PROGRESS)
		self.mUpdateProgress:hide()

		local percent = self.mUpdateProgress:getPercent()
		self.mUpdateProgressText = display.newTTFLabel({text=string.format("%d%%", percent),color = cc.c3b(255,255,255), size = 20, align = cc.TEXT_ALIGNMENT_CENTER, valign = cc.VERTICAL_TEXT_ALIGNMENT_CENTER, dimensions = cc.size(0,0)})
		self.mUpdateProgressText:pos(GAME_ITEM_WIDTH/2, -10)
		self:addChild(self.mUpdateProgressText, self.ZORDERS.PROGRESS_TEXT)
		self.mUpdateProgressText:hide()

		self.mUpdateStateImgInstalling = display.newSprite(self.DOWNLOAD_STATE_IMG.INSTALLING)
		self.mUpdateStateImgInstalling:pos(GAME_ITEM_WIDTH / 2, -10)
		self:addChild(self.mUpdateStateImgInstalling, self.ZORDERS.PROGRESS_TEXT)
		self.mUpdateStateImgInstalling:hide()

		self.mUpdateStateImgDownloadFailed = display.newSprite(self.DOWNLOAD_STATE_IMG.FAILED)
		self.mUpdateStateImgDownloadFailed:pos(GAME_ITEM_WIDTH / 2, -10)
		self:addChild(self.mUpdateStateImgDownloadFailed, self.ZORDERS.PROGRESS_TEXT)
		self.mUpdateStateImgDownloadFailed:hide()
	end
end

function GameUpdateProgressItem:recreateAssetsManagerEx(urlPrefix)
	local gameid = self.mGameData.game_id
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

	local cacheAm = NewUpdateMgr.getInstance():getAssetsManagerExCache(self.mGameData.game_id)
	if cacheAm then
		-- 如果有正在下载的AssetsManagerEx优先用正在下载的
		if cacheAm:isLuaUpdating() then
			-- self:setDownloading(true)
			self:setDownloadState(self.DOWNLOAD_STATE.DOWNLOADING)
		end
		self.mAssetsManagerEx = cacheAm
		self.mAssetsManagerExCallback = handler(self, self.onGameUpdateCallback)
		NewUpdateMgr.getInstance():addAssetsManagerExCallback(self.mGameData.game_id, self.mAssetsManagerExCallback)
	else
		-- 否则创建一个新的
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
	end

	return amEx, listener
end

-- 释放AssetsManagerEx的lua端监听
function GameUpdateProgressItem:removeAssetsManagerExCallback()
	if self.mAssetsManagerExCallback then
		NewUpdateMgr.getInstance():removeAssetsManagerExCallback(self.mGameData.game_id, self.mAssetsManagerExCallback)
		self.mAssetsManagerExCallback = nil
	end
end

-- 释放AssetsManagerEx，只有在recreate的时候调用
function GameUpdateProgressItem:releaseAssetsManagerEx()
	self:removeAssetsManagerExCallback()
	if self.mAssetsManagerEx then
		NewUpdateMgr.getInstance():releaseAssetsManagerEx(self.mAssetsManagerEx)
		self.mAssetsManagerEx = nil
	end
end

function GameUpdateProgressItem:requestCheckUpdate()
	local gameid = self.mGameData.game_id
	NewUpdateMgr.getInstance():checkSingleGameUpdate(gameid, self, self.onHotUpdateResponse, 4)
end

function GameUpdateProgressItem:releaseCheckUpdateCallback()
	NewUpdateMgr.getInstance():clearCheckGameUpdateCallback(self)
end

function GameUpdateProgressItem:onHotUpdateResponse(result, url, params, data)
	dump(data, "GameUpdateProgressItem:onHotUpdateResponse")
	if result then
		-- 成功状态200
		local code = data.code
		if checkint(code) == 1 then
			if self:isRequestForDownloading() then
				-- 下载
				self:setRequestForDownloading(false)
				self:download()
			end
		else
			self:setRequestForDownloading(false)
			game.AlertDlg:ShowTip({msg="服务器连接失败"})
		end
	else
		-- http请求失败
		self:setRequestForDownloading(false)
		game.AlertDlg:ShowTip({msg="服务器连接失败"})
	end
end

function GameUpdateProgressItem:setPercent(percent)
	-- print("self.mUpdateProgress: ", self.mUpdateProgress)
	if type(percent) == "number" then
		if percent > 100 then percent = 100 end
		if percent < 0 then percent = 0 end
		if not self.mUpdateProgress then
			self:createUpdateProcessView()
		end

		if percent == 100 then
			self:setDownloadState(self.DOWNLOAD_STATE.INSTALLING)
		end

		self.mUpdateProgress:setPercent(percent)
		self.mUpdateProgressText:setString(string.format("%0.0f%%", percent))

	end
end

function GameUpdateProgressItem:download()
	print(debug.traceback())
	print("GameUpdateProgressItem:download() self:isDownloading() == ", self:isDownloading(), "gameName == ", self.mGameData.game_name)
	if not self:isDownloading() then
		if NewUpdateMgr.getInstance():getCheckedGameUpdateResult(self.mGameData.game_id) then
			local urlPrefix = NewUpdateMgr.getInstance():getCheckedGameUpdateResult(self.mGameData.game_id)
			self:recreateAssetsManagerEx(urlPrefix)
			self:update()
		else
			self:setRequestForDownloading(true)
			self:requestCheckUpdate()
		end
	end
end

-- 用于判断是不是收到urlPrefix后就直接请求下载了
function GameUpdateProgressItem:setRequestForDownloading(isRequestForDownloading)
	self.mRequestForDownloading = isRequestForDownloading == true
	print("self.mRequestForDownloading == ", self.mRequestForDownloading)
end

function GameUpdateProgressItem:isRequestForDownloading()
	return self.mRequestForDownloading
end

function GameUpdateProgressItem:setDownloadState(state)
	if self.mDownloadState == state then
		return
	end

	self.mDownloadState = state
	self:setEnabled(true)

	if self.mDownloadState == self.DOWNLOAD_STATE.NONE then
		-- 原则上不会回到NONE
	elseif self.mDownloadState == self.DOWNLOAD_STATE.DOWNLOADING then
		self:setEnabled(false)

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
		self:setEnabled(false)

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

function GameUpdateProgressItem:isDownloading()
	return self.mDownloadState == self.DOWNLOAD_STATE.DOWNLOADING or self.mDownloadState == self.DOWNLOAD_STATE.INSTALLING
end

function GameUpdateProgressItem:createEmptyManifestFiles()
	local gameid = self.mGameData.game_id
	local packagePath = game.gameManager:getPkgName(gameid)
	local remoteManifestUrl = "project.manifest"
	local remoteVersionUrl = "version.manifest"
	NewUpdateMgr.getInstance():createEmptyManifestFilesByPackagePath(packagePath, remoteManifestUrl, remoteVersionUrl)
end

function GameUpdateProgressItem:createEmptyManifestFilesAndDownload()
	self:createEmptyManifestFiles()
	self:download()
end

function GameUpdateProgressItem:update()
	if self.mAssetsManagerEx and not self:isDownloading() then
		self:setDownloadState(self.DOWNLOAD_STATE.DOWNLOADING)
		self.mAssetsManagerEx:luaUpdate()
	end
end

-- 该游戏是否已安装
function GameUpdateProgressItem:isInstalled()
	local gameid = checkint(self.mGameData.game_id)
	local result = game.gameManager:isGameInstalled(gameid)
	return result
end

function GameUpdateProgressItem:checkUpdate()
	if self.mAssetsManagerEx then
		self.mAssetsManagerEx:checkUpdate()
	end
end

function GameUpdateProgressItem:onGameUpdateCallback(event)
	-- print("GameUpdateProgressItem:onGameUpdateCallback")
	local eventCode = event:getEventCode()
	if eventCode == cc.EventAssetsManagerEx.EventCode.ERROR_NO_LOCAL_MANIFEST
	or eventCode == cc.EventAssetsManagerEx.EventCode.ERROR_DOWNLOAD_MANIFEST
	or eventCode == cc.EventAssetsManagerEx.EventCode.ERROR_PARSE_MANIFEST
	or eventCode == cc.EventAssetsManagerEx.EventCode.UPDATE_FAILED then
		-- 没有localManifest文件，或者本地描述文件加载失败
		game.AlertDlg:ShowTip({msg=(self.mGameData.game_name or "游戏") .. "下载失败"})
		self:setDownloadState(self.DOWNLOAD_STATE.DOWNLOAD_ERROR)
	elseif eventCode == cc.EventAssetsManagerEx.EventCode.NEW_VERSION_FOUND then
		-- 加载removteVersion或者remoteManifest后，发现有新版本
	elseif eventCode == cc.EventAssetsManagerEx.EventCode.UPDATE_FINISHED then
		-- 解压成功，更新成功
		game.AlertDlg:ShowTip({msg=(self.mGameData.game_name or "游戏") .. "下载成功"})
		-- self._gameIcon:setColor(cc.c3b(255,255,255))
		-- self._downloadIcon:setVisible(false)
		local gameid = self.mGameData.game_id
		game.gameManager:reInitGame(gameid)
		self:setDownloadState(self.DOWNLOAD_STATE.DOWNLOAD_FINISHED)

	elseif eventCode == cc.EventAssetsManagerEx.EventCode.ASSET_UPDATED then
		-- 通知资源已更新，但并不代表成功
	elseif eventCode == cc.EventAssetsManagerEx.EventCode.UPDATE_PROGRESSION then
		-- 下载进度
		local assetId = event:getAssetId()
	    local percent = event:getPercent()
	    local strInfo = ""

	    if assetId == cc.AssetsManagerExStatic.VERSION_ID then
	        strInfo = string.format("Version file: %d%%", percent)
	    elseif assetId == cc.AssetsManagerExStatic.MANIFEST_ID then
	        strInfo = string.format("Manifest file: %d%%", percent)
	    else
	        strInfo = string.format("Game files: %d%%", percent)
	        self:setPercent(percent)
	    end
	    -- print("downloading progress:", strInfo)
	elseif eventCode == cc.EventAssetsManagerEx.EventCode.ALREADY_UP_TO_DATE then
		-- 检查更新时，比对localManifest和remoteManifest版本信息时，如果版本号相同，则判断为已经更新到最新版本
		-- self._gameIcon:setColor(cc.c3b(255,255,255))
		-- self._downloadIcon:setVisible(false)
		self:setDownloadState(self.DOWNLOAD_STATE.DOWNLOAD_FINISHED)
	elseif eventCode == cc.EventAssetsManagerEx.EventCode.ERROR_DECOMPRESS then
		-- 解压文件失败，不会中断逻辑
	elseif eventCode == cc.EventAssetsManagerEx.EventCode.ERROR_UPDATING then
		-- 更新出错/失败（downloader出错/失败）
	end
end


return GameUpdateProgressItem