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

------------------------ Read Setpoints Start ---------------------------------

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

function SUM(meter1, meter2, meter3, meter4, targetmeter, val, sumval)
 local value1 = WR.read(meter1, val)
 if is_nan(value1) then value1 = 0 end
 local value2 = WR.read(meter2, val)
 if is_nan(value2) then value2 = 0 end
 local value3 = WR.read(meter3, val)
 if is_nan(value3) then value3 = 0 end
 local value4 = WR.read(meter4, val)
 if is_nan(value4) then value4 = 0 end
 
 WR.setProp(targetmeter, sumval, value1+value2+value3+value4)
end

function AVG(meter1, meter2, meter3, meter4, targetmeter, val, avgval)
 local cnt = 4
 local value1 = WR.read(meter1, val)
 if is_nan(value1) then value1 = 0; cnt = cnt - 1 end
 local value2 = WR.read(meter2, val)
 if is_nan(value2) then value2 = 0; cnt = cnt - 1 end
 local value3 = WR.read(meter3, val)
 if is_nan(value1) then value3 = 0; cnt = cnt - 1 end
 local value4 = WR.read(meter4, val)
 if is_nan(value2) then value4 = 0; cnt = cnt - 1 end
 

 if cnt > 0 then
  WR.setProp(targetmeter, avgval, (value1+value2+value3+value4)/cnt)
 end
end

------------------------- Read Function End -----------------------------------

if not(settings) then
 --print ("Inside file loading")
 settingsConfig = assert(io.open("/mnt/jffs2/solar/modbus/Settings.txt", "r"))
 settingsJson = settingsConfig:read("*all")
 settings = cjson.decode(settingsJson)
 settingsConfig:close()
end

if not(settings.EM[devS].dcCapacity and settings.EM[devS].prRealRadSetpoint) then
 --print ("Data loading")
 settings.EM[devS].dcCapacity = settings.EM[devS].dcCapacity or settings.EM.dcCapacity or 198.0
 settings.EM[devS].prRealRadSetpoint = settings.EM[devS].prRealRadSetpoint or settings.EM.prRealRadSetpoint or 250.0

 CHECKDATATIME(dev, now, "EXP_GEN_CUM_1")
 CHECKDATATIME(dev, now, "EXP_GEN_CUM_2")
 CHECKDATATIME(dev, now, "GEN_LOSS_CUM")
 CHECKDATATIME(dev, now, "EAE_DAY_NO_RAD")
 CHECKDATATIME(dev, now, "START_TIME")
 CHECKDATATIME(dev, now, "STOP_TIME")
 CHECKDATATIME(dev, now, "OPERATIONAL_TIME")
 CHECKDATATIME(dev, now, "PR_DAY")
end

--print ("dcCapacity = ", settings.BLOCK.dcCapacity)

------------------------ Read Setpoints End -----------------------------------

------------------------ Read Required Data Start -----------------------------

local pacAct = WR.read(dev, "PAC")
local paclimit = WR.read(dev, "PAC_LIMIT")
local eaeDay = WR.read(dev, "EAE_DAY")
local dg01Pac = WR.read(dev, "DG1_PAC")
local dg02Pac = WR.read(dev, "DG2_PAC")
local radiation = WR.read(dev, "RADIATION")
local radiationCum = WR.read(dev, "SOLAR_RADIATION_CUM")
local pr = WR.read(dev, "PR")
local prDay = WR.read(dev, "PR_DAY")
local expGen1Now = 0
local expGen2Now = 0
local gridOut = 0

if is_nan(pac) then pac = 0 end
if is_nan(pr) then pr = 0 end
if is_nan(prDay) then prDay = 0 end
if is_nan(alphaFact) then alphaFact = 1 end
if is_nan(dg01Pac) then dg01Pac = 0 end
if is_nan(dg02Pac) then dg02Pac = 0 end


if devS=="EM01" then
 local deviceIn1 = "SN:EM01"
 local deviceIn2 = "SN:EM02"
 local deviceIn3 = "SN:EM03"
 local deviceIn4 = "SN:EM04"
 local deviceOut = "SN:EM01"
 SUM(deviceIn1, deviceIn2, deviceIn3, deviceIn4, deviceOut, "PAC",           "TOTAL_PAC")
 SUM(deviceIn1, deviceIn2, deviceIn3, deviceIn4, deviceOut, "PAC_LIMIT",     "TOTAL_PAC_LIMIT")
 SUM(deviceIn1, deviceIn2, deviceIn3, deviceIn4, deviceOut, "QAC",           "TOTAL_QAC")
 SUM(deviceIn1, deviceIn2, deviceIn3, deviceIn4, deviceOut, "SAC",           "TOTAL_SAC")
 AVG(deviceIn1, deviceIn2, deviceIn3, deviceIn4, deviceOut, "FAC",           "TOTAL_FAC")
 AVG(deviceIn1, deviceIn2, deviceIn3, deviceIn4, deviceOut, "UAC",           "TOTAL_UAC")
 SUM(deviceIn1, deviceIn2, deviceIn3, deviceIn4, deviceOut, "IAC",           "TOTAL_IAC")
 SUM(deviceIn1, deviceIn2, deviceIn3, deviceIn4, deviceOut, "EAE",           "TOTAL_EAE")
 SUM(deviceIn1, deviceIn2, deviceIn3, deviceIn4, deviceOut, "EAE_DAY",       "TOTAL_EAE_DAY")
 AVG(deviceIn1, deviceIn2, deviceIn3, deviceIn4, deviceOut, "PF",            "TOTAL_PF")
 SUM(deviceIn1, deviceIn2, deviceIn3, deviceIn4, deviceOut, "SPECIFIC_YIELD","TOTAL_SPECIFIC_YIELD")
end

commStatus = commStatus or {}
commStatus[dev] = commStatus[dev] or {DayOn=WR.read(dev, "COMMUNICATION_DAY_ONLINE"), DayOff=WR.read(dev, "COMMUNICATION_DAY_OFFLINE"), HourOn=0, HourOff=0, ts=now}
if is_nan(commStatus[dev].DayOn) then commStatus[dev].DayOn = 0 end
if is_nan(commStatus[dev].DayOff) then commStatus[dev].DayOff = 0 end
local pac = WR.read(dev, "PAC")
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

------------------------ Read Required Data End -------------------------------

---------------------- Plsnt Load Calculation start ----------------------------------

local pvPac = WR.read(dev, "TOTAL_PAC")
local pveaeDay = WR.read(dev, "TOTAL_EAE_DAY")
local pveae = WR.read(dev, "TOTAL_EAE")

local dg1Pac = WR.read(dev, "DG1_PAC")
local dg1eaeDay = WR.read(dev, "DG1_EAE_DAY")
local dg1eae = WR.read(dev, "DG1_EAE")
local dg2Pac = WR.read(dev, "DG2_PAC")
local dg2eaeDay = WR.read(dev, "DG2_EAE_DAY")
local dg2eae = WR.read(dev, "DG2_EAE")
local grid1Pac = WR.read(dev, "GRID1_PAC")
local grid1eaiDay = WR.read(dev, "GRID1_EAI_DAY")
local grid1eai = WR.read(dev, "GRID1_EAI")
local grid2Pac = WR.read(dev, "GRID2_PAC")
local grid2eaiDay = WR.read(dev, "GRID2_EAI_DAY")
local grid2eai = WR.read(dev, "GRID2_EAI")

if is_nan(pvPac) then pvPac = 0 end
if is_nan(pveaeDay) then pveaeDay = 0 end
if is_nan(pveae) then pveae = 0 end
if is_nan(dg1Pac) then dg1Pac = 0 end
if is_nan(dg1eaeDay) then dg1eaeDay = 0 end
if is_nan(dg1eae) then dg1eae = 0 end
if is_nan(dg2Pac) then dg2Pac = 0 end
if is_nan(dg2eaeDay) then dg2eaeDay = 0 end
if is_nan(dg2eae) then dg2eae = 0 end
if is_nan(grid1Pac) then grid1Pac = 0 end
if is_nan(grid1eaiDay) then grid1eaiDay = 0 end
if is_nan(grid1eai) then grid1eai = 0 end
if is_nan(grid2Pac) then grid2Pac = 0 end
if is_nan(grid2eaiDay) then grid2eaiDay = 0 end
if is_nan(grid2eai) then grid2eai = 0 end

local PlantLoad = pvPac + grid1Pac + grid2Pac + dg1Pac + dg2Pac
local PlantLoadDay = pveaeDay + dg1eaeDay + grid1eaiDay + dg2eaeDay + grid2eaiDay
local PlantLifetimeLoad = pveae + dg1eae + grid1eai + dg2eae + grid2eai

WR.setProp(dev, "PLANT_LOAD", PlantLoad)
WR.setProp(dev, "PLANT_LOAD_DAY", PlantLoadDay)
WR.setProp(dev, "PLANT_LIFETIME_LOAD", PlantLifetimeLoad)

---------------------- Plsnt Load Calculation start ----------------------------------

-------------------------Elite EAE Dip neglection-----------------------------

local eae = WR.read(dev, "EAE")
if eae > 0 then WR.setProp(dev, "EAE_DAY", eae) end

------------------------- Specific Yield Comparison of Inv Start -------------------------

local eaeDay = WR.read(dev, "EAE_DAY")
if is_nan(eaeDay) then eaeDay = 0 end
local Sy = WR.read(dev, "SPECIFIC_YIELD")
if is_nan(Sy) then Sy = 0 end

local invSyNow = ((eaeDay) / settings.EM[devS].dcCapacity)
if ((is_nan(invSyNow)) or (invSyNow < 0) or (invSyNow > 10)) then
 invSyNow = Sy
end
WR.setProp(dev, "SPECIFIC_YIELD", invSyNow)

------------------------- Specific Yield Comparison of Inv End --------------------------

--[[
------------------------ Check Midnight Start ---------------------------------

checkMidnight = checkMidnight or {}
checkMidnight[dev] = checkMidnight[dev] or {ts=now}
if (os.date("*t", checkMidnight[dev].ts).hour > os.date("*t", now).hour) then
 prDay = 0
end
checkMidnight[dev].ts = now

------------------------ Check Midnight End -----------------------------------
--]]

------------------------ Meter Calculation Start ------------------------------

local pac = WR.read(dev, "PAC")
local uac1 = WR.read(dev, "UAC1")
local uac2 = WR.read(dev, "UAC2")
local uac3 = WR.read(dev, "UAC3")
local uac12 = WR.read(dev, "UAC12")
local uac23 = WR.read(dev, "UAC23")
local uac31 = WR.read(dev, "UAC31")
local iac_1 = WR.read(dev, "IAC1")
local iac_2 = WR.read(dev, "IAC2")
local iac_3 = WR.read(dev, "IAC3")

if is_nan(uac1) then uac1 = 0 end
if is_nan(uac2) then uac2 = 0 end
if is_nan(uac3) then uac3 = 0 end
if is_nan(uac12) then uac12 = 0 end
if is_nan(uac23) then uac23 = 0 end
if is_nan(uac31) then uac31 = 0 end
if is_nan(iac_1) then iac_1 = 0 end
if is_nan(iac_2) then iac_2 = 0 end
if is_nan(iac_3) then iac_3 = 0 end

WR.setProp(dev, "UACLN", (uac1+uac2+uac3)/3)
WR.setProp(dev, "UAC", (uac12+uac23+uac31)/3)
WR.setProp(dev, "IAC", (iac_1+iac_2+iac_3))
local iac = WR.read(dev, "IAC")
if iac ~= 0 then WR.setProp(dev, "IAC_MAX", iac) end

------------------------ Meter Calculation End --------------------------------

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


--------------------- Plant Operational Time Calculation Start ----------------

local pac = WR.read(dev, "PAC")
if (pac > 1) then
 opTime[dev].tson = opTime[dev].tson + (now - opTime[dev].ts)
 if (startTime[dev].ts == 0) then
  startTime[dev].ts = ((hour * 60 * 60) + (min * 60) + sec)
 end
 stopTime[dev].againStart = 1
elseif ((pac <= 1) and  (startTime[dev].ts ~= 0) and ((stopTime[dev].againStart == 1) or (stopTime[dev].ts == 0))) then
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


------------------------ PR Calculation Start ---------------------------------

local prDayNow = ((((eaeDay) / settings.EM[devS].dcCapacity) / radiationCum)) * 100
if ((is_nan(prDayNow)) or (prDayNow < 0) or (prDayNow > 100)) then
 prDayNow = prDay
end
WR.setProp(dev, "PR_DAY", prDayNow)

if(radiation >= (settings.EM[devS].prRealRadSetpoint)) then   -- if 250 & ABOVE
 local prNow = ((((pac * 1000) / settings.EM[devS].dcCapacity) / radiation)) * 100
 if((is_nan(prNow)) or (prNow < 0) or (prNow > 100)) then
  prNow = pr
 end
 WR.setProp(dev, "PR", prNow)
else
 WR.setProp(dev, "PR", 0/0)
end

------------------------ PR Calculation End -----------------------------------

------------------------ GEN LOSS Calculation Start ---------------------------

eaeDayNoRad = eaeDayNoRad or {}
eaeDayNoRad[dev] = eaeDayNoRad[dev] or {day=WR.read(dev, "EAE_DAY_NO_RAD"), last=eaeDay}
if (is_nan(eaeDayNoRad[dev].day)) then eaeDayNoRad[dev].day = 0 end

if is_nan(radiation) then
 radiation = 0
 eaeDayNoRad[dev].day = eaeDayNoRad[dev].day + (eaeDay - eaeDayNoRad[dev].last)
end
eaeDayNoRad[dev].last = eaeDay
WR.setProp(dev, "EAE_DAY_NO_RAD", eaeDayNoRad[dev].day)

expGen1Now = ((((settings.EM[devS].dcCapacity * radiation) / 1000) * 0.8) * 1)
expGen1Cum = expGen1Cum or {}
expGen1Cum[dev] = expGen1Cum[dev] or {ts=now, day=WR.read(dev, "EXP_GEN_CUM_1")}
if (is_nan(expGen1Cum[dev].day)) then expGen1Cum[dev].day = 0 end

expGen1Cum[dev].day = expGen1Cum[dev].day + (((now-expGen1Cum[dev].ts) * expGen1Now) / (60 * 60))
expGen1Cum[dev].ts = now
WR.setProp(dev, "EXP_GEN_CUM_1", expGen1Cum[dev].day)
WR.setProp(dev, "EXP_GEN", expGen1Now)

expGen2Now = ((((settings.EM[devS].dcCapacity * radiation) / 1000) * 0.8) * 1)
expGen2Cum = expGen2Cum or {}
expGen2Cum[dev] = expGen2Cum[dev] or {ts=now, day=WR.read(dev, "EXP_GEN_CUM_2")}
if (is_nan(expGen2Cum[dev].day)) then expGen2Cum[dev].day = 0 end

genLossCum = genLossCum or {}
genLossCum[dev] = genLossCum[dev] or {ts=now, day=WR.read(dev, "GEN_LOSS_CUM")}
if (is_nan(genLossCum[dev].day)) then genLossCum[dev].day = 0 end

local expGen80 = 0
local genLoss = 0

local paclimit1 = WR.read(dev, "PAC_LIMIT1")
local paclimit2 = WR.read(dev, "PAC_LIMIT2")

if ((radiation > 25) and ((paclimit1 < 100) or (paclimit2 < 100))) then
 expGen80 = (((settings.EM[devS].dcCapacity * radiation) / 1000) * 0.8)
 genLoss = (expGen80 - pacAct)
 gridOut = 1
 if (genLoss < 0) then genLoss = 0 end

 genLossCum[dev].day = genLossCum[dev].day + (((now-genLossCum[dev].ts) * genLoss) / (60 * 60))

 expGen2Now = 0
end

genLossCum[dev].ts = now
WR.setProp(dev, "GEN_LOSS_CUM", genLossCum[dev].day)
WR.setProp(dev, "GEN_LOSS", genLoss)

expGen2Cum[dev].day = expGen2Cum[dev].day + (((now-expGen2Cum[dev].ts) * expGen2Now) / (60 * 60))
expGen2Cum[dev].ts = now
WR.setProp(dev, "EXP_GEN_CUM_2", expGen2Cum[dev].day)

------------------------ GEN LOSS Calculation End ---------------------------

------------------------ Check Midnight Start ---------------------------------

checkMidnight = checkMidnight or {}
checkMidnight[dev] = checkMidnight[dev] or {ts=now}
if (os.date("*t", checkMidnight[dev].ts).hour > os.date("*t", now).hour) then
 prDay = 0
 expGen1Cum[dev].day = 0
 expGen2Cum[dev].day = 0
 genLossCum[dev].day = 0
 eaeDayNoRad[dev].day = 0
 eaeDayNoRad[dev].last = 0
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
 WR.setProp(dev, "EXP_GEN_CUM_1", expGen1Cum[dev].day)
 WR.setProp(dev, "EXP_GEN_CUM_2", expGen2Cum[dev].day)
 WR.setProp(dev, "GEN_LOSS_CUM", genLossCum[dev].day)
 WR.setProp(dev, "EAE_DAY_NO_RAD", eaeDayNoRad[dev].day)
 WR.setProp(dev, "PR", 0)
 WR.setProp(dev, "PR_DAY", 0)
end
if (os.date("*t", checkMidnight[dev].ts).hour < os.date("*t", now).hour) then
 commStatus[dev].HourOn = 0
 commStatus[dev].HourOff = 0
 end
checkMidnight[dev].ts = now

--if ((os.date("*t", now).hour == 23) and (os.date("*t", now).min > 55)) then
if (((os.date("*t", now).hour == 23) and (os.date("*t", now).min > 55)) or ((os.date("*t", now).hour == 0) and (os.date("*t", now).min < 30))) then
 WR.setProp(dev, "PLANT_START_TIME", 0)
 WR.setProp(dev, "PLANT_STOP_TIME", 0)
 WR.setProp(dev, "OPERATIONAL_TIME", 0)
 WR.setProp(dev, "SPECIFIC_YIELD", 0)
 WR.setProp(dev, "PLANT_LOAD_DAY", 0)
end
------------------------ Check Midnight End -------------------------------

