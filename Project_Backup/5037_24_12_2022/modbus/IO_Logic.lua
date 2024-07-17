local dev, good = ...
--print(dev)

---------------------- COMMUNICATION STATUS Start -----------------------------

if WR.isOnline(dev) then
 WR.setProp(dev, "COMMUNICATION_STATUS", 0)
else
 WR.setProp(dev, "COMMUNICATION_STATUS", 1)
end

---------------------- COMMUNICATION STATUS End -------------------------------
-------------------------------IO Logic Start----------------------------------

local cCBc = WR.read(dev, "CB1_CC")
local cCBcWrite = "CB1_CC"
local dg01Pac = WR.read(dev, "DG01_PAC")
--if is_nan(dg01Pac) then dg01Pac = 0 end
local dg02Pac = WR.read(dev, "DG02_PAC")
--if is_nan(dg02Pac) then dg02Pac = 0 end
local zePac = WR.read(dev, "ZE_PAC")
--if is_nan(zePac) then zePac = 0 end
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



  if ((iMc1Status > 0) or (iMc2Status > 0) or (iMc3Status > 0) or (iMc4Status > 0) or (iMc5Status > 0) or (iMc6Status > 0) or (iMc7Status > 0) or (iMc8Status > 0) or (iMc9Status > 0) or (iMc10Status > 0)  or (iMc11Status > 0)  or (iMc12Status > 0) or (iMc13Status > 0) or (iMc14Status > 0)  or (iMc15Status > 0)  or (iMc16Status > 0) or (iMc17Status > 0) or (dg01Pac < 0) or (dg02Pac < 0))  then
    WR.writeHexOpts(dev, cCBcWrite, bit.tohex(1,4),0x6)
  else
    WR.writeHexOpts(dev, cCBcWrite, bit.tohex(0,4),0x6)
  end

-------------------------------IO Logic End------------------------------------


