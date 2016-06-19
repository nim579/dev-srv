# start <port> <host>
# stop
# exec <name> <command> <port> <args>
# fork <name> <path_to_script> <port> <args>
# srv <name> <path> <root>
# proxy <name> <port>
# remove <name>
# list, ls, l
# connect
# ping
# set <key> <value>

commands =
    connect: (callback)->
    disconnect: ->
    
    ping:   (callback)->
    set:    (key, value, callback)->
    list:   (callback)->

    start:  (port, host, callback)->
    stop:   (callback)->
    exec:   (name, command, port, args, callback)->
    fork:   (name, path, port, args, callback)->
    srv:    (name, path, root, callback)->
    proxy:  (name, port, callback)->
    remove: (name, callback)->


module.exports = commands
