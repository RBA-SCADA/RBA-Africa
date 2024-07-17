local dev, good = ...
--print(dev)

devS = string.sub(dev, 8, -1)
--print("devS = ", devS)

require ("socket")
local now = socket.gettime()
local date = os.date("*t")
local hour = date.hour
local min = date.min
local sec = date.sec

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
 CHECKDATATIME(dev, now, "SOLAR_RADIATION_CUM")
end

------------------------ Meter Calculation Start ------------------------------

local ambTempAct = WR.read(dev, "Ambient_Temperature_Act")
local modTempAct = WR.read(dev, "Module_Temperature_Act")
local radiationAct = WR.read(dev, "Solar_Radiation_Act")

local cellTempA = WR.read(dev, "Cell_Temperature")
local ambTempA = WR.read(dev, "Ambient_Temperature")

local ambTemp = 0
local modTemp = 0
local radC = 0

if (ambTempAct < 20001) then ambTemp = (((ambTempAct - 4000)*(0.008125)) - 40) end
if (modTempAct < 21001) then modTemp = (((modTempAct - 4000)*(0.0125)) - 123.5) end
if (radiationAct < 20001) then radC = ((radiationAct - 4000)*(0.075)) end

if (radC < 1.2) then WR.setProp(dev, "Solar_Radiation", 0) else WR.setProp(dev, "Solar_Radiation", radC) end

WR.setProp(dev, "ALPHA_FACT", (((ambTempA - cellTempA) * (-0.02)) +1))
--WR.setProp(dev, "Ambient_Temperature", ambTemp)
--WR.setProp(dev, "Module_Temperature", modTemp)
--WR.setProp(dev, "Solar_Radiation", radC)

------------------------ Meter Calculation End --------------------------------

---------------------- COMMUNICATION STATUS Start -----------------------------

if WR.isOnline(dev) then
 WR.setProp(dev, "COMMUNICATION_STATUS", 0)
else
 WR.setProp(dev, "COMMUNICATION_STATUS", 1)
end

---------------------- COMMUNICATION STATUS End -------------------------------

------------------------ Check Midnight Start ---------------------------------

checkMidnight = checkMidnight or {}
checkMidnight[dev] = checkMidnight[dev] or {ts=now}
if (os.date("*t", checkMidnight[dev].ts).hour > os.date("*t", now).hour) then
 radCum[dev].day = 0
end
checkMidnight[dev].ts = now

------------------------ Check Midnight End -----------------------------------

local radiation = WR.read(dev, "Solar_Radiation")
radCum = radCum or {}
radCum[dev] = radCum[dev] or {ts=now, day=WR.read(dev, "SOLAR_RADIATION_CUM")}
if is_nan(radiation) then radiation = 0 end
if (is_nan(radCum[dev].day)) then radCum[dev].day = 0 end

------------------------- Radiation Day Start ---------------------------------

radCum[dev].day = radCum[dev].day + (((now-radCum[dev].ts) * radiation) / (60 * 60 * 1000))
radCum[dev].ts = now
WR.setProp(dev, "SOLAR_RADIATION_CUM", radCum[dev].day)

------------------------- Radiation Day End -----------------------------------

