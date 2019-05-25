--2018.11.05
--mj局部直接使用了audio.playsound，为了不一个个更新，底层兼容，创建新类audioNew
local engine = ccexp.AudioEngine
local audio = {}

-------------------------------基本接口 start -------
local __audioMap = {}
local __soundVolume = 1
local __musicVolume = 1

function audio.__addToAudioMap(audioID,path,loop,volume,callback,atype)
    __audioMap[audioID] = {audioID = audioID,path=path,loop=loop,volume=volume,callback=callback,atype=atype}
end

function audio.__removeFromAudioMap(audioID)
    __audioMap[audioID] = nil
end

function audio.__clearAudioMap( ... )
    __audioMap = {}
end

function audio.onAudioFinishCallback(audioID,filePath)
    local tAudio = __audioMap[audioID]
    if tAudio and tAudio.callback then
        tAudio.callback(audioID,filePath)
    end

    if not tAudio or not tAudio.loop then
        audio.__removeFromAudioMap(audioID)
    end
end

function audio.__addFinishCallback(audioID)
    engine:setFinishCallback(audioID,audio.onAudioFinishCallback)
end

--预加载
function audio.preload(filename,callback)
    if not filename then
        printError("audioNew.preload() - invalid filename")
        return
    end
    if DEBUG > 1 then
        printf("[audioNew] preload() - filename: %s", tostring(filename))
    end

    engine:preload(filename,callback)
end

function audio.unload(filename)
    if not filename then
        printError("audioNew.unload() - invalid filename")
        return
    end
    if DEBUG > 1 then
        printf("[audioNew] unload() - filename: %s", tostring(filename))
    end

    engine:uncache(filename)
end

function audio.unloadAll()
    if DEBUG > 1 then
        printf("[audioNew] unloadAll()")
    end
    engine:uncacheAll()
end


function audio.stopAll( ... )
    engine:stopAll()
    audio.__clearAudioMap()
end

function audio.pauseAll( ... )
    engine:pauseAll()
end

function audio.resumeAll( ... )
    engine:resumeAll()
end


--总时长
function audio.getDuration(audioID)
    if audioID then
        return engine:getDuration(audioID)
    end
end

function audio.getCurrentTime(audioID)
    if audioID then
        return engine:getCurrentTime(audioID)
    end
end

function audio.setCurrentTime(audioID,time)
    if audioID then
        return engine:setCurrentTime(audioID,time)
    end
end


function audio.getState(audioID)
    if audioID then
        return engine:getState(audioID)
    end
end

-------------------------------基本接口 end -------



function audio.preloadMusic(filename,callback)
    audio.preload(filename,callback)
end

function audio.unloadMusic(filename)
    audio.unload(filename)
end

function audio.unloadAllMusic()
    for k,v in pairs(__audioMap) do
        if v.atype == "music" and v.path then
            audio.unload(v.path)
        end
    end
end


function audio.playMusic(filename,loop,volume,callback,stopPre)

    assert(filename, "audioNew.playMusic() - invalid filename")
    if type(loop) ~= "boolean" then loop = true end


    stopPre = (stopPre == nil and true or stopPre)
    if stopPre and audio.stopAllMusic then
        audio.stopAllMusic()
    end

    if DEBUG > 1 then
        printf("[audioNew] playMusic() - filename: %s, loop: %s", tostring(filename), tostring(loop))
    end

    volume = volume or __musicVolume
    local audioID = engine:play2d(filename, loop,volume)
    audio.__addToAudioMap(audioID,filename,loop,volume,callback,"music")
    if callback then
        audio.__addFinishCallback(audioID)
    end

    return audioID
end

function audio.isMusicPlaying(audioID)
    if not audioID then
        printError("audioNew.isMusicPlaying() - invalid audioID")
        return
    end
    if not __audioMap[audioID] then
        printError("audioNew.isMusicPlaying() - invalid __audioMap[audioID]")

        return
    end

    local state = audio.getState(audioID)
    return (1 == state)
end


--为兼容旧版保留，建议直接使用 setCurrentTime
function audio.rewindMusic()
    if DEBUG > 1 then
        printf("[audioNew] rewindMusic()")
    end
   print("\n********** \n audio.rewindMusic was deprecated please use audio.setCurrentTime instead.\n**********")
end


function audio.stopMusic(audioID)

    if not audioID then
        printError("audioNew.stopMusic() - invalid audioID")
        return
    end

    if DEBUG > 1 then
        printf("[audioNew] stopMusic() - audioID: %d", checkint(audioID))
    end

    if audioID then
        engine:stop(audioID)
        audio.__removeFromAudioMap(audioID)
    end
end


function audio.pauseMusic(audioID)
     if not audioID then
        printError("audioNew.pauseMusic() - invalid audioID")
        return
    end

    if DEBUG > 1 then
        printf("[audioNew] pauseMusic() - audioID: %d", checkint(audioID))
    end


    if __audioMap[audioID] then
        engine:pause(checkint(audioID))
    end
end

function audio.resumeMusic(audioID)
    if not audioID then
        printError("audioNew.resumeMusic() - invalid audioID")
        return
    end

    if DEBUG > 1 then
        printf("[audioNew] resumeMusic() - audioID: %d", checkint(audioID))
    end

    if __audioMap[audioID] then
        engine:resume(checkint(audioID))
    end
end


function audio.stopAllMusic()
    if DEBUG > 1 then
        printf("[audioNew] stopAllMusic()")
    end

    for k,v in pairs(__audioMap) do
        if v.atype == "music" then
            engine:stop(checkint(k))
            __audioMap[k] = nil
        end
    end
end

function audio.pauseAllMusic( ... )
    if DEBUG > 1 then
        printf("[audioNew] pauseAllMusic()")
    end
    for k,v in pairs(__audioMap) do
        if v.atype == "music" then
            engine:pause(checkint(k))
        end
    end
end

function audio.resumeAllMusic( ... )
    if DEBUG > 1 then
        printf("[audioNew] resumeAllMusic()")
    end

    for k,v in pairs(__audioMap) do
        if v.atype == "music" then
            engine:resume(checkint(k))
        end
    end
end

function audio.setMusicVolume(volume,audioID)
    volume = checknumber(volume)
    if audioID then
        if DEBUG > 1 then
            printf("[audioNew] setMusicVolume() - audioID:%d volume: %0.2f",audioID, checknumber(volume))
        end

        engine:setVolume(checkint(audioID),volume)
    else

        if DEBUG > 1 then
            printf("[audioNew] setMusicVolume() - volume: %0.2f", checknumber(volume))
        end

        __musicVolume = volume
        for k,v in pairs(__audioMap) do
            if v.atype == "music" then
                engine:setVolume(checkint(k),__musicVolume)
            end
        end
    end

end

function audio.getMusicVolume(audioID)
    if audioID then
        local volume = engine:getVolume(audioID)
         if DEBUG > 1 then
            printf("[audioNew] getMusicVolume() - audioID:%d volume: %0.2f", audioID,checknumber(volume))
        end

        if volume then
            return volume
        end
        return 0
    else
        if DEBUG > 1 then
            printf("[audioNew] getSoundsVolume() - volume: %0.2f", checknumber(__musicVolume))
        end

        return __musicVolume
    end
end



function audio.preloadSound(filename,callback)
    audio.preload(filename,callback)
end

function audio.unloadSound(filename)
    audio.unload(filename)
end

function audio.unloadAllSound()
    for k,v in pairs(__audioMap) do
        if v.atype == "sound" and v.path then
            audio.unload(v.path)
        end
    end
end


function audio.playSound(filename,loop,volume,callback)
    if not filename then
        printError("audioNew.playSound() - invalid filename")
        return
    end
    if type(loop) ~= "boolean" then loop = false end

    if DEBUG > 1 then
        printf("[audioNew] playSound() - filename: %s, loop: %s", tostring(filename), tostring(loop))
    end


    volume = volume or __soundVolume
    local audioID = engine:play2d(filename, loop,volume)
    audio.__addToAudioMap(audioID,filename,loop,volume,callback,"sound")
    if callback then
        audio.__addFinishCallback(audioID)
    end
    return audioID
end

function audio.getSoundsVolume(audioID)
    if audioID then
        local volume = engine:getVolume(audioID)

        if DEBUG > 1 then
            printf("[audioNew] getSoundsVolume() - audioID:%d volume: %0.2f", audioID,checknumber(volume))
        end

        if volume then
            return volume
        end
        return 0
    else
        if DEBUG > 1 then
            printf("[audioNew] getSoundsVolume() - volume: %0.2f", checknumber(__soundVolume))
        end

        return __soundVolume
    end
end


function audio.stopSound(audioID)
    if not audioID then
        printError("audioNew.stopSound() - invalid audioID")
        return
    end

    if DEBUG > 1 then
        printf("[audioNew] stopSound() - audioID: %d", checkint(audioID))
    end

    if audioID then
        engine:stop(audioID)
        audio.__removeFromAudioMap(audioID)   
    end
end

function audio.stopAllSounds()

    if DEBUG > 1 then
        printf("[audioNew] stopAllSounds()")
    end

    for k,v in pairs(__audioMap) do
        if v.atype == "sound" then
            engine:stop(checkint(k))
            __audioMap[k] = nil
        end
    end
end

function audio.pauseSound(audioID)
    if not audioID then
        printError("audioNew.pauseSound() - invalid audioID")
        return
    end

    if __audioMap[audioID] then
        engine:pause(checkint(audioID))
    end
end

function audio.resumeSound(audioID)
    if not audioID then
        printError("audioNew.resumeSound() - invalid audioID")
        return
    end

    if __audioMap[audioID] then
        engine:resume(checkint(audioID))
    end
end

function audio.pauseAllSounds( ... )
    if DEBUG > 1 then
        printf("[audioNew] pauseAllSounds()")
    end

    for k,v in pairs(__audioMap) do
        if v.atype == "sound" then
            engine:pause(checkint(k))
        end
    end
end

function audio.resumeAllSounds( ... )
     if DEBUG > 1 then
        printf("[audioNew] resumeAllSounds()")
    end

    for k,v in pairs(__audioMap) do
        if v.atype == "sound" then
            engine:resume(checkint(k))
        end
    end
end



--音效
function audio.setSoundsVolume(volume,audioID)
    volume = checknumber(volume)
    if audioID then
        if DEBUG > 1 then
            printf("[audioNew] setSoundsVolume() - audioID%d volume: %0.1f", audioID,checknumber(volume))
        end

        engine:setVolume(checkint(audioID),volume)
    else
        if DEBUG > 1 then
            printf("[audioNew] setSoundsVolume() - volume: %0.1f",checknumber(volume))
        end
        __soundVolume = volume
        for k,v in pairs(__audioMap) do
            if v.atype == "sound" then
                engine:setVolume(checkint(k),__soundVolume)
            end
        end
    end
end

return audio