-- Author: Dominik Stuecheli (DS 105D)
-- GitHub: https://github.com/dominikstuecheli-105D-Engineering
-- Workshop: https://steamcommunity.com/profiles/76561199031764342/myworkshopfiles/
--
--- Developed using LifeBoatAPI - Stormworks Lua plugin for VSCode - https://code.visualstudio.com/download (search "Stormworks Lua with LifeboatAPI" extension)
--- If you have any issues, please report them here: https://github.com/nameouschangey/STORMWORKS_VSCodeExtension/issues - by Nameous Changey


--[====[ HOTKEYS ]====]
-- Press F6 to simulate this file
-- Press F7 to build the project, copy the output from /_build/out/ into the game to use
-- Remember to set your Author name etc. in the settings: CTRL+COMMA


--[====[ EDITABLE SIMULATOR CONFIG - *automatically removed from the F7 build output ]====]
---@section __LB_SIMULATOR_ONLY__
do
    ---@type Simulator -- Set properties and screen sizes here - will run once when the script is loaded
    simulator = simulator
    simulator:setScreen(1, "3x3")
    simulator:setProperty("ExampleNumberProperty", 123)

    -- Runs every tick just before onTick; allows you to simulate the inputs changing
    ---@param simulator Simulator Use simulator:<function>() to set inputs etc.
    ---@param ticks     number Number of ticks since simulator started
    function onLBSimulatorTick(simulator, ticks)

        -- touchscreen defaults
        local screenConnection = simulator:getTouchScreen(1)
        simulator:setInputBool(1, screenConnection.isTouched)
        simulator:setInputNumber(1, screenConnection.width)
        simulator:setInputNumber(2, screenConnection.height)
        simulator:setInputNumber(3, screenConnection.touchX)
        simulator:setInputNumber(4, screenConnection.touchY)

        -- NEW! button/slider options from the UI
        simulator:setInputBool(31, simulator:getIsClicked(1))       -- if button 1 is clicked, provide an ON pulse for input.getBool(31)
        simulator:setInputNumber(31, simulator:getSlider(1))        -- set input 31 to the value of slider 1

        simulator:setInputBool(32, simulator:getIsToggled(2))       -- make button 2 a toggle, for input.getBool(32)
        simulator:setInputNumber(32, simulator:getSlider(2) * 50)   -- set input 32 to the value from slider 2 * 50
    end;
end
---@endsection


--[====[ IN-GAME CODE ]====]

-- try require("Folder.Filename") to include code from another file in this, so you can store code in libraries
-- the "LifeBoatAPI" is included by default in /_build/libs/ - you can use require("LifeBoatAPI") to get this, and use all the LifeBoatAPI.<functions>!



require("SWDUI")
require("Default SWDUI Theme")



--Constants
smallBatteryCapacity = 1600 --each small battery stores 1600 SWs
targetTractionBatterySOC = property.getNumber("Target traction battery SOC (0-100)")/100

maxTankPressure = 60 --in atm

--Fuel cell properties are for all 4 Cells combined
fuelCellPowerOnFullThrottle = 238.4 --SW
hydrogenFlowAtFullPower = 35.538 --L/s
oxygenFlowAtFullPower = 35.8 --L/s


--Settings
maxValveChange = 0.1 / 60 --/tick
valveChangeSpeedMultiplier = 0.0002
tractionBatterySOCErrorCorrectionMultiplier = 100

displayedValueSmoothing = 0.97

--State
oldTractionBatteryCharge = 0
hydrogenValve = 0
oxygenValve = 0
motor = 0

displayedFuelCellPower = 0
displayedMotorPower = 0



function onTick()

    --INPUTS

    --Touch
    setCursor(input.getNumber(3), input.getNumber(4), input.getBool(1))

    --Traction battery
    tractionBatterySOC = input.getNumber(5)
    tractionBatteryCharge = tractionBatterySOC*property.getNumber("Traction battery small battery count")*smallBatteryCapacity

    tractionBattteryChargeDelta = (tractionBatteryCharge-oldTractionBatteryCharge)*60 --in SW
    oldTractionBatteryCharge = tractionBatteryCharge

    tractionBatterySOCError = (targetTractionBatterySOC - tractionBatterySOC)/targetTractionBatterySOC

    --Fuels
    hydrogenFlow = -input.getNumber(6)
    oxygenFlow = -input.getNumber(7)

    hydrogenTankPressure = input.getNumber(9)
    oxygenTankPressure = input.getNumber(10)

    --Fuel cell
    fuelCellPower = hydrogenFlow/hydrogenFlowAtFullPower * oxygenFlow/oxygenFlowAtFullPower * fuelCellPowerOnFullThrottle --in SW
    displayedFuelCellPower = displayedValueSmoothing*displayedFuelCellPower + (1-displayedValueSmoothing)*fuelCellPower --smoothed value to be displayed

    --Motor
    motorPower = math.min(0, tractionBattteryChargeDelta-fuelCellPower) --in SW
    displayedMotorPower = displayedValueSmoothing*displayedMotorPower + (1-displayedValueSmoothing)*motorPower --smoothed value to be displayed

    --Other
    throttle = input.getNumber(8)
    systemOn = input.getBool(5)
    reverse = input.getBool(6)

    --CALCULATIONS & OUTPUTS

    --Motor
    motor = throttle
    if reverse then motor = -motor end
    if not systemOn then motor = 0 end
    output.setNumber(1, motor)

    --System readyness
    output.setBool(1, tractionBatterySOC>0.8 and hydrogenTankPressure>0.5 and oxygenTankPressure>0.5)

    --Fuel valves
    targetHydrogenFlow = math.max(0, (throttle + tractionBatterySOCError*tractionBatterySOCErrorCorrectionMultiplier)*hydrogenFlowAtFullPower)
    targetOxygenFlow = math.max(0, (throttle + tractionBatterySOCError*tractionBatterySOCErrorCorrectionMultiplier)*oxygenFlowAtFullPower)

    if not systemOn then
        targetHydrogenFlow = 0
        targetOxygenFlow = 0
    end

    hydrogenValve = hydrogenValve + clamp((targetHydrogenFlow - hydrogenFlow)*valveChangeSpeedMultiplier, -maxValveChange, maxValveChange)
    oxygenValve = oxygenValve + clamp((targetOxygenFlow - oxygenFlow)*valveChangeSpeedMultiplier, -maxValveChange, maxValveChange)

    hydrogenValve = clamp(hydrogenValve, 0,1)
    oxygenValve = clamp(oxygenValve, 0,1)

    output.setNumber(2, hydrogenValve)
    output.setNumber(3, oxygenValve)

    output.setBool(2, hydrogenValve > 0 or oxygenValve > 0) --Pumps

    --Fan motor
    fanMotor = 0.05 + clamp(throttle + math.max(tractionBatterySOCError*tractionBatterySOCErrorCorrectionMultiplier,0), 0,1)*0.25
    if not systemOn then fanMotor = 0 end
    output.setNumber(4, fanMotor)

end



function onDraw() drawOnScreen(
    VStack {
        Default.Topbar("Hydrogen"),

        Default.Table(
            {
                Text("TBatt",-1):color(50),
                Text("FCell",-1):color(50),
                Text("Motor",-1):color(50)
            },
            {
                Text(string.format("%.1f%%", tractionBatterySOC*100),1):color(200),
                Text(string.format("+%.0fSW", displayedFuelCellPower),1):color(20,150,20),
                Text(string.format("%.0fSW", displayedMotorPower),1):color(200,20,20),
            }
        ):padding(1),

        HStack({
            ZStack {
                ProgressBar(hydrogenTankPressure/maxTankPressure, 1):color(10,10,40),
                RectangleBorder():color(15),
                VStack {
                    Text("H2"):color(200,200,200,0.2):fixedSize(nil,7),
                    Text(string.format("%.0fatm", hydrogenTankPressure)):color(200,200,200,0.2):fixedSize(nil,7)
                }
            },

            ZStack {
                ProgressBar(oxygenTankPressure/maxTankPressure, 1):color(40,40,60),
                RectangleBorder():color(15),
                VStack {
                    Text("O"):color(200,200,200,0.2):fixedSize(nil,7),
                    Text(string.format("%.0fatm", oxygenTankPressure)):color(200,200,200,0.2):fixedSize(nil,7)
                }
            }
        }, 2)
            :individualPadding{nil,1,1,1},
    }
) end