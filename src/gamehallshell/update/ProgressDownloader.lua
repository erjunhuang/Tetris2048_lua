local ConstantConfig = import(".ConstantConfig")

-- 带下载进度的下载器LuaDownloader
local ProgressDownloader = class('ProgressDownloader')

function ProgressDownloader:ctor()
    self.mDownloadInfosTab = {}

    -- 最大任务数，秒为单位的读取超时，临时文件后缀
    self.mLuaDownloader = cc.LuaDownloader:create(10,15)
    self.mLuaDownloader:retain()
    local function onDownloadEvent(event)
            if not self.mDownloadInfosTab then
                return
            end

            -- eventCode- 0:progress 1:fail 2:finished
            local eventCode = event:getEventCode()
            local assetId = event:getAssetId()

            local downloadInfo = self.mDownloadInfosTab[assetId]

            -- print("ProgressDownloader----onDownloadEvent----", " eventCode = ", eventCode, " assetId = ", assetId)
            if eventCode == ConstantConfig.LUA_DOWNLOADER_EVENT_CODE.PROGRESS then
                
                local downloadedSize = event:getDownloaded()
                local totalSize = event:getTotal()

                -- print("PROGRESS", " assetId = ", assetId, " downloadedSize = ", downloadedSize, " totalSize = ", totalSize)
                self:onDownloadProgress(downloadedSize, totalSize, downloadInfo)
            elseif eventCode == ConstantConfig.LUA_DOWNLOADER_EVENT_CODE.FINISHED then
                -- print("FINISHED", " assetId = ", assetId)
                self:onDownloadFinished(true, downloadInfo)
            elseif eventCode == ConstantConfig.LUA_DOWNLOADER_EVENT_CODE.FAILED then
                -- print("FAILED", " assetId = ", assetId)
                self:onDownloadFinished(false, downloadInfo)
            end
        end
    self.mEventListener = cc.EventListenerDownloader:create(self.mLuaDownloader,onDownloadEvent)
    cc.Director:getInstance():getEventDispatcher():addEventListenerWithFixedPriority(self.mEventListener,1)
end

function ProgressDownloader:clean()
    cc.Director:getInstance():getEventDispatcher():removeEventListener(self.mEventListener)
    self.mEventListener = nil
    self.mLuaDownloader:release()
    self.mLuaDownloader = nil
    self.mDownloadInfosTab = nil
end

function ProgressDownloader:download(downloadInfo)
    print("---------------------ProgressDownloader:download---------------------")
    dump(downloadInfo)
    local url = downloadInfo.url
	local savepath = downloadInfo.savepath
    local md5 = downloadInfo.md5
    self.mDownloadInfosTab[md5] = downloadInfo
    self.mLuaDownloader:createDownloadFileTask(url,savepath,md5)
end

function ProgressDownloader:onDownloadFinished(result, downloadInfo)
    local md5 = downloadInfo.md5
    self.mDownloadInfosTab[md5] = nil

    local data = {}
	data.result = result
	data.downloadInfo = downloadInfo
	core.EventCenter:dispatchEvent({name = ConstantConfig.UPDATEEVENT.UPDATE_FILE_DOWNLOAD, data = data})
end

function ProgressDownloader:onDownloadProgress(downloadedSize, totalSize, downloadInfo)
    local data = {}
    data.downloadedSize = downloadedSize
    data.totalSize = totalSize
    data.downloadInfo = downloadInfo
    core.EventCenter:dispatchEvent({name = ConstantConfig.UPDATEEVENT.UPDATE_FILE_DOWNLOAD_PROGRESS, data = data})
end


return ProgressDownloader