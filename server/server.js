var helper = require('./helper');
var url = require('url');
var express = require('express');  
var app = express();
var apiv1 = require('./apiv1');
var tickprotocol = require('./tickprotocol');
var tick = require('./tick');

var server = require('http').createServer(app);

helper.connectMongodb();

app.configure(function () {  
        app.use(express.bodyParser());  
        app.use(express.methodOverride());  
        app.use(express.logger());  
        app.use(express.bodyParser());  
        app.use(express.cookieParser());  
        app.use(express.session({  
                    secret: "skjghskdjfhbqigohqdioukd",  
                        }));  
    });  

app.get('/', function (req, res) {  
        res.sendfile(__dirname + '/public/index.html');  
    });
app.use('/public', express.static(__dirname + '/public'));
app.use('/upload', express.static(__dirname + '/upload'));

apiv1.serve(app);
tickprotocol.installConnectHandler(server, tick.tickHandler);

server.listen(helper.config.server.port, helper.config.server.host);
console.log('daemon start on http://' + helper.config.server.host + ':' + helper.config.server.port);
