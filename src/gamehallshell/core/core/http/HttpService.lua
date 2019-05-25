--[[
core.HttpService.POST({mod="friend",act="list"},
    function(data) 
    end,
    function(errCode[, response])
    end)
    TODO 取消请求功能
]]


--[[
cc.XMLHTTPREQUEST_RESPONSE_STRING       = 0
cc.XMLHTTPREQUEST_RESPONSE_ARRAY_BUFFER = 1
cc.XMLHTTPREQUEST_RESPONSE_BLOB         = 2
cc.XMLHTTPREQUEST_RESPONSE_DOCUMENT     = 3
cc.XMLHTTPREQUEST_RESPONSE_JSON         = 4

METHOD: GET/POST/DELETE/PUT

--]]

--[[
TOLUA_API int register_xml_http_request(lua_State* L)
{
    tolua_open(L);
    lua_reg_xml_http_request(L);
    tolua_module(L,"cc",0);
    tolua_beginmodule(L,"cc");
      tolua_cclass(L,"XMLHttpRequest","cc.XMLHttpRequest","cc.Ref",lua_collect_xml_http_request);
      tolua_beginmodule(L,"XMLHttpRequest");
        tolua_variable(L, "responseType", lua_get_XMLHttpRequest_responseType, lua_set_XMLHttpRequest_responseType);
        tolua_variable(L, "withCredentials", lua_get_XMLHttpRequest_withCredentials, lua_set_XMLHttpRequest_withCredentials);
        tolua_variable(L, "timeout", lua_get_XMLHttpRequest_timeout, lua_set_XMLHttpRequest_timeout);
        tolua_variable(L, "readyState", lua_get_XMLHttpRequest_readyState, nullptr);
        tolua_variable(L, "status",lua_get_XMLHttpRequest_status,nullptr);
        tolua_variable(L, "statusText", lua_get_XMLHttpRequest_statusText, nullptr);
        tolua_variable(L, "responseText", lua_get_XMLHttpRequest_responseText, nullptr);
        tolua_variable(L, "response", lua_get_XMLHttpRequest_response, nullptr);
        tolua_function(L, "new", lua_cocos2dx_XMLHttpRequest_constructor);
        tolua_function(L, "open", lua_cocos2dx_XMLHttpRequest_open);
        tolua_function(L, "send", lua_cocos2dx_XMLHttpRequest_send);
        tolua_function(L, "abort", lua_cocos2dx_XMLHttpRequest_abort);
        tolua_function(L, "setRequestHeader", lua_cocos2dx_XMLHttpRequest_setRequestHeader);
        tolua_function(L, "getAllResponseHeaders", lua_cocos2dx_XMLHttpRequest_getAllResponseHeaders);
        tolua_function(L, "getResponseHeader", lua_cocos2dx_XMLHttpRequest_getResponseHeader);
        tolua_function(L, "registerScriptHandler", lua_cocos2dx_XMLHttpRequest_registerScriptHandler);
        tolua_function(L, "unregisterScriptHandler", lua_cocos2dx_XMLHttpRequest_unregisterScriptHandler);
      tolua_endmodule(L);
    tolua_endmodule(L);
    return 1;
}

--]]

 local scheduler = require(cc.PACKAGE_NAME .. ".scheduler")
-- 
local HttpService = {}
local logger = core.Logger.new("HttpService")
HttpService.defaultURL = ""
HttpService.defaultParams = {}

HttpService.requestId_ = 1
HttpService.requests = {}
HttpService.defaultTimeout = 10000


HttpService.timeoutReqs = {}

HttpService.defaultExtra = 
{
	header = 
	{
		["Content-Type"] = "application/x-www-form-urlencoded"
	},
	timeout = 10000,
	responseType = cc.XMLHTTPREQUEST_RESPONSE_STRING
}




function HttpService.getDefaultURL()
    return HttpService.defaultURL
end

function HttpService.setDefaultURL(url)
    HttpService.defaultURL = url
end

function HttpService.clearDefaultParameters()
    HttpService.defaultParams = {}
end

function HttpService.setDefaultParameter(key, value)
    HttpService.defaultParams[key] = value;
end

function HttpService.cloneDefaultParams(params)
    if params ~= nil then
        local tparams = {}
        table.merge(tparams,HttpService.defaultParams)
        table.merge(tparams,params)
        return tparams
    else
        return clone(HttpService.defaultParams)
    end
end

local except = {"header"}
local setXhrExtra = function(xhr,extra)
    if(xhr and extra)then
        if(extra.header) then
            for key,v in pairs(extra.header) do
                xhr:setRequestHeader(key,extra.header[key])
            end
        end
        --other
        -- for k,v in pairs(extra) do
        --     if not except[k] then
        --         xhr[k] = extra[k]
        --     end

        -- end

        xhr.timeout = (extra.timeout or HttpService.defaultTimeout);
        xhr.responseType = (extra.responseType or cc.XMLHTTPREQUEST_RESPONSE_STRING)
    end
end



local function request_(method, url, addDefaultParams, params, resultCallback, errorCallback,extra)
    local requestId = HttpService.requestId_
    logger:debugf("[%d] Method=%s URL=%s defaultParam=%s params=%s", requestId, method, url, json.encode(addDefaultParams), json.encode(params))


    --'onloadstart', 'onabort', 'onerror', 'onload', 'onloadend', 'ontimeout',onreadystatechange

     --创建一个请求，并以 指定method发送数据到服务端HttpService.cloneDefaultParams初始化
    local xhr = cc.XMLHttpRequest:new()
    xhr:open(method, url, true)
    setXhrExtra(xhr,extra or HttpService.defaultExtra)

    params = params or {}
    HttpService.requests[requestId] = xhr;
    HttpService.requestId_ = HttpService.requestId_ + 1;
    local allParams

    if (addDefaultParams) then
        allParams = HttpService.cloneDefaultParams(params);
    else
        allParams = params;
    end

    local paramStr = ""
    if(allParams)then
        for key,v in pairs(allParams) do
            if(paramStr ~="")then
                paramStr = paramStr .. "&";
            end

             paramStr = paramStr .. (tostring(key) .. "=" .. (tostring(allParams[key])));
        end

    end

    local modAndAct = ""
    if params.mod and params.act then
        modAndAct = string.format("[%s_%s]", params.mod, params.act)
    end

    if params.method then
        modAndAct = string.format("[%s]", params.method)
    end

    -- logger:debugf("[%s][%s][%s]%s %s", requestId, method, url, modAndAct, json.encode(allParams))

    local function onReadyStateChanged()

        if requestId and HttpService.timeoutReqs[requestId] then
            scheduler.unscheduleGlobal(HttpService.timeoutReqs[requestId])
            HttpService.timeoutReqs[requestId] = nil
        end
        local readyState = xhr.readyState
        if readyState == 4 then -- DONE

            local code = xhr.status;
            local statusText = xhr.statusText
            local response = xhr.response
            local responseText = xhr.responseText

            if code ~= 200 then
                -- 请求结束，但没有返回 200 响应代码
                logger:debugf("[%d] code=%s", requestId, code)
                -- 延迟一帧回调
                local function nextFrameErrorCallback()
                    if errorCallback ~= nil and requestId and HttpService.requests[requestId] ~= nil then
                        HttpService.requests[requestId] = nil
                        errorCallback(code)
                    end
                end
                scheduler.performWithDelayGlobal(nextFrameErrorCallback,0.001)

                return
            end

            HttpService.requests[requestId] = nil
            -- local response = request:getResponseString()
            -- todo:better,string太长了打日志报错
            if string.len(responseText) <= 10000 then
                logger:debugf("[%d] response=%s", requestId, responseText)
            end
            -- logger:debugf("[%d] response=%s", requestId, response)
            if resultCallback ~= nil then
                resultCallback(responseText)
            end
        else

            local code = xhr.status;
            local statusText = xhr.statusText
            local response = xhr.response
            local responseText = xhr.responseText
            -- 延迟一帧回调
            local function nextFrameErrorCallback()
                if errorCallback ~= nil and requestId and HttpService.requests[requestId] ~= nil then
                    HttpService.requests[requestId] = nil
                    errorCallback(code)
                end
            end
            scheduler.performWithDelayGlobal(nextFrameErrorCallback,0.001)
            
            return
        end

        xhr:unregisterScriptHandler()
    end

    xhr:registerScriptHandler(onReadyStateChanged)
    logger:debugf("[%s][%s][%s]%s %s", requestId, method, url, modAndAct, json.encode(allParams))

    if extra and extra.rawData then
        xhr:send(extra.rawData)
    else
        xhr:send(paramStr)
    end
    
    local timeout = checkint(xhr.timeout)
    if timeout > 0 then
        timeout = checknumber(string.format("%0.1f",timeout/1000))
        local handle = scheduler.performWithDelayGlobal(function()

            if requestId and HttpService.timeoutReqs[requestId] then
                HttpService.timeoutReqs[requestId] = nil
            end

            if requestId and HttpService.requests[requestId] then
                HttpService.requests[requestId]:abort()
                HttpService.requests[requestId] = nil
            end

            if errorCallback ~= nil then
                errorCallback(0,"timeout")
            end
        end,timeout)

        HttpService.timeoutReqs[requestId] = handle
    end

    return requestId
end

--[[
    POST到默认的URL，并附加默认参数
]]
function HttpService.POST(params, resultCallback, errorCallback,extra)
    return request_("POST", HttpService.defaultURL, true, params, resultCallback, errorCallback,extra)
end

--[[
    GET到默认的URL，并附加默认参数
]]
function HttpService.GET(params, resultCallback, errorCallback,extra)
    return request_("GET", HttpService.defaultURL, true, params, resultCallback, errorCallback,extra)
end

--[[
    POST到指定的URL，该调用不附加默认参数，如需默认参数,params应该使用HttpService.cloneDefaultParams初始化
]]
function HttpService.POST_URL(url, params, resultCallback, errorCallback,extra)
    return request_("POST", url, true, params, resultCallback, errorCallback,extra)
end

--[[
    GET到指定的URL，该调用不附加默认参数，如需默认参数,params应该使用HttpService.cloneDefaultParams初始化
]]
function HttpService.GET_URL(url, params, resultCallback, errorCallback,extra)
    return request_("GET", url, false, params, resultCallback, errorCallback,extra)
end

-- {
--     fileFieldName="filepath",
--     filePath=device.writablePath.."screen.jpg",
--     contentType="Image/jpeg",
--     extra={
--         act"=upload,
--         submit=upload,
--     }
-- }
function HttpService.UPLOAD_FILE(url, params,resultCallback, errorCallback)
    assert(params or params.fileFieldName or params.filePath, "Need file params!")
    local BOUNDARY = "----------------------------78631b43218d";
    local NEWLINE = "\r\n";
    local function postFormFile(key, filePath)
        local filename = core.getFileName(filePath)
        local file_data = cc.FileUtils:getInstance():getDataFromFile(filePath)
        local sb =""
        sb =sb .. ("--");
        sb =sb .. (BOUNDARY);
        sb =sb .. (NEWLINE);
        sb =sb .. ("Content-Disposition: form-data; ");
        sb =sb .. ("name=\"");
        sb =sb .. (key);
        sb =sb .. ("\"; ");
        sb =sb .. ("filename=\"");
        sb =sb .. (filename);
        sb =sb .. ("\"");
        sb =sb .. (NEWLINE);
        sb =sb .. ("Content-Type: application/octet-stream");
        sb =sb .. (NEWLINE);
        sb =sb .. (NEWLINE);
        sb =sb .. file_data;
        sb =sb .. (NEWLINE);
        return sb;
    end

    local function postFormContent(key,val)
        local sb =""
        sb =sb .. ("--");
        sb =sb .. (BOUNDARY);
        sb =sb .. (NEWLINE);
        sb =sb .. ("Content-Disposition: form-data; name=\"");
        sb =sb .. (key);
        sb =sb .. ("\"");
        sb =sb .. (NEWLINE);
        sb =sb .. (NEWLINE);
        sb =sb .. (val);
        sb =sb .. (NEWLINE);
        return sb
    end

    local function postFormEnd( ... )
        local sb = ""
        sb =sb .. ("--");
        sb =sb .. (BOUNDARY);
        sb =sb .. ("--");
        sb =sb .. (NEWLINE);
        return sb
    end

    local contentType = (params.contentType or "application/octet-stream")
    local boundaryData = ""
    if params.extra then
        contentType = "multipart/form-data"
        for k,v in pairs(params.extra) do
            boundaryData = boundaryData .. postFormContent(k,v) 
        end
    end

    boundaryData = boundaryData .. postFormFile(params.fileFieldName,params.filePath)
    boundaryData = boundaryData .. postFormEnd()

    local contentType = contentType .. ("; boundary=" .. BOUNDARY);
    local header = {["Content-Type"] = contentType}
    
    -- print("boundaryData",boundaryData)
    return request_("POST", url, false, {}, resultCallback, errorCallback,{header = header,rawData = boundaryData})
end

--[[
    取消指定id的请求
]]
function HttpService.CANCEL(requestId)
    if requestId and HttpService.timeoutReqs[requestId] then
        scheduler.unscheduleGlobal(HttpService.timeoutReqs[requestId])
        HttpService.timeoutReqs[requestId] = nil
    end

    if requestId and HttpService.requests[requestId] then
        HttpService.requests[requestId]:abort()
        HttpService.requests[requestId] = nil
    end
end

return HttpService