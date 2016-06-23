# dev-srv

Developer servers daemon.

## Install

```
$ npm install -g dev-srv
```

## Useage

```
$ dev-srv proxy test 3000
```

## Folder structure

Once *dev-srv* is installed, it will automatically create these folders:

* `$HOME/.devsrv` — will contain all PM2 related files
* `$HOME/.devsrv/daemon.sock` — socket file for remote commands
* `$HOME/.devsrv/daemon.log` — *dev-srv* daemon logs
* `$HOME/.devsrv/daemon-error.log` — *dev-srv* daemon error logs

## Start and config

```
$ dev-srv start -p 8080 -h lc.nim.space
```

This command starts daemon on port (`-p` or `8080` by default). `-h` parameter will useing for servers start (`http://[server_name].lchost.ws/` for host `lchost.ws`).

Set DNS *A* record for all subdomains in your host. For example:
```
*.lchost.ws.  A   127.0.0.1
```

## Commands

* `start [options]` — Starts daemon server
    * `-p, --port [port]` — Set daemon server port
    * `-h, --host [hostname]` — Set daemon server domain name
* `restart [options]` — Restarts daemon server
    * `-p, --port [port]` — Set daemon server port
    * `-h, --host [hostname]` — Set daemon server domain name
* `stop`  — Stops daemon server
* `ping` — Ping daemon server
* `list` — List current running servers
* `proxy <name> <port>` — Add proxy connection for already running server
* `srv [options] <name> <root>` — Add node-srv server
    * `-p, --port [port]` — Set custom port
    * `-i, --index [filename]` — Set index file name
* `exec [options] <name> <command>` — Execute server start command
    * `-p, --port [port]` — Set custom port
    * `-- [args...]` — Custom args for command
* `fork [options] <name> <path>` — Fork nodejs server script by path
    * `-p, --port [port]` — Set custom port
    * `-- [args...]` — Custom args for script
* `remove <name>` — Remove server
