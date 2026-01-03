fx_version 'cerulean'
game 'gta5'

author 'Kap'
description 'Drug Selling with Database'

-- This is crucial for ox_lib and oxmysql to work
shared_script '@ox_lib/init.lua'
-- This ensures MySQL is defined globally
server_script '@oxmysql/lib/MySQL.lua' 

shared_script 'config.lua'
client_script 'client.lua'
server_script 'server.lua'

dependencies {
    'ox_lib',
    'ox_inventory',
    'oxmysql'
}