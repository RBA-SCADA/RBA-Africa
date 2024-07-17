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
local datw = os.date ("%u")
--print("datw=", datw)

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

function FAULTINV(dev, ...)
 local result = 0
 local value = 0
 for i,v in ipairs(arg) do
  --value = (WR.read(dev, v))
  value = v
  if is_nan(value) then value = 1 end
  if (value == 1) then
   value = 0
  else
   value = 1
  end
  result = result + value
 end
 if result > 0 then result = 1 else result = nil end
 return result
 --WR.setProp(dev, fault, result)
end

function FAULT(dev, ...)
 local result = 0
 local value = 0
 for i,v in ipairs(arg) do
  --value = WR.read(dev, v)
  value = v
  if is_nan(value) then value = 0 end
  result = result + value
 end
 if result > 0 then result = 1 end
 return result
 --WR.setProp(dev, fault, result)
end

function SET_DO(dev, readDp, bitPos)
 local valueRead = WR.read(dev, readDp)
 local valueWrite = string.format("%04X", (bit.bor(valueRead, (2 ^ bitPos))))
 WR.writeHex(dev, readDp, valueWrite)
end

function RESET_DO(dev, readDp, bitPos)
 local valueRead = WR.read(dev, readDp)
 local valueWrite = string.format("%04X", (bit.band(valueRead, bit.bnot((2 ^ bitPos)))))
 WR.writeHex(dev, readDp, valueWrite)
end

------------------------- Read Function End -----------------------------------

------------------------ Read Setpoints Start ---------------------------------

if not(settings) then
 --print ("Inside file loading")
 settingsConfig = assert(io.open("/opt/iplon/jffs2/solar/modbus/Settings.txt", "r"))
 settingsJson = settingsConfig:read("*all")
 settings = cjson.decode(settingsJson)
 settingsConfig:close()
end


 CHECKDATATIME(dev, now, "COMMUNICATION_DAY_ONLINE")
 CHECKDATATIME(dev, now, "COMMUNICATION_DAY_OFFLINE")


--print ("roomHighTempSetpoint = ", settings.IO.roomHighTempSetpoint)
--print ("otiHighTempSetpoint = ", settings.IO.otiHighTempSetpoint)
--print ("wtiHighTempSetpoint = ", settings.IO.wtiHighTempSetpoint)
--print ("interconnectingVCB = ", settings.IO.interconnectingVCB)
--print ("DOAlarmSetpoint = ", settings.IO.DOAlarmSetpoint)

------------------------ Read Setpoints End -----------------------------------

------------------------ Read Required Data Start -----------------------------

local radiation = WR.read(dev, "RADIATION")

--------------------- Read Required Datapoints Start --------------------------

------------------------ Read Status of DI & DO -------------------------------

commStatus = commStatus or {}
commStatus[dev] = commStatus[dev] or {DayOn=WR.read(dev, "COMMUNICATION_DAY_ONLINE"), DayOff=WR.read(dev, "COMMUNICATION_DAY_OFFLINE"), HourOn=0, HourOff=0, ts=now}
if is_nan(commStatus[dev].DayOn) then commStatus[dev].DayOn = 0 end
if is_nan(commStatus[dev].DayOff) then commStatus[dev].DayOff = 0 end
local cb1Cf = WR.read(dev, "INR_CB1_CF")                  --cb1 off status
local cb1Of = WR.read(dev, "INR_CB1_OF")                  --cb1 on status
local cb2Cf = WR.read(dev, "INR_CB2_CF")                  --cb2 off status
local cb2Of = WR.read(dev, "INR_CB2_OF")                  --cb2 on status
local cb3Cf = WR.read(dev, "INR_CB3_CF")                  --cb3 off status
local cb3Of = WR.read(dev, "INR_CB3_OF")                  --cb3 on status
local cb4Cf = WR.read(dev, "INR_CB4_CF")                  --cb4 off status
local cb4Of = WR.read(dev, "INR_CB4_OF")                  --cb4 on status

local cbRm = WR.read(dev, "CB_RM")
if (cbRm == 1) then
 WR.setProp(dev, "CB_LM", 0)
elseif (cbRm == 0) then
 WR.setProp(dev, "CB_LM", 1)
end
local cbLm = WR.read(dev, "CB_LM")

-------------------------- Read Analog Values--------------------------------


------------------------- Read_Scada_Overrides --------------------------------


local cb1Cmd = WR.read(dev, "CB1_CMD")                  --cb1-
local cb1Src = WR.read(dev, "CB1_SRC")                  --cb1-
local cb2Cmd = WR.read(dev, "CB2_CMD")                  --cb2-
local cb2Src = WR.read(dev, "CB2_SRC")                  --cb2-
local cb3Cmd = WR.read(dev, "CB3_CMD")                  --cb3-
local cb3Src = WR.read(dev, "CB3_SRC")                  --cb3-
local cb4Cmd = WR.read(dev, "CB4_CMD")                  --cb4-
local cb4Src = WR.read(dev, "CB4_SRC")                  --cb4-

local dg01pac = WR.read(dev, "DG01_PAC")
local dg02pac = WR.read(dev, "DG02_PAC")
--local zeuac1 = WR.read(dev, "ZE_UAC1")
local iMc1Status = WR.read(dev, "COMMUNICATION_STATUS_INV01")
local iMc2Status = WR.read(dev, "COMMUNICATION_STATUS_INV02")
local iMc3Status = WR.read(dev, "COMMUNICATION_STATUS_INV03")
local iMc4Status = WR.read(dev, "COMMUNICATION_STATUS_INV04")
local iMc5Status = WR.read(dev, "COMMUNICATION_STATUS_INV05")
local iMc6Status = WR.read(dev, "COMMUNICATION_STATUS_INV06")
local iMc7Status = WR.read(dev, "COMMUNICATION_STATUS_INV07")
local iMc8Status = WR.read(dev, "COMMUNICATION_STATUS_INV08")
local iMc9Status = WR.read(dev, "COMMUNICATION_STATUS_INV09")
local iMc10Status = WR.read(dev, "COMMUNICATION_STATUS_INV10")
local iMc11Status = WR.read(dev, "COMMUNICATION_STATUS_INV11")
local iMc12Status = WR.read(dev, "COMMUNICATION_STATUS_INV12")
local iMc13Status = WR.read(dev, "COMMUNICATION_STATUS_INV13")
local iMc14Status = WR.read(dev, "COMMUNICATION_STATUS_INV14")
local iMc15Status = WR.read(dev, "COMMUNICATION_STATUS_INV15")
local iMc16Status = WR.read(dev, "COMMUNICATION_STATUS_INV16")
local iMc17Status = WR.read(dev, "COMMUNICATION_STATUS_INV17")

if is_nan(cb1Cmd) then cb1Cmd = 3 end
if is_nan(cb1Src) then cb1Src = 0 end
if is_nan(cb2Cmd) then cb2Cmd = 3 end
if is_nan(cb2Src) then cb2Src = 0 end
if is_nan(cb3Cmd) then cb3Cmd = 3 end
if is_nan(cb3Src) then cb3Src = 0 end
if is_nan(cb4Cmd) then cb4Cmd = 3 end
if is_nan(cb4Src) then cb4Src = 0 end

WR.setProp(dev, "CB1_CMD",     cb1Cmd)
WR.setProp(dev, "CB1_SRC",     cb1Src)
WR.setProp(dev, "CB2_CMD",     cb2Cmd)
WR.setProp(dev, "CB2_SRC",     cb2Src)
WR.setProp(dev, "CB3_CMD",     cb3Cmd)
WR.setProp(dev, "CB3_SRC",     cb3Src)
WR.setProp(dev, "CB4_CMD",     cb4Cmd)
WR.setProp(dev, "CB4_SRC",     cb4Src)



-------------------- Initialise Virtual Field End -----------------------------

------------------------ Read Required Data End -------------------------------

------------------------ Check Midnight Start ---------------------------------

checkMidnight = checkMidnight or {}
checkMidnight[dev] = checkMidnight[dev] or {ts=now}
if (os.date("*t", checkMidnight[dev].ts).hour > os.date("*t", now).hour) then
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

------------------------ Check Midnight End -----------------------------------

---------------------- COMMUNICATION STATUS Start -----------------------------

if WR.isOnline(dev) then
 WR.setProp(dev, "COMMUNICATION_STATUS", 0)
else
 WR.setProp(dev, "COMMUNICATION_STATUS", 1)
end

local commChannel = 0
for d in WR.devices() do
 --print("d = ",d)
 if not(WR.isOnline(d)) then
  commChannel = commChannel + 1
  if (commChannel > 1) then commChannel = 1 end
 end
 --print("commChannel = ",commChannel)
end
file = io.open("/ram/"..masterid..".temp","w+")
if file ~= nil then
 file:write(commChannel)
end
file:close()
os.remove("/ram/"..masterid.."")
os.rename("/ram/"..masterid..".temp","/ram/"..masterid.."")

if ((now-commStatus[dev].ts) >= 15) then
 --print("commStatus["..dev.."].commDayOnline = ", commStatus[dev].commDayOnline)
 --print("commStatus["..dev.."].commDayOffline = ", commStatus[dev].commDayOffline)
 --print("commStatus["..dev.."].commHourOnline = ", commStatus[dev].commHourOnline)
 --print("commStatus["..dev.."].commHourOffline = ", commStatus[dev].commHourOffline)
 --print("commStatus["..dev.."].ts = ", commStatus[dev].ts)
 if good then
  commStatus[dev].DayOn = commStatus[dev].DayOn + 1
  commStatus[dev].HourOn = commStatus[dev].HourOn + 1
 else
  commStatus[dev].DayOff = commStatus[dev].DayOff + 1
  commStatus[dev].HourOff = commStatus[dev].HourOff + 1
 end
 commStatus[dev].ts = now
 WR.setProp(dev, "COMMUNICATION_DAY_ONLINE", commStatus[dev].DayOn)
 WR.setProp(dev, "COMMUNICATION_DAY_OFFLINE", commStatus[dev].DayOff)
 WR.setProp(dev, "COMMUNICATION_DAY", (((commStatus[dev].DayOn) / (commStatus[dev].DayOn + commStatus[dev].DayOff)) * 100))
 WR.setProp(dev, "COMMUNICATION_HOUR", (((commStatus[dev].HourOn) / (commStatus[dev].HourOn + commStatus[dev].HourOff)) * 100))
end

---------------------- COMMUNICATION STATUS End -------------------------------


--------------------------- CB OC & CC Start ----------------------------------
--if (zeuac1 < 0 ) then
  if ((dg01pac < 0) or (dg02pac < 0)) then                                      -- if dg backfeed, iGate open cb
 if (cb1Cf == 1) then
  SET_DO(dev, ("DO"), 0)
  socket.sleep (.1)  -- sleep 100 milli seconds
  RESET_DO(dev, ("DO"), 0)
 else
  smokeReset = 0
 end
 WR.setProp(dev, "CB1_SRC",1)
 end
--end
if (cb1Cmd == 2) then                                                                  -- if scadacmd = 2 then open cb1
 if (cb1Cf == 1) then
  SET_DO(dev, ("DO"), 0)
  socket.sleep (.1)  -- sleep 100 milli seconds
  RESET_DO(dev, ("DO"), 0)
 else
  WR.setProp(dev, "CB1_CMD",3)
 end
 WR.setProp(dev, "CB1_SRC",2)
elseif (cb1Cmd == 1) then                                                              -- if scadacmd = 1 then close cb1
 if (cb1Cf == 0) then
  SET_DO(dev, ("DO"), 1)
  socket.sleep (.1)  -- sleep 100 milli seconds
  RESET_DO(dev, ("DO"), 1)
 else
  WR.setProp(dev, "CB1_CMD",3)
 end
 WR.setProp(dev, "CB1_SRC",2)
  end

if (cb2Cmd == 2) then                                                                  -- if scadacmd = 2 then open cb2
 if (cb2Cf == 1) then
  SET_DO(dev, ("DO"), 2)
  socket.sleep (.1)  -- sleep 100 milli seconds
  RESET_DO(dev, ("DO"), 2)
 else
  WR.setProp(dev, "CB2_CMD",3)
 end
 WR.setProp(dev, "CB2_SRC",2)
elseif (cb2Cmd == 1) then                                                              -- if scadacmd = 1 then close cb2
 if (cb2Cf == 0) then
  SET_DO(dev, ("DO"), 3)
  socket.sleep (.1)  -- sleep 100 milli seconds
  RESET_DO(dev, ("DO"), 3)
 else
  WR.setProp(dev, "CB2_CMD",3)
 end
 WR.setProp(dev, "CB2_SRC",2)
end  

if (cb3Cmd == 2) then                                                                  -- if scadacmd = 2 then open cb3
 if (cb3Cf == 1) then
  SET_DO(dev, ("DO"), 4)
  socket.sleep (.1)  -- sleep 100 milli seconds
  RESET_DO(dev, ("DO"), 4)
 else
  WR.setProp(dev, "CB3_CMD",3)
 end
 WR.setProp(dev, "CB3_SRC",2)
elseif (cb3Cmd == 1) then                                                              -- if scadacmd = 1 then close cb3
 if (cb3Cf == 0) then
  SET_DO(dev, ("DO"), 5)
  socket.sleep (.1)  -- sleep 100 milli seconds
  RESET_DO(dev, ("DO"), 5)
 else
  WR.setProp(dev, "CB3_CMD",3)
 end
 WR.setProp(dev, "CB3_SRC",2)
end  

if (cb4Cmd == 2) then                                                                  -- if scadacmd = 2 then open cb3
 if (cb4Cf == 1) then
  SET_DO(dev, ("DO"), 6)
  socket.sleep (.1)  -- sleep 100 milli seconds
  RESET_DO(dev, ("DO"), 6)
 else
  WR.setProp(dev, "CB4_CMD",3)
 end
 WR.setProp(dev, "CB4_SRC",2)
elseif (cb4Cmd == 1) then                                                              -- if scadacmd = 1 then close cb3
 if (cb4Cf == 0) then
  SET_DO(dev, ("DO"), 7)
  socket.sleep (.1)  -- sleep 100 milli seconds
  RESET_DO(dev, ("DO"), 7)
 else
  WR.setProp(dev, "CB4_CMD",3)
 end
 WR.setProp(dev, "CB4_SRC",2)
end 

--------------------------- CB OC & CC End ------------------------------------


