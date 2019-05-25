local ConstantConfig = import(".ConstantConfig")
local Downloader = import(".ProgressDownloader")

-- 任务管理器
local NewTaskManager = class("NewTaskManager")

function NewTaskManager:ctor()
	self.mDownloader = Downloader.new() -- 显式任务下载器

	self.mWaitingTasks = {}

	self.mDownloadingTask = nil

	self.mShouldRun = false
	self.mEventHandle = nil

	self:addEventListener()
end

function NewTaskManager:clean()
	print("-----------------------NewTaskManager:clean--------------------------")
	self:removeEventListener()
	self.mDownloader:clean()
	self.mWaitingTasks = nil
	self.mDownloadingTask = nil
end

function NewTaskManager:addEventListener()
	if not self.mEventHandle then
		self.mEventHandle = core.EventCenter:addEventListener(
			ConstantConfig.UPDATEEVENT.UPDATE_FILE_DOWNLOAD, handler(self, self.onFileDownload))
	end
end

function NewTaskManager:removeEventListener()
	if self.mEventHandle then
		print("NewTaskManager 清除下载事件回调")
		print(self.mEventHandle, type(self.mEventHandle))
		core.EventCenter:removeEventListener(self.mEventHandle)
		self.mEventHandle = nil
	end
end

function NewTaskManager:onFileDownload(event)
	local data = event.data
	local result = data.result
	local downloadInfo = data.downloadInfo
	
	if self.mDownloadingTask and self.mDownloadingTask == downloadInfo then
		if self.mShouldRun then
			if #self.mWaitingTasks > 0 then
				self:getTaskAndDownload()
			else
				self.mDownloadingTask = nil
			end
		else
			self.mDownloadingTask = nil
		end
	end
end

function NewTaskManager:createNewTask(upType, gameid, md5, size, name, url, savepath)
	local task = {}
	task.type = upType
	task.gameid = gameid
	task.md5 = md5
	task.size = size
	task.name = name
	task.url = url
	task.savepath = savepath
	return task
end

function NewTaskManager:addNewTask(task)
	print("添加下载任务: ", task.gameid)
    table.insert(self.mWaitingTasks,task)
end

function NewTaskManager:getTask()
    local task = nil
    if #self.mWaitingTasks > 0 then
        task = table.remove(self.mWaitingTasks, 1)
    end
    return task
end

function NewTaskManager:start()
	self.mShouldRun = true
	if (not self.mDownloadingTask) and #self.mWaitingTasks > 0 then
		self:getTaskAndDownload()
	end
end

function NewTaskManager:stop()
	self.mShouldRun = false
end

function NewTaskManager:getTaskAndDownload()
	print("--------------NewTaskManager:getTaskAndDownload-----------------------")
    local task = self:getTask()
    dump(task)
    if task then
        self.mDownloadingTask = task
        self.mDownloader:download(task)
    end
end

return NewTaskManager