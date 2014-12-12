#!/usr/bin/lua
-- ------------------------------------------------------------------------- --
-- domoWRT.lua
-- ~~~~~~~~~~~~~~
-- - On failure, automatically reconnect to MQTT server.
-- ------------------------------------------------------------------------- --

function is_openwrt()
  return(os.getenv("USER") == "root")  -- Assume logged in as "root" on OpenWRT
end



-- ------------------------------------------------------------------------- --

if (not is_openwrt()) then require("luarocks.require") end
local lapp = require("pl.lapp")

local args = lapp [[
  Subscribe to topic1 and publish all messages on topic2
  -H,--host   (default mqtt)   MQTT server hostname
  -n,--name   (default ArDomo14)     MQTT client identifier
  -p,--port   (default 1883)        MQTT server port number
  -s,--sleep  (default 1.0)         Sleep time between commands
]]



require ("gpio")
local MQTT = require("mqtt")

local mqtt_client = MQTT.client.create(args.host, args.port)

-- ------------------------------------------------------------------------- --
function getUnixTimestamp()
  return string.format("%.0f000", socket.gettime())
end


function log(level, message)
  local logMsg = string.format("{\"node\":\"" .. args.name .. "\",\"level\":\"" .. level .. "\",\"date\":" .. dateString() .. "\"msg\":\"" .. message .. "\"}")
  mqtt_client:publish("/home_dev/log/" .. args.name, logMsg, 1);             
end



function dateString()
-- 2014-12-05T08:15:14.688Z
-- TODO : use GMT time
  return os.date("%Y-%m-%dT%H:%M:%S.000Z")
end

mqtt_client:connect(args.name, "/home_dev/nodes/" .. args.name .. "/alive", 0, 1, "0")                                                                                                                                                      

local error_message = nil                                                                                                                                                                                                                 
local index = 1                                                                                                                                                                                                                           
local messages = { "[GATE OPEN]", "[GATE CLOSED]", "[GATE MOVING]" }                                                                                                                                                                                      
local currentState = -1; -- 0 closed - 1 open - 2 moving

mqtt_client:publish("/home_dev/nodes/" .. args.name .. "/alive", "1", 1);             
mqtt_client:publish("/home_dev/nodes/" .. args.name .. "/alive/lastupdate", getUnixTimestamp());
log("info", args.name .. " started")
configureInGPIO(0) -- closed 
-- WARNING : don't use this GPIO for now : need more infos
configureInGPIO(1) -- open 
while (error_message == nil) do
--  mqtt_client:publish("/home_dev/nodes/" .. args.name .. "/sensors/TESTSENSOR/value", messages[index],1);                                                                                                                                    
--  mqtt_client:publish("/home_dev/nodes/" .. args.name .. "/sensors/TESTSENSOR/value/lastupdate", getUnixTimestamp());  

--  index = index + 1
--  if (index > #messages) then index = 1 end
  local now = getUnixTimestamp()
  local valClosed = readGPIO(0) --read the value of the pin
  mqtt_client:publish("/home_dev/nodes/" .. args.name .. "/sensors/CLOSED/value", valClosed,1);
  mqtt_client:publish("/home_dev/nodes/" .. args.name .. "/sensors/CLOSED/value/lastupdate", now);
  local valOpen = readGPIO(1) --read the value of the pin
  mqtt_client:publish("/home_dev/nodes/" .. args.name .. "/sensors/OPEN/value", valOpen,1);
  mqtt_client:publish("/home_dev/nodes/" .. args.name .. "/sensors/OPEN/value/lastupdate", now);

  if (valClosed == 1 and valOpen == 0 and currentState ~= 0) then
    currentState = 0
    mqtt_client:publish("/home_dev/events/GATE", "CLOSED",0);
    log("info", "Gate Closed")
  elseif (valClosed == 0 and valOpen == 1 and currentState ~= 1) then
    currentState = 1
    mqtt_client:publish("/home_dev/events/GATE", "OPEN",0);
    log("info", "Gate Open")
  elseif (valClosed == 0 and valOpen == 0 and currentState ~= 2) then
    currentState = 2
    mqtt_client:publish("/home_dev/events/GATE", "MOVING",0);
    log("info", "Gate Moving")
  end
  error_message = mqtt_client:handler()
  socket.sleep(args.sleep)  -- seconds
end

if (error_message == nil) then
  mqtt_client:destroy()
else
  print(error_message)
end






-- ------------------------------------------------------------------------- --
