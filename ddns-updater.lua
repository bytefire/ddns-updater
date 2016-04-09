local https = require 'ssl.https'
local http = require 'socket.http'

http.USERAGENT="ddns-updater/0.1 okash.khawaja@gmail.com"

-- values plugged in the URL below must be URL-encoded
local response, code, headers, status = https.request(
	"https://username:password@dynupdate.no-ip.com/nic/update?
				hostname=dnsname.net&myip=127.0.0.1")
print(response, status)

