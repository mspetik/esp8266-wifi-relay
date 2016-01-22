--Modified by Andy Reischle Based on XChip's NodeMCU IDE
tmr.delay(1000)
wifi.setmode(wifi.SOFTAP)
cfg={}
cfg.ssid="RelaySetup"
wifi.ap.config(cfg)
dofile ("dns-liar.lua")

srv=net.createServer(net.TCP) 
srv:listen(80, function(conn) 

   local rnrn=0
   local Status = 0
   local responseBytes = 0
   local method=""
   local url=""
   local vars=""

   conn:on("receive",function(conn, payload)
  
    if Status==0 then
        _, _, method, url, vars = string.find(payload, "([A-Z]+) /([^?]*)%??(.*) HTTP")
        -- print(method, url, vars)                          
    end
    if vars~=nil and parse_wifi_credentials(vars) then
        node.restart()
    end

    if url == "favicon.ico" then
        conn:send("HTTP/1.1 404 file not found")
        responseBytes = -1
        return
    end    

    -- Only support one sending one file
    url="set.html"
    responseBytes = 0
    
    conn:send("HTTP/1.1 200 OK\r\n\r\n")
    
  end)
  
  conn:on("sent",function(conn) 
    if responseBytes>=0 and method=="GET" then
        if file.open(url, "r") then            
            file.seek("set", responseBytes)
            local line=file.read(512)
            file.close()
            if line then
                conn:send(line)
                responseBytes = responseBytes + 512    

                if (string.len(line)==512) then
                    return
                end
            end
        end        
    end

    conn:close() 
  end)
end)
print("HTTP Server: Started")


function parse_wifi_credentials(vars)
    if vars == nil or vars == "" then
        return false
    end

    local _, _, wifi_ssid = string.find(vars, "ssid\=([^&]+)")
    local _, _, wifi_password = string.find(vars, "pwd\=([^&]+)")

    if wifi_ssid == nil or wifi_ssid == "" or wifi_password == nil then
        return false
    end

    pwd_len = string.len(wifi_password)
    if pwd_len ~= 0 and (pwd_len < 8 or pwd_len > 64) then
        print("Password length should be between 8 and 64 characters")
        return false
    end

    print("Neue WiFi Zugangsdaten erhalten")
    print("-----------------------------")
    print("wifi_ssid     : " .. wifi_ssid)
    print("wifi_password : " .. wifi_password)
      wifi.setmode(wifi.STATION)
      wifi.sta.config(wifi_ssid,wifi_password)
      wifi.sta.connect()
     
    return true
end