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

## API

```js
var DevSrv = require('dev-srv');

DevSrv.ping(function(err, data){
   console.log(err, data);
});
```

### Methods
* **start(port, host, autoport, callback)**
* **stop(callback)**
* **restart(port, host, autoport, callback)**
* **ping(callback)**
* **list(callback)**
* **srv(name, root, port, index, callback)**
* **proxy(name, port, callback)**
* **exec(name, command, cwd, port, args, callback)**
* **fork(name, path, cwd, port, args, callback)**
* **remove(name, callback)**

All callbacks has *errdata* format.

Methods automatically call **connect()**, if daemon socket not connected. Disconnect will done manually with method **disconnect()** (sync).

You can connect manually, just call method **connect(callback)**.

## Grunt task

```js
module.exports = function(grunt) {
    grunt.loadTasks('dev-srv');

    grunt.initConfig({
        devsrv: {
            site: {
                mode: 'srv',
                name: 'mysite',
                root: './dist'
            },
            tests: {
                mode: 'exec',
                name: 'tests.mysite',
                command: 'npm',
                args: ['test']
            }
        }
    });
};
```

```bash
grunt devsrv:site
```

```bash
grunt devsrv:remove:site    # remove server with name 'site'
```

Available modes: srv, proxy, exec, fork.

Grunt task just starts servers. You can't start and stop daemon. Server not removing when task done, runt `devsev:remove:{name}` task.

