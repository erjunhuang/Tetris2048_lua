-- 通过cocos2dx AssetsManagerEx实现的更新/下载功能
--[[
		下面是Cocos2dx 3.10版本中的工作逻辑，目前已经手动将AssetsManangerEx及依赖库更新到3.16版本的库，所以会有些差异
		C++中AssetsManagerEx逻辑和工作流程：
		1.通过create函数new出AssetsManagerEx实例对象
		2.在构造函数：AssetsManagerEx::AssetsManagerEx(const std::string& manifestUrl, const std::string& storagePath)中
			a.用manifestUrl初始化_manifestUrl成员变量，用storagePath初始化_storagePath成员变量，
			b.通过LISTENER_ID + pointer的形式创建给EventDispatcher的事件名称，
			c.将状态更新为State::UNCHECKED，
			d.创建network::Downloader智能指针，并设置一堆回调，
			e.三个核心逻辑路径
			  _cacheVersionPath=_storagePath+"version.manifest"，
			  _cacheManifestPath=_storagePath+"project.manifest"，
			  _tempManifestPath=_storagePath+"project.manifest.temp"，
			f.调用void AssetsManagerEx::initManifests(const std::string& manifestUrl)加载manifest
		3.在initManifests中调用void AssetsManagerEx::loadLocalManifest(const std::string& manifestUrl)函数：
			a.如果本地存在_cacheManifestPath则加载_cacheManifestPath为cachedManifest
			b.加载_manifestUrl为_localManifest：
				I.如果加载_manifestUrl成功，判断_localManifest中记录的版本号是不是大于cachedManifest中的版本号（通过strcmp，TODO 这里需要修改），如果大于，则清空storagePath（即清除更新路径）
				  如果不大于，则将cachedManifest赋值于_localManifest，然后获取_localManifest中的所有assets为_assets，并将描述文件中的所有索引路径添加到Director的索引路径中
				II.如果加载_manifestUrl失败，则广播一个ERROR_NO_LOCAL_MANIFEST错误（然而那时候Lua的事件监听还没有扔进去，所以收不到）
			c.加载_tempManifestPath为_tempManifest，如果加载失败，就将该文件删掉
			d.初始化成功的条件是：
				I._localManifest加载成功
				II._tempManifest创建成功（内存足够）
				III._remoteManifest创建成功（内存足够）
		4.调用checkUpdate（初始化成功并且_localManifest加载成功），否则会广播一个ERROR_NO_LOCAL_MANIFEST错误
			switch (_updateState) {
		        case State::UNCHECKED:
		        case State::PREDOWNLOAD_VERSION:
		        {
		            downloadVersion();
		        }
		            break;
		        case State::UP_TO_DATE:
		        {
		            dispatchUpdateEvent(EventAssetsManagerEx::EventCode::ALREADY_UP_TO_DATE);
		        }
		            break;
		        case State::FAIL_TO_UPDATE:
		        case State::NEED_UPDATE:
		        {
		            dispatchUpdateEvent(EventAssetsManagerEx::EventCode::NEW_VERSION_FOUND);
		        }
		            break;
		        default:
		            break;
		    }
		5.调用update（初始化成功并且_localManifest加载成功），否则会广播一个ERROR_NO_LOCAL_MANIFEST错误
			_waitToUpdate = true;

		    switch (_updateState) {
		        case State::UNCHECKED:
		        {
		            _updateState = State::PREDOWNLOAD_VERSION;
		        }
		        case State::PREDOWNLOAD_VERSION:
		        {
		            downloadVersion();
		        }
		            break;
		        case State::VERSION_LOADED:
		        {
		            parseVersion();
		        }
		            break;
		        case State::PREDOWNLOAD_MANIFEST:
		        {
		            downloadManifest();
		        }
		            break;
		        case State::MANIFEST_LOADED:
		        {
		            parseManifest();
		        }
		            break;
		        case State::FAIL_TO_UPDATE:
		        case State::NEED_UPDATE:
		        {
		            // Manifest not loaded yet
		            if (!_remoteManifest->isLoaded())
		            {
		                _waitToUpdate = true;
		                _updateState = State::PREDOWNLOAD_MANIFEST;
		                downloadManifest();
		            }
		            else
		            {
		                startUpdate();
		            }
		        }
		            break;
		        case State::UP_TO_DATE:
		        case State::UPDATING:
		        case State::UNZIPPING:
		            _waitToUpdate = false;
		            break;
		        default:
		            break;
		    }
		6.void AssetsManagerEx::downloadVersion()函数：
			a.如果当前状态大于State::PREDOWNLOAD_VERSION，直接返回
			b.如果从_localManifest中获取的remoteVersionUrl成功（即远端的version.manifest Url），则通过下载器下载该文件，并以"@version"做为标识符
			c.如果没有获取remoteVersionUrl，则进入State::PREDOWNLOAD_MANIFEST状态，调用downloadManifest()函数下载远端的"project.manifest"文件
		7.void AssetsManagerEx::onSuccess(const std::string &srcUrl, const std::string &storagePath, const std::string &customId)函数，即downloader的下载成功回调函数：
			a.如果标识符为"@version"，则当前状态进入State::VERSION_LOADED，调用parseVersion()函数解析该version.manifest
			b.如果标识符为"@manifest"，则当前状态进入State::MANIFEST_LOADED，调用parseManifest()函数解析该project.manifest
			c.资源下载成功逻辑：
				I.从_remoteManifest找到该asset，并标记为下载成功，如果该asset是压缩包，则放进待压缩队列
				II.等待下载_totalWaitToDownload减一，_percentByFile = 100 * (float)(_totalToDownload - _totalWaitToDownload) / _totalToDownload;广播UPDATE_PROGRESSION，通知下载完成进度
				III.广播ASSET_UPDATED，通知有资源更新/下载成功
				IV.如果在失败记录中找到该asset记录，则将该失败记录清除
				V.如果等待下载任务数小于等于0（跑完一遍下载），如果有失败任务_failedUnits，则调用void Manifest::saveToFile(const std::string &filepath)函数将_tempManifest保存在_tempManifestPath
				  状态更新为State::FAIL_TO_UPDATE更新失败，广播UPDATE_FAILED，通知更新失败
				  如果没有失败任务，则调用void AssetsManagerEx::updateSucceed()
		8.void AssetsManagerEx::updateSucceed()函数（进入这个函数说明所有要下载的任务都下载成功了）：
			a.将_tempManifest文件（project.manifest.temp）文件更名为_storagePath中的"project.manifest"文件
			b.释放原_localManifest，将_remoteManifest赋值于_localManifest，调用prepareLocalManifest()函数
			c.将状态更新为State::UNZIPPING，异步解压压缩包资源
			b.如果途中有一个压缩包解压失败，则删除该文件，并中断，广播ERROR_DECOMPRESS，通知解压失败，否则广播UPDATE_FINISHED，通知更新结束
		9.void AssetsManagerEx::parseVersion()函数（解析下载下来的version文件）：
			a.调用_remoteManifest->parseVersion(_cacheVersionPath)，如果_remoteManifest加载成功，则：
				I.如果_localManifest和_remoteManifest中的版本号一样，则状态更新为State::UP_TO_DATE，广播ALREADY_UP_TO_DATE，通知已是最新版本
				II.如果版本号不一样（TODO 这里需要修改），则状态更新为State::NEED_UPDATE需要更新，并广播NEW_VERSION_FOUND，通知发现新版本，如果_waitToUpdate标识位为真，则状态再变更为State::PREDOWNLOAD_MANIFEST，调用downloadManifest()函数下载远端manifest
			b.如果_remoteManifest没有加载成功，状态更新为State::PREDOWNLOAD_MANIFEST，调用downloadManifest()函数下载远端project.manifest
		10.void AssetsManagerEx::downloadManifest()函数（与downloadVersion函数类似）：
			a.如果当前状态不是State::PREDOWNLOAD_MANIFEST，直接返回
			b.如果从_localManifest中获取的remoteManifestUrl成功（即远端的project.manifest Url），则通过下载器下载该文件，并以"@manifest"做为标识符
			c.如果没有获取remoteManifestUrl，则进入State::UNCHECKED状态，广播ERROR_DOWNLOAD_MANIFEST，通知下载project.manifest出错
		11.TODO 如果是压缩包更新，解压过程中杀进程的处理和如果是单文件更新，下载过程中杀进程的处理
		12.TODO 如果是收到广播 UPDATE_FAILED 事件，则不能重新调用update来继续update
		]]

local Utils = import(".Utils")
local ConstantConfig = import(".ConstantConfig")
local NewConstantConfig = import(".NewConstantConfig")
local NewTaskManager = import(".NewTaskManager")
local UpdateDAO = import(".UpdateDAO")
local GameConfig = require(require("GameHallShellConfig").GAME_CONFIG_PATH)

local gamehallshell_src_path = GameConfig.src_path..".gamehallshell."

local NewUpdateMgr = class("NewUpdateMgr")

NewUpdateMgr.s_instance = nil

NewUpdateMgr.getInstance = function()
	if not NewUpdateMgr.s_instance then
		print("NewUpdateMgr.getInstance create new instance")
		NewUpdateMgr.s_instance = NewUpdateMgr.new()
	end
	return NewUpdateMgr.s_instance
end

NewUpdateMgr.releaseInstance = function()
	print("NewUpdateMgr.releaseInstance")
	if NewUpdateMgr.s_instance then
		NewUpdateMgr.s_instance:dtor()
		NewUpdateMgr.s_instance = nil
	end
end


--[[
约定一个gameid只能对应一个AssetsManagerEx，创建出来之后用完要release
创建: NewUpdateMgr:createAssetsManagerEx
清除: releaseAssetsManagerEx，只能在更新/下载出现结果之后才能调用（成功/失败）
界面相关回调注销：removeAssetsManagerExCallback，只注销外部回调
]]
function NewUpdateMgr:ctor()
	-- 创建所需目录， 其中一部分是沿用以前的版本
	local fileUtils = cc.FileUtils:getInstance()
	fileUtils:createDirectory(NewConstantConfig.LOCALPATH.DOWNLOAD_PATH)
	fileUtils:createDirectory(NewConstantConfig.LOCALPATH.PREUPDATE_PATH)
	fileUtils:createDirectory(NewConstantConfig.LOCALPATH.UPDATES_PATH)
	fileUtils:createDirectory(NewConstantConfig.LOCALPATH.APK_DOWNLOADS_PATH)

	self.mPlatform = device.platform
	self.mTaskManager = NewTaskManager.new()

	self.mUpdateDAO = nil
	self.mCacheAppUpdateData = nil

	self.mEventDownloadHandle = nil
	self.mEventDownloadProgressHandle = nil

	self.mDownloadHandler = {}
	self.mDownloadProgressHandler = {}

	-- 缓存AssetsManangerEx及相关，用于继续显示下载记录/进度，格式为{gameid:{am:xxx,listener:xxx}}
	self.mAssetsManagerExCacheTable = {}
	-- 监听某个AssetsManagerEx的lua监听器{gameid:callbacks}
	self.mAssetsManagerExCallbacks = {}

	-- 请求php获取单个更新URL的监听和重试次数{gameid:{callbacks:{obj1:xxx,obj2:xxx,obj3:xxx},requestId:xxx,retryTimes:xxx,}}
	self.mCheckUpdateCaches = {}
	-- 请求php获取多个游戏更新URL的requestId和回调对象{obj:{callback:xxx, requestId:xxx, retryTimes:xxx}}
	self.mCheckMultipleGamesUpdateCaches = {}
	-- 请求php获取更新URL结果缓存{gameid:{urlPrefix:urlPrefix, version:version}}
	self.mCheckedUpdateResults = {}
	-- 更新成功的记录, {gameid:true}
	self.mGameUpdatedRecords = {}

	self:__loadAppInfos()

	self:addEventListener()
end

function NewUpdateMgr:addEventListener()
	if not self.mEventDownloadHandle then
		self.mEventDownloadHandle = core.EventCenter:addEventListener(ConstantConfig.UPDATEEVENT.UPDATE_FILE_DOWNLOAD, handler(self, self.onFileDownload))
	end
	if not self.mEventDownloadProgressHandle then
		self.mEventDownloadProgressHandle = core.EventCenter:addEventListener(ConstantConfig.UPDATEEVENT.UPDATE_FILE_DOWNLOAD_PROGRESS, handler(self, self.onFileDownloadProgress))
	end
end

function NewUpdateMgr:dtor()
	core.EventCenter:removeEventListenersByEvent(ConstantConfig.UPDATEEVENT.UPDATE_FILE_DOWNLOAD)
	core.EventCenter:removeEventListenersByEvent(ConstantConfig.UPDATEEVENT.UPDATE_FILE_DOWNLOAD_PROGRESS)

	self.mTaskManager:clean()
	self.mTaskManager = nil

	self.mUpdateDAO = nil
	self.mCacheAppUpdateData = nil

	self.mDownloadHandler = nil
	self.mDownloadProgressHandler = nil

	self.mAssetsManagerExCacheTable = {}
	self.mAssetsManagerExCallbacks = {}
	for k, v in pairs(self.mCheckUpdateCaches) do
		if v.requestId then
			core.HttpService.CANCEL(v.requestId)
		end
	end
	self.mCheckUpdateCaches = {}

	for k, v in pairs(self.mCheckMultipleGamesUpdateCaches) do
		if v.requestId then
			core.HttpService.CANCEL(v.requestId)
		end
	end
	self.mCheckMultipleGamesUpdateCaches = {}

	self.mGameUpdatedRecords = {}
end

-- -- AssetsManagerEx下载资源文件成功后的验证回调
-- -- 计算并验证md5，写死在C++中
-- local function onVerifyFunction(absolutePath, size, md5, relativePath)
-- 	-- print("NewUpdateMgr => onVerifyFunction(",absolutePath, size, md5, relativePath, ")")
-- 	local md5hash = cc.utils_.md5file(absolutePath)
-- 	-- print("calc md5hash == ", md5hash)
-- 	if string.upper(md5) == string.upper(md5hash) then
-- 		return true
-- 	end
-- 	return false
-- end

-- 比较两个版本号，返回int
-- A > B = 1
-- A < B = -1
-- A == B = 0
local function onVersionCompareFunction(versionA, versionB)
	-- print("NewUpdateMgr => onVersionCompareFunction(", versionA, versionB, ")")

    local tab1 = string.split(versionA, ".")
    local tab2 = string.split(versionB, ".")

    if #tab1 ~= 4 then
    	return -1
    end

    if #tab2 ~= 4 then
    	return 1
    end

    for i = 1, #tab1 do
        v1 = tonumber(tab1[i]) or 0
        v2 = tonumber(tab2[i]) or 0
        -- print(v1, v2)
    	if v1 > v2 then
            return 1
        elseif v1 == v2 then
        elseif v1 < v2 then
        	return -1
        end
    end
    return 0
end

-- 判断version1的Lua版本号是否大于version2的Lua版本号
-- 没有version1，返回false
-- 没有version2，返回true
-- 位数不同，返回false
-- 前三位不等返回false
-- 最后只比较最后一位,如果version1的大于version2的，则返回true，否则返回false（只判断可以用于Lua更新的情况）
-- orEqual 为true时判断大于等于，为false时判断大于
-- !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!此接口已过时，更新只判断isFullVersionNewer!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
function NewUpdateMgr:isLuaVersionNewer(version1, version2, orEqual)
	if not version1 then
		return false
	end
	if not version2 then
		return true
	end

	orEqual = orEqual == true

	local tab1 = string.split(version1, ".")
	local tab2 = string.split(version2, ".")

	if #tab1 ~= #tab2 then
		return false
	end

	for i = 1, #tab1-1 do
		if tab1[i] and tab2[i] and tab1[i] == tab2[i] then
		else
			return false
		end
	end
	local result = false
	if orEqual then
		result = tonumber(tab1[#tab1]) >= tonumber(tab2[#tab2])
	else 
		result = tonumber(tab1[#tab1]) > tonumber(tab2[#tab2])
	end
	return result
end

-- 判断version1的完整版本号是否大于version2的完整版本号
-- 没有version1，返回false
-- 没有version2，返回true
-- 位数不同，返回false
-- orEqual 为true时判断大于等于，为false时判断大于
function NewUpdateMgr:isFullVersionNewer(version1, version2, orEqual)
	print(string.format("NewUpdateMgr:isFullVersionNewer (%s,%s,%s)", 
		tostring(version1), tostring(version2), tostring(orEqual)))
	if not version1 then
        return false
    end
    if not version2 then
        return true
    end

    orEqual = orEqual == true

    local tab1 = string.split(version1, ".")
    local tab2 = string.split(version2, ".")

    if #tab1 ~= #tab2 then
    	return false
    end

    for i = 1, #tab1 do
        v1 = tonumber(tab1[i]) or 0
        v2 = tonumber(tab2[i]) or 0
        -- print(v1, v2)
        if orEqual then
	        if v1 > v2 then
	            return true
	        elseif v1 == v2 then
	        	if i == #tab1 then
	        		return true
	        	end
	        elseif v1 < v2 then
	        	return false
	        end
	    else
	    	if v1 > v2 then
	            return true
	        elseif v1 == v2 then
	        elseif v1 < v2 then
	        	return false
	        end
	    end
    end
    return false
end

-- 如果返回不为nil，则返回AssetsManagerEx对象以及设置监听的回调，则使用完需要调用release，并且调用removeEventListener
-- gameid 游戏id
-- localVersionPath 本地version.manifest的相对路径
-- localProjectPath 本地project.manifest的相对路径
-- storagePath 下载保存的外存路径，一般为device.writablePath + "updates/" + 游戏包名，大厅为gamehall
-- callback lua端的监听回调，一个eventListener对应多个callback
-- urlPrefix 更新地址前缀，拼接manifest文件中的后半截路径即完整下载路径，通过请求php获得
-- 注意调用更新的时候不要调用AssetsManagerEx的update函数，要调用luaUpdate
function NewUpdateMgr:createAssetsManagerEx(gameid, localVersionPath, localProjectPath, storagePath, callback, urlPrefix)
	gameid = tonumber(gameid)
	urlPrefix = urlPrefix or ""
	print("NewUpdateMgr:createAssetsManagerEx (", gameid, localVersionPath, localProjectPath, storagePath, callback, urlPrefix, ")")
	if type(localVersionPath) == "string" and type(storagePath) == "string" and type(callback) == "function" then
		-- Donwloader最大并行任务数
		local maxConcurrentTask = 4
		local amEx = cc.AssetsManagerEx:create(localVersionPath, localProjectPath, storagePath, maxConcurrentTask, urlPrefix)
		amEx:retain()
		if not amEx:getLocalManifest():isLoaded() then
			print(string.format("AssetsManagerEx load manifest[%s] failed", localVersionPath))
			amEx:release()
			return nil
		end
		-- 包装一层默认的
		local onAssetsManagerExEvent = function(event)
			local assetsManagerEx = event:getAssetsManagerEx()
			-- 看C++的逻辑是所有EventListenerAssetsManagerEx都会收到广播，所以这里做一个隔离
			if assetsManagerEx ~= amEx then
				print("Not the same AssetsManagerEx: ", assetsManagerEx, amEx, "ignore the event")
				return
			end

			-- print("localVersionPath => ", localVersionPath)
			-- print("localProjectPath => ", localProjectPath)
			-- print("storagePath => ", storagePath)

			local eventCode = event:getEventCode()
			if eventCode == cc.EventAssetsManagerEx.EventCode.ERROR_NO_LOCAL_MANIFEST then
				-- 没有localManifest文件，或者本地描述文件加载失败
				print("NewUpdateMgr => onUpdateEvent: ERROR_NO_LOCAL_MANIFEST")
				amEx.__isLuaUpdating = false
			elseif eventCode == cc.EventAssetsManagerEx.EventCode.ERROR_DOWNLOAD_MANIFEST then
				-- 下载描述文件失败或者描述文件下载参数不合法
				print("NewUpdateMgr => onUpdateEvent: ERROR_DOWNLOAD_MANIFEST")
				amEx.__isLuaUpdating = false
			elseif eventCode == cc.EventAssetsManagerEx.EventCode.ERROR_PARSE_MANIFEST then
				-- 加载tempManifest失败
				print("NewUpdateMgr => onUpdateEvent: ERROR_PARSE_MANIFEST")
				amEx.__isLuaUpdating = false
			elseif eventCode == cc.EventAssetsManagerEx.EventCode.UPDATE_FAILED then
				-- 如果存在失败任务，则将tempManifest保存为文件，并通知更新失败
				print("NewUpdateMgr => onUpdateEvent: UPDATE_FAILED")
				amEx.__isLuaUpdating = false
			elseif eventCode == cc.EventAssetsManagerEx.EventCode.NEW_VERSION_FOUND then
				-- 加载remoteManifest后，发现有新版本
				print("NewUpdateMgr => onUpdateEvent: NEW_VERSION_FOUND")
			elseif eventCode == cc.EventAssetsManagerEx.EventCode.UPDATE_FINISHED then
				-- 解压成功，更新成功
				print("NewUpdateMgr => onUpdateEvent: UPDATE_FINISHED")
				-- 设置已更新记录
				self:setGameUpdatedRecord(gameid)
				amEx.__isLuaUpdating = false
			elseif eventCode == cc.EventAssetsManagerEx.EventCode.ASSET_UPDATED then
				-- 通知资源已更新，但并不代表成功
				-- print("NewUpdateMgr => onUpdateEvent: ASSET_UPDATED")
			elseif eventCode == cc.EventAssetsManagerEx.EventCode.UPDATE_PROGRESSION then
				-- 下载进度
				-- print("NewUpdateMgr => onUpdateEvent: UPDATE_PROGRESSION")
			elseif eventCode == cc.EventAssetsManagerEx.EventCode.ALREADY_UP_TO_DATE then
				-- 检查更新时，比对localManifest和remoteManifest版本信息时，如果版本号相同，则判断为已经更新到最新版本
				print("NewUpdateMgr => onUpdateEvent: ALREADY_UP_TO_DATE")
				-- 设置已更新记录
				self:setGameUpdatedRecord(gameid)
				amEx.__isLuaUpdating = false
			elseif eventCode == cc.EventAssetsManagerEx.EventCode.ERROR_DECOMPRESS then
				-- 解压文件失败，不会中断逻辑
				print("NewUpdateMgr => onUpdateEvent: ERROR_DECOMPRESS")
			elseif eventCode == cc.EventAssetsManagerEx.EventCode.ERROR_UPDATING then
				-- 更新出错/失败（downloader出错/失败）
				print("NewUpdateMgr => onUpdateEvent: ERROR_UPDATING")
			end
			
			local callbackCounts = 0
			if type(self.mAssetsManagerExCallbacks[gameid]) == "table" then
				local callbacks = self.mAssetsManagerExCallbacks[gameid]
				callbackCounts = #callbacks
			end
			if callbackCounts == 0 then
				-- 如果没有Lua监听器，则自行处理结果
				local eventCode = event:getEventCode()
				if eventCode == cc.EventAssetsManagerEx.EventCode.ERROR_NO_LOCAL_MANIFEST
					or eventCode == cc.EventAssetsManagerEx.EventCode.ERROR_DOWNLOAD_MANIFEST
					or eventCode == cc.EventAssetsManagerEx.EventCode.ERROR_PARSE_MANIFEST
					or eventCode == cc.EventAssetsManagerEx.EventCode.UPDATE_FAILED then
					-- 当作更新失败结果
					self:releaseAssetsManagerEx(assetsManagerEx)

				elseif eventCode == cc.EventAssetsManagerEx.EventCode.UPDATE_FINISHED then
					-- 当作更新成功结果
					local gameMgr = require("app.manager.GameManager").getInstance()
					gameMgr:reInitGame(gameid)
					self:releaseAssetsManagerEx(assetsManagerEx)
				elseif eventCode == cc.EventAssetsManagerEx.EventCode.ALREADY_UP_TO_DATE then
					-- 已经最新
					self:releaseAssetsManagerEx(assetsManagerEx)
				end

			else
				-- 如果有回调，则交给外部处理
				for k,v in ipairs(self.mAssetsManagerExCallbacks[gameid]) do
					v(event)
				end
			end
				
		end

		-- 以闭包方式添加两个函数
		amEx.luaUpdate = function()
			print("amEx.luaUpdate() gameid = ", gameid)
			amEx.__isLuaUpdating = true
			amEx:update()
		end

		-- 以闭包方式添加两个函数
		amEx.isLuaUpdating = function()
			local result = amEx.__isLuaUpdating
			print("amEx.isLuaUpdating() result => ", result, "gameid = ", gameid)
			return result
		end

		self:addAssetsManagerExCallback(gameid, callback)
		-- 写死于C++
		-- amEx:setVerifyCallback(onVerifyFunction)
		amEx:setVersionCompareHandle(onVersionCompareFunction)
		local listener = cc.EventListenerAssetsManagerEx:create(amEx,onAssetsManagerExEvent)
		-- 设置回调事件监听
		cc.Director:getInstance():getEventDispatcher():addEventListenerWithFixedPriority(listener, 1)

		self:cacheAssetsManagerEx(gameid, amEx, listener)
		return amEx, listener
	end
	return nil
end

-- 设置游戏/大厅已经更新过
function NewUpdateMgr:setGameUpdatedRecord(gameid)
	gameid = tonumber(gameid)
	if gameid then
		self.mGameUpdatedRecords[gameid] = true
	end
end

-- 这次游戏启动大厅是否已经更新过
function NewUpdateMgr:isGameUpdated(gameid)
	gameid = tonumber(gameid)
	if gameid then
		return self.mGameUpdatedRecords[gameid]
	end
end

-- 清除更新记录
function NewUpdateMgr:clearGameUpdatedRecord(gameid)
	gameid = tonumber(gameid)
	if gameid then
		self.mGameUpdatedRecords[gameid] = nil
	end
end

-- 释放
-- 先释放assetsManagerEx在lua端的缓存和Lua监听器
-- 再释放assetsManagerEx注册的对应C++EventListener
-- 最后释放assetsManagerEx
function NewUpdateMgr:releaseAssetsManagerEx(assetsManagerEx)
	local eventListenerAssetsManagerEx = nil 
	if type(assetsManagerEx) == "userdata" then
		eventListenerAssetsManagerEx = self:removeAllAssetsManagerExCacheAndCallbacks(assetsManagerEx)
	end
	if type(eventListenerAssetsManagerEx) == "userdata" then
		print("removeEventListener: ", eventListenerAssetsManagerEx)
		cc.Director:getInstance():getEventDispatcher():removeEventListener(eventListenerAssetsManagerEx)
	end
	if type(assetsManagerEx) == "userdata" and type(eventListenerAssetsManagerEx) == "userdata" then
		-- 要找到记录才清除
		print("release AssetsManagerEx: ", assetsManagerEx)
		assetsManagerEx:release()
	end
end

-- 缓存AssetsManagerEx及相关，用于继续显示下载记录/进度
function NewUpdateMgr:cacheAssetsManagerEx(gameid, assetsManagerEx, eventListenerAssetsManagerEx)
	if gameid and assetsManagerEx and eventListenerAssetsManagerEx then
		self.mAssetsManagerExCacheTable[gameid] = {am = assetsManagerEx, listener = eventListenerAssetsManagerEx}
	end
end

function NewUpdateMgr:addAssetsManagerExCallback(gameid, callback)
	local callbacks = self.mAssetsManagerExCallbacks[gameid]
	if type(callbacks) ~= "table" then
		callbacks = {}
		self.mAssetsManagerExCallbacks[gameid] = callbacks
		table.insert(callbacks, callback)
		return
	end
	for k, v in ipairs(callbacks) do
		if v == callback then
			return
		end
	end
	table.insert(callbacks, callback)
	return
end

-- 注销Lua端的监听
function NewUpdateMgr:removeAssetsManagerExCallback(gameid, callback)
	local callbacks = self.mAssetsManagerExCallbacks[gameid]
	if type(callbacks) ~= "table" then
		return
	end
	for k, v in ipairs(callbacks) do
		if v == callback then
			table.remove(callbacks, k)
			return
		end
	end
end

-- 清除lua中assetsManagerEx的记录，清除Lua中与assetsManagerEx绑定的EventListener记录，清除监听该assetsManagerEx的Lua回调
-- 值清除Lua表，不调用C++release，完整释放需要调用releaseAssetsManagerEx
function NewUpdateMgr:removeAllAssetsManagerExCacheAndCallbacks(assetsManagerEx)
	print("NewUpdateMgr:removeAssetsManagerExCallbacks(", assetsManagerEx, ")")
	if type(assetsManagerEx) == "userdata" then
		local gameid = nil
		local listener = nil
		for k,v in pairs(self.mAssetsManagerExCacheTable) do
			if type(v) == "table" then
				if v.am == assetsManagerEx then
					gameid = k
					listener = v.listener
					self.mAssetsManagerExCacheTable[gameid] = nil
					print("remove AssetsManagerEx cache gameid = ", gameid)
					break
				end
			end
		end
		if gameid then
			print("removeAllAssetsManagerExCallbacks gameid = ", gameid)
			self.mAssetsManagerExCallbacks[gameid] = nil
		end
		return listener
	end
end

-- 获取缓存的AssetsManagerEx及相关
-- 取出AssetsManager后根据getState获取当前状态，然后进行后续逻辑
function NewUpdateMgr:getAssetsManagerExCache(gameid)
	local tmp = self.mAssetsManagerExCacheTable[gameid]
	if tmp then
		-- assetsManagerEx, eventListenerAssetsManagerEx
		return tmp.am, tmp.listener
	end
	return nil
end

-- 判断游戏是不是正在下载/更新
function NewUpdateMgr:isAssetsManagerExDownloading(gameid)
	local amEx = self:getAssetsManagerExCache(gameid)
	if amEx then
		return amEx:isLuaUpdating()
	end
	return false
end

-- 下载新游戏之前创建version.manifest，project.manifest
-- storagePath为完整目录路径
function NewUpdateMgr:__createEmptyManifestFiles(packagePath, storagePath, remoteManifestUrl, remoteVersionUrl)
	print("NewUpdateMgr:__createEmptyManifestFiles(", packagePath, storagePath, remoteManifestUrl, remoteVersionUrl, ")")
	local fileUtils = cc.FileUtils:getInstance()

	fileUtils:createDirectory(storagePath)

	local versionManifest = self:joinDirectorySeparator(packagePath) .. "version.manifest"
	if fileUtils:isFileExist(versionManifest) then
		print(string.format("versionManifest[%s] exists", versionManifest))
	else
		local writeVersion = self:joinDirectorySeparator(storagePath) .. "version.manifest"
		local versionContent = {
			packageUrl = "",
			remoteManifestUrl = remoteManifestUrl or "",
			remoteVersionUrl = remoteVersionUrl or "",
			version = "0.0.0.0", -- 没安装就当是0.0.0.0版本
			assets = {},
			-- searchPaths = {}, -- 因为空表会默认编成JSONObject，此处是空数组
		}
		local jsonStr = json.encode(versionContent)
		io.writefile(writeVersion, jsonStr, "w+b")
	end

	local projectManifest = self:joinDirectorySeparator(packagePath) .. "project.manifest"
	if fileUtils:isFileExist(projectManifest) then
		print(string.format("projectManifest[%s] exists", projectManifest))
	else
		local writeProject = self:joinDirectorySeparator(storagePath) .. "project.manifest"

		local projectContent = {
			packageUrl = "",
			remoteManifestUrl = remoteManifestUrl or "",
			remoteVersionUrl = remoteVersionUrl or "",
			version = "0.0.0.0", -- 没安装就当是0.0.0.0版本
			assets = {},
			-- searchPaths = {}, -- 因为空表会默认编成JSONObject，此处是空数组
		}
		local jsonStr = json.encode(projectContent)
		io.writefile(writeProject, jsonStr, "w+b")
	end
end

-- 通过包路径拼接,为下载新游戏前确保本地有两个manifest
function NewUpdateMgr:createEmptyManifestFilesByPackagePath(packagePath, remoteManifestUrl, remoteVersionUrl)
	local storagePath = NewConstantConfig.LOCALPATH.UPDATES_PATH .. packagePath
	self:__createEmptyManifestFiles(packagePath, storagePath, remoteManifestUrl, remoteVersionUrl)
end

-- 确认路径结尾是"/"
function NewUpdateMgr:joinDirectorySeparator(str)
	local endchar = string.sub(str, -1)
	if endchar == "/" or endchar == "\\" then
		return str
	else 
		return str .. "/"
	end
end

-- 检查已有更新缓存或者弹窗请求更新检查
function NewUpdateMgr:checkGameVersionCacheOrShowCheckGameUpdateDialog(gameid, shouldUpdateCallback, noUpdateCallback)
	print("NewUpdateMgr:checkGameVersionCacheOrShowCheckGameUpdateDialog(", gameid, shouldUpdateCallback, noUpdateCallback, ")")
	gameid = tonumber(gameid)
	local urlPrefix, version = NewUpdateMgr.getInstance():getCheckedGameUpdateResult(gameid)
    if urlPrefix then
    	-- 已有检查更新的cache
    	local gameMgr = require("app.manager.GameManager").getInstance()
        local nowGameVersion = gameMgr:getGameVersion(gameid)
        local isNewer = self:isFullVersionNewer(version, nowGameVersion)
        if isNewer then
        	if type(shouldUpdateCallback) == "function" then
	            pcall(shouldUpdateCallback)
	        end
        else
        	if type(noUpdateCallback) == "function" then
	            pcall(noUpdateCallback)
	        end
        end
    else
		local CheckUpdateProgressDialog = require(gamehallshell_src_path.."update.CheckUpdateProgressDialog")
	    CheckUpdateProgressDialog.new(gameid, shouldUpdateCallback, noUpdateCallback):show()
	end
end

-- 尝试获取已检查到的更新记录，返回urlPrefix 或 nil
function NewUpdateMgr:getCheckedGameUpdateResult(gameid)
	gameid = tonumber(gameid) or 0
	local cache = self.mCheckedUpdateResults[gameid]
	if cache then
		local urlPrefix = cache.urlPrefix
		local version = cache.version
		local alert = cache.alert
		print("NewUpdateMgr:getCheckedGameUpdateResult(", gameid, ") => ", urlPrefix, version, alert)
		return urlPrefix, version, alert
	end
	return nil
end

--[[
请求检查多个游戏的更新
只会请求没有请求过的游戏
如果所有游戏都请求过，则回调的data为nil
]]
function NewUpdateMgr:checkMultipleGamesUpdate(gameids, obj, callback, trytimes)
	print("NewUpdateMgr:checkMultipleGamesUpdate(", gameids, obj, callback, trytimes, ")")
	if type(gameids) == "table" and obj and callback then
		trytimes = tonumber(trytimes) or 1
		if trytimes < 1 then
			trytimes = 1
		end

		local gameMgr = require("app.manager.GameManager").getInstance()
		local appconfig = require("appconfig")
		local url = appconfig.hotUpdateUrl
		local params = {}
		params.method = "DayDayUp.getDayDayUpUrl"
		params.demo = appconfig.phpdemo
		params.appid = appconfig.appid
		local games = {}
		for _, gameid in ipairs(gameids) do
			local urlPrefix, version = self:getCheckedGameUpdateResult(tonumber(gameid) or 0)
			if not urlPrefix then
				-- 挑出沒有記錄的
				local gameVersion = gameMgr:getGameVersion(tonumber(gameid) or 0) or "0.0.0.0"
				games[tostring(gameid)] = gameVersion
			end
		end
		-- 沒有需要檢查更新的
		if not next(games) then
			if callback then
				-- 直接回调
				callback(obj, true, url, params, nil)
				return
			end
		end
		params.games = json.encode(games)
		params.hallVersion = gameMgr:getGameVersion(100) or "0.0.0.0"
		params.appVersion = self:getAppVersion() or "1.0.0"
		params.lastLoginMid = cc.UserDefault:getInstance():getIntegerForKey("LAST_LOGIN_MID", 0)
	    params.time=os.time()

	    local onCheckGamesUpdateResult = function(data)
			dump(data, "NewUpdateMgr:checkMultipleGamesUpdate => onCheckGamesUpdateResult")
	    	local returnData = data and json.decode(data) or {}
	    	local code = returnData.code
	    	if checkint(code) == 1 then

	    		if type(returnData.data) == "table" then
	    			for gameid, updateData in pairs(returnData.data) do
	    				gameid = tonumber(gameid)
						if gameid then
							local version = updateData.version -- 版本号
							local urlPrefix = updateData.url -- urlPrefix
							local alert = updateData.alert -- 是否提示
							print(string.format("NewUpdateMgr record mCheckedUpdateResults[%d] => '%s', version[%s]", gameid, tostring(urlPrefix), tostring(version)))

							self.mCheckedUpdateResults[gameid] = {urlPrefix = urlPrefix, version = version, alert=alert}
							local currentVersion = require("app.manager.GameManager").getInstance():getGameVersion(gameid)

							if not self:isFullVersionNewer(version, currentVersion) then
								-- 如果新版本号并不大于当前版本号，则当作已经更新过了
								self:setGameUpdatedRecord(gameid)
							end
						else
							print(string.format("error gameid[%s] is not a number", tostring(gameid)))
						end
	    			end
	    		end

				if callback then
					-- 回调出去
			    	callback(obj, true, url, params, returnData)
			    end
		    	self.mCheckMultipleGamesUpdateCaches[obj] = nil
		    else
		    	print("NewUpdateMgr:checkMultipleGamesUpdate => onCheckGamesUpdateResult php returns error", data)
		    	if callback then
					-- 回调出去
			    	callback(obj, false, url, params, returnData)
			    end
		    	self.mCheckMultipleGamesUpdateCaches[obj] = nil
		    end
		end
		local onCheckGamesUpdateFailed = nil
		onCheckGamesUpdateFailed = function(data)
			dump(data, "NewUpdateMgr:checkMultipleGamesUpdate => onCheckGamesUpdateFailed")
			-- 此处增加一个容错，但是感觉并不对
			if self and self.mCheckMultipleGamesUpdateCaches and obj and self.mCheckMultipleGamesUpdateCaches[obj] then
				-- 闭包obj
				self.mCheckMultipleGamesUpdateCaches[obj]["retryTimes"] = self.mCheckMultipleGamesUpdateCaches[obj]["retryTimes"] - 1
				if self.mCheckMultipleGamesUpdateCaches[obj]["retryTimes"] >= 0 then
					-- 重试
					local requestId = core.HttpService.POST_URL(url, params, onCheckGamesUpdateResult, onCheckGamesUpdateFailed)
					self.mCheckMultipleGamesUpdateCaches[obj]["requestId"] = requestId
				else
					if callback then
						-- 回调出去
						callback(obj, false, url, params, data)
					end
					self.mCheckMultipleGamesUpdateCaches[obj] = nil
				end
			end
		end

		local requestId = core.HttpService.POST_URL(url, params, onCheckGamesUpdateResult, onCheckGamesUpdateFailed)
		self.mCheckMultipleGamesUpdateCaches[obj] = {callback = callback, retryTimes = trytimes, requestId = requestId,}
	end
end

-- 取消检查更新
function NewUpdateMgr:cancelCheckMultipleGamesUpdate(obj)
	if obj and self.mCheckMultipleGamesUpdateCaches and self.mCheckMultipleGamesUpdateCaches[obj] then
		local requestId = self.mCheckMultipleGamesUpdateCaches[obj]["requestId"]
		core.HttpService.CANCEL(requestId)
		self.mCheckMultipleGamesUpdateCaches[obj] = nil
	end
end

--[[
请求检查单个游戏更新
callback = function(self, result, url, params, data)
]]
function NewUpdateMgr:checkSingleGameUpdate(gameid, obj, callback, trytimes)
	gameid = tonumber(gameid)
	trytimes = tonumber(trytimes) or 1
	if trytimes < 1 then
		trytimes = 1
	end
	print(debug.traceback())
	print("NewUpdateMgr:checkSingleGameUpdate(", gameid, callback, trytimes,")")
	-- self.mCheckUpdateCaches = {gameid:{callbacks:{obj1:xxx,obj2:xxx,obj3:xxx},requestId:xxx,retryTimes:xxx,}}
	if gameid and obj and callback then
		if self.mCheckUpdateCaches[gameid] then
			-- 已有
			local callbacks = self.mCheckUpdateCaches[gameid]["callbacks"]
			callbacks[obj] = callback
			local retryTimes = self.mCheckUpdateCaches[gameid]["retryTimes"]
			if trytimes > retryTimes then
				self.mCheckUpdateCaches[gameid]["retryTimes"] = trytimes
			end
		else
			-- 没有
			self.mCheckUpdateCaches[gameid] = {callbacks={},retryTimes=trytimes,requestId=nil}
			local callbacks = self.mCheckUpdateCaches[gameid]["callbacks"]
			callbacks[obj] = callback

			-- 请求
			local requestId = self:__requestCheckSingleGameUpdate(gameid)
			self.mCheckUpdateCaches[gameid]["requestId"] = requestId
		end
	end
end

-- 清空检查更新请求缓存
function NewUpdateMgr:clearCheckGameUpdateCallback(obj)
	for gameid,v in pairs(self.mCheckUpdateCaches) do
		if type(v.callbacks) == "table" then
			v.callbacks[obj] = nil
			if not next(v.callbacks) and v.requestId then
				-- 如果一个回调都没有，则清空
				core.HttpService.CANCEL(v.requestId)
				self.mCheckUpdateCaches[gameid] = nil
			end
		end
	end
end

--[[
请求检查单个游戏更新
获取给AssetsManagerEx用的urlPrefix
]]
function NewUpdateMgr:__requestCheckSingleGameUpdate(gameid)
	local gameMgr = require("app.manager.GameManager").getInstance()
	local appconfig = require("appconfig")
	local url = appconfig.hotUpdateUrl
	local params = {}
	params.method = "DayDayUp.getDayDayUpUrl"
	params.demo = appconfig.phpdemo
	params.appid = appconfig.appid
	local games = {}
	-- for k,gameid in ipairs(gameids) do
	-- 	local gameVersion = gameMgr:getGameVersion(tonumber(gameid) or 0) or "0.0.0.0"
	-- 	games[tostring(gameid)] = gameVersion
	-- end
	games[tostring(gameid)] = gameMgr:getGameVersion(tonumber(gameid) or 0) or "0.0.0.0"
	params.games = json.encode(games)
	params.hallVersion = gameMgr:getGameVersion(100) or "0.0.0.0"
	params.appVersion = self:getAppVersion() or "1.0.0"
	params.lastLoginMid = cc.UserDefault:getInstance():getIntegerForKey("LAST_LOGIN_MID", 0)
    params.time=os.time()

	local function innerHandler(obj, method)
		return function(...)
			print("innerHandler", obj, method)
			return method(obj, url, params, ...)
		end
	end

	local requestId = core.HttpService.POST_URL(url, params, 
		innerHandler(self,self.onResponseHotUpdateResult), 
		innerHandler(self,self.onResponseHotUpdateFailed))
	return requestId
end

function NewUpdateMgr:onResponseHotUpdateFailed(url, params, data)
	dump(data, "NewUpdateMgr:onResponseHotUpdateFailed")
	for gameid, version in pairs(json.decode(params.games)) do
		gameid = tonumber(gameid)
		if gameid and self.mCheckUpdateCaches[gameid] then
			local retryTimes = self.mCheckUpdateCaches[gameid]["retryTimes"]
			retryTimes = retryTimes - 1
			if retryTimes >= 0 then
				-- 重试次数够，重试
				local requestId = self:retryCheckGameUpdate(url, params)
				self.mCheckUpdateCaches[gameid]["requestId"] = requestId
				self.mCheckUpdateCaches[gameid]["retryTimes"] = retryTimes
			else
				-- 重试次数不够，回调请求失败
				local callbacks = self.mCheckUpdateCaches[gameid]["callbacks"]
				for obj,func in pairs(callbacks) do
					func(obj, false, url, params, data)
				end
				-- 清空cache
				self.mCheckUpdateCaches[gameid] = nil
			end
		end
	end
end

-- 这里只代表请求成功返回状态码200，并不代表逻辑上的成功
function NewUpdateMgr:onResponseHotUpdateResult(url, params, data)
	dump(data, "NewUpdateMgr:onResponseHotUpdateResult")
	local returnData = data and json.decode(data) or {}
	local code = returnData.code

	if checkint(code) == 1 then
		-- 缓存请求更新结果

		-- "{"code":1,"codemsg":"","data":{"100":{"version":"1.0.0.0","url":"http:\/\/192.168.1.158\/game\/staticres\/hotupdate\/files\/10\/","alert":1}},"time":1515752317,"exetime":0.0020060539245605}"
		if type(returnData.data) == "table" then
			for gameid, updateData in pairs(returnData.data) do
				gameid = tonumber(gameid)
				if gameid then
					local version = updateData.version -- 版本号
					local urlPrefix = updateData.url -- urlPrefix
					local alert = updateData.alert -- 是否提示
					print(string.format("NewUpdateMgr record mCheckedUpdateResults[%d] => '%s', version[%s]", gameid, tostring(urlPrefix), tostring(version)))

					self.mCheckedUpdateResults[gameid] = {urlPrefix = urlPrefix, version = version, alert=alert}
					local currentVersion = require("app.manager.GameManager").getInstance():getGameVersion(gameid)

					if not self:isFullVersionNewer(version, currentVersion) then
						-- 如果新版本号并不大于当前版本号，则当作已经更新过了
						self:setGameUpdatedRecord(gameid)
					end
					if self.mCheckUpdateCaches[gameid] then
						local callbacks = self.mCheckUpdateCaches[gameid]["callbacks"]
						for obj, func in pairs(callbacks) do
							pcall(func, obj, true, url, params, returnData)
						end
						-- 清空cache
						self.mCheckUpdateCaches[gameid] = nil
					end
				else
					print(string.format("error gameid[%s] is not a number", tostring(gameid)))
				end
			end
		end
	else
		print("NewUpdateMgr:onResponseHotUpdateResult php returns error", data)
		for gameid, version in pairs(json.decode(params.games)) do
			gameid = tonumber(gameid)
			if gameid and self.mCheckUpdateCaches[gameid] then
				local callbacks = self.mCheckUpdateCaches[gameid]["callbacks"]
				for obj, func in pairs(callbacks) do
					pcall(func, obj, false, url, params, returnData)
				end
				-- 清空cache
				self.mCheckUpdateCaches[gameid] = nil
			end
		end
	end
end

-- 重试
function NewUpdateMgr:retryCheckGameUpdate(url, params)
	-- 更新请求时间
	params.time=os.time()
	local function innerHandler(obj, method)
		return function(...)
			print("innerHandler", obj, method)
			return method(obj, url, params, ...)
		end
	end

	local requestId = core.HttpService.POST_URL(url, params, 
		innerHandler(self,self.onResponseHotUpdateResult), 
		innerHandler(self,self.onResponseHotUpdateFailed))
	return requestId
end

---------------------------------------------------- App相关 开始----------------------------------------------------
-- 获取持久化数据访问对象
function NewUpdateMgr:getUpdateDAO()
	if not self.mUpdateDAO then
		self.mUpdateDAO = UpdateDAO.new()
	end
	return self.mUpdateDAO
end

-- 获取App的相关信息
function NewUpdateMgr:__loadAppInfos()
	local infos = nil
	self.mBundleIdOrPackageName = self.mBundleIdOrPackageName or "unknown"
	self.mAppVersion = self.mAppVersion or "1.0.0"
	self.mAppBuildVersion = self.mAppBuildVersion or "unknown"
	if self.mPlatform == "android" then
		infos = self:__readAndroidAppInfos()
		self.mBundleIdOrPackageName = infos.packageName or "unknown"
		self.mAppVersion = infos.versionName or "1.0.0"
		self.mAppBuildVersion = tostring(infos.versionCode) or "unknown"
	elseif self.mPlatform == "ios" then
		infos = self:__readIOSAppInfos()
		self.mBundleIdOrPackageName = infos.bundleId or "unknown"
		self.mAppVersion = infos.shortVersion or "1.0.0"
		self.mAppBuildVersion = tostring(infos.buildVersion) or "unknown"
	elseif self.mPlatform == "windows" then
		infos = self:__readWin32AppInfos()
	end
end

-- 读iOS
function NewUpdateMgr:__readIOSAppInfos()
	local infos = {}
	if self.mPlatform == "ios" then
		local ok, ret = luaoc.callStaticMethod(
	        "LuaOCBridge",
	        "getManifestInformations", nil)
		if ok then
			local tmp = json.decode(ret)
			if tmp and type(tmp) == "table" then
				-- bundleId
				-- shortVersion   --1.0.0
				-- appName
				-- buildVersion   --1.0.0.xxxx
				infos = tmp
			end
		end
	end
	return infos
end

-- 读安卓
function NewUpdateMgr:__readAndroidAppInfos()
	local infos = {}
	if self.mPlatform == "android" then
		local ok, ret = luaj.callStaticMethod("org/ode/cocoslib/core/functions/ManifestFunction", 
	        "getManifestInformations", {}, "()Ljava/lang/String;")
		if ok then
			local tmp = json.decode(ret)
	        if tmp and type(tmp) == "table" then
	        	-- String packageName
			    -- int versionCode
			    -- String versionName
			    -- long lastUpdateTime
			    -- String appName
	            infos = tmp
	        end
		end
	end
	return infos
end

-- 一无所有的Win32
function NewUpdateMgr:__readWin32AppInfos()
	local infos = {}
	return infos
end


-- iOS端返回bundleId
-- Android端返回packageName
function NewUpdateMgr:getBundleIdOrPackageName()
	self.mBundleIdOrPackageName = self.mBundleIdOrPackageName or "unknown"
	return self.mBundleIdOrPackageName
end

-- 获取应用版本号
-- 改为三位
function NewUpdateMgr:getAppVersion()
	self.mAppVersion = self.mAppVersion or "1.0.0"
	return self.mAppVersion
end

-- 获取应用的构建版本，恒为字符串，android为versionCode，iOS为buildVersion
function NewUpdateMgr:getAppBuildVersion()
	return self.mAppBuildVersion or "unknown"
end

-- 验证apk的MD5
function NewUpdateMgr:verifyApkMD5(apkPath, md5)
	return Utils.verifyFile(apkPath, md5)
end

-- 删除文件
function NewUpdateMgr:removeFile(filePath)
	return Utils.rmfile(filePath)
end

function NewUpdateMgr:installApk(apkPath)
	print("NewUpdateMgr:installApk apkPath = ", apkPath)
	if self.mPlatform == "android" then
	    local ok, ret = luaj.callStaticMethod("org/ode/cocoslib/core/functions/APKFunction",
	        "installApk", {apkPath}, "(Ljava/lang/String;)V")
	    return true
	end
	return false
end


--[[/**
 * @param patchPath 差分包绝对路径
 * @param desApkPath 生成的apk的绝对路径
 * @return "1":仅仅调用API成功，具体以回调结果ret为准  ret: "1":成功 other:失败
 */]]
function NewUpdateMgr:genApk(patchPath,desApkPath,callback)
	print("NewUpdateMgr:genApk(", patchPath, desApkPath, callback, ")")
	if self.mPlatform == "android" and type(callback) == "function" then
	    local ok, ret = luaj.callStaticMethod("org/ode/cocoslib/patchupdate/PatchUpdateBridge", 
	    	"genApk", {patchPath,desApkPath,callback}, "(Ljava/lang/String;Ljava/lang/String;I)I")
	    return true
	end
	return false
end

function NewUpdateMgr:openURL(url)
	local ret = cc.Application:getInstance():openURL(url)
	if ret then
		print(string.format("NewUpdateMgr:openURL(%s) success", tostring(url)))
	else
		print(string.format("NewUpdateMgr:openURL(%s) failed", tostring(url)))
	end
end

--[[
判断是否有APP更新
appData的格式为
local app = {}
app.gameid = 0
app.md5 = "E0210936C458075F7BF81DB459DB99B1"
app.size = 38826392
app.version = "1.0.2.x"
app.updateType = ConstantConfig.UPDATETYPE.FORCE_FULL_APK
app.url = "http://192.168.1.158/game/staticres/android/hunan/test/test.apk"
app.clientpath = ""
app.desc = "xxxxxxxxxxxxxxxxxxx\nyyyyyyyyyyyyyyyyyyyyyy\nzzzzzzzzzzzzzzzz"

如果是bsdiff更新
代表补丁包的url
app.diffUrl = "http://192.168.1.158/game/staticres/android/hunan/test/test.patch"
代表合成后的apk的md5
app.apkmd5 = "E0210936C458075F7BF81DB459DB99B1"
app.md5代表补丁包的md5
app.url代表完整包的md5

20190108增加
app.tipInterval 弹窗提示间隔时间间隔（秒），只对非强制app更新有效
]]
function NewUpdateMgr:doesAppHaveUpdate(appData)
	if type(appData) ~= "table" then
		return false
	end

	if self.mPlatform == "windows" or self.mPlatform == "mac" then
		return false;
	end

	local updateType = tonumber(appData.updateType) or ConstantConfig.UPDATETYPE.NOUPDATE

	if updateType == ConstantConfig.UPDATETYPE.NOUPDATE then
		return false
	end
	for k, update_type in ipairs(ConstantConfig.APP_UPDATE_TYPES) do
		if update_type == updateType then
			if self:isFullVersionNewer(appData.version, self:getAppVersion()) then
				return true
			end
			break
		end
	end
	return false
end

-- 缓存APP更新数据（在用户取消可选APP更新的场景下）
function NewUpdateMgr:cacheAppUpdateData(appData)
	self.mCacheAppUpdateData = appData
end

function NewUpdateMgr:getCachedAppUpdateData()
	return self.mCacheAppUpdateData
end

-- 更新弹窗提示文本
function NewUpdateMgr:getUpdateDesc(updateData)
	local desc = nil
	local sizeMsg = nil
	if updateData and type(updateData) == "table" then
		if updateData.desc and type(updateData.desc) == "string" then
			desc = updateData.desc
		end
		if updateData.size and type(updateData.size) == "number" and updateData.size > 0 then
			sizeMsg = "更新包大小: " .. self:getShowSizeString(updateData.size)
		end
	end
	if not desc then
		desc = ""
	end
	if desc ~= "" then
		if sizeMsg then
			desc = desc .. "\n" .. sizeMsg
		end
	else
		if sizeMsg then
			desc = sizeMsg
		end
	end
	return desc
end

function NewUpdateMgr:getShowSizeString(size)
	if size < 1024 then
		return string.format("%dB", size)
	elseif size >= 1024 and size < 1048576 then
		return string.format("%0.2fKB", size/1024)
	elseif size >= 1048576 then
		return string.format("%0.2fMB", size/1048576)
	end
end

function NewUpdateMgr:isForceUpdate(updateType)
	for k,update_type in ipairs(ConstantConfig.FORCE_UPDATE_TYPES) do
		if update_type == updateType then
			return true
		end
	end
	return false
end

function NewUpdateMgr:downloadAppUpdate(appData)
	dump(appData, "NewUpdateMgr:downloadAppUpdate")
	if self.mPlatform == "ios" then
		local url = appData.url
		if url then
			self:openURL(url)
			return true
		end
	else
		self:__downloadUpdateApk(appData)
		return true
	end
	return false
end

function NewUpdateMgr:__downloadUpdateApk(appData)
	dump(appData, "NewUpdateMgr:__downloadUpdateApk")
	local updateType = appData.updateType
	if updateType == ConstantConfig.UPDATETYPE.OPTIONAL_FULL_APK or
		updateType == ConstantConfig.UPDATETYPE.FORCE_FULL_APK then
		-- 完整包
		local upType = tonumber(updateType)
		local gameid = 0
		local url = appData.url
		local name = self:__getUpdateApkName(appData.version)
		local md5 = appData.md5
		local size = appData.size
		local savepath = ConstantConfig.LOCALPATH.DOWNLOAD_PATH .. name
		local task = self.mTaskManager:createNewTask(upType, gameid, md5, size, name, url, savepath)
		self.mTaskManager:addNewTask(task)
		self.mTaskManager:start()

	elseif updateType == ConstantConfig.UPDATETYPE.OPTIONAL_BS_DIFF_APK or
		updateType == ConstantConfig.UPDATETYPE.FORCE_BS_DIFF_APK then
		-- 差量包
		local upType = tonumber(updateType)
		local gameid = 0
		local url = appData.diffUrl
		local name = self:__getUpdateBSDiffPatchName(self:getAppVersion(), appData.version)
		local md5 = appData.md5
		local size = appData.size
		local savepath = ConstantConfig.LOCALPATH.DOWNLOAD_PATH .. name
		local task = self.mTaskManager:createNewTask(upType, gameid, md5, size, name, url, savepath)
		self.mTaskManager:addNewTask(task)
		self.mTaskManager:start()
	end
end

function NewUpdateMgr:getUpdateApkName(newVersion)
	return self:__getUpdateApkName(newVersion)
end

function NewUpdateMgr:__getUpdateApkName(newVersion)
	if not newVersion then
		newVersion = "Unknown"
	end
	local newVersionStrInName = string.gsub(newVersion,"%.","_")
	local fileName = string.format("v%s.apk", newVersionStrInName)
	print("NewUpdateMgr:__getUpdateApkName => " .. fileName)
	return fileName
end

function NewUpdateMgr:__getUpdateBSDiffPatchName(oldVersion, newVersion)
	if not oldVersion then
		oldVersion = "None"
	end
	if not newVersion then
		newVersion = "Unknown"
	end
	local oldVersionStrInName = string.gsub(oldVersion,"%.","_")
	local newVersionStrInName = string.gsub(newVersion,"%.","_")
	local fileName = string.format("v%stov%s.patch", oldVersionStrInName, newVersionStrInName)
	print("NewUpdateMgr:__getUpdateBSDiffPatchName => " .. fileName)
	return fileName
end

function NewUpdateMgr:onFileDownloadProgress(event)
	print("---------------------NewUpdateMgr:onFileDownloadProgress---------------------")
	local data = event.data
	local downloadedSize = data.downloadedSize
    local totalSize = data.totalSize
	local downloadInfo = data.downloadInfo
	print("downloadedSize = ", downloadedSize, " totalSize = ", totalSize)

	self:__callGameDownloadProgressHandlerBack(downloadedSize, totalSize, downloadInfo)
end

-- Lua更新走AssetsManagerEx的逻辑，这里只处理源生App的更新下载
function NewUpdateMgr:onFileDownload(event)
	print("---------------------NewUpdateMgr:onFileDownload---------------------")
	local data = event.data
	local result = data.result
	local downloadInfo = data.downloadInfo

	if result then
		-- 下载成功
		local md5 = downloadInfo.md5
		local savepath = downloadInfo.savepath
		local upType = downloadInfo.type
		local name = downloadInfo.name
		local gameid = tonumber(downloadInfo.gameid)

		if Utils.verifyFile(savepath, md5) then
			-- md5验证成功
			print("md5验证成功")
			if upType == ConstantConfig.UPDATETYPE.OPTIONAL_BS_DIFF_APK or
				upType == ConstantConfig.UPDATETYPE.FORCE_BS_DIFF_APK then
				-- 差异apk更新

			elseif upType == ConstantConfig.UPDATETYPE.OPTIONAL_FULL_APK or
				upType == ConstantConfig.UPDATETYPE.FORCE_FULL_APK then
				-- 完整apk更新
				-- 移动到apkdownloads路径
				local dstpath = ConstantConfig.LOCALPATH.APK_DOWNLOADS_PATH .. name
				local result = Utils.renameFile(savepath,dstpath,true)
				if result then
					print("移动到路径",savepath, dstpath)
				else
					print("移动失败", savepath, dstpath)
					Utils.rmfile(savepath)
					self:__callGameDownloadHandlerBack(false, downloadInfo)
					return
				end
			end
			self:__callGameDownloadHandlerBack(true, downloadInfo)
		else
			-- md5验证失败
			print("md5验证失败")
			Utils.rmfile(savepath)
			self:__callGameDownloadHandlerBack(false, downloadInfo)
		end
	else
		-- 下载失败
		self:__callGameDownloadHandlerBack(false, downloadInfo)
	end
end

-- 设置结果回调和进度回调
function NewUpdateMgr:setOnGameDownloadHandlers(obj, resultHandler, progressHandler)
	self.mDownloadHandler[obj] = resultHandler
	self.mDownloadProgressHandler[obj] = progressHandler
end

-- 移除结果回调和进度回调
function NewUpdateMgr:removeOnGameDownloadHandlers(obj)
	self.mDownloadHandler[obj] = nil
	self.mDownloadProgressHandler[obj] = nil
end

function NewUpdateMgr:__callGameDownloadHandlerBack(result, downloadInfo)
	if self.mDownloadHandler then
		for k,v in pairs(self.mDownloadHandler) do
			v(result, downloadInfo)
		end
	end
end

function NewUpdateMgr:__callGameDownloadProgressHandlerBack(downloadedSize, totalSize, downloadInfo)
	if self.mDownloadProgressHandler then
		for k,v in pairs(self.mDownloadProgressHandler) do
			v(downloadedSize, totalSize, downloadInfo)
		end
	end
end
---------------------------------------------------- App相关 结束----------------------------------------------------

---------------------------------------------------- 删除游戏相关 开始 ---------------------------------------------------
-- 删前记录
function NewUpdateMgr:writeRemoveGameDirRecord(dir)
	print("NewUpdateMgr:writeRemoveGameDirRecord(",dir,")")
    local fileTaskFile = NewConstantConfig.LOCALPATH.FILE_TASK_PATH
    local fileUtils = cc.FileUtils:getInstance()
    local recordTable = nil
    if type(dir) == "string" and fileUtils:isDirectoryExist(dir) then
	    if fileUtils:isFileExist(fileTaskFile) then
	    	local jsonStr = fileUtils:getStringFromFile(fileTaskFile)
	    	recordTable = json.decode(jsonStr) or {}
	    else
	    	recordTable = {}
	    end

	    recordTable[dir] = {[NewConstantConfig.FILE_TASK_RECORD.HSWL_FILE_TASK_KEY_OPERATION] = NewConstantConfig.FILE_TASK_OPERATION_TYPE.HSWL_FILE_TASK_REMOVE}
	    fileUtils:writeStringToFile(json.encode(recordTable), fileTaskFile)
	end
end

-- 删完清除
function NewUpdateMgr:clearRemoveGameDirRecord(dir)
    print("NewUpdateMgr:clearRemoveGameDirRecord(",dir,")")
    local fileTaskFile = NewConstantConfig.LOCALPATH.FILE_TASK_PATH
    local fileUtils = cc.FileUtils:getInstance()
    local recordTable = nil
    if type(dir) == "string" and fileUtils:isDirectoryExist(dir) then
	    if fileUtils:isFileExist(fileTaskFile) then
	    	local jsonStr = fileUtils:getStringFromFile(fileTaskFile)
	    	recordTable = json.decode(jsonStr) or {}
	    else
	    	recordTable = {}
	    end

	    recordTable[dir] = nil
	    fileUtils:writeStringToFile(json.encode(recordTable), fileTaskFile)
	end
end

-- 删完游戏清除lua缓存
function NewUpdateMgr:clearGameLoadedPackage(gameid)
	print("NewUpdateMgr:clearGameLoadedPackage(", gameid, ")")
	local gameMgr = require("app.manager.GameManager").getInstance()
	local pkgName = gameMgr:getPkgName(tonumber(gameid) or 0)

	if pkgName then
		-- 清除已加载lua代码模块记录
		for k,v in pairs(package.loaded) do
			if string.match(k,"^" .. pkgName .. "%.") then
				print("clearGameLoadedPackage => ", k)
				package.loaded[k] = nil
			end
		end

		-- 清一层C++全路径缓存
	    cc.FileUtils:getInstance():purgeCachedEntries()
	end
end

-- 刪除游戏
function NewUpdateMgr:deleteGameInUpdatesDir(gameid)
	print("NewUpdateMgr:deleteGameInUpdatesDir(", gameid, ")")
	local gameid = tonumber(gameid)
	local gameMgr = require("app.manager.GameManager").getInstance()
    if gameid and gameid ~= 100 then
        local basePath = NewConstantConfig.LOCALPATH.UPDATES_PATH
        local gamePath = basePath .. gameMgr:getPkgName(gameid) .. "/" -- 结尾的分隔符必须有，不然cocos底层不当作目录处理
        local gameTempPath = basePath .. gameMgr:getPkgName(gameid) .. "_temp/"
        -- 先删除下载的_temp目录
        local isTempDirExist = cc.FileUtils:getInstance():isDirectoryExist(gameTempPath)
        if isTempDirExist then
        	self:writeRemoveGameDirRecord(gameTempPath)
        	cc.FileUtils:getInstance():removeDirectory(gameTempPath)
        	self:clearRemoveGameDirRecord(gameTempPath)
        end
        -- 再删除游戏目录
        local isDirExist = cc.FileUtils:getInstance():isDirectoryExist(gamePath)
        if isDirExist then
        	self:writeRemoveGameDirRecord(gamePath)
            cc.FileUtils:getInstance():removeDirectory(gamePath)
            self:clearRemoveGameDirRecord(gamePath)
            self:clearGameLoadedPackage(gameid)
            self:clearGameUpdatedRecord(gameid)
            gameMgr:__resetGameStatus(gameid)
        	gameMgr:reInitGame(gameid)
        end
    end
end
---------------------------------------------------- 删除游戏相关 结束 ---------------------------------------------------


return NewUpdateMgr