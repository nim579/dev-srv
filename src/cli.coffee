pkg      = require '../package.json'
_        = require 'underscore'
Table    = require 'cli-table'
program  = require 'commander'
commands = require './commands'


getAdditional = ->
    if (argsIndex = program.rawArgs.indexOf('--')) >= 0
        optargs = program.rawArgs.slice argsIndex + 1

    return optargs or []

errorHandlers = (err)->
    if err
        switch err.code
            when 'ENOENT'
                console.log "Daemon not started."

            when 'name_is_not_defined'
                console.log "Name is not defined."

            when 'server_is_not_defined', 'server_not_found'
                console.log "Server is not defined."

            when 'params_is_not_defined'
                console.log "Some required params is not defined."

            when 'server_name_exists'
                console.log "Server already exists."

            when 'server_not_found'
                console.log "Server not found."

            when 'node-srv_not_installed'
                console.log 'Node-srv module not installed. Install optional module, and retry.'

            else
                console.log "Some error:"
                console.log err

        return true

    return false


program
.version pkg.version

program
.command 'start'
.description 'Starts daemon server'
.option '-p, --port [port]', 'Set daemon server port'
.option '-h, --host [hostname]', 'Set daemon server domain name'
.option '-a, --autoport [first_port]', 'Set start port for automatic configuration'
.action (options)->
    commands.start options.port, options.host, options.autoport, (err, daemon)->
        if err
            if err is "socket_addr_in_use"
                console.log "Daemon server already started. Stop server or remove .devsrv/daemon.sock file and try again"

            else if err is 'proxy_port_access_denied'
                console.log "Proxy port access denied. Try to start with sudo."

            else if err is 'proxy_port_already_in_use'
                console.log "Proxy port already in use. Choose another port or release current."

            else
                console.log "Daemon server not started. Some error."
                console.log err

            return

        console.log "Daemon started on pid: #{daemon.pid}"

program
.command 'stop'
.description 'Stops daemon server'
.action ->
    commands.stop (err, data)->
        commands.disconnect()

        if err
            console.log "Some error"
            console.log err
            return

        console.log "Daemon stoped!"

program
.command 'restart'
.description 'Restarts daemon server'
.option '-p, --port [port]', 'Set server port'
.option '-h, --host [hostname]', 'Set server domain name'
.option '-a, --autoport [first_port]', 'Set start port for automatic configuration'
.action (options)->
    commands.restart options.port, options.host, options.autoport, (err, data)->
        commands.disconnect()

        if err
            console.log "Some error"
            console.log err
            return

        console.log "Daemon restarted with pid: #{data.pid}"

program
.command 'ping'
.description 'Ping daemon server'
.action ->
    commands.ping (err, data)->
        commands.disconnect()

        return if errorHandlers(err)

        console.log "Daemon started on port #{data.port} and listen host \"#{data.host}\". Next automatic port #{data.next_auto_port}."

program
.command 'list'
.description 'List current running servers'
.action ->
    commands.list (err, data)->
        commands.disconnect()

        return if errorHandlers(err)

        tbl = new Table head: ['Name', 'Mode', 'Port', 'Status', 'Identy']

        data = [] unless _.isArray data

        for srv in data
            tbl.push [srv.name, srv.mode, srv.port, srv.status, srv.identy]

        console.log tbl.toString()

program
.command 'proxy <name> <port>'
.description 'Add proxy connection for already running server'
.action (name, port)->
    commands.proxy name, port, (err, data)->
        commands.disconnect()

        return if errorHandlers(err)

        console.log "Proxy \"#{data.name}\" started for port #{data.port}."

program
.command 'srv <name> <root>'
.description 'Add node-srv server'
.option '-p, --port [port]', 'Set custom port'
.option '-i, --index [filename]', 'Set index file name'
.action (name, root, options)->
    commands.srv name, root, options.port, options.index, (err, data)->
        commands.disconnect()

        return if errorHandlers(err)

        console.log "Server \"#{data.name}\" started on port #{data.port}."

program
.command 'exec <name> <command>'
.description 'Execute server start command'
.option '-p, --port [port]', 'Set custom port'
.option '-- [args...]', 'Custom args for command'
.action (name, command, options)->
    args = getAdditional()

    commands.exec name, command, process.cwd(), options.port, args, (err, data)->
        commands.disconnect()

        return if errorHandlers(err)

        console.log "Executed server \"#{data.name}\" started on port #{data.port}."

program
.command 'fork <name> <path>'
.description 'Fork nodejs server script by path'
.option '-p, --port [port]', 'Set custom port'
.option '-- [args...]', 'Custom args for script'
.action (name, path, options)->
    args = getAdditional()

    commands.fork name, path, process.cwd(), options.port, args, (err, data)->
        commands.disconnect()

        return if errorHandlers(err)

        console.log "Fork server \"#{data.name}\" started on port #{data.port}."

program
.command 'remove <name>'
.description 'Remove server'
.action (name)->
    commands.remove name, (err, data)->
        commands.disconnect()

        return if errorHandlers(err)

        console.log "Server \"#{data.name}\" removed."


program.parse process.argv
