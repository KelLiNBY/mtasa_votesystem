-- VoteSystem created & released by KelLiN, Do not remove credits! --
-----------------------------------------------------------------
-- IF YOU CAN'T WRITE IN LUA, DO NOT EDIT ANYTHING ABOVE HERE! --
-----------------------------------------------------------------

-- CONNECTION HANDLER --
local dbpTime = 500 -- How many Miliseconds will use the dbPoll function for waiting for a result
-- EVENTS --

addEvent("onVoteSystemVoteCreate", true)
local voteid = 0 -- Define the Voteid, 

local vote = {} -- The Vote array
local voteData = {} -- The Vote Data array

--local saveBackupTimer -- не стал делать. Будет много io и проца есть, сделаю memcache.
--хз что за версия sqlite в мта и экранирует ли сама.
local function MySQLEscape(Value)
return string.gsub(tostring(Value),';','_')
end
-- STARTUP EVENT HANDLER --

addEventHandler("onResourceStart", getResourceRootElement(), function()

handler = dbConnect("sqlite", "votes.db","", "", "autoreconnect=1")
    if not(handler) then
    outputServerLog("[VOTE_SYSTEM] MySQL handler not accepted! Shutting down...")
        cancelEvent()
    else
    outputServerLog("[VOTE_SYSTEM] MySQL handler FILE accepted!")
        votesys_startup()-- не стал делать. Будет много io и проца есть, сделаю memcache.
    end

end)

-- SHUTDOWN EVENT HANDLER --
addEventHandler("onResourceStop", getResourceRootElement(), function()
    -- Free the arrays --
    -- не стал делать. Будет много io и проца есть, тогда сделаю.
end)

--------------
-- COMMANDS --
--------------

-- /vote --

addCommandHandler("vote", function(thePlayer,commandname,...)
    local arg = {...}
    local id,text,numsOfVariants=0,"bugaga",2
    --Чтение из таблицы информации. Понадобится в любом случае.
    if #arg>0 then
        if tonumber(arg[1])~=nil then
            local query = dbQuery(handler, "SELECT id,text,numsOfVariants FROM votes WHERE id='"..tonumber(arg[1]).."';" )
            local result, numrows = dbPoll(query, dbpTime)
            if (result and numrows > 0) then
                if numrows == 1 then
                    for index, row in pairs(result) do
                        id,text,numsOfVariants = row['id'],row['text'],row['numsOfVariants']
                        outputChatBox("Распаршено.",thePlayer,0,255,255)
                    end
                    outputChatBox("id1="..id..", text1="..text..", num1="..numsOfVariants,thePlayer,0,255,255)
                end
            else outputChatBox("Такого голосования не существует или произошла ошибка.",thePlayer,0,255,255) end
            dbFree(query)
        else return end
    else return end
    
    if #arg==1 then
        --Берем из таблицы с именем id голосования данные об голосовании.
        local variantsQuery = ""
        outputChatBox("id2="..id..", text2="..text..", num2="..numsOfVariants,thePlayer,0,255,255)
        for i=1,tonumber(numsOfVariants) do
            --костылик из-за не полного знания Lua. Должен быть какой-нибудь variantsQuery=join( i , ',')
            variantsQuery=variantsQuery.."num"..i
            if i~=numsOfVariants then
                variantsQuery=variantsQuery..","
            end
        end
        local query = dbQuery(handler, "SELECT "..variantsQuery.." FROM votes_variants WHERE id='"..id.."';" )
        local result, numrows = dbPoll(query, dbpTime)
        if (result and numrows > 0) then
            outputChatBox("Голосование с id="..id..". "..text..".",thePlayer,0,255,255)
            outputChatBox("Варианты для голосования:",thePlayer,0,255,255)
            for index, row in pairs(result) do
                for j=1,numsOfVariants do
                    outputChatBox(j..". "..row['num'..j]..".",thePlayer,0,255,255)
                end
            end
        else
            outputChatBox("Shit hapened #1:",thePlayer,0,255,255)
        end
        --getPlayerAccount ( thePlayer )
        local thirtyDaysInSeconds=2592000
        --outputChatBox("id="..id..", text="..text..", num="..numsOfVariants,thePlayer,0,255,255)

    elseif #arg==2 then
        --команда с 2мя аргументами для голосования за конкретноеголосование.
        if tonumber(arg[1])~=nil and tonumber(arg[2])~=nil and tonumber(arg[2])>0 and tonumber(arg[2])<=numsOfVariants then
            outputChatBox("2 args ok, В разработке",thePlayer,0,255,255)
            local query = dbQuery(handler, "SELECT accvariant FROM '"..tonumber(arg[1]).."' WHERE accname='"..tostring(MySQLEscape(getPlayerAccount(thePlayer))).."';" )
            local result, numrows = dbPoll(query, dbpTime)
            if (result and numrows > 0) then
                --Голосовал, отказ в голосовании.
                for index, row in pairs(result) do
                    variant = row['accvariant']
                    outputChatBox("Вы уже голосовали за вариант "..variant,thePlayer,0,255,255)
                end
                outputChatBox("id1="..id..", text1="..text..", num1="..numsOfVariants,thePlayer,0,255,255)
                dbFree(query)
            else 
                --запись голоса в базу.
                local query = dbQuery(handler, "INSERT INTO '"..tonumber(arg[1]).."' (accname,accvariant) values ('"..tostring(MySQLEscape(getPlayerAccount(thePlayer))).."', '"..tonumber(arg[2]).."');")
                outputChatBox("dbQuery OK", thePlayer, 0, 255, 0)
                local result, numrows,lastid = dbPoll(query, dbpTime)
                outputChatBox("dbPoll OK", thePlayer, 0, 255, 0)
                outputChatBox("result="..tostring(result), thePlayer, 0, 255, 0)
                if(result) then
                    outputChatBox("Вы успешно проголосовали за вариант "..tonumber(arg[2]), thePlayer, 0, 255, 0)
                    return
                elseif result == false then
                    local error_code,error_msg = numrows,lastid
                    outputChatBox("Ошибка при голосовании! Обратитесь к администрации через команду /report", thePlayer, 255, 0, 0)
                    --error("Vote error!")
                end
            end
        else outputChatBox("Ошибка, вы ввели неверный вариант",thePlayer,0,255,255) end
    end
end)

-- /votecreate --
addCommandHandler("createvote", function(thePlayer)
    if(hasObjectPermissionTo ( thePlayer, "function.voteCreate", false ) ) then
        triggerClientEvent(thePlayer, "onClientVoteSystemGUIStart", thePlayer)
    else
        outputChatBox("You are not have permissions to do vote!", thePlayer, 255, 0, 0)
    end
end)


-- /votehelp --

addCommandHandler("votehelp", function(thePlayer)
    outputChatBox("/vote # #", thePlayer, 0, 255, 255)
    outputChatBox("For Admins: /createvote, /deletevote", thePlayer, 0, 255, 255)
end)

-- /votes

addCommandHandler("votes", function(thePlayer)
    local query = dbQuery(handler, "SELECT id,text FROM votes;" )
    local result, numrows = dbPoll(query, dbpTime)
    local NumVotes=0
    local playerMessage="Проводиные голосования:"
    if (result and numrows > 0) then
        for index, row in pairs(result) do
            local id = row['id']
            local text = row['text']
            local by = row['CreatedBy']
            playerMessage = "[ "..id.." ] "..tostring(text)
            NumVotes = NumVotes+1
            outputChatBox(playerMessage, thePlayer, 0, 255, 255)
        end
        dbFree(query)
    end
    --можно if'ом запилить другую фразу если NumVotes=0 типа "голосований нет"
    outputChatBox("Всего "..NumVotes.." голосований. Будьте внимательно, изменить свой голос после голосования нельзя.", thePlayer, 0, 255, 255)
end)

-- VOTE DATABASE STARTUP --

function votesys_startup()
--
end
-- Read id and text
function votesys_getVotes ()
--пока GUI нет, бесполезная вещь. Потом даже экспортной сделать можно.
end
-- Vote Data array set --не стал делать, буду напрямую каждый раз sqlite дергать.

function setVotesData(ID, typ, value)

end

