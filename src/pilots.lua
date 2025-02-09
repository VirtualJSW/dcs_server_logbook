-- src/pilots.lua

local utils = require("src.utils")

--print(type(utils.getPilotInfoByID))

local pilotsModule = {}

function pilotsModule.generatePilotHTML(stats, pilotList, pilotID, outputFilePath, threshold)

    local pilotInfo = utils.getPilotInfoByID(pilotList, pilotID)
    local totalSeconds = 0
    local typeLog = {}

    if not pilotInfo then
        print("Pilot with ID " .. pilotID .. " not found in the pilot list.")
        return
    end

    local pilotLog = stats[pilotID]

    if not pilotLog then
        print("No logbook information found for pilot " .. pilotInfo.name)
        return
    end

    local htmlContent = "<h1>Pilot Information File</h1>\n"
    local typeContent = ""
    htmlContent = htmlContent .. "<h2>Basic Information</h2>\n"
    htmlContent = htmlContent .. "<p>Pilot ID: " .. utils.truncatePilotID(pilotID) .. "</p>\n"
    htmlContent = htmlContent .. "<p>Pilot Service: " .. pilotInfo.service .. "</p>\n"
    htmlContent = htmlContent .. "<p>Pilot Rank: " .. pilotInfo.rank .. "</p>\n"
    htmlContent = htmlContent .. "<p>Pilot Name: " .. pilotInfo.name .. "</p>\n"
    htmlContent = htmlContent .. "<h2>Qualifications</h2>\n"
    if pilotInfo.quals then
        for _, qual in ipairs(pilotInfo.quals) do
            htmlContent = htmlContent .. "<li>" .. qual .. "</li>\n"
        end
        htmlContent = htmlContent .. "</ul>\n"
    else
        htmlContent = htmlContent .. "No qualifications logged.\n"
    end
    htmlContent = htmlContent .. "<h2>Awards</h2>\n"
    if pilotInfo.awards then
        for _, award in ipairs(pilotInfo.awards) do
            htmlContent = htmlContent .. "<li>" .. award .. "</li>\n"
        end
        htmlContent = htmlContent .. "</ul>\n"
    else
        htmlContent = htmlContent .. "No awards.\n"
    end
    htmlContent = htmlContent .. "<h2>Logbook</h2>\n"

    local killLog = {}  -- Table to store kills by type

    for logKey, logValue in pairs(pilotLog) do
        if logKey == "times" then
            for aircraftType, timeValue in pairs(logValue) do
                for state, seconds in pairs(timeValue) do
                    if state == "total" and seconds >= threshold then
                        totalSeconds = totalSeconds + seconds
                        table.insert(typeLog, {name = aircraftType, time = seconds})
                    end
                end

                -- Summing up kills across all types
                if timeValue["kills"] then
                    for killType, killDetails in pairs(timeValue["kills"]) do
                        if type(killDetails) == "number" then
                            killLog[killType] = (killLog[killType] or 0) + killDetails
                        elseif type(killDetails) == "table" then
                            for _, killCount in pairs(killDetails) do
                                if type(killCount) == "number" then
                                    killLog[killType] = (killLog[killType] or 0) + killCount
                                end
                            end
                        end
                    end
                end
            end
        elseif logKey == "lastJoin" then
            lastJoinContent = "<p>Last Joined: " .. utils.epochToDateString(logValue) .. "</p>\n"
        end
    end


    htmlContent = htmlContent .. "<h3>Totals</h3>\n"
    htmlContent = htmlContent .. lastJoinContent
    htmlContent = htmlContent .. "<p>Total hours: " .. utils.secToHours(totalSeconds) .. "</p>\n"
    htmlContent = htmlContent .. "<h3>Type Totals</h3>\n"
    htmlContent = htmlContent .. "<table style=border='1'>\n"
    htmlContent = htmlContent .. "<tr><th style='width:20%'>Type</th><th style='width:20%'>Hours</th></tr>\n"
    table.sort(typeLog, function(a, b) return a.time > b.time end)
    for i, entry in ipairs(typeLog) do
        htmlContent = htmlContent .. "<tr><td>" .. entry.name .. "</td><td>" .. utils.secToHours(entry.time) .. "</td></tr>"
    end
    htmlContent = htmlContent .. "</table>\n"

    htmlContent = htmlContent .. typeContent

    -- Generate HTML content for Kills
    htmlContent = htmlContent .. "<h3>Kills</h3>\n"
    htmlContent = htmlContent .. "<table style=border='1'>\n"
    htmlContent = htmlContent .. "<tr><th style=\'width:20%\'>Type</th><th style=\'width:20%\'>Kills</th></tr>\n"
    for killType, killCount in pairs(killLog) do
        htmlContent = htmlContent .. "<tr><td>" .. killType .. "</td><td>" .. killCount .. "</td></tr>\n"
    end
    htmlContent = htmlContent .. "</table>\n"

    -- Open the HTML file for writing
    local file = io.open(outputFilePath, "w")

    -- Check if the file was opened successfully
    if not file then
        print("Error opening file for writing: " .. outputFilePath)
        return
    end

    -- Write HTML content to the file
    file:write("<html>\n<head>\n<title>Pilot Information</title>\n<meta name='viewport' content='width=device-width, initial-scale=1'>\n<link rel='stylesheet' type='text/css' href='styles.css'>\n</head>\n<body>\n")
    file:write("<div class='container'>")
    file:write(htmlContent)
    file:write("</div>")
    file:write("\n</body>\n</html>")

    -- Close the file
    file:close()

    --print("HTML file created successfully: " .. outputFilePath .. "\n")
end

return pilotsModule
