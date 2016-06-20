_  = require 'underscore'
cp = require 'child_process'
Proxy = require './proxy'
sock  = require './sock'

class Daemon
    servers: []
    portFamily: 5000

    constructor: (port, host)->
        @_commands = new sock.Server _.bind(@command, @)
        @_proxy    = new Proxy port, host

        process.on 'SIGINT',  _.bind(@stop, @)
        process.on 'SIGTERM', _.bind(@stop, @)

    stop: (callback)->
        callback?()

        @_commands.destroy ->
            setTimeout ->
                process.exit()
            , 200

    command: (method, params, callback)->
        console.log 'comm', arguments

        switch method
            # Admin methods
            when 'ping'
                callback? null, msg: 'pong'

            when 'list'
                callback? null, _.map @servers, (server)=> return @_returnServer server

            when 'stop'
                @stop ->
                    callback? null, {}

            # Set server methods
            when 'srv'
                @srv params, callback

            when 'proxy'
                @proxy params, callback

            # when 'exec'
            # when 'fork'

            when 'remove'
                @remove params, callback

    srv: (params, callback)->
        return callback? code: "name_is_not_defined" unless params.name
        return callback? code: "server_name_exists" if @_checkName params.name

        try
            NodeSrv = require 'node-srv'

        catch
            return callback? {code: "node-srv_not_installed"}

        return callback? code: "params_is_not_defined" unless params.root

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
            _fport: _fport

        @servers.push server
        @_proxy.addNode server.name, server.port

        callback? null, @_returnServer server

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
            _fport: _fport

        @servers.push server
        @_proxy.addNode server.name, server.port

        callback? null, @_returnServer server

    exec: (params, callback)->
    fork: (params, callback)->

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

            callback? null, @_returnServer server

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


new Daemon process.argv[2], process.argv[3]
