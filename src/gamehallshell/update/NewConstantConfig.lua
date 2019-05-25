local ConstantConfig = {}

-- 拼接路径分隔符
local function joinDirectorySeparator(str)
	local endchar = string.sub(str, -1)
	if endchar == "/" or endchar == "\\" then
		return str
	else 
		return str .. "/"
	end
end

--[[
对应C++中的
    enum class State
    {
        UNCHECKED,
        PREDOWNLOAD_VERSION,
        DOWNLOADING_VERSION,
        VERSION_LOADED,
        PREDOWNLOAD_MANIFEST,
        DOWNLOADING_MANIFEST,
        MANIFEST_LOADED,
        NEED_UPDATE,
        UPDATING,
        UNZIPPING,
        UP_TO_DATE,
        FAIL_TO_UPDATE
    };
由AssetsManager:getState()获取
]]
ConstantConfig.ASSETS_MANAGER_EX_STATE = {
	UNCHECKED = 0,
	PREDOWNLOAD_VERSION = 1,
	DOWNLOADING_VERSION = 2,
	VERSION_LOADED = 3,
	PREDOWNLOAD_MANIFEST = 4,
	DOWNLOADING_MANIFEST = 5,
	MANIFEST_LOADED = 6,
	NEED_UPDATE = 7,
	UPDATING = 8,
	UNZIPPING = 9,
	UP_TO_DATE = 10,
	FAIL_TO_UPDATE = 11,
}

-- 关键字
ConstantConfig.FILE_TASK_RECORD = {
	HSWL_FILE_TASK_KEY_OPERATION = "op",
	HSWL_FILE_TASK_KEY_FROM = "from",
}

-- 操作类型
ConstantConfig.FILE_TASK_OPERATION_TYPE = {
	HSWL_FILE_TASK_MOVE_FROM = 1,
	HSWL_FILE_TASK_REMOVE = 2,
}

-- 本地路径
ConstantConfig.LOCALPATH = {
	DOWNLOAD_PATH = joinDirectorySeparator(device.writablePath) .. "downloads/", -- 下载路径
	PREUPDATE_PATH = joinDirectorySeparator(device.writablePath) .. "preupdates/", -- 准备更新路径(用于重启后更新/隐式更新)
	PREUPDATE_CONFIG_PATH = joinDirectorySeparator(device.writablePath) .. "preupdates/preupdates.config", -- 隐式热/Lua更新的配置文件路径
	DOWNLOADS_CONFIG_PATH = joinDirectorySeparator(device.writablePath) .. "downloads/downloads.config", -- 显式热/Lua更新的记录文件路径
	UPDATES_PATH = joinDirectorySeparator(device.writablePath) .. "updates/", -- 更新加载路径
	ADDONS_CONFIG_PATH = joinDirectorySeparator(device.writablePath) .. "updates/addons.config", -- 插件持久化配置路径
	APK_DOWNLOADS_PATH = joinDirectorySeparator(device.writablePath) .. "apkdownloads/", -- apk下载路径，与android/res/xml/provider_paths.xml中配置的path相同
	FILE_TASK_PATH = joinDirectorySeparator(device.writablePath) .. "hswl_paiyou_filetask.record", -- 删除/移动的操作记录文件，用于LuaUpdateFixer
}

return ConstantConfig