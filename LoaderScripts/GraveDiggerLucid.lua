--[[    
    +========Features========+
    Dreadnought Highlighting [DONE-ish]
        Dreadnought Highlight Team Colors [DONE]
        Dreadnought Boss Bar [UNDOABLE AT THE MOMENT]
    Shock Trooper Highlighting [DONE-ish]
    Shock Kit Highlighting [NEEDS TESTING]
    TP To Shock Kit [NEEDS TESTING]
    TP To Control Point [NEEDS TESTING]
    +========================+
]]


-- //Constants
local WORKSPACE = Globals.Workspace()
local LOCAL_PLAYER = Globals:LocalPlayer()
local NATION_FOLDER = WORKSPACE:FindFirstChild("nation_team")
local EMPIRE_FOLDER = WORKSPACE:FindFirstChild("empire_team")
local SERVER_FOLDER = WORKSPACE:FindFirstChild("serverDtuff")
local GAME_SETUP = SERVER_FOLDER:FindFirstChild("game_setup")
local VALUE_OFFSET = 0xD0
local POSITION_OFFSET = 0xE4

-- //Colors
local COLOR_NATION_PURPLE = Vector3.new(192, 0, 255)
local COLOR_EMPIRE_YELLOW = Vector3.new(241, 234, 0)
local COLOR_RED = Vector3.new(255, 0, 0)
local COLOR_BLACK = Vector3.new(0, 0, 0)
local COLOR_DEEP_RED = Vector3.new(93, 0, 0)
local COLOR_DARK_GREY = Vector3.new(93, 93, 93)
local COLOR_WHITE = Vector3.new(255, 255, 255)

-- //UI stuff
local highlightDread = false
local dreadTeamColors = false
local dreadBossBar = false
local highlightShocks = false
local highlightKits = false
local tpControlKitOne = false
local tpControlKitTwo = false
local tpPointOne = false
local tpPointTwo = false
local tpPointThree = false
local tpPointFour = false
local tpPointFive = false
local WindowName = "It Just Works: Grave/Digger"

-- //Caches
local dreadObject = nil
local dreadPlayer = nil
local dreadTeam = nil
local dreadTorso = nil
local shockModelCache = {}
local shockTeamsCache = {}
local shockClassCache = {}
local shockTorsoCache = {}
local shockKitCache = {}

-- //Generic Functions

--takes a StringValue and returns it's value
local function ValueCheck(toCheck)
    local addressToCheck = toCheck.Address
    if toCheck.ClassName == "StringValue" then
        return utils.ReadMemory("String", addressToCheck + VALUE_OFFSET)
    end
end

-- //Cache Functions
local function dreadnoughtCacher()
    dreadObject = nil
    dreadPlayer = nil
    dreadTeam = nil
    dreadTorso = nil

    local players = Globals:CachedPlayers()
    for _, player in ipairs(players) do
        if player.MaxHealth >= 500 and player.Health > 0 then
            dreadObject = player.Character
            dreadPlayer = player.Name
            dreadTeam = dreadObject:GetParent()
            break
        end
    end

    if dreadPlayer then
        if not dreadObject then return end
        local torso = dreadObject:FindFirstChild("HumanoidRootPart")
        if not torso then return end
        dreadTorso = torso
    end
end

local function dreadnoughtHighlight()
    if not dreadTorso then return end
    local dreadPos = dreadTorso:GetPartPosition()
    if not dreadPos then return end

    local dreadScreenPos = utils.WTS(dreadPos)
    if not dreadScreenPos then return end
    if dreadScreenPos.x <= 0 then return end
    if dreadTeamColors then
        if dreadTeam == NATION_FOLDER then
            Rendering.DrawRect(dreadScreenPos, Vector2.new(10, 10), COLOR_NATION_PURPLE, 240, 0, 20)
        elseif dreadTeam == EMPIRE_FOLDER then
            Rendering.DrawRect(dreadScreenPos, Vector2.new(10, 10), COLOR_EMPIRE_YELLOW, 200, 0, 20)
        end
    else
        Rendering.DrawRect(dreadScreenPos, Vector2.new(10, 10), COLOR_RED, 255, 0, 20)
    end
    Rendering.DrawText(dreadScreenPos, COLOR_WHITE, 255, "D", 20)
end

local function shockCacher()
    shockModelCache = {}
    shockTeamsCache = {}
    shockClassCache = {}
    shockTorsoCache = {}

    local players = Globals:CachedPlayers()
    for _, player in ipairs(players) do
        if player.MaxHealth >= 300 and player.Health > 0 then
            local character = player.Character
            table.insert(shockModelCache, character)
        end
    end
    for i = 1, #shockModelCache do
        local tempShockModel = shockModelCache[i]
        table.insert(shockTeamsCache, tempShockModel:GetParent())
        local eliteKitValue = tempShockModel:FindFirstChild("elitekit")
        if not eliteKitValue then return end
        local shockClass = ValueCheck(eliteKitValue)
        if not shockClass then return end
        table.insert(shockClassCache, shockClass)
        local shockModel = shockModelCache[i]
        local shockTorso = shockModel:FindFirstChild("Torso")
        table.insert(shockTorsoCache, shockTorso)
    end
end

--Will add icons when textures and http features are available in lucid, or if text is fixed I'll use abbreviations (AT, ST, TT, etc.)
local function shockHighlight()
    for i = 1, #shockTorsoCache do
        local shockTorso = shockTorsoCache[i]
        local shockPos = shockTorso:GetPartPosition()
        if not shockPos then return end
        local shockScreenPos = utils.WTS(shockPos)
        if not shockScreenPos then return end
        if shockTeamsCache[i] == NATION_FOLDER then
            Rendering.DrawRect(shockScreenPos, Vector2.new(10, 10), COLOR_NATION_PURPLE, 240, 0, 15)
        elseif shockTeamsCache[i] == EMPIRE_FOLDER then
            Rendering.DrawRect(shockScreenPos, Vector2.new(10, 10), COLOR_EMPIRE_YELLOW, 200, 0, 15)
        end
    end
end

local function shockKitCacher()
    local valuesFolder = SERVER_FOLDER:FindFirstChild("values")
    if not valuesFolder then return end
    local gamemodeValue = valuesFolder:FindFirstChild("gamemode")
    if not gamemodeValue then return end
    local currentGamemode = ValueCheck(gamemodeValue)
    if not currentGamemode then return end
    if currentGamemode == "control" then
        local kitOne = GAME_SETUP:FindFirstChild("elite_kit1")
        local kitTwo = GAME_SETUP:FindFirstChild("elite_kit2")
        if not kitOne and kitTwo then return end
        local clickOne = kitOne:FindFirstChild("click")
        local clickTwo = kitTwo:FindFirstChild("click")
        if not clickOne and clickTwo then return end
        local clickOnePos = clickOne:GetPartPosition()
        local clickTwoPos = clickTwo:GetPartPosition()
        if not clickOnePos and clickTwoPos then return end
        table.insert(shockKitCache, clickOnePos)
        table.insert(shockKitCache, clickTwoPos)
    else
        for _, model in ipairs(GAME_SETUP:GetChildren()) do
            if model.ClassName == "model" and model.Name == "elitecrate" then
                local crateClick = model:FindFirstChild("click")
                if not crateClick then return end
                local crateClickPos = crateClick:GetPartPosition()
                if not crateClickPos then return end
                table.insert(shockKitCache, crateClickPos)
            end
        end
    end
end

local function highlightShockKits()
    for i = 1, #shockKitCache do
        local kitScreenPos = utils.WTS(shockKitCache[i])
        if not kitScreenPos then return end
        Rendering.DrawCircle(kitScreenPos, 15, 3, COLOR_WHITE, 255, 10)
    end
end

local function tpToKit(selection)
    local HRP = LOCAL_PLAYER:FindFirstChild("HumanoidRootPart")
    if not HRP then return end
    local HRPMemAddress = HRP.Address
    if not HRPMemAddress then return end
    local kitOne = GAME_SETUP:FindFirstChild("elite_kit1")
    local kitTwo = GAME_SETUP:FindFirstChild("elite_kit2")
    if not kitOne and kitTwo then return end
    local clickOne = kitOne:FindFirstChild("click")
    local clickTwo = kitTwo:FindFirstChild("click")
    if not clickOne and clickTwo then return end
    local clickOnePos = clickOne:GetPartPosition()
    local clickTwoPos = clickTwo:GetPartPosition()
    if not clickOnePos and clickTwoPos then return end
    local tpOnePos = Vector3.new(clickOnePos.x, clickOnePos.y + 5, clickOnePos.z)
    local tpTwoPos = Vector3.new(clickTwoPos.x, clickTwoPos.y + 5, clicktwoPos.z)
    if not tpOnePos and tpTwoPos then return end
    if selection == "one" then
        utils.WriteMemory("Vector3", HRPMemAddress + POSITION_OFFSET, tpOnePos)
    elseif selection == "two" then
        utils.WriteMemory("Vector3", HRPMemAddress + POSITION_OFFSET, tpTwoPos)
    end
end

local function tpToPoint(selection)
    local HRP = LOCAL_PLAYER:FindFirstChild("HumanoidRootPart")
    if not HRP then return end
    local HRPMemAddress = HRP.Address
    if not HRPMemAddress then return end
    local objectivesFolder = SERVER_FOLDER:FindFirstChild("objectives")
    if not objectivesFolder then return end
    local pointToTp = nil
    if selection == 1 then pointToTp = objectivesFolder:FindFirstChild("objectiveA") end
    if selection == 2 then pointToTp = objectivesFolder:FindFirstChild("objectiveB") end
    if selection == 3 then pointToTp = objectivesFolder:FindFirstChild("objectiveC") end
    if selection == 4 then pointToTp = objectivesFolder:FindFirstChild("objectiveD") end
    if selection == 5 then pointToTp = objectivesFolder:FindFirstChild("objectiveE") end
    local pointCapture = pointToTp:FindFirstChild("capture")
    if not pointCapture then return end
    local pointCapturePos = pointCapture:GetPartPosition()
    if not pointCapturePos then return end
    utils.WriteMemory("Vector3", HRPMemAddress + POSITION_OFFSET, pointCapture)
end

Events.SetCallback("PlayerCache", function()
    if highlightDread then
        dreadnoughtCacher()
    end
    if highlightShocks then
        shockCacher()
    end
    if highlightKits then
        shockKitCacher()
    end
end)

Events.SetCallback("Paint", function()
    if highlightDread then
        dreadnoughtHighlight()
    end
    if highlightShocks then
        shockHighlight()
    end
    if highlightKits then
        highlightShockKits()
    end
    if tpControlKitOne then
        tpToKit("one")
    end
    if tpControlKitTwo then
        tpToKit("two")
    end
    if tpPointOne then
        tpToPoint(1)
    end
    if tpPointTwo then
        tpToPoint(2)
    end
    if tpPointThree then
        tpToPoint(3)
    end
    if tpPointFour then
        tpToPoint(4)
    end
    if tpPointFive then
        tpToPoint(5)
    end
end)

Imgui.Setnextwindowsize(350, 350)
if Imgui.Beginwindow(WindowName, 0) then
    Imgui.Separator()
    Imgui.Begingroup(WindowName, "Digging my grave fr fr ong", 0, 0, 1)
    Imgui.Checkbox(WindowName, "Highlight Dreadnaught", highlightDread, function(v)
        highlightDread = v
    end)
    Imgui.Checkbox(WindowName, "Dreadnought Team Colors", dreadTeamColors, function(v)
        dreadTeamColors = v
    end)
    Imgui.Checkbox(WindowName, "Dreadnaught Boss Bar (UNUSED)", dreadBossBar, function(v)
        dreadBossBar = v
    end)
    Imgui.Checkbox(WindowName, "Highlight Shock Troopers", highlightShocks, function(v)
        highlightShocks = v
    end)
    Imgui.Checkbox(WindowName, "Highlight Shock Kits", highlightKits, function(v)
        highlightKits = v
    end)
    Imgui.Button(WindowName, "TP to Control Kit 1", tpControlKitOne, function(v)
        tpControlKitOne = v
    end)
    Imgui.Button(WindowName, "TP to Control Kit 2", tpControlKitTwo, function(v)
        tpControlKitTwo = v
    end)
    Imgui.Button(WindowName, "TP to Point Alfa", tpPointOne, function(v)
        tpPointOne = v
    end)
    Imgui.Button(WindowName, "TP to Point Bravo", tpPointTwo, function(v)
        tpPointTwo = v
    end)
    Imgui.Button(WindowName, "TP to Point Charlie", tpPointThree, function(v)
        tpPointThree = v
    end)
    Imgui.Button(WindowName, "TP to Point Delta", tpPointFour, function(v)
        tpPointFour = v
    end)
    Imgui.Button(WindowName, "TP to Point Echo", tpPointFive, function(v)
        tpPointFive = v
    end)
    Imgui.Button(WindowName,"close",function()
        highlightDread = false
        dreadTeamColors = false
        highlightShocks = false
        highlightKits = false
        Imgui.ClearAllWindows()
    end)
    Imgui.Endgroup()
    Imgui.Endwindow()
end
