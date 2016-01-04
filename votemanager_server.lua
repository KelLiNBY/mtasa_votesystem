-- VoteSystem created & released by KelLiN (kellinby@gmail.com), Do not remove credits! --
-----------------------------------------------------------------
-- IF YOU CAN'T WRITE IN LUA, DO NOT EDIT ANYTHING ABOVE HERE! --
-----------------------------------------------------------------

local dbpTime = 500

addEvent("onVoteSystemVoteCreate", true)

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
    local Query = executeSQLQuery("CREATE TABLE IF NOT EXISTS `votes_variants` (\
    `id`    INTEGER NOT NULL,\
    `num1`  TEXT NOT NULL,\
    `num2`  TEXT NOT NULL,\
    `num3`  TEXT,\
    `num4`  TEXT,\
    `num5`  TEXT,\
    `num6`  TEXT,\
    `num7`  TEXT,\
    `num8`  TEXT,\
    `num9`  TEXT,\
    `num10` TEXT,\
    PRIMARY KEY(id)\
    )")
    local Query = executeSQLQuery("CREATE TABLE IF NOT EXISTS `votes` (\
    `id`    INTEGER NOT NULL UNIQUE,\
    `CreatedBy` TEXT NOT NULL,\
    `text`  TEXT NOT NULL,\
    `numsOfVariants`    INTEGER NOT NULL,\
    PRIMARY KEY(id)\
    )")

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
    else  
        outputChatBox("Для голосования нужно ввести команду с номером голосования и пунктом,за который нужно проголосовать. Либо ввести команду и номер голосования для просмотра возможных вариантов для голосования",thePlayer,0,255,255)
    end
    
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
            outputChatBox("Голосования отсутствуют.",thePlayer,0,255,255)
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
addCommandHandler("votecreate", function(thePlayer,commandname,...)
    local arg = {...}
    <10

end)

-- /votedel --
addCommandHandler("votedel", function(thePlayer)
    local query = dbQuery(handler, "DELETE FROM votes WHERE id = '"..id.."';")
    local result = dbPoll(query, dbpTime)
    if(result) then
        outputChatBox("", thePlayer, 0, 255, 0)
    else
        error(" WTF")
    end
end)

-- /votehelp --

addCommandHandler("votehelp", function(thePlayer)
    outputChatBox("/votes для просмотра голосований", thePlayer, 0, 255, 255)
    outputChatBox("/vote #1 #2 для голосования в голосовании #1 за пункт #2", thePlayer, 0, 255, 255)
    outputChatBox("Для админов: /createvote, /deletevote", thePlayer, 0, 255, 255)
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

