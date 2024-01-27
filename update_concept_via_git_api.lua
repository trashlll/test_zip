script_version("0.26") 
local hash = require("updater.hash")
local effil = require 'effil'
local lfs = require("lfs")

local script_autoupd = {
    gitapi_url = "",
    update_status = nil
}

local function async_http_request(method, url, args, resolve, reject)
    local request_thread = effil.thread(function (method, url, args)
       local requests = require 'requests'
       local result, response = pcall(requests.request, method, url, args)
       if result then
          response.json, response.xml = nil, nil
          return true, response
       else
          return false, response
       end
    end)(method, url, args)
    if not resolve then resolve = function() end end
    if not reject then reject = function() end end
    lua_thread.create(function()
        local runner = request_thread
        while true do
            local status, err = runner:status()
            if not err then
                if status == 'completed' then
                    local result, response = runner:get()
                    if result then
                       resolve(response)
                    else
                       reject(response)
                    end
                    return
                elseif status == 'canceled' then
                    return reject(status)
                end
            else
                return reject(err)
            end
            wait(0)
        end
    end)
end
function download_file(url, path, filename, callback)
    local success = false
    local content
    asyncHttpRequest('GET', url, nil, function(response)
        content = response.text
        success = true
    end, function(error)
        print(string.format("Error: %s", error))
        callback(true)
    end)

    while not success do
        wait(0)
    end

    local file = io.open(path, "wb")
    if file then
        file:write(content)
        file:close()
        -- sampAddChatMessage(" {b8b8b8}" .. filename .. " {dd99ff}успешно загружен!", -1)
        process_archive()
        callback(true)
    else
        -- sampAddChatMessage(" {b8b8b8}" .. filename .. " {dd99ff}ошибка при записи файла!", -1)
        callback(true)
    end
end
function update_my_script(url)
    async_http_request('GET', url, nil, function(response)
        local json_data = decodeJson(response.text)
        if json_data then
            for _, data in ipairs(json_data) do
                local sha_local = hash.gen_sha(thisScript().path)
                if data.name ==thisScript().name and data.sha ~= sha_local then
                    download_file(data.download_url, thisScript().path, filename, function(success)
                        script_autoupd.update_status = true
                        return
                    end)
                end
            end
        else
            script_autoupd.update_status = false
            return false
        end
    end, function(error)
        print(string.format("Error: %s", error))
    end)
end

function update_handler(url)
    update_my_script(url)
    lua_thread.create(function ()
        repeat
            wait(100)
        until script_autoupd.update_status ~= nil
        if script_autoupd.update_status then
            sampAddChatMessage('Скрипт '..thisScript().name.. ' обновлен! Текущая версия: '..thisScript().version, -1)
        else
            sampAddChatMessage('Возникла ошибка при обновлении '..thisScript().name.. '! Текущая версия: '..thisScript().version, -1)
        end
    end)
end

function main()
    while not isSampAvailable() do wait(0) end
        
    while true do
        wait(0)
        
    end
end