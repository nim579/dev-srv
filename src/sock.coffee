_    = require 'underscore'
net  = require 'net'
conf = require '../tools/config'

class Server
    constructor: (@messageCallback)->
        @_start()
        return @

    _start: ->
        @_srv = net.createServer()

        @_srv.on 'error', (error)=>
            process.send? success: false, error: error

            console.log "Daemon socket not started"

        @_srv.on 'connection', (socket)=>
            @_onConnection socket

        @_srv.listen conf.DAEMON_PORT, ->
            process.send? success: true

            console.log "Daemon socket started"

    _onConnection: (socket)->
        new Socket socket, @messageCallback

    destroy: (callback)->
        return callback?() unless @_srv

        @_srv.close ->
            callback?()


class Socket
    constructor: (@_socket, @requestCallback)->
        @_socket.on 'data', (data)=>
            @request data.toString()

    request: (req)->
        message = null

        try
            message = JSON.parse req

        if message and message.id and message.method and message.params
            @requestCallback message.method, message.params, (error, result)=>
                @response message.id, message.method, error, result

    response: (id, method, error=null, result=null)->
        res = JSON.stringify
            id: id
            method: method
            error: error
            result: result

        @_socket.write res


class Client
    options:
        timeout: 5000

    requests: []

    constructor: (callback)->
        @_connect callback
        return @

    destroy: ->
        @_sock?.destroy()

    generateId: ->
        return _.uniqueId new Date().getTime() + "_"

    request: (method, params={}, callback)->
        if _.isFunction params
            callback = params
            params = {}

        cuncurentReq = _.find @requests, (req)->
            return req.request.method is method and JSON.stringify(req.request.params) is JSON.stringify(params)

        return cuncurentReq.defer if cuncurentReq

        requestData =
           id: @generateId()
           method: method
           params: params

        defer = new Promise (resolve, reject)=>
            request =
                id: requestData.id
                method: method
                request: requestData
                startTime: new Date()
                defer: defer
                resolve: resolve
                reject: reject

            @_setTimeout request
            @requests.push request
            @_send requestData

        defer.then (data)->
            callback? null, data
            return data

        , (data)->
            callback? data
            return data

        return defer

    _connect: (callback)->
        @_sock = net.connect conf.DAEMON_PORT, -> callback?()

        @_sock.on 'error', (err)->
            callback? err

        @_sock.on 'data', (data)=>
            @_message data.toString()

    _message: (message)->
        if _.isString message
            try
                message = JSON.parse message

            catch e
                return

        if message.method and message.id and (message.error or message.result)
            if request = _.findWhere(@requests, id: message.id, method: message.method)
                @_resolveRequest request

                if message.error
                    request.reject message.error

                else if message.result
                    request.resolve message.result

    _send: (data)->
        @_sock.write JSON.stringify data

    _setTimeout: (request)->
        request.timeout = setTimeout =>
            @_requestTimeout request
        , @options.timeout

    _requestTimeout: (request)->
        @requests = _.without @requests, request
        request.reject code: 'timeout'

    _resolveRequest: (request)->
        clearTimeout request.timeout
        @requests = _.without @requests, request


module.exports =
    Server: Server
    Client: Client
    Socket: Socket
