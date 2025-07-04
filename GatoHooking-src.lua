-- TrackStats Elite v2.12 - Configuração via getgenv()
-- Inicializar configurações padrão se não existirem
if not getgenv().TrackStatsConfig then
    getgenv().TrackStatsConfig = {
        webhook = {
            url = "https://discord.com/api/webhooks/SEU_WEBHOOK_ID/SEU_WEBHOOK_TOKEN",
            username = "🏴‍☠️ TrackStats Elite",
            avatar_url = "https://cdn.discordapp.com/attachments/123456789/987654321/pirate_avatar.png"
        },
        settings = {
            update_interval = 300,
            max_retries = 3,
            retry_delay = 5,
            enable_logging = true,
            debug_mode = true
        }
    }
end

-- Referências locais para melhor performance
local webhookConfig = getgenv().TrackStatsConfig.webhook
local settings = getgenv().TrackStatsConfig.settings

-- Serviços do Roblox
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local HttpService = game:GetService("HttpService")
local RunService = game:GetService("RunService")

local LocalPlayer = Players.LocalPlayer
local CommF_

-- Função para inicializar o CommF_
local function initializeCommF()
    local remotes = ReplicatedStorage:WaitForChild("Remotes", 10)
    if remotes then
        CommF_ = remotes:WaitForChild("CommF_", 10)
        return CommF_ ~= nil
    end
    return false
end

-- Sistema de logging
local function log(level, message)
    if not settings.enable_logging then return end
    
    local timestamp = os.date("%H:%M:%S")
    print(string.format("[%s] [%s] %s", timestamp, level:upper(), message))
    
    if settings.debug_mode and level == "debug" then
        game:GetService("StarterGui"):SetCore("ChatMakeSystemMessage", {
            Text = "[DEBUG] " .. message,
            Color = Color3.fromRGB(255, 255, 0)
        })
    end
end

-- Função para verificar se um valor é uma tabela válida
local function isValidTable(value)
    return value and type(value) == "table"
end

-- Função de diagnóstico completo
local function diagnosticInventory()
    log("debug", "=== DIAGNÓSTICO COMPLETO DO INVENTÁRIO ===")
    
    local methods = {
        "getInventory", "getInventoryFruits", "getInventoryWeapons", "getInventoryAccessories",
        "GetFruits", "GetWeapons", "GetAccessories", "getFruits", "getWeapons", "getAccessories",
        "Inventory", "Fruits", "Weapons", "Swords", "Accessories", "getRace"
    }
    
    for _, method in ipairs(methods) do
        local success, result = pcall(function()
            return CommF_:InvokeServer(method)
        end)
        
        if success and result ~= nil then
            local resultType = type(result)
            if resultType == "table" then
                local itemCount = 0
                local countSuccess, _ = pcall(function()
                    for _ in pairs(result) do
                        itemCount = itemCount + 1
                    end
                end)
                
                if countSuccess then
                    log("debug", string.format("✅ %s: %s com %d itens", method, resultType, itemCount))
                    
                    -- Mostrar alguns itens como exemplo
                    local exampleCount = 0
                    local exampleSuccess, _ = pcall(function()
                        for key, value in pairs(result) do
                            if exampleCount < 2 then
                                if type(value) == "table" then
                                    local properties = {}
                                    local propSuccess, _ = pcall(function()
                                        for propKey, propValue in pairs(value) do
                                            table.insert(properties, tostring(propKey) .. ":" .. type(propValue))
                                        end
                                    end)
                                    
                                    if propSuccess then
                                        log("debug", string.format("  Item[%s]: {%s}", tostring(key), table.concat(properties, ", ")))
                                    else
                                        log("debug", string.format("  Item[%s]: tabela complexa", tostring(key)))
                                    end
                                else
                                    log("debug", string.format("  Item[%s]: %s (%s)", tostring(key), tostring(value), type(value)))
                                end
                            end
                            exampleCount = exampleCount + 1
                        end
                    end)
                    
                    if not exampleSuccess then
                        log("debug", string.format("  ⚠️ Erro ao iterar sobre %s", method))
                    end
                else
                    log("debug", string.format("✅ %s: %s (erro ao contar itens)", method, resultType))
                end
            else
                log("debug", string.format("✅ %s: %s = %s", method, resultType, tostring(result)))
            end
        else
            log("debug", string.format("❌ %s: FALHOU - %s", method, tostring(result)))
        end
    end
    
    log("debug", "=== FIM DO DIAGNÓSTICO ===")
end

-- Função para determinar cor baseada no nível
local function getLevelColor(level)
    if level < 100 then return 15158332 end -- Vermelho
    if level < 500 then return 3447003 end -- Verde escuro
    if level < 1000 then return 3066993 end -- Azul escuro
    if level < 1500 then return 10181046 end -- Roxo
    if level < 2000 then return 15965202 end -- Laranja
    if level < 2500 then return 15105570 end -- Amarelo
    return 9323693 -- Azul claro
end

-- Função para obter raça do jogador
local function getPlayerRace()
    local race = "❌ Raça não identificada"
    local attempts = {}
    
    local raceMethods = {"getRace", "GetRace", "Race", "race", "PlayerRace"}
    
    for _, method in ipairs(raceMethods) do
        local success, result = pcall(function()
            return CommF_:InvokeServer(method)
        end)
        
        table.insert(attempts, string.format("Método '%s': %s", method, success and "OK" or "FALHA"))
        
        if success and result then
            if type(result) == "string" and result ~= "" then
                local raceIcons = {
                    Human = "🧑 Humano",
                    Fishman = "🐟 Homem-Peixe", 
                    Skypiean = "☁️ Skypiean",
                    Mink = "🐺 Mink",
                    Cyborg = "🤖 Cyborg",
                    Ghoul = "👻 Ghoul"
                }
                race = raceIcons[result] or "🎭 " .. result
                break
            elseif type(result) == "table" and result.Race then
                local raceIcons = {
                    Human = "🧑 Humano",
                    Fishman = "🐟 Homem-Peixe",
                    Skypiean = "☁️ Skypiean", 
                    Mink = "🐺 Mink",
                    Cyborg = "🤖 Cyborg",
                    Ghoul = "👻 Ghoul"
                }
                race = raceIcons[result.Race] or "🎭 " .. result.Race
                break
            end
        end
    end
    
    -- Fallback: tentar obter da Data do jogador
    if race == "❌ Raça não identificada" then
        local success, _ = pcall(function()
            local raceValue = LocalPlayer.Data:FindFirstChild("Race")
            if raceValue and raceValue.Value then
                local raceIcons = {
                    Human = "🧑 Humano",
                    Fishman = "🐟 Homem-Peixe",
                    Skypiean = "☁️ Skypiean",
                    Mink = "🐺 Mink", 
                    Cyborg = "🤖 Cyborg",
                    Ghoul = "👻 Ghoul"
                }
                race = raceIcons[raceValue.Value] or "🎭 " .. raceValue.Value
            end
        end)
    end
    
    log("debug", "Raça - " .. table.concat(attempts, ", "))
    return race
end

-- Função para obter frutas do inventário
local function getInventoryFruits()
    local fruits = {}
    local attempts = {}
    
    local remotes = game:GetService("ReplicatedStorage")
    local commF = remotes:WaitForChild("Remotes"):WaitForChild("CommF_")
    
    -- Tentar método principal
    local success, result = pcall(function()
        return commF:InvokeServer("getInventoryFruits")
    end)
    
    table.insert(attempts, "Método 'getInventoryFruits': " .. (success and "OK" or "FALHA"))
    
    if success and typeof(result) == "table" then
        local processSuccess, _ = pcall(function()
            for _, item in pairs(result) do
                if type(item) == "table" then
                    local name = item.Name or item.name or item.Item or item.item
                    local count = item.Count or item.count or item.Amount or item.amount or 1
                    local owned = item.Owned or item.owned or item.Have or item.have
                    
                    if name and type(name) == "string" and name ~= "" then
                        local hasItem = false
                        
                        if owned ~= nil then
                            hasItem = owned == true or owned == "true" or owned == 1
                        elseif type(count) == "number" then
                            hasItem = count > 0
                        else
                            hasItem = true
                        end
                        
                        if hasItem then
                            local countText = type(count) == "number" and count > 1 and " `x" .. count .. "`" or ""
                            table.insert(fruits, "🥭 " .. name .. countText)
                            log("debug", string.format("Fruta adicionada: %s (Qtd: %s, Possuída: %s)", name, tostring(count), tostring(owned)))
                        end
                    end
                end
            end
        end)
        
        if processSuccess and #fruits > 0 then
            log("debug", string.format("Método 'getInventoryFruits' retornou %d frutas válidas", #fruits))
        end
    end
    
    -- Fallback: tentar inventário geral
    if #fruits == 0 then
        local fallbackSuccess, fallbackResult = pcall(function()
            return commF:InvokeServer("getInventory")
        end)
        
        table.insert(attempts, "Fallback 'getInventory': " .. (fallbackSuccess and "OK" or "FALHA"))
        
        if fallbackSuccess and typeof(fallbackResult) == "table" then
            for _, item in pairs(fallbackResult) do
                if type(item) == "table" then
                    local itemType = item.Type or item.type or item.Category or item.category
                    local name = item.Name or item.name or item.Item or item.item
                    local count = item.Count or item.count or item.Amount or item.amount or 1
                    local owned = item.Owned or item.owned or item.Have or item.have
                    
                    if itemType and (itemType == "Blox Fruit" or itemType == "Devil Fruit" or itemType == "Fruit") then
                        if name and type(name) == "string" and name ~= "" then
                            local hasItem = false
                            
                            if owned ~= nil then
                                hasItem = owned == true or owned == "true" or owned == 1
                            elseif type(count) == "number" then
                                hasItem = count > 0
                            else
                                hasItem = true
                            end
                            
                            if hasItem then
                                local countText = type(count) == "number" and count > 1 and " `x" .. count .. "`" or ""
                                table.insert(fruits, "🥭 " .. name .. countText)
                                log("debug", string.format("Fruta do inventário geral: %s", name))
                            end
                        end
                    end
                end
            end
        end
    end
    
    log("debug", "Frutas - " .. table.concat(attempts, ", "))
    log("info", string.format("Total de frutas encontradas: %d", #fruits))
    
    return #fruits > 0 and table.concat(fruits, "\n") or "❌ Nenhuma fruta encontrada"
end

-- Função para obter armas/espadas do inventário
local function getInventoryWeapons()
    local weapons = {}
    local attempts = {}
    
    local weaponMethods = {"getInventoryWeapons", "GetWeapons", "getWeapons", "Swords", "getSwords"}
    
    for _, method in ipairs(weaponMethods) do
        local success, result = pcall(function()
            return CommF_:InvokeServer(method)
        end)
        
        table.insert(attempts, string.format("Método '%s': %s", method, success and "OK" or "FALHA"))
        
        if success and result then
            if type(result) == "table" then
                pcall(function()
                    for _, item in pairs(result) do
                        if type(item) == "table" then
                            local name = item.Name or item.name or item.Item or item.item
                            local count = item.Count or item.count or item.Amount or item.amount or 1
                            local owned = item.Owned or item.owned or item.Have or item.have
                            
                            if name and type(name) == "string" and name ~= "" then
                                local hasItem = false
                                
                                if owned ~= nil then
                                    hasItem = owned == true or owned == "true" or owned == 1
                                elseif type(count) == "number" then
                                    hasItem = count > 0
                                else
                                    hasItem = true
                                end
                                
                                if hasItem then
                                    local countText = type(count) == "number" and count > 1 and " `x" .. count .. "`" or ""
                                    table.insert(weapons, "⚔️ " .. name .. countText)
                                    log("debug", string.format("Espada adicionada: %s (Qtd: %s, Possuída: %s)", name, tostring(count), tostring(owned)))
                                else
                                    log("debug", string.format("Espada ignorada: %s (Qtd: %s, Possuída: %s)", name, tostring(count), tostring(owned)))
                                end
                            end
                        elseif type(item) == "string" and item ~= "" then
                            table.insert(weapons, "⚔️ " .. item)
                            log("debug", string.format("Espada string adicionada: %s", item))
                        end
                    end
                end)
                
                if #weapons > 0 then
                    log("debug", string.format("Método '%s' retornou %d espadas válidas", method, #weapons))
                    break
                end
            end
        end
    end
    
    -- Fallback: inventário geral
    if #weapons == 0 then
        local fallbackSuccess, fallbackResult = pcall(function()
            return CommF_:InvokeServer("getInventory")
        end)
        
        if fallbackSuccess and isValidTable(fallbackResult) then
            table.insert(attempts, "Método 'getInventory' (filtrado): OK")
            pcall(function()
                for _, item in pairs(fallbackResult) do
                    if type(item) == "table" then
                        local itemType = item.Type or item.type or item.Category or item.category
                        local name = item.Name or item.name or item.Item or item.item
                        local count = item.Count or item.count or item.Amount or item.amount or 1
                        local owned = item.Owned or item.owned or item.Have or item.have
                        
                        if itemType and (itemType == "Sword" or itemType == "Weapon" or itemType == "Melee") then
                            if name and type(name) == "string" and name ~= "" then
                                local hasItem = false
                                
                                if owned ~= nil then
                                    hasItem = owned == true or owned == "true" or owned == 1
                                elseif type(count) == "number" then
                                    hasItem = count > 0
                                else
                                    hasItem = true
                                end
                                
                                if hasItem then
                                    local countText = type(count) == "number" and count > 1 and " `x" .. count .. "`" or ""
                                    table.insert(weapons, "⚔️ " .. name .. countText)
                                    log("debug", string.format("Espada do inventário geral: %s", name))
                                end
                            end
                        end
                    end
                end
            end)
        else
            table.insert(attempts, "Método 'getInventory' (filtrado): FALHA")
        end
    end
    
    log("debug", "Espadas - " .. table.concat(attempts, ", "))
    log("info", string.format("Total de espadas encontradas: %d", #weapons))
    
    return #weapons > 0 and table.concat(weapons, "\n") or "❌ Nenhuma espada encontrada"
end

-- Função para obter acessórios do inventário
local function getInventoryAccessories()
    local accessories = {}
    local attempts = {}
    
    local accessoryMethods = {"GetAccessories", "getAccessories", "getInventoryAccessories"}
    
    for _, method in ipairs(accessoryMethods) do
        local success, result = pcall(function()
            return CommF_:InvokeServer(method)
        end)
        
        table.insert(attempts, string.format("Método '%s': %s", method, success and "OK" or "FALHA"))
        
        if success and result then
            if type(result) == "table" then
                pcall(function()
                    for _, item in pairs(result) do
                        if type(item) == "table" then
                            local name = item.Name or item.name or item.Item or item.item
                            local count = item.Count or item.count or item.Amount or item.amount or 1
                            local owned = item.Owned or item.owned or item.Have or item.have
                            
                            if name and type(name) == "string" and name ~= "" then
                                local hasItem = false
                                
                                if owned ~= nil then
                                    hasItem = owned == true or owned == "true" or owned == 1
                                elseif type(count) == "number" then
                                    hasItem = count > 0
                                else
                                    hasItem = true
                                end
                                
                                if hasItem then
                                    local countText = type(count) == "number" and count > 1 and " `x" .. count .. "`" or ""
                                    table.insert(accessories, "👑 " .. name .. countText)
                                    log("debug", string.format("Acessório adicionado: %s (Qtd: %s, Possuída: %s)", name, tostring(count), tostring(owned)))
                                else
                                    log("debug", string.format("Acessório ignorado: %s (Qtd: %s, Possuída: %s)", name, tostring(count), tostring(owned)))
                                end
                            end
                        elseif type(item) == "string" and item ~= "" then
                            table.insert(accessories, "👑 " .. item)
                            log("debug", string.format("Acessório string adicionado: %s", item))
                        end
                    end
                end)
                
                if #accessories > 0 then
                    log("debug", string.format("Método '%s' retornou %d acessórios válidos", method, #accessories))
                    break
                end
            end
        end
    end
    
    -- Fallback: inventário geral
    if #accessories == 0 then
        local fallbackSuccess, fallbackResult = pcall(function()
            return CommF_:InvokeServer("getInventory")
        end)
        
        if fallbackSuccess and isValidTable(fallbackResult) then
            table.insert(attempts, "Método 'getInventory' (filtrado): OK")
            pcall(function()
                for _, item in pairs(fallbackResult) do
                    if type(item) == "table" then
                        local itemType = item.Type or item.type or item.Category or item.category
                        local name = item.Name or item.name or item.Item or item.item
                        local count = item.Count or item.count or item.Amount or item.amount or 1
                        local owned = item.Owned or item.owned or item.Have or item.have
                        
                        if itemType and (itemType == "Accessory" or itemType == "Wear" or itemType == "Hat" or itemType == "Cape") then
                            if name and type(name) == "string" and name ~= "" then
                                local hasItem = false
                                
                                if owned ~= nil then
                                    hasItem = owned == true or owned == "true" or owned == 1
                                elseif type(count) == "number" then
                                    hasItem = count > 0
                                else
                                    hasItem = true
                                end
                                
                                if hasItem then
                                    local countText = type(count) == "number" and count > 1 and " `x" .. count .. "`" or ""
                                    table.insert(accessories, "👑 " .. name .. countText)
                                    log("debug", string.format("Acessório do inventário geral: %s", name))
                                end
                            end
                        end
                    end
                end
            end)
        else
            table.insert(attempts, "Método 'getInventory' (filtrado): FALHA")
        end
    end
    
    log("debug", "Acessórios - " .. table.concat(attempts, ", "))
    log("info", string.format("Total de acessórios encontrados: %d", #accessories))
    
    return #accessories > 0 and table.concat(accessories, "\n") or "❌ Nenhum acessório encontrado"
end

-- Função para obter informações monetárias
local function getMoneyInfo()
    local moneyInfo = {}
    
    local success, _ = pcall(function()
        -- Beli
        local beliValue = LocalPlayer.Data:FindFirstChild("Beli")
        if beliValue and beliValue.Value then
            local beli = tonumber(beliValue.Value)
            if beli then
                local formattedBeli = tostring(beli):reverse():gsub("(%d%d%d)", "%1,"):reverse():gsub("^,", "")
                table.insert(moneyInfo, "💰 **" .. formattedBeli .. "** Beli")
            end
        end
        
        -- Fragmentos
        local fragmentsValue = LocalPlayer.Data:FindFirstChild("Fragments")
        if fragmentsValue and fragmentsValue.Value then
            local fragments = tonumber(fragmentsValue.Value)
            if fragments then
                local formattedFragments = tostring(fragments):reverse():gsub("(%d%d%d)", "%1,"):reverse():gsub("^,", "")
                table.insert(moneyInfo, "💎 **" .. formattedFragments .. "** Fragmentos")
            end
        end
    end)
    
    return #moneyInfo > 0 and table.concat(moneyInfo, "\n") or "❌ Informações monetárias indisponíveis"
end

-- Função para obter status do jogador
local function getPlayerStatus()
    local status = {}
    
    pcall(function()
        table.insert(status, "👤 **" .. LocalPlayer.Name .. "**")
        table.insert(status, "🎮 *" .. (LocalPlayer.DisplayName or LocalPlayer.Name) .. "*")
        
        if LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then
            local position = LocalPlayer.Character.HumanoidRootPart.Position
            table.insert(status, string.format("📍 `X:%.0f Y:%.0f Z:%.0f`", position.X, position.Y, position.Z))
        end
    end)
    
    return #status > 0 and table.concat(status, "\n") or "❌ Status indisponível"
end

-- Função principal para coletar e enviar dados
local function collectAndSendData()
    if not LocalPlayer:FindFirstChild("Data") then
        log("erro", "Dados do jogador não encontrados")
        return false
    end
    
    local levelValue = LocalPlayer.Data:FindFirstChild("Level")
    if not levelValue then
        log("erro", "Nível do jogador não encontrado")
        return false
    end
    
    local level = levelValue.Value
    log("info", string.format("Coletando dados para o nível %d", level))
    
    if settings.debug_mode then
        diagnosticInventory()
    end
    
    -- Coletar todas as informações
    local race = getPlayerRace()
    local fruits = getInventoryFruits()
    local weapons = getInventoryWeapons()
    local accessories = getInventoryAccessories()
    local money = getMoneyInfo()
    local playerStatus = getPlayerStatus()
    
    log("debug", "Raça: " .. race)
    log("debug", "Frutas coletadas: " .. fruits:gsub("\n", " | "))
    log("debug", "Espadas coletadas: " .. weapons:gsub("\n", " | "))
    log("debug", "Acessórios coletados: " .. accessories:gsub("\n", " | "))
    
    -- Preparar dados para webhook
    local timestamp = os.date("!%Y-%m-%dT%H:%M:%SZ")
    local webhookData = {
        username = webhookConfig.username,
        avatar_url = webhookConfig.avatar_url,
        embeds = {{
            title = "Project: GatoHooking V2.12",
            description = "```Version: BETA: 2.12```",
            color = getLevelColor(level),
            fields = {
                {
                    name = "**Account Info**",
                    value = playerStatus,
                    inline = true
                },
                {
                    name = "🎯 **Level**",
                    value = string.format("```yaml\nLevel: %d\n```", level),
                    inline = true
                },
                {
                    name = "**RACE**",
                    value = race,
                    inline = true
                },
                {
                    name = "**Beli**",
                    value = money,
                    inline = false
                },
                {
                    name = "🥭 **Devil Fruits**",
                    value = fruits ~= "❌ Nenhuma fruta encontrada" and 
                           string.format("```diff\n+ %s\n```", fruits:gsub("🥭 ", ""):gsub("\n", "\n+ ")) or 
                           "```diff\n- Nenhuma fruta encontrada\n```",
                    inline = false
                },
                {
                    name = "**Swords**",
                    value = weapons ~= "❌ Nenhuma espada encontrada" and 
                           string.format("```diff\n+ %s\n```", weapons:gsub("⚔️ ", ""):gsub("\n", "\n+ ")) or 
                           "```diff\n- Nenhuma espada encontrada\n```",
                    inline = false
                },
                {
                    name = "**Accessories**",
                    value = accessories ~= "❌ Nenhum acessório encontrado" and 
                           string.format("```diff\n+ %s\n```", accessories:gsub("👑 ", ""):gsub("\n", "\n+ ")) or 
                           "```diff\n- Nenhum acessório encontrado\n```",
                    inline = false
                }
            },
            thumbnail = {
                url = "https://static.wikia.nocookie.net/blox-fruits/images/7/7c/BloxFruitsIcon.png"
            },
            image = {
                url = "https://i.imgur.com/YourCustomBanner.png"
            },
            footer = {
                text = "🔄 Próximo envio em " .. tostring(settings.update_interval) .. " segundos",
                icon_url = "https://cdn.discordapp.com/emojis/123456789/skull.png"
            },
            timestamp = timestamp,
            author = {
                name = "Blox Fruits Tracking",
                icon_url = "https://static.wikia.nocookie.net/blox-fruits/images/7/7c/BloxFruitsIcon.png"
            }
        }}
    }
    
    -- Função para enviar webhook
    local function sendWebhook(attempt)
        local success, response = pcall(function()
            return request({
                Url = webhookConfig.url,
                Method = "POST",
                Headers = {
                    ["Content-Type"] = "application/json",
                    ["User-Agent"] = "TrackStats-Elite/2.12",
                    ["Accept"] = "application/json"
                },
                Body = HttpService:JSONEncode(webhookData)
            })
        end)
        
        if success then
            if response.Success or (response.StatusCode and response.StatusCode >= 200 and response.StatusCode < 300) then
                log("sucesso", string.format("✅ Relatório enviado com sucesso! (Tentativa %d)", attempt))
                return true
            else
                log("erro", string.format("❌ Resposta inválida do Discord (Tentativa %d): Status %s", attempt, tostring(response.StatusCode)))
                return false
            end
        else
            log("erro", string.format("❌ Falha na conexão (Tentativa %d): %s", attempt, tostring(response)))
            return false
        end
    end
    
    -- Tentar enviar com retry
    for attempt = 1, settings.max_retries do
        if sendWebhook(attempt) then
            return true
        end
        
        if attempt < settings.max_retries then
            log("aviso", string.format("⏳ Aguardando %d segundos antes da próxima tentativa...", settings.retry_delay))
            task.wait(settings.retry_delay)
        end
    end
    
    log("erro", "💥 Todas as tentativas de envio falharam!")
    return false
end

-- Função para inicializar o sistema
local function initializeSystem()
    log("info", "═══════════════════════════════════════")
    log("info", "🏴‍☠️ TrackStats Elite v2.12 Iniciando...")
    log("info", "═══════════════════════════════════════")
    
    -- Verificar se a webhook está configurada
    if webhookConfig.url == "https://discord.com/api/webhooks/SEU_WEBHOOK_ID/SEU_WEBHOOK_TOKEN" then
        log("erro", "❌ WEBHOOK NÃO CONFIGURADA!")
        log("erro", "Configure sua webhook usando:")
        log("erro", "getgenv().TrackStatsConfig.webhook.url = 'SUA_WEBHOOK_URL'")
        return false
    end
    
    if not initializeCommF() then
        log("erro", "Falha ao inicializar CommF_. Tentando novamente em 10 segundos...")
        task.wait(10)
        if not initializeCommF() then
            log("erro", "Falha crítica: Não foi possível inicializar CommF_")
            return false
        end
    end
    
    log("sucesso", "🚀 Sistema inicializado com sucesso!")
    log("info", string.format("⏰ Intervalo de atualização: %d segundos", settings.update_interval))
    log("info", string.format("🔗 Webhook configurada: %s", webhookConfig.username))
    
    -- Executar primeira coleta
    collectAndSendData()
    return true
end

-- Função principal de loop
local function mainLoop()
    local executionCount = 0
    
    while getgenv().TrackStatsRunning do
        task.wait(settings.update_interval)
        executionCount = executionCount + 1
        
        log("info", string.format("⚡ Execução Elite #%d ⚡", executionCount))
        
        local success = collectAndSendData()
        if not success then
            log("aviso", "⚠️ Execução falhou, mas continuando o monitoramento...")
        end
        
        -- Limpeza de memória a cada 10 execuções
        if executionCount % 10 == 0 then
            log("info", "🧹 Executando limpeza automática de memória...")
            collectgarbage("collect")
        end
    end
end

-- Função para configurar webhook via comando
getgenv().SetWebhook = function(url, username, avatar_url)
    if not url then
        log("erro", "URL da webhook é obrigatória!")
        return false
    end
    
    getgenv().TrackStatsConfig.webhook.url = url
    if username then
        getgenv().TrackStatsConfig.webhook.username = username
    end
    if avatar_url then
        getgenv().TrackStatsConfig.webhook.avatar_url = avatar_url
    end
    
    log("sucesso", "✅ Webhook configurada com sucesso!")
    log("info", "Username: " .. getgenv().TrackStatsConfig.webhook.username)
    return true
end

-- Função para atualizar configurações
getgenv().UpdateSettings = function(newSettings)
    for key, value in pairs(newSettings) do
        if getgenv().TrackStatsConfig.settings[key] ~= nil then
            getgenv().TrackStatsConfig.settings[key] = value
            log("info", string.format("Configuração atualizada: %s = %s", key, tostring(value)))
        end
    end
end

-- Função para parar o sistema
getgenv().StopTrackStats = function()
    getgenv().TrackStatsRunning = false
    log("info", "🛑 TrackStats Elite interrompido pelo usuário")
end

-- Função para reiniciar o sistema
getgenv().RestartTrackStats = function()
    getgenv().StopTrackStats()
    task.wait(2)
    getgenv().StartTrackStats()
end

-- Função para iniciar o sistema
getgenv().StartTrackStats = function()
    if getgenv().TrackStatsRunning then
        log("aviso", "⚠️ TrackStats Elite já está em execução!")
        return
    end
    
    getgenv().TrackStatsRunning = true
    
    spawn(function()
        if initializeSystem() then
            mainLoop()
        else
            log("erro", "💥 Falha na inicialização. Sistema encerrado.")
            getgenv().TrackStatsRunning = false
        end
    end)
end

-- Função para mostrar status atual
getgenv().TrackStatsStatus = function()
    print("═══════════════════════════════════════")
    print("🏴‍☠️ TrackStats Elite v2.12 - Status")
    print("═══════════════════════════════════════")
    print("Status: " .. (getgenv().TrackStatsRunning and "🟢 Ativo" or "🔴 Inativo"))
    print("Webhook: " .. (webhookConfig.url ~= "https://discord.com/api/webhooks/SEU_WEBHOOK_ID/SEU_WEBHOOK_TOKEN" and "✅ Configurada" or "❌ Não configurada"))
    print("Username: " .. webhookConfig.username)
    print("Intervalo: " .. settings.update_interval .. " segundos")
    print("Debug: " .. (settings.debug_mode and "Ativado" or "Desativado"))
    print("═══════════════════════════════════════")
end

-- Função para configuração rápida
getgenv().QuickSetup = function(webhookUrl)
    if not webhookUrl then
        print("❌ Uso: getgenv().QuickSetup('SUA_WEBHOOK_URL')")
        return false
    end
    
    getgenv().SetWebhook(webhookUrl)
    getgenv().StartTrackStats()
    return true
end

-- Detectar quando o jogador sai do jogo
Players.PlayerRemoving:Connect(function(player)
    if player == LocalPlayer then
        log("info", "👋 Jogador saindo... Finalizando TrackStats Elite.")
        getgenv().TrackStatsRunning = false
    end
end)

-- Mensagem de inicialização
log("info", "🏴‍☠️ TrackStats Elite v2.12 carregado!")
log("info", "📋 Comandos disponíveis:")
log("info", "• getgenv().SetWebhook('URL') - Configurar webhook")
log("info", "• getgenv().StartTrackStats() - Iniciar sistema")
log("info", "• getgenv().StopTrackStats() - Parar sistema")
log("info", "• getgenv().TrackStatsStatus() - Ver status")
log("info", "• getgenv().QuickSetup('URL') - Configuração rápida")
log("info", "════════════════════════════════════════════════")

-- Auto-iniciar se a webhook já estiver configurada
if webhookConfig.url ~= "https://discord.com/api/webhooks/SEU_WEBHOOK_ID/SEU_WEBHOOK_TOKEN" then
    log("info", "🚀 Webhook detectada, iniciando automaticamente...")
    getgenv().StartTrackStats()
else
    log("info", "⚙️ Configure sua webhook para começar:")
    log("info", "getgenv().SetWebhook('SUA_WEBHOOK_URL')")
end
