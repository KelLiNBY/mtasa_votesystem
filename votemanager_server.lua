-- VoteSystem created & released by KelLiN (kellinby@gmail.com), Do not remove credits! --
-----------------------------------------------------------------
-- IF YOU CAN'T WRITE IN LUA, DO NOT EDIT ANYTHING ABOVE HERE! --
-----------------------------------------------------------------


--Количество голосов, необходимое для успешного завершения голосования.
NumsToEndVote=10

--в следующей строке нужно установить вместо 40 значение 30*24*60*60 это 30 дней в секундах.  40 для теста
TimeToEndVote=30*24*60*60


--безнеобходимые для настройки
local sysvote_timer
local dbpTime = 500

--addEvent("onVoteSystemVoteCreate", true)

--local saveBackupTimer -- не стал делать. Будет много io и проца есть, сделаю memcache.


--хз что за версия sqlite в мта и экранирует ли сама.
--added: согласно вики в МТА 1.6 добавили dbPrepareString . Юзать её после обновы выше 1.6 r7745.
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
        votesys_check()
        --outputServerLog("[VOTE_SYSTEM] votesys_check() is ok")
    end
    
    local Query = dbQuery(handler,"CREATE TABLE IF NOT EXISTS `votes` (\
    `id`    INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT UNIQUE,\
    `CreatedBy` TEXT NOT NULL,\
    `text`  TEXT NOT NULL,\
    `numsOfVariants`    INTEGER NOT NULL,\
    `deleteDate`    INTEGER NOT NULL,\
    `active`    INTEGER NOT NULL\
    )")
    dbFree(Query)
    
    local Query = dbQuery(handler,"CREATE TABLE IF NOT EXISTS `votes_variants` (\
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
    dbFree(Query)

end)

function votesys_check ()
    --outputServerLog("[VOTE_SYSTEM] syscheck begin!")
    local query = dbQuery(handler, "SELECT id,deleteDate,active FROM votes where deleteDate<"..getRealTime().timestamp..";" )
    --позже прооптимизировать чтобы не искало те голосования где уже флаг active=0. Пока добавлена проверка№7
    --при большом количестве голосований будет перебирать и лишние уже неактивные.
    local result, numrows = dbPoll(query, dbpTime)
    dbFree(query)
    --outputServerLog("[VOTE_SYSTEM] MySQL querry OK")
    if (result and numrows > 0) then
        --outputServerLog("[VOTE_SYSTEM] Result >0")
        for index, row in pairs(result) do
            local id = row['id']
            local active = row['active']
            if active==1 then
                --проверка№7
                --outputServerLog("[VOTE_SYSTEM] active====1. id="..id..".active= "..active.." ." )
                local query = dbQuery(handler, "UPDATE votes SET `active`=0 WHERE id='"..id.."';" )
                local result, numrows = dbPoll(query, dbpTime)
                dbFree(query)
                if (result and numrows > 0) then
                    outputServerLog("[VOTE_SYSTEM] Vote "..id.." unactivated")
                else
                    outputServerLog("[VOTE_SYSTEM] can't unactivate vote #"..id)
                end
            --else outputServerLog("[VOTE_SYSTEM] active~=1. id="..id..".active= "..active.." ." ) end
            end
        end
    else outputServerLog("[VOTE_SYSTEM] all votes are active.") end
    
    
    --SELECT id,min(deleteDate) FROM votes;
    --select id,deleteDate from votes where deleteDate = (select min(deleteDate) from votes)
    local query = dbQuery(handler, "select id,deleteDate from votes where deleteDate = (select min(deleteDate) from votes where active='1')" )
    local result, numrows , lastid= dbPoll(query, dbpTime)
    dbFree(query)
    --outputServerLog("[VOTE_SYSTEM] NUMROWS="..numrows..".")
    --outputServerLog("[VOTE_SYSTEM] ERROR/lastid="..lastid..".")
    if (result and numrows > 0) then
        for index, row in pairs(result) do
            --outputServerLog("[VOTE_SYSTEM] pairs index="..index..".")
            local id = row['id'] or "shit8"
            local delDate = row['deleteDate'] or "shit9"
            outputServerLog("[VOTE_SYSTEM] Vote "..id.." set to timer.")
            if sysvote_timer then
                killTimer ( sysvote_timer )
            end
            sysvote_timer = setTimer ( votesys_check, (delDate-getRealTime().timestamp)*1000+51,1)
            outputServerLog("[VOTE_SYSTEM] Time ro next timer: "..delDate-getRealTime().timestamp.." seconds.")
        end
    end
end

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
            local query = dbQuery(handler, "SELECT id,text,numsOfVariants,deleteDate,active FROM votes WHERE (id='"..tonumber(arg[1]).."' AND active='1');" )
            local result, numrows = dbPoll(query, dbpTime)
            if (result and numrows > 0) then
                if numrows == 1 then
                    for index, row in pairs(result) do
                        id,text,numsOfVariants,deleteDate,active = row['id'],row['text'],row['numsOfVariants'],row['deleteDate'],row['active']
                        --отладочный вывод.
                        --outputChatBox("Распаршено.",thePlayer,0,255,255)
                    end
                    --отладочный вывод.
                    --outputChatBox("id1="..id..", text1="..text..", num1="..numsOfVariants,thePlayer,0,255,255)
                end
            else outputChatBox("Такого голосования не существует, уже завершено и удалено или произошла ошибка.",thePlayer,255,0,0) end
            dbFree(query)
        else return end
    else  
        outputChatBox("Для голосования нужно ввести команду с номером голосования и пунктом,за который нужно проголосовать.\
        Либо ввести команду и номер голосования для просмотра возможных вариантов для голосования",thePlayer,0,255,255)
    end
    
    if #arg==1 then
        --Берем из таблицы с именем id голосования данные об голосовании.
        local variantsQuery = ""
        --outputChatBox("id2="..id..", text2="..text..", num2="..numsOfVariants,thePlayer,0,255,255)
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
            --outputChatBox("2 args ok",thePlayer,0,255,255)
            local query = dbQuery(handler, "SELECT accvariant FROM "..tonumber(arg[1]).." WHERE accname='"..tostring(MySQLEscape(getPlayerAccount(thePlayer))).."';" )
            local result, numrows = dbPoll(query, dbpTime)
            if (result and numrows > 0) then
                --Голосовал, отказ в голосовании.
                for index, row in pairs(result) do
                    variant = row['accvariant']
                    outputChatBox("Вы уже голосовали за вариант "..variant,thePlayer,255,0,0)
                end
                --outputChatBox("id1="..id..", text1="..text..", num1="..numsOfVariants,thePlayer,0,255,255)
                dbFree(query)
            else 
                --запись голоса в базу.
                local query = dbQuery(handler, "INSERT INTO '"..tonumber(arg[1]).."' (accname,accvariant) values ('"..tostring(MySQLEscape(getPlayerAccount(thePlayer))).."', '"..tonumber(arg[2]).."');")
                --outputChatBox("dbQuery OK", thePlayer, 0, 255, 0)
                local result, numrows,lastid = dbPoll(query, dbpTime)
                --outputChatBox("dbPoll OK", thePlayer, 0, 255, 0)
                --outputChatBox("result="..tostring(result), thePlayer, 0, 255, 0)
                if(result) then
                    outputChatBox("Вы успешно проголосовали за вариант "..tonumber(arg[2]), thePlayer, 0, 255, 0)
                    return
                elseif result == false then
                    --local error_code,error_msg = numrows,lastid
                    outputChatBox("Ошибка при голосовании! Обратитесь к администрации через команду /report", thePlayer, 255, 0, 0)
                    --error("Vote error!")
                end
            end
        else outputChatBox("Ошибка, вы ввели неверный вариант",thePlayer,255,0,0) end
    end

end)

--в луа этой шляпы нет. Это просто нет слов...
--взято с http://lua-users.org/wiki/SplitJoin
string.split = function(str, pattern)
  pattern = pattern or "[^%s]+"
  if pattern:len() == 0 then pattern = "[^%s]+" end
  local parts = {__index = table.insert}
  setmetatable(parts, parts)
  str:gsub(pattern, parts)
  setmetatable(parts, nil)
  parts.__index = nil
  return parts
end
-- /votecreate --
addCommandHandler("votecreate", function(thePlayer,commandname,...)
    --лучше бы это вынести в GUI,т.к. луа ущербна в работе со строками.
    local arg = {...}
    if #arg>1 then
        local stringWithAllParameters = table.concat(arg, " ")
        if string.match(stringWithAllParameters,";") then
            --отладочный вывод
            --outputChatBox("ARGS"..stringWithAllParameters,thePlayer,0,255,255)
            args=stringWithAllParameters:split("[^;]+")
            --отладочный вывод
            --outputChatBox("Количество аргов"..#args,thePlayer,0,255,255)
            if #args>2 and #args<11 then
                local argsnum = #args-1
                local query = dbQuery(handler, "INSERT INTO 'votes' (CreatedBy,text,numsOfVariants,deleteDate,active) values ('"..tostring(MySQLEscape(getAccountName(getPlayerAccount(thePlayer)))).."', '"..args[1].."','"..argsnum.."',"..((getRealTime().timestamp)+TimeToEndVote)..",1);")
                
                local result, numrows,id = dbPoll(query, dbpTime)
                dbFree(query)
                --outputChatBox("lastid="..id, thePlayer, 0, 255, 0)
                
                local Query = dbQuery(handler,"CREATE TABLE IF NOT EXISTS '"..id.."' ('accname' TEXT NOT NULL UNIQUE,'accvariant' INTEGER NOT NULL);")
                dbFree(query)
                local arx={10,""}
                for i=1,10 do
                    arx[i]=args[i+1] or ""
                end
                local query = dbQuery(handler, "INSERT INTO 'votes_variants' (id,num1,num2,num3,num4,num5,num6,num7,num8,num9,num10) values ("..id..", '"..arx[1].."', '"..arx[2].."', '"..arx[3].."', '"..arx[4].."', '"..arx[5].."', '"..arx[6].."', '"..arx[7].."', '"..arx[8].."', '"..arx[9].."', '"..arx[10].."')")
                local result, numrows,lastid = dbPoll(query, dbpTime)
                dbFree(query)
                votesys_check()
                outputChatBox("Голосование создано. Голосование № "..id, thePlayer, 0, 255, 0)
            else
                outputChatBox("Ошибка: количество аргументов должнобыть не менее 2х и не более 10.",thePlayer,255,0,0)
            end
        else
            outputChatBox("Неправильный разделитель вопроса и вариантов ответа",thePlayer,255,0,0)
        end
    else
        outputChatBox("Ошибка : неправильное количество аргументов.",thePlayer,255,0,0)
    end

end)

-- /votedel --
addCommandHandler("votedel", function(thePlayer,commandname,...)
    local arg = {...}
    if #arg==1 and tonumber(arg[1])>0 then
        local id=tonumber(arg[1])--микрооптимизация
        --if(hasObjectPermissionTo ( thePlayer, "command.votedel", false ) ) then
        --взял с вики, не пашет, хотя себя как user.Kellin_Rover прописал в группу Admin и админпанель на локалхосте пашет. Поэтому могут пока удалять все
            local query = dbQuery(handler, "DELETE FROM votes WHERE id = '"..id.."';")
            local result = dbPoll(query, dbpTime)
            dbFree(query)
            if(result) then
                local query = dbQuery(handler, "DROP TABLE '"..id.."';")
                local result = dbPoll(query, dbpTime)
                dbFree(query)
                if(result) then
                    local query = dbQuery(handler, "DELETE FROM votes_variants WHERE id = '"..id.."';")
                    local result = dbPoll(query, dbpTime)
                    dbFree(query)
                    if(result) then
                        outputChatBox("Голосование молча удалено", thePlayer, 0, 255, 0)
                    end
                else 
                    outputChatBox("Голосование не найдено или другая ошибка.", thePlayer, 255, 0, 0)
                    outputConsole("[VOTE_SYSTEM] shit hapened #1")
                end
            else
                outputConsole("[VOTE_SYSTEM] shit hapened #2")
            end
        --else outputChatBox("Голосование могут удалять только администраторы/модераторы", thePlayer, 255, 0, 0) end
    else outputChatBox("Неправильное количество аргументов команды /votedel", thePlayer, 255, 0, 0) end
end)

-- /votehelp --

addCommandHandler("votehelp", function(thePlayer)
    outputChatBox("/votes для просмотра голосований", thePlayer, 0, 255, 255)
    outputChatBox("/vote #1 #2 для голосования в голосовании #1 за пункт #2", thePlayer, 0, 255, 255)
    outputChatBox("/votecreate для создания голосования. Пример:", thePlayer, 0, 255, 255)
    outputChatBox("/votecreate Тестовое голосование;Да;нет;Всем мандаринок", thePlayer, 0, 255, 255)
    outputChatBox("Для админов: /deletevote", thePlayer, 0, 255, 255)
end)

-- /votes

addCommandHandler("votes", function(thePlayer)
    local query = dbQuery(handler, "SELECT id,text,CreatedBy,active FROM votes WHERE active=1;" )
    local result, numrows = dbPoll(query, dbpTime)
    dbFree(query)
    local NumVotes=0
    outputChatBox("Проводимые голосования:", thePlayer, 0, 255, 255)
    local playerMessage
    if (result and numrows > 0) then
        for index, row in pairs(result) do
            local id = row['id']
            local text = row['text']
            local by = row['CreatedBy']
            --local active = row['active']
            playerMessage = "[ "..id.." ] "..tostring(text)
            NumVotes = NumVotes+1
            outputChatBox(playerMessage, thePlayer, 0, 255, 255)
        end
    end
    --можно if'ом запилить другую фразу если NumVotes=0 типа "голосований нет"
    outputChatBox("Всего "..NumVotes.." голосований. Будьте внимательно, изменить свой голос после голосования нельзя.", thePlayer, 0, 255, 255)
end)

-- /votecheck

addCommandHandler("votecheck", function(thePlayer,commandname,...)
    local query = dbQuery(handler, "SELECT id,text,CreatedBy,active FROM votes WHERE active=0;" )
    local result, numrows = dbPoll(query, dbpTime)
    dbFree(query)
    local NumVotes=0
    local playerMessage
    --outputChatBox("===================================================", thePlayer, 0, 255, 255)
    outputChatBox("Проведенные голосования:", thePlayer, 0, 255, 255)
    if (result and numrows > 0) then
        for index, row in pairs(result) do
            local id = row['id']
            local text = row['text']
            local by = row['CreatedBy']
            local active = row['active']
            local id,text,numsOfVariants = row['id'],row['text'],row['numsOfVariants']
            local query = dbQuery(handler, "select accvariant,count(accvariant) from '"..id.."' GROUP BY accvariant ORDER BY count(accvariant) DESC" )
            local result2, numrows2 = dbPoll(query, dbpTime)
            dbFree(query)
            --outputChatBox("sort ok", thePlayer, 0, 255, 255)
            if (result2 and numrows2 > 0) then
                --outputChatBox("result2>0", thePlayer, 0, 255, 255)
                for index2, row2 in pairs(result2) do
                    local variant = row2['accvariant']
                    local numsForVariant = row2['count(accvariant)']
                    --outputChatBox("id====="..id, thePlayer, 0, 255, 255)
                    --outputChatBox("variant "..variant, thePlayer, 0, 255, 255)
                    --outputChatBox("num"..numsForVariant, thePlayer, 0, 255, 255)
                    if numsForVariant>=NumsToEndVote then
                        --outputChatBox(numsForVariant..">2 ", thePlayer, 0, 255, 255)
                        outputChatBox("Голосование с id="..id.." набрало "..numsForVariant.." из требуемых "..NumsToEndVote.." голосов", thePlayer, 0, 255, 0)
                        outputChatBox("Текст: "..text, thePlayer, 0, 200, 0)
                        local query = dbQuery(handler, "select num"..variant.." from 'votes_variants' WHERE id='"..id.."'" )
                        local result3, numrows3 = dbPoll(query, dbpTime)
                        dbFree(query)
                        if (result3 and numrows3 > 0) then
                            for index3, row3 in pairs(result3) do
                                local variantText = row3['num'..variant]
                                outputChatBox("Победил вариант №"..variant.." : "..variantText, thePlayer, 0, 255, 0)
                            end
                        end
                    else
                        outputChatBox("Голосование с id="..id.." не прошло. Всего "..numsForVariant.." голосов", thePlayer, 200, 200, 0)
                    end
                end
            else
                outputChatBox("Голосование с id="..id.." набрало 0 голосов", thePlayer, 0, 255, 0)
            end
            NumVotes = NumVotes+1
            --outputChatBox(playerMessage, thePlayer, 0, 255, 255)
        end
        
    end
    --можно if'ом запилить другую фразу если NumVotes=0 типа "голосований нет"
    outputChatBox("Всего "..NumVotes.." неактивных голосований. Удалить ненужные можно командой /votedel #", thePlayer, 0, 255, 255)
end
)

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

