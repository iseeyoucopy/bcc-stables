local VORPcore = {}
local VORPutils = {}
local PlayerJob
local JobName
local JobGrade
local InMenu = false
local OpenShop
local ReturnShop
local ClosedShop
local Adding = true
local ShowroomHorse_entity
local ShowroomHorse_model
local SpawnPoint = {}
local MyHorse_entity
local IdMyHorse
local Saddlecloths = {}
local Acshorn = {}
local Bags = {}
local Horsetails = {}
local Manes = {}
local Saddles = {}
local Stirrups = {}
local Acsluggage = {}
local SpawnplayerHorse = 0
local HorseModel
local HorseName
local HorseComponents = {}
local Initializing = false
local SaddlesUsing = nil
local SaddleclothsUsing = nil
local StirrupsUsing = nil
local BagsUsing = nil
local ManesUsing = nil
local HorseTailsUsing = nil
local AcsHornUsing = nil
local AcsLuggageUsing = nil

TriggerEvent("getCore", function(core)
    VORPcore = core
end)

TriggerEvent("getUtils", function(utils)
    VORPutils = utils
end)

-- Start Stables
Citizen.CreateThread(function()
    local PromptOpen = VORPutils.Prompts:SetupPromptGroup()
    OpenShop = PromptOpen:RegisterPrompt(_U("shopPrompt"), Config.shopKey, 1, 1, true, 'click')
    ReturnShop = PromptOpen:RegisterPrompt(_U("returnPrompt"), Config.returnKey, 1, 1, true, 'click')

    local PromptClosed = VORPutils.Prompts:SetupPromptGroup()
    ClosedShop = PromptClosed:RegisterPrompt(_U("shopPrompt"), Config.shopKey, 1, 1, true, 'click')

    while true do
        Citizen.Wait(0)
        local player = PlayerPedId()
        local coords = GetEntityCoords(player)
        local sleep = true
        local dead = IsEntityDead(player)
        local hour = GetClockHours()

        if InMenu == false and not dead then
            for shopId, shopConfig in pairs(Config.stables) do
                if shopConfig.shopHours then
                    if hour >= shopConfig.shopClose or hour < shopConfig.shopOpen then
                        if not Config.stables[shopId].BlipHandle and shopConfig.blipAllowed then
                            AddBlip(shopId)
                        end
                        if Config.stables[shopId].BlipHandle then
                            Citizen.InvokeNative(0x662D364ABF16DE2F, Config.stables[shopId].BlipHandle, GetHashKey(shopConfig.blipColorClosed)) -- BlipAddModifier
                        end
                        if shopConfig.NPC then
                            shopConfig.NPC:Remove()
                            shopConfig.NPC = nil
                        end
                        local coordsDist = vector3(coords.x, coords.y, coords.z)
                        local coordsShop = vector3(shopConfig.npcx, shopConfig.npcy, shopConfig.npcz)
                        local distanceShop = #(coordsDist - coordsShop)

                        if (distanceShop <= shopConfig.distanceShop) then
                            sleep = false
                            local shopClosed = CreateVarString(10, 'LITERAL_STRING', _U("closed") .. shopConfig.shopOpen .. _U("am") .. shopConfig.shopClose .. _U("pm"))
                            PromptClosed:ShowGroup(shopClosed)

                            if ClosedShop:HasCompleted() then

                                Wait(100)
                                VORPcore.NotifyRightTip(_U("closed") .. shopConfig.shopOpen .. _U("am") .. shopConfig.shopClose .. _U("pm"), 3000)
                            end
                        end
                    elseif hour >= shopConfig.shopOpen then
                        if not Config.stables[shopId].BlipHandle and shopConfig.blipAllowed then
                            AddBlip(shopId)
                        end
                        if Config.stables[shopId].BlipHandle then
                            Citizen.InvokeNative(0x662D364ABF16DE2F, Config.stables[shopId].BlipHandle, GetHashKey(shopConfig.blipColorOpen)) -- BlipAddModifier
                        end
                        if not shopConfig.NPC and shopConfig.npcAllowed then
                            SpawnNPC(shopId)
                        end
                        if not next(shopConfig.allowedJobs) then
                            local coordsDist = vector3(coords.x, coords.y, coords.z)
                            local coordsShop = vector3(shopConfig.npcx, shopConfig.npcy, shopConfig.npcz)
                            local distanceShop = #(coordsDist - coordsShop)

                            if (distanceShop <= shopConfig.distanceShop) then
                                sleep = false
                                local shopOpen = CreateVarString(10, 'LITERAL_STRING', shopConfig.promptName)
                                PromptOpen:ShowGroup(shopOpen)

                                if OpenShop:HasCompleted() then
                                    DisplayRadar(false)
                                    OpenStable(shopId)

                                elseif ReturnShop:HasCompleted() then
                                    returnHorse(shopId)
                                end
                            end
                        else
                            local coordsDist = vector3(coords.x, coords.y, coords.z)
                            local coordsShop = vector3(shopConfig.npcx, shopConfig.npcy, shopConfig.npcz)
                            local distanceShop = #(coordsDist - coordsShop)

                            if (distanceShop <= shopConfig.distanceShop) then
                                sleep = false
                                local shopOpen = CreateVarString(10, 'LITERAL_STRING', shopConfig.promptName)
                                PromptOpen:ShowGroup(shopOpen)

                                if OpenShop:HasCompleted() then

                                    TriggerServerEvent("oss_stables:GetPlayerJob")
                                    Wait(200)
                                    if PlayerJob then
                                        if CheckJob(shopConfig.allowedJobs, PlayerJob) then
                                            if tonumber(shopConfig.jobGrade) <= tonumber(JobGrade) then
                                                DisplayRadar(false)
                                                OpenStable(shopId)
                                            else
                                                VORPcore.NotifyRightTip(_U("needJob") .. JobName .. " " .. shopConfig.jobGrade, 5000)
                                            end
                                        else
                                            VORPcore.NotifyRightTip(_U("needJob") .. JobName .. " " .. shopConfig.jobGrade, 5000)
                                        end
                                    else
                                        VORPcore.NotifyRightTip(_U("needJob") .. JobName .. " " .. shopConfig.jobGrade, 5000)
                                    end
                                elseif ReturnShop:HasCompleted() then

                                    TriggerServerEvent("oss_stables:GetPlayerJob")
                                    Wait(200)
                                    if PlayerJob then
                                        if CheckJob(shopConfig.allowedJobs, PlayerJob) then
                                            if tonumber(shopConfig.jobGrade) <= tonumber(JobGrade) then
                                                returnHorse(shopId)
                                            else
                                                VORPcore.NotifyRightTip(_U("needJob") .. JobName .. " " .. shopConfig.jobGrade, 5000)
                                            end
                                        else
                                            VORPcore.NotifyRightTip(_U("needJob") .. JobName .. " " .. shopConfig.jobGrade, 5000)
                                        end
                                    else
                                        VORPcore.NotifyRightTip(_U("needJob") .. JobName .. " " .. shopConfig.jobGrade, 5000)
                                    end
                                end
                            end
                        end
                    end
                else
                    if not Config.stables[shopId].BlipHandle and shopConfig.blipAllowed then
                        AddBlip(shopId)
                    end
                    if Config.stables[shopId].BlipHandle then
                        Citizen.InvokeNative(0x662D364ABF16DE2F, Config.stables[shopId].BlipHandle, GetHashKey(shopConfig.blipColorOpen)) -- BlipAddModifier
                    end
                    if not shopConfig.NPC and shopConfig.npcAllowed then
                        SpawnNPC(shopId)
                    end
                    if not next(shopConfig.allowedJobs) then
                        local coordsDist = vector3(coords.x, coords.y, coords.z)
                        local coordsShop = vector3(shopConfig.npcx, shopConfig.npcy, shopConfig.npcz)
                        local distanceShop = #(coordsDist - coordsShop)

                        if (distanceShop <= shopConfig.distanceShop) then
                            sleep = false
                            local shopOpen = CreateVarString(10, 'LITERAL_STRING', shopConfig.promptName)
                            PromptOpen:ShowGroup(shopOpen)

                            if OpenShop:HasCompleted() then
                                DisplayRadar(false)
                                OpenStable(shopId)

                            elseif ReturnShop:HasCompleted() then
                                returnHorse(shopId)
                            end
                        end
                    else
                        local coordsDist = vector3(coords.x, coords.y, coords.z)
                        local coordsShop = vector3(shopConfig.npcx, shopConfig.npcy, shopConfig.npcz)
                        local distanceShop = #(coordsDist - coordsShop)

                        if (distanceShop <= shopConfig.distanceShop) then
                            sleep = false
                            local shopOpen = CreateVarString(10, 'LITERAL_STRING', shopConfig.promptName)
                            PromptOpen:ShowGroup(shopOpen)

                            if OpenShop:HasCompleted() then

                                TriggerServerEvent("oss_stables:GetPlayerJob")
                                Wait(200)
                                if PlayerJob then
                                    if CheckJob(shopConfig.allowedJobs, PlayerJob) then
                                        if tonumber(shopConfig.jobGrade) <= tonumber(JobGrade) then
                                            DisplayRadar(false)
                                            OpenStable(shopId)
                                        else
                                            VORPcore.NotifyRightTip(_U("needJob") .. JobName .. " " .. shopConfig.jobGrade, 5000)
                                        end
                                    else
                                        VORPcore.NotifyRightTip(_U("needJob") .. JobName .. " " .. shopConfig.jobGrade, 5000)
                                    end
                                else
                                    VORPcore.NotifyRightTip(_U("needJob") .. JobName .. " " .. shopConfig.jobGrade, 5000)
                                end
                            elseif ReturnShop:HasCompleted() then

                                TriggerServerEvent("oss_stables:GetPlayerJob")
                                Wait(200)
                                if PlayerJob then
                                    if CheckJob(shopConfig.allowedJobs, PlayerJob) then
                                        if tonumber(shopConfig.jobGrade) <= tonumber(JobGrade) then
                                            returnHorse(shopId)
                                        else
                                            VORPcore.NotifyRightTip(_U("needJob") .. JobName .. " " .. shopConfig.jobGrade, 5000)
                                        end
                                    else
                                        VORPcore.NotifyRightTip(_U("needJob") .. JobName .. " " .. shopConfig.jobGrade, 5000)
                                    end
                                else
                                    VORPcore.NotifyRightTip(_U("needJob") .. JobName .. " " .. shopConfig.jobGrade, 5000)
                                end
                            end
                        end
                    end
                end
            end
        end
        if sleep then
            Citizen.Wait(1000)
        end
    end
end)

function OpenStable(shopId)
    InMenu = true

    local shopConfig = Config.stables[shopId]
    SpawnPoint = {x = shopConfig.spawnPointx, y = shopConfig.spawnPointy, z = shopConfig.spawnPointz, h = shopConfig.spawnPointh}

    createCamera(shopId)

    SetNuiFocus(true, true)
    SendNUIMessage({
        action = "show",
        shopData = getShopData(),
        customize = false
    })
    TriggerServerEvent('oss_stables:GetMyHorses')
end

function getShopData()
    local ret = Config.Horses
    return ret
end

RegisterNetEvent('oss_stables:ReceiveHorsesData')
AddEventHandler('oss_stables:ReceiveHorsesData', function(dataHorses)
    SendNUIMessage({
        myHorsesData = dataHorses
    })
end)

RegisterNUICallback("loadHorse", function(data)
    local horseModel = data.horseModel

    if ShowroomHorse_model == horseModel then
        return
    end

    if MyHorse_entity ~= nil then
        DeleteEntity(MyHorse_entity)
        MyHorse_entity = nil
    end

    local modelHash = GetHashKey(horseModel)

    if IsModelValid(modelHash) then
        if not HasModelLoaded(modelHash) then
            RequestModel(modelHash)
            while not HasModelLoaded(modelHash) do
                Citizen.Wait(10)
            end
        end
    end

    if ShowroomHorse_entity ~= nil then
        DeleteEntity(ShowroomHorse_entity)
        ShowroomHorse_entity = nil
    end

    ShowroomHorse_model = horseModel
    ShowroomHorse_entity = CreatePed(modelHash, SpawnPoint.x, SpawnPoint.y, SpawnPoint.z - 0.98, SpawnPoint.h, false, 0)
    Citizen.InvokeNative(0x283978A15512B2FE, ShowroomHorse_entity, true) -- SetRandomOutfitVariation
    Citizen.InvokeNative(0x58A850EAEE20FAA3, ShowroomHorse_entity) -- PlaceObjectOnGroundProperly
    Citizen.InvokeNative(0x7D9EFB7AD6B19754, ShowroomHorse_entity, true) -- FreezeEntityPosition
    SetPedConfigFlag(ShowroomHorse_entity, 113, true) -- PCF_DisableShockingEvents
    --NetworkSetEntityInvisibleToNetwork(ShowroomHorse_entity, true)

    SendNUIMessage({
        customize = false
    })
end)

RegisterNUICallback("rotate", function(data)
    local direction = data.RotateHorse
    if direction == "left" then
        rotation(-20)
    elseif direction == "right" then
        rotation(20)
    end
end)

function rotation(dir)
    local playerHorse = MyHorse_entity
    local pedRot = GetEntityHeading(playerHorse) + dir
    SetEntityHeading(playerHorse, pedRot % 360)
end

RegisterNUICallback("BuyHorse", function(data)
    SetHorseName(data)
end)

function SetHorseName(data)
    SetNuiFocus(false, false)
    SendNUIMessage({
        action = "hide"
    })
    Wait(200)
    local horseName = ""

	Citizen.CreateThread(function()
		AddTextEntry('FMMC_MPM_NA', "Name your horse:")
		DisplayOnscreenKeyboard(1, "FMMC_MPM_NA", "", "", "", "", "", 30)
		while (UpdateOnscreenKeyboard() == 0) do
			DisableAllControlActions(0)
			Citizen.Wait(0)
		end
		if (GetOnscreenKeyboardResult()) then
            horseName = GetOnscreenKeyboardResult()
            TriggerServerEvent('oss_stables:BuyHorse', data, horseName)

            SetNuiFocus(true, true)
            SendNUIMessage({
                action = "show",
                shopData = getShopData()
            })

        Wait(1000)
        TriggerServerEvent('oss_stables:GetMyHorses')
		end
    end)
end

RegisterNUICallback("loadMyHorse", function(data)
    local horseModel = data.HorseModel
    IdMyHorse = data.IdHorse

    if ShowroomHorse_model == horseModel then
        return
    end

    if ShowroomHorse_entity ~= nil then
        DeleteEntity(ShowroomHorse_entity)
        ShowroomHorse_entity = nil
    end

    if MyHorse_entity ~= nil then
        DeleteEntity(MyHorse_entity)
        MyHorse_entity = nil
    end

    ShowroomHorse_model = horseModel

    local modelHash = GetHashKey(ShowroomHorse_model)

    if not HasModelLoaded(modelHash) then
        RequestModel(modelHash)
        while not HasModelLoaded(modelHash) do
            Citizen.Wait(10)
        end
    end

    MyHorse_entity = CreatePed(modelHash, SpawnPoint.x, SpawnPoint.y, SpawnPoint.z - 0.98, SpawnPoint.h, false, 0)
    Citizen.InvokeNative(0x283978A15512B2FE, MyHorse_entity, true) -- SetRandomOutfitVariation
    Citizen.InvokeNative(0x58A850EAEE20FAA3, MyHorse_entity) -- PlaceObjectOnGroundProperly
    Citizen.InvokeNative(0x7D9EFB7AD6B19754, MyHorse_entity, true) -- FreezeEntityPosition
    SetPedConfigFlag(entity, 113, true) -- PCF_DisableShockingEvents
    --NetworkSetEntityInvisibleToNetwork(MyHorse_entity, true)

    SendNUIMessage({
        customize = true
    })

    local componentsHorse = json.decode(data.HorseComp)
    if componentsHorse ~= '[]' then
        for _, Key in pairs(componentsHorse) do
            local model2 = GetHashKey(tonumber(Key))
            if not HasModelLoaded(model2) then
                Citizen.InvokeNative(0xFA28FE3A6246FC30, model2) -- RequestModel
            end
            Citizen.InvokeNative(0xD3A7B003ED343FD9, MyHorse_entity, tonumber(Key), true, true, true) -- ApplyShopItemToPed
        end
    end
end)

RegisterNUICallback("selectHorse", function(data)
    TriggerServerEvent('oss_stables:SelectHorse', tonumber(data.horseID))
end)

RegisterNetEvent('oss_stables:SetHorseInfo')
AddEventHandler('oss_stables:SetHorseInfo', function(horse_model, horse_name, horse_components)
    HorseModel = horse_model
    HorseName = horse_name
    HorseComponents = horse_components
end)

--[[Citizen.CreateThread(function()
    while true do
    Citizen.Wait(100)
        if MyHorse_entity ~= nil then
            SendNUIMessage(
                {
                    customize = true
                }
            )
        else
            SendNUIMessage(
                {
                    customize = false
                }
            )
        end
    end
end)]]

RegisterNUICallback("CloseStable", function()
    local player = PlayerPedId()
    SetNuiFocus(false, false)
    SendNUIMessage({
        action = "hide",
        customize = false
    })
    SetEntityVisible(player, true)

    ShowroomHorse_model = nil

    if ShowroomHorse_entity ~= nil then
        DeleteEntity(ShowroomHorse_entity)
    end

    if MyHorse_entity ~= nil then
        DeleteEntity(MyHorse_entity)
    end

    DestroyAllCams(true)
    ShowroomHorse_entity = nil
    DisplayRadar(true)
    InMenu = false
    StableClose()
end)

function StableClose()
    local compData = {
        SaddlesUsing,
        SaddleclothsUsing,
        StirrupsUsing,
        BagsUsing,
        ManesUsing,
        HorseTailsUsing,
        AcsHornUsing,
        AcsLuggageUsing
    }
    local compDataEncoded = json.encode(compData)

    if compDataEncoded ~= "[]" then
        TriggerServerEvent('oss_stables:UpdateComponents', compData, IdMyHorse, MyHorse_entity)
    end
end

RegisterNetEvent('oss_stables:SetComponents')
AddEventHandler('oss_stables:SetComponents', function(horseEntity, components)
    for _, value in pairs(components) do
        NativeSetPedComponentEnabled(horseEntity, value)
    end
end)

function NativeSetPedComponentEnabled(ped, component)
    Citizen.InvokeNative(0xD3A7B003ED343FD9, ped, component, true, true, true) -- ApplyShopItemToPed
end

Citizen.CreateThread(function()
    while true do
        Citizen.Wait(1)
        if Citizen.InvokeNative(0x91AEF906BCA88877, 0, 0x24978A28) then -- Control =  H / IsDisabledControlJustPressed
			WhistleHorse()
			Citizen.Wait(10000) --Flood Protection? i think yes zoot
        end
        if Citizen.InvokeNative(0x91AEF906BCA88877, 0, 0x4216AF06) then -- Control = Horse Flee / IsDisabledControlJustPressed
			if SpawnplayerHorse ~= 0 then
				fleeHorse(SpawnplayerHorse)
			end
		end
    end
end)

function WhistleHorse()
    local player = PlayerPedId()
    if SpawnplayerHorse ~= 0 then
        if GetScriptTaskStatus(SpawnplayerHorse, 0x4924437D, 0) ~= 0 then
            local pcoords = GetEntityCoords(player)
            local hcoords = GetEntityCoords(SpawnplayerHorse)
            local caldist = #(pcoords - hcoords)
            if caldist >= 100 then
                DeleteEntity(SpawnplayerHorse)
                Wait(1000)
                SpawnplayerHorse = 0
            else
                TaskGoToEntity(SpawnplayerHorse, player, -1, 4, 2.0, 0, 0)
            end
        end
    else
        TriggerServerEvent('oss_stables:GetSelectedHorse')
        Wait(100)
        InitiateHorse()
    end
end

function InitiateHorse(atCoords)
    if Initializing then
        return
    end

    Initializing = true

    if SpawnplayerHorse ~= 0 then
        DeleteEntity(SpawnplayerHorse)
        SpawnplayerHorse = 0
    end

    local player = PlayerPedId()
    local pCoords = GetEntityCoords(player)
    local modelHash = GetHashKey(HorseModel)
    if not HasModelLoaded(modelHash) then
        RequestModel(modelHash)
        while not HasModelLoaded(modelHash) do
            Citizen.Wait(10)
        end
    end

    local spawnPosition
    if atCoords == nil then
        local x, y, z = table.unpack(pCoords)
        local nodePosition = GetClosestVehicleNode(x, y, z, 1, 3.0, 0.0)
        local index = 0
        while index <= 25 do
            local _bool, _nodePosition = GetNthClosestVehicleNode(x, y, z, index, 1, 3.0, 2.5)
            if _bool == true or _bool == 1 then
                nodePosition = _nodePosition
                index = index + 3
            else
                break
            end
        end
        spawnPosition = nodePosition
    else
        spawnPosition = atCoords
    end

    if spawnPosition == nil then
        Initializing = false
        return
    end

    local entity = CreatePed(modelHash, spawnPosition, GetEntityHeading(player), true, true)
    SetModelAsNoLongerNeeded(modelHash)

    Citizen.InvokeNative(0x9587913B9E772D29, entity, 0) -- PlaceEntityOnGroundProperly
    Citizen.InvokeNative(0x4DB9D03AC4E1FA84, entity, -1, -1, 0) -- SetPedWrithingDuration
    Citizen.InvokeNative(0x23f74c2fda6e7c61, -1230993421, entity) -- BlipAddForEntity
    Citizen.InvokeNative(0xBCC76708E5677E1D, entity, 0) -- SetHorseTamingState?
    Citizen.InvokeNative(0xB8B6430EAD2D2437, entity, GetHashKey("PLAYER_HORSE"))
    Citizen.InvokeNative(0xFD6943B6DF77E449, entity, false) -- SetPedCanBeLassoed
    Citizen.InvokeNative(0xC80A74AC829DDD92, entity, GetPedRelationshipGroupHash(entity)) -- SetPedRelationshipGroupHash
    Citizen.InvokeNative(0xBF25EB89375A37AD, 1, GetPedRelationshipGroupHash(entity), "PLAYER") -- SetRelationshipBetweenGroups
    --Citizen.InvokeNative(0x931B241409216C1F, player, entity, true) -- SetPedOwnsAnimal
    SetVehicleHasBeenOwnedByPlayer(entity, true)

    SetPedConfigFlag(entity, 324, true)
    SetPedConfigFlag(entity, 211, true) -- PCF_GiveAmbientDefaultTaskIfMissionPed
    SetPedConfigFlag(entity, 208, true)
    SetPedConfigFlag(entity, 209, true)
    SetPedConfigFlag(entity, 400, true)
    SetPedConfigFlag(entity, 297, true) -- PCF_ForceInteractionLockonOnTargetPed
    SetPedConfigFlag(entity, 136, false) -- (for horse) disable mount
    SetPedConfigFlag(entity, 312, false) -- PCF_DisableHorseGunshotFleeResponse
    SetPedConfigFlag(entity, 113, false) -- PCF_DisableShockingEvents
    SetPedConfigFlag(entity, 301, false) -- PCF_DisableInteractionLockonOnTargetPed
    SetPedConfigFlag(entity, 277, true)
    SetPedConfigFlag(entity, 319, true) -- PCF_EnableAsVehicleTransitionDestination
    SetPedConfigFlag(entity, 6, true) -- PCF_DontInfluenceWantedLevel
    SetPedConfigFlag(entity, 546, true) -- IgnoreOwnershipForHorseFeedAndBrush

    SetAnimalTuningBoolParam(entity, 25, false)
    SetAnimalTuningBoolParam(entity, 24, false)

    TaskAnimalUnalerted(entity, -1, false, 0, 0)
    Citizen.InvokeNative(0x283978A15512B2FE, entity, true) -- SetRandomOutfitVariation

    SpawnplayerHorse = entity

    SetPedNameDebug(entity, HorseName)
    SetPedPromptName(entity, HorseName)

    if HorseComponents ~= nil and HorseComponents ~= "0" then
        for _, componentHash in pairs(json.decode(HorseComponents)) do
            NativeSetPedComponentEnabled(entity, tonumber(componentHash))
        end
    end

    TaskGoToEntity(entity, player, -1, 7.2, 2.0, 0, 0)
    Initializing = false
end

function fleeHorse(playerHorse)
    local player = PlayerPedId()
    TaskAnimalFlee(SpawnplayerHorse, player, -1)
    Wait(10000)
    DeleteEntity(SpawnplayerHorse)
    Wait(1000)
    SpawnplayerHorse = 0
end

RegisterNUICallback("Saddles", function(data)
    if tonumber(data.id) == 0 then
        num = 0
        SaddlesUsing = num
        local playerHorse = MyHorse_entity
        Citizen.InvokeNative(0xD710A5007C2AC539, playerHorse, 0xBAA7E618, 0) -- RemoveTagFromMetaPed
        Citizen.InvokeNative(0xCC8CA3E88256E58F, playerHorse, 0, 1, 1, 1, 0) -- UpdatePedVariation
    else
        local num = tonumber(data.id)
        hash = ("0x" .. Saddles[num])
        setcloth(hash)
        SaddlesUsing = ("0x" .. Saddles[num])
    end
end)

RegisterNUICallback("Saddlecloths", function(data)
    if tonumber(data.id) == 0 then
        num = 0
        SaddleclothsUsing = num
        local playerHorse = MyHorse_entity
        Citizen.InvokeNative(0xD710A5007C2AC539, playerHorse, 0x17CEB41A, 0) -- RemoveTagFromMetaPed
        Citizen.InvokeNative(0xCC8CA3E88256E58F, playerHorse, 0, 1, 1, 1, 0) -- UpdatePedVariation
    else
        local num = tonumber(data.id)
        hash = ("0x" .. Saddlecloths[num])
        setcloth(hash)
        SaddleclothsUsing = ("0x" .. Saddlecloths[num])
    end
end)

RegisterNUICallback("Stirrups", function(data)
    if tonumber(data.id) == 0 then
        num = 0
        StirrupsUsing = num
        local playerHorse = MyHorse_entity
        Citizen.InvokeNative(0xD710A5007C2AC539, playerHorse, 0xDA6DADCA, 0) -- RemoveTagFromMetaPed
        Citizen.InvokeNative(0xCC8CA3E88256E58F, playerHorse, 0, 1, 1, 1, 0) -- UpdatePedVariation
    else
        local num = tonumber(data.id)
        hash = ("0x" .. Stirrups[num])
        setcloth(hash)
        StirrupsUsing = ("0x" .. Stirrups[num])
    end
end)

RegisterNUICallback("Bags", function(data)
    if tonumber(data.id) == 0 then
        num = 0
        BagsUsing = num
        local playerHorse = MyHorse_entity
        Citizen.InvokeNative(0xD710A5007C2AC539, playerHorse, 0x80451C25, 0) -- RemoveTagFromMetaPed
        Citizen.InvokeNative(0xCC8CA3E88256E58F, playerHorse, 0, 1, 1, 1, 0) -- UpdatePedVariation
    else
        local num = tonumber(data.id)
        hash = ("0x" .. Bags[num])
        setcloth(hash)
        BagsUsing = ("0x" .. Bags[num])
    end
end)

RegisterNUICallback("Manes", function(data)
    if tonumber(data.id) == 0 then
        num = 0
        ManesUsing = num
        local playerHorse = MyHorse_entity
        Citizen.InvokeNative(0xD710A5007C2AC539, playerHorse, 0xAA0217AB, 0) -- RemoveTagFromMetaPed
        Citizen.InvokeNative(0xCC8CA3E88256E58F, playerHorse, 0, 1, 1, 1, 0) -- UpdatePedVariation
    else
        local num = tonumber(data.id)
        hash = ("0x" .. Manes[num])
        setcloth(hash)
        ManesUsing = ("0x" .. Manes[num])
    end
end)

RegisterNUICallback("HorseTails", function(data)
    if tonumber(data.id) == 0 then
        num = 0
        HorseTailsUsing = num
        local playerHorse = MyHorse_entity
        Citizen.InvokeNative(0xD710A5007C2AC539, playerHorse, 0x17CEB41A, 0) -- RemoveTagFromMetaPed
        Citizen.InvokeNative(0xCC8CA3E88256E58F, playerHorse, 0, 1, 1, 1, 0) -- UpdatePedVariation
    else
        local num = tonumber(data.id)
        hash = ("0x" .. Horsetails[num])
        setcloth(hash)
        HorseTailsUsing = ("0x" .. Horsetails[num])
    end
end)

RegisterNUICallback("AcsHorn", function(data)
    if tonumber(data.id) == 0 then
        num = 0
        AcsHornUsing = num
        local playerHorse = MyHorse_entity
        Citizen.InvokeNative(0xD710A5007C2AC539, playerHorse, 0x5447332, 0) -- RemoveTagFromMetaPed
        Citizen.InvokeNative(0xCC8CA3E88256E58F, playerHorse, 0, 1, 1, 1, 0) -- UpdatePedVariation
    else
        local num = tonumber(data.id)
        hash = ("0x" .. Acshorn[num])
        setcloth(hash)
        AcsHornUsing = ("0x" .. Acshorn[num])
    end
end)

RegisterNUICallback("AcsLuggage", function(data)
    if tonumber(data.id) == 0 then
        num = 0
        AcsLuggageUsing = num
        local playerHorse = MyHorse_entity
        Citizen.InvokeNative(0xD710A5007C2AC539, playerHorse, 0xEFB31921, 0) -- RemoveTagFromMetaPed
        Citizen.InvokeNative(0xCC8CA3E88256E58F, playerHorse, 0, 1, 1, 1, 0) -- UpdatePedVariation
    else
        local num = tonumber(data.id)
        hash = ("0x" .. Acsluggage[num])
        setcloth(hash)
        AcsLuggageUsing = ("0x" .. Acsluggage[num])
    end
end)

function setcloth(hash)
    local model2 = GetHashKey(tonumber(hash))
    if not HasModelLoaded(model2) then
        Citizen.InvokeNative(0xFA28FE3A6246FC30, model2) -- RequestModel
    end
    Citizen.InvokeNative(0xD3A7B003ED343FD9, MyHorse_entity, tonumber(hash), true, true, true) -- ApplyShopItemToPed
end

RegisterNUICallback("sellHorse", function(data)
    DeleteEntity(ShowroomHorse_entity)
    TriggerServerEvent('oss_stables:SellHorse', tonumber(data.horseID))
    TriggerServerEvent('oss_stables:GetMyHorses')
    Wait(300)

    SendNUIMessage(
        {
            action = "show",
            shopData = getShopData()
        }
    )
    TriggerServerEvent('oss_stables:GetMyHorses')
end)

function returnHorse(shopId)
    if SpawnplayerHorse == 0 then
        VORPcore.NotifyRightTip(_U("noHorse"), 5000)

    elseif SpawnplayerHorse ~=0 then
        DeleteEntity(SpawnplayerHorse)
        SpawnplayerHorse = 0
        VORPcore.NotifyRightTip(_U("horseReturned"), 5000)
    end
end

Citizen.CreateThread(function()
	while Adding do
		Wait(0)
		for _, v in ipairs(HorseComp) do
			if v.category == "Saddlecloths" then
				Saddlecloths[#Saddlecloths+1] = v.Hash
			elseif v.category == "AcsHorn" then
				Acshorn[#Acshorn+1] = v.Hash
			elseif v.category == "Bags" then
				Bags[#Bags+1] = v.Hash
			elseif v.category == "HorseTails" then
				Horsetails[#Horsetails+1] = v.Hash
			elseif v.category == "Manes" then
				Manes[#Manes+1] = v.Hash
			elseif v.category == "Saddles" then
				Saddles[#Saddles+1] = v.Hash
			elseif v.category == "Stirrups" then
				Stirrups[#Stirrups+1] = v.Hash
			elseif v.category == "AcsLuggage" then
				Acsluggage[#Acsluggage+1] = v.Hash
			end
		end
		Adding = false
	end
end)

function createCamera(shopId)
    local shopConfig = Config.stables[shopId]
    local horseCam = CreateCam("DEFAULT_SCRIPTED_CAMERA", true)
    SetCamCoord(horseCam, shopConfig.horseCamx, shopConfig.horseCamy, shopConfig.horseCamz + 1.2 )
    SetCamActive(horseCam, true)
    PointCamAtCoord(horseCam, SpawnPoint.x - 0.5, SpawnPoint.y, SpawnPoint.z)
    DoScreenFadeOut(500)
    Wait(500)
    DoScreenFadeIn(500)
    RenderScriptCams(true, false, 0, 0, 0)
end

function AddBlip(shopId)
    local shopConfig = Config.stables[shopId]
    local blip = VORPutils.Blips:SetBlip(shopConfig.blipName, shopConfig.blipSprite, 0.2, shopConfig.npcx, shopConfig.npcy, shopConfig.npcz)
    Config.stables[shopId].BlipHandle = blip
end

function SpawnNPC(shopId)
    local shopConfig = Config.stables[shopId]
    local npc = VORPutils.Peds:Create(shopConfig.npcModel, shopConfig.npcx, shopConfig.npcy, shopConfig.npcz - 1, shopConfig.npch, 'world', false)
    npc:Freeze(true)
    npc:Invincible(true)
    npc:CanBeDamaged(false)
    SetBlockingOfNonTemporaryEvents(npc, true)
    Config.stables[shopId].NPC = npc
end

function CheckJob(allowedJob, playerJob)
    for _, jobAllowed in pairs(allowedJob) do
        JobName = jobAllowed
        if JobName == playerJob then
            return true
        end
    end
    return false
end

RegisterNetEvent("oss_stables:SendPlayerJob")
AddEventHandler("oss_stables:SendPlayerJob", function(Job, grade)
    PlayerJob = Job
    JobGrade = grade
end)

AddEventHandler('onResourceStop', function(resourceName)
    if (GetCurrentResourceName() ~= resourceName) then
        return
    end

    if InMenu == true then
        SetNuiFocus(false, false)
        SendNUIMessage(
            {
                action = "hide"
            }
        )
    end

    ClearPedTasksImmediately(PlayerPedId())
    OpenShop:DeletePrompt()
    ReturnShop:DeletePrompt()
    ClosedShop:DeletePrompt()

    if SpawnplayerHorse then
        DeleteEntity(SpawnplayerHorse)
        SpawnplayerHorse = 0
    end

    for _, shopConfig in pairs(Config.stables) do
        if shopConfig.BlipHandle then
            shopConfig.BlipHandle:Remove()
        end
        if shopConfig.NPC then
            shopConfig.NPC:Remove()
        end
    end
end)
