local Dialog = import(".Dialog")
local ConstantConfig = import(".ConstantConfig")
local NewConstantConfig = import(".NewConstantConfig")
local ShellUpdateScene = import(".ShellUpdateScene")
local NewUpdateMgr = import(".NewUpdateMgr")
local appconfig = import("appconfig")
local ShellScreenOrientationManager = import(".ShellScreenOrientationManager")

local GameConfig = require(require("GameHallShellConfig").GAME_CONFIG_PATH)
local GAME_PATH = GameConfig.GamePath
local GAME_VERSION = GameConfig.gameVersion
local GAME_ID = GameConfig.gameId

print("ShellUpdateController ====> GAME_PATH = ", GAME_PATH, "GAME_VERSION = ", GAME_VERSION, "GAME_ID = ", GAME_ID)

--- 壳游戏更新Controller
local ShellUpdateController = class("ShellUpdateController")

ShellUpdateController.s_retryCounts = 3
-- 请求失败延迟5秒继续请求
ShellUpdateController.s_failRetryDelay = {1,1,1}

function ShellUpdateController:ctor()
	self.hasShellOrientationChanged = false

	local gameManager = require("app.manager.GameManager").getInstance()
	gameManager:initPkgName(GAME_ID, GAME_PATH)
	gameManager:initGame(GAME_ID)

	--- 基本都是摘抄自GameManager
	-- 壳游戏屏幕方向
	-- LANDSCAPE = 1; --横屏
	-- PORTRAIT = 2;  --竖屏
	local gameResolution = gameManager:getGameResolution(GAME_ID)
	local gameAutoScale = gameManager:getGameAutoscale(GAME_ID)
	local gameVerticalScreen = GameConfig.gameVerticalScreen or 1

	local designWidth = gameResolution[1] or 1280
	local designHeight = gameResolution[2] or 720

	local function __innerChangeOrientationCallback(resultTable)

		self:__setAutoscaleOrResolution(gameResolution[1], gameResolution[2], gameAutoScale)

		self.hasShellOrientationChanged = true
		self:initControllerAndScene(designWidth, designHeight)
	end

	if gameVerticalScreen ~= 1 then
		ShellScreenOrientationManager.getInstance():changeScreenOrientation(
			ShellScreenOrientationManager.SCREEN_ORIENTATION.PORTRAIT,
			nil, nil, __innerChangeOrientationCallback
		)
	else
		self:initControllerAndScene(designWidth, designHeight)
	end
	
end

function ShellUpdateController:__setAutoscaleOrResolution(width, height, autoscale)
	local autoscaleTb = string.split(autoscale,"_")
	local autoscale_1 = autoscale
	local autoscale_2 = autoscale
	if #autoscaleTb >= 3 then
		autoscale_1 = string.format("%s_%s",autoscaleTb[1],autoscaleTb[2])
		autoscale_2 = string.format("%s_%s",autoscaleTb[1],autoscaleTb[3])
	end
	CONFIG_SCREEN_AUTOSCALE = autoscale_1
	local newDesign = {
			width = width,
			height = height,
			autoscale = CONFIG_SCREEN_AUTOSCALE,
			callback = function(framesize)
				if framesize.width/framesize.height >= CONFIG_SCREEN_WIDTH / CONFIG_SCREEN_HEIGHT then
					CONFIG_SCREEN_AUTOSCALE = autoscale_2
					return {autoscale = CONFIG_SCREEN_AUTOSCALE}
				else
					CONFIG_SCREEN_AUTOSCALE = autoscale_1
					return {autoscale = CONFIG_SCREEN_AUTOSCALE}
				end
			end,
		}

	display.setAudoScaleWithCurrentFrameSize(newDesign)
end

function ShellUpdateController:__doAfterRotateScreenBack(func)
	if self.hasShellOrientationChanged then
		local function __innerChangeOrientationCallback(resultTable)
			self:__setAutoscaleOrResolution(CONFIG_SCREEN_WIDTH, CONFIG_SCREEN_HEIGHT, CONFIG_SCREEN_AUTOSCALE)

			func(self)
		end

		ShellScreenOrientationManager.getInstance():changeScreenOrientation(
			ShellScreenOrientationManager.SCREEN_ORIENTATION.LANDSCAPE, nil, nil, __innerChangeOrientationCallback)
	else
		func(self)
	end
end

function ShellUpdateController:initControllerAndScene(designWidth, designHeight)
	self.mScene = ShellUpdateScene.new(self, designWidth, designHeight)
	self.STATE = ShellUpdateScene.STATE
	display.runScene(self.mScene)
	self.mSchedulerPool = core.SchedulerPool.new()
	NewUpdateMgr.getInstance():setOnGameDownloadHandlers(self,  handler(self, self.onAppDownloadCallback), handler(self, self.onAppDownloadProgressCallback))

	self.mRetryCounts = ShellUpdateController.s_retryCounts

	self.firstApiUrl = self:getFirstApi()
	self:requestFirstAPI()
end

function ShellUpdateController:dtor()
	print("ShellUpdateController:dtor()")
	NewUpdateMgr.getInstance():removeOnGameDownloadHandlers(self)
	self:releaseCheckUpdateCallback()
	self:releaseAssetsManagerEx()
	if self.mSchedulerPool then
		self.mSchedulerPool:clearAll()
		self.mSchedulerPool = nil
	end
end

function ShellUpdateController:dispose()
	print("ShellUpdateController:dispose()")
	self:dtor()
end

function ShellUpdateController:recreateAssetsManagerEx(urlPrefix)
	local versionManifest = GAME_PATH .. "/version.manifest"
	local projectManifest = GAME_PATH .. "/project.manifest"
	local storagePath = NewConstantConfig.LOCALPATH.UPDATES_PATH .. GAME_PATH
	self.mLastUrlPrefix = urlPrefix or self.mLastUrlPrefix

	if self.mAssetsManagerEx then
		self:releaseAssetsManagerEx()
	end

	local amEx, listener = NewUpdateMgr.getInstance():createAssetsManagerEx(GAME_ID, versionManifest, projectManifest, storagePath, 
		handler(self, self.onShellGameUpdateCallback), self.mLastUrlPrefix)
	if amEx then
		-- 用于释放
		self.mAssetsManagerEx = amEx
	else
		print("cant not create a legal AssetsManagerEx")
	end
end

function ShellUpdateController:releaseAssetsManagerEx()
	if self.mAssetsManagerEx then
		NewUpdateMgr.getInstance():releaseAssetsManagerEx(self.mAssetsManagerEx)
		self.mAssetsManagerEx = nil
	end
end

function ShellUpdateController:requestFirstAPI()
	self.mScene:showJuhua()

	--默认使用第一个域名
	local url = self.firstApiUrl

	local appid = appconfig.appid
	local params = {}

	-- 0不是，1是
	params.isHallShell = 1

	params.appid = appid
	params.gameid = GAME_ID
	params.gameVersion = GAME_VERSION or "1.0.0.0"
    params.appVersion= NewUpdateMgr.getInstance():getAppVersion() or "1.0.0"

    params.demo = appconfig.phpdemo
    params.time = os.time()

	print("firstAPI url: ", url)
    dump(params, "firstAPI 请求参数: ")

    -- self:startTimer()
    local extra = {timeout = 6000}
	self.mRequestId = core.HttpService.POST_URL(url, params,
		handler(self,self.onResponseFirstAPIResult),
		handler(self,self.onResponseFirstAPIFailed),extra)
end

--获取要使用的域名,
function ShellUpdateController:getFirstApi(isSpare)
	local firstApiUrl = appconfig.firstApiUrl
	if type(firstApiUrl) == "string" then
		return firstApiUrl
	elseif type(firstApiUrl) == "table" then
		if not isSpare then
			return firstApiUrl[1]
		else

			--临时规则-循环取下一个,具体待定
			local idx = table.indexof(firstApiUrl,self.firstApiUrl)
			if not idx or (idx == #firstApiUrl) then
				idx = 1
			else
				idx  = idx+1
			end
			return firstApiUrl[idx]
		end
	end
end


function ShellUpdateController:onResponseFirstAPIResult(data)
	-- self:stopTimer()
	self.mScene:hideJuhua()
	local returnData = data and json.decode(data)
	dump(returnData,"ShellUpdateController:onResponseFirstAPIResult", 5)
	local code = returnData.code
	if checkint(code) == 1 then
		-- 成功
		local dataTab = returnData.data
		local cdnGameUrl = dataTab.cdnGameUrl
		local feedBackUrl = dataTab.feedBackUrl
		local gatewayUrl = dataTab.gatewayUrl
		local indexUrl = dataTab.indexUrl
		local sendfeedUrl = dataTab.sendfeedUrl
		local hotUpdateUrl = dataTab.hotUpdateUrl
		local agreementUrl = dataTab.agreementUrl
		local isVerify = dataTab.isVerify
		--- 壳游戏专属
		local isHallShellGameVerify = dataTab.isHallShellGameVerify
		local isJump = dataTab.isJump

		self.cdnGameUrl_ = cdnGameUrl or ""
		self.feedBackUrl_ = feedBackUrl or ""
		self.gatewayUrl_ = gatewayUrl or ""
		self.indexUrl_ = indexUrl or ""
		self.sendfeedUrl_ = sendfeedUrl or ""
		self.hotUpdateUrl_ = hotUpdateUrl or ""
		self.agreementUrl_ = agreementUrl or ""
		self.isVerify_ = checkint(isVerify) 
		-- 0隐藏 1显示
		self.isHallShellGameVerify = checkint(isHallShellGameVerify)
		-- 0默认大厅，1壳游戏
		self.isJump = checkint(isJump)


		--test
		-- self.isVerify_ = 1

		print("cdnGameUrl", cdnGameUrl)
		print("feedBackUrl", feedBackUrl)
		print("gatewayUrl", gatewayUrl)
		print("indexUrl", indexUrl)
		print("sendfeedUrl", sendfeedUrl)
		print("hotUpdateUrl", hotUpdateUrl)
		print("agreementUrl", agreementUrl)

		appconfig.cdnGameUrl = self.cdnGameUrl_
		appconfig.gatewayUrl = self.gatewayUrl_
		appconfig.indexUrl = self.indexUrl_
		appconfig.feedBackUrl = self.feedBackUrl_
		appconfig.sendfeedUrl = self.sendfeedUrl_
		appconfig.hotUpdateUrl = self.hotUpdateUrl_
		appconfig.agreementUrl = self.agreementUrl_
		appconfig.isVerify = self.isVerify_ == 1


		local versionInfos = clone(dataTab.version)
		self.mAppUpdateData = versionInfos.app

		-- test
		-- self.mAppUpdateData = self:getTestAppData()
		dump(self.mAppUpdateData, "self.mAppUpdateData")

		NewUpdateMgr.getInstance():cacheAppUpdateData(self.mAppUpdateData)
		self:startUpdateFlow()

	elseif checkint(code) == 2 then
		--停服维护

		Dialog.new({
			parent = self.mScene.mDialogNode,
			titleText = "系统公告",
	        messageText = ""..returnData.codemsg,
	        secondBtnText = "确认",
	        firstBtnText = "退出",
	        closeWhenTouchModel = false,
	        hasFirstButton = false,
	        hasCloseButton = false,
	        callback = function (clickType, passArgs)
	            if clickType == Dialog.SECOND_BTN_CLICK then
	            	-- self.mRetryCounts = ShellUpdateController.s_retryCounts
	             --    self:requestFirstAPI()
	            elseif clickType == Dialog.FIRST_BTN_CLICK then
	            	--self:quitApp()
	            end
	        end,
	    }):show()
	end
end

function ShellUpdateController:onResponseFirstAPIFailed(errData)
	-- self:stopTimer()
	dump(errData)
	if self.mSchedulerPool then
		-- 延迟一些间隔后再重新请求，为了给iOS访问网络确认弹窗预留时间
		local delay = self.s_failRetryDelay[self.mRetryCounts]
	
		self.mSchedulerPool:delayCall(handler(self, self.tryRequestFirstAPIAgain), delay)
	else
		self:tryRequestFirstAPIAgain()
	end
end

function ShellUpdateController:tryRequestFirstAPIAgain()
	-- 第一次重试的时候显示菊花
	self.mScene:showJuhua()
	self.mRetryCounts = self.mRetryCounts - 1
	if self.mRetryCounts > 0 then
		if self.mRetryCounts <= 1 then
			self.firstApiUrl = self:getFirstApi(true)
			--自动切换域名
		end
		self:requestFirstAPI(self.firstApiUrl)
	else
		local hasFirstButton = true
		local firstBtnText = "退出"
		if device.platform == "ios" then
			hasFirstButton = false
			firstBtnText = nil
		end
		Dialog.new({
			parent = self.mScene.mDialogNode,
			titleText = "连接异常",
	        messageText = "无法连接到服务器，请确认您的网络连接状况后重试",
	        secondBtnText = "确认",
	        firstBtnText = firstBtnText,
	        closeWhenTouchModel = false,
	        hasFirstButton = hasFirstButton,
	        hasCloseButton = false,
	        callback = function (clickType, passArgs)
	            if clickType == Dialog.SECOND_BTN_CLICK then
	            	self.mRetryCounts = ShellUpdateController.s_retryCounts
	            	--临时切到新域名
	            	self.firstApiUrl = self:getFirstApi(true)
	                self:requestFirstAPI()
	            elseif clickType == Dialog.FIRST_BTN_CLICK then
	            	self:quitApp()
	            end
	        end,
	    }):show()
	end
end

-- 只接收App更新下载的回调，Lua更新的走AssetsManagerEx逻辑
function ShellUpdateController:onAppDownloadProgressCallback(downloadedSize, totalSize, downloadInfo)
	if (not downloadInfo) or (downloadInfo.gameid ~= 0) 
		or downloadInfo.type == ConstantConfig.UPDATETYPE.IMPLICIT then
		-- gameid == 100	大厅lua更新
	 	-- gameid == 0		App更新
		return
	end
	if tonumber(totalSize) or 0 <= 0 then
		totalSize = downloadInfo.size
	end
	local percent = math.floor(downloadedSize/totalSize * 100)
	self.mScene:setDownloadProgress(percent)	
end

-- 只接收App更新下载的回调，Lua更新的走AssetsManagerEx逻辑
function ShellUpdateController:onAppDownloadCallback(result, downloadInfo)
	if (not downloadInfo) or (downloadInfo.gameid ~= 0)
	 	or downloadInfo.type == ConstantConfig.UPDATETYPE.IMPLICIT then
	 	-- gameid == 100	大厅lua更新
	 	-- gameid == 0		App更新
		return
	end
	if result then
		-- 下载成功
    	self.mScene:startDownloadProgressQuickFinishAction(downloadInfo)
	else
		-- 下载失败
    	self:setViewState(self.STATE.DOWNLOADFAILED)

	    local updateType = downloadInfo.type
	    local isForceUpdate = NewUpdateMgr.getInstance():isForceUpdate(updateType)

	    local dialog = self:createDownloadFailedDialog(isForceUpdate, 
	    	handler(self, self.onUpdateFlowGoNextByDownloadFaild), 
	    	handler(self, self.onAppUpdateCanceled), 
	    	self.__lastUpdateDialogCallbackPassArgs)
	    dialog:show()
	end
end

function ShellUpdateController:onDownloadActionFlowFinished(downloadInfo)
	if not downloadInfo then
		print("ShellUpdateController:onDownloadActionFlowFinished downloadInfo = ", downloadInfo)
		return
	end
	local updateType = downloadInfo.type or ConstantConfig.UPDATETYPE.NOUPDATE
	local isForceUpdate = NewUpdateMgr.getInstance():isForceUpdate(updateType)
	local savepath = downloadInfo.savepath
	local md5 = downloadInfo.md5
	local name = downloadInfo.name
	local gameid = tonumber(downloadInfo.gameid)

	if updateType == ConstantConfig.UPDATETYPE.OPTIONAL_BS_DIFF_APK or
		updateType == ConstantConfig.UPDATETYPE.FORCE_BS_DIFF_APK then

		local appData = self.mAppUpdateData
		local version = appData.version
		local apkmd5 = appData.apkmd5

		-- 调用合并
		local apkName = NewUpdateMgr.getInstance():getUpdateApkName(version)
		local apkPath = ConstantConfig.LOCALPATH.APK_DOWNLOADS_PATH .. apkName
		local callback = function(ret)
			if tostring(ret) == "1" then
				-- 合并成功
				local result = NewUpdateMgr.getInstance():verifyApkMD5(apkPath, apkmd5) 
				if result then
					-- 删除补丁
					NewUpdateMgr.getInstance():removeFile(savepath)
					local yesCallback = function(...)
						NewUpdateMgr.getInstance():installApk(apkPath)
					end

					-- 验证成功
					local desc = "是否安装新版本？"
					-- 调用安装
					local dialog = self:createInstallApkDialog(isForceUpdate, desc, yesCallback, handler(self, self.onAppUpdateCanceled))
					dialog:show()
				else
					-- 验证失败
					-- 删除apk
					-- 删除补丁
					NewUpdateMgr.getInstance():removeFile(apkPath)
					NewUpdateMgr.getInstance():removeFile(savepath)
					local dialog = self:createDownloadFailedDialog(isForceUpdate, 
				    	handler(self, self.onUpdateFlowGoNextByDownloadFaild), 
				    	handler(self, self.onAppUpdateCanceled), 
				    	self.__lastUpdateDialogCallbackPassArgs)
				    dialog:show()
				end

			else
				-- 合并失败
				NewUpdateMgr.getInstance():removeFile(savepath)
				local dialog = self:createDownloadFailedDialog(isForceUpdate, 
			    	handler(self, self.onUpdateFlowGoNextByDownloadFaild), 
			    	handler(self, self.onAppUpdateCanceled), 
			    	self.__lastUpdateDialogCallbackPassArgs)
			    dialog:show()
			end
		end
		NewUpdateMgr.getInstance():genApk(savepath, apkPath, callback)
		-- 调用安装

	elseif updateType == ConstantConfig.UPDATETYPE.OPTIONAL_FULL_APK or
		updateType == ConstantConfig.UPDATETYPE.FORCE_FULL_APK then

		local appData = self.mAppUpdateData
		local desc = "是否安装新版本？"
		local apkPath = ConstantConfig.LOCALPATH.APK_DOWNLOADS_PATH .. name

		local yesCallback = function(...)
			NewUpdateMgr.getInstance():installApk(apkPath)
		end

		-- 调用安装
		local dialog = self:createInstallApkDialog(isForceUpdate, desc, yesCallback, handler(self, self.onAppUpdateCanceled))
		dialog:show()
	end
end

function ShellUpdateController:startUpdateFlow()

	if NewUpdateMgr.getInstance():doesAppHaveUpdate(self.mAppUpdateData) then
		print("有App更新")
		-- 有App更新
		local appData = self.mAppUpdateData
		local updateType = appData.updateType or ConstantConfig.UPDATETYPE.NOUPDATE
		local desc = NewUpdateMgr.getInstance():getUpdateDesc(appData)
		local isForceUpdate = NewUpdateMgr.getInstance():isForceUpdate(updateType)

		if updateType == ConstantConfig.UPDATETYPE.FORCE_BROWSER then
			local desc = appData.desc or "您的客户端版本过低\n请通过浏览器下载安装新版本"
			local url = appData.url
			Dialog.new({
				parent = self.mScene.mDialogNode,
				titleText = "发现更新",
		        messageText = desc,
		        firstBtnText = "确定",
		        closeWhenTouchModel = false,
		        hasFirstButton = false,
		        hasCloseButton = false,
		       	dontAutoHideByFirstOrSecond = true,
		        callback = function (clickType, dialog, passArgs)
		            if clickType == Dialog.SECOND_BTN_CLICK then
		                NewUpdateMgr.getInstance():openURL(url)
		            elseif clickType == Dialog.FIRST_BTN_CLICK then
		            	
		            end
		        end,
		    }):show()
			return
		end

		local passArgs = appData

		local shouldTipAppUpdate = true
		if not isForceUpdate then
			-- 如果不是强制APP更新，则检查提示历史和提示间隔字段
			local tipInterval = tonumber(self.mAppUpdateData.tipInterval) or 0

			if tipInterval > 0 then
				local updateDAO = NewUpdateMgr.getInstance():getUpdateDAO()
				local infoObj = updateDAO:getAppUpdateInfo()
				local currentAppVersion = NewUpdateMgr.getInstance():getAppVersion()
				local now = os.time()

				if infoObj:isValid() then
					-- 历史数据合法
					local fromVersion = infoObj:getFromVersion()
					local toVersion = infoObj:getToVersion()
					local lastTipTime = infoObj:getLastTipTime()

					if fromVersion == currentAppVersion and
						toVersion == self.mAppUpdateData.version and
						updateType == infoObj:getUpdateType() then
						-- 更新信息验证通过

						if now >= lastTipTime + tipInterval then
							shouldTipAppUpdate = true
							-- 更新提示时间
							infoObj:setLastTipTime(now)
							updateDAO:updateAppUpdateInfo(infoObj)
						else
							-- 未到提示时间 不提示更新
							shouldTipAppUpdate = false
						end
					else

						-- 更新信息验证不通过
						-- 用新的更新信息覆盖
						shouldTipAppUpdate = true
						infoObj:setFromVersion(currentAppVersion)
						infoObj:setToVersion(self.mAppUpdateData.version)
						infoObj:setLastTipTime(now)
						infoObj:setUpdateType(updateType)
						updateDAO:updateAppUpdateInfo(infoObj)
					end
				else
					-- 历史数据不合法
					-- 作为新收到的更新信息提示
					shouldTipAppUpdate = true
					infoObj:setFromVersion(currentAppVersion)
					infoObj:setToVersion(self.mAppUpdateData.version)
					infoObj:setLastTipTime(now)
					infoObj:setUpdateType(updateType)
					updateDAO:updateAppUpdateInfo(infoObj)
				end
			end
		end
		
		if shouldTipAppUpdate then
			local dialog = self:createUpdateDialog(isForceUpdate, desc, 
				handler(self, self.onStartAppUpdate), handler(self, self.onAppUpdateCanceled), passArgs)
			dialog:show()
			-- 如果不能提示App更新，需要继续走Lua更新流程，就不需要return了
			return
		end
	end

	print("ShellUpdateController: 无App更新")
	-- 检查Lua更新
	self:requestCheckUpdate()
end

function ShellUpdateController:onStartAppUpdate(dialog, passArgs)
	print("ShellUpdateController:onStartAppUpdate", dialog, passArgs)
	local appData = passArgs

	local updateType = appData.updateType or ConstantConfig.UPDATETYPE.NOUPDATE

	if updateType == ConstantConfig.UPDATETYPE.OPTIONAL_FULL_APK or
		updateType == ConstantConfig.UPDATETYPE.FORCE_FULL_APK then
		-- 完整apk更新
		print("ShellUpdateController:onStartAppUpdate FULL_APK")
		if dialog then
			dialog:hidePanel_()
		end
		self:setViewState(self.STATE.DOWNLOADING, "正在下载安装包")

		NewUpdateMgr.getInstance():downloadAppUpdate(appData)
		return
	end

	if updateType == ConstantConfig.UPDATETYPE.OPTIONAL_APP_STORE or
		updateType == ConstantConfig.UPDATETYPE.FORCE_APP_STORE then
		-- iOS APP Store更新
		print("ShellUpdateController:onStartAppUpdate APP_STORE")
		if dialog then
			-- appstore只能通过浏览器跳转，所以不能隐藏弹窗
			-- dialog:hidePanel_()
		end
		NewUpdateMgr.getInstance():downloadAppUpdate(appData)
		return
	end

	if updateType == ConstantConfig.UPDATETYPE.OPTIONAL_BS_DIFF_APK or
		updateType == ConstantConfig.UPDATETYPE.FORCE_BS_DIFF_APK then
		-- apk差异更新
		print("ShellUpdateController:onStartAppUpdate BS_DIFF_APK")
		if dialog then
			dialog:hidePanel_()
		end
		self:setViewState(self.STATE.DOWNLOADING, "正在下载补丁包")
		NewUpdateMgr.getInstance():downloadAppUpdate(appData)
		return
	end

	print("error: #########No valid updateType#########")
end

function ShellUpdateController:onAppUpdateCanceled(dialog, passArgs)
	-- 因为强制更新点取消会被Dialog杀进程，所以此处不判断
	if dialog then
		dialog:hidePanel_()
	end

	-- 进入下一步检查Lua更新
	self:requestCheckUpdate()
end

-- 目前只通过下载失败弹窗确定回调
function ShellUpdateController:onUpdateFlowGoNextByDownloadFaild(dialog, passArgs)
	print("ShellUpdateController:onUpdateFlowGoNextByDownloadFaild", dialog, passArgs)
	if self.__lastUpdateDialogYesCallback then
		print("self.__lastUpdateDialogYesCallback => ", self.__lastUpdateDialogYesCallback)
		self.__lastUpdateDialogYesCallback(dialog, self.__lastUpdateDialogCallbackPassArgs)
	end
end

-- 检查大厅Lua更新
function ShellUpdateController:requestCheckUpdate()
	NewUpdateMgr.getInstance():checkSingleGameUpdate(GAME_ID, self, self.onHotUpdateResponse, 4)
end

function ShellUpdateController:releaseCheckUpdateCallback()
	NewUpdateMgr.getInstance():clearCheckGameUpdateCallback(self)
end

function ShellUpdateController:onHotUpdateResponse(result, url, params, data)
	dump(data, "ShellUpdateController:onHotUpdateResponse")
	self.mScene:hideJuhua()
	local function onHotUpdateRequestError()
		local hasFirstButton = true
		local firstBtnText = "退出"
		if device.platform == "ios" then
			hasFirstButton = false
			firstBtnText = nil
		end
		Dialog.new({
			parent = self.mScene.mDialogNode,
			titleText = "连接异常",
	        messageText = "无法连接到服务器，请确认您的网络连接状况后重试",
	        secondBtnText = "确认",
	        firstBtnText = firstBtnText,
	        closeWhenTouchModel = false,
	        hasFirstButton = hasFirstButton,
	        hasCloseButton = false,
	        callback = function (clickType, passArgs)
	            if clickType == Dialog.SECOND_BTN_CLICK then
	            	self.mRetryCounts = ShellUpdateController.s_retryCounts
	                self:requestCheckUpdate()
	            elseif clickType == Dialog.FIRST_BTN_CLICK then
	            	self:quitApp()
	            end
	        end,
	    }):show()
	end

	if result then
		-- 成功状态200
		local code = data.code
		if checkint(code) == 1 then
			local urlPrefix, version, alert = NewUpdateMgr.getInstance():getCheckedGameUpdateResult(GAME_ID)

			local shellGameVersion = GAME_VERSION
			if NewUpdateMgr.getInstance():isFullVersionNewer(version, shellGameVersion) then
				self:recreateAssetsManagerEx(urlPrefix)
				local startLuaUpdate = function()
					self:setViewState(self.STATE.DOWNLOADING)
					self.mAssetsManagerEx:luaUpdate()
				end
				if tonumber(alert) == 1 then
					-- 如果是显式alert，则等待用户弹窗确认
					self:createUpdateDialog(true, "是否立即更新？", function(dialog, ...) 
							dialog:hidePanel_()
							startLuaUpdate()
						end, nil):show()
				else
					-- 否则直接开始下载
					startLuaUpdate()
				end
			else
				self:releaseAssetsManagerEx()
				self:endGameHallShellUpdate()
			end
		else
			print("cannot get php update response")
			onHotUpdateRequestError()
		end
	else
		
	end
end

function ShellUpdateController:releaseResources()
	-- 释放所有纹理
	print("----------------释放所有纹理----------------")
	cc.Director:getInstance():getTextureCache():removeAllTextures()
	print("----------------释放所有精灵帧----------------")
	cc.SpriteFrameCache:getInstance():removeSpriteFrames()

	-- print("----------------重启Director----------------")
	--cc.Director:getInstance():restart()
end

-- 20190108 此函数有可能会释放旧的NewUpdateMgr
function ShellUpdateController:reloadLuaPackages()
	print("--------------------------------ShellUpdateController:reloadLuaPackages-----------------------------------")

	local olderUpdateMgrClass = NewUpdateMgr
	local olderUpdateMgr = NewUpdateMgr.getInstance()
	local older_appconfig = appconfig

	local gamePathPattern = "^" .. GAME_PATH .. "%."

	-- 清除已加载lua代码模块记录
	-- 不清除GameHallShellConfig.lua
	for k,v in pairs(package.loaded) do
		if string.match(k, "^core%.") or
			string.match(k, "^app%.") or
			string.match(k, "^cocos%.") or
			string.match(k, gamePathPattern) or
			string.match(k, "^gamehall%.") or 
			string.match(k, "^packages%.") or
			k == "appentry" or
			k == "config" or
			k == "channelConfig" or
			k == "appconfig" then
			package.loaded[k] = nil
		end
	end

	-- 清一层C++全路径缓存
    cc.FileUtils:getInstance():purgeCachedEntries()

	-- 重新加载
	require("config")
	require("cocos.init")
	require("core.init")

	-- appconfig 新增字段的可能性
	local newer_appconfig = require("appconfig")
	for k, v in pairs(older_appconfig) do
		newer_appconfig[k] = v
	end
	cc.exports.appconfig = newer_appconfig

	if self.mAppUpdateData and olderUpdateMgr:doesAppHaveUpdate(self.mAppUpdateData) then
		-- 尝试加载新的NewUpdateMgr
		local result, newerUpdateMgrClass = pcall(require, GAME_PATH .. ".src.gamehallshell.update.NewUpdateMgr")
		if result then
			local newerUpdateMgr = newerUpdateMgrClass.getInstance()
			print("newerUpdateMgr => ", newerUpdateMgr, "olderUpdateMgr => ", olderUpdateMgr, "isSameObj => ", newerUpdateMgr == olderUpdateMgr)
			if newerUpdateMgr == olderUpdateMgr then
				-- 这条代码其实并没有什么用途，因为gamehall.src.update.NewUpdateMgr会被从package.loaded中清空
				-- 当lua文件被重新加载时，不论它是否被修改过，该上下文都是不同的
				newerUpdateMgr:cacheAppUpdateData(self.mAppUpdateData)
			else
				newerUpdateMgr:cacheAppUpdateData(self.mAppUpdateData)
				-- 释放掉旧的
				olderUpdateMgrClass.releaseInstance()
			end
		else
			olderUpdateMgr:cacheAppUpdateData(self.mAppUpdateData)
		end
	end
end


function ShellUpdateController:endGameHallShellUpdate()
	print("ShellUpdateController:endGameHallShellUpdate")
	appconfig.cdnGameUrl = self.cdnGameUrl_
	appconfig.gatewayUrl = self.gatewayUrl_
	appconfig.indexUrl = self.indexUrl_
	appconfig.feedBackUrl = self.feedBackUrl_
	appconfig.sendfeedUrl = self.sendfeedUrl_
	appconfig.hotUpdateUrl = self.hotUpdateUrl_
	appconfig.isVerify = self.isVerify_ == 1

	
	self:__enterApp()
end

--- 界面跳转，根据php返回的isJump参数判断是进大厅还是进壳游戏
-- 0 进大厅 1 进壳游戏
function ShellUpdateController:__enterApp()
	print("ShellUpdateController:__enterApp => self.isJump:", self.isJump)
	if self.isJump == 0 then
		-- 跳转大厅
		-- 1. 判断大厅是否安装，如果安装，跳转到大厅更新场景
		-- 2. 如果大厅没有安装，则在本场景下载安装大厅，再跳转到大厅更新场景
		if require("app.manager.GameManager").getInstance():isGameInstalled(100) then
			self:__enterGameHall()
		else
			self:__startCheckHallUpdate()
		end
	else
		-- 跳转壳游戏
		self:__enterShellGame()
	end
end

function ShellUpdateController:__enterShellGame()
	print("ShellUpdateController:__enterShellGame")

	-- self:__doAfterRotateScreenBack(function()
		require("config")
		require("cocos.init")
		require("core.init")
		require("app.init")
		-- 包含app.init

		cc.exports.appconfig = require("appconfig")

		local gameManager = require("app.manager.GameManager").getInstance()
		gameManager:initPkgName(GAME_ID, GAME_PATH)
		gameManager:initGame(GAME_ID)

		require("app.App").new():run(GAME_ID)
	-- end)
end

function ShellUpdateController:__enterGameHall()
	print("ShellUpdateController:__enterGameHall")

	self:__doAfterRotateScreenBack(function()
		require("config")
		require("cocos.init")
		require("core.init")
		-- 没有app.init

		cc.exports.appconfig = require("appconfig")

		if cc.enable_global then
			cc.enable_global()
		end

		require("gamehall.src.update.NewUpdateController").new()
	end)
end

-----------------------------------------------下载大厅相关 start-----------------------------------------------

function ShellUpdateController:__startCheckHallUpdate()
	self.mScene:showJuhua()
	self:setViewState(self.STATE.NONE)
	NewUpdateMgr.getInstance():checkSingleGameUpdate(100, self, self.__onHallHotUpdateResponse, 4)
end

function ShellUpdateController:__onHallHotUpdateResponse(result, url, params, data)
	dump(data, "NewUpdateController:__onHallHotUpdateResponse")
	self.mScene:hideJuhua()
	local function __innerOnHotUpdateRequestError()
		local hasFirstButton = true
		local firstBtnText = "退出"
		if device.platform == "ios" then
			hasFirstButton = false
			firstBtnText = nil
		end
		Dialog.new({
			parent = self.mScene.mDialogNode,
			titleText = "连接异常",
	        messageText = "无法连接到服务器，请确认您的网络连接状况后重试",
	        secondBtnText = "确认",
	        firstBtnText = firstBtnText,
	        closeWhenTouchModel = false,
	        hasFirstButton = hasFirstButton,
	        hasCloseButton = false,
	        callback = function (clickType, passArgs)
	            if clickType == Dialog.SECOND_BTN_CLICK then
	                self:__startCheckHallUpdate()
	            elseif clickType == Dialog.FIRST_BTN_CLICK then
					self:quitApp()
	            end
	        end,
	    }):show()
	end

	if result then
		-- 成功状态200
		local code = data.code
		if checkint(code) == 1 then
			local urlPrefix, version, alert = NewUpdateMgr.getInstance():getCheckedGameUpdateResult(100)

			local currentHallVersion = require("app.manager.GameManager").getInstance():getGameVersion(100)
			if NewUpdateMgr.getInstance():isFullVersionNewer(version, currentHallVersion) then
				self:__recreateGameHallAssetsManagerEx(urlPrefix)
				local startLuaUpdate = function()
					self:setViewState(self.STATE.DOWNLOADING, "正在下载游戏大厅")
					self.mAssetsManagerEx:luaUpdate()
				end
				if tonumber(alert) == 1 then
					-- 如果是显式alert，则等待用户弹窗确认
					self:createUpdateDialog(true, "是否立即更新？", function(dialog, ...) 
							dialog:hidePanel_()
							startLuaUpdate()
						end, nil):show()
				else
					-- 否则直接开始下载
					startLuaUpdate()
				end
			else
				self:releaseAssetsManagerEx()
				self:__endGameHallDownload()
			end
		else
			print("cannot get php update response")
			onHotUpdateRequestError()
		end
	else
		
	end
end

function ShellUpdateController:__createEmptyGameHallManifestFiles()
	local packagePath = "gamehall"
	local remoteManifestUrl = "project.manifest"
	local remoteVersionUrl = "version.manifest"
	NewUpdateMgr.getInstance():createEmptyManifestFilesByPackagePath(packagePath, remoteManifestUrl, remoteVersionUrl)
end

function ShellUpdateController:__recreateGameHallAssetsManagerEx(urlPrefix)
	local versionManifest = "gamehall/version.manifest"
	local projectManifest = "gamehall/project.manifest"
	local storagePath = NewConstantConfig.LOCALPATH.UPDATES_PATH .. "gamehall"
	self.mLastUrlPrefix = urlPrefix or self.mLastUrlPrefix

	if self.mAssetsManagerEx then
		self:releaseAssetsManagerEx()
	end

	self:__createEmptyGameHallManifestFiles()

	local amEx, listener = NewUpdateMgr.getInstance():createAssetsManagerEx(100, versionManifest, projectManifest, storagePath, 
		handler(self, self.__onHallUpdateCallback), self.mLastUrlPrefix)
	if amEx then
		-- 用于释放
		self.mAssetsManagerEx = amEx
	else
		print("cant not create a legal AssetsManagerEx")
	end
end

function ShellUpdateController:__onHallUpdateCallback(event)
	local eventCode = event:getEventCode()
	if eventCode == cc.EventAssetsManagerEx.EventCode.ERROR_NO_LOCAL_MANIFEST
	or eventCode == cc.EventAssetsManagerEx.EventCode.ERROR_DOWNLOAD_MANIFEST
	or eventCode == cc.EventAssetsManagerEx.EventCode.ERROR_PARSE_MANIFEST
	or eventCode == cc.EventAssetsManagerEx.EventCode.UPDATE_FAILED then
		-- 没有localManifest文件，或者本地描述文件加载失败
		self:createDownloadFailedDialog(true, function(dialog, ...)
				dialog:hidePanel_()
				self:setViewState(self.STATE.DOWNLOADING, "正在下载游戏大厅")
				self:__recreateGameHallAssetsManagerEx()
				self.mAssetsManagerEx:luaUpdate()
			end, nil):show()
	elseif eventCode == cc.EventAssetsManagerEx.EventCode.NEW_VERSION_FOUND then
		-- 加载remoteManifest后，发现有新版本
	elseif eventCode == cc.EventAssetsManagerEx.EventCode.UPDATE_FINISHED then
		-- 解压成功，更新成功
		self:setViewState(self.STATE.UPDATE_FINISHED)
		self:releaseAssetsManagerEx()

		self:releaseResources()
		self:reloadLuaPackages()
		self:__endGameHallDownload()
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
	        strInfo = string.format("Downloading %s: %d%%", assetId, percent)
	        self.mScene:setDownloadProgress(percent)
	    end
	    print("downloading progress", strInfo)
	elseif eventCode == cc.EventAssetsManagerEx.EventCode.ALREADY_UP_TO_DATE then
		-- 检查更新时，比对localManifest和remoteManifest版本信息时，如果版本号相同，则判断为已经更新到最新版本
		self:releaseAssetsManagerEx()
		self:__endGameHallDownload()

	elseif eventCode == cc.EventAssetsManagerEx.EventCode.ERROR_DECOMPRESS then
		-- 解压文件失败，不会中断逻辑
	elseif eventCode == cc.EventAssetsManagerEx.EventCode.ERROR_UPDATING then
		-- 更新出错/失败（downloader出错/失败）
	end
end

function ShellUpdateController:__endGameHallDownload()
	print("ShellUpdateController:__endGameHallDownload")
	appconfig.cdnGameUrl = self.cdnGameUrl_
	appconfig.gatewayUrl = self.gatewayUrl_
	appconfig.indexUrl = self.indexUrl_
	appconfig.feedBackUrl = self.feedBackUrl_
	appconfig.sendfeedUrl = self.sendfeedUrl_
	appconfig.hotUpdateUrl = self.hotUpdateUrl_
	appconfig.isVerify = self.isVerify_ == 1

	self:__enterGameHall()
end

-----------------------------------------------下载大厅相关 end-----------------------------------------------

function ShellUpdateController:onShellGameUpdateCallback(event)
	local eventCode = event:getEventCode()
	if eventCode == cc.EventAssetsManagerEx.EventCode.ERROR_NO_LOCAL_MANIFEST
	or eventCode == cc.EventAssetsManagerEx.EventCode.ERROR_DOWNLOAD_MANIFEST
	or eventCode == cc.EventAssetsManagerEx.EventCode.ERROR_PARSE_MANIFEST
	or eventCode == cc.EventAssetsManagerEx.EventCode.UPDATE_FAILED then
		-- 没有localManifest文件，或者本地描述文件加载失败
		self:createDownloadFailedDialog(true, function(dialog, ...)
				dialog:hidePanel_()
				self:setViewState(self.STATE.DOWNLOADING)
				self:recreateAssetsManagerEx()
				self.mAssetsManagerEx:luaUpdate()
			end, nil):show()
	elseif eventCode == cc.EventAssetsManagerEx.EventCode.NEW_VERSION_FOUND then
		-- 加载remoteManifest后，发现有新版本
	elseif eventCode == cc.EventAssetsManagerEx.EventCode.UPDATE_FINISHED then
		-- 解压成功，更新成功
		self:setViewState(self.STATE.UPDATE_FINISHED)
		self:releaseAssetsManagerEx()

		self:releaseResources()
		self:reloadLuaPackages()
		self:endGameHallShellUpdate()
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
	        strInfo = string.format("Downloading %s: %d%%", assetId, percent)
	        self.mScene:setDownloadProgress(percent)
	    end
	    print("downloading progress", strInfo)
	elseif eventCode == cc.EventAssetsManagerEx.EventCode.ALREADY_UP_TO_DATE then
		-- 检查更新时，比对localManifest和remoteManifest版本信息时，如果版本号相同，则判断为已经更新到最新版本
		self:releaseAssetsManagerEx()
		self:endGameHallShellUpdate()

	elseif eventCode == cc.EventAssetsManagerEx.EventCode.ERROR_DECOMPRESS then
		-- 解压文件失败，不会中断逻辑
	elseif eventCode == cc.EventAssetsManagerEx.EventCode.ERROR_UPDATING then
		-- 更新出错/失败（downloader出错/失败）
	end
end

function ShellUpdateController:setViewState(...)
	self.mScene:setViewState(...)
end

-- 退出
function ShellUpdateController:quitApp()
	-- 摘抄自AppBase:exit
	print("ShellUpdateController:quitApp")
	cc.Director:getInstance():endToLua()
    if device.platform == "windows" or device.platform == "mac" then
        os.exit()
    end
end

function ShellUpdateController:createUpdateDialog(isForceUpdate, desc, yesCallback, noCallback, callbackPassArgs)

	local yesFuncs = {}
	local noFuncs = {}

	if yesCallback and type(yesCallback) == "function" then
		self.__lastUpdateDialogYesCallback = yesCallback
		self.__lastUpdateDialogCallbackPassArgs = callbackPassArgs
		table.insert(yesFuncs, yesCallback)
	end

	local hasFirstButton = true
	local firstBtnText = "取消下载"
	if isForceUpdate then
		if device.platform == "ios" then
			-- iOS不显示退出游戏按钮，因为无法杀进程
			hasFirstButton = false
			firstBtnText = nil
		else
			firstBtnText = "退出游戏"
			table.insert(noFuncs, handler(self, self.quitApp))
		end
	else
		if noCallback and type(noCallback) == "function" then
			table.insert(noFuncs, noCallback)
		end
	end

	local new_dialog = Dialog.new({
			parent = self.mScene.mDialogNode,
			titleText = "发现新版本",
	        messageText = desc, 
	        secondBtnText = "确认下载",
	        firstBtnText = firstBtnText,
	        closeWhenTouchModel = false,
	        hasFirstButton = hasFirstButton,
	        hasCloseButton = false,
	        dontAutoHideByFirstOrSecond = true,
	        callbackPassArgs = callbackPassArgs,
	        callback = function (clickType, dialog, passArgs)
	            if clickType == Dialog.SECOND_BTN_CLICK then
	                for _, func in ipairs(yesFuncs) do
	                	if func and type(func) == "function" then
	                		print("----createUpdateDialog second----")
	                		print(func,dialog,passArgs)
	                		func(dialog, passArgs)
	                	end
	                end
	            elseif clickType == Dialog.FIRST_BTN_CLICK then
	            	for _, func in ipairs(noFuncs) do
	            		if func and type(func) == "function" then
	            			print("----createUpdateDialog first----")
	                		print(func,dialog,passArgs)
	            			func(dialog, passArgs)
	            		end
	            	end
	            end
	        end,
	    })
	return new_dialog
end

function ShellUpdateController:createDownloadFailedDialog(isForceUpdate, yesCallback, noCallback, callbackPassArgs)

	local yesFuncs = {}
	local noFuncs = {}

	if yesCallback and type(yesCallback) == "function" then
		table.insert(yesFuncs, yesCallback)
	end

	local hasFirstButton = true
	local firstBtnText = "取消下载"
	if isForceUpdate then
		if device.platform == "ios" then
			-- iOS不显示退出游戏按钮，因为无法杀进程
			hasFirstButton = false
			firstBtnText = nil
		else
			firstBtnText = "退出游戏"
			table.insert(noFuncs, handler(self, self.quitApp))
		end
	else
		if noCallback and type(noCallback) == "function" then
			table.insert(noFuncs, noCallback)
		end
	end

	local new_dialog = Dialog.new({
			parent = self.mScene.mDialogNode,
			titleText = "更新失败",
	        messageText = "下载失败了，请检查网络状况后重试",
	        secondBtnText = "重新下载",
	        firstBtnText = firstBtnText,
	        closeWhenTouchModel = false,
	        hasFirstButton = hasFirstButton,
	        hasCloseButton = false,
	       	dontAutoHideByFirstOrSecond = true,
	       	callbackPassArgs = callbackPassArgs,
	        callback = function (clickType, dialog, passArgs)
	            if clickType == Dialog.SECOND_BTN_CLICK then
	                for _, func in ipairs(yesFuncs) do
	                	if func and type(func) == "function" then
	                		func(dialog, passArgs)
	                	end
	                end
	            elseif clickType == Dialog.FIRST_BTN_CLICK then
	            	for _, func in ipairs(noFuncs) do
	            		if func and type(func) == "function" then
	            			func(dialog, passArgs)
	            		end
	            	end
	            end
	        end,
	    })
    return new_dialog
end

function ShellUpdateController:createInstallApkDialog(isForceUpdate, desc, yesCallback, noCallback, callbackPassArgs)

	local yesFuncs = {}
	local noFuncs = {}

	if yesCallback and type(yesCallback) == "function" then
		table.insert(yesFuncs, yesCallback)
	end

	local hasFirstButton = true
	local firstBtnText = "取消安装"
	if isForceUpdate then
		if device.platform == "ios" then
			-- iOS不显示退出游戏按钮，因为无法杀进程
			hasFirstButton = false
			firstBtnText = nil
		else
			firstBtnText = "退出游戏"
			table.insert(noFuncs, handler(self, self.quitApp))
		end
	else
		if noCallback and type(noCallback) == "function" then
			table.insert(noFuncs, noCallback)
		end
	end
	
	local new_dialog = Dialog.new({
			parent = self.mScene.mDialogNode,
			titleText = "发现新版本",
	        messageText = desc, 
	        secondBtnText = "确认安装",
	        firstBtnText = firstBtnText,
	        closeWhenTouchModel = false,
	        hasFirstButton = hasFirstButton,
	        hasCloseButton = false,
	        dontAutoHideByFirstOrSecond = true,
	        callbackPassArgs = callbackPassArgs,
	        callback = function (clickType, dialog, passArgs)
	            if clickType == Dialog.SECOND_BTN_CLICK then
	                for _, func in ipairs(yesFuncs) do
	                	if func and type(func) == "function" then
	                		print("----createInstallApkDialog second----")
	                		print(func,dialog,passArgs)
	                		func(dialog, passArgs)
	                	end
	                end
	            elseif clickType == Dialog.FIRST_BTN_CLICK then
	            	for _, func in ipairs(noFuncs) do
	            		if func and type(func) == "function" then
	            			print("----createInstallApkDialog first----")
	                		print(func,dialog,passArgs)
	            			func(dialog, passArgs)
	            		end
	            	end
	            end
	        end,
	    })
	return new_dialog
end

--------------------------测试----------------------------
function ShellUpdateController:getTestAppData()
	local app = {}
	app.gameid = 0
	app.md5 = "E0210936C458075F7BF81DB459DB99B1"
	app.size = 38826392

	-- app.md5 = "3f2ddc491b88c8b27e80329747ca01be"
	-- app.size = 33435642
	app.version = "1.0.20"
	-- app.updateType = ConstantConfig.UPDATETYPE.FORCE_FULL_APK
	app.updateType = ConstantConfig.UPDATETYPE.OPTIONAL_FULL_APK
	-- app.updateType = ConstantConfig.UPDATETYPE.FORCE_BS_DIFF_APK
	-- app.updateType = ConstantConfig.UPDATETYPE.OPTIONAL_BS_DIFF_APK
	-- app.updateType = ConstantConfig.UPDATETYPE.FORCE_BROWSER
	-- app.url = "http://192.168.1.158/game/staticres/android/hunan/test/test.apk"
	app.url = "http://192.168.1.158/game/staticres/android/hunan/test/test.apk"
	app.diffUrl = "http://192.168.1.158/game/staticres/android/hunan/test/test.patch"
	app.apkmd5 = "E0210936C458075F7BF81DB459DB99B1"
	app.clientpath = ""
	-- app.desc = "测试bsdiff"
	app.desc = "赵令畤《清平乐》\n春风依旧,\n著意随堤柳。\n搓得蛾儿黄欲就,\n天气清明时候。\n去年紫陌青门,\n今宵雨魄云魂。\n断送一生憔悴,\n只销几个黄昏。"
	app.tipInterval = 30 -- 弹窗提示间隔时间间隔（秒），只对非强制app更新有效
	return app
end

return ShellUpdateController