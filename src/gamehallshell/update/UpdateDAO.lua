local AppUpdateInfo = class("AppUpdateInfo")

function AppUpdateInfo:ctor()
	-- updateInfo = {fromVersion:xx.xx.xx, toVersion:xx.xx.xx, lastTipTime:xxxxxxxxx, updateType:x}
	self.mInfoTab = {}
end

function AppUpdateInfo:parse(infoStr)
	self.mInfoTab = json.decode(infoStr) or {}
end

function AppUpdateInfo:setFromVersion(fromVersion)
	self.mInfoTab.fromVersion = fromVersion
	return self
end

function AppUpdateInfo:getFromVersion()
	return self.mInfoTab.fromVersion
end

function AppUpdateInfo:setToVersion(toVersion)
	self.mInfoTab.toVersion = toVersion
	return self
end

function AppUpdateInfo:getToVersion()
	return self.mInfoTab.toVersion
end

function AppUpdateInfo:setLastTipTime(lastTipTime)
	self.mInfoTab.lastTipTime = lastTipTime
	return self
end

function AppUpdateInfo:getLastTipTime()
	return self.mInfoTab.lastTipTime
end

function AppUpdateInfo:setUpdateType(updateType)
	self.mInfoTab.updateType = updateType
	return self
end

function AppUpdateInfo:getUpdateType()
	return self.mInfoTab.updateType
end

function AppUpdateInfo:toJsonString()
	return json.encode(self.mInfoTab)
end

function AppUpdateInfo:isValid()
	return self.mInfoTab and type(self.mInfoTab.fromVersion) == "string" and 
		type(self.mInfoTab.toVersion) == "string" and type(self.mInfoTab.lastTipTime) == "number" and type(self.mInfoTab.updateType) == "number"
end




--- 用于持久化一些APP更新相关数据
local UpdateDAO = class("UpdateDAO")

UpdateDAO.USER_DEFAULT_KEY = {
	APP_UPDATE_INFO = "APP_UPDATE_INFO",
}

function UpdateDAO:ctor()
	self.mUserDefault = cc.UserDefault:getInstance()
end

function UpdateDAO:createAppUpdateInfo()
	return AppUpdateInfo.new()
end

function UpdateDAO:getAppUpdateInfo()
	local infoStr = self.mUserDefault:getStringForKey(self.USER_DEFAULT_KEY.APP_UPDATE_INFO)
	local infoObj = self:createAppUpdateInfo()
	infoObj:parse(infoStr)
	return infoObj
end

function UpdateDAO:updateAppUpdateInfo(infoObj)
	local infoStr = infoObj:toJsonString()
	self.mUserDefault:setStringForKey(self.USER_DEFAULT_KEY.APP_UPDATE_INFO, infoStr)
	self.mUserDefault:flush()
end

function UpdateDAO:deleteAppUpdateInfo()
	self.mUserDefault:deleteValueForKey(self.USER_DEFAULT_KEY.APP_UPDATE_INFO)
	self.mUserDefault:flush()
end

return UpdateDAO