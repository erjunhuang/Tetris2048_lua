
-- 工具函数
local Utils = {}
Utils.s_directorySeparator = "/"

function Utils.md5File(filepath)
	local md5code = cc.utils_.md5file(filepath)
	return md5code
end

function Utils.md5String(str)
	local md5code = cc.utils_.md5(str)
	return md5code
end

function Utils.isSameMD5(first, second)
	print("first: ", first)
	print("second: ", second)
	return string.upper(first) == string.upper(second)
end

function Utils.verifyFile(filepath, md5)
	if not io.exists(filepath) then
		return false;
	end
	return Utils.isSameMD5(Utils.md5File(filepath), md5)
end

function Utils.verifyString(str, md5)
	if not io.exists(filepath) then
		return false;
	end
	return Utils.isSameMD5(Utils.md5File(str), md5)
end

-- 整包加载LuaChunk
function Utils.loadLuaZip(zipInSearchPath)
	if not zipInSearchPath or type(zipInSearchPath) ~= "string" then
		print("需要加载的zip文件名称非法", zipInSearchPath)
		return
	end
	cc.LuaLoadChunksFromZIP(zipInSearchPath)
end

-- 拼接路径分隔符
function Utils.joinDirectorySeparator(str)
	local endchar = string.sub(str, -1)
	if endchar == Utils.s_directorySeparator or endchar == "\\" then
		return str
	else 
		return str .. Utils.s_directorySeparator
	end
end

-- 反斜杠替换为斜杠
function Utils.convertDirectorySeparator(path)
	return string.gsub(path, "\\", Utils.s_directorySeparator)
end

-- 解压文件
function Utils.unzipFile(zipPath, destDir)
	local result = cc.utils_.unzipFile(zipPath, destDir)
	return result
end

-- 获取文件大小
function Utils.getFileSize(file)
	local size = lfs.attributes(file, "size") 
	return size
end

-- 目录是否存在
function Utils.isDirExist(dir)
	local mode = lfs.attributes(dir, "mode")
	if mode and mode == "directory" then
		return true
	end
	return false
end

-- 文件是否存在
function Utils.isFileExist(file)
	local mode = lfs.attributes(file, "mode")
	if mode and mode == "file" then
		return true
	end
	return false
end

-- 路径是否存在
function Utils.isPathExist(path)
	local mode = lfs.attributes(path, "mode")
	return mode ~= nil
end

-- 是否为目录
function Utils.isDir(path)
	local mode = lfs.attributes(path, "mode")
	return mode == "directory"
end

-- 是否为文件
function Utils.isFile(path)
	local mode = lfs.attributes(path, "mode")
	return mode == "file"
end

-- 查找目标目录下的所有符合pattern的文件名的文件
function Utils.findFiles(path,pattern)
	local resultTab = {}
	if not Utils.isDirExist(path) then
		return resultTab
	end
	for dir in lfs.dir(path) do
		if dir ~= "." and dir ~= ".." then
			local curPath = Utils.joinDirectorySeparator(path) .. dir
			local mode = lfs.attributes(curPath, "mode")
			if mode == "file" then
				if string.match(dir, pattern) then
					table.insert(resultTab, dir)
				end
			end
		end
	end
	return resultTab
end

-- 重命名文件，移动文件
function Utils.renameFile(srcpath, dstpath, force)
	if not Utils.isFileExist(srcpath) then
		print("源文件不合法")
		return false
	end
	force = force == true
	local pathinfo = io.pathinfo(dstpath)
	local dir = pathinfo.dirname
	local result = Utils.mkdirs(dir)
	if not result then
		return false
	end
	if Utils.isFileExist(dstpath) and force then
		Utils.rmfile(dstpath)
	end
	local err
	result,err = os.rename(srcpath, dstpath)
	if result then
		return true
	end
	print("renameFile err = ", err)
	return false
end

-- 创建目录（不会创建父目录）
function Utils.mkdir(path)
	if Utils.isPathExist(path) then
		if Utils.isDir(path) then
			print("路径已经存在，并且该路径为目录 path = " .. path)
			return true
		else 
			print("路径已经存在，并且该路径不是目录 path = " .. path)
			return false
		end
	end

	local succ, err = lfs.mkdir(path)
    if succ then
    	print("创建目录成功 path = " .. path)
        return true
    else
    	print("创建目录失败 err = " .. err)
    	return false
    end
end

-- 创建目录（会创建父目录）
function Utils.mkdirs(path)
	-- dump("mkdir " .. tostring(path))
	if Utils.isPathExist(path) then
		if Utils.isDir(path) then
			return true
		else 
			print("路径已经存在，并且该路径不是目录 path = " .. path)
			return false
		end
	end

	local pathElements = string.split(path, Utils.s_directorySeparator)
	for i = #pathElements, 1, -1 do
		local element = string.trim(pathElements[i] or "")
		if element == "" then
			table.remove(pathElements, i)
		end
	end

	if #pathElements < 1 then
		print("路径非法 path = " .. path)
		return false
	end

	local curPath = ""
	if string.sub(path, 1, 1) == Utils.s_directorySeparator then
        curPath = Utils.s_directorySeparator
    end
	for i = 1, #pathElements do
		curPath = curPath .. Utils.joinDirectorySeparator(pathElements[i])
		local result = Utils.mkdir(curPath)
		if not result then
			return false
		end
	end

	return true
end

-- 删除目录中的文件
-- path目录，filename目录中的文件名
function Utils.rmfileInPath(path, filename)
	local rmfilepath = Utils.joinDirectorySeparator(path)..filename
	Utils.rmfile(rmfilepath)
end

-- 删除文件
function Utils.rmfile(path)
	if not Utils.isPathExist(path) then
		print("要删除的路径并不存在 path = " .. path)
		return true
	end

	if not Utils.isFile(path) then
		print("要删除的路径并非文件 path = " .. path)
		return false
	end

	local _, err = os.remove(path)
	if err then
		print("删除文件失败 path = ".. path .. ", err = " .. err)
		return false
	else
		print("删除文件 "..path.." 成功")
		return true
	end
end

-- 删除空文件夹
function Utils.rmEmptyDir(path)
	if not Utils.isDirExist(path) then
		return false
	end
	local result, err = lfs.rmdir(path)
	if not result then
		print("删除目录失败 path = " .. path .. ", err = " .. err)
		return false
	else
		return true
	end
end

-- 删除目录和目录下的所有目录和文件
function Utils.rmdirs(path)
	if not Utils.isPathExist(path) then
		print("要删除的路径并不存在 path = " .. path)
		return true
	end

	if not Utils.isDir(path) then
		print("要删除的路径并非目录 path = " .. path)
		return false
	end

	local function _rmdir(path)
		for dir in lfs.dir(path) do
			if dir ~= "." and dir ~= ".." then
				local curPath = Utils.joinDirectorySeparator(path) .. dir
				local mode = lfs.attributes(curPath, "mode")
				local result = false
				if mode == "directory" then
					result = _rmdir(curPath)
					if result then
						result = Utils.rmEmptyDir(curPath)
					end
				elseif mode == "file" then
					result = Utils.rmfile(curPath)
				end
				if not result then
					return false
				end
			end
		end
		return true
	end

	local result = _rmdir(path)
	if result then
		result = Utils.rmEmptyDir(path)
	end
	return result
end

return Utils