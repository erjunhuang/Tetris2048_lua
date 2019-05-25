local Utils = import(".Utils")

local ConstantConfig = {}

-- 更新类型定义
ConstantConfig.UPDATETYPE = {
	NOUPDATE = 0, 				-- 无更新
	FORCE = 1, 					-- 强制热更新
	IMPLICIT = 2, 				-- 隐式/后台更新
	OPTIONAL = 3, 				-- 可选热更新
	QUICK = 4, 					-- 敏捷更新, 不弹窗确认，进入游戏前直接下载的强制热更新

	OPTIONAL_BS_DIFF_APK = 5, 	-- 可选差异apk包更新
	FORCE_BS_DIFF_APK = 6,		-- 强制差异apk包更新
	OPTIONAL_FULL_APK = 7, 		-- 可选完整apk包更新
	FORCE_FULL_APK = 8,			-- 强制完整apk包更新
	OPTIONAL_APP_STORE = 9,		-- 可选iOS新版
	FORCE_APP_STORE = 10,		-- 强制iOS新版
	FORCE_BROWSER = 11,			-- 强制浏览器更新
}

-- APP更新
ConstantConfig.APP_UPDATE_TYPES = {
	ConstantConfig.UPDATETYPE.OPTIONAL_BS_DIFF_APK,
	ConstantConfig.UPDATETYPE.FORCE_BS_DIFF_APK,

	ConstantConfig.UPDATETYPE.OPTIONAL_FULL_APK,
	ConstantConfig.UPDATETYPE.FORCE_FULL_APK,

	ConstantConfig.UPDATETYPE.OPTIONAL_APP_STORE,
	ConstantConfig.UPDATETYPE.FORCE_APP_STORE,

	ConstantConfig.UPDATETYPE.FORCE_BROWSER,
}

-- Lua更新
ConstantConfig.LUA_UPDATE_TYPES = {
	ConstantConfig.UPDATETYPE.FORCE,
	ConstantConfig.UPDATETYPE.IMPLICIT,
	ConstantConfig.UPDATETYPE.OPTIONAL,
	ConstantConfig.UPDATETYPE.QUICK,
}

-- 强制更新
ConstantConfig.FORCE_UPDATE_TYPES = {
	-- Lua部分
	ConstantConfig.UPDATETYPE.FORCE,
	ConstantConfig.UPDATETYPE.QUICK,

	-- APP部分
	ConstantConfig.UPDATETYPE.FORCE_BS_DIFF_APK,
	ConstantConfig.UPDATETYPE.FORCE_FULL_APK,
	ConstantConfig.UPDATETYPE.FORCE_APP_STORE,

	ConstantConfig.UPDATETYPE.FORCE_BROWSER,
}

-- 可选更新
ConstantConfig.OPTIONAL_UPDATE_TYPES = {
	-- Lua部分
	ConstantConfig.UPDATETYPE.OPTIONAL,

	-- APP部分
	ConstantConfig.UPDATETYPE.OPTIONAL_BS_DIFF_APK,
	ConstantConfig.UPDATETYPE.OPTIONAL_FULL_APK,
	ConstantConfig.UPDATETYPE.OPTIONAL_APP_STORE,
}

-- 广播事件
ConstantConfig.UPDATEEVENT = {
	UPDATE_FILE_DOWNLOAD = "UPDATE_FILE_DOWNLOAD", -- 文件下载结果
	UPDATE_FILE_DOWNLOAD_PROGRESS = "UPDATE_FILE_DOWNLOAD_PROGRESS", -- 文件下载进度
}

-- LuaDownloader 回调事件码
ConstantConfig.LUA_DOWNLOADER_EVENT_CODE = {
	PROGRESS = 0, -- 进度
	FAILED = 1, -- 下载失败
	FINISHED = 2, -- 下载完成
}

-- Lua大厅版本号时间线，用于做版本兼容
ConstantConfig.LUA_HALL_VERSION_TIMELINE = {
	-- 全国包无用
	-- CAN_UPDATE_APP_BY_EXTERNAL_BROWSER = "1.0.0.10",	-- 可以调用外部浏览器下载安装包/跳转APPStore的版本号
	-- CAN_UPDATE_APP_INSIDE = "1.0.1.0",					-- 内部本身支持apk更新，apk差异更新，获取系统信息的版本号
	-- CAN_GET_BATTERY_LEVEL = "1.0.2.0",					-- 可以调用源生接口获取电量变化
}

-- 本地路径
ConstantConfig.LOCALPATH = {
	DOWNLOAD_PATH = Utils.joinDirectorySeparator(device.writablePath) .. "downloads/", -- 下载路径
	PREUPDATE_PATH = Utils.joinDirectorySeparator(device.writablePath) .. "preupdates/", -- 准备更新路径(用于重启后更新/隐式更新)
	PREUPDATE_CONFIG_PATH = Utils.joinDirectorySeparator(device.writablePath) .. "preupdates/preupdates.config", -- 隐式热/Lua更新的配置文件路径
	DOWNLOADS_CONFIG_PATH = Utils.joinDirectorySeparator(device.writablePath) .. "downloads/downloads.config", -- 显式热/Lua更新的记录文件路径
	UPDATES_PATH = Utils.joinDirectorySeparator(device.writablePath) .. "updates/", -- 更新加载路径
	APK_DOWNLOADS_PATH = Utils.joinDirectorySeparator(device.writablePath) .. "apkdownloads/", -- apk下载路径，与android/res/xml/provider_paths.xml中配置的path相同
}

return ConstantConfig