local dev, good = ...

--print(dev)

devS = string.sub(dev, 4, -1)
--print("devS = ", devS)

require ("socket")
local now = socket.gettime()
local date = os.date("*t")
local hour = date.hour
local min = date.min
local sec = date.sec


------------------------ Read Required Data Start -----------------------------

local ze1_pac = WR.read("SN:ZE_EM01", "PAC")
local ze2_pac = WR.read("SN:ZE_EM02", "PAC")
local totalzepac = (ze1_pac + ze2_pac)
WR.setProp(dev, "TOTAL_ZE_PAC", totalzepac)
local number = 0
if ze1_pac > 1 then number = number + 1 end
if ze2_pac > 1 then number = number + 1 end
local totalzeonline = number
WR.setProp(dev, "TOTAL_ZE_ONLINE", totalzeonline)

------------------------ Read Required Data End ------------------------------]]--

------------------------- Read Function Start ---------------------------------

function CHECKDATATIME(dev, now, field)
 local midNight = (now - ((hour * 60 * 60) + (min * 60) + sec))
 local dataTime = WR.ts(dev, field)
 if (dataTime < midNight) then
  WR.setProp(dev, field, 0)
 else
  local data = WR.read(dev, field)
  WR.setProp(dev, field, data)
 end
end

------------------------- Read Function End -----------------------------------

if not(settings) then
 --print ("Inside file loading")
 settingsConfig = assert(io.open("/mnt/jffs2/solar/modbus/Settings.txt", "r"))
 settingsJson = settingsConfig:read("*all")
 settings = cjson.decode(settingsJson)
 settingsConfig:close()

 CHECKDATATIME(dev, now, "START_TIME")
 CHECKDATATIME(dev, now, "STOP_TIME")
 CHECKDATATIME(dev, now, "OPERATIONAL_TIME")
end

------------------------ Read Required Data Start -----------------------------

commStatus = commStatus or {}
commStatus[dev] = commStatus[dev] or {DayOn=WR.read(dev, "COMMUNICATION_DAY_ONLINE"), DayOff=WR.read(dev, "COMMUNICATION_DAY_OFFLINE"), HourOn=0, HourOff=0, ts=now}
if is_nan(commStatus[dev].DayOn) then commStatus[dev].DayOn = 0 end
if is_nan(commStatus[dev].DayOff) then commStatus[dev].DayOff = 0 end
local iac1 = WR.read(dev, "IAC1")
startTime = startTime or {}
startTime[dev] = startTime[dev] or {ts=WR.read(dev, "START_TIME")}
if is_nan(startTime[dev].ts) then startTime[dev].ts = 0 end
stopTime = stopTime or {}
stopTime[dev] = stopTime[dev] or {ts=WR.read(dev, "STOP_TIME"), againStart=0}
if is_nan(stopTime[dev].ts) then stopTime[dev].ts = 0 end
if is_nan(stopTime[dev].againStart) then stopTime[dev].againStart = 0 end
gridAvailability = gridAvailability or {}
gridAvailability[dev] = gridAvailability[dev] or {ts=now, tson=WR.read(dev, "GRID_ON"), tsoff=WR.read(dev, "GRID_OFF")}
if is_nan(gridAvailability[dev].tson) then gridAvailability[dev].tson = 0 end
if is_nan(gridAvailability[dev].tsoff) then gridAvailability[dev].tsoff = 0 end
opTime = opTime or {}
opTime[dev] = opTime[dev] or {ts=now, tson=WR.read(dev, "OPERATIONAL_TIME")}
if is_nan(opTime[dev].tson) then opTime[dev].tson = 0 end


---------------------- COMMUNICATION STATUS Start -----------------------------

if WR.isOnline(dev) then
 WR.setProp(dev, "COMMUNICATION_STATUS", 0)
else
 WR.setProp(dev, "COMMUNICATION_STATUS", 1)
end

---------------------- COMMUNICATION STATUS End -------------------------------


--------------------- Plant Operational Time Calculation Start ----------------

if (iac1 > 1) then
 opTime[dev].tson = opTime[dev].tson + (now - opTime[dev].ts)
 if (startTime[dev].ts == 0) then
  startTime[dev].ts = ((hour * 60 * 60) + (min * 60) + sec)
 end
 stopTime[dev].againStart = 1
elseif ((iac1 <= 2) and  (startTime[dev].ts ~= 0) and ((stopTime[dev].againStart == 1) or (stopTime[dev].ts == 0))) then
 stopTime[dev].ts = ((hour * 60 * 60) + (min * 60) + sec)
 stopTime[dev].againStart = 0
end
opTime[dev].ts = now
WR.setProp(dev, "START_TIME", startTime[dev].ts)
WR.setProp(dev, "STOP_TIME", stopTime[dev].ts)
WR.setProp(dev, "OPERATIONAL_TIME", opTime[dev].tson)
local operationaltime = WR.read(dev, "OPERATIONAL_TIME")
WR.setProp(dev, "OPERATIONAL_HOUR", (operationaltime/3600))

--------------------- Plant Operational Time Calculation End ------------------

checkMidnight = checkMidnight or {}
checkMidnight[dev] = checkMidnight[dev] or {ts=now}
if (os.date("*t", checkMidnight[dev].ts).hour > os.date("*t", now).hour) then
 startTime[dev].ts = 0
 stopTime[dev].ts = 0
 gridAvailability[dev].tson = 0
 gridAvailability[dev].tsoff = 0
 opTime[dev].tson = 0
 pacOld = 0
 prDay = 0
 prMin = 0
 commStatus[dev].HourOn = 0
 commStatus[dev].HourOff = 0
 commStatus[dev].DayOn = 0
 commStatus[dev].DayOff = 0
end
if (os.date("*t", checkMidnight[dev].ts).hour < os.date("*t", now).hour) then
 commStatus[dev].HourOn = 0
 commStatus[dev].HourOff = 0
end
checkMidnight[dev].ts = now

--if ((os.date("*t", now).hour == 23) and (os.date("*t", now).min > 55)) then
if (((os.date("*t", now).hour == 23) and (os.date("*t", now).min > 55)) or ((os.date("*t", now).hour == 0) and (os.date("*t", now).min < 01))) then
 WR.setProp(dev, "START_TIME", 0)
 WR.setProp(dev, "STOP_TIME", 0)
 WR.setProp(dev, "OPERATIONAL_TIME", 0)
 WR.setProp(dev, "OPERATIONAL_HOUR", 0)
end

------------------------ Check Midnight End -----------------------------------


