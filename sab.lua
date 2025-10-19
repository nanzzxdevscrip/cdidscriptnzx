-- AUTO GIFT PET (Client-side fuzzing) for Delta / Arceus X / Hydrogen
-- Target username:
local TARGET_USERNAME = "Natoaji"

-- Configuration
local AUTO_SEND = true         -- mulai aktif otomatis
local INTERVAL = 1.2           -- delay antar percobaan (detik)
local MAX_ATTEMPTS_PER_REMOTE = 6
local VERBOSE = true           -- true -> print log di output rconsole

-- helper: safe print to rconsole if available
local function log(...)
    local s = table.concat({...}, " ")
    if VERBOSE then
        if rconsoleprint then
            rconsoleprint(s .. "\n")
        else
            print(s)
        end
    end
end

-- find all candidate RemoteEvent / RemoteFunction instances under a parent
local function findRemotes(root)
    local remotes = {}
    local function scan(parent)
        for _, v in pairs(parent:GetChildren()) do
            local t = typeof(v)
            if v:IsA("RemoteEvent") or v:IsA("RemoteFunction") then
                table.insert(remotes, v)
            end
            -- sometimes modules or folders contain more
            if #v:GetChildren() > 0 then
                pcall(scan, v)
            end
        end
    end
    pcall(scan, root)
    return remotes
end

-- common guess payloads patterns to try per remote
local function generatePayloads(localPlayer)
    local plyName = localPlayer.Name
    local plyId = localPlayer.UserId
    local targetName = TARGET_USERNAME

    -- common pet identifiers used by games (change if you know specific pet id/name)
    local petNames = {
        "Pet", "BasicPet", "Chicken", "Egg", "Pet1", "DefaultPet", "Pet_Template",
        "natoaji_pet", "natoaji", "NatoajiPet"
    }

    -- build payload patterns (array of argument lists)
    local payloads = {}

    -- 1) (targetUsername, petName)
    for _, pet in ipairs(petNames) do
        table.insert(payloads, {targetName, pet})
    end

    -- 2) (targetUserId, petName)
    for _, pet in ipairs(petNames) do
        table.insert(payloads, {0 + 0 + (tonumber(TARGET_USERNAME) or 0), pet}) -- no-op; kept for structure
        table.insert(payloads, {plyId, pet}) -- attempt gifting to self (some remotes expect userId)
    end

    -- 3) (targetUsername) or (targetUserId)
    table.insert(payloads, {targetName})
    table.insert(payloads, {plyId})

    -- 4) (petName) or (petId)
    for _, pet in ipairs(petNames) do
        table.insert(payloads, {pet})
    end

    -- 5) (targetUsername, petId, extra) common in some games
    for _, pet in ipairs(petNames) do
        table.insert(payloads, {targetName, pet, true})
        table.insert(payloads, {targetName, pet, plyName})
    end

    -- 6) (targetUserId, petId, quantity)
    for _, pet in ipairs(petNames) do
        table.insert(payloads, {plyId, pet, 1})
        table.insert(payloads, {0, pet, 1})
    end

    -- 7) Entire table payloads often used
    table.insert(payloads, {{to=targetName, pet="BasicPet"}})
    table.insert(payloads, {{userId=plyId, giftTo=targetName, pet="BasicPet"}})

    return payloads
end

-- attempt to call remote with different call types
local function tryCall(remote, payload, isFunction)
    local ok, err
    if remote:IsA("RemoteEvent") then
        ok, err = pcall(function() remote:FireServer(table.unpack(payload)) end)
    else
        -- RemoteFunction
        ok, err = pcall(function() remote:InvokeServer(table.unpack(payload)) end)
    end
    return ok, err
end

-- main worker
local Players = game:GetService("Players")
local localPlayer = Players.LocalPlayer

if not localPlayer then
    log("Error: LocalPlayer not found. Jalankan di dalam game.")
    return
end

log(("AutoGift started. Target: %s  Interval: %.2fs"):format(TARGET_USERNAME, INTERVAL))

-- build candidate remotes list (search common service parents)
local searchRoots = {
    game:GetService("ReplicatedStorage"),
    workspace,
    game:GetService("StarterGui"),
    game:GetService("Players"),
    game:GetService("ServerScriptService"), -- sometimes exploitable clients can still see client references
}
local remotes = {}
for _, root in ipairs(searchRoots) do
    for _, r in ipairs(findRemotes(root)) do
        table.insert(remotes, r)
    end
end

-- also try to look for common named objects directly
local commonNames = {
    "GiftPet", "GivePet", "RemoteGift", "SendPet", "EquipPet", "BuyPet",
    "PurchasePet", "TradePet", "PetRemote", "PetEvent", "PetService", "RemoteEvent"
}
for _, name in ipairs(commonNames) do
    local r = game:GetService("ReplicatedStorage"):FindFirstChild(name, true)
    if r and (r:IsA("RemoteEvent") or r:IsA("RemoteFunction")) then
        table.insert(remotes, r)
    end
end

-- dedupe remotes by Instance
local seen = {}
local uniqueRemotes = {}
for _, r in ipairs(remotes) do
    if r and not seen[r] then
        seen[r] = true
        table.insert(uniqueRemotes, r)
    end
end
remotes = uniqueRemotes

if #remotes == 0 then
    log("Tidak menemukan RemoteEvent/RemoteFunction di scan awal. Script akan tetap tetap memeriksa ReplicatedStorage secara periodik.")
end

-- prepare payloads
local payloads = generatePayloads(localPlayer)

-- toggle with RightControl
local UserInputService = game:GetService("UserInputService")
UserInputService.InputBegan:Connect(function(input, processed)
    if processed then return end
    if input.KeyCode == Enum.KeyCode.RightControl then
        AUTO_SEND = not AUTO_SEND
        log("AUTO_SEND toggled ->", AUTO_SEND and "ON" or "OFF")
    end
end)

-- background loop
spawn(function()
    while true do
        if AUTO_SEND then
            -- refresh remotes occasionally
            if #remotes == 0 then
                for _, root in ipairs(searchRoots) do
                    for _, r in ipairs(findRemotes(root)) do
                        if not seen[r] then
                            seen[r] = true
                            table.insert(remotes, r)
                            log("New remote found: ", r:GetFullName())
                        end
                    end
                end
            end

            for _, remote in ipairs(remotes) do
                if not AUTO_SEND then break end
                if not remote or not remote.Parent then
                    -- ignore
                else
                    local isFunction = remote:IsA("RemoteFunction")
                    log("Trying remote:", remote:GetFullName(), "(" .. (isFunction and "Function" or "Event") .. ")")

                    local attempts = 0
                    for _, payload in ipairs(payloads) do
                        if attempts >= MAX_ATTEMPTS_PER_REMOTE then break end
                        if not AUTO_SEND then break end

                        attempts = attempts + 1
                        local ok, err = tryCall(remote, payload, isFunction)
                        if ok then
                            log(("Attempt OK -> remote:%s payload:%s"):format(remote.Name, tostring(payload[1] or "<table>")))
                        else
                            log(("Attempt FAIL -> remote:%s err:%s"):format(remote.Name, tostring(err)))
                        end
                        task.wait(INTERVAL)
                    end
                end
            end
        end
        task.wait(1)
    end
end)
