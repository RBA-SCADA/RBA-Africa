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

------------------------ Define Function Start --------------------------------

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

-- function to log events in file
function logEvent(file, msg)
 file = io.open(file,"a")
 now = socket.gettime()
 if file~=nil then
  file:write(os.date("%a %b %d %Y %X",currTime)..":"..string.sub(now*1000, 11, 13).." "..msg.."\n")
 end
 file:close()
end


function logCsv(file, msg)
 file1 = io.open(file,"r")
 if file1 == nil then
  fileName = filePath.."/"..anlagen_id.."_DG_LOG_IM04_"..string.sub(now, 1, 10).."_2.csv"
  file = fileName
  file1 = io.open(file,"a")
  file1:write(anlagen_id..",SN:DG_LOG_IM04_,DG_LOG,0.0.0.0,2".."\n")
  -- log format ts, dg01Pac, dg02Pac, pvPac, pacLimit, gridConnSt, pacLimitSet, gridConnSet
  file1:write("TS,CASE,DG01_PAC,DG02_PAC,TOTAL_DG_PAC,PV_PAC,PAC_LIMIT,GRID_CONNECT,PAC_LIMIT_WRITE,GRID_CONNECT_WRITE".."\n")
 end
 file1:close()

 file = io.open(file,"a")
 now = socket.gettime()
 if file~=nil then
  file:write(string.sub(now, 1, 10)..","..msg.."\n")
 end
 file:close()
end


 function logCsvZE(file, msg)
 file2 = io.open(file,"r")
 if file2 == nil then
  fileNameZE = filePath.."/"..anlagen_id.."_ZE_LOG_IM04_"..string.sub(now, 1, 10).."_3.csv"
  file = fileNameZE
  file2 = io.open(file,"a")
  file2:write(anlagen_id..",SN:ZE_LOG_IM04_,ZE_LOG,0.0.0.0,3".."\n")
  --log format ts, dg01Pac, dg02Pac, pvPac, pacLimit, gridConnSt, cmdEnableSt, pacLimitSet, gridConnSet, cmdEnableSet
  file2:write("TS,CASE,ZE_PAC,PV_PAC,PAC_LIMIT,GRID_CONNECT,PAC_LIMIT_WRITE,CMD_ENABLE".."\n")
 end
 file2:close()

 file = io.open(file,"a")
 now = socket.gettime()
 if file~=nil then
  file:write(string.sub(now, 1, 10)..","..msg.."\n")
 end
 file:close()
end



------------------------ Define Function End ----------------------------------

-------------------------- Read Setpoints Start -------------------------------

if not(settings) then
 --print ("Inside file loading")
 settingsConfig = assert(io.open("/mnt/jffs2/solar/modbus/Settings.txt", "r"))
 settingsJson = settingsConfig:read("*all")
 settings = cjson.decode(settingsJson)
 settingsConfig:close()
 filePath = "/mnt/jffs2/dglog"
 fileName = filePath.."/"..anlagen_id.."_DG_LOG_IM04_"..string.sub(now, 1, 10).."_2.csv"
 fileNameZE = filePath.."/"..anlagen_id.."_ZE_LOG_IM04_"..string.sub(now, 1, 10).."_3.csv"
 --fileNameQAC = filePath.."/"..anlagen_id.."_QAC_LOG_IM02_"..string.sub(now, 1, 10).."_4.csv"
 filePackts = now
 dgCtlDev = {}
 lastDev = "SN:INV12"
 caseReset = 5
 case1DG = caseReset
 case2DG = caseReset
 case3DG = caseReset
 case4DG = caseReset
 case5DG = caseReset
 case6DG = caseReset
 case7DG = caseReset
 case8DG = caseReset

 case1ZE = caseReset
 case2ZE = caseReset
 case3ZE = caseReset
 case4ZE = caseReset
 case5ZE = caseReset

end

if not(settings.INVERTER[devS].dcCapacity and settings.INVERTER[devS].prRealRadSetpoint and settings.INVERTER[devS].prdcRealRadSetpoint and settings.INVERTER[devS].Module_inseries and settings.INVERTER[devS].Module_voc) then
 --print ("Data loading")
 settings.INVERTER[devS].dcCapacity = settings.INVERTER[devS].dcCapacity or settings.INVERTER.dcCapacity or 66.0
 settings.INVERTER[devS].prRealRadSetpoint = settings.INVERTER[devS].prRealRadSetpoint or settings.INVERTER.prRealRadSetpoint or 250.0
 settings.INVERTER[devS].prdcRealRadSetpoint = settings.INVERTER[devS].prdcRealRadSetpoint or settings.INVERTER.prdcRealRadSetpoint or 600.0
 settings.INVERTER[devS].Module_inseries = settings.INVERTER[devS].Module_inseries or settings.INVERTER.Module_inseries or 20.0
 settings.INVERTER[devS].Module_voc = settings.INVERTER[devS].Module_voc or settings.INVERTER.Module_voc or 45.82


 settings.PLANT.dg01Capacity = settings.PLANT.dg01Capacity or 400
 settings.PLANT.dg01MinLoad = settings.PLANT.dg01MinLoad or 30.0
 settings.PLANT.dg01ForceTune = settings.PLANT.dg01ForceTune or 2
 settings.PLANT.dg01CriticalLoad = settings.PLANT.dg01CriticalLoad or 10.0
 dg01MinLoad = (settings.PLANT.dg01Capacity * settings.PLANT.dg01MinLoad) / 100
 dg01CrititicalLoad = (settings.PLANT.dg01Capacity * settings.PLANT.dg01CriticalLoad) / 100
 dg01ForceTuneDown = (dg01MinLoad - ((settings.PLANT.dg01Capacity * settings.PLANT.dg01ForceTune) / 100))
 dg01ForceTuneUp = (dg01MinLoad + ((settings.PLANT.dg01Capacity * settings.PLANT.dg01ForceTune) / 100))
 dg01Threshold = (settings.PLANT.dg01Capacity * settings.PLANT.dg01Threshold) / 100 or 1

 settings.PLANT.dg02Capacity = settings.PLANT.dg02Capacity or 400
 settings.PLANT.dg02MinLoad = settings.PLANT.dg02MinLoad or 30.0
 settings.PLANT.dg02ForceTune = settings.PLANT.dg02ForceTune or 2
 settings.PLANT.dg02CriticalLoad = settings.PLANT.dg02CriticalLoad or 10.0
 dg02MinLoad = (settings.PLANT.dg02Capacity * settings.PLANT.dg02MinLoad) / 100
 dg02CrititicalLoad = (settings.PLANT.dg02Capacity * settings.PLANT.dg02CriticalLoad) / 100
 dg02ForceTuneDown = (dg02MinLoad - ((settings.PLANT.dg02Capacity * settings.PLANT.dg02ForceTune) / 100))
 dg02ForceTuneUp = (dg02MinLoad + ((settings.PLANT.dg02Capacity * settings.PLANT.dg02ForceTune) / 100))
 dg02Threshold = (settings.PLANT.dg02Capacity * settings.PLANT.dg02Threshold) / 100 or 1

 settings.PLANT.dg12Capacity = settings.PLANT.dg12Capacity or 400
 settings.PLANT.dg12MinLoad = settings.PLANT.dg12MinLoad or 30.0
 settings.PLANT.dg12ForceTune = settings.PLANT.dg12ForceTune or 2
 settings.PLANT.dg12CriticalLoad = settings.PLANT.dg12CriticalLoad or 10.0
 dg12MinLoad = (settings.PLANT.dg12Capacity * settings.PLANT.dg12MinLoad) / 100
 dg12CrititicalLoad = (settings.PLANT.dg12Capacity * settings.PLANT.dg12CriticalLoad) / 100
 dg12ForceTuneDown = (dg12MinLoad - ((settings.PLANT.dg12Capacity * settings.PLANT.dg12ForceTune) / 100))
 dg12ForceTuneUp = (dg12MinLoad + ((settings.PLANT.dg12Capacity * settings.PLANT.dg12ForceTune) / 100))
 dg12Threshold = (settings.PLANT.dg12Capacity * settings.PLANT.dg12Threshold) / 100 or 1
 tuneStep = settings.PLANT.tuneStep or 1
 pacLimitResetCnt = 0

 
 totalInvertersAcCapacity = settings.PLANT.totalInvertersAcCapacityS2 or 3
 zeMinLoad = settings.PLANT.zeMinLoad or 10
 zeCriticalLoad = settings.PLANT.zeCriticalLoad or 9
 zeThreshold = settings.PLANT.zeThreshold or 5
 tuneStep = settings.PLANT.tuneStep or 1
 pacLimitResetCnt = 0

 dgCtlDev = dgCtlDev or {}
 dgCtlDev[dev] = dev
 CHECKDATATIME(dev, now, "PR_DAY")
end

--------------------------- Read setpoints End --------------------------------

------------------------- Pack CSV For Portal Start ---------------------------

if (now > (filePackts + 300)) then
 os.execute("cd "..filePath.."; for f in *.csv; do mv -- \"$f\" \"${f%}.unsent\"; done")
 fileName = filePath.."/"..anlagen_id.."_DG_LOG_IM04_"..string.sub(now, 1, 10).."_2.csv"
 fileNameZE = filePath.."/"..anlagen_id.."_ZE_LOG_IM04_"..string.sub(now, 1, 10).."_3.csv"
 filePackts = now
end

-------------------------- Pack CSV For Portal End ----------------------------

---------------------- Reset DG & ZE case Start -------------------------------

if (dev == lastDev) then
 case1DG = caseReset
 case2DG = caseReset
 case3DG = caseReset
 case4DG = caseReset
 case5DG = caseReset
 case6DG = caseReset
 case7DG = caseReset
 case8DG = caseReset

 case1ZE = caseReset
 case2ZE = caseReset
 case3ZE = caseReset
 case4ZE = caseReset
 case5ZE = caseReset

end

----------------------- Reset DG & ZE case End --------------------------------

---------------------- COMMUNICATION STATUS Start -----------------------------

if WR.isOnline(dev) then
 WR.setProp(dev, "COMMUNICATION_STATUS", 0)
else
 WR.setProp(dev, "COMMUNICATION_STATUS", 1)
end

---------------------- COMMUNICATION STATUS End -------------------------------

------------------------ Factor Calculation Start------------------------------

local pac = WR.read(dev, "PAC")
local uac1 = WR.read(dev, "UAC1")
local uac2 = WR.read(dev, "UAC2")
local uac3 = WR.read(dev, "UAC3")
local uac12 = WR.read(dev, "UAC12")
local uac23 = WR.read(dev, "UAC23")
local uac31 = WR.read(dev, "UAC31")
local udc1 = WR.read(dev, "UDC1")
local udc2 = WR.read(dev, "UDC2")
local udc3 = WR.read(dev, "UDC3")
local udc4 = WR.read(dev, "UDC4")
local udc5 = WR.read(dev, "UDC5")
local udc6 = WR.read(dev, "UDC6")
local eae = WR.read(dev, "AC_ENERGY")

local uac = ((uac12+uac23+uac31)/3)
local udc = ((udc1 + udc2 + udc3)/3)
local pac1 = pac / 3
local pac2 = pac / 3
local pac3 = pac / 3
local uacln = ((uac1+uac2+uac3)/3)
WR.setProp(dev, "EAE", eae)
local eae1 = WR.read(dev, "EAE")
if eae1 ~= 0 then WR.setProp(dev, "EAE_DAY", eae1) end
local pvPac = 0
   for devV in pairs(dgCtlDev) do
    local invPac = WR.read(devV, "PAC")
    if not(is_nan(invPac)) then pvPac = pvPac + invPac end
          WR.setProp(dev, "TOTALS2PAC", pvPac)
   end
WR.setProp(dev, "UAC",       uac)
WR.setProp(dev, "UDC",       udc)
WR.setProp(dev, "PAC1",      pac1)
WR.setProp(dev, "PAC2",      pac2)
WR.setProp(dev, "PAC3",      pac3)
WR.setProp(dev, "UACLN",     uacln)
--WR.setProp(dev, "EAE",       eae)
--WR.setProp(dev, "EAE_DAY",   eae_day)

------------------------ Factor Calculation END --------------------------------

------------------------ Read Required Data Start -----------------------------

local radiationCum = WR.read(dev, "SOLAR_RADIATION_CUM")
local radiation = WR.read(dev, "RADIATION")
local prDay = WR.read(dev, "PR_DAY")
if is_nan(prDay) then prDay = 0 end
local pr = WR.read(dev, "PR")
if is_nan(pr) then pr = 0 end
local eaeDay = WR.read(dev, "EAE_DAY")
local udc = WR.read(dev, "UDC")
if is_nan(udc) then udc = 0 end

------------------------ Read Required Data End -------------------------------

------------------------ EFFICIENCY Calculation Start -------------------------

local Inv_pac = WR.read(dev, "PAC")
if is_nan(Inv_pac) then Inv_pac = 0 end
local Inv_pdc = WR.read(dev, "PDC")
if is_nan(Inv_pdc) then Inv_pdc = 0 end

if(Inv_pac == 0 and Inv_pdc == 0)then
 WR.setProp(dev, "EFFICIENCY", 0)
else
 WR.setProp(dev, "EFFICIENCY", ((Inv_pac/Inv_pdc)*100))
end
if is_nan(WR.read(dev, "EFFICIENCY")) then WR.setProp(dev, "EFFICIENCY", 0) end

----------------------- EFFICIENCY Calculation END ----------------------------

------------------------ PR Calculation Start ---------------------------------

if(radiation >= (settings.INVERTER[devS].prRealRadSetpoint)) then   --if 250 & ABOVE
 local prDayNow = (((eaeDay) / settings.INVERTER[devS].dcCapacity) / radiationCum) * 100
 if((is_nan(prDayNow)) or (prDayNow < 0) or (prDayNow > 100)) then
  prDayNow = prDay
 end
 WR.setProp(dev, "PR_DAY", prDayNow)
else
 WR.setProp(dev, "PR_DAY", 0/0)
end

if(radiation >= (settings.INVERTER[devS].prRealRadSetpoint)) then   -- if 250 & ABOVE
 local prNow = (((Inv_pac *1000) / (settings.INVERTER[devS].dcCapacity) / radiation)) * 100
 if((is_nan(prNow)) or (prNow < 0) or (prNow > 100)) then
   prNow = pr
 end
 WR.setProp(dev, "PR", prNow)
else
 WR.setProp(dev, "PR", 0/0)
end

if(radiation >= (settings.INVERTER[devS].prdcRealRadSetpoint)) then -- if 600 & ABOVE
 local prdc = (udc / ((settings.INVERTER[devS].Module_inseries) * (settings.INVERTER[devS].Module_voc)))*100
 if is_nan(prdc) then prdc = 0 end
  WR.setProp(dev, "PR_DC", prdc)
else
 WR.setProp(dev, "PR_DC", 0/0)
end

------------------------ PR Calculation End -----------------------------------

------------------- ZE & DG Logic Main Loop START ------------------------------

dgCtlDev = dgCtlDev or {}
local pvPacM = 0
for devV in pairs(dgCtlDev) do
 local invPacM = WR.read(devV, "PAC")
 if not(is_nan(invPacM)) then pvPacM = pvPacM + invPacM end
end
local dg01PacM = WR.read(dev, "DG01_PAC")
local dg02PacM = WR.read(dev, "DG02_PAC")

local zePacM = WR.read(dev, "ZE_PAC")
local pacLimitMWrite = "PAC_LIMIT"
local gridConnMWrite = "GRID_CONNECT"
local cmdEnableMWrite = "CMD_ENABLE"
local totaldgOnline = WR.read(dev, "TOTAL_DG_ONLINE")
local totaldgPac = WR.read(dev, "TOTAL_DG_PAC")


if ((is_nan(dg01PacM)) or (is_nan(dg02PacM))  or (is_nan(zePacM))) then
 dg01PacM = ""
 dg02PacM = ""
 zePacM = ""
 --local pacLimitResetCnt = 0
 if (pacLimitResetCnt > 4) then
  local pacLimitM = WR.read(dev, "PAC_LIMIT")/10
  local gridConnM = WR.read(dev, "GRID_CONNECT")
  if (gridConnM == 1) then
   --logCsv(fileName,"1".."INTOLOG3".."")
   for devV in pairs(dgCtlDev) do
    --WR.writeHexOpts(devV, gridConnMWrite, bit.tohex(1,4),0x6)
    WR.writeHexOpts(devV, pacLimitMWrite, bit.tohex(0*10,4),0x6)
    WR.writeHexOpts(devV, cmdEnableMWrite, bit.tohex(1,4),0x6)
   end
   logCsv(fileName,"0.1"..","..dg01PacM..","..dg02PacM..","..totaldgPac..","..totaldgOnline..",,"..pvPacM..","..pacLimitM..","..gridConnM..",".."0"..",".."")
  elseif (pacLimitM >= 0) then
   for devV in pairs(dgCtlDev) do
    --WR.writeHexOpts(devV, gridConnMWrite, bit.tohex(1,4),0x6)
    WR.writeHexOpts(devV, pacLimitMWrite, bit.tohex(0*10,4),0x6)
    WR.writeHexOpts(devV, cmdEnableMWrite, bit.tohex(1,4),0x6)
   end
   logCsv(fileName,"0.2"..","..dg01PacM..","..dg02PacM..","..totaldgPac..","..totaldgOnline..",,"..pvPacM..","..pacLimitM..","..gridConnM..",".."0"..",".."")
  end
  pacLimitResetCnt = 0
 else
  pacLimitResetCnt = pacLimitResetCnt + 1
 end
end


-------------------- ZE & DG Logic Main Loop END -------------------------------

-------------------------- ZE Logic START ---------------------------------------

if (dev == lastDev) then
 if ampZEFUHF == nil then
  -- Initialise FUH Function to Control PV Power
  ampZEFUHF =
  function(dev)
   local zePac = WR.read(dev, "ZE_PAC")
   local dg01PacZ = WR.read(dev, "DG01_PAC")
   --if is_nan(dg01PacZ) then dg01PacZ = 0 end
   local dg02PacZ = WR.read(dev, "DG02_PAC")
   --if is_nan(dg02PacZ) then dg02PacZ = 0 end
   local maxPacLimit = WR.read(dev, "PAC_LIMIT")/10
   if is_nan(maxPacLimit) then maxPacLimit = 0 end
   local minPacLimit = maxPacLimit
   for devV in pairs(dgCtlDev) do
    local invPacLimit = WR.read(devV, "PAC_LIMIT")/10
    if ((not(is_nan(invPacLimit))) and (invPacLimit > maxPacLimit)) then maxPacLimit = invPacLimit end
    if ((not(is_nan(invPacLimit))) and (invPacLimit < minPacLimit)) then minPacLimit = invPacLimit end
   end
  
   local pacLimit = maxPacLimit
   local oldPacLimit = pacLimit
   local gridConn = WR.read(dev, "GRID_CONNECT")
   local pacLimitWrite = "PAC_LIMIT"
   local cmdEnableWrite = "CMD_ENABLE"
   local gridConnWrite = "GRID_CONNECT"
   --local cmdEnableWriteV = ""
   --local dg02Pac = ""
   local pvPac = 0
   for devV in pairs(dgCtlDev) do
    local invPac = WR.read(devV, "PAC")
    if not(is_nan(invPac)) then pvPac = pvPac + invPac end
   end
   -- log format ts, dg01Pac, dg02Pac, pvPac, pacLimit, gridConnSt, pacLimitSet, gridConnSet
   -- logCsv("fileName","case"..","..dg01Pac..","..dg02Pac..","..pvPac..","..oldPacLimit..","..gridConn..","..pacLimit..",""")
  --[[ 
   for devV in pairs(dgCtlDev) do  
     local pacramp = WR.read(devV, "PAC_RMPTMS")
     local pacrampWrite = "PAC_RMPTMS"
     local pactimeout = WR.read(devV, "PAC_RVRTTMS")
     local pactimeoutWrite = "PAC_RVRTTMS"
     local cmdEnable = WR.read(devV, "CMD_ENABLE")
     local cmdEnableWrite = "CMD_ENABLE"
     local pacwintime = WR.read(devV, "PAC_WINTMS")
     local pacwintimeWrite = "PAC_WINTMS"
     if  ((pacramp ~= 5) or (pactimeout ~= 90) or (cmdEnable ~= 1) or (pacwintime ~= 0)) then
      if WR.isOnline(devV) then
       WR.writeHexOpts(devV, cmdEnableWrite, bit.tohex(1,4),0x6)
       WR.writeHexOpts(devV, pacrampWrite, bit.tohex(5,4),0x6)     
       WR.writeHexOpts(devV, pactimeoutWrite, bit.tohex(90,4),0x6)
       WR.writeHexOpts(devV, pacwintimeWrite, bit.tohex(0,4),0x6)
      end
     end
   end
   --]]
 
   local inv1_Com = WR.read("SN:INV08", "COMMUNICATION_STATUS")
   local inv2_Com = WR.read("SN:INV09", "COMMUNICATION_STATUS")
   local inv3_Com = WR.read("SN:INV10", "COMMUNICATION_STATUS")
   local inv4_Com = WR.read("SN:INV11", "COMMUNICATION_STATUS")
   local inv5_Com = WR.read("SN:INV12", "COMMUNICATION_STATUS")

   local totalInverters = 0
   if (inv1_Com < 1) then totalInverters = totalInverters + 1 end
   if (inv2_Com < 1) then totalInverters = totalInverters + 1 end
   if (inv3_Com < 1) then totalInverters = totalInverters + 1 end
   if (inv4_Com < 1) then totalInverters = totalInverters + 1 end
   if (inv5_Com < 1) then totalInverters = totalInverters + 1 end

   WR.setProp("SN:INV08", "TOTAL_INV_ONLINE", totalInverters)
   WR.setProp("SN:INV09", "TOTAL_INV_ONLINE", totalInverters)
   WR.setProp("SN:INV10", "TOTAL_INV_ONLINE", totalInverters)
   WR.setProp("SN:INV11", "TOTAL_INV_ONLINE", totalInverters)
   WR.setProp("SN:INV12", "TOTAL_INV_ONLINE", totalInverters)

   local udc = WR.read(dev, "UDC")
   if is_nan(udc) then udc = 0 end

   -- ZE starts ---------------------------------------------------------------------------
   if ((dg01PacZ < 1) and (dg02PacZ < 1)) then
    -- case 1 : ZE meter < critical load
    if ((zePac <= zeCriticalLoad) and (maxPacLimit >= 0)) then
         pacLimit = (((pvPac - (zeCriticalLoad - zePac)) / (totalInvertersAcCapacity * totalInverters)) * 100)
     if (pacLimit < 0) then pacLimit = 0 end
     pacLimit = tonumber(string.format("%.0f", pacLimit))
     if (oldPacLimit <= pacLimit) then
      pacLimit = oldPacLimit - 1
      if (case1ZE >= caseReset) then
       case1ZE = 0
       for devV in pairs(dgCtlDev) do
        if WR.isOnline(devV) then
         WR.writeHexOpts(devV, pacLimitWrite, bit.tohex(pacLimit*10,4),0x6)
         WR.writeHexOpts(devV, cmdEnableWrite, bit.tohex(1,4),0x6)
        end
       end
       logCsvZE(fileNameZE,"1.1.0"..","..zePac..","..pvPac..","..oldPacLimit..","..gridConn..","..pacLimit..",".."")
      else
       case1ZE = case1ZE + 1
       logCsvZE(fileNameZE,"1.1.1"..","..zePac..","..pvPac..","..oldPacLimit..","..gridConn..","..pacLimit..",".."")
      end
     else
      if (case1ZE >= caseReset) then
       case1ZE = 0
       for devV in pairs(dgCtlDev) do
        if WR.isOnline(devV) then
         WR.writeHexOpts(devV, pacLimitWrite, bit.tohex(pacLimit*10,4),0x6)
         WR.writeHexOpts(devV, cmdEnableWrite, bit.tohex(1,4),0x6)
        end
       end
       logCsvZE(fileNameZE,"1.1.2"..","..zePac..","..pvPac..","..oldPacLimit..","..gridConn..","..pacLimit..",".."")
      else
       case1ZE = case1ZE + 1
       logCsvZE(fileNameZE,"1.1.3"..","..zePac..","..pvPac..","..oldPacLimit..","..gridConn..","..pacLimit..",".."")
      end
     end
    -- case 2 : ZE meter > 10  force up
    elseif ((zePac >= (zeMinLoad + zeThreshold)) and (minPacLimit <= 100)) then
     pacLimit = (((pvPac + (zePac - zeCriticalLoad)) / (totalInvertersAcCapacity * totalInverters)) * 100) / 5
     if (pacLimit > 100) then pacLimit = 100 end
     pacLimit = tonumber(string.format("%.0f", pacLimit))
     oldPacLimit = minPacLimit
     if (oldPacLimit >= pacLimit) then
      pacLimit = oldPacLimit + 1
      if (case3ZE >= caseReset) then
       case3ZE = 0
       for devV in pairs(dgCtlDev) do
        if WR.isOnline(devV) then
         WR.writeHexOpts(devV, pacLimitWrite, bit.tohex(pacLimit*10,4),0x6)
         WR.writeHexOpts(devV, cmdEnableWrite, bit.tohex(1,4),0x6)
        end
       end
       logCsvZE(fileNameZE,"1.2.0"..","..zePac..","..pvPac..","..oldPacLimit..","..gridConn..","..pacLimit..",".."")
      else
       case3ZE = case3ZE + 1
       logCsvZE(fileNameZE,"1.2.1"..","..zePac..","..pvPac..","..oldPacLimit..","..gridConn..","..pacLimit..",".."")
      end
     else
      if (case3ZE >= caseReset) then
       case3ZE = 0
       for devV in pairs(dgCtlDev) do
        if WR.isOnline(devV) then
         WR.writeHexOpts(devV, pacLimitWrite, bit.tohex(pacLimit*10,4),0x6)
         WR.writeHexOpts(devV, cmdEnableWrite, bit.tohex(1,4),0x6)
        end
       end
       logCsvZE(fileNameZE,"1.2.2"..","..zePac..","..pvPac..","..oldPacLimit..","..gridConn..","..pacLimit..",".."")
      else
       case3ZE = case3ZE + 1
       logCsvZE(fileNameZE,"1.2.3"..","..zePac..","..pvPac..","..oldPacLimit..","..gridConn..","..pacLimit..",".."")
      end
     end
    -- case 3 : ZE meter > minload & ZE meter < 10  tune up
    elseif ((zePac >= zeMinLoad) and (minPacLimit <= 100)) then
     pacLimit = tonumber((maxPacLimit + tuneStep))
     if (pacLimit > 100) then pacLimit = 100 end
     if (case4ZE >= caseReset) then
      case4ZE = 0
      for devV in pairs(dgCtlDev) do
       if WR.isOnline(devV) then
        WR.writeHexOpts(devV, pacLimitWrite, bit.tohex(pacLimit*10,4),0x6)
        WR.writeHexOpts(devV, cmdEnableWrite, bit.tohex(1,4),0x6)
       end
      end
      logCsvZE(fileNameZE,"1.3.0"..","..zePac..","..pvPac..","..oldPacLimit..","..gridConn..","..pacLimit..",".."")
     else
      case4ZE = case4ZE + 1
      logCsvZE(fileNameZE,"1.3.1"..","..zePac..","..pvPac..","..oldPacLimit..","..gridConn..","..pacLimit..",".."")
     end
    -- case 4 : ZE meter > 0 & ZE meter < minload  no change
    --elseif ((zePac >= zeMinload) and (zePac <= zeThreshold)) then
     --pacLimit = pacLimit
     --logCsvZE(fileNameZE,"1.5.0"..","..zePac..","..pvPac..","..oldPacLimit..","..gridConn..","..",".."")
     else
     logCsvZE(fileNameZE,"1.5.0"..","..zePac..","..pvPac..","..oldPacLimit..","..gridConn..","..",".."")
    end
   end
   end
  -- add "FUH" function immediately:
  WR.addFieldUpdateHookFunction(dev, "ZE_PAC", ampZEFUHF);

  -- and save for repeated registration on later call of "initialize":
  WR.addInitHookFunction(
    function (nExpected)
      WR.addFieldUpdateHookFunction(dev, "ZE_PAC", ampZEFUHF);
    end
  )
 end
end


---------------------------- ZE LOGIC END --------------------------------------

------------------------ DG Logic START ---------------------------------------

if (dev == lastDev) then
 if ampDG01FUHF == nil then
  -- Initialise FUH Function to Control PV Power
  ampDG01FUHF =
  function(dev)
   local zePac = WR.read(dev, "ZE_PAC")
   local dg01Pac = WR.read(dev, "DG01_PAC")
   local dg02Pac = WR.read(dev, "DG02_PAC")
   local totaldgPac = WR.read(dev, "TOTAL_DG_PAC")
 
   local dgPac = dg01Pac
   local dg01CapacityX = settings.PLANT.dg01Capacity
   local dg01MinLoadX = dg01MinLoad
   local dg01CrititicalLoadX = dg01CrititicalLoad
   local dg01ForceTuneDownX = dg01ForceTuneDown
   local dg01ForceTuneUpX = dg01ForceTuneUp
   local dg01ThresholdX = dg01Threshold
 

   if ((dg01Pac == 0) and (dg02Pac > 0)) then
   dgPac = dg02Pac
   dg01CapacityX = settings.PLANT.dg02Capacity
   dg01MinLoadX = dg02MinLoad
   dg01CrititicalLoadX = dg02CrititicalLoad
   dg01ForceTuneDownX = dg02ForceTuneDown
   dg01ForceTuneUpX = dg02ForceTuneUp
   dg01ThresholdX = dg02Threshold
   end

   if ((dg01Pac > 0) and (dg02Pac > 0)) then
   dgPac = totaldgPac
   dg01CapacityX = settings.PLANT.dg12Capacity
   dg01MinLoadX = dg12MinLoad
   dg01CrititicalLoadX = dg12CrititicalLoad
   dg01ForceTuneDownX = dg12ForceTuneDown
   dg01ForceTuneUpX = dg12ForceTuneUp
   dg01ThresholdX = dg12Threshold
   end
   local maxPacLimit = WR.read(dev, "PAC_LIMIT")/10
   if is_nan(maxPacLimit) then maxPacLimit = 0 end
   local minPacLimit = maxPacLimit
   for devV in pairs(dgCtlDev) do
    local invPacLimit = WR.read(devV, "PAC_LIMIT")/10
    if ((not(is_nan(invPacLimit))) and (invPacLimit > maxPacLimit)) then maxPacLimit = invPacLimit end
    if ((not(is_nan(invPacLimit))) and (invPacLimit < minPacLimit)) then minPacLimit = invPacLimit end
   end
   
    local pacLimit = maxPacLimit
   local oldPacLimit = pacLimit
   local gridConn = WR.read(dev, "GRID_CONNECT")
   local pacLimitWrite = "PAC_LIMIT"
   local cmdEnableWrite = "CMD_ENABLE"
   local gridConnWrite = "GRID_CONNECT"
   
  --[[
   for devV in pairs(dgCtlDev) do
     local pacramp = WR.read(devV, "PAC_RMPTMS")
     local pacrampWrite = "PAC_RMPTMS"
     local pactimeout = WR.read(devV, "PAC_RVRTTMS")
     local pactimeoutWrite = "PAC_RVRTTMS"
     local cmdEnable = WR.read(devV, "CMD_ENABLE")
     local cmdEnableWrite = "CMD_ENABLE"
     local pacwintime = WR.read(devV, "PAC_WINTMS")
     local pacwintimeWrite = "PAC_WINTMS"
    
     if  ((pacramp ~= 5) or (pactimeout ~= 90) or (cmdEnable ~= 1) or (pacwintime ~= 0)) then  
       if WR.isOnline(devV) then
       WR.writeHexOpts(devV, cmdEnableWrite, bit.tohex(1,4),0x6)
       WR.writeHexOpts(devV, pacrampWrite, bit.tohex(5,4),0x6)
       WR.writeHexOpts(devV, pactimeoutWrite, bit.tohex(90,4),0x6)
       WR.writeHexOpts(devV, pacwintimeWrite, bit.tohex(0,4),0x6)
      end
     end
   end
  --]]
   

   local pvPac = 0
   for devV in pairs(dgCtlDev) do
    local invPac = WR.read(devV, "PAC")
    if not(is_nan(invPac)) then pvPac = pvPac + invPac end
   end

   local inv1_Com = WR.read("SN:INV08", "COMMUNICATION_STATUS")
   local inv2_Com = WR.read("SN:INV09", "COMMUNICATION_STATUS")
   local inv3_Com = WR.read("SN:INV10", "COMMUNICATION_STATUS")
   local inv4_Com = WR.read("SN:INV11", "COMMUNICATION_STATUS")
   local inv5_Com = WR.read("SN:INV12", "COMMUNICATION_STATUS")

   local totalInverters = 0
   if (inv1_Com < 1) then totalInverters = totalInverters + 1 end
   if (inv2_Com < 1) then totalInverters = totalInverters + 1 end
   if (inv3_Com < 1) then totalInverters = totalInverters + 1 end
   if (inv4_Com < 1) then totalInverters = totalInverters + 1 end
   if (inv5_Com < 1) then totalInverters = totalInverters + 1 end

   WR.setProp("SN:INV08", "TOTAL_INV_ONLINE", totalInverters)
   WR.setProp("SN:INV09", "TOTAL_INV_ONLINE", totalInverters)
   WR.setProp("SN:INV10", "TOTAL_INV_ONLINE", totalInverters)
   WR.setProp("SN:INV11", "TOTAL_INV_ONLINE", totalInverters)
   WR.setProp("SN:INV12", "TOTAL_INV_ONLINE", totalInverters)

   
   -- log format ts, dg01Pac, dg02Pac, pvPac, pacLimit, gridConnSt, pacLimitSet, gridConnSet
   -- logCsv("fileName","case"..","..dg01Pac..","..dg02Pac..","..pvPac..","..oldPacLimit..","..gridConn..","..pacLimit..",""")

   -- case 1 : dg meter no communication or dg < 0 consider dg off and set power limit to 100 %
   --if ((dg01Pac < 1) and (dg02Pac < 1) and (zePac < 1)) then
   if ( (totaldgPac < 1) and (zePac < -250))then
    for devV in pairs(dgCtlDev) do
     invGridConn = WR.read(devV, "GRID_CONNECT")
     if ((not(is_nan(invGridConn))) and (invGridConn < gridConn)) then gridConn = invGridConn end
    end
    if (minPacLimit ~= 100) then
     pacLimit = 0
     if (gridConn == 0) then
      if (case1DG >= caseReset) then
       case1DG = 0
       for devV in pairs(dgCtlDev) do
        --WR.writeHexOpts(devV, gridConnWrite, bit.tohex(1,4),0x6)
        WR.writeHexOpts(devV, pacLimitWrite, bit.tohex(pacLimit*10,4),0x6)
        WR.writeHexOpts(devV, cmdEnableWrite, bit.tohex(1,4),0x6)
       end
       logCsv(fileName,"2.1.0"..","..dg01Pac..","..dg02Pac..","..totaldgPac..","..pvPac..","..oldPacLimit..","..gridConn..","..pacLimit..",".."1")
      else
       case1DG = case1DG + 1
       logCsv(fileName,"2.1.1"..","..dg01Pac..","..dg02Pac..","..totaldgPac..","..pvPac..","..oldPacLimit..","..gridConn..","..pacLimit..",".."1")
      end
     else
      if (case1DG >= caseReset) then
       case1DG = 0
       for devV in pairs(dgCtlDev) do
        WR.writeHexOpts(devV, pacLimitWrite, bit.tohex(pacLimit*10,4),0x6)
        WR.writeHexOpts(devV, cmdEnableWrite, bit.tohex(1,4),0x6)
       end
       logCsv(fileName,"2.1.2"..","..dg01Pac..","..dg02Pac..","..totaldgPac..","..pvPac..","..oldPacLimit..","..gridConn..","..pacLimit..",".."")
      else
       case1DG = case1DG + 1
       logCsv(fileName,"2.1.3"..","..dg01Pac..","..dg02Pac..","..totaldgPac..","..pvPac..","..oldPacLimit..","..gridConn..","..pacLimit..",".."")
      end
     end
    end
   --elseif ((dg01Pac < 1) and (dg02Pac > 1)) then
    --- No Operation
   -- case 2 : dg generation < dg critical load then trip the inverter
   elseif (dgPac > 2) then
    if (dgPac <= dg01CrititicalLoadX) then
     if (maxPacLimit >= 0) then
      if (case2DG >= caseReset) then
       case2DG = 0
       for devV in pairs(dgCtlDev) do
        --WR.writeHexOpts(devV, gridConnWrite, bit.tohex(0,4),0x6)
        WR.writeHexOpts(devV, pacLimitWrite, bit.tohex(0,4),0x6)
        WR.writeHexOpts(devV, cmdEnableWrite, bit.tohex(1,4),0x6)
       end
       logCsv(fileName,"2.2.0"..","..dg01Pac..","..dg02Pac..","..totaldgPac..","..pvPac..","..oldPacLimit..","..gridConn..",".."0"..",".."0")
      else
       case2DG = case2DG + 1
       logCsv(fileName,"2.2.1"..","..dg01Pac..","..dg02Pac..","..totaldgPac..","..pvPac..","..oldPacLimit..","..gridConn..",".."0"..",".."0")
      end
     end
    -- case 3 : dg generation > dg critical load and inverter is tripped then switch on inverter
    elseif ((dgPac > dg01CrititicalLoadX) and (gridConn == 0)) then
     if (case3DG >= caseReset) then
      case3DG = 0
      --[[--
      for devV in pairs(dgCtlDev) do
       WR.writeHexOpts(devV, gridConnWrite, bit.tohex(1,4),0x6)
      end
      --]]--
      logCsv(fileName,"2.3.0"..","..dg01Pac..","..dg02Pac..","..totaldgPac..","..pvPac..","..oldPacLimit..","..gridConn..","..""..",".."1")
     else
      case3DG = case3DG + 1
      logCsv(fileName,"2.3.1"..","..dg01Pac..","..dg02Pac..","..totaldgPac..","..pvPac..","..oldPacLimit..","..gridConn..","..""..",".."1")
     end
    -- case 4 : dg generation < dg force tune down setpoint and pac limit setpoint > 0 then calculate power limit setpoint and set
    elseif ((dgPac <= dg01ForceTuneDownX) and (maxPacLimit >= 0)) then
     pacLimit = (((pvPac - (dg01MinLoadX - dgPac)) / (totalInvertersAcCapacity * totalInverters)) * 100)
     if (pacLimit < 0) then pacLimit = 0 end
     pacLimit = tonumber(string.format("%.0f", pacLimit))
     if (oldPacLimit <= pacLimit) then
      pacLimit = oldPacLimit - 1
      if (case4DG >= caseReset) then
       case4DG = 0
       for devV in pairs(dgCtlDev) do
        WR.writeHexOpts(devV, pacLimitWrite, bit.tohex(pacLimit*10,4),0x6)
        WR.writeHexOpts(devV, cmdEnableWrite, bit.tohex(1,4),0x6)
       end
       logCsv(fileName,"2.4.0"..","..dg01Pac..","..dg02Pac..","..totaldgPac..","..pvPac..","..oldPacLimit..","..gridConn..","..pacLimit..",".."")
      else
       case4DG = case4DG + 1
       logCsv(fileName,"2.4.1"..","..dg01Pac..","..dg02Pac..","..totaldgPac..","..pvPac..","..oldPacLimit..","..gridConn..","..pacLimit..",".."")
      end
     else
      if (case4DG >= caseReset) then
       case4DG = 0
       for devV in pairs(dgCtlDev) do
        WR.writeHexOpts(devV, pacLimitWrite, bit.tohex(pacLimit*10,4),0x6)
        WR.writeHexOpts(devV, cmdEnableWrite, bit.tohex(1,4),0x6)
       end
       logCsv(fileName,"2.4.2"..","..dg01Pac..","..dg02Pac..","..totaldgPac..","..pvPac..","..oldPacLimit..","..gridConn..","..pacLimit..",".."")
      else
       case4DG = case4DG + 1
       logCsv(fileName,"2.4.3"..","..dg01Pac..","..dg02Pac..","..totaldgPac..","..pvPac..","..oldPacLimit..","..gridConn..","..pacLimit..",".."")
      end
     end
    -- case 5 : dg generation > dg minimum load and < dg fine tune then no change in power limit setpoint
    elseif((dgPac >= dg01MinLoadX) and (dgPac <= (dg01MinLoadX + dg01ThresholdX))) then
     pacLimit = pacLimit
     logCsv(fileName,"2.5.0"..","..dg01Pac..","..dg02Pac..","..totaldgPac..","..pvPac..","..oldPacLimit..","..gridConn..","..""..",".."")
    -- case 6 : dg generation < dg minimum load and pac limit setpoint > 0 then decrement the pac limit setpoint
    elseif ((dgPac < dg01MinLoadX) and (maxPacLimit >= 0)) then
     pacLimit = tonumber((minPacLimit - tuneStep))
     if (pacLimit < 0) then pacLimit = 0 end
     if (case6DG >= caseReset) then
      case6DG = 0
      for devV in pairs(dgCtlDev) do
       WR.writeHexOpts(devV, pacLimitWrite, bit.tohex(pacLimit*10,4),0x6)
       WR.writeHexOpts(devV, cmdEnableWrite, bit.tohex(1,4),0x6)
      end
      logCsv(fileName,"2.6.0"..","..dg01Pac..","..dg02Pac..","..totaldgPac..","..pvPac..","..oldPacLimit..","..gridConn..","..pacLimit..",".."")
     else
      case6DG = case6DG + 1
      logCsv(fileName,"2.6.1"..","..dg01Pac..","..dg02Pac..","..totaldgPac..","..pvPac..","..oldPacLimit..","..gridConn..","..pacLimit..",".."")
     end
    -- case 7 : dg generation > dg force tune up setpoint and pac limit setpoint < 100 then calculate power limit setpoint and set
    elseif ((dgPac >= dg01ForceTuneUpX) and (minPacLimit <= 100)) then
     pacLimit = (((pvPac + (dgPac - dg01MinLoadX)) / (totalInvertersAcCapacity * totalInverters)) * 100)
     if (pacLimit > 100) then pacLimit = 100 end
     pacLimit = tonumber(string.format("%.0f", pacLimit))
     oldPacLimit = minPacLimit
     if (oldPacLimit >= pacLimit) then
      pacLimit = oldPacLimit + 1
      if (case7DG >= caseReset) then
       case7DG = 0
       for devV in pairs (dgCtlDev) do
        WR.writeHexOpts(devV, pacLimitWrite, bit.tohex(pacLimit*10,4),0x6)
       WR.writeHexOpts(devV, cmdEnableWrite, bit.tohex(1,4),0x6)
       end
       logCsv(fileName,"2.7.0"..","..dg01Pac..","..dg02Pac..","..totaldgPac..","..pvPac..","..oldPacLimit..","..gridConn..","..pacLimit..",".."")
      else
       case7DG = case7DG + 1
       logCsv(fileName,"2.7.1"..","..dg01Pac..","..dg02Pac..","..totaldgPac..","..pvPac..","..oldPacLimit..","..gridConn..","..pacLimit..",".."")
      end
     else
      if (case7DG >= caseReset) then
       case7DG = 0
       for devV in pairs(dgCtlDev) do
        WR.writeHexOpts(devV, pacLimitWrite, bit.tohex(pacLimit*10,4),0x6)
         WR.writeHexOpts(devV, cmdEnableWrite, bit.tohex(1,4),0x6)
       end
       logCsv(fileName,"2.7.2"..","..dg01Pac..","..dg02Pac..","..totaldgPac..","..pvPac..","..oldPacLimit..","..gridConn..","..pacLimit..",".."")
      else
       case7DG = case7DG + 1
       logCsv(fileName,"2.7.3"..","..dg01Pac..","..dg02Pac..","..totaldgPac..","..pvPac..","..oldPacLimit..","..gridConn..","..pacLimit..",".."")
      end
     end
    -- case 8 : dg generation > dg minimum load and pac limit setpoint < 100 then increment the pac limit setpoint
    elseif ((dgPac > (dg01MinLoadX + dg01ThresholdX)) and (minPacLimit <= 100)) then
     pacLimit = tonumber((maxPacLimit + tuneStep))
     if (pacLimit > 100) then pacLimit = 100 end
     if (case8DG >= caseReset) then
      case8DG = 0
      for devV in pairs(dgCtlDev) do
       WR.writeHexOpts(devV, pacLimitWrite, bit.tohex(pacLimit*10,4),0x6)
       WR.writeHexOpts(devV, cmdEnableWrite, bit.tohex(1,4),0x6)
      end
      logCsv(fileName,"2.8.0"..","..dg01Pac..","..dg02Pac..","..totaldgPac..","..pvPac..","..oldPacLimit..","..gridConn..","..pacLimit..",".."")
     else
      case8DG = case8DG + 1
      logCsv(fileName,"2.8.1"..","..dg01Pac..","..dg02Pac..","..totaldgPac..","..pvPac..","..oldPacLimit..","..gridConn..","..pacLimit..",".."")
     end
    -- case 9 : unknown
    else
     logCsv(fileName,"2.9.0"..","..dg01Pac..","..dg02Pac..","..totaldgPac..","..pvPac..","..oldPacLimit..","..gridConn..","..""..",".."")
    end
   end
  end
  -- add "FUH" function immediately:
  WR.addFieldUpdateHookFunction(dev, "DG01_PAC", ampDG01FUHF);
  -- and save for repeated registration on later call of "initialize":
  WR.addInitHookFunction(
    function (nExpected)
      WR.addFieldUpdateHookFunction(dev, "DG01_PAC", ampDG01FUHF);
    end
  )
 end
end

---------------------------- DG LOGIC END --------------------------------------

