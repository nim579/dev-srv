var p    = require('path');
var fs   = require('fs');
var conf = require('./config');

fs.access(conf.ROOT_PATH, function(err){
    if(err){
        fs.mkdirSync(conf.ROOT_PATH);
        fs.writeFileSync(p.resolve(conf.ROOT_PATH, 'conf.json'), JSON.stringify(conf));
        console.log('Module inited');
    }
});


