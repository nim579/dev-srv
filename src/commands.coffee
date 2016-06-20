_    = require 'underscore'
p    = require 'path'
fs   = require 'fs'
cp   = require 'child_process'
conf = require '../tools/config.js'
sock = require './sock'


commands =
    connect: (callback)->
        commands = @

        client = new sock.Client (err)->
            commands._client = client
            callback? err, client

    disconnect: (client=@_client)->
        client?.destroy?()

    start:  (port, host, callback)->
        mode = p.extname process.argv[1]
        script = p.resolve __dirname, './daemon'+mode
        initer = process.argv[0]

        out = fs.openSync conf.DAEMON_LOGS, 'a'
        err = fs.openSync conf.DAEMON_LOGS_ERROR, 'a'

        daemon = cp.spawn initer, [script, port, host],
            detached: true
            cwd: process.cwd()
            stdio: ['ipc', out, err]

        daemon.unref()

        daemon.once 'message', (msg)->
            if msg.success
                callback? null, daemon

            else
                callback? msg.error, daemon

            daemon.disconnect()

    stop: (callback)->
        commands._request 'stop', callback

    restart: (port, host, callback)->
        commands.stop (err)->
            return callback? err if err

            commands.start port, host, (err, data)->
                callback? err, data

    ping: (callback)->
        commands._request 'ping', callback

    list: (callback)->
        commands._request 'list', callback

    srv: (name, root, port, index, callback)->
        commands._request 'srv', {name: name, root: root, index: index, port, port}, callback

    proxy: (name, port, callback)->
        commands._request 'proxy', {name: name, port: port}, callback

    # exec: (name, command, port, args, callback)->
    # fork: (name, path, port, args, callback)->

    remove: (name, callback)->
        commands._request 'remove', {name: name}, callback

    set:    (key, value, callback)->

    _request: (method, params, callback)->
        if _.isFunction params
            callback = params
            params = {}

        commands.connect (err, daemon)->
            return callback err if err

            daemon.request method, params
            .then (data)->
                callback? null, data
                commands.disconnect()

            , (data)->
                callback? data
                commands.disconnect()


module.exports = commands
