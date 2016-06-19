var p = require('path');

var conf = {
	ROOT_PATH: '',
	FOLDER:    '.devsrv'
}

if(process.env.DEVSRV_HOME){
	conf.ROOT_PATH = process.env.DEVSRV_HOME;
} else if(process.env.HOME && !process.env.HOMEPATH){
	conf.ROOT_PATH = p.resolve(process.env.HOME, conf.FOLDER);
} else if(process.env.HOME || process.env.HOMEPATH){
	conf.ROOT_PATH = p.resolve(process.env.HOMEDRIVE, process.env.HOME || process.env.HOMEPATH, conf.FOLDER);
} else {
	conf.ROOT_PATH = p.resolve('/etc', conf.FOLDER)
}

conf.DAEMON_PORT = p.resolve(conf.ROOT_PATH, 'daemon.sock');
conf.DAEMON_PID  = p.resolve(conf.ROOT_PATH, 'daemon.pid');

module.exports = conf;
