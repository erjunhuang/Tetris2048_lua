local BuglyUtil = {}


if device.platform == "ios" then
	BuglyUtil.Tags = 
	{
		Crash = 71653,
	}

elseif device.platform == "android" then
	BuglyUtil.Tags = 
	{
		Crash = 71655,
	}

end



--@param appid string
--@param release int 0:debug,1:release
function BuglyUtil.init(appid, release)
	--兼容旧接口，新版已经弃用
	if lua_crash_report_method then
		release = type(release) == "number" and release or 0
		lua_crash_report_method(0, tostring(appid), release)
	elseif buglyInitCrashReport then
		--新版接口，详见 Bugly/lua/BuglyLuaAgent.cpp
		buglyInitCrashReport(tostring(appid), release)
	end
end

--@param userid string
function BuglyUtil.setUserId(userid)
	--兼容旧接口，新版已经弃用
	if lua_crash_report_method then
		lua_crash_report_method(1, tostring(userid))
	elseif buglySetUserId then
		--新版接口，详见 Bugly/lua/BuglyLuaAgent.cpp
		buglySetUserId(tostring(userid))
	end
end

--@param version string
function BuglyUtil.setAppVersion(version)
	--兼容旧接口，新版已经弃用
	if lua_crash_report_method then
		lua_crash_report_method(2, tostring(version))
	elseif buglySetAppVersion then
		--新版接口，详见 Bugly/lua/BuglyLuaAgent.cpp
		buglySetAppVersion(tostring(version))
	end
end

--@param channel string
function BuglyUtil.setAppChannel(channel)
	if lua_crash_report_method then
		--兼容旧接口，新版已经弃用
		lua_crash_report_method(3, tostring(channel))
	elseif buglySetAppChannel then
		--新版接口，详见 Bugly/lua/BuglyLuaAgent.cpp
		buglySetAppChannel(tostring(channel))
	end
end


--@param channel number
function BuglyUtil.setTag(tag)
	if buglySetTag then
		buglySetTag(tag)
	end
end

--@param key string  value string
function BuglyUtil.addUserValue(key,value)
	if buglyAddUserValue then
		buglyAddUserValue(key,value)
	end
end


function BuglyUtil.removeUserValue(key)
	if buglyRemoveUserValue then
		buglyRemoveUserValue(key)
	end
end

function BuglyUtil.reportLog(tag, log)
	if buglyLog and type(tag) == "string" and type(log) == "string"  then
		--1:debug
		buglyLog(1, tag, log)
	end
end





--default init
function BuglyUtil.default_init()
	BuglyUtil.init(appconfig.buglyAppid, IS_RELEASE and 1 or 0)
    BuglyUtil.setAppVersion(game.gameManager:getGameVersion(GameType.HALL))
    BuglyUtil.setAppChannel(appconfig.appid)

    if game and type(game.getAppVersion) == "function" then
    	BuglyUtil.addUserValue("releVer",game.getAppVersion())
    end

    if game and type(game.getAppBuildVersion) == "function" then
    	BuglyUtil.addUserValue("buildVer",game.getAppBuildVersion())
    end
    

end

return BuglyUtil