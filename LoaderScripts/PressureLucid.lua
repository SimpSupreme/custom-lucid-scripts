--[[
    +====Features====+
    Angler + Variants Warning
    Wall Dweller Warning
    Fake Door Warning
    Void Locker Warning
    Money Highlighting
    Item Highlighting
    Keycard Highlighting
    Searchlights Generator Highlighting
    We Die In The Dark Helper
    Extra Careful Helper
    +================+
]]

-- //Constants
local DATAMODEL = Globals:Game()
local PLAYERS = DATAMODEL:FindFirstChild("Players")
local LOCAL_PLAYER = Globals:LocalPlayer()
local WORKSPACE = Globals.Workspace()
local SCREEN_SIZE = Vector2.new(1920, 1080)
local GAMEPLAY_FOLDER = WORKSPACE:FindFirstChild("GameplayFolder")
local ROOMS_FOLDER = GAMEPLAY_FOLDER:FindFirstChild("Rooms")
local MAJOR_FILE_NAMES = {"AbstractDocument", "LunarDockDocument", "ThePainterDocument", "StanDocument", "MindscapeDocument", "AnalogChristmasDocument", "LetVandZoneDocument", "DiVineDocument", "RidgeDocument"} -- currently unused, still finding them
local FAKE_DOOR_NAMES = {"ServerTrickster", "TricksterRoom", "OutskirtsTrickster"}
local ITEM_NAMES = {"RoomsBattery", "DefaultBattery1", "DefaultBattery2", "DefaultBattery3", "AltBattery1", "AltBattery2", "AltBattery3", "FlashLight", "Flashlight", "WindupLight", "Blacklight", "Gummylight", "Lantern", "SmallLantern", "BigFlashBeacon", "FlashBeacon", "Book", "Medkit", "CrateMedkit", "HealthBoost", "CrateHealthBoost", "Defib", "CrateDefib", "SPRINT", "DoubleSprint", "CodeBreacher", "CrateCodeBreacher", "ToyRemote", "BlueToyRemote"}
local ITEM_NAMES_NO_LIGHTS = {"RoomsBattery", "DefaultBattery1", "DefaultBattery2", "DefaultBattery3", "AltBattery1", "AltBattery2", "AltBattery3", "Medkit", "CrateMedkit", "HealthBoost", "CrateHealthBoost", "Defib", "CrateDefib", "SPRINT", "DoubleSprint", "CodeBreacher", "CrateCodeBreacher", "ToyRemote", "BlueToyRemote"}
local KEYCARD_NAMES = {"NormalKeyCard", "PasswordPaper", "InnerKeyCard", "RidgeKeyCard"}
local ANGLER_VARIANTS = {"Angler", "Blitz", "Froger", "Pinkie", "Chainsmoker", "Pandemonium", "RidgeAngler", "RidgeFroger", "RidgeBlitz", "RidgePinkie", "RidgeChainsmoker", "A60", "Mirage"}
local CURERNCY_NAMES = {"Blueprint", "Relic", "HypnoCoin"}
local VALUE_OFFSET = 0xD0

-- //Colors
local COLOR_WHITE = Vector3.new(255, 255, 255)
local COLOR_BLACK = Vector3.new(0, 0, 0,)
local COLOR_RED = Vector3.new(255, 0, 0)
local COLOR_LIGHT_RED = Vector3.new(255, 90, 90)
local COLOR_GREEN = Vector3.new(0, 255, 0)
local COLOR_LIGHT_GREEN = Vector3.new(90, 255, 90)
local COLOR_BLUE = Vector3.new(0, 0, 255)
local COLOR_LIGHT_BLUE = Vector3.new(90, 90, 255)
local COLOR_YELLOW = Vector3.new(255, 255, 0)
local COLOR_LIGHT_YELLOW = Vector3.new(255, 255, 90)
local COLOR_PURPLE = Vector3.new(255, 0, 255)
local COLOR_LIGHT_PURPLE = Vector3.new(255, 90, 255)
local COLOR_TEAL = Vector3.new(0, 255, 255)
local COLOR_LIGHT_TEAL = Vector3.new(90, 255, 255)

-- //UI Values
local anglerWarning = false
local wallDwellerWarning = false
local fakeDoorWarning = false
local voidLockerWarning = false
local moneyESP = false
local itemESP = false
local keycardESP = false
local searchlightsHelp = false
local WDITDToggle = false
local extraCarefulHelp = false
local renderDistance = 0
local currentRoomOnly = false
local WindowName = "It Just Works: Pressure"

-- //Name Sets/Display Names
-- name set for Angler variants
local anglerNameSet = {}
for _, name in pairs(ANGLER_VARIANTS) do
    anglerNameSet[name] = true
end

-- name set for fake doors
local fakeDoorNameSet = {}
for _, name in pairs(FAKE_DOOR_NAMES) do
    fakeDoorNameSet[name] = true
end

-- name set for unique currencies
local currencyNameSet = {}
for _, name in pairs(CURERNCY_NAMES) do
    currencyNameSet[name] = true
end

-- name set for keys
local keycardNameSet = {}
for _, name in pairs(KEYCARD_NAMES) do
    keycardNameSet[name] = true
end

-- name set for normal items
local itemNameSet = {}
for _, name in pairs(ITEM_NAMES) do
    itemNameSet[name] = true
end

-- name set for WDITD items
local noLightsNameSet = {}
for _, name in pairs(ITEM_NAMES_NO_LIGHTS) do
    noLightsNameSet[name] = true
end

-- display names for items
local itemDisplayNames = {
    ["RoomsBattery"] = "Battery",
    ["DefaultBattery1"] = "Battery",
    ["DefaultBattery2"] = "Battery",
    ["DefaultBattery3"] = "Battery",
    ["AltBattery1"] = "Battery",
    ["AltBattery2"] = "Battery",
    ["AltBattery3"] = "Battery",
    ["SmallLantern"] = "Lantern",
    ["BigFlashBeacon"] = "Flash Beacon",
    ["FlashBeacon"] = "Flash Beacon",
    ["CrateMedkit"] = "Medkit",
    ["HealthBoost"] = "Cocktail 'Perithesene'",
    ["CrateHealthBoost"] = "Cocktail 'Perithesene'",
    ["Defib"] = "Defibrillator",
    ["CrateDefib"] = "Defibrillator",
    ["DoubleSprint"] = "SPRINT x2",
    ["CrateCodeBreacher"] = "Code Breacher",
    ["CodeBreacher"] = "Code Breacher"
}

-- //Caches
local currencyCache = {}
local itemPosCache = {}
local itemNameCache = {}
local keycardCache = {}
local monsterLockerCache = {}
local fakeDoorCache = {}
local generatorCache = {}
local wallDwellerCache = {}

-- //Generic Methods

-- returns the player's current position
local function playerPosition()
    if not LOCAL_PLAYER then return end
    local HumanoidRootPart = LOCAL_PLAYER:FindFirstChild("HumanoidRootPart")
    local playerPosition = HumanoidRootPart:GetPartPosition() 
    return playerPosition
end

-- returns the current room's folder
local function currentRoom()
    local rooms = ROOMS_FOLDER:Children()
    local currentRoom = rooms[#rooms - 1]
    return currentRoom
end

-- returns the distance between two positions, might rework it so it only needs the part instead of the position
local function Distance(positionOne, positionTwo)
    if not positionOne or not positionTwo then return nil end
    if not positionOne.z or not positionTwo.z then return nil end


    local distanceX = positionOne.x - positionTwo.x
    local distanceY = positionOne.y - positionTwo.y
    local distanceZ = positionOne.z - positionTwo.z
    local distance = math.sqrt(distanceX * distanceX + distanceY * distanceY + distanceZ * distanceZ)
    return distance
end

-- takes a cache/array and displays the provided label or the label in the same position of a different cache/array in the provided color
local function renderHighlights(cache, labelOrCache, color)
    local playerPos = playerPosition()
    if not playerPos then return end
    
    local hasLabelCache = type(labelOrCache) == table
    for _, pos in ipairs(cache) do
        local screenPos = utils.WTS(pos)
        if screenPos.x > 0 then
            if renderDistance == 0 or Distance(playerPos, pos) <= renderDistance then
                local labelText = hasLabelCache and labelOrCache[i] or labelOrCache
                if labelText then
                    Rendering.DrawText(screenPos, color, 255, labelText, 10)
                end
            end
        end
    end
end

-- checks if a searchlights encounter generator is broken.
local function generatorBrokenCheck(generatorModel)
    local generatorFixedValue = generatorModel:FindFirstChild("Fixed")
    if not generatorFixedValue then return end
    local fixedValueAddress = generatorFixedValue.Address
    if not fixedValueAddress then return end
    local fixedIntValue = utils.ReadMemory("Int", fixedValueAddress + VALUE_OFFSET)
    return fixedIntValue < 100
end

-- updates the searchlights encounter generator cache
local function updateGeneratorCache()
    generatorCache = {}

    local encounterRoom = ROOMS_FOLDER:FindFirstChild("SearchlightsEncounter")
    local endingRoom = ROOMS_FOLDER:FindFirstChild("SearchlightsEnding")
    local current = currentRoom()
    if not current then return end
    
    local targetRoom
    local generatorType

    if encounterRoom and current.Name == encounterRoom.Name then
        targetRoom = encounterRoom
        generatorType = "Generator"
    elseif endingRoom and current.Name == endingRoom.Name then
        targetRoom = endingRoom
        generatorType = "PresetGenerator"
    else
        return
    end

    local interactables = targetRoom:FindFirstChild("Interactables")
    if not interactables then return end

    for _, model in ipairs(interactables:GetChildren()) do
        if model.Name == generatorType and generatorBrokenCheck(model) then
            local proxy = model:FindFirstChild("ProxyPart")
            if proxy then
                local pos = proxy:GetPartPosition()
                if pos then
                    table.insert(generatorCache, pos)
                end
            end
        end
    end
end

local function buildCache(targetCache, opts)
    --[[
        roomOnly = bool
        nestedCheck = bool
        filterFn = function(model):bool
        nameMap = optional table (used for item display names)
    ]]
    
    for k in pairs(targetCache) do
        targetCache[k] = nil
    end

    local rooms = opts.roomOnly and { currentRoom() } or ROOMS_FOLDER:GetChildren()

    for _, room in ipairs(rooms) do
        for _, model in ipairs(room:GetChildren()) do
            if model.ClassName == "Model" then
                local spawnFolder = model:FindFirstChild("SpawnLocations")
                if spawnFolder then
                    for _, spawn in ipairs(spawnFolder:GetChildren()) do
                        local modelToCheck = opts.nestedCheck and spawn:FindFirstChildOfclass("Model")
                        if modelToCheck and opts.filterFn(modelToCheck) then
                            local pos = spawn:GetPartPosition()
                            if pos then
                                table.insert(targetCache, playerPosition)

                                -- fill the item name cache too
                                if targetCache == itemPosCache then
                                    local rawName = modelToCheck.Name
                                    local displayName = (opts.nameMap and opts.nameMap[rawName]) or rawnName
                                    table.insert(itemNameCache, displayName)
                                end
                            end
                        end
                    end
                end
            end
        end
    end
end

local function updateFakeDoorCache()
    fakeDoorCache = {}

    local rooms = currentRoomOnly and { currentRoom() } or ROOMS_FOLDER:GetChildren()

    for _, room in ipairs(rooms) do
        for _, model in ipairs(room) do
            if fakeDoorNameSet[model.Name] then
                local interactables = model:FindFirstChild("Interactables")
                if interactables then
                    local trickster = interactables:FindFirstChild("Trickster")
                    if trickster then
                        local tricksterDoor = trickster:FindFirstChild("TricksterDoor")
                        if tricksterDoor then
                            local root = tricksterDoor:FindFirstChild("Root")
                            if root then
                                local pos = root:GetPartPosition()
                                if pos then
                                    table.insert(fakeDoorCache, pos)
                                end
                            end
                        end
                    end
                end
            end
        end
    end
end

local function updateMonsterLockerCache()
    monsterLockerCache = {}
    local rooms = currentRoomOnly and { currentRoom() } or ROOMS_FOLDER:GetChildren()

    for _, room in ipairs(rooms) do
        for _, model in ipairs(room:GetChildren()) do
            if model.Name == "MonsterLocker" then
                local collision = model:FindFirstChild("LockerCollision")
                if collision then
                    local pos = collision:GetPartPosition()
                    if pos then
                        table.insert(monsterLockerCache, pos)
                    end
                end
            end
        end    
    end
end

local function updateItemCache()
    itemPosCache = {}
    itemNameCache = {}

    buildCache(itemPosCache, {
        roomOnly = currentRoomOnly,
        nestedCheck = true,
        nameMap = itemDisplayNames,
        filterFn = function(model)
            local name = model.Name
            if WDITDToggle then
                return noLightsNameSet[name]
            else
                return itemNameSet[name]
            end
        end
    })
end

local function updateKeycardCache()
    buildCache(keycardCache, {
        roomOnly = currentRoomOnly, 
        nestedCheck = true, 
        filterFn = function(model)
            return keycardNameSet[model.Name]
        end
    })
end

local function updateCurrencyCache()
    buildCache(currencyCache, {
        roomOnly = currentRoomOnly, 
        nestedCheck = true, 
        filterFn = function(model)
            return currencyNameSet[model.Name]
        end
    })
end

local function WDITDCheck()
    local player = LOCAL_PLAYER.Character
    if not player then return end

    local playerFolder = player:FindFirstChild("PlayerFolder")
    if not playerFolder then return end

    local hadLightStore = playerFolder:FindFirstChild("HadLightSource")
    if not hadLightStore then return end

    local address = hadLightStore.Address
    if not address then return end

    local value = utils.ReadMemory("Int", address + VALUE_OFFSET)
    return value == 1
end

local function WDITDHelp()
    local success = WDITDCheck()
    if success == nil then return end

    local text = success and "WDITD Good :3" or "WDITD Failed D:"
    local color = success and COLOR_GREEN or COLOR_RED

    Rendering.DrawText(Vector2.new(20, SCREEN_SIZE.y - 300), color, 255, text, 33)
end

local extraCarefulFailed = false

local function CarefulHelp()
    if extraCarefulFailed then
        Rendering.DrawText(Vector2.new(20, SCREEN_SIZE.y - 335), COLOR_RED, 255, "Extra Careful Failed D:", 33)
        return
    end

    local player = LOCAL_PLAYER.Character
    if not player then return end
    local folder = player:FindFirstChild("PlayerFolder")
    if not folder then return end
    local health = folder:FindFirstChild("Health")
    if not health then return end
    local address = health.Address
    if not address then return end
    local hp = utils.ReadMemory("Int", address + VALUE_OFFSET)
    if hp < 100 then
        extraCarefulFailed = true
        Rendering.DrawText(Vector2.new(20, SCREEN_SIZE.y - 335), COLOR_RED, 255, "Extra Careful Failed D:", 33)
    else
        Rendering.DrawText(Vector2.new(20, SCREEN_SIZE.y - 335), COLOR_RED, 255, "Extra Careful Good :3", 33)
    end
end

local function updateWallDwellerCache()
    local monsters = GAMEPLAY_FOLDER:FindFirstChild("Monsters")
    if not monsters then
        wallDwellerCache = nil
        return
    end

    local dweller = monsters:FindFirstChild("DiVineRoot")
    wallDwellerCache = dweller or nil
end

local function wallDwellerWarn()
    local dweller = wallDwellerCache
    if not dweller then return end

    local humanoidRootPart = dweller:FindFirstChild("HumanoidRootPart")
    if not humanoidRootPart then return end

    local pos = humanoidRootPart:GetPartPosition()
    if not pos then return end
    local screenX = SCREEN_SIZE.x / 2 - 100
    local ScreenY = SCREEN_SIZE.y - 210
    local playerPos = playerPosition()
    local distance = Distance(playerPos, pos)
    Rendering.drawText(Vector2.new(screenX, screenY), COLOR_WHITE, 255, "Wall Dweller: " .. math.floor(distance),  33)
end

local function anglerWarn()
    local playerPos = playerPosition()
    if not playerPos then return end
    local screenX = SCREEN_SIZE.x / 2 - 100
    local screenY = SCREEN_SIZE.y - 140

    for _, anglerPart in pairs(WORKSPACE:GetChildren()) do
        local className = anglerPart.ClassName
        if className == "Part" then
            local anglerType = anglerPart.Name
            if anglerNameSet[anglerType] then
                local anglerPos = anglerPart:GetPartPosition()
                local distance = Distance(anglerPos, playerPos)
                local warnText = anglerType .. ": " .. math.floor(distance)
                Rendering.DrawText(Vector2.new(screenX, screeenY), COLOR_YELLOW, 255, warnText, 33)
            end
        end
    end
end


Events.SetCallback("PlayerCache", function()
    if wallDwellerWarning then
        updateWallDwellerCache()
    end
    if fakeDoorWarning then
        updateFakeDoorCache()
    end
    if voidLockerWarning then
        updateMonsterLockerCache()
    end
    if moneyESP then
        updateCurrencyCache()
    end
    if itemESP then
        updateItemCache()
    end
    if keycardESP then
        updateKeycardCache()
    end
    if searchlightsHelp then
        updateGeneratorCache()
    end
end)

Events.SetCallback("Paint", function()
    if anglerWarning then
        anglerWarn()
    end
    if wallDwellerWarning then
        wallDwellerWarn()
    end
    if fakeDoorWarning then
        renderHighlights(fakeDoorCache, "Fake Door", COLOR_RED)
    end
    if voidLockerWarning then
        renderHighlights(monsterLockerCache, "Void Locker", COLOR_PURPLE)
    end
    if moneyESP then
        renderHighlights(currencyCache, "Currency", COLOR_WHITE)
    end
    if itemESP then
        renderHighlights(itemPosCache, itemNameCache, COLOR_GREEN)
    end
    if keycardESP then
        renderHighlights(keycardCache, "Keycard", COLOR_TEAL)
    end
    if searchlightsHelp then
        renderHighlights(generatorCache, "Broken Generator", COLOR_LIGHT_RED)
    end
    if WDITDToggle then
        WDITDHelp()
    end
    if extraCarefulHelp then
        CarefulHelp()
    end
end)

Imgui.Setnextwindowsize(350, 350)
if Imgui.Beginwindow(WindowName, 0) then
    Imgui.Separator()
    Imgui.Begingroup(WindowName, "uhh fish joke or something", 0, 0, 1)
    Imgui.Sliderfloat(WindowName, "Render Distance (0 for inf)", 0, 1000, renderDistance, "%.1f", function(v)
        renderDistance = v
    end)
    Imgui.Checkbox(WindowName, "Current Room Only", currentRoomOnly, function(v)
        currentRoomOnly = v
    end)
    Imgui.Text("Warnings")
    Imgui.Checkbox(WindowName, "Angler Warning", anglerWarning, function(v)
        anglerWarning = v
    end)
    Imgui.Checkbox(WindowName, "Wall Dweller Warning", wallDwellerWarning, function(v)
        wallDwellerWarning = v
    end)
    Imgui.Checkbox(WindowName, "Fake Door Warning", fakeDoorWarning, function(v)
        fakeDoorWarning = v
    end)
    Imgui.Checkbox(WindowName, "Void Locker Warning", voidLockerWarning, function(v)
        voidLockerWarning = v
    end)
    Imgui.Text("ESPs")
    Imgui.Checkbox(WindowName, "Money ESP", moneyESP, function(v)
        moneyESP = v
    end)
    Imgui.Checkbox(WindowName, "Item ESP", itemESP, function(v)
        itemESP = v
    end)
    Imgui.Checkbox(WindowName, "Keycard ESP", keycardESP, function(v)
        keycardESP = v
    end)
    Imgui.Checkbox(WindowName, "Searchlights Generator ESP", searchlightsHelp, function(v)
        searchlightsHelp = v
    end)
    Imgui.Text("Helpers")
    Imgui.Checkbox(WindowName, "We Die In The Dark Helper", WDITDToggle, function(v)
        WDITDToggle = v
    end)
    Imgui.Checkbox(WindowName, "Extra Careful Helper", extraCarefulHelp, function(v)
        extraCarefulHelp = v
    end)
    Imgui.Endgroup()
    Imgui.Endwindow()
end