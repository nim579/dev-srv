var commands = require('../lib/commands');

module.exports = function(grunt) {
    grunt.registerMultiTask('devsrv', 'Commands for dev-srv daemon for Grunt', function() {
        var done = this.async();
        var data = this.data || {};

        function onCommand(err, data){
            if(err){
                if(err.code == 'server_name_exists'){
                    restart();
                } else {
                    grunt.fail.fatal(JSON.stringify(err));
                }
                return;
            }

            grunt.log.ok(JSON.stringify(data));
            commands.disconnect();
            done();
        }
        function restart(){
            commands.remove(data.name, function(err){
                if(err){
                    return grunt.fail.fatal(JSON.stringify(err));
                }
                start();
            });
        }
        function start(){
            switch(data.mode){
                case 'srv':
                    commands.srv(data.name, data.root, data.port, data.index, onCommand);
                    break;

                case 'proxy':
                    commands.proxy(data.name, data.port, onCommand);
                    break;

                case 'exec':
                    commands.exec(data.name, data.command, data.cwd, data.port, data.args, onCommand);
                    break;

                case 'fork':
                    commands.fork(data.name, data.path, data.cwd, data.port, data.args, onCommand);
                    break;

                default:
                    grunt.fail.fatal('`mode` not defined.');

            }
        }

        start();
    });
    grunt.registerTask('devsrv:remove', 'Remove server from dev-srv', function(name){
        var done = this.async();

        commands.remove(name, function(err){
            if(err && err.code != 'server_is_not_defined'){
                grunt.fail.fatal(JSON.stringify(err));
                return;
            }

            commands.disconnect();
            done();
        });
    });
};
