local https = require 'ssl.https'
local http = require 'socket.http'

-- config. following must be URL-encoded
local USERNAME = "username"
local PASSWORD = "password"
local HOSTNAME = "dnsname.net"

local RESPONSE_911 = "911"
local RETRY_SECONDS_911 = 30 * 60 -- wait at least 30 mins before retrying after receiving 911 from noip.com
local LAST_UPDATE_FILE_PATH = "last-update"
local EXTERNAL_IP_SERVER = "http://icanhazip.com/s"

http.USERAGENT="ddns-updater/0.1 okash.khawaja@gmail.com"

local function read_whole_file(path)
        local f = io.open(path, "r")
        if not f then
                return nil
        end

        local contents = f:read("*all")
        f:close()

        return contents
end

local function write_last_update(last_update)
        local str = last_update.time .. " " .. " " .. last_update.ip ..
                " " .. " " .. last_update.response
        local f = io.open(LAST_UPDATE_FILE_PATH, "w")
        f:write(str)
        f:close()
end

local function read_last_update()
        local last_update = {}
        local str = read_whole_file(LAST_UPDATE_FILE_PATH)

        if not str then
                last_update.time = 0
                last_update.ip = ""
                last_update.response = ""

                return last_update
        end

        -- time
        local start_index = 1
        local space_index = string.find(str, " ")
        last_update.time = tonumber(string.sub(str, start_index, space_index - 1))

	-- ip
        start_index = space_index + 1
        space_index = string.find(str, " ", start_index)
        last_update.ip = string.sub(str, start_index, space_index - 1)

        -- response
        last_update.response = string.sub(str, space_index + 1)

        return last_update
end

local function get_ip()
        local response, code = http.request(EXTERNAL_IP_SERVER)

        if tonumber(code) ~= 200 then
                return nil
        end

        return response:gsub("\r", ""):gsub("\n", "")
end


---- main ----

-- read last_update table (time, ip, response)
local last_update = read_last_update()
local current_ip = get_ip()

if last_update.ip == current_ip then
        return
end

local current_time = os.time()

if last_update.response == RESPONSE_911 and
        (current_time - last_update.time < RETRY_SECONDS_911) then
        return
end

-- if here then either we've waited long enough after receiving a 911
-- or we didn't need to wait. update ip in both cases

-- values plugged in the URL below must be URL-encoded
local response, code, headers, status = https.request(
	"https://" .. USERNAME .. ":" .. PASSWORD .. "@dynupdate.no-ip.com/
		nic/update?hostname=" .. HOSTNAME .. "&myip=" .. current_ip)

if tonumber(code) ~= 200 then
        return
end

local current_update = {}
if response == RESPONSE_911 then
        current_update.time = current_time
        current_update.ip = last_update.ip
        current_update.reponse = response
else
        current_update.time = current_time
        current_update.ip = current_ip
        current_update.response = response
end

write_last_update(current_update)
