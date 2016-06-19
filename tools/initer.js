var p    = require('path');
var fs   = require('fs');
var conf = require('./config');

var commands  = require('../lib/commands.js')

function stratDaemon(){
    commands.start(null, null, function(err){
        if(!err){
            console.log('Daemon started');
        } else if(err = 'already_started'){
            console.log('Already started');
        } else {
            console.log(err);
        }
    })
}

fs.access(conf.ROOT_PATH, function(err){
    if(err){
        fs.mkdirSync(conf.ROOT_PATH);
        fs.writeFileSync(p.resolve(conf.ROOT_PATH, 'conf.json'), JSON.stringify(conf));
        console.log('Inited');
        stratDaemon();
    } else {
        console.log('Already inited');
        stratDaemon();
    }
});


