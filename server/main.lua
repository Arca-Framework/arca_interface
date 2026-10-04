Arca.Callback.Register('arca_interface:info', function()
    return {
        name = GetConvar('sv_projectName', GetConvar('sv_hostname', 'Arca')),
        players = #GetPlayers(),
        maxPlayers = GetConvarInt('sv_maxclients', 48),
    }
end)

-- saves the character and sends the player back to character selection (arca_character)
RegisterNetEvent('arca_interface:switchCharacter', function()
    exports.arca_core:Logout(source)
end)

RegisterNetEvent('arca_interface:disconnect', function()
    DropPlayer(source, 'Disconnected from the server.')
end)
