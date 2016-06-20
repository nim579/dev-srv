pkg      = require '../package.json'
_        = require 'underscore'
Table    = require 'cli-table'
program  = require 'commander'
commands = require './commands'

program
.version pkg.version

program
.command 'start [port] [host]'
.description 'Starts daemon server'
.action (port, host)->
    commands.start port, host, (err, daemon)->
        if err
            if err.code is "EADDRINUSE"
                console.log "Daemon server already started. Stop server or remove .devsrv/daemon.sock file and try again"

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
        console.log "Daemon stoped!"

program
.command 'restart [port] [host]'
.description 'Restarts daemon server'
.action (port, host)->
    commands.restart port, host, (err, data)->
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
        if err
            if err.code is "ENOENT"
                console.log "Daemon not started."

            else
                console.log "Some error"
                console.log err

            return

        console.log "Daemon answer: #{JSON.stringify data}"

program
.command 'list'
.description 'List current running servers'
.action ->
    commands.list (err, data)->
        if err
            if err.code is "ENOENT"
                console.log "Daemon not started."

            else
                console.log "Some error"
                console.log err

            return

        tbl = new Table head: ['Name', 'Mode', 'Port', 'Identy']

        data = [] unless _.isArray data

        for srv in data
            tbl.push [srv.name, srv.mode, srv.port, srv.identy]

        console.log tbl.toString()

program
.command 'proxy <name> [port]'
.description 'Add proxy connection for already running server'
.action (name, port)->
    commands.proxy name, port, (err, data)->
        if err
            if err.code is "ENOENT"
                console.log "Daemon not started."

            else
                console.log "Some error"
                console.log err

            return

        console.log data

program
.command 'srv <name> <root> [port] [index]'
.description 'Add node-srv server'
.action (name, root, port, index)->
    commands.srv name, root, port, index, (err, data)->
        if err
            if err.code is "ENOENT"
                console.log "Daemon not started."

            else
                console.log "Some error"
                console.log err

            return

        console.log data

program
.command 'remove <name>'
.description 'Add node-srv server'
.action (name)->
    commands.remove name, (err, data)->
        if err
            if err.code is "ENOENT"
                console.log "Daemon not started."

            else
                console.log "Some error"
                console.log err

            return

        console.log "Server removed", data

program.parse process.argv
