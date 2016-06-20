pkg  = require '../package.json'
http = require 'http'
url  = require 'url'
_ = require 'underscore'

class Proxy
    _nodes: {}

    constructor: (port, host)->
        @host = host or 'lc.nim.space'
        @port = port or 8080

        console.log @port, @host

        @_proxy = http.createServer _.bind(@request, @)
        @_proxy.listen @port

        console.log 'Proxy started'

    stop: ->
        @_proxy.close()

    request: (req, res)->
        hostname = url.parse('node://'+req.headers.host).hostname
        return @responseForbidden res unless hostname.indexOf(@host) > -1

        name = hostname.replace @host, ''
        name = name.replace /\.$/, ''

        port = @getNode name

        return @responseUndefined res unless port

        options =
            hostname: '127.0.0.1'
            port: port
            path: req.url
            method: req.method
            headers: req.headers

        proxy_req = http.request options, (proxy_res)=>
            res.writeHead proxy_res.statusCode, @_addHostHead proxy_res.headers

            proxy_res.on 'data', (data)->
                res.write data

            proxy_res.on 'end', (data)->
                res.end data

        req.on 'data', (data)->
            proxy_req.write data

        req.on 'end', (data)->
            proxy_req.end data

    responseUndefined: (res)->
        res.writeHead 503
        res.write "<h1>#{http.STATUS_CODES[503]}</h1>"
        res.end()

    responseForbidden: (res)->
        res.writeHead 403
        res.write "<h1>#{http.STATUS_CODES[403]}</h1>"
        res.end()

    _addHostHead: (headers)->
        server = "dev-srv/#{pkg.version}"

        headers.server = server + if headers.server then ', ' + headers.server else ''
        return headers

    addNode: (name, port)->
        @removeNode name
        @_nodes[name] = port

    removeNode: (name)->
        if @_nodes[name]
            delete @_nodes[name]

    getNode: (name)->
        return @_nodes[name]


module.exports = Proxy
