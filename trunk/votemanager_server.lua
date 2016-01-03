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
    if #arg>0 then
        if tonumber(arg[1])~=nil then
            
    
    if #arg==1 then
        if tonumber(arg[1])~=nil then
            local query = dbQuery(handler, "SELECT id,text,numsOfVariants FROM votes WHERE id='"..tonumber(arg[1]).."';" )
            local result, numrows = dbPoll(query, dbpTime)
            if (result and numrows > 0) then
                if numrows == 1 then
                    local id,text,numsOfVariants=0,"bugaga",2
                    for index, row in pairs(result) do
                        id,text,numsOfVariants = row['id'],row['text'],row['numsOfVariants']
                    end
                    dbFree(query)
                    --Берем из таблицы с именем id голосования данные об голосовании.
                    local variantsQuery = ""
                    for i=1,numsOfVariants do
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
                else outputChatBox("something wrong 1",thePlayer,0,255,255) end
            else
                outputChatBox("Такого голосования не существует или произошла ошибка.",thePlayer,0,255,255)
            end
        else 
            --неправильные аргументы для голосования.
            outputChatBox("something wrong 5",thePlayer,0,255,255)
        end
    elseif #arg==2 then
        --команда с 2мя аргументами для голосования за конкретноеголосование.
        outputChatBox("2 args, В разработке",thePlayer,0,255,255)
        if tonumber(arg[1])~=nil and tonumber(arg[2])~= then
            
        end
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

