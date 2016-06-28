_  = require 'underscore'
p  = require 'path'
fs = require 'fs'
cp = require 'child_process'
conf  = require '../tools/config.js'
Proxy = require './proxy'
sock  = require './sock'

cluster = require 'cluster'

class Daemon
    servers: []
    portFamily: 5000

    constructor: (port, host, autoPortFrom)->
        # Experimental clusterization
        # return @_clusterize() if cluster.isMaster
        @portFamily = Number(autoPortFrom) if autoPortFrom

        @_startProxy port, host, (err)=>
            if err
                process.send? success: false, error: err
                console.log "Daemon proxy not started:", err
                @destroy()
                return

            console.log "Daemon proxy started"
            @_startCommands (err)=>
                if err
                    process.send? success: false, error: err
                    console.log "Daemon socket not started:", err
                    @destroy()
                    return

                console.log "Daemon socket started"

                @_bindEvents()

                process.send? success: true
                console.log 'Daemon ready'

    _clusterize: ->
        cluster.settings.silent = true
        worker = cluster.fork()

        @_bindEvents @destroyCluster

        cluster.on 'message', (data)->
            if data.success
                cluster.on 'error', (worker, code, signal)->
                    console.log 'Daemon died', code, signal
                    cluster.fork()

            worker.process.stdout.on 'data', (data)->
                process.stdout.write data.toString()

            worker.process.stderr.on 'data', (data)->
                process.stderr.write data.toString()

            process.send? data
            console.log "Daemon clusterized."

    _startProxy: (port, host, callback)->
        @_proxy = new Proxy port, host, (err, data)->
            if err
                if err is 'proxy_port_access_denied'
                    console.log 'Proxy port access denied. Try to start with sudo.'
                    callback? 'proxy_port_access_denied'

                else if err is 'proxy_port_already_in_use'
                    console.log 'Proxy port already in use. Choose another port or release current.'
                    callback? 'proxy_port_already_in_use'

                else
                    console.log 'Proxy start unknown error', data
                    callback? data

                return

            return callback? null

    _startCommands: (callback)->
        @_commands = new sock.Server _.bind(@command, @), (err, data)->
            if err
                console.log 'Socket server not started:', data
                return callback? err

            return callback? null

    _bindEvents: (destroy=@destroy)->
        process.on 'SIGINT',             _.bind(destroy, @)
        process.on 'SIGTERM',            _.bind(destroy, @)
        process.on 'unhandledRejection', _.bind(destroy, @)
        process.on 'rejectionHandled',   _.bind(destroy, @)

        process.on 'uncaughtException', (err)->
            console.error "Uncaught Exception"
            console.error err

    destroy: (callback)->
        for server in @servers
            @remove server

        @_proxy?.stop()
        @stop callback

    destroyCluster: (callback)->
        if cluster.isMaster
            for worker in cluster.workers
                worker.kill 1

        callback?()

    stop: (callback)->
        console.log 'Daemon stoped'
        callback?()

        process.exit() unless @_commands

        @_commands.destroy ->
            setTimeout ->
                process.exit()
            , 200

    command: (method, params, callback)->
        switch method
            # Admin methods
            when 'ping'
                callback? null,
                    port: @_proxy.port
                    host: @_proxy.host
                    next_auto_port: @_getPort()

            when 'list'
                callback? null, _.map @servers, (server)=> return @_returnServer server

            when 'stop'
                @destroy ->
                    callback? null, {}

            # Set server methods
            when 'srv'
                @srv params, callback

            when 'proxy'
                @proxy params, callback

            when 'exec'
                @exec params, callback

            when 'fork'
                @fork params, callback

            when 'remove'
                @remove params, callback

    srv: (params, callback)->
        return callback? code: "name_is_not_defined" unless params.name
        return callback? code: "server_name_exists" if @_checkName params.name

        try
            NodeSrv = require 'node-srv'

        catch
            return callback? {code: "node-srv_not_installed"}

        return callback? code: "params_is_not_defined", param: "root" unless params.root

        port = null
        _fport = null

        if params.port
            port = params.port

        else
            port = @_getPort()
            _fport = port

        options =
            port: port
            root: params.root
            logs: false

        options.index = params.index if params.index

        srv = new NodeSrv options

        server =
            mode: 'srv'
            name: params.name
            identy: params.root
            instance: srv
            port: port
            status: 'normal'
            _fport: _fport

        @servers.push server
        @_proxy.addNode server.name, server.port

        callback? null, @_returnServer server
        console.log "Server added for \"#{server.name}\" on port #{server.port}"

    proxy: (params, callback)->
        return callback? code: "name_is_not_defined" unless params.name
        return callback? code: "server_name_exists" if @_checkName params.name

        port = null
        _fport = null

        if params.port
            port = params.port

        else
            port = @_getPort()
            _fport = port

        server =
            mode: 'proxy'
            name: params.name
            identy: port
            instance: null
            port: port
            status: 'normal'
            _fport: _fport

        @servers.push server
        @_proxy.addNode server.name, server.port

        callback? null, @_returnServer server
        console.log "Proxy added for \"#{server.name}\" on port #{server.port}"

    exec: (params, callback)->
        return callback? code: "name_is_not_defined" unless params.name
        return callback? code: "server_name_exists" if @_checkName params.name

        return callback? code: "params_is_not_defined", param: "command" unless params.command

        port = null
        _fport = null

        if params.port
            port = params.port

        else
            port = @_getPort()
            _fport = port

        env =
            'PORT': port

        out = fs.openSync p.resolve(conf.ROOT_PATH, "srv-#{params.name}.log"), 'a'
        err = fs.openSync p.resolve(conf.ROOT_PATH, "srv-#{params.name}-error.log"), 'a'

        options =
            cwd: if params.cwd then params.cwd
            stdio: ['ipc', out, err]
            env: _.extend {}, process.env,
                'PORT': port

        proc = cp.spawn params.command, params.args or [], options

        server =
            mode: 'exec'
            name: params.name
            identy: params.command + unless _.isEmpty(params.args) then ' '+params.args.join(' ') else ''
            instance: proc
            port: port
            status: 'online'
            _fport: _fport

        proc.on 'exit', ->
            server.status = 'offline'

        @servers.push server
        @_proxy.addNode server.name, server.port

        callback? null, @_returnServer server
        console.log "Server executed for \"#{server.name}\" on port #{server.port}"

    fork: (params, callback)->
        return callback? code: "name_is_not_defined" unless params.name
        return callback? code: "server_name_exists" if @_checkName params.name

        return callback? code: "params_is_not_defined", param: "path" unless params.path

        port = null
        _fport = null

        if params.port
            port = params.port

        else
            port = @_getPort()
            _fport = port

        env =
            'PORT': port

        out = fs.openSync p.resolve(conf.ROOT_PATH, "srv-#{params.name}.log"), 'a'
        err = fs.openSync p.resolve(conf.ROOT_PATH, "srv-#{params.name}-error.log"), 'a'

        options =
            cwd: if params.cwd then params.cwd
            silent: true
            env: _.extend {}, process.env,
                'PORT': port

        proc = cp.fork params.path, params.args or [], options

        proc.stdout.on 'data', (data)->
            fs.write out, data.toString()

        proc.stderr.on 'data', (data)->
            fs.write err, data.toString()

        server =
            mode: 'fork'
            name: params.name
            identy: params.path + unless _.isEmpty(params.args) then ' '+params.args.join(' ') else ''
            instance: proc
            port: port
            status: 'online'
            _fport: _fport

        proc.on 'exit', ->
            server.status = 'offline'

        @servers.push server
        @_proxy.addNode server.name, server.port

        callback? null, @_returnServer server
        console.log "Server forked for \"#{server.name}\" on port #{server.port}"

    remove: (params, callback)->
        return callback? code: "name_is_not_defined" unless params.name
        return callback? code: "server_is_not_defined" unless @_checkName params.name

        server = _.findWhere @servers, name: params.name
        @servers = _.without @servers, server
        @_proxy.removeNode params.name

        if server
            switch server.mode
                when 'srv'
                    server.instance.stop()

                when 'exec', 'fork'
                    server.instance.removeAllListeners()
                    server.instance.kill()

            callback? null, @_returnServer server
            console.log "Server \"#{server.name}\" removed"

        else
            callback? code: 'server_not_found'

    _getPort: ->
        port = @portFamily
        lastPort = _.max _.pluck(@servers, '_fport'), (port)-> return port or 0

        port = lastPort + 1 if lastPort > 0

        return port

    _checkName: (name)->
        return !!_.findWhere @servers, name: name

    _returnServer: (server)->
        return _.omit server, 'instance', '_fport'


new Daemon process.argv[2] or null, process.argv[3] or null
